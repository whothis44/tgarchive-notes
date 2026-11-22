# Review brief: E16, the judge of the frame check (copies track, session C3, 2026-11-15)

You are an independent reviewer. **Read-only: you change nothing in the copy you review**
(`C:\Users\trabi\Claude\Projects\Telegram\wt-copies-16`, branch `wip/copies-16`, head c3dabe2c: four commits on
d0d91f7c, all in one new package `archiver/internal/probejudge` plus two documents). You commit nothing, push
nothing, switch no branch. Your own files (probe tests, overlay files, notes, your report) live only in
`C:\Users\trabi\Claude\Projects\Telegram\wt-copies-review16-scratch` (make it). A probe is a `_test.go` file there
compiled into the package with `go test -overlay <a JSON file in the scratch folder>`; `git status` in the
copy is clean when you finish. **Another reviewer works on `wt-copies-15` and its scratch folder right now:
touch neither.**

What was asked of the coder: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-E16-judge.md` (read it in full); the
design `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-COPIES-frame-check.md`; the doors it calls are described
in Part A of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-E15-frame-check-catalogue.md` and live in
`archiver/internal/catalog/probe.go` (being reviewed by the other reviewer: you review the judge, and the
doors only as the judge uses them). The coder's report: `archiver/docs/progress/copies-probe-judge-REPORT.md`.
The piece's diff: `git diff d0d91f7c c3dabe2c`.

## What it is for, and the rules it must hold
A queued video whose sampled parts are on the local disk is compared, by frames, with saved videos'
fingerprints. The judge (one worker beside the lanes and the copier) reads kept parts through ffmpeg and
writes one word per turn through the catalogue's `ProbeVerdict`. The rules, each from an incident of the old
app (`archiver/docs/COPY-CHECKS-STUDY.md` B, B.1, E.1; `ANSWERS-for-archiver-8.md` section C in the project
folder: its "copy" was right in 184 of 188, its "no match" wrong about 3 times in 4):
1. The judge can never say "exact", and no path of it makes the door write an exact edge.
2. A limit that ran out, a missing or failing ffmpeg, a part that is not there, a panic, a stop: never "no
   match", "partly" or "copy". A stop writes nothing at all.
3. A "copy" holds a file for the owner (it then waits for good unless released): a wrong "copy" is the
   costly error. "No match" and "partly" release nothing.
4. No Telegram access: nothing of `internal/telegram`, `internal/engine` or a network package is imported;
   ffmpeg reads only a server on 127.0.0.1 that serves kept parts.
5. Nothing reads the library or the staging folder.
6. No spin: a failing ffmpeg, a failing door or an empty list never turns the worker without a pause.
7. Logs, errors, counts: numbers and fixed words; never ffmpeg's own text, a path, a name or an id.
8. It runs concurrently with callers of `Kick`, `Ready` and `Stats` from other goroutines.

## What I ask you to settle, by probes where a probe can show it (my reading; each may be wrong)
A. **Every way out of `decide` and `turn` (turn.go) to its verdict:** list them all and check each against
   rule 2. In particular: the unknown with why `parts-missing` when ffmpeg missed parts the store says it
   keeps; `finalWhy`'s default (every other final category becomes `bad-data`); an outcome that names no
   candidate; `ErrNoFFmpeg` as an error with a result; a `Check` that returns a status and an error both.
B. **A wrong "copy".** The coder reports that its "shares a third" clip had to share 4 of 8 moments, and that
   in the automatic mode **the second round turns that clip into a copy**. With the real ffmpeg
   (`FFMPEG_PATH`: the second line `where.exe ffmpeg` prints) and invented clips, for a queued clip that
   shares about a third, a half and two thirds of a saved one, in the modes off, auto and always: which
   word is written, with how many hits of how many frames? Is the rule that makes "copy" from both rounds
   together (`footage.Verdict`, `footage.Together`, the need of 60%) applied as `internal/footage` defines
   it, or does the judge's use of `Check` (the resume with `prev`, the candidates' order, `res.After[0]` in
   the "not affordable" path) change what the arithmetic would say? You do not review `internal/footage`
   itself; say what the judge does with it. If a half-shared clip is called a copy by the merged
   arithmetic itself, say so plainly with the numbers: that is for the main session to decide.
C. **The resume.** `m.prev` is kept per file in memory and reused when the candidates' ids are equal. Can a
   `prev` from one set of kept parts or another length be used wrongly (the candidates the same but a
   fingerprint replaced; the memory cleared at its cap in the middle of a check; two files' states mixed)?
   What does a restart in each place cost (it must cost no request, only local reads)?
D. **The index path.** `mp4index.Read` then `PartsFor`: a part named twice, `MaxCalls`, a file that is not
   an MP4 (the judge passes an empty MIME type to the source: does ffmpeg or the range server care?), a
   hostile index (the reader's own tests are not yours; the judge's handling of its errors is), predicted
   parts over the door's cap, and a prediction that keeps naming parts ffmpeg then still misses (does the
   file end, or go round for ever between "more parts" and the check?).
E. **The bounds as the judge computes them** against the door's (`ProbeMaxRounds`, `ProbeMaxParts`,
   `job.Rounds`, `job.PartsFetched`): can the judge ask for a round the door then settles as final
   `parts-cap` although round 0 had an answer (the "not affordable" rule missed)?
F. **The pending verdict.** A verdict the door did not take is written first at the next turn and blocks
   every other file meanwhile. With a door that fails for one file only (not found, a bad record, a busy
   catalogue for a minute): what is judged, what is lost, how long is the worker held? The `skip` and `mem`
   maps at their caps.
G. **The self-test and `Ready`:** every state (no ffmpeg found; found and failing; passing then failing
   three times; found again after `Retry`); what is written while not ready (only unknown `no-ffmpeg`?);
   that `Ready` is false whenever a verdict from a check could not be trusted; a `Find` that panics or is
   slow.
H. **After a copy:** `Remove` only after the verdict is recorded; the fates for which it is called
   (`FateHeld`, `FateWanted`); a `Remove` that fails; a copy verdict the door settles as something else
   (no candidate any more, late, left): are parts removed that a download still needs?
I. **Rules 4, 5, 7:** the wall test (does it really follow imports through to the forbidden packages, or can
   an indirect import slip by?); every `Logf` and every error's text; what `Stats().Report()` prints.
J. **Rule 8, by reading** (the race detector is run by the main session afterwards): the fields `turn` and
   `decide` touch without a lock, and which of them `Kick`, `Ready`, `Stats` or a second `Run` can reach.
K. **The tests:** for each mutation the report lists and five of your own in `decide`, `turn` and `record`,
   say whether a named test fails. Which rules above have no test.
L. Anything else. The brief's own rules may be wrong too: say so where one, followed exactly, breaks a rule
   above.

## How to work
`source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then in the copy's `archiver/`:
`GOGC=25 GOMAXPROCS=2 go test -p 1 -count=1 -overlay <file> ./internal/probejudge/ -run '<names>'`. Only that
package; no race detector, nothing in Docker, no `go vet` over the tree. Before each go command look at the
free memory (`(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB` in PowerShell) and wait a minute
when it is under 2.5 GB; never two go commands at once. Nothing you run may contact Telegram or the network
(ffmpeg reading the test's own server on 127.0.0.1 is the one exception); invented clips and data in temp
folders only; never open anything under `E:\T` or any real catalogue. Any file holding a Windows path is
written with the Write tool, never from an inline script string.

## Your report
`C:\Users\trabi\Claude\Projects\Telegram\wt-copies-review16-scratch\REVIEW.md`, saved as you go (after each
letter): findings ranked, each **confirmed** (a probe shows it: name the probe file and what it printed,
counts only) or **plausible** (by reading: say exactly where), with its severity (which rule it breaks), the
lines, and the smallest fix you see; then what you checked and found sound, per letter; then what you did not
check. No names, paths of real files, ids or texts of any archive. Your last message to me: the count of
findings by rank and severity, then at most 25 lines with the confirmed ones first, and one line saying the
copy is clean.
