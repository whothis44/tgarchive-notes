# Brief for the independent review of M9 (11-16 00:17, the mirror session M4)

You review one piece of a private Go application (a standalone Telegram archiver) that you did not write.
**The tree under review is a frozen copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review11-tree`
(detached at e57adb3f). You edit nothing in it** and nothing anywhere else but your own folder,
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review11-scratch`: probe tests go there and are loaded with
`go test -overlay`; your report is `REVIEW.md` in that folder. (The coder goes on working in another copy,
`wt-mirror-door`: not yours to read or judge; judge e57adb3f.)

**How to work: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-M7-review.md`, its sections "How to work" and
"Hand-back"**, as the reviews before you did (each finding high, medium or low, and CONFIRMED by a probe or
PLAUSIBLE by reading; what you did not check, said plainly). Go commands:
`source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, `GOGC=25 GOMAXPROCS=2`, `-p 1`, one
at a time, named tests only, never a whole package, no Docker, no race detector; the PC measured before each
(under 2 GB free or over 85% CPU: wait). Nothing runs against Telegram; nothing is started but `go test`; no
real catalogue, log or media file is opened. Your report holds no chat name, message text, id, link, or path
of this PC ("the copy", "the scratch folder").

## The piece
The range `76df070b..e57adb3f` (13 commits; 76df070b is the piece before it, already reviewed). What was asked:
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-M9-mirror-door.md` with its two addenda. What the coder says it
built, its ten departures and its 17 undone rule lines: `archiver/docs/progress/mirror-door-REPORT.md` in the
tree. In short: the owner can ask from a page of the running program that a chat be mirrored. A "door" (called
from an HTTP handler) only writes the catalogue: a want made by the owner's hand (`c_mirror_want.by`, schema
step 22), a never mark, an allow, a stop, the owner's word for a settle's waiting choice (`c_mirror_word`).
The running collector's own automatic task (the reader task's goroutine, one writing request a turn) carries
it out, now also without the switch `run -auto-mirror` (then for the owner's wants only: no look, no policy).
New files: `catalog/schema_mirrorwant.go`, `mirror/door.go`, `mirror/auto_word.go`,
`collector/mirror_door.go`; changed: `mirror/auto.go`, `collector/mirror_auto.go`, `command.go` (the secret).

This code acts for the owner on Telegram. Its rules: one writing request at a time, never repeated by itself;
every wait Telegram stated slept in full; an unknown outcome settled from what the mirror chat holds, never
guessed, never sent again; the owner's "never" mark, the stop and the protected flag read before every
request; never a second mirror chat while the first may exist; fail closed on any stored value that cannot be
read; one row per item; nothing done by itself that the owner did not choose, and never undone what the owner
chose.

## Attack these, and anything else you find
1. **A request from anywhere but the reader task's goroutine, or a new kind of request.** Every door in
   `door.go` and `mirror_door.go`, followed to its last call: does any reach the forwarder, the reader, a
   connection, or a function that can send? Does a door ever sleep on a wait?
2. **The pace.** With owner's and automatic wants together and the door's nudge (`turnDue` clears the yield):
   is any write sooner after the one before than the account's pause, or over the bound per hour, or two
   writes in one turn? A storm of 200 door calls during a history: the moments of the requests against a run
   without it. **And with the switch on and no door used: the requests and their moments are the same as on
   76df070b** (use the earlier reviews' probes if they build:
   `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review9-scratch`, read-only), except what the report's
   departure 9 changes (the cap per day now counts every starter): say exactly what that changes for a run
   that only has automatic wants.
3. **Never, stop, protected, left: no request for the chat starts after the record is written**, on every
   kind of want (owner's, automatic, on a command-made mirror) and at every point of a turn you can reach
   between two requests; a stop, then a look with the switch on: the chat is not taken again; a new want
   after a stop: the same mirror row, only what is left, 0 creates.
4. **Never a second mirror chat.** `AddOwnerMirrorWant` and `Want` against every state a chat can be in: a
   mirror row creating, unknown, created, protected, not created, ended with each end word; a want blocked;
   a chat whose migration links it to one that has a mirror or a want; a mirror whose chat the owner removed;
   two wants written at once; a want written while the task is in the middle of that chat's create.
5. **The owner's word.** Applied only to the block it fits and only once; a word for an older batch or after
   the block was lifted another way; the read of the mirror chat starts after the word and after the
   settle's own margin; `not-arrived` and `arrived` give exactly what the command's `-settle -take` gives on
   the same fixture (build the real shape: a batch of 99, 65 in the mirror, and a case where some cannot be
   told), in particular **no message that arrived is ever forwarded again unless the owner said
   `not-arrived`**; `by-rules` and what it reblocks with; `create-not-made`: its condition against the
   command's own (`mirror_settle_cmd.go`), and that a channel that does exist is never declared not made.
6. **The forward secret.** A door makes its file when absent: the same path as the command's and the run's,
   never a second secret while one exists, never a partial file read by the task, never printed or logged.
   The random ids the task gives a message equal the ids the command would give it (so a message put back
   goes under the id it had).
7. **Without `-auto-mirror`:** no look, no "since", no baseline, no policy for new chats written; a chat
   joined in the run is not taken; automatic wants of an earlier run are neither served nor ended; with no
   owner's want: 0 requests, 0 writes, 0 log lines per turn.
8. **The schema step and older files.** Applied once on a file at the step before; rows that exist get
   `by = 'auto'`; a read-only handle on an older file says "nothing on record" for every new read (no SQL
   error text reaches a page or the command); `mirror -list` and the plan on an older file.
9. **`NoteAccountWrite`:** only ever raised; `MirrorLastWriteAt` the later of the two; an unreadable note
   sends nothing; with no note no moment of any run changes.
10. **Fail closed:** each new stored value made unreadable in turn (`by`, a word, the word's batch, the note,
    an end word): nothing is sent and no default is taken.
11. **The state for the page.** `States` against the plan for the same chat: can they disagree (the report's
    departure 10: `Never` is the chat's own mark only, `Left` counts media only)? Is any state reachable that
    shows "kept" while nothing will be sent, or an offer the task cannot carry out? The cost at 300 mirrors
    and 200,000 forward rows.
12. **Shared state, by reading (no race detector):** everything an HTTP goroutine and the reader's goroutine
    both touch (`turnDue`, the fields under `autoSession.mu`, `autoSession.secret`, `said`, the collector's
    `mu`, the secret file): is each guarded? List them for the race run that follows.
13. **An account that is not signed in, is stopped by the owner, or is refused:** what each door does.
14. **Words and logs:** no name, title, text, id or link in any new line, error or event; constant formats.
15. **The tests:** undo 6 of the report's rule lines of your own choice by overlay; look for a test that
    stores its case as no real path does.

## Hand-back
`REVIEW.md` in your folder, and your final message: the verdict in one line (may be listed / may be listed
after these fixes / not yet); the findings most severe first with file and line, each CONFIRMED or PLAUSIBLE
with its probe's name and numbers; the list of point 12; what you did not check.
