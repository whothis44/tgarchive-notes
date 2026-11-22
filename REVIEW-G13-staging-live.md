# Review of G13 (the Staging page on the store's reads of the moment)

Independent, read-only review of `wip/pages-staging2` at 02b1ce2d against f7d6ca63 (`git diff f7d6ca63 02b1ce2d --
archiver/internal`, 14 files), brief `BRIEF-G13-review.md`. Nothing in the tree was changed (`git status` empty after);
probes and mutations ran from `wt-pages-review-g13-scratch` through `go test -overlay`, named tests only, one go
command at a time, the PC measured before each (free 3.3 to 3.6 GB, CPU 44 to 80 %). Nothing ran against Telegram.

**Verdict: may be listed after these fixes** (1 must fix, which is the already decided backstop done on the right
clock; 2 should fix; 5 minor).

## Must fix

### M1. The carried hold can stay "not held" for as long as the store's 24-hour marks stay equal: the 60 s backstop must be measured from the last *answer*, not from the reading before. CONFIRMED (probe)
- `internal/server/stagingread.go` 97-107 (`gaugesWanted`), 232-241 (the carry), 84 (`holdMarks`).
- The rule asks again only when `prev.Hold.Marks != lv.Day.WantedAgain + lv.Day.HoldMet`. `Day` is a sliding 24-hour
  sum (`livepages/staging.go` 142-156), so one event can leave the window as another enters.
- Sequence (probe `TestProbeG13DayMarksEqualAcrossLatch`, through the real adapter): yesterday's 12:00 hour holds 1 file
  made wanted again; today hour 11 holds 20. The gauges answer at 11:59:30, not held, marks 21. At 11:59:50 the copier
  latches (`guard.go` 210-221: `HoldMet` +1 in hour 11). The next reading at 12:00:03: yesterday's 12:00 hour has left the
  window, so the marks are 20 + 1 = **21, equal**. No put-off clause fires if the latching file had an earlier failed try
  (`later` keeps `last_fail_at`, so `stagingPutOffSQL`'s `last_fail_at = 0` leaves it out: `catalog/staging.go` 404).
- Probe `TestProbeG13HoldMissedWhenMarksEqual` (server, fake seam): the gauges say held, marks unchanged, 30 readings
  over 150 s: **0 asks, the hold shown in 0**; What needs you and the Overview say nothing needs the owner.
- How long in the store as it is: until the next decision that meets the hold changes the marks (the held file is
  looked at again after `CheckPause`, 10 minutes, and each look counts `WantAgainHeld`), or never if no file meets it
  again (then the hold stops nothing until one does, and that one shows it).
- A second way to equal marks: the kept reading is in memory as long as the program runs, so a page opened more than
  24 hours after the last answer compares against marks that have all left the window (0 against 0) after a latch whose
  files were since found again (the library back).
- Smallest change (the decided backstop, with what makes it work): give `holdState` the time of its answer (`At`,
  set where `rd.Hold` is set from the gauges, carried unchanged), and ask in `gaugesWanted` when
  `rd.At.Sub(prev.Hold.At) >= 60*time.Second`. `prev.At` is NOT that time: while a page is open a reading is made
  every 5 s, so a backstop on `prev.At` never fires. A failed ask keeps the old `At`, so the next reading asks again.
  Add the probe's sequence as a test (marks equal, gauges say held: shown at the first reading 60 s after the answer).
- Nothing against the backstop: one ask a minute on a steady page (1 in 12 readings) is cheap, and it also covers a
  Core change to how `WantAgainHeld` is counted (the author's second doubt).

## Should fix

### S1. "The store looks at the disk again by itself and ends this once it answers" is not true when the store's own look never returned. CONFIRMED (reading)
- `internal/server/stagingverdict.go` 66 (`verdictStagingAwayWords`).
- `store/writer.go` 536-541: "a look that never returns leaves probing set, so the loop never looks again in this run
  (also in a later "away")". After that only a download's open looks (`place`, 473-481). With downloads paused or
  nothing queued, "away" lasts until the program stops, and the page keeps saying the store will end it by itself. In
  that state the page's own free-space read is also stuck (`freeBusy`), so the "answers these pages now" form cannot
  appear either: this sentence is the one the owner sees.
- Smallest change: "The store looks at the disk again about once a minute, and at each download's open, and ends this
  once a look answers." (no "by itself"), or keep it and add "(if its own look never comes back, only a download's open
  looks again)". The other two changed sentences (read by the pages; resting with its two times, the end moved by a
  second full error) are true of `writer.go` 466-497 and 663-673.

### S2. A reading that did not ask the gauges leaves the reader's holds out, and the live poll then says the due files are taken "within 5 s". CONFIRMED (probe)
- `internal/server/stagingread.go` 106 and 265-272 (`heldNow`), `stagingverdict.go` 232-248 and 280-285.
- The reading asks for `HeldNow` only when `DueNow > 0 && Busy == 0` *at the reading*; the live poll judges with the
  memory's `Busy` of *now* and the kept reading. Probe `TestProbeG13HeldNowLeftOut`: 3 due, a copier busy at the
  reading (asked 0), the gauges would say 3 held by a reader; 2 s later no copier busy: the live verdict is "waiting",
  its first cause says "within 5 s" and nothing of the reader's holds.
- How long: until the next reading, 5 s (30 s when a reading takes over a quarter second); the Overview shows no causes.
  The comment on `heldNow` ("gaugesWanted asks them whenever the words need it") is untrue for the live poll.
- Harm: a false promise for a few seconds; nothing the owner must do. Smallest change: when `rd.Gauges == nil`, say
  the due files without the time promise ("...at its next look, unless a reader holds its staged copy (not read at
  this reading)"), and correct the comment. Asking the gauges whenever files are due would undo the saving.

## Minor

### m1. Two handlers at once can note the copiers' count out of order: that answer says "measuring" and the 10 s window starts again. CONFIRMED (probe of the mechanism); the timing is PLAUSIBLE
- `internal/collector/livepages/staging.go` 107 (`StoreNow` outside `s.mu`), 216-221.
- `Load()` is read before `s.mu` is taken; the 2 s live poll and the 5 s `/api/staging` (several `StagingLive` calls
  each) run on separate goroutines. If A reads (t=5.9 s) and B reads (t=6.0 s) but B notes first, A's `Now` is before
  the last sample: the samples are reset. Probe `TestProbeG13WrittenOutOfOrder`: in order known over 6000 ms; the
  out-of-order one known false over 0 ms ("measuring"); the next known over 2100 ms instead of about 8000.
- Not a 0, so no lesson is broken; the figure flickers. Smallest change: same run, `Now` before the last sample and
  `Written` not below the base: do not reset and do not append; answer against the base.

### m2. The "clock went back" rule of the written speed is untested. CONFIRMED (mutation)
- `livepages/staging.go` 218. Mutation: `|| l.Now.Before(last.at)` taken out: `TestStaging*` of livepages all pass.
  Without it a clock back by an hour gives "measuring" for that hour. Add one case to `TestStagingWrittenRate`.

### m3. "nothing written in the last 10 s" while the busy copiers are checking. PLAUSIBLE (harm), true of the count
- `stagingverdict.go` 110-131. `Busy` counts copiers "copying or checking" (`CopierLoad.Busy`); a read-back or the
  helper's hash of a large file writes nothing for minutes, so the copying verdict says "2 of 2 copiers busy (copying or
  checking); written to the library now, before its check: nothing written in the last 10 s". True as counted (writes
  return every 1 MB, `writer.go` 894, so a true 0 is not two readings inside one write call) and it is what the brief
  asked for, but it reads like a stall. Optional: "nothing written in the last 10 s (busy copiers may be checking)".

### m4. `speedOf` says "1000 kB/s" between 999.5 kB/s and 1 MB/s. CONFIRMED (reading)
- `stagingverdict.go` 135-143: `%.0f` of 999.5 to 999.99 is "1000". Compare against 999.5e3 (as `format.js` `bytes`
  does, line 21).

### m5. The put-off clause of `gaugesWanted` misses held files that once failed. CONFIRMED (reading)
- `stagingread.go` 101-105 with `stagingPutOffSQL` (`last_fail_at = 0`): a file that met the hold after a failed try
  (likely when files went missing while the share flickered) is counted under "failed and tried again", not under
  "wanting again held". The marks clause covers it; noted because the comment lists the clause as a separate guard.
  (Not new: the waiting cause sentence has the same blind spot since G5.)

## The hold goes on or off by ... -> the page shows it after ...

| The hold goes on or off by | In the store | The page (as built) | With the backstop on the answer's time |
|---|---|---|---|
| Latch at the hourly cap (`wantAgain`) | `Held` set, `HoldMet` +1 in the same call (`guard.go` 210-221) | the next reading (5 s; 30 s slow) | same |
| Latch while an equal count leaves the 24 h window (M1) | as above | the next decision that meets the hold (10 min `CheckPause`), or never while none does | within 60 s of the last answer |
| A decision that cannot read the record (fail closed) | `HoldMet` +1 (`guard.go` 199-205) | the next reading | same |
| Held on record from an earlier program run | `readWant` at the first decision or the first gauges ask | the first reading (`prev == nil`); the pages are made after the store and live as long as it, so no `prev` of another run in the program | same |
| The gauges' own read of an unreadable record (fail closed, no count) | answered "held" | at the reading that asked (asked again at every reading while held, so it clears at the next one that reads it) | same |
| Store not running (starting, closing) | unchanged | needs are not judged (`needsOf` returns at `!ok`); the hold carried, not shown | same |
| Release through the page | record written released (`guard.go` 274-285) | at once: `dirty`, and a held `prev` always asks. Not new: a reading begun between `dirty.Store(true)` and the release can keep "held" for one floor (5 s) after the toast (`stagingread.go` 559-569); set `dirty` again after the release | same |
| Release through a command | none exists (the page's route is the only caller of `ReleaseWantAgain`) | n/a | n/a |
| Restart of the store | releases nothing (record kept in the catalogue) | first reading asks | same |
| A new hour | does not release (`Held` survives the count's reset) | nothing to show | nothing to show |

What a missed hold costs the owner: the hold only stops files *found gone* from being made wanted again (downloaded
again); the files under it are looked at every 10 minutes anyway, so a button shown 60 s late adds at most 60 s to a
wait of up to 10 minutes. The waiting verdict's own cause "N wait under the wanting-again hold: they need you" comes
from the queue rows and shows regardless (for files without an earlier failure). The real cost is the lesson: during
the miss What needs you and the Overview say nothing needs the owner.

## Checked and found sound
- **Locks (point 4).** `StagingNow` takes `w.mu` only; `Load` reads the clock, `c.limited()` (the collector's
  `speedLimited`: `c.mu`, then each account's and session's locks and `Engine.Stats`, no catalogue) outside the
  copier's `c.mu`, then `c.mu` for two fields (`copier.go` 1443-1451). `stagingSource.StoreNow` calls both after
  `stg()` has let the collector's `c.mu` go (`pagesstaging.go` 22-26, 54). Callers: the live poll with no server lock;
  `readStaging` under `s.stg.mu` with its read transaction open (one of 8 reader connections; as before, and the base
  also called `Gauges` there, which asked `c.limited()` *under* the copier's mutex: this piece removes that ordering
  from steady readings); `handleUnstick` under `s.mu` (as before). Nothing on the collector's side holds `c.mu`, `w.mu`
  or a catalogue transaction while waiting on `s.stg.mu`; no cycle found. Not new: `place` holds `w.mu` across the
  staging disk's free-space call, so a hanging disk can hold `StagingNow` (the author says so too).
- **Written speed (point 3).** Base is the oldest sample inside 10 s, never older (a longer gap leaves only the new
  sample: "measuring"); never across another run (pointer compared), a count that went down, a clock back, or a "not
  running" answer in between (samples cleared); bytes never negative (samples rise monotonically within a run); span
  at least 1 s, so no absurd figure; `s.mu` guards `written` and `wRun` on every path; units decimal like `format.js`.
  The "copied and verified" figure keeps its own cases (under 30 s, nothing ended while busy) and only changes unit.
- **The adapter's other changes:** rest only when the writer itself says resting, with its own beginning (moved end
  keeps `RestSince`: `writer.go` 665-671); away since from `StagingNow`; `HoldMet` summed into hour and day.
- **The other changed sentences (point 5):** "read by the pages" form and its comment; the rest sentence; the foot
  ("the copiers and both speeds come every 2 s": `onLive` redraws the copiers, `copiersOf` takes the newer); the
  interface comments in `staging.go`. Times of the changed sentences go through `timeAt`/`timeUntil` (`verdictWords`).
- **Tests (point 6).** Mutation 1 (`l.Written < last.n` out): `TestStagingWrittenRate` fails ("a count that went down"
  Known with negative bytes). Mutation 2 (`gaugesWanted` always true): `TestStagingCopiersFromMemory` fails (1 ask, 6
  statements against 6) and `TestStagingGaugesWhenNeeded` (5 errors). My own mutation 3 (the marks clause out):
  `TestStagingGaugesWhenNeeded` fails (5 errors). Removed test functions against the base: 0. The two adjusted tests
  (`TestStagingVerdictWords`, `TestStagingAwayMarkReadable`) still tell the two away forms apart and only read the
  words with times filled in. No test judges on real time: `TestStagingCostAtSizeMemory` times and logs but judges
  only the asks; `TestStagingLiveLook` sleeps and is skipped unless its variable is set.

## What I did not look at
- `pages_g13_test.go` beyond its name, the browser look, the measured readings, the demo; whole packages, the race
  detector (the author lists `livepages` and `TestStagingConcurrentRequests` for the full runs: m1 is the one
  concurrent behaviour found); the scripts beyond `stagingrows.js`'s three functions and `staging.js`'s changed lines;
  `TestScriptsTimeOnlyThroughFormat` and node checks were not re-run.

## Probes and mutations run (scratch `wt-pages-review-g13-scratch`, overlays; counts only)
| Run | Result |
|---|---|
| livepages `TestProbeG13DayMarksEqualAcrossLatch` | marks 21 at the answer, 21 after the latch (equal) |
| livepages `TestProbeG13WrittenOutOfOrder` | in order known/6000 ms; out of order not known/0 ms; next 2100 ms |
| server `TestProbeG13HoldMissedWhenMarksEqual` | 30 readings over 150 s, 0 asks, hold shown 0 times |
| server `TestProbeG13HeldNowLeftOut` | asks 1 then 0; live cause says "within 5 s", no reader's holds |
| mutation 1 (count down) | `TestStagingWrittenRate` FAIL |
| mutation 2 (always ask) | `TestStagingCopiersFromMemory`, `TestStagingGaugesWhenNeeded` FAIL |
| mutation 3 (marks clause out) | `TestStagingGaugesWhenNeeded` FAIL |
| mutation 4 (clock-back check out) | livepages `TestStaging*` PASS (untested: m2) |
