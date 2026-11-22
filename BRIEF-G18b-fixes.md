# Brief G18b: the review's fixes for G18, the app's window and Quit (pages, P6, 11-16)

You are one Opus coder, fresh to this piece. Work only in the copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-pages-quit`, branch `wip/pages-quit` (head d6a89aaa, pushed,
clean). Read first, whole: `BRIEF-G18-window-ends-and-quit.md` (what the piece is; its rules bind you
too), the coder's report `archiver/docs/progress/pages-quit-REPORT.md`, and the independent review
`REVIEW-G18-window-and-quit.md` in the project folder (its finding numbers are used here; its probes
are in `wt-pages-review-g18-scratch`: read them, take them over as tests where they fit). ONE round.

**The owner, asked whether they closed the window themselves at the first real start: "I don't think I
closed it. I did see them flicker up, several times."** So the windows were ended and started by us
(the path the first round mended), and the owner's "doesn't quit properly" is what this round is about:
**after any close or Quit, the owner must never be left with the app running and nothing to see, nor
with a launcher that runs with no window.**

## 0. First: merge the main head in
`git fetch private` and merge **f1d7127b** (`private/claude/charming-feynman-vm2xia` at that commit; by
its hash) into the branch: a trial merge is clean. It brings the viewer track's window with
`-tell-close` (exit code 4 the person's close, 6 already open, 0 every other clean end; and the
window's last output line says how it ended). From then on the real window knows the flag: take the
`TGARCHIVE_REAL_WINDOW_TELL_CLOSE` switch out of the look and the tests (the flag is always passed).

## To fix (all of these; each with the test that fails without it)
1. **Finding 1 (must): a person's close (4) while nothing of the app runs and no start is under way
   ends the launcher**, exactly as its own "Close the launcher" does (the review names the existing
   path). The setup page, a refused start, an ended run: all three. The existing test that expects the
   launcher to wait on after such a close changes its expectation: say which and why in the report.
2. **Finding 2 (must): a person's close while a start is under way** (before the watchdog is
   followed) is noted, not dropped: when the start comes to follow the programs, the box is asked then
   (the app does run now); when the start ends without programs (refused), rule 1 applies (the
   launcher ends). Never: programs running, no window, nobody asked.
3. **Finding 3 (must): after the box's "Quit the app", the owner sees what happens.** When the stop
   could not be sent, or the watchdog has not ended within 5 seconds (a stop held for a sign-in's
   code, a slow stop), the launcher shows its window again (as "Try the window again" allows a start)
   on what is to be shown now: the pages while they answer (they carry the held Quit's words and "Quit
   now"), else the launcher's page with what it says today ("The stop could not be sent ..."). Once
   only for that Quit.
4. **Finding 4: a box that cannot be shown** (the helper fails): the launcher shows its window again on
   the launcher's page, which says in one line that the window was closed while the app runs and has
   its Stop. Never nothing.
5. **Finding 5: the wrong build order must fail a test, not the owner's start.** A test in
   `internal/launcher` that reads `cmd/tgarchive-window`'s sources (as the package's other
   source-reading tests do, if any; else the plain file) and fails while they do not define the
   `tell-close` flag, with words that say what it means ("the launcher passes -tell-close: the window
   program of this tree must know it"). After step 0 it passes.
6. **Finding 6: the box does not outlive the run it asks about.** When the following of the watchdog
   ends for any reason while the box is open, the helper is ended by its handle; its late answer is
   ignored. (A box that says "still collecting" over a failure page is a lie on the screen.)
7. **Finding 7 (tests):** a test with exit code 6 while the programs ARE followed (the box must not
   open); the "second close while a box is open asks no second box" that the existing test's comment
   claims.
8. **Finding 8:** "Show the viewer" when no start of this launcher set the viewer's environment: use
   `programEnv(l.env.Environ(), lay)` (the folder's ffmpeg).
9. **Finding 9:** the "started again once" count goes back to none once a restarted window has run
   past `windowEarly`; and a second unasked clean end inside that time falls back with words of its own
   (not "another error"): "the app's window ended twice without anyone closing it".
10. **Finding 11:** `POST /viewer` answers with a redirect to `GET /viewer` (303), as the launcher's
    other changes do.
11. **Finding 12 (words, true of the code):** `wordViewerNotNow` and the box's content: with the pages
    in the app's window the viewer runs only when it was asked for; the box says what goes on without
    claiming the viewer does ("the collector and its watchdog go on").
12. **Finding 13:** `refusalNames` names the address only when NOTHING answers there (`answerNone`);
    the `/viewer` page's "Back to the app's pages" link only while the programs are followed.
Left on purpose, one line each in the report: finding 10 (the bring-forward start of the viewer is not
held) and finding 14 (Windows' sign-out restarts the window once).

## Then
- Run `deploy/folder/look-both-windows.sh` ONCE on the merged tree (both real windows, 20 s each; the
  flag now always passed) and say what it printed. Real windows show on the owner's screen: keep it to
  that one run; `LOCALAPPDATA`, `APPDATA`, `TEMP` redirected as the script does; never the owner's
  folder or its ports (8786, 8787, 8788); never end a process you did not start (by its id).
- Named tests only, through the lock script:
  `bash /c/Users/trabi/Claude/Projects/Telegram/runs-pages-p6/go1.sh /c/Users/trabi/Claude/Projects/Telegram/wt-pages-quit/archiver <command...>`
  (nothing over two minutes a command; no whole package, no race detector: the full runs follow by a
  script of mine). gofmt on what you changed.
- Files: `internal/launcher`, `cmd/tgarchive-open` if needed, the launcher's part of
  `deploy/folder/look-both-windows.sh`. Nothing in `internal/window` (it is merged from the head now and
  is the viewer's). Keep out of the setup's code (`settings.go`, `ui.go`'s setup page, `look.go`,
  `folders.go`: another piece of this track changes them and the two must merge).
- No test function removed or renamed (a changed expectation is said). Never a Windows path inside a
  shell string. Never capture the output of a command that starts a hidden or windowed program.
- Commit as you go (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the last line
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`), push `private wip/pages-quit` only. No
  names, paths, ids or counts of anyone's real archive. Leave no process, no window, no scratch folder.

## Hand back (at most 12 lines)
The pushed head (and that it holds f1d7127b); each finding: done, with its test's name, or left and
why; the changed expectation of finding 1; what the look printed; test functions added and removed; the
named tests run; what is NOT verified. Add a section "The second round" to the report on the branch.
