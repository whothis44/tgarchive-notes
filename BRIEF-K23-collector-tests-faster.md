# Brief K23: the whole `internal/collector` test suite faster (Core, K-6, 2026-11-21)

**Why:** the whole `internal/collector` takes 30 to 35 minutes on this PC (about 2,000 s on 11-21) and the
integrator runs it at every batch. Cut its wall time **without weakening anything a test asserts**. Tests only;
a production timer or default is changed only if you stop and say why first.

**Rules:** you are the one Opus coder of this piece, start to finish. Invented data only; never touch a running
program, the main copy `repo-archiver`, `C:\Users\trabi\tgarchive-app` or `E:\`. Nothing runs against Telegram
(the fake only). **Every go command through the track's lock:**
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go1.sh <folder> go test ...` (prints "go1: exit N";
97 or 98: nothing ran, try again; other Core coders share it). No race detector; no Docker. Commit with
`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `wip/core-tests` to `private`. No stash, no rebase.

**Where:** from `C:\Users\trabi\Claude\Projects\Telegram`:
`git -C repo-archiver worktree add ../wt-core-tests -b wip/core-tests af4ca40e`; work only in `wt-core-tests`.

## Steps
1. **Measure before**, once, the whole package with times: `go test -p 1 -count=1 -json -timeout 60m ./internal/collector/ > before.json`
   (through the lock; about 35 min). From it: the package's wall time, the sum of test times, and the 20 slowest
   tests with their seconds (a small script of yours; keep it in `archiver/docs/progress/`).
2. **For each slow test, find what the time goes to:** real `time.Sleep`, real timers or tickers, polling loops
   with real waits where the collector's or engine's injected clock (or the fake Telegram's) would do; a
   catalogue or fake built anew per test or subtest that could be one shared fixture (built once, copied or
   reset); a test that waits for a deadline to pass rather than for an event; tests that could run with
   `t.Parallel()` (only where they share no package variable, file, port or clock: say why each is safe).
   Read the test's comments first: some real-time bounds are the assertion (e.g. "answers within 250 ms") and
   stay.
3. **Change the tests** (and test helpers, the fake's test-only knobs). If a speed-up needs a seam in
   production code (an injectable clock or interval where none exists), keep it a test-only field with the
   production default unchanged, and list it. Every test still asserts what it asserted; a test you cannot speed
   up without weakening it stays as it is, named in the report.
4. **Measure after**, the same command, `after.json`; and run the whole package a second time to show it is not
   flaky (two clean runs). Say both numbers.

## Hand back
`archiver/docs/progress/core-tests-REPORT.md` (committed) and your last message, short: the head and that it
is pushed; wall time before and after (and the sum of test times); the 20 slowest before, what each spent its
time on and what you did; any production line touched (a seam) and why; tests left slow and why; the two clean
runs. Then stop.
