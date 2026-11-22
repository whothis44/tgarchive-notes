# Brief: an independent, read-only review of the watchdog (K2)

You are a challenger. You did not write this code and you are not here to like it. Find what is wrong with it
before it supervises a program that talks to Telegram for days. **You change nothing in the working copy**
`C:\Users\trabi\Claude\Projects\Telegram\wt-core-watchdog` (branch `wip/core-watchdog`; the piece is the three
new folders `archiver/internal/crashlog`, `archiver/internal/watchdog`, `archiver/cmd/tgarchive-watchdog`,
everything after commit d1af260). What it must do is written in `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-K2-watchdog.md`:
read that first, in full. The old code it was ported from: `C:\Users\trabi\Claude\Projects\Telegram\wt-v12.31\core-service\internal\crashlog\crashlog.go`
and `cmd\tgdl-server\supervise.go`.

## What to hunt for, in this order

1. **A restart that must not happen.** Any path on which the child is started again after: a refusal or a
   failed start (exit code 1 or 2 with the collector's own words), a clean stop, a stop that was asked
   (Ctrl-C or SIGTERM noted while the child ran, or during the wait), a person's kill, the console's own end;
   or started again sooner than the policy allows (the doubling delay, the status file's latest wait or gate
   plus 60 s), or more often (three quick deaths, 12 a day). Look hard at: text in the child's STANDARD
   output or in a refusal's words that could be taken for the runtime's crash text; a crash text cut in two
   by the 256 KB tail or by a read boundary; exit codes as Windows gives them (unsigned 32-bit, negative
   after conversion); a stop noted in the instant the child dies; the clock going backwards or a status
   file with times in the past or far in the future; a status file half written.
2. **Two children at once, or a child nobody waits for.** The order of start, pipes drained, `Wait`,
   classification, wait, next start; what happens when a pipe read fails, when the log file cannot be
   written, when the folder disappears.
3. **A loop without an end or a pause without one**: a restart loop with no delay under any input; a wait
   that never ends because of a corrupt value.
4. **The record lying or leaking.** `history.jsonl`, `watchdog-status.json` and the watchdog's own output
   must hold only numbers, times, fixed words, the Go runtime's own words and function names: find any way
   a line of the child's output, a panic's message, a path or an argument of the child gets into one of
   them. Find any history line that says the wrong class, or a death that leaves no line.
5. **Goroutines and data races**: every shared value between the pipe copiers, the beat, the signal note
   and the loop; a goroutine left behind at the end; a send on a channel nobody reads.
6. **The lock**: two watchdogs on one folder; the lock left behind after a kill.
7. **The tests themselves**: a test that passes without proving its name (no real time anywhere is the
   rule: any sleep, any deadline on a real clock, any bound a slow process start could miss, is a finding);
   a rule of the brief with no test.

## How to work

- Prove findings with probe tests that live OUTSIDE the working copy: write them in
  `C:\Users\trabi\Claude\Projects\Telegram\wt-core-watchdog-review-scratch\` and load them with
  `go test -overlay` (an overlay JSON that adds your `zz_probe_test.go` to the package's folder), so the
  copy is never edited. Mark each finding **CONFIRMED** (a probe shows it; name the probe) or **PLAUSIBLE**
  (by reading; say what would confirm it), with a severity (high: a wrong restart, two children, a leak;
  medium; low) and the file and line.
- Shell: Git Bash. `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then in
  `wt-core-watchdog/archiver`: `GOPROXY=off GOGC=25 GOMAXPROCS=2 go test -p 1 ...` on these three small
  packages only. No race detector (on this PC it runs in Docker, and the Core session runs it once after
  your findings are fixed): find races by reading, and say where the detector should look.
  Never another package, never `./...`, no Docker. Look at free memory before a go command (PowerShell:
  `(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB`, GB) and do not start one under 2.5 GB.
- Privacy: read nothing under `E:\`, no `start.bat`, no log of a real run. Invented data only.
- Do not fix anything, do not commit, do not push. Do not soften: a finding you are unsure of is PLAUSIBLE,
  not left out.

## Your report

Write `C:\Users\trabi\Claude\Projects\Telegram\wt-core-watchdog-review-scratch\REVIEW.md` and give the same
text as your last message: the findings, most severe first, each with CONFIRMED or PLAUSIBLE, severity, file
and line, what happens, the probe's name; then what you looked for and did not find (so the next reader
knows it was looked at); then the rules of the brief you found no test for.
