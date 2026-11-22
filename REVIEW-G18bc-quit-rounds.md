# Review of G18's second and third rounds: the window's close and Quit (pages, P7, 2026-11-21)

I reviewed the code independently (Opus, high effort) on the head af4ca40e. I read 17d0bb2a, 4b273cd0, e0794002 and 72bf7ff9 with `git show`, and the two merges (a1ca9e09, 8ea2bebf) against their first parents. I also read the coder's report (rounds 2 and 3), `closeask.go`, `present.go`, `launcher.go` (with G19's run loop), `ui.go` `wait`, `viewerpage.go`, `change.go`, `cmd/tgarchive-open`, and `cmd/tgarchive-window`'s exit codes and joined mode.

What ran (scratch copy `wt-pages-review-g18b-scratch` only):
- Every go command went through `runs-pages-p6/go1.sh`, named tests only.
- `LOCALAPPDATA`, `APPDATA`, `TEMP` and `TMP` were redirected into `zz_env`. `FFMPEG_PATH` was set to an invented path that does not exist.
- All runs used stand-in programs only and invented data.
- **Baseline:** the 11 coder's tests named below all pass on the head.
- **Probes** (`zz_probe_g18bc_test.go`, uncommitted): A to D below, all ran.
- **Plants:** nine plants, each loaded with `-overlay` from `zz_plants/` and run against its named test (question 1).
- **Pages:** dumped by `zz_probe_dump_test.go` and shot with headless Edge (`--headless`, own profile per shot, `file://`, no network) at 1400x900 and 390 wide, light and dark.
  - Edge's smallest window lays out at 492 px. The 390 shots were therefore made through a 390 px iframe, and its own `innerWidth` was checked.
- No real window, close box or browser was put on the screen. Nothing of the owner's program was touched.
- Clean-up: at the end no process names the scratch folder.

## Question 1: the first review's fourteen findings on af4ca40e

"Caught" means the plant (the old behaviour put back by `-overlay`) makes the named test fail. Each was run once.

| # | Mark then | Now | Test that fails without the cure (plant: result) |
|---|---|---|---|
| 1 | must | **cured** (except the orphan page: finding 2 below) | p1, no `endAsk` send: `TestWindowCloseNothingRunsEndsLauncher` FAIL in all 3 subtests ("the launcher did not end"): caught |
| 2 | must | **cured** | p2a, no ask at the following's start: `TestWindowCloseDuringStartAsked` FAIL ("the log never said ... the box answered"): caught. p2b, no end after a refused start: `TestWindowCloseDuringRefusedStartEnds` FAIL ("the launcher did not end"): caught |
| 3 | must | **cured in the pages form; in part in the joined form** (finding 1 below; also minor 6) | p3a, no show at a stop not sent: `TestWindowBoxQuitStopNotSentShowsWindow` FAIL ("started 1 times, waiting for 2"): caught. p3b, no show after 5 s: `TestWindowBoxQuitNotEndedShowsWindow` FAIL ("not shown again"): caught |
| 4 | should | **cured in the pages form; in part in the joined form** (finding 1) | p4, box failure does nothing: `TestWindowPersonCloseBoxFailsKeeps` FAIL ("started 1 times, waiting for 2"): caught |
| 5 | should | **cured** | `TestWindowProgramKnowsTellClose` reads the sources from disk, so `-overlay` cannot plant it. By reading: it parses every non-test file of `cmd/tgarchive-window` for a `Bool*` call with the literal `"tell-close"` and fails without one. It passes on the head |
| 6 | should | **cured** | p6, no `endCloseBox` at the following's end: `TestWindowBoxEndedWithTheRun` FAIL ("the log never said ... the close box was ended"): caught |
| 7 | should (test) | **cured**: plant (b) is caught now | p7, `person := code == 4 \|\| code == 6`: `TestWindowBroughtForwardWhileFollowedAsksNothing` FAIL ("a box, a window or the browser was started"): caught. `TestWindowSecondCloseWhileBoxOpen` exists and passes |
| 8 | minor | **cured for "Show the viewer"; not for the joined window**, now the default (finding 4) | p8, `viewerEnv` alone: `TestViewerShownForFollowedWatchdogHasFFmpeg` FAIL ("the viewer's ffmpeg: 0 characters"): caught |
| 9 | minor | cured (`TestWindowEndedByItselfCountResets`; not planted) | - |
| 10 | minor | left, as the report says (the front start of the viewer is not held) | - |
| 11 | minor | cured: POST `/viewer` answers 303 (`TestViewerPagePostRedirectsAndBackLink`; not planted) | - |
| 12 | minor | cured: the words were read; `wordViewerNotNow` and the box's content say what the code does | - |
| 13 | minor | cured: `answerNone` only; the back link only while followed (`TestWindowRefusalStoppingCollectorNotNamed`; not planted) | - |
| 14 | minor | left, as the report says (sign-out restarts the window once) | - |

## Findings

1. **SHOULD FIX, confirmed (probe B). With the joined window, the default since 9980a21f, the window shown again after the close box opens on the viewer, not on the launcher's page that says why.**
   - **Where:** `present.go` 725-745 (`showAgain`), 263-272 (`windowLine`, `-first viewer` at 271); `launcher.go` 827-849.
   - **The sequence the owner meets:**
     1. The owner closes the app's window while it collects.
     2. Either the box cannot be shown (reason 3), or the owner picks "Quit the app" and the stop cannot be sent (reason 1).
     3. The window comes back.
   - **Probe B:** the window came back in the joined form, `-first "viewer"`, for both reasons. The launcher's page held the words: box-failed true, stop-not-sent true. Those words are only the window's second `-pages` address, so the owner sees the viewer and no reason.
   - **What this does to the owner:**
     - After reason 1 they believe they quit, and the viewer reopens.
     - After reason 3 the words "Stop the program ends it cleanly" and the Stop button are two clicks away, on a page nothing points to.
     - Reason 2 (still stopping after 5 s) and `showPage` after a close (a failed or ended run while the pages are still named) take the same path.
   - **The first review's 3 and 4 are therefore met only in the pages form.** The coder's report says the window "comes back as `ownWindowSpec` gives it then", but no test runs the joined form.
   - **Smallest cure:** for a show-again, pass the place to show first. `checkJoined` accepts any named `-pages` address as `-first`. Use the launcher's page for reasons 1 and 3, and the pages for reason 2 when they answer. Add one joined-form test per reason.

2. **SHOULD FIX, confirmed (probe D). On the "a collector of this folder is left running" page, the person's close ends the launcher without asking. The collector runs on with nothing to see.**
   - **Where:** `present.go` 670-685 (the `default:` branch sends `endAsk`) and `ui.go` 270-282.
   - **The sequence:**
     1. The start finds an orphan collector of this folder (`launcher.go` 655-660; the same page comes from `leftRunning` and `changeEnded`).
     2. The window shows "Stop what is left".
     3. The person closes it.
   - **Probe D:** "launcher ended true (code 1); the orphan collector still runs true; boxes 0; window starts 1; browser opens 0".
   - The same holds, by reading, for a close noted during a start that then finds the orphan. `launcher.go` 328 ends the launcher because `hadPrograms` is false.
   - The comment says "Nothing of the app runs", but a collector of the app runs and talks to Telegram. This is the original "something runs and nothing is seen", one state further on. A second double-click does find it again.
   - **Smallest cure:** in `windowEnded`'s person branch, treat a view in `phaseOrphan` like running programs. Either show the window again on that page, or ask the box with Quit = Stop what is left. Do not end there.

3. **SHOULD FIX, confirmed (probe C). "Quit the app" in the close box during a "Change the folders" stop is lost: the setup comes in a new window and the launcher stays.**
   - **Where:** `launcher.go` 802-806 (`done` with `fw.change`), 818-823 and 827-837.
   - **The sequence:**
     1. The owner confirms "Change the folders". The stop is sent, and a held or slow stop is allowed to "take a while".
     2. They close the window and answer the box "Quit the app".
     3. The quit's stop goes out, but `fw.change` stays true.
     4. The watchdog's 0 goes to `changeEnded`, which returns `resultChange`, and the setup comes.
   - **Probe C:** "launcher ended within 8 s after the box's Quit and the app's end: false; setup shown true; window starts 2; boxes 1".
   - During that stop the box also says "The app is still collecting in the background" (`closeask.go` 39), which is not true.
   - **Smallest cure:** the `quitAsk` case sets `fw.change = false`, so the end is Quit's. Optionally, give the box different main words while a change stops.

4. **SHOULD FIX, confirmed (probe A). The joined window, which now holds the viewer by default, is started without the folder's ffmpeg. The viewer in it then has no ffmpeg on this PC, so no video thumbnails.**
   - **Where:** `present.go` 590. `spawnWindow` gives `windowEnv(l.env.Environ())`, the launcher's own environment.
   - **Probe A:** "joined form true; window FFMPEG_PATH 0 chars; watchdog FFMPEG_PATH 145 chars (folder's ffmpeg 145 chars)".
   - **Why nothing else finds it:**
     - The window program's ffmpeg finder looks in the setting, then `tools` beside the program (`programs\tools`, not the folder's `tools`), then `FFMPEG_PATH`, then PATH (`internal/footage/ffmpeg` `find`).
     - The joined line passes no `-ffmpeg`.
     - On this PC Go does not find ffmpeg through PATH.
   - **Origin:** this came in with the head's 9980a21f, merged in 8ea2bebf. It is the first review's finding 8 again, for the form the owner now runs.
   - **Smallest cure:** start the window with `programEnv(windowEnv(...), lay)`, or pass `-ffmpeg lay.FFmpeg` in the joined line when it is a file. Add a test like probe A.

5. **MINOR, by reading. `quitShowBound` (5 s) is shorter than a normal clean stop, so the window comes back during an ordinary Quit from the box and is ended a moment later.**
   - **Where:** `present.go` 86.
   - **Why 5 s is short:**
     - The collector's own stop allows `StopGrace` 10 s, `SessionGrace` 10 s and `lastTickGrace` 15 s (`collector.go` 409-410, `account.go` 1050).
     - The launcher itself treats a change's stop as slow only after `changeSlowBound` 10 s, with words saying it "can take a while" (`change.go` 45).
   - **The sequence:** Quit in the box; the window disappears; at 5 s it reappears ("Stopping the program", or the viewer in the joined form, finding 1); seconds later the launcher ends it.
   - **Cure:** a bound at or above the collector's graces (for example 20 s), or show it again at 5 s only when the pages report a held stop.

6. **MINOR, by reading and the coder's own test. Reason 1 (the stop could not be sent) sends the shown-again window to the app's pages, which say nothing of it.**
   - **Where:** `launcher.go` 836, `showAgain(true, 1)`.
   - `TestWindowBoxQuitStopNotSentShowsWindow` itself waits for the redirect to the pages. The words `wordStopNotSent` and "Try Stop the program again" are on the launcher's page, which the window leaves.
   - **Cure:** `showAgain(false, 1)`.

7. **MINOR, by reading. In the joined form, an error at the window's end wins over 4. A person's close then reads as a failure: the browser opens and no box is asked.**
   - **Where:** `cmd/tgarchive-window/main.go` 75; `stop()` returns `errClose` when the viewer's close fails, giving exit 1. `present.go` 697-704 maps that to `windowFailed(whyOther)`.
   - **The sequence:** the owner closes the window; the viewer's files do not all close; the browser pops up on the pages with "another error" while the app runs; nobody is asked.
   - This is rare. **Cure:** in the window program, keep 4 when the person's close came first and only log the close error. The launcher has no signal of its own that would tell such a 1 from a real failure.

8. **MINOR, by reading. A 6 from the joined window can mean "a viewer window of its own on the same catalogue was brought forward", not the app's window. The launcher then starts nothing and the app's pages are nowhere.**
   - **Where:** `present.go` 687-688; `cmd/tgarchive-window/main.go` 337-346. Both windows use `<catalogue>\viewer` as their `FirstInstance` folder.
   - **When it happens:** a viewer window of its own outlives a launcher. Nothing at Close, at the person's close with nothing running, or at a failed end calls `stopViewer`, and the viewer is not in the window's job. That viewer exists only after a run where the viewer was not joined, such as a fall to the browser or an unusable viewer address.
   - **What the owner sees:** at the next start the joined window ends with 6 and the old viewer comes forward. The launcher thinks its window is on the screen.
   - **Cure:** a 6 from the joined form while no window of this launcher was open shows the launcher's page in the pages form. Or end the launcher's own viewer at the launcher's end.

9. **MINOR, by reading; the code's comment accepts this. After the joined window falls (1, 3 or 7), nothing gives the owner a viewer, and two things mislead.**
   - **Where:** `present.go` 752-756; `viewerpage.go` 63-66 and 148.
   - `/viewer` still says "The viewer is in the app's window" and offers no "Show the viewer".
   - The pages' Viewer link is the joined address. After a 7, another program answers there.
   - Listed so that it is not lost; the coder's comment says "accepted for now".

10. **MINOR, by reading and the screenshots (e0794002).**
    - (a) The launcher's page follows only the system theme (`@media (prefers-color-scheme:dark)`). The app's pages also honour `data-theme`, so with the pages set to light on a dark Windows the same window changes theme between the two.
    - (b) Input and button borders use `--line-strong`: 1.79:1 light and 1.99:1 dark against the surface. That is below 3:1 for control boundaries. The tokens are shared with `base.css`, so this is a design-wide point, not this commit's.
    - (c) On `/viewer` the "Back to the app's pages" link-button is underlined, unlike every other button.
    - Text contrast is fine in both themes (ink 15-16:1, muted 5.3-7.2:1, links 6.5-8.1:1, primary button 5.1 and 7.6:1, pills 5.3-7:1).
    - Nothing overflows at 390 wide. The setup's long collector path wraps inside its box.

## Checked and sound
- **Lost signals.** Every send to `quitAsk`, `boxFail`, `viewerAsk`, `endAsk` and `ui.acts` is a non-blocking send into a buffer of 1. No goroutine of the launcher can block for ever on a send.
  - `quitAsk`, `viewerAsk` and `boxFail` are drained at each following's start, so a late answer of an earlier run cannot reach a newer one.
  - The answer is also checked against `following` and `followGen`. The box is killed at the following's end (p6 caught).
  - A stale `endAsk` is taken only when the window is still closed by the person at the wait, so it acts only where a fresh close would.
- **Two boxes:** impossible. `closeAsking` is a CAS, and `takeCloseAsk` marks the closed window once. `TestWindowSecondCloseWhileBoxOpen` passes.
- **A close while `following` and `starting` change.** The window's `closed` is set under `w.mu` before `following` is read. `follow` stores `following` before its own `windowClosedByPerson` look. Every order therefore gives at least one ask, and `takeCloseAsk` keeps it to one.
  - A close between the following's end and the start's end is noted. The end's `showPage` then reopens the window, or the launcher quits on `resultQuit`.
- **Exit codes, both forms** (`windowEnded` read against `cmd/tgarchive-window` main.go 56-99):
  - 0 unasked: restarted once, a second within `windowEarly` gives `whyTwice`.
  - 4: asked, noted, or ended.
  - 6: nothing.
  - 3: `whyWebView`.
  - 1, 7 and any crash code (for example 0xC0000005): `whyOther`, the browser opened once with the reason.
  - The launcher's own stops are logged as its own. `-tell-close` ends both forms of the line (`windowLine`), and the window program takes it in its pages mode and its joined mode.
- **G19's run loop:** the refused-start end after a noted close stays inside `!change`. A change's end goes to `setup`, whose `showPage` reopens a closed window. A person's close of the change's setup window ends the launcher (nothing runs). A box open while a change stops is ended with that following. Only "Quit" during the change is lost (finding 3).
- **Baseline and probes:** the 11 named coder's tests pass on the head. The box helper's code path (`runCloseBox`) is unchanged since the first review apart from the handle held and killed at the end.
- **The style commit:** only the 19 colour tokens and the font changed, equal to `base.css` (`TestLauncherStyleMatchesAppTokens` passes per the coder; the dumps show both themes applied).

## Not verified
- Everything that needs a real window: the box's place and focus over the joined window, the joined window's real 4/6/7, and what the owner sees after a show-again (finding 1 was decided from the window's line and the window program's `-first` handling).
- The real collector's stop time, behind finding 5.
- A real `errClose` at the joined window's end (finding 7).
- Finding 8's sequence with real programs.
- The 390-wide look was taken through an iframe, because headless Edge's window is at least 492 wide.
