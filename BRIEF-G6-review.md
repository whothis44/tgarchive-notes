# Brief: independent review of G6, stage A (the launcher `tgarchive.exe`, its settings, the folder's build) — read-only

You are an independent reviewer. You did not write this code and you owe its author nothing. Find what is
wrong with it before the owner double-clicks it on the PC where the real collector and its Telegram account
live. **You change nothing in the tree.**

## What to review
The branch `wip/pages-g6` at 51d7656a, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-g6` (Go
module in `archiver/`), against its base 27a7d4dc: `git diff 27a7d4dc..51d7656a` (20 files, all new:
`cmd/tgarchive-open`, `internal/launcher`, `deploy/folder`). What it was asked to do:
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-G6-one-folder.md` and the design the owner approved,
`C:\Users\trabi\Claude\Projects\Telegram\DESIGN-G6-one-folder.md`. Its author's own account:
`archiver/docs/progress/pages-g6-REPORT.md` (read it last; do not take its word for anything). What it must
match: today's start script `C:\Users\trabi\Claude\Projects\Telegram\a3\a3-start.ps1` and its stop script
`a3\a3-stop.ps1` (READ ONLY: never run or edit them; open no other file in that folder), the watchdog
(`cmd/tgarchive-watchdog`, `internal/watchdog`: its marker file, its status file, its exit codes, how it stops
its child), the collector's `run` flags and exit codes (`internal/collector/command.go`), what the collector's
starting page answers (`internal/collector/pages.go`).

Background: the collector is the one program that talks to Telegram; the VPN's rule is by its program FILE,
and it refuses to dial unless it is behind the VPN and its public address differs from the one it is handed
(`-public-forbid`: the PC's own address, which only a program outside the tunnel can learn: the launcher). It
runs as the child of a watchdog that restarts it after a crash by bounded rules and ends with exit code 0
after the pages' Quit. The owner's rules: a launcher that restarted silently once hid a crash for days: this
one never restarts anything itself and says why a start failed, once; nothing depends on an absolute path of
this PC, the current directory, PATH or a script; logs hold constant words and numbers only (a folder's path
may be shown on the owner's own page, never logged); the Telegram API file and the session key are never
read, copied or named in content; only processes named `tgarchive-collector*` or `tgarchive-watchdog*` are
ever taken for the app's (the viewer's window is `tgarchive-window`; other programs on this PC, the old app
among them, must never be stopped or signalled).

## Where to look hardest (not a limit)
1. **What it can stop or signal** (`internal/launcher/proc_windows.go`: `Kill`, `SendCtrlC`; "Stop what is
   left", "End it now", the stop of the viewer at Quit, the helper start of `tgarchive.exe` itself): prove
   that no path can signal or end a process that is not the exact one the marker or the launcher's own start
   named: a process number reused by another program between the look and the act; a name check that a
   longer name passes; a marker file with a number of someone else's process (the marker is a file anyone
   with the folder can write); the old app or the installed collector of the TEST account under
   `%LOCALAPPDATA%` running at the same time as a collector from this folder; a Ctrl-C sent to a console group
   that holds more than the target (what else shares that console: the launcher itself, the watchdog, the
   collector, a terminal the owner started it from); "the launcher clears its own inherited ignore-Ctrl-C mark
   before each start": what that does to a launcher started from a script or a terminal. What does a stop of
   the watchdog do to its collector, and of the collector to a download in transfer (it must be the clean
   stop, never a kill, unless the owner clicked the kill)?
2. **The command line against the script's**, flag by flag and value by value (the catalogue, staging and
   library paths, relative settings resolved against the folder and never the current directory; the status
   file; `-vpn-adapter`; `-public-forbid`; `-pages`; the extra flags from the settings: can a settings file
   inject a flag that turns a guard off, such as another `-public-forbid`, `-vpn-adapter` or an address that
   is not loopback; is `pages_addr` or `launcher_addr` ever accepted when it is not 127.0.0.1). **The public
   address:** when the lookup fails, times out, answers something that is not an address, or answers through
   a VPN that happens to be on for the launcher too (then the "forbidden" address is the VPN's own and the
   collector would refuse to run, or worse, the PC's real address is not forbidden): what starts? The address
   in any log, page, error or settings file?
3. **Already open, two launchers, an orphan:** "already open" decided by a page's title on a port (anything
   else on that port, another user's program, a stale browser tab's server); two double-clicks at once (the
   fixed `launcher_addr` as the guard: what if that port is taken by something else); a watchdog that runs
   with no pages; a collector with no watchdog (the orphan page); the watchdog waiting to restart (is a
   second start possible then); a start while `make-folder.sh` replaces the programs.
4. **The setup page and the status page as a local web surface:** the guard on every change (host, origin,
   token); what another site's page or another local program can make the launcher do (start programs with
   chosen folders, write settings, stop "what is left"); a folder path that is a network path, a drive that
   is away, a path with quotes or spaces through to the child's command line (argument quoting on Windows);
   the settings file written whole and never left half; an unreadable or newer file never overwritten; what
   the first start does when the data folder already holds a catalogue of an older or newer build.
5. **While it runs and when it ends:** the launcher never restarts anything (find any loop that starts a
   program again); Quit from the pages ends the viewer it started and only that; the watchdog ending with
   another code; the launcher killed while its children run (what is left, and does the next start say so);
   the PC shut down; the failure page that stays in the background with no idle end.
6. **The log and the pages' words:** any path, name, address or id in the launcher's log or in an error; any
   sentence that is false in a state it can be shown in.
7. **`deploy/folder/make-folder.sh` and the README:** what it deletes or overwrites (it must never touch
   `tgarchive.json`, `data` or `tools`; it must refuse while a collector or watchdog runs FROM THAT FOLDER:
   how does it tell, and can it be fooled into replacing a running program); a path with spaces; an output
   folder that is the repository or the installed `bin`; the README's commands and its one VPN instruction.
8. **The tests:** stand-ins are the test binary under the programs' names: does any test start a real program
   of the app or touch a real port (8787, 8786) or a real folder; a test that judges on real time; a mutation
   the author says was caught that its test would not catch.

## How to work
- Read the code yourself. Prove a finding where you can with a probe test in your own scratch folder
  `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g6-scratch`, loaded with `go test -overlay` (the tree
  stays untouched), or by reasoning from quoted lines when a probe would cost too much. Mark each finding
  **CONFIRMED** or **PLAUSIBLE** (say what would settle it).
- **You start no real program of the app** (no collector, watchdog, viewer or window on any real folder), you
  build no folder outside your scratch folder, you signal and stop no process but ones your own probe started,
  and you never run the launcher against the default ports with a real program behind them. The owner's own
  program may be running on this PC: leave every process alone.
- Go: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, one go command at a
  time, `GOGC=25 GOMAXPROCS=2 go test -p 1 -run '<names>' ./internal/launcher` (the package is small: its whole
  tests may be run once); no other package's whole run, no race detector, no Docker. Before each go command:
  `powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`;
  wait when free memory is under 2.5 GB or the CPU is over 85%.
- Never touch `E:\T\tg-dl`, the folder `b`, any real catalogue, media, session or account; never read the
  Telegram API file or the session key. Print counts and timings only.
- Any file you write that holds a Windows path is written with the file-writing tool, never from inside a shell
  or script string.

## What to hand back
Write `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-G6-launcher.md`: findings in order of harm, each with its
mark, the file and lines, what goes wrong in one concrete sequence of events, and the smallest change you would
ask for; first the ones that must be fixed before the owner opens it, then the ones that should be, then minor
ones; then the command line beside the script's as a table with every difference; what you checked and found
sound (briefly, by name); what you did not look at; and what the race detector should be run on. Your final
message: the count by class and the must-fix findings in one line each.
