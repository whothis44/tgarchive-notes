# Brief C23: the copies track's own give-backs judged; the frame check's "copy" reason; the guard on two opens

For ONE coder (Opus 5.5, high effort). Written by the copies session C7, 2026-11-21. Small piece, no schema step.

## 1. Where and how you work (these bind)
- Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-28` (branch `wip/copies-28`, cut from `wip/copies-27`
  964397c4, C22's listed tip, which holds the main head af4ca40). Work only there; use `git -C` and full paths,
  never `cd` in a compound command.
- **Every go command through the track's lock script:** `bash /c/Users/trabi/Claude/Projects/Telegram/runs-copies-c23/go1.sh <log name> <go args...>`
  (it checks memory, takes `runs-copies-golock`, sets `GOMAXPROCS=2 GOMEMLIMIT=1GiB GOFLAGS=-p=1`, sources
  `ix-tools/env-archiver.sh`, runs in the copy's `archiver`, logs to `runs-copies-c23/<name>.log`). Never run `go`
  any other way. **Named tests only** (`-run`), never a whole package, never the race detector, never `go vet`
  over many packages. The whole runs are a clerk's, after the review.
- Files you may change: `internal/catalog/exactcheck.go`, `internal/catalog/probe.go`, `internal/catalog/ladder.go`
  (only `probableReasonSQL` and `heldReasonSQL` if needed), `internal/catalog/pairword.go` (only `pairWantSQL`'s
  reason list), `internal/catalog/state.go` (only if a give-back helper needs a small export inside the package:
  say so), `internal/pairwords/pairwords.go` (its one `sql.Open`), `internal/probejudge/panics.go` and its tests,
  and new or existing `_test.go` files in those packages, and `archiver/docs/progress/copies-givebacks-REPORT.md`
  (your report). Anything else: stop and say why in the report.
- Commit as you go: `git -C <copy> -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message
  ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push `wip/copies-28` to `private` after
  each commit (`git -C <copy> push private wip/copies-28`). Never another branch, never `main`, never a tag.
- Invented data only. No Telegram request. Never open the owner's catalogue, library or the old archive.

## 2. Read first
- `internal/catalog/state.go` lines about 260 to 420: `backToSQL`, `giveBackReadSQL`, `givenBackHolds`,
  `giveBackRead`, `judgeGivenBack`, `giveBack` (Core's K17, merged: a give-back reads once whether the settle's
  holds may apply, writes the plain give-back, then runs the settle's topic and chat statements on that one file),
  and `TestGiveBack*` in `giveback_test.go` (how K17 tests a give-back: a chat or topic switched off while the
  file is in transfer; a probable copy).
- Core's list (board message 163 b, in `BOARD-LOG.md`): the statements of this track that move a file out of
  `active` or `aside` without that judgement. Line numbers there are of an older head: find each by its text.

## 3. The list (each with a test that fails on 964397c4 and passes after)
**(a) Give-backs in `exactcheck.go` that write `backToSQL` with no judgement:** `LinkSame` when it links nothing
(the setting off, or fetch-for-real: "not linked"), `HoldExact` when the saved file is gone, and `HoldExact`'s
"differs" branch before `pairHandBack` (check whether `pairHandBack` already judges chats and topics: if it does,
say so and leave it). Each goes through `tc.giveBack(ctx, id, set, args...)` with its guard (`guardedBy`) kept on
the rows changed. Test per statement: the file's chat switched off (and, separately, its topic not collected)
while it is in transfer, then the outcome: it must end held as the settle holds a file of an uncollected chat
(`probable = 0`, not supplied), never `wanted` or `probable = 1`.

**(b) Holds in `exactcheck.go` that write `state = 'held', probable = 1` with no look at the chat:** `HoldExact`'s
hold and `HoldLookAlike`'s held branch (and its topic rule). After the write, `judgeGivenBack` when
`giveBackRead` says the settle's holds may apply (read BEFORE the write, as `giveBack` does). Tests as in (a).

**(c) `probe.go`: `probeWantedSQL` (aside or active back to wanted, or held when probable) and
`probeHeldCopySQL` (held as a probable copy by the frames):** every call site through the same judgement. Find
every call site (`grep -n probeWantedSQL\|probeHeldCopySQL`); a test for each distinct door
(`ProbeFetched`, `ProbeVerdict`, `ProbeOverdue`, `ProbeNotReady`, `ProbeUnchecked`, `ProbeWaitJudge`,
`ProbeRejudge`, `ProbeLaneRefused`, as they apply).

**(d) The defect C22's random worlds found (world 105):** a file held by the frames (`ReasonProbeCopy`) whose
chat is switched off and whose probable edge is then lost stays held with no edge for good: its reason is in
neither `probableReasonSQL` (ladder.go) nor `pairWantSQL`'s reason list (pairword.go). Add `ReasonProbeCopy` to
both, and check `heldReasonSQL` (a file held by the frames that comes back from aside should get its own reason
back, not rung 6's: say what it does today and fix it if it is wrong). Then in `TestTwinNeverSkips`
(`twin_*_test.go`, C22's) take back the line that leaves `ReasonProbeCopy` out of the stranded-file check, and
run it with both seeds it uses. Test: the world-105 shape by hand.

**(e) `internal/pairwords/pairwords.go`:** its `sql.Open("sqlite", ...)` takes `sqlguard.DriverName`
(`internal/sqlguard`, K19, merged): the same library in the collector's process (Core's 163 c 2). Its named tests
pass. `tools/probe-misses` stays plain (do not touch it).

**(f) `internal/probejudge/panics.go`: the judge's door mark (`markDoor`, `sqlPanicked`, `doorPanic` and the frame
walk).** Since K19 a panic raised inside the driver ends the program inside `sqlguard` before it unwinds through
the door call, for every handle opened with `sqlguard.DriverName`. **First list, in the report, every database
handle a door call of the judge can reach** (`markedCatalog`'s three methods; `markedParts.Remove`, the part
ledger's write) and how each is opened. **Only if every one is opened with `sqlguard.DriverName`**, remove the
mark, the walk and their tests, so that a panic in a door call is handled as any turn panic (`turnPanicked`),
and say in the report why a panic in `database/sql`'s own code (not the driver) is safe there (its deferred
`Rows.Close` lets the connection go: show it with a test that panics inside a `Scan` through a custom
`sql.Scanner` and then uses the catalogue again in the same process). If any handle is not under the guard, leave
the mark as it is and say which.

## 4. What done is
Each point with its test, every named test of the changed areas passing (`-run 'TestGiveBack|TestExact|TestHold|
TestProbe|TestTwin|TestPair|TestJudge|TestDoor'` in the packages you changed, each package by its own command),
`gofmt -l` clean on the files you changed, all committed and pushed. A report (`copies-givebacks-REPORT.md`):
per point what you found on 964397c4 (with the line), what you changed, the test, and anything you left and why.
Hand back with the branch's head. Stop at the first thing not as written here and say it.
