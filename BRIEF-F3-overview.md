# Brief F3: the Overview as the dashboard (UI track, session U-1, 11-21)

You are an Opus coder for the UI track of a private Go project (a Telegram archiver; the app is a WebView2 window
over two local HTTP servers: the collector's pages, `internal/server`, and the viewer, `internal/viewer`). Work ONLY
in your copy `C:\Users\trabi\Claude\Projects\Telegram\wt-ui-f3` (branch `wip/ui-overview`, cut from pages' W3 at
b50584b0; the Go module is in `archiver/`). Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com
commit`, each message ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only
`git push private wip/ui-overview` (never another branch, never `main` or `origin`, no tag, no merge into another
branch).

## Rules (binding)
The "Rules" section of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-F1-one-frame.md` binds you word for word
(invented data only; the owner's window is open: never a screen screenshot, never computer-use; Go through
`ix-tools/env-archiver.sh`, one command at a time, named tests only, never the whole `internal/server` or
`internal/collector`; nothing against Telegram; Windows paths only through Write/Edit). Read that section.
Other coders: F1 (`wt-ui-f1`) reshapes the left list and the top strip (`internal/appshell`, the pages' head bar in
`internal/server/web/index.html` and `internal/server/shell.go`); F5 the viewer's chat page. Do not touch those; your
files are the Overview's and the Queue's in `internal/server/web/assets` (js and css), and Go only where a route must.

## Read first
`DESIGN-ONE-WINDOW.md` (point 4: "C's dashboard as the Overview, and every number a link") and `AUDIT-UI-1121.md`
(point 4) in the project folder, and the picture `design-options/app-look-options.html`, first button "The
combination" (its Overview). Then W3's report and review (`REVIEW-W3-overview-links.md`, `BRIEF-W3-overview-links.md`)
and its files: `overview.js`, `places.js`, `keep.js`, `queue.js`, `chats.js`, `/api/overview` (`needs` and the
totals; `overviewneeds.go`). The viewer's filter addresses: `DESIGN-ONE-WINDOW-HOW.md` section 9, question 3.

## The goal: the Overview answers "is it working?" and "what needs me?" at a glance
1. **Now**, one block at the top: one sentence in plain words (collecting / waiting for Telegram's limit / stopped /
   not signed in, with the speed and how many wait), Start/Stop beside it, and the account(s) in a line each. No lane
   table, no "parts in flight", no server numbers here.
2. **Needs you**, next, only when something does: W3's `needs` (held probable copies, mirrors blocked, mirror wants
   waiting, chats not added, files that failed), each a row with its count and one word of what to do, the whole row
   a link to its place already filtered. When nothing needs the owner, one quiet line "Nothing needs you".
3. **The archive in numbers**: saved, new in the last 7 days, deleted on Telegram, first seen here, probable copies,
   still wanted; each a tile whose number is a link (library views on the viewer's address, the Queue's filters on
   the pages'). A number with no place to open is not a link.
4. **Today**: copied today, downloaded today, mirrors made against the cap, the last backup: one compact row.
5. The engineer's parts move, nothing is deleted: the lane table ("Right now" per server), the 48-hour chart and its
   hour table, "How much is left" go to the Queue page as its "Details" section (folded by default), and the Mirrors
   block's detail line ("read records ... could not be read") goes to the mirrors' place; the Overview keeps at most a
   one-line summary with a link.
6. Words: every block's title one or two words, at most one short line under it. The demo banner stays.
7. Both themes and the narrow width keep working; an empty catalogue shows the Overview's empty state (one sentence:
   add an account, then choose chats; a link to each).

## Done means
- The server's named tests for the Overview, the Queue and W3's needs (find them by name; adjust where markup moved);
  `go vet ./internal/server/` if Go changed; `gofmt -l`.
- Pictures (1400x900) by headless Edge of `tgarchive app -demo` on an invented archive (`tgarchive fabricate -db ...
  -library ... -files -reads -real-rows -chats 40`, LOCALAPPDATA/APPDATA/TEMP/TMP inside your try folder, programs
  started in the background with output to files): the Overview filled (dark and light), with nothing needing you, on
  an empty catalogue (`app` without `-demo` on a new file), and the Queue with its Details open. In
  `runs-ui-1/f3-pictures/`. Look at them beside the picture and say what differs.
- Report back: the branch head, files touched, tests with times, the pictures, what is not done or not verified (under
  40 lines). Close your programs.
