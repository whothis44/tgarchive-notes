# Brief E5: fingerprints and sampled frames through ffmpeg, from local bytes only (session C, 2026-11-15)

For one Opus coder, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-footage` on branch
`wip/copies-4` (create it there from `wip/copies-3`, head 3e7de63, with `git switch -c wip/copies-4`; that is
the only branch change allowed). Go module in `archiver/`. Commit work in progress as you go (`git -c
user.name=Claude -c user.email=noreply@anthropic.com commit`, messages starting `WIP copies: `, ending with a
blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no number of any real archive) and
push with `git push private wip/copies-4`; never `origin`, never the main branch, never a force-push.

## Why
`internal/footage` (on this branch) is the old app's fingerprint and frame-match arithmetic, pure. This piece
is the part that runs ffmpeg: making a saved video's fingerprint from its local copy, and reading the 8
sampled frames of a video of which only some 1 MiB parts are on disk. Nothing calls it yet; the catalogue's
table and the lane's fetching of parts are later pieces.

The old app's lessons that bind it (do not re-derive; `archiver/docs/COPY-CHECKS-STUDY.md` sections B, C and
E, rules R1, R2 and R6; `archiver/docs/TRIED-BEFORE.md` section 6):
- The old check let ffmpeg wait on Telegram while it held a download's place: every trouble of its last
  fifteen versions came from that. **Here ffmpeg only ever reads bytes that are already on the local disk.**
  A read that needs a part that is not there ends at once and is reported as "needs these parts", never
  waited for.
- A check that ran out of time or could not read is **unknown**, never "no match" and never a reason to
  download unchecked.
- Fingerprints were once made by reading saved videos back from the NAS and filled the link; since then they
  are made from the local copy before it moves. This package takes a local path and never looks for one.
- A GPU decode failure counts against the GPU only when the CPU then reads the file (a file neither can open
  is a broken upload).

## Ported from (read-only: `C:\Users\trabi\Claude\Projects\Telegram\wt-v12.31\core-service\internal\app`)
- `ix_vdup.go` 570-676 `ixFFmpegFingerprint` (the arguments, `fps=2`, 96 x 96 grey, `showinfo` times, the
  duration line, frames read as a stream, `ixThin(ixOnGrid(...))`, the length fallback) and
  `ix_stage_process.go` 207-225 `ixFingerprintFallback` (GPU then CPU, three GPU failures the CPU survived
  switch the run to the CPU).
- `ix_copies_sample.go` 233-465 `ixRangeFile`, `ixParseRange`, `ixServeRemote` (127.0.0.1, a random port, a
  random 128-bit path, an answer never past the end of the part holding its start), 467-536 `ixSampleFrame`
  (one process a frame, fixed arguments, no shell, one thread, `-noaccurate_seek -copyts`, the frame's real
  time from `showinfo`), 163-229 the failure categories, 711-767 the loop (first frame alone, then two at
  once; `footage.Decided` after each batch).
- Changed from the old app, each for the lesson above: the range server answers from local parts only (an
  interface the caller gives: `Part(index) ([]byte, bool)` and the file's size); a missing part is recorded
  and ffmpeg's read ends; there is no fetching, no waiting on parts, so the old "time not counting waits"
  clock becomes plain limits: a limit per ffmpeg process and one for the whole sampling (both config, the
  old values of 60 s own time as the whole limit's default); `-rw_timeout` follows the process limit.

## What to build
New package `archiver/internal/footage/ffmpeg` (name it as fits Go; standard library plus `internal/footage`):
1. **Finding ffmpeg:** an explicit path in the config, else the environment variable `FFMPEG_PATH`, else
   `PATH`. None: every call returns a typed "no ffmpeg" error. A `SelfTest(ctx)` that makes a tiny invented
   clip with ffmpeg's own `lavfi` source in a temp folder and checks the filters and options this package
   needs; its result says exactly what is missing. Look at `archiver/internal/fabricate` for how the module
   already finds and uses ffmpeg, and reuse its finder if it has one that fits (say so).
2. **`Fingerprint(ctx, path, hwaccel) (durationSeconds, []footage.Frame, error)`** with the GPU-then-CPU rule
   kept in a small struct the caller owns (no package state). Typed errors: no ffmpeg; cannot open; timed out;
   stopped.
3. **`Sample(ctx, src Source, durationSeconds, candidates [][]footage.Frame) (Result, error)`**: serves `src`
   (size, mime, `Part`) on the local range server, reads frames in `footage.SampleOrder` (first alone, then
   two at once), stops when `footage.Decided` says so, and returns: the frames read, the parts it used, the
   parts it asked for that were missing (sorted, each once), and one of: decided (enough frames: the caller
   runs `footage.Verdict`), **needs parts** (a read ended on a missing part and it is not decided), **unknown**
   with a category (the old categories that still apply: timeout, ffmpeg-io, ffmpeg, no-ffmpeg) or **final**
   with a category (no-index, cannot-seek, bad-data, few-frames). It never returns a verdict itself and never
   "no match". Every process it started is gone and the server closed when it returns, also on cancel.
4. No log lines with names or paths: errors carry categories and numbers; an ffmpeg error text is kept only
   as a category (the old code matched words in the text: keep that matching in one function with a test per
   word, since there is no typed error to be had from a child process).

## Tests (invented media only, made by ffmpeg's `lavfi` sources in temp folders; named)
Tests that need ffmpeg skip with a clear message when it is absent and say so in the report; say in the
report whether this PC had it and which version (`ffmpeg -version` first line only).
- `TestFingerprintInvented`: an invented clip and its re-encode at another size give fingerprints that
  `footage.Compare` calls the same; an unrelated clip does not; a mirrored one matches through the mirror hash;
  a letterboxed one matches.
- `TestSampleAllPartsLocal`: with every part present, the 8 frames of a re-encode matched against the
  original's fingerprint give `footage.Verdict` Probable; an unrelated clip NoMatch; a trimmed copy (new
  intro) Probable at its offset.
- `TestSampleMissingParts`: with only some parts present the result is "needs parts" with the exact missing
  indexes ffmpeg asked for, nothing waited for (bounded time), and after those parts are added a second call
  goes further; MP4 with the index at the end and at the front, and MKV.
- `TestSampleNeverNoMatchOnTrouble`: a truncated file, garbage bytes, a process limit of a millisecond, a
  cancelled context: each gives unknown or final with the right category, never a decided result.
- `TestRangeServer`: ranges, the part-boundary rule, a wrong token is 404, only 127.0.0.1.
- `TestNoLeak`: after each of the above, no ffmpeg child is left and the listener is closed (count the
  package's own started and ended processes).
- `TestCategoryWords`: each word the category matcher looks for.
- Mutations, each shown failing a named test, then undone: a missing part served as zeros; the answer allowed
  past its part's end; a timeout returned as decided; the GPU blamed when the CPU also fails; the token check
  removed.

## Rules (hard)
- Touch nothing outside the new package and `archiver/docs/progress/`. `internal/footage` and
  `internal/lookalike` are not to change (if the pure package lacks something, stop and say what).
- This package starts processes and goroutines: every goroutine has an owner that waits for it; no package
  variables holding state; safe for several calls at once. Say in the report exactly which goroutines exist
  and what ends each: the main session will have a race run made of this package.
- Never read a path the caller did not give; never touch the network beyond 127.0.0.1; never under `E:\T\`
  or `%LOCALAPPDATA%\tgarchive\`. Invented media only. The old app's code is read-only reference, never built
  or run.
- Load: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then
  `GOMAXPROCS=2 go test -p 1 ./internal/footage/...`. Keep invented clips tiny (a few seconds, small frames):
  no test over 20 s. No race detector, no Docker. Other agents' tests may be running: leave them alone. If Go
  or its caches are missing, stop and say so.
- Keep `archiver/docs/progress/copies-ffmpeg-PROGRESS.md` current and commit it with each step; at the end
  `archiver/docs/progress/copies-ffmpeg-REPORT.md`: what was ported from which lines and what was changed and
  why, every test with its mutation, the goroutines, the ffmpeg found, what was NOT verified, the changed
  files, a drafted final commit message.
