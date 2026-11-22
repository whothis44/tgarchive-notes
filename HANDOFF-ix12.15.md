# Handoff: after ix.12.14 (built and pushed 2026-11-07) — for a fresh session

Self-contained. Read this file first, then the project memory
(`C:\Users\trabi\.claude\projects\C--Users-trabi-Claude-Projects-Telegram\memory\`: MEMORY.md and the files it points
to). `HANDOFF-ix12.14.md` is background only; everything that still matters is repeated here. Times: "local" is the
user's EST (UTC-5); report timestamps are UTC (Z).

## The goal and the account

- Fork `whothis44/telegram-media-downloader` (Go server in `core-service/`, dashboard pages embedded). The user archives
  Telegram groups with it. **Goal: save as much distinct content as possible before the Telegram account is deleted on
  2026-11-30.** Account: non-Premium, **frozen since 10-31** (it can still read and download; some methods are refused).
- A crash or a bad restart costs more than most improvements. Small, tested changes; batch them into one release.
- The user's attention is limited: short reports, numbers first, one clear recommendation, ask before anything that
  changes the archive.

## FIRST: where 12.14 stands (check before anything else)

| Version | Tag / commit | State at handoff |
|---|---|---|
| ix.12.13 | `v3.4.18-ix.12.13` = 96128b8 | live since 11-07 01:16 local |
| **ix.12.14** | branch `ix/v12.14`: 9be1fe8 + **6c2beca** (test-only race fixes), draft CI-only PR #26 | **not tagged yet.** First CI run failed on two test-only races (fixed in 6c2beca); CI was re-running on 6c2beca when this was written |

1. Check CI for 6c2beca: `cd C:\Users\trabi\Claude\Projects\Telegram; PYTHONUTF8=1 python -I ix-tools/ci_wait.py 6c2beca44df408aea6da752c04c5b3fb4a21ebe2 ix/v12.14`
   (in the background), or `IX_VER=12.14 python -I ix-tools/gh_pr.py runs`. Also check whether the tag already exists
   (`git ls-remote --tags origin v3.4.18-ix.12.14`): an earlier session may have published it.
2. **If green and not tagged: the user authorized publishing 12.14** ("Once that's done, move towards building and
   pushing 12.14. Authorized", 11-07). Tag 6c2beca: `git tag v3.4.18-ix.12.14 6c2beca && git push origin v3.4.18-ix.12.14`,
   then `IX_VER=12.14 python -I ix-tools/gh_release.py wait` (background) and `show`. A failing
   `TestHistoryBackpressureHonorsConfiguredStallDeadline` in the release run is a known flake: re-run only the failed
   job. That OK is for 12.14 only; 12.15 needs its own.
3. If CI fails again: read the job log (`PYTHONUTF8=1 python -I ix-tools/ci_log.py RUN_ID "JOB NAME" OUT`; without
   `PYTHONUTF8=1` it crashes printing "→" but still writes OUT). The race detector only runs in CI (this PC has no cgo).
   The two races found were in **tests** (an unguarded append in a callback; assigning `a.dataDir` while background
   workers read it): look there first, but read the report's stacks before concluding.
4. After the install (the app checks GitHub hourly, drains ≤20 min, restarts): verify `E:\T\tg-dl\data\crashes\running`
   says 3.4.18-ix.12.14 and `history.jsonl` shows 12.13 ended "clean".

## Rules that matter most (standing, from the user)

- **Live install `E:\T\tg-dl`: read only.** Never stop, restart, replace or edit it or its settings. The DB may be read
  only as `file:E:/T/tg-dl/data/db.sqlite?mode=ro`, and only **counts/categories** may be printed: never names, IDs,
  paths, message text. Folder names under `data\tgdl-staging` and paths in `start.bat` are private.
- **No report reading until the 12.14 privacy fix is live** (the user's words: "no log reading until fixed"). Once 12.14
  runs, ask the user before reading `data\ixreports` again; never print report lines matching "same bytes as".
- The start.bat console prints full names by design (ixLog → `a.output`, at most one line a minute); only the report
  (`data\ixreports`) is redacted. The user knows this and does not want the console anonymised.
- **Publishing installs on the user's archive.** Tag/publish only with the user's explicit OK for that version. Never
  merge a PR or push `main` (still `93b7dd6`). PRs are draft, CI-only.
- **Claims:** no speed claim without measurement; "looks like" for one day's evidence.
- **Copies design** (probable copies held at the back) is deliberate: act on evidence it ignores, don't redesign.
- Tests use invented data only. Any new `ixLog` must have a constant format string (`ix127_redact_guard_test.go`).
  Text that reaches the report (e.g. Priorities' "waiting" text, which `ix_coverage.go` puts in a diag line) must not
  carry a group name.
- Windows: **write edit scripts with the Write tool** (shell heredocs can mangle `\n`), run with `python -I`, write with
  `newline=''`. All repo files are LF. Git Bash's `grep -c $'\r$'` miscounts: check line endings in Python. Shell cwd
  resets often: absolute paths.
- VPN: never test the downloader outside it, never change VPN settings. Never commit or print `start.bat`.

## Tools (unchanged from 12.14 unless noted)

- Worktree `C:\Users\trabi\Claude\Projects\Telegram\repo-v12.11` (branch `ix/v12.14`). New work: `git checkout -b ix/v12.15 ix/v12.14`.
- Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env.sh` from `repo-v12.11/core-service`.
- Before pushing: `gofmt -l .`, `go vet ./...`, `go test ./internal/app ./internal/engine ./internal/telegram ./internal/download`
  (app ~110–140 s). Windows baseline failures, not regressions: `backup`, `config`, `dbread`, `faststart`, `fsx`, `hash`.
  A full `go test ./...` piped through `head` hides lines: run the four packages separately to see app's result.
- UI checks: `SP=/c/Users/trabi/AppData/Local/Temp/claude/71f159c3a9e5d4b9/63fc91bc-a626-41aa-a92f-6717bf517e6d/scratchpad;
  PYTHONPATH=$SP/pw PLAYWRIGHT_BROWSERS_PATH=$SP/pw/browsers PYTHONUTF8=1 python tests/ui/<x>.py`. 12 checks exist; new in
  12.14 and in CI: `archive_rescan_lanes.py`, `queue_chip_totals.py`.
- Commit: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit …` ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Version in `core-service/internal/version/app.go` and
  `docs/archive-data-sample/data/manifest.json`; CHANGELOG in two identical copies (check with `cmp`).
- `ix-tools/`: `gh_pr.py` (`IX_VER=12.15 python -I ix-tools/gh_pr.py open BODY.md`), `ci_wait.py FULLSHA BRANCH`
  (background), `ci_log.py` (needs `PYTHONUTF8=1`), `gh_release.py`. No `gh` CLI. **The app's PR tools (`ccd_pr bind_pr`)
  refuse this repo** (the session folder is not the checkout): use `ci_wait.py`. CI strategy as before: one draft PR
  per version, re-run only failed jobs, batch fixes so CI runs once.
- Read-only live queries: `ix-tools/live_q*.py`; 11-07 scratch examples printed counts only (queue lanes, job progress
  deltas).

## What 12.14 changed (where the code is)

- **Report redaction** `app/ix_diag.go` `clean`: `<name>`/`<link>`/`<email>` become private-use runes while the
  Windows-path, relative-path and file rules run (`ixPlaceholderHide/Show`); relative paths also end at `:`. Staging
  log lines print `message #%d`. Guard values + `TestIx1214NamesInsidePathsAreHiddenWhole`. What 12.13 leaked (made-up
  sample): `leak-sample-12.13.md` in the project folder — only words before a chat/topic name inside a file name.
- **Stall watchdog** `app/ix_stall.go`: `ixBeat(groupID)` in `runHistory`'s loop top (`history_runner.go`), each
  gap-fill batch and Telegram wait (`ix_live.go`), each comment page (`ix_chat.go`). `ixPassStalled` (30 min,
  `ixPassStallAfter`; a job first seen by this process counts from then). `ixQueueTrack` (`ix_queue.go`, case
  "running"): `ixAbandonPass` ends the job (state error + Cancelled, memory + DB with a 30 s write limit) and dumps
  goroutines to `data/crashes/stall-<UTC>.txt` (at most 10 kept); log line says "its worker was still running, blocked"
  or "its worker had already ended". First stall → retry from `ResumeFrom`; second in a row → failed (`Stalls`, reset
  by progress or "Run again"). Stalled after the last page (`ixPassEnd`/`ixPassEnded`) → counts as a finished messages
  pass. `finishHistory` failures now also go to `ixLog`. Comments bounded: 5 failures in a row or 1 h
  (`ixCommentsFailMax/TimeMax`).
- **Staging** `download/staging.go` `stageHasRoom`: staged while `free - inFlight - size >= KeepFree`; unknown free space
  → old cap (20 GB); a started download with nothing waiting to copy goes on. `ixSettings.StageKeepFreeGB` /
  `StageKeepFree()` (`ix_safety.go`; old cap ≤50 → 50, >50 → cap; min 20). Kept parts floor `ixPartsFloor`
  (`ix_part_store.go`) = max(60 GB, keep-free + 10 GB) when staging is on. Status `keepFree/room/roomKnown`.
- **Parallel copies** `MoveStaged`: `StageCopiers = 3`; `stageBatches` keeps moves sharing a file (identity) or a
  message together, in order (`moveOneStaged`). Report copy line: "MB/s per copy", seconds summed over copies.
- **Lanes** `app/ix_lanes.go` `ixQueueLanes` (status key `lanes`: holders, last sign of work, `ahead`, rank `places`);
  `ixLaneLess` is the queue's own order (also used by `ixQueueStep`). Priorities text `ixLaneWait`/`ixCoverageWaiting`
  (`ix_coverage.go`). Page: `laneLines`, `laneQuiet`, run-order sort, "Rank N" in `ix.html`; `prioEta` shows nothing /
  "not known until its messages are read" when a group's own needed is 0.
- **Check for updates** `ix_update.go` action `check` → `ixUpdateCheckNow` (≥1 min apart, waits ≤15 s); `checkedAt`,
  `checking` in the status; `updateCheckLine()` in Settings.
- **Downloads chips** `webassets/public/js/queue.js`: "N of total" for Queued / Set aside only when the snapshot was
  capped (`listCapped`); server `queuedCount` in `app/queue_hold.go`.
- **Choose groups type filter** `ix.html`: `pickHide` (localStorage `ix.pickHide`), types from `ix_group_info.kind`
  (status `groups[].kind`) or the loaded dialogs; unknown stays visible; hidden ticked count shown.

## Open items (in priority order; confirm with the user before building)

1. **Publish/verify 12.14** (above). Then, with the user's OK to read reports again: the stall lines ("rescan: the
   messages pass of … made no progress…"), whether the stuck messages lane moved (on 11-07 the group at Priorities
   place 38 had read 100 messages and nothing for 19 h; ranked groups at places 45, 46, 50, 61 waited behind it), and
   the Rescan tab's lane lines.
2. **Root cause of the 11-07 messages-pass stall** (unknown). Every Telegram call has a 30 s timeout, so either the
   worker blocked on something that ignores its context (`monitorOp`, `mediaMu`) or it ended and `finishHistory`
   could not save its end (the reviewer's lead suspect; it matches "a restart resumed the same job"). The first stall
   after 12.14 says which and writes `data\crashes\stall-*.txt`: read only function names/frames from it (no
   arguments), find the blocked history goroutine, fix the cause. Not a closed/banned group and not deleted messages:
   those end a job with an error, never a 19 h "running".
3. **Watch the 12.13 in-download check** (HANDOFF-ix12.14 item 1, blocked on the report rule): the line "big videos
   checked in their download (on) since start: …"; warning signs: "downloaded without a check" dominated by one reason,
   many "check failed" of one kind, downloads/hour dropping, rows stuck `processing`, crashes. The user can switch it off
   in Settings; never change it yourself. Also check "decoder cuda" on the video index line and no `document_<digits>`.
4. **Staging/NAS**: live 11-07 ~14:30Z: staging ~128–135 GB / ~2,500 files waiting, E: 346 GB free, copier ~10 GB/h one
   file at a time. 12.14 copies 3 at once (speed-up **not measured**): compare "last hour: N copied … MB/s per copy"
   and "oldest waiting" in no-limit hours with 12.13. If the NAS is the limit, 3 copies share it; don't claim a speed-up
   without numbers.
5. **High CPU and reads all the time** (unchanged): ~900–990 MB/s read and 250–290% of a core every hour since 11-06
   15:00, video index idle. Profile before changing anything (pprof CPU profile, or statement timing with a big synthetic
   queue of ~32,600 rows). 12.14 adds `ixQueueLanes` to every status poll (one rank query + triage when the queue is
   non-empty): include it in the profile.
6. **DC1 slowness in no-limit hours** (unchanged): the 12.12 per-server time line will answer it; `paceByAnswers` stays
   off unless that line gives evidence.
7. **Rank-33 group never queued**: ask the user to click "Add it to the rescan" once on 12.14 and read the page message;
   check for a new `ix_walks`/`tgdl_history_jobs` row (counts only).
8. **"Downloading 14 vs 25"** (user screenshot 11-07): the Downloads page and the Archive summary both count
   `processing` rows; likely different moments. If the user sees a gap after reloading the Downloads page, compare
   `engine/snapshot.go` (active rows) with `ix_dlstate.go` `ixDlCount` (`run`).
9. **From the 12.14 review, later**: prune old `stall-*.txt` instead of stopping at 10; show a job abandoned by the
   watchdog consistently (a late `finishHistory` turns "error" into "cancelled"); redaction gap: a folder named after an
   old chat title with spaces before the first `/`, or a relative folder path with no extension (rare in logs).
10. **UI, later (review's ranked proposals not built)**: Choose groups "in the rescan: waiting (N ahead)"; merge the
    Rescan queue table into Priorities as one list per group.
11. **Per-topic priority**: the user asked whether a topic can be prioritised. Not possible today (ranking is per group;
    the topic filter is include/exclude). Would need a rank per topic in `ix_sched.go`, `tgdl_group_rank`, `sched_order`
    and the Priorities page. Offer, don't build unasked.

## Facts learned this session

- Rescan lanes: one group per lane (messages, files), next = first waiting group by ranked place, then ★, then the
  deletion triage; a higher-ranked group takes a lane from a lower one after 2 min. A group waits until it is first
  among the waiting groups of its lane, not until it is rank 1. Restarting a rescan loses nothing: pages are saved as
  read, the queue is in kv `ix_queue`, `ResumeFrom/Carried/PassStartedAt` survive, so `ixFinishWalk` does not
  wrongly flag messages deleted.
- A cancel only flags a history job (`handleHistoryCancel`); the job stays `running` until its worker returns, and
  `handleHistoryStart` hands back the same job (ALREADY_RUNNING) while it is `running` in memory.
- The Downloads page lists at most the next 1,000 files to download, 500 set aside and the last 100 finished; its chip
  counts are of the page. The Archive summary counts the whole queue.
- 11-07 live numbers (counts only): rescan 58 groups, all ranked: 32 done, 20 waiting for their files pass (places
  37–60), 4 waiting for messages (45, 46, 50, 61), 1 files pass running (place 36), 1 messages pass stalled (place 38).
  Set aside 26,521 (18,345 likely copies, 8,135 private/smaller first, 39 big lane, 2 by the user); ready 4,832.
