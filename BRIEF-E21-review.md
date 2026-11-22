# Brief E21, the narrow independent review: the read-only count of the frame check's verdicts against downloads (copies, session C5, 11-16)

**For an Opus 5.5 reviewer at high effort who has not seen the coder's work. One narrow pass on one small tool
(631 lines and its test). The question is not style: it is whether the numbers this tool will print can
mislead, and whether it truly writes nothing and prints nothing but counts.**

- The piece: branch `wip/copies-21`, head cc8f6e43, in the copy
  `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-21`; new files only: `archiver/tools/probe-misses/main.go`,
  `probe.go`, `probe_test.go`. Its brief: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-E21-probe-misses.md`
  (read it first: section 0 has the old app's table that this tool's output will be set beside). The coder's
  report: `archiver/docs/progress/copies-probe-misses-REPORT.md` on the branch (read it last: a claim, not
  evidence).
- **You change nothing in that copy.** Probes go into a scratch copy you make yourself:
  `git -C /c/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add --detach /c/Users/trabi/Claude/Projects/Telegram/wt-copies-review21-scratch cc8f6e43`
  as untracked files named `zz_probe_*_test.go` in the tool's folder; leave them there, uncommitted. Go:
  `. /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then the scratch copy's `archiver`.
  One go command at a time, `GOMAXPROCS=2 GOMEMLIMIT=1GiB GOFLAGS=-p=1`, only
  `go test ./tools/probe-misses -run <name> -count=1`; before each, free memory
  (`powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`)
  must be at least 1.2; under it wait 2 minutes and look again, at most 5 times, then skip that probe and say so.
- Invented data only; never open a real catalogue, anything under `E:\T` or a folder of the owner's; nothing
  runs against Telegram. A text with a Windows path is written with the Write tool, never through a shell string.

## The questions, in the order of their weight
1. **What does "downloaded in full" count?** The tool takes a media as downloaded when `tg_media.file_id` leads
   to a `file` row with a content hash, and as "same bytes" when that row's SHA-256 equals the named file's.
   Read in the catalogue (`internal/catalog`: `exactcheck.go`, `state.go`, `ladder.go`, `atsave.go`, whatever
   sets `tg_media.file_id`) **every way a media gets a `file_id`**: a real download and save; a skip by exact
   evidence (the same Telegram file, the same SHA-256, every part hash) that links the media to a file that was
   already saved; the bring-in. Is `file.sha256` unique, so that a download of identical bytes ends on the named
   file's own row? Then: can the tool tell "skipped by exact evidence, never downloaded" from "downloaded and
   found identical" (the old table has them as two columns: "skipped by Telegram's hashes" and "same bytes")? If
   it can from a column or table without guessing, name it; if it cannot, the output must say in fixed words
   what the cell really is. **A "copy" or "no match" row that lands in "same bytes" without a download would
   make the check look better or worse than it was: this is the finding that matters most.**
2. **Is each row judged against the right file?** When is `c_probe.of_file` written, for which results, and can
   it change after the result is set (the coder's doubt: a late word on a row that is done)? For `nomatch`: does
   `of_file` name the candidate the check compared most closely, any candidate, or nothing? If a "no match" was
   reached against several candidates, the tool judges against one: say which, and what that does to the
   "wrong about 3 in 4" kind of sentence.
3. **Is `footage.Compare` of the two stored fingerprints the right post-download judge**, used as its own
   callers use it (the frames as stored by `PutVideoFingerprint`, the length from the meta, the version)? Are
   `Same`, `Clip` and `Overlap` all "a pair", and is anything else than `None` possible?
4. **Each row in exactly one cell;** the sums of a line equal its "downloaded"; the two sentences under the
   table say what the numbers say (their denominators), and "too few to read" under 20.
5. **It writes nothing and prints no data:** the open (immutable when no `-wal` is there, `mode=ro` when one
   is; what if only a `-shm` or a zero-length `-wal` is there; what a collector starting in that instant
   means); no id, hash, path or per-file number in any output or error, also on a failure in the middle.
6. One snapshot or several: the rows and each pair's fingerprints are read by separate statements while a
   collector may write. Can that put a row in a wrong cell, and is one read transaction for the whole pass the
   smaller risk (it would hold the log's reset for the run's minutes)?
7. A named file that is lost is "not judged" though its fingerprint row may still be there: right, or a loss of
   data that matters?

## What to hand back
A file `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-E21-probe-misses.md` (write it with the Write tool): the
head you read; your answer to each question with the lines of the catalogue's code that show it; findings
numbered, each with its rank (high: a count that would mislead about how often the check is right, or anything
written or any data printed; medium; low), what happens, the smallest fix, and whether a probe shows it; what
you did not look at; then one last line, exactly one of: "may be listed", "may be listed after these fixes:
<numbers>", "not yet". Your last message: that last line, the findings by rank with one line each for high and
medium, the probes run with their results.
