# Brief G16b: the fixes from the review of G16 (the cap's Settings row) (pages, P7, 2026-11-21)

You are the coder of this fix round: Opus 5.5 at high effort. Hand back commit-ready work on your branch.

## The house rules (binding)
Read `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-P7-review-rules.md`: its privacy, safety and go-command
rules bind you too (invented data; never touch the owner's running program, folder, settings or `E:`;
headless only; `LOCALAPPDATA`, `APPDATA`, `TEMP`, `TMP` redirected to a folder OUTSIDE any git copy (the
review found a run refuses an API settings file inside a repository): use
`C:\Users\trabi\AppData\Local\Temp\p7-g16b`; every go command through `runs-pages-p6/go1.sh`; named tests
only). Commits: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; one commit per finding with its pinned test;
push after each: `git push private HEAD:wip/pages-cap` (only that branch; no merge, no tag, no stash).

## Where
The existing copy `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-cap` (branch `wip/pages-cap`, head
da8c1c3d, clean). Edit only `internal/server` and `internal/collector/livepages`, and the collector's lent
lines only if a finding needs them (say so). Report: append a section "Round 2 (G16b)" to
`archiver/docs/progress/pages-cap-REPORT.md`.

## Read first
`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-G16-cap-row.md` (whole); its probes in
`C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g16-scratch` (`zz_*`).

## What to fix
1. **Finding 1:** the row's state words and the cost sentence say the cap counts per account ("for each
   account"), true of `internal/mirror/newperday.go` and `MirrorCreatesSince`; pinned in the tests.
2. **Finding 2:** the cost sentence no longer says the automatic mirror never ran against Telegram. Use:
   "What many creates in a day cost is not on record yet: the first automatic run made 4, each answered at
   once with no wait; every wait Telegram states is waited out in full." Pinned.
3. **Finding 3:** the "at 500" clause true on this branch alone: "Telegram refuses a new channel at 500,
   and the chat then waits for you" (or the review's words), with a comment that M13 (`wip/mirror-capmax`)
   holds the task itself at 500 and the words change with it; pinned.
4. **Finding 4:** typing in the field clears the answer line; Enter in the field acts as the button.
5. **Finding 5:** every failure that is not the door's own refusal shows "Not stored: " first; the page
   refuses any text that is not digits only before sending.
6. **Finding 6:** the run's-flag words start with a capital and end with a full stop; "N is stored for
   later runs" when a stored value exists.
Then the named tests of the cap (`NewPerDay|AutoNewCost|NoCapConstant|MirrorAutoNewWords|MirrorListEverySetting`
in `internal/server`, `NewPerDay|NoCapConstant` in livepages), gofmt and vet of the two packages.

## Hand back
Branch pushed, copy clean, the report's new section (per finding: done, commit, test). Final message: the
branch's head (8 characters) and one line of what is not verified. Nothing else.
