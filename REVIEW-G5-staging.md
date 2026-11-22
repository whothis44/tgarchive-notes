# Review G5: the Staging page (independent, read-only)

Branch `wip/pages-g5-main` at 84d9991a (copy `wt-pages-g5m`) against 5b29e28b, 24 files. Reviewed 2026-11-16 by an
agent that did not write it. The tree was not changed (`git status` clean before and after); probes were loaded with
`go test -overlay` from `wt-pages-review-g5-scratch`. Invented data only; nothing ran against Telegram, a real
catalogue, staging folder or library.

**Count: 2 must-fix, 7 should-fix, 14 minor.** Marks: CONFIRMED means proved by a probe test or shown by the lines
quoted. PLAUSIBLE means argued from the code, with what would settle it.

---

## Must fix before the merge

### M1. The verdict says "downloads go on into staging" exactly when downloads can go nowhere. CONFIRMED (probe P1)
`internal/server/staging.go` 221-222 (the words), 286-289 (the order). The verdict that comes first, "library away"
or "library full", always says "downloads go on into staging". The rest of the store's state is never checked.
- Sequence: staging is below its keep-free line (or the staging disk is away), and then the share drops. The writer
  sends every new download straight to the library (`writer.go` 431-461, 504-518). `createLibrary` fails against the
  away share, so `Open` returns an error and the engine gives the file back (`writer.go` 319-324). Downloads have
  stopped. The page shows the top verdict: "The library is away since 06:18:00 (2 min): copies wait and are tried
  again by themselves; downloads go on into staging."
- Probe P1 printed that sentence for "library away + free under keep" and for "library away + staging away". For
  "library full + free under keep" it printed the full-disk sentence with the same ending. The author's own test
  states the false sentence as expected: `staging_test.go` 189-190 ("library away beats staging", with staging away
  and resting, expects "downloads go on into staging").
- This is the one state on this page where the owner most needs to act (nothing downloads anywhere), and the page
  says it is fine.
- Smallest change: in `judgeStaging`, when the library is away or full, choose the clause from the staging side. If
  `StagingAway || noRoom(lv, rd)`, say "staging has no room (or is away) too, so downloads stop until one of them
  is back". Otherwise keep "downloads go on into staging". Fix the test case at 189-190 and add the three pairs of P1.

### M2. "Let it go on" is accepted when nothing is held, and every accepted release resets the hour's count. CONFIRMED (probe P2)
`internal/server/stagingread.go` 346-364, `internal/store/guard.go` 274-285.
- `handleReleaseWantAgain` calls the store whatever its state. `Copier.ReleaseWantAgain` always writes
  `WantAgainRecord{Hour: now, Count: 0, Held: false}`.
- A release when nothing is held therefore gives the copier a fresh cap of 20 files this hour on top of those
  already made wanted again. Each of those files is downloaded again from Telegram.
- Sequence: the owner has two tabs open, or a reading up to 5 s old (30 s when the reading is slow). Tab A releases.
  The copier's next looks make files wanted again. Tab B still shows the button from its older reading. The owner
  clicks it, and a second hold the owner never saw is released, or the count is reset with no hold at all.
- Probe P2: with the gauges saying "not held", `POST /api/staging/release-want-again` answered 200 and reached the
  store once.
- This is the guard that `guard.go` calls "the most dangerous decision after a delete". A click must not widen it
  without a hold on screen. Under the project's rules it also starts Telegram downloads without the owner seeing
  their cost (see S6).
- Smallest change: in the handler, read `s.staging.StagingGauges(ctx)` first. Answer 409 "Nothing is held now:
  nothing was changed." unless `WantAgainHeld` is true. Mark `dirty` as now. Add the probe as a test.

---

## Should fix

### S1. The "copy speed" is not what crosses the link: 0.0 MB/s while copiers copy. CONFIRMED (code)
`livepages/staging.go` 103-115 and 123-156 sum `Hour.CopiedBytes`. The store counts those bytes only in
`finish()`, once a copy is verified, published and catalogued (`copier.go` 839-841).
- A copy whose verification is put off counts nothing: no helper answer, not speed-limited, `-read-back-now` off
  (the default, `command.go` 457). `copier.go` 706-713 records `CopyCopied` and `Deferred++` only.
- Its bytes are counted later, when its check finishes. That check is a read, in the speed-limited hours.
- Sequence: the NAS helper does not answer for an hour of unlimited speed. Three copiers write at about 2 MB/s each,
  and the verdict says "Copying to the library: 3 of 3 copiers busy; 0.0 MB/s over the last 5 min". In the next
  limited hour the read-backs finish and the "speed" jumps while nothing is copied.
- A big file has the same problem without the helper: 4 GB at 4 MB/s ends after about 17 min. Every 5-minute window
  shows 0 and then one spike.
- The old app's lesson was "show the copy speed live, so a drop points at something else" (brief, LESSONS 6d). This
  figure cannot show a drop for up to 5 minutes.
- Smallest change without touching the store: call it "recorded in the library (verified)", not a speed of the
  link. When the hour's `Deferred` grows, say that copies kept unverified are not in it. Put the store's
  bytes-as-written (`Copier.copied`, private) on Core's list as a gauge for later.

### S2. "Staging has no room" is the page's guess, not the writer's rule. CONFIRMED (code)
`staging.go` 267-272 judges `rd.Free < lv.KeepFree`. The writer stages a download only while
`free - pending - size >= KeepFree` (`writer.go` 450-461), where `pending` is what the downloads in flight will
still write.
- Sequence: 55 GB free, keep-free 50 GiB (53.7 GB), 2-4 GB videos downloading. Every video goes straight to the
  library over the Wi-Fi link while the page says "Copying ..." or "Nothing to copy".
- The "staging full for 10 minutes" need (`needsOf` 380-382) never appears.
- The only trace is the hour's "Written straight to the library" row, further down.
- Smallest change: use the store's own evidence. The adapter already samples the hours, so `BypassFiles` growing
  since the last sample (or within the last 5 min) means "new files are going straight to the library (staging
  keeps N free and a download did not fit)". Feed that, not only free < keep, to the verdict and to `roomless`. Say
  in `numFreeCounts` that downloads in flight and the file's own size count too.

### S3. "The staging disk is away" can stay on the page for hours beside a free space just read. CONFIRMED (probe P3, code)
- The writer clears "away" only inside `place()`, at the next download open (`writer.go` 438-449). With downloads
  paused, an account stopped, or nothing queued, `StagingAway` stays true after the disk is back.
- The page's own `freeBytes` reads the same disk and shows it. Probe P3: the verdict "The staging disk is away since
  05:20:00: new files go straight to the library." and the number "Free on the staging disk" known, at 400 GB.
- The same applies to the needs list and the Overview count.
- Smallest change: when the page's own read of the free space succeeded after `StagingAwaySince`, say "the store
  last found the staging disk away at X. It reads now, and the store looks again at the next download."

### S4. Two verdicts lump different causes or say something false. CONFIRMED (code; the author's test at `staging_test.go` 204)
(a) **"Waiting, none busy"** (`staging.go` 227, 303-304) counts every unstuck copy entry. That includes entries put
off without a failure by `CopyLater`:
- `later_why` "absence being confirmed", 5 min
- "wanting again held", which needs the owner (re-looked every 10 min)
- "a check reads it"
- "not published locally yet"
- files passed over under a reader's hold (`Gauges.HeldNow`, dropped by the adapter).

It also counts entries due now with no copier on them, which would be a fault. One sentence, "(K failing now:
tried again after a pause)", covers all of these, and it reads "(0 failing now ...)" when none fails.

Smallest change: one more `SUM` in the reading's summary statement for `next_try > now AND last_fail_at = 0` (put
off, by `later_why`), plus the earliest `next_try`. Then say "N wait for a time (the next at HH:MM; why)" apart
from "N due now".

(b) **In speed-limited hours** with checks waiting (`staging.go` 305-308), the verdict falls to "Nothing to copy:
staging holds no file waiting for the library."
- Those checks keep their staged bytes ("The bytes stay staged", `catalog/staging.go` 413-415).
- They are read back now, after their `CheckPause` (up to 10 min).
- The author's test asserts this false sentence at 204.

Say "N copied, not verified, are read back in these speed-limited hours" instead.

### S5. A stuck file "unreadable" gets advice that cannot help. CONFIRMED (code)
- The only place that sets `StuckUnreadable` is `copyStaged` when the catalogue's own SHA-256 of the file is not 64
  hex characters (`copier.go` 649-650; every other open or read error is an ordinary failed try).
- The page says "The staged copy cannot be read." and "Check that the staging folder can be read (its disk, its
  permissions), then try again." (`staging.go` 161-162).
- The owner checks a healthy disk, clicks, and the file is stuck again at once. Each click is harmless but useless.
- Smallest change: words that say the catalogue's record of its hash is bad, that nothing on the disk will fix it,
  and that trying again stops at once.

### S6. "Let it go on" does not say its cost before the click. CONFIRMED (code)
`needWantAgainWords`/`Do` (`staging.go` 341-342) say "downloaded again" but not how many. The release lets the
copier make up to `WantAgainCap` files (default 20) wanted again this hour, each downloaded again from Telegram,
and then it holds again.
- The project rule is no Telegram requests from a click without the owner's OK and the cost.
- Smallest change: hand the cap to the page (the collector's `cfg.Store.WantAgainCap`, or 20) and say "up to 20
  files this hour, each downloaded again from Telegram". Also say how many are held, if the reading counts
  `later_why = 'wanting again held'` (one more `SUM` in the existing summary).

### S7. The library "full" while one copy runs, and wrong words about when copies drop to 1. CONFIRMED (code)
- `Copier.LibraryFull()` is true during `halfOpen` (`copier.go` 1336). That is the state after a probe found room:
  one copy at a time runs until one succeeds (1305-1311). During it the verdict says "copying waits until it has
  room" and the needs item says "nothing is copied to it". With a big file, `halfOpen` lasts minutes.
- `copiersPinned` (`stagingview.go` 131) says "1 for a while after the library comes back". The drop to 1 happens
  only after the library's disk was **full**, never after the library was away.
- Smallest change: fix both sentences. The adapter cannot tell `halfOpen` from full without a store change, so the
  verdict should say "the library's disk was full since X: copying waits for room, or tries one copy at a time".

---

## Minor

1. **The verdict with no gauges falls to "Nothing to copy" beside a waiting count. CONFIRMED (probe P4).**
   `stagingview.go` 148-150 turns the empty verdict into "Nothing to copy". Probe P4: 5 files waiting, verdict
   "nothing". It is hardly reachable in the program, because the pages attach after the store is set. Say "not known
   at this reading" instead.
2. **Half of each reading is the store's queue summary, read and thrown away. CONFIRMED (measured).**
   `Copier.Gauges` runs `Ledger.Summary` and `OldestCheck` (`copier.go` 1417-1421), and the adapter keeps only the
   copiers, the speed limit and the hold. At 100,000 entries: 205 ms against 82 ms, and 152 ms against 65 ms (see
   Measurements). This cannot be cut without a store accessor; note it for Core. It also makes the 30 s slow floor
   kick in sooner.
3. **The speed hides a dropped hour. CONFIRMED (probe P6).** The adapter sums all kept hours. When the store lets its
   oldest hour go while new bytes outweigh it, the sum does not go down and the samples are not reset. Probe: 1,500
   bytes copied in 60 s were counted as 500. Sum only the hours inside the window, or the hours present in both
   samples.
4. **The copiers' busy share can pass 100 %. CONFIRMED (code).** `BusyNanos` is added whole in the hour a copy ends
   (`copier.go` 632-633), while the time allowed accrues as it passes. A 20-minute copy that ends at 14:05 with one
   copier shows about 400 % "of the time allowed this hour". Cap the share, or say what it counts.
5. **"Kept free: 53.7 GB" for the default of 50.** `numKeepCounts` explains it, but the figure reads wrong. Show it
   as the owner gave it ("50 × 2^30 bytes (53.7 GB)").
6. **The read-back verdict ignores `-read-back-now` and the 24-hour bound.** It says "(a read-back is put off to
   speed-limited hours)" even with `-read-back-now`. With downloads paused there are no speed-limited hours (no lane
   busy, `staging.go` of the collector 291-304), so the check waits `DeferMax` (24 h), which the page never says.
7. **"Copying to the library" counts checks.** `Busy` includes copiers that are reading back or asking the helper.
8. **The verdict can flip between "copying" and "waiting" between readings. PLAUSIBLE.** `Busy` is sampled at one
   instant, every 5 s, and with small files a copier is free between files. To settle: a rig run with allowed=1 and
   many small files, logging the verdict kind at each reading.
9. **"Since" for no room can come from an old reading.** `liveOfStaging` judges `noRoom` against the kept reading,
   which on any page but Staging and Overview can be arbitrarily old. A "since" can then span a period that had room.
   Track `roomless` only when a reading is made.
10. **The Overview's "as of" is the reading's time**, but its count also holds "library away" and "no room" judged
    from the memory now. Say both, or the older.
11. **"Try its copy again" understates its cost or its effect.**
    - For "no free name" it copies the whole file again over the link and reads in full each same-named library file.
    - For a stuck check it first records a failed try (its part was removed when it stuck), so it shows under
      "failing now".
    - The answer "Back in line: the copier takes it when the program runs" (`stagingread.go` 300-303) is given while
      the program runs but its store does not.
12. **Each stuck file's "Last failed try" is the last failure on record**, which may have nothing to do with why it
    is stuck (`err_step`/`err_class` are cleared only by `CopyCopied`). Say "an earlier failed try" when it predates
    the stuck.
13. **The rig test can pass its "came back by itself" step vacuously. CONFIRMED (code).** In `pages_g5_test.go` 72
    and 74-77, `!live().LibraryAway` and "kind is not library away" also hold when the store is not running. Require
    `running` and a verdict kind other than "not running". The 59 to 60 s "back" is the copier's `ProbeEvery` (1 min).
14. **Smaller points:**
    - The JS release button could lose its `onclick` and no test would fail: `TestStagingPageRows` only looks for the
      path string.
    - `stagingrows.js` 42 says "copies before checks", but the index orders 'check' first. The list's "in the
      copier's order" means nothing for stuck files, which the copier never takes.
    - `stagingSummarySQL` and `stagingOldestCheckSQL` copy the catalogue's statements word for word, so a later change
      to `catalog.QueueSummary` will not reach the page.
    - PLAUSIBLE: `/api/live` now takes the writer's `w.mu` (`StagingState`), which `place()` holds across a disk
      free-space call. The server's own `freeBytes` runs with no timeout under `stg.mu`, which blocks Staging and the
      Overview. Both are fast on the owner's local staging disk. To settle: a free-space call on an unreachable
      network path, timed.

---

## Why a file is stuck -> is un-sticking it safe (point 2)

The click runs `UPDATE file_queue SET stuck = 0, next_try = 0 WHERE file_id = ?1 AND stuck <> 0`. The catalogue's
own way, `catalog.CopyStuck(id, 0)` through `storeledger`, only sets `stuck = 0`. The page adds `next_try = 0` and
the guard. Nothing else is involved:
- no attempt count, failure record or copier wake-up beyond what `CopyStuck` itself does;
- the feeder looks again within `PollEvery` (5 s) when a copier is free;
- `next_try = 0` puts it in the "never tried" range, oldest staged first, so it jumps the line.

| Why stuck (where it is set) | What one click makes happen | Safe? |
|---|---|---|
| Staged size differs (`copyStaged`, `copier.go` 666-667) | Open, check the size, stuck again. No byte crosses the link | Yes |
| Staged bytes changed (`copyStaged` 692-695; its part removed) | The whole file is copied again over the link, the hash differs, the part is removed, stuck again. Nothing published, library untouched | Yes; costs one full copy per click (the page says so) |
| "Unreadable" (`copyStaged` 649-650: the catalogue's SHA-256 is not valid hex; the only setter) | Stuck again at once, nothing read | Yes; the page's advice is wrong (S5) |
| No free name (`publish` 919-925, every candidate holds other bytes) | Copy state: the whole copy again, the same-named library files read in full, stuck again. Check state: its part is gone, so verify finds it missing, a failed try is counted (CopyBack), then a copy | Yes. Publish never replaces, and same bytes are compared in full. The cost is not said (minor 11) |
| Name refused (`createPart` 764, `publish` 923, `check` 938, `checkStraight` 966) | Stuck again at the same step: before any write (createPart, a bad recorded path), or after a full copy (publish) | Yes |
| Library copy disagrees | Never stuck: a copy's mismatch is a failed try, a check's part goes back to a copy, a straight file is wanted again after a second look | n/a |
| Missing from staging | Never stuck: `missing()` puts it off, adopts it, or makes it wanted again under the cap | n/a |
| An unknown future value | Generic words; the copier decides again | Yes |

More on the click:
- **Publishing bad bytes:** the click cannot cause it. Every publish follows a verified copy (the helper's hash or a
  full read-back), and `Publish` never replaces a file.
- **Overwriting a good library file:** no. A name holding other bytes is passed over.
- **Looping forever:** no. Every click is at most one try, and the file sticks again by itself.
- **`next_try = 0` against the doubling pause:** attempts are kept, so the next failure's pause still doubles. The
  click skips one pause only. For a straight check it also counts the fallback again and books the result as "read
  back at once" (counts only).
- **A click while the copier holds the row:** a stuck row is never handed out (`DueCopies`/`DueChecks`, rule 6). A
  row unstuck meanwhile by another tab gets 409 and no change.
- **The hold of the writer:** one statement by primary key on the single writer, under the server's `s.mu`. It waits
  only for a write already running.

---

## Measurements (looks-like; free memory 6.2 GB each time; CPU before and after each run)
- `TestStagingCostAtSize` (author's: 100,000 entries, 1,000 stuck, the fake gauges' two statements): best of 3,
  **139 ms**, CPU 79 % then 53 %. The author had 202 ms at 65 %.
- Probe P5, the same size split in the same run (CPU 79 % then 53 %): with the gauges **205 ms**, the server's own
  transaction alone **82 ms**. Second run (CPU 55 % then 54 %): **152 ms** and **65 ms**. The store's discarded
  summary is over half of each reading, and it adds up across one reading every 5 s.
- `TestStagingPollStatementsBounded` (CPU 55 %): over a minute, calm and in a storm, the live poll ran 0 statements;
  there were 12 readings and 72 statements in the page's answers. Two tabs share the one kept reading. An open page at
  100,000 entries costs about 12 × 150 ms of reader time a minute, or 2 a minute once on the 30 s floor.
- `TestStagingPageLibraryAway` (rig, CPU 54 %): passed in 3.67 s. The library came back 59 s of the clock after the
  fault ended (the probe's one-minute period).
- The author's named server tests were re-run and pass: TestStagingVerdictWords, TestStagingNumbersSayWhatTheyCount,
  TestStagingNeedsYouList, TestReleaseWantAgainFromPage, TestStagingPageWithoutProgram, TestStagingLogNoNames,
  TestStagingPageRows, TestMutationsRefusedFromElsewhere, TestCrossSiteRefusedOnEveryRoute, TestDemoRunWritesNothing,
  TestScriptsNoDuplicateOrMissingNames (CPU 71 %). The livepages tests TestStagingAdapterMaps and
  TestStagingRateWindow also pass.
- Probes, all failing on purpose (each failure is the finding): P1 (M1), P2 (M2), P3 (S3), P4 (minor 1), P6 (minor 3).

## Checked and found sound
- `GET /api/live` reads no table (test re-run). Its staging part takes these locks briefly: the collector's `c.mu`,
  the copier's `mu`, the writer's `mu` and the counters' `mu`. It reads no catalogue (see minor 14 on `w.mu`).
- The reading is one read transaction on the reader pool (`Catalog.DB()` is `rdb`), so its counts and its stuck
  list are of one snapshot. Its plans use `file_queue_due` with no temporary b-tree (the author's EXPLAIN test). The
  stuck list is capped at 50 and says "the first 50 of M".
- The unstick is one statement by key, guarded `stuck <> 0`, with 409 when nothing changed. Attempts are kept.
- The routes go through `handle(...)` and so through the guard (same origin and the run's token); tests are listed in
  `mutating` and `programOnly`. The release route is absent (404) without the program. The demo refuses both writes.
- Logs: route and error class only (`s.fail`). The folders are shown on the page only. Names, folders and errors
  reach the DOM only as text nodes (`dom.js` puts strings in `textContent`; there is no `innerHTML` in any script).
- **The collector's source is read-only:** `pagesstaging.go` only reads `c.cfg` and `c.stg` under `c.mu` and calls
  methods that take their own locks. No two locks are nested. The pages attach after `c.stg` is set (`collector.go`
  703 before `markReady` 715) and stop before the collector stops (`runWithPages`), so a stop cannot deadlock on a
  handler. The adapter starts no goroutine and no timer; its samples sit under a mutex.
- The release maps the collector's errors to fixed words (409), and a failed write keeps the hold (`guard.go`
  280-282).
- The tests judge on the fake clock. The size tests skip under the race detector and `-short`. The rig test's real
  times are upper bounds only. No test needs Windows (the node test skips without node). The author's five mutations
  are each caught by the test named; I found no claim of a catch that its test would miss (but see minor 14 on the
  JS button).

## Not looked at, or not verified
- I did not open the page in a browser at desktop or phone width. The script was read, not run, except for the
  author's node test.
- No real copier reached its wanting-again cap, and no real `halfOpen`, read-back put off, or straight write was run.
  S1, S2, S4, S6 and S7 rest on the store's code as quoted.
- How long `freeBytes` (Windows) hangs on an unreachable path, and the verdict flicker (minor 8): not measured.
- No whole-package runs, no race detector, no `go vet` or `gofmt` (the author reports them clean).
- Report and progress files: read, not checked line by line beyond what is above.

## Race detector for this piece
- **`internal/collector/livepages`: yes.** It is a small package and quick. `Staging.samples` is shared state that
  every concurrent page request writes (`/api/live` from each tab, the staging and overview readings).
- **`internal/server`: no whole-package race run for this piece.** The new shared state, `stagingKeep` (an atomic
  pointer, the `dirty` flag, `roomless` under its own mutex, one working-out mutex), is plainly guarded. None of the
  new tests sends requests concurrently, so a race run would prove little. If one is wanted, add one small test that
  runs `/api/live`, `/api/staging`, `/api/overview` and an unstick in parallel goroutines, and run only that test
  under `-race`.
- **The collector: no.** `pagesstaging.go` is read-only accessors over methods that already take their own locks,
  and it starts no goroutine. At most, run `TestStagingPageLibraryAway` alone under `-race`, because it drives these
  accessors while the copier runs.
