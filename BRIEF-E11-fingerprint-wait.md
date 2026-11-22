# Brief E11: the fingerprint at save, resumed: a short wait at the copier, then the review's B2 to B8 (copies track, 2026-11-15)

For one Opus coder, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-vfp` on branch `wip/copies-11`
(made for you from the main branch's head d1af260; change no branch). Go module in `archiver/`. Commit work in
progress as you go (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, messages starting
`WIP copies: `, ending with a blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no number
of any real archive) and push with `git push private wip/copies-11`; never `origin`, never the main branch, never
a force-push. Keep `archiver/docs/progress/copies-vfp-PROGRESS.md` on the branch current (what is done, what is
next), so that another coder could take over from it.

## What this is
E10 (`private/wip/copies-10`, commit e24d390, cut from f0e3f0c; brief `BRIEF-E10-fingerprint-at-save.md` in the
project folder) built a worker that makes a saved video's fingerprint from its staged copy. Its independent
review (`C:\Users\trabi\Claude\Projects\Telegram\wt-copies-review10-scratch\REVIEW.md`, section B and F6, with
its probe tests under `vfp/`, `ffmpegB/`, `catalog/` in that folder: **read all of section B before the code**)
found it sound in its parts and useless as a whole: the copier takes a staged file in hand the moment it is
published, a hold is refused for a file in hand, so the worker loses nearly every video (B1). This brief brings
E10 onto the present head, closes B1 with a small door in the copier, and fixes B2 to B8.

## What the old app already knows (its numbers; read before the code)
Read in `C:\Users\trabi\Claude\Projects\Telegram\wt-v12.32\core-service\internal`: `app/ix_stage_process.go`
(all), `download/staging_process.go` (all) and `download/staging.go` lines 680 to 780 (`stagedDue` and its caller).
Read-only: never edit or build anything there.
- Fingerprints read back from the NAS cost 20 to 25 GB an hour of a link that copied about 20 GB an hour; since
  12.16 the staged copy is read first. 82,586 of 84,867 saved videos had a fingerprint on 11-10.
- The old mover asks a predicate for every due file (`StageDefer`): a video staged less than 90 minutes ago,
  without a fingerprint row, while the pass can run, and only with 100 GB of room on the staging disk, is
  passed over. **And: "while fewer files are due than there are copiers the oldest of them go anyway, so the
  copiers never sit idle for a check."** The old app nearly always had a staging backlog (45 to 318 GB on
  11-07 to 11-09), so videos waited behind other copies and the worker reached them.
- **Our number beside it:** the new app's copier keeps up (the test account's run: 734 files staged, copied and
  read back at once), so under the old rule alone a new video would go to an idle copier at once: B1 in the
  old app's own terms. Nothing of E10 has run beside a real copier; how many seconds of video ffmpeg
  fingerprints per second on this PC is not measured (measure it in your tests' output, on invented clips).
- So the old way is kept (a predicate asked by the copier for each due file; bounded; only with room; only
  while the worker can run; downloads never wait), and one thing is changed because the copier here is idle
  where the old one was not: **a staged file is "not yet due" only until the worker has looked at it, never
  for the worker's whole queue.** The worker then holds at most `Holds` (8) videos in its line, as E10 built;
  every other file goes to the copier at once. If ffmpeg is slower than the downloads, the line stays full
  and the rest are copied without a fingerprint (counted), instead of every video waiting 90 minutes.

## What to build

### 0. Bring E10 onto this branch (no collector file)
From e24d390 take `internal/catalog/vfp.go` and `vfp_test.go`, `internal/vfp/*`, and the two progress files
under `archiver/docs/progress` (`git checkout private/wip/copies-10 -- <paths>`). **Take nothing of
`internal/collector`** (see part 4). `internal/footage/ffmpeg` changed on the main branch since (the review's F1
to F7 are fixed there: a start failure is `ErrCannotStart`, a frame cap, format whitelist): keep the main
branch's files and add E10's thread bound for `Fingerprint` again on top (`DefaultFingerprintThreads`, its test),
**passed in both cases, with and without a GPU decoder (B8)**. Make it build and E10's own tests pass first.

### 1. The door in the copier (`internal/store/copier.go`; the Core track's package, lent for these lines only)
Two fields in `CopierConfig` and their use in `due`; nothing else in the package changes.
- `NotYet func(q Queued) bool`: asked, outside `c.mu`, for each **copy** (state `QueueCopy`, never a check) that
  `DueCopies` returned, before it is handed to a copier. True: the file is left out of this look.
  nil: never asked (every existing test and caller behaves bit for bit as before: prove it).
- `NotYetMax time.Duration` (default 2 minutes): **the copier's own bound.** A file whose `StagedAt` is 0, in the
  future, or `NotYetMax` or more ago is never asked about: whatever the predicate says, no file waits longer.
- A file left out is passed over, not cut: the look goes on to later due files so free copiers are filled
  (ask `DueCopies` again with the left-out ids added to `skip`; at most 3 asks a look). It does not count as
  "copies waiting" (`waiting`, `backlog`: `CopiesWaiting` and `LibraryRead` must not report a wait because of
  it), and the feeder's ordinary poll (`PollEvery`) looks again; nothing is written to the ledger for it and
  no try is spent.
- A predicate that panics is treated as false, counted, and never asked again in that run.
- One counter per hour in `Counters` (`NotYet`: files left out, each look counted) and its figure in
  `store.Report`'s lines (numbers and fixed words).
- A file under a reader's hold is handled as today (`copyOne`: put off, `LaterReading`): do not change it.

### 2. The worker (`internal/vfp`)
- `Worker.NotYet(q store.Queued) bool`, for `CopierConfig.NotYet`: true only when all hold: `Run` is alive and
  its last turn began at most `2 x Tick` ago; ffmpeg is found and passed its self-test; the staging disk had
  room at the last look; the line has a free place (`len(holds) < Holds`); the file was staged less than
  `Grace` ago (a new `Config.Grace`, default 30 s); and the worker has **not yet read a list since the file
  was staged** (keep the time each list read began; a file staged before it is known: it is either in the
  line, held, or not this worker's, so false). No I/O and no catalogue read in it; it must be safe from any
  goroutine (atomics or `w.mu`), and cheap (measure: it is called per due file per look).
- `Worker.Kick()`: a file was staged (the collector will call it from the writer's publish hook, beside
  `Copier.Kick`). It wakes `Run` at once: the list is read, holds taken. While a video is being read (`read`),
  a kick or a tick reads the list again and brings the line up to date (today `read` keeps the list it
  started with for the whole read, up to an hour).
- The review's findings, each with a named test that fails before the fix (the reviewer's probes are in the
  scratch folder: turn them into tests): **B2** (an ffmpeg that cannot start records nothing and counts as
  "no ffmpeg"; `SelfTest` once per runner found, and again after 3 failure rows `ffmpeg` or `no-frames` in a
  row, nothing recorded until it passes); **B3** (a file staged less than a minute ago whose copy is not there
  yet is looked at again at the next tick, not counted gone, not passed over 10 minutes); **B4** (the time is
  taken again after a read; a file whose record fails 3 times is given up until the next start, counted);
  **B5** (the "ffmpeg is gone" path returns `Retry`, counts a look, and the fake clock fires a wait of 0);
  **B6** (the list is asked for with the passed-over ids left out, or with a longer look-ahead when a whole
  list was passed over: 64 unreadable rows must not block the 65th); **B7** (the read has a context of its
  own; `Run`'s way out cancels it and waits for the helper before any hold is let go; the helper recovers a
  panic into an error; after a restart never two reads); **B8** (above, part 0).
- Not in this round, say so in the report: B9 (an index for the staged-videos door is a schema step; today's
  cost is 70 ms at 50,000 queued), B10 (the one-hour limit per attempt), B11, B12 (candidates by length come
  with the frame check piece).

### 3. Proof that B1 is closed: a test with the real copier
In `internal/vfp` (or a small `_test` package that imports both): a real `store.Copier` on `store.MemLedger`
and a temp staging and library folder, the worker with a fake runner, `NotYet` and `Kick` wired as the
collector will wire them, the fake clock where the copier's tests use one. (a) Videos staged one after another
while the copier has free slots and the runner keeps up: every one is fingerprinted before it is copied, none
waits longer than its read. (b) A runner slower than the arrivals with `Holds` 2: never more than 2 held, every
other video is copied at once, none waits `Grace` or more unless held. (c) No worker running, no ffmpeg, no
room, or a worker that stops turning (stalled inside a step): no file waits at all after `2 x Tick`. (d) A
photo (a staged file the list never shows): its wait ends at the worker's next list read; with a kick, within
the same test step. (e) A predicate that always says true: every file is copied after `NotYetMax`. Mutations
you must show caught (revert each, run the named tests, restore): the copier's own bound; "passed over, not
cut"; the list-read time compared with the staged time; the alive test; the line-full test.

### 4. The collector's lines: written down, NOT built
`internal/collector` is being changed by three waiting branches and is closed to this piece until they are
merged. Write `archiver/docs/progress/copies-vfp-COLLECTOR.md`: the exact lines for later (E10's lines in
`collector.go`, `command.go`, `staging.go` and its `fingerprints.go`, read them with `git show
private/wip/copies-10:archiver/internal/collector/fingerprints.go` and `git diff f0e3f0c private/wip/copies-10 --
archiver/internal/collector`; plus `NotYet` given to the copier, which is made before the worker today, so say
how; `Worker.Kick` beside `Copier.Kick` at the writer's publish hook; the self-test). Do not create or edit any
file under `internal/collector` or `cmd/`.

## Tests while working (named only; invented data; the PC is shared)
`source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then in `archiver/`:
`GOGC=25 GOMAXPROCS=2 go test -p 1 -count=1 ./internal/vfp/` (the whole small package is fine),
`./internal/store/ -run '<your new tests and the copier tests that touch due>'`,
`./internal/catalog/ -run 'VideoFingerprint|StagedVideos|VideoCandidates'`,
`./internal/footage/ffmpeg/ -run '<the thread bound's test>'` with
`FFMPEG_PATH` set to the ffmpeg 9.0.2 build (find it with `where.exe ffmpeg` in PowerShell; the WinGet one; if
you cannot tell which is 9.0.2 run each with `-version`). **Never** the whole `internal/catalog`,
`internal/store` or `internal/collector`, no race detector, no `go vet ./...`: the full runs are the main
session's, once, after the review. The first go command compiles everything once (the toolchain changed
today): let it. Before each go command check memory (`powershell -c "(Get-CimInstance
Win32_OperatingSystem).FreePhysicalMemory/1MB"`): under 2.5 GB free, wait a minute and look again.
No test judges real time (no sleeps of a few ms that must be "enough"): the fake clock, or wait on a condition.

## Rules (hard)
- Nothing here may make a download wait, fail a save, or keep a staged file from the copier beyond the bounds
  written above. The copier's bound is its own and does not trust the predicate.
- The library is never read by this piece. No Telegram request. No file under `internal/collector`, `cmd/`,
  `internal/engine`, `internal/supply`; in `internal/store` only `copier.go`, `counters.go` (and the report
  lines), and tests. No schema step, no new table, no new index.
- Logs, counts, errors and test data: numbers and fixed words only; never a name, a path, an id in a log
  line; `logf` formats are constants. Invented data only in tests; nothing of a real archive anywhere.
- Never open, read or list anything under `E:\`, the owner's library, or any real catalogue.

## Hand-back
Commit-ready on `wip/copies-11`, pushed, the copy clean. A report `archiver/docs/progress/copies-vfp2-REPORT.md`:
what you built per part, each named test and what it proves, the mutations and whether each was caught, the
measured seconds of video per second of fingerprinting on the invented clips and the cost of `NotYet` per
call, every departure from this brief with its reason, and what you doubt. Your final message to the main
session: the head commit, then at most 25 lines: what is done, what is not, departures, doubts.
