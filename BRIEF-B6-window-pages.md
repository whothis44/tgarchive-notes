# Brief B6-W: the window shows the app's own pages (`tgarchive-window -pages`), for the launcher (viewer session B6, 11-16)

You are an Opus coder for the viewer track of the new archiver. Work only in the copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-b-join` (Go module in `archiver/`). First, there: check the copy is
clean (`git status --short` prints nothing; if not, stop and say so), `git fetch private`, and cut the branch
`wip/b-winpages` from `private/claude/charming-feynman-vm2xia` (the main head; write the exact commit into your
hand-back). Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash (Go is
not on PATH). **You run named tests only; the whole runs and the race detector are not yours** (`CLAUDE.md`,
the archiver section, second point).

## Why
The owner opened the app's one program for the first time today and asked: "Will it eventually be standalone
(i.e. not in a browser)". The app's pages (the launcher's setup and status pages, and the collector's pages:
Chats, Queue, Staging, Settings) open in the default browser today. The viewer already has a window of its
own (`internal/window`, `cmd/tgarchive-window`: a WebView2 shell, used by the owner: "It works"). The pages
track will have the launcher start that program to show the app's pages in a window of the app's own, with
the browser as the fallback. **Your piece is the window's side of that: a mode of `tgarchive-window` that
shows named local pages and nothing of the viewer.** "Done" is the owner's next opening of the program.

**Read first, in full:** `internal/window`: `doc.go`, `allowed.go`, `run.go`, `shell_windows.go`,
`webview_windows.go`, `instance_windows.go`, `procs_windows.go`, `place.go`, and the parts of
`selfcheck_windows.go` that check navigation, new windows and downloads; `cmd/tgarchive-window/main.go`; the
two reviews of the window in `archiver/docs/review` (`viewer-b4-window-2026-11-15.md` and `-2-`, and
`viewer-b5-window-only-2026-11-15.md` and `-2-`): what they found is what this mode must not reopen.

**What the launcher will rely on (the pages track's words, board message 108 b; build exactly this):**
1. One way to start `tgarchive-window.exe` so that it shows ONE local address and nothing of the viewer: no
   catalogue, no library, no mpv needed.
2. It shows only addresses on `127.0.0.1` of the ports the launcher names (two: the launcher's own page first,
   then the app's pages; the launcher's page links to the app's pages, so navigation between those two must
   work); anything else is not shown.
3. Forms with POST and a meta refresh work as in a browser (the launcher's pages have no script).
4. It says by its exit code, within a few seconds, when it cannot show a window (no WebView2 runtime), so that
   the launcher falls back to the browser.
5. Closing the window ends that process and nothing else.
6. A second start while one is open brings the open one to the front.

## What to build
1. **The flag.** `tgarchive-window -pages URL [-pages URL ...] -data FOLDER` (at most 4 addresses; the first is
   the page shown first). Each must be `http://127.0.0.1:<port>/` with nothing else in it (no user, no path
   beyond `/`, no query: decide and say whether a start path is worth allowing; if in doubt, none). `-data`
   is required in this mode (the window's own folder: its place file and its WebView2 folder, kept apart
   from any viewer's; one window per data folder, as now). With `-pages`, every flag of the viewer (`-db`,
   `-library`, `-staging`, `-lan`, `-mpv`, the thumbnail flags, ...) is refused in fixed words: the two modes
   never mix. Without `-pages` the program is byte for byte what it is today (test it: the existing tests
   and the existing flag errors unchanged).
2. **Nothing of the viewer.** In this mode no catalogue is opened, no viewer is made, no listener is opened by
   this program, no mpv is looked for or started, no child process is started at all, and the page-to-window
   message channel takes nothing: a message from a page in this mode is dropped and counted (the viewer's
   pages are the only ones that may talk to the window, and they are not shown here). The package
   `internal/viewer` must not be needed by this mode's path (the command imports it for the other mode; do
   not call into it).
3. **What may be shown.** The existing rule (`allowed.go`: http, host exactly `127.0.0.1` and our port, no
   user part; `about:`, `data:`, `blob:`, `file:`, `javascript:`, `localhost` and every other address
   refused) widened from one port to the named set, for this mode only. A top-level navigation from one
   named address to another works (a link, a form's POST and its redirect, a meta refresh). A new-window
   request to a named address opens in the SAME window; to anything else it is refused. A frame of another
   address, a download of any kind, a request for a permission (camera, microphone, place, notifications,
   clipboard read), the launch of another program through a link's scheme (`mailto:`, `ms-settings:`, any
   other): each refused and counted, as the viewer's window refuses them today or more strictly: find what
   the window does for each today and say where this mode differs. **A link to the open web is NOT handed to
   the browser in this piece** (a page must not be able to make this program start another): refused,
   counted, and listed in your hand-back as a decision for the pages track to know.
4. **When the page does not answer.** The launcher or the collector may be starting, stopping or gone. The
   window must not show a blank or a browser's own error page with its buttons: one fixed line of the
   window's own ("The app's pages are not answering.") with "Try again", which loads the first address
   again; no loop without a pause.
5. **The exit code.** 0: the window was closed by the person, or another window on this data folder was open
   and was brought to the front. A code of its own, one constant (say which number), within a bound you
   state and test (10 s at most): the window cannot be shown (no WebView2 runtime, or it did not start):
   nothing is left running, and one fixed line says so. **In this mode there is no fallback to the browser
   inside the program** (the launcher does that). Another code for bad flags, as today.
6. **Closing.** Closing the window ends this process within the existing bound and nothing else; nothing is
   written anywhere but the data folder (the place file, the WebView2 folder, the counts file if this mode
   keeps one: numbers only).
7. **The look.** The same shell as the viewer's window (title, icon, remembered place and size per data
   folder); the title is one fixed word for the app, not a page's own title (a page must not be able to
   name the window), unless the viewer's window already does otherwise: then the same as it.
8. **A self-check for this mode** (`-selfcheck` with `-pages` given no address: the program starts two small
   servers of its own on 127.0.0.1 with invented pages, shows the first, and checks, printing numbers and
   fixed words only: a link from the first to the second and back; a form's POST with a redirect; a meta
   refresh; a link, a `window.open` and a frame to a third local port, to `localhost`, to an `https` address
   and to a `file:` address (each refused); a download (refused); a permission request (refused); a scheme
   launch (refused); a message from the page to the window (dropped); the first server stopped and "Try
   again" after it is started again; then it closes the window itself and exits 0). It needs no network
   beyond this PC and reaches no address but its own two servers.

## Tests (named)
- The address rule as a table (every form `allowed_test.go` has today, for a set of two and of four ports).
- The flags: each good and bad combination, in fixed words; without `-pages`, today's behaviour.
- The exit code for "no window can be shown", with a stand-in for the WebView2's start that fails and one
  that never answers (the bound holds on a test clock).
- That this mode's path makes no viewer, opens no catalogue and starts no process (by a stand-in or by
  construction: say which).
- The self-check of point 8, run by you **at most three times** (it opens a real window on this PC's
  screen for some seconds, and the owner is at the PC: say how often and how long). No other real window.
- The existing tests of `internal/window` and `cmd/tgarchive-window` by name where your change touches them.
- Before handing back: `git diff <your base> HEAD | grep '^-func Test'` prints nothing, or you account for
  each line.

## Rules (hard)
- Only `internal/window` and `cmd/tgarchive-window` (and their tests). No `go.mod` change, no new
  requirement. Nothing in `internal/viewer`, `internal/launcher`, `internal/server` or any other package.
- **Privacy and the owner's programs:** invented pages only. Never start the owner's viewer, window,
  launcher, collector or old app; never start `tgarchive-window` on any folder but a scratch folder of your
  own, **with `LOCALAPPDATA` pointed at an empty scratch folder for that process** so that no real folder
  can be reached whatever a script or default does, its output written to a file, never read through a
  pipe from a hidden start. Stop no process you did not start (the owner's own programs may be running: a
  `tgarchive` launcher, a collector, a watchdog, a window). Nothing under
  `%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b`, `%LOCALAPPDATA%\tgarchive`,
  `C:\Users\trabi\tgarchive-app`, `E:\T` or the NAS is opened, listed or written.
- **Words:** every line the program prints and every sentence the window shows from this piece is fixed
  words and numbers: never an address beyond `127.0.0.1` and a port, never a path, never a page's text.
- **Load (other work is going on this PC):** one go command at a time, `GOGC=50 GOMAXPROCS=2 go test -p 1 -run
  '<names>' ./internal/window` (or the command's package); before each go command
  `powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`
  and wait while free memory is under 2.5 GB or the CPU is over 85%. No race detector, no Docker, never any
  cache clean-up. Every wait in a test has a bound.
- Any file that holds a Windows path is written with the file-writing tool, never from inside a shell string.
- Other copies (`wt-b-viewer`, `wt-b-faces`, `wt-b-window`, any other track's) are not yours.
- Commit as you go on `wip/b-winpages` and push only `git push private wip/b-winpages` (never another branch,
  never `origin`; never merge into, rebase or switch another branch; never stash):
  `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no archive numbers in it.

## At the end, once
`gofmt -l` on what you touched; `go vet ./internal/window ./cmd/tgarchive-window`; your named tests;
`CGO_ENABLED=0 go build ./...`. Hand back, as your last message: the head (pushed) and its base; **the mode as
built, written so that the pages track can start it without reading your code: the exact command line, what
each exit code means and within what time, what is shown and what is refused, what happens when a page does
not answer, what a second start does, what the program writes and where**; each of the eight points with any
difference from this brief and its reason; the self-check's printed lines (numbers) and how often it ran; what
you did NOT test (monitors of different scaling, a PC without the WebView2 runtime, a real launcher); your
doubts, plainly. Commit-ready, nothing left running, the copy clean.
