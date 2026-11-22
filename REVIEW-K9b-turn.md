MAY BE LISTED AFTER THE MUST-FIXES

# Independent review of K9b, the click's turn (`wip/core-turn` at dc5bb4fb, against 51fc8160)

Reviewer: one independent reviewer, 2026-11-16 night. Read-only on the tree; nothing committed. Probes live in the
scratch folder `wt-core-turn-review-scratch` (`zz_review_k9b_test.go`, loaded with `go test -overlay overlay.json`),
with their outputs `run1.txt` to `run5-existing.txt`. Every request counted below was counted at the fake
(`srv.Requests()`, `CountByKind`), never from the collector's counters. All data invented.

Counts: **2 MUST FIX** (both CONFIRMED), **1 SHOULD FIX** (CONFIRMED), **6 MINOR** (1 confirmed by reading, 5
PLAUSIBLE). Lines are relative to `archiver/`.

## Findings, most serious first

### 1. MUST FIX, CONFIRMED: a queued click cuts the reader's own pause before a RETRY, and the reader asks again at once

- **Where:** `internal/collector/click.go:710-745` (`readerClock.Sleep` cuts any sleep of a history read, so also
  the pause of `internal/telegram/call.go:304-313`), with `click.go:336-338` (`more`) and `click.go:723`
  (`pending` cuts at once, without sleeping at all).
- **What happens to the owner:** while Telegram answers the reader's history requests with server errors,
  timeouts or a lost connection, every click (and every round of a queue longer than 5) makes the reader send
  the next history request at once instead of after its doubling back-off; the call's retry count starts over,
  so it never gives up and never pauses the chat ("retries exhausted", then `chatFailed`): the app asks a
  struggling server many times more often, the pattern the lessons warn against. A stated wait is on record and
  is slept again (`held`); **a retry pause is not on record anywhere**, so the claim in the code's comment
  (click.go:16-20, 689-699) and in the brief (3.2.3: "the wait itself is on record ... nothing is asked early")
  is false for pauses.
- **Probes:** `TestReviewRetryPauseCut` (run1.txt): "6 of 6 clicks made the reader's next history request leave
  before its retry pause ended: [1529 ms early (pause end 1592 ms after the click) 1831 ms early ...]"; "history
  requests to a server answering errors in 120 s of the clock: **5 without clicks, 70 with 35 clicks** (one every
  3 s)". `TestReviewQueueSpinsReader` (run4.txt): 200 clicks queued at once (the cap at its default, so 5 sent, the
  rest "not sent" without a request): "drained in 5013 ms of the clock; **27 history requests to the failing
  server meanwhile, the closest two 80 ms apart** (the reader's own first retry pause: 2000 ms)". Nothing in the
  turn bounds the queue (a page fault queued 1070 clicks in P3b's first run, none refused).
- **Smallest fix I would accept:** cut only a stated wait's sleep: in `readerClock.Sleep`, cut only when the
  Reader's state shows `WaitingUntil` set (the `waiting` hook runs before the sleep, call.go:66-69) and
  `PausedUntil` zero; a pause before a retry is slept as before (at most `RetryPauseMax`; the click waits). Or,
  if the pause is to be cut, carry its end into the chat's `backoff` (reader.go, `st.backoff[chat] =
  PausedUntil`, no doubling, no "failed" line) so that the next request of that chat waits for it. A test: the
  fake answering 500, a click during a pause, no history request before the pause's end (P2 inverted).

### 2. MUST FIX, CONFIRMED: a click queued while the account's session ends goes out in the NEXT session

- **Where:** `internal/collector/click_api.go:364` (`runningSession` only checks `a.sess != nil`) and `445-450`;
  `internal/collector/reader.go:297` (`defer s.clicksStopped(cat)` runs when the reader task ends, while
  `account.go:1170-1204` (`close`) keeps `a.sess` set through the flushes, the client's close and the grace);
  `click.go:641-662` (`clicksStopped` stops after `catalog.ActSentMax` = 1000 rows or 5 s). The next session's
  step sweeps only by age (2 minutes), so anything still queued goes out.
- **What happens to the owner:** a click made as the VPN or the connection drops (or any session end) is
  answered "queued", the old session never sends it nor marks it, and the next session (5 s later in the rig,
  `GateRetryMin`) sends it: against the brief's rule 4 ("nothing that was queued ... before a stop is sent after
  it") and "a click must never sit waiting for a sign-in". With more than 1000 queued (no queue bound exists) the
  rest goes out after a reconnect the same way.
- **Probes:** `TestReviewOrphanSentNextSession` (run1.txt): a row queued while no session ran "ended "done" ...
  sent 5088 ms of the clock after it was queued; sends at the fake +1". `TestReviewQueueRaceAtSessionEnd`
  (run3.txt, `-count=3`, the real `QueueClick` called back to back after `KillConn`, fewer than 1000 queued so
  the bound plays no part): **3 of 3 runs**, "2 clicks queued during the session's end ... end states
  map[done/:2]; 2 begun after the old session was gone" (then 1 and 1); `clicksStopped` logged nothing (it found
  none queued), so these were queued after it ran. Its first version (run1.txt, unthrottled): 1070 queued, 1000
  marked "not sent", 70 sent by the next session (the bound and the race together).
- **Smallest fix I would accept:** the session's first clicks' step (or `runSession` before the reader task
  starts) marks "not sent" (`ActWhyStopped`) every click of the account still queued with `clicked_ms` before
  the session began; or `NextClick`/the turn takes only clicks queued at or after the session's start. That
  covers the race, the 1000-row bound and a slow `clicksStopped` alike. A test: P3a as a regression test.

### 3. SHOULD FIX, CONFIRMED: a click during a channel gap's read counts as a failed read, and penalises every open gap

- **Where:** `internal/collector/reader.go:690` (`if fired || err != nil { return false, err }`: a cut pass
  returns `context.Canceled`), then `reader.go:528-529` (`s.chatFailed(-g.ID, err)`), and the gap loop goes on
  to the next gap while `click.wake` is still set (`reader.go:509-531`, the wake check only at `535`), so each
  further gap read's sleep (`held` sleeping the same recorded wait) is cut at once (click.go:723) and penalised.
- **What happens to the owner:** one click makes every open channel gap wait 1 minute (doubling to an hour on
  repeats, `chatFailed`) and logs "a read failed (context canceled)" for each; gaps are the monitor's missed
  updates, read first on purpose. No request is early (the fake's check passed).
- **Probe:** `TestReviewGapCutPenalty` (run1.txt, run2.txt): "open gaps 2; click begun 47 ms after queueing; 'a
  read failed' lines before the click 0, after 2; lines: [... a read failed (context canceled); that chat waits
  60 s ×2]"; then "the wait ended 59615 ms after the click; the first history request after it left 60646 ms
  after the click", `noViolations` passed.
- **Smallest fix I would accept:** in `readGap`'s channel path, `if fired { return false, nil }` (as its common-box
  path and `readTurn`'s history path already do), and in `readTurn`'s gap loop return `(true, time.Time{}, nil)`
  after a fired gap read (the loop comes round to the clicks' step) instead of going on to the next gap.

### 4. MINOR, PLAUSIBLE: `wake` outlives the click it was set for

- **Where:** `click.go:292` clears `wake` only at the top of the step; a click queued while another click's
  request is out sets it (`click_api.go:450`), is taken by the same step's loop (`click.go:321-333`), and `wake`
  stays set. **What happens:** the next round's `readTurn` skips the automatic mirror's turn once
  (`reader.go:535`), and a gap read's sleep before that check is cut with no click queued (feeding 1 and 3).
  **Fix:** have `readerClock` cut only when a click is really queued (e.g. the step records the last ref it
  found and `QueueClick` bumps a counter; cut when the counter moved), or accept and say so.

### 5. MINOR, PLAUSIBLE: the watchdog can cancel a click's pass in a narrow window

- **Where:** `reader.go:303-311`: `r.Stalled(...)` is read, then `st.cancel` under `passMu` separately; if the
  reader's stalled call is answered between the two and the loop has reached a click's `pass`, the click's pass
  is cancelled. **What happens:** the click ends "not sent" (unclassified, before Begin), "not sent" (cancelled
  after the mark) or "not known" (its request cut): each true; no second request. The coder's "by construction"
  (report section 3) holds except for this window. **Fix:** `pass` takes a flag "reader call"; the watchdog
  cancels only a pass so flagged (the clicks' step and `clickLimits` call an unflagged pass).

### 6. MINOR, CONFIRMED by reading: the owner's cancel racing the turn is counted and logged as "begun by another turn"

- **Where:** `click.go:422-426` and `467-481`: a cancel between `NextClick` and `Begin` makes Begin's
  compare-and-set fail (`ErrClickSpent`); `clickSpent` reads the row, finds "not sent / the owner cancelled",
  which is not "too old", and counts `click.spent` with `clickLineSpent`. Nothing is sent. **Fix:** a third arm
  for `ActWhyCancelled` (its own count, no line), or count by the row's `why` as `clickBegun` does.

### 7. MINOR, PLAUSIBLE: smaller things found by reading

- (a) `click.go:427-433`: `End` failing after an `OutNotSent` (no request, `Requests` 0) makes the row "not
  known (the outcome could not be recorded)". Conservative, but the owner is told a request may have left when
  none did. Fix: when `out.Requests == 0`, say "not sent" (a ledger door from "sending" to "not sent") or accept.
- (b) `reader.go:297` with `supervisor.go:59-64, 84-104`: a panic in the reader task (it is restarted alone
  within the session) runs the deferred `clicksStopped`: queued clicks become "not sent: the program stopped"
  while the session runs on; a panic inside `Do` between Begin and End leaves the row "sending" for the rest of
  the run (shown as "not known" only at the next start). An old reader task that outlives `SessionGrace` marks
  the next session's queued clicks the same way. Wrong words only; Begin's compare-and-set prevents a second
  request. Fix: run `clicksStopped` only when the task's context ended.
- (c) Uncut waits the report's list misses: a history request that is out without an answer waits up to
  `RequestTimeout`, 2 minutes by default (the run command sets none: `account.go:529`), which equals
  `clickMaxAge` (`click.go:48`): a click queued then will usually end "not sent in time". The chat list's stated
  wait (up to `MaxWait`, 1 hour) is listed by the coder. Fail-safe; say it on the page, or bound the reader's
  request timeout below the click's age bound.

## The fake Telegram: where it is kinder than Telegram

- `ErrActLost` answers an error and keeps the connection; a real lost connection ends the session
  (`conn.Done`, `endConnLost`), so "the answer lost and the session ending at once" (End racing the close, the
  others marked by `clicksStopped`) is never exercised. `KillConn` exists for it (used by my P3).
- No 48-hour edit limit, no write rights, no slow mode or protected source unless scripted (a forward from a
  protected source succeeds at the fake). The code's handling of those words is the request layer's and is
  tested there.
- The fake's transport does not model the library's own re-send of an unacknowledged request at the MTProto
  level; "one request at the fake" cannot see it (not checked; random ids and idempotent kinds limit the harm).

## Checked and found sound (do not check again)

- **One click, one request:** Begin's compare-and-set (`catalog/schema_act.go:701-702`) is the guard; the second
  `Do` (`click.go:410-420`) only follows `ErrNoLimits`, which `Do` returns only from `limited`
  (`telegram/act.go:928-946`), before Begin; a second `Do` of a begun click gets `ErrClickSpent`. Every Actor of
  an account shares the door. No path found that sends one row twice, also across two sessions.
- **The cut never reaches a click's request:** it happens only inside the Reader's own `Sleep`; the Reader is not
  running during `Do`, so `Stalled` is false (save finding 5). `TestClickRequestNotCancelled` agrees.
- **Stated waits after a cut:** put in memory (`stated`) and in the record (`takeWait`) before the sleep; the next
  request sleeps the rest (`held`). P1 confirmed it with two gaps and the fake's own violation check.
- **readerClock's lock and flags:** no lost wake-up (`wake` is stored before the lock; `Sleep` registers and reads
  the flags under it); no wake for another sleep (one reader goroutine; the stop is unregistered under the lock);
  a sleep registered after a cancel returns at once.
- **`autoTurn`** (mirror_auto.go:398-411): statement for statement as before except the Forwarder's source; the
  same `ForwardConfig`; the secret is `AutoMirrorSecret` whenever it is 32 bytes (`click.go:114-126`), which
  `startAutoMirror` requires. With the mirror off the Forwarder serves only `Limits` (bounded by
  `autoConfigBound`) and the Actor's `report`, which never sleeps.
- **No click ever queued:** `wake` is never set, `readerClock` passes every sleep through; `readTurn` and
  `readerTask` take the old paths; cost one `NextClick` (`hasAct` from memory on the writable handle, one indexed
  query) per loop round and one at the task's end.
- **The own-message rule:** private chats and basic groups use per-account spaces (`catalog/tgrows.go:143-155`),
  so `outgoing` is the account's own; supergroups and forums by sender; broadcast and any unknown kind refused;
  not held or deleted refused; the same number in another chat is another space.
- **Random ids:** crypto random, never 0, one per message, unique within a forward (`shape`), copied by
  `SendClickAgain` (`schema_act.go:1135-1162`).
- **Settings:** exact round trip, bounds, an overflow guard on the window; unreadable values stop clicks with a
  fixed word, said once; mark as read checked at the door and the turn.
- **Privacy:** every new log format is constant (kind, state or reason words, the catalogue's account number,
  milliseconds, counts); count names are fixed words; the new errors are fixed words (`words.go`).
- **The secret file:** the same `forward.secret` as the mirror command and `run -auto-mirror`, made with
  `O_EXCL`, mode 0600, never replaced; a wrong size fails closed.
- **The self peer:** only a user chat whose id is the account's own user id.

## Existing collector tests run (not in the coder's list)

Named, at this head, unchanged tree (run5-existing.txt): `TestReaderWatchdog`, `TestGapsBecomeRangeReads`,
`TestMirrorReadsOpenGap`, `TestCommonGapCostBounded`, `TestOwnerStopEndsSession`, `TestSupervisorPanicRestartsAlone`,
`TestKillRestart`, `TestGateLostAndBack`, `TestOneClientSessionRestart`, `TestSignedOutStopsAlone`,
`TestMirrorAutoSettleRun`, `TestChalReaderKeepsAskingAfterGateLostWhileEngineStops`, `TestMethodFrozenEndsMethodOnly`:
all ok, 137 s in the package. (They queue no click, so they cannot show findings 1 to 3.)

## Could not check

- The race detector (not allowed here) on the new shared state (`click.wake`, `click.more`, `sleepMu`); the whole
  `internal/collector` package.
- Real Telegram's answer shapes (a basic group's send answer; whether edits beyond 48 hours matter).
- The library's MTProto re-send of unacknowledged requests (above).

## Where the brief or the design is wrong or silent

- **Brief 3.2.3 is wrong for pauses:** "a pause before a retry ... is cancelled ... the wait itself is on record
  and is slept again ... nothing is asked early": a retry pause is not on record (finding 1). Its test asked only
  for a stated wait.
- **Brief 3.2.2's bound of 5 a round "so that a queue can never starve the reader"** protects the reader's turn
  but, with the cut, makes it spin (P2b).
- **The brief is silent on the window between the reader task's end and the session's end** (finding 2) and on
  the 1000-row bound of the session's sweep; the design's rule is clear.
- **Design section 3 step 2** has the door refuse at once (a mirror, a wait running, the cap, the text, no access
  hash); the brief moved these to the turn, where they become "not sent" rows within milliseconds. Fine for the
  page if piece 3 reads the row back; say so in piece 3's brief.
- **Design section 4:** "a forward counted by its messages against the mirror's hourly bound" is not built (the
  report's 1d) and the mirror's pause after a click (3.2.4) is a marked gap with a skipped test; both wait for the
  mirror track. Until then a click does not slow the automatic mirror.
- **Design section 4 "It also bounds what a fault in a page could do":** the cap bounds requests, not the queue;
  nothing bounds how many clicks a page may queue (P3b queued 1070); with finding 1 a long queue becomes reader
  requests. A queue bound at `QueueClick` (say the cap's window count) is cheap.

## Second pass (the fix round, 8977dc2c)

MAY BE LISTED AFTER THE MUST-FIXES

The second pass covers only `git diff dc5bb4fb 8977dc2c`. The tree is read-only and unchanged. I measured free
memory before each go command (6,465 MB or more). The scratch folder holds:
- `zz_review_k9b2_test.go`: the first pass's probes, renamed, plus the new P2c, loaded with `overlay2.json`;
  output in `run6-second.txt`;
- `undo/click.go` and `undo/reader.go`: findings 1, 2 and 3 undone, loaded with `overlay-undo.json` to run the
  coder's tests; output in `run7-undo.txt`.

All requests were counted at the fake.

### 1. The nine findings

| # | Status | By code, and by a test that fails with the fix undone |
|---|---|---|
| 1 | **PARTLY** | **The pause itself is closed.** `statedWait` (`click.go:774-776`) never cuts a pause. With only that line undone, `TestClickRetryPauseNotCut` fails ("a history request left 1492 ms before its pause's end") and `TestClickQueueNoSpin` fails ("27 history requests ... 102 ms apart"). **What is still open:** a cut of a stated wait inside a retry chain restarts the chain (new finding N1). |
| 2 | **CLOSED** | `ending`, `runningSession`, `queuedFor` and `StopClicksBefore` at the first step. With only the `StopClicksBefore` call undone, `TestClickQueuedBetweenSessions` fails ("done", sends +1). My P3a now ends "not sent (stopped)" with sends +0. P3b now gets 0 clicks in (the session refuses at once). Two leftovers by reading: N2 and N4. |
| 3 | **CLOSED** | `errPassCut` (`reader.go:639`, 686, 718) and the gap loop's return (`reader.go:539-542`). With the channel path undone, `TestClickGapCut` fails ("2 failed reads"). My P1: 0 "a read failed" lines, no request inside the wait. |
| 4 | **CLOSED** | `wakeGen` and `stepGen` (`click.go:309-310`, 779). `TestClickWakeOnce` (the coder saw it fail first; I did not undo it). |
| 5 | **CLOSED** by code | `cancelReaderPass` reads the cancel and the owner under one lock (`reader.go:248-257`). `clickPass` is used only by the clicks' step (`reader.go:395`). The test (`TestClickWatchdogSparesClickPass`) checks only the new door, not the watchdog's use of it: it would not fail with the old watchdog lines put back. |
| 6 | **CLOSED** | `clickSpent`'s cancel arm (`click.go:521-533`). `TestClickCancelRaceCounted` calls `clickSpent` directly. |
| 7a | **CLOSED**, as briefed | `click.go:471-481`. `TestClickNotSentEndLost`. The row stays "sending" for the rest of the run, and the next start's sweep then shows it "not known" all the same. Accepted in the brief. |
| 7b | OPEN, accepted | A panic restart of the reader runs `clicksStopped` (report 9, row 7b). |
| 7c | OPEN, accepted | The click's age bound equals the request timeout (report 9, row 7c). |

### 2. Must-fix 1 again, with requests counted at the fake

- **P2 on the new head:** 0 of 6 clicks made a history request leave before its retry pause ended. The
  coder's `TestClickRetryPauseNotCut` counts 5 history requests in 120 s with clicks and 5 without. In my run the
  count window came after the chat's retries were exhausted, so it saw 0 and 0.
- **P2b on the new head:** 200 clicks drained in 125,777 ms of the clock, because they now wait behind the
  pauses. Meanwhile 6 history requests went out, the closest two 4,025 ms apart. That is the reader's own back-off;
  the probe's naive threshold ("more than 3") flagged it, but it is not a spin.
- **The gap loop's early return** skips no read. The gap stays open and is first in the next turn, and `held`
  sleeps the rest of the recorded wait without a cut, because nothing is pending after the step. If the clicks
  cannot be taken (clicks off, a step that fails, a store that cannot be read, the cap closed), every exit of the
  step sets `stepGen`. The pending state therefore lasts at most one round per queued click, and nothing loops
  without idling. `more` alone cuts only a stated wait, never a pause, so it adds no request.
- **One way remains: N1 below.**

**N1. MUST FIX, CONFIRMED: a click that cuts a stated wait inside the reader's retry chain restarts the chain.**
- **Where:** `click.go:781-815`, `statedWait` at `click.go:774-776`, and `internal/telegram/call.go:240-318`.
  A cut ends the history call. The next call starts with `retries` 0 and `pause` equal to `RetryPause`.
- **What happens to the owner:** while Telegram mixes server errors with short stated waits, every click turns
  the reader's doubling back-off (2, 4, 8, 16, 32 s) back into 2 s. The reader then asks a failing server several
  times as often, and never reaches "retries exhausted" (the chat's pause). No request goes inside a stated wait.
- **Probe `TestReview2CutResetsRetryChain`** (run6-second.txt): "history requests in 150 s of the clock to a
  server alternating a 500 and FLOOD_WAIT 8: **10 without clicks**, **27 with 28 clicks** each cutting a stated
  wait". `noViolations` passed in both rigs.
- **Smallest fix, in the collector only:** `readerClock` notes when the running reader pass has slept a pause
  before a retry (a `Sleep` whose state shows `PausedUntil` set). `run` resets that flag when a reader pass
  begins. A stated wait is cut only in a pass that has not paused. A click then waits behind a retry chain, as it
  already does behind a pause (item 6).
- **Test:** P2c as a test, with the same count with clicks as without.

### 3. Must-fix 2: any order of events left?

- **A click queued just before `began`:** `began` is set when the session object is made, before `a.sess` is set.
  So a click whose door check passed against the new session has `clicked_ms` at or after `began` and is never
  stopped. A click for an older session has `clicked_ms` before `began` and is stopped by the first step, which
  takes nothing until it has worked.
- **"Send again":** its row's `clicked_ms` is the time of that call. Same as above.
- **The first step failing:** it is retried each round. It takes nothing meanwhile. Clicks of this session are not
  touched by the later sweep.
- **Two sessions at a reconnect:** an old reader that outlives the grace has a cancelled context and takes no click
  (`Do` and `NextClick` both see the cancelled context). Its deferred `clicksStopped` can still mark the new
  session's queued clicks "not sent: stopped". That is the wrong word; nothing is sent; it was accepted with 7b.
- **`StopClicksBefore`'s statement** (`catalog/schema_act.go:1276-1279`): `state = 'queued' AND account_id = ?`
  only. It cannot touch a "sending" row or another account's rows, and it has no bound, as asked.
  `TestActStopClicksBefore` covers all three.

**N2. MINOR, PLAUSIBLE: a clock that steps back.**
- **Where:** `click.go:323-325` and `click_api.go:408`. Both sides of the comparison are wall-clock milliseconds.
- **What happens:** if the clock steps back across a reconnect by more than the gap between a click and the next
  session's start, an earlier session's click is not stopped. Begin then lets a click dated up to `ActAheadMs`
  (5 s) ahead of the clock go out. A step back after `began` and before the first step stops a current click with
  the word "stopped".
- **Assessment:** narrow, and bounded by the 5 s ahead. Accept it, or close it with N4's fix.

**N4. MINOR, PLAUSIBLE: a row written after the next session's first step.**
- **Where:** `queuedFor` (`click_api.go:363-372`).
- **What happens:** if its `ClickNotSent` fails (a store error) and the door call stalled long enough for the next
  session's first step to have run already, the row stays queued with `clicked_ms` before that session's `began`.
  That session then takes it.
- **Smallest fix (also covers N2's first case):** in `oneClick`, before `Do`, a click with
  `cl.ClickedMs < s.began.UnixMilli()` is made "not sent (stopped)" (one comparison), so that the first-step
  sweep is not the only guard.

### 4. Whose pass

- **Neither cut can reach a click's pass.** The clicks' cut and the watchdog both go through `cancelReaderPass`,
  which cancels only a pass flagged as the reader's. The flag and the cancel are read under one lock. The clicks'
  step uses only `clickPass`.
- **The watchdog keeps its old job.** Every reader call (history, gaps, chat list, topics, the mirror's settle read,
  the owner's estimate through `onReader`) still runs in `pass` with the flag set. Before, the watchdog could
  cancel only the running pass, and a click's pass was the only kind it should not cancel.

**N3. MINOR, CONFIRMED by reading: a channel gap read cancelled by the watchdog is no longer paused.**
- **Where:** `errPassCut` (`reader.go:539-542`, 718) also takes the watchdog's cancel.
- **What happens:** a hanging gap read that the watchdog cancels (after 5 minutes without progress) is asked again
  at the next turn. Before, it waited 1 minute, doubling, through `chatFailed`. This matches the history path and
  the brief asked for it ("or by the watchdog").
- **Assessment:** it is at most one request per watchdog period. Say it in the report.

### 5. `Requests` after a failed `End`

Sound by reading `internal/telegram/act.go:680-826` and `call.go:436-530`:
- `Requests` is incremented right before the send (`call.go:471`).
- After Begin, `report` returns either a `*NotSentError` from `recheck`, where `Do` replaces the outcome with
  `notSent` and `Requests` 0, or the request's own answer.
- `outcome` keeps the `Requests` it is given.

So `Requests` 1 means a send was attempted. The count is 1 even when the send failed before any bytes left, so the
row says "not known". That is conservative and correct.

### 6. The coder's three stated limits

- **A click waits behind the reader's whole retry call: acceptable, and waiting is right.** A write sent into a
  server answering 5xx would likely end "not known" instead of a certain "not sent". A safe improvement that sends
  nothing extra: when the step finds the reader in a retry chain (its state shows `PausedUntil` or a retry under
  way) and the click is older than about 90 s, end it "not sent" at once with its own word ("the connection is
  retrying") rather than silently "not sent in time". Or show the reader's state on the page.
- **P3b shows little on the new head: acceptable.** The session now refuses at once. `TestClickQueuedBetweenSessions`
  fails with the sweep undone. A cheap addition: a direct test of `queuedFor` (a row written, `ending` set, the row
  "not sent").
- **No bound on the queue: acceptable now.** A long queue no longer becomes reader requests (P2b: 6 requests in
  125 s, at least 4 s apart); a click past the cap costs ledger writes only. Bound it at piece 3's door.

### 7. Other new code

- **Shared data:** `stepGen` is a plain integer, written and read only on the reader's goroutine (the step's
  deferred write, `readerClock.Sleep`, `readTurn`). `wakeGen` and `ending` are atomic. `began` is written before
  any goroutine starts. `readerPass` is read and written under `passMu`. Sound.
- **The mirror's turn skipped "at most once per queued click":** true by reading. `clickPending` (`reader.go:557`)
  is false after any step whose last look came after the click's bump. `more` does not skip the mirror.
- **A failing `StopClicksBefore`** (for example a catalogue file without the clicks' table) is retried each round
  with one statement and said once. Harmless.

### Counts for the second pass

- Of the nine findings: 6 closed (2, 3, 4, 5, 6, 7a), 1 partly (1), 2 open and accepted (7b, 7c).
- New: N1 MUST FIX (CONFIRMED); N2, N3, N4 MINOR (N3 confirmed by reading, N2 and N4 plausible).

## Third look (the last small round, 2bb3c3d3)

MAY BE LISTED

The third look covers only `git diff 8977dc2c 2bb3c3d3`. The tree is unchanged.
- **Probes:** `zz_review_k9b2_test.go` and the new `zz_review_k9b3_test.go`, loaded with `overlay3.json`. Output is in
  `run8-third.txt` and `run9-third.txt`. Free memory was 5,830 MB or more before each run.
- **Requests** were counted at the fake.

### 1. N1: CLOSED

The fix is `click.go:801-808` with `reader.go:343-345`.

**`TestReview2CutResetsRetryChain` on this head:** 10 history requests in 150 s of the clock without clicks, and
10 with clicks (run8-third.txt). My probe managed only 1 click in that window, because each click now waits behind
the retry chain and my loop waits for each click to end. The coder's `TestClickRetryChainKept` gets 10 and 10 with
5 clicks.

**The questions asked:**
- **A pass that pauses after a stated wait was cut in it:** this cannot happen. The cut ends the pass.
- **Is the note the reader pass's own?** Yes. Only `run(reader=true)` resets it. A click's pass (`reader=false`)
  never does, and `watchdogTick` never touches it. So a pass the watchdog cancelled, or one that ended in an
  error, leaves a note that the next reader pass clears before its first sleep.
- **Goroutines:** `paused` is written in `readerClock.Sleep` and `run`, and read in `Sleep`. All three run on the
  reader's goroutine only: the watchdog sleeps on the collector's clock, not the reader's. No lock is needed.
- **The mirror's settle read and an owner's call through `onReader`:** both run in `pass`, so both are reader
  passes. A retry pause in the settle read correctly stops a later cut in that pass. In an estimate, the pause
  sets the note for that pass only; estimates are never cut anyway. Both answers are right.
- **A stated wait in the first attempt of a pass:** still cut. P1 on this head began its click 37 ms after
  queueing, with no "a read failed" line. The coder's `TestClickReaderWoken` says 33 ms.

**One new finding, T1 below:** the note is kept per pass, but a retry chain belongs to one call (one page's
request).

### T1. SHOULD FIX, CONFIRMED: the "paused" note outlives the call that paused

- **Where:** `click.go:804-806`, with `internal/telegram/reader.go:626-705`.
- **How it happens:** `ReadChat` makes a new `call`, with a fresh retry count and pause, for every page. A pass of
  up to `PagesPerTurn` (10) pages is one reader pass. So one retried page that then succeeded keeps every later
  stated wait of the same pass uncut.
- **Why it costs the owner:** cutting that later wait would lose no back-off. The click still waits behind the
  wait, which can be up to `MaxWait` (1 hour). Past 2 minutes the click ends "not sent in time". No request is
  sent early or extra.
- **Probe `TestReview3PausedNoteOutlivesItsCall`** (run9-third.txt): "the last history answers before the wait
  [ok INTERNAL_SERVER_ERROR ok FLOOD_WAIT]; the click was begun **61709 ms** after it was queued". The same click
  is begun in about 35 ms when the wait comes on a pass's first page (P1, `TestClickReaderWoken`).
- **Smallest fix:** clear the note when a page finishes (`s.click.paused = false` in `pageRead`,
  `reader.go:747`). `pageRead` runs on the reader's goroutine from every history read's `OnPage`, after that page's
  call was answered: the retry chain that the note guards is over at that point.
- **Test:** P5 as a test, the click begun within 2 s, plus `TestClickRetryChainKept` unchanged.

### 2. N2 and N4: the age check at the top of `oneClick` (`click.go:426`)

- **N4: CLOSED.** `TestClickOlderThanSession` covers it.
- **Can the check stop a click queued for this session?** No.
  - `began` is read when the session object is made, before `a.sess` is set.
  - `QueueClick` reads its clock (`click_api.go:408`) after `runningSession` returned that session.
  - A "send again" row is dated by `SendClickAgain`'s own clock read, which comes after `runningSession` too.
  - The door's `ClickInput` carries no time of its own.
  - So a click of this session is dated at or after `began`, unless the clock steps back inside the session. The
    coder's report accepts that case (the click is "not sent", nothing is sent).
- **N2: still OPEN, accepted as narrow.** The comment at `click.go:422-425` says the check catches "a clock
  stepped back across a reconnect". It cannot. A step back makes an earlier session's click look newer than the
  new `began`, not older, so it passes the check.
  - What really bounds the case is Begin. The step back must exceed the reconnect gap, but by no more than about
    5 s (`ActAheadMs`), and the click must be under 2 minutes old.
  - **MINOR, CONFIRMED by reading (documentation only):** correct that comment. My second pass's remark that
    N4's fix "also covers N2's first case" was wrong in the same way.

### 3. The watchdog's tick: CLOSED

`watchdogTick` (`reader.go:250-259`) does what the base's lines did:
- when the reader is stalled, cancel the running pass, count it, and log it;
- the only difference is that it requires the pass to be a reader's.

Before this piece every pass was a reader's. Every reader call still runs in `pass` with the flag set: the owner's
calls, the chat list, topics, history, gaps and the settle read. So the watchdog cancels every stalled pass it
cancelled before, and never the clicks' step's `clickPass`. The coder's `TestClickWatchdogTick` failed with the old
lines put back. I did not re-run that undo.

### 4. Anything else new

Nothing else. The tests added in `click_fix_test.go` use invented data only, and the report's section 10 matches
the code except the clock remark above.

**Counts for the third look:** N1 closed. T1 SHOULD FIX (confirmed). One MINOR on documentation (the clock-step
comment). No must fix.
