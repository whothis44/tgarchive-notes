# Brief: the independent review of K19 (a panic raised inside the database driver ends the program at once) (Core, K-5, 2026-11-16)

You are the independent reviewer of this piece: Opus, read-only on the branch, with probes. You did not write
it. The coder's report is a claim, not evidence. This code sits on the path of EVERY statement the program
runs against its catalogue, so the first question is not "does it end the process on a panic" but "does it
change anything at all when nothing panics".

**Rules of the house:** invented data only; nothing of a name, text, path or id in any output or in your
report (numbers and code names only). Never touch a running program, the main copy `repo-archiver`, the
coder's copy `wt-core-guard`, or anything under `E:\`. No push, no commit to any branch, no `git stash`. Start
no program of the project except `go test`, `go build`, `go vet`, `gofmt` (a test may start its own test
binary as a child). **Every go command goes through the track's lock script** (one go command at a time for
the track; it waits for memory itself and sets the environment):
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go1.sh <folder to run in> go test -p 1 -run '<names>' -timeout 15m ./internal/sqlguard/`
(exit 97 or 98: nothing was run; wait and try again). Named tests only in `internal/catalog` (its whole run is
9 minutes and not yours); `internal/sqlguard` whole is fine (seconds). No race detector EXCEPT on
`internal/sqlguard` itself if you judge a question needs it (say so).

**Where:** make a scratch copy yourself, one command, from the project folder:
`git -C repo-archiver worktree add --detach ../wt-core-guard-review-scratch 6d2b9a03`. Probes are test files
named `zz_probe_k19_*_test.go` there, uncommitted. The main head the piece was cut from is 78739d59.

## Read first

1. `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-K19-driver-panic.md` (what was asked, the decision and its
   reason) and `REVIEW-E26-judge-recovers-doors.md`, "Question 1" and finding 1 (what was wrong).
2. On the branch: `archiver/docs/progress/core-guard-REPORT.md`; `archiver/internal/sqlguard` (three source
   files, about 560 lines); `git diff 78739d59 6d2b9a03 -- archiver/internal/catalog`.
3. Go 1.27.3's `database/sql` (`sql.go`, `convert.go`, `ctxutil.go`) and `database/sql/driver` under
   `C:\Users\trabi\Claude\Projects\Telegram\ix-tools\goroot-1.27.3\src\database\sql`, and the inner driver's
   source, `modernc.org/sqlite` at the version in `archiver/go.mod`, in the module cache (`go env GOMODCACHE`
   through the lock script's environment: `source ix-tools/env-archiver.sh` first).

## Questions, in this order

1. **Is every concrete value the inner driver can hand out one the guard accepts?** The guard checks each
   inner value's set of optional interfaces at run time and REFUSES a value with another set (the open, the
   statement, the query then fail with an error). Read the inner driver's source: every concrete type it can
   return as a `driver.Conn`, `driver.Stmt`, `driver.Rows`, `driver.Tx` (and `driver.Result`), on every path:
   a statement that returns no rows run through `QueryContext` (an `INSERT`, a `PRAGMA`, an empty statement,
   several statements in one string, `RETURNING`), an in-memory file, a read-only file, `_txlock` and
   `_pragma` in the DSN, a statement prepared and then run both ways, a `Ping` on a closed connection. Does
   any path return a type whose set differs from the one the guard was written against? Probe each you find,
   through the guard and through the plain driver, on two files. One refused value that the plain driver
   serves is a must-fix.
2. **Does `database/sql` take the same path for a wrapper value as for its inner value?** List every type
   assertion `database/sql` makes on a driver value (`grep -n "(driver\." sql.go convert.go ctxutil.go`) and
   say, for each, that the wrapper and the inner value answer it alike. Then the coder's two tests of this
   (`TestWrapperInterfacesExact`, `TestOptionalListIsFull`): do they prove it, or only for the values one
   open happened to return?
3. **Nothing changes without a panic.** Your own differential probe, wider than the coder's 67 steps: the
   catalogue's own statements are the ones that matter: run, through both driver names on two copies of one
   invented catalogue, a few hundred of the catalogue's real doors (claims, a Batch with cached writes,
   settles, reads with every bind type, a schema migration from an older file, a busy timeout between two
   handles, an error of each `*sqlite.Error` code the catalogue's `errwords.go` and `imported.go` look at),
   and compare results and error values (`errors.As`, the code, the text).
4. **Every way into the driver ends the process.** With your own panicking test driver behind the guard:
   every method the wrapper forwards, not only the review's ten forms (also `Stmt.Close`, `Rows.Close`,
   `Rows.Columns`, each `ColumnType...`, `Ping`, `ResetSession`, `IsValid`, `Rollback`, `Begin`, `Prepare`,
   `NumInput`, the open): the end seam reached once, nothing returned into `database/sql`. Is any call into
   the inner driver NOT under a guard (a method value handed out, a `driver.Result`, a goroutine the inner
   driver starts itself: say which exist and what a panic there does)? Two goroutines panicking in the driver
   at once: one report, one exit.
5. **Can the end hang or come back?** `end` writes the report to the standard error output, then exits. The
   standard error of the collector is a pipe the watchdog reads. **If nobody reads that pipe (the watchdog
   stuck or gone) and it is full, does the write block for good, so that the stall this piece exists to end
   is back?** Decide it with a child process whose error output is a pipe nobody reads, filled first. If it
   can block: the smallest cure (the write on a goroutine of its own, the exit after it or after a few
   seconds, whichever is first). Also: a panic value whose `Error` or `String` method panics or blocks (the
   guard must never call it for a value that is not the runtime's own: show it); `debug.Stack` with a very
   deep stack; the seam in the product cannot be set from outside the package.
6. **What the report holds.** With panic values that carry an invented statement, an invented path and an
   invented number as text, as an error, as a wrapped error, as a `fmt.Stringer`, and as a type of another
   package that implements `runtime.Error`: does any of that text reach the report, by the first line or by
   the stack's lines (the `panic(` frame's arguments, a `[recovered]` line)? Is the first line always one
   line that starts "panic: " at the start of a line, whatever was written to the error output before it
   without a line end?
7. **Classed as a crash, restarted as one.** By the watchdog's and `crashlog`'s exported code: the child's
   real output classed and parsed (the coder's child test: is it honest: does it use the same rule the
   watchdog's loop uses, or a copy of it?). Then by reading `internal/watchdog`: what happens after such an
   end (the delay, three quick deaths in a row, the daily cap); and what the next start of the collector
   meets (the catalogue's write-ahead log, files left "in transfer", the staging folder's lock held by a dead
   process, the status file): is each handled as after any kill, by code you can name?
8. **The cost.** Your own measure, plain against guarded in one process, three rounds each: `ClaimNext` at
   200,000 rows, a cached write in a Batch, a prepared read; and allocations per call for each (the wrapper
   makes a new value per statement, rows and transaction). Say the numbers with their spread.
9. **The rest.** K16's rollback for a panic of the catalogue's own code still works on this branch (its tests
   by name). `GOOS=linux` builds and vets the package. The init order and a second registration. The tests'
   files left in the temporary folder at every run (how many, how large; the smallest way to leave none).
   Anything in `archiver/` that asserts the driver's own concrete types, calls `Raw`, or lists drivers.

## Your report

`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-K19-guard.md` (write it with your file tool), and your last
message the same, short: an answer per question; the findings numbered, each with its severity (must fix,
should fix, minor), the probe that shows it and the smallest fix; what you did not look at; and one last
line, exactly one of: "may be listed", "may be listed after these fixes: <numbers>", "not yet: <why>". Then
stop.
