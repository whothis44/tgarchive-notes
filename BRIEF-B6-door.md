# Brief B6-D: the viewer's pass-through to the collector's door, and the seam brought up to date (viewer session B6, 11-16)

You are an Opus coder for the viewer track of the new archiver. Work only in the copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-b-viewer` (Go module in `archiver/`). First, there: check the copy
is clean (`git status --short` prints nothing; if not, stop and say so), `git fetch private`, and cut the branch
`wip/b-door` from `private/wip/b-compose` (31362d5d: the compose box with the main head 788ebf77 in it).
Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash (Go is not on PATH).
**The routine-steps rule of this project (`CLAUDE.md`, the archiver section, second point) binds you too:** you
run named tests only; the whole runs and the race detector are not yours.

## Why, and what exists
The owner asked for the app to be used like a Telegram client. Every request to Telegram is the collector's;
the viewer has no Telegram code and keeps none. Built so far: the request layer, the ledger of clicks and the
click's turn in the collector (merged); the viewer's compose box, buttons and a click's place in the
conversation, **behind a seam that is nil in every program** (`internal/viewer/act.go`, `act_keys.go`,
`act_ledger.go`, `web/js/act.js`: your base). Being built by other tracks right now: the door (six routes on
the collector's own listener; the pages track, branch `wip/pages-door`, brief
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-G8-clicks-door.md`) and the door's guarantees in the collector
(Core, "K14", brief `BRIEF-K14-door-guarantees.md` in the same folder). **Your piece is the link from the
viewer's seam to that door**, built now against a fake door in tests, so that it is ready when the two land.

**Read first, in full:**
- `C:\Users\trabi\Claude\Projects\Telegram\SEAM-B5-viewer-act.md` (the seam as built) and the head comments of
  `act.go`, `act_keys.go`, `act_ledger.go`.
- `BRIEF-G8-clicks-door.md`, points 2, 3 and 5: the door's guard, its routes and answers, the door file. **That
  is the contract you build to.** In short: POST with a JSON body, one click a call, to
  `/api/act/state` {account, chat}, `/api/act/queue` {the click's fields as the collector's `ClickInput` has
  them, plus `key`} answering {ref}, `/api/act/cancel` {ref}, `/api/act/again` {ref, try_again, not_in_chat}
  answering {ref}, `/api/act/verdict` {ref, arrived}, `/api/act/not-arrived` {ref}. Every request carries the
  header `X-Tgarchive-Door` with the door's secret. A request with `Origin`, any `Sec-Fetch-*` header or a
  `Cookie` is refused. Answers: 200 with the result; 409 with {"word", "until_ms"} for a refusal; 400 "bad
  request"; 403 for the guard; 500 "failed". The door finishes queue, cancel, again, verdict and not-arrived
  on its own context within 15 s whatever becomes of the caller. The collector writes ONE file while it
  serves the door, `act-door.json` **in the folder of the catalogue file**: `{"addr": "127.0.0.1:<port>",
  "secret": "..."}`, fresh at every start, replaced whole, removed at a clean stop.
- In `C:\Users\trabi\Claude\Projects\Telegram\BOARD.md`: message 100 (b), and both messages numbered 101 (pages
  P4 of 07:03, Core K-4 of 07:02): what the door and K14 give and when.
- `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-CORE-client-actions.md` sections 3, 4 and 5.
- `git show private/wip/core-settle:archiver/internal/collector/click_api.go` and the entry "K9c" at the end of
  `C:\Users\trabi\Claude\Projects\Telegram\MERGE-QUEUE.md` (what K9c added: a second word on "send again",
  `ClickNotArrived`, the candidates of a "not known" click). Do not merge that branch.
- `internal/viewer/wall_test.go`, whole.

**What is known already (the main session read it; build to it, do not rediscover it):**
- The rules for anything that acts for the owner (`TRIED-BEFORE.md` sections 24 and 25, the design's section
  4): **one click, one request, never repeated by the program** (not after a timeout, not after a lost answer,
  not at a restart); one item per call; a stored value that cannot be read stops the action and never reads as
  empty (fail closed); every "no" in fixed words; nothing of a message in any log.
- The compose box's two reviews found the same thing twice: a path where the page would say "sent" for
  something never sent, or send twice. The key is the guard: the viewer hands the page's key to the door
  unchanged on every try of the same click; the door (K14) answers a known key with the same click's number
  and refuses it with another content (the new word "key").
- The old app has no acting side: there is no number of its to put beside this piece.

## What to build
1. **The pass-through: ONE new file, `internal/viewer/act_door.go`**, the only file of the viewer that may
   make a connection. An implementation of the seam `Act` that calls the door:
   - It is given how to find the door, not where it is: a function handed in by the program
     (`func() (addr, secret string, ok bool)`, or a shape you find better; **the viewer package imports nothing
     new**: the pages track exports the door file's reader in a small package of its own, and the two commands
     will hand it in when that is merged). The door is looked up again for every call (the secret changes at
     every start of the collector); address and secret are always used as the pair one lookup gave.
   - **It connects to `127.0.0.1` and nothing else.** The address must be exactly `127.0.0.1:<port 1 to
     65535>`: anything else the lookup gives (a name, `localhost`, another loopback address, IPv6, a home
     address, a path, a scheme) is refused without a connection and without the secret leaving the process.
     One client of its own: no proxy from the environment, no redirect followed (a redirect is a failure),
     no cookie jar, plain HTTP, a dial that can only reach the checked address whatever the URL says, an
     answer's body bounded (64 KB), the caller's context and deadline honoured. It never sends `Origin`,
     `Cookie` or a `Sec-Fetch-*` header.
   - **The secret** goes into the one header of a request to the checked address and nowhere else: not into
     an error, a log line, the counts file, a page, a test's failure message.
   - **Answers.** 200: the result (an answer that is not the route's shape is a failure). 409: an
     `*ActRefusal` with the word **only if the word is one of the door's words in the viewer's closed set**
     (a word of the viewer's own, or an unknown one, is a failure, never passed on), the time only with
     "wait" and "cap". 400, 403, 500, any other status, a body that cannot be read: a failure (`ActFailed`).
   - **Two kinds of failure, kept apart, because the page says different things for them:** (a) *nothing left
     this program* (no door file; the address refused by the check; the connection could not be made): for
     the state call this is "cannot write: not running", for a change it is the refusal "not running":
     certain, nothing is queued. (b) *the request left and no usable answer came* (a timeout, a reset, a bad
     status or body): a failure; the page's existing behaviour for a failed change holds (Send held until the
     state is read; the same key on the next try). Never turn (b) into (a). Never send a change a second
     time by yourself, whatever the error: no retry inside the pass-through for any of the five changing
     calls; the state call may be asked once more only when no connection was made.
   - **The door can come and go while the viewer runs.** A catalogue beside which no door file has ever been
     seen in this run of the viewer is the old case: **the page draws nothing, exactly as with a nil seam
     today** (the owner's old archive is opened by the same programs and must stay as it is: test it). Once
     the file has been seen, the box is there, and a later missing file or refused connection shows the
     existing line for "not running". Say how a chat page that is already open learns that the door appeared
     (at the latest when it is opened again; through its live poll if that is cheap).
2. **The seam brought up to date** (`act.go`, `act.js`, the routes; the page's words stay a closed set written
   in one place):
   - `SendClickAgain` carries K9c's second word (`not_in_chat`): read in K9c's entry and `click_api.go` what it
     means and where the page's "Send again" on a "not known" click must give it.
   - `ClickNotArrived`: the owner takes back an "arrived" the app made by itself. Find from K9c's entry how
     such a row is told from one the owner confirmed, draw it where its click was with one button in plain
     words, and stop drawing it as K9c's rules say. If the ledger's read today drops such rows as finished,
     say what you changed in `act_ledger.go` and keep its bounds.
   - The candidates of a "not known" click come from the catalogue (`catalog.ClickCandidates`, on K9c's
     branch; the viewer reads the catalogue itself, read-only). They replace or back the page's own match by
     text: say which and why. **This needs K9c in your base:** build point 1 first; when you reach this,
     `git fetch private` and, if `private/claude/charming-feynman-vm2xia` holds K9c (`ClickCandidates` exists
     in `internal/catalog`), merge that head into your branch (a clean merge only; on a conflict stop and
     report). If it does not hold it yet, build everything else, leave the candidates out, and say so
     plainly in the hand-back.
   - Two new words of the door, with their sentences: **"key"** (the same key came with another content: the
     page must make a new key only for a new click, so show it as a fault of the page in fixed words and let
     nothing be sent twice) and **"queue full"** (50 clicks wait for this account).
   - A 200 answer of the state route may carry more fields after K14 than today (wait ends per kind, the
     cap's next opening, a caption's and a forward's limit): unknown fields of the STATE answer are ignored;
     build nothing on them now and list them in the hand-back as "not used yet". Every other route's answer
     is read strictly.
3. **The wall, kept honest.** `wall_test.go`: the forbidden calls stay forbidden everywhere but in
   `act_door.go`, named as the one exception as `ffmpeg.go` and `launch.go` are for programs; a new wall test
   pins what that file may do (one client, one dial, the address check in front of it); `TestWallDependencies`
   unchanged. The About page's sentence that the viewer makes no connections gets new, exact words (it
   connects only to the collector on this PC, and only to hand over what the owner sends).
4. **`SEAM-B5-viewer-act.md`**: add a section "Changed by the pass-through (B6)" with everything a reader of
   the seam must now know (written with the file-writing tool; it holds no Windows path today, keep it so).
5. **Not in this piece:** `cmd/tgarchive/viewer.go` and `cmd/tgarchive-window/main.go` are NOT changed: the
   seam stays nil in both programs until the door is merged and this piece has had its own security review.
   No route for another device at home. No schema step, no `go.mod` change.

## Tests (named; a fake door is an `httptest` server on 127.0.0.1 that speaks the contract above)
- Each of the six calls: the request the fake door saw (path, method, the header, the JSON fields, no
  `Origin`, `Cookie` or `Sec-Fetch-*`), and the happy answer.
- Each door word round-trips as a refusal with its time where it has one; a word outside the set, a viewer's
  own word, a 400, a 403, a 500, a 200 with a wrong shape, a body over the bound, a redirect: each a failure,
  and for the changing calls the fake door saw **exactly one** request.
- The address check: for each of a name, `localhost`, `127.0.0.2`, an IPv6 loopback, a home address, a port
  of 0 or over 65535, a value with a path or a scheme: no connection is made (a listener that counts
  accepts where one can be made), and the answer is kind (a).
- No door file; a door that is not listening: kind (a) for the state and for a change. A door that accepts
  and never answers: the call ends at the caller's deadline as kind (b), one request seen.
- The secret: a test that greps every log line, error text, counts snapshot and page answer produced during
  the above for the secret's value and finds none.
- The door never seen: the page's flag and every route behave exactly as with a nil seam (reuse the nil
  tests' assertions); seen once, then gone: the "not running" line.
- The key: the same click tried again after kind (b) reaches the door with the same key and the same body;
  a 409 "key" is shown and nothing more is sent.
- The seam's new parts (the second word, not-arrived, the candidates when K9c is in your base), each drawn
  from ledger rows written through the catalogue's own doors on an invented catalogue, as the existing
  `TestAct*` do.
- For each guard above (the address check, the single request, the word filter, the secret's one place) one
  mutation: the check removed, which test fails. List them.
- The existing `TestAct*`, `TestWall*` and `TestLAN*` still pass.

## Rules (hard)
- Only `internal/viewer` (and its tests) and the one seam file in the project folder. Nothing in
  `internal/catalog`, `internal/collector`, `internal/server`, the commands, `internal/window`.
- **Privacy:** invented data only (`tgarchive fabricate -real-rows` makes an invented catalogue). Never open
  the owner's catalogues, library or any real media (nothing under
  `%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b`, `%LOCALAPPDATA%\tgarchive`,
  `C:\Users\trabi\tgarchive-app`, `E:\T`, the NAS); never start the collector, the old app, or a viewer or
  window on anything but a scratch folder of your own; stop no process you did not start (the owner's own
  programs may be running). **Nothing in this piece reaches Telegram or any machine but this one**: your
  tests' only connections are to `httptest` servers on 127.0.0.1.
- **Words:** every string a page, a console or the counts file can show from this piece is one of a closed
  set written in one place; new console lines pass the fixed-words filter (`viewer.LogWord`); no name, text,
  id, path, key, secret or hash in a log line, an error or a test message.
- **Load (other runs are going on this PC):** one go command at a time, `GOGC=50 GOMAXPROCS=2 go test -p 1
  -run '<names>' ./internal/viewer`; before each go command
  `powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`
  and wait while free memory is under 2.5 GB or the CPU is over 85%. No whole run of `internal/viewer`, no
  race detector, no Docker, never any cache clean-up. Tests do not judge real time; every wait in a test has
  a bound.
- Any file that holds a Windows path is written with the file-writing tool, never from inside a shell string.
- Before handing back: `git diff 31362d5d HEAD | grep '^-func Test'` must print nothing, or you account for
  each line.
- Commit as you go on `wip/b-door` and push only `git push private wip/b-door` (never another branch, never
  `origin`; never merge into, rebase or switch another branch; never stash):
  `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no archive numbers in it. A scratch folder of your
  own with a unique name, removed at the end.

## At the end, once
`gofmt -l` on what you touched; `go vet ./internal/viewer`; your named tests and
`go test ./internal/viewer -run 'TestAct|TestWall|TestLAN' -p 1`; `CGO_ENABLED=0 go build ./...`. Hand back, as
your last message: the head (pushed) and the base it sits on (and whether the main head with K9c was merged
in); **the pass-through as built** (how the door is found, the client's exact limits, each status and what it
becomes, the two kinds of failure and what the page shows for each); what changed in the seam, method by
method, and every new string the page can show; the tests and mutations with their results (numbers); what you
did NOT test (no real door exists yet; say whether any page was seen in a browser and how); anything in the
door's brief, the seam file or the board's messages that you found wrong or that does not fit together; your
doubts, plainly. Commit-ready, nothing left running, the copy clean.
