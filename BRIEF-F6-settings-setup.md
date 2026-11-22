# Brief F6: Settings, the setup and the bring-in step in the app's look (UI track, session U-1, 11-22)

You are an Opus coder for the UI track of a private Go project (a Telegram archiver; the app is a WebView2 window over the
collector's pages, `internal/server`, the viewer, `internal/viewer`, and the launcher's own page, `internal/launcher`).
Work ONLY in your copy `C:\Users\trabi\Claude\Projects\Telegram\wt-ui-f6` (branch `wip/ui-settings`, cut from F2's
`wip/ui-nocollector` 67d6f50b, which holds F1's frame, pages' L1 (the bring-in step) and T1 (the twin-hold switch)).
Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `git push private wip/ui-settings`.

## Rules (binding)
The "Rules" section of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-F1-one-frame.md` binds you word for word (invented
data only; the owner's real window is open: never a screen screenshot, never computer-use, pictures only of your own try
window with `runs-ui-1\shot.ps1` or headless Edge; Go through `ix-tools/env-archiver.sh`, one command at a time, named
tests only; nothing against Telegram). Your files: the pages' Settings and Accounts front end
(`internal/server/web/assets/js/pages/settings.js`, `mirrorsettings.js`, `clicksettings.js`, `accounts.js`,
`programregion.js`, the CSS), the launcher's `ui.go`/`look.go`/`page.go` (the setup, the change of folders, the bring-in's
views). Go handlers, routes and their data are pages' (P7): where you need a field or route that is not there, stop and
ask U-1; never change a route's meaning. Pages' launcher logic (other launcher files) is not yours.

## Read first
`DESIGN-ONE-WINDOW.md` ("Folders are changed in Settings with Windows' own folder box..."; "a setup page that is not
ugly"), the owner's 11-16 words in its first section ("the setup screen is ugly and there's no folder selection boxes, just
paths"), `AUDIT-UI-1121.md` points 6 and 8, picture `ui-audit-1121/` and today's Settings in `runs-ui-1/f1-pictures/4-settings.png`.
Pages' report for the bring-in: `archiver/docs/progress/pages-bringin-REPORT.md` (GET /api/bringin, one answer per phase:
offer, choose, counting, counted, refused, stopping, running, after, done, not-offered; counts, progress, words, action,
yes). The counts' words: `DESIGN-UNIFIED-ARCHIVE.md` §4 (in the old archive / probably / partly / new; "seen by the old
app, never saved"). The twin-hold switch: GET /api/settings `twin_hold` {on, stored, words, cost}; POST
/api/settings/twin-hold {on}.

## The goal
1. **Settings, calm and grouped:** a left column of sections inside the page (General, Library display (the viewer's, as
   F1's card leads there), Folders, Downloads, Copies, Mirrors, Acting in chats, Accounts, Program), one section shown at
   a time, the address keeping it (`#/settings?s=folders`). Each setting one row: its name, one short line, the control
   at the right; "Not a setting" facts (the engine's fixed numbers) move into a folded "How downloading works" under
   Downloads. Every setting that exists today stays and keeps its route and guard.
2. **Folders with Windows' own folder box:** the library, staging and data folders each shown as a path with "Change…"
   that opens the folder box the launcher already has (`folderbox*.go`, `change.go`: find how the setup page opens it and
   use the same route; if the pages' Settings cannot reach it, the button leads to the launcher's "Change the folders"
   step, which does). The second yes for a folder that is not empty and not this catalogue's, as decided.
3. **Copies:** the twin-hold switch (T1) as a row, its words and its cost said before the click.
4. **The setup and the change of folders** (launcher pages) in the app's look: a few steps (Welcome; Library folder;
   Staging folder; VPN adapter; Ready), each a folder path with "Choose…" (the folder box), what the setup sees said in one
   line under it, the red box only when something is truly wrong, never as the first thing seen.
5. **The bring-in step** (launcher, from `/api/bringin`): one card per phase in the app's look: the offer (one sentence
   and "Show me first"), the counts before (the four words with numbers, adding up to the account's files; "seen by the
   old app, never saved" as a note), the one yes (the button names what happens: "Stop the app for about 15 minutes and
   bring it in"), progress (a bar and the numbers), the counts after, refused (why, in one line, and what to do). Draw
   from the JSON only; pages' plain views are replaced.
6. Both themes, the narrow width, an empty catalogue.

## Done means
- Named tests: settings' sections and address, each existing setting still present and posting to its route (a test
  that lists them), the twin-hold row, the launcher's setup/change/bring-in markup per phase (a fixture for each JSON
  phase); appshell whole; gofmt, vet.
- Pictures (your try window or headless Edge, invented data): Settings' General, Folders, Copies, Downloads with the folded
  facts; the setup's first step and its folder step on an empty folder; the bring-in's counted and after phases (from
  fixtures if a real try cannot reach them: say so). In `runs-ui-1/f6-pictures/`.
- Report back: the branch head, files touched, tests with times, the pictures, what you needed from pages and did not
  have, what is not done or not verified (under 30 lines). Close your programs.
