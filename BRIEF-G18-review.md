# Brief: the independent review of G18, the app's window and Quit (pages, P6, 11-16)

You are an independent reviewer (Opus, high effort). You did not write this code. **Read-only on the
copy `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-quit`** (branch `wip/pages-quit`, head d6a89aaa;
base 78739d59: `git diff 78739d59 d6a89aaa`; 25 files, +1,516 -51; mostly `archiver/internal/launcher`,
a little `internal/server` and `cmd/tgarchive-open`; one lent commit in `internal/window` and its
revert cancel out). You edit and commit nothing there. Probes and scratch things go into
`C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g18-scratch` (make it; `go test -overlay`).
Write the review to `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-G18-window-and-quit.md`.

## What the piece is
`BRIEF-G18-window-ends-and-quit.md` in the project folder (what was asked and the owner's words: "doesn't
quit properly"; the app's window was gone seconds after each start and the launcher showed nothing) and
the coder's report `archiver/docs/progress/pages-quit-REPORT.md` on the branch. As built:
- a start refused before its programs ran, then "Try again", made the launcher stop and restart its own
  window (the owner's log lines); now the pages' address stays named and the same window is kept;
- the window is started with `-tell-close` (the viewer track's contract, built on ITS branch, not on
  this one: 4 = closed by the person, 6 = a window on this folder was already open and was brought to
  the front, 0 = every other clean end, 3 = no window, 1 = other); **only 4 is the person's close**; an
  unasked 0 starts the window again once in the run, then the browser with the reason;
- on 4 while the app's programs run the launcher asks in a small Windows box of a helper process
  (`tgarchive.exe -ask-close`): "Keep it running" / "Quit the app"; Quit is the watchdog's clean stop;
- with the pages in the app's window, the viewer's window is started only from a new launcher page
  `GET /viewer` ("Show the viewer", a guarded POST), and the collector gets `-viewer-url` to that page.

## What to decide, in this order (it starts and ends programs for the owner: be hard on it)
1. **After a person's close, can the app be left in a state the owner cannot see or end?** Every case:
   the close while the programs run and the box answers Keep, Quit, is closed without a choice, cannot
   be shown, never returns (the helper hangs: is anything held?), or the watchdog ends while the box is
   open; **the close while NOTHING of the app runs** (the setup page, a refused start, an ended run):
   does the launcher end, or stay as a process with no window and no page (how does the owner get it
   back or end it)? "Quit the app" is sent on a channel without waiting: can it be lost (nobody
   receiving at that moment), and what does the owner see then? Two closes in a row; a close during a
   start; a close during a held Quit (the sign-in page holds a Quit for a code).
2. **The window's ends:** for each exit code (0, 1, 3, 4, 6, another) at each moment (the first
   seconds, later, during the launcher's own stop, from the bring-forward start, from an adopted
   front start): what does the launcher do, and can any path start windows in a loop, start a second
   window beside a living one, or take an end for the person's wish that was not? The restart "once in
   the run": once per what, and is the count ever reset? What happens on the HEAD's window program,
   which refuses `-tell-close` (exit 1): is that the browser fallback with a true reason, at every
   start (this piece must merge after the viewer's; say what a wrong order would show the owner)?
3. **The retry fix (`refusalNames`):** it looks at the pages' address once to decide whether to name
   it: can it name an address another program answers on (the window's security rule: a named port
   taken by another program would be shown under the app's title); what if the look hangs; is the rule
   "not after programs ran" kept; does the setup's own path still work as before?
4. **The viewer's start moved to "Show the viewer":** with the pages in the app's window the viewer no
   longer starts with the programs: is that true on every path (a retry, a change of the choice
   "window or browser", the browser fallback after a failed window), and never the reverse (two
   viewers; a viewer started on GET)? The new routes: `GET /viewer` acts on nothing; the POST is behind
   the launcher's page guard (origin and token) as every change is; what it starts is exactly
   `viewerSpec`'s program and arguments. The collector's `-viewer-url`: only the launcher's own
   address; and the Settings row's words are true ("set by the program's launcher").
5. **The close box helper (`closebox_windows.go`, the `-ask-close` case in `cmd/tgarchive-open`):** it
   reads nothing, writes nothing, opens no listener; its words; it comes to the front (the coder could
   not verify which of its two forms showed); it is in a job that ends it with the launcher; a second
   box is never opened while one is open.
6. **The tests:** for each rule above a test that fails without it (plant by overlay: 0 taken as the
   person's close again; the box opened on 6; Quit from the box not reaching the watchdog; the viewer
   started with the programs in the window; the pages' address named after programs ran). The two
   real-window tests (`TestRealBothWindows*`, only with `TGARCHIVE_REAL_WINDOW=1`): read them; run them
   ONCE through `deploy/folder/look-both-windows.sh` if you can do it safely (rules below): real
   windows show on the owner's screen for about 20 s each; say what you saw end and with which code.
   Test functions removed or renamed: the coder says 0; existing tests that meant the person's close
   by 0 were changed to 4 or 6: check none lost its meaning.
7. Anything else in the diff that is wrong. Not in scope: the look; the window program itself (the
   viewer's); the one-window design.

## Rules
- The owner's real app may be RUNNING on this PC (`C:\Users\trabi\tgarchive-app`, ports 8786, 8787,
  8788): never open, list, read or signal anything there, never ask those ports, never end a process
  you did not start (by the id you got at its start, never by name: the owner's programs have the same
  names as yours). Nothing under `E:`. Invented data only; no real collector; nothing to Telegram.
- For every process you start: `LOCALAPPDATA`, `APPDATA` and `TEMP` redirected to scratch folders;
  ports above 20000. Never capture the output of a command that starts a hidden or windowed program:
  output to a file. Each real-window try under 60 s; close what you opened; leave none behind.
- Every go command through
  `bash /c/Users/trabi/Claude/Projects/Telegram/runs-pages-p6/go1.sh /c/Users/trabi/Claude/Projects/Telegram/wt-pages-quit/archiver <command...>`
  (it may wait for the track's lock). Named tests only, nothing over three minutes a command, no whole
  package, no race detector.
- Never a Windows path inside a shell string (`/c/...` in bash; the Write tool for files; forward
  slashes inside an overlay's JSON). Leave no process, no window and no file in the copy.

## The review file
Findings numbered, each **must fix / should fix / minor**, each **confirmed** (the probe and its
decisive line) or **plausible** (read, not run). The last line is one of: "may be listed", "may be
listed after these fixes: <numbers>", "not yet". Hand back at most 12 lines: the verdict line, the
counts by weight, each must-fix in one line, what the real windows showed if you ran them, what you
could not check.
