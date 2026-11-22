# Brief C33: a saved picture gets its PDQ hash and is compared with the library's pictures

For ONE coder (Opus 5.5, high effort), start to finish. Written by the copies session C7, 2026-11-22, for the owner's
priority "new items against the saved library". No review by the lean rule IF it writes only copy edges between SAVED
media and its own fingerprint rows (nothing held, skipped or released); say in the report if anything else moves.

## What the old app knows
- `C:\Users\trabi\Claude\Projects\Telegram\wt-v12.31\core-service\internal\app\ix_pdq.go` (337 lines, read it): PDQ,
  Meta's perceptual picture hash, 256 bits plus a quality; a match at 31 bits or fewer, quality 50 or more trusted.
  The old app used it in its viewer and review, not to hold queued pictures (COPY-CHECKS-STUDY A12). The old archive's
  84,675 PDQ rows come with the bring-in as fingerprints of kind `pdq` (`catalog.FpPDQ`, 32 bytes, bytes as they are).
- In the new app a picture is compared before download only by same size or the same preview bytes (rung 6's stills
  rule); a re-encoded picture is downloaded and never linked to the saved one.

## Where and how (these bind)
- Copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-38`, branch `wip/copies-38` from the main head named in your
  start message. Go commands only through `bash /c/Users/trabi/Claude/Projects/Telegram/runs-copies-c33/go1.sh <log> <go args...>`.
  Named tests and the whole of the small packages you add or change; NEVER the whole `internal/catalog` or
  `internal/collector`; a race run through `ix-tools/copies-runs.sh` if you add concurrent work.
- Files: a new package `internal/pdq` (the port, pure Go, with the reference's test vectors if the old app has them, or
  invented pictures whose distances the old code gives: run the old code read-only in a throwaway test of the old
  tree's own, never committed there, as answers 4 E.13 did for the preview hash); the fingerprint worker
  (`internal/vfp`, or a small worker beside it in copies' files) that hashes a saved picture from its STAGED copy before
  the copy (never reading the library), a catalogue door for the picture candidates and the pairs (`internal/catalog`,
  a new file), the collector's `fingerprints.go` (copies'), tests, the report
  `archiver/docs/progress/copies-picture-pairs-REPORT.md`. A lookup by hash needs an index: if it needs a schema step,
  claim the board's next free number first, moving "Next free" on. Commits as usual (`git -c user.name=Claude -c
  user.email=noreply@anthropic.com commit`, ending `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`), push
  `wip/copies-38` to `private`. Invented data only. Never check out anything in the main `repo-archiver` tree.

## The change
1. A saved picture's PDQ is written as a fingerprint row of kind `pdq` (the bring-in's form, so old and new compare
   alike), from its staged copy, at the worker's pace, never making the copy wait.
2. It is compared with the saved pictures' PDQ: a candidate set that is bounded and indexed (for example by one or
   more 16-bit bands of the hash, any band equal; say what you chose and what it misses), each at 31 bits or fewer and
   both qualities 50 or more: a `probable` edge between the two SAVED media, evidence "same picture (PDQ n bits)". Never
   `exact`; no `c_want` change; the owner's "not the same" respected; no edge twice.
3. Counts in the worker's hourly line and a door.

## Tests
The port against the old code's values; match, no match, low quality; the band lookup's recall on invented
near-copies; nothing but fingerprint rows and edges written; the copy never waits; the cost of one lookup at 100,000
PDQ rows.

## Done
All of it, named runs and the small packages whole, any race run, gofmt and vet, committed and pushed, the report.
Hand back with the head. Stop at the first thing not as written.
