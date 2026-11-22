# Brief M2-R: independent read-only review of the mirror command's run of several batches (2026-11-15)

You are a challenger. You did not write this code. It forwards messages on a real Telegram account, batch
after batch, possibly for hours unattended, when its owner starts it. Nobody knows how many forwards an hour
Telegram allows, so the defects that matter are: a forward sent twice; a forward sent inside a wait Telegram
stated or without the pause; a run that goes on after it should have ended; the record of a forward lost; a
pause that gets shorter; something private shown.

The code: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-history` (branch `wip/mirror-history`), Go module
in `archiver/`. The change under review is `git diff 85bd550..HEAD` (one commit, fd0cb2a). What it was asked to
do: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-M2-mirror-history.md`. The code it builds on was reviewed
before (`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review-scratch\REVIEW.md`, fixed in 85bd550): do not
review that again, but check that none of its fixes was undone by the new loop (`Step` was folded into `Run`).
The coder's report (`archiver/docs/progress/mirror-history-REPORT.md`): read it last, trust none of it.

## Read-only (the same rules as the first review)
- Edit nothing in the copy. Probes live in a scratch folder of your own
  (`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review2-scratch`, make it), loaded with `go test -overlay`.
  Mark each finding CONFIRMED (a probe shows it) or PLAUSIBLE (reading only).
- Nothing against Telegram; never the built command with real settings; never a real catalogue, a session
  file, the API settings file, `E:\T\tg-dl` or media. Invented data only.
- Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`; one go command at a time, each
  with `GOGC=25 GOMAXPROCS=2 -p 1`; only named tests; never a whole-package run of `internal/catalog` or
  `internal/collector`; no race detector, no Docker.

## What to try to break, in this order
1. **A forward sent twice or a batch overlapping another:** across batches of one run; across two runs; after
   a stop at each point of the loop (before the intent row, during the request, between the answer and the
   record, during the pause, during the resend's pause); when a batch ends done with some messages left out by
   Telegram; when candidates change between the two reads around the pause.
2. **A run that goes on when it must end:** after an unknown outcome, `RANDOM_ID_DUPLICATE`, a refusal, a
   protected source, the account refused, a long wait, a ledger failure, the second wait of the run, the
   number of batches, no candidates. Count the forwards the fake saw in each case.
3. **The pause:** is there any path with two forwards and less than the pause between the first's answer and
   the second's request (the resend after a wait in a run of one batch goes at once by design: say whether
   that is sound given the forwarder slept the wait in full)? Can the stored pause get shorter by any flag,
   order of runs, clock change, or parse of a strange stored value? Is a wait on `help.getConfig` or on the
   create treated as a forward's wait (it must not double the pause) and the reverse? What happens to the
   pause when the store write fails, and is anything sent after that?
4. **Waits:** a wait stated on a forward is slept in full by the forwarder before the loop's pause starts; the
   run never sends inside a recorded wait, also in the next run started at once.
5. **Default flags behave as before:** with no new flag, is any request, record or output line different from
   85bd550 (the coder says one line is added after a wait)?
6. **The numbers:** "forwards per hour achieved" (what it divides by what; can it mislead, for example over a
   run that mostly slept a wait); the plan's "about N batches, about M minutes"; counts after an early end.
7. **Privacy:** every new output line, progress line and error path: a title, username, Telegram id, access
   hash, secret or path anywhere; format strings not constant.
8. **The tests:** for the three rules you judge most important, plant the defect through the overlay and say
   whether a test fails.

## One question of the architect's, after your own pass
At the default pause of 10 s, `-batches all` forwards up to 36,000 messages an hour for as long as the chat
lasts, on a number nobody has measured. By reading only: is there anything in the code that would let the
owner bound a run by messages per hour or by wall time, and what is the smallest such bound you would add?

## Report
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review2-scratch\REVIEW.md`, written as you go: findings most
severe first, each with file and line, the scenario, CONFIRMED or PLAUSIBLE, the smallest fix you would accept;
then what you found sound; then what you did not check. Lead with what you ran. Final message: the findings as
a numbered list, the answer to the architect's question, what you did not check; under 40 lines.
