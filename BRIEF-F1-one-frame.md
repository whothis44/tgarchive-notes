# Brief F1: one frame (UI track, session U-1, 11-21)

You are an Opus coder for the UI track of a private Go project (a Telegram archiver; the app is a WebView2 window
over two local HTTP servers: the collector's pages, `internal/server`, and the viewer, `internal/viewer`). The UI
track owns the whole front end. Work ONLY in your copy `C:\Users\trabi\Claude\Projects\Telegram\wt-ui-f1` (branch
`wip/ui-frame`; the Go module is in `archiver/`). Commit as you go with
`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message ending with the line
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `git push private wip/ui-frame` (never another
branch, never `main` or `origin`, no tag, no merge into another branch).

## Rules (binding)
- Invented data only in tests, fixtures and pictures. Never open the owner's folders (`C:\Users\trabi\tgarchive-app`,
  `...-next`), catalogue, viewer or media; never stop, start or touch a program you did not start yourself.
- **The owner's real app window is open on this PC.** Never take a screenshot of the screen and never use
  computer-use. Pictures only of your own try window, with `C:\Users\trabi\Claude\Projects\Telegram\runs-ui-1\shot.ps1`
  (it captures one window by its process id and refuses any program whose path lacks "try"); clicks in it with
  `runs-ui-1\uiclick.ps1` (by accessible name, same refusal); pages alone may also be shot with headless Edge.
- Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` first, one `go` command at a time.
  Tests: ONLY named tests (`-run`) of what you changed, plus the whole of `internal/appshell` (small). Never the whole
  `internal/viewer`, `internal/server`, `internal/collector` or `internal/catalog`; no race detector. `gofmt -l` and
  `go vet` on the packages you changed.
- Nothing runs against Telegram (the `app` subcommand and `-demo` never connect; the collector is never started).
- Text with a Windows path goes into files through the Write/Edit tools, never through a shell string.

## Read first
`DESIGN-ONE-WINDOW.md` (the decided shape and the owner's words), `AUDIT-UI-1121.md` (what is wrong today, with the
pictures in `ui-audit-1121/`), `DESIGN-ONE-WINDOW-HOW.md` sections 3 and 9 (the viewer's constraints), and the
picture `design-options/app-look-options.html`, first button "The combination" (open it with headless Edge, or read
its markup). All in `C:\Users\trabi\Claude\Projects\Telegram`. Then `internal/appshell` whole (`shell.go`,
`assets/shell.js`, `assets/shell.css`), the viewer's mount (`internal/viewer/shellmount.go`, `web/index.html`,
`web/app.css`'s shell part) and the pages' (`internal/server/shell.go`, `web/index.html` and its head bar).

## The goal
Today the window looks like two programs (audit 1 and 2). Since the viewer's W1v (in your base) both servers draw
the list from the same `internal/appshell`; make that one frame the right one, identical on every page of both:
1. **The list, top to bottom:** Overview, Saved Messages; LIBRARY: All media, New, Deleted on Telegram, First seen
   here, Probable copies, Changes (with their counts as now); CHATS: a "Find a chat" box, then the chats by newest
   activity, each with its state in a few words. Photos / Videos / Files leave the list (the library's filters
   still offer them; a later piece makes them a toggle in the library's head). Copies, Overlap, Staging, Import,
   Report, About, Program and "Viewer settings" leave the list's body.
2. **Fixed parts, one scroll:** the head and the Library group stay put; the Chats group scrolls on its own and
   fills the height between them and the foot; the list never scrolls as a whole. The Collecting group goes.
3. **The foot, pinned at the bottom:** Queue (its waiting count when known), Choose chats, Settings, Accounts, and
   "More" opening a small menu with Staging, Import, Report, Copies, Overlap, About, Program. Nothing is lost: every
   place reachable today stays reachable in at most two clicks. On the old archive's window (NoCollector) the
   pages' entries stay left out, as now.
4. **One top strip on every page** (appshell owns its markup): the app's name at the left, the search box in the
   middle (on a pages page it opens the viewer's library with the query, as the viewer's own box does), the state
   pill at the right. The viewer's own head and the pages' head bar no longer draw a second one; the pages' "Viewer:
   set its address" button shows only when the run gave no viewer address (never in the app), and its "Theme"
   button goes (the theme is a setting).
5. **One Settings:** the foot's Settings is the app's Settings; the viewer's settings appear as its section
   "Library display" (a link card at the top of the app's Settings to the viewer's `/settings`, whose title then
   reads "Settings · Library display" with a way back). The list has no second Settings.
6. **The window's title bar** reads "tgarchive" (`internal/window/shell_windows.go`, `windowTitle`: the viewer
   track's file: one lent commit of its own, subject "Lent to the viewer (window):").
7. **The look of the picture:** widths, spacing, the selected row, the group titles, the avatars and the strip as in
   "The combination". The same width (the picture's) on both servers; nothing jumps when a click crosses servers.
8. **For the pictures:** `cmd/tgarchive/app.go` takes `-viewer-url` (and `-launcher-url` if trivial) and hands it to
   `server.Config` as the collector does, so `app -demo` plus a joined window show the whole frame working (one lent
   commit, subject "Lent to pages (app):"). Write the try steps as a script in `runs-ui-1/try-joined.sh`: build the
   window and `tgarchive` from your copy into `runs-ui-1/try-<name>/`, fabricate an invented archive
   (`tgarchive fabricate -db ... -library ... -files -reads -real-rows -chats 40`), start `app -demo -viewer-url` on
   127.0.0.1:18797 and the joined window (`tgarchive-window -db ... -addr 127.0.0.1:18798 -pages
   http://127.0.0.1:18797/ -tell-close`), every program with LOCALAPPDATA, APPDATA, TEMP and TMP inside the try
   folder, output to files, started in the background (never capture a started program's output through a pipe).

## Done means
- appshell's tests for the new order, the fixed foot, the More menu's entries, NoCollector, an empty and a filled
  catalogue; the viewer's and the server's shell tests by name.
- Pictures of your try window (1280x860) on the invented archive: the library, a chat, the Overview, Settings, and
  the More menu open; plus the pages on an empty catalogue (`app` without `-demo` on a new file). Put them in
  `runs-ui-1/f1-pictures/` and look at them yourself beside the picture; say what still differs.
- Report back: the branch head, the files touched (and the lent commits), the tests with times, the pictures' names,
  what is not done or not verified. Then close your try window and programs.

## Added 11-22 at the owner's word (on W1v's list in F5's pictures)
"It looks very clumsy/ugly. The stuff under Library takes up so much space that you can barely see the chats. Not sure
if it's collapsible or customizable? Or if we can filter out chats, or entire accounts?" So, binding: the Library group
compact (at most six one-line rows, about 30 px each) and collapsible by its title, remembered, the Chats title too; head
plus Library within about 40% of an 860 px window; "Find a chat" filters as you type; an account filter at the Chats
group's head when there is more than one account, remembered; "Hide from the list" on a chat row and "Show hidden chats"
(the viewer's hidden-chats rule, or a door asked of U-1); an "Edit" on the Library title to tick which views show.
Pictures: one account, two accounts with the filter, the Library folded, 40 chats.
