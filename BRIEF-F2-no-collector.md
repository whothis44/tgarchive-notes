# Brief F2: the library opens without the collector (UI track, session U-1, 11-22)

You are an Opus coder for the UI track of a private Go project (a Telegram archiver; the app is a WebView2 window over the
collector's pages, `internal/server`, the viewer, `internal/viewer`, and the launcher's own page, `internal/launcher`).
Work ONLY in your copy `C:\Users\trabi\Claude\Projects\Telegram\wt-ui-f2` (branch `wip/ui-nocollector`, cut from F1's
`wip/ui-frame` 5bf253bc; first merge pages' `private/wip/pages-bringin` b141da57 into it). Commit with
`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `git push private wip/ui-nocollector`.

## Rules (binding)
The "Rules" section of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-F1-one-frame.md` binds you word for word (invented
data only; the owner's real window is open: never a screen screenshot, never computer-use, pictures only of your own try
window with `runs-ui-1\shot.ps1`; Go through `ix-tools/env-archiver.sh`, one command at a time, named tests only; nothing
against Telegram: a try never has an API file or a session, so the collector refuses to start: that is exactly the case
to show). Pages' launcher logic (`internal/launcher` except `ui.go`/`look.go`/`page.go`) is not yours: ask U-1.

## Read first
`AUDIT-UI-1121.md` point 3 and picture `ui-audit-1121/3-no-collector-no-app.png` (today: no collector, no app);
`archiver/docs/progress/pages-bringin-REPORT.md` on the branch (the door: the launcher starts the joined window viewer-first
when the collector cannot start, the launcher's page as a `-pages` address; `GET /api/state` on the launcher:
`{"collector":"running|starting|not-running|stopping","why","since","page","action"}`, CORS for the launcher's own
origins); `internal/appshell` (F1's frame: the strip, the pill, PagesOff's dead words).

## The goal
1. **The notice:** when the launcher says the collector is not running (or starting, or stopping), a one-line notice sits
   in the strip under the search box or as the strip's first line: a dot, the `why` words (fixed words from the launcher,
   e.g. "Not collecting: not signed in"), and one button with the `action` words (e.g. "Start again") or "Details" leading
   to the launcher's `page`. It is the same on every page of every server. When the collector runs, nothing shows.
   Asked every 15 s and when the window regains focus; a failed ask shows nothing new (never a second error).
2. **CSP:** both servers' Content-Security-Policy `connect-src` must allow exactly the launcher's origin (the address the
   server was told: the pages' `-launcher-url`, the viewer's from the joined window's second `-pages` address), nothing
   wider; or, if a server does not know the launcher's address, the shell does not ask. Tests for both headers.
3. **The list while the collector is away:** the pages' places (Overview, Queue, Choose chats, Accounts, the pill) show as
   what they are (PagesOff words, greyed, a click shows the notice's Details) instead of dead links or errors; the library,
   chats and the viewer's Settings work as normal. The window opens on the library.
4. **The launcher's "Not running" page** (`ui.go`/`look.go`/`page.go`, yours) in the app's look (the frame's colours and
   type, no log paths or watchdog lines in the first view: those go under a folded "Technical details"), with its buttons
   (Start again, Change the folders, Close) as today.

## Done means
- Named tests: the shell's notice (state answers: running, not-running with action, starting, a failed ask), the CSP
  headers on both servers, the launcher page's markup; internal/appshell whole; gofmt, vet.
- A try folder built with `deploy/folder/make-folder.sh` into `runs-ui-1/try-f2/folder` with an invented catalogue
  (`tgarchive fabricate`), ports 18786-18788 changed in its `tgarchive.json` to 18806-18808, LOCALAPPDATA etc. redirected,
  started as the owner starts it (`tgarchive.exe`, in the background, output to files). The collector refuses (no API file):
  pictures by `shot.ps1` of the window: the library with the notice; the list with the pages' places greyed; the launcher's
  page after Details. In `runs-ui-1/f2-pictures/`. Then end your try programs (Close on the launcher's page, then stop
  any left by their process path inside your try folder only).
- Report back: the branch head, files touched, tests with times, the pictures, what is not done or not verified (under 30
  lines).
