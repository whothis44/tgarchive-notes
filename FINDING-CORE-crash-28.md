# The crash of board message 28: what it is (Core session, 2026-11-15 17:45 local)

A whole test run of `internal/collector` ended on 11-15 about 16:05 with Windows exception 0xc0000005 inside
the pure-Go SQLite (`runs-12b/win-collector.log`). This file says what it is, how that was shown, and what
would close it. Numbers and versions only; every probe used invented numbers and no file, database or network.

## In short

- **It is not a defect of SQLite, of the catalogue's handles, or of our code.** Windows' `LockFileEx` was
  entered with a garbage argument array: the Go program had passed the right values, and they were gone
  before the Go runtime copied them.
- **Cause, shown by experiment:** a Windows call made through `golang.org/x/sys/windows` `LazyProc.Call`
  (v0.49.0) puts its arguments in a heap array, and from the moment the Go runtime (1.27.3) has stored that
  array's address as a plain number until it copies the arguments, nothing references the array. If the
  thread loses the CPU in that window for as long as one garbage collection takes, the array is freed and
  its memory reused or released. `modernc.org/libc` v1.79.0 makes all its 157 Windows calls that way, so
  every SQLite read and write on Windows passes through it.
- **It is rare by nature and tied to load:** 0 wrong results in 920 million calls without a stall; a crash
  within a second, 3 runs of 3, when the thread is held 50 ms in the window. The one crash on record came
  with the PC at about 80% CPU.
- **No newer version addresses it.** `modernc.org/sqlite` v1.61.1, v1.62.0 and v1.62.1 (11-13, the newest)
  say nothing about it; `modernc.org/libc` v1.81.2 (11-15, the newest) still makes the call the same way.
- **One added line closes it for every Windows call of every package** (`KeepAlive(args)` in the Go
  runtime's `syscall_syscalln`): with it, the same 50 ms stall ran 30 s (about 540 stalled calls, 11,626
  collections) with no wrong result. Where that line goes is the integrator's decision (below).
- A real collector can die the same way and nothing restarts it: the watchdog (this track's next piece) is
  needed whatever is decided here.

## What the log shows (read by me: the stack, the registers, the other tasks)

- The fault is at KERNELBASE.dll + 0x23b9b, which is `LockFileEx` + 0x1b (found from the library's export
  table; the PC had not been restarted since, so the address still held): the instruction that reads the
  OVERLAPPED argument's `Offset`, with that pointer equal to 0x77.
- The registers at the fault: the four register arguments all 0, the sixth argument 0x77, six arguments
  copied (the runtime's copy pointers are 0x30 apart). The Go frames above show what was passed: a file
  handle, flags 1, reserved 0, length 1, 0, and a valid pointer. So the count and the function were right
  and only the array's content was wrong: zeros and 0x77, the look of memory given to something else.
- The task was a download lane's claim reading the catalogue (`engine` claim, `supply.Next`,
  `catalog.LaneNext`, `readCached`, the driver's `step`, SQLite's read lock on the shared-memory file). It
  is not special to the monitor or to how the catalogue opens its handles: any statement takes that lock.
- The SQLite library's own exception shim (`lib/seh.go`, in the stack) plays no part: it turns a fault in
  the mapped shared-memory pages into an error, and this fault was inside Windows.

## Why the array can vanish (read in the sources on this PC, then checked with the compiler)

- `x/sys/windows` `Proc.Call` and `LazyProc.Call` carry `//go:uintptrescapes`: the compiler reports the
  argument array "escapes to heap" for a call through them, and "does not escape" for
  `syscall.SyscallN(proc.Addr(), ...)` (my probe, `-gcflags=-m`).
- `runtime.syscall_syscalln` stores `uintptr(&args[0])` in the thread's record and calls `cgocall`, which
  enters the system-call state and only then runs the code that copies the arguments. The compiler's own
  liveness listing (`-live`) shows no reference to the array live at the call in `syscall_syscalln`,
  `syscall.SyscallN`, `Proc.Call`, `LazyProc.Call` or the caller. A task in the system-call state can have
  its stack scanned, so a collection that starts and ends while the thread is off the CPU frees the array.
- Related, known upstream, not the same report: Go issue 34474 (`LazyProc.Call` and what it keeps alive),
  a golang-nuts thread "Proc.Call() forces heap allocation, while syscall.SyscallN(Proc.Addr()) doesn't".
  I found no report of exactly this; the GitLab trackers of the SQLite library could not be read.

## The probe (bounded, said with the PC's load)

`core-probes/winsyscall-args/` in this folder (not tracked by git: `main.go`, `stall.diff`, `keepalive.diff`).
`MulDiv(n, 1, 1)` must return n; one group of tasks calls it through `LazyProc.Call`, a control group
through `syscall.SyscallN` (array on the stack); two tasks make garbage of the array's size, one forces
collections. Bound to 2 of the 12 logical cores.

| Run (11-15) | PC before | What | Result |
|---|---|---|---|
| 17:34, 100 s | CPU 65%, 4.0 GB free | plain, 2 Go threads | 573 million calls through `LazyProc.Call`, 0 wrong; control 2,085 million, 0 wrong |
| 17:36, 100 s | CPU 36%, 4.0 GB free | plain, 24 Go threads on the 2 cores | 347 million, 0 wrong; control 2,388 million, 0 wrong |
| 17:39, 20 s asked | same | every 1000th six-argument call held 50 ms in the window (`stall.diff`, a patched copy of one runtime file by `-overlay`, for the probe only) | died in its first second: access violation in the runtime's copy of the arguments, at the array's own address. Twice more, 10 s asked each: the same |
| 17:40, 30 s | same | the stall, plus `KeepAlive(args)` (`keepalive.diff`) | 539,648 calls (about 540 stalled), 11,626 collections, 0 wrong, clean exit; the compiler now lists the array live at the call |

Not shown: that the crash of 16:05 was this and nothing else (it cannot be replayed); how often a loaded
PC holds a thread that long in that window. The registers fit this cause exactly and I found no other
that does.

## What it means for a real collector

- Likelihood: low, and it grows with the PC's load and with how often the program collects garbage. One
  crash on record, in a whole-package test run beside other sessions' builds.
- Outcome when it happens: most likely the process ends (as here). In principle a call entered with other
  arguments can also fail oddly instead (an error from a lock, a read or a write on a wrong handle); the
  catalogue's writes are transactions and staging is checked by hash, so a wrong call should surface as an
  error or a crash, not as silent damage. Not proven.
- So: a collector that died must be restarted (the watchdog), and the cause should be closed at its root.

## Ways to close it (the integrator's to choose: `go.mod`, the toolchain and the build are not Core's)

1. **Recommended: the one line in the local toolchain**, `ix-tools/goroot-1.27.3/src/runtime/syscall_windows.go`
   (`keepalive.diff`; the file's SHA-256 today begins 53518810c4557c36), with a check in
   `ix-tools/env-archiver.sh` that warns when the line is missing (the toolchain was rebuilt once already,
   on 11-14). It covers libc, x/sys and anything else that calls Windows, in every program built here
   (collector, viewer, bring-in, tests); no `go.mod` change, no copy of a module. Every package is compiled
   again once (the build cache is shared). The installed programs get it at their next build (G1's install).
2. The same line by `-overlay` (a patched copy of that one file kept in `ix-tools`, `GOFLAGS=-overlay=...`
   set by `env-archiver.sh`): nothing in the toolchain folder changes, but a build started without the
   script silently lacks it.
3. Not recommended: a `replace` of `modernc.org/libc` with a copy whose 157 calls use
   `syscall.SyscallN(proc.Addr(), ...)`: a `go.mod` change, a module copy to carry, and it leaves every
   other caller of `LazyProc.Call` as it is.
4. Upgrading the libraries does not help today.

Reporting it upstream (Go; the SQLite library's authors, who can avoid the heap array on their side) would
be posted under the owner's account: on the board's list for the owner, not urgent.
