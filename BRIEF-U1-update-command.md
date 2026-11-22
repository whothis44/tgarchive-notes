# Brief U1: the owner's update command (pages, P7, 2026-11-21)

You are the coder of this piece: Opus 5.5 at high effort. Hand back commit-ready work on your branch.
**It is needed within hours** (before the mirror's M14 is installed): build it plainly, then try it as
the owner will run it.

## The house rules (binding)
Read `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-P7-review-rules.md`: its privacy and safety rules bind
you. Above all: **the owner's folder and their running app are never touched, read, started or stopped by
you**: you never name, open or list it; every try runs on scratch folders you make under
`C:\Users\trabi\AppData\Local\Temp\p7-u1\` (outside any git copy), with `LOCALAPPDATA`, `APPDATA`, `TEMP`,
`TMP` redirected there for each try process. **No window on the owner's screen:** in a try the app's
start is a stand-in (below). Read these four notes first (each a lesson paid for):
`C:\Users\trabi\.claude\projects\C--Users-trabi-Claude-Projects-Telegram\memory\starter-try-on-a-copy.md`,
`scripts-written-through-tools.md`, `hidden-start-pipe-hang.md`, `commands-run-from-anywhere.md` (same
folder). In short: **never name a PowerShell parameter after a variable the script uses (case does not
count)**; write the script with the Write/Edit tool, never through an inline string, and count bytes
below 32 other than line ends afterwards; never capture the output of a call that starts a program (it
hangs on the inherited pipe): write to a log file and read it after; every command for the owner by full
path, working from any folder.
Go commands (to build test folders) through `bash /c/Users/trabi/Claude/Projects/Telegram/runs-pages-p6/go1.sh <dir> <command>`.
Commits: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push `git push private HEAD:wip/pages-update`
only (no merge, no tag, no stash).

## Where
`git -C repo-archiver fetch private && git -C repo-archiver worktree add -b wip/pages-update ../wt-pages-update private/claude/charming-feynman-vm2xia`
(the head 6aa225fb). New file `archiver/deploy/folder/update-folder.ps1`; `make-folder.sh` copies it into
the folder it builds (beside `tgarchive.exe`) if that is the simplest way for the owner to have it; the
folder's `README.txt` gains a short "Updating" part. Report: `archiver/docs/progress/pages-update-REPORT.md`.

## Read first
`archiver/deploy/folder/make-folder.sh` whole (its checks, the "updating" mark, the running check by the
programs' paths, the moves with put-back, `programs/<commit>/` for the earlier programs, exit codes),
`README.txt` there, `internal/launcher/settings.go` (where `tgarchive.json` says the data folder is:
absolute or relative to the folder) and how the catalogue file is named inside the data folder (find it
in `internal/launcher` / `start.go`), `cmd/tgarchive-backup/main.go` and `internal/backup` (a checked copy
of the catalogue: decide whether it is the right tool here; with the app quit, a plain copy of the file
and its `-wal` and `-shm` is consistent too: say which you chose and why).

## What it does (the integrator's five points, the owner's words)
The owner quits the app, then runs ONE command, e.g.
`powershell -ExecutionPolicy Bypass -File "C:\Users\trabi\tgarchive-app-next\update-folder.ps1" -Into "<their folder>"`
(you choose the parameter names: `-Into` for the folder to update; the folder holding the new build is the
script's own folder, `$PSScriptRoot`, unless a `-NewBuild` is given; check no name clashes with a variable).
1. **Checks, changing nothing:** both folders are ones `make-folder.sh` made (`folder.version`); the new
   build's `programs/VERSION.txt` differs from the folder's (same: say "already this version", exit 0);
   no `updating` file in either; nothing of the app runs from the folder (the same process names and path
   test as `make-folder.sh`'s `running()`, by both the path given and its resolved form); enough free
   space on the data folder's drive for the catalogue's copy. Any failure: fixed words, exit non-zero,
   nothing changed.
2. **The catalogue set aside:** its file with `-wal` and `-shm` (or the backup program's checked copy),
   into a folder inside the data folder named with the old commit and the time; the copy checked (sizes,
   or the backup program's check). Fails: stop, nothing else done.
3. **The programs replaced as `make-folder.sh` does it:** the `updating` mark written first, the running
   check again, the earlier `tgarchive.exe`, `programs/*.exe` and `VERSION.txt` moved to
   `programs/<old commit>/`, the new ones copied in, all or nothing (a failed step puts back every step
   made; if putting back fails, say exactly which files are which and leave `updating`); `tgarchive.json`,
   `data/` and `tools/` never touched; `updating` removed at the end.
4. **The app started again:** `tgarchive.exe` of the folder, by `Start-Process` with no redirect (a switch
   `-NoStart` for the try and for an owner who wants to start it by hand).
5. **Fixed words:** from which version to which, where the catalogue's copy is (by its name inside the data
   folder only), and HOW TO GO BACK: a second form of the same command (for example `-GoBack`) that, with
   the app quit, moves the current programs aside, puts `programs/<old commit>/` back, and puts the
   catalogue's copy back (saying plainly first that what the newer build wrote since the update is lost
   with it, and keeping the newer catalogue aside, never deleting it). Build and try `-GoBack` too.
No path of this PC goes into a file; the words name places inside the folders only. Exit codes like
`make-folder.sh`'s, each said in the script's head.

## The try, as the owner will run it (all under `...\Temp\p7-u1\`)
- Build an OLD folder with `make-folder.sh` from a copy at af4ca40e (`git -C repo-archiver worktree add
  --detach ../wt-pages-update-old af4ca40e`), give it a `tgarchive.json` with a data folder, and an
  invented catalogue (fabricate, or the empty catalogue the program makes; a schema older than the new
  build's: that is the case).
- Build a NEW folder from your branch.
- **Replace the NEW folder's `tgarchive.exe` with a stand-in for the try** (a tiny program that writes a
  line to a file in the scratch folder and ends), so step 4 starts no window; a second try with `-NoStart`
  and the real `tgarchive.exe`.
- Run the command by full path from another folder (`Set-Location` to `C:\` first), output to a log file.
  Then: the old folder's programs under `programs/<old commit>/`, the new ones in place, the json and
  data byte for byte as before (hash them before and after), the catalogue's copy present and equal, the
  stand-in started once. Then `-GoBack`: the old programs back, the catalogue copy back, the newer one
  aside. Then the refusals: a stand-in process running from the old folder's `programs` (the update
  refuses and changes nothing: hashes), an `updating` file, a folder not made by the script, the same
  version twice.
- At the end: no process left with its path under `p7-u1`; the owner's folder never named in any command.

## Hand back
Branch pushed, copy clean; the report: what it does, the exact command for the owner (with `<their
folder>` left for the integrator to fill), every try and its result, the control-byte count, what is not
verified. Final message: the branch's head (8 characters), the report's path, one line of what is not
verified. Nothing else.
