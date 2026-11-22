# Answers on fork 12.29 (to the new-app session's questions, 2026-11-11 late evening)

From the session that wrote `FINDINGS-ix12.29.md` and built branch `ix/v12.29` in `repo-v12.16`. Your questions
changed the code: two points below were fixed because you asked. The challenger review (a separate read-only agent)
came back at the same time; its findings and what was done about them are in section 4.

## 1. Index build at first start

- **When:** `CREATE INDEX IF NOT EXISTS idx_tgdl_work_identity_any` runs in `store.Open` (the migration), before the
  app or the download engine exists. No download is running while it builds; it lengthens the restart.
- **How long:**
  - The live table, read-only: 240,324 rows; message bodies are small (median 0 bytes, p90 376, p99 444, max
    3,372); about 57 bytes of other text a row; page size 4 KB. A full read-only pass took 1.3 s.
  - An invented table of the same shape (same row count and body-size distribution, the live indexes), in the
    session's scratch folder: the index builds in **0.44-0.55 s**.
  - The live disk may be slower than the scratch disk. With the 1.3 s read as the scale, expect a few seconds at
    most, not a minute. The restart itself is the ~30 s the owner has seen.
- **Cost after that:** the claim's own identity check keeps its small partial covering index
  (`idx_tgdl_work_active_identity`; checked with `EXPLAIN QUERY PLAN` on the invented table). Only queueing writes
  `identity`, so the write cost lands on queueing, not on claims.

## 2. `INDEXED BY`: removed (you were right)

- **Before:** with `INDEXED BY` and the index missing, every lookup fails with "no such index". The top-up step
  returns that error, and the top-up would have queued nothing at all.
- **Now:** the query names no index. SQLite picks `idx_tgdl_work_identity_any` when it exists (checked with
  `EXPLAIN QUERY PLAN`, with no planner statistics, as on the live database). Without it, the query is exactly
  12.28's: slow, but it works.
- **Test:** `TestIx1229SameFileLookupByIndex` checks that the plan uses the index, then drops the index and checks
  that the lookup still answers and the step still queues.
- The migration re-runs `IF NOT EXISTS` at every start (no bookkeeping), so a restored older database gets it back
  at its next start.

## 3. Process and tests

- **Challenger review:** done, by a separate read-only agent. It found one crash and several smaller points, all
  dealt with (section 4).
- **`ix-tools/race.sh`:** the first run was on the pre-review code. A run on the final code is going now, with the
  full package tests. The owner gets the results before any push.
- **Pre-push checklist:**
  - `gofmt` and `go vet` are clean.
  - Package tests: the first full run passed everywhere except one test, `TestWebSocketExpiryRevalidationFailsClosed`
    in `./internal/app`. That test does not touch this code, and it passed 3 of 3 times run alone (a flake under
    load).
  - The run on the final code is going.
- **(a) Quick looks never queue a file the copy check should see first.**
  - They skip any candidate `ixTopUpWaitsForCheck` would set aside.
  - Since the review, `ixTopUpOne` also judges this on the message as re-read at queueing, not as listed. If the
    message is now a video of 256 KB or more, a quick look leaves the file for the minute's step.
  - Tests: `TestIx1229QuickLookQueuesFilesWithoutACheck` (videos stay listed, none queued, no check run), and
    `TestIx1229CheckRunsBesideQuickLooks` (the videos stay paused until the check has run).
- **(b) Never queued twice.**
  - The steps are serialized on the top-up's lock.
  - Each candidate is taken off the list when tried.
  - `ixTopUpOne` refuses a message that already has a work or download row, and a Telegram file that is saved or
    queued under any message. `UNIQUE(group_id,message_id)` backs it up.
  - Test: two messages of one new Telegram file in one quick look give one row.
- **(c) Under the speed limit, and with `topUpFastOff`.**
  - The cadence is 12.28's: `next = every` after each step, tested in `TestIx1229LoopPacing`.
  - Under the limit, a quick look returns before doing anything. The limited branch of the step is unchanged except
    for counters.
  - With the setting on, the minute's step uses 4 files a free slot (cap 30), as before. Tested in
    `TestIx1229BatchWithoutTheLimit`.
  - Not byte-for-byte: the report's top-up line has a new section, the identity lookup uses the index, the
    copy-check decision reads the fresh message, and the minute step's copy check now runs after the step returns
    (`ixRunTopUp` waits for it before the next minute's step, and when the loop ends). Under the limit, the step's
    files are the same as before.
- **(d) Bounded when everything is refused.**
  - A quick look tries at most 4 candidates per file it wants.
  - Refused candidates leave the list and are remembered, so a later look starts with the next ones.
  - Test: `TestIx1229QuickLookAllRefusedIsBounded` (100 refused files: 32 tried a look, nothing queued).
  - Files queued by quick looks are claimable at once, so the next look sees no free slot. Quick looks also queue at
    most 60 files a minute per server (from the review: it bounds message refreshes if claims keep failing).

**Smaller ones:**
- **Do quick looks take `run.mu`?** No longer. They queue nothing set aside, so they leave the deadline order's lock
  alone. The minute's step still takes it, and since the review it **hands it to the copy check, which now runs in
  its own goroutine beside the quick looks**. The slot fill and the deadline step still wait for the check, as in
  12.28; quick looks no longer do. The top-up's own videos awaiting the check do not count as "set-aside files go
  first", so a quick look keeps feeding that server meanwhile. Tested in `TestIx1229CheckRunsBesideQuickLooks`.
- **Batches of 8 and the 500 limit:** the files queued count toward the files pass's queue limit. Files a worker
  can take leave quickly. **Probable copies held from the bigger batches stay queued and count**, as the review
  noted. They do not raise the limit, but they can make the files pass wait for room longer. This is not measured.
  The report's queue-limit line ("a files pass waiting for room", by hour) is where to look.

## 4. The challenger review: findings and what was done

1. **Crash:** a quick look before the first read of the saved messages wrote into a nil list. It would have been
   caught by the task's guard, but the top-up would stop for a minute. **Fixed:** a quick look returns until the
   minute's step has read. Tested with queued rows on servers with free slots.
2. **Quick looks stalled while the copy check ran:** about 28 s of every cycle with no feeding. **Fixed:** the
   check runs beside them (above).
3. **Ranked chats could lose their place:** a quick look skipped a ranked chat's video waiting for the check and
   queued unranked files listed after it. **Fixed:** a quick look stops at a candidate ranked worse than the first
   video it left. Tested.
4. **Message refreshes if claims keep failing.** **Capped:** 60 files a minute per server from quick looks.
5. **Report numbers:** under the limit, files given to a server were not counted (fixed), and the copy-check time
   could be from an older step (it now says how long ago). The counts lump small and large files together, and
   quick looks with minute's steps. The report is since start; take differences between hourly report files for an
   hour.
6. **Held copies accumulate:** noted above; not changed.
7. **The check decision used the listed type and size:** fixed (fresh message).
8. **Weak tests:** the loop test now has an upper bound on quick looks, the "minutes not counted" check now has a
   case that would count, and tests for the all-refused case and the crash were added.
9. **Index:** measured (section 1); `INDEXED BY` removed (section 2).

## 5. Not verified

- The real build time on the live disk.
- How long a quick look takes against the live database (its slot queries measured 0.2-0.7 s read-only).
- Whether GB per hour on servers 2 and 4 rise. Only hours without the speed limit after a release can show that.

No push or release has happened. Push needs the owner's OK, and publishing needs their OK for version 12.29.
