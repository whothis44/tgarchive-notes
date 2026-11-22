# Brief G1: one program to open (pages track, session P2; 2026-11-15)

For one Opus coder, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-g1` on branch `wip/pages-g1`
(made for you from the main head f0e3f0c; change no branch). Go module in `archiver/`. Commit work in progress as
you go (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, messages starting `WIP pages: `,
ending with a blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`) and push with
`git push private wip/pages-g1`; never `origin`, never the main branch, never a force-push.

## The owner's words, and what "done" means
The owner, 11-15 15:15: "How are we doing with overall progress? Remember we want a functional app, with a GUI."
Today `tgarchive app` serves Overview, Chats, Queue, Settings, Accounts and Import from a catalogue with nothing
behind its `Live` seam, and the collector is another program started from PowerShell scripts. **G1: the collector
serves those pages itself, from its own catalogue handle (one process, one writer), and the pages start and stop
it.** Done is not yours to reach: it is the owner double-clicking a starter, seeing the real test catalogue's
chats and queue, and starting and stopping collecting from the page. Yours: everything up to a branch that is
commit-ready, with a way for the main session to open the pages in a browser over a collector that runs against
the fake Telegram on invented data (section 7).

## What the old app already knows (read by the main session in full; numbers are the old app's unless said)
- **A poll must be cheap, not slow.** The old dashboard polled every 250 ms; two COUNTs per poll read 62.6 MB
  each, about one core; an EXISTS and a covering index took the CPU from 205-250% to 82-139% and the reads from
  514-716 to about 200 MB/s. The owner rejected slowing the polls to 2 s: the fix was to make each poll cheap
  (TRIED-BEFORE 15, LESSONS 5). Here: the 2 s poll reads **no table**; counts over the archive are worked out
  again only when the catalogue's change key moved and at most every 5 s (this track measured 1.6 to 1.9 s for
  every chat's counts at 300,000 messages: `notadded.go` `coverages`).
- **Every action is one indexed statement.** The old batch Pause of about 1,000 files timed out: each file was a
  scan of 361,378 rows, and a timeout left half the items changed (LESSONS-ix12.30 6b). Long writes are chunked
  so the writer is never held for seconds: one failed statement on the single writer once cancelled every
  download in progress (TRIED-BEFORE 21, A3).
- **"Stop taking new work" is its own state; it never touches a file's held or aside state** (TRIED-BEFORE 19:
  clearing a queue-wide pause released held copies). **A person's pause is never undone by the app**
  (TRIED-BEFORE 24, rule 1), **a stored mark that cannot be read fails closed** (rule 13), a "busy" flag is
  released with `defer` (rule 8), a cancel that only flags a job left it "running" and a second start handed back
  the same job (TRIED-BEFORE 18): "stopping" and "stopped" are told apart, and a Start during the stop is kept.
- **A stop must end in seconds whatever Telegram does** (the old update drain of 20 minutes failed under the
  speed limit until 12.27). The collector's stop is ordered already; this piece reuses it and adds no other.
- **One vocabulary, one place for each control, every state says why in plain words, show the age of the data,
  no control that does nothing, a refused click keeps its message** (TRIED-BEFORE 10, 15, 19). A page that
  could not refresh once showed "no progress for 55 min".
- **A blank page reads as "doesn't work at all"** (the old viewer: 9 to 77 s of silence while it built its
  index; LESSONS-viewer-ix12.32 3 and 4): show "Starting... N s". A browser has about 6 connections per host:
  no request a page depends on waits for slow work.
- **No Telegram request from a click without its cost shown first; what a click already fetched is kept and
  not asked twice** (TRIED-BEFORE 4, 24, 26 rule 5). A media or message count is never shown as a size
  (TRIED-BEFORE 26: wrong by a factor of 4).
- **Download only what the owner chose; what the app adds is marked as the app's** (LESSONS-ix12.30 6b; brief K1
  on `wip/core-chosen` builds the rule; this piece is its page).
- **The shared log is numbers and fixed words only**: the old report leaked name fragments four times and was
  fixed by a guard test that feeds every log format with hard invented names (TRIED-BEFORE 11, 18).
- The VPN rule is by program name: the collector's installed name is the one under it, so the pages must be
  served by that program, and the viewer stays another program (TRIED-BEFORE 14).

## What exists (read these before writing anything)
- `cmd/tgarchive/app.go` (the `app` command), `internal/server`: `server.go` (Config, guard, routes, `handleRun`),
  `live.go` (`Live`, `Snapshot`, `Lane`, `offLive`, `ErrNotConnected`), `overview.go`, `queue.go`, `chats.go`,
  `notadded.go`, `topics.go`, `accounts.go`, `settings.go`, `importer.go`, `demo.go`, `web/assets/js/*`.
- `internal/collector`: `command.go` (`RunCommand`), `collector.go` (`Config.AllowIdle`, `Run`, the start and
  stop order in the package comment, `c.ready`), `account.go` (`Accounts`, `LaneStats`, the account's `loop`,
  the `ending` values, `ClearFrozen` as the pattern of an owner's action), `reader.go` (`EstimateRead`,
  `ApproveRead`), `approve_cmd.go` (the console's fixed words for every outcome of an estimate),
  `signin.go` (not used in this piece), `lock.go`. The collector was written with these calls for a page.
- `internal/engine/counters.go` `LaneStats`.

## What to build

### 1. `tgarchive-collector run -pages`
- Flags: `-pages` (off by default: without it `run` is exactly as today), `-pages-addr` (default
  `127.0.0.1:8787`; the host must be 127.0.0.1), `-viewer-url` (optional: the viewer's address shown as the
  link for this run; empty keeps the stored setting). No flag opens a browser: the collector starts no process.
- Order: flags checked; **the page's address bound before anything else** (in use: fixed words naming the
  address, the refused exit code, nothing sent); the pages' own lock `server.AcquireLock` taken as well as the
  collector's (so `tgarchive app` cannot write the same catalogue beside it); then as today. With `-pages`,
  `AllowIdle` is on: with no signed-in account the program serves the pages and says so on them.
- **From the bind until the collector is ready** (`c.ready`: the catalogue open, recovery and the staging sweep
  done) the address answers a small page "Starting... N s" that asks again by itself, and every `/api/` route
  answers 503 with fixed words. Then the real handler. If `Run` ends before it is ready, the program exits as
  today and the page says nothing more (the starter shows the log's last line).
- **The stop: the pages first, then the collector.** On Ctrl-C, SIGTERM or the page's Quit: no new request is
  taken, requests in flight get a bound (3 s), and only then is the collector's context ended; the collector's
  own stop is untouched. No handler may run on the catalogue after the collector began to close it: a named
  test with a handler held open across the stop.
- The catalogue handle: a new exported accessor on the collector (in a **new file**), nil before ready and
  from the moment the stop begins. The server's start-up settings (`settleSettings`) get no `-library` in this
  mode (the collector's own rule about the library stays the only one). **`RecoverActive` is never called by
  the pages in this mode** (the collector's supply did its own recovery; calling it would give back files that
  are downloading): a named test.
- Quit: `POST /api/quit` (guarded like every change) ends the program the way Ctrl-C does. `tgarchive app` has
  no such route (404) and no button.

### 2. The owner's Stop and Start, per account, on record
- `Collector.StopAccount(ctx, account)` and `StartAccount(ctx, account)` in a **new file**; account 0 is every
  account, one at a time, each result kept.
- Stop: a memory mark first (as `frozenMem`: a record that failed cannot make the account dial again), then a
  settings row `collector.owner_stop.<account>` with the time (one row per account), then the running session
  is asked to end with a new `ending` value through the existing `signal` (the session's ordered stop: the
  engine gives its files back with no attempt spent, then the reader and the monitor end, the counts are
  written, the client is closed). Nothing else is stopped by another path. If the row cannot be written the
  account still stops for this run and the answer says, in fixed words, that it will start again at the next
  start of the program.
- Start: the row removed first (cannot be removed: stays stopped, the error told), the memory mark cleared,
  the account's loop nudged.
- The account's `loop` (account.go; **the fewest lines that do it**): at the top of every turn, before the
  sign-in and frozen checks' dial, "stopped by the owner" is checked (memory mark or the row; **a row that
  cannot be read counts as stopped** and is tried again after the pause, state in fixed words); a new
  `AccountState` "stopped by you" with the time as its why; it waits for a nudge. After a dial that came back
  while a Stop arrived, the check is made again before the session starts (the connection closed, nothing
  else sent). Nothing but the owner's Start clears it: not a sign-in, not `ClearFrozen`, not the gate, not a
  restart of the program.
- **Whatever is clicked, an account never dials twice within `GateRetryMin` of its last session's end**: a
  Start inside that time waits the rest out (state "starting in N s"), not cut short by a nudge. (The redial
  pause exists because a connection that asks too soon after another may be closed: TRIED-BEFORE 27.)
- No file's state is touched by Stop or Start beyond what the session's stop does already (active files given
  back). Held, aside, wanted, kept-held stay as they are: a named test counts the rows by state before and
  after.
- Stop answers at once; the state goes "stopping" then "stopped by you". Bound: the session's own
  (`closeBound`); say in the report what the rig measured.

### 3. The `Live` seam filled, and the cheap poll (`internal/server`, and a new small package for the adapter)
- The adapter (new package, e.g. `internal/collector/livepages`; it may import `collector`, `server`,
  `engine`; **`internal/server` must not import the collector or the Telegram package**: keep the wall, add a
  test for it) implements `server.Live` over an interface of the collector's calls, so its mapping is tested
  with a fake and no Telegram.
- `Snapshot`: mode `live`; per account its state in the collector's fixed words, the why, whether the owner
  stopped it and when; `Running` = not stopped by the owner and signed in. Lanes from `LaneStats`: window, in
  flight, sleeping, files active, limited or not, the state words, both speeds, the last answered part's age,
  the gate's end, network away, cannot write. **A field the engine does not give is left out, never shown as
  0** (extend `server.Lane` with optional fields; the page shows a dash). The small and large slots in use and
  the last wait come from the engine only if it has them: do not add counters to the engine for this piece.
- One verdict line for the whole program from the snapshot alone, in fixed words with numbers: collecting (N
  accounts, M servers downloading), waiting for the VPN check (its reason), stopped by you, no account signed
  in, frozen, signed out by Telegram, starting, closing.
- **A new route `GET /api/live`: the snapshot and the verdict, reading no table.** The pages' 2 s timer uses
  it and nothing else. Totals, the hourly chart, the estimate and the chats' counts are asked again only when
  a change key moved (`CountsKey`, as `coverages` does) and at most every 5 s. Named test: a counting wrapper
  shows `/api/live` runs no statement; another shows a page left open for a minute at 300,000 invented files
  runs a bounded number of statements (judge by statements and rows, never by seconds).
- Every page shows the age of what it shows ("as of HH:MM:SS"), and when the program stops answering the top
  bar says so with the time of the last answer instead of going quiet.
- `ErrNotConnected`'s words are false now. In `tgarchive app` they become: "Not connected: these are the pages
  alone. Open the program with its starter to connect." Change every copy (Go and JS) and the tests.

### 4. What each change route does while the collector runs (the risky part: read every handler)
Write this as a table in the report: every non-GET route, the catalogue calls it makes, whether it leaves an
action for the supply to settle, and its rule in this mode. Decided already:
- Allowed as they are, each proven on the collector's rig (section 6): ranks and order, what a chat collects,
  topics, retry a set-aside file, release or keep a held file, theme, the viewer's address, an account's label.
- **Library folder: refused in this mode** (the store runs on it), in fixed words, the field shown disabled
  with the sentence. Every other setting says beside it when it takes effect (now, at the account's next
  connection, at the next start of the program): find where the collector reads each and say it; a setting
  the collector never reads says so.
- **Import of a list of known files: refused while any account is not stopped** ("Press Stop first: an import
  is one long write"), unless you show by a counting test that it holds the writer under 100 ms a chunk.
- **Mark an account removed: refused unless that account is stopped by the owner or not signed in.** Start is
  refused for a removed account (it is today). An account brought back that this run never loaded: fixed
  words ("it will be used at the next start of the program").
- Hand-over stays as it is (off; the collector does not read it yet: say so beside it).
- The pages' log in this mode goes to the collector's log, which other sessions read: **constant words and
  numbers only: the route's fixed name and an error class, never an error's text, a title, a file name, a
  path or an id.** `s.fail` today logs the error as it is: in this mode it must not. A guard test: every
  route, failing ones included, on an archive whose titles, file names and folders are hard invented words;
  the captured log holds none of them.

### 5. The Chats and Queue pages on a live catalogue
- **Choosing a chat.** A switch on the chat's own row, "Collect this chat's files": `SetChatCollect`. On
  `wip/core-chosen` (not merged) that call settles the files already listed, in chunks, both ways, and a chat
  the collector first meets starts switched off; on your base it acts on files listed from then on only. Build
  the page against the call as it is; the words beside the switch come from a constant you can change in one
  place when the main session says the other branch is merged (it will ask you to merge the new head in before
  the review). A chat switched off shows who switched it off only when the catalogue says (do not guess).
- **"Approve this read, about N requests."** For a chat with no read and no approval, for one account that
  reaches it and is running (the page names the account when more than one could):
  1. If an estimate is on record (the collector's settings row; `notadded.go` reads it already) it is shown
     with its age and nothing is asked. Otherwise a button "Ask Telegram how large it is (1 request)". A
     second estimate for the same chat is offered only when the one on record is over a day old. One estimate
     per chat at a time, and at most one in flight per account (the reader is one call at a time): a second
     click is refused in words, never queued.
  2. Then: "Telegram counts M messages; reading it whole takes about N requests" and a button "Approve this
     read (about N requests)" which sends that N back: `ApproveRead` refuses when the estimate on record is
     another (`ErrNoEstimate`): the page then shows the new one and asks again. Messages are a count of
     messages; nothing is shown as a size.
  3. Every outcome the console words in `approve_cmd.go` has its fixed sentence on the page: refused by the
     chat (recorded, never asked again), Telegram asked to wait S seconds (nothing sent before then; the time
     shown), no access on record, the account is not running ("Start it first"), stopped meanwhile.
  The server reaches these through a second small seam (estimate, approve) that `tgarchive app` leaves nil
  (the buttons are then not shown and the row keeps its present sentence).
- The Queue page asks again by itself while anything runs (the change key, at most every 5 s), keeps the
  lane's own order (`NextWanted`: do not sort it again on the page), and shows per server how many files are
  in transfer now (from the lanes). "Downloading now, just finished, failed with reasons" is the next piece,
  not this one.
- The viewer's link: as today from the stored address, or `-viewer-url` for this run.

### 6. Tests (named; invented data; fake clocks; nothing judged on real seconds)
- Server (fast): `TestLiveRouteReadsNoTable`, `TestOpenPageStatementsBounded`, `TestNotConnectedWords`,
  `TestCollectSwitch`, `TestEstimateShownBeforeApprove`, `TestEstimateNotAskedTwice`,
  `TestApproveWithOldEstimateRefused`, `TestEstimateOutcomesWords` (each outcome), `TestLibraryRefusedWhileCollecting`,
  `TestImportRefusedWhileRunning`, `TestRemoveAccountNeedsStop`, `TestPagesLogNoNames`, `TestQuitRouteOnlyWithProgram`,
  `TestServerDoesNotImportCollector`.
- Adapter (fast): `TestSnapshotMapsStates`, `TestSnapshotLeavesOutWhatEngineLacks`, `TestVerdictWords`.
- Collector, on its rig with the fake Telegram (slow package: **named runs only**): `TestOwnerStopEndsSession`
  (files in transfer given back, no attempt spent, rows by state unchanged), `TestOwnerStopSurvivesRestart`,
  `TestOwnerStopWhileConnecting`, `TestOwnerStopWhileGateRefuses`, `TestOwnerStopUnreadableFailsClosed`,
  `TestOwnerStopRecordFailsStillStops`, `TestStartDuringStopIsKept`, `TestStartNeverDialsTwiceInsideThePause`,
  `TestSignInDoesNotUndoOwnerStop`, `TestClearFrozenDoesNotUndoOwnerStop`, `TestPagesStartingThenReady`,
  `TestPagesAddressInUseSendsNothing`, `TestPagesStopBeforeCatalogueCloses`, `TestPagesNeverRecoverActive`,
  `TestRunWithoutPagesUnchanged`.
- One end to end on the rig, pages over a running collector (`TestE2EPages`): a rank change reorders the
  lane's next claim; retry of a set-aside file and release of a held file get them downloaded; estimate then
  approve of a chat reads it (the fake counts exactly 1 estimate request, then the pages) and its files are
  downloaded; Stop: no request of any kind for that account afterwards (the fake's count stays), Start: they
  resume.
- Mutations, each shown failing a named test, then undone: Stop that only flags (the session keeps asking);
  the owner's stop cleared by a sign-in; an unreadable stop row read as "not stopped"; a Start that dials
  inside the pause; `/api/live` reading a table; the pages calling `RecoverActive`; the library folder saved
  while collecting; an estimate asked twice; an error's text in the log.

### 7. A way to open it in a browser on invented data
`TestPagesHold` in the collector's tests: skipped unless `TGARCHIVE_PAGES_HOLD` names an address
(127.0.0.1:port); then it builds an invented archive with the rig (a few chats never read, a few read, a forum,
files waiting on two servers, one set aside, one held), runs the collector against the fake Telegram with the
pages on that address, prints the address in one line and holds until the test's context ends or
`TGARCHIVE_PAGES_HOLD_MINUTES` pass. The fake answers parts slowly enough that a download is seen moving. No
real account, no real network beyond 127.0.0.1. The main session opens it in a browser and clicks through
before the owner is asked to.

### 8. Side item, its own commit (board message 17)
`internal/catalog/topics_size_test.go` `TestTopicSettleAtSize` judges the topics' counts on one real second and
sits on its bound (0.87 to 1.01 s on this PC). Judge it by what the statements read (rows or the plan) or by a
ratio to a baseline measured in the same run. Tests only; no change to `topics.go`.

## Rules (hard)
- Two unmerged branches also change `internal/collector` (`wip/mirror-auto`: `command.go` flags and three
  places in `RunCommand`, `account.go`'s structs and `runSession`, `collector.go`'s `Config` and one place in
  `Run`, `reader.go`'s `EstimateRead`, `ApproveRead` and `readTurn`; `wip/core-chosen` on top of it: the start
  of `run`, `ApproveRead`, the `chats` and `status` commands). **Put new code in new files; in the existing
  collector files change only: `command.go` (the flags, the bind, the start and stop of the pages around
  `c.Run`), `account.go` (the loop's check, the state, the ending's case).** Not `reader.go`, not `collector.go`
  unless you cannot avoid it (say why in the report), not the engine, the supply, the store, the reader's
  requests, the mirror, the catalogue's schema (no schema step: settings rows only), the viewer.
- No request to Telegram is added except through `EstimateRead` (one, on the owner's click, its cost on the
  button) and what `ApproveRead` and a session's start do already. Nothing here downloads, forwards or deletes
  by itself. Every wait stays the collector's own.
- The pages stay on 127.0.0.1; every change route keeps the guard (same origin, the run's token, POST or PUT);
  the new routes are inside it. No font, script or picture from outside (the existing test).
- New log, error and state text is constant words with numbers: never a name, a title, a path, an id or a text.
- Load: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, one go command at
  a time, `GOGC=25 GOMAXPROCS=2 go test -p 1 -run '<names>' ./internal/<package>`. **Named tests only** while
  working: no whole run of `internal/collector` or `internal/catalog` (minutes each), no race detector, no
  Docker, no `go vet` over many packages: the full runs are the main session's, once, after the review. Memory
  on this PC is short (under 4 GB free when this was written) and other agents compile: before each go
  command look at free memory (`powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB"`)
  and wait when it is under 2.5.
- Never touch `E:\T\tg-dl`, the folders `a3` and `b`, any real catalogue, media, session or account; never
  start the installed collector. Invented data only, in tests and in anything you screenshot or print.
- Keep `archiver/docs/progress/pages-g1-PROGRESS.md` current and commit it with each step. At the end
  `archiver/docs/progress/pages-g1-REPORT.md`: what was built against each numbered section; the route table of
  section 4; where each setting is read; every test and mutation with its result; what the rig measured for a
  Stop; every existing test whose expectation changed and why; **what was NOT verified** (nothing here has
  run against Telegram or been seen in a browser by you); anything in this brief you found wrong or
  contradictory (say so rather than build around it); the changed files; a drafted final commit message.
  Hand back commit-ready: everything committed and pushed, the tree clean, `gofmt` clean.
- Order of work, so that a stop in the middle leaves something usable: section 8; the seam's new fields, the
  adapter with its fake and `/api/live` (sections 3, part of 4); `run -pages` with the starting page and the
  stop order (1); the owner's Stop and Start (2); the Chats and Queue pieces (5); the rest of 4; the end to
  end and the hold (6, 7).
