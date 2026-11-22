# Review B4: the native window with mpv (`wip/b-window`, d59160a against d4269cc), 2026-11-15

Independent, read-only review. Everything new was read (`git diff d4269cc..d59160a`): `internal/window` (every file,
the self-check skimmed for what also runs outside it), `cmd/tgarchive-window`, the viewer's `play.go`, `stats.go`,
`viewer.go`, `play.js`, `item.js`, and the binding's `pkg/edge/chromium.go`, `corewebview2.go` init and
`webviewloader/module.go` in the module cache. Nothing in the worktree or the project was changed (`git status`
clean after every probe).

What ran for real (all in my scratch folder under `%TEMP%`, invented files only):
- Five probe tests loaded with `go test -overlay` into `internal/window`, run by name, `-p 1`, `GOMAXPROCS=2 GOGC=50`
  (R1 to R6 below).
- mpv 0.42 headless (`--vo=null --ao=null`, the author's option set from `mpvargs.go`, `-v` log) on 19 files made with
  ffmpeg 7.1.1 and by writing bytes, with a local listener counting connections; the same crafted-reference files
  again under mpv's defaults as a control; `mpv.com --list-options`.
- One real mpv started by a probe through the package's own `connectedPipe` and `mpvArgs` (no `--wid`, `vo=null`).
- Not run: the program's `-selfcheck` (see "Not checked").

Severity words: **A** = a page or a file can make the program do something it must not; **B** = wrong result or a
hang for the owner; **C** = cosmetic or needs an unlikely precondition.

## Findings, most severe first

### F1. A, PLAUSIBLE: downloads are not refused: a page script can write a file of its choosing into the owner's Downloads folder
- Where: `internal/window/webview_windows.go:170-204` (no `DownloadStarting` handler; the WebView2's own default
  applies), with the page features `item.js:184`, `item.js:509`, `play.js:180` (links with `download`).
- Input: a script in our page (the brief's premise) does
  `a=document.createElement('a'); a.href=URL.createObjectURL(new Blob([bytes])); a.download='x.pdf.exe'; a.click()`
  (or a `data:` href). An anchor download is not a navigation, so `NavigationStarting` (which would refuse `blob:` and
  `data:`) is never asked; the page CSP (`server.go:23`) does not govern downloads. The WebView2's default is to save
  into the user's Downloads folder without a question and to show its download flyout, which offers "Open file".
  The global "deny" permission only stops the second and later automatic downloads of a page, not the first.
  The same default also saves the viewer's own "Download the file"/"Save the file" answers (attachment,
  `media.go:967-973`) straight into Downloads under the sender's (cleaned) name; that may be wanted, but it is now a
  silent write by the window, not the browser's.
- Smallest fix I would accept: add `DownloadStarting` (ICoreWebView2_4; take the slot and the args' `put_Cancel`
  from WebView2.h, as was done for the others, or QueryInterface for IID_ICoreWebView2_4) and cancel every download
  whose URI `origin.allows` refuses (this cancels `blob:`, `data:`, `filesystem:`); count it. Better still, cancel all
  and let the pages' download links say "use Open in the player / the browser" in the window. A unit test cannot
  reach it; a self-check step that clicks a `blob:` download and counts files in a temporary download folder can.
- Not confirmed: I had no rule-abiding way to run a script in the window (the self-check's `execScript` is the only
  door and its run was not taken).

### F2. B, CONFIRMED (mechanism): the kill-on-close job also kills every program the viewer starts to outlive it
- Where: `internal/window/instance_windows.go:69-83` (job with only `KILL_ON_JOB_CLOSE`, no `BREAKAWAY_OK`),
  `internal/viewer/launch.go:32-41` and `launch_windows.go:11-26` ("Open in the player": `DETACHED_PROCESS |
  CREATE_NEW_PROCESS_GROUP`, documented as "does not end with it"), `internal/window/procs_windows.go:151-165`
  (the browser fallback through rundll32).
- Probe R2: a child test process joined a job made by `joinKillOnCloseJob()`, started `PING.EXE -n 30` with the
  viewer's exact `detachedFlags`, and exited. 500 ms later: **with the job, the detached program was dead; without
  it (control), alive**.
- What the owner sees: in the window, "Open in the player" opens VLC or the set player program (a child or
  grandchild of the window's process, so in the job); closing the window kills that player mid-file. In the browser
  fallback, if the default browser was not already running, the browser started by rundll32 dies with the window
  (the window's own text says "Close this window to stop it", meaning the viewer, not the browser). A default
  player that Windows activates as an app (Films & TV) is outside the job and not affected.
- Smallest fix I would accept: `JOB_OBJECT_LIMIT_BREAKAWAY_OK` on the job, and `CREATE_BREAKAWAY_FROM_JOB` on exactly
  these two launches (Windows only; the viewer's `detached()` and `openInBrowser`); then repeat the self-check's job
  test, because a breakaway-permitting job may also let Chromium's own process launcher break away (WebView2
  processes surviving a kill would be worse). Alternative without `BREAKAWAY_OK`: start the default-program open
  through `explorer.exe <file>` (handed to the running shell, outside the job) and say that a set player program
  closes with the window.

### F3. B, CONFIRMED (bridge) / PLAUSIBLE (end to end): a new document does not end the old document's play or full screen
- Where: `internal/window/bridge.go:195-196` (`hello` only answers), `shell_windows.go:349-363` (a renderer that
  died or hangs is reloaded with no word to the bridge), `webview_windows.go:116-126` (an allowed main-frame
  navigation tells the bridge nothing), `item.js:212`, `item.js:1006` (`shellFull` lives in the old document).
- Probe R1 (stand-in mpv): play shown, then `fullscreen on`, then `hello` (what any new document sends first):
  hides 0, stops sent 0, fullscreen-off 0.
- Interleavings that reach it: (a) the renderer crashes or hangs while a video plays: the shell reloads, no
  `pagehide` runs in the dead page, so no `stop`; mpv keeps playing with sound, its window stays raised over the
  reloaded page at the old rectangle until the file ends, and the new page has no control of it (its `stop`, Space,
  seeks only act on its own `current`). (b) In the window's full screen, F5/Ctrl+R (browser keys are on, F5 below)
  or a reload: `pagehide` sends `stop`, but the window stays borderless over the monitor and the new page's Escape
  does nothing (its `shellFull` is false); the owner gets out only by opening a post and pressing full screen twice.
- Smallest fix I would accept: the bridge treats `hello` as "a new document": what `stop` does, plus
  `ui.Fullscreen(false)`; and `webviewProcessFailed` calls the same before `reload()`. One unit test: play, shown,
  hello: hidden, `stop` sent, fullscreen false.

### F4. B, CONFIRMED (mechanism), rare path: the fatal guard holds Go's log lock for the rest of the run, so the viewer's own log lines hang their requests
- Where: `internal/window/shell_windows.go:531-561`. The binding calls `log.Fatalf("Creating environment/controller
  failed")`; the guard catches it inside `Write` and runs the browser fallback's whole message loop there
  (`s.loop()` at :553) so that `Fatalf` never reaches `os.Exit`.
- Probe R3: Go's `log` holds the logger's output lock while `Write` runs: with a first `Write` not returning, a
  second `log.Printf` from another goroutine was still blocked after 300 ms (released when the first returned).
- What the owner sees in that fallback: every later `log.Printf` in the process blocks forever: the viewer's own
  `viewer.go:574` ("an answer could not be written", which happens whenever a browser drops a video request, i.e. on
  every seek) and `viewer.go:586`, and net/http's own error log (`server.go:265-268` sets no `ErrorLog`, so it is the
  standard logger). Each such request's goroutine hangs; the viewer in the browser degrades request by request;
  `log.SetOutput` cannot be used to escape (it takes the same lock).
- Smallest fix I would accept: no user of the standard logger besides the binding while the window runs: the
  viewer's two `log.Printf` go through its `Logf` (the command passes `say`), and the command sets
  `ns.ErrorLog = log.New(<its own writer>, "", 0)`. (Or: in the guard, start the program again in a browser-only
  mode and exit, instead of looping inside `Write`.)

### F5. B, PLAUSIBLE, unlikely: the window cannot be closed while the binding's Embed waits
- Where: `shell_windows.go:248-254` (`close` refused while `s.embedding`), binding `chromium.go` `Embed` (a
  `GetMessage` loop until the controller callback sets `inited`, no time bound).
- Interleaving: the environment's or controller's callback never comes (a WebView2 browser process that starts
  and stalls, the user-data folder held by a process that hangs). The window shows "Opening the archive..." and its
  X does nothing; only Task Manager ends it. A callback with an error is handled (F4's guard); only "never" is not.
- Smallest fix: a timer (for example 30 s) posted to the window while embedding that runs the browser fallback, or
  let a close during embedding end the program (`PostQuitMessage` after the job's cleanup).

### F6. A (conditional), PLAUSIBLE: mpv's disc readers look at the file's name before the forced demuxer
- Where: `mpvargs.go:226-237` (`--demuxer=lavf` limits demuxers, not mpv's stream handlers), `checkPath`
  `mpvargs.go:245-262`.
- Seen: on every file, under the author's options, mpv's log shows `[ifo_dvda] Opening`, `[ifo_dvdnav] Opening`,
  `[bdmv/bluray] Opening` before `[file] Opening`. My files named `VIDEO_TS.IFO` (inside `VIDEO_TS\` with a
  `VTS_01_1.VOB` beside it) and `BDMV\index.bdmv` held MP4 bytes, so those readers declined and the file played
  through lavf. A real IFO or `index.bdmv` would make mpv open the folder as a disc and read its siblings.
- Reachable only if a library file can keep a sender's name (I did not find where the library names files; if the
  names are the app's own, this is nothing). Smallest fix: `checkPath` refuses base names ending in `.ifo`,
  `.bdmv`, `.mpls`, `.bup` (case-insensitive), or a test that pins the library's naming.

### F7. C, PLAUSIBLE: the browser's own accelerator keys are left on
- Where: `webview_windows.go:188-196`. `AreBrowserAcceleratorKeysEnabled` is not set (the binding has
  `PutAreBrowserAcceleratorKeysEnabled`). F5/Ctrl+R reload (feeds F3 b), Ctrl+P opens the print dialog (a file only if
  the owner picks "Print to PDF"), Ctrl+F find, Alt+Left/Right and the mouse's back button go through history (our
  address, allowed). Dev tools stay off (that setting is separate).
- Fix: `_ = s.PutAreBrowserAcceleratorKeysEnabled(false)` (the page's own key handlers keep working).

### F8. C, PLAUSIBLE: a `stop` can be dropped silently when mpv's command queue is full
- Where: `bridge.go:126-134` with `:215-217` (and `toMPV` :239-245). The queue holds 1024; the rate limit lets 400 a
  second in; each command waits up to 5 s for mpv. A flood of `seek`/`pause` while mpv answers slowly fills it and the
  next `stop` is dropped (not counted): the page has left, mpv keeps playing (hidden: `hide` is not queued).
  Needs a hostile page or a stalled mpv. Fix: `stop` counts a drop and, when the queue is full, empties it before
  queueing itself.

### F9. C, PLAUSIBLE: a relative `-mpv` or `MPV_PATH` is taken against the working folder
- Where: `mpvargs.go:114-124` (`filepath.Abs` on the value) against its own comment "Only a full path counts".
  `MPV_PATH=mpv` started from a Downloads folder would run `Downloads\mpv\mpv.exe`. The owner's own setting, so
  cosmetic. Fix: refuse a value that is not `filepath.IsAbs` (as `onPathByHand` already does for PATH).

### F10. C, PLAUSIBLE (not run): no cap on a decoded picture's size
- A crafted file that declares, say, 16384x16384 makes the decoder allocate about 1 GiB per frame, several queued,
  in mpv on the owner's PC. Not run (the PC's memory budget). Fix: `--vd-lavc-o=max_pixels=<for example 8192*8192>`
  in `mpvArgs`, checked against this mpv's `--h=vd-lavc-o`.

## Checked and found sound

**The page's messages (point 1).** `parsePageMsg` (`msg.go:119-175`): one object, nothing after it, no repeated key
(also after JSON unescaping), exact key set per type, numbers checked by kind and bound, ids digits only up to 2^53,
rectangles four whole numbers, 512 bytes, valid UTF-8. Probe R4 (15 edge inputs): a BOM, two objects, a repeated
`id`, id 2^53+1 are dropped; leading/trailing spaces, `-0`, `1e0`/`1.0` in a rectangle, `1e-400` are taken as
harmless numbers. Messages are taken only from a top-level document whose source `origin.allows`
(`allowed.go:32-41`: scheme http, host exactly `127.0.0.1:PORT`, no user part, no backslash or control characters);
non-strings are dropped. Nothing from a page reaches mpv as text: commands are built from fixed words, numbers and
the PathSource's path; messages to the page are built from numbers and fixed words (`whyWord`). Rectangles move a
child of our own window, so mpv's picture is clipped to our client area and cannot cover another program; full
screen is a non-topmost borderless window.

**The id to path step (point 2).** `PathOf` and `handleOpen` share `playerFile` (the diff moves the code, not a
copy); `PathOf` adds no route (the viewer's test pins that) and answers fixed words. `checkPath` refuses relative
paths, `://`, a leading `-`, control characters, U+FFFD and anything not a regular file now. The path goes to mpv
only in `loadfile` over the pipe, JSON-encoded by `encoding/json` (newlines escaped, one line); mpv's `%n%` length
prefixes and `edl://`/`memory://`/`lavf://`/`av://` only apply to option strings or need `://`. Probe R5: the
bridge's exact `loadfile <path> replace -1 {"start":"1.000"}` is accepted by this mpv (`playlist_entry_id` 1) and the
first picture came at time-pos 1.04; `keybind MBTN_LEFT "cycle pause"` answers success under
`--input-default-bindings=no`.

**mpv's command line (point 3).** All 41 options exist in this mpv's `--list-options` (`--no-config` is the
`--config` flag); `--input-ipc-server` defaults to empty; `--demuxer-lavf-propagate-opts` defaults to yes, so the
whitelists reach nested opens too. Nothing on the line names a file. Headless runs with the author's set:
- plays (end of file, 0 connections): MP4, MKV, and the nine single-file demuxers taken on trust (rm, dv, mxf, nut,
  h264, hevc, m4v, gif, ivf), each detected by libavformat; Matroska goes through libavformat, so mpv's own Matroska
  reader (the one with ordered chapters and linked segments) never runs;
- refused ("Format not on whitelist" or "Failed to recognize file format"): a PNG and a Y4M under a video's name,
  an mpv EDL under `.mkv`;
- MOV files with a non-self-contained `url ` data reference to `http://127.0.0.1:<listener>/`, to a `file:///`
  sibling and to an absolute sibling, and QuickTime reference movies (`rmra/rmda/rdrf`) to an http address and to a
  relative sibling: no connection to the listener (0 in all runs), no sibling opened, reference movies end with
  "Errors when loading file". Honest limit: mpv's defaults did not follow my crafted references either, so these
  files show no leak, not that the options are what stops one; the author's self-check covers the list formats.
- No file written: watch-later and history are off; after the spike's and the author's runs with a real video
  output, `%APPDATA%\mpv` is empty and `%LOCALAPPDATA%\mpv` does not exist (no shader cache under `--no-config`).
- The OSC draws the media title inside the window only; the window title is fixed; media keys, system media
  controls and taskbar progress are off.

**The pipe.** Probe R6: once the window's end is connected, a second client (read, or read/write) gets "All pipe
instances are busy". `FILE_FLAG_FIRST_PIPE_INSTANCE` stops a squatter; the server end is inherited by mpv only
(Go's explicit handle list) and closed in the window after `Start`. The connected end is full control of mpv (this
mpv has `run`, `subprocess`, `load-script`), so this exclusivity matters, and it holds. Left: a same-user program
that wins the microseconds between `CreateNamedPipe` and `CreateFile` makes the start fail (mpv not started, no
hijack); a same-user program can do worse anyway.

**Processes and lifetime (point 4).** Only `procs_windows.go` starts programs (the wall test), with fixed
arguments; the fallback's address is checked by `origin.allows` and rundll32 is found by the system folder's full
path. The job is created and joined first in `main`, its handle is not inheritable, and without `BREAKAWAY_OK` a
child's `CREATE_BREAKAWAY_FROM_JOB` is refused (R2 shows children die with it; see F2 for the other side). mpv,
the job child and ffmpeg get only the listed handles.

**DLL loading (point 5).** `Prepare` is the first statement of `main`; before it, only package inits run: the
binding's `init` locks the thread and calls `CoInitializeEx` through `NewLazySystemDLL` (System32 only); the
window's own `NewLazyDLL` handles load on first call, after `Prepare`. `LoadLibraryW("WebView2Loader")` then
searches System32 only and fails, so the binding loads its embedded copy from memory (`go-winloader`), whose
imports resolve through the same limited search. mpv's DLLs come from mpv's own folder (the owner's).

**WebView2 settings (point 6).** Main-frame and frame navigations outside our address are cancelled (this also
covers redirects, `file:`, external schemes such as `ms-settings:`/`mailto:` and a dropped file or link); new
windows are handled with none (`window.open` gives null; Ctrl/middle-click and `target=_blank` included); the
global permission is "deny" (the binding's per-kind bug does not matter with a global state); dev tools, context
menus, status bar, zoom, pinch, swipe and host objects are off; the user-data folder is `<data>\window-webview`.
The vtable slots used match ICoreWebView2's order (get_Source 4, add_NavigationStarting 7,
add_FrameNavigationStarting 17, add_ProcessFailed 25, ExecuteScript 29, Reload 31, PostWebMessageAsJson 32,
add_WebMessageReceived 34, CallDevToolsProtocolMethod 36, get_BrowserProcessId 37, add_NewWindowRequested 44) and
the argument objects' (put_Cancel 8, put_Handled 6, get_Source 3, TryGetWebMessageAsString 5).

**Concurrency (point 7).** Every window and WebView2 call runs on the window's thread (functions queued, a message
posted to the window, so modal loops do not lose them); the bridge decides under one lock and the UI calls only
queue. A play superseded by the next (`gen`), `stop` during resolve, during the wait for a starting mpv and between
`loadfile` and its reply, mpv dying mid-play (failed `player`, at most two restarts), and the late start-file or
reply orders are all handled; `Close` and the pipe's end finish the job, resolver and event goroutines.

**The viewer's side (point 8).** In a browser or on a phone `window.chrome.webview` is absent, so no message, no
changed control, no request; the shell's messages are taken only as objects of the four known types; the one
builder `shellSend` clamps every field; no `innerHTML` or similar in the diff; the previous/next buttons sit in the
media box's 56 px padding, outside the frame, and the "Opening..." line is inside the frame only before the first
picture, which is also when mpv's window appears.

**Tests (point 9).** No test judges a span of real time (waits are hang guards; one 20 ms sleep only lets a goroutine
reach its wait). The wall test pins the imports, the one file that starts programs and the one place that sends
`loadfile`. Guarantees with no failing test today: downloads refused (F1, none exists); a new document ending the
play and full screen (F3); `ProcessFailed` and the reload; the DLL search limit and the job (self-check only).

## Not checked
- The program's `-selfcheck`: not run, to keep a window off the owner's desktop; the probes covered what it could
  have added for this review, except running a script in the real window (F1) and the WebView2's real reaction to a
  reload in full screen (F3).
- Mixed-DPI monitors; a crafted huge-dimension or zero-duration file (F10); a real DVD or Blu-ray structure (F6);
  whether Chromium's launcher breaks away from a job that permits it (F2's fix).
- How the library names its files (F6), and `library.abs` itself (reparse points, alternate streams): shared with
  "Open in the player" and unchanged here.
- WebView2's environment variables and policies (`WEBVIEW2_ADDITIONAL_BROWSER_ARGUMENTS`, `WEBVIEW2_USER_DATA_FOLDER`,
  the per-program browser-folder policy): whoever can set them already controls the account.
- `go-winloader`'s own handling of the loader DLL (exception tables, relocations), and the race detector (not mine).
- Doubts for the main session, not findings: the page stops the video when the document is hidden
  (`play.js:340`), so minimising the window, or covering it fully if the WebView2 tracks occlusion, stops playback
  (the brief asked for "stop when the page is hidden"); the production binary carries `-selfcheck-pages`, which
  plays real saved files if pointed at a real catalogue.
