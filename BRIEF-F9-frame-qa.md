# Brief F9: the frame's QA round (UI track, session U-1, 11-22)

You are an Opus coder for the UI track of a private Go project (a Telegram archiver for Windows; a WebView2 window,
`internal/window`, over the collector's pages, `internal/server`, the viewer, `internal/viewer`, and the launcher's page,
`internal/launcher`; one shared left list and strip, `internal/appshell`). Work ONLY in your copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-ui-f9` (branch `wip/ui-frame-qa`, cut from `wip/ui-all` 6b659b13: every UI
piece combined). Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `git push private wip/ui-frame-qa`.

## Rules (binding)
The "Rules" section of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-F1-one-frame.md` binds you word for word (invented data
only; the owner's real window is open: never a screen screenshot, never computer-use, pictures only of your own try window
with `runs-ui-1\shot.ps1`; Go through `ix-tools/env-archiver.sh`, one command at a time, named tests only; nothing against
Telegram; Windows paths only through Write/Edit). Your try ports: 18816-18819. Pages' Go handlers and launcher logic are
not yours (ask U-1); `internal/window` is the viewer track's: changes there are ONE lent commit "Lent to the viewer (window):".

## Read first
`reports-qa/QA-6aa225fb.md` (a real-window test of the build BEFORE the UI pieces; its pictures in `reports-qa/6aa225fb/`)
and `NOTE-UI-QA-6aa225fb.md` (which findings the pieces fixed and which are yours here), `DESIGN-ONE-WINDOW.md`, the agreed
picture `design-options/app-look-options.html` ("The combination"; `ui-audit-1121/agreed-design.png`), and the combined
app's pictures `runs-ui-1/all-pictures/` (1-overview, 2-library-tile-selected, 3-chat, 4-settings-folders). Try scripts:
`runs-ui-1/all-try.sh`, `try-joined.sh`.

## The goal: what the QA found that is still there
1. **A dark title bar** (QA 6): the window's caption follows the theme (DwmSetWindowAttribute DWMWA_USE_IMMERSIVE_DARK_MODE,
   and the caption colour where Windows 11 allows it) so no white bar sits over the dark app; light theme keeps a light bar.
2. **Quit never asks in a browser dialog** (QA 7): no `confirm()`/`alert()` anywhere in the pages or the viewer (a test that
   greps the assets); Quit asks in the app's own small dialog (the frame's look, two buttons). Pages are adding a launcher
   route that shows Windows' own Quit question (L3); when that lists, U-1 tells you to switch to it.
3. **Program inside the frame** (QA 4): the list's More › Program opens Settings › Program (F6's section), with the list;
   the launcher's own page is reached only from the notice's Details or when nothing else answers.
4. **The pill and Start say the truth** (QA 6, 13): the strip's pill words agree with the launcher's state and the
   accounts: "Collecting", "Paused", "Not collecting: no account signed in", "Not running" (the latter from F2's notice
   state); the Overview's Start is disabled with one line ("Sign in an account first", linking Accounts) when no account is
   signed in.
5. **One scrollbar** (QA 12): the library shows two vertical bars at the right edge (the grid's and the window's:
   `all-pictures/2-library-tile-selected.png`): one only, the document's; the list's chat scroller starts at a whole row.
6. **The grid by day** (QA 10; design point 3): day headers in the library ("Sat 21 Nov"; "Today", "Yesterday"), the month
   stays in "Jump to" and as a quiet divider.
7. **Duplicate chats told apart** (QA 14): with more than one account, a chat row in the list and in All chats shows the
   account's initials in a small badge (the account filter's label on hover).
8. **Counts with their units** (QA 11): a zero shows "0", never "Open" (Overview's tiles); every count says what it counts
   where it could be read two ways ("posts", "files"); "Gone from Telegram" and "Deleted on Telegram" each get one short
   explaining line (hover or under the tile); "Deleted on Telegram" with none says "Nothing was deleted on Telegram since
   this archive began", not the filters' wording.
9. Check "New since the old archive" in the list when the notice shows (F6's coder saw it missing on the no-collector run):
   find why and fix it if it is ours.

## Done means
- Named tests for each point (the no-confirm grep; the pill words per state; Start disabled; day headers; the account
  badge; zero tiles; the Deleted empty state; the caption's dark mode where testable), appshell whole, gofmt, vet.
- Pictures of the WHOLE app in your real try window (a folder from `make-folder.sh`, invented catalogue with 2 accounts and
  40 chats): the Overview, the library (one bar, day headers), All chats with two accounts, Settings › Program, the Quit
  dialog, dark and light title bars. In `runs-ui-1/f9-pictures/`. Compare each with the agreed picture and say what still
  differs.
- Report: the branch head, files touched (and the lent commit), tests with times, the pictures, what is not done (under 30
  lines). Close your programs.
