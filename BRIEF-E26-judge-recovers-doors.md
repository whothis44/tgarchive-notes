# Brief E26 (merge entry "C20"): the judge recovers a panic inside a catalogue call too, now that the catalogue lets go on a panic (copies, session C5, 11-16)

**For an Opus 5.5 coder at high effort. A small piece in the frame check's judge: it removes an exception that
was needed until today. You write code and run only the named tests of what you changed; whole packages, vet,
the race detector and the merge of the head are done once, later, by a clerk of the main session. Read only
what section 1 names.**

- Copy: make it first, from the Bash tool, from the main head named in your start message:
  `git -C /c/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add -b wip/copies-26 /c/Users/trabi/Claude/Projects/Telegram/wt-copies-26 <the head>`
  (if the branch or the folder exists already, stop and say so). Work only in that copy. Go:
  `. /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then the copy's `archiver`.
- **Go commands: one at a time, each with `GOMAXPROCS=2 GOMEMLIMIT=1GiB GOFLAGS=-p=1`; free memory at least 1.2 GB
  before each (`powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`;
  under it wait 2 minutes and look again); and the track's lock around each: `mkdir /c/Users/trabi/Claude/Projects/Telegram/runs-copies-golock`
  (if it exists wait 30 seconds and try again, 20 minutes at most; a lock older than 30 minutes may be removed and
  taken), `rmdir` right after the command ends, also when it fails. Write the code first, then test. Keep any
  helper script of yours in a folder of your own inside the copy (never committed), never in a shared
  temporary folder.**
- Commit as you go: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; `git push private wip/copies-26` after each commit.
  Never another branch; never merge; never tag.
- Invented data only. Nothing runs against Telegram. No log line, test, comment or report carries a real name,
  text, path, id or link; log calls keep constant format strings and never a panic's text.
- You touch `internal/probejudge` (ours), in `internal/catalog` only `ProbeJobs` (`probe.go`) and
  `VideoCandidates`, `VideoCandidatesOf` and what they share (`vfp.go`) (ours), and tests of ours that name the
  judge's wrappers (one test double in `internal/collector/framecheck_test.go` may). **Not `catalog.go` (Core's
  `Batch`), not `internal/parts` or `internal/partsledger` unless section 2's check finds a lock that must be
  let go by a defer there (then say so first in the report and make the smallest change), not `lane.go`, not
  `state.go`, nothing else.**

## 0. What is there, and why it can change
- The judge runs each worker's turn with a recover (`safeTurn`, `internal/probejudge/panics.go`): a panic is
  counted, said in fixed words, the file in hand passed over, the worker goes on: downloads never end because a
  check panicked. **One exception was built on purpose** (review E18b and E18c, 11-16 morning; read the file's
  own comment, lines 33 to 44): a panic raised INSIDE a call into the catalogue or the part store's ledger ends
  the program as before, because `Catalog.Batch` neither committed nor rolled back on a panic: recovered, such a
  panic left the catalogue's ONE write connection inside an open transaction and stalled every write of the
  program until the stop (and a panic in a read held one reader connection the same way). The comment ends:
  "The day catalog.Batch rolls back on a panic, the mark can go."
- **That day is today:** Core's K16 is on the head (3eb9b110, "a panic inside a write no longer leaves the one
  writer held"): `Batch` rolls its transaction back when its function does not return, and passes the panic on.
- The old app has no counterpart (its checker ran in the download's own code, and a crash there ended the run);
  the new app's rule is the board's: a failure of a check never costs a download.
- **So: a panic inside a door call is recovered like any other, once it is SHOWN that nothing is left held.**
  That showing is the piece. If for one of the calls it cannot be shown, the exception stays for that call and
  the report says why.

## 1. Read first (in the copy; no more than this)
- `internal/probejudge/panics.go` in full; `judge.go` around line 317 (where the wrappers are put on) and
  `turn.go`'s `record` (the verdict's write and its "pending" retry).
- `internal/catalog/catalog.go`: `Batch` as it is now (the defers at about lines 255 to 285) and K16's tests of
  it (search the catalogue's tests for `Panic`): what exactly is let go on a panic, and what is not (a panic in
  `Commit`; a panic in the driver).
- `internal/catalog/probe.go`: `ProbeJobs` and `ProbeVerdict` (which of them runs inside a `Batch`; how their
  rows are closed); `internal/catalog/vfp.go`: `VideoCandidates`, `VideoCandidatesOf` (the same).
- The part store's `Remove` as the judge calls it (`internal/parts`: `Store.Remove` and the ledger's delete it
  calls in `internal/partsledger`): **every lock it takes and whether a panic at any line leaves one held.**
- The tests that pin today's exception (search `internal/probejudge`'s tests and
  `internal/collector/framecheck_test.go` for `doorPanic`, `markedCatalog`, `markedParts` and for the line "the
  program ends").

## 2. What to build
1. **The showing, per call** (write it into the report as a table: the call; what a panic inside it can leave;
   what lets it go; the test that proves it): `ProbeJobs`, `VideoCandidatesOf` (reads: a `rows` not closed
   holds a reader connection: close them by `defer`, also in `VideoCandidates`; nothing else of those functions
   changes), `ProbeVerdict` (a `Batch`: K16), the part store's `Remove` (its own locks; the ledger's `Batch`).
   Also: any lock or mark of the catalogue outside `Batch` that those calls take (a statement cache, a
   counter's mutex): held across a point that can panic, or not?
2. **Where the showing holds, the exception goes:** the wrappers `markedCatalog`, `markedParts`, `markDoor`,
   `doorPanic` and the branches that test for it (`safeTurn`, `releaseTurn`) are removed; a panic inside a door
   call is then counted, said and passed over exactly as any other panic of a turn (`TurnPanics`,
   `PanicPassedOver`, the same fixed line, the same pause). The file's comment is rewritten to say what is true
   now, with what a recovered panic inside each call leaves (nothing) and why.
3. **Where it does not hold for one call**, keep the mark for that call only, and say in the report what would
   have to change and in whose file.
4. **The verdict that panicked is not lost and not doubled:** a panic inside `ProbeVerdict` rolls its
   transaction back (nothing written); the judge's `record` and its pending retry must then behave as for a
   write that failed (the verdict kept aside and tried again within its bounds) or as for a turn that panicked
   (the file passed over and judged again later): say which the code does after your change and make sure it
   is one of the two, never "written twice" and never "the row left in phase judge for good" (the Supply's
   bound for a file waiting for its judge lets it through: check that this bound still runs).

## 3. Tests (every new name starts with `TestJudgeDoorPanic`; invented data; the judge's own rig and fakes)
1. `TestJudgeDoorPanicRecovered`: a catalogue whose `ProbeJobs`, `VideoCandidatesOf`, `ProbeVerdict` panic, one
   at a time, and a part store whose `Remove` panics: the program does not end; the panic is counted and said
   once in the fixed words (never its text); the file is passed over and comes back; the worker goes on and
   judges the next file.
2. `TestJudgeDoorPanicLeavesNothingHeld` (with the REAL catalogue, not a fake, and the real part store where
   the rig allows): a panic injected inside each call through the smallest seam (a function variable, or a
   wrapper around the real catalogue that panics after calling into it and one that panics inside a `Batch`
   function through an existing test hook): right after the recover, a write through the catalogue succeeds
   within a second, all reader connections answer (as many reads at once as the pool has), and the part store
   takes a put and a remove. **This test must fail on a `Batch` without K16's rollback** (see it fail once by
   taking the rollback out in your copy, then restore).
3. `TestJudgeDoorPanicVerdictNotLostOrDoubled`: point 4 above, on the real catalogue: after a panic inside the
   verdict's write the row is as before the word, and the file is judged again and settled once.
4. The tests that pinned the exception are CHANGED to pin the new behaviour (list each by name with the line
   that changed); none is removed without a successor.
Run while working: `go test ./internal/probejudge -count=1` (the package is small: about 40 s; it needs ffmpeg:
`export FFMPEG_PATH="$(where.exe ffmpeg 2>/dev/null | sed -n 2p | tr -d '\r')"`),
`go test ./internal/catalog -run 'TestProbe|TestVideoCandidates|TestVFP' -count=1`,
`go test ./internal/collector -run 'TestFrameCheck|TestJudge' -count=1`, `go build ./...`, `gofmt -l` on your
files. **Not** the whole catalogue or collector, no race detector, no vet over packages.

## 4. Hand-back
A report `archiver/docs/progress/copies-judge-doors-REPORT.md`: the table of the showing; what was removed and
what (if anything) stays marked and why; what the judge does with a verdict whose write panicked; every file
touched; test functions removed (none without a successor) and changed (each named); each new test and what
breaks it; what you could not verify (a panic inside `Commit` or the driver: K16's own "not verified"); every
doubt, **above all any lock you found held across a point that can panic**. Everything committed and pushed on
`wip/copies-26`; the copy clean. Your last message: the head's short hash, the tests run with their seconds,
the table in four lines, what stays marked (if anything), the doubts in a few lines.
