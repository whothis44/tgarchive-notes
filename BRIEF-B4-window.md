# Brief B4-4: the native window with mpv, the build (session B4, 11-15)

You are an Opus coder. Read first, in `C:\Users\trabi\Claude\Projects\Telegram`, in full: `SPIKE-native-window.md`
(what was measured today on this PC, and its section "What the build's brief must say": every point there
binds this build), then `PLAN-native-window.md` (the plan; where the spike disagrees, the spike wins). The
spike's program is on the branch `wip/b-window-spike` (`archiver/spikes/window/`): take code from it freely.

## Why (the owner, 11-15)
"Some of the videos need to be converted, and that is very slow, with the length/progress bar filling slowly,
so seeking is impossible." In a browser a video the browser cannot decode is converted while it plays. In the
window mpv plays every file as it is, from the library, with seeking. The pages stay the same pages.

## What the old app has (so nothing is reinvented)
Its viewer is a separate program under its own name that never goes through the VPN and reads the NAS
(`TRIED-BEFORE.md` 14); it converts unplayable videos while playing (12.20: 339 HEVC, 49 MPEG-4 Part 2, 25,949
of unknown codec). It has no native player. Its lessons that bind here: nothing a click depends on waits on
slow I/O without saying so; a separate program must not slow or restart anything else.

## Where, and the two stages
The copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-window`. Stage A now: `git checkout -B wip/b-window
f0e3f0c`. Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in each Bash call;
everything builds with `CGO_ENABLED=0`. Commit as you go and push to `private` as `wip/b-window`
(`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; no archive numbers).
- **Stage A (this brief, now): the shell.** A new package `archiver/internal/window` and a new command
  `archiver/cmd/tgarchive-window`; in `archiver/go.mod` exactly one new requirement,
  `github.com/jchv/go-webview2 v0.0.0-20260205173254-56598839c808` (the integrator said yes in principle,
  board message 28: pinned, pure Go; your hand-back lists the module's licence and every line `go.mod` and
  `go.sum` gained). **Nothing in `internal/viewer` or any other existing package changes in stage A.**
- **Stage B (a second message from the main session, after the viewer's two branches in flight are joined):**
  the viewer's side (one exported function for "the path of this saved file", shared with "Open in the
  player") and the page's side (`web/js/play.js`, `item.js` ask the shell). Until then the shell is built
  and tested against the interfaces below, and the window shows the pages with the browser's own video.
Hand back at the end of stage A; do not start stage B by yourself.

## Stage A: what to build
1. **The program** `tgarchive-window` (Windows; on another system it builds and says in one sentence that it
   is for Windows): the same flags as `tgarchive viewer` for the catalogue, library, data folder, thumbnail
   makers and ffmpeg (read `cmd/tgarchive/viewer.go`; no `-lan` and no `-addr`: the window listens on a free
   port of 127.0.0.1 only), plus `-mpv FILE-or-FOLDER`. It runs the viewer in its own process
   (`viewer.New`, `Listen("127.0.0.1:0")`, `HTTPServer`) and one window whose whole client area is a
   WebView2 at that address. Flag parsing shared with `cmd/tgarchive` goes into one small file both commands
   can use only if that needs no change outside the two command folders; otherwise repeat the few lines.
2. **The window** (`internal/window`, through the binding's `pkg/edge` only, as the spike): our own window
   class and loop on the main thread; per-monitor DPI awareness before the first window; the place and size
   remembered in a small JSON file of the window's own in the data folder (`window.json`), put back on a
   monitor that still exists; **one instance per data folder** (a named mutex from a hash of the folder; a
   second start brings the first window to the front and exits 0); the WebView2's user-data folder is
   `<data>\window-webview` (never shared); dev tools, context menus, status bar, zoom, pinch and swipe off;
   **navigation to anything but our own address and every new window are refused**; a WebView2 that is
   missing or fails to start is found before the binding can end the program (`GetInstalledVersion`), and
   the program then opens the same address in the default browser and says so in one line. Before any DLL
   is loaded the program limits the DLL search to system folders (`SetDefaultDllDirectories`), so a
   `WebView2Loader.dll` beside the program or in the working folder is never taken; say in the hand-back
   what the binding then loads.
3. **Lifetime:** the program puts itself into a kill-on-close job at start; closing the window stops mpv,
   closes the viewer cleanly (its `Close`, the servers' `Shutdown`) and ends; a crash or a kill leaves no
   mpv and no WebView2 process (the job). `ProcessFailed` of the WebView2: one reload, then the browser
   fallback of point 2.
4. **mpv** (one process, started when the window opens, kept with its window: the spike's 27 to 42 ms per
   start against 0.5 s): found by `-mpv`, then the environment variable `MPV_PATH`, then `mpv\mpv.exe`
   beside the program and one folder up (`bin\..\mpv`), then PATH split by hand as `internal/viewer` does for
   ffmpeg (this PC's PATH holds an entry with a stray quote that hides everything after it from
   `exec.LookPath`: board message 22; read how `findFFmpeg` does it and do the same, without importing its
   private code). Missing or not starting: the window works with the browser's own video and the pages'
   existing paths, and says once where mpv was looked for (fixed words, no path of the library).
   **Its command line is fixed** (no argument from a page, a file's name or the catalogue): `--wid`,
   `--idle=yes`, `--force-window=yes`, `--no-config`, `--input-ipc-server=\\.\pipe\<random>`, `--terminal=no`,
   `--window-dragging=no`, `--hwdec=auto-safe`, and what keeps a file's name and the world out: no media
   keys or system media controls, a fixed title, no "watch later", no screenshots to disk, no scripts but
   its own on-screen controller, no network (`--ytdl=no`), no log file. **Check every option against this
   mpv's own `--list-options` and manual, not memory, and list the final command line in the hand-back.**
5. **A crafted file must not lead mpv anywhere** (library files came from Telegram; the viewer's ffmpeg
   commands got the same care today, `REVIEW-B4-open.md` F2 and `wt-copies-review10-scratch/REVIEW.md` F1 to
   F5, read-only). mpv has demuxers of its own for playlists, EDL, cue sheets, archives and image
   sequences, each of which can name other files or addresses. Find, in this mpv's manual and by trying, the
   options that leave only real media containers read from a local file (for example forcing the lavf
   demuxer with a format and protocol whitelist), and prove it with invented hostile files next to an
   invented clip: an ffconcat text, an m3u/m3u8 list, an mpv EDL file, a cue sheet, a zip, each under a
   video's name: mpv must play nothing and open no sibling and no address (count mpv's `end-file` reasons and
   watch a local listener for a connection). Real MP4, MOV, MKV, WebM, AVI, WMV, FLV, MPEG-TS and the
   spike's three clips must still play. This runs as a `-selfcheck` mode of the program (numbers and fixed
   words only), not as a unit test.
6. **The bridge** (the message set between the page and the shell; JSON objects from Go, JSON strings from
   the page, as the spike found; the binding's echo ignored): from the page `hello`, `play {id, t, rect,
   muted}`, `pause`, `resume`, `seek {t}`, `volume {v}`, `stop`, `rect {rect}`, `fullscreen {on}`; to the page
   `shell {v, mpv: true|false}`, `state {id, pos, dur, paused}` (a few times a second while playing, from
   observed properties), `ended {id}`, `failed {id, why}` with `why` one of a fixed list of words. **`id` is a
   number and the only thing that names a file; `rect` is four numbers; every message is checked for its
   shape and bounds and anything else is dropped and counted.** The shell turns an id into a path only
   through the interface `PathOf(ctx, id int64) (string, error)` it is given (stage B hands it the
   viewer's; stage A's tests hand it a stand-in), and passes that path to mpv by `loadfile` over the pipe,
   never on a command line. A message is taken only from a document of our own address.
7. **Placement and input:** as the spike's points 5 and 7: the page's rectangle in device pixels, our child
   moved with `SWP_NOZORDER`, raised once when a video starts, hidden when nothing plays. mpv's own window
   is enabled so that its on-screen controller answers the mouse (the spike: the keys still stay with the
   page); the page's keys stay the page's. Full screen: the shell makes the window borderless over its
   monitor and back; Escape (the page's) leaves it.
8. **Its own numbers:** a counts-only `window-stats.json` in the data folder at stop and once a minute while
   something changed (plays started, ended, failed by word, ms from `play` to mpv's `playback-restart`
   median and worst, messages dropped by reason, mpv restarts, WebView2 failures). Numbers and fixed words
   only: no id, name or path.

## Tests (stage A)
- Unit tests in `internal/window` for everything that needs no window: the message checks (every shape that
  must be dropped), the bridge's state machine against a stand-in mpv (the test binary started again, speaking
  the pipe's JSON over a named pipe or an injected connection) and a stand-in `PathOf`, mpv's search order,
  the remembered place put back on a monitor that exists, the stats file's fixed words. **No test judges a
  span of real time; no test starts a real mpv or a real WebView2.** A wall test for the new package: the
  short list of what `internal/window` may import, and that only one named file starts a program.
- `-selfcheck` on this PC, run by you once at the end with the PC's load noted: the window opens on an
  invented archive (`tgarchive fabricate`, with `FFMPEG_PATH` set so its clips are real), the spike's
  placement steps and job test, point 5's hostile files, 10 starts; it closes itself. It opens a window on
  the owner's desktop for some seconds: keep it short, never leave anything running, list what is left.
- While working only named tests; at the end once: `gofmt -l`, `go vet ./internal/window ./cmd/tgarchive-window`,
  `go test ./internal/window -p 1`, and `go build ./...` for the module with `CGO_ENABLED=0`.
  The race detector is the main session's.

## Load and rules
- Two other coders are compiling. One go command at a time; `GOMAXPROCS=2 GOGC=50` for test runs; check free
  memory before a build or run and wait under 2.5 GB.
- mpv is at `C:\Users\trabi\AppData\Local\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b\mpv`
  (0.42.0). Download nothing, install nothing, change no system setting, run none of mpv's `.bat` files.
- Never open the window or mpv on real data or any real file; never read the owner's viewer folder or
  library or anything else under `tgarchive-b`; nothing against Telegram. Invented data only.
- Do not touch `repo-archiver`, other `wt-*` folders or, in stage A, any existing package; do not merge into
  or push `claude/charming-feynman-vm2xia`.
- Log lines use constant format strings and carry no path, name or id of the library.

## Hand back (stage A)
The commits (pushed); the lines `go.mod` and `go.sum` gained and the module's licence; mpv's final command
line and how each option was checked; point 5's result per hostile file and per real container; the
`-selfcheck` numbers with the PC's load; what differs from this brief and why; what the stage B message must
say (the exact interface you want from the viewer and from the page); doubts, and what a reviewer should try
to break first (what a page can make the shell do; child processes; DLL loading; crafted files).
