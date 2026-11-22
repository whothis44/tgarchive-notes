# Brief B6-W2: the window's gate (nothing but the named local ports is ever asked, in both modes), and the fix round of the pages mode (viewer session B6, 11-16)

You are an Opus coder for the viewer track of the new archiver, taking over a branch another coder built.
Work only in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-join` (Go module in `archiver/`), on the
branch `wip/b-winpages` (head bc6a44f5, pushed; check the copy is clean and on that head first; if not, stop
and say so). Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash.
**Named tests only; the whole runs and the race detector are not yours** (`CLAUDE.md`, the archiver section,
second point). The hard rules of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-B6-window-pages.md` bind you
unchanged (only `internal/window` and `cmd/tgarchive-window`; the owner's programs and folders; a start of
`tgarchive-window` only on a scratch folder of your own with `LOCALAPPDATA` pointed at an empty scratch
folder, output to a file; words; load: check free memory and CPU before each go command and wait while the
CPU is over 85% or free memory under 2.5 GB; commits; push only `wip/b-winpages` to `private`). **Tests and
probes name addresses, never host names.**

## Why
The independent security review (`C:\Users\trabi\Claude\Projects\Telegram\wt-b6-review-W-scratch\REVIEW.md`:
read it in full first, with its probe `probe/zz_review_probe_windows_test.go`, its printouts `outA.txt`,
`outB.txt`, `outC.txt` and its `scripts/`; read-only: copy what you turn into tests) measured that **the
window's browser engine sends requests of its own to the internet at every start, in BOTH modes** (its
component updater and its configuration service, with DNS lookups), that a shown page's sub-resources go to
any address, and that a refused navigation has sent its request before the window refuses it. This program
runs on the owner's PC outside the VPN: every such request shows the owner's own address. **The viewer's
window, which the owner uses on a private archive, does this today.** The review also measured the cure: with
the engine pointed at a gate inside this program, every one of 26 kinds of request and the engine's own
ended at the gate and nothing reached an address nobody named.

**So the order of your work is fixed: build the gate first, test it in plain Go, and only then open any real
window. Until the gate is in and on, every real window you open lets the engine call out from the owner's
address: do not open one before.**

## The decisions (the main session's; every finding is accepted unless it says otherwise)
**A. The gate, in both modes (findings F1, F2, F10).**
- A1. Before the WebView2 loader runs, the program sets `WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS` for its own
  process to its own value and removes `WEBVIEW2_USER_DATA_FOLDER`, `WEBVIEW2_BROWSER_EXECUTABLE_FOLDER`,
  `WEBVIEW2_RELEASE_CHANNEL_PREFERENCE` and `WEBVIEW2_PIPE_FOR_SCRIPT_DEBUGGER` from it (an inherited value
  must never steer the engine; say what the self-check's own use of the executable-folder variable becomes).
  The value: the engine's proxy is the gate (`--proxy-server=http://127.0.0.1:G`), loopback is NOT bypassed
  (`--proxy-bypass-list=<-loopback>`), and no host name is ever resolved
  (`--host-resolver-rules="MAP * ~NOTFOUND , EXCLUDE 127.0.0.1"`; measure whether the engine's last two
  host lookups are gone with it, by the engine's own net log in the self-check only). Add what else you can
  show to help and not to harm (the component updater, background networking, the first-run and sign-in
  pieces), each only with a measurement; say what you tried and dropped.
- A2. The gate itself: a listener of this process on `127.0.0.1:0`, opened before the engine starts, closed
  at the end. It forwards a request only when it is plain `http` to an absolute address whose host is exactly
  one of the allowed `127.0.0.1:PORT`: in the pages mode the named set; in the viewer's mode the viewer's own
  port, which is known only after the viewer has started (the allowed set is empty until then, and set
  once). Everything else (another port, another host, `CONNECT`, a request with no absolute address, a
  WebSocket to anything not allowed) is answered 403 and counted by kind, in the fixed words the mode
  already counts refusals by. **The rule is one pure function, tested without a window** (forward if and
  only if: http, host in the set). Forwarding streams (the collector's live route and the viewer's media
  answers must not be buffered: no added latency, range requests and a client that goes away handled);
  its own outgoing side can reach only an allowed address whatever the request says (as
  `internal/viewer/act_door.go` on `private/wip/b-door` pins its dial: read it for the pattern), never a
  proxy from the environment, never a redirect followed by the gate itself. A request's and an answer's
  headers pass as they are but for the hop-by-hop ones; nothing of a request is logged: counts only.
- A3. The wall test of `internal/window` names the gate's one file as the place where `net/http` serves and
  dials, pinned as tightly as the viewer's door file is.
- A4. WebRTC: the review still saw 4 UDP packets to a page-named address with the gate in. Try what can
  close it without giving a page a new power (an engine switch; a fixed one-line script the shell adds to
  every document that removes the WebRTC constructors, in both modes) and **measure it with the review's
  step**; keep only what measures 0 packets; if nothing does, say so: it is then written down as a residual
  (only a page's own script can open it, and the app's pages and the viewer's allow only their own).
- A5. **The measure of success, as failing checks, not printed numbers:** in the self-check of each mode, a
  port of the program's own that nobody named must see 0 connections through every kind of request the
  review's probe makes (sub-resources of each kind, a refused top-level navigation, a frame, a meta
  refresh, a redirect from a named page, a link's `ping`, a press on a link, a form's POST), and the
  engine's net log (switched on by the self-check only, written into its own scratch folder, removed at
  the end) must show 0 connection attempts to any address that is not 127.0.0.1 and 0 lookups of any name.
- A6. **What it costs, measured:** in the viewer's mode on an invented archive (`tgarchive fabricate -files
  -videos`), the existing self-check's numbers before and after the gate (play to first picture; the
  library page with its thumbnails), and the time of 200 thumbnail answers through the gate against
  direct. A saved video still goes to mpv as a file, not through the gate: confirm it.

**B. The two modes apart (F3).** The pages mode has a key of its own for the mutex and the window class and a
WebView2 folder name of its own; a test that for one folder the two modes' three names differ. A pages start
on a folder where a viewer's window runs must not bring that window forward nor report success.

**C. What the engine keeps (F4, F11).** In both modes: general autofill off, password autosave off (set, not
assumed), the reputation check (SmartScreen) off; each checked as the other settings are. Crash dumps (F11):
say what turning the engine's crash reporting off takes; build it only if it is small and you can show the
dump folder stays empty after the self-check's crash step; otherwise write the residual down.

**D. The pages mode's own findings.**
- D1 (F5). A watch started before the loader runs ends the process with code 3 and the fixed line when no
  window has been shown within 10 s, whatever the message loop does; the engine's processes end with it.
- D2 (F6). A named page that answers 500 or more with no page shown is "not answering".
- D3 (F7). While opening, one timer of 15 s: then the window's line with "Try again".
- D4 (F8). Port 80 is refused in `-pages` (the engine reports that address without its port).
- D5 (F9). Nothing in the window; it is said to the pages track by the main session.

**E. What the app's pages need (the pages track, board message of 08:03), decided:**
- E1. A download in the pages mode is let through only from a named address and only when the answer is
  plain text (`text/plain`: the app's report), handled exactly as the viewer's mode handles its own allowed
  downloads; every other download stays refused and counted. Say how the viewer's mode saves a file today
  and that this is the same.
- E2. A refused link to the open web is not silent: the window shows a line of its own, "This link opens
  outside the app.", with the address as plain text (printable characters only, at most 300, never as
  markup) and a "Copy" button; nothing is handed to Windows and nothing is asked of the address.
- E3. In the pages mode the engine's user agent gains one fixed word, `tgarchive-window`, so that a page can
  tell where it runs. Nothing else of the user agent changes.

## Tests
- The gate's rule as a table; the gate end to end with `httptest` servers on 127.0.0.1 (an allowed port
  reached; another port, another host by address, `CONNECT`, a WebSocket upgrade, an absolute address with a
  user part: each 403, counted, and the other listener saw no connection); streaming (a slow answer arrives
  as it is written; a range request; a client that goes away closes the upstream); the set empty before the
  viewer's port is known; the environment's variables set and removed.
- Each of B, C, D1 to D4, E1 to E3 with a test that fails without it (for D1 a stand-in loader that blocks;
  for D3 a listener that accepts and never answers; for D2 an empty 500).
- The two self-checks (the pages mode's, and the viewer's on an invented archive with the gate in): **a real
  window at most FOUR times in all, each only after the gate is built and on; say how often and how long.**
- The existing tests of both packages by name where your change touches them;
  `git diff bc6a44f5 HEAD | grep '^-func Test'` prints nothing, or you account for each line.

## At the end, once
`gofmt -l`; `go vet ./internal/window ./cmd/tgarchive-window`; your named tests; `CGO_ENABLED=0 go build ./...`.
Commit and push. Hand back, as your last message: the head (pushed); each decision A1 to E3 with what you did
and any difference and its reason; **the gate as built** (what it forwards, what it refuses, how the engine is
pointed at it, what the engine can still do that the gate does not see, each with its measurement); the
self-checks' lines (numbers) and how often a window was opened; the cost numbers of A6; the mode's command
line, exit codes and anything else that changed for the pages track; every new or changed string; what you
did NOT test; your doubts, plainly. Commit-ready, nothing left running (count the engine's processes before
and after), the copy clean.
