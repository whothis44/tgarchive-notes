# Brief K19b: the fix round after K19's independent review (Core, K-5, 2026-11-16)

**Rules of the house:** you are an Opus coder and hand back commit-ready work. Named tests only in
`internal/catalog` and `internal/watchdog` (`-run`); `internal/sqlguard` whole is fine (seconds). No race
detector. Invented data only; nothing of a name, text, path or id in any log line, error or commit message.
Never touch a running program, the main copy `repo-archiver` or anything under `E:\`. **Every `go`, `gofmt` or
`vet` command goes through the track's lock script:**
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go1.sh <folder to run in> go test -p 1 -run '<names>' -timeout 15m ./internal/sqlguard/`
(it prints "go1: exit N"; 97 or 98: nothing was run, wait and try again).

**Where:** the existing copy `C:\Users\trabi\Claude\Projects\Telegram\wt-core-guard`, branch `wip/core-guard`,
head 6d2b9a03 (clean, pushed). New commits on top; commit with `git -c user.name=Claude -c
user.email=noreply@anthropic.com commit`, the message ending `Co-Authored-By: Claude Opus 5.5
<noreply@anthropic.com>`; push only that branch to `private`. No `git stash`, no rebase, no amend.

## Read first

1. `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-K19-guard.md`, in full (answers 4, 5, 6, 7 and the four
   findings).
2. `BRIEF-K19-driver-panic.md` (what the piece is for) and, on the branch, `archiver/internal/sqlguard`
   (`sqlguard.go` above all: `guard`, `end`, `report`, `fromPanic`) and `archiver/docs/progress/core-guard-REPORT.md`.
3. The reviewer's probes (read-only; take them over where this brief says so):
   `wt-core-guard-review-scratch\archiver\internal\sqlguard\zz_probe_k19_*_test.go` and the one in
   `internal\watchdog`.

## The decisions (the Core session's, on every finding)

1. **Finding 1, to be fixed (for this piece it is a must: it exists to end a stall, and the reviewer showed
   its own end can stall): `end` must not wait for good on an error output that is full and unread.** The
   report is written on a goroutine of its own; `endProcess(exitCode)` is called when that write has returned
   or after a bound, whichever is first. The bound: 5 seconds, a package constant (unexported; a test may
   shorten it through the package's own seam). The rest of `end` stays: one goroutine ends the process, a
   second one that comes there waits for it; a panic while reporting does not stop the end; nothing returns
   into `database/sql`. Tests: the reviewer's `TestZZK19ChildByTheWatchdog` shape taken over (a real child
   whose error output is a pipe nobody reads, filled first: exit code 2 within the bound plus a margin; seen
   hanging without the fix by its own timer); and with the seam: a writer that blocks for good, the end
   reached once after the bound; a writer that returns at once, the end reached without waiting for the
   bound.
2. **Finding 4, taken: the report's stack carries no argument words.** In `fromPanic` (or beside it) every
   frame's argument list becomes `(...)` as the runtime itself prints an elided list: the function names and
   the file and line stay. Show by a test that `internal/crashlog`'s parse still names the cause and the
   functions on such a report (the child test does: extend it), and that an invented number passed as an
   argument down the panicking stack (the reviewer's Q6 shows how) appears nowhere in the report.
3. **Finding 2: the child's output is classed by the watchdog's own code.** A package-internal test in
   `internal/watchdog` (Core's package) that feeds the guard's real report through `copyStream`, `newKeeper`
   and `evidence` and classes the end (take the reviewer's watchdog probe over, renamed without `zz`). The
   copy of the prefix rule in `sqlguard`'s `child_test.go` may stay as a second check or go: say which.
   `internal/watchdog` must not import `internal/sqlguard` in product code (a test file may, if the wall
   test of the package allows it: check `wall_test.go` first; if it does not, the test builds the report's
   text by starting the `sqlguard` test binary as a child, or lives in `sqlguard`: say what you did).
4. **Finding 3: the tests leave nothing behind.** `TestGuardEndsOnDriverPanic`'s folders: removed at the
   test's end where Windows allows, and at the test's start every `sqlguard-test-*` folder older than an
   hour in the temporary folder is removed (best effort, no failure for it).

Nothing else changes: not the wrapper's forwarding, not the interface sets, not the catalogue's opens.

## Checks

`internal/sqlguard` whole; the new `internal/watchdog` test by name with `TestClassify` and the package's wall
test; the catalogue's named set of the first round once (`TestOpen|TestMigrat|TestSchema|TestBatch|TestClaim|
TestCheckpoint`); `gofmt -l`; `go build ./...`; `go vet ./internal/sqlguard ./internal/watchdog ./internal/catalog`;
`GOOS=linux go vet ./internal/sqlguard` (through the lock script: `env GOOS=linux go vet ...`).

## Hand back

The report file brought up to date and committed, the branch pushed, and your last message, short: the head;
per decision what was done; test functions added, by name; the bound and how long the blocked-output child
took to end; anything that is not as this brief says. Then stop: the full runs are the Core session's.
