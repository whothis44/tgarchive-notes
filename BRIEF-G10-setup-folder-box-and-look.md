# Brief G10: the launcher's setup: Windows' own folder box, and the look of the app's pages (pages track, session P4; 2026-11-16 07:49)

For one Opus coder. **The owner opened the folder's program for the first time on 11-16 at 07:40 and said: "Will
it eventually be standalone (i.e. not in a browser), plus the setup screen is ugly and there's no folder
selection boxes, just paths, which looks worse."** The design the owner agreed to on 11-15
(`C:\Users\trabi\Claude\Projects\Telegram\DESIGN-G6-one-folder.md`, point 2) says "a folder dialog"; the page was
built with text boxes. This piece builds the two things that need nothing from anyone else: the folder box and
the look. The third (the pages in a window of the app's own instead of the browser) is a piece of its own that
follows when the viewer track has said what the launcher may call: **build nothing of it here, but build
nothing that stands in its way** (the setup page must work the same in a WebView2 window as in a browser).
"Done" for this piece is the owner opening the folder again; you cannot do that, so say plainly what you saw
and what only a person at the PC can see.

**The routine-steps rule of this project (`CLAUDE.md`, the archiver section, second point) binds you too:**
you run named tests only; the whole runs are not yours.

**Read first, in full:** `internal/launcher/ui.go`, `settings.go`, `folder.go`, `words.go` and the part of
`launcher.go` that makes and changes views (the setup phase and `checkSetup`);
`internal/server/web/assets/base.css`, `parts.css` and `web/index.html` (the app's look);
`DESIGN-G6-one-folder.md` points 1 and 2; `C:\Users\trabi\Claude\Projects\Telegram\FINDING-CORE-crash-28.md`
"In short" (a hazard of raw Windows calls from Go, closed in this project's toolchain by one line: build only
with the toolchain `ix-tools/env-archiver.sh` sets, and never with another Go).

## What is known already (read by the main session)
- **The launcher's page is plain HTML with forms and no script**: its policy is `default-src 'none'` with ONE
  inline style allowed by its hash; every change is a POST of the form with the run's token and the view's
  number, checked for same origin (`ui.act`). Keep all of that. A browser page cannot give a real folder path
  to a program, so the box has to be opened by the launcher itself, on the PC, at the page's request.
- **The old app's interface lessons** (TRIED-BEFORE 10, 15, 19): a control in one place only; every state says
  why in plain words; nothing the owner typed is thrown away by a refresh or an error; a page says when what
  it shows was read.
- **This track's reviews of the launcher** (`archiver/docs/review/pages-g6-launcher-2026-11-16.md` and `-2-`):
  the launcher restarts nothing by itself, a second press is refused while the first is being carried out,
  and a path is never written to a log.
- **The library is a NAS share** (a network path or a mapped drive); staging is a local disk; the data folder
  is by default a folder inside the program's own folder. All three must be choosable with the box, and the
  typed path must stay possible (a share that is not connected yet cannot be browsed to).

## What to build (`internal/launcher` only)
1. **"Choose..." beside each of the three folder boxes** (library, staging, data), as a submit button of the
   setup form itself (no script): it carries every field as typed. The launcher then opens **Windows' own
   folder box** (the modern one: `IFileOpenDialog` with the pick-folders option, file-system folders only,
   network places allowed; not the old tree box), titled in plain words for the folder it is for, starting in
   the box's current folder when that exists. Chosen: the setup page comes back with that folder in its box,
   every other field exactly as it was typed, its checks and "free on its disk" shown for the new value.
   Cancelled or failed: the page as it was, a failure said in one fixed sentence. **Nothing is saved or
   started by a choose**: only "Save and start" does that, as today.
   - The page's request must not hang while the box is open (a person may leave it open for an hour): answer
     at once with a view that says a folder box is open on this PC and for which folder, refreshing itself as
     the launcher's other waiting views do, with the typed values kept by the launcher for that view; the
     setup page returns when the box is closed.
   - One box at a time: a second choose, a save or a close while a box is open is refused in fixed words (or
     queued behind it: decide, and say which), never a second box.
   - **The box must come to the front**, over the browser or the app's window, and take the keyboard: a box
     that opens behind the page is worse than no box. Windows does not give a background program the
     foreground freely: read how to own the box (an owner window of the launcher's, made topmost for the
     box's life, is one way) and build what works; see the real test below.
   - The COM calls live in one file for Windows (`folderbox_windows.go` or the like) behind a small interface
     the tests replace; one goroutine locked to its thread, the apartment initialised and released on it;
     every COM object released on every path; a failure of any call is an error in fixed words, never a
     panic. Other systems: no box and no button (`folderbox_other.go`), the form as today.
   - A chosen path goes into the form and nowhere else: never a log line, never an error text.
2. **The launcher's pages in the look of the app's pages**: the setup page and every status page (starting,
   running, failed, what is left, closed). The same type, colours in light and dark, spacing, buttons, fields,
   notes and error text as the app's own pages (`base.css`, `parts.css`), the app's name at the top as the
   pages show it, the setup as a form that reads top to bottom: each folder with its label, ONE plain
   sentence of what it is for, its box with "Choose..." beside it, its check and free space under it; the
   VPN's adapter; what opens as the viewer; the collector's path for the VPN's list with one sentence saying
   what to do with it; one main button. Narrow widths (a phone's, a small window's) must not scroll sideways.
   - The launcher imports nothing of `internal/server` and keeps its policy: one inline style by its hash, no
     script, no file fetched. So its style is its own text; **a test keeps it from drifting**: the values it
     shares with the app's pages (the colours, the font stack, the radius and spacing tokens you take) are
     read from `base.css` in the source tree by the test and compared.
   - Every label and sentence on the setup page: plain words a person who has never seen the program
     understands; say what each folder is FOR. No sentence may claim what the code does not do.
   - Do not change what the setup asks for, its checks, or what "Save and start" does.

## Tests (named; invented folders under the test's own temporary folder; no test judges on real time)
- With the fake box: chosen (the value in its box, the other fields as typed, including a half-typed wrong
  one, nothing saved: the settings file byte for byte as before), cancelled, failed; a choose for each of the
  three; a second choose, a save and a close while one is open; the page's request answers at once while the
  fake box is held open; a choose with a wrong token, another origin or an old view number opens no box.
- No path in any log line through every path of a choose (a marker folder name searched for in the log).
- The look: the drift test of point 2; the policy's hash still matches the style; the page still has no
  script and fetches nothing.
- **One real test of the real box, skipped unless `TGARCHIVE_REAL_FOLDERBOX=1`** (so that no whole run ever
  opens a box): it opens the real box on an invented folder, finds within 5 s a visible top-level window of
  this process that is the box, records whether it is the foreground window, closes it by its own cancel,
  and expects "cancelled" within 5 s with no window left. Run it yourself three times and report the three
  results (appeared after N ms; foreground yes or no). It shows a system dialog on the desktop for about a
  second each time: nothing else is opened, and you look at nothing on the screen.
- One mutation each: the one-box-at-a-time check, the token check on a choose, the release of the typed
  values after the box closes (which test fails).

## Rules (hard)
- Copy and branch: `git -C C:/Users/trabi/Claude/Projects/Telegram/repo-archiver fetch private`, then
  `git -C C:/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add -b wip/pages-setup ../wt-pages-setup <the head of private/claude/charming-feynman-vm2xia>`
  (dbca91d4 at 07:47; write the exact commit into your progress file). Work only in
  `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-setup`. Do not touch the main checkout's working tree
  (another session has uncommitted work there).
- Product code only in `internal/launcher`. Nothing in `internal/server`, `internal/window`, the viewer, the
  collector, the watchdog, `cmd/`, `deploy/`, `go.mod` (no new module: `golang.org/x/sys/windows` is there).
- **Never start the real program**: not `C:\Users\trabi\tgarchive-app`, not an installed collector, watchdog,
  viewer or window, nothing in the folders `a3`, `b`, `app`; stop no process you did not start. To look at
  the pages, run the launcher's own tests' stand-ins or a build of the launcher from your copy in a scratch
  folder of its own **with stand-in programs, `LOCALAPPDATA` and `APPDATA` pointed into that scratch folder
  for the process**, on addresses nothing of the owner's uses (127.0.0.1:8796 and up), and end what you
  started. Nothing runs against Telegram; never touch `E:\T\tg-dl`, any real catalogue, media, session or
  account.
- New log, error and state text is constant words with numbers: never a path, a name or a folder.
- Go: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, one go command at a
  time, `GOGC=25 GOMAXPROCS=2 go test -p 1 -run '<names>' ./internal/launcher`, named tests only while you
  work (the launcher's whole package once before you hand back is fine: it takes under a minute); no race
  detector, no Docker. Before each go command:
  `powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`;
  wait when free memory is under 2.5 GB or the CPU is over 85%. Every wait in a test has a bound.
- **Open it before handing back**, in the built-in browser if you have one, at desktop and phone width, light
  and dark: the setup page empty, filled, with a wrong folder, with the "a folder box is open" view (the fake
  box held), each status page; and beside it one of the app's own pages (`tgarchive app -demo` built from
  your copy on an invented catalogue, 127.0.0.1:8799) to compare the look. Say exactly what you saw and what
  you did not.
- Before handing back, list the test functions your difference removes against your base
  (`git diff <base> HEAD | grep '^-func Test'`) and account for each: the expected count is none.
- Any file that holds a Windows path is written with the file-writing tool, never from inside a shell or
  script string.
- Commits: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; commit work in progress as you go and push only
  `git push private wip/pages-setup`. Never push, merge into, rebase or switch any other branch; never stash.
- Keep `archiver/docs/progress/pages-setup-PROGRESS.md` current from your first action and commit it with
  each step.

## Hand back
Commit-ready: everything committed and pushed, the tree clean, `gofmt -l` clean, `go vet ./internal/launcher/`.
`archiver/docs/progress/pages-setup-REPORT.md`: what was built against each point; how the box is owned and
brought to the front, and the three results of the real test; every Windows call made and how each object is
released; what a choose does to the launcher's views, step by step; every test and mutation with its result;
what you saw in the browser and what you did not; **what only a person at the PC can see** (the box over the
window, the keyboard in it, a network share in it); what the window piece must know (anything in these pages
that a WebView2 window would treat differently from a browser); anything in this brief you found wrong; the
changed files; a drafted final commit message. Your final message: the head commit and the base it sits on,
what is built and tested, what is not, every departure, and your doubts, plainly.
