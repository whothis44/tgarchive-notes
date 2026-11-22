# Handoff: ix.12.7–12.8 done, ix.12.9 to build (2026-11-06, ~12:40 local)

Self-contained. Then read `HANDOFF-ix12.md` (standing rules, still valid), `HANDOFF-ix12.7.md` (the 12.7 plan,
for background only) and the project memory (`C:\Users\trabi\.claude\projects\C--Users-trabi-Claude-Projects-Telegram\memory\`).
Repo: worktree `C:\Users\trabi\Claude\Projects\Telegram\repo-v12.7` (branches ix/v12.7, ix/v12.8; currently on
ix/v12.8). Create **ix/v12.9 from the tag `v3.4.18-ix.12.8`** (bcaeeb9). Live install `E:\T\tg-dl`.
Account: non-Premium, frozen since 10-31, **deletion 2026-11-30**.

**The goal:** save as much useful, distinct content as possible before the account disappears. Every change is
judged by that. A crash or a bad restart costs more than most improvements gain: keep changes small and measured.

## Rules that matter most

- **Live install: read only.** Never stop, restart, replace or edit it (the user allowed one edit on 11-06 while
  away: `ix-update.ps1` was replaced, old kept as `ix-update.ps1.before-ix12.7`; that permission is spent).
- **Publishing installs on the user's archive.** The app checks for a release about hourly, lets downloads finish
  (at most 20 min; files of 8 MB+ stop at a checkpoint), exits, and the launcher (`start.bat` loop) runs
  `ix-update.ps1` and starts the new version. Tag only with the user's explicit OK for that version. Auto mode
  blocked the first tag push on 11-06 ("Create Public Surface"); it went through once the user wrote
  "Explicit permission given". Don't work around a block: ask.
- Never merge a PR or push `main` (still `93b7dd6`). PRs #16–#20 are draft, CI-only. Open the 12.9 PR the same way
  (CI only runs on pull requests to main).
- **Privacy:** media, names, chats are private. Read the live DB only with `file:E:/T/tg-dl/data/db.sqlite?mode=ro`,
  print counts and categories only; mask anything from `error`/`note` columns. Folder names under
  `data\tgdl-staging` and the paths in `start.bat` are private: don't print them (filter output). Tests use invented
  data. The diagnostics report must never show a name (`ix127_redact_guard_test.go` checks every `ixLog` format).
- **Claims:** no speed claim without measurement; "looks like", not "is", for one day's evidence.
- **Copies design** (probable copies held at the back) is deliberate: act on evidence it ignores, don't redesign.
- Batch changes, test locally first; the user dislikes repeated hour-long CI waits. The release workflow runs
  `go vet` and `go test ./...` itself before it publishes.
- On Windows, heredocs mangle `\n` and `\r\n` inside scripts: write edit scripts to files with the Write tool, or
  use the Edit tool. Python text mode writes CRLF unless `newline=''`. `*.ps1`/`*.bat` are CRLF (.gitattributes).

## State

| Version | Tag / commit | State |
|---|---|---|
| ix.12.6 | `v3.4.18-ix.12.6` / 98021ae | live since 11-06 07:39, no crash (still live at 12:25) |
| ix.12.7 | branch ix/v12.7, fa4e1c5, PR #19 | all CI green; **never tagged** (shipped inside 12.8) |
| ix.12.8 | `v3.4.18-ix.12.8` / bcaeeb9, branch ix/v12.8, PR #20 | **published 11-06 ~12:00**, GitHub "latest"; release notes say it includes 12.7. Expected live by ~13:20 |

**First thing:** check 12.8 went live: `E:\T\tg-dl\data\crashes\running` (version, start time),
`data\crashes\history.jsonl` (12.6's run should end "clean"). If it isn't live, find out why without touching the
app: GitHub limit (`https://api.github.com/rate_limit`, 60/h per IP, was 60/60 at 12:24), the app's hourly check
(`app/ix_update.go`: ixUpdateCheckEvery 1 h, auto-drain ≤ 20 min then retry after 1 h).

New in 12.8: **`E:\T\tg-dl\data\ixreports\latest.txt`** (the redacted diagnostics report, every 10 min, first save
2 min after start) and hourly copies `YYYY-MM-DD_HH.txt` (48 kept). Read these instead of asking for the dashboard
login (the `/api/ix/diagnostics` endpoint needs it).

### What 12.7 and 12.8 changed (CHANGELOG.md has the user-facing text)
- **Slot fill (12.7, `app/ix_slotfill.go`, `ix_deadline.go` ixDeadlineKeepBusy):** a claimable file counts as ready
  only if its server has a free slot of its size (5 under 20 MB, 2 larger, per server; `Controller.FileSlots`);
  set-aside files are let go into free slots on their own server, smallest band first; held copies stay held.
  Report line "file slots by server … set-aside files let go into free slots: N since start".
- **Queue limit (12.8, `app/ix_queuecap.go`, `ix_order.go` ixWaitingApart):** claimable files whose server has no
  free slot of their size don't count towards a rescan's queue limit (500), bounded together with 1 GB files waiting
  for their lane at 2× the limit. Report: "queue N of 500 (not counted: M waiting for a free slot on their server)".
- **Trade-off now active:** with rescans no longer held, keep-busy uses `limit = (workers+1)/2` while a rescan reads
  (`ix_deadline.go` ~line 516): half the workers wait for the rescan's files. Before 12.7 this was the normal state.
- 12.7 also: browser links a missing file to its saved copy, forum topic menu; report guard over all `ixLog`
  formats, "speed-limited" says which waits, `[process]`, staging copy rate, NAS reads by hour, per-server hour
  figures, fallback start–end; Organise plan "move uncatalogued copies to _trash" (`ix_uncatalogued.go`, not run by
  the user yet); dashboard update check cached; `ix-update.ps1` release-page fallback and **self-update** (the
  Windows release archive carries it, checked by SHA256SUMS, used only if it parses; `tests/ix_update_check.py`).

### Measured live on 11-06 (counts only)
- 08:03–10:43 on 12.6: about 470 claimable files on one server waited for its 2 large slots and held the rescans at
  the queue limit; small slots on the other servers idle; ~14,700 files set aside. Same at 12:25.
- Telegram's speed limit came back ~10:10: speed-limit waits per hour 547 (10:00), 899 (11:00); 0 from 03:00 to
  10:00. Pacer bytes: 9.1 GB (10:00), 2.85 GB (11:00), 0.73 GB in 12:00–12:24. In-progress files grew ~0.4 MB/s
  in total at 12:25.
- Note: `downloads.created_at` lags the network (rows are written after staging moves files to the NAS); use the
  pacer's hours (`data\sessions\native\*.pace-hours.json`: bytes, premium = speed-limit waits, waits = plain) for
  network rate. Print numbers only from that file.
- Last 48 h: 30 hours under the limit averaged 3.0 GB/h; 14 full unlimited hours 23.1 GB/h; last 24 h 248 GB.
- Left at 12:25: 28,975 files, 2.71 TB (by size: <10 MB 2,607 / 0.02 TB; 10–100 MB 20,441 / 0.71 TB;
  100–500 MB 5,098 / 1.06 TB; 500 MB–1 GB 540 / 0.40 TB; 1 GB+ 289 / 0.52 TB). Held as probable copies or originals
  of an already-saved lower quality: ~14,900 files, 1.25 TB (ix_held reason<>'' or ix_lowq state='saved').
  Ranked groups 7,822 files / 0.85 TB; unranked 21,153 / 1.85 TB.
- Rough outlook: limit on all the time → ~70 GB/day → ~1.7 TB by 11-30; on/off like 11-05/06 → everything not
  held could finish in under two weeks. The limit is Telegram's; keeping every server busy under it is ours.

### 12.8 live: first half hour (added 13:20)
- 12.6 ended clean 12:48:58; 12.8 started 12:49:38; `data\ixreports` written from 12:51 (works).
- Pacer bytes, speed limit on throughout: 11:00 2.85 GB/h and 12:00–12:24 ~1.8 GB/h on 12.6; 13:00–13:15 0.95 GB
  (~3.8 GB/h; report 1.13 MB/s over 5 min) on 12.8. Looks better; 25 minutes is not a measurement: compare full
  hours from the hourly copies.
- 25 downloading (all workers): DC1/2/4 all 7 slots, DC5 4 of 7. Each server ~0.22–0.31 MB/s whether it has 4 or 7
  files: consistent with a per-server limit (more files on a busy server add nothing; more busy servers do).
- Workers (25) now cap, not slots (28): "set-aside files let go: 2 since start". Given the per-server look, that cap
  seems to cost little; check before changing the worker count.
- Rescans still paused: "queue 503 of 500 (not counted: 1493 waiting for a free slot)": the 2× bound (1,000) is
  reached because the restart left 1,495 files ready, mostly on full servers. 27,463 files not queued yet. Decide
  with evidence whether the bound or the reserve matters now (item 1 below).

## ix.12.9: proposed to the user (they agreed to a fresh conversation for it; confirm the order with them)

1. **Measure 12.8, then decide the worker reserve.** From the hourly reports: per-server MB/s under the limit,
   slots used, files let go, whether rescans still pause. If the limit applies per server (it looked so on 11-05/06),
   keeping half the workers back while a rescan reads costs downloads: a rescan's files can only use their own
   server's slots. Candidate: a small fixed reserve (~3) instead of half. Change only on that evidence.
2. **Deadline forecast** in the report and Downloads card: at the last 24 h rate (pacer hours), what finishes by
   11-30 by size band and by group (ranked/unranked, held last), so the user can raise a group's rank in time. There
   is a finish-estimate "ahead of held copies" line from 12.5: find it and build on it.
3. **Cheap records complete:** every message's text indexed and a thumbnail or preview for every media item, so
   files that miss the deadline still leave a record. Measure coverage first (ix_messages; `downloads.telegram_thumb`;
   `data\ixthumbs`, `data\ixpreviews`: see `app/ix_copies_ml.go`); find where they're made, don't guess.
4. **Lower quality first for big videos** where Telegram offers one (`ix_lowq`: originals wait to replace a saved
   lower quality): measure how much of the 1.9 TB in files over 100 MB it covers.
5. Still for the user to decide (low priority while the waits are speed-limit ones): the plain-FLOOD_WAIT fallback
   length (2 h, `telegram/floodguard.go` premiumFallbackFor); `paceByAnswers`.
6. **Forum topic subfolders (user asked 11-06 13:30).** Today a file goes to `<group>/<type>/`
   (`download/library.go` destinationParts; the download Item carries no topic). Proposed:
   `Group/<Topic name>/videos/…` for new downloads of forum groups, plus a reversible Organise plan (counts first,
   checked moves, undo, like `ix_uncatalogued.go`) that moves files already downloaded. The plan needs no account,
   so it can run even after 11-30 (topics: ix_messages.topic_id, ix_topics titles). Below the goal items in
   priority (organises, doesn't save more). Confirm with the user first; Claude's suggestions: layout
   Group/Topic/type; General stays in `Group/type`; the folder keeps the topic name it had at its first file
   (no moves on rename). Keep adoption of hand-moved files (orphansFor), the uncatalogued plan and duplicate checks
   working with the new folder (they call destinationParts or key on the folder). `safeComponent` the topic name.
7. **Workers (user asked 11-06):** not raised. The worker count adapts up to `advanced.downloader.maxConcurrency`
   (25 here; `app/monitor_api.go`) and the pacer's suggestion (3 × parts allowed + 2: 29 at 13:15); a new maximum
   applies only at the engine's next start (no restarts to test tuning). Under the speed limit each server gives
   ~0.3 MB/s with 4 or 7 files, so more workers look useless now. Re-check in an unlimited stretch: free slots
   while all workers are busy would argue for a higher cap.
8. Housekeeping: the user may run Organise → "Plan: move uncatalogued copies to _trash" (shows counts first).
   Draft PRs #16–#20 can be closed (never merged).

No "13": no redesign before 11-30.

## Tools

- `C:\Users\trabi\Claude\Projects\Telegram\ix-tools\`:
  - `env.sh`: `source` it in Git Bash for Go (GOTOOLCHAIN=local) from an older session's scratch folder.
  - `gh_pr.py` (`IX_VER=12.9 python -I gh_pr.py open BODY.md | runs | jobs RUN_ID`) and `gh_release.py`
    (`wait | show | note`): GitHub API with the sign-in stored for git; never print the token. No `gh` CLI here.
  - `live_q*.py`: the read-only live queries used on 11-06 (numbers only).
- If that scratch folder is gone: install Go matching `core-service/go.mod` (go1.27.x) and Playwright for Python
  (`pip install playwright` + `playwright install chromium`) into the new session's scratch folder.
- Playwright UI checks: `PYTHONPATH=<scratch>/pw PLAYWRIGHT_BROWSERS_PATH=<scratch>/pw/browsers PYTHONUTF8=1 python
  tests/ui/<x>.py` with `<scratch>` = `C:/Users/trabi/AppData/Local/Temp/claude/71f159c3a9e5d4b9/63fc91bc-a626-41aa-a92f-6717bf517e6d/scratchpad`.
- Tests: `go test ./internal/app ./internal/engine ./internal/telegram ./internal/download` (all pass on 12.8;
  app ~105 s). Failures also on the baseline (not regressions): `internal/backup`, `dbread`, `faststart`, `fsx`,
  `hash`, `config` on Windows. `TestIxLostStagedFileIsQueuedAgain` flakes rarely on Windows.
- Commits: `git -c user.name="Claude" -c user.email="noreply@anthropic.com" commit`, ending with the
  Co-Authored-By line from the session's attribution reminder. Version in `core-service/internal/version/app.go`,
  `docs/archive-data-sample/data/manifest.json`; CHANGELOG.md and `core-service/internal/webassets/public/CHANGELOG.md`
  must stay identical. The release notes are the version's CHANGELOG section.
- A check of the live state was scheduled from the 12.7/12.8 conversation for 13:18 (trig_01QV6FYNQQVn3yApn1uChr4k);
  it reports there, not in the new conversation.
