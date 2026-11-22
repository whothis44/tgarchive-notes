# Brief B8-L1: the launcher starts the app as ONE window (a lent commit in pages' `internal/launcher`; session B8, 11-16 20:36)

**The project's first rule applies to you too: routine steps by a script, not call by call.** You are ONE Opus
coder. A small change in a careful package: read before you write. Hand back commit-ready and pushed.

## Where
- Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-b-launch` (branch `wip/b-launch`, cut from the main head
  e9413e4e; clean). Work only there. Module: `archiver/`.
- You may change ONLY `archiver/internal/launcher` (code and tests). It is the pages track's package, lent for
  this one commit by the integrator's word (board message 183): change as little as the piece needs, keep
  its style and its comments' way of speaking, rename nothing, restructure nothing. Do not touch
  `internal/window`, `cmd/...`, `internal/server`, `deploy/`.

## What exists (read these first, whole)
- `internal/launcher/present.go` lines 14 to 46 (how the launcher shows things), `windowArgs` (181),
  `ownWindowSpec` (193), `rescope` (228), `startWindow` (about 400 to 470) and what it does with each end of
  its window; `start.go` `collectorArgs` (154), `viewerSpec` (174); `launcher.go` 560 to 600 and 725 to 760
  (where the watchdog and the viewer are started); `settings.go` (`Viewer`, `PagesOpen`, `ViewerAddr`,
  `inWindow`); `folder.go` (`Layout`).
- The window program (`cmd/tgarchive-window`, the viewer track's; do not change it) has since today a JOINED
  mode: the viewer's pages and the app's pages in ONE window:
  `tgarchive-window.exe -db <catalogue> -library <library> -staging <staging> [-mpv <mpv.exe>] -addr 127.0.0.1:<viewer port> -pages http://127.0.0.1:<pages>/ [-pages http://127.0.0.1:<launcher>/] -first viewer`
  (`-first viewer`: the viewer's page is shown first; the FIRST `-pages` address is where the viewer's
  "Overview" entry leads; `-data` not given: the viewer's folder beside the catalogue, where its thumbnails
  are). Without `-tell-close` its exit codes are as the launcher knows them (0 closed by the person or
  already open; 3 no window; 1 another error) plus 7: the viewer's port (`-addr`) is taken.
- Today the launcher, with `viewer` "window" and `pages_open` "window", starts TWO windows: its own
  (`-pages L [-pages P] -data <folder>\pages-window`) and the viewer's (`viewerSpec`: `-db -library -staging`),
  and gives the collector no `-viewer-url` (only the browser kind of viewer gets one).

## The change: for `viewer` "window" WITH `pages_open` "window" (the defaults), and only then
1. **The collector gets `-viewer-url http://<ViewerAddr>`** (`collectorArgs`), as the browser kind does.
2. **No separate viewer window is started** (`viewerSpec` answers "none" for this case; check every caller:
   nothing may then say or log that a viewer failed, and the launcher's own page must not claim a second
   window).
3. **The launcher's window, while the app's pages are NAMED to it (`ownWindowSpec` gives two addresses), is
   the joined window:** its line is
   `-pages <the app's pages> -pages <the launcher's page> -db <lay.Catalog> -library <lay.Library> -staging <lay.Staging> [-mpv <lay.MPV> when it is a file] -addr <s.ViewerAddr> -first viewer`
   and NO `-data` (the viewer's default folder) and NO `-tell-close` (on this head the launcher takes any
   end but a clean 0 as a failure: that stays G18's). **The app's pages come FIRST in that line** (the
   viewer's "Overview" leads to the first `-pages` address); keep whatever list the launcher compares in
   `rescope` consistent with what was really started (a window's addresses are fixed for its life).
   **While the pages are NOT named** (the setup page, a refusal, after the programs ended: one address,
   the launcher's own) **the window is started exactly as today** (`-pages L -data <folder>\pages-window`):
   the catalogue may not exist then. The existing restart at `rescope` (the addresses changed) is what
   turns one into the other; build nothing new for it.
4. **If the viewer's address cannot be used** (`ViewerAddr` not 127.0.0.1 with a port, port 80, or the same
   as the pages' or the launcher's): do not start a half-joined window; fall back to exactly today's
   behaviour for all three points (two windows, no `-viewer-url`) and say why in one log line with fixed
   words. `settings.go`'s check may already refuse some of these: read it and do not duplicate.
5. **Every other combination of the two settings does exactly what the head does**: `viewer` "browser" or
   "none"; `pages_open` "browser"; the window having failed in this run (`l.win.fell`: the browser is used:
   then the collector still has `-viewer-url` from its start and no viewer runs: that is accepted tonight,
   write it in a comment where the fallback is made, and tell me in the hand-back what the owner would see).
6. Exit 7 and exit 3 of the joined window: build NOTHING new for them. Read what the launcher does with
   each today (3 is known to it; 7 is "another error") and tell me in the hand-back, one line each.

## Tests (in `internal/launcher`, in the package's own style, with its stand-in programs)
- The three functions' lines for every combination: the exact argument list of the collector, whether a
  viewer is started, the exact window line when the pages are named and when they are not; the fallback
  of point 4.
- One test through the launcher's start with the stand-ins (find the nearest existing one and follow it): a
  start with the defaults starts the watchdog line with `-viewer-url`, ONE window program and no viewer;
  after the pages are named, the running window's line is the joined one; after the programs end, the
  window on the launcher's page alone is today's line.
- **The existing tests must pass UNCHANGED for every other combination.** A test that asserts today's
  behaviour for the defaults (two windows) changes with the piece: change it openly and list each such
  test in the hand-back with one line on why. Remove no test function.

## Rules
- Every go command through the track's lock:
  `bash /c/Users/trabi/Claude/Projects/Telegram/runs-b7/shell/scripts/gorun.sh <folder> <command...>`.
  While working: named tests only (`go test ./internal/launcher -count=1 -run '<names>'`). Before the
  hand-back, ONCE: `gofmt -l internal/launcher`, `go vet ./internal/launcher`,
  `GOOS=linux go vet ./internal/launcher`, and the package's named families you touched. NOT the whole
  package (the main session runs it once), no race detector.
- Start NO real program of the app: no launcher, no collector, no window (the main session makes the look
  with the real programs afterwards). Only the package's tests with their stand-ins.
- Invented data only; never open, list or name the owner's folders; print counts and fixed words only.
- Scripts are written with the Write tool; never a Windows path inside an inline shell string; no
  persistent `cd` (use `git -C` and full paths).
- Commit: `git -C <copy> -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message
  ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push:
  `git -C <copy> push -u private wip/b-launch`. One commit (two if the tests are large).
- If anything is not as this brief says (a function gone, a caller that makes the piece larger than about
  120 lines of code, a test of another combination that cannot pass unchanged): STOP and report it.

## Hand back (your final message is the only report)
The head (8 hex), pushed or not; the diff's size per file; the exact three lines as built (the collector's
added flag, the joined window's line with its order, the plain line); every existing test you changed and
why; the test lines, gofmt, both vets; what the launcher does today with the window's exit 3 and exit 7 and
with the browser fallback in the joined case, one line each; where it will meet pages' G18 (the functions
and lines you touched in `start.go` and `present.go`); anything not as written and anything you doubt.
