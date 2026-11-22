# Brief F8: the app's identity: its icon and its name (UI track, session U-1, 11-22)

You are an Opus coder for the UI track of a private Go project (a Telegram archiver for Windows; programs in
`archiver/cmd/*`, a WebView2 window in `internal/window`). Work ONLY in your copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-ui-f8` (branch `wip/ui-identity`, cut from F1's `wip/ui-frame` f76f3197).
Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `git push private wip/ui-identity`.

## Rules (binding)
The "Rules" section of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-F1-one-frame.md` binds you word for word (invented
data; the owner's real window is open: never a screen screenshot, never computer-use, pictures only of your own try window
with `runs-ui-1\shot.ps1`; Go through `ix-tools/env-archiver.sh`, one command at a time, named tests only; nothing against
Telegram). **No new third-party Go module and nothing downloaded:** the resource writer is a small program of our own.
**Never rename a program file or folder** (`tgarchive.exe`, `programs\tgarchive-collector.exe`, ...): the owner's VPN
split-tunnel list names the collector's exact path, and the update command and settings depend on the names.

## The owner's words and choice
On the taskbar entry (a blank Windows icon and the bare word "tgarchive"): "This looks shabby". They chose icon C, refined
as C2 (a dark tile with a light rim: a media grid where one tile is a chat bubble), and the shown name "TG Archive".
Source and output, all in `C:\Users\trabi\Claude\Projects\Telegram\design-options\icons\`: `icon-c2.svg` (32 px and up),
`icon-c2-small.svg` (16 to 24 px), `app.ico` (made from them: 16, 20, 24, 32, 40, 48, 64, 128, 256; each checked to be the
intended drawing), `app-<size>.png`, the sheet `icon-c2-sheet.png`.

## The goal
1. **The icon in every program file.** Put the two SVGs and `app.ico` into the repo (e.g. `archiver/internal/appicon/`, with
   a README line on how the .ico was made: headless Edge renders each SVG at 256, Pillow scales and writes the ICO). Write
   `archiver/tools/mkres` (Go, standard library only): it writes a COFF resource object (`rsrc_windows_amd64.syso`) holding
   RT_ICON + RT_GROUP_ICON (group id 1, from the .ico) and a VERSIONINFO (ProductName "TG Archive", FileDescription per
   program, e.g. "TG Archive", "TG Archive collector", "TG Archive window", CompanyName empty, the version from the build if
   one exists, else [address removed]). Generate and commit the .syso into each main package the owner meets: `cmd/tgarchive-open`
   (tgarchive.exe), `cmd/tgarchive-window`, `cmd/tgarchive` (the viewer), `cmd/tgarchive-collector`, `cmd/tgarchive-watchdog`,
   `cmd/tgarchive-backup`. A test in tools/mkres parses its own output (the section, the group directory, the sizes). Check
   that `deploy/folder/make-folder.sh` (pages') needs no change (go build picks up a .syso); if it does, ask U-1.
2. **The window's own icon:** title bar, taskbar and Alt-Tab use the program's icon (WNDCLASSEX hIcon / hIconSm from the
   resource, sizes from GetSystemMetrics). `internal/window` is the viewer track's: one lent commit, subject "Lent to the
   viewer (window):".
3. **The name shown:** the window's title "TG Archive · <place>" (the place's name, e.g. Overview, Library, a chat's name,
   Settings), following the page: the shell sets `document.title` on each place and the window mirrors the document's title
   (WebView2's title-changed event, or what the window already has: find it); the waiting page "TG Archive". The strip's name
   (appshell), every page's `<title>`, the launcher's setup and other pages ("tgarchive" in their head) say "TG Archive"; the
   pages' and the viewer's favicon become the new icon (an SVG asset, `script-src 'self'` rules unchanged). Words inside
   sentences that name a file or a program path stay as they are.
4. **The notification-area icon** does not exist yet (checked: no Shell_NotifyIcon in the code). Do not build it; say in your
   report where it will take the icon from (the same resource).

## Done means
- tools/mkres's test; the window's and appshell's named tests; any test that names "tgarchive" in a title, updated; gofmt, vet.
- A try folder built with `deploy/folder/make-folder.sh` into `runs-ui-1/try-f8/folder`: pictures of (a) the folder in
  Explorer is NOT allowed (it is the screen): instead extract the icon from the built `tgarchive.exe` and
  `programs\tgarchive-window.exe` with a few lines of PowerShell (`[System.Drawing.Icon]::ExtractAssociatedIcon`, saved as
  PNG) to show it is embedded; (b) your try window's capture by `shot.ps1` (title bar with the icon and "TG Archive ·
  Overview"); (c) the version info read back (`(Get-Item ...).VersionInfo`, the fields only). In `runs-ui-1/f8-pictures/`.
- Report back: the branch head, files touched (and the lent commit), tests with times, the pictures, what is not done or
  not verified (under 30 lines). Close your programs.
