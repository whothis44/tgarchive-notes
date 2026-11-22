# Brief W1v: the two lists made one (viewer session B9, 11-21)

You are an Opus coder for the viewer track of a private Go project (a Telegram archiver). Work ONLY in the
copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-onelist` (branch `wip/b-onelist`, cut from the main head
af4ca40). The Go module is in `archiver/`. Commit as you go to `wip/b-onelist` with
`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message ending with the line
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, and push it: `git push private wip/b-onelist`
(never another branch, never `main`, no tag, no merge into another branch).

## Rules (binding)
- Invented data only in tests, fixtures and pictures. Never open the owner's real folder, catalogue, viewer
  or media; never stop, start or touch a program you did not start yourself. Print counts, sizes and timings
  only, never names or paths of real data.
- Every `go` command goes through the track's lock script, one at a time:
  `bash /c/Users/trabi/Claude/Projects/Telegram/runs-b7/shell/scripts/gorun.sh <dir> go test ./internal/x -run 'Name' -count=1`
  (it measures the PC and sets the environment; do not run `go` any other way).
- Tests while working: ONLY named tests (`-run`) of what you changed, and the whole of `internal/appshell`
  (small). No whole `internal/viewer`, no race detector, no `go vet` over many packages: the full runs are
  done once later, not by you. `gofmt -l` on the files you changed is fine.
- Text with a Windows path goes into files through the Write/Edit tools, never through a shell string.
- Do not start a window on the screen. The joined self-check (below) is the one exception, and only if the
  brief's last section says you may.

## The goal
The app is ONE window with ONE list on the left (`C:\Users\trabi\Claude\Projects\Telegram\DESIGN-ONE-WINDOW.md`;
the joint note `DESIGN-ONE-WINDOW-HOW.md` in the same folder, sections 2, 3 and 9: read both first). Today
there are two lists in two looks: pages' package `archiver/internal/appshell` (mounted on the collector's pages
in `internal/server`: `server.go` line about 331, `shell.go`) and the viewer's own (`internal/viewer/web/js/shell.js`,
the `nav#places` markup in `internal/viewer/web/index.html`, the `.has-places` block in the viewer's `app.css`).
At every change of server in the window the owner sees the list change. **Make `internal/appshell` the one
list, mounted on the viewer's pages too, and remove the viewer's own list.**

## Part A: the lent part in pages' `internal/appshell` (ONE commit of its own, additive only)
This package belongs to the pages track; its session is asked on the board for its yes. Keep every change
additive (nothing of theirs removed or renamed, every existing test passes unchanged) and in ONE commit whose
subject starts "Lent to pages (appshell):", so it can be reworked or dropped on its own.
1. `Entry.Count int` (json `count`, omitted when 0) and `assets/shell.js` drawing it as a small badge at the
   end of the row (a style in `assets/shell.css` in the strip's colours; 0 draws nothing; thousands with a
   separator).
2. `Options.Counts func(ctx context.Context) map[string]int`: counts by entry key, asked once per `List`
   with `List`'s own context; nil: none. A count not ready is left out of the map, never waited for
   (pages P7, message 207/216).
3. `Options.SkipChat func(id int64) bool`: a chat for which it answers true is left out of the Chats group
   (the viewer's hidden chats); nil: none. `Answer.Chats` keeps counting every chat; `Shown` what is drawn.
4. The Library group gains Photos, Videos, Files after All media (`/?type=photo`, `/?type=video`,
   `/?type=file`; keys `lib:photo`, `lib:video`, `lib:file`) and Changes last (`/changes`, key `changes`).
   Copies (`/copies`, "files kept more than once", key `copies`) and Overlap (`/overlap`, "chats that share
   files", key `overlap`) also go in the Library group, after Files and before Changes (pages P7: they are
   the library's places; NO group "Viewer"). At the foot: "Viewer settings" (`/settings`, key
   `viewer-settings`) right after the pages' "Settings", and About (`/about`, key `about`) last. All owned by
   Viewer.
5. `Options.NoCollector bool`: the old archive's window (no collector at all). Then the pages' places
   (Overview, the Collecting group, the foot's Settings and Accounts, "N more" chats' link) are LEFT OUT
   instead of drawn dead, and the head starts with one entry that leads nowhere, key `nocollector`,
   title "Old archive", words "nothing collects this archive" (its Dead text: "This archive is only viewed:
   no collector runs on it."). Saved Messages and the chats still show.
6. Tests in `shell_test.go` for each point (invented catalogue as the existing tests make it).
Read `shell.go` and `assets/shell.js` whole before you change them.

## Part B: the viewer mounts it (the viewer's own files)
1. Serve the shell on the viewer: `appshell.AssetHandler()` under `appshell.AssetPath` and the list under
   `appshell.APIPath`, through the viewer's own `handle(...)` with its route classes (`server.go` `routes`,
   `access.go`): **this PC only** (a device at home gets neither: its page keeps the top bar). The options:
   `Self: appshell.Viewer`; `PagesURL` from the viewer's `AppURL` (the joined window's pages address; trim the
   slash at the end); `LauncherURL` if the window knows the launcher's address (find out whether
   `cmd/tgarchive-window` / `internal/window` receive it in the joined line the launcher builds,
   `internal/launcher` `present.go`/`start.go`; if they do not, pass "" and say so in your hand-back:
   do NOT change `internal/launcher`); `Counts` with `lib:deleted` = the deleted posts count the viewer's
   `/api/meta` already gives (`deleted_posts`, from memory, no new read of the library); `SkipChat` = the
   owner's hidden chats (`hiddenSnap.chats`, `decisions.go`); `NoCollector` true when the viewer has no
   `AppURL` (started without a pages address: the old archive's starter). Check the viewer imports nothing
   it may not (it may import `internal/catalog` and `internal/appshell`; never Telegram code or
   `internal/server`): there is a test or a list that guards the viewer's imports: keep it passing.
   `appshell.List` takes a `*catalog.Catalog`: find how the viewer reaches its read-only catalogue (it opens
   the catalogue file read-only through a door: `viewer.go` around line 254) and give `List` what it needs
   without a second writable open; if that cannot be done cheaply, say so before building around it.
2. `index.html`: load `/shell/shell.css` and `/shell/shell.js` (`defer`, before the page's module scripts;
   the CSP is `script-src 'self'`: keep it). Remove `nav#places` and the viewer's `shell.js`, its import in
   `main.js` and the `.has-places` block of `app.css`. On this PC the viewer's top bar (`#top` with its tabs
   and icon buttons) goes away under the shell's strip; its **search box moves into the content's head**
   (the library's head, where the owner searches); "The app" link (`#applink`) goes (Overview is the way). On
   a device at home (`listener.lan`) nothing changes: no shell, the top bar as today. The shell must be
   mounted only on this PC's page: shell.js mounts itself on load, so load the two files only on this PC's
   page (the server fills the page per listener: `fillPage`/`homeFlags` in `server.go`) or gate it; your
   choice, said in the hand-back.
3. The router (`main.js`): `AppShell.onNavigate((url) => { navigate(url.pathname + url.search); return true; })`
   for the viewer's own places (no reload); a place of the other server is an ordinary navigation (the hook
   answers false or is never asked: shell.js asks it only for this page's own origin).
   `AppShell.select(key)` at every change of address (where `shell.mark()` is called today), with the
   package's keys: `lib:all` for a plain `/` (search words ignored, as the viewer's `placeOf` does now),
   `lib:photo|video|file`, `lib:deleted`, `lib:first`, `lib:new` (`/?first=1&from=...`), `lib:copies`
   (`/?copies=probable`), `changes` (`/changes`, `/deleted`), `saved:ACCOUNT` (`/saved?account=ID`, `/saved`,
   and `/chat/ID` of an account's own chat: the viewer's meta knows which chat is whose, see the old
   `shell.js` `savedIDs`), `chat:ID`, `copies` (`/copies`, `/copies/probable`), `overlap`,
   `viewer-settings`, `about`; `/chats` has no entry of its own (select nothing).
4. Layout, what the viewer's page must respect (the joint note section 9): the list is a fixed column beside
   a document that scrolls as a whole (the library's grid scrolls the window): never two inner scrolling
   boxes; the post's view (`item.js`) covers the whole window, list and strip too; the library's own filter
   column stays as it is (narrowing it is a later piece). Nothing wider than the window at 900 px wide.
5. A chat hidden or shown again (`clutter.js` raises `viewer:marks`): call `AppShell.refresh()`.
6. Tests: the viewer's Go tests that look at the page's markup, its routes and its access classes (find them
   by grep: `index.html`, `places`, `has-places`, `routeClass`, `classes`) brought to the new page; a test
   that `/api/shell` and `/shell/shell.js` answer on this PC's listener and are refused on the device
   listener; a test of the options the viewer builds (pages address from `AppURL`, `NoCollector` without it,
   a hidden chat skipped, the deleted count). Run each by name.

## Part C: the pictures (only after A and B pass their named tests)
The window has a joined self-check that takes pictures: `internal/window/joinedcheck_windows.go`
(`TGARCHIVE_JOINED_PICTURES`; how session B8 ran it: `runs-b8/b8-scripts/selfcheck.sh`, which runs a built
window on an invented archive in `runs-b8/look`). Bring its checks to the new page (it looks for the old
list's markup: it must look for the shell's `.as-list` and the selected entry instead). Build the window with
`gorun.sh` into a folder of your own under `C:\Users\trabi\Claude\Projects\Telegram\runs-b9\look` (copy the
invented archive from `runs-b8/look/arch`; redirect LOCALAPPDATA, APPDATA, TEMP as that script does) and run
the self-check ONCE, output to a file, pictures into `runs-b9/look/pictures1`. **You may run it: it opens a
real window for up to 90 s; the session has announced it.** Do not start anything else that opens a window.

## Hand-back (your final message; short; numbers, no real data)
The commits (hash, subject) and that they are pushed; what each part does in a few lines; every test you ran
by name with its result and seconds; the pictures' file names and what each shows; what you did NOT do or
could not (LauncherURL, the pill on the viewer's pages: not in this piece), and anything in this brief that
was wrong against the code. Stop at the first thing that is not as written here and say it, rather than
building round it.
