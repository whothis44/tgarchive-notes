# Brief G3b: the sign-in page's fix round, on the main head (pages track, session P3; 2026-11-15 23:05)

For one Opus coder. The piece: `wip/pages-g3` at c49b27ac in the copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-pages-g3` (Go module in `archiver/`), built from
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-G3-signin-page.md`; its builder's account is
`archiver/docs/progress/pages-g3-REPORT.md` on the branch. **Read the independent review in full first:
`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-G3-signin.md`** (3 must fix, 6 should, 9 minor; its probes are in
`C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g3-scratch`: read them; each must fail to show its fault
after your round). Every finding is accepted. This brief says how each is closed; where it and the review's
"smallest change" differ, this brief wins; where you find either wrong, say so in the report rather than build
around it.

## Why these are not matters of taste
Telegram allows about 5 login attempts per phone a day and tells the account's other devices of each: a code
request the owner did not mean, or a code that can no longer be typed, is a real cost. The owner's rules
(FEATURES 12 rounds 10 and 11): every code asked for is recorded first; a stated wait is kept and slept in
full; **the app never asks for a code again by itself and never invites a request Telegram has just refused**;
a stop is held while a code is awaited so the code is not wasted; nothing typed is kept. The program runs under
a watchdog with no keyboard: the page is the only place a code can be typed.

## Step 0: onto the main head
The main branch has moved a long way (G1 is on it as one squashed commit; the Queue page G2; Core's protected
flag and backup; the mirror's name rule; the fake Telegram's topics answer repaired). A plain merge meets many
"both added" conflicts because G1 is squashed there. So: `git fetch private`, take the head of
`private/claude/charming-feynman-vm2xia` (27a7d4d or later; write the exact commit into your progress file),
make a NEW branch `wip/pages-g3-main` from it in a NEW copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-pages-g3m`
(`git -C C:/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add -b wip/pages-g3-main ../wt-pages-g3m <head>`),
and apply the piece's own difference there: `git -C ../wt-pages-g3 diff --binary ee437a46 c49b27ac | git apply --3way --index`.
Where it meets the head (expected: `internal/server/server.go`, `security_test.go`, `web/assets/js/main.js`,
`pages/accounts.js`; `internal/collector/collector.go`, `account.go`, `pages.go`, `pages_e2e_test.go`,
`pages_test.go`): both sides stay; the head wins wherever the same line differs for a reason that is not this
piece's. The head's `main.js` lands a new page through `land(main, window)`: keep it. The head's
`TestAssetsStaySmall` holds every script under 600 lines: keep `pages/accounts.js` and `signin.js` under it.
Commit that as its own commit ("the piece on the main head"), run the piece's 17 named tests once, then start
the fixes. `wip/pages-g3` stays as it is for reference. Work only in `wt-pages-g3m`.

## The fixes
1. **M1: a code request and the stop's decision exclude each other.** A read-write lock on `pagesRun`
   (`beginMu`): the pages' `BeginSignIn` takes the read side before its `stopAsked()` check and holds it until
   it returns; the stopper, after `p.stopAsked.Store(true)`, takes and drops the write side before
   `c.holdForSignIn()`. So a request either saw the stop and sent nothing, or stored its sign-in before the
   stopper looks, and the stopper's hold keeps the pages up for it. Backstop: when the stopper has already
   held (the pages ran), `Run`'s own hold does not hold a second time with the pages closed: it logs fixed
   words and goes on. Named tests with a hook the test holds between the check and the dial (the review's P1 as
   a test): the Quit that crosses a code request ends with the pages up and the code typeable, or with nothing
   sent; never with a code sent and the pages closed.
2. **M2: Telegram's refusal is not a connection problem.** In `step`, an answered error with no rule
   (`errors.Is(err, engine.ErrRefused)`) gets its own outcome and words ("Telegram answered with an error this
   app has no rule for: nothing more is sent by itself; asking again may count as another login attempt"), with
   NO phone step offered at the phone stage and no "type it again" at the code or password stage unless the
   owner chooses "Try again" on a button that says it is a request to Telegram. "The step got no answer" stays
   only for a lost connection, a timeout and a server error. Do not edit `internal/telegram` (the mapping of
   `PHONE_NUMBER_FLOOD` to "too many tries" is the core track's: it goes on the board from the main session).
   Test: the fake answers `400 PHONE_NUMBER_FLOOD` to the code request: the words, no second request from any
   control that does not say it sends one (count the fake's requests).
3. **M3: a way to a new code, said honestly.** On the code step, once the hold's end has passed (the program's
   clock, as the wait's countdown uses), a button "Ask for a new code (this one is then wasted)" opens the
   phone step; its `begin` closes the stale sign-in after fix 5's order. The note says when the button appears.
   Before the hold's end there is no such button and the note says so. Test in node for the step's states, and
   on the fake: a new code past the hold is one `auth.sendCode`, inside the hold none.
4. **S1: "busy" is per account.** A per-account "step in flight" mark under its own small lock, set around the
   step by `BeginSignIn` and the code and password steps, instead of `TryLock` on the lock every account shares.
   `busy` is its own stage on the page (words only, no fields, asked again in a second); a busy answer never
   maps to "signed in already" (`ErrSignInUnderWay`); another account's row and removal are not marked or
   refused because of it. Test: the review's P3 as a test.
5. **S2: the stale rule cannot waste a code.** The recorded wait is checked before the stale sign-in is looked
   at, and only a sign-in at "code sent" can be closed as stale: never one waiting out a stated wait, never one
   at the password. Test: the review's P4 as a test.
6. **S3: a held stop is a stop.** While the stop is asked, every change route except the code, the password,
   the status, the gate's verdict and Quit answers 409 in fixed words ("The program is stopping (held for a
   sign-in until <time>): ..."): Start, Stop, pause, resume, estimate, approve, collect, rank, the queue's
   actions, the settings, add an account, begin a sign-in. A code or password accepted during the hold records
   the sign-in and does NOT start the account (no nudge): the words are "Signed in. The program is stopping:
   the account starts at the next start." The live answer carries "stopping, held for a sign-in until <time>"
   and the header shows it, with the explicit "Quit now (the code is then wasted)". Tests: the review's P2 as
   a test (a Start during the hold dials nothing: count the fake's dials); the header's words in node.
7. **S4: a sign-in that ends on another Telegram account leaves nothing behind.** On `ErrWrongUser`, after the
   sign-in is ended and only when this row is not signed in on record, the session file the dial wrote under
   this row's name is removed (a local file; nothing is sent; logging out at Telegram would be a request and is
   not done: say so in the words: "that login is still listed among the other account's devices: end it from
   Telegram's own settings"). For a new row the words are "This Telegram account is account N of this archive
   already: nothing was recorded." Test: the file is gone, the other account's own session file and record are
   untouched, the fake saw no extra request.
8. **S5: a refusal ends the dialogue's way to the next request.** The refused stage shows its words and no
   fields. "Try another number" (opening the phone step) is offered only for a refused number and for a number
   with no account; never for too many tries, banned, frozen, the API id refused, a payment or an email needed,
   an unknown answer. Node test of the stage for each refusal.
9. **S6: the browser is not asked to keep the password.** The password step has no `<form>` (a container, a
   button, Enter handled), `autocomplete="new-password"` on the password, `autocomplete="one-time-code"` on the
   code, the phone as now. Say in the report that only a real Chrome or Edge can show whether a save bubble
   still comes (the built-in browser may have no password manager): it stays "not verified" for the owner's
   first real use.
10. **The minors.** (1, the page's part) The sentence "Signing in downloads nothing by itself" is said only when
    it is true: when new chats start switched off (the catalogue's "chosen only" setting on record); otherwise
    the page says what the program was started with. That the automatic mirror and its new-chats rule do not
    reach an account added while the program runs goes to the mirror track from the main session: do not edit
    the mirror. (2) "no code was asked for" where a dial had gone out, never "nothing was sent". (3) "the
    account starts by itself" only when it does (fix 6). (4) Closing during a wait in the middle of the code
    step asks the same confirm. (5) A button the dialogue turned off stays off when the page's controls are
    unlocked again. (6) The console's "3 mismatches in a row end it": add it (the dialogue closes with fixed
    words; nothing was sent). (7) A 409 "under way" from the phone step keeps the number just typed for the
    code step. (8) Removal and a code request cannot cross: one lock or one order for the two checks, with the
    review's hook as a test. (9) The tests the review names as missing: M1's window, a held stop's routes,
    `ErrAddedForNextStart`, a status while another account's step is in flight, an answered error with no
    rule; one line that the session file's content holds none of the typed values.

## Rules (hard)
- Work only in `wt-pages-g3m` on `wip/pages-g3-main`. New code in new files where it can be; in the collector's
  existing files only the lent lines this piece already has plus what fixes 1, 6 and 7 need (`pages.go`,
  `signin.go`, `collector.go`: each said in the report). Not `reader.go`, the engine, the supply, the store,
  the mirror, the watchdog, the viewer, `internal/telegram`, `faketg`, the catalogue's schema (no schema step).
  The only requests to Telegram are the sign-in's own four, each on the owner's click.
- Nothing runs against Telegram: the fake only, with invented numbers, codes and passwords. Never touch
  `E:\T\tg-dl`, the folders `a3`, `b`, `app`, any real catalogue, media, session or account; start no installed
  program.
- Nothing typed is kept, logged or printed; new log, error and state text is constant words with numbers.
- No test judges on real time: a hold is a hook or a channel the test owns, a wait is the fake clock's.
- Go: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, one go command at a
  time, `GOGC=25 GOMAXPROCS=2 go test -p 1 -run '<names>' ./internal/<package>`, named tests only: no whole run of
  `internal/collector`, `internal/catalog` or `internal/server`, no race detector, no Docker. Before each go
  command: `powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`;
  wait when free memory is under 2.5 GB or the CPU is over 85% (the PC had 2.0 GB free when this was written:
  read and write first, compile late).
- After any change under `web/assets/js`: `TestScriptsNoDuplicateOrMissingNames`, `TestAssetsStaySmall` and a
  module parse of each script with node.
- **Open it before handing back:** `TestPagesHold` from your copy (`TGARCHIVE_PAGES_HOLD=127.0.0.1:8796`), the
  dialogue in the built-in browser if you have one: a refusal (no fields after it), a code step past its hold
  (the new button), a Quit while a code is awaited (the header's words, a Start refused), the busy stage. Say
  exactly what you saw and what you did not.
- Any file that holds a Windows path is written with the file-writing tool, never from inside a shell or script
  string.
- Commits: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; commit work in progress as you go and push only
  `git push private wip/pages-g3-main`. Never push, merge into, rebase or switch any other branch; never stash.
- Keep `archiver/docs/progress/pages-g3-PROGRESS.md` current and commit it with each step.

## Hand back
Commit-ready: everything committed and pushed, the tree clean, `gofmt -l` clean, `go vet` on the packages you
changed. A new section "Fix round (G3b)" at the end of `archiver/docs/progress/pages-g3-REPORT.md`: the head
you applied the piece to and every place it met that head; each finding (M1 to M3, S1 to S6, minors 1 to 9)
with what was changed and the test that now fails without it; every lent line added in the collector's
existing files; every existing test whose expectation changed and why; mutations (the read-write lock removed;
a refusal offered the phone step again; the stale rule before the wait's check; a Start let through during a
held stop; the wrong user's session file left): each applied, its test failing, undone; what you saw in the
browser and what you did not; what was NOT verified; anything in this brief you found wrong. Your final
message: the head commit, what is fixed and tested, what is not, every departure, and your doubts about the
concurrent parts (the lock against the stopper, the two holds, the held stop's routes), plainly.
