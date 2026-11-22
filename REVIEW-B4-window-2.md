# Review B4, second look: the fix round of `wip/b-window` (d59160a..ff81d31), 2026-11-15

Independent, read-only. Read in full: `REVIEW-B4-window.md`, `BRIEF-B4-window-fixes.md`, the two earlier briefs, the whole
diff d59160a..ff81d31 (20 files), `webview_windows.go`, `shell_windows.go`, `bridge.go`, `allowed.go`, `mpvargs.go`,
`procs_windows.go` (changed parts), `fixes_test.go`, the viewer's `launch*.go`, `play.go` (open/PathOf), `media.go`
(file route), the pages' download links, and the pinned binding's `pkg/edge` vtables and `webviewloader/module.go`.
Nothing in the worktree changed (`git status` clean, HEAD ff81d31 after every probe).

What ran for real (scratch folder `%TEMP%\rv-b4w2`, invented files only):
- mpv 0.42 headless (`mpv.com`, `--vo=null --ao=null`, the author's whole option set from `mpvargs.go` minus the
  window/pipe ones, `--msg-level=all=debug`) on files made with ffmpeg 7.1.1 and by writing bytes: H.264, HEVC, MJPEG,
  MPEG-4 clips; an 8448x8192 H.264 frame; `VIDEO_TS\VIDEO_TS.IFO`, `AUDIO_TS\AUDIO_TS.IFO`, `BDMV\MovieObject.bdmv`,
  `BDMV\index.bdmv` with their magic bytes; MP4 bytes under `.mpls`/`.VOB` names. A Go pipe client sent `stop` to mpv.
- The program built into scratch; its job-child mode (`-selfcheck-jobchild`: hidden window, no desktop window) run
  once under a probe that lists its descendants, kills it and counts survivors. The full `-selfcheck` was NOT run.
- The round's nine new tests by name (`-p 1`, pass), and one probe test via `-overlay`.
- WebView2 slots and ids checked against the binding's source and against webview2-sys (generated from WebView2.idl):
  https://docs.rs/webview2-sys/latest/src/webview2_sys/lib.rs.html and Microsoft's ICoreWebView2_4 /
  ICoreWebView2Settings3 pages.

Severity: **A** = a page or a file can make the program do something it must not; **B** = wrong result, crash or hang
for the owner; **C** = cosmetic or needs an unlikely precondition.

## F1 to F10

- **F1 downloads: gone.** `DownloadStarting` is added on ICoreWebView2_4 (QI with the right id), cancels everything
  `allowsDownload` refuses (blob:, data:, filesystem:, other paths, other origins, `%`-encoded paths, ids with
  leading zeros or over 16 digits), and fails closed when the URI cannot be read. Slots verified (below). By reading:
  the only bytes that can be saved are the file route's, under the name the route's `Content-Disposition` gives
  (`cleanName` of the stored name), which Chromium prefers over a `download` attribute; the route never redirects;
  a service worker cannot be registered (no same-origin URL serves script but the app's own); frames are covered
  (the event is per WebView). What stays: see N2 (the flyout's "Open") and N7 (fail-open without ICoreWebView2_4).
  Not run end to end by me.
- **F2 job kills what must outlive it: gone. CONFIRMED** by my run of the job child: before the kill 9 descendants
  (mpv 1, msedgewebview2 6, conhost 1, PING 1); 3 s after TerminateProcess of the child, 1 alive: PING (started with
  breakaway). mpv and every WebView2 process died with the job although it now allows breakaway. Limit: the child's
  WebView2 never navigates, so processes Chromium starts later (page renderer, audio/media utilities) were not in
  the count. The retry logic matches Microsoft's nested-job rule (breakaway from an immediate job that allows it
  goes up to the first job that does not, without error; only a non-allowing immediate job gives access denied).
- **F3 a new document: gone** (hello, NavigationStarting of an allowed URL, ProcessFailed of a renderer or the
  browser all call `NewDocument`: gen++, cur/want cleared, child hidden, stop queued never dropped, full screen off).
  `TestNewDocumentEndsOldPlay` covers the bridge. Residue: N5.
- **F4 the log lock: gone.** No writer on the standard logger (test pins `log.SetOutput` and the binding's
  fatal paths `Embed`, `Eval`, `AddWebResourceRequestedFilter`, `NewChromium` absent); the binding's remaining
  `log.Fatal` calls are only in those functions.
- **F5 close while embedding: gone.** `close` cancels the start and destroys the window; a late environment or
  controller is closed (`cancelled`); an error result or no controller in 30 s falls back once (`fellBack` guard);
  the timer's dispatch after close posts to a dead window and does nothing. Test gap: N9.
- **F6 disc readers: gone, twice.** By the debug log, this mpv's readers match exact base names only:
  `ifo_dvdnav` on `video_ts.ifo` (magic DVDVIDEO-VMG), `ifo_dvda` on `audio_ts.ifo` (DVDAUDIO-AMG),
  `bdmv/bluray` on `MovieObject.bdmv` (MOBJ). `discFile` refuses every `.ifo`/`.bdmv` (a superset), and mpv's own
  comparison is on the same string, so 8.3 names, trailing dots or `::$DATA` suffixes match neither. New fact
  (CONFIRMED): with mpv's defaults my three crafted files get "detected. Redirecting to dvd:// / dvda:// /
  bluray://"; adding only `--access-references=no` (already on the fixed line since stage B and pinned by
  `mpvargs_test.go`) gives 0 redirects for all three. So the option the brief asked for exists and is already
  there; the self-check does not count it, and the brief's DVD/BDMV trees in the self-check were not added (N9).
- **F7 browser keys: gone.** Set before the first navigation. Microsoft's page: off are find, print, reload, zoom,
  DevTools, back/forward/search keys; Home/End/PageUp/Down, Ctrl+X/C/V/A/Z stay; page key events still fire. The
  mouse's back button is not a key and may still go back (to our own address: a new document, handled).
  Caveat N6.
- **F8 a dropped stop: gone** (`queueStop` drains and goes first; drops counted). Residue N4.
- **F9 relative mpv path: gone** (`-mpv`/`MPV_PATH` must be `filepath.IsAbs` after quote stripping; `mpvAt` no longer
  calls `Abs`; one fixed line; test).
- **F10 the picture cap: the cap works, and it makes a new hang: see N1.** `max_pixels=67108864` is honoured by
  this mpv's lavc decoders (MJPEG, MPEG-4 part 2 and software H.264 fail with "exceeds specified max pixel count"
  and the file ends with an error). The demuxer bounds (`150MiB`/`50MiB`, cache auto, no disk cache) are this
  mpv's defaults, now explicit; all new options are known to this mpv.

## New findings, most severe first

### N1. B, CONFIRMED: a video whose declared size is over the cap makes mpv spin forever and stop answering; the window's player is dead for the rest of the session
- Where: `mpvargs.go:210` (`--hwdec=auto-safe`) with `:256` (`max_pixels`); `bridge.go` has no first-picture or
  unanswered-command recovery; `ipc.go:37` (5 s per command).
- Input: an H.264 file of one 8448x8192 frame (204 KB, made by ffmpeg), played with the author's whole option set:
  mpv tries hwdec `d3d11va-copy`, `dxva2-copy`, `nvdec-copy`, then software; each open fails on the cap, and mpv
  loops "Attempting next decoding method" for ever: 77,976 attempts in 12 s, killed by my timeout (exit 124),
  never "Errors when loading file". HEVC does the same (shown with a lowered cap on a 320x240 clip: 62,346
  attempts in 8 s). Control: the same file with `--hwdec=no` (or a hwdec that cannot make a device) fails
  cleanly at once (exit 2); MJPEG and MPEG-4 part 2 are not on the hwdec list and fail cleanly.
- While it spins, mpv does not answer IPC: my `{"command":["stop"]}` on its pipe got no reply in 8 s.
- What the owner sees: `loadfile` is accepted, no picture comes; after 30 s the page's own timer hands the video to
  the browser's player; the bridge's `stop` and every later command wait 5 s each and fail, so every later video
  in the window fails "open" after 15-20 s and goes to the page; the supervisor never restarts mpv (it is alive);
  one CPU core stays busy until the window is closed (then `quit` times out and mpv is killed). A file a sender
  chose can do this. Without the cap the same file would just decode at about 100 MB a frame.
- Not checked: the same with a real video output (`d3d11va` non-copy is tried there); VP9/AV1 (no encoder here).
- Smallest fix I would accept: when a command to mpv gets no reply within `ipcTimeout` (or no `playback-restart`
  within, say, 20 s of a `loadfile` that was accepted), the shell kills that mpv, the play fails with a why word,
  and the supervisor starts a new one (such a kill not counted against the three-restart limit, or that limit
  per file); plus a self-check case with this 8448x8192 H.264 file. Keeping `--hwdec=auto-safe` and dropping the
  cap is the other way out; `--hwdec=no` alone costs CPU on every large video.

### N2. B, PLAUSIBLE: what the owner opens from the WebView2's download flyout runs inside the kill-on-close job and dies with the window; and it can be an archived program
- Where: `webview_windows.go:336-352` (an allowed download keeps the default UI: saved to the owner's Downloads
  folder, the flyout with "Open file"), `instance_windows.go` (job), `media.go:967-973` (attachment under
  `cleanName(name)`: the sender's name, extension kept).
- The flyout's "Open" is a ShellExecute in the WebView2 browser process, which is in the job (my run: all six
  msedgewebview2 processes are its members); a desktop program it starts (a PDF reader, an archiver) is in the job
  too and is killed when the window closes. The same "Open" runs whatever the saved name's extension says, e.g.
  a sender's `.exe` or `.bat`; a download from 127.0.0.1 is not Internet-zone, so Windows' downloaded-file warning
  may not appear (not checked). The plain browser viewer has the same "Open"; only the job is new.
- Smallest fix: on an allowed download, `put_Handled(TRUE)` (no flyout, no "Open" from the window) and let the page
  say where the file went; or document it. Optional: the route answers `download=1` for names with a program
  extension with a neutral suffix.

### N3. A only with a script in the page; pre-existing, not changed by this round: the page chooses the player program
- Where: `server.go:126` `POST /api/prefs` (`PlayerPath`, any existing full-path `.exe`, `play.go:391-407`) then
  `POST /api/open/{id}` (`play.go:409-466`). Both are `classLocal` and reachable by the window's own document.
- A script running in our page could set `PlayerPath` to a system script host (for example `mshta.exe`) and open a
  saved "video" whose bytes are crafted for it; with this round the start also breaks away from the job. The page's
  CSP (`script-src 'self'`) makes the premise hard; the window only adds the breakaway.
- Smallest fix: `playerProgram` refuses programs under the Windows folder (`%SystemRoot%`, by the system folder's
  real path, case-insensitive).

### N4. C, CONFIRMED (probe): a stop that drains a full queue also drops the setup job of a newly attached mpv
- Where: `bridge.go:140-162` with `:468-481`.
- Probe `TestProbeRV2StopDrainsAttachSetup` (overlay): worker blocked, `Attach` queues its setup, queue filled,
  `hello`: afterwards `observe_property` sent 0, `keybind` sent 0, `stop` 1. That mpv then never reports time,
  duration or pause to the page and the click on the picture does nothing, until mpv restarts. Needs a full queue
  at the moment of an attach (a flood or a stalled mpv, e.g. N1).
- Fix: the drain keeps jobs marked as setup (tag them), or `Attach` runs its setup before publishing `b.conn`.

### N5. C, PLAUSIBLE: "a new document" is taken at NavigationStarting, before anything is committed
- Where: `webview_windows.go:251-265`. A navigation that is later cancelled, fails, or turns into a download (a
  top-level navigation to an attachment) ends the play and the full screen while the old document stays and
  still believes it plays. No page link does this today (all download links have `download`), so only a script.
- Fix: end the old play on a committed new document (ContentLoading or NavigationCompleted with success); the
  page's `hello` and ProcessFailed already cover the rest.

### N6. C, PLAUSIBLE: the WebView2 settings fail open, silently
- Where: `webview_windows.go:365-376`. The binding's `GetSettings` judges success by the thread's last error
  (`comproc_go18.go`: `syscall.SyscallN`'s errno), not by the HRESULT. If `get_Settings` returns S_OK but leaves a
  last error, every setting is skipped (DevTools, accelerator keys, context menus, host objects) with no line.
- Fix: call `get_Settings` (slot 3) with `comCall`, check the HRESULT, Release the settings after, and say one
  fixed line when it fails.

### N7. C, PLAUSIBLE: no ICoreWebView2_4, no download control
- Where: `webview_windows.go:388-393`, `shell_windows.go:333-335`: only a log line; downloads keep the defaults
  (F1 as before). Every runtime since 1.0.902 (2021) has the interface. Fix: treat it like a WebView2 failure
  (browser fallback).

### N8. C, PLAUSIBLE: COM details
- `webview_windows.go:135`: `QueryInterface` answers every interface id with the handler itself (should be
  IUnknown and the handler's own id; otherwise `*ppv = NULL`, E_NOINTERFACE). A runtime that asked for, say,
  IAgileObject or IMarshal would be told yes and could call slot 3 (`Invoke`) with other arguments or from another
  thread (the handlers assume the UI thread). Not seen; the binding's own handlers are no better.
- `webview_windows.go:292`: `put_Handled` of NewWindowRequested takes a BOOL by value; a pointer is passed (non-zero,
  so TRUE). Pass 1, as `put_Cancel` does.
- `get_Settings`' reference is never released (one leak).

### N9. C: guarantees of the fix round with no test that would fail
- F10/N1: no file over the cap in tests or the self-check (the brief asked for one refused and one played);
  `TestMPVArgsBounds` only finds the strings.
- F6: the brief's DVD/BDMV trees and the log count of disc readers are not in the self-check (`grep` finds no
  disc case in `selfcheck_windows.go`); the names test exists.
- F5: `TestEmbedTimeout` tests a comparison; the `AfterFunc` wiring, the `embedding` guard, close during the embed
  and a late controller are untested (removing the timer fails nothing).
- F2: `JOB_OBJECT_LIMIT_BREAKAWAY_OK` on the job and the use of `startOutliving` in `openInBrowser` have no unit
  test (self-check only; my run confirms the behaviour).
- F1: the handler's wiring (slots, cancel, fail-closed on a missing URI) is self-check only.
- No new test judges real time or starts a real mpv or WebView2 (`waitUntil` and a 500 ms settle in my probe only).

### N10. C: the plain browser viewer changes in one case
- `internal/viewer/launch.go:38-58`: when `tgarchive viewer` itself runs inside a job that allows breakaway, the
  player now leaves that job (before, it stayed). In a job that does not allow it, the retry gives the old
  behaviour. Probably wanted; worth one line in the changelog.

## Checked and found sound

**Hand-written COM.** ICoreWebView2 slots against the binding's `iCoreWebView2Vtbl`: get_Settings 3, Navigate 5,
add_NavigationStarting 7, add_NavigationCompleted 15, add_FrameNavigationStarting 17, add_PermissionRequested 23,
add_ProcessFailed 25, ExecuteScript 29, Reload 31, PostWebMessageAsJson 32, add_WebMessageReceived 34,
CallDevToolsProtocolMethod 36, get_BrowserProcessId 37, add_NewWindowRequested 44; the last own slot is 60.
ICoreWebView2_2 has 7 (61-67) and _3 has 5 (68-72) in both the binding and webview2-sys, so _4's add_FrameCreated is
73, remove 74, **add_DownloadStarting 75** (verified). IID_ICoreWebView2_4 `20d02d59-6df2-42dc-bd06-f98a694b1302`
(verified in webview2-sys). DownloadStartingEventArgs: get_DownloadOperation 3, get_Cancel 4, **put_Cancel 5**,
get_ResultFilePath 6, **put_ResultFilePath 7**, get_Handled 8, **put_Handled 9** (verified). DownloadOperation:
three add/remove pairs 3-8, **get_Uri 9** (verified). Environment CreateCoreWebView2Controller 3; Controller
put_IsVisible 4, put_Bounds 6, MoveFocus 12, NotifyParentWindowPositionChanged 23, Close 24, get_CoreWebView2 25
(binding). Navigation args get_Uri 3, put_Cancel 8; WebMessage args get_Source 3, TryGetWebMessageAsString 5;
Permission args put_State 7; ProcessFailed args get_ProcessFailedKind 3; NewWindow args put_Handled 6 (verified).
Handler objects live in package variables (never collected, Go's heap does not move); AddRef/Release constant;
Invoke signatures have the right arity; HRESULTs read as `int32`; every wrapper that passes Go pointers as uintptr
(`comCall`, `call`, `callErr`) carries `//go:uintptrescapes` (variadic arguments included); strings from COM are
freed with CoTaskMemFree; `get_DownloadOperation`'s reference released; the environment, controller and view
AddRef'd once and kept; QI's extra reference on _4 released; all events and both completed handlers run on the UI
thread (the STA's loop). Completed handler with an error: fallback once; never: 30 s fallback; late after a close or
a fallback: closed. A synchronous error callback inside `CreateCoreWebView2EnvironmentWithOptions` only doubles a
count and a log line (fallback guarded).

**Downloads (point 2).** As under F1. `allowsDownload` also refuses `//` paths, trailing segments, other schemes,
`localhost`; Go lower-cases the scheme. Whether `get_Uri` is the first or the final URL of a redirect does not
matter: the file route does not redirect, and a final URL off the route is refused. A second automatic download in
one document is stopped by the global "deny" before the handler.

**Breakaway (point 3).** Exactly two production starts ask for it: `openInBrowser` (rundll32 by the system folder,
our checked address) and the viewer's `startDetached` (player program or rundll32 for the default program, with a
media extension). The retry is only on ERROR_ACCESS_DENIED, unwrapped through `os.PathError`. `SILENT_BREAKAWAY_OK`
is not set, so a child of mpv or Chromium leaves only if it asks itself; my run shows none did. mpv starts nothing
(no scripts but the OSC, `run`/`subprocess` only over our pipe).

**Points 4 and 7.** `close` during the embed, the timer, the second fallback, the window closing during the
fallback, timers and goroutines after `Close` (a dead post, a finished worker): no hang or double action found.
`internal/viewer` changes reach nothing new from the network (`/api/open` still `classLocal`, this PC and loopback
only); the help line is drawn only when the window answered (`shellPresent`) and is built with `text`.

**F6 and option set (point 5).** Above; `.iso`, `.cue`, `.mds`, device names and folders never reach mpv
(`checkPath`: full path, no `://`, regular file), and mpv's `archive://`, `dvd://`, `bd://` need `://`.

## Not checked

- The program's `-selfcheck` (a window on the owner's desktop): not run; so F1 end to end (a real blob/data
  download cancelled, the route allowed), F3's reload in full screen, F7's keys in the real page were not seen by me.
- N1 under a real video output (non-copy d3d11va), and VP9/AV1; mpv's CPU use while spinning was not measured.
- Chromium's choice between `Content-Disposition` and the `download` attribute, the zone mark on a download from
  127.0.0.1, the File System Access pickers (`showSaveFilePicker`, needs a click and the owner's choice of a file),
  and `window.print()` (still opens the print dialog): by reading or not at all.
- WebView2 processes started after a navigation (renderer, audio, media) against the breakaway job.
- Race detector, whole-package runs.
