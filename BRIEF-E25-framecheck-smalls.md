# Brief E25 (merge entry "C18"): four small things in the frame check's start and its hourly lines (copies, session C5, 11-16)

**For an Opus 5.5 coder at high effort. Four small, separate changes in one file of ours and its tests. You
write code and run only the named tests of what you changed; whole packages, vet, the race detector and the
merge of the head are done once, later, by a clerk of the main session. Read only what section 1 names.**

- Copy: make it first, from the Bash tool, from the main head named in your start message:
  `git -C /c/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add -b wip/copies-25 /c/Users/trabi/Claude/Projects/Telegram/wt-copies-25 <the head>`
  (if the branch or the folder exists already, stop and say so). Work only in that copy. Go:
  `. /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then the copy's `archiver`.
- **Go commands: one at a time, each with `GOMAXPROCS=2 GOMEMLIMIT=1GiB GOFLAGS=-p=1`; free memory at least 1.2 GB
  before each (`powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`;
  under it wait 2 minutes and look again); and the track's lock around each: `mkdir /c/Users/trabi/Claude/Projects/Telegram/runs-copies-golock`
  (if it exists wait 30 seconds and try again, 20 minutes at most; a lock older than 30 minutes may be removed and
  taken), `rmdir` right after the command ends, also when it fails. Write the code first, then test.**
- Commit as you go, one commit per point: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`,
  the message ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; `git push private wip/copies-25`
  after each commit. Never another branch; never merge; never tag.
- Invented data only. Nothing runs against Telegram. No log line, test, comment or report carries a real name,
  text, path, id or link; log calls keep constant format strings and print counts and fixed words only.
- You touch `internal/collector/framecheck.go`, `internal/collector/copyset.go` (ours) and their tests. **Not
  `collector.go`, `command.go`, `staging.go`, `account.go`, `words.go` (Core's), no other package.** If a point
  seems to need one of them, do not: say so in the report.

## 0. Where the four come from (each found today by a reviewer or a coder of this track; none changes a file's fate)
The old app has no counterpart for these: they are defects and gaps in code this track merged today (C12, C16,
C17). Nothing here changes what a check decides.

## 1. Read first (in the copy; no more than this)
`internal/collector/framecheck.go`: `claimPartsDir`, `readPartsMark`, `writePartsMark`, `startFrameCheck`,
`partsWord`, `logFrameCheckHour`, `ignoredOf` and where it is called; `internal/collector/copyset.go` (all, 170
lines); `catalog.ProbeStats` in `internal/catalog/probe.go` (the type and the function that fills it); C12's
tests of the mark and of the start's lines in `framecheck_test.go` (their rig).

## 2. The four points
1. **A mark that could not be written whole is not left behind.** `writePartsMark` makes the mark file and then
   writes and syncs it; when the write or the sync fails (a full disk), the file stays, empty or short, and
   `readPartsMark` then refuses that folder at EVERY later start, also when the disk has room again, until
   someone removes the file by hand. Fix: when the write, the sync or the close fails after this call made the
   file, remove that file (and only then: never a mark this call did not make), and answer the first error.
   Test `TestPartsMarkFailedWriteLeavesNothing`: a write that fails through the smallest seam (a function
   variable for the write, or the existing test seam if there is one), then a later start with the cause gone
   sets up cleanly; seen failing once on the head's code.
2. **The part store's refusal is logged with its word doubled** ("collector: collector: ..."): the line's
   format adds a prefix the error's own words already carry. Make the line say it once, without changing the
   error's words (other code and the exit's line use them). A test on the line's text.
3. **The frame check's two record counts are shown.** `catalog.ProbeStats` has `Late` (words that came while a
   lane held the file) and, since C17, `SettledWords` (words that came for a row already settled): nothing
   prints either. Add them to the frame check's hourly lines (`logFrameCheckHour`, when the frame check runs):
   one line, fixed words, two counts; a read that fails is counted or said in fixed words, never a raw error
   with a path. One read of the stats an hour: say in the report what that read costs (which statements).
   A test on the line.
4. **Flags given while their group is off are counted against what is really in force.** When the frame check
   was switched on by its stored setting and its set-up fails (C16: off for this run, the start goes on), the
   line "N flags ... were given while their group is off" has already been said with the check counted as on.
   Make the count right in that case with the smallest change (say the line after the set-up's outcome is
   known, or say a second fixed line only in the failed case: your choice, reasoned in the report); with no
   failed set-up every line of a start is what it is on the head. A test for the failed case and one that the
   normal starts' lines did not change (C12's and C16's "as today" tests must pass unchanged).

## 3. Tests
Named as above or `TestFrameCheckSmalls...`; each seen failing once on the head's code; no existing test
function removed or weakened. Run while working:
`go test ./internal/collector -run 'TestPartsMark|TestPartsDir|TestFrameCheck|TestCopySet|TestFlags|TestKeptParts' -count=1`
(about 2 minutes), `go build ./...`, `gofmt -l internal/collector`. **Not** the whole collector (25 minutes),
no race detector, no vet over packages.

## 4. Hand-back
A report `archiver/docs/progress/copies-framecheck-smalls-REPORT.md`: per point what changed and where, the
test and what breaks it; for point 3 the line's words and the read's cost; for point 4 the choice and why;
**whether any line of a start or of the hourly report changed for a run with the frame check off, or on and
set up without trouble (expected: only the new hourly line when it is on)**; test functions removed (none);
what you could not verify; every doubt. Everything committed and pushed on `wip/copies-25`; the copy clean.
Your last message: the head's short hash, the tests run with their seconds, the answer to the bold question,
the doubts in a few lines.
