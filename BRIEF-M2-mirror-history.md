# Brief M2: a chat's history into its mirror, batch after batch (2026-11-15)

Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-history` (branch `wip/mirror-history`, cut from
`wip/mirror-step1` 85bd550). Work only there, in `archiver/`. Commit-ready work; do not push, merge or touch
another copy. **Nothing is run against Telegram**: the fakes only.

Read first: `BRIEF-M1-mirror-step1.md` (its "Rules" section holds here word for word), `DESIGN-MIRROR-STEP1.md`,
the code this builds on (`internal/mirror/mirror.go`, `step.go`, `internal/collector/mirror_cmd.go`,
`internal/catalog/schema13.go`), the review of that code (`wt-mirror-review-scratch/REVIEW.md`) and its fix
round (the end of `archiver/docs/progress/mirror-step1-REPORT.md`): the same classes of defect must not come
back in the loop you add.

## What is already known (the architect read the history; you do not need to)
- The owner (FEATURES.md section 12, rounds 4 and 6): the mirror forwards a chat's history too, as the owner
  did by hand with a third-party client: 100 at a time, "reasonably fast", without trouble; "add a smart sort
  of delay". The rule agreed there: whole batches up to the server's maximum, an album never split, one chat at
  a time, **a pause between batches**, every batch counted, any wait slept in full and reported, history oldest
  first, the cost shown before a chat's history starts ("about N batches"), the count against the 500 shown.
  **No setting shortens a wait.** The pause "starts from the owner's own experience, is lengthened after any
  wait, and never shortens a wait Telegram states".
- **Nobody has a number for forwards per hour.** The old app never forwarded (it uploads files again). The
  first real batch (M1) has not run yet. So the pause's start is a default the owner can change, and this
  piece measures: it must print what it achieved.
- From the old app's lessons (TRIED-BEFORE.md 24, 25): Telegram's waits are stored and checked at the top of
  every step; one costly failure ends the step; one item per call, each success recorded; a cap per step.

## What to build
The same command, `tgarchive-collector mirror`, gains a loop. Nothing else changes: with no new flag it does
exactly what it does today (one batch).

1. **`-batches N`** (default 1; 1 to 1000) and **`-batches all`**: how many batches this run may forward. The
   plan shows the cost before the yes: candidates, "about B batches" (cut at the plan's maximum), the pause in
   use, "about M minutes" (B times the pause plus a fixed allowance per request said as such), and the requests
   it will send at most. One yes covers the run.
2. **The pause between batches** (`internal/mirror`, on the injected clock, measured from one forward's answer
   to the next forward's request):
   - `-pause D`: default 10 s; 2 s to 10 m. It is the START of the pause, not a bound on anything of Telegram's.
   - **After any wait Telegram states on a forward in this run, the pause doubles** (at most 10 minutes), and
     the lengthened pause is **stored for the account** (a catalogue setting; no schema step) so that the next
     run starts from it, not from the flag: the plan says "the pause in use: X s (lengthened after a wait on
     <date>)". Only a flag given explicitly AND larger than the stored one replaces it; a stored pause is
     never shortened by a flag (the owner resets it with a flag of its own, `-pause-reset`, which says what it
     does). A stored value that cannot be read: nothing is sent (fail closed).
   - A wait Telegram states is slept in full by the forwarder as today; the pause comes after it, on top.
3. **The loop** (`internal/mirror`): after `help.getConfig` and the mirror's creation (once, as today), batch
   after batch: candidates read again from the ledger each time (never a list kept from the start), the intent
   rows before each forward, the result recorded, then the pause. **It ends at the first of:** the number of
   batches reached; no candidates left; a stop (Ctrl-C: between batches it ends cleanly at once, also during
   the pause; during a request as today); a batch that ends unknown, already, refused, protected, account
   refused, a long wait, a ledger failure; **the second wait in the run on which a batch could not be sent**
   (today's rule per batch stays: the same batch once more after a wait slept in full; if that is answered
   with a wait again, the run ends). A run that ends early says how many batches were done and why it ended.
4. **Never more than one request in flight**, and never a create or forward repeated except today's one
   resend. No goroutine in `internal/mirror`.
5. **The numbers at the end** (fixed words and numbers): batches sent and done; messages forwarded and left
   out; per method the counts as today; every wait with its stated seconds; the time of each request (for a
   long run: the first 20 lines, then smallest, median and largest of the rest); the pauses slept; the run's
   wall time; **forwards per hour achieved in this run** (messages forwarded over wall time, said as "this
   run's rate, not a limit"); messages still to forward; the count against 500. The step's counts go to the
   hourly tables as today.
6. **A progress line** after each batch (one line: batch k of n, forwarded, left out, ms, next pause), so a
   long run can be watched in the owner's window and its log.
7. The fake Telegram: a switch to answer the k-th forward with a wait, and to count forwards per call, if the
   existing switches do not allow it.

## Tests (named, invented data, the fake clock: no real sleeping)
In `internal/mirror` and `internal/collector` (new files or added to the mirror tests):
1. `-batches 3` on a chat of 450 candidates: exactly 3 forwards, 2 pauses of the start length slept on the
   fake clock, the ledger's rows, 150 candidates left; a second run goes on from there.
2. `-batches all`: runs to no candidates; the last batch is partial; no forward after it.
3. A wait on the 2nd forward: slept in full, that batch sent once more, the pause doubled from then on and
   stored; a new run's plan shows the stored pause and uses it; a smaller `-pause` does not shorten it;
   `-pause-reset` does and says so.
4. A wait twice on the same batch: the run ends there; nothing after it is sent.
5. No answer on the 2nd forward: recorded unknown, the run ends, a later run sends nothing for that mirror.
6. A stop during the pause: ends at once, cleanly; the next run forwards the next batch; nothing is unknown.
7. A stop during the 2nd forward's request: as M1's rules (unknown unless a wait was counted).
8. An album straddling a batch boundary in the middle of a run is never split.
9. Default flags: byte-for-byte the behaviour and output of today's command (the existing Mirror tests pass
   unchanged, except where a line gained a field: list each such change).
10. The stored pause unreadable: nothing sent.
11. Privacy: the marker-word test of M1 extended to the progress lines and the end numbers.
For tests 3, 4, 5 and 6 say in the report how you saw each fail with its rule removed (through
`go test -overlay` from a scratch folder of your own, the working copy not edited for it).

Run only: `go test ./internal/mirror -count=1`, `go test ./internal/collector -run 'Mirror' -count=1`,
`go test ./internal/collector/faketg -count=1`, `go test ./cmd/tgarchive-collector -count=1`,
`go test ./internal/catalog -run 'Schema13|Mirror' -count=1` if you touched the catalogue; `gofmt -l` and
`go vet` on what you touched. No whole-package run of `internal/catalog` or `internal/collector`, no race
detector, no Docker. One go command at a time, each with `GOGC=25 GOMAXPROCS=2 -p 1`.

## Rules
As `BRIEF-M1-mirror-step1.md`: work only in your copy; invented data; constant format strings; no title,
username, Telegram id or access hash in any line; `internal/telegram/forward.go` and `call.go` unchanged; no
new dependency; the forbidden packages untouched; no schema step (if you find you need one, stop and say so).
Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no archive numbers. Report:
`archiver/docs/progress/mirror-history-REPORT.md` in the commit (what was built, each test with its time, how
tests 3 to 6 were seen to fail, **whether any concurrent code was added or changed**, departures, doubts, what
is not verified). Final message to the architect: the commit hash, tests as counts and seconds, concurrent
code, departures, doubts, under 30 lines.
