# Brief for the independent review of M11 (11-16 03:44, the mirror session M4): a short one

You review one small piece of a private Go application (a standalone Telegram archiver) that you did not
write. **The tree under review is a frozen copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review11-tree`
(detached at 85f984de). You edit nothing in it** and nothing anywhere else but your own folder,
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review12-scratch`: probe tests go there and are loaded with
`go test -overlay`; your report is `REVIEW.md` in that folder.

**How to work: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-M7-review.md`, its sections "How to work" and
"Hand-back"** (each finding high, medium or low, and CONFIRMED by a probe or PLAUSIBLE by reading; what you
did not check, said plainly). Go commands: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`,
`GOGC=25 GOMAXPROCS=2`, `-p 1`, one at a time, named tests only, never a whole package, no Docker, no race
detector; the PC measured before each (under 2 GB free or the CPU over 80%: wait). Nothing runs against
Telegram; nothing is started but `go test`; no real catalogue, log or media file is opened. Your report holds
no chat name, message text, id, link, or path of this PC. Budget: this is a short review: about 30 minutes.

## The piece
The range `f0d54ad6..85f984de`. What was asked: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-M11-ended-read.md`.
What the coder says it built, its departures and its undone rule lines:
`archiver/docs/progress/mirror-endread-REPORT.md` in the tree. In short: the mirror's automatic task had written
an approval for the collector's reader to read a chat (a settings record, `ReadApproval` in
`collector/reader.go`, with `By` set to the mirror's word). When the mirror's want of that chat ends for good
(the source protects its content, the owner's never mark, the source left, the mirror chat removed, a refused
forward, the owner's stop), the reader went on reading that chat for nothing. The reader (another track's
code, already merged, not under review) now skips a chat whose record is the mirror's and carries
`mirror_ended_at`. **This piece writes that field** in the transaction of each end and of a never mark
(`AutoDeps.EndRead`, the collector's `endReadFor` over `setReadEnd`), and **clears it** on each new beginning
(the look's take and a page's want through `autoApprove`; a want on a chat already read through `ResumeRead`;
an allow that leaves a live want). A record of the owner's (no `By`) is never touched; a record that cannot
be parsed, or whose `By` is not a word of the mirror's, is left byte for byte and counted.

## Attack these, and anything else you find
1. **A record of the owner's is rewritten, or its meaning changed**, on any path: an estimate on record, an
   approval the owner gave by hand, an estimate the owner answered "no" to, a record made by the owner after
   the mirror's (the reader's `approveRead` drops `By`). And the opposite: a record of the mirror's that the
   rewrite damages (a field lost or changed by the round trip through a map: compare byte meaning before and
   after for every field the reader reads).
2. **A chat that is never read again though it should be:** every beginning against a record that still
   carries the field: the look's take of a chat joined again; a page's want on a chat read to its end, not
   read to its end, with a cursor, with no record; a new want after the owner's stop; an allow after a never
   mark with a live want, with an ended want, with a stopped want, with a command-made mirror and no want;
   the chats a migration links. Count the reader's history requests on the collector's fake after each.
3. **A chat read on though its want ended:** each end (the coder lists seven) and the never door, in a run
   with the switch and in a run without it (an automatic want is not visited then); the one-turn window the
   coder names (the reader read the records before the task's turn: it added a line that ends the reader's
   turn when the task ended a want: does it hold for a door's write too, and can that line starve or stall
   the reader, for example a want that ends every turn?).
4. **Half done:** an end written without the field, or the field written without the end, when the closure
   or the end fails in between (the closure runs inside the end's transaction: check each caller really
   passes the transaction's handle and that a failing closure rolls the end back). The command's `-never` and
   `-allow` (the collector stopped) against the doors' (the collector running): the same result on the same
   record.
5. **The count of unreadable records:** counted once per record and event, never per turn without bound (a
   record that cannot be read and a want that is weighed every turn); the line said once a session; no name,
   text or id in it. The shared counter (`autoSession.readBad`, atomic) and anything else an HTTP goroutine
   and the reader's goroutine now both touch: list them for the race run.
6. **What existed and must not change:** with no end and no never mark in play, the task's requests and
   their seconds are the same on f0d54ad6 and on 85f984de (the earlier review's probe
   `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review11-scratch\zz_m9base_test.go`, read-only there, if it
   still builds: its digests were bf22f9016133bbe6 and 4a0a602934ac6f5b), and `EndMirror`, `SetMirrorNever` and
   `MirrorAllow` called with a nil closure behave exactly as before (the coder changed 16 tests by `, nil`).
7. **The tests:** undo 5 rule lines of your own choice by overlay and see the named test fail; look for a
   test that stores its record as no real path writes it.

## Hand-back
`REVIEW.md` in your folder, and your final message: the verdict in one line (may be listed / may be listed
after these fixes / not yet); the findings most severe first with file and line, each CONFIRMED or PLAUSIBLE
with its probe's name and numbers; the list of point 5's shared state; what you did not check.
