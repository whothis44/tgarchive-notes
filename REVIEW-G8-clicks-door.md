# Review of G8: the door for the owner's clicks (independent, read-only; 11-16)

Reviewed: `wip/pages-door` at 8a8a5f35 in `wt-pages-door`, the difference 788ebf77..8a8a5f35 without 285b1efc
(K9c's difference). The tree was not changed (`git status` clean at the end). Probes ran from
`wt-pages-review-g8-scratch` through `go test -overlay`; named tests only, the PC measured before each go
command (free memory 4.3 to 5.3 GB; CPU 31 to 85 %, one wait at 85 %).

**Verdict: may be listed after these fixes.** The door's code is sound on the points that matter most: no
path opens it but a program's POST with the secret, the page's token never opens it and the secret opens
nothing else, every path answers once, and for the queue "200" means queued, "409" and "500" mean not queued
(one exception, named below, that is never sent). The one must-fix is the door's contract with its caller:
until K14 a call that gets no answer leaves the click's fate unknown, and the viewer's seam is written to send
that key again, which this door queues a second time.

Counts: must fix 1, should fix 3, minor 10.

---

## Must fix before the merge

### M1. A queue with no answer is "unknown", and a second call with the same key queues a second click. The door's contract does not say so, and the viewer's pass-through is being built to resend. PLAUSIBLE (the duplicate needs one of the narrow no-answer paths below; the door's half is CONFIRMED by reading)
- **Where:** `internal/collector/livepages/clicks.go` 215-224 (`Queue`: "Key is not handed on... nothing here
  remembers it"); `internal/server/clicks.go` 355-367 (`doorWork`); the report's section 2.
- **The caller's side, from `SEAM-B5-viewer-act.md` (data):** "a key whose call failed or was refused goes to
  the door again"; "The door should answer a key it has already given a click number with that number"; the
  pass-through maps any error that is not a refusal, a transport error included, to "failed".
- **What the door gives (proven from the code):** within the door, 200 if and only if the row was written
  (`QueueClick` after `cat.QueueClick` returns an error only through `queuedFor`, which is `ErrNotRunning` with
  the row marked "not sent" or swept at the next start: never sent). A 500 "failed" is answered only for an
  error before the commit, so nothing was queued. So a retry after a door's own "failed" is safe. **The unsafe
  case is no answer at all:**
  1. The stop: a queue still in its seam call when the pages' stop bound (3 s) passes. `pages.go` 400-404
     cancel the work and `hs.Close()` the connection together. If the row was committed just before, the
     sessions are not ending yet (`endColl` comes after `p.stop()`), `queuedFor` passes, `wakeForClick` runs and
     the account's loop can send it, while the 200 goes to a closed connection.
  2. A panic in the seam after the commit: net/http drops the connection.
  3. The pass-through's own deadline (20 s) passing before the door answers. Today the collector's calls honour
     their context (database/sql, the one writer connection), so the 15 s deadline holds. But the door
     deliberately waits for a late seam and then answers 200 (`TestDoorDeadline`, second half), and any future
     seam step that ignores its context turns that into a click queued and a caller already gone.
- **One sequence:** the owner forwards a post (sends and edits are not possible yet: `max_text` 0); the queue
  commits at second 2.9 of a stop; the connection is closed at 3.0; the pass-through answers "failed"; the
  viewer keeps the key as "failed" and, at the next run, sends it again; the door has no memory of the key and
  `QueueClick` makes **new random ids** for every forward (`click_api.go` 454): the post is forwarded twice.
  A reaction or a read mark repeated does no harm; a delete repeated finds the messages gone. Forwards, and
  sends and edits once `max_text` is known, are the harmful kinds.
- **Not affected:** again, cancel, verdict and not-arrived are once-only by the ledger (a second "again" on
  the same ref is "not tip", a second cancel or verdict is "state"), so their retry is safe.
- **Smallest change asked:** no code. (a) The report's "door as built" and the comment on `Queue` say plainly:
  "until K14, no answer from `/api/act/queue` (a transport error, a timeout, a closed connection) means the
  click may be queued and may be sent; the door does not remember keys, so calling it again with the same key
  queues a second click with new random ids. A 500 'failed' or any 409 from the door means nothing will be
  sent." (b) A board message to the viewer's pass-through track (B6) saying the same: until K14 the
  pass-through must answer "not known" (not "failed") for a queue that got no answer, and the viewer must not
  send that key to the door again; it can show the chat's ledger rows instead. (c) K14's memory must outlive a
  restart (case 1 above retries against the next run), so a memory of minutes in RAM is not enough: the key
  belongs in the ledger row.

---

## Should fix

### S1. A malformed click that passes the route's shape is answered "failed" (500), never a refusal. CONFIRMED by reading
- **Where:** the route checks only the form of each field (`clicks.go` 440-452: kind, key, ids not below 0,
  messages 1 or more and at most 100), not which fields a kind may carry; `click_api.go` `QueueClick` checks some
  (`ErrNotAClick` for messages on another kind) but not an emoji, a reply, a target, a source or a text on the
  wrong kind, nor an id twice; `catalog.checkClick` (`schema_act.go` 517-587) then refuses with
  `catalog.ErrBadAct`, which has no row in `clickWordTable`, so the answer is 500 "failed" and a log line.
- **Sequences:** `{"kind":"send","text":"x","emoji":"y",...}` (line 549); `{"kind":"send","target":5,...}`
  (543); `{"kind":"delete","msgs":[7,7],...}` (575); `{"kind":"send","text":"",...}` (533). Each: nothing
  queued, 500 "failed". The seam file's words for these are "not a click" and "empty".
- **Harm:** a refusal shown as a failure, which the viewer treats as "try again" and which logs as a fault.
  Nothing is sent, so it is not a must-fix.
- **Smallest change:** one row in `clickWordTable`, `{is: sentinel(catalog.ErrBadAct), word:
  server.ClickWordNotAClick}` (the ledger's own "not a click the ledger takes; nothing was written"), placed
  before the `ErrNotFound` row; move `catalog.ErrBadAct` in `TestClickDoorWordTable` from the "no row" list to
  the rows. ("empty" can wait for K14's text limits.)

### S2. Answers on the door's paths that are not in the door's form. CONFIRMED by reading and probe
- While the collector starts, stops, or its pages could not be made, `pages.go` 216-218, 243 and 310-311 answer
  503 `{"error":"..."}` (no `word`); an unknown path under `/api/act/` is the mux's plain-text 404; another Host
  is a plain-text 421. The probe `TestReviewProbeDoorPathForms` saw 307, 403 and 404 answers for unusual path
  forms (none reached the seam).
- **Harm:** the caller cannot tell "starting/stopping, nothing queued" from a failure unless it reads the
  status. The report mentions the 503; the 404 and 421 are not mentioned.
- **Smallest change:** in `pagesUnavailable`, for a path under `/api/act/`, answer
  `{"word":"not running","until_ms":0}` (503 is fine); and list the 404/421 forms in the report's answer table
  so the pass-through maps them (both mean nothing was queued).

### S3. Two words the door answers on the state route that the viewer does not know. CONFIRMED by reading
- `stateWhys` adds "setting" (`clicks.go` 186-189) and the adapter's `State` answers 409 "not found" for a chat
  the catalogue does not hold (`livepages/clicks.go` 288-290). The seam file says the viewer shows any state
  word other than the six as "failed". The author lists the first as a departure.
- **Harm:** a setting that cannot be read (a real, known stop of all clicks) shows as "failed" with no hint to
  write it anew.
- **Smallest change:** a board message to the viewer's track: add "setting" (and "not found" from the state
  call) to the viewer's state words, with their sentences; and add both to `SEAM-B5-viewer-act.md`.

---

## Minor

1. **The test of "too many messages" does not test the count.** `clicks_test.go` 616 sends 101 zeros, which the
   check "an id below 1" refuses first. CONFIRMED: with `len(in.Msgs) > doorMaxMsgs` removed from
   `clicks.go` 442 (overlay), `TestDoorBadBodies` still passes, and the probe `TestReviewProbeDoorTooManyValidMsgs`
   (101 ids 1..101) gets 200 with one seam call. Not one of the author's 17 mutations. The collector refuses it
   too (`click_api.go` 423, 441), so no harm. Change: 101 ids of 1 or more in that case.
2. **The table test guards only `var Err...` in `click_api.go`.** `TestClickDoorWordTable` parses that one file.
   An error that reaches the door from `click.go` or the catalogue (S1's `ErrBadAct`, or a K14 sentinel declared
   elsewhere, or an error type) has no such guard. Say so in the test's comment, or parse the files K14 touches.
3. **`ReadDoorFile` can return a path in its error.** On Windows `openShared` hands `os.NewFile(uintptr(h), p)`
   the full path (`door_windows.go` 57; on other systems `os.Open` does the same); a failure of `io.ReadAll`
   (`door.go` 256-259) is an `*os.PathError` naming that path, returned unfixed by `readOnce`, `ReadDoorFile` and
   `Remove` (line 213). The report says every other read failure names only "door file". CONFIRMED by reading
   (`os.File.Read` wraps with `f.name`); hard to provoke. Change: `return Door{}, fixed(err)` at line 259, or
   give `os.NewFile` the name `pathWord`.
4. **The held stop refuses cancel, verdict and not-arrived while clicks can still be sent.** During a stop held
   for a sign-in (up to `SignInHold`, 15 minutes) every door route answers 409 "not running", but the accounts'
   loops still run and `click.go` does not look at `stopAsked`. A click already queued can still go out, and its
   cancel is refused. Queued clicks rarely linger (a wait or the cap ends them "not sent"), so the harm is small.
   Change: let cancel, verdict and not-arrived (they send nothing) through during the hold, or say in the
   report that "not running" here means "takes no new clicks".
5. **The door file outlives the door.** It is removed in `runWithPages` after `c.Run` has returned
   (`pages.go` 475), so after the collector's lock is released and possibly many seconds after the listener
   closed. `Remove` compares the secret first, so a newer start's file survives except in a window of
   microseconds between `readOnce` and `os.Remove` (a TOCTOU, `door.go` 207-223). Change: call `closeDoor` at
   the end of `p.stop()` (the listener is closed there and the lock is still held).
6. **The settings rows' failure text.** On a 502 the script shows "Not stored: The settings of acting in chats
   could not be read or written now: whether a change was kept shows at the next reading."
   (`clicksettings.js` 41-43 with `clicks.go` 556). "Not stored" is not known after a failure. Change: no prefix
   for a 5xx, keep "Not stored:" for the 400 refusal.
7. **`WaitWork` and `s.bg.Add` in a route.** `doorWork` adds to the WaitGroup inside the handler, as the estimate
   does. A door handler that has not reached `Add` when `WaitWork` begins would have to be past both stop bounds
   with its body read; `hs.Close()` has then closed its connection and `p.work` is cancelled, so its seam call
   fails before writing, and a call already in a transaction is rolled back by its context; `cat.Close` waits for
   statements in flight. Nothing can be written after the catalogue is closed. Not a real race; no change asked.
8. **The cap's "when" sentence.** "Stored at once; it holds from the next click." The cap is read at each click's
   turn, so it also holds for clicks already queued and not yet turned. "from the next click sent" is exact.
9. **Small strictness.** The content type is matched by prefix (`application/jsonx` passes); `encoding/json`
   matches field names case-insensitively (`"KEY"` is taken as `key`). Harmless.
10. **The door file follows `-db` as given.** A relative `-db` puts `act-door.json` relative to the start
    folder, as the catalogue itself is. The viewer must resolve the catalogue's folder the same way.

---

## The author's departures and doubts, judged
- **A late seam's success answered 200:** right. Within the door a queued click is never answered "failed". What
  the caller can conclude is in M1: 200 queued; 409 and 500 nothing will be sent; no answer is unknown.
- **403 for every method but POST, and for the browser's marks, one body:** right; the brief allowed 403 or 405.
- **The held stop answered 409 "not running":** acceptable. No other path queues a click (`QueueClick`'s only
  caller is the door's adapter, `pages.go` 516); a request that passed the check just before the stop was asked
  goes on, as a click made before the stop. The wording and cancel during the hold: minor 4.
- **`s.bg.Add` against `WaitWork`:** not a real race (minor 7).
- **`Content-Type: application/json` required:** fine; the pass-through must set it (Go's client adds no
  browser marks).
- **`ClickInput(in)` in `pages.go`:** a plain conversion between struct types needs the same field names and
  types in the same order. When K14 adds `Key`, the build breaks until `livepages.ClickInput` gains `Key` at the
  same place. The break forces the field, not its use: `clickSeam.Queue` builds the collector's input with a
  keyed literal (`livepages/clicks.go` 218-219) and would compile with `Key` left empty. K14's merge must also
  set `Key: in.Key` there, with a rig test that two queues with one key give one ref, one row and one request.
- **`State`'s cost:** five keyed reads (`c_hold` by its primary key `(account_id, kind, ...)`,
  `tg_forward_refusal` by `account_id`, `chat` by `id`, two settings) and a copy of the accounts under `c.mu`; no
  walk, no request. Fine for one call per open chat every few seconds.
- **`catalog.ErrBadAct` with no row:** I ask for the row (S1).
- **The K9c comment contradiction** (`ClickNotArrived` vs `SendClickAgain` on tryAgain/notInChat): real, in
  Core's code; not this branch's.

---

## Error of the collector -> the door's word (as the code has it)

Rows that differ from `SEAM-B5-viewer-act.md` are marked **DIFFERS**.

| Error reaching the door | Where it comes from | Door's answer |
|---|---|---|
| `ErrNotRunning` | every entry point (no catalogue, no session, session ending; also after a commit via `queuedFor`, the row "not sent" or swept, never sent) | 409 "not running" |
| `ErrClicksOff` | Queue, Again | 409 "clicks off" |
| `ErrClickNotOwn` | Queue (edit, delete) | 409 "not own" |
| `ErrClickChannel` | Queue (edit, delete) | 409 "channel" |
| `ErrClickNoMessage` | Queue | 409 "no message" |
| `ErrReadMarksOff` | Queue, Again (read) | 409 "read marks off" |
| `ErrClickSetting` | Queue, Again (read) | 409 "setting" |
| `ErrClickNotTip` | Cancel, Again, Verdict, NotArrived | 409 "not tip" |
| `ErrClickState` | Cancel, Again, Verdict, NotArrived | 409 "state" |
| `ErrNotAClick` | Queue | 409 "not a click" |
| `catalog.ErrNotFound` (wrapped) | Queue, Again, Cancel; State's chat | 409 "not found" |
| `ErrClickCapRange` | SetCap only | 400 on the Settings page, the collector's sentence (not a door word) |
| `telegram.ErrActFrozen` | none reaches the door today | 409 "frozen" |
| `telegram.ErrAccountRestricted`, `*AccountRefusedError` | none today | 409 "writes stopped" |
| `telegram.ErrActMirror` | none today | 409 "mirror" |
| `telegram.ErrForwardsRestricted` | none today | 409 "protected" |
| `*telegram.ActRefusedError` with Earlier | none today | 409 "refused earlier" |
| `telegram.ErrNoAccessHash` | none today | 409 "not addressable" |
| `telegram.ErrNoLimits` | none today | 409 "limits unknown" |
| `*telegram.ActCapError` | none today | 409 "cap" with until_ms |
| `*telegram.WaitRunningError` | none today | 409 "wait" with until_ms |
| `telegram.ErrActText` | none today | 500 "failed" **DIFFERS** (seam: "too long" or "empty") |
| `catalog.ErrBadAct` (a field of another kind, an id twice, a send or edit without text) | Queue, reachable today | 500 "failed" **DIFFERS** (seam: "not a click"; "empty" for no text) (S1) |
| `telegram.ErrMethodFrozen` | none today | 500 "failed" **DIFFERS** (seam's "frozen" would cover it) |
| `*telegram.ActRefusedError` without Earlier, `telegram.ErrActBadAction` | none today | 500 "failed" (not in the seam's table) |
| `catalog.ErrBadActLedger`, raw `catalog.ErrActState` | not expected at the door (`ownerActErr` maps `ErrActState`) | 500 "failed" |
| context cancelled (the stop) or deadline (15 s) | any | 500 "failed", nothing queued |
| any other (the catalogue, the random source) | any | 500 "failed" |
| "key", "queue full" | nothing maps to them before K14 | **DIFFERS** (seam's fix round expects the door to answer a known key with its ref) |
| (the door's own) the stop held | route wrapper | 409 "not running" |
| (the pages' gate) starting, stopping, pages not made | `pages.go` | 503 `{"error":...}`, no word **DIFFERS** (S2) |
| (the door's own) the state answered with "setting", or 409 "not found" | `State` | **DIFFERS** from the viewer's six (S3) |

---

## For the viewer's pass-through and for K14

**The pass-through must:**
1. Find the door with `actdoor.ReadDoorFile(<the catalogue's folder>)`, at each call or again after a 403 or a
   refused connection. `errors.Is(err, os.ErrNotExist)`: no door now, "not running". `ErrNotWhole`: failed.
   A refused connection (a crash leaves the file and its old port): "not running".
2. Send a POST with `Content-Type: application/json`, exactly one `X-Tgarchive-Door` header, and none of
   `Origin`, `Cookie`, `Sec-Fetch-*` (never copy the browser's headers onto the door's request). Never put the
   secret in a page, a URL, a log or an error text; never take a click for the door from the home-network
   listener.
3. Read the answers this way. 200: done, `{"ref":n}`. 409 `{"word"}`: refused, nothing will be sent (the one
   exception, "not running" from a queue at the moment a session ends, leaves a row "not sent" that is never
   sent). 400 "bad request", 403 "refused", 404 "no door", 404 plain text, 421 plain text, 503 `{"error"}`:
   nothing queued. 500 "failed": nothing queued (proven for the queue: after the commit the collector returns
   only "not running"). **No answer** (a transport error, a timeout, a closed connection): **not known**; until
   K14, never send that key to the door again. Show "not known" and the chat's ledger rows.
4. Keep its deadline above the door's 15 s (20 s does). A late seam is still answered 200 after the deadline.
5. State: `why` may be "setting"; a chat the catalogue does not hold is a 409 "not found"; `max_text` is 0
   today (no sends or edits); `write: true` does not mean the chat will take the click (the click's row says).
   Fields it does not know are to be ignored (K14 adds some).
6. Again, cancel, verdict and not-arrived can be called again after no answer: the ledger makes them once-only.

**K14 must:**
1. Add `Key` to the collector's `ClickInput` and to `livepages.ClickInput` at the same place, set
   `Key: in.Key` in `clickSeam.Queue` (the build break does not force this line), and add a rig test: two
   queues with one key give one ref, one row, one request; the same key with another content gives "key".
2. Keep the key in the ledger row, not only in memory: the risky retry (M1, case 1) comes after a restart.
3. Declare its new sentinels in `click_api.go`'s `var` block (so `TestClickDoorWordTable` sees them) and give
   each a row and a `ClickErrors` field; map `catalog.ErrBadAct` (S1) and the text's limits to "not a click",
   "too long" and "empty".
4. When `Collector.ClickState` replaces the body of `State`, agree the extra state words ("setting", "not found")
   with the viewer (S3).

---

## Checked and found sound
- **Who can open the door.** `guard` runs the Host check, then sends every path `/api/act` or under `/api/act/`
  (`r.URL.Path`, decoded) to `doorGuard` and returns; the page's rule never sees it. Probe
  `TestReviewProbeDoorPathForms`: 11 path forms (`//api/act/queue`, `/api/x/../act/queue`, `/api/act/./queue`,
  `/api/%61ct/queue`, `/api%2Fact/queue`, `/API/act/queue`, a trailing slash, `//` inside, `/./` first, `%2F` at
  the end, `/api/actx/queue`), each with the page's token and same-origin marks, and each with the secret alone:
  22 requests, 1 reached the seam: `/api/%61ct/queue` with the right secret, which is the door itself (decoded
  path), correctly opened. Every form that the guard did not treat as the door was redirected by the mux (307) or
  refused or not found; none reached a handler. Probe `TestReviewProbeDoorHeaderForms`: two door headers (right
  and wrong, either order), the secret with spaces, the secret in upper case: all 403, no seam call. The secret
  is compared in constant time (only its length can show, and it is fixed). An empty secret: `New` refuses a
  secret not of the form; "" means no door: routes not registered, the guard answers 404 "no door"
  (`TestDoorPagesDoorFile` covers a door file that could not be written). A browser page on any site cannot
  send the custom header without a preflight (OPTIONS: 403), carries `Origin` and `Sec-Fetch-*` (403 before the
  secret), and cannot learn the secret (no answer carries it). The secret is read by no other route;
  `TestDoorSecretOpensNothingElse` covers it.
- **The door file.** Written whole by a temporary file and a POSIX-semantics rename (`os.Root.Rename`, the
  watchdog's way) with a 2 s bounded retry; on Unix the temporary file is 0600, on Windows it takes the
  folder's rights; nothing left on failure; an older file replaced; `Remove` only with this run's secret; the
  reader retries for about 100 ms on not found, refused, or not whole. A second collector on the same folder
  fails on the catalogue's lock (`acquireLock` in `Run`) and its pages never reach `attach`'s write. The secret
  is in no log (only the fixed line), no answer, no error (`fixed`), not in the catalogue or the status file;
  `Server` keeps it in an unexported field. Nothing depends on this PC's paths or a script (minor 10 aside).
- **Exactly once, and the words.** Every route answers once on every path (the author's `onceWriter`, and my
  reading); no loop, no retry in the door; a refusal outside the closed set and any other error become 500
  "failed", logged as the route's pattern and the error's Go type only. Wrong JSON types, numbers beyond int64,
  floats, negative refs, two objects, unknown fields, more than 100 messages, over 64 KB: 400 and no seam call.
- **A caller that goes away.** The five acting routes run on `p.work` with 15 s and are not cancelled by the
  caller; the state route keeps the request's context; the stop cancels the work after 3 s and waits up to 10 s;
  no goroutine is started by the door; `p.doorSecret` is written by `attach` and read after `<-attached`.
- **The adapter's map** (table above): `errors.Is`/`errors.As` through wrapping, first match, no row is a
  failure; `ClicksOf` is nil if any door or sentinel is missing. `State` reads no table and sends nothing.
- **The Settings rows.** The page's token rule and the held stop's refusal through `handle`; a value that
  cannot be read is shown as that ("cannot be read... write it anew"), never as the default or "off" (the
  adapter zeroes the numbers and clears "on" when bad); a refused cap stores nothing (collector's
  `CheckClickCap` first); changing "mark as read" sends nothing (`SetMarkAsRead` writes one setting); over the
  cap a click is "not sent" (`clickWhy`: `ActWhyCap`), as the row says.
- **The tests.** No test of the base removed (count 0). The guard test uses a non-nil fake seam. Real-time waits
  are bounded (10 s, 2 min, a 300 ms sleep); one positive time check (`TestDoorDeadline`: under 5 s for a 100 ms
  deadline) could fail on a very loaded PC, never pass wrongly. Re-run here: `TestDoor|TestClicksSettingsRows` in
  `internal/server` ok (2.6 s); `internal/actdoor` ok (0.5 s). Mutations M1 to M17 checked by reading against
  their tests; each would fail its named test.

## Not looked at
- The collector's rig tests were not re-run (`internal/collector` is slow; read only). No race run.
- A real Windows reader holding the door file during the rename (only reasoning from the watchdog's lessons).
- The Settings rows in a browser; `dom.js`'s `h` was not read (the rows' text is fixed words and numbers).
- K9c's own code (`click.go`, `act_settle.go`) beyond the lines the door's answers depend on.
- The viewer's side (`wip/b-compose`) beyond the seam file.

Probe files (scratch, not in the tree): `wt-pages-review-g8-scratch/server_probe_test.go`,
`mut1/clicks.go` (the count check removed), `overlay-probe.json`, `overlay-mut1.json`.

---

# Second pass (0521253c)

Reviewed: `git log 6d4b1770..0521253c` (13 commits) and their difference in the door's files. The merge 6d4b1770 was not
reviewed. `git diff e4a4a61d 0521253c --stat` shows the 14 door files and nothing else. The tree was left
untouched (`git status` clean). Probes and mutations ran from `wt-pages-review-g8-scratch/p2` through
`-overlay`, one go command at a time, the PC measured before each (free memory 5.2 to 5.6 GB, CPU 31 to 56 %).

**Verdict: may be listed.** No must-fix and no should-fix. Five minor findings below; four of them are wording in
the report or a comment.

Counts for this pass: must fix 0, should fix 0, minor 5.

## The first pass's findings
| Finding | State | Lines |
|---|---|---|
| M1 what no answer means | **fixed** | `server/clicks.go` 467-474 (`handleActQueue`'s comment); `livepages/clicks.go` 222-231 (`Queue`'s comment); report section 2, lines 36 and 64-70. Read against the code: true. |
| S1 `catalog.ErrBadAct` | **fixed** | `livepages/clicks.go` 187-190, before `ErrNotFound`; the table test and `TestDoorPagesQueueOnFakeTelegram` (a send with an emoji: 409 "not a click", no row, no request). One side effect: new minor P2-3. |
| S2 door paths while unavailable | **fixed** | `collector/pages.go` 263-269; `TestDoorPathsWhilePagesUnavailable`. |
| S3 "setting", "not found" | **fixed** (wording, as decided) | report 91-93. The viewer's side is not in this branch. |
| minor 1 count test | **fixed** | `server/clicks_test.go` 625 (`ids(101)`), and 100 ids taken. M18 caught (below). |
| minor 2 table test's scope | **fixed** | `pages_clicks_test.go` 108-114. |
| minor 3 path in a read error | **fixed** | `actdoor/door.go` 254, 258-260 (`fixed(err)`); `door_windows.go` 57-59 (`os.NewFile(..., pathWord)`). |
| minor 4 cancel during a held stop | **fixed** | `server/clicks.go` 268-293 (`stopKeepsDoor`); `TestDoorHeldStop`. |
| minor 5 file outlives the door | **fixed in part** | `collector/pages.go` 456-459 (`closeDoor` at the end of `p.stop()`), 511-532 (`doorMu`). It holds while the collector still runs. When `Run` ends by itself, `p.stop()` runs after the lock is released (P2-2). |
| minor 6 "Not stored" on a failure | **fixed** | `clicksettings.js` 41-44 (`err.status === 400`; `ApiError` carries `status`, `api.js` 7-9). |
| minor 7, 9 | nothing done, as decided | |
| minor 8 the cap's sentence | **fixed** | `server/clicks.go` 573. True of `clickWhy` and the turn. |
| minor 10 relative `-db` | **fixed** in the report | report 113-116. |

## What the round rebuilt, checked

**a. The held stop's route wrapper.** During a held stop, only cancel, verdict and not-arrived reach the seam
through the door (`clicks.go` 283: `!stopKeepsDoor[pattern] && s.stopHeld()`; the keys are the same pattern
constants the loop registers). Of the page's routes, `GET /api/clicks/settings` still reads (a read, as before),
and the two POSTs are refused by `refusedWhileStopping`. The wrapper either writes the 409 and returns, or calls the
route once, so each route still answers exactly once.

A cancel during the hold is safe on every path:
- `CancelClick` uses `c.runningCat()`, which stays set during the hold (the hold comes before `p.stop()`).
- `ClickNotSent` updates only `WHERE id = ? AND state = 'queued'` and the click's turn takes it only
  `WHERE ... state = 'queued'` (`BeginClick`), both through the single writer. So either the cancel wins and
  the turn finds it spent (nothing sent), or the turn wins and the cancel is 409 "state".
- A cancel still in flight when the hold ends follows the same stop bounds as before (gate 3 s, then its context
  is cancelled and the transaction rolled back).

Mutations: **M20** (the queue let through during the hold) fails `TestDoorHeldStop`; **M21** (the cancel refused)
fails `TestDoorHeldStop`. Both CAUGHT. The head passes.

**b. `closeDoor` at the end of the stop, and `doorMu`.** `openDoor` takes the mutex only to set the secret, after
`actdoor.Write`. `closeDoor` holds it across `actdoor.Remove`, which is at most one read and a remove tried again
for up to 2 s on a reader's refusal. Nothing the stop waits for takes `doorMu`; `attach` may wait on it for up to
2 s but nothing waits on `attach` until after `<-stopped`. So there is no deadlock. In the worst case the stop
takes up to 2 s longer (a reader holding the file without delete sharing), after the listener is already closed.

**A start whose `attach` writes the file after the stop removed it:** the stop's `closeDoor` finds no secret and
leaves the file. `openDoor` then sets the secret, and `runWithPages`'s second call removes the file after `Run`
returns. The door is never served with a secret whose file is gone: the stop's removal comes after
`<-p.served`. The reverse case (a file whose door is not served) lasts until that second call, as before the round.

**Two runs on one folder:** the second fails the catalogue's lock in `Run`, its `attach` never writes, and its
`closeDoor` has no secret.

**M22** (the stop's removal taken out) fails `TestDoorPagesDoorFile` ("the door file after the pages' stop"):
CAUGHT.

**c. S2's lines.** The new branch is first in `pagesUnavailable`, before any method look, for exactly
`isDoorPath`'s paths, with a constant body. All three callers reach it:
- the closed gate in `ServeHTTP`;
- `starting` (only `GET /` is a page);
- `failedPages` (its own Host check first: another Host is 421 plain text there).

It leaks nothing. Compared with e4a4a61d, the only change to `pagesUnavailable` is that inserted branch; the
`/api/` JSON answer and the plain-text answer are unchanged byte for byte.

**d. S1.** Within the door's entry points, `catalog.ErrBadAct` comes from `checkClick` (the click's form),
`ActMessages` (bounded by the route already), and two fixed-constant checks (`ClickNotSent`'s reason,
`ClickVerdict`'s word). `ErrBadActLedger` is a separate `errors.New` (no wrap), and nothing in the catalogue or
`click*.go` wraps two sentinels together. So a damaged ledger is not swallowed: it is still "failed". One kind of
fault is: P2-3.

**e. Minor 3 on Windows.** `openShared` names the opened file "door file", so a later `Read`'s `*PathError`
carries those words, and `readOnce` passes it through `fixed` anyway. The open's own error is built with `pathWord`.
`UTF16PtrFromString`'s error names nothing. In `Write`, the file from `CreateTemp` carries the full path, but every
error leaves through `fixed` (lines 169 and 185), and `os.Root.Rename`'s `*LinkError` with relative names is turned
into a `*PathError` with the fixed words. No path can reach an error of `actdoor`. The author's test opens a folder
through `os.Open`, so it covers `fixed`, not the Windows name. That is right as far as it goes: by reading, the
name is harmless either way.

**f. Mutations, each by overlay, the named test run:**

| Mutation | Test run | Result |
|---|---|---|
| M18 (the count check removed) | `TestDoorBadBodies` | FAIL, CAUGHT |
| M19 (the read's error not made fixed, `door.go` 260) | `TestDoorFileReadErrorNamesNoPath` | FAIL, CAUGHT |
| M20 | `TestDoorHeldStop` | CAUGHT |
| M21 | `TestDoorHeldStop` | CAUGHT |
| M22 | `TestDoorPagesDoorFile` | CAUGHT |
| S1's row removed (mine) | `TestClickDoorWordTable` | FAIL on all five entry points, CAUGHT |

At the head: `TestDoorHeldStop`, `TestDoorBadBodies`, actdoor `TestDoorFile*` (7), `TestDoorPagesDoorFile` and
`TestClickDoorWordTable` all pass. M15 being missed now is by design, as the author says: only the race of P2-2's
second case would show it.

## New findings (all minor)

**P2-1. The report's section 2 says a trailing slash gets the mux's 307 redirect: it gets a plain-text 404.
CONFIRMED** by the probe `TestReviewProbeP2PathFormStatus` (`/api/act/cancel/` with the secret: 404;
`/api/act//cancel`, `/api/act/./cancel`, `/./api/act/cancel`: 307; seam calls 0). Report lines 60-62.
Nothing is queued either way. Change: "a trailing slash: 404 plain text".

**P2-2. "The collector's lock still held" is not true when the collector ends by itself. CONFIRMED by reading.**
`pages.go` 482-494: on `runDone`, `Run` has returned (its `defer lk.release()` ran) before the stopper calls
`p.stop()`. Its comment at 456-458 and report line 134 say the lock is still held. In that case the window
of the first pass's minor 5 is unchanged: a new start that took the lock and wrote its file between `Remove`'s
read and its remove would lose its file. That is microseconds against a start's seconds. Change: say "while
the collector runs (when its stop was asked; when it ended by itself, after)". No code needed.

**P2-3. S1's row also answers some faults as the refusal "not a click", not "failed". PLAUSIBLE** (needs a
damaged catalogue row or a broken clock). `checkClick` (`catalog/schema_act.go` 525-530, 545, 555) refuses with
`ErrBadAct` for a chat or source that "cannot be addressed" (`TgChat.valid()`: the chat row's kind or id as
`ReadableChats` read it), for "no time of the click" (`ClickedMs <= 0`, the clock), and for "a random id of 0".
Sequence: a chat row whose stored kind is damaged, and the owner reacts in it. Then `QueueClick` reaches
`checkClick`, the answer is 409 "not a click" and nothing is logged, where the first pass's rule wants a logged
failure. Nothing is queued, so no harm beyond the word. Change, if wanted: none in the door. K14, which adds the
text checks at the queue, can give the click's own form its own sentinel in the collector (`ErrNotAClick` before
`checkClick`) and leave `ErrBadAct` a failure.

**P2-4. Report line 169: "`TestClickDoorWordTable` fails until `click_api.go`'s new errors have rows".** True
only for `var Err...` declared in `click_api.go`. The test's own comment now says so; the report line does not.
K14 builds to it. Change: add "(declared as `var Err...` in `click_api.go`; any other new error needs its row
added by hand to the test)".

**P2-5. Report line 51, "The program's stop is held (sign-in hold)", is narrower than the code.**
`pagesSource.StopHeld` is true from the moment a stop is asked from the pages or by Ctrl-C (`stopAsked`), whether
or not a sign-in holds it, until the gate closes (then the 503). The answers are as stated; only the condition is
wider. Change: "the program's stop was asked (and, for a sign-in awaiting its code, held)".

## Section 2 of the report at 0521253c, every line not true of the code
- Lines 60-62: "a trailing slash: the mux's 307": it is 404 plain text (P2-1).
- Line 134: "the collector's lock still held": not when the collector ended by itself (P2-2).
- Line 169: the table test fails "until `click_api.go`'s new errors have rows": only for `var Err...` declared there (P2-4).
- Line 51: "(sign-in hold)": the condition is any stop asked (P2-5).
- Lines 91-96: "A chat the catalogue does not hold is the refusal 409 'not found'" stands twice (true, repeated).
- Line 158: "the entry points of `click_api.go` as at d6415255": now from the main head (a294e8d5, the same
  content). True in substance.
- Line 101-103 (S1's sentence): true for the click's form; it does not mention P2-3's faults.

Everything else in section 2 I checked against the code at 0521253c and found true:
- the guard's order and answers;
- the held stop's three and three routes;
- the 503 door body;
- the queue's meanings, including "500 or any 409: nothing will be sent" with its one exception;
- bodies, answers and the route table;
- the deadlines;
- the Settings routes;
- the door file's place, fields, reader, errors, writer and removal;
- the seam's methods and words.

## Not looked at in this pass
- The merge 6d4b1770 and other tracks' files.
- The collector's whole package and any race run.
- A real Windows reader during the rename.
- The rows in a browser (the author reports a look).
- The board messages to the caller tracks: reported to me, not read.

Probe files: `wt-pages-review-g8-scratch/p2/forms_probe_test.go`, `m18`..`m22` (mutated copies), `ov-*.json`.
