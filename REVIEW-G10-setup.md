# Review of G10 (the launcher's setup: Windows' folder box, and the app's look) — independent, read-only

Reviewer: Opus 5.5, 11-16 about 08:30. Branch `wip/pages-setup` at 1a7c0be4 against dbca91d4, in
`C:\Users\trabi\Claude\Projects\Telegram\wt-pages-setup` (Go module `archiver/`). Nothing in the tree was changed
(`git status` empty before and after; `gofmt -l internal/launcher` empty; `go vet ./internal/launcher` clean).
Probes and mutations ran from `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g10-scratch` through
`go test -overlay`, with the toolchain of `ix-tools/env-archiver.sh`, one go command at a time, the PC measured
before each (free memory 4.8 to 5.4 GB, CPU 35 to 81%). No window, dialog or program was opened; the real box
was never called.

**Verdict: may be listed after these fixes** (the three already decided, which I agree with, plus the should-fix
items below; no new must-fix).

## The three items already decided by the main session

I agree with all three; no reason against. Advice for the fix round:

1. **A choose's checks read-only** (`choose.go` 155-159 call `folderWords`, whose `os.CreateTemp` + `os.Remove`
   at `ui.go` 632-638 writes into the chosen folder, on the NAS for the library). Make a read-only twin of
   `folderWords` (empty / not allowed / missing / not a folder) for `afterBox`; leave Save's check as it is. My
   probe saw 0 entries left in the chosen folder afterwards (the file is removed), so today's harm is the write
   itself, not a leftover.
2. **The bound on `os.Stat` of the start folder** (`boxStart`, `choose.go` 99-110, via `isDir`). The same
   bound should cover the `isDir(l.folder)` call for the data folder only if the program folder can be on a
   share (it cannot today: local). When the bound passes, skip `SetFolder` entirely: `SHCreateItemFromParsingName`
   on the same unreachable path would block the box thread just as long (it is inside `runBox`, before the owner
   window exists, so nothing would show while the page says a box is open).
3. **A button that closes the open box.** Two things make it safe:
   - Close it by message, from the page's goroutine: record the box thread's id (`GetCurrentThreadId` inside
     `runBox`, in an atomic), find the dialog with `FindWindowExW(0, prev, "#32770", nil)` in a loop matched by
     `GetWindowThreadProcessId` to that thread (no Go callback needed), and `PostMessageW(WM_COMMAND, IDCANCEL)`
     to it, as `TestRealFolderBox` does. Do **not** call `IFileDialog::Close` through the raw vtable from another
     thread: the object is an STA object and the pointer is not marshalled.
   - Forget the box on the page side at once, whatever the box does: set `u.box = nil` and put the setup view back
     with `b.typed` under the lock (the code in `waitBox` already drops a late answer by `if u.box != b`). Keep
     `systemBox.busy` set until the box goroutine really returns, so that a stuck box (before `Show`, or a hung
     `SetForegroundWindow` to a hung foreground thread) frees the page without ever allowing a second box; a
     choose meanwhile then fails with step 1 and the fixed sentence. Without this, a box stuck before `Show` has
     no window to close and the page stays refused for ever.

## Must fix before the merge (beyond the three above)

None found.

## Should fix

### S1. A second press while the box is open ends on a bare text page with no way back — CONFIRMED (server side), the browser side PLAUSIBLE
`ui.go` 299-302 (and `choose.go` 27-31): any valid POST while a box is open is answered
`http.Error(w, wordBoxOpenRefused, 409)`: plain text, no refresh, no link (probe `TestProbeG10DoubleChoose`:
status 409, no `refresh`, no `href`, no `<html`). Sequence: the owner has two tabs of the launcher, or presses
Back and then Save, or a double click lands its second click before the page is replaced; the browser shows
"refused: a folder box is open on this PC; close it first …" as text. When the box closes, that text page does
not go back to the setup by itself (the box view's sentence promises this), and a reload re-posts and gets
"not now: the page changed; reload it". The typed values are safe in the launcher, but the owner must type the
address by hand. Smallest change: while a box is open, answer a POST that passed the origin and token checks with
`303 /` (which shows the box view, which says why and refreshes itself); keep the refusal itself (nothing is
taken). The tests that expect 409 change accordingly.

### S2. The box is drawn by a DPI-unaware process — CONFIRMED that no awareness is set; the blur is for a person to see
The launcher (`cmd/tgarchive-open`, built `-H=windowsgui`, no manifest, no `.syso`) never sets DPI awareness;
only `internal/window` does (`SetProcessDpiAwarenessContext`). Windows then draws the launcher's folder box at
96 DPI and stretches it: on a display scaled above 100% the box is blurry, next to a sharp browser, on a piece
whose purpose is the look. Smallest change: on the locked box thread, before `makeOwner`, call
`SetThreadDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)` (user32, Windows 10 1703+; skip when
the proc is missing). It is thread-scoped, and the thread ends with the box, so nothing else of the launcher
changes. (`centre`'s coordinates then come from the same awareness as the owner window, which keeps them
consistent.)

### S3. A fault inside the box kills the launcher; the shell's extensions stay in it for its whole life — PLAUSIBLE (by the runtime's code)
`folderbox_windows.go` 147-156: `debug.SetPanicOnFault(true)` and `recover` only turn faults **in Go code** into a
panic (for example a bad `vtbl` read). Go's Windows exception handler (`isgoexception`) passes a fault whose PC is
outside Go's text on, so a fault inside `Show` (shell32, comdlg, or a third-party shell extension the box loads:
cloud-sync overlays, a NAS vendor's namespace extension, an antivirus handler) ends in the runtime's last-chance
handler: the launcher dies ("Exception 0xc0000005 … signal arrived during external code execution", written to
`data\logs\launcher-crash.log` by `SetCrashOutput`). What is survivable: a Go-side fault, any failed HRESULT, a
panic in `waitBox`. What is not: any fault in system or extension code. During the setup the harm is small
(nothing has been started; the typed values and the page are lost; the owner double-clicks again). But the DLLs
the box loaded stay mapped, some with their own threads, in the program that then follows the watchdog for days;
a later fault there ends the launcher (the children survive: no job object). Also say it plainly in the code's
comment and the report ("never a panic" is true only of failed calls, not of faults). Smallest change, if the
main session wants isolation: open the box in a short-lived child of the launcher itself, as the existing
`-send-ctrl-c` helper does (`tgarchive.exe -choose-folder <field>`, the path back on its stdout pipe, never a log);
a crash, a hang or an extension then dies with the helper, decided fix 3 becomes "end the helper", and the
long-lived launcher never loads the shell's extensions. Otherwise accept the risk knowingly.

## Minor

- **M1. A save and a choose from two tabs can both be taken** — PLAUSIBLE (a window of microseconds).
  `ui.go` 348-357 sends the save to `u.acts` under the lock, unlocks, and marks the view busy only in a second
  locked block (374-379). A choose of another tab of the same view number that runs between them passes every
  check in `choose()` (box nil, `u.n == n`, phase setup) and opens a box; the launcher meanwhile saves and starts
  the app, every page action (Stop the program, Close the viewer) is refused while that box is open, and the chosen
  folder is dropped. Change: set the busy view in the same critical section as the send.
- **M2. The choose's own one-box check is never reached** — CONFIRMED by mutation. With `choose.go` 27's
  `u.box != nil` disabled, every choose test passes (the act's check at `ui.go` 299 and the view number refuse
  first). With the act's check disabled, `TestOneBoxAtATime` fails only on words ("409 not now" instead of the
  box words): no second box opens either way, because the box view has a new number and no form. Fine as defence
  in depth; the report should not count it as a tested layer.
- **M3. "Missing" stays after the missing folder was chosen** — CONFIRMED (probe `TestProbeG10MissingAfterChoose`:
  library chosen and in its box, the page still says "A folder named in the settings is not there: library").
  True of the saved settings, but reads as wrong next to an existing folder. Change: drop `Missing` in `afterBox`
  when the chosen field is the missing one.
- **M4. The failure sentence says "could not be opened" when it did open** — CONFIRMED by reading. `wordBoxFailed`
  is shown for every `boxFailed`, including steps 8-11 (the box was shown and failed, or gave no folder) and an
  empty answer. Change: "The folder box gave no folder." or a neutral "The folder box failed on this PC. …".
- **M5. The real test's "within the screens" checks only the size** — CONFIRMED (`folderbox_windows_test.go` 144:
  width and height against the virtual screen's size; the position is never compared). The report's "within the
  screens" overstates it. Change: compare the rect against `SM_XVIRTUALSCREEN`/`SM_YVIRTUALSCREEN` (76, 77) too.
- **M6. A minimised foreground window puts the owner at -32000** — PLAUSIBLE. `centre` (290-300) trusts
  `GetWindowRect` of an iconic window (about -32000,-32000), and the box positions itself relative to its owner.
  Change: if `IsIconic(prev)`, use the screen centre (or `MonitorFromWindow` + its work area).
- **M7. Writes the author did not list: the shell's recent items and the dialog's MRU** — PLAUSIBLE. The common
  item dialog records its last folder and size per program in HKCU (ComDlg32 MRU), and without
  `FOS_DONTADDTORECENT` (0x02000000) may add the chosen folder to Recent items. Not a log, and the owner's own
  profile, but it is a write the report says does not exist. Change: add `FOS_DONTADDTORECENT`; mention the MRU.
- **M8. A box goroutine that lands on the main thread is wedged, not ended** — PLAUSIBLE (runtime `mexit`: the
  main thread m0 is parked for ever instead of exiting). At most once per process, after COM was released and the
  windows destroyed: harmless, but the comment "the thread ends with the goroutine" is not always true.
- **M9. `FrontWay` is stale after a refused box** — CONFIRMED by reading: a box refused at step 1 or failed before
  `makeOwner` logs the previous box's way (or -1 only before any box). Store -1 at the start of each `Choose`.
- **M10. The drift test's reach** — CONFIRMED by mutation that it fails (a changed `--surface` in an overlay:
  "light: --surface is … in the launcher's style and … in base.css"). It compares only the custom properties
  (19 colours light and dark, `--font`, `--mono`, `--radius`, `--gap`); the rules copied from `parts.css`
  (`.btn`, `.pill`, `.field`, the error box) and base.css's `:root[data-theme="dark"]` block are not compared and
  can drift silently. Say so in the test's comment.

## COM and Windows calls: method -> vtable index as coded -> index by the documented order

IUnknown 0 QueryInterface, 1 AddRef, 2 Release; IModalWindow 3 Show; IFileDialog 4 SetFileTypes,
5 SetFileTypeIndex, 6 GetFileTypeIndex, 7 Advise, 8 Unadvise, 9 SetOptions, 10 GetOptions, 11 SetDefaultFolder,
12 SetFolder, 13 GetFolder, 14 GetCurrentSelection, 15 SetFileName, 16 GetFileName, 17 SetTitle,
18 SetOkButtonLabel, 19 SetFileNameLabel, 20 GetResult, …; IFileOpenDialog 27 GetResults, 28 GetSelectedItems;
IShellItem 3 BindToHandler, 4 GetParent, 5 GetDisplayName, 6 GetAttributes, 7 Compare.

| method | as coded | documented | arguments as coded | right |
|---|---|---|---|---|
| IUnknown::Release (dialog, items) | 2 | 2 | (this) | yes |
| IModalWindow::Show | 3 | 3 | (this, hwndOwner) | yes |
| IFileDialog::SetOptions | 9 | 9 | (this, FILEOPENDIALOGOPTIONS by value) | yes |
| IFileDialog::GetOptions | 10 | 10 | (this, *DWORD) | yes |
| IFileDialog::SetFolder | 12 | 12 | (this, IShellItem*) | yes (result ignored on purpose) |
| IFileDialog::SetTitle | 17 | 17 | (this, LPCWSTR) | yes |
| IFileDialog::GetResult | 20 | 20 | (this, IShellItem**) | yes |
| IShellItem::GetDisplayName | 5 | 5 | (this, SIGDN 0x80058000, LPWSTR*) | yes |

Flat functions: `CoInitializeEx(NULL, APARTMENTTHREADED|DISABLE_OLE1DDE)`; `CoCreateInstance(&CLSID, NULL,
CLSCTX_INPROC_SERVER, &IID, &ppv)`; `SHCreateItemFromParsingName(path, NULL, &IID_IShellItem, &ppv)`;
`CoTaskMemFree(name)`; `CreateWindowExW(exStyle, "STATIC", NULL, WS_POPUP, x, y, 1, 1, 0, 0, 0, 0)` (negative x/y
sign-extend and are read as 32-bit ints: right); `SetLayeredWindowAttributes(h, 0, 0, LWA_ALPHA)`;
`ShowWindow(h, SW_SHOW)`; `AttachThreadInput(me, fgThread, 1/0)`; `GetWindowThreadProcessId(h, NULL)`;
`GetWindowRect(h, &RECT)`; `GetSystemMetrics(0/1)`; `IsWindow`; `SetForegroundWindow`; `BringWindowToTop`;
`DestroyWindow`. All argument orders match the documentation. GUIDs: CLSID_FileOpenDialog
{DC1C5A9C-E88A-4DDE-A5A1-60F82A20AEF7}, IID_IFileOpenDialog {D57C7288-D4AD-4768-BE02-9D969532D960},
IID_IShellItem {43826D1E-E718-42EE-BC55-A1E261C37BFE}: all right. Constants: FOS_NOCHANGEDIR 0x8,
FOS_PICKFOLDERS 0x20, FOS_FORCEFILESYSTEM 0x40, FOS_PATHMUSTEXIST 0x800, SIGDN_FILESYSPATH 0x80058000,
HRESULT_FROM_WIN32(ERROR_CANCELLED) 0x800704C7, WS_EX_TOPMOST 0x8, WS_EX_TOOLWINDOW 0x80, WS_EX_LAYERED 0x80000,
WS_POPUP 0x80000000, LWA_ALPHA 2, SW_SHOW 5: all right.

Release and lifetime, path by path: `CoUninitialize` is deferred first (runs last) and only after a non-negative
`CoInitializeEx` (S_FALSE included, which must be balanced: right; RPC_E_CHANGED_MODE returns without it:
right); the dialog's `Release` is deferred after a successful create; the start item is released right after
`SetFolder`; the result item's `Release` is deferred; the display name is freed with `CoTaskMemFree` after it was
copied; the owner window is destroyed once on every path (explicit after `Show`, and deferred; the `ownerGone`
flag stops a double destroy), on the thread that made it. Nothing is released twice or used after its release.
The input attachment is undone on the only path that made it (no return in between); if a detach ever failed, the
attachment still ends with the thread, which ends with the box. The UTF-16 title and start strings are heap
objects (do not move), passed as `uintptr(unsafe.Pointer(p))` in the `syscall.SyscallN` call itself
(`//go:uintptrkeepalive`) and kept alive past `Show` by `runtime.KeepAlive`. `comObj` pointers to system memory
in Go pointer variables: the collector ignores pointers outside its arenas; `checkptr` instruments only
`unsafe.Pointer` -> `*T` conversions and arithmetic, of which there are none (the system writes the pointer);
`go vet` is clean. The `[32]uintptr` table type is only indexed at 2-20 for the dialog and 2-5 for the item, inside
each real table. The arguments go through `syscall.SyscallN` (stack array, not `LazyProc.Call`'s heap array) and
the toolchain carries the KeepAlive line of FINDING-CORE-crash-28: the hazard of that finding does not apply.

The thread: locked and never unlocked; the goroutine ends after sending its answer, so the thread exits (or is
parked, M8); one box at a time (`systemBox.busy`), so at most one such thread exists, and only one stays if a
box never returns.

## Owner window and foreground

- `makeOwner`/`toFront`/`endOwner` are sound on every path I traced: the attach is undone right after the one
  call; a foreground window that dies in between makes the attach or the call fail, which falls through to the
  plain `SetForegroundWindow`; `IsWindow(prev)` guards the give-back (a reused handle is possible but very rare).
- `SetForegroundWindow(prev)` at the close: the box can only be closed by interacting with it, so the box thread
  holds the foreground then, and gives it to the window that was in front when Choose was pressed (the browser,
  where the page is): what is wanted. With decided fix 3 (closed from the page), the browser is already in front
  and the call is refused harmlessly.
- A topmost box that cannot take the keyboard (way 3): seen over everything; the owner clicks it once. The page
  meanwhile is the box view, which has no buttons, so keys pressed in the browser do nothing harmful. The box
  has no taskbar button and no Alt+Tab entry (owned by a tool window): if another topmost window covers it, it
  cannot be found, which decided fix 3 answers.
- The 1x1 alpha-0 owner is disabled while the box is modal; at most one pixel at the browser's centre ignores
  clicks for the box's life. Nothing is left behind on any path (and the thread's end would destroy it anyway).
- The author's three runs measured "not in front" with a low-integrity packaged shell window
  (`Windows.UI.Core.CoreWindow`) in front. I believe the mechanism (input attachment across integrity levels is
  refused, and a plain `SetForegroundWindow` from a background program too). It may also mean the session was
  locked at 08:10 (the lock screen is such a window), in which case those runs say nothing about the owner's
  case. Either way only the owner's first log line settles it.

## The page's side

- **Another site cannot open a box**: a cross-site or same-site POST (another port of 127.0.0.1 is "same-site")
  is refused by `Sec-Fetch-Site` and `Origin`; the token (128 random bits) is only in the page, which another
  origin cannot read or frame (`X-Frame-Options: DENY`, `frame-ancestors 'none'`); the Host check stops DNS
  rebinding; a multipart body leaves the token empty. A local program can read the page and post: that was true
  of Save before and is not new.
- Wrong token, other origin, old view, GET (`/act` GET redirects to `/`): no box (tests and reading).
- Two tabs, refresh during the box, the view's own refresh racing the close: consistent (one lock; `render`
  reads the view and its number separately, which can only show the box view one extra refresh).
- The typed values: kept exactly (not trimmed) in `openBox.typed`, put back in the setup view on chosen,
  cancelled and failed, let go from `u.box` under the lock; they then live only in the setup view until the next
  view replaces it. Lost only in M1's race and in S3's crash.
- Enter in a field: the form's first submit button in tree order is the clip-hidden Save (not `display:none`), so
  implicit submission presses Save in Chromium, WebView2 and Firefox, never a Choose. A crafted form with two
  `do` values is read by `PostFormValue` (the first only): one action.
- A save, close or retry while a box is open: refused (retry exists only outside the setup). The launcher cannot
  be ended from its page while a box is open; a Windows end of session or `taskkill` (WM_CLOSE to the box) closes
  the box as a cancel and the launcher goes on as usual.

## What a choose does beyond showing a box

Reads: `os.Stat` of the typed start folder (unbounded today: decided fix 2), `os.Stat` of the program folder,
`SHCreateItemFromParsingName` on the start folder (network when it is a share), the shell's own browsing, and
after the close `os.Stat` + `GetDiskFreeSpaceEx` of the chosen folder (chosen in the box, so reachable).
Writes: the write check's temporary file in the chosen folder (decided fix 1); the dialog's MRU and possibly
Recent items (M7). Folders made: none (probe: no data folder made; `TestChooseKeepsTypedAndSavesNothing`).
Programs started: none. Network: none of the launcher's own. Settings: unchanged byte for byte (test).
Relative form (`formPath`): probe `TestProbeG10FormPath`, 9 invented cases, 0 differing from what is right: inside
(also with other letter case) gives a relative path; a sibling with the same prefix (`app2`), another drive, a
share, the parent and the folder itself (with or without a trailing separator) stay as chosen; `..x` inside stays
relative and is allowed. Not right only when the program folder is reached through a junction or a mapped drive
(`FindFolder` resolves links): the path then stays absolute, which is harmless.

## Privacy and logs

The two new formats carry numbers only (`TestChooseNoPathInLog` and `TestLauncherLogNoPathsOrNames`); every
refusal and error text is a constant; `BoxError` prints numbers only; the box's titles are constants; no panic
value is printed; a crash's traceback prints arguments as machine words, not strings. The only place a chosen
path goes is the form's input (escaped). Sound.

## The look

One `<style>`, exactly `pageStyle`, allowed by its hash; no script, no `src`, no `url(`, no inline style, no
handler, on all seven views (test, and read). Every value put into the page (folder paths, adapter names, error
words, the collector's path, the pages' address) goes through `html/template` actions, escaped by context; the
words concatenated into the template's own text are constants with no `<`, `&` or `{{`. Narrow widths: the
author measured 375 px; by reading nothing forces a width (`min-width:0`, wrapping `.pick`, `overflow-wrap`);
the `.enter` button is absolutely placed 1x1 and clipped. The drift test fails when a colour drifts (M10 for its
reach).

## Sentences on the pages that are not true of the code

1. `wordHelpData`: "…By default the folder named data inside the program's folder, made when you save." At a
   first start that folder already exists while the setup is shown (`setCur` makes `data\logs` for the log):
   probe `TestProbeG10DataMadeBeforeSave`, true. Say "made at the first start if it is not there".
2. `wordBoxFailed`: "could not be opened" also for a box that opened and gave no folder (M4).
3. `wordBoxOpenThen`: "This page goes back to the setup by itself when the box is closed" is not true for a tab
   that got the bare refusal (S1).
4. The "missing" error box after the missing folder was chosen (M3): true of the saved file, misleading on the page.
5. `wordHelpInside`: true except for a program folder reached through a link (above; harmless).

Not checked against the other programs (outside this piece): `wordHelpStaging` "from there they are copied to
the library" (copied or moved?) and `wordHelpAdapter` "the collector's route to Telegram must leave through it".

## The tests

- No test judges on real time; every wait is bounded by `bound` (60 s) or the real test's 5 s and 1 s.
- The three mutations of the report, applied by me in overlays: the act's one-box check off ->
  `TestOneBoxAtATime` FAILS ("409 not now", on words, see M2); the token check off -> `TestChooseGuarded` FAILS
  ("a wrong token: 303"); `u.box = nil` removed -> 6 tests FAIL (close or a later choose: 409). The choose's own
  box check off -> every test passes (M2). The drift mutation (`--surface` changed) -> `TestLauncherStyleMatchesAppTokens` FAILS.
- `TestRealFolderBox`: its skip is safe (only `TGARCHIVE_REAL_FOLDERBOX` exactly "1" runs it; no whole run sets
  it). I did not run it; it was matched once by my baseline `-run` pattern and reported SKIP (the variable unset).
- Test functions of the base removed by the difference: 0 (`git diff dbca91d4 1a7c0be4 | grep -c '^-func Test'`).
- Baseline: the nine named tests of the change PASS (1.4 s).

## What only a person at the PC can check, and how

Do these on the owner's PC with a fresh folder from the branch, the browser in front, the launcher's log open
afterwards (`data\logs\` launcher log). Each choose writes one line
"launcher: the folder box of folder N closed: outcome O, step S, code C, in front by way W, after T s".

1. Press Choose beside the library with the browser in front: the box appears over the browser, near its centre,
   and you can type in the box's folder field **without clicking it first**. The log says way 1 (or 0/2). Way 3
   means "seen, but the keyboard stayed in the browser"; way 4 "no owner window".
2. The box's text is sharp, not blurred, on a display scaled above 100% (S2).
3. "Network" is in the box's left pane; a share on the NAS can be opened and chosen; a mapped drive too; the path
   in the library box afterwards is the one Windows names (`\\NAS\share\…` or `Z:\…`). A share that asks for a
   sign-in shows Windows' own prompt.
4. After choosing: the browser is in front again, and the setup returns within about 2 s with the folder in its
   box, the other fields as typed (outcome 0). After Cancel: outcome 1, everything as typed.
5. Enter in a folder field presses Save, not Choose: try it with the staging field emptied, so the save is
   refused with "A folder is needed here." instead of starting the app.
6. No `launcher-crash.log` appears in `data\logs` after a few chooses (S3).
7. With the box open, refresh the page and open a second tab: both show "A folder box is open…"; pressing a
   button in an older tab shows the bare refusal (S1, until fixed).

## For the window piece

- The page needs nothing new in WebView2: forms, 303s, meta refresh, the hashed style, `prefers-color-scheme`
  (follows the profile's preferred scheme), `Origin` and `Sec-Fetch-Site` sent as in Chromium. Keep
  `Referrer-Policy: same-origin`.
- When the window is another process, the launcher is still a background program for the foreground rules:
  either keep this owner window, or have the window process (foreground when Choose is pressed) call
  `AllowSetForegroundWindow(launcher's pid)` when it sees the POST of a `choose-*` (WebView2's NavigationStarting),
  so the launcher can take the foreground without attaching input. Do not pass the window's HWND from another
  process as the box's owner: a cross-process owner joins the two threads' input queues, so a hang of either
  hangs both.
- The window program is per-monitor DPI aware; the launcher is not (S2): the box should match.
- A box closing gives the foreground back to the window that was in front when Choose was pressed: in the window
  piece that is the app's window, as wanted.
- The bare-text refusals (S1) would show as a plain text page inside the window with no browser address bar to
  get back: fix S1 before the window piece.

## What I checked and found sound

Every COM index, argument order, GUID and constant (table above); release on every path; apartment balance with
S_OK, S_FALSE and RPC_E_CHANGED_MODE; strings kept alive; no `LazyProc.Call` (heap-array hazard avoided); the
owner window's lifetime; input attachment undone; the page's guards (origin, site, token, view number, host);
the one-box layers; typed values kept on chosen, cancelled and failed; no path in any log line or error text; the
style policy and escaping; the relative form of a chosen path in 9 cases; the failed save now keeps what was
typed (`launcher.go` 418, 426); the setup loop untouched; no test of the base removed; `gofmt` and `go vet` clean.

## What I did not look at

I did not open or look at the pages in a browser, at desktop or phone width, light or dark; I opened no box and
did not run `TestRealFolderBox`. I built nothing with `-d=checkptr` (reasoned instead: no instrumented
conversion exists on the box path). I did not compare `parts.css` rule by rule with the launcher's copy, did not
check the collector's staging or adapter behaviour against the help sentences, and did not read the window or
viewer tracks' code. The whole package was not run (named tests only).

## Second pass (3879e627)

Same rules as the first pass: read-only (`git status` empty before and after), probes and mutations by
`go test -overlay` from `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g10-scratch` (files `p2\`,
`stuck\`, `m2*\`, `ov2-*.json`), the toolchain of `ix-tools/env-archiver.sh`, one go command at a time, the PC
measured before each (free memory 4.4 to 5.5 GB, CPU 59 to 81%). Every helper started was the test's stand-in
(no `TGARCHIVE_REAL_FOLDERBOX`): no window, dialog or program was opened on the desktop and no input was sent.
No test process or helper was left afterwards (0 `launcher.test.exe`, 0 `tgarchive.exe`). `go vet
./internal/launcher ./cmd/tgarchive-open` clean; `gofmt -l` empty; test functions of the base removed: 0. The
20 named tests of the change pass (2.4 s); no `TestRealFolderBox*` was matched.

**Verdict: may be listed after these fixes** (one must-fix, two should-fix, small minors).

### The first pass's findings

| finding | state | where |
|---|---|---|
| Decided 1: a choose's checks read-only | fixed | `choose.go` 165-172 call `folderFacts` (`ui.go` 649-666, Stat only); mutation back to `folderWords` caught |
| Decided 2: the start folder's look bounded | fixed | `folderbox_helper.go` 141-162 and 183 (one 2 s deadline for both; past it no start folder, so no `SHCreateItemFromParsingName`); the launcher looks at no folder (`startOf`) |
| Decided 3: Close the folder box | fixed in part | `ui.go` 304-308, `choose.go` 90-105: only that view's press, the setup back at once as typed, the helper ended by Go's handle; but see MF1 (a helper that ends late is held for ever) and SF1 (a second press) |
| S1: bare text on a press during a box | fixed in part | while a box is open every press is a 303 and the box's view says it once (`ui.go` 304-316, `take` 383-405); a press of a view that has just ended is still a bare 409 (SF1) |
| S2: DPI | fixed | `folderbox_windows.go` 135-152: `setDPIAware()` is evaluated as an argument of `helperMain`, before any window or COM call, on every path; a missing or refused call returns -1/0 and the box goes on |
| S3: faults kill the launcher | fixed | the box, its COM and the shell's extensions live only in the helper process |
| M1: save and choose from two tabs | fixed | `take` sends and marks busy in one lock; nothing waits under it (the send is a non-blocking select; `Abort`, `afterBox` and every disk read are outside the lock) |
| M2: the choose's own check untested | fixed | `TestChooseOwnBoxCheck` (mutation caught) |
| M3: "missing" after choosing it | fixed | `choose.go` 162-164 |
| M4: "could not be opened" when it opened | fixed | `wordBoxNoFolder` for steps 9-11 (`choose.go` 175-176); still "could not be opened" for step 23 (m6) |
| M5: the real test's rectangle | fixed | `folderbox_windows_test.go`, origin and size of the virtual screen |
| M6: minimised front window | fixed | `folderbox_windows.go` 311-317 (`IsIconic`) |
| M7: Recent items, MRU | fixed in part | `FOS_DONTADDTORECENT` (211); the dialog's own MRU is said in the report (cannot be turned off without a client GUID store; acceptable) |
| M8, M9, M10 | fixed | comment; the way and the DPI come with each answer; the drift test's comment |
| Untrue sentences 1 and 2 | fixed | `wordHelpData`, `wordBoxNoFolder` |
| Untrue sentence 3 (S1) | fixed in part | as S1 |

### Must fix

**MF1. A helper not seen to end within 10 s holds the box's slot for the launcher's whole life, and its chosen
folder is dropped — CONFIRMED (probe, with the bound shortened); the trigger with the real 10 s PLAUSIBLE.**
`helperbox_windows.go` 135-146: after the answer has been read, the launcher closes the helper's input and waits
5 s for its end, kills it, waits 5 s more, and then `return boxFail(23)` **without `letGo()`**. The goroutine at
131-134 still sees the helper end later, but nothing then lets go of `b.cur`. Probe `TestProbe2StuckSlot`
(`helperEndBound` set to 1 ms in an overlay so that an ordinary helper counts as "late"), twice: the helper had
answered `chosen`; the first box returns step 23 (the folder dropped, the page says "could not be opened"); the
helper has really ended; the slot is still held; the next Choose returns step 1 and starts nothing; `Abort`
returns false. With the real bound, one sequence: the owner has typed the library as a NAS share that is not
connected and presses Choose; the helper's `os.Stat` of it blocks in the network redirector; after 2 s the box
opens without a start folder, as designed; the owner chooses a folder within a few seconds; the helper writes
`chosen …` and calls `os.Exit`, but the process cannot finish ending while one of its threads is still inside
that network call (the same blocked look the 2 s bound walks away from), which can last longer than 10 s. From
then on every Choose of that launcher says "The folder box could not be opened on this PC" until the owner
restarts it, and the folder just chosen is not in its box. Smallest change: on that path, start
`go func() { <-exited; letGo() }()` before returning (with `letGo` made idempotent by a `sync.Once`, since it
closes `run.ended`), and return the parsed answer when `line` was a valid one instead of step 23 (the slot still
waits for the real end). `Abort` then also returns true once the helper ends. Correct the report's "until it
does" (233-234) and "stays held" (57-61) to match.

### Should fix

**SF1. A press of a view that has just ended is still a bare 409 text page — CONFIRMED (probe).** `ui.go`
317-319 (the view-number check, unchanged) answers `http.Error(w, wordNotNow, 409)`. Probe
`TestProbe2DoubleCloseBox`: the first press of "Close the folder box" 303, the second press of the same page
409, plain text (no html, no refresh). Sequences: a double click on "Close the folder box" (`closeBox` waits for
the helper's end before its redirect, so the page is still there for the second click); or the owner cancels
the box and then, within the box view's 2 s refresh, presses "Close the folder box" that is still on the screen.
Either way the browser shows "not now: the page changed; reload it" as text, and in the coming window piece
there is no address bar to get back. Smallest change: a press that passed the origin and token checks but names
an older view is answered `303 /` (the current view), at least for `close-box`; the refusal stays a refusal.

**SF2. A folder chosen in the same instant as "Close the folder box" is dropped without a word — CONFIRMED
(probe, 12 runs of 12).** `choose.go` 90-100 puts the setup back as "closed from the page"; `waitBox` (77-79)
then finds `u.box != b` and throws the chosen answer away; the helper box's `Choose` (151-153) also prefers
"aborted" over a valid answer already read. Probe `TestProbe2CloseRacesAnswer`: the fake box answers `chosen`,
then the close is pressed at once: folder put in 0, dropped silently 12, refused 0. The window is the time
`waitBox` spends reading the chosen folder's facts and free space before it takes the lock (milliseconds
locally, longer on a NAS share). Sequence: the owner chooses in the box, the browser comes to the front still
showing the box's view with its button, the owner presses "Close the folder box"; the setup returns without the
folder. Smallest change: `closeBox` remembers the number of the setup view it put back; `waitBox`, finding
`u.box != b` with a chosen answer and that view still current, puts the folder into it (or at least says one
sentence); and the helper box returns a valid answer it has read even when aborted.

### Minor

- **m1. `Abort` ends whatever helper is current, not that box's — PLAUSIBLE (two tabs, tight timing).**
  `closeBox` lets the page's box go (lock) and only then calls `Abort` (`choose.go` 101); if box 1's helper had
  just let go of the slot and another tab's choose started box 2's helper in between, `Abort` kills box 2.
  Change: `Choose` hands out its run, and `Abort(run)` acts only on that run.
- **m2. After an `Abort` that returned false the next Choose says "could not be opened on this PC"** while the
  old box may still be on the screen (step 1). Say "A folder box is still closing on this PC; try again in a
  moment." for step 1.
- **m3. The step-23 sentence.** A helper that dies after its box was shown (a fault in an extension) is said as
  "could not be opened" (`outcomeOf`, `folderbox.go` 115-121). Use the neutral wording for 23.
- **m4. `parseAnswer` takes a relative path** (probe: `chosen 1 1 relative` accepted) and a path longer than
  64 KB of UTF-8 is step 23 (a 30 000-character path of three-byte characters is 90 KB; only with Windows' long
  paths). Check `filepath.IsAbs` on a chosen path; the limit is acceptable. Everything else of the form behaved
  as it should in 16 cases (spaces, a trailing space, non-ASCII kept; NUL, no path, an empty path, out-of-range
  front, DPI, step and code refused; a path that is a protocol word is only a path). Nothing of the answer but
  the range-checked numbers reaches the log.
- **m5. "Nothing is started" now has an exception.** A choose starts a program (the helper); `wordSetupIntro`
  ("Nothing is started … until you press Save and start") and the comment of `choose` ("Nothing is saved,
  written or started by a choose") should say "nothing of the app".
- **m6. If `StdinPipe` succeeds and `StdoutPipe` fails** (`helperbox_windows.go` 92-97), the stdin pipe's two
  handles are never closed. Practically never; close `stdin` on that path.
- **m7. `TGARCHIVE_REAL_FOLDERBOX=1` in the shell makes every helper test open the real box**, the "hang" ones
  too (`standin_box_test.go` 23-25), not only the two real tests. Whole runs stay safe (the variable is never
  set); say it in the real test's comment.

### Checked and sound in the rebuilt parts

- **`Choose` and `Abort` on every path.** An abort before `run.proc` is set marks the run and `Choose` kills the
  helper right after its start; between the start and the write the write fails (22, reported as aborted);
  during the read the pipe closes; after the answer `Kill` on an ended helper is harmless. `Kill` acts on the
  handle Go has held since `CreateProcess` until `Wait` has finished (afterwards it returns "already finished"),
  so a process number Windows has given to another process can never be hit. The reader goroutine ends when the
  pipe closes (the helper's end, or `Wait` closing it); the waiting goroutine ends with the helper. A helper that
  writes megabytes or never a newline is cut at 64 KB (step 23) and then ended by its closed input or `Kill`; one
  that answers and does not end is ended by its closed input, then by `Kill` (MF1 for the rest). The request
  goes only on standard input, never a command line. Standard error is the null device; only the two pipes are
  handed to the helper.
- **The helper's side.** A request not of the form (unknown key, a line over its limit, input closed early) is
  `failed 25`, exit 2, no box. A start folder of any text is only `os.Stat`-ed and handed to the shell only when
  it is a folder. Input closed while the box is open: the reading goroutine calls `os.Exit(3)`, which ends every
  thread of the process, the one inside `Show` with its windows (measured with the stand-in's held box; with the
  real box only `Kill` was measured: `TestRealFolderBoxClosedFromLauncher`). It reads no settings, writes no
  file or log, opens no listener. Started by hand by another program of the same user it shows one box and
  prints one path: nothing that program could not do itself. Started with no input (a double click on the
  program with the argument) it answers `failed 25` and ends without a box.
- **"Close the folder box"** counts only on that box's own view (the token and origin checked first, then
  `view == b.viewN`); the setup is back at the very next look with every field as typed (`TestCloseTheFolderBox`,
  fake box held, passes), and a new choose follows at once.
- **`take`**: the M1 race is closed (the send, the busy view and its new number in one critical section; a
  choose checks the number in the same lock). No helper is waited for under the page's lock.
- **B1 and B2.** `TestChooseWritesNothing` watches the chosen folder (names, folders, sizes, writes, subtree):
  with `folderWords` put back in an overlay it fails ("a choose wrote into the chosen folder"), so it proves the
  launcher's side writes nothing (it does not watch the shell in the helper, which the fake box replaces). The
  bound abandons the look at 2 s; the goroutine left inside the blocked `os.Stat` belongs to the helper process,
  at most one per helper, and goes with the helper, so nothing piles up in the launcher (its effect on the
  helper's end is MF1).
- **The four mutations the report newly claims**, applied by me: the helper box's one-at-a-time check off ->
  `TestHelperNeverTwice` FAILS ("a second helper was started beside the first: 2"); `folderWords` back in a
  choose -> `TestChooseWritesNothing` FAILS; the busy view not set in `take` -> `TestTakeMarksBusyInOneLock`
  FAILS; the choose's own box check off -> `TestChooseOwnBoxCheck` FAILS. All four caught.
- **The pages' changed sentences** are true of the code: the data folder's help ("the launcher makes it when it
  is not there": `setCur` and Save both make it), "or press Close the folder box below" (the button is in the
  actions under the region), the refusal said once on the box's view, the "gave no folder" sentence for steps
  9-11. Exceptions: m3, m5.

### The report at 3879e627: lines not true of the code

- 57-61 "a helper not seen to end stays held, so no second one starts beside it" and 233-234 "every later
  choose is refused … until it does": it stays held for the launcher's whole life, even after it has ended
  (MF1). 59-61 "a new choose is possible as soon as it returns": only when `Abort` returned true.
- 185-186 "No bare-text refusal is left on the box's paths (S1)": a second press of "Close the folder box", or a
  press of it just after the box closed, is a bare 409 (SF1).
- 24-27 "Closed from the page: the page as it was, no sentence": true, but a folder chosen in that instant is
  dropped with it (SF2).
- 61-63 "it cannot outlive the launcher": true of the code by Windows' process end; measured only with the
  stand-in, and the helper's end can be delayed by a thread blocked on a dead share (MF1's trigger).
- The window piece's lines (183-195) and the "only a person can see" lines (171-179) are otherwise true; the
  latter should add two checks below.

### Added for the person at the PC

- With a box open, end `tgarchive.exe` (the launcher, not the helper) in Task Manager: the box disappears within
  a second and no `tgarchive.exe` is left (the helper ends on its closed input).
- With the library typed as a share that is not connected, press Choose: the box opens after about 2 s; choose
  a local folder at once; the folder is in its box and a second Choose still opens a box (MF1, after its fix).

## Third look (a142c68d)

Only the five points asked. Same rules: read-only (`git status` empty after), overlays from the scratch folder,
named tests, the PC measured before each go command (free 5.2 to 5.5 GB, CPU 67 to 76%), only the stand-in
helper (no window, dialog, program or input), no test process left. Passing at a142c68d:
`TestHelperLateEndLetsGo`, `TestHelperAbortOwnBoxOnly`, `TestCloseKeepsAFolderJustChosen`,
`TestBoxFailureSentences`, `TestCloseTheFolderBox`, `TestOneBoxAtATime`, `TestHelperNeverTwice`,
`TestHelperBoxAnswers`, and my second-pass probes re-run (`TestProbe2DoubleCloseBox`: second press now 303;
`TestProbe2CloseRacesAnswer`: folder put in 12 of 12). **Verdict: may be listed.**

1. **MF1: sound.** `helperbox_windows.go`: `letGo` runs inside `run.once` (so at most once), and on every path it
   runs exactly once: pipe failure (118), start failure (123), the normal end (179, which covers a failed write,
   an abort before or after the start, and an abort during the wait, since each of those ends the helper and
   `Wait` returns), and the late path, through the goroutine at 169-172 once `exited` closes. An abort before
   `Choose` takes the slot starts no helper and takes no slot (the `abortedID` check under the same lock). The
   new goroutine stays only while `cmd.Wait` has not returned, i.e. only while the helper process itself has not
   ended; then the slot, that goroutine and the waiting one stay held, later chooses get step 1 ("A folder box is
   still closing on this PC; try again in a moment."), which is true and keeps no second helper beside a live one.
   An answer already read is returned (173-175, 186-187). `TestHelperLateEndLetsGo` passes; with the let-go at 171
   removed in an overlay it FAILS ("the slot was not let go after the helper ended", after its 60 s bound).
2. **`Abort(id)`: sound for what was asked; one negligible gap.** IDs are the page's `boxSeq`, incremented before
   each use from 1, never reused, and 0 is excluded (`ask.ID != 0`), so a stale `abortedID` cannot refuse a later
   box. An abort for an old id finds `run.id != id` and kills nothing (`TestHelperAbortOwnBoxOnly`). The gap:
   `abortedID` holds one id only. Box 1 closed from the page before its `waitBox` goroutine reached `Choose`
   (abortedID = 1), then box 2 opened and was closed the same way (abortedID = 2), and only then box 1's
   goroutine runs `Choose` (it does `os.Executable`, `EvalSymlinks` and a stat first): box 1 starts a helper and
   opens a box the page no longer knows of. PLAUSIBLE only in theory: it needs two Choose-and-Close presses inside
   the milliseconds before one goroutine is scheduled. If wanted: keep the aborted ids in a small set, cleared
   when their `Choose` returns.
3. **SF2: sound, with one minor edge.** Close first, folder after: `closeBox` puts the setup back with "The folder
   box was closed from this page; nothing chosen in it was taken." and records `closedBox`/`closedN`. `Abort(id)`
   follows. Then `closeBox` waits for `b.done`, and the folder `waitBox` brings is put into that setup (its own
   view has no such sentence): what the owner sees after the redirect is true (probe 12 of 12). Folder first:
   the setup comes back with it, and the close of the old view is a 303 to that page. Double press: the second is
   a 303 (probe). A save taken between them: `take` changes `u.n` under the lock, so `u.n == closedN && phase ==
   phaseSetup` fails and nothing is put into a view that is not that setup. The close's waits (`Abort` up to 5 s,
   `b.done` up to 5 s) hold only that one request: no lock is held across them (`choose.go` 100-121), and other
   requests go on. The edge (minor, PLAUSIBLE): if the helper takes longer than those waits, the owner's page
   already says "nothing chosen in it was taken", and the folder that arrives later is put into the launcher's
   view at the same number without a refresh. A save from that page uses its own fields, without the folder, so
   it stays true for what the owner does; only a reload would show the folder after the sentence. Smallest change
   if wanted: clear `closedBox` under the lock when `closeBox`'s wait gives up.
4. **SF1: sound.** `ui.go` 322-329: a stale `close-box` press is a 303 to the page and does nothing; every other
   stale action keeps its 409 as before.
5. **The real-box switch: sound.** The stand-in runs the real helper only when its own control folder holds
   `folderbox-real` (`standin_box_test.go` 25-30). That file is written in one place, `realBox`
   (`folderbox_windows_test.go` 101), after its `TGARCHIVE_REAL_FOLDERBOX` skip check, and `realBox` is used only
   by `TestRealFolderBox` and `TestRealFolderBoxClosedFromLauncher`. Each fixture has its own temporary control
   folder; no test calls `FolderBoxHelper`, `runBoxLocked`, `systemFolderBox` or `SystemEnv`. With the variable
   set, no other test can reach a real box (reasoned from the code; the variable was not set).
