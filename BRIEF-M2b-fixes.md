# Brief M2b: the fix round of the mirror command's run of several batches (2026-11-15)

Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-history` (branch `wip/mirror-history`, at fd0cb2a). Work
only there, in `archiver/`. One commit on top; do not push, merge or touch another copy. Nothing is run against
Telegram. The rules of `BRIEF-M2-mirror-history.md` and of `BRIEF-M1-mirror-step1.md` ("Rules") hold: invented
data, the fake clock, named tests only, one go command at a time with `GOGC=25 GOMAXPROCS=2 -p 1`, no
whole-package run of `internal/catalog` or `internal/collector`, no race detector, no Docker, `forward.go` and
`call.go` unchanged, no goroutine in `internal/mirror`.

Read the review whole first: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review2-scratch\REVIEW.md` (its
probe tests P1 to P6 are in that folder and may be the start of your tests). The numbers below are its finding
numbers. The architect judged each: all are to be fixed. Each fix gets a named test that fails without it; say
in the report how you saw it fail (a copy with the fix undone, through `go test -overlay`, the working copy
not edited for it).

## Fixes
1. **The pause holds across runs** (finding 1, confirmed). A run's first forward must not go out sooner than
   the pause in use after the account's last forward answer, whichever run or mirror it was in. Read that time
   from the ledger (the newest batch's end time for the account, over all its mirrors; if the ledger's time is
   in whole seconds, round the wait up). The plan shows it ("the last forward was answered N s ago: the first
   forward waits M s more"), and `Run` sleeps what is left before the first intent row (a stop during it ends
   cleanly: nothing in flight). This holds for the default one-batch run too. An end time in the future (a
   clock that went back) is treated as "just now": the full pause is slept, never less.
2. **A bound on messages per hour, read from the ledger** (the architect's question; the review's better
   option). Before each intent row: the messages of the account's forward requests sent in the last 60 minutes
   (every batch row whose request went out, whatever its end; over all its mirrors) plus this batch must not
   exceed the bound; if they would, the run ends there with fixed words that say when room returns (the local
   time at which enough of the hour's batches are older than 60 minutes). It does not sleep until then.
   `-per-hour N`: default 10,000 messages; 100 to 100,000. The plan shows the bound, what the last hour holds,
   and says in fixed words that it is the app's own caution and not a limit of Telegram's (nobody has a number
   for forwards per hour). The plan's "about N batches, about M minutes" accounts for it ("this run can send at
   most K batches before the bound"). It applies to the default one-batch run too. A ledger that cannot be read
   for it: nothing is sent.
3. **The stored-pause write failing after a wait has a test** (finding 2): the review's P4 as a test, in a run
   of several batches and in the default run: nothing more is sent.
4. **"Messages still to forward" is right after an early end** (finding 3): the mirror's id is known before any
   return that reports it.
5. **A long run's counts go to their own hours** (finding 4): the hourly counts are written at each turn of the
   hour during a run (from the progress callback, on the command's side, with the function used at the end
   today), not once at the end. If the existing writer cannot be called twice in a run without counting twice,
   say so in the report and leave it, with the reason.
6. **The rate line cannot mislead** (finding 5): print "this run's rate" as messages per hour only when the run
   lasted 10 minutes or more; always print beside it the wall time, the time slept in Telegram's waits and the
   time slept in pauses, so the reader can see what the figure covers.
7. **A stored pause is checked before it is multiplied** (finding 6): a value out of bounds, or one that would
   overflow, is unreadable (fail closed), never a short pause.
8. **The repeat guard has a test** (finding 7): a ledger that hands back a message of a batch done in this run:
   nothing more is sent.
9. **The refusal for an unreadable stored pause names `-pause-reset`** (finding 8), and the report lists plainly
   the three ways the default run differs from 85bd550 (a setting written after a wait; no resend when that
   write fails; an unreadable stored pause refuses), so the merge-queue entry can say them.

## Tests to run
`go test ./internal/mirror -count=1`; `go test ./internal/collector -run 'Mirror' -count=1`;
`go test ./internal/collector/faketg -count=1`; `go test ./cmd/tgarchive-collector -count=1`;
`go test ./internal/catalog -run 'Schema13|Mirror' -count=1` (fixes 1 and 2 add catalogue reads: they must use
an index; show the query plan in a test on invented batch rows); `gofmt -l` and `go vet` on what you touched.

## Report
Append a section "Fix round" to `archiver/docs/progress/mirror-history-REPORT.md` in the commit: each fix with
its file and test and how the test was seen to fail first; whether any concurrent code was added or changed;
departures; doubts. Commit as before (the message ends `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`,
no archive numbers). Final message to the architect: the commit hash, tests as counts and seconds, concurrent
code, departures, doubts, under 30 lines.
