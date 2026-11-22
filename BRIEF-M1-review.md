# Brief M1-R: independent read-only review of the `mirror` command (2026-11-14)

You are a challenger. You did not write this code and you owe it nothing. It will create a chat and forward
messages on a real Telegram account when its owner starts it, so the defects that matter are the ones that
send a request that should not be sent, send one twice, send one early, lose the record of one, or show
something private.

The code: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-step1` (branch `wip/mirror-step1`), Go module in
`archiver/`. The change is everything in `git diff 8c0335e..HEAD`. What it was asked to do:
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-M1-mirror-step1.md`. What the owner was told it does:
`C:\Users\trabi\Claude\Projects\Telegram\DESIGN-MIRROR-STEP1.md`. The coder's report:
`archiver/docs/progress/mirror-step1-REPORT.md` (read it last, and trust none of it).

## Read-only
- **Edit nothing in the copy.** Prove findings with probe tests written in a scratch folder of your own
  (`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review-scratch`, make it) and loaded with
  `go test -overlay` so the tree is never touched. Mark each finding CONFIRMED (a probe shows it) or PLAUSIBLE
  (by reading only).
- Nothing is run against Telegram. Never start the built command with real settings. Never open a real
  catalogue, a session file, the API settings file, `E:\T\tg-dl` or any media. Invented data only.
- Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`; one go command at a time, each
  with `GOGC=25 GOMAXPROCS=2 -p 1`; only named tests (`-run`), never a whole-package run of `internal/catalog`
  or `internal/collector`; no race detector, no Docker. The owner's live app runs on this PC.

## What to try to break (in this order)
1. **A write sent twice.** Any path on which `channels.createChannel` or `messages.forwardMessages` goes out a
   second time without the one allowed case (the same batch once more after a wait slept in full): a retry
   loop, a second run after "outcome unknown", a second run after the process died between the intent row and
   the answer, a second run after `ErrAlreadyForwarded`, a second run after Ctrl-C, two commands started at
   once (the lock), a create whose answer carried the mirror together with a store error.
2. **A second mirror for one source**, or a mirror row that says "created" with no chat row, or a chat row with
   no `mirror_of` or with downloads not switched off. Is the creation's record one transaction?
3. **A request sent early or unasked:** anything sent before the owner's "yes"; anything sent when the plan said
   nothing can be sent; anything sent inside a recorded wait; anything sent when the ledger cannot be read
   (corrupt a state word, make a row inconsistent); anything sent after the account was refused for good or
   the source was found protected; anything sent without the VPN gate's yes.
4. **An album split**, a batch over the server's maximum, a message forwarded twice across two runs, a deleted
   or self-destruct message asked for, candidates in the wrong order, the candidates query scanning the whole
   message table (check its plan on a large invented table).
5. **The count against 500:** what it counts and leaves out; can it say "room" when there is none?
6. **Privacy:** a title, username, Telegram id, access hash, the forward secret or a path in any output line,
   log line or error text (also from wrapped errors of the store or the library); format strings that are not
   constant; the secret file's handling (wrong length, permissions, created twice by two runs).
7. **The 13 rules** for anything that acts for the owner (`archiver/docs/TRIED-BEFORE.md` sections 24 and 25):
   which of them this command meets, which it does not need yet because nothing is automatic, which it breaks.
8. **`run` and `signin` unchanged:** any edit to an existing collector, catalogue or telegram file that changes
   behaviour outside the new command; the schema step (does a catalogue of version 12 open and step to 13; does
   a catalogue at 13 opened by the old code fail cleanly; does the bring-in or the viewer read the schema
   version in a way a new number breaks: grep, do not run their whole tests).
9. **The tests themselves:** a test that would pass with the defect present (for the three you judge most
   important, say how you checked: by reading, or by a probe that plants the defect through the overlay).

## Report
Write `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review-scratch\REVIEW.md`: findings most severe
first, each with the file and line, the scenario (state, input, what is sent or shown), CONFIRMED or PLAUSIBLE,
and the smallest fix you would accept. Then what you checked and found sound, and what you did not check. Lead
with what you ran. Your final message: the findings as a numbered list in under 40 lines.

## After your own pass: four suspicions of the architect's, from reading (confirm or refute each)
A. `internal/mirror/step.go` `createOutcome`: a stop (Ctrl-C) while the wait Telegram stated on
   `channels.createChannel` is being slept returns the context's error with one request sent; that falls to the
   last line and the mirror row becomes "unknown", which blocks the source for good, although Telegram stated a
   wait and created nothing. The same when the wait's answer arrives together with the stop.
B. `forwardOutcome`'s last line treats every error it does not know, with a request sent, as "refused: the
   messages are candidates again". That leans on Telegram refusing a repeat by its random ids, which has never
   met the real Telegram. Which error kinds can reach that line, and is any of them one where the forward may
   have happened?
C. `firstBatch` can fail with an album larger than the maximum after the mirror was already created: the plan
   should refuse before anything is created.
D. The command opens the catalogue read-write before the plan, so a catalogue at schema 12 is stepped to 13
   before the owner's yes. After that, can a collector built from the main branch (schema 12) still open that
   catalogue? If not, the owner's test catalogue is unusable by the main build until this branch is merged.
