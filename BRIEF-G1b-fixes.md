# Brief G1b: the fix round of G1 (pages track, session P2; 2026-11-15)

For G1's coder, in the same copy and branch (`wt-pages-g1`, `wip/pages-g1`, head 023c048 when this was
written). The rules of `BRIEF-G1-one-program.md` hold unchanged (new files, the fewest lines in `account.go`
and `command.go`, named tests only, commits and pushes, the report). **Parts A and B are the main session's own
read and its click through the pages in a browser over `TestPagesHold`; part C is the independent review
(`REVIEW-G1-pages.md`). All three are there: start.**

What the browser pass found working, on invented data, with no console error: the Overview's lanes and
verdict; Stop of one account (stopped by you, with its time, in about 5 s) and Start; "Ask Telegram how large
it is" then "Approve this read" (the chat was read and its files saved); the collect switch; the Queue, the
Accounts, Settings and Import pages rendering; Quit (the program ended cleanly; the header then said it does
not answer). Not seen: the starting page (the hold was ready in 3 s), topics, a drag, a narrow window.

## A. The collector's side (from reading `ownerstop.go`, `pages.go` and the two diffs)
1. **The owner's Stop is not a failure.** After `endOwnerStop` the loop still runs the pause that follows
   every session's end and doubles it; a few Stop and Start clicks grow the pause to its maximum, and a later
   real failure (the gate refusing) then waits up to 10 minutes instead of 5 s. The case goes straight to the
   top of the loop (the redial floor already keeps two dials apart). A named test: five Stop and Start cycles,
   then a refused gate waits `GateRetryMin`, not more.
2. **A Stop with no session says so at once.** `stopByOwner` sets "stopping" only when a session runs; with
   none (waiting on the gate, in the redial floor, dialling) the state keeps its old words for up to 5 s
   ("starting in N s" after the owner pressed Stop). Set "stopped by you" there.
3. **No package-level state.** `ownerStopFault` is shared by every collector of the test binary (a test that
   sets `read` stops every other test's accounts if tests ever run side by side: the old app's CI failures
   were exactly this pattern, TRIED-BEFORE 12 and 21); `pagesClosing` is a global map. Put the fault switches
   on the account's own `ownerStop` value (set by a test after the account exists), and the "stop begun" mark
   on the `pagesRun`; the catalogue accessor becomes the `pagesRun`'s own unexported one (the brief asked for
   an exported accessor on the collector: that was the brief's mistake, as your report says).
4. **Signed in or not must come from the record.** `pagesSource.Accounts` derives it from the state word, so
   an account that never signed in and is stopped by the owner is shown as signed in. Take it in the loop's
   own check (it has the catalogue) and keep it beside the Stop's mark; the poll still reads no table.
5. **`server.New` failing at attach** leaves "Starting... N s" counting for ever. The address then says in
   fixed words that the pages could not be made and that the collector runs on, and the console line says it.

## B. The pages (from the browser)
1. **Words that are false while the program runs.** Overview: "Nothing on this page asks Telegram for
   anything. Start and Stop act on the accounts only." (Start connects an account: say that Start connects it
   through the VPN check and Stop ends its connection, and that nothing else on the page sends anything.)
   Chats: the footer still tells the owner to run `tgarchive-collector run ... -approve-read` and that "this
   page sends nothing to Telegram, so it cannot add a chat", above the sentence about the estimate button:
   in the program only the second stays. Accounts: "The app runs 5 small and 2 big files at once per account
   and server (see Settings)" while Settings says those two numbers have no effect: say what is in force, from
   where the engine takes it, or nothing. Go through every page's fixed sentences once in both modes.
2. **The estimate is said three times in one row** (a bullet "A read was estimated at about 1 request (15 Nov
   2026)", then "Telegram counts 19 messages; reading it whole takes about 1 request (asked 15 Nov 2026)", then
   "Telegram answered: the cost is shown; approve it to read the chat."). Once: the count of messages, the
   requests, when it was asked (with the time of day when it is today), then the button.
3. **The collect switch cannot be told from the three kinds**: four identical toggles in a row with no word
   on the screen (only a label for screen readers). Its own column with its heading, apart from "Photos,
   Videos, Files", each of which gets a visible short word too.
4. **The Chats page does not ask again by itself**: after "Approve this read" the row said "approved, not
   started" until Reload, while the chat was read and saved within seconds. It asks again when the change key
   moved, at most every 5 s, as the Queue does, and not while a control has the keyboard, a row is being
   dragged or a rank box is open.
5. **Controls that do nothing are not offered** (TRIED-BEFORE 10 and 19; your report's point 4): small files
   at once, big files at once, timeouts before a file is set aside, minutes set aside, and the hand-over
   switch are read by nothing. In both modes they stop being inputs: where the engine has a value in force,
   one line says it as a fact with where it comes from; the hand-over says it is not built and stays off. The
   stored values are left as they are. **The library folder in the program** shows the folder the store
   really writes to (the collector's, through the adapter), as a fact with the sentence that it is set when
   the program starts; never "Problem: give the folder where files go" beside a field the owner cannot use.
6. **Import while collecting**: the button is off with the sentence beside it while any account is not
   stopped, instead of a refusal after the click (the refusal stays behind it).
7. **After Quit** the header says "does not answer". When the page itself sent the Quit and got its answer, it
   says the program was closed from this page at that time and to open it again with its starter; "does not
   answer" stays for every other silence.
8. **The viewer's link only when the viewer answers.** The header shows "Open viewer" whatever runs at that
   address. The server looks at the address (a TCP connect, 127.0.0.1 only, 200 ms at most, kept for 10 s; not
   on the poll's path for longer than that) and the page shows the link, or "The viewer is not running" with
   no link. An address that is not 127.0.0.1 is shown as stored and not looked at.
9. A date of 0 is a dash, not "31 Dec 1969" (Accounts, "Added").
10. **One second after Stop the row still said "Running".** The answer of `POST /api/run` carries the new
    snapshot and the page shows it at once ("stopping: your Stop"), without waiting for the next poll.

## C. The independent review (`REVIEW-G1-pages.md`: 1 must fix, 6 should fix, 9 minor; read it in full first)
Every finding below is accepted by the main session; the review's "smallest change" is the starting point, and
where it would mean lines in `account.go`'s `runSession` or in `collector.go`, find the way through
`ownerstop.go` or `pages.go` first.
- **M1 (must): the header's Start starts an account marked removed.** No path may start, dial for or send a
  request for an account whose row is marked removed: in the collector (the loop's top check counts a removed
  account as stopped, state in fixed words; "every account" leaves it out), not only in the page's handler.
  Named test on the rig, the review's sequence: Stop, mark removed, Start all: no dial, no request.
- **S1: the pages' stop has no bound after its 3 s.** After the bound the connections are closed
  (`hs.Close`) before the wait, the wait gets a second bound (10 s) with a fixed log line when it passes, and
  the stop goes on. The handlers that run on a context that cannot be cancelled (the three topic routes and
  the collect switch) get, in the program, a context that ends with the pages' work: a settle that stops
  leaves its action on record for the supply's next settle. Named tests: a client that stops reading a large
  answer; a topic settle under way at the stop (it ends within the bounds, its action is finished afterwards).
- **S2: "stopping" is decided in the collector, not from a word.** An account whose Stop mark is on and whose
  session has not ended is stopping, whichever path the Stop took (the watcher too), from before the row is
  written. Import and removal are refused through that whole time. (With A.2 and B.10.)
- **S3: the Overview's "as of" is true.** Either the hourly table's own cheap key joins the overview's key, or
  the kept answer's own time is what the page says; a file downloading for minutes without a state change
  must not leave the hour's bars stale under "as of now".
- **S4: an estimate belongs to its account.** The row gives each account's own estimate; "fresh", the approve
  number and the "Ask" button are decided for the account the box acts through; a removed account's estimate
  is a fact shown, never the one approved.
- **S5** is A.5 (the failed-pages handler also answers Quit).
- **S6: an owner's Stop must not swallow a sign-out.** The session's end channel holds up to four endings and
  `runSession` reads the first (checked by the main session: `end: make(chan ending, 4)`), so a sign-out that
  arrives after the Stop is left unread and the account dials again with the refused session after Start.
  After a session ended for the owner's Stop, what is left in its end channel is looked at: a sign-out is
  recorded as the loop's own case does. Settle it with a rig test whose fake refuses the login at the Stop.
- **Minor 1 and 2: one lock for every writer of the Stop** (TRIED-BEFORE 25, rule 11): Stop's mark and row,
  Start's delete and clear, and the loop's read-then-set cannot interleave; a Start can never be lost at the
  first turn after the program's start; two tabs cannot leave the mark and the row disagreeing.
- **Minor 3:** the header's pill follows the verdict (collecting, waiting, stopped), not "any account signed
  in and not stopped": it must not say "Running" when every account is frozen or refused by the VPN check.
- **Minor 5:** "waits for one" is false while the program holds the lock the `signin` command needs. Until the
  sign-in page exists (piece G3) the words, in the help and on the pages, are: Quit, sign in with the command,
  open the program again.
- **Minor 6:** Start and Stop of every account answer per account (which started, which stays stopped and
  why, which Stop is not on record); one account's failure is not the answer for all.
- **Minor 7:** the data race on `pagesRun.c`. **Minor 8:** `http.Server.ErrorLog` writes one fixed line (a
  handler's panic must not put its value or stack in the collector's log; add it to the log guard test).
- **Minor 9:** `TestStartDuringStopIsKept` asserts that the Start landed during the stop. And measure once,
  for the report, what one working-out of the overview (`Totals` and the hours) costs at 300,000 invented
  files, as statements and wall time on a quiet moment ("looks like"): **if it is over a quarter second, the
  overview's floor becomes 30 s and the page says so.** The Queue's the same way.
- Minor 4 is noted and not changed (the floor counts from a session's end, as the brief said).
- **One more, from the review's last section (older than this branch, closed here because the pages now belong
  to the collector):** `tgarchive app` without `-demo` takes only the pages' lock and runs `RecoverActive`; beside
  a collector started with plain `run` that gives back files in transfer. `app` refuses, in fixed words, while
  a collector holds the catalogue (a look at the collector's lock file from `internal/server`, which must still
  not import the collector: the file's name in one place with a test in the collector that the two agree).

## Tests and the report
A named test for each item of A, B.4 to B.8 and B.10 (the browser-only ones, B.1 to B.3 and B.9, by a test on
the answer's words or fields where one is possible); each item of part C as the review asks. Add a section
"Fix round" to `archiver/docs/progress/pages-g1-REPORT.md`: each item, what was done, its test; anything you
did not do and why. Hand back commit-ready as before.
