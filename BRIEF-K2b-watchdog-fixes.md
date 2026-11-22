# Brief K2b: the review's fixes for the watchdog (Core, 2026-11-15)

Same copy and branch as K2 (`wt-core-watchdog`, `wip/core-watchdog`, head d9386d7), same rules, same commit and
push form. The independent review is `C:\Users\trabi\Claude\Projects\Telegram\wt-core-watchdog-review-scratch\REVIEW.md`:
read it in full; its probes are `watchdog_probe_test.go` and `crashlog_probe_test.go` in that folder (take each
that a decision below names as a named test of its package, renamed, never by overlay). The decisions below are
the Core session's: build them as written and say in the hand-back where one cannot be built so.

## A. The record quotes only what is proven to be the runtime's (review 1, 14: high)

Today `Parse` trusts that a line is the runtime's and passes it through a character filter. A log line of
the child can land on such a line (the runtime writes a crash line in pieces), or start with the same words.
From now on **nothing is quoted because of where it stands; only because of what it is**:
1. **A fatal error's words** are quoted only when the whole rest of the line is one of a fixed list of the Go
   runtime's own messages (write the list as constants; at least: `all goroutines are asleep - deadlock!`,
   `concurrent map writes`, `concurrent map read and map write`, `concurrent map iteration and map write`,
   `stack overflow`, `out of memory`, `unexpected signal during runtime execution`,
   `sync: unlock of unlocked mutex`, `sync: Unlock of unlocked RWMutex`, `sync: RUnlock of unlocked RWMutex`,
   `found bad pointer in Go heap`, `checkptr: pointer arithmetic result points to invalid allocation`,
   and the others you find by name in this toolchain's `runtime` that a collector could meet; a list of
   exact strings, no patterns). Any other: `fatal error (its words are only in the report)`.
2. **A `panic: runtime error: ` line** is quoted only when its rest matches one of a fixed list of patterns
   made of fixed words and numbers alone (`invalid memory address or nil pointer dereference`,
   `integer divide by zero`, `index out of range [N]` with or without ` with length N`, the
   `slice bounds out of range` forms with their numbers, `assignment to entry in nil map`,
   `makeslice: len out of range`, `makeslice: cap out of range`). Any other panic, a `runtime error` not on
   the list included: `panic (its message is only in the report)`.
3. **An `Exception 0x...` line**: only the word and a hexadecimal number of at most 16 digits.
   **A `[signal ` line**: only `signal` and the fixed name that follows when it is one of a fixed list
   (`SIGSEGV`, `SIGBUS`, `SIGFPE`, `SIGABRT`, `SIGILL`), nothing else of the line.
4. **A `runtime: ` line** is quoted only when it is exactly `runtime: goroutine stack exceeds N-byte limit`
   (N digits). No other, before or after anything.
5. **A function** goes into `top` and `at` only when its line has the shape of a Go symbol (letters, digits
   and `_ . / ( ) * [ ] , -` only: no space, no colon), holds a dot, ends in an argument list, and the next
   line is a location line (a tab, then a path that ends in `.go:N` or `.s:N`, then nothing or the runtime's
   own ` +0x..`, ` fp=.. sp=.. pc=..` tails). Anything else is skipped, not cleaned.
6. **The file of `at`** is the base name alone, taken from the right of the location (after the last `/` or
   `\`), and only when it is letters, digits, `_ . -` and ends `.go:N` or `.s:N`; else `at` has no file.
7. `safe` stays as a last net behind these, not as the rule.
8. **The privacy guard is rebuilt so that it can fail:** the invented marker word is put, in turn, on a line
   starting `fatal error: `, between the pieces of a real fatal line (the review's 1b), between a function
   line and its location (1c), on a `runtime: ` line before and after the crash's first line (1d), in a
   panic message starting `runtime error: ` (1e), and in a build path with a space (1f); for each the
   watchdog's own output, `history.jsonl` and `watchdog-status.json` must not hold it. Each of rules 1 to 6
   is shown failing the guard when undone.

## B. Crash text counts only when the child ended right after it (review 2, 6, 8: high)

The runtime prints its crash text as the last thing a process does. So:
9. The keeper notes the moment (the watchdog's clock) at which the crash text's first line was seen. **It is
   evidence of a crash only if the child ended within 2 minutes of that moment** (`crashWindow`, a constant;
   a big report under load takes seconds). Classification takes the end's time.
10. **When a child is still running after that window, the keeper lets the text go and looks again from then
    on** (the tail keeps being kept), so a real crash hours later is seen and recorded, and no more than the
    window's text stays in memory. A named test with the review's probe: an early crash-looking line, 17 MB
    of ordinary lines over more than the window, then a real fatal error: on record with the real one's
    words.
11. A crash report is written, and `Parse` run, **only for an end classed as a crash** (review 8).
12. The review's probes as named tests: a crash-looking line, five hours, then exit code 1: `ended by
    itself`, no restart; the same line and exit code 1 within the window: a crash (said in a comment: this
    is the price of the rule; today's collector prints no such line), its words not quoted (A).

## C. Stops (review 4, 5)

13. **Before every start of a child the interrupts are looked at once more**: a stop that is there ends the
    watchdog as a stop during the wait, nothing started (the first start included).
14. **A noted stop does not last for ever.** When the child is still running 10 minutes after the last noted
    stop (`stopHolds`, a constant, the watchdog's clock), the watchdog says in fixed words that the program
    did not stop and the stop no longer counts; a later crash is then a crash. A second stop counts anew.
    The review's probe (a stop in the instant before the child is on the console, the child runs six hours,
    then crashes) becomes a named test: restarted.
15. **Off Windows a noted stop is passed on to the child** (SIGTERM, once per noted stop), because there the
    signal reaches the watchdog alone; on Windows nothing is sent (the console gives the event to both). A
    small pair of files by build tag; the fake child records it for a test on every system.

## D. A child that outlived its watchdog (review 3)

16. At its start, before it settles anything, the watchdog reads the marker: **when it names a child process
    that is still alive, the watchdog starts nothing**: fixed words ("the program started by the last
    watchdog is still running (process N): nothing was started; stop it first"), exit code 2, the marker
    and the history left as they are. "Alive" is: a process of that number exists and was created within
    2 minutes of the marker's start time (so a number given to another program later is not taken for it);
    Windows by `OpenProcess`, `GetExitCodeProcess`, `GetProcessTimes` from the standard library's `syscall`,
    elsewhere by signal 0 and, where the start time cannot be read, the number alone (say so). A named test
    with a real living process (the test binary as a helper that waits on its standard input) and one with a
    process that has ended.
17. Not changed, and said in the package's comment: the child is not tied to the watchdog's life (a killed
    watchdog leaves a healthy collector downloading); 16 is what keeps a second watchdog from starting a
    second collector beside it.

## E. Small ones (review 9 to 12)

18. A wait or a gate in the status file is compared as a number before it becomes a time: anything more than
    6 hours ahead, the end of the number range included, is taken as 6 hours and counted (9).
19. Crash reports are pruned, and temporary files found, by listing the folder and matching names, not by a
    pattern built from the folder's path (10).
20. `history.jsonl`: only "there is no file yet" starts a new history. Any other failure to read it appends
    the new line to the file as it is (no rewrite, no pruning that time) and is counted (11). A temporary
    file left by a failed rename is removed at the next write.
21. A marker that could not be removed after an end already on record does not become a second line at the
    next start (compare its start time with the last history line's) (12).
22. `collector_status_stale` is false whenever no child runs (12).

## F. Tests the review found missing (its last list): add each as a named test

The output logs appended across children and rotated at 16 MB; the marker touched every minute by the loop;
the stale status file counted and nothing killed; the daily cap in the loop with exit code 1; a Windows
exception status with no text restarted by the loop; "status not read" and "taken as 6 hours" counted and said
by the loop; a failed write costing the record only, at the loop's level; the lock between two real processes
and free after a kill; no standard input for the child; a second stop while the child runs; `Parse` on the
real text of this Go version for a fatal error, a nil dereference, a stack overflow and a Windows exception
(real helper children, as the end-to-end test starts one). And the review's note on
`TestLoopCrashIsRestartedAfterTheDelayNotBefore`: make its "not before" check wait for the loop to have seen
the clock move.

## Not built, on purpose (say so in the package's comment where it helps a reader)

Review 7 (crash text that starts in the middle of a line the child had not ended: the safe side, no restart);
a read error on a stream while the child lives; a grandchild holding a pipe; the 32-bit exit codes; a Policy
made by hand and not checked.

## Rules

As K2's: only the three new folders; the standard library alone (the wall tests); no real time in any test;
invented data; named tests or these three packages only, one go command at a time, free memory looked at
first (2.5 GB); no race detector, no Docker; `gofmt -l` clean and `go vet` of the three clean. Each fix A to E
shown failing its test when undone (say which mutation for which). Commit as you go and push
`wip/core-watchdog` to `private`.

## Hand back

The head; for each numbered item: what changed, its test, its mutation; what was built differently and why;
the `ok` lines; the fatal messages and panic patterns on your lists (the lists themselves).
