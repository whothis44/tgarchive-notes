# Brief E6: more frames when the first round is on the cusp, and a setting (session C, 2026-11-15)

For one Opus coder, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-footage` on branch
`wip/copies-5` (create it there from `wip/copies-4`, head af3bb5a, with `git switch -c wip/copies-5`; the only
branch change allowed). Go module in `archiver/`. Commit work in progress as you go (`git -c user.name=Claude
-c user.email=noreply@anthropic.com commit`, messages starting `WIP copies: `, ending with a blank line and
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no number of any real archive) and push with
`git push private wip/copies-5`; never `origin`, never the main branch, never a force-push.

## Why (the owner's request, 11-15, in his words)
"If the file is on the cusp, can it automatically adjust the number of samples it takes/fingerprints? Or have a
setting for it?"

The old app always sampled 8 points and never looked twice. Its "copy" was right nearly every time it was judged
after download; its "no match" against a named file was wrong about 3 times in 4. The parts a check reads are
reused by the download, so more frames of a file that is then downloaded cost almost nothing. So: when the
first round neither reaches a copy nor clearly misses, read a second round of frames between the first and
judge all of them together. Thresholds do not change.

## Ported from, and what is new
- Unchanged, already ported in `internal/footage` (`sample.go`): the old app's 8 points between 5% and 95% of
  the length (`ix_copies_sample.go` line 723), the visiting order, `SampleMatch`, `Decided`, `Verdict` (a copy
  needs max(3, 60% of the frames read); partial at 3; `TooFew`).
- New, with no counterpart in the old app (it is the owner's request): a second round, the test for "on the
  cusp", the setting. Everything of the first round must come out bit for bit as before when the setting is
  off: the golden tests against the old code must still pass unedited.

## What to build

### 1. Pure part, in `internal/footage` (this brief allows adding to that package; nothing existing changes)
- `SampleTimesRound(durationSeconds, round) []float64`: round 0 is exactly `SampleTimes` in its visiting
  order; round 1 is 8 more points, the midpoints between neighbouring points of round 0 plus one before the
  first or after the last so there are 8 (say exactly which and why in the doc comment), visited in an order
  that spreads them as round 0's does. Deterministic; no point of round 1 equals one of round 0.
- `type Mode` with three values: `ModeAuto` (the zero value and the default), `ModeAlways`, `ModeOff`, with
  `String()` and a parser for the words `auto`, `always`, `off`.
- `type Evidence struct`: what else is known about the file and one candidate, given by the caller: `Of int`
  (the candidate's index, -1 none), `LookAlike bool` (it is a look-alike of that candidate by the preview rule),
  `SameFacts bool` (the same byte size, pixels and length as that candidate).
- `Cusp(out Outcome, ev Evidence) (bool, Why)`: on the cusp after a round when
  (a) some frames match one candidate but fewer than a copy needs (`Hits` from 1 to `Need`-1: this includes
  `Partial`); or (b) no frame matches (`NoMatch`, `Hits` 0) but `ev` names a candidate that is a look-alike or
  has the same facts; or (c) `TooFew` with candidates given (fewer than 3 frames could be read). Not on the
  cusp: `Probable`; `NoMatch` with 0 hits and no evidence; `TooFew` because there are no candidates. `Why` is
  a small enum with fixed words (`short of a copy`, `evidence without frames`, `too few frames`).
- `MoreRounds(mode Mode, round int, out Outcome, ev Evidence) bool`: never after round 1 (two rounds at most);
  never after a `Probable` (it stays: more frames would only cost parts); `ModeOff` never; `ModeAlways` after
  round 0 for every outcome but `Probable`; `ModeAuto` after round 0 when `Cusp` says so.
- `Verdict` is used unchanged on all frames read in both rounds together (the need is then 60% of all of
  them, at least 3). `Decided` is used unchanged within round 0; within round 1 the early stop is: a copy is
  reached over all frames so far, or it can no longer be reached with the points left (write this as
  `DecidedOver(samples, candidates, left, total)` or extend by a new function; `Decided` itself stays as it is).

### 2. The ffmpeg part, in `internal/footage/ffmpeg`
- `Sample` takes the points to read from its caller (or a round number) instead of always round 0, so a caller
  can ask for round 1 with the frames of round 0 in hand; the frames of both rounds are returned together and
  the status rules are as now (decided / needs parts / unknown / final). Keep the present call working for
  round 0 (the existing tests must pass unedited, apart from a signature change you list).
- A helper the later caller will use, and the tests use now: `Check(ctx, src, durationSeconds, candidates,
  evidence, mode) (Result, footage.Outcome)` that runs round 0, judges, asks `MoreRounds`, runs round 1 when
  asked and all parts are there, and returns the final outcome with: rounds run, frames per round, the outcome
  after round 0 and after round 1, and why a second round ran. It returns "needs parts" with the missing
  parts when round 1 needs parts that are not local (the caller fetches and calls again; the frames already
  read are passed back in so nothing is decoded twice).

### 3. Counts (returned, not stored: no catalogue here)
`Result` carries what a caller will count per hour: second rounds run, by why; and how the answer changed
(no match to copy, no match to partial, partial to copy, unchanged, copy lost: a `Probable` can never be lost,
since a `Probable` after round 0 takes no round 1; assert that).

## Tests (invented data and invented clips only; named)
- Pure: `TestSampleTimesRound` (round 0 equals the old points bit for bit; round 1's points, their order, no
  overlap); `TestCusp` (every outcome kind with and without evidence, at the edges of `Hits` and `Need`);
  `TestMoreRounds` (the three modes); `TestSecondRoundVerdict` (invented fingerprints where round 0 gives 2 of
  8 and both rounds give enough for a copy; where round 0 gives 4 of 8 and both rounds do not reach 60%: stays
  partial; where nothing matches in either: stays no match); `TestModeOffEqualsOld` (with `ModeOff` every
  result equals the present package's, on the golden scenarios).
- ffmpeg (skip without ffmpeg, as now): `TestCheckSecondRound`: an invented clip that shares only a stretch
  with its original (so round 0 is short of a copy) takes a second round in `auto` and `always`, none in `off`;
  a re-encode (a copy after round 0) takes none in any mode; an unrelated clip takes none in `auto`, one in
  `always`, and one in `auto` when the evidence says look-alike; missing parts for round 1 give "needs parts"
  and a second call with them goes on without decoding round 0 again (count processes).
- Mutations, each shown failing a named test, then undone: a round 1 point equal to a round 0 point; `Cusp`
  true for 0 hits without evidence; a second round after `Probable`; the verdict taken over round 1's frames
  only; `ModeOff` taking a round; a third round.

## Rules (hard)
- Touch only `archiver/internal/footage` (additions; no existing function's behaviour changes), its `ffmpeg`
  sub-package, and `archiver/docs/progress/`. `internal/lookalike` is not to change.
- Thresholds stay: Hamming 8, slack 2.5 s, 60% and at least 3, partial at 3. A frame check never gives exact;
  nothing here releases or holds a file: it only returns outcomes.
- Pure part pure; the ffmpeg part as brief E5's rules (every process and goroutine ended before a call
  returns; no package state; invented media only; never a path the test did not create; no names or paths in
  errors).
- Load: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, set `FFMPEG_PATH`
  as the E5 report says, `GOMAXPROCS=2 go test -p 1 ./internal/footage/...`. Tiny clips; no test over 20 s; no
  race detector, no Docker. Whole-package runs of other sessions may be going: leave them alone.
- Keep `archiver/docs/progress/copies-cusp-PROGRESS.md` current and commit it with each step; at the end
  `archiver/docs/progress/copies-cusp-REPORT.md`: what was built, the exact definition of round 1's points and
  of the cusp, every test with its mutation, what was NOT verified, anything in this brief you found
  contradictory, the changed files, a drafted final commit message.
