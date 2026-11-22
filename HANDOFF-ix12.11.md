# Handoff: build ix.12.11 (2026-11-06, evening)

Self-contained. Read first: `PLAN-ix12.11.md` (what to build and why, with measured numbers), then the standing
rules in `HANDOFF-ix12.9.md` ("Rules that matter most" and "Tools") and `HANDOFF-ix12.md`, and the project
memory (`C:\Users\trabi\.claude\projects\C--Users-trabi-Claude-Projects-Telegram\memory\`).

**Goal (unchanged):** save as much useful, distinct content as possible before the account is deleted on
2026-11-30. A crash or a bad restart costs more than most improvements gain: keep changes small and tested.

## State

| Version | Tag / commit | State |
|---|---|---|
| ix.12.8 | `v3.4.18-ix.12.8` / bcaeeb9 | live since 11-06 12:49 |
| ix.12.9 | `v3.4.18-ix.12.9` / 992889b, PR #21 | **published 11-06 ~16:45**, installs itself within the hour |
| ix.12.10 | branch `ix/v12.10` / 6612e6c, PR #22 | CI running; **the other session publishes it when green** (the user asked). Do not tag it yourself. |

Repo worktree: `C:\Users\trabi\Claude\Projects\Telegram\repo-v12.7`. Create **`ix/v12.11` from `ix/v12.10`**
(`git checkout -b ix/v12.11 ix/v12.10`). If 12.10's CI needed a fix commit, branch from the newest
`ix/v12.10` (check `git log origin/ix/v12.10`).

## What 12.9 and 12.10 changed (context for 12.11)
- 12.9: forecast to the deletion date (`ix_forecast.go`); previews of files not downloaded keep coming under the
  speed limit (10 s gap, `ix_previews_all.go`); one-time repair of 2,423 queue rows marked done before ix.10.2
  with nothing saved, reopened as held probable copies (`ix_unlinked.go`).
- 12.10: a big-video check keeps its sampled frames (`ix_copy_sample.frames`, `dur_ms`) and "no match" videos are
  compared again locally when saved videos get fingerprints (`ix_sample_recheck.go`); checks get 3 minutes in 10
  while downloads are busy (`ix_remote_budget.go`, `ixRemoteBudgetSample`); a report line "big-video checks:
  last hour … last 24 h … waiting for a check … turn …" (`ixSampleRateDiag`); forum topic folders
  (`ix_topic_dirs.go`, `download.Item.Topic`, `destinationParts`) with an Organise plan; Organise moves now
  repoint `ix_held`, `ix_msg_link`, `ix_subst`, `ix_vfp`, `ix_pdq`, `ix_lowq`, `ix_fixity` (`ixRepointRefs`).

## 12.11 in short (details in PLAN-ix12.11.md)
1. Keep the 1 MiB parts a check fetched (`ixRangeFile.parts` in `ix_copies_sample.go`) on disk, keyed by the
   Telegram identity; cap 4 GB; nothing kept under 20 GB free on the data disk (68 GB free on 11-06).
2. Downloads take kept parts in `telegram.fetchParallelFrom` (`parallel_download.go`; called from
   `downloadMedia` in `attachment.go`, which knows the identity) via a hook the app sets; length and SHA-256
   checked on read, anything doubtful fetched from Telegram.
3. Remove kept parts once the file is downloaded, its queue row is gone, or over the cap (oldest first).
4. Step the check floor (`ixSampleMinSize`, 200 MB) down 200 → 100 → 50 → 20 MB only when nothing at or above
   the current step waits for a check (`ixSampleDueOf`); report the floor in use.
5. Report: MB of parts reused from checks.
Then CHANGELOG (both copies identical), version `3.4.18-ix.12.11` in `core-service/internal/version/app.go`
and `docs/archive-data-sample/data/manifest.json`, commit, push, draft CI-only PR. **Publishing needs the
user's explicit OK for 12.11** (they approved 12.9 and 12.10 only).

## Lessons from 11-06 (avoid repeating)
- **CI runs `gofmt -l .` first** and fails on any file; run it locally before pushing (12.9 lost one CI round).
- **SQLite cannot split `tgdl_work.identity`** (kind NUL id NUL size) with `instr(...char(0))`: it silently
  matches nothing. Match on `ix_messages.media_key` (kind:id:size) or split in Go. An early count was 5× wrong.
- Tests pin old constants (a share bound, a report line count): when a constant or a report line changes on
  purpose, update those tests and say so.
- `source` the Go env with its absolute path: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env.sh`
  (a relative path failed silently in a background run, and the "passing" run had not run at all).
- Version comparison is numeric in both the app (`ixVersionNewer`) and `ix-update.ps1` (`Test-Newer`): 12.10 >
  12.9, 12.11 > 12.10.
- Live DB: read-only URI, counts only; never print names, paths or file names from the live archive.

## Tools (in `ix-tools`)
- `env.sh` (Go 1.27.3), `gh_pr.py` (`IX_VER=12.11 python -I gh_pr.py open BODY.md | runs | jobs RUN_ID`),
  `gh_release.py` (`IX_VER=… wait | show`).
- `ci_wait.py SHA BRANCH`: waits for every CI run of a commit (run in the background; prints results; a failed
  run lists its jobs). `ci_log.py RUN_ID "JOB NAME" OUTFILE`: saves a job's log (follows GitHub's redirect
  without the token) and prints failing test lines.
- Tests: `go test ./internal/app ./internal/engine ./internal/telegram ./internal/download` (app ~115 s).
  Baseline failures on Windows (not regressions): `internal/backup`, `dbread`, `faststart`, `fsx`, `hash`, `config`.
