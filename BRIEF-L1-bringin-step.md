# Brief L1: the launcher's bring-in step, and the door F2 for the UI track (pages, P7, 2026-11-21)

You are the coder: Opus 5.5 at high effort, one piece start to finish; hand back a branch ready to list.

## The house rules (binding)
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-P7-review-rules.md` (privacy, safety, go commands through
`runs-pages-p6/go1.sh`, named tests). `TEMP`, `TMP`, `LOCALAPPDATA`, `APPDATA` of every test process in
`C:\Users\trabi\AppData\Local\Temp\p7-l1\` (OUTSIDE any git copy: make-folder and the API settings refuse a
folder inside one). No window on the screen (stand-ins; headless only). **Never the owner's folder, catalogue or
the old app's data (`E:\`): invented catalogues and an invented old database only.** Commits:
`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`;
push `git push private HEAD:wip/pages-bringin` only. Long commands in the background.

## Where
`git -C repo-archiver fetch private && git -C repo-archiver worktree add -b wip/pages-bringin ../wt-pages-bringin private/wip/pages-quitfix`
(d46aa8f6: G18d, the launcher's latest; listed, to be merged before yours). Report:
`archiver/docs/progress/pages-bringin-REPORT.md`.
**The launcher's look files (`ui.go`'s rendering, `look.go`, `page.go`) belong to the UI track (U-1) now.**
Put your logic, state and routes in files of your own (`bringin.go`, `apistate.go`, ...); where a line in
`ui.go` or `page.go` is unavoidable (registering a route, a phase's plain view), make those lines ONE commit
whose subject starts "Lent to the UI (launcher look):", the plainest view that works (fixed words, the existing
page's elements), so U-1 can redraw it. Say each such line in the report.

## Read first
1. `C:\Users\trabi\Claude\Projects\Telegram\CONTRACT-bringin-step.md` (whole: the bring-in program's commands,
   its `@ ` lines, exit codes and done setting from the viewer track; Core's stop, mark and start rules; U-1's
   door F2). Build against it exactly.
2. `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-UNIFIED-ARCHIVE.md` sections 5, 7, 8.
3. `internal/launcher`: how "Change the folders" stops the app and starts it again (`change.go`, `launcher.go`'s
   run loop, `present.go`), the folder boxes (`choose.go`), the setup's looks, `settings.go`, `words.go`.

## Part A: the bring-in step
1. **Offered** on the launcher's page (a link or button in the running view and the stopped view) only when
   ALL hold, each looked at by a bounded read on a read-only handle: the folder has `programs\tgarchive-bringin.exe`;
   the catalogue's setting `bringin.app.v1.complete` is not "1"; the catalogue's schema equals this build's;
   `catalog.chosen_only` is set; Core's mark door is in this build (K24: until its names come, a dry run's exit 2
   "door-missing" is the check, and the step says "this build cannot bring the old archive in yet"). Never
   offered again once the setting is "1".
2. **The owner names the old app's database and the old library** with Windows' own boxes (a file box for the
   database, the folder box for the library; no path typed, none built into the program). The library goes into
   Core's stored setting for the second root (K24 names it; until then keep the chosen folder in the step's own
   state and say in the report where it will go).
3. **The dry run first:** stop nothing yet; `tgarchive-bringin plan -into-app -old <db> -new <catalogue>` run
   with no window (hidden, its output read by the launcher, never through a pipe that a started program
   inherits: read its own stdout file or pipe in Go, which is fine); its `@ count` lines shown as numbers with
   fixed words; a "would stop the run" count above 0, or any exit but 0, shown with the contract's words and
   nothing else offered.
4. **A yes that belongs to those counts** (the counts' fingerprint carried with the yes, as G19's second yes is
   tied to what the page showed; a yes on an older page refused).
5. **The run:** stop the app as "Change the folders" does, AND every read-only opener (the window, the viewer,
   any pages server: Core's 1a); wait until the collector's lock file is free; then
   `tgarchive-bringin run -into-app ...` hidden, its `@ progress` lines as a progress line (stage, done/total)
   refreshed every 2 s; a Cancel that sends Ctrl-C (safe and resumable by the contract) and says so; its
   `@ result` and exit code mapped to fixed words.
6. **After:** `tgarchive-bringin counts -into-app -new <catalogue>` shown (in the old archive / probably / partly /
   new, seen never saved); then the app started again, with a longer bound for "the collector answers" and the
   words "a large catalogue is being opened" (Core's 3). Never install a new build in the same step.
7. **Fails closed:** anything not as the contract says (an unknown `@ result`, an exit code not listed, the lock
   not free within a bound, the program missing) ends the step with fixed words and starts the app as it was.
8. **Tests** with a stand-in `tgarchive-bringin.exe` (a small Go program in testdata built by the test, playing
   each exit code and `@` line sequence, a slow run, a Ctrl-C): offered or not for each condition; the yes tied to
   the counts; the stop waits for the lock; every exit code's words; the app started again after each end;
   nothing offered after done.

## Part B: the door F2 for U-1 (in the contract file, end)
(a) When the collector cannot start, the launcher still starts the ONE joined window, viewer first, the
launcher's page named as the second `-pages` address. (b) `GET /api/state` on the launcher's own server:
the JSON in the contract, `Access-Control-Allow-Origin` exactly the request's origin when it is one of the
addresses the launcher started, `Vary: Origin`, GET only, no credentials; any other origin refused as today.
Tests for both (the window's line in each case; the route's answers and headers for each origin).

## Hand back
Branch pushed, copy clean; the whole `internal/launcher` run once at the end (TEMP outside a git copy), gofmt,
vet; the report (what a person sees in each state, the lent lines for U-1, what waits for K24's and B9's
heads). Final message: the head (8 characters), the report's path, one line of what is not verified.
