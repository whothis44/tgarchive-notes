# Brief W3: the Overview as the dashboard, every number a link to its filtered place (pages, P7, 2026-11-21)

You are the coder of this piece: Opus 5.5 at high effort. You hand back commit-ready work on your branch.

## The house rules (binding)
- Invented data only, in tests, fixtures and screenshots. Nothing of a real name, text, path, id or link
  in any output, test, commit or report: numbers and code names only.
- **The owner's program runs on this PC (launcher, watchdog, collector, one window). Never stop, restart,
  signal or reconfigure it; never read or write its folder, its `%LOCALAPPDATA%`/`%APPDATA%` settings, its
  catalogue, or anything under `E:\`.** Test processes get `LOCALAPPDATA`, `APPDATA`, `TEMP`, `TMP`
  redirected into your copy. Ports: `:0` or from 27950 up. **No window on the owner's screen:** a browser
  only headless (`TGARCHIVE_BROWSER` naming Edge), screenshots to files in your copy. Nothing runs against
  Telegram (the fake only). No new Telegram request of any kind.
- **Every go, gofmt or vet command through the track's lock script, one at a time:**
  `bash /c/Users/trabi/Claude/Projects/Telegram/runs-pages-p6/go1.sh /c/Users/trabi/Claude/Projects/Telegram/wt-pages-overview/archiver go test -p 1 -count=1 -run '<names>' -timeout 15m ./internal/server/`
  (exit 97: nothing ran, try again; others share the lock). **Named tests only** while you work: the whole
  `internal/server` (6 minutes) is run once by the session at the end, not by you. No race detector.
  Long commands in the background (your shell tool stops at 10 minutes).
- Commits: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message ending with
  the line `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Commit work in progress as you go and
  push it: `git push private HEAD:wip/pages-overview` (only that branch; never main, no tag, no merge of
  anything into anything else, no `git stash`). New log lines (`ixLog` or the package's logger) use
  constant format strings.
- **Do not edit `internal/appshell`** (the viewer track's coder adds to it now) or `internal/viewer`, or
  any package outside `internal/server` and `internal/collector/livepages` without saying why in the
  report; if you need a door from another package, stop at a written door in the report.

## Where
Make your copy, one command from the project folder:
`git -C repo-archiver worktree add -b wip/pages-overview ../wt-pages-overview af4ca40e`
The Go module is in `archiver`. Report: `archiver/docs/progress/pages-overview-REPORT.md` (on the branch).

## Read first (in full)
1. `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-ONE-WINDOW.md` point 4 and `DESIGN-ONE-WINDOW-HOW.md`
   section 3 (the Overview's numbers: "each to the owning server's place with its filter in the address";
   "a number with no such address is not a link"; "Counts on the Overview are read from memory or by cheap
   reads; nothing in the background reads the library").
2. `internal/server/web/assets/js/pages/overview.js` (all of it), `internal/server/overview.go`,
   `overviewcache.go`, the page router in `web/assets/js/main.js` (the hash router: `#/name?...`), and the
   pages Queue, Chats, Mirrors (`queue.js`, `chats.js`, `chatmirror.js`), Staging.
3. `internal/appshell/shell.go` lines about the library's places (`lib:new`, `lib:deleted`, `lib:first`,
   `lib:copies` and their viewer addresses) and how the shell knows the viewer's address and says a dead
   place's reason: **use the same addresses and the same dead words** (read the shell's answer the page
   already has, or the same Options; do not invent a second set).

## What to build
1. **Every number on the Overview that counts something a place shows becomes a link to that place,
   already filtered** (an `<a>` with a real `href`, keyboard reachable, the number's text unchanged). A
   number with no place stays plain text. A viewer place with no viewer address is not a link: the number
   stays plain and its title says the shell's dead words. Make a table in the report: every number on the
   page, its place, its address, or "no place".
2. **Filters by address on the pages' own places**, as far as the numbers need them: the Queue
   (`#/queue?show=waiting`, `now`, `failed`, or the words that fit the Queue page as it is), the Chats page
   (for example chats joined and not collected), Mirrors (wants that wait for the owner's word, blocked
   ones). Each page reads its filter from its address, shows it as one removable chip ("Showing: waiting ·
   show all"), and a count on the Overview equals what the filtered place lists (the same read or the same
   rule: say which in the report).
3. **"Needs you" on the Overview** (the design's second half), each a number and a link, each shown only
   when not 0: held probable copies (the viewer's probable copies place); a mirror waiting for the owner's
   word or blocked (Mirrors, filtered); chats joined and not collected (Chats, filtered); failed files
   (Queue, filtered). Read with cheap reads only: an index, a count the catalogue already keeps, or the
   overview cache's own read; **measure each new read on a fabricated catalogue of real size**
   (`internal/fabricate`; extend `TestOverviewCostAtSize` or its kind) and give the times in the report;
   a read over 50 ms at that size is not added: say it instead. Nothing reads the library's files.
4. **The one window:** a viewer link opens in the same window (the window's gate lets the viewer's address
   through); say by reading how a click on a viewer address from the pages behaves today, and keep it so.
5. Everything else on the Overview stays as it is (words, regions, the live updates of the lanes: a live
   update must keep a number's link and not rebuild the region under the keyboard's focus).

## Tests (named, yours)
- Pure view functions (number to link or text, a filter's chip) under node as the package does already.
- The browser test (`browser_test.go`'s kind, headless Edge, `TGARCHIVE_BROWSER`): on the empty catalogue
  and the invented archive, with and without the program, with and without a viewer address: every link's
  `href`, each followed once lands on its place with the filter chip shown and the same count; no console
  error; no page wider than the screen at 390 px.
- Two screenshots for the report, dark and light (`--force-prefers-color-scheme`), 1400x900, the Overview
  on the invented archive; look at them yourself.
- Name every test added; remove or rename none without saying why.

## Hand back
Your branch pushed, the copy clean, the report with: what was built; the table of numbers; the reads and
their measured times; the tests and what each would catch; what you did not verify. Your final message:
the branch's head (8 characters), the report's path, and one line of what is not verified. Nothing else.
