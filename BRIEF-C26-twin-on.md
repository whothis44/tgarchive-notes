# Brief C26: lesser copies wait behind the best, ON by default

For ONE coder (Opus 5.5, high effort). Written by the copies session C7, 2026-11-21. Small piece, no schema step.
Why (read it): `ANSWERS-for-archiver-10.md` in the project folder (the old app's twin holds: 516 of 644 pairs of
different Telegram files were the same content, 80%; 1,127 of 1,255 with the same file, 90%; a wrong hold costs a
wait, never a file; two release paths of the old app were wrong and must not exist here). The switch is C22's
(`copies.twin_hold`, `internal/catalog/twin.go`), merged as schema step 27.

## 1. Where and how you work (these bind)
- Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-30`, branch `wip/copies-30`, cut from the main head
  named in your start message (it holds C22). Only there; `git -C` and full paths, never `cd` in a compound
  command.
- Every go command through `bash /c/Users/trabi/Claude/Projects/Telegram/runs-copies-c26/go1.sh <log name> <go args...>`
  (the track's lock; memory check; logs in `runs-copies-c26/`). Named tests only; no whole package; no race
  detector. Other coders of this track share the lock.
- Files: `internal/catalog/twin.go`, the `twin_*_test.go` files and new test files in `internal/catalog`, and any
  other test file in the repository whose test assumed the switch off when no row is stored (list each in the
  report; change only what that assumption needs). Anything else: stop and say why.
- Commits with `git -C <copy> -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push `wip/copies-30` to `private` after each.
  Invented data only.

## 2. The change
1. `TwinHold`: on when its row is "1" **or when no row is stored**; off only when the stored row says "0" (or any
   other stored value: say in the report what a stored value that is neither "0" nor "1" now means, and keep it
   off: fail closed, TRIED-BEFORE 25 rule 13: a corrupt stored value never reads as the risky choice; here "on"
   holds more, which costs a wait only, so say which you chose and why). `stored` keeps its meaning. The comments
   of `twin.go` (the package comment, `twinHoldKey`, `TwinHold`, `SetTwinHold`) say "on by default" and why, with
   the two counts above.
2. `SetTwinHold(false)` stores "0" (it does today: check), so the owner's "off" stays off across builds.
3. **Two tests that pin what the old app got wrong** (each must pass; say whether it would have failed before):
   - A file waiting behind a queued better copy is never made wanted by a frame check's "no match" of anything
     (its own or the better copy's, the same Telegram file or not): a world where the better copy is probed and
     judged "no match" against saved videos, and the waiting file stays waiting until the better copy stops
     coming. Look first whether a waiting file can be probed at all (it is held with `probable = 0`, out of the
     lanes); say what you found.
   - A better copy that ends saved ONLY as a link (rung 2, the same Telegram file as a saved one; and separately
     the exact check's `LinkSame`) sends the waiting file to the door, and the door judges it against that saved
     file (rung 6 against the saved files: held as a probable copy, or marked for the exact check first, when it
     still looks alike), never wanted without a comparison.
4. Every test that relied on "off when nothing is stored" either stores "0" first or expects the new default.

## 3. What done is
The change, the tests, all named tests of the twin piece and of every test file you touched passing
(`-run 'TestTwin'` and the named ones), `gofmt -l` clean on your files, committed and pushed, and a short report
`archiver/docs/progress/copies-twin-on-REPORT.md`: what changed, the two tests and what they found, each test
file changed and why. Hand back with the branch's head. Stop at the first thing not as written and say it.
