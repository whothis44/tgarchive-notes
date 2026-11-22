# Brief E16b: the fix round after the independent review of the frame check's judge (copies track, session C3, 2026-11-16)

For one Opus coder at high effort, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-16` on branch
`wip/copies-16` (head c3dabe2c; change no branch, merge nothing). Go module in `archiver/`. You are a fresh
coder: the first one cannot be resumed. Read, in this order and in full, before changing a line:
1. `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-E16-judge.md` (what was asked; its rules bind you, but for the
   two this brief takes back).
2. `archiver/docs/progress/copies-probe-judge-REPORT.md` in the copy.
3. `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-review16-scratch\REVIEW.md` (the review: eleven findings,
   the mutation table; its probe tests are in that folder: read them, **change nothing there**).
4. The code: all of `archiver/internal/probejudge`.

Commits and pushes as before (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, messages
starting `WIP copies: `, ending with a blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`;
`git push private wip/copies-16`; never `origin`, never the main branch, never a force-push). **You change only
`archiver/internal/probejudge` and its two documents.** The catalogue's doors are being changed by another coder
on another branch right now (see "What moves under you"): do not edit them here.

## What the old app already knows, for this round
The old check's "copy" was right in 184 of 188 and its "no match" wrong about 3 times in 4; a part it could not
read made the check "failed", tried again later (1 hour, doubling), never "no index": only ffmpeg finding no
index at all was final. **So a part that could not be had is an unknown here too** (finding 1: my brief's own
rule was wrong). The review measured the judge on invented clips that share a third, a half and two thirds
with a saved one, in the three modes, 15 runs: no "copy" (the best: "partly", 8 of 15 with 9 needed).

## The decisions, finding by finding (the numbers are the review's)
**1 (accepted; the brief's step 2 is taken back).** A part the index reader names a second time for a file is
an unknown with why `parts-missing` (the door's bounds end it), not final `no-index`. Final `no-index` stays for
`MaxCalls` and for the reader's own "this is not an index" answers that the check then confirms. The memory of
named parts stays per file for the run. Test: the review's probe (a part named, kept, then read failing once;
and one refused and forgotten): unknown, and at the next turn the check runs.

**2 (accepted).** A verdict the door does not take is tried again at most 5 times or for 10 minutes (whichever
comes first, on the judge's clock), then dropped, counted (a count of its own in `Stats`), and its file passed
over for `PassOver`; the door's "not where the word acts" error (`catalog.ErrWrongState`) is taken as refused
at once, as `ErrBadProbe` and `ErrNotFound` are. Other files are judged meanwhile: a pending verdict no longer
comes before every turn; it is tried when its pause is over and the turn then goes on to the next file. Test:
the review's probe: a door failing for one file only, 2 hours on a passed clock: the other file gets its
verdict in its first turn; the failing one is dropped at its bound.

**3 (accepted).** A `Find` or a `SelfTest` that panics is recovered in `haveRunner`: counted, taken as "not
found" or "the self-test failed", the turn goes on (unknown `no-ffmpeg` for the file at hand). Test: both.

**4 and 5 (accepted; the judge's half).** The kept parts are removed only when the door answers that the file
is held by this copy: fate held with no why. Not for a file the door left wanted (the owner released it: its
download needs those parts; the door will keep their rows after its own fix round) and not when the door
settled the "copy" as something else (final `no-candidate`, late, left). Tests: both cases, with a fake door
answering each fate.

**6 (accepted).** `ErrNoFFmpeg` from `Check` is an unknown `no-ffmpeg` whatever the `Result` says.

**7 (accepted).** When a second round is not affordable and round 0's outcome is the answer, only round 0's
frames go with it (`res.Frames[:res.After[0].Frames]`, guarded on the lengths).

**9 (accepted).** The end-to-end "partly" clip is what it is (the original with short windows replaced at four
sample moments, about nine tenths the same pictures): name and comment it so, and keep its two expectations
(second round off: partly; automatic: a copy, which is right for that clip). **Add the review's measurement
as a test with the real ffmpeg** (skipped with a counted reason when `FFMPEG_PATH` is absent): clips that
share the first third, the first half and the first two thirds of a saved one, in the automatic mode: never
"copy"; the file wanted, its parts kept. Three clips are enough (keep it under about 15 s).

**11 (accepted, small).** A check is resumed only when the candidates' ids **and their frames** are the same
as at the earlier call (keep a SHA-256 of each candidate's packed frames beside its id).

**10 (accepted, small).** The wall test also fails when a module package it reaches, other than
`internal/footage/ffmpeg`, imports `net`, `net/http` or `os/exec`.

**8 (not changed; say so in the report).** More than 64 passed-over files at the front of the list delay newer
ones by at most the pass-over time: left as it is, counted already.

**The four mutations no test caught:** a test that fails when `parts-missing` is written as "no match" (o1);
when a stopped category the context did not see is written as "no match" (o2); when the guard against a copy
that names no candidate is removed (o3: assert on the word, not on the fake door's refusal); when `turn`'s
own stop guard is removed (o4: a stop that arrives after `decide` returned a word).

## Added 11-16 00:11, at the owner's word ("The stuck verdict seems like a weak spot. Can there be parallel checks, or perhaps a stricter timeline?")
One worker means one slow or stuck file delays every file behind it. The old app ran up to 10 checks at once
(sized for its download slots, each waiting on Telegram); the study's proposal for a judge that reads only
local parts was 2 (`COPY-CHECKS-STUDY.md` E.7); a check here starts at most two ffmpeg processes of one thread
each, so 2 checks at once are at most 4 of this PC's 12 cores at their peak.
- **P1. Checks in parallel.** `Config.Workers`: how many files are judged at once, default 2, 1 to 4 (anything
  else is the default). Each worker does one file's turn at a time, as the single worker does now. What they
  share is guarded by one lock (or owned by one coordinating goroutine; your choice, said in the report): which
  files are in hand, the per-file memory, the passed-over files, the verdicts waiting to be written, the
  runner and the self-test's state, the counts. **A file is never in two workers' hands** (the list is read
  and the oldest file not in hand is taken under the lock; a file whose verdict waits to be written stays in
  hand until it is written or dropped). The lock is never held across a door call, an ffmpeg call or a
  `Find`. The self-test runs once, not once per worker; while it has not passed no worker writes any word but
  unknown `no-ffmpeg`. `Run` returns only when every worker has ended and every process it started with it; a
  stop writes nothing from any worker. `Ready`, `Kick` and `Stats` keep their meaning.
- **P2. A stricter timeline for a verdict the door does not take** (this replaces finding 2's numbers): its
  own worker tries it 3 times (pauses of 1, 2 and 4 s), then it waits aside, tried once a minute by whichever
  worker is free, and is **dropped after 5 minutes** (not 10), counted, its file passed over; the three
  sentinels are refused at once as before. No worker waits on it: it takes the next file.
- **P3. So that the first real run can say whether 2 is right:** `Stats` gains the most checks running at once,
  the most files found waiting at one read of the list, and the checks' seconds in sum and at their longest.
- Tests: two files, one whose check blocks on a gate the test holds: the other gets its verdict meanwhile (no
  real time: gates and the passed clock); two workers never take the same file (a list that keeps answering
  the same file); a stop with one check running and one verdict waiting writes nothing; the self-test runs
  once with 4 workers. **The main session runs the race detector on this package afterwards:** every shared
  field must be reached under the lock by construction, and no test may depend on which worker runs first.

## What moves under you (do not build against it; just do not contradict it)
Also from the owner's word, in E15's round: a file's own failures (ffmpeg timing out or failing on it, a part
that cannot be read, no answer from the judge) end after 3 tries 5 minutes apart instead of up to 24 hours;
a file waits for its judge 5 minutes, not 15; at most 16 files have a check in flight at once.
E15's fix round, on `wip/copies-15`: after an unknown the file comes back to the judge without a lane turn (a
door at `Next`); `ProbeJobs` lists only files still wanted, set aside or held; a "copy" for a released file
keeps its part rows; a "more parts" that names no part not kept already is settled by the door as an unknown.
The doors' names, `ProbeVerdictIn`, the kinds and `ProbeSettled` stay as they are. The main session merges the
two branches after both rounds and runs your end-to-end test on the merged tree.

## Tests and runs
`source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then in `archiver/`:
`GOGC=25 GOMAXPROCS=2 go test -p 1 -count=1 ./internal/probejudge/ -run '<names>'`; the package whole at the
end, once without and once with `FFMPEG_PATH` (the second line `where.exe ffmpeg` prints; the seconds in your
report). Before each go command look at the free memory and wait when under 2.5 GB; never two go commands at
once; no race detector, nothing in Docker, no `go vet` over the tree (vet and gofmt on your package). For
every fix say which test fails without it (break it on purpose once). No test judges on real seconds.

## Hand-back
Commit after each finding's fix and its test, pushed, the copy clean. Add to
`archiver/docs/progress/copies-probe-judge-REPORT.md` a section "The fix round" (per finding: what changed,
where, the test; departures and doubts), and keep `copies-probe-judge-PROGRESS.md` current with times from
`date`. Your last message to the main session: the head commit, then at most 25 lines.

## Decided by the owner, 11-16 00:25 ("No to hold for 24 hours. Try again and reset ffmpeg or fallback to CPU."; "auto fallback, with default to gpu then cpu, but also manual"; the options passed to the standalone NAS app too) (written 00:26)
- **While ffmpeg is not working the judge resets it and tries again:** your `Retry` (a minute by default) is
  that: at each one the runner is dropped, found anew and self-tested. Keep it, and make it visible: `Stats`
  counts the resets and how many of them passed, and one constant-format line is logged when the judge goes
  from ready to not ready and back (never once a turn). The door now ends a file after three unknowns five
  minutes apart whatever their why (E15's round), so a file never waits a day on a broken ffmpeg.
- **The decoder is the runner's business, not yours** (another coder builds it in `internal/footage/ffmpeg`:
  the card first, the CPU when the card fails, or a named choice): nothing in the judge may assume a decoder,
  and a runner that says a frame failed has already tried the CPU.
- **Every option of the judge must be a plain value another program can be handed** (the owner wants the same
  options in the standalone NAS app, set and read from the PC): `Config`'s numbers and words stay plain
  (no function needed to express a setting but `Find`, `Mode`, the clock and `Logf`), `Stats` and its
  `Report()` stay plain data (give `Stats` JSON field names, fixed and lower-case, so that a status page
  or the NAS app can carry it), and your report lists every option with its default and its range in one
  table for the main session.
