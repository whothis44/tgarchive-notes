# Independent review: W1v, the app's one list on the viewer's pages (session B9, 11-21)

You are an independent Opus reviewer. Review the branch `wip/b-onelist` (head dad8caa1) against the main head
af4ca40: `git -C C:\Users\trabi\Claude\Projects\Telegram\wt-b-onelist diff af4ca40e..dad8caa1`. Do not edit
that copy. For probes, make your own scratch worktree from dad8caa1
(`git -C C:\Users\trabi\Claude\Projects\Telegram\repo-archiver worktree add --detach C:\Users\trabi\Claude\Projects\Telegram\wt-b9-review-W1v-scratch dad8caa1`)
and work only there; commit nothing, push nothing.

## Rules
- Invented data only. Never open the owner's real folder, catalogue, viewer or media, `E:\T\tg-dl`, or
  `%LOCALAPPDATA%\tgarchive*`. Print counts and timings only.
- Every `go` command through the lock, one at a time:
  `bash /c/Users/trabi/Claude/Projects/Telegram/runs-b7/shell/scripts/gorun.sh <dir> go test ./internal/x -run 'Name' -count=1`.
  Named tests only (`internal/appshell` whole is fine: about 5 s). No whole `internal/viewer`, no race
  detector. Do not open a window on the screen.

## What the piece is meant to do (the goal, not its author's claims)
The app is one window with one list on the left (`C:\Users\trabi\Claude\Projects\Telegram\DESIGN-ONE-WINDOW.md`;
the joint note `DESIGN-ONE-WINDOW-HOW.md` sections 2, 3, 4 and 9). Two servers draw pages in that window: the
collector's pages (`internal/server`) and the viewer (`internal/viewer`). The list is the pages track's package
`internal/appshell`; this piece mounts it on the viewer's pages too and removes the viewer's own list, so the
list is the same whichever server drew the page. The brief the coder worked from:
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-B9-W1v-one-list.md` (with pages' two changes in part A).

## Look hardest at
1. **Security walls of the viewer:** the shell's three routes on the viewer's listeners (this PC and the
   device-at-home listener, `lan.go`, `access.go`): can a device at home reach `/api/shell` or the shell's
   files, or get a page that loads them; can another web site read the list (it holds chat titles); does the
   page's CSP still hold (`script-src 'self'`); is any catalogue text put into the page as HTML anywhere
   (shell.js and the viewer's page scripts); the viewer must import neither Telegram code nor
   `internal/server` (its wall tests).
2. **The viewer's catalogue handle:** the list reads through the clicks' read-only handle (`actCatalogue`):
   can it write, can it hold a lock that blocks the collector's writer, what happens when the catalogue file
   does not exist yet or is replaced (the window waits up to 60 s for a catalogue made by the setup), and what
   a list request costs on a large catalogue (pages measured its own at 5,017 chats: median 184 ms).
3. **Older catalogues:** the old archive's window opens a catalogue at schema step 16 and the viewer opens
   older ones on purpose. Is the per-part degrading right (an older file vs. a real error of this build), and
   does anything else in the piece break on an older file?
4. **The router and the page:** the shell's hook into the viewer's one-page router (no reload for a viewer
   place, a real navigation for a pages place), the selected entry for every viewer address, the search box's
   move, the post view covering the whole window, Esc and Back, the narrow width, a device's page unchanged.
5. **The lent part in `internal/appshell`:** pages' own server uses it too (`internal/server/shell.go`):
   does anything change for the pages' list that pages did not ask for?
6. Anything else you find: correctness first.

## Output
Write your review to `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-B9-W1v-one-list.md`: findings numbered,
each with its weight (must fix / should fix / minor), the file and line, what goes wrong, and how you know (a
probe you ran, with its numbers, or the lines you read); then one line: "may be listed", "may be listed after
these fixes: N, M", or "not to be listed". Your final message: that line and the count of findings by weight.
