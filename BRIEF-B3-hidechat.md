# Brief B3-17: hide a junk chat from where the owner is looking at it (session B3, 11-15)

You are an Opus coder. Work only in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-viewer`. First:
`git fetch private wip/b-review2fix && git checkout -B wip/b-hidechat private/wip/b-review2fix` (86a397d). Go
module: `archiver/`. Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in each
Bash call. Package: `archiver/internal/viewer` only (Go and `web/`). Commit as you go and push to `private`
as `wip/b-hidechat` (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; no archive numbers).

## What the owner said (11-15, after opening the viewer for the first time)
"Some groups seem kinda junk, so an option to hide them (from the actual chat page) would be good", with a
picture of one chat's own page (its header line: kind, account, messages, files, share saved; "Media only",
the topics menu, "Jump to month"), and then: "From the channel page rather."
The main session's reading: the owner is on a chat's (channel's) own page, sees it is junk, and wants to
hide it right there; and a hidden chat should then be gone from the Chats list too, not only from the
library. Build both; the hand-back says so, so the owner can correct the reading.

## What exists (read first)
Hiding a chat exists: `POST /api/hide` with kind `chat` (`api.go`, `decisions.go`, `marks.go`: the owner's
marks by stable key, surviving a fresh bring-in), a hidden chat's posts leave the library, the library's
chip "Hidden chats: N" opens a list with "Show again", and the Chats page and the library's sidebar have a
three-way menu per chat (show all / hide clutter / hide all). `chats.go` (`/api/chats`, `/api/chat/{id}`),
`web/js/chats.js`, `chat.js`. Every route carries an access class (`access.go`); hiding is `classMark`.

## What to build
1. **On a chat's own page** (`chat.js`, the header the picture shows): a button "Hide this chat" at the end
   of the header line; after it the page says, in place: "Hidden: its posts are left out of the library and
   it is left out of the chat list. Show again", and stays open (the owner may still read it). A hidden
   chat opened by its address shows that line and a "Show again" button. On a device that may not mark
   (the home-network listener with the owner's switch off) neither button is drawn.
2. **The Chats list** (`chats.js`): hidden chats are not listed. Under the list's heading: "N hidden: show"
   which lists them greyed below the others with "Show again" on each row, and "hide" again collapses them;
   the choice is not remembered (hidden means out of sight by default). The row's existing three-way menu
   keeps "hide all" as the same action. The counts in the page's heading say what they count ("212 chats,
   12 hidden").
3. **Everywhere a chat is offered to choose** (the library sidebar's chat list, the Overlap page's rows and
   pair lists, the "Also in…" select, search results' chat names): hidden chats are left out the same way,
   with the page's existing "hidden chats" chip or note as the way back. The Overlap page already says when
   chats are hidden: keep its arithmetic as it is.
4. **Several at once:** on the Chats list a checkbox per row appears after "Select", with "Hide the N
   chosen": one request per chat through the existing route (no new bulk route), each failure said.
5. Nothing is deleted and nothing in the catalogue changes: hiding is the viewer's own mark, undone by "Show
   again" or "Show all again".

## Tests (named, while working)
`/api/chats` leaves hidden chats out unless asked (`hidden=1` or the existing way) and its counts add up;
`/api/chat/{id}` says a chat is hidden; the pages draw no hide control for a device that may not mark (the
script-reading test `TestLANPageDrawsNoRefusedControls` covers any script that posts `/api/hide`: keep it
passing, extend it if a new script posts it); hidden chats are absent from the sidebar's list and the
Overlap rows. Then once at the end: `go test ./internal/viewer -p 1` (about 3.5 minutes, in the background),
`gofmt -l`, `go vet ./internal/viewer`; the scripts parse as modules (`TestPageScriptsParseAsModules`; `node
--check FILE` alone proves nothing for a script with imports). No race detector, no mutation checks, one go
command at a time.

## Rules
- Never open the viewer on real data or any real file; nothing against Telegram; do not touch
  `repo-archiver`, other `wt-*` folders or other packages. Do not merge into or push
  `claude/charming-feynman-vm2xia` or any other `wip/b-*` branch.
- Another coder works on `wip/b-ffmpeg` (`ffmpeg.go`, `maker.go`, `media.go`, `stats.go`, `web/js/dom.js`,
  `about.js`, `settings.js`): stay out of those files where you can.
- CSS in one block at the end of `web/app.css`.

## Hand back (short)
Commits, the reading of the owner's words as built, differences from this brief and why, named tests,
whole-package time and result, doubts.
