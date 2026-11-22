# Brief E16: the judge of the frame check (copies track, session C3, 2026-11-15)

**Started 11-15 23:28.** For one Opus coder at high effort, in the copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-copies-16` on branch `wip/copies-16` (made and pushed for you at
d0d91f7c: E15 as handed back, with the main head 10a9e3a8 merged in; change no branch). Go module in `archiver/`.
**E15 is being reviewed while you work, and its fix round will change `internal/catalog/probe.go` and
`internal/supply` under you on its own branch:** the doors' names and the verdict's kinds stay; what may move is
what happens after an unknown (the retry may no longer pass through a lane) and small guards. Build against the
doors as they are on your branch (`ProbeJobs`, `ProbeVerdict` with `ProbeVerdictIn` and its kinds `VerdictCopy`
to `VerdictFinal`, `ProbeMaxRounds`, `ProbeMaxParts`, `ProbeWhyPassing`, `ProbeWhyFinal`, `VideoCandidates`); the
main session merges the two branches and tells you if a call of yours must follow.
Commits and pushes as in `BRIEF-E15-frame-check-catalogue.md` (messages starting `WIP copies: `, the same
co-author line, `git push private wip/copies-16`, never `origin`, never the main branch, never a force-push).

**You build one new package, `archiver/internal/probe`, and its tests. You edit nothing else** (not the
catalogue, the supply, the engine, `internal/parts`, `internal/footage`, the collector). If a door of the
catalogue is missing or has the wrong shape for a rule below, stop and say so in your report's first lines:
the doors are E15's and are changed there. The judge has **no Telegram access at all**: it imports nothing of
`internal/telegram`, `internal/engine` or the network (a wall test in your package holds that by reading the
package's imports). It runs concurrently with the lanes and the copier: after you it gets an independent
read-only review and the race detector.

Design: `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-COPIES-frame-check.md` (you are E16) and E15's brief,
Part A (the doors you call, and the rules that live in `ProbeVerdict`, not in you).

## What the old app already knows (its numbers; read before the code)
Read, read-only: `C:\Users\trabi\Claude\Projects\Telegram\wt-v12.31\core-service\internal\app\ix_copies_sample.go`
(all: `ixSampleCheck` is what you replace; `ixSampleWhyOf` and `ixSampleFinal`; `ixSampleRecord`) and
`ix_dl_check.go` lines 286 to 545. In `archiver/docs`: `COPY-CHECKS-STUDY.md` B, B.1 and E.7; in the project
folder `ANSWERS-for-archiver-8.md` section C and `ANSWERS-for-archiver-5.md` section B.
- **The old check's "copy" was right in 184 of 188; its "no match" against a named file was wrong about 3
  times in 4** (882 of 1,140), and it released at least 23 exact copies it had been held for. So a judge's
  "no match" is only ever "go on as you were": the door keeps a held file held, and you never soften that.
- **The old check held a download's place while ffmpeg waited on Telegram:** 10 to 22 s a check in fast
  hours, 3 to 14 minutes under the speed limit, about half of those timing out; a timeout was once taken
  for "no copy" (7 big videos, 4.8 GB). **Here ffmpeg only ever reads parts that are on the local disk and
  waits for nothing; any limit that runs out is "unknown", never a verdict.**
- A check read 8 parts at the median, cap 32; 99.6% of saved videos are MP4 or MOV (the index reader plans
  those; for the rest ffmpeg says what it misses); 27 of 27,051 checks failed for a reason in the file
  itself (22 over the parts cap, 5 bad data).
- The arithmetic (8 points, Hamming 8, 2.5 s slack, 3 hits and 60%, partial at 3, the visiting order) is
  ported and merged in `internal/footage`; you call it and change none of it.
- Our numbers: `mp4index.PartsFor` predicted the parts of 201 of 201 invented clips; a fingerprint decodes
  65 to 79 s of video a second at 360p on 2 threads. Nothing of the judge has run.

## The state today (read first, in full)
`internal/footage/ffmpeg`: `check.go` (`Check`: its statuses, what `prev` resumes, why trouble in round 1 is
never a decided result), `sample.go` (`Result`, `Status`), `category.go`, `ffmpeg.go` (`Config`, the limits),
`selftest.go`, `rangeserver.go` (`Source`). `internal/footage`: `sample.go` (`Verdict`, `Outcome`,
`SampleTimes`), `rounds.go` (`Mode`, `Evidence`, `Cusp`, `MoreRounds`), `footage.go` (`Unpack`).
`internal/footage/mp4index`: `mp4index.go` (`Read`, `NeedError`, `MaxCalls` and the rule to stop at a part named
twice), `parts.go` (`PartsFor`). `internal/parts`: `source.go` (`Store.Source`), `parts.go` (`Remove`, `Has`,
`Indexes`). `internal/vfp/vfp.go` (the fingerprint worker: the shape you follow: one worker, a `Runner`
interface with a fake, the self-test before anything is recorded and again after failures in a row, a pause
after any failure so that a broken ffmpeg or a failing read never spins a core, `Stats().Report()`).
`internal/catalog`: E15's `probe.go` and `vfp.go` `VideoCandidates`.

## What it is
`probe.Judge`: one worker (`Run(ctx)`), one file at a time, `Kick()` to look now, `Ready() bool` (it runs and
its ffmpeg passed the self-test: the collector gives this to `supply.Config.FrameCheck`), `Stats()` with
`Report()` lines (counts, seconds and fixed words only). Its `Config`: the catalogue's doors as a small
interface of your own (`ProbeJobs`, `ProbeVerdict`, `VideoCandidates`, and what else you call), the part store
as an interface (`Source`, `Indexes`, `Remove`), a `Runner` interface (`Check`, `SelfTest`, `Found`;
`*ffmpeg.Runner` has them) found through a `Find func() Runner` as the fingerprint worker's is, the second
round's mode as `Mode func() footage.Mode`, a clock, `Logf`, and the limits with their defaults (below).

**One turn, for the oldest file in phase `judge`:**
1. **The candidates:** `VideoCandidates` for the file's length, the saved file its hold names first when it
   is held, at most 300 (the old number). None (it went away since `Next`): the verdict is final with why
   `no-candidate`. The evidence for the second round (`footage.Evidence`): the hold's file is candidate 0
   and `LookAlike` when the job says the file is held as its look-alike; `SameFacts` when the job's facts
   say so; else `footage.NoEvidence`.
2. **The index first, for a file that may be MP4 or MOV:** `mp4index.Read` over the kept parts. A
   `NeedError`: the verdict is "more parts" with exactly those parts (stop, final `no-index`, at a part
   named a second time for this file or after `MaxCalls`, as the reader's own rule says: keep that memory
   per file for the run). An index: `PartsFor(the 8 sample moments)`; the ones not kept yet: "more parts"
   with them, in one list. Not an MP4, or `ErrBadIndex`: go to step 3 and let ffmpeg say what it misses.
3. **The check:** `Runner.Check` over `store.Source(file, size, mime)` with the candidates' unpacked frames,
   the evidence, the mode, and the `Result` of this file's earlier call when you still hold it in memory
   (lost at a restart: round 0 is then read again from local parts, which costs no request).
   - `Decided`: Probable is the verdict **copy** (the candidate's file, hits, frames judged, the offset);
     Partial is **partly**; NoMatch is **no match**; TooFew is final `few-frames`. The sampled frames go
     with every one of them (the old packing), to be compared again later.
   - `NeedsParts`: **more parts** with `Result.Missing`. **When that list would pass the door's bounds (32
     parts in all, 4 rounds) and round 0 has finished (`Result.After` has its outcome): the verdict is
     round 0's outcome** (the old app's check exactly, which read one round), with a count "second round
     not affordable"; when round 0 has not finished: final `parts-cap`.
   - `Unknown` with a category: the verdict **unknown** with that why. A stopped context writes nothing at
     all (the file is judged at the next start). `Final` with a category: **final**.
   - An error of the call itself (`ErrBadInput`, a panic you recover): unknown with why `ffmpeg`, counted,
     the worker pauses; never a verdict and never a crash of the collector's task.
4. **After a "copy" is recorded:** `store.Remove(file)` (the door has deleted the rows in its transaction; a
   part with no row is never read; a `Remove` that fails is the sweep's to finish and is counted).
5. One turn's limits: `ffmpeg.Config`'s own (60 s of local work a check, 10 s a process); a turn that the
   context cut is not an answer. Between turns: nothing to do is a wait for a `Kick` or 30 s; a failure is
   a pause doubling from 1 s to a minute.

**Ready and the self-test:** as the fingerprint worker: `SelfTest` once per runner found, before any verdict;
again after 3 unknowns with why `ffmpeg`, `ffmpeg-io` or `no-ffmpeg` in a row; while it has not passed,
`Ready()` is false and no verdict but "unknown, `no-ffmpeg`" is written (so the door's bounds run and every
such file is counted). ffmpeg is looked for by `Config.Path`, then `FFMPEG_PATH`, then PATH (the runner's
own order; Go does not find it on this PC's PATH: set `FFMPEG_PATH` for every test that needs the real one).

## Rules that bind every line
The judge cannot say "exact": the door's kind has no such value and you add none. A limit that ran out, a
missing ffmpeg, a part that is not there: unknown, never "no match". "No match" and "partly" release nothing
(the door's rule; your tests show it end to end on a held file). Nothing reads the library or the staging
folder: only kept parts and the catalogue. Logs, errors and test output hold counts, sizes, timings and fixed
words: never a path, a name, an id or ffmpeg's own text. Invented clips only (`internal/fabricate` and the
ffmpeg tests' helpers show how they are made). No test judges on real seconds.

## Tests
With a fake `Runner` and a fake store and catalogue (most of them), each of: every status and outcome above to
its verdict; the index path (parts named, then predicted parts, then the check) with an invented MP4 built by
`mp4index`'s own test builder if it is exported to tests, else by ffmpeg; a part named twice; the bounds (the
second round not affordable with and without a finished round 0); no candidate; the self-test's states and
`Ready`; a stopped context writes nothing; a panic in the runner; a failing door (the verdict is tried again
at the next turn, nothing is lost, no spin: count the calls on a clock you pass in). With the real ffmpeg
(`FFMPEG_PATH` set; skipped with a counted reason when absent), the real `parts.Store` on a temp folder and
E15's catalogue doors on a temp catalogue, end to end on invented clips: an original saved with its
fingerprint and a re-encode queued gives "copy" and the file held with its edge and its parts gone; an
unrelated clip of the same length gives "no match", the file wanted and its parts kept; a clip that shares a
third gives "partly"; the same three on a file that was held before: held after each. Mutations: say in the
report which rules you broke on purpose to see a test fail (at least: a timeout taken for "no match"; the
affordability rule; `Remove` before the verdict; the self-test skipped).

Run while working: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then in
`archiver/`: `GOGC=25 GOMAXPROCS=2 go test -p 1 -count=1 ./internal/probe/ -run '<names>'`; the package may run
whole at the end (write its seconds). Before each go command look at the free memory and wait when it is
under 2.5 GB; never two go commands at once; no race detector, nothing in Docker, no `go vet` over the tree.

## Hand-back
Commit-ready on `wip/copies-16`, pushed, the copy clean; a report
`archiver/docs/progress/copies-probe-judge-REPORT.md` and a progress file beside it kept current from the first
hour; what the collector's lines need (how the judge is made and started, what `Ready` is given to, the
flags); departures and doubts. Your last message: the head commit, then at most 25 lines.
