# Brief C27: a small table of video lengths, so the frame check's candidates stop seeking the fingerprint table

For ONE coder (Opus 5.5, high effort), start to finish (build, tests, gofmt, vet, named tests; fix rounds come back
to you). Written by the copies session C7, 2026-11-21. Schema step **29** (claimed on the board).

## Why (numbers from C24, `archiver/docs/progress/copies-unified-costs-REPORT.md` on your branch: read its finding 1)
At the unified archive's size (136,000 video fingerprints) `VideoCandidates`/`VideoCandidatesOf` take 150 to 290 ms a
call: `fingerprint` is WITHOUT ROWID and holds the frames in its rows, so the walks of `fingerprint_video_length`
(`probeWalk` in `vfp.go`) seek the table at every index entry (they also read `length(q.data)`). `ProbeLook` walks the
same index. The cure: a narrow table that the walks read instead.

## Where and how (these bind)
- Copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-31`, branch `wip/copies-31`, cut from `wip/copies-29`
  (C24, which holds the main head 6aa225fb). Go commands only through
  `bash /c/Users/trabi/Claude/Projects/Telegram/runs-copies-c27/go1.sh <log> <go args...>` (the track's lock).
- **Tests: named tests only; never the whole `internal/catalog`** (the integrator runs it per batch). No race run
  unless you add concurrent code (you should not).
- Files: `internal/catalog/vfp.go`, a new `internal/catalog/schema_videolen.go`, the schema places of
  `internal/catalog/catalog.go` (the step list, `actSchema`/latest constant, as the other steps do: read how C22's
  step 27 and M6's step 28 are wired, and add 29 after 28), test files, a report
  `archiver/docs/progress/copies-video-lengths-REPORT.md`. Anything else: stop and say why.
- Commits: `git -C <copy> -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push `wip/copies-31` to `private` after each.
  Invented data only.

## The change
1. **Schema step 29:** a table, e.g. `fingerprint_video_len(file_id INT PRIMARY KEY, ver INT NOT NULL, len REAL NULL,
   framed INT NOT NULL)` (`len` exactly the expression `probeLenSQL` computes; `framed` = the row has frames), and an
   index `(ver, len, file_id)` WHERE `framed = 1` (or what the walks need), filled from `fingerprint` in the step
   (kind 'video', model '', seq 0), in chunks if a test at 136,000 rows shows the step holding the writer more than
   about a second (report it). Triggers on `fingerprint` (insert, update of the columns that matter, delete) keep it
   equal; the bring-in writes `fingerprint` rows, so it is covered by the triggers (say so).
2. `probeWalk` (and so `candWalk`, `ProbeLook`'s walk) reads the new table, never `fingerprint`; the frames of the
   kept candidates are read by key as C24 does. Results row for row the same as on 6aa225fb plus C24: extend C24's
   `TestUnifiedVideoCandidatesSame` (or a test of its kind at a size that runs in minutes) and the existing named
   tests of these reads.
3. A test that the table stays equal to `fingerprint` through every door that writes a video fingerprint
   (`PutFingerprints`, the worker's write, a failure row, a replace with another version, a delete, a file removed).
4. Measure with C24's gated test (`CAT9_UNIFIED=1 -run 'TestUnified'`, by name): `VideoCandidates`, `VideoCandidatesOf`,
   `ProbeLook` before and after at full size; and a save's cost with the new trigger beside its cost without
   (`TestHoldAtSaveCostAtScale`'s way): stop and report if the trigger adds more than 20 µs to a fingerprint write.

## Done
The step, the triggers, the walks, the tests, the figures, all named tests passing (`-run 'TestVideoCandidates|TestVfp|
TestProbe|TestSchema|TestUnified|TestFingerprint'`), `gofmt -l` clean, `go vet ./internal/catalog`, committed and
pushed, the report. Hand back with the head and the before/after figures. Stop at the first thing not as written.
