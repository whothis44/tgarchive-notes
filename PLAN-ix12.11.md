# Plan: ix.12.11 — reuse the parts a check fetched, then check smaller videos

Written 2026-11-06, after ix.12.10 (branch `ix/v12.10`, PR #22). Build on `ix/v12.10`.

## Why
- A big-video check (`ix_copies_sample.go`) fetches about 10–16 one-MiB parts of the file from Telegram
  (the index plus the parts around 5–8 sample points). When the video is not a copy, it is downloaded
  later and those parts are fetched again.
- Measured on the live archive (read-only, 11-06): **147 checked videos were later downloaded, 2.06 GB of
  their parts fetched twice**; 193 checked "no match" videos still queued hold 2.86 GB that will be.
- ix.12.10 raises the checks' turn to 3 minutes in 10: perhaps 15–20 checks an hour, about 200 MB of
  parts an hour, five in six of them on videos that are then downloaded. Under the speed limit
  (~3.5 GB/h) that is roughly 5% of all bytes fetched twice. Estimate; ix.12.10's report line will measure it.
- With reuse, a check of a video that is downloaded anyway costs almost nothing, so the 200 MB floor can
  come down. Queued videos not held (11-06): 100–200 MB 1,375 / 200 GB; 50–100 MB 2,161 / 161 GB;
  20–50 MB 4,019 / 134 GB; under 20 MB 5,636 / 77 GB.

## What
1. **Keep a check's parts** (`ixRangeFile.parts`) on disk after the check, whatever the result:
   `dataDir/ixparts/<sha256 of the Telegram identity>/<part index>`, with a table
   `ix_part_store(ident, part, bytes, sha256, at)`. Telegram serves the same bytes for the same file
   (document id and size), so a part is valid for any later download of that identity.
2. **Downloads take kept parts instead of asking Telegram.** One place: `telegram.fetchParallelFrom`
   (every multi-part download, fresh or resumed, goes through it; `downloadMedia` knows the identity).
   A lookup hook, set by the app, returns a kept part; it is checked (length: 1 MiB, or the last part's
   size; SHA-256 as stored) and written in order like a fetched one. A part that fails either check is
   fetched from Telegram as before. Kept parts take no pacer slot and count in no pacer figure (they are
   not network bytes); the report counts them apart ("parts reused from checks: N MB").
3. **Space:** at most 4 GB in all; nothing kept while the data disk has less than 20 GB free (68 GB free
   on 11-06, staging may use 20 GB). Removed when the file is downloaded (identity in `downloads`), when its
   queue row is gone, and oldest first over the cap. Not in the backups.
4. **Smaller videos once the big ones are checked:** the floor (200 MB, `ixSampleMinSize`) steps down
   200 → 100 → 50 → 20 MB, only when no video at or above the current step waits for a check. Below 20 MB a
   check reads most of the file: downloading it is as cheap. The report says the floor in use.

## Risks and how they are covered
- **Wrong bytes in a saved file** (the worst outcome): parts are keyed by the Telegram identity, length-
  and SHA-256-checked on read, and anything doubtful is fetched again. Tests: a corrupted kept part and a
  part of the wrong length are fetched from Telegram; the output equals a plain download byte for byte.
- **Disk:** the cap and the free-space floor; a failed write keeps nothing and changes nothing else.
- **Resume / staging / lower quality first:** all sit above `fetchParallelFrom` (byte stream unchanged);
  tests resume from an offset with kept parts on both sides of it.
- The single-part path (files of 1 MiB or less) and per-chunk verification (`TGDL_VERIFY_CHUNKS`) are left
  as they are.

## Tests
- `telegram`: fetchParallelFrom with kept parts at the start, middle and end; corrupted and short kept
  parts; resume offset; thread counts 1 and 4; Telegram never asked for a reused part.
- `app`: a check's parts are kept and found by identity; removed after the download and over the cap;
  nothing kept under the free-space floor; the floor steps down only when nothing above it waits.
- The ix.12.7 report guard covers the new report line's format.

## Not in it
- Using kept parts for anything but downloads of the same identity.
- Checks of photos (the preview likeness check covers them).
