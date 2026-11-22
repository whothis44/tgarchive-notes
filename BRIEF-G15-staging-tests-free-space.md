# Brief G15: the Staging page's tests must not depend on this PC's disk (pages, P6, 11-16)

**The first rule of this folder, for you as for every session: routine steps are done by a script or in one
go, never one call at a time for its own sake.** You are one Opus coder. Work only in the copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-pages-free`, branch `wip/pages-free` (cut from the main head
78739d59). Never touch `repo-archiver` itself (a merge run is going on its tree), never another `wt-*` copy.

## What is wrong (read to its cause by the integrator at 17:52, confirmed by me in the code)
Since about 17:45 on 11-16 the WHOLE package `internal/server` fails on this PC for every track and every
merge: five tests answer "no room":
`TestStagingWaitCauses`, `TestStagingCopiersFromMemory`, `TestStagingGaugesWhenNeeded`,
`TestStagingHoldsUnread`, `TestStagingLiveReadsNoTable`.
Their rig (`newStagingEnv` in `internal/server/staging_test.go`) hands the page `KeepFree: 50 << 30`, and
the page reads the REAL free space of the temporary folder's disk: `(*Server).freeWithin` in
`stagingread.go` calls `freeBytes(dir)` (`diskfree_windows.go`: `GetDiskFreeSpaceExW`; `diskfree_unix.go`:
`Statfs`). When the system disk had under 50 GiB free, `noRoom` (`stagingverdict.go` 178) was true and every
verdict became `VerdictNoRoom`. The disk has more room again at the moment (it changes by the hour), so
**the fault may not show when you run the tests: do not take a green run as the proof.** The proof is that
no test's result can change with the disk.

## What the old app already knows
Nothing to port: the old app has no page of this kind and its tests never ask a disk. The rule is this
app's own (the board, the handoff): invented data only in tests; a test must not depend on the PC.

## What to build (small; product behaviour does not change)
1. **A seam for the free space on the kept staging state.** In `stagingKeep` (`stagingread.go`, beside
   `since`, which is the same kind of seam): a field such as `free func(dir string) int64` ("nil: the real
   call; a test sets it"), and `freeWithin` calls it (the real `freeBytes` when nil). Keep `freeWithin`'s
   bound, its `freeBusy` guard and its goroutine exactly as they are: only the function called changes.
   No new exported name, nothing in `Config`, nothing in `livepages`, nothing in the collector.
2. **The rig gives every test an invented, fixed free space.** `newStagingEnv` sets the seam to a constant
   that cannot bind against its own `KeepFree` (for example 1 << 40 against 50 << 30; name the constant
   and say in its comment why it exists and name this brief's fault in one line). A test whose SUBJECT is
   "no room", "free space not known" (the seam answers -1) or a slow call sets the seam itself. Go through
   every test file of `internal/server` that builds a `Server` with `Config.Staging` set or calls
   `freeWithin`/`stagingNow`/the Staging routes in any other way than through `newStagingEnv` (for example
   the fixtures of `staging_look_test.go`, which force "no room" today with `KeepFree` of 1 << 50 against
   the real disk, and `staging_fix_test.go`, `staging_live_test.go`): each must get its free space from the
   seam, never from the disk. List in your report every place you changed and every place you looked at
   and left, with the reason.
3. **Tests that keep the mend true:**
   - one test that shows the dependence is gone: the same rig, the seam answering LESS than `KeepFree`
     (say 49 << 30): the verdict is `VerdictNoRoom`; the seam answering more: it is not. (This is the
     test that would have failed before the mend had it existed: with the seam line in `freeWithin`
     taken out again, it must fail. Try that once, say so in the report, put the line back.)
   - one test that shows the REAL call still works and is still the default: `freeBytes(t.TempDir())` is
     above 0, a path that cannot exist answers -1 (check what each system really answers; if Windows and
     Linux differ, say so and assert only what is true of both, or split by build tag), and a `Server`
     made by `New` with no seam set reads a known, positive free space for its staging folder through
     `freeWithin` (it may assert nothing about HOW MUCH).
   - a seam answering -1: "free space not known" as the page says it today (if a test already shows it
     through the real call failing, move it onto the seam).
4. **Look for the same dependence elsewhere and REPORT, change only what is pages':**
   - `internal/server/settings.go` 231 (`libraryCheck.FreeBytes`): does any test assert on the number?
   - `internal/collector/livepages` (its tests hand `KeepFree` through; I found no disk call: confirm);
   - `internal/launcher` (`freeWords` in `ui.go`, `diskFree` in `proc_windows.go`/`proc_other.go`): does
     any test's result depend on how much is free?
   - `cmd/tgarchive-open`, `internal/actdoor`: confirm none.
   - Core's `internal/collector` (NOT yours: read only): do the pages' tests there (`pagesstaging.go`'s
     tests, anything that reads the Staging page's verdict through the real server) depend on the disk?
     Its rig uses `KeepFree: 1 << 20`, which cannot bind in practice; a test without the rig would use the
     store's default. Report file and test names; change nothing there.

## Rules
- Files you may change: `internal/server/stagingread.go` (the seam only) and `internal/server/*_test.go`.
  Anything else you think is needed: stop and say so in the hand-back instead.
- No test function removed or renamed (say the count of added, removed: 0 expected).
- The PC's memory is tight and other sessions run go commands: **one go command at a time, `-p 1`, named
  tests only (`-run`), nothing that takes over two minutes; no whole package, no vet over packages, no
  race detector** (the whole package runs once after the review, by a script of mine). Before each go
  command look at free memory; under 1.5 GB wait a minute and look again, at most five times, then go on.
  Go's environment: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in bash.
- `gofmt -l` on the files you changed (a single command) before each commit.
- Commit as you go and push `wip/pages-free` to the remote `private` (never `origin`, never the main
  branch): `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  the line `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. No counts of anyone's archive, no
  names, paths or ids of the owner's in code, tests, messages or the report: invented data only.
- Leave no process behind (look before you hand back).

## Hand back (at most 15 lines)
The head's hash, pushed; files changed with +/- lines; test functions added and removed; the named tests
you ran with their result; the one "seam line taken out: the new test fails" try; what part 4 found, by
package; anything you could not verify, said plainly. A short report as
`archiver/docs/progress/pages-free-REPORT.md` on the branch (what changed and why, part 4's list).
