# Finish NA5 (the move to the NAS) on the owner's Console credits

You are one Claude Code session in a terminal, billed to the owner's Anthropic Console credits (API prices). The owner
asked for exactly this one task: finish NA5, get it reviewed, and merge it. Nothing else. Keep it lean: every turn
costs the owner real money.

## Rules (binding)
- Read `CLAUDE.md` in this folder first: privacy (counts, sizes, timings and versions only; never names, texts, paths or
  ids of real data; invented data in tests), the owner's folders (never written), Telegram (nothing runs against it),
  git (commit as `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, messages ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only the `private` remote; never tag or touch `main`).
- **Nothing runs on the NAS, and nothing moves for real.** `tgarchive-nasmove` is built and tested with invented data
  in folders of your own only. Never point it at `C:\Users\trabi\tgarchive-app` or `E:\T\tg-dl`.
- No new Telegram request, no sign-in.
- You are the coder AND, for this one piece, the integrator. Core and pages are archived, so you also read NA5's lent
  commits (the collector re-check, the bring-in refusal) as their owners would.
- Use at most ONE subagent: the second review pass in step 3. No other agents, no sessions.

## Read (in this order, only these)
1. `CLAUDE.md`.
2. `SESSION-NAS-PROGRESS.md`: the block "STATE FOR A TAKE-OVER, session N-1 (Opus), 11-22 16:37" at the top and the
   owner's steps below it. That is the state: which review points are written, which are not.
3. `BRIEF-NA5-move.md` (what NA5 is) and `REVIEW-NA5-move.md` (the review's 4 HIGH and MED points, 1 to 11).
4. `START-INTEGRATOR.md`, sections "Each batch" and "Practical" (how a piece is tested and merged here).

## Steps
1. **Finish the fix round** in the existing copy `C:\Users\trabi\Claude\Projects\Telegram\wt-nas-move` (branch
   `wip/nas-move`, head 7b0d01c0, which does not build yet). Do every review point marked NOT done in the state block,
   plus the `-viewer` and `-abort` flags, the README fixes, and the review's probes turned into tests. Go:
   `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh; export GOMEMLIMIT=1GiB GOMAXPROCS=2 GOFLAGS=-p=2`
   (Git Bash). Then build, `gofmt -l`, `go vet`, and the named tests of `internal/nasmove`, the collector's lock and
   words tests, and `internal/bringin -run` the refusal's tests. Never run whole `internal/collector` or
   `internal/catalog` at this step.
2. **Split into commits**, as the state block says: NA5's own; one "Lent to Core (collector):" commit (lock.go,
   words.go, command.go); one lent commit for the bring-in refusal (internal/bringin/run.go). Push `wip/nas-move`.
   Race run on `internal/nasmove`:
   `bash /c/Users/trabi/Claude/Projects/Telegram/runs-nas-n1/race-run.sh <copy> 2 3g 30m ./internal/nasmove`.
3. **The second review pass**: one Opus subagent, independent, given the diff of the fix round only (from 50bd1206 to
   your head) and `REVIEW-NA5-move.md`. It checks that each finding is really fixed and that the fixes add no logic
   error, above all: never two live copies of a login; the PC's login files deleted only after the bundle verified
   whole and only on the owner's typed yes; `back` takes only the bundle that came back from the NAS; no staged or
   library file deleted. It writes `REVIEW-NA5-move-2.md` (code references only) and says "may be listed" or "fix
   first". Fix what it finds, then ask it once more about those fixes only.
4. **Merge** (as the integrator): in a new copy of your own, cut from the main head (`git -C repo-archiver rev-parse
   --short=8 HEAD`, expected 84e98ca5), use
   `bash /c/Users/trabi/Claude/Projects/Telegram/ix-tools/batch-tree.sh` or `batch-lean.sh` (read the head of each
   script) with NA5's pieces. Whole runs: `collector`, `catalog`, `bringin`, `store`, `launcher`, plus `nasmove`;
   and by path `./cmd/...` and `./internal/collector/livepages` (scripts skip packages with a slash in the name). A
   failure is run again by name on the same tree before you call it load. Then `ix-tools/merge-batch.sh` (one
   commit a piece, pushed), then `bash runs-int-i6/folder-next.sh` (the second folder).
5. **Notes**: three lines in `SESSION-11-PROGRESS.md` under a heading "NA5 on Console credits"; the NAS row of
   `BOARD.md`; mark NA5 merged in `MERGE-QUEUE.md`; commit on `notes`; then `bash ix-tools/notes-backup/backup.sh`.
   If it refuses for names, follow its own message.
6. **Report to the owner in about ten lines**: what merged (the head), what the second review found, test results,
   what is not verified, and the owner's exact steps for the move (from `deploy/nas-app/README.md`), each command on
   its own line with full paths. Say plainly that nothing has moved and that the move starts only when the owner runs it.

## Stop and ask the owner instead of guessing when
- the second review says "fix first" twice, or finds a way the move could lose or duplicate the login or delete files;
- a step needs anything on the NAS, a sign-in, or the owner's real folders;
- a whole run fails and the failure is not explained by name.
