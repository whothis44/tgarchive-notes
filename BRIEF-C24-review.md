# Brief: independent review of C24 (`wip/copies-29`, af4ca40e..56d1da98)

For ONE reviewer (Opus 5.5, high effort). Written by the copies session C7, 2026-11-21. You review; you do not fix.

## How you work (these bind)
- The code: `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-review29-scratch` (detached at 56d1da98). Never edit or
  commit tracked files there; prove findings with your own uncommitted `zz_probe_*_test.go` files, or `go test -overlay`.
- Every go command through `bash /c/Users/trabi/Claude/Projects/Telegram/runs-copies-r24/go1.sh <log name> <go args...>`
  (the track's lock; logs in `runs-copies-r24/`). Named tests only; no whole package; no race detector. Other agents
  share the lock. Invented data only; no real catalogue; no Telegram request. `git -C` and full paths only.

## The piece
Its brief: `BRIEF-C24-unified-costs.md` (project folder). The report: `archiver/docs/progress/copies-unified-costs-REPORT.md`
in the copy. It adds gated cost tests (`CAT9_UNIFIED=1`) and ONE change of program code: `internal/catalog/vfp.go`,
`VideoCandidates` (and so `VideoCandidatesOf`): the two walks read file ids and lengths only; the frames and meta of
the candidates kept are read after in one statement by their keys (`candDataSQL`).

## Questions, each "real" (with a probe) or "not real" (with why)
1. Is the result the same as before, row for row and in the same order, for every input (first given or not, limit
   reached or not, a file read by both walks, files without frames, other versions, a lost file, a file in staging)?
   Read `TestUnifiedVideoCandidatesSame` and say what it does not cover.
2. The coder says a candidate whose fingerprint row changes between the walk and the second read is now left out.
   What else can happen between the two statements (a version replaced, a row deleted, frames taken back, a file
   moved or lost, the judge's door mark and its panic path in `internal/probejudge`)? Can a call return fewer than
   `limit` candidates when more exist, in a way that matters for the frame check's rules (a "no match" never
   releases a file; candidates within 20% of the length, the first 300)?
3. `candDataSQL` with `json_each` over up to 300 ids: its plan, and its cost against the old read at the brief's
   size or a tenth (a small probe is enough).
4. Every caller of `VideoCandidates`/`VideoCandidatesOf`: does any rely on `Data` being set for every returned
   candidate, or on the old order of statements?
5. The gated tests: do they skip cleanly without `CAT9_UNIFIED`, and do they leave anything behind (temp folders,
   a goroutine)? Run the package's named tests of `vfp` (`-run 'TestVideoCandidates|TestVfp|TestProbe'`).

## Hand back
`REVIEW-C24-unified-costs.md` in the project folder: each question with real or not real, its probe, severity (must
fix / should fix / note); the last line "may be listed after these fixes: ..." or "may be listed as it is". Reply
with that line and one line per finding.
