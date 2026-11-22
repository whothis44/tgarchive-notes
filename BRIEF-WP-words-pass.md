# Brief WP: the words pass on the pages' and the launcher's Go words (pages, P7, 2026-11-22)

You are the coder: Opus 5.5 at high effort, one piece start to finish; hand back a branch ready to list.

## The house rules (binding)
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-P7-review-rules.md` (privacy, safety, every go command through
`runs-pages-p6/go1.sh`, named tests). TEMP, TMP, LOCALAPPDATA, APPDATA of test processes in
`C:\Users\trabi\AppData\Local\Temp\p7-wp\` (outside any git copy). Commits `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`,
ending `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push `git push private HEAD:wip/pages-words` only. Go
only: no front-end file (`internal/server/web`, `internal/appshell`, the launcher's look files) is yours.

## Where
`git -C repo-archiver fetch private && git -C repo-archiver worktree add -b wip/pages-words ../wt-pages-words private/claude/charming-feynman-vm2xia`
(the head 2b38b2a). Report: `archiver/docs/progress/pages-words-REPORT.md` with a table: file, constant, old words, new words.

## The task
The UI track shows each door's words behind an "i" now, so **one short sentence each** is plenty. Shorten the words the UI
track found long or [name removed], keeping every TRUE claim they make (read the code each describes before you cut):
- `internal/server/copychecks.go` about lines 120-140 (the copy checks' costs, `copySetUpFailed`, `copyReadFailed`);
- `internal/server/exactsetting.go` about 28-30 (`ExactWords*`). **The truth that must stay:** a three-places match (or
  every part hash) LINKS the file to the saved one and it is NOT downloaded; `full` falls back to three places where it may
  not run; a comparison that cannot decide ends in the download. Never "skip" or "only held" for the exact check;
- `internal/server/twinhold.go` about 34 (`TwinHoldCost`): keep "nothing is ever skipped by it";
- `internal/server/nas.go` (the "not paired" sentence and `nasHeld`'s words); the alerts' `AlertRecordFailingWords`;
- `internal/launcher/words.go` about 70-98 and 213 (`wordSetupIntro`, `wordHelpData`, `wordVPNList`, `wordSavedUnlooked`).
Find each by name on the head (line numbers moved). Plain words: what it does, what it costs, when it takes effect; no
history, no internals, no paths. A test that pins a word is updated to the new word in the same commit (a word that only
changed length, not meaning); a test that pins a TRUTH (e.g. "not downloaded", "nothing is ever skipped") must still pass
unchanged: if it would not, keep the truth in the new words. Named tests of each file's package, gofmt, vet.
Hand back: head, report path, one line not verified.
