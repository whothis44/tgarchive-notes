# Brief: the program's own logging (tenth session, 2026-11-14; started 16:05 in `wt-logging`, on the margin's commit c869db2)

For one Opus coder in a copy of its own, made from the branch **after** `BRIEF-A4-wait-margin.md` has
landed (both touch `engine/lane.go`, `telegram/options.go` and the collector's flags and log). It needs one
catalogue schema step: take the next free number at the time (the exact check, in `wt-exact`, holds 11; if
it has not merged yet, the main session says which number to take).

The owner: "one of the big lessons learned from the old app". Every point below was found by losing data
for real on 11-13 (`archiver/docs/TRIED-BEFORE.md` section 27; read it and sections 11, 12, 24 and 26 first).

## What is wrong today (read by the main session at 8761d5c)

- `internal/collector/account.go` `hourlyTask` (768) writes the engines' counters (`flushAll`), the Telegram
  counts (`writeTgHours`) and the store's line (`logStoreHour`) **at each hour's end and at a clean stop
  only**. A kill or a crash loses the hour: after two starts on 11-13 `c_hourly` had 0 rows.
- The store's counts (`Resumed`, `ResumeBytes`, `ResumeRestarted` and the rest) are in **no table**, only
  in that hourly log line, and the resume counts are not even in the line.
- No time per request and no length of a wait is kept: only counts and sums per hour.
- Nothing is printed while it works: a healthy run and a stuck one look the same in the log.
- The VPN check prints nothing when it allows.
- A file set aside is logged; what became of it later is not.

## Build

1. **Counts every minute.** The same hourly rows, written again each minute (replaced, never added twice:
   check how `Flush` and `writeTgHours` write, and prove with a test that two flushes in one hour give the
   hour's numbers once), and at a clean stop as now. A flag for the interval (default 60 s). A flush never
   holds the catalogue's writer for long and a failed one is retried by the next (TRIED-BEFORE 21, A3).
   Test: counters at minute 5, a "kill" (no stop path), reopen: the rows hold minute 5's numbers.
2. **A heartbeat line a minute** in the log, numbers only, per account and server with work: files active,
   parts in flight, window, bytes and parts since the last line, waits (plain, speed limit) since the last
   line, connections lost and dialled since the last line, staged and waiting to copy, and the seconds
   since the last answered part (so "stuck" is visible). One line when nothing at all happened ("idle").
3. **Time to an answer and length of a wait, per kind of request** (parts, hashes, reference refreshes,
   history pages, chat list, differences, forwards, sign-in; the kinds `c_tg_hourly` already has): per hour
   the smallest, the median and the largest time to an answer, and for waits the smallest, median and
   largest seconds asked, plus how many waits were the second or later on the same request. A fixed set of
   buckets per kind and hour is enough for the median (say so in the column comments); no unbounded list in
   memory. Columns in the catalogue (the test that every exported counter has a column must keep passing).
   The wait margin piece already logs one line per part wait and per connection death; keep those lines,
   and add the deaths' counts **by error class** per hour to `c_conn_hourly` (a small table keyed by hour,
   server, kind and class word is fine).
4. **The store's counts in a table** (per hour, replaced each minute like the rest), with the resume
   counts; and the resume counts in the start-up lines ("N active files given back", "K parts kept") as
   "resumed N files from M bytes; R started over".
5. **The VPN check's verdict printed each time**, allowed or refused, as a fixed sentence with the check's
   number of the run and its milliseconds; counted per hour.
6. **A file set aside: one line when it is fetched after all or given up**, with how many tries and how
   long it was aside (numbers only: the file is named by nothing, or by its row number in the run).
7. **A small machine-readable status file beside the log** (TRIED-BEFORE 26, rule 6): JSON, rewritten
   every minute by write-to-temp-and-rename, numbers and fixed words only: the time, the program's build,
   per account and server the heartbeat's numbers and the hour's counts so far, waits running and their
   ends, the last error class per server. Scripts read this, never the log's prose. A test parses it.
8. **Requirements from what the old app could never answer** (its answers 4, point 12; each must be a
   number from the first day, with smallest, median and largest where it is a length): hash windows per
   answer; requests per exact check; candidates per check; seconds per check; waits per method; the length
   of each wait; connections made and lost; waits on message reads. Where the exact check is not merged
   yet, add the counters' places and say in the report which are fed and which wait for it.
9. **A number a counter cannot support is never shown as zero:** a count not fed in this build is absent
   or marked "not counted", in the tables, the heartbeat and the status file alike.

## Rules

- Constant format strings; arguments are numbers, server numbers and fixed words. **The privacy guard test
  covers every new line and the status file** (feed hard invented names through every path that reaches a
  line; none may appear).
- No new Telegram request of any kind. No change to what is sent or when.
- Nothing the logging does may block a download: no log or status write under a lane's lock or on the
  library's callback goroutines.
- Each new counter has a test on a known case (TRIED-BEFORE 11).
- Tests with an injected clock; no background loop runs in a test unless the test starts it.

## Bounds

The same as in `BRIEF-A4-wait-margin.md`, section "Bounds", word for word (no Telegram, no start of the
collector, work in the copy only, no commit or push, the Go environment script, `GOMEMLIMIT`, `-timeout`,
named tests, the memory gate, the lock directory, no process left behind, a PROGRESS file from the first
edit, a REPORT at the end). Additionally: the catalogue's whole tests and the collector's whole tests are
slow (minutes): named tests only; the main session runs the full and race runs before the merge.
