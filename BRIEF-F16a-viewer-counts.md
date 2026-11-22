# Brief F16a: the list's counts on the viewer's pages, and two consistencies (UI track, session U-1, 11-22)

You are an Opus coder for the UI track of a private Go project (a Telegram archiver for Windows; a WebView2 window over the
collector's pages, `internal/server`, and the viewer, `internal/viewer`; one frame `internal/appshell`). Work ONLY in your
copy `C:\Users\trabi\Claude\Projects\Telegram\wt-ui-f16a` (branch `wip/ui-viewercounts`, cut from F15 `wip/ui-nasgive`
b9766541, which holds every UI piece). Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each
message ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `git push private wip/ui-viewercounts`.

## Rules (binding)
The "Rules" section of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-F1-one-frame.md` binds you word for word (invented data
only; the owner's real window is open: never a screen screenshot, never computer-use; pictures only of your own try window with
`runs-ui-1\shot.ps1`; Go through `ix-tools/env-archiver.sh`, one command at a time, named tests only; nothing against Telegram;
TEMP/TMP outside the project folder). Try ports 18916-18919. Before pushing, by name: server
`-run 'TestAssets|Security|TestEmptyCatalogue'`, viewer `-run 'TestWall|TestHomeDevice|TestLAN|Security|TestPagesCounts'`. The
viewer's outbound rule: its ONE read of the pages is pinned (TestWallPagesCountsOneClient, TestWallShellLiveOneClient): never a
new outbound call; the viewer track (B9) owns `internal/viewer`'s Go: a change there is ONE lent commit "Lent to the viewer:".

## What U-1 saw (the merged main be291417, a real joined window: `runs-ui-1/try-final.sh`, pictures `runs-ui-1/final-pictures/`)
1. On the viewer's pages (the library, a chat) the list shows NO count beside Alerts, Mirrors and Queue, even after more than a
   minute, while the same list on the pages' pages shows Alerts 7, Mirrors 3, Queue 396. The pages answer
   `GET /api/counts` → `{"alerts":7,"mirrors":3}` (checked directly). So the viewer does not take or does not pass them on:
   find where (the viewer's pagescounts.go reader: its address check, its Host header, its readiness, the keys it keeps; the
   viewer's shell mount passing Counts; appshell drawing those keys on a viewer page) and fix it, with a test that a joined
   viewer's /api/shell carries `alerts` and `mirrors` when the pages answer them.
2. The Queue's count (files waiting) is drawn on the pages' pages from the Overview's numbers, never on the viewer's pages: ask
   U-1 before adding a key (pages would add `queue` to /api/counts and the viewer's key list): first say what it needs.
3. Choose chats' rows show the accounts as text badges ("PK", "OB") while the list uses F11c's small marks on the avatar's
   corner: use the same marks on Choose chats' rows (All chats in the viewer keeps text, as decided).

## Done means
- The test for point 1; a test for point 3; the security sets; appshell whole; gofmt, vet.
- Pictures from a real joined try window built from your branch: the library with the list's Alerts, Mirrors (and Queue if done)
  counts; Choose chats with the marks. In `runs-ui-1/f16a-pictures/`.
- Report: branch head, the cause of point 1 in one line, files (and any lent commit), tests, pictures, what point 2 needs (under
  15 lines). Close your programs.
