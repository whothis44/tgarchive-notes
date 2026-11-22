# Review B7-T: the window says how it ended, and `-tell-close` (commits 69e3f3ad and ca98432f on `wip/b-winfix`, base 78739d59)

One narrow independent Opus reviewer, read-only on the reviewed copy, 11-16 about 18:52 to 19:01; written down
by the viewer session B7 from its hand-back (the reviewer could not write files). Plants in its own scratch
copy `wt-b7-review-T-scratch` (detached at ca98432f, left in place, clean). The session's decisions are at the
end.

## Verdict: MAY BE LISTED AFTER THESE FIXES (both small, low severity)

## Findings, most severe first
1. **Low.** Nothing tests where the window notes the end (`internal/window/shell_windows.go` 244 to 248,
   `mainProc`): every test drives `endFromMessage` or `endNote` directly. A `mainProc` that noted the person's
   close on a bare `WM_CLOSE`, or that dropped the `WM_SYSCOMMAND` case, would pass every test. The window
   procedure cannot be tested without a real window: the smallest fix is the brief's real-window check (a) to
   (d), recorded.
2. **Low.** A planted "end line printed twice" is caught by no test (`Run` and `RunPages` never have their
   output checked). Smallest fix: say so, or one helper called once.
3. **Low, older than this change.** `internal/window/pages_windows.go` 412 to 415: if the engine's "process
   failed (browser exited)" is handled after the person's close has destroyed the window and before the
   loop's end, the end error becomes "no window" and the code is 3 (the launcher then opens the browser),
   not 4. Not guarded by the window's state. Rare. Smallest fix: return early in `pagesProcessFailed` when
   the main window is gone.
4. **Cosmetic.** The usage lines (`cmd/tgarchive-window/main.go` 243 to 244) do not list `-tell-close`
   (`-selfcheck` is not listed either).
5. **Information.** The end line is printed right after the loop (`shell_windows.go` 146,
   `pages_windows.go` 177): lines of the shutdown, the counts file, the self-check and the command's own end
   line come after it, so it is not always the very last line. The pages mode's 10 s watch and `RunPages`'
   early returns print no end line (no loop ran). Both look intended.

## The six questions
1. Without the flag everything is as on 78739d59 but the one new line: yes (`main.go` 48 skips a line only
   for the two ends that need the flag; `ending.go` 73).
2. A person's close always gives 4 when nothing went wrong, except the old race of finding 3; errors win
   (`ending.go` 74). Nothing in the module sends or makes `WM_SYSCOMMAND` or `SC_CLOSE`; the program's own
   closes call `DestroyWindow` or `close()` directly and note nothing; a note cannot go stale (`SC_CLOSE`
   always becomes `WM_CLOSE`, then `close()`, then an unconditional `DestroyWindow`). Only something outside
   posting `SC_CLOSE` would give a 4 that was not the person's. NOT checked (needs a real window): whether
   Alt+F4 with the focus inside the engine's or mpv's child window reaches the main window as `SC_CLOSE`.
3. The instance rule: 6 only with the flag, the line printed as before, the mutex code unchanged: yes.
4. The note: one atomic value, compare-and-swap from the window's thread and the signal's goroutine, read
   after the loop has ended: yes. A late Ctrl-C can only fill an empty note; it can never make 4.
5. Fixed words only: yes.
6. The tests test what they say for the mapping, the flag in both modes, "already open" through the real
   mutex and the self-check's refusal; not the window procedure's wiring nor the line's count (1 and 2).

## Plants (one at a time)
| Plant | Caught by |
|---|---|
| a: 4 and 6 swapped | `TestTellCloseExitCodes`, `TestTellCloseFlag`, `TestTellCloseAlreadyOpen` |
| b: an error does not win over the person's close | `TestTellCloseResult` |
| c: the flag ignored in the pages mode | `TestTellCloseFlag`, `TestTellCloseWithSelfCheck`, `TestTellCloseAlreadyOpen` |
| d: nil for "already open" with the flag | `TestTellCloseAlreadyOpen` |
| e: a bare `WM_CLOSE` noted as the person's (in `endFromMessage`) | `TestEndNoteSaysHowTheWindowEnded`; the same plant in `mainProc`: not caught |
| f: the end line printed twice | not caught |

## Not checked by the reviewer
Any real window (Alt+F4 inside the engine or mpv, the taskbar's Close, real exit codes); gofmt, vet, the race
detector, the whole window package; the launcher's side. It ran eight named test runs, one at a time through
the track's lock.

## The session's decisions (B7)
- **1: answered by what the coder had done and the reviewer had not been told:** four real windows in the
  pages mode on a scratch folder (the coder's hand-back; `runs-b7/tellclose/look.out`): the X's message with
  the flag: exit 4 and the person's line; a bare close message: 0 and the "from outside" line; a second
  start: 6; the X's message without the flag: 0. NOT seen with a real window: Ctrl-C, the viewer's mode,
  Alt+F4 with the focus in a child window, the taskbar's Close. Said in the entry.
- **2: accepted as it is** (two call sites, one per mode); said in the entry.
- **3 and 4: given to the next piece's coder (W2, the one window, `wip/b-onewin`, cut from ca98432f)**, which
  works in the same functions: a guard in the process-failed handlers when the window is closing, and the
  usage lines. Until W2 is merged: a rare end can give 3 after the person's close; the launcher then opens
  the pages in the browser.
- So NO fix round on `wip/b-winfix`: its full runs go on ca98432f.
