# Review: wip/fix-addacct 69c1ebb0 (base 3dd304df), several accounts waiting for their sign-in

**Verdict: fix first.** One HIGH: the one-at-a-time refusal was the only thing that kept a stated
sign-in wait in force across accounts. A probe test shows a new account sending `auth.sendCode` for the same
number while another account's FLOOD_WAIT is still running.

The schema step, the upsert and the readers are sound. Checked:
- Step 45 runs twice and on older files. It only drops and recreates `account_tg_user`, which exists since v2
  and which no other step touches.
- `ON CONFLICT(tg_user_id) WHERE tg_user_id <> 0` matches the partial index. A real id still revives its row,
  and id 0 always makes a new row.
- No product code deletes `account` rows, so an account's number is never given twice.
- `SetAccountUserID` runs one transaction with the unique index under it. Two accounts waiting that both end on
  the same Telegram user: the second is refused, its session file is removed, and nothing is recorded.
- Every reader of `tg_user_id` already treats 0 as "no key" (`otherAccountOf`, the viewer's `act_account` and
  marks, appshell, selfchat with `> 0`).
- Runs in a scratch worktree: `go vet ./...` clean; `catalog -run 'Schema|Step|PendingAcc'` ok;
  `server -run 'TestAssets|Security|SignIn'` ok; `collector -run 'TestAddAccount|ChooseSignIn|SignInCmd|WrongUser'` ok.

## HIGH 1: a new account escapes another account's stated sign-in wait
- **Where:** the wait record is per account. `telegram/signin.go` `recorded()` loads
  `memo.load(ctx, s.cfg.Account, "signin:wait")`. `collector/signin_pages.go` `BeginSignIn` checks
  `c.signInWait(ctx, account)` for this account only. The console `signin` does the same (`signin_cmd.go`
  391/487).
- **Before:** account A, waiting for its sign-in, held a Telegram-stated wait on `auth.sendCode`. The owner could
  not make another account: "Add an account" was refused, removed or not. The console's `chooseSignInAccount`
  with no live account ran `UpsertAccount(TgUserID 0)`, which revived A's row (same number, same wait).
- **Now:** "Add an account" makes B (or the console makes a new row). B's "Ask Telegram for a code" for the same
  number dials at once. That breaks "every wait Telegram states is slept in full", and Telegram's sendCode waits
  are bound to the number.
- **Evidence (probe test, deleted):** account 3 is answered `FLOOD_WAIT_3600` on `auth.sendCode` and stands at
  stage `wait`. Account 4 is then added, and `begin(4, same number)` answers 200, stage `code`, with **1
  auth.sendCode sent by account 4** inside account 3's wait.
- **Fix:** before any code request (`pagesSource.BeginSignIn`, `ResendCode`, the console `signin`, ideally also
  at the dial in `Collector.BeginSignIn`), take the latest running sign-in wait of **every account with no
  Telegram id, removed ones included**. The number is not known to the record, so stay on the safe side. Refuse
  with `SignInWaitError{Until: max}`, sending nothing. An equivalent way: also save every sign-in wait under one
  shared memo key and check it in `recorded()`. Add a test: account 3's FLOOD_WAIT, then add 4 and begin, and
  expect 0 requests from 4.

## MED 2: two accounts may ask for codes for the same number at once
- **Where:** `TestAddAccountWhileOneWaits` (signin_pages_test.go) makes accounts 3 and 4 both call
  `begin(a, phoneB, phoneB)` and asserts both stand at their own code. That makes the behaviour intended.
- **Scenario:** the owner adds an account while the first's code is awaited and types the same number. Account
  4's `auth.sendCode` for the number invalidates the first code or gets the same one. The two sign-ins then share
  a code at Telegram's end, against "two pending sign-ins never share state or codes". If the second one
  finishes, Telegram holds a second live authorization of that user (account 4's). The app refuses it and removes
  the local file but sends no `auth.logOut`, so that login stays live at Telegram.
- **Fix:** refuse a code request whose number (digits only, compared in memory as a per-process keyed hash, never
  stored or logged) is the number of another open entry in `c.signins`. Use fixed words, for example "this
  number's sign-in is under way in account N", and send nothing. Change the test to two different numbers and add
  the refusal case.

## LOW 3: the dialogue no longer steers to the account already waiting
- **Where:** `signin.js` `nameStep`. The "Go on with account N's sign-in" path was removed along with the 409.
- **Scenario:** the owner closes the dialogue mid-sign-in and presses "Add an account" again. Each press leaves
  another live, never-signed-in row that is never deleted (numbers are kept for good) and runs an idle task. Each
  press is also the HIGH 1 escape route.
- **Fix:** when accounts wait for their sign-in, have the name step offer them ("Go on with account N") next to
  "Add another". That is a choice, not a refusal.

## LOW 4: the bring-in with an old database that has no user id
- **Where:** `bringin/into.go` 557/583 and `intoplan.go` 117 (`a.TgUserID == uid && a.ID != mine`, where
  `oldUserID` may be 0). Also `bringin/run.go` `account()`, called again after a crash between the chunk and
  `account.done`.
- **Scenario A (only when uid is 0):** a rerun of the into mode after the owner added an account still waiting
  fails with `ErrAccountTaken`. Before this change a waiting account and a brought-in row at 0 could not both
  exist.
- **Scenario B (only when uid is 0):** a rerun of the plain mode's account stage now inserts a second account row
  instead of taking the first. As a side effect the change also fixes an older bug: with uid 0, the upsert used to
  rename a waiting account into the brought-in one.
- **Fix:** treat uid 0 as "no Telegram user" in those comparisons. In `run.go` `account()`, take the account
  from the stage's own setting when it is there.

## NOTE 5: stale words
`docs/ROADMAP.md` line 83 still says "one account may wait for its sign-in at a time". So does
`docs/progress/pages-g3-REPORT.md` (22, 188). With several waiting, the console `signin` without `-account`
now answers `errSeveralToSignIn`; check that its words name the flag.

**Verdict: fix first** (HIGH 1; MED 2 is best done in the same round, since it sits in the same check).

## Second pass (the fix): 69c1ebb0..1a0310dd
Runs in a scratch worktree at 1a0310dd (removed afterwards):
- `go vet` on collector, server and bringin: clean.
- `collector -run 'TestAddAccount|ChooseSignIn|SignInCmd|WrongUser|TestSignInResend'`: ok. `collector -run 'Nas|NAS'`: ok.
- `server -run 'TestAssets|Security|SignIn'`: ok. `catalog -run 'Schema|Step|PendingAcc'`: ok. `bringin` whole: ok.
- One probe test (deleted): account 3 waits at its code, then account 4 is answered FLOOD_WAIT on `auth.sendCode`.
  Account 3's "send a new code" inside 4's wait answers 409 with 4's end and sends 0 `auth.resendCode`. Account 4's
  own begin inside its own wait answers 409 and sends nothing. Once 4 is cancelled and its record cleared, 3's resend
  goes (200, 1 request).

- **HIGH 1: fixed.**
  - The wait is read from the catalogue (`signInWait`, the memo `signin:wait` that `SignIn.wait` writes for every
    step's FLOOD_WAIT), so it holds across restarts. `ListAccounts` includes removed rows.
  - `waitsApply` applies, to an account with no Telegram id, every account's wait. To an account with an id it
    applies its own wait and those of every account with id 0. That covers the rule both ways.
  - The checks sit at every code request:
    - `pagesSource.BeginSignIn` and `SignInStatus` (the record).
    - `Collector.BeginSignIn` under `signMu`, before the dial (record plus memory, for a wait whose write failed).
      The console goes through this too.
    - `Collector.ResendCode`.
    - The console's `blocked` and `waitOrEnd`.
    - `NASSignIn` send/resend.
  - Concurrent begins are serialised by `signMu`, and the wait is written inside `SendCode` before the lock is let
    go. The account's own wait still holds for itself (the probe). An ended wait lets requests go (the test and the
    probe). Lock order is `signMu` then `c.mu`, as before (`ceiling` and `endSignIn` already did it): no new deadlock.
- **MED 2: fixed** for sign-ins in this process.
  - `phoneOpenLocked` refuses another account's open sign-in of the same number, before any dial. It answers
    `PhoneInUseError`, which the page shows as a 409 in fixed words.
  - The mark is HMAC-SHA256 under a 32-byte key from `crypto/rand`, drawn per process. It is kept only in the
    in-memory `signin` struct. Nothing writes, logs or returns the key or the mark.
  - An open sign-in whose wait has ended still holds its number until it is cancelled. The words say "cancel it
    first", and removal is refused while a sign-in is open. So nothing is refused forever.
  - The test now uses two numbers and adds the refusal case.
- **LOW 3: fixed.** The name step offers "Go on with X's sign-in" for each live, not signed-in account, next to "Add
  another account".
- **LOW 4: fixed.**
  - `uid != 0` is guarded in `notTaken`, `accountInto` and `dryRun`.
  - `run.go` `account()` takes the stage's own setting back at uid 0 (`madeAccount`, only while that row still has
    id 0). `nouser_test.go` covers it.
- **NOTE 5: partly.**
  - `errSeveralToSignIn` and the console's words now name `-account`, and `pages-g3-REPORT.md` is updated.
  - `docs/ROADMAP.md` line 83 still says "one account may wait for its sign-in at a time": change it when convenient.

New findings (none blocking):
- **NOTE A, the NAS path (pre-existing, not widened by this change):**
  - `NASSignIn` send_code does not check `phoneOpenLocked`, so a PC sign-in and the NAS's sign-in could ask for the
    same number at once.
  - A wait stated to the NAS's sign-in lives in the NAS's record only. A PC account with id 0 typing that number
    would not see it.
  - Fix later: before send/resend, check the number's mark against `c.signins`. Have the PC write a NAS-reported
    `WaitUntil` (state wait) under that account's `signin:wait`.
- **NOTE B, an in-memory-only wait of another account (cosmetic):** if the record write failed, `Collector.BeginSignIn`
  returns a plain wait status without the "another account's" words, and `SignInStatus` shows nothing (it reads the
  record only). Nothing is sent, so the rule holds.
- **NOTE C (pre-existing):** a new account given the number of an account already signed in ends as "wrong user".
  The local file is removed but no `auth.logOut` is sent, so that second authorization stays live at Telegram until
  the owner ends it in Telegram's sessions list. This branch did not cause it: one waiting account could do it
  before. It touches "one login never live twice" and deserves its own small piece (a logOut of that session before
  the file is removed, under the review rule for code that acts for the owner).

**Second pass verdict: may be merged.**
