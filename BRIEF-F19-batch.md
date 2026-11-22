# Brief F19: batch actions with search, like the old app (UI track, session U-1, 11-22) — usage near the limit: keep it tight

You are an Opus coder for the UI track of a private Go project (a Telegram archiver for Windows; the collector's pages,
`internal/server`, and the viewer, `internal/viewer`; one frame `internal/appshell` with its control set, side sheet and
`AppShell.ask`). Work ONLY in `C:\Users\trabi\Claude\Projects\Telegram\wt-ui-f19` (branch `wip/ui-batch`, cut from F17
`wip/ui-clutter` 1e682d3b: chat groups and clutter are on it). Commit with `git -c user.name=Claude -c
user.email=noreply@anthropic.com commit`, each message ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`;
push only `git push private wip/ui-batch`.

## Rules (binding)
The "Rules" section of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-F1-one-frame.md` binds you (invented data only; the owner's
real window is open: never a screen screenshot, never computer-use; pictures only of your own try window with `runs-ui-1\shot.ps1`;
Go through `ix-tools/env-archiver.sh`, one command at a time; named tests only; nothing against Telegram; TEMP/TMP outside the
project folder). Ports 18976-18979. Before pushing: server `-run 'TestAssets|Security|Mutations|TestEmptyCatalogue'`, viewer
`-run 'TestWall|TestHomeDevice|TestLAN|Security'`, appshell whole; every asset under 600 lines. Use only the routes that exist
(the group writes `/api/chatgroups/{set,alone,clear,dismiss}`, `/api/hide`, `/api/not-clutter`, the chats' collect switches):
one POST per chat is fine; no new Go door; if one is truly needed, stop and ask U-1.

## The owner's words (11-22)
On the one-at-a-time menus for groups and hiding: "Looks a bit clumsy. A batch option with search would be good, like the old
app. Or multiple options." The old app: `wt-v12.32/core-service/internal/webassets/public/js/chat-select.js` (a select mode: tick
chats, or "Select all (N)" over what the tab and the search show, a bar with the count and the action, one sheet that names the
chats and asks once; never reaching chats the search hides) and `gallery-select.js` (the same for media). Read both first.

## The goal
1. **Choose chats: a select mode** (its row checkboxes exist): "Find a chat" filters as you type; "Select all (N)" selects exactly
   what the search and filters show (never hidden ones); a sticky action bar with the count and: **Group as…** (a name: a new
   group or an existing one, picked from a list with search), **Take out of group**, **Hide**, **Show again**, **Collect on / off**.
   Each opens ONE question naming the count (and up to 8 names, "and N more"), then one POST per chat, a progress line, the
   result "N of M done" (failures named by count), and Undo where the action has one.
2. **The list's groups:** "Join chats to it…" opens the same picker with search and multiple choice (ticks), not one chat at a time.
3. **The library:** a "Select" button in the head row: tiles get ticks; "Select all (N)" over what the current view, toggle and
   search show; the bar offers **Hide**, **Not clutter** (on the Suggested view) and **Show again** (on the Hidden view), with the
   same one question and Undo. (Ctrl/Shift-click from F4b keep working.)

## Done means
- Named tests: select all respects the search; one question per batch; the POSTs per chat; partial failure words; Undo; the
  picker's search and ticks; the security sets; gofmt, vet.
- Two pictures from your real try window: Choose chats in select mode with the bar and a search; the "Group as…" question.
  In `runs-ui-1/f19-pictures/`.
- Report: branch head, files, tests, what is not done (under 12 lines). Close your programs.

## Added (the owner, 11-22): "Yes, grouping the batch is probably good. Hiding should have that batch option as well. But also, from the main screen, like your mockup."
4. The LEFT LIST (appshell): a "Select" toggle at the Chats group's head; ticks on chat rows (a group's tick ticks its members);
   "Select all (N)" over what "Find a chat" shows; a compact action bar at the list's foot: Group as…, Take out of group, Hide,
   Show again; one question, one POST per chat, "N of M done", Undo; Esc leaves. Batch Hide everywhere batch is offered.
