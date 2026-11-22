# Review brief: E17, the graphics card as the decoder with the CPU as the fallback; ffmpeg found beside the program (copies track, session C3, 2026-11-16)

You are an independent reviewer. **Read-only: you change nothing in the copy you review**
(`C:\Users\trabi\Claude\Projects\Telegram\wt-copies-17`, branch `wip/copies-17`, head 036e3cde: three commits on the
main head 29bcfa2e, in `archiver/internal/footage/ffmpeg` and `archiver/internal/vfp` plus two documents). You
commit nothing, push nothing, switch no branch. Your own files (probe tests, overlay files, notes, your
report) live only in `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-review17-scratch` (make it); a probe is a
`_test.go` file there compiled into the package with `go test -overlay`; `git status` in the copy is clean when
you finish. Other agents work in `wt-copies-15`, `wt-copies-16` and their scratch folders: touch none.

What was asked of the coder: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-E17-gpu-decoder.md` (all of it,
including its last section, the owner's decisions: the card first then the CPU by default for both kinds of
read, a manual choice, "try again and reset ffmpeg or fall back to the CPU", every option a plain value
another program can be handed). The coder's report: `archiver/docs/progress/copies-gpu-decoder-REPORT.md`.
The piece's diff: `git diff 29bcfa2e 036e3cde -- archiver/internal`.

## What it is for, and the rules it must hold
ffmpeg reads a saved video's fingerprint (the whole video at 2 frames a second) and a check's sampled frames
(one key frame a process). The old app decoded fingerprints on the card (`cuda`) with the CPU as the fallback.
This piece adds the decoder choice (`cpu`, `auto`, or a named card decoder) to both reads, a self-test of a
card decoder, the CPU run-again, and a finder that looks beside the program first.
1. **A decoder is a speed choice, never a verdict.** No status, category, outcome, missing-part list or
   resume of `Sample` and `Check` may differ because of the decoder; a card that fails is the CPU's turn,
   never "no match", "unknown" or a failure by itself; a frame read with a card must be the frame the CPU
   reads (within the fingerprint's own match distance).
2. A runner asked for a card never ends "not working" because of the card; a named card that fails falls
   back as `auto` does.
3. On a machine without a card (the NAS, Linux) `auto` ends on the CPU by itself, counted, no error; the
   packages build and test there.
4. Arguments are fixed lists with no shell; a decoder word is a plain word; nothing from a setting reaches
   ffmpeg's command line unchecked.
5. Logs, errors, counts and states: numbers and fixed words; never ffmpeg's own text or a path.
6. The finder: beside the program, its `tools` folder, the setting, `FFMPEG_PATH`, then PATH split by hand;
   nothing depends on the folder the program was started from; **it never runs a file from a folder an
   attacker of lower privilege could plausibly write to because of the new order** (say what you find).
7. Concurrency: a runner is used by two judge workers and the fingerprint worker at once.

## What I ask you to settle, by probes where a probe can show it (my reading; each may be wrong)
A. **The run-again of a sampled frame (`readFramesDec` in `sample.go`).** A frame is run again on the CPU when
   its card process "failed or timed out". Is a frame whose process asked for a part that is not there also
   "failed", and then run again (a second process that misses the same part; what do `Missing`, `Points`,
   the counts and the blame count say then)? A stop in the middle; a gone ffmpeg; a card process that hangs to
   its 10 s limit and the call's 60 s limit (how many frames can a check still read; is the answer "unknown
   timeout" where the CPU alone would have decided?). The blame count: per runner, shared by concurrent
   checks: can it switch to the CPU on files that are simply broken (the old rule: only when the CPU then read
   it), and is it ever reset?
B. **Rule 1 end to end, with the card on this PC** (`FFMPEG_PATH`: the second line `where.exe ffmpeg` prints):
   for invented clips (H.264 and HEVC, 8 and 10 bit if the encoder is there, key frames near and far apart,
   an MP4 with its index at the end, an MKV), compare `Sample`'s and `Check`'s whole results with `cpu`, `cuda`
   and `d3d11va`: statuses, categories, the frames' hashes (bits apart), their times, `Used` and `Missing`
   part lists (**does a card decoder make ffmpeg read other parts of the file than the CPU does?** That
   would change what a probe turn must fetch), and the outcomes against the same candidates.
C. **The decoder's self-test and `auto`:** what passes and fails it; ffmpeg falling back to software by itself
   inside a `-hwaccel` run (does the piece ever claim the card was used?); a decoder word that ffmpeg does not
   know; a self-test that hangs; two goroutines asking at once (run once?); the state after a failure and
   when a runner is made anew.
D. **Fingerprints (`fingerprint.go`, `vfp.go`):** `auto` resolved once; the blame rule unchanged from the base
   for a named decoder (compare with 29bcfa2e); the thread bound with every decoder; the per-decoder counts
   and seconds; nothing in the worker's holds, its watermark or its pauses changed (diff `vfp.go` against the
   base and say what else moved).
E. **The finder (`ffmpeg.go`):** each step of the order with temp folders; a relative setting; links; a PATH
   entry with a stray quote, an empty entry, a folder that does not exist; what `Where()` returns (a path
   must never reach a log: who calls it?); rule 6.
F. **Rules 3, 4, 5:** build and vet for Linux; every argument list; every `Logf`, error text, state word and
   JSON name.
G. **The tests:** for each mutation the report lists and five of your own, whether a named test fails; which
   tests skip without a card and whether they ran with one here; the link case the coder could not run.
H. Anything else, including rules of the brief that, followed exactly, break a rule above.

## How to work
`source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then in the copy's `archiver/`:
`GOGC=25 GOMAXPROCS=2 go test -p 1 -count=1 -overlay <file> ./internal/footage/ffmpeg/ -run '<names>'` (and
`./internal/vfp/`). Named tests and your probes only; no race detector, nothing in Docker, no `go vet` over the
tree. Before each go command look at the free memory and the CPU's load
(`(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB` and
`(Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average` in PowerShell) and
wait a minute when memory is under 2.5 GB or the load is over 85%; never two go commands at once. You may use
this PC's graphics card through ffmpeg's decoders on invented clips, one test command at a time; change no
system or driver setting. Nothing you run may contact Telegram or the network (ffmpeg reading a test's own
server on 127.0.0.1 is the one exception); never open anything under `E:\T` or any real catalogue or media.
Any file holding a Windows path is written with the Write tool, never from an inline script string.

## Your report
`C:\Users\trabi\Claude\Projects\Telegram\wt-copies-review17-scratch\REVIEW.md`, saved as you go (after each
letter): findings ranked, each **confirmed** (a probe shows it: name the probe file and what it printed,
counts only) or **plausible** (by reading: say exactly where), with its severity (which rule it breaks), the
lines, and the smallest fix you see; then what you checked and found sound, per letter; then what you did not
check. Your last message to me: the count of findings by rank and severity, then at most 25 lines with the
confirmed ones first, whether the piece may be listed after its fixes, and one line saying the copy is clean.
