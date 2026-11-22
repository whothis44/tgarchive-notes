# Brief B8-W2c: the way back from the app's pages to the viewer in the one window (session B8, 11-16 20:20)

**The first rule of this project applies to you too: routine steps by a script, not call by call.** You are
one Opus coder. Small piece: about 30 lines of code and a table of tests. Hand back commit-ready and pushed.

## Where
- Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-b-onewin` (branch `wip/b-onewin`, head 99cef0f1, clean,
  equal to `private`). Work only there. Do NOT touch `wt-b-shell` (its full runs are going).
- Module: `archiver/`. Packages you may change: `internal/window` only (and its tests).

## What is wrong (seen by the main session with the real programs on an invented catalogue)
In the joined mode (the one window: the viewer's address plus the named addresses of the app's pages), the
app's pages show a header link "Open viewer". It is a NEW-WINDOW link (`target=_blank`) whose address is the
viewer's address exactly as the pages were given it: its root, `http://127.0.0.1:PORT/`. Since commit
0b08b8e3 (`joinedNewWindow`: a new-window request is followed only for a NAMED address, the review's
finding 1) that request is refused and counted. The window has no back button, so a person who clicked
"Overview" in the viewer's list is left on the app's pages with no way back to the viewer.

## The change
1. `internal/window/joined.go`, `joinedNewWindow(j, uri, read)`: followed in this same window when the
   address was read AND it is either a named address (as now) OR **the viewer's first page exactly**: scheme
   `http`, the host and port exactly the viewer's (`j.viewer.host`), no user part, path empty or exactly
   `/`, no query (not even an empty `?`), no fragment. Everything else on the viewer's address stays refused
   and counted as now (`/post/12`, `/media/...`, `/api/...`, `/?type=photo`, `/#x`, `//`). Write the root
   test as a small pure function of its own (for example `viewerRoot(j, uri)`), parsed with `net/url`, never
   by string prefix.
   Why this is safe (say it in the comment in your own short words): a named page may already send the
   window to any viewer page by a plain link (the navigation rule `allows`); the review's finding was that
   the WINDOW's own navigation carries no other-site mark, so a new-window request could make it load the
   viewer's files and api, and that a viewer page's "open the saved copy" left the window on a raw file.
   The first page is neither: it is the viewer's own document, and it always has the list.
2. `internal/window/pages_windows.go`, `pagesNewWindow`: no new branch should be needed (a followed request
   is counted as "opened here" and navigated; `NavigationStarting` checks it again). Bring its comment up
   to date. Check that the refused-and-counted branch still catches every other viewer address.
3. Tests, `internal/window/joined_test.go`, `TestJoinedNewWindow`: the viewer's root is now `true`; add
   rows, each `false`: the root with a query, with an empty `?`, with a fragment, with a user part, with
   `https`, with a second slash, with another port, `localhost` in place of 127.0.0.1; the root without
   the final slash is `true`; `post/12`, `media/1/file`, `api/meta` stay `false`; unread stays `false`.
4. The joined self-check (the file that prints `selfcheck(joined): (b) a link from the named page ...`):
   add ONE step after (b): the named page of the self-check's own gets a new-window link
   (`target=_blank`) to the viewer's root, the check clicks it by script, and reports
   `selfcheck(joined): (b2) a new-window link from the named page to the viewer's first page followed here: true|false`,
   and one more, a new-window link to a viewer address that is NOT the root (`/about` will do):
   `(b3) ... to another viewer address refused: true|false`. Both count as checks. If this turns out to be
   more than about 40 lines or needs a new mechanism, STOP that step, say so in the hand-back and leave
   the self-check as it is: the rule and its table come first.

## Rules
- Every go command goes through the track's lock: `bash /c/Users/trabi/Claude/Projects/Telegram/runs-b7/shell/scripts/gorun.sh <folder> <command...>`
  (it measures memory and CPU, takes the lock, sources the environment). A full run holds the lock for
  about 8 minutes from 20:08: write the code first, test after. Named tests only:
  `go test ./internal/window -count=1 -run 'TestJoined|TestPages'`; then `gofmt -l internal/window`,
  `go vet ./internal/window`, `GOOS=linux go vet ./internal/window`. No whole-package run of anything
  else, no race detector: the main session runs those once.
- The self-check in the real window, once (at most 2 starts): build `./cmd/tgarchive-window` into a NEW
  scratch folder `C:\Users\trabi\Claude\Projects\Telegram\runs-b8\wayback`, and run it exactly as
  `runs-b7/shell/scripts/pictures2.sh` does (read that script: `LOCALAPPDATA`, `APPDATA`, `TEMP`, `TMP`
  redirected into the scratch folder; `-selfcheck -pages`; `timeout 90`; output to a file), on a COPY of
  the invented archive `runs-b7/shell/arch/invented.sqlite` and its `lib` folder made into your scratch
  folder. No pictures (do not set `TGARCHIVE_JOINED_PICTURES`). Write your script with the Write tool
  (never a Windows path inside a shell string typed on the command line).
- Invented data only. Never open, read or name the owner's folders (`E:\T\...`, the app's folder), never
  stop or start any program but your own scratch one. Print counts and fixed words only.
- Commit in the copy: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message
  ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; then
  `git push private wip/b-onewin`. One commit for the rule and its table, one for the self-check step.

## Hand back (short; it is the only report: you cannot write files outside your scratch folder's outputs)
The new head (8 hex) and that it is pushed; the lines of the named tests, gofmt, both vets; the
self-check's lines (a), (b), (b2), (b3) and its last line "checks N, failed M"; the diff's size; anything
that was not as written here, and anything you doubt.
