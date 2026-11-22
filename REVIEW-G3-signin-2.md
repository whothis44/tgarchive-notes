# Review of G3b, the sign-in page's fix round (wip/pages-g3-main at 71000827; the round is 30152dc2..71000827)

Second pass, read-only, 2026-11-15 23:58. The tree `wt-pages-g3m` was not changed (clean status). Probes on the fake
Telegram with invented values only, loaded with `go test -overlay` from
`C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g3-scratch`: `g3review2_probe_test.go` (`overlay2.json`: P1b
to P7, 29 s); one mutation of the round's M1 test (`signin_pages_g3m_norlock.go`, `overlay2-mut.json`: the code
request's read side removed: `TestSignInQuitCrossesCodeRequest` fails, "the stopper went on while a code request past
its stop check was under way"). Named server tests `TestSignInSteps*` (node), `TestHeldStopRefusesChanges`,
`TestQuitHeldWordsAndForce`: pass. The four changed scripts parse as modules with node.

New findings: **1 must-fix, 3 should-fix, 6 minor.** Of the first pass's 18: 13 closed, 4 partly, 1 closed in code
but not verifiable here (S6).

## The first pass's 18 findings

| # | Finding | Now | Evidence |
|---|---|---|---|
| M1 | Code request past the stop check; Run holds with the pages closed | **Closed** | P1b on this tree (the tree's own `beforeDial` hook): the Quit answered 200, the pages still up 1.5 s later (the stopper waited), the code request then answered "code", `/api/live` 200 with `held`, the program held; the code typed: signed in, Run ended nil; 1 `auth.sendCode`. `TestSignInQuitCrossesCodeRequest` fails with the read side removed (my mutation). Backstop in `collector.go` 760-766 present. |
| M2 | A refusal with no rule told as "connection problem", the number invited again | **Partly** | P5: outcome "no rule", no "connection problem", the number not invited in the answer, 1 request. But the refusal is not remembered: the status right after it answers stage phone with no outcome, so a closed and reopened dialogue (or a reload) shows the phone step with plain words, one click from the next request (new finding S-N1). |
| M3 | No way to a new code while a sign-in stays open | **Closed** | `codeHold` (signinsteps.js 67-81), the button past `hold_until`; `TestSignInNewCodeAfterHold` (inside the hold 409 and no request; past it one `auth.sendCode`, the old sign-in closed); node test `TestSignInStepsCodeHold` passes. Not seen in a browser by me. |
| S1 | "Busy" one lock for every account | **Closed** | P3: account 2 "busy" (its own stage, no fields); account 1's status did not wait behind account 2's step and answered "signed in", not busy. Kept-view ordering gap: minor M-N4. |
| S2 | Stale rule before the wait's check; closes wait and password | **Closed** | P4: past the hold, a code request inside the code's wait: 409 with the wait, the sign-in kept at wait/resume code, nothing closed, 1 request. The password case in `TestSignInStaleRuleKeepsWaitAndPassword`. The departure (a wait at the code that is over counts as "code sent") is sound: closing it still needs the owner's "Ask for a new code" click. |
| S3 | Controls still act during a held Quit | **Closed** | P2: Quit 202; Start 409, pause 409, the gate's verdict 200; account 1 not dialled. `TestHeldStopRefusesChanges` passes (every change route but the five). A code typed during the hold records and does not nudge (`signin.go` 184-189). Gaps: minor M-N5 (a change that passed the check just before), should S-N2 (the header's "Closed" after one failed poll). |
| S4 | Wrong user's session file left | **Closed, with gaps** | `wrongUserLeavesNothing` (signin_steps.go 232-251), tests extended. Gaps: the words always say "removed" (M-N1); a client outliving its Close may save the file again (M-N2, plausible). |
| S5 | Every refusal back to the phone step | **Partly** | Inside the dialogue: no fields after a refusal, "Try another number" only for `number` and `sign-up` (`signinsteps.js` 18-20, 44-45; node test passes). After a close and reopen: the phone step again (same as M2, S-N1). |
| S6 | Password offered to the browser's password manager | **Closed in code, not verifiable** | No `<form>`, `new-password`, Enter handled (signin.js 308-325); the code `one-time-code`. Only a real Chrome or Edge can show a save bubble. |
| m1 | Mirror's new-chats rule; "downloads nothing" words | **Closed (page part)** | `newChats` (signin_pages.go) and the words by case. The mirror part is routed to the mirror track per the brief: not checked on the board by me. |
| m2 | "Nothing was sent" after a dial | **Closed** | `ErrSignInRecordUnreadDialled`; untested (no fault injection), by reading. |
| m3 | "Starts by itself" during a held stop | **Closed** | `Stopping` words; `TestHeldStopRefusesStart`. |
| m4 | No confirm on close during a mid-code wait | **Closed** | `awaiting(stage, resume)`; node test. |
| m5 | `unlockControls` re-enables a button the dialogue turned off | **Closed** | `setOff` drops the lock mark (signinsteps.js 94-106); node test. (A different lock path stays: S-N2.) |
| m6 | Console's 3 mismatches | **Closed** | P5: two different numbers to the route: 400, 0 dials, 0 requests. The page checks `digits(one) !== digits(two)` before any request (signin.js 214-220) and counts; the third closes the dialogue. |
| m7 | A 409 "under way" drops the number | **Closed** | By reading (signin.js 224, 229-233; `show` keeps it at the code). |
| m8 | Removal and a code request can cross | **Partly** | The begin is closed by `signGate` (needed: without it the removal can look before the request's step mark and write after the request's own removed check). Its test does not fail without the lock (the coder says so). A code **submission** past the hold can still cross a removal (M-N3). |
| m9 | Missing tests | **Closed** | M1's window, held stop's routes, `ErrAddedForNextStart`, busy, no rule, session file content: all present. Notes in "Tests" below. |

---

## New findings

### Must fix before the merge

**M-1. Nothing can stop the program while a sign-in step hangs: Quit, "Quit now" and a second Ctrl-C all wait for it — CONFIRMED (probe P6), how long is PLAUSIBLE**
Files: `collector/signin.go` 59-95 (`BeginSignIn` holds `signMu` through the dial and `auth.sendCode`; the code and
password steps likewise, 129-136), 206-243 (`signInPending` and `holdForSignIn` take `signMu`); `server/liveroute.go`
79-86 (`handleQuit` asks `SignInPending()` before it calls `ForceStop`, also for `{"now": true}`);
`collector/signin_steps.go` 156-189 (`waitBegins` ends on `ForceStop`, then `holdForSignIn` blocks on `signMu`);
`server/program.go` `lasting` (the step's context is the pages' work, cancelled only in `p.stop`, which runs after
the hold).
Sequence (P6): `auth.sendCode` for account 2 does not return (held in the fake). The first Quit: no answer within
3 s. "Quit now" (`{"now": true}`): no answer within 3 s. Ctrl-C then `ForceStop`: Run had not ended 5 s later. Once
the request returned, all three went on (Quit 202, Quit now 200, Run ended). The loop is closed: the step's context
ends only in `p.stop`, `p.stop` comes after the hold, and the hold waits on the step's lock. So the only bound is the
library's own: a dial to a Telegram that does not answer behind a working VPN waits for the client's reconnect loop
(`Options.ReconnectionBackoff`, the library's default, not set by the app: `telegram/doc.go` 182), and a request on a
stalled connection for the library's own detection. Not new in this round (G3's `holdForSignIn` and `handleQuit`
already took `signMu`; I missed it in the first pass), but this round says a ForceStop ends the stopper's wait
"at once", and under the watchdog the page's Quit is the owner's only way out.
Smallest change: (1) the pages' sign-in steps run on a context of their own, bounded (for example 90 s) and cancelled
by `ForceStop` (`context.WithCancel(p.work)` kept on `pagesRun`, cancelled in `ForceStop` as well); (2)
`handleQuit` with `now` calls `ForceStop` before it asks anything; (3) `holdForSignIn` looks at `c.force` before each
`signInPending`, and `signInPending` reads a summary kept under its own small lock (or `TryLock` plus the step marks)
instead of waiting on `signMu`. Test: P6 as a named test (the fake holds the request; Quit now answers and Run ends
within a fake bound; the request's later answer changes nothing).

### Should fix

**S-N1. A refusal (and an answer with no rule) is forgotten: a closed and reopened dialogue, or a reload, offers the phone step again — CONFIRMED (probe P5)**
Files: `collector/signin.go` 96-98 and 145-148 (a refused sign-in is ended and dropped); `signin_pages.go`
`SignInStatus` (nothing open, no wait: stage phone, no outcome); `signin.js` 400-406 and `signinsteps.js` 50
(stage phone: the phone step).
Sequence: PHONE_NUMBER_FLOOD (or too many tries, banned, frozen) answered; the dialogue shows the words and no
fields; the owner closes it and opens it again (or the page reloads): the status answers stage phone with no
outcome; the dialogue shows the number fields and "Ask Telegram for a code" with no word of the refusal. One click
is the next login attempt, the one this round set out to stop inviting.
Smallest change: keep the last refusal or no-rule outcome per account in memory (beside the kept views in
`signSteps`, with its time) and answer it in the status until the owner chooses "Try another number" or "Try again"
(each saying it is a request), or until the next start; the card's facts can show it too.

**S-N2. One failed live poll during a held stop says "Closed" for good and locks the dialogue's buttons — PLAUSIBLE**
Files: `web/assets/js/main.js` `notAnswering` (sets `app.closed` when `quitHeld`), `refreshLive` (`if (app.closed)
{ notAnswering(); return; }`), `lockControls` (disables every `[data-needs-program]`, the dialogue's "Sign in with
this code" among them); `showLive` is the only unlock.
Sequence: Quit held while a code is awaited; one `/api/live` poll fails (a network blip, a 5xx); `app.closed` is
set, every later poll is skipped, the header says the program stopped and to open it again, and the dialogue's
buttons stay off. The program is still holding and waiting for that code; only a reload brings the page back, and
the words tell the owner the opposite. Settle: make `/api/live` fail once in the browser during a held stop.
Smallest change: on the held path, do not set `app.closed` on the first failure (keep polling; set it only once the
held stop's end has passed or after several failures in a row).

**S-N3. The pages' stop now waits for idle connections: a browser's spare connection delays every program stop by about 6 s — CONFIRMED (probe P7)**
File: `collector/pages.go` 397-404 (`Shutdown` within `waitBound` before `Close`).
P7: with nothing pending, Quit to Run's end took 12 ms; with one idle connection open (no bytes sent, as browsers
keep spare connections), 6372 ms. net/http's `Shutdown` treats a new connection as idle only once it is 5 s old; a
connection in the middle of a response can hold it to `waitBound` (10 s). The catalogue is still given to no handler
(the gate is closed and `closing` set before; a request read meanwhile gets 503). Bounded, but on every run's stop
and for every Quit, and the watchdog's patience is not known.
Smallest change: bound the `Shutdown` by a short time of its own (for example 1 s, or `stopBound`), enough for an
answer already written to leave.

### Minor

**M-N1. The wrong user's words always say the file was removed** (`server/signin.go` `wrongUserLeft`), also when it
stays (the row signed in on record) or `os.Remove` failed. Say it from the outcome (a flag in the status).
CONFIRMED by reading.

**M-N2. The removed session file can come back** — PLAUSIBLE. `wrongUserLeavesNothing` removes the file right after
`endSignIn`; `libConn.Close` waits at most its grace (5 s) and the client may still save after it (`dialer.go`
159-171: "the client may outlive it"). Settle: a library client that saves at its end. Change: wait for the file's
hold to be let go (`sessionHolds`, bounded) before removing, or look again after the client's end.

**M-N3. A code submission past the hold can still cross a removal** — PLAUSIBLE. `handleSignInCode` is not under
`signGate`; the removal looks at `signInOpen` (not open past the hold, no step mark yet) while the submission has
passed the server's removed check: one `auth.signIn` for an account then marked removed, and its sign-in recorded.
Change: the code and password routes take `signGate`'s read side as the begin does.

**M-N4. Two tabs can leave an older kept view** — PLAUSIBLE, narrow. `keepView` keeps a step's view whatever the
order (`signin_steps.go` 78-85, `step=true`): step A reads its view, step B (same account, another tab) runs and
keeps, then A keeps its older view. Shown only while another account's step holds the lock. Change: a per-account
version taken under `signMu`, keep only a newer one.

**M-N5. A change that passed the held-stop check just before the Quit still acts** (a Start then dials during the
hold). By reading; inherent to a check at the route's start; say it in the report or re-check in the collector's
`StartAccount`.

**M-N6. Tests.** `TestSignInRemovalCannotCrossCodeRequest` does not fail without its lock (the coder says so: the
step mark refuses in both hooked orders); `TestHeldStopRefusesStart` and `TestSignInPageDoesNotUndoOwnerStop` judge
"no dial" over a short real window (they can pass without the fix under load, never fail wrongly). No test meets
M-1 or S-N3. `TestSignInQuitCrossesCodeRequest` is sound: the request is held between its checks and its dial, the
stopper's look is checked against it, and it fails when the read side is removed (my mutation) or when the stopper's
wait is removed (the coder's). `TestSignInNewCodeAfterHold` judges "inside the hold" only when the fake clock agrees:
sound. No other test judges on real time.

---

## Requests to Telegram on the changed paths

| Route / sequence | Requests | Counted |
|---|---|---|
| Code request crossing a Quit (past its checks) | dial + 1 `auth.sendCode`; the stop then held with the pages up; the code: 1 `auth.signIn` | P1b; the round's test |
| Code request after the Quit (held), or blocked behind the stopper's wait | none (409) | P1b; the round's test |
| Start, Stop, pause, resume, add, collect, estimate, approve, settings during the held stop | none (409); no dial | P2; `TestHeldStopRefusesStart`, `TestHeldStopRefusesChanges` |
| Gate's verdict during the held stop | none to Telegram (the address service when configured) | P2 |
| Code typed during the held stop | 1 `auth.signIn`; recorded; the account not started (no dial) | `TestHeldStopRefusesStart` |
| Password during the held stop | `account.getPassword` + `auth.checkPassword` | by reading |
| Quit or "Quit now" while a step hangs | none more; both wait for the step (M-1) | P6 |
| PHONE_NUMBER_FLOOD at the code request | 1 `auth.sendCode`; no control offers another; after a reopen the phone step does (S-N1) | P5 |
| An answer with no rule at the code | 1 `auth.signIn`; "Try again" (said to be a request) then the code: 1 more | the round's test |
| New code past the hold / inside it | the old sign-in closed, 1 `auth.sendCode` / none (409) | the round's test |
| Code request inside a wait stated at the code, past the hold | none (409 with the wait); the sign-in kept | P4 |
| Two numbers that differ (route or page) | none, no dial | P5 |
| Third mismatch in a row | none; the dialogue closes | by reading, node words |
| Status while the account's step runs (busy) | none; asked again each second | P3 |
| Status of another account meanwhile | none; does not wait | P3 |
| Wrong Telegram account | the code's own requests; the session file removed; none extra | the round's tests |
| Removal and a code request | the lock: either no request (removal first) or the removal refused | the round's test |

Exit codes: unchanged: every path ends Run with nil (exit 0), M-1's included once the step returns.

## Checked and found sound
- The read-write lock against the stopper: the code request holds the read side from before its stop check to its
  return; the stopper's write side waits for it; new code requests that queue behind the waiting writer then see the
  stop and send nothing; the goroutine `waitBegins` leaves after a `ForceStop` takes and drops the lock when the last
  reader returns and ends (bounded by that request: see M-1). No lock-order cycle among `signGate`, `beginMu`,
  `signMu` and `c.mu`.
- The two holds: `pagesHeld` makes Run skip its hold only after the stopper held; with the lock no sign-in becomes
  pending after the stopper's hold ends except through `ForceStop`, which logs that the code is wasted. Exit 0.
- The held stop's routes: one check in the route wrapper for every non-GET route but the five; refused from the
  stopper's first step to the end; the live answer's `held` and the header (`heldHeader`, `paintHeld`), also after a
  reload.
- The step marks are released by `defer`; every way out of a step keeps the view it ends with (`step` reads first);
  plain reads are kept only when no step began since; an account no step ran for answers "nothing under way" without
  the lock.
- The wrong user's file: removed only for the row's own path, only when the row is not signed in on record, after its
  sign-in's connection is closed; nothing sent.
- The phone step's button on while two numbers differ: nothing is sent on a mismatch (page and route).
- Shutdown: no handler gets the catalogue after the stop began.

## Not looked at, or not verifiable here
- Nothing against Telegram; how long a real dial or request can hang (M-1's bound); whether the library saves a
  session after Close (M-N2).
- A real browser: the save-password bubble (S6), the header's freeze (S-N2), the dialogue's flows by hand.
- The watchdog (not in this tree): how long it waits for a stop.
- Whether the mirror track's item for minor 1 is on the board.
- No race detector, no whole-package runs; the coder's collector tests were not re-run beyond the mutation run.

## Interleavings the race detector should meet
1. A code request between its stop check and its dial while the stopper sets `stopAsked` and waits for the write side
   (`beginMu`), with a second code request queued behind the waiting writer.
2. `ForceStop` while `waitBegins` waits: the left goroutine taking and dropping the lock as the request returns.
3. `holdStop` reading `signInHoldUntil` while a code step runs; then a code typed: `signedIn` reading `stopAsked`
   while the stopper's `holdForSignIn` polls; then `p.stop` with `Shutdown` while that answer is still being written.
4. `signSteps`: `enter`/unmark, `look`, `remember` (plain and step) and `last` from two tabs of one account and a
   status of another account, while `trySignInState` fails behind a third account's step.
5. The removal's write side of `signGate` against a code request's read side, and a code submission crossing a
   removal (M-N3).
6. `wrongUserLeavesNothing`'s remove while the closed client may still be ending (its session hold).
7. `AddAccount` across the stop's start (`addAccount`'s hook) and against every reader of `c.accts` (first pass).
8. Run's `stopAsked.Store` and the backstop's `signInPending` against a sign-in step finishing.
