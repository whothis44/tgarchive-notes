# Independent review of K15, three reads the store gives the Staging page (Core, K-4, 2026-11-16)

For one reviewer who has not seen the work. Read-only on the tree: you change no file of the copy and
commit nothing. Your one product is the file `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-K15-store.md`.
A short review: the change is about 140 lines of code in two files; aim for an hour.

## What is reviewed

Branch `wip/core-store` at 9844ef07, copy `C:\Users\trabi\Claude\Projects\Telegram\wt-core-store` (Go module in
its `archiver` folder), against the main head it was cut from: `git diff 788ebf77 9844ef07`. Two code files,
`internal/store/copier.go` (+39) and `internal/store/writer.go` (+97), one new test file, the coder's report.

`internal/store` is on the path of every download (`Writer` is the download engine's sink: `Open`, the
writes, the publish) and of every copy from the local staging folder to the library on a NAS (`Copier`). The
piece adds reads for a status page: the copiers' numbers from memory (`Copier.Load`), bytes counted as they
are written, the staging disk's state with "resting since" (`Writer.StagingNow`), and ONE change of
behaviour: when the staging disk is "away" and no download opens, the writer's own loop now probes it
(`probeAway`, `awayLook`, a goroutine per probe) so that "away" can end. **What a mistake costs: the old app
once had every download blocked for 3 hours by its staging disk (`archiver/docs/TRIED-BEFORE.md` section 8).
The rule of this piece: nothing in it may make a download's open or write, or a copy, wait longer than
before, nothing may send a download to the wrong place, and nothing new reads the library's folder.** That is
what you are looking for. Style is not.

## Read first

1. `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-K15-store-for-staging-page.md` (what the coder was given; it
   may itself be wrong: say so where it is).
2. In the copy: `archiver/docs/TRIED-BEFORE.md` section 8; `internal/store/writer.go` whole (`Open`, `place`,
   `create`, `stagingAway`, `stagingBack`, `stagingFull`, `Run`, `Settle`), `copier.go` around `allowed`,
   `account`, `tune`, `writeTagged`, `Gauges`; where the collector starts and stops the store
   (`internal/collector/staging.go`, `collector.go` near the "writer" task).
3. The difference in full; the coder's report (`archiver/docs/progress/core-store-REPORT.md`) last, and with
   suspicion. It names four departures from the brief: judge each.

## What to try to break (questions, not conclusions)

- **A download held up or misplaced.** With the probe: any ordering of `Open` (through `place`), a failed
  staging create (`stagingAway`), a full error (`stagingFull`) and the loop's probe in which an `Open` waits
  on a file system call it did not wait on before, or in which a download goes to the library when staging
  is in fact back and today's code would have sent it to staging for longer than one probe period, or goes
  to staging while it is away. The claimed period: after `probeAway` moved the probe time on, an open goes
  to the library without a look until the look answers: how long can that last when the look is fast, slow,
  or never returns (`probing` then stays set: who probes from then on, and is that today's behaviour or
  worse)? The change counter `awayGen`: can a look's stale answer still be applied (away ended and began
  again; a wrap is not a concern), or a fresh one be dropped for ever?
- **The goroutine.** It is not waited for at a stop. What can it touch after `Run` has returned and the
  collector has closed the store, the counters and the catalogue (`Counters.add` through `stagingBack`, the
  clock, the file system)? A panic inside it (the fake or real `FS.Free`): the "writer" task is supervised,
  this goroutine is not: what happens to the program? Can more than one run at a time by any path? Under the
  race detector, by name, run the coder's three probe tests and your own (see below).
- **`Load`.** No ledger call, no file system call: by reading every function it reaches (`allowed`, `limited`
  and what `SpeedLimited` is wired to in the collector: can that callback take a lock that a download or the
  copier's feeder holds, in the opposite order to `c.mu` anywhere?). It reads `limited()` outside `c.mu`
  where `Gauges` reads it inside: is either a lock-order hazard?
- **`Written`.** One atomic add on the copy's write path: anything else changed there? Counted exactly once
  per write that wrote bytes, also on a short write and an error with n > 0? The tuner: is anything it reads
  or does different (its fields, the lock, the order)?
- **"Resting since".** Over: a first full error, a second inside the rest, one exactly at the rest's end, one
  after it; the clock stepping back. `StagingNow` against `StagingState`: can the two disagree at one moment
  in a way a page would show as nonsense?
- **Counters and the shared report:** any line of the report, any hourly count, that changes meaning or
  number because of this piece (away starts and ends, away time, room unknown).
- **The tests:** does each new test fail without its code (try it with an overlay that takes one line out)?
  Does any judge on real time or leave a goroutine that can touch another test?
- **Privacy:** any name or path in a log line, an error's text or a count (none should be new at all).

## How to work

- **Prove what you can without editing the tree:** probe tests in a scratch folder
  `C:\Users\trabi\Claude\Projects\Telegram\wt-core-store-review-scratch`, loaded with `go test -overlay` (your
  `_test.go` files added into `internal/store`), each finding marked CONFIRMED (a probe shows it; keep the
  probe and its output) or PLAUSIBLE (by reading; say what would show it). No finding without the file and
  line (relative to `archiver/`).
- Go is not on PATH: in Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`,
  then `cd /c/Users/trabi/Claude/Projects/Telegram/wt-core-store/archiver`; prefix go commands with
  `GOGC=25 GOMAXPROCS=2`. Another agent builds on this PC: before EVERY go command read free memory
  (`powershell -NoProfile -Command "[int]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1024)"`)
  and wait 3 minutes and measure again while it is under 3,000 MB; never two go commands at once. Named
  tests only (`-run`), this one package. The race detector only by name on the probe tests (`-race -run`),
  and only if free memory is over 5,000 MB and the toolchain's race build works on this PC (if it does not,
  say so and go on without it: a whole race run follows in a container before the merge). No whole-package
  run, no Docker. Nothing contacts the network; never start the collector; never read anything under `E:\`
  or on a network share. Anything over 2 minutes in the background.
- Invented data only. Any file with a Windows path in it is written with a file tool, never from inside an
  inline script string. No path of this PC inside the report's findings.

## The report (`REVIEW-K15-store.md`)

First line: MAY BE LISTED, MAY BE LISTED AFTER THE MUST-FIXES, or NOT AS IT IS. Then the findings, the most
serious first, each with: a number, MUST FIX / SHOULD FIX / MINOR, CONFIRMED or PLAUSIBLE, file and line, what
happens to the owner in one sentence, the probe's name and output where there is one, and the smallest fix
you would accept. Then: what you checked and found sound, what you could not check, and each place where the
brief is wrong or silent. Your final message to me: the first line, the count by class, and the three
findings that matter most.
