# Design G6: one program with its own folder (pages track, session P2; 2026-11-15; not built)

The owner, 11-15 18:47: "remember we're going to roll this program into a standalone .exe with a folder as
well." The integrator's reading (board message 40): product code finds its files from the program's own
folder or a setting; no absolute path of this PC; tools looked for in the program's folder first; what a
starter script does today is reachable from the program and its settings. The packaging is this track's,
after G1. This page is the design; a coder's brief is cut from it once G1 is merged and the owner has seen
the four choices at the end (each has a recommendation, and the build goes by the recommendation unless the
owner says otherwise).

## What is known already
- **Two programs are needed whatever the folder looks like.** The VPN rule is by program: the collector's
  name is in the VPN's list and everything it sends goes through the VPN; the viewer reads the library on the
  NAS and must stay out of it (TRIED-BEFORE 14: that is why the old app's viewer is a copy of the program under
  another name, and why an update must not find the viewer holding the downloader's file). So "one .exe"
  is the one thing the owner opens; behind it the folder holds the collector and the viewer as their own
  programs.
- **The old app's lessons for a program that starts itself** (TRIED-BEFORE 12, 21; LESSONS 6): a launcher that
  hid crashes cost days (a stack overflow every 2 to 3 hours, restarted silently): the launcher shows why a
  start failed and never restarts a program by itself without saying so; a version that crashes at start must
  not loop; a copy of the catalogue before an update; GitHub's anonymous limit broke the launcher twice (this
  launcher asks nobody for updates). An install by hand took 33 s from stop to start.
- **What the test account's scripts do today that the program must do itself** (`a3\a3-start.ps1`,
  `app\tgarchive.ps1`): name the catalogue, the staging and the library folders; name the VPN's adapter
  (`WindscribeWireguard` since the owner's update; the app must say plainly when the named adapter is missing:
  FEATURES 12 round 10); look up the PC's public address **outside** the VPN and hand it to the collector as
  the address it must not have (the collector itself is inside the tunnel and cannot learn it); send the
  output to a log file; open the page.
- **Where files are looked for today:** the API settings file and the session key under `%LOCALAPPDATA%\tgarchive`
  (the key is outside the data folder on purpose: a copy of the data folder alone cannot use the login); the
  catalogue, staging and library by flags; the sessions in a folder beside the catalogue; the viewer's own
  state in a folder beside the catalogue; ffmpeg by a setting, `FFMPEG_PATH`, then PATH (Go programs on this PC
  do not find it on PATH: board message 22). Nothing uses the program's own folder yet.
- The viewer track plans a native window (`PLAN-native-window.md`: a program of its own around the same pages,
  with mpv). It fits this folder as one more program the launcher may open instead of the browser.

## The folder
```
tgarchive\
  tgarchive.exe                      the one thing to open. Not in the VPN's list. Talks to nobody but 127.0.0.1
                                     and one public-address lookup.
  tgarchive.json                     its settings: where the data is, the staging and library folders, the VPN
                                     adapter's name, the two page addresses. Made at the first start.
  programs\tgarchive-collector.exe   the collector with its pages (G1). The one entry in the VPN's list.
  programs\tgarchive-viewer.exe      the viewer. Never in the VPN's list.
  programs\tgarchive-window.exe      later: the native window (viewer track).
  tools\                             optional: ffmpeg, mpv. Looked for here first, then the setting, then
                                     FFMPEG_PATH, then PATH.
  data\                              by default: the catalogue, the sessions, the logs, the viewer's own folder.
                                     Staging and the library are folders the settings name (another disk, the NAS).
```
Every path in `tgarchive.json` may be absolute or relative to the program's folder; the defaults are relative.
Nothing in any program reads the current directory.

## What `tgarchive.exe` does (a new, small program; it imports neither the collector nor the Telegram package)
1. Finds its folder from its own location, reads `tgarchive.json`.
2. **First start (no settings, or a folder missing):** a small setup page on 127.0.0.1 before anything else
   is started: the library folder (a folder dialog; checked to exist), the staging folder (default `data\staging`
   with the disk's free space shown), the VPN adapter chosen from this PC's adapters by name, and one line
   saying which program file to put in the VPN's list (its full path, to copy). Nothing is sent to Telegram.
3. **Already open:** the pages answer at their address: it shows them and does nothing else.
4. Looks up the public address (one request to a plain-text service, as the script does; this program is
   outside the VPN), starts the collector with `run -pages` and the settings' folders and adapter, its output
   in `data\logs`; starts the viewer on the same catalogue; waits for the pages; opens them (the browser now;
   the native window when it exists and the setting says so).
5. Stays in the background until the pages' Quit ends the collector; then stops the viewer and ends. If the
   collector ends by itself it says so in a small window with the log's last lines (numbers and fixed words),
   and **does not start it again by itself**.
6. A start that fails (the adapter is missing, the address is in use, the collector's file is not where the
   settings say, an older catalogue) says why in fixed words, once.

What moves out of flags and scripts into the settings and the pages: the folders, the adapter's name, the
addresses; later the copy's choices (`-no-links`, `-read-back-now`, the NAS helper's address), which are the
core track's flags today and get their place on the Settings and Staging pages.

## The build
One script (`ix-tools`, the integrator's to run at an install) makes the folder from a commit: the three
programs with their version, an empty `tools`, no settings file and no data. An install or an update replaces
`tgarchive.exe` and `programs\`; `tgarchive.json`, `data\` and `tools\` are never touched. The earlier programs
are kept beside the new ones under their commit's name, as the installed collector's `.bak` is today.

## For the owner: four choices, each with what the build will do unless you say otherwise
1. **Where the data sits.** Recommended: inside the program's folder (`data\`), so the folder is the app; the
   staging and library folders are set at the first start (the library on the NAS, staging on the disk you
   enlarged for it).
2. **The keys** (the Telegram API file and the key of the session files). Recommended: they stay in your
   Windows profile, outside the program's folder, as today: a copy of the folder to another PC or a backup
   then does not carry a usable login. The other way (inside the folder) makes the folder fully portable.
3. **The VPN's list.** The collector's file moves from `%LOCALAPPDATA%\tgarchive\bin\` into the program's
   folder, so Windscribe's split tunnelling entry has to be changed once to the new path; the first start
   shows the path to copy. The old entry can stay until the old scripts are no longer used.
4. **What opens.** Recommended: your browser on the pages now; the native window in its place once the viewer
   track has built it, with a setting to choose.

## Not in this piece
Automatic updates (FEATURES: later, with a signed checksum and a step back after three crashes); a watchdog that
restarts the collector (core track; it must go through this launcher's rule: say so, never loop); the NAS
downloader; an installer.
