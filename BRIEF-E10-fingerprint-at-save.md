# Brief E10: a saved video's fingerprint, made from its staged copy; the frame check's candidates (copies track, 2026-11-15)

For one Opus coder, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-vfp` on branch `wip/copies-10`
(made for you from the main branch's head; change no branch). Go module in `archiver/`. Commit work in progress
as you go (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, messages starting `WIP copies: `,
ending with a blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no number of any real
archive) and push with `git push private wip/copies-10`; never `origin`, never the main branch, never a
force-push.

## What the old app already knows (its numbers; read before the code)
Read in the old app's source, `C:\Users\trabi\Claude\Projects\Telegram\wt-v12.31\core-service\internal\app`:
`ix_vdup.go` lines 568 to 870 (the ffmpeg fingerprint and the background worker) and `ix_stage_process.go`
(all of it: the staged copy first). Read-only: never edit or build anything in that folder.
- A saved video's fingerprint (frames at 2 a second on a grid of 0.5, 1 or 2 s, 20 bytes a frame, at most 3,600)
  is what a sampled-frame check of a queued video is compared with. 82,586 of 84,867 saved videos had one.
- Until 12.15 the fingerprints were made by reading each saved video back from the NAS: 20 to 25 GB an hour of
  the Wi-Fi link, while the copies to the NAS moved about 20 GB an hour. Since 12.16 the **staged copy is read
  first**, from this PC's disk, before the file is copied; a staged video waits for its fingerprint at most
  90 minutes after it was staged, only while the pass can run and only while the staging disk has room.
  **Downloads never wait for it, and copies never idle for it.**
- One video at a time. The GPU decoder by default there, the CPU when the GPU cannot read a file; only a file
  the CPU then reads counts against the GPU, and three of those make the rest of the run CPU only (12.13).
- A failure is recorded and not tried again (89 videos ffmpeg could not read, 104 with no readable frame).
- Candidates of a frame check: the saved file it is held as a copy of first, then up to 300 saved
  fingerprints whose length is within 20% of the video's, closest first. The old archive has a median of 1,410
  saved videos in one second of length (9 in 10 seconds under 4,318): a lookup that reads every video within
  20% would read tens of thousands of rows.

## What exists in the new app (merged; read it first)
- The catalogue's table `fingerprint` (`internal/catalog/schema9.go`, `imported.go`): kind `video`
  (`FpVideo`), the value in the old app's packing, written by `PutFingerprints`. The bring-in already carries
  the old archive's video fingerprints into it (`internal/bringin/run2.go`, the `ix_vfp` step: the version,
  the frames as they are, `duration_s` in the meta). **No new table and no schema step is needed or allowed.**
- `internal/footage` (the fingerprint arithmetic and packing, bit for bit the old app's) and
  `internal/footage/ffmpeg` `Runner.Fingerprint` (the ffmpeg part, from a local path only). Nothing calls them.
- The copier's doors for a reader of staged files, built for this (`internal/store/copier.go`, the end of
  the file): `HoldStaged(fileID)` (while held, a staged copy is neither copied nor removed: a copy that meets
  it is put off), `LibraryRead()` and `CopiesWaiting()`.

## What to build

### 1. Three doors in the catalogue: a new file `internal/catalog/vfp.go` (nothing else in the package changes)
- `StagedVideosWithoutFingerprint(ctx, limit)`: files whose bytes are in staging, that are a video (a saved
  Telegram video points at the file), with no `video` fingerprint row of any version (a recorded failure is a
  row), oldest staged first; what the worker needs of each (file id, its staged path as the store names it,
  size, when it was saved). An index walk: its cost must not grow with the saved files.
- `PutVideoFingerprint(ctx, fileID, version, durationSeconds, packedFrames, failedWord)`: one row through
  `PutFingerprints`, the meta written **exactly as the bring-in writes it** (`duration_s`), so a reader does
  not care where a fingerprint came from; a failure is a row with an empty value and its fixed word in the
  meta. The version is the old app's present one (find it in `ix_vdup.go`; the bring-in's rows carry it).
- `VideoCandidates(ctx, durationMs, first, limit)`: saved videos with a fingerprint that has frames, whose
  length (the saved Telegram video's `duration_ms`) is within 20% of `durationMs`, closest first, at most
  `limit` (the caller passes 300); the file `first` (0: none) is put first whatever its length. It must read
  about `limit` rows a side from the index by length, never every video in the range: two walks outward from
  the length, merged. Also `VideosWithoutFingerprint(ctx)`: the count of saved videos in the library with no
  fingerprint row, for the report (they are not read by this piece: see the rules).

### 2. A new package `internal/vfp`: the worker
- `Run(ctx)`: one goroutine, one video at a time. It takes the oldest staged videos without a fingerprint,
  holds each staged copy (`HoldStaged`; one a copier has in hand is passed over), checks the local file is
  there, runs the fingerprint from the staged copy, stores it, lets the copy go.
- **A staged video waits for its fingerprint** the old app's way, through the hold: the worker keeps holds on
  the next few staged videos in line (at most 8) so that the copier puts them off, each **only until 90
  minutes after it was staged** (then it is let go without a fingerprint and counted), and **only while the
  staging disk has room** (a `Room func() bool` the collector gives; false: every hold except the file being
  read is let go at once and none is taken). Nothing here ever makes a download wait.
- What it never does: read a file in the library (a video copied before its turn is counted, not read: the
  pass over library files, allowed only when `LibraryRead()` says so, is NOT built here); start more than one
  ffmpeg; keep a hold after `Run` returns (every hold is let go on every way out); record anything for a file
  that went away while it was read or for a stop.
- ffmpeg not found: nothing is recorded, the state says so in fixed words, it looks again every minute.
- A failure of the file itself (cannot be opened, the time limit): a failure row with the runner's category
  word, not tried again. The GPU rule as the old app's `ixFingerprintFallback` (a setting names the decoder,
  default none: the CPU).
- It stops within seconds of `ctx` ending (ffmpeg is ended by the runner; holds let go).
- Counts (`Stats()`, numbers and fixed words): fingerprinted (files, seconds), failed by word, passed over
  (in hand; gone), holds taken, let go at 90 minutes, let go for room, no ffmpeg, library videos without one.
- The dependencies are small interfaces (the catalogue's doors, the copier's hold, the runner, a clock), so
  the tests use fakes and an injected clock: no test judges real time or sleeps.

### 3. One bound in `internal/footage/ffmpeg`: decoding threads for `Fingerprint`
`Config` gets `FingerprintThreads` (default 2) and `Fingerprint` passes `-threads` for the CPU decode, so one
fingerprint never takes every core (the old app beside it needs about 4 of this PC's 12). **Another coder is
working in that package now on `sample.go`, `check.go` and new files: touch only `fingerprint.go`, the one
field in the config and its default, and a named test. Nothing else there.**

### 4. The collector starts it (`internal/collector`: the core track's files, lent for these lines only)
- Where the copier is started: the worker beside it, with the store's copier for the hold, a room test from
  the writer's own state and keep-free figure (read how the writer decides "staging is full"; do not invent a
  second threshold), the runner with ffmpeg found as `internal/footage/ffmpeg` finds it. It ends with the
  store at a stop, inside the stop's existing wait.
- `run` gets `-fingerprints` (default on) and `-fingerprint-hwaccel` (default empty). One log line at the
  start (on, off, or no ffmpeg) and its counts with the store's hourly lines: constant words, numbers only.
- As few lines as this takes. No change to the reader, the monitor, the engine, the supply, the writer, the
  copier or any wait.

## Tests (named; invented data only)
- Catalogue: `TestStagedVideosWithoutFingerprint` (only staged, only videos, a failure row counts as done,
  oldest first), `TestPutVideoFingerprintMeta` (the meta equals the bring-in's for the same values; a failure
  row), `TestVideoCandidates` (within 20%, closest first, `first` first, a fingerprint without frames left
  out), `TestVideoCandidatesAtSize` (150,000 invented saved videos, 2,000 in the asked second: the rows the
  statement reads are bounded by the limit, shown by the query plan or a count of rows stepped, not by
  seconds).
- Worker, with fakes: `TestWorkerOldestFirst`, `TestWorkerHoldsWhileReading` (the fake copier sees the hold
  before the read and its release after the store), `TestWorkerInHandPassedOver`, `TestWorkerNinetyMinutes`,
  `TestWorkerNoRoom`, `TestWorkerNoFFmpeg`, `TestWorkerFailureRowNotRetried`, `TestWorkerStopMidRead` (nothing
  recorded, every hold let go), `TestWorkerGoneWhileRead`, `TestWorkerGPURule`, `TestWorkerNeverReadsLibrary`
  (the fake runner fails the test on any path outside the staging folder).
- With ffmpeg (skips without it; set `FFMPEG_PATH` as `archiver/docs/progress/copies-ffmpeg-REPORT.md` says):
  `TestWorkerRealClip`: an invented clip staged in a temp folder gets a fingerprint equal to
  `Runner.Fingerprint`'s own, and `VideoCandidates` returns it for its length.
- Collector: `TestRunStartsFingerprintWorker` (started with the store, stopped at the stop, no goroutine left;
  `-fingerprints=false` starts none), by name only.
- The bring-in's and the catalogue's existing fingerprint tests pass unedited (run those by name).
- Mutations, each shown failing a named test, then undone: a library file read; the hold let go before the
  store; a hold kept past 90 minutes; holds kept without room; a failure retried; a row recorded at a stop;
  two ffmpeg at once; candidates read without a limit per side; the meta differing from the bring-in's.

## Rules (hard)
- Touch only: `archiver/internal/catalog/vfp.go` and its test (new), `archiver/internal/vfp` (new), the one
  bound in `archiver/internal/footage/ffmpeg` (section 3), the collector's start and flags (section 4, with
  the one-line documentation of the flags where `run`'s flags are documented), `archiver/docs/progress/`.
  **Not `internal/store`**: if a door you need is missing there, stop and say so in the report; do not add it.
- Nothing in the background reads the library while copies wait: this piece reads staged copies only.
- Never a request to Telegram; nothing here touches a download, a wait or a claim.
- No names, paths or ids in any log, error or count: constant words with numbers. Invented media only; never
  touch `E:\T\tg-dl` or any real file or database.
- Load: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`,
  `GOMAXPROCS=2 go test -p 1 -run '<names>' ./internal/<package>` while working: named tests only. No
  whole-package run of the catalogue or the collector (minutes each), no race detector, no Docker: the full
  runs are the main session's, once, after the review. Other sessions' runs may be going: leave them alone.
- Keep `archiver/docs/progress/copies-vfp-PROGRESS.md` current and commit it with each step; at the end
  `archiver/docs/progress/copies-vfp-REPORT.md`: what was built; each door's statement and what it reads; the
  worker's rules with their tests and mutations; exactly which collector lines changed; the goroutines added
  and what ends each; what was NOT verified (it has not run beside a real copier or on a real video); anything
  in this brief you found wrong or contradictory (say so rather than build around it); the changed files; a
  drafted final commit message. Hand back commit-ready: everything committed and pushed, the tree clean,
  gofmt clean.
