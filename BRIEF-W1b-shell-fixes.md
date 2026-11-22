# Brief W1b: the fixes from the review of W1 (the app's pages in the new look) (pages, P7, 2026-11-21)

You are the coder of this fix round: Opus 5.5 at high effort. You hand back commit-ready work on your branch.

## The house rules (binding)
Read `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-P7-review-rules.md`: its privacy, safety and go-command
rules bind you too (invented data; never touch the owner's running program, folder, settings or `E:`; no
window on the owner's screen: headless only, `LOCALAPPDATA`, `APPDATA`, `TEMP`, `TMP` redirected; every go
command through `runs-pages-p6/go1.sh`; named tests only; no race detector). Ports `:0` or from 28100 up.
Long commands in the background (your shell tool stops at 10 minutes).
Commits: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, messages ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; ONE COMMIT PER FINDING with the named test that
fails without it; push after each: `git push private HEAD:wip/pages-w1fix` (only that branch; no merge of
anything, no tag, no `git stash`).

## Where
**The branch is cut from the viewer track's `wip/b-onelist` (dad8caa1), NOT from the main head**: that
branch rewrote `internal/appshell` (the one list for both servers: counts, skipped chats, the viewer's
places, `NoCollector`, an older catalogue drawn per part) and will be merged before yours. From the project
folder: `git -C repo-archiver fetch private && git -C repo-archiver worktree add -b wip/pages-w1fix ../wt-pages-w1fix dad8caa1`.
**Do not edit `internal/viewer`, `internal/window`, `cmd/tgarchive-window` or `internal/launcher`** (other
coders work there now); if a cure needs a line there, write it as a door in your report.
Module in `archiver`. Report: `archiver/docs/progress/pages-w1fix-REPORT.md`.

## Read first
1. The review `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-W1-app-pages-look.md` (whole); its probes are
   in `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-w1-scratch` (`zz_*` files): reuse them as
   real tests where they decide a finding.
2. `internal/appshell` (`shell.go`, `assets/shell.js`, `shell.css`, `shell_test.go`) as on dad8caa1, and
   `git log af4ca40e..dad8caa1 -- archiver/internal/appshell` (what the viewer's coder added: keep it all);
   `internal/server/shell.go`, `web/assets/js/main.js`, `web/index.html`, `base.css`.

## What to fix
1. **Finding 1:** with the viewer as "a window of its own" (the pages' `-viewer-url` ends in the launcher's
   `/viewer` path), the list's viewer places never lead to a 404: give them the launcher's page itself, or
   mark them dead with words of their own ("The viewer is a window of its own: Show the viewer on the
   launcher's page"); say which; a test with that address. Fix it in `internal/server/shell.go`'s options
   (not in the launcher).
2. **Finding 2:** check first what dad8caa1's "an older catalogue drawn per part" already gives (the fixed
   places when a chat read fails?). Then what is left: `shell.js` draws a built-in set of the pages' own
   places when it has no answer at all, and asks again after a failure (a bound, not a tight loop). Test by
   the route answering 500 with a fresh profile.
3. **Finding 3:** the list asked again when `/api/live`'s viewer state changes and on a slow timer (60 s;
   the review measured 0.18 s at 5,000 chats and 2 M messages), keeping the selected entry, the scroll
   place and the keyboard's focus (a redraw never under a focused entry: say how).
4. **Findings 6, 7, 8, 9, 10, 11** as the review's cures say (6: an account not signed in says so; 7: a
   chat with a read under way is never left out by the bound; 8: "Mirrors' settings" lands at the mirrors'
   region of Settings and keeps its selection, or loses its promise; 9: one title, the same words; 10: the
   `?as-try=` aid only in the demo and test runs; 11: the skip link visible when focused).
5. **Finding 5 (the test's narrow width):** the browser test's narrow case at a true 390 CSS px
   (device-metrics emulation as the review's `TestZZW1CDP` does), or say 484 in the test; say which.
6. **Finding 4 is NOT yours** (the launcher's window line; another coder has it).

## Hand back
Branch pushed, copy clean, the report: per finding what was done, its commit and test, what a person now
sees; two headless screenshots (the Overview filled, dark and light at 1400x900, at a true width) looked at
by you; tests added (none removed or renamed without a word); what is not verified. Final message: the
branch's head (8 characters), the report's path, one line of what is not verified. Nothing else.
