# Brief K9b2: the click's turn, the fix round (Core, K-3, 2026-11-16 00:58)

For the coder of K9b, on `wip/core-turn` (copy `wt-core-turn`, at dc5bb4fb). The independent review is
`REVIEW-K9b-turn.md` in the project folder (verdict: may be listed after the must-fixes; 2 must fix, 1
should fix, 6 minor; all requests counted at the fake; its probes and outputs are in
`wt-core-turn-review-scratch`: `zz_review_k9b_test.go`, `overlay.json`, `run1.txt` to `run5-existing.txt`).
**Read the review in full first, and the probes.** Every finding is accepted; my choices where the
reviewer left one are below. Turn each probe into a test of the tree and see it fail before your fix.
Same ground rules as K9b (only that copy; named tests only; no Docker, no race detector, no whole run of
the collector; nothing contacts Telegram; the memory check before go commands; commit often, push
`private wip/core-turn`; merge nothing).

## 1. Must fix: a click never shortens a pause of the reader's own (finding 1)

My brief's part 3.2.3 was wrong: it had a click cut "a wait Telegram stated or a pause before a retry"
and said both were on record. Only a stated wait is on record. So:
- **The cut is for a stated wait only:** the reader's sleep is cut for a click only while the reader says
  it is sleeping a wait Telegram stated (the reader's state: the wait's end set, no retry pause running:
  read how `State()` tells them apart, as the review names it). A pause before a retry is never cut, by
  a queued click, by `more`, or by anything else of this piece: a click queued then waits for the pause's
  end (and ends "not sent in time" if that is past its 2 minutes).
- After a cut of a stated wait, nothing changes in the reader's retry count or pause for that call
  beyond what a watchdog cancel does today; say in the report what a cancelled call's next attempt
  starts with.
- Tests: the reviewer's P2 and P2b as tests: against a fake that answers errors, the history requests
  the reader sends in 120 s of the clock are the same count with a click every 3 s as with none, and no
  request leaves before its pause's end; 200 clicks queued at once: the same. `TestClickReaderWoken`
  (a stated wait) still begins the click within 2 s.

## 2. Must fix: nothing queued for an earlier session is sent by a later one (finding 2)

- **At a session's first clicks' step, before any click is taken:** every click of the account queued
  before that session began becomes "not sent" with the stopped reason (one statement through the
  ledger's door for it; if the door takes no "queued before" time, use the existing doors in a way that
  cannot miss a row: say which; do not edit the schema text). No bound of rows or seconds that can leave
  one behind: if the statement fails, the session's clicks stay off until it has succeeded (fail closed,
  said once in a constant log line).
- **Queueing refuses** when the account's session is ending or ended (the session's `done`), not only
  when `a.sess` is nil; a click that slipped in during the close is caught by the rule above.
- `clicksStopped` at the reader task's end stays as a first pass, without being the guarantee.
- Tests: the reviewer's P3a and P3b as tests (a row queued between sessions; `QueueClick` back to back
  after the connection is killed): 0 requests for them at the fake in the next session, the rows "not
  sent".

## 3. Should fix: a gap's read cut for a click is not a failed read (finding 3)

In `readGap` and the gap loop of `readTurn`: a pass ended by the cut for a click (or by the watchdog) is
"resume next turn", not a failure: no `chatFailed`, no back-off, and the gap loop returns after it so that
the clicks' step runs. Test: the reviewer's P1 (one click, two open gaps): no "a read failed" line, no
back-off recorded, both gaps read after the click.

## 4. The minor findings

- `wake` is cleared when the clicks' step finds nothing queued, and never outlives the click it was set
  for: the mirror's turn is skipped at most once per queued click.
- The watchdog cannot cancel a pass in which a click's request is out: while a click's `Do` runs, the
  pass's cancel is not the reader's watchdog's to fire (the reader is not reading then); the row's end
  state must stay true either way.
- An owner's cancel that wins the race with the turn is counted and logged as the owner's cancel, not as
  "begun by another turn".
- `ClickOutcomeLost` is called only when a request left (`Requests` 1) and `End` failed; a click that
  made no request and whose "not sent" could not be recorded is not shown "not known": the row stays
  "sending" for the next start's sweep, with one constant log line and a count. (If the request layer
  cannot say which case it is, say so and keep "not known": never claim "not sent" for a request that
  may have left.)
- A restart of the reader task after a panic: say in the report what happens to queued clicks (they are
  marked stopped): accepted as it is.
- The click's age bound (2 minutes) equals the reader's request timeout: a click queued behind a history
  request that hangs to its timeout ends "not sent in time". Accepted as a known limit: one sentence in
  the report's list of what a click can wait behind.

## 5. Runs, report, hand-back

- Once at the end: `go build ./...`; `gofmt -l` and `go vet` on `internal/collector`,
  `internal/collector/faketg`, `internal/telegram`, `internal/catalog`, `internal/tgstore`;
  `-run 'TestClick' ./internal/collector/`; the whole `faketg` package;
  `-run 'MirrorAuto|Reader|OnReader|Estimate|E2EPages|Status|NotCounted|Gap|Watchdog' ./internal/collector/`;
  the 13 existing tests the reviewer ran (named in its report). No whole collector run, no race
  detector: mine.
- A section "9. The fix round" in `archiver/docs/progress/core-turn-REPORT.md`: each finding's number,
  what changed (file, function), its test and "seen failing first: yes or no"; the list of what a click
  can wait behind, as it is now; the entry points' names and signatures as they are now (the pages track
  builds piece 3 on them).
- Commits as before, pushed; `git status --short` empty. Your final message: the head's full hash, each
  of the nine findings with its test and "seen failing first", the commands with results and seconds,
  anything you disagree with.
