# Review of G11: the app in a window of its own (the launcher's side)

Reviewer: independent, read-only. 11-16, about 09:50 local. Under review: `wip/pages-window` at efedabd0 against
835e2826 (`archiver/internal/launcher`, 12 files). Nothing in the tree was changed (`git status` clean). Every probe
ran from `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g11-scratch` through `go test -overlay`, with the
package's stand-ins; no window, no browser, no real launcher; named tests only, one go command at a time, the PC
measured before each.

**Verdict: may be listed after these fixes.** 2 must fix, 5 should fix, 9 minor. The launcher's OWN window is
handled carefully (bound, own handle, rescope, once-only redirect, mutations caught). What is not: the window a
second start of `tgarchive.exe` keeps (which is the path the page itself tells the owner to use to get the window
back), and the fallback's one browser opening after the pages have ended.

Probes (all six FAIL on efedabd0, i.e. each finding is present; file
`C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g11-scratch\zz_review_probe_test.go`, overlay
`overlay-probes.json` beside it; run: `go test -p 1 -count=1 -overlay <overlay> -run TestReviewProbe -v ./internal/launcher`, 12.6 s):

| probe | what it shows | result |
|---|---|---|
| P1 | fallback opens the ended pages' address | browser opened on the pages: true; on the launcher's page: false; pages answer: none |
| P2 | a second start's window outlives the pages | keeper runs: true; its window names the pages: true; pages answer: none; 2 s after the crash |
| P3 | a second start's window during the setup never names the pages; the redirect sends it there | kept window: 4 arguments, pages among them: false; first launcher's window starts after the save: 0 |
| P4 | refused starts name a foreign port and restart the window twice per Try again | 6 window starts for 1 start + 2 presses; 3 named the port another program held |
| P5 | Try the window again after the pages were shown: the window stays on the launcher's page | first look 200 (no redirect); the page says the pages are in the window: true |
| P6 | after the person closed the window, a crash is shown nowhere | browser opens 0, window starts 1 |

---

## Must fix before the merge

### M1. The second start's window ("keeper") is outside every rule of the window's review: it outlives the pages, never follows a new address, and from the setup it is redirected to an address it does not name. CONFIRMED (P2, P3)

`launcher.go` 368-393 (`second`, its `alive` at 385-390), `present.go` 559-589 (`keepWindow`), `present.go` 215-238
(`rescope` acts only on `w.proc`, the first launcher's own window).

The page tells the owner (wordWindowHow): close the window and double-click `tgarchive.exe` to get it back. That
double-click is a second launcher, which starts the window as ITS child and keeps it while `alive()` is true:
"the first launcher's page answers, or the pages answer". The first launcher's `rescope` cannot reach it.

- **P2, the dangerous one.** Sequence: the owner closes the window (exit 0); double-clicks: the keeper's window opens
  on [launcher page, pages]; the collector/watchdog then end with a failure. The first launcher shows its failure page
  and waits for the owner (it never ends by itself), so `alive()` stays true forever and the keeper's window keeps
  `http://127.0.0.1:P/` named with nothing serving P. That is exactly board 113 (c): "when the app's servers end,
  close the window (another program that takes a named port would be shown under the app's title)". The owner was
  probably looking at the pages in that window when they ended; a reload of P would show whatever holds P next.
  The same window is also never restarted when the pages come back on another address (rule: "the ports are fixed
  for the window's life").
- **P3.** Sequence: a first start (no settings file) shows the setup in the window; the person closes it (or it exits
  0 at once); a double-click starts a keeper window on the launcher's page alone (`st != SettingsOK`, so `pages` is
  ""); the setup is saved; `begin` → `showStart` → `rescope(true)` sees the first launcher's own window ended and
  returns; `startWindow` refuses (`starts > 0 && !again`); the pages answer; `armRedirect` sends the keeper's window
  to `http://127.0.0.1:P/`, which that window does not name: the window refuses it and the once-only redirect is
  spent. The person is left on a refused navigation.

Smallest change I would ask for: **while a launcher answers, a second start starts no window of its own; it asks the
first launcher to show its window** (one request to the first launcher's page, e.g. `POST /show-window` carrying a
fixed header such as `X-Tgarchive-Second: 1`, which a page of another site cannot send without a preflight the
launcher never grants; refused when `Sec-Fetch-Site` is present and not `none`). The first launcher then does
`again = true; startWindow()` when none of its own runs (at most one per such request, and say one per 2 s), so every
window on the screen is the first launcher's and `rescope`, `endWindow` and the redirect cover it. Keep the keeper
only for "no launcher answers, the pages do" (`launcherUp == false`), name only the pages there, and end it as soon
as the pages stop answering (which it already does). If the hand-over is too large for this round, the minimum is:
`alive()` must also require the pages to answer whenever the keeper's window names them (end it at the third miss of
the pages, whatever the launcher's page says), and the keeper must never be started on the launcher's page alone
while the first launcher is in its setup (P3).

### M2. The fallback's one browser opening can go to the address of pages that have ended, and the failure page is then shown nowhere. CONFIRMED (P1)

`present.go` 424-454 (`windowFailed`, the case at 438-440), with 215-219 (`rescope(false)` sets `pagesGone` but not
`pagesShown`) and 271-275 (`pagesShown` is reset only at the next `showStart`).

Sequence: the pages were shown (`pagesShown = true`); the watchdog ends with a failure; the run loop's
`rescope(false)` ends the window and starts it again on the launcher's page alone; that new start exits 3 (or 1).
`windowFailed` takes `w.pagesShown && w.pagesURL != ""` and opens `http://127.0.0.1:P/` in the browser: the server
has ended (P1: pages answer "none"). `browserOpened` is now spent, so the launcher's failure page (why it ended, Try
again, the watchdog's lines) is shown neither in the window nor in the browser. The brief's own words: "never an
address whose server has ended". A restart of the real engine immediately after the clean stop of the previous one
is exactly when an exit 3 is most likely (see the person's checks), so this is not far-fetched.

Smallest change: in `rescope`, when `pagesUp` is false, set `w.pagesShown, w.pagesURL = false, ""` under the same
lock (or have `windowFailed` choose the pages only when `!w.pagesGone`). One line; a test like P1.

## Should fix

### S1. A start names the pages' port in the window BEFORE the checks that may refuse it, and each refused Try again ends and starts the window twice. CONFIRMED (P4)

`launcher.go` 506-508 (`showStart` right after the "starting" view, before `findLeft`, the address look and `free`),
`present.go` 271-283, and the run loop's `rescope(false)` at 284.

With P held by another program: the first start names P (window start 1) and is refused, then restarted on the
launcher's page (2); each press of Try again restarts it on [L, P] (P still the other program's) and again on [L].
P4: 6 starts for one start and two presses; 3 of them named a port another program held. Every restart is a cold
WebView2 start (up to the window's 8-10 s certainty), and each is one more chance of an exit 3 that sends the owner to
the browser. It also names P at the setup (`setup` → `showPage` before any `rescope(false)`), and at an orphan
collector's refusal.

Change: name the pages only when they are about to come: move `l.rescope(true)` out of `showStart` to the two places
where the pages really come (just before the watchdog's start, after `free(s.PagesAddr)` and the program and adapter
checks; and the `leftWatchdog` branch), keep `startWindow()` (launcher page only) where `showStart` is; and make the
spec's default `pagesGone = true` until then.

### S2. Once the person has closed the window, a later failure is shown nowhere. CONFIRMED (P6)

`present.go` 252-266 (`showPage` → `startWindow`, refused by `starts > 0 && !again`), called from the run loop
(`launcher.go` 285), `follow`'s pages bound (630) and "no pages" (666).

The page says "Closing the window does not stop the program: the collector runs on". If the collector or watchdog
then fails (hours later), the base (and the browser setting) opens the launcher's page so the owner sees it; the
window setting shows nothing until the owner happens to double-click. P6: after the crash, 0 browser opens, 0 new
starts. Change: treat these three events like `rescope`'s: one `again = true; startWindow()` per event (still
bounded: each needs a new failure, and the run loop then waits for the owner). Or say on the page that a failure
will not be shown; I would build the start.

### S3. Nothing ends the window when the launcher itself dies. CONFIRMED by reading

`start.go` 39-102 (`StartHidden`: no job object); `present.go` 494-512 runs only on an orderly return.

A panic in a goroutine other than `run`'s (e.g. the window's watcher at 359-363), a fatal runtime error, an end from
Task Manager, or Windows ending the launcher leaves the window (and a keeper's window) running. The servers run on at
first, but when they later end nothing closes the window that names them (rule 113 (c)). Change: put the window
program in a job object of the launcher's with `JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE` (the tests already use a job);
assign it right after the start (or start it suspended), only for the window (never the watchdog, collector or
viewer).

### S4. The browser kind of viewer's address is named whether or not that viewer runs. CONFIRMED by reading

`present.go` 201-203 (`ownWindowSpec`), `launcher.go` 381-383 (`second`).

V is named whenever `s.Viewer == ViewerBrowser`, also when `startViewer` did not start it (no catalogue, program
missing, start failed: `launcher.go` 727-739), and after that viewer ends (not watched, as the report says). A named
port with no server is the danger of 113 (c). Change: name V only while the launcher's own viewer `Proc` runs; at its
end (watch its `Done` in `follow`) rescope without V. The second start should name V only when it answers.

### S5. A change of the setting from window to browser leaves the window running on the launcher's page, and the "could not be shown" sentence follows into the browser mode. CONFIRMED by reading; becomes a common path with the decided change (1)

`present.go` 271-283 (`showStart` does nothing when `!inWindow()`), 513-516 in `ui.go` (`windowWords` says `fell`
before it looks at `inWindow`).

Today only by editing `tgarchive.json` before Try again; after the decided change (1) (the choice on the launcher's
own page) it is one click. Then: the pages open in the browser, and the window stays open on the launcher's page
until the launcher ends. Change, with (1): a change to browser ends this launcher's window (after the browser has the
page) and clears `fell`; a change to window starts it (`again = true`) and clears `browserOpened` only if the owner
should get a second fallback tab (I would not). No reason against (1) or (2) otherwise.

## Minor

1. **Try the window again after the pages were shown** (P5, CONFIRMED): the redirect is disarmed by the failure and
   never armed again, so the new window stays on the launcher's page, which says "The pages are shown in the app's
   own window."; the browser tab has the pages too. `present.go` 459-471: when `w.pagesShown`, arm the redirect again
   before `startWindow`.
2. **Unreadable, invalid or newer settings use the window even when the file says `browser`** (CONFIRMED by reading:
   `launcher.go` 251-253 and 294-296 set the settings only for OK/Missing; `inWindow()` on zero settings is true).
   The base opened the browser. For `SettingsInvalid` the parsed `s.PagesOpen` could be used when valid.
3. **Untrue reason words**: `wordWhyMissing` ("missing from the folder") for an unknown folder (`spawnWindow` 370
   returns `whyMissing` when `l.folder == ""`) and for a link or a folder in its place; `wordWhyOther` points to
   `pages-window\window.out.log` also when the data folder could not be made (no such file), when the start failed,
   and when the window's lines went to `window.err.log` (the window program writes its flag errors to stderr).
4. **The second start's window looks at the pages' "/" every 500 ms** while the first launcher does not answer
   (`alive` 389), for as long as the window lives; `follow` deliberately stops looking once the pages answer.
   PLAUSIBLE cost (settled by measuring the collector's "/" render).
5. **A settings file saved by this build is "unreadable" to the base launcher**, not "newer" (no version bump).
   Nothing is overwritten or lost (the base's `SaveSettings` keeps an unreadable file). Acceptable as said in the report.
6. **Test meaning weakened**: `TestSettingsUnreadableRefusedNotOverwritten` now accepts any number of window starts
   (`f.count("start ") != f.count("start "+WindowExe+" -pages")`): a loop of window starts would pass. Ask for exactly
   one. The other two changed assertions keep their meaning (see below).
7. **Race at the end**: `windowFailed` may pass its `ending` check just before `endWindow` sets it, and open the
   browser on the launcher's page that is about to close. PLAUSIBLE, rare, harmless beyond a dead tab.
8. **The redirect is taken by the first document navigation of the launcher's page from anywhere** within 30 s,
   e.g. a browser tab on 127.0.0.1:8786 restored at the browser's start. PLAUSIBLE, rare; the window then shows the
   launcher's page with the pages' link.
9. **Pre-existing flake, not G11** (for the integrator's full run): `TestEachFailureWordsOnce/collector_refused`
   fails now and then with "The watchdog ended at once" instead of the collector's refusal (`ended()`, unchanged by
   G11). Base 835e2826: 1 of 30 runs; head: 3 of 7 runs on a busy PC (load 50-90%). The full run before the merge may
   meet it; it is not caused by this change (it fails the same way on the base).

---

## Every start of the window

| event | where | guard | bound |
|---|---|---|---|
| the setup is shown | `launcher.go` 462 → `present.go` 252 | `inWindow`; `startWindow`'s guard (`fell`, `ending`, own one runs, `starts > 0 && !again`) under `w.mu` | 1 per run |
| a start's beginning | `launcher.go` 508 → `present.go` 280-281 | `rescope(true)`: own window runs and its addresses differ → stopped, `again`; then `startWindow`'s guard | 1 restart per `begin` (each needs the owner's Try again) |
| a refusal or an end (run loop) | `launcher.go` 284-285 | `rescope(false)` as above; `showPage` refused once started | 1 restart per `resultWait`; the loop then waits for the owner |
| the pages' bound passed; "no pages" | `launcher.go` 630, 666 | `starts > 0 && !again` | 0 |
| the pages answer | `openPages` | starts nothing (arms the redirect) | 0 |
| the window ends 0 / non-zero | `windowEnded` | `closed` / `fell` | 0 |
| Try the window again | `ui.go` 422-430 → `present.go` 459 | token, same origin, view number, `fell`, not `ending`, none running | 1 per accepted press (409 otherwise) |
| a second start, a launcher answers | `launcher.go` 326/332 → 392 → `present.go` 565 | once in that process | 1 per double-click (each a new keeper; M1) |
| a second start, the address held by a non-launcher | `launcher.go` 342-343 | as the own run | 1, plus presses |
| the pages' address changed | `rescope(true)` in `begin` | as above | 1 per `begin` |

No sequence without an act of the owner or a new event starts it again (a window that exits 0 at once, exits 3 at
once, cannot be started, or is replaced between starts: checked; `TestWindowNeverLoops` and my reading agree). The
author's sentence "one per run, one more per event that replaces a running window of its own, one per press" holds
by its letter; P4 shows that a refused Try again counts as two such events (S1).

## Every end of the window

| event | what is ended | by what handle |
|---|---|---|
| the launcher returns (Quit, Close, any return of `run`; `another`) | its own last window (`w.proc`) if it runs | the `Proc` its `env.Start` returned: the Ctrl-C helper (pid and creation time handed over and checked again under the helper's own handle, while the launcher still holds its handle), 3 s, then `Kill` (opens by number only to compare the creation time, then `TerminateProcess`), 2 s |
| the pages end / a refusal / other addresses (`rescope`) | its own running window | same; marked `stopped` so its end is no failure |
| a keeper's three misses | the keeper's own window | same, through `Run`'s `endWindow` |
| the person closes a window; a window brings another to the front | nothing else | none |
| the launcher dies (panic elsewhere, Task Manager, fatal error) | nothing: the window stays (S3) | none |
| the browser viewer ends | nothing (S4) | none |
| the pages end while a keeper's launcher still answers | nothing (M1) | none |

The clean stop reaches only the window: the window program is a console program (`tgarchive-window` is not built
`-H=windowsgui`), started with `CREATE_NO_WINDOW`, so it has a console of its own; its WebView2 processes are GUI
programs and are not on it; the launcher is built `-H=windowsgui` and has no console; the helper ignores the event
itself. Nothing is ever found by name or by a number read from elsewhere.

## The window's review rules (board 113 (c)), one by one

| rule | state |
|---|---|
| `-data` a folder of the window's own, the same every time, never a viewer's | kept (`<folder>\pages-window`; the viewer's window gets no `-data`) |
| a clean environment (no `WEBVIEW2_*`) | kept for the variables (`windowEnv`); WebView2's registry overrides are out of the launcher's reach (the window's own concern) |
| never port 80 | kept (`pageURL`, `ownWindowSpec`, `second`) |
| act on the exit code of the process YOU started (3 and 1: the browser) | kept (`windowEnded` compares `w.proc`); a flag error of its own also falls back, acceptable |
| a second start's 0 says nothing about the first window | kept (the keeper only ends) |
| the ports are fixed: restart the window when the pages come back on another port | kept for the own window; **missing for a second start's window** (M1) |
| when the app's servers end, close the window | kept for the own window at the watchdog's end and at the launcher's end; **missing**: a second start's window (M1, P2), the launcher's death (S3), the browser viewer's end (S4); and the fallback opens the ended pages (M2) |
| no web link on the launcher's or the collector's pages until the gate | kept for the launcher's page (`default-src 'none'`, no link out) |

## Sentences on the pages that are not true of the code

- "The pages are shown in the app's own window." (wordPagesInWindow): not true after the person closed the window,
  after Try the window again (P5), in a second start's window (it opens on the launcher's page), when the 30 s
  redirect passed unused, or when a browser tab took it.
- "The app's pages come into this window by themselves when they answer." (wordPagesComeHere): not true in a second
  start's window opened during the setup (P3).
- "The app's own window could not be shown, so the pages are in your browser instead: ..." (wordWindowFell): after M2
  the browser has ended pages and this sentence is on a page shown nowhere; for a window that ran for hours and then
  crashed, "could not be shown" is not what happened.
- "the window program is missing from the folder ..." (wordWhyMissing): also said when the folder is unknown and when
  the file is a link or a folder.
- "another error (the window's own lines are in pages-window\window.out.log ...)" (wordWhyOther): no such file when
  the folder could not be made or the start failed; flag errors go to `window.err.log`.
- "If the window cannot be shown on this PC, they open in your browser instead and this page says why."
  (wordOpenWindow): true except M2.
- The report: "With `browser` they do exactly what the base did": except unreadable, invalid or newer settings (minor
  2). "To choose the browser after the first setup: set pages_open in tgarchive.json": being changed (decided (1)).

## What only a person at the PC can check, and how

1. **A restart of the real window right after the clean stop of the previous one** (every `rescope`): does the engine
   come up on the same `window-webview` folder within its 10 s, or exit 3 because the old engine still holds it?
   How: `TestRealPagesWindow` adapted on an invented folder: while the real window shows the pages, make the
   stand-in collector end with 3 (`quit` file with `3`) and read the launcher's log lines ("started again", "ended,
   exit code"); five times. An exit 3 there leads straight to M2.
2. The folder box over the app's window: does it come to the front with the keyboard (G10's way) when the window,
   not the browser, is in front.
3. Close the window, double-click `tgarchive.exe`: the window opens on the launcher's page; one click on the pages'
   link; Quit closes it within about 2 s (the keeper's three looks).
4. Double-click while the window is open, and while it is still starting (the engine not yet shown): the open
   window comes to the front; nothing else opens.
5. A PC (or a user) without WebView2: the browser opens once on the launcher's page, the sentence says WebView2.
6. After any window restart, Task Manager: the watchdog, the collector and the viewer kept their process numbers
   (the clean stop reached only the window).

## What I checked and found sound

- The bound: `startWindow`'s guard is taken under one lock with the spawn; concurrent callers (the page's Try
  again, the run goroutine, the watcher goroutines) cannot start two; no timer, refresh or end starts it; the run
  loop always waits for the owner between restarts.
- Every end goes through the `Proc` from `env.Start`; the helper re-checks the creation time; `Kill` re-checks it
  too; ended processes' handles are let go only after `Done`.
- The redirect: target fixed to `pageURL(s.PagesAddr)` (always `http://127.0.0.1:P/` for valid settings; never taken
  from the request: no open redirect); taken once (M2 of the author's mutations); only by GET document navigations
  with `Sec-Fetch-Site` none or same-origin; `look()` (both launchers' probes) sends none of those headers; another
  site's link is refused; refused while a folder box is open; dropped after 30 s; the launcher's page refreshes every
  2 s (starting) or 5 s (running), so a window that loads it takes it.
- The browser mode: `showPage`/`openPages`/`second`/`another` open the same addresses in the same order as the base;
  no redirect ever (the base tests pass in that mode; `TestWindowSettingAbsentWindowBrowserStored` checks 5
  navigations); the only page change is the new choice on the setup form.
- The setting: absent key loads as window; a wrong value is refused in fixed words; a save writes `window` when
  empty; a file of this build is refused, never overwritten, by the base.
- The three changed base assertions: the fixture's `browser` keeps the base tests' meaning for that mode (they no
  longer cover the default mode: the window tests do); `TestEachFailureWordsOnce/settings_unreadable` still means
  "said once"; `TestSettingsUnreadableRefusedNotOverwritten` is weaker (minor 6).
- The folder box: the choice is carried across a box (`typedForm.open`, `afterBox` falls back to the earlier view's
  choice); nothing else in the box changed.
- The log: every new line a fixed format with numbers and booleans only (`checkLog` enforces it);
  `window.out.log`/`.err.log` hold only the window program's own fixed lines (they grow by a few lines a start, no
  bound: harmless).
- `Lstat` regular-file check: covers the last component only (a junction on `programs\` or a hard link passes); the
  other programs are checked with `Stat` (links followed), so this is stricter than the rest; no change asked.
- The tests: no test judges on real time (the 500 ms in `TestWindowClosedThenSecondStartKeepsAndEnds` only bounds a
  "still there"); every wait bounded; the stand-in's race (Ctrl-C before the handler) is handled right in the product
  (`stopped == p`, no fallback). `TestRealPagesWindow` and `TestPreviewWindowPages` skip unless their own variables
  are set (read, not run): safe in a whole run. Base test functions removed: 0.
- **The author's three mutations, applied in overlays and run:** M1 (`if !w.browserOpened` → `if true`):
  `TestWindowTryAgain` FAILS ("opened 2 times"). M2 (the redirect not dropped): `TestWindowPagesAppearOnce` FAILS
  ("navigation 0 after the first: 303"), `TestWindowNeverLoops` FAILS ("42 times"). M3 (every process of the window's
  file ended by a process list): `TestWindowLauncherEndsOnlyItsOwn` FAILS ("ended a window it did not start"). All as
  the report says.
- The window tests and the base tests named here pass on efedabd0 (except the pre-existing flake, minor 9):
  `TestWindow*` (11), `TestSecondLauncherOpensFirstOnesPage`, `TestCrashShownNeverRestartedByLauncher`,
  `TestSettingsUnreadableRefusedNotOverwritten`, `TestFirstStartSetupPage`, `TestQuitEndsViewerAndLauncher`,
  `TestAlreadyOpenFollowsThisFoldersWatchdog`.

## What I did not look at

The window program itself (`wip/b-winpages`: its single-instance rule, whether its mutex is per data folder, its exit
3 timing, the gate); `internal/server`; `deploy/folder/make-folder.sh`; the non-Windows build (`proc_other.go`); the
race detector; the whole package run; the real window (not started, by the brief).

---

# Second pass (10f62435)

Same reviewer, same rules, 11-16 about 10:30 local. Under review: `git diff efedabd0 10f62435 -- archiver/internal/launcher`
(the merge of f7d6ca63 not reviewed). Tree untouched (`git status` clean). Probes in
`C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g11-scratch\r2` (`zz_review2_probe_test.go`, overlays
`overlay-probes2.json`, `overlay-mA/B/E/G.json`), with the first pass's probe file loaded beside it. The PC was measured
in a command of its own before each go command (free memory 2.6 to 2.9 GB, CPU 49 to 79%; I waited once).

**Verdict: may be listed after these fixes.** 1 must fix, 2 should fix, 7 minor. Every first-pass finding is fixed,
except S5 and minor 1, which are fixed in part (both by the new must-fix). The rebuilt pieces (the ask, the job, the
fallback, the bound) are sound. One root cause is not: the pages are named to the window only in the window mode,
so any window started after the browser has been in use cannot reach the running pages.

## The first pass's findings at 10f62435

| finding | state | where |
|---|---|---|
| M1 the second start's window | **fixed**. `keepWindow` is gone. A second start asks the running launcher (`askShow`) and opens no window of its own. My P2 probe now records: no keeper, 3 window starts all by the first launcher, the window on L alone after the crash. New caveat: N2 | `launcher.go` 369-376; `present.go` 563-612, 756-769; `ui.go` 350-374 |
| M2 the fallback onto ended pages | **fixed**. P1: the browser opens the launcher's page, not the pages. Mutation B caught | `present.go` 221-224, 487-493 |
| S1 the pages' port named before the checks | **fixed**. P is named only at the watchdog's start or when a running one is found. The author's `TestWindowRefusedStartNamesNoForeignPort` passes (1 start, no line names P). My P4 now only times out waiting for the churn, which is gone | `launcher.go` 511, 591; `present.go` 300-317 |
| S2 a failure unseen after the person's close | **fixed**. P6: the crash starts the window once | `present.go` 275-285 |
| S3 the window outlives a dead launcher | **fixed**. The window is in a kill-on-close job. Mutation E caught; its test uses stand-ins only (read before running) | `proc_windows.go` 216-247; `present.go` 428-444 |
| S4 the viewer's address | **fixed** (no longer named) | `present.go` 183-209 |
| S5 change of the setting | **fixed in part**. "To the browser" works (mutation G caught). "To the window" while the app runs starts a window that cannot reach the pages (N1, Q1). A race with a restart (N3) | `present.go` 620-665 |
| minor 1: Try the window again, redirect | **fixed in part**. Fixed after a late failure (P5 now gets 303). Broken when the window had already failed before the programs started (N1, Q2) | `present.go` 509-528 |
| minor 2: invalid settings and their choice | fixed | `launcher.go` `keepFileChoice` |
| minor 3: untrue reason words | fixed | `words.go` |
| minor 4: the keeper's polling | gone with the keeper | |
| minor 5: settings file refused as unreadable by the base | accepted | |
| minor 6: the test's window-start count | fixed (exactly one) | `launcher_test.go` 624 |
| minor 7 (a browser tab in the launcher's last ms), minor 8 (the redirect taken by any navigation) | left, with reasons; I agree both can wait | |
| minor 9: the flake | fixed in the stand-in. I agree with the author's cause; my rerun on 10f62435: 15 of 15 | `standin_test.go` 134-150 |

## New findings

### Must fix

**N1. The pages are named to the window only while the window mode is in force, so a window started after the browser was in use cannot reach the running pages, and it is redirected to an address it does not name. CONFIRMED (probes Q1, Q2)**

Where:
- `present.go` 311-317: `windowForPages` returns at once when `!l.inWindow()`, so `rescope(true)` never runs and `pagesNamed` stays false.
- `present.go` 198-200: `ownWindowSpec` then names L alone.
- `present.go` 523-526 (`tryWindowAgain`) arms the redirect to P. `changeChoice` (641-646) does not arm it.

Two sequences:
- **Q2 (a first start on a PC where the window does not come up in time).** The setup's window exits 3, and the browser opens the launcher's page. The owner presses Save and start. `windowForPages` returns early (the window has fallen back). The pages open in the browser (2 browser opens). The owner presses "Try the window again". The new window names L alone (`names the pages false`), and its first look is sent with a 303 to P, which it does not name: the window refuses it. The pages' link on the page is refused the same way, and the page says "The pages are shown in the app's own window."
- **Q1 (the decided change (1)).** The setting is the browser and the app runs. The owner chooses "In the app's own window" on the launcher's page. The window starts on L alone (`names the pages false`; first look 200), and the page says "The pages are shown in the app's own window." The window cannot reach the pages until the next start.

The smallest change: keep "the pages are named" as the run's fact, whatever the mode.
1. In `windowForPages`, set it (call `rescope(true)`, which restarts only a running window) before the `inWindow` check.
2. In `changeChoice` to the window, arm the redirect when `pagesShown`, as `tryWindowAgain` does.
3. Add one test for each sequence.

### Should fix

**N2. The start that brings the window to the front can become the only window, and the launcher ends it after 10 s. Launcher side CONFIRMED (Q3); whether the real window program reaches this state is PLAUSIBLE**

Where: `present.go` 579-581 and 594-612.

`frontWindow` starts the window program without the usual guards and treats the new process as never a window. That holds only while the open window is still there when the new start checks. Sequence:
1. The owner double-clicks while the window is open: `running` is true, and `frontWindow` starts a second process.
2. Meanwhile the open window ends: the person closed it a moment before, and its process was still tearing down. Or the open window had not yet taken its single-instance mutex while it was starting.
3. The new start finds no window on the folder and shows one: the only window on the screen.
4. After `frontBound` (10 s) the launcher ends it by its handle. Nothing is left on the screen, and the page says the window was closed.

Q3 (stand-ins: the ask's start stays and the open window then ends with 0): after 12 s, the start had been ended by the clean stop (1 clean end) and the window had been started 2 times. Either way the owner may see the window vanish.

The smallest change: when `frontBound` passes, or when the open window's watcher sees that window end while a front start still runs, adopt the front start as the launcher's window (`w.proc`, `w.addrs`, the watcher, the `wg`) instead of ending it. End it only while the launcher's own window still runs.

**N3. `startWindow` and `rescope` do not look at the choice. A change to the browser during a restart leaves a window started in the browser mode. PLAUSIBLE (a race; the window is about the length of the clean stop, at least 0.5 s)**

Where: `present.go` 365-378 (the guard has no choice test) and 236-243.

Sequence: `rescope` is restarting the window (`stopWindow` takes the helper's time). On the HTTP goroutine, `changeChoice(OpenBrowser)` stores the choice, stops the same window and opens the browser. `rescope` then sets `again` and calls `startWindow`, which starts a window although the choice is the browser. Later `rescope` calls keep restarting it.

The smallest change: `startWindow` returns when `l.choice() != OpenWindow` (computed before taking `w.mu`).

### Minor

1. **`wordWindowHow` overstates.** It says "If the program stops or fails while the window is closed, the window opens again on this page". A clean stop (the watchdog's exit 0) ends the launcher, and nothing opens. Say "fails".
2. **A failed job is said only in the log** (`logWindowJob false`). The window then still goes at an orderly end, but not with a dead launcher. One sentence on the page, or accept it.
3. **`AllowSetForegroundWindow(ASFW_ANY)` lets any process take the foreground once**, until the next input. It is needed because the window program's front start, not the launcher, takes the foreground. It is small and short-lived; accept it, or narrow it when the window program can be told the second start's grant.
4. **Every ask writes a log line**, whether refused or within the bound. A local program asking in a loop grows the launcher's log without bound. Log the first of each 2 s only.
5. **`changeChoice` writes the whole settings as loaded** (`present.go` 624-632). A hand edit of `tgarchive.json` made since the launcher read it (e.g. a new `pages_addr` for the next Try again) is overwritten. Re-read the file and change only `pages_open`.
6. **An ask while a folder box is open** brings the window over the box. The box helper's own way to the front may then lose. PLAUSIBLE; a person check.
7. **The report's "no second tab" holds only within one start.** After a fallback before Save and start, the browser gets the launcher's page and then the pages: Q2 counted 2 opens. This is the same as the base's browser mode at a first start; correct the sentence.

## The four claimed mutations, applied in overlays and run

| mutation | named test | result |
|---|---|---|
| A: the ask's `sec-fetch-` check looks for another prefix | `TestWindowAskRefusedFromABrowser` | FAILS ("sec-fetch-site none: 204, want 403") |
| B: the pages' shown state not cleared at `rescope(false)` | `TestWindowFallbackAfterPagesEndedOpensLauncherPage` | FAILS ("opened another address than the launcher's page") |
| E: no job | `TestWindowGoesWithAKilledLauncher` | FAILS ("the window outlived its launcher by 10 s") |
| G: the change to the browser leaves the window running | `TestWindowChoiceFromPage` | FAILS ("the window was not ended, or the pages not opened") |

`TestWindowGoesWithAKilledLauncher`, read before running: it starts the stand-in `tgarchive.exe` (this test binary) running `Run` with `SystemEnv`. The browser, the public lookup and the adapters are replaced and the folder box is off. Every program it starts is a stand-in in the invented folder, so I ran it. `TestRealPagesWindowLauncherKilled` is gated by `TGARCHIVE_REAL_WINDOW=1`: read, not run.

All 20 `TestWindow*` tests pass on 10f62435, as do `TestSettingsUnreadableRefusedNotOverwritten` and `TestSecondLauncherOpensFirstOnesPage`. The two removed functions (`TestWindowClosedThenSecondStartKeepsAndEnds`, `TestWindowSecondStartBringsToFront`) were G11's own and tested the removed keeper; the ask tests replace them. Removed against the main head: 0.

## Point by point (the coordinator's a to i)

**a. The ask route and `showAsked`.**
- **Who can call it.** Only a program of this user on this PC. A page cannot:
  - a cross-site `fetch` with the custom header is preflighted, and OPTIONS is refused with 403;
  - a form or beacon cannot carry the header;
  - DNS rebinding fails the exact Host test.
- **What a caller can do.** At most, every 2 s: bring the window to the front, or start it again after the person closed it, or (browser setting or after a fallback) open the launcher's page in the browser. Nothing worse.
- **The bound.** It is taken under `w.mu`. `Clock.Now` is `time.Now` with its monotonic reading, so a change of the wall clock does not move it. The `!now.Before(lastAsk)` escape matters only for a clock that steps back, which the system clock does not.
- **`frontWindow`.** It has no loop. It can make a second real window only as in N2; every such process is ended by its handle at 10 s, or by its job at the launcher's end.
- **An ask while the launcher shows the setup.** The window comes to the front (or is started on L).
- **An ask while the launcher is starting.** The window is started on L, then restarted on L and P when the programs start.
- **An ask while the launcher is ending.** A front start may begin; its job ends it when the launcher exits.
- **An ask after a fallback.** The browser, as the base.
- **An ask during a folder box.** See minor 6.

**b. The second start.**
- **Taken.** It ends with 0 and opens nothing.
- **Not taken.** It opens what the base opened. That is a tab without a window, except in one rare case: the ask's answer takes longer than 3 s while the running launcher, already fallen back to the browser, opens a tab. Then two tabs open; harmless.
- **The first launcher still starting.** It answers as soon as it serves, a few ms after its bind, and the ask is taken. If `look` fails in that instant, the second start shows its own "address in use" page in a window on the same data folder. Rare; not worth code.
- **Exit code.** Always 0, as the base.
- **`ASFW_ANY`.** See minor 3.

**c. The job.**
- **The process opened by its number.** It is checked against the creation time held since the start. The launcher still holds its handle, so the number cannot have been reused.
- **Engine processes started before the assignment.** The launcher assigns right after `CreateProcess` returns. The window's own kill-on-close job (its `Prepare`) holds its engine and dies with it. Either order of the two assignments nests and kills the window. The author's real try 3 left 0 of 7.
- **A failure to make or assign the job.** The launcher goes on and says so only in the log (minor 2).
- **When the job's handle is closed.** Only when the window has ended (`holdInJob`'s goroutine) or at the launcher's exit. No path closes it early: a change of the choice, a restart or Try again each ends the window first, and a new window gets a new job.
- **What is in the job.** `ownJob` is called only from `spawnWindow`, which starts only `-pages` windows. The watchdog, the collector and the viewer go through `env.Start` in `begin` and `startViewer` and are never assigned. The killed-launcher test checks that the watchdog runs on.

**d.** The bound is restated in the table below. I found no sequence that starts the window without an owner's act or a new event.
- D adds one start per failure event after a close. The events need the owner between them: the run loop waits after each one, and the pages' bound and "no pages" fire once per start.
- `TestWindowNeverLoops` now counts 2 for a run with a crash.

**e. The choice form.**
- It carries the token, the same origin and the view number.
- It is offered on the running, failure and orphan views only: never during the setup or while a box is open.
- A double press is the same choice and does nothing.
- A store that fails is said and changes nothing.
- "To the browser" opens the pages only while they are shown and not ended, else L: never an ended address.
- The issues: "to the window" while the app runs (N1), the race with a restart (N3), and the whole-file write (minor 5).

**f.** The pages' port is never named while another program holds it, as far as the launcher can see. The only gap left is the moment between the launcher's one bind and the collector's own bind. The setup's close-and-open could be avoided within the window's rules:
- At the setup, name P when `look(P)` answers "none" at that moment. The setup's addresses then equal those of the start, and `rescope(true)` does not restart the window.
- Nothing navigates to P before the launcher's own look has seen the pages' mark: there is no link on the setup page, and the redirect is armed only after that look.
- If P is taken meanwhile, the start is refused and `rescope(false)` restarts the window on L, as now.
- This is the main session's choice: P named but never navigated to during the setup, or the visible restart. I would take the former.

**g.** The real path is sound:
- The real watchdog's last write is tried again for up to 2 s (`finalBudget`, `putInPlace`).
- `watchdog.ReadStatus` opens with `FILE_SHARE_DELETE` and tries again itself.
- The launcher reads the final status only after the watchdog's process has ended.
- If that write is really lost, the launcher says the watchdog ended without saying why, which is true of what it can know.

**h.** Mutations above. Both removed tests were G11's own.

**i.** Report lines not true of the code at 10f62435:
- State table, "Try the window again | one more start (sent to the pages when they were shown)": not when the window had fallen back before the programs started (Q2).
- State table, "the choice changed to window | stored; the window started | the window's words": the window cannot reach the running pages, and "The pages are shown in the app's own window" is untrue then (Q1).
- Point 3, "sent on to the pages when they answer: no second tab": only within one start (minor 7).
- Point 5 / wordWindowHow, "If the program stops ... the window opens again": not at a clean stop (minor 1).
- "Every window on the screen is therefore the running launcher's, and every rule above holds for it": true of ownership. The front start is ended at 10 s even when it is the only window (N2).
- "Known and not built": true as worded, the download and the outside-link line being the window's next build.

## Every start of the window (10f62435)

| event | where | guard | bound |
|---|---|---|---|
| the setup is shown | `launcher.go` 462 → `present.go` 275 | `inWindow`; `startWindow`'s guard (`fell`, `ending`, own one runs, `starts > 0 && !again`) under `w.mu` | 1 per run |
| this start's watchdog started, or a running one found | `launcher.go` 591, 511 → `present.go` 311 | `inWindow` (N1); `rescope(true)` restarts a running window with other addresses, else `startWindow`'s guard | 1 per start (each needs the owner's Save or Try again) |
| a refusal or an end (run loop) | `launcher.go` 284-285 | `rescope(false)` as above; `showPage` restarts a window the person closed (D) | 1 per `resultWait`; the loop then waits for the owner |
| the pages' bound passed; "no pages" | `launcher.go` 630, 666 → `showPage` | as above | at most 1 each per start |
| the pages answer | `openPages` | starts nothing (arms the redirect) | 0 |
| the window ends 0 / non-zero | `windowEnded` | `closed` / `fell` | 0 |
| Try the window again | `ui.go` 461-469 → `present.go` 509 | token, same origin, view number, `fell`, not `ending`, none running | 1 per accepted press |
| the choice changed to the window | `ui.go` 470 → `present.go` 641-646 | token, origin, view number; the same choice does nothing; stored first | 1 per accepted change |
| a second start's ask, own window closed | `ui.go` 350 → `present.go` 583-587 | the ask's checks; 1 per 2 s | 1 per 2 s |
| a second start's ask, own window open (`frontWindow`) | `present.go` 579-581, 594 | the ask's checks; 1 per 2 s; none of `startWindow`'s guards | 1 process per 2 s, each ended at 10 s (N2) |
| the launcher's address held by a non-launcher (`another`) | `launcher.go` 345 | as the own run | 1, plus presses |
| the pages' address changed | `rescope(true)` at the programs' start | as above | 1 per start |

## Every end of the window (10f62435)

| event | what is ended | by what handle |
|---|---|---|
| the launcher returns (Quit, Close, any return of `run`; `another`) | its own last window | the `Proc` from `env.Start`: the Ctrl-C helper (pid and creation time checked again), 3 s, then `Kill` (creation time checked), 2 s |
| the pages end / a refusal / other addresses (`rescope`) | its own running window | same; marked `stopped` |
| the choice changed to the browser | its own running window | same; marked `stopped` |
| a front start still there after 10 s | that process | same (`endProc`), not marked: its exit is only logged |
| the launcher dies (Task Manager, a crash, Windows) | every window process it started, own and front | its kill-on-close job: one job per process, holding only that process, assigned by a handle opened by number with the creation time checked while the launcher holds the process; logged when it could not be made |
| the launcher's orderly end while a front start runs | the front start | its job, at the launcher's exit (`endWindow` does not end it) |
| the person closes a window; a front start ends with 0 | nothing else | none |

The clean stop still reaches only the window (its own hidden console; the helper ignores the event).

---

# Closing look (f9afdd05)

Narrow, on the six points asked. `git diff 10f62435 f9afdd05 -- archiver/internal/launcher`; tree untouched; stand-ins
only; PC measured before each go command (free 2.8 GB, CPU 59-65%). The round's eight named tests
(`TestWindowChoiceToWindowReachesRunningPages`, `...TryAgainAfterEarlyFailureReachesPages`,
`...FrontStartAdoptedWhenOnlyWindow`, `...ChoiceToBrowserDuringRestart`, `...SetupNamedPortTakenMeanwhile`,
`...SetupAnsweringPortNotNamed`, `...ChoiceFromPage`, `...AskThreeDoubleClicksBound`) pass.

**Verdict: may be listed.** The three points below are minor and can go to a later piece.

1. **N1: sound.** `windowForPages` (`present.go` 321-329) names the pages before it looks at the mode. In the browser
   mode no window runs, so `rescope(true)` only sets the flag. `changeChoice` to the window arms the redirect when the
   pages are shown (≈ 752-759), and `tryWindowAgain` already did. The case "the setup's look finds the port answering,
   then an early failure and Try again" is right by reading:
   - the setup's window names L alone (`launcher.go` 465);
   - it fails, and the browser takes over;
   - Save and start: `windowForPages` names P at the watchdog's start (no window runs: nothing restarted);
   - the pages answer in the browser;
   - Try again: the window starts on L and P, with the redirect.
   If the foreign program still holds P at Save, the start is refused and `rescope(false)` clears the flag.

2. **N2: sound, with one minor (CONFIRMED by reading).**
   - **Two windows taken as the launcher's own:** impossible. Adoption is under `w.mu`, sets `w.proc` and clears
     `w.front`; `startWindow` refuses while `w.proc` runs; the 10 s branch adopts only when no own window runs.
   - **A window nobody watches:** none. An adopted one gets `wg.Add` (in `adoptFront`, 425) and `watchWindow`. A
     front start that is not adopted is either seen to end or ended by its handle.
   - **The job:** the front start goes through `spawnWindow`, so it is in its own kill-on-close job from its start,
     and an adopted window is in a job.
   - **What is wrong:**
     - **Minor A.** The job's outcome of the front start is discarded (`p, _, _ :=` at 669), and `adoptFront` does
       not set `w.noJob`. If the front start's job failed and the earlier window's had not, the adopted window runs
       outside a job while the page does not say so; a dying launcher would then leave it. Smallest change: keep the
       front start's `jobOK` beside `w.front` and set `w.noJob = !frontJobOK` in `adoptFront`.
     - **Minor B (PLAUSIBLE).** The 10 s branch (698-700) adopts without looking at the choice. A front start that
       became the only window, followed by a change of the choice to the browser within those 10 s, leaves an
       adopted window in the browser mode. Smallest change: adopt only when `l.choice() == OpenWindow && !w.fell`,
       else end it.

3. **N3: sound for its purpose.** `startWindow` returns at once when the choice is not the window (380). A race of a
   few microseconds is left: the choice is read before `w.mu` is taken, while `changeChoice` reads `w.proc` under
   `w.mu`. Not worth more code now.

4. **The setup's look: sound, with one minor that is older than this round.**
   - The look is bounded by `probeBound` (3 s: the client's timeout and the context).
   - The window is sent to P only by the redirect, armed in `openPages` after `follow`'s own look saw the pages'
     mark. The setup and refusal views carry no pages link. A refusal clears the naming before "Try again".
     `TestWindowSetupNamedPortTakenMeanwhile` checks the foreign-program case (a restart on L, ten navigations,
     nothing sent).
   - **Minor C (PLAUSIBLE).** The view after the pages' bound passes (`launcher.go` 639) shows the pages' link
     although their mark was never seen, while P is named. A program that took P between the one bind and the
     collector's own bind would be one click away under the app's title. Smallest change: no `pages` link in that
     view (or only after a look that sees the mark).

5. **The minors: sound.**
   - **The change of the choice.** It re-reads the file and writes only `pages_open` into it (734-740), so a hand edit
     is kept. A file that does not load as OK is never written; the page then says it was not changed. Its words say
     "or was written by another version", which is loose for an invalid file but harmless. Nothing else writes the
     file after the setup, so no change can be lost.
   - **The folder box.** While a box is open, a double-click is answered 204 and does nothing (outcome 5, logged at
     most every 2 s). The page does not say so. It is acceptable because the box is the window in front then; one
     sentence on the box's view ("opening tgarchive.exe again does nothing while a folder box is open") would make
     it said.

6. **Mutation (the early return put back before the naming), applied in an overlay:**
   `TestWindowChoiceToWindowReachesRunningPages` FAILS ("the window does not name the running pages"). Caught, as
   claimed.
