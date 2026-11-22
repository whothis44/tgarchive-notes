# Brief: an independent, read-only review of `wip/b-window` (the native window with mpv) (session B4, 11-15)

You are an independent reviewer. You did not write this code and you are not told what its author or the
main session think of it: read the code and try to break it. This is a security-minded review: the program
shows pages in an embedded browser, starts a media player as a child process and hands it files that came
from Telegram.

## What to review
The branch `wip/b-window` in the git worktree `C:\Users\trabi\Claude\Projects\Telegram\wt-b-window`, against
the main branch's head it was joined with (the main session gives the two commits in its message). New:
`archiver/internal/window`, `archiver/cmd/tgarchive-window`, one requirement in `archiver/go.mod`
(`github.com/jchv/go-webview2`, which brings `github.com/jchv/go-winloader`). Changed in
`archiver/internal/viewer`: an exported `PathOf` shared with "Open in the player", and the page scripts
`web/js/play.js` and `item.js`. What it was asked to do: `BRIEF-B4-window.md` and `BRIEF-B4-window-stageB.md`
in `C:\Users\trabi\Claude\Projects\Telegram`, after `SPIKE-native-window.md` (what was measured). Read them
for the guarantees they name, then judge the code.

## Where to look hardest (each finding: file and line, the input or the interleaving, what goes wrong)
1. **What a page can make the shell do.** The pages are the app's own, but a saved file's caption or name is
   text a stranger wrote, and a page script bug is possible: assume a hostile script runs in our page. Can
   it make mpv open anything but a saved video or audio file of the library by its numeric id (a path, a
   URL, an option, a second file, a playlist); make the shell run a program, navigate, open a window, read
   or write a file, change a setting; flood or hang the shell; move mpv's window over something else on
   screen or keep it showing after the page left? Read `msg.go`, `bridge.go`, `allowed.go`,
   `webview_windows.go`, `shell_windows.go`: every message field from parse to use.
2. **The id to path step** (`viewer.PathOf`, the bridge's `checkPath`, `loadfile`): one rule with "Open in the
   player"; nothing outside the library root; a file that is not a regular file; a path with characters
   mpv's command or its EDL/URL-looking prefixes could misread (`edl://`, `memory://`, `lavf://`, `av://`,
   a leading `-`, `%n%` length prefixes); how the path is quoted in the pipe's JSON.
3. **mpv itself** (`mpvargs.go`, `procs_windows.go`, `ipc.go`): the fixed command line, option by option,
   against this mpv's own `--list-options` and manual (`C:\Users\trabi\AppData\Local\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b\mpv`,
   read-only: run only `mpv.com --list-options` and `--h=<option>`; none of its `.bat` files): anything left
   on that reaches the network, writes a file (screenshots, watch-later, logs, caches), reads a config or a
   script from a folder a file's neighbour could plant (a `portable_config` folder, scripts beside the
   played file), shows a file's name outside the window (title, media controls, taskbar), or lets a key or
   mouse binding run a command. **Crafted files:** the author's self-check covers nine kinds; try what it
   did not: a Matroska file with ordered chapters or an external segment, a MOV with an external data
   reference, an MP4 with a `file:`/`http:` reference atom, an image sequence pattern, subtitles or fonts
   pulled from beside the file, a huge-dimension or zero-duration file, the nine single-file demuxers taken
   on trust (`rm,dv,mxf,nut,h264,hevc,m4v,gif,ivf`). Make every such file yourself in a scratch folder with
   ffmpeg's test sources or by writing bytes; run mpv headless on them (`--vo=null --ao=null`, the author's
   option set copied from `mpvargs.go`), next to a clip and with a local listener counting connections.
   **The pipe:** who can connect to it, and what a connected program can make mpv do; whether the author's
   answer on an already connected pipe holds.
4. **Processes and lifetime:** only the named file starts a program; mpv and the WebView2 processes always
   die with the program (the job object: before the first child, inherited, not escapable by
   `CREATE_BREAKAWAY_FROM_JOB`); the browser fallback opens only our own address through a system program
   found by its full path; no handle or pipe is inherited by a child that should not have it.
5. **DLL and file loading at start:** what the program loads before `SetDefaultDllDirectories` takes effect
   (package init order: the binding's `init` runs first); whether a DLL planted beside the program, in the
   working folder or on PATH can be taken by the program, by the WebView2 loader, or by mpv (mpv's own
   folder is the owner's); the WebView2 user-data folder's place and whether anything else shares it; the
   in-memory loader's source of the loader DLL.
6. **The WebView2 settings:** navigation and new windows refused in every way a page has (links,
   `location`, forms, `window.open`, frames, downloads, `file:` and custom schemes, drag and drop of a file
   or a link onto the window, the context menu, keyboard shortcuts that open things: Ctrl+O, Ctrl+N, Ctrl+P,
   F12, Ctrl+Shift+I, Ctrl+U, Alt+Left); permissions denied; what a download or a print can write.
7. **Concurrency** (`bridge.go`, `ipc.go`, `shell_windows.go`): the UI thread rule (every window and WebView2
   call on the main thread); the bridge's lock around mpv's replies and events; a play superseded by the
   next play, stop during load, mpv dying mid-play and being restarted, the window closing while a load is
   in flight; goroutines and timers that outlive `Close`.
8. **The viewer's side:** `PathOf` adds no route and nothing a device on the home network can reach; the
   pages behave exactly as before in a plain browser and on a phone (no shell: no message, no changed
   control); the "Opening…" line and the fallback on `failed`; nothing built with `innerHTML` from data.
9. **Tests and the wall test:** what `internal/window` may import and which file may start a program; which
   named guarantee has no test that would fail if it broke; any test that judges a span of real time.

## How to work (rules)
- **Read-only: do not edit, commit or check out anything in `wt-b-window` or any other folder of the
  project.** Probes: your own `_test.go` files in a scratch folder under `%TEMP%`, loaded with
  `go test -overlay`, run by name, `-p 1`, `GOMAXPROCS=2 GOGC=50`; Go through
  `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`. One go command at a time; check
  free memory first (`powershell -NoProfile -Command
  "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`) and wait under 2.5 GB.
  No Docker, no whole-package run of `internal/viewer`, no race detector.
- You may run mpv headless on files you made, and you may build the program into your scratch folder and run
  its `-selfcheck` **once**, briefly (it opens a window on the owner's desktop for about half a minute: the
  owner is using this PC; never leave the program, mpv or a WebView2 process running: list processes after
  and kill only what you started). No other window, no desktop automation.
- Download nothing, install nothing, change no system setting. Never open a real media file, the owner's
  viewer folder or library, or anything under `tgarchive-b` but its `mpv` folder. Nothing against Telegram.
- Mark each finding **CONFIRMED** (a probe or a run shows it) or **PLAUSIBLE** (by reading), with a severity
  (a page or a file can make the program do something it must not; wrong result or hang for the owner;
  cosmetic) and the smallest fix you would accept.

## Hand back
Write the review to `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-B4-window.md` (findings most severe
first, then what you checked and found sound, then what you did not check) and give a ten-line summary as
your final message: the counts by mark and severity, and the two findings you would fix first.
