# Brief: the narrow independent review of G15 (pages, P6, 11-16)

You are an independent reviewer (Opus, high effort). You did not write this code. **Read-only on the
copy `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-free`** (branch `wip/pages-free`; the head your
start message names; the base is 78739d59: `git diff 78739d59 HEAD`). You edit nothing there and commit
nothing. Probes go into `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g15-scratch` (make it;
plain files, loaded with `go test -overlay`, as `TRIED-BEFORE.md` section 25 says: "reviewers prove
findings without editing the tree"). Write your review to
`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-G15-staging-free.md` with the Write tool.

## What the piece is
`BRIEF-G15-staging-tests-free-space.md` in the project folder (read it): five tests of `internal/server`
failed for every track whenever this PC's system disk had under 50 GiB free, because the Staging page's
reading asked the real disk. The mend: a seam `stagingKeep.free` read by `freeWithin`
(`stagingread.go`), the rig and four other tests on an invented fixed number, three new tests
(`staging_free_test.go`), and in a second round the order of the busy flag and the answer inside
`freeWithin`'s goroutine with a test `TestStagingFreeBackToBack`. The coder's report:
`archiver/docs/progress/pages-free-REPORT.md` on the branch.

## What to decide (narrow: these questions, in this order)
1. **Can any test of `internal/server` still change its result with the state of this PC** (the disk's
   free space, the disk's speed, the temporary folder's place)? Look at EVERY place a `Server` is built
   in the package's tests (`New(`, `newEnv`, `newStagingEnv`, the demo's server) and at every route or
   function that reaches `freeWithin` or `freeBytes` (`readStaging`, the Overview's region if it reads
   staging, `settings.go`'s `libraryCheck`): which of them run with no seam set, and does an assertion
   depend on what the disk answers? The coder lists what it changed and what it left: check the list
   against the code; a missed place is a must-fix. A good probe: by overlay, make `freeBytes` answer 1
   (one byte free) and, separately, -1, and run the WHOLE set of the package's Staging, Overview, Mirror
   and Settings tests by name (`-run 'Staging|Overview|Mirror|Settings|HeldStop|Minors|Verdict'`): only
   `TestStagingFreeRealCall` may fail. Say exactly which tests you ran under each overlay.
2. **Is product behaviour unchanged but for the order inside `freeWithin`?** With the seam nil the real
   call is used; nothing outside tests sets the seam (search the non-test sources of the whole module
   for `stg.free`). The seam is read on the caller's goroutine before the goroutine starts: say whether
   any reader or writer of the field can race (tests set it between readings: is any reading still
   under way then? `TestStagingFreeFromSeam` and `TestStagingFreeBackToBack` are the ones to read).
3. **The second round's order (flag cleared, then the answer sent):** is it right on every path (answer
   in time; the bound passes first and the call returns later; the call never returns; a second caller
   during a slow call)? Can a caller that has received an answer still meet a busy flag? Can two real
   calls now run at once where one ran before? Is the guard's purpose (no second call while a disk does
   not answer: review G5, minor 14) kept?
4. **Do the new tests test what they say?** For each of the four: would it fail if the seam were ignored
   (the coder says it tried), if `noRoom` compared the wrong way, if -1 were taken as 0 bytes free? Is any
   of them itself dependent on timing in a way that can fail on a loaded PC (this PC is loaded: other
   sessions run tests)? `TestStagingFreeRealCall` is the one test that asks the real disk on purpose: is
   what it asserts true on any PC with a writable temporary folder, including one with very little room?
5. Anything else you see in the diff that is wrong. Not in scope: the page's design, other packages
   (the coder's part 4 found the collector's rig keeps 1 MiB free: say only if you find a collector or
   launcher test that asserts on an amount of free space).

## Rules
- The PC's memory is tight: ONE go command at a time, `-p 1`, named tests only (`-run`), nothing over
  three minutes, no whole package, no race detector (the full runs come after you, once, by a script).
  Look at free memory before each go command; under 1.5 GB wait a minute and look again, at most five
  times, then go on. Go's environment in bash:
  `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, go from
  `/c/Users/trabi/Claude/Projects/Telegram/wt-pages-free/archiver`.
- Never a Windows path inside a shell string (`/c/...` in bash; the Write tool for files; an overlay's
  JSON written with the Write tool, its paths with forward slashes).
- Never open anything of the owner's (nothing under `E:`, nothing of the owner's app folders); invented
  data only. Leave no process behind and no file in the copy (`git status` there stays clean).

## The review file
Findings numbered, each **must fix / should fix / minor**, each marked **confirmed** (with the probe's
name and its output's decisive line) or **plausible** (read, not run); for question 1 the list of
places with "seam set / real call, no assertion on it / real call asserted". The last line is one of:
"may be listed", "may be listed after these fixes: <numbers>", "not yet". Then hand back at most 10
lines: the verdict line, the count of findings by weight, what you could not check.
