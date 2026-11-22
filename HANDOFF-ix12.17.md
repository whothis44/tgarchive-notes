# Handoff: after ix.12.16 (built 2026-11-07) — for the session that builds ix.12.17

Self-contained. Read this file first, then the project memory
(`C:\Users\trabi\.claude\projects\C--Users-trabi-Claude-Projects-Telegram\memory\`: MEMORY.md and the files it points
to). Background only: `HANDOFF-ix12.15.md` (rules and tools, repeated below), `PLAN-small-dedup.md` (the measured
analysis behind 12.16). Times: "local" is the user's EST (UTC-5); report timestamps are UTC (Z) unless marked local.

## The goal and the account

- Fork `whothis44/telegram-media-downloader` (Go server in `core-service/`, dashboard pages embedded). The user archives
  Telegram groups with it. **Goal: save as much distinct content as possible before the Telegram account is deleted on
  2026-11-30.** Account: non-Premium, **frozen since 10-31** (it can still read and download; some methods are refused).
- A crash or a bad restart costs more than most improvements. Small, tested changes, batched into one release.
- The user's attention is limited: short reports, numbers first, one clear recommendation, ask before anything that
  changes the archive. The user dislikes any change that adds waiting per file ("2 seconds for each file over a day
  will accumulate a lot"): prefer fixes that remove work over fixes that slow it down, even when a delay is not per file.

## FIRST: where things stand (check before anything else)

| Version | Tag / commit | State at handoff (2026-11-07 ~18:15 local) |
|---|---|---|
| ix.12.15 | `v3.4.18-ix.12.15` = 958344d | **live since 11-07 17:35 local**, GitHub latest; 12.14 ended "clean" |
| **ix.12.16** | tag **`v3.4.18-ix.12.16` = 83fc7d1** (f5d0a49 + a test-only race fix), branch `ix/v12.16`, draft CI-only PR [#28](https://github.com/whothis44/telegram-media-downloader/pull/28) | **PUBLISHED 2026-11-07 evening with the user's explicit OK** ("Publish 12.16 now"). Release workflow 42428711262 success; GitHub latest; 8 archives + SHA256SUMS. Install not verified at handoff: check `crashesunning` and `history.jsonl` |

- Worktree for 12.16: **`C:\Users\trabi\Claude\Projects\Telegram\repo-v12.16`** (branch `ix/v12.16`, made with
  `git worktree add` from the 12.15 tag). `repo-v12.11` stays on `ix/v12.15` (958344d), clean; don't switch its branch.
  For 12.17: `git -C repo-v12.16 checkout -b ix/v12.17 ix/v12.16` (or a new worktree from `ix/v12.16`).
- 12.16 was published by tagging 83fc7d1 (`git tag … && git push origin v3.4.18-ix.12.16`) with the user's explicit
  OK; release workflow: `IX_VER=12.16 python -I ix-tools/gh_release.py wait` / `show`. A failing
  `TestHistoryBackpressureHonorsConfiguredStallDeadline` in a release run is a known flake: re-run only the failed job.
  12.17 needs its own OK.
- After any install (the app checks GitHub hourly, drains ≤ 20 min, restarts): verify `E:\T\tg-dl\data\crashes\running`
  shows the new version and `history.jsonl` shows the previous one ended "clean".

## Rules that matter most (standing, from the user)

- **Live install `E:\T\tg-dl`: read only.** Never stop, restart, replace or edit it or its settings. The DB may be read
  only as `file:E:/T/tg-dl/data/db.sqlite?mode=ro`, and only **counts/categories/timings** may be printed: never names,
  IDs, paths, message text. Folder names under `data\tgdl-staging` and paths in `start.bat` are private.
- Reports: `E:\T\tg-dl\data\ixreports\latest.txt` (hourly, redacted) may be read; **never print lines matching
  "same bytes as"**. The start.bat console prints full names by design (ixLog, ≤ 1 line/min); only the report is redacted.
- **Publishing installs on the user's archive.** Tag/publish only with the user's explicit OK for that version. Never
  merge a PR or push `main` (still `93b7dd6`). PRs are draft, CI-only. Pushing a branch also needs the user's OK in
  this setup (the auto-mode classifier blocked an unapproved push on 11-07; the user then said "push for CI").
- **Claims:** no speed claim without measurement; "looks like" for one day's evidence. Duplicate matches are
  probabilistic; a timeout is "unknown", never a match or non-match.
- **Copies design** (probable copies held at the back, never skipped) is deliberate: act on evidence it ignores, don't
  redesign. No change may add Telegram requests without measuring them (requests are scarce: downloads get FLOOD_WAITs).
- Tests use invented data only. Any new `ixLog` must have a constant format string (`ix127_redact_guard_test.go`).
  Report lines carry numbers only (no group names, no paths).
- Windows: **write edit scripts with the Write tool**, run with `python -I`, write files with `newline=''` (all repo
  files are LF). Shell heredocs can mangle `\n`. Shell cwd resets often: use absolute paths. A Bash `cat > file`
  without input hangs (stdin is not closed) — don't.
- VPN: never test the downloader outside it, never change VPN settings. Never commit or print `start.bat`.

## Tools

**Read `PRE-PUSH-CHECKLIST.md` (project folder) before every push.** CI kept failing after pushes on things a local run
can catch: test-only data races (12.14 twice, 12.16 once) and tests that collide with the app's own background loops.
**`ix-tools/race.sh WORKTREE PACKAGES… [-- go test flags]`** now runs `go test -race` like CI in the local
`golang:1.27.3` Docker image (already on this PC; worktree and module cache mounted read-only, no network). Verified
11-07: it reproduces CI's 12.16 race on f5d0a49 and passes on 83fc7d1. Download package ~95 s under -race; all of
`./internal/app` ~25 min (run your tests plus those of touched files, or the whole package in the background).


- Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env.sh`, then run from `repo-v12.16/core-service`.
  Before pushing: `gofmt -l .`, `go vet ./...`, and `go test` for `./internal/app` (~120–170 s), `./internal/engine`,
  `./internal/telegram`, `./internal/download` — run them separately (piping a full `./...` through `head` hides lines).
  In a background command, put the `cd` *inside* the command group (`{ cd …/core-service || exit 1; … }`): once the
  `cd` before it did not apply and `go vet ./...` ran in the wrong folder.
- Windows baseline failures, not regressions: `backup`, `config`, `dbread`, `faststart`, `fsx`, `hash`.
- **ffmpeg locally:** env.sh puts none on PATH, so real-ffmpeg tests skip. To run them:
  `export PATH="/c/Users/trabi/AppData/Local/WhisperJAV/Library/bin:$PATH"`. That build has **no WebP encoder**, so
  `TestRenderGalleryThumbStill` fails with it on every version (12.15 too): an environment difference, not a regression.
  CI installs a static ffmpeg with WebP; CI is the tiebreaker.
- Known flaky/global-state tests: `TestIx127LibraryReadsByHour` reads a global per-hour counter (fails 9/10 with
  `-count=10` on 12.15 too; passes in one full run unless another test notes library reads in the same hour);
  `TestIxMLParallelismSettlesNearTheService` is load-sensitive (fails under a loaded full run, passes 4/4 alone on 12.15
  and 12.16); `TestHistoryBackpressureHonorsConfiguredStallDeadline` (release CI flake).
- Commit: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit …` ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Version in `core-service/internal/version/app.go` and
  `docs/archive-data-sample/data/manifest.json`; CHANGELOG in two identical copies (`CHANGELOG.md`,
  `core-service/internal/webassets/public/CHANGELOG.md`; check with `cmp`).
- `ix-tools/`: `gh_pr.py` (`IX_VER=12.17 python -I ix-tools/gh_pr.py open BODY.md`; `runs`; `jobs RUN_ID`),
  `ci_wait.py FULLSHA BRANCH` (background, `PYTHONUTF8=1`), `ci_log.py RUN_ID "JOB NAME" OUT` (needs `PYTHONUTF8=1`),
  `gh_release.py`. No `gh` CLI. The app's PR tools (`ccd_pr bind_pr`) refuse this repo: use `ci_wait.py`.
- Read-only live queries: `ix-tools/live_q*.py`. Measurement scripts from 11-07 (counts only), in the scratchpad of
  session 5aa93136 (`C:\Users\trabi\AppData\Local\Temp\claude\71f159c3a9e5d4b9\5aa93136-c483-416c-99c8-144cba0e0f18\scratchpad\`):
  `q1.py`–`q3.py` (queue by state, previews), `m1.py`–`m3.py` (the CPU challenger's timings with Windows I/O
  counters), and a copy of core-service at `cs\` with `internal\app\zz_measure_test.go` — a Go test that decodes the
  live archive read-only and measures twin/album precision against video fingerprints
  (`IX_MEASURE_DB=E:/T/tg-dl/data/db.sqlite go test ./internal/app -run TestZZMeasureSmallDups -v`, ~2 min). The
  scratchpad may be cleaned; copy what you need.

## What 12.16 changed (commits f5d0a49 + 83fc7d1; where the code is)

### 1. Copies among small files (the user's approved plan, PLAN-small-dedup.md)
- **Blind spot fixed** — `app/ix_held.go` `ixQueuedVideos`: was `LIMIT 20000 ORDER BY file_size DESC` over ~28.5k
  queued ≥ 5 MB videos, so everything under ~16.1 MB was never checked (1,144 queued 5–20 MB videos had no `ix_held`
  row; ~450 copies / 4.35 GB downloaded in 24 h because of it). Now: light columns of every queued video each round
  (bound `ixQueuedVideosMax` = 500,000), facts decoded once and cached per work id + identity (`ixQueuedFactsBox`,
  `ixDecodeQueuedFacts` in batches of 400, `keepOnly` forgets rows no longer queued). Report line
  `ixQueuedLookedLine`: "copy check of queued videos (256 KB or more): looked at all N … (M read for the first time)".
  Step 3 ("looked at" rows) now runs in one transaction.
- **Floor** — `ixHoldCheckMin` = 256 KB for the free check (was `ixHoldMinSize` 5 MB, which stays for image recognition
  on 320 px previews: those cost requests; `ix_copies_ml.go` vector attach skips < 5 MB). Survey estimate
  (`ix_copies.go`) uses the new floor. 24 h before: 619 copies < 5 MB (1.4 GB) downloaded.
- **Album rule** — `app/ix_album_copies.go`, setting `HoldAlbums` (`holdAlbums`, default **off**), UI checkbox under
  "Hold probable copies" in `ixassets/ix.html`. In-memory index of archived album videos from `ix_messages`
  (`ixBuildAlbumIndex`, rebuilt every 30 min, twins capped at 400 per video). Rule (`copyOf`): a queued video's album
  has ≥ 2 OTHER videos with a twin ≤ 6 preview bits in one album of another chat ("anchors"); then a saved twin in that
  album at 7–20 bits or without a preview counts (same length ±0.5 s, same shape, saved at least as good). Refuses when
  the queued video has any saved twin ≤ 6 bits (the free check decides, it may have refused because this copy is
  better); skips saved twins already matched by another album video (`targets`). Off, or while `HoldForever` is on: only
  counts; turning it off releases `how='album'` holds (`ixAlbumLetGo` → `ixUnhold`). Errors are logged, never stop the
  triage. Report: "copies by whole albums (off): would hold N files / MB now · index of N album videos, built in N ms".
  Measured precision (saved < 20 MB pairs vs fingerprints): ≤ 6 bits 95–98% same; 7–12 bits lone 76%, anchored 89%;
  13–20 lone 3%, anchored 67%; lengths-only album matching useless (5%).
- First round after install (live counts 11-07 18:00): 1,385 queued videos never looked at (1,058 in 5–16 MB, 307
  under 5 MB, 20 new). Expect roughly 600 new holds at once, then up to ~1,000/day at most.

### 2. Staged videos fingerprinted locally (user request in the 12.16 session)
- Why: the fingerprint pass read every new video back from the NAS (20–25 GB/h on 11-07) while the staging copier
  moved ~20 GB/h over the same share; staging held 2,401 files / 144 GB, oldest 7.9 h, none failing.
- `download/staging_process.go`: `StagedFile`, `HoldStaged` (lock key `stagedFileKey` = "staged-file:" + lowercased
  clean local path, via `Library.tryEnter`), `StagedToProcess`, `StagedFileAt`, `RemoveIfForgotten`,
  `dropStagedFree`, `removeStagedWhenFree` (background, up to `stageRemoveWait` = 3 h), `tryEnterWithin`
  (`stagePurgeWait` = 10 s), `stageDeferOK` (needs `StageDefer` set, staging room left = free − KeepFree − in-flight
  ≥ `StageDeferRoom` = 100 GB).
- `download/staging.go`: `moveStaged` takes the file lock for the whole move (busy → `errStageLater`, retried 30 s,
  not a failure). `MoveStaged` reads up to 400 due rows (with `json_extract(item,'$.Type')`), passes over files the app
  defers (they take no copier slot), and tops up to `StageCopiers` from the oldest waiting ones so copiers never idle.
  `RemoveStagedFiles` (purge) waits ≤ 10 s for the lock, else removes in the background. Ingest's same-bytes drops use
  `dropStagedFree`. New index `tgdl_stage_moves_wait(state, created_at)`. Status field `WaitingForChecks`.
- `app/ix_stage_process.go`: `ixStageDefer` (video, SHA-256 known, staged < `ixStageProcessWait` = 90 min, fingerprint
  pass can run — `ixVdupCanRun`, cached 30 s in `ixVdupRunsNow` — and no `ix_vfp` row for `h:<sha>`);
  `ixVdupStaged` (oldest first, one anti-join query `ixStagedToFingerprint`, LIMIT 8; holds the copy while ffmpeg
  reads; `RemoveIfForgotten` after; error text uses the library-relative path); fingerprints saved under
  `ixFileKey(sha,"")` = `h:<sha>` so the library pass (`ixVdupStep`) finds the file done after the copy;
  `ixStagedVfpArrived` (called from `ixStagedArrived`) repoints `ix_vfp.file_path` to the final library path;
  `ixStagedVfpSweep` (hourly, from `ixVdupStep`) forgets `h:` fingerprints of the last 7 days (older than 2 h) whose
  bytes are in no download and no staged file. `ixLocalReadKey` in the context keeps staged reads out of the
  "library reads by the background checks" counter (`ixFFmpegFingerprint` counts only library reads).
  `ixStagingRunnerOff` (test switch) keeps the background mover from starting.
- `app/ix_vdup.go` `ixVdupStep`: sweep, then staged videos first, then the library backlog (which was 1 video on 11-07:
  the pass keeps up). GPU→CPU fallback moved to `ixFingerprintFallback`.
- Report staging line: "videos fingerprinted here before copying: N since start; M staged videos waiting for it in
  the last pass (at most 90 min); fingerprints of staged files that never arrived, forgotten: K".

### 3. CPU: history drain asks EXISTS (found by the CPU challenger, measured)
- `engine/manual.go` `HasPendingManual` (`SELECT EXISTS(…)`); used by the history drain loop (`app/history_runner.go`
  ~line 486 and ~505), `history_api.go` (start), and `engine.StopObserving`. `PendingManual` (the count) stays only in
  `runHistory`'s backpressure (line ~109), which needs the number.
- Evidence (challenger, Windows I/O counters on the read-only DB): the count reads **62.6 MB in 15,284 ReadFile calls,
  0.16–0.18 s, every call even warm** (looks up 30,765 table rows to check `origin`; 2 MB page cache, no mmap). The drain
  loop called it twice per pass, back to back (a pass > the 250 ms ticker): ~400–500 MB/s and ~1 core of the measured
  512–770 MB/s / 1.8–2.2 cores. EXISTS: 0.5 ms, 7 pages cold. Same answers, no timing change.
- Not changed (user rejected): slowing the 250 ms polls to 2 s.

### Review
- An independent review agent checked all of 12.16; every must-fix and should-fix finding was applied (album errors
  no longer stop the triage; HoldForever never keeps album holds; no override of the free check's refusal; taken twins
  skipped; one anti-join query instead of per-row lookups; purged copies never left on disk; copier top-up; twin cap;
  orphan fingerprint sweep). Tests: `app/ix1216_copies_test.go`, `app/ix1216_stage_test.go`,
  `download/staging_process_ix1216_test.go`, `engine/pending_manual_ix1216_test.go`; existing
  `TestIxCopiesAreMeasured` updated (two report lines appended at the end of the copies section).
- Review nits **not** done (fine to leave or do in 12.17): `WaitingForChecks` undercounts (counts only within the
  400-row scan of one pass); the facts cache keeps a failed archived-record fallback until the identity changes (only
  misses holds); `ix_vfp.error` and the report's "video index errors" may contain an absolute *library* path (as before
  12.16; the report's `clean` redacts Windows paths) — staged errors now use the relative path.

## After 12.16 installs: what to check (report `latest.txt`, numbers only)

1. `[restarts]`: 0 crashes; `crashes\running` = 3.4.18-ix.12.16; previous version "clean".
2. **CPU/reads** `[process]` by-10-minutes: before (12.15, 11-07 17:35–18:00) **205–250% CPU, 514–716 MB/s read**.
   Expect reads to drop by roughly 400 MB/s and CPU by ~1 core. `[cpu]`: `engine.(*Controller).PendingManual` should
   fall from 17% to near 0. If not, the drain loop is not the main reader: re-measure (see open item 2).
3. Copies section: "copy check of queued videos … looked at all N" with N ≈ 29–30k and the first round reading ~1.4k
   records for the first time; held count (`queue: … held …`) up by roughly 600 in the first round; "copies by whole
   albums (off): would hold N" (expected tens of files: ~27 on 11-07).
4. Downloads: speed (11-07 18:00: 23–26 MB/s with plain waits only) and "last hour" (1,509 files) unchanged.
5. Staging line: "videos fingerprinted here before copying" rising; "library reads by the background checks … video
   fingerprints" falling (was 20–25 GB/h); copies per hour (11-07: 316 files / 19.8 GB in one hour, 2.2 MB/s per copy)
   — **speed-up not measured yet: compare before claiming**. Watch "oldest waiting" and that downloads never show
   "waiting for room".
6. No new "held-back copies:", "copies by whole albums:" or "near-duplicate scan:" errors in `[recent archive log]`.

## Open items for 12.17 (priority order; confirm with the user before building)

1. **Verify 12.16 live** (list above), especially the CPU drop and the first holds round. Report numbers to the user.
1a. **Report fixes found in the 12.15 log check (11-08 00:27Z; build these first, small):**
   - **Failed requests by kind never reach the report.** 12.15 records them (`PaceHour.DCFailKinds` / `DCFailKindsMs`,
     keyed `"<server> <kind>"`, `internal/telegram/pacer_hours.go`), but the report merges each account's hours field
     by field (`ix_diag_hours.go` ~lines 106–140, `ixAddCounts(&r.pace.…)`), and those two maps are missing there, so
     the "failed by kind:" part of the per-server time lines is always empty (`ixDCTimes` / `ixDCFailKinds`, ~line 337).
     Fix: merge both maps (a `map[string]int` version of `ixAddCounts`) and a test that builds the report from two
     accounts' hours with kinds. 12.16 has the same gap (checked: `repo-v12.16` has `ixDCFailKinds` but not the merge).
     The kinds are in the hourly record file meanwhile (`data\sessions\native\*.pace-hours.json`, numbers only, keys
     `dcFailKinds` / `dcFailKindsMs`). Read from it on 11-08: 11-07 18:00 local, no speed limit: **DC4 110 Telegram
     timeouts (-503), 564 s; DC1 55, 280 s**; plain waits DC4 58 / DC2 47 (a few seconds); 19:00: DC4 1 timeout. So the
     failed time is Telegram's -503, and DC1 lost little in those hours (12.15's -503 pause is the lever already built).
   - **`[cpu]` says "33.14 cores sampled" on Windows.** The Go profiler samples threads blocked in system calls there:
     98% of samples were in `runtime.cgocall`, and `app.integrityCheck` took 80% (the fixity pass waiting on NAS reads),
     while `[process]` measured 2.2 cores. Relabel it ("thread time sampled, includes waiting in system calls on
     Windows"), and report samples whose leaf is `runtime.cgocall` apart ("waiting in system calls, by what asked")
     from the rest ("on the CPU"), so it can't be read as CPU use (`internal/app/ix_cpuprof.go`, `ixCPUSummary`,
     `ixCPUDiag`). Function names and shares only, as now.
   - Privacy: both stay numbers and function names; no names, IDs or paths. Tests with invented data only.
2. **CPU, the rest (challenger's ranked fixes B and C, not built):**
   - B: covering index for the backpressure count in `runHistory` (`PendingManual` at line ~109, every 250 ms while
     the queue is full, ~2.5/s, ~150 MB/s): `CREATE INDEX IF NOT EXISTS … ON tgdl_work(status, origin)` or partial
     `ON tgdl_work(origin) WHERE status IN ('pending','processing')`, added in `internal/store/migrate.go` next to the
     existing `CREATE INDEX IF NOT EXISTS` at lines ~207–218. Stand-in measured 1.3 MB / 8.6 ms cold, ~0 warm. Build ~1 s
     at startup on 133k rows (estimate). Verify with `EXPLAIN QUERY PLAN` → "USING COVERING INDEX".
   - C: the 3-second-cached helpers in the same loop: `ixWaitingApartNow` (82 MB / 0.2–0.3 s per call),
     `ixSlotBlockedNow` (63 MB / 0.15 s), `ixAdmissionCredit` (10 MB / 25 ms): ~52 MB/s together. Options: a wider
     covering index, or a longer cache (15–30 s: only shifts the backfill's admission estimate, never a download).
   - The onset on 11-06 ~15:00 is unexplained (the queue did not suddenly grow); a release or rescan starting then is
     plausible. Not needed for the fix.
   - Remember the profile overcounts on Windows (threads blocked in syscalls are sampled: 8.84 "cores" vs 2.21
     measured), but cached ReadFile work (PendingManual) is real CPU.
3. **One clear view of the archive (user request, 11-07; clarified).** A "download all" button is *not* required (fine
   if included). The problem is that the current melange of screens (Overview, Priorities, Rescan, Downloads, Choose
   groups, Archive summary) makes it hard to see what is happening. The user wants, in one place:
   - to **prioritize groups cleanly** (and topics: see 3a);
   - per group: **what is downloaded, what is not, and why not** (held as a probable copy, set aside by the deadline
     order, not queued yet, waiting for its rescan, failed / given up, paused by a person);
   - **what has been scanned / rescanned so far and what is still outstanding**, including groups the user has not
     selected yet. Whole categories are still unselected ("imagine entire sports"): they may look large, but
     considerable overlap with what is saved is expected, so show an overlap estimate (copies by Telegram file, by
     the free preview check and by albums) next to their size, not just raw counts.
   Facts to start from (11-07 18:00): to download 66,941 (35,936 not queued yet); set aside 26,259 (copies 18,761,
   private/smaller first 7,474, big-file lane 22, paused by a person 2); rescan 58 groups: 41 done, 1 running (files),
   16 waiting (files). The Downloads page lists at most 1,000/500/100 rows; the Archive summary counts the whole queue;
   Priorities has per-group rescan state since 12.15. Design it as a proposal first (one page or a reworked Priorities),
   show the user, then build.
   **The core problem, from the user's screenshots (11-08, 12.15; names cropped): the same groups appear on three
   screens with three different vocabularies, and the numbers can't be reconciled by reading them.**
   - **Overview → groups table:** "Messages saved / Telegram says / Complete? / Finished / Deleted on Telegram / Files".
     Complete? reads e.g. "messages ✓ · 916 file(s) to go" (Files 1,785), "· 17 to go" (733), "· 306 to go" (1,111).
   - **Priorities → ranked rows:** "Saved / Through others / Probable / Still needed / Queue / Rescan". Typical row:
     still needed **1 (20.4 MB) "about 1 min from now"**, queue **0 · 320 held back**, rescan done. Another: needed 0,
     "28 held back". One ranked row has no rescan ("–"). "1 also needed ahead" appears without saying where.
   - **Rescan → queue table:** "Step / Messages saved / Files missing / Files queued / Tries", e.g. fetching files,
     47,689 messages, **16,586 files missing, 7,225 queued**; waiting rows say "N before it in its lane" and
     "Rank 45: change in Priorities".
   - So one group's "not downloaded" is called "to go" (Overview), "still needed" + "probable" + "held back"
     (Priorities) and "files missing" / "files queued" (Rescan), each counting a different set: Overview's "to go"
     seems to include held probable copies, Priorities' "still needed" leaves them out, Rescan's "missing" counts what
     the walk found before copies were held. A group with 916 "to go" can show 1 "still needed" and an ETA of
     "about 1 min" while hundreds wait held at the back. Nothing on any screen says which number is which, or links
     a held file to the saved file it matches (3b).
   - **What the user wants:** one row per group, in one place, with one vocabulary that adds up: **saved** (own /
     through another group) · **held as probable copy** (count, with a link to what it matches) · **waiting to
     download** (queued, with its place) · **not queued yet** (why: rescan waiting N ahead, never rescanned, group not
     selected) · **set aside** (deadline order) · **failed / given up** · **paused by you**, plus rescan state and rank,
     and an ETA that says what it covers ("unique files: about 1 min; 320 held copies after everything else").
     Unselected groups/categories listed too, with size and an overlap estimate. Verify each number's definition in
     code before naming it (`ix_coverage.go` for Priorities, `ix.html` Overview `groupComplete`, `ix_queue.go` items
     `missing`/`downloaded`), and make the totals add up in a test with invented data.
   **Seen on 12.15 (user screenshots, 11-07 evening), to fix or explain in that view:**
   - Rescan lane pill **"fetching files · no progress for 55 min"** (red). Its tooltip says a pass is stopped after
     30 min without a sign of work, yet it showed 55 min, so either the watchdog does not watch that pass or the pill
     measures something else. `ix_lanes.go:78` (`LastWay` = max(beats, passSeen)), `ix_stall.go` (`ixBeat`,
     `ixPassStalled`), `ixassets/ix.html:458/467`. A files pass waiting for room in a full queue beats every loop in
     `runHistory` (`history_runner.go:105`), so find which runner the files pass uses and why it shows no beat. Don't
     let the watchdog fail a files pass that is only waiting for queue room. Not diagnosed.
   - **"files waiting (6 ahead) · context canceled"**: a group whose pass was cancelled by the 12.15 restart (G227 in
     the report: attempts 1, resumes yes) shows the raw error text as if it failed. A pass cancelled by a restart that
     will resume should read "will resume", not an error.
   3a. **Topic ranks don't do what the page suggests (measured 11-07 ~18:30, read-only).** The user ranked 5 topics
   (all place 1); the Priorities box "Topics that go first" stays at the bottom, not in the ranking order (acceptable
   if it works). The ranking itself works (every queued topic file has sched_order 8-11, the top place). But:
   - topics 1 and 4 (559 and 26 archived photos/videos) have **nothing saved and nothing queued**: their groups are
     not in the rescan queue and have no work rows at all. Ranking a topic does not bring its group into the rescan.
     The page shows "0" queued without saying why;
   - topic 5: 459 saved, 560 waiting **all held as probable copies**, 279 not queued yet because its group's files pass
     waits in the files lane; the topic's place does not move its group up that lane;
   - topics 2 and 3: 877 / 25 saved, 172 / 26 waiting, **all held as probable copies** (back of the queue by design,
     whatever the rank).
   Proposals: ranking a topic adds its group to the rescan (or queues that topic's files directly) and gives the
   group's files pass the topic's place in the lane; the topic box shows per topic "saved N · waiting N (held as copies
   N) · not queued yet N (why)". **Decided by the user (11-07): held copies of a ranked topic stay behind unranked
   unique files** ("doesn't make sense to download a copy over a unique file when we can just cross-reference in the
   archive"): don't change the copy order for ranks; make the cross-reference visible instead (item 3b). Code: `ix_topic_rank.go`
   (`ixTopicBases`, `ixTopicRanks`), `ix_sched.go:349`, `ix_queue.go` (`ixLaneLess`, `ixQueueStep`).
   3b. **Media viewer: a file's duplicate is shown but not linked (user, 11-07: "major usability hindrance").** Opening a
   file that has a duplicate shows the duplicate on the page / side panel, but it cannot be clicked through to. Make
   every shown copy a link that opens that file in the viewer (and the reverse: from a held copy or a "probable copy"
   row to the saved file it matches, by `ix_held.like_path`/`like_key`, `ix_copy_hold.of_work`, `ix_msg_link`,
   `ix_subst`, near-duplicate pairs). This is how the user cross-references held copies instead of downloading them.
   **Privacy: never open the real media viewer, the live dashboard or any real file to look at this.** Work from the
   code (`ixassets/browse.html` and the viewer's JS under `ixassets/` / `webassets/public/js/`, the browse API in
   `ix_browse.go`, `ix_vdup_api.go`) and test with invented files in a test app or the repo's UI checks
   (`tests/ui/*.py` with Playwright on synthetic data, as in 12.14/12.15).
4. **Staging throughput:** measure 12.16's effect (item list above). If copying is still the bottleneck, consider more
   copiers only with evidence (3 since 12.14; 2.2 MB/s per copy on 11-07).
5. **"every file waits for each speed-limit wait … until 19:36 (plain FLOOD_WAIT on a file part)"** was shown on
   11-07 18:00: ix.12.4's 2-hour fallback to the shared gate after a plain FLOOD_WAIT on a file part. Downloads ran
   23–26 MB/s anyway. Watch how often it triggers; don't change without evidence.
6. Carried over from HANDOFF-ix12.15.md, check status before acting: root cause of the 11-07 messages-pass stall
   (12.14 watchdog dumps `data\crashes\stall-*.txt` — none seen yet; read function names only); rank-33 group never
   queued (ask the user to click "Add it to the rescan" once and read the page message); DC1 slowness in no-limit hours
   (12.15's per-server failed-request kinds answer it); `paceByAnswers` stays off.
7. Not proposed (measured, small): targeted 320 px previews for uncertain twins (~700 files, ~115 copies / 1.5 GB at
   best; the preview pass got ~60/h under 12.14, mostly paused by download FLOOD_WAITs; 74,784 still to fetch). Fetching
   all previews to hash them is not worth it (requests are the scarce resource).

## Live numbers (11-07, counts only)

- Pending < 20 MB: 13,233 files / 138.3 GB (videos 5–20 MB 10,551 / 134.6 GB); 79% in albums; held 8,215 / 73.6 GB;
  exact size of a saved file 6,654 (the exact re-upload check handles them at claim: 266–340 a day < 20 MB).
- Last 24 h (11-07): 8,161 files < 20 MB completed (42.3 GB); ~1,435 of the small videos were fingerprint-confirmed
  copies of an earlier saved one (8.3 GB), ~1,070 of them (5.75 GB) by today's own rule — the gaps 12.16 closes.
- Downloads 18:00: 23–26 MB/s, 1,509 files last hour, 21 downloading, waiting 30,746. Staging: ~2,400 files / ~144 GB
  waiting, 0 failing. Process: 215% CPU, 674 MB/s read (12.15, first 23 min).

## CI result for 12.16

- **f5d0a49: failed on one test-only data race**, everything else green (Docker, Archive features with ffmpeg, all
  server builds, browser and end-to-end checks; the Go application job had one failure). The race:
  `download.TestIx1216PurgedCopyHeldByACheckIsRemovedAfterwards` restored the package variable `stageRemoveWait` in
  its cleanup while the background goroutine of `removeStagedWhenFree` read it. Not possible in the live app (the
  variable never changes at run time). Fixed in **83fc7d1**: the deadline is read before the goroutine starts.
- **83fc7d1: CI green** (2026-11-07 evening): CI, Docker and Archive features (with ffmpeg) all success. Locally,
  `ix-tools/race.sh` on `./internal/download`, `./internal/engine` and the 12.16-related app tests
  (`-run 'Ix1216|IxCopies|IxHeld|History|Staging|Staged|Vdup|Purge|Album' -count=2`, 311 s) passed under -race too.
  **12.16 is ready to tag at 83fc7d1 when the user says publish.**
