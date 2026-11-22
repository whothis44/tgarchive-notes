# Start of an integrator session (lean version, 11-21; the old text is `START-INTEGRATOR-old-2026-11-21.md`)

The owner pastes: "Read `START-INTEGRATOR.md` and do what it says." You are the integrator (Opus): you merge into
`claude/charming-feynman-vm2xia`, run the whole test suites once per batch, ship each batch to the owner, and keep
`BOARD.md` and `MERGE-QUEUE.md` short. You build nothing yourself; scripts and agents do the mechanical steps.

## First turn
1. Read `CLAUDE.md`, `BOARD.md`, `MERGE-QUEUE.md`, and the newest state block of `SESSION-11-PROGRESS.md`.
2. Check against the disk: `git -C repo-archiver fetch private`, the head against `private`, `git status`,
   `git worktree list`. Measure usage (`get_usage`) and the PC's free memory.
3. Tell the owner in about ten lines: what is merged since the last integrator, what is listed, what each track is on,
   what waits for the owner, the usage percentage.
4. **Tell every running track session that you are the integrator now**, one short message each (their ids are in the
   newest take-over block of `SESSION-11-PROGRESS.md`), so their reports and listings come to you, not to the session
   before you. Then archive the integrator before you (the standing rule).
5. Start a fresh session for each track that has work and no running session (`start_session`, context fresh; its
   prompt: "Read `BOARD.md`, take over the <track> track from its progress file, and carry on", plus two lines on what
   changed and what comes first), then `detach_session` it. This turn is the owner's, so the starts are allowed.

## Each batch
1. When one or more entries are READY in `MERGE-QUEUE.md`: read each entry and the risky part of its diff (anything
   that writes to Telegram, skips or releases files, or touches the download path).
2. Make the combined tree in a copy of your own: `ix-tools/batch-tree.sh <name> "<base:head ...>" "<packages>" "<named>"`
   (base and head as 8-character hashes). A piece that conflicts: join it by hand in the copy (or with an Opus agent,
   "keep both" only), as a tentative commit, and give that commit as its head. Schema steps take the next free number in
   merge order: set the later step's "after" constant and its test's comparison.
3. Whole runs once on that tree: the whole `internal/collector` and `internal/catalog`, and the packages the batch
   touches or that open a catalogue; the viewer's change-log tests by name when `internal/catalog` changed. Packages
   with a slash in the name (`collector/livepages`, `exact/wire`) are run by path in a command of your own (`full-runs.sh`
   skips them). A failure is run by name on the same tree before it is called load.
4. `ix-tools/merge-batch.sh <head, 8 chars> <tested tree> <pieces file>`: one commit a piece, pushed, the merged tree
   checked against the tested one. The pieces file's commit message paths are absolute.
5. Build the second folder: `bash runs-int-i6/folder-next.sh`. When a piece changes what the owner sees or a schema
   step, give the owner the update command (pages' `deploy/folder`) with one line on what changes.
6. Update: the board's own row, the schema line, the queue (mark merged), three lines in your progress file, one notes
   commit. Tell the tracks whose branches the head moved under, by direct message.

## The notes' backup (the owner, 11-22)
The notes (this folder's top-level `.md`/`.sql`, branch `notes`) are backed up to the private repo
`whothis44/tgarchive-notes` (remote `backup`) as snapshot commits only; the local history never goes up. After the notes
commit of each batch: `bash ix-tools/notes-backup/backup.sh`. It checks every file against both catalogues' real names,
usernames and ids (read-only), personal emails and secrets, and refuses on any hit, printing counts and file names only.
A refusal for names: `REDACT=1 python -I ix-tools/notes-backup/scan_names.py . repo-archiver/archiver wt-v12.32`
replaces them with "[name removed]" (never shown), then commit and run the backup again. Real chat names, titles,
contents or ids never go into the notes at all (CLAUDE.md).

## Practical
- Go: `source ix-tools/env-archiver.sh` (it names the app folder's ffmpeg); `GOMEMLIMIT=1GiB GOMAXPROCS=2 GOFLAGS=-p=2`.
  Keep about 2 GB free. The whole collector takes 30 to 35 minutes (`-timeout 45m`).
- Text with a Windows path goes through the Write or Edit tool, or `chr(92)` in a script, never through a shell string.
- Never stop the owner's app or write to the owner's folder; never push `main`, never tag.
- Wait for runs with a background command that ends on the result, not with turns that poll.
- Usage: say the percentage to the owner at each batch; when it runs low, tell the tracks to list what they have and
  write their state.
- **The test-runner PC (the owner's second PC, since 11-22):** `ix-tools/remote-run.sh <name> <commit> "<packages>" <out>` sends a
  commit as a git bundle over SSH (`trabi@10.0.0.124`, DHCP: the name `gaminglaptop` may work if the address moves) and runs whole
  packages there (Go 1.27.3 with our runtime patch, 16 GB free). Use it for the whole `internal/collector` while this PC runs the rest.
  No archive data and no Telegram sign-in there. Docker on it only for race runs, started and stopped each time.
- **The second PC is used only when it is measured faster (the owner's standing rule, 11-22: "If the second PC is too slow to be effective, stop using it").** Before sending a whole run there, time one small package on both PCs (`internal/supply` named set or `internal/mirror`); use it only if it is at least as fast, and never with a second run or the tester's app open at the same time. On 11-22 its whole catalog took over 45 minutes against 15 to 19 here: an i9-13900HX in the laptop's "Balance" mode at 68% performance, with Windows Defender scanning every test file (no exclusion there; this PC has one), and the tester's app running beside it.
  **Measured 11-22 01:45, after the owner's Defender exclusion and Performance mode:** `internal/supply` 183 s there (warm cache), 120 s here on a quiet PC, 194 to 297 s here under load. So: NO whole runs there (not faster); it is the tester's PC and runs the race detector in Docker.
