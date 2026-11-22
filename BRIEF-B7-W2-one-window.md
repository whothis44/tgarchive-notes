# Brief B7-W2: ONE window (the viewer's window also shows the app's own pages)

Written by the viewer session B7, 11-16. One Opus coder, high effort. Hand back commit-ready work on the
branch; merge nothing; push only this branch. Cut from `wip/b-winfix` at ca98432f (the `-tell-close` piece).

**The project's first rule (the owner): no routine sequence call by call for its own sake. While working run
only the named tests of what you changed, one go command at a time, never the race detector, never a whole
slow package (`internal/viewer` whole takes about 7 minutes: by name only).**

## 1. What the owner decided, and what this piece is
The owner opened the app for the first time on 11-16 and said: "a very ugly app, not fully functional, doesn't
quit properly, and still runs in a browser, just a standalone one?" Two windows came up (the app's pages; the
viewer). The owner then chose ONE window for both (`DESIGN-ONE-WINDOW.md` in the project folder; how:
`DESIGN-ONE-WINDOW-HOW.md`, its sections 3 and 4; read both first, they are short). The two servers stay (the
collector serves the app's pages; the viewer is read-only with no Telegram code). What becomes one is the
window: **the viewer's window (`tgarchive-window -db ...`) also takes the app's addresses (`-pages`), shows
them as places of the same window, and is the only window the launcher starts.** The list on the left that
joins the places ("W1", a package of the pages track) is NOT this piece; nor is the app's own title bar
("W2b"). This piece must work with the pages as they are today.

## 2. What the old app already knows
Nothing to port: the old app (the fork) is a web dashboard in the browser, with no window of its own. What
this project already learnt, and you must keep: `LESSONS-viewer-ix12.32.md` section 4 (no request a page
depends on may wait for slow I/O; show progress, never a blank area); the window's own record: the engine
(WebView2) calls out by itself unless it is started behind the gate (`internal/window/gate.go`,
`engine.go`): **nothing in this window may reach anything but the allowed 127.0.0.1 ports.**

## 3. Where
- A NEW copy and branch, made by you as your first step, cut from `wip/b-winfix` at ca98432f (the
  `-tell-close` piece is on it):
  `git -C /c/Users/trabi/Claude/Projects/Telegram/wt-b-join worktree add /c/Users/trabi/Claude/Projects/Telegram/wt-b-onewin -b wip/b-onewin ca98432f`.
  Work only in `wt-b-onewin`; change nothing in `wt-b-join` (a review and the full runs of the earlier piece
  use it) and never touch the folder `repo-archiver`. Push to the remote `private` as you go
  (`git push private wip/b-onewin`); never the main branch, never `origin`.
- Commits: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- You may edit: `archiver/internal/window`, `archiver/cmd/tgarchive-window`, and in `archiver/internal/viewer`
  only what section 9 names. Nothing in `internal/launcher`, `internal/server` or any other package.

## 4. Read first, yourself (about 1,200 lines)
`cmd/tgarchive-window/main.go` and `pages.go` whole; in `internal/window`: `doc.go`, `allowed.go`, `gate.go`'s
head and `allow`, `shell_windows.go` (`Run`, `viewerReady`, `webViewReady`, `fallBack`,
`webviewProcessFailed`), `pages.go` (the pages view: what is shown when a page does not answer),
`pages_windows.go` (`RunPages`, `mayShow`, `pagesNewWindow`, the download rule's use), `webview_windows.go`
(the navigation, frame, new-window, message, download and permission handlers), `bridge.go`'s
`OnPageMessage` and where it hides the video; the reviews of the window in `archiver/docs/review` whose names
hold `window` (their findings are rules now: do not undo one).

## 5. What to build
1. **Both flag sets together.** `tgarchive-window -db FILE ... -pages http://127.0.0.1:PORT/ [-pages ...]`
   is the joined mode: the viewer as today AND 1 to 4 named addresses (each exactly as `PagesAddress` takes
   them; none twice; none equal to the viewer's own address). `-pages` WITHOUT `-db` stays the pages mode
   exactly as it is (the launcher's setup page uses it). `-db` without `-pages` stays the viewer's window
   exactly as it is (the old archive's window; `b-window.cmd`).
2. **A fixed address for the viewer: `-addr 127.0.0.1:PORT`** (this PC only: any other host, port 80, a
   malformed value are refused in fixed words; default as today, a free port). Required in the joined mode
   (the launcher picks it and tells the app's pages). A port that cannot be listened on: the program's own
   fixed line and **exit code 7**, so the launcher picks another; in the joined mode this is known BEFORE
   the window shows (listen first, then open the archive: see 5).
3. **What may be shown and reached, joined mode:** the navigation rule (`mayShow`), the frame rule, the
   new-window rule and the gate's allowed set are the viewer's own address plus the named ones, nothing
   else; the gate's set is still fixed ONCE, before the engine starts (possible because the viewer's
   address is now known at the start). A new-window request for an allowed address is followed in the same
   window, as the pages mode does today; any other is refused and counted as today.
4. **The page-to-window channel stays the viewer's alone.** `Bridge.OnPageMessage` already drops a message
   whose source is not the viewer's address: keep it, and add the test that a message from a named address
   moves nothing (no video shown, no path asked, counted as dropped by source). When the window navigates
   from a viewer page to a named address, the video area is hidden and mpv is stopped or paused as at any
   navigation today: find how it is done, say it in your hand-back, and test it (pure) if it is not.
   Downloads: a viewer address follows the viewer's rule (`decideDownload`), a named address the pages
   mode's (`pagesDownloadOK`). Permissions: refused as today, in every mode.
5. **The start, joined mode: no blank window, and the pages do not wait for the archive.** Order: flags
   checked; the instance rule (the viewer's: one window per data folder); the viewer's listener opened on
   `-addr` (or exit 7); the gate's set fixed; the window shown; the engine started; **the place named by
   `-first` shown at once** (`-first` is one of the named addresses or the word `viewer`; default: the
   first `-pages` address in the joined mode). The viewer opens the archive in the background as today
   (`Start`); until it serves, a request for a viewer address is answered by the window's own listener
   with ONE small fixed page ("Opening the archive... N s", which asks again by itself; the viewer's own
   "reading the archive" page takes over when it serves), never by a refused connection. If the archive
   cannot be opened: the same small page says the viewer's safe words for why (`viewer.OpenFailureWords`,
   the rule of `StartError`), and the named pages go on working: the window does NOT become "Close this
   window" in the joined mode.
6. **A page that does not answer** (a named address whose server is down; the collector stopped): the
   window's own line with "Try again", as the pages mode has it, for named addresses in the joined mode
   too; never the engine's error page.
7. **No fallback to the browser inside the program in the joined mode** (as in the pages mode): no WebView2
   runtime, or it did not come in time, or it ended for good: `ErrNoWindow`, exit code 3, the launcher's to
   handle. The viewer's window without `-pages` keeps its fallback as it is.
8. **One of everything:** one mutex, one window class, one data folder (the viewer's `-data`, default as
   today), one engine folder (the viewer's), one title (the constant the viewer's window has), one counts
   file: the viewer window's stats gain the pages mode's counts that now apply (refused navigations by
   kind, dropped messages by source, "Try again" shown). `-tell-close` works as in the other modes.
9. **A way back from the viewer's pages to the app's, until W1's list exists.** The window has no back
   button. In the joined mode the viewer is told the first named address (`viewer.Config` gains one field,
   `AppURL`, validated as exactly `http://127.0.0.1:PORT/`; empty: nothing changes), and the viewer's
   header shows ONE link to it, in fixed words ("The app"), on every viewer page. From the session's look
   (`REPORT-B7-viewer-151.md`, "Q2"): the header is ONE shared piece, `<header class="top">` in
   `internal/viewer/web/index.html` lines 16 to 46 (the viewer is one page with a client router,
   `web/js/main.js`); the page's flags reach the script through `web/js/api.js` lines 8 to 18 and
   `server.go` line 75 (`lan`, `mark`, `act` today): add the app's address there as one more flag and show
   the link only when it is set. The link is NOT `data-nav` (it leaves the viewer's page). Tests: the
   viewer's page-flag tests and its header tests by name (find them with the flags' names); the guard's
   tests untouched. The
   link is a plain navigation; the viewer's guards and its Content-Security-Policy are not loosened for it
   (if `form-action` or `navigate-to` stands in the way, say so and stop: do not weaken the policy).

## 6. Not in this piece (do not build)
The list on the left and any new look; the app's own title bar; a tray icon; a question at the close (the
launcher's); any change to the launcher; any change to what the pages mode or the plain viewer's window do.

## 7. Tests
Plain Go, by name, in `internal/window` and `cmd/tgarchive-window`: the flags of the three modes (each
refusal in fixed words; the joined mode's rules of 1 and 2); the allowed set and the gate's set for the
joined mode (the viewer's and the named ports pass; a third port, another host, CONNECT, an upgrade are
refused: reuse the gate's existing probes); the message rule of 4; the start's order of 5 with stand-ins (the
small page before the viewer serves; the failure's words; the named pages unaffected); exit 7; nothing
changed for the two old modes (their existing tests pass unchanged: name the ones you ran). The wall tests
(`TestWallGate`, `TestPagesPathMakesNoViewer`, the viewer's `TestWall`) by name.
**The self-check with real windows** (the existing `-selfcheck` forms are your models): a joined-mode
self-check on an invented archive and two small servers of its own with invented pages, that (a) shows the
first named page, (b) goes to a viewer page and back by links, (c) plays one invented clip on the viewer page
and sees the video area hidden after the navigation away, (d) posts a message from a named page and sees it
dropped, (e) asks for a third port and sees it refused by the gate, (f) ends with the person's close and
`-tell-close`: exit 4. On a scratch folder (`runs-b7/onewin`), `LOCALAPPDATA`, `APPDATA`, `TEMP`, `TMP`
redirected into it BEFORE anything starts, output to files, at most 10 real window starts, each under 90 s.
mpv and ffmpeg: use `MPV_PATH` and `FFMPEG_PATH` if they are set in your environment; if not, run the
self-check without the clip and say so. Never look for them in the owner's folders.
Before EACH go command: free memory at least 2.5 GB (wait 2 minutes and look again, at most 5 times, then
stop and say so); `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`;
`GOMAXPROCS=2 GOFLAGS=-p=1`; one go command at a time, through the track's lock: take it with
`until mkdir /c/Users/trabi/Claude/Projects/Telegram/runs-b7/golock 2>/dev/null; do sleep 20; done`, release it
with `rmdir` of the same folder right after the command (also when it fails).

## 8. Hard rules (the owner's)
- Invented data only, in every test, fixture, picture and self-check. Never open, list or read anything
  under `E:\`, any folder named `tgarchive-b` or `tgarchive-app`, the owner's app folder, any NAS path or
  any real catalogue. Do not search drives.
- Never stop, kill or signal a process you did not start; post window messages only to your own window
  (found by its class for your scratch folder). At the end no process of yours is left (count them).
- The window reaches nothing but the allowed 127.0.0.1 ports: any new way out is a defect, however small.
  No new dependency.
- Every line the program prints is fixed words and numbers: no path, no address, no error text.
- Text with a Windows path never goes through a shell string into a file: the Write or Edit tool.
- Commit and push work in progress to `wip/b-onewin` as you go (usage can run out in the middle).

## 9. Hand back
Push. Your final message, at most 40 lines: the head's hash; files and line counts; how you solved 5.4's
navigation-away and 5.5's small page; each named test and its result; the self-check's lines (a) to (f) with
what was seen, or why a step was not run; every place where you could not do what the brief says and what you
did in its stead; your doubts, most important first; what you saw that is wrong but outside this brief.
