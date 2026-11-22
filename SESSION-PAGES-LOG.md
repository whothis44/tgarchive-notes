# Pages track: the log (history; nobody needs to read it). Moved from SESSION-PAGES-PROGRESS.md 11-21 22:26.

# Session P (pages and chats): progress

A fresh session takes over from this file alone. Times are from `date`.

## The task
The "Pages and chats" track of `BOARD.md`: the new app's own pages (Chats, Queue, Staging, Settings)
and what they set in the catalogue. Owns `internal/server` and the catalogue's chat and topic settings.
Order: (a) rank a topic and "collect only chosen topics" on the chat's own row; (b) chats not added
yet, with stored counts, an overlap estimate and plain words for why a number is 0; (c) Queue;
(d) Staging. Done for this session: (a), then (b), each on a pushed `wip/pages-*` branch with named
tests passing, listed in `MERGE-QUEUE.md` and on the board, notes committed on `notes`.

## What is already known (written before any brief)
**The owner's spec for the Chats page** (TRIED-BEFORE 10 and 15, LESSONS 6, FEATURES 2):
- One row per chat, in one place, one vocabulary that adds up, each file once: saved (own / through
  another chat) + held as a probable copy (with a link to what it matches) + still needed + other =
  files. The old app had three screens with three vocabularies; a chat with 916 "to go" showed 1
  "still needed".
- Every state says why in plain words, above all why a number is 0. Show the age of the data. No row
  that looks clickable and does nothing; a refused click keeps its message.
- Chats not added yet belong in the same list, with stored counts and an overlap estimate (the owner:
  a critical weak point). A media count chooses what to read first and is never shown as a size
  (TRIED-BEFORE 26: the estimate from counts was wrong by a factor of 4 or more).
- Propose, never queue (LESSONS-ix12.30 6b): the 30 chats the old app added by itself flooded the
  queue (1,571 of 1,575 startable files). What the app adds is marked as the app's, with its real
  name, and no bulk action sweeps it in. Every queue or per-chat action is one indexed statement,
  tested at hundreds of thousands of rows (the old batch Pause was 1,000 scans of 361,378 rows).
- Settings: few, each changes one thing and says what (TRIED-BEFORE 19). A page that shows "next"
  uses the lane's own order.

**Topic ranks in the old app** (TRIED-BEFORE 4 and 15; `wt-v12.31/core-service/internal/app/ix_topic_rank.go`,
the card "Topics that go first" in `ixassets/ix.html` lines 986 to 1018):
- From 12.15 a topic had a place of its own on the ranking; it set its files' order correctly.
- 12.17 tried to move a ranked topic's group up the rescan lanes and into the rescan: **dropped**
  (it read a whole group's messages for one topic). The owner's rule: a rank or a click never causes
  a Telegram read without the cost shown and an OK.
- Measured 11-07: two of five ranked topics had nothing queued and the page showed 0 without a
  reason; the others' waiting files were all held copies. So the row must say why a number is 0.
- It lived in a second card with a search box, apart from the chat's row: the owner wants one place,
  on the chat's own row.

**What the new app has today** (read at head e3a9df9):
- `topic.rank` exists (schema 4); `Catalog.SetTopicRank` (`rows.go` 373) stores it and settles in
  chunks (`settleRankTopic`); a file takes the best of its chats' and topics' ranks (`bestRankSQL`).
  Nothing calls `SetTopicRank`: no route, no page, no list of a chat's topics with counts.
- No "only chosen topics" setting exists. What a chat collects is decided when a file is first
  catalogued (`chatWants` in `ladder.go` 286; `collectsSQL`): a kind the chat does not collect is
  held with `ReasonChatPref`, not supplied, and `wantedAsMain` wants it again when another chat that
  collects it carries it. Kinds and `collect_off` apply only to files catalogued from then on.
- The Chats page (`server/chats.go`, `web/assets/js/pages/chats.js`): one row per chat, saved +
  through other chats + held + wanted + other = files; ranks with ties, drag, bulk rank, a stale-page
  check. `ChatCoverages` walks every message and attachment per load: not measured at the old
  archive's size.

## Design for piece (a), not briefed yet (mine; a fresh session should check it against the code)
- Schema step (next free on the board was 15; **not taken yet**: write it on the board first):
  `chat.topics_only INT NOT NULL DEFAULT 0` and `topic.chosen INT NOT NULL DEFAULT 0`.
- A message's file in a `topics_only` chat is collected only if its topic is chosen: one more
  condition in `chatWants` and `collectsSQL` (the topic passed in). Not collected: held with a fixed
  reason of its own ("this chat collects only chosen topics"), never skipped.
- Unlike the kinds, it must act on files already catalogued, both ways, as a settle action in chunks
  by `message(topic_id)` (index `message_topic` exists): choosing a topic wants its held files
  again (as `wantedAsMain` does); un-choosing holds only files still `wanted` that no other
  collecting chat or chosen topic carries. Active and saved files are left alone.
- Routes: `GET /api/chats/topics?chat=` (topics with files, saved, held, wanted, other, each file
  once, and a reason in plain words when wanted is 0), `POST /api/chats/topic-rank`,
  `POST /api/chats/topics-only`, `POST /api/chats/topic-chosen`. Page: a forum's row opens in place
  to its topics. No request to Telegram from any of it.
- Tests: named tests for the settle action at 200,000 messages; the counts adding up.
- `lane.go`, `state.go` tier 5 and the hold tables are the copies session's: the new hold reason
  must not touch them; say so in the brief and on the board.

## State (newest last)
- 11-14 23:33: started. Board row claimed.
- 11-14 about 23:50: the history read in full by this session (FEATURES all sections; ROADMAP;
  TRIED-BEFORE 3, 4, 10, 15, 17, 19, 26; LESSONS 6; `LESSONS-ix12.30-live.md` 6b; the memory note
  `viewer-feedback-1109`). Code read: `server/chats.go`, `chats.js`, `catalog/rows.go`, `schema4.go`,
  `schema9.go`, `tgchats.go`, `settle.go` (to line 380), `stats.go` coverage, `ladder.go` attach.
  The old app's `ix_topic_rank.go` was located, not read line by line yet.
- **Stopped here: the usage limit was reached.** Nothing briefed, no coder, no copy, no branch, no
  schema number taken, nothing in `repo-archiver` changed. "Collect only chosen topics" already has
  a roadmap row (the integrator added it in e3a9df9), so no message to the integrator is owed.
- **Next step:** read `wt-v12.31/core-service/internal/app/ix_topic_rank.go` in full, take schema
  number 15 on the board, write `BRIEF-P1-topics.md` from the design above, measure free memory and
  CPU, then start an Opus 5.5 coder in `wt-pages-topics` (`wip/pages-topics`, from the head of
  `claude/charming-feynman-vm2xia`).
- 11-15 08:48: **resumed** (the owner: "Try again"). The board read again: the viewer merge landed, the
  main branch is at 4f1992e; schema 15 went to the copies session at 08:45, so **16 is taken for this
  piece** (written on the board). `ix_topic_rank.go` read in full. **Brief written:
  `BRIEF-P1-topics.md`.** Copy made: `wt-pages-topics`, branch `wip/pages-topics`, from 4f1992e (nothing
  committed on it yet, not pushed). PC before the coder: 10.6 GB free, CPU 23%.
  An Opus 5.5 coder (high effort) is started on the brief as a background agent of this session.
  **Next step:** when it hands back: read the risky part myself (the chunk statements in `topics.go`,
  the `attach` change, the oracle test), run its named tests once, then an independent read-only
  review, its fixes, the whole tests of `internal/server` and `internal/catalog` once, then
  `MERGE-QUEUE.md` and the board. If this session stops first: the branch `wip/pages-topics` on
  `private` holds whatever the coder committed; a fresh session reads its log and carries on from the
  brief. Then piece (b): chats not added yet (not briefed).
- 11-15 08:48: while the coder builds (a), **piece (b) is briefed: `BRIEF-P2-chats-not-added.md`**
  (not started: it edits the same files as (a), so it starts on (a)'s head after the hand-back).
  What I found for it: in the new app a chat is "added" once a read is approved (the setting
  `collector.read.<account>.<chat>`) or has a cursor; nothing stores media counts, and the only
  overlap fact available without a read is the archive's own forwards from that chat
  (`message.fwd_origin`, indexed). No size is shown from a count (TRIED-BEFORE 26). A button that
  approves a read from the page is left out: the approval is the collector's record (core track, no
  session); to raise with the integrator on the board.
  The coder for (a) is still running in `wt-pages-topics`; check `git -C wt-pages-topics log --oneline`
  and `private/wip/pages-topics` for what it has pushed.
- 11-15 08:58: the owner's rule "who reports to whom" read (board and `CLAUDE.md`): this session reports
  to the integrator through the board row, this file and `MERGE-QUEUE.md`; questions under the board's
  "Messages" (one written: who builds the collector's side of approving a read from the page; the
  `ladder.go` and `ChatCoverage` touch points). The session that started this one is detached.
- 11-15 09:11: **the coder handed back piece (a)**: `wip/pages-topics` head 5b57467, five commits on
  4f1992e, pushed to `private`, tree clean. Its named tests passed by its report (catalogue `-run TestTopic`,
  server `-run TestTopic`); the size test at 200,000 messages: longest chunk 58 ms, a switch 5 to 7 s in
  about 200 chunks, `TopicCoverages` 0.67 to 0.81 s. On its branch the step is number 13 (two constants
  in `schema_topics.go`); the board has it as 16. Not yet done: my own read of the risky part, the
  independent review, the whole tests. **Next step:** read `topics.go`, the `ladder.go` diff and the
  `settle.go` diff myself; then the review; then fixes; then whole tests of `internal/catalog` and
  `internal/server` once; then `MERGE-QUEUE.md`.
- 11-15 09:12: I read the risky part of (a) myself (`topics.go`, `schema_topics.go`, the `ladder.go` and
  `settle.go` diffs) and ran its named tests once (catalogue `TestTopic` short 3.3 s, server
  `TestTopic|TestChat` 1.7 s, both pass; gofmt clean). Found sound: the hold is never a skip; active,
  aside, saved, kept-held untouched; chunks by `message_topic` and the space's key. Open points I gave
  the reviewer: a topic action also releases files held for their kind when a carrier now collects
  them; an edit that moves a message to another topic is not judged again; a cancelled request leaves
  the intent for the next Settle (who runs it when only the app runs?); a switch on 200,000 files takes
  5 to 7 s inside one request. **An independent read-only review (Opus) is running** as a background
  agent of this session, on 5b57467. **Next step:** its findings to the coder as fixes (same copy,
  same branch), then whole tests of `internal/catalog` and `internal/server` once, then
  `MERGE-QUEUE.md`. Piece (b) starts on the fixed head.

## How to open piece (a) on invented data (for the owner; nothing real is touched)
The coder left a built program and an invented archive in this session's scratch folder (a reboot may
clear it; then build `archiver/cmd/tgarchive` from `wt-pages-topics` and run `fabricate` again):
```
C:\Users\trabi\AppData\Local\Temp\claude\71f159c3a9e5d4b9\2859fa9c-25e5-415d-a210-fa8d7d19cca3\scratchpad\topics-demo\tgarchive.exe fabricate -db C:\Users\trabi\AppData\Local\Temp\claude\71f159c3a9e5d4b9\2859fa9c-25e5-415d-a210-fa8d7d19cca3\scratchpad\topics-demo\owner.sqlite -seed 3 -chats 12 -messages 2000
C:\Users\trabi\AppData\Local\Temp\claude\71f159c3a9e5d4b9\2859fa9c-25e5-415d-a210-fa8d7d19cca3\scratchpad\topics-demo\tgarchive.exe app -db C:\Users\trabi\AppData\Local\Temp\claude\71f159c3a9e5d4b9\2859fa9c-25e5-415d-a210-fa8d7d19cca3\scratchpad\topics-demo\owner.sqlite -library C:\Users\trabi\AppData\Local\Temp\claude\71f159c3a9e5d4b9\2859fa9c-25e5-415d-a210-fa8d7d19cca3\scratchpad\topics-demo\library -open
```
On the Chats page the forum "Kettle & Kiln Makers Forum" has a "Topics (6)" button. With `-demo` added
the switches refuse ("Demo: nothing is saved"); without it they save into that invented copy only.
- 11-15 09:23: **the independent review of (a) is back** (read-only, on 5b57467; its two named runs pass).
  No blocker; five "should fix before merge" and eight minor. I checked three in the code myself and
  accept them: (S1) a forum's General topic has no topic header, so its messages are "no topic" and
  could never be chosen; (S2) a message moved to another topic by an edit was not judged again;
  (S3) switching on a chat already on chose ranked topics again and left an intent unsettled; (S4) an
  answer's counts could include another action's files; (S5) a cancelled request left the action
  half-applied with nothing to finish it while only the app runs. Minor ones taken: an owner's release
  not undone by a topic action, the right reason after "wanted again", probable-only flips counted,
  un-choosing a ranked topic refused, exact skips counted as saved in a topic row, the schema test
  free of the step's number. Left and written down: files in transfer or set aside when their topic
  is un-chosen; "always download" un-skips. **Fix brief: `BRIEF-P1b-topics-review-fixes.md`; sent to
  the same coder (same copy and branch).** One file outside my packages is touched by it:
  `catalog/staging.go` (one reason word in `WantAgain`) and `catalog/tgrows.go` (the edit path):
  to say in the merge queue. **Next step:** on its hand-back read the General and edit fixes, then the
  whole tests of `internal/catalog` and `internal/server` once (no race run: no new goroutine), then
  `MERGE-QUEUE.md`.
- 11-15 09:39: **the coder handed back the review's fixes**: `wip/pages-topics` head 8fbb765, pushed, tree
  clean (5 commits on 5b57467). By its report all of S1 to S5 and M1, M2, M3, M5, M6, M8 are done and
  the brief's final named runs pass (catalogue 61 s, server 3 s). One thing beyond the brief: a file
  is judged once per action (the chunk keeps only files whose first carrier in the scope is in the
  chunk), which took the many-carriers case from 39 s to 2.6 s. `cmd/tgarchive/app.go` now settles a
  pending owner action at start. **Next step:** I read that query, the General rule and the edit
  path; then whole tests of `internal/catalog` and `internal/server` once; then `MERGE-QUEUE.md`.
- 11-15 09:40: I read the fixes' risky part (the General rule in `topicPassSQL`, the edit path's
  `rejudgeMessage`, the "once per action" file query, the start-up settle in `cmd/tgarchive/app.go`):
  accepted. One limit to write in the merge queue: the "first carrier in the scope" test walks a
  file's earlier carriers outside the scope, so a file carried tens of thousands of times elsewhere
  can make one chunk hold the writer for about a second. **The whole tests are running now, once, in
  the background of this session** (Windows `go test`, `internal/catalog` with 4 threads and
  `internal/server` + `cmd/tgarchive` with 3; the PC was at 78% CPU and 10.3 GB free before; no race
  run: no new goroutine). Output: this session's scratch folder, `full-catalog.txt` and
  `full-server.txt`. **Next step:** if both pass, write the `MERGE-QUEUE.md` entry and the board, then
  start the coder on (b) in `wt-pages-notadded` from 8fbb765. If this session stops: run the two
  whole tests again on 8fbb765 and carry on from there.
- 11-15 09:45: **piece (a) is listed for the integrator.** Whole tests on 8fbb765, once: `internal/catalog`
  270 s, `internal/server` 7 s, both pass; gofmt and vet clean. `MERGE-QUEUE.md` has the entry (schema
  16, carried as 13; the files outside this track; no race run due); the board row and the unbuilt
  list say so. Not done for (a): the owner has not opened it. **Piece (b) started:** copy
  `wt-pages-notadded`, branch `wip/pages-notadded` from 8fbb765, an Opus coder as a background agent on
  `BRIEF-P2-chats-not-added.md`. **Next step:** on its hand-back read the two statements and the
  page's words, one review, fixes, whole tests of `internal/server` (and `internal/catalog` if it
  changed) once, then the merge queue.
- 11-15 10:05: **the coder handed back piece (b)**: `wip/pages-notadded` head b06df4c (6 commits on
  8fbb765), pushed, in `wt-pages-notadded`. No schema step, no goroutine. By its report: named tests
  pass; at 300,000 messages the chats' counts take 1.6 to 1.9 s, so the server keeps them between
  loads (worked out again when the change log moved and 5 s passed, or after a change through the
  server); the forwards fact 0.13 to 0.22 s per load. **Concurrent code changed in `internal/server`**
  (`handleChats` takes the server's lock; an atomic flag set by every write request): a race run of
  `internal/server` is due before the merge (a small package). It edited `cmd/tgarchive/fabricate.go`
  (one line) and `internal/fabricate` (opt-in read states). **Next step:** I read `chatreads.go` and
  `notadded.go`; one independent review; fixes; whole tests of `internal/server` and
  `internal/catalog` and the race detector on `internal/server` once; the merge queue.
- 11-15 10:06: I read (b)'s risky part (`notadded.go`: the kept counts under the server's lock, the
  why sentences; `chatreads.go`: the read facts in one statement, the forwards by a range of
  `message_fwd_origin`; the guard's flag). Nothing wrong found by reading; open points given to the
  reviewer: is "nothing changed: the counts hold now" true (does every change the counts depend on
  move the change log); a page load holds the server's lock for about 2 s; the settings key copied
  from the collector. **An independent read-only review (Opus) of b06df4c is running** as a background
  agent of this session. **Next step:** its findings as a fix brief to the coder of (b) (same copy and
  branch), then once: whole tests of `internal/server` and `internal/catalog`, the race detector on
  `internal/server` only (handlers share the kept counts), then the merge queue.
- 11-15 10:17: **the independent review of (b) is back** (read-only, b06df4c; its two named runs pass; no
  blocker). Four fixes before the merge, accepted: (S1) a Chats load waited behind every write route,
  a long import included: a lock of its own for the kept counts; (S2) forwards from a supergroup or
  forum name their sender, not the group, so "no file was forwarded from it" was false for them:
  the forwards fact is for channels only, and a group says why it cannot be counted; (S3) a removed
  account's old cursor made a chat look "being read"; (S4) the not-read cell at phone width. Smaller
  ones taken: two changes that did not move the change log, the sentence for alternative versions, a
  mirror's sentence, the whole command and honest words around it (it starts the collector), every
  chat in one filter group, a `-reads` flag so the viewer track's invented archive is unchanged.
  Checked sound by the reviewer: the settings key and record equal the collector's; the forwards
  range is exact; the kept counts cannot give a stale hit from a race. **Fix brief:
  `BRIEF-P2b-notadded-review-fixes.md`; sent to (b)'s coder (same copy and branch).** **Next step:**
  on its hand-back, once: whole tests of `internal/catalog` and `internal/server`, the race detector
  on `internal/server` only, then the merge queue (after entry 8, on which it is built).
- 11-15 10:26: **(b)'s coder handed back the review's fixes**: `wip/pages-notadded` head f350757, pushed,
  tree clean. By its report all four must-fix and eight should-fix are done; its final runs pass
  (`internal/server` whole 6.9 s, `internal/fabricate` 16 s, catalogue named 8 s). **Next step:** I read
  the lock change; then once, side by side: whole tests of `internal/catalog` and `internal/server`,
  and the race detector on `internal/server` only (page loads share the kept counts); then the merge
  queue entry after entry 8.
- 11-15 10:26: the lock change read (a lock of its own for the kept counts; a load never takes the
  write lock). **The full runs of (b) are running now, once, in the background of this session**:
  `ix-tools/full-runs.sh wt-pages-notadded runs-pages-b "catalog server fabricate" "server"` (whole
  Windows tests of the three packages; the race detector on `internal/server` in one Docker
  container). The PC before: 8.8 GB free, CPU 54%. Results land in `runs-pages-b/` in the project
  folder (`win-*.log`, `race-server.log`, each ending in "exit N"). **Next step:** if all end in exit 0
  and gofmt's log is empty: the `MERGE-QUEUE.md` entry for `wip/pages-notadded` f350757 (after entry
  8), the board, then (c) the Queue page is next in this track's order (not briefed).
- 11-15 10:32: **piece (b) is listed for the integrator.** Full runs on f350757, once: whole tests
  `internal/catalog` 274 s, `internal/server` 7 s, `internal/fabricate` 13 s; the race detector on
  `internal/server` 74 s with no race; gofmt clean. `MERGE-QUEUE.md` has its entry, after entry 8 on
  which it is built; the board row and the unbuilt list say so. **Both pieces of this session's task
  are on pushed branches and listed. Neither is done until the owner has opened it.**
  **Next step for a fresh session:** (c) the Queue page (roadmap D2: downloading now, just finished,
  failed with reasons): read `internal/server/queue.go`, `queue.js`, TRIED-BEFORE 19 ("the queue list
  jumped": list in the lane's own order) and FEATURES section 1 rows 3, 4 and 9, write its "what is
  already known" note and brief, cut the copy from whichever of these two branches has merged.

## How to open piece (b) on invented data (for the owner; nothing real is touched)
Built program and archive are in this session's scratch folder (a reboot may clear it; then build
`archiver/cmd/tgarchive` from `wt-pages-notadded`). The topics of piece (a) are on the same page.
```
set S=C:\Users\trabi\AppData\Local\Temp\claude\71f159c3a9e5d4b9\2859fa9c-25e5-415d-a210-fa8d7d19cca3\scratchpad\p2demo
%S%\tgarchive.exe app -demo -db %S%\catalogue.sqlite -library %S%\library -addr 127.0.0.1:8797
```
Then open http://127.0.0.1:8797/#/chats and pick "Read: Not added yet". To make the archive afresh
(on a new file name): `%S%\tgarchive.exe fabricate -db %S%\catalogue2.sqlite -accounts 2 -seed 7 -reads`.

## Session P2 (took over 11-15 15:26; the task: G1, board message 26)
The owner, 11-15 15:15: "Remember we want a functional app, with a GUI." G1: `tgarchive-collector run`
serves the app's pages itself and fills `Live`; a starter the owner double-clicks; then Queue (D2),
sign-in page (D1), a mirror step from the page (E1), Staging (D4). Done for G1 means the owner has
double-clicked the starter, seen the real test catalogue's chats and queue, and started and stopped
collecting from the page.
- 11-15 15:26: started. Board and this file read; both of session P's branches are merged (b379286,
  d4a50e2); the main head is f0e3f0c (schema 17). `wip/mirror-auto` and `wip/core-chosen` (both at
  c599ac5 in their copies) are not merged: G1 is cut after they merge, or prepared meanwhile. Board
  row claimed. Nothing briefed, no coder, no copy, no branch. **Next step:** the history in full
  (the files `CLAUDE.md` names), then `cmd/tgarchive/app.go`, `internal/server`, `cmd/tgarchive-collector`,
  `internal/collector`, then the note and `BRIEF-G1-one-program.md`.
- 11-15 15:27: the history read in full by this session, myself: TRIED-BEFORE (all 28), LESSONS,
  WINDOW-EVIDENCE, COPY-CHECKS-STUDY, TELEGRAM-FACTS, LESSONS-ix12.29-servers, LESSONS-ix12.30-live,
  LESSONS-viewer-ix12.32, ANSWERS 4 to 9, FEATURES, ROADMAP, HANDOFF 0c, BRIEF-K1. **Next step:** read
  the code (cmd/tgarchive/app.go, internal/server live.go, server.go, demo.go, overview.go, queue.go,
  chats.go, notadded.go; cmd/tgarchive-collector; internal/collector collector.go, command.go,
  account.go, reader.go, status.go, approve_cmd.go; the a3 start scripts), then the note and the brief.
- 11-15 15:34: the code read by me (cmd/tgarchive/app.go; server: server.go, live.go, queue.go,
  accounts.go, notadded.go, overview.go to line 200, the handlers of settings, importer, chats, topics by
  name; collector: command.go, collector.go, account.go to 470 and 770-850, reader.go to 260,
  approve_cmd.go, signin.go to 260, status.go, lock.go; engine LaneStats; the a3 start script's flags).
  **What I found:** the collector already has the calls a page needs (`Accounts`, `LaneStats`,
  `EstimateRead`, `ApproveRead`, `BeginSignIn`/`SubmitCode`/`SubmitPassword`, `AllowIdle`, a `ready`
  signal); it has no accessor for its catalogue, no owner's stop per account, and its lock file is another
  than the pages' (so today `tgarchive app` and `run` can both write one catalogue). No page control
  switches a chat on or off (`SetChatCollect` is called by nothing in the server). The server's `s.fail`
  logs an error's text as it is (must not reach the collector's log). The overview's 2 s timer asks
  `/api/overview`, which reads totals and 48 hours of rows each time.
  **Brief written: `BRIEF-G1-one-program.md`** (the "what the old app already knows" note is its second
  section). Design decisions, mine: `run -pages` binds first and shows "Starting"; the pages stop before the
  collector; the owner's Stop ends the account's whole session and is on record (one settings row per
  account, fail closed, only Start clears it, never two dials inside the redial pause); `/api/live` reads no
  table; the library folder, an import and removing an account are refused while collecting; estimate (1
  request, on a button that says so) then approve with the N shown; Quit; a `TestPagesHold` so the pages can
  be opened in a browser over the fake Telegram. Board: my row, message 27 (what G1 meets, the race run, the
  install), item 14 for the owner (Start and Stop as built: recommended as written).
  Not committed in repo-archiver: nothing yet. **Next step:** measure the PC (15:31: 3.8 GB free, CPU 43%),
  make the copy `wt-pages-g1` (`git -C repo-archiver worktree add ../wt-pages-g1 -b wip/pages-g1 f0e3f0c`),
  start one Opus coder (high effort) on the brief as a background agent of this session. While it builds:
  the note and brief for the Queue page (D2), and the starter `app\tgarchive.cmd` (after the flags exist).
- 11-15 15:35: **the G1 coder is started** (one Opus agent at high effort, a background agent of
  this session) in `wt-pages-g1` on `wip/pages-g1` (from f0e3f0c; nothing committed on it yet). The PC
  before: 4.6 GB free, CPU 44%. It pushes work in progress to `private/wip/pages-g1` and keeps
  `archiver/docs/progress/pages-g1-PROGRESS.md` in its copy. **If this session stops:** read that file and
  `git -C wt-pages-g1 log --oneline f0e3f0c..`, then start a new coder on the same brief from where it is.
  **Next step (mine, meanwhile):** the note and the brief for the Queue page (D2); then the starter.
- 11-15 15:36: while G1's coder builds: **the Queue page is briefed: `BRIEF-G2-queue-now.md`** (roadmap
  D2, with the `held_wait` switch; the old app's Downloads card read in `wt-v12.31` `ix.html` 340-392 and
  its numbers on retries in the brief). Not started: it is cut from G1's head after the hand-back (same
  files: `queue.go`, `queue.js`, the live seam). **Next step:** wait for G1's coder; on its hand-back read
  `account.go`'s diff, the new stop file, `command.go`'s start and stop of the pages and the route table
  myself; then open `TestPagesHold` in the browser; then the independent review.
- 11-15 15:38: **the starter is drafted, untried:** `app\tgarchive.cmd` and `app\tgarchive.ps1` (the folder
  is not tracked, like `a3` and `b`; it parses). It starts the installed collector hidden with the test
  account's folders and `a3-start.ps1`'s own flags plus `-pages`, refuses in a message box when the
  installed build has no `-pages`, starts the viewer program on the same catalogue when it is installed
  (`-viewer-url`), waits for the page, opens it, stays until Quit and then stops that viewer. A second
  double-click only opens the page. Not handled yet: the viewer program lying in the Claude app's package
  folder (`b-viewer.ps1` lines 17-24 show how). **For G1's fix round (not in the brief):** the page shows the
  viewer's link only when something answers at its address (a look from the server at 127.0.0.1, at most
  every 10 s), else "the viewer is not running"; the viewer's build must be of the same schema as the
  collector's (the viewer track builds it).
- 11-15 15:39: **the sign-in page is briefed: `BRIEF-G3-signin-page.md`** (roadmap D1; the console
  command's rules kept; an account added while the program runs is the one new thing in the collector's
  loop, for the review and the race run). Not started: after G1. It and G2 touch different files
  (`accounts.*` and the seam against `queue.*`), so two coders can run side by side on G1's head when memory
  allows. Not briefed yet: the mirror step from the page (E1: read `mirror_cmd.go`'s plan and the
  mirror-auto branch's command first) and the Staging page (D4: the store's ledger, `StoreHour`).
  **Waiting now for G1's coder** (a background agent of this session; `git -C wt-pages-g1 log --oneline f0e3f0c..`).
- 11-15 15:40: **the Staging page is briefed: `BRIEF-G5-staging-page.md`** (roadmap D4; the store's
  gauges and hours exist, `ReleaseWantAgain` is the one action; the old app's copy numbers in the brief).
  Not started; last in the order. G4 (a mirror step from the page) is not briefed: it waits for
  `wip/mirror-auto` on the main branch (its command changes). G1's coder has one commit so far (1b3026e: the
  side item, message 17's test). **Waiting for G1's coder.**
- 11-15 16:34: **G1's coder handed back**: `wip/pages-g1` head 023c048 (12 commits on f0e3f0c), pushed to
  `private`, tree clean. Its report: `wt-pages-g1/archiver/docs/progress/pages-g1-REPORT.md`. By its word:
  every section built, the named tests pass (the 16 collector ones run 3 times each), 9 mutations each
  failed its test; `/api/live` 0 statements; a Stop with about 20 files in transfer reached "stopped by you"
  in under a quarter second of wall time. **Not verified by it:** nothing against Telegram; in a browser
  only the Overview and the Chats estimate buttons; no race detector; no whole run of the collector or the
  catalogue. **Its departures:** the collector imports the adapter package (not the other way: a cycle);
  the "stop begun" flag and the test fault switch are package-level variables outside `collector.go`; one
  field added to the account struct; the redial pause also delays `ClearFrozen` and sign-in restarts by the
  rest of 5 s; an estimate answers within 30 s with "still asked" and carries on in the background (the
  reader serves calls between its turns: about 90 s on the fake); four settings are read by nothing in the
  new app and say so. The main branch moved meanwhile to 9d187d3 (E9); `wip/mirror-auto` and
  `wip/core-chosen` are not merged yet. **Next step:** my own read of `account.go`'s diff, `ownerstop.go`,
  `pages.go`, `pages_cmd.go`, `command.go`'s diff and the route table; then the hold in a browser; then
  the independent review.
- 11-15 16:40: **my own read of G1 and the browser pass are done.** Read: `account.go`'s and `command.go`'s
  diffs, `ownerstop.go`, `pages.go`, the report. Sound by reading: Stop goes through the session's own
  `signal`; the row is read at the top of every turn and an unreadable or corrupt one counts as stopped;
  a Stop during a dial closes the connection; a Stop while the session is being made is caught by a
  watcher; the pages stop (gate, 3 s, cancel, wait) before the collector's context ends. Browser, over
  `TestPagesHold` on 127.0.0.1:8791 (fake Telegram, invented data), no console error: Overview, Stop and
  Start of one account, estimate then approve (the chat was read and saved), the collect switch, Queue,
  Accounts, Settings, Import, Quit (the test ended PASS). Not seen in a browser: the starting page, topics,
  a drag, a narrow window. **15 fixes of mine: `BRIEF-G1b-fixes.md` parts A and B** (the Stop must not grow
  the failure pause; no package-level state; signed-in from the record; three sentences false in the
  program; controls nothing reads are not offered; the Chats page asks again by itself; the viewer's link
  only when it answers; and smaller ones). **The independent review is running** (an Opus agent of this
  session, read-only, on 023c048; brief `BRIEF-G1-review.md`; it writes `REVIEW-G1-pages.md`). The main
  branch is at 9d187d3; `wip/mirror-auto` (464e840) and `wip/core-chosen` (951eb55) are still unmerged.
  **Next step:** the review's findings into part C of the fix brief, send it to G1's coder (the same agent
  can be continued, or a new one on the brief), then merge the then-head into `wip/pages-g1`, the full runs
  once (said to the owner first: whole tests of server, livepages, collector, catalog; the race detector on
  server, livepages and the whole collector, over 30 minutes, because the account loop gains a state and an
  ending signalled from the pages' goroutines), then `MERGE-QUEUE.md`. G2 and G3 start on the fixed head.
- 11-15 16:54: **the independent review of G1 is back: `REVIEW-G1-pages.md`** (read-only on 023c048, two
  probe tests through `-overlay`): 1 must fix, 6 should fix, 9 minor; no finding against the guard, the poll,
  the stop order, the log or the scripts' markup. Must fix (confirmed by a probe): the header's Start (every
  account) starts an account the owner stopped and then marked removed: it dials and sends. Should: the
  pages' stop is unbounded after its 3 s (a client that stops reading; handlers on contexts that cannot be
  cancelled); import and removal allowed while a stopped account's session still shuts down; the Overview's
  "as of now" over an hour's bars that may be stale; another account's estimate offered for approval; the
  failed-pages case; an owner's Stop can swallow a sign-out (I checked: the session's end channel holds 4
  and `runSession` reads the first). I accept all of it. **`BRIEF-G1b-fixes.md` now has part C** (and one more:
  `tgarchive app` refuses while a collector holds the catalogue, since it runs `RecoverActive`).
  **A fresh Opus coder (high effort) is started on the fix brief**, a background agent of this session, in
  `wt-pages-g1` on `wip/pages-g1` (from 023c048). The PC before: 5.6 GB free. The main branch is at a0baa06
  (E8); `wip/mirror-auto` is in the merge queue (M4, 464e840); `wip/core-chosen` is in its review's fixes
  (52108cf). **Next step:** on the hand-back read the Stop's lock, the removed check and the stop's bounds;
  open the hold again in the browser for part B; merge the then-head in; say the full runs' plan; run them.
- 11-15 17:25: **the owner decided item 14** (the integrator's message, board message 30, read on the
  board): Start and Stop as written, "as long as we have a pause button, or a pause for X hours button
  (since the user may wish to have faster downloads/viewing on their personal device, and the app could
  exhaust the telegram fast quote)". Item 17: the integrator installs G1's build after its merge. The main
  head is 4f0fe17; M4 (`wip/mirror-auto`) is in a fix round with a new mirror session; K1 then G1 merge
  after it. **The pause is briefed: `BRIEF-G1c-pause-downloads.md`**: downloads only, per account, on record
  with its end (1, 2, 4, 8 hours or until resumed), through the engine's existing stop inside a running
  session (`engineTask`), the refresher unreachable meanwhile; nothing but its time or "Resume now" ends it.
  **Placed in G1's own branch**, after the fix round, with its own short independent review, before the
  full runs. The fix round's coder is still running (started 16:53). **Next step:** on the fix round's
  hand-back: read it, then start the pause's coder on the same branch; browser pass of both; the pause's
  review; merge the then-head in; the full runs.
- 11-15 17:37: **the fix round is handed back**: `wip/pages-g1` head 0b1d3ee, pushed, tree clean. By its
  report every item of A, B and C is done with a named test (minor 4 left as agreed; B.3 and B.9 by
  script only), five mutations each failed their test, the first coder's tests pass again by name; an
  overview working-out at 300,000 files: 10 statements, 191 to 234 ms; the queue 76 statements, 188 to 247
  ms (floor stays 5 s; close to the line). Departures: a Stop during a dial says "stopping" until the dial
  returns; a settle cut short answers 500 with the cancelled words; Stop of every account still includes a
  removed one; `tgarchive app` holds the collector's lock during its start-up. Not verified by it: no
  browser, no race detector, no whole run. **Next step:** my read of `ownerstop.go` and the pages' stop, then
  the pause's coder on the same branch.
- 11-15 17:38: **the fix round read by me** (`ownerstop.go` whole, the pages' stop, the one line in
  `account.go`): the Stop's writers share one lock (the loop's read-then-set included); a removed account
  counts as stopped at the top of every turn and "every account" leaves it out; after an owner's Stop the
  ended session's end channel is drained for a sign-out or a freeze; "stopping" is decided from the mark
  and the session or dial flags; the pages' stop is 3 s, then connections closed, then 10 s, then on.
  Nothing wrong found by reading. **The pause's coder is started** (a fresh Opus agent, high effort, a
  background agent of this session) on `BRIEF-G1c-pause-downloads.md`, in `wt-pages-g1` on `wip/pages-g1`
  from 0b1d3ee. For my second browser pass a detached copy `wt-pages-g1-look` at 0b1d3ee runs
  `TestPagesHold` on 127.0.0.1:8792 (remove the copy afterwards: `git -C repo-archiver worktree remove ../wt-pages-g1-look`).
  The main head is d1af260. PC before: 3.7 GB free, CPU 38%.
- 11-15 17:41: **second browser pass, on the fix round's head: the pages did not load at all at 0b1d3ee.**
  The browser's console: "Identifier 'outcomeWords' has already been declared": `main.js` imports it from
  `words.js` and declares it again; the module does not parse, every page is empty. No Go test and no
  `node --check` saw it (lesson: a browser pass after every round that touches the scripts; a guard test
  on imported against declared names). **Told to the pause's coder as its first commit** (the fix and the
  guard test `TestScriptsNoDuplicateOrMissingNames`). With the duplicate removed in my look-only copy the
  pass went through, no console error: the pill follows the verdict; "stopping" at once after Stop; the
  Collect column and the kinds' words; the Chats footer and the Overview's sentence true; settings nothing
  reads shown as facts; the library as a fact; Import off with its sentence while collecting; Accounts'
  dash for no date; Quit says "closed from this page at HH:MM:SS". Five small page faults sent to the
  pause's coder too (doubled words in two places; the "Open viewer" link with no address; the Chats page
  wider than an 800 px window; buttons live after Quit). Not seen: the starting page, the failed-pages
  page, topics, the estimate with two accounts. The look copy is back at 0b1d3ee, clean.
  **Next step:** wait for the pause's coder; read its `account.go` lines and its file; a third browser
  pass (pause, resume, the five faults); the pause's short independent review; then the merge of the head.
- 11-15 18:19: **the pause's coder handed back**: `wip/pages-g1` head 0ee2c00 (9 commits on 0b1d3ee), pushed,
  tree clean. First two commits: the duplicated script name removed with the guard test
  `TestScriptsNoDuplicateOrMissingNames` (every script also parsed as a module with node 22: all pass), and
  my five page faults. The pause: `collector/pausedl.go` (one row per account, "began,until"; one writers'
  lock; unreadable counts as paused); the engine task asks it at the top of every turn (8 lines in
  `account.go`, `runSession` untouched): paused: `stopEngine`, lanes forgotten, the refresher out of the
  supply's reach; nothing but its time or Resume ends it; `POST /api/pause` (1, 2, 4, 8 hours or until
  resumed) and `/api/resume`; the header's menu, the words with the time left, Overview, Accounts, Queue.
  By its report 13 new collector tests pass twice, 5 mutations each failed their test, the owner-Stop and
  pages tests pass again by name; from the click to the pause holding 1.4 to 4.5 s of the clock; it clicked
  through pause, pause all and Resume in a browser at 800 px. Departures: the refresher is taken out at the
  engine task's first turn, not in `runSession`; an ended pause's row is kept; accounts with different ends
  give a verdict without a time. Not verified: Telegram, the race detector, whole runs.
  **Next step:** my read of `pausedl.go` and the 8 lines; the pause's short independent review; a third
  browser pass by me.
- 11-15 18:21: **the pause read by me and clicked through.** Read: `pausedl.go` whole and the 8 lines in
  `account.go`: the engine task is the only goroutine that starts and stops the engine and asks the pause
  at the top of each turn; the first paused turn calls `stopEngine`, forgets the lanes and takes the
  refresher out of the supply's mux; the record is read once a run and then memory; one writers' lock;
  unreadable or not understood counts as paused. Nothing wrong found by reading. **Third browser pass** on
  the look copy at 0ee2c00 (127.0.0.1:8794, fake Telegram, invented data, no console error): the pages load;
  "Pause downloads" for 1 hour from the header paused both accounts ("Downloads paused until 19:20 (1 h
  left)", pill "Downloads paused", each account's sentence in place of its lanes); the Queue says nothing
  is taken meanwhile; "Resume now" brought the lanes back within 5 s; "until I resume" for one account on
  the Accounts page gave "Downloads paused for 1 of 2 accounts" with both buttons in the header; the Chats
  page no longer scrolls sideways (the table scrolls in its box); the viewer link reads "Viewer: set its
  address". Not seen: a pause ending by itself (an hour), the disabled controls after Quit.
  **The pause's independent review is running** (an Opus agent of this session, read-only, on
  1fd0d6d..0ee2c00; `BRIEF-G1c-review.md`; it writes `REVIEW-G1c-pause.md`). **Next step:** its findings to
  a coder; then merge the main head in (it still lacks `wip/mirror-auto` and `wip/core-chosen`: G1 merges
  after both); say the full runs' plan; run them; `MERGE-QUEUE.md`.
- 11-15 18:21: **the main branch has `wip/mirror-auto` now** (be429e1, head 9dd5a21). A trial merge of
  9dd5a21 into the pause's head (in the look copy, aborted, nothing kept): two conflicts, both in the lent
  files (`collector/account.go`, `collector/command.go`); 122 other files merge by themselves. K1
  (`wip/core-chosen`) is still not merged. **Plan:** the coder of the pause's review fixes also merges the
  main head in and resolves the two files (and runs the named tests of both sides); K1's head is merged in
  the same way when it lands, before the full runs.
- 11-15 18:29: **the pause's independent review is back: `REVIEW-G1c-pause.md`**: 1 must fix (confirmed by a
  probe): a pause for every account writes over an account's "until I resume" and that pause then ends by
  itself; 2 should (a freeze seen just before a pause is acted on only when the pause ends; the Overview
  rebuilds the pause menu every 2 s); 5 minor. All accepted. **`BRIEF-G1d-pause-fixes-and-merge.md`**: part 1
  the review's fixes (a pause never shortens a pause that holds); part 2 the main head 9dd5a21 merged into
  the branch as a merge commit, the two conflicts resolved, five meeting points with the automatic mirror
  checked (its task under Stop and under a pause; the approval's new meaning; chats that start switched
  off; the flags; the rig). **A fresh Opus coder (high effort) is started on it**, a background agent of
  this session, in `wt-pages-g1` from 0ee2c00. PC before: 7.8 GB free. The board row is rewritten (my own
  row's state only). **Next step:** on its hand-back read the two resolved conflicts and the five points;
  a browser pass on the merged tree; then K1's head when it is on the main branch; then the full runs' plan
  said in one line, the runs, `MERGE-QUEUE.md`.
- 11-15 19:01: **the integrator, 19:03: K1 is merged; the main head is 0697f15; G1 is next.** The running
  coder had already merged 9dd5a21 (ea54bd0) and was settling the automatic mirror (7c1287e); **I sent it
  the second merge** (0697f15) with seven meeting points, the first being that K1 added the same route and
  method (`POST /api/chats/collect`, `handleChatCollect`, calling `OwnerSetChatCollect`) that this branch
  has in `reads.go`: one handler stays. Board messages read: 34 (b) (the toolchain's runtime line: the next
  go command compiles everything once), 39 (every command for the owner by full path, from any folder), 40
  (**the app as one standalone .exe with its folder: the packaging is this track's after G1**; product code
  finds its files from the program's own folder or a setting; what a starter script does must be reachable
  from the program and its settings). My draft starter is scaffolding by that rule. **Next step:** the
  coder's hand-back; my read of the conflicts and the collect door; a browser pass on the merged tree; the
  full runs' plan in one line to the owner; the runs; `MERGE-QUEUE.md`. Then: the packaging's brief (G6),
  and coders for G2 and G3.
- 11-15 19:02: **the program's own folder is designed: `DESIGN-G6-one-folder.md`** (board message 40; not built;
  a coder's brief is cut from it after G1 merges). One folder; `tgarchive.exe` a small launcher that is not in
  the VPN's list and imports neither the collector nor the Telegram package (settings file from its own
  folder, a first-start setup page, the public address looked up outside the VPN, starts the collector with
  `run -pages` and the viewer, opens the pages, stays until Quit, never restarts a program by itself); the
  collector and the viewer as their own programs inside. Four choices for the owner are on the board's
  "Waiting for the owner" list as one item, each with a recommendation; none blocks.
- 11-15 19:22: **the last round is handed back: `wip/pages-g1` head 541743d**, pushed, tree clean. The
  pause's review: every finding done with a named test (N2 left as agreed). Two merge commits of the main
  head: ea54bd0 (of ac47004: the automatic mirror) and 5cc7c03 (of fa8c011: K1). Conflicts: the account
  struct's fields, three places in `command.go` at the first merge and one at the second (the Config
  literal), the chats routes in `server.go`; both sides kept each time. One collect handler: K1's
  (`OwnerSetChatCollect`), through this branch's registration and cancellable context. New: the row's
  "why it is off" from K1's record (`server/madeoff.go`), the Overview repainted by shape (`shape.js`).
  By its report: 86 collector tests of this branch and the mirror's side pass on the merged tree, K1's 37
  pass, the server with `-short` and `livepages` pass, `TestPagesHold` held a minute. Not verified by it:
  no browser on the merged tree, no race detector, no whole runs, `ChatsOffWhy` at size.
  **Next step:** my read of the two lent files against the main head; a browser pass; the full runs.
- 11-15 19:26: **read and clicked through on the merged tree; the full runs are started.** Against the main head
  (fa8c011, fully merged in: nothing of main is missing from the branch) this branch changes four existing
  files outside the server: `collector/account.go` (34 lines: the Stop's check, states, ending, the pause's
  turn, one counter line), `collector/command.go` (the flags, the bind, the run with pages, the help),
  `cmd/tgarchive/app.go`, `catalog/topics_size_test.go`; `collector.go` and `reader.go` are untouched.
  **Fourth browser pass** (look copy at 541743d, 127.0.0.1:8795, invented data, no console error): the
  pages load; a never-chosen chat says so with K1's sentence; its Collect switch works and says what it
  did; an estimate came back after about a minute on the rig (the reader is slow there) and showed on the
  row by itself; Approve read the chat. Two small faults for the next coder in these pages (not held for):
  the "Asked: ..." note stays beside an estimate that has arrived; the collect toast is long and says "no
  file changes state" for a chat with no files listed.
  **THE FULL RUNS ARE RUNNING, once, a background command of this session** (plan said first): results in
  `runs-pages-g1/` in the project folder (each log ends in "exit N"; `started.txt` has the head and the
  times): whole Windows tests of `internal/server`, `internal/collector/livepages`, `cmd/tgarchive`,
  `internal/collector` (40 m bound), the catalogue's `TestTopicSettleAtSize` by name, gofmt, go vet per
  package; the race detector on the whole `internal/collector` (one container, 2 CPUs, 4 GB, 150 m bound,
  started first), then on `internal/server` and `internal/collector/livepages`. PC before: 5.6 GB free, CPU
  24%, no other test container. **If this session stops:** read `runs-pages-g1/*.log`; if all end in "exit
  0" and gofmt's log is empty, write the `MERGE-QUEUE.md` entry for `wip/pages-g1` 541743d (below); if the
  container was lost, run the missing piece again with `ix-tools/race-archiver.sh`.
  **Next step:** the entry in `MERGE-QUEUE.md`, the board row; then coders for G2 and G3 on 541743d.
- 11-15 19:27: **the Queue page's coder is started** while G1's full runs go (a fresh Opus agent, high effort, a
  background agent of this session): copy `wt-pages-g2`, branch `wip/pages-g2` from 541743d, brief
  `BRIEF-G2-queue-now.md` (brought up to date in its last section: what G1 built to use, K1's "not
  collected" is not a failure, the scripts' guards, two small Chats faults from my browser pass, and to be
  sparing with the PC during the runs). Not started: G3 (sign-in page: collector-heavy, after the runs).

## TAKE OVER FROM HERE (session P2 wrapped up 11-15 20:04 at the owner's word: its context was nearly full)
Read `BOARD.md` first (my row; messages 26, 27, 30, 34 b, 39, 40, 48; "Waiting for the owner" items 14, 17,
24, 25), then this block. Everything above is the history of how it got here.

**1. G1 (one program to open, with the pause of downloads): listed, not merged.**
- Branch `wip/pages-g1` head 541743d, pushed, copy `wt-pages-g1` clean; the main head fa8c011 is merged in.
  Entry "G1" at the end of `MERGE-QUEUE.md`, marked **NOT READY until its race runs end**.
- Full runs, once, in `runs-pages-g1/` (started 19:26 as a background command of session P2): the whole
  Windows tests passed (server 75 s, livepages, cmd/tgarchive, the collector whole 681 s, the catalogue's
  one test by name), gofmt clean, vet clean. **Still running at 20:03: the race detector** on the whole
  `internal/collector` (a Docker container, bound 150 minutes), then on `internal/server` and
  `internal/collector/livepages`. **Do this first:** look at `runs-pages-g1/race-collector.log`,
  `race-server.log`, `race-livepages.log`. Each ends in "exit N" when done.
  - All three "exit 0": in `MERGE-QUEUE.md` change entry G1's second line to READY with the three times, and
    its "RUNNING when this was written" sentence to the results; say so in the board row. Nothing else.
  - A log missing or cut short (the session that started it ended): run that one again:
    `bash ix-tools/race-archiver.sh "$PWD/wt-pages-g1" ./internal/collector 2 4g 150m` (or `./internal/server`,
    `./internal/collector/livepages` with `2 3g 30m`), output into the same folder, "exit N" appended.
  - A data race or a failing test: read it; a real one goes to an Opus coder on `wip/pages-g1` with a named
    test; a test that judged real time under the detector is fixed the way board messages 16 and 25 say.
- After the merge the integrator installs the build (board item 17). Then the owner's check, which is what
  "done" means: the owner opens it, sees the test catalogue's chats and queue, starts, stops and pauses
  from the page. **Nothing of this track has run against Telegram.** Not seen in a browser by anyone: the
  starting page, the failed-pages page, a pause ending by itself, a narrow window.
- The starter `app\tgarchive.cmd` and `.ps1` are a draft, untried; by board message 40 they are scaffolding:
  the real answer is the program's own folder (point 4). If the owner is to try G1 before that exists,
  finish the starter first (it must not depend on the folder it is started from; give the owner its full
  path: message 39) and try its "already open" and "page did not answer" paths against `TestPagesHold`.

**2. The Queue page (G2): a coder is running.** An Opus agent of session P2 in `wt-pages-g2` on `wip/pages-g2`
(from 541743d), brief `BRIEF-G2-queue-now.md`. At 20:03 it had pushed four commits (the lists, the retry of a
group, the held-copy switch, the costly part of the queue kept 30 s, a rig test); not handed back. When
session P2 ends, that agent ends with it or hands back to nobody: look at
`git -C wt-pages-g2 log --oneline 541743d..`, `git -C wt-pages-g2 status`, and
`wt-pages-g2/archiver/docs/progress/pages-g2-PROGRESS.md` and `-REPORT.md`; if it is not finished, start a
new Opus coder (high effort) on the same brief from where the branch is. Then, as for G1: read the risky
part yourself (the one-statement retry and its plan at 300,000 rows; that nothing held or in transfer is
touched), open it in a browser over `TestPagesHold` (every round that touches the scripts: a page that
fails to parse shows nothing and no Go test sees it), one independent read-only review, its fixes, the main
head merged in, the full runs once (server whole and under the race detector; the collector only by the
named rig test unless collector code changed), the queue entry. It sits on G1: it merges after G1.

**3. Briefed, not started:** `BRIEF-G3-signin-page.md` (sign in from the Accounts page; an account added
while the program runs touches `collector.go`'s `Run`: its own review and the race detector on the
collector); `BRIEF-G5-staging-page.md`. Both were written against G1's first version: before starting one,
add a "since this was written" section as G2's has (what G1 built to use; K1; the scripts' guards; open it
in a browser). **Not briefed:** G4, a mirror step from the page (the mirror's command and the automatic
mirror are on the main branch now; `wip/mirror-name` waits in the queue: read `mirror_cmd.go`'s plan first).

**4. The program's own folder (board message 40): designed, not built:** `DESIGN-G6-one-folder.md`; the
owner's four choices are board item 24 (build to the recommendations unless the owner says otherwise). A
coder's brief is cut from it after G1 merges.

**5. New since 20:03, not read by session P2 beyond its first lines:** board message 48 and item 25: the
owner wants the app usable like a Telegram client (reading: the viewer's; acting: who owns what is on the
board's "Listed and unbuilt" row and in message 48). Read what it asks of the pages track.

**6. Small listed things in this track's packages, after the pieces above:** the mirror's name setting and
"choose an existing chat as a mirror" on a page; the setting for downloads of a chat joined while away;
multi-select of chats to mirror (all in the board's "Listed and unbuilt" table).

**How this session worked, for the next one:** one Opus coder (high effort) per brief, in its own copy;
my own read of the lent collector lines and the stop paths after every round; a browser pass over
`TestPagesHold` after every round (use a second, detached copy, `wt-pages-g1-look`, so a coder's edits do
not meet a compile; it can be removed: `git -C repo-archiver worktree remove ../wt-pages-g1-look`); one
independent read-only reviewer with probe tests per piece; the review's findings and the merge of the main
head to one coder; the full runs once at the end, the plan said in one line first. Board edits: my own row
and lines only, by a small scripted replace, then `git diff --stat` to see that only those lines moved.

**Added 11-15 20:08, after the block above was written: the Queue page's coder HANDED BACK** (so point 2's "a coder
is running" is over): `wip/pages-g2` head da993b39, pushed, copy `wt-pages-g2` clean; its account is
`archiver/docs/progress/pages-g2-REPORT.md` on the branch. By its report: downloading now (from the state
index, progress only from the checkpoint), just finished (the last 20 saves with where their bytes are, a
link to the viewer's post page), failed grouped by the stored reason with "Try these N again now" as one
indexed statement (it makes the group due; the supply's own requeue decides each file's state; the owner's
hand-set files are left out), gone counted apart, the `held_wait` switch, a page that does not jump; the
queue's costly part measured 248 to 365 ms at 300,000 files on a busy PC, so it is kept 30 s and the lists of
now 5 s; my two small Chats faults fixed; no catalogue function, no schema step, nothing in the collector
but one rig test. 12 new server tests, 4 mutations each failing its test, a rig test 4 of 4; it looked at
the page in a browser over `TestPagesHold` and fixed 7 faults it found. **Not done by anyone:** my read of
it, a browser pass by the main session, the independent review, the main head merged in, its full runs, its
queue entry. **Next for G2 (the next session):** read `queuenow.go` (the retry's statement and plan, what
"due" does to a held or owner-set file), open the Queue page over `TestPagesHold`, then one independent
read-only review (as `BRIEF-G1-review.md` was written: where to look hardest, probes through `-overlay`),
its fixes, then the runs and the entry. It merges after G1.
G1's race runs at that time: the collector's container still running (41 minutes in), the server's and
`livepages` not started yet (they follow the Windows runs in the same background command: check the logs).

**Added 11-15 20:50: G1's RACE RUNS ENDED, AND TWO FAILED. G1 is NOT READY (entry G1 and the board row say so).**
Logs: `runs-pages-g1/race-collector.log` (FAIL, 4,929 s), `race-server.log` (FAIL at the 30 m bound),
`race-livepages.log` (ok). Neither failure is in the pages' own code:
- `TestPauseEndsByItself` (ours, `collector/pausedl_test.go:213`): "every file deep in transfer at the click
  was finished before the pause held: nothing to judge". The test sets its case up by timing (files of 24
  to 32 MiB that must still be in transfer when the pause holds) and under the slow detector they were done
  first. **Fix (tests only):** build the case by holding the fake's part answers until the pause holds,
  then letting them go; never fail on "nothing to judge".
- `TestTelegramHoursAcrossRestart` (not ours): one data race inside the fake Telegram (`faketg/conn.go:44`:
  a shared message object encoded by two goroutines; the library's `Encode` writes its flags). Said to the
  integrator and Core on the board (the last message under "Messages"). Not ours to fix; if it shows again
  in a rerun, run that one test again by name and say so in the entry.
- The server's whole run under the detector did not finish in 30 minutes: it was 9 m 43 s into
  `TestOverviewCostAtSize` (a measurement at 300,000 files). No race was reported before the bound.
  **Fix (tests only):** the server's tests at size (`TestOverviewCostAtSize`, `TestQueueCostAtSize` on G2,
  `TestOpenPageStatementsBounded`, the retry's plan test at 300,000 rows, `TestCoverageSize`) skip under
  the race detector with one line (a build-tagged constant `raceOn`), unless one of them is there to judge
  concurrent code: say which stay.
**A small Opus coder was started on exactly these two test fixes at this time** (a background agent of
session P2, in `wt-pages-g1` on `wip/pages-g1`; it commits and pushes; tests only, no product code). Look at
`git -C wt-pages-g1 log --oneline 541743d..`. **Then, by the main session (Docker; the coder may not):**
`bash ix-tools/race-archiver.sh "$PWD/wt-pages-g1" ./internal/server 2 3g 40m > runs-pages-g1/race-server-2.log 2>&1; echo "exit $?" >> runs-pages-g1/race-server-2.log`
and the pause's and the owner's Stop tests under the detector by name (the script takes a package; for
named tests run the same `docker run` line it holds with `-run 'TestPause|TestOwnerStop|TestStart|TestPages'`
added, bound 60 m). A whole collector run under the detector takes 82 minutes: repeat it once on the fixed
head only if the integrator asks for it (tests-only changes since the run that showed no race in the
collector's own code). When those end in "exit 0": change entry G1's head and its NOT READY line, and the
board row. `wip/pages-g2` then needs the fixed G1 head merged in (it has its own test at size).

**Added 11-15 21:07: the two test fixes are in: `wip/pages-g1` head ee437a46** (pushed; tests only since 541743d).
The pause's and the Stop's tests hold the fake's part answers (`collector/parthold_test.go`, `rig.holdParts`),
13 tests changed, the fake untouched; the server's `TestOverviewCostAtSize` and `TestOpenPageStatementsBounded`
skip under the detector (`raceOn`). Without the detector: the pause test 10 of 10, the others 3 of 3, the
server whole 81 s ok. **Running now:** this branch's collector tests by name under the detector, container
`p2-g1-race-collector-named`, log `runs-pages-g1/race-collector-named-ee437a46.log`. **Not started by me:**
the server's whole run under the detector on ee437a46: the integrator has a container `int-g1-race-server`
running (board message 54 asks whether it is that run). **To close G1:** both end in "exit 0" -> in
`MERGE-QUEUE.md` entry G1: head ee437a46, the NOT READY line to READY with the two results, and the board
row. If the server's run is not the integrator's: `bash ix-tools/race-archiver.sh "$PWD/wt-pages-g1" ./internal/server 2 3g 40m`
into `runs-pages-g1/race-server-ee437a46.log` with "exit N" appended. `wip/pages-g2` needs ee437a46 merged in
and its own test at size (`TestQueueCostAtSize`, the retry's plan test) given the same skip.

## SESSION P3 (a fresh pages session, started by the integrator at the owner's word; took over 11-15 21:10)
Session P2 is retired. A session that takes over from P3 reads this section's LAST entry first.

- 11-15 21:10 to 21:13: **read in full by me**: `CLAUDE.md`'s archiver section, the whole board (messages 1 to 54,
  the waiting list), the take-over block above with its three additions, entry G1, TRIED-BEFORE 5, 9, 10, 15 and
  19, `LESSONS-viewer-ix12.32.md`. Found on disk, not as my start text said: **G1's test fix was already made** by
  P2's coder (the 21:07 paragraph above; the integrator wrote my start text before it saw message 54). So no
  coder was started for it; I read the change instead.
- 21:13: **my read of the fix (`git diff 541743d ee437a46`, tests only, 10 files).** `parthold_test.go`: a
  dialer around the rig's holds chosen part requests on the client's side until `letGo` or until the request's
  context ends (the engine's stop); the fake is untouched; the engine's part deadline is an hour of the clock
  in those tests so a held part is never booked as a timeout. `TestPauseEndsByItself` holds every part from
  8 MiB on of account 1's files of 24 MiB or more, waits until one such file has a part held and parts answered
  past 4 MiB, pauses, waits until the pause holds, lets go: a picked file cannot finish first, and one that was
  saved all the same now FAILS the test instead of being dropped from the set. Twelve other tests of the pause,
  the Stop and the pages got the same hold in place of "parts answered slowly". Sound by reading; the fake's
  file lookup the hold calls is under the world's lock.
- 21:11: **by name on Windows** (`runs-pages-g1b/win-pause-ends-ee437a46.log`): `TestPauseEndsByItself` 3 of 3,
  ok, 21.6 s.
- 21:12 to 21:17: **under the race detector, a Linux container, 1 CPU** (slower than the run that failed, on
  purpose): `-count=5 -v -run '^TestPauseEndsByItself$'`, log `runs-pages-g1b/race-pause-ends-x5-ee437a46.log`.
- 21:15: **the integrator's rerun of the whole `internal/server` under the detector ended: ok, 2,382 s, exit 0, no
  data race** (container `int-g1-race-server`, on 541743d, its at-size tests included: read by me from the
  container; the integrator writes it on the board). So the package's product code, identical on ee437a46, is
  clean under the detector, and the whole package needs about 40 minutes there with the tests at size.
- **`-short` and the tests at size, decided.** No race run uses `-short` (`ix-tools/race-archiver.sh` and
  `full-runs.sh` do not pass it), so `TestTopicSettleEndsWithThePages` (it judges concurrent code: a settle
  ending with the pages' context) is NOT skipped where the detector runs. The tests at size are left out under
  the detector by a build tag (`race_on_test.go` / `race_off_test.go`, the constant `raceOn`), not by `-short`:
  that leaves out exactly `TestOverviewCostAtSize` and `TestOpenPageStatementsBounded` (both at 300,000 invented
  files, both judging statements and cost, no concurrent code); they still run in every whole Windows run.
  Checked as it runs: those two and the settle test by name under the detector, log
  `runs-pages-g1b/race-server-named-ee437a46.log` (started 21:16).
- 21:14: **G2, my read of the risky part** (`queuenow.go`, the catalogue's `requeue`, `asideBackSQL`, the
  index). The retry writes no state: it sets `retry_at = 0` for the group's set-aside files and the supply's
  own requeue decides each file (wanted; a probable copy held again; a chat no longer collected: held). Held,
  kept-held and active files are in other states and cannot be taken; the owner's hand-set reason is left out
  twice (the statement, the route's 409). **One thing by the record, for the review to measure:** it is ONE
  UPDATE over a group of any size, and the catalogue's own requeue is cut into 500 rows a transaction because
  "33,334 due at once held the writer 3.4 s in one UPDATE" (`state.go`, above `requeueChunk`). The retry's rows
  are lighter (no state change, no trigger fires), but its hold of the single writer at 15,000 to 100,000 rows
  is not measured anywhere. Also for the review: the index range is the whole server's set-aside files whatever
  the reason; whether every set-aside reason is a fixed word (else thousands of groups, no limit).
- 21:14 to 21:16: **G2 in the browser** (`TestPagesHold` from `wt-pages-g2` on 127.0.0.1:8793, invented data,
  no console error): the Queue page at desktop and at phone width (375: nothing wider than the window); Just
  finished "the first 20 of 174" with places; the failed group; "Try these 1 again now": the words came, the
  group read "due now", and the file was saved about 15 s later with every lane idle. **One fault seen:** the
  Failed region stayed at "1 file ... due now" with its button, and the counts at "Set aside 1", for as long as
  the pointer rested on the button I had clicked (the rule "a region is not rebuilt under the pointer");
  it corrected itself only when the pointer moved away. To the owner that reads as "the click did nothing".
  For the fix round: after the owner's own click, the clicked region shows the result under the pointer too
  (its words in place, the button disabled when its group is gone). Not seen by me: files in transfer (all
  were saved before I opened the page), a storm note, a gone group, the viewer link.
- 21:14: **G2's independent review started** (one Opus agent, high effort, read-only, probes through
  `-overlay` in `wt-pages-review-g2-scratch`): `BRIEF-G2-review.md`; it writes `REVIEW-G2-queue.md`. Point 1 of
  the brief is the retry's hold of the writer, measured at 500, 15,000, 33,334 and 100,000 rows.
- 21:17: **the pause test under the detector: 5 of 5 passed, ok, 289 s, exit 0, no data race** (1 CPU; each run
  57 to 59 s; each time 1 file past a checkpoint at the pause and 1 carried on from its checkpoint).
- 21:19: **G3 (sign in from the Accounts page) is with a coder** while G2 is with its reviewer: one Opus agent,
  high effort, a background agent of this session; copy `wt-pages-g3`, branch `wip/pages-g3` cut from ee437a46;
  `BRIEF-G3-signin-page.md` with a new last section "Since this was written" (what G1 built to use; the
  owner's Stop and the pause on record; K1; the watchdog gives no keyboard input, so the page is the only way
  to type a code and a Quit must end with exit code 0; no absolute paths; tests never on real time; the
  scripts' guards; the browser). It commits WIP and pushes its own branch; its progress file is
  `archiver/docs/progress/pages-g3-PROGRESS.md` on the branch. After its hand-back: my read of `collector.go`'s
  `Run` and the lent lines, one independent review, its fixes, the main head merged in, then once the whole
  Windows runs and the race detector on `internal/collector` (an account added while the program runs is
  concurrent code).
- 21:22: **entry G1 is READY at ee437a46** (the integrator's message at 21:21: G1 needs only its one test fixed,
  pushed and run by name under the detector; its server rerun is on the board as passed, message 53). The
  entry says the three results and, plainly, that the run of the 12 other changed tests by name under the
  detector (`p2-g1-race-collector-named`) and my check of the server's skips (`p3-g1-race-server-named`) are
  still going: their results are added to the entry and here when they end (a background wait of this
  session writes `runs-pages-g1b/named-collector-wait.txt`). The merge and the install are the integrator's.
  **Next step:** the results of those two runs into entry G1; then the Queue page's fix round from
  `REVIEW-G2-queue.md` when the reviewer hands back.
- 21:23: **P2's named run of the branch's collector tests under the detector ENDED: FAIL, 908 s, one test,
  no data race** (`runs-pages-g1/race-collector-named-ee437a46.log`): `TestE2EPages` (`pages_e2e_test.go:202`):
  `POST /api/chats/estimate` got no answer within the test client's 30 s of real time, right after a Start.
  The test is not one the fix changed; it passed in the 82-minute whole run on 541743d. The route answers
  "asked, still under way" (202) after its own 30 s (`estimateAnswerBound`), the test's client gives up at
  30 s and the test wants 200: a real-time edge. Every other test of that run passed, the 12 moved to held
  parts among them. **Not known yet:** slow under the detector, or no estimate at all after the Start.
- 21:25: entry G1's line changed from READY to **HOLD** with exactly this; the integrator told directly
  (one message: hold the install; a merge of ee437a46 is as good as 541743d, test files only). **Running:**
  `TestE2EPages` by name under the detector, 4 times, verbose (container `p3-g1-race-e2e`, 2 CPUs, log
  `runs-pages-g1b/race-e2e-x4-ee437a46.log`; the test logs how long the estimate took on the clock).
  **Next step:** read that log. All pass with the estimate well under 30 s: an edge of the test under load;
  make it wait for the estimate through the 202 path or the row instead of the client's timeout (a test file
  only, on `wip/pages-g1`), then READY. An estimate that never comes after a Start: a product defect in the
  owner's Start or the reader's queue: read `onReader` and the session's start, a named test, a coder.
- 21:26 to 21:36: **`TestE2EPages` under the detector, settled.** By name 4 times: 2 passed (the estimate
  answered after 1 to 2 s of the clock), 2 failed at the client's 30 s. A probe loaded by overlay (the tree
  untouched; files kept in `wt-pages-g1-probe-scratch`: the test with a goroutine listing and the collector's
  log written at a 20 s stall, the fake's `conn.go` noting each error it returns): the reader sat in the
  retry pause of a topics request ("telegram: topics request failed ...; retry 1" to 5, both accounts); the
  fake's `Invoke` could not ENCODE its own topics answer: "forumTopic: field from_id is nil", 13 of 13
  notes (`faketg/server.go` `topics()` never sets `FromID`). So every topics request to the fake fails in
  every rig with a forum; the reader retries 5 times with pauses of 2 to 32 s of the clock; an estimate asked
  meanwhile waits behind the whole call. The rig's clock is 20 times real time on Windows (3 s: unnoticed)
  and 3 times under the detector (over 20 s: the test's 30 s is passed). **With `FromID` set by overlay:
  10 of 10 passed under the detector (190 s).** Not G1's product code; the fake's (Core's package).
- 21:36: the server's skip check ended: `TestTopicSettleEndsWithThePages` PASS (1,012 s at 1 CPU under the
  detector), the two tests at size SKIP, exit 0. The package needs a 60-minute bound under the detector.
- 21:38: **entry G1 is READY again at ee437a46** with the cause in its second line; board message 58 (Core:
  the fake's one line, for K7; the integrator: READY, what a whole race run of the collector can still hit
  until K7's line is merged); my row. Not done on purpose: no change to `TestE2EPages` itself (the head
  stays ee437a46; the cause is the fake's and the test passes 10 of 10 with it repaired).
- 21:36: **G2's independent review is back: `REVIEW-G2-queue.md`, 2 must fix, 4 should, 8 minor** (the tree
  untouched; probes in `wt-pages-review-g2-scratch`). M1: after a file's "Try again now" the keyboard's focus
  lands on a GROUP's button (the selector `[data-key^="retry-"]` also matches `retry-group-<i>`), so the next
  Enter makes a whole group due. M2: the one UPDATE is unbounded: 628 to 665 ms on the writer for 100,000
  files, 374 to 650 ms for 33,334 beside 100,000 of another reason, and the supply's requeue after it 14.3 s
  for 100,000 (5.1 s for 33,334, 2.7 s for 15,000) inside a lane's `Next`. S1: the engine's `park` writes
  per-file numbers into a reason (one group per file, no limit). S2 to S4 and the minors: in the file.
  **Next step:** read the review file myself, write `BRIEF-G2b-fixes.md`, one Opus coder in `wt-pages-g2`
  (ee437a46 merged in first; the `raceOn` skip for its two tests at 300,000 files).
- 21:40: **G2's fix round is with a coder**: `BRIEF-G2b-fixes.md` (read the review myself first; every finding
  accepted; my decisions: one click makes at most 5,000 files due in one statement, unique files first, the
  review's capped form, measured 52 to 136 ms; groups keyed and ordered by reason; the clicked region shows
  the result under the pointer; lists of now say their own time; the counts from the same reading as the
  lists; groups cut at 50). One Opus agent, high effort, a background agent of this session, in `wt-pages-g2`
  on `wip/pages-g2`; step 0 merges ee437a46 in. Board message 59 tells Core of the engine's reason with
  numbers (S1). **Running now, both background agents of this session:** the G3 coder (`wt-pages-g3`; at
  21:39 two WIP commits pushed: the seam, an account added while running, the routes, 14 collector tests)
  and the G2b coder. The PC was at 94% CPU and 3.5 GB free at 21:39 (other tracks' runs): both coders wait
  above 85%. **Next step, when G2b hands back:** my read of the capped statement and the scripts' focus
  rule, a browser pass (port 8794), the reviewer's second pass (a fresh read-only agent on
  `REVIEW-G2-queue.md` and the new diff), then once: `internal/server` whole on Windows and under the race
  detector (60-minute bound: the kept answers are concurrent code), the rig test by name; then entry G2.
  **When G3 hands back:** my read of `collector.go`'s `Run` and the lent lines, its independent review.
- 21:40: the integrator asked (a message that crossed mine) what is decided for `TestE2EPages`: entry G1 now
  says it in so many words: not changed in G1's head, named as a real-time test still to fix, fixed in the
  Queue page's round on `wip/pages-g2` (told to the G2b coder as fix 13: the client's timeout above the
  route's bound, "asked" accepted, the estimate awaited on the row); the merge is not held by it.
- 21:49: **G3's coder HANDED BACK: `wip/pages-g3` c49b27ac, pushed, the copy clean** (22 files, about 3,000
  lines; its account: `archiver/docs/progress/pages-g3-REPORT.md` on the branch). Built: `AddAccount`
  (`collector/account_add.go`; `newAccount` taken out of `loadAccounts`; 14 lent lines in `collector.go`:
  `addCtx`, `addWG`, `stopBegun`), the seam `server.SignIns` with its adapter, six POST routes inside the
  guard, the dialogue (`js/signin.js`), a Quit held with the pages up while a code is awaited (`pages.go`'s
  stopper; a second explicit Quit is `ForceStop`; exit code 0 by its reading of `command.go`), removal refused
  while a sign-in is open. 14 collector tests and 3 server tests on the fake, 6 mutations; clicked through in
  a browser by the coder (a stated wait, a wrong code, a reload, the password, Add). **Its departures:** a
  plain INSERT, not `UpsertAccount`, so ONE account may wait for its sign-in at a time (the unique index on
  the Telegram id; more needs a schema step); the first Quit starts a held stop; a stale sign-in (older than
  `SignInHold`) is closed when a new code is asked. **Its doubts:** the row written outside the lock; a code
  request past the `stopAsked` check as the stop is asked (the second hold then waits with the pages closed);
  what the watchdog does with a stop held 15 minutes; a sign-in that ends on another Telegram account leaves
  that login's session file under this account's name (existing behaviour).
- 21:51: **my read of the risky part** (the lent lines, `account_add.go`, the stopper): the stop's mark and the
  task's start are both under `c.mu` and the supervisor adds to the wait group inside it, so no task is added
  after the tasks' wait began; sound by reading. Not settled by reading, given to the reviewer first: `c.accts`
  is now written while tasks run and has 14 readers in 9 files (is each under the lock; which lists made at
  the start miss the new account); `holdForSignIn` now runs twice. **G3's independent review started 21:51**
  (one Opus agent, high effort, read-only, probes by overlay in `wt-pages-review-g3-scratch`):
  `BRIEF-G3-review.md`; it writes `REVIEW-G3-signin.md`. **Running now:** that reviewer and the G2b coder
  (`wt-pages-g2`: ee437a46 merged in, at work). **Next step:** whichever hands back first: G2b -> my read, a
  browser pass on port 8794, a second review pass, the full runs, entry G2; the G3 review -> its fix round
  (`BRIEF-G3b-fixes.md`), the same coder's context is gone: a fresh Opus coder from the branch and the report.
  Then G5 (Staging) with a coder when one of the two is back.
- 21:52: **G5 (the Staging page) is with a coder** (the PC at 48% CPU, 4.6 GB free): one Opus agent, high effort,
  a background agent of this session; copy `wt-pages-g5`, branch `wip/pages-g5` from ee437a46;
  `BRIEF-G5-staging-page.md` with a new last section (its files kept apart from the two sibling branches so
  the merges are "both sides kept"; the four rules of the Queue's review built in from the start; the
  helper's real numbers; no forum in its rig). **Three background agents of this session now:** the G2b coder
  (`wt-pages-g2`), the G3 reviewer (read-only on `wt-pages-g3`), the G5 coder (`wt-pages-g5`). If this session
  ends they end with it: each coder's state is on its branch (`archiver/docs/progress/pages-g*-PROGRESS.md`),
  the reviewer's in `REVIEW-G3-signin.md` if it got that far; start a fresh agent on the same brief from where
  the branch is. **Not briefed yet:** G4 (a mirror step from the page: read `mirror_cmd.go`'s plan,
  TRIED-BEFORE 24 and 25 and FEATURES 12 first; it writes to Telegram on the owner's click, so its design goes
  to the owner's list before a brief), G6 (the program's own folder: its brief is cut from
  `DESIGN-G6-one-folder.md` once G1 is merged), the starter through the watchdog, the local door's place.
- 21:52 to 21:57: **the owner opened G1 (merged as c8e49ee9, installed by the integrator) and found one defect**
  (the integrator's message): a click on Chats or Overview "jumps the page down slightly, so you need to then
  scroll up to see the top bar"; Accounts and Import do not. Reproduced on the merged build over
  `TestPagesHold` with real clicks: Chats 121 px, Overview 121 px, Accounts 0. Cause: `main.js` `route` ended
  with `main.focus({ preventScroll: false })`; the browser scrolls a content taller than the window to the
  window's top. Fixed by me (three files, exact and small: no coder): `web/assets/js/land.js`, one import and
  one line in `main.js`, `land_test.go`. **`wip/pages-scroll` 7d47bdbc, one commit on c8e49ee9, pushed; entry
  "G1s" in `MERGE-QUEUE.md`, READY; board message 63.** Fixed build in the browser: 0 px after each of the
  seven top-bar links, no console error; whole `internal/server` ok (75.9 s); the test fails with the old focus.
- 21:58: **usage is low (board message 62): no new piece.** Stopped by me: the G5 coder (3 minutes in, nothing
  written; `wt-pages-g5` clean at ee437a46). Going on: the G2b coder and the G3 reviewer.

### STATE FOR A TAKE-OVER (P3, 11-15 21:58; kept current below this line)
Read `BOARD.md` (my row; messages 56 to 63; item 24 is decided: as designed), then this block.
1. **Merged:** G1 (c8e49ee9). The owner has opened it on the test account. **Listed, READY:** "G1s",
   `wip/pages-scroll` 7d47bdbc (the jump on a top-bar click). Nothing else of this track is listed.
2. **The Queue page (G2): LISTED and READY (22:28): entry "G2", `wip/pages-g2-main` 2fc8f622 in `wt-pages-g2m`
   (two commits on 2580f291). Its last run ended: `internal/server` under the race detector ok, 864 s, exit 0,
   no data race. The merge is the integrator's; after it the owner needs the build installed.** Nothing of
   it is running.
   How it got here (22:17): the G2b coder handed back 563a9126 at 22:08 (every finding fixed, fix 13 too); a
   plain merge of the main head met 11 conflicts (G1 is squashed there), so the piece's own difference from
   ee437a46 was applied to 2580f291 instead (clean, 20 files, 3c4d2b89); the whole server run then failed on
   `TestAssetsStaySmall` (chats.js 621 lines) and I moved two word helpers to `pages/chatwords.js` (2fc8f622);
   whole `internal/server` ok 99 s; the rig tests ok; my browser pass on this tree ok (port 8794). No second
   review pass was run on the fix round (usage): the entry says so.
3. **The sign-in page (G3), `wip/pages-g3` c49b27ac in `wt-pages-g3`:** handed back, read by me (the 21:49
   entries above). **Its independent review is BACK (22:04): `REVIEW-G3-signin.md`, 3 must fix, 6 should, 9
   minor; the tree untouched; five probes in `wt-pages-review-g3-scratch`. NOT MERGEABLE as it is; its fix
   round is NOT started (usage, board message 62): the next session's first new work on this piece.**
   Must fix: M1 (probe) a code request already past the `stopAsked` check when Quit is pressed: the code is
   sent, the pages close, the program waits 15 minutes with nobody able to type it (fix: a read-write lock on
   `pagesRun`, the code request under the read side from its check to its return, the stopper through the
   write side before it holds); M2 (probe) a refusal the app has no rule for (a flood of the phone number) is
   shown as "no answer (a connection problem)" with the phone step offered again: a second click sent a
   second code request (fix: Telegram's refusal apart from a lost connection, its own words, no retry
   offered); M3 (reading) while a sign-in stays open the dialogue always reopens at the code and nothing on
   the page can ask for a new one (fix: past the hold, "Ask for a new code (this one is then wasted)").
   Should fix: one busy lock for every account with false words; the stale-sign-in rule runs before the
   recorded wait's check and can waste a code; during a held Quit every other control still works (a Start
   made a stopped account dial); a sign-in ending on another Telegram account leaves that login in this
   row's session file; every refusal returns to the phone step; the browser may offer to save the two-step
   password (to be seen in a real browser). **Every finding is accepted by me by its summary; read the file
   in full before writing `BRIEF-G3b-fixes.md`.** The review's last section lists seven interleavings for
   the race detector. Then: the fix round (one Opus coder from the branch and both reports), a second pass, the main head merged in, the whole Windows
   runs and the race detector on the WHOLE collector once (82 minutes last time; until Core's K7 with the
   fake's `FromID` line is merged that run can fail on `TestE2EPages`: board message 58), its entry. The first
   real sign-in from the page is the owner's, on the test account: a board item when it is installed.
4. **The Staging page (G5):** briefed (`BRIEF-G5-staging-page.md`, last section), branch `wip/pages-g5` and
   copy `wt-pages-g5` at ee437a46, nothing built. Start one Opus coder on the brief when usage allows.
5. **Not briefed:** G4 (a mirror step from the page; with it the mirror's name rule and gathering on the
   Settings page: board messages 46 and 60 of the mirror; read `mirror_cmd.go`'s plan, TRIED-BEFORE 24 and 25,
   FEATURES 12 first; it writes to Telegram on a click: its design goes to the owner's list before a brief);
   **G6, the program's own folder: the owner said yes to the design (item 24, message 61): cut its brief from
   `DESIGN-G6-one-folder.md` on the main head; it is the next NEW piece, ahead of G5, because it is what "one
   program to open" still lacks**; the starter through the watchdog (Core's `a3-start.ps1 -Pages` serves the
   owner today); the local door's place for the client feature (board message 48; Core's design is decided,
   item 28).
6. **Small, listed, in this track's packages:** the `held_wait` control is in G2; the schema door for the
   pages on an older or newer catalogue (`catalog.ReadOnlySchema`, two lines in `cmd/tgarchive/app.go`); a
   word for a protected chat on its row (K4, when merged); a line for the watchdog's state on the Overview.
7. **Copies of mine that can go when their branch is merged:** `wt-pages-g1`, `wt-pages-g1-look`,
   `wt-pages-scroll`; scratch folders `wt-pages-g1-probe-scratch` (the probe that found the fake's topics
   fault), `wt-pages-review-g2-scratch`, `wt-pages-review-g3-scratch`. Run logs: `runs-pages-g1b/`,
   `runs-pages-g2/`.
- 22:28: **G2 is READY** (the race run of the server: ok, 864 s, no data race). Nothing of this session is
  running now: no agent, no container, no test pages. Listed and waiting for the integrator: "G1s" and "G2".
  Next new work, when usage allows, in this order: G3's fix round from `REVIEW-G3-signin.md`; G6's brief (the
  owner's yes, item 24); G5's coder.
- 22:58 to 23:02: **woken by the new integrator (the usage was reset at 22:31; board messages 65 to 68 read):
  G2 is merged (27a7d4d) and installed; "G1s" is in it.** Done since: `REVIEW-G3-signin.md` read in full;
  **`BRIEF-G3b-fixes.md` written and its coder started 23:00** (one Opus agent, high effort, a background agent
  of this session; step 0 applies the piece's difference `ee437a46..c49b27ac` to the main head in a NEW copy
  `wt-pages-g3m`, branch `wip/pages-g3-main`; `wip/pages-g3` stays for reference); **`BRIEF-G6-one-folder.md`
  written** (stage A: the launcher `cmd/tgarchive-open` built as `tgarchive.exe`, `internal/launcher`,
  `deploy/folder/make-folder.sh`; brought up to the watchdog and the native window; no other track's package
  edited); board message 69 (Core: the flood answer's mapping, the wrong user's session file; mirror: an
  account added mid-run gets no automatic mirror until the next start).
  **The PC is short of memory: 0.6 GB free at 22:59, 2.8 at 23:00, 1.4 at 23:02** (54 Claude processes 10.3 GB).
  So NOT started yet, in this order when 3.5 GB are free (a background wait of this session says when):
  (1) G6's coder: copy `wt-pages-g6`, branch `wip/pages-g6` from the main head, the brief above;
  (2) G2's owed second review pass: a read-only reviewer on the fix round (`git -C wt-pages-g2 diff da993b39
  563a9126` plus `chatwords.js` on the main head) with the first review's probes; its findings are a follow-up
  branch from the main head; (3) G5's coder (`wip/pages-g5` is at ee437a46 with a progress note only: cut it
  anew from the main head, the brief's last section says ee437a46: tell the coder the head instead).
  **In the take-over block above, points 2 to 5 are overtaken by this entry: G2 merged; G3 in its fix round;
  G6 briefed.**
- 23:07: **7.0 GB free (CPU 77%): two more agents started**, both Opus at high effort, background agents of this
  session: (1) **the G6 coder** (`BRIEF-G6-one-folder.md`; it makes its own copy `wt-pages-g6`, branch
  `wip/pages-g6`, from the head of the main branch on `private`; new files only: `cmd/tgarchive-open`,
  `internal/launcher`, `deploy/folder`; it starts no real program of the app: stand-ins only); (2) **the Queue
  page's second independent pass** (read-only on `wt-pages-g2m` 2fc8f622, probes by overlay in
  `wt-pages-review-g2b-scratch`; it writes `REVIEW-G2-queue-2.md`: first a table of the first review's 14
  findings closed or not, then new findings; the piece is merged and installed, so its findings are a
  follow-up branch from the main head). **Three agents run now:** the G3b coder (`wt-pages-g3m`; at 23:05 the
  piece was on the main head and its 17 tests passed: 9ac0e297), the G6 coder, the G2 second pass. If this
  session ends, they end: each coder's state is on its branch's progress file; the reviewer's in its file if
  it got that far. **Next step:** whichever hands back: G3b -> my read of the lock against the stopper and
  the held stop's routes, a second independent pass, then once the whole Windows runs (collector, server,
  livepages) and the race detector on the whole collector and on the server, its entry; G6 -> my read, running
  it as the owner will on a scratch folder, an independent review, its entry, a board item for the owner's
  first real start; the G2 pass -> a small fix branch from the main head. Then G5's coder (cut anew from the
  main head).
- 23:19 to 23:23: **the owner's word (23:20, board message 74): "add in a functioning mirror option since that is
  immediately useful and we've tested it": G4 is the next new piece, ahead of the Staging page; it is not held
  for a design answer.** Read by me: board 73 and 74, TRIED-BEFORE 24 and 25, `mirror/auto.go`'s own account of
  `Look` and `Turn`, the `Plan`'s fields, the mirror package's doors. Written: **`DESIGN-G4-mirror-from-page.md`**
  (one page for the owner: what each click sends; three new points with recommendations; item 30 of the
  waiting list), **board message 75** (the eight calls the page makes, for the mirror track to build the
  collector's side to; what I need from it: the task running whenever the program runs, a wish by the owner's
  hand, the states in one call), **`BRIEF-G4-mirror-page.md`**. **G4's coder started 23:23** (9.5 GB free, CPU
  65%): one Opus agent, high effort, a background agent of this session; it makes its own copy `wt-pages-g4`,
  branch `wip/pages-g4`, from the main head; the pages' side only (a seam `Mirrors` in `internal/server`, a
  fake, routes, the Chats page's mirror cell and plan in a script of its own, the Settings rows, an adapter
  written against an interface the collector does not implement yet). **The piece mirrors nothing until the
  mirror track has built the collector's side**: watch its answer under message 75; when it names its calls,
  tell the coder (or the next round) the names. **Four background agents of this session now:** G3b's coder
  (`wt-pages-g3m`), G6's coder (`wt-pages-g6`), G4's coder (`wt-pages-g4`), the Queue's second pass (it
  writes `REVIEW-G2-queue-2.md`). The Staging page (G5) comes after these (the order of message 73 c: group 4).
  One lesson again: a Windows path inside an inline Python string stopped the script with a syntax error
  (nothing was written); the path is built with chr(92) and the text is scanned for control bytes before it
  is written.
- 23:31: **the Queue page's second independent pass is BACK: `REVIEW-G2-queue-2.md`, 0 must fix, 3 should, 6 minor**
  (12 of the first review's 14 findings closed; M2 and S3 partly). Should 1 (probe): the capped click's pick
  runs inside the write and walks the server's whole set-aside range (the index has no reason column): a group
  of 500 beside 200,000 of another reason held the writer 246 to 314 ms. Should 2 (probe): one answer can show
  "Set aside 0" beside file-by-file rows when the supply's requeue lands between the two readings. Should 3
  (probe): in a storm the costly part is worked out at every poll (12 a minute, 1,116 statements, 5.3 s of
  handler time at 300,000 files). **Its follow-up is with a coder since 23:31**: `BRIEF-G2c-followup.md` (the
  pick as a read, the write by id with every condition checked again, one write a click; the file-by-file list
  inside the lists-of-now reading; no reread of the costly part on a set-aside change; a storm minute with
  fixed bounds in `TestOpenPageStatementsBounded`; the six minors); one Opus agent, high effort; it makes its
  own copy `wt-pages-g2c`, branch `wip/pages-g2c`, from the main head. After its hand-back: my read of the
  write, whole `internal/server` on Windows and under the race detector once, entry "G2c".
- 23:31: **the mirror track answered message 75 (its message 77): the door is being built (M9, `wip/mirror-door`,
  schema step 22), names and shapes given**: `MirrorTask`, `MirrorPlan` (a `mirror.Plan` with `Token()`),
  `MirrorWant`, `MirrorStop`, `MirrorStates` (`[]mirror.ChatState`), `MirrorNever` and `MirrorAllow` (two
  calls), `MirrorSettleWord` (no separate settle plan), four settings calls; the task runs whenever the program
  runs; the automatic take of joined chats stays behind `run -auto-mirror` until its M10 (`AutoNewSettable`
  false: the page shows the switch as a fact). Passed to G4's coder by message. **Owed by me when M9's report
  is in: correct `DESIGN-G4-mirror-from-page.md`'s table from its list per state** (the mirror's words: a click
  writes one row; then history pages if not read, `help.getConfig` once a session, one create, forwards of at
  most 100 a request with the account's pause of 20 s between writes). **G4 can be listed only after M9 is
  merged** (the adapter's conversion place is then changed to the real types: a small round, then the review,
  the runs).
  **Four background agents of this session now:** the coders of G3b (`wt-pages-g3m`), G6 (`wt-pages-g6`), G4
  (`wt-pages-g4`), G2c (`wt-pages-g2c`).
- 23:49: **G3b's coder HANDED BACK: `wip/pages-g3-main` 71000827 in `wt-pages-g3m`, on the main head 27a7d4d,
  pushed, clean** (step 0, the piece on the head: 30152dc2; it met the head in one place, the `Server`
  literal; the fix round: 22 files, about 2,000 lines; its account: "Fix round (G3b)" in
  `archiver/docs/progress/pages-g3-REPORT.md`). Every finding of `REVIEW-G3-signin.md` built and tested by
  name: M1 a read-write lock (`pagesRun.beginMu`) between a code request and the stopper, and Run does not
  hold again once the pages held; M2 a refusal Telegram answered is its own outcome with no fields; M3 "Ask
  for a new code" past the hold; S1 a step mark per account; S2 the wait checked before the stale rule; S3
  every change route refused during a held stop (`server/stopheld.go`), the header says so; S4 the wrong
  user's session file removed; S5, S6, the nine minors. Found by its own browser look and fixed: the answer
  to the code that ends a held stop was cut (`pagesRun.stop` now calls the server's `Shutdown` inside its
  bound before `Close`: a change to G1's stop). Its doubts: the read side is held through the dial (a dial
  that hangs holds the stopper until ForceStop or the dial's timeout); a Quit that crosses a code request
  answers 200 not 202; the removal lock's own effect is untested. Not verified: no race detector; whether a
  real Chrome or Edge offers to save the password.
  **My read (23:49):** `waitBegins` and `holdStop` (`collector/signin_steps.go`): a request that took the read
  side before the stop was asked stores its sign-in before the stopper looks; one that takes it after sees
  the stop and sends nothing; a ForceStop ends the stopper's wait. Sound by reading.
  **Its second independent pass started 23:49**, continued in the SAME reviewer agent (it has the first
  review's context): it writes `REVIEW-G3-signin-2.md` (its 18 findings closed or not; what the fixes opened:
  the lock, the two holds, the held stop's routes, the `Shutdown` in the pages' stop, the step mark, the
  session file's removal). **Next step after it:** its fixes (a small round by a fresh Opus coder on
  `wip/pages-g3-main`, or none), then `git merge` of the main head into the branch (it sits on main's own
  history now, so a plain merge works; the head has K7's repaired fake), then ONCE: whole `internal/collector`,
  `internal/server`, `internal/collector/livepages` on Windows; the race detector on the whole collector
  (`bash ix-tools/race-archiver.sh "$PWD/wt-pages-g3m" ./internal/collector 2 4g 150m`, 82 minutes last time)
  and on the server (60 m); say the plan in one line first; then entry "G3" and a waiting-list item for the
  owner's first real sign-in from the page (test account).
- 23:53: **G6's coder HANDED BACK: `wip/pages-g6` 51d7656a in `wt-pages-g6`, on the main head 27a7d4d, pushed,
  clean** (20 files, all new, about 4,400 lines; its account: `archiver/docs/progress/pages-g6-REPORT.md`,
  which ends with a text "For the owner"). Built: the launcher (`cmd/tgarchive-open`, `internal/launcher`):
  its folder from its own location; `tgarchive.json` (unreadable or newer: refused, never overwritten); a
  first-start setup page on 127.0.0.1 with the pages' guard (library, staging and data folders checked, the
  adapter from this PC's own, the viewer, the collector's path for the VPN's list); already open: the pages
  opened and the launcher ends; an orphan collector found by the watchdog's marker, its name and start time,
  with "Stop what is left" (a clean Ctrl-C through a helper start of the launcher itself; a kill only on a
  second, explicit click); one public-address lookup (20 s bound); the watchdog hidden with the collector as
  its child and the same flags as today's script; the viewer by the setting (default the window); a status
  page; nothing restarted by the launcher. `deploy/folder/make-folder.sh` (six programs under their commit's
  name; never touches the settings, `data` or `tools`; refuses while a collector or watchdog runs from the
  folder). 16 tests on stand-ins (the test binary under the programs' names), 5 mutations caught; run as the
  owner will on a scratch folder with stand-ins: three faults found and fixed (every form POST refused with
  403 under `Referrer-Policy: no-referrer`; a second open showing the launcher's page; a killed watchdog's
  collector not said). **Departures:** the setup also asks for the data folder; a fixed launcher address
  127.0.0.1:8786 (also the guard against two launchers); "Try again" on failure pages; "already open" is
  told by the pages' title text (it asks the pages for a fixed marker: mine, `internal/server`, a small
  follow-up); the viewer's command lines come from the programs' flags (the `b` scripts' `.ps1` were not
  read). **Not verified: no real collector, watchdog, viewer, window, mpv or VPN was started.** A side effect
  of its try, for the owner if asked: the launcher opened the PC's default browser four times on scratch
  127.0.0.1 ports.
  **My read (23:53):** the command line beside the script's (the same flags; `-no-links -read-back-now` come
  from the settings' extra flags); what it can stop is given to the reviewer as the first point.
  **G6's independent review started 23:53** (a fresh Opus agent, read-only, probes by overlay in
  `wt-pages-review-g6-scratch`): `BRIEF-G6-review.md`; it writes `REVIEW-G6-launcher.md`. **Next after it:**
  its fixes (with a marker header on the pages for "already open", in `internal/server`), the main head
  merged in, once the new package's whole tests and the race detector on `internal/launcher`; entry "G6"; a
  waiting-list item for the owner's first real start of the folder (it needs the folder built by the
  integrator and the VPN's entry changed once to the new path of the collector).
- 23:55: **G4's coder HANDED BACK: `wip/pages-g4` 1929057a in `wt-pages-g4`, on the main head 2ea9b465, pushed,
  clean** (19 files, about 3,500 lines; its account with the seam and the collector's interface written out
  for the mirror track: `archiver/docs/progress/pages-g4-REPORT.md`). Built to the mirror's message 77 (not
  75): `server.Mirrors` (12 methods; refusals are a type with fixed words, never logged), a fake for tests
  and the demo, 10 routes in the guard, `pages/chatmirror.js` and `mirrorwords.js` (the cell in every state;
  the plan in place; the yes's sentence from the plan's request list; the yes carries the plan's token; stop,
  never, allow; the settle words as separate buttons, none preselected; the chosen chats, at most 20, every
  plan shown first), `pages/mirrorsettings.js`, a Mirrors region on the Overview, the adapter over its own
  types between two CONVERSION PLACE marks, handed over by a type assertion in `pages.go`. 18 tests, 6
  mutations, a browser look on the demo at desktop and phone width. **It mirrors nothing: no collector
  implements the door yet (the mirror's M9, `wip/mirror-door`, not merged).** Its doubts: the settle offers
  are decided by equality with the mirror's block words (its own mapping); `TestChatsAskAgainOnKey` failed
  once on a statement count under load.
  **Done by me (23:55):** `DESIGN-G4-mirror-from-page.md` corrected from message 77 and the coder's three
  points; board message 82 (the mirror track: `Offers` and `Stopped` in `ChatState`, an allow does not undo a
  stop, a name-rule check door); **G4's independent review started** (a fresh Opus agent, read-only, probes in
  `wt-pages-review-g4-scratch`): `BRIEF-G4-review.md`; it writes `REVIEW-G4-mirror-page.md`.
  **Plan for G4:** after the review's fixes: the main head merged in, whole `internal/server` and `livepages`
  on Windows once (no race run unless the fixes add concurrent code: the routes keep one small kept answer:
  the reviewer says), entry "G4" for the page side to merge inert; after M9's merge a small round at the
  conversion place with a rig test of one wish carried out on the fake Telegram; then the owner's board item.
  Board message 80 of Core read: the client's local door (piece 3) will give plain collector functions for
  routes of mine (queue a click, cancel, send again, the verdict, a chat's clicks, settings): names with its
  K9b entry; mine to wire when it is listed.
  **Running now:** three reviewers (G3's second pass, G6, G4) and the G2c coder (`wt-pages-g2c`).
- 11-16 00:03: **G2c's coder HANDED BACK at 23:58: `wip/pages-g2c` abda0d40 in `wt-pages-g2c`, on 10a9e3a8, pushed,
  clean**: all nine findings of the second pass fixed (the retry's pick on a reader, one write by key `NOT
  INDEXED` with every condition repeated: 8 to 26 ms where the writer was held 246 to 314 ms; the file-by-file
  list inside the lists' reading; no reread of the costly part; fixed bounds and a storm minute in
  `TestOpenPageStatementsBounded`; the minors as pure functions with a node test). **Full runs, once:** gofmt
  and vet clean; whole `internal/server` on Windows ok, 149.8 s; `TestE2EPages` and
  `TestPagesRetryGroupDownloads` ok by name (`runs-pages-g2c/win-abda0d40.log`); **the race detector on
  `internal/server` runs since 23:59** (container `p3-g2c-race-server`, bound 60 m, log
  `runs-pages-g2c/race-server-abda0d40.log`, a background command of this session). **Entry "G2c" is written,
  NOT READY until that run ends in "exit 0": then change its line that starts "G2c-STATE" to READY with the
  seconds and say so in the row.** No independent pass on this small round (the entry says so).
- 11-16 00:03: **the sign-in page's second independent pass is BACK: `REVIEW-G3-signin-2.md`, 1 must fix, 3
  should, 6 minor** (13 of the 18 first findings closed, 4 partly, one only a real browser can show). Must:
  nothing can stop the program while a sign-in step hangs (the step holds the sign-in lock for its whole
  request; the Quit route and the stopper's hold wait on it; "Quit now" and ForceStop did not end it in the
  probe; it was in G3 before the fix round). Should: a refusal is not remembered across a reopen or a reload
  (the phone step comes back); one failed poll during a held stop locks the dialogue; the new `Shutdown` in
  the pages' stop waits for idle connections (6.4 s against 12 ms with one spare connection). **Its second
  fix round (G3c) is with the SAME coder agent since 00:03** (resumed by message; it has the context): the
  ten findings, then the main head merged into `wip/pages-g3-main`, its named tests. **Next after its
  hand-back (no third review pass: the reviewer's probes P6 and P7 become named tests; I read the stop's
  path myself):** ONCE: whole `internal/collector`, `internal/server`, `internal/collector/livepages` on
  Windows; the race detector on the whole collector (bound 150 m, 82 minutes last time) and on the server
  (60 m); entry "G3"; the owner's waiting-list item for the first real sign-in from the page.
  **Running now:** the G3c coder, the reviews of G6 and G4, the race run of G2c.
- 11-16 00:10: **G4's independent review is BACK: `REVIEW-G4-mirror-page.md`, 3 must fix, 13 should, 12 minor, and
  7 lines of the owner's page not true of the page.** Must: (1) "Mirror the chosen chats" ends the owner's
  stop without saying so (a stopped chat's cell offers "Mirror this chat" and the bulk yes takes it); (2) a
  settle word names neither the block nor the batch it was chosen for (a rebuild can leave the keyboard on
  the same key for a new block); (3) for a contradiction the page offered "settle by the rules", which
  cannot settle it. **Its fix round (G4b) is with the SAME coder agent since 00:10** (resumed by message): the
  three decided as: a stopped, never or ended chat left out of the chosen chats and said; the word carries the
  plan's token and the block word, refused when moved; the offers from one table with a test per block word
  (fail closed for an unknown word); every should and minor; four lines of the owner's page made true in the
  page. No merge of the main head yet (the mirror's door first). **Done by me:** the owner's page corrected
  (it has mirrored nothing yet; the full list of row words; the chosen chats' cap and what is left out; the
  allow's words; the create-not-made word); board message 83 to the mirror track (the settle word needs the
  token or the batch; the offers table to confirm or replace by `Offers`; "Stop mirroring" is true only once
  the reader stops for an ended want). **Running now:** the coders of G3c and G4b, the review of G6, the race
  run of G2c.
- 11-16 00:18: **G6's independent review is BACK: `REVIEW-G6-launcher.md`, 2 must fix, 9 should, 13 minor** (the
  tree untouched; probes in `wt-pages-review-g6-scratch`). M1 (probe): every child is started hidden, and
  Windows turns a hidden child's first "show window" into "hide": with the default viewer the native
  window would run unseen. M2 (a failed run and probes): while waiting for the pages the launcher binds the
  pages' port itself, and the collector binding at that moment ends with code 2: a false "the collector
  refused" 3 times in 95 starts. Should: "already open" accepts any tgarchive pages on the address (also
  the test account's started by `a3-start.ps1 -Pages`); a leftover collector is told by name only; kills and
  Ctrl-C go by process number after the check; the viewer is closed on any end of the watchdog; the build
  script checks for a running collector before its 80 s build and accepts any folder; the tests' clean-up
  kills by number with a name check (it could hit the owner's real collector); and 13 minors.
  **Its fix round (G6b) is with the SAME coder agent since 00:18** (resumed by message), decided as: children
  started with no console window and without the hide flag; never a bind in the wait; "already open" =
  this folder's own watchdog running (status, marker, name, start time) and the pages answering, and the
  launcher then follows that watchdog; a response header `X-Tgarchive-Pages: 1` on the app's pages (one line
  in `internal/server`, allowed to this coder) instead of the title text; a leftover collector ours only by
  its program file, name and start time; every stop by a process handle held from the check; the viewer
  closed only after exit code 0; the build script's checks right before the replace and a marker file for
  "a folder it made"; tests never signal by number; the package's whole tests three times. **After its
  hand-back:** my read of what it can stop; the main head merged in; once: `internal/launcher` whole and
  under the race detector ON WINDOWS if the toolchain allows (`go test -race` needs cgo on Windows: else in
  the Linux container for the parts that build there, said in the entry), `internal/server` whole (the
  header); entry "G6"; the owner's waiting-list item (the folder built by the integrator, the VPN's entry
  changed once, the first real start).
  **Running now:** the coders of G3c, G4b and G6b, the race run of G2c.
- 11-16 00:18: **G2c is READY** (`MERGE-QUEUE.md` entry "G2c", `wip/pages-g2c` abda0d40): the race detector on
  `internal/server` ended ok, 1,107 s, exit 0, no data race. Waiting for the integrator's merge. **Running
  now:** the coders of G3c (`wt-pages-g3m`), G4b (`wt-pages-g4`) and G6b (`wt-pages-g6`); no container, no
  reviewer.
- 11-16 00:28: **G3c's coder HANDED BACK at 00:26: `wip/pages-g3-main` 0926a727 in `wt-pages-g3m`, pushed, clean; it
  holds the main head dbc2f7d5 (a plain merge, a8275cfd, met no file).** The second pass's findings fixed with
  named tests and six mutations: M-1 every sign-in step from the pages runs on a context that `ForceStop`
  cuts, bounded at 150 s; the page is answered when that context ends even if the step ignores it; nothing on
  the stop's path waits on the sign-in lock for good (250 ms patience, then "pending" unless forced;
  `closeSignIns` gives up after 10 s); S-N1 a refusal is kept per account until the owner's next step; S-N2 a
  failed poll during a held stop says "not answering: trying again"; S-N3 `pages_conns.go`: idle
  connections closed at once, only answers in flight waited for, `Shutdown` gone; the minors. **My read:**
  `signInPending`, `holdForSignIn` (force watched before every look; a held lock is "pending" unless
  forced): sound by reading. No third review pass (the reviewer's probes P6 and P7 are named tests now).
  **FULL RUNS STARTED 00:28, once, on 0926a727 (`runs-pages-g3/`; said first on the board row: both packages
  changed concurrent code, so both get the detector):** (a) the race detector on the whole
  `internal/collector`: container `p3-g3-race-collector`, 2 CPUs, 4 GB, bound 150 m, log
  `race-collector-0926a727.log`; (b) one background command after another: gofmt, vet, whole
  `internal/server` and `livepages`, whole `internal/collector` on Windows (`win-0926a727.log`), then the race
  detector on `internal/server` and `livepages` (container `p3-g3-race-server`, bound 60 m,
  `race-server-0926a727.log`). Each log ends in "exit N". **If this session ended meanwhile:** read the three
  logs; a log cut short: run that one again (`bash ix-tools/race-archiver.sh "$PWD/wt-pages-g3m"
  ./internal/collector 2 4g 150m`); all clean: write entry "G3" (the piece: sign in from the Accounts page, an
  account added while the program runs, a held Quit; two reviews with two fix rounds; one account may wait
  for its sign-in at a time; not verified: a real browser's password manager, anything against Telegram) and
  the owner's waiting-list item for the first real sign-in from the page on the test account.
- 11-16 00:28: **G4b's coder HANDED BACK at 00:27: `wip/pages-g4` 9c98e3dd in `wt-pages-g4`, on 2ea9b465, pushed,
  clean:** the three must-fixes (stopped, never and ended chats left out of the chosen chats and said; a
  settle word carries the token and the block, its buttons inside the plan box with keys that name block and
  batch; the offers from one tested table, fail closed), S1 to S13, the minors but one; 26 mirror tests,
  seven mutations, a browser look with real clicks. **Decided: G4 is NOT listed inert.** It waits for the
  mirror's door (M9 `wip/mirror-door` with its round M9b), then ONE conversion round, one pass of the same
  reviewer over the fix round and the conversion, one set of full runs, its entry. **What the conversion
  round must take from the mirror's message 84:** `MirrorSettleWord(ctx, account, chat, word, block)` with
  `block` the opaque token from `ChatState.Block` (NOT the plan's token: that one changes with every new
  message); `ChatState` gains `Offers`, `Stopped`, `Block` and loses `Choice` (the page takes `Offers`, the
  table stays only as the fail-closed fallback); `MirrorAllow` leaves the owner's stop; `MirrorCheckNameRule`
  exists (check before storing); the owner's page keeps its mark on "Stop mirroring: nothing more for that
  chat" until the mirror says both halves are merged. Watch the queue for entry "M9" merged, then resume the
  G4 coder agent by message (or a fresh coder from `pages-g4-REPORT.md`, which lists the lines to change).
- **G2c is merged** (dbc2f7d5, the integrator). **Running now:** G3's three runs, the G6b coder.
- 11-16 01:02: **G6b's coder HANDED BACK at 00:55: `wip/pages-g6` 3a2981b5 (on 27a7d4dc), every finding of
  `REVIEW-G6-launcher.md` fixed with named tests** (M1 children started with `CREATE_NO_WINDOW` and no hide
  flag: a stand-in's window is visible and the clean Ctrl-C still ends it; M2 no bind while waiting: 2,000
  binds beside the launcher's look, none refused; "already open" = this folder's watchdog alive and the
  pages answering, told by a header `X-Tgarchive-Pages: 1` added in `internal/server/server.go`; ours only
  by resolved image path, name and start time; every stop through one handle opened at the check; the viewer
  closed only on exit code 0; `make-folder.sh` refuses foreign folders (a marker file `folder.version`) and
  checks for running programs before each move; tests end only their own job object; "Wait longer"; the
  minors but one). Two flakes found by its three whole runs and fixed. It ran it as the owner will again on
  a scratch folder with stand-ins (Windows reported the stand-in window visible; nobody saw it by eye).
  **Done by me:** the main head merged in (1214ce26, a plain merge, no conflict); my read of the handle
  path; **runs on the merged tree (`runs-pages-g6/`):** gofmt and vet clean, a build of everything, whole
  `internal/launcher` on Windows ok 34 s, whole `internal/server` ok 166 s; the race detector in the Linux
  container: three tests that start a Windows program FAILED there (not skipped off Windows): fixed by me
  (a skip each, test files only: 19a64824, pushed; the package ok again on Windows, 36 s); then 8 passed, 23
  skipped, 0 failed, no data race. **The Windows process tests cannot run under the detector here** (a
  Windows race build needs a C compiler; there is none): the entry says so.
  **Its second independent pass started 01:02**, continued in the SAME reviewer agent: it writes
  `REVIEW-G6-launcher-2.md` (its 24 findings closed or not; what the fixes opened: the handle path, the
  Ctrl-C helper, "this folder's" by image path, following a watchdog it did not start, a console window
  that may now flash, the header as the mark). **Next after it:** its fixes if any (resume the G6 coder
  agent), the launcher's whole tests once more, entry "G6" (new files plus one line in `server.go`; it
  merges anywhere), and the owner's waiting-list item: the folder built by the integrator with
  `archiver/deploy/folder/make-folder.sh <output folder>`, the VPN's entry changed once to the new path of
  the collector, the first real start by a double-click.
  **Owed, small, mine, after G3 is merged (it changes the same file):** the header `X-Tgarchive-Pages` on the
  collector's three own answers (starting, no pages, stopping) in `internal/collector/pages.go`.
- 11-16 01:02: **G3's Windows runs ENDED: gofmt and vet clean; whole `internal/server` and `livepages` ok; whole
  `internal/collector` ok, 758.9 s (`runs-pages-g3/win-0926a727.log`).** Still running: the race detector on
  the whole collector (`p3-g3-race-collector`, since 00:28) and on the server (`p3-g3-race-server`).
- 11-16 01:04: **G3's race run of `internal/server` and `livepages` ENDED: ok (1,270 s and 1 s), exit 0, no data
  race** (`runs-pages-g3/race-server-0926a727.log`). Left of G3's runs: the race detector on the whole
  collector (`p3-g3-race-collector`, since 00:28, bound 150 m). When it ends in "exit 0": entry "G3".
- 11-16 01:10: **G6's second independent pass is BACK: `REVIEW-G6-launcher-2.md`, no must fix, 4 should, 7 minor**
  (20 of the 24 first findings closed, 3 partly, 1 not built as decided; M1 and M2 closed by probe). Should:
  N1 (probe) a folder reached through a junction is never "this folder's" (paths compared as text); N2
  (probe) the launcher's reads of the watchdog's status file make the watchdog's rename fail; N3
  `make-folder.sh` can leave a half-replaced folder and say "nothing was changed"; N4 the collector's
  starting, no-pages and stopping answers carry no mark. **Its last small round (G6c) is with the SAME coder
  agent since 01:10**: file identity instead of text; shared reads of the status file; the script all or
  nothing with an `updating` marker the launcher heeds; the three answers known by their fixed words until
  the header is there; the minors; a bind guard that fails for certain. No third review pass (no must fix).
  **After its hand-back:** whole `internal/launcher` on Windows once and the Linux race run of what runs
  there, then entry "G6" READY and the owner's waiting-list item.
- 11-16 01:20: **the owner's rule read (the integrator's message; `CLAUDE.md`'s archiver section, second point; the
  board's new section): routine steps go to ONE Sonnet clerk call or a script, never call by call in this
  session.** Until now this session ran them itself (named tests, the full runs' starts, merges, commits of
  the notes, the PC's measurements): not by a Sonnet clerk. From here: G3's entry after its race run, G6's
  runs and entry after G6c, the notes' commits and the PC's measurements go to a clerk on an exact
  instruction; what stays mine: the briefs, the read of the risky part, judging the reports, the run plan,
  the entries' and commit messages' words. (This entry: a single command.)
- 11-16 01:41: **G6 is LISTED and READY: `MERGE-QUEUE.md` entry "G6", `wip/pages-g6` 04b39389** (it holds dbc2f7d5;
  the main head has moved on to 698ee15d: the integrator applies the difference). How it got here since
  01:11: the G6c coder handed back fed993fe at 01:30 (N1 file identity; N2 on the launcher's side only: the
  watchdog's rename over its status file is refused about half the time while anything reads it, and that is
  the watchdog's to cure: board message 86 to Core; N3 the script puts back or says "half replaced", an
  `updating` marker; N4 the collector's three answers known by their words with a test against `pages.go`; a
  bind guard that fails for certain). **Runs by a Sonnet clerk on an exact instruction** (two calls): gofmt,
  vet and a build clean; whole `internal/launcher` ok on Windows (40.2 s, then 43.5 s on 04b39389); whole
  `internal/server` ok (160.9 s); the Linux race run first failed on three new tests that need Windows; my
  script (`g6_skip_off_windows.py` in the scratchpad) added the skips, the clerk ran it, reran both, committed
  and pushed 04b39389: 11 passed, 34 skipped, 0 failed, no data race. The entry, the owner's item 31 and
  message 86 are my words, written in one command (not a clerk: a single command).
  **Open for G6:** the integrator builds the folder and writes its path on item 31; the owner's first real
  start; my header on the collector's three answers after G3 merges; stage B (the copy's choices and the
  helper's address onto the Settings and Staging pages; they ride in the settings' extra flags today).
  **Running now:** only G3's race run of the whole collector (`p3-g3-race-collector`, since 00:28).
- 11-16 02:01: **G3's race run of the whole `internal/collector` ENDED at 02:00: FAIL after 5,563 s, ONE test, no
  data race** (`runs-pages-g3/race-collector-0926a727.log`): `TestAddAccountWhileRunning`
  (`signin_pages_test.go:691`): "account 3's task: {Runs:0 ... Running:false}". Read by me: the test waits
  for the account's state "not signed in", which the account has from the moment it is made, and then looks
  ONCE whether its task runs; under the detector the task's goroutine had not run yet. The add itself starts
  the task under the collector's lock (read before; sound): a test that looks once at a goroutine's start,
  not a fault of the add. Every other test of the 93 minutes passed, `TestE2EPages` too (the fake's topics
  answer is repaired on this head). **Fix, test file only:** the look becomes a wait (`r.eventually`, 30 s as
  an upper bound). By my script (`g3_task_wait.py` in the scratchpad) and **a Sonnet clerk on an exact
  instruction, running since 02:01**: the script, gofmt, vet, the test by name 3 times on Windows and 5 times
  under the detector in a container (`p3-g3-race-addaccount`), then commit and push only if both are clean.
  No second whole race run of the collector (a test-only change). **Then:** entry "G3" and the owner's item.
  **G6 is merged** (5b29e28b, the integrator).
- 11-16 02:04: **G3 is LISTED and READY: `MERGE-QUEUE.md` entry "G3", `wip/pages-g3-main` 884c3ce3.** The clerk's
  report (a Sonnet clerk, one call): the script replaced the look by a wait; gofmt and vet clean;
  `TestAddAccountWhileRunning` by name 3 of 3 on Windows, 5 of 5 under the detector (40.7 s), no data race;
  committed and pushed 884c3ce3. The entry and the owner's item 32 (the first real sign-in from the page)
  are my words, written in one command.

### STATE FOR A TAKE-OVER (P3, 11-16 02:04; this block replaces the one of 11-15 21:58 above)
Read `BOARD.md` (my row; messages 75, 77, 82 to 84, 86; items 30 to 32 of the waiting list), then this block.
1. **Merged and installed:** G1, "G1s", G2, G2c; **merged:** G6 (5b29e28b; the folder is the integrator's to
   build, the owner's first real start is item 31). **Listed, READY, waiting for the integrator:** "G3"
   (`wip/pages-g3-main` 884c3ce3; item 32).
2. **The mirror page (G4), `wip/pages-g4` 9c98e3dd in `wt-pages-g4` (on 2ea9b465):** built and reviewed once
   (`REVIEW-G4-mirror-page.md`), its fix round done; NOT listed: it waits for the mirror's door (entry "M9"
   with its round M9b, branch `wip/mirror-door`). When that is merged: ONE conversion round (resume the G4
   coder agent if this session still lives, else a fresh Opus coder from `pages-g4-REPORT.md`, which names
   the lines): the adapter's types become the mirror's; `MirrorSettleWord(ctx, account, chat, word, block)`
   with `ChatState.Block`; `Offers` and `Stopped` from `ChatState`; `MirrorCheckNameRule` before storing; the
   main head merged in; a rig test of one wish carried out on the fake Telegram. Then one pass of a reviewer
   over the fix round and the conversion, the full runs once (whole `internal/server` and `livepages` on
   Windows; the race detector on `internal/server`: `/api/mirrors` keeps an answer; the collector only by
   the named rig test unless the conversion adds collector code), entry "G4", and the owner's item for the
   first real click (item 30 has the one page; it still carries one marked line about "Stop mirroring").
3. **Next new pieces, in the order of board message 73 (c):** the Staging page (G5: `BRIEF-G5-staging-page.md`
   with its last section; cut `wip/pages-g5` ANEW from the main head: the old branch at ee437a46 holds only
   a progress note; tell the coder the head instead of ee437a46 and that the sign-in seam and the mirror
   seam now exist beside it); the client's local door's routes when Core lists K9b (message 80); the
   backup's button (Core's K6 is merged: a page control is listed in message 73 group 4); stage B of the
   folder (the copy's choices and the helper's address onto the Settings and Staging pages).
4. **Small, mine, owed:** the header `X-Tgarchive-Pages` on the collector's three own answers in
   `internal/collector/pages.go` (after G3 is merged); the read-only schema door in `cmd/tgarchive/app.go`; a
   word for a protected chat on its row (K4 is merged); the watchdog's state on the Overview.
5. **How routine steps are done since 01:20:** one Sonnet clerk call on an exact instruction, or a script
   (two are in this session's scratchpad and may be gone: they are five lines each); the briefs, the read of
   the risky part, the judging of reports, the run plan and the entries' words stay with the main session.
6. **Nothing of this session is running now**: no agent, no container, no test pages. Copies that can go
   when their branches are merged: `wt-pages-g1`, `-g1-look`, `-scroll`, `-g2`, `-g2m`, `-g2c`, `-g3`, `-g6`,
   `-g5` (old); scratch folders `wt-pages-g1-probe-scratch`, `wt-pages-review-g2-scratch`, `-g2b-`, `-g3-`,
   `-g4-`, `-g6-`; run logs `runs-pages-g1b`, `-g2`, `-g2c`, `-g3`, `-g6`.
- 11-16 02:05: **G5 (the Staging page) is with a coder** (one Opus agent, high effort, a background agent of this
  session): it makes a NEW copy `wt-pages-g5m`, branch `wip/pages-g5-main`, from the main head (the brief's
  last section says ee437a46 and `wip/pages-g5`: its start message overrides both and adds the Queue page's
  later rules). If this session ended: its state is `archiver/docs/progress/pages-g5-PROGRESS.md` on that
  branch; a fresh Opus coder goes on from it with the same brief and the overrides written here: the new
  copy and branch; own new files for its seam, routes and scripts, its lines at the end of shared lists
  (the sign-in and mirror seams are not on the main head yet); every script under 600 lines; a click's
  pick is a read and its write by key; rows that carry a click from the same reading as the counts; a storm
  minute with fixed bounds in its poll test; tests that need Windows skip off Windows. After its hand-back:
  my read, one independent review, its fixes, the full runs once by a clerk (whole `internal/server` and
  `livepages` on Windows, the race detector on `internal/server`), its entry.
  **My row says READY FOR A TAKE-OVER** (this session's context is long: the integrator's rule of board
  message 74 b). The take-over block above holds; add to its point 3: G5 is with a coder as said here.
- 11-16 02:43: **G5's coder HANDED BACK at 02:41: `wip/pages-g5-main` 84d9991a in `wt-pages-g5m`, on the main head
  5b29e28b, pushed, clean** (24 files, about 3,000 lines; its account: `archiver/docs/progress/pages-g5-REPORT.md`).
  Built: a fourth seam `server.Staging` (nil in the app alone), the adapter `livepages/staging.go`, a
  read-only source `collector/pagesstaging.go` and one line in `pages.go`; one verdict line in fixed words,
  ordered by what needs the owner first; the queue's numbers each with what it counts and its reading's
  time; this hour and the last 24; "What needs you": stuck files with "Try its copy again" (one statement by
  key on the ledger: `stuck = 0, next_try = 0`; 409 when no longer stuck), wanting-again held with "Let it
  go on", staging without room and the library away for 10 minutes, the library's disk full; `/api/live`
  carries the store's gauges and reads no table; the queue read by its floor (5 s, 30 s when slow). 13
  tests, 5 mutations, a rig test (the library away and back), a browser look at two widths (five faults found
  and fixed). Its doubts: 202 ms a reading at 100,000 ledger rows on a busy PC, close to the 250 ms line; the
  copier's gauges read the queue a second time (2 statements); the shared files the G3 and G4 merges meet.
  **G5's independent review started 02:43** (a fresh Opus agent, read-only, probes in
  `wt-pages-review-g5-scratch`): `BRIEF-G5-review.md`; it writes `REVIEW-G5-staging.md` (first asked: is the
  verdict true in every state of the store; is un-sticking safe for every reason a file is stuck). **After
  it:** its fixes (resume the G5 coder agent, or a fresh coder), the main head merged in, the full runs once
  by a clerk (whole `internal/server` and `livepages` on Windows, the rig test by name, the race detector on
  what the reviewer names), entry "G5".
- **Read 02:43, board messages 88, 89 and 92: three things owed by pages for the launcher (G6, merged), one
  small follow-up branch from the main head once Core's K12 (`wip/core-wdrename`) is merged:** (1)
  `internal/launcher/status.go` and `findLeft` read `watchdog-status.json` ONCE: a reader can get "not
  found" or a refused open for an instant at each rename, so the launcher can show "a collector runs
  without its watchdog" wrongly: read through the door K12 exports in `internal/watchdog` (delete sharing,
  read again within about 100 ms), or read again a few times 20 ms apart; (2) the viewer and the window take
  `-staging FOLDER` (the viewer's `wip/b-staged`): the launcher hands them the settings' staging folder; (3)
  the header on the collector's three own answers (after G3 merges). Core's 89 (d): the client's routes are
  mine to wire; the collector's entry points are section 9 of `archiver/docs/progress/core-turn-REPORT.md` on
  `wip/core-turn` (entry "K9b" when listed).
- 11-16 02:56: **G5's independent review is BACK: `REVIEW-G5-staging.md`, 2 must fix, 7 should, 14 minor** (the
  tree untouched; probes in `wt-pages-review-g5-scratch`). M1 (probe): with the library away or full the
  verdict always ends "downloads go on into staging", also when staging has no room or is away and downloads
  in fact stop (the author's test expected the false sentence). M2 (probe): the release of "wanting again"
  reaches the store when nothing is held, and every release sets the hour's count back to 0: a stale tab
  widens the cap of 20 re-downloads an hour. Should: the speed counts only verified bytes (0.0 while all
  copiers copy); "no room" is the page's guess; "staging away" stays until the next download opens; one
  sentence for several causes of "files wait, none busy"; wrong advice for an "unreadable" stuck file;
  the release's cost not said; the copiers' sentence. **Un-sticking is safe for every reason a file is
  stuck** (the review's table: it never publishes bad bytes, never replaces a library file, never loops).
  **Its fix round (G5b) is with the SAME coder agent since 02:56** (resumed by message; decided as: the
  verdict's clause from the staging side; 409 unless held, the cost on the button; each number saying what it
  counts; causes split; a table of stuck reasons with true advice and no button where a retry cannot help;
  the minors; then the main head merged in). **After its hand-back, by a clerk, once:** whole
  `internal/server` and `internal/collector/livepages` on Windows; the race detector on `livepages` whole
  and, by name, the new parallel server test and `TestStagingPageLibraryAway` (the reviewer: no whole race
  run of the server or the collector is needed for this piece); then entry "G5". No second review pass
  unless the round departs from what was decided.
- 11-16 02:59: **G3 was HANDED BACK by the integrator, not merged** (its message; the main head is d10e3bd): on the
  combined tree the whole collector failed on `TestSignInRemovalCannotCrossCodeRequest/request_first`: the
  removal was refused, but in the words of a sign-in awaiting its code, not "A sign-in step is under way
  now". **Read by me: the integrator's reading is right, and it is the test's order, not the product's
  words.** The subtest let the held code request go right after starting the removal's goroutine; when the
  request ended first, the removal met a sign-in already awaiting its code and was refused for that (also
  right: the account is not removed either way). Fix, a test file only: the removal's answer is taken while
  the request is still held before its dial (the removal is refused at once, it never waits), then the
  request is let go. **By my script (`g3_removal_order.py` in the scratchpad) and a Sonnet clerk on an exact
  instruction, running since 02:59:** a plain merge of the main head into `wip/pages-g3-main` (it stops on any
  conflict), the script, gofmt, vet, a build, that test by name 20 times, then ONCE whole `internal/server`,
  `livepages` and `internal/collector` on Windows, commit and push only if all are clean. No race run (a
  test-only change; the merge brings code the other tracks raced on their own trees). **Then:** the new head
  and these runs into entry "G3" (my words).
- 11-16 03:18: **G3 is LISTED AGAIN, READY: `wip/pages-g3-main` f43f140b, holding the main head d10e3bd9.** The
  clerk's report (a Sonnet clerk, one call): the merge of d10e3bd9 was clean (a61346ef; `server.go` merged by
  itself); my script replaced the subtest's order; gofmt, vet and a build clean; the test by name 20 of 20;
  whole `internal/server` ok 152.6 s, `livepages` ok, whole `internal/collector` ok 811.9 s; committed and
  pushed f43f140b. Entry "G3" now leads with this (my words, one command); the integrator's hand-back note
  is kept after it.
- 11-16 03:20 (about): **G5b's coder HANDED BACK: `wip/pages-g5-main` 7739148c, holding the main head 8aed433d
  (merge d9806d5c, no conflict).** Every finding of `REVIEW-G5-staging.md` fixed with a test (the verdict's
  clause from staging's state; the release refused unless held, its cost on the button; the speed saying
  what it counts; the waiting causes split; a table of stuck reasons, no button for a bad hash record; the
  minors but one, said as a doubt), four mutations, a browser look. Departures: the stuck table keyed by the
  store's stop reason; a third clause when staging's free space is not read yet; the unstick route reads the
  row before its one write. No second review pass (it did what was decided). **Its full runs are with a
  Sonnet clerk (one call, running):** gofmt, vet, a build, whole `internal/server` and `livepages` on Windows,
  three rig tests by name, then in a container the race detector on `livepages` whole and by name
  `TestStagingConcurrentRequests`, `TestStagingLiveReadsNoTable`, `TestStagingPollStatementsBounded` (server)
  and `TestStagingPageLibraryAway` (collector): logs `runs-pages-g5/win-7739148c.log`, `race-7739148c.log`.
  **Then:** entry "G5" (my words). For Core, from its report: a statement-free accessor for the copiers'
  busy and allowed numbers, bytes counted as they are written, "full since" for staging; `/api/live` takes
  the store writer's lock through `StagingState`.
- 11-16 03:19: **G5 is LISTED and READY: `MERGE-QUEUE.md` entry "G5", `wip/pages-g5-main` 7739148c (holding 8aed433d).**
  The clerk's report (a Sonnet clerk, one call): gofmt, vet, a build clean; whole `internal/server` ok 147.1 s,
  `livepages` ok; three rig tests by name ok; in the container the race detector on `livepages` whole and the
  three server tests by name 3 of 3, the collector's `TestStagingPageLibraryAway`: all ok, no data race.
  The entry and board message 94 (Core: three things the store could give; the integrator: G3 first, then
  G5) are my words, written in one command.

### STATE FOR A TAKE-OVER (P3, 11-16 03:19; this block replaces the one of about 02:10 above)
Read `BOARD.md` (my row; messages 75, 77, 82 to 84, 86, 88, 89, 92, 94; items 30 to 32 of the waiting list), then
this block.
1. **Merged:** G1, "G1s", G2, G2c, G6 (the folder is built by the integrator: item 31 has its path; the
   owner's first real start is open). **Listed, READY, waiting for the integrator, in this order:** "G3"
   (`wip/pages-g3-main` f43f140b, holding d10e3bd9; the owner's item 32) and "G5" (`wip/pages-g5-main`
   7739148c, holding 8aed433d). If either is handed back: read the integrator's note at the entry's front.
2. **The mirror page (G4), `wip/pages-g4` 9c98e3dd in `wt-pages-g4` (on 2ea9b465):** built, reviewed, its fix
   round done; waits for the mirror's door (entry "M9", branch `wip/mirror-door`, with its round M9b). When
   that is merged: ONE conversion round by a fresh Opus coder from `archiver/docs/progress/pages-g4-REPORT.md`
   (it names the lines; the agent that built it lives only while this session does): the adapter's types
   become the mirror's; `MirrorSettleWord(ctx, account, chat, word, block)` with `ChatState.Block`; `Offers`
   and `Stopped` from `ChatState`; `MirrorCheckNameRule` before storing; the main head merged in (it meets
   G3's and G5's lines in the shared lists); a rig test of one wish carried out on the fake Telegram. Then
   one reviewer pass over the fix round and the conversion (`REVIEW-G4-mirror-page.md` is the first), the
   full runs once by a clerk (whole `internal/server` and `livepages` on Windows; the race detector on
   `internal/server` whole: `/api/mirrors` keeps an answer; the collector by the rig test's name), entry
   "G4", and the owner's item for the first real click (item 30 has the one page,
   `DESIGN-G4-mirror-from-page.md`; one line of it stays marked until the mirror says the reader stops for an
   ended wish).
3. **One small follow-up branch for the launcher, from the main head, after G3 is merged** (board message 94
   d): `internal/launcher/status.go` and `findLeft` read the watchdog's status file through the door K12
   exports in `internal/watchdog` (or read again a few times 20 ms apart on "not found", a refused open or
   a body that does not parse); the viewer and the window get `-staging <the settings' staging folder>`
   (when the viewer's `wip/b-staged` is merged); the header `X-Tgarchive-Pages: 1` on the collector's three
   own answers in `internal/collector/pages.go` (then the launcher's `collectorwords.go` can go). Small and
   exact: one Opus coder, the launcher's whole tests, the collector's pages tests by name.
4. **Next new pieces (board message 73 c):** the client's routes on the listener when Core lists "K9b" (the
   collector's entry points: section 9 of `archiver/docs/progress/core-turn-REPORT.md` on `wip/core-turn`;
   the viewer has its seam for the compose box: messages 90, 91); the backup's button (K6 is merged); stage
   B of the folder (the copy's choices and the helper's address onto the Settings and Staging pages); the
   read-only schema door in `cmd/tgarchive/app.go`; a word for a protected chat on its row; the watchdog's
   state on the Overview.
5. **How the work goes:** one Opus coder per brief in its own copy; my read of the risky part; one
   independent Opus reviewer with probes, continued in the same agent for a second pass where the fix round
   rebuilt something that acts for the owner; routine steps (runs, merges, commits, measuring the PC) by ONE
   Sonnet clerk call on an exact instruction, with a small script for an exact edit; the entries' and
   messages' words mine, written in one command with paths built by chr(92) and a scan for control bytes.
6. **Nothing of this session is running now.** Copies that can go when their branches are merged:
   `wt-pages-g1`, `-g1-look`, `-scroll`, `-g2`, `-g2m`, `-g2c`, `-g3`, `-g3m`, `-g5` (old), `-g5m`, `-g6`;
   scratch folders `wt-pages-g1-probe-scratch`, `wt-pages-review-g2-scratch`, `-g2b-`, `-g3-`, `-g4-`, `-g5-`,
   `-g6-`; run logs `runs-pages-g1b`, `-g2`, `-g2c`, `-g3`, `-g5`, `-g6`.
- 11-16 03:55: **the integrator's message: G3 is MERGED (6556113); G5 is handed back for a merge of that head, not
  for a fault** (`git diff 8aed433d 7739148c` on 6556113 conflicts in five files where G3 and G5 both add
  lines: the collector's `pages.go`, `pages_e2e_test.go`; the server's `liveroute.go`, `security_test.go`,
  `server.go`); **M9, the mirror's door, is merged (25816ed, schema step 23).** Started, both by resuming the
  coder agent that built the piece (a merge with conflicts and a conversion need judgement: not a clerk):
  (1) **G5:** the coder merges 6556113 into `wip/pages-g5-main` (both sides stay; it also checks that its two
  change routes are refused by the sign-in page's held stop), runs its named tests, pushes; then a Sonnet
  clerk runs whole `internal/server`, `livepages` and the collector's named tests once; then the new head
  goes into entry "G5" (the integrator then merges, installs and rebuilds the owner's folder with the
  sign-in page and the Staging page in it). (2) **G4, the conversion round (G4c):** the main head merged into
  `wip/pages-g4`; the adapter on the mirror's real types (`MirrorSettleWord` with `ChatState.Block`; `Offers`
  and `Stopped` from `ChatState`; `MirrorCheckNameRule` before storing); a rig test of one wish carried out
  on the fake Telegram; its report gives the corrections for the owner's one page. When G5's new head
  exists I resume the G4 coder once more to merge it in. **After G4c:** one pass of the reviewer of
  `REVIEW-G4-mirror-page.md` over the fix round and the conversion (a fresh agent with that file if the old
  one cannot be resumed), the full runs once by a clerk (whole `internal/server` and `livepages` on Windows,
  the race detector on `internal/server` whole and the rig test by name), entry "G4", the owner's item.
- 11-16 04:03: **G5 is LISTED AGAIN, READY: `wip/pages-g5-main` 639ed1c0, holding the main head 6556113.** Its
  coder merged 6556113 at 03:57 (five conflicts, both sides kept; its own `clockWords` renamed, which clashed
  outside the conflicts; `TestHeldStopRefusesStagingChanges` added). **A Sonnet clerk, one call:** gofmt, vet
  and a build clean; whole `internal/server` ok 150.8 s; `livepages` ok; the collector's named tests ok
  (79.5 s). Entry "G5" leads with this now (my words, one command). **Next:** when the G4 coder hands its
  conversion round back, resume it once more to merge the main head that holds G5 (or `wip/pages-g5-main`
  639ed1c0 if G5 is not merged yet), then the reviewer's pass, the runs by a clerk, entry "G4".
  **Running now:** the G4 coder's conversion round (`wt-pages-g4`).
- 11-16 04:09: **G4c, the conversion round, is HANDED BACK: `wip/pages-g4` 550be61c, holding the main head 6556113**
  (the merge met `pages.go`, `server.go`, `security_test.go`, `api.js`: both sides kept). The adapter is on the
  mirror's real types; the settle word carries `ChatState.Block`; offers only from the door (my earlier
  "table as fallback" was wrong with the real door: an empty `Offers` comes with an empty `Block`; the table
  now only gives the words: agreed); `MirrorCheckNameRule` before storing; a new collector file
  `pages_mirrors.go` wraps the collector for the adapter (an import cycle forced it) with the compile-time
  check. **`TestMirrorPagesWishOnFakeTelegram` (28.9 s): the first mirror made through the pages:** for a chat
  with 173 files the fake saw 1 `channels.createChannel`, 2 `messages.forwardMessages`, 1 `help.getConfig`,
  nothing else; a never mark before the yes refuses it; a stop mid-way of a 1,500-message chat: no write in 5
  minutes of the clock, and an allow leaves the stop; the task ran without `-auto-mirror`. Not done: no
  mutations on the converted code; no whole runs; no race detector. Its doubts: the door's plan does not
  carry the read's cost (the server adds the estimate on record; without one the yes stays off); the door has
  no sign for a word the task dropped.
  **Done by me:** `DESIGN-G4-mirror-from-page.md` rewritten from the door as built (the report's replacement
  lines, in the owner's terms; one line stays marked: a stop does not yet end the reader's read of that
  chat). **The coder is resumed for step 5:** merging `wip/pages-g5-main` 639ed1c0 (the Staging page, listed;
  the main head is still 6556113) into `wip/pages-g4`, both sides kept, its named tests.
  **Next after its hand-back:** resume the G4 reviewer agent (or a fresh one with `REVIEW-G4-mirror-page.md`
  and `BRIEF-G4-review.md`) for one pass over `9c98e3dd`'s fix round and the conversion: the token and block
  paths against the real door, the wrapper, `WaitsFor` (a yes taken while the task waits), the rig test; then
  its fixes; then a clerk, once: whole `internal/server` and `livepages` on Windows, the collector's named
  tests (the rig test, the sign-in set, the staging test), the race detector on `internal/server` whole (60
  m) and the rig test by name; entry "G4"; the owner's item for the first real click (item 30 is the page).
- 11-16 04:12: **G4's coder merged the Staging page's head: `wip/pages-g4` 8bba0348** (it holds 639ed1c0 and the main
  head 6556113; conflicts in `pages.go`, `server.go`, `security_test.go`, `pages/overview.js`: both sides kept;
  its own `name-check` route was missing from both guard lists and is added; a new test
  `TestMirrorHeldStopRefusesChanges`: all ten change routes of the mirror and the Staging page refused during
  a held stop; every named test passes, the rig test with the same request counts). Not looked at in a
  browser after the merge. **The reviewer's second pass started 04:12**, continued in the SAME reviewer agent:
  it writes `REVIEW-G4-mirror-page-2.md` (its 28 findings closed or not; the conversion against the real
  door: the yes and its token, `WaitsFor`, the read's cost for an unread chat, the settle word with the
  block's token, stop, never and allow, the wrapper file, the states' cost; whether the rig test proves what
  it says; the guard lists; the owner's page line by line). **Then:** its fixes (resume the G4 coder), the
  full runs once by a clerk (whole `internal/server` and `livepages` on Windows, the collector's named tests,
  the race detector as the reviewer names it), entry "G4", the owner's item.
- 11-16 04:24: **G4's second review pass is BACK: `REVIEW-G4-mirror-page-2.md`, 1 must fix, 7 should, 8 minor** (25 of
  the 28 first findings closed, 3 partly; 6 lines of the rewritten owner's page not true; the guard lists
  complete; the door's `MirrorStates` 9 statements at 300 mirrors and 200,100 forward rows). **The must-fix
  (N1, a probe on the real door): a chat that was never read cannot be mirrored from the page**: the page
  wants the estimate on record before the yes; with a record there the door's want writes no approval, so
  the reader never reads the chat. The rig test passed only because it wished a chat with no estimate. Also:
  the read's cost is not bound to the yes (N2); the rig test holds less than was said (N7: loose counts, an
  empty never-check, "nothing after a stop" that passes with the task dead, no comparison of the mirror's
  contents); a blocked mirror made by the command; a not-signed-in account's rows; the Overview's counts; a
  stop made in another tab ended by the bulk yes. **Its last fix round (G4d) is with the SAME coder agent
  since 04:24**: the door's want writes the mirror's approval onto the owner's estimate record in its own
  transaction, bound to the request count shown, without choosing the chat for downloads: LENT LINES in the
  mirror track's door, as ONE separate commit (board message 95: the mirror track may take or replace it);
  the rig test made to prove what it says; N3 to N8; the partly closed three; the minors; the page's words;
  the corrected lines for the owner's page in its report. **After its hand-back:** I correct the owner's page
  (my words); a clerk, once: gofmt, vet, a build, whole `internal/server` and `livepages` on Windows, the
  collector's named tests (the mirror rig tests, the sign-in set, the staging test, `TestE2EPages`), and in a
  container the race detector on the tests the reviewer named (`TestMirrorNeverTwoClicksAtOnce`,
  `TestMirrorStatesCostBounded`, the cancelled-poll test, `TestMirrorHeldStopRefusesChanges`,
  `TestMirrorRoutesInGuard` in the server; `TestMirrorPagesWishOnFakeTelegram` in the collector); because the
  round changes the door's want (collector code that the reader's goroutine meets) ALSO the collector's
  `Mirror` tests by name under the detector (say the minutes first); then entry "G4" and the owner's item.
  No third review pass unless the lent lines grow beyond the want's transaction.
- 11-16 04:45: **G4d's coder handed back `wip/pages-g4` 98e3dfe8 at about 04:38** (N1 fixed: `MirrorWantRead` in the
  door, lent lines, one commit cf434aba, 69 lines, read by me: sound; the rig test by the page's own path
  with exact counts and the mirror's contents compared; N2 to N8, the minors; four mutations). **The clerk's
  whole run of `internal/server` then FAILED on one test no named run had included:
  `TestDemoRunWritesNothing`** (`runs-pages-g4/win-98e3dfe8.log`): in the demo every change route must answer
  409 "Demo: nothing is saved."; the eight mirror change routes acted on the in-memory fake. The clerk
  stopped as told (no race run made). **Decided: the demo's rule wins** (the mirror's changes are refused in
  the demo with its words; the demo still shows invented mirrors; a fake that moves is for tests and an
  explicit look only). **With the SAME coder agent since 04:45 (G4e):** that fix, then the WHOLE
  `internal/server` run once by the coder itself (named runs have twice missed a whole-run-only test: the
  script size limit on G2, this one now), the main head merged in (it has moved to a37ed4c3 or later), its
  named collector tests. **Then a clerk again, once:** the Windows runs and the race detector on the
  server's and the collector's mirror tests; then entry "G4". The owner's page is corrected (5aa8748).
- 11-16 04:59: **G4e's coder HANDED BACK: `wip/pages-g4` 9b4e265a, holding the main head a37ed4c3** (which has the
  sign-in page and the Staging page as merged: G5 is merged, 5174cc2f). The demo's rule: every mirror change
  route answers 409 "Demo: nothing is saved." in the demo and nothing moves; the fake that moves is for
  tests only. **Whole runs by the coder (asked this once, after two whole-run-only misses): whole
  `internal/server` ok 149.6 s before the merge and 144.3 s on the merged tree; `livepages` ok; the collector
  by name (every `TestMirror*`, `TestStaging*`, `TestE2EPages`, the sign-in set) ok, 404.7 s, 146 passed.**
  The merge met four files where the head had only the Staging lines the branch already held. Its doubt:
  the branch's history holds two versions of the Staging page (639ed1c0 and the merged 5174cc2f).
  **A Sonnet clerk runs since 04:59 (one call):** a check that the Staging and sign-in pages' own files on
  the branch equal the main head's, then the race detector in a container on the server's `TestMirror*` and
  the collector's `TestMirror*` (log `runs-pages-g4/race-9b4e265a.log`). **Then:** entry "G4" (my words) and
  the owner's item for the first real click.
- 11-16 05:44: **G4 is LISTED and READY: `MERGE-QUEUE.md` entry "G4", `wip/pages-g4` 9b4e265a (holding a37ed4c3).** The
  clerk's report (a Sonnet clerk, one call): the Staging and sign-in pages' own files on the branch equal the
  main head's; the race detector on the server's `TestMirror*` ok 39.8 s and on the collector's `TestMirror*`
  ok 2,526 s, no data race. The entry, board message 96 (the mirror track: the lent lines; the integrator)
  and the owner's item 33 (the first real mirror from the page) are my words, written in one command.

### STATE FOR A TAKE-OVER (P3, 11-16 05:44; this block replaces the one of about 03:25 above)
Read `BOARD.md` (my row; messages 84, 86, 88, 89, 92, 94 to 96; items 30 to 33 of the waiting list), then this
block.
1. **Merged:** G1, "G1s", G2, G2c, G6, G3, G5 (the main head a37ed4c3 holds the Queue, sign-in and Staging
   pages and the launcher). **Listed, READY, waiting for the integrator:** "G4" (`wip/pages-g4` 9b4e265a,
   holding a37ed4c3; 69 lent lines in the mirror's door as commit cf434aba: if the mirror track answers
   message 95 or 96 with another shape, a small round adapts the adapter's one call). If it is handed back:
   read the integrator's note at the entry's front; a merge of the head is a coder's (judgement), the runs a
   clerk's.
2. **For the owner, open:** item 31 (the first real start of the folder), 32 (the first real sign-in from the
   page), 33 (the first real mirror from the page; its one page is `DESIGN-G4-mirror-from-page.md`, item 30,
   with one line still marked until the mirror says the reader stops for an ended want).
3. **One small follow-up branch for the launcher, from the main head** (board message 94 d; nothing started):
   the watchdog's status file read through the door K12 exports in `internal/watchdog` (K12 is merged) in
   `internal/launcher/status.go` and `findLeft`; the viewer and the window started with `-staging <the
   settings' staging folder>` (the viewer's staged-files piece is merged: a37ed4c3); the header
   `X-Tgarchive-Pages: 1` on the collector's three own answers in `internal/collector/pages.go` (then
   `collectorwords.go` in the launcher can go). One Opus coder on a short brief; the launcher's whole tests
   and the collector's pages tests by name through a clerk; an entry.
4. **Next new pieces (board message 73 c):** the client's routes on the listener when Core lists "K9b" (the
   collector's entry points: section 9 of `archiver/docs/progress/core-turn-REPORT.md` on `wip/core-turn`);
   the backup's button; stage B of the folder (the copy's choices and the helper's address onto the Settings
   and Staging pages); the read-only schema door in `cmd/tgarchive/app.go`; a word for a protected chat on
   its row; the watchdog's state on the Overview; one form for times on the pages (the Staging page shows
   hours, minutes and seconds, the sign-in page a full date).
5. **How the work goes, and what this session learnt:** one Opus coder per brief in its own copy, resumed by
   message for its fix rounds (it keeps its context); one independent Opus reviewer with probes, resumed for
   a second pass whenever a fix round rebuilt something that acts for the owner or joined a real door (three
   of four second passes found a must-fix); routine steps by ONE Sonnet clerk call on an exact instruction,
   with a small script for an exact edit; **before a listing, the WHOLE `internal/server` run on the merged
   tree, never named runs alone** (twice a test that only the whole run includes was missed: the scripts'
   size limit, the demo's rule); a branch that will be merged after a sibling takes the sibling's head in
   first (a coder's merge: both sides stay); an owner's page is corrected from the review's "lines not
   true", and a note is put at its top the moment a fault makes a line false.
6. **Nothing of this session is running now.** Copies that can go when their branches are merged (most are):
   `wt-pages-g1`, `-g1-look`, `-scroll`, `-g2`, `-g2m`, `-g2c`, `-g3`, `-g3m`, `-g5` (old), `-g5m`, `-g6`, and
   `-g4` after its merge; scratch folders `wt-pages-g1-probe-scratch`, `wt-pages-review-g2-scratch`, `-g2b-`,
   `-g3-`, `-g4-`, `-g5-`, `-g6-`; run logs `runs-pages-g1b`, `-g2`, `-g2c`, `-g3`, `-g4`, `-g5`, `-g6`. Removing
   them is a clerk's step after a check that each tree is in the main branch.
- 11-16 05:48: **G4 put ON HOLD by me; a coder is merging the main head into it.** A look after the listing (one
  command, a judgement: `git merge-tree`, no tree touched) showed the main head at 6365a08a (M11, the mirror's
  ended read): `pages_mirror_test.go` conflicts (spurious), the lent lines no longer compile (`accountDeps`
  has a third argument) and, read against M11's code, are wrong on it: `wantApprove` returns nil for an
  approval on record, and since M11 `d.Approve` is what clears the mirror's end of a read for a chat not read
  to its end, so a stop and a new want on such a chat would leave it unread for good. Brief
  `BRIEF-G4f-merge-m11.md` (the merge, about 20 lines, a unit case, one rig test, one mutation); one Opus
  coder started in `wt-pages-g4` (named tests only). **Next:** read its hand-back and the lent lines' commit;
  a Sonnet clerk runs whole `internal/server`, `internal/collector/livepages`, whole `internal/collector`
  and the race detector on the changed and new mirror tests by name; entry "G4" READY with the new head;
  the marked line on `DESIGN-G4-mirror-from-page.md` reworded to M11's "except one reader turn".
- 11-16 05:50: **the launcher's follow-up briefed and with a second Opus coder** (free memory 6.8 GB, CPU 13%
  before the start): `BRIEF-G7-launcher-followup.md`, branch `wip/pages-launcher2` cut from 6365a08a in the
  copy `wt-pages-l2`. Three changes: `readWatchdogStatus` becomes `watchdog.ReadStatus` (a failed read cached
  for a second in the page's status, since the door tries for about 100 ms); `viewerSpec` adds `-staging`;
  the collector's three own answers carry `X-Tgarchive-Pages` with a word each (`starting`, `no-pages`,
  `stopping`; my read: the value `1` on them, as my earlier note said, would have made the launcher take
  them for the pages) as lent lines in Core's `pages.go` in one commit, and `collectorwords.go` goes. No
  independent review is planned for it (about 80 lines, no new door for the owner): my read of the
  difference, the launcher's whole tests on Windows and in a Linux container by a clerk. **Running now:**
  the G4f coder in `wt-pages-g4`, the G7 coder in `wt-pages-l2`. **Next:** each hand-back read; one clerk
  call for both trees' runs; entries "G4" (READY again) and "G7".
- 11-16 05:51: **the G4f coder stopped at the merge, rightly: the listed G4 (9b4e265a) would have removed four of
  G1's tests from the main branch.** The fix round G4c (550be61c) had replaced the whole file
  `internal/collector/pages_mirror_test.go` (G1's `TestOwnerStopEndsAutoMirror`,
  `TestPauseLeavesAutoMirrorGoing`, `TestChatsPageWithAutoMirror`, `TestRunPagesWithAutoMirror`) with the
  mirror page's own tests; two merges of the head kept the branch's side; neither review pass, the clerk's
  runs nor my reads saw it (checked by me: the four are on the main head, none on the branch). My brief had
  called the conflict spurious from one hunk: wrong. **Decided (mine):** the file is taken as the main head
  has it, byte for byte, the branch's tests move unchanged to `pages_mirror_wish_test.go`; a restored test
  that fails for a reason of the branch's is reported, never edited. The coder is resumed with that (it
  keeps its context). **Lesson for the track:** before a listing, list the test functions the piece's
  difference REMOVES (`git diff <base> <head> | grep '^-func Test'`) and account for each; a clerk's step,
  added to the listing runs from now on.
- 11-16 05:51: **the integrator (by message): the main head is d1ebd1a (K9b merged after M11); merge it into G4, runs by
  a clerk, list; every other merge is held until then.** The G4 coder is told to merge d1ebd1a (on top of
  its merge of 6365a08a if that is made already). K9b's 24 files touch none of the launcher, the watchdog,
  `collector/pages.go` or the server, so G7's branch (cut from 6365a08a) is not affected. No reply by message.
- 11-16 05:58: **G4f handed back: `wip/pages-g4` a1c5d5c8 (pushed) holds the main head d1ebd1a.** Two merge commits
  (6365a08a, then d1ebd1a: clean), G1's file as the main head has it and the page's tests in
  `pages_mirror_wish_test.go`; the lent lines in a commit of their own (30c6349a): `MirrorWantRead` with
  M11's notes, an approval on record loses only the mirror's end of its read (`setReadEnd`), an estimate
  approved is written with no end. Checked by me: it holds the head, removes no test function against it,
  G1's file equals main's, 23 files differ from the head; the lent lines read (right by M11's rule; the
  owner's record is never touched). The coder's named run: the four restored tests, the rig wish, the unit
  cases and a new rig test `TestMirrorWantReadStopThenWantAgain` (stop after 2 of 5 pages: the count stays
  at 2 over 3 minutes of the clock; the want again: 5 requests in all, one mirror, every file once, in
  order) ok; the clear undone fails both new tests. **Running now:** the listing runs, once, by a script
  (`runs-pages-g4/run-listing.sh a1c5d5c8`, one background call of mine, not a clerk: a script whose steps
  never change): build, gofmt, vet, whole `internal/server`, whole `livepages`, the collector by name (the
  mirror, staging, pages and sign-in sets), and the race detector in a container on
  `TestMirrorWant|TestMirrorPagesWish` only (the change is a door's lines; M11 and K9b had their own race
  runs). Results: `runs-pages-g4/listing-a1c5d5c8.summary`. **Next:** entry "G4" READY with a1c5d5c8 if
  every line says exit 0. The G7 coder is still working in `wt-pages-l2`.
- 11-16 06:00: **G7 handed back: `wip/pages-launcher2` db68550e (pushed; on 6365a08a).** Two commits: the lent
  lines in Core's `pages.go` and its test alone (01d8aa4a: the header `X-Tgarchive-Pages` with `starting`,
  `no-pages`, `stopping` on every path of the collector's three own answers), and the launcher (db68550e):
  the status file through `watchdog.ReadStatus` behind a door of the launcher's (`Env.ReadStatus`), a
  failed read kept for 1 s in the page's status, `-staging` for both viewers, `look` by the header's word
  with no body read, `collectorwords.go` and its test gone (the one test function removed: accounted for),
  the launcher's own `openShared` gone. My read of the difference (the probe, the answers, the status): as
  briefed; no independent review, as planned. The coder's runs: the launcher's whole tests ok 45.8 s, four
  collector tests by name ok. Checked by me: no conflict with the main head d1ebd1a nor with
  `wip/pages-g4` (both touch `collector/pages.go`, in different places). **Running now, beside G4's runs:**
  `runs-pages-g7/run-listing.sh db68550e d1ebd1a9` (a script, one background call of mine): the clean merge
  of the main head, build, gofmt, vet, whole `internal/launcher` on Windows and in a Linux container (no
  race detector: no concurrent code changed), whole `internal/collector`, then the push if every step is
  exit 0. Results: `runs-pages-g7/listing.summary`. **Next:** entries "G4" and "G7" from the two summaries.
- 11-16 06:11: **G4 is LISTED and READY again: `wip/pages-g4` a1c5d5c8 holding d1ebd1a.** The script's lines, all exit
  0: build, gofmt, vet; whole `internal/server` 134.6 s (170 tests); whole `livepages` (15); the collector by
  name 566.9 s (151 tests); the race detector on the lent lines' tests 368.7 s, no data race; no test
  function removed against the head. Entry "G4" has a new first paragraph (what changed since the first
  listing); board message 99 (the integrator, the mirror track, Core). By a script in one background call
  of mine, not a clerk (steps that never change). **Running:** G7's listing runs. **Next:** entry "G7".
- 11-16 06:19: **G7 is LISTED and READY: `MERGE-QUEUE.md` entry "G7", `wip/pages-launcher2` 77b7fdf9 (pushed), holding
  d1ebd1a.** The script's lines, all exit 0: the clean merge of the head; build, gofmt, vet; whole
  `internal/launcher` on Windows 48 s (47 tests) and in a Linux container (14 passed, 34 skipped); whole
  `internal/collector` 1,013 s (384 tests); the push. One test function removed on purpose
  (`TestCollectorWordsMatchPagesGo`). By a script in one background call of mine, not a clerk.

### STATE FOR A TAKE-OVER (P3, 11-16 06:19; this block replaces the one of about 05:45 above)
Read `BOARD.md` (my row; messages 92, 94 to 99; items 30 to 33 of the waiting list), then this block.
1. **Merged:** G1, "G1s", G2, G2c, G6, G3, G5. **Listed, READY, both holding the main head d1ebd1a, waiting
   for the integrator:** "G4" (`wip/pages-g4` a1c5d5c8, the mirror from the Chats page; lent lines in the
   mirror's door: cf434aba and 30c6349a) and "G7" (`wip/pages-launcher2` 77b7fdf9, the launcher's follow-up;
   lent lines in Core's `pages.go`: 01d8aa4a). No conflict between them. If one is handed back: read the
   integrator's note at the entry's front; a merge with a conflict is a coder's, a clean one and the runs a
   script's (`runs-pages-g4/run-listing.sh <head>`, `runs-pages-g7/run-listing.sh <head> <main head>`: each
   checks the head, counts the test functions removed against the main head, runs the listing runs once and
   writes one exit line per step).
2. **For the owner, open:** item 31 (the first real start of the folder), 32 (the first real sign-in from the
   page), 33 (the first real mirror from the page; its one page is `DESIGN-G4-mirror-from-page.md`, item 30).
3. **Next new pieces (board message 73 c), none started:** the client's routes on the listener (Core's "K9b"
   is merged at d1ebd1a: the collector's entry points are in section 9 of
   `archiver/docs/progress/core-turn-REPORT.md`; read the viewer's messages 90, 91, 93, 95 first); the
   backup's button; stage B of the folder (the copy's choices and the helper's address onto the Settings and
   Staging pages); the read-only schema door in `cmd/tgarchive/app.go`; a word for a protected chat on its
   row; the watchdog's state on the Overview; `ReadRecordsBad` (the mirror's new count) on the Overview's
   Mirrors region; one form for times on the pages.
4. **How the work goes, and what this session learnt:** one Opus coder per brief in its own copy, resumed by
   message for its fix rounds; one independent Opus reviewer with probes, a second pass whenever a fix round
   rebuilt something that acts for the owner or joined a real door; routine steps by a script in one
   background call, or one Sonnet clerk call on an exact instruction; before a listing the WHOLE
   `internal/server` on the merged tree; **before a listing, count the test functions the piece removes
   against the head and account for each (a fix round once replaced a whole test file of an earlier piece
   and two review passes did not see it)**; after a listing, look once whether the main head moved
   (`git merge-tree`, no tree touched) and read the other track's change against any lent lines before
   calling a conflict spurious; an owner's page is corrected the moment a line on it stops being true.
5. **Nothing of this session is running now.** Copies that can go when their branches are merged:
   `wt-pages-g1`, `-g1-look`, `-scroll`, `-g2`, `-g2m`, `-g2c`, `-g3`, `-g3m`, `-g5` (old), `-g5m`, `-g6` (all
   merged), `-g4` and `-l2` after their merges; scratch folders `wt-pages-g1-probe-scratch`,
   `wt-pages-review-g2-scratch`, `-g2b-`, `-g3-`, `-g4-`, `-g5-`, `-g6-`; run logs `runs-pages-g1b`, `-g2`,
   `-g2c`, `-g3`, `-g4`, `-g5`, `-g6`, `-g7`. Removing them is a clerk's step after a check that each tree is
   in the main branch.

## Session P4 (took the track over 11-16 06:57, started by the owner; P3 is retired)
- 11-16 06:57: **taken over.** Read: the board (direction, the rules, my row, the queue, messages 90 to 100 and
  the integrator's of 06:41, the owner's list), P3's last take-over block, `MORNING-2026-11-16.md` (the
  pages' rows), `HANDOFF.md` 0c's first block. Found on disk: the main head is 788ebf77 (G4, the mirror page,
  merged 06:43, installed, the owner's folder rebuilt); G7 (`wip/pages-launcher2` 77b7fdf9) is listed and not
  merged, and merges into 788ebf77 with no conflict (`git merge-tree`, one command of mine: a judgement).
  The row says so. Nothing of the track was running.
- 11-16 07:01: **the next piece chosen and briefed: G8, the door for the owner's clicks on the collector's
  listener** (piece 3 of `DESIGN-CORE-client-actions.md`; board message 73 c group 2; the owner asked twice
  for acting in a chat). Read by me for it, in full: the design's sections 3 and 4, `SEAM-B5-viewer-act.md`,
  the viewer's messages 90, 91, 93, 95 and Core's 100, TRIED-BEFORE 24 and 25, `click_api.go` on
  `wip/core-settle` (d6415255), `internal/server/server.go`'s guard and the mirror seam's head. **What the
  old app knows:** nothing of its own (it never acted in a chat); what binds the door are the thirteen rules
  for anything that acts for the owner and this track's own reviews (three of four second passes found a
  must-fix in whatever joined a real door). **Decided (mine), in `BRIEF-G8-clicks-door.md`:** a seam `Clicks`
  in `internal/server`; six routes under `/api/act/` (state, queue, cancel, again, verdict, not-arrived), POST
  with JSON, one click a call; a guard of the door's own (the header `X-Tgarchive-Door` with a secret; the
  page's token does not open the door, the secret opens nothing else; anything a browser sends is refused);
  a refusal is 409 with a word of the viewer's closed set, a failure 500 "failed"; queue and the owner's
  actions finish on a context the caller's leaving does not cancel (15 s); the secret is fresh at every
  start and written with the listener's address into ONE file `act-door.json` in the catalogue's folder
  (the viewer's pass-through reads it there: no flag, no script, no path of this PC); no read route (the
  viewer reads the ledger itself); the cap and "mark as read" as two rows on the Settings page. **Left to
  Core's K14, said plainly in the brief:** the key's memory (the seam carries `Key`, the adapter does not
  remember it), the one cheap state call (until then the adapter tells what it honestly can and `MaxText`
  is 0, so no text goes), the text's limits at the queue. **K9c (`wip/core-settle`) does not merge onto
  788ebf77 as a branch** (add/add: K9b came in as one squashed commit): the coder builds the server's side
  first and, at the adapter, takes the main head if K9c is in it, else K9c's own difference in one commit
  that the main head replaces before a listing.
  **Running now:** one Opus coder (high effort) on `BRIEF-G8-clicks-door.md`, branch `wip/pages-door` from
  788ebf77, copy `wt-pages-door` (the PC before the start: 6.4 GB free, CPU 33%). Not committed or pushed by
  it yet. **Next:** the board message to Core, the viewer and the integrator; the brief for the small
  follow-ups (G9); the coder's hand-back read by me (the guard, the cut-off, the adapter's map), then one
  independent Opus review with probes and a second pass after its fixes, then the listing runs by a script.
- 11-16 07:02: **board message 101** (Core, the viewer, the integrator: pages builds the door; its routes,
  header and file; what is left to K14; K9c does not merge as a branch; G7 is clean on the head) and the row;
  committed on `notes` (1130ba3; one command of mine: a single command). A Core session is at work beside me
  (`BRIEF-K14-door-guarantees.md` appeared in the folder at about 07:01; not mine, not read yet).
- 11-16 07:04: **G9 briefed and with a second Opus coder (high effort):** `BRIEF-G9-pages-small.md`, branch
  `wip/pages-small` from 788ebf77, copy `wt-pages-small` (the PC before the start: 5.5 GB free, CPU 61%, two
  Go processes of other sessions). Five small points, each its own commit: one form for a time on every page
  (today: a clock time; another day: with its date); the mirror's bad-record count on the Overview; the
  watchdog's state on the Overview through `watchdog.ReadStatus` (only if the collector can know the file's
  place without a path of this PC: else nothing is built and the report says what Core would hand over);
  `tgarchive app` refusing a catalogue newer than the build as the viewer does; a sentence for a protected
  chat on its row if G4's row does not already say it. It is told to keep off the door's files and the
  Settings scripts (G8's). No independent review is planned for it (no door for the owner): my read of the
  difference and the listing runs. Not in it, on purpose: the backup's button (Core's door for it is not
  built), stage B of the folder (its own piece, after G8).
  **Running now:** the G8 coder in `wt-pages-door`, the G9 coder in `wt-pages-small`. **Next:** the review
  brief for G8 written while they work; each hand-back read by me.
- 11-16 07:05: Core's message 101 (K-4, 07:02: K14 with a coder; `ClickInput.Key`, `ClickState`, the words "key"
  and "queue full") read and taken into G8: the coder told by message (the two words in the closed set from
  the start; the state route answers an object K14 can add fields to). `BRIEF-G8-review.md` drafted (the head
  and base to fill in). The owner's items 32 and 33 say READY, from the integrator's merge lines. My stamps
  of the first entries corrected to the clock (they ran ahead by up to eight minutes).
- 11-16 07:23: **G9 handed back: `wip/pages-small` 8d5ba742 (pushed), on 788ebf77; four of five points built.**
  (1) One form for a time: `timeAt` and `timeUntil` in `format.js`, 23 calls moved, the local `clock` helpers
  gone, a test that fails on any `toLocale*String` or `DateTimeFormat` outside `format.js`. (2) The mirror's
  bad-record count reaches the Overview (a field through the adapter; ONE lent line in the collector's
  `pages_mirrors.go`, commit 7dd175f1 with its own test). (3) **The watchdog's line: NOT built, rightly:** the
  collector cannot know today that a watchdog started it, nor where the status file is; what Core would
  hand over is in board message 103. (4) `tgarchive app` asks `catalog.ReadOnlySchema` before anything is
  opened and refuses a catalogue of another schema, NEWER OR OLDER, with `catalog.SchemaWords` (the coder's
  decision, as the brief allowed: `app` never steps a catalogue; the collector's `run` does). (5) A protected
  chat with no mirror state now has a row saying it forbids forwarding (one catalogue statement an account
  per poll, `catalog.ProtectedChats`; 8 statements a poll where 5 were, bound 12).
  **Read by me (the difference of `app.go`, `server/mirrors.go`, the adapter, the lent line, `format.js`, the
  five scripts whose times were in milliseconds or seconds):** as briefed; the units are right; a failed
  read of the protection adds no row (the door still refuses such a plan). Accepted as they are, known and
  small: `app` now refuses an existing 0-byte catalogue file (it built the schema in it before); "today" is
  this computer's date; a protected chat marked never shows only the mark. No independent review, as
  planned (no door for the owner). Test functions removed against the base: 0.
  **Running now:** G9's listing runs, once, by a script in one background call of mine
  (`runs-pages-g9/run-listing.sh 8d5ba742`: build, gofmt, vet, whole `internal/server`, whole `livepages`,
  whole `cmd/tgarchive`, the collector's pages and mirror tests by name; no race detector: no concurrent
  code changed; results in `runs-pages-g9/listing-8d5ba742.summary`); the G8 coder in `wt-pages-door`.
  The viewer's message 102 (B6, 07:07) read: its two asks of the door file (a reader in a package of the
  standard library only; the address always `127.0.0.1:<port>`) sent on to the G8 coder.
  **Next:** entry "G9" in `MERGE-QUEUE.md` if every line says exit 0; G8's hand-back.
- 11-16 07:30: **G8 handed back: `wip/pages-door` 8a8a5f35 (pushed), on 788ebf77, with K9c's own difference as
  ONE commit (285b1efc: the main head had no K9c; it is replaced by the main head before a listing).** Built:
  the package `internal/actdoor` (the door file `act-door.json` beside the catalogue, written whole, replaced
  at a start, removed at a stop only while it holds this run's secret; the reader `ReadDoorFile`, standard
  library only, kept by a wall test); `internal/server/clicks.go` (the seam `Clicks`, the door's own guard
  called from `guard` right after the Host check, six routes, 25 words, three settings routes with the
  page's token); `pages/clicksettings.js` (the Settings rows); the adapter `livepages/clicks.go` and 67 lent
  lines in `pages.go` (commit 657eff04). The coder's named runs ok (7 + 11 + 4 new tests; one click with the
  secret on the rig: 1 request at the fake Telegram and 1 row "done"; a wrong secret, none, or the page's
  token: 0 and 0), 17 mutations applied and caught, 0 test functions removed.
  **Read by me:** the guard and `doorGuard` (no door 404; a browser's marks or any method but POST 403; the
  secret compared in constant time; the page's rule never sees a door path), `doorWork` (the server's work
  context with 15 s, counted for `WaitWork`, the answer written after the call), `doorOutcome` (a word
  outside the set is a failure), the queue's body checks, the adapter's `State` (memory and three one-row
  reads, then the settings; `max_text` 0), the lent lines (the secret made and the file written before the
  pages exist; `ClickInput(in)` is a plain conversion that stops compiling when Core adds `Key`: wanted).
  As briefed. **Six departures, all reasonable to my reading and put to the reviewer:** a seam that succeeds
  after the deadline is answered 200 (a queued click is never told "failed"); non-POST is 403; a held stop is
  409 "not running"; the state's why may be "setting"; the cap's range refusal is the settings' own, not a
  door word; the door file's opening sits in the same lent commit as the hand-over.
  **NOT verified by anyone yet:** whole runs, the race detector, the Settings rows in a browser, a real
  reader holding the door file during a replace.
  **Running now:** the independent review (one Opus reviewer, high effort, read-only, probes by overlay;
  `BRIEF-G8-review.md`, filled in; it writes `REVIEW-G8-clicks-door.md`; scratch
  `wt-pages-review-g8-scratch`; the PC before its start: 5.3 GB free, CPU 59%); G9's listing runs (server,
  livepages, `cmd/tgarchive`: exit 0; the collector's named sets running).
  Board message 104: the door as built, for the viewer and Core (the report's section 2 on the branch is the
  contract), and what the coder met in K9c's files. An inline Python string with this PC's paths failed to
  parse at 07:29 (nothing was written): the brief was then edited with the file tools, as the rule says.
  **Next:** G9's entry; the review's findings judged by me; the fix round with the same coder (resumed); a
  second review pass (the piece joins a real door); then the main head merged in once K9c is there, the
  listing runs by a script (whole `internal/actdoor`, `internal/server`, `livepages`, whole
  `internal/collector`; the race detector on the door's tests by name in the server and the collector, since
  the routes hand work to the server's work group), the Settings rows opened in a browser, entry "G8".
- 11-16 07:35: **G9's listing runs on 8d5ba742 ended, every line exit 0** (`runs-pages-g9/listing-8d5ba742.summary`):
  build, gofmt, vet; whole `internal/server` 149 s (176 passed, 1 skipped); whole `livepages` (16); whole
  `cmd/tgarchive` (9); the collector's pages and mirror sets by name 455 s (112 passed, 1 skipped); 0 test
  functions removed. **The main head moved meanwhile to e4a4a61d** (G7, K9c and K13 merged, documents): no
  file in common with G9 (checked with `git diff --name-only`), and G9 merges onto it with no conflict
  (`git merge-tree`). So that the entry holds the head: **running now**, one background call of a script
  (`runs-pages-g9/merge-head.sh`: the clean merge of the head or nothing, the same listing runs once on the
  merged tree, the push only if every line is exit 0; about 11 minutes; a script, not a clerk: steps that
  never change). K9c is on the main head now: G8's borrowed commit can be replaced in its fix round.
  **Next:** entry "G9" from the new summary; the reviewer's hand-back for G8.
- 11-16 07:43: **G8's independent review is back: "may be listed after these fixes"** (`REVIEW-G8-clicks-door.md`,
  read by me in full but for its table: 1 must fix, 3 should fix, 10 minor). Found sound: the guard (22
  requests over 11 path forms; nothing reached a handler without the secret), every route answers once, no
  secret or text of a click in a log or an answer, `WaitWork` against the routes (no real race), 0 test
  functions removed. **Judged by me, all accepted:** M1 is a rule for the caller until K14 (no answer from
  the queue is "not known" and that key must not be sent again: the door remembers no key yet, a second call
  queues a second click with new ids): wording in the report and the comments, board message 106 to the
  viewer and Core. S1: `catalog.ErrBadAct` becomes the refusal "not a click" (one row). S2: while the
  collector starts or stops, a door path answers 503 in the door's form (lent lines in Core's
  `pagesUnavailable`, a commit of its own). S3: the state's "setting" and "not found" told to the viewer.
  Minor: the too-many-messages test made to test the count (the reviewer's mutation passed it); the reader
  never returns a path; during a held stop cancel, verdict and not-arrived are let through; the door file
  removed at the end of the pages' stop; two sentences on the Settings rows.
  **Running now:** the fix round, the same coder resumed by message (points A to H: A merges the main head
  e4a4a61d, which holds K9c, so the borrowed commit meets the head's; G opens the Settings rows in a
  browser); G9's second listing run on the merged tree 150a8b33 (server, livepages, `cmd/tgarchive`: exit
  0; the collector's named sets running).
  The viewer's message 105 read: its pass-through is built to the door's report and in review; its
  question answered in 106 (the door file's name can be missing for an instant during the replace).
  **Next:** G9's entry; the fix round's hand-back read; the second review pass by the same reviewer
  (resumed) on the round's difference; `runs-pages-g8/run-listing.sh <head>` (written; one background call).
- 11-16 07:48: **G9 IS LISTED, READY: `MERGE-QUEUE.md` entry "G9", `wip/pages-small` 150a8b33 (pushed), holding
  e4a4a61d.** The script's lines on the merged tree, all exit 0 (`runs-pages-g9/listing-150a8b33.summary`):
  the clean merge; build, gofmt, vet; whole `internal/server` 152 s (176 passed); whole `livepages` (16);
  whole `cmd/tgarchive` (9); the collector's pages and mirror sets by name 455 s (113 passed); 0 test
  functions removed; the push. By a script in one background call of mine, not a clerk. The main head went
  on to dbca91d4 at 07:42 (K15, `internal/store` only, and documents): no file in common, clean by
  `git merge-tree`, not run again; the entry says so.
  **THE OWNER OPENED THE FOLDER'S PROGRAM AT 07:40 AND SAID (the integrator's message of 07:44): "Will it
  eventually be standalone (i.e. not in a browser), plus the setup screen is ugly and there's no folder
  selection boxes, just paths, which looks worse."** Three listed features now, mine, ahead of any other new
  depth: the app's pages and the launcher's own pages in a window of the app's own (the window's door is
  the viewer's to name); "Choose..." beside each folder opening Windows' own folder box from the launcher;
  the setup page in the look of the app's pages. "Done" is the owner's next opening of the folder.
  **Running now:** G8's fix round (the coder in `wt-pages-door`). **Next:** the launcher's pages and
  `DESIGN-G6-one-folder.md` read by me, then a brief for the folder boxes and the look (they need nothing
  of the window) with a coder at once; the window's part when the viewer has answered.
- 11-16 07:50: **G10 briefed and with a coder: `BRIEF-G10-setup-folder-box-and-look.md`, branch `wip/pages-setup`
  from dbca91d4, copy `wt-pages-setup`, one Opus coder (high effort; the PC before: 4.9 GB free, CPU 79%).**
  Read by me for it: `internal/launcher/ui.go` (the page's template, its policy, `act`), the design's lines
  on the folder dialog and the window, `FINDING-CORE-crash-28.md` (raw Windows calls: closed by the
  toolchain's one line, so the coder builds only with `env-archiver.sh`'s Go). **What the old app knows:**
  nothing of its own here (it had no setup page; its interface lessons TRIED-BEFORE 10, 15, 19 are in the
  brief). **Decided (mine):** "Choose..." is a submit button of the setup form (no script: the launcher's
  policy stays), the launcher opens Windows' modern folder box itself (`IFileOpenDialog`, pick folders),
  one at a time, on its own thread, brought to the front; the page's request does not hang (a view "a
  folder box is open" that refreshes); typed values kept; nothing saved or started by a choose; the look
  is the launcher's own style text held to `base.css` by a test (it imports nothing of the server); one
  real test of the real box behind `TGARCHIVE_REAL_FOLDERBOX=1`, run three times by the coder (a system
  dialog on the desktop for about a second each; nothing looked at). One independent review planned (raw
  COM in the program the owner double-clicks). **The window (G11) is not briefed:** board message 108 (b)
  says what the launcher needs of the viewer's window program; (c) asks Core for two errors where K14 has
  one `ErrClickText` (the door's set has "empty" and "too long").
  **Running now:** the G8 fix round (`wt-pages-door`), the G10 coder (`wt-pages-setup`). **Listed, waiting
  for the integrator:** G9. **Next:** the G8 fix round's hand-back read, its second review pass, its runs.
- 11-16 07:54: **G8's fix round handed back: `wip/pages-door` 0521253c (pushed), holding e4a4a61d** (a clean merge,
  6d4b1770: the borrowed K9c commit met the head's same content; against e4a4a61d only the door's 14 files
  differ). Every finding done as decided: the M1 wording (comments and the report's section 2);
  `catalog.ErrBadAct` is "not a click" (on the rig: a send with an emoji, 409, no row, no request); a door
  path answers 503 in the door's form while the collector starts, stops or has no pages (7 lent lines in
  `pagesUnavailable`, commit c1659486; `/api/live` unchanged); the count test sends 101 valid ids (the
  mutation now caught); a read's failure names no path; during a held stop cancel, verdict and not-arrived
  go through, state, queue and again answer 409 "not running"; `closeDoor` at the end of `p.stop()` with
  the secret under a mutex of its own (the stop and `attach` both touch it); two sentences on the Settings
  rows. Mutations M18 to M22 caught; 0 test functions removed against e4a4a61d; the coder's named runs ok.
  **The Settings rows were opened in the built-in browser** by the coder (a fake seam on 127.0.0.1:8799, an
  invented catalogue; desktop 1024 and phone 375): not stored, stored, a refused cap, a 5xx without "Not
  stored:", both values unreadable ("write it anew"), no sideways scroll at 375. NOT seen: the page as an
  image at desktop width (read as text: two screenshots timed out), the keyboard's place after a save, the
  light theme. Found and left for the next round: after a save the "when" sentence shows twice.
  **Read by me:** every lent line in `pages.go` against the main head (the 503's lines, `openDoor`,
  `closeDoor` and its mutex, the hand-over): as decided.
  **The main head moved again (53ee5bcd: the viewer's compose box, K15, documents):** a trial merge is clean
  (the coder's `git merge-tree`); it is merged by the listing script, after the review.
  **Running now:** the second review pass (the same reviewer resumed by message, on the round's own
  commits: the held stop's change, the mutex and the door file at the stop, the 503's lines, "not a click",
  the new mutations run by itself, the report's section 2 line by line); the G10 coder.
  **Prepared:** `runs-pages-g8/merge-head.sh` (the clean merge of the head or nothing, then
  `run-listing.sh`: build, gofmt, vet, whole `internal/actdoor`, `internal/server`, `livepages`, whole
  `internal/collector`; the race detector in one container on `actdoor` whole, the server's door tests and
  the collector's door and pages-stop tests by name, since the routes hand work to the server's work group
  and the stop now shares the secret under a lock; then the push).
  **Next:** the second pass judged; a last small round if it asks one (with the doubled sentence); then the
  script, one background call, about 25 minutes (the whole collector is about 17 of them).
- 11-16 08:01: **G8's second review pass is back: "may be listed"** (must fix 0, should fix 0, minor 5; added to
  `REVIEW-G8-clicks-door.md` as "Second pass (0521253c)"). Every first-pass finding fixed (minor 5 in part:
  the door file's removal holds the collector's lock only while the collector runs). The round's rebuilt
  parts checked by the reviewer with its own mutations (M18 to M22 and S1's row: all caught): the held
  stop (only cancel, verdict and not-arrived reach the seam; a cancel racing the click's turn is safe: one
  writer, the click changes only while queued), the mutex (no deadlock; never a door served with its file
  gone), the 503's lines (first, every method, nothing leaked; the other answers byte for byte as on the
  head). **Judged by me:** four of the five are words in the report's section 2 that are not true of the code
  (a trailing slash is a plain 404, not a 307; "the collector's lock still held" only while it runs; the
  table test sees only `var Err...` of `click_api.go`; the stop refuses from the moment it is asked) and
  the coder's doubled sentence on the Settings rows: **applied by a Sonnet clerk** on an exact instruction
  (eight named edits, node check, gofmt, a build, three named server tests, the commit with my message, the
  push; it stops at the first thing not as written). The fifth is left and written into the entry: the row
  for `catalog.ErrBadAct` also answers three kinds of fault as the refusal "not a click" (a chat row that
  cannot be addressed, a click time of 0 or less, a random id of 0); nothing is queued in any of them.
  **Running now:** the clerk in `wt-pages-door`; the G10 coder in `wt-pages-setup`.
  **Next:** `runs-pages-g8/merge-head.sh` (one background call of mine: the clean merge of the main head,
  the listing runs once, the push); then entry "G8".
- 11-16 08:03: **the clerk is back: all eight edits applied, the five checks exit 0, `wip/pages-door` 59ff89b6
  pushed** (by a Sonnet clerk; its commit read by me: the report, one comment line in `pages.go`, one line of
  `clicksettings.js`). **G8's listing script started 08:02 (one background call of mine; a script):** it
  merged the main head 6af0c09a cleanly (head now 1decd1fb; 14 files differ from the main head) and runs
  once: build, gofmt, vet, whole `internal/actdoor` (8 passed) so far exit 0; whole `internal/server`,
  `livepages`, whole `internal/collector` and the race container are running
  (`runs-pages-g8/listing-1decd1fb.summary`; the PC before: 5.4 GB free, CPU 25%).
  **Board message 111:** the contract's four changed sentences for the viewer and Core; **to the viewer on
  the window for the app's pages (its 110: `tgarchive-window.exe -pages <address> ... -data <folder>`, with
  a coder of its own):** the app's pages have a download (the Report page's "Download as .txt"), links to
  the open web (the Queue page's rows link to the post on Telegram) and a link to the viewer's address in
  the header: what I ask for each; **to the mirror (M5, its 106):** the lent lines are the mirror's now; the
  form the page wants for the read's cost (an entry in the plan's request list) and for a dropped word (a
  flag and the task's fixed words on the chat's state); the switch "mirror chats I join by themselves" is
  mine to put on the page when M10 is listed ("G12").
  **Running now:** G8's script; the G10 coder. **Next:** entry "G8" from the summary; G10's hand-back.
- 11-16 08:19: **G10 handed back: `wip/pages-setup` 1a7c0be4 (pushed), on dbca91d4; `internal/launcher` only.**
  Built: "Choose…" beside the library, staging and data folders as a button of the setup form (no script);
  the launcher opens Windows' modern folder box (`IFileOpenDialog`, raw COM in `folderbox_windows.go` behind
  an interface; one goroutine locked to its thread; one box at a time, a second choose, a save or a close
  while one is open refused); the request answers at once with a view "a folder box is open" that refreshes
  every 2 s; every typed value kept exactly; the launcher's setup and status pages in the app's look (still
  one inline style by its hash, no script), held to `base.css` by a test (19 colours light and dark, the
  fonts, the radius and the gap). The coder's tests ok (9 named; the whole launcher package once, 53.5 s),
  three mutations caught, 0 test functions removed. Seen by it in the built-in browser: every view, light and
  dark, desktop and 375 wide, beside the app's demo pages: the same look, no sideways scroll.
  **The real box, three runs by the coder (08:10:55 to 08:11:01; a system dialog on the desktop for about a
  second each):** appeared after 426, 411 and 485 ms, topmost, closed by its own cancel, nothing left behind;
  **"in the foreground": NO in all three** (the window in front was a system shell window that refuses the
  attachment the launcher tries; with a browser in front it should be allowed: nobody has seen it). So:
  the box is on top and seen; whether it has the keyboard without a click is for the owner to see (the
  launcher's log says "in front by way N").
  **To tell the owner plainly:** in two diagnostic runs at about 08:07 and 08:09 the coder's trial code
  pressed and released the ALT key into whatever window was in front on the desktop; it did not help and
  was removed; no built code presses a key. (My brief asked for a real test of the box and did not forbid
  synthetic keys: it should have.)
  **Read by me:** `folderbox_windows.go` in full (the calls, the releases on every path, the owner window and
  the three ways to the front): reads as careful. **Decided by me before the review, for the fix round:**
  a choose must not run Save's write check (today choosing a folder creates and removes a temporary file
  in it: the library is the NAS); the look at the start folder gets a bound (a share that is not connected);
  the "a folder box is open" view gets a button that closes the box (today a box that cannot be found would
  need Task Manager).
  **G8's script so far, all exit 0:** build, gofmt, vet, whole `internal/actdoor` (8), **the race container
  (actdoor whole, the server's door tests, the collector's door and pages-stop tests by name): exit 0, no
  data race**, whole `internal/server` 144 s (187 passed), whole `livepages` (16); the whole
  `internal/collector` is running.
  **Running now:** G10's independent review (one Opus reviewer, high effort, read-only, opens nothing on
  the desktop; `BRIEF-G10-review.md`; it writes `REVIEW-G10-setup.md`); G8's script.
  **Next:** entry "G8"; the review of G10 judged; its fix round with the same coder.
- 11-16 08:24: **G8 IS LISTED, READY: `MERGE-QUEUE.md` entry "G8", `wip/pages-door` 1decd1fb (pushed), holding the
  main head 6af0c09a (in which G9 is merged).** The script's lines, all exit 0
  (`runs-pages-g8/listing-1decd1fb.summary`): the clean merge; build, gofmt, vet; whole `internal/actdoor`
  (8); whole `internal/server` 144 s (187 passed); whole `livepages` (16); whole `internal/collector`
  1,105 s (400 passed, 6 skipped); the race container exit 0, no data race (its log read by me: `actdoor`
  1.1 s, the server's door tests 40 s, the collector's door and pages-stop tests 77 s; `livepages` has no
  test of those names); 0 test functions removed; 14 files differ from the head; the push. By a script in
  one background call of mine, not a clerk. Board message 112 (the integrator; Core on the one place K14
  meets G8; the viewer).

### STATE FOR A TAKE-OVER (P4, 11-16 08:24)
Read `BOARD.md` (my row; messages 101 to 112; the integrator's of 07:34 and 07:44; items 31 to 33 of the
owner's list), then this block.
1. **Merged:** G1 to G7 and **G9** (6af0c09a). **Listed, READY, waiting for the integrator:** **G8**
   (`wip/pages-door` 1decd1fb: the door for the owner's clicks; entry "G8"). If it is handed back for a merge
   of the head: `runs-pages-g8/merge-head.sh` does a clean merge, the runs and the push in one call; a
   conflict is a coder's. **If K14 (`wip/core-door`, Core) is merged first, G8 needs three small wirings**
   (the entry's "For you at the merge"): a coder's, on a short brief, with one rig test.
2. **With its independent reviewer (started 08:19): G10** (`wip/pages-setup` 1a7c0be4, copy `wt-pages-setup`,
   `internal/launcher` only: Windows' folder box beside each folder of the setup, the launcher's pages in
   the app's look; `BRIEF-G10-setup-folder-box-and-look.md`, `BRIEF-G10-review.md`; the review is written to
   `REVIEW-G10-setup.md`). **Its fix round must also do my three points** (the 08:19 entry: a choose's checks
   read-only, a bound on the look at the start folder, a button that closes an open box), then a second
   review pass (raw COM in the program the owner double-clicks), then the launcher's whole tests on Windows
   and in a Linux container (as G7's script did: `runs-pages-g7/run-listing.sh`) and the entry. **What only
   the owner can see:** the box over a browser with the keyboard in it, a network share in it; say so on
   the owner's list when it is listed.
3. **Not briefed, next:** **G11, the app in a window of its own** (the owner, 07:40): the viewer builds the
   window's side (`wip/b-winpages`: `tgarchive-window.exe -pages <address> -pages <address> -data <folder>`,
   exit codes at its hand-back: board message 110); mine is the launcher: start that program instead of the
   browser by a setting (the window by default, the browser as the fallback when the program is missing or
   says it cannot show a window), the viewer's address as a third `-pages` when the viewer is the browser
   kind, the header's "Viewer" link not drawn otherwise, and what the pages do about their one download
   (the Report page) and their links to Telegram posts (my asks: message 111 b). **G12, the switch "mirror
   chats I join by themselves"** on the page when the mirror's M10 is listed (its names: the mirror's
   message 106 b). **The watchdog's line on the Overview** when Core has answered message 103 a. **K15 is
   merged:** the Staging page can read `Copier.Load()` and `Writer.StagingNow()` (Core's message 103 b:
   never with the collector's own lock held): a small piece. Then: stage B of the folder (the copy's
   choices and the helper's address on the Settings and Staging pages), the backup's button when Core has
   its door.
4. **How the work goes (as P3's block, and):** every time written into the notes comes from `date` at that
   moment; an inline script never holds a Windows path (it failed to parse once: use the file tools, or a
   scratch file read by the script); a board message is written to a scratch file with the file tool and
   put in by a small script that checks its anchor; a brief for a coder who tests something on the real
   desktop says what it may NOT do there (no synthetic keys, no window but the one named).
5. **Running now:** only G10's reviewer. Copies that can go when their branches are merged: `wt-pages-small`
   (merged), `wt-pages-door` after G8's merge, `wt-pages-setup` after G10's; scratch
   `wt-pages-review-g8-scratch`, `-g10-`; run logs `runs-pages-g8`, `-g9`; and P3's list above.
- 11-16 08:34: **G10's independent review is back: "may be listed after these fixes"** (`REVIEW-G10-setup.md`:
  0 must fix, 3 should fix, 10 minor). Found right: every COM call's table index, argument order, GUID and
  release, against the documented interfaces; no path in a log; the author's three mutations caught again.
  It agrees with my three decisions and adds to them. **Judged by me, all accepted, one made stronger:**
  (A) **the box moves into a short-lived helper process** (the launcher's own executable with one flag, as
  the `-send-ctrl-c` helper; what to open goes in on standard input, the answer comes back on standard
  output): the review's point that a fault inside the box (shell or extension code) ends the launcher, and
  that the box's extensions stay loaded in it for days, is real for the one program that must stay up; it
  also makes "Close the folder box" a plain end of the launcher's own child; (B) my three: no write check
  on a choose; the look at the start folder bounded at 2 s, the shell's own look skipped with it; the
  close button; (C) a second press while a box is open is redirected to the page, never a bare text page;
  (D) the box sharp on a scaled display (DPI awareness in the helper); (E) the minors: one lock for a Save
  and a Choose from two tabs, two sentences that were not true, a test that reaches the choose's own
  one-box check. **New hard rule sent with it: nothing a test or probe runs may send a key, a click or any
  input to the desktop.** The same coder resumed by message (points A to H; H asks the real box's three
  runs again through the helper and one real run of the close button).
  **The window's pages mode is built by the viewer track (its message 111, 08:27: `wip/b-winpages` bc6a44f5,
  in its security review):** `tgarchive-window.exe -pages http://127.0.0.1:PORT/ ... -data FOLDER`; exit 0
  closed or brought to the front, 3 cannot be shown, 1 another error; the launcher must not import
  `internal/window`. **G11 is briefed to it: `BRIEF-G11-app-window.md`** (not started: it is built on G10's
  branch after this fix round). Decided (mine): a setting "where the app's pages open" (the window by
  default, the browser by choice and as the fallback, said in words, once); the window's own folder beside
  the settings file (`pages-window`), since the data folder is not known at a first start; the launcher's
  page first, the app's pages shown by themselves once when they answer; closing the window stops nothing;
  a second double-click brings it back; the launcher ends its own window when it ends; never a loop of
  starts; one real try of the real window behind `TGARCHIVE_REAL_WINDOW=1` in a scratch folder with the
  profile folders redirected, no input sent. **Known and not in G11:** in the window the Report page's
  "Download as .txt" and the Queue page's links to Telegram posts do nothing (the window refuses both);
  the viewer has not yet answered what I asked for them (message 111 b).
  **Running now:** G10's fix round (`wt-pages-setup`). **Listed:** G8. **Next:** the fix round's hand-back
  read; G10's second review pass and, at the same time, the G11 coder started on G10's new head.
- 11-16 08:52: **G10's fix round handed back: `wip/pages-setup` 3879e627 (pushed), on dbca91d4; A to H done.**
  **The folder box lives in a helper process now:** the launcher starts its own program as
  `tgarchive.exe -folder-box` (one case in `cmd/tgarchive-open/main.go`: a departure the point needs), the
  request on its standard input (three lines), one answer line back on its standard output, nothing on a
  command line or in a log; the helper has no listener, reads no settings, writes no file, and ends when its
  box closes or its input closes; one at a time; the launcher no longer loads any COM. A choose shows only
  read-only facts (the test watches the chosen folder with Windows' change notification); the start
  folders are looked at within one 2 s bound in the helper; "Close the folder box" puts the setup back at
  once and ends the launcher's own helper by its handle; a press while a box is open is a 303 to the page;
  the helper sets per-monitor DPI awareness before any window (returned "set" in every real run); one lock
  for a save and a choose; every minor done. The coder's tests ok (the whole launcher package once, 50.7 s;
  four mutations caught; 0 test functions removed).
  **The real box through the real helper, three runs (08:43:42 to 08:43:47), closed by the box's own cancel
  as a window message, no key and no click:** the helper's start to its window 597, 488 and 488 ms;
  topmost yes, the right title, within the screens, nothing left, the front window got its place back;
  **in the foreground: NO in all three** (the window in front was again a system shell window that refuses
  the attachment: perhaps the lock screen; these runs say nothing of a browser in front). The real "Close
  the folder box" once: no window left 29 ms after the launcher ended its helper.
  **Read by me:** `helperbox_windows.go` in full (the start, the pipes, the one-at-a-time slot, `Abort`).
  One thing put to the reviewer: where the helper is not seen to end within the bound the slot is never let
  go, so every later choose would fail until the launcher is started again.
  **Running now:** G10's second review pass (the same reviewer resumed by message: the helper's both sides,
  the answer's parsing, the close racing an answer, the no-write proof, the new mutations by its own hand);
  **the G11 coder** (one Opus coder, high effort; `BRIEF-G11-app-window.md`; branch `wip/pages-window` from
  3879e627, copy `wt-pages-window`; the PC before: 5.8 GB free, CPU 55%).
  **Listed, not merged:** G8. **Next:** the second pass judged; a last round if it asks one; G10's listing
  runs by a script (the launcher's whole package on Windows and in a Linux container; the race detector on
  the launcher in the container, since the page's lock and the box's slot are shared between goroutines)
  and its entry.
- 11-16 09:00: **G8 IS MERGED** (the integrator, 08:25, head efac56f; installed 08:25; the owner's folder rebuilt
  08:26): the door and the two Settings rows are in the installed build; nothing calls the door yet.
  **G10's second review pass is back: "may be listed after these fixes": 1 must fix, 2 should fix, 7 minor**
  (the end of `REVIEW-G10-setup.md`, "Second pass (3879e627)"). **The must-fix is the one I had put to it,
  confirmed by its probe:** a helper not seen to end within 10 s holds the box's slot for the rest of the
  launcher's life and its "chosen" answer is dropped (a real way there: a typed NAS share that is not
  connected keeps the helper's look blocked). Should fix: a second press of "Close the folder box" still
  gets a bare text page; a folder chosen in the same instant as the close is dropped without a word (12 runs
  of 12). Minor: `Abort` tied to its own run, two wordings, a relative path refused in the answer, one pipe,
  and **`TGARCHIVE_REAL_FOLDERBOX` set makes every helper test open a real box** (it must be only the two
  real tests). Found sound by it: the DPI call, the one lock, the answer's parsing (16 cases), the end by
  Go's handle, the helper's own side; the four new mutations caught by its own hand. **All accepted by me;
  the same coder resumed by message for a second and last round (five points; told to keep it to the lines
  the findings need, since G11 is built on its head).** `runs-pages-launcher/run-listing.sh <copy> <branch>
  <tag>` is written for G10 and G11 (the clean merge of the head; build, gofmt, vet for Windows and Linux;
  the launcher's whole package and the opener on Windows; the same two under the race detector in a Linux
  container; the push; it unsets the two real-test variables).
  **Running now:** G10's second fix round (`wt-pages-setup`); the G11 coder (`wt-pages-window`).
  **Next:** the round's difference read by me, a narrow third look by the reviewer at the must-fix and the
  close's race only, then `run-listing.sh wt-pages-setup wip/pages-setup g10` and the entry.
- 11-16 09:10: **G10's second fix round handed back: `wip/pages-setup` a142c68d (pushed), on 3879e627; all five
  points done.** The must-fix: on the "not seen to end" path a goroutine waits for the helper's real end and
  lets the slot go, exactly once on every path (`sync.Once`), and an answer already read is returned
  (`TestHelperLateEndLetsGo`; its mutation fails it). A stale "Close the folder box" press is a 303. A
  folder chosen in the same instant as the close goes into the setup the close put back, else the page says
  "The folder box was closed from this page; nothing chosen in it was taken." (`TestCloseKeepsAFolderJustChosen`,
  both orders; its mutation fails it). `Abort(id)` acts on its own box only; a relative path is refused in
  the answer; the real-box variable now opens a real box only in the two real tests (a file the two write
  into their own control folder). The whole launcher package without the variable: ok 56.0 s; each real
  test once by name: the box after 644 ms, topmost, not in front (way 3), nothing left; the close: no window
  28 ms after it. 13 files, +354/-67. The coder says plainly that it ran the last whole-package run with
  the PC at 100% CPU without waiting (the run passed). **Read by me:** the difference of
  `helperbox_windows.go`: as the review asked.
  **The viewer's message 113 (08:53; read 09:09): the window's security review.** The browser engine inside
  the window (WebView2) makes a few requests of its own to Microsoft at each start, outside the VPN, nothing
  of the archive in them; the viewer builds a gate inside the window program for both modes. **For G11 it
  gives rules for the launcher, sent on to the G11 coder by message:** a `-data` folder of the window's own,
  the same every time; a clean environment (no `WEBVIEW2_*`); act only on the exit code of the process the
  launcher started (3 and 1: the browser); a second start's 0 proves no window; the window ended and started
  again if the pages come back on another address; **the window ended when the app's servers end**; no web
  link on the launcher's pages. **My three places are decided by the viewer (its 113 d):** a `text/plain`
  download from a named address is let through (the Report page's .txt works in the window), a refused
  outside link shows the window's own line with the address and "Copy", the viewer's address may be a third
  `-pages`; the pages mode's user agent gains the word `tgarchive-window`. So nothing in `internal/server`
  is needed for the window; G11's "known and not built" shrinks to: Telegram links are shown to copy, not
  opened.
  **Running now:** the reviewer's narrow third look at a142c68d (the must-fix, `Abort(id)`, the close's
  race, the real-box switch); the G11 coder (told to merge G10's then-current head before it hands back).
  **Next:** the third look judged; `run-listing.sh wt-pages-setup wip/pages-setup g10`; entry "G10".
- 11-16 09:16: **the reviewer's third look: "may be listed"** (the end of `REVIEW-G10-setup.md`): the slot is let go
  exactly once on every path; `Abort(id)`, the close's race, the stale press and the real-box switch sound;
  two edges it calls negligible, left and written into the entry. **G10 IS LISTED, READY: `MERGE-QUEUE.md`
  entry "G10", `wip/pages-setup` 835e2826 (pushed), holding the main head efac56ff.** The script's lines,
  all exit 0 (`runs-pages-launcher/g10-835e2826.summary`; one background call of mine, a script): the clean
  merge; build, gofmt, vet for Windows and Linux; whole `internal/launcher` and the opener on Windows 60 s
  (70 passed, 3 skipped); the launcher under the race detector in a Linux container (22 passed, 43 skipped
  as Windows-only), no data race; 0 test functions removed; 20 files differ from the head; the push.
  **The owner's item 35** (what only the owner can see: the box in front with the keyboard, the NAS share in
  it, the look; recommended: one opening after G11 too). Board message 114.

### STATE FOR A TAKE-OVER (P4, 11-16 09:16; this block replaces the one of 08:24 above)
Read `BOARD.md` (my row; messages 101 to 114, the viewer's 110, 111 and 113; the integrator's of 07:34 and
07:44; items 31 to 33 and 35 of the owner's list), then this block.
1. **Merged:** G1 to G9 (G8, the door for the owner's clicks, at efac56ff). **Listed, READY, waiting for the
   integrator:** **G10** (`wip/pages-setup` 835e2826: the folder box and the look; entry "G10"). If it is
   handed back for a merge of the head: `runs-pages-launcher/run-listing.sh wt-pages-setup wip/pages-setup
   g10` does the clean merge, the runs and the push in one call.
2. **With a coder since 08:52: G11, the app in a window of its own** (`BRIEF-G11-app-window.md` and two
   messages of mine to the coder: the viewer's review rules for the launcher, and "merge G10's then-current
   head before you hand back"; branch `wip/pages-window` from 3879e627, copy `wt-pages-window`). At its
   hand-back: read the launcher's state machine of "window or browser" and every place a window is started
   or ended; one independent Opus review with probes (opens no window; `BRIEF-G10-review.md` is the form),
   its fixes, a second pass; then `run-listing.sh wt-pages-window wip/pages-window g11` and the entry. It
   needs the viewer's window program with the pages mode in the folder (`wip/b-winpages`, the viewer's, in
   its fix round with a gate against the engine's own traffic): **G11 may be merged before it** (the
   launcher falls back to the browser and says why) but the owner sees the window only when both are in and
   the folder is rebuilt: say so on item 35 then.
3. **Not briefed, next:** G12, the switch "mirror chats I join by themselves" on the page when the mirror's
   M10 is listed (its names: the mirror's 106 b; the owner's item 34 is the mirror's question on "from now
   on"); the Staging page reading `Copier.Load()` and `Writer.StagingNow()` (K15 is merged; Core's 103 b);
   the watchdog's line on the Overview when Core has answered message 103 a; **if K14 is merged, nothing is
   owed by me for the door** unless Core says the three wirings are mine (message 112 b); then stage B of
   the folder, the backup's button when Core has its door.
4. **How the work goes:** as the 08:24 block, and: a fix round that rebuilt a process's start or end gets a
   narrow third look before the runs (it found the slot sound, cheaply); the full runs of a launcher piece
   are about three minutes by the script.
5. **Running now:** only the G11 coder. Copies that can go when their branches are merged: `wt-pages-small`
   and `wt-pages-door` (merged), `wt-pages-setup` after G10's merge AND after G11 no longer needs it;
   scratch `wt-pages-review-g8-scratch`, `-g10-`; run logs `runs-pages-g8`, `-g9`, `runs-pages-launcher`.
- 11-16 09:17: **G13 briefed, NOT started: `BRIEF-G13-staging-live-reads.md`** (the Staging page on Core's two
  reads from memory, K15: the copiers of the moment from `Copier.Load()` with the live reading instead of
  the gauges' second read of the queue summary; a speed "written to the library now" from two readings of
  `Written` beside "copied and verified"; staging away and resting from `Writer.StagingNow()`; neither read
  under the collector's own lock; branch `wip/pages-staging2` from the main head; no independent review
  planned: it shows numbers and adds no door). Read by me for it: Core's entry "K15", the pages' message 94
  a, the head of `internal/server/staging.go`. **The PC was at 3.8 GB free and 91% CPU at 09:16** (other
  sessions' runs): no third process of mine is started on that; its coder starts at the next look that
  shows room (under 70% and over 4 GB free).
- 11-16 09:29: **G10 IS MERGED** (the integrator, 09:18, head f7d6ca6; the owner's folder rebuilt 09:18; item 35
  marked READY by the integrator).
  **G11 handed back: `wip/pages-window` efedabd0 (pushed), on 3879e627 with G10's 835e2826 merged in (one
  conflict, `ui.go`, both sides kept); `internal/launcher` only.** Built: the setting `pages_open` (the
  window by default, also when the key is absent; the browser by choice) with two choices on the setup
  page; one place (`present.go`) that decides how anything is shown; with the window:
  `programs\tgarchive-window.exe -pages <launcher's page> -pages <the app's pages> [-pages <the viewer, browser
  kind only>] -data <folder>\pages-window`, started once per run, without any `WEBVIEW2_` variable, never a
  port 80, the program a plain file in the folder; the app's pages shown by themselves once (the next
  navigation of the launcher's page after they answer gets one 303, within 30 s); any non-zero end of the
  launcher's own window opens the browser once in the run with a fixed sentence and "Try the window
  again"; the person's close changes nothing; the launcher ends its own window at its end (a clean stop
  through its Ctrl-C helper, then by the handle after 3 s); the window restarted on the launcher's page
  alone when the pages end for good, and on the new addresses when they change; a second start of
  `tgarchive.exe` starts the window program once (an open one comes to the front; else that second start
  keeps its window while the first launcher answers). The coder's tests ok (11 window tests; the whole
  launcher package on the merged tree 70.5 s), three mutations caught, 0 test functions removed.
  **Two real tries of the real window by the coder (09:16:09 and 09:16:30; the window built from the
  viewer's bc6a44f5 in a scratch copy, an invented folder, stand-in collector and watchdog, the profile
  folders redirected, 127.0.0.1:8796 and 8797, no input, no picture):** the window started 110 and 160 ms
  after the launcher, was sent to the pages after about 0.5 s, still ran after 10 s with one visible window
  titled "tgarchive", ended with exit 0 on the launcher's clean stop, nothing left after 0.4 and 0.1 s.
  **Read by me:** `present.go` from `startWindow` to `keepWindow` (the guards on a start, whose end is
  whose, the fallback's once). **Decided by me before the review, for the fix round:** the choice "where
  the app's pages open" must be changeable from the launcher's own page after the first setup (today only
  by editing `tgarchive.json`); the report's list of what does not work in the window is out of date (the
  viewer's 113 d: the .txt download and a line for an outside link are the window's). For the integrator,
  from the coder: `deploy/folder/make-folder.sh`'s running check does not count `tgarchive-window*`
  processes (an update with the window open would move a running file).
  **G13's coder started 09:29** (the PC: 4.1 GB free, CPU 65%): `wip/pages-staging2` from the main head
  f7d6ca63, copy `wt-pages-staging2`.
  **Running now:** G11's independent review (one Opus reviewer, high effort, read-only, opens nothing;
  `BRIEF-G11-review.md`; it writes `REVIEW-G11-app-window.md`; scratch `wt-pages-review-g11-scratch`); the G13
  coder. **Next:** the review judged; G11's fix round with its coder (resumed); a second pass; then
  `runs-pages-launcher/run-listing.sh wt-pages-window wip/pages-window g11` and the entry.
- 11-16 09:51: **G11's independent review is back: "may be listed after these fixes": 2 must fix, 5 should fix,
  9 minor** (`REVIEW-G11-app-window.md`; six probes with the stand-ins, no window). Found sound: the browser
  mode opens the same addresses in the same order as the base and never redirects; the author's three
  mutations caught; the two skipped real tests skip safely. **The two must-fixes, both confirmed by
  probes:** (M1) the window that a SECOND start of `tgarchive.exe` keeps is outside every rule: it stays
  open naming the pages' port after the pages have ended, is never restarted when their address changes,
  and, opened during the setup, is sent by the once-only redirect to an address it does not name; and that
  second start is the way the page itself tells the owner to get the window back; (M2) after the pages end
  for good, a failed restart of the window opens the browser on the pages' ended address, so the failure
  page is shown nowhere. Should fix: the pages' port named before the checks that may refuse it; a failure
  after the person closed the window shown nowhere; the window outlives a launcher that dies; the browser
  viewer's address named whether or not it runs; a change of the setting leaving the window up.
  **Judged by me, all accepted:** (A) a second start asks the running launcher to show ITS window (one
  route for a program, refused for anything a browser sends, bounded) and opens none of its own, so the
  first launcher owns every window; (B) the one line the review names; (C) to (E) as the review asks, the
  window in a job of its own that ends with the launcher (the watchdog, the collector and the viewer stay
  outside it, as today); (F) the viewer's address is not named to the window at all in this piece (the
  default viewer has none); (G) my own point: the choice changed from the launcher's page, taking effect at
  once; (I) **a flake the reviewer met in an existing test, `TestEachFailureWordsOnce/collector_refused` (1
  of 30 on the base, 3 of 7 on the head, on a busy PC): the coder finds the cause first** and runs it 30
  times; (K) the main head merged in (G10 is in it as one commit). The same coder resumed by message
  (points A to K). No new real try unless the way the real window is started or ended changed beyond what
  the stand-ins show.
  **Running now:** G11's fix round (`wt-pages-window`); the G13 coder (`wt-pages-staging2`).
  **Next:** the round's difference read by me (the ask's route; the job); the reviewer's second pass; the
  listing script; entry "G11".
- 11-16 09:52: **G13 handed back: `wip/pages-staging2` 02b1ce2d (pushed), on the main head f7d6ca63.** Built:
  the copiers of the moment from `Copier.Load()` with the live poll (no statement); a speed "written to
  the library now, before its check" from the adapter's own readings of `Written` (kept 10 s; no speed
  across a restart, a count that went down, a clock that went back, a gap over the window; "measuring"
  without a pair; never "0.0": kB/s and "under 1 kB/s" below 1 MB/s) beside "copied and verified"; the
  staging disk away and resting from `Writer.StagingNow()`; the page's own "readable now" read kept,
  reworded. **Measured by the coder (one reading at 100,000 invented queue rows, best of 3, in one
  process, three runs):** before 237, 162, 160 ms; after 120, 97, 122 ms; statements a reading 6 before, 4
  after: looks like 25 to 50 % less for a steady reading on these runs (not "more than half"); a reading
  that has to ask the gauges costs what it did. The two reads run on the pages' handler goroutines after
  the collector's own lock is released (the brief was wrong on one point: `StagingNow` does not reach
  `speedLimited`). The coder's tests ok, two mutations caught, 0 test functions removed; seen in the
  built-in browser on invented data (desktop and 375 wide): busy with a written speed, "measuring", away
  in its "the pages can read it" form, resting with both times; not seen: the plain "away" form.
  **A departure I had not briefed, and the part that needs judging: a reading now asks the store's gauges
  only when a rule says so (`gaugesWanted`) and otherwise CARRIES THE HOLD OVER from the reading before**
  (the hold on making files wanted again: the one state on that page besides stuck copies that needs the
  owner). **Read by me:** `gaugesWanted`, `holdMarks` and where a reading takes the earlier hold. The rule
  asks at the first reading, while the last answer said held, when the store's 24-hour counts moved, when
  the reading itself counts copies put off under the hold, and when files are due with no copier busy. My
  doubt: a 24-hour sum can stay equal while a latch happens (one event leaves the window as another
  enters). **Decided by me:** the gauges are also asked whenever the last answer is older than 60 s; and,
  because the rule decides what the owner is told is needed, **one independent review after all, narrow**
  (`BRIEF-G13-review.md`: the rule against every way the store puts the hold on or off, the reader's holds
  in the waiting causes, the written speed's arithmetic and its shared samples, where the two reads are
  called and under which locks, the changed sentences, the two mutations by its own hand).
  **Running now:** G13's independent review (one Opus reviewer, high effort, read-only; it writes
  `REVIEW-G13-staging-live.md`; scratch `wt-pages-review-g13-scratch`); G11's fix round.
  **Next for G13:** the review judged; one fix round (the 60 s backstop with it); then its listing runs by
  a script like G9's (whole `internal/server`, `livepages`, the collector's staging and pages sets by name;
  the race detector on `livepages` whole and the server's staging tests by name: the adapter's samples and
  the carried hold are shared between requests) and the entry.
- 11-16 10:05: **G13's narrow review is back: "may be listed after these fixes": 1 must fix, 2 should fix, 5
  minor** (`REVIEW-G13-staging-live.md`). **The must-fix is my doubt, confirmed by two probes through the
  real adapter:** a hold going on at 11:59:50 while yesterday's hour leaves the 24-hour window keeps the
  marks at 21 and 21; 30 readings over 150 s asked the gauges 0 times and never showed the hold. The 60 s
  backstop fixes it only if it is timed from the gauges' last ANSWER (the reading's own time would never
  fire: a reading comes every 5 s). Should fix: the sentence "the store looks at the disk again by itself"
  is untrue once the store's own look has hung; a live poll with no copier busy can say due files are taken
  "within 5 s" on a reading that never asked for a reader's holds. Sound: no deadlock (neither read under
  the collector's lock), the written speed never across a restart, negative or absurd, the two mutations
  caught. **All accepted; the same coder resumed by message (six points).**
  `runs-pages-g13/run-listing.sh wt-pages-staging2 wip/pages-staging2 g13` is written (the clean merge;
  build, gofmt, vet; whole `internal/server`, `livepages`, the collector's staging, pages and held-stop
  sets by name; the race detector in a container on `livepages` whole and the server's `TestStaging`; the
  push). Board message 118 (the three pieces' states; one thing for Core's list: a read from memory for
  "wanting again held" and a reader's holds; the mirror's and Core's messages read: **K14's coder does the
  three wirings for the door**; G12 grows by the chat list's interval on the Settings page).
  **Running now:** G11's fix round (`wt-pages-window`); G13's fix round (`wt-pages-staging2`).
  **Next:** each round's difference read; G11's second review pass; G13: my read of the backstop, then its
  script; the entries.
- 11-16 10:11: **G13's fix round handed back: `wip/pages-staging2` 2741af3a (pushed), on f7d6ca63; all six points
  done.** The backstop: `holdState.At` is when the gauges last answered; they are asked again once that is
  60 s old; an answer that old is "not known" and the page says so under "What needs you" and on the
  Overview. The reviewer's probes are tests (`TestStagingHoldBackstop`: equal marks across a latch, readings
  every 5 s for 150 s: 19 asks, the hold shown 60 s after the last answer; with the backstop removed: 0 asks
  and it fails). A live answer that cannot know a reader's holds says the due files without a time and has
  the next reading ask (`holdsWanted`); the two "away" sentences reworded; the written count's order and the
  clock-back rule tested; "1000 kB/s" gone; `dirty` set again after a release. Left, said: "nothing written
  in the last N s" while copiers only check (the memory cannot tell). **Read by me:** the difference of
  `stagingread.go` (the backstop's place and its clock; the carried `At`; the atomic flag): as decided. No
  second review pass (the probes are tests, the change is small and read).
  **Running now, started 10:11: G13's listing script** (one background call of mine; `SEQ=1`, one step after
  the other, because the PC had 2.9 GB free and CPU 64%): the clean merge of the head; the race container
  first (`livepages` whole, the server's `TestStaging`), then build, gofmt, vet, whole `internal/server`,
  `livepages`, the collector's staging, pages and held-stop sets by name; the push
  (`runs-pages-g13/g13-<head>.summary`). The entry is drafted in the scratchpad. **Also running:** G11's fix
  round. **Next:** entry "G13" if every line is exit 0; G11's round read and its second review pass.
- 11-16 10:14: **G11's fix round handed back: `wip/pages-window` 10f62435 (pushed), holding the main head f7d6ca63**
  (merged as 1a0cf125; four files conflicted only because the head's launcher code is the 835e2826 it had
  merged already: its own side kept). Every lettered point built: a second start opens no window, it sends
  one `POST /show-window` (header `X-Tgarchive-Show: 1`; refused for anything a browser adds, another Host,
  another method) to the running launcher and ends; the launcher then, at most once in 2 s, brings its
  window to the front by one start of the window program, starts a closed one again, or opens its page in
  the browser; `keepWindow` is gone; the fallback after the pages ended opens the launcher's page; the
  pages' port named only after the watchdog has started; a failure after the person's close starts the
  window once; **the window, and only it, in a kill-on-close job** (opened by its number, taken only when
  its creation time matches); the viewer's address no longer named; **a form "Where the app's pages open"
  on the running and failure views**, stored first, at once in both directions. **The flake's cause, by
  the coder: the test's stand-in watchdog wrote its last status with one rename that Windows refuses under
  a reader** (the real watchdog tries again); the stand-in fixed; the test 30 of 30 on the head. The whole
  launcher package on the merged tree ok 79.3 s; four mutations caught; minors 7 and 8 left with reasons
  (a browser tab in the launcher's last milliseconds; the once-only redirect can be taken by any document
  navigation within 30 s until the window's user-agent word exists).
  **One more real try by the coder, with its reason (the job nests with the real window's own job and its
  engine processes; a stand-in cannot show that): 10:08:59, the launcher's process killed from outside: the
  window gone 50 ms later, 0 of its 7 processes left after 252 ms, the watchdog's stand-in still running.**
  The coder's doubt to tell the owner later: after "Save and start" the setup's window is closed and
  opened again with the pages named (the window's addresses are fixed for its life).
  **Found by me at 10:13 and ended at 10:14: a test process of the coder's left running** (its preview
  test serving the changed views on 127.0.0.1:8799, started 10:11:12, after its last word; identified as
  `launcher.test.exe` running `TestPreviewWindowPages` from a go-build temporary folder; ended by its
  process number after that check; no listener left on 8786 to 8799). One command of mine: a judgement.
  **Read by me:** `showAsked`, `frontWindow`, the route's guard, the job's making and `allowForeground`.
  **Running now:** G11's second review pass (the same reviewer resumed by message: the ask and its bound,
  the second start's side, the job and what is in it, the bound on starts again, the choice form, the
  flake's cause, the four mutations by its own hand, the report's table); G13's script (the race container
  exit 0, no data race, 43 passed; build, gofmt, vet exit 0; whole server, livepages, the collector's sets
  to come).
- 11-16 10:17: **G13 IS LISTED, READY: `MERGE-QUEUE.md` entry "G13", `wip/pages-staging2` 2741af3a (pushed), holding
  the main head f7d6ca63.** The script's lines, all exit 0 (`runs-pages-g13/g13-2741af3a.summary`; one
  background call of mine, a script, one step after the other): the race container on `livepages` whole and
  the server's `TestStaging` (43 passed, 6 skipped), no data race (its log read: tests ran in both
  packages); build, gofmt, vet; whole `internal/server` 164 s (195 passed, 2 skipped); whole `livepages`
  (21); the collector's staging, pages and held-stop sets by name 24 s (22 passed); 0 test functions
  removed; 16 files differ from the head. Board message 119.
  **Running now:** only G11's second review pass. **Listed, not merged:** G13. **Next:** the second pass
  judged; a last round if it asks one; `runs-pages-launcher/run-listing.sh wt-pages-window wip/pages-window
  g11`; entry "G11" and a line on the owner's item 35 saying when the window itself can be seen (it needs
  the viewer's window piece merged and the folder rebuilt).
- 11-16 10:31: **G13 IS MERGED** (the integrator, 10:18, head b8dd4ab; installed 10:18).
  **G11's second review pass is back: "may be listed after these fixes": 1 must fix, 2 should fix, 7 minor**
  (the end of `REVIEW-G11-app-window.md`, "Second pass (10f62435)"). Fixed: both first-pass must-fixes and
  S1 to S4; the four mutations caught by its own hand; the flake's fix confirmed (15 of 15). **The new
  must-fix, confirmed by two probes:** the pages are named to the window only while the window mode is in
  force, so a change of the choice TO the window while the app runs opens a window that cannot reach the
  pages while the page says they are in it, and "Try the window again" after an early failure sends the
  window to an address it does not name. Should fix: the extra start that brings the window to the front
  can become the only window and is then ended after 10 s; a change to the browser during a window restart
  can leave a window in browser mode. The reviewer also shows how to avoid the close-and-open after "Save
  and start" (name the pages' port at the setup when nothing answers on it then; the window is sent there
  only after the launcher's own check has seen the pages' mark). **All accepted by me, that last one
  taken; the same coder resumed by message at 10:29 for a second and last round (six points; no real try;
  told that its preview process had been left running and to leave none).**
  **THE INTEGRATOR'S SIGNAL OF 10:19 (read by me at 10:30, after the round was sent): usage at 88% of all
  models' week, 83% of this model's: finish what is in flight to its next listing and stop; start nothing
  new.** G11's fix round was in flight as a piece already in review: it goes on to its listing (the round,
  one closing look by the reviewer at the round's lines, the listing script, the entry). **Nothing else is
  started: G12, the next pieces and every reading for a brief wait for the owner's word that usage is
  reset.**

### STATE FOR A TAKE-OVER (P4, 11-16 10:31; this block replaces the one of 09:16 above)
Read `BOARD.md` (my row; the integrator's of 10:19: START NOTHING NEW until it lifts the signal; messages
110 to 119 and the viewer's 113 and 116 for the window), then this block.
1. **Merged today:** G8 (the door for the owner's clicks), G9, G10 (the folder box and the setup's look),
   G13 (the Staging page on the store's reads of the moment; b8dd4ab). Nothing of mine is listed and
   unmerged.
2. **In flight, to be taken to its listing and no further: G11, the app in a window of its own**
   (`wip/pages-window`, copy `wt-pages-window`; head 10f62435 holding f7d6ca63 before the round now running).
   Its coder is in a second and last fix round since 10:29 (my message to it names six points: the must-fix
   N1, N2, N3, the first start without a close-and-open, the minors, the report). **When it hands back:**
   (a) read the round's difference in `present.go` (where the pages are named; the adoption of a front
   start; the setup's look at the pages' port); (b) ONE closing look by the reviewer on those lines only
   (resume it by message, as G10's third look was asked; it opens no window); (c) if it says "may be
   listed": `bash runs-pages-launcher/run-listing.sh wt-pages-window wip/pages-window g11` in one background
   call (the clean merge of the head; build, gofmt, vet for Windows and Linux; the launcher whole on
   Windows; the race detector in a Linux container; the push; about 3 minutes); (d) entry "G11" at the end
   of `MERGE-QUEUE.md` in the form of entry "G10" (what only the owner can see: the window itself, the
   pages in it, the folder box over it, closing it and double-clicking again, a PC without the web
   component; known: the app's pages have no link back to the launcher's page; links to Telegram posts
   are shown to copy; the once-only jump can be taken by any navigation within 30 s; for the integrator:
   `make-folder.sh`'s running check does not count `tgarchive-window*`); (e) a line on the owner's item 35:
   the window itself is seen only when the viewer's `wip/b-winpages` is merged too and the folder rebuilt;
   until then the launcher opens the browser and says why. Check that no process of the coder's is left
   (its preview test was left on 127.0.0.1:8799 once).
3. **NOT started, waiting for the signal to be lifted, in this order:** G12 (the switch "mirror chats I join
   by themselves" from `AutoNew`, and the chat list's interval, 10 minutes by default, beside the gathering
   on the Settings page: the mirror's messages 106 b and 115 b; when M10 is listed); the watchdog's line on
   the Overview (when Core answers my 103 a); stage B of the folder (the copy's choices and the helper's
   address on the Settings and Staging pages); the backup's button (when Core has its door); a link from
   the app's pages back to the launcher's page, and the pages adapting to the window by its user-agent
   word (` tgarchive-window`), once the viewer's window piece is merged.
4. **How the work goes:** as the blocks of 08:24 and 09:16, and: read the board before every message to a
   coder (the integrator's signal of 10:19 was read eleven minutes late); a coder may leave a process
   behind after its last word: look for one at every hand-back; with the PC under 3 GB free, run a
   listing's steps one after the other (`SEQ=1` in `runs-pages-g13/run-listing.sh`).
5. **Running now:** only G11's coder. Copies that can go (all merged): `wt-pages-small`, `wt-pages-door`,
   `wt-pages-setup`, `wt-pages-staging2`; `wt-pages-window` after G11's merge; scratch
   `wt-pages-review-g8-scratch`, `-g10-`, `-g11-`, `-g13-`; run logs `runs-pages-g8`, `-g9`, `-g13`,
   `runs-pages-launcher`; and P3's list. Removing them is a clerk's step after a check that each tree is in
   the main branch; not now.
- 11-16 10:45: **G11's second fix round came back (f9afdd05; six points done; no process left: checked), the
  reviewer's closing look said "may be listed"** (the end of `REVIEW-G11-app-window.md`: the must-fix sound,
  an adopted front start inside its job, the setup's look bounded at 3 s; three minors for a later piece).
  **G11 IS LISTED, READY: `MERGE-QUEUE.md` entry "G11", `wip/pages-window` 232dd7cd (pushed), holding the main
  head 1d9cd6e5.** The script's lines, all exit 0 (`runs-pages-launcher/g11-232dd7cd.summary`; one background
  call of mine, a script, one step after the other: 2.8 GB free): the clean merge; the launcher and the
  opener under the race detector in a Linux container (23 passed, 69 skipped as Windows-only), no data
  race; build, gofmt, vet for Windows and Linux; whole `internal/launcher` and the opener on Windows 102 s
  (96 passed, 6 skipped); 0 test functions removed; 19 files differ from the head; the push. Board message
  121 (the integrator: merge it with the viewer's window piece or rebuild the folder only when both are
  in; the viewer: the launcher as built); one line more on the owner's item 35.

### STATE FOR A TAKE-OVER (P4, 11-16 10:45; this block replaces the one of 10:31 above)
Read `BOARD.md` (my row; the integrator's signal of 10:19: START NOTHING NEW until it is lifted there;
messages 118 to 121; the viewer's 113 and 116), then this block.
1. **Merged today:** G8, G9, G10, G13. **Listed, READY, waiting for the integrator: G11**
   (`wip/pages-window` 232dd7cd: the app in a window of its own, the launcher's side; entry "G11"). If it
   is handed back for a merge of the head: `SEQ=1 bash runs-pages-launcher/run-listing.sh wt-pages-window
   wip/pages-window g11` (the clean merge, the runs, the push; about 3 minutes); a conflict is a coder's.
2. **NOTHING OF THIS TRACK IS RUNNING. Nothing is started while the signal holds.**
3. **When the signal is lifted, in this order:** (a) G12 when the mirror's M10 is listed: the switch
   "mirror chats I join by themselves" mapped from `AutoNew`, its words as the mirror gives them, and the
   chat list's interval (10 minutes by default) beside the gathering on the Settings page (the mirror's
   106 b and 115 b); (b) three minors of G11's closing look and what the window's next build allows: a link
   from the app's pages back to the launcher's page, the pages adapting by the user-agent word
   ` tgarchive-window`, the once-only redirect given only to the window; (c) the watchdog's line on the
   Overview when Core has answered my 103 a; (d) stage B of the folder (the copy's choices and the helper's
   address on the Settings and Staging pages); (e) the backup's button when Core has its door; (f) if Core
   gives a read from memory for the hold and a reader's holds (my 118 b), the Staging page stops asking
   the gauges.
4. **For the owner, open:** item 31 (the first real start of the folder: done in part at 07:40, the setup
   not saved), 32 (the first real sign-in from the page), 33 (the first real mirror from the page), 35 (the
   setup with the folder box and the look; the window when the viewer's piece is in too).
5. **How the work goes:** as the earlier blocks. Copies that can go after a check that each tree is in
   the main branch (a clerk's step, not now): `wt-pages-small`, `-door`, `-setup`, `-staging2`, and
   `-window` after G11's merge; the review scratch folders `-g8-`, `-g10-`, `-g11-`, `-g13-`; the run logs.

## SESSION P5 (took the track over 11-16 12:42, started by the integrator at the owner's word; P4 is retired)

### The board's Pages row as P4 left it (moved here by P5 at 12:50 when the row was cut; one line)
| Pages and chats: the app's own pages (Chats, Queue, Staging, Settings) and what they set in the catalogue | **session P4** (pages; took the track over 11-16 06:57 from P3, started by the owner; sessions P2 and P3 are retired: do not wait for them or message them) | `internal/server`, the catalogue's chat and topic settings | **11-16 06:57 (P4): TAKEN OVER. G4 is merged (788ebf7). G7 (`wip/pages-launcher2` 77b7fdf9) stays LISTED and READY: checked 06:56 with `git merge-tree`, it merges into 788ebf7 with no conflict. 07:01: BEING BUILT: "G8", the door for the owner's clicks on the collector's listener (`BRIEF-G8-clicks-door.md`, `wip/pages-door` from 788ebf77 in `wt-pages-door`, one Opus coder; message 101 says what the door is). 07:48: "G9" IS LISTED, READY: `wip/pages-small` 150a8b33 (`MERGE-QUEUE.md` entry "G9" at the end of the file; it holds e4a4a61d; whole server, livepages and `cmd/tgarchive` and the collector's pages and mirror sets ok; one lent line in the collector's `pages_mirrors.go`). THE OWNER'S THREE WORDS ON THE SETUP (the integrator, 07:44) ARE CUT IN TWO (message 108): "G10", Windows' own folder box beside each folder and the launcher's pages in the look of the app's pages, IS WITH A CODER since 07:50 (`BRIEF-G10-setup-folder-box-and-look.md`, `wip/pages-setup` from dbca91d4 in `wt-pages-setup`); "G11", the app in a window of its own, when the viewer has said what the launcher may call. 09:51: "G11": THE REVIEW IS BACK ("may be listed after these fixes": 2 must fix, both about which window is whose after a second double-click and after the pages end; 5 should fix; 9 minor); IN ITS FIX ROUND: a second start asks the running launcher to show its own window; the window in a job that ends with the launcher; the choice changed from the launcher's page. 10:45: "G11" IS LISTED, READY: `wip/pages-window` 232dd7cd (`MERGE-QUEUE.md` entry "G11" at the end of the file; it holds 1d9cd6e5; `internal/launcher` only; two review passes and a closing look, "may be listed"; the launcher whole on Windows and under the race detector in a container ok). **NOTHING OF THIS TRACK IS RUNNING NOW; under the signal of 10:19 I start nothing and go quiet. READY FOR A TAKE-OVER: the block of 10:45 at the end of `SESSION-PAGES-PROGRESS.md`.** 10:31 (the integrator's signal of 10:19 read 10:30): G13 IS MERGED (b8dd4ab): thank you. **IN FLIGHT, to its listing and no further: "G11"** (`wip/pages-window`): its second review pass came back at 10:28 ("may be listed after these fixes": 1 must fix, 2 should fix), its coder is in a second and last round since 10:29 (sent before I had read the signal; a piece already in review), then one closing look at those lines, the listing script (3 minutes) and the entry. **Nothing else of this track runs or is started; READY FOR A TAKE-OVER: the block of 10:31 at the end of `SESSION-PAGES-PROGRESS.md`.** 10:17: "G13" WAS LISTED, READY: `wip/pages-staging2` 2741af3a (`MERGE-QUEUE.md` entry "G13" at the end of the file; it holds f7d6ca63; the Staging page on K15's reads of the moment; one narrow independent review; whole server and livepages, the collector's named sets and the race run ok; 2 lent lines in Core's `pagesstaging.go`). 10:14: "G11": THE FIX ROUND IS BACK (`wip/pages-window` 10f62435, holding f7d6ca63: a second start asks the running launcher to show its window; the window in a kill-on-close job of its own; the choice changed from the launcher's page), read, IN ITS SECOND REVIEW PASS. "G13": the fix round is back (2741af3a: the gauges asked at least every 60 s from their last answer), read, IN ITS LISTING RUNS (the race run clean so far). 10:05: "G13": THE NARROW REVIEW WAS BACK ("may be listed after these fixes": 1 must fix: the carried hold could stay "not held" while the store's 24-hour counts stayed equal; 2 should fix; 5 minor); IN ITS FIX ROUND (the gauges asked at least every 60 s from their last answer). "G11" is in its fix round. Message 118. 09:52: "G13" WAS HANDED BACK (`wip/pages-staging2` 02b1ce2d on f7d6ca63: the copiers of the moment, a written speed beside "copied and verified", staging away and resting from the store's memory; a steady reading measured at about 100 to 120 ms where it was about 160 at 100,000 invented rows), read, IN A NARROW INDEPENDENT REVIEW (it carries the hold over between readings under a rule of its own: that rule is what is reviewed). 09:29: G10 IS MERGED (f7d6ca6; the folder rebuilt 09:18): thank you; item 35 says READY. "G11" IS HANDED BACK (`wip/pages-window` efedabd0, holding G10's 835e2826; `internal/launcher` only: a setting "where the app's pages open", the window started instead of the browser, the browser as the fallback said in words, the pages shown by themselves once, the launcher ends its own window), read, IN ITS INDEPENDENT REVIEW. "G13" (the Staging page on K15's two reads of the moment; `BRIEF-G13-staging-live-reads.md`, `wip/pages-staging2`) IS WITH A CODER since 09:29. 09:16: "G10" WAS LISTED, READY: `wip/pages-setup` 835e2826 (`MERGE-QUEUE.md` entry "G10" at the end of the file; it holds efac56ff; `internal/launcher` and one case in `cmd/tgarchive-open/main.go`; two review passes and a third look, "may be listed"; the launcher whole on Windows and under the race detector in a container ok). What only the owner can see is item 35. "G11" is with its coder, built on G10. 09:10: "G10": THE SECOND FIX ROUND WAS BACK (`wip/pages-setup` a142c68d; the must-fix and both should-fixes done, each with a test and its mutation), read, in a narrow third look by the reviewer; then its listing runs. The viewer's 113 (the window's security review) read 09:09: its rules for the launcher are with the G11 coder; thank you for the three decisions (the .txt download, the line for an outside link, the user agent's word): nothing in `internal/server` is needed for the window. 09:00: G8 IS MERGED (efac56f): thank you. "G10": THE SECOND REVIEW PASS IS BACK ("may be listed after these fixes": 1 must fix: a folder-box helper not seen to end holds the box for the launcher's life; 2 should fix; 7 minor); IN ITS SECOND AND LAST FIX ROUND. "G11" is with its coder. 08:52: "G10": THE FIX ROUND WAS BACK (`wip/pages-setup` 3879e627: the folder box in a helper process `tgarchive.exe -folder-box`, a choose only reads, "Close the folder box"), read, IN ITS SECOND REVIEW PASS. "G11", THE APP IN A WINDOW OF ITS OWN, IS WITH A CODER since 08:52 (`wip/pages-window` from 3879e627 in `wt-pages-window`). 08:34: "G10": THE REVIEW WAS BACK ("may be listed after these fixes": 0 must fix, 3 should fix, 10 minor; every COM call checked right); IN ITS FIX ROUND: the folder box moves into a short-lived helper process of the launcher's own (a fault in it cannot end the launcher), a choose only reads the folder, a button closes an open box. "G11", THE APP IN A WINDOW OF ITS OWN, IS BRIEFED to the viewer's mode as built (`BRIEF-G11-app-window.md`; the viewer's 111 of 08:27 read 08:33); its coder starts on G10's head when the fix round is back. 08:24: "G8" IS LISTED, READY: `wip/pages-door` 1decd1fb (`MERGE-QUEUE.md` entry "G8" at the end of the file; it holds 6af0c09a; two review passes, "may be listed"; whole actdoor, server, livepages and collector ok; the race run on the door's tests clean; lent lines in Core's `pages.go` in three commits; nothing calls the door yet). 08:19: "G10" IS HANDED BACK (`wip/pages-setup` 1a7c0be4, `internal/launcher` only: "Choose…" with Windows' own folder box beside each folder, the launcher's pages in the app's look), read, IN ITS INDEPENDENT REVIEW; not seen by anyone: the box over a browser with the keyboard in it (the owner's to see). G8's runs so far exit 0 with no data race; the whole collector is running. 08:03: "G8": THE SECOND REVIEW PASS WAS BACK ("may be listed": 0 must fix, 0 should fix, 5 minor, the wording applied by a Sonnet clerk: `wip/pages-door` 59ff89b6); IN ITS MERGE OF THE HEAD AND ITS LISTING RUNS (a script; message 111). 07:54: "G8": THE FIX ROUND WAS BACK (`wip/pages-door` 0521253c, holding e4a4a61d; every finding done; the Settings rows opened in a browser), read, IN ITS SECOND REVIEW PASS; then the head merged in and the listing runs by a script. 07:43: "G8": THE REVIEW WAS BACK ("may be listed after these fixes": 1 must fix, a rule for the caller until K14; 3 should fix; 10 minor; message 106); IN ITS FIX ROUND with the same coder, which also merges e4a4a61d in; then a second review pass and the listing runs. "G9": the head merged in (150a8b33), its runs once more on that tree. 07:30: "G8" (`wip/pages-door` 8a8a5f35) was handed back and read (message 104 says what the door is as built). 07:24: "G9" (`wip/pages-small` 8d5ba742) IS HANDED BACK, read, in its listing runs (four of five points built; the watchdog's line waits for one thing of Core's: message 103). 07:04: ALSO BEING BUILT: "G9", five small things (`BRIEF-G9-pages-small.md`, `wip/pages-small` from 788ebf77 in `wt-pages-small`, a second Opus coder): one form for a time on every page, the mirror's bad-record count and the watchdog's state on the Overview, `tgarchive app` refusing a catalogue newer than the build, a sentence for a protected chat. Two coders of this track run; G7 waits for its merge.** Earlier: **11-16 06:19 (P3). TWO entries LISTED and READY, both holding the main head d1ebd1a: "G4" (`wip/pages-g4` a1c5d5c8: the mirror from the Chats page; message 99) and "G7" (`wip/pages-launcher2` 77b7fdf9: the launcher reads the watchdog's status through its door, starts the viewers with `-staging`, and tells the collector's own answers by a header word; a few lent lines in Core's `pages.go`, commit 01d8aa4a). No conflict between them. Merged: G1, G1s, G2, G2c, G6, G3, G5. The owner's open items: 31, 32, 33. Nothing of this session is running. READY FOR A TAKE-OVER: the block at the end of `SESSION-PAGES-PROGRESS.md`.** Earlier: **11-16 06:11 (P3). LISTED and READY again: entry "G4", `wip/pages-g4` a1c5d5c8, holding the main head d1ebd1a (message 99): G1's four tests restored, the lent lines on M11's rule, whole server, livepages and the collector's named sets ok, the race run on the lent lines' tests ok. The owner's first real click is item 33. The launcher's follow-up "G7" (`wip/pages-launcher2`) is in its listing runs (a script; `runs-pages-g7/listing.summary`).** Earlier: **11-16 05:51 (P3). The integrator's word taken: the G4 coder merges d1ebd1a (M11 and K9b) into `wip/pages-g4`, not 6365a08a. Found by that coder at the merge: G4 as listed (9b4e265a) had replaced G1's `pages_mirror_test.go` and would have removed its four tests from the main branch: they are restored in this merge (the file as the main head has it; the page's tests in a file of their own). The lent lines are brought up to M11's rule in a commit of their own. Then a clerk's runs, then entry "G4" READY with the new head. The launcher's follow-up "G7" is with a second coder.** Earlier: **11-16 05:50 (P3). Two coders: (1) entry "G4" is ON HOLD by me while a coder merges the main head 6365a08a (M11) into `wip/pages-g4` and brings the lent lines up to M11's rule (`BRIEF-G4f-merge-m11.md`, copy `wt-pages-g4`); (2) the launcher's follow-up "G7" (`BRIEF-G7-launcher-followup.md`, `wip/pages-launcher2` from 6365a08a, copy `wt-pages-l2`): the status file through `watchdog.ReadStatus`, the viewer started with `-staging`, the collector's three own answers marked by a header word (a few lent lines in Core's `pages.go`, one commit). Then a clerk's runs and the entries.** Earlier: **11-16 05:48 (P3). Entry "G4" is ON HOLD by me (do not merge 9b4e265a): the main head moved to 6365a08a (M11); one test file conflicts and the lent lines must follow M11's rule (clear the mirror's end of a read at a new want). With a coder now (`BRIEF-G4f-merge-m11.md`, copy `wt-pages-g4`); then a clerk's runs; then READY with the new head.** Earlier: **11-16 05:44 (P3). LISTED and READY: entry "G4", `wip/pages-g4` 9b4e265a, holding the main head a37ed4c3: the mirror from the Chats page, joined to the mirror's door; two review passes; one wish carried out on the fake Telegram by the page's own path; whole `internal/server` and the collector's mirror, staging and sign-in sets ok; the race detector on the server's and the collector's mirror tests ok (2,526 s, no data race); 69 lent lines in the mirror's door as one commit (message 96). The owner's first real click is item 33. Merged: G1, G1s, G2, G2c, G6, G3, G5. Owed, small: the launcher's follow-up (message 94 d). Nothing of this session is running. READY FOR A TAKE-OVER: the block at the end of `SESSION-PAGES-PROGRESS.md`.** Earlier: **11-16 04:24 (P3). The mirror page's second review pass is back (`REVIEW-G4-mirror-page-2.md`: 1 must fix, 7 should, 8 minor): a chat that was never read cannot be mirrored once its size was asked (the door's want writes no approval onto an existing estimate): its last fix round (G4d) is with the same coder, with the door's cure as lent lines in one separate commit (message 95, for the mirror track to take or replace). G5 is listed READY (639ed1c0).** Earlier: **11-16 04:09 (P3). The mirror page's conversion round is back: `wip/pages-g4` 550be61c, holding 6556113: the page joined to the mirror's merged door (M9), and ONE WISH CARRIED OUT ON THE FAKE TELEGRAM through the pages for the first time (a rig test: 1 create, 2 forwards, 1 `help.getConfig` for a chat of 173 files; a never mark refuses the yes; a stop mid-way sends nothing more; no `-auto-mirror` needed). Its coder now merges the Staging page's head (639ed1c0) in; then the reviewer's pass, the runs by a clerk, entry "G4". The owner's one page (`DESIGN-G4-mirror-from-page.md`, item 30) is rewritten from the door as built.** Earlier: **11-16 04:03 (P3). LISTED AGAIN, READY: entry "G5", `wip/pages-g5-main` 639ed1c0, holding the main head 6556113 (the Staging page with the sign-in page merged in, both sides kept; whole `internal/server` 150.8 s, `livepages` and the collector's named tests ok on that tree). The mirror page's conversion round is with its coder; it takes this head in before its runs.** Earlier: **11-16 03:55 (P3). G3 is merged (6556113). G5 was handed back for a merge of that head (five files where both add lines; no fault): its coder merges 6556113 into `wip/pages-g5-main` now (both sides stay), then a clerk runs whole `internal/server`, `livepages` and the named collector tests once, and the new head goes into entry "G5". The mirror page (G4): its conversion round to the mirror's merged door (M9) is with its coder since 03:55 (the main head merged in, the adapter on the real types, a rig test of one wish carried out on the fake Telegram); it takes G5's new head in before its runs.** Earlier: **11-16 03:19 (P3). LISTED and READY: entry "G5", `wip/pages-g5-main` 7739148c, holding 8aed433d: the Staging page (one review, its fix round; whole `internal/server` 147 s and `livepages` ok; the named race runs ok, no data race). Also READY: "G3" (f43f140b). Waiting on the mirror's door: G4. Owed, small: the launcher's follow-up (message 94 d). Nothing of this session is running. STILL READY FOR A TAKE-OVER: the block at the end of `SESSION-PAGES-PROGRESS.md`.** Earlier: **11-16 03:18 (P3). LISTED AGAIN, READY: entry "G3", `wip/pages-g3-main` f43f140b, holding d10e3bd9 (the sign-in page): the test it was handed back for is fixed (its order made certain; 20 of 20 by name), and on that merged tree whole `internal/collector` (812 s), `internal/server` (153 s) and `livepages` passed. The Staging page's fix round is back (`wip/pages-g5-main` 7739148c, holding 8aed433d): its runs are with a clerk; entry "G5" follows.** Earlier: **11-16 02:43 (P3; still READY FOR A TAKE-OVER: no fresh session has written here). The Staging page (G5) is HANDED BACK: `wip/pages-g5-main` 84d9991a on 5b29e28b (pushed, clean; the seam, one verdict line, the queue's numbers, "what needs you" with "Try its copy again" for a stuck file and "Let it go on"; 13 tests, 5 mutations, seen in a browser at two widths); its independent review runs since 02:43 (`BRIEF-G5-review.md` -> `REVIEW-G5-staging.md`). Messages 88, 89 and 92 read 02:43: owed by pages for the launcher once Core's K12 is merged: read the watchdog's status file through its exported door (read again on a miss); and hand the viewer the staging folder (`-staging`).** Earlier: **11-16 02:04 (P3). LISTED and READY: entry "G3", `wip/pages-g3-main` 884c3ce3 (it holds dbc2f7d5): sign in from the Accounts page, an account added while the program runs, a Quit held for a code; two review passes, two fix rounds; whole collector, server and livepages ok on Windows; the server ok under the race detector; the whole collector under it: no data race, one test of its own failed (it looked once at a task's start) and is fixed and run by name 5 of 5 under the detector. The owner's first real sign-in is item 32. G6 is merged (5b29e28b). Waiting: the mirror page (G4) for the mirror's door. **The Staging page (G5) is with a coder since 02:05** (`wip/pages-g5-main`, a new copy `wt-pages-g5m` from the main head; `BRIEF-G5-staging-page.md`). **This session's context is long: READY FOR A TAKE-OVER at this point** (everything else of the track is listed or waiting on another track; the block "STATE FOR A TAKE-OVER (P3, 11-16 ...)" at the end of `SESSION-PAGES-PROGRESS.md`); until a fresh session writes on this row I read the G5 coder's hand-back and nothing new is started here.** Earlier: **11-16 01:41 (P3). LISTED and READY: entry "G6", `wip/pages-g6` 04b39389 (it holds dbc2f7d5): the one program to open with its own folder, stage A (the launcher `tgarchive.exe`, its settings, the setup page, the folder's build script); two review passes and three fix rounds; whole `internal/launcher` and `internal/server` ok on Windows; the race detector only on the 11 tests that run off Windows. No real program was started with it yet: the owner's first real start is item 31, after the integrator builds the folder (message 86). The sign-in page's last run (the race detector on the whole collector) is still going.** Earlier: **11-16 01:10 (P3). The launcher's second pass is back (`REVIEW-G6-launcher-2.md`: no must fix, 4 should, 7 minor); a last small round (G6c) is with the same coder; entry "G6" follows it. The sign-in page: every run passed but the last, the race detector on the whole collector (since 00:28); its race run of the server ended ok (1,270 s).** Earlier: **11-16 01:02 (P3). The launcher's fix round is back: `wip/pages-g6` 19a64824 (it holds the main head dbc2f7d5; every finding of the review fixed: the viewer's window shows, no bind while waiting, "already open" means this folder's own watchdog, every stop through a held handle and only for this folder's program files). Its runs on the merged tree: whole `internal/launcher` on Windows ok (36 s, and three clean whole runs by its coder), whole `internal/server` ok (166 s), a build of everything; under the race detector only the 8 tests that run off Windows (no data race; the Windows process tests cannot run under it here: no C compiler for a Windows race build). Its second independent pass runs since 01:02 (the same reviewer; `REVIEW-G6-launcher-2.md`); entry "G6" follows it. The sign-in page's Windows runs passed (whole collector 759 s); its two race runs are still going.** Earlier: **11-16 00:28 (P3). The sign-in page's second fix round is back: `wip/pages-g3-main` 0926a727, holding the main head dbc2f7d5 (the second pass's 10 findings fixed: a hanging sign-in step no longer blocks a stop; a refusal is remembered; the pages' stop no longer waits for idle connections). ITS FULL RUNS ARE GOING, once, since 00:28: whole `internal/collector`, `internal/server`, `livepages` on Windows; the race detector on the whole collector (bound 150 m; 82 minutes last time) and on the server; entry "G3" follows them. The mirror page's fix round is back too (`wip/pages-g4` 9c98e3dd: the three must-fixes and every should-fix): it is NOT listed inert: it waits for the mirror's door (M9 with M9b, message 84: `Offers`, `Stopped`, `Block` in `ChatState`; the settle word with the block's token), then one conversion round, one review pass, one set of runs. G2c is merged (dbc2f7d5). Running besides: the launcher's fix round (G6b).** Earlier: **11-16 00:18 (P3). READY: entry "G2c", `wip/pages-g2c` abda0d40 (on 10a9e3a8): the Queue page's follow-up; its race run of the server ended ok (1,107 s, no data race); whole `internal/server` 149.8 s and the rig tests ok.** Earlier: **11-16 00:18 (P3). The launcher's independent review is back (`REVIEW-G6-launcher.md`: 2 must fix, 9 should, 13 minor): its fix round (G6b) is with the same coder since 00:18. The must-fixes: the viewer's window would never appear (every child was started hidden, and Windows turns a hidden child's first "show" into "hide"); a false "the collector refused to start" (the launcher bound the pages' port itself while waiting: 3 failures in 95 starts). Also decided: "already open" means this folder's own watchdog running and the pages answering; a leftover collector is ours only by its program file, name and start time; every stop by a held process handle, never by number.** Earlier: **11-16 00:10 (P3). The mirror page's independent review is back (`REVIEW-G4-mirror-page.md`: 3 must fix, 13 should, 12 minor): its fix round (G4b) is with the same coder since 00:10 (a stop never ended by the chosen-chats path; a settle word carries its block and batch; the offers per block word from one tested table); message 83 asks the mirror track for the door's part; the owner's one page corrected again (it had said "tried on the fake Telegram": it has mirrored nothing yet).** Earlier: **11-16 00:03 (P3). LISTED: "G2c", `wip/pages-g2c` abda0d40 (on 10a9e3a8): the Queue page's follow-up (the retry's write off the set-aside range: 8 to 26 ms where it held the writer 246 to 314; the numbers of one answer from one reading; no reread in a storm); whole `internal/server` ok 149.8 s, the rig tests ok; NOT READY only for its race run of the server, going since 23:59. The sign-in page's second pass is back (`REVIEW-G3-signin-2.md`: 1 must fix, 3 should, 6 minor; 13 of 18 closed, 4 partly): the must-fix is that nothing can stop the program while a sign-in step hangs; its second fix round (G3c) is with the same coder since 00:03, which also merges the main head in; then my full runs. Running besides: the reviews of G6 and G4.** Earlier: **11-15 23:55 (P3). The mirror page (G4) is HANDED BACK: `wip/pages-g4` 1929057a on 2ea9b465 (pushed, clean): the page side built to the mirror's message 77 on a fake (seam, 10 routes, the Chats page's mirror cell, plan and yes with its token, stop, never, allow, the settle words, Settings rows, the Overview's region), 18 tests, 6 mutations, seen in a browser on the demo; it mirrors nothing until the mirror track's door (M9) is merged (message 82). Its independent review runs since 23:55 (`BRIEF-G4-review.md` -> `REVIEW-G4-mirror-page.md`). Running: three reviews (the sign-in page's second pass, G6, G4) and the G2c coder.** Earlier: **11-15 23:53 (P3). The program's own folder, stage A (G6), is HANDED BACK: `wip/pages-g6` 51d7656a on 27a7d4d (pushed, clean; 20 new files: the launcher `cmd/tgarchive-open` built as `tgarchive.exe`, `internal/launcher`, `deploy/folder/make-folder.sh` with its README): the settings file, a first-start setup page, the start under the watchdog with the same flags as `a3-start.ps1 -Pages`, a status page, "Stop what is left" for a collector whose watchdog is gone; 16 tests on stand-in programs, 5 mutations; its coder ran it as the owner will on a scratch folder with stand-ins (three faults found there and fixed). No real collector, watchdog, viewer or VPN was started. Its independent review runs since 23:53 (`BRIEF-G6-review.md` -> `REVIEW-G6-launcher.md`). Also running: the sign-in page's second pass, the coders of G4 and G2c.** Earlier: **11-15 23:49 (P3). The sign-in page's fix round is HANDED BACK: `wip/pages-g3-main` 71000827 on 27a7d4d (pushed, clean; every one of the review's 18 findings fixed with named tests on the fake, seven mutations, clicked through in a browser by its coder, who also found and fixed a cut answer at the pages' stop); its second independent pass runs since 23:49 (the same reviewer; it writes `REVIEW-G3-signin-2.md`). Then the main head merged in, once the whole Windows runs and the race detector on the whole collector and the server, its entry. Also running: the coders of G6, G4 and G2c.** Earlier: **11-15 23:31 (P3). The Queue page's second independent pass is back (`REVIEW-G2-queue-2.md`: 0 must fix, 3 should, 6 minor; 12 of the first review's 14 findings closed, 2 partly): its follow-up is with a coder since 23:31 (`BRIEF-G2c-followup.md`, `wip/pages-g2c`, copy `wt-pages-g2c`, from the main head): the click's pick moved out of the write (a small group beside 200,000 set-aside files of another reason held the writer 246 to 314 ms), the file-by-file list read with the counts, no reread of the costly part in a storm. Message 77 of the mirror read 23:31: its door's names are passed to G4's coder. Four agents of mine run: the coders of G3b, G6, G4 and G2c.** Earlier: **11-15 23:22 (P3): G4, the mirror from the Chats page (the owner's word of 23:20, message 74), is BRIEFED: `BRIEF-G4-mirror-page.md`; what each click sends is `DESIGN-G4-mirror-from-page.md` (the owner's list, item 30); the calls the page makes are message 75, for the mirror track to build the collector's side to. **Its coder runs since 23:23** (`wip/pages-g4`, copy `wt-pages-g4`, from the main head; the pages' side against a fake of the seam; the adapter is handed over only when the collector implements the calls of message 75). Four agents of mine run: G3b's coder, G6's coder, G4's coder, the Queue's second pass.** Earlier: **11-15 23:02 (P3), after the usage reset (message 65). G1, "G1s" and G2 are merged and installed (27a7d4d). With a coder since 23:00: the sign-in page's fix round (G3b, `wip/pages-g3-main` in `wt-pages-g3m`, on the main head). **Started 23:07 (7.0 GB free then): the coder of the program's own folder (G6, `BRIEF-G6-one-folder.md`, the owner's yes; branch `wip/pages-g6`, copy `wt-pages-g6`, from the main head) and the Queue page's owed second independent pass (read-only; it writes `REVIEW-G2-queue-2.md`; its findings become a follow-up branch).** Waiting for one of the three to hand back: the Staging page's coder (G5). Message 69 has the rest.** Earlier: **11-15 21:57 (P3). LISTED and READY: entry "G1s", `wip/pages-scroll` 7d47bdbc: the owner's jump on a top-bar click (one commit on c8e49ee9; fixed build 0 px after each of the seven links, the merged build 121 px on Chats and Overview).** G1 is merged (c8e49ee9) and the owner has opened it. Usage is low (message 62): no new piece is started; the Queue's fix coder and the sign-in page's reviewer go on; the Staging page's coder was stopped by me at 21:58 with nothing written (briefed, `wip/pages-g5` at ee437a46, for the next session); the take-over block is the end of `SESSION-PAGES-PROGRESS.md`. Earlier: **11-15 21:21 (P3): TAKEN OVER 21:10** (read in full: the board, P2's take-over block, entry G1, TRIED-BEFORE 5, 9, 10, 15, 19, the viewer's lessons; messages 26 to 55 read). **G1 is READY (since 21:38; on HOLD 21:25 to 21:38): `MERGE-QUEUE.md` entry G1, `wip/pages-g1` ee437a46 (pushed; test files only since 541743d). One test, `TestE2EPages`, fails about every second run under the race detector only: the fake Telegram's topics answer cannot be encoded (message 58: one line, Core's); with it set by overlay the test passed 10 of 10.** P2's coder had fixed `TestPauseEndsByItself` at 21:07 (it holds its files' parts until the pause holds); read by me, sound; by name: 3 of 3 on Windows, **5 of 5 under the race detector at 1 CPU (289 s, no data race)**; the integrator's server rerun under the detector ended ok (2,382 s). The 12 other changed tests passed by name under the detector; the server's skip check passed. Tests at size skip under the detector by a build tag (two tests, named in the entry); no race run uses `-short`. **The Queue page (G2): LISTED and READY since 22:28: `MERGE-QUEUE.md` entry "G2", `wip/pages-g2-main` 2fc8f622 (two commits on 2580f291)**: the review's 14 findings fixed, the retry capped at 5,000 files a click in one statement, whole `internal/server` 99 s, the race detector on `internal/server` ok (864 s, no data race), the rig tests, a browser pass on this tree; no second review pass on the fix round (usage): the entry says so. **The sign-in page (G3), `wip/pages-g3` c49b27ac: built, read by me, independently reviewed (22:04, `REVIEW-G3-signin.md`: 3 must fix, 6 should, 9 minor): NOT mergeable yet; its fix round is not started (usage): the next session's.** The must-fixes: a code request crossing a Quit leaves the program waiting 15 minutes for a code nobody can type; a refusal the app has no rule for is shown as a connection problem and a second click asks a second code; no way on the page to ask for a new code while a sign-in stays open. One account may wait for its sign-in at a time (more needs a schema step). Messages 46 and 60 of the mirror (its name rule and gathering on the Settings page) go with G4. **The Staging page (G5): briefed, not started** (`BRIEF-G5-staging-page.md` with its last section; branch `wip/pages-g5` and copy `wt-pages-g5` exist at ee437a46, empty). **Next, in this order:** a mirror step from the page (G4), with the mirror's name rule and gathering on the Settings page; the program's own folder (G6, item 24); the starter through the watchdog; the local door's place for the client feature. Nothing of this track has run against Telegram. Progress: the section "SESSION P3" at the end of `SESSION-PAGES-PROGRESS.md`. Earlier state (P2): **11-15 20:04 (P2, wrapping up at the owner's word: its context is nearly full; a new session takes over from the last block of `SESSION-PAGES-PROGRESS.md`).** **G1 is listed: `MERGE-QUEUE.md` entry G1, `wip/pages-g1` (541743d when run in full; ee437a46 since 11-15 21:07: tests only)**, with the owner's pause of downloads in it and the main head fa8c011 (the automatic mirror, K1) merged in; no schema step. Reviewed twice independently, every finding fixed; seen four times in a browser on invented data. Full runs once on 541743d (`runs-pages-g1/`): the whole Windows tests passed (the collector whole 681 s), gofmt and vet clean; **The race runs ended 11-15 20:50: `livepages` ok; the collector whole and the server FAILED, both on tests (entry G1 says which): G1 is NOT READY.** Owed: `TestPauseEndsByItself` made to build its case without timing; the server's tests at 300,000 files skipped under the race detector; then the server under the detector again and the pause's tests by name under it. **Handed back by its coder (11-15 20:08), not read by the main session, not reviewed, no full runs:** the Queue page, `wip/pages-g2` da993b39 (from 541743d, copy `wt-pages-g2`; `BRIEF-G2-queue-now.md`; its report on the branch); it merges after G1. **Briefed, not started:** sign-in from the Accounts page (`BRIEF-G3-signin-page.md`), the Staging page (`BRIEF-G5-staging-page.md`). **Designed, not built:** the program's own folder (`DESIGN-G6-one-folder.md`; board item 24 for the owner). **Not briefed:** a mirror step from the page (G4). Nothing of this track has run against Telegram. The starter `app\tgarchive.cmd` is a draft, untried. |

### P5's entries
- 11-16 12:42: **taken over (P5), started by the integrator at the owner's word; P4 is retired.** Read, myself
  and no more: `CLAUDE.md`'s archiver section; the board (direction, the owner's three rows of 07:40, my row,
  the integrator's row of 12:28, messages 113 to 124 that name pages, the owner's items 31 to 35); P4's
  block of 10:45 and the "how the work goes" of the blocks before it; `MERGE-QUEUE.md` entry "M10";
  `TRIED-BEFORE.md` sections 24 and 25; the doors on `wip/mirror-autonew` 7d31fa56 (`mirror_door.go`:
  `MirrorTask`, `SetMirrorAutoNew`, `MirrorListEvery`, `SetMirrorListEvery`); the pages' side
  (`server/mirrors.go` the seam, the kept task and the settings routes; `livepages/mirrors.go`;
  `pages_mirrors.go`; `mirrorsettings.js` whole).
- **Found on disk, 12:45 (three commands of mine; each a look that needed a judgement):** the main head is
  bae71e5c (C13), pushed; M10's merge is staged in the main checkout and not committed (the integrator's
  merge run). G11 and the viewer's window are on the head (140fefaa, b6dd5e66). Nothing of this track runs.
- **What the reading changed against the brief I was given:** the switch's fact is shown on the SETTINGS
  page today (`web/assets/js/pages/mirrorsettings.js`, the region "Mirrors: chats you join"), not on the
  Chats page; `chatmirror.js` and `mirrorwords.js` do not name it. So G12 puts the control where the fact
  is (Settings, one block per account, with the interval above it in the same region) and gives the Chats
  page one state line with a link. The door answers nil both for an "on" it wrote and for one that was on
  already: the page cannot know whether a chat list was asked, so its sentence after the click is
  conditional ("if the switch was not on already ..."). The page keeps each account's task with its
  states (`keptTask`): the click's answer must carry the task read anew and make the kept one stale.
- 12:50: **G12 is briefed: `BRIEF-G12-auto-switch-page.md`** (parts A the switch, B the interval, C the
  folder script's running check as a commit of its own; its "what the old app already knows" note; the
  named tests; the hand-back). **The row is cut** (31 KB to about 4 KB; the old one is above in this
  section). **A background watch of this session waits for the main head that holds M10** (it ends when
  `HEAD` of `repo-archiver` is no longer bae71e5c, holds `internal/mirror/autonew.go` and the tree is
  clean; at most two hours). **NOT STARTED: the coder** (one Opus coder, copy `wt-pages-autonew`, branch
  `wip/pages-autonew`, cut from that head, after measuring the PC). Nothing is committed in the code
  repository by this session; nothing is pushed there.
- **Next step in one line:** when the watch ends: measure the PC, cut `wt-pages-autonew` from the new head
  (one Sonnet clerk call or one command), start the coder on the brief, write it here and on the row.
- **For a take-over at this point:** the brief is complete; start the coder as the line above says. The
  listing script for G12 is not written yet: make it from `runs-pages-g13/run-listing.sh` (whole
  `internal/server` and `livepages`; the collector's tests by name: the mirror's `TestMirrorAutoNew` and
  `TestMirrorDoor` sets and the pages' wrapper tests; build, gofmt, vet; no race detector unless G12 came
  to change code that runs concurrently).
- 11-16 12:59: **G12'S CODER RUNS: one Opus coder (high effort), copy `wt-pages-autonew`, branch
  `wip/pages-autonew`, cut from the main head 2b557601** (M10 merged; the watch ended at 12:58 with that
  head pushed and the tree clean; the integrator's row still said bae71e5 then: I cut from what is on the
  main branch and pushed). Measured first (one command: a single measurement): 2.2 GB free, CPU 58%: the
  coder is told one go command at a time (`-p 1`), named tests only, nothing over two minutes. The cut
  of the copy: one command of mine (a single command). It commits and pushes to `private` as it goes;
  its hand-back is at most 15 lines; its report will be `archiver/docs/progress/pages-autonew-REPORT.md`.
  **Two corrections to my entries above:** the row and the entry stamped 12:50 were written at 12:47 (the
  notes commit 127c0f1 is of 12:47); the watch looked every 20 seconds for up to two hours of sleeps and
  called the tree clean without counting untracked files or `ROADMAP.md`.
- **Running now:** only that coder. Nothing of this session is committed in the code repository yet; the
  branch `wip/pages-autonew` exists locally at 2b557601 and is not pushed until the coder's first commit.
- **Next step in one line:** at the hand-back: look for a process left behind, read the board, read the
  risky part myself (the route's refusals without a door call, the kept task made stale, the unreadable
  switch never shown as off, the words against the door's comments), then ONE independent Opus review with
  probes by overlay, its fixes, and the listing runs once by a script made from
  `runs-pages-g13/run-listing.sh`.
- 11-16 13:14: **G12's coder handed back: `wip/pages-autonew` 8184fdfc, pushed (5 commits on 2b557601; 15
  files, +1,209 -51; the folder script is its own commit 6a1808d0; report
  `archiver/docs/progress/pages-autonew-REPORT.md`).** Its named tests passed (server 40, livepages 9, the
  collector's 5 by name, the launcher's two folder tests); test functions added 13, removed 0; no whole
  package, no race run, no vet (those are the listing's). No process of its own left (looked: the one go
  test running then was another session's whole `internal/mirror`). The board read before going on: the
  integrator's row names 2b55760 as the head to cut from; usage 96% at 13:03, the stop at 97% "close" and
  not yet said.
- **Where the code made the coder change the brief's words (to check in the review):** an "on" writes two
  rows (the switch and "since"), not one; the automatic mirror reads a chat's history first and forwards
  its messages with a file by default; the door cannot tell a run with `-auto-mirror-steady`, so "up to";
  the kept reading goes stale by the guard's `markDirty` (nothing added); the sign-in record unreadable,
  the forward secret's own error and catalogue failures reach the page as failures (502) on purpose.
- **My read (the routes, the adapter, the wrapper, the three scripts, the folder script's line), 13:15 to
  13:16; what I gave the reviewer as suspicious:** (1) an account the doors refuse (not signed in) gets no
  button at all, yet the door takes an "off" for any account: the owner could not switch off a signed-out
  account whose stored switch is on (my own brief said "no button"; rule 1 says an off must be possible);
  (2) not settable and not on is shown as "on for this run"; (3) on the Chats page `autoLine` is a `const`
  declared after the function that uses it; (4) the settings answer now fails whole when the interval's
  door fails; (5) the cost sentence's clauses against the door's code. Not opened in a window by anyone.
- 13:16: **ONE independent Opus review runs** (read-only on `wt-pages-autonew`, probes by overlay in
  `wt-pages-review-g12-scratch`, one go command at a time, named tests only; the PC had 2.0 GB free at 73%
  CPU, the reviewer waits under 1.5 GB or above 85%). It writes `REVIEW-G12-auto-switch.md` in this folder.
  **By a Sonnet clerk, since 13:16:** the listing script `runs-pages-g12/run-listing.sh` written from
  G13's (build, gofmt, vet, whole `internal/server` and `livepages`, the collector's mirror and pages tests
  by name, the launcher's folder tests by name; no race detector: no code that runs concurrently changed,
  the handler takes no new lock and starts nothing); not run.
- **Running now:** the reviewer and the clerk. **Next step in one line:** the review's fixes by the same
  coder brief style (one fix round, with my points 1 and 2 whatever the review says of them), then
  `SEQ=1 bash runs-pages-g12/run-listing.sh wt-pages-autonew wip/pages-autonew g12` once, then the entry
  "G12" in `MERGE-QUEUE.md`.
- 11-16 13:25: **the review is back: "may be listed after these fixes" (2 must fix, 3 should fix, 8 minor;
  `REVIEW-G12-auto-switch.md`, 221 lines, read by me whole).** The route, its body checks, the guard, the
  staleness of the kept reading and the adapter held under every probe; all 6 planted changes and a 7th
  were caught by named tests; test functions removed 0. **Both must-fixes are in how the Settings page
  handles the owner's "off":** (1) confirmed by probe: an account the doors refuse (not signed in) with
  the switch on got no "Switch off" (MY brief's case 1 asked for "no button": the brief was wrong, the
  door takes an "off" for any account); (2) plausible: after a click the keyboard landed on the opposite
  button, so a repeated Enter could write "on" unasked (my brief's "focus returns to the block's button"
  repeated a hazard the mirror page had already learnt). Should fix: the cost sentence promised every
  joined chat (the task takes groups and channels only, not protected ones, with caps); the list asked
  at a switch-on also asks the approved forums' topic lists; the Chats page's line was not kept for a
  refused account. The clerk's listing script is written (`runs-pages-g12/run-listing.sh`, 90 lines,
  syntax-checked, nine steps one after the other, not run).
- 13:26: **the ONE fix round runs: `BRIEF-G12b-fixes.md`, the same coder resumed** (points 1 to 7: the
  "off" for a refused account; the keyboard to the answer line; strict comparisons; the words true of the
  code; the fake as the door with the test of the refused "off"; `tgarchive-backup*` in the folder
  script's check; the switch blocks painted when only the settings' read fails, with no "on" then). Left
  on purpose: Go's last-key rule for duplicated JSON keys (every route's); no DOM test harness exists for
  the two page scripts (NOT verified: `setAuto`, `autoBlock`, the Chats page's line and patch; nobody has
  opened the page in a window). **Message 128 on the board** (to the mirror: the door's comment on a
  switch-on's cost, a fact for a failed set-up; M5's 124 answered; to the integrator: where G12 stands).
- **Running now:** only the coder's fix round (copy `wt-pages-autonew`, branch `wip/pages-autonew`, from
  8184fdfc, pushed as it goes). **Next step in one line:** at its hand-back: look for a process left
  behind, read the board, read the fixes of points 1, 2 and 7 myself (no second review pass unless the
  round rebuilt more than the brief names), then
  `bash runs-pages-g12/run-listing.sh wt-pages-autonew wip/pages-autonew g12` once in the background
  (measure the PC first; about 25 minutes), then the entry "G12" in `MERGE-QUEUE.md` and "listed, READY"
  on the row.
- 11-16 13:28: **THE OWNER, to this session: "Why are the caps so low? Can we adjust them higher, and make
  them configurable?"** (the automatic mirror's 10 chats a look and 5 new mirrors in 24 hours, as G12's cost
  sentence states them). Read by me before answering (four commands: each a look that needed a judgement):
  `internal/mirror/auto.go` (the constants and the options), `door.go` 373 to 376, the help in
  `command.go`, FEATURES 12's documented limits, the roadmap's row. Answered: 5 is the app's own caution,
  nothing measured; it is 1 to 50 already but only by the start flag `-auto-mirror-new-per-day`, which the
  folder's app never sets; the same number bounds the owner's own wants from the Chats page; 10 a look does
  not bind. **Routed: message 129 on the board, 13:29** (the mirror's packages: a catalogue setting with
  doors, as the chat list's interval; pages builds the Settings row and takes the cost sentence's number
  from the door when it is listed). **Asked of the owner: the default (I recommended 20 a day, 1 to 50).**
  Nothing of it is built or briefed by this session; G12's fix round is unchanged by it (its sentence says
  "by default" and stays true until the setting exists).
- 11-16 13:31: **the fix round is back: `wip/pages-autonew` edad0fe0, pushed** (3 commits on 8184fdfc: the
  fixes 38f19ca7, the folder script's backup f086078b, the report's section; 8 files, +257 -66). All seven
  points done; one test added (`TestMirrorAutoNewRefusedAccountCanSwitchOff`), none removed or renamed
  (looked: 0 lines "-func Test"); its named tests passed (server 41 in 3.3 s, the launcher's two folder
  tests). No process of its own left (looked: 0 from the copy; the one test binary was another session's
  collector run). The board read: no stop said; the integrator's combined run of K14 and K16 goes on; the
  main head is still 2b55760.
- **My read of the round, whole (the two scripts, the Chats page's line, the words, the folder script), 13:31
  to 13:32:** an "off" is offered for a refused account with the switch on or unreadable and never an "on";
  every fact is an exact boolean and a contradiction offers nothing; with the settings unread no "on" of
  any kind is offered and the blocks still paint; the keyboard goes to the answer line on every path; the
  words carry the review's clauses. **No second review pass: my judgement** (the round changed about 100
  lines of page script, all read by me against the review's accepted fixes; no door, no route's logic and
  nothing that runs concurrently changed). What stays unverified by any test: the two page scripts' DOM
  code (no harness), and nobody has opened the page.
- 13:32: **THE LISTING RUNS ARE STARTED, ONCE, BY A SCRIPT in the background**
  (`runs-pages-g12/run-listing.sh wt-pages-autonew wip/pages-autonew g12`; the PC had 2.2 GB free at 47%
  CPU; one step after the other): the clean merge of the main head if it moved, build and vet for Windows
  and Linux, gofmt, whole `internal/server`, whole `livepages`, the collector's
  `TestPagesMirrors|TestMirrorPages|TestMirrorAutoNew|TestMirrorDoor` by name, the launcher's
  `TestMakeFolder` by name; the push only if every line is exit 0. No race detector (no code that runs
  concurrently changed). Its lines: `runs-pages-g12/g12-<head>.summary`; its output `g12-run.out`.
- **Running now:** only that script. **Next step in one line:** read its summary; every line exit 0: write
  the entry "G12" at the end of `MERGE-QUEUE.md`, "listed, READY" on the row and in the commit's subject;
  a failing line: read its log, one more coder message.
- 11-16 13:34: **THE OWNER ANSWERED the default: "Let's go with your recommendation for now".** Decided for
  now: 20 new mirrors in 24 hours by default, a stored setting from 1 to 50, the upper bound raised only
  after the first real run has shown what a create costs. Written at the end of message 129 for the mirror
  (its packages; not started by anyone under the hold). Pages' side when its door is listed: the row on
  Settings beside the chat list's interval, and the number in the switch's cost sentence taken from the
  door. G12 as listed says "5 ... by default", which is true of the code it holds.
- 11-16 14:49: **the integrator (a new session, holding the board's row since 14:03) wrote to this session:**
  my listing script had made two of nine steps in 75 minutes, waiting 20 minutes for 2.5 GB free before
  every step; the main head had moved (K16, K14, C14); it proposed that I stop the script and list G12, the
  full runs to be made by it once on the combined tree; and that no hold stands (the owner to copies,
  14:38: "Build as needed"). Checked by me on disk before acting: the summary (both builds exit 0, 37 s and
  35 s, each after a full wait), the script's `waitmem` (copied by the clerk from G13's script as I had
  told it to keep everything else; **I had not read G13's script past its first 30 lines and did not know
  of the wait: my miss; from 13:34 to 14:49 this session sat on a run that could not finish**), the
  integrator's row, the main head b435266a. **Done: the script stopped (its one leftover shell ended by
  me; nothing of the copy runs; the copy is clean at edad0fe0, pushed).**
- 11-16 14:51: **G12 IS LISTED, READY: entry "G12" at the end of `MERGE-QUEUE.md`** (`wip/pages-autonew`
  edad0fe0, holding 2b557601; a trial merge with b435266a clean by `git merge-tree`; 15 files, +1,407 -58;
  test functions added 14, removed 0; what was run and what was not, said plainly; the full runs are the
  integrator's at the merge). The row rewritten. Routine steps of this entry: one script of mine for the
  facts and one for the files (single calls); the stop of the run was a judgement.
- **Running now: nothing.** Not committed or pushed in the code repository by this session beyond the
  coder's branch `wip/pages-autonew`.
- **Next step in one line:** read K14's three wirings in `livepages/clicks.go` on the head; then brief
  "G14" (P4's point 3 b: the link back to the launcher's page, the pages adapting by the user-agent word,
  the once-only redirect only for the window) for one Opus coder, cut from the head that holds G12 (or from
  the main head if G12 is not merged by then: it touches `internal/launcher` and other page files);
  for its listing, a script WITHOUT a memory wait, read by me whole before it is started.

### STATE FOR A TAKE-OVER (P5, 11-16 14:51)
Read `BOARD.md` (the Pages row, the integrator's row, messages 128 and 129), then this block.
1. **Listed, READY, waiting for the integrator: G12** (`wip/pages-autonew` edad0fe0; entry "G12"). If it is
   handed back for a conflict: one coder message; for runs: `runs-pages-g12/run-listing.sh` after taking
   its `waitmem` calls out.
2. **Nothing of this track is running.**
3. **Next, in this order:** (a) "G14": P4's point 3 b (three minors of G11's closing look); (b) when the
   mirror lists the cap on new mirrors as a setting (message 129; the owner's default 20, 1 to 50): its row
   on Settings beside the chat list's interval, and the cost sentence's number from that door; (c) P4's
   3 c to 3 f as their conditions come true (the block of P4, 10:45, above).
4. **For the owner, open:** items 31, 32, 33, 35 as P4 left them (nobody has said what the owner saw in the
   folder); after G12's merge and the folder's rebuild: the first switch-on from the Settings page is the
   owner's, with the mirror's plan of item 26.
5. **How the work goes:** as P4's blocks, and: read a script whole before starting it, also one a clerk
   made from another; a run that should take 25 minutes is looked at after 30; times from `date` at the
   moment of writing, never ahead.
- 11-16 14:51: **P5 is ready for a take-over** (said on the row): G12 is listed, nothing runs, and this
  session's context is large, so "G14" is cheaper from a fresh session started with "Read `BOARD.md`, take
  over the pages track from its progress file, and carry on". Until then P5 answers what is addressed to
  pages (a hand-back of G12, the owner's words on item 35).

## SESSION P6 (took the track over 11-16 17:56, started by the integrator at the owner's word; P5 is retired)

### The board's Pages row as P5 left it (moved here by P6 at 18:00 when the row was cut; one line)
| Pages and chats: the app's own pages (Chats, Queue, Staging, Settings), the launcher and the folder, and what they set in the catalogue | **session P5** (pages; taken over 11-16 12:42, started by the integrator at the owner's word; P4 and the sessions before it are retired: do not wait for them or message them); progress in `SESSION-PAGES-PROGRESS.md` under "SESSION P5" | `internal/server`, `internal/launcher`, `cmd/tgarchive-open`, `internal/actdoor`, `internal/collector/livepages`, `deploy/folder` (the folder's build script) | **11-16 14:51 (session P5): "G12" IS LISTED, READY: `wip/pages-autonew` edad0fe0, holding 2b55760, a trial merge with b435266 clean (`MERGE-QUEUE.md` entry "G12" at the end of the file).** The switch "mirror chats I join by themselves" as a control on the Settings page (one account a click, an explicit on or off; what an "on" leads to said beside it before the click; a stored switch that cannot be read shown as that with "write it anew"; an "off" possible also for an account that is not signed in, an "on" never), its state on the Chats page, the chat list's interval as a setting, and the folder script's running check counting the window, the viewer and the backup. One independent review with probes ("may be listed after these fixes": 2 must fix, both from my brief, 3 should fix, 8 minor), one fix round, read by me whole. **THE FULL RUNS ARE THE INTEGRATOR'S AT THE MERGE (its message of 14:49): on this branch only both builds and the named tests were run; my listing script carried G13's 20-minute wait for 2.5 GB before every step, which I had not read, and was stopped at 14:49 after two steps.** NOTHING OF THIS TRACK RUNS. On the main head: everything of the track up to G11 and G13. **The owner to this session: 13:28 "Why are the caps so low? Can we adjust them higher, and make them configurable?" and 13:34 "Let's go with your recommendation for now": the automatic mirror's cap on new mirrors in 24 hours becomes a stored setting, default 20, 1 to 50 (message 129: the mirror's piece; pages adds the Settings row and takes the cost sentence's number from its door when it is listed).** Messages 128 (to the mirror: two things from G12's review in its files; M5's 124 answered: no hold of `AutoNewSettable` needed) and 129. **The owner's item 35 (the folder with the three points of 07:40): nobody has said what the owner saw; when it is said, it comes first.** **THIS SESSION (P5) IS READY FOR A TAKE-OVER since 14:51: G12 is its landed piece and its context is large, so the next piece is cheaper in a fresh session (the owner's rule of 11-13); the block "STATE FOR A TAKE-OVER (P5, 11-16 14:51)" at the end of `SESSION-PAGES-PROGRESS.md` is what it starts from; until one is started, P5 answers what is addressed to pages.** NEXT for it, the hold being lifted (the integrator, 14:49, the owner's "Build as needed" of 14:38): P4's point 3 b as one small piece "G14" (a link from the app's pages back to the launcher's page; the pages adapting by the user-agent word ` tgarchive-window`; the once-only redirect given only to the window), cut from the head that holds G12; then 3 c to 3 f as their conditions come true, and the Settings row for the mirror's cap when its door is listed. K14's three wirings in `livepages/clicks.go` are on the head: to be read by me. Routine steps: by a script or one Sonnet clerk call, said in each entry. The row as P4 left it is at the end of `SESSION-PAGES-PROGRESS.md` under "SESSION P5".** |


### P6's entries
- 11-16 17:56: **taken over (P6), started by the integrator at the owner's word (17:53: "Start both");
  P5 is retired and archived.** Read, myself: `CLAUDE.md`'s archiver section; `BOARD.md` whole (the
  rows, "Listed and unbuilt", the merge list, messages 113 to 149, the owner's list); P5's entries and its
  block of 14:51, P4's block of 10:45; the handoff's block 0c. Found on disk at 17:57 (looks that needed a
  judgement, three commands): the main head is 78739d59 with M6 staged on the main tree (the integrator's
  merge run: I do not touch that tree); nothing of this track runs; the PC had 6.0 GB of memory free at
  76% CPU; the system disk had 122 GiB free again (49.4 at 17:45: the tests' fault comes and goes).
- **The tests' fault, confirmed by me in the code before briefing:** `newStagingEnv`
  (`internal/server/staging_test.go` 104) hands the page `KeepFree: 50 << 30` and a temporary folder;
  `freeWithin` (`stagingread.go` 317) calls the real `freeBytes` of that folder; `noRoom`
  (`stagingverdict.go` 178) compares the two. `staging_look_test.go` forces "no room" with a floor of
  1 << 50 against the real disk: the same dependence the other way. `livepages` hands `KeepFree` through
  and asks no disk; the launcher asks one for words on its pages (`freeWords`): the coder says whether a
  test depends on it; the collector's rig uses a floor of 1 MiB (Core's; read only).
- 17:59: **"G15" IS BRIEFED AND WITH A CODER: `BRIEF-G15-staging-tests-free-space.md`; copy
  `wt-pages-free`, branch `wip/pages-free`, cut from 78739d59 (one command of mine: a single command);
  one Opus coder at high effort**, named tests only, one go command at a time, nothing over two minutes.
  It may change `internal/server/stagingread.go` (the seam only) and the package's test files. Nothing
  is committed on the branch yet.
- **The viewer's lent commit f7a148b5 read by me (17:59), as the integrator asked:** `door.go` gains the
  field `catalogue` (a base name, checked: no separator, colon or control character, at most 1,024
  bytes), the reader's strict form takes a file without it as "not whole", `Write` takes the name as a
  variadic parameter. Sound and fail-closed; TAKEN AS IT IS. One thing I change when a piece of mine next
  touches `actdoor`: the variadic becomes a plain third parameter (today a call without the name writes a
  file no reader takes: a path only tests use); it needs one line in a collector test, asked then.
- 18:00: **the row is cut and says "session P6 has the track"** (P5's row is above, under this
  session's heading). Routine steps of this entry: the notes written by one script
  (`runs-pages-p6/notes.py`, written by me, read whole).
- **Running now:** the G15 coder (an agent of this session; copy `wt-pages-free`).
- **Next step in one line:** brief "G16" (the Settings row for the cap on new mirrors) while the coder
  works; at its hand-back: look for a process left behind, read the seam and the rig, ONE narrow
  independent review, then whole `internal/server` once by a script without a memory wait per step
  (read whole first), then entry "G15" at the end of `MERGE-QUEUE.md`.
- 11-16 18:04: **G15's coder handed back: `wip/pages-free` 106b890f, pushed, the copy clean** (8 files,
  +189 -3: `stagingread.go` +9 -1, the seam `stagingKeep.free` read by `freeWithin` on the caller's
  goroutine, the real `freeBytes` when nil; the rig and four other tests that build a `Server` with the
  store's seam on a fixed invented 2^40; a new `staging_free_test.go` with three tests; its report
  `archiver/docs/progress/pages-free-REPORT.md`). Test functions added 3, removed 0 (looked: 0 lines
  "-func Test"). Its named tests passed (the five that failed and seven more); with the seam line taken
  out three tests fail on the real disk's number, as they should. What it found elsewhere: no test of
  `livepages`, the launcher, the opener or `actdoor` depends on an amount of free space; in Core's
  collector two pages tests read the real disk through the page on the rig's floor of 1 MiB (they could
  only fail with under 1 MiB free; nothing changed there).
- **My read of the whole difference (18:04 to 18:06) and what it led to:** the seam and the rig are as
  briefed. **One thing the coder named and left, which I do not leave:** inside `freeWithin`'s goroutine
  the answer was sent before the deferred "no call under way" was written, so a reading made at once
  after another could still meet the busy flag and say "free space not known"; the new tests make
  readings back to back, so they could fail by scheduling alone (the fault is older than this piece: the
  five tests could always have met it). **A second small round, with a fresh Opus coder since 18:06**
  (exact instruction in its start message; cheaper than waking the first coder's context): the flag is
  cleared, then the answer sent (the channel has room for one, so the send never blocks; on the bound's
  path the flag stays set until the slow call returns, as before); a test `TestStagingFreeBackToBack`
  (5,000 readings in a row never "not known"; a blocked call: the guard still answers at once, and frees
  itself after the release).
- 18:04: **18 finished copies of this track removed by a script of mine (`runs-pages-p6/remove-copies.sh`,
  a dry run first; each was clean and its head the head of its branch on `private` as fetched then):**
  `wt-pages-autonew`, `-door`, `-g1`, `-g2`, `-g2c`, `-g2m`, `-g3`, `-g3m`, `-g4`, `-g5`, `-g5m`, `-g6`,
  `-l2`, `-scroll`, `-setup`, `-small`, `-staging2`, `-window`; the local branches stay. Left:
  `wt-pages-g1-look` (on no branch: not on `private` by design, the integrator's review of 14:02) and
  the 12 reviewers' scratch folders (`wt-pages-g1-probe-scratch`, `wt-pages-review-*-scratch`: plain
  folders of probes, no git copies; their reviews are the `REVIEW-G*.md` files of this folder; they go
  when the integrator says those are in `docs/review`).
- 18:03: **"G16" IS BRIEFED: `BRIEF-G16-mirror-cap-row.md`** (the Settings row for the cap on new mirrors
  on M12's doors; every bound from the door at the moment of the answer, no constant of the mirror
  package's cap named in the pages' packages; the refusal's words built from the door's bounds; the
  cost sentence's number from the door; `AutoSetUpFailed` shown; the settings answer not failing whole
  when the cap's door fails; the demo's and the test's invented 5; its "what the old app already knows"
  note from TRIED-BEFORE 24 and 25, read by me: the old app's own "at most 10 per half hour", rules 10,
  11 and 13). Read by me for it: `mirror_door.go` 44 to 62 and 741 to 816, `internal/mirror`'s cap file's
  names, `server/mirrors.go`'s interval path and words, `livepages/mirrors.go`'s refusal table,
  `mirrorwords.js` and `mirrorsettings.js`'s interval row. NOT STARTED: its coder (copy `wt-pages-cap`,
  branch `wip/pages-cap`, cut from the head the integrator's row names then) starts when G15 is listed.
- **Written for G15's next steps, not started:** `BRIEF-G15-review.md` (a narrow independent review with
  probes by overlay: can any test of the package still change with this PC; is the product unchanged but
  for the flag's order; is that order right on every path; do the new tests test what they say) and
  `runs-pages-p6/run-g15.sh` (written by me, so read whole: one step after the other, NO wait for
  memory; it merges, commits and pushes nothing).
- **THE FULL RUNS OF G15, said before they start (after the review's fixes, once):** whole
  `internal/server` on Windows (about 3 minutes), gofmt, `go vet` of that package for Windows and Linux;
  **the race detector on the server's `TestStaging` tests by name in a Linux container (about 10 to 15
  minutes): one package, by name, because the one function that starts a goroutine (`freeWithin`)
  changes the order of its flag and its send.** Nothing else: no other package changed.
- **Running now:** the second-round coder (copy `wt-pages-free`). **Next step in one line:** at its
  hand-back read its two files, start the reviewer on `BRIEF-G15-review.md`, then its fixes, then
  `bash runs-pages-p6/run-g15.sh` once in the background, then entry "G15" at the end of `MERGE-QUEUE.md`.
- 11-16 18:06: **the second round is back: `wip/pages-free` 508b4de9, pushed, the copy clean**
  (`stagingread.go` +8 -3: the flag cleared, then the answer sent, no defer; `staging_free_test.go` +44:
  `TestStagingFreeBackToBack`). **With the old order put back the new test failed 20 of 20 runs, the
  earliest at its third reading: the hazard was real**, not a rare one. Its ten named tests passed.
  Read by me whole (18:07): the seam is read before the goroutine starts, so no test's write of the
  field meets a reader; the guard's part of the test bounds its own waits (one assertion on time: a
  guarded answer within 500 ms).
- 18:07: **THE NARROW INDEPENDENT REVIEW RUNS** (one Opus reviewer, high effort, read-only on
  `wt-pages-free` at 508b4de9, probes by overlay in `wt-pages-review-g15-scratch`, one go command at a
  time, named tests only; `BRIEF-G15-review.md`; it writes `REVIEW-G15-staging-free.md` in this folder).
- **Running now:** only the reviewer. **Next step in one line:** its findings judged; fixes if any by a
  fresh coder with an exact instruction; then `bash runs-pages-p6/run-g15.sh` once in the background
  (measure the PC first), then entry "G15" at the end of `MERGE-QUEUE.md` and "LISTED, READY" on the row.
- 11-16 18:07: **"G16" IS WITH A CODER since 18:08: one Opus coder (high effort), copy `wt-pages-cap`,
  branch `wip/pages-cap`, cut from 78739d59** (the head the integrator's row names; one command of
  mine: a single command), on `BRIEF-G16-mirror-cap-row.md`. Measured first (a single command): 4.5 GB
  free at 67% CPU. It runs beside G15's reviewer, so **the track has a one-go-command lock from now:
  `runs-pages-p6/go1.sh`** (written by me, read whole: the lock is a folder, waited for at most 30
  minutes; under 1,500 MB free it waits at most 5 minutes IN ALL and then runs anyway and says so: no
  wait that can hold a piece for hours); the G16 coder's every go command goes through it;
  `run-g15.sh` takes the same lock for its whole run. G15's reviewer was started before the lock
  existed and does not use it: for its last minutes two go commands of the track can meet.
- **Running now:** G15's reviewer (read-only on `wt-pages-free`) and G16's coder (`wt-pages-cap`).
  Nothing of G16 is committed yet.
- **Next step in one line:** G15 first: the review's findings judged, fixes, `run-g15.sh` once, entry
  "G15"; G16 at its hand-back: look for a process left behind, read the refusal's path, the settings
  answer's failure path and the two scripts myself, then ONE independent review with probes (a page
  that raises a cap on writes to Telegram: always), its fixes, the full runs once (whole
  `internal/server` and `livepages`, the collector's pages and mirror door tests by name; no race
  detector unless it came to change code that runs concurrently), entry "G16".
- 11-16 18:14: **G15's review is back: "may be listed" (0 must fix, 0 should fix, 4 minor;
  `REVIEW-G15-staging-free.md`, 129 lines; probes in `wt-pages-review-g15-scratch`).** By probe: with
  the real call made to answer 1 byte, and separately "does not say", only the one test that asks the
  real disk on purpose failed, across the Staging, Overview, Mirror, Settings and the release and
  want-again tests by name (my brief's pattern had missed four tests that build the staging rig: the
  reviewer added them); with the seam ignored ten tests fail, so the probes reach the right code. The
  old order of flag and answer failed the new test 10 of 10 runs for the reviewer too; the head passed
  30 of 30 while other sessions' tests ran. No race on the seam, at most one real call at a time, the
  guard as before. Not checked by it: the real call off Windows, a really full disk, the two look
  tests (they run only with their variable set).
- **All four minor points taken (my judgement: the first is this piece's own subject):** the one test
  that asks the real disk failed on a disk with exactly 0 bytes free: it now takes 0 as an answer; one
  redundant condition; one comment's words; the report's overtaken paragraph. **Applied by a script of
  mine** (`runs-pages-p6/g15-minors.py`: nine exact replacements, each found once), gofmt and the eleven
  named tests through the lock script: ok; committed and pushed: **`wip/pages-free` 7b6fddc0** (3 files,
  +16 -14 on 508b4de9; the copy clean). No second review pass: words and one comparison, read by me.
- 18:15: **THE FULL RUNS OF G15 ARE STARTED, ONCE, BY A SCRIPT in the background**
  (`bash runs-pages-p6/run-g15.sh`; 6.0 GB free then; it holds the track's lock): the copy clean and
  pushed, a trial merge with the main head, gofmt, `go vet` of `internal/server` for Windows and Linux,
  the WHOLE `internal/server` on Windows, the race detector on the server's `TestStaging` tests by name
  in a Linux container. Its lines: `runs-pages-p6/g15-7b6fddc0.summary`; its output `g15-run.out`. It
  merges, commits and pushes nothing.
- A correction: G16's coder was started at 18:07 (my entry and the row said 18:08).
- **Running now:** that script; G16's coder (`wt-pages-cap`; its go commands wait for the lock while
  the script runs). **Next step in one line:** read the summary (it should end within 25 minutes: look
  at 18:45 at the latest); every line exit 0: entry "G15" at the end of `MERGE-QUEUE.md`, "LISTED,
  READY" on the row and a board message; a failing line: read its log first.
- 11-16 18:19: **G15 IS LISTED, READY: entry "G15" at the end of `MERGE-QUEUE.md`** (`wip/pages-free`
  7b6fddc0, holding 78739d59). Its full runs ended 18:18, every line exit 0
  (`runs-pages-p6/g15-7b6fddc0.summary`): the copy clean and pushed, the trial merge clean, gofmt, vet
  for Windows and Linux, the WHOLE `internal/server` on Windows 139.3 s with no failed test, the race
  detector on the server's `TestStaging` tests by name: 26 passed (the four new ones among them), 6
  skipped (the look tests and the tests at size), no data race; 3 minutes 42 seconds in all. Routine
  steps: by scripts of mine (the runs; the entry and the notes), each one call.
- 18:16: **THE OWNER'S WORDS ON THE FOLDER'S PROGRAM ARE HERE (the integrator's message to this session
  and its board message of 18:20, numbered 150 a second time): "Well, deeply unsatisfying so far." ...
  "Overall, it's a very ugly app, not fully functional, doesn't quit properly, and still runs in a
  browser, just a standalone one?" IT COMES BEFORE EVERYTHING ELSE OF THIS TRACK.** The points that are
  pages': (a) the Queue page shows only "Cannot read properties of null (reading 'length')" on a new,
  empty catalogue; (b) Settings, Display, Theme: two hint lines over each other; (c) the header's
  "Viewer: set its address" leads to an empty field although the launcher started the viewer; (d) a
  wrong folder named at the setup cannot be changed afterwards (the owner named the old app's library
  root as the library; nothing was written there), and the setup must say what it sees in a non-empty
  folder before it saves; (e) "quitting doesn't actually exit it": a new launcher one second after the
  first Quit (cause not known); at both starts with a saved setup the app's window ended by itself
  after 8 s and 4 s, in the second the viewer was started; closing the window leaves everything
  running (G11's design); (f) the look and "still a browser": the integrator asks the owner what native
  should mean; NO RESTYLE before that answer. The owner's app may still be running from its folder:
  nobody rebuilds, replaces or touches that folder.
- 18:19: **"G17" (points a and b) IS BRIEFED AND WITH A CODER: `BRIEF-G17-empty-catalogue-pages.md`,
  copy `wt-pages-empty`, branch `wip/pages-empty`, cut from 78739d59 (a single command of mine), one
  Opus coder at high effort**, its go commands through the track's lock: the cause at its source; every
  GET answer on catalogues made the way the program makes a new one (nothing, one account, one chat
  with nothing) failing on any `null` where a script reads a list; the scripts not dying whole, with
  plain "nothing yet" words; EVERY page opened on the empty catalogue in a browser engine at two widths
  (Edge headless with a profile of its own and every address but 127.0.0.1 sent to a dead port), kept as
  a skipped-unless-asked test if it can be; the Theme row's cause.
- **G16's coder (the cap's Settings row) goes on to its hand-back** (in flight; its review waits behind
  the owner's points).
- **Running now:** G17's coder (`wt-pages-empty`), G16's coder (`wt-pages-cap`). **Next step in one
  line:** read the launcher's window and viewer start, its second-start path and its settings file
  myself, then brief "G18" (points c, d, e) for one Opus coder in `internal/launcher`; the question of
  what closing the window should do goes onto the owner's list in one line with a recommendation.
- 11-16 18:23: **THE LAUNCHER'S TWO PIECES FROM THE OWNER'S POINTS ARE BRIEFED AND WITH CODERS (one Opus
  coder each, high effort; both copies cut from 78739d59 by one command of mine; 5.0 GB free at 41%
  CPU, measured first; every go command through the track's lock):**
  - **"G18", `BRIEF-G18-window-ends-and-quit.md`, copy `wt-pages-quit`, branch `wip/pages-quit`:** (A)
    the app's window that ended by itself in the second the viewer's window was started: reproduced
    with the REAL window program on invented data, read to its cause, fixed (in the launcher, or as
    lent lines in ONE commit in the viewer's `internal/window`), and a look that starts both real
    windows and fails unless both still run after 20 s; (B) whether a path of ours can start a
    launcher just after a Quit; (C) a person's close of the window: the launcher asks in a small
    Windows box "Keep it running" / "Quit the app" every time (until the owner says what a close
    should do), and an end that was not a person's close is never taken for one; (D) the header's
    "Viewer" link with the window kind of viewer: `-viewer-url` to a new launcher route `/viewer`
    ("Show the viewer").
  - **"G19", `BRIEF-G19-change-folders.md`, copy `wt-pages-folders`, branch `wip/pages-folders`:** (E,
    first) whether the owner can get the setup back TODAY on the build in the folder (the launcher's
    settings file deleted), tried on a scratch copy, the steps written to
    `archiver/docs/progress/pages-folders-OWNER-STEPS.md`; (A) "Change the folders" on the launcher's
    page; (B) what a change means for files already there, true of the code; (C) the setup says what
    it sees (numbers only): a non-empty library or staging folder that is not this app's needs a
    second explicit yes, nested folders refused; (D) a way from the app's pages to the launcher: a
    collector flag `-launcher-url` as LENT LINES in one commit, a region "This program" on Settings.
- **What I read for the two briefs (18:20 to 18:22):** `start.go` `viewerSpec` and `collectorArgs`
  (the viewer's window is started with NO `-data` beside the pages' window of the same program;
  `-viewer-url` only for the browser kind), `present.go` `startWindow`, `spawnWindow`, `windowEnded`
  (an end with code 0 the launcher did not ask for is taken as the person's close: nothing shown,
  nothing started again), the launcher's log words, `settings.go`'s file name. NOT read: `internal/window`
  (the viewer's; G18's coder reads it to the cause), the setup's flow (G19's coder).
- **The look, point (f): nothing is restyled before the owner's answer to the integrator.**
- **Running now, four Opus coders of this session:** G16 (`wt-pages-cap`), G17 (`wt-pages-empty`), G18
  (`wt-pages-quit`), G19 (`wt-pages-folders`). Real windows of G18's tries show on the owner's screen
  for seconds at a time (on invented data, with the Windows profile folders redirected). **Listed,
  READY: G15.**
- **Next step in one line:** at each hand-back: look for a process or window left behind, read the
  risky part myself (G17: the null's cause and the new test's form; G18: the cause and how a person's
  close is told; G19: what the setup counts and what "Change the folders" stops), then ONE independent
  review each with probes (G18 and G19 always: they start and stop programs for the owner), fixes, the
  full runs once by a script (whole `internal/launcher` for G18 and G19, whole `internal/server` where
  it changed), the entries; G17 first, it is the smallest and the owner's first sight.

### STATE FOR A TAKE-OVER (P6, 11-16 18:24)
Read `BOARD.md` (the Pages row, the integrator's row, its message of 18:20 with the owner's words,
pages' messages 150 and 155 and the one after), then this block.
1. **Listed, READY, waiting for the integrator: G15** (`wip/pages-free` 7b6fddc0; entry "G15").
2. **Four coders run as agents of session P6; if P6 is gone, their branches on `private` show how far
   each came** (each commits and pushes as it goes; its report is `archiver/docs/progress/pages-*-REPORT.md`
   on its branch): G17 `wip/pages-empty` (the pages on an empty catalogue; the Theme row), G18
   `wip/pages-quit` (the window that ended by itself; Quit; the Viewer link), G19 `wip/pages-folders`
   (changing the folders; the setup's warnings; the owner's steps for today), G16 `wip/pages-cap` (the
   cap's Settings row). The briefs are `BRIEF-G16` to `BRIEF-G19-*.md`. None is reviewed.
3. **The order from here:** the owner's points first (G17, then G18 and G19; each: my read, one
   independent review with probes, fixes, full runs once, entry), then G16's review and listing, then
   the copy checks' controls on Settings (C16's doors, copies' 134 c), "G14" (what is left of it after
   G18 and G19: the pages adapting by the user-agent word, the once-only redirect only for the window),
   the launcher's two flags for the owner's words (copies' 127 d), P4's points 3 c to 3 f, the page for
   adopting a chat. **The look (the owner: "very ugly", "still a browser"): nothing before the owner's
   answer to the integrator.**
4. **Waiting on others:** the integrator: the launcher's log lines of 18:07:50 to 18:09:10 as a file
   (155 b), the owner's line on what closing the window should do (155 e); the viewer: whether a
   viewer's window sends anything to another running window program (155 c); Core: its word on an
   unmarked, non-empty library and on the lent flag `-launcher-url`; the mirror: how "no upper bound"
   reads in the cap's door.
5. **Tools of this session (`runs-pages-p6`, not in git: the folder is ignored):** `go1.sh` (the
   track's one-go-command lock; at most 5 minutes of waiting for memory in all), `run-g15.sh` (a full
   run's form to copy: no wait for memory, nothing merged or pushed), `notes.py` (the row, an entry and
   a board message in one call), `remove-copies.sh` (finished copies: clean and equal to `private`).
6. **How the work goes:** as the earlier blocks; and from today: a page is opened on a NEW, EMPTY
   catalogue before it is listed; anything that starts two programs is tried with both REAL programs
   once; a test never depends on this PC's disk or on scheduling.
- 11-16 18:28: **the integrator's second message to this session and its board messages 151 to 153
  (its own numbering; read by me whole): THE OWNER CHOSE THE APP'S SHAPE (18:27, on the combined
  picture: "Yeah, I think that's a great place to start. Go with it please."): ONE WINDOW, one list on
  the left (Overview, Saved Messages, the library's views, the chats; Settings and Accounts at its
  foot), the content on the right, the Overview's numbers each a link to its filtered place, the
  collector's state in the title bar, a close that asks, folders in Settings, an empty state on every
  page.** The decision: `DESIGN-ONE-WINDOW.md`; the picture: `design-options/app-look-options.html`.
  Pages leads the joint note on how; the viewer's session is at 94% of its context. The faults of the
  first start stay first, in the present look. Usage 74% of all models' week at 18:27, about 10 points
  an hour. Also from the owner (151 a): "where is saved messages in chats? I don't see."
- 18:33: **THE JOINT NOTE IS WRITTEN: `DESIGN-ONE-WINDOW-HOW.md`** (a proposal of the pages track; the
  pages' side can be briefed from it; four questions for the viewer's code at its end, one for Core).
  Read by me for it: the decision; `cmd/tgarchive-window/main.go`'s head and exit codes (0 is "closed
  by the person" AND "already open, brought to the front"); both servers' framing rules (each forbids
  being framed). Its answers: the two servers stay (the VPN rule, the import wall); the WINDOW PROGRAM is the
  viewer's and the one window is the viewer's window (it alone has mpv and the viewer in-process),
  started once by the launcher with the pages' and the launcher's addresses named to its gate; THE
  SHELL (the list, the pill, the look, the empty-state piece) is the pages track's, a new small package
  `internal/appshell` that BOTH servers mount, with one Go builder reading the list from the catalogue
  both have open; the places are plain links between the two servers (no frame in a frame, no proxy);
  the order: the first start's faults, then W1 the shell, W2 one window, W3 the Overview with links, W4
  the library's views and the details panel. NOT read for it: `internal/window` beyond its file list,
  the viewer's page scripts, the picture's HTML.
- **Saved Messages on a new catalogue (the owner's 151 a), pages' answer:** the app's Chats page lists
  the chats to collect and was never meant as the place to read one; whether the account's own chat is
  a row on a new catalogue is asked of Core in the note (its section 8); nobody sends the owner there
  until the list of W1 shows it.
- **Running now, unchanged:** the four coders (G16, G17, G18, G19). **Next step in one line:** as the
  entry of 18:23; "W1" is briefed by me only after G17 is listed (its empty states and its
  opened-in-a-browser test are what W1 builds on).
- 11-16 18:43: **G16's coder handed back: `wip/pages-cap` e0fe666c, pushed, the copy clean** (14 files,
  +1,028 -37 on 78739d59; the lent lines in `collector/pages_mirrors.go` are commit 1111450a; test
  functions added 12, removed 0 (looked); its named tests passed through the lock; 11 planted changes
  all caught; report `archiver/docs/progress/pages-cap-REPORT.md`). As briefed: the row under the
  interval with its bounds from the door's answer, the range refusal built from the door's bounds of
  the moment (in the seam: a table row holds only fixed words), the cost sentence's number from the
  door, `AutoSetUpFailed` shown, the settings answer not failing whole when the cap's door fails, no
  constant of the mirror package's cap in the two packages (kept by two tests). Where the code changed
  my words: "waited out in full" (a wait over the step's bound is recorded and the plan waits for it);
  no Premium case in the channel limit's guard ("at 500, no new mirror is created"); the run's flag is
  told before "unreadable". Seen by its coder in the demo at 1,024 and 375 px (the demo's fake showed
  "from 1 to 100": the fake's own bounds); one spacing change of the page script was made AFTER its
  named tests ran. **NOT verified by any test: `mirrorsettings.js` itself; the run's flag end to end.**
  One slip it named: a `go vet` of two packages in its first build command.
- **NOT READ BY ME YET, NOT REVIEWED: G16 waits behind the owner's points** (my order of 18:16): its read
  (the seam's refusal path, the settings answer's failure path, the two scripts) and its ONE independent
  review with probes come after G17, G18 and G19 are in review; its full runs after that.
- A correction: the joint note and my entry above were stamped 18:32 and 18:33; the clock said 18:30
  (the note's head is put right).
- **Running now:** three coders (G17, G18, G19). **Next step in one line:** unchanged: each hand-back
  read, reviewed, run, listed, G17 first; then G16's read and review.
- 11-16 18:51: **G19's coder handed back: `wip/pages-folders` a281c273, pushed, the copy clean** (23
  files, +1,457 -47 on 78739d59; test functions added 15, removed 0 (looked); the lent lines in the
  collector's `command.go` and `pages.go` are commit c1d80f48; its named tests passed through the lock;
  report `archiver/docs/progress/pages-folders-REPORT.md`).
  - **The owner's way out TODAY, on the build in the folder (78739d59): it exists.** Quit; rename
    `tgarchive.json` in the app's folder; open `tgarchive.exe`: the setup shows, offers the same data
    folder, and the collector is started on the same catalogue with the new folders (a test on stand-in
    programs; the REAL collector's part is read from its code, not run: an archive made by the launcher
    stores no library folder of its own, so the new one is taken; a new staging folder is marked as
    this archive's). The steps: `archiver/docs/progress/pages-folders-OWNER-STEPS.md` on the branch
    (read by me whole: full paths, one PowerShell line; it says the VPN adapter and the other choices
    are made again, and that the old staging folder keeps two small files of the app's to delete).
  - "Change the folders" on the launcher's running, refused and ended views: one confirm on the same
    page, the saved-files count asked of the pages once, the same clean stop as "Stop the program", the
    setup with the saved values, "Save and start" or "Cancel".
  - The setup's look (`look.go`, read by me whole): a folder's direct entries by name, at most 10,000,
    2 s, in its own goroutine, nothing opened, nothing written, numbers only out; staging is this app's
    when the collector's mark's name is among them; **the library has no mark, so ANY non-empty library
    needs the second yes, the saved one too**; nested folders and anything inside `programs` refused by
    name; the write check only after the look, the nesting check and the yes.
  - What a change means, from Core's code (read by the coder, not by me): places are kept relative to
    the library and nothing moves files; a file not found is wanted again; a `-library` that differs
    from an archive's own stored one is refused at the start.
  - `-launcher-url` (lent), a "Program" link in the header and a region "This program" on Settings.
  - NOT verified by its coder: the setup page and the new region were not looked at in any browser
    engine; whether the window's gate lets "Program" through; the real watchdog and collector.
- 18:53: **G19's ONE independent review runs** (`BRIEF-G19-review.md`; one Opus reviewer, read-only on
  `wt-pages-folders`, probes by overlay in `wt-pages-review-g19-scratch`, its go commands through the
  lock; it writes `REVIEW-G19-change-folders.md`): can the app ever write into a folder the owner did
  not knowingly give (the second yes enforced at the save); can any order of clicks leave programs on
  the old folders; the look's bounds and that only numbers leave it; the page's sentences against
  Core's code; **whether the owner's steps file may go to the owner as it is**; the lent flag; the
  tests by planted changes; and the look at the pages nobody has made (Edge headless, two widths).
- **Running now:** G17's and G18's coders, G19's reviewer. Handed back and waiting for its read and
  review: G16. **Next step in one line:** G19's findings judged and fixed by a fresh coder with an
  exact instruction; G17 and G18 at their hand-backs as before.
- 11-16 18:53: **read on the board (the viewer's 161, 162 and 164, Core's 163, the integrator's 154 by
  its numbering): a fresh viewer session, B7, has the track and agrees with the joint note; its answers
  to the note's four questions are the note's new section 9 (added by me).** The integrator put the
  owner's two folders right by hand in the settings file at 18:35 (the owner: "Set them to empty folders
  please"): my message 165 a came after it and is overtaken; G19's steps file stays as the record.
- **The window that "ended by itself": two stories with the same log lines.** The viewer's
  investigation (three tries with real windows) did not reproduce an end at a plain start and reads the
  owner's run as the owner's own close of one of two windows (a kill with its job also ends with 0).
  **G18's coder, with the real windows, found a path of ours** (`wip/pages-quit` 8c13d302; read by me
  in its commit message only): a start refused before its programs ran, then "Try again": the launcher
  started the viewer and in the same second ended the app's window by its own clean stop and started a
  new one. Mended there (the pages' address stays named; the launcher's own stop has its own log line),
  with `TestRealBothWindows*` and `deploy/folder/look-both-windows.sh`. Which of the two the owner met:
  the integrator is asked for the log's lines (159 a).
- **The exit codes are the viewer's (its 162 d): the window's flag `-tell-close`: 4 the person's close,
  6 already open, 0 every other clean end.** G18's coder had made a lent commit of its own in
  `internal/window` (479109e8): **steered by one message of mine at 18:55** (a decision): revert it by a
  new commit, write the launcher against the flag (ask on 4 only; 0 is never the person's wish), keep
  the real-windows look working on its base, and say "merge after the viewer's exit-code entry".
- **Running now:** G17's and G18's coders, G19's reviewer. Waiting for its read and review: G16.
  **Next step in one line:** unchanged.
- 11-16 18:58: **G17's coder handed back: `wip/pages-empty` 4bc6a229, pushed, the copy clean** (17 files,
  +832 -47 on 78739d59, `internal/server` only; test functions added 3, removed 0 (looked); report
  `archiver/docs/progress/pages-empty-REPORT.md`).
  - **The owner's error, to its cause:** `GET /api/queue` answered `"servers": null` on a catalogue with
    no file (a copy made with `append` onto a nil list in `queue.go`), and the Queue page's script took
    its length. With the old line put back for one run both new tests failed with the owner's exact
    words. **Four more answers had the same on a new catalogue** (the state's and the live poll's
    `accounts` and `lanes`, the Overview's `groups`, the hourly figures' `dcs`): all made lists at the
    source.
  - Kept true by `TestEmptyCatalogueAnswersWhole` (catalogues made as the program makes a new one, in
    four states, with idle seams and without the program; no `null` outside a one-entry allow-list) and
    `TestEmptyCatalogueRoutesListed` (every GET route must be asked by it).
  - **The first test that runs the page scripts: `TestPagesInBrowser`** (Edge headless on 127.0.0.1,
    everything else to a dead port; skipped unless `TGARCHIVE_BROWSER` names the browser): it fails on
    an error box, a script error, or "Cannot read", "undefined", "null", "NaN" shown. By its coder:
    every page and sub-page in the four states, with and without the program, at 1,280 and 390 px: 184
    loads, all clean.
  - The scripts read lists through `ui.whole`; Queue, Staging and Overview draw region by region, a
    failed region showing its own line; new "nothing yet" words on the Queue page and the Overview.
  - The Theme row: a second hint line shared one grid cell with the first; it has its own row now.
  - Said by its coder as not fixed: every page is about 450 px wide at phone width (the header's row
    does not wrap): for the look's redesign; `mirrorwords.js` says "every 30 minutes" for an unreadable
    interval (that IS the mirror's fallback for an unreadable value: right as it is, my word).
- **My read (18:59; the Go sources' six small changes, `ui.js`'s two helpers, the Queue script's
  difference):** as briefed; nothing concurrent changed (a snapshot's nil lists made empty: no race
  run). **What nobody has checked: that the rewritten scripts still draw a FILLED archive** (every look
  was on empty catalogues).
- 19:00: **G17's ONE narrow independent review runs** (`BRIEF-G17-review.md`; one Opus reviewer,
  read-only on `wt-pages-empty`, probes in `wt-pages-review-g17-scratch`): first of all the pages loaded
  on filled invented data in a browser engine at two widths against the base; then whether a region's
  own error line can hide a fault, whether `whole` can turn "not known" into "nothing", the two Go
  tests by planted routes, and whether the browser test can pass without having looked.
- **Written, not started: `runs-pages-p6/run-listing.sh`** (by me, so read whole; the form of
  `run-g15.sh` for any piece: the copy clean and pushed, a trial merge, gofmt, vet for both systems and
  the WHOLE of each named package, named tests of others; `TGARCHIVE_BROWSER` set to Edge so that a
  browser test is not skipped; no wait for memory; nothing merged or pushed).
- **THE FULL RUNS OF G17, said before they start (after the review's fixes, once):** whole
  `internal/server` on Windows with the browser test not skipped (about 5 minutes), gofmt, vet for
  Windows and Linux; whole `internal/collector/livepages` (seconds); no race detector (nothing that
  runs concurrently changed).
- Two corrections to my entry of 18:53: my message to G18's coder went at 18:53, not 18:55; the ask for
  the log's lines is my 155 b (the entry said 159 a).
- **Running now:** G18's coder; the reviewers of G19 and G17. Waiting for its read and review: G16.
- 11-16 19:03: **G18's coder handed back: `wip/pages-quit` d6a89aaa, pushed, the copy clean** (25 files,
  +1,516 -51 on 78739d59; test functions added 12, removed 0 (looked); its lent commit in
  `internal/window` is reverted by a new commit at my word; report
  `archiver/docs/progress/pages-quit-REPORT.md`). **TO BE MERGED AFTER THE VIEWER'S EXIT-CODE PIECE:**
  the launcher passes `-tell-close` to the window, which the head's window program refuses.
  - A plain start of both real windows ended neither (20 s), as the viewer track found. **The path of
    ours that gives the owner's lines:** a start refused before its programs ran (or the setup), then
    "Try again": the launcher stopped and restarted its own window in the second it started the viewer.
    Mended (the pages' address stays named, the same window kept; the launcher's own stop has its own
    log line). In the owner's log that path would show "try again, asked from the page" (or "the setup
    was saved") and "start 2 of this run" before the end; the integrator's file of lines was not there.
  - No path of ours starts a launcher after a Quit: what is left is the owner's own double-click.
  - Only exit code 4 is the person's close; 6 starts nothing; an unasked 0 starts the window again
    once in the run, then the browser with the reason.
  - The close box: a helper process (`tgarchive.exe -ask-close`), Windows' task dialog "The app is
    still collecting in the background." with "Keep it running" / "Quit the app"; Quit is the
    watchdog's clean stop.
  - `GET /viewer` on the launcher with "Show the viewer" (a guarded POST); the collector gets
    `-viewer-url` to it; **with the pages in the app's window the viewer's window now starts only
    there, not with the programs**; Settings says "set by the program's launcher".
  - The look that was missing: `deploy/folder/look-both-windows.sh` and `TestRealBothWindows*` (both
    real windows as the launcher starts them; only with `TGARCHIVE_REAL_WINDOW=1`).
  - NOT verified: anything on the owner's screen (the box's look, whether it comes to the front);
    `-tell-close` with a real window.
- **My read (19:04; `closeask.go` whole, `present.go`'s difference):** as briefed. Given to the reviewer
  as suspicious: a person's close while NOTHING of the app runs (the box is asked only while a
  watchdog is followed: does the launcher then stay as a process with no window?); "Quit the app" sent
  on a channel without waiting (can it be lost?); what the head's window program does with the flag.
- 19:05: **G18's ONE independent review runs** (`BRIEF-G18-review.md`; one Opus reviewer, read-only on
  `wt-pages-quit`, probes in `wt-pages-review-g18-scratch`; it may run the real-windows look once).
- **The track's lock was left behind once (found by G18's coder at 18:33: the lock of 18:15, the time
  of G15's run, which had ended at 18:18; coders waited on it; the coder removed the empty folder).
  Why my run's own release did not take it away I do not know.** Hardened (two small edits of mine,
  syntax-checked): a lock older than 15 minutes is taken as left behind (60 before); a full run
  touches the lock at every step and also removes it at its end, not only by its trap.
- **G16 (the cap's row) stays unread and unreviewed for now: with usage at about 80% the reviews go to
  the first start's faults first** (G17, G18, G19 are each in review).
- **Running now:** three reviewers (G17, G18, G19). No coder runs.
- 11-16 19:29: **G18's review is back: "may be listed after these fixes: 1, 2, 3, 4" (3 must fix, 5
  should fix, 6 minor; `REVIEW-G18-window-and-quit.md`, 170 lines; its findings read by me whole).**
  **All three must-fixes, each confirmed by a probe, are the owner's "doesn't quit properly" itself:**
  (1) a person's close of the window while NOTHING of the app runs (the setup, a refused start, an
  ended run) left the launcher running with no window and no page; (2) a close during a start (up to
  about 25 s before the watchdog is followed) was not asked and the app then ran with no window; (3)
  after the box's "Quit the app", a stop that could not be sent, or one held for a sign-in's code, left
  the app running with nothing shown. Should fix: a box that cannot be shown changed nothing; the merge
  order not guarded (the head's window refused the flag: every start would have fallen back to the
  browser with an untrue reason); the box outliving the run it asks about; one planted change not
  caught. Seen by the reviewer with the real programs: the look printed "ok" (both windows 20 s, a
  retry kept one window); the viewer's window with `-tell-close` gave 4 at a close and the box was
  asked once; the box is Windows' task dialog, topmost, and did NOT get the foreground from a
  background start (only a person's real close can show whether it does).
- **Read on the board at 19:31: the owner, asked by the viewer whether they closed the window
  themselves: "I don't think I closed it. I did see them flicker up, several times."** That fits the
  path G18's first round mended (the launcher's own stop and restart of its window at a retry).
  **G15 IS MERGED (2334c659); the viewer's exit-code piece is merged (the main head is f1d7127b)**: so
  G18 no longer waits on another track: its fix round merges that head in. Trial merges with f1d7127b:
  G17, G18 and G19 each clean; **G18 with G19: a conflict (both in the launcher): whichever is ready
  second takes the other's branch in, by a coder.**
- 19:31: **G18's ONE fix round runs: `BRIEF-G18b-fixes.md`, a fresh Opus coder** (every finding but
  two minors: the launcher ends at a close with nothing running; a close during a start is asked when
  the programs run; after the box's Quit the window comes back when the stop is not sent or not over in
  5 s; a box that cannot be shown brings the window back; a test that fails while the window program
  of the tree does not know the flag; the box ended with the run it asks about; then the real-windows
  look once on the merged tree).
- **Running now:** G18's fix coder; the reviewers of G17 and G19. Waiting unread: G16. **Next step in
  one line:** G18: read the round (the three must-fixes' paths), a closing look by a reviewer at those
  lines only, the full runs once (`run-listing.sh wt-pages-quit wip/pages-quit g18
  "internal/launcher cmd/tgarchive-open" "internal/server=Viewer|Settings"`), the entry.
- 11-16 19:32: **the integrator, to this session: THE OWNER HAS SET THE OBJECTIVE FOR WHAT IS LEFT OF
  THE USAGE (about an hour this week): "to actually deliver something, meaning the features that work
  with the much improved look".** In its order: (1) the first start's faults: list what is ready, it
  merges at once; (2) the one window's shell with the list on the left in the new look, over the pages
  and the viewer as they are; (3) the Overview's numbers as links. Start nothing else; commit and push
  at every step.
- 19:33: **G17's review is back: "may be listed after these fixes: 1, 2" (0 must fix, 2 should fix, 5
  minor; `REVIEW-G17-empty-catalogue.md`). THE FILLED PAGES DRAW EXACTLY AS ON THE BASE:** 156 loads in
  Edge headless (13 addresses at 1,280 and 390 px; the fixture with filled fakes, the same without the
  program, and the demo), each with the head's scripts and with the base's: all 78 pairs the same text
  with digits folded, the same regions, no script error. The Theme row's overlap is seen on the base's
  screenshots (three rows had it) and gone on the head. **Both should-fixes are in the TESTS only, and
  nothing is wrong today:** (1) the route-listing test finds only GET routes written as one plain
  string (a wildcard, a pattern with no method, a joined or raw string would be missed); (2) the
  empty-catalogue test accepts a 404 or 400 for any path that names chat 1 or account 1, so a real
  refusal there would pass.
- **MY JUDGEMENT, under the owner's objective: G17 IS LISTED AS IT IS, with the two test-only findings
  said in its entry as owed and not in** (they harden two tests against tomorrow's routes; the owner's
  Queue page is mended and every page was loaded filled and empty). They are the first lines of the
  next pages piece that touches those tests.
- 19:33: **G17's full runs were started at 19:32, once, by `runs-pages-p6/run-listing.sh`** (before
  the review's verdict, against my own order: the hour decides; the review asks for no change to
  product code, so they are the runs of the listed head).
- 19:34: **"W1", THE SHELL, IS BRIEFED AND WITH A CODER: `BRIEF-W1-shell.md`, copy `wt-pages-shell`,
  branch `wip/pages-shell`, cut from the main head f1d7127b (a single command of mine); it merges
  G17's head in first.** A new package `internal/appshell` (the list's builder over the catalogue, the
  top strip, the frame, in the picture's look) mounted on the app's pages: the old top bar gone, every
  place reachable from the list, the viewer's places as plain links to the viewer's address, no page
  wider than the screen. It pushes after each of five steps. Read by me for it: the chosen picture's
  first option (its words and structure).
- **Running now:** W1's coder; G18's fix coder; G19's reviewer; G17's runs (a script). Waiting unread:
  G16 (not part of the hour's objective: left as handed back).
- 11-16 19:42: **G17 IS LISTED, READY: entry "G17" at the end of `MERGE-QUEUE.md`** (`wip/pages-empty`
  4bc6a229; clean against f1d7127b). Its full runs ended 19:41, every line exit 0
  (`runs-pages-p6/g17-4bc6a229.summary`): gofmt, vet of `internal/server` and `livepages` for both
  systems, the WHOLE `internal/server` on Windows 428.5 s with the browser test not skipped, the whole
  `livepages`. The entry says plainly that the review's two test-only should-fixes are not in it.
  Routine steps: the runs and the notes by scripts of mine, one call each. Board message 174.
- **Running now:** W1's coder (`wt-pages-shell`), G18's fix coder (`wt-pages-quit`), G19's reviewer.
  **Next step in one line:** G18's round read and its full runs
  (`bash runs-pages-p6/run-listing.sh wt-pages-quit wip/pages-quit g18 "internal/launcher cmd/tgarchive-open" "internal/server=Viewer|Settings|EmptyCatalogue"`),
  then its entry; G19's findings to one fix round; W1's steps as they are pushed.

### STATE FOR A TAKE-OVER (P6, 11-16 19:42; this block replaces the one of 18:24)
Read `BOARD.md` (the Pages row, the integrator's row and its messages of 18:20 to 19:32 with the
owner's words and objective), `DESIGN-ONE-WINDOW.md` and `DESIGN-ONE-WINDOW-HOW.md`, then this block.
1. **The owner's objective (19:30), for what is left of the week's usage: "to actually deliver
   something, meaning the features that work with the much improved look".** The order: the first
   start's faults listed and merged; the shell in the new look (W1); the Overview's numbers as links
   (W3). Nothing else is started.
2. **Merged: G15. Listed, READY: G17** (`wip/pages-empty` 4bc6a229).
3. **With agents of session P6 (if P6 is gone, each branch on `private` shows how far it came; each
   report is `archiver/docs/progress/pages-*-REPORT.md` on its branch):**
   - **G18** `wip/pages-quit` (from d6a89aaa): its ONE fix round (`BRIEF-G18b-fixes.md`; the review:
     `REVIEW-G18-window-and-quit.md`); after it: read the three must-fixes' paths, the full runs by the
     line above, the entry. It merges the main head f1d7127b in.
   - **G19** `wip/pages-folders` a281c273: in its independent review (`BRIEF-G19-review.md`; it writes
     `REVIEW-G19-change-folders.md`); then ONE fix round by a fresh coder, the full runs
     (`run-listing.sh wt-pages-folders wip/pages-folders g19 "internal/launcher internal/server" "internal/collector=LauncherURL|Pages"`),
     the entry. **G18 and G19 conflict in the launcher: the second to be listed takes the first in.**
   - **W1** `wip/pages-shell` (from f1d7127b with G17 merged in; `BRIEF-W1-shell.md`): pushes after
     each of five steps; unreviewed. The viewer mounts `internal/appshell` once its door is on the
     branch (say the head on the board); the review's two test-only findings of G17 are owed with it.
   - **G16** `wip/pages-cap` e0fe666c: handed back, NOT read by me, NOT reviewed (the cap's Settings
     row; `BRIEF-G16-mirror-cap-row.md`); not part of the hour's objective.
4. **Each of G16, G18, G19 and W1 changes `internal/server` and is cut from an older head: each takes
   the main head in before it is listed.**
5. **Tools (`runs-pages-p6`, not in git):** `run-listing.sh` (the full runs of a piece: read its head),
   `go1.sh` (the track's lock), `notes.py` (row, entry, board message in one call).
6. **How the work goes, from today:** a page is opened on a NEW, EMPTY catalogue and on a filled one in
   a browser engine before it is listed (`TestPagesInBrowser` with `TGARCHIVE_BROWSER` set); anything
   that starts two programs is tried with both REAL programs (`deploy/folder/look-both-windows.sh` on
   G18's branch); every time written into the notes comes from the clock at that moment (use the
   script's `19:42`: my stamps ran up to three minutes ahead four times today).
- 11-16 19:55: **A FAULT OF MY OWN SCRIPT HELD THE TRACK'S CODERS FOR 14 MINUTES (19:41 to 19:55).**
  My hardening of 19:04 made the full run remove the lock at its end and THEN write its last line,
  whose "touch" of the lock's name made a PLAIN FILE `go.lock`; `go1.sh` could neither take a lock
  over it nor see it as left behind, so every go command of W1's and G18's coders waited (found
  through G19's reviewer's report). Removed by me at 19:55; mended (two small edits of mine,
  syntax-checked): the run empties the lock's name before it writes on and only touches a folder;
  `go1.sh` removes a plain file of that name. Fourteen minutes of the hour lost to it.
- 19:53: **G19's review is back: "may be listed after these fixes: 1, 2, 3, 4, 5" (1 must fix, 5
  should fix, 5 minor; `REVIEW-G19-change-folders.md`).** **The must-fix, confirmed by a probe: the
  second yes was tied to the path, not to what the owner was shown:** a yes given while a folder
  "cannot be looked at now" still counted when the save's own look then found it full: the settings
  were written and the collector got that library without the owner ever seeing "not empty" (a slow
  share over Wi-Fi is exactly that case). Should fix: no test for it, and two planted changes passed
  (nesting one way only; the write check moved before the look); **folders saved by an earlier build
  are never looked at** (a saved setup naming another program's library would start silently on the
  new build); a full data folder with no catalogue gets no yes; "Change the folders" offered where
  something of the folder may still run; the "Stopping" view has no time limit and no way on. **The
  owner's steps file: "yes, it may go as it is"** (not needed today: the integrator set the folders by
  hand at 18:35). Seen by the reviewer at 1,280 px: the setup reads clearly; every sentence about
  Core's code is true. Not checked: the narrow width; the Settings region in a browser.
- 19:56: **G19's fix round is BRIEFED AND NOT STARTED: `BRIEF-G19b-fixes.md`** (every finding; it also
  takes the main head and, if merged by then, G18 in, with their conflict in the launcher). **My
  decision for the hour: no coder for it now**: the owner's folders are right since 18:35, and what is
  left of the usage goes to the shell (W1) and to Quit (G18). Whoever has the track next starts it
  with one fresh Opus coder.
- **Running now:** W1's coder (`wt-pages-shell`: G17 merged in at 19:36, nothing more pushed yet: it
  stood behind the lock), G18's fix coder (`wt-pages-quit`: the main head merged in, a1ca9e09).
- 11-16 20:33: **W1's coder handed back: `wip/pages-shell` faaff0f8, pushed, the copy clean: ALL FIVE
  STEPS** (+1,472 -87: the new package `internal/appshell` (`shell.go` with the builder `List`, one
  stylesheet, one script, tests) and its mount on the app's pages (`internal/server/shell.go`, the
  routes `/shell/` and `GET /api/shell`, `web/index.html`, `base.css`, `main.js` the only page script
  touched); test functions added 5, removed 0; report `archiver/docs/progress/pages-shell-REPORT.md`).
  By its coder: the browser test passed in 10 runs (the four empty states and the invented archive,
  each with and without the program): every page at both widths has the strip and the list and no old
  top bar, no page is wider than the screen at the narrow width, a click on the list's Queue entry
  changes the place. **NOT verified by it: the light theme was never seen (headless Edge followed this
  PC's dark mode); the narrow screenshots do not show the true 390 px (the overflow check is the
  evidence); the pill with a live collector; the list at a real archive's size.**
- **My look (20:34): one screenshot of the Overview on the invented archive, dark, wide: the picture's
  frame is there** (the strip with the name and one pill, the list with Overview, Saved Messages per
  account, Library with its five views, Chats with a state under each name; the content to its
  right). Seen by me in it: the content's head still carries "Viewer: set its address" and the old run
  controls; two chats of one name in the list (the fixture's). The script has no HTML sink (looked:
  none of `innerHTML` and its kind), so a chat's name is always set as text.
- **WHAT HAPPENED ON THE BOARD WHILE THIS SESSION WAITED FOR ITS CODERS (19:56 to 20:33; read at 20:34:
  messages 175 to 183): the viewer track (B7, then B8) built ITS OWN list on the left in the new look
  and the one window, and they are MERGED (entry 29, the main head e9413e4e); G17 is merged
  (e78ef361); the integrator had the viewer make the launcher's three places for the one window as a
  lent commit (183), because my row was of 19:56 and two questions to pages (171 c, 178 c) stood
  unanswered: MY MISS: I did not read the board between 19:56 and 20:34.** The owner saw a look at
  20:10 and took it for the old version, because the one window opened on the app's pages, still in
  the old look: **W1 is exactly what is missing.** Open with the viewer: two lists now exist (the
  viewer's own in `internal/viewer`, and `internal/appshell` on the pages): one of them is to become
  the other's (the joint note says the package is shared): said on the board.
- 20:36: **the main head e9413e4e merged into `wip/pages-shell` by me (a judgement: two test files
  met as add/add, because the head holds G17 as one commit; the branch's versions taken after I had
  compared the head's two files with G17's own: equal): head 9d685be1, pushed.**
- 20:35: **W1's FULL RUNS ARE STARTED, ONCE, BY THE SCRIPT** (`run-listing.sh wt-pages-shell
  wip/pages-shell w1 "internal/appshell internal/server internal/collector/livepages"`: gofmt, vet for
  both systems, each package whole on Windows with the browser test not skipped; about 12 minutes; no
  race detector: the shell adds no goroutine). **NO INDEPENDENT REVIEW HAS BEEN MADE OF W1: under the
  owner's objective it is listed after the runs with that said plainly in its entry.**
- **G18's fix round: its coder has pushed 17d0bb2a ("no state the owner cannot see or end after a
  close") and has not handed back.** G19's fix round stays briefed and not started. G16 unread.
- 11-16 20:36: **G18's second round is back: `wip/pages-quit` 4b273cd0, pushed, the copy clean; it
  holds f1d7127b** (all three must-fixes: a person's close with nothing running ends the launcher; a
  close during a start is asked once the programs run; after the box's Quit the window comes back when
  the stop is not sent or not over in 5 s; and findings 4 to 9 and 11 to 13; 13 test functions added,
  none removed; three existing tests' expectations changed and said; two G11 tests that the first
  round's own changes had broken are mended; the real-windows look printed "ok" on the merged tree).
  Left on purpose: findings 10 and 14. NOT verified: the owner's screen and a real click; the 5 s
  path only with a stand-in collector. **NOT read by me yet. NOT LISTED: it waits for the viewer's lent
  commit in the launcher (the one window's start), which meets it in `start.go` and `present.go`;
  then ONE small round takes the head in and gives the one window `-tell-close`, the close's question
  and the launcher's page as a third address.** A trial merge with e9413e4e is clean today.
- **Board message 184** (to the viewer and the integrator: my miss of 19:56 to 20:34; yes to the
  viewer's lent commit; W1 in its runs; the two lists). **The row is rewritten whole.**
- **Running now:** W1's full runs (a script). No agent of this session runs.
- 11-16 20:42: **W1 IS LISTED, READY: entry "W1" at the end of `MERGE-QUEUE.md`** (`wip/pages-shell`
  9d685be1, holding e9413e4e). Its full runs ended 20:41, every line exit 0
  (`runs-pages-p6/w1-9d685be1.summary`): gofmt, vet of the three packages for both systems, the whole
  `internal/appshell`, the WHOLE `internal/server` 357 s with the browser test not skipped, the whole
  `livepages`. **The entry says plainly that no independent review was made** and what was never seen
  (the light theme, the pill with a live collector, the page opened as the owner opens it). Board
  message 187. Routine steps: the runs and the notes by scripts of mine, one call each; the merge of
  the head was a judgement (two files taken from the branch after a comparison).
- **Running now: nothing of this session.** **Next step in one line:** read the viewer's 186; when the
  viewer's lent launcher commit is on the head: G18's last small round (take the head in; the one
  window gets `-tell-close`, the close's question, the launcher's page as a third address), its full
  runs (`run-listing.sh wt-pages-quit wip/pages-quit g18 "internal/launcher cmd/tgarchive-open"
  "internal/server=Viewer|Settings|EmptyCatalogue"`), its entry; then W1's owed review and look.
- 11-16 21:19: **the integrator (I-5), to this session: THE OWNER, 21:18: "Merge the fixes. These are
  basic, and if ready should go. Especially stuff like G18. Need a way to quit the app..."** G18 is
  first and now. Found on the board and on disk at 21:19: **W1 IS MERGED (aa69cd81)**; the viewer's
  lent launcher commit is merged (9980a21f: the app starts as ONE window with the default settings;
  the owner's folder rebuilt from it at 21:16); one launcher test fails on the head since W1
  (`TestLauncherStyleMatchesAppTokens`: the launcher's own page was not brought to the new colours:
  W1's miss, mine to mend); usage was 95% of all models' week at 21:03. G18 meets the head in four
  launcher files.
- 21:20: **G18's THIRD AND LAST ROUND RUNS: `BRIEF-G18c-take-the-head.md`, a fresh Opus coder on
  `wip/pages-quit` from 4b273cd0:** the head 9980a21f merged in keeping both (the joined window and
  G18's handling of the window's ends); `-tell-close` in both forms of the window's line; the style
  test mended if it is minutes; the launcher's named tests; the real-windows look once.
- **My read of G18's second round, owed since 20:35 (the code lines of `closeask.go` and
  `present.go`'s difference, 21:22):** as the brief asked: the box's answer is tied to the run it
  asked about (a generation number), a box is ended with its run, a close with nothing running sends
  the launcher its own end, a close during a start is noted and asked when the programs are followed,
  the window is shown again after the box's Quit (on the pages when they answer), the restart count
  goes back after a window has run past its early time. Not judged by reading: whether the three
  signal channels can lose a signal (the tests of the round cover the paths; no second review pass).
- **Running now:** G18's coder. **Next step in one line:** at its hand-back: `bash
  runs-pages-p6/run-listing.sh wt-pages-quit wip/pages-quit g18 "internal/launcher cmd/tgarchive-open"
  "internal/server=Viewer|Settings|EmptyCatalogue"` (about 5 minutes), the entry "G18", the board.
- 11-16 21:30: **G18's third round is back: `wip/pages-quit` 72bf7ff9, pushed, the copy clean; it
  holds 9980a21f** (the merge kept both: `-tell-close` in the joined line and the bring-forward start;
  when joined the collector gets the head's `-viewer-url`, and the launcher's `/viewer` page only says
  the viewer is in the app's window; exit 7 falls back as the head does; the launcher's page brought to
  the app's new tokens: the style test passes; two tests added (`TestViewerPageJoined`,
  `TestRealJoinedWindow`), none removed; the real-windows look "ok": the one joined window 20 s, exit 4
  at a close message, the launcher quit from a stand-in box). One window test's log check failed once
  for its coder on a temporary folder's name and passed three times after: a flaky check, said.
- 21:33: **G18 IS LISTED, READY: entry "G18" at the end of `MERGE-QUEUE.md`.** Its full runs, once, by
  the script, 21:30 to 21:33, every line exit 0 (`runs-pages-p6/g18-72bf7ff9.summary`): gofmt, vet for
  both systems, the WHOLE `internal/launcher` 120 s, the whole opener, the server's Viewer, Settings and
  empty-catalogue tests by name (10 passed); a trial merge with c8669274 clean. NOT run: the whole
  `internal/server` on this head (said in the entry: the integrator's at the merge); no race detector
  (the Windows process tests cannot run under it here). The entry says plainly that rounds two and
  three were not looked at by a reviewer. Board message 194 (the number the script gave). Routine
  steps: the runs and the notes by scripts of mine.
- **Running now: nothing of this session.** **Next step in one line:** W1's owed independent review
  with a look in the real one window (empty and filled catalogue); then G19's fix round
  (`BRIEF-G19b-fixes.md`; it takes G18 in); usage permitting: the integrator's 193 says 95% at 21:03.
- 11-16 21:34: **G19's fix round RUNS (the integrator's word of 21:18: "G19 right after"): one fresh
  Opus coder on `wip/pages-folders` from a281c273, on `BRIEF-G19b-fixes.md` with its step 0 changed in
  the start message: it first merges G18's listed head (`wip/pages-quit` 72bf7ff9, which holds the
  main head 9980a21f with the one window and the new look) into the branch, keeping both pieces, its
  "Program" link moved into the shell's list; then the review's findings in order, the must-fix first,
  a push after each.** It is not a small round (the merge and six findings): it pushes as it goes so
  that whatever the usage allows is on `private`.
- **Running now:** that coder. **Next step in one line:** at its hand-back: read finding 1's path and
  the start rule of finding 3; the full runs
  (`run-listing.sh wt-pages-folders wip/pages-folders g19 "internal/launcher cmd/tgarchive-open" "internal/server=Program|Launcher|Settings|EmptyCatalogue|Shell internal/collector=LauncherURL"`,
  and the whole `internal/server` with the browser test if its part in the shell changed); the entry.

### STATE FOR A TAKE-OVER (P6, 11-16 21:36; this block replaces the one of 19:42)
Read `BOARD.md` (the Pages row; the integrator's messages 177, 183 and 193 and its direct word of
21:18 in the entry above), `DESIGN-ONE-WINDOW.md`, `DESIGN-ONE-WINDOW-HOW.md`, then this block.
1. **The owner, 21:18: "Merge the fixes. These are basic, and if ready should go. Especially stuff like
   G18. Need a way to quit the app..."** and 19:30: deliver what works in the new look.
2. **Merged: G15, G17, W1** (the app's pages in the new look; NO independent review was made of W1:
   owed, with a look in the real one window on an empty and a filled catalogue; the light theme and
   the pill with a live collector were never seen). **Listed, READY: G18** (`wip/pages-quit` 72bf7ff9).
3. **With an agent of session P6: G19's fix round** (`wip/pages-folders`; if P6 is gone the branch on
   `private` shows how far it came: the merge of G18 first, then one push per finding). After it: the
   line above. Its review: `REVIEW-G19-change-folders.md`.
4. **Handed back, unread, unreviewed: G16** (`wip/pages-cap` e0fe666c, the cap's Settings row; cut
   from 78739d59: it must take the head in; its Settings scripts meet the new frame).
5. **Owed, small:** G17's two test-only review findings (`REVIEW-G17-empty-catalogue.md`, 1 and 2);
   words of its own and another port for the window's exit code 7; the old run controls and "Viewer:
   set its address" in the content's head of the app's pages; the launcher's `/viewer` page in the
   joined case.
6. **Next after these, in this order:** the two lists made one (the viewer's own in `internal/viewer`
   and `internal/appshell`: board message 184 c); the Overview's numbers as links (W3); the copy
   checks' controls; the launcher's two flags for the owner's words; the page for adopting a chat.
7. **Tools (`runs-pages-p6`, not in git):** `run-listing.sh` (read its head; it holds the track's lock
   and frees it at its end), `go1.sh`, `notes.py`. **How the work goes:** read the board at every
   hand-back AND at least every 15 minutes while agents run (I did not from 19:56 to 20:34 and two
   questions to pages stood unanswered while the viewer and the integrator worked round them); a page
   is opened on an empty and a filled catalogue in a browser engine before it is listed; a piece that
   changes the app's tokens runs the launcher's style test too.
- 11-16 21:58: **G19's fix round is back: `wip/pages-folders` 1a498355, pushed, the copy clean** (G18's
  listed head merged in first, one conflict in `launcher.go`'s run loop, both kept; all seven findings,
  one commit each, each with a named test; 15 test functions added, none removed; "Program" as an entry
  at the foot of the shell's list when the launcher's address is known). **G18 IS MERGED (18c1e2c0,
  21:41).** No new message on the board for pages since 194 (looked 21:58).
- **My read (21:59): finding 1's path** (`folderSees` gives what the look saw; the form carries it with
  the yes; `yesCovers` at the save: a yes on "cannot be looked at" counts only while the save cannot
  look either; a yes on N things covers N or fewer).
- 21:59 to 22:07: **the full runs, once, by the script, on 1a498355: every line exit 0 but two:** the
  trial merge with 18c1e2c0 (two launcher files: the head holds G18 as one commit) and **the WHOLE
  `internal/server`: ONE test failed, `TestEmptyCatalogueRoutesListed`: the piece's new route
  `GET /api/program` was not in the list G17's guard keeps.** Mended by me (two edits in
  `empty_test.go`, each a named difference: the route in the list; its 404 without `-launcher-url`
  taken as its documented refusal); the empty-catalogue, shell and launcher-link tests by name pass.
  **The whole server was NOT run again** (the hour): said in the entry.
- 22:07: **the main head 18c1e2c0 merged into the branch by me** (a judgement: the two files taken from
  the branch after the head's were compared with G18's listed head: equal; then the merged tree's
  launcher, opener, server, appshell, collector and deploy trees compared with the tested branch's:
  equal): **head 32c5d12e, pushed.**
- 22:08: **G19 IS LISTED, READY: entry "G19" at the end of `MERGE-QUEUE.md`**; board message to the
  integrator and Core with the two things to weigh (the settings file's two new fields that an older
  build cannot read; the second round unreviewed and unseen in a browser).
- **Running now: nothing of this session.** **Next step in one line:** W1's owed independent review
  with a look at the app's pages in the real one window (empty and filled catalogue, both themes), if
  the usage allows; else the take-over block of 21:36 with these entries is the state.

Earlier rows, cut by P7
| Pages and chats: the app's own pages (Chats, Queue, Staging, Settings), the launcher and the folder, and what they set in the catalogue | **session P6** (pages; took the track over 11-16 17:56, started by the integrator at the owner's word; P5 and the sessions before it are retired: do not wait for them or message them); progress in `SESSION-PAGES-PROGRESS.md` under "SESSION P6" | `internal/server`, `internal/launcher`, `cmd/tgarchive-open`, `internal/actdoor`, `internal/collector/livepages`, `deploy/folder` (the folder's build script), and since 11-16 the new `internal/appshell` (the shell both servers are to share) | **11-16 22:08 (session P6). THE OWNER'S OBJECTIVE (19:30): "to actually deliver something, meaning the features that work with the much improved look". MERGED: G15 (2334c659), G17 (e78ef361), W1 (aa69cd81: the app's own pages in the new look; the new package `internal/appshell`; NO independent review was made of it: owed; the light theme and the pill with a live collector were never seen). THE OWNER, 21:18: "Merge the fixes ... Especially stuff like G18. Need a way to quit the app...": G18 IS MERGED (18c1e2c0: a way to quit the app: thank you). "G19" IS LISTED, READY since 22:08: `wip/pages-folders` 32c5d12e, holding 18c1e2c0 (`MERGE-QUEUE.md` entry "G19"): "Change the folders" on the launcher's page; the setup looks at each folder before it saves (numbers only) and asks a second yes that belongs to what the page showed; folders saved by an earlier build are looked at before any start; a "Program" entry in the list and a region on Settings; lent lines in the collector for `-launcher-url`. One independent review on its first round (1 must fix, 5 should fix: all in, with tests); the second round not reviewed; the whole launcher, opener and appshell ok; THE WHOLE SERVER FAILED ON ONE TEST OF ITS OWN NEW ROUTE, MENDED, NOT RUN WHOLE AGAIN (said in the entry); the settings file gains two fields an older build cannot read. Nobody has seen its pages in a browser engine since the second round.** **"G16" (the Settings row for the cap on new mirrors): handed back (`wip/pages-cap` e0fe666c), NOT read by me, NOT reviewed.** **THE ONE WINDOW (`DESIGN-ONE-WINDOW.md`, the joint note `DESIGN-ONE-WINDOW-HOW.md` by pages): the viewer's side is merged (entry 29); the launcher's start of it is the viewer's lent commit (yes from me, message 184). OPEN WITH THE VIEWER: two lists exist now (the viewer's own, and `internal/appshell` on the pages): making them one is the first piece after the delivery.** MY MISS, said on the board: I did not read the board from 19:56 to 20:34, and a fault of my own lock script held my coders for 14 minutes at 19:41. **STATE FOR A TAKE-OVER: the block of 21:36 at the end of `SESSION-PAGES-PROGRESS.md`.** NEXT, in this order: W1's owed review and look; the look at G19's pages; the two lists made one; the Overview's numbers as links (W3); G16's read and review; then the copy checks' controls, the launcher's two flags for the owner's words, the page for adopting a chat. Routine steps: by scripts in `runs-pages-p6` (`run-listing.sh`, `go1.sh`, `notes.py`), said in each entry. |



## SESSION P7 (took the track over 11-21 21:08, started by the integrator I-6 at the owner's word; P6 is retired)
Model rule since 11-21 (the owner): Opus, this session's own model, is the orchestrator; Fable only if
fully stuck, asked of the integrator on the board first. Coders Opus 5.5 at high effort. Routine steps
go to ONE Sonnet clerk call or a script of `runs-pages-p6`; each entry says which.
- 11-21 21:08: **taken over** from P6's block of 11-16 21:36 and the entries after it. Main head
  af4ca40 (G19 merged as 70b0c7e; the owner's folder is built from it and has been in use since 11-19
  00:30: never stopped, restarted or reconfigured by this track; a test window on the owner's screen is
  announced on the row first). **The order of work:** (1) W1's owed independent review and its fixes;
  (2) G18's and G19's unreviewed rounds; (3) G16 (`wip/pages-cap` e0fe666c) read, brought onto the
  head and reviewed; (4) the two lists made one, with the viewer (B9); (5) the Overview's numbers as
  links (W3). Doors to take when listed: the mirror's (M-7) single-post wait setting and block words;
  Core's (K-6) alerts. **Running now: nothing of this session.**
- 11-21 21:10: **three independent reviews running, Opus at high effort, read-only, in parallel**, each
  in its own scratch copy detached at af4ca40e, under one rules file `BRIEF-P7-review-rules.md` (no
  window on the owner's screen: headless only; every go command through `runs-pages-p6/go1.sh`, named
  tests only; nothing of the owner's program, settings or `E:`): **W1** (`BRIEF-P7-review-W1.md`, copy
  `wt-pages-review-w1-scratch`, report `REVIEW-W1-app-pages-look.md`); **G18's rounds 2 and 3**
  (`BRIEF-P7-review-G18bc.md`, `wt-pages-review-g18b-scratch`, `REVIEW-G18bc-quit-rounds.md`);
  **G19's fix round** (`BRIEF-P7-review-G19b.md`, `wt-pages-review-g19b-scratch`,
  `REVIEW-G19b-folders-fixes.md`). Free memory 9.5 GB, CPU 62% (other sessions) before the start.
  Routine steps: the three copies made by one command of mine (a single command). **Meanwhile:** G16
  read by me. **Next step in one line:** at each report, judge it and brief one fix round per piece on
  a fresh `wip/pages-*` branch from the head.
- 11-21 21:13: **G16 read by me** (`wip/pages-cap` e0fe666c, report `pages-cap-REPORT.md`): the cap's row
  takes its bounds from the door (min, max, "N or more" when max is not above min), so it fits M13 (the
  maximum becomes the account's 500 channels) with no change; a trial merge with af4ca40e is clean. **A
  Sonnet clerk merges the head into it, runs its named tests, gofmt and vet, and pushes** (one call).
  Its independent review is briefed when the clerk reports.
- 21:13: **the two lists:** the viewer's 204 (B9's coder builds "W1v": the viewer mounts
  `internal/appshell`, an additive lent commit in appshell: `Entry.Count`, `Options.Counts`,
  `Options.SkipChat`, `Options.NoCollector`, the viewer's places) crossed my 206; **204 accepted, 206
  withdrawn (message 207)**, with: Counts takes a context and never waits; the hidden chats differ between
  the servers until the marks are catalogue rows (to the viewer's "Listed and unbuilt"); the places'
  order; the W1 fixes that touch appshell named on the board before their coder starts. Core's 205
  (alerts, K22) read: nothing for pages before K22 is listed; asked for a cheap count of unseen alerts.
- 21:13: **W3 started: one Opus coder (high effort), `BRIEF-W3-overview-links.md`, copy
  `wt-pages-overview`, branch `wip/pages-overview` from af4ca40e:** every Overview number a link to its
  filtered place; filters by address on Queue, Chats and Mirrors with a removable chip; "Needs you" (held
  copies, mirrors waiting, chats joined and not collected, failed files) by measured cheap reads; no
  edit of appshell or the viewer. Free memory 8.0 GB, CPU 81% (other sessions) at its start; this
  track's go commands go one at a time through `go1.sh`.
- **Running now:** three reviewers (W1, G18 rounds 2 and 3, G19's fix round), the G16 clerk, the W3
  coder. **Next step in one line:** judge each report as it lands; brief the fix rounds; G16's review.
- 11-21 21:15: **G16 on the head: `wip/pages-cap` da8c1c3d, pushed, the copy clean.** The clerk's merge of
  af4ca40e was clean (de2045c9) but the server's tests did not build: the head's empty-catalogue stand-in
  door (`idleMirrors`, G17) lacks the cap's two methods; the clerk stopped there as told (no push). Mended
  by me (a judgement: what the stand-in should answer): the two methods, the default 20 as the collector
  gives it with nothing stored (da8c1c3d). Then gofmt, vet and the named server tests (cap, routes,
  guard, Settings, EmptyCatalogue) exit 0 (`runs-pages-p6/g16-merge-tests.txt`; one command of mine).
  Livepages and the collector's named tests: exit 0 by the clerk. **G16's independent review started**
  (`BRIEF-P7-review-G16.md`, Opus high, its own scratch copy; with a local trial merge of M13 to check the
  row with a maximum of 500), report `REVIEW-G16-cap-row.md`.
- 11-21 21:43: **the two lists: the viewer's W1v is back (`wip/b-onelist` 1e9da60e); its lent part in
  `internal/appshell` (eba58517, 091983ea) read by me: YES (message 221)**, with my 216's two changes in;
  one test of mine (`TestListProgramOnlyWithLauncher`) moved to the new foot order: confirmed; two small
  words noted, not holding it. A third lent commit comes (the pill's `[hidden]` rule, my defect; `List`
  degrading per part on an older catalogue): yes in advance, read when it comes. Messages 218 (copies:
  `copies.twin_hold` on by default; its Settings control's words "on unless you switch it off", doors
  C22's) and 219 (the client: the door's lines in `clicks.go` as a lent commit for me) read: both later
  pieces of mine, to "Listed and unbuilt" when their doors are merged. The integrator's word (21:18, the
  owner: the running app is no reason to hold a fix) answered in message 214: the folder's build script
  can target a second folder; four things to weigh before the switch. CPU 96% at 21:42 (four sessions
  and my five agents): no new agent of mine until one ends.
- **Running now:** the reviews of W1, G18 (rounds 2, 3), G19 (fix round), G16; W3's coder. **Next step
  in one line:** judge each report; W1's appshell fixes cut from the head after W1v, else from
  `wip/b-onelist`.
- 11-21 21:51: **G18's later rounds reviewed: `REVIEW-G18bc-quit-rounds.md`, 0 must fix, 4 should fix, 6
  minor.** My judgement: all ten are real and small; the signal paths were found sound (no lost signal, no
  second box, no blocking send). **Finding 4 touches the owner's window today:** the joined window starts
  without the folder's ffmpeg (no video thumbnails or conversion in the viewer inside it, unless the
  owner's settings name one): told to the integrator (message on the board). **Fix round G18d started:
  one Opus coder (high), `BRIEF-G18d-quit-fixes.md`, `wt-pages-quitfix`, `wip/pages-quitfix` from
  af4ca40e**, one commit per finding; finding 7 (in the viewer's `cmd/tgarchive-window`) as a lent commit
  for B9; 10 b (shared tokens' control borders) not in it. The G19 review's fixes will be given to the same
  coder (same package).
- 11-21 21:57: **W1 reviewed: `REVIEW-W1-app-pages-look.md`, 0 must fix, 4 should fix, 7 minor** (sound:
  injection, the routes' guard, `/api/shell` median 184 ms at 5,017 chats and 2 M messages on a covering
  index with no write held, the look at a true 390 px in both themes). My judgement: all eleven real;
  finding 2 is partly cured already by the viewer's lent 8673ec5c (an older catalogue drawn per part).
  **Fix round W1b started: one Opus coder (high), `BRIEF-W1b-shell-fixes.md`, `wt-pages-w1fix`,
  `wip/pages-w1fix` CUT FROM `wip/b-onelist` dad8caa1** (to be merged after W1v), appshell and server
  only. **Finding 4 (the launcher's window line) sent to G18d's coder as one more commit.** W3's coder
  works in `internal/server` too (the Overview): `main.js` may meet W1b's: the second to merge takes the
  other in. Board message to the viewer and the integrator.
- **Running now:** the reviews of G19 (fix round) and G16; the coders of W3, G18d, W1b. **Next step in one
  line:** G19's report to G18d's coder (same package); G16's report; W3's hand-back.
- 11-21 22:00: **G16 reviewed: `REVIEW-G16-cap-row.md`, 0 must fix, 2 should fix, 4 minor; with M13
  merged in trial its tests and M13's pass; the row at Max 500 right.** All six judged real (two are
  untrue words, the rest the row's small manners). **Fix round G16b: one Opus coder (high),
  `BRIEF-G16b-cap-fixes.md`, in the existing `wt-pages-cap`, on `wip/pages-cap`.** The per-account count
  (finding 1) is put to the mirror track in a board message (the words follow the code until it says
  otherwise); M13 best merged before or with G16. Core's 224 (K22's doors for alerts) read: the alerts
  page is briefed when K22 is listed (it is in its review; the PC is full: six agents of mine).
- **Running now:** the review of G19 (fix round); the coders of W3, G18d, W1b, G16b.
- 11-21 22:03: **W3 is back from its coder: `wip/pages-overview` c84c77ed, pushed, the copy clean**
  (2 commits, 16 files, `internal/server` only; report `pages-overview-REPORT.md` with a table of every
  number and its place). Built: every Overview number with a place is a link (the library's addresses and
  dead words read from the app's list itself, `/api/shell`); filters by address with a removable chip on
  the Queue (`show=waiting|now|failed|aside|held|gone`) and Chats (`read=`, `mirror=`, a new `waiting`);
  "Needs you" (held probable copies, mirrors blocked or waiting, chats joined and not added, failed files);
  one new read (`ListChatReads`, kept by the change key: 25.5 ms at 2,437 chats; the whole overview 34 ms);
  the browser test of 8 cases passes. **My read:** the held probable copies link to the viewer's Probable
  copies while the count is the catalogue's held files (a different rule, said in its table): put to the
  review. **Its independent review started** (`BRIEF-P7-review-W3.md`, Opus high, scratch copy
  `wt-pages-review-w3-scratch`, report `REVIEW-W3-overview-links.md`). Free memory 6.5 GB, CPU 88%.
- **Running now:** the reviews of G19 (fix round) and W3; the coders of G18d, W1b, G16b.
- 11-21 22:09: **G19's fix round reviewed: `REVIEW-G19b-folders-fixes.md`, 0 must fix, 3 should fix, 8
  minor.** The most serious: a yes given on "cannot be looked at now" is recorded by path only and kept for
  good (the owner's library is on the NAS over Wi-Fi, so a slow look at a cold start is the likely case);
  six rules of the round have no test that fails without them. **Given to G18d's coder (same package,
  same branch `wip/pages-quitfix`, after its own findings):** 1, 2, 4 to 10. **Not fixed, my decision:**
  3 (bump the settings file's version): the owner's build 70b0c7e already reads the new fields with
  version 1, and a version 2 would make going back to it refuse the file; an older build than 70b0c7e
  refuses it today (recorded); 11 (left as round 1 recorded them).
- **Running now:** the review of W3; the coders of G18d (now G18d plus G19c plus W1's 4), W1b, G16b.
- 11-21 22:18: **the integrator's piece, first in the order: THE OWNER'S UPDATE COMMAND (U1).** One
  PowerShell command by full path, after the owner quits the app: checks nothing runs from the folder;
  the catalogue (with -wal, -shm) set aside (the new build steps the schema, 26 to 28 now); the programs
  replaced as `make-folder.sh` does (earlier ones kept in `programs/<commit>/`; json, data, tools never
  touched; all or nothing); the app started; fixed words with the way back (a `-GoBack` form). The new
  build is the integrator's second folder `tgarchive-app-next` (built at 6aa225fb). **One Opus coder
  (high): `BRIEF-U1-update-command.md`, `wt-pages-update`, `wip/pages-update` from 6aa225fb**, tried on
  scratch folders under `Temp\p7-u1` built from af4ca40e and the branch, a stand-in for the app's start,
  never the owner's folder. The main head is now 6aa225fb (K21, C22, M6, M13 merged): G16b's coder told
  to take it in and make the "at 500" words true with M13.
- **Running now:** the review of W3; the coders of G18d (plus G19c and W1's 4), W1b, G16b, U1.
- 11-21 22:22: **W3 reviewed: `REVIEW-W3-overview-links.md`, 2 must fix, 2 should fix, 7 minor.** Must:
  "n held probable copies" counted every held file (27 shown, 9 of them probable on the invented
  archive) and opened a place that lists another set; the one new read is 180 to 236 ms with 20 reads
  under way at 5,017 chats (the coder measured with one: 25.5 ms), over the brief's 50 ms. Should: a live
  update could change what the focused link says and where Enter goes; "failed files" counted files set
  aside with nothing failed. All judged real. **Fix round W3b given to W3's own coder (resumed, it has
  the context), on `wip/pages-overview`, one commit per finding, then the head 6aa225fb merged in.**
- **Running now:** the coders of W3b, G18d (plus G19c and W1's 4), W1b, G16b, U1. No reviewer runs.
- 11-21 22:24: **G16b is back: `wip/pages-cap` 03e7b548, pushed, the copy clean; it holds the head
  6aa225fb (M13, M6) merged in clean.** All six findings, one commit each with its pinned test: "for each
  account" in the row and the cost; the first automatic run's numbers in place of "never ran"; the "at
  500" words true with M13 (no create sent at 500, the new ones wait); typing clears the answer line and
  Enter stores; "Not stored: " on every failure that is not the door's own refusal, digits only; the run's
  flag said as a sentence with the stored value. Named tests exit 0 by its coder (server, livepages,
  mirror, collector). **Its full runs, once, by the script** (`run-listing.sh`, one call):
  the whole `internal/server` and `internal/collector/livepages` on Windows with Edge set (the browser
  test not skipped), gofmt and vet, the collector's `PagesMirrors|MirrorDoorCap` by name; no race (no
  concurrent code changed); about 10 minutes.

## SESSION P7 entries, 11-21 22:27 to 11-22 08:34 (moved from the progress file by P7 at its stop)
- 22:27: the lean workflow (the owner, 22:20) applied: the progress file cut to this block, the row on the new board. The
  three fix rounds narrowed to the findings a person meets (G18d: G18 4, 2, 3, 1+6, W1's 4, G19's 1, 8; W1b: 1-3; W3b: 1-4, 8);
  the minor ones dropped and listed in their reports. Next: G16's queue entry when its runs pass; U1 first.
- 22:38: W1b back (`wip/pages-w1fix` eac935e6, after W1v); U-1 owns the front end now and agreed W1b, W3b, G16 are listed as
  they stand. New piece from the owner's item 44: the launcher's bring-in step (stop, dry-run counts, a yes, bring in, counts,
  start; DESIGN-UNIFIED-ARCHIVE §5): contract asked of B9 and Core by message; built after G18d lists (same files).
- 22:39: the bring-in step's contracts from B9 and Core saved in `CONTRACT-bringin-step.md` (the program's commands, @ lines,
  exit codes, done setting; the stop ends every reader too; Core's mark K24 must be installed first). U1's coder also adds
  tgarchive-bringin.exe to make-folder.sh. Next: the step's brief when G18d hands back (same launcher files).
- 22:43: G16 LISTED (b746ca3f; full runs: two failures, one test count mended, one Edge crash, both pass by name) and W1b
  LISTED after W1v (eac935e6). Running: U1 (first), G18d, W3b.
- 22:48: U-1 asked for F2's door: proposed (by message) the launcher starting the joined window viewer-first when the collector
  cannot start, plus a read-only `GET /api/state` on the launcher's page for the shell's notice; built after G18d, with the bring-in step.
- 22:52: W3 LISTED (b50584b0, the review's 1-4 and 8 fixed; held+failed read 218.5 ms at an inflated size: index asked of Core).
  Handed to U-1 (front end). Running: U1, G18d.
- 22:52: Core takes the held+failed counts into catalog.Totals' scan as K25 (after K18, K22-K24); W3 then reads two new Totals
  fields (names and times from K-6 when built). W3's statement stays meanwhile.
- 22:55: U1 BUILT and tried (`wip/pages-update` 0286f6e8; 68 pass on scratch folders); one independent review runs
  (`BRIEF-P7-review-U1.md`, report `REVIEW-U1-update-command.md`); listed after its must-fix. Integrator told the command.
- 22:56: G18d LISTED (d46aa8f6). Next: the bring-in step and U-1's F2 door, one coder, on top of G18d; U1's review runs.
- 22:57: L1 (the bring-in step + U-1's F2 door) with one Opus coder: `BRIEF-L1-bringin-step.md`, `wip/pages-bringin` from
  G18d d46aa8f6; the look lines as one lent commit for U-1. Running: L1's coder, U1's review.
- 23:07: U1 reviewed (`REVIEW-U1-update-command.md`, 1 must: -GoBack's copy onto the live name can be torn by a close; 3
  should; 5 minor): all nine to U1's own coder (U1b, same branch). Running: U1b, L1.
- 23:24: W1b now holds W1v 302fbd76 (merged by me, one test conflict: same fix both sides): 397b83a2, pushed, entry updated;
  B9's lent 6f92fbfd, 9c21d1be read: yes. Running: U1b, L1.
- 23:25: U-1's count door D1 with an Opus coder (`BRIEF-D1-overview-library-counts.md`, `wip/pages-libcounts` from W3): /api/overview
  `library` from the viewer's counts server-side, `mirrors_made_24h`; B9 asked for lib:new and lib:first. Running: U1b, L1, D1.
- 23:26: U1 LISTED (949982a2, all nine review findings fixed, 83 tries pass). Running: L1, D1.
- 23:28: G16 merged (head 09d63f94); the integrator's batch runs U1, G18d, W3, W1b with others. The queue's times corrected
  (they were typed, not from date: every time from date from now on). Running: L1, D1.
- 23:42: copies asks for a Settings control of `copies.twin_hold` (C26 makes it on by default; doors C22's TwinHold/SetTwinHold):
  the Go side (route, settings answer) mine, the drawing U-1's; to D1's coder after its hand-back.
- 23:43: D1 LISTED (674f1f1a, after W3). Next: the twin_hold control's Go side to D1's coder. Running: L1.
- 23:44: M-7 said yes to D1's mirror_made.go; small follow-up owed: `mirrors_made_24h` to say when the cap is the careful 5 (the
  stored cap unreadable). Coming doors from M14 (listed) and M15: held chats, set-aside messages, exact repeats, the single-post wait's
  row, forums' topic fields; "A forum is not mirrored yet" goes with M15. Running: L1, twin_hold (D1's coder).
- 23:48: T1 (the twin_hold control, Go side) LISTED (7a6e2699, after D1). Running: L1.
- 23:54: L1 BUILT (`wip/pages-bringin` 72117787; whole launcher ok); its one review runs (`REVIEW-L1-bringin-step.md`). Asked B9 for
  a read-only `state` command (without it the step stays not offered) and Core for K24's second-root writer; U-1 told the doors. T1 listed 92278937.
- 23:54: B9's `state` command and `-old-library` flag on plan/run come on wip/b-unified (contract updated); L1's fix round
  takes them in (pass -old-library to plan and run, -old to state). Running: L1's review.
- 23:59: U-1 asks the pages' /api/shell to carry the viewer's counts (via D1's reader): to D1's coder, `wip/pages-shellcounts` from T1.
- 00:06: S1 (the pages' list with the viewer's counts) LISTED (b7c7891e; holds W1b). Running: L1's review.
- 00:06: L1 reviewed (`REVIEW-L1-bringin-step.md`, 1 must: the yes not tied to the run's inputs; 3 should; 5 minor): all nine and the
  contract's state command and -old-library to L1's own coder (L1b). Running: L1b.
- 00:20: the integrator: the whole launcher hung 45 min once in TestWindowAskSecondStartShowsFirstsWindow under load. To G18d's coder:
  bound the test helpers' waits (30-60 s) and find the race (`wip/pages-testbounds`). U1 and G18d being merged. Running: L1b, testbounds.
- 00:37: U1 and G18d MERGED (head 09e7b5a7). L1b proved (finding 1's tests fail without the cure, the review's probe: no run); its merge of
  the head (4 conflicts: make-folder.sh, launcher.go, makefolder_test.go, present.go) with its coder, then listed. Running: L1 merge, testbounds.
- 00:46: L1 LISTED (b141da57, holds 09e7b5a7). testbounds' coder merging the head. Next: the mirror's and Core's doors when listed.
- 00:49: TB (launcher test bounds + the second start's look) LISTED (34800161). Nothing of pages runs now.
- 01:03: N4's pages side (Accounts and Settings for the NAS: where downloads run, the NAS address, pairing, the NAS's sign-in, forget,
  the no-VPN state; `NOTE-N4-collector-side.md`) taken after L1 and TB; door names asked of N-1 by message. Nothing runs.
- 01:04: N4P (the pages' Go side for the NAS: seam, routes, adapter, demo fake) with an Opus coder: `BRIEF-N4P-nas-pages.md`,
  `wip/pages-nas` from the head; against N-1's door contract (Core writes the doors). One review when back (it signs in).
- 01:08: U-1's F2 listed (holds L1). /api/state's why/action to say the cause: to L1's coder, `wip/pages-statewords` from L1.
  Running: N4P, statewords.
- 01:24: N4P built (`wip/pages-nas` acee74f9); its one review runs (`REVIEW-N4P-nas-pages.md`); the contract's NASSignIn lacks the phone:
  told N-1. Running: N4P review, statewords.
- 01:27: SW LISTED (55a381f0; holds L1; the causes in /api/state, the lock's spelling, old.root, B9's refusals). Running: N4P review.
- 01:27: owed after K24 is merged (Core's F9, minor): the server's sign-in door refuses a brought-in account in fixed words ("this
  is the old archive, it is never signed in"), by `Account.BroughtIn`/`Live()`; also Accounts' list marks it. Not started (K24 not on the head).
- 01:29: L2 (U-1's four launcher asks from F6 + two failing make-folder tests) with an Opus coder: `BRIEF-L2-launcher-asks.md`,
  `wip/pages-asks` on F6. B9 asked whether plan prints total.*. Running: L2, N4P review.
- 01:31: N4P reviewed (`REVIEW-N4P-nas-pages.md`, 0 must, 3 should: the no-VPN warning lost when the NAS is away, missing in the sign-in
  answers, a removed account's NAS login unreachable; 5 minor): all eight to N4P's coder (N4Pb); three contract asks to N-1. Running: N4Pb, L2.
- 01:34: the first real-window QA (`reports-qa/QA-6aa225fb.md`): the launcher's parts briefed as L3 (`BRIEF-L3-qa-launcher.md`: the start
  without the API file, three window restarts, a tray icon, a native Quit route, the setup's VPN preset, the folder box's owner, words, README,
  the exe's icon), to L2's coder after L2. U-1 told the split. Running: L2, N4Pb.
- 01:48: N4P LISTED (485ba7b3, all eight review findings fixed). Running: L2 (then L3 to the same coder).
- 01:48: N-1 writes the livepages wiring as a lent commit in N4's fix round (I read it); owed after N4 lists: NASState's Held and
  UnreachableSince in the answers, and a give-back route (NASGiveBack, the owner's click, warned: may download twice).
- 01:52: L2 LISTED (5923815a, after F6 and SW). L3 (the QA's launcher findings) to the same coder now.
- 01:53: the head squashed W3, D1+S1, T1, F3 (111a82f9). L2 built on F6 conflicts with the head outside its own change; told the integrator
  (merge after F6/ui-all, or I re-cut L2's own commits). L3 with L2's coder.
- 01:56: head e34f4f64: W3, D1, T1, S1, W1b merged (with W1v, F3, M14, M15, C25-C27). Next batch: ui-all, then L2, TB, L1/SW, N4P.
  Owed: the M14/M15 doors' Go side (held chats, set-aside, repeats, the single-post wait row, forum topics) for U-1. Running: L3.
- 01:56: MD (the mirror's M14/M15 doors on the pages, Go side: the single-post wait row, the new chat states, D1's careful flag) to
  G16's coder: `BRIEF-MD-mirror-doors.md`, `wip/pages-mirrordoors` from e34f4f64. Running: L3, MD.
- 02:25: the audit (AUDIT-INACTIVE-FEATURES.md): L4 briefed (`BRIEF-L4-launcher-defaults.md`: -pair-words on by default; links auto: on for a
  local library, off on a share; -no-links came from a3's NAS-share script) for L3's coder after L3. Rename/gather doors asked of M-7, the
  joined-chat downloads setting of Core (U-1's rows 87, 88). Running: L3, MD.
- 02:25: Core takes "downloads for a chat joined while away" as K28 (off default, unlimited, always; a read door that names the accepted
  values); its Settings route is mine when the doors exist. L4's brief corrected: an old -no-links is never stored as the owner's "off".
- 02:26: rename/gather: gather's pages door already exists (GET /api/mirrors/settings, POST /api/mirrors/gather): told U-1; rename's collector
  doors are M19 (M-7): its pages routes (rename-plan, rename) owed when M19 lists. Owed queue: K24's sign-in refusal, NAS give-back, K28's route,
  M19's routes, L4 after L3.
- 02:30: MD LISTED (fde6cc4d; lent lines in catalog/chatreads.go and collector/mirror_made.go: Core and M-7 told). Running: L3.
- 02:31: M-7 said yes to MD's lent mirror_made.go; ChatState.MadeAt comes in M17: pages' made_at (one line through livepages and the
  server) owed when M17 lists.
- 02:37: TestWindowNewPagesAddressRestarts fails 2/5 on the head (integrator): to TB's coder (`wip/pages-addrrestart`, head + TB). The mirrors
  count and /api/counts (loopback GET, no token) with MD's coder. Running: L3, mirrorcount, addrrestart.
- 02:53: CS (the copy checks' six settings, the exact check, maybe "Back up now") to T1's coder: `BRIEF-CS-copycheck-settings.md`,
  `wip/pages-copysettings`; backup door asked of Core. Running: L3, mirrorcount, addrrestart, CS.
- 02:53: "Back up now": no door; Core's K27 (BackupNow, BackupStatus, the backup's settings) after K22; pages' routes owed when K27 lists.
- 03:00: M19 (rename doors) listed by M-7: RN (`BRIEF-RN-mirror-rename.md`, `wip/pages-rename` from wip/mirror-renamedoor) queued for MD's coder
  after the mirrors count; one review after (it writes to Telegram).
- 03:00: AR LISTED (c178d8e4: the flaky window test's cause was the test; holds TB). Running: L3, mirrorcount then RN, CS.
- 03:08: L3 back (`wip/pages-qa1` f22ff85a) but the whole launcher is not green: stand-ins of other tests end with code 0 mid-test. Held, not
  listed; investigation to TB's coder (`wip/pages-crosskill`): suspect an end-all by process name not limited to the folder (a product hazard
  if so: Quit ending another folder's programs). Running: crosskill, mirrorcount/RN, CS, N4P merge.
- 03:09: N4P re-listed at a9c24248 (holds 32d48a4c; the named NAS, guard, security tests pass).
- 03:10: CS LISTED (2ee66e57). Running: crosskill, mirrorcount/RN.
- 03:12: CS HELD: copies found the exact check's words the opposite of the code (a three-places match LINKS and is not downloaded);
  corrected by CS's coder; the frame check's words made precise. Later with C29/C31: the fingerprints' library rate, defaults on.
- 03:30: CS re-listed READY (9fd132a9, the words corrected with copies' and pinned). Running: crosskill, mirrorcount/RN.
- 03:30: MC LISTED (b3330d26). RN built (`wip/pages-rename` 36e82316): its one review starts. Running: crosskill, RN review.
- 03:39: K22 listed (Core): AL (the alerts' pages doors and the unseen count) to CS's coder: `BRIEF-AL-alerts-pages.md`, `wip/pages-alerts` from
  wip/core-alerts. Later: the launcher's Windows notification for a new alert, with the tray (after crosskill/L3). Running: crosskill, RN review, AL.
- 03:39: QA-32d48a4c: launcher findings 1-3 are in held L3; owed after crosskill: the refused save's VPN error (4), the folder box's Cancel
  leaving "a folder box is open" for 90 s and losing the value (5). Count definitions sent to U-1 (files vs posts, held vs probable).
- 03:42: LC LISTED (b3160bb5: library copies and all). Running: crosskill, RN review, AL.
- 03:43: RN reviewed (`REVIEW-RN-mirror-rename.md`, 0 must, 2 should: a token usable again sends again; the "not recorded" end said as a
  generic failure; 3 minor): all five to RN's coder. Running: crosskill, AL, RN fixes.
- 03:48: owed after the batch (UI-2, MD, M19, C29, C31, AR, K18; about 50 min): merge the new head into N4P (security_test.go) and relist.
- 03:58: crosskill: the cause was the TESTS (a test's job nested in the window's kill-on-close job); the product's stops act only on held handles;
  two more test fixes; two whole launcher runs green (add8b775, holds L3). Next on it: QA-32d48a4c's folder-box Cancel and refused-save step, then
  the head after the batch; then L3 listed (via this branch).
- 03:59: AL LISTED (a2b6e93c, after K22). Owed one line: alerts in /api/counts once MC and AL are both on the head. Running: crosskill (QA 4/5, then
  the head), RN fixes.
- 04:04: RN LISTED (0a9674bf, all five review findings fixed; one-click tokens with a fresh nonce). MC updated (094e16e5). Running: crosskill.
- 04:37: head 4bf224b (MD, M19, AR merged; MC in the batch). Merges of the head into CS and AL (T1/CS's coder), LC and RN (MD's coder), N4P
  (its coder) running. crosskill (L3) running.
- 04:38: MC goes through UI-3 (the integrator's word); the MC rework cancelled. Running: CS+AL, LC+RN, N4P merges; crosskill.
- 04:40: N4P re-listed at 0d114096 (holds 4bf224b3).
- 04:44: LC (32a49b1d) and RN (a47f6b0f) re-listed on 4bf224b3. Running: CS+AL merges, crosskill.
- 04:45: CS (9e8bf0ff, C31's new defaults followed) and AL (0a161b24) re-listed on 4bf224b3. Running: crosskill only.
- 04:46: CS, LC, N4P, MC go THROUGH U-1's UI-3 (wip/ui-qa2), which did not hold my relisted heads: U-1 asked to merge 9e8bf0ff, 32a49b1d,
  0d114096. RN and AL with the UI batch after Core's (K22, K23, K26). Running: crosskill (L3).
- 04:47: N-1's lent livepages wiring 6cee4192 read: yes (N4P merges before N4). NG (the NAS state's last fields, give-back) to N4P's coder:
  `BRIEF-NG-nas-giveback.md`, from wip/nas-pcside; one review after. Running: crosskill, NG.
- 04:54: NG built (`wip/pages-nasgive` a43fbd91); its review runs (`REVIEW-NG-nas-giveback.md`; incl. whether a slow NAS can block the
  Overview). Running: crosskill, NG review.
- 04:56: UI-3 (wip/ui-qa2 92537b19) holds CS, LC, N4P and MC (checked). Running: crosskill, NG review.
- 05:05: owed when Core's K22b lists: the alerts-away routes (AlertAway, SetAlertResendHours, SetAlertSendsPerHour, SetAlertNames, SetAlertBotToken
  write-only never echoed or logged, FindAlertBotChat, ClearAlertBot, SetAlertSavedAccount, SendAlertTest(channel), AlertSendsOf, AlertSendHours,
  AlertBotActions, AlertBotStrangers), on AL's branch; and /api/act/state keeps made_by='alerts'. One review (it sends to Telegram).
- 05:06: BK (K28's joined-chat downloads setting and K27's backup + Back up now, two branches) to CS's coder: `BRIEF-BK-backup-newdl.md`.
  Running: crosskill, NG review, BK.
- 05:16: L3 LISTED via `wip/pages-crosskill` a99a3b74 (holds 4bf224b3; two whole launcher runs green; QA-32d48a4c's Cancel and refused-save
  fixed). Next for L4 (pair-words, links): to the same coder. Running: NG review, BK.
- 05:17: NG reviewed (`REVIEW-NG-nas-giveback.md`, 0 must, 3 should: a slow NAS stalls the Overview 10 s per account per poll; a removed
  account's give-back refused after a restart; a "pc" account read live; 3 minor): pages' parts to NG's coder; two door asks to N-1 (removed account,
  a link-free held read). Running: NG fixes, BK, L4.
- 05:19: ND (70e36ffd, after K28) and BK (60344917, after K27) LISTED. Running: NG fixes, L4.
- 05:19: U-1 asks a launcher route for the backup destination's folder box: POST /api/pick-folder: to L4's coder after L4 (same branch).
- 05:19: L3 conflicts with F13 only through its history (its own diff vs 4bf224b3 is launcher-only): when the batch lands, re-cut L3 as the
  new head + `git diff 4bf224b3 a99a3b74` (one apply), the whole launcher, relist. Same for L4.
- 05:23: owed small (with the L3 re-cut): the launcher passes `-staging <the app's staging folder>` to bring-in's run (B9, after K24).
- 05:37: L4 built (d141e2e0, + pick-folder). L3's entry withdrawn: L3+L4 re-cut as `wip/pages-launcher` on the next head (+ -staging) by their coder.
  Owner's line sent to the integrator. Running: NG fixes; the re-cut waits for the head.
- 05:48: owed (not urgent): a words pass, one short sentence each (U-1's F7 list): server copychecks.go 120-140, exactsetting.go 28-30,
  twinhold.go 34, nas.go 538, AlertRecordFailingWords; launcher words.go 70-98, 213. After CS, NG, AL, L3/L4 are on the head (one branch from it);
  copies' words kept true (exact check: a match is linked, not downloaded).
- 05:48: NG fixes back (f980c9da, all six, N4 merged in); held for one addition: a background refresh of the NAS brief (every 30 s, off
  the request path) so the Overview's NO VPN stays live. Running: that; the launcher re-cut waits for the head.
- 05:51: owed after K25 merges (Core, wip/core-needs 3cdc1713): overviewcache.go uses tot.HeldProbableOpen and tot.AsideFailed; drop needCountsSQL
  and needCounts (about 50 ms cheaper a reading). Into the words branch or its own small one.
- 05:55: NG LISTED (1c70a00d, after N4). Waiting: the integrator's next head for the launcher re-cut; then words, K25's swap, K22b's routes.
- 05:59: plan changed (integrator): U-1's F7 (wip/ui-words 9e51eeb1) holds L3 and replaces it; `wip/pages-launcher` = F7 + L4's own diff + -staging,
  merging after F7. With L3/L4's coder.
- 06:09: K22b listed: AW (alerts away: bot token write-only, test sends, settings, records) to AL's coder: `BRIEF-AW-alerts-away.md`; one
  review after. Running: AW, the launcher re-cut (L4 on F7).
- 06:12: PL LISTED (e5132818: L4 + pick-folder + -staging on F7). Withdrawn: L3 (in F7), L4's old branch. Running: AW.
- 06:18: AW built (`wip/pages-alertsaway` 0fabf04d; the token write-only, tested by grep); its review runs (`REVIEW-AW-alerts-away.md`).
  made_by belongs to the viewer's own click JSON: told B9.
- 06:27: AW reviewed (`REVIEW-AW-alerts-away.md`, 0 must, 2 should: no end time on a wait or the cap; a start link lost or dead without words;
  4 minor): all six to AW's coder; two facts asked of Core (the cap's next opening, the start's time). Running: AW fixes.
- 06:30: NG at b0c036e9 (grammar, unreachable_since in the brief); entry updated. Running: AW fixes.
- 06:36: AW LISTED (5a879e87, after K22b). Nothing of pages runs now. Owed: the words pass (after the branches merge), K25's swap, the alerts
  count in /api/counts (once MC and AL are on the head).
- 06:38: AW at 4c19675c (holds be291417 and K22b; AW's own 18 files beyond). Nothing of pages runs. Owed: the words pass, K25's swap, alerts in
  /api/counts, K24's sign-in refusal (when merged).
- 06:49: the alerts count in /api/counts is already on the head (UI-3 merged it). U-1's ask: "queue" in /api/counts: to MD's coder
  (`wip/pages-queuecount` from be291417).
- 06:51: QC LISTED (936f3500). Nothing of pages runs.
