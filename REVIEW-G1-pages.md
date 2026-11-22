# Review of G1 (the collector serves the pages; the owner's Stop and Start)

Branch `wip/pages-g1` at 023c048 in `wt-pages-g1`, against f0e3f0c. Independent, read-only review, 2026-11-15.
The tree was not changed (`git status` clean at the end). Two probe tests were run from a scratch folder with
`go test -overlay` (named runs only, `GOGC=25 GOMAXPROCS=2 -p 1`, free memory 4.4 to 5.0 GB before each):
`C:\Users\trabi\AppData\Local\Temp\claude\71f159c3a9e5d4b9\d968be25-bb4c-460c-a415-c3cbcc8ac244\scratchpad\probes\probe_review_test.go`.
Invented data only (the rig's fake Telegram); nothing real was opened.

Count: **1 must fix before merge, 6 should fix, 9 minor.**

---

## Must fix before merge

### M1. "Start" in the header starts an account the owner marked removed: it dials and sends requests. CONFIRMED (probe A)
- Files: `internal/collector/ownerstop.go` 228-247 (`targets`: account 0 is every account of `c.accts`, removed or
  not), `internal/server/server.go` handleRun (the removed check is only `in.AccountID != 0 && !contains(s.accountIDs(), ...)`),
  `internal/collector/account.go` `loop` (never looks at `removed_at`), `web/assets/js/main.js` 143 (the header
  button posts `account_id: 0`).
- Sequence: the owner presses Stop for account 1 (state "stopped by you"), then "Mark removed" (allowed: it is
  owner-stopped). Later the header shows "Start" (no account running) and the owner presses it to start the
  others. `StartAccount(0)` deletes account 1's stop row too, clears its mark and nudges its loop; the loop finds
  it signed in and not frozen and dials. Probe A, through the real HTTP routes on the rig: Start of account 1
  alone after removal answers 404 (correct), Start-all then gives account 1 a second dial, 3 more requests, state
  "running". The brief: "Start is refused for a removed account". Since removal needs the account stopped first,
  this sequence is the normal way the owner reaches it.
- Smallest change: in `targets` (or in `StartAccount` for account 0) skip an account whose catalogue row has
  `removed_at` set (one read of `ListAccounts`, or the account row by id); better also in the loop's top check
  (a removed account counts as stopped), so no other path can start it. A named test: stop, mark removed, Start
  all, no dial.

---

## Should fix

### S1. The pages' stop is not bounded: a client that stops reading, or a handler on an uncancellable context, holds the program's stop. CONFIRMED (probe B) for the first; CONFIRMED by reading for the second
- File: `internal/collector/pages.go` 241-265 (`stop`): after `pagesStopBound` it calls `endWork()` and then waits
  `<-zero` with no bound; `p.hs.Close()` (which would close the connections) comes only after that wait.
- Sequence 1 (probe B): a request whose answer is larger than about 200 KB (the probe's handler blocked after
  196,608 bytes on this PC; `/api/chats` of a large archive, `/api/report`, `/api/queue?limit=500` can be that
  size) and a client that stops reading. Ending the request's context does not end a blocked `Write`. The probe's
  stop still waited 10 s after it began (bound 3 s) and returned only when the client closed; in the program the
  wait ends at the server's write limit (`httpTimeouts.write`, one minute from the request's start). A second
  Ctrl-C does not help: it only calls `ForceStop` (sign-in hold).
- Sequence 2 (reading): `handleTopicsOnly`, `handleTopicChosen`, `handleTopicRank` (`topics.go` 195, 260, 291) and
  `handleChatCollect` (`reads.go` 320) run on `context.WithoutCancel(r.Context())`; the topics' calls run
  `c.Settle(ctx)`, which applies **every** stored intent to its end (`settle(ctx, 0, nil)`), the supply's own
  included. A Quit or Ctrl-C while one runs on a large forum waits for the whole settle, however long.
- Smallest change: after the bound, call `p.hs.Close()` before waiting (it closes the connections, so blocked
  writes fail at once), then wait `<-zero` with a second bound and log if it passes. Give the four
  `WithoutCancel` handlers a context that ends with the pages' work context in program mode: a settle that stops
  leaves its intent stored for the supply's next settle (`settleTopics`' own comment), so nothing is lost.

### S2. Import and "Mark removed" are allowed while the account's session still runs after a Stop. CONFIRMED by reading
- Files: `internal/collector/ownerstop.go` 263-285 and 191-226; `internal/collector/livepages/live.go` 104-106;
  `internal/server/accounts.go` `allStopped`, `stoppedOrSignedOut`.
- The page's rule rests on `Running = SignedIn && OwnerStoppedAt == 0` and `Stopping = (state == "stopping")`.
  `stopByOwner` sets the memory mark first (so `OwnerStoppedAt` is at once non-zero and `Running` false), then
  writes the row, and only then sets `StateStopping`, and only when `a.sess` was not nil. When the Stop lands
  while the session is being made, the watcher (`watchOwnerStop`) signals the session but never sets "stopping":
  `runSession` sets "running" and the state stays "running" through the whole ordered stop (engine stop grace,
  memo grace, reader and monitor grace: up to `closeBound`). In that time the snapshot says not running and not
  stopping, so `allStopped()` is true (the import, "one long write", starts beside a session that is giving its
  files back) and `stoppedOrSignedOut()` is true (removal allowed). The same holds for the few milliseconds of the
  row write in the direct path. The verdict meanwhile says "Starting"/"Collecting" words of a running account.
- Smallest change: derive "stopping" in the collector, not from the state word: an account whose owner mark is on
  and whose `a.sess` is not nil (or whose loop has not reached "stopped by you") is stopping; set `StateStopping`
  in the watcher when it signals, and set it in `stopByOwner` before the row write.

### S3. The overview says "as of now" while its hourly chart and estimate can be up to an hour old. CONFIRMED by reading
- File: `internal/server/overviewcache.go` 31-43 (`reuse`): when the change key did not move it returns
  `asOf = now`. The report itself says `c_hourly` writes do not move the change log; the hour was added to the key,
  but inside an hour nothing moves it while no file changes state. A large file downloading for many minutes under
  Telegram's speed limit changes no `c_want` state: the current hour's bars (bytes, requests, waits) and the
  estimate built from them (`makeEstimate(tot, rows)`) stay as they were, and the page says "The numbers and the
  hours as of <now>".
- Smallest change: add a cheap key of the hourly table to the overview's key (e.g. `MAX(rowid)` of `c_hourly`:
  a replaced row gets a new rowid; one seek), or report the kept answer's own time (`k.at`) as its "as of".

### S4. With two accounts in a chat, the page offers "Approve" with another account's estimate and never offers "Ask" for the chosen one. CONFIRMED by reading
- Files: `internal/server/notadded.go` 82-85 (`summarise` keeps the newest estimate over all accounts, removed
  ones included), `web/assets/js/pages/chats.js` `readBox` (`fresh` and the approve button use `c.estimate` with
  the picked account `acct`).
- Sequence: chat X is reached by accounts 1 and 2. The owner asked the estimate through account 1, then stopped
  account 1. The row now lists only account 2 as running, shows account 1's estimate as fresh and the button
  "Approve this read (about N requests)" for account 2. `ApproveRead(2, X, N)` finds no record for account 2
  (`ErrNoEstimate`), the page answers "The estimate on record is another one now: it is shown; approve again" but
  shows the same one; the "Ask Telegram" button for account 2 does not appear for a day. Nothing wrong is approved
  (the number must match account 2's own record), but the owner is stuck with a false sentence.
- Smallest change: give the page each account's estimate (or the estimate of the account the box acts through),
  and decide "fresh" and the approve number per account.

### S5. When `server.New` fails, the address says "Starting... N s" for ever and Quit is refused. CONFIRMED by reading
- File: `internal/collector/pages.go` 216-222 (`attach`): on an error it logs "the collector runs on without them"
  and returns without storing a handler; `ServeHTTP` then serves the starting page (its counter keeps growing)
  and 503 "Starting" for every `/api/`, `/api/quit` included. New can fail on its start-up settings write
  (`settleSettings`) on the shared writer.
- Smallest change: store a small handler that says, in fixed words, that the pages could not be made and the
  collector runs on (and answers `/api/quit`, or says to use Ctrl-C).

### S6. An owner's Stop that lands as Telegram signs the account out loses the sign-out record. PLAUSIBLE
- File: `internal/collector/account.go` 558-567 and 345-348: the session ends on the first value of `s.end`; the
  sign-out is recorded (`markSignedOut`, `signedOutMem`) only in the loop's `endSignedOut` case. If the Stop's
  `endOwnerStop` is first in the channel and the engine's or reader's `endSignedOut` second, the second is dropped.
  After the owner's Start the account dials again with a session Telegram refused. (Frozen is not affected: it is
  recorded as a hold by the engine's side.) The same race existed with `endRestart`; the Stop adds a new, more
  frequent source. Settle with a rig test whose fake refuses the login at the moment of the Stop.
- Smallest change: when the session ends for the owner's Stop, drain `s.end` for a sign-out (or let
  `endSignedOut` win over `endOwnerStop`) before choosing the ending.

---

## Minor

1. **A Start can be lost at the first turn after the program's start.** CONFIRMED by reading.
   `ownerstop.go` 132-153: with the mark off, the loop reads the row, and only afterwards sets the mark. A Start
   between the read and the set deletes the row, clears nothing, nudges; the loop then sets the mark and stays
   "stopped by you" in memory while the record says started (the next restart starts it). Window: one settings
   read, when the mark is off and a row exists (first turn after a start with a Stop on record, or two tabs'
   Stop and Start at once). Fix: a generation counter on `ownerStop` taken before the read, or `owner.mu` held
   across Start's delete and clear and checked before `set`.
2. **Stop and Start of two tabs at once** can leave memory and record disagreeing (Stop's mark set, Start's delete
   and clear, Stop's row write): the loop then follows the row. No lock orders them. Same fix as 1.
3. **Words false while a Stop is pending.** A Stop during the redial pause or a dial leaves the state "starting in
   N s"/"connecting" (no "stopping") for up to `GateRetryMin` or the dial; the verdict says "Starting: connecting
   to Telegram." The header pill says "Running" whenever any account is signed in and not owner-stopped, also when
   every account is frozen or refused by the VPN check (`Running = SignedIn && !OwnerStopped`).
4. **The redial floor counts only a session's end** (`owner.lastEnd`): a failed dial or a gate refusal sets no
   floor, so Stop then Start during the doubling pause after failed dials dials at once. The brief's rule is
   about a session's end, so this is in line with it; noted because each click is a dial.
5. **"Waits for one" is false.** `-pages` help and the Accounts/Overview words say the program waits for a signed-in
   account and to sign in with the collector's signin command; that command takes the collector's lock, which this
   program holds, so it is refused until Quit (the loop also only rereads the record after 24 h or a nudge).
   Say "Quit, sign in, start again".
6. **Start-all and Stop-all answers name no account.** `livepages.Start` returns `ErrStopStays` (409 "Not started")
   when one account's row could not be removed, although the others started; `Stop` returns one note for all.
7. **Data race** on `pagesRun.c`: written in `attach`'s goroutine, read in `stop` (another goroutine) with no
   ordering when no request ran. The race detector may report it in the full runs.
8. **`http.Server.ErrorLog` is nil**: net/http's own lines (a handler's panic with its value and stack, accept
   errors) go to the process's standard error, outside the fixed-words log rule. Set `ErrorLog` to a logger that
   writes a fixed line.
9. **Tests.** `TestStartDuringStopIsKept` does not assert that the Start landed during "stopping" (it only logs
   when not), so it can pass without covering its case. Several collector tests judge absence by one second of
   wall time ("20 s of the clock"): on a loaded PC they pass vacuously, never falsely. `TestOpenPageStatementsBounded`
   counts statements, not rows (the brief asked for rows; the report says why not): a recompute of the overview at
   300,000 files scans `tg_media`, `c_want` and `file` (`Totals`) every 5 s while downloads move the key; its cost
   per recompute was not measured. `TestTopicSettleAtSize` is still a wall-time ratio (allowed by the brief).

---

## Checked and found sound
- The guard: every new change route (`/api/quit`, `/api/chats/estimate`, `/approve`, `/collect`) is registered
  through `handle` inside `s.guard` (Host list, cross-site refusal, token, POST); `/api/quit`, estimate and approve
  are 404 in `tgarchive app`. The starting page and its 503s carry no data and change nothing.
- `server.Listen` and `bindPages`: 127.0.0.1 only; the address bound and the pages' lock taken before anything
  is read or sent; nothing made when the address is in use; `-pages-addr`/`-viewer-url` refused without `-pages`.
- `GET /api/live` reads no table in the program (memory only: states, lanes from `LaneStats`); the header polls it
  alone every 2 s. Overview and queue keep their answers by `CountsKey` with the 5 s floor; changes through the
  server mark them dirty before and after.
- `RecoverActive` is never called in program mode; `settleSettings` gets no library; the library is refused in
  save and validation.
- Stop order: the pages' gate refuses new requests, in-flight ones are waited for, background estimates waited
  for (`WaitWork`, after their context ended), then the collector's context; no handler runs after the catalogue
  closes (bar the unbounded wait of S1). Quit twice and Quit before ready (503) are harmless.
- Owner's Stop: memory mark first, row second, the session's own `signal`; fails closed on an unreadable row;
  survives a restart; not undone by `ClearFrozen` or a sign-in; a dial that returns after a Stop is closed; the
  redial floor is an uncut sleep. Files given back by the session's own stop only; held, kept held and set-aside
  untouched (no new write path).
- Estimate: one per account and per chat in flight (server maps, cleared after the record is written); a request
  queued on the reader when the account stops is not run by the next session (its `readerState` is new); a
  request whose page ended at 30 s is kept; at the program's stop its context ends and it is waited for.
  `ApproveRead` approves only the number on record.
- Retry, release and keep-held are conditional single-row updates (a race with the engine answers 409).
  Settings save settles the size classes in chunks after its batch commits.
- Logs: `fail` and the read routes log the route's pattern and the error's Go type only; collector lines use
  `errWord`. Scripts put text only through `textContent` (`dom.js`), never markup.
- `internal/server` does not import the collector or the Telegram package.

## Not looked at
- The browser itself (nothing was opened); the Settings, Import and Report pages' scripts beyond their diffs.
- The catalogue's settle code beyond what the routes call; the engine and supply (unchanged).
- Pre-existing, outside this diff: `tgarchive app` takes only the pages' lock and runs `RecoverActive` at its
  start; with a collector running plain `run` (without `-pages`) beside it, that gives back files in transfer.
  `-pages` closes this for the program mode only.
- No race detector, no whole-package runs, no Telegram.
