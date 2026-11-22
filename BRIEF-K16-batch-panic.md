# Brief K16: a panic inside `Catalog.Batch` must not leave the one writer held (Core, K-4, 2026-11-16)

**Rules of the house (the project folder's `CLAUDE.md`, the archiver section):** you are the Opus coder of this
piece and hand back commit-ready work. Named tests only while you work (`-run`, this one package; the whole
`internal/catalog` takes 8 minutes and is not yours to run); no race detector; no `go vet` over many packages.
Invented data only; nothing of a name, text or path in any log line or error. Never touch a running program
or anything under `E:\`. Before every `go` command: `source
/c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, prefix `GOGC=25 GOMAXPROCS=2` (`-p 1`), and
read free memory first (`powershell -NoProfile -Command "[int]((Get-CimInstance
Win32_OperatingSystem).FreePhysicalMemory/1024)"`; under 3000: wait 2 minutes and measure again); another
coder works on this PC: one go command at a time.

**Where:** the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-core-batch`, branch `wip/core-batch`, cut from
the main head f7d6ca63. Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the
message ending `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only that branch to `private`.
No `git stash`.

## What is wrong (found twice by two independent reviewers of the copies track, each with a probe)

`internal/catalog/catalog.go`, `Catalog.Batch`: the catalogue has ONE writing connection. `Batch` begins a
transaction on it, runs the caller's function, and rolls back only when that function RETURNS an error. When
the function panics:
- the transaction is never rolled back, so the one connection stays inside an open transaction;
- `Batch`'s own deferred `c.wstmts.preparePending(ctx, c.wdb)` then asks that same connection to prepare
  statements and blocks for good where a statement is pending: the goroutine never reaches any recover;
- where nothing is pending, the panic goes up, and whoever recovers it (the collector's supervisor recovers
  every task and restarts it) goes on with a writer that every later claim, finish and ledger write waits on
  until the context ends. Nothing crashes, nothing moves.

The two reports and probes (read-only for you; take the probes over as tests):
`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-E19-owner-verdicts.md` finding 5 with
`wt-copies-review19-scratch\archiver\internal\catalog\zz_probe_e19_test.go` (`TestProbeBatchPanic`: it hangs
by design, run it only with `-timeout`), and `REVIEW-E18b-second-look.md` finding 1 with
`wt-copies-review18b-scratch\archiver\internal\catalog\zz_probe_e18b_test.go`. If a file is not where I say,
find it by name under the project folder and say where it was.

## What to build

**For:** a panic in any catalogue write must leave the writer free at once, and still be a panic for whoever
is above (the supervisor counts and restarts on it; hiding it would hide a defect).

- In `Batch`: when the function does not return normally, the transaction is rolled back BEFORE anything
  that needs the connection again (`preparePending`), and then the panic goes on unchanged (the same value;
  do not wrap it, do not log its text). Order the defers so; say the order in a comment.
- The nested case (`c.tx` true: `Batch` inside a `Batch` just calls the function): the outer `Batch` does it.
- Look at every other place in `internal/catalog` that begins a transaction on the writer or holds the
  writing connection across a caller's function (`BeginTx`, `Conn`, the settle's chunks, the schema steps,
  `Import`-style loops, anything with `wtx`): the same hole there? Fix each the same way, or say why it
  cannot panic with the connection held. List them all in the report with file and function.
- Rows left open by a read on the writer inside the function when it panics: the rollback ends them; show
  it in a test if you can make the case, else say so.
- Nothing else changes: no behaviour on a returned error, on success, in the hooks after a commit, in
  `Settle`.

## Tests (each seen FAILING or hanging before the fix; a test that would hang runs under a context or a
timer of its own so that it fails instead)

1. A panic in the function with a statement pending: `Batch` panics up with the same value within a
   second (today: blocks for good), and a second `Batch` right after it commits.
2. A panic with nothing pending, recovered by the caller: the next `Batch` on the same catalogue commits at
   once (today: waits until the context ends), and nothing of the panicked function's writes is there.
3. A panic inside a nested `Batch`.
4. For each other place you fixed: its own test.
5. The existing tests of `Batch`, the settle and the schema steps by name still pass.

`gofmt -l`, `go build ./...`, `go vet ./internal/catalog`. Hand back in
`archiver/docs/progress/core-batch-REPORT.md` (committed) and as your last message: the head, pushed or not;
what changed (file, function, the defer order); every other place you looked at and what you found; the
tests and results as run; what you could not test.
