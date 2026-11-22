# Brief E23, the narrow independent review: a settled frame-check row is not rewritten by a later word (copies, session C5, 11-16)

**For an Opus 5.5 reviewer at high effort who has not seen the coder's work. One narrow pass on a change of 33
lines in one function and its 261-line test.**

- The piece: branch `wip/copies-23`, head 767769a9, in the copy
  `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-23`, against the main head it was cut from (b435266a):
  `git -C <copy> diff b435266a HEAD`. Its brief: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-E23-settled-row.md`
  (read it first); the coder's report `archiver/docs/progress/copies-settled-row-REPORT.md` on the branch last.
- **You change nothing in that copy.** Probes go into a scratch copy you make yourself:
  `git -C /c/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add --detach /c/Users/trabi/Claude/Projects/Telegram/wt-copies-review23-scratch 767769a9`
  as untracked files `zz_probe_*_test.go`; leave them there. Go:
  `. /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then the scratch copy's `archiver`. Only
  named tests (`-run`, `-count=1`), one go command at a time with `GOMAXPROCS=2 GOMEMLIMIT=1GiB GOFLAGS=-p=1`;
  before each: free memory at least 1.2 GB
  (`powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`;
  under it wait 2 minutes and look again, at most 5 times, then skip the probe and say so) and the track's lock:
  `mkdir /c/Users/trabi/Claude/Projects/Telegram/runs-copies-golock` (if it exists wait 30 seconds and try again,
  20 minutes at most), `rmdir` right after. Never the whole catalogue package, no race detector, no vet over
  packages.
- Invented data only; nothing runs against Telegram; never open anything under `E:\T`, a real catalogue or a
  folder of the owner's. A text with a Windows path is written with the Write tool.

## The questions
1. **Does the guard change any file's fate, or anything but the record, against the head?** For every caller
   that can send a word for a row already done with `copy`, `partly` or `nomatch` (the judge's `record` in
   `internal/probejudge/turn.go`, the Supply's final word in `internal/supply/probe.go`, any other `ProbeVerdict`
   caller: find them yourself): what did the head do with the call's answer (the fate), what does it do now
   that the answer is `FateLeft` or `FateLate` where it was `FateHeld` or `FateWanted`? Kept parts, the part
   store's ledger, the count of checks in flight, a retry, a pending verdict that is tried again for ever, a log
   line per turn. **A file that is now put off, released, re-listed for ever or left with parts nobody sweeps is
   a finding of the highest rank.**
2. **Is "final as a record" right in every state the row can be in?** A row done as `copy` whose file the owner
   released or said "not the same" about (the pair words, `pairword.go`), or whose named file was lost and the
   file judged again (`WantAgain`): can the frame check legitimately run AGAIN for that file later (a row put
   back to `fetch` by some door), and does the guard then stand in the way of a fresh check, or is the row
   reset first so that the guard never sees it? If a file can be checked twice in its life, say exactly how
   the row moves.
3. The fate answered: `FateLate` when a lane holds the file and both counters go up: is the late count still
   what its readers (the hourly line, a test) take it for?
4. The tests: does the first fail on the head's code for the reason the brief names (seen by you, by taking the
   guard out in your scratch copy)? Do they compare every column of the row and the file's edges, or could a
   rewritten column pass?
5. The coder's note, outside its brief: `ProbeFetched`'s branch for a turn whose plan is not the row's still
   rewrites a done row's `parts_fetched`, `last_new_parts` and `at`. Is that a rewrite of the record that this
   piece should have closed too (rank it; do not ask for more than the smallest fix)?

## What to hand back
A file `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-E23-settled-row.md` (write it with the Write tool): the
head you read; your answer to each question with the lines that show it; findings numbered with rank (high: a
file's fate or a check's lifecycle changed for the worse; medium; low), the smallest fix, whether a probe shows
it; what you did not look at; then one last line, exactly one of: "may be listed", "may be listed after these
fixes: <numbers>", "not yet". Your last message: that last line, the findings by rank in one line each, the
probes run with their results.
