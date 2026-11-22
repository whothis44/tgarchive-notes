# Brief for the independent review of M10 (drafted 11-16 07:53 by the mirror session M5; the head is written in at the hand-back)

You review one piece of a private Go application (a standalone Telegram archiver) that you did not write.
**The tree under review is a frozen copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review13-tree`
(detached at the head named below). You edit nothing in it** and nothing anywhere else but your own folder,
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review13-scratch`: probe tests go there and are loaded with
`go test -overlay`; your report is `REVIEW.md` in that folder.

**HEAD UNDER REVIEW: ea105e9b (written in by M5, 11-16 08:27). The range: `dbca91d4..ea105e9b`.**

**How to work:** each finding high, medium or low, and CONFIRMED by a probe or PLAUSIBLE by reading; what you
did not check, said plainly. Go commands: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`,
`export GOGC=25 GOMAXPROCS=2`, `-p 1`, one at a time, named tests only, never a whole package, no Docker, no
race detector; the PC measured before each (under 2 GB free or the CPU over 80%: wait 60 s and measure
again, at most 10 times, then say so and go on by reading). Nothing runs against Telegram or the network;
nothing is started but `go test`; no real catalogue, log or media file is opened; the installed program is
never started. Your report holds no chat name, message text, id, link, or path of this PC's data. A probe
that has not ended after 10 minutes is stopped and said. Budget: about 60 minutes.

## The piece
What was asked: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-M10-auto-switch.md` (read it first, with its
section "What the old app already knows"). What the coder says it built and where it departed:
`archiver/docs/progress/mirror-autonew-REPORT.md` in the tree. In short: the app can, by itself, take a chat
the account's owner joined, create a private channel on the owner's Telegram account and forward the chat's
media into it (the "automatic mirror"). Until this piece that was a flag of the run (`run -auto-mirror`), set
up once at the start by `startAutoMirror` for the accounts of the start. This piece (1) stores the switch,
one settings row per account (`mirror.auto.new.N`), read by the task every turn; (2) adds a door a page
calls, `SetMirrorAutoNew`; (3) lets the task do the start's set-up itself, so that a switch set from a page
and an account added or signed in while the program runs need no restart; (4) while the switch is off, ends
the reads of the chats the task took (and clears that end when it is on again); (5) binds the plan's token
to the account and the chat. **This is code that decides whether chats are created and messages forwarded
on a person's real account without a click.** The rules it must keep are the 13 of
`archiver/docs/TRIED-BEFORE.md` sections 24 and 25; the lesson behind them is section 6b of
`C:\Users\trabi\Claude\Projects\Telegram\LESSONS-ix12.30-live.md` (read all three).

## Attack these, and anything else you find
1. **Something automatic is sent though the switch says no.** Any path on which a look takes a chat, a
   mirror is created or a batch forwarded for an automatic want, in a turn that read the switch as off or as
   unreadable, or after such a turn without a later "on": the first turn of a session; a session that began
   before the flip; the turn in which a page's door wrote (`turnDue`); the early returns of `autoTurn`; a
   set-up that failed half way (the mark set though "since" was not stored; the look due though not set
   up); `AutoWantsHeld` and `OwnerOnly` disagreeing with the mark. Count the fake's creates and forwards
   before and after each off. At most the one request already under way may land.
2. **An "off" undone backwards (rule 1).** A chat joined while the switch was off, taken after a later "on":
   through the baseline not removed, "since" not moved, a baseline written by a chat list that was under way
   during the flip, a look that reads the old baseline from memory, the flag's path after a page's flip, a
   restart between the off and the on, a second account of the same catalogue. And the opposite error: a
   second "on" (a double click, two tabs) that moves "since" or the baseline and so drops chats joined
   in between.
3. **Fail closed (rule 13).** A stored row that is empty, has another case, trailing text, a time of 0 or
   below, a time in the future, or is very long: never "on", never silently "off" without the unreadable
   sign; the policy for new chats is NOT removed then; the line is said once, with no stored text in it. A
   failed read of the catalogue in the task and in the door: nothing sent, nothing half written.
4. **The owner's own things touched by the switch.** An owner's want (made from a page) that stops being
   carried out because the switch is off or unreadable; an owner's read record (no `By`) or an owner's
   estimate changed by part A6; a chat the owner chose for downloads switched off; the owner's never mark
   or stop changed by a flip. And part A6 the other way: a held chat that is never read again after an
   "on" (the end not cleared on some path: the start's set-up, the task's set-up, a want that ended and
   began again while off), or a chat read on while off (count the reader's history requests on the fake).
5. **The door.** Under the run's flag (refused; the row untouched; `AutoNewSettable` false with words); an
   account not signed in, signed out a moment ago, unknown, or whose sign-in record cannot be read; the
   forward secret absent, of the wrong size, or with no file path (nothing written when it cannot be made);
   two flips at once from two goroutines (the row, "since" and the baseline must end as one of the two
   orders, never mixed); the transaction failing between the row and "since". What `MirrorTask` says in each
   state (`AutoNew`, `AutoJoined`, `AutoNewUnreadable`, `AutoNewFrom`) against what is true.
6. **The start, and an account that appears later.** With the stored switch on and no flag: is the policy
   for new chats in force before the monitor can store a chat (as it was with the flag)? An account added
   while the program runs, and one that signs in later: set up at its first turn, once, and never a second
   "since"; with no forward secret: not set up, said, and the other accounts still handled (the old code
   returned out of the loop). A reused account number is known and not this piece's (say only if this piece
   makes it worse than one more inherited settings key).
7. **What existed and must not change.** With the flag on and no page click, the task's requests and their
   seconds on the head are those on dbca91d4 (an earlier review's probe, read-only, if it still builds:
   `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review11-scratch\zz_m9base_test.go`). No chat list is
   asked sooner because of a click. The monitor's sink with the switch off does exactly what it did.
8. **The token (part B2).** A token of one chat's plan accepted for another chat or account; a token that
   now changes when nothing the owner saw changed (a page's yes refused for no reason).
9. **Shared state, for the race run:** list everything an HTTP goroutine and the reader's goroutine (or
   `Run`'s start) now both touch, and the tests that cross them, by name.
10. **The tests:** undo 6 rule lines of your own choice by overlay (among them: the switch read before `on`
    is taken; the baseline's removal at a flip; the "already on" case; the unreadable row; the door's refusal
    under the flag; A6's end) and see a named test fail; look for a test that stores its record as no real
    path writes it.

## Hand-back
`REVIEW.md` in your folder, and your final message: the verdict in one line (may be listed / may be listed
after these fixes / not yet); the findings most severe first with file and line, each CONFIRMED or PLAUSIBLE
with its probe's name and numbers; point 9's list; what you did not check.
