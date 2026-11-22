# Brief: independent review of G3 (sign in from the Accounts page; an account added while the program runs) — read-only

You are an independent reviewer. You did not write this code and you owe its author nothing. Find what is
wrong with it before the owner types a real phone number, code and two-step password into it. **You change
nothing in the tree.**

## What to review
The branch `wip/pages-g3` at c49b27ac, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-g3` (Go
module in `archiver/`), against its base ee437a46: `git diff ee437a46..c49b27ac` (22 files). What it was asked
to do: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-G3-signin-page.md` (all of it, the last section included).
Its author's own account: `archiver/docs/progress/pages-g3-REPORT.md` (read it last, and do not take its word
for anything). The pieces: `internal/collector/account_add.go`, `signin_pages.go`, the lent lines in
`collector.go` (14), `account.go` (a function taken out), `pages.go` (the stop's order); the adapter
`internal/collector/livepages/signin.go`; `internal/server/signin.go`, the changes in `server.go`,
`accounts.go`, `liveroute.go`; the scripts `web/assets/js/signin.js`, `pages/accounts.js`, `main.js`, `api.js`.
The steps it stands on existed before and ran for real twice: `internal/collector/signin.go`
(`BeginSignIn`, `SubmitCode`, `SubmitPassword`, `holdForSignIn`, `ForceStop`) and `signin_cmd.go` (the
console's rules in `SigninUsage`).

Background: the collector is one process holding every Telegram session and is the one writer of the
catalogue; the pages' handlers run inside it. It is started under a watchdog that gives it no keyboard input
and restarts it unless it ends with exit code 0. The rules that bind this piece: every code asked for is
recorded first and counted; a wait Telegram states is kept on record and slept in full; the app never asks for
a code again by itself; a stop is held briefly while a code is awaited so the code is not wasted; **nothing
typed (phone, code, password) is kept, logged, printed or put in an error, a URL or an answer after the one
that carried it**; the VPN check's verdict comes before anything is typed and a refusal means nothing is
dialled; a sign-in never clears the owner's Stop or ends a pause of downloads; Telegram allows about 5 login
attempts per phone a day and tells the account's other devices of each: a wasted or doubled code request is
a real cost to the owner; logs hold constant words and numbers only; every change route needs same origin and
the run's token.

## Where to look hardest (not a limit)
1. **An account added while the program runs** (`AddAccount`, the three fields in `collector.go`). Until this
   branch `c.accts` was filled once before any task started. Now it is written while tasks run: **read every
   reader of `c.accts` and of an `*account`'s fields** (`account.go` 214, 230, 1131; `collector.go` 472;
   `gate.go`, `heartbeat.go`, `staging.go`, `tghourly.go`, `ownerstop.go` 365, `pages.go` 469, `signin.go` 265
   to 347): is each under `c.mu`, and does any keep a slice or count of accounts made at the start that the new
   account is then missing from (the hourly rows, the refresher's mux, the gate's task, the counts task, the
   lane tables, the heartbeat, the store's per-account figures, the automatic mirror)? What does an account
   with Telegram id 0 do in each of them before its sign-in? The stop: can a task be added after the tasks'
   wait began, or its wait group be added to while it is waited on (also with no account at all at the start,
   the wait group at zero)? `supv.Go` under `c.mu`: can the new loop or the supervisor take `c.mu` and
   deadlock? The row is written outside the lock with a plain INSERT by the collector into the catalogue's
   `account` table: what does it skip that `UpsertAccount` does, what does the unique index on the Telegram id
   do to a second unsigned account, to an account marked removed, to the sign-in's own write of the id at the
   end (two accounts signing in to the same Telegram account)?
2. **The stop held for a sign-in, with the pages up** (`pages.go` `runWithPages`'s stopper, `stopAsked`,
   `holdForSignIn` now called twice: before the pages stop and again in `Run`). Every interleaving: Quit while
   a code is awaited, then the code typed; Quit twice; Ctrl-C then Quit; a code request already past the
   `stopAsked` check when the stop is asked (the author's own doubt: the second hold then waits with the pages
   closed for up to `SignInHold`, 15 minutes: confirm or refute, and say the smallest close); the program
   ending by itself (`runDone`) while a sign-in is open; `ForceStop` before any hold. What exit code does each
   path end with (the watchdog restarts anything but 0: a restart would dial again by itself)? What do the
   pages answer during the hold (which routes still work; can the owner start a download, add an account, ask
   another code)? Is anything sent to Telegram during the hold other than the awaited step?
3. **Requests to Telegram, counted.** For every route and every sequence (the happy path, a wrong code, a wrong
   password, a stated wait, a refusal, a second click, a double submit, two browser tabs, a reload in the
   middle, the dialogue closed and reopened, an expired code): exactly which requests leave, and can any leave
   twice or by itself? **The new rule "a sign-in left awaiting its code longer than `SignInHold` is closed when
   the owner asks for a new code"**: can it close a sign-in whose code is still good, or ask a second code
   inside a wait? `begin`'s refusals "before any dial": is any of them decided after a dial? A wait on record:
   is the button's "off until" the recorded end, and is nothing sent before it by any path (the status route,
   the gate route, a reload)?
4. **Nothing typed is kept.** Follow the phone, the code and the password from the script to the Telegram
   package and back: every variable, struct field, closure, log line, error value (wrapped errors' text), JSON
   answer, the kept answers of the pages, the change key, the catalogue, the session file's name and content,
   the crash log. The request's body after a decode error. The browser side: `autocomplete`, the DOM after the
   dialogue closes, anything written to storage or the URL, the password field's value after a wrong password.
   Probe it: hard invented values through every step, the failing ones included, then search everything the
   process can show.
5. **A sign-in that ends on another Telegram account than the row names** (`ErrWrongUser`: the author's doubt):
   what is left on disk under this account's name (the session file), what does the next code request or the
   next start do with it, can the app then run as the other account under this row? Existing behaviour or not,
   say what the page makes worse or better.
6. **The owner's Stop, the pause, removal:** a sign-in from the page for an account stopped by the owner, paused,
   marked removed, being removed, removed while its sign-in is open, added and never signed in then removed;
   "signed in; stopped by you: press Start".
7. **The guard and the seam:** the six routes behind the guard and absent without the program; `internal/server`
   importing neither the collector nor Telegram; what another site's page can do; errors mapped by type, never
   by text (the two refusals shown as "an answer this app does not know": which real answers of Telegram fall
   there, and is "try again" then offered when it must not be).
8. **The scripts:** words that are false in a state the page can be in; a button enabled when its click would
   send something the owner did not ask for; the wait's countdown against the PC's clock being wrong or the
   page left open overnight; text put into the page as markup; a refresh that takes the dialogue or its typed
   values away, or keeps them when it must not.
9. **The tests:** one that judges on real time; `holdForSignIn` polls every 100 ms of real time: a test that
   depends on it; a mutation the author says was caught that its test would not catch; the request counts
   (are they counted on the fake for the whole test or only around the step).

## How to work
- Read the code yourself; read the old code it relies on. Prove a finding where you can with a probe test in
  your own scratch folder `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g3-scratch`, loaded with
  `go test -overlay` (the tree stays untouched), or by reasoning from quoted lines when a probe would cost too
  much. Mark each finding **CONFIRMED** or **PLAUSIBLE** (say what would settle it).
- Load: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, one go command at a
  time, `GOGC=25 GOMAXPROCS=2 go test -p 1 -run '<names>' ./internal/<package>`: named tests only; no whole run
  of `internal/collector`, `internal/catalog` or `internal/server`, no race detector, no Docker (the race
  detector on the whole collector is run once by the main session after your findings are fixed: say which
  interleavings you want it to meet). Before each go command:
  `powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`;
  wait when free memory is under 2.5 GB or the CPU is over 85%.
- Never touch `E:\T\tg-dl`, the folders `a3`, `b`, `app`, any real catalogue, media, session or account; start
  no installed program; nothing runs against Telegram. Invented numbers, codes and passwords only. Print
  counts and timings only.
- Any file you write that holds a Windows path is written with the file-writing tool, never from inside a shell
  or script string.

## What to hand back
Write `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-G3-signin.md`: findings in order of harm, each with its
mark, the file and lines, what goes wrong in one concrete sequence of events, and the smallest change you would
ask for; first the ones that must be fixed before this is merged, then the ones that should be, then minor
ones; then a table of every route and sequence with the requests to Telegram it sends (point 3); what you
checked and found sound (briefly, by name); what you did not look at. Your final message: the count by class
and the must-fix findings in one line each.
