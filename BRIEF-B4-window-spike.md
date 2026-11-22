# Brief B4-2: the native window's one-day spike (session B4, 11-15). The owner said yes to both downloads at 16:08; mpv is unpacked (see "What you may fetch")

You are an Opus coder. This is a throwaway experiment that answers four questions; nothing of it is merged.
Read first, in `C:\Users\trabi\Claude\Projects\Telegram`: `PLAN-native-window.md` in full (the plan, and its
last section, "The spike, as planned by session B4": it says what was looked up and what is to be written
down for each question).

## Where
A copy of its own, `C:\Users\trabi\Claude\Projects\Telegram\wt-b-window`, which the main session makes before
you start (`git worktree add -b wip/b-window-spike ../wt-b-window f0e3f0c`, run in `repo-archiver`;
`wt-b-faces` and `wt-b-viewer` are in use by other coders). Everything goes into one new folder, `archiver/spikes/window/`, **a module of its own** (`go mod
init tgarchive-window-spike` inside it; it imports nothing from the app and the app's `archiver/go.mod` is
not touched, not even by `go work`). Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`
in each Bash call; build with `CGO_ENABLED=0`. Commit as you go and push to `private` as
`wip/b-window-spike` (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`).

## What you may fetch (the owner's yes covers exactly these; anything else: stop and say so)
- The Go module `github.com/jchv/go-webview2` and what it requires, by `go get` inside the spike's module.
  If it cannot do what question 1 needs, say so and try `github.com/wailsapp/go-webview2` (its fork) the
  same way; no other module, no cgo.
- mpv for Windows: the main session hands you the folder it was unpacked into (`MPV_DIR` below). Do not
  download a player yourself.
Read the documentation of both as they are today (the module's own source in the module cache; `mpv
--list-options`, `mpv --input-keylist`, and the manual text `mpv --h=wid`, `--h=input-ipc-server`,
`--h=input-vo-keyboard`): do not write from memory.

## What to build
One small program (`go run .` in the spike's folder, flags `-mpv DIR -clips DIR`):
1. A top-level window with a WebView2 filling it, its user-data folder a temporary one of the spike's own,
   showing a page the program serves itself on a free 127.0.0.1 port: a heading, a rectangle of 16:9 in the
   middle of some scrolling text, and three buttons (play clip A, play clip B, stop). Navigation to any
   other address is refused.
2. A message path both ways between the page and Go (the binding's `Bind`, or `postMessage` if it has it):
   the page sends `{play, rect}` and `{rect}` when the rectangle moves or the window resizes; Go sends back
   `{pos, dur, paused, ended, key}`.
3. A child window of the top-level window placed exactly over the rectangle (device pixels: mind the
   monitor's scaling), `mpv --wid=<it> --idle=yes --input-ipc-server=\\.\pipe\<random name> --no-config`
   started once and kept, driven over the pipe: `loadfile`, `set_property pause`, `observe_property
   time-pos`, the events `playback-restart` and `end-file`. A job object so that mpv dies with the program,
   also when the program is killed.
4. Keys: with the video clicked, arrow keys, Space and Escape reach the page through mpv (an `input.conf`
   given on the command line that binds them to `script-message`, read from the pipe); the program stamps
   the time when mpv reports the key and when the page acknowledges it.
5. A `-measure` flag that runs the measurements below by itself and prints one table (numbers and fixed
   words only), so that nobody has to sit and click for the numbers; what can only be seen (a flicker, a
   wrong order for a moment) is tried by hand through the session's desktop tools only if the main session
   says so: otherwise write "not looked at".

## The clips (invented only)
Make them yourself with ffmpeg's test sources, 20 s each, with a tone: A as HEVC in MP4 (`-f lavfi -i
testsrc2=size=1280x720:rate=30 -f lavfi -i sine -c:v libx265`, or `hevc_nvenc` if libx265 is missing), B as
MPEG-4 Part 2 in AVI (`-c:v mpeg4`), C as H.264 with its index at the end (no `+faststart`). ffmpeg: the
one `FFMPEG_PATH` names, else say it is missing. Never any real file.

## The four questions: write the answer and the numbers for each into `SPIKE-native-window.md` (project folder)
1. **Binding:** for the binding tried: builds with `CGO_ENABLED=0` (yes/no); gives the host window's
   handle; page-to-Go and Go-to-page messages; a user-data folder we choose; navigation limited to our
   address; added size of the program in MB; what it could not do.
2. **Stays on top:** after each of: a resize in steps (10 sizes), maximise and restore, full screen and
   back, the page scrolled, the top-level window moved (to a second monitor if one exists: say if none):
   read both windows' rectangles and their order from Win32 and say for each step whether mpv's window sat
   exactly over the page's rectangle and above the WebView2. Count right and wrong.
3. **Keys:** 50 keys sent to mpv's window (`PostMessage` of key messages is acceptable for the count; say
   so): ms from mpv's report to the page's acknowledgement, median and worst. Who gets the keys when the
   web content was clicked last and when the video was clicked last.
4. **Start and decoding:** for A, B and C, 10 starts each: ms from `loadfile` to `playback-restart`, with
   `--hwdec=auto-safe` and with `--hwdec=no`; what `hwdec-current` reports; the same with one mpv per video
   instead of one kept warm (ms from process start to `playback-restart`).
If question 2 fails, try the plan's fallback in the same program (mpv in its own borderless top-level
window owned by ours, moved with the rectangle) and answer 2 again for it.

## Load and rules
- One go command at a time; check free memory before a build and wait under 2.5 GB. The program opens a
  window on the owner's desktop for a few seconds per run: keep runs short, close it every time, never leave
  mpv or the program running (check with the process list at the end and say the count).
- Never open real media, the owner's viewer or library; nothing against Telegram; no other folder of the
  project touched; no system setting changed; nothing installed.
- Do not push anywhere but `private` `wip/b-window-spike`.

## Hand back
`SPIKE-native-window.md` written (the four answers with numbers, the binding you would use for the build
and why, what the build's brief must say that the plan could not know, what was not tried); the commit on
`wip/b-window-spike`; a ten-line summary as your final message.
