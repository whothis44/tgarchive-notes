# Brief B5-W: the window becomes the only viewer (viewer session B5, 11-15)

You are an Opus coder for the viewer track of the new archiver. Work only in the copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-b-window` (Go module in `archiver/`), on the branch
`wip/b-winlan` (already cut from 3244f0d: the main head plus the listed entry 19; clean).
Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash (Go is not on PATH).

## Why (the owner, 11-15 20:25)
"Eventually we'll only have the window. The browser should probably be deprecated." The native window
(`cmd/tgarchive-window`, `internal/window`: the same pages in a WebView2, mpv for video) is the viewer on this
PC. The browser command (`tgarchive viewer`) stays in the code, but the owner's way in is the window, so the
window must have what only the browser command has today. The pages stay web pages: the window shows them
and phones at home need them.

## What is already known (read first)
- The home-network mode: `internal/viewer/lan.go` (its head comment: the six rules every request passes),
  `access.go`, `session.go`, `password.go`, `lanfolder.go`, `cert.go`, and
  `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-B3-lan.md` **in full** (its seven findings, "Design points",
  "Checked and sound"). It was built for `tgarchive viewer -lan ADDRESS:PORT` and has never been switched on
  by the owner. "Open in the player", the preferences and the player's path are this PC's only (the access
  classes).
- The window: `cmd/tgarchive-window/main.go`, `internal/window` (`doc.go`, `run.go`, `shell_windows.go`,
  `bridge.go`, `allowed.go`), and `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-B4-window.md` and
  `REVIEW-B4-window-2.md` (what two security-minded looks found: a page script naming any program as the
  player, the picture cap hanging mpv). The window listens on a free port of 127.0.0.1 only and takes no
  `-lan` today.
- The old app's lesson for anything served to a browser: a browser opens about six connections to a host;
  no request a page depends on may wait on the library (`LESSONS-viewer-ix12.32.md` 3 and 4).
- The product ends as one program with its own folder (board message 40): tools are looked for in the
  program's own folder first; no absolute path of this PC, no dependence on the start folder, PATH or a
  script. On this PC Go's `exec.LookPath` does not find ffmpeg (a stray quote in PATH): `ffmpeg.go` already
  reads PATH by hand; keep that.

## What to build
1. **`-lan ADDRESS:PORT` and `-lan-data DIR` in `tgarchive-window`,** with the same meaning, the same
   checks before anything starts (`viewer.LANAddressOK`, no start without a password, a private address of
   this PC only) and the same one printed line as `tgarchive viewer` has. The window's own page keeps its
   free loopback port; the second listener is the viewer's `ListenLAN` and `LANServer`, started and stopped
   with the window (the ending order of `main.go`: the numbers first, then every server within
   `shutdownWait`, then `Close`). A refusal to start the listener (address not this PC's, no password,
   port taken) must not leave a window open on nothing: it is said as one plain sentence, and you decide
   and say whether the window then opens without other devices or does not open (my recommendation: it
   opens, and the Settings page says in the same words why other devices are off, because the owner starts
   it by a double-click and reads no console).
   - **Go through everything the window added to the viewer and say, route by route and message by
     message, what a device on the home listener can reach:** the shell's messages (`bridge.go`, `msg.go`)
     exist only inside the WebView2, never over HTTP: prove it by reading and with a test that a signed-in
     home device gets none of the window-only behaviour (no mpv play, no "Open in the player", no
     preference or player-path change, no download handled by the shell) and plays video the browser way.
     Any route the window work added must carry an access class; a new one defaults to local.
   - The page that tells a phone's script it is inside the window (how `item.js` and `play.js` choose the
     shell path) must not be answerable by a home device's request, a header or a query.
2. **The archive cannot be opened: the window shows why.** Today the window shows the fixed line
   `textNoViewer` whatever `viewer.New` said. Show the viewer's own sentence when it is one of the fixed,
   safe ones (the catalogue's schema words from the read-only door, "the catalogue file is not there", the
   library not reachable, a second program holding the folder): a small closed set mapped in the viewer
   package (an exported function that turns an error of `New` into words fit for a page, or ""), never an
   error's raw text (it can hold a path). Anything else keeps the fixed line.
3. **ffmpeg is looked for in the program's own folder first** (after an explicit `-ffmpeg`): beside the
   program, in `ffmpeg\` beside it, and one folder up in `ffmpeg\` (the rule mpv has: read how the window
   finds mpv and mirror it), then `FFMPEG_PATH`, then PATH as today. By `os.Executable`, never the current
   folder. The log line that says where ffmpeg was found keeps saying only the kind of place, not the path.
   mpv's own order is reviewed code: leave it, and say in the hand-back what its order is.
4. **Small things from the window's first real uses, each with a named test where a test can see it:**
   - Left and Right while a video plays in the window: today they seek; previous and next are buttons.
     Leave the keys, but make sure the page's own arrow-key handler and mpv's do not both act on one press
     (say what you found).
   - An over-cap video costs about 7 s in the window before the page takes over: find where the time goes
     (the watchdog's bound, mpv's own failure) and shorten it if a number shows it is safe; otherwise say
     why not.
   - The window counted as hidden when minimised: say what the page and mpv do then (a video that goes on
     playing sound in a minimised window is wanted; a page that keeps polling is not).
   Do not spend more than a small part of the piece on these; 1 to 3 are the piece.

## Bounds
- Only these: `cmd/tgarchive-window`, `internal/window`, and in `internal/viewer`: `ffmpeg.go` (and its
  per-system files), a new small file for the error words, `lan.go`/`access.go` only if 1 shows a gap (say
  it), `web/js/settings.js` and `lan.js` for the one sentence of 1. No schema step, no `go.mod` change, no
  other package. Two other coders work in other copies: on the thumbnail makers (`maker.go`, `thumb.go`,
  `cmd/tgarchive/thumbs.go`, one new flag in each command's flag list) and on the conversation (`conv.go`,
  `chats.go`, `web/js/chat.js`, `chats.js`): keep out of those files; in `cmd/tgarchive-window/main.go` keep
  your flag lines together so a one-line flag of theirs merges cleanly.
- The viewer's and the window's import walls stay (`wall_test.go` in both): no Telegram code, no new
  outbound connection.
- **Privacy:** invented data only. Never start the owner's window or viewer, never open the owner's
  catalogue, library or any real media; nothing under
  `%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b` except running the mpv
  program there headless on invented clips, as the earlier rounds did. Nobody moves the owner's pointer or
  takes the foreground: the window's `-selfcheck` on an invented archive is the way to drive the real
  pages; what only a real pointer or a real phone can show is written as "for the owner".
- The home listener is never started on a real address by you except bound to a private address of this
  PC inside a test, with an invented password, closed at the test's end; never 0.0.0.0.
- **Load:** `GOMAXPROCS=2`, `go test -p 1`, `GOGC=50`; before a test run check free memory
  (`powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB"`) and
  wait while under 2 GB. **Named tests only while working**; `internal/window` whole is small and may run
  once at the end; no whole run of `internal/viewer`, no race detector (the main session runs both once).
  Tests must not judge real time. `FFMPEG_PATH` set for tests that need ffmpeg.
- A caller that captures the output of a script or program that starts a hidden child waits until the
  child ends: do not pipe such a start.
- Commit as you go on `wip/b-winlan` and push it to `private` (never another branch):
  `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## At the end, once
`gofmt -l` on what you touched; `go vet ./internal/window ./internal/viewer ./cmd/...`; your named tests;
`go test ./internal/window -p 1`; `go test ./cmd/...`; `CGO_ENABLED=0 go build ./...`; the `-selfcheck`
through the real pages once, briefly, if you changed what it covers. Hand back, as your last message: the
commits (pushed) and the head; for 1, the list of what a home device can and cannot reach and the test
that holds each line; what 2 to 4 do; any difference from this brief with the reason; the exact command
line for the owner to switch other devices on (placeholders for the address; the password is set first in
Settings or with `tgarchive viewer-password`: say which works with the window's folder); what you ran and
what it printed; what you did not test; doubts. Commit-ready, nothing left running, the copy clean.
