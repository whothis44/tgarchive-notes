# Handoff: ix.12.3 built and pushed, not tagged (2026-11-05, evening)

Repo: `C:\Users\trabi\Claude\Projects\Telegram\repo`, branch **`ix/v12.3`** (from `93b7dd6`, head `f89d100`): **pushed;
draft PR #15 is open only to run CI (do not merge); not tagged**.

Added later the same evening: pacer judging by answer time (`paceByAnswers`, off by default, with fallbacks; off, each
hour records where it would have decided otherwise); per server and hour, parts in flight, waiting, window and large-file
slots; crash capture (`TGDL_CRASH_CAPTURE=1`, the program supervises itself and keeps the runtime's crash words). The
user has a new `start.bat` in the project folder with both settings, to swap in only while the window is closed.
Item 4 (one ffmpeg "Conversion failed!" check, connection turnover) is not started. Version in the code: `3.4.18-ix.12.3`, service worker `v34185`.
Read `HANDOFF-ix12.md` for the rules (live install `E:\T\tg-dl` is read-only for us; publishing installs on the
user's archive at its next start; the user's OK first).

## Release state

| Version | State |
|---|---|
| ix.12.1 | Live since 14:25; no crash since (before: one every 2–3 h). |
| ix.12.2 | Published 15:22 by the other session. **Not installed yet**: the app has not restarted since 14:25. |
| ix.12.3 | Built here. Publish only after ix.12.2 is seen working live, with the user's OK. |

## What ix.12.3 does (see CHANGELOG)

- Resume from 8 MiB, checkpoint every 8 MiB or 30 s (`download/manager.go`); resume in the staging folder
  (`tgdl_part_progress.stage_dir`, `download/resume.go`, `staging.go`). Real-process kill tests for staging
  (`resume_ix123_test.go`). Mutation checks: 6 of 7 caught; the missed one (`partKept` limited to the library) is a
  guard against a path collision that 128-bit random names make practically impossible.
- Stop at a checkpoint (`telegram.WithCheckpointStop`, `ErrDownloadStopped`): used by the update drain and by pausing
  a downloading file (`engine.PauseJob`). Nearly finished (≤ 8 MiB left) and small files finish.
- "Install updates automatically" (`autoUpdate`, `app/ix_update.go`): needs `TGDL_LAUNCHER_RESTARTS=1`; gives up after
  20 min and retries after 1 h; going back by hand leaves that version alone.
- Archive layout: one place per control, as the user approved (`ARCHIVE-LAYOUT-PROPOSAL.md`). Same setting keys.
  `tests/ui/archive_layout.py` checks each moved control.
- Queue in download order (`engine/snapshot.go` claim order + `order`; `queue.js` default sort "download").
- Diagnostics: per-DC MB and speed-limit waits per hour (`PaceHour.DCBytes/DCPremium`); 5-min speeds first;
  freeze lines labelled apart.
- Fixes: ffmpeg ≥ 7 frame times (per-output metadata files instead of interleaved showinfo lines; was the
  `TestIxFFmpegFramesAtTheRightTimes` flake); lesser copies of queued files count as probable; ranked groups with
  files nobody queues get a one-click rescan; console `Â·`; "after 0s".
- NAS measurement behind 8 MiB: sync 6–8 ms; 8 MiB cost 2–5 % only at 23 MB/s flat out; 2 MiB about 13 %.

## The user must do (before relying on it)

- To use automatic updates: add `set TGDL_LAUNCHER_RESTARTS=1` to `start.bat` before `:run`, then restart the window.
- Staging is now safe to turn on (it resumes), but nothing obliges it.

## Not done

- Crash cause words into a file (handoff item 5): needs `watchdog.ps1`/`ix-update.ps1` to tee stderr. Those scripts are
  not updated by the updater, PowerShell 5.1 piping of native stderr changes behaviour, so it was left out to avoid
  breaking the launcher. Do it only with a tested script the user installs by hand.
- Connection turnover (item 8), per-server limit and volume-allowance questions (items 9–11): measure from the new
  per-server diagnostics once ix.12.3 is live.

## Live observations (read-only counts, 18:00)

- Speed limit on 06:00–16:00 (about 1–4 GB/h), lifted at 17:00 (11.7 GB/h) **without** a quiet stretch first.
- All 25 transfers were files over 20 MB, none small: the stall ix.12.2 fixes.
- Since ix.12.1: 104 big-video checks, 0 timeouts, 1 ffmpeg "Conversion failed!" after 68 MB of parts; 31 previews.
- Unlimited hours: the allowed parts were full 92–100 % of the time at about 2 in flight. Unproven whether the
  pacer holds those hours back; worth measuring (handoff item 11).

## Tests

- Go: everything passes on Windows except the known baseline packages (backup, config, dbread,
  faststart, fsx, hash). `TestIxLostStagedFileIsQueuedAgain` flakes on Windows (file still open), old code too.
  `TestIxRealVideosNearDuplicates` needs ffmpeg on PATH, not only FFMPEG_PATH.
- UI (Playwright, `PYTHONUTF8=1`): all 7 scripts in `tests/ui/` pass, including the new `archive_layout.py` and
  `queue_download_order.py`. The previous session's Playwright install is in its scratchpad `pw/`.
