# Brief: independent review of the pause of downloads (G1c) — read-only, short

You are an independent reviewer. You did not write this code. Find what is wrong with it before it runs on a
real Telegram account. **You change nothing in the tree.**

## What to review
The branch `wip/pages-g1` in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-g1` (Go module in
`archiver/`): **the commits after 1fd0d6d up to 0ee2c00** (the pause), `git diff 1fd0d6d..0ee2c00`, and, as far
as the pause leans on them, the two commits before (eb2aabd, 1fd0d6d). What was asked:
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-G1c-pause-downloads.md`. The author's account: the section
"Pause downloads" of `archiver/docs/progress/pages-g1-REPORT.md` (read it last; take its word for nothing).
The pieces: `internal/collector/pausedl.go`, the 8 lines in `account.go` (`engineTask`), the line in
`ownerstop.go`, `pages.go`'s pause calls, `internal/collector/livepages`, and in `internal/server` the pause
routes, the snapshot's pause fields and the scripts (`main.js`, `pages/overview.js`, `accounts.js`, `queue.js`).

Background: the collector (`internal/collector`; read `account.go`'s `runSession`, `engineTask`, `startEngine`,
`stopEngine` and how `Config.DownloadsOff` works) holds each account's Telegram session: an engine (downloads),
a reader, a monitor. The owner asked for a pause of **downloads only** ("pause for X hours"), because the
owner's phone shares the account's download allowance: while paused the account stays connected and nothing
may ask a file part, a reference refresh or a hash request for it; reading and live updates go on. An earlier
piece on this branch (already reviewed) is the owner's Stop of a whole account (`ownerstop.go`). Rules that
bind: a person's pause is never undone by the app; a stored mark that cannot be read fails closed; no file's
held, set-aside or wanted state is touched; time is the collector's injected clock; logs hold constant words
and numbers only; the pages' 2-second poll (`GET /api/live`) reads no table.

## Where to look hardest (not a limit)
1. **Can a download-side request leave while paused**, by any path: the window between a session's start and
   the engine task's first turn (the refresher is put in the supply's mux by `runSession` and taken out by the
   first paused turn); a pause that lands while `startEngine` runs or between a scan and a start; an engine
   restart for a new server; the supply or another account's engine reaching this account's refresher; the
   exact check's hash requests; anything that outlives `stopEngine`.
2. **Can a pause be lost or outlive its end**: Pause, Resume and the loop's read interleaved; two tabs; the
   program restarted with time left or with the end passed; the clock; a session that ends and starts again
   while paused (`heldFor`); Stop and Start around a pause; a pause for every account when one is removed.
3. **Does it stop cleanly**: what `stopEngine` does to transfers in flight when called for a pause (attempts,
   checkpoints, counters, the window's levels); ten pauses in a row; goroutines left (the per-second sleep's
   helper); the engine task spinning after the session ends.
4. **The detection the engine task does each turn is skipped while paused** (the exact check's counts, the
   frozen and signed-out watch): does anything get lost or delayed that matters?
5. **The pages**: the routes behind the guard and absent in `tgarchive app`; what the page says when accounts'
   pauses end at different times, when the record is unreadable, when the pause is for this run only; the
   time left computed where (the server's clock or the browser's); a menu repainted from under the pointer.
6. **The tests**: one that judges on real time; one that would pass with the pause not holding (its author
   says one test was flaky and was made strict: look at it); the mutations claimed.

## How to work
Read the code yourself. Prove a finding where it is affordable with a probe test in your own scratch folder
loaded with `go test -overlay` (the tree stays untouched), else by quoted lines. Mark each finding
**CONFIRMED** or **PLAUSIBLE**. Load: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`,
one go command at a time, `GOGC=25 GOMAXPROCS=2 go test -p 1 -run '<names>' ./internal/<package>`: named tests
only; no whole run of `internal/collector` or `internal/catalog`, no race detector, no Docker; look at free
memory before each go command and wait when it is under 2.5 GB. Never touch `E:\T\tg-dl`, the folders `a3`,
`b`, `app`, the copy `wt-pages-g1-look`, any real catalogue, media, session or account. Invented data only.

## What to hand back
Write `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-G1c-pause.md`: findings in order of harm (must fix
before merge; should fix; minor), each with its mark, file and lines, one concrete sequence of events, and
the smallest change you would ask for; then what you checked and found sound; then what you did not look at.
Your final message: the count by class and each must-fix finding in one line.
