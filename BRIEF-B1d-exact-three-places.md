# Brief: the exact check judges a video at three places, as the old app does (the owner, 2026-11-14)

This replaces fix 3 of `BRIEF-B1c-exact-review2-fixes.md` and changes the default of the setting. For the
coder working in `wt-exact`; the bounds of `BRIEF-B1c` apply unchanged (commit after each item).

## The decision (the owner, 11-14, after the second review and after the main session read the old app's
`ix_subst.go` in full)

"The sample checks are critical to efficient downloading", most of all for a frozen account where time is
limited. Asked whether three places should decide "same" for video by default, as in the old app: "I think
that's sensible. The three places. Seems like a reasonable compromise with, I expect, minimal downside.
This is all about tradeoffs." This reverses the thirteenth round's default (compare in full); the full
comparison stays as a setting.

Why: comparing a video in full costs thousands of hash requests for one large file, reads the whole saved
copy from the library, and holds the file for up to an hour; the budget, the library's turn and the
set-aside rules exist only to contain that, and most of the second review's findings come from it. The old
app's three places cost 3 requests and a few MiB read: 3,932 videos (233 GB) not downloaded in ten days,
none known wrong (none re-checked either). The new app's spot check is the guard the old app never had.

## What the old app does (read it yourself: `wt-v12.30/core-service/internal/app/ix_subst.go`)

Video of 2 MiB or more: hash requests at the start, the middle and the end; every hash in those answers is
compared with the saved file's bytes; all equal: same. Everything else from 256 KiB: every part's hash, at
most 64 requests, else downloaded. Anything undecided: the file goes on to its download.

## Build

1. **The setting's three values are now `three-places` (the default), `full`, `off`.**
   - **`three-places`:**
     - a video (the present rule for "video") of 2 MiB or more: one hash request at each place: the
       start, the middle, the end; **over 256 MiB five more, at one sixth to five sixths** (eight places:
       the old app's `sampleOffsets`). Every window in those answers is compared with the saved copy's
       bytes. Each place must be covered by its own answer (the first review's F4 stays). All equal:
       **same** (linked, not downloaded). Any window different: different. Anything else: unknown.
     - everything else, and a video under 2 MiB: every window, within the bound of 64 requests; over the
       bound: unknown.
     - **The outcome "probable copy, held" for a three-place match is gone**: three places decide. (The
       look-alike hold is another feature and is not touched.)
   - **`full`:** every window whatever the size, as built. **Whenever a full comparison may not run or
     may not go on** (the hourly budget is reached, the three-waits rule has tripped, the candidate is in
     the library while copies are waiting to start, the setting was changed) **the file is judged by the
     `three-places` rule instead**, at once; counted (`full_fell_back`, by reason).
   - **`off`:** no hash request; a running check stops within one call and links nothing (fix 4).
2. **Nothing is set aside, held or sent back by this check any more.** Remove the "same size, not
   compared yet" hold, the hour's set-aside, and the library's turn sending a file back (the engine's
   `CheckDeferred` and `CheckWaitTurn` outcomes, the catalogue's `HoldNotCompared` and `WaitTurn`, their
   counts and tests), unless something else uses them; say what you removed. The schema step 11 has not
   merged, so take their columns and kinds out of it; no new schema number. **An undecided check always
   ends in the file's download**, as in the old app.
3. **The budget and the three-waits rule after this:**
   - the budget (requests per server and hour) only decides whether `full` may run (see 1);
   - three waits on hash requests of one server within the clock hour: no further check starts on that
     server in that hour, in either mode; files are downloaded unchecked meanwhile; counted, one log line
     when it trips. (A check that is running when it trips ends unknown.)
4. **The spot check stays as built and now guards the three-place verdicts too:** one "same" in every
   hundred (the config field) is downloaded all the same and its SHA-256 compared; a difference raises
   the alarm and switches the setting to `off` until the owner switches it on. **Additionally the first
   20 "same" verdicts of a catalogue by three places are all spot-checked** (a config field, default 20;
   the count kept in the catalogue), so that the rule has a measured error rate on this account before it
   is trusted. Record with each spot check whether its verdict was by three places or in full.
5. **The record and the log line of each comparison** say which rule decided (`three-places` or `full`),
   the places asked, the windows compared and the bytes covered, so that "how much of the file three
   answers cover" becomes a number from the first real request.
6. **Fix 5 of `BRIEF-B1c` (the library's turn asked again before the read) and its fix 3 are replaced by
   the above.** Fixes 1, 2, 4, 6, 7, 8 and 9 stand. For fix 6: the counts that the three-waits rule and
   the budget rest on are still written at each tick and read back at a start. For fix 7: the one extra
   call at the recorded size applies to `full` only; in `three-places` the end place already asks for the
   last window, and a window returned past the recorded size makes the result unknown.
7. **Tests** (each with a bounded mutation):
   - a video of 300 MiB with a same-bytes candidate: 8 hash requests, same, linked, no part asked;
   - a video of 50 MiB: 3 requests; one differing byte inside a compared window: different, downloaded;
   - a video whose bytes differ only in a place that is not compared: same by three places (this is the
     accepted trade-off: the test documents it and asserts the spot check, when due, downloads it, finds
     the difference, raises the alarm and switches the check off);
   - a photo and a document over the 64-request bound: unknown, downloaded;
   - `full` with the budget reached, with three waits, with copies waiting: judged by three places,
     counted by reason;
   - the first 20 by three places are all spot-checked; the count survives a restart;
   - the review's probes for findings 2 and 3 now pass because nothing is held or sent back: 10 of 10
     unique files saved through a 30-minute hash wait.
8. **The report's first section, for the owner:** what the default now does, in five lines; the accepted
   trade-off stated plainly (a video that differs only between the compared places would be linked as
   same; the spot check is what would show it); what is counted so the owner can judge it after the first
   hundred verdicts (verdicts by rule, spot checks and their results, bytes not downloaded).
