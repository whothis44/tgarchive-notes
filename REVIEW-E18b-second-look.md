# Review E18b: second look at the fix round of the collector's lines (independent, Opus 5.5 high, 11-16 09:40)

**Head reviewed:** `b0a1514a` on `wip/copies-18`, the fix round `56c5fc0d..b0a1514a` (13 commits). I did not read
`wt-copies-18`. I made a detached copy, `wt-copies-review18b-scratch` at `b0a1514a`, and left it with two untracked
probe files and nothing else changed:
- `archiver/internal/catalog/zz_probe_e18b_test.go`
- `archiver/internal/collector/zz_probe_e18b_test.go`

I made two deliberate breaks in `internal/probejudge/panics.go` for question 9 and put them back with `git checkout`.
Nothing ran against Telegram. All data was invented.

I read these in order: the first review, the fixes' brief, the whole difference (`probejudge`, `supply`, `framecheck.go`,
`staging.go`, the tests), the code it calls (`catalog.Batch`, `probeSettle`/`ProbeOverdue`, the Supply's
`probeNext`, `parts.Store`'s locks), and then the report's section "The fix round".

## Runs
Named runs only, `-count=1`. I checked the PC before the runs: 3.6 to 4.0 GB free, CPU 38 to 60%.

| Run | Result |
|---|---|
| `internal/probejudge` whole | ok (0.5 s) |
| `internal/probejudge` under the race detector, in Docker (`race-archiver.sh ... 2 4g 20m`) | ok, 3.2 s, exit 0 |
| catalog `TestProbeE18bBatchPanicHoldsWriter`: a panic inside `Batch`'s function, recovered by the caller | **confirmed**: any other write then times out (2 s, `context deadline exceeded`) until the first context ends. When the statement was not yet prepared, the panicking goroutine does not even reach its recover: it blocks in `Batch`'s deferred `preparePending` until its context ends. My first version of the probe hung for 430 s for exactly that reason |
| collector `TestProbeE18bJunctionToLibrarySubfolder`: `-parts-dir` through a junction to a folder *inside* the library | **confirmed accepted**: overlap false, answered true, both before and after the parts folder exists |
| Break A: `retryOne`'s deferred `p.trying = false` removed | `TestJudgePanicAsideTry` fails ("aside false, trying true, passed over true") |
| Break B: `lookDone`'s deferred `close(ch)` skipped after a panicking look | **`TestJudgePanicInLook` still passes** (finding 4) |

## Answers

**1. The judge's recover.** I traced every step of a turn.

What holds:
- **Locks.** No lock of the judge is held at a point that can panic. The only panics possible under `j.mu` come from the clock (`passOver`, `setReady`/`markDown`), and every such place now has a deferred unlock. I checked every remaining plain `Lock`/`Unlock` pair: `turn` lines 60-75, 88-96 and 107-129, `nextJob`, `record`'s success branch, `count`, `release`. They do only map, field and arithmetic work.
- **`checking`.** It is counted down first in `check`'s deferred end, and the clock is read before the count goes up.
- **`hand`.** The file is let go by `turn`'s `defer j.release`, then passed over by `afterPanic`. `w.file`/`w.holding` are set one line after that defer, and nothing between can panic. `pend`'s entry for a try that panics is dropped and its file passed over (`retryOne`'s defer).
- **The probing channel.** `lookDone`'s defer clears the mark (if it is still this look's) and closes the channel.
- **The other worker goes on**, as far as the judge's own state is concerned. That is not true of the catalogue's state: see finding 1.

How a file comes back, traced to the door:
- While it is passed over (10 min), the row stays in phase judge.
- At `JudgeBy` (`JudgeWait`, 5 min), the Supply's `Next` calls `ProbeOverdue`. That records an unknown with why no-answer, which counts toward `ProbeSameFailsMax` = 3, and puts the file off for `ProbeRetry` (5 min).
- It then goes back to phase judge over its kept parts (`ProbeRejudge`).
- A file whose turn panics every time therefore takes 3 overdue rounds, about 25 to 30 minutes. Then the door settles it final "unchecked, no-answer" and it is downloaded (a held file stays held).
- It is counted on its row (why no-answer) and in the judge's `TurnPanics`/`PanicPassedOver`.
- The report's "if the judge's pass-over ends first, it is judged again" never happens with the defaults. `PassOver` (10 min) is longer than `JudgeWait` (5 min), so even a single transient panic costs the file one no-answer unknown.

Other points:
- **A panic every turn on every file** does not spin. Each worker pauses 1 s, doubling to a minute. Meanwhile `Ready()` stays true, so new videos keep getting their first plan and each waits out those rounds (the `judgeBusy` cap and its 10-minute bound also apply). That costs latency, not a loss.
- **Wrong "copy" or "no match":** none. A verdict is written only from a finished `decide`, the unwind skips `write`, and `passOver` drops the file's memory (`prev`, `named`) before the clock read that might panic. A verdict aside was made from a whole check.
- **A panic swallowed that should end the program:** yes, one. A panic inside a catalogue transaction now leaves the writer held for the whole run (finding 1).
- **The log line** has a constant format and no panic text, at powers of two. `Report()`'s third line always carries `TurnPanics` and `PanicPassedOver`.
- **Not covered by the recover:** the clock in `work` (`began`, `idle`) is outside `safeTurn`. That is said in the report, and the wall clock cannot panic.

**2. `Run`'s defers.**
- The order is: `running.Store(false)` registered first and run last, then `setState(StateStopped)`, then the end's clean-up under a deferred unlock.
- In a normal run all three run after `wg.Wait()`.
- The only code in `Run`'s goroutine that can panic is the start's `markDown`, which runs before any worker is started. So no worker is running when `running` goes false, and no second `Run` can start while workers judge.
- When the end's clean-up itself panics again (the same clock), Go still runs the two remaining defers. The fix's test shows this.

**3. `replayMu`.**
- Every way out unlocks exactly once: the early return through the defer, the normal path through `locked = false` and an explicit unlock, a panic through the defer.
- The `Saved` calls come after the unlock, with no lock held.
- With `Saved` nil, `replaySaved` is never appended to (`supply.go:462`), and the behaviour is the base's. The error count comes after the unlock, as the first review found; that is harmless.
- The notes of a replay that panicked are told at the next replay that ends. They are told once, because a second replay finds those saves through `SavedAs` (not fresh).

**4. Other spellings of the parts folder.**
- **Junction and symlink:** `os.Stat` follows both. The check is right when the link targets the library or staging folder itself, or one of its ancestors (the "holds" direction). It **misses a link to a folder inside the library or staging folder** (finding 2, confirmed).
- **Mapped drive against UNC:** the same holds. `SameFile` compares volume serial and file index, so a drive mapped to the library's own folder or an ancestor is caught, and a drive mapped to a subfolder is not. I did not probe an SMB share. If a server gave every folder the same file index, `SameFile` would answer "same" across that share; that can only refuse, never accept wrongly.
- **A folder that does not exist yet:** its existing ancestors are compared, with the same subfolder gap.
- **System calls that reach the library:** one `Stat` of the library itself. When the parts folder exists, one `Stat` per element of the library's path upwards. No listing and no walk.
- **A library that never answers:** the one goroutine stays until the system's own timeout. It runs once per start (`newFrameCheck`), its channel has room for one, and its answer is dropped. The report says this.
- **A library whose `Stat` fails quickly** (NAS away with a fast error) is silently left out of the comparison, and the check is counted as answered (finding 5).
- **`pathWithin`** still refuses every case the first version refused by name. The first version's `samePath` cases (one folder under two spellings) are now refused only when the folders answer within 2 s. That is as the brief allowed.

**5. The mark.**
- **The new `Lstat`** runs after `MkdirAll` and after the staging lock file was made in the same folder. That is one more call on a folder that has just answered.
- It fails closed on any error except "not there". The base's `claimStaging` also refuses on any error reading its mark, so no start that worked before is refused unless that one name cannot be read. The words would then say "a part store's folder", which is misleading but rare.
- No staged file can carry that name: staging entries are attempt parts and two-hex-digit buckets.
- **A parts folder made by the first version** (it carries `collector.mark`) is refused as `-parts-dir`, with words saying it is a staging folder. It is accepted as `-staging` for the same catalogue. The report's sentence "refused as a staging folder" reads the wrong way round (finding 6). Only test copies have such a folder.
- **The two marks** never let one catalogue's parts be swept by another catalogue. Another catalogue's parts mark is refused (`errPartsOther`), a staging mark is refused as `-parts-dir`, and a parts mark is refused as `-staging`. An unmarked folder that is not empty is not adopted.

**6. The bounds.**
- **`ProbeCloseAll`, flag off, failing for good.** Four calls at most, 7 s, one line, and the start goes on. The Supply's `probeNext` returns `probeHand` when `FrameCheck` is nil. A file set aside for its judge (`aside`, `retry_at` = `JudgeBy`) is requeued by the generic aside requeue (`state.go:403`, any reason) and downloaded unchecked. A held file stays held. The rows stay open until a start that closes them. Nothing is lost, stuck or skipped.
  - What it costs is not counted as files: only the one line says it. That is acceptable.
- **The part store's open.** A stop during a pause returns `ctx.Err()`; `Sleep` returns only the context's error. `startFrameCheck` passes it on as a stop, with no "cannot be set up" line. The refusal's words are fixed (`errPartsOpen`).

**7. Fix 10's second test.**
- The file is put in state `held` by hand. For that state, `probeSettle`'s `wanted()` takes the held branch (`catalog/probe.go:846-853`): no SQL touches `c_want`, and the fate is `FateHeld`.
- `probeWantedSQL`'s `CASE WHEN probable = 1` is the second guard. It serves a free file that is probable.
- The test proves the end result (still held by the look-alike rule, no part fetched, across a restart). It cannot tell which guard did it, so a regression in one guard alone passes while the other holds. The coder says so; that is honest.
- It uses wall-clock sleeps of 3 s. That is a flake risk, not a defect.

**8. The path with both flags off.** These are all the changes:
- the `Lstat` (fix 5);
- the bound (fix 7);
- `ensureReplayed`'s restructuring (the same as the base with `Saved` nil);
- `saveOnce`'s new `SavedLookedUp` count, under `s.mu`, in the shape of the existing count at line 164;
- the "flags ignored" line, only when such a flag is given. The launcher gives none.

Everything else is reached only with a group on. On existing tests: `TestPartsDirMarked` now reads the parts mark instead of the staging mark, which is the intended change. The worker-panic case is switched on. No other existing assertion changed; the only removed lines in the tests are the skip.

**9. Breaks.**
- Break A (the trying mark kept after a panicking try): `TestJudgePanicAsideTry` fails.
- Break B (the look's channel not closed after a panic): no test fails (finding 4).

## Findings

1. **A panic inside a catalogue transaction reached from a judge turn is now recovered, and it leaves the catalogue's only writer connection in an open transaction for the rest of the run: every download stalls.**
   - **Severity:** high when `-frame-check` is on; unreachable with it off.
   - **Evidence:** the catalogue half is **confirmed** by the probe; the judge half is by trace, since `safeTurn` recovers anything.
   - **Mechanism:** `catalog.Batch` (`catalog.go:255-270`) rolls back only on an error. On a panic it neither commits nor rolls back. The writer has `SetMaxOpenConns(1)`. `database/sql` rolls the transaction back only when its context ends, and the judge's context is the store task's, which ends at the stop.
   - **Effect:** until the stop, every write in the program waits: claims, finishes, the Supply, the ledgers. The judge meanwhile counts one turn panic and looks alive.
   - **Statement not yet prepared:** the worker itself blocks in `Batch`'s deferred `preparePending` and never reaches the recover.
   - **Routes:** `ProbeVerdict` → `probeSettle` (map, JSON and driver work inside the transaction), and `Parts.Remove` → the ledger.
   - **Before fix 1:** the same panic ended the process, and the restart dropped the transaction. A crash became a silent stall.
   - **Same class:** reads (`ProbeJobs` and `VideoCandidates` close their rows without `defer`). A panic in `Scan` holds one of the 8 reader connections until the stop.
   - **Already existing:** the supervisor's recover above store tasks that write in a `Batch` (the kept parts task's `ProbeCloseLeft`) has the same hazard.
   - **Smallest fix:** in `catalog.Batch` (Core's file), a `defer` registered after the `preparePending` defer that rolls back when the function did not return, then lets the panic go on. Until that lands, `safeTurn` should not recover a panic raised inside the door's write (a flag set around `record`'s `ProbeVerdict`/`Parts.Remove`, re-panicking), or the listing must say that `-frame-check` stays off until then.
2. **Fix 4 misses a link into a subfolder of the library or staging folder.**
   - **Severity:** low.
   - **Evidence:** **confirmed** by `TestProbeE18bJunctionToLibrarySubfolder`. With a junction `elsewhere → library\videos` and `-parts-dir elsewhere\parts`, the overlap is false and the check is counted as answered.
   - **Why:** `os.SameFile` on ancestors recognises only a link to the folder itself or to one of its ancestors. The same applies to a mapped drive to a subfolder.
   - **Fix:** resolve each existing ancestor's final path (`GetFinalPathNameByHandle`, or `os.Readlink` for a reparse point) and run the lexical test on it. Alternatively, state the limit in the report.
3. **`afterPanic` can clear another worker's hold on the same file.**
   - **Severity:** low.
   - **Evidence:** plausible by trace.
   - **Mechanism:** `turn`'s deferred `release` lets the file go before `safeTurn`'s recover reaches `afterPanic`. In between, another worker's `nextJob` can take the same file. `afterPanic` then deletes that worker's `hand` mark, drops its memory (losing the "named again" guard) and passes the file over while it is being judged.
   - **Effect:** that verdict is still whole and written, and `skip` prevents a double judging. But the file is then passed over for 10 minutes, which can cost it a no-answer unknown at the door.
   - **Fix:** drop `delete(j.hand, file)` from `afterPanic`, and do the pass-over inside `turn`'s deferred release under the same lock, with a flag set at `turn`'s normal returns.
4. **`TestJudgePanicInLook` does not guard the channel's close.**
   - **Severity:** low.
   - **Evidence:** **confirmed** by break B.
   - **Why it passes:** clearing the mark alone lets the next look go.
   - **Effect if the close were lost:** a worker already waiting on the look would wait until the stop. The code is right; only the test is missing.
   - **Fix:** have a second worker waiting in `haveRunner` (`probeWaiters == 1`) when the look panics, and assert that it returns.
5. **A library whose `Stat` fails quickly is silently left out of the folder check.**
   - **Severity:** low.
   - **Mechanism:** `foldersOverlap` drops an `other` whose `Stat` errors and still reports "answered". There is no line, and the "decided by names alone" count stays 0.
   - **Fix:** treat a failed `Stat` of a non-empty `other` like "did not answer": counted and said.
6. **The report's words on a first-version parts folder.**
   - **Severity:** low.
   - **What is wrong:** such a folder is refused as `-parts-dir`, but it is accepted as `-staging` for the same catalogue. The report's sentence says the reverse and does not mention the acceptance.
   - **Fix:** correct the sentence. Only test copies have such a folder.

## What I did not look at
- No run of the whole `internal/collector`.
- No race run of `internal/collector` or `internal/parts`; they belong to the merge run.
- No real ffmpeg, no SMB share and no mapped drive. Question 4's mapped-drive answer is by reading `SameFile`.
- I did not probe the judge's half of finding 1 end to end, because that would need a panic placed inside `probeSettle` in product code. The catalogue's half is probed, and the judge's recover is plain.
- I did not re-review the piece itself beyond these 13 commits.
- I did not check the first reviewer's probes again.

**May be listed after these fixes: 1** (either `catalog.Batch` rolls back on a panic (Core), or the judge does not recover a panic raised inside the door's write; until one lands, `-frame-check` stays off). Findings 2 to 6 are low and can follow.
