# Brief C29: fingerprints for videos already in the library, read only while no copy waits

For ONE coder (Opus 5.5, high effort), start to finish. Written by the copies session C7, 2026-11-22. No review by
the lean rule (it holds, skips or releases nothing); a race run of `internal/vfp` because it adds concurrent work.

## What the old app knows (TRIED-BEFORE 6 and 8; COPY-CHECKS-STUDY A11 and B; DIGEST "Copies")
- Fingerprinting saved videos by reading them back from the NAS cost 20 to 25 GB an hour of the Wi-Fi link (to
  12.15) and fought the copies; 12.16 moved to the local staged copy. Rule: nothing in the background reads the
  library while copies to it wait. The link is about 14 MB/s each way.
- Fingerprints are the frame check's candidates: a video with none can never be found as a copy by frames.
- The new app's worker (`internal/vfp`) fingerprints only staged copies; it counts library videos without one
  (`LibraryWithout`, `VideosWithoutFingerprint`, hourly) and reads none. Who has none: the new app's own videos
  copied before their turn, written straight to the library, and, once the old archive is brought in, the old
  archive's videos that had none (about 16,000 of 152,000 saved).

## Where and how (these bind)
- Copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-34`, branch `wip/copies-34` from the main head e34f4f64.
  Go commands only through `bash /c/Users/trabi/Claude/Projects/Telegram/runs-copies-c29/go1.sh <log> <go args...>`.
  Named tests and the whole of `internal/vfp`; NEVER the whole `internal/catalog` or `internal/collector`. Then ONE
  race run of `internal/vfp` with `bash /c/Users/trabi/Claude/Projects/Telegram/ix-tools/copies-runs.sh wt-copies-34
  runs-copies-c29/race "" "vfp@2"` (Docker; make the out folder first).
- Files: `internal/vfp`, `internal/catalog/vfp.go` (a door that lists library videos without a fingerprint, by a
  cursor, bounded; if it needs an index, it needs a schema step: claim the next free number on the board first, in
  the same edit moving "Next free" on), the collector's `fingerprints.go` (copies'), tests, the report
  `archiver/docs/progress/copies-library-fingerprints-REPORT.md`. Paths only through the catalogue's resolver (an old
  archive file whose root is not set is skipped and counted: Core's K24 brings that root). Anything else: stop and
  say why.
- Commits `git -C <copy> -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push `wip/copies-34` to `private`. Invented data only.

## The change
1. **The gate:** the worker reads a library video only when (a) no staged video waits for its own fingerprint, (b) the
   copy queue has no entry waiting to copy or check (`file_queue` in state copy or check), (c) the library answers,
   and (d) the hour's byte cap is not reached. It checks (b) before each file and at least every few seconds while it
   reads; when copies appear it stops the read within seconds (the read's context), records nothing for that file,
   and goes back to staged work. One file at a time, as the worker already is.
2. **The cap:** a stored setting `fingerprints.library_mb_per_hour`, default 5,000 (about 1.4 MB/s, a tenth of the
   link), 0 = off, no upper bound of the app's own; its read and set doors (with "stored or default") for the pages.
   A random part is not needed (it paces no request to Telegram).
3. **Order:** newest saved first (the frame check meets new arrivals' look-alikes first), by a cursor so nothing is
   walked twice; a file that fails gets the worker's existing failure row (not tried again) and is counted.
4. **Counts and lines:** library videos read, bytes, stopped for copies, skipped (no root, library away), failed, in the
   worker's counters and its hourly line (constant formats, numbers only).

## Tests (invented: a fake library folder, the fake ffmpeg the package uses)
The gate (each of a to d holds a read back), a copy appearing mid-read stops it within the bound and records
nothing, the cap per hour, the order, a failure row, a restart going on from where it was, nothing read while staged
work waits, and that no file in the library is written or moved (compare the folder before and after).

## Done
All of it, named tests and the whole of `internal/vfp`, the race run, `gofmt -l` clean, `go vet` of the packages you
changed, committed and pushed, the report. Hand back with the head. Stop at the first thing not as written.
