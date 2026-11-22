# Brief G18d: the fixes from the review of G18's later rounds (the window's close and Quit) (pages, P7, 2026-11-21)

You are the coder of this fix round: Opus 5.5 at high effort. You hand back commit-ready work on your branch.

## The house rules (binding)
Read `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-P7-review-rules.md`: its privacy, safety and go-command
rules bind you too (invented data; never touch the owner's running program, folder, settings or `E:`; no
window on the owner's screen: stand-in programs and headless only, `LOCALAPPDATA`, `APPDATA`, `TEMP`, `TMP`
redirected; every go command through `runs-pages-p6/go1.sh`; named tests only; no race detector). Ports
`:0` or from 28000 up. Long commands in the background (your shell tool stops at 10 minutes).
Commits: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; ONE COMMIT PER FINDING, each with the named test
that fails without it; push after each: `git push private HEAD:wip/pages-quitfix` (only that branch; no
merge, no tag, no `git stash`). New log lines use constant format strings.

## Where
`git -C repo-archiver worktree add -b wip/pages-quitfix ../wt-pages-quitfix af4ca40e` from the project
folder. Module in `archiver`. Report: `archiver/docs/progress/pages-quitfix-REPORT.md`.

## Read first
1. The review: `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-G18bc-quit-rounds.md` (whole). Its probes are
   in `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g18b-scratch` (files `zz_probe_*`): copy them
   into your tests where they decide a finding (renamed as real tests).
2. The earlier review `REVIEW-G18-window-and-quit.md` and the coder's report
   `archiver/docs/progress/pages-quit-REPORT.md`; the code in `internal/launcher` (`present.go`,
   `launcher.go`, `closeask.go`, `change.go`, `viewerpage.go`, `ui.go`).

## What to fix (in this order)
1. **Finding 4 first (the owner's window today): the joined window gets the folder's ffmpeg** (start it with
   the program environment the watchdog gets, or `-ffmpeg` in the joined line when the folder has the file;
   say which and why). A test as probe A.
2. **Finding 2:** a person's close on the "a collector of this folder is left running" page (and on any
   page whose phase means something of this folder still runs) never ends the launcher without asking:
   show the window again on that page or ask the box with Quit = stop what is left. Tests for the page and
   for a close noted during a start that then finds the orphan.
3. **Finding 3:** the box's "Quit the app" during a "Change the folders" stop is the end (the change is
   dropped); the box's words while a change stops are true (not "still collecting").
4. **Findings 1 and 6:** a show-again in the joined form opens on the place that holds the reason (the
   launcher's page for reasons 1 and 3; the pages for reason 2 when they answer); one joined-form test per
   reason.
5. **Finding 5:** the show-again bound at or above the collector's stop graces (say the number and why),
   or shown at 5 s only when the pages report a held stop.
6. **Finding 8:** a 6 from the joined form while no window of this launcher was open is not taken as "the
   app's window is on the screen" (the review's two cures: pick one and say why).
7. **Finding 9:** `/viewer` after the joined window has fallen says the truth and offers what can be done.
8. **Finding 10 a and c:** the launcher's page honours the pages' `data-theme` if the window carries it
   (read how the pages set it; if the launcher's page cannot know it, say so and leave it); the link-button
   on `/viewer` styled as the other buttons. 10 b (the shared tokens' control borders) is NOT yours: note it.
9. **Finding 7 is in `cmd/tgarchive-window` (the viewer track's program):** make it ONE commit of its own
   whose subject starts "Lent to the viewer (window):", the smallest change (keep 4 when the person's close
   came first; log the close error), with its test; the viewer session reads it before it is listed.
**Later messages from me may add the fixes of the G19 review (same package, same branch): take them in
the order given.**

## Hand back
The branch pushed, the copy clean, the report: per finding what was done, its commit, its test, and what a
person now sees; tests added (none removed or renamed without a word); what is not verified (anything
needing a real window). Your final message: the branch's head (8 characters), the report's path, one line
of what is not verified. Nothing else.
