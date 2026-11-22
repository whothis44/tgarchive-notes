# Brief: independent review of G5 (the Staging page) — read-only

You are an independent reviewer. You did not write this code and you owe its author nothing. Find what is
wrong with it before the owner reads it to decide whether the library on the NAS is away, the staging disk is
full or a file is stuck. **You change nothing in the tree.**

## What to review
The branch `wip/pages-g5-main` at 84d9991a, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-g5m` (Go
module in `archiver/`), against its base 5b29e28b: `git diff 5b29e28b..84d9991a` (24 files). What it was asked
to do: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-G5-staging-page.md` (all of it, the last section
included). Its author's own account: `archiver/docs/progress/pages-g5-REPORT.md` (read it last; do not take its
word). The pieces: `internal/server/staging.go`, `stagingread.go`, `stagingview.go` (the seam `Staging`, the
route, the queue's reading, the verdict), the changes in `server.go`, `liveroute.go`, `overview.go`;
`internal/collector/livepages/staging.go` (the adapter, the copy speed from samples);
`internal/collector/pagesstaging.go` (a read-only source) and one line in `pages.go`; the scripts
`web/assets/js/pages/staging.js`, `stagingrows.js`, the changes in `main.js`, `pages/overview.js`, `index.html`.
What it stands on (read these; none is edited): `internal/store` (`counters.go`, `copier.go`, the writer),
`internal/collector/staging.go`, `internal/catalog/staging.go` (the ledger `file_queue`: its states, `stuck`,
`next_try`, `CopyStuck`, `CopyLater`, `CopyCopied`).

Background: downloads are written to a staging folder on a local disk and copied to the library on a NAS over
Wi-Fi by copiers; a ledger row per file says waiting, copied and not verified, failing, stuck. The collector is
the single writer of the catalogue and the pages' handlers run inside it. The rules: every number says what it
counts and when it was read, and the numbers on one page add up; a state says why in plain words and the
states are told apart correctly (the old app once showed "no progress for 55 min" for a page that could not
refresh, and spread staging over three places); nothing a page does may hold the single writer long or read
the library; `GET /api/live` reads no table; an action is one bounded statement by key; logs hold constant
words and numbers only (a folder's path may be shown on the owner's own page, never logged); every change
route needs same origin and the run's token.

## Where to look hardest (not a limit)
1. **The verdict is true in every state and their order is right.** For each state the store can be in (read
   the store, not the report): the library away (how the store knows, since when, and what the page says while
   the store has not noticed yet); the library's disk full; the staging disk away; staging without room (the
   writer then writes straight to the library: does the page say so, and is "free space under keep-free" the
   store's own rule or the page's guess); copiers busy; files waiting with no copier busy (why can that be:
   is each cause said, or is one sentence covering causes that need different actions); waiting for a
   read-back in speed-limited hours; nothing to copy. Two at once; a state that flips every few seconds; the
   program not running (the seam nil); the program running with downloads paused, the account stopped.
2. **"Try its copy again" (`UPDATE file_queue SET stuck = 0, next_try = 0 WHERE file_id = ?1 AND stuck <> 0`).**
   Is it what `CopyStuck(id, 0)` does, exactly, or does the catalogue's own door do more (attempt counts, the
   failure's record, a kick of the copier); is un-sticking safe for EVERY reason a file is stuck (read every
   place that sets `stuck`: a file whose staged bytes do not match their hash; a file whose library copy
   disagrees; a file missing from staging): can the click make the copier publish bad bytes, overwrite a good
   library file, or loop a failing file forever; `next_try = 0` against the copier's own doubling pause; a
   click while the copier holds that row; one statement, by key: its hold of the writer.
3. **"Let it go on" (`ReleaseWantAgain`)**: what it lets happen (files wanted again after their staged copy
   was lost: downloads), whether its cost is said before the click, whether it can be clicked when nothing is
   held, twice, or while the program stops.
4. **The numbers.** Each one down to its statement or gauge: what it counts, its unit, its reading's time;
   do "waiting + copied not verified + failing + stuck" add up to the ledger at one reading (one read
   transaction?); the hour's and the day's figures across the hour's turn and a restart; the copy speed from
   samples (the first 30 s, a counter that goes back at a restart, a sample gap while the PC slept); free space
   read by the server (a path that is away: does the read hang a handler, and for how long); "full for 10
   minutes counted from when the pages first saw it": what it says after a restart of the pages.
5. **The poll.** `/api/live` with the store's gauges: prove it reads no table and takes no lock the copier
   holds long; the queue's reading by its floor (5 s, 30 s when slow): its cost at 100,000 ledger rows
   (measure: the author had 202 ms on a busy PC), what an open page costs a minute calm and in a storm, two
   tabs; the Overview's use of the same reading up to 60 s old: what it can show as true when it is not.
6. **The seam, the adapter, the collector's source.** `pagesstaging.go` is in the collector's package: is it
   read-only in fact (no write, no lock order with the store's or the collector's locks that can deadlock a
   stop); the adapter's sampling goroutine or timer (is there one; is it stopped at the pages' stop); what the
   page gets while the collector starts or stops.
7. **The guard, the log, the scripts:** the routes behind the guard and absent or 409 without the program; no
   path, file name or id in any log line or error; text put into the page as markup (file names and paths are
   hostile input); the click gate, focus after a click, a control whose row left; words false at phone width
   or when a list is cut ("the first N of M").
8. **The tests:** one that judges on real time; the rig test's "came back by itself 60 s of the clock after the
   fault ended" (what makes it so, and can it pass vacuously); a mutation the author says was caught that its
   test would not catch; tests that need Windows and do not skip off Windows.

## How to work
- Read the code yourself. Prove a finding where you can with a probe test in your own scratch folder
  `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g5-scratch`, loaded with `go test -overlay` (the tree
  stays untouched), or by reasoning from quoted lines. Mark each finding **CONFIRMED** or **PLAUSIBLE** (say
  what would settle it). Timings are "looks like" numbers: say the PC's CPU load beside each.
- Go: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, one go command at a
  time, `GOGC=25 GOMAXPROCS=2 go test -p 1 -run '<names>' ./internal/<package>`: named tests only; no whole run
  of `internal/server`, `internal/collector`, `internal/catalog` or `internal/store`, no race detector, no
  Docker. Before each go command:
  `powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`;
  wait when free memory is under 2.5 GB or the CPU is over 85%.
- Nothing runs against Telegram. Never touch `E:\T\tg-dl`, the folders `a3`, `b`, `app`, any real catalogue,
  media, session, account, staging folder or library; start no installed program; leave every running process
  alone. Invented data only. Print counts, sizes and timings only.
- Any file you write that holds a Windows path is written with the file-writing tool, never from inside a shell
  or script string.

## What to hand back
Write `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-G5-staging.md`: findings in order of harm, each with its
mark, the file and lines, what goes wrong in one concrete sequence of events, and the smallest change you would
ask for; first the ones that must be fixed before the merge, then the ones that should be, then minor ones;
then a table "why a file is stuck -> is un-sticking it safe" (point 2); your measurements; what you checked and
found sound; what you did not look at; and whether the race detector is needed on `internal/server`,
`internal/collector/livepages` or the collector for this piece and why. Your final message: the count by class
and the must-fix findings in one line each.
