# Review of G3: sign in from the Accounts page (wip/pages-g3 at c49b27ac against ee437a46)

Independent, read-only review, 2026-11-15 22:02. The tree `wt-pages-g3` was not changed. Probes ran on the fake
Telegram with invented numbers and codes only, loaded with `go test -overlay` from
`C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g3-scratch` (`overlay.json`, `g3review_probe_test.go`,
`g3probe_hook.go`, and `signin_pages_hooked.go` = `signin_pages.go` plus one hook call after the `stopAsked` check, used
by P1 only). One go command, `GOGC=25 GOMAXPROCS=2 go test -p 1 -run TestG3Probe ./internal/collector`: 5 probes, all
ran, 10.8 s.

Count: **3 must-fix, 6 should-fix, 9 minor.** Marks: CONFIRMED (a probe or quoted lines prove it) or PLAUSIBLE (what
would settle it is said).

---

## Must be fixed before the merge

### M1. A code request already past the `stopAsked` check when the stop is asked: the code is sent, and Run then holds the stop for `SignInHold` with the pages closed (the author's doubt) — CONFIRMED (probe P1)
Files: `collector/signin_pages.go` 175-206 (`stopAsked` checked first; `c.BeginSignIn` takes `signMu` only at
`signin.go` 59); `collector/pages.go` 409-417 (the stopper's hold); `collector/collector.go` 749-753 (Run's hold).
Sequence (P1): the owner clicks "Ask Telegram for a code"; the handler passes `p.stopAsked()` and is in the catalogue
reads (`removedOnRecord`, `isSignedIn`, `closeStaleSignIn`, `signInWait`) when a Quit comes (another tab, or a stop
asked from outside: Ctrl-C, the watchdog). `handleQuit`'s `SignInPending()` is false (no sign-in yet, `signMu` free):
the Quit answers 200, not 202. The stopper's `holdForSignIn` also finds nothing and `p.stop()` begins (P1: `closing`
true). The handler goes on: `signMu`, the dial, one `auth.sendCode`, the sign-in stored, 200 "code sent" (inside
`pagesStopBound`). The pages close; `endColl`; Run sets `stopBegun` and its own `holdForSignIn` finds the code awaited:
**P1 measured: 6 s after, Run had not ended, a sign-in was pending, the pages answered nothing (connection refused),
1 code request sent.** Under the watchdog there is no keyboard and no page: the code cannot be typed anywhere, the
program sits 15 minutes, then stops with exit 0 and the code is wasted. (If the dial takes longer than
`pagesStopBound`, `p.work` is cancelled instead: the code may still have been sent with its answer lost: wasted.)
Smallest close: make the stopper's decision and a code request's start exclusive. A `sync.RWMutex` on `pagesRun`
(`beginMu`): `pagesSource.BeginSignIn` takes `RLock` before its `stopAsked()` check and holds it until it returns; the
stopper, after `p.stopAsked.Store(true)`, takes and drops `Lock` before `c.holdForSignIn()`. Then a request either
saw `stopAsked` and sent nothing, or finished (stored its sign-in) before the stopper looks, and the stopper's hold
keeps the pages up for it. A named test with the hook P1 uses (a test hook in `pagesSource`, or a channel the test
holds) proves it. Also wanted: when the stopper did hold (pages ran), Run's hold should not hold again with the pages
closed (log and go on), as a backstop.

### M2. Telegram's own refusals with no rule (for example PHONE_NUMBER_FLOOD) are told as "no answer, a connection problem", with the phone step offered again — CONFIRMED (probe P5)
Files: `collector/signin_pages.go` 298-299 (`err != nil` → `OutcomeStepFailed`); `server/signin.go` 267-268, 272-273;
`telegram/errors.go` 154-162 (an answered RPC error with no rule is `engine.ErrRefused`, kept apart from
`engine.ErrConnLost`).
Sequence (P5): `auth.sendCode` answered `400 PHONE_NUMBER_FLOOD` (Telegram: too many code requests for this number).
The page: outcome "step failed", "The step got no answer from Telegram (a connection problem): nothing more was
sent. Type the account's phone number twice, then ask Telegram for a code." A second click sent a second
`auth.sendCode` (P5: 2 code requests). Each is a login attempt Telegram counts (about 5 a day) and tells the
account's other devices of; the words are false (Telegram answered) and invite exactly the request Telegram refused.
The same for any answered error at the code or password step ("type it again to try once more").
Smallest change: in `step`, `errors.Is(err, engine.ErrRefused)` (Telegram answered, no rule here) gets its own
outcome ("Telegram answered with an error this app has no rule for: nothing more is sent by itself; asking again
may count as another login attempt"), with no phone step offered at the phone stage; `OutcomeStepFailed` only for
`engine.ErrConnLost`, `ErrNetTimeout`, `ErrTimeout`, `ErrServerError` (no answer, or Telegram said it failed). Map
`PHONE_NUMBER_FLOOD` to `ErrTooManyTries` in the Telegram package (not this track's package: say so on the board).

### M3. While a sign-in stays open the dialogue can never ask for a new code: "close this and ask for a new one later" is false, and the only way out is to quit the whole program — CONFIRMED (by reading)
Files: `collector/signin_pages.go` 228-236 (`SignInStatus`: an open sign-in not in `StateNeedPhone` is always shown at
its stage, also long past `SignInHold`); `server/web/assets/js/signin.js` 177-209 (`codeStep` has no way to the phone
step) and 206 (the note); `collector/signin.go` 106 (a sign-in stays in `c.signins` until it ends: signed in,
refused, code expired, or the program's stop).
Sequence: the code does not come (sent to the app on a device not at hand, or a valid but mistyped number typed the
same twice). The owner closes the dialogue (the confirm says "opening it again goes on at the code") and later
reopens it, past the hold: the status answers `code`, the dialogue opens at the code, again and again. The rule the
report adds ("a sign-in left awaiting its code longer than `SignInHold` is closed when the owner asks for a new code",
`closeStaleSignIn`) is reachable only through the phone step, which the page never shows for an open sign-in (except
by the fault in S1). The ways out are typing a junk code (one `auth.signIn`, a wrong attempt on record at Telegram)
or Quit (all accounts stop; the next start).
Smallest change: in `codeStep`, once `hold_until` has passed (the program's clock, as the wait's countdown does), a
button "Ask for a new code (this one is then wasted)" that opens the phone step; its begin closes the stale sign-in
(after S2's order fix). Say in the note when the button appears.

---

## Should be fixed

### S1. "Busy" is one lock for every account: any account's dialogue opens at the phone step, with false words, while another account's step is in flight — CONFIRMED (probe P3)
Files: `collector/signin_pages.go` 52-55 (`signMu.TryLock`: one mutex for all accounts), 232-233 (`Busy` → stage
`phone`), 269-274 (`ErrSignInBusy` → `SignInState` busy → "This account is signed in already: nothing was sent");
`server/signin.go` 136-143 (`Open()` true for `Busy`), 619-625, 631-636; `signin.js` 107-115 (`show` paints the phone
step for stage `phone`, `busy` ignored).
P3: while account 2's `auth.sendCode` was in flight, the status of account 1 (signed in) answered busy, stage phone;
account 2's too; `/api/accounts` marked 2 rows "a sign-in is under way" (every account). The dialogue then shows the
phone fields and "Ask Telegram for a code" under "A step of this sign-in is under way now: wait for its answer." The
same happens for a fraction of the 100 ms polls while a stop is held (`signInPending` takes `signMu`). The removal
route refuses every account meanwhile. No second request leaves by itself (`closeStaleSignIn` waits for `signMu`),
but this is the door to S2 and M3's dead end.
Smallest change: a per-account "step in flight" mark (a `map[int64]bool` under its own small mutex, set by
`BeginSignIn`/`signStep` around the step) instead of `TryLock` on the shared lock; `busy` answered as its own stage
in the page (words only, no fields, asked again in a second); `ErrSignInBusy` with a step in flight maps to
`ErrSignInUnderWay`, never to "signed in already".

### S2. `closeStaleSignIn` runs before the record-of-waits check and closes sign-ins that wait for a stated wait or a password — CONFIRMED (probe P4)
File: `collector/signin_pages.go` 64-99 and 197-205.
P4 (`SignInHold` 30 s on the fake clock): code sent; the code answered `FLOOD_WAIT_7200` (stage wait, resume code).
Past the hold, a code request: the sign-in was closed ("closed for a new code request" logged), then the request was
refused by the same wait (409); the status became wait/resume phone. The code that could be typed after the wait is
gone, and nothing was gained. The same closes a sign-in at the password step (its code already accepted).
Smallest change: `signInWait` before `closeStaleSignIn`; and `closeStaleSignIn` closes only `StateCodeSent` (not
`StateNeedPassword`, not `StateWait`).

### S3. During a Quit held for a sign-in every other control still acts, and some send to Telegram — CONFIRMED (probe P2)
Files: `collector/pages.go` 167-180 (`catalog()` still given: `closing` is false while held), 409-415;
`server/liveroute.go` handleQuit.
P2: after a held Quit (202), "Start" for an account the owner had stopped answered 200 and the account dialled
Telegram again (state running); the pause answered 200. By reading, the estimate (one request) and the approval (a
read) also run. A code typed during the hold also starts its account (`signedIn` nudges the loop), which then dials
while the program stops; the page says "Signed in: the account starts by itself." The header shows nothing of the
held stop (after a reload the owner cannot see that a stop is pending). Before G3 the pages were closed during this
hold, so this is new. (Running accounts keep downloading during the hold: existing, as before.)
Smallest change: while `stopAsked`, the change routes other than the code, the password, the status, the gate's
verdict and Quit answer 409 "The program is stopping (held for a sign-in): ..." (one check in `pagesSource`/the
adapter: `StartAccount`, `StopAccount`, pause, resume, estimate, approve, collect); `signedIn` during a held stop
records the sign-in and does not nudge; the live answer carries "stopping, held for a sign-in until <time>" for the
header.

### S4. A sign-in that ends on another Telegram account leaves that account's authorization in this row's session file — CONFIRMED (by reading; the author says so too)
Files: `collector/signin.go` 129-151 (`signStep`: `endSignIn`, then `signedIn` returns `ErrWrongUser`; the session file
the dial wrote is left), 157-168; `account.go` 158-176 (`isSignedIn` trusts the file plus the record); no check of the
session's own user id when a session starts (`account.go` 534 uses `userID` for the monitor only).
What is left: `account-N.session` holds a live, authorized login of the other Telegram account (listed in that
account's active sessions; anyone with the file and the key file is signed in as it). The next code request of this
row dials with it (Telegram re-authorizes the key: probably harmless; PLAUSIBLE: settle with a real sign-in on the
test account). It runs as the other account under this row only if this row's record says signed in (a sign-out
whose record failed: `markSignedOut` logs and keeps `signedOutMem` in memory only; at the next start
`isSignedIn` is true): PLAUSIBLE, narrow. The page makes the case easier to reach than the console (a new account of
a Telegram account already in the archive: "another Telegram account than this one", though a new row has none).
Smallest change: on `ErrWrongUser`, remove this row's session file after `endSignIn` (the key on disk; nothing sent;
logging out at Telegram would be a request: the owner's call). Words for the new-row case: "This Telegram account is
account N of this archive already: nothing was recorded."

### S5. Every refusal goes back to the phone step, one click from another code request — CONFIRMED (by reading)
File: `signin.js` 107-115 (`show`: stage `refused` falls through to `phoneStep()`).
After "Telegram refused the sign-in: too many tries" (or banned, frozen, the API id refused, a payment, an email
needed, an answer this app does not know) the number fields and "Ask Telegram for a code" are shown again. The
console ends at a refusal (exit 2/1). For too-many-tries, banned and frozen another request only adds an attempt
Telegram counts and announces.
Smallest change: the refused stage shows its words and no fields; a deliberate "Try another number" link opens the
phone step for `number` and `sign-up` only.

### S6. The two-step password field may be offered to the browser's password manager — PLAUSIBLE
File: `signin.js` 211-224 (`<form>` with an `input type="password"` and `autocomplete="off"`, cleared after an XHR).
Chrome and Edge ignore `autocomplete="off"` on password fields and may offer "Save password?" when a form with a
password disappears after a fetch; saved, the password is kept by the browser. Settle: click the dialogue through in
Chrome/Edge against `TestPagesHold` and watch for the save bubble. Smallest change: `autocomplete="one-time-code"` on
the code, and for the password no `<form>` (a `div` with a button and Enter handled) plus `autocomplete="new-password"`,
or a text field with `-webkit-text-security: disc`.

---

## Minor

1. **The automatic mirror and its new-chats policy do not reach an account added (or signed in) while the program
   runs** — CONFIRMED by reading (`mirror_auto.go` 105-150: `startAutoMirror` runs once over the start's list and
   skips accounts not signed in). PLAUSIBLE consequence: with `-new-chats-download` and the automatic mirror without
   its download switch, the new account's chats may start switched on, so the page's sentence "Signing in downloads
   nothing by itself" would be false. Settle: a probe with `NewChatsDownload` and `AutoMirror` on. Existing for
   mid-run sign-ins; now the rule for every page-added account. Put on the mirror track's list.
2. **"Nothing was sent" after a dial.** `ErrSignInAttemptUnsaved` and a `MemoError`/`ErrWaitNotOver` from
   `SendCode`'s own check come after `Dial` (`signin.go` 83-95): the connection's own set-up went to Telegram. Words:
   "no code was asked for" (true) rather than "nothing was sent".
3. **"Signed in: the account starts by itself"** is false when the code was typed during a held stop (S3) or the
   program stops at once after it.
4. **Closing during a wait in the middle of the code step** asks no confirm (`signin.js` 71: `awaiting()` counts
   `code` and `password` only), though the code is held only for the hold.
5. **`unlockControls` re-enables a button the dialogue turned off** while the page was "not answering"
   (`main.js` 183-196: a button enabled at the lock, then disabled by `check()`, is enabled at the next answer). The
   server refuses the mismatch (nothing sent); only the button lies.
6. **The console's "3 mismatches in a row end it"** (`SigninUsage`) is not kept by the page (the brief: keep every
   console rule). Nothing is sent on a mismatch, so harmless; say it in the report or add it.
7. **A 409 "under way" from the phone step drops the number just typed** (`signin.js` 160-165: `phone = typed` only on
   200), so the code step asks it twice again.
8. **Removal and a code request can cross**: the removal route checks `signInOpen` under the server's lock, the code
   request reads `removedOnRecord` without it; a request between the two goes on for an account then marked removed
   — PLAUSIBLE, narrow; settle with a hook between the two in a test.
9. **Tests.** No test covers M1's window, S3 (actions during the held stop), `ErrAddedForNextStart`, a status while
   another account's step is in flight, or an answered error with no rule. `TestSignInNothingKept` reads the
   catalogue's files and every file's name, not the session file's content (by design it holds no number; one line
   would prove it). No test judges on real time in a way that can fail wrongly; `TestSignInPageDoesNotUndoOwnerStop`
   and `TestSignInWaitShownAndNothingSentInside` judge "nothing happened" over a short wall window (0.5 s and 3 s at
   the fast clock's ×20), which can pass vacuously under load but not fail. `holdForSignIn`'s 100 ms wall poll only
   bounds how fast `TestQuitHeldForSignIn` ends (60 s bound): fine. The request counts are taken for the whole test
   (the hook is set before the pages start), and "nothing else before the sign-in ended" is checked: sound. The six
   mutations the report lists would be caught by the tests named (read, not re-run).

---

## Requests to Telegram, by route and sequence (point 3)

Counted on the fake where a test or probe did; else by reading. "Dial" = a connection of the sign-in's own (the gate
asked first; its set-up goes to Telegram; no sign-in method).

| Route / sequence | Requests to Telegram | Can one leave twice or by itself? |
|---|---|---|
| `gate` (each open, each "ask the VPN check again") | none (the address service once, when configured) | no |
| `add` | none | no |
| `status` (open, reload, reopen; the Accounts list for every row) | none (memory, the record of waits) | no |
| `begin`, happy path | dial + 1 `auth.sendCode` (attempt recorded first) | no |
| `begin` inside a recorded wait (any path: second click, reload, other tab) | none, not even a dial (409 with the end) | no |
| `begin` with the gate refusing | none (the gate refuses at the dial) | no |
| `begin` while one awaits its code within the hold (second click, second tab, dialogue reopened) | none (409, goes on at the code) | no |
| `begin` while another `begin` of it is in flight | waits for it; then none (409) if it stored a code, else 1 `auth.sendCode` (the owner's click) | no |
| `begin` with a stale sign-in (past the hold; reachable only via S1) | closes it (the code wasted), dial + 1 `auth.sendCode`; in a stated wait: none, but the sign-in is lost (S2) | no |
| `begin` answered with a refusal (banned, number, sign-up, frozen, app, too many, email, payment) | 1 `auth.sendCode`; the sign-in ends | the page offers the next one at once (S5) |
| `begin` answered with an error with no rule (PHONE_NUMBER_FLOOD) | 1 `auth.sendCode` | the page says "connection problem" and invites the next (M2; P5: 2 sent) |
| `begin` answered with a wait | 1 `auth.sendCode`, the wait recorded; none after it until the owner clicks | no (test) |
| `begin` past the `stopAsked` check when the stop is asked | dial + 1 `auth.sendCode`, then the code cannot be typed (M1) | no |
| `code`, right / wrong / wrong length / without the number | 1 `auth.signIn` / 1 each / none / none | no (signMu serialises two tabs) |
| `code` with the sign-in ended (program restarted, signed in in another tab) | none (409) | no |
| `code` inside a wait stated at the code | none (`ErrWaitNotOver`) | no |
| `code` expired | 1 `auth.signIn`; the sign-in back at the phone; nothing by itself | no |
| `password`, right / wrong / empty or too long | `account.getPassword` + `auth.checkPassword` / the same per entry / none | no |
| Quit with a code awaited (first) | none; the stop held, pages up | during the hold the pages may Start an account, estimate, approve (S3) |
| Quit `now` / second Ctrl-C | none; the sign-in's connection closed | no |
| Reload in the middle of a step | the step goes on (`lasting` = the pages' work context) and is not repeated | no |
| A code typed during a held stop | 1 `auth.signIn`; then its account dials while the program stops (S3) | no |

Exit codes: every path ends Run with nil, so `RunCommand` gives 0 (`command.go` 647-649): a held Quit ended by the
code, by the hold, by `now`, by a second Ctrl-C; M1's closed hold too, after 15 minutes. Nothing here restarts by
itself under a watchdog that restarts on anything but 0.

## Checked and found sound
- `c.accts`: every reader takes `c.mu` and copies (`account.go` 214, 230, 1131; `collector.go` 472; `gate.go` 38;
  `heartbeat.go` 206; `staging.go` 279; `tghourly.go` 190; `ownerstop.go` 365; `pages.go` 469); the add writes it under
  `c.mu`. Only `startAutoMirror` keeps the start's list (minor 1). The hourly rows, heartbeat, gate, lane stats, the
  refresher's mux (set per session) and the counts read the map each time, so the new account is in them; its
  `tg.open`, counters, conn watch and tally are made by `newAccount` as at the start. With Telegram id 0 the loop
  says "not signed in" and sends nothing; the monitor starts only with an id (`account.go` 534), which `signedIn` sets.
- The stop and the wait group: `stopBegun` and `supv.Go`'s `Add` are both under `c.mu`, set/done before
  `waitGroup(&mainWG)`; the group never sits at zero (settle, counts and the gate watcher are in it, also with no
  account). `supv.Go` takes only the supervisor's lock and starts a goroutine: no lock-order problem.
- The plain INSERT: the same SQL as `UpsertAccount` without its conflict clause, which would rename and revive the one
  unsigned row; a second add, an add beside a removed unsigned row and two adds at once are refused by number; two
  sign-ins of one Telegram account are serialised (`signMu`, and `SetAccountUserID` in one immediate transaction).
- Nothing typed in answers, errors or logs: `readSecret` writes fixed words; the locals are cleared; the seam's
  errors are sentinels and types; logs carry ids, states and counts; the session file's name has the id only; the
  catalogue holds the attempt's time and the wait's end only; the script keeps the number in the open dialogue only,
  empties every field, writes nothing to storage or the URL, and puts text in with `textContent`.
- A sign-in never clears the owner's Stop or a pause (`signedIn` touches neither; the page's words follow the record).
- The guard: the six routes are POST, behind the token and same origin, registered only with `SignIns`, in the
  guard's route lists; `internal/server` imports neither the collector nor Telegram; errors are mapped by type.
- The wait's countdown uses the program's clock offset (`app.live.now`) and re-enables only; nothing is clicked by
  itself. The scripts parse as modules (`node --check`: `signin.js`, `pages/accounts.js`, `main.js`, `api.js`).
- G3 improves on G1: before it, a Quit with a code awaited closed the pages first and then held for 15 minutes with
  no way to type the code.

## Not looked at, or not verifiable here
- Nothing against Telegram: the real answers' codes (PHONE_NUMBER_FLOOD and others), what a real dial sends, whether
  `auth.sendCode` on a key authorized as another user behaves as assumed (S4).
- The watchdog: not in this tree (`internal/watchdog` absent at c49b27ac); how it asks for a stop and how long it
  waits before a kill during a 15-minute hold is unknown.
- The browser: not opened (S6, the confirm dialogues, focus and screen-reader order).
- No race detector, no whole-package runs, no Docker; the author's own tests were not re-run (only the 5 probes).
- `internal/server/accounts.go` beyond the two changes; the CSS; G1's code outside what G3 touches.

## Interleavings the race detector should meet (for the main session's one run on `internal/collector`)
1. `AddAccount` across Run's stop: the row written, then `stopBegun` set before the second look
   (`ErrAddedForNextStart`), and the add's `supv.Go` racing `waitGroup(&mainWG)`.
2. `AddAccount` while `takeBeat`, `writeTg`, `netState`, `speedLimited`, `flushAll`, `targets` and the pages'
   `Accounts` copy `c.accts`; the new loop's first turn while the counts task writes its hourly rows.
3. `signedIn` (`userID.Store`, `signedOutMem.Store`, `SetSetting`, `nudge`) while the account's loop reads them and
   starts the monitor.
4. A held Quit: `SubmitCode` finishing while the stopper's `holdForSignIn` polls, then `p.stop` with the code's
   handler in flight, then Run's `holdForSignIn` and `closeSignIns`.
5. `BeginSignIn` holding `signMu` through its dial while `handleQuit`'s `SignInPending`, the status route's `TryLock`,
   a second tab's `closeStaleSignIn`, and the stop's `closeSignIns` run.
6. `ForceStop` from the page while both holds (stopper and Run) run.
7. M1's window, once fixed (the `beginMu` against the stopper).
