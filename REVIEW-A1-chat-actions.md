# Review A1: the client's chat actions (look, join, leave, mute)

Branch `wip/client-chat`, head 9d881dd9, diff `af4ca40e..9d881dd9` (4 commits; the frame 2bb5a715 read with
care). Independent review, 2026-11-21. Nothing in the tree was edited. Every probe is a test file loaded with
`go test -overlay` from
`C:\Users\trabi\AppData\Local\Temp\claude\71f159c3a9e5d4b9\203f8752-f1fd-4d92-89da-68a6a88f4ca9\scratchpad\review-a1`
(`tg_probe_test.go`, `cat_probe_test.go`, `col_probe_test.go` and their `*_overlay.json`). Nothing ran against
Telegram. Data in the probes is invented.

## Findings

### F1. A leave that has taken the account out of a basic group can end "waited", "refused", "not known" or "not sent", with no mark. MUST FIX. CONFIRMED.

- **Where:**
  - `internal/telegram/act_chat.go`: `leave` and `leaveStopped`.
  - `internal/catalog/schema_actchat.go`: `endChatAct`, case `ActLeave`, which calls `markOwnerLeft` only `if done`.
- **What happens:** take a basic group.
  1. `getPeerDialogs` answers, and the step becomes "in the list".
  2. `deleteChatUser` answers, the step becomes "out", and the account has left the group.
  3. `deleteHistory` then gets one of these:
     - a `FLOOD_WAIT`: the click ends `OutWaited`;
     - a refusal, or no answer: the click ends refused, or "not known";
     - nothing sent at all, because the session's context ended, the account's refusal was recorded meanwhile, or a wait was recorded. The click ends `OutNotSent` with `Requests` 2. Its text says "stopped after the click was written down; nothing was sent (cancelled)".

  In every one of these cases:
  - `endChatAct` writes no mark, and `tg_access` stays `ok`;
  - `ReadableChats` reports `OwnerLeft` false, so the reader goes on reading a group the account has left;
  - the ledger says "not sent" for a click whose two requests went out and took effect.

  This breaks the brief's "after a done leave the catalogue marks the chat" and design 4.5 ("its reading stops"). The owner has to come back and click "finish leaving" before reading stops. The "decided otherwise" line in the report ("not sent at the step reached, though earlier steps went out") is this defect.
- **Probes:**
  - `TestProbeA1LeftThenWaited`: sends `getPeerDialogs`, `deleteChatUser`, `deleteHistory`; ends with kind waited and step "out".
  - `TestProbeA1LeftThenNotSent`: two requests; ends with kind not sent (cancelled), step "out", Requests 2.
  - `TestProbeA1OutButNoMark` (catalog), for an end of waited, and for an end of not sent, both at step "out": mark false, the record says the account is in, the reader does not skip the chat.
- **Fix:**
  - In `endChatAct`, write the mark (`markOwnerLeft`) whenever `e.Step` is `LeaveOut` or `LeaveCleared`, whatever the state.
  - In `leave`, a stop after any request has gone must not end `OutNotSent`. End it as the step's own outcome (waited or unknown), or as done with "not finished" once the step is "out". Keep "not sent" for `Requests == 0` only.

### F2. Saved Messages is "left" (its history removed) when the account's Telegram id is not on record. MUST FIX. CONFIRMED (request layer).

- **Where:**
  - `internal/telegram/act.go`, `Do`: `act.Kind == ActLeave && ... && a.cfg.SelfID != 0 && act.Chat.ID == a.cfg.SelfID`.
  - `internal/collector/click_chat.go`, `chatClickInput`: `self != 0 && ch.tg.ID == self`.
- **What happens:**
  - The collector passes `SelfID: a.userID.Load()`. That value is `account.TgUserID` from the catalogue (`account.go:157`), and it stays 0 until a sign-in through the app records it. The monitor's own gate (`account.go:545`, `a.userID.Load() != 0`) shows that this state is expected.
  - With 0, both checks pass. Saved Messages is in the chat list as a user chat whose access hash the peers hold. `leave` then sends `getPeerDialogs`, then `deleteHistory` on the account's own user: every saved message is removed, and this cannot be undone.
  - The rule is "fail closed". A leave of a user chat while the account's own id is unknown must be refused.
- **Probe:** `TestProbeA1SavedMessagesSelfUnknown`: with SelfID 0, a user chat's leave sends `getPeerDialogs` and `deleteHistory` and ends done, "history removed".
- **Fix:**
  - In `Do`, refuse `ActLeave` of `ChatUser` when `SelfID == 0`, with `ErrActSavedMessages` or a store-failure word.
  - In `chatClickInput`, refuse the same leave when `self == 0`.

### F3. A join answered `INVITE_REQUEST_SENT` ("asked") takes away the owner's leave mark, though the account is not in the chat. SHOULD FIX. CONFIRMED.

- **Where:**
  - `internal/catalog/schema_actchat.go`, `endChatAct`, case `ActJoin`: `if done { clearOwnerLeft(...) }`.
  - `chatSaid` makes "asked" a done outcome.
- **What happens:**
  1. The owner leaves a public channel; the mark is written and `tg_access` becomes left.
  2. Later the owner looks at the channel by its name. The look finds the channel, and the join's row takes its chat.
  3. The join is answered `INVITE_REQUEST_SENT`: done, said "asked". The mark is cleared at once while the admins have not decided.
  4. `ReadableChats` no longer skips the chat. The reader reads it again; a public channel's history can be read without being a member.

  This breaks "the mark ends when the account is seen in the chat again".
- **Probe:** `TestProbeA1AskedClearsMark`: after the done "asked" end, the mark is false, the record says not in and out, and the reader does not skip the chat.
- **Fix:** in `endChatAct` (and `settleJoin`), clear the mark only for a done join whose `e.Said` is "" or `SaidAlreadyIn`, never for `SaidAsked`.

### F4. The mark lapses on any later "ok" save of the chat's facts, stamped with the save's own time, and the left chat then becomes a new source of the automatic mirror. SHOULD FIX. CONFIRMED mechanism; PLAUSIBLE trigger.

- **Where:**
  - `internal/catalog/schema_actchat.go`: `ownerLeftSQL` (`joined_at <= owner_left_at`).
  - `internal/catalog/tgchats.go`, `saveFacts`: sets `joined_at = at` on any change from out to in.
  - `tgstore.Store.ChatChanged`, which passes `at = s.now().Unix()`.
- **What happens:**
  - The mark holds only while `joined_at` is not later than the mark.
  - `joined_at` is not Telegram's join date. It is the local time of any save that moves `tg_access` from out to ok, whatever the event (`ChatUpdated` included).
  - Such a save can be stale. The live monitor runs beside the click turn, and an `updateChannel` or `updateChat` carrying a chat object from before the leave (a title change in flight, a `getDifference` batch) can be stored after `EndClick`. When it is:
    - the mark lapses;
    - `tg_access` is ok again;
    - the reader reads the chat;
    - `MirrorAutoNewChats` takes it as newly joined (`joined_at > baseline`), so the automatic mirror would create a mirror channel for a chat the owner left: a write to Telegram.
  - The mirror never reads the mark itself; it relies on `tg_access`.
- **Probe:** `TestProbeA1StaleOkLapses`: an ok save one second after the mark gives mark false; the automatic mirror's new chats go from 0 to 1, and the one is this chat.
- **Fix:** lapse the mark only on an explicit join (the `ChatJoined` event, the app's done join or its settle), not on `ChatUpdated` with access ok. Ask the mirror track to add `owner_left_at` to `MirrorAutoNewChats` as well.

### F5. A look's link outlives its 7 days, as a plain SHA-256 that can be guessed, in `c_act_key.form` (30 days). SHOULD FIX. CONFIRMED.

- **Where:** `internal/collector/click_api.go`, `clickForm`. The branch adds `str(in.Link)` for the four kinds.
- **What happens:**
  - The page's key row keeps a digest of the click's form for `ActKeyDays` (30) days.
  - The digest is an unkeyed SHA-256. For a look, every other input is predictable: a small account number, chat 0, kind "look", zeros.
  - A list of public names, each tried with the few ways of typing it, finds the link from the catalogue alone. That still works after the look's link and title are cleared (7 days, a done join, the verdict "left").
  - The brief: the hash and the username "live only in the click's row ... at most 7 days".
- **Probe:** `TestProbeA1LookFormGuessable` (collector): the stored digest of `@name` is found among 4 candidates × 4 spellings.
- **Fix:** do one of these:
  - key the digest with a secret of the catalogue's own (HMAC);
  - leave the link out of the digest for a look and compare the parsed link held in the row instead;
  - clear `c_act_key.form` for a look when its link is cleared.

### F6. "Finish leaving" starts from a stored step without looking again. MINOR. PLAUSIBLE.

- **Where:** `internal/telegram/act_chat.go`, `leaveStep`. A "finish leaving" with step "out" on a basic group goes straight to `deleteHistory`.
- **What happens:**
  1. A basic group's leave ended "waited" at step "out" (F1).
  2. The account is added back to the group, or joins on the phone.
  3. Days later the owner clicks "send again" on that row.
  4. The program removes the account's history in a group it is a member of, does not leave it, ends done "history removed", and writes the mark. The reader then stops reading a chat the account is in, until the next save.
- **Fix:** when `act.Step != ""`, begin a "finish leaving" with the same one `getPeerDialogs` (1 request, said on the button). Or let F1's fix make this path rare and say so on the page.

### F7. The `c_act` rebuild copies a hard-coded column list. MINOR (robustness for the merge). CONFIRMED by reading.

- **Where:** `internal/catalog/schema_actchat.go`: `schemaActChat`'s `INSERT INTO c_act_v27(...) SELECT ...`, and the same for `c_act_msg` and `c_act_key`.
- **What is right today:** main (09d63f94) has not changed `c_act` since af4ca40e, and nothing else refers to it. On the reviewed tree everything comes through:
  - every row, message row and key row;
  - every index (the 9 old ones, plus `c_act_join_look`, `c_act_kind_sent` and `c_act_link`);
  - the three references (`again_of`, `chain`, `c_act_msg.act_id`, `c_act_key.act_id`), which SQLite rewrites on the rename.

  There is no trigger or view on these tables. The step is one transaction, children are dropped first, and it is atomic.
- **The risk:**
  - Any branch that adds a column to `c_act` (or a table that refers to it) and merges before this step would lose that column's data silently.
  - A table referring to `c_act` would make the migration fail, and the app would not open.
  - The frame is shared with another branch, so the risk is real at the merge.
- **Fix:** in `schemaActChatFor`, refuse the step unless `pragma_table_info('c_act')` has exactly the 30 known columns, and unless `pragma_foreign_key_list` of every other table names no `c_act`.

### F8. Small ones. MINOR. CONFIRMED by reading.

- **`leave`'s unreadable answer** (`act_chat.go`, the `rerr != nil` branch):
  - It sets `out.Type = "no answer of the history's removal"` at every step, the chat list's included.
  - The apostrophe fails `catalog.ActTypeOK`, so `tgstore.actType` stores "unclassified".
  - Fix: use `ue.Type` and words without the apostrophe.
- **A look sent again with "try again"** (`sendClickAgain` copies `try_again`):
  - It reaches `chatShape`, which refuses `TryAgain` on a look, so it ends not sent, "bad action".
  - Fix: refuse it at `sendClickAgain`, or ignore `try_again` for a look.
- **`getPeerDialogs` on a left private channel is not confirmed:**
  - The old app confirmed against the account's full chat list. What Telegram answers `getPeerDialogs` for a channel the account has left (an empty list, or `CHANNEL_PRIVATE`) is not on record.
  - If the answer is `CHANNEL_PRIVATE`, the leave ends refused and is remembered (R7), and no mark is written although the account is out.
  - Measure it at the first real leave, and read `CHANNEL_PRIVATE` at step "" as "already out".
- **Older read-only programs:**
  - An older read-only program (an older viewer) opening a v27 catalogue fails closed on a chat's leave and mute rows, because their kind words are unknown to it.
  - It is harmless when the app's folder is updated as one, but say so in the merge notes.
- **The viewer's chat box:**
  - It draws a leave's or a mute's open tips (waited, refused, not known, not sent) with the text step's words.
  - This is the viewer track's, not this branch's; list it for them.

## What was checked and holds

- **Leave sequence and flags:**
  - The order is `getPeerDialogs`, then `leaveChannel`, or `deleteChatUser(self)` then `deleteHistory`, or `deleteHistory` alone.
  - `revoke`, `just_clear` and `revoke_history` are never set; `max_id` is 0 (the branch's `TestChatActLeaveSteps` checks the flags bit for bit).
  - The history loop is bounded at 50 rounds and `LeaveFor`.
  - `USER_NOT_PARTICIPANT` at the leave's step counts as out.
  - Each step is recorded through `Step` before the next request goes.
  - "Finish leaving" goes on from the recorded step and never repeats a step that cannot be repeated (F6 aside).
- **Mirror chats, the cap and the account's door:**
  - Mirror chats are refused at the queue and in `Do`.
  - The click cap counts a leave once.
  - The account's door is held up to Begin.
- **Joins:**
  - A join names its look. `LookFor` refuses a look that is stale (7 days, by `ended_ms`), another account's, spent (`c_act_join_look` and the chain's own join excepted), or cleared; it reads the look again at the join's turn.
  - The join cap: 5 an hour and 20 a day, a stored setting with no upper bound (at least 1). It is read at each join, counted from the joins begun (`sending_ms`), and the state call uses the same arithmetic.
  - `USER_ALREADY_PARTICIPANT` and `INVITE_REQUEST_SENT` end done with their words.
  - `CHANNELS_TOO_MUCH` is refused with its word and not remembered.
  - Paid invites and persons or bots are refused at the queue and at the turn.
  - `INVITE_WEBVIEW_ASKED` is refused and not remembered.
  - A private invite whose look found no chat learns its chat from the answer.
- **Mute:** `inputNotifyPeer`, with only `mute_until` set (flags `1<<2`). It takes 0, now plus seconds, or 2147483647. Saved Messages goes as `inputPeerSelf`.
- **The door:**
  - The new routes go through the same wrapper, guard and secret.
  - `/api/act/click` is read-only and kept during a held stop.
  - `/api/clicks/join-cap` is under the same handler as the cap's route, with the same body limit.
  - The state route takes chat 0 for the account's part only.
  - The queue refuses a chat on a look or a join, and a negative look or mute.
  - The five new words are in the closed set.
- **Privacy:**
  - Every new `logf` line has a constant format with counts and seconds only.
  - Error texts are fixed words; `failed` logs `errType` only.
  - Titles reach the door's answer only; peers are stored without names.
  - F5 is the one leak found.

## Tests run

- Each run used `GOMAXPROCS=2 GOGC=25`, named tests only, the project's toolchain (`ix-tools/goroot-1.27.3`), and no race detector.
- The CPU was measured before each run: 64%, 84% and 88%. The third run started above the 85% bound by my mistake; it took 12 s.

| Package | Run | Time |
|---|---|---|
| `./internal/telegram/` | `-run TestProbeA1` | 0.16 s (7.8 s with the build) |
| `./internal/catalog/` | `-run TestProbeA1` | 0.97 s (11.8 s) |
| `./internal/collector/` | `-run TestProbeA1` | 0.14 s (12.1 s) |

Each probe printed its CONFIRMED line.

## Verdict

**Not ready:** F1 and F2 must be fixed first.
- F1 leaves the reader reading a group the account has left, and records "not sent" for requests that went out.
- F2 can remove Saved Messages' history when the account's id is not on record.

F3, F4 and F5 should be fixed in the same round: F3 and F4 because the mark is the leave's one durable record, F5 because the rule on links is binding. F6 to F8 may follow.

Once F1 to F5 are fixed and each has its test seen failing first, the branch may be listed.

## Second look (F1, F2, F4)

Head 38b7d918, diff `9d881dd9..38b7d918`, the coder's report section 8. Only F1, F2 and F4 were checked.

New probes, in the same scratch folder:
- `tg_probe2_test.go` with `tg_overlay2.json`;
- `cat_probe2_test.go` with `cat_overlay2.json`.

They ran with `GOMAXPROCS=2 GOGC=25`, named tests only:

| Package | Run | Time |
|---|---|---|
| telegram | `-run TestProbeA1b` | 0.15 s |
| catalog | `-run TestProbeA1b` | 0.39 s |

The CPU was 56% before the telegram run. The catalog run started at 87%, because the measurement and the run were in one command. That broke the 85% bound; it is my mistake, and the run took 11 s.

### F1: fixed for what it named; one regression (S1)

**What now holds:**
- Once a request has gone out, a stop no longer ends "not sent".
- With the step "out", a stop with no request of its own is done "not finished". Telegram's own wait, refusal or no answer at a later step ends there, at the step "out".
- `ClickStep(out | history removed)` writes the mark in the same transaction as the step, so the mark is on record before the next request and whatever ends the click. Probe (1): with the click still "sending", the mark is true, the reader skips the chat, and the record says the account is out.
- `endChatAct` also marks at any end whose step is "out" or "history removed".
- A private chat is "out" from the first answered round of its history removal.

**S1. A leave whose first request does not go after Begin now ends "not known" or "waited", with 0 requests. SHOULD FIX. CONFIRMED.**
- **Where:** `internal/telegram/act_chat.go`, `leave` and `leaveStopped`.
- **What happens:**
  - Report's check right after Begin fails: a wait recorded meanwhile, the account's refusal, the caller's cancel, or a record that cannot be read.
  - `begun` is already true and `out.Requests == before == 0`, so `leaveStopped` runs with step "".
  - Before the fix this ended "not sent", correctly. It now ends:
    - `OutUnknown` ("the next step was not sent") for a cancel or a store failure;
    - `OutWaited` for a wait;
    - `OutAccountRefused` for the account's refusal.

    Each time `Requests` is 0, so the ledger says "not known", "waited" or "account refused" for a click that sent nothing. That breaks `Do`'s own contract: after Begin with no request, End records `OutNotSent`.
- **Probe:** `TestProbeA1bFirstStepStoppedAfterBegin`. A ledger whose Begin cancels the context, or records a wait, while the row turns "sending".
  - Cancel: sent `[]`, ends not known, type "the next step was not sent", requests 0.
  - Wait: sent `[]`, ends waited, requests 0.
- **Fix:** at the top of `leaveStopped`, when `out.Requests == 0`, return the old not-sent outcome (`a.notSent` with its reason).

### F2: fixed. CONFIRMED by reading

- `Do` refuses every leave of a private chat while `SelfID == 0` (`ErrActSelfUnknown`).
- `chatClickInput` refuses the same leave at the queue while `a.userID` is 0 (`ErrClickSelfUnknown`, door word "self unknown").
- A send again and an older queued leave both reach `Do`.
- The Actor keeps the `SelfID` it was made with, so an Actor made while the id was 0 keeps refusing: the safe side.
- The finish's `leaveLook` comes after these checks.
- No path found removes a private chat's history with `SelfID` 0.

### F4: the stale save is closed; one gap remains (S2)

**What holds:**
- `ownerLeftSQL` no longer reads `joined_at`.
- While the mark holds, `saveFacts` drops any access that would put the account in, whatever the event. Probe (2):
  - an "updated" ok save and a "joined" ok save, 60 s after the mark;
  - the mark holds, the reader skips the chat, the record stays out, and `MirrorAutoNewChats` has 0 new chats.
- The coder's answer on the mirror's sources is right for a held mark:
  - `MirrorAutoNewChats` needs `tg_access` ok and `access <> 'gone'`;
  - `AccountInChat` says out, so an existing mirror ends `MirrorEndLeft`.
- `LapseOwnerLeft`:
  - it lapses only for a list whose read began after the mark (probe (3): begun at the mark, 0 lapsed; one second after, 1);
  - the reader takes `now` before the list's request;
  - clicks run before `readTurn` in the same loop, so no leave can land during a list's read;
  - the reader's list is the only chat-list store.
- A done join clears the mark, but not one answered "asked"; so does its settle.
- **By design, a minor note:** a rejoin on the phone, seen by the live monitor, is held until the next chat list. That can be up to `ChatListEvery` (24 h by default; 30 minutes while the automatic mirror is on).

**S2. A private chat whose history removal stopped part way is read again after the next chat list. SHOULD FIX. CONFIRMED mechanism; trigger near certain.**
- **Where:**
  - `internal/collector/reader.go`: the `in` list built for `LapseOwnerLeft`.
  - `internal/telegram/dialogs.go`, `dialogEntries`: every user is `AccessOK`.
- **What happens:**
  1. A private chat's leave reaches "out" (the first round answered), then stops. It may stop at a wait or refusal on a later round, or end done "not finished" at 50 rounds or at `LeaveFor`. The mark is written.
  2. The dialog still holds messages, so the next chat list names it, with the user "ok". It goes into `in`, its mark lapses, and the list's save puts the account back in (`joined_at` now).
  3. The reader reads the chat again while the owner is part way through leaving it.

  For a basic group, the list's `Chat.Left` keeps it out of `in`. For a channel, the chat is no longer listed. So the gap is private chats only.
- **Probe:** `TestProbeA1bMarkPaths` (4): the reader skips the chat before the list; `LapseOwnerLeft` lapses 1; after the list's save the reader no longer skips it.
- **Fix:** do not lapse a private chat's mark from the list. Keep only a done join or its settle (there is none for a person), or "the other side wrote after the mark". Or lapse it only when the listed dialog's top message is newer than the mark (`ChatEntry.TopMessage` or its date against `owner_left_at`).

### Verdict of the second look

F2 is fixed. F1 is fixed for every stop after a request has gone out, and the mark now follows the step. F4's stale save is closed, and the mirror's choice of sources is safe while the mark holds.

Two new defects should be fixed before listing:
- S1: a leave that sent nothing ends "not known" or "waited". It is a one-line guard.
- S2: a private chat part way through its leave is read again at the next chat list.

**May be listed after S1 and S2 are fixed**, each with its test seen failing first. Neither needs another full look: a check of the two lines and their tests is enough.
