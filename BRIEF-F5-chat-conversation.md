# Brief F5: a chat as a conversation (UI track, session U-1, 11-21)

You are an Opus coder for the UI track of a private Go project (a Telegram archiver; the app is a WebView2 window
over two local HTTP servers; the viewer, `internal/viewer`, serves the library and the chats read-only). Work ONLY in
your copy `C:\Users\trabi\Claude\Projects\Telegram\wt-ui-f5` (branch `wip/ui-chat`; the Go module is in `archiver/`).
Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `git push private wip/ui-chat` (never another
branch, never `main` or `origin`, no tag, no merge into another branch).

## Rules (binding)
The "Rules" section of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-F1-one-frame.md` binds you word for word
(invented data only; the owner's window is open: never a screen screenshot, never computer-use, pictures only with
`runs-ui-1\shot.ps1` of your own try window; Go through `ix-tools/env-archiver.sh`, one command at a time, named tests
only, no whole `internal/viewer`; nothing against Telegram; Windows paths only through Write/Edit). Read that section.
Another coder (F1, `wt-ui-f1`) is reshaping the left list and the top strip (`internal/appshell`, the viewer's
`shellmount.go`, `index.html`, `main.js`, and the "beside the app's one list" block at the end of `app.css`): do not
touch those; your files are the chat page's.

## Read first
`DESIGN-ONE-WINDOW.md` and `AUDIT-UI-1121.md` (point 7; picture `ui-audit-1121/4-chat-view.png`) in the project
folder, and the picture `design-options/app-look-options.html`, first button "The combination" (its chat). Then
`internal/viewer/web/js/chat.js`, `act.js`, `item.js` (what a post draws), the chat sections of `app.css` ("chat
conversation", "a chat as a client shows it", "the owner's clicks on a chat page"), and the chat routes in
`internal/viewer` that feed them.

## The goal: opening a chat looks and works like a messaging app
1. **Bubbles, not cards:** messages as bubbles, consecutive messages of one sender grouped (the name once, at the
   group's head, in a colour of its own per sender; times small at the bubble's foot); the account's own messages on
   the right in an accent colour; service messages as a centred line; date separators as now. Albums as one bubble
   with the pictures in a tight grid; a single picture or video fills the bubble's width (bounded); a file as a row
   with its icon, name and size; replies, edits, "also posted in" kept, styled small inside the bubble.
2. **The chat's head, fixed at the top of the content:** avatar, name, kind and a few words of state (members,
   messages, saved share as today), "Media only" and "Jump to month" as compact controls at its right, "Hide this
   chat" and "Changes in this chat" in a small menu. The "← Chats" back link goes (the list is always there).
3. **The text box at the foot, fixed**, when this viewer can act (act.js's door): one line growing to a few, the send
   button, the file button where act.js offers it; where it cannot act, the foot says in one quiet line why (e.g. "Read
   only: the collector is not running") instead of nothing.
4. **Scroll like a messenger:** opens at the newest message at the bottom, loads older ones on scrolling up without
   jumping; a "jump to newest" button appears when scrolled up. Keep the document as the one scroller if the viewer's
   rules need it (DESIGN-ONE-WINDOW-HOW.md section 9: never two inner scrolling boxes beside the list) and pin the head
   and the foot with `position: sticky`.
5. **Empty and odd states:** an empty chat, a chat never read, a chat no account reaches, Saved Messages not read yet:
   each one short sentence in the middle of the content, saying what to do.
6. Both themes (dark and light) and the narrow width keep working.

## Done means
- The viewer's named tests that look at the chat page's markup and routes pass (find them by name; add tests where a
  route or markup changed); `gofmt`, `go vet ./internal/viewer/` only if Go changed.
- Pictures (1280x860, invented archive) of your own try window or of the viewer alone in headless Edge: a group chat,
  a channel with albums, a person's chat with the account's own messages, the text box shown (act door) and the
  read-only foot, an empty chat; dark and one light. In `runs-ui-1/f5-pictures/`. Look at them beside the picture and
  say what differs. For a try window, `runs-ui-1/try-joined.sh` may exist from F1 by then; else start
  `tgarchive viewer -db <invented catalogue> -addr 127.0.0.1:18799` in the background and use headless Edge.
- Report back: the branch head, files touched, tests with times, the pictures, what is not done or not verified (under
  40 lines). Close your programs.
