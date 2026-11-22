# Brief E23 (merge entry "C17"): a settled frame-check row is not rewritten by a later word (copies, session C5, 11-16)

**For an Opus 5.5 coder at high effort. One guard in one function and its tests. You write code and run only the
named tests of what you changed; whole packages, vet and the merge of the head are done once, later, by a clerk
of the main session. Read only what section 1 names.**

- Copy: make it first, from the Bash tool, from the main head named in your start message:
  `git -C /c/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add -b wip/copies-23 /c/Users/trabi/Claude/Projects/Telegram/wt-copies-23 <the head>`
  (if the branch or the folder exists already, stop and say so). Work only in that copy. Go:
  `. /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then the copy's `archiver`.
- **Memory and the track's lock: one go command at a time, each with `GOMAXPROCS=2 GOMEMLIMIT=1GiB GOFLAGS=-p=1`;
  free memory at least 1.2 GB before each
  (`powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`;
  under it wait 2 minutes and look again); before each go command take the lock with
  `mkdir /c/Users/trabi/Claude/Projects/Telegram/runs-copies-golock` (it fails when another coder of the track
  holds it: wait 30 seconds and try again, 20 minutes at most; a lock folder older than 30 minutes may be removed
  and taken) and `rmdir` it right after the command ends, also when it fails. Write the code first, then test.**
- Commit as you go: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; `git push private wip/copies-23` after each commit.
  Never another branch; never merge; never tag.
- Invented data only. Nothing runs against Telegram. No log line, test, comment or report carries a real name,
  text, path, id or link.
- You touch `internal/catalog/probe.go` and its tests (ours), nothing else: not `lane.go`, not `state.go`, no
  schema step, no other package. If the fix seems to need more, do not make it: say so in the report.

## 0. What was found, and what the old app knows
- Found today by an independent reviewer with a probe (`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-E21-probe-misses.md`,
  finding 3 and its probe P4 in
  `wt-copies-review21-scratch\archiver\tools\probe-misses\zz_probe_review_test.go`: read both): **`probeSettle`
  lets a later decisive word (copy, partly, no match) rewrite the result and the named file of a row that is
  already settled, when the file is held.** In the probe: a "copy" word naming file X held the file (result
  `copy`, `of_file` X); a later "no match" word naming Y left it held with result `nomatch`, `of_file` Y; a
  third "no match" naming nothing left it held with result `nomatch` and no named file. The hold itself and its
  probable edge were not touched: only the row.
- Why it matters: the row is the record of why a file is held, and it is what is counted after the owner's first
  real run (the tool `tools/probe-misses`, in review beside this piece, judges each verdict against the file
  its row names). The old app's own record held one row per checked item with its LAST outcome
  (`ANSWERS-for-archiver-8.md`, section C: "One row per item holds its last outcome"), and its table could not
  say what a file was first held for; the new app's rule is stricter on purpose: **a hold's evidence is kept as
  it was when the hold was made** (the frame check's "copy" is the one verdict that can be trusted: 184 right
  of 188; a "no match" is wrong about 3 times in 4: a later "no match" must never overwrite a "copy").
- No file's fate is wrong today because of it (a held file stays held either way). This piece changes no fate.

## 1. Read first (in the copy; no more than this)
- `internal/catalog/probe.go`: `probeSettle` in full (about lines 794 to 1010) with the comment above it and
  the words' kinds (`VerdictCopy`, `VerdictPartly`, `VerdictNoMatch`, `VerdictUnknown`, `VerdictFinal`,
  `VerdictMoreParts`), `writeProbeRow`, and the counters this file keeps in the settings table (`countSetting`,
  `keyProbeLate`).
- The existing tests of `probeSettle` on a done row and on a held file (search the test files of
  `internal/catalog` for `ProbePhaseDone` and `held`): take their rig.

## 2. What to build
- **A row that is settled with a decisive result (`copy`, `partly`, `nomatch`) is final as a record.** Any later
  word on it, of any kind, whatever the file's state (held, free, in a lane, saved, gone): the row's result,
  why, named file, hits, samples, offset and frames stay exactly as they are; the row's `at` stays as well (it
  is when it was settled); nothing else of the file changes; the word is counted once in a new counter of the
  settings table (name it beside `keyProbeLate`, e.g. "a word on a settled row") and the call answers the fate
  the function already has for "the word does not act" (`FateLeft`, or `FateLate` when a lane holds the file:
  keep today's distinction and its own count).
- **What stays as today:** a row done as `unchecked` or `left` (or with no result) still takes a decisive word
  exactly as it does now (that is how a file let through unchecked, or a row closed for a held file, can still
  get its verdict); a row not done is untouched by this piece; every fate of every other path.
- Look at the one path where a later decisive word on a settled row did MORE than rewrite the row: a second
  "copy" word on a row already settled as `copy` (it would add a second probable edge and delete kept parts'
  rows again). With the guard it does nothing. Say in the report whether any caller relies on that (the judge
  lists only rows in phase `judge`: find out who can send a word on a done row at all, and write the list).
- The fixed lines of `tools/probe-misses` are not yours (another branch).

## 3. Tests (in `internal/catalog`; every new name starts with `TestProbeSettledRow`; invented data)
1. `TestProbeSettledRowKeepsCopy`: the reviewer's probe P4 as a test: copy naming X (held), then no match
   naming Y, then no match naming nothing, then partly, then copy naming Z, then unknown, final and more parts:
   after each the row is byte for byte what the first word left (every column), the file is held as before, its
   probable edges and their evidence are what the first word made, no kept part's row changes, and the new
   counter went up by one each time.
2. `TestProbeSettledRowKeepsNoMatchAndPartly`: the same for a row settled as `nomatch` and one settled as
   `partly`, on a file that is wanted (not held), then saved, then gone: the row never changes; the file's
   state is what it was.
3. `TestProbeSettledRowUncheckedStillTakesAWord`: a row done as `unchecked` (and one done as `left` on a held
   file) takes a later copy word exactly as on the head (compare with the head's behaviour by the existing
   tests' expectations: none of them may change).
4. No existing test function is removed or weakened; if one fails, it is a finding: say which and why before
   changing anything in it.
Say for each new test what change in the code makes it fail (seen failing once, by hand: the first must fail on
the head's code).
Run while working: `go test ./internal/catalog -run 'TestProbe' -count=1` (say its seconds; if it is over 5
minutes, name a narrower pattern in the report and use it), `go build ./...`, `gofmt -l` on your files. **Not**
the whole catalogue (9 minutes), no race detector, no vet over packages.

## 4. Hand-back
A report `archiver/docs/progress/copies-settled-row-REPORT.md`: the guard as built and where; who can send a
word on a done row (the list); every file touched; test functions removed (none) or changed (none expected);
each new test and what breaks it; the new counter's key; what you could not verify; every doubt, above all
whether "final as a record" could ever keep a WRONG record that a later word should correct (say the case; do
not build an exception for it). Everything committed and pushed on `wip/copies-23`; the copy clean. Your last
message: the head's short hash, the tests run with their seconds, the list of callers in a line, the doubts in
a few lines.
