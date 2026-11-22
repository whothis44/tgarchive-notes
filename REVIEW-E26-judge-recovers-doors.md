# Review E26 (merge entry C20): the judge recovers a panic inside a door call

Independent review, Opus 5.5 at high effort, 11-16. One pass, with probes.

- Head read: `wip/copies-26` **d6f72758** (copy `wt-copies-26`), against 3781f8f2. Brief
  `BRIEF-E26-judge-recovers-doors.md` read first; the coder's report read last.
- Go source read: toolchain 1.27.3, `ix-tools/goroot-1.27.3/src/database/sql/sql.go`. Driver of the
  catalogue: modernc.org/sqlite v1.61.0 (it implements `ExecerContext`, `QueryerContext`,
  `ConnBeginTx`, `ConnPrepareContext`, `SessionResetter`, `Validator`; not `RowsColumnScanner`).
- Probes: scratch copy `wt-copies-review26-scratch` (detached at d6f72758), untracked files
  `archiver/internal/catalog/zz_probe_e26_test.go` and `archiver/internal/probejudge/zz_probe_e26_test.go`
  (left there; the catalogue probe also leaves its invented databases in `zz_probe_db_*` folders
  beside it). The catalogue probe registers a driver that wraps the real sqlite driver and panics
  once where armed (prepared statement exec/query, plain exec/query, commit), and builds a
  `Catalog` over it exactly as `Open` does (one writer, 8 readers). Every wait bounded at 5 s.

## Question 1: is the coder's reading of database/sql right?

**Yes, in every point it makes; probes confirm each.** What database/sql holds while the driver
runs, and whether a panic gives it back (`sql.go`, line numbers of 1.27.3):

| Form (who in the catalogue uses it) | Held during the driver call | Given back on a panic? |
|---|---|---|
| any call: the driver connection's mutex, `withLock` (3618-3622) | `dc` mutex | yes, `defer lk.Unlock()` (3620) |
| `DB.ExecContext` plain (`c.w.ExecContext` when a statement is not cached) → `execDC` (1701-1738) | a pool connection | **yes**: `defer release(err)` (1702-1704) |
| `DB.QueryContext` / `QueryRowContext` plain (every read of `ProbeJobs`, `VideoCandidates(Of)`, `int64s`) → `queryDC` (1776-1838) | a pool connection | **no**: `releaseConn` is called only after the driver returns (1795, 1816, 1824) or by the rows |
| `Stmt.ExecContext` prepared outside a transaction (`c.exec`'s default branch, catalog.go:322: `RemoveParts`, most writes) (2648-2665) | a pool connection (the writer's one) | **no**: `releaseConn(err)` at 2660 after `resultFromStatement` (2659); only `s.closemu` is deferred (2650) |
| `Stmt.QueryContext` prepared (the lane walk's `c.stmts`) (2790-2835) | a pool connection | **no** (2830, or through the rows) |
| `Tx.ExecContext` plain inside a `Batch` (2516-2522) → `execDC` with `release = tx.closemuRUnlockRelease` | `tx.closemu` read lock (`grabConn` 2259) | **yes** (`execDC`'s defer) |
| `Tx.QueryContext` / `QueryRowContext` inside a `Batch` (every read of `probeFileOf` etc. through `tc.r`) (2534-2541) → `queryDC` | `tx.closemu` read lock | **no** |
| `tx.StmtContext(st).ExecContext` inside a `Batch` (catalog.go:318-319, every cached write) → `Stmt.connStmt` → `cg.grabConn` (2738) → `resultFromStatement` | `tx.closemu` read lock | **no** (2660). (`Tx.StmtContext` itself defers its own release, 2427.) |
| `Tx.Commit` (2292-2325) | `tx.done` set (2304), then the driver's commit under `withLock` (2317-2319) | **no**: `tx.close` (2323) never runs: the connection stays out of the pool for good |
| `Tx.Rollback` → `rollback` (2331-2360) | takes `tx.closemu.Lock()` (2345) after `tx.cancel()` | **blocks for good** while any statement's read lock is still held (the two "no" rows inside a transaction) |
| `Rows.Next` (3040-3063, `nextLocked` 3072-3073) | `rs.closemu` read lock, `dc` mutex | yes, both deferred |
| `Rows.Scan` (3394-3410) | `rs.closemu.RLock()` (3401) with no defer | **no**: a later `Rows.Close` → `close` takes `closemu.Lock()` (3492) and waits for good |

Probe results (catalogue package, `TestZZProbeE26Batch` 36.6 s, `TestZZProbeE26Outside` 28.6 s):

(a) Inside the catalogue's `Batch` (K16's rollback in place; `catalog.go` is not changed by this
piece, so this is the main head 3781f8f2's behaviour too):
- a1, the driver panics in a **cached (prepared) write** inside `Batch`: **`Batch` hangs** (its
  deferred `tx.Rollback()` waits on `tx.closemu`); the panic never comes up to any caller; a write
  through the writer afterwards: **context deadline exceeded after 5 s** (the writer is held).
- a3, the driver panics in a **read inside `Batch`** (`tc.r.QueryRowContext`): **hangs**; writer
  **not usable**.
- a2, the driver panics in an **uncached write** inside `Batch` (plain `Tx.ExecContext`): the panic
  **comes up**; the writer **is usable** afterwards.
- a4, the driver panics in **`Commit`**, no statement pending: the panic **comes up**; the writer is
  **not usable** (the transaction's connection never goes back).
- a5, the driver panics in `Commit` with a statement **pending** (met uncached in the Batch): **hangs**
  (the deferred `preparePending` waits for the writer that the commit's panic kept).
- a6, a **Go panic of the catalogue's own code** inside `Batch`, with a cached write done and a
  transaction's rows left open: the panic **comes up**; the writer **is usable**; the write is rolled
  back (row count 0). K16 works for this case.

(b) Outside a transaction:
- b1, the driver panics in a plain read (`DB.QueryContext`, the form of the judge's reads) nine times:
  each panic comes up and **keeps one reader connection** (in use 1, 2, ... 8); the 9th read **hangs**;
  afterwards **0 of 8** reads at once answer. **8 such panics empty the reader pool for good.**
- b2, prepared read (`Stmt.QueryContext`): panic comes up, 1 reader kept (7 of 8 answer).
- b3, prepared write outside a transaction (`c.exec`, the form of the ledger's `RemoveParts`): panic
  comes up; **writer not usable** (its one connection kept).
- b4, plain write outside a transaction: panic comes up; writer usable.
- b6, `ProbeJobs` itself with its list query panicking in the driver: panic comes up; 1 reader kept.

**What a driver panic does on the main head today, whoever recovers it:** in a cached write or any
read inside a `Batch`, the goroutine hangs for good inside `Batch`'s deferred rollback, holding the
writer's one connection: every write of the program stalls, nothing ends the program, and no recover
anywhere is ever reached. In `Commit`, in a cached write outside a transaction, or in any read, the
panic does come up, but the writer's connection (Commit, cached write) or one reader connection
(read) is kept for good; any recover above it (the collector's supervised tasks, the judge without
its mark, `parts.Store.Kept`) leaves it so. Only a panic in a plain (uncached) write gives the
connection back.

## Question 2: is the narrowed mark right, both ways?

Probe `TestZZProbeE26Mark` (probejudge, through `markedCatalog` and the coder's `e26DB`):
- m1 a driver panic under `DB.QueryContext`: **marked**.
- m2 the same with an inner deferred function that recovers and panics again with the value:
  **marked**. m3 an inner deferred function that panics anew (no recover): **marked**. The original
  frames are still on the stack below the deferred calls while `markDoor` runs; `runtime.Callers`
  from a deferred function sees `gopanic` and the panicking frames; inlined frames are expanded by
  `CallersFrames` under their own names.
- m4 a driver panic **recovered by a function that returned, then raised again by its caller**:
  **unmarked (recovered)**: the walk fails open by construction there. No code under the four door
  calls does this today: the only `recover` in `internal/catalog`, `internal/parts`,
  `internal/partsledger` is `parts.Store.Kept` (parts.go:410-415), which never raises again and is not
  under a door call.
- m5 a Go panic 6000 frames deep, no database/sql: **marked** (the 4096-entry walk does not reach the
  door: `if !more { return true }`, panics.go). m6 100 frames deep: unmarked (recovered).
- (a) A panic that passed through database/sql can reach `safeTurn` unmarked only as in m4 (none
  today) or from a call not wrapped (Source's reads through `Kept`: finding 3). But **where it
  matters most the mark is never reached**: a1, a3, a5 hang inside `Batch` before `markDoor` runs, so
  the panics.go comment ("Such a panic ends the program as before E18b") is false for a driver panic
  inside `ProbeVerdict`'s transaction (finding 2). The coder's report says so under "Not verified";
  the code comment does not.
- (b) The conservative side holds in the code (`return true` when the walk ends without the door;
  a doorFrame that no longer matches makes every door panic marked), shown by m5; **no test of the
  branch pins it** (finding 5).

## Question 3: for a panic now recovered (no database/sql frame), is anything left held?

No, on every path I traced:
- `ProbeJobs`: the list's rows closed by `defer` in `probeJobRows`; per-file reads are `int64s`
  (staging.go:716-731, deferred close) and `QueryRowContext(...).Scan` (database/sql's own deferred
  close, sql.go:3553). The statement cache is not used by these plain reads; `stmtCache.lookup`
  unlocks by defer, `get` before `PrepareContext` (lane.go:450-504): no lock across a panicking call.
- `VideoCandidatesOf`: the walks through `candRows` (deferred close); the coder's table lists
  `pairDiffer` as already deferring (not re-read beyond that).
- `ProbeVerdict`: a Go panic inside its `Batch` rolls back with rows open on the transaction
  (`tx.cancel()` closes them through each rows' `awaitDone`), then `preparePending` on the free
  writer: shown by probe a6. `settleMu` is taken only in `Settle` with a defer (settle.go:104-105) and
  `Settle` runs only after a commit.
- Part store `Remove` (parts.go:538-574): `defer s.shutG.leave()`, `defer s.unlockFile(id, f)`; `s.mu`
  held only over field sums and `clear` (no panicking point). The ledger's delete is one cached exec
  outside any transaction (`RemoveParts`, parts_ledger.go:114-117): a panic there can only be a
  database/sql one (b3: writer kept; marked).
- `TestJudgeDoorPanicLeavesNothingHeld`: its read panics rise **after** the real call has returned
  (`realDoor` panics after `ProbeJobs`/`VideoCandidatesOf`), so it exercises only the judge's side, not
  the new `defer rows.Close()`; that defer is exercised by the catalogue's
  `TestJudgeDoorPanicReadRowsClosed` (the hook inside the real loops). Its verdict case is the real
  `Batch` with a Go panic in its function after the real `ProbeVerdict` wrote: the real rollback path.
  Its ledger case wraps the ledger's delete in a `Batch` of the test's own, which is not the real path
  (an autocommit exec), but it does show the store's lock and gate let go under a panic. Both tests
  pass on my run (probejudge named tests 1.9 s; catalogue `TestJudgeDoorPanic` 0.3 s).

## Question 4: a verdict whose write panicked

As the coder says, the "turn panicked" way, never twice:
- `record` (turn.go:297) takes `j.mu` only after `ProbeVerdict` returns: a panic leaves it with no lock
  held and nothing counted. `write` (turn.go:262) has no recover: no retry of a panicked write.
- Turn path: `turn`'s `defer j.releaseTurn(job.TgMediaID)` (turn.go:99): unmarked → `delete(j.hand)`,
  `PanicPassedOver++`, `passOver` (deletes `pend` and `mem`, sets `skip`) (panics.go:202-220,
  turn.go:248-255).
- Aside path: `retryOne`'s deferred handler (panics.go:226-240): `trying = false`; when the pending
  word is still this one: `PanicPassedOver++`, `passOver` (drops the word).
- The row is rolled back (a6; the coder's "a turn's word" subtest compares the whole row), stays in
  phase judge with its `judge_by`; the coder's "the Supply's bound" subtest settles it through
  `RequeueAside` + `ProbeOverdue`. A Go panic after the commit (a hook, `Settle`) would leave the word
  written once and the file passed over; the row is done, so it is not listed again: not doubled.

## Question 5: the changed tests

- `TestJudgeDoorPanicRaisedAgain`, `TestJudgeDoorPanicEndsProcess`: same assertions (raised with its
  own value, not in hand, lock free, nothing counted, the end line; the child process ends), now on a
  driver panic. As strict for what they still pin. Note `driverDoor`'s write is a plain `DB.ExecContext`
  on a driver without `ExecerContext`, whose connection database/sql does give back: they pin the
  marking, not a held connection (fine for their purpose).
- `TestJudgePanicAsideTry`: still pins trying let go, word dropped, passed over, lock free; now
  recovered and counted. **No test pins any more that a driver panic in the aside try-again path is
  raised again** (it was pinned for any door panic before) (finding 6).
- `TestJudgeWorkerPanic`: two cases added; as strict.
- Collector `TestJudgeRunAgainAfterPanic`: the `door` child now must live and count one panic: strict
  for the new behaviour. **Nothing at the collector level pins any more that a door panic of
  database/sql ends the process under the supervisor**; the judge's `TestJudgeDoorPanicEndsProcess`
  wraps Run in a recover like the supervisor's, so it is covered there (finding 6).

## Question 6: `doorRowHook`

One package-variable load and nil check per row in `probeJobRows` and `candRows`: no measurable cost.
The test registers `t.Cleanup(func() { doorRowHook = nil })` before setting it and clears it after each
call, so a failing test cannot leave it set for later tests. It is read without synchronisation: a race
report would need a test to set it while another goroutine reads rows (none today; the pattern of
`pairDifferHook`) (finding 7).

## Question 7

The difference decides nothing about what is held, wanted or skipped; `lane.go` and `state.go` are not
touched; the new log line is a constant string; the panic's value is never logged (raised again, as
before, for the runtime to print when the program ends).

## Findings

1. **High, not this piece's (pre-existing on the main head; Core's `catalog.go`, `Batch` and `Open`).**
   A driver panic in a cached write or in any read inside a `Batch` hangs the goroutine for good in
   `Batch`'s deferred `tx.Rollback()` (database/sql left `tx.closemu` read-locked: sql.go:2259, 2660,
   1786-1796; `rollback` waits at 2345): the writer's one connection is held, every write of the program
   stalls, and nothing ends the program (probes a1, a3). A panic in `Commit` keeps the writer for good
   (a4), and with a statement pending hangs in `preparePending` (a5). K16's "the writer is freed" holds
   for Go panics only (a6). Smallest fix, Core's: register the catalogue's driver behind a thin wrapper
   (in `Open`) whose methods recover a panic, mark the connection broken and return an ordinary error;
   the broken connection answers `ResetSession`/`IsValid` as bad (so database/sql drops it on release,
   with no automatic retry, which `driver.ErrBadConn` from a statement would cause) and its
   `Rollback`/`Commit` return `driver.ErrBadConn` without calling the inner driver (SQLite discards the
   uncommitted transaction when the connection closes). Until then: the judge's mark does not cover
   these cases.
2. **Medium (ours: `internal/probejudge/panics.go` comment and `judge.go:316-318`).** The rewritten
   comment says a panic raised while database/sql runs "ends the program as before E18b"; for a driver
   panic inside `ProbeVerdict`'s transaction (a cached write, any read) and for `Commit` with a pending
   statement, the turn hangs inside the door call instead, with the writer held (finding 1). Fix: say
   so in the comment, name finding 1 as the condition for "ends the program" to be true there.
3. **High by the rubric (a panic recovered with a connection held), not this piece's (pre-existing; `internal/parts`, `Store.Kept` parts.go:410-415, and the
   panics.go comment that relies on it).** `Kept` recovers every panic, including one raised inside
   database/sql during its ledger read (`s.ledger.Parts`: a reader connection kept, b1/b6 form) or during
   `refuse`'s ledger delete (a cached write outside a transaction: the writer's one connection kept, b3
   form). That is a recovered panic with a connection held, in the judge's own turn (Source's reads).
   Smallest fix: finding 1's driver wrapper makes it moot; otherwise `Kept`'s recover must raise again
   a panic whose frames include database/sql (the same walk as `sqlPanicked`). The panics.go line
   "Source's reads go through parts.Store.Kept, which recovers its own faults" should not present that
   as safe.
4. **Low (ours: `catalog/probe.go` `probeJobRows`, `catalog/vfp.go` `candRows`).** The new
   `defer rows.Close()` turns a panic inside `Rows.Scan` (database/sql's conversion; `Scan` read-locks
   `closemu` without a defer, sql.go:3401) into a hang of the deferred `Close` (probe b5: hangs),
   where before the panic came up and was marked. Practically unreachable (fixed built-in destinations;
   the driver has no `ScanColumn`), and `Row.Scan` and `int64s` already behave so. No fix needed; one
   line in the comment.
5. **Low (ours: tests).** No test pins `sqlPanicked`'s conservative side (a walk that does not reach the
   door call is marked) nor its fail-open case (m4). Fix: a direct test of `markDoor` with a panic deeper
   than the walk (as probe m5), and a line in the comment that the mark relies on no code under a door
   call recovering a panic and raising it again later.
6. **Low (ours: tests).** Pinned before, by nothing now: a driver panic in the aside try-again path
   (`retryOne`) is raised again. Fix: one case in `TestJudgeDoorPanicRaisedAgain` with the word waiting
   aside on `driverDoor`.
7. **Low (ours).** `doorRowHook` is a production package variable read without synchronisation; safe as
   tests use it now. No change needed.

## Not looked at

- `pairDiffer` and `VideoCandidatesOf`'s other reads beyond the coder's table; `ProbeVerdict`'s
  `probeSettle` paths beyond the `Batch` boundary.
- The coder's runs without K16's rollback or without the rows' defers (not repeated).
- A panic inside the real modernc driver (only a wrapper around it panics in my probes); what state a
  real mid-statement panic leaves inside SQLite's connection.
- The race detector, vet, whole packages (not mine to run).
- The behaviour on 3781f8f2 was not re-run: it follows from `catalog.go` and database/sql being
  unchanged by the difference.

may be listed after these fixes: 2
