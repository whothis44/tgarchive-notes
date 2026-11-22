# Brief E14: the engine's side of the frame check: a probe turn, and kept parts taken by the transfer (copies track, 2026-11-15)

For one Opus coder, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-engine` on branch
`wip/copies-14` (made for you from the main branch's head d1af260; change no branch). Go module in `archiver/`.
Commit work in progress as you go (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`,
messages starting `WIP copies: `, ending with a blank line and `Co-Authored-By: Claude Opus 5.5
<noreply@anthropic.com>`, no number of any real archive) and push with `git push private wip/copies-14`; never
`origin`, never the main branch, never a force-push.

**This is download-path code that runs concurrently. You change `archiver/internal/engine` only** (`types.go`,
`lane.go`, `engine.go` for the config, `counters.go`, `memsupply.go`, new test files; `check.go` only if a
line there must know a probe). It gets an independent review and the race detector after you. The design it
is one piece of: `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-COPIES-frame-check.md` (read it first; you
are E14).

## What the old app already knows (its numbers; read before the code)
Read `C:\Users\trabi\Claude\Projects\Telegram\wt-v12.32\core-service\internal\telegram\kept_parts.go` and
`parallel_download.go` lines 90 to 200 (how a download takes a kept part in place of a request), and
`...\internal\app\ix_dl_check.go` lines 1 to 200 and 380 to 632 (the check inside a download and what it
cost). Read-only: never edit or build anything there.
- Kept parts: at least 63 GB reused in 7,916 downloads; refused on reuse 0. Before them, 2.06 GB was fetched
  twice for 147 videos. A kept part "takes no place in a window and is counted apart from network bytes".
- The check inside the download (12.13 to 12.27) fetched its own parts while the file held a download slot
  and a worker, with its own retry rules: a part silent for a minute made 4 of 51 checks hit 10 minutes and
  download unchecked; 7 big videos (4.8 GB) slipped through on other failures; its part reads retried a
  timeout 20 times with no pause and were never set aside; an update could not drain. **Every one of those
  came from a second, private way of asking Telegram for parts.**
- **So here a probe's parts are asked by the lane's own code, the one way parts are asked:** the window, a
  wait slept in full with its margin by the request that got it, the timeout rule and the set-aside, the
  reference refresh, the stop. Our number beside it: none yet (not built); the lane's own numbers for a
  transfer's parts are in `archiver/docs/TRIED-BEFORE.md` section 28 and must not move.

## The state today (read first, all of it, before changing a line)
`types.go` (all: `File`, `Part`, `Transport`, `Supply`, `Sink`, `FileWriter`, `CheckSupply`); in `lane.go`:
`part`, `wop`, `xfer`, `claim` (the whole function: how a file is opened, where the exact check is decided,
`markStale`), `open`, `retire`, `writer`, `finish`, `do` (every case), `ckptDue`, `checkpointsDue`,
`checkpoint`, `diskFail`, `end`, `abandon`, `deliver`, `fill`, `pick`, `pickFrom`, `anyReady`, `fetch` (all
350 lines: the loop before a request is sent and every case after it), `handOver`, `stopSaves`, `stats`;
`check.go` (how a file leaves by `leaveHeld` and `leaveSame`); `memsupply.go` (its finishes).

## What to build

### 1. Types (`types.go`, `engine.go`, `counters.go`)
- `File.Plan []int64`: the parts to fetch in a **probe turn**: indexes of parts of `PartSize` bytes (a part's
  real offset is its index times the part size), ascending, no duplicates, each inside the file. Empty: an
  ordinary transfer (every existing caller).
- `PartStore` (the app's `internal/parts.Store` satisfies it; do not import that package):
  `Has(file int64) bool` (in memory, no I/O: it may be called with the lane's lock held),
  `Kept(file, index int64, want int) ([]byte, bool)` (a verified part of exactly `want` bytes, or false;
  disk I/O: never with the lane's lock held), `Put(ctx context.Context, file, index int64, data []byte) error`.
  `Config.Parts PartStore`; nil: none (today's engine).
- `ProbeSupply`, the Supply's side: `Probed(lane LaneID, id int64, r ProbeResult)`: the file's probe turn is
  over, the file is given back, no attempt spent (one finish per claim, as `Release`). `ProbeResult`:
  planned parts, parts kept by this turn, parts found kept already, and whether the store refused a part.
- Counters (per hour, in `Counters`, and in `LaneStats` where the others are): `ProbeTurns`, `ProbeParts` and
  `ProbeBytes` (answered by Telegram in a probe turn: they are also in `Parts` and `Bytes`, as any answered
  part), `KeptParts` and `KeptBytes` (delivered from the store: **not** in `Requests`, `Parts`, `Bytes`),
  `KeptMisses` (`Has` said yes and `Kept` said no: the part was asked of Telegram), `ProbeNotKept` (a `Put`
  failed), `ProbeRefused` (a plan the lane would not run: see 2). `internal/supply/hourly.go` copies the
  counters into the catalogue field by field: **do not edit it**; the new ones are not stored yet (a later
  piece), say so in the report.

### 2. The probe turn (`lane.go`)
A claimed file with a non-empty `Plan` and `Config.Parts` set is a probe turn.
- **Refused, with no request and no attempt spent** (`Supply.Requeue` with fixed words, counted): a plan while
  `Config.Parts` is nil or the Supply is no `ProbeSupply`; a file of unknown size (`Size <= 0`); an index
  outside the file, a duplicate, an unsorted plan, more than 64 indexes; a file with `HoldUnlessSame` (such a
  file is never probed by this piece: it keeps today's path, plan ignored, counted).
- `open`: no `Sink.Open`, no `LoadProgress`. The transfer gets a writer of the engine's own (an unexported
  `FileWriter` over the part store: `WritePart` puts one part, `Checkpoint` and `Close` do nothing), so that
  every path that closes a writer works as it is. Its planned parts are made as `part`s and put where the lane
  keeps parts to ask again (`xfer.retry`, by offset); nothing sequential is ever asked (`next` at the file's
  end); `written` stays 0.
- The exact check keeps its place: a file with `Check` is compared first (`x.check`), in the pen, exactly as
  today; "same" ends it without a probe request; after "different", "unknown" or none the probe goes on
  where a download would.
- Its reference is refreshed before its first part, as any claimed file's.
- `pickFrom`, `anyReady`, `fetch`: unchanged for it but for what follows from the above (its parts come from
  the retry list, each not before its `notBefore` and `waitUntil`; the one-part-until-proven rule applies).
  A wait, a timeout, a lost connection, a stale reference, a storm, the network away, the stop: the lane's
  own rules, untouched. Two timeouts set the file aside as they do a transfer: `Aside`, not `Probed`.
- `deliver` for a probe: the part goes to the writer goroutine as it arrives, in any order (no ordering
  buffer); when every planned part is kept or accounted for, the file is retired with a new way out,
  `leaveProbed`: the writer's queue is worked off, then `finish` (a wait still running goes on record first,
  as for any file that may be claimed again) calls `Probed`. Its file slot is free then.
- A `Put` that fails: the part is not kept (counted); **it is not a disk failure of the lane**: no write
  pause, no `WriteErrors`, no `Requeue`. Nothing more is asked for the file (requests at the server are left
  to end and their parts dropped), and it leaves by `Probed` with what was kept.
- No checkpoint, no progress row, no hand-over for a probe turn (`ckptDue`, `checkpointsDue`, `opClose`'s
  checkpoint, `handOver`): guard each. `Saved` is never called for it.
- A stop, a halt, `abandon`: as a transfer: `Release`, once. Parts kept before it stay in the store.

### 3. Kept parts in any transfer (`fetch`)
Just before a request for a part would be booked and sent (after every check of the loop: the stop, closed,
stale, the gates, the part's own wait, the window, the network away), when `Config.Parts` is set and
`Has(file)` is true: the lane's lock is given up, `Kept(file, index, want)` is asked (`want`: the length the
part must have: the part size, or the file's last part's), the lock taken again.
- Found: it is delivered as an answered part is (`deliver`; for a probe turn: counted as kept already, not
  put again), unless the file left the lane meanwhile. It is **no answer of Telegram's**: not in `Requests`,
  `Parts`, `Bytes`, the lane's speed, the window policy (`OnAnswer`), `answered`, the network's state
  (`net.sent`, `net.ended`), `retried`, and it does not make the file "proven". Counted `KeptParts`,
  `KeptBytes`. The slot it held is given back and the lane goes on (`done`).
- Not found: counted `KeptMisses`, the part is marked so that the store is not asked for it again, and the
  loop goes round once more (everything is checked afresh: the world may have changed while the lock was
  away) to the ordinary request.
- A transfer of a file with kept parts otherwise runs exactly as today: the writer gets every part in
  order; the checkpoint and resume rules are untouched.
- With `Config.Parts` nil this adds nothing but one nil test per request.

### 4. `MemSupply`
`ProbeSupply` for the tests: `Probed` gives the file back as wanted with its plan cleared, not offered before
a time the test sets; what it was told is readable.

## Tests (named; the engine's fake clock and scripted transport; no real time judged, no sleeps)
Invented bytes: a source of pseudo-random bytes per file so every delivered byte can be checked.
- `TestProbeTurnFetchesPlan`: a file of 40 parts whose last is short, plan 0, 5, 17, 39: exactly those four
  requests with their real offsets and the fixed limit; each put under its index with the source's bytes;
  `Probed` once, planned 4, kept 4; no `Sink.Open`, `LoadProgress`, `SaveProgress`, `Saved`; its slot free.
- `TestProbeThenTransferTakesKept`: then the same file without a plan: 36 requests, none for a kept index;
  the sink's file equals the source byte for byte; `KeptParts` 4; a counting policy saw 36 answers; `Requests`
  36. The same with the kept parts spread at random, 200 seeds.
- `TestKeptPartRefused`: `Has` true and `Kept` false for one index: asked of Telegram once, the store asked
  for it once, the output equal.
- `TestKeptWhileGatedOrAway`: with the lane's gate closed, or the network away, a kept part is delivered
  only when a request could have been sent (it follows the loop's rules), and nothing is booked as sent.
- `TestProbeWait`, `TestProbeTimeoutAside`, `TestProbeStaleReference`, `TestProbeStop`: a planned part told to
  wait is asked again only after the wait and its margin; two timeouts: `Aside` once, never `Probed`, the
  parts kept before stay; an expired reference mid-probe is refreshed and the plan finished; a stop
  mid-probe: `Release` once, nothing after `Wait` returns.
- `TestProbePutFails`: the second `Put` fails: no further request for the file, `Probed` with kept 1 and the
  refusal set, the lane's write pause and `WriteErrors` untouched, the next file claimed at once.
- `TestProbeRefusedPlans`: each refused case of part 2: `Requeue`, no request.
- `TestProbeAfterExactCheck`: `Check` and a plan: "same" ends in `CheckSame` with no part request;
  "different" then the probe.
- `TestProbeNoCheckpoint`: a plan of 20 parts of a file over `ResumeMin`, with the clock moved past
  `CheckpointAfter`: no `Checkpoint`, no `SaveProgress`, no hand-over offered on a wait.
- **`TestNoStoreUnchanged`**: with `Config.Parts` nil and no plan, a scripted lane (waits, a timeout, a stale
  reference, two files of each class) makes the same calls in the same order as on the base: record the
  sequence of transport requests, Supply calls and counters and compare with a recording you make from the
  base commit's engine. How: the test asserts a fixed expected trace (a digest and its length) and names no
  new field or type, so it also compiles against the base; you produce the expected trace by running that
  one test file against d1af260's engine sources with `go test -overlay` (each file you changed mapped to its
  base version, taken with `git show d1af260:<path>` into a scratch folder outside the copy; no branch
  switch, no stash, no second worktree). Say in the report how you produced it and the digest.
Mutations you must show caught (revert, run the named tests, restore): the kept part booked as an answer;
the lookup made with the lock held (a test with a store whose `Kept` calls back into the engine's `Stats`
must not deadlock); the refused-plan guards; the checkpoint guard; `Probed` called twice or beside `Release`;
a probe part put under a wrong index; the "not asked again after a miss" mark.
Run while working: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then in
`archiver/`: `GOGC=25 GOMAXPROCS=2 go test -p 1 -count=1 ./internal/engine/ -run '<names>'`. At the very end,
once: the whole `./internal/engine/` (no race detector) and `gofmt -l internal/engine`, `go vet
./internal/engine/`; write the seconds in the report. Never another package, never `go vet ./...`. The first
go command compiles everything once (the toolchain changed today). Before each go command check memory
(`powershell -c "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB"`): under 2.5 GB free, wait a
minute and look again.

## Rules (hard)
- A file without a plan, in an engine without a part store, takes every path exactly as today.
- No second way of asking Telegram for a part: a probe's parts go through `fetch` like any other. No wait is
  shortened, nothing in flight is cancelled that today's code would not cancel.
- The engine never calls the Supply, the Sink or `Kept`/`Put` with a lane's lock held (`Has` may be).
- One finish per claim: exactly one of `Probed`, `Aside`, `Gone`, `Release`, `Requeue`, `CheckSame`,
  `CheckHeld` for a probe turn, also across a stop.
- A probe never downloads the file, never calls `Saved`, never spends an attempt except where a transfer's
  set-aside would.
- No file outside `internal/engine`. Logs and errors: numbers and fixed words (the engine's existing
  messages name a file by its catalogue number; add no new kind of text). Invented data only.

## Hand-back
Commit-ready on `wip/copies-14`, pushed, the copy clean. A report `archiver/docs/progress/copies-engine-probe-REPORT.md`:
what changed per part with the functions touched, each named test, the mutations and whether each was
caught, the whole package's seconds, every departure from this brief with its reason, and what you doubt
(above all: any path where a probe transfer meets code written for a file with a real writer). Your final
message to the main session: the head commit, then at most 25 lines.
