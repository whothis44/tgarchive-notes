# Brief F18: the app opens on the Overview, never straight onto media (UI track, session U-1, 11-22) — small, usage 90%

You are an Opus coder for the UI track of a private Go project (a Telegram archiver for Windows; the launcher,
`internal/launcher`, starts ONE joined WebView2 window, `cmd/tgarchive-window` + `internal/window`, over the collector's pages,
`internal/server`, and the viewer, `internal/viewer`). Work ONLY in `C:\Users\trabi\Claude\Projects\Telegram\wt-ui-f18` (branch
`wip/ui-startscreen`, cut from main 2b38b2a). Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`,
each message ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `git push private wip/ui-startscreen`.
Keep it small: named tests only, a few pictures, no exploration beyond what the fix needs.

## Rules (binding)
The "Rules" section of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-F1-one-frame.md` binds you (invented data only; the owner's
real window is open: never a screen screenshot, never computer-use; pictures only of your own try window with
`runs-ui-1\shot.ps1`; Go through `ix-tools/env-archiver.sh`, one command at a time; nothing against Telegram; TEMP/TMP outside the
project folder). Ports 18966-18969. The launcher's Go is pages' (P7): your change there is ONE lent commit "Lent to pages
(launcher): …"; the window program's is the viewer track's (B9): ONE lent commit "Lent to the viewer (window): …". Before pushing:
server `-run 'TestAssets|Security|TestEmptyCatalogue'`, viewer `-run 'TestWall|TestHomeDevice|TestLAN|Security'`, the launcher's
and window's named tests you touch.

## The owner's words (11-22)
"Can we change the default start screen to overview? Right now it looks as if it opens directly to media ... want to safeguard the
contents and not expose sensitive contents on a fresh start ... Or add a toggle for default home screen."

## What is there
`internal/launcher/present.go` `windowLineFirst`: a normal start passes `-first viewer` (the library) to the joined window; the
solo case (the collector cannot start) passes `-first viewer` too (U-1's F2).

## The goal
1. **Default: the Overview.** A normal start opens the joined window on the pages' address (the Overview), never the viewer. The
   first paint shows no media (no flash of the library: the window must load the first place directly).
2. **The setting** "Start on": Overview (default) / The library / The last place, stored with the launcher's prefs (the
   launcher's `/api/prefs` and its prefs file, beside `close`, `pair_words`, `links`), drawn in Settings › General with F10's
   segmented control, saved on change. The launcher reads it at each window start.
3. **The last place:** the window program remembers the last top-level address it showed (only of its own named addresses,
   in its own data folder, written on navigation, never a log line with it) and starts there when the setting says so and the
   address is still one it may show; otherwise the Overview.
4. **When the collector cannot start** (the solo window): with "Overview" (the default), open on the launcher's page (its
   notice and "Back to the library"), never the library; with "The library" or the last place, as chosen.
5. **Check every other way in** and fix any that lands on media without a click: tgarchive.exe opened a second time (brings the
   window forward: must not navigate), Open from the notification area (a new window: the setting applies), an alert's toast
   link (goes to its place: none of them is the library: check), the close question's "keep collecting" and back.

## Done means
- Named tests: the launcher's window line per setting (overview, library, last; normal and solo); the prefs route; the window's
  last place written and refused when not one of its addresses; the Settings row posting; the security sets; gofmt, vet.
- Two pictures from your real try window (built with make-folder.sh, a fresh start): the Overview first; Settings › General with
  "Start on". In `runs-ui-1/f18-pictures/`.
- Report: branch head, the lent commits, tests, what each "other way in" does (one line each), what is not done (under 15 lines).

## Added (the owner, 11-22: "Yes, add it")
A one-click switch on the library's head row, "Albums / Files": it flips the viewer's pref `album_tiles` (Library display's "One
tile per album"); toolbar and Settings show the same state; kept as the pref is today; the counts follow. Viewer web only.
