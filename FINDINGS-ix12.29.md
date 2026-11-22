# Findings for STOPGAP-ix12.29.md: why servers 2, 4 and 5 sat unfed (written 2026-11-11 ~23:00 local)

For the session building the new app (and any later session on the fork). It answers section 3 of
`STOPGAP-ix12.29.md`, says how each answer was measured, and what 12.29 changes. Numbers only, read-only, from the
live report (`data\ixreports\*.txt`) and the database opened `?mode=ro`, 11-11 18:00-21:00 local (no speed limit,
12.28). The scripts are counts and timings only; their method is described below so the same can be done again.

## 1. The short answer

The top-up was not too slow because of its once-a-minute clock alone. Two delays inside each step, which the report
never showed, were larger:

1. **The step spent about 26 s queueing its files.** For every file it would queue, `ixTopUpOne` asks whether its
   Telegram file is saved or queued already: `SELECT COUNT(*) FROM tgdl_work WHERE identity=? AND status IN
   ('pending','processing','completed')`. No index covers `identity` for those statuses (only
   `idx_tgdl_work_active_identity`, for `processing`), so SQLite walks every work row through the status index
   (~197,000 completed rows, each with its message body). Timed read-only on the live database with an invented
   value: **2.0-2.8 s per lookup.** Every candidate pays it, the refused ones too, unless an earlier check already
   refused them.
2. **Videos then waited for the copy check.** A video of 256 KB or more (`ixHoldCheckMin`) is queued paused, set
   aside in `ix_deferred`, until `ixHeldTriage` has looked at it. That runs in the step's deferred function, still
   holding the top-up's lock and the deadline order's `run.mu`. The triage re-reads all ~40,000 queued videos each
   time. Measured through `ix_deferred` (`released_at - deferred_at` of files set aside when queued):
   | Server, size | Top-up files set aside when queued | Median wait until let go | Files not set aside: queued to done |
   |---|---|---|---|
   | DC2 small | 723 of 1,466 | 46 s (p75 58) | median 1 s |
   | DC2 large | 228 of 355 | 33 s | median 1 s |
   | DC4 small | 484 of 3,905 | 30 s | median 4 s |
   | DC5 small | 421 of 1,230 | 20 s | median 1 s |

   Seen per step (files set aside in one step share one `released_at`): 152 steps; from the step's first file
   queued to the release, median 54 s (p25 38, p75 70); of that, **queueing alone median 26 s** (first to last
   file set aside), so the check took about 28 s.

So a cycle was: queue for ~26 s, check for ~28 s (videos paused meanwhile, and the slot fill and deadline step
blocked on `run.mu`), then sleep 60 s from the end. That is a ~115 s cycle in which a server got non-videos spread
over ~26 s and videos in one burst at ~54 s. Files that were not held finished about a second after queueing, so
the rest of the cycle was empty.

How it looked in the queue: the time-weighted count of each server's files in the queue (only files that later
completed, counted from `created_at` to `updated_at`):
| Server, size | No file queued at all | 6 or more queued |
|---|---|---|
| DC2 small | 49% of the 3 h | 37% |
| DC2 large | 31% | 16% |
| DC4 small | 12% | 47% |
| DC4 large | 0% | 100% |
| DC5 small | 56% | 27% |

The two-peaked shape for DC2 small (empty or 6+, rarely between) is a batch arriving, waiting, then draining fast.
At the same time, 1,798 DC2 small files were listed and waiting in the top-up's list.

## 2. Section 3 of the stopgap, point by point

- **A (step too coarse): partly.** Small files do finish in seconds once they may start: median 1 s for files not
  set aside. But the step was not "4 files a slot, then wait 60 s". It was "26 s of queueing, 28 s of check, then
  60 s". The per-step cap (20 small) mattered less than the step's length.
- **B (early re-read never fires): not a bug.** Its condition needs a server with free slots and an **empty** list
  (`len(st.cands[k]) == 0`). The lists never emptied (DC2 small 1,798, DC4 small 20,872 left), and the reason
  "no files left" never appears in the report's skip reasons. It is a guard for a different case.
- **C (refused more than queued): not measurable from 12.28's report.** It counts only the total (5,561). The likely
  large reason: the read lists messages with no `downloads` or `tgdl_work` row by (group, message), not by Telegram
  file, and the report counts 36,386 seen-not-downloaded files whose Telegram file is the same as another's. Each
  such candidate paid the 2-2.8 s lookup to be refused. 12.29 counts refusals by why.
- **D (the 22 s read):** reader only, no writer, but it runs holding the top-up's lock and `run.mu`. It runs once
  every 30 minutes, so it is minor next to the per-step 54 s. Not changed.
- **E (DC4 large at 1 of 2, 0 could start):** two things. (1) The top-up leaves a server and size alone while it
  has set-aside files not held as copies ("set-aside files go first"), counting on the slot fill to let them go.
  (2) The slot fill (every 20 s) takes `run.mu`, which the top-up held for ~54 s of every ~115 s. Of DC4's large
  pending files at 21:10, 4,792 of 4,867 were held as probable copies (correctly at the back). The rest were set
  aside by the deadline order or awaiting checks.
- **F (DC5):** agreed, left out.
- **Server 1's 20+ retry runs (finding only):** `timeout_aside.go` sets a file aside only if other files of the
  server were answered after the run began (DC1 answered 2,183 files that hour, so this nearly always holds), the
  server has used fewer than 20 set-asides in 10 minutes, and **the file has been set aside fewer than 3 times in
  this run of the app** (`asideRepeatsMax`, deliberate since a 12.20 review: after that, a dead file spends its
  attempts and is given up). At 19:00 DC1's -503s came from 3 files (1 also answered), with 26 runs of 20+ and
  "set aside 0, gave up 7". With the app up since 02:46, the likeliest reason is that those few dead files had used
  their 3 set-asides. **Not verified:** the report does not count set-asides refused by which cap.

## 3. Traps that cost time here (worth knowing before reading this report)

- **"Room unused" is not idle time.** It is the share of 10 s samples in which the server's window had a free part
  and no part was waiting. A server running 1.4 parts in a window of 2.3 counts as "room unused" in most samples.
  To see whether a server was **unfed**, count its files in the queue over time from `tgdl_work.created_at` /
  `updated_at` (as above), and check `paused` and `ix_deferred` for files queued but not allowed to start.
- **The 500 queue limit is not what holds the top-up.** It holds the rescan's files pass only. The top-up queues past
  it (676 of 500 at 21:10). Raising the limit would add files-pass reads from Telegram, mostly for DC1's groups.
- **Time a step from the database, not the report.** The report had no step durations. Shared timestamps (one
  `released_at` per step) give them for free.
- **Time a suspicious query against the live database read-only, with an invented value**, before guessing at
  causes. Here one `EXPLAIN QUERY PLAN` and three timings found the main cost.
- **The worker count was not the limit:** 25 workers configured (`download.concurrent` 25, scaling off since
  `maxConcurrency` 20 is lower), 28 file slots in all, and 13-14 downloading at the 21:10 snapshot.

## 4. What 12.29 changes (fork, branch `ix/v12.29`)

- `store/migrate.go`: index `idx_tgdl_work_identity_any ON tgdl_work(identity)`. SQLite picks it for the lookup.
  The query does not name it, so without the index the query is 12.28's. It is built in `store.Open` before
  downloads start: 0.44-0.55 s on an invented table of the live size (see `ANSWERS-ix12.29.md`).
- After the challenger review and the new-app session's questions (details in `ANSWERS-ix12.29.md`):
  - the minute step's copy check runs in its own goroutine, holding `run.mu`, beside the quick looks;
  - quick looks take no `run.mu`;
  - a quick look stops at a candidate ranked worse than a video it left for the check;
  - quick looks queue at most 60 files a minute per server;
  - the copy-check decision uses the freshly read message.
- `app/ix_topup.go`:
  - **Quick looks:** without the speed limit, every 10 s between the minute's steps. They queue only files no copy
    check looks at (non-videos, videos under 256 KB, or every file when "hold likely copies" is off). They start at
    once, as before. Quick looks run no copy check, no read of the saved messages and no early re-read, and add
    nothing to "minutes a server got nothing". Videos stay in their place in the list for the minute's step.
  - **Bigger batches:** without the limit, the minute's step queues up to 8 files per free slot (at most 40 per
    server and size) instead of 4 (30). This makes the videos released after the check last longer. Free slots
    count only files a worker could take, so the number queued stays bounded by the slots.
  - **Under the limit, or with the new setting** "Without the speed limit, look at idle servers once a minute only"
    (`topUpFastOff`), the step and its cadence are as in 12.28.
  - **Report**, on the top-up line: steps by kind; files queued by quick looks per server; per server, the looks it
    had free slots and files listed, and those it got files; refusals by why; the last minute's step's queueing time
    and copy-check time.
- **Not changed:** the copy check itself (~28 s, it re-reads all queued videos). It is the next lever for videos.
  The 500 limit, waits, slots, deadline order and copies are untouched. No new kind of Telegram request: each file
  still costs the one message refresh at claim.

## 5. What to read after it is live (unlimited hours against unlimited hours only)

- The top-up line: "the last minute's step queued N files in X ms" (expect well under a second per file, against
  ~26 s per step), "copy check after it Y ms", and "looks ... given files" per server.
- `by hour`: DC2 and DC4 MB, and files per server, against 11-11 18:00-20:00 (DC2 5.9 / 12.5 / 9.7 GB; DC4 17.9 /
  22.4 / 22.0 GB). "Room unused" can be compared too, with the trap in section 3 in mind.
- If DC2 stays near 10 GB an hour, say so. The next candidate is then the copy check's ~28 s for videos.

## 6. For the new app

- Any per-file "already have this Telegram file?" lookup needs an index on the identity for every status, or an
  in-memory set. At 200,000+ rows a table walk per file costs seconds.
- Do not make freshly queued files wait for a whole-queue copy check. Check new files against an index that is kept
  up to date, so the check for one file costs milliseconds, not a pass over 40,000.
- Keep the feeder off the locks that the slot-filling path needs.
