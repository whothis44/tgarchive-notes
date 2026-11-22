# Review A2: a file the archive holds, sent from Telegram's own copy

Independent review of branch `wip/client-afile`, head 78a3ad63, against main 6aa225fb. The frame commit 2bb5a715 was
read only where this branch relies on it (the `c_act` rebuild, the kind words). Reviewed 2026-11-21.

Read against: `DESIGN-CLIENT-acting.md` sections 3, 4.3 and 6 point 2; `BRIEF-A2-file-from-archive.md`; the coder's
`archiver/docs/progress/client-afile-REPORT.md`; R1 to R12 of `core-act-REPORT.md`.

**How the probes were run.** The probes are in
`C:\Users\trabi\AppData\Local\Temp\claude\71f159c3a9e5d4b9\203f8752-f1fd-4d92-89da-68a6a88f4ca9\scratchpad\review-a2\`:
- `probe_telegram_test.go`, loaded by `overlay_tg.json` as `internal/telegram/zz_probe_a2_test.go`;
- `probe_catalog_test.go`, loaded by `overlay_cat.json` as `internal/catalog/zz_probe_a2_test.go`.

Run with `GOMAXPROCS=2 GOGC=25 go test -count=1 -overlay <overlay> -run TestProbeA2 -v ./internal/<pkg>/`. Each probe
fails (prints `PROBE:`) while the defect is there. Nothing in the tree was edited. Nothing ran against Telegram.

## Findings

### F1. Frozen and mirror are judged only before the read, which can last minutes. MUST FIX. CONFIRMED.

- **Where:** `internal/telegram/act_file.go`, `sendFile`.
- **What goes wrong:** R5 (`cfg.Frozen` and the kind's frozen record) and R9 (`cfg.IsMirror` on the destination) are
  asked once, before the source's read. After the read, only these are checked again before `messages.sendMedia`:
  - the cap (`capped`);
  - the waits (report's first check and `recheck`);
  - the account's refusal (`recheck`).

  The read can take minutes: it sleeps stated waits (F2), with up to 3 tries of 2 minutes each. In `Do` the gap
  between R5 or R9 and the request is milliseconds; here it is the read's whole length. Two cases:
  - **Frozen:** the account is found frozen while the read runs (another goroutine sets it). The send still goes
    out: a write on a frozen account (R5: off for a frozen account).
  - **Mirror:** the destination becomes one of the app's mirrors while the read runs (an adoption, M6). The send
    goes into the mirror (R9: never into the app's own mirror chats).
- **Probes:** `TestProbeA2FrozenDuringRead` and `TestProbeA2MirrorDuringRead` in `probe_telegram_test.go`. The read's
  answer flips the rig's frozen flag (or adds the destination to the mirrors). Both show requests `read,send` and the
  outcome done.
- **Fix:** after `sourceMedia`, and before `a.door.lock()`, ask R5 (the callback and the kind's frozen record) and R9
  again. Better still, fold them into the `refusal` callback that `report` calls right after Begin, so they hold up
  to the send.

### F2. The read sleeps stated waits inside the click's turn, past the 2 minutes a click may wait. SHOULD FIX. CONFIRMED.

- **Where:** `internal/telegram/act_file.go`, `readSource`, through `caller.call`. Seen from the turn:
  `internal/collector/click.go`, `oneClick`, running in the reader task's goroutine.
- **What goes wrong:**
  - **How long one click can hold the turn:**
    - the click's Forwarder has MaxWait 60 s (`mirror.AutoWaitInTurn`) and up to 5 waits per call
      (`DefaultMaxWaitsPerCall`);
    - `held` also sleeps a refresh wait that is already running;
    - each try has the Forwarder's RequestTimeout of 2 minutes (default; the clicks' Forwarder sets none), with 2
      retries (`AutoConfigRetries`).

    So one file click can hold the account's loop for about 5 minutes of waits, or about 6 minutes of timeouts.
  - **Who waits behind it:**
    - the reader's next page;
    - the automatic mirror's turn;
    - the owner's estimate calls (`st.reqs`);
    - every other queued click.

    A click's pass is never cut (`cancelReaderPass` cuts only reader passes).
  - **What the sleep buys:**
    - **The turn's rule holds, but the sleep is wasted.** The ledger's Begin (`catalog.BeginClick`, through
      `tgstore.ActLedger.Begin` with `clickMaxAge` = 2 minutes) refuses a click older than 2 minutes as "not sent
      in time". A click whose read slept more than about 2 minutes, minus its time in the queue, is therefore always
      refused at Begin: no send, the read spent.
    - **Other clicks are lost.** The clicks queued behind it pass their own 2 minutes during the sleep, and the next
      round's `SweepOldClicks` marks them "not sent in time".
  - **A stop during the sleep is handled correctly:**
    - `takeWait` records the wait before it sleeps;
    - the sleep ends on the context;
    - `readFailed` returns `ctx.Err()`;
    - `oneClick` returns with the row still queued, and the session's end marks it "not sent". It is never shown as
      "not known".
- **Probe:** `TestProbeA2ReadSleepsInTheTurn` in `probe_telegram_test.go`. The read is answered FLOOD_WAIT_59 four
  times, then answers. One `Do` slept 4m0s and the clock moved 4m0s before Begin. Requests:
  `read,read,read,read,read,send`. The rig's ledger has no age bound, so the send went out there; in the collector,
  Begin would refuse it as too old after the 4 minutes.
- **Fix:** limit the read's total waiting to the click's remaining age (clickMaxAge minus its age, with one wait at
  most). Or, simpler: treat a stated wait on the read as the send's is treated: recorded, the click "not sent,
  waiting" with its end, nothing slept. Give the read a short request timeout of its own (seconds, not 2 minutes).

### F3. Deleting an account leaves its file clicks' source rows; the next file clicks cannot be queued. SHOULD FIX. CONFIRMED.

- **Where:**
  - `internal/catalog/settle.go`, the account purge (the `delRest` statement list): it deletes `c_act_key`,
    `c_act_msg` and `c_act` of the account, but not `c_act_file`.
  - `internal/catalog/schema_actfile.go` itself: `QueueFileClick`, and the trigger `c_act_file_again`.
- **What goes wrong:**
  - **Ids come back.** `c_act.id` is an INTEGER PRIMARY KEY without AUTOINCREMENT. Once the deleted account's rows
    were the newest, SQLite gives the same ids again. A catalogue with one account that is deleted and added again
    starts again at 1.
  - **File clicks fail.** The next file click of any account gets the id of an orphan row. Its INSERT INTO
    `c_act_file` fails on the primary key, the whole transaction rolls back, and the door answers a store error. The
    id is not consumed, so every later file click fails the same way until a click of another kind takes that id.
  - **The orphan stays attached.** The orphan row then sits under that click: `FileOfClick` of the send click reads
    as a bad ledger.
  - **Data is left over.** The deleted account's source references (chat, message, file) stay in the catalogue.
  - **Fail-closed holds.** No wrong file is ever sent: the trigger's copy and the explicit INSERT both conflict.
- **Probe:** `TestProbeA2PurgeLeavesFileRows` in `probe_catalog_test.go`. After `DeleteAccount(1)`: 0 `c_act` rows,
  1 `c_act_file` row. Account 2's file click: `UNIQUE constraint failed: c_act_file.act_id`. A send click then takes
  id 1, and `FileOfClick` on it is `ErrBadActLedger`.
- **Fix:** add `DELETE FROM c_act_file WHERE act_id IN (SELECT id FROM c_act WHERE account_id = ?)` to the purge,
  before the `c_act` delete (a line in Core's file, lent). Optionally, have `QueueFileClick` refuse in fixed words a
  ref that already has a source row.

### F4. The caption is judged by the text limit, not the caption limit. SHOULD FIX. CONFIRMED.

- **Where:**
  - `internal/telegram/act_file.go`, `sendFile` (`textFits(act.Text, textMax)`);
  - `internal/collector/click_api.go`, `QueueClick` (`limit = lim.TextMax` for a file click).
- **What goes wrong:** the limits are `message_length_max` 4096 and `caption_length_max` 1024 (2048 premium). A caption
  between the caption limit and the text limit passes both checks, costs one read, and then sends a
  `messages.sendMedia` that Telegram can only refuse (MEDIA_CAPTION_TOO_LONG). That is a write request known to
  fail, made from the owner's click.
  - The coder's reason in "decided otherwise" is that the Actor does not keep the caption limit. But
    `help.getConfig`, which `Limits` already asks, carries it. The collector's state already publishes
    `lim.CaptionMax` (`click_state.go`), so the door can use it with no request.
- **Probe:** `TestProbeA2CaptionOverCaptionMax` in `probe_telegram_test.go`. With a caption limit of 50 and a text
  limit of 200, a caption of 100 is sent: requests `read,send`.
- **Fix:** keep `CaptionLengthMax` in the Actor beside `textMax`, and judge a caption by it (no limit known: refused,
  as now). At the door, use `lim.CaptionMax` for a file click.

### F5. The send's 7 days' guard is not applied to a file send. SHOULD FIX (or a recorded decision). CONFIRMED.

- **Where:**
  - `internal/catalog/act_settle.go`, `settleJudgeClick` and `preGuard`: both apply the guard only when
    `cl.Kind == ActSend`;
  - `internal/catalog/act_settle_file.go`.
- **What goes wrong:**
  - **What the guard is for.** The guard (K9c2 section 5) keeps a send for the owner when the account sent the same
    thing in the chat in the 7 days before the window, or when the catalogue does not hold the chat back that far or
    has an open gap. Its reason is that a repeated thing found in the window may be the owner's own repeat, not the
    app's try.
  - **Why it matters more for a file.** A file sent by its Telegram id is exactly how a client re-sends a saved GIF
    or a sticker, and most often with an empty caption.
  - **The case.** The owner re-sends the same document from the phone, with no caption, inside the try's window. It
    settles "arrived" by the app. A text in the same history would be held for the owner.
  - **Open gaps.** The guard's gap check (an open gap of the live monitor) is also skipped. So "alone" may be judged
    on a window the catalogue does not fully hold.
- **Probe:** `TestProbeA2NoRepeatGuard` in `probe_catalog_test.go`. The history holds the same file (no caption) and
  the same text, each sent one day before; the window holds one exact match for each. The send stays "not known";
  the file click is "arrived" ("found in the chat by the app").
- **Fix:** run `settleGuard` for `ActSendFile` too. Its "same thing" is the attachment (kind, tg_id) with the same
  caption, and its unrecorded and gap checks are unchanged.

### F6. A refusal of photos (or of documents) is remembered for every file send to the chat. MINOR. CONFIRMED.

- **Where:** `internal/telegram/act_file.go`, `sendFile` (`mediaWords`, `out.Remember = true`), with R7 keyed on
  (chat, kind sendfile).
- **What goes wrong:**
  - **The wrong file kind is held.** CHAT_SEND_PHOTOS_FORBIDDEN on a photo is remembered for the whole kind. The next
    document to that chat, which that refusal is not about, is refused locally for RefusalFor. The reverse holds for
    CHAT_SEND_DOCS_FORBIDDEN.
  - **Other media words are not remembered at all.** CHAT_SEND_VIDEOS_FORBIDDEN, _GIFS_, _STICKERS_, _AUDIOS_ and so
    on are not remembered. That direction is the careful one.
- **Probe:** `TestProbeA2PhotoRefusalHoldsDocuments` in `probe_telegram_test.go`. After the photo's refusal, the
  document's click is "refused earlier (CHAT_SEND_PHOTOS_FORBIDDEN)" with 0 requests.
- **Fix:** remember only CHAT_SEND_MEDIA_FORBIDDEN. Or remember the photo and document words only against a click of
  the same media kind.

### F7. A captioned file click whose caption is gone would be sent without it. MINOR. PLAUSIBLE.

- **Where:** `internal/catalog/schema_actfile.go`, `FileOfClick`.
- **What goes wrong:** the check refuses a text without the caption flag (`cl.TextKept && cl.Text != "" &&
  !f.Caption`), but not the reverse: the caption flag set and the text gone.
  - **The result:** a queued click with `caption = 1` and `text` NULL fills `act.Text = ""` and sends the file with no
    caption.
  - **Reachable today?** I found no path:
    - `clearOldTexts` clears at 7 days, but queued rows die at 2 minutes;
    - the send-again trigger refuses a cleared caption.

    So this is fail-closed hardening only.
- **Probe:** none (read only).
- **Fix:** add `(f.Caption && !cl.TextKept && cl.State == ActQueued)` to the bad-row condition.

### F8. "Send again" of a click whose caption was cleared answers a raw SQLite error. MINOR. PLAUSIBLE.

- **Where:** `internal/catalog/schema_actfile.go`, the trigger `c_act_file_again`, with `schema_act.go`'s
  `sendClickAgain`.
- **What goes wrong:**
  - **The refusal is not in fixed words.** The trigger's `RAISE(ABORT, ...)` surfaces as an SQLite constraint error
    through `sendClickAgain`, not as `ErrActState` (the fixed "not in that state").
  - **What the page gets.** The door then answers a store failure, where a text send whose text was cleared gets
    "not in that state". Nothing is written, so this is the wording only.
- **Probe:** none (read only; the coder's `TestActFileRowLife` checks only that an error comes).
- **Fix:** add the case to `sendClickAgain`'s own WHERE clause: `sendfile` with `caption = 1` needs `o.text IS NOT
  NULL`. Keep the trigger as the guard behind it.

## Checked and found sound

1. **The order in `sendFile`.** It runs:
   1. form;
   2. R6, R5, R9;
   3. the caption;
   4. the protected record;
   5. R7;
   6. addresses;
   7. the send's wait and slow mode;
   8. the cap;
   9. the read;
   10. the door;
   11. the cap again;
   12. `report` (first check, Begin, then `recheck`, which covers the context, the account's refusal from the
       store and from memory, the kind's wait and the chat's slow mode);
   13. one `sendMedia`;
   14. `End` once.

   - **Never without Begin:** `report` calls `begin` before the send.
   - **Never twice:** `report` sends once. The turn's second `Do` (after `ErrNoLimits`) can only follow a refusal that
     comes before the read.
   - **Never after the account's refusal or a send-kind wait recorded during the read:** `recheck` stops it.

   F1 is the only gap.
2. **The answers to the send:**
   - `FILE_REFERENCE_*` is a refusal: not remembered, not refreshed and sent again;
   - `RANDOM_ID_DUPLICATE` is "sent before";
   - `CHAT_FORWARDS_RESTRICTED` puts the source on the shared record and is not remembered for the destination;
   - `PEER_FLOOD` and `USER_RESTRICTED` go to `answered`.
3. **The source read:**
   - matched by id and peer;
   - a message preferred over an empty copy;
   - `messageEmpty` is "gone", with the deletion told as the reader tells it;
   - a protected message or chat sends nothing.

   An account refusal answered to the read is not recorded as one. That matches `mirror_ids.go`'s reads and is not a
   write.
4. **The turn:**
   - the source row is read, and the file is checked as still held (with its Telegram identity) before any request;
   - a missing source or file is "not sent" with its word;
   - the read's "no"s map through `clickWhy`;
   - a stop leaves the row queued.
5. **The settle's exact match:**
   - **What must match:** the account's own message, the same (kind, tg_id) attachment, the same caption byte for
     byte, the same reply and topic;
   - **What is excluded:** forwards, self-destructing and edited messages;
   - **Other messages and clicks:** `tiedSQL` covers a done file click's `new_msg` (any kind), and other file
     clicks and forward clicks near the window are counted;
   - **Alone:** `judgeSettle` requires exactly one match.

   F5 is the gap.
6. **The step on a catalogue holding rows:**
   - it adds a table and a trigger (IF NOT EXISTS), and refuses any version but its own;
   - it runs after the frame's rebuild of `c_act`, so the trigger is not dropped by it;
   - `TestActFileSchemaStep` checks the trigger exists at SchemaVersion, so a later rebuild that drops it is caught.

   The trigger copies the source row on "send again" in the same statement.
7. **The door:**
   - `file` is set exactly for `sendfile`;
   - the digest covers the file (and every other click's digest is unchanged);
   - a source not held, deleted or not carrying the file is "no message", with nothing written.
8. **Privacy:**
   - every new log line uses a constant format with counts or fixed words;
   - error texts carry fixed words, the type of an error and the ledger's own row number (as elsewhere in the
     ledger);
   - no caption, name, Telegram id or link appears.
9. **Fragile but not a defect:** `Refresher.ask` is called on a nil `*Refresher`. A later change that makes `ask`
   read its receiver would panic in the reader's goroutine; the tests would show it at once.

## Verdict

**May be listed after these fixes:** F1 (must), then F2 to F5 (should). F6 to F8 can go with them or be listed as
known.

F1 is small: the frozen and mirror checks asked again after the read. It breaks two of the stated rules (R5, R9) in
a window that F2 makes minutes long. Everything else holds:
- one write per click, written down first;
- never repeated, and a wait on the send reported and not slept;
- the account's refusal and the cap re-judged at the send;
- fail closed, and nothing private in a log.

## Second look (F1)

Head ef0293ae: the fix round 64c34a5f and the purge line ef0293ae, read against 78a3ad63. Only F1 was looked at
closely, with F2's change looked at in passing. The new probe is `probe_telegram2_test.go` in the same scratch folder,
loaded by `overlay_tg2.json` beside the first round's telegram probes. It was run with `-run 'TestProbeA2|TestActFile'`
and `GOMAXPROCS=2 GOGC=25`, after the CPU was checked under 85%. Every probe and every `TestActFile` test passes.

**1. Frozen, the kind frozen, or the destination a mirror, up to the request.** `fileStanding` asks the frozen
callback, the kind's frozen record and `IsMirror`. It is asked at three points:
- **Before the read.** Nothing is sent.
- **After the read, before the door and Begin.** These probes now refuse with no send:
  - `TestProbeA2FrozenDuringRead` and `TestProbeA2MirrorDuringRead`: requests `read` only;
  - `TestProbeA2bKindFrozenDuringRead`, where the kind's frozen record is written while the read is out:
    `ErrMethodFrozen`, no send, no Begin.
- **Right after Begin.** It runs inside `report`'s `refusal` callback, which `recheck` calls before the request.
  `TestProbeA2bStandingAtBegin` (frozen, kind frozen, mirror, each set by a ledger hook as Begin returns) shows the
  same in all three cases:
  - requests `read` only, no send;
  - the outcome `OutNotSent`;
  - End called once and the row ended "not sent".

  So "not sent" is recorded truly: no request left, and End is written once.

What is left (neither is a defect):
- **Minor: the reason word.** After Begin, a frozen or mirror finding is recorded with the reason `NotSentStore`
  ("record unreadable"), is counted as a store failure, and is logged as "the account's refusal is on record, or
  cannot be read". The state is true; the word is not. A "send again" from it is refused before the read with the
  right word and costs no request. Fix if wanted: a `NotSentStanding` reason (or pass `ErrActFrozen` and
  `ErrActMirror` through `refusedNow`) mapped to the ledger's frozen and mirror words.
- **A residual window of milliseconds.** Between `fileStanding` in `recheck` and the request there are two reads of
  the wait records and the memory-only last look, and the latter has no frozen or mirror state. This is the same
  bound the text step has, where it is wider (R5 and R9 are judged before the door there).

**2. F2's `readOnce`, in passing.** It sends exactly one request with no loop. A wait stated on the read is recorded
and returned as `*WaitRunningError` before the door. Any error returns from `sendFile` before `a.door.lock()`.
`sendMedia` is still sent only inside `report`, after `begin`, once. I found no path to a second `sendMedia` or to a
send without Begin. `TestActFileR1SendNeverRepeated` and the first round's probes, which are now clean, agree.

Two lines that print are not `PROBE:` failures. `TestProbeA2ReadSleepsInTheTurn` now shows `read` with 0 s slept.
`TestProbeA2CaptionOverCaptionMax` shows its caption refused with no request.

**Verdict on F1: fixed.** The reason word after Begin is minor and may be left as known. For F1 and the F2 change,
the branch may be listed.
