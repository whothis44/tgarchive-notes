# Brief E15: the catalogue's side of the frame check: its tables and doors, the part store's ledger on the catalogue, the supply's decision at `Next` (copies track, session C3, 2026-11-15)

For one Opus coder at high effort, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-15` on branch
`wip/copies-15` (made for you: the main head 4daa0309 with `wip/copies-11` and `wip/copies-12` merged in, both
clean; change no branch, merge nothing). Go module in `archiver/`. Commit work in progress as you go
(`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, messages starting `WIP copies: `, ending
with a blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no number of any real archive)
and push with `git push private wip/copies-15`; never `origin`, never the main branch, never a force-push.
Commit and push after each of the three parts below at the latest: the session that briefs you can end at any
moment and another must be able to carry on from the branch and your report.

**You change:** `archiver/internal/catalog` (new files `schema_probe.go`, `probe.go`, `parts_ledger.go` and their
tests; in existing files only: `catalog.go`'s `SchemaVersion` line, one line of the steps' table and the two
lines of `migrate`'s switch; `vfp.go`'s `VideoCandidates` and its statements; the hourly columns where
`HourlyDelta` lives), a new package `archiver/internal/partsledger`, and `archiver/internal/supply`
(`supply.go`, `pending.go`, `hourly.go`, a new `probe.go`, tests). **You touch nothing else:** not
`internal/engine`, `internal/parts`, `internal/collector`, `internal/server`, `internal/viewer`, `cmd/`, nor
any other file of `internal/catalog` (`chosen.go`, `settle.go`, `state.go`, `ladder.go`, `topics.go` are other
tracks' or settled; if a rule cannot be built without one of them, stop and say so in your report's first
lines). The supply is download-path code that runs concurrently: after you it gets an independent read-only
review with probes and the race detector. The judge (ffmpeg over kept parts) is the next piece, E16: you build
the doors it will call and none of it.

The design this is one piece of: `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-COPIES-frame-check.md` (read
it first; you are E15). Where this brief and the design differ, the brief wins and says why.

## What the old app already knows (its numbers; read before the code)
Read, read-only (never edit or build there): `C:\Users\trabi\Claude\Projects\Telegram\wt-v12.31\core-service\internal\app\ix_dl_check.go`
(all: which videos are checked, lines 286 to 361; the put-back bounds, lines 71 to 187 and 468 to 500),
`ix_part_store.go` (all: the rows, the trust rule, the sweep's "still queued" question, lines 349 to 419) and
`ix_copies_sample.go` lines 163 to 229 (why a check failed, which reasons are final) and 863 to 891 (the
candidates). And in `archiver/docs`: `COPY-CHECKS-STUDY.md` sections B.1, C and E; `TRIED-BEFORE.md` section 6.
- **A frame check's "copy" was right in 184 of 188** judged after download. **Its "no match" against a named
  file was wrong about 3 times in 4** (882 of 1,140). So here: "copy" holds a file; "no match" and "partly"
  never release a held file and never end anything by themselves.
- **Checked videos that nothing had held are copies 10 to 25% of the time (copies average 360 MB); a check
  costs 8 parts at the median** (cap 32), and those parts were reused: at least 63 GB in 7,916 downloads,
  0 refused on reuse. Before parts were kept, 2.06 GB was fetched twice for 147 videos.
- **Every incident from 12.25 to 12.27 was a check that had no answer being taken for an answer:** 4 of 51
  checks timed out and their videos downloaded unchecked; 7 big videos (4.8 GB) went through on other
  failures ("a critical error", the owner). The old app's answer, kept here number for number: a check with
  no answer puts the file back, 15 minutes when the try read new parts, 1 hour when it read none; after 24
  hours of that (a gap of 6 hours without one starts the count again) or 3 identical ffmpeg failures with no
  new part it downloads, **counted, with its reason on record**; a failure in the file itself (no index,
  cannot seek, bad data, too few frames, over the parts cap, 27 of 27,051 checks) downloads at once, counted.
- **Which videos:** 20 MB or more (the old in-download floor, a setting 20 to 4,096 MB), with a length, never
  one that has a partial download, when a saved video with a fingerprint is 20% shorter to 20% longer **by
  the fingerprint's own length** (`ix_vfp.duration`, ffmpeg's seconds), closest first, at most 300.
- **Kept parts' rows:** one per part (file, index, bytes, SHA-256, when); a part is read back only with its
  row's length and hash; rows go when the file is downloaded or no longer queued; the oldest go first over
  the cap or under the free-space floor. That store is built and merged (`internal/parts`); it has only an
  in-memory ledger: yours is the real one.
- Our numbers beside these: none yet (nothing of the frame check has run). `internal/footage/mp4index`
  predicted the parts of 201 of 201 invented clips.

## The state today (read first, all of it, before changing a line)
- `internal/parts`: `ledger.go` (the `Ledger` you implement, `Row`, `FileSum`), `sweep.go` (`Sweep`'s `needs`
  and what a failure of it does), `parts.go` `Open`, `Put`, `Kept`, `Remove` (when each calls the ledger).
- `internal/engine/types.go` lines 60 to 176: `File.Plan`, `MaxProbePlan`, `KeptPartSize`, the `ReasonProbe...`
  words and `IsProbeRefusal`, `PartStore`, `ProbeResult`, `ProbeSupply`; `counters.go` `ProbeCounters` and
  `Bucket.Probe`; `memsupply.go` `Probed` (what the in-memory supply does with a probe turn's end).
- `internal/supply`: `supply.go` (all: above all `Next`, every line, with `checkpen.go`; `Requeue`;
  `heldWaits`), `pending.go` (all: how a finish is retried until recorded, which kinds are in the finish
  log and why `pendSame` and `pendHeld` are not), `hourly.go`.
- `internal/catalog`: `exactcheck.go` (`CheckLater`: how a claimed file is given back until a time with no
  attempt spent; `HoldExact`, `HoldLookAlike`, `HoldCheckFirst`: how a hold and its edge are written;
  `guardedBy`), `state.go` (`ClaimWith`, `Release`, `Aside`, the requeue of set-aside files, `RecoverActive`),
  `lane.go` `LaneNext`, `vfp.go` (all), `schema_mirrorname.go` and `schema_protected.go` (how a step is
  written: its two constants, the step refused at any other version, columns added only when missing),
  `catalog.go` lines 300 to 320 and 500 to 590, and `internal/storeledger/storeledger.go` (the adapter
  pattern and its error type: yours follows it).

## Part A: schema step 21 and the catalogue's doors
**The step** (`schema_probe.go`): `probeSchema = probeAfter + 1`, `probeAfter = mirrorNameSchema`
(the number, 21, is written nowhere else: a step's number is the order of its merge and the integrator may
move it); `SchemaVersion = probeSchema`; refused at any other version; idempotent (tables and indexes
`IF NOT EXISTS`, columns only when missing). It makes:
1. `c_part(tg_media_id INT NOT NULL REFERENCES tg_media(id) ON DELETE CASCADE, idx INT NOT NULL, bytes INT NOT
   NULL, sha256 BLOB NOT NULL, at INT NOT NULL, PRIMARY KEY(tg_media_id, idx))`: a kept part's row. The
   reference is required (entry C8: parts are keyed by the catalogue's number and the store trusts nothing
   but the row). Foreign keys are on in this catalogue: a test deletes a `tg_media` row and finds its parts'
   rows gone, and another shows a put for a number the catalogue does not hold fails and writes nothing.
2. `c_probe`: one row per file that had a probe turn or a judge's word: `tg_media_id` (primary key, the
   same reference and cascade), `phase` (`fetch`: a plan waits to be fetched; `judge`: its parts are in and
   a judge's answer is awaited; `done`), `plan` (the part indexes the judge asked for next, as JSON),
   `rounds`, `parts_fetched`, `last_new_parts` (what the last round newly kept), `result` (`''` while open;
   `copy`, `partly`, `nomatch`, `unchecked`), `why` (a category, fixed words only: `flood`, `timeout`,
   `no-ffmpeg`, `ffmpeg`, `ffmpeg-io`, `no-answer`, `not-kept`, `parts-missing`, `lane-refused`, and the
   final ones `no-index`, `cannot-seek`, `bad-data`, `few-frames`, `parts-cap`), `hits`, `samples`,
   `offset_ms`, `of_file` (the saved file, nullable), `frames` (the sampled frames, the old packing, kept to
   compare again), `tries`, `same_fails` (identical ffmpeg failures in a row with no new part),
   `first_unknown_at`, `last_unknown_at`, `judge_by` (when a file in phase `judge` comes back by itself),
   `at`. An index for the judge's list (`phase = 'judge'`, oldest first).
3. **Saved videos with a fingerprint, by the fingerprint's own length** (the review's B12: today
   `VideoCandidates` finds only videos that have a preview hash). Recommended: a partial expression index on
   `fingerprint` over `json_extract(meta, '$.duration_s')` for rows of kind `video`, model `''`, seq 0 with
   frames (`length(data) > 0`), carrying `ver` and `file_id`. Show with `EXPLAIN QUERY PLAN` in a named test
   that both reads below use it. If SQLite will not use it as needed, a small table kept by
   `PutVideoFingerprint` and filled by the step is the fallback: say which and why in the report. Measure the
   step on 100,000 invented fingerprint rows and write its seconds in the report (the brought-in old archive
   has about 82,000; the step runs in one transaction under the one writer).
4. The eight `ProbeCounters` fields as columns of `c_hourly` (added only when missing).

**The doors** (`probe.go`, `parts_ledger.go`; names are a proposal, keep them unless one clashes, and list the
final ones in the report). Every write is one transaction; every error is typed or one of the catalogue's
sentinels, never text to be matched; nothing here logs or returns a path, a name or an id in an error's text.
- The ledger's five: put a part's row (replacing), a file's rows by index, every file with its sums, remove
  one row, remove a file's rows. And **`PartsNeeded(ctx, files) (map[int64]bool, error)`** for the store's
  sweep: a file's parts are still needed while its `c_want` state is `wanted`, `active` or `aside`; not when
  it is `held`, `gone`, `skipped`, saved, or has no row. One test per state, named for it.
- **`VideoCandidates`** (in `vfp.go`, signature kept): the same answer as now, but walked on the new index,
  by the fingerprint's own length, 20% shorter to 20% longer, closest first, the file `first` first whatever
  its length, at most `limit`; only files whose bytes the archive has (location library or staging: a lost
  file is never a candidate). `VideoCandidate.DurationMs` becomes the fingerprint's length; say so in its
  comment. Its existing tests are adjusted where they assumed the preview hash; say which in the report.
- **`ProbeLook(ctx, id, durationMs) (ProbeLook, error)`**: for the supply at `Next`: the file's `c_probe`
  row if any (phase, plan, result, judge_by), whether it has a resume checkpoint, and whether at least one
  candidate exists (the walk above cut at its first hit, reading no fingerprint's frames, at most 64 index
  entries a side). At most three index seeks and that bounded walk; a named test holds the bound by
  counting rows read, not seconds.
- **`ProbeFetched(ctx, in)`**: a probe turn's end (`ProbeSupply.Probed`), for a file the account holds
  (`guardedBy`, as `CheckLater`): the row made or updated (`rounds` + 1, `parts_fetched` + kept,
  `last_new_parts`), and the file given back by `CheckLater`'s own statement shape (set aside until a time,
  `claimed_by` cleared, **no attempt spent, the set-aside count unchanged**) with a fixed reason of its own
  ("its frame check is being judged"). When every planned part is kept (kept + already = planned, not
  refused): phase `judge`, until `in.JudgeBy`. Otherwise it is settled as an unknown (below) with why
  `not-kept` (the store refused a part) or `parts-missing`.
- **`ProbeJobs(ctx, limit)`**: the judge's list: files in phase `judge`, oldest first, with what the judge
  needs (the file's number, size, length, rounds, parts so far, the saved file a hold names if it is held).
- **`ProbeVerdict(ctx, in)`**: the judge's word, and the one place the rules below live. Its kind is a Go
  type with exactly these values: copy, partly, no match, more parts, unknown, final. **There is no value
  for "exact" and the door writes no exact edge on any path** (a test tries every kind and reads the edges).
  It acts on the file only while the file is not claimed and not saved or gone (set aside as above, or
  wanted again because its time passed); when a lane holds it the verdict is recorded on the row only and
  counted as late.
  - **copy** (it names the saved file, hits and samples): the file is held as a probable copy with a fixed
    reason ("the same footage as a saved video (sampled frames)"), a probable edge to that file with the
    evidence "sampled frames k of n" (numbers only), written the way `HoldExact` and `HoldLookAlike` write
    theirs; its `c_part` rows deleted in the same transaction; its frames kept. A file that is held already
    stays held and gains the edge and a mark that frames confirmed it.
  - **partly** and **no match**: the file is as it was before its probe: wanted now (its time cleared), or,
    **if it was held, held still: neither ever releases a held file**. Partly leaves a related edge
    ("partly the same footage") and the mark the lane order's partly tier reads, if one exists (read
    `lane.go`; if none exists, record it on the row and say so). Frames kept, parts kept.
  - **more parts** (a list): phase `fetch`, the plan stored, the file wanted now. Refused when the file has
    had 4 rounds (a named constant; **corrected 22:52 from the design's 3**: the index's parts, the rest of a
    long index, the 8 frames, and the second round of frames a check on the cusp takes are four trips; the
    parts, which are what cost Telegram anything, keep the old cap) or the plan would bring its parts over
    32 in all: then it is settled as final, `parts-cap`.
  - **unknown** (a why; passing reasons only): the file set aside 15 minutes when `last_new_parts` > 0, an
    hour otherwise; `tries` + 1; `first_unknown_at` set when it is 0 or when `last_unknown_at` is more than
    6 hours back (a new stretch); `same_fails` counted for why `ffmpeg` with no new part, cleared otherwise.
    **Downloaded unchecked only by these two bounds:** 24 hours since `first_unknown_at`, or `same_fails`
    of 3: result `unchecked`, why kept, phase `done`, the file wanted now.
  - **final** (a why from the final list): result `unchecked`, phase `done`, wanted now, counted.
  - A held file is never made wanted by unknown, final or the bounds either: it stays held.
- **`ProbeOverdue(ctx, id, now)`**: for the supply, on a file that is wanted, unclaimed, in phase `judge`
  with `judge_by` passed (no judge answered): settled as unknown with why `no-answer` through the same code
  as the verdict; it answers what became of the file (put off, or now unchecked and to be handed out).
  Guarded on the state it read: a file claimed or changed meanwhile is left alone and reported as such.
- **`ProbeCloseAll(ctx, why)`** (added 22:53): for a start with the frame check switched off: every open row
  (phase `fetch` or `judge`) becomes result `unchecked` with the why given (`switched-off`, one more fixed
  word of the list), phase `done`; a file set aside for its judge is wanted now, a held one stays held; in
  chunks, so the writer is never held for seconds; it answers how many. Also one more final why in the
  list: `no-candidate` (the saved video it was to be compared with is gone by the time the judge looks).
- **`ProbeStats(ctx)`**: counts by phase, result and why, and the files downloaded unchecked by why: every
  number says what it counts (rows of `c_probe`, not requests).
- A setting row for the floor, read and written by two small doors of your own in `probe.go`
  (`ProbeFloor`, `SetProbeFloor`: megabytes, 20 by default, 20 to 4,096, a value that does not read back is
  an error and the default is not assumed): do not edit the `Settings` struct.

## Part B: `internal/partsledger`
`parts.Ledger` on the catalogue, as `internal/storeledger` is `store.Ledger`: types converted, the catalogue
does the work, errors come back as the package's own `*Error` naming the method and the failure's type only
(`errors.Is` finds the catalogue's sentinels through it). `Needs` with the signature `parts.Store.Sweep`
takes. Tests: the store's own ledger tests run against it where they exist as a suite, else the same cases
written here (put, replace, parts sorted, files' sums, remove one, remove a file, a failing catalogue keeps
nothing), plus one end to end: a real `parts.Store` on a temp folder with this ledger: put, read back
verified, reopen the store and read back again, delete the `tg_media` row and find `Kept` false (the row is
gone, so the part is never read), sweep with `Needs` in each state. Invented bytes only.

## Part C: the supply
**Corrected 22:53 (two states of the switch, not one):** with `FrameCheck` nil the frame check is off and
nothing below happens. With it set and answering false (a judge runs but its ffmpeg has not passed its
self-test) the supply still makes its one `ProbeLook` per eligible video, makes **no first plan** (the file
is handed out as today, counted "the judge is not ready") and settles a file whose row is open (phase
`fetch` or `judge`) as an unknown with why `no-ffmpeg` through `ProbeOverdue`'s code (put off, the bounds
apply, counted): a file in the middle of its check is never handed out uncounted because ffmpeg went away.

`supply.Config` gains: `FrameCheck func() bool` (the judge's word that it runs and its ffmpeg passed its
self-test; nil: **`Next` and every finish are bit for bit as today**, shown by a test that runs the
same scripted lane with the field nil, once with no probe rows in the catalogue and once with rows in every
phase, and compares what was handed out and written with what the base hands out and writes); `JudgeWait` (how long a file waits for its judge before it comes back: default 15
minutes). `*Supply` implements `engine.ProbeSupply`.
- **At `Next`,** for a file that is a video of the floor's size or more with a known size and a length,
  that is not marked for the exact check first (`check_first`: the engine never probes such a file), not a
  held copy (tier 5: confirming held files is a later piece; say it in a comment) and not in the run's
  "never plan" set: one `ProbeLook`. Every other file takes no new read at all.
  - It has a checkpoint: handed out as today (a file with a partial download is never checked: the old rule).
  - No row and no candidate: as today, counted ("nothing to compare with").
  - No row and a candidate: `Plan` is the first and the last part of the file (where an MP4's index lives:
    the old app let ffmpeg read both; asking them in one turn saves a second trip, and both are reused by
    the transfer). A file of one part is not probed.
  - Phase `fetch`: `Plan` is the stored plan (ascending, no duplicate, inside the file, at most 32; a
    stored plan that fails this is not handed out: the file is settled final with `parts-cap` and counted).
  - Phase `judge`, its time passed: `ProbeOverdue`; put off: not handed out; unchecked: handed out as today.
  - Phase `done`: as today.
  - `ProbeLook` or `ProbeOverdue` failed: the file is passed over for a later `Next` (as a failed
    `HeldUnlessSame` read is today), **never handed out unchecked because a read failed**.
  A file may carry `Check` and a `Plan` at once (the lane runs the exact check first); the pen's rules for
  marked files are not changed.
- **`Probed`**: one finish per claim, through `record` like every finish (a new pending kind, retried until
  recorded, not in the finish log, as `pendSame`: a stop before the record leaves the file active, `Recover`
  gives it back, and its next probe turn finds its parts kept and asks nothing).
- **`Requeue` with a reason for which `engine.IsProbeRefusal` holds:** the file joins the run's "never plan"
  set and its row gets result `unchecked`, why `lane-refused` (it is handed out as an ordinary transfer:
  counted, with its reason on record). After `ReasonProbeNoStore` or `ReasonProbePartSize` (the engine has no
  part store or another part size: every plan would be refused) the supply plans nothing more in this run
  and counts files as it does with the frame check off.
- **Counters:** `Stats` gains the frame check's counts (planned first rounds, further rounds, nothing to
  compare with, probe turns recorded, overdue, put off, unchecked by why, refused plans by reason; maps
  cloned in `Stats()` as the look-alike ones are). `Flusher` writes `Bucket.Probe` into the new columns with
  the same "what it gained since the last flush" rule; the existing test that every field of `Counters`
  reaches a column gets its twin for `ProbeCounters`.

## What is not yours
The judge and ffmpeg (E16); any line of the collector (the main session writes on the board what it needs
there); the engine; confirming or releasing held files and the owner's verdicts (a later piece: your doors
only keep a held file held); a page.

## Rules that bind every line
Only the same file id, the same SHA-256 or every part hash may skip a file: nothing here skips one. A
probable copy is held, never skipped. Unknown is never "download unchecked" outside the two bounds and the
final list above, each counted with its why. Nothing in a log, an error or a test's output but counts,
sizes, timings and fixed words. Invented media and numbers only. New log lines use constant format strings.
No test judges on real seconds (a clock you pass in, rows read, or a plan).

## Tests while working, and at the end
`source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then in `archiver/`:
`GOGC=25 GOMAXPROCS=2 go test -p 1 -count=1 ./internal/catalog/ -run '<names>'` (and the same for
`./internal/supply/` and `./internal/partsledger/`). **Named tests only for `internal/catalog` and
`internal/supply`** (their whole runs take minutes and are the main session's, once, after the review);
`internal/partsledger` may run whole. No `go vet` over the tree, no race detector, nothing in Docker. **The PC
had 3.1 GB of memory free when this was written: before each go command look at the free memory, and when
under 2.5 GB wait a minute rather than start one; never two go commands at once.** At the very end: gofmt
on your files, `go build ./...` once, `go vet` on your three packages, and every test you added or changed
by name once more; write the seconds in the report. Name your tests so one `-run` pattern takes each part's
(for example `TestProbeSchema`, `TestProbeDoor`, `TestPartsLedger`, `TestSupplyProbe`).
Tests that must exist by the end, besides those named above: the step on a file at the version before
(tables, index and columns there; run twice: nothing changes); the step refused at any other version; each
verdict kind on a wanted file and on a held file (a held file is held after every one of them); the 24 hour
bound, the 6 hour gap and the 3 identical failures, each by a passed clock; a late verdict on a claimed file;
`ProbeOverdue` on a file claimed meanwhile; `Next` with the frame check on: each row of its list above; a
failed `ProbeLook` hands nothing out unchecked; a refused plan is not planned again and is on record; a
`Probed` whose record fails is retried until recorded; mutations: say in the report which rules you broke on
purpose to see a test fail (at least the held-stays-held rule, the two bounds, the "never plan" set, the
part-count bound, the lost-file candidate).

## Hand-back
Commit-ready on `wip/copies-15`, pushed, the copy clean. A report
`archiver/docs/progress/copies-probe-catalogue-REPORT.md` (commit it): what was built per part, the final names of
the doors, the index chosen and its plans, the step's seconds at 100,000 rows, every test added or changed
(other tracks' included, with the reason), the mutations, departures from this brief with the reason, doubts,
and what the judge (E16) and the collector's lines will need to know. Keep a
`archiver/docs/progress/copies-probe-catalogue-PROGRESS.md` current from your first hour (what is done, what is
in hand, the next step in one line) and commit it with each push. Your last message to the main session: the
head commit, then at most 25 lines.
