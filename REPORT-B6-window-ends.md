# Report B6-X: the app's window that ended by itself at the owner's first real start (viewer session B6, 11-16 18:37)

Written down by the main session from the investigator's hand-back (the investigator could not write files).
Brief: `BRIEF-B6-window-ends.md`. Branch: `wip/b-winfix`, head 69e3f3ad, one commit on the main head 78739d59,
pushed; copy `wt-b-join`, clean. Nothing of the owner's app, folders or windows was opened or touched.

## The cause: NOT found in the code; most likely the owner's own close of the window. Inferred, not proven
- **Nothing in the window or the launcher ends the app's window when the viewer's window starts, and the two
  windows do not end each other.** Every place in `internal/window`, `cmd/tgarchive-window` and
  `internal/launcher` that can end a process or touch another one was read: the single-instance rule only
  brings a window of the SAME mode and folder forward (the two modes have different mutexes, window classes
  and engine folders); the window's own kill-on-close job holds only its own process and children; the
  launcher's job around the app's window is released only when that window has ended; Ctrl-C is sent only
  by the launcher's `endProc`, `stopViewer` and `stopWatchdog`, each with its own log line, none reported at
  those ends; nothing posts a close message to another window.
- **Exit code 0 from the window is a close:** `shell_windows.go`, the `wmClose` case of `mainProc`, then
  `RunPages` returns nil and `cmd/tgarchive-window/main.go` exits 0. The launcher reads 0 as "closed by the
  person" (`internal/launcher/present.go` line 494 sets `closed`; line 504 returns with nothing else done):
  by G11's design the launcher, the watchdog, the collector and the viewer go on. That is the owner's
  "quitting doesn't actually exit it".
- **"In the same second as the viewer" is how `begin()` is built** (`internal/launcher/launcher.go` lines 589
  to 600): it always starts the watchdog, then the viewer, then the app's window within about 10 ms, so
  every start with a saved setup shows both in one second, whatever ends the window later.
- **The timeline fits a person:** 18:07:53 Quit on the pages; 18:07:55 a new launcher (a start from outside:
  nothing in the code starts `launcher.Run` by itself; the launcher starts its own program again only as
  its Ctrl-C helper or its folder-box helper, and both exit before `Run`); 18:08:03 the window ends after
  8 s; 18:08:36 Quit; about 18:08:59 a new start; 18:09:03 the window ends after 4 s.
- **Measured: a process killed when its kill-on-close job closes ALSO ends with exit code 0.** So 0 alone
  cannot tell a person's close from a job kill or a clean stop.
- **The cheapest proof: ask the owner** whether they closed the app's window with its X at about 18:08 and
  18:09 (two windows came up at once: the viewer's "Opening the archive..." and the app's). Files in the
  owner's folder cannot settle it afterwards (they are rewritten at every later close).
- **If the owner says no:** the next suspects are the mpv start in the viewer's window (not tested: see
  below) and the real collector; the window's new last line (below) will then name the end at once.

## The reproduction's record (scratch folder, invented archive, its own builds; 8 real window starts, each ended within 46 s; none left)
1. A plain harness in the launcher's way (no console window, a job with no breakaway, no `WEBVIEW2_*`; the
   viewer's window, then the pages window 9 ms later): both ran until ended by the harness at 30 s. NOT
   reproduced.
2. The launcher's own code (`launcher.Run` with its outside lookups stubbed and a stand-in watchdog; ports
   18786 to 18788): the watchdog at 0.39 s, the viewer at 0.45 s, the pages window at 0.46 s; all lived until
   the stand-in watchdog ended at 45 s; the launcher's clean stop then ended both windows with exit 0. NOT
   reproduced.
3. As 2 with the engine folders of the earlier run reused and the launcher outside any job: the same. NOT
   reproduced.
4. The mended window, with the person's close (the message the X sends) posted to the harness's own pages
   window after 8 s: the pages window ended at 8.5 s, exit 0; **the launcher's log had the owner's very
   line: "the app's window ended, exit code 0, after 8 s", and nothing else; the launcher and the viewer
   went on.** The pages window's new last line: "window: closed by the person (its close button, Alt+F4,
   its menu or the taskbar)"; the viewer's at the stop: "window: stopped from outside (Ctrl-C, its console
   closed, or Windows signing out or shutting down)".

## What was changed (69e3f3ad; `internal/window` only; no exit code changed)
- `ending.go`: the first cause of the window's end is noted (four causes, four fixed lines: the person's
  close; a close message from outside; a stop from outside; the program's own end).
- `shell_windows.go`, `pages_windows.go`: the window procedure notes the close messages, both Ctrl-C paths
  note the stop, both modes print the line when their loop ends (into the window's own output, which the
  launcher keeps as `pages-window\window.out.log`).
- Test `TestEndNoteSaysHowTheWindowEnded` (plain Go) and `TestEndInOrder` pass; gofmt and vet clean. No race
  run, no whole-package run, no independent look yet.

## For the pages track (the launcher): what to change, without reading the window's code
- **The person's close:** in `present.go`, `windowEnded`, the branch for an exit code 0 of its own window
  only sets `closed` and returns: the owner's X leaves everything running in silence. Decide with the
  owner: treat it as Quit (stop the watchdog, then the viewer, as the clean end does), or keep running and
  SAY so; write a log line in words. **Do not take 0 alone as the person's close** (a job kill gives 0 too):
  the window's out log now ends with the line that says how it ended.
- **Two windows at once:** at every start with a saved setup the viewer's window comes up in the same
  instant as the app's, and the owner may close the wrong one. Until ONE window exists: start the viewer's
  window only when asked, or after the pages show, or not in front.
- **The second launcher at 18:07:55** came from outside (most likely the owner reopening after Quit).

## What the window could offer for "X quits or asks" (read only; nothing built)
- An exit code of its own for "closed by the person" (a non-zero one, say 4, since stops and job kills give
  0): about 30 lines on each side.
- A flag "ask before closing" with Windows' own question box and fixed words (Yes: a "quit" code, say 5,
  for the launcher to end everything; No: only the window; Cancel: stay): about 80 lines.
- Hiding to the background with a tray icon ("Open", "Quit the app"): about 200 lines, an icon needed,
  hard to test without a real window.

## Not tested, and doubts
- **mpv:** the owner's folder gives the viewer's window an mpv and it starts some seconds in; every run here
  was without mpv (the only copy is in a folder the brief forbade). Nothing read gives mpv a way to close
  another process's window.
- The real collector, watchdog and pages (a stand-in served the pages' mark); a near-empty new catalogue;
  Windows' own compatibility job around a program started from Explorer.
- The taskbar's Close is assumed to send what the X sends. The lines for "the viewer's window closed by its
  X" and "a close message from outside" were not seen in a real window.

## The owner's answer (18:45): "I don't think I closed it. I did see them flicker up, several times."
So the inference above (a close by hand) is most likely WRONG, and the report's "if the owner says no" holds. What the
answer adds: windows came up and went SEVERAL times. Suspects for the next session, in this order, none checked:
1. **The launcher's "bring to the front" start and its job.** To bring its window forward the launcher starts
   `tgarchive-window` again on the same addresses and `-data`; that second start exits 0 at once. If the launcher takes
   that exit for the end of ITS window (or adopts the second start as the window) and then lets go of the kill-on-close
   job around the first, Windows kills the real window, and a job kill ends with exit code 0 (measured). A second
   launcher started while one runs (the owner reopening: 18:07:55, about 18:08:59) asks the first to show its window:
   that is exactly when this path runs, and the three reproductions never took it. Read `internal/launcher/present.go`
   around `windowEnded` and the code that starts the window again, and reproduce with a SECOND start of the launcher
   a second after the first.
2. **mpv's start inside the viewer's window** some seconds in (never tested here: every run was without mpv).
3. The engine restarting (a renderer or browser process ending: the window reloads once, then closes; code 3, not 0,
   so less likely) and Windows' own compatibility job around a program started from Explorer.
**The quickest way to know:** the mend on `wip/b-winfix` makes the window print how it ended; once it is merged and the
folder rebuilt, the next occurrence names its cause in `pages-window\window.out.log`. The pages track has the launcher.
