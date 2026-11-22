# Review of G18: the app's window, the close box, the Viewer link (pages, P6, 11-16)

Independent review (Opus, high effort) of `wip/pages-quit` d6a89aaa against 78739d59, read-only on
`wt-pages-quit` (its `git status` stayed clean). Probes by `go test -overlay` from
`wt-pages-review-g18-scratch` (`zz_review_probe_test.go`, `zz_review_real_test.go`, `plants/`), every go
command through the track's lock script, LOCALAPPDATA/APPDATA/TEMP/TMP redirected to scratch, ports from
27860 or random free ones, invented data, stand-in collector and watchdog. No process left (none with
its program under the scratch folder at the end).

## What ran
- Stand-in probes: `TestReviewCloseNothingRuns`, `TestReviewCloseDuringStart`, `TestReviewBoxQuitStopNotSent`,
  `TestReviewBoxOpenWhenRunEnds` (all ran, numbers below).
- The real close box: `cmd/tgarchive-open` built to scratch, started as `-ask-close`, its window
  read by Windows' own calls (class, title, children, style), then answered by message.
- Real windows with the viewer track's window program (`wip/b-winfix` b0c1c970, exported with `git
  archive`, built in scratch) and `-tell-close`: the person's close made as the close button makes it
  (WM_SYSCOMMAND SC_CLOSE), the close box a stand-in: `TestReviewRealPersonCloseRuns`,
  `TestReviewRealPersonCloseNothingRuns`.
- The HEAD's window program (built from the copy) started with `-tell-close`: exit 1 at once, one line.
- The coder's look, once: `deploy/folder/look-both-windows.sh` (without `-tell-close`): "look: ok".
  `TestRealBothWindowsAfterRetry`: one start of the app's window, both windows run and show 20 s, the
  viewer's window higher, the foreground another program's. `TestRealBothWindows`: both run and show
  20 s, the app's window higher; "Show the viewer" again: the start to the front ended at once with 0,
  the viewer's window ran on; after Quit both ended.
- Plants (each the coder's named tests under one overlay): (a) 0 taken as the person's close: caught
  (`TestWindowEndedByItselfStartedAgainNoBox`: "started 1 times, waiting for 2"); (b) the box opened on 6:
  **not caught** (`TestWindowBroughtForwardStartsNothing` passes); (c) the box's Quit not sent to the
  watchdog: caught (`TestWindowPersonCloseAsksAndQuits`: "the launcher did not end"); (d) the viewer
  started with the programs in the window: caught (`TestViewerPageShowsTheViewerWindow`); (e) the pages'
  address named after programs ran: caught (`TestWindowAskSecondStartShowsFirstsWindow`,
  `TestWindowClosedThenCrashShown`).

## Findings

1. **Must fix. The person's close while nothing of the app runs leaves the launcher running with no
   window and no page.** Confirmed twice. Stand-in (a refused start, window code 4): "launcher still
   runs 4 s after the person's close with nothing running: true; window starts 1; browser opens 0;
   boxes 0". Real window of the viewer's piece: "window exit code 4; launcher still runs 4 s later true;
   window starts 1; browser opens 0; boxes 0". The same holds on the setup page (the existing
   `TestWindowAskDuringSetup` closes the setup's window and finds the launcher still waiting) and after
   an ended run. `windowEnded` sets `closed` and returns when `following` is false; `run` and `setup`
   then wait on `ui.wait()` forever. The owner sees nothing, the launcher holds its port, and the only
   ways out are a second double-click and "Close the launcher". This is the owner's "doesn't quit
   properly" itself. The fix: a 4 while no programs run and no start is under way ends the launcher as
   its own Close does (ExitStopped). `another()` already does this with `windowClosedByPerson`.

2. **Must fix. A close during a start is not asked, and the app then starts with no window.** Confirmed
   (stand-in): the window was closed (code 4) while the start looked up the public address after Try
   again, and then: "boxes 0; watchdog runs true; window starts 1; browser opens 0; launcher runs true".
   `following` becomes true only at the top of `follow`. Before that, a start can take up to about 25 s
   (the checks, the public lookup bounded at 20 s, the watchdog's start), and a person's close in that
   time is kept as "closed". `openPages` then starts no window (by design: "one closed by the person
   stays closed"), so the collector runs and nothing shows. The fix: treat a start under way like
   running programs. Either ask at once, or note the close and ask when `follow` begins (or end the
   start, if that is the owner's answer).

3. **Must fix. After the box's "Quit the app" the owner may see nothing while the app runs on.**
   Confirmed for a stop that cannot be sent (CtrlC refused for the watchdog only): "launcher runs true;
   watchdog runs true; window starts 1; browser opens 0; page says stop not sent true". The page with
   "The stop could not be sent. Try Stop the program again." is shown in no window, so the app runs on
   for good and the owner believes it quit. Plausible (read, not run) for a stop held for a sign-in:
   the collector holds a Ctrl-C stop while a sign-in waits for its code (`stopheld.go`, `SignInHold`
   default 15 minutes), and the only place to type the code or "Quit now" is the pages, which are in
   the closed window. The same applies to a slow clean stop. The fix: after the box's Quit, when the stop
   was not sent, or the watchdog has not ended within a few seconds, show the window again
   (`closed`→`again`, `showPage`) on the launcher's page.

4. **Should fix. A box that cannot be shown changes nothing.** The app runs on with no window and the
   person was not asked (`TestWindowPersonCloseBoxFailsKeeps` makes this the rule). This is the original
   complaint, met by a helper failure. Rather than nothing, show the window again on the launcher's
   page, which says the window was closed and has Stop. Plausible (read).

5. **Should fix. The merge order is not guarded.** Confirmed: the HEAD's window program started with
   `-tell-close` ends at once with 1 (one line of output, the flags error). With this branch merged
   before `wip/b-winfix`, every start of the app's window fails at once. Each start opens the browser
   with "another error (...window.out.log...)", "Try the window again" fails the same way, and the
   bring-forward start fails too. That is the owner's "still runs in a browser", with a reason that is
   not the true one. Suggest a launcher test that reads `cmd/tgarchive-window/main.go` and fails while it
   has no `tell-close` flag, so the merge's full runs refuse the wrong order.

6. **Should fix. The box outlives the run it asks about.** Confirmed: with the box open, the collector
   ended (code 3). The failure page came up in a new window (window starts 2) while the box was still
   unanswered, still saying "still collecting". Its "Quit the app" is then dropped (`following` false),
   so the owner asked to quit and the launcher stays on the failure page. End the helper by its handle
   when `follow` ends, or take a late Quit as the launcher's Close.

7. **Should fix (test).** Plant (b), "the box opened on 6", survives the coder's tests:
   `TestWindowBroughtForwardStartsNothing` ends with 6 before `follow` starts, so the box would not be
   asked anyway. A test with a 6 while the programs are followed (for example the second start's front
   start adopted, or a stand-in "exit6-go") would catch it. Also, `TestWindowPersonCloseBoxFailsKeeps`
   says "a second close while a box is open asks no second box" but does not test it.

8. **Minor (should, small). "Show the viewer" after following a watchdog that was found running uses
   `viewerEnv` from no start.** It is nil on a launcher's first start, so the viewer gets the launcher's
   own environment without `FFMPEG_PATH` (on this PC Go cannot find ffmpeg through PATH, so there would
   be no video thumbnails). Use `programEnv(l.env.Environ(), lay)` when it was not set. Plausible (read).

9. **Minor. The restart after an unasked 0 is once per launcher run, never reset.** A second such end
   days later goes to the browser with the reason "another error" (whyOther) although the window ended
   cleanly. No loop is possible: the second 0 falls back and the fallback stops further starts. Consider
   resetting the count once a restarted window has run past `windowEarly`, or giving that fallback words
   of its own. Read; the stand-in table (`exit 0 twice`) shows the bound.

10. **Minor.** The start to the front for the viewer is not held: it is not `l.viewer`, not in a job,
    and not waited for. If the open viewer's window ends in that instant, that start becomes the viewer
    on the screen, and Quit's `stopViewer` does not end it. Rare; plausible.

11. **Minor.** POST `/viewer` answers 200 with the page, not a redirect (the launcher's `/act` uses
    303). A reload of that page re-posts and starts or fronts the viewer again.

12. **Minor (words).** `wordViewerNotNow` says "the viewer opens once it runs". With the pages in the
    app's window that is not true: it waits for "Show the viewer". The box says "the collector, the
    watchdog and the viewer go on", but with the pages in the window the viewer runs only if it was
    asked for.

13. **Minor.** `refusalNames` also names the address when the collector there is stopping
    (`answerStopping`). That is broader than the setup's rule (`answerNone` only), although the comment
    calls it "the setup's rule". After `findLeft` found nothing of this folder, a stopping collector
    there is another folder's (the mark does not say which). The risk is low: the window is sent there
    only after `follow` sees the pages' mark, and the look is bounded at 3 s, so a hang is not possible.
    But the `/viewer` page always shows "Back to the app's pages", even when no pages run. Suggest
    `answerNone` only, and the link only while the programs are followed.

14. **Minor.** At Windows sign-out the viewer's piece ends the window with "stopped from outside" (0).
    The launcher then starts it again once during the sign-out. Plausible; harmless in practice.

## Checked and right
- The exit codes as built match the viewer track's contract on b0c1c970 (4, 6, 0, 1, 3; `-tell-close`
  in pages mode). Only 4 is taken for the person's close. 6 starts nothing. The launcher's own stop (an
  event, its end) is logged as its own. An unasked 0 restarts the window once, then falls back. 1, 3 and
  other codes fall back. A bring-forward start's code is only logged. An adopted front start carries
  `-tell-close` and is read like any other. No path starts windows in a loop or a second window beside
  a running one (`startWindow` checks `proc` running, `fell`, `ending` and `again` under the lock).
- With the real program, the close button's message gives 4, and the box is asked once ("the box
  answered 10" with a stand-in Keep) while the app runs.
- The retry fix: a refused start's Try again keeps the same window (the stand-in test and
  `TestRealBothWindowsAfterRetry`: one start). The address is not named after programs ran (plant e
  caught). Another program answering there is not named (`answerOther`). The setup's own path is
  unchanged.
- The viewer: it is not started with the programs while the pages are in the app's window, on every
  path through `begin` (plant d caught). A failed window or a change to the browser leaves it for "Show
  the viewer", which works there too. GET `/viewer` acts on nothing. The POST checks origin,
  `Sec-Fetch-Site` and the run's token, and is handed to `follow`, the only goroutine that starts or
  stops the viewer. What it starts is `viewerSpec`'s program and line. The second start of the viewer
  window program finds its open window (FirstInstance on the same data folder) and ends with 0 (real
  run). `-viewer-url` is only `http://<loopback launcher address>/viewer`. The server takes only that one
  path, and the Settings field still refuses a path. The pages' header link becomes ".../viewer/"
  (accepted), the server's look at it is a TCP connect to the launcher's port, and a link to a named
  address opens in the same window. Settings says "set by the program's launcher", which is true.
- The close box helper reads no settings, writes no file and opens no listener. It shows as Windows'
  task dialog (real: class #32770, title "tgarchive", DirectUIHWND and the two buttons "Keep it running"
  and "Quit the app"), it is topmost, and it answers 11 for Quit and 10 for a close without a choice.
  From a background start in this probe it was not given the foreground; at the owner's close, the
  viewer's piece hands the foreground on (ASFW_ANY), which was not tried with a person's real click. It
  is held in a kill-on-close job, waited for on its own goroutine without locks, and one at a time
  (CAS). The packed TASKDIALOGCONFIG offsets match commctrl.h for 64-bit (160 bytes).
- Tests that meant the person's close by 0 and were moved to 4 or 6 keep their meaning
  (`TestEachFailureWordsOnce`, `TestWindowAskSecondStartShowsFirstsWindow`, `TestWindowAskDuringSetup`,
  `TestWindowAskThreeDoubleClicksBound`, `TestWindowAskRefusedFromABrowser`,
  `TestWindowClosedThenCrashShown`, `TestWindowNeverLoops`). A window that always ends with 0 is covered
  by the new "exit 0 twice" case. No test function was removed or renamed.

## Not checked
The owner's own screen and a person's real click: whether the box comes up in front with the
foreground after a real close; the box's text beyond its buttons; the real collector's handling of a
second Ctrl-C during a held sign-in stop; the owner's 18:05 log lines
(`OWNER-RUN-1805-launcher-lines.txt` is not in the folder), so whether point 1's cause was the retry path
rests on the coder's reproduction.

may be listed after these fixes: 1, 2, 3, 4
