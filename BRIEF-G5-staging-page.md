# Brief G5: the Staging page (pages track, session P2; 2026-11-15)

Roadmap row D4 ("Staging page: free space, what waits, what is stuck"); FEATURES section 1 ("Staging folder:
... keep N GB free, copies at once (1-8), what waits, what fails, what is stuck and needs the owner"; "Banner
when staging has been full for 10 minutes; banner for stuck files"). **Last in the track's order after G1:
Queue (G2), sign-in (G3), the mirror step from the page (G4, not briefed: after `wip/mirror-auto` is merged).
Not started.** For one Opus coder; the copy, branch and base are named when it is started. Rules of work as in
`BRIEF-G1-one-program.md` ("Rules (hard)").

## What the old app already knows (read by the main session; its numbers, one account, the NAS over Wi-Fi)
- **Staging full once blocked every download for 3 hours** (12.6: since then new files go straight to the
  library); the soft "space it may use" was "super counterintuitive" and became "keep N GB free" (12.14).
- **The copy is capped by the link, and each staged byte crosses it twice** (written, then read back to
  verify): about 14 MB/s each way; copies ran at 1.9 to 2.1 MB/s each whether 3 or 6 ran; the best hour 14.0
  MB/s with 8 small-file copies; a big file alone copies at about 4 MB/s. In a spell without the speed limit the
  backlog grew 15 to 30 GB an hour (45 to 303 GB in 6 hours on 11-07; 217 GB waiting on 11-14).
- **Per-file work, not only the link, limits small files:** of the copy time in one hour, write 52%,
  catalogue 19%, prepare 16%, read back 6%, publish 6%, flush 1% (ANSWERS 7, section 4).
- **The library being away is a state the app shows and waits out** (the NAS was unreachable 42 minutes on
  11-08: copies retried with a pause doubling to 10 minutes, nothing lost). Nothing in the background reads
  the library while copies wait.
- **Things outside the app use the same link** (LESSONS-ix12.30 6d): show the copy speed live, so a drop
  points at something else.
- The old page spread staging over three places (a settings picker, one line under Downloads, banners) and
  said "see the diagnostics report" for stuck files. The owner's rule: one place per control, every state says
  why, every number says what it counts, show the age of the data (TRIED-BEFORE 10, 19).
- The new app's own record: 734 files (17.8 GB) staged, copied to a local folder, read back at once and
  verified on 11-13; the copy to the NAS and the helper have not run for real.

## What exists
The store counts everything this page needs; nothing is to be added to it. `Collector.StoreHour(ctx, t)`
gives `store.Hour` (staged, written straight to the library, copied, verified by the helper or by a read-back,
time per step, copier time busy against allowed, staging-full errors) and `store.Gauges` (the copy queue:
waiting, copied and not verified, failing now, failed before, stuck, the oldest staged file; copiers allowed,
pinned or not, busy now; the library away and since when; the library's disk full; the staging disk away;
its free space, known or not; the helper on; "wanting files again held"). `Collector.ReleaseWantAgain` is the
owner's one action there. `catalog/staging.go` has the queue's rows (`DueQueue`, `QueueOf`: state, attempts,
next try, the step and class of the last failure, stuck and why). `server/diskfree_*.go` reads a disk's free
space. Read `internal/collector/staging.go`, `internal/store/counters.go` and `catalog/staging.go` first.

## What to build (`internal/server` and its page; the adapter gets one more read-only call; nothing in the store)
1. A page "Staging", reached from the menu, from a fourth small seam (the gauges and hours; nil in `tgarchive
   app`, where the page shows the copy queue from the catalogue alone and says the rest needs the program).
2. One verdict line in fixed words with its why: copying (N of M copiers busy, the last 5 minutes' MB/s);
   nothing to copy; the library is away since a time (copies wait and are tried again; downloads go on into
   staging); the library's disk is full; staging has no room (new files go straight to the library); the
   staging disk is away; waiting for a read-back in speed-limited hours. When several hold, the one that
   needs the owner first.
3. The numbers, each saying what it counts, with the age of the reading: staging's free space and "keeps N GB
   free" (the collector's start value; say that it is set when the program starts); files and bytes waiting to
   be copied and the oldest one's age; copied, not verified yet; failing now and failed before; stuck. This
   hour and the last 24 hours: staged, copied, written straight to the library, verified by the helper against
   by a read-back, and the copy time by step as shares (the old app's own table, so the two can be set side by
   side). No size is estimated.
4. **What needs you**, as a list with one action each (the old banners, in one place): files stuck (each with
   the step and the class of its failure in fixed words and what the owner can do; if the catalogue has a way
   to put a stuck file back in line, a button for it, one statement; if not, say so in the report and build
   none); "wanting files again is held at its hourly cap": the button "Let it go on" (`ReleaseWantAgain`);
   staging full for over 10 minutes; the library away for over 10 minutes. The Overview gets the count of
   these with a link, nothing more.
5. Copies at once: shown (allowed now, busy, chosen by the app or pinned). Changing it while the program runs
   is not built in the store: say beside it that it is pinned with `-copiers` at the start; add no setter.
6. The page asks again through G1's rule: the live poll carries the gauges that cost no statement; the
   catalogue's queue is read again only when the change key moved, at most every 5 s.

## Tests (named; invented data; the store's fake file system for "away" and "full")
`TestStagingVerdictWords` (each state and the order among several), `TestStagingNumbersSayWhatTheyCount`,
`TestStagingNeedsYouList`, `TestReleaseWantAgainFromPage`, `TestStagingPageWithoutProgram`,
`TestStagingPollStatementsBounded`, `TestStagingLogNoNames`. On the collector's rig, one named run: a library
that goes away shows as away with its time and comes back by itself. Mutations: "away" told as "nothing to
copy"; a stuck file left out of the list; the release button calling nothing.

## Since this was written (2026-11-15 21:51, session P3): what G1 became, and where you work
- **Copy and branch:** `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-g5`, branch `wip/pages-g5`, cut from
  G1's head ee437a46 (`wip/pages-g1`: listed READY, not merged yet). Two sibling pieces sit on the same head
  and are not merged either: the Queue page (`wip/pages-g2`) and the sign-in page (`wip/pages-g3`, which adds
  a THIRD seam `SignIns` to `internal/server` and the adapter). Yours is therefore the fourth seam by count
  but you do not see the third: add yours beside `Live`, `LiveEach` and the reads' seam in its own new files
  (`internal/server/staging.go`, `internal/collector/livepages/staging.go`), and in shared files (`server.go`'s
  `Config` and routes, the menu in `main.js`, `security_test.go`'s lists, `pages.go`'s `server.Config`
  literal) add your lines as their own lines at the end of each list, so the later merge is "both sides kept".
  Commit work in progress as you go and push with `git push private wip/pages-g5`. Progress and report:
  `archiver/docs/progress/pages-g5-PROGRESS.md` and `pages-g5-REPORT.md`, written from your first action.
- **The hard rules of `BRIEF-G1-one-program.md` apply, with its first rule replaced by this:** product code in
  `internal/server`, its page scripts and one new adapter file in `internal/collector/livepages`; in the
  collector's existing files only the one line that hands the adapter to the pages (`pages.go`), and a
  read-only accessor in a NEW collector file if `StoreHour` and the gauges need one. Nothing in the store, the
  engine, the supply, the catalogue's schema (no schema step), the viewer, `faketg` or the watchdog. No request
  to Telegram. Commits: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending
  with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; never push or merge any branch but your own.
- **Read G1's report first** (`archiver/docs/progress/pages-g1-REPORT.md`, every section) and use what G1 built:
  routes through `handle(...)`; `s.lasting(r)` for long work; `data-needs-program`; the kept answers and the
  change key (`overviewcache.go`); `GET /api/live` reads no table (two tests guard it: the gauges you add to
  the live answer must cost no statement); repaint by shape (`shape.js`).
- **Four rules the Queue page's review made today (`REVIEW-G2-queue.md`): build to them from the start.**
  (1) A reading says when it was read, never "now": a kept answer shows its own time, and a list whose rows
  can change without the change key moving (the copier's ledger steps `CopyCopied`, `CopyStuck`, `CopyLater`,
  a verification) is worked out again by its floor whatever the key says. (2) The numbers on one page add up
  at every moment: counts and the lists they count come from the same reading. (3) After the owner's own click
  the clicked region shows the result at once, also under the pointer; a button is disabled from its click
  until its answer is painted. (4) Any action is one bounded statement: if "put a stuck file back in line"
  exists in the catalogue it acts on ONE file a click; no action over a set without a cap and its time measured
  at 100,000 rows (the single writer is shared with the downloads).
- **The store has moved since:** Core's NAS copy test and the helper ran for real on 11-15 (150 of 150 files by
  the helper on the NAS, 30 MB/s in all against 23 by read-back): the page's "verified by the helper against
  by a read-back" now has a real number beside it; say in the report what the page shows for the helper (on,
  reachable or not) from the gauges as they are, and add nothing to the store for it.
- **Standalone program (board message 40):** nothing you add depends on an absolute path of this PC, the folder
  the program is started from, PATH or the `a3` scripts; the staging folder and the library are shown as the
  program was given them (paths are the owner's own, shown on the owner's own page: never in a log).
- **Tests never judge on real time** (three of this track's tests failed under the race detector today because
  they did): a library that "goes away" is the store's fake file system, a wait is the fake clock's, files in
  transfer are held with `rig.holdParts` (`internal/collector/parthold_test.go`). Tests at size skip under the
  detector by `raceOn` (`internal/server/race_on_test.go`). In any rig with a forum the fake's topics answer
  fails today and the reader retries it with pauses (the fake's fault, Core's, being fixed elsewhere): use a
  spec without a forum for your rig test or allow for it; do not edit `faketg`.
- **The scripts' guards:** after any change under `web/assets/js`, `TestScriptsNoDuplicateOrMissingNames` and a
  module parse of each script with node (`node --input-type=module --check < file`).
- **Open it yourself before handing back:** `TestPagesHold` (`TGARCHIVE_PAGES_HOLD=127.0.0.1:8797`) and the
  Staging page in the built-in browser if you have one, at desktop and at phone width; say exactly what you saw
  and what you did not (a library away, a stuck file: seen or only tested).
- **Load:** before each go command
  `powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`;
  wait when free memory is under 2.5 GB or the CPU is over 85%; one go command at a time,
  `GOGC=25 GOMAXPROCS=2 go test -p 1 -run '<names>' ./internal/<package>`, named tests only; no whole run of
  `internal/collector`, `internal/catalog` or `internal/server`, no race detector, no Docker.
- **Any file that holds a Windows path is written with the file-writing tool**, never from inside a shell or
  script string.
