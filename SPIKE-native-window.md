# Spike: the native window (brief B4-2), 2026-11-15, 16:10 to 16:40

What ran for real: one throwaway program, `archiver/spikes/window/` (a Go module of its own, `tgarchive-window-spike`),
on `wip/b-window-spike` in `wt-b-window`, last commit `ca1b426`, pushed to `private`. Nothing else in the repository
changed; the app's `go.mod` is untouched. Every number below comes from its `-measure` modes on this PC, with
invented clips made with ffmpeg's test sources (`testsrc2` 1280x720 30 fps plus a sine tone, 20 s each: A HEVC in MP4
5.5 MB, B MPEG-4 Part 2 in AVI 20.5 MB, C H.264 in MP4 with its index at the end 8.2 MB), kept in
`%TEMP%\b4spike\clips`, never committed. mpv: the folder the main session unpacked (v0.42.0-38, built 2026-11-11).
ffmpeg: `FFMPEG_PATH` was not set; the one `Get-Command ffmpeg` finds (7.1.1) was used.
The PC's load is given beside each set of timings (other coders were compiling). Two runs of each mode agreed;
the tables are from the last run.

## 1. Binding: `github.com/jchv/go-webview2` does it, through its lower layer `pkg/edge` plus about 100 lines of raw COM

Version tried: `v0.0.0-20260205173254-56598839c808`, which brings `github.com/jchv/go-winloader
v0.0.0-20250406163304-c1995be93bd1` and `golang.org/x/sys v0.0.0-20210218145245-beda7e5e158e`. Read in the module cache.
The Wails fork was not needed and not fetched.

| Asked | Answer |
|---|---|
| Builds with `CGO_ENABLED=0` | yes (Go 1.27.3; `go vet` only flags the raw pointer casts every Win32 caller has) |
| Host window's handle | yes: with `pkg/edge` the program creates the window itself and calls `Chromium.Embed(hwnd)`; the WebView2 then puts one child of its own (`Chrome_WidgetWin_0`) into it, found with `GetWindow` |
| Page to Go | yes: `window.chrome.webview.postMessage(string)` arrives in `Chromium.MessageCallback` on the UI thread |
| Go to page | yes, but not in the binding: `pkg/edge` only has `Eval` (ExecuteScript); `PostWebMessageAsJSON` was called raw (vtable slot 32). Go to page to Go round trip: median 0.11 to 0.42 ms, worst 0.91 to 1.63 ms over 20 (CPU 38 to 46%) |
| A user-data folder we choose | yes: `Chromium.DataPath`; the runtime created `EBWebView` inside the spike's own temporary folder |
| Navigation limited to our address | yes, but not in the binding: no NavigationStarting or NewWindowRequested in `pkg/edge`. Two small COM handler objects added: a navigation to another address was refused (1 of 1, the page stayed ours), `window.open` was refused (1 of 1, it returned null), a navigation within our address was allowed (1 of 1) |
| Added size of the program | +0.51 MB (+0.34 MB stripped), measured with two probe programs that differ only by using `pkg/edge`; it includes the embedded 134 KB `WebView2Loader.dll`. The whole spike is 10.4 MB (7.2 MB stripped) |
| WebView2 ready | 338 to 535 ms from `Embed` to a usable controller |

What it could not do, or does in a way the build must know:
- Its top-level API (`webview2.New...`) hides the `Chromium` object and owns the window procedure, so no
  navigation filter and no own message handling: use `pkg/edge` directly.
- The page must post **strings** (`JSON.stringify`): the binding reads messages with `TryGetWebMessageAsString`
  only (read in its code; posting an object was not tried).
- It **echoes every page message back to the page** as a string (`PostWebMessageAsString(sender, message)` in
  `MessageReceived`); the page ignores string messages and takes only objects (which is what
  `PostWebMessageAsJSON` delivers).
- No NavigationStarting, NewWindowRequested, ProcessFailed, PostWebMessageAsJSON: raw COM. In WebView2's headers a
  property's getter comes before its setter: the first try put `put_Cancel` at slot 7 and crashed; it is slot 8
  (NavigationStarting args: get_Uri 3, get_Cancel 7, put_Cancel 8; NewWindowRequested args: put_Handled 6).
- On a failure to create the environment or controller (for example no WebView2 runtime) it calls `log.Fatal`:
  the program dies. Check the runtime first (`webviewloader.GetInstalledVersion()`) and fall back to the browser.
- It loads `WebView2Loader.dll` first through the normal DLL search (`LazyDLL("WebView2Loader")`, so a file of
  that name beside the program would be taken), else its embedded copy through `go-winloader`, an in-memory PE
  loader. For the build's review.
- Its package `init` locks the main goroutine to the main thread and initialises COM single-threaded: `main()` is
  the UI thread, and every WebView and window call has to be sent there.
- Small bug seen in passing: its PermissionRequested handler passes the kind by value, so per-kind permissions
  never match. Not needed.

## 2. Stays on top: yes, 23 right of 23, without ever raising mpv's window again

The setup: our top-level window (`WS_CLIPCHILDREN`), the WebView2 filling its client area, and our own black
child window (`WS_CHILD | WS_CLIPSIBLINGS`) raised once when a video starts; `mpv --wid` draws into a window of its
own inside it. The page sends its rectangle in device pixels (CSS pixels times `devicePixelRatio`, each edge
rounded) on `resize`, `scroll`, a `ResizeObserver` on the frame, and a change of resolution; Go moves the child with
`SetWindowPos(..., SWP_NOZORDER)`. For each step the program read from Win32 the child's and mpv's rectangles and
the order of our window's children, waited at least 400 ms, and also sampled 144 screen pixels inside the frame
for the page's frame colour (1.00 with the child hidden, the baseline; 0.00 means mpv's picture is what shows).
"Right" = child exactly over the page's rectangle (0 px), mpv's window exactly over the child (0 px), the child
above the WebView2 in the order, page colour share under 0.05. CPU 46%.

| Step | dpi | child off by px | mpv off by px | child above | page colour | settled after ms | right |
|---|---|---|---|---|---|---|---|
| start | 96 | 0 | 0 | yes | 0.00 | 0 | yes |
| resize 1 to 10 (900x640, 1000x700, 1100x760, 1237x811, 1333x877, 1180x690, 960x900, 1400x820, 850x600, 1100x800) | 96 | 0 each | 0 each | yes each | 0.00 each | 4 to 11 | 10 of 10 |
| maximise | 96 | 0 | 0 | yes | 0.00 | 6 | yes |
| restore | 96 | 0 | 0 | yes | 0.00 | 6 | yes |
| full screen (window made borderless over the monitor) | 96 | 0 | 0 | yes | 0.00 | 10 | yes |
| windowed again | 96 | 0 | 0 | yes | 0.00 | 38 | yes |
| page scrolled to 150, 420, 900 (frame fully out of view), 0 | 96 | 0 each | 0 each | yes each | 0.00, 0.00, none visible, 0.00 | 16 to 17 | 4 of 4 |
| moved on the same monitor | 96 | 0 | 0 | yes | 0.00 | 3 | yes |
| moved to the second monitor and back | 96 | 0 | 0 | yes | 0.00 | 2 and 3 | 2 of 2 |
| after the drag-like resizing below | 96 | 0 | 0 | yes | 0.00 | 0 | yes |

Drag-like resizing (the nearest a program gets without the mouse): 40 sizes 16 ms apart; the child and mpv matched
the page's new rectangle within the same 16 ms 40 times of 40, median 8.6 ms, worst 14.5 ms. In the first run one
of the ten resizes settled after 261 ms (the others 4 to 31 ms); it did not recur in the two later runs.
**This PC has two monitors, both 2560x1440 at 100%**: a move between monitors of different scaling could not be
tried (changing the scaling is a system setting). The program handles `WM_DPICHANGED` (takes the suggested
rectangle) and the page reports a change of resolution, but that path is unmeasured. The fallback (mpv in its own
borderless window owned by ours) is built into the program behind `-fallback` but was not run, because the child
window did not fail.

## 3. Keys: they never pass through mpv; the page keeps the focus

- **mpv 0.42 creates its embedded window disabled** (`WS_DISABLED`, read with `GetWindowLongPtr`). No real mouse
  or key input reaches it: `WindowFromPoint` over the video gives our black child window, not mpv's.
- **Who gets the keys** (two real clicks by `SendInput`, only on points of our own window while it was in front;
  one real Right arrow after each, sent only while our window was the foreground window): after a click on the
  page's text the keyboard focus was `Chrome_WidgetWin_1` of the WebView2's browser process; **after a click on the
  video, the same**. The Right arrow reached the page's own `keydown` both times (3 to 27 ms from `SendInput` to the
  page's message arriving in Go, three runs, "looks like"). So the page's own key handling keeps working while a
  video plays, with no forwarding.
- With mpv's window enabled by us (`EnableWindow`), a real click on the video reached mpv (its `MBTN_LEFT` binding
  fired) and the keyboard focus still stayed with the WebView2.
- The forwarding path the plan described (an `input.conf` binding to `script-message`, read from the pipe, posted
  to the page, acknowledged back): 50 keys (Left, Right, Up, Down, Space, Escape in turn) **posted** with
  `PostMessage(WM_KEYDOWN/WM_KEYUP)` to mpv's window: 50 reported and acknowledged, none lost. From the post to
  mpv's report on the pipe: median 0.16 ms, worst 1.39 ms. From mpv's report to the page's acknowledgement: median
  0.31 ms, worst 3.27 ms. CPU 50%. Far under the 50 ms the plan set.
- Clicks into mpv without real input also work: a posted left click to mpv's window (disabled or not), the IPC
  command `mouse x y 0 single`, and `keypress MBTN_LEFT` all fired its `MBTN_LEFT` binding.

## 4. Start and decoding

`hwdec-current` under `--hwdec=auto-safe`: **HEVC `d3d11va`, H.264 `d3d11va`, MPEG-4 Part 2 `no`** (software;
same in all 10 starts each); under `--hwdec=no` always `no`. The PC has an NVIDIA GeForce RTX 5070 Ti and an AMD
Radeon iGPU; which adapter d3d11va used was not read. Local disk, sound muted (the audio output still opened).
CPU 26 to 29%, 5.7 to 6.3 GB free. Milliseconds, 10 starts each, median (best to worst):

| | A HEVC/MP4 | B MPEG-4 Part 2/AVI | C H.264/MP4, index at end |
|---|---|---|---|
| one mpv kept, its window kept (`--force-window=yes`), auto-safe | 42 (25 to 516; the first start 516) | 39 (37 to 162; first 162) | 27 (25 to 49) |
| same, `--hwdec=no` | 34 (21 to 64) | 40 (35 to 46) | 41 (21 to 57) |
| one mpv kept, window not kept (`--force-window=no`, the window is rebuilt after each stop), auto-safe | 259 (24 to 603) | 401 (138 to 452) | 56 (30 to 490) |
| same, `--hwdec=no` | 281 (27 to 571) | 445 (69 to 479) | 496 (23 to 554) |
| one mpv per video, from process start, auto-safe | 711 (586 to 826) | 661 (600 to 726) | 578 (512 to 835) |
| same, `--hwdec=no` | 543 (490 to 871) | 588 (541 to 633) | 548 (507 to 710) |

Opening mpv's pipe after the process starts: median 33 to 44 ms, worst 113 ms. The very first video in a freshly
started mpv took about 0.5 s (516 ms here; 528 ms through the page's own Play button in the binding run). Without a
kept window the times split in two groups (about 25 to 60 or about 400 to 600 ms), depending on whether the old
window was already gone. **The kept mpv with its window kept is the fast one: 27 to 42 ms medians, against 0.5 to
0.7 s for one process per video.** Hardware decoding does not make starts faster for these 720p clips; what it saves
in processor load was not measured. A file from the NAS was not tried (no session opens real media).

Job object: the program put itself into a job with kill-on-close at start, so mpv (and the WebView2's processes)
inherit it when they start, with no gap. Killing the program (`TerminateProcess`, not a clean exit) ended mpv 3
times of 3, after 9 to 13 ms. After every run: 0 `mpv`, 0 spike processes, 0 WebView2 processes with the spike's
folder in their command line.

## The binding for the build: `github.com/jchv/go-webview2` at `v0.0.0-20260205173254-56598839c808`, its `pkg/edge` only

Why: it is pure Go and answered everything; it adds 0.5 MB and ships the loader DLL inside; its `pkg/edge` lets the
app own the window and the message loop. The missing pieces (refusing navigation and new windows, posting JSON,
and for the build ProcessFailed) are three or four vtable calls and two handler objects, about 100 lines in one
file, all read from the binding's own vtable list. Writing the whole COM layer ourselves would still need the
loader DLL from somewhere and buys nothing measured. The Wails fork was not needed. For `go.mod` (the
integrator's): `require github.com/jchv/go-webview2 v0.0.0-20260205173254-56598839c808`, which adds
`github.com/jchv/go-winloader v0.0.0-20250406163304-c1995be93bd1`; its `golang.org/x/sys` of 2021 is older than
the one the app already requires, so the app's own version wins (not built inside the app's module: that is the
integrator's step).

## What the build's brief must say that the plan could not know

1. **`pkg/edge`, not the binding's window.** Our own window class and loop; `main()` is the UI thread (the binding's
   `init` locks it and starts COM). Anything from another goroutine goes to the UI thread by a message posted to
   **the window** (thread messages are lost while Windows runs a modal loop, such as a drag of the border).
2. **One small COM file** for NavigationStarting (cancel anything outside our loopback address), NewWindowRequested
   (handled, no window), PostWebMessageAsJSON, and ProcessFailed (not tried: what to do when the WebView2 process
   dies). Slots as above; the handler objects live in package variables; every wrapper that passes pointers as
   `uintptr` needs `//go:uintptrescapes` (without it one measurement in the spike read a stale stack address).
3. **Messages:** the page posts strings and ignores string messages (the binding's echo); Go posts JSON objects.
4. **DPI:** `SetProcessDpiAwarenessContext(PER_MONITOR_AWARE_V2)` before the first window; the page reports the
   frame in device pixels; `WM_DPICHANGED` takes the suggested rectangle. Mixed scaling is untested on this PC.
5. **Placement:** the page reports the rectangle on resize, scroll, a ResizeObserver and a change of resolution;
   the shell moves its child with `SWP_NOZORDER` and raises it once when a video starts. No timer, no re-raising.
   WebView2 settings off: dev tools, context menus, status bar, zoom (zoom would break the pixel mapping), pinch,
   swipe.
6. **mpv:** `--wid=<our child> --idle=yes --force-window=yes --no-config --input-ipc-server=\\.\pipe\<random>
   --window-dragging=no --terminal=no`, started once with the window and kept; our child hidden while nothing
   plays. The pipe is opened with `FILE_FLAG_OVERLAPPED` and `os.NewFile` so that reading events and writing
   commands run at the same time (the manual says plain file I/O cannot); `request_id` matches replies.
7. **Input:** mpv's window is disabled by mpv: the mouse over the video goes to our child window and the keys stay
   with the page. Keys need no forwarding. For mpv's own on-screen controller to answer the mouse the shell either
   enables mpv's window (a real click then reached mpv and the focus stayed with the page) or forwards from its
   child with the IPC command `mouse`. Which one, and how the controller then looks and behaves, the build
   decides; it was not looked at.
8. **Lifetime:** put the program itself into a kill-on-close job object at start (children inherit it; 3 of 3
   killed runs left no mpv).
9. **Start:** about 0.5 s for the first video after mpv starts, 25 to 45 ms after that: start mpv when the window
   opens; "Opening..." from the first moment stays the rule. MPEG-4 Part 2 decodes in software (`auto-safe`).
10. **WebView2 missing or failing:** the binding exits the program; check first and fall back to the browser.
11. **Timing in tests:** Go's clock moved in steps of about 1 ms in the first runs; sub-millisecond timings in the
    spike use the performance counter.

## Not tried, and why

- A move between monitors of different scaling: both monitors are at 100%, and changing that is a system setting.
- A resize by dragging the border with the mouse (the modal sizing loop), another window dragged across ours, and
  any flicker or wrong order for a moment: "not looked at" (no desktop look was asked for); the drag-like series of
  programmatic sizes stands in for the first.
- The page's own full screen (`requestFullscreen` inside the WebView2): only the window's full screen was tried.
- The fallback window (`-fallback`): built, not run, as the child window did not fail.
- The Wails fork: not needed.
- mpv's on-screen controller with the mouse, and how the video looks: not looked at.
- Processor and graphics load while decoding, and which graphics adapter d3d11va used.
- A file from the NAS (rule: no real media); `tgarchive fabricate` clips (only the three ffmpeg clips were used).
- What happens when the WebView2's process crashes (ProcessFailed) or the runtime is missing.
- The program by hand (`go run . -mpv DIR -clips DIR` opens the window with the three buttons); only the
  `-measure` modes ran, and the page's Play and Stop buttons were clicked from a script.

To repeat: in `archiver/spikes/window`, `go build -o window.exe .`, then `window.exe -mpv <mpv folder> -clips
<clips folder> -measure nav|place|keys|start|job` (`keys -clicks` makes two real clicks; `-enablempv` enables mpv's
window first; `-mpvlog` writes mpv's log into the spike's temporary folder).
