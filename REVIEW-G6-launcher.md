# Review G6 stage A: the launcher `tgarchive.exe`, its settings, the folder's build (independent, read-only)

Reviewed: branch `wip/pages-g6` at 51d7656a against 27a7d4dc, in the copy `wt-pages-g6` (left untouched: `git status`
empty before and after). Read in full: every file of the diff, `a3-start.ps1`, `a3-stop.ps1`, the watchdog
(`cmd/tgarchive-watchdog`, `internal/watchdog` loop/status/exec/proc/lock/group, `internal/crashlog` marker), the
collector's `run` flags and `bindPages`/`signedInAccounts` (`internal/collector/command.go`, `pages_cmd.go`), its
starting/stopping/no-pages answers (`pages.go`), and the native window's start and show (`cmd/tgarchive-window`,
`internal/window/shell_windows.go`, `place.go`). The author's report was read last.

Probes: `wt-pages-review-g6-scratch\probe_test.go`, loaded with `go test -overlay` (the stand-ins and the tests' own
helpers reused). No real program of the app was started, no real folder or port of the app was touched, nothing
talked to Telegram; every process signalled or ended was one a probe started.

**Count: 2 must-fix, 9 should-fix, 13 minor.**

---

## Must be fixed before the owner opens it

### M1. The viewer's window is started invisible. CONFIRMED (probe)
`internal/launcher/proc_windows.go:68-71` (`hidden`: `HideWindow: true` with `CREATE_NEW_CONSOLE`), used for the
viewer by `launcher.go:491-516` (`startViewer` → `env.Start` → `StartHidden`).

`HideWindow` sets `STARTF_USESHOWWINDOW` with `SW_HIDE` in the child's start-up information. Windows then replaces the
child's FIRST `ShowWindow` call with `SW_HIDE`. The native window shows its main window with exactly one such call:
`ShowWindow(main, SW_SHOWNORMAL)`, or `SW_MAXIMIZE` when it was maximised last time
(`internal/window/shell_windows.go:172-176`). On a first start there is no saved place (`place.go:77-88`), so the call is
`SW_SHOWNORMAL`.

Sequence: the owner double-clicks `tgarchive.exe` with the default setting `viewer: window`. The window program starts,
takes its one-window-per-folder lock, starts the viewer and its background thumbnail makers (reading the library),
and shows nothing. Opening the window again by hand only "brings to the front" the invisible one. Quit then ends it.

Probe (`TestProbeHiddenStartHidesWindow`): a top-level window created off screen, shown as the window shows it.
- `SW_SHOWNORMAL`: visible when started plainly, **not visible** when started as the launcher starts the viewer.
- `SW_MAXIMIZE`: visible either way.

The report's "not verified" list names this ("the window started hidden by the launcher ... was not seen").

Smallest change: start the viewer (or every child) with `CreationFlags: CREATE_NO_WINDOW` and without `HideWindow`.
The console still exists, just with no window. Probe (`TestProbeNoWindowFlagShowsAndStops`): with `CREATE_NO_WINDOW`
the window is visible (visible=1), and the launcher's own helper Ctrl-C still reaches the program (sent true, seen
true). A test that records the viewer's start flags would keep it from coming back.

### M2. The launcher binds the pages' port while it waits for the collector to bind it: a false "collector refused" and a flaky test. CONFIRMED (probe and a failed whole run)
`internal/launcher/probe.go:52-56,89-97`: when a connection is refused, `probe` calls `free(addr)`, which does
`net.Listen` on the address and then `Close`. `launcher.go:458-459` calls `probe(PagesAddr)` on every poll while the
just-started collector is binding that very address (`bindPages` → `server.Listen`, at once after its flags).

Sequence: the watchdog starts the collector. The launcher's poll finds the port still closed and binds it for a
moment. In that moment the collector's bind fails: "the pages' address ... cannot be used", exit 2. The watchdog ends
with 2, and the launcher shows "The collector refused to start. Nothing runs." for a start that would have worked.

Evidence:
- The package's whole run, done once as allowed: `TestStartOrderAndArguments` failed ("nothing opened at" the pages)
  after 60 s. Every other test passed.
- That test alone ×5: pass.
- The same flow repeated after the tests that run before it, at the tests' 50 ms poll: 3 failures in 95 runs. Each
  had the stand-in collector's line "the pages' address cannot be used" and the watchdog ending with 2 after 0 s, and
  no socket was on the port a second later.
- The same flow with a 3 s poll: 0 failures in 45 runs.
- Direct probe (`TestProbeLookBindsThePort`): while `probe` looks at a free address, 620 of 4290 binds of that address
  were refused in 5 s.

At the program's 500 ms poll the chance per start is smaller, but it is not zero. In tests it makes the pre-merge full
run fail now and then.

Smallest change: do not bind in `probe`. Treat a refused connection as `answerNone`. If the "in use" distinction is
still wanted, keep `free` only for the one look before the start (`begin`, line 372), never in the poll loop.

---

## Should be fixed

### S1. "Already open" takes any tgarchive pages on the address for this folder's. PLAUSIBLE (depends on the starter script running at the same time)
`launcher.go:372-376`, `:174-178`; `probe.go:62-72` (by `<title>` only).

`a3-start.ps1 -Pages` uses the same default `127.0.0.1:8787`. Sequence: the test account's collector runs from the
script with its pages, and the owner double-clicks the folder's `tgarchive.exe`. The pages answer, so the launcher
opens the TEST account's pages as "already open" and ends. Nothing from the folder starts, and the owner believes the
folder runs. Quit on those pages ends the script's collector.

Change: take the pages for this folder's only when this folder's watchdog is alive (`findLeft` → `leftWatchdog`), or
its marker's collector is. Otherwise refuse in fixed words: "the pages' address is used by another tgarchive (another
folder, or the starter scripts)". The author's proposed `X-Tgarchive-Pages` header would not tell two catalogues apart.

### S2. The orphan and the followed watchdog are recognised by name, not by place. CONFIRMED (probe)
- `status.go:85-106` (`findLeft`), `proc_windows.go:46`: `Info` reads the full image path, then keeps only its base name.
- The watchdog branch of the marker (`status.go:96`) has no creation-time check at all.

Probe (`TestProbeForeignCollectorTakenAsOrphan`): a `tgarchive-collector.exe` running from ANOTHER folder, named by
this folder's marker, is taken as this folder's orphan, with "Stop what is left" offered.

The marker is a file anyone with the folder can write. With a marker naming the installed test collector (and its start
time), the owner's click sends that collector a Ctrl-C.

Change: return the full path from `Info`, and require it to sit under `<folder>\programs\` (case-insensitive) for both
the collector and the watchdog. Give the marker's watchdog the status file's `watchdog_started` check, as the status
branch has.

### S3. Kill and Ctrl-C go by process number after the check. PLAUSIBLE (milliseconds; a number reused by another program)
- `launcher.go:540`: `stopViewer` kills `v.Pid()` by number. Before that it checked `Done`, then waited up to 15 s for
  the helper and 10 s more. The viewer can end meanwhile (the owner closed the window as Quit came). Go then lets go of
  its handle, and the number is free for another program.
- `launcher.go:692-712`: `stopLeft` checks, then `Procs.Kill(pid)` opens the process again by number.
- `proc_windows.go:85-94`: the helper `AttachConsole(pid)`s by number about 100 ms after the check. If the number now
  belongs to another console program, the Ctrl-C goes to every program on that console (group 0).

Change:
- Give `Proc` a `Kill` that uses the start's own handle (`cmd.Process.Kill`, which fails once the process has ended).
- In `SystemProcs`, open ONE handle with query and terminate rights, check name, path and creation time on it, and
  terminate that handle.
- In the helper, open a handle first, check name and creation time (pass them as arguments), and keep the handle open
  across `AttachConsole`. A number cannot be reused while a handle is open.

### S4. Any end of the watchdog closes the owner's viewer, not only Quit. CONFIRMED (probe)
`launcher.go:554` (`ended` stops the viewer before looking at the code), `:229-231` and `:235-237` (Close).

Brief point 5 stops the viewer only on exit code 0. Probe (`TestProbeViewerStoppedOnCrash`): the collector ends with 3
and the viewer is stopped.

Sequence: the owner is browsing in the window. The collector crashes, the watchdog gives up, and the window vanishes.
The same happens when the collector refuses at start, or when the owner presses Close on a failure page.

Change: stop the viewer only when the watchdog's code is 0. Leave it running otherwise. A Try again that starts it
again is harmless: the window keeps one per folder, and a second browser viewer fails to bind its address.

### S5. `make-folder.sh` checks for a running app before an 80 s build, by the unresolved path. PLAUSIBLE
`deploy/folder/make-folder.sh:33-34,41-51` (the check) against `:73-91` (the moves after the build).

Sequence: the installer runs the script, and the owner double-clicks `tgarchive.exe` during the build. Windows lets a
running program file be renamed, so the moves succeed. The running collector's file goes into `programs\<old>\`, and
the watchdog's next restart starts the NEW collector beside the old watchdog.

Second way past the check: the script compares `pwd` (the logical path). The launcher starts its programs from
`os.Executable` with links resolved. A folder reached through a junction or link therefore never matches.

Change: run the check right before the moves (and again just before each `mv`), on `pwd -P` and the resolved path.

### S6. `make-folder.sh` accepts the repository's root and any foreign folder. CONFIRMED by reading (`:33-37`)
- The guard compares with the Go module (`archiver/`), not with the repository (`git rev-parse --show-toplevel`). An
  output folder at the repository's root or under `docs/` is filled with `programs\`, `tools\`, `tgarchive.exe` and
  `README.txt`.
- `mkdir -p "$1"` runs before the refusal, so a refused folder inside `archiver/` is still made.
- A non-empty folder that is not an earlier app folder is taken as one: any `tgarchive.exe` and `programs\*.exe` there
  are moved into `programs\earlier\`. PLAUSIBLE harm: whether the installed `bin` holds a `tgarchive.exe` could not be
  checked (the `b` scripts were not read).

Change: refuse a non-empty folder that has no `programs\VERSION.txt`, refuse anything inside the repository, and make
the folder only after the checks.

### S7. A second launcher after the first was killed opens the pages and ends: nobody follows the watchdog. CONFIRMED by reading
`launcher.go:372-376`.

A launcher that bound `launcher_addr` knows it is the only one. Even so, when the pages answer it opens them and
returns. Sequence: the launcher is killed (Task Manager, or its own crash) and the owner opens it again. The pages are
opened and the new launcher ends. A later give-up of the watchdog is then shown nowhere, which is the "hidden crash" the
owner's rule is about. The first launcher's viewer is also never stopped at Quit.

Change: after opening the pages, follow this folder's watchdog (`followOther`) when it is alive.

### S8. The tests' clean-up kills by process number with a name check only. PLAUSIBLE (rare)
`launcher_test.go:379-411` (`alive`, `cleanup`), also used after every test.

The PC runs the owner's real `tgarchive-collector` under its watchdog, and the tests are run on that PC. A stand-in's
number reused by the real collector between its end and the clean-up is killed. That would be a kill in the middle of
a download.

Change: also require the image's full path to be under the test's temporary root.

### S9. "End it now" is the only choice after 60 s, though a clean stop can take longer. CONFIRMED by reading
`launcher.go:722-729`, `words.go:42`, `ui.go:273`.

`a3-stop.ps1` says a collector with much in transfer may need longer than 60 s, and offers to look again. After 60 s
the launcher offers only the kill. Its words lump the case together with "the clean stop could not be sent".

Change: keep "Stop what is left" (look again) beside "End it now". Say plainly that the collector "has not ended yet;
it may still be giving files back".

---

## Minor

1. `start.go:184-190`: `cleanAddress` takes any address. CONFIRMED (probe): 0.0.0.0, 10/8, 192.168/16, 127.0.0.1, ::1,
   100.64/10 and 169.254/16 are all taken. A portal or a broken service would make the forbidden address a wrong one.
   Require a global unicast address that is neither private nor shared.
2. `settings.go:131`: the same port spelt twice ("08786" and "8786") passes the same-address check. CONFIRMED (probe).
   It fails closed later as "pages address in use". Compare the parsed ports.
3. `start.go:158-179`: the lookup uses `http.DefaultClient`.
   - It follows `HTTPS_PROXY` from the environment (the "public" address would then be the proxy's) and redirects,
     https→http included.
   - It sends `User-Agent: tgarchive`, which names the app to an outside service.
   Use a client with no proxy and no redirects, and a generic agent.
4. `ui.go:483-530` against `launcher.go:351`: `checkSetup` runs on the page server's goroutine and reads `l.s`. A
   second, simultaneous save (two tabs) can read it while the main goroutine writes it. `render` reads `l.lay` the
   same way. The race detector would report it; the harm is nil in practice.
5. A failure page has no idle end (the author's doubt): the launcher holds `launcher_addr` until Close. Acceptable,
   since opening it again shows that page.
6. `launcher.go:296-301,453-456`: the launcher's page is opened once per life. If the pages did not come up in 90 s,
   the page was opened then. A later end is not opened again if the owner has closed that tab.
7. When the watchdog itself refuses because its marker's child lives (its rule takes any program, the launcher's takes
   a collector), the page says "The watchdog ended at once. Nothing runs." The status line just below says the earlier
   program still runs.
8. The launcher's own crash leaves no trace (a GUI program, nowhere to write its standard error). Use
   `debug.SetCrashOutput` into `data\logs`.
9. README:
   - "must name this file, and only this one" is followed by "the old entry ... can stay".
   - The sign-in command has no `-public-forbid`: the adapter check only. That is acceptable, but it should be said.
   - `viewer.err.log` is not listed.
10. `launcher_test.go:897-901`: "opened again" is checked without waiting right after the first open, so a later
    second open would pass. Weak, not wrong.
11. `ui.go:503`: the data folder is made even when the form is refused for another field.
12. "The collector refused to start" gives an exit code only. Naming where its own words are (`collector.err.log` in
    the watchdog's folder, by its place in the folder) would let the owner find why. The VPN refusing the forbidden
    address (the VPN on for the launcher too) lands here.
13. No copy of the catalogue is made before a new build's collector migrates it. This is the old app's lesson; the
    author lists it as not built.
14. A Ctrl-C to the orphan's console reaches every program on that console. When the launcher started the watchdog,
    that is only the collector and its own children. A watchdog of this folder started by hand in a terminal would
    share that terminal (as `a3-stop.ps1` does). Fine as it stands; worth a sentence in the code.

---

## The command line beside the script's (`a3-start.ps1 -Pages`)

| | `a3-start.ps1 -Pages` | launcher |
|---|---|---|
| watchdog program | `%LOCALAPPDATA%\tgarchive\bin\tgarchive-watchdog.exe` | `<folder>\programs\tgarchive-watchdog.exe` |
| `-dir` | `<script folder>\watchdog` | `<data>\logs\watchdog` |
| `-status-file` | `<root>\catalog\collector-status.json` | `<data>\catalog\collector-status.json` (same rule: beside the catalogue; the collector gets no `-status-file` in either) |
| collector program | `bin\tgarchive-collector.exe` | `<folder>\programs\tgarchive-collector.exe` (the VPN entry changes once) |
| `-db` | `<root>\catalog\catalog.sqlite` | `<data>\catalog\catalog.sqlite` |
| `-staging` / `-library` | `<root>\staging` / `<root>\library` | the settings' folders, absolute or relative to the folder (blanks and `& % ^` reach the collector unchanged: probe) |
| `-no-links -read-back-now` | fixed, before `-vpn-adapter` | from `run_flags` (both by default), at the end; the settings can remove them |
| `-vpn-adapter` | `-Adapter`, default `WindscribeWireguard`, not checked | `vpn_adapter`, same default; checked present exactly once, in any case, before anything is started |
| `-public-forbid` | `curl --max-time 20 https://api.ipify.org`, any non-empty answer | `public_address_url` (https only), 20 s bound, the answer must parse as an address (any address: minor 1); proxy from the environment (minor 3) |
| `-pages -pages-addr` | only with `-Pages`; any `-PagesAddr` | always; `pages_addr` must be `127.0.0.1:port` |
| `-viewer-url` | never | only with `viewer: browser`: `http://<viewer_addr>` |
| extra flags | `-Extra`, anything | `run_flags`, without `db staging library vpn-adapter public-forbid pages pages-addr viewer-url status-file direct` in any spelling (`-x`, `--x`, `-x=v`); the remaining gate flags `-public-url` and `-public-require` only add checks |
| catalogue missing | refused ("not where the script looks") | started all the same: the collector runs its pages with no account signed in |
| earlier run | `a3.pid` and the marker | the watchdog's status file and the marker (S2) |
| watchdog's own output | `<script folder>\logs\watchdog-<stamp>.out/.err.log` | `<data>\logs\watchdog-<stamp>.out/.err.log` |
| working folder | PowerShell's current folder | the app's folder |
| environment | inherited | inherited, plus `FFMPEG_PATH=<folder>\tools\ffmpeg.exe` when that file exists (an existing `FFMPEG_PATH` is replaced) |
| how started | `Start-Process -WindowStyle Hidden`, new console | `CREATE_NEW_CONSOLE` + hidden, no input, output to files (M1 for the viewer) |
| first seconds | reads `watchdog-status.json` for 12 s | follows the watchdog until the pages answer (90 s bound), then to its end |
| viewer | none | `window`: `programs\tgarchive-window.exe -db <cat> -library <lib> [-mpv tools\mpv.exe]`; `browser`: `programs\tgarchive-viewer.exe viewer -db <cat> -library <lib> -addr <viewer_addr>`. The `b` scripts' arguments (for example the thumbnail flags) were not compared: not read |

---

## Checked and found sound
- The launcher never starts a program again by itself. The run loop starts again only on the owner's Try again;
  `followOther` and `stopLeft` start nothing; the one helper start is `tgarchive.exe -send-ctrl-c`.
- Exactly one public-address lookup per start, after the adapter check. With no address, nothing is started (test and
  mutation sound).
- The address is in no log, page or settings file; the log keeps milliseconds only. It is on the processes' command
  lines, as with the script.
- The guard on the extra flags: no flag that turns a gate off (`-direct`, a second `-public-forbid` or `-vpn-adapter`,
  a non-loopback pages address) gets through. Flags reach the watchdog only after `--`.
- `pages_addr`, `launcher_addr` and `viewer_addr` are taken only as `127.0.0.1:port`. An invalid `launcher_addr` falls
  back to the default for the bind.
- The page's guard: the host (DNS rebinding), `Sec-Fetch-Site`, `Origin` (including `null`), this run's token, the
  view's number. No script on the page; framing denied; a cross-site GET only by navigation.
- The settings file is written whole (temporary name, sync, rename). An unreadable, unknown-field or newer file is
  refused and never overwritten, and `SaveSettings` refuses too. Paths that depend on a current folder (`\x`, `C:x`)
  are refused.
- The folder comes from `os.Executable` with links resolved, never the current folder (test and mutation sound).
- No pipe is held: output goes to files, the input is the null device, and Go's handle list keeps the launcher's
  listener out of the children.
- Clearing the inherited "ignore Ctrl-C" mark: the launcher is a GUI program with no console, so this changes nothing
  for the launcher itself, from Explorer, a script or a terminal. Its children run on new consoles of their own, never
  on the owner's terminal.
- A stop of the orphan is the clean Ctrl-C; the kill happens only on the owner's End it now. The launcher never stops
  a running watchdog.
- Two double-clicks at once: the second fails to bind `launcher_addr` and opens the first's page, or the pages.
- The watchdog waiting to restart is followed, never started beside.
- A broken marker fails closed.
- The status file is read with delete sharing, so the watchdog's rename is never refused.
- The log: constant formats, numbers and the build only (the test checks every line against the formats).
- The wall test: no collector, Telegram, catalogue or server import.
- The tests: no real port (all from `:0`), no real folder (`t.TempDir`), no real program of the app.

## Not looked at / not verified
- The real window, viewer, collector, watchdog and VPN (none started).
- Whether the real collector creates the catalogue on an empty data folder.
- The `b` scripts' viewer arguments (not to be opened).
- Windscribe's behaviour for a program file renamed while it runs (S5).
- `tools-README.txt` beyond its three lines.
- `make-folder.sh` was not run by me: its test ran in the package's whole run and passed.
- The Linux build (`proc_other.go`) only by reading.
- `cmd/tgarchive-open` beyond its 42 lines.

## The race detector
Only `internal/launcher`: the page server's goroutines against the main loop (minor 4), `StartHidden`'s wait
goroutine, and the shared logger. Its tests depend on Windows process behaviour (new consoles, the Ctrl-C helper,
`QueryFullProcessImageName`), so run it on Windows if a race-enabled toolchain is at hand. Otherwise, in the Linux
container, expect the Windows-path tests to need skipping. No race run is needed for `cmd/tgarchive-open` (no
goroutine) or for the shell script.

Note for the full run before the merge: until M2 is fixed, `TestStartOrderAndArguments` and the other start tests can
fail by chance (about 3% per start at the tests' poll).
