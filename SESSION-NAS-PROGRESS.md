# The NAS downloader track: progress (newest state only; older text in SESSION-NAS-LOG.md)

## STATE FOR A TAKE-OVER, session N-1 (Opus), 11-22 16:37: stopped by usage (99%); start from here
- **The direction (owner, 11-22, item 50 "Yes, as recommended"):** the whole app runs headless on the NAS, the PC's app
  is its dashboard; the login MOVES with the catalogue; the PC downloads nothing for a NAS-run archive.
  Design: `DESIGN-NAS-autonomous.md`. Measured: `MEASURE-NA1-memory.md` (collector 768 MiB, viewer 1 GiB, ffmpeg 512 MiB).
- **Merged (main 84e98ca):** N1-N4 (the earlier NAS downloader), NA2 (`collector.telegram_way`: system/tunnel/none),
  NA3 (`deploy/nas-app`), NA3b (old-archive refusal on NAS doors, `check` health command, `-no-staging`), NA4 (the
  pinned-key gate `tgarchive-nasgate` front/back). The NAS runs WITH a staging folder (fingerprints read staged copies).
- **NA5, the move (`tgarchive-nasmove out|in|back`), NOT LISTED:** `wip/nas-move` (copy `wt-nas-move`), first build
  50bd1206; the fix round's WORK-IN-PROGRESS commit 7b0d01c0 (main merged in at 6260d5b2) is pushed: it DOES NOT BUILD and nothing
  in it was run. Written, untested: review points 3, 5, 6, 9, 10, most of 11, the out halves of 2 and 8. NOT done: 1, the back
  half of 2, 4, 7, the placing half of 8, the -viewer and -abort flags, the README fixes, the probes as tests, all runs.
  At the split into commits: the collector re-check (lock.go, words.go, command.go) goes in a "Lent to Core (collector):"
  commit, and the bring-in refusal (internal/bringin/run.go, the viewer track's) in a lent commit of its own. Its review `REVIEW-NA5-move.md` found 4 HIGH (a copied
  bundle places the login twice; `back` takes an older round trip's bundle; -bundle around staging deletes staged files;
  the PC's old-library path breaks the NAS collector) and MED ones (backups keep the login files; a wrong key; the
  viewer's decisions.sqlite not moved). The fix round's decisions are in this file's log and in the coder's brief
  message: points 1-11 of the review, all to fix, probes in the review's scratch folder to pass. **Owed:** finish the
  fix round (the coder's hand-back at the stop says which points are done), then a SECOND review pass (logic errors),
  then list; the lent collector commit 8eb5f317 is read by the integrator (Core and pages archived).
- **Owed small:** none else. Later pieces: the launcher's button for the move and starting the PC's `back` (pages);
  thumbnails/fingerprints' ffmpeg container on the NAS; N2-N4 (the PC-run NAS downloader) kept, nothing built on them.
- **The owner's NAS steps:** tonight's tunnel speed test (M2) is on the owner's page (image in `nas-test-image/`); the
  move's steps are in `deploy/nas-app/README.md` on `wip/nas-move` and in the section below; none runs before NA5 is
  merged and the owner starts it. Nothing of this track has run on the NAS or against Telegram.
- **The owner's decision (11-22, with I-7; CLAUDE.md's NAS line, PROMPT-NA5-console.md):** the NAS containers run as a dedicated regular (non-admin) NAS user of the app's own, not 1000:10: `user: "${TGARCHIVE_UID:?}:${TGARCHIVE_GID:?}"` from a `.env`, with README steps to create that user and `chown` its folders. Applies to deploy/nas-app (collector, viewer, gate) and the NA5 README; to do in NA5's fix round.
- Tools: lock `runs-nas-n1/go1.sh`; race in Docker `runs-nas-n1/race-run.sh <copy> <cpus> <mem> <timeout> <go test args>`.

## The owner's steps for the move (for the instructions page; from `deploy/nas-app/README.md`, branch `wip/nas-move`; NOT to run before NA5 is merged and the owner starts it)
1. On the PC: build the NAS image and `tgarchive-nasmove.exe` (README's build step).
2. On the NAS: stop the test project; set its `data` and `keys` aside; keep `wireguard.conf`; make a new staging folder; point the library at the archive's own folder.
3. On the PC: quit the app; run `tgarchive-nasmove out` (it shows the counts first and says the PC's login files are then deleted, which cannot be undone); type yes; copy the bundle to the NAS with `scp -r`.
4. On the NAS: run `in` inside the image (`docker compose run ... --entrypoint /app/tgarchive-nasmove collector in ...`), then `docker compose up -d`.
5. The way back: `out` on the NAS, then `back` on the PC.

## The owner's step for tonight (sent to I-7 for the instructions page, 11-22): the tunnel's speed test on the NAS (M2)
Nothing to Telegram, no sign-in, about 1 GB. The integrator builds `tgarchive-nasdl-0.1.0.tar` (deploy/nasdl/README "Build");
the owner makes a Windscribe WireGuard file (with a DNS line; for this test only), loads the image, makes
`/volume1/<share>/nasdl-test` and `/volume2/docker/tgarchive-nasdl/data` (1000:10, data 700), copies compose.yaml,
settings.conf (listen 10.0.0.42, accounts 1) and wireguard.conf (600), then runs
`cd /volume2/docker/tgarchive-nasdl && sudo docker compose run --rm nasdl vpntest -dir /data` (never `compose up`).
Expected: the address check "different", MB/s and CPU seconds: the one open number of the tunnel on the NAS.
