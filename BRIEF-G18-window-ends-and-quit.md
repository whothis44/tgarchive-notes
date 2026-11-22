# Brief G18: the app's window that ended by itself; "quitting doesn't exit"; the Viewer link (pages, P6, 11-16)

**The first rule of this folder: routine steps in one go or by a script, never one call at a time for its
own sake.** You are one Opus coder. Work only in the copy and on the branch your start message names
(`wt-pages-quit`, `wip/pages-quit`). Never touch `repo-archiver` itself or another `wt-*` copy.

## What the owner met (11-16 18:05 to 18:15, the first real start of the folder's program)
"Overall, it's a very ugly app, not fully functional, doesn't quit properly, and still runs in a
browser, just a standalone one?" From the owner's words and the launcher's own log (read by the
integrator; fixed words and times only):
1. **At BOTH starts with a saved setup the app's window ended by itself, exit code 0, after 8 s and
   after 4 s, each time in the second in which the launcher had started the viewer** (log: "viewer
   started (process N), kind 1": the viewer as a window). At the first start (the setup; no catalogue
   yet, so no viewer was started) the window lived 136 s. The owner had to open `tgarchive.exe` again
   each time ("the pages already answer: opened them, nothing started").
2. **One second after the first Quit (18:07:53: the collector, the watchdog, the window and the
   launcher all ended) a new launcher started (18:07:55).** The owner's own double-click, or something
   of ours: not known.
3. **Closing the window with X leaves the collector, the watchdog and the launcher running** (G11's
   design: "one closed by the person stays closed"). To the owner that is "quitting doesn't actually
   exit it".
4. **The header's "Viewer: set its address" leads to Settings' "Viewer address", an empty field**,
   although the launcher had started the viewer's window itself.
G11 and the window were tried with stand-in programs and with ONE real window: never with the pages'
window and the viewer's window together, and never by a person.

## What the old app already knows
The old app is one tray-less server with a browser tab: it has no window of its own, so nothing to
port. What it teaches is in this track's own record: the owner judges the program by its first minute;
"done" means the owner has opened it.

## What I read before briefing (check it, do not trust it)
- `internal/launcher/start.go` `viewerSpec`: the viewer as a window is started as
  `tgarchive-window.exe -db ... -library ... -staging ... [-mpv ...]` with `Dir` the app's folder and
  **no `-data`**; the pages' window as `tgarchive-window.exe -pages A -pages B -data <folder>/pages-window`
  (`present.go` `spawnWindow`, `windowArgs`). Both are the same program file, started by the same
  launcher, the second some seconds after the first.
- `present.go` `windowEnded`: an end with code 0 that the launcher did not ask for is taken as "the
  person closed it" (`w.closed = true`): nothing is shown, nothing is started again. So whatever ended
  the window, the launcher took it for the owner's own close.
- `start.go` `collectorArgs`: `-viewer-url` is passed only for the browser kind of viewer; with the
  window kind the pages have no viewer address, hence "Viewer: set its address"
  (`internal/server/web/assets/js/main.js` about 138 to 154).
- The viewer track's contract for the window (board messages 113, 116, 117 and 121 in `BOARD.md` /
  `BOARD-LOG.md`; `internal/window`'s own comments): the pages mode has a mutex, a window class and an
  engine folder of its own; a second start of the same mode on the same `-data` brings the first
  forward and ends with 0; a start that shows no window within 10 s ends with 3.

## What to build
**A. Reproduce point 1 first, with the REAL programs, then find its cause.** Build the folder's
programs from your copy into a scratch folder (`deploy/folder/make-folder.sh` shows how; or `go build`
of `cmd/tgarchive-window`, `cmd/tgarchive-open` and what you need, through the lock script), with
**`LOCALAPPDATA`, `APPDATA` and `TEMP` redirected to scratch folders for every process you start** (a
try of a starter once ran on the owner's real folder: never again), an invented catalogue (the server
package's fixture or the demo's), an invented library folder, and stand-ins for the collector and the
watchdog where the launcher's tests have them (the real collector must NOT run: nothing may reach
Telegram, and it refuses outside the VPN anyway). Start the pages' window as the launcher does, then
the viewer's window as the launcher does, a few seconds later, and watch both processes: which ends,
with which code, after how long. Then the other order. Then through the launcher itself if you can
(its own flow with a saved setup). Real windows will show on the owner's screen for some seconds: keep
each try short, close what you opened, never leave one behind; never use the owner's real folder
`C:\Users\trabi\tgarchive-app` or its ports (8786, 8787, 8788: choose others above 20000).
Read `internal/window` and `cmd/tgarchive-window` (the viewer track's: read-only unless the next
sentence applies) to its cause: an instance check, a window message, a shared engine folder, the
default data folder, the launcher's own "bring forward" start, the launcher's job.
- If the cause is in the launcher's use of the program (for example the missing `-data` for the
  viewer's window): fix it in `internal/launcher`.
- If the cause is in `internal/window` or `cmd/tgarchive-window`: make the smallest fix as **LENT LINES
  in ONE commit of their own** (the viewer track takes, replaces or drops it), with a test there in the
  package's own style, and say so first in your hand-back.
- Either way, a test in `internal/launcher` that would have caught it with stand-ins if one can be
  written honestly, and **a look that cannot be skipped next time: a script or a Go test behind an
  environment variable that starts BOTH real windows on invented data, as the launcher does, waits 20
  s, and fails unless both still run** (say how to run it; it is what the integrator runs before the
  folder is handed to the owner again).
**B. Point 2, the launcher that started one second after the Quit.** Read every path of ours that
starts `tgarchive.exe` or the launcher anew (the window's "bring forward" start, the second-start
request, the watchdog, the folder-box helper, the Ctrl-C helper, anything in `cmd/tgarchive-open`):
can one of them start a launcher while or just after a Quit ends everything? If yes: fix and test. If
you find none, say so plainly ("no path of ours found: the owner's own double-click is what is left");
the integrator is asked for the launcher's log lines of those seconds and they are added to this
folder as `OWNER-RUN-1805-launcher-lines.txt` if it writes them: look for that file before you hand
back.
**C. Point 3, closing the window.** The owner decides what a close should do (asked, with a
recommendation: ask once and remember; a small icon beside the clock with Open and Quit). Until that
answer, build the part that is right under every answer: **when the person closes the app's window
while the app's programs run, the launcher asks, in a small Windows box of its own in front of
everything ("The app is still collecting in the background." ... "Keep it running" / "Quit the app"),
every time; "Quit the app" does exactly what Quit on the pages does; "Keep it running" leaves
everything as today and the box says how to get the window back (open `tgarchive.exe` again).** A
window that ended by itself (point 1's kind of end, or any end within the first seconds, or an end
the launcher can tell was not a person's close) must NOT be taken for the owner's close: the launcher
starts it again once and, if it ends again, opens the browser with the reason, as it does for a
failed window. Decide and say how the launcher tells a person's close from another end (the window
program may have to say it: an exit code of its own for "closed by the person" would be the honest
way; that is a lent line in the viewer's program, in the same lent commit, if you need it). The box
runs outside the launcher's own goroutines' locks (as the folder box's helper does: a fault in it
must not end or stall the launcher); no tray icon in this piece.
**D. Point 4, the Viewer link.** With the window kind of viewer the launcher passes the collector
`-viewer-url http://<the launcher's address>/viewer`; the launcher's new route `GET /viewer` shows a
small page in the launcher's look: "The viewer runs in a window of its own." with a button "Show the
viewer" (a POST behind the launcher's page guard: it brings the viewer's window to the front by
starting the window program once more with the SAME arguments as `viewerSpec`, or starts the viewer
when the launcher's is not running; say what the window program does on such a second start and check
it with the real program in A's rig) and a link back to the app's pages. Then the header says
"Viewer" and Settings' "Viewer address" must not be an empty riddle: look at what the Settings page
shows when the address comes from the start flag, and make it say so ("set by the program's launcher")
if it does not; that part is `internal/server` and small.

## Rules
- Files: `internal/launcher`, `cmd/tgarchive-open`; for D's last sentence `internal/server` (the
  Settings page's viewer row only: another coder of this track works in `internal/server` on other
  files now); lent lines in `internal/window` / `cmd/tgarchive-window` only as said above. Nothing in
  the collector. Another coder of this track ("G19": changing the folders, the setup's warnings) works
  in `internal/launcher` at the same time, in `settings.go`, `ui.go`'s setup page and the setup's flow
  in `launcher.go`: keep out of the setup's code and keep your changes to `present.go`, the routes you
  add, `start.go` and the window's paths in `launcher.go`, so that the two merge.
- No test function removed or renamed. Words a person reads: plain, true of the code, no jargon.
- **Every go, gofmt and vet command through the track's lock script:**
  `bash /c/Users/trabi/Claude/Projects/Telegram/runs-pages-p6/go1.sh /c/Users/trabi/Claude/Projects/Telegram/wt-pages-quit/archiver <command...>`
  (it may wait some minutes for the lock: expected). Named tests only, nothing over two minutes a
  command, no whole package, no race detector (the full runs are made once after the review).
- Never a Windows path inside a shell string (Write/Edit tools; `/c/...` in bash; PowerShell scripts
  written with the Write tool and started by full path). Never capture the output of a command that
  starts a hidden or windowed program (the call hangs until the program ends): start it with its
  output to a file and read the file.
- Commit as you go, push to `private` only (`git push private wip/pages-quit`):
  `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the last line
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Invented data only. Leave no process, no
  window and no scratch folder behind.

## Hand back (at most 18 lines)
The pushed head; **the cause of point 1 in two lines and where it is fixed**; the lent commit's hash
if any; what the two-windows look showed before and after; point 2's finding; how a person's close is
told from another end; what the box says; the Viewer route; files with +/- lines; test functions added
and removed; the named tests run; what is NOT verified (above all: what only the owner's screen can
show). A report as `archiver/docs/progress/pages-quit-REPORT.md`.
