# Brief C25: say which ffmpeg the app uses, and warn plainly when it reads fewer frames

For ONE coder (Opus 5.5, high effort), start to finish. Written by the copies session C7, 2026-11-21. Small; no
schema step; no review (it decides no hold or skip: by the lean rule the coder's tests and the session's read).

## Why
On this PC the ffmpeg on the PATH (7.1.1) makes two of the frame check's fifteen reads give no frame on one common
clip shape (a key frame every 50 frames, no B-frames: the test clip `p-k50-end` in
`internal/footage/ffmpeg/index_test.go`, `TestPartsForAgainstFFmpeg`); the 9.0.2 the app's folder ships reads all.
A read with no frame counts as not read; a check may then miss a copy (a download), never skip or release a file.
Today the self-test (`internal/footage/ffmpeg/selftest.go`, `SelfTestResult.Version`) reads the version and both
callers throw it away (`internal/probejudge/judge.go` ~686, `internal/vfp/vfp.go` ~841).

## Where and how (these bind)
- Copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-32`, branch `wip/copies-32` from the main head 09d63f94.
- Go commands only through `bash /c/Users/trabi/Claude/Projects/Telegram/runs-copies-c25/go1.sh <log> <go args...>`.
  Named tests and the whole of the small packages you change (`internal/footage/ffmpeg`, `internal/probejudge`,
  `internal/vfp`); NEVER the whole `internal/catalog` or `internal/collector`.
- Files: `internal/footage/ffmpeg` (selftest and its tests), `internal/probejudge/judge.go`, `internal/vfp/vfp.go`,
  their tests, a report `archiver/docs/progress/copies-ffmpeg-version-REPORT.md`. A collector line belongs to Core:
  if the version is best said in the collector's own start lines, say so in the report and do not edit the collector.
- New log calls use constant format strings; a version is a number, never a path or name.
- Commits with `git -C <copy> -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push `wip/copies-32` to `private`. Invented data only.

## The change
1. The two callers write ffmpeg's version once at their start, in the lines they already write there.
2. The self-test adds one read of a fabricated clip of the shape above (made with ffmpeg's own lavfi source, as the
   self-test's clip is): when it gives no frame, the self-test still PASSES (the frame check stays on: off would send
   every video down unchecked, which is worse) and the result carries a fixed warning that the callers write once:
   "this ffmpeg reads fewer frames than the one the app ships: copies may be missed, nothing is skipped by it".
   Measure what the extra read adds to the self-test's time and say it.
3. `TestPartsForAgainstFFmpeg`'s failure line names the ffmpeg's version.
4. Tests: the warning shown with an ffmpeg that fails the read (a fake runner or a stub), not shown with one that
   passes; the version written. If the PATH's 7.1.1 is reachable from a test only by this PC's layout, do not
   depend on it: use the fake.

## Done
The change, its tests, the named runs and the three small packages whole passing, `gofmt -l` clean, `go vet` of the
three packages, committed and pushed, the report. Hand back with the head. Stop at the first thing not as written.
