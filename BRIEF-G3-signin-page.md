# Brief G3: sign in from the Accounts page (pages track, session P2; 2026-11-15)

Roadmap row D1; FEATURES section 6 ("Sign-in wizard: phone, code, cloud password, a name for the account");
the collector's own note in `signin_cmd.go`: "Signing in beside a running collector is for the page, later."
**Not started: cut from the main head once G1 (`wip/pages-g1`) is merged or, if the main session says so, from
G1's head.** For one Opus coder; the copy, branch and base are named when it is started. Rules of work as in
`BRIEF-G1-one-program.md` ("Rules (hard)").

## What is known already (read by the main session)
- The sign-in steps exist and have run for real: the test account twice on 11-13 (a code only; then a wrong
  and a right two-step password). `Collector.BeginSignIn`, `SubmitCode`, `SubmitPassword` (`signin.go`) were
  written for this page; the console command's rules are in `SigninUsage` (`signin_cmd.go`): keep every one.
- The owner's rules (FEATURES 12 rounds 10 and 11): no limit of sign-ins per day (that was a session's own
  caution and is gone); **every code asked for is recorded first and counted; a wait Telegram states is kept on
  record and slept in full; the app never asks for a code again by itself; a stop is held briefly while a code
  is awaited so the code is not wasted**; nothing typed is kept, logged or printed.
- Telegram's side (TELEGRAM-FACTS 8): about 5 login attempts per phone per day, then a flood wait; the other
  devices of the account are told of a new login; sign-in waits of a day and more are stated and a code asked
  inside one may lengthen it (`SignInStats.WaitsOver48h`).
- The VPN check comes first and its verdict is shown before anything is typed (the console's rule;
  TRIED-BEFORE 14: the collector refuses to dial when it cannot tell it is behind the VPN).
- From the old app's review of anything that acts for the owner (TRIED-BEFORE 24, 25): one item per call, each
  result recorded; a "busy" flag released with `defer`; errors sorted into permanent and passing by type, never
  by matching text; fail closed.
- No old-app number exists for a sign-in page: the old app's sign-in was the base app's and was used once.

## What to build
1. **An account can be added while the program runs.** A new call on the collector (new file; the lent lines
   in `collector.go` and `account.go` kept to what this needs): the account's row is made with its label
   (`UpsertAccount`), its task is made as `loadAccounts` makes one (take that out into one function both use)
   and started under the supervisor beside the others, **refused once the stop has begun** (decided under the
   collector's lock, so no task is added while the stop waits for the tasks: a named test with the stop held).
   With no account at all `run -pages` already serves the pages (G1): the Accounts page then leads with "Add
   an account".
2. **The dialogue on the Accounts page** (it replaces the disabled preview), for a new account or for one that
   is not signed in or was signed out by Telegram:
   - First the VPN check's verdict, asked when the dialogue opens (a small new accessor; no request to
     Telegram): allowed, or refused with its fixed reason: then nothing can be typed.
   - A name for the account (a new account only).
   - The phone number, typed twice and compared as the console does (digits only count); nothing is sent
     until they match. Then "Ask Telegram for a code": the button says it is a request to Telegram and that
     the account's other devices are told. `BeginSignIn`.
   - What comes back, each in fixed words: a code was sent (how, its length); Telegram asks to wait until a
     time (shown in local time; the button stays off until then; asking earlier sends nothing, which the
     package already ensures: a named test counts the fake's requests); refused, with Telegram's reason by
     its type; this account is signed in already; another sign-in of it is under way.
   - The code; a wrong one is asked again on the same attempt with the count of wrong ones (`WrongCodes`).
     Then, only when Telegram asks, the two-step password, in a password field; a wrong one is asked again
     with its count. There is no "send the code again" (as the console; say so on the page).
   - Signed in: the row says so and the account starts by itself, **unless the owner stopped it** (G1's rule:
     a sign-in never undoes the owner's Stop: the page then says "signed in; stopped by you: press Start").
     A sign-in that ends on another Telegram account than the row names (`ErrWrongUser`) says so and records
     nothing.
   - Closing the dialogue while a code is awaited says first that the code is then wasted; the sign-in stays
     open on the collector for its hold (`SignInHold`), and opening the dialogue for that account again goes
     on at the code (a small new accessor for a sign-in's status; the phone is asked again, since nothing kept
     it). The program's Quit while a code is awaited answers with the console's words and needs a second,
     explicit Quit (`ForceStop`).
   - The row shows as facts: codes asked for this account so far and when the last was (the record the
     package keeps), and a stated wait's end while one runs.
3. **Nothing typed is kept or logged, anywhere.** The server holds no phone number, code or password after
   the request that carried it returns (the page keeps the number in the open dialogue only and sends it again
   with the code, as `SubmitCode` needs); the three fields have `autocomplete` off and the password is never
   put in a URL, an error or a log; the routes are POST, inside the guard, with `no-store`. A guard test types
   hard invented values through every step, the failing ones included, and finds none of them in the log, in
   any answer after the one that carried it, in the catalogue or in a session file's name.
4. The seam: a third small interface beside G1's two (sign-in steps, the gate's verdict, add an account),
   nil in `tgarchive app`, where the dialogue keeps a sentence saying the program must be opened with its
   starter.

## Tests (named; the fake Telegram; invented numbers, codes and passwords; fake clocks)
`TestSignInPageHappyPath` (code only), `TestSignInPagePassword` (a wrong then a right one),
`TestSignInPageWrongCodeSameAttempt`, `TestSignInPhoneMismatchSendsNothing`, `TestSignInWaitShownAndNothingSentInside`,
`TestSignInRefusedWords` (each type), `TestSignInGateRefusedNothingTyped`, `TestSignInWrongUserRecordsNothing`,
`TestSignInResumeAfterDialogueClosed`, `TestQuitHeldForSignIn`, `TestSignInDoesNotUndoOwnerStop`,
`TestAddAccountWhileRunning`, `TestAddAccountRefusedDuringStop`, `TestSignInNothingKept` (the guard above),
`TestSignInRoutesOnlyWithProgram`. Every test counts the fake's requests: exactly the sign-in's own
(`auth.sendCode`, `auth.signIn`, `account.getPassword`, `auth.checkPassword`), once per entry typed.
Mutations: a code asked again by itself after a wait; the phone kept on the server between requests; a
sign-in clearing the owner's stop; an account's task added after the stop began; the gate's refusal skipped.
The hold of G1 (`TestPagesHold`) gains an account that is not signed in, so the dialogue can be clicked
through in a browser against the fake.

## Not verified by this piece, and to be said in its report
Nothing here runs against Telegram: the first real sign-in from the page is the owner's to do, on the test
account, and is a real run to be asked for on the board when the branch is merged and installed.

## Since this was written (2026-11-15 21:20, session P3): what G1 became, and where you work
- **Copy and branch:** `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-g3`, branch `wip/pages-g3`, cut from
  G1's head ee437a46 (`wip/pages-g1`; it holds the main head fa8c011 with the automatic mirror and K1). G1 is
  listed and not merged yet; the main branch is at 2625aa0 and the integrator has a batch waiting behind G1
  (K4, K3, C8, M5) that changes `command.go` and `account.go` elsewhere: when it lands you will be told to
  merge the new head in (those conflicts have always been "both sides kept"). Commit work in progress as you
  go and push with `git push private wip/pages-g3`. Progress and report:
  `archiver/docs/progress/pages-g3-PROGRESS.md` and `pages-g3-REPORT.md`, written from your first action.
- **The hard rules of `BRIEF-G1-one-program.md` apply, with its first rule replaced by this:** new code goes in
  new files; in the collector's existing files change only what "an account added while the program runs"
  and the sign-in's seam need (`collector.go`: the one function that makes an account's task, taken out of
  `loadAccounts`, and the new call's lines; `account.go`, `command.go`, `signin.go`: lent lines, each said in
  the report). Not `reader.go`, the engine, the supply, the store, the mirror, the watchdog, the viewer, the
  catalogue's schema (no schema step: stop and say so if you find one is needed). The only requests to
  Telegram are the sign-in's own four, each on the owner's click. Commits:
  `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with the line
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; never push or merge any branch but your own.
- **Read G1's report first** (`archiver/docs/progress/pages-g1-REPORT.md`, every section: it is long and it is
  the map) and use what G1 built instead of building beside it: the seams `Live` and `LiveEach`
  (`internal/server/live.go`) and their adapter `internal/collector/livepages` (your third seam goes the same
  way: `internal/server` imports neither the collector nor Telegram, and a test guards it); routes registered
  through `handle(...)` (the route's pattern is all the fixed-words log names); a handler whose work may be long
  takes `s.lasting(r)`; controls that need the program carry `data-needs-program`; a region with controls
  repaints by shape (`shape.js`), never rebuilt under the pointer; **after the owner's own click the clicked
  region must show the result even under the pointer** (a fault seen today on the Queue page: the click looked
  as if it did nothing); the guard's route lists in `security_test.go`.
- **The owner's Stop and the pause of downloads are on record** (`ownerstop.go`: `StopAccount`, `StartAccount`;
  `pausedl.go`): a sign-in never clears a Stop and never ends a pause; G1 has tests for both
  (`TestSignInDoesNot...`, `TestClearFrozenDoesNot...`): they stay green, and an account added while the
  program runs obeys the same record (an account whose row carries a Stop does not start; a new account has
  none). An account removed while its sign-in is open: find what G1's "removing an account is refused while
  collecting" already covers and say what is left.
- **K1 is in:** a new account's chats start switched off until the owner chooses them; after a sign-in the
  page says so in one sentence and links to Chats (signing in downloads nothing by itself).
- **The program runs under a watchdog now** (Core, board message 52; `internal/watchdog`): the watchdog gives
  the collector no keyboard input, so in the one program a code can only be typed on the page: nothing in your
  flow may fall back to the console. A Quit, also the second, explicit one while a code is awaited, must end
  the collector with exit code 0 (the watchdog restarts anything else): check `ForceStop`'s path and say what
  exit code it gives; do not edit `internal/watchdog` (Core's): say what you would need.
- **Standalone program (board message 40):** nothing you add depends on an absolute path of this PC, the folder
  the program is started from, PATH or the `a3` scripts.
- **Tests never judge on real time.** Two of this track's tests failed under the race detector today because
  they did. A test that needs files in transfer holds their parts with `rig.holdParts`
  (`internal/collector/parthold_test.go`), a test that needs "the stop has begun" holds the stop by a hook or a
  channel, a wait is a fake clock's. Tests at size in `internal/server` skip under the detector by the constant
  `raceOn` (`race_on_test.go`).
- **The scripts' guards:** after any change under `web/assets/js`, `TestScriptsNoDuplicateOrMissingNames` and a
  module parse of each script with node (`node --input-type=module --check < file`). A page that fails to
  parse shows nothing at all and no Go test sees it.
- **Open it yourself before handing back:** `TestPagesHold` (`TGARCHIVE_PAGES_HOLD=127.0.0.1:<a free port>`, not
  8793) with its new not-signed-in account; click the dialogue through in the built-in browser if you have
  one (the fake's invented code and password), a wrong code and a stated wait included; say in the report
  exactly what you saw and what you did not.
- **What the main session does after your hand-back (not you):** its own read of `collector.go`'s `Run` and
  the lent lines, one independent review, then once: the whole Windows runs and the race detector on
  `internal/collector` (an account added while the program runs is concurrent code). You run named tests only:
  no whole run of `internal/collector` or `internal/catalog`, no race detector, no Docker.
- **Load:** the PC is shared with other sessions' coders and race runs. Before each go command:
  `powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`;
  wait when free memory is under 2.5 GB or the CPU is over 85%; one go command at a time,
  `GOGC=25 GOMAXPROCS=2 go test -p 1 -run '<names>' ./internal/<package>`.
- **Any file that holds a Windows path is written with the file-writing tool**, never from inside a shell or
  script string (a backslash before a letter became a control byte five times today).
