# Brief: the independent review of G16 (the cap on new mirrors in 24 hours as a Settings row) (pages, P7, 2026-11-21)

Read first: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-P7-review-rules.md` (the house rules: binding).
One difference from them: G16 is NOT merged; it is the branch `wip/pages-cap` da8c1c3d (it holds the main
head af4ca40e since de2045c9; da8c1c3d adds two stand-in methods to a head test). Findings are on that branch.

**The piece:** the owner, 11-16 13:28: "Why are the caps so low? Can we adjust them higher, and make them
configurable?"; 17:58: "The daily mirror cap should be 20, but the maximum of 50 is dumb. It should be
higher if needed, configurable." The stored setting exists (M12, 44a6d7b7, 1 to 50); the mirror track's M13
(`wip/mirror-capmax` c7ea2d40, listed, not merged) raises the maximum to the account's 500 channels. G16 is
the Settings page's row for it: the seam `Mirrors.NewPerDay` / `SetNewPerDay`, the route
`POST /api/mirrors/new-per-day`, the settings answer's `new_per_day*` fields, the switch's cost words with
the cap in force, the row in `mirrorsettings.js`, the words in `mirrorwords.js`, the lent collector lines
(1111450a), the demo fake. Diff: `git diff af4ca40e da8c1c3d` (the piece's own commits: 9542d980,
1111450a, e0fe666c, da8c1c3d). The coder's report: `archiver/docs/progress/pages-cap-REPORT.md`.

**Where:** your scratch copy, made by you, one command from the project folder:
`git -C repo-archiver worktree add --detach ../wt-pages-review-g16-scratch da8c1c3d`.
Report to `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-G16-cap-row.md`.

## Questions, in this order
1. **With M13.** In your scratch copy, `git merge --no-commit --no-ff private/wip/mirror-capmax` (a local
   trial only; never commit or push it; `git merge --abort` after): does it merge, does it build, and do
   G16's named tests and M13's named tests pass together? What the row shows with Max = 500 (the label, the
   field's `max`, the range words), and with Max 0 or not above Min.
2. **The route.** Body parsing (`n` only as a JSON whole number: try every form you can think of, big
   numbers, -0, 1e3, 20.0, duplicate keys, a body over a size limit, wrong content type); the guard (the
   same refusal of a request from elsewhere as the other settings routes; `TestMutationsRefusedFromElsewhere`
   names it: check by a probe, not by the list); the run's flag ("not settable") checked before anything is
   written; a value outside the door's bounds: the words, and nothing stored.
3. **The settings answer when the cap's door fails** (the answer still comes with every other setting):
   every page script that reads `new_per_day` copes with it absent; the switch's cost words then.
4. **The cost words and the "when" sentence** against what the mirror package does (`internal/mirror`: the
   24-hour window, the owner's and the automatic creates counted together, lowering undoes nothing, the 500
   limit): every claim the page makes is true of the code on the branch and of M13's code. Name any that is
   not.
5. **The row in the new look**, headless: the demo server or a test server with an invented catalogue,
   Settings at 1400x900 and 390x800, dark and light; the row's states (default, stored, unreadable, not
   settable, the door failing, a refusal shown). Look at the images yourself. Keyboard: after a click the
   focus goes to the answer line, never lost.
6. **Lent collector lines** (1111450a): the door's errors mapped as the collector's other mirror doors map
   theirs; nothing of the collector's run changed.
7. Anything else you judge a defect: its own number.
