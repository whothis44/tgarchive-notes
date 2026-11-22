# Brief B6-X: why the app's window ends by itself when the viewer's window starts (viewer session B6, 11-16 evening): find the cause, then mend the window's side

You are an Opus coder and investigator for the viewer track of the new archiver. Work only in the copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-b-join` (Go module in `archiver/`). First, there: check the copy is
clean (`git status --short` prints nothing; if not, stop and say so), `git fetch private`, and cut the branch
`wip/b-winfix` from `private/claude/charming-feynman-vm2xia` (the main head; write the exact commit into your
hand-back). Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash.

**Hard rules, first:**
- **THE OWNER'S APP MAY BE RUNNING RIGHT NOW from `C:\Users\trabi\tgarchive-app` (a launcher, a collector, a
  watchdog, one or two windows). Never open, list, read or write anything in that folder or under
  `%LOCALAPPDATA%\tgarchive`, `%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b`,
  `E:\T` or the NAS. Never stop, signal, focus, move or touch a process or a window you did not start
  yourself: before any stop, check that the process id is one you started.** In particular: never send a
  console control event (Ctrl-C, Ctrl-Break) to a process group you did not create, and never end a
  process by its name.
- No search over a whole drive (look only inside the copy, a scratch folder of your own, the Go toolchain's
  folders). Invented pages and an invented archive only (`tgarchive fabricate -files`).
- Every start of `tgarchive-window.exe` or of the launcher by you: built by you into your scratch folder,
  on scratch data folders of your own, **with `LOCALAPPDATA`, `APPDATA`, `TEMP` and `TMP` pointed at empty
  scratch folders for that process**, output written to a file, never read through a pipe from a hidden
  start. **Real windows: at most EIGHT starts in all, each ended by you within 90 seconds; say how many.**
  The browser engine starts behind the window's gate by itself: never switch the gate off.
- One go command at a time, `GOGC=50 GOMAXPROCS=2 GOFLAGS=-p=1`, named tests only; before each go command
  `powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`
  as a command of its own, and wait (at most 20 minutes) while free memory is under 2.5 GB or the CPU over
  85%. No whole-package run, no race detector, no Docker.
- **You may CHANGE only `internal/window` and `cmd/tgarchive-window` (and their tests). `internal/launcher`
  is the pages track's: read it, run it on your scratch folder if that helps, change nothing in it.**
  Commits on `wip/b-winfix`, pushed only with `git push private wip/b-winfix`:
  `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no archive numbers. Never stash.

## What happened (the owner's first real start of the app, today 18:05 to 18:15; from the launcher's own log, read by the integrator)
The launcher (`tgarchive.exe`, `internal/launcher`) starts the collector under its watchdog, shows the app's
pages in a window (`tgarchive-window.exe -pages <the launcher's page> -pages <the app's pages> -data <the
program's folder>\pages-window`, in a kill-on-close job of the launcher's own that does not allow
breakaway, the environment without `WEBVIEW2_*`), and starts the viewer (kind 1: the viewer's window,
the same `tgarchive-window.exe` in its viewer mode, on the catalogue). **At both starts with a saved setup the
app's pages window ENDED BY ITSELF WITH EXIT CODE 0, after 8 s and after 4 s, each time in the second in
which the launcher had also started the viewer's window. At the first start, where no viewer was started,
the pages window lived 136 s (until Quit).** The owner had to open the program again each time. Also in the
log, not explained: one second after the owner's first Quit a new launcher started.

**The question:** two processes of the same program, one in the pages mode and one in the viewer's mode,
started by the launcher within the same second: which of them ends the other, or makes it end itself, and
by what? Candidates the main session can think of, none checked: the single-instance rule (the mutex and
the window class per data folder and mode; `FirstInstance` bringing "the other window" forward); a job
object (the window's own kill-on-close job for mpv and the engine, the launcher's job around the pages
window, a job named alike in both, a handle closed); a console control event reaching both (the launcher
ends its window "by a clean stop through its Ctrl-C helper": is anything sent at the viewer's start, or
when a second start of the pages window is used to bring it to the front?); the launcher itself taking the
exit of ANOTHER start of the window (its "bring to the front" start, which exits 0 at once) for the window's
end, or closing the pages window when the viewer's window appears; the two modes writing the same
`window.json`; the WebView2 runtime (two engines, two user-data folders: one ending the other's browser
process); the gate (each process has its own). **Do not start from this list: start from the code and the
reproduction.**

## What to do, in this order
1. **Read** how the launcher starts, watches and ends both windows (`internal/launcher`: find every place
   that starts `tgarchive-window.exe`, its flags, its job, its environment, its console and process group,
   what it does when a window process ends, the "bring to the front" start, the Ctrl-C helper), and in
   `internal/window` and `cmd/tgarchive-window` everything that can end the process with code 0 or touch
   another process or window (the instance rule, the jobs, the signals, the close paths, `os.Exit`).
2. **Reproduce it on a scratch folder, as near to the launcher's way as you can**: the pages window on two
   small local pages of your own (a few lines of Go or the self-check's servers), then, in the same
   second, the viewer's window on an invented archive, with the same flags, job, environment and console
   arrangement the launcher uses (use the launcher's own code for the starts if it can be run on a scratch
   folder without a collector; if not, a small harness of yours in the scratch folder that starts them
   the same way). Record for each process: its start, its end, its exit code, and what the program's own
   lines say. If it does not reproduce with a plain harness, change one thing at a time toward the
   launcher's real way until it does, and say which thing it was.
3. **Find the cause, to the line.** Then say whose it is: the window's (yours to mend), the launcher's (the
   pages track's: do not edit; write down exactly what to change), or both.
4. **Mend the window's side**, if it has one, with a test that fails before and passes after (the
   reproduction itself as a named, bounded test where it can run without a real window; otherwise the rule
   that was wrong, tested in plain Go, and the reproduction re-run by hand afterwards: say which).
5. **The second question, by reading only:** closing the app's window with X leaves the launcher, the
   collector and the watchdog running (the launcher's design). Say what the window's side can offer the
   launcher so that the owner's X can either quit the app or be asked: an exit code of its own for "closed
   by the person" against "ended by a stop from outside", a flag for "ask before closing" with fixed
   words, a way to hide to the background. Build NOTHING of it: one paragraph of what each would take.

## Hand back, as your last message
The head (pushed) and its base; **the cause, to the file and line, with the reproduction's record (each
process's start, end and exit code, before and after the mend)**; whose it is; what you changed in the
window's packages and its test; **what the pages track must change in the launcher, written so that it can
be done without reading your code**; the unexplained second launcher start, if your reading explains it;
the answer to step 5; how many real windows you started and for how long each; what you did NOT test;
your doubts, plainly. Commit-ready, nothing left running (count the engine's processes of your own starts:
none may be left), the copy clean, your scratch folder removed.
