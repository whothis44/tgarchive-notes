# Brief: the independent review of G19, changing the folders (pages, P6, 11-16)

You are an independent reviewer (Opus, high effort). You did not write this code. **Read-only on the
copy `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-folders`** (branch `wip/pages-folders`, head
a281c273; base 78739d59: `git diff 78739d59 a281c273`). You edit and commit nothing there. Probes go
into `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g19-scratch` (make it; plain files loaded
with `go test -overlay`; builds and scratch folders for a look go there too). Write the review to
`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-G19-change-folders.md` with the Write tool.

## What the piece is
Read `BRIEF-G19-change-folders.md` in the project folder (what was asked, and the owner's words behind
it: at the first real start the owner named ANOTHER PROGRAM'S LIBRARY as this app's library and could
not change it) and the coder's report `archiver/docs/progress/pages-folders-REPORT.md` and
`pages-folders-OWNER-STEPS.md` on the branch. In short: the launcher (`internal/launcher`) gets "Change
the folders" (one confirm, the app's programs stopped as Quit stops them, the setup shown again); the
setup looks at each folder before it saves and asks a second explicit yes for a non-empty library or a
non-empty staging folder that is not this app's; nested folders are refused; the collector gets a
start flag `-launcher-url` (lent lines, commit c1d80f48) and the app's pages a "Program" link and a
"This program" region on Settings.

## What to decide, in this order (this piece starts and stops programs for the owner and decides
## where the app writes: be hard on it)
1. **Can the app ever come to write into a folder the owner did not knowingly give it?** The second
   yes: is it enforced at the SAVE on the launcher's side (not only drawn on the page): a save request
   made by hand without the yes, with a yes given for another path, with the path changed after the
   yes, with the yes for the library used for staging; the same through "Change the folders" and
   through the first setup; a folder that could not be looked at (no answer, refused): is the yes
   asked; a folder that fills between the look and the save. The nesting refusals: either way round,
   the same folder twice, inside `programs`, by another case, with a trailing separator, a relative
   path, `..` parts, a UNC path, a mapped drive beside its UNC name (say what cannot be told and
   whether the page says so). The existing writability check writes a temporary file into the folder:
   does it now run only AFTER the look, the nesting check and the yes, on every path?
2. **"Change the folders": can any order of clicks or ends leave programs running against the OLD
   folders while the settings say the new ones, or two collectors, or none with the page saying
   "running"?** A click during a start that has not finished; twice; in two windows; while a Quit is
   held (the sign-in page holds a Quit for a code); when the watchdog does not end within its bound;
   when the pages do not answer the count; Cancel; Save and start that then fails; the launcher ended
   in the middle (what does the next start show). Are the new POST routes behind the launcher's page
   guard as every change is? Does the confirm survive only where it should (the coder says: kept on
   the launcher's side for that view only)?
3. **The look itself:** never a file opened or read, never a link followed out, nothing written; a
   goroutine held by a share that never answers: how many can pile up (one per look? bounded?);
   **nothing but numbers and fixed words leaves it**: search the page's answers, the launcher's log
   lines and the tests' failure messages for any entry name or path (the launcher's log rule is "no
   path in any line": the package has a test for it; is the new code under it?).
4. **Are the page's sentences true?** Each sentence the setup now says about what a change means (the
   report's B) against Core's code, read by you: places stored relative to the library; a file the
   copier cannot find wanted again; the staging mark and lock; a `-library` that differs from an
   archive's own `library_dir` refused at the start; "an archive made by the launcher has no
   `library_dir`". And each step of `pages-folders-OWNER-STEPS.md` (it goes to the owner TODAY, for the
   build of 78739d59): would a careful person following it end where it says? What does it not say
   that they will meet (the VPN adapter chosen again; the Windscribe entry; the sign-in kept)?
5. **The lent lines and the pages' side:** `-launcher-url` takes only `http://127.0.0.1:PORT` (try
   others: a host name, another address, a path, userinfo, a port of 0 or 80, upper case); with the
   flag absent every page and answer is byte for byte the head's; what `GET /api/program` gives and to
   whom (is it behind what the other reads are behind); the header's link and the region cannot be
   made to point anywhere else.
6. **The tests:** for each new rule, is there a test that fails without it (plant the change by
   overlay: the yes not enforced at the save; nesting one way only; the mark's name changed; the
   write check before the look; the count shown as a name)? Test functions removed or renamed: the
   coder says 0.
7. **A look at the pages, which nobody has made:** build the launcher from the copy into your scratch
   folder (through the lock script) and run it there with stand-in programs as its tests do, or use a
   look test if the package has one; `LOCALAPPDATA`, `APPDATA` and `TEMP` redirected to scratch
   folders; ports above 20000; open the setup page (first setup; after "Change the folders"; with a
   non-empty invented library; with nested folders) and the app's Settings page's new region (the
   server's demo or fixture with the flag set) in Edge headless at a wide and a narrow width
   (`--headless=new --disable-gpu --no-first-run --disable-background-networking --disable-component-update --disable-sync --proxy-server=http://127.0.0.1:9 --user-data-dir=<a scratch folder> --virtual-time-budget=8000 --dump-dom <address>`:
   127.0.0.1 is reached directly, everything else goes to a dead port). Say what a person reads there,
   whether anything is cut, overlaid or [name removed], and what you could not open.

## Rules
- The owner's real app may be RUNNING on this PC from `C:\Users\trabi\tgarchive-app` on ports 8786,
  8787, 8788: never open, list, read or signal anything there, never ask those ports, never end a
  process you did not start (by the id you got at its start, never by name). Nothing under `E:`,
  nothing of the old app. Invented data only. No real collector, nothing to Telegram.
- Every go, gofmt and vet command through
  `bash /c/Users/trabi/Claude/Projects/Telegram/runs-pages-p6/go1.sh /c/Users/trabi/Claude/Projects/Telegram/wt-pages-folders/archiver <command...>`
  (it may wait some minutes for the track's lock). Named tests only, nothing over three minutes a
  command, no whole package, no race detector.
- Never a Windows path inside a shell string (`/c/...` in bash; the Write tool for files; forward
  slashes inside an overlay's JSON). Never capture the output of a command that starts a hidden
  program: output to a file. Leave no process, no browser and no file in the copy (`git status` there
  stays clean).

## The review file
Findings numbered, each **must fix / should fix / minor**, each **confirmed** (the probe's name and its
decisive line) or **plausible** (read, not run). The last line is one of: "may be listed", "may be
listed after these fixes: <numbers>", "not yet". Hand back at most 12 lines: the verdict line, the
counts by weight, each must-fix in one line, whether the owner's steps file may go to the owner as it
is, what you saw of the pages, what you could not check.
