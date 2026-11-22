# Brief: the independent review of G18's second and third rounds (the window's close and Quit) (pages, P7, 2026-11-21)

Read first: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-P7-review-rules.md` (the house rules: binding;
note: NO real window and no close box on the screen this time: the owner is at the PC).

**The piece:** G18, "a way to quit the app": closing the app's window asks "Keep it running" or "Quit the
app"; no state left running with nothing to see. Merged as 18c1e2c0. Its FIRST round (`wip/pages-quit`
d6a89aaa) had an independent review: `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-G18-window-and-quit.md`
(3 must fix, 4 should fix, 7 minor). **The rounds after it were never reviewed:** on the branch, first
parent, after d6a89aaa: 17d0bb2a (G18b: the review's fixes; brief `BRIEF-G18b-fixes.md`), 4b273cd0 (two
window tests), 8ea2bebf (merge of the head 9980a21f: the app as ONE joined window), e0794002 (the launcher's
page in the new colours), 72bf7ff9 (the look starts the joined window too; brief `BRIEF-G18c-take-the-head.md`),
and a1ca9e09 (a merge of f1d7127b, the window's `-tell-close`). Read each non-merge commit with `git show`,
and the two merges' resolutions (`git show --cc` / `git diff <merge>^1 <merge>`). Report of the coder:
`archiver/docs/progress/pages-quit-REPORT.md`. The original asks: `BRIEF-G18-window-ends-and-quit.md`.
The code as it is on af4ca40e is what counts (G19 merged after: it touched `launcher.go`'s run loop).
Packages: `internal/launcher` (`closeask.go`, `present.go`, `launcher.go`, `page.go`), `cmd/tgarchive-open`,
the window's exit codes in `internal/window`.

**Where:** your scratch copy `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g18b-scratch`
(detached at af4ca40e, already made). Report to `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-G18bc-quit-rounds.md`.

## Questions, in this order

1. **Each of the first review's fourteen findings:** cured on af4ca40e, cured in part, or not; for each must
   and should fix, the test that fails without the cure (plant the old behaviour back with `-overlay` and
   run that test by name: caught or not). Finding 7 (plant (b), "the box opened on 6", survived the tests):
   is it caught now?
2. **Signals.** The second round added a generation number tying the box's answer to the run it asked
   about, a box ended with its run, a close during a start noted and asked later. Trace every channel and
   goroutine between the window's end, the box, the watchdog and the run loop: can a signal be lost (a
   buffered channel of 1 written twice, a select with a default that drops, a send after the reader left),
   can two boxes be open at once, can a stale box's Quit end a newer run, can the launcher block for ever
   on a send? Decide the risky ones with a stand-in probe (the coder's stand-in watchdog and collector,
   fake window ends by exit code), not by reading alone.
3. **The joined window (8ea2bebf and 72bf7ff9).** With the viewer and the app's pages in ONE window: every
   exit code the window can give (`internal/window`'s list, 0, 4, 6, 7, a crash code) mapped to what the
   launcher does; exit 7 "falls back as the head does": to what, and does the owner then see a window?
   `-tell-close` in both forms of the window's line. The launcher's `/viewer` page in the joined case.
4. **The close with nothing running and the close during a start** (findings 1 and 2 before): every order of
   a start, a close, a box's answer and the watchdog's own end you can build with stand-ins: the end state
   is never "something runs and nothing is seen" and never "the launcher runs with nothing to see".
5. **The merge with G19 on the head** (`launcher.go`'s run loop, the change of folders): can "Change the
   folders" and the close box meet (a box open while a change stops the app; a Quit during a change)? What
   happens, by a probe if cheap.
6. **The style commit e0794002:** the launcher's page in both themes, headless screenshots of its pages
   (the setup page, the running page) at 1400x900 and 390x800, dark and light; look at them yourself;
   contrast, overflow.
7. Anything else in these rounds you judge a defect: its own number.
