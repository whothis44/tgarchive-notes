# Brief M3-R: independent read-only review of "the mirror reads the chat itself" (2026-11-15)

You are a challenger. You did not write this code. The `mirror` command now reads a chat's whole history from
Telegram itself and then forwards its media into a mirror chat, when its owner starts it. The defects that
matter here, in order: a file queued for download from a chat the owner did not choose; a request sent before
the owner's yes it belongs to; a chat forwarded from a partial read (so not "oldest first", or a hole);
messages forwarded that should not be (no media, when media only; deleted; self-destructing); a forward sent
twice or too soon (the earlier rules); something private shown.

The code: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-reads` (branch `wip/mirror-reads`), Go module in
`archiver/`. The change under review is `git diff 9f09e86..HEAD` (one commit, e5eef11). What it was asked to do:
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-M3-mirror-reads.md`, plus one change sent to the coder mid-way:
whether a chat read for a mirror is also downloaded is a parameter (`Options.Download`, the command's
`-download`, default off through one constant). The code underneath was reviewed twice
(`wt-mirror-review-scratch/REVIEW.md`, `wt-mirror-review2-scratch/REVIEW.md`): do not review it again, but check
none of those fixes was undone. The coder's report (`archiver/docs/progress/mirror-reads-REPORT.md`): read it
last, trust none of it.

## Read-only (the same rules as before)
- Edit nothing in the copy. Probes in a scratch folder of your own
  (`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review3-scratch`, make it), loaded with `go test -overlay`.
  Each finding CONFIRMED (a probe shows it) or PLAUSIBLE (reading only). Write findings into the report as you
  confirm them.
- Nothing against Telegram; never the built command with real settings; never a real catalogue, a session
  file, the API settings file, `E:\T\tg-dl` or media. Invented data only.
- Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`; one go command at a time, each
  with `GOGC=25 GOMAXPROCS=2 -p 1`; only named tests; never a whole-package run of `internal/catalog` or
  `internal/collector`; no race detector, no Docker.

## What to try to break, in this order
1. **A file wanted from a chat the owner did not choose.** Every way a message of such a chat can be catalogued
   before, or without, the switch-off: the estimate; a read that begins, stops, and is taken up by a later run
   of the command, or by the collector's `run` (which now finds an approval on record: read
   `internal/collector/reader.go` to see what `run` then does with that chat, and whether its files can become
   wanted there); a chat whose row does not exist yet in the catalogue when the plan is made; a chat that has a
   cursor from an earlier read but was never approved, or an approval and no cursor; a chat brought in from the
   old archive; the switch-off succeeding and the approval failing, and the reverse; `-download` given on one
   run and not on the next. After each: count the files wanted for that chat.
2. **A chat the owner did choose loses its downloads:** any path on which the switch-off is applied to a chat
   that had an approval or a read under way, or that the owner had switched on.
3. **Requests before their yes:** anything dialled or sent before the first yes; anything but the one estimate
   before the second; the read or a forward starting when the second answer is not yes, when the input ends, at
   Ctrl-C at either question.
4. **Forwarding from a partial read:** a stop, a long wait, a refusal, a reader error or the pass bound in the
   middle of the read, then the same run going on to forward, or a later run forwarding without finishing the
   read; a chat whose cursor says done while messages are missing; new messages arriving in the chat between
   the read's end and the run (are they forwarded in order later?).
5. **Media only:** a message without an attachment forwarded; a message with media left out; an album split; a
   message whose media was left out for a self-destruct timer; `-all-messages` behaving otherwise than its
   name; the plan's two counts wrong; the candidates query scanning `message` or `attachment` on a large table.
6. **The read's waits and ends:** a wait on a history page slept in full and on record; a wait over the bound
   ending the command with the time; the chat refusing the account recorded and no mirror created afterwards;
   the reader's errors never taken for "read to the end".
7. **The approval record:** is it written exactly as the collector writes its own (so `chats` and `run` read it
   the same), and never before the second yes?
8. **Privacy:** every new line of output, progress and error: a title, username, Telegram id, access hash or
   path; format strings not constant.
9. **The tests:** for the three rules you judge most important, plant the defect through the overlay and say
   whether a test fails.

## One question of the architect's, after your own pass
The next piece runs this same function (`mirror.ReadThenRun`) inside the running collector, for a chat that
newly appears in the account's chat list, with nobody at the keyboard. By reading only: what in this function
or its `Deps` assumes a person answered yes just now, or a command that owns the catalogue's lock and the only
connection, and would be wrong when called from the collector's live run beside its reader and monitor?

## Report
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review3-scratch\REVIEW.md`: findings most severe first, each
with file and line, the scenario, CONFIRMED or PLAUSIBLE, the smallest fix you would accept; then what you
found sound; then what you did not check. Lead with what you ran. Final message: the findings as a numbered
list, the answer to the architect's question, what you did not check; under 40 lines.
