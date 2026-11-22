# Brief: independent review of G13 (the Staging page on the store's reads of the moment) — read-only, narrow

You are an independent reviewer. You did not write this code and you owe its author nothing. **You change
nothing in the tree.**

## What to review
The branch `wip/pages-staging2` at 02b1ce2d, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-staging2`
(Go module in `archiver/`), against its base f7d6ca63: `git diff f7d6ca63 02b1ce2d -- archiver/internal` (14
files: `internal/server/staging.go`, `stagingread.go`, `stagingverdict.go`, `stagingview.go`, two scripts;
`internal/collector/livepages/staging.go`; two lines in `internal/collector/pagesstaging.go`; tests). What it
was asked to do: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-G13-staging-live-reads.md`. Its author's own
account: `archiver/docs/progress/pages-staging2-REPORT.md` (read it last; do not take its word).

Background. The app's Staging page shows the owner what the store is doing: files staged on a local disk,
copied to the library on a NAS, checked. Two things on it need the owner: copies that are stuck, and a HOLD
the copier puts on "making files wanted again" when it has done so too often in an hour (the page then
shows it with a button "Let it go on"). Until now every reading asked the store's gauges (a second read of
the queue summary, slow at size) for the copiers' numbers and for that hold. The store now gives the
copiers' numbers from memory (`Copier.Load()`), bytes written (`Written`) and the staging disk's state
(`Writer.StagingNow()`). This piece uses them, and so that a steady reading costs less it **asks the gauges
only when a rule says it must (`gaugesWanted` in `stagingread.go`) and otherwise carries the hold over from
the reading before.** That rule was not in the brief; it is the part to review hardest. The project's
lessons for such a page: a state that needs the owner must never be shown as "nothing needed"; every
number says what it counts and when it was read; a speed is never shown as 0 while work is going on.

**Already decided by the main session for the fix round (comment only if you see a reason against):** the
gauges are also asked whenever the last answer is older than 60 s, whatever the rule says (a backstop, so a
hold the rule missed shows within a minute).

## Where to look, and only there
1. **The asking rule and the carried hold.** `gaugesWanted`, `holdMarks`, `holdState`, and where a reading
   takes `prev.Hold`: find every way the store can put the hold on (read `internal/store`: where
   `WantAgainHeld` is set and counted, what `Hour`/`Day` counts are and whether a 24-hour sum can stay equal
   while a latch happens: one event leaving the window as another enters; the two counts added together) and
   every way it comes off (the owner's release through the page, through a command, a restart of the
   store), and for each say whether the page shows it within one reading, within the 60 s backstop, or
   never. A hold shown as held after it was released; a release route answered while the page still shows
   the button; the first reading after a restart; a store not running; `prev` from another store's run.
   What exactly does the owner lose if a hold is missed for N seconds (read what the hold stops)?
2. **The other thing the gauges gave: a reader's holds (`HeldNow`) in the waiting verdict's causes.** The
   author's doubt: when the memory says no copier is busy but the reading did not ask the gauges, the
   causes can leave out the reader's holds for one reading. Is the page's sentence then false, and for how
   long?
3. **The written speed** (`livepages/staging.go`): the samples kept for 10 s; the rule for "no speed" (a
   count that went down, another store run, a clock that went back, the store not running in between, a gap
   over the window); can it ever show a speed across a restart, a negative or absurd speed, or "nothing
   written in the last N s" while bytes are being written (two readings inside one write call: is that a
   true 0); the units (kB/s, MB/s, "under 1 kB/s"); the same for the changed "copied and verified" figure.
   Shared state: which goroutines read and write the samples, and under what lock.
4. **Where the two reads are called.** The author says both run on the pages' handler goroutines after the
   collector's own lock is released, `/api/staging` under the server's own `s.stg.mu` with the reading's
   read transaction open, and that `StagingNow` does not reach `speedLimited` while `Load` does (outside the
   copier's mutex). Check each by reading; say whether any path can hold the collector's lock, the writer's
   lock or a catalogue transaction while it waits on another of them (an ordering that can deadlock or
   stall the live poll).
5. **The sentences that changed** (the report lists them): each true of the code and of the store; the
   times through the page's one form; nothing that claims the store "looks again by itself" where it does
   not (read `probeAway`'s limit: a look that never returns stops the loop's looks for the run).
6. **The tests.** The two mutations the author says were caught: apply each yourself in an overlay and run
   the named test; a test that judges on real time; test functions of the base that this difference
   removes (`git diff f7d6ca63 02b1ce2d | grep '^-func Test'`: the expected count is none); the two tests it
   adjusted to new words: still meaning what they meant.

## How to work
- Read the code yourself. Prove a finding where you can with a probe test in your own scratch folder
  `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g13-scratch`, loaded with `go test -overlay` (the
  tree stays untouched), or by reasoning from quoted lines. Mark each finding **CONFIRMED** or **PLAUSIBLE**.
- Go: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, one go command at a
  time, `GOGC=25 GOMAXPROCS=2 go test -p 1 -run '<names>' ./internal/<package>`: named tests only; no whole run
  of `internal/server`, `internal/collector`, `internal/store` or `internal/catalog`, no race detector, no
  Docker. Before each go command, IN A COMMAND OF ITS OWN:
  `powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`;
  wait when free memory is under 2.5 GB or the CPU is over 85%.
- Nothing runs against Telegram. Never touch `E:\T\tg-dl`, the folders `a3`, `b`, `app`,
  `C:\Users\trabi\tgarchive-app`, any real catalogue, media, session or account; start no installed program;
  open no window; send no input to the desktop; leave every running process alone. Invented data only.
  Print counts and timings only.
- Any file you write that holds a Windows path is written with the file-writing tool.

## What to hand back
Write `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-G13-staging-live.md`: findings in order of harm, each
with its mark, the file and lines, one concrete sequence of events, and the smallest change; must fix, then
should fix, then minor; a table "the hold goes on or off by ... -> the page shows it after ..."; what you
checked and found sound; what you did not look at. Your final message: the count by class, each must-fix in
one line with its mark, and your verdict ("may be listed", "may be listed after these fixes", "not ready").
