# Brief K2: a crash log, a run history and a watchdog that restarts a collector that died (Core, 2026-11-15)

For one Opus coder. Roadmap rows: "Crash log, run history" (part: runs are numbered; no crash log) and the
board's Core row. You work in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-core-watchdog`, branch
`wip/core-watchdog` (cut from the main head d1af260), Go module in `archiver/`.

## What the old app already knows (read by the Core session in its code, `wt-v12.31`; its numbers)

- **A crash costs more than most improvements.** From ix.10.2 to 12.1 a stack overflow ended the old app every
  2 to 3 hours for days; every download in flight was lost each time, and the launcher that started it again
  hid it. With a crash log and run history (12.1) the cause was found: then 0 crashes in 7 days. Its history
  today (read 11-15, counts only): 28 runs on record, 27 ended cleanly, 1 with no report, 0 crashes.
- **Its way** (`core-service/internal/crashlog/crashlog.go`, `cmd/tgdl-server/supervise.go`): a marker file
  touched every minute; the runtime's crash report kept as a file; a history of runs (`history.jsonl`, 300
  lines) settled at the next start: a report means "crash", a marker alone means "no report" (killed, power,
  window closed), neither means "clean". Go prints the words of a fatal error to the window only, so since
  12.3 the server runs as a child of a small supervisor that copies its error output and keeps the runtime's
  own words. **Only the runtime's own words and function names are ever quoted; a panic's message never** (it
  can hold a name).
- A restart of the old app costs about 45 s (33 s when installed by hand).
- Open in the old app and a rule for the new one (code review A5): a version that crashes at start loops for
  ever. Rule: after three crashes within ten minutes of starting, stop.
- The new app's own numbers: kills and restarts of the collector were run for real (11-13: active files given
  back, exactly the checkpointed parts kept); inside the collector a failing task already restarts alone
  (`internal/collector/supervisor.go`); one crash of the whole process is on record (11-15, board message 28:
  Windows exception 0xc0000005, written to the error output, exit code 2), and nothing restarts it.

Port the old code where it does the job (`crashlog.go` nearly whole: marker, history, pruning, `Parse`, `Text`,
`safe`; `supervise.go`'s `copyWindow` and `runtimeCause`), with the changes below. Do not invent a second way.

## The shape: a separate small program, nothing of the collector touched

Three other branches are changing `internal/collector` and must merge first. **You edit no existing file.** New
only:
- `archiver/internal/crashlog` (the record: marker, history, the parse of a crash report),
- `archiver/internal/watchdog` (the classification, the restart policy, the supervising loop),
- `archiver/cmd/tgarchive-watchdog` (the program).
Standard library only (a wall test in each package says so: no import outside the standard library and these
two packages; no `tgarchive/internal/collector`, no Telegram library). No `go.mod` change, no schema step.

```
tgarchive-watchdog run -dir <folder> [-status-file <path>] [flags] -- <program> [arguments...]
tgarchive-watchdog history -dir <folder>
tgarchive-watchdog version
```
`run` starts `<program>` with its arguments exactly as given (the installed collector with its `run ...`
line), as a child on the same console, with the same environment, no standard input, its standard output and
error output read through pipes. The watchdog itself never opens a network connection, the catalogue or the
library.

## What `run` does

1. **One watchdog per folder:** a lock file in `-dir` held for the process's life (the collector's
   `lockFile` in `internal/collector/lock*.go` shows the way on Windows and elsewhere: copy the few lines,
   do not import). A second one prints fixed words and exits 2.
2. **Settles what the last watchdog left** (the old `settle`): a marker with no clean end becomes a history
   line "no report" (the watchdog itself was killed, or power was lost).
3. **Starts the child, copies its output** to `collector.out.log` and `collector.err.log` in `-dir` (appended;
   at 16 MB a file becomes `.1` and a new one starts: the old `copyWindow`), and keeps the last 256 KB of the
   error output in memory. It writes the child's output nowhere else (not to its own output).
4. **Touches the marker every minute** (child's start time, both process numbers).
5. **While the child runs, Ctrl-C or SIGTERM is noted, not acted on**: the child gets the same console event
   and stops by itself (a second one makes the collector stop at once: its own rule). The watchdog waits for
   the child to end, however long. Interrupts come through a channel that tests fill.
6. **When the child ends, it is classified, in this order:**

   | Class | Evidence | Restart |
   |---|---|---|
   | stopped | a stop was noted (5) | no |
   | clean | exit code 0 | no |
   | crash | exit code not 0 AND the error output holds the Go runtime's crash text: a line that starts with `fatal error: `, `panic: `, `Exception 0x` or `[signal ` | yes, under the policy |
   | crash | no such text AND the exit code is a Windows exception status (0xC0000000 to 0xCFFFFFFF) other than 0xC000013A (the console's own end) | yes, under the policy |
   | ended by itself | anything else: exit code 1 or 2 with its own words (a refusal: no account signed in, the VPN check, a lock, a missing library; a failed start), a kill by a person or a script (code 1, -1), the console closed | **no** |

   **Only positive evidence that it died by itself restarts it.** A refusal is never restarted: that is how
   it never loops on one. A person's kill is a person's stop.
7. **A crash's record:** the kept error output is written as `crash-<UTC time>.log` (10 kept), parsed as the
   old `Parse` does (the module prefix to cut is `tgarchive/`), and the history line holds the class, the
   exit code, the run's start and end, the runtime's own words, the top functions, the first function of
   ours, the goroutine count, the dump's name, and what was decided ("restart after N s", or the fixed reason
   for none).
8. **The restart policy** (a pure function of the history of this watchdog run, the clock and the status
   file; all numbers flags with these defaults):
   - the delay doubles with each death in a row: 2, 4, 8, 16, 30, 30 ... minutes (`-min-wait 2m`,
     `-max-wait 30m`); a child that ran 30 minutes or more (`-reset-after 30m`) puts it back to 2;
   - **three deaths in a row, each within 10 minutes of its start** (`-quick 10m`, `-quick-deaths 3`): no
     restart, the watchdog ends ("it dies at its start: a person is needed");
   - at most 12 restarts in any 24 hours (`-max-restarts-day 12`): then no restart, the watchdog ends;
   - **never before a wait Telegram stated is over.** The collector keeps its own waits across a restart;
     the watchdog adds a second line of defence from the collector's status file (`-status-file`: the JSON
     the collector rewrites every minute, `internal/collector/status_file.go`; read it tolerantly, only
     these fields): the latest `until` of every account's `waits_running` and the latest `gate_until` of
     every lane, in Unix seconds. The restart is not before that moment plus 60 s. A value more than 6 hours
     ahead is taken as 6 hours and counted; a file that is missing or cannot be read adds nothing and is
     counted ("status not read"). The 2-minute floor alone already covers every wait on a file part the old
     app ever saw (none of 60 s or more in 142 report hours);
   - a Ctrl-C or SIGTERM during the wait ends the watchdog at once, exit code 0: nothing is started.
9. **Its end:** exit code 0 after a clean or stopped child; the child's own exit code after "ended by
   itself"; 1 when it gave up (quick deaths, the daily cap); 2 for its own refusals (flags, the lock, a
   program that cannot be started: said in fixed words, not retried).
10. **A status file of its own**, `watchdog-status.json` in `-dir`, written through a temporary file and a
    rename at every change of state and every minute: a version number, the write's time, the state
    (`running`, `waiting`, `ended`), the child's start, deaths in a row, restarts in the last 24 hours, when
    the restart is due and which rule set that time (fixed words), why it ended (fixed words), the last
    death's class, code and runtime words. The pages will read it later; scripts never parse prose.
11. **Not built now, only counted in the status file:** the collector's status file being stale while the
    child lives (its `stale_after` passed: a hang). The watchdog kills nothing.

`history` prints the last 7 days by class and the recent ends that were not clean (the old
`ixRestartsDiag`'s first lines), from `history.jsonl` alone.

## Rules that are not negotiable

- **Privacy:** the watchdog's own output, `history.jsonl` and `watchdog-status.json` hold numbers, times,
  versions, fixed words, the Go runtime's own words and function names: never a panic's message, never a
  line of the child's output. Every format string is a constant. A guard test feeds a child whose output
  and panic message carry an invented marker word and requires it in none of those three (the raw output
  logs and the crash dump are the child's own text, kept locally as the start scripts keep them today).
- Nothing in the record may stop the watchdog or the child: a failed write costs the record only.
- The child is started again only after the earlier child has ended (`Wait` returned) and its pipes are
  drained. Never two children.
- Invented data only in tests. No test reads a real folder, catalogue or log of this PC.

## Tests (named; write them with the code)

- **No real time anywhere:** an injected clock for every wait, beat and time stamp; a fake child starter
  behind a small interface for the loop's tests (start, the two output streams, wait with a code). The
  integrator's standing notes: judge no test on a second of real time; a stand-in process gets no bound it
  could miss by starting slowly.
- `Parse` and the classification as tables: a fatal error, a runtime panic, a panic with a message (not
  quoted), an `Exception 0xc0000005` report of the shape of message 28's (invented frames), a refusal's
  words, nothing at all; each exit code class of the table above.
- The policy as a table: 2, 4, 8, 16, 30, 30; the reset after a long run; three quick deaths; the daily
  cap; a status file's wait and gate honoured plus 60 s; a missing file, a corrupt file, a value days ahead.
- The loop with the fake starter: clean end; a refusal (exit 2, words) is not restarted; a crash is
  restarted once after the fake clock passes the delay and not a moment before; a stop noted while the
  child runs; an interrupt during the wait; the second child never starts before the first ended.
- One end-to-end test with a real child: the test binary started again as a helper (an environment variable
  picks its act): a real unrecovered `panic` the first time, a clean end the second; the delay passes on the
  fake clock. It proves the real pipes, the real exit code and the real crash text of this Go version.
- Settling: a marker left by a killed watchdog becomes one "no report" line; history pruned at 300; dumps
  at 10.
- The lock: a second watchdog on the folder is refused.
- The privacy guard and the two wall tests above.

Run while you work: only your named tests or these two small packages and the command
(`go test ./internal/crashlog/ ./internal/watchdog/ ./cmd/tgarchive-watchdog/`). No other package, no
`./...`, no race detector, no Docker: the full runs are the Core session's, once, after the review.

## How to work

- Shell: Git Bash. First `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then
  work in `wt-core-watchdog/archiver`. Go commands as `GOGC=25 GOMAXPROCS=2 go test -p 1 ...` (the PC's
  memory is short and four other sessions build on it; before a go command look at free memory and do not
  start one under 2.5 GB free). `GOPROXY=off`: nothing is downloaded.
- Read first, in the copy: `internal/collector/command.go` (the exit codes and how `run` ends),
  `internal/collector/status_file.go` (the JSON), `internal/collector/lock*.go`, `cmd/tgarchive-nashelper/main.go`
  (how a small command is laid out and tested); and in `C:\Users\trabi\Claude\Projects\Telegram\wt-v12.31\core-service`:
  `internal/crashlog/crashlog.go` with its test, `cmd/tgdl-server/supervise.go` with its test. Read nothing
  under `E:\`, no `start.bat`, no log of a real run.
- Never work in `repo-archiver` itself or in another copy. Edit no existing file of the repository; if you
  believe one is unavoidable, stop and say which line and why.
- Commit as you go on `wip/core-watchdog` and push it to the remote `private` after each commit that
  builds: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Never push another branch, never merge, never tag.
- `gofmt -l` clean on your three folders before the hand-back.

## Hand back (in your last message; the Core session reads the risky parts itself)

The branch's head; the files; which named tests ran and their time; what of this brief is not built or built
differently, and why; anything in the classification or the policy you found doubtful while building it;
what the end-to-end test's real crash text looked like in its first lines (the runtime's words only).
