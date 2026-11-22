# DRAFT for the owner to read: a report to the Go project (board item 19; Core, K-3, 2026-11-15)

Not posted. It would go to https://github.com/golang/go/issues under the owner's account, or not at all.
It holds versions, a probe with invented numbers and two small patches; nothing of the archive, no name,
no path of this PC. The probe file to attach is `core-probes\winsyscall-args\main.go` in the project
folder (134 lines). Before posting: the one check marked "TO CHECK" below.

---

**Title:** runtime: on Windows the argument array of `syscall.SyscallN` can be freed before the call copies it, when the array is on the heap (`x/sys/windows` `LazyProc.Call`)

### Go version

go1.27.3 windows/amd64 (Windows 11, 12 logical cores). `golang.org/x/sys` v0.49.0.

The current development tree has the same code (read on 2026-11-15 from the master branch:
`syscall_syscalln` stores `uintptr(noescape(unsafe.Pointer(&args[0])))`, calls `cgocall` and does not
touch `args` again).

### What did you do?

A program that makes many Windows calls through `golang.org/x/sys/windows` `(*LazyProc).Call` (in our
case through `modernc.org/libc`, which makes all its Windows calls that way) crashed once, under load,
with exception 0xc0000005 inside `LockFileEx`. The registers showed the right function and the right
argument count, and an argument array holding zeros and one small number: the look of memory that had
been given to something else. The Go frames above showed the correct values being passed.

Reading the sources:

- `(*Proc).Call` and `(*LazyProc).Call` carry `//go:uintptrescapes`, so the variadic argument slice's
  backing array is on the heap (`-gcflags=-m`: "escapes to heap"). With
  `syscall.SyscallN(proc.Addr(), ...)` called directly it stays on the stack.
- `runtime.syscall_syscalln` stores the array's address as a plain number,
  `c.Args = uintptr(noescape(unsafe.Pointer(&args[0])))`, and then calls `cgocall(asmstdcallAddr, ...)`,
  which enters the system-call state before the code that copies the arguments runs.
- The compiler's liveness listing (`-live`) shows no reference to the array live at that call, in
  `syscall_syscalln`, `syscall.SyscallN`, `Proc.Call`, `LazyProc.Call` or the caller.
  `syscall_syscalln` carries `//go:uintptrkeepalive`; as far as we can tell that keeps alive what the
  caller's arguments point to, not the backing array of the variadic slice itself once it is on the heap.

So from the moment the address is stored until `asmstdcall` has copied the arguments, nothing keeps a
heap-allocated argument array reachable. If the thread loses the CPU in that window for as long as one
garbage collection takes, the array can be freed and its memory reused.

This is about the argument array itself, not about objects the arguments point to (that is #34474 and
the documented use of `runtime.KeepAlive` by the caller): a caller cannot keep this array alive, since it
is the variadic slice the compiler made.

### A probe

Attached `main.go` (no file, no network): `MulDiv(n, 1, 1)` must return `n`. One group of goroutines calls
it through `LazyProc.Call`, a control group through `syscall.SyscallN` (array on the stack); two goroutines
make garbage of the array's size and one forces collections. Bound to 2 cores.

| Run | Result |
|---|---|
| plain, 100 s, 2 threads | 573 million calls through `LazyProc.Call`, 0 wrong; control 2,085 million, 0 wrong |
| plain, 100 s, 24 threads on 2 cores | 347 million, 0 wrong; control 2,388 million, 0 wrong |
| with the stall patch below (every 1000th six-argument call held 50 ms in the window) | access violation in the runtime's copy of the arguments, at the array's own address, within the first second; 3 runs of 3 |
| the stall patch plus the one-line patch below | 30 s, 539,648 calls (about 540 stalled), 11,626 collections, 0 wrong, clean exit; `-live` now lists the array live at the call |

So without help the window is hit very rarely (not once in 920 million calls here); the one crash we
have on record came with the machine at about 80% CPU. The stall patch only widens the window to show
the mechanism.

The stall, for the probe only (`-overlay`):

```diff
--- go/src/runtime/cgocall.go
+++ patched/cgocall_stall.go
@@ -166,6 +166,12 @@
 	// saved by entersyscall here.
 	entersyscall()
 
+	// PROBE ONLY: hold every 1000th six-argument Windows call here for 50 ms, after the arguments'
+	// address was stored and before asmstdcall copies them.
+	if fn == asmstdcallAddr && arg == unsafe.Pointer(&mp.winsyscall) && mp.winsyscall.N == 6 && mp.ncgocall%1000 == 0 {
+		usleep(50000)
+	}
+
```

### What did you see happen?

With the stall: the process dies with an access violation while copying the arguments. In the wild: one
crash inside a Windows function entered with a garbage argument array.

### What did you expect to see?

The arguments passed to `syscall.SyscallN` reach the Windows function whatever the scheduler does.

### A possible fix

One line closed it in the probe:

```diff
--- go/src/runtime/syscall_windows.go
+++ patched/syscall_windows_keep.go
@@ -425,6 +425,8 @@
 		c.Args = uintptr(noescape(unsafe.Pointer(&args[0])))
 	}
 	errno := cgocall(asmstdcallAddr, unsafe.Pointer(c))
+	// c.Args is a plain number: keep the arguments' array reachable until the call has returned.
+	KeepAlive(args)
```

We build with that line in a local toolchain since 2026-11-15; no crash of this kind since (a short
time, not a proof).

---

## Notes for the owner (not part of the report)

- What is shown and what is not: the mechanism is shown by the probe with an artificial stall; that the
  one real crash was this and nothing else cannot be replayed (the registers fit it exactly).
- Related and not the same: Go issues 34474 (`LazyProc.Call` and what it keeps alive), 16035 and 42680
  (pointers passed as numbers; the safety of `Proc.Call`). A search on 11-15 found no report of exactly
  this.
- The current development tree was read on 11-15 at 22:43 (the master branch's
  `src/runtime/syscall_windows.go` and `x/sys`'s `windows/dll_windows.go`): the function is unchanged, no
  line keeps `args` reachable after the call, and no issue number stands in its comments. Read it once
  more on the day of posting: a fix may land in between.
- One sentence in the report is my reading and not shown by a run: what `//go:uintptrkeepalive` covers.
  It is worded as "as far as we can tell"; the Go team will know.
- "We run with that line in a local toolchain since": the integrator put the line into
  `ix-tools\goroot-1.27.3` on 11-15; change "a few days" to the real span on the day of posting.
