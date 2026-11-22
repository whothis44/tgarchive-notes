# Independent review of K22b, alerts away from the PC (Core, 2026-11-22)

Reviewed `wip/core-alerts-away` at dec145e2 against `wip/core-alerts` ecbecda0, in a detached scratch copy (removed
afterwards). Probes were loaded with `go test -overlay` through `runs-core-k5/go2.sh`: named tests only, the local fake
Bot API only, invented data. Nothing ran against Telegram or the real Bot API. No file in the coder's copy or on any
branch was changed.

## Verdict

**It may be listed after these fixes: F1, F2 and F3 (must), then F4, F5 and F6 (should).**

What holds:
- The owner check: user id and chat id both, plus the nonce in `/start`.
- Edited messages are kept out (`allowed_updates` asks for "message" only).
- Each update is taken once, before anything is done.
- Commands older than 10 minutes are refused.
- `allow` and `yes` hold for: no allow, a wrong code, a late yes, a yes sent twice, two allows.
- `pause` cannot shorten a longer pause the owner set (`pauseByOwner` keeps it). Only `resume` ends a pause.
- The token never appears in an error, a log line, a door's answer, the catalogue or a backup. `internal/backup` copies
  only files named `account-<n>.session`.
- There is no proxy and no redirect. Every request asks `DialCheck` first.
- The click path's guards are unweakened: `queueClickBy` runs every check that `QueueClick` runs.
- The words are fixed text and numbers. A chat name is added only when the setting is on.

## Findings

**F1 (must, CONFIRMED, probe P7): the cap of 20 an hour counts only sends that went, not requests asked.**
- Where: `internal/collector/alertaway.go:261-265`, together with `internal/catalog/alertaway.go:153`
  (`... AND sent = 1`).
- What happens: a refused or failed send costs a request but not a place under the cap. Each look then asks up to `left`
  more, and the back-off is per alert.
- Probe result: with the cap at 2 an hour, 10 open alerts and every send refused with 400, **40 `sendMessage` were asked
  in one hour**.
- Fix: count every row that asked (`Counted`, sent or not) toward the cap. Also end the channel's turn at its first
  refusal that is not a stated wait.

**F2 (must, CONFIRMED, probe P1): a 429 on the bot's answer to a command is neither stored nor obeyed.**
- Where: `internal/collector/alertbot.go:370` (`_ = cl.SendMessage(...)`).
- Probe result: after a 429 with `retry_after` 600 on the first answer, the second command in the same batch was
  answered at once (2 requests), and no wait was stored.
- Fix: treat the answer's error as `sendAway` does. Store `retry_after` under `alert.wait.bot` and stop answering the
  batch. Also check the stored wait before each answer.

**F3 (must, CONFIRMED, probes P2 and P3): the "send a test alert" door ignores the stored wait and the cap.**
- Where: `internal/collector/alertaway.go:509-539`.
- Probe results:
  - Inside a stored wait of 3,600 s, the test button asked `sendMessage` anyway, and it went.
  - With the cap at 1 and 1 already sent, 5 presses sent 5 more (6 in the hour).
- The same holds for the setup doors. `getMe` (`alertbot.go:145-155`) and the setup `getUpdates` (`alertbot.go:199-206`)
  neither check nor store a stated wait. A 429 on `getMe` is reported as "the token was refused".
- Fix:
  - In `SendAlertTest`, refuse in fixed words while `channelWait` holds or the cap is reached.
  - In the two setup doors, check and store the wait, and give a 429 its own word.

**F4 (should, CONFIRMED, probe P5): the poll goes deaf when the bot's update ids drop below the newest one taken.**
- Where: `internal/catalog/alertaway.go:286-295`, `internal/collector/alertbot.go:319` and `alertbot.go:166`.
- Why: the poll's offset is `MAX(update_id)+1` over everything ever taken. `c_bot_update` is not cleared when a new
  token is set. Telegram's own documentation says that after a week without updates the next update id is chosen at
  random, not in sequence. A new bot also has ids of its own.
- Probe result: an update with id 1,000,000 was taken, then the owner sent `pause 3`, which got a lower id. It was
  dropped unseen: not acted on, not answered, and confirmed away at the fake.
- This fails closed (nothing wrong is done), but two-way goes silent with no sign of it.
- Fix:
  - Reset the table and the offset when a new token is set.
  - Take the offset only from the last answer of this run.
  - At start, ask from offset 0 and judge "taken before" by the update id and the message's date together.

**F5 (should, CONFIRMED, probe P4): on the Saved Messages channel, alerts about the chosen account starve every other
alert.**
- Where: `internal/collector/alertaway.go:277-284`.
- Why: those alerts are skipped (`continue`) with no record. `AlertsDue` keeps giving them first (oldest first, at most
  `left`), so they fill the list on every look.
- Probe result: with the cap at 2, two open alerts about the chosen account, and a third alert about no account, the
  third never got a row on the Saved Messages channel in 20 looks.
- Fix: leave the chosen account's alerts out of the query (`account_id IS NOT ?`), or record them once with
  `outSameAccount` and no later retry.

**F6 (should, CONFIRMED by reading): the door that lists a chat's clicks does not [name removed] made a click.**
- Where: `internal/catalog/schema_act.go:396-436` and `ChatClicks` at `schema_act.go:1280`. `ActClick` and `actCols` have
  no `made_by`, and `grep` finds `made_by` only in the writes.
- `ChatClicks` (collector `click_api.go:850`, the server's click route and the viewer's act door) lists every row of the
  own chat.
- Effect: in Saved Messages, an alert's click shows as the owner's own send, including its "not known" state, with
  "send again" and the verdict buttons.
- Fix: add `MadeBy` to `ActClick` and to `actCols` (and to `Click`). The pages should then mark these rows "sent by the
  app's alerts".

**F7 (minor, PLAUSIBLE): a forwarded message is acted on like one the owner typed.**
- Where: `internal/botapi/botapi.go:93-99` reads no `forward_origin`, and `alertbot.go:348` does not look for one.
- Effect: a forwarded text such as "allow abcd" or "pause 3" in the owner's chat counts as a command. Only the owner can
  do this, so the risk is low.
- Fix: read `forward_origin` and `via_bot`, and pass over any message that has either.

**F8 (minor, PLAUSIBLE): the Start link's nonce stays good after the chat is found, and never expires.**
- Where: `alertbot.go:191-238`. `keyBotStart` is kept, and its time is never checked.
- Effect: if the owner presses "find the chat" again, anyone who learned the link and pressed Start alone becomes the
  owner.
- Fix: clear the nonce once the chat is stored, and refuse a nonce older than, say, an hour.

**F9 (minor, PLAUSIBLE): the poll's pace has no lower bound on success, and a revoked token is asked forever.**
- Where: `alertbot.go:341` and `alertbot.go:330`.
- Effect:
  - An empty answer that comes back at once is asked again at once.
  - A 401 is asked again every 30 s without end (about 120 an hour).
- Fix: keep at least about 1 s between polls. After a 401, stop until the token is set again, and show that on the
  page.

**F10 (minor, PLAUSIBLE): a command can still be acted on after the bot is cleared.**
- Where: `alertbot.go:243-257` and `alertbot.go:337`.
- Effect: `ClearAlertBot` does not end a poll already in flight. For up to 50 s, commands that arrive are still acted on
  and answered with the old settings.
- Fix: re-read the bot's setting before each update is acted on, or cancel the poll's context when the bot is cleared.

**F11 (minor, PLAUSIBLE): a Saved Messages send can stay refused forever.**
- Where: `alertaway.go:388-393`.
- Effect: the click's key is fixed by the alert and its send number, but its form covers the text. If the text changed
  after a kill (names turned on, or a chat's title changed), every retry gets `ErrClickKey` and the alert is never sent
  on Saved Messages.
- Fix: put the text's digest in the key, or treat `ErrClickKey` as "sent before".

**F12 (minor, by reading): the token file's permissions do nothing on Windows, and the bot client looks up names
itself.**
- Where: `alertbot.go:157` and `botapi.go:146`.
- Mode 0600 has no effect on Windows. The file is protected only by the folder's access list under `%LOCALAPPDATA%`.
  `os.WriteFile` also keeps the mode of a file that already exists.
- The client resolves `api.telegram.org` through the system's name lookup, while the collector's own connections ask
  no name.
- Fix: note both in the report. Optionally write the file through a temporary file and a rename, and check that the
  name lookup stays inside the VPN.

Notes (no change asked):
- A Saved Messages alert counts as "sent" once it is queued. A click that later ends refused or "not sent" is not tried
  again for 12 h (the coder's point 5).
- `DROP TABLE c_alert_sent` cannot lose anything on a K22 file, because nothing on ecbecda0 writes that table (checked
  with `git grep`). If rows were there, at worst an open alert would be sent once more.
- `allow` on an alert that was seen but has not ended is accepted. That is right: its mirror is still blocked.

## The client track's three questions on `c_act.made_by`

1. **The click cap is shared: confirmed.** `ClicksSentSince` (`schema_act.go:1080`) does not filter on `made_by`.
   - The scheduled sender keeps alerts to at most PerHour an hour (default 20).
   - One look can queue up to 20 at once: up to 20 of the click cap's 30 per 5 minutes, and 20 of the account's 50
     queued places (`ActQueuedMax`).
   - **The test button has no bound (F3).** The 20-an-hour bound holds only once F3 is fixed. Above that, the bound is
     whatever the owner sets.
2. **The click list does not carry `made_by`: confirmed, finding F6.**
3. **The settle cannot match an owner's own "not known" send: refuted by reading** (`act_settle.go` header and rules).
   - The match is the text byte for byte, and an alert's text carries the app's prefix and the alert's own random code.
   - If an owner's click with the same content is waiting, "another click with the same content waits" blocks both,
     whoever made them.
   - A 12-hour resend of the same alert falls under the 7-day repeated-text guard, so the app never settles it; the
     owner decides. That is the careful side.

## Concurrency

No data race was found by reading:
- `away.strangers` and `away.polls` are atomic.
- `away.fail` is used only by its own task.
- Settings go through the catalogue's writer, and the token through its file.
- A Bot API client is made per call.
- `c.account` and `alertState` take their locks.

No test runs the two tasks against the doors at the same time. To run under the race detector (collector only):
- `-run 'TestAway|TestBot'`;
- a new test that starts `Run` with a bot set, then calls `SetAlertBotToken`, `ClearAlertBot`, `SendAlertTest` and
  `SetAlertSavedAccount` from other goroutines while both tasks run.

## Probes and results

The file `zz_probe_test.go` was loaded by overlay into `internal/collector`. It was run once, with
`-run TestProbe -count=1`, and took 2.2 s. Each probe failed as written, which confirms its finding:

| Probe | Finding | Result |
|---|---|---|
| P1 `TestProbeAnswer429NotStored` | F2 | 2 answers asked after a 429 of 600 s; no wait stored |
| P2 `TestProbeTestButtonIgnoresWaitAndCap` | F3 | inside a stored wait of 3,600 s: 1 `sendMessage` asked ("sent") |
| P3 (same test) | F3 | cap 1, already 1 sent: 5 test presses sent 5 more (6 in the hour) |
| P4 `TestProbeSavedStarvedBySameAccount` | F5 | the other alert: 0 rows after 20 looks |
| P5 `TestProbeUpdateIDBelowStoredMax` | F4 | `pause 3` with an id below the newest taken: not paused, not answered |
| P7 `TestProbeCapCountsOnlySuccesses` | F1 | cap 2 an hour, every send refused: 40 `sendMessage` in the hour |

## Second look (fix round: `wip/core-alerts-away` 5dd29d01, fixes 9f791091)

**Verdict: may be listed. F1, F2, F3, F4 and F11 are fixed. Of three small new findings, S1 should be fixed before
listing or with the next piece; S2 and S3 are minor.**

This look covered only three questions: (1) waits and the cap, (2) the update record, (3) the Saved Messages key. I
read the fix diff for those three. I ran seven probes through `go2.sh`, overlay only, against the local fake Bot API;
they took 1.8 s in all. The scratch copy is removed.

### (1) Waits and the cap: fixed

No path still asks the Bot API inside a stored wait or past the cap. The re-run probes all pass:

| Probe | Path | Result |
|---|---|---|
| P1 | answers to commands | after a 429 of 600 s, 1 answer was asked; the wait is stored; the next turn asks nothing |
| P2 | test button | inside a stored wait it asks nothing (`ErrAwayWait`) |
| P2b | setup | `SetAlertBotToken` inside the wait asks no `getMe` (`ErrBotWait`) |
| P3 | test button at the cap | 0 more sent in 5 presses (`ErrAwayCap`) |
| P7 | every request counts | 2 `sendMessage` in the hour with a cap of 2, every send refused |
| P10 | after a 401 on the poll | 0 more calls over 18 minutes of polls and sends; the test button answers "not set" |

By reading:
- `FindAlertBotChat` checks and stores the wait.
- `botUpdate` checks the stored wait before each update. Commands that arrive during a wait stay untaken and come back
  after it. A wait longer than 10 minutes turns them into "stale" answers, which is the design.
- Answers to commands are still outside the cap, one per owner command. That is by design (the coder's point 6), and
  strangers are never answered.

Two small leftovers, both minor and PLAUSIBLE:
- **S2: the cap can be overshot by one.** `SendAlertTest` and the sender task each read the count, then send
  (`alertaway.go:258-279` and `SendAlertTest`).
- **S2: one request can land inside a fresh wait.** The sender's loop checks the stored wait once per channel turn. A
  wait the poll stores in the middle of that turn is not seen until the next send's own 429.
- Fix for both: take one lock (or one catalogue step) around "read the count and the wait, ask, record".

### (2) The update record: fixed for restarts and quiet weeks, with one narrow way to act twice

What holds:
- Updates are now recorded by id and message date together, and the offset is the run's own, kept in memory.
- **P8: a restart before the batch was confirmed does not act twice.** The command came back with offset 0, was
  recognised, and was not answered or acted on again.
- **P5b: a lower id is seen after 6 days and 2 hours of quiet.** `pause 3` was acted on.
- Within a run, Telegram keeps its ids in sequence. The 6-day reset comes before its 7-day rule.
- By design, nothing is lost for ever except an update already taken when a kill comes. Deferred updates (a stop, a
  wait) stay unconfirmed and come back.
- Pruning the record cannot cause a second action: anything Telegram could give again is older than the 10-minute stale
  guard.

**S1 (should, narrow, CONFIRMED by probe P9): pasting the same token again can act on one command twice.**
- Where: `alertbot.go:187-190`. `SetAlertBotToken` empties `c_bot_update` for any token, even the same bot's.
- Probe result: `pause 3` was acted on, the same token was set again a minute later before any poll confirmed the
  batch, and the next poll from offset 0 took `pause 3` as new. It was recorded twice and paused again.
- When it can happen: in a live run the next poll confirms the batch at once. The window is open only while the poll
  is stopped (a stated wait, a refused VPN check) and within the 10 minutes before a command goes stale.
- Why it matters anyway: most commands are harmless to repeat. A `resume` replayed after the owner paused on the page
  in between would end the owner's own pause (TRIED-BEFORE rule 1).
- Fix: empty the record only when `getMe` answers another bot id than the one on record. Store the bot id with the
  setting.

**S1b (minor, PLAUSIBLE): a poll in flight can leave the old bot's offset in place.**
- Where: `alertbot.go:419` against `alertbot.go:190`.
- What happens: if `SetAlertBotToken` runs between `botUpdate`'s check and `offset.Store(id+1)`, the old bot's offset
  survives into the new bot. It stays until 6 quiet days have passed.
- Fix: keep a bot generation with the offset, and store it only when the generation still matches.

### (3) The Saved Messages key: one send never becomes two clicks (confirmed by reading)

Why it holds:
- The key is the alert's id and its send number. The send number moves only when a send is recorded, so a send not yet
  recorded uses the same key.
- `queueClickBy` answers a known key with its click, and the `ErrClickKey` path now looks the click up the same way.
- Two writers racing on one key: the second reads the key again and gets the first one's click.
- The test button always uses a new test alert.

The only way to a second click is a change of the setting naming the account. That makes a new click on the other
account, which is the owner's choice.

**S3 (minor, PLAUSIBLE, by reading): a send the ledger says "not sent" can be counted as sent.**
- What happens: a click queued before a kill is marked "not sent" at the next start (`SweepClicksAtStart`). The sender
  then finds its key and counts it as sent. The alert does not reach Saved Messages until its 12-hour resend.
- Fix: when the known click is in a state that never went out ("not sent", cancelled), send it again through
  `SendClickAgain` on that click, which keeps `made_by`, rather than counting it.
