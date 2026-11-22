# Brief G18c: G18 onto the main head with the one window (pages, P6, 11-16 21:20)

**The owner, 21:18: "Merge the fixes. These are basic, and if ready should go. Especially stuff like G18.
Need a way to quit the app..."** The week's usage is almost gone: this is ONE short round. Commit and
push after every step that works. You are one Opus coder, fresh to the piece. Work only in the copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-pages-quit`, branch `wip/pages-quit` (head 4b273cd0, pushed,
clean).

## What G18 is (read `archiver/docs/progress/pages-quit-REPORT.md` on the branch, both rounds; skim
## `BRIEF-G18-window-ends-and-quit.md` and `BRIEF-G18b-fixes.md` in the project folder for the rules)
The launcher (`archiver/internal/launcher`) starts the app's window with `-tell-close` and reads its
exit codes: **4 = closed by the person** (then, while the app's programs run, a small Windows box of a
helper process asks "Keep it running" / "Quit the app"; with nothing running the launcher ends; a
close during a start is asked once the programs run; after the box's Quit the window comes back when
the stop is not sent or not over in 5 s); **6 = already open, brought forward** (nothing started);
**an unasked 0 starts the window again once**; the launcher's own stop has its own log line; a refused
start then "Try again" keeps the same window.

## What is new on the main head 9980a21f (the viewer track's lent commit, "B8-L1", read it:
## `git show 9980a21f --stat` and its diff in `internal/launcher`)
With the viewer "window" and the pages "window" (the defaults) the launcher now starts ONE window:
`tgarchive-window.exe -pages P -pages L -db .. -library .. -staging .. [-mpv ..] -addr 127.0.0.1:V
-first viewer` (`present.go` `windowLine`, `joined`, `viewerJoined`), NO separate viewer window, the
collector gets `-viewer-url http://<ViewerAddr>`, and **no `-tell-close`** (because on the head any
end but a clean 0 is taken as a failure). While only the launcher's page is named (the setup, a
refusal, after the end) the window is the old pages form.

## Do, in this order
1. **Merge 9980a21f into the branch** (`git fetch private`; by its hash). Four files conflict:
   `launcher.go`, `present.go`, `start.go`, `window_test.go`. Keep BOTH: the head's joined window and
   G18's handling of the window's ends. Rules for the meeting points:
   - **`-tell-close` is passed in BOTH forms of the window's line** (the joined branch of `windowLine`
     too, and the bring-forward start): G18's handling of 4, 6 and an unasked 0 applies to the joined
     window exactly as to the pages form.
   - **The joined case has no separate viewer window:** G18's "the viewer's window starts only at
     'Show the viewer'" and its `-viewer-url http://<launcher>/viewer` apply ONLY where the head still
     starts a separate viewer window with the pages in the app's window (if the head leaves such a
     combination; if none is left, the `/viewer` page stays for the browser kind as the head has it
     and you say so). In the joined case the collector gets the head's `-viewer-url http://<ViewerAddr>`.
   - The window program's exit code **7** (the viewer's port is taken) in the joined form: do what the
     head does with it, and make sure G18's "unasked end" rule does not start the window again in a
     loop on it (7 is not 0: the fallback with its reason; say the words it shows).
   - After the box's "Quit the app" and the 5 s rule, "the window comes back": in the joined case that
     is the joined window again while the pages are named, else the pages form: whatever
     `ownWindowSpec` gives then.
2. **Named tests:** every `TestWindow*`, `TestViewer*`, `TestReal*` (skipped without its variable),
   the head's tests for the joined window (find them: `joined`, `B8-L1`), `TestRun*` that read the
   collector's line. All must pass; a test whose expectation you change is said with its reason. No
   test function removed or renamed.
3. **`TestLauncherStyleMatchesAppTokens` fails on the main head since the app's pages took the new
   look** (`internal/server/web/assets/base.css` changed; the launcher's own page did not). **If it is
   minutes: bring the launcher's page's tokens (`internal/launcher/ui.go`'s styles) to the app's new
   ones so that the test passes** (the tokens only: colours and font, both themes; no layout work) and
   say what you changed. If it is more than about ten minutes of work: leave it, and say so first in
   the hand-back.
4. **The real-windows look once** (`deploy/folder/look-both-windows.sh`, as the report says): it must
   still print "look: ok"; if the joined form makes its second test meaningless (no second window any
   more), make the look start the JOINED window as the launcher now does and check it lives 20 s and
   ends with 4 at a close message if the script can post one; say what you did. Real windows show on
   the owner's screen: one run, under a minute each.
5. gofmt on what you changed; add a section "The third round: onto the one window" to the report;
   commit; push.

## Rules (the earlier briefs' rules bind you; the ones that cost most)
- The owner's real app may be RUNNING on this PC from `C:\Users\trabi\tgarchive-app` on ports 8786,
  8787, 8788 (the owner was just handed the new build): never open, list, read, start, stop or signal
  anything there; never ask those ports; never end a process you did not start (by its id, never by
  name). For every process you start: `LOCALAPPDATA`, `APPDATA`, `TEMP` redirected to scratch folders,
  ports above 20000, stand-ins for the collector and the watchdog. Nothing under `E:`.
- Every go, gofmt and vet command through
  `bash /c/Users/trabi/Claude/Projects/Telegram/runs-pages-p6/go1.sh /c/Users/trabi/Claude/Projects/Telegram/wt-pages-quit/archiver <command...>`.
  Named tests only (the launcher's window tests in one command with `-timeout 5m` is fine), no whole
  package (the full run follows by a script), no race detector.
- Files: `internal/launcher`, `cmd/tgarchive-open` if needed, `deploy/folder/look-both-windows.sh`.
  Nothing in `internal/window`, `internal/viewer`, `internal/server`.
- Never a Windows path inside a shell string. Never capture the output of a command that starts a
  hidden or windowed program. Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com
  commit`, the last line `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push
  `private wip/pages-quit` only. Leave no process, no window, no scratch folder.

## Hand back (at most 10 lines)
The pushed head (it holds 9980a21f); how each meeting point was resolved, one line each; the style
test: mended or left; the named tests run and their result; what the look printed; test functions
added and removed; what is NOT verified.
