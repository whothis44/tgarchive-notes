# Brief: the independent review of G19's fix round (changing the folders) (pages, P7, 2026-11-21)

Read first: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-P7-review-rules.md` (the house rules: binding).

**The piece:** G19, "Change the folders" on the launcher's page; the setup looks at each folder before it
saves (numbers only) and asks a second yes that belongs to what the page showed; folders saved by an
earlier build are looked at before any start; a "Program" entry in the shell's list and a region on
Settings; lent lines in the collector for `-launcher-url`. Merged as 70b0c7ef. Its first round
(`wip/pages-folders` a281c273) had an independent review:
`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-G19-change-folders.md` (1 must fix, 5 should fix, 5 minor).
**The fix round was never reviewed:** first parent after a281c273: b8e7eec0 (G18 merged in; "Program" in the
shell's list), 0bfdc914 (finding 1), 82735c18 (2), e5c31c69 (5), 192c9689 (3), 7665014a (4 and 7),
1a498355 (6), e6bc8a69 (the route in the empty-catalogue test), 32c5d12e (merge of the head 18c1e2c0).
Read each with `git show`; the brief of the round: `BRIEF-G19b-fixes.md`; the coder's report
`archiver/docs/progress/pages-folders-REPORT.md` and `pages-folders-OWNER-STEPS.md`. The code as it is on
af4ca40e counts. Packages: `internal/launcher` (`change.go`, `look.go`, `folders.go`, `choose.go`,
`launcher.go`, `settings.go`, `ui.go`, `page.go`, `start.go`, `words.go`), `internal/server`
(`launcherlink.go`, the route `GET /api/program`), `internal/appshell` (the "Program" entry), the
collector's lent lines.

**Where:** your scratch copy `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g19b-scratch`
(detached at af4ca40e, already made). The first reviewer's probes are in
`C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g19-scratch` (read them, copy what helps; do not
edit that folder). Report to `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-G19b-folders-fixes.md`.

## Questions, in this order

1. **Each of the first review's eleven findings:** cured, cured in part, or not, on af4ca40e; for each
   cured must or should fix, the named test that fails without its cure (plant the old behaviour with
   `-overlay`, run that test by name: caught or not). The first reviewer's mutants `m1` to `m10`: re-run
   the ones that still apply.
2. **Finding 1's cure in detail** (`folderSees`, the form carrying what the look saw with the yes,
   `yesCovers` at the save: a yes on "cannot be looked at" counts only while the save cannot look either;
   a yes on N things covers N or fewer). Every way the owner's yes can cover more than the page showed: a
   folder that grows between the look and the save, a folder replaced by another of the same path, a yes
   from an older page (two tabs, the back button), a form edited by hand, a share that answers the look
   and not the save or the other way round, a number that overflows or is negative. Probes.
3. **The settings file's two new fields:** an older build reading a file this build wrote (start the
   head's predecessor's settings reader on such a file in a probe, or read its code: does it refuse,
   ignore or lose data?), and this build reading an older file (finding 3's cure: what exactly is looked
   at before anything starts, and what the owner sees when a saved folder now looks wrong). **The owner's
   own settings file is this case today:** say by reading what the owner's program did at its first start
   after the rebuild, without touching the owner's files.
4. **"Change the folders" only when nothing of this folder can still run** (finding 5): every refusal and
   state on which the link is offered: is any where a collector, a watchdog, the viewer or the window of
   THIS folder may still run? And the "Stopping" view's bound (finding 6): what the owner sees when the stop
   never ends; a way back.
5. **The data folder's second yes** (finding 4) and the words (7): the same checks as question 2 for the
   data folder.
6. **The "Program" entry and `GET /api/program`:** who can reach the route (the same gate as the pages'
   other routes?), what it returns (no path, no name: numbers and fixed words only?), and that without
   `-launcher-url` the pages are as before (finding 10).
7. **Headless look:** the launcher's setup page and its change view (a stand-in launcher on invented
   folders in your scratch copy), 1400x900 and 390x800, dark and light: look at the images yourself.
8. Anything else in the round you judge a defect: its own number.
