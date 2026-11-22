# Brief B3-15: the second viewer review's fixes (session B3, 11-15)

You are an Opus coder. Work only in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-faces`. First:
`git fetch private wip/b-nofaces && git checkout -B wip/b-review2fix private/wip/b-nofaces` (a713cfc). Go
module: `archiver/`. Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in each
Bash call. Package: `archiver/internal/viewer` only (Go and `web/`). One commit per finding, pushed to
`private` as `wip/b-review2fix` (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending
with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; no archive numbers).

Read first, in full: `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-B3-viewer-2.md` (an independent
read-only review of a713cfc: 5 confirmed, 3 probable). The main session decided: **fix every finding**, as
follows where the review leaves a choice.

1. **The library's endless reload after a preference change elsewhere.** A listing's identity must change
   whenever anything its filter key depends on changes: saving preferences bumps the decisions version; the
   identity also carries a part made at random when the viewer starts (so an identity from before a restart
   never matches). And the page itself must never loop: a forced reload that comes back stale again is
   retried at most 3 times, spaced 1, 2 and 4 s, then the page shows one line "The library changed while it
   was loading. Reload" with a button, and stops. The same bound on the review page, the Overlap page and
   the Deleted page wherever they reload by themselves. A named Go test for the identity; a named test that
   reads the scripts for the bound, as the package's other script tests do.
2. **"+n probable" on a tile per post** counts only folded files whose face has a tile in this listing (the
   `faceIn` bit), so a file never has a tile of its own and a place in a "+n" at once; the post page's fold
   card agrees with the tile. A named test with a type filter and with "Not downloaded" in album mode.
3. **The review page's keys.** A card is busy from the key press or click until the server's answer; S, N
   and the buttons skip busy cards and act on the first card that is neither done nor busy; a failed
   request frees the card and says so. The page shows what the server kept (the answer carries the verdict).
   A named script-reading test.
4. **The album strip** uses the grid-made test (`gridOf`), as the other grid consumers do.
5. **The two hiding chips** ("Hidden posts: N", "Clutter hidden: N"): the number and the listing the chip
   opens must be the same count. Either the opened listing is built with the same rules the count was made
   under (the fold off, the other hiding rules as in the listing the chip is on), or the chip says what it
   counts in words that are true ("N tiles here"). Choose the first if it is a few lines; say which. A named
   test that the chip's number equals the opened listing's total, in both tile modes.
6. **The probable ones:** the shape request that fails is retried with the same 1, 2, 4 s bound (no reload
   without a pause); the arrows with "Hide not downloaded" walk only what is shown.
7. **The cost notes:** apply those that are a kept value instead of a recomputation and a few lines each;
   list the others in the hand-back with what each would save. One measured constraint: the default
   library's first build per index version is 150 to 190 ms on the real catalogue (budget 200).

## Tests
The named tests while working (`-run`). Then once at the end: `go test ./internal/viewer -p 1` (about 3.5
minutes, in the background), `gofmt -l`, `go vet ./internal/viewer`; the scripts parse as modules
(`TestPageScriptsParseAsModules`). No race detector, no mutation checks, one go command at a time.

## Rules
- Never open the viewer on real data or any real file; nothing against Telegram; do not touch
  `repo-archiver`, other `wt-*` folders or other packages. Do not merge into or push
  `claude/charming-feynman-vm2xia`, `wip/b-viewer`, `wip/b-viewer2` or `wip/b-nofaces`.
- Every route is registered with an access class (`access.go`); if you add one, name its class.
- Concurrent code: say exactly what requests share that you changed.

## Hand back (short)
Commits per finding, differences from this brief and why, named tests, whole-package time and result, the
cost notes applied and not applied, anything in the review you found to be wrong, doubts.
