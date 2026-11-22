# Handoff: Telegram archive fork, ix.11.1 release and next work

Written so a fresh session can resume if usage ran out. Verify everything with git and the GitHub API before acting: this reflects the state when it was written (2026-11-04, about 23:35 local), and work may have moved on since.

Repo checkout: `C:\Users\trabi\Claude\Projects\Telegram\repo`. Remote: `whothis44/telegram-media-downloader` (public; pushing works with stored git credentials; no `gh` CLI). Commit identity: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, with a `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` trailer.

Go 1.27.3 is at `<scratchpad>\gotool\go\bin`, and `env.sh` in the scratchpad sets PATH, GOPATH, GOCACHE. Scratchpad: `C:\Users\trabi\AppData\Local\Temp\claude\71f159c3a9e5d4b9\63fc91bc-a626-41aa-a92f-6717bf517e6d\scratchpad`. If it has gone, reinstall from go.dev (verify the published SHA-256).

Standing constraints are in memory (`telegram-capture-constraints`). In short: the account stays non-Premium, use synthetic data only, make no live speed claims, the live install at `E:\T\tg-dl` is read-only for you (never stop or replace it), and only the downloader is meant to be on the VPN. Never commit the real `start.bat` (private paths).

> **Status 2026-11-05, 00:45: Step 1 is done.** `v3.4.18-ix.11.1` is published and verified. Step 2 is built, tested and pushed on `ix/v11.2-update-resume` (`d748c47`, version ix.12), with a local package in `dist`. **Do not merge, tag or release ix.12 unless the user asks:** their updater would install it by itself, and it has not been run against live Telegram.

## Step 1: release ix.11.1 (the user approved publishing)

Release commit: `073d387` on branch `ix/v11-group-priority`, **already pushed to main**. CI was running when this was updated: go straight to step 3 below. The race run on `1e5f035` was clean except for one rare test flake, fixed in `073d387` (a once-a-minute safety loop overwrote a test's global setting).

1. **Check the final test run:** `<scratchpad>\final.log` (Docker, Linux, race detector, ffmpeg, commit `1e5f035`). If it is missing or incomplete, rerun `run-final.sh` the way it was run:
   `docker run --rm -v "C:\Users\trabi\Claude\Projects\Telegram\repo:/src:ro" -v "<scratchpad>\baseline:/baseline" -v "<scratchpad>\run-final.sh:/run-final.sh:ro" -v tgdl-gomod:/go/pkg/mod -v tgdl-gocache:/root/.cache/go-build golang:1.27.3 bash /run-final.sh`
   That copy is taken from the working tree, so check out `1e5f035` in a separate worktree and mount that instead if the checkout has moved on.
   The archive package takes about 25 minutes.
   - Known, not caused by this work: `TestIxFFmpegFramesAtTheRightTimes` can flake with the `keyframes` message. It also flakes on the baseline (1 in 8).
   - Anything else failing: investigate and fix before publishing. Never publish a failing build.
2. **Push to main:** `git push origin ix/v11-group-priority` then `git push origin ix/v11-group-priority:main` (a fast-forward from `f5168c9`). Check first that main has not moved. Dependabot could have added commits, and in that case merge rather than force. Never force-push.
3. **Wait for CI:** workflows `CI` and `Archive features (with ffmpeg)`. Public read: `https://api.github.com/repos/whothis44/telegram-media-downloader/actions/runs?per_page=10`. CI time limits were raised to 50 minutes. If `Archive features` fails only on the frames flake, rerunning needs sign-in, so judge from the known flake. Say plainly that it was a flake rather than calling it green.
4. **Tag and release:** `git tag v3.4.18-ix.11.1 <main commit>` and `git push origin v3.4.18-ix.11.1`. This triggers `Release native server`. The tag version must match `AppVersion` in `core-service/internal/version/app.go`.
5. **Verify:** release `v3.4.18-ix.11.1` is `latest` and has `tgdl-server-v3.4.18-ix.11.1-windows-amd64.tar.gz` and `SHA256SUMS`. Download that archive into a new empty scratch folder, check its checksum, and confirm `tgdl-server.exe version` prints `3.4.18-ix.11.1`.

The user's running install updates itself at its next start, so nothing needs touching there. Their morning instructions were: close the window and reopen `start.bat`, or skip it, since the only change is the faster Priorities tab. The local package is in `C:\Users\trabi\Claude\Projects\Telegram\dist`.

## Step 2: in-app update button, then durable resume (the user approved both, in that order)

Work on branch `ix/v11.2-update-resume` (update button committed; resume in progress there, see git log). Merge `ix/v11-group-priority` into it after step 1 and bump the version to the next ix number. Release them separately, after step 1. Do not put either feature in the ix.11.1 release.

### Update button that waits

- Show when a newer release exists. Reuse the number-by-number comparison in `ix-update.ps1` (`Test-Newer`), written in Go. Cache the GitHub check.
- Clicking Update drains: an in-memory `draining` flag on `engine.Controller` stops workers claiming new rows. Files only waiting for a slot give way through the existing `telegram.ErrDownloadYield` path (their `yield` should also return true while draining).
- **Do not use the queue pause for this.** `SetQueuePaused(false)` clears every row's pause, which would release held copies and set-aside files.
- Show progress such as "waiting on 3 files, about 2 GB left", with **Update now** (exit straight away) and **Cancel** (stop draining).
- Once nothing is left, exit cleanly so the launcher updates and restarts. `cmd/tgdl-server/main.go` owns the signal context and the shutdown.
- **Exiting only restarts if a launcher loops.** Add a marker to `start.example.bat` (for example `set TGDL_LAUNCHER_RESTARTS=1`). Without the marker, never exit: tell the user it is ready and to close the window and reopen `start.bat`. The user's own `start.bat` lacks the marker, so they need one added line (it is not in the repo, so give them the line).
- Admin only. Put it on the Archive page. The existing `/api/update/status` in `internal/app/update_api.go` is for Docker: read it first and do not break it.

### Durable resume

Parts are written strictly in order (`telegram.fetchParallel`), so a checkpoint is one offset.

- **State:** a new table (for example `tgdl_part_progress`) in `store/engine_schema.sql`, holding identity, relative path, size, offset, SHA-256 of the prefix, updated time. A database row gives no sidecar files on the NAS for the library scanners to trip over, and state stays bounded and visible.
- **Names are random per attempt** (`destinationName` adds random hex). Look up the row by group, message and identity, then reuse its stored relative path.
- **Checkpoint** in `download.Manager.transfer`: for files of at least about 64 MiB, every 64 MiB and only on a 1 MiB part boundary (Telegram needs aligned offsets). Order matters: write data, `Sync`, then commit the row, so the row never claims more than is durable.
- **Resume:** check the identity and size match, re-read and hash the prefix, compare with the stored SHA-256, truncate to the offset, and feed the prefix into the library's digest (`hashClient` in `library.go` and `staging.go`) so the final hash covers the whole file. On any mismatch, discard and start from zero.
- **Keep the part on failure** when a checkpoint exists; today `transfer` removes it on every error. Discard it on a size mismatch. Delete the row after publishing.
- **Offset plumbing:** a context value such as `telegram.WithDownloadOffset`, read in `GotdClient.DownloadMedia`, which then uses `fetchParallel` from that offset (the gotd downloader cannot start at an offset). Check capability through the wrappers (like `PartSourceOf`): a transport that does not support resume must start from zero, never append. Skip resume when `TGDL_VERIFY_CHUNKS` is on.
- **Cleanup:** `Library.Recover` removes rows and parts whose row is no longer pending or that are stale. `recoverStaging` deletes `.tgdl-*.part` files, so keep those that have a progress row.
- **Crash tests (required before release):** stop at deterministic points, including between data sync and row commit. Assert exact bytes and no refetch of committed ranges. Also cover changed identity or size, a corrupted prefix, a missing part file, an expired file reference and a cancelled attempt. Use invented bytes and a fake `UploadGetFile`.

## Reporting

Finish with what was published (commit, tag, and whether the Windows archive was verified), test results including anything still flaky, and what is left. Do not claim a live speed improvement. If anything could not be finished, say so plainly.
