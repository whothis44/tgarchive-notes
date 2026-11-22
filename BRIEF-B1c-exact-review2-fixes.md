# Brief: the exact check, fixes after its second independent review (tenth session, 2026-11-14)

For one Opus coder in `C:\Users\trabi\Claude\Projects\Telegram\wt-exact` (branch
`wip/exact-check-2026-11-13`, head 4ce4a0f). The review:
`C:\Users\trabi\Claude\Projects\Telegram\wt-review-exact2-scratch\REVIEW.md`, with its probes
(`probe_*_test.go`, loaded with `-overlay`) and two mutants in `mut/`. Read it in full first; you may copy
from the probes. The review found no way to a wrong "same" other than every walked window matching, but six
findings block the merge. The main session judged each finding; what to build is below. Where this brief
and the review's suggested fix differ, this brief decides.

**The principle behind most of them (the owner's goal: as much distinct content as possible saved before a
fixed date): the check must never be worse than no check. It may save a download; it must never stop, slow
or indefinitely postpone the download of a file that is not shown to be a copy, and never slow the unique
files of its lane.**

## Fixes

1. **(Review 1; blocks the first real hash request.) No hash call inside a stated wait.** One hold per
   account and server for hash calls, kept where every hash call passes (the `Parts`, beside its hash
   slots), set by a wait Telegram stated on any hash call of that server (the stated seconds plus the
   margin, see 9a), and **checked before every hash call**, also inside a comparison that is already
   running: the call waits for the hold to end (on its context; the check's deadline still applies) and
   then goes. The rule of three waits and the lane's closed gate are heeded the same way by a running
   comparison (no further call while the gate is closed; after the third wait the running comparison ends
   as "not compared" for the hour, see 3). The engine's `checkHoldUntil` stays for starting checks.
   Test: the review's probe (one call answered a 3 s wait, a second comparison running): 0 hash calls on
   that server before the wait plus the margin has passed. Mutation: the hold not checked per call.
2. **(Review 2.) Checks never take download slots.** A file waiting for its check, or being compared,
   holds no file slot of its lane (the 5 small and 2 large) and no window slot; comparisons are bounded by
   the check slots alone (2 per lane). When its check ends "different" or "unknown" it takes a file slot
   like any claimed file, or waits for one without blocking others. A file whose check cannot start within
   a short bound (a config field, default 30 s: the lane's checks are held, or both check slots are
   taken) goes back to the catalogue with no attempt spent, to be claimed again later.
   Tests: the review's two probes must give 10 of 10 unique files saved during a 30-minute hash wait, and 4
   of 4 large files saved while two 900 MiB comparisons run. Mutations for both.
3. **(Review 3, 5; the coder's decisions 3 and 4.) Nothing waits for ever, and "not compared yet" is not
   a probable copy.** On the old account 45% of same-size files turned out different, so a file that was
   not compared must not be parked behind every unique file.
   - **Budget reached, or the three-waits rule tripped:** the file is set aside until that hour ends and
     then is **wanted again as before** (its own rank; checked again when claimed). It is never turned
     into a held probable copy by this. No attempt spent; counted as now.
   - **The library's turn:** (a) candidates still in staging are compared whatever the copier does; (b)
     "copies are waiting" means the copier has files waiting to start, not that one copy is running (find
     the right signal in the store; say what you used); (c) a file is sent back for its turn at most 3
     times (a config field); the next time it is compared all the same, reading the library, counted
     (`turn_overridden`). So the longest postponement is bounded and the file is then either linked or
     downloaded.
   - **When the setting goes to `off`:** every file set aside or held as "not compared yet" returns to
     wanted at once (one indexed statement; test at 100,000 such rows that it takes well under a second).
   Tests: the review's catalogue and turn probes; a file with one staged candidate of the same bytes is
   linked with copies waiting; a file is compared on its fourth claim. Mutations.
4. **(Review 4.) `off` stops a running comparison's effect.** The setting is read again before a
   comparison returns "same" or "probable", and inside `LinkSame` (in the same transaction as the link):
   if it is `off` (or the spot check's alarm switched it off meanwhile), nothing is linked or held and the
   file is downloaded. `LinkSame` also reads the fetch-for-real mark again. A running comparison stops
   asking within one call of the setting going off. Test: the review's probe (off after the first of 25
   calls: no link, at most one more call). Mutation.
5. **(Review 6.) The library's turn is asked again right before the library is read** (after the hash
   answers are in). If it is not the file's turn then, rule 3 applies (sent back, or overridden on the
   fourth). Test: the review's probe reads 0 library bytes on the first three claims.
6. **(Review 7.) The three-waits rule and the budget across a restart.** The counts they rest on are
   written with the engine's own flush at each tick the collector makes (not only hourly), and read back
   at a start. Tests that fail against the review's mutants M1 and M3: two waits before a restart and one
   after trip the rule; a restart does not reset the budget.
7. **(Review 9.) A file longer at Telegram than the catalogue's size is never "same".** After the walk
   has covered every byte up to the recorded size, one more hash call at the recorded size: any window
   returned there makes the result unknown (reason: a fixed word). Counted as a request. Test and mutation.
8. **(Review 10.) Conflicting windows are unknown.** Two different hashes for one range, a window that
   overlaps another with other bounds, or a window lying inside another: unknown, never "same" (reason: a
   fixed word). Tests for each shape; mutation.
9. **Smaller, all to do:**
   a. A hash wait's margin is the engine's `PartWaitMargin` as it applies (`e.margin`), in `holdChecks`,
      `keepFileWait` and the new hold of fix 1; no separate constant.
   b. **One log line per wait on a hash call**, as the part-wait line: server, plain or speed limit,
      stated seconds, milliseconds the call had been out, the margin (constant format; through the
      engine's `Logf` or the checker's, never under a lock).
   c. The collector's privacy guard test reaches the exact check's log lines (run its end-to-end guard
      with a same-size candidate so the lines are produced, and assert they are among the lines checked).
   d. A FILE_MIGRATE hop on a hash call is counted as the request it is (the budget's count).
   e. A failed final flush of the checker's counts is retried once and logged.
   f. **A command to change the setting without SQL:** `tgarchive-collector exact-mode
      full|three-places|off` on a catalogue (it takes the catalogue's lock as the other commands do, or
      writes through a running collector's settle path if that is how settings are changed elsewhere: use
      the existing way and say which), printing the old and the new value, and `exact-mode` with no value
      printing the present value and its reason. Switching on again after a spot-check alarm clears the
      alarm's reason and is logged.
10. **Report to the owner, not to fix** (write these plainly in the report's first section):
    - What one full comparison costs in hash requests by file size (the review: a 4 GiB video takes
      4,096 to 32,770 calls) against the provisional budget of 1,000 an hour: with the budget as it is,
      which sizes can be compared at all in an hour, and what the first measured request must settle.
    - That the budget is checked when a comparison starts (the owner's wording), so one large comparison
      can pass it; and that counting by clock hour allows a burst across the hour's end.
    - That a reference expiring during a long comparison restarts it from the start.

Every fix: a test that fails without it (a bounded mutation, restored, checked with `cmp`).

## Bounds (the owner's rules; no exceptions)

- Nothing against Telegram; never start the collector or any program of the app. A real run of the
  collector may be going on this PC: do not touch its process, the folders under the user's local
  application data, or the `a3` folder. Never touch anything under `E:\T\`.
- Work only in `wt-exact`. No push. **Commit your work yourself in this copy as you finish each numbered
  fix** (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, message "WIP exact check:
  review 2, fix N: ...", last line `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`), so a crash
  of the app loses at most one fix.
- Go through `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`.
- Every go command: `GOMEMLIMIT=1GiB GOMAXPROCS=2 GOFLAGS=-p=2`, `-count=1 -timeout 300s` (90s for
  mutations), `-run` naming tests, one package per command. No whole run of `internal/catalog` or
  `internal/collector`; no race detector; no Docker. At the end `gofmt -l` on changed files and `go vet`
  on changed packages, one each.
- Before every go command measure free memory as a separate command first
  (`powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`);
  under 3.0 GB do not run, try again minutes later.
- A test or mutation with a virtual clock must not be able to spin without bound (the story of the
  runaway is in `exact-PROGRESS.md`). A mutation is never left in place.
- No test or compiler process of yours left running.
- `exact-PROGRESS.md` updated after each fix; `exact-REPORT.md` gets a section "Second review: fixes".
- Privacy: numbers and fixed words only in anything printed, logged or written; invented test data.
- The catalogue schema stays 11 (extend its step if a column is needed).
