# Handoff: ix.12.3 released, ix.12.4 to build (2026-11-05, 21:05 local)

Read this first, then `HANDOFF-ix12.md` (the standing rules) and the project memory. Repo:
`C:\Users\trabi\Claude\Projects\Telegram\repo`. Live install `E:\T\tg-dl`: **read it only; never stop, restart, replace or
edit it.** Its launcher installs the newest GitHub release at every start, so **publishing installs on the user's
archive: publish only with the user's OK.** Account: non-Premium, frozen, deletion date 2026-11-30.

## State

| Version | Where | State |
|---|---|---|
| ix.12.1 | tag on `289768a` | Was live from 14:25 on 11-05; no crash in 6.5 h. |
| ix.12.2 | tag on `93b7dd6` (= `main`) | Published 15:22; never installed live (skipped). |
| ix.12.3 | tag `v3.4.18-ix.12.3` on `dccc8a5`, branch `ix/v12.3` | **Published 21:00 (02:00 UTC).** Verified: the real `ix-update.ps1` moves a scratch copy of the live 12.1 to 12.3 with checksum; 12.3 starts under crash capture on a throwaway folder, serves `/metrics`, writes `crashes/window.log`. |

- `main` is still at `93b7dd6`. Draft PR #15 (`ix/v12.3` -> `main`) exists only to run CI: **do not merge without asking.** A push to `main` also runs the "Notify Telegram" workflow.
- The user is installing 12.3 with `INSTALL-ix12.3.md` (project folder): Update when downloads finish, close the window, swap in the new `start.bat` (their own + `TGDL_LAUNCHER_RESTARTS=1` + `TGDL_CRASH_CAPTURE=1`), open it. **Confirm 12.3 is live first**: `E:\T\tg-dl\core-service\tgdl-server.exe version`, process start time, `data\crashes\` (window.log present means crash capture is on).

## First: see 12.3 working live (read-only, counts only)

Ask the user for a diagnostics report after a few hours (Archive -> Settings -> Diagnostics report; it is anonymised).
Live counts can be read with `sqlite3`/Python on `file:E:/T/tg-dl/data/db.sqlite?mode=ro` and `http://127.0.0.1:3000/metrics`
(counts only). Check:
- no crash in `[restarts]`; memory: `/metrics` heap and reserved, against 12.1 (heap swung 620-1,180 MB, reserved
  flat ~2 GB over 20 min at 6 h uptime: no leak seen);
- resume: `tgdl_part_progress` count grows, files from 8 MB carry on after restarts;
- small files downloading alongside large (ix.12.2's make-room), no `ix_lowq` rows for ranked files;
- the queue page in download order; the Archive layout (each control in one tab);
- the new per-server hour lines: parts in flight vs allowed, waiting, large-file slots in use / waited for, and
  "tries judged by bytes: N bigger (answer time would have kept X that bytes refused) ...".

## ix.12.4: what to build (the user chose these for 12.4)

1. **Copies: act on evidence the current rules ignore, keeping the design.** The user stresses that the current
   method is a deliberate tradeoff to maximise the odds when some loss is inevitable: do not redesign it.
   Live counts (11-05 21:00): held on look-alike evidence never checked 9,364 (505 GB) + lesser copies of queued
   files 3,856 (347 GB); sampled and matched 281 (200 GB); **sampled with no match but still held: 161 (129 GB)**
   (notes "at most 2-4 of 8 sampled frames match"); old holds with no reason row 474 (38 GB).
   - A held video whose sampled check found no match (best below `ixSamplePartialHit`) goes back to its normal
     place; a partial match stays at the back; a failed or timed-out check is unknown and changes nothing.
     Release the existing ones once, with a report line. Code: `ixSampleRecord` in `app/ix_copies_sample.go`
     (the `j.held` branch only records "unconfirmed").
   - Check held files first (ranked groups first, then most bytes per check), within the checks' existing turns.
   - Say "matched by sampled frames", not "confirmed" (rule: sampled matches are probable).
   - Two independent switches, "Hold probable copies at the back" and "Check big videos by sampling" (today
     `holdLikely` also gates sampling), keeping "until I release them"; map old settings; keep their keys readable.
   - Finish estimate: `ixDeadlineEstimate` uses `max(queue bytes incl. held, distinct still to get)`; leave held
     and set-aside rows out of the queue figure.
   Propose the exact changes to the user before building; show what moves where in the queue.
2. **Memory, privacy kept:** a `[memory]` section in the report: heap, reserved, goroutines, and the top 10
   functions by in-use heap from `runtime/pprof` (function names and bytes only, never data). Only if 12.3 shows
   growth, or cheaply anyway.
3. **CI split** so a slow mirror or a flaky test re-runs only its own piece: separate jobs for `go test -race`,
   process E2E, media E2E (ffmpeg), browser E2E. Install limits were raised in `dccc8a5` (all install steps 10-20 min).
   `TestFTPLowRateDoesNotExpireNetworkDeadlines` (backup, 100 ms timeout) flaked once under `-race` in CI.
4. **After a day of 12.3 figures, decide with the user:**
   - `paceByAnswers` (Settings -> Downloads, experimental, off). The user remembers an earlier dynamic pacer that
     flooded Telegram, errored, or underused: switch it on only if the shadow counts show climbs missed while parts
     wait at a full window. Its fallbacks: two flood cuts in an hour -> judged by bytes for 2 h under the flooded
     window; a climb not borne out in bytes after 5 min is undone. Live windows were `{1:1, 2:1, 4:1, 5:2}`.
   - Large-file slots are 2 per server from Telegram's own config (5 small): never raise them. If some servers'
     slots sit idle while others queue, spread claims across servers (needs a row's DC before claiming).
   - The one ffmpeg "Conversion failed!" check (68 MB of parts), and connection turnover (HANDOFF-ix12 item 8).
5. Open from earlier handoffs, still undecided: whether the speed limit is per server or a volume allowance that
   recovers (11-05: limited 06:00-16:00, lifted 17:00-~18:30 for ~22 GB without a quiet stretch, limited again).

## Facts learned this session (so they are not re-derived)

- Live unlimited hours: hour totals give ~0.6-1.5 parts in flight on average against 2-14 allowed: the window may
  not be the limit; 12.3's per-server figures say.
- ffmpeg >= 7 runs each output's filters on its own thread; showinfo lines interleave. 12.3 writes each output's
  frame time to its own file (`metadata=mode=print:file=`). That was the `TestIxFFmpegFramesAtTheRightTimes` flake.
- The Go runtime prints "fatal error:" before it marks itself dying, so `SetCrashOutput` files lack the cause;
  12.3's supervisor (`cmd/tgdl-server/supervise.go`) keeps it in `crashes/cause.txt` -> run history.
- The server listens on `PORT` (default 3000), not `TGDL_CORE_PORT`.
- NAS checkpoint cost: sync 6-8 ms; 8 MiB checkpoints cost 2-5 % only at 23 MB/s flat out.
- GitHub: CI runs only on `main` pushes and PRs into `main`; releases on `v*` tags (a tag run can start a few
  minutes late; deleting a pushed tag needs the user's permission). Earlier release tags are lightweight.
- Windows test baseline failures (not regressions): backup, config, dbread, faststart, fsx, hash.
  `TestIxLostStagedFileIsQueuedAgain` can flake on Windows; `TestIxRealVideosNearDuplicates` needs ffmpeg on PATH.
- Tools: Go `source <old scratchpad>/env.sh` (the toolchain is in the 63fc91bc... scratchpad); Playwright from that
  scratchpad's `pw/` with `PYTHONPATH`, `PLAYWRIGHT_BROWSERS_PATH`, `PYTHONUTF8=1`; GitHub API through
  `git credential fill` (no `gh`). On Windows, write edit scripts to files: heredocs mangle backslashes, and Python's
  text mode writes CRLF unless `newline=''`.
