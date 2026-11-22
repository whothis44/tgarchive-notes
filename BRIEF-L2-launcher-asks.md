# Brief L2: four small launcher asks from the UI track, and two make-folder tests (pages, P7, 2026-11-22)

You are the coder: Opus 5.5 at high effort, one piece start to finish; hand back a branch ready to list.

## The house rules (binding)
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-P7-review-rules.md` (privacy, safety, every go command through
`runs-pages-p6/go1.sh`, named tests). TEMP, TMP, LOCALAPPDATA, APPDATA of test processes in
`C:\Users\trabi\AppData\Local\Temp\p7-l2\` (OUTSIDE any git copy). No window on the screen (stand-ins). Invented data
only. Commits `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`;
push `git push private HEAD:wip/pages-asks` only. **The launcher's look files (`ui.go`'s rendering, `look.go`,
`page.go`) are the UI track's (U-1)**: logic, words, routes and settings are yours; a line in their files only as
ONE commit "Lent to the UI (launcher look): ...".

## Where
`git -C repo-archiver fetch private && git -C repo-archiver worktree add -b wip/pages-asks ../wt-pages-asks private/wip/ui-settings`
(U-1's F6 06d36442, listed: it holds L1, F1, F2; build on it so the words meet F6's buttons). Report:
`archiver/docs/progress/pages-asks-REPORT.md`. Also read `private/wip/pages-statewords` (SW, 55a381f0, listed; it
also holds L1): if F6 and SW meet in a file, merge SW in first and say each resolution.

## What to build
1. **Words** (`words.go`, the bring-in's): `wordBringCounted` and the JSON `action` to "Stop the app for about 15
   minutes and bring it in"; the offer's second button "Show me first" (the dry run); read F6's cards
   (`page.go`, `bringinpage.go` on F6) and make every bring-in word the cards show agree with the buttons.
2. **`GET /change?folder=library|staging|data`**: opens "Change the folders" directly at that folder (the same
   confirm and stop as today, the chosen folder's box opened first); the same guard and token as the launcher's other
   actions; an unknown folder refused in fixed words. Tests.
3. **The close question's answer remembered** (keep collecting / quit), for Settings > General: a stored choice and a
   route to set it and to forget it ("ask me each time", the default). **Not in `tgarchive.json`**: an older build
   refuses a settings file with a field it does not know (`DisallowUnknownFields`, see the review of G19, finding 3);
   keep it in a small file of its own beside it (e.g. `launcher-prefs.json`, version 1, unknown fields ignored), read
   at start, written atomically. With a remembered answer the close box is not shown and the answer is taken; say so
   in the close's log line (constant format). Tests (the box not started with a remembered answer; Quit and Keep each).
4. **`TestMakeFolderMarkWrittenFirst` and `TestMakeFolderHalfReplacedSaysSo` fail on F2's base and on F6** (U-1's
   report). Find why: most likely the test's folder inside a git copy (make-folder refuses that) or TEMP; or the
   running check seeing another test's stand-in. Fix the test (or the script if it is the script's), say the cause.
5. **(If the viewer track says `plan` prints them)** the dry run's `total.*` counts carried in `/api/bringin`'s
   `counts` as they are printed (they may already be: check; if plan does not print them, say so in the report).

## Hand back
Branch pushed, copy clean; the whole `internal/launcher` once (TEMP outside a git copy), gofmt, vet; the report.
Final message: head, report path, one line not verified.
