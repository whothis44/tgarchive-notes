# Brief: the second look at E18's fix round (copies, session C4, 11-16)

**For an Opus 5.5 reviewer at high effort, fresh: you have seen neither the piece nor its first review's author.
A short pass (aim at 20 minutes): the fixes of the first review, not the piece again.**

## What you review
Branch `wip/copies-18`, the fix round's commits `56c5fc0d..b0a1514a` (13 commits). **Do not read from the working
copy `wt-copies-18` (a clerk may merge into it while you work): make your own detached copy** from
`C:\Users\trabi\Claude\Projects\Telegram\repo-archiver`: `git worktree add --detach ../wt-copies-review18b-scratch
b0a1514a`; read and probe there (`zz_probe_*_test.go`, never committed; leave the copy as it is). Read first:
`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-E18-collector-lines.md` (the first review: its findings 1 to 12),
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-E18b-fixes.md` (what was asked), then the difference, then the
report's section "The fix round" in `archiver/docs/progress/copies-collector-lines-REPORT.md`.

The piece is download-path code behind two flags that are off by default. The owner's rules: only exact evidence
may skip a file; a probable copy is held, never skipped; nothing may make a lane, a slot, a finish or the copier
wait on ffmpeg, the judge or the part store; every wait has a bound; nothing in the background reads the library
folder; logs carry counts and fixed words only (never a panic's text, a path, a name, an id).

Go: `. /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then your copy's `archiver`. Named tests
only (`-run`, `-count=1`); whole `internal/probejudge` and `internal/parts` are allowed (seconds each); never the
whole `internal/collector`, `internal/catalog` or `internal/supply`; no `go vet` over packages. The race detector
only on `internal/probejudge`, in Docker, if the PC allows: `bash
/c/Users/trabi/Claude/Projects/Telegram/ix-tools/race-archiver.sh <your copy's path> ./internal/probejudge 2 4g
20m` (read the script's header first). Before a run: less than 2 GB of memory free or the CPU above 80% over a
few seconds: wait a minute, at most 10 times, then `GOMAXPROCS=2`. Invented data only; nothing against Telegram.

## The questions
1. **Fix 1, the judge's recover (`internal/probejudge/panics.go`, `judge.go`, `turn.go`).** After a panic at each
   step of a worker's turn (the list, the candidates, the index reader, the part store, a check, the decide code,
   the verdict's write, a verdict waiting aside, the look at ffmpeg): is every lock free, is `checking` right, is
   the file out of `hand`, is the probing channel closed, can the other worker go on, and does the file come
   back and end at a bound (trace it to the catalogue's door: which bound lets it through, after how long, counted
   how)? Can a panic be swallowed that should end the program (a corrupted state that goes on judging: can a
   verdict be written from a half-made check)? A panic every turn on every file: does the judge spin, or pause?
   Is anything recovered now that makes a wrong "copy" or "no match" possible? The log line: constant format, no
   panic text; is a panic's count always visible in `Report()`?
2. **Fix 2, `Run`'s defers:** the order of the defers against the workers' wait (are workers still running when
   `running` goes false and the state is set; can a second `Run` start while the first's workers still judge)?
3. **Fix 3, `replayMu`:** every way out unlocks exactly once; the `Saved` calls still come with no lock held; with
   `Saved` nil the function is the base's.
4. **Fix 4, the parts folder's other spellings (the coder left `filepath.EvalSymlinks` for `os.SameFile` on every
   existing ancestor, in a goroutine bounded by 2 s):** is it right for a junction, a symlink, a mapped drive
   against a UNC path, a folder that does not exist yet; how many system calls reach the library (it is on a NAS
   over Wi-Fi: no walk, no listing); what happens to the goroutine when the NAS never answers (does it leak for
   the program's life: once, or once per start; is that said)? Does `pathWithin` still refuse every case the first
   version refused?
5. **Fix 5, the mark:** the new `Lstat` in `newStaging` runs with both flags off: can it refuse or delay a start
   that worked before (a staging folder that does not answer, a file of that name there)? A folder that is not
   empty and unmarked is refused: also a parts folder made by the first version of this branch (it carries the
   staging mark): is that said? Can the two marks ever let one catalogue's parts be swept by another?
6. **Fixes 7 and 8, the bounds:** `ProbeCloseAll` at a start with the check off (first call plus three tries, at
   most 7 s): what does a file set aside for its judge do in a run where the call failed for good (trace it: is it
   ever lost, stuck or skipped; is it counted)? The part store's open tried again: a stop during the pauses; the
   refusal's words.
7. **Fix 10's second test** holds the file by hand to reach the judge already held, and the coder says it fails
   only when two things are broken at once (`probeWantedSQL` keeps a probable file held by itself): is the rule
   "a no match never releases a held file" guarded in fact, by which line, and is the test honest about what it
   proves?
8. **Anything in the 13 commits that changes the path with both flags off**, beyond fix 5's `Lstat` and fix 7's
   bound. Any existing test changed in what it asserts (the coder adapted `TestPartsDirMarked`).
9. Break two fixes of your choice in your copy and say which test failed.

## What you hand back
`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-E18b-second-look.md` (the Write tool): the head; per question an
answer with its evidence; findings numbered with severity (high: a file skipped, lost, stuck for good, or
downloads stalled; medium: a wrong count, a bound passed, a leak, a rule of the owner's bent; low: the rest),
confirmed or plausible, the smallest fix; what you did not look at; one closing line: "may be listed", "may be
listed after these fixes: n, m", or "not yet". Your last message: that line and the findings' titles with
severities.
