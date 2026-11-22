# Brief: the independent review of U1, the owner's update command (pages, P7, 2026-11-21)

Read first: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-P7-review-rules.md` (the house rules: binding), and
`C:\Users\trabi\.claude\projects\C--Users-trabi-Claude-Projects-Telegram\memory\starter-try-on-a-copy.md` and
`hidden-start-pipe-hang.md` (same folder). **The owner's folder is never named, read, listed, started or stopped:
every try on scratch folders of your own under `C:\Users\trabi\AppData\Local\Temp\p7-u1rev\`, with
`LOCALAPPDATA`, `APPDATA`, `TEMP`, `TMP` redirected there for each process; never capture the output of a call
that starts a program (write to a file); no window on the screen (a stand-in for `tgarchive.exe`, or `-NoStart`).**
It is wanted within the hour: questions 1 to 3 first; report what you have by then.

**The piece:** `wip/pages-update` 0286f6e8 (from 6aa225fb): `archiver/deploy/folder/update-folder.ps1` (new),
`make-folder.sh`, `README.txt`. The coder's report: `archiver/docs/progress/pages-update-REPORT.md`; its try
driver `C:\Users\trabi\AppData\Local\Temp\p7-u1\try-u1.ps1` and its scratch folders (read them, reuse them by
copying into your own folder; do not change theirs). The ask: `BRIEF-U1-update-command.md`. The owner will run,
with the app quit: `powershell -ExecutionPolicy Bypass -File "<the new build>\update-folder.ps1" -Into "<their folder>"`
and to go back `... "<their folder>\update-folder.ps1" -GoBack`. **This script moves the owner's programs and
catalogue: your job is to find any way it loses or damages the owner's data, leaves the folder unable to start,
or does something the words do not say.**

**Your copy:** `git -C C:\Users\trabi\Claude\Projects\Telegram\repo-archiver worktree add --detach ../wt-pages-review-u1-scratch 0286f6e8`.
Report to `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-U1-update-command.md`.

## Questions, in this order
1. **The catalogue.** Every way the catalogue (with -wal and -shm) can be lost, mixed or half put back: a
   `-wal` present in the folder and not in the copy or the other way round at `-GoBack` (a stale `-wal` beside
   an older main file corrupts SQLite: check the put-back removes or moves every one of the four names that is
   not in the copy); a data folder relative to the folder, absolute, on another drive, behind a junction; a
   second update before any go-back (which copy does `-GoBack` take, and does it ever take one whose
   programs are not the ones kept?); two copies with the same stamp; the copy check by SHA-256 actually
   comparing the copy with the source.
2. **The running check and the mark.** Can anything of the app start or still hold a file between the check
   and the moves (the launcher started by the owner during the update: does `tgarchive.exe` really start
   nothing while `updating` exists, in the OLD build too, i.e. 70b0c7e's launcher? read `internal/launcher`
   at 70b0c7e for that check); a process whose path cannot be read (another user, elevated): counted as
   running or missed?
3. **All or nothing.** Every failure point in the moves: is every move put back in the reverse order; what the
   folder holds after exit 5 (can the app start?); after exit 4 (do the words name every file truly?);
   a Ctrl-C half way (PowerShell's `trap`/`finally`: is `updating` left in place so nothing starts on a
   half folder?).
4. **The words.** No path of this PC in any output; the words true for each exit code; the "how to go back"
   true after each kind of update.
5. Anything else: its own number.
