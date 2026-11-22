# Brief E18: the collector's lines for the fingerprint worker and the frame check (copies, session C4, 11-16)

**For an Opus 5.5 coder at high effort. First rule (the owner, 11-16): routine steps are not yours to repeat call by
call. You write code and run only the named tests of what you changed; the whole runs, the race detector, vet over
packages and the merge of the head are done once, later, by a clerk of the main session.**

- Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-18`, branch `wip/copies-18`, cut from the main head
  dbca91d4. Work only there. Go: `. /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in the Bash
  tool, then `cd` to the copy's `archiver`. For tests that need ffmpeg: `FFMPEG_PATH` set to the second line of
  `where.exe ffmpeg` (this PC's PATH hides it from Go).
- Commit as you go: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push with `git push private wip/copies-18` after each
  commit. Never push or touch any other branch; never merge; never tag.
- Nothing runs against Telegram. Invented data only. No log line, test name, comment or report may carry a real
  name, text, path, id or link; every new log call has a constant format string and prints counts, sizes, timings
  and fixed words only (an error goes through `errWord`, never `%v` of an error that may hold a path:
  `parts.Open`'s error may hold one).
- Nothing in product code may depend on this PC's absolute paths, the folder the program is started from, PATH or
  the start scripts (the app becomes one `.exe` with its folder).
- A text with a Windows path goes into a file with the Write or Edit tool, never through a shell string.

## 0. What the old app already knows (its numbers; read by the main session in full: TRIED-BEFORE 6, 17, 21, 27, COPY-CHECKS-STUDY E, answers 4, 5, 8)

- **The check as the first step of a video's own download is the right shape, and what broke it in the old app was
  holding a download slot while waiting on Telegram** (12.13 to 12.27): 4 of 51 checks timed out and the videos
  were downloaded unchecked, 7 big videos (4.8 GB) slipped through on other failures, an update could not drain.
  The new design (merged: C8, C10) fetches a check's parts on the lane as counted requests, frees the slot, and
  judges from local parts only. **This piece adds no mechanism: it only switches on what is merged.** Anything
  here that would make a lane, a slot, a finish or the copier wait on ffmpeg, on the judge or on the part store is
  a defect.
- The old app's check, in its download: 8 parts a check at the median; 10 to 22 s added per check in hours without
  the speed limit, 3 to 14 minutes under it (about half timed out). Checks of videos nothing held confirmed 10 to
  25%. Its "copy" was right in 184 of 188 judged after download; its "no match" against a named file was wrong
  about 3 times in 4 (882 of 1,140): **a "no match" never releases a held file, and only exact evidence skips.**
  Nothing in this piece may change what a verdict does.
- A rule that paused the old app's background checks for 10 minutes after any plain wait gave 0 checks in some
  hours (30 to 64 plain waits an hour). **The judge's and the worker's tasks are tied to no wait of Telegram's.**
- Kept parts in the old app: at least 63 GB reused in 7,916 downloads, none refused on reuse; lost on a timeout
  (12.25) and on a drain (12.27). Its sweep ran every 10 minutes. Its cap was 100 GB because videos were downloaded
  a median 23 to 55 hours after a background check; here the transfer follows the verdict, so the store's default
  of 20 GB stands.
- Fingerprints of saved videos: reading them back from the NAS took 20 to 25 GB an hour of the Wi-Fi link; since
  12.16 the old app reads the local staged copy, with bounded waits so that copies never idle. **Nothing started
  by this piece reads the library folder.** The card did the fingerprints (the CPU when it fails: one broken
  upload once switched the whole index to the CPU, fixed in 12.13: merged here as C11's rule of 3 files); the CPU
  did a check's frames.
- The old app ran up to 10 checks with 2 ffmpeg processes each, sized for download slots. Here: 2 judge workers
  (1 to 4), 16 checks in flight (the owner, 11-16).

## 1. What this piece is

Two groups of lines in the collector, **each off unless its flag is set, and with both flags off the program's
path bit for bit as today** (no task started, no folder made, no new field of another package's config set, no new
call of the catalogue except the one named in 3.6).

Files you may touch, and nothing else:
- `internal/collector`: `collector.go`, `staging.go`, `account.go` (only inside `startEngine`), `command.go`; new
  files `fingerprints.go`, `fingerprints_test.go`, `framecheck.go`, `framecheck_test.go`. Core lends these files
  for this one branch; Core's and the pages' coders are working in `click_api.go`, `pages*.go`, `livepages`,
  `reader.go` and the store's writer: **do not touch those**, and keep your edits in the lent files to the fewest
  lines (new code goes into your two new files; the lent files get calls and fields).
- `internal/supply` (ours): `Config.Saved` (2.4).
- `internal/parts` (ours): `Store.Shut` (3.5).
- `archiver/docs/progress/copies-collector-lines-REPORT.md` (your report) and a `-PROGRESS.md` beside it kept
  current as you go.
- No schema step. No change in `internal/catalog`, `internal/engine`, `internal/store`, `internal/probejudge`,
  `internal/vfp`, `internal/footage`. If you find you need one, stop and say so in the progress file: do not make
  it.

Read first, in the copy: `archiver/docs/progress/copies-vfp-COLLECTOR.md` (group 1, line by line),
`copies-probe-judge-REPORT.md` section "What the collector's lines need", `copies-probe-catalogue-REPORT.md`
sections "What the collector's lines need" and "The collector's two calls", `copies-gpu-decoder-REPORT.md` section
"The collector's flags", `copies-engine-probe-REPORT.md` (its last bullet), then `Run` in `collector.go` whole,
`newStaging` and `logStoreHour` in `staging.go`, `startEngine` and `stopEngine` in `account.go`, the flag block of
`command.go`. E10's worker file and test: `git show private/wip/copies-10:archiver/internal/collector/fingerprints.go`
and `.../fingerprints_test.go`.

## 2. Group 1: the fingerprint worker (`-fingerprints`)

Build it as `copies-vfp-COLLECTOR.md` says, with these changes (where the note and this brief differ, this brief
wins):

1. **`-fingerprints` is false by default** (the note says true). `Config.Fingerprints`, `Config.FingerprintHWAccel`.
2. **`-fingerprint-hwaccel` defaults to `auto`** (C11: the first card decoder that passes its self-test, else the
   CPU; `cpu` or a card word by hand; checked with `vfp.ValidHWAccel`, refused with `ExitRefused` otherwise). Help
   text as `copies-gpu-decoder-REPORT.md` gives it.
3. **The finder**: both this worker's runner and the judge's are made with the owner's `-ffmpeg` (a new flag, a
   path, empty by default, into `ffmpeg.Config.Path`) and `-card-decoders` (a new flag, default `cuda,d3d11va`, a
   comma list of card words each checked with `ffmpeg.ValidDecoder`, into `ffmpeg.Config.Decoders`). With
   `-ffmpeg` empty the package's own order applies (the `tools` folder beside the program, `FFMPEG_PATH`, PATH).
   The start's log line says where ffmpeg was found with `Runner.Where()` (fixed words), never a path.
4. **`supply.Config.Saved func(fileID int64, revived bool)`** (the note's section 6, way 1): nil by default and then
   nothing changes; set, it is called after a save with `res.FileID, res.Revived` at the two places where `res`
   comes fresh from `saveOnce` (not on the retry path that rebuilds `res` from `SavedAs`: there the flag is not
   known; say so in the report). It is called with none of the Supply's locks held and must not be able to block a
   finish: the collector's closure only calls `fp.Staged(id, true)` when `revived` and the worker is on. A test in
   `internal/supply` by name for both places and for nil.
5. `NotYet` is passed to the copier's config only when `-fingerprints` is set; the writer's `Kick` closure is the
   present one, unchanged, when it is not.
6. `logStoreHour`: the worker's `Stats().Report()` lines only when the worker exists.
7. `fingerprints_test.go`: E10's test with the note's two changes (section 5), plus `TestFingerprintsOffAsToday`:
   with the flag off no worker is made, the copier's config has no `NotYet`, no task named "fingerprints" starts.

## 3. Group 2: the frame check (`-frame-check`)

New code in `framecheck.go`; the lent files get the calls.

1. **Flags** (`command.go`), all read into `Config` fields:
   - `-frame-check` (bool, false): a video with a saved look-alike candidate is checked by sampled frames as the
     first step of its own download.
   - `-check-hwaccel` (word, default `cpu`: the owner's choice of 11-16; `auto` or a card word by hand;
     `ffmpeg.ValidDecoder`), into `ffmpeg.Config.SampleHWAccel` of the judge's runner.
   - `-check-workers` (1 to 4, default 2; anything else refused), into `probejudge.Config.Workers`.
   - `-parts-cap-gb` (1 to 1024, default 20), into `parts.Config.Cap`.
   - `-parts-dir` (a folder, empty by default): see 3.2.
   - No flag for the floor of file sizes: it is the catalogue's stored setting (`catalog.ProbeFloor`) and gets its
     control with the settings rows, a later piece.
   - With `-frame-check` set and `-fingerprints` not set, one log line at the start with fixed words: saved videos
     get no fingerprint in this run, so the check compares only with fingerprints already stored.
2. **The part store's folder.** Default: a folder of its own beside the staging folder, never inside it: the
   staging folder's absolute path with `-parts` added to its last name (same parent). `-parts-dir` names another.
   Refused at the start with fixed words (nothing started, as a staging folder that cannot be set up is refused
   today), when: the folder is the staging folder or the library folder, or inside either, or either is inside it
   (compare cleaned absolute paths, case-insensitively on Windows, as `samePath` does); the staging folder is a
   drive's root and `-parts-dir` is empty; the folder cannot be made; `parts.Open` fails. The folder is this
   catalogue's alone: give it the same mark the staging folder has (`stagingmark.go`: `readMark`, `writeMark`,
   `catalogueID`; reuse them through one small helper, do not copy them), and refuse another catalogue's folder.
   Made only when `-frame-check` is set.
3. **In `Run`**, with the flag set, after the staging is set up and before `supply.New`: open the store
   (`parts.Open` with `Ledger: partsledger.New(cat)`, the cap, the wall clock), make the judge
   (`probejudge.New` with `Catalog: cat`, `Parts: probejudge.Parts(store)`, `Find` making an `ffmpeg.New` runner
   with the path, `SampleHWAccel` and `Decoders`, `Workers`, `Logf: c.logf`; `Mode` nil), and give the Supply
   `FrameCheck: judge.Ready` and `FrameCheckDownSince: judge.DownSince` (other new fields of `supply.Config` stay
   at their defaults). With the flag off none of the four exists and `supply.Config` is today's literal.
   A seam for tests: `Config` gets one field through which a test supplies the judge's `Find` (as `WrapSupply`,
   `Hasher` and `FS` are seams today); nil: the real ffmpeg runner.
4. **The tasks**, on the store's context beside the writer and the copier (`c.supv.Go(storeCtx, ..., &storeWG, ...)`),
   so they stop after every engine has returned and before the Supply and the catalogue close:
   - `"frame-check"`: `judge.Run(ctx)`.
   - `"kept parts"`: at once and then every 10 minutes by the collector's clock (`Clock.Sleep`): `store.Sweep(ctx,
     ledger.Needs)`, then `cat.ProbeCloseLeft(ctx)`. A failure of either is counted by kind and logged with fixed
     words at most once an hour; the task goes on at its next turn; it never ends the run.
   - **Check and say in the report, with a named test each:** (a) that `Judge.Run` called a second time on the
     same context after a panic (the supervisor does that) is safe, as E11 made the worker's `Run`; if it is not,
     stop and say so (the fix would be in `internal/probejudge`); (b) that after the store's context ends
     `Judge.Run` returns within the store's stop grace (`Store.StopGrace`, 10 s by default) also while an ffmpeg
     process of a check is running (a fake runner that blocks until its context ends); (c) that the sweep's task
     returns within that grace in the middle of a sweep.
5. **The stop.** The engine's report says an abandoned probe writer may still be inside one `Put` for up to the
   put's timeout (10 s) after `Engine.Wait` returned, so the catalogue (the store's ledger) must not close under
   it. Do it with a bound and no fixed sleep: **`parts.Store` gains `Shut(wait time.Duration) (left int)`**: from
   the call on no `Put` begins (it is refused with a fixed error, nothing written, counted) and no ledger write of
   the store begins; it waits for puts and ledger writes in flight, at most `wait`; it answers how many were still
   in flight at the end. `Kept` after `Shut` answers "not kept" without a ledger read. Idempotent. In `Run`'s stop,
   after the store's tasks have been waited for and before `endSupply` and `closeStore`: `Shut(10 s)`; when
   `left` is above 0 one log line with the count. With nothing in flight it costs no time: a stop is not made
   longer for it. Tests by name in `internal/parts`: a put in flight delays `Shut` until it ends; a put stuck past
   the bound returns `left` 1 at the bound; a put after `Shut` is refused and writes neither a file nor a row;
   `Shut` twice.
6. **A start with the frame check off:** `cat.ProbeCloseAll(ctx, catalog.ProbeWhySwitchedOff)` once, after the
   recovery and the staging sweep and before any account's task, tried again as the recovery above it is (doubling
   to a minute, ended by the stop), its count logged when above 0. This is the one new catalogue call a run with
   both flags off makes; with no open row it changes nothing (check that it writes nothing then, and say so).
7. **`startEngine`** (`account.go`): `ecfg.Parts` is the store only when the frame check is on and the engine's
   part size is `engine.KeptPartSize` (the engine refuses a part store at any other size, and an account must
   never fail to start an engine because of the frame check). At another part size: no part store for that
   engine, one log line with fixed words per engine start, and the Supply's own handling of a plan a lane will not
   run applies (`ProbeLaneRefused`). A named test: such an engine downloads its files and no file is handed out
   in a loop. One reading of the store under `c.mu`, as the writer and the copier are read there.
8. **The hourly lines** (`logStoreHour`): the part store's `Stats().Report()`, the judge's `Stats().Report()`, and
   each runner's `Counts().Report()` where the runner can be reached without a new door (if it cannot, leave the
   runners' lines out and say so). Only when the frame check is on.
9. **Nothing else changes for a file.** No verdict's effect, no bound, no setting of the judge or the Supply
   beyond the fields named in 3.3.

## 4. Tests (by name, in `framecheck_test.go` unless said; the collector's fake Telegram and its rigs; invented clips only)

- `TestFlagsOffAsToday`: both flags off: no task named "fingerprints", "frame-check" or "kept parts"; no parts
  folder made; `supply.Config.FrameCheck` nil and the engine's `Parts` nil (through a seam or by behaviour: say
  which); the copier's `NotYet` nil; and the existing end-to-end tests you name pass unchanged (name at least
  `e2e_store_test.go`'s and `kill_test.go`'s main cases and run them).
- `TestFrameCheckOnEndToEnd`: a saved invented video with a fingerprint; a re-encode of it comes: its parts are
  fetched, the judge (a fake runner through the seam, or the real ffmpeg when `FFMPEG_PATH` is set: then both)
  says "copy", **the file is held with its evidence and is never skipped and never downloaded**; an unrelated
  video of the same length is judged "no match" and downloaded, **its kept parts taken in place of requests** (the
  requests of its transfer are fewer by exactly the kept parts; counted apart). A held file is still held after
  every later word.
- `TestFrameCheckOffClosesOpenRows` (3.6); `TestKeptPartsTask` (a fake clock: the sweep and `ProbeCloseLeft` run
  at the start and after 10 minutes; a failing sweep does not end the task); `TestStopShutsPartStore` (3.5: a put
  held by a hook delays the catalogue's close until it ends, at most the bound; the stop's order as written);
  `TestEngineOtherPartSize` (3.7); `TestPartsDirRefused` (each case of 3.2) and `TestPartsDirMarked`;
  `TestFrameCheckRestart` (a stop in the middle of a check's fetch and one while a file waits for its judge: after
  the restart the check ends with no part fetched twice).
- The tests of 3.4 (a), (b), (c), 2.4 and 2.7.
- While working run only these and the tests you touch, by name (`-run`), with `-count=1`. **Do not run the whole
  `internal/collector` (15 minutes), `internal/catalog` or `internal/supply`, do not run `go vet` over packages,
  do not use the race detector.** `gofmt -l` on the files you changed and `go build ./...` at the end are yours.
  Before a test run look at the PC: with less than 2 GB of memory free, or the CPU above 80% over a few seconds,
  wait a minute and look again, at most 10 times; then run anyway with `GOMAXPROCS=2`.

## 5. Bounds (every wait here has one; if you add a wait, give it one and list it in the report)

| Wait | Bound |
|---|---|
| The store's `Shut` at the stop | 10 s, then the stop goes on and the count is logged |
| The store's tasks at the stop | the store's stop grace, as the writer and the copier today |
| `ProbeCloseAll` at a start | tried again doubling to a minute; ended by the stop (as the recovery) |
| The sweep's turn | every 10 minutes; a failed turn waits for the next |
| A file waiting for its judge, a check with no answer, an ffmpeg outage | the Supply's and the judge's merged bounds, untouched |

## 6. Hand-back

A report `archiver/docs/progress/copies-collector-lines-REPORT.md`: what was built, per numbered point above; every
file touched, with the count of lines changed in each lent file; test functions removed (none expected: say
"none" or list them); each named test and what it fails on when its rule is broken on purpose (break it once,
see it fail, restore: say so per test); what you could not verify; every doubt, above all about a rule of this
brief that looks wrong to you (the last piece's defects were mostly the brief's own rules: say so plainly rather
than build a rule you think is wrong). Everything committed and pushed on `wip/copies-18`; the copy clean. Your
last message: the head's short hash, the tests run with their seconds, and the doubts in a few lines.
