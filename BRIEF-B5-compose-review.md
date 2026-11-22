# Review brief B5-A: an independent, read-only review of "the chat page acts, behind a seam"

You are an independent reviewer (Opus) with a security eye, for the viewer track of the new archiver. You
did not write this code and you owe its coder nothing. The piece: branch `wip/b-compose`, head 42a1df11, cut
from 5b29e28b, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-window` (Go module in `archiver/`;
the difference is `git diff 5b29e28b..HEAD`: `internal/viewer/act.go`, `act_test.go`, `web/js/act.js`, a few
lines of `viewer.go`, `server.go`, `api.js`, `chat.js`, `app.css`). What it was asked to do:
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-B5-compose.md` (read it in full first), on Core's design
`C:\Users\trabi\Claude\Projects\Telegram\DESIGN-CORE-client-actions.md` (sections 2 to 6).
Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash (Go is not on PATH).

**Why this deserves a hard look:** once Core's door exists behind the seam, a POST to these routes makes the
owner's real Telegram account send, edit, delete, forward or react. Today the seam is nil in both commands
and nothing can leave; review it as if the seam were live.

## How
- **Read-only on the copy and the branch:** change no tracked file, commit nothing, push nothing. Probes live
  in a new folder `C:\Users\trabi\Claude\Projects\Telegram\wt-b5-review-A-scratch` (lay a probe in with
  `go test -overlay`, or copy it into the package for one run and remove it; the copy must be clean when
  you end: say so).
- Read the brief, the design's sections, the whole difference, then the code around it as far as a doubt
  takes you: the viewer's `server.go` (`guard`, the page's token, Host and Origin), `access.go` and `lan.go`
  (the classes; who is "this PC"), `chat.go`, `live.go`, the index's posts and messages, the catalogue's
  `schema_act.go` (the ledger's rows, its fail-closed readers, `tgChatOf`) and the collector's entry points
  the seam is shaped on (`git show private/wip/core-turn:archiver/internal/collector/click_api.go`, read
  only).
- **Try to break it.** A finding is **confirmed** only with a probe that shows it or a line-by-line
  argument nobody could doubt; otherwise **plausible**, with what would settle it. Look hardest at:
  1. **Who can make a click happen.** Another device at home on the home-network listener in every class
     (read, mark, device), with and without a signed-in cookie; a web page open in the owner's browser on
     this PC (a form post, a fetch, an image tag, a wrong or missing token, a wrong Origin or Host, DNS
     rebinding, a simple content type); a page script of the viewer itself on another route; a GET that
     changes anything. The native window's own channel to the pages, if it has one.
  2. **One click, one request.** Can the page send the same click twice (Enter held or pressed twice, a
     double click, a button not disabled while its POST is in flight, a fetch retried after a network
     error or a timeout, the live poll or a re-render re-sending, a back or forward of the page, two tabs)?
     The door makes a new random id per queued click, so two POSTs are two messages. What does the page do
     when the answer never comes?
  3. **The right target.** Does each page id become exactly the message, chat, topic and account the owner
     sees? A "post" in the viewer can gather several messages: can a delete, a forward or an edit reach a
     message the owner was not shown in that post (the viewer's set rules, an album split by an edit, a
     post page against a chat page, a hidden chat or item, a message of another chat with the same number,
     a migrated group, a shared chat seen by two accounts, a basic group against a channel)? Is `actTgChat`
     the catalogue's own rule for every kind of chat (compare with `tgChatOf`, by a probe over each kind)?
     Edit and delete "own messages only": what decides "own" on the server side, as opposed to the page?
     A forward's destination: can it be a chat the account is not in, a mirror chat, a hidden chat?
  4. **Refused, never changed.** A text over the largest size, an empty text, odd text (lone surrogates,
     control characters, a NUL, 64 KB of combining marks, right-to-left overrides): refused or passed on
     byte for byte, never cut or altered; the UTF-16 count against Telegram's own way of counting.
  5. **The words.** Every string the routes answer, a page draws, a console prints or the counts file
     holds: a closed set, or text of the row shown as text. Can a click's text, Telegram's word, an account
     label or a chat name reach the page as HTML or script (`act.js`: every place a row's value is put
     into the page), a log line, an error or the counts file? An error of the seam: is its text ever
     written anywhere?
  6. **Cost and bounds.** The GET's cost on a chat with 10,000 clicks and on a chat of 100,000 posts; with
     the live poll's rate, is anything proportional to the chat or the archive per poll; the second
     read-only catalogue handle (when opened, when closed, what it holds); the per-chat memory of the
     30 s read-mark bound and of the remembered account; the forward chooser on 10,000 chats.
  7. **Nil is nothing.** With no seam: is anything of this piece reachable, drawn, asked or opened (the
     second catalogue handle, the new table in the viewer's decisions file, a request from the chat page)?
     Is the old archive's window byte for byte what it was for a page request?
  8. **The ledger's rows as drawn:** each state of the brief's point 3, a chain's tip only, rows of another
     account or chat, a row whose words are not known (the readers fail closed: what does the page then
     show, and can one bad row hide the compose box for good?), rows older than their text.
- **Privacy and load:** never start the owner's viewer, window, collector or old app; never open the owner's
  catalogues, library or any real media (nothing under
  `%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b`, `%LOCALAPPDATA%\tgarchive`,
  `E:\T`, the NAS); a viewer may be started only on a scratch folder of your own with invented files, and
  nothing may reach Telegram (nothing here can). `GOMAXPROCS=2`, `go test -p 1`, `GOGC=50`, named tests and
  your probes only, free memory checked first (wait while under 2 GB); no whole run of `internal/viewer`,
  no race detector; no Docker; never any cache clean-up or prune. Another coder works in the copy
  `wt-b-viewer`: do not touch it.

## Hand back, as your last message
Write `REVIEW.md` in your scratch folder (**no path of this PC in it**) and give its content: a verdict in
three lines; the findings worst first, each with: confirmed or plausible, the file and line, what happens
and to whom, the probe (its file in the scratch folder and what it printed), and the smallest fix you would
accept; then "Checked and sound", "The tests the hand-back leans on" (which of the coder's tests would still
pass with the defect present), "For the pass-through and Core's routes" (what this piece assumes of the
door that the door must then guarantee), and "Not run". No praise, no summary of what the code does.
