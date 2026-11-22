# Brief F11c: the viewer's remaining pages and the library's polish (UI track, session U-1, 11-22)

You are an Opus coder for the UI track of a private Go project (a Telegram archiver for Windows; the viewer, `internal/viewer`,
serves the library and chats read-only; one frame, `internal/appshell`, with one control set `controls.js`/`controls.css`
and one dialog `AppShell.ask`). Work ONLY in your copy `C:\Users\trabi\Claude\Projects\Telegram\wt-ui-f11c` (branch
`wip/ui-viewerpages`, cut from `wip/ui-chats` 46c3478f). Commit with `git -c user.name=Claude -c
user.email=noreply@anthropic.com commit`, each message ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`;
push only `git push private wip/ui-viewerpages`.

## Rules (binding)
The "Rules" section of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-F1-one-frame.md` binds you word for word (invented data
only; the owner's real window is open: never a screen screenshot, never computer-use; pictures only of your own try window with
`runs-ui-1\shot.ps1` or headless Edge; Go through `ix-tools/env-archiver.sh`, one command at a time, named tests only;
nothing against Telegram; TEMP/TMP outside the project folder). Try ports 18856-18859. Another coder (F11b, `wt-ui-f11b`)
rebuilds the app's pages in `internal/server/web`: do not touch those. Your files: `internal/viewer/web`, and appshell only
for point 4.

## The goal
1. **Copies, Overlap, Changes, About** in the modern style of Settings (F10) and Chats (F11a) (`runs-ui-1/f10-pictures/`,
   `runs-ui-1/f11a-pictures/`): clean lists, a side sheet for a row's details, F10's controls for every choice, whole
   sentences, empty states, no sideways scroll from 900 px. The review of probable copies (`/copies/probable`): one pair at a
   time, the two side by side, the verdict as large buttons with their words, the next pair coming in without a reload.
2. **The library's sparse days** (F9's day headers): days with few items pack side by side on one row (a day's header over its
   own tiles, several days to a row when they fit), so a quiet archive does not show one tile per row.
3. **One theme setting:** the pages' theme and the viewer's theme become one (the viewer's Library display › Theme drives
   both: the strip, the pages and the viewer read the same stored choice; the pages' own theme switch goes). If this needs a
   Go door on the pages' side, stop and ask U-1.
4. **Account badges** (F9) cut chat names in the list: replace the text chips by a small mark on the avatar's corner (the
   account's colour and initial), the full name on hover; All chats keeps the text.

## Done means
- Named tests for each page and the review's verdict flow (every action to its route), no sideways scroll, the packed days,
  the single theme (both servers follow), the avatar mark; appshell whole; gofmt, vet.
- Pictures (your real try window or headless Edge, invented data): Copies, the probable-copy review, Overlap, Changes, About,
  the library with sparse days, the list with two accounts' marks, light theme once. In `runs-ui-1/f11c-pictures/`, for U-1's
  check only.
- Report: branch head, files, tests with times, pictures, what is not done (under 25 lines). Close your programs.
