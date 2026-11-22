# Brief F12: the second QA's points still open (UI track, session U-1, 11-22)

You are an Opus coder for the UI track of a private Go project (a Telegram archiver for Windows; a WebView2 window over the
collector's pages, `internal/server`, and the viewer, `internal/viewer`; one frame `internal/appshell` with its control set
and `AppShell.ask`). Work ONLY in your copy `C:\Users\trabi\Claude\Projects\Telegram\wt-ui-f12` (branch `wip/ui-qa2`, cut
from F11c `wip/ui-viewerpages` b3599920, which holds UI-2 c7b4c451 and main 32d48a4c); first merge F10b
`private/wip/ui-copysettings` ccefefc1. Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`,
each message ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `git push private wip/ui-qa2`.

## Rules (binding)
The "Rules" section of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-F1-one-frame.md` binds you word for word (invented data
only; the owner's real window is open: never a screen screenshot, never computer-use; pictures only of your own try window
with `runs-ui-1\shot.ps1`; Go through `ix-tools/env-archiver.sh`, one command at a time, named tests only; nothing against
Telegram; TEMP/TMP outside the project folder). Try ports 18866-18869. Another coder (F11b, `wt-ui-f11b`) rebuilds Accounts,
Queue, Staging, Import, Report and removes the pages' own Theme row: do not touch those pages. Go handlers are pages' or the
viewer's: if a count or field is missing, stop and ask U-1.

## Read first
`reports-qa/QA-32d48a4c.md` (a real-window test of the build WITHOUT UI-2; its pictures in `reports-qa/32d48a4c/`): findings
4 (the pill contradicts the Program page), 6 (numbers that disagree), "New in this build" 2 (a Saved Messages entry "not
read yet" does nothing when clicked) and 3 (the Filters panel stays open when another place opens), the table's row 10
(counts only on New, First seen, Queue), and the integrator's note: "The Overview redraws every few seconds, so clicks miss.
Redraw only what changed, never under the pointer." Check each against your base first (UI-2 fixed several QA points): say
which are already fixed.

## The goal
1. **One truth for "running":** the strip's pill, the Overview's Now and Settings › Program never contradict. Two facts, two
   words: the program (running / not running) and collecting (collecting / paused / not collecting: why). Program says
   "The program runs; nothing is being collected: <why>" where both apply; the pill says the collecting fact.
2. **Numbers that agree or say what they count:** "Held as probable copies" (files), "Probable copies" in the library (posts
   with a probable copy), the Overview's needs row (held files waiting for your word): each label says its unit and what it
   counts, so 118, 191 and 521 cannot read as the same thing; "Saved 2,197 files" opens All media filtered to saved, and the
   view's head says "N posts holding the 2,197 saved files" (or the view counts files when opened from that tile: pick the
   clearer and say why).
3. **Saved Messages not read yet:** a click opens a page (never nothing) that says in one sentence why it is empty and offers
   what to do (e.g. "Read it now" if a door exists to ask the collector to read the account's own chat (Core's K21: find it;
   if no door, say how it will be read and ask U-1 for the door)).
4. **The Filters panel closes** when another place opens (and on Esc, as now).
5. **The Overview never redraws under the pointer:** update only the numbers that changed, in place; a block is never
   replaced while the pointer is over it or a control in it has focus; a click is never lost (a test that clicks while
   updates arrive).
6. **Counts on every library view** (the design: All media, New, Deleted, First seen, Probable copies each with its count):
   if the viewer's Counts lack `lib:all` and `lib:copies`, stop and ask U-1 (B9 adds them); draw "0" for a known zero.

## Done means
- Named tests for each point (the pill/Program words per state; the labels' units; Saved Messages' page and its action; the
  Filters panel closing; the Overview click under updates; the counts), appshell whole, gofmt, vet.
- Pictures (your real try window, invented data): the Overview with the pill and Settings › Program side by side in two
  shots, the library's head opened from "Saved", Saved Messages not read, the list with all counts. In `runs-ui-1/f12-pictures/`.
- Report: branch head, which QA points were already fixed on the base, files, tests with times, pictures, what is not done
  (under 25 lines). Close your programs.
