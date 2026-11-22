# Brief K19: a panic raised inside the database driver ends the program at once; it never stalls it (Core, K-5, 2026-11-16)

**Rules of the house (the project folder's `CLAUDE.md`, the archiver section):** you are the Opus coder of this
piece and hand back commit-ready work. Named tests only while you work (`-run`, one package at a time; the whole
`internal/catalog` takes 9 minutes and is not yours to run); no race detector; no `go vet` over many packages.
Invented data only; nothing of a name, text, path or id in any log line, error or commit message. Never touch a
running program, the main copy `repo-archiver` or anything under `E:\`. **Every `go`, `gofmt` or `vet` command
goes through the track's lock script** (one go command at a time for the whole track: a reviewer of another
piece works beside you; the script waits for memory itself and sets the environment, `GOGC=25 GOMAXPROCS=2`):
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go1.sh <folder to run in> go test -p 1 -run '<names>' -timeout 15m ./internal/sqlguard/`
(it prints "go1: exit N"; exit 97 or 98 means nothing was run: wait and try again, and say so in the report).

**Where:** make the copy yourself, one command, from the project folder: `git -C repo-archiver worktree add
../wt-core-guard -b wip/core-guard 78739d59` (the main head on `private` at 18:38; a merge run is staged in
the main copy: the command writes nothing in its files). Work only in `C:\Users\trabi\Claude\Projects\Telegram\wt-core-guard`. Commit with `git -c user.name=Claude
-c user.email=noreply@anthropic.com commit`, the message ending `Co-Authored-By: Claude Opus 5.5
<noreply@anthropic.com>`; push only `wip/core-guard` to `private`, work in progress too. No `git stash`, no
rebase.

## What the old app already knows

The old app uses the same SQLite driver (`modernc.org/sqlite`, C code translated to Go) through `database/sql`
and has no guard of this kind; its record has no Go panic inside the driver. What it does have, and what this
piece copies in spirit: a fault it cannot handle ends the process, the crash text is kept
(`core-service/internal/crashlog`), and a watchdog starts it again; nothing in it tries to go on with a database
library in an unknown state. On this PC the new app has met one hard fault inside the driver's Windows calls
(`FINDING-CORE-crash-28.md`: it ended the process, which is the safe outcome). SQLite's file is safe against
the process ending at any instant (the write-ahead log); it is not safe against a process that goes on using a
library whose own locks and caches were left half-way by a panic.

## What is wrong (shown by the copies track's reviewer with probes; board message 151)

Read first, in full: `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-E26-judge-recovers-doors.md`, "Question 1"
(the table of what `database/sql` holds during a driver call and whether a panic gives it back, with the line
numbers of Go 1.27.3's `sql.go`) and finding 1. The probes are `zz_probe_*` files in
`wt-copies-review26-scratch\archiver\internal\catalog` (`TestZZProbeE26Batch`, `TestZZProbeE26Outside`): read
them, take their test driver's idea over for your tests, edit nothing there.

In short: `database/sql` gives a connection back after a driver's panic only on the plain exec path. A driver's
panic in a cached write or in any read inside `Catalog.Batch` makes `Batch`'s deferred rollback (K16) wait for
good: the goroutine hangs holding the one writer, no panic comes up, no supervisor is reached, every write of
the program waits and the program does not end. A panic in `Commit` or in a cached write outside a transaction
keeps the writer; each panic in a read keeps one of the 8 reader connections. And the watchdog does nothing
about a hang (`internal/watchdog/status.go`: stale beats are counted, "nothing is done"), nor would a stalled
writer make the status file stale.

## The decision (the Core session's, with its reason; say in your report if the code contradicts it)

The reviewer proposed a wrapper that recovers the driver's panic, marks the connection broken and answers an
ordinary error. **Not taken.** After a Go panic inside the translated C code, SQLite's own state in this process
(its mutexes, the per-file objects every connection of the process shares, the allocator) cannot be trusted:
another connection may wait on a lock the panic left held, and closing the "broken" connection calls into the
same library. Going on risks a silent stall of another kind, or a wrong write to the catalogue. **So: a panic
that crosses the driver's boundary ends the program at once, as an unrecovered panic ends it: its text kept
by the watchdog as a crash, the process restarted by the watchdog's own policy.** The start then recovers as
after any kill.

## What to build

1. **A small package of its own, `archiver/internal/sqlguard`** (no import of any other package of ours, so
   that every track can use it): it registers ONE `database/sql` driver under an exported name
   (`sqlguard.DriverName`) that wraps `modernc.org/sqlite`'s driver. Every call that enters the inner driver
   (the driver's open, and every method of its connection, statement, transaction and rows that database/sql
   can call) runs under one deferred function that, when a panic is on its way up, ends the process and never
   returns to database/sql.
2. **The wrapper must not change how any statement runs.** `database/sql` picks its path by the optional
   interfaces a driver's values implement (`driver.DriverContext`, `Pinger`, `SessionResetter`, `Validator`,
   `ExecerContext`, `QueryerContext`, `ConnPrepareContext`, `ConnBeginTx`, `NamedValueChecker`,
   `StmtExecContext`, `StmtQueryContext`, `ColumnConverter`, the `RowsColumnType...` family,
   `RowsNextResultSet`, and any other in `database/sql/driver` of Go 1.27.3: go through the package's list,
   do not trust mine). Each wrapper value must implement EXACTLY the optional interfaces its inner value
   implements, no more and no fewer, and forward each unchanged (the same arguments, the same results, the
   inner driver's own error values untouched: the catalogue's `errors.As` on `*sqlite.Error` in `errwords.go`
   and `imported.go` must keep working). A test proves "exactly" by reflection over the full list, for the
   driver, a connection, a statement, a transaction and rows obtained from a real open.
3. **How the process ends:** one function of the package, called from the deferred recover. It writes to the
   standard error output a report the watchdog and `internal/crashlog`'s parse take as a crash (read both
   first: what the watchdog keeps of a child's error output, how it classes an end as `HowCrash`, which exit
   code an unrecovered Go panic gives; then produce the same class: say in the report which lines of theirs
   decide it): a first line in fixed words that names this guard, the panic value's Go TYPE, the value's text
   ONLY when it is a `runtime.Error` (fixed words and numbers), never the text of any other value (it may
   hold a statement or a path), then the goroutine's stack (`debug.Stack()`); then the process exits with
   that code. No other goroutine is waited for. A second panic while it reports must not hang it (a plain
   exit in any case).
   A seam for tests only: the "end the process" step is a package variable a test replaces; in the product
   it cannot be set from outside the package's tests (unexported).
4. **The catalogue uses it:** `internal/catalog/catalog.go`'s two opens and `checkpoint.go`'s one name
   `sqlguard.DriverName` instead of `"sqlite"`; nothing else in the catalogue changes: not `Batch`, not K16's
   rollback (it stays for a panic of the catalogue's own code), not the DSNs. Other packages' own opens
   (`internal/viewer`, `internal/pairwords`, `internal/backup`, `internal/bringin`, `tools/probe-misses`) are
   other tracks': do NOT change them; list them in the report with file and line.
5. **Measure, before and after, on the same PC state, each three times:** the claim path at size (the
   catalogue's existing at-size or benchmark tests for `ClaimNext`: find them and say which), one cached write
   in a `Batch`, one prepared read. Report the numbers side by side. If any is slower by more than the spread
   of the three runs, stop and say so.

## Tests (each seen FAILING or hanging without the guard first, by its own timer; say so per test)

1. With a test driver that panics on demand in each form of the review's table (cached write in a `Batch`,
   read in a `Batch`, uncached write, `Commit`, `Commit` with a statement pending, plain read, prepared read,
   prepared write outside a transaction, `Rows.Next`, the open itself): through the guard, the "end" seam is
   reached exactly once, within a second, with the report's first line and type as specified, and with NO
   text of the panic's value when it is not a `runtime.Error` (a value holding an invented statement and an
   invented path: neither appears in the report).
2. One test with a REAL child process (the test binary started again with an environment mark, as Go's own
   tests do): a panic inside the wrapped driver ends the child with the crash's exit code, its error output
   parses with `crashlog`'s parser as a crash.
3. The reflection test of point 2.
4. No panic, nothing changes: a table of statements through the guard and through the plain driver on two
   files gives equal results (named and positional parameters, a NULL, a blob, an integer above 2^53, a
   read-only open that refuses a write with the same error value, a busy timeout that answers the same
   `*sqlite.Error` code).
5. The catalogue's own tests that open, migrate, claim and batch, by name (`TestOpen|TestMigrat|TestSchema|
   TestBatch|TestClaim|TestCheckpoint` and what else names the open: list what you ran) still pass.

`gofmt -l`, `go build ./...`, `go vet ./internal/sqlguard ./internal/catalog`.

## Hand back

`archiver/docs/progress/core-guard-REPORT.md` (committed) and your last message, the same content, short: the
head and that it is pushed; the list of optional interfaces you found for each of the five inner values and
that the wrapper matches; how the end is classed as a crash (their lines); the timings side by side; the other
packages' opens (file, line); the tests as run; what you could not test; anything in this brief the code
contradicts. Then stop: the review and the full runs are the Core session's.
