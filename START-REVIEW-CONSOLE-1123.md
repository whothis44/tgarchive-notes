# Next interactive session: review what the Console run of PROMPT-NEXT-1123-console.md did

The owner pastes: "Read `START-REVIEW-CONSOLE-1123.md` and do what it says." You are the integrator (Opus 5.5, high
effort; `START-INTEGRATOR.md` and `CLAUDE.md` apply). The Console run worked alone: check it before the owner relies
on it. Keep it lean: read diffs and logs, do not redo work that is right.

## 1. What the run did
- Its log: the newest `runs-agent\PROMPT-NEXT-1123-console-*.log` (read the final report at its end first; then
  grep it for `STOPPED`, `FAIL`, `refused`, `skip`).
- `git -C repo-archiver fetch private`; `git -C repo-archiver log --oneline <head before the run>..private/claude/charming-feynman-vm2xia`
  (the head before the run is the last one under "Fixes of 11-23" in `SESSION-11-PROGRESS.md`).
- Its notes: "Console run after 11-23" in `SESSION-11-PROGRESS.md`, `BOARD.md`'s integrator row.

## 2. Check each merged piece against the prompt's rules
For each of 1 (library pictures, shared read total, default 50,000 MB/h), 2 (watchdog alerts, three steps),
3 (add an account while another waits), 4 (mirror door and facts, copies' T4 and N1 review, viewer loopback client),
5 (ROADMAP/FEATURES brought up to date), and the two UI quirks the owner flagged (no "a.m.." after a time; one "Quit now" during a held stop):
- The diff does what the prompt and the owner's words say (read the risky part: anything that writes to Telegram,
  holds, skips or releases a file, a schema step, the watchdog's wall).
- The reviews the prompt required exist (`archiver/docs/review/`), and their findings were fixed.
- The merge went through `merge-batch.sh` (its "MERGE-BATCH: done …, the tree is the tested one" in the log) with
  whole runs of the collector and catalogue on the tested tree; a schema step ran `-run 'Schema|Step'` whole.
- Nothing was pushed but `claude/charming-feynman-vm2xia` and `wip/*` to `private`; no tag; nothing to `origin`.
- Privacy: no names, ids, paths or links of real data in commits, notes or logs (`bash ix-tools/notes-backup/backup.sh`
  refuses on a hit); the owner's folders untouched.
Fix what is wrong with one Opus coder per piece (a branch, the named tests, then a batch as usual); a piece the run
skipped is built here if the usage allows, else listed for the owner.

## 3. Ship
`bash runs-int-i6/folder-next.sh` (the update folder stays marked update-only) if anything changed, then tell the
owner in about ten lines what is new, what was fixed after the review, what is left, the usage percentage, and:
- Quit TG Archive, then run: `powershell -ExecutionPolicy Bypass -File "C:\Users\trabi\tgarchive-app-next\update-folder.ps1" -Into "C:\Users\trabi\tgarchive-app"`
- Run only `C:\Users\trabi\tgarchive-app\tgarchive.exe`.
- Windscribe's inclusive split tunnelling list holds only `C:\Users\trabi\tgarchive-app\programs\tgarchive-collector.exe`.

## Still the owner's (do not start without them)
The bring-in's trial on a copy of the owner's catalogue, then the owner's real bring-in step (the unified archive);
the NAS move (`OWNER-NEXT-STEPS.html`); the mirror's real numbers.
