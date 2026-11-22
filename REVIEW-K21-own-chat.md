# Review of K21: the account's own chat is read by itself (independent reviewer, Opus, 2026-11-16)

Branch `wip/core-self` 589af9a0 (from f1d7127b), read-only. Scratch copy `wt-core-self-review-scratch`
(detached at 589af9a0). The probes are uncommitted files there:
`archiver/internal/collector/zz_probe_k21_run_test.go` and `zz_probe_k21_unit_test.go`. Every go command ran
through `runs-core-k5/go1.sh`, named tests only, no race detector. Nothing ran against Telegram: only the
collector's fake. Numbers only below.

## The thirteen rules (TRIED-BEFORE 24 and 25), by number

1. **Never undo a person's pause or off.** Kept for the chat's download switch in the shipped default:
   `ChooseChat` is not called, and a chat made switched off stays off. **Broken in one case: under
   `-new-chats-download` the read makes the own chat's history files download with no click (finding 2).**
   The catalogue switch set to off does not stop a read under way (finding 1, known).
2. **"Taken out" is judged from a durable record.** Kept. The mark is a settings row per account, written in
   the same transaction as the approval. Any read record of any form leaves the record byte for byte and
   writes the mark alone. Probe U3 checked an empty value, `null`, a mirror's end and an estimate without a
   yes, on top of the coder's four forms.
3. **A "never" switch, checked again before every request.** Not kept as built (finding 1, known). With the
   decided cure it holds at catalogue level, once per reader's turn, which is at most 10 pages. It does not
   hold per account.
4. **Waits stored and checked at the top of each step.** The step itself sends nothing. The read uses the
   reader's path, which this piece does not change. I did not check again whether a wait survives a restart.
5. **Errors sorted.** Not applicable: the step makes no request. A failed catalogue read writes nothing, and
   the next chat list tries again.
6. **One costly failure ends the step.** Not applicable: there is no request.
7. **One item per call, each success recorded.** Kept: one chat per account per try, recorded in one
   transaction.
8. **Busy flags released with defer.** Not applicable: no lock is held. `selfBadSaid` is a said-once flag,
   not a busy flag.
9. **No request for an item that will not be acted on.** Kept. Probes P1 and P4 counted 0 estimate requests,
   and the read feeds the first screen.
10. **A cap per step.** Kept: at most one approval per account per stored chat list.
11. **One row per item.** Kept. The switch is one `c_settings` row (key primary key), the mark one row per
    account, the record one row per account and chat. 16 tries at once wrote 1 approval and 1 line (U2).
12. **A mark follows a change of identity.** The own chat never migrates. One gap: an account deleted
    through `catalog.DeleteAccount` leaves its mark and its record, and the next account and chat reuse the
    same numbers (finding 4; no door calls it today).
13. **Fail closed.** Kept in the step:
    - a mark of any value counts as done;
    - a switch that cannot be read stops the step, with one fixed line;
    - a record that cannot be read is left as it is;
    - a failed read of the catalogue writes nothing.

    The reader side needs the cure (finding 1, last point).

## Answers to the nine questions

1. **Once, for good.**
   - **The approval and the mark** are one `Batch`: one write transaction on the catalogue's single writer.
     The mark, the switch and the record are read again inside it. A restart between the two cannot happen.
   - **Two sessions at once:** 16 concurrent tries wrote 1 approval and 1 line (U2).
   - **Removed and added again under the same Telegram user:** `RemoveAccount` only marks the row, and
     `UpsertAccount` returns the same id. The mark stops the account, which is right: it is the same
     account, and its record is still there.
   - **Deleted** (`DeleteAccount`, no door today): the mark and the record are left behind (finding 4).
   - **A backup:** it holds both rows or neither. A restore from before the step lets the step act once
     more. This is unavoidable and harmless.
   - **The switch flipped off and on:** a marked account never acts again; an unmarked one acts at its next
     chat list.
   - **A mark that cannot be read:** a read error writes nothing; any stored value counts as done.
2. **Never over a record.** Every form I built is left byte for byte, with the mark set (U3 and the coder's
   `TestSelfReadRecordThere`, which passed when I re-ran it). The other order, the step's record first and
   then each door:
   - **The owner's estimate** (`EstimateRead`) keeps the approval and its word.
   - **The owner's yes** (`approveRead`, or `-approve-read`, which asks no estimate for this word) makes the
     record the owner's and chooses the chat. This is the mirror's precedent.
   - **The mirror's doors** never reach the own chat: `wantRefusal` refuses kind `user` (`mirror/door.go`
     424), and `Look` weighs it as Private.
   - **`setReadEndWrote`** would leave the record and count it as "bad". This cannot be reached.

   No person's choice is lost.
3. **No other chat, no file.**
   - **`SelfChat`** joins the account's own private space (`shared = 0`, `account_id`, `tg_chat_id =
     tg_user_id > 0`). Every chat maker stores Telegram ids through `TgChat.Marked()`: a basic group is
     negative and a channel is `-1e12 - id`. So no group, channel or migrated chat can match. A bot or
     another user has another id. Another account's own chat is in that account's space. The unique index on
     `tg_user_id` rules out two accounts with one user.
   - **Request counts:** in a run with the own chat and two other chats (P1), there were 3 history requests,
     all of the own chat, 0 of the others, and 0 estimates.
   - **Files:** in the shipped default, 0 files are wanted (the coder's `TestSelfReadRun` passed). **Under
     `-new-chats-download` (the rig's own default) there were 49 parts and 49 files saved from the own
     chat, with no click (P1: finding 2).** The baseline, a kinds change and `-auto-mirror-download` do not
     reach it: the mirror refuses a private chat, and the baseline counts the word as not the owner's
     (coder's test 8).
4. **Stopped by everything that stops a read.**
   - **The step** checks frozen and signed out, both in memory and on record, and runs only inside a live
     session's chat list.
   - **The read** is the reader's ordinary read, so it stops when the session ends.
   - **Not probed by me:** the owner's Stop of the account, a pause, Quit, a wait during that read, and
     whether a wait is stored across a restart. These belong to the unchanged reader path; I leave them
     not decided by me.
   - **The catalogue switch does not stop a read under way** (finding 1).
5. **The switch.**
   - Absent means on; "on" and "off" are exact; any other value is unreadable. All of this is tested and
     passed when I re-ran it.
   - Two calls at once leave one row (a primary key; the last write wins).
   - A set during the step's transaction: the single writer orders the two, and the transaction reads the
     switch again.
   - The fixed line is said once, and again only after a good read.
   - Both doors answer `ErrNotRunning` with no catalogue open.
   - Minor: the line says "until it is set anew from a page", but no page control exists yet (pages track).
   - Switched on again, the step acts only at the next chat list, which can take up to `ChatListEvery`
     (24 h). This is documented.
6. **Every reader of `By`.** The coder's table is right where it goes but is not complete. Missing places:
   - **`collector/status.go` 56:** "approved for reading N" counts the step's approval with no word that it
     was by itself (U1: count 1).
   - **`server/notadded.go` `accountReadWord`:** the word is "approved" with no "by itself" word. The
     `By` field exists now; using it is the pages track's work.
   - **`server/reads.go` 182:** the estimate door answers "already" for an approved chat. This is fine.
   - **`mirror_auto.go` 1337 and `mirror/read.go` 114-123:** mirror chats only, never the own chat.

   The mirror never takes the own chat:
   - **The automatic mirror:** `Look` weighs it as Private. This is tested, and I confirmed it in the code.
   - **The owner's "Mirror this chat":** the want door refuses kind `user` with `ErrWantPrivate`. I confirmed
     this by reading the code, not with a probe.

   `setReadEndWrote`'s "unreadable" count cannot be reached, so it cannot mislead a page today.
7. **What a page and a command show.**
   - **Fixed words, nothing of the chat:** `chats` and `-approve-read` use fixed words plus numbers, and the
     two new log lines are constant formats.
   - **`ListChatReads` hands every page an estimate that was never asked:** `Estimate{Requests: 0,
     Messages: 0, At: the approval's second}` (U1, finding 3). The Chats page's `chatwords.js` would print
     "A read was estimated at about 0 requests (today at ...)" where it shows the known words. The mirror's
     approvals have the same form; this is an older precedent.
8. **The cost, said truly.** Measured on the fake (P4):
   - **An empty own chat:** 1 history request at the first start, 0 at a restart.
   - **250 messages with ids from 1:** 3 requests, 0 at a restart.
   - **Nothing repeats at a start** for a chat read to its end.
   - **One cost the report leaves out:** after its read, the own chat has a cursor, so it joins every
     common-box gap read (`reader.go` 741-744). That is one small page per common gap per account, as for
     any read private chat.
   - **The report's claim of 4 requests when ids start higher** was not re-measured by me.
9. **The tests.** I re-ran three by name: `TestSelfReadRun`, `TestSelfReadSwitch` and
   `TestSelfReadRecordThere`. All three passed. Weak spots:
   - **`TestSelfReadOnceRestart`** removes the record by direct SQL *before the first history request*. It
     shows "no second approval", but it avoids the case its comment names, the owner's end of a read. With
     a read under way, the read goes on by its cursor.
   - **`TestSelfReadRun`** pins `NewChatsDownload = false`. Its "no file wanted" holds for the shipped
     default only (P1).
   - **No test shows:** the `-new-chats-download` case; the switch off during a read under way; the
     common-box gap; a wait or an owner's Stop during the own chat's read.

## On the decided cure for finding 1 (where it must sit)

- **Where:** in `readChats`, not in `readTurn`'s loop alone. `readChats` is the one input of all three
  places that read a chat:
  - the topics loop;
  - **the common-box gap** (`readGap`): it reads every private chat with a cursor, and so the own chat after
    its first page;
  - the best-ranked loop.

  Compute a flag there and honour it at the three places where `skipEnded` is called now. Do not drop the
  chat from the list: the gap's `gapNext` index needs the list whole (review K11 finding 1). Do not reuse
  `skipEnded`'s words or its count.
- **What it keys on:** the account's own chat (`SelfChat`) **with no owner's record** (a record with `By ""`
  and `ApprovedAt != 0`), not only "the record carries the word". If the record is removed or cannot be
  parsed, the cursor keeps the read going, and a check on the word alone would miss it (rule 13).
- **What it must not break:** the owner's later yes (`By ""`) leaves the chat outside the switch. The
  owner's estimate keeps the word, which is right: an estimate is not a yes.
- **What the cure gives:** it is read once per turn, so up to `PagesPerTurn` (10) pages can still go after
  an off. The switch covers every account's own chat at once; one account alone cannot be stopped. That is
  acceptable for this piece; say it on the board.

## Findings

1. **Must fix (known, cure decided): the switch off does not stop a read under way, and the owner has no
   other door.**
   - **Shown by:** the code (`readChats` reads `approved || cursor`) and the coder's own report.
   - **Smallest fix:** the cure above: in `readChats`, keyed on the own chat with no owner's record, honoured
     in the gap loop and the turn loop. Add a test: the switch goes off after the first page, and no further
     history request of the own chat follows, through a common-box gap as well.
2. **Must fix, or the owner's explicit OK on the board: under `-new-chats-download` the own chat's history
   files are downloaded with no click.**
   - **Shown by:** probe `TestZZProbeK21NewChatsDownload`. With 250 messages and 50 files, there were 3
     history requests, **49 part requests and 49 files saved**. The own chat's downloads were "" (on, made
     chosen by the flag).
   - **Why it matters:** before K21, a chat made under the flag was never read without the owner's
     approval, so its history files never came. The owner's decision covered the READ only, and the brief
     says "no file is downloaded from that chat unasked". The app's own precedent keeps an automatic read's
     downloads behind a separate flag (`-auto-mirror-download`).
   - **Smallest fix:** in `selfApprove`, inside the transaction, act only while the own chat is switched off
     for downloads (`ChatOffWhy` not `OffNone`). Otherwise write nothing, no record and no mark, and say one
     fixed line once. Add P1 as a test.
3. **Minor (should fix in the same round, cheap): the pages' data shows an estimate never asked.**
   - **Shown by:** probe `TestZZProbeK21PagesEstimate`. `ListChatReads` returns `Estimate{0, 0, at}` for the
     step's record.
   - **Smallest fix:** in `catalog.ListChatReads`, leave `Estimate` nil when `By == ReadBySelf` and the
     estimate's numbers are 0 with `EstimatedAt == ApprovedAt`. The record must keep `EstimatedAt`, because
     `approveRead` needs it for the owner's yes.
4. **Minor (no door today): `catalog.DeleteAccount` leaves the step's mark and record behind, and the
   numbers are reused.**
   - **Shown by:** probe `TestZZProbeK21DeletedAccount`. After the delete and settle, the old mark and
     record are left. The new account got the same account number, its first chat got the same chat
     number, and the step wrote nothing for it. The stale approval then applies to whatever chat the new
     account makes first at that number. The same is true of every read record already; this piece adds one
     the owner never gave.
   - **Smallest fix:** in the delete-account step (`catalog/settle.go` around 491), delete
     `c_settings` keys `collector.read.<N>.%` and `collector.self_read.<N>`.
5. **Minor: gaps in the report and the line.**
   - **The report's `By` table** misses `status.go` 56 and `server/notadded.go`'s word (question 6). Pass
     these to the pages track.
   - **The report's cost** leaves out the common-box gap (question 8).
   - **`selfLineSwitchBad`** names a page control that does not exist yet.
6. **Minor: the tests.** `TestSelfReadOnceRestart` avoids the read-under-way case, and `TestSelfReadRun`
   pins the flag off (question 9). The tests for findings 1 and 2 cover both.

## What I did not look at

- The `internal/collector` package as a whole, and the race detector.
- The click and door tests (the coder reports 76 passed).
- `TestSelfReadOnceRestart`, `TestSelfReadTwoAccounts`, `TestSelfReadNotWhen`, `TestSelfReadMirror` and the
  catalogue tests: read, not re-run.
- `gofmt` and `go vet` of the branch.
- Whether a stated wait is stored across a restart, and the owner's Stop, pause or Quit during the own
  chat's read (question 4).
- The coder's figure of 4 requests for ids that start higher.
- The `telegram` package's handling of the self peer, beyond the fake.
- Whether the owner's real starter uses `-new-chats-download`: not looked at, by the house rules.

may be listed after these fixes: 1, 2
