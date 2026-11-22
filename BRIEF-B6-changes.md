# Brief B6-C: the "what changed" feed: deletions and edits, one page, newest first (viewer session B6, 11-16)

You are an Opus coder for the viewer track of the new archiver. Work only in the copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-b-faces` (Go module in `archiver/`). First, there: check the copy is
clean (`git status --short` prints nothing; if not, stop and say so), `git fetch private`, and cut the branch
`wip/b-changes` from `private/claude/charming-feynman-vm2xia` (the main head; write the exact commit into your
hand-back). Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash (Go is
not on PATH). **The routine-steps rule of this project (`CLAUDE.md`, the archiver section, second point) binds
you too:** you run named tests only; the whole runs and the race detector are not yours.

## Why, and what exists
A listed feature (`archiver/docs/ROADMAP.md`, the row `"What changed" feed`, E3; `FEATURES.md` section 10: "A
'what changed' feed: deletions, edits ... one page, newest first"), and one of the owner's stated aims for the
new app: automatic flagging of deleted items. The viewer is a reader: it opens the catalogue read-only and
sends nothing.

What the viewer has today (read these first, in full): `internal/viewer/deleted.go` and `web/js/deleted.js`
(the Deleted page: every post with a deleted mark, newest deletion first, a keyset page in a list the index
keeps, `ix.deleted`); `index.go` (`deletedAt` per message, `deleted` per post, the ordered list); `refresh.go`
(how a mark reaches the index in place through the change log, kind 4: a message's text, edit date or deleted
mark changed); `conv.go` and `live.go` (a chat page reads `edit_date` per page and the earlier versions of one
message through its own route; `message_version` with `replaced_at`, the second the change was seen). In the
catalogue: `internal/catalog/schema7.go` (the columns, the table, the change log's trigger) and `tgrows.go`
(where an earlier version is written: find out what is written in the same transaction as the message's
change, and say so).

**What the main session read and counted before this brief (build to it, do not rediscover it):**
- The old app has no such page; there is no number of its to beat. Its viewer was slow for reasons that are
  on record and bind this piece (`LESSONS-viewer-ix12.32.md`, `LESSONS.md` section 1, `TRIED-BEFORE.md` section
  9): **a warm index updated in place; nothing proportional to the archive per update, per click or per
  page; no request waits on the library; a page is cut by a stable key (a time and an id), never by
  position; grouping must keep the order the page relies on; show the age of what is shown.**
- `TRIED-BEFORE.md` section 10: one place for each control; every number says what it counts and adds up;
  every state says why in plain words.
- **Counted on the owner's brought-in old archive (read-only, numbers only, 11-16): 584,075 messages; 8 with
  a deleted mark (3 distinct times); 64,990 with an edit date (1,738 distinct days; 24,218 of them with an
  empty text); 0 earlier versions kept.** So on the old archive this page is 8 deletions and a very long
  list of edits that can show no "before": the page must not drown the first in the second. Its real use is
  the new accounts, where the live monitor writes deleted marks and earlier versions as they happen.

## What to build
1. **One page, "Changes"**, newest first, of two kinds of change, each drawn as the conversation draws a post
   (reuse what the Deleted page uses) with one plain line above it saying what changed and when:
   - **Deleted on Telegram**: as the Deleted page lists today (a post with a deleted mark; "all of it" or
     "part of it"), by when the app saw the deletion.
   - **Edited**: a message whose text or media changed. Where the catalogue keeps an earlier version: "Edited",
     with the text before and the text now, and the number of earlier versions when there are more (the
     chat page's existing route shows them all: link to it or reuse it, do not build a second one). Where
     it keeps none: "Edited (no earlier version is kept)".
   - **The time of a change is said for what it is**: a deletion's time is when the app saw it; an edit with an
     earlier version has the second the app saw the change (`replaced_at`); an edit without one has only
     Telegram's own edit time. Decide the one order that keeps the page truthful and stable (say what you
     chose and why), and let the line of each row say which kind of time it shows.
2. **What is shown by default, and the chips.** By default: deletions, and edits that have an earlier version.
   Chips, each with its count, each removable, as the library's chips are: the kind (deletions, edits); "also
   edits with no earlier version (N)"; one chat (the page can be opened for one chat from that chat's own
   page: "Changes in this chat"); "only with media". The viewer's hiding rules hold here exactly as on the
   Deleted page (a hidden chat or post is not listed; say how the count treats them, and make the counts add
   up to what the page can show).
3. **One place.** The Deleted page becomes this page with the kind set to deletions: its address keeps
   working (the page, its link in the navigation, the library's "Deleted on Telegram" switch and the
   `/api/deleted` answer that anything else reads: find every user and keep each working or move it, and
   list them). No second list of deletions anywhere.
4. **The index, kept warm and updated in place.** What the page needs is kept in the index beside
   `ix.deleted`, changed by an update only for the messages the change log names: the edited messages in the
   page's order, and whether each has an earlier version. Say what the full read gains (statements, rows,
   milliseconds at size) and what an update with nothing new costs before and after. Memory: say the bytes
   per edited message and the total at 600,000 messages with 65,000 edited. **A catalogue from before schema
   step 7, or stepped while the viewer runs, is followed as the Deleted page follows it** (no column: no
   changes of that kind, said in fixed words, never an SQL error on the page).
5. **The page's own cost.** A page of the feed is a keyset seek and one bounded read of the rows it draws
   (the "before" text of at most the rows on the page, one statement, bounded); nothing walks a chat or the
   archive; the counts on the chips come from the index, not from a count per request. The page is cut by a
   cursor that stays right when changes arrive between two pages (no row twice, none skipped: test it).
6. **Words.** Every new string in one place; a message's text is shown as text, never as markup; nothing of
   a message in a log line, an error or the counts file. The page says "as of" the index's time, as the
   other pages do (find how).

## Not in this piece
No request to Telegram, no write to the catalogue, no schema step, no `go.mod` change, nothing in
`internal/catalog`, `internal/collector`, `internal/server`, the commands, `internal/window`. No reactions, no
"what a service message says" (the catalogue does not record them). No change to the chat page's own
"edited" mark. The files `act*.go` and `web/js/act.js` do not exist on your base (another piece of this track
adds them): keep your changes to `server.go`, `api.go`, `viewer.go`, `web/js/api.js`, `web/js/chat.js`,
`web/js/main.js` and `web/app.css` to few, separate lines so that the two merge without work, and put new code
in new files.

## Tests (named)
- Each kind drawn from rows written through the catalogue's own doors on an invented catalogue (a deletion
  of a whole post and of part of an album; an edit with one, with several and with no earlier version; a
  message edited and then deleted: say what the page shows and why).
- The default view, each chip, the counts adding up, the hiding rules, one chat.
- The cursor: changes arriving between two pages (a new deletion, a new edit of a message already on page
  one, an edit of a message on page two): no row twice, none skipped.
- The index in place: after an update that names k messages, only those entries moved (count the work, do
  not time it); a full read and an incremental path give the same list (compare them over a random
  sequence of edits and deletions).
- At size, by the package's existing timing rig (`timing_test.go`: find how it grows an invented catalogue):
  600,000 messages with 65,000 edited and 2,000 deleted: the full read's added cost, an update with nothing
  new, a first page and a tenth page of the feed, in milliseconds; **a test must not judge real time** (it
  prints the numbers and bounds the work by counts).
- A catalogue from before step 7; the old addresses of the Deleted page.
- The existing tests of the Deleted page, `TestWall*` and `TestLAN*` still pass; on the home-network
  listener the new routes are of the reading class, as the Deleted page's.
- Before handing back: `git diff <your base> HEAD | grep '^-func Test'` must print nothing, or you account
  for each line.

## Rules (hard)
- Only `internal/viewer` (and its tests).
- **Privacy:** invented data only (`tgarchive fabricate -real-rows` makes an invented catalogue). Never open
  the owner's catalogues, library or any real media (nothing under
  `%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b`, `%LOCALAPPDATA%\tgarchive`,
  `C:\Users\trabi\tgarchive-app`, `E:\T`, the NAS); never start the collector, the old app, or a viewer or
  window on anything but a scratch folder of your own; stop no process you did not start.
- **Words:** new console lines pass the fixed-words filter (`viewer.LogWord`); no name, text, id, path or hash
  in a log line, an error or a test message built from real data.
- **Load (other work is going on this PC):** one go command at a time, `GOGC=50 GOMAXPROCS=2 go test -p 1 -run
  '<names>' ./internal/viewer`; before each go command
  `powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`
  and wait while free memory is under 2.5 GB or the CPU is over 85%. No whole run of `internal/viewer`, no
  race detector, no Docker, never any cache clean-up. Every wait in a test has a bound.
- Any file that holds a Windows path is written with the file-writing tool, never from inside a shell string.
- Other copies (`wt-b-viewer`, `wt-b-window`, any other track's) are not yours: do not touch them.
- Commit as you go on `wip/b-changes` and push only `git push private wip/b-changes` (never another branch,
  never `origin`; never merge into, rebase or switch another branch; never stash):
  `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no archive numbers in it (the counts above are
  for you, not for a commit message or a comment in the code).

## At the end, once
`gofmt -l` on what you touched; `go vet ./internal/viewer`; your named tests and
`go test ./internal/viewer -run 'TestWall|TestLAN|TestDeleted' -p 1`; `node --check` on each changed script;
`CGO_ENABLED=0 go build ./...`. Hand back, as your last message: the head (pushed) and its base; each of the
six points with any difference from this brief and its reason; the order you chose for the feed and why;
every user of the old Deleted page and what became of it; the numbers at size; every new string the page can
show; what you ran and what it printed; what you did NOT test (say whether the page was seen in a browser
and how); your doubts, plainly. Commit-ready, nothing left running, the copy clean.
