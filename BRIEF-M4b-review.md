# Brief M4b-R: independent read-only review of the automatic mirror's fix round and of settling (2026-11-15)

You are a challenger. You did not write this code. Two commits on `wip/mirror-auto` are under review:
f182f7d (sixteen fixes after an earlier review of the automatic mirror) and d5a4a7c (**settling**: a batch of
forwards whose outcome is unknown is settled from what the mirror chat holds, and its mirror unblocked). The
change is `git diff 186d76d..HEAD` in `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-auto` (Go module in
`archiver/`). What was asked: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-M4b-fixes-and-settle.md`. The earlier
review whose findings part A answers: `wt-mirror-review4-scratch\REVIEW.md`. What happened on the real account
(the reason for settling): `C:\Users\trabi\Claude\Projects\Telegram\SESSION-MIRROR-PROGRESS.md` sections 8 to 10.
The coder's report (`archiver/docs/progress/mirror-auto-REPORT.md`, sections "Fix round" and "Settling"): read
it last, trust none of it.

The defects that matter most here: **a settle that calls a message "not arrived" when it is in the mirror (it
is then forwarded a second time: a copy in the owner's mirror), or "arrived" when it is not (it is never
forwarded: a hole);** a settle that runs before the mirror chat is truly on record past the request; anything
sent in a loop; a mirror ended or unblocked wrongly; a download queued from a chat nobody chose; with the
switch off, anything different from before.

## Read-only (as before)
Edit nothing in the copy. Probes in a scratch folder of your own
(`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review5-scratch`, make it), loaded with `go test -overlay`.
Each finding CONFIRMED (a probe shows it) or PLAUSIBLE (reading only); write findings into the report as you
confirm them. Nothing against Telegram; never the built command with real settings; never a real catalogue
(nothing under %LOCALAPPDATA%\tgarchive), a session file, the API settings file, `E:\T\tg-dl` or media. Invented
data only. Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`; one go command at a
time, each with `GOGC=25 GOMAXPROCS=2 -p 1`; only named tests; never a whole-package run of `internal/catalog`
or `internal/collector`; no race detector, no Docker.

## Part B first: settling (`internal/catalog/mirrorsettle.go`, the settle turn in `internal/mirror/auto.go` and
`internal/collector/mirror_auto.go`, the command's `-settle`)
1. **The architect's first suspicion, from reading: a source message that is itself a forward.** Telegram keeps
   a forward's ORIGINAL origin: when the source chat's message 500 is itself "forwarded from channel B, post
   55", its copy in the mirror names B:55, not the source's 500. `SettleMirrorBatch` looks only for origins
   with the source's own prefix, and for a broadcast channel takes every message without one as "did not
   arrive" (`again = rest`). So in a channel that reposts, an arrived repost is put back as a candidate and
   forwarded a second time. Confirm or refute with a probe (a batch of a channel source in which some messages
   carry their own forward origin: a post of another channel; a bare sender; the same other post twice), and
   say what the reader records as the origin of such a message in the source and in the mirror (read
   `internal/telegram/record.go` `forwardOrigin`). The smallest fix you would accept.
2. **The architect's second suspicion: "on record past the request" can be true for a read that began before
   the request.** `MirrorOnRecordAt` takes the later of the newest stored message's date and the time the
   read reached its end (`cur_at`, the END of the read by the coder's own doubt). A read of the mirror that
   started before the batch was sent and ended more than 60 s after it (a wait slept inside the read; a slow
   page) passes the check without having seen the batch's messages: all of them are then "not arrived" and
   sent again. Confirm or refute; say what the catalogue stores about a read's start; the smallest fix (for
   example: the settle counts only a read of the mirror that the settle itself began after the request plus
   the margin and that ended cleanly).
3. Everything else you can do to make a settle wrong: the mirror holding forwards of the same source from an
   earlier mirror row or made by the owner by hand; the same source message forwarded into the mirror twice
   before (the real case had none); service messages; edited or deleted mirror messages; a source that is a
   supergroup, a basic group, a private chat (the media rule): two source messages with the same media, a
   message with two media, an album; a batch "already"; a batch "sending" left by a kill; a mirror chat read
   by another account; clock steps; the transaction's all-or-nothing; the ledger after a settle (counts,
   states, candidates' order, the per-hour bound's reading of a settled batch); a second settle of the same
   batch; a settle while a "never" mark is set; a settle of a mirror whose chat the owner removed.
4. The settle turn: at most one read a turn; what it reads (`Newer`); the reader not called twice at once; its
   waits; the mirror chat's read queues no file (the mirror is switched off: count wanted files); the approval
   it writes for the mirror chat; a loop of settle turns that never settles (cannot tell): how often it reads.
5. The command: `-settle N`, the plan's offer, going on with `-batches` after a settle; nothing sent before its
   yes; the words.

## Part A: are the sixteen fixes real?
For each of the earlier review's findings 1 to 6 and 8 to 14 (7 is deliberately not fixed; 15 is a note), run
its probe again against this code (the probes are in `wt-mirror-review4-scratch`) and say fixed, partly, or
not. Then look for what the fixes broke: a blocked want or mirror that can never be unblocked, or is unblocked
wrongly by `-allow`; the cap counting; the policy for shared chats (a channel two accounts share when one
account is removed or signed out); the baseline; the adoption of a channel after a lost create (two channels
of the name; a channel of that name the owner made; the title changed); the 30-second bound on
`help.getConfig`; the look leaving the owner's records alone; `TestMirrorAutoSwitchOff`'s fixed expectation
(is it really the behaviour of 99b71c3?); the start pause of 20 s everywhere it is named. And once more:
with the switch off, does `run` send, write or log anything it did not before this branch.

## The fake and the race run that follows
The architect runs the race detector on the whole `internal/collector` after this. The coder says the fake's
`ChatOf` reads a map without its lock beside `Join`. By reading only: every place where the new test code or
the fake shares state between goroutines without a lock or an atomic, and whether the program's own new code
does (the heartbeat's numbers, the look-due flag, the topics' time, the policy read).

## Report
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review5-scratch\REVIEW.md`: findings most severe first, each
with file and line, the scenario, CONFIRMED or PLAUSIBLE, the smallest fix you would accept; the table of the
earlier findings (fixed / partly / not); the places a race run may flag; what you found sound; what you did
not check. Lead with what you ran. Final message: the findings as a numbered list, the verdict on the two
suspicions, the earlier findings' table in one line each, the race places, what you did not check; under 45
lines.
