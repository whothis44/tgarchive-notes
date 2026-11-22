# Brief F17a / F17b: chats grouped under names, and clutter (UI track, session U-1, 11-22; the owner's priorities 3 and 4)

You are an Opus coder for the UI track of a private Go project (a Telegram archiver for Windows; a WebView2 window over the
collector's pages, `internal/server`, and the viewer, `internal/viewer`; one frame `internal/appshell` with its control set,
side sheet and `AppShell.ask`). Your piece is named in the prompt: **F17a** (chat groups) or **F17b** (clutter). Your copy and
branch are named in the prompt, cut from the main head 2b38b2a. Commit with `git -c user.name=Claude -c
user.email=noreply@anthropic.com commit`, each message ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`;
push only your own `wip/ui-*` branch.

## Rules (binding)
The "Rules" section of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-F1-one-frame.md` binds you word for word (invented data
only; the owner's real window is open: never a screen screenshot, never computer-use; pictures only of your own try window with
`runs-ui-1\shot.ps1`; Go through `ix-tools/env-archiver.sh`, one command at a time, named tests only; nothing against Telegram;
TEMP/TMP outside the project folder). Ports: F17a 18946-18949, F17b 18956-18959. Before pushing, by name: server
`-run 'TestAssets|Security|TestEmptyCatalogue'`, viewer `-run 'TestWall|TestHomeDevice|TestLAN|Security'`; every asset under
600 lines; never a host or port in an asset; never a new outbound call in the viewer. The viewer's and the catalogue's Go are
the viewer track's (B9): a change there is ONE lent commit "Lent to the viewer: …". The pages' Go handlers are pages' (P7): a
write route you add there is ONE lent commit "Lent to pages: …". The two coders: F17a touches appshell's list and the pages'
write route; F17b touches the viewer's library, the post view and Library display: do not touch each other's files.

## The data (agreed with B9: `NOTE-UI-groups-clutter-contract.md` and `DESIGN-B9-groups-clutter.md` in the project folder)
B9's branches are with coders: `wip/b-chatgroups` (groups) and `wip/b-clutter` (clutter). Build against the contract now; merge
the branch from `private` as soon as it is pushed (check `git fetch private` now and then; ask U-1 if unsure), then wire for real.

## F17a: chats grouped under names (the owner: "chats grouped under suggested names, with the owner's manual overrides")
1. In the list's Chats group, a group is a foldable row (its name, its count of chats, a small "suggested" mark when the rule
   made it and the owner has not acted), its chats inside; ungrouped chats as today. Remembered folding (per group).
2. A group's menu (the "⋯" or right-click): Rename…, Join a chat to it… (a picker of chats), Split a chat out (on a member's
   menu), Undo (where `by: "owner"`), and for a suggestion: Keep (makes it the owner's) / Not a group (dismiss, one write).
3. The write route on the pages' server (lent): POST e.g. /api/chatgroups/{set|alone|clear|dismiss} calling SetChatGroup,
   SetChatAlone, ClearChatGroup, DismissSuggestedGroup, the usual guard and page token; the list redraws from the change log.
   When the pages are away (the viewer alone), the menu says so and is off.
4. Choose chats and All chats show each chat's group as a small label; Choose chats can filter by group.

## F17b: clutter (the owner: "hide a channel, group or single post, with undo and a way to see what is hidden; a detector's
## suggestion is shown, never applied silently")
1. Hide a chat (exists), a GROUP (hides each member chat through /api/hide, one confirm naming N chats, undo all), a post
   (exists, F4b): reachable from the list's menus, the chat head's menu and the library's right-click.
2. A "Hidden" place (More, or a library view): hidden chats and hidden posts, each with Show again; "Show all again" behind a
   confirm.
3. The detector: Library display gets "Suggest clutter" (pref `clutter_suggest`, OFF by default, its words: it only marks,
   never hides) and the threshold (`clutter_threshold`, default 70) as a stepper. When on: tiles with `clutter_suggested` carry a
   small mark with `clutter_why` on hover; a library view "Suggested clutter" (`?clutter=suggested`, its count `lib:clutter`)
   lists them, each with Hide / Not clutter (POST /api/not-clutter {media, not}; undoable), and "Hide all N" behind a confirm
   naming N. Nothing is ever hidden without the owner's click.

## Done means (each piece)
- Named tests for every point (menus and their single POST each, the dismiss in one write, the detector never hiding: a test
  that with the switch on and scores present no tile is hidden until a click), the security sets, appshell whole, gofmt, vet.
- Pictures from your real try window (invented data; a fake B9 answer if their branch is not pushed yet: say so): F17a: the list
  with a suggested group folded and open, a group's menu, rename; F17b: the Hidden place, the Suggested clutter view, a tile's mark.
  In `runs-ui-1/f17a-pictures/` or `f17b-pictures/`, for U-1's check.
- Report: branch head, which B9 branch you merged (or not yet), files and lent commits, tests with times, pictures, what is not
  done (under 20 lines). Close your programs.
