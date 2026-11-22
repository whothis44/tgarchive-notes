# Tenth archiver session: progress (started 2026-11-14 by the scheduled task, the owner not present)

Limits of this unattended start: nothing against Telegram, no start of the collector, no folder deleted or
emptied, until the owner says so in the conversation.

## Log
- Start: read `CLAUDE.md`, `START-SESSION-10.md`, `LESSONS-ix12.30-live.md` (in full). `repo-archiver` is clean on
  `claude/charming-feynman-vm2xia` at 8761d5c.
- Read: the handoff's first block, `SESSION-9-PROGRESS.md` from "A3 RAN FOR REAL" to its end, the memory note
  on answers 6 to 8, `TRIED-BEFORE.md` in full (sections 1 to 27), the part's wait path in
  `engine/lane.go` (`waitLen`, `keepPartWait`, `fetch`'s wait case, `late`, `sleepHeld`), `engine/guard.go`,
  `telegram/parts.go`, `telegram/invokers.go`, `ConnWatch.dead` in `telegram/options.go`, and the library's
  `pool/pool.go` and `pool_conn.go` (v0.166.0).
- **What the reading showed:** the part path has no margin anywhere (gates and refreshes have 1 s). The
  library's pool retires a connection only when it died before the request was acknowledged
  (`ErrConnDead`, `rpc.ErrEngineClosed`) and re-sends on a new one; a wait answer does not close a
  connection on the library's side. So the 759 deaths were closed from outside the pool's own logic
  (Telegram's side or the transport underneath): the error class of each death is what the next run must
  record (a transport protocol error with code 429 would be Telegram closing for too many requests).
- **The PC at the start: 0.8 to 1.3 GB of memory free** (31 GB in all; the browser about 8.8 GB, the old
  app 4.4 GB and 3.6 cores, this app 3.3 GB), about 5 of 12 cores busy. Under the 2 GB floor. So both coders
  run under a memory gate: no go command under 3.0 GB free, one go command at a time across agents (a lock
  directory `.go-run.lock` in the project folder), `GOMEMLIMIT=1GiB`, `-timeout`, named tests only.
- **Started (background agents, Opus, high effort):**
  1. the wait margin with its log lines: brief `BRIEF-A4-wait-margin.md`, copy `wt-margin` (new, detached
     at 8761d5c); its notes `archiver/docs/progress/waitmargin-PROGRESS.md` there.
  2. the exact check's remaining review fixes in `wt-exact` (on 8bcc997), as the start file's section 4.
- **Written, not started:** `BRIEF-A5-logging.md` (the logging piece; starts after the margin lands; needs
  the next free schema number).
- **Not done, waiting for the owner:** anything against Telegram (the repeat of the run, the one hash
  request); emptying the test folders; any start of the collector.
- **The owner came (about an hour in): "Yes, prepare it"** to "empty the test folders and prepare the repeat
  of the download run once the margin is reviewed", and freed memory ("Use it as needed": 7.3 GB free then).
  Prepared, nothing deleted yet: `a3/a3-reset.ps1` (dry run by default, `-Go` does it; dry run showed
  library 734 files / 17.8 GB, staging 2 small files, the copy's write-ahead file and the finish log empty,
  no collector running) and `a3/REPEAT-RUN.md` (the steps, what is compared, how to read the result). The
  reset runs after the margin is merged, right before the run.
- **Both coders came back (about 15:25 to 15:32 local).**
  - **The exact check: findings F1 to F10 all fixed**, targeted tests and mutations passed. Saved as a
    local commit 6eb8311 on `wip/exact-check-2026-11-13` in `wt-exact` (not for merge yet). I read
    `engine/check.go` myself: two points (a hash wait is kept with no margin; one unchecked type
    assertion at line 251). **Not built: the owner's addendum** (a video compared in full, the budget, the
    three-waits rule, the spot check, the library's turn, the setting with three values, the
    per-comparison record). Brief written: `BRIEF-B1b-exact-full-comparison.md`; its coder starts when
    the margin's test runs have freed the CPU.
  - **The wait margin: done**, targeted tests and two mutations passed. I read its changes to `lane.go`
    and `engine.go` myself: sound by reading. Saved as local commit 260d6ad on
    `wip/wait-margin-2026-11-14` in `wt-margin`. Its coder found: a wait on one part does not hold the
    file's other parts in this run (a comment says it does); a recorded wait ends with no margin; a dying
    connection's error is `io.EOF`, a socket error, a transport protocol error (429 is the flood) or a
    ping deadline.
- **The Go toolchain was damaged at 14:02 by a clean-up of the temporary folder** (both coders hit it and
  worked around it). **Repaired without a download:** `ix-tools/goroot-1.27.3` (sources from the local
  Docker image `golang:1.27.3`, the Windows programs from the old copy), used through
  `ix-tools/env-archiver.sh`. The module and build caches are still in the temporary folder.
- **Running in the background (started about 15:35):** the margin's race runs in Docker
  (`runs-10/margin-race.sh`: engine and sim, then telegram, then collector; logs `runs-10/race-*.log`),
  its whole Windows tests (`runs-10/margin-win.sh`; logs `runs-10/win-*.log`), and its independent review
  (an Opus agent; `wt-review-margin-scratch/REVIEW.md`). `ix-tools/race-archiver.sh` is the race command.
- Note: the Go toolchain and its caches live in another session's temporary folder (`ix-tools/env.sh`
  points there); a reboot or a clean-up of temporary files would remove them.
- If this session dies: both agents die with it. Their PROGRESS files say where each stood; check for
  leftover `*.test.exe` and for the lock directory `.go-run.lock` (remove it if no go command runs).
- **About 15:48: the margin's first results and its review.**
  - Whole Windows tests passed: engine 26 s, sim 103 s, supply 234 s, collector 408 s; `gofmt` and `go vet`
    clean. Race detector: engine passed (336 s); the rest stopped by me before they ran, because the
    review's fixes change the code under test.
  - **telegram's Windows run failed on `TestGotdQ4ConcurrentLoadChangeSave`** ("loads failed while two
    writers saved"). Not the margin: repeated 60 times on each copy, it failed 8 times on the unchanged
    branch and 11 on the margin copy, in bursts under load. An existing flaky test or an existing defect
    in reading the session file during a save on Windows: **to look into before a long run.**
  - **The independent review** (`wt-review-margin-scratch/REVIEW.md`): no path found by which a part is
    asked before its wait plus the margin (a probe over 14 minutes, 3 seeds, 3 margins); nothing blocks a
    real run. Taken on: two test gaps (the hand-over-and-back record; the flag reaching the engine), the
    record written before the log line, an early-retry kick inside the margin, one wrong comment. Left:
    its small points.
  - **Started:** an Opus coder on those five in `wt-margin`; an Opus coder on
    `BRIEF-B1b-exact-full-comparison.md` in `wt-exact`.
  - **Then:** I read the fix, whole Windows tests of engine and collector again, all four race runs
    (`runs-10/margin-race.sh`), merge, push to `private`, build, reset, the owner starts the run.
- 15:50: correction: three clock times above were written as guesses two hours late and are now the real
  ones (the session started at 15:02). Lesson of the hour: `runs-10/margin-race.sh` went on to its next
  package each time its container was stopped; stopping it needs its containers killed one after another
  (now done: none left). The next version runs every package from one loop that a stop file ends.
- 15:56: the margin's review fixes came back (five, each new test with its mutation); I read the diff
  (the collector's flag-to-engine path is the same fields as before, now testable); local commit c869db2 in
  `wt-margin`. Whole Windows tests and the four race runs restarted on it (`runs-10/STOP` ends the race
  script before its next package).
- **The flaky session test, read:** `SessionStore.LoadSession` reads the file with one `os.ReadFile` and no
  retry, while `StoreSession` of ANOTHER store on the same file renames a new file over it (the rename
  retries on Windows' sharing errors 5, 32 and 33; the read does not). In one program each account has one
  store with one lock, so its own reads and saves never overlap. It can only bite when two programs use
  one session file at once (the collector and a `signin` or status command, say) or a scanner holds the
  file. **A small fix to brief after the margin merges: the read retries on the same three errors, as the
  rename does; the test then has to pass 200 of 200 under load.**
- 16:05: the owner: the usage window resets in 50 minutes, so use what is spare. The wall clock is set by
  the race runs and by memory (2.2 GB free), not by usage; so two more Opus coders were started on copies
  made from the margin's commit c869db2, each under the 3.0 GB memory gate: **the logging piece** in
  `wt-logging` (branch `wip/logging-2026-11-14`, brief `BRIEF-A5-logging.md`, schema number 12) and **the
  session read's retry** in `wt-sessfix` (branch `wip/session-read-2026-11-14`). Three coders run now (with
  the exact check's full comparison in `wt-exact`), beside the margin's Windows and race runs.
- 16:14: the owner: "do you remember the claude.md rules? We don't need excessive race checks on
  everything." Right. **The margin's race runs are cut to the two packages where it changes anything that
  runs concurrently: engine (passed, 340 s) and telegram (running).** Dropped: the simulator (one line: it
  sets "no margin") and the collector (a flag and its hand-through; no new goroutine; its whole Windows
  tests cover the wiring). For later pieces: race only the packages whose concurrent code changed.
- **16:25: THE MARGIN IS MERGED AND PUSHED** (`private`, branch `claude/charming-feynman-vm2xia`: b24bae7
  the code, ead8b6d the handoff's first block, the roadmap row and the review). Full runs on the fixed
  code: whole Windows tests engine 37 s, sim 100 s, supply 253 s, collector 587 s passed, `gofmt` and vet
  clean; race detector engine 340 s and telegram 87 s passed; telegram on Windows fails only on the
  session read test (being fixed in `wt-sessfix`).
- **`CLAUDE.md` tightened at the owner's word** (2bca58e in the notes): race only where concurrent code
  changed; order fixed (review and fixes before the full runs, once); the plan told first;
  `ix-tools/full-runs.sh` with named package lists. A memory note too (`race-runs-scope`).
- **The collector is built from ead8b6d** as `tgarchive-collector.exe` in the program's folder (the build of
  92bb821 kept beside it as `...-92bb821.exe.bak`); `run -h` shows `-part-wait-margin` (default 1s).
- **The reset is done** (`a3/a3-reset.ps1 -Go`): test library and staging empty, the first run's catalogue
  kept in a dated folder beside the catalogue, the copy from before the run in place: schema 9, 741
  wanted. **READY FOR THE OWNER TO START THE REPEAT RUN** (`a3/REPEAT-RUN.md`). Nothing sent to Telegram.
- Still running: three Opus coders (`wt-exact` full comparison, `wt-logging`, `wt-sessfix`).
- **16:26 local (21:25:42 UTC): the owner started the repeat run** (program built from ead8b6d, margin 1 s;
  collector process and sampler started from their own PowerShell window with
  `powershell -ExecutionPolicy Bypass -File`). **Reading at 14 minutes ("looks like", one run):**
  - **Plain waits unchanged:** per minute 32, 27, 25, 21, 19, 19, 15, 12, 14, 19, 22, 18, 19: about one part
    request in 13 (the first run: one in 14), in the photo minutes and the video minutes alike. 272 of 273
    were the first wait on their part; stated 1 s (158), 2 s (108), 3 s (7); answered about 0.13 s after
    the request. **I told the owner at 16:32 that the waits had stopped with the small files: that was
    wrong (one unfinished minute's count); corrected at 16:42 here and in the questions file.**
  - **Connection losses about a quarter of the first run's:** 35 in 10 minutes (3 to 4 a minute; the first
    run about 15 a minute), all `pool, server 2, eof, sent`, a median of 4 s after the last wait; none in
    the first four minutes.
  - 614 files, 3.4 GB saved and verified at 14 minutes: about 4 MiB a second at 2 parts.
  - **So: the margin looks like it cut the losses and left the waits.**
- **`QUESTIONS-for-fork-9.md` and `ANSWERS-for-archiver-9.md` (read in full, 16:38):** on the old account
  plain waits do not go with files started (a photo hour of 5,007 files on one server: 0 waits; worst
  server 0.32 waits per 1,000 part requests against about 75 per 1,000 here); the old app never ran on
  another account, so **the difference may be the account** (the owner: the test account is not much
  newer but far less active, with far fewer groups); the old app re-reads each file's message on the main
  connection before the file; a pool for a non-home server runs every connection on one key; the old
  app's connections carried gigabytes each; **the library differs (v0.163.0 against v0.166.0): ping every
  minute against every 30 to 45 s with a disconnect delay, future salts asked hourly against never, a
  connection slot keeping its server session across reconnects, the downloader's `precise` flag**.
- **The session read fix found a second defect:** the store's sweep of temporary files can delete the
  live session file when two stores use one file (6 times in 60 test runs; reads as "no session"). Its
  coder was sent back to fix it (only temporary files older than 2 minutes; a name per store) and to
  check whether the collector can have two stores on one file.
- **The exact check's full comparison came back** (twelve items, each with test and mutation; schema stays
  11): local commit c6f4e4e in `wt-exact`. Next, in the fixed order: an Opus coder merges the branch into
  it (started 16:40), I read `engine/check.go`'s changes, the independent review, its fixes, the full
  runs once. Seven decisions of its coder to judge (budget in both modes; clock hour; "not compared yet"
  kept aside until the hour ends; the library's turn sends a file back 10 minutes at a time; a full
  comparison of a 4 GiB video may hold a file slot over an hour).
- 16:41: the owner: do both tests; start with the library's debug log; they will see to the old app on
  the test account after. Brief `BRIEF-A6-library-debug-log.md` (allow-lists of exact messages and numeric
  attribute keys, everything else dropped and counted; flag `-lib-debug`, off by default); an Opus coder
  started in `wt-libdebug` (branch `wip/lib-debug-2026-11-14`, at ead8b6d).
- The session fix is back and saved (fc29d3e in `wt-sessfix`): the sweep removes only other stores'
  temporary files older than 2 minutes; the test passes 200 of 200 twice. By reading, one program cannot
  have two clients on one session file and two programs cannot run on one catalogue; **gap left: two
  catalogues in one folder share `sessions/account-N.session` with no lock.** To do: I read its diff, the
  telegram package's whole Windows tests, merge.
- 16:44: **the session fix is merged and pushed** (9083e1d on `private`): I read its diff; the telegram
  package's whole Windows tests passed (36 s; the first clean pass today), `gofmt` and vet clean; no race
  run (no concurrent code changed). The handoff's block still calls it "being built": to correct at the
  next documents commit.
- 16:52: the exact check's merge with the branch came back (4ce4a0f in `wt-exact`, a merge commit; safety
  branch `backup/exact-before-rebase-2026-11-14`; named tests passed, no test changed). I read
  `engine/check.go`'s changes since 6eb8311 (the deadline by size, the two new outcomes held, the spot
  check downloaded, both margins, the checked assertion): sound by reading. **Its independent review is
  started** (an Opus agent, scratch folder `wt-review-exact2-scratch`, eight question groups led by "any
  way to a wrong same"). Open from the merge coder: no test with a hash wait and a part wait on one file
  (given to the reviewer); a wait on a hash call has no log line with its seconds (for the fixes).
- 16:56: the logging piece came back (nine items built, named tests passed; schema step 12 on top of 10,
  with notes for the merge after the exact check's 11): local commit f09f9b3 in `wt-logging`. I read its
  changes to `engine/lane.go` and `telegram/inflight.go` (to check: whether the aside book's log call runs
  with the lane's lock held). **Its independent review is started** (an Opus agent, scratch folder
  `wt-review-logging-scratch`). Two reviews run now (the exact check's, the logging's) and one coder (the
  library's debug log).
- 17:09: **the exact check's second review came back** (`wt-review-exact2-scratch/REVIEW.md`): no way found
  to a wrong "same" other than every walked window matching; **six findings block the merge**, the first
  also the first real hash request: (1) a running comparison keeps asking inside a wait stated on another
  hash call (23 calls inside a 3 s wait); (2) files waiting for or under a check hold download slots, so
  unique files stop (2 of 10 saved in 10 minutes); (3) the library's turn can postpone a file for ever;
  (4) "off" does not stop a running comparison's link; (5) "not compared yet" files stay held after
  "off"; (7) the three-waits rule across a restart is untested. Also: a file longer at Telegram than
  recorded, conflicting windows, smaller points.
- **My judgement, written as `BRIEF-B1c-exact-review2-fixes.md`** (principle: the check must never be
  worse than no check). Decided there, **for the owner to confirm**: a file not compared (budget, three
  waits) is set aside to the hour's end and is then wanted again, never parked as a probable copy (45% of
  same-size files were different on the old account); the library's turn is given at most 3 times, then
  the comparison runs all the same; staged candidates are compared whatever the copier does; "off"
  returns every not-compared file to wanted. Added: a command `exact-mode` to change the setting without
  SQL; a log line per hash wait; the hash wait's margin is the engine's. An Opus coder started on it in
  `wt-exact` (it commits after each fix).
- To tell the owner from the review: one full comparison of a 4 GiB video takes 4,096 to 32,770 hash
  requests; the provisional budget is 1,000 an hour.
- 17:11: the library's debug log came back (local commit 5c690fd in `wt-libdebug`): flag `-lib-debug`, 133
  messages written singly, 29 counted a minute, 39 attribute keys each of one kind, errors as a class;
  three mutations each fail the guard. I read the filter (`liblog.go` lines 217 to 448): a line is
  written only for a listed message, a value only by its key's kind, a name only from a list. **Its short
  independent review (privacy key by key, blocking) is started**; scratch `wt-review-libdebug-scratch`.
  **A candidate cause its coder found in the library:** v0.166.0 continues an earlier connection's server
  session on a new connection ("Continuing session"); v0.163.0, the old app's, does not.
- 17:13: **the logging piece's review came back** (`wt-review-logging-scratch/REVIEW.md`): it changes nothing
  sent to Telegram and logs nothing under a lane's lock; a minute's write holds the catalogue's writer
  1.5 to 4 ms. Confirmed defects: the store's totals added again every minute after 26 hours; a stop just
  after an hour's end counts the hour twice; one account's failed hour-end write overwrites another's;
  the status file's replace fails on Windows while a reader holds it; the median reads up to a third
  high; three test gaps. **Hazard: this branch alone would label a version-10 catalogue 12 without the
  exact check's step 11: never run it on a real catalogue before the merge with the exact check.** An
  Opus coder started on eleven fixes in `wt-logging` (it commits after each; a start-up guard against
  the schema mistake among them).
- 17:18: **the owner disagrees broadly with the fix brief for the exact check**: "The sample checks are
  critical to efficient downloading", most of all for a frozen account where time is limited; asked how
  the old app handles it. Fix 3 of `BRIEF-B1c` is put on hold (its coder told; fixes 1, 2, 4 to 9e go on).
  **Read by me in full (12.30): `ix_subst.go` and `download/library.go` 290 to 345.** The old app's rule:
  - a video of 2 MiB or more with a saved file of exactly its size: **three hash requests** (start, middle,
    end), every hash in those three answers compared with the saved file's bytes; all equal: same, linked,
    not downloaded. No hashes at Telegram: three 1 MiB parts downloaded and compared (eight over 256 MiB).
  - everything else from 256 KiB: every part's hash, at most 64 requests, else downloaded.
  - **anything undecided (an error, a wait, no hashes): the file simply goes on** to the sampled-frame
    check and its download. No budget, no turn-taking, no hold, nothing parked.
  - it runs in the file's own turn after the reference refresh; answers are kept across up to 5 candidates.
  - result on record: 5,007 files (240 GB) not downloaded in ten days, 3,932 of them videos judged this
    way; none known wrong, none ever re-checked.
  **What I take from it:** the weight of the new design (thousands of requests per large video, the whole
  saved file read from the library, a file slot held up to an hour, the budget, the library's turn, files
  set aside) all comes from "compare a video in full". With the old app's three places deciding, a check
  is 3 requests and a few MiB read, and most of the review's findings lose their cause. The spot check
  (one in a hundred downloaded anyway and compared by SHA-256) is the guard the old app never had: it
  turns "never shown wrong" into a measured rate. Proposed to the owner; awaiting the answer.
- 17:23: **the owner decided: three places.** "I think that's sensible. The three places. Seems like a
  reasonable compromise with, I expect, minimal downside. This is all about tradeoffs." Written as
  `BRIEF-B1d-exact-three-places.md` and sent to the exact check's coder: the setting's default is
  `three-places` (a video of 2 MiB or more judged at three places, eight over 256 MiB, and that decides
  "same"); `full` stays and falls back to three places whenever it may not run; nothing is set aside,
  held or sent back by this check; an undecided check ends in the download; the first 20 three-place
  verdicts are all spot-checked, then one in a hundred. **To write into `FEATURES.md` section 12 as the
  fourteenth round when the exact check merges** (it reverses the thirteenth round's default).
- 17:23: the library log's review came back (`wt-review-libdebug-scratch/REVIEW.md`): nothing private can
  reach a line (all 17 number keys checked at every call site of the library; all safe); nothing blocks
  using the flag in one run. One crash path: a typed nil error panics the error classifier (the death
  line has it too). An Opus coder started on two fixes (the classifier never panics; the key list pinned
  in a test). Then: whole Windows tests of telegram and collector, the race detector on telegram (a
  goroutine per client is new) and on the collector's one new dialer test by name, merge, build, the run.
- 17:31: the library log's review fixes are back (8aaf5f6 in `wt-libdebug`: `errClass`, `errType` and
  `safeErr` never panic and give the word "unclassified"; the 39 keys pinned in a test). The branch's
  latest commits merged into the copy (745f09e, clean). **Full runs started with
  `ix-tools/full-runs.sh wt-libdebug runs-10b "telegram collector" "telegram"`** (whole Windows tests of
  both; the race detector on telegram only: the writer goroutine is there). Left open, small:
  `ConnWatch.sentDown` still calls `errors.Is` unguarded on the library's goroutine.
- 17:32: **THE REPEAT RUN IS DONE AND STOPPED CLEANLY** (work 21:25:42 to 22:29:58 UTC, 64 minutes, one start;
  `a3-stop.ps1` at 22:31:26 UTC, "stopped in 12 ms"; the sampler told to stop). 734 of 734 files saved and
  verified, 17,842 MiB. From the hourly tables (server 2, which carried all but 11 files), against the
  first run of 11-13 (no margin) in brackets; one run against one, "looks like":
  - **Plain waits on parts: 1,359 (1,261); one part request in 14.5 (one in 14); 13.8 MB per wait (14).
    Unchanged.** Stated 1 to 3 s, nearly all the first wait on their part.
  - **Connections of the pool lost: 261 (759), about a third.** Requests in flight at a loss 477 (1,426),
    of them under a stated wait 21 (82). All "eof, sent". Dials 260, new server sessions 260.
  - **Slot time asleep: 43% (about 31%)**: answered 4,164 s, sleeping 3,352 s, failed 203 s. The margin
    adds a second to each of 1,359 waits.
  - **Speed: about 4.85 MB a second at 2 parts (about 5.6): about 13% slower.** The window never left 2.
  - Timeouts 2 (2); refreshes 733 requests, all answered; no speed-limit wait.
  **Reading: the margin is not the cause of the waits; it looks like it cut the losses to a third; and at
  this rate of waits it costs about an eighth of the speed.** The owner's question of 15:5x ("could
  accumulate?") was right for this account. Next: the library's debug log run at the same margin (so its
  lines explain this run), then a run at a smaller margin (300 ms) to find where the losses come back.
- 17:38: **the library's debug log is merged and pushed** (58d8087 the code, 4f5be66 its review, on
  `private`): whole Windows tests telegram 39 s and collector 353 s passed, the race detector on telegram
  65 s passed, `gofmt` clean. The collector is rebuilt from 4f5be66 (the build of ead8b6d kept as
  `...-ead8b6d.exe.bak`); the test folders are reset again (the second run's catalogue kept in a dated
  folder; 741 wanted). New script `a3/a3-start-debug.ps1` (the flag on; the margin as a parameter,
  default 250ms). **Ready for the owner to start the third run**; which margin is asked of the owner.
- The owner (17:3x): the first 20 three-place verdicts all spot-checked "is probably excessive, unless
  that's a testing only setting": now a testing flag, default 0 (the coder told). "The 13% speed needs to
  be drastically improved": my reading of both runs' tables: the loss is slots asleep under waits (31%
  of slot time without the margin, 43% with it) and a window that never leaves 2; a working slot brings
  about 4.4 MiB a second; lost connections cost about 200 s of slot time in a run. Proposed next build:
  a part sleeping out a short wait frees its window slot, and the upward-only window rule
  (WINDOW-EVIDENCE.md; to read myself first). Awaiting the owner's word on the order.
- 17:41: the owner: "The one in a hundred should be a testing thing as well. Off by default." (the coder told:
  both spot-check settings default 0, flags for test runs). And: **"What about the rest of the app? We're
  a week into development and we have basically nothing."** My count from the roadmap: 12 features real,
  28 built but run only against fakes, 9 in part, 24 not built; real so far is sign-in, the VPN check,
  one chat read, one chat downloaded to a local disk. Not real: the copy to the NAS, the viewer, any copy
  check, the bring-in, the pages. Answered with a change of course proposed: breadth before depth (see the
  conversation); awaiting the owner's choice.
- 17:55: **the owner: "I want the downloader to work, and be good, so implement everything we discussed, but
  don't test needlessly. Get it done then test. Go. Log your progress routinely... you have the tg1 GitHub
  to examine, so don't reinvent the wheel unless it actually improves things."** Done at once:
  - the two running coders told: no mutation runs, one test per behaviour, a package's tests once;
  - read myself: `WINDOW-EVIDENCE.md` in full; the old app's `pacer.go` (acquire, release, the 12.30
    short-wait rule) and `attachment.go` `invokePart`: **the old app also keeps a waiting part's slot**
    (it only gives the slot back while a lost connection is replaced), so freeing it is new, justified by
    this account's wait rate;
  - `BRIEF-C1-window.md` written and an Opus coder started in `wt-window` (branch
    `wip/window-2026-11-14`, at 4f5be66): part 1 a sleeping part frees its window slot (bounded; not
    under the speed limit; a switch to compare), part 2 the upward-only rule as the default policy, acting
    from the start;
  - `START-SESSION-11.md` written (the plan from here: integrate the three branches, one review, one
    full run, merge, the owner's run; then breadth).
- 17:55: **the logging piece's review fixes are back**: all 11 items, committed in `wt-logging` (12 commits,
  f16a648 to 46176f5), named tests in seven packages passed, `gofmt` and vet clean. Its report has the
  complete notes for merging after the exact check (nine files conflict by a dry merge). Its doubt to
  carry into the integration: only the collector has the schema guard; the other programs built from that
  branch alone would also take a version-10 catalogue to 12 (moot once merged after the exact check).
  **Logging is ready for the integration.** Still working: the exact check's coder, the window's coder.
- 18:00: **the owner: "No. We're not going to do 100 tests for every single change. You have a massive amount
  of evidence from the previous app, and you should have research as to how telegram works. Figure it
  out."** So: no more diagnostic runs to find the waits' cause; a conclusion from what is on record.
  **MY CONCLUSION ("looks like", from two runs, the old app's answers 6, 8, 9 and its reports): the plain
  waits and the dropped connections are Telegram's own throttle on that account at that server, not a
  defect of the app.** Evidence:
  1. About one part request in 14 is refused whatever the request rate (5.6 or 4.85 MB/s), the kind of
     file (photos or videos), and the margin (none or 1 s). A fault of ours would move with one of them.
  2. The request is the old app's request (1 MiB, no flags, one per connection, the same library
     defaults), by its code.
  3. The old account shows the same thing in bursts: one-second plain waits that come as often at 1 part
     as at 2 (TRIED-BEFORE 23), 116 in the hour after a speed limit lifted, 25 in a big-file hour on
     server 2, ending by themselves. The test account (less active, the owner) gets it all the time.
  4. **The drops belong to the same throttle.** In the second run's 261 losses, the time since the last
     wait peaks at 3 to 4.5 s (10 to 30 per half second there, against 3 to 11 in the first 2 s): a
     drop comes where the next wait would be due, about a second after the waited part was asked again.
     Telegram answers "wait" or closes the connection; asking the instant a wait ended made the drops
     three times as common (759 against 261). So the margin stays.
  **What follows:** the waits cannot be removed from our side; their cost can. They cost 3,352 of 7,719
  slot-seconds only because the waiting part holds its slot; the window piece's part 1 frees it (already
  being built). Expected, not measured: about 8 MB/s at 2 parts where the runs got 4.85 to 5.6. No more
  runs to hunt the cause; the diagnostic run and the old app on the test account are optional. **One real
  run at the end of the downloader work, as its acceptance.**
- 18:14: **the exact check is back, complete** (`wt-exact`, head 438855f, clean tree): three places decide by
  default (three places, seven over 256 MiB: the old app's offsets give seven, not eight); `full` and
  `off` through `tgarchive-collector exact-mode`; spot checks are testing flags, both 0 by default;
  nothing set aside, held or sent back; a wait on any hash call holds every hash call of that server;
  checks hold no download slot. Its coder's own judgements to check in the review: on three waits it
  stops checks for the hour in both modes (no fallback); the extra call at the recorded size on every
  whole-file walk; `exact-mode` needs the collector stopped to change the setting.
- 18:14: **integration started**: an Opus coder in `wt-downloader` (branch `wip/downloader-2026-11-14`, at
  4f5be66) merges the exact check (schema 11), then the logging (12, following its merge notes; the
  start-up guard removed), then the window piece when its coder has finished (its part 1 is committed,
  ff8b9c7). Notes go to `archiver/docs/progress/downloader-INTEGRATION.md` there.
- 18:15: the owner: "The exact switch is fine, for this test, although I don't know if the test group has
  duplicates." So the acceptance run has the exact check on (the OK is for that run). Known from the first
  run: 11 photos there are byte-identical to another under a different Telegram id, about 240 KiB each on
  average (2.6 MiB in all), which may be under the check's 256 KiB floor; so the run may send few or no
  hash requests. To exercise it for real the chat needs a few re-uploaded videos (the owner's choice).
- 18:17: **the window piece is back, complete** (`wt-window`, 87cb62c): part 1 a part answered with a wait
  frees its window slot at once and goes out first when its wait plus margin is over (bounded by the
  window; not while limited; switch `-sleep-keeps-slot`); part 2 `engine.Upward` is the default policy
  (`-window-policy careful|upward`), acting from the start, a log line per try, the proven level per
  server remembered in the catalogue's settings (no schema step). Whole engine package passed (265
  tests, 25 s). Its coder's doubts for the review: the pick of a woken part repeats the normal pick's
  file rules; a kept step's check drops the window to n for about 50 s; a slow-answer run during a check
  can drop two levels. The integration coder is told to merge it last and to give its counters columns in
  the unshipped schema step 12. **All three pieces are built; the integration is the only work running.**
- 18:31: the owner made a private group on the test account for the exact check: about 50 messages, mostly
  videos, many duplicates. To bring it in: `a3/a3-prep.ps1` (a foreground run with `-no-downloads`: it
  stores the present chat list; Ctrl-C after a minute), `a3/a3-chats.ps1` (the owner reads the group's
  catalogue number in their own window; it shows names, so never run by a session), then the acceptance
  run in a console with `-approve-read N` (the cost is shown, "yes" typed). The console start script for
  that run is to be written with the new build.
- 18:42: the owner ran the prep run (connected 23:39:57 UTC, downloads off) and the chat list: **the new
  group of duplicates is catalogue chat 13.** No collector is running now. Written, not yet tried:
  `a3/a3-start-console.ps1 -ApproveRead 13` (the collector in the owner's window with its output in the
  log file and shown as it grows, so the approval's "yes" can be typed).
- 18:43: the owner asked whether to start another session for other roadmap tasks. Yes: `START-SESSION-B.md`
  written: a parallel session for breadth (the old archive brought in for real and opened by the owner in
  the new viewer; then the copy to the NAS; then the pages), in copies of its own, never touching the
  download path, the test catalogue or the main branch (`SCHEMA-NUMBERS.md`, `MERGE-QUEUE.md` as the
  two shared notes).
- 18:44: **the integration is back: all three pieces on one branch** (`wip/downloader-2026-11-14` in
  `wt-downloader`, head c39f6b2; merges b379ec9 exact, 06f1534 logging, c39f6b2 window; clean tree;
  the named tests of seven packages passed after each merge; notes in
  `archiver/docs/progress/downloader-INTEGRATION.md`). Schema 12 follows 11; the start-up guard is gone;
  the window's nine counters have columns in step 12; a file waiting for an exact check no longer counts
  as "a part waits for a slot" for the window rule. **Two independent reviews started side by side**
  (Opus; read first, probe only to confirm): A the window piece and `lane.go` as it stands (scratch
  `wt-review-dl-A-scratch`); B the exact check with three places and the collector's seams (scratch
  `wt-review-dl-B-scratch`). Then: their fixes, the full runs once, merge, push, build, the owner's run.
- 18:55: **review B is back** (the exact check and the seams; `wt-review-dl-B-scratch/REVIEW.md`). The
  default rule is sound ("same" only with every place covered by its own answer and every window equal;
  the link, `off`, the hash hold, the flags, the schema order and privacy all sound). To fix, my
  judgement (all in the spirit of the old app: undecided means download):
  - F1 (confirmed; `full` mode only): the fall-back to three places is applied to any file; it must be
    for a video of 2 MiB or more only, else every walked window or unknown.
  - F2 (confirmed): a wait on a hash call puts the wait on the file's parts, so the file sits in a file
    slot for the whole wait. Fix: a hash wait is not put on the file's parts; the file downloads at once,
    unchecked.
  - F3: while a server's checks are held, files that would be checked wait 30 s and are set aside; and
    files waiting for checks can fill the claim bound so nothing else is claimed (0 of 5 in the probe).
    Fix: checks held: download unchecked at once; both check slots busy: one send-back, then unchecked;
    a claim goes ahead whenever a file slot is idle.
  - F4 (small): the hour's base read again later can include this run's own counts.
  - Left: F5 (a kill loses a hash wait under 30 s), F6 (four rare lines not produced by the guard test).
  Waiting for review A (the engine) before one coder fixes both lists (both touch `lane.go`).
- 18:56: **review A is back** (the engine; `wt-review-dl-A-scratch/REVIEW.md`): no path shortens a wait, the
  window is never exceeded, no part is lost, sent twice or starved, counters add up, privacy holds.
  Its finding 1 (confirmed): the growth rule's wait-rate test can end a try on chance with this account's
  background waits and then block the step for an hour (2 of 10 simulated runs not at the ceiling after
  40 minutes). **One Opus coder started on both reviews' fixes** in `wt-downloader`: B1 the fall-back to
  three places only for videos of 2 MiB or more; B2 a hash wait is not put on the file's parts (the file
  downloads at once); B3 checks held or check slots busy end in an unchecked download, and a claim goes
  ahead whenever a file slot is idle; B4 a counting fix; A1 the wait-rate test on pooled data with a
  chance margin, a 30-minute pause, a block only on a repeat; A2 a try aborted on a speed-limit wait, a
  network drop or a storm; A3 the hourly maximum of parts sleeping without a slot; A4 the no-log-under-
  lock test covers the window lines; A5 a proven level re-checked about hourly. Then: the full runs
  once, merge, push, build, the owner's run with chat 13.
- 19:19: **both reviews' fixes are back** (`wt-downloader`, head d462838; commits 08147e6 the exact check's,
  e1c6af6 the engine's, d462838 one test expectation): all nine fixes built, each with one test; named
  tests of seven packages passed. Accepted by me: the wait-rate reference pools the lane's levels up to
  the try's baseline (the floor alone was too little data); a file with candidates beyond the check pen
  downloads unchecked; the "sent back once" memory is per run. **The full runs are started, once**
  (`runs-10c/win.sh`: whole Windows tests of ten packages and the commands, `gofmt`, vet;
  `runs-10c/race.sh`: race detector on engine, exact, exact/wire, telegram whole and the collector's
  concurrent tests by name). Session usage is at 81% (resets 21:50 local): if this session stops, the
  next reads `runs-10c/*.log`, and when all say ok: squash-merge `wip/downloader-2026-11-14` into the
  branch in `repo-archiver` (one commit; the documents in a second: FEATURES fourteenth round, TRIED-
  BEFORE 28, the handoff's first block, the roadmap rows), push to `private`, build the collector under
  its usual name, `a3/a3-reset.ps1 -Go`, then `a3/a3-prep.ps1` again (the reset loses the chat list:
  the group's number may no longer be 13: the owner checks with `a3/a3-chats.ps1`), and the owner starts
  `a3/a3-start-console.ps1 -ApproveRead <number>`.
- 19:31: **SAVED FOR A TAKE-OVER (the owner: usage is running out).** State:
  - The combined downloader branch is `wip/downloader-2026-11-14` in `wt-downloader`, head d462838,
    clean tree, local only (NOT merged, NOT pushed).
  - Full runs (`runs-10c/*.log`): race detector passed on engine (238 s), exact (77 s), exact/wire
    (32 s), telegram (64 s) and the collector's named concurrent tests (281 s). Whole Windows tests passed:
    engine, exact, exact/wire, telegram, tally, tgstore, supply, store, catalog. **Still running or to
    read: `win-collector.log`, `win-cmd.log`, `win-gofmt.log` (must be empty), `win-vet.log`.** The
    script `runs-10c/win.sh` dies with this session if the app closes: re-run only what has no "ok".
  - No collector is running. The installed collector is the build of 4f5be66 (without these pieces).
    The test folders were reset at 17:38 and then the prep run stored the chat list (the owner's group of
    duplicates is chat 13 in that catalogue).
  **Next steps, in order (also in `START-SESSION-11.md`):**
  1. When the four remaining logs are clean: in `repo-archiver`,
     `git merge --squash wip/downloader-2026-11-14`, one commit (message: the three pieces and the
     reviews' fixes; no archive numbers), then a documents commit (FEATURES section 12 fourteenth round:
     three places decide, spot checks are testing flags; TRIED-BEFORE section 28: the two runs' table,
     the throttle conclusion, answers 9; the handoff's first block; roadmap rows; copy the two reviews
     from `wt-review-dl-A-scratch` and `-B-scratch` into `docs/review`). Push to `private`.
  2. Build: `go build -o <bin>\tgarchive-collector.exe ./cmd/tgarchive-collector` from
     `repo-archiver/archiver` after keeping the present build as `...-4f5be66.exe.bak`.
  3. Do NOT reset before the run unless the owner wants a clean comparison: the catalogue as it is has
     741 wanted, empty folders and chat 13 known. (A reset loses the chat list: then `a3-prep.ps1` and
     `a3-chats.ps1` again.) The new build takes the catalogue from schema 10 to 12 at its first start.
  4. The owner starts, in their own window, VPN on:
     `powershell -ExecutionPolicy Bypass -File a3\a3-sampler-start.ps1` then
     `powershell -ExecutionPolicy Bypass -File a3\a3-start-console.ps1 -ApproveRead 13` (untried
     script: it shows the log as it grows; the owner types yes at the cost question). The exact check is
     on by default (three places); the owner's OK covers this run.
  5. Read the numbers (`a3/a3-watch.py`, the hourly tables, the new heartbeat and status file, the
     window's try lines, the exact check's lines) against the two earlier runs (the table in
     `START-SESSION-11.md`): speed at 2 parts and above, share of slot time asleep, waits, losses,
     window level reached, hash requests and "same" verdicts in chat 13.
  6. Then breadth (`START-SESSION-B.md`, which a second session can start at any time).
- 19:33: **MERGED, PUSHED AND BUILT.** The last logs came back clean (collector whole on Windows 348 s, the
  commands, `gofmt` empty, vet ok). The downloader is one commit on the branch, a28700f, pushed to
  `private`, with the four reviews of today in `docs/review`. The collector in the program's folder is
  built from a28700f (the build of 4f5be66 kept as `...-4f5be66.exe.bak`); its help shows the new flags.
  **Steps 1 and 2 of the list above are done, except the documents commit** (FEATURES fourteenth round,
  TRIED-BEFORE 28, the handoff's first block, the roadmap rows: still to write). **Next is step 4: the
  owner's run** (`a3-sampler-start.ps1`, then `a3-start-console.ps1 -ApproveRead 13`), then step 5.
- 19:42: **THE ACCEPTANCE RUN IS RUNNING** (the owner started it 00:41:20 UTC; build a28700f; log
  `a3/logs/run-20261114-194119.out.log`; `a3-start-console.ps1` works: the log shows in the owner's
  window; the approval question for chat 13 was printed (32 messages, 1 request) and was still waiting for
  the owner's "yes" at 00:42). **First minute, to check against my 18:00 conclusion:** on server 2 (photos
  phase) 277 parts answered and 72 plain waits (one request in 5, where the earlier runs had one in 14),
  the waits now come 4 to 6 in the same second about every 3 s, window 3; 158 MB in the minute, about the
  earlier runs' photo-phase speed. **So with slots freed and more requests out, the refusals rose: that
  points to a rate allowance per few seconds, not a fixed share of requests: my "per request" reading
  may be wrong.** The video phase decides: compare MB per minute on server 2 with 4.85 to 5.6 MB/s.
  Also new: server 1 carried 206 MB in the first minute, then 4 speed-limit waits of 5 s (the first
  speed-limit waits seen on this account) and 3 lost connections; a window try there was aborted.
- 19:44: the owner typed yes; chat 13 is being read and downloaded. **The owner's standing direction for the downloader (again, 19:44): "don't reinvent the wheel if the other/older engine has a better system that we've iterated on there. Just improve on it the best you can, if you can."** For the next session: read the acceptance run's numbers first (server 2 in the video phase against 4.85 to 5.6 MB/s; waits per request; window level; the exact check's lines for chat 13). If freeing the slot and the upward rule do not clearly beat the earlier runs, do NOT invent a third scheme: port the old app's pacing as it stands at 12.31 (`wt-v12.31/core-service/internal/telegram/pacer.go` and `floodguard.go`: a waiting part keeps its slot, the flood guard's per-server and account gates, the 60-a-second limiter, the short-wait rule of 12.30), keep the new engine's switches (`-sleep-keeps-slot`, `-window-policy careful`) for the comparison, and improve only where a number shows it. The run is the owner's window; stop it with `a3/a3-stop.ps1` or Ctrl-C there when nothing is wanted, then `touch a3/stop-sampler`.
- 20:57: **THE ACCEPTANCE RUN IS DONE** (the owner ended it at 01:55 UTC; the work ended about 01:44:44; no
  collector running; sampler told to stop). Build a28700f, margin 1 s, slots freed, upward policy, exact
  check on. **756 of 756 files saved and verified, 18,021 MiB** (the first group's 734 and 22 of chat 13).
  Server 2 against the two earlier runs (no margin / margin 1 s / this run), "looks like":
  - **Speed: 5.6 / 4.85 / about 4.9 to 5.0 MB a second** (18,691 MB in 3,739 busy seconds). No gain.
  - **Plain waits: 1,261 / 1,359 / 2,940; one request in 14 / 14.5 / 7.5.** Twice the waits for the same
    bytes. Slot-seconds: answered 3,638, asleep with a slot 3,559, asleep without one 3,708, failed 377.
  - Pool connections lost: 759 / 261 / 153. Speed-limit waits on server 2: 0 / 0 / 15.
  - The window rule tried 2 to 3 parts once on server 2: speed per slot 3,051 then 2,162 then 2,778 KB/s,
    waits per 1,000 requests 167, 336, 224: **not kept**, rightly. Window max 3 (the trial), else 2.
  **CONCLUSION, replacing my 18:00 reading: Telegram holds this account at about 5 MB a second on that
  server; more requests only bring more refusals.** Freeing the slot buys nothing here. By the owner's
  direction (the older engine's way where it is as good or better): **recommend the default goes back to
  "a waiting part keeps its slot"** (`SleepKeepsSlot` true: half the refused requests for the same bytes),
  the upward rule stays (it refused the third part correctly), nothing else is invented.
  **The exact check, first real numbers:** 15 checks, 43 hash requests, all answered, no wait. **One
  answer carries up to 8 windows of 128 KiB (1 MiB per request)**: so a full comparison costs about one
  request per MiB. 3 small files "same" by every window (1 request each; the byte-identical photos of the
  first group that are over the floor): linked, not downloaded. 12 videos of chat 13 judged at three
  places (one at seven): all "different", and none of them turned out byte-identical after download (the
  store's 8 identical-after-download are the 8 small photos under the check's floor: 3 + 8 = the 11 known).
  So the group's duplicate videos either share a Telegram file (free match) or differ in bytes at the same
  size (likely the file's header: what the look-alike and frame checks are for). Not looked at further.
  **Owed:** the documents commit; the default switch above (the owner to say); then breadth.
- 21:04: **the owner: "I need you to instruct the next session to actually read the old code and learn from
  it. There's literally a lessons learned document, and a what we tried that didn't work document. Why
  are we spinning in circles? Take a look yourself as well."** I looked. The owner is right, and the
  failure is mine: `WINDOW-EVIDENCE.md` (read by me at 17:50) says a server's speed is about
  min(parts x 4 MB/s, a ceiling), that more parts bring the same bytes, and that the old account's
  server 2 brought 2.3 to 4.4 MB/s per part (5.2 to 7.5 MB/s in its best hours);
  `LESSONS-ix12.29-servers.md` says one part brings 3.5 to 4 MB/s and more parts "may only split a
  per-server ceiling"; TRIED-BEFORE 1 says more than 2 parts under a limit brought only more waits. **The
  test account's 4.85 to 5.6 MB/s on server 2 at 2 parts was inside the old app's normal range from the
  first run.** I never put the old app's number beside mine, called a normal speed a defect, and built the
  margin, the library log and the slot freeing to [name removed] it. Written as the first block of
  `START-SESSION-11.md` (what to read, the note to write before any proposal, the rule that a number is
  a defect only against the old app's number) and as a bullet in `CLAUDE.md`; memory `check-tried-before`
  updated.
