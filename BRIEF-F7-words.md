# Brief F7: the words pass over the whole app (UI track, session U-1, 11-22)

You are an Opus coder for the UI track of a private Go project (a Telegram archiver for Windows; a WebView2 window over the
collector's pages, `internal/server`, the viewer, `internal/viewer`, and the launcher's page; one frame `internal/appshell`).
Work ONLY in your copy `C:\Users\trabi\Claude\Projects\Telegram\wt-ui-f7` (branch `wip/ui-words`, cut from F13 `wip/ui-alerts`
8bcc0e3e, which holds every UI piece). First merge pages' L3 `private/wip/pages-crosskill` a99a3b74 (the launcher's QA fixes;
two lent commits in the launcher's look files: 520149cc and a9066224: read them). Commit with `git -c user.name=Claude -c
user.email=noreply@anthropic.com commit`, each message ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`;
push only `git push private wip/ui-words`.

## Rules (binding)
The "Rules" section of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-F1-one-frame.md` binds you word for word (invented data
only; the owner's real window is open: never a screen screenshot, never computer-use; pictures only of your own try window
with `runs-ui-1\shot.ps1`; Go through `ix-tools/env-archiver.sh`, one command at a time, named tests only; nothing against
Telegram; TEMP/TMP outside the project folder). Try ports 18886-18889. Before pushing, by name: server
`-run 'TestAssets|Security|TestEmptyCatalogue'`, viewer `-run 'TestWall|TestHomeDevice|TestLAN|Security'`. Every asset under
600 lines. **Words that come from the Go side** (a door's `words`, `cost`, `why`, fixed refusals) are not yours to change in
the page: list the ones that are long or [name removed] in your report (U-1 asks their owners); you change only words written in the
front end (HTML, JS, CSS content, the launcher's templates).

## The owner's words
"The pages are wordy" (the QA), "too many words" (the audit), and of the whole app: "modern and proper". The look is done:
see `runs-ui-1/f13-pictures/`, `f11b-pictures/`, `f10-pictures/`. Today almost every page opens with a sentence or two of
explanation under its title, every setting row repeats its title in its second line ("Fingerprints of saved videos: off
(default)"), and panels explain at length.

## The goal
1. **One line at most under a page's title**, often none; the rest moves behind an "i" (F10's popover) or a "How this works"
   fold at the page's foot. Lists and cards say facts, not explanations.
2. **Setting rows:** the title, then only the state in a few words ("Off · default", "On", "Takes effect at the next start");
   never the title again; the explanation behind "i".
3. **Buttons** say the action in one to three words; the words before an action that reaches Telegram (cost, what is sent)
   stay whole, in the confirm or above the button, never cut.
4. **Empty states:** one short sentence and one action.
5. **Consistency:** the same thing has one name everywhere (a glossary in your report: e.g. "held", "probable copy",
   "collecting", "mirror", "set aside", "saved"); sentence case; no "the program's own" style filler.
6. **From L3:** the Quit button uses the launcher's native Quit route (shape in L3's `pages-qa1-REPORT.md`) in place of
   AppShell.ask, where the launcher answers; the setup's step nav highlights the shown step (data-at); a refused save's error
   sits beside its field in the frame's error look.

## Done means
- Named tests updated where words moved (do not weaken what they check: a test that pinned a meaning keeps pinning it);
  the security sets; appshell whole; gofmt, vet.
- Pictures (your real try window, invented data): Overview, Queue, Chats with a sheet open, Settings › Downloads and Copies,
  Accounts, Alerts, the setup's VPN step with a refused save. In `runs-ui-1/f7-pictures/`, for U-1's check.
- Report: branch head, the glossary, the Go-side words you found long or [name removed] (file and line), tests, pictures, what is not
  done (under 30 lines). Close your programs.
