# Brief NA3: the app on the NAS, its Docker files (NAS track, N-1, 2026-11-22)

**Why:** the owner decided the whole collector runs headless on the NAS and the PC's app is its dashboard
(`C:\Users\trabi\Claude\Projects\Telegram\DESIGN-NAS-autonomous.md`: read it whole, with section 5's measured limits).
This piece is section 6 (a): the deploy files only. **No product code changes** (if a flag the collector lacks is
needed, say exactly which; do not add it). No review needed (deploy files), so make them exact.

**Rules:** you are the Opus coder. Nothing is built for or copied to the NAS, nothing runs against Telegram; a local
`docker build` and a start on this PC with invented data and `--network none` is allowed to check the files work (keep
2 GB of the PC free; C: is nearly full: clean up every image, container and volume you make). Every go command through
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-nas-n1/go1.sh <folder> <command ...>`. **Where:**
`git -C C:/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add ../wt-nas-app -b wip/nas-app private/claude/charming-feynman-vm2xia`;
commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `wip/nas-app` to `private`.

## What exists
`deploy/nasdl` (N3: Dockerfile FROM scratch, compose in host mode, user 1000:10, read-only root, `cap_drop: [ALL]`,
`no-new-privileges`, limits, the heartbeat health check, the certificates mount, README in the owner's order),
`deploy/nashelper`, `deploy/thumbs`, `deploy/folder` (the PC's folder build). The collector's commands and flags:
`internal/collector/command.go` (`run`, `-pages`, `-pages-addr`, the data folder). The way to Telegram:
`collector.telegram_way` (NA2, `wip/nas-ctunnel`, listed: "tunnel" is the default on Linux and needs a WireGuard file
with a DNS line in the collector's folder). The watchdog (`cmd/tgarchive-watchdog`), the backup (`cmd/tgarchive-backup`),
the viewer (`cmd/tgarchive viewer`). The rule: the collector and the NAS downloader never share one WireGuard key.

## What to build: `deploy/nas-app`
- **Dockerfile:** static Linux binaries (collector, watchdog, backup, the main program for the viewer), a small base with
  no shell at run time; ffmpeg NOT in this image (its own later).
- **compose.yaml:** two services, both `network_mode: host`, no `ports:`, `user: "1000:10"`, `read_only: true`,
  `cap_drop: [ALL]`, `no-new-privileges`, `pids_limit`, restart unless stopped:
  (1) **collector**, under the watchdog if the watchdog runs it on Linux (check; else the collector alone with the
  container's restart), `mem_limit: 768m`, `GOMEMLIMIT=512MiB`, `cpus: 2`; volumes: the app's data folder (catalogue,
  sessions and keys, settings, the WireGuard file; on the NAS's own disk, NEVER a share: SQLite on a share is unsafe; a
  comment says so), the library folder read-write, an optional staging folder, the certificates read-only; its pages on
  `127.0.0.1` for now (the PC reaches them in a later piece); (2) **viewer**, `mem_limit: 1g`, `GOMEMLIMIT=600MiB`, one
  thumbnail maker, the data folder and the library READ-ONLY, on `127.0.0.1` for now. Health checks that open no
  network connection where possible (a heartbeat file, as N3).
- **README.md** in the owner's order, full commands, from any folder: make the folders on the NAS's own disk with
  `sudo chown -R 1000:10` and 700/600 modes; put the Windscribe WireGuard file (with its DNS line; a DIFFERENT file from
  the NAS downloader's, if both are ever used); load the image; start; check (`ss -tn | grep -E '149\.154\.|91\.108\.'`
  prints nothing); stop. Say plainly that the move of the catalogue and login from the PC is a later step of the app,
  and that until then this runs on a NEW, empty data folder only.
- **settings example** for the collector's first start on the NAS (the way "tunnel", the folders), if the collector
  reads one; else say how its settings are set.

## Hand back
On `wip/nas-app`, pushed. Report in at most 15 lines: the files, what you checked by a local build and start (and that
you cleaned up), any flag or behaviour the collector lacks for headless use; then stop.
