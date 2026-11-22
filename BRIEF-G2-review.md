# Brief: independent review of G2 (the Queue page: downloading now, just finished, failed with reasons, "try these again") — read-only

You are an independent reviewer. You did not write this code and you owe its author nothing. Find what is
wrong with it before the owner uses it on a real catalogue beside a collector that is downloading. **You change
nothing in the tree.**

## What to review
The branch `wip/pages-g2` at da993b39, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-g2` (Go
module in `archiver/`), against its base 541743d: `git diff 541743d..da993b39` (17 files; product code in
`internal/server` only: `queuenow.go` new, `queue.go`, `server.go`, `overviewcache.go`, and the page scripts
`web/assets/js/pages/queue.js`, `chats.js`, `topics.js`, `web/assets/js/queuelists.js`; one rig test in
`internal/collector`). What it was asked to do: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-G2-queue-now.md`.
Its author's own account: `archiver/docs/progress/pages-g2-REPORT.md` (read it last, and do not take its word
for anything).

Background you need: the collector (`internal/collector`) is one process holding every Telegram session and is
the one writer of the catalogue (SQLite). Since the piece before this one (G1) the pages' handlers run inside
the collector's process, on its catalogue handle, while lanes claim files, the engine writes checkpoints and
saves, the reader stores messages and the supply requeues set-aside files. The rules that bind it: every
number on a page says what it counts and adds up; a list is shown in the lane's or the statement's own order,
never sorted again; a held or kept-held copy is never released by a bulk action and never goes before unique
files; nothing a page does may hold the single writer long (on record: one UPDATE of 33,334 due rows held the
writer 3.4 s, which is why `catalog.requeueChunk` is 500 rows a transaction: `internal/catalog/state.go`, the
comment above `requeueChunk`; and a batch action that scanned the whole queue per file timed out half done in
the old app); decisions are never made by matching words in a stored reason; logs hold constant words and
numbers only, never a name, title, path, id or text; every change route needs same origin and the run's token.

## Where to look hardest (not a limit)
1. **"Try these N again now" (`retryGroupSQL`, `handleRetryGroup`).** It is ONE statement by design:
   `UPDATE c_want INDEXED BY c_want_aside_lane SET retry_at = 0 WHERE state = 'aside' AND dc = ?1 AND reason = ?2
   AND reason <> 'by the owner'`. The index is `(dc, probable, retry_at) WHERE state = 'aside'`, so the range is
   the whole server's set-aside files whatever their reason, and the statement changes a column of the index it
   walks. **Measure, do not reason:** how long does this one statement hold the writer for a group of 500,
   15,000, 33,334 and 100,000 rows in a queue of 300,000 (and with 100,000 set-aside rows of ANOTHER reason on
   the same server: what does a small group cost then)? Put the number beside the 3.4 s on record. Say whether
   it must be done in bounded transactions (as `requeue` does, with `CheckpointGap` between) and what the
   smallest such form is that keeps "never a loop over files". What does a lane's claim, a checkpoint write or
   a save do meanwhile (the writer is one)? What happens when the request's context ends in the middle (the
   page closed, the pages stopping: `s.lasting(r)` is not used here), and when the statement fails?
2. **What "due now" then does, down in the supply and the catalogue** (`RequeueAside`, `RequeueAsideDC`,
   `asideBackSQL`, `DueAside`, the supply's own memory of "the next set-aside is due at T", the claim gate's
   third check): is a file made due by the page really brought back at the supply's next look, in every state of
   the collector (downloading, paused by the owner, stopped by the owner, the lane frozen, the server in a
   storm, no collector running)? Can a group made due starve or reorder anything: a held copy getting ahead of a
   unique file, a probable copy among the set-aside files going out as wanted, a file whose chat is no longer
   collected being downloaded, a file marked "exact check first" losing its mark? Does `retry_at = 0` mean
   anything else anywhere (grep every reader of `retry_at`)? `asides` and `attempts` afterwards: is "set aside
   again, for longer" true?
3. **Which files the statement can take that it must not:** a file the owner set aside by hand (only by the
   reason word: is the word written anywhere else, can a reason on record equal it by another path?), a file
   set aside by the engine for a cause where a retry is harmful or pointless (read every place that writes
   state `aside` and list its reason: are all of them fixed words? if any reason carries a number or a name the
   page will show thousands of groups with no limit, and the retry's `reason = ?2` round-trips text from the
   page), the group's `reason` being NULL or empty.
4. **The lists' statements at size and their truth:** `activeSQL` (order, the count when cut, the account from
   `claimed_by`), `finishedSQL` (the order by `fetch.rowid`: is a row ever rewritten or deleted so the order
   lies; one file saved twice; `COUNT(*) FROM fetch` every 5 s at 300,000 saves), `failedSQL` and `goneSQL`
   (two temporary b-trees: at 100,000 set-aside rows?), `placeOf` against the store's real states
   (`internal/catalog/staging.go`, `internal/store`): is any place word false for a state the store can be in
   (a copy in flight, a file being verified, a file lost and found)? Every number's sentence: does it say what
   it counts, and do the counts add up with the page's counts block?
5. **The kept answer in two parts** (`overviewcache.go`, `queue.go`): the costly part kept 30 s, the lists of
   now 5 s, "by the same change key". What can each show as true when it is not (what does not move the change
   key: a checkpoint, a save, a copier's step, the supply's requeue)? After the page's own click, are both
   worked out again, and can a second request get the old kept answer? Two requests at once for the same
   answer; a request for another server or limit; memory kept per server and limit without bound?
6. **The held-copy switch** (`handleHeldWait`): `Batch(LoadSettings, SaveSettings)` beside every other writer
   of the settings row (the Settings page's save, the collector's own settings); the sentence "within 5
   seconds" against where the supply really reads it; what the page's "next" lists show in the seconds between.
7. **The guard and the log:** both new routes inside the guard and refused in the demo; the 409 and the
   field errors; whether a reason string from the page reaches a log line, an error's text or a toast as markup.
8. **The scripts** (`queue.js`, `queuelists.js`, the changes in `chats.js` and `topics.js`): text put into the
   page as markup (names, reasons and chat titles are hostile input); a refresh that takes a control from under
   the pointer or the keyboard; a click while a request is in flight; words that are false when no collector
   runs, when downloads are paused, when the account is stopped; "the first N of M"; the shape rule (a region
   rebuilt or updated in place) losing an update for good; the viewer link when the viewer is not running.
9. **The tests themselves:** a test that judges on real time (this track's last two failures under the race
   detector were both of that kind); a mutation the author says was caught that its test would not catch;
   `TestQueueCostAtSize` and `TestRetryGroupIsOneStatement` under the race detector (should they skip there, as
   the two tests at size on the base's successor do: `raceOn` in `internal/server` on `wip/pages-g1` ee437a46).

## How to work
- Read the code yourself; read the old code it relies on (`internal/catalog/state.go`, `staging.go`,
  `internal/supply`, the engine's set-aside paths). Prove a finding where you can with a probe test written in
  your own scratch folder `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g2-scratch` and loaded with
  `go test -overlay` (the tree stays untouched), or by reasoning from quoted lines when a probe would cost too
  much. Mark each finding **CONFIRMED** (a probe or an unarguable reading) or **PLAUSIBLE** (say what would
  settle it). Timings are "looks like" numbers: say the PC's CPU load beside each.
- Load: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, one go command at a
  time, `GOGC=25 GOMAXPROCS=2 go test -p 1 -run '<names>' ./internal/<package>`: named tests only; no whole
  run of `internal/collector`, `internal/catalog` or `internal/server`, no race detector, no Docker. The PC is
  busy (three race runs in containers this hour): look at free memory and the CPU before each go command
  (`powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`)
  and wait when free memory is under 2.5 GB or the CPU is over 85%.
- Never touch `E:\T\tg-dl`, the folders `a3`, `b`, `app`, any real catalogue, media, session or account; start
  no installed program. Invented data only. Print counts, sizes and timings only.
- Any file you write that holds a Windows path is written with the Write tool, never from inside a shell or
  script string (a backslash before a letter has become a control byte several times today).

## What to hand back
Write `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-G2-queue.md`: findings in order of harm, each with its
mark, the file and lines, what goes wrong in one concrete sequence of events, and the smallest change you would
ask for; first the ones that must be fixed before this is merged, then the ones that should be, then minor
ones; then the measurements of point 1 as a small table; then what you checked and found sound (briefly, by
name), and what you did not look at. Your final message: the count by class and the must-fix findings in one
line each.
