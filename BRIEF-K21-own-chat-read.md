# Brief K21: the account's own chat (Saved Messages) is read by itself (Core, K-5, 2026-11-16)

**The owner's decision (board item 41, 11-16 19:39, asked with both ways and their cost): "By itself".** On a
signed-in account the app reads the history of the account's own chat without the owner choosing it, so that
the one window's first screen shows something. Board message 173 says what it covers and what not; this brief
is that, made exact.

**Rules of the house:** you are the Opus coder of this piece and hand back commit-ready work. Named tests only
while you work (`-run`; the whole `internal/collector` takes 30 minutes and is not yours to run); no race
detector; no `go vet` over many packages. Invented data only; nothing of a name, text, path or id in any log
line, error or commit message; new log lines are constant format strings with numbers only. Nothing runs
against Telegram: the collector's fake Telegram only. Never touch a running program, the main copy
`repo-archiver` or anything under `E:\`. **Every `go`, `gofmt` or `vet` command goes through the track's lock
script:** `bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go1.sh <folder to run in> go test -p 1 -run '<names>' -timeout 20m ./internal/collector/`
(it prints "go1: exit N"; 97 or 98: nothing was run, wait and try again).

**Where:** make the copy yourself, one command, from the project folder:
`git -C repo-archiver worktree add ../wt-core-self -b wip/core-self f1d7127b`. Work only in
`C:\Users\trabi\Claude\Projects\Telegram\wt-core-self`. Commit with `git -c user.name=Claude -c
user.email=noreply@anthropic.com commit`, the message ending `Co-Authored-By: Claude Opus 5.5
<noreply@anthropic.com>`; push only `wip/core-self` to `private`, work in progress too. No `git stash`, no
rebase.

## What the old app already knows

- The old app treats Saved Messages as one chat among the others the owner added; nothing in it reads a chat
  the owner did not add, until 12.30's automatic count-and-add, whose independent review found defects after
  every test had passed. **Its thirteen rules for anything that acts for the owner bind this piece**
  (`repo-archiver/archiver/docs/TRIED-BEFORE.md` sections 24 and 25: read both in full before you write).
  The ones that bite here: (1) never undo a person's pause or "off"; (2) "the owner took this out" is judged
  from a durable record, not from one sign; (3) a "never" switch, checked again before every action; (4)
  Telegram's waits stored and slept in full; (9) no request for an item that will not be acted on; (10) a cap
  per step; (11) one row per item; (13) fail closed: a mark that cannot be read stops the automatic step.
- The cost of a read: about one history request per 100 messages, no download (TRIED-BEFORE sections 14 and
  26; the same in the new app's reader). On the test account the new app's reads have met no wait at that
  pace.
- The new app already has an approval of a read that is not the owner's: the automatic mirror's
  (`internal/collector/mirror_auto.go` `autoApprove`; the record `ReadApproval` with `By` set, in
  `reader.go`). It approves the READ and does not choose the chat for downloads. That is the form to follow.

## What to build

**For:** the owner's own notes are in the archive, and on the first screen, without a click; and nothing else
changes: no file is downloaded from that chat unasked, no other chat is read unasked.

1. **Which chat.** The account's own chat is the chat row whose Telegram peer is the user with the account's
   own user id (`account.tg_user_id`; the chat list answers `InputPeerSelf` for it, `telegram/dialogs.go`).
   One door in `internal/catalog`, usable on a read-only handle (the viewer calls it; it has no Telegram
   code): `SelfChat(ctx, account) (chat int64, ok bool, err error)`: the catalogue's chat id, false when the
   account has no such row yet or its user id is not known. No schema step: it is a read of what is stored.
   If the stored rows cannot tell it (say so and stop): do not add a column without asking.
2. **The approval, written once.** In the collector, at an account's turn after its chat list is stored (find
   the place the automatic mirror's set-up uses; do not put it on the reader's hot path): when the account is
   signed in and not frozen, the switch below is on and readable, `SelfChat` answers, **and no read record of
   any kind exists for that chat** (`keyRead(account, chat)`: an estimate, an approval of anyone's, an end):
   one `ReadApproval` is written with `ApprovedAt` now and `By` a new fixed word of its own (a constant,
   e.g. `selfApprovedBy`), in one transaction with a durable mark "done for this account at T" (a settings
   row per account). **Once the mark exists the step never writes again for that account**, whatever happened
   to the record since: an owner who ends or removes that read is never overridden (rules 1 and 2). No
   estimate request is sent (rule 9: the read is not waiting for a yes). It does NOT call `ChooseChat` and
   changes nothing of the chat's downloads: a chat made switched off stays switched off.
3. **The reader then reads it as it reads any approved chat** (its pace, its counts per kind and hour, every
   wait slept in full, the live monitor after). Nothing in the reader's loop changes. Its rank among the
   account's reads: as any chat without a rank (do not put it first by a special case).
4. **The switch.** One stored setting per catalogue, on when absent: `reader.self_chat` ("read each account's
   own chat by itself"); doors in the collector for a page, in the form of the mirror's `MirrorListEvery`
   and `SetMirrorListEvery`: a read that answers the value, whether it is stored, and "unreadable", and a
   set. A value that cannot be read: the step does nothing and one fixed line says so (rule 13). Switched
   off: the step writes nothing from then on; an approval it wrote earlier stays (ending a read is the
   owner's own door, which exists). The control's place on a page is the pages track's: list the doors in
   the report.
5. **Every reader of `ReadApproval.By` looked at.** Today a `By` that is not empty means "the mirror's" in
   several places (`mirrorRecordBy`, the reader's `ended` and `ownerEnded`, `EstimateRead`'s keep, the approve
   command's words, the baseline's `ownerApproved`, the pages' and the mirror's doors that show a chat's
   state). For each: what must the new word mean there? At least: a mirror's want that ends must not end
   this read; the baseline must not take it for the owner's hand on DOWNLOADS (the chat stays unchosen); the
   owner's own "approve this read" on that chat afterwards makes the record the owner's, as it does for the
   mirror's; a page that shows a chat's read state has a fixed word for it. List every place in the report
   with what you did.
6. **One log line** when the approval is written: constant format, the account's number only. Nothing else
   new in the log.

**Do not touch:** the download path, `internal/supply`, `internal/engine`, the mirror's files (read them; if
one line of the mirror's is needed, stop and say which), `internal/viewer`, `internal/server` and
`livepages` (the pages' and the viewer's; list for them what they can call). No schema step.

## Tests (each seen FAILING first; against the collector's fake Telegram where a run is needed)

1. A new catalogue, one account signed in, its own chat in the chat list with 250 invented messages and two
   other chats: after the run's first turns the own chat's history is read (3 history requests counted at
   the fake, as an owner-approved read of 250 messages costs), the other two chats get no history request,
   no estimate request is sent, and no file of the own chat is wanted (its chat is switched off for
   downloads; the queue is empty).
2. Written once: the owner ends that read through the existing door, the program restarts, the chat list
   comes again: no new approval, no request.
3. A record already there before the step's first turn (an estimate only; the owner's approval; the
   mirror's approval): the step writes nothing over it and its mark is still set (it never comes back).
4. The switch: off: nothing written, nothing read; unreadable (a corrupt stored value): nothing, and the
   fixed line once; on again: the step acts for an account that has no mark.
5. A frozen account, an account that is not signed in, an account whose own chat is not in the chat list:
   nothing; the last one acts at a later chat list that has it.
6. Two accounts in one catalogue: each its own mark, each its own chat, neither reads the other's.
7. The mirror: a want on another chat that ends does not end the own chat's read; the automatic mirror's
   set-up does not take the own chat for a joined chat to mirror (say what it does today; if it would mirror
   Saved Messages, that is a finding for the board, not yours to change).
8. The baseline (`TestBaseline...` shows how): a catalogue whose only approval is this one: the own chat is
   not counted as chosen by the owner.
9. `SelfChat` on a read-only handle, on an account without a user id, on a catalogue older than the build.
10. The existing tests of the reader's approvals, the mirror's approvals and the baseline by name still
    pass; list what you ran.

`gofmt -l`, `go build ./...`, `go vet ./internal/collector ./internal/catalog`.

## Hand back

`archiver/docs/progress/core-self-REPORT.md` (committed) and your last message, the same content, short: the
head and that it is pushed; where the step runs and what it writes; the table of every reader of `By`; the
doors for pages and the viewer with their exact names; the tests as run; what you could not test; anything in
this brief the code contradicts (above all: point 1, if the stored rows cannot name the chat). Then stop: the
review and the full runs are the Core session's.
