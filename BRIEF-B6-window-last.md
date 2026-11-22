# Brief B6-W3: the last round on the window's gate and pages mode, after the review's second look (viewer session B6, 11-16)

You are an Opus coder for the viewer track of the new archiver, taking over a branch others built. Work only
in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-join` (Go module in `archiver/`), on the branch
`wip/b-winpages` (head 8e5664a9, pushed; check the copy is clean and on that head first; if not, stop and say
so). Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash. **Named tests
only; the whole runs and the race detector are not yours.** The hard rules of
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-B6-window-pages.md` and of `BRIEF-B6-window-gate.md` bind you
unchanged (only `internal/window` and `cmd/tgarchive-window`; the owner's programs and folders; a start of
`tgarchive-window` only on a scratch folder of your own with `LOCALAPPDATA` and `TEMP` pointed at empty scratch
folders, output to a file; words; load; commits; push only `wip/b-winpages` to `private`).

**Four rules that were broken or missing in the last round, hard now:**
- **No search over a whole drive, ever** (`find /`, `dir /s` from a drive's root, a glob from a root): look only
  inside the copy, your own scratch folder and the Go toolchain's folders.
- **No step that crashes the engine on purpose**, in a test, a probe or a self-check.
- **No window with the gate off or bypassed.** A real window **at most three times in all**.
- **Tests and probes name addresses, never host names.**
- For the viewer's self-check: ffmpeg is the one PowerShell's `Get-Command ffmpeg` gives (hand it by
  `FFMPEG_PATH`); mpv is the folder
  `C:\Users\trabi\AppData\Local\Temp\claude\639d98b407042671\a1138643-a691-474b-aff4-3ed4e639f547\scratchpad\mpv-tool`
  (a copy the main session made for you; read it, change nothing in it, hand it by `-mpv`).

**Read first, in full:** `C:\Users\trabi\Claude\Projects\Telegram\wt-b6-review-W-scratch\REVIEW-2.md` (the
second look: nine new findings and what the self-check should fail on) with its probes in `probe2/` and its
printouts (read-only: copy what you turn into tests); the code its findings name.

## The decisions (the main session's)
1. **N1 (a frame's navigation takes the view's place).** Only the top-level `NavigationStarting` sets the
   navigation the pages view follows; the frame handler does not. `TestPagesStaleNavigation` gains a frame
   event; the review's case (a named frame that refreshes itself while the page goes to an empty 500) is a
   test.
2. **N2 (crash data can leave through Windows: the one way left out of this PC).** Build the options object
   the review describes and hand it to the loader in both modes: it sets `IsCustomCrashReportingEnabled`
   TRUE (the engine's crash data is then not sent by Windows). Whether it also carries the additional
   arguments in place of the variable is yours to decide by what you can measure (the gate must still see
   everything; the variable must still not be left for a child program); say which and why. **It is native
   code: get the interface's layout from the binding's own sources or Microsoft's header in the Go module
   cache, never from memory, and say where each slot's number comes from.** Proven by: the window starts and
   the self-check passes with it; the option read back where the interface lets it be read. **Not proven,
   and said so: that a dump stays on this PC after a crash (no crash is caused).** If it cannot be built
   soundly in this round, say so plainly and leave the engine's start as it is: the main session then puts
   the residual to the owner.
3. **N3 (a 503 with the app's own words is hidden).** The window's line replaces a page only when no document
   of that navigation was committed, or the committed document is the engine's own error page. A named page
   that answers 500 or more WITH a body is shown as it is. The review's case (a 503 with a text body) is a
   test; the empty 500 still shows the line.
4. **N4 (a download's name and place).** An allowed `text/plain` download in the pages mode is saved in the
   person's Downloads folder under a name of the window's own (`tgarchive-` and the date and time, `.txt`;
   never a name or an extension a page chose; never over an existing file). Say how the viewer's mode names
   its own downloads today and leave that as it is.
5. **N5 (the link line shows a page's words).** Decided: kept as it is (the address is what the person needs
   to copy); nothing to build.
6. **N6 (the engine's own sign-in dialog).** The gate drops `WWW-Authenticate` from every answer it passes, in
   both modes (pure Go, a test), so no credential dialog of the engine can be raised by a server.
7. **N7.** The gate's server gets a `ReadTimeout` of one minute; a test that a streamed ANSWER longer than
   that is not cut.
8. **N8 (the wall).** `net.Resolve*`, `net.Lookup*`, `net.ListenPacket`, `net.ListenUDP`, `net.ListenIP`,
   `net.ListenMulticastUDP` are refused in every file of the package (name the one exception if a file
   rightly uses one, and why); a `net.Listen` on anything but a `127.0.0.1` address is refused where the
   source can show it; the callers of the probe's listeners are pinned to the two self-check files. Each
   with the mutation it catches.
9. **N9.** The self-check removes its net log's folder after the engine is known to be gone, trying again
   for a bounded time, and its fixed line says whether it was removed.
10. **What the self-checks fail on, and what they only print (the review's list, accepted):** FAIL on a
    connection at the port nobody named (per kind), a UDP packet at the page's UDP address, a TCP attempt off
    127.0.0.1, **a UDP datagram sent off 127.0.0.1** (count the log's bytes-sent events per socket whose
    connect went off 127.0.0.1), any resolver job, system task or DNS transaction, any request refused at the
    gate that names a host at start or idle. PRINT ONLY: UDP connects (the engine's IPv6 reachability check:
    a connect sends nothing), names answered inside the engine, crash dumps found. The check that fails on
    a UDP connect today is replaced by the datagram check.
11. **The final build seen in a window: once in each mode**, after everything above is in (the pages
    self-check, and the viewer's self-check on an invented archive to its END: the reviewer's ended after a
    second because its invented clips could not be made: find why and say). Both must exit 0. The third
    window is a spare.

## At the end, once
`gofmt -l`; `go vet ./internal/window ./cmd/tgarchive-window`; your named tests (every test this round and the
last added, by name); `CGO_ENABLED=0 go build ./...`; `git diff 8e5664a9 HEAD | grep '^-func Test'` prints
nothing or you account for each line. Commit and push. Hand back, as your last message: the head (pushed);
each of the eleven with what you did and any difference and its reason; for N2 where each slot's number comes
from and what was proven; the two self-checks' lines (numbers), their exit codes, how often and how long a
window was open; anything that changed for the pages track; every new or changed string; what you did NOT
test; your doubts, plainly. Commit-ready, nothing left running (count the engine's processes before and
after), the copy clean, your scratch files removed.
