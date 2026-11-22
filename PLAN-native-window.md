# Plan: a native window around the viewer's pages, with mpv built in for video

Written by session B3 (viewer and bring-in), 2026-11-15, for the next session of this track to build.
**Decided by the owner, 11-15: "yes, plan the native window with mpv, but leave it to the next session to
implement."** Nothing of it is built. Roadmap row: "A native window around the same pages, with a built-in
player" (`ROADMAP.md`, viewer and bring-in).

## What the owner asked, in order
- 11-15, on a video the browser cannot play: "Open in the system player isn't a terrible option to have, or
  simply a proper library that can play the videos. Also, we're talking browser, but what if we transition
  to a native app?"
- Answered then: no script library plays HEVC or MPEG-4 Part 2 in a browser without converting; the players
  that play everything are mpv and VLC; a rewrite of the pages is not recommended, because viewing from
  phones at home (built, `-lan`) needs the pages anyway.
- 11-15: yes to a native window around the same pages with mpv built in.

## What exists today (so nothing is built twice)
- The pages: `archiver/internal/viewer` (Go server and `web/`), opened in a browser at
  `http://127.0.0.1:8798` by `b\b-viewer.cmd`. They stay as they are and stay the only pages.
- For a video the browser cannot decode: `GET /media/{id}/play` (ffmpeg converts while it plays, the old
  app's 12.20 code ported, two at once) and `POST /api/open/{id}` ("Open in the player": this PC only, the
  file's path taken from the catalogue through the library root, handed to a program as one argument, never
  through a shell; pref `player_path`, empty = Windows' default program). Both stay: the conversion is what
  a phone uses, the button is what a plain browser on this PC uses.
- On this PC (checked 11-15, counts and versions only): the WebView2 runtime is installed (157.x); **mpv is
  not installed**; VLC is installed (usable today as the "Open in the player" program).
- The old app's numbers (12.20): 339 saved HEVC videos, 49 MPEG-4 Part 2, 25,949 whose codec Telegram did
  not give. The native player's gain is exactly these, plus no conversion load and full quality.

## The shape (the main session's recommendation)
One new program, `tgarchive-window.exe` (its own name: the viewer stays off the VPN, TRIED-BEFORE 14), in
a new command folder `archiver/cmd/tgarchive-window` and a new package `archiver/internal/window`:
1. **It runs the same viewer** in its own process (`viewer.New`, the loopback listener on a free port, the
   same flags as `tgarchive viewer`), and opens one native window whose whole client area is a WebView2
   showing that address. No second copy of the pages, no file:// pages.
2. **Video goes to mpv, not to `<video>`.** mpv runs as a child process drawing into a child window of ours
   (`mpv --wid=<window handle>`), driven over its JSON IPC (a named pipe: `--input-ipc-server`). No cgo, no
   libmpv binding: a process and a pipe, the same pattern the viewer already uses for ffmpeg and the player
   (`ffmpeg.go`, `launch.go`), so the import wall grows by one more "may start a program" file and nothing
   else.
3. **A small bridge between the page and the shell.** WebView2 lets the host receive messages from the page
   (`window.chrome.webview.postMessage`) and post back. The page's video code (`web/js/play.js`, the video
   part of `item.js`) asks once whether a shell is there; if so, instead of a `<video>` it draws an empty
   frame and sends `{play: mediaId, rect, t}`; the shell resolves the id to a path exactly as `handleOpen`
   does (the catalogue, the library root, one argument), places mpv's child window over that rectangle,
   and sends back position, duration, paused, ended, error. Without a shell (a browser, a phone) the page
   behaves exactly as today.
4. **Controls.** A native child window sits above the web content (the web page cannot draw over it), so
   the video's own controls are mpv's on-screen controller, and the page keeps its controls around the
   frame (close, previous and next, the strip, the side panel). Keys while the video has focus are sent by
   mpv to the shell (`input.conf` bindings to `script-message`) and from there to the page, so the arrow
   keys, Escape and the verdict keys keep working.
5. **mpv itself** is not shipped in the repository. The window looks for it in a setting (`player_path`'s
   neighbour: `mpv_path`), then beside the program, then on PATH; missing: the window still works and video
   falls back to the browser path (`<video>`, then the converted copy), with one line in Settings saying
   where to put mpv. Installing mpv on this PC is a download the owner has allowed in general for tools;
   say what is downloaded and from where before doing it.

## Steps for the next session, in order
0. **Read first, yourself:** `CLAUDE.md`, `BOARD.md`, the end of `SESSION-B-PROGRESS.md`; TRIED-BEFORE 9, 10,
   14; LESSONS 1; `LESSONS-viewer-ix12.32.md`; `REVIEW-B3-viewer.md`, `REVIEW-B3-viewer-2.md`,
   `REVIEW-B3-lan.md` (what reviewers found in this viewer); `play.go`, `launch.go`, `access.go`,
   `web/js/play.js`, `item.js`. Cut from the main branch's head once the viewer's merge queue entries are in.
1. **A one-day spike, before any brief** (invented clips only, `tgarchive fabricate -files -videos`): a bare
   WebView2 window from Go, a child window, `mpv --wid` into it, one IPC command and one event. It answers
   the four things this plan cannot know from here:
   - which WebView2 binding for Go to use, or whether to write the small COM layer needed directly (**look
     this up; do not trust memory**: the candidates and their state must be checked against their current
     documentation, and `go.mod` is the integrator's to change);
   - whether a sibling child window stays above the WebView2 reliably when the window is resized, moved
     between monitors of different scaling, and made full screen;
   - keyboard focus: who gets the keys when the video is clicked, and whether forwarding through mpv's
     bindings is fast enough to feel direct;
   - mpv's hardware decoding of HEVC on this PC's graphics card, and its start time on a file read over the
     Wi-Fi from the NAS (the old app's lesson: nothing a click depends on may wait on slow I/O without
     saying so: show "opening…" at once).
   If the child window cannot be kept above the web content, the fallback is mpv in its own borderless
   window placed over the frame and moved with it; decide from the spike, not before.
2. **The shell** (`cmd/tgarchive-window`, `internal/window`): the window, the viewer inside it, one
   instance only (a second start brings the first to the front), the window's place remembered, a clean stop
   of the viewer and of mpv when the window closes or the process is killed (a job object on Windows, so no
   mpv is ever left running).
3. **The bridge and the player**: the message set (play, pause, seek, volume, stop, rect changed; position,
   ended, error back), the path rule shared with `handleOpen` (one function, not a copy), mpv's lifetime
   (one process kept warm and told `loadfile`, or one per video: the spike's start times decide), the
   fallback to the browser path on any failure, said in one line on the page.
4. **The page**: `play.js` and the video part of `item.js` only; everything else untouched. Previous and
   next, autoplay, "play videos when opened", the position remembered when stepping away and back, full
   screen.
5. **Tests**: the bridge and the path rule against a stand-in mpv (the test binary itself, as the play
   tests do); the page's messages by the script-reading tests; no real player in tests. Then one independent
   read-only review (child processes, the path rule, what a page can make the shell do: a page script must
   not be able to make mpv open anything but a saved file of the library by its id).
6. **The owner opens it**: a starter `b\b-window.cmd` beside `b\b-viewer.cmd`. "Done" is the owner playing
   an HEVC video in it.

## What must stay true
- The pages are the same for the browser, the window and a phone. Nothing is written twice.
- The viewer writes only its own `decisions.sqlite` and thumbnail cache; the window adds one small settings
  file of its own (the window's place, `mpv_path`).
- The library is only read. mpv is given a path inside the library root and nothing else, never a URL from
  a page, never an argument built from text a page sent.
- The privacy rules: the session never opens the window on real data; invented archives only for looking.
- Nothing against Telegram; the window has no Telegram code.
- The home-network mode is unaffected: the window uses the loopback listener only.

## What it is not
- Not a rewrite of the viewer in a native toolkit. Not a replacement for the browser viewer or for the
  phones' pages. Not a media library manager. No download path, no collector control (the app's own pages
  are another track's).

## Open points for the owner (none blocks the spike)
- mpv has to be put on this PC (it is not installed). VLC is installed and can serve "Open in the player"
  until then.
- Whether the window should become the default way to open the viewer on this PC once it works (the
  browser starter would stay).

## The spike, as planned by session B4 (11-15 15:50; nothing built, nothing downloaded yet)

### Looked up on 11-15 (not from memory; sources at the end)
- **WebView2 in its ordinary "windowed" hosting is a window of its own (an HWND)**, and Windows sends it its
  input (Microsoft's "Windowed vs. Visual hosting" page). So mpv's window beside it is ordinary Win32 sibling
  order; whether it stays on top through resize, a move between monitors and full screen is the spike's to
  show. The page warns only of DPI trouble when several programs share one WebView2 user-data folder: the
  window gets a folder of its own.
- **Go bindings without cgo** (the module is pure Go today: `modernc.org/sqlite`, no `import "C"`, and
  `golang.org/x/sys` is already required; a cgo binding would bring a C++ toolchain into every build and is
  ruled out):
  1. `github.com/jchv/go-webview2`: pure Go, MIT, last published 2026-02-05, 23 open issues; the
     `webview/webview` shape (`Navigate`, `Init`, `Eval`, `Bind`, `Dispatch`, `Window()` giving the HWND);
     loads `WebView2Loader.dll` from an embedded copy.
  2. `github.com/wailsapp/go-webview2`: the Wails project's fork of (1), MIT, v1.0.23 of 2025-11-13 with newer
     versions after it; its README says it is "not intended to be used as a standalone package"; lower-level
     packages (`pkg/edge`, `webviewloader`).
  3. Ports of `webview/webview` on `purego` (`crgimenes/glaze`, `moxcomic/go-webview`): newer, little used.
  4. A small COM layer of our own on `golang.org/x/sys/windows` (no new module, but `WebView2Loader.dll` or
     its loading logic still has to come from somewhere).
  **To try first: (1)**, because it is the smallest thing that answers the spike's questions and (2) is its
  fork if something is missing. Which one the build uses is decided from the spike and is the integrator's to
  approve (board message 28): **the spike itself adds nothing to the repository's `go.mod`.**
- **mpv on Windows:** mpv.io says every Windows build is a third party's except its own test builds, and names
  the builds by shinchiro and by zhongfly (GitHub releases) and the project's own nightly builds; an archive
  is about 34 MB (a `.7z`; 7-Zip is on this PC). With `--wid` mpv makes its own window as a child of the
  window handed to it, so the host only resizes its own window; an embedded mpv window is reported not to
  take keys and mouse by itself unless told to (`--input-vo-keyboard`, `--input-cursor`: to be read in mpv's
  own manual during the spike, not trusted from here).
- **On this PC (presence and versions only):** WebView2 runtime 157.0.4341.46; mpv absent; VLC and 7-Zip
  present; `winget` present.

### What the spike is
A throwaway program in a module of its own, never merged: `archiver/spikes/window/` with its own `go.mod`
(a nested module: the main `go.mod`, the import wall and the packages' tests do not see it), on the branch
`wip/b-window-spike` cut from f0e3f0c in a copy of its own (`wt-b-window`), pushed to `private`. One Opus coder, one day
at most, invented clips only (`tgarchive fabricate -files -videos`, plus two clips made with ffmpeg's own
test sources as HEVC and MPEG-4 Part 2, which are the kinds the browser cannot play).
It builds: a top-level window; a WebView2 filling it that shows a fixed local page with a rectangle and a
button; a child window placed over the rectangle; `mpv --wid=<that window> --input-ipc-server=<a pipe with a
random name>` started on a click; one command sent (`loadfile`, then `set pause`), one event read back
(`playback-restart`, `end-file`, `time-pos` observed); a job object so that killing the program ends mpv.

### The four questions, each with what is written down
1. **Binding:** does (1) give what the build needs: the HWND of the WebView2's host, a message from the page
   to Go and back (`Bind` or `postMessage`), a user-data folder we choose, navigation limited to our own
   loopback address, no cgo, a clean build with `CGO_ENABLED=0`? Written down: yes or no for each, the
   module's size in the build, and anything it could not do.
2. **Stays on top:** the mpv window against the web content through: a resize by dragging, maximise, a move
   to a monitor with another scaling (if the PC has one; said if not tried), full screen and back, the page
   scrolling under it, another window dragged across. Written down: for each, right or wrong, by reading the
   two windows' rectangles and order from Win32 (`GetWindowRect`, `GetWindow` order), not by eye alone.
3. **Keys:** with the video clicked, who gets the arrow keys, Space and Escape; the time from a key in mpv
   (a `script-message` binding) to the page receiving it. Written down: the median and worst of 50 keys in
   ms. Good enough is under 50 ms at the worst.
4. **Start and decoding:** from `loadfile` to `playback-restart` for the two invented clips from a local
   disk, with `--hwdec=auto-safe` and without; which decoder mpv reports (`hwdec-current`); one mpv kept warm
   against one started per video. Written down: ms for each of 10 starts. **Not in the spike: a real file
   from the NAS** (no session opens real media); the owner's first play in the built window is that
   measurement, and the page says "Opening…" from the first moment either way (brief B4-1's rule).
The fallback named above (mpv in its own borderless window moved with the frame) is tried in the same spike
only if question 2 fails.

### What comes out
`SPIKE-native-window.md` in this folder: the four answers with their numbers, the binding recommended, what
the build's brief must say that this plan could not, and a list of what was not tried. Then the build is
briefed (steps 2 to 6 above) and the board message about `go.mod` gets its concrete module and version.

### Waiting on
- **The owner's yes to two downloads** (asked 11-15, "Waiting for the owner" item 15): mpv for Windows
  (about 34 MB, from one of the builds mpv.io names; unpacked into a folder under `%LOCALAPPDATA%`, nothing
  installed system-wide, no setting changed), and the Go module `github.com/jchv/go-webview2` with what it
  requires, fetched by `go get` through the Go proxy into the spike's own module.
- Room on the PC for one more coder (measured before the start).

Sources: Microsoft Learn, "Windowed vs. Visual hosting of WebView2"; pkg.go.dev pages of
`github.com/jchv/go-webview2` and `github.com/wailsapp/go-webview2`; github.com/jchv/go-webview2;
mpv.io/installation; github.com/zhongfly/mpv-winbuild/releases.
