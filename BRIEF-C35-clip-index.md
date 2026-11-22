# Brief C35: clips found at any length, through a small in-memory index of frame hashes

For ONE coder (Opus 5.5, high effort), start to finish. Written by the copies session C7, 2026-11-22, for the owner's
priority "new items against the saved library". Builds on C32 (`wip/copies-37` 80ef29fe: read its report's "clip
question": the 20% length band of `VideoCandidates` misses nearly every clip; the old app found them with an index of
frame hashes, 256 frames a video). Edges only, as C32: one independent review follows (edges feed `WantAgain`).

## Where and how (these bind)
- Copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-40`, branch `wip/copies-40` cut from `wip/copies-37`
  (80ef29fe, C32's head: C35 merges after C32). Go commands only through
  `bash /c/Users/trabi/Claude/Projects/Telegram/runs-copies-c35/go1.sh <log> <go args...>`. Named tests and the whole of
  the small packages you change; NEVER the whole `internal/catalog` or `internal/collector`; a race run of `internal/vfp`
  (or your new package) through `ix-tools/copies-runs.sh` (Docker) if you add concurrent work.
- Files: a new package for the index (e.g. `internal/clipindex`, pure), `internal/vfp` (C32's `pairs.go`: candidates from
  the index besides `VideoCandidates`), `internal/catalog` only for a paged read of video fingerprints if none fits,
  tests, the report `archiver/docs/progress/copies-clip-index-REPORT.md`. No schema step (the index lives in memory,
  built from the stored fingerprints at the worker's start and kept by its own writes; a count check like C33's F1 for
  rows other writers add). Commits as usual (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`,
  ending `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`), push `wip/copies-40` to `private`. Invented data
  only. Never check out anything in the main `repo-archiver` tree.

## The change
1. **The index:** for each saved video's fingerprint, a bounded number of its frame hashes (say 16 to 64, spread over
   its length, flat frames left out: the footage package says which frames "say anything"), each mapped to the video.
   A lookup with a new video's sampled hashes returns the saved videos sharing at least N near hashes (Hamming 8, as
   the frame check; a band scheme like C33's for near matches), ranked by hits, at most K (say 32). Measure the memory
   at 136,000 videos and keep it under about 100 MB; say what you chose and the recall on invented clips (a clip of 10%,
   30%, 60% of a saved video; a saved clip of a new long video).
2. **Use:** C32's comparing step takes the index's candidates besides `VideoCandidates`' (no duplicates), and
   `footage.Compare` decides as now: clip and overlap give `related` edges, same a probable edge lesser to better (C32's
   door, unchanged). The 5 s bound per file holds for the whole step.
3. **Counts:** candidates from the index, clips found, in the worker's hourly line.

## Tests (invented fingerprints, as `internal/footage`'s tests make them)
Clips of several shares found both ways; unrelated videos not returned; the memory and lookup cost at 136,000 videos;
the index kept by new writes and by rows other writers add (a count check); nothing but edges written.

## Done
All of it, the named runs and the small packages whole, any race run, gofmt and vet, committed and pushed, the
report. Hand back with the head. Stop at the first thing not as written.
