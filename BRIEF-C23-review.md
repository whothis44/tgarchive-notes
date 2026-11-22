# Brief: independent review of C23 (`wip/copies-28`, 86ebd1d0..8942c6ef)

For ONE reviewer (Opus 5.5, high effort). Written by the copies session C7, 2026-11-21. You review; you do not fix.

## How you work (these bind)
- Read the code at `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-review28-scratch` (a detached copy at 8942c6ef).
  **Never edit or commit tracked files there.** Prove a finding with probe tests in files of your own named
  `zz_probe_*_test.go` in that copy (uncommitted), or load them with `go test -overlay`.
- Every go command through `bash /c/Users/trabi/Claude/Projects/Telegram/runs-copies-r23/go1.sh <log name> <go args...>`
  (the track's lock; logs in `runs-copies-r23/`). Named tests only (`-run`), never a whole package, no race detector.
  Another coder shares the lock.
- Invented data only; no real catalogue; no Telegram request. `git -C` and full paths only.

## What the piece claims (read the diff yourself first: `git -C <copy> diff 86ebd1d0 8942c6ef`)
Its brief is `BRIEF-C23-givebacks.md` (project folder); the coder's report is
`archiver/docs/progress/copies-givebacks-REPORT.md` in the copy. Background: Core's K17 (`state.go`: `giveBack`,
`giveBackRead`, `judgeGivenBack`) judges a file given back from a transfer as the settle would (a chat or topic
switched off while it was in transfer must leave it held, not probable, not supplied). C23 applies the same to
the copies track's own doors in `exactcheck.go` and `probe.go`, adds the frames' copy reason to two lists and to
`heldReasonSQL`, puts `internal/pairwords`' open under `sqlguard`, and keeps the judge's door mark with a test.

## Questions, each answered "real" (with a probe) or "not real" (with why)
1. Every statement in `exactcheck.go` and `probe.go` (and anything they call) that moves a file out of `active`
   or `aside`, or holds it: is any still unjudged after C23? List them all yourself; do not take the report's list.
2. `giveBackRead` is read BEFORE the write and `judgeGivenBack` AFTER. Can the write itself change what the read
   would have said (so the judgement runs when it should not, or not when it should)? Can `judgeGivenBack` move
   a file the owner keeps held (`keep_held`), a released file, a file fetched for real, a file waiting behind a
   better copy (C22's `ReasonTwin`, `c_twin`), or an alternative version, against those rules?
3. The doors that now answer `FateHeld` where they answered "unchecked", "wanted" or "fetch" before: does every
   caller (the Supply in `internal/supply`, the engine, the judge) handle `FateHeld` for that door? Could a held
   file be handed to a lane, or a file be lost from both lanes and the door?
4. `heldReasonSQL`'s new branch (`LIKE 'sampled frames %'`): can another edge's evidence begin that way (the
   bring-in's old-app evidence, the exact check's, rung 6's, the owner's words)? Is the order of the CASE
   branches right when a file has several probable edges?
5. `HoldExact`'s "differs" path: `pairHandBack`, then `judgeGivenBack`. Counts double? A file left held and
   probable by `pairHandBack` (another probable edge) and then judged: right?
6. Cost: the extra read on every give-back of the frame check and the exact check. Measure one `ProbeVerdict` and
   one `LinkSame` give-back before and after at 100,000 want rows (µs); say if it is more than a few µs.
7. The report's point (f): it says a panic inside a custom `sql.Scanner` during `Rows.Scan` leaves the rows' close
   lock held in Go 1.27.3's `database/sql`, so the deferred `Close` waits for good and keeps the connection.
   Real or not, from the Go source on this PC and the coder's test `TestDoorPanicInScanHoldsTheConnection`. Does
   any code in `internal/catalog` scan into a custom `sql.Scanner` (a type with a `Scan(any) error` method)?
8. The tests: does each new test fail on 86ebd1d0 for the reason it names, and would it catch the defect if the
   fix were undone in one place only? Pick two and undo one line each in your probe overlay.

## What to hand back
A file `REVIEW-C23-givebacks.md` in the project folder: each question with "real" or "not real", the probe that
shows it (its name and file), severity (must fix / should fix / note), and at the end one line: "may be listed
after these fixes: ..." or "may be listed as it is". Then reply with that last line and the findings in one line
each. Leave your probe files in the scratch copy.
