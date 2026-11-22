# START HERE: everything a new session needs for this project

Written 2026-11-08 for a fresh assistant account working in this folder (`C:\Users\trabi\Claude\Projects\Telegram`). Read
this whole file first, then **`HANDOFF-ix12.28.md`** (current state: 12.28 live, the speed-limit findings, what to watch for, and the
next ideas; `HANDOFF-ix12.24.md` has 12.23–12.27), then **`PRE-PUSH-CHECKLIST.md`** before any push. Older `HANDOFF-ix*.md` files are history: read them only
for background. A memory folder may also exist at
`C:\Users\trabi\.claude\projects\C--Users-trabi-Claude-Projects-Telegram\memory\` (MEMORY.md and the files it lists).
It says the same things in short. If it is there, keep it up to date; if it is not, this file is complete without it.

Times: "local" is the user's EST (UTC-5). Report timestamps are UTC (Z) unless marked local.

---

## 1. The goal

- **The fork:** `whothis44/tg1` on GitHub (PRIVATE since 11-13; the public fork whothis44/telegram-media-downloader was deleted at the owner's request; releases are installed by hand, since the updater asks GitHub without signing in), with our releases tagged `v3.4.18-ix.<n>`. It is a Go server
  (`core-service/`) with dashboard pages embedded, which the user runs to archive Telegram groups (photos, videos, files)
  to their own disks and NAS.
- **Goal: save as much distinct, useful content as possible before the Telegram account is deleted on 2026-11-30.** The
  primary measure is **the fastest downloads**. Secondary: a usable UI and media browser.
- **The account** is **non-Premium** and **frozen since 2026-10-31**: it can still read and download, but some methods are refused.
  Telegram's speed limit for non-Premium accounts (FLOOD_PREMIUM_WAIT) is on for most hours and lifts for a few hours at
  a time. With the limit about 1.5–2.5 GB an hour; without it 50–103 GB an hour (record 103 GB, 11-08 17:00 local).
- **A crash or a bad restart costs more than most improvements.** Make small, tested, reviewed changes, batched into one release.

## 2. Hard rules (the user's standing rules; never break them)

### Privacy (the media is private)
- **Never open the live dashboard pages, the real media viewer, or any real media or file to look at it.** That includes
  the user's own browser tabs on the dashboard. For any UI work or bug, work from code and **invented data only**: the browser
  checks in `tests/ui/*.py`, run with `ix-tools/ui.sh`, load invented data from a fake origin (`http://archive.test`).
- **The live install `E:\T\tg-dl` is read-only.** Never stop, restart, replace or edit the app, its files or its settings.
  - You may read:
    - `E:\T\tg-dl\data\ixreports\latest.txt`, the hourly diagnostics report, already privacy-redacted, with older ones beside it;
    - `E:\T\tg-dl\data\crashes\running` and `history.jsonl`;
    - the database, **only** as `file:E:/T/tg-dl/data/db.sqlite?mode=ro` (sqlite URI, read-only).
  - From any of these, **print only counts, categories, sizes, timings and versions.** Never print group or chat names, message
    text, file names, paths, IDs, links, user names, or anything else that identifies content or people.
  - **Never print report lines containing "same bytes as"** (they name files).
  - Never print folder names under `data\tgdl-staging`.
- **`start.bat` holds private storage paths**: never commit it, print it, or replace it with a generic one. `start.example.bat`
  in the repo is the public template.
- The start.bat console (`ixLog`, at most one line a minute) prints full names by design. Only the report is redacted. Any new
  `ixLog` call must use a **constant format string** (a test, `ix127_redact_guard_test.go`, enforces it). Report lines carry
  **numbers only**.
- Tests, fixtures, screenshots and commit messages use invented names only ("Group 17", "Topic 3", `invented-*`).
- Never need the live sessions or secret key. Never read `data\sessions\` or `data\secret.key`.

### The archive and Telegram
- **Never bypass Telegram's waits.** Never add sessions or accounts, never restart the app to test tuning, never test the
  downloader outside the VPN, and never change VPN settings. (Only the downloader is on the VPN, Windscribe WireGuard; other
  programs on WiFi is intended.)
- **No new Telegram requests without measuring them.** Requests are scarce: downloads get FLOOD_WAITs. Anything that turns a
  person's action (a ranking, a click) into new Telegram reads needs the user's explicit OK, with the cost spelled out. Never
  change a group's download filters as a side effect.
- **Copies:** probable copies are **held at the back, never skipped**, and a held copy never goes before a unique file, not even
  for a ranked group or topic. The design is deliberate: improve it by acting on evidence it ignores, not by redesigning it.
  Duplicate matches are probabilistic; a timeout is "unknown", never a match or non-match; sampled or visual matches are
  "probable", never "exact".
- **Transfers:** keep request timeouts when excluding waits from budgets. Do not cancel active transfers just to honour a
  ranking.
- **Prefer removing work over adding delays.** The user rejected slowing the 250 ms queue polls to 2 s. Any added wait per file
  adds up ("2 seconds for each file over a day will accumulate a lot").
- Keep `paceByAnswers` **off** (the user's choice). Ranking a topic must not move its group up the rescan lanes or add the group
  to the rescan by itself.

### Claims
- No speed claim without measurement. One night's or one day's numbers are "looks like", not proof. Compare like with like
  (hours without the speed limit are rare and episodic). No universal MB/s, daily quota or reset hour; the 2–8 part window
  and similar numbers are local choices, not Telegram limits. Event counters cover different windows and overlap across
  requests.

### Git, pushing and publishing
- **Publishing installs on the user's archive:** its launcher (`start.bat` → `ix-update.ps1`) installs any newer release, and
  the app checks GitHub hourly and drains itself (up to 20 min) to update. So:
  - **Tag and publish only with the user's explicit OK for that version.** The OK for 12.19 does not carry over to 12.20.
  - **Pushing a branch also needs the user's OK.**
  - PRs are **draft, CI-only** ("ix.<n> (CI only, do not merge)"). **Never merge a PR. Never push `main`** (it stays at
    `93b7dd6`).
- Commit identity (no git identity is configured on this PC):
  `git -c user.name=Claude -c user.email=noreply@anthropic.com commit …`, with a message ending
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. PR bodies end with
  `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.
- Never use bare `git stash` (the stash is shared across worktrees); use a WIP commit instead.

### Working with the user
- Their attention is limited: short reports, numbers first, one clear recommendation, plain words, and ask before anything that
  changes the archive. Say plainly what was not verified.
- They work in the desktop app and sometimes over Remote Control from a phone: put the answer and any question in the closing
  message.
- The user asks for **independent challenger reviews** (a separate read-only agent) of every download-path change and of UI
  changes before release. They have caught crashes, a media failure storm, mislabelled "exact" copies and design
  showstoppers. Use them, and fix what they confirm before pushing.

## 3. Where things stand (2026-11-11; details in HANDOFF-ix12.28.md)
| Version | Tag = commit | Branch / worktree | State |
|---|---|---|---|
| ix.12.19 | `v3.4.18-ix.12.19` = cea1925 | `ix/v12.19` in `repo-v12.16` | live since 11-08 16:15:45 local; draft CI-only PR #31 |
| ix.12.20 | see HANDOFF-ix12.21.md | `ix/v12.20` in `repo-v12.16` | ran 11-09 04:11-11:31 |
| ix.12.21 | `v3.4.18-ix.12.21` = 99b22d4 | `ix/v12.21` in `repo-v12.16` | ran 11-09 11:31-20:49 |
| ix.12.22 | `v3.4.18-ix.12.22` = 77a7bda | `ix/v12.22` in `repo-v12.16` | live since 11-09 20:50:30; draft CI-only PR #34 |
| ix.12.23 | `v3.4.18-ix.12.23` = 6457af3 | `ix/v12.23` in `repo-v12.16` | live since 11-10 01:58:31 (12.22 ended clean); draft CI-only PR #35 |
| ix.12.24 | `v3.4.18-ix.12.24` = 9907fe8 | `ix/v12.24` in `repo-v12.16` | live since 11-10 16:18:23 (12.23 ended clean); draft CI-only PR #36 |
| ix.12.25 | `v3.4.18-ix.12.25` = 6edc4bd | `ix/v12.25` in `repo-v12.16` | live since 11-10 21:49:41 (installed by the user by hand; 12.24 ended clean); draft CI-only PR #37 |
| ix.12.26 | `v3.4.18-ix.12.26` = e027c8e | `ix/v12.26` in `repo-v12.16` | published 11-10 (release job re-run after a flaky test); draft CI-only PR #38; the user installs it by hand |
| ix.12.27 | `v3.4.18-ix.12.27` = 66cdc26 | `ix/v12.27` in `repo-v12.16` | published 11-11; draft CI-only PR #39; live since 11-11 00:37:18 (12.26 ended clean) |
| ix.12.28 | `v3.4.18-ix.12.28` = 999a4af | `ix/v12.28` in `repo-v12.16` | published 11-11; draft CI-only PR #40: speed-limit fallback rule; live since 11-11 02:46:26 (12.27 ended clean) |
| **ix.12.29** | `v3.4.18-ix.12.29` = 34d051e | **`ix/v12.29` in `repo-v12.16`** | published 11-12 (release 43159549147, latest); draft CI-only PR #41: idle-server top-up fed within seconds (index, quick looks); findings in `FINDINGS-ix12.29.md`, `ANSWERS-ix12.29.md` |

- Next: read 12.29 in hours without the speed limit (FINDINGS-ix12.29.md section 5). Further work branches from `ix/v12.29`.
- Other worktrees (`repo`, `repo-v12.5`, `repo-v12.7`, `repo-v12.11`) are old versions: leave them alone and don't switch
  their branches.

## 4. This machine and its tools
- **Windows 11.** Shells: Git Bash (POSIX; preferred for scripts) and PowerShell 5.1. Shell working directories reset often:
  **use absolute paths.**
- **Go 1.27.3:** `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env.sh` puts it on PATH. It lives in an old session's
  temp folder (`…\AppData\Local\Temp\claude\…\63fc91bc-…\scratchpad\gotool\go`). If that folder has been cleaned, ask the
  user before downloading a Go toolchain again (downloads need their OK), and update env.sh. This Go has **no cgo**, so
  `go test -race` cannot run natively; use race.sh.
- **Race detector:** `ix-tools/race.sh WORKTREE PACKAGES… [-- go test flags]` runs `go test -race` in the local Docker image
  `golang:1.27.3` (already on this PC, 1.31 GB; never pull another image without the user's OK). The worktree and module cache
  are mounted read-only and there is no network. Examples:
  `bash ix-tools/race.sh repo-v12.16 ./internal/telegram ./internal/engine`;
  `bash ix-tools/race.sh repo-v12.16 ./internal/app -- -run 'Ix1219|IxUpdate' -count=2`.
  The whole app package takes about 25 min under -race, so run your tests plus those of the files you touched.
- **Browser checks (Playwright, local):** `bash ix-tools/ui.sh WORKTREE [tests/ui/x.py …]`; with no tests it runs every check
  CI lists in `.github/workflows/ci.yml` (16 at 12.19). It uses the venv `ix-tools/pwvenv` and browsers `ix-tools/pw-browsers`.
  Invented data only.
- **Python:** 3.10 on PATH; run scripts with `python -I`. Write edit scripts with the file-writing tool rather than shell
  heredocs (heredocs can mangle `\n`), and write files with `newline=''`: repo files are LF (git turns `ix-update.ps1` into
  CRLF on checkout). A Bash `cat > file` with no input hangs. Set `PYTHONUTF8=1` for scripts that print non-ASCII.
- **ffmpeg:** env.sh puts none on PATH, so real-ffmpeg tests skip. To run them:
  `export PATH="/c/Users/trabi/AppData/Local/WhisperJAV/Library/bin:$PATH"`. That build has no WebP encoder, so
  `TestRenderGalleryThumbStill` fails with it on every version. CI (static ffmpeg with WebP) is the tiebreaker.
- **GitHub:** there is no `gh` CLI. The helpers use the GitHub credential stored for git (`git credential fill`) and never
  print it:
  - `IX_VER=12.20 python -I ix-tools/gh_pr.py open BODY.md | runs | jobs RUN_ID` (opens the draft CI-only PR for branch
    `ix/v12.20`);
  - `PYTHONUTF8=1 python -I ix-tools/ci_wait.py FULL_SHA BRANCH` (run it in the background; it waits for every workflow on
    that commit);
  - `PYTHONUTF8=1 python -I ix-tools/ci_log.py RUN_ID "JOB NAME" OUT` (a failed job's log);
  - `IX_VER=12.20 PYTHONUTF8=1 python -I ix-tools/gh_release.py wait | show` (the release workflow after a tag; `show` lists
    the archives and "latest").

  The app's own PR tools cannot bind this repo (the session folder is not the checkout), so use ci_wait.py. GitHub's
  anonymous API limit (60 an hour per IP) is shared with the user's updater: use the helpers, which are authenticated.
- **Live read-only queries:** `ix-tools/live_q*.py` (sqlite read-only, counts only). Check what a script prints before
  running it.

## 5. The code (worktree `repo-v12.16`, Go module in `core-service/`)
- `internal/telegram/`: the MTProto client (gotd) and the download path:
  - `pacer.go` (per-server window of parts in flight; the 2-part floor; cuts for waits), `pacer_hours.go` (per-hour
    counters for the report);
  - `floodguard.go` (Telegram's waits: per request, per-server gates, escalation, the automatic fallback to 12.17's waits);
  - `route.go`, `route_home.go` (main and media addresses, the router);
  - `attachment.go` (the part invoker, hooks to the pacer), `parallel_download.go` (`fetchParallelKept`, `fetchPart`:
    -503 retries 1→16 s, 20 tries);
  - `timeout_aside.go` (12.19's set-aside of a file its server keeps timing out on), `kept_parts.go`.
- `internal/engine/`: claims and work rows: `controller.go` (an attempt's end: deferred, yield, stop, FLOOD_WAIT and
  set-aside reschedule without spending an attempt), `work.go` (the `tgdl_work` table).
- `internal/download/`: library and staging: `staging.go` (local staging, then copying to the NAS library), `resume.go`
  (keeping partial downloads of 8 MiB or more), `manager.go`, `library.go`.
- `internal/app/`: the archive features, all `ix_*.go`:
  - the report: `ix_diag.go`, `ix_diag_hours.go`, `ix_reportfile.go`; its redaction is guarded by `ix127_redact_guard_test.go`;
  - updates and backups: `ix_update.go`, `ix_preupdate.go` (12.19: the copy before each update and the version pin),
    `ix_backup.go` (nightly backup to the NAS);
  - the rescan queue and lanes: `ix_queue.go`, `ix_stall.go` (watchdog);
  - copies and holds: `ix_held.go`, `ix_copies_*.go`, `ix_dl_check.go` (in-download check);
  - the browser: `ix_browse.go`, `ix_browse_api.go`, `ix_relations.go` (12.19: cross-references and the album view);
  - settings: `ix_safety.go` (the `ixSettings` struct and parsing), applied to the engine in `ix_biglane.go`
    `ixApplyEngineSettings`;
  - the pages: `ixassets/ix.html` (dashboard, Groups tab, Settings), `ixassets/browse.html` (media browser).
- `internal/store/migrate.go`: the schema. Any schema change also needs `./internal/store` tests (its old-schema migration
  tests).
- Version: `core-service/internal/version/app.go` and `docs/archive-data-sample/data/manifest.json`. CHANGELOG has **two
  identical copies**: `CHANGELOG.md` and `core-service/internal/webassets/public/CHANGELOG.md` (check with `cmp`).
- Updater: `ix-update.ps1` (run by start.bat before every start; moves forward only, checks SHA256SUMS, honours
  `data\ix-update.pin`), checked by `tests/ix_update_check.py` (Windows, needs Go).
- CI: `.github/workflows/ci.yml` (Go, browser checks), `ix-tests.yml` (archive features with ffmpeg), `docker.yml`;
  `release-server.yml` runs on a tag and builds 8 archives plus SHA256SUMS.

## 6. Building and testing (follow PRE-PUSH-CHECKLIST.md; summary)
1. `source …/ix-tools/env.sh; cd …/repo-v12.16/core-service`; `"$(go env GOROOT)/bin/gofmt" -l .` must print nothing
   (`gofmt` alone is not on PATH); `go vet ./...`.
2. `go test -count=1`, one package at a time:
   - always `./internal/app` (about 120–180 s), `./internal/engine`, `./internal/telegram` and `./internal/download`;
   - `./internal/store` whenever the schema changes;
   - `./internal/webassets` and `./internal/api` when pages change.

   Put the `cd` inside a background command's command group.
3. Run race.sh on every changed package, and on the changed app tests.
4. Browser checks: `ix-tools/ui.sh repo-v12.16` when pages or their APIs change. Updater check:
   `PYTHONUTF8=1 python tests/ix_update_check.py` when `ix-update.ps1` changes.
5. Run new tests with `-count=5` or more. Read them for the patterns that caused every CI-only failure so far:
   - package variables changed while the test app's background loops read them;
   - `App` fields assigned after start;
   - callbacks appending to shared slices without a lock;
   - tests racing the app's own loops: the update loop, staging mover, held copies and previews all run inside `ixTestApp`;
   - assertions on timing under load.
- **Windows baseline failures, not regressions:** `internal/backup`, `config`, `dbread`, `faststart`, `fsx`, `hash`.
- **Known flaky tests** (check alone before blaming a change):
  - `TestIx127LibraryReadsByHour` (a global hourly counter);
  - `TestIxMLParallelismSettlesNearTheService` and `TestHistoryCapIgnoresItemsWaitingApart` (both fail under load; the
    second passed 40/40 alone);
  - `TestHistoryBackpressureHonorsConfiguredStallDeadline` (release CI flake: re-run only the failed job);
  - `TestRenderGalleryThumbStill` (fails only with the WhisperJAV ffmpeg).

## 7. Release flow (each step that changes GitHub needs the user's OK for that version)
1. On the branch: version bump in both files, CHANGELOG entry in both copies (plain language, numbers measured, "looks like"
   where not proven), and all of section 6 clean.
2. With the user's OK to push: `git -C repo-v12.16 push origin ix/v12.20`, then
   `IX_VER=12.20 python -I ix-tools/gh_pr.py open BODY.md` (draft, CI only), then `ci_wait.py <full sha> ix/v12.20` in the
   background. Expect CI, Archive features (with ffmpeg) and Docker to succeed, in 30–50 min.
3. With the user's OK to publish, and only when CI is green:
   `git -C repo-v12.16 tag v3.4.18-ix.12.20 <sha> && git -C repo-v12.16 push origin v3.4.18-ix.12.20`, then
   `IX_VER=12.20 PYTHONUTF8=1 python -I ix-tools/gh_release.py wait`, then `show`. Check for 8 archives, SHA256SUMS and
   "latest: v3.4.18-ix.12.20".
4. Verify the install (within about 1.5 h): `E:\T\tg-dl\data\crashes\running` shows the new version, `history.jsonl` shows the
   previous one ended `"how":"clean"`, and the report's `update:` line says "running 3.4.18-ix.12.20". From 12.19 on, the
   exiting version first makes `data\backups\pre-update-<old version>_<time>\` (db, sessions, secret.key; last 3 kept). That
   folder is local to the user's data disk: never read inside it.
5. Rolling back: the user writes `data\ix-update.pin` naming the version (e.g. `3.4.18-ix.12.19`) and restarts. That is the
   user's to do, never ours.

## 8. Reading the live report (counts only)
- `latest.txt` sections:
  - `[settings]`;
  - `[restarts]` (crashes, clean stops);
  - `recent errors` (frozen/deactivated refusals);
  - `[process]` (CPU %, reads/writes per 10 min);
  - `[cpu]` (profile; thread time, not CPU use);
  - `download state` (ready, downloading, retry later, set aside, speed-limit waits in the last 10 min);
  - `file parts by route` (per server: home, media on or no media address; escalations; automatic fallbacks);
  - `last 24 h` and `by hour` lines. One line per hour, newest first, local time. It holds:
    - GB, files, plain waits, speed-limit waits, per-server MB, parts in flight / allowed / waiting;
    - time per server (in flight, answered, failed by kind, -503 seconds);
    - room and tries (room unused, nothing in the way, speed limit, held by another server's wait, climbs);
    - routes per server (-503 per 1,000, KB per slot-second, retries after a -503, files with a -503, run ends:
      answered / set aside / gave up / cancelled, run lengths);
    - held per server (gate seconds by cause);
  - `update:` line;
  - staging line (waiting GB/files, copied last hour, MB/s per copy, copies at once);
  - copies and dedup lines.
- Use `grep`/`cut` to pull numbers. **Never print a line with "same bytes as"**, and don't paste whole sections that might
  hold names: the report is redacted, but print only the numbers you need.
- The key figures and their history up to 12.19 are in HANDOFF-ix12.19.md and HANDOFF-ix12.20.md (compare against those).

## 9. Known facts worth not rediscovering
- **Servers:**
  - Files live on DC1, DC2, DC4 and DC5; this archive has never had a file on DC3.
  - The home server is DC1.
  - Telegram gives no media address for DC1 or DC5, so media routes run only on DC2/DC4 (+3–9% there, no -503s).
- **-503 Timeout answers** come in server-side storms, mostly on DC1/DC5. First retries are often answered; second and
  later retries almost never are.
- **12.17's shared files gate** let one server's plain wait hold every server. 12.18 fixed it; 12.19 fixed the counter that
  still showed it.
- **Under Telegram's speed limit** each server gets its own ~15 s waits (FLOOD_PREMIUM_WAIT, held by the one request
  since 12.4) and brings about 0.3–0.6 MB/s, about 0.6 GB an hour each. It looks like a limit per server, but that is not proven.
  It does not go away with fewer parts at once.
- **Staging:** downloads go to a local staging disk, then copies go to the NAS at about 1.9–2.1 MB/s per copy.
  - The setting is 6 copies at once, but only about 3.3 ran on average on 11-08.
  - The backlog grows in unlimited hours (223 GB at 18:49 local on 11-08).
  - When staging is full, new downloads go straight to the library (12.6).
- **CPU:** 12.15 205–250%, 12.16 114–150%, 12.17 82–139%, 12.19 110–148% in an unlimited hour.
- **Updates:** the app's update check runs hourly, so a new release takes up to about 1.5 h to install.

## 10. If something looks wrong on the live archive
- Read only, and report to the user with numbers. Never restart or change anything yourself.
- Login errors (AUTH_KEY_*, SESSION_*) after a release: tell the user at once. The setting "Do not use Telegram's media
  servers" turns the second login client and the media pools off.
- DC2/DC4 plain waits growing, or escalations or automatic fallbacks appearing: tell the user. The setting "Make every server
  wait when one is asked to wait" brings back 12.17's waits and cuts.
- A file kept timing out for ever: "Keep asking for a file its server keeps timing out on" turns 12.19's set-aside off.
- A bad release: the user can pin the previous version (section 7.5).
