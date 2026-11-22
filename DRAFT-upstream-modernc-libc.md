# DRAFT for the owner to read: a report to the authors of the pure-Go SQLite (board item 19; Core, K-3, 2026-11-15)

Not posted. It would go to the issue tracker of `modernc.org/libc` (https://gitlab.com/cznic/libc/-/issues)
under the owner's account, or not at all. It holds versions and numbers from a probe with invented data;
nothing of the archive, no name, no path of this PC. It is the smaller of the two reports: the cause is in
the Go runtime (the other draft, `DRAFT-upstream-go-syscalln.md`), and this one only tells the library's
authors that they can step around it on their side.

---

**Title:** windows: calls made through `LazyProc.Call` can enter Windows with a freed argument array (a Go runtime window); `syscall.SyscallN(proc.Addr(), ...)` avoids it

### Versions

`modernc.org/sqlite` v1.61.1, `modernc.org/libc` v1.79.0, `golang.org/x/sys` v0.49.0, go1.27.3
windows/amd64, Windows 11. Read as well, not run: `modernc.org/libc` v1.81.2 makes the calls the same way.

### What happened

One crash on record, under load (the machine at about 80% CPU): exception 0xc0000005 inside `LockFileEx`,
reached from SQLite's read lock on the shared-memory file. The registers showed the right function and
argument count and an argument array of zeros and one small number; the Go frames above showed the
correct values being passed. Nothing in SQLite or in the library's logic is at fault.

### Why

`(*LazyProc).Call` in `golang.org/x/sys/windows` carries `//go:uintptrescapes`, so the variadic argument
array of each call is on the heap. The Go runtime then stores that array's address as a plain number and
enters the system-call state before the arguments are copied; in between nothing references the array. If
the thread loses the CPU there for as long as one garbage collection takes, the array is freed. The
library makes its Windows calls (157 call sites in v1.79.0 by our count) through `LazyProc.Call`.

A probe with a harmless function (`MulDiv(n, 1, 1)` must return `n`; no file, no network):

| Run | Result |
|---|---|
| through `LazyProc.Call`, plain, 2 runs of 100 s | 920 million calls, 0 wrong |
| through `syscall.SyscallN(proc.Addr(), ...)` (array on the stack), the same runs | 4,473 million calls, 0 wrong |
| through `LazyProc.Call`, with the Go runtime patched to hold every 1000th call 50 ms in that window | access violation while the runtime copies the arguments, within a second; 3 runs of 3 |
| the same, plus one line in the runtime keeping the array reachable | 30 s, about 540 stalled calls, 11,626 collections, 0 wrong |

So it is very rare without help and tied to load. We are reporting the runtime side to the Go project.

### What would avoid it on the library's side

Calling `syscall.SyscallN(proc.Addr(), a, b, ...)` in place of `proc.Call(a, b, ...)`: the compiler then
keeps the argument array on the stack of the calling goroutine (`-gcflags=-m` says "does not escape"),
where it cannot be freed during the call. It is also the cheaper call (no allocation per call).

We have not made that change in a copy of the library and run it; we closed it for ourselves in the
toolchain. Offered as a pointer, not as a tested patch.

---

## Notes for the owner (not part of the report)

- The tracker's address is from the module's own page as I remember it and was not opened by a session
  (the earlier Core session could not read the GitLab trackers either): look that it is the right place
  before posting, and whether the same report is already there.
- The 157 call sites are the earlier Core session's count for v1.79.0 (`FINDING-CORE-crash-28.md`); not
  counted again by me.
- Post the Go report first and put its link into this one where it says "We are reporting".
