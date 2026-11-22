# Brief B8-L1b: the fix round of the launcher's one window, and the window waits for a new catalogue (session B8, 11-16 21:00)

**Routine steps by a script, not call by call.** You are ONE fresh Opus coder. Two small parts, two commits,
in this order. Hand back commit-ready and pushed.

## Where
- Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-b-launch` (branch `wip/b-launch`, head c4d0f502, clean,
  pushed). Module `archiver/`. Read first: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-B8-L1-launcher-one-window.md`
  (what c4d0f502 was asked to do) and `git -C <copy> show c4d0f502` (what it did).
- Part A changes ONLY `archiver/internal/launcher` (the pages track's package, lent: smallest change, its
  style, no renames). Part B changes ONLY `archiver/cmd/tgarchive-window` (the viewer track's own).

## Part A: the independent review's fixes (one commit)
The review's findings, decided by the session:
1. **MUST FIX (medium-high): the joined decision is read from the settings in three places and looks at
   nothing else.** (a) When the launcher's window has FAILED earlier in this run (`win.fell`: the browser is
   used) and the programs start, the collector gets `-viewer-url`, no viewer is started and the pages go
   to the browser: the owner has no viewer at all; the head started the viewer's own window there.
   (b) When a viewer window of its own is STILL RUNNING (it is closed only at Quit; left from an earlier
   start of this run with the pages in the browser or an unusable address), the joined window finds its
   instance folder taken, exits 0 ("already open"), the launcher takes that as the person's close, and the
   app's pages appear in no window and in no browser.
   **The fix, the reviewer's:** decide ONCE per start, in `begin`, before the watchdog's line is made:
   joined = `joinedViewer(s)` AND the window has not failed in this run AND no viewer of this launcher's
   own is running. Hand that one decision to `collectorArgs` and `viewerSpec` (a parameter), store it in
   `win.joined`, and let `windowForPages` use the stored value instead of reading the settings again
   (this also closes the small race with a change of the choice between the watchdog's start and
   `windowForPages`). A start that FINDS a watchdog already running: decide the same way there (the
   collector's line is whoever started it: one comment saying so).
2. **Changing "where the pages open" to the browser on the launcher's page while the window is the joined
   one** ends the window and with it the viewer; the head's separate viewer window stayed open. **Fix it
   only if it is small once 1 is in** (at most about 12 lines: after the joined window is ended there,
   clear the stored decision and start the viewer's own window by the existing `startViewer` path);
   otherwise leave the behaviour, write a comment at that place ("accepted for now: the viewer goes with
   the window; changing back to the window brings it back") and say so in the hand-back.
3. **Low, fix:** in the joined case build the collector's link from the normalised port,
   `http://127.0.0.1:<port>` (the same form the window's `-addr` gets), not from `ViewerAddr` as written.
4. **Low, comments only:** exit 7 of the joined window (the viewer's port held by another program) is
   "another error" with the browser fallback: one line of comment where the ends are read. Nothing built.
5. **Not in this round (say nothing more than a line in the hand-back):** the setup page's words for the
   viewer choice (`ui.go` about 845: "The viewer's own window" is no longer what happens with the
   defaults): pages' words, left for pages.
- **Tests:** the pure test must stop forcing `fell=true` while expecting the joined spec; add: a start after
  the window failed in this run (the head's lines: no `-viewer-url`, the viewer's own window started, the
  pages in the browser); a start while a viewer of the launcher's own still runs (the head's lines, two
  windows); the link's normalised form; and for 2 whichever way you took. The existing tests of every
  other combination pass unchanged. Remove no test function.

## Part B: in the joined mode the window program waits for a catalogue that is not there yet (one commit)
Seen by the session with the real program at 20:53: started with the launcher's joined line on a folder
whose catalogue did not exist yet (a first start: the collector makes it a moment later), the window says
"The archive could not be opened. The catalogue file is not there ..." and NEVER tries again: `/api/meta`
stayed 503 after the catalogue existed. A first start would show the owner that page for good.
- `cmd/tgarchive-window/main.go`, `(*session).start` (about line 481): **only when `s.pre != nil` (the
  joined mode: the viewer's address is listened on before the window)** and before `viewer.New`: while the
  catalogue file does not exist, OR `catalog.ReadOnlySchema` on it fails, OR it reports schema 0 (a file
  being made), wait and look again every 500 ms, for at most 60 s in all, ending at once when the context
  ends or the session is stopped (`isStopped`). Then call `viewer.New` exactly as now (after the bound
  too: its failure and its words are today's). While it waits the small page already says "Opening the
  archive..." and reloads itself every second: nothing to change there. Make the wait a small function
  with the clock, the pause and the look as parameters so that its test needs no real time and no real
  file (check how the package's other tests stand in for time).
- Outside the joined mode (`s.pre == nil`) NOTHING changes: no wait, the same words at once.
- **Tests (cmd/tgarchive-window, the package's style):** the file appears after three looks: the wait ends
  and the start goes on; schema 0 twice then a real schema: goes on; never appears: ends at the bound and
  the failure is today's; the context ends during the wait: ends at once; `s.pre == nil`: no look at all.
- Do not touch `internal/viewer`, `internal/window`, `internal/catalog`.

## Rules (as in the first brief)
- Every go command through the lock: `bash /c/Users/trabi/Claude/Projects/Telegram/runs-b7/shell/scripts/gorun.sh <folder> <command...>`.
  Named tests only while working; before the hand-back once: `gofmt -l internal/launcher cmd/tgarchive-window`,
  `go vet` of both packages for Windows and with `GOOS=linux`, the named families you touched in both. NOT
  the whole launcher package (the main session runs it once), no race detector.
- Start NO real program of the app. Invented data only. Never open, list or name a folder outside this
  project folder. Print counts and fixed words only.
- Scripts with the Write tool; no Windows path inside an inline shell string; no persistent `cd`.
- Commit: `git -C <copy> -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message
  ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; then `git -C <copy> push private wip/b-launch`.
- Anything not as written here: STOP and report it.

## Hand back (your final message is the only report)
The head (8 hex), pushed or not; per part: the diff's size per file, what you built in three lines, the
tests' lines, gofmt and the vets; for A 2 which way you took and why; every existing test changed and why;
anything not as written and anything you doubt.
