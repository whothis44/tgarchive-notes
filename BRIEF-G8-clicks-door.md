# Brief G8: the door for the owner's clicks on the collector's listener (pages track, session P4; 2026-11-16 07:05)

For one Opus coder. Piece 3 of `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-CORE-client-actions.md` (the
owner's yes: board item 28): the routes under `/api/act/` on the collector's own listener, through which the
viewer's compose box hands a click to the collector. The owner asked twice for "actually seeing/interacting
with the chat"; the request layer (K8), the ledger (K9a) and the click's turn (K9b) are merged, the viewer's
compose box is built behind a nil seam (`wip/b-compose`). This piece is the link between them, plus the two
settings of the clicks on the Settings page.

**The routine-steps rule of this project (`CLAUDE.md`, the archiver section, second point) binds you too:**
you run named tests only; the whole runs are not yours.

**Read first, in full:**
- `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-CORE-client-actions.md` sections 3 and 4.
- `C:\Users\trabi\Claude\Projects\Telegram\SEAM-B5-viewer-act.md` (what the viewer's side is written to: the
  five calls, the closed words, `Key`, the deadlines). Your routes are what its pass-through will call.
- In `C:\Users\trabi\Claude\Projects\Telegram\BOARD.md`: messages 93 and 95 (the viewer's asks of the door) and
  message 100 (b) (Core's answer: what holds today and what waits for Core's next piece, "K14").
- `internal/collector/click_api.go` as on `private/wip/core-settle` (d6415255): the entry points you adapt.
- `internal/server/server.go` (`guard`, `refuse`) and `internal/server/mirrors.go` with
  `internal/collector/livepages/mirrors.go` (the newest seam and adapter of this track: the pattern to follow).

## What is known already (read by the main session)
- **Every request is the collector's.** `Collector.QueueClick` writes the click down and nudges the account's
  loop; the turn sends one request, never repeats it by itself, and writes the outcome to the row. All checks
  at the queue are the catalogue's; the cap, a stated wait, a frozen or refused account are judged at the
  turn and written to the row. Your routes send nothing and add no request.
- **Not built yet, Core's next piece (K14):** the key's memory at the queue (one key, one click), one cheap
  state call, the text's limits at the queue. Your seam carries `Key` and has the state call now; the adapter
  says plainly what it cannot give until K14 (below, point 4).
- **The rules for anything that acts for the owner** (TRIED-BEFORE 24 and 25), as they bind a door: one item
  per call, each result its own answer; a setting that cannot be read stops the action and never reads as
  empty or as the default (fail closed); every "no" in fixed words; nothing of a click in any log.
- **This track's reviews so far found, three times out of four, a must-fix in whatever joined a real door.**
  Build to it: every path of a route answers exactly once, a refusal is never taken for a failure nor a
  failure for a refusal, and a call cut off by its caller leaves the click fully queued or not at all.
- `internal/server` imports neither the collector, Telegram nor the mirror package (its wall test): the door
  reaches the collector through a seam of the server's own, as `Mirrors` does.

## What to build
1. **The seam `Clicks`** in `internal/server` (a new file, `clicks.go`; nil: no route is served, 404):
   - `State(ctx, account, chat) (ClickState, error)`: `Write bool`, `Why` (one of the six words), `MaxText int`
     (UTF-16 units; 0: not known), `MarkAsRead bool`.
   - `Queue(ctx, ClickIn) (ref int64, err)`: `ClickIn` is field for field the collector's `ClickInput` plus
     `Key string`.
   - `Cancel(ctx, ref)`, `Again(ctx, ref, tryAgain, notInChat bool) (ref int64, err)`,
     `Verdict(ctx, ref, arrived bool)`, `NotArrived(ctx, ref)`.
   - The settings: `Settings(ctx) (ClickSettings, error)` (the cap, whether each value is stored, whether a
     stored one cannot be read), `SetCap(ctx, ...)`, `SetMarkAsRead(ctx, on bool)`.
   - A refusal is `*ClickRefusal{Word string; UntilMs int64}`. The words are a closed set of constants in
     `clicks.go`, exactly the door's words of `SEAM-B5-viewer-act.md` (its table and its six state words); only
     "wait" and "cap" carry a time. Any other error is a failure.
2. **The door's own guard** (not the page's): every request under `/api/act/` is POST with a JSON body and
   carries the header `X-Tgarchive-Door` with the door's secret (constant-time compare). The page token does
   NOT open the door and the secret does not open any other route. A request that carries `Origin`, any
   `Sec-Fetch-*` header or a `Cookie` is refused before the secret is looked at (the caller is a program, never
   a browser). The Host check, the response headers and "no door while the program is stopping"
   (`refusedWhileStopping`) stay as for every route. A demo has no door. Decide where this sits so that
   `guard` cannot let an `/api/act/` request through by the page's rule, and prove it by tests over every
   method.
3. **The routes** (one click a call; bodies and answers are JSON; numbers and the fixed words only):
   `POST /api/act/state` {account, chat}; `/api/act/queue` {the click, key} answers {ref};
   `/api/act/cancel` {ref}; `/api/act/again` {ref, try_again, not_in_chat} answers {ref};
   `/api/act/verdict` {ref, arrived}; `/api/act/not-arrived` {ref}.
   - Answers: 200 with the result; **409 with {"word", "until_ms"} for a refusal** (a word outside the closed
     set is never passed on: it becomes a failure); 400 with the word "bad request" for a body that is not the
     route's shape (unknown fields refused, a key that is not 16 to 64 lower-case hex digits, a kind that is
     not one of the six, a text over the body limit); 403 for the door's guard, one fixed body whatever the
     reason; 500 with the word "failed" for anything else, its class logged with a constant format string and
     nothing of the click.
   - **Cut-off calls:** queue, cancel, again, verdict and not-arrived run on a context that the caller's
     leaving does not cancel, with one deadline of 15 s (the viewer's is 20 s); the state call keeps the
     request's context. The answer is written after the seam's call has ended, whatever became of the caller.
     `Server.WaitWork` (or its like) waits for them at a stop.
   - No read route for the ledger's rows or the candidates: the viewer reads the catalogue itself, read-only.
4. **The adapter**: ONE new file `internal/collector/livepages/clicks.go` that implements the seam over the
   collector's entry points, and the one place in `internal/collector/pages.go` that hands it over (as the
   mirror's adapter is handed over). The map from each error of `click_api.go` (and the request layer's local
   "no"s that reach the door) to its word is the table of `SEAM-B5-viewer-act.md`; `errors.Is`/`errors.As`
   through wrapping; an error with no row in the table is a failure, never a guessed word.
   - `Key`: until K14 the collector has no place for it. The adapter checks nothing more than the route did
     and does not remember it; a comment says so and names K14. Do not build a key memory of your own.
   - `State`: until K14 gives one call, answer only from entry points that exist and are cheap (no request,
     no walk of a table): what can be told today among "not running", "not signed in", "frozen", "clicks
     off", "mirror" is told; `MaxText` is 0 (not known: the viewer then lets no text go); `MarkAsRead` from
     the settings (a setting that cannot be read: the word "setting", `Write` false). List in your report
     which of the six words you can tell today and from what, and which not. If nothing honest and cheap can
     tell whether the account can write, `State` answers a failure and you say so: no guess.
5. **The door's secret and where the viewer finds it.** When the collector serves the pages with the door
   (`run -pages`, not a demo, not `tgarchive app`), it makes a fresh secret (32 random bytes, hex) and writes
   ONE file, `act-door.json`, **in the folder of its catalogue file** (`{"addr": "127.0.0.1:<port>", "secret":
   "..."}`), put in place whole (a temporary file in the same folder, then a rename with a bounded retry: on
   Windows a rename onto a file a reader holds open can fail; `internal/watchdog`'s status file, K12, shows
   the way), and removes it at a clean stop. A start finds an older one and replaces it. If it cannot be
   written the pages run without the door (no route served) and one constant line says so. The secret is
   never logged, never in an answer, never in the catalogue. Nothing here depends on this PC's paths, the
   start folder or a script. Export the file's name and a small reader (`ReadDoorFile(catalogueFolder)` with
   the retry) where the viewer's pass-through can import it without importing the collector or the server's
   pages: say where you put it and why.
6. **The Settings page: "Acting in chats"**, two rows through the seam (the page's own token rule, as every
   settings route): the cap (off, or N a second and M in W minutes inside Core's bounds; the collector's check
   is the only check, its refusal shown in its words) and "Mark chats as read when I open them" (off unless
   the owner turns it on). A stored value that cannot be read is shown as that, with "write it anew", never as
   the default. With no seam (`tgarchive app`, a demo's change) the rows follow what the mirror's settings rows
   do. Each row says what it does in one plain sentence; no Telegram word on the page.

## Tests (named; a fake seam for the server; the collector's rig with the fake Telegram for the adapter)
- The guard: without the header, with a wrong one, with the page's token instead, with `Origin` or
  `Sec-Fetch-Site` and the right secret, GET/PUT/DELETE: each 403 or 405 and the fake seam saw no call; the
  secret on a non-door route changes nothing there.
- Each route: its happy answer; each refusal word round-trips with its time; a word outside the set becomes
  "failed"; malformed bodies are 400 and the seam saw no call.
- The cut-off: a caller that goes away during `Queue` (the fake seam blocks until released): the call ends,
  the click is queued once, nothing is logged of it; a seam that outlives the deadline answers "failed" and
  the test says what the fake saw.
- The adapter, end to end on the rig: one `POST /api/act/queue` with the secret leads to exactly one request
  at the fake Telegram and a row "done"; the same with a wrong secret leads to none and no row; cancel,
  again (both words), verdict and not-arrived each against a click in the right and in a wrong state; every
  error of the table maps to its word (a table test that fails when `click_api.go` gains an error with no
  row).
- The door file: written whole, replaced at a start, removed at a stop, unreadable folder: the pages run and
  the routes are not served.
- The Settings rows: stored, not stored, cannot be read; a refused cap shows the refusal and changes nothing.
- For each guard and each "exactly once" claim one mutation (the check removed: which test fails), listed in
  the report.

## Rules (hard)
- Copy and branch: `git -C C:/Users/trabi/Claude/Projects/Telegram/repo-archiver fetch private`, then
  `git -C C:/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add -b wip/pages-door ../wt-pages-door <the head of private/claude/charming-feynman-vm2xia>`
  (788ebf77 at 07:00; write the exact commit into your progress file). Work only in
  `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-door`.
- **Order: build points 1 to 3, 5 and 6 first; they need nothing of Core's listed work.** The adapter (4) needs
  K9c (`ClickNotArrived`, the second word of `SendClickAgain`), listed and not merged at 07:00. When you reach
  it: fetch; if the main head holds K9c, merge the main head (a clean merge only; a conflict: stop and
  report). If not, apply K9c's own difference in ONE commit of its own
  (`git diff 77cf3d7f d6415255 | git apply --3way --index`; subject "K9c's difference, for the door's base")
  and say so: the main session has it replaced by the main head before a listing.
- Product code only in `internal/server` (Go, `web`), the ONE new adapter file, the hand-over place in
  `internal/collector/pages.go` (lent by Core: one commit of its own, as few lines as it takes) and, for the
  door file, one small new package or file you name. Nothing in `internal/telegram`, the catalogue (no schema
  step), `click.go`, `click_api.go`, the viewer, the window, the launcher, `faketg`.
- **Nothing runs against Telegram.** Invented data only; never touch `E:\T\tg-dl`, the folders `a3`, `b`,
  `app`, `C:\Users\trabi\tgarchive-app`, any real catalogue, media, session or account; start no installed
  program and stop no process you did not start (the owner's own program may be running).
- New log, error and state text is constant words with numbers: never a chat's title, a name, a path, an id,
  a key, the secret or a text.
- `TestAssetsStaySmall` holds every script under 600 lines: the Settings rows go into a script with room, or
  a small new one. After any change under `web/assets/js`: `TestScriptsNoDuplicateOrMissingNames`,
  `TestAssetsStaySmall` and `node --input-type=module --check < file` for each changed script.
- Go: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, one go command at a
  time, `GOGC=25 GOMAXPROCS=2 go test -p 1 -run '<names>' ./internal/<package>`, named tests only: no whole run
  of `internal/server`, `internal/collector` or `internal/catalog`, no race detector, no Docker. Before each go
  command: `powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`;
  wait when free memory is under 2.5 GB or the CPU is over 85%. Every wait in a test has a bound.
- Before handing back, list the test functions your difference removes against your base
  (`git diff <base> HEAD | grep '^-func Test'`) and account for each: the expected count is none.
- Any file that holds a Windows path is written with the file-writing tool, never from inside a shell or
  script string.
- Commits: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; commit work in progress as you go and push only
  `git push private wip/pages-door`. Never push, merge into, rebase or switch any other branch; never stash.
- Keep `archiver/docs/progress/pages-door-PROGRESS.md` current from your first action and commit it with each
  step.

## Hand back
Commit-ready: everything committed and pushed, the tree clean, `gofmt -l` clean, `go vet` on the packages you
changed. `archiver/docs/progress/pages-door-REPORT.md`: what was built against each numbered point; **the door
as built, written so that the viewer's pass-through and Core's K14 can be built to it without reading your
code: every route (path, body, each answer and its status), the header, the door file (name, place, fields,
the reader), the seam method by method, what the adapter expects of the collector, and the exact places K14
changes (the key, the state call)**; the six state words: which are told today and from what; every test and
mutation with its result; what was NOT verified; anything in the design, the seam file, the board's messages
or this brief you found wrong; the changed files; a drafted final commit message. Your final message: the
head commit and the base it sits on, what is built and tested, what is not, every departure, and your doubts,
plainly.
