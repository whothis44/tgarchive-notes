# Brief C32: a newly fingerprinted video is compared with the library's fingerprints (the old app's ix_vdup, at events)

For ONE coder (Opus 5.5, high effort), start to finish. Written by the copies session C7, 2026-11-22, for the owner's
priority "new items against the saved library". No review by the lean rule IF it writes only copy edges between SAVED
media (nothing held, skipped or released); say in the report if anything else moves.

## What the old app knows (COPY-CHECKS-STUDY A11; answers 8 C.4)
- The old app fingerprinted every saved video and paired them (`ix_vdup`): "same" when 80% of both are covered,
  "clip" when 90% of the shorter, "overlap" otherwise, for review; the bring-in carries 38,802 related and the "same"
  pairs as probable edges. It is the "post-download check" answers 8 used to judge the frame check (it found 882 pairs
  the frame check had called distinct). Videos under the frame check's 20 MB floor, and videos that had no saved
  candidate when they downloaded, are compared by nothing in the new app today.
- `internal/footage` already holds the port (`Compare`, `SameCover = 0.8`, the clip and overlap rules; tests against
  the old app's numbers). `VideoCandidates` (C27: about 90 ms at the unified size) gives saved videos within 20% of a
  length.

## Where and how (these bind)
- Copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-37`, branch `wip/copies-37` from the main head named in your
  start message. Go commands only through `bash /c/Users/trabi/Claude/Projects/Telegram/runs-copies-c32/go1.sh <log> <go args...>`.
  Named tests and the whole of the small packages you change (`internal/vfp`, `internal/footage`); NEVER the whole
  `internal/catalog` or `internal/collector`; a race run of `internal/vfp` through `ix-tools/copies-runs.sh` if you add
  concurrent work.
- Files: `internal/vfp`, `internal/footage` (only if the port lacks something), `internal/catalog/vfp.go` and a new
  catalogue file for the pairs' door, the collector's `fingerprints.go` (copies'), tests, the report
  `archiver/docs/progress/copies-saved-video-pairs-REPORT.md`. No schema step unless a table is needed for "compared
  already" (then claim the board's next free number first, moving "Next free" on). Commits as usual
  (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending `Co-Authored-By: Claude Opus 5.5
  <noreply@anthropic.com>`), push `wip/copies-37` to `private`. Invented data only. Never check out anything in the
  main `repo-archiver` tree.

## The change
1. When the worker writes a video fingerprint (staged copy, or C29's library pass), it compares it with the saved
   videos `VideoCandidates` returns for its length (the first 300), by `footage.Compare`, on the worker's own goroutine
   after the write (never delaying the copy); bounded per file (a time and a count) and counted.
2. Outcomes as edges between the two SAVED media (both ends saved): "same" a `probable` edge with evidence
   "same footage (n%% of both)"; "clip" and "overlap" `related` edges with their evidence. Never `exact`; no `c_want`
   change; an edge that exists is not written twice; the owner's "not the same" (`not_copy`, pair words) is never
   contradicted (no edge written for such a pair).
3. Counts in the worker's hourly line (compared, same, clip, overlap, cut by the bound) and a door with the counts.
4. Clips need candidates of other lengths: say in the report whether `VideoCandidates`' 20% band misses clips, and
   what reading clips would cost; do not build a second walk in this piece.

## Tests (invented: fabricated fingerprints, as `internal/footage`'s tests make them)
Same, clip, overlap, different; an existing edge not written twice; the owner's "not the same" respected; nothing but
edges written (compare `c_want`, `c_supply`, `tg_media` before and after); the bound; the copy never waits.

## Done
The change, the tests, named runs and the small packages whole, any race run, gofmt and vet, committed and pushed, the
report. Hand back with the head. Stop at the first thing not as written.
