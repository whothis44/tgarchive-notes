# Brief K2c: the watchdog's last round (Core, 2026-11-15)

Same copy and branch as K2 and K2b (`wt-core-watchdog`, `wip/core-watchdog`, head 49217ab), same rules. The
reviewer's second pass is `C:\Users\trabi\Claude\Projects\Telegram\wt-core-watchdog-review-scratch\REVIEW-2.md`
(its probes: `watchdog_probe2_test.go`, `crashlog_probe2_test.go` beside it): read it in full. Every finding of
the first pass that was to be fixed is closed. This round takes what the second pass found and is worth
closing; it is the last one, so build exactly this and say plainly what you could not.

## To build

1. **Review-2 A: a function and a file are quoted only from where a Go program's frames can come.**
   - A function goes into `top` only when, besides the symbol's shape, its symbol starts with one of a fixed
     list of prefixes: `tgarchive/`, `main.`, `runtime.`, `runtime/`, `internal/`, `syscall.`, `sync.`,
     `sync/`, `os.`, `os/`, `io.`, `net.`, `net/`, `time.`, `context.`, `database/sql.`, `encoding/`,
     `crypto/`, `bufio.`, `bytes.`, `strings.`, `fmt.`, `errors.`, `reflect.`, `sort.`, `math/`,
     `golang.org/x/`, `modernc.org/`, `github.com/gotd/`, `github.com/go-faster/`, `go.uber.org/`,
     `github.com/klauspost/`, `nhooyr.io/`, `github.com/coder/` (add the standard library packages this
     module really imports that are missing here, by looking, as exact names; no pattern that a made-up word
     could meet). A symbol from anywhere else is counted in a number ("frames not quoted") and skipped.
   - `at` is taken only from a `tgarchive/` function, and its file only when the location's path holds that
     function's package folder right before the file (for `tgarchive/internal/engine.(*Lane).note` the path
     must end `/internal/engine/<file>.go:N`) and the file's name is lower-case letters, digits and `_`
     with `.go` or `.s`. Else `at` is the function alone.
   - The guard gets the review's two cases (a symbol-shaped line of the child above a location; a line that
     is a tab, a word, `.go:N` under a real function), each failing when the rule is undone.
2. **Review-2 G:** an argument list may hold `_` (the runtime prints it for an argument it cannot read); the
   reviewer's generic case with spaces and braces in the name stays skipped (said in a comment).
3. **Review-2 C and the grandchild: the child's end is the moment its process ended, not the moment its
   streams ended.** `Wait` is called in its own goroutine as soon as the child is started (the watchdog owns
   the pipes, so `Wait` does not depend on them); its return gives the exit code and the end's time (the
   watchdog's clock). The crash window (B9) and the stop's hold are judged against that time. After the
   exit the two streams are given 30 s of the watchdog's clock (`drainGrace`, a constant) to end; when they
   have not, the watchdog closes its reading ends, counts it in the status file (`streams_cut`), says so in
   one fixed line, and goes on. **The next child is still started only after the exit AND after both
   copiers have returned** (ended by themselves or by the closed reading ends): keep that order provable in
   a test. The fake child gets a way to end its process while holding a stream open. Tests: the review's
   probe (a fatal error, the process gone, the error stream held 3 minutes: a crash, restarted, the cause on
   record); a grandchild case (the process ends cleanly, a stream held for an hour: the watchdog ends after
   the grace, `streams_cut` 1); the order test above.
4. **Review-2 B:** `stopHolds` is 20 minutes (the collector holds a stop for up to 15 while a sign-in waits
   for its code: `internal/collector/collector.go`, the sign-in's hold; name that in the comment). The
   review's two probes at 15 minutes become named tests: `stopped`, no restart, exit code 0.
5. **Review-2 D, off Windows:**
   - `processAlive` reads the process's start from `/proc/<pid>/stat` and `/proc/uptime` (or `/proc/stat`'s
     `btime`) where `/proc` is there, and compares it with the marker's start as on Windows; only where that
     cannot be read does the number alone count (and the second fixed line says so). The watchdog's own
     number and its parent's are never taken for the child.
   - **`TestLoopSettlesWhatTheLastWatchdogLeft` must not depend on which process has number 2:** give it a
     check of its own or the number of a process that has ended (as the test with a real helper does). Look
     through every test for the same kind of dependence on a real process number. **The Core session's race
     run is in a Linux container: every test of the three packages must pass there.** You cannot run Linux
     tests on this PC without Docker (not allowed here): make them right by reading, vet with `GOOS=linux`,
     and list in the hand-back every test whose behaviour differs by system.
6. **Review-2 E, off Windows:** the child is started in a process group of its own (`Setpgid`, in the
   non-Windows start file), so a Ctrl-C at a terminal reaches the watchdog alone and the stop is passed on
   exactly once. On Windows nothing changes (the console gives the event to both; nothing is sent).
7. **Review-2 H:** the marker is written through a temporary file and a rename, so it is never found cut
   short; a marker that still cannot be parsed makes the watchdog start nothing ("the last watchdog's marker
   cannot be read: nothing was started; remove it by hand after checking no program runs", exit code 2):
   fail closed.
8. **Review-2 I:** an append to a history that could not be read adds no empty line, and empty lines in a
   history are not counted as runs.

## Not built, on purpose (add to the package's comment where missing)

Review-2 F (a crash-looking line within 2 minutes before a real crash: it needs a line the collector does
not print); J (the clock set back between two ends); a dump pruned at once after the clock was set back.

## Rules

As before: only the three folders; the standard library alone; no real time in any test; invented data;
these three packages only, one go command at a time, free memory looked at first; no race detector, no
Docker; gofmt and vet (Windows and `GOOS=linux`) clean. Each numbered item shown failing its test when
undone. Commit as you go, push `wip/core-watchdog`.

## Hand back

The head; each item with its test and mutation; the prefix list as written; what differs by system and
which tests are skipped or shaped differently off Windows; what could not be built as written; the `ok`
lines of all three packages.
