# Review K19: the database driver behind a guard (Core, independent reviewer, 2026-11-16)

Branch `wip/core-guard` at 6d2b9a03 (from 78739d59). I worked read-only in the scratch copy
`wt-core-guard-review-scratch` (detached at 6d2b9a03). Five uncommitted probe files are there:
`internal/sqlguard/zz_probe_k19_{paths,every,args}_test.go`, `internal/catalog/zz_probe_k19_same_test.go`
and `internal/watchdog/zz_probe_k19_child_test.go`. Every go command went through `runs-core-k5/go1.sh`. One
of them waited 2,993 s for the lock while the other agent ran; none got exit 97 or 98. I did not use the race
detector because no question needed it. Invented data only. Nothing was committed or pushed.

## Answers

**Q1. Does the guard accept every concrete value the inner driver hands out? Yes.** I read modernc v1.61.0
(`conn.go`, `stmt.go`, `rows.go`, `tx.go`, `result.go`, `driver.go`). Every path returns exactly one type per
kind:

| Kind | Type | Built in |
|---|---|---|
| connection | `*conn` | `newConn` |
| statement | `*stmt` | `newStmt`, through `newStmtContext` |
| rows | `*rows` | `newRows`, on the cached, script and empty paths alike |
| transaction | `*tx` | `newTx` |
| result | `*result` | `newResult` |

`*Driver` has no `OpenConnector`. An error path can hand back a typed-nil value, but always with an error, and
the guard returns nil on an error.

Probe `TestZZK19Paths` covered:
- 14 DSN variants: the catalogue's writer and reader, a plain file, `_txlock` deferred and exclusive,
  `:memory:`, `file::memory:`, `vfs=memdb`, a file with the read-only attribute, `mode=ro` on it,
  `immutable=1`, a bad `_pragma`, a bad `_txlock`, a missing folder.
- 24 statements: INSERT, RETURNING, PRAGMA read and write, empty, blank, comment only, two scripts of two
  statements, a SELECT with no rows, errors, VACUUM, and a bound one.
- Each statement through `conn.QueryContext`, `ExecContext`, `Query`, both prepares, and the statement's four
  run methods twice. Then three `BeginTx` options, `Begin`, `Ping`, `ResetSession`, `IsValid`, and after Close.
- Both at the driver level and through database/sql, plain driver on one file and the guard on another.

Result: **8,260 steps compared, 0 differences, 0 refusals.** The types seen were the same five on both sides.

On a closed connection (`TestZZK19ClosedConn`), modernc's Ping, Exec, Query, Prepare and Begin each panic with a
runtime error. Through the guard each one ends the process. database/sql never calls a driver connection after
closing it, so this is not reachable.

**Q2. Does database/sql take the same path for the wrapper as for the inner value? Yes, for every assertion
it makes.** The assertions in Go 1.27.3:

| Interface | Where (`sql.go` unless named) |
|---|---|
| SessionResetter, Validator | 608, 623, 1908-1909 |
| DriverContext | 876 |
| Pinger | 889 |
| io.Closer (on the connector, not on the driver) | 956 |
| ExecerContext, Execer | 1705, 1708 |
| QueryerContext, Queryer | 1777, 1780 |
| RowsColumnScanner | 3080, 3432 |
| RowsNextResultSet | 3094, 3138 |
| the five `RowsColumnType...` | 3307-3321 |
| NamedValueChecker on the statement and the connection | `convert.go` 131, 133 |
| ColumnConverter | `convert.go` 135 |
| ConnPrepareContext | `ctxutil.go` 14 |
| StmtExecContext, StmtQueryContext | `ctxutil.go` 64, 81 |
| ConnBeginTx | `ctxutil.go` 98 |

`Valuer` (`convert.go` 67, `sql.go` 440) is asked of the caller's arguments, not of the driver's values.

Each of these gets the same answer from the wrapper as from its inner value, because the guard checks equal
sets over all 30 interfaces plus io.Closer. The identity checks also hold:
- `err != driver.ErrSkip` (1720, 1793) and `errors.Is(err, driver.ErrBadConn)` see the inner error untouched.
- The probes' error values match on type, text and code.

On the coder's two tests:
- `TestWrapperInterfacesExact` proves the sets only for the values one open returned: one DSN, a prepared
  statement's rows, one BeginTx.
- `TestOptionalListIsFull` proves the list is complete against the toolchain source. It does not prove the
  paths. `RowsColumnScanner` is matched by method names only, which is acceptable.
- What covers the remaining paths is the run-time check, and it fails loudly (an error), never silently.
  Together with the Q1 probe I call this sufficient.

**Q3. Does anything change when nothing panics? No.** `TestZZK19SameDoors` ran the catalogue's own doors on two
copies of one invented catalogue. The plain side used `zzOpenPlain`, which is `Open`'s own code with the name
`"sqlite"` (its checkpointer plain too). The guard side used `Open`. The doors run:
- accounts, chats and wants, a known-list import, and 120 messages with up to three media each
- Totals, ListChats, WantedByServer
- 80 `ClaimNext` with progress, release, `Saved` (all three locations, duplicate hashes) and `SavedAs`
- MediaState, and the doors' own refusals (bad hash, unknown id, fingerprints for no file)
- three Batches of 20 cached `SaveProgress`, `AddHourly` and reads each, plus a Batch ending in a unique error
- Hourly, Settle, settings saved and loaded
- writer errors with codes 2067, 1299, 275, 787 (`isForeignKey` true), 1555 and 1
- 26 bind types (nil, every integer width, `MaxInt64`, `1<<62`, float, infinity, strings, blobs both empty
  and nil, bools, `time.Time`, the `sql.Null*` types, `sql.Null[T]`), named parameters, and a bad bind
- a read-only handle refusing a write (code 8)
- a busy writer between two handles (code 5, `IsBusy` true, after the 5 s timeout), and the same with a
  context's end
- the whole file dumped table by table at the end

Result: **2,108 lines compared (688 results, 21 of them errors, plus 1,420 table rows), 0 differ.**
`ErrorWords`, `IsBusy`, `errors.As` code and the text were all the same.

`TestZZK19SameMigration` migrated a v7 file to v25 both ways: 280 lines of schema and rows, the same.

Not produced: SQLITE_LOCKED (code 6), which needs a shared cache that the catalogue does not use.

**Q4. Does every way into the driver end the process? Yes.**
- `TestZZK19EveryMethodDirect` armed each of the wrapper's 29 methods in turn, as listed by reflection over
  the five wrapper types. Every one reached the end once, nothing came back, and nothing panicked up:
  - Driver: Open
  - Conn: all 12 methods
  - Stmt: Close, NumInput, Exec, Query, ExecContext, QueryContext
  - Tx: Commit, Rollback
  - Rows: Columns, Close, Next and the five `ColumnType...`
- `TestZZK19EveryMethodThroughSQL` reached 14 forms from database/sql:
  - Ping, ResetSession on reuse, IsValid on return to the pool
  - `Rows.Columns`, `ColumnTypes`, `Rows.Close`, `Stmt.Close`, `NumInput`
  - Rollback, BeginTx, the connection's close from `db.Close`, the open from the pool's opener
  - the rows' own goroutine closing on a context's end, and the transaction's own goroutine rolling back on a
    context's end

  All ended once.
- The guard's refusal paths (an inner Close or Rollback) run under the caller's deferred guard.

What is not under a guard:
- the `driver.Result`. modernc's only returns two stored numbers.
- modernc's own goroutine `interruptOnDone` (`sqlite.go:113`). It calls `sqlite3_interrupt` when a context ends.
  A panic there is an ordinary unrecovered panic: the runtime ends the process with exit 2 and prints the value
  itself, including its text. That is outside the guard, and the process ends either way.

No method value is handed out.

Two at once (`TestZZK19TwoAtOnce`): two goroutines panicking inside the driver together, 20 rounds. Each round
had one end and one report.

A real panic through modernc's own code: a SQL function of ours, called by SQLite's step, panicking in a
prepared write inside a transaction. It ended the child process, as shown under Q7.

**Q5. Can the end hang? Yes.** `end` writes the report synchronously and only then exits.
`TestZZK19ChildByTheWatchdog` started a child through the watchdog's own `ExecStarter` with an error-output
pipe that the parent never reads. The child filled the pipe first, then hit a real driver panic:
- `fill-guard`: **the child did not end within 15 s** and was killed.
- `fill-runtime` (the runtime's own unrecovered panic, no guard): the same, it hangs.
- `fill-cure` (the write on its own goroutine, exit after it or after 3 s, whichever comes first): **ended with
  code 2 after 4.5 s**, which is 1.5 s of filling plus the 3 s timer.

So this exposure is not new, the runtime's own crash text has it too, but the stall this piece removes comes
back when the watchdog stops reading. A watchdog that is gone closes the pipe, and then the write fails at once
and the exit follows. The cure is finding 1.

The rest of Q5:
- A panic value whose `Error` panics or blocks, or whose `String` blocks, is never called. Its type is not the
  runtime package's, and `%T` calls no method. All three ended at once.
- `debug.Stack` is bounded: depth 10 gave 2.6 KB; depth 1,000 and depth 100,000 both gave 17 KB (197 lines), in
  1.1 ms and 55 ms.
- The seams `endProcess` and `errOut` are unexported package variables: no other package can set them.

**Q6. Does the report hold any of the panic value's text? No.**
- Values tried: a string, an error, a wrapped error (`%w`), a `fmt.Stringer`, a type of another package
  implementing `runtime.Error`, an int64, and an `id %d` string. Each carried an invented statement, path or
  number. None of that text reached any report, across 43 ends.
- The `panic(` frame shows only two pointers. There is no `[recovered` line.
- Frame arguments showed as `0x0?` in my probe (`TestZZK19FrameArgs`). Under the register ABI a spilled
  argument can show its raw word, but that is equally true of the runtime's own crash text; finding 4.
- The first line always begins with `"\n" + "panic: sqlguard: ..."`. In the real child, after a log line left
  without its line end, the watchdog's keeper kept text starting `panic: sqlguard:`.
- Each write is one `os.File.Write`, held under the file's write lock, so it does not interleave with the
  program's other `os.Stderr` writes.

**Q7. Is the end classed as a crash and restarted as one? Yes, by the watchdog's own code.**
- In my child probe:
  - The parent ran the real chain: `ExecStarter`, `copyStream`, `newKeeper`, `keeper.evidence`, `Classify`,
    `keeper.kept`, `crashlog.ParseReport`. That is the sequence of `loop.go` `watch` and `after` (lines 304
    and 421-433).
  - The child ran a real modernc panic through the guard.
  - Result: exit code 2 after 27 ms, class `crash`. Cause: "panic (its message is only in the report)".
    1 goroutine.
  - `top` runs from our function through `funcTrampoline`, `_sqlite3VdbeExec` and `_sqlite3Step` to
    `Xsqlite3_step`. No invented text was kept.
- The coder's child test is honest about the outcome, but it uses a copy of the prefix rule (two of the four
  prefixes, read line by line with bufio), not the keeper; finding 2.
- After the end:
  - `Decide` (`policy.go:65`): a delay of 2, 4, 8, 16, then 30 minutes, back to 2 after a 30-minute run.
  - Three deaths in a row, each within 10 minutes of its start: no restart, "a person is needed".
  - At most 12 restarts in 24 hours.
  - The crash dump is written by `crashlog.WriteDump`.
- The next start:
  - The catalogue's write-ahead log is recovered by SQLite at open.
  - Files left "in transfer" go back to wanted through `Catalog.RecoverActive` (`state.go:480`), called from
    `supply.go:387` and `cmd/tgarchive/app.go:106`.
  - The catalogue's lock and the staging folder's lock are operating-system locks (`collector/lock.go`,
    `lockFile`), dropped when the process dies.
  - The status file is written again by `writeStatus` (`collector/account.go:1035`).
  - The watchdog's marker is replaced by `crashlog.WriteMarker` at the start.
  - Each of these is handled as after any kill.

**Q8. The cost: none outside the spread, and one more allocation per wrapped value.** Same process, plain and
guard alternating, three rounds each, each on its own copy of one 200,000-file catalogue (`fillLanes(200000,
397)`). PC cpu 56 %, 9.1 GB free.

| Per call | Plain (3 rounds) | Guard (3 rounds) |
|---|---|---|
| ClaimNext (300 per round) | 1.290, 1.522, 1.243 ms | 1.694, 1.267, 1.347 ms |
| cached write in a one-write Batch (3,000) | 31.1, 18.3, 12.1 µs | 40.8, 14.4, 13.3 µs |
| prepared read (50,000) | 5.40, 5.81, 5.13 µs | 5.26, 5.04, 5.14 µs |
| allocations (claim, batch write, read) | 602, 32, 20 | 610, 33, 21 |

All three are within the spread of their three runs. The cached write warms up across the rounds on both
sides. The allocations are +8 per claim and +1 per write or read: one wrapper value per statement, rows and
transaction.

**Q9. The rest.**
- K16's `TestBatchPanicWithStatementPending`, `TestBatchPanicNothingPendingRecovered`,
  `TestBatchPanicRowsLeftOpen`, `TestBatchGoexitFreesWriter`, `TestBatchPanicNested` and
  `TestMigratePanicReleasesTheFile` all pass on the branch. They use their own plain-based test drivers, not
  the guard.
- `GOOS=linux`: `go vet ./internal/sqlguard/` and `go build ./internal/sqlguard/ ./internal/catalog/` pass.
- Windows: `go vet ./internal/sqlguard/` passes. `gofmt -l` lists only my probe files.
- The coder's six tests pass, 4.5 s.
- Init order is sound: Go initialises the imported `modernc.org/sqlite`, which registers `"sqlite"`, before
  `sqlguard`'s `init`. `"sqlite-guarded"` is registered once. The test drivers use their own names under
  `sync.Once`.
- Temporary folders: each run of `TestGuardEndsOnDriverPanic` leaves 10 `sqlguard-test-*` folders in `%TEMP%`,
  about 57 KB each, so about 0.6 MB a run. There are 40 on this PC now (30 from before my runs); finding 3.
- In `archiver/`:
  - No product code calls `Raw` or `sql.Drivers()`, or asserts modernc's concrete types.
  - The viewer's tests build their own `&sqlite.Driver{}` registrations, which this piece does not touch.
  - `internal/server/stmtcount_test.go` registers a connection hook on the default driver. It still runs
    inside the inner `Open`.
  - `catalog/vfp_test.go` registers a SQL function. A panic in such a callback would now end the process,
    but that is tests only; no product code registers callbacks.
- The code does not contradict the brief's decision.

## Findings

1. **Should fix: a full, unread error output holds the end for good** (`sqlguard.go`, `end`).
   - Probe: `TestZZK19ChildByTheWatchdog/fill-guard` (did not end in 15 s) against `fill-cure` (ended, code 2,
     4.5 s).
   - Smallest fix: in `end`, write the report on a goroutine of its own, then call
     `endProcess(exitCode)` after the write returns or after about 5 s, whichever comes first. The second
     goroutine's `select {}` stays as it is.
   - Say in the comment that a timed-out end leaves no crash text, so a watchdog that recovers later classes
     it "ended". The case only arises when the watchdog has stopped reading.
2. **Minor: the child test classes the output with a copy of the watchdog's rule, not the watchdog's keeper**
   (`child_test.go:67-77`).
   - Probe: `TestZZK19ChildByTheWatchdog/read` shows the real chain gives `crash`.
   - Smallest fix: move that test, or add one, into `internal/watchdog` (package-internal), feeding the child's
     pipe through `copyStream` and `newKeeper` and classing with `keeper.evidence`, as `loop.go` does.
3. **Minor: tests leave 10 folders (about 0.6 MB) in `%TEMP%` per run** (`guard_test.go`, `heldDir`).
   - Seen: 30, then 40 after one run.
   - Smallest fix: at the start of `TestGuardEndsOnDriverPanic`, remove `sqlguard-test-*` folders older than
     an hour. Their processes are gone, so Windows lets them go.
4. **Minor, not this piece's alone: the stack's frames can carry raw argument words.** A spilled integer
   argument (an id) could appear in hex, exactly as in the runtime's own crash text. In my probe both
   arguments showed as `0x0?` (`TestZZK19FrameArgs`).
   - No fix is required for this piece. If wanted, strip each frame line's argument list in `fromPanic`.
     `crashlog.frameOf` only checks it against a pattern.

For information only, the same with or without the guard:
- database/sql itself panics (nil pointer) on `LastInsertId` and `RowsAffected` after an `Exec` of an empty,
  blank or comment-only statement, because modernc returns a nil result with no error.
- modernc panics on a call into a closed connection.

## Not looked at

- What a real mid-statement panic leaves inside SQLite's state: by the decision, nothing goes on after it.
- The other packages' own opens (`viewer`, `pairwords`, `backup`, `bringin`, `tools/probe-misses`): not
  guarded, by the brief.
- Linux behaviour of the end. On Linux a write to a closed pipe on stderr raises SIGPIPE: the process still
  ends, by the signal.
- The whole `internal/catalog` package and the race detector. These are the Core session's full runs.
- A busy timeout under a shared cache (code 6).

may be listed after these fixes: 1
