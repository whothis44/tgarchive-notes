# Brief F4: the library (UI track, session U-1, 11-22)

You are an Opus coder for the UI track of a private Go project (a Telegram archiver; the app is a WebView2 window over
two local HTTP servers; the viewer, `internal/viewer`, serves the library read-only). Work ONLY in your copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-ui-f4` (branch `wip/ui-library`, cut from F1's `wip/ui-frame` 1d0e376e; the
Go module is in `archiver/`). Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each
message ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `git push private
wip/ui-library` (never another branch, never `main` or `origin`, no tag, no merge into another branch).

## Rules (binding)
The "Rules" section of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-F1-one-frame.md` binds you word for word (invented
data only; the owner's real window is open: never a screen screenshot, never computer-use, pictures only of your own try
window with `runs-ui-1\shot.ps1` or headless Edge; Go through `ix-tools/env-archiver.sh`, one command at a time, named
tests only, never the whole `internal/viewer`; nothing against Telegram). Your files: the viewer's library
(`web/js/library.js`, `item.js` where a tile or the post view draws, the library sections of `web/app.css`, and the
viewer's Go only where a route must). Not yours: `internal/appshell`, the chat page (`chat.js`, F5's), the pages.

## Read first
`DESIGN-ONE-WINDOW.md` (point 3: "B's library views and toggles": the grid by day, the Photos / Videos / Files toggle,
the chips that exist today, a details panel for the selected item: where it came from, first seen, also in which chats,
whether Telegram still has it, its copies), `AUDIT-UI-1121.md` (point 5: three columns that scroll on their own; the
types both in the list and in the filters), the picture `design-options/app-look-options.html` (button "B · Like a
photo library" shows the toggle and the details panel; "The combination" the frame), the pictures of F1 in
`runs-ui-1/f1-pictures/` (1-library.png is today's state), and `NOTE-UI-oldnew-contract.md` (the old-or-new data).
`runs-ui-1/try-joined.sh` (F1's) builds and starts an invented try window; `f1-size.ps1`, `f1-expand.ps1` help.

## The goal
1. **One scroll, no filter column:** the 270 px filter column goes. Over the grid, a head row (sticky): the view's name
   and count, the Photos / Videos / Files / All toggle (segmented), the sort, and a "Filters" button that opens a panel
   (a popover or a drawer over the grid, not a column) holding every filter that exists today. Filters that are on show
   as chips in the head row with their ×, as today. Nothing that can be filtered today is lost.
2. **The details panel:** a click on a tile selects it (a ring) and opens a panel on the right (about 340 px, the grid
   narrows; closes with × or Esc; a double click or Enter opens the post as today). It shows: the picture, kind, size,
   date; the chat(s) it was posted in (links), first seen where and when; whether Telegram still has it; its copies
   (exact and probable, with links to their review); saved or not downloaded; and, when the old-or-new data is present,
   "in the old archive / probably / partly / new" and "seen by the old app, never saved". Data the viewer does not have
   is left out, never invented. Arrow keys move the selection.
3. **Old or new:** when `/api/meta` says `old_archive`, a toggle in the Filters panel (New / Probably / Partly / In the
   old archive) using `old=`, and a small mark on tiles that are new. The viewer track's U2 (`wip/b-oldnew`) carries the
   data; merge its listed head when it lists (ask U-1 for it); until then build against the contract with every field
   optional, and test with a fixture that has the fields.
4. The list's library views (New, Deleted, First seen here, Probable copies, Changes) keep opening the grid with their
   filter, shown as a chip, and the toggle keeps working with them. The address keeps every choice (back/forward and a
   reload land in the same place).
5. Both themes, the tile sizes and the narrow width keep working.

## Done means
- The viewer's named library tests (find them by name; add tests for the head row, the panel's data, `old=`); `gofmt`,
  `go vet ./internal/viewer/` if Go changed.
- Pictures (1280x860, invented archive, your try window): the library with the head row; the Filters panel open with
  two chips on; a tile selected with the details panel; Videos only; old-or-new if the data is there; light theme once.
  In `runs-ui-1/f4-pictures/`. Look at them beside the picture B and say what differs.
- Report back: the branch head, files touched, tests with times, the pictures, what is not done or not verified (under
  40 lines). Close your programs.

## Added 11-22 at the owner's word: "Add a way to hide media by maybe right clicking on it."
A right-click menu of the app's own on a tile (Hide, Open, Show in its chat, Select); Hide through the viewer's
`/api/hide` kind "post" (its own folder, never the archive), the tile gone at once, "Hidden · Undo" for about 8 s; the
same Hide in the details panel and on the key H; several selected tiles hidden at once; a "Hidden" filter with "Show
again". An album is one post: the menu says "Hide this post (N files)" when N > 1.
