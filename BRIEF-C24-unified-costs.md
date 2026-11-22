# Brief C24: every copy layer's cost at the size of the unified archive

For ONE coder (Opus 5.5, high effort). Written by the copies session C7, 2026-11-21, for the first copies step of
`DESIGN-UNIFIED-ARCHIVE.md` (in the project folder: read sections 0 to 3 and 7). The old archive is to be brought
into the app's own catalogue; before that runs, each read the copy layers make must be known at that size. This
piece measures them on invented data and fixes a read that grows with the archive where the fix is small.

## 1. Where and how you work (these bind)
- Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-29` (branch `wip/copies-29`, cut from the main head
  af4ca40). Only there; `git -C` and full paths, never `cd` in a compound command.
- **Every go command through the track's lock script:** `bash /c/Users/trabi/Claude/Projects/Telegram/runs-copies-c24/go1.sh <log name> <go args...>`
  (memory check, the lock `runs-copies-golock`, `GOMAXPROCS=2 GOMEMLIMIT=1GiB GOFLAGS=-p=1`, the environment
  script; logs in `runs-copies-c24/`). Never `go` any other way. Named tests only, never a whole package, no race
  detector. Another coder of this track shares the lock: a wait for it is normal.
- Files: new test files in `internal/catalog` (gated by an environment variable `CAT9_UNIFIED=1`, skipped
  otherwise, as `TestLookAlikeCostAtScale` is), the report `archiver/docs/progress/copies-unified-costs-REPORT.md`,
  and a fix only in the copies track's own catalogue files (`ladder.go` rung 4 and 6 reads, `exactcheck.go`,
  `vfp.go`, `probe.go`, `atsave.go`, `schema_lookalike.go`, `schema_probe.go`): an index or a bound, never a
  change of rule. A fix that needs a schema step, or a file of another track: stop and say it in the report.
- Commits: `git -C <copy> -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push `wip/copies-29` to `private` after each.
- Invented data only. Never open the owner's catalogue, library or the old archive. Memory: a world of this size
  must stay under about 1 GB in the test process; build it with bulk SQL (`WITH RECURSIVE`), as the existing
  scale tests do; if it cannot, measure at the largest size that fits and say so.

## 2. The shape to build (the old archive's, read-only counts of its 11-15 bring-in; numbers only)
- 310,000 media, of them 241,000 saved, on 230,000 files (one file row per SHA-256; about 2% of saved media share
  a file with another).
- 192,000 videos, 152,000 of them saved; 148,000 saved videos carry a preview hash (`phash`); lengths spread from a
  few seconds to an hour, most under 10 minutes; widths and heights in a handful of common shapes.
- 136,000 saved videos with a video fingerprint row (kind video, the packing of `internal/footage`, its meta's
  duration), frames on the grid the worker writes (0.5 s to 30 s, 1 s to 20 minutes, 2 s beyond, at most 3,600).
- Byte sizes: most saved files have a size no other file has; of files of 256 KiB or more about 3,800 sizes are
  shared by 2 files, 630 by 3, 155 by 4 and 117 by 5 or more (the old app's own count).
- About 100,000 probable copy edges and 9,500 exact ones; 69,000 held collector rows.
- The new account's side, small: a few thousand media arriving.

## 3. What to measure (each logged with the world's counts; nothing asserted but that it ran)
For each read: one call, then 100 calls, cold and warm, the median and the slowest; and its query plan
(`EXPLAIN QUERY PLAN`), written in the report. Find each by its constant or function:
1. Rung 4's pinned read (`samePostForwardsSQL` and its partner) for 100 forwarded attachments.
2. Rung 6's read (`lookAlikeSQL`, `lookAlike`, `lookAlikeVideo`) for 100 new videos in a crowded length and shape
   band and 100 in a sparse one.
3. `sameSizeSaved` and `ExactCandidates` for 100 new files whose size 0, 1, 2 and 5 saved files share.
4. `VideoCandidates` and `VideoCandidatesOf` (the frame check's candidates: within 20% of the length, the first
   300) for 100 videos in a crowded band; also the bytes of fingerprint values a call returns.
5. The at-save steps of this track (`atsave.go`: the same-bytes link and the held-copy steps that run when a
   file is saved), as `TestHoldAtSaveCostAtScale` does, at this size.
6. **Every other read of this track's catalogue files that the collector runs per file, per turn, per hour or
   at its start** (the fingerprint worker's pick, the frame check's jobs and its start and hourly lines, the
   counts the pages read): list them in the report first (file, function, how often it runs), then measure
   those that touch `file`, `tg_media`, `fingerprint`, `copy_edge` or `c_want` at this size.
7. The whole ladder for one new message with 10 attachments (`CatalogueMessage` or its batch form), against
   this world.

**A read is a finding** when one call takes more than 5 ms warm, or its time grows with the archive (compare with
the same read at a tenth of the size), or its plan scans a table. Fix it in this piece when the fix is an index
or a tighter bound in this track's files and the result stays row for row the same (a test that says so);
otherwise report it with the numbers.

## 4. What done is
The gated tests on the branch, committed and pushed; the report: the world as built (counts, build time, the
process's peak memory), a table per read (calls, median, slowest, plan) at the full size and at a tenth, the
findings with what was fixed (before and after) and what was left. Run them once at the end by name
(`CAT9_UNIFIED=1 ... -run 'TestUnified'`), and the named tests of anything you fixed. Hand back with the
branch's head. Stop at the first thing not as written here and say it.
