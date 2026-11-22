# Brief B7-T: the window tells the launcher how it was closed (exit codes of their own, behind `-tell-close`)

Written by the viewer session B7, 11-16. One Opus coder, high effort. A SMALL piece: about 60 lines of product
code and its tests. Hand back commit-ready work on the branch; merge nothing; push only this branch.

**The first rule of this project (the owner): routine sequences are not run call by call for their own sake.
Run only the named tests below, each go command once per change, never a whole slow package you were not asked
for, never the race detector.**

## What the old app already knows
Nothing: the old app (the fork) has no window of its own; it is a web dashboard. Nothing to port. What exists
is this project's own: `REPORT-B6-window-ends.md` in the project folder (read it whole first: 88 lines) and the
commit 69e3f3ad on this branch, which notes the first cause of the window's end (`internal/window/ending.go`:
`endBySelf`, `endByPerson`, `endByMessage`, `endByStop`) and prints one fixed line for it.

## Where
- Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-b-join` (Go module in its `archiver` folder), branch
  `wip/b-winfix`, head 69e3f3ad, clean. Work there and only there. Remote to push to: `private`
  (`git push private wip/b-winfix`). Never the main branch, never `origin`.
- Commits: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- You may edit ONLY `archiver/internal/window` and `archiver/cmd/tgarchive-window`. Nothing in
  `internal/launcher` or anywhere else.

## Why
The launcher (another track's) reads the window's exit code 0 as "the person closed the window". But 0 is
also a clean stop by Ctrl-C, a close asked from outside, "a window on this folder is already open: brought to
the front", and (measured) a kill by the closing of a kill-on-close job. The launcher is being changed to ask
"Keep it running / Quit the app" when the PERSON closes the window: it needs a code that means that and
nothing else. The head's launcher must keep working whatever the order of merges: so the new codes come only
with a flag.

## What to build
1. A flag `-tell-close` (a boolean, default false) taken in BOTH modes (the viewer's window and `-pages`; add
   it to `pagesFlagsAllowed`). Its help line, in plain words: with it, the exit code says how the window
   ended: 4 closed by the person, 6 a window on this folder was already open and was brought to the front, 0
   any other clean end; without it, as before.
2. With the flag:
   - the window's loop ended and the end's first cause is `endByPerson`: **exit code 4**;
   - "already open, brought to the front" (both modes' `FirstInstance` / `FirstPagesInstance` returning
     false): **exit code 6** (its line is printed as today);
   - every other clean end (`endByStop`, `endByMessage`, `endBySelf`): **0**, as today;
   - "no window" stays 3, any error stays 1, bad flags stay 1. An error at the end (the viewer's files could
     not all be closed, a failed self-check) wins over 4: the code is then the error's, as today.
   Without the flag: every exit code exactly as on 69e3f3ad (a test says so).
3. How the cause comes out of the package is yours to choose, the smallest that reads well: for example
   `window.Run` and `window.RunPages` return an exported fixed error value (say `window.ErrClosedByPerson`)
   only when their config asks for it (a new boolean field in `Config` and `PagesConfig`), which
   `cmd/tgarchive-window` maps to 4 and for which it prints NO extra line (the window's last line already
   says it). Whatever the form: `exitCode` stays the one place that maps to numbers, with the numbers as
   named constants and one comment block that lists every code of the program (0, 1, 3, 4, 6; 5 is left
   free on purpose).
4. The self-check paths (`-selfcheck`, with and without `-pages`) are not changed: with `-tell-close` and
   `-selfcheck` together the flag is simply ignored or refused in fixed words, as you find cleaner; say which.
5. Every line the program prints stays fixed words and numbers (the file's rule): no path, no address, no
   error text.

## Tests (plain Go, no window needed; named)
- the mapping: each of the four causes, with and without the flag, to its exit code; an error with
  `endByPerson` gives the error's code;
- the flag is taken with `-pages` and with `-db`; without it nothing changed (the existing tests of
  `cmd/tgarchive-window` pass as they are: `TestPagesPathMakesNoViewer` and the flags' tests by name);
- "already open" gives 6 with the flag and 0 without, through the stand-in the command's tests already use
  for the instance rule if there is one; if the instance rule cannot be reached without a real mutex, test
  the mapping function and say so.
Run: `go test ./internal/window -run 'TestEnd|TestTellClose' -count=1` and
`go test ./cmd/tgarchive-window -count=1` (this command package is small: whole is fine), `gofmt -l`,
`go vet ./internal/window ./cmd/tgarchive-window`. Before EACH go command: free memory must be at least
2.5 GB (`powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`);
if not, wait 2 minutes and look again (at most 5 times, then stop and say so). One go command at a time;
`source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` first; `GOMAXPROCS=2 GOFLAGS=-p=1`.

## One look with real windows (at most 4 starts, each under 60 s)
As the report's reproduction did, on a scratch folder of your own
(`C:\Users\trabi\Claude\Projects\Telegram\runs-b7\tellclose`), with `LOCALAPPDATA`, `APPDATA`, `TEMP` and `TMP`
set to folders inside it BEFORE anything starts, the pages mode with `-selfcheck`-free invented pages of your
own (a tiny local server on 127.0.0.1 that you start and stop) or the simplest form you find, output to
files (never a pipe from a background program):
(a) `-pages ... -data <scratch> -tell-close`, then the message the X sends (`WM_SYSCOMMAND` `SC_CLOSE`)
posted to YOUR window (found by its class for your scratch folder, never by title, never another window):
expect exit 4 and the "closed by the person" line; (b) the same ended by Ctrl-C or by a bare `WM_CLOSE`:
expect 0; (c) a second start on the same folder while the first runs: expect 6 from the second; (d) (a)
without the flag: expect 0. Write the four results (codes, the last lines) into your hand-back. If a real
window cannot be started in your environment, say so and do not work around it.

## Hard rules (the owner's)
- Invented data only. Never open, list or read anything under `E:\`, any folder named `tgarchive-b`,
  `tgarchive-app` or the owner's app folder, or any real catalogue. Do not search drives.
- Never stop, kill or signal a process you did not start. Post messages only to a window of your own
  process. At the end: no process of yours left (count them).
- Text with a Windows path never goes through a shell string into a file: use the Write or Edit tool.
- No new dependency. No change to the gate, the instance rule's names, the job, or mpv.

## Hand back
Push the branch. Your final message, at most 30 lines: the head's hash; files and line counts; the form you
chose for (3) and (4); each named test run and its result; the four real-window results or why not; your
doubts, most important first; anything you saw that is wrong but outside this brief (do not fix it).
