# Review brief B6-W: an independent, read-only, security-minded review of `tgarchive-window -pages`

You are an independent reviewer (Opus) with a security eye, for the viewer track of the new archiver. You did
not write this code and you owe its coder nothing. The piece: branch `wip/b-winpages`, head bc6a44f5, cut from
the main head 6af0c09a, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-join` (Go module in
`archiver/`). The difference is `git diff 6af0c09a bc6a44f5` (only `internal/window` and
`cmd/tgarchive-window`: new `pages.go`, `pages_windows.go`, `pagescheck_windows.go`, the command's `pages.go`
and tests; changed `allowed.go`, `shell_windows.go`, `webview_windows.go`, `wall_test.go`, `run_other.go`,
`doc.go`, the command's `main.go`). What it was asked to do:
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-B6-window-pages.md` (read it in full first). The earlier reviews
of the window are in the copy's `archiver/docs/review` (`viewer-b4-window-2026-11-15.md` and `-2-`,
`viewer-b5-window-only-2026-11-15.md` and `-2-`): read them so that you know what was settled.
Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash (Go is not on PATH).

**Why this deserves a hard look:** this mode puts the app's own pages (the launcher's setup and status pages
and the collector's pages, from which a Telegram account is signed in, chats are chosen and, soon, messages
are sent) into a browser engine that this program controls. The program runs on the owner's PC OUTSIDE the
VPN, so any request it lets out to the internet shows the owner's own address. And the same shell is the
viewer's window, which shows a private archive.

## How
- **Read-only on the copy and the branch:** change no tracked file, commit nothing, push nothing. Probes live
  in a new folder `C:\Users\trabi\Claude\Projects\Telegram\wt-b6-review-W-scratch` (lay a probe in with
  `go test -overlay`; the copy must be clean when you end: say so).
- **Try to break it.** A finding is **confirmed** only with a probe that shows it or a line-by-line argument
  nobody could doubt; otherwise **plausible**, with what would settle it. Look hardest at:
  1. **Requests that leave although nothing is shown.** The coder found, and says plainly, that this WebView2
     sends the request of a refused top-level or frame navigation BEFORE the window refuses it (its
     self-check counted HTTP requests and TLS hellos at a port that was not named), and that the viewer's
     window does the same today through the shared handlers. Establish exactly what can leave, in BOTH
     modes: a refused navigation, a frame, a `window.open`, a form's target, a meta refresh, a redirect from
     a named address, a sub-resource of a page (an image, a script, a style sheet, a font, `fetch`, a
     WebSocket, a beacon, a `<link rel=prefetch>`, a favicon), DNS prefetch, the engine's own traffic
     (component updates, SmartScreen, safe browsing, crash reports, spell-check, translation, sign-in:
     which are on and which the program switches off). For the viewer's mode: can anything in an ARCHIVED
     MESSAGE (a text, a caption, a link preview, a file name) or in a crafted media file cause such a
     request? Read the viewer's response headers (its content security policy) for what they already stop.
     **Say the smallest sound way to make "nothing but the named 127.0.0.1 ports is ever asked" true for
     both modes** (WebView2's resource-request filter, a proxy setting that points nowhere, the engine's
     own switches: which holds, which leaks, what each costs), concretely enough to brief.
  2. **The address rule** (`allowed.go`: `PagesAddress`, `pageSet`, `refusedKind`, and `origin.allows` which it
     reuses): every form you can think of for the flag and for a page's link (other loopback forms, a
     trailing dot, an at-sign, a backslash, upper case, percent escapes, an IPv6-mapped form, a port with
     signs or spaces, a very long value, `http://127.0.0.1:PORT@evil/`, `http://127.0.0.1:PORT.evil/`); a
     named port on which ANOTHER local program listens later (the launcher gone, the port taken): what that
     program can then do inside the window.
  3. **What a page of a named address can make the program do.** The page-to-window channel (dropped and
     counted: is anything of the viewer's bridge reachable in this mode, by a message, a host object, a
     script injected by the shell?); a new window; a download in every form (a link with `download`, a
     file answer, a blob, a data address, "save as", print to file, drag out); a permission request of every
     kind, and those WebView2 grants without asking; the launch of another program (a scheme link, a
     `ms-` address, a UNC path, a `file:` address, a `.lnk` or `.url`); the context menu, the developer
     tools, the keyboard shortcuts (F12, Ctrl+U, Ctrl+P, Ctrl+S, Ctrl+O, Ctrl+N, Ctrl+J), autofill and
     saved passwords (the sign-in page asks for a phone number, a code and a password: is anything of that
     kept in the WebView2 folder on disk?), script dialogs, full screen, the title.
  4. **The two modes never mix.** Without `-pages`: is the program byte for byte what it was (the flags, the
     words, the bridge, the self-check)? With `-pages`: can any viewer flag, the viewer's data folder (the
     same `-data` as a viewer's window: what then), or an environment variable bring the viewer's parts in?
     One window per data folder: two starts at once; a start while the first is still starting; the mutex
     and the window class against a viewer's window on another folder.
  5. **The exit code and the bound.** Code 3 within 8 s in every way the WebView2 can fail to come (not
     installed, a broken install, the user-data folder locked by another process or not writable, the
     browser process dying at start, a hang), with nothing left running (no orphan `msedgewebview2`
     processes: count them before and after); code 3 later when the engine ends; never a window flashed up
     and gone; never a hang past the bound.
  6. **"Not answering".** The line of the window's own in every way a page can fail (refused connection,
     reset, a timeout, a 500, an empty answer, a certificate error cannot occur on http: what else), no
     loop, "Try again" loading only the first address; can a page make the window show that line or hide
     it at will, or put its own words into it?
  7. **What is written.** The data folder only: what the WebView2 folder keeps of the pages (cache, cookies,
     local storage, form data, history, crash dumps) and whether any of it holds what the app's pages show
     (names, phone numbers); the counts file: numbers and fixed words only.
  8. **The self-check and the wall.** The self-check's servers and what its pages reach (the coder says: a
     third port of its own and `localhost`, all on this PC); the widened wall test (`net/http` now allowed
     in one file of `internal/window`): can that file's code run outside the self-check; what the wall
     would not catch.
  9. **The tests the hand-back leans on.** Which of the defects you looked for would its tests still pass
     with?
- **A real window:** the self-check opens one on this PC's screen for about half a minute, and the owner is
  at the PC. Run it **at most three times**, only as the brief's rules for the coder say (a scratch `-data`
  folder of your own, `LOCALAPPDATA` pointed at an empty scratch folder for that process, output to a file,
  never read through a pipe from a hidden start), and say how often you did. A probe of your own that opens
  a window counts toward the three.
- **Privacy and load:** invented pages only. Never start the owner's viewer, window, launcher, collector or
  old app; never open the owner's catalogues, library or any real media (nothing under
  `%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b`, `%LOCALAPPDATA%\tgarchive`,
  `C:\Users\trabi\tgarchive-app`, `E:\T`, the NAS). **Your probes name addresses, never host names** (a
  reserved name in a probe can still make a DNS query leave this PC); where a probe must show that a
  request WOULD leave, point it at a listener of your own on this PC and count there; nothing may reach
  another machine. Stop no process you did not start (other programs on this PC use the WebView2 runtime:
  never end an `msedgewebview2` process that is not a child of your own start). `GOMAXPROCS=2`,
  `go test -p 1`, `GOGC=50`, named tests and your probes only; before each go command check free memory and
  load
  (`powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`)
  and wait while free memory is under 2.5 GB or the CPU is over 85%; no race detector, no Docker, never any
  cache clean-up. Other copies are other people's: do not touch them. Any file that holds a Windows path is
  written with the file-writing tool.

## Hand back, as your last message
Write `REVIEW.md` in your scratch folder (**no path of this PC in it**) and give its content: a verdict in
three lines (may the launcher start this mode for the owner after these fixes, or not); the findings worst
first, each with: confirmed or plausible, the file and line, what happens and to whom, the probe (its file in
the scratch folder and what it printed), and the smallest fix you would accept; then "Requests that leave:
what, in which mode, and the fix to brief", "Checked and sound", "The tests the hand-back leans on", "For the
pages track" (what the launcher must and must not do when it starts this mode), and "Not run". No praise, no
summary of what the code does.
