# Brief G6: one program to open, with its own folder (pages track, session P3; 2026-11-15 23:10)

For one Opus coder. The design is `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-G6-one-folder.md`: read it in
full first. **The owner said yes to it as written (11-15 21:53, board item 24: the data inside the folder; the
keys stay in the Windows profile; the VPN's entry changes once to the new path; the browser opens now, the
native window by a setting).** This brief cuts the first buildable stage from it and brings it up to what has
been merged since it was written. Where the two differ, this brief wins; where you find either wrong, say so
in the report rather than build around it.

## What is known already (read by the main session; the numbers are the old app's and today's)
- **Why the owner wants it:** the functions exist behind scripts (`a3\a3-start.ps1` for the test account,
  `b\b-window.cmd` for the viewer). The owner's first look at the one program was started by a PowerShell
  command with full paths. "A standalone .exe with a folder" (11-15 18:47) is the product's shape.
- **The old app's lessons for a program that starts another** (TRIED-BEFORE 12 and 21): a launcher that
  restarted silently hid a crash every 2 to 3 hours for days; GitHub's anonymous limit broke the launcher
  twice (this launcher asks nobody for updates); an install by hand took 33 s from stop to start; a copy of
  the catalogue before an update. So: this launcher shows why a start failed, never loops, never restarts a
  program by itself, and asks the network exactly one thing (the PC's public address).
- **Two programs whatever the folder looks like:** the VPN's rule is by program file; the collector's file is
  in the VPN's list and everything it sends goes through the VPN; the viewer reads the library on the NAS and
  must stay out of it; the launcher is outside the tunnel on purpose (it is what can learn the PC's own public
  address, which the collector must never have: `-public-forbid`).
- **Merged since the design was written:** the collector serves the app's pages itself (`run -pages`, G1) with
  Start, Stop, a pause and Quit; **a watchdog (`cmd/tgarchive-watchdog`, Core's)** starts the collector as its
  child, keeps its output in two log files in its own folder, restarts it after a crash by its own bounded
  rules and ends with the collector's exit code 0 after a Quit; **the native window (`cmd/tgarchive-window`,
  the viewer track's)** is the viewer the owner uses; a backup program (`cmd/tgarchive-backup`). The owner's
  first real start of the one program ran 2 minutes under the watchdog and ended clean by Quit (exit 0).
- **Three facts Core found by starting things on this PC (board message 52): keep them.** (a) The watchdog
  gives its child no keyboard input: nothing may count on a typed answer. (b) A caller that takes a hidden
  starter's output through a pipe waits until the started program ends: the launcher never holds a pipe of
  what it starts (the watchdog writes the logs). (c) A watchdog that was killed leaves its collector running
  and the next watchdog refuses to start beside it (its marker file names the child): the launcher must find
  that collector by the marker and say what to do, never say "stop it first" with nothing to stop it. Only
  processes named `tgarchive-collector*` or `tgarchive-watchdog*` are ever taken for ours (`tgarchive-window`
  is the viewer's).
- **What today's start script does that the launcher must do itself:** read `a3\a3-start.ps1` (READ ONLY; never
  run it, never edit it): the flags of `run` it passes (the catalogue, staging and library folders, the status
  file, `-no-links`, `-read-back-now`, `-vpn-adapter`, `-public-forbid`, `-pages`, `-pages-addr`), the one
  public-address lookup, the watchdog's `run -dir <its folder> -status-file <the collector's> -- <collector>
  run ...`, how it reads `watchdog-status.json` to say what became of the start in its first seconds.
- **No absolute path of this PC, no current directory, no PATH, no script** in anything you write (board
  message 40). Go programs on this PC do not find ffmpeg on PATH (a stray quote in the stored PATH): a tool is
  looked for in the folder's `tools\` first.

## What to build (stage A: the launcher, its settings, the folder's build)
A new command `archiver/cmd/tgarchive-open` (built as `tgarchive.exe` in the folder; the existing
`cmd/tgarchive`, which holds `app` and `viewer`, is built as `programs\tgarchive-viewer.exe`) and a new package
`archiver/internal/launcher` with everything testable in it. **It imports neither `internal/collector` nor
`internal/telegram` nor `internal/catalog`** (a wall test, as `TestServerDoesNotImportCollector`): it starts
programs and reads their status files.
1. **The folder and the settings.** The launcher finds its folder from its own location (`os.Executable`,
   links resolved). `tgarchive.json` beside it: the data folder (default `data`), the staging and library
   folders, the VPN adapter's name, the pages' address (default `127.0.0.1:8787`), the viewer's address and
   what opens (`browser`, `window`, `none`), the extra `run` flags kept as a list (so that `-no-links`,
   `-read-back-now` and a helper's address need no code change). Every path absolute or relative to the
   folder; a written file is written whole to a temporary name and renamed; an unreadable or newer-format
   file is refused in fixed words, never overwritten. The Telegram API file and the session key stay where
   they are (the Windows profile): the launcher never reads, copies or names their content.
2. **First start (no settings, or a named folder missing): a setup page on 127.0.0.1** served by the launcher
   itself before anything else is started, with the pages' own guard (same origin and a per-run token on
   every change): the library folder and the staging folder as text fields, each checked to exist and to be
   writable, with the disk's free space shown (no folder dialog: no native code); the VPN adapter chosen from
   this PC's adapters by name (`net.Interfaces`), with the sentence the app must say when the named one is
   missing; the full path of `programs\tgarchive-collector.exe` to copy into the VPN's list, and the words that
   until it is there the collector will refuse to dial (it checks for itself: fail closed). Saving writes the
   settings and goes on to the start. Nothing is sent to Telegram and nothing but 127.0.0.1 is listened on.
3. **Already open:** when the pages' address answers as the app's pages, open them and end. When the watchdog's
   marker names a collector that still runs with no watchdog: say so in fixed words with the one thing to do
   (the launcher's own "Stop what is left", which ends exactly that process after checking its name), and
   start nothing.
4. **The start.** One public-address lookup (a plain-text service, a 20 s bound; on failure: say so and do not
   start: the collector must not run without the address it must not have); then the watchdog as a hidden
   process with the collector as its child (`run -pages` and the settings' folders, adapter and extra flags;
   the watchdog's folder and the status file under the data folder's `logs`), no pipe held; `FFMPEG_PATH` set
   for the programs it starts when `tools\ffmpeg.exe` exists (other tracks' lookups are not edited); then,
   by the setting, the viewer (`programs\tgarchive-window.exe` with the catalogue read-only and `tools\mpv.exe`
   when there, or `programs\tgarchive-viewer.exe viewer`, or none): read `b\b-window.cmd` and `b\b-viewer.cmd`
   (READ ONLY) for the arguments they pass today. Then wait for the pages (the "Starting" page counts as
   up), and open them in the default browser.
5. **While it runs:** the launcher stays in the background and holds nothing open but its own small status
   page on 127.0.0.1 (the watchdog's state from `watchdog-status.json` in the watchdog's own fixed words:
   running; waiting to restart, when and by which rule; ended and why). It never restarts anything itself.
   When the watchdog ends with exit code 0 (the pages' Quit): it stops the viewer it started and ends. When it
   ends otherwise: one page with the watchdog's reason and the last lines of its own log (the watchdog's
   lines are counts and fixed words; the collector's log is NOT shown), and nothing is started again.
6. **A start that fails says why once, in fixed words, and leaves nothing running:** the settings unreadable;
   a program file missing (which one, by its place in the folder); the adapter missing; the pages' address in
   use by something that is not the app; the public address not learnt; the watchdog ended at once (its
   reason from its status file); the collector refused (its exit code and the watchdog's class).
7. **The folder's build:** `archiver/deploy/folder/make-folder.sh <output folder>` (Git Bash, run from a copy
   of the repository by whoever installs; the toolchain comes from the caller's environment): builds
   `tgarchive.exe`, `programs\tgarchive-collector.exe`, `-watchdog.exe`, `-viewer.exe`, `-window.exe`,
   `-backup.exe` with their version, an empty `tools\` with a line of text saying what may be put there, no
   settings file and no data. On an existing folder it replaces `tgarchive.exe` and `programs\` only, keeping
   the earlier programs beside the new ones under their commit's name; `tgarchive.json`, `data\` and `tools\`
   are never touched; it refuses while a process named `tgarchive-collector*` or `tgarchive-watchdog*` runs
   from that folder. A `README.txt` in the folder for the owner: what to open, the one VPN entry to change,
   where the logs are. Every command the README gives uses the folder's own relative layout (the folder may
   be anywhere).

## Not in this stage (say in the report that nothing is built for them)
Moving the copy's choices and the helper's address onto the Settings and Staging pages (they ride in the
settings' extra flags for now); automatic updates; an installer; a tray icon; the first start's folders chosen
by a native dialog; the NAS downloader. **Nothing in `internal/collector`, `internal/watchdog`,
`internal/window`, `internal/viewer`, `internal/server` or the catalogue is edited**: if the launcher needs
something from one of them (a flag, a status field, an exit code's meaning), say exactly what in the report
for the main session to put to that track.

## Tests (named; no real program of the app is started; invented folders in the test's own temporary folder)
The programs the launcher starts are stand-ins built by the test from a few lines of Go in `testdata` (as the
watchdog's own tests do): one that serves "the app's pages" on the address it is given and ends with a chosen
exit code on a signal file, one that ends at once with a chosen code, one that ignores its stop.
`TestFolderFromOwnLocationNotCurrentDir` (started from another directory), `TestSettingsRelativeAndAbsolute`,
`TestSettingsUnreadableRefusedNotOverwritten`, `TestFirstStartSetupPage` (the guard; a folder that does not
exist refused; saving then starts), `TestAlreadyOpenOnlyOpens`, `TestOrphanCollectorSaidNotStarted`,
`TestStartOrderAndArguments` (the stand-in records its arguments: every flag of today's script is there, the
public address is passed, no pipe is inherited), `TestNoPublicAddressNoStart`, `TestQuitEndsViewerAndLauncher`,
`TestCrashShownNeverRestartedByLauncher`, `TestEachFailureWordsOnce`, `TestLauncherImportsNoCollectorOrTelegram`,
`TestLauncherLogNoPathsOrNames` (its own log: fixed words and numbers; a folder's path is shown on the owner's
own page only), `TestMakeFolderKeepsSettingsAndData` (the script on a scratch folder with stand-in sources if a
full build is too heavy: say which). No test judges on real time (a wait is a bound, a clock is injected).
Mutations: the current directory used for the folder; the settings overwritten when unreadable; a start
without the public address; the launcher restarting a crashed child; an orphan collector started beside.

## Rules (hard)
- Copy and branch: `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-g6`, branch `wip/pages-g6`, cut from the
  main head (`git fetch private`, the head of `private/claude/charming-feynman-vm2xia`, 27a7d4d or later:
  write the exact commit into your progress file; make the copy with
  `git -C C:/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add -b wip/pages-g6 ../wt-pages-g6 <head>`).
  New files only: `cmd/tgarchive-open`, `internal/launcher`, `deploy/folder`; plus one line for the new
  package in the repository's wall test if it lists packages. No change to `go.mod` (stop and say so if you
  think one is needed).
- **Nothing runs against Telegram and no real program of the app is started by you**: not the installed
  collector, not the watchdog on a real folder, not the viewer on a real catalogue. Never touch `E:\T\tg-dl`,
  any real catalogue, media, session, account, staging folder or library; in the folders `a3` and `b` you may
  READ the scripts named above and nothing else. The first real start of the folder is the owner's.
- New log, error and state text is constant words with numbers: never a name, a title, a path, an id or a text.
- Go: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, one go command at a
  time, `GOGC=25 GOMAXPROCS=2 go test -p 1 -run '<names>' ./internal/launcher`; the new package's whole tests are
  yours to run (it is small); no race detector, no Docker, no whole run of any other package. Before each go
  command: `powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`;
  wait when free memory is under 2.5 GB or the CPU is over 85% (the PC is short of memory tonight).
- **Run it as the owner will before handing back** (the lesson of two scripts today that were called checked
  and had never been started): build the launcher and the stand-ins into a scratch folder OUTSIDE the
  repository, start `tgarchive.exe` by its full path from another directory, and click the setup page and the
  status page in the built-in browser if you have one: say exactly what you saw and what you did not.
- Any file that holds a Windows path is written with the file-writing tool, never from inside a shell or script
  string (a backslash before a letter became a control byte five times today); scan what you wrote for bytes
  below 32 other than line ends.
- Commits: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; commit work in progress as you go and push only
  `git push private wip/pages-g6`. Never push, merge into, rebase or switch any other branch; never stash.
- Keep `archiver/docs/progress/pages-g6-PROGRESS.md` current from your first action and commit it with each
  step.

## Hand back
Commit-ready: everything committed and pushed, the tree clean, `gofmt -l` clean, `go vet` on the new packages.
`archiver/docs/progress/pages-g6-REPORT.md`: what was built against each numbered point; the settings file's
fields; the exact command line the launcher gives the watchdog and the collector, beside today's script's;
every test and mutation with its result; what you saw when you ran it as the owner will; what each other
track would have to give for the next stage; what was NOT verified (no real collector, watchdog, viewer or
VPN was started); anything in the design or this brief you found wrong; the changed files; a drafted final
commit message; and a short "for the owner" text: what to open and the one VPN entry to change. Your final
message: the head commit, what is built and tested, what is not, every departure, and your doubts, plainly.
