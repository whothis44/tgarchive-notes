# Brief: the narrow independent review of G17, the pages on an empty catalogue (pages, P6, 11-16)

You are an independent reviewer (Opus, high effort). You did not write this code. **Read-only on the
copy `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-empty`** (branch `wip/pages-empty`, head 4bc6a229;
base 78739d59: `git diff 78739d59 4bc6a229`; 17 files, +832 -47, `archiver/internal/server` only). You
edit and commit nothing there. Probes and scratch things go into
`C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g17-scratch` (make it; `go test -overlay`).
Write the review to `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-G17-empty-catalogue.md`.

## What the piece is
`BRIEF-G17-empty-catalogue-pages.md` in the project folder and the coder's report
`archiver/docs/progress/pages-empty-REPORT.md` on the branch. The owner's first real look at the app
showed the Queue page as one error box on a new, empty catalogue (`"servers": null` read by the page's
script). The piece: every such `null` made a list at its source; a test over new catalogues in four
states that fails on any `null` outside a one-entry allow-list, and a test that every GET route is asked
by it; the scripts read lists through `ui.whole` and Queue, Staging and Overview draw region by region
(`ui.drawRegion`); "nothing yet" words; the Theme row's overlapping hint (CSS); **and the first test
that runs the page scripts at all: `TestPagesInBrowser` (Edge headless; skipped unless
`TGARCHIVE_BROWSER` names the browser).**

## What to decide (narrow: these, in this order)
1. **Did the scripts' changes break a FILLED page?** The coder opened the pages on EMPTY catalogues
   only (four states). The Queue, Staging and Overview scripts were rewritten to draw region by region,
   and nine page scripts changed. Run the pages in a browser engine on a filled invented archive (the
   package's fixture, and the demo's archive: find how `TestPagesInBrowser` serves its pages and, by an
   overlay probe or a copy of the test in your scratch folder, point it at the fixture's `newEnv` and
   at the demo, with the program's fakes filled: files in transfer, set aside, held, failed, gone; a
   staging queue; several accounts) at a wide and a narrow width: no error box, no script error, and the
   regions that held content on the base still hold it (compare with the same look on the base
   78739d59 by building it into your scratch folder, or by `git stash`-free means: a second checkout is
   NOT allowed; use `git show 78739d59:<path>` into your scratch folder for the scripts if you need the
   base's pages). Say exactly what you loaded and what you compared.
2. **`drawRegion` and `whole`:** can a region's failure now HIDE a fault the owner should see (an
   error swallowed with nothing shown; a region left empty; a region drawn once and never again after a
   failure: the coder deletes the kept shape, check it); does `whole` ever turn a value that means
   "not known" into an empty list that the page then shows as "nothing" (which fields of which answers
   may be absent on purpose)? Is any "nothing yet" sentence untrue of the code (what it tells a new
   owner to do must work: for example the Queue's words about choosing a chat)?
3. **The two Go tests:** would `TestEmptyCatalogueAnswersWhole` fail for a route added tomorrow that
   answers a nil list (plant one by overlay); does `TestEmptyCatalogueRoutesListed` see every GET
   route, the program's too, and routes registered outside the one table (plant one); is the
   allow-list's one entry right; are the four states made the way the program makes a new catalogue
   (not the fixture)?
4. **`TestPagesInBrowser`:** when it is asked for (the variable set), can it pass without having
   looked (a browser that dumps nothing twice; a page that never finishes loading; an error drawn
   after its time budget)? Does it send anything outside this PC (read its flags; it should reach
   127.0.0.1 only and send everything else to a dead port)? Does it leave a browser or a profile
   folder behind when a test fails in the middle? When the variable is NOT set it must be skipped and
   say so.
5. **The Theme row's CSS:** does the change touch any other row's layout (the coder says wide-input
   and switch rows keep their flow); look at Settings at both widths in your filled look.
6. Anything else in the diff that is wrong. Not in scope: the look of the app (it is being redesigned),
   the header that does not wrap at phone width (known, said), other packages.

## Rules
- The owner's real app may be RUNNING on this PC (ports 8786, 8787, 8788; folder
  `C:\Users\trabi\tgarchive-app`): never touch it or those ports; ports the system chooses or above
  20000; never end a process you did not start (by its id). Nothing under `E:`. Invented data only.
- Every go command through
  `bash /c/Users/trabi/Claude/Projects/Telegram/runs-pages-p6/go1.sh /c/Users/trabi/Claude/Projects/Telegram/wt-pages-empty/archiver <command...>`
  (it may wait for the track's lock). Named tests only, nothing over three minutes a command, no whole
  package, no race detector.
- Edge headless only with a profile folder of your own in your scratch folder and the flags the test
  uses (everything but 127.0.0.1 to a dead port). Leave no process, no browser, no profile folder and
  no file in the copy (`git status` there stays clean).
- Never a Windows path inside a shell string (`/c/...` in bash; the Write tool for files; forward
  slashes inside an overlay's JSON).

## The review file
Findings numbered, each **must fix / should fix / minor**, each **confirmed** (the probe and its
decisive line) or **plausible** (read, not run). The last line is one of: "may be listed", "may be
listed after these fixes: <numbers>", "not yet". Hand back at most 10 lines: the verdict line, the
counts by weight, each must-fix in one line, what you loaded in a browser engine and what you saw, what
you could not check.
