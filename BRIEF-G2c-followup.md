# Brief G2c: the Queue page's follow-up after its second independent pass (pages track, session P3; 2026-11-15 23:30)

For one Opus coder. The Queue page (G2) is merged and installed. Its second independent pass is
`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-G2-queue-2.md` (0 must fix, 3 should, 6 minor; 12 of the first
review's 14 findings closed, 2 partly): **read it in full first**, with its probes in
`C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g2b-scratch` (each must stop showing its fault after
your round; its measurements are the numbers you must not make worse). The first review and the fix round's
brief, for what was meant: `REVIEW-G2-queue.md`, `BRIEF-G2b-fixes.md`. Every finding is accepted. Where this
brief and the review's "smallest change" differ, this brief wins; where you find either wrong, say so.

## Why
The single writer is shared with the downloads: the catalogue's own bound for one write transaction is about
70 ms (500 rows). A click on a small group beside 200,000 set-aside files of another reason held it 246 to
314 ms, because the click's pick walks the server's whole set-aside range inside the write. And a page's
numbers add up in every answer, or the owner stops trusting them.

## The fixes
1. **Finding 1: the pick is a read; the write is by id.** "Try these again" first picks at most 5,000 file
   numbers on the reader side (the same order: unique before probable, by set-aside time; not due yet; that
   server, that reason, not the owner's), then ONE write statement makes exactly those due, by id, with every
   condition checked again in the write (still set aside, still that reason and server, still not due), so a
   file that moved between the two is left alone. Still one write per click, never a loop over files. The
   answer's count is what the write changed. Tests: `TestRetryGroupIsOneStatement` keeps its meaning (one
   WRITE statement through the counting wrapper; the read is counted apart); at 300,000 files with 200,000 of
   another reason, the write touches only the picked rows (judge by rows and the plan, log the time); a file
   that leaves the group between the pick and the write is not made due (a hook between the two).
2. **Finding 2: the rows that carry a click come from the same reading as the counts.** The file-by-file
   set-aside list is read inside the lists-of-now read transaction (with the failed groups, gone, in transfer
   and their counts), under that reading's "As of". Test: the review's `TestRvbS3OneAnswer` as a test: no
   answer shows "Set aside 0" beside a file-by-file row.
3. **Finding 3: no reread of the costly part on a set-aside change; a bounded storm.** With fix 2 the costly
   part (wanted counts, next lists, held with evidence, the switch) keeps its 30 s floor whatever the
   set-aside total does, under its own "As of", and the page says in one sentence that those figures may be
   up to 30 s older than the lists above them. `TestOpenPageStatementsBounded` gains a storm minute (a file
   set aside every second) and its bounds become fixed numbers of statements and of workings-out, written in
   the test (finding 4: not a cost measured in the same run). If the lists of now cost more than a quarter
   second at 200,000 set-aside files (the review measured 242 to 276 ms), give them the rule the Overview has:
   their floor grows to 30 s above that cost, said on the page.
4. **The minors.** (5) After a retry the answer says how many of the group are left only when it knows; a
   group not among the 50 shown is said as "not among the groups shown", never "0 left". (6) The pause's
   sentence is true for a pause with an end ("when the pause ends at <time>, or when you resume") and Start
   is not named as ending a pause; "back in line by rank" becomes true for a file whose chat no longer
   collects it ("or held as not collected"). (7) A refused click's words are cleared on a change of the
   server tab. (8) A click whose write succeeded and whose reload failed says "Done; the page could not be
   read again: reload it", never "refused", and its button stays off until the reload. (9) After a poll
   rebuilds a region whose focused control's row is gone, the keyboard goes to the next control of the same
   kind (the rule of `focusAfter`), not to the server tab. A node test for each of 5 to 9 where the page
   decides it.

## Rules (hard)
- Copy and branch: make them yourself: `git -C C:/Users/trabi/Claude/Projects/Telegram/repo-archiver fetch private`,
  then `git -C C:/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add -b wip/pages-g2c ../wt-pages-g2c <the head of private/claude/charming-feynman-vm2xia>`
  (write the exact commit into your progress file). Work only in
  `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-g2c`.
- Product code only in `internal/server` (`queuenow.go`, `queue.go`, `overviewcache.go`) and the scripts
  `web/assets/js/pages/queue.js`, `web/assets/js/queuelists.js`. No catalogue function, no schema step, nothing
  in the collector, the engine, the supply, the store, the viewer, `faketg`. Another coder of this track works
  in `internal/server` on the Chats page and the Settings page at the same time (new files, `pages/chats.js`,
  `pages/settings.js`, lines at the end of `server.go`'s route list): do not touch those.
- Nothing runs against Telegram; invented data only; never touch `E:\T\tg-dl`, the folders `a3`, `b`, `app`, any
  real catalogue, media, session or account; start no installed program; leave every running process alone.
- New log, error and state text is constant words with numbers. No test judges on seconds of real time; tests
  at 300,000 files skip under `raceOn`.
- Go: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, one go command at a
  time, `GOGC=25 GOMAXPROCS=2 go test -p 1 -run '<names>' ./internal/server`, named tests only; no whole-package
  run, no race detector, no Docker. Before each go command:
  `powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`;
  wait when free memory is under 2.5 GB or the CPU is over 85%.
- After any change under `web/assets/js`: `TestScriptsNoDuplicateOrMissingNames`, `TestAssetsStaySmall` (every
  script under 600 lines) and a module parse of each script with node.
- **Open it before handing back:** `TestPagesHold` from your copy (`TGARCHIVE_PAGES_HOLD=127.0.0.1:8795`), the
  Queue page in the built-in browser if you have one: a group's retry, a file's retry with the keyboard, a
  change of the server tab after a refused click. Say exactly what you saw.
- Any file that holds a Windows path is written with the file-writing tool, never from inside a shell or script
  string.
- Commits: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; commit work in progress as you go and push only
  `git push private wip/pages-g2c`. Never push, merge into, rebase or switch any other branch; never stash.
- Keep `archiver/docs/progress/pages-g2c-PROGRESS.md` current from your first action; at the end
  `archiver/docs/progress/pages-g2c-REPORT.md`: each finding with its change and the test that fails without
  it; the write's plan and logged times at 300,000 files beside the review's; the statements of an open page's
  minute (nothing changing, a change every second, a storm) beside the review's table; mutations (the pick
  back inside the write; the file-by-file list from the older reading; the reread put back); what you saw in
  the browser; what was NOT verified; a drafted final commit message.

## Hand back
Commit-ready: everything committed and pushed, the tree clean, `gofmt -l` clean, `go vet ./internal/server/`.
Your final message: the head commit and the main head it sits on, what is fixed and tested, what is not,
every departure, and your doubts, plainly.
