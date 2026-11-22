# Review E18: the collector's lines (independent, Opus 5.5 high, 11-16 08:40)

**Head reviewed:** `56c5fc0d` on `wip/copies-18`, against its base `dbca91d4`. Read-only on `wt-copies-18` (its tree
was clean before and after). Probes in a detached copy `wt-copies-review18-scratch` at `56c5fc0d`, left as it is
with three untracked probe files and nothing else changed: `archiver/internal/probejudge/zz_probe_e18_test.go`,
`archiver/internal/parts/zz_probe_e18_test.go`, `archiver/internal/collector/zz_probe_e18_test.go`. The three
deliberate breaks of question 11 were put back with `git checkout`. Nothing ran against Telegram, and all data
was invented.

I read the brief, the whole difference and the code it calls (`probejudge` Run/work/turn, `parts` Put/Kept/Sweep/
disk, `supply` finish/replay, `engine` probePlan/keptSet/probeWriter, the supervisor, `stagingmark.go`,
`catalog.ProbeCloseAll`, `store.Writer.Sweep`'s rules) before I read the coder's report. The report agrees with
what I found. It already names B1/B2 and the "used by downloads" doubt; I confirmed both by my own probes.

## Runs (named only, `-count=1`; the PC was checked before each run: 5.4 to 5.8 GB free, CPU 32 to 54%)
| Run | Result |
|---|---|
| probejudge `TestProbeE18WorkerPanicEndsProcess` | **confirmed**: the child process exits with status 2 and the panic text; a recover around `Run` does not see it |
| probejudge `TestProbeE18RunPanicLeavesState` | **confirmed** (panicking clock): after the panic `running`=true, `j.mu` is held, a second `Run` returns at once, and `Stats()` is still blocked after 1 s |
| parts `TestProbeE18ShutStress` (30 rounds, 32 goroutines x 40 puts against one `Shut`) | pass. `Shut` landed mid-put in most rounds (0 to 33 kept, the rest refused); it answered 0 each time; no ledger write after it; files = rows = kept puts; gate count 0 at the end |
| parts `TestProbeE18GateAfterPanic` | pass: a panic inside a put leaves the gate count at 0, and `Shut` returns at once |
| parts, race detector in Docker (`race-archiver.sh ... ./internal/parts 2 4g 20m`, whole small package incl. the probes) | ok, 4.6 s, exit 0 |
| parts benchmarks, `-cpu 8` | the gate's enter+leave under 8 goroutines takes **50 ns**. `Kept` of a 1 MiB part takes 737 us alone and 206 us/op in parallel; a `Kept` of a part not kept takes 84 ns, gate included |
| collector `TestProbeE18PartsDirThroughJunction` | **confirmed**: `-parts-dir <junction to the library>\parts` is accepted |
| collector named tests: `TestFlagsOffAsToday`, `TestFrameCheckOnEndToEnd`, `TestEngineOtherPartSize`, `TestStopShutsPartStore`, `TestFrameCheckOffClosesOpenRows`, `TestPartsDirRefused`, `TestPartsDirMarked`, `TestFrameCheckRestart`, `TestRunStartsFingerprintWorker` (FFMPEG_PATH set), `TestKeptPartsTask`, `TestKeptPartsTaskStopsInSweep`, `TestJudgeStopsWithinGrace`, `TestJudgeRunAgainAfterPanic`, `TestFrameCheckFlags`, `TestFingerprintsOffAsToday` | all pass (25 s + 2 s) |
| existing end-to-end on the branch: `TestKillRestart`, `TestE2EExactSame`, `TestStopWithCopyInFlight` | pass (12 s) |
| supply `TestSupplySavedHook`; parts `TestShut*` | pass |

## Answers to points A to E
**A. `ensureReplayed`'s hand-made unlock.**
- *Returns that unlock:* the "already replayed" path unlocks once and returns. The path after `replay()`, with or
  without an error, unlocks once and then makes the `Saved` calls.
- *A panic inside `replay()`* (for example in `Config.Duplicate` or `saveOnce`) leaves `replayMu` locked for good.
  On the base, the `defer` unlocked it. On the branch, every later `ensureReplayed` (`Next`, `record`, `Retry`,
  `Recover`) would block for ever. Today no program path differs: the first caller is `Run`'s `sup.Recover()`, in
  the main goroutine with no recover, so the program ends either way. This is a trace, not a probe (finding 3).
- *Work that left the lock:* the `Saved` calls (intended) and the error count (`st.Errors`, `LastError`), which is
  still under `s.mu`. `replayed.Store(true)` and the `Duplicate` calls stay under `replayMu`.
- *With `Saved` nil:* `replaySaved` is never appended to, so the behaviour is the base's apart from that ordering.
  A second caller can enter `replay` before the first caller's error is counted, which is harmless.

**B. Panics in the judge.**
- *B1 confirmed:* a panic anywhere in a worker's turn outside `Find`, `Found`, `SelfTest` and `Check` ends the
  process. The probe shows this with the catalogue's `ProbeJobs` panicking.
- *B2 confirmed, but only through a panicking clock.* The only call in `Run`'s own goroutine that can panic is
  `markDown`'s `Clock.Now`, under `j.mu`, before the defer exists, and again inside the deferred end. The program's
  clock cannot panic.
- *Smallest safe fix, in `internal/probejudge`:*
  1. In `work`, wrap each turn in a closure with `defer recover()`. On a panic, count it (`Stats.Panics`) and wait
     `j.pause(w)` before the next turn. `turn` already has `defer j.release(id)`, so the file in hand is let go.
     Audit `turn`'s locked sections (lines 60-75, 88-96, 106-128): they are plain map and field work. A panic
     there would deadlock instead of crash, so either keep them free of anything that can panic or give them
     `defer` unlocks.
  2. `haveRunner` should close `j.probing` with a defer. Every call in `lookAt` that can panic is already
     recovered, so this is for safety.
  3. In `Run`: register `defer j.running.Store(false)` first, read the clock outside the lock, and do the end's
     cleanup with `j.mu.Lock(); defer j.mu.Unlock()`.
- *The fingerprint worker (`vfp`) does not have the hazard.* `Run` defers its cleanup right after its
  compare-and-swap, its loop runs in the supervisor's goroutine, and its one helper goroutine recovers its own
  panic (`vfp.go:1259`).
- *The "kept parts" task does not have it either.* It runs in the supervisor's goroutine. `fc.mu` is held only
  around map work, and `Sweep`'s gate and the part store's own locks are let go by `defer`. A panic there is
  recovered and the task is restarted after the supervisor's pause.

**C. `parts` gate.**
- *Contention:* the gate's mutex is held only for its counter and is never held across disk or ledger work. Under
  8 goroutines it costs 50 ns per call. `Kept` on a lane's path reads the ledger, the disk and SHA-256 (206 to
  737 us), so the gate adds under 0.03%. The engine asks `Kept` only for indexes in `x.kept`. I measured the
  gate's own cost rather than the base's `Kept`, because the base's package would have to be copied to bench it.
- *Accounting on a panic:* every gated call registers `defer s.shutG.leave()` right after `enter`. In `Kept` the
  recover is registered first, so `leave` runs before it. The probe confirms that the count stays right.

**D. Early returns in `Run`.**
- *Between `startFrameCheck` and the tasks:* `parts.Open` makes the folder and reads the ledger. It starts no
  goroutine and keeps no file open. The judge, the `vfp.Worker` and `New` start nothing until `Run`. The parts
  folder has no lock, only its mark, which stays as intended. `stg.release()` is deferred.
- *Leaks:* nothing is left running or open. No engine exists on those paths, so nothing needs a `Shut`.
- *On the normal stop:* `shutParts` follows `waitGroup(&mainWG, closeBound())`. Each account task's
  `stopEngine` waits for `Engine.Wait`. Accounts added later join `mainWG` (`c.addWG`). An engine restarted by
  `startEngine` is waited for first (`stopEngine`).
- *When `mainWG`'s wait times out*, an engine may still be running. Its later puts and `Kept` calls are then
  refused (`ErrShut`, counted), which is the intent.

**E. The coder's doubts.**
- *"Used by downloads" counts the judge's reads:* yes. `FileSource.Part` calls `Kept`, which counts `usedParts`.
  The engine's `LaneStats.Probe.KeptParts` is the true "requests saved" figure (finding 6).
- *The three test fields* (`partsTune`, `partsShutWait`, `keptPartSize`) are unexported. `RunCommand` does not set
  them, and their zero values give the real program's values, so they cannot matter in the program.
- *`ErrPartsDir`* is printed through `partsWord` in `startFrameCheck`'s log line and in `RunCommand`'s exit line,
  as fixed text. `runWithPages` hands `Run`'s error back to `RunCommand`, and `SignInOnly` returns before
  `startFrameCheck`. Any other route through `errWord` would print "an error of type ...": no path, but not
  helpful. I found no such route (finding 11).
- *Silence with both flags off* is what the brief asked for.
- *`-card-decoders ""`* makes `auto` the CPU without saying so (finding 9).

## The brief's twelve questions

**1. Flags off as today.** These are every changed line in the four lent files, read with both flags off:

| File | What changed | Reached with both flags off | Does what then |
|---|---|---|---|
| `collector.go` | two imports; the `Config` fields | — | zero values |
| `collector.go` | `startFrameCheck` | yes | returns `nil, nil` at once |
| `collector.go` | `scfg` and `frameCheckSupply` | yes | `Saved = fingerprintsSaved(nil) = nil`, `fc` is nil, so the literal is the same value |
| `collector.go` | `closeProbesAtStart` | yes | the one new call (below) |
| `collector.go` | `frameCheckTasks` | yes | `vfp` and `fc` are nil: starts nothing |
| `collector.go` | `shutParts` | yes | returns at once, with no stop step |
| `staging.go` | import, three fields | — | zero values |
| `staging.go` | `Kick` (`fingerprintsKick`) | yes | `func() { (*cp).Kick() }`, the same as the base's `func() { cp.Kick() }` (both read `cp` when called) |
| `staging.go` | `NotYet` (`fingerprintsNotYet`) | yes | nil |
| `staging.go` | `newFingerprints` | yes | returns nil before anything, with no log line |
| `staging.go` | the two hourly calls | yes | return at once |
| `account.go` | `fc` read under `c.mu` | yes | nil |
| `account.go` | `enginePartStore(nil, ...)` | yes | nil, so `ecfg.Parts` is the base's zero |
| `command.go` | help text; `addFrameCheckFlags` (defaults); `check()` | yes | the defaults pass |
| `command.go` | `apply` | yes | sets fields that are read only when their group is on |
| `command.go` | the exit switch | yes | gains `ErrPartsDir`; `partsWord` is `errWord` for every other error |

- *Started, made or armed:* no folder, no task, no timer.
- *`ProbeCloseAll` at the start:* two `Batch` transactions, each with a `LIMIT` select that finds nothing, plus
  `CheckpointGap`. It holds the writer only for those two empty transactions, before any task, and writes nothing
  (the coder's `data_version` check, which I re-ran).
- *While the catalogue fails:* it is retried doubling to a minute, and a stop ends it. There is no limit on the
  count (finding 7).
- *Evidence:* `TestFlagsOffAsToday` passes, and so do `TestKillRestart`, `TestE2EExactSame` and
  `TestStopWithCopyInFlight`. I did not compare a request digest against the base.

**2. The stop's order.** From `<-ctx.Done()`, who can still write at each step:
- `stopTasks`, then the wait on `mainWG`: the engines stop. The judge, the kept parts task and `vfp` keep
  writing (verdicts, `ProbeCloseLeft`, part removals, fingerprints).
- `sup.Retry`, `Settle`, `stopCounts`: the Supply's writes.
- `stopStore`, then the wait on `storeWG` (at most `StopGrace`): all five store tasks end. `TestJudgeStopsWithinGrace`
  and `TestFrameCheckRestart/waiting` show the judge ending with a check blocked until its context ends.
  `TestKeptPartsTaskStopsInSweep` shows the kept parts task ending in the middle of a sweep. `ProbeCloseLeft`'s
  chunk is one transaction with the context.
- `shutParts` (at most 10 s): only abandoned probe writers, and tasks that outlived the grace, are still in a
  gated call.
- `supv.Wait(1 s)`, `markStoreStopped`, `endSupply`, `closeStore`.

A task that outlives the grace meets a part store that refuses it (`ErrShut`), and then a closed catalogue, which
gives errors that are counted. I found nothing that panics or hangs (the `database/sql` calls return "closed").
Early returns: see D.

**3. `Shut`.**
- *A put that began before `Shut`* cannot write after `Shut` has answered 0. Both `enter` and `Shut` take
  `g.mu`, so there is no window between "is it shut?" and "count me in flight".
- *A put stuck past the bound* finishes after `left > 0` is reported. That is by design, counted and logged.
- *Lock:* the gate's lock is never held across disk or ledger work, and contention is negligible (C).
- *Calls after `Shut`:* `Kept` answers false with no ledger read. `Sweep` and `Remove` are refused, and the judge's
  reads go through `Kept`.
- *`Shut` twice* is fine.
- *`Shut` while a sweep runs* waits for the sweep, which is bounded by the wait.
- *Evidence:* the stress probe and the race detector are clean.

**4. `Config.Saved`.**
- *Locks:* no Supply lock is held at either call (the test checks all three locks with `TryLock`).
- *The collector's closure* calls `Staged`: a bounded set and a non-blocking kick. It cannot block, and it panics
  only if `vfp` does.
- *Once per fresh save.* A retry or a replay of the same save finds it already recorded and goes through `SavedAs`
  (`fresh=false`), so it is never told twice.
- *Duplicates are told too* (`res.Duplicate` with `fresh`), with `revived` false in practice. The closure ignores
  them, and the comment says "each save", which is right.
- *A revived save on the `SavedAs` path gets no call and is counted nowhere* (finding 12).
- *With `Saved` nil,* a finish is as on the base.

**5. `startEngine`.**
- *The part-size condition* reads the same `pol` the engine is made with, and `e.lim` is fixed at `engine.New`.
  The store is read once under `c.mu`.
- *A restart in the middle of a check:* the old engine is waited for, and the abandoned writer is bounded by
  `probePutTimeout`.
- *Two accounts share one store.* `Put` is per file, and a file is with one lane at a time.
- *An account added later* reads `c.stg` again when it starts.
- *Engine without a store:* the lane refuses the plan (`ReasonProbeNoStore`), and the Supply settles it through
  `ProbeLaneRefused`. `TestEngineOtherPartSize` shows the plan handed out once, no check, the row "unchecked",
  and each part fetched once. No requests are spent on the refused plan.
- *An engine cannot fail to start because of the frame check:* `engine.New` refuses only a store at another part
  size, which `enginePartStore` prevents. In the program every policy's part size is 1 MiB, so that branch never
  runs.

**6. Rules end to end.**
- *Covered by tests:*
  - A "copy" is held with its reason, never saved, and fetched only for its plan, and stays held across a
    restart.
  - An unrelated video is downloaded with its kept parts taken in place of requests: answered requests equal its
    parts, none twice, and kept parts taken equal the probe's parts.
  - A stop during a fetch, or while a file waits for its judge, fetches no part twice after the restart.
- *Not tested here* (finding 10):
  - A file already held by a look-alike rule and then judged "no match". The engine ignores the plan of a
    `HoldUnlessSame` file (`lane.go:824`), so it stays on the merged path, but no collector test shows it.
  - ffmpeg missing for the whole run (`fakeJudge.failST` exists but is unused).
  - The real ffmpeg (the coder explains why).
  - A kill instead of a stop.
- *A kill, by trace:* a put cut by a kill can leave a part file with no row. It is not offered at the restart
  (`Indexes` comes from the ledger) and is swept after `SweepAge`, so at most the parts that were in flight are
  fetched again. That is acceptable, but it is not what the stop test asserts.
- *No exact edge is written by this path:* the judge writes only through `ProbeVerdict`, and the collector adds no
  call.

**7. Waits.**
- *The judge and the part store* are reached only from the store's tasks and from the engine (merged, bounded:
  `probePutTimeout`, `Kept`'s 2 s read).
- *The finish* adds `Saved`, which does not block.
- *The copier:* `NotYet` is bounded by the copier's own 2 minutes (merged). The fingerprint worker's hold of a
  staged video (up to 90 minutes, only while there is room) is the merged design, and the copier goes on with
  other files meanwhile.
- *The library folder:* nothing new reads it. `vfp` reads staged copies, and the sweep reads the parts folder.
  Finding 4 is the one way the parts folder can end up inside the library.
- *Not tested at collector level:* a slow judge or a slow part-store disk while other files download.

**8. The parts folder.**
- *Lexical checks are right:* the case and slash variants, inside or holding either folder, and the drive's root.
- *Missing: other spellings of the same folder.* A junction or a mapped-drive spelling into the library is
  accepted (confirmed for a junction, finding 4).
- *A folder inside the data folder* is not refused. That is harmless, because the sweep touches only its own
  bucket names.
- *Two collectors:* the same catalogue is stopped by its lock, and another catalogue is refused by the mark.
- *A relative `-parts-dir`* resolves against the start folder (finding 9).
- *A relative staging folder* is made absolute in `newStaging`.
- *The sweep* removes only empty two-hex-digit buckets, number folders in the matching bucket, and number or
  `.tmp` files in them, older than `SweepAge` and with no row (`sweep.go:109-210`, `disk.go:142`). It cannot
  remove an owner's file unless the owner's file has exactly that shape.
- *The mark* is the staging folder's own (finding 5): an unmarked folder that is not empty is adopted, and another
  catalogue's folder is refused (tested).

**9. Words and privacy.**
- *Format strings:* every new `logf` has a constant format and prints counts, `decoderWord` of a word already
  checked against `^[a-z0-9_]{1,32}$`, `Runner.Where()` (fixed words), `partsWord` (fixed) and `errWord`.
- *`parts.Open`'s error* is replaced by `errPartsOpen` and not wrapped, so it cannot leak.
- *`Sweep`'s error* is only counted.
- *`-parts-dir` and `-ffmpeg`* are never printed.
- *The flags' help* carries no path.
- *`account %d`* is the app's own account number, as in the existing lines.

**10. The flags.**
- *Defaults:* all as the brief (the test asserts each).
- *Refusals:* tested, and they happen before anything is done.
- *A flag given with its group off* is ignored without a word (finding 9).
- *Existing flags:* no meaning or default changed. The only other `-ffmpeg` is in the separate `tgarchive thumbs`
  command, and `deploy/` passes none of the new names.
- *The launcher and watchdog:* I read only `deploy/` and `cmd/`, not the `a3` scripts in the project folder.
  A run with today's arguments is a run with both flags off.

**11. The tests.** I broke three rules on purpose; each was caught, and each passed again once restored:
- `replay`'s `Saved` calls under `replayMu`: `TestSupplySavedHook/replay` fails ("1 locks held").
- `Shut` that never waits for the idle signal: `TestShutWaitsForPutInFlight` fails ("did not return after the put
  ended").
- The kept parts turn that returns after a failed sweep: `TestKeptPartsTask` fails ("ProbeCloseLeft did not run
  after a failed sweep").

The coder's sixteen mutations match what I read. Rules with no test are listed in finding 10.

**12. The brief.**
- *Refusing the start when the parts folder cannot be set up:* acceptable while `-frame-check` is the owner's
  explicit choice. But `parts.Open` reads the catalogue (the ledger), so a transient catalogue error refuses the
  start, while the recovery and the staging sweep would retry. A stop during that read is reported as a refusal
  (finding 8).
- *`Shut` instead of a fixed 10 s:* right. It is bounded and costs nothing when nothing is in flight.
- *An engine without a part store at another part size:* fine, and it is unreachable today.
- *No kick of the judge from the Supply:* the judge's idle is 30 s, so a checked video can start up to about 30 s
  later than its fetch. Lanes are free meanwhile, so this is latency only. That is acceptable, but nobody has
  measured it.
- *`ProbeCloseAll` retried without a limit:* with the flags off, this is a new way for a start to stall every
  download for as long as the catalogue fails on `c_probe` (finding 7).
- *Point 3.4 (a) assumed the supervisor restarts the judge.* It cannot, which is finding 1. The brief's "stop and
  say so" was followed.
- *"Give it the same mark the staging folder has"* is finding 5.

## Findings
1. **A panic in any judge worker ends the whole collector, downloads included.** Medium, and high once
   `-frame-check` is on with any panic-capable bug, since a deterministic panic on the oldest job would crash at
   every restart. **Confirmed** by `TestProbeE18WorkerPanicEndsProcess`. With the flag off it is unreachable.
   *Fix (in `internal/probejudge`):* a per-turn recover in `work`, counted and followed by `pause(w)`, with
   `turn`'s locked sections audited (B), plus a test of a panicking door. It should land before or with this
   branch, and at the latest before `-frame-check` is switched on.
2. **A panic in `Run`'s own goroutine leaves `j.mu` held and `running` true.** The task then ends for good, and
   `Stats()` blocks the hourly line, and with it the counts task. Low: **confirmed** only through a panicking
   clock, which the program's clock is not. *Fix:* the defers described in B.
3. **`ensureReplayed`: a panic in `replay` now leaves `replayMu` locked** (the base unlocked it). Low: plausible
   by line-by-line trace (A). No program path differs today. *Fix:* unlock in a deferred closure guarded by a
   flag, and make the `Saved` calls after it.
4. **The parts folder's overlap check is lexical.** A `-parts-dir` reached through a junction (or a mapped drive
   against a UNC library) inside the library or the staging folder is accepted, and the sweep then walks the
   library over Wi-Fi. Low, since it needs the owner to give such a path. **Confirmed** for a junction
   (`TestProbeE18PartsDirThroughJunction`). *Fix:* in `pathWithin`, also compare each existing ancestor of either
   path with `os.SameFile`, or compare paths with junctions resolved.
5. **The parts folder carries the staging folder's mark**, with the same file name and the text "tgarchive
   staging folder of catalogue". An old parts folder is then accepted as `-staging`, and an old staging folder as
   `-parts-dir` when it is no longer the current one. A folder that is not empty and has no mark is adopted. The
   mark is also counted "not ours" at every sweep. Low: both sweeps remove only entries named as their own, so I
   see no loss, only confusion. *Fix:* the one helper takes a role (mark name or first line); a parts folder that
   is not empty and has no mark is refused, or at least logged.
6. **The hourly line "used by downloads: N parts" also counts every verified read by the judge.** Low:
   **confirmed** by reading (`source.go:37` calls `Kept`). *Fix:* reword the line in `internal/parts`
   ("handed out, downloads and checks"), or count by caller; the engine's `KeptParts` is the "requests saved"
   figure.
7. **The start's `ProbeCloseAll` has no limit on its retries.** With both flags off, a catalogue failure confined
   to `c_probe` now stops every download at the start for as long as it lasts (no flag-off run could stall there
   before). Low: plausible, not probed. *Fix:* after a few failures go on with one line, and close the rows at
   the next start. Or keep the brief's rule and say so.
8. **A stop, or a transient catalogue error, while the part store opens is reported as a refusal.** The message
   is "part store cannot be set up", with `ExitRefused`, because `errPartsOpen` hides `ctx`'s error. A transient
   ledger error refuses the start without a retry. Low: by trace (`framecheck.go:214-216`, `parts.go:184-192`).
   *Fix:* return `ctx.Err()` when the context has ended; optionally retry `Open` as the recovery is retried.
9. **The flags.**
   - A flag given with its group off is ignored with no line.
   - `-card-decoders ""` makes `auto` the CPU and the start line still says "auto".
   - A relative `-parts-dir` resolves against the start folder.

   Low. *Fix:* one start line naming the ignored flags; the decoder line says "auto (no card listed: cpu)"; refuse
   a relative `-parts-dir`.
10. **Rules with no test.**
    - ffmpeg absent for the whole run: let through only at the merged bound, and counted.
    - A file held by a look-alike rule and then judged "no match" stays held.
    - A kill, not a stop, in the middle of a fetch and while a file waits for its judge.
    - `ProbeCloseAll`'s retry on failure.
    - The start line for `-frame-check` without `-fingerprints`.
    - Lanes and the copier going on while the judge or the part store's disk is slow.

    Low. *Fix:* the first two at least, with `fakeJudge.failST` and a `HoldUnlessSame` video.
11. **`ErrPartsDir` is not among `words.go`'s sentinels.** Any future route through `errWord` would print a type
    name. Low: no route found. *Fix:* add it to the sentinels when `words.go` is next lent.
12. **A revived save recorded on the `SavedAs` path is not told to the worker and is counted nowhere.** That video
    gets no fingerprint. Low: by trace. *Fix:* count it in `supply.Stats` ("saves recorded by look-up: revival
    not known").

No finding of a file skipped, lost or stuck, or of a lane, slot, finish or the copier waiting, with either flag
off or on.

## What I did not look at
- I did not run the real ffmpeg through the collector, or a card decoder.
- I did not compare a digest or request count against the base (I ran the existing cases on the branch only).
- No race run on `internal/collector`. Its new concurrent code (the tasks and the stop's `Shut`) needs one in the
  merge run, together with `internal/parts`, which I ran.
- I did not read the `a3` scripts or the watchdog's own files in the project folder.
- I did not bench the base's `Kept` itself: I measured the gate's added cost instead.
- I took the merged `vfp`, `probejudge` and `engine` behaviour from their code and tests, without probing it
  beyond B.

**May be listed after these fixes: 1** (in `internal/probejudge`, on a branch of its own merged before or with this
one; the rest are low and can follow).
