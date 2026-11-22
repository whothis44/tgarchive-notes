# Brief: the independent review of K21 (the account's own chat is read by itself) (Core, K-5, 2026-11-16)

You are the independent reviewer of this piece: Opus, read-only on the branch, with probes. You did not write
it. The coder's report is a claim, not evidence. **This piece makes the program send requests to Telegram for
the owner without a click. The owner decided it for ONE chat (the account's own), the READ only. Your job is
to find any way it does more than that: a second write, a write over what a person did, a request for
another chat, a file wanted, a read that cannot be stopped.**

**Rules of the house:** invented data only; nothing of a name, text, path or id in any output or in your
report (numbers and code names only). Nothing runs against Telegram: the collector's fake Telegram only.
Never touch a running program, the main copy `repo-archiver`, the coder's copy `wt-core-self`, or anything
under `E:\`. No push, no commit, no `git stash`. **Every go command goes through the track's lock script:**
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go1.sh <folder to run in> go test -p 1 -run '<names>' -timeout 20m ./internal/collector/`
(exit 97 or 98: nothing was run; wait and try again; a coder of another piece works beside you). Named tests
only (`-run`): the whole `internal/collector` is 30 minutes and not yours. No race detector.

**Where:** a scratch copy, one command from the project folder:
`git -C repo-archiver worktree add --detach ../wt-core-self-review-scratch 589af9a0`. Probes are files named
`zz_probe_k21_*_test.go` there, uncommitted. The piece was cut from the main head f1d7127b.

## Read first

1. `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-K21-own-chat-read.md` (what was asked; the owner's decision).
2. `repo-archiver/archiver/docs/TRIED-BEFORE.md` sections 24 and 25 in full: the thirteen rules for anything
   that acts for the owner. They are your checklist: answer each of the thirteen for this piece, by number.
3. On the branch: `archiver/docs/progress/core-self-REPORT.md`; `git diff f1d7127b 589af9a0 -- archiver/internal`
   (`collector/selfread.go` is the step; one call in `reader.go` `readTurn`; `approve_cmd.go`;
   `catalog/selfchat.go`, `chatreads.go`).

## Known before you start (the Core session's read; do not spend time re-finding these, do check the cure)

- **The brief said "ending a read is the owner's own door, which exists". It does not exist** (the coder's
  hand-back). So with the piece as built, the stored switch `reader.self_chat` set to off stops FUTURE
  approvals only: a read the step approved goes on, and the owner has no way to stop it. **Decided for the
  fix round: while the switch is off, or cannot be read, the reader does not read a chat whose approval
  carries the step's word** (looked at once per reader's turn, so before every request of that chat; the
  record stays; switched on again the read goes on from its cursor). Say whether that cure is enough for
  rule 3, where exactly it must sit (`readChats`? `readTurn`?), and what it must not break (the owner's own
  later yes on that chat makes the record the owner's: then the switch no longer governs it).

## Questions, in this order (a probe where one can decide it)

1. **Once, for good.** Every sequence you can build in which the step writes an approval twice for one
   account, or writes one after its mark exists: a restart between the approval's write and the mark (are
   they one transaction?), two sessions of one account at once, an account removed and added again under the
   same number (does the mark of the old account stop the new one, or is a stale mark left behind: which is
   right?), a catalogue restored from a backup, the switch flipped off and on, the mark's row unreadable.
2. **Never over a record.** Every form of an existing read record of the own chat (an estimate only, the
   owner's approval, the mirror's approval, a mirror's end, a record that cannot be parsed, an empty value):
   the step leaves it byte for byte. And the other order: the step's record first, then each owner's and
   mirror's door on that chat: is the result what that door's own rule says, and is a person's choice ever
   lost?
3. **No other chat, no file.** Can `SelfChat` ever name a chat that is not the account's own (another
   account's own chat in a shared catalogue, a private chat with a user whose number equals something else,
   a chat row whose account has no user id, a bot, a deleted account, a migrated chat)? After the step: is
   any file of the own chat wanted, supplied or downloaded on any path (a chat made collecting under
   `-new-chats-download`, the baseline, a kinds change, the mirror's `-auto-mirror-download`)? Count the
   fake's requests by kind in a run of several chats: every history request is the own chat's; no estimate;
   no part.
4. **Stopped by everything that stops a read.** A frozen account, a signed-out account, the owner's Stop of
   the account from the pages, a pause, Quit: does the own chat's read stop as any read does, and stay
   stopped across a restart? A wait Telegram states during that read: slept in full, stored, checked at the
   top of the next step (rule 4)?
5. **The switch.** Absent, on, off, unreadable, set twice at once from two calls (rule 11: is it one row?),
   set while the step's transaction runs. The fixed line is said once and again only after a good read. The
   doors `SelfChatRead` and `SetSelfChatRead` with no catalogue open.
6. **Every reader of the approval's `By`.** The coder's table lists eleven places. Is it complete
   (`grep -rn "\.By\b" internal/ cmd/`, the pages' `livepages`, the server's demo data, the viewer)? For each
   place: does the new word behave as the table says? Above all: the mirror never takes the own chat (the
   coder says a private chat is refused: show it for the automatic mirror AND for the owner's own "Mirror
   this chat" want); `setReadEndWrote` "counts it unreadable": can that count mislead a page?
7. **What a page and a command show.** `chats`, `-approve-read`, `ListChatReads`' new field: fixed words,
   nothing of the chat. The approval carries `EstimatedAt` although no estimate was asked: does anything
   show "estimated" or a request count of 0 as if it were a measured cost?
8. **The cost, said truly.** The report says a read of 250 messages cost 3 history requests when ids start
   at 1 and 4 when they do not. What does the reader ask for an EMPTY own chat (the click tests' rig has one:
   the step now runs in every such test), and at every later start: is any request repeated at each start
   for a chat already read to its end?
9. **The tests.** Run three of the coder's ten by name; say which pass for the wrong reason, if any (a
   record removed by direct SQL where a door should be; a "0 requests" read from a counter that does not
   count that kind). What the brief asked for and no test shows.

## Your report

`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-K21-own-chat.md` (write it with your file tool), and your last
message the same, short: the thirteen rules by number; an answer per question; the findings numbered, each
with its severity (must fix, should fix, minor), the probe that shows it and the smallest fix; what you did
not look at; and one last line, exactly one of: "may be listed", "may be listed after these fixes:
<numbers>", "not yet: <why>". Then stop.
