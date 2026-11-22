# Brief: the window: a waiting part frees its slot, and the window may grow (tenth session, 2026-11-14)

For one Opus coder in `C:\Users\trabi\Claude\Projects\Telegram\wt-window` (branch `wip/window-2026-11-14`,
at 4f5be66; Go module in `archiver/`). The owner (11-14): "I want the downloader to work, and be good...
don't test needlessly. Get it done then test... don't reinvent the wheel unless it actually improves
things." So: build it, a few tests that matter, hand back. One independent review and one full run happen
later for all the download pieces together.

## Why (two real runs on the test account, 11-13 and 11-14; `docs/TRIED-BEFORE.md` sections 1, 23, 27)

- About one part request in 14 is answered with a plain wait of 1 to 3 s, whatever the files are. The part
  sleeps the wait **holding its window slot**. With a window of 2: **31% of slot time asleep without the
  wait margin, 43% with it**. A working slot brings about 4.4 MiB a second (0.23 s a part); two fully busy
  slots would bring nearly 9; the runs got 5.6 and 4.85 MB a second.
- The default policy `Careful` (`internal/engine/policy.go`) steps the window down on every plain wait and
  holds it ten minutes: with a wait every few seconds the window never leaves 2. This is the trap the old
  app sat in for days (TRIED-BEFORE 23).
- The old app (read by the main session: `wt-v12.31/core-service/internal/telegram/pacer.go`,
  `attachment.go` `invokePart`) also keeps a waiting part's slot; it gets a wait per thousands of MB, so it
  never mattered there. Its pacer's history and what to avoid: `docs/WINDOW-EVIDENCE.md`. **Read that
  document in full: its section "The rule for the new app" is the specification of part 2.**

## Part 1: a part sleeping out a wait does not hold a window slot

- A part that Telegram answered with a wait (plain or speed limit) still sleeps the stated wait plus the
  margin before IT is asked again: nothing about a wait is shortened or bypassed.
- While it sleeps, **its window slot is free for another part** of the lane (another part of the same
  file or of another file, by the lane's normal order). When its sleep ends it needs a window slot again
  like any part waiting to go: it goes out as soon as one is free, before parts that have not been asked
  yet (it is the oldest).
- Bounds: the parts sleeping without a slot on a lane are at most the lane's window (so at most twice the
  window is held in memory and in file slots); beyond that a waiting part keeps its slot as today. Under
  the speed limit (the lane is limited) nothing changes: a sleeping part keeps its slot (more requests
  bring only more waits there: TRIED-BEFORE 1). A closed gate still stops everything new.
- File slots (5 small, 2 large per server) are not window slots: a file with a sleeping part keeps its
  file slot.
- Counters keep adding up: slot-seconds in flight, answered, failed, sleeping (now: sleeping WITH a
  slot), a new `SlotFreedSleeping` (sleeping without one), requests by kind. Say in the comments what
  changed in their meaning.
- A config switch `Config.SleepKeepsSlot` (default false = the new behaviour) and a collector flag
  `-sleep-keeps-slot` restore today's behaviour for a comparison run.

## Part 2: the upward-only window rule, as the default policy

A new `Policy` beside `Careful` and `AdaptiveCost`, the default from now on; `Careful` stays selectable
(the collector's existing way of choosing a policy, or a flag `-window-policy careful|upward`). Build
WINDOW-EVIDENCE's rule with these settled points:
1. Floor and start 2; the ceiling is the owner's parts ceiling (the pool is sized by it; today 4).
   Under the speed limit: the floor, no tries, nothing learned or forgotten.
2. Only upward tries: baseline, trial at n+1, baseline again; each at least 200 answered parts with the
   lane's slots busy and files waiting. Measure: bytes answered per slot-second with a request out, failed
   and timed-out requests included, sleeps left out. Keep n+1 when its speed per slot is above n/(n+1) of
   the two baselines' mean plus half the difference. Not kept: back to n, no try of that step for an hour,
   doubling to 8 hours. Kept: checked once more ten minutes later.
3. **A plain wait is not a verdict.** This account's floor rate is about one wait per 14 requests: so NO
   rule of the form "N waits within a minute". The window reacts only to: a single wait of 10 s or more;
   or, during a trial, a wait rate per request at least twice the baseline's and at least 5 waits more
   than the baseline's rate would give. Then: back to the last proven level, no tries for 30 minutes. The
   lane's gate for long or repeated long waits (`guard.go`) is unchanged.
4. Four answers of 8 s or more in a row take away one part (never below the floor).
5. Tries only while the lane is not short of files, not in a timeout storm, not limited, the network not
   away, and at most one try per lane in ten minutes.
6. What was proven per account and server is remembered across restarts if the catalogue's settings (or
   the Supply's holds) give a simple place for it; if that needs a schema step, keep it in memory, and say
   so (schema numbers 11 and 12 are taken by pieces not merged yet: add none).
7. **It acts from the start (no shadow mode)**: the owner asked why a switch nobody flips was shipped off.
   Every try writes one log line as it is decided (server, from, to, speed per slot before / during /
   after, waits per request in each, kept or not; constant format, numbers and fixed words) and is counted
   per hour in the engine's counters (tries, kept, taken back, reactions by cause). No new table.
8. With part 1 in, "slots busy" for the measure means window slots with a request out; sleeping parts
   without a slot are not in the measure.

## Tests: these and no more (injected clock, the engine's fake transport; no mutations)

- Part 1: a wait on one part of a 2-part lane: a third part goes out during the sleep; the waiting part
  is asked again not before its wait plus the margin, and before any part not yet asked; never more than
  the window in flight; never more than the window sleeping without a slot; under the speed limit the
  slot is kept; with `SleepKeepsSlot` the seeded request log equals today's
  (`TestEarlyRetryOffIsTodaysRequestLog`'s constants).
- Part 2, the five ways the old app failed (WINDOW-EVIDENCE's list): noise from files starting and
  finishing never lowers the window; background plain waits at one request in 14 do not pin the window
  at the floor; a server at its ceiling (speed per slot falls as parts rise) gives the step back within
  one trial; a server whose waits really rise with the window is left at the proven level; a change of
  the server's speed during a trial is not credited to the step.
- The privacy guard covers the new log line.

## Bounds (the owner's rules)

- Nothing against Telegram; never start the collector or any program of the app; a real run may be going
  on this PC: do not touch its process, the folders under the user's local application data, or the `a3`
  folder; never touch anything under `E:\T\`.
- Work only in `wt-window`. No push. Commit after part 1 and after part 2
  (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, last line
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`).
- Go through `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`.
- Run tests once per part, when its code is complete: `GOMEMLIMIT=1GiB GOMAXPROCS=2 GOFLAGS=-p=2`,
  `-count=1 -timeout 300s`, `-run` naming your tests plus `TestMargin|TestEarlyRetry|TestC3`; the whole
  `internal/engine` package once at the very end (it takes under a minute). No race detector, no Docker,
  no run of `internal/catalog` or `internal/collector` beyond the tests you name. Measure free memory as a
  separate command before a go command; under 3.0 GB wait.
- Bound every virtual-clock test (a timeout, a cap on iterations). No process of yours left running.
- `gofmt -l` and `go vet ./internal/engine` at the end. A short `docs/progress/window-REPORT.md`: what
  was built, the settled points kept or changed and why, what is not built, the tests.
- Privacy: numbers and fixed words only in anything printed, logged or written.
