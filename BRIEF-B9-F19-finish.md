# Brief F19-finish: complete the UI track's batch selection (viewer session B9 for the archived UI track, 11-22)

You are an Opus coder. The UI track's session is archived; its batch piece F19 stopped unlisted at `wip/ui-batch` f74c7cc2
(a WIP commit) in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-ui-f19` (clean). Finish it THERE, on that branch.
Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, messages ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `git push private wip/ui-batch`.

## Read first
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-F19-batch.md` whole (the goal and "Done means") and the "Rules" section of
`BRIEF-F1-one-frame.md` in the same folder (binding: invented data only; the owner's real window is open: never a screen
screenshot, never computer-use; pictures only of your own try window; Go one command at a time through the track lock
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-b7/shell/scripts/gorun.sh <dir> go ...` with ABSOLUTE output paths;
named tests only; ports 18976-18979; TEMP/TMP outside the project folder). Then `git show f74c7cc2 --stat` and read what
it wrote: `chatbatch.js`, `libselect.js`, the select mode in appshell `shell.js`/`groups.js`, the picker.

## What is left
1. **The viewer's reader of the `as-h` hand-off.** The pages' Hide / Show again cross to the viewer's library with
   `?as-h={"a":"hide"|"show","c":[chat ids]}` (written in `chatbatch.js` and appshell `shell.js` around line 1351).
   Build it in the viewer's page (`internal/viewer/web/js/carryhide.js` and a hook in `main.js`): parse it strictly (an
   object; `a` exactly "hide" or "show"; `c` an array of at most 500 positive integers; anything else ignored), remove
   it from the address at once (`history.replaceState`), and NEVER act on the address alone (any link could carry it):
   show one bar or sheet naming the count (and up to 8 chat names from what the viewer knows, "and N more") with the
   action button and Cancel; only the owner's click posts `/api/hide` `{kind: "chat", id, hidden}` once per chat
   (the existing route, page token, this PC), with the progress line, "N of M done", failures by count, and Undo.
   A device at home's page never reads it.
2. **Everything F19's "Done means" lists:** the named tests (select all respects the search; one question per batch;
   one POST per chat; partial failure words; Undo; the picker's search and ticks; the as-h reader: strict parse, no
   action without the click, the address cleaned, device page ignores it); the security sets before pushing: server
   `-run 'TestAssets|Security|Mutations|TestEmptyCatalogue'`, viewer `-run 'TestWall|TestHomeDevice|TestLAN|Security'`,
   appshell whole; every asset under 600 lines; gofmt; vet of the changed packages.
3. **Pictures** only from your own try window on invented data into `runs-ui-1/f19-pictures/` (Choose chats in select
   mode with the bar and a search; the "Group as…" question; the as-h bar on the viewer). They are for the integrator's
   check; nobody sends them to the owner.

## Hand back (short; numbers only)
The head pushed; what each of the four parts and the reader does in a line; tests by name with seconds; the pictures'
names; anything of F19 you could not finish and why. Stop at the first thing not as written and say it.
