# Brief B5-C: a chat as a Telegram client shows it, reading only (viewer session B5, 11-15)

You are an Opus coder for the viewer track of the new archiver. Work only in the copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-b-viewer` (Go module in `archiver/`), on the branch
`wip/b-client` (already cut from 3244f0d: the main head plus the listed entry 19; clean).
Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash (Go is not on PATH).

## Why (the owner, 11-15 evening)
"Does the app also have an ability to be used like an actual telegram client, meaning interact with
chats/messages? That should be added as well if not already here." The order on record
(`repo-archiver/archiver/docs/FEATURES.md` section 12, sixteenth round: read it): first the conversation as
a client shows it, live, with no request to Telegram: this piece. Acting in a chat (send, reply, edit,
react) comes later, through the collector, by another track: **the viewer sends nothing, has no Telegram
code, and marks nothing as read anywhere.**

## What exists (read it before designing; do not rebuild it)
- `internal/viewer/chats.go` and `conv.go`: the Chats list by newest activity; a chat paged as a
  conversation with keyset cursors both ways (`before`, `after`, `around`, `at`), albums as one post, text,
  forwards and replies resolved; `web/js/chat.js` and `chats.js` draw them; a chat opens at its newest
  post. A chat page already carries: media only, topics, jump to a month, hide this chat, the deleted mark.
- The index (`refresh.go`, its head comment in full; `index.go`): kept current while the collector writes,
  at most every 2 s, reading only what is new plus what the catalogue's change log names (kind 4 of schema
  step 7: a message's text, edit date or deleted mark). A version has a number (`gen`). Requests never
  wait for an update.
- The catalogue's message row (`internal/catalog/schema7.go`): `edit_date`, `outgoing`, `service`,
  `deleted_at`, `reply_to`; earlier versions of an edited message in `message_version` (by message, with
  the text it had); the newest raw message in `message_raw` (the viewer cannot decode it: no Telegram
  code). **Reactions are not in the catalogue as rows or columns, and a service message's action is only in
  the raw bytes:** they are another track's to record (the main session lists them on the board); do not
  decode raw bytes, do not add a column.
- The old archive as brought in (`internal/bringin`) has no earlier versions (`plan.go`: "WANTED:
  message_version import") and may not fill `outgoing` or `edit_date`: read what it writes and say in the
  hand-back what an old chat's rows lack. Not this piece's to fix.

## What the old viewers taught (the numbers to stay inside)
- The old app's slow viewer rebuilt its whole model about once a minute while downloads wrote, and "Chats
  does not work at all" was the owner's verdict; its fixed version opened the largest chat (36,000 media
  messages) in 0.20 s and listed the chats in 0.04 s on an invented archive of the real size
  (`C:\Users\trabi\Claude\Projects\Telegram\LESSONS-viewer-ix12.32.md`: read it in full, and
  `repo-archiver/archiver/docs/TRIED-BEFORE.md` sections 9 and 10).
- The rules that follow, binding here: nothing proportional to the archive or to the chat per request or
  per poll; no poll may cause an index update or a database read when nothing changed; a browser has
  about six connections to a host, so a page keeps at most one live request going and never stacks them;
  no request waits on the library; every number says what it counts; this viewer's budget is 200 ms of
  server time for a page's request at the invented archive's real size (`timing_test.go`, `bigshape_test.go`).

## What to build
1. **Live while open.** While a chat page is on screen and showing the chat's newest end, new posts appear
   by themselves, in order, without moving what the reader is looking at: when the reader is at the
   bottom they are appended and the view follows; when scrolled up, a small "N new messages" pill appears
   and a click goes to them. Posts already on screen that are edited or deleted while shown change in
   place (the text, the "edited" mark, the deleted mark), and an album that gains a member is redrawn.
   - One route, cheap by construction: the page says which version it last saw and the newest cursor it
     shows; the server answers at once from the in-memory index: nothing new (no database touched), or
     the new posts after the cursor and the ids of shown-range posts that changed since that version. For
     "what changed since version G" keep, per index version, a bounded record of the posts the update
     touched (the refresher knows them: it re-reads them by key); when the record no longer reaches back
     to G the answer is "ask again from the start" and the page reloads its window. Design the details;
     keep the record bounded in memory whatever the collector writes.
   - The page asks every few seconds only while it is visible and the chat's newest end is loaded
     (`document.visibilityState`; the window counts as hidden when minimised), one request at a time, and
     backs off after a failure. Not a held-open connection: the home-network listener and its connection
     budget must stay as reviewed. A chat page that is not at the newest end asks nothing.
   - The Chats list moves a chat up when it gets a new message while the list is open (the same kind of
     cheap ask, the whole list at most every few seconds and only when the version moved).
2. **What a client shows that the page lacks:**
   - **Edited:** an "edited" mark with the time on a message whose `edit_date` is set; a click shows the
     earlier versions the catalogue has (`message_version`, read by the message's key through its index;
     text and time only), newest first, and says so plainly when it has none.
   - **Mine and theirs:** a message the account sent (`outgoing`) is drawn on the other side, as a client
     does, where the row says so; in a chat seen by more than one account, say whose.
   - **Service messages** (`service` = 1) as a centred quiet line "Service message" with its time (their
     action is not readable by the viewer yet); they must not look like an empty message.
   - **Replies:** the quoted line exists; make a click land on the replied message with a brief highlight
     and a "back to where I was" button, also when the target is outside the loaded window (the `around`
     cursor already does this: keep the reader's place to return to).
   - **Jump to newest:** a button that appears when the reader is away from the newest end.
   - **The Chats list as a client's:** under each title one line with the newest post's sender and the
     start of its text (or its kind: "photo", "video", "album of 4"), and its time; read for the whole
     list in one bounded query by the posts' keys, not one per chat, and cached per index version.
   - **Leave room for a compose box:** the layout keeps a fixed foot under the conversation, empty now, so
     a later piece adds it without moving anything. No disabled input, no "coming soon" text.
   - **Reactions:** nothing is drawn (not in the catalogue). Put one exported hook in the post's JSON
     shape only if it costs nothing; otherwise leave it.
3. **Access classes:** every new route is a read route (`access.go`); a home device gets the live asks the
   same way. No route of this piece changes anything.

## Bounds
- Only these: `internal/viewer`: `conv.go`, `chats.go`, `server.go` (routes), `index.go` and `refresh.go`
  for the bounded "touched posts" record and the edit date (the least that works; `refresh.go` is the
  viewer's most delicate file: the record must not change what an update reads or how versions share
  parts, and its random and merge tests (`refresh_random_test.go`, `refresh_merge_test.go`) must still
  pass by name), new files as you see fit, `web/js/chat.js`, `chats.js`, `dom.js` if needed, `web/app.css`.
  No schema step, no `go.mod` change, nothing in `internal/catalog` or any other package. Two other coders
  work in other copies: on the thumbnail makers (`maker.go`, `thumb.go`, the commands' flag lists) and on
  the window and the home listener (`internal/window`, `cmd/tgarchive-window`, `ffmpeg.go`, `lan.go`,
  `web/js/settings.js`, `lan.js`): keep out of those files.
- The import wall stays (`wall_test.go`): no Telegram code in the viewer.
- **Privacy:** invented data only, in tests, fixtures and anything you look at. Never start the owner's
  viewer or window, never open the owner's catalogue, library or any real media; nothing under
  `%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b` or `E:\T`. Message text, names
  and ids never in a log line, an error or the counts file (`stats.go`): the new route is counted like the
  others, numbers only.
- **Seeing the pages:** `internal/viewer/browsercheck` and the earlier rounds' way (a test viewer on an
  invented catalogue; the pages' own requests read, or a headless browser from `ix-tools/pw-browsers` if it
  is already set up; do not install anything). Check the live behaviour with a second connection that
  writes to the invented catalogue as the collector does (new message, edit, delete mark, an album's
  second member arriving later) and say what the page did. A fixture stores rows the way the real writer
  does (`internal/catalog/tgrows.go`, `ladder.go`), not by a shortcut insert that skips the change log.
- **Load:** `GOMAXPROCS=2`, `go test -p 1`, `GOGC=50`; before a test run check free memory
  (`powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB"`) and
  wait while under 2 GB. **Named tests only while working**; no whole run of `internal/viewer` (about 4.5
  minutes), no race detector: the main session runs both once. Tests must not judge real time (a poll's
  timer is injected or driven by the test); the one timing test you add or extend states its budget at the
  real size and runs alone.
- New tests, at least: nothing changed costs no database read (count the queries); a new post, an edit, a
  deletion and a late album member each reach the page's ask once and only once; the record's bound holds
  under a long run of writes and the "ask again from the start" answer is given past it; a poll for a
  chat does not see another chat's posts; a hidden chat and a topic filter behave as the first load does;
  the earlier versions of a message; the Chats list's line for a text, a photo and an album; the live ask
  at the real size inside the budget; the home listener's access class for each new route.
- Commit as you go on `wip/b-client` and push it to `private` (never another branch):
  `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## At the end, once
`gofmt -l` on what you touched; `go vet ./internal/viewer ./cmd/...`; your named tests and the refresh
tests named above; `CGO_ENABLED=0 go build ./...`. Hand back, as your last message: the commits (pushed) and
the head; the live route's contract in a few lines and what bounds its cost; what each part of 2 does; any
difference from this brief with the reason; what an old (brought-in) chat's rows lack for this page; what
you saw the pages do and how you saw it; what you ran and what it printed; what you did not test; doubts.
Commit-ready, nothing left running, the copy clean.
