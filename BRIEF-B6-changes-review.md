# Review brief B6-C: an independent, read-only review of the "what changed" feed (the viewer's Changes page)

You are an independent reviewer (Opus) for the viewer track of the new archiver. You did not write this code
and you owe its coder nothing. The piece: branch `wip/b-changes`, head 9d24b538, cut from the main head
dbca91d4, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-faces` (Go module in `archiver/`). The
difference is `git diff dbca91d4 9d24b538` (only `internal/viewer`: new `changes.go`, `feed.go`,
`web/js/changes.js` and two test files; changed `refresh.go`, `index.go`, `deleted.go`, `server.go`,
`viewer.go`, `chat.js`, `main.js`, `index.html`, `app.css`; `web/js/deleted.js` removed). What it was asked to
do: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-B6-changes.md` (read it in full first). The lessons it must
keep: `C:\Users\trabi\Claude\Projects\Telegram\LESSONS-viewer-ix12.32.md` (sections 3, 4 and 6) and, in the
copy, `archiver/docs/LESSONS.md` section 1 and `archiver/docs/TRIED-BEFORE.md` sections 9 and 10.
Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash (Go is not on PATH).

**Why this deserves a hard look:** the piece changes the index writer (`refresh.go` `read` and `apply`), which
every page of the viewer depends on and which runs at every update while a collector writes. A wrong entry
there is a wrong page everywhere, and work per update that grows with the archive is the old viewer's
slowness again. The owner's archive: 584,000 messages, 65,000 with an edit date, 8 deleted, no earlier
version kept; a new account's catalogue gets deletions and earlier versions live.

## How
- **Read-only on the copy and the branch:** change no tracked file, commit nothing, push nothing. Probes live
  in a new folder `C:\Users\trabi\Claude\Projects\Telegram\wt-b6-review-C-scratch` (lay a probe in with
  `go test -overlay`; the copy must be clean when you end: say so).
- **Try to break it.** A finding is **confirmed** only with a probe that shows it or a line-by-line argument
  nobody could doubt; otherwise **plausible**, with what would settle it. Look hardest at:
  1. **The feed against a full read, after anything.** The coder compares the two over 60 random steps of
     new, edited, files-only-edited and deleted messages. Go further: a message that moves to another post
     (an album completed later, an album split, a set regrouped); a post whose lead message changes; a post
     that gains or loses its files (the "with media" class); a message edited twice in one update and across
     two; an edit and a deletion in one update; a deleted mark taken back; a version row removed; a message
     that leaves the index or a chat that is removed and inserted again (`INSERT OR REPLACE`, schema step 8's
     note); a catalogue stepped while the viewer runs; **a full read after incremental updates on the same
     writer, and an update that failed halfway** (the writer's own map `edits`: is it ever out of step with
     the index version that is served?); a catalogue with no change log.
  2. **Cost per update.** Every message the change log names with kind 2 (attachments, sightings) now gets a
     primary-key read with a join on `message_version` per update. With a collector writing (thousands of
     kind 2 rows per update at times), what does an update cost before and after this piece, in statements,
     rows and milliseconds, on an invented catalogue of 600,000 messages (the package's timing rig;
     `TGARCHIVE_VIEWER_CHANGES_N`)? An update with nothing new: before and after (the coder did not measure
     the base). The full read: before and after. A change of the feed now makes a new index version: what
     else rebuilds on a new version (library listings kept by version), and how often would an edit-heavy
     chat cause it?
  3. **Cost per page and per count.** A page merges lists of every chat that has changes: on 2,000 chats with
     changes; with 10,000 hidden posts and 200 hidden chats (the counts subtract them per request: how?);
     with one chat holding 60,000 bare edits; the tenth and the thousandth page. Is anything proportional
     to the archive, to a chat, or to the hidden items, per request?
  4. **The cursor.** No row twice and none skipped whose time did not change, with rows at one second across
     kinds and chats, a row that moves while the reader is between pages (to above and to below the cursor),
     a cursor from an older index version, a malformed or hostile cursor (huge numbers, signs, a kind that
     is not one), the old `/api/deleted` cursor format.
  5. **What the page says is true.** Each row's time is what its line says it is; the counts add up to what
     can be listed in every combination of the choices, with hidden chats and posts, in one chat, with
     media only; "N earlier versions"; the "before" and "now" texts belong to the right message and version
     (the latest earlier one), also for a message edited between the index's read and the page's read; an
     album with several edited messages; a message edited and then deleted; a deleted post that was hidden
     and is shown again.
  6. **One place.** `/deleted`, `/api/deleted` and the library's "Deleted on Telegram" switch: what each did
     before and does now (the coder changed `/api/deleted` to apply the hiding rules: who reads it?); the
     home-network listener's classes for the new routes, signed in and not; the native window's allowed
     addresses and its self-check (does anything there name `/deleted`?).
  7. **Words and markup.** A message's text, a chat's name, a version's text: put into the page as text only;
     nothing of a message in a log line, an error, or the counts file; the server's three error strings.
  8. **The tests the hand-back leans on.** Which of the defects you looked for would its tests still pass
     with? Do any of its tests judge real time? Does `TestTimingChangesAtSize` at its default size add much
     to the package's whole run (say the seconds)?
- **Privacy and load:** never start the owner's viewer, window, collector or old app; never open the owner's
  catalogues, library or any real media (nothing under
  `%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b`, `%LOCALAPPDATA%\tgarchive`,
  `C:\Users\trabi\tgarchive-app`, `E:\T`, the NAS); a viewer may be started only on a scratch folder of your
  own with invented files (`tgarchive fabricate -real-rows`). `GOMAXPROCS=2`, `go test -p 1`, `GOGC=50`,
  named tests and your probes only; before each go command check free memory and load
  (`powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`)
  and wait while free memory is under 2.5 GB or the CPU is over 85%; no whole run of `internal/viewer`, no
  race detector, no Docker, never any cache clean-up. Other copies (`wt-b-viewer`, `wt-b-join`,
  `wt-b-window`, any other track's) are other people's: do not touch them. Stop no process you did not
  start. Any file that holds a Windows path is written with the file-writing tool.

## Hand back, as your last message
Write `REVIEW.md` in your scratch folder (**no path of this PC in it**) and give its content: a verdict in
three lines; the findings worst first, each with: confirmed or plausible, the file and line, what happens
and to whom, the probe (its file in the scratch folder and what it printed), and the smallest fix you would
accept; then "Checked and sound", "The numbers" (every measurement, before and after), "The tests the
hand-back leans on", and "Not run". No praise, no summary of what the code does.
