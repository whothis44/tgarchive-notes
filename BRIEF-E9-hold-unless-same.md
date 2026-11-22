# Brief E9: a file marked for the exact check first is never downloaded unchecked (copies track, 2026-11-15)

For one Opus coder, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-1` on a new branch
`wip/copies-9` cut from the main branch's head **named in the start message** (`git switch -c wip/copies-9
<head>`; the only branch change allowed). Go module in `archiver/`. Commit work in progress as you go (`git -c
user.name=Claude -c user.email=noreply@anthropic.com commit`, messages starting `WIP copies: `, ending with a
blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no number of any real archive) and
push with `git push private wip/copies-9`; never `origin`, never the main branch, never a force-push.

**This is download-path code that runs concurrently.** It gets an independent review and the race detector on
`internal/engine` before it is merged. Change as little as the rule needs; nothing else in the engine moves.

## What the old app already knows (its numbers; read before the code)
- Its exact check (Telegram's part hashes against a saved file of the same byte size) ran 9,046 times in ten
  days and spared 5,007 files (240 GB); 18 checks ended without hashes. In the new app's first real run: 15
  checks, 43 hash requests, 0 without an answer. So a check without an answer is rare: about 2 in 1,000.
- A file whose check could not run was downloaded: that was right for a file that is only a candidate for
  "same bytes" (a download costs its bytes, nothing is lost). It is wrong for a **look-alike**: of 275
  look-alike holds a frame check released, 203 had the saved file's exact byte size, pixels and length and at
  least 23 were exact copies. The owner's rules: a probable copy is held, never skipped, and never goes
  before unique files; a held copy waits unless the owner releases it. The old app called a big video
  downloaded unchecked after a failed check "a critical error" and put the file back instead (12.26).
- The old app's fix for "no check slot free" was to put the row back with a retry time (10 minutes), bounded.
  The same idea here: give the file back for later first, hold it when that does not help.
- The old app never checked a file that already had a partial download again. That stays.

## The state today (merged; read `archiver/internal/supply/supply.go` `Next`, `Claim`, `Checked`, `checkpen.go`,
## `archiver/internal/exact`, and `archiver/internal/engine/check.go` with the claim path in `lane.go` first)
A video the look-alike rule finds like a saved file, with a saved file of exactly its byte size, is not held
at once: it stays wanted with a mark (`c_want.check_first`), and the Supply hands it out with `File.Check` set.
For such a file the Supply's checker answers "probable" for everything but "same", and the engine then leaves
it held with no attempt spent. **But these outcomes are the engine's own and end in the download whatever the
checker would say** (each is `uncheckedNow`, `noteUnchecked`, or the fall-through in `runCheck`):
1. as many files wait for a check of its class as there are file slots (the pen is full: `lane.go`, at the
   claim, `ReasonCheckPenFull`, recorded nowhere);
2. the lane's checks are held by a wait Telegram stated on a hash call (`ReasonChecksHeld`);
3. the check slots are taken a second time (`ReasonCheckSlotsTwice`);
4. the check ran past its deadline (`expireChecks`);
5. the checker panicked; 6. a wait on the file's own hash call (`runCheck`: the outcome becomes unknown);
7. the engine has no Checker at all while the Supply marked the file; 8. the checker answers anything the
   engine downloads on (none, different, unknown) for such a file, should that ever reach the engine.
The Supply bounds 1 to 3 from outside today (one marked file per lane and class, alone in the pen, none while
the lane's checks are held) and counts the rest as `LookAlikeUnchecked`. That bound stays as it is.

## What to build
- `engine.File` gets one field, `HoldUnlessSame bool`: "this lane never downloads this file: its check finds
  it the same, or it leaves the lane held, or it is given back for later" (it is downloaded only after the
  owner releases it, which takes the mark off). The Supply sets it for a marked file (`check_first` and not a
  probable copy) and for no other.
- For a file with the flag, in every one of the eight cases above the engine does not download:
  - **cannot start now** (1, 2, 3, and a wait on its own hash call, 6): the file is given back as today's
    `CheckNotStarted` is (through `CheckSupply.CheckHeld`: wanted again, not offered before a time, no attempt
    spent), the time being the end of the hold that stopped it or `CheckLater`. At most once per file and run
    by the memory `sendBackOnce` already keeps (use the same memory and bound); the second time it is held, as
    below. Every claim costs a reference refresh, so a file must not bounce without bound.
  - **ran and gave no answer** (4, 5), **no Checker** (7), **an answer that would download** (8), and the
    second "cannot start": the file leaves the lane held (`leaveHeld`), no attempt spent, with a result that
    says the check gave no answer and why in fixed words. The Supply records it as the marked look-alike it
    is (`catalog.HoldLookAlike` with `ReasonLookAlikeUndecided`; the engine's reason kept in the record), so
    the hold has its evidence: the look-alike edge the mark was made with, and what became of the check.
- A file with the flag that is **resumed from a checkpoint** (bytes already on disk) is downloaded on, as
  today and as the old app did, and counted apart (`LookAlikeUnchecked` with a reason of its own). Say in the
  report how such a file can come about (a save marks a wanted file that has a kept prefix) and how often
  the tests can make it.
- A spot check (`CheckSame` with `Spot`, the owner's testing flag) is downloaded, flag or not.
- A file without the flag: **nothing changes, in any path**. Prove it: the existing engine tests pass
  unedited, and one new test runs the same scripted lane twice, with and without a flagged file elsewhere,
  and compares every request and outcome of the unflagged files.
- Counts (the engine's counters and the Supply's stats, fixed words): flagged files given back for later, by
  reason; flagged files held without an answer, by reason; `LookAlikeUnchecked` now only "resumed".
- No Supply call under the lane's lock (the rule the engine keeps today: `spawnW`, `supply(...)`); no new
  goroutine beyond what the existing paths start; no new lock.

## Tests (named; the engine's fake clock and scripted transport; no real time judged, no sleeps)
- `TestHoldUnlessSamePenFull`, `...ChecksHeld`, `...SlotsTwice`, `...Deadline`, `...Panic`, `...WaitOnHash`,
  `...NoChecker`, `...AnswerWouldDownload`: each asserts no part request was ever sent for the flagged file,
  no attempt was spent, what the Supply was told (given back with its time, or held with its reason), and
  that the pen and the check slots are free afterwards (no leak: a later file is checked).
- `TestHoldUnlessSameSecondTimeHeld` (given back once, held the second time, in one run).
- `TestHoldUnlessSameResumed`, `TestHoldUnlessSameSpot`, `TestUnflaggedUnchanged` (above).
- In `internal/supply`: `TestMarkedFileCarriesFlag` (and an unmarked candidate does not);
  `TestEngineHeldRecordedAsLookAlike` (the record: held, probable, the undecided reason, the engine's reason
  kept, the check on record; a file the owner released or set to be fetched for real is given back wanted
  instead, as `HoldLookAlike` already does); the collector's `TestE2EExact*` pass unedited (run those four by
  name once at the end).
- Mutations, each shown failing a named test, then undone: each of the eight paths downloading again (eight
  mutations); the send-back memory not consulted; an attempt spent; the flag set for an unmarked file; the
  check slot not given back after a hold; a Supply call made under the lane's lock (if a test can show it:
  say so if not).

## Rules (hard)
- Touch only `archiver/internal/engine` (the field, the eight paths, counters, tests; `memsupply.go` only as
  its test double needs), `archiver/internal/supply` (set the flag, record the hold, counts, tests), a
  catalogue reason word only if one is missing, and `archiver/docs/progress/`. Not the collector (but its four
  named tests are run), not the window, waits, gates, resume or staging code. No schema step.
- Every wait Telegram states is slept or held exactly as today; no request is added anywhere; no retry is
  added. A given-back file is not asked about again before its time.
- Only exact evidence ends a file without bytes; a held file keeps its evidence; nothing here releases one.
- New log, error and counter text is constant words with numbers only.
- Load: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`,
  `GOMAXPROCS=2 go test -p 1 -run '<names>' ./internal/engine` (and `./internal/supply`) while working: named
  tests only. No whole-package run of the engine, the supply, the catalogue or the collector, no race
  detector, no Docker: the full runs are the main session's, once, after the review. Other sessions' runs may
  be going: leave them alone. Never touch `E:\T\tg-dl` or any real data.
- Keep `archiver/docs/progress/copies-holdunless-PROGRESS.md` current and commit it with each step; at the end
  `archiver/docs/progress/copies-holdunless-REPORT.md`: each of the eight paths with the lines changed and its
  test and mutation; what an unflagged file's path looks like before and after (identical: how shown); the
  counts added; what was NOT verified; anything in this brief you found wrong or contradictory (say so rather
  than build around it); the changed files; a drafted final commit message. Hand back commit-ready: everything
  committed and pushed, the tree clean, gofmt clean.
