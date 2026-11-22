# Brief B5-A: the chat page acts (the compose box, the buttons, a click's place in the conversation), behind a seam (viewer session B5, 11-16)

You are an Opus coder for the viewer track of the new archiver. Work only in the copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-b-window` (Go module in `archiver/`). First, there: check the
copy is clean, `git fetch private`, and cut the branch `wip/b-compose` from
`private/claude/charming-feynman-vm2xia` (the main head, 5b29e28b or newer). If the copy is not clean, stop
and say so.
Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash (Go is not on PATH).

## Why, and what exists
The owner asked for the app to be used like a Telegram client (FEATURES section 12, sixteenth round). The
reading side is merged: the chat page (`internal/viewer`: `chat.go`, `live.go`, `web/js/chat.js`) opens at
the newest message and stays live. The acting side is Core's design, **read it in full first**:
`C:\Users\trabi\Claude\Projects\Telegram\DESIGN-CORE-client-actions.md` (sections 2 to 6 and 8). In short:
the viewer has no Telegram code and keeps none; every request is the collector's. A click is written to a
ledger in the catalogue before it is sent (`c_act`, schema step 21, **merged**:
`internal/catalog/schema_act.go`: read its head comment, `ActClick`, the state words `Act...`, the "why"
words `ActWhy...`, the read doors `ChatClicks` and `Click`), sent in the account's own loop, and its
outcome written to the row. The collector's entry points for a click exist on a branch that is reviewed and
about to be listed (`private/wip/core-turn`, `archiver/internal/collector/click_api.go`: `ClickInput`,
`QueueClick`, `CancelClick`, `SendClickAgain`, `ClickVerdict`, `ReadClickSettings`, and the errors at its
top; read it with `git show private/wip/core-turn:archiver/internal/collector/click_api.go`; do not merge
that branch). **What does not exist yet:** the routes on the collector's listener and the viewer's
pass-through to them (Core's piece 3). So this piece builds everything of the viewer's side **against a
seam**, with a fake behind it in tests; the pass-through is a later, small piece.

Board messages that hold the states and words (in `C:\Users\trabi\Claude\Projects\Telegram\BOARD.md`, the
numbered messages 67 and 76, "Viewer (B5)" parts): read both.

## What to build
1. **The seam** (`internal/viewer/act.go`): `Config.Act`, an interface the viewer calls for the owner's
   clicks, shaped on the collector's entry points with the catalogue's numbers (the viewer's chat ids and
   Telegram's message ids are what the page has: say how each of the page's ids becomes what `ClickInput`
   takes): queue a click (kind, chat, the fields of its kind; returns the click's number), cancel a queued
   one, send again (with "try again" over a remembered refusal), the owner's verdict on a "not known" one
   (arrived, leave it), and what the page must know before a click: whether this account can write now and,
   if not, why in a **closed set of words** (not running, not signed in, frozen, writes stopped for the
   account, a mirror chat, clicks off for this run), the largest text (a number from the door: a longer
   text is refused, never cut), whether "mark as read" is on. A "no" of the door comes back as a typed
   refusal: a word of a closed set, plus a time where it has one (the cap opens at, a wait ends at). **`nil`
   means this viewer cannot act:** no compose box, no buttons, nothing in the page hints at them (the old
   archive's window is this case, and stays exactly as it is now: test it).
2. **The routes, on this PC's listener only.** `POST` routes for the four actions and one `GET` for a
   chat's clicks and its "can write" state. Every one refuses any home-network class (`access.go`, `lan.go`:
   a new closed word in `LANRefusalWords` if one is needed) and passes the same checks the viewer's other
   state-changing routes pass (find them: the hidden items, the verdicts, Settings; `server.go` `guard`);
   a body is bounded; an id or a kind that is not the page's own is refused in fixed words; an error of the
   seam is never printed back as text: only its word. **Which account acts:** a chat seen by one signed-in
   account acts as that one; a chat seen by several lets the page choose among them (their names as the
   Accounts data already gives them) and remembers the choice per chat in the viewer's own state; none: no
   compose box.
3. **A click's place in the conversation.** The chat page shows the chain tips of the chat's clicks that are
   not finished or finished badly, at the conversation's end (a send, a forward) or on the message they
   act on (an edit, a delete, a reaction), each in fixed words from its state:
   - queued and sending: "Sending" (a queued one has "Cancel");
   - waited: the text kept, "Telegram asks to wait until HH:MM", "Send again" (the owner's click, enabled
     when the time is reached; a countdown is fine, no request is made by it);
   - refused by the chat: Telegram's own word as the row holds it (`TgType`), and "Try again" where the
     row says the refusal is remembered;
   - account refused: "Writing is stopped for this account"; frozen; signed out;
   - not sent: its "why" word as it is (they are the catalogue's fixed words), for the cap with the time;
   - not known: "It may have been sent", with "It is in the chat" where the live page shows a message of
     the account's own after the click with the same text and reply target (the design's section 5; the
     match is the page's hint only, the verdict is the owner's click), "Send again", "Leave it";
   - sent before (a forward of several): "At least one arrived earlier; look in the chat";
   - done, not modified, arrived, left: nothing drawn (the message itself arrives through the live page).
   The rows are read from the catalogue's own door (`ChatClicks`, read-only; the viewer already opens the
   catalogue with `catalog.Open(path, true)`), bounded (the newest 50 tips of the chat), asked with the
   page's live poll and not more often, never proportional to the chat. A click's text is personal
   content: it goes to this PC's page only, never to a log, an error or the counts file.
4. **The compose box and the buttons** (`web/js/chat.js` and its styles; plain script as the page is now, no
   new library): a text box at the foot of the chat (Enter sends, Shift+Enter a new line; a counter once
   near the largest text; a chip "Replying to ..." with a way out); on a message: Reply, React (a small
   fixed row of plain emoji and "take back"), Forward (a chooser of the destination among the account's
   chats, a mirror chat never offered; an album goes whole), and on the account's own messages Edit (the
   box takes the text; "Save") and Delete (asks once more; "for everyone" or "only for me" where both
   exist: a private chat or a small group, by the design's section 2). In a forum: the topic the page
   shows is the topic sent to. In place of the box, one fixed line when the account cannot write (the
   closed words of point 1); in a mirror chat no box and no buttons. A click never waits on the library and
   the page stays usable while one is sending (several may be). After a send the page goes to the newest
   message. **"Mark as read":** only when the seam says it is on: opening a chat at its newest message asks
   once, at most once per chat in 30 s, never from a background tab.
5. **Nothing here sends anything.** With the fake seam in tests and `nil` in both commands
   (`cmd/tgarchive/viewer.go`, `cmd/tgarchive-window/main.go` are **not** changed by this piece), no click
   can leave the program. Say so in the hand-back and show the test that proves `nil` draws nothing.

## Bounds
- Only `internal/viewer` (and its tests). No schema step, no `go.mod` change, nothing in `internal/catalog`,
  `internal/collector`, `internal/server`, the commands or `internal/window`. The wall tests stay as they
  are: no new import, no dial, no outbound connection (the pass-through is not this piece).
- **Privacy, hard:** invented data only (`tgarchive fabricate -real-rows` makes an invented catalogue with
  chats, names and a live token; clicks' rows are written in the tests through the catalogue's own doors on
  a writable invented catalogue). Never open the owner's catalogues, library or any real media (nothing
  under `%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b`, `%LOCALAPPDATA%\tgarchive`,
  `E:\T`, the NAS); never start the collector, the old app, or a viewer or window on anything but a scratch
  folder of your own. Nothing in this piece may reach Telegram, and nothing does: there is no path to it.
- **Words:** every string a page, a console or the counts file can show from this piece is one of a closed
  set written in one place; new console lines pass the fixed-words filter (`viewer.LogWord`); no name,
  text, id, path or hash in a log line, an error or a test message built from real data.
- **Load:** `GOMAXPROCS=2`, `go test -p 1`, `GOGC=50`; before a test run check free memory
  (`powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB"`) and
  wait while under 2 GB. **Named tests only** (`-run`); no whole run of `internal/viewer`, no race detector,
  no Docker, never any cache clean-up or prune. Tests do not judge real time.
- Another piece of this track (`wip/b-staged`, in another copy) changes a few lines of `chat.js`, `item.js`
  and `media.go` at the same time: keep your changes to existing lines small and put new code in new
  files or new functions where you can, so that the two merge without work.
- New tests, at least: `nil` seam: no box, no buttons, every route answers "not here" in fixed words; each
  route refused for every home-network class and without the page's token; each state of point 3 drawn
  from a ledger row written through the catalogue's doors, and nothing drawn for the finished ones; a
  chain shows only its tip; the text over the largest size refused, not cut; the account chooser with two
  accounts and its remembered choice; a mirror chat; a frozen account; the seam's refusal words reach the
  page as words; the clicks' read is bounded on a chat with 10,000 clicks; no click text in any printed
  line or in the counts file; the "mark as read" ask at most once per chat in 30 s (a clock handed in).
- Commit as you go on `wip/b-compose` and push it to `private` (never another branch, never `origin`):
  `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no archive numbers in it. A scratch folder of
  your own with a unique name, removed at the end.

## At the end, once
`gofmt -l` on what you touched; `go vet ./internal/viewer`; your named tests and
`go test ./internal/viewer -run 'TestWall|TestLAN' -p 1`; `CGO_ENABLED=0 go build ./...`. Hand back, as your
last message: the commits (pushed) and the head; **the seam as built** (the interface, its types, the closed
sets of words: this is what Core's routes and the pass-through will be written to); the routes with their
checks; how each page id becomes a `ClickInput` field; each of the five points with any difference from this
brief and its reason; every string the page can show; what you ran and what it printed (numbers); what you
did not test (the page was not seen in a browser unless you say how); doubts. Commit-ready, nothing left
running, the copy clean.
