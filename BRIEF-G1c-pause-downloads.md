# Brief G1c: pause downloads, and "pause for X hours" (pages track, session P2; 2026-11-15)

For one Opus coder, **after the fix round of G1 is handed back**, in the same copy and branch (`wt-pages-g1`,
`wip/pages-g1`), as its own commits on top. The rules of `BRIEF-G1-one-program.md` ("Rules (hard)") hold
unchanged. It gets its own short independent review before G1's full runs, so G1 reaches the owner with it.

## The owner's words (11-15 17:21, on G1's Start and Stop; board item 14 and message 30)
"Probably fine. Makes it instantly useful, as long as we have a pause button, or a pause for X hours button
(since the user may wish to have faster downloads/viewing on their personal device, and the app could exhaust
the telegram fast quote)."
So: **a pause of downloads only.** The account stays connected, its chats are read, live updates are
followed, mirrors go on (none of that moves file bytes); no file part, no reference refresh and no hash
request is asked while it is paused. As a button, and as "for 1, 2, 4, 8 hours" that ends by itself.

## What is known already (read by the main session)
- Telegram's speed limit is stated for the account ("the current account does not have a Premium
  subscription"; it applies after "tens of gigabytes": TELEGRAM-FACTS 2), so the owner's phone shares it.
  Nobody has measured the phone beside a download (FEATURES 12, round 15). The old app's numbers for what a
  download costs the allowance: 60 to 100 GB in an hour without the limit, then limited spells of 8 to 24
  hours (TRIED-BEFORE 14). The old app had a queue pause on its dashboard and the lesson from it: **"stop
  taking new work" is its own state and never touches a file's held or aside state** (TRIED-BEFORE 19:
  clearing a queue-wide pause released held copies and set-aside files).
- **A person's pause is never undone by the app** (TRIED-BEFORE 24 rule 1); a stored mark that cannot be read
  fails closed (rule 13); one lock for every writer of a stored mark (rule 11); a switch nobody flips back
  helps nothing (TRIED-BEFORE 25): hence the pause that ends by itself, with its end shown.
- A stop at any moment is safe on the byte path: a transfer given back spends no attempt and a file of 8 MiB
  or more carries on from its checkpoint (run for real on 11-13 with kills; TRIED-BEFORE 7, 27).
- The collector can already stop and start an account's engine inside a running session: `engineTask`
  restarts it when a file of a new server appears (`startEngine` stops the running one first: its files
  given back, its counters written, its window levels saved), and `run -no-downloads` runs a session with no
  engine at all (`Config.DownloadsOff`: the refresher is then not handed to the supply). The pause is that
  existing stop, asked for by the owner. No new way to stop a transfer is built.

## What to build
1. **The pause, per account, on record** (a new file beside `ownerstop.go`, the same shape and the same one
   lock per account): one settings row per account with when it began and when it ends (0: until resumed).
   `PauseDownloads(ctx, account, until)` and `ResumeDownloads(ctx, account)`; account 0 is every loaded
   account that is not marked removed, one at a time, each result kept. A row that cannot be read counts as
   paused (state in fixed words, read again after a pause); a row that cannot be written: paused for this run,
   said so. Kept through a restart: a pause whose end has passed while the program was closed is over at the
   start; one with time left goes on for the rest.
2. **In the session** (`account.go` `engineTask`; the fewest lines): each turn asks the pause first. Paused:
   the running engine is stopped through `stopEngine` as `startEngine` does it, the lanes are forgotten so
   that the next scan after the pause starts it again, and nothing is scanned or started meanwhile. **While
   paused the refresher is not reachable from the supply** (as with `DownloadsOff`), so nothing asks a
   reference; the exact check lives in the engine and stops with it. When the end time passes (the
   collector's clock, never real time in a test) or the owner resumes, the next turn scans and starts the
   engine as at a session's start. A session that starts during a pause starts no engine. The reader, the
   monitor, the mirror's task and the store's copier are not touched.
3. **Nothing else ends a pause**: not the owner's Start after a Stop (the account connects, reads and
   follows updates; its downloads stay paused until the time or "Resume now"), not a sign-in, not
   `ClearFrozen`, not a restart. A Stop during a pause and a pause during a Stop are both kept; each has its
   own row.
4. **No file's state is touched** beyond what the engine's own stop does (transfers given back, no attempt
   spent): held, kept-held, set-aside and wanted rows are counted before and after in a test.
5. **On the pages** (the adapter and the server's seam get the two calls and the pause in the snapshot, which
   still reads no table):
   - In the header beside Start and Stop: "Pause downloads" with a small menu: 1 hour, 2 hours, 4 hours, 8
     hours, until I resume. While paused it reads "Downloads paused until HH:MM (1 h 12 min left)" or "...
     until you resume", with "Resume now". Per account the same on the Overview and the Accounts page.
   - The verdict line and each account's state say it in fixed words with numbers: "Connected; downloads
     paused until HH:MM; reading and following updates go on." A lane table is not shown for a paused
     account (it has no lanes); the sentence stands in its place.
   - The Queue page says above its lists that nothing is taken while downloads are paused, and until when.
   - `POST /api/pause` (account, hours or "until resumed") and `POST /api/resume`, inside the guard; in
     `tgarchive app` they are 404 and the buttons are not shown.
6. `run -no-downloads` keeps its meaning (no downloads for the whole run, whatever the page says); the page
   then says downloads are off for this run and offers no pause.

## Tests (named; the collector's rig; fake clocks; nothing judged on real seconds)
`TestPauseStopsPartsNotReading` (after the pause the fake counts no part, no refresh and no hash request for
the account, while a message posted live is still stored and a read under way goes on),
`TestPauseEndsByItself` (the clock passes the end: parts are asked again, the files in transfer before carry
on from their checkpoints), `TestResumeNow`, `TestPauseSurvivesRestart` (with time left, and with its end
passed while closed), `TestPauseUnreadableFailsClosed`, `TestPauseRecordFailsStillPauses`,
`TestStartDoesNotEndPause`, `TestStopDuringPauseKeepsBoth`, `TestSessionStartsPausedStartsNoEngine`,
`TestPauseTouchesNoFileState`, `TestPauseWithNewServerAppearing` (a file of a new server arrives during the
pause: no engine starts; after it, the lane is there), `TestPauseAndResumeInARow` (ten in a row: one engine
at the end, no goroutine left: the supervisor's task count), `TestNoDownloadsFlagWins`, and on the server:
`TestPauseRoutesOnlyWithProgram`, `TestPauseWordsAndTimeLeft`, `TestLiveStillReadsNoTable`.
Mutations: a pause that only hides the lanes (parts still asked); the refresher left reachable; Start ending
the pause; an unreadable row read as "not paused"; the end time judged by the wall clock.
`TestPagesHold` gains nothing: the buttons are there to click.

## The report
A section "Pause downloads" in `archiver/docs/progress/pages-g1-REPORT.md`: what was built against each
number; every line changed in `account.go` and why it could not live elsewhere; the tests and mutations;
what the rig measured from the click to the last part asked; what was not verified (nothing has run against
Telegram; whether a pause really leaves the phone its speed is the owner's to see).
