# Handoff: after ix.12.13 (published 2026-11-07 05:35Z = 00:35 local) — for a fresh session

Self-contained. Read this file first, then the project memory
(`C:\Users\trabi\.claude\projects\C--Users-trabi-Claude-Projects-Telegram\memory\`: MEMORY.md and the two files it
points to). Older handoffs (`HANDOFF-ix12.13.md`, `HANDOFF-ix12.9.md`) are background only; everything that still
matters is repeated here. "Task N" below means the numbering of `HANDOFF-ix12.13.md`. Times: "local" is the user's
EST (UTC-5); the reports' timestamps are UTC (Z).

## The goal and the account

- Fork `whothis44/telegram-media-downloader` (Go server in `core-service/`, dashboard pages embedded). The user archives
  Telegram groups with it. **Goal: save as much distinct content as possible before the Telegram account is deleted on
  2026-11-30.** Account: non-Premium, **frozen since 10-31** (it can still read and download; some methods are
  refused, e.g. listing forum topics).
- A crash or a bad restart costs more than most improvements. Small, tested changes; batch them into one release.

## Words used here
- **Speed limit**: Telegram's FLOOD_PREMIUM_WAIT for non-Premium accounts (~1-5 GB/h); "no-limit hours" (~25-40 GB/h)
  come and go. **Plain wait**: an ordinary FLOOD_WAIT. **DC1/2/4/5**: Telegram's file servers.
- **Held / held back**: a queued file paused at the back as a probable copy (`ix_held`, `ix_copy_hold.how`:
  saved/queued/sampled/sampled-partial/recognition...). **Set aside**: paused by the deadline order (`ix_deferred`).
  **Ranked groups**: the user's Priorities list (`tgdl_group_rank`); their files go first. **Rescan**: the queue that
  re-reads a group's whole history (messages pass, then files pass; kv `ix_queue`). **Check / sampled check**: reading
  ~10 MB of a big video from Telegram, sampling 8 frames and comparing with saved videos' fingerprints (`ix_vfp`).
  **Kept parts**: those parts kept for the download (`data\ixparts`, `ix_part_store`). **Staging**: downloads written
  to local disk first (`data\tgdl-staging`), then copied to the NAS library.

## Codebase map (`repo-v12.11/core-service/internal/`)
- `engine/`: download queue (`work.go`: claim/finish of `tgdl_work` rows), workers (`controller.go`), pacing.
- `telegram/`: Telegram client, part downloads, pacer, waits (`download_wait.go`), kept parts, deferral error.
- `download/`: the library (`library.go`: ingest of one file, Substitute/Check hooks, staging, resume).
- `app/`: the HTTP server and the archive add-ons, all `ix_*.go` ("ix" = this fork's archive features): copies and
  checks (`ix_copies*.go`, `ix_held.go`, `ix_dl_check.go`), rescan queue (`ix_queue.go`, `ix_api.go`), priorities
  (`ix_sched.go`, `ix_coverage.go`), report (`ix_diag.go`, `ix_copies.go` diag lines), updater (`ix_update.go`),
  settings (`ix_safety.go` `ixSettings`), video index (`ix_vdup.go`). The Archive page is `app/ixassets/ix.html`
  (tabs: Overview, Rescan, Priorities, Downloads, Copies & duplicates, Organise, Settings...); the main dashboard is
  `webassets/public/`. Tests sit next to the code; `ix1213_*_test.go` are 12.13's.

## Rules that matter most (standing, from the user)

- **Live install `E:\T\tg-dl`: read only.** Never stop, restart, replace or edit it or its settings. The DB may be read
  only as `file:E:/T/tg-dl/data/db.sqlite?mode=ro`, and only **counts/categories** may be printed: never names, IDs,
  paths, message text (mask `error`/`note` columns). Folder names under `data\tgdl-staging` and paths in `start.bat` are
  private.
- **Publishing installs on the user's archive.** The app checks GitHub about hourly, lets downloads finish (≤20 min),
  exits; the launcher runs `ix-update.ps1` and starts the new version. **Tag/publish only with the user's explicit OK
  for that version.** (12.13's OK was for 12.13 only.) Never merge a PR or push `main` (still `93b7dd6`). PRs are
  draft, CI-only (CI runs only on PRs to main).
- **Claims:** no speed claim without measurement; "looks like" for one day's evidence.
- **Copies design** (probable copies held at the back) is deliberate: act on evidence it ignores, don't redesign.
- Tests use invented data only. The diagnostics report must never show a name (`ix127_redact_guard_test.go` fills
  every `ixLog` format and checks for leaks: any new `ixLog` must have a constant format string).
- Windows quirks: heredocs mangle `\n`/`\r\n` in scripts — write edit scripts with the Write tool and run with
  `python -I`; Python text mode writes CRLF unless `newline=''`. `*.ps1`/`*.bat` are CRLF. Shell cwd resets often: use
  absolute paths.
- VPN: only the downloader runs over the user's VPN; never test the downloader outside it, never change VPN settings.
- The project folder's `start.bat` holds private paths: never commit it, never print it.

## Tools and how to build/test/release

- Repo worktree: **`C:\Users\trabi\Claude\Projects\Telegram\repo-v12.11`** (branch `ix/v12.13`, HEAD 96128b8 = tag
  `v3.4.18-ix.12.13`). For new work: `git checkout -b ix/v12.14 ix/v12.13` there. Leave `ix/v12.12-nas-draft` alone;
  `repo-v12.7` belongs to a finished session.
- Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env.sh` (absolute path) before `go`, from
  `repo-v12.11/core-service`. It points at a Go toolchain in an older session's scratch folder; if that is gone,
  install the Go version `core-service/go.mod` names (go1.27.x) into your own scratch folder and set
  `GOTOOLCHAIN=local`.
- Before pushing: `gofmt -l .` (CI runs it first), `go vet ./...`,
  `go test ./internal/app ./internal/engine ./internal/telegram ./internal/download` (app ~140 s; all pass at 12.13).
  Baseline failures on Windows, not regressions: `internal/backup`, `dbread`, `faststart`, `fsx`, `hash`, `config`.
- UI checks (Playwright, real `ix.html`, invented API data):
  `SP=/c/Users/trabi/AppData/Local/Temp/claude/71f159c3a9e5d4b9/63fc91bc-a626-41aa-a92f-6717bf517e6d/scratchpad;
  PYTHONPATH=$SP/pw PLAYWRIGHT_BROWSERS_PATH=$SP/pw/browsers PYTHONUTF8=1 python tests/ui/<x>.py` (e.g.
  `archive_priorities.py`, `archive_rescan_ranking.py`). If that folder is gone: `pip install --target <scratch>/pw
  playwright` and `PLAYWRIGHT_BROWSERS_PATH=<scratch>/pw/browsers python -m playwright install chromium`.
- Commit: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit …`, message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` (or the attribution the session's system reminder gives).
- Version: `core-service/internal/version/app.go` and `docs/archive-data-sample/data/manifest.json`. CHANGELOG in two
  identical copies: `CHANGELOG.md` and `core-service/internal/webassets/public/CHANGELOG.md` (release notes = the
  version's section; check with `cmp`).
- `ix-tools/` (project folder): `gh_pr.py` (`IX_VER=12.14 python -I ix-tools/gh_pr.py open BODY.md | runs | jobs ID`;
  PR body ends with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`), `ci_wait.py FULLSHA BRANCH`
  (full 40-char SHA; run in background), `ci_log.py RUN_ID "JOB NAME" OUT`, `gh_release.py` (`IX_VER=… wait | show`). No `gh` CLI; the
  scripts use the git credential (never print it).
- **CI strategy (keep it; the user dislikes repeated hour-long CI waits):** CI runs only on PRs to `main` (open a draft
  PR per version, never merge). Workflows run in parallel, so a slow mirror or a flaky test re-runs only its own job
  (re-run failed jobs via the API, never the whole run):
  - `ci.yml` "CI", split into jobs since ix.12.4:
    - Go application: gofmt, then `go test -race -timeout 50m ./...` (job limit 70 min).
    - Process E2E (30 min; pip install step limit 10 min, retries).
    - Media E2E with ffmpeg from `scripts/ci-install-ffmpeg.sh` (30 min; install 15).
    - Browser E2E against the production server (40 min; Playwright install 20).
    - Cross-builds per target.
    - Browser regression checks (25 min).
  - `ix-tests.yml` "Archive features (with ffmpeg)": only `TestIx*` in `internal/app`, `-race -timeout 50m` (job 60
    min, ffmpeg install 15).
  - `docker.yml` "Docker".
  - `release-server.yml` runs on `v*` tags only: `go test -timeout 30m ./...` before it publishes.

  The generous `-timeout` and `timeout-minutes` values exist because `-race` makes the app package slow (~140 s
  locally without race, much longer on the runners). Don't lower them. A run takes about 25–40 min; wait with
  `ci_wait.py` in the background, and batch fixes so CI runs once per version. The release run takes ~15–25 min more.
- Release (only with the user's OK): `git tag v3.4.18-ix.12.N <sha> && git push origin v3.4.18-ix.12.N`, then
  `IX_VER=… gh_release.py wait` (background) and `show`. The release workflow runs vet+tests itself; its app test
  `TestHistoryBackpressureHonorsConfiguredStallDeadline` can flake: re-run only the failed job
  (`POST /repos/whothis44/telegram-media-downloader/actions/runs/<id>/rerun-failed-jobs`), then `wait` again.
- Live reading: `E:\T\tg-dl\data\ixreports\latest.txt` (redacted report, every 10 min) and hourly
  `YYYY-MM-DD_HH.txt` (48 kept); `data\crashes\running` (version, start) and `data\crashes\history.jsonl` (each run's
  end: "clean" or not); pacer hours `data\sessions\native\*.pace-hours.json` (print numbers only; examples of read-only live queries:
  `ix-tools/live_q*.py`). A report written
  just after a restart covers only the time since it.
- Notes folder (shared with earlier sessions): `C:\Users\trabi\AppData\Local\Claude-Data\claude_pzs8sxrjxfjjc\side-session-notes\local_46479689-1733-4e8d-ace2-cc62b72929b9\`
  (`ix12.13-logs.md` = the latest log evaluation; `ix12.13-check-rate-challenge.md`, `ix12.12-challenge.md`).

## State

| Version | Tag / commit | State |
|---|---|---|
| ix.12.11 | e0afb2b | ran 11-06 17:00–21:09, ended clean |
| ix.12.12 | a61c8d4, PR #24 | live since 11-06 21:09:55 (as of the 12.13 release) |
| **ix.12.13** | **`v3.4.18-ix.12.13` = 96128b8**, branch `ix/v12.13`, draft PR #25 | published 11-07 05:35Z; **installed and live since 11-07 01:16:33 local (06:16Z)**; 12.12 ended clean 01:15:48. At 06:18Z the in-download check had made 0 checks (2 min after start): verify it checks in the next hours. |

## First thing to do

1. 12.13 is live (verified 11-07 06:18Z: `data\crashes\running` = 3.4.18-ix.12.13, 12.12 ended clean). Fix the
   privacy bug (open item 0) first, as 12.14, with the user's OK to publish.
2. Read the first reports after install (`latest.txt`), especially the new line
   **"big videos checked in their download (on) since start: N (held at the back X: copies, partly the same; no match;
   check failed, downloaded anyway: by reason) · MB of parts · s added a check on average · downloaded without a
   check: by reason"**. Expect 10–25% of front checks to be copies; checks add ~3–5 s in no-limit hours, ~150 s under
   the speed limit. Warning signs: "downloaded without a check" dominated by one reason (esp. "checks busy", "let go
   before", "program error"), many "check failed" of one kind, downloads/hour dropping vs 12.12, rows stuck
   `processing`, crashes. If it misbehaves, the user can switch it off in the dashboard (Settings → "Check each big
   video as the first step of its own download"); tell the user, never change the live setting yourself.
3. Also check: "decoder cuda" stays (not "cpu") on the video index line; the "rescan: N group(s) added (…)" log lines
   when the user uses Priorities → "Add it to the rescan"; no `document_<digits>` in the report.

## What 12.13 changed (where the code is)

- **In-download sampled check (Task 7, the user's design).** `download.Library.Check` hook
  (`internal/download/library.go`, called after `Substitute`, before staging; skipped when a part of an earlier attempt
  exists, `partOfAttempt` in `resume.go`) → `app.ixDlCheck` (`internal/app/ix_dl_check.go`). The row comes via ctx
  (`ixWithDlCheck` in `ixIngestWork`, `ix_lowq.go`; not when a lower quality is downloaded instead). A copy (or, in an
  unranked group with HoldForever off, a partly-same video) returns `*telegram.DownloadDeferred`
  (`internal/telegram/download_defer.go`); the engine (`controller.go`, after the sink) calls
  `WorkStore.FinishDeferred` (`engine/work.go`): one transaction sets the row `pending`, `paused=1`, refunds the
  attempt, and the Hold callback writes `ix_held` + `ix_copy_hold`. Stale claim or hold failure → normal cancelled
  Finish (row pending, unpaused; `holdFailed` set stops repeat deferral this run). Any check failure → download.
  - Reads go through the download's own client (`ixRemoteFile.ReadPart`) with `telegram.WithFileCheckRank`; the
    attempt budget is paused during the check (`PauseBudget`); hard limit 10 min; `recover`.
  - At most 6 checks at once (`ixDlCheckSlots`); a video waiting >2 min for one downloads ("checks busy").
  - Skips: rows let go before or held now (`ix_held` with `released_at>0` or `reason<>''` — **NOT** the "looked at"
    rows `reason='' AND released_at=-1` that `ixHeldTriage` writes for every pending big video; the review caught
    that bug before release); rows with a recorded answer (confirmed / recorded partial → deferred again from the
    record; other answers → download); a failed non-final record gets one more try (tries<2).
  - Parts: kept on disk as in 12.11 (`ixPartsKeep`); in memory (`ixMemParts`) only if the disk store didn't keep them,
    dropped when the ingest returns; `ixKeptPartsFor` (`ix_part_store.go`) reads memory first, then disk.
  - Setting `checkInDownload` (`ixSettings.CheckInDownloadOn()`, default on, `ix_safety.go`; checkbox in `ix.html`).
    With it on, the background sample checks (`ix_copies_ml.go` work hook) run for **held videos only**.
  - Check's ffmpeg uses `-threads 1`. Report line from `ixDlCheckLine` appended in `ixCopiesDiag` (`ix_copies.go`;
    `ix_copies_test.go` pins 7 lines now).
  - Tests: `engine/defer_ix1213_test.go`, `app/ix1213_dl_check_test.go`.
- **Report redaction (Task 1)** `app/ix_diag.go`: digits ≥6 anywhere, mixed hex ≥8 (`ixHideHex`), more extensions,
  paths after `>`. Tests: guard + `TestIx1213GeneratedNamesAreHidden`.
- **GPU fallback (Task 5)** `app/ix_vdup.go` `ixVdupStep`: a GPU failure counts only if the CPU retry succeeds.
- **Ranked partly-same videos (Task 4, user-approved)** `app/ix_partial_ranked.go`: `ixReleasePartialRanked` each held
  step; `ixSampleRecord` doesn't hold partials in ranked groups.
- **Rescan/Priorities (Task 6 + user reports)**: refused "Add it to the rescan" stays visible (`ix.html`
  `pr-rescan-missing`) and every add is logged (`ix_api.go`); `ixGroupCoverage.InRescan`, unranked rescan groups listed
  first with a one-click "Add them to the end of the ranking" (`pr-rank-rescan`); a note after adding in Rescan says
  whether they were ranked; "not fully read" only when never read (`ix_coverage.go`).
- **Forum-topic filter list** (`app/dialogs_api.go` `handleDialogTopics` → `ixArchiveTopics`): when Telegram refuses
  (frozen account) the archive's recorded topics (`ix_topics`, `ix_messages.topic_id>1`) are listed.

## Open items (in priority order; confirm with the user before building)

0. **PRIVACY BUG, fix first (found 11-07 after 12.13 installed): the report still leaks parts of file names.** Lines
   from `app/ix_subst.go:435` ("not downloading %s #%d: same bytes as %s (%s)") showed e.g.
   `G203/videos/<words of a file name> <name><file>`: when a file name contains a name the redactor already replaced
   by `<name>` (`ixRedactor.clean` replaces names first), `ixReUnix` (`app/ix_diag.go`) stops at `<` (its classes
   exclude `<>`), so the path is not hidden, and `ixReFile` then hides only the tail after the last `>`. The words
   before the placeholder leak. Fix: allow `<` `>` inside the path token in `ixReUnix` (both character classes), or
   run the path/file rules over the text with placeholders treated as ordinary characters; then add guard values like
   `G1/videos/Some Words ` + chat + `_005_More Words_2021.mp4` and `G1/videos/_iCaps` + chat + `.mp4` to
   `ix127_redact_guard_test.go` (leaks: the invented words). Until released, the user should not share
   `data\ixreports` files (told 11-07). Do not print report lines matching "same bytes as" to the user while checking.

1. **Watch 12.13** (above). The user said the in-download check is the priority and wanted it out while Telegram's
   speed limit was off (at 04:39Z the report showed 21 MB/s "now").
2. **High CPU and reads all the time** (unexplained): every hourly report since 11-06 15:00 shows the process reading
   ~900–990 MB/s and 250–290% of one core (before 15:00 on 12.8: ~480–585 MB/s, ~120%), across 12.8–12.12, with the
   video index idle. Probably repeated SQLite reads from the OS cache (queue/coverage/slot queries over ~32,600 queued
   rows); unconfirmed. Find the hot queries before changing anything (e.g. a pprof CPU profile or statement timing in
   a test with a big synthetic queue). Not a crash risk on its own (heap ~810 MB steady).
3. **DC1 slowness in no-limit hours** (11-06 03:00–08:00: DC1 0.4–1.5 MB/s per part in flight vs DC4 4–4.8) — the 12.12
   per-server time line ("time per server, seconds summed over parts: … answered, failed, waits (speed-limit sleeps),
   rate limit, other") will answer it in the next full no-limit hours. `paceByAnswers` stays **off** unless that line
   gives evidence (the user fears losing overnight hours); never change it yourself.
4. **Rank-33 group never queued (Task 6)**: a basic ranked group (3,162 media messages, 180 files saved, one
   messages-only walk 11-03, no files pass, no job since). The add path works in tests; 12.13 now shows any refusal and
   logs every add. Ask the user to click "Add it to the rescan" once on 12.13 and read the page message; check the
   report for "rescan: … added" / "refused" and for a new `ix_walks`/`tgdl_history_jobs` row (counts only).
5. **Task 3 (low, the user's request)**: Rescan → Choose groups: a filter to hide channels/supergroups (type from
   `telegram/dialogs.go` for "Show all my chats"; configured groups need a type added server-side from known data, no
   new Telegram request per group; unknown type stays visible); ticks survive the filter, say how many ticked are
   hidden; remember the toggle in localStorage with try/catch. Not built.
6. **Per-topic priority** (the user asked whether a topic can be prioritised): not possible today (ranking is per
   group; the topic filter is a hard include/exclude). Would need a rank per topic in the scheduler
   (`ix_sched.go`, `tgdl_group_rank`, claim order `sched_order`) and the Priorities page. Offer, don't build unasked.
7. **Staging/NAS** — 11-07 05:32Z (no speed limit): staging held **2,557 files / 55.4 GB (60 GB on disk incl. 14
   partial downloads, 1.2 GB) against its 20 GB cap**; the copier ran the whole hour (3,621 s) and moved 9.9 GB at
   2.7 MB/s; oldest waiting 49 min. **Why (found 11-07):** the cap is soft by design.
   `download/staging.go` `StageRoom`: a download is staged if `used+size <= cap` **or** `stageRoomOnDisk` (the disk
   keeps at least `max(cap, stageFreeReserve)` free after it). With 450 GB free and a 20 GB cap, staging could grow
   until ~50 GB free. Only past both does a download go straight to the library (`StageBypass`). The Settings text
   ("When the space below is used up, new downloads wait for copies to finish") is wrong, and the user finds the
   setting "super counterintuitive" (raising it to 250 GB *shrank* staging's room). **Agreed fix for 12.14 (confirm
   with the user):** replace "Space it may use" with one plain setting, **"Keep at least N GB free on this disk"**
   (default 50): a download is staged while the disk keeps N GB free after it, otherwise it goes straight to the
   library. Keep the old value working on upgrade (old cap ≤50 → N=50; old cap >50 → N=old cap, the same behaviour)
   and show "staging may use about X GB more now". Test `StageRoom` both ways. The user set the
   cap to 250 GB on 11-07 ~01:00 local, then was advised to set it back to 20 (≤50 gives staging the most room: it
   stops at ~50 GB free); check which value is live in the next report ("local staging on (up to N GB)"). Earlier: copier ~9–10 GB/h at best; on heavy days the backlog grows. Track "local staging … waiting",
   "oldest waiting", "straight to the library because staging was full" in no-limit hours.
8. **Priorities ETA cosmetics** (user screenshot 11-07): a ranked group with 0 still needed shows "about 10–17 min
   from now": `prioEta` (`ix.html`) uses the cumulative bytes through the group (`cum`), so it shows when the groups
   above finish. Show nothing (or "nothing left") when the group's own needed is 0. The small "still needed" counts
   with "Queue 0, N held back" were the partly-same videos held at the back: 12.13 releases them in ranked groups —
   verify after install that those counts drop and "Queue" shows them.
9. **"Check for updates now" (the user asked 11-07).** There is none: the update check is cached for
   `ixUpdateCheckEvery` (1 h, `app/ix_update.go:48,160`); the page only shows the "Version X is out → Update when
   downloads finish" banner (`ix.html` `updateBanner`, actions `start|cancel|now` in `handleIxUpdateAction`). Add an
   action `check` that ignores the hour (at most once a minute: GitHub's anonymous API limit is 60/h per IP, shared
   with `ix-update.ps1`), and a small "Check for updates" button on the Archive page that shows "You have the latest
   (X)" or the banner. Small; test the throttle.
10. Background, from the 12.13 review of checks: the claim gate / parallel background checks are not needed now that
   checks run in downloads. The kept-parts reuse is confirmed working (72 MB in 8 downloads, 0 refused, 12.12).

## Live numbers at the 12.13 release (11-07 04:39Z report, counts only)

- Queue 32,627 files / 2,322.8 GB (forecast): at the last 24 h speed (13.9 GB/h) everything fits with ~4,971 GB to
  spare; if the speed limit stays on (4.8 GB/h) 32,556 files / 2,270.2 GB finish (what misses: held copies at the back).
- Set aside 30,909 (copies 17,973, private/smaller first 12,904); ready 1,698; downloading 21.
- Errors: 5–6× -503 Timeout, 3× FILE_REFERENCE_EXPIRED (usual background); failed 7, given up 5.
- Big-video background checks on 12.12: 9–11 an hour, 0–3 copies an hour, 1,977 waiting at 200 MB+.
- Video index 51,969/51,969, 69 errors (files ffmpeg cannot open), fell back to "cpu" again on 12.12 (fixed in 12.13).
- Rescan queue 53–54 groups: 30 done, 19 waiting files (unranked), a few reading messages; 38 ranked groups.
- Forum topics recorded: 91 named topics in 8 groups.

## Gotchas learned

- SQLite cannot split `tgdl_work.identity` (NUL-separated); match `ix_messages.media_key` (kind:id:size) instead.
- `ix_held` rows with `reason=''`, `released_at=-1` mean only "looked at" by triage; "held" is `released_at=0 AND
  reason<>''`; "let go" is `released_at>0`. `ixHoldWork` never re-holds a let-go row.
- `ixHoldWork`/`ixLetGo` only change `pending` rows; a row being downloaded is `processing`.
- Config group IDs are JSON numbers; most groups here are stored without the -100 prefix; queue, ranks and config use
  the same form. Never print one.
- `Controller.OpenHistory`/`openMessages` take `c.opMu`: don't call them from inside a download worker (deadlock risk
  with Stop); use the download's own client.
- Tests pin report line counts: update on purpose.
- The user's attention is limited this week (usage nearly exhausted): keep reports short, numbers first, one clear
  recommendation, and ask before anything that changes the archive.
