# Brief K21b: the fix round after K21's independent review (Core, K-5, 2026-11-16)

**Rules of the house:** you are an Opus coder and hand back commit-ready work. Named tests only (`-run`; the
whole `internal/collector` is 30 minutes and not yours). No race detector. Invented data only; nothing of a
name, text, path or id in any log line, error or commit message; log lines are constant formats with numbers
only. Nothing runs against Telegram: the collector's fake only. Never touch a running program, the main copy
`repo-archiver` or anything under `E:\`. **Every `go`, `gofmt` or `vet` command goes through the track's lock
script** (full runs of another piece take turns with you: a wait of many minutes for the lock is normal):
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go1.sh <folder to run in> go test -p 1 -run '<names>' -timeout 20m ./internal/collector/`
(it prints "go1: exit N"; 97 or 98: nothing was run, wait and try again).

**Where:** the existing copy `C:\Users\trabi\Claude\Projects\Telegram\wt-core-self`, branch `wip/core-self`,
head 589af9a0 (clean, pushed). New commits on top; commit with `git -c user.name=Claude -c
user.email=noreply@anthropic.com commit`, the message ending `Co-Authored-By: Claude Opus 5.5
<noreply@anthropic.com>`; push only that branch to `private`. No `git stash`, no rebase, no amend.

## Read first

1. `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-K21-own-chat.md`, in full (the thirteen rules, the nine
   answers, "where the decided cure goes", the six findings).
2. `BRIEF-K21-own-chat-read.md` (the owner's decision and what it covers: the READ of one chat, nothing
   downloaded unasked) and, on the branch, `archiver/docs/progress/core-self-REPORT.md` and
   `archiver/internal/collector/selfread.go`.
3. The reviewer's probes (read-only; take them over as tests where this brief says so):
   `wt-core-self-review-scratch\archiver\internal\collector\zz_probe_k21_run_test.go` and
   `zz_probe_k21_unit_test.go`.

## The decisions (the Core session's, on every finding)

1. **Finding 1, must fix: the switch stops the read, not only the approval.** (The first brief was wrong to
   say an owner's door to end a read exists; so today nothing can stop a read the step approved: rule 3 of
   TRIED-BEFORE 24.) While the stored switch `reader.self_chat` is off, or cannot be read (rule 13: fail
   closed, and the fixed line once), **the reader does not read the account's own chat unless its read
   record is the owner's own** (an approval with `By` empty: the owner's yes takes the chat out from under
   the switch for good). As the reviewer places it: a flag set in `readChats` for that chat (it is the
   account's own chat by `SelfChat`, and its record is not the owner's: the step's word, another program's
   word, no record, or a record that cannot be read), **honoured at all three places that today call
   `skipEnded`: the topics loop, the common-box gap and the turn loop**; the chat is NOT dropped from the
   list (the gap's index needs the list whole). The switch is read once per reader's turn, not per request.
   The record and the cursor stay: switched on again, the read goes on where it stopped. Nothing else of
   the reader changes, and for a chat that is not an account's own, nothing at all.
   Tests (each seen failing on 589af9a0): the switch set to off after the own chat's first page: no further
   history request for it, in the turn loop and in the common-box gap; on again: the read goes on from its
   cursor and ends; unreadable: as off, with the line once; the owner's yes on the own chat, then off: it is
   read on; another chat approved by the owner is read on whatever the switch says.
2. **Finding 2, must fix: nothing of the own chat is downloaded by this step, under any flag.** The reviewer's
   probe: under `-new-chats-download` the own chat's row is made collecting, the step approves its read, and
   49 files of its history are downloaded with no click. The owner's decision says its files follow the
   owner's download choice and nothing is downloaded from it unasked. **So the step acts only while the own
   chat is switched off for downloads** (the chat's `collect_off`, read inside the step's transaction with
   the mark, the switch and the record). When the chat collects: no record, NO mark (so that it can act
   later, the day the chat is switched off), one fixed line said once per account and run (constant format,
   the account's number). Take the reviewer's `TestZZProbeK21NewChatsDownload` over as the test (0 history
   requests for the own chat by the step, 0 parts, 0 files), and one more: the chat switched off later, the
   next chat list: the step acts.
   Not changed, and said in the report: an owner who LATER switches the own chat on for downloads gets the
   files of what was read: that is the owner's choice, as for any chat.
3. **Finding 3: the step's record shows no estimate that was never asked.** The smaller of the two: either
   the step does not set `EstimatedAt` (if no door needs it for a record that is approved: check the owner's
   later "approve this read" and the estimate door on such a record, by test), or `ListChatReads` leaves the
   estimate empty for the step's record as the reviewer describes. Say which and why. The reviewer's
   `TestZZProbeK21PagesEstimate` becomes its test.
4. **Finding 4 (a deleted account leaves its mark and its read records): NOT in this round.** It is in the
   catalogue's account removal (`settle.go` `deleteAccountChunk`), which a listed piece of this track (K17)
   changes in the same lines; no door calls `DeleteAccount` today. Written down as known in the report, with
   the two key patterns to delete; the Core session takes it after K17 is merged.
5. **Findings 5 and 6:** the report's table of every reader of `By` gains the two places the reviewer found
   (`status.go` near 56: "approved for reading" counts the step's approval: say whether that count should
   include it, and keep it if the line's words stay true; `internal/server/notadded.go`'s "approved" word:
   the pages track's file: list it for them, do not edit it); the report says the cost the reviewer adds
   (after its read the own chat is part of every common-box gap read; an empty own chat costs 1 history
   request at the first start and 0 at a restart); `selfLineSwitchBad` no longer names a page control that
   does not exist ("until it is set anew" is enough).

Nothing else changes.

## Checks

The new and changed tests by name; `-run 'TestSelfRead|TestSelfChat|TestBaselineSelf'` in both packages; the
existing reader, approval, mirror-read and baseline tests the first round ran, by name, once (the report lists
them); `gofmt -l`; `go build ./...`; `go vet ./internal/collector ./internal/catalog`.

## Hand back

The report file brought up to date and committed, the branch pushed, and your last message, short: the head;
per decision what was done (for 1: the three places, by function); test functions added, changed, removed, by
name; anything that is not as this brief says. Then stop: the full runs are the Core session's.
