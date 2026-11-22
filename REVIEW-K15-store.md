MAY BE LISTED

# Independent review of K15 (the store's three reads for the Staging page), 2026-11-16

Reviewed: `wip/core-store` at 9844ef07 against 788ebf77 (`internal/store/copier.go`, `internal/store/writer.go`,
`internal/store/stagingpage_test.go`, the hand-back). Read-only on the copy: nothing in it was changed. Probes and
mutations ran through `go test -overlay` from the scratch folder `wt-core-store-review-scratch` (probe file
`k15rev_probe_test.go`, mutated copies `writer_mut_{a,b,c,d}.go`, outputs `out-probes.txt`, `out-mut-{a..d}.txt`).
Named tests of `internal/store` only; free memory measured before each go command (5,255 to 5,703 MB).

**The rule of the piece holds.** No path found where an `Open`, a download's write or a copy waits on anything it
did not wait on before; no path sends a download to staging while it is known away; nothing new touches the
library's folder; no new text. No MUST FIX. Five MINOR findings, two of them one-line fixes worth taking before the
listing (2 and 3). One older hazard, not of this piece, is reported apart at the end because it is the one that
matters for TRIED-BEFORE section 8.

Count: MUST FIX 0, SHOULD FIX 0, MINOR 5 (3 CONFIRMED, 2 PLAUSIBLE). Plus 1 pre-existing hazard (CONFIRMED), not
counted.

## Findings

### 1. MINOR, CONFIRMED: a look that hangs stops Run's probes for good, also in a later "away"
`internal/store/writer.go:537` (`w.probing` in the condition) with `:554` (cleared only when the look returns).
- What happens to the owner: after one hung `FS.Free` on the staging folder, a later "away" (begun and left by
  downloads in between) is again never ended by the loop while no download opens: the store says "staging away
  since ..." in a quiet period, which is what part 3(b) was built to stop. Downloads are not affected (`place`
  still looks for itself one period after each claim). The page's own read (`internal/server/stagingverdict.go:122`,
  "back") softens it on the page.
- Probe `TestK15RevHungLookStopsLoopProbes`: look 2 hangs; at t0+2m a download's own look ends away; the next open
  meets the room unreadable (away again since t0+2m0s); the disk then answers, no download opens; output: "10 min
  later: away true, Run's looks meanwhile 0"; after the hung call returns: "away false".
- The coder's `TestK15ProbeHangHoldsNoOpen` enshrines "no second look while one hangs" for the same episode, which
  is a fair choice (one stuck goroutine at most). The cross-episode case is not said anywhere.
- Smallest fix I would accept: say it in `probeAway`'s comment and the hand-back (a hung look disables the loop's
  probe until it returns; downloads still probe). A code fix (remember the running look's generation and allow one
  more look once `awayGen` has moved past it) buys little: a hung local disk is rare, and finding P below dominates
  it.

### 2. MINOR, CONFIRMED: a failed look stretches the probe period by the look's own duration
`internal/store/writer.go:559` (`w.stagingAway(now)` in `awayLook`, `now` read after `Free` returned, `:552`).
- What happens to the owner: when Run's look takes d and fails, the next probe is (end of look) + AwayProbe instead
  of (claim) + AwayProbe, so a staging disk that came back is noticed up to d later and downloads go to the
  library for up to d longer (d < AwayProbe; beyond that a download's own look takes over). Today `place` sets
  the next probe from the time taken before its look.
- Probe `TestK15RevLookFailPushesProbe`: the claim at t0+1m, the look takes 40 s and fails, the disk is back;
  output: "at 2m1s after t0 (claim + period + 1 s): open to staging false, new looks 0, away true"; "away ended
  at 2m40s after t0".
- The else branch does nothing else: the claim in `probeAway` (`:542`, `:543`) already moved `nextProbe` and
  `awayGen`; `stagingAway` with `w.away` true adds no count.
- Mutation d (else branch removed): every coder test passes (`TestK15AwayEndsByTheLoop`,
  `TestK15ProbeHangHoldsNoOpen`, both subtests of `TestK15ProbeOvertakenChangesNothing`), and the probe then shows
  "open to staging true, new looks 1, away false" at claim + period + 1 s.
- Smallest fix: drop the else branch (a failed look changes nothing; the claim already set the next probe). The
  brief asked for this line (section 3(b): "when it does not, set the next probe as stagingAway does"), so the
  brief is the cause.

### 3. MINOR, CONFIRMED: a panic inside the look ends the whole program
`internal/store/writer.go:546` (`go w.awayLook(gen)`), `:551`.
- What happens to the owner: a panic in `FS.Free` (or in the test hook) inside the look's goroutine is not
  under the supervisor that guards the "writer" task (`internal/collector/supervisor.go:59`): the collector
  dies instead of the task restarting.
- Probe `TestK15RevLookPanicEndsProcess` (child process; Run wrapped in a recover as the supervisor wraps it, the
  fake `Free` panics at the loop's look): "child exit error true; survived false; the panic's stack names
  awayLook true". Only booleans were printed.
- Weight: the real `OSFS.Free` (`internal/store/osfs_windows.go:31`, `osfs_linux.go:40`) has no panicking path,
  and a panic in `place`'s `Free` reaches the engine's lane through `Sink.Open` (`internal/engine/lane.go:774`),
  where I found no recover around the call (I did not trace the lane goroutine's whole stack). So this is
  likely "as unguarded as today's open", not worse in practice.
- Smallest fix: in `awayLook`, a `defer` that recovers, clears `probing` under `w.mu` and applies no answer.

### 4. MINOR, PLAUSIBLE: the negative "no second look" checks in the coder's tests race the look's goroutine
`internal/store/stagingpage_test.go:521`, `:534`, `:592`.
- What happens: these read `g.count()` right after `tick`, but a look would be started in a goroutine, so a
  wrongly started look may not have reached `Free` yet: the check can pass when it should fail. With mutation a
  (`w.probing` removed from the condition) the run still failed, at `:593` ("3 looks while one hangs") and at the
  later state check in "place keeps away", so the tests catch it today by later assertions and by timing.
- What would show it: a slow scheduler (or a `runtime.Gosched`-free fake) making `:592` pass under mutation a.
- Smallest fix: after `tick`, assert on what `probeAway` does synchronously before Run waits again: `w.probing`
  read under `w.mu` is false and `len(r.probed) == 0`.

### 5. MINOR, PLAUSIBLE: "resting since" after the wall clock steps back
`internal/store/writer.go:647`-`650`, `:243`.
- What happens to the owner: comparisons use the monotonic reading of `time.Now` (`RealClock` in the collector,
  `internal/collector/staging.go:124`), so the rest's rule and `Resting` stay right; but if the wall clock steps
  back by more than `FullPause` during a rest and a second full error comes, the page can show "resting since
  10:00 until 09:01" (since keeps the old wall time, until takes the new one).
- What would show it: a fake clock that steps back with a wall reading only.
- Smallest fix: none needed in the store; the page may print "since" only when it is before "until".

## The older hazard (before K15; not counted): `place` looks at the staging disk with `w.mu` held
`internal/store/writer.go:476` (`w.cfg.FS.Free` inside `place`, called under `w.mu` from `create` `:571`-`:572` and
`resume` `:410`-`:411`).
- What happens to the owner: when the staging disk's free-space call hangs, the first open after a probe time
  hangs inside it with `w.mu` held, and every other `Open`, `Run`'s settle and `StagingState` wait behind it: every
  download stops, the shape of TRIED-BEFORE section 8 ("full staging blocked every download for 3 hours"). The
  same happens on any open when staging is not away (each `place` looks).
- Probe `TestK15RevPlaceHangHoldsEveryOpen` (no Run): "a second Open held while the first one's look hangs: true".
- K15 neither causes nor worsens it: with Run going, Run's look meets a hang first (in its own goroutine), and
  downloads hang one probe period later, at their own look, as today. The brief applied the right rule ("the file
  system call is made WITHOUT w.mu held") to the new probe only.
- Suggested as its own piece, not in K15: `place`'s look made outside `w.mu`, with the period claimed first as
  `probeAway` now does; the brief's own pattern carries over.

## Checked and found sound

- **No new wait for a download.** `probeAway` holds `w.mu` for field reads and the claim (`:536`-`:545`); `awayLook`
  makes `Free` without the lock and takes `w.mu` only to apply (`stagingBack`'s `Counters.add` under `w.mu`, as
  `place` does). An `Open` in a claimed period goes to the library without a look (`:473`), as it did before the
  probe time; confirmed by the coder's `TestK15ProbeHangHoldsNoOpen` and by finding 2's probe.
- **Never to staging while known away; stale answers dropped.** Every change of `away` or of its probe time moves
  `awayGen` (`:502`, `:514`, `:543`); the answer is applied only with `w.away && w.awayGen == gen` (`:555`). Mutation
  b (no `awayGen++` in `stagingAway`) is caught by "place keeps away". The bump in `stagingBack` (`:514`) is
  redundant (a new away always passes `stagingAway`) and harmless. A fresh answer is dropped only when something
  else set a newer probe or ended away, so none is lost for good (apart from finding 1's stuck flag).
- **At most one loop look at a time**, by `w.probing` under `w.mu`; mutation a is caught. A look longer than one
  period and a download's own look can run at once (two `Free` calls on the staging folder, in two periods).
- **After a stop**, the look can touch only `w.mu`, the writer's fields, the clock and the in-memory `Counters`
  (`internal/store/counters.go:151`): no catalogue, no file but the staging folder's free space, no library. Run
  itself returns at once; the collector's stop is not held.
- **`Load`** (`copier.go:1443`): no ledger call (the coder's counting ledger, read), no file system call, no
  context; `c.mu` covers `allowed()` (field reads and `Tuner.N`, a field read, `tuner.go:149`) and `busy`, the same
  size as `Away()`. `limited()` is called outside `c.mu`; the collector's `speedLimited`
  (`internal/collector/staging.go:277`) takes the collector's `c.mu`, then account and session locks, then the
  engine's stats locks (leaf `statMu`, `lane.go:3182`); none of them is held anywhere while the copier's `c.mu` is
  taken, so `Load` adds no lock order. `Gauges` calling it inside `c.mu` is older and unchanged.
- **`Written`** (`copier.go:813`-`819`): one atomic add after the existing locked add, inside `n > 0`: counted
  once per write that wrote bytes, also on a short write and on an error with n > 0. `copyBytes` (`:782`) is the
  only user of `writeTagged`, and only for the library's part, so "written to the library" is right. The tuner's
  fields, lock and order are unchanged; the coder's hand-back lists the tuner's ten tests as passing (not re-run
  here).
- **"Resting since"** (`:647`): first error starts a rest; a second inside it moves the end only; one exactly at
  the end (`now == fullUntil`) starts a new rest, consistent with `Resting = now.Before(fullUntil)`; one after it
  starts a new rest. Mutation c (since set always) is caught by `TestK15RestSinceAndUntil`. `StagingNow` and
  `StagingState` read the same fields under the same lock: they cannot disagree beyond the moment each is read.
  `StagingNow.Now` is read before the lock (as `place` does), so it can be microseconds before a "since" set
  meanwhile; not visible at the page's seconds.
- **Counts and the report.** The report's staging line (`counters.go:235`) keeps its meaning; its numbers become
  truer: "away" now ends in quiet hours, so `StagingAwayEnds` and `StagingAwayNanos` land in those hours and the
  away time is shorter. `RoomUnknown` is counted less while away (the loop claims most periods and its failed look
  is not counted, as the brief asked); it is shown in no report or page (only `writer.go:478` touches it).
- **Privacy.** No new text, log line or error; the probe goroutine carries no name or path out.
- **The coder's seven tests** pass as given (`out-probes.txt`). Each failed under its one-line mutation (a, b, c)
  except the else branch of finding 2 (d), which no test covers. None judges on real time except bounded
  `waitReal` waits that only fail when they run out; each probe test ends its look and its Run before returning.

## The four departures, judged

1. The look in its own goroutine, not waited for: accepted. It keeps Run's settle and stop free of a hung disk.
   Its costs are findings 1 and 3.
2. `awayGen` instead of comparing `nextProbe`: accepted, stricter, shown by mutation b.
3. No test of how long `Load` holds `c.mu`: accepted; by reading, field reads only.
4. "`c.copied` is never reset either": correct (`winBytes` takes snapshots, `copier.go:563`, `:1310`). A second
   count kept the tuner untouched, as the brief wanted.

## What I could not check

- **The race detector**: `go test -race` answers "-race requires cgo" (cgo off, no C compiler on this PC). The
  probe tests were not run under it; by reading, every new shared field is under `w.mu`/`c.mu` or atomic, and
  `w.probed` is set before Run starts. The race run belongs in the container before the merge (`internal/store`).
- A real staging disk that hangs or vanishes (only the fake `Free`); how Windows' free-space call behaves on a
  disconnected local disk (likely a quick error, which would make findings 1 and P rare).
- The pages' wiring of `Load` and `StagingNow` (not built). One note for it: `Load` and `Gauges` call the
  collector's `speedLimited`, which takes the collector's `c.mu`: neither may be called with that lock held.
- The tuner's ten tests were not re-run by me (the coder reports them passing; nothing they read changed).

## Where the brief is wrong or silent

- Wrong: 3(b) "when it does not, set the next probe as stagingAway does": the claim already set it; doing it
  again from the look's end stretches the period (finding 2).
- Silent: `place`'s own look under `w.mu` (the older hazard above), though the brief states the rule for the new
  probe.
- Silent: the probe goroutine sits outside the supervisor (finding 3), and what a hung look does to later "away"
  episodes (finding 1).
- "Never two probes for one period" holds; but a look longer than a period runs beside a download's own look in
  the next period. Harmless; worth one sentence in the comment.
- The page already has its own read of the staging folder that shows "back" (`internal/server/stagingverdict.go:122`),
  so part 3(b)'s value is mostly for the store's own state, the counts and the downloads' return to staging, not
  only for the page's words.
