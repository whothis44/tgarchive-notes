# Stopgap for the running app (fork): keep servers 2, 4 and 5 fed in unlimited hours

Instructions for an Opus agent (high effort) working on the **fork**, not on the new app. Written 2026-11-11
21:30 local by the session that is building the new app, from the fork's own numbers-only report of 21:10 and
from reading `core-service/internal/app/ix_topup.go` lines 1-135. It states what was measured, what is only a
guess, and what must be checked before any line of code changes.

## 0. Before anything else

1. Read `START-HERE.md` (rules, tools, code map, build, test and release flow), then `HANDOFF-ix12.28.md`, then
   `PRE-PUSH-CHECKLIST.md`, all in this folder, yourself, in full. Their rules win over this file.
2. The rules that matter most here:
   - **Never stop, restart, replace or reconfigure the running app.** It is downloading at 65-75 GB an hour
     right now. Only a published release changes it, and **publishing needs the owner's explicit OK for that
     version**. Push a branch only with the owner's OK. Draft CI-only PRs; never merge, never push `main`.
   - Privacy: `E:\T\tg-dl` is read-only, and only the report `data\ixreports\latest.txt`, `data\crashes\running`,
     `history.jsonl`, and the database as `file:E:/T/tg-dl/data/db.sqlite?mode=ro`. Print counts, sizes, timings
     and versions only. Never print a report line containing "same bytes as". Invented data in tests.
   - No new kind of Telegram request. Count what a change adds. No speed claim without a measurement; one
     day's numbers are "looks like".
   - New `ixLog` calls use constant format strings. Every new behaviour has a setting that switches it off.
   - Run `ix-tools/race.sh` and the pre-push checklist before any push. An independent challenger review
     (an agent that did not write the code) before release.
3. Work in the fork's current worktree as `START-HERE.md` names it (do not guess the folder). Do not touch
   `repo-archiver` (the new app) at all.

## 1. The problem, in numbers (the fork's report, 11-11, version 12.28, unlimited hours 18:00 to 21:00 local)

Telegram's speed limit lifted during the 17:00 hour. Since then:

| Hour | All | Server 1 | Server 2 | Server 4 | Server 5 |
|---|---|---|---|---|---|
| 18:00 | 65.2 GB | 28.3 | 5.9 | 17.9 | 13.6 |
| 19:00 | 72.3 GB | 33.0 | 12.5 | 22.4 | 7.2 |
| 20:00 | 74.6 GB | 40.4 | 9.7 | 22.0 | 3.9 |

Room unused with "nothing in the way" (the report's own measure), 19:00 / 20:00 / first minutes of 21:00:
server 1: 17% / 9% / 9%; **server 2: 57% / 69% / 90%; server 4: 17% / 23% / 45%; server 5: 51% / 73% / 98%.**

At 21:10 the file slots were: server 1 small 5 of 5 and large 2 of 2 (171 small and 1,562 large could start);
server 2 small 0 of 5, large 0 of 2, **0 could start**; server 4 small 0 of 5, large 1 of 2, 0 could start;
server 5 small 0 of 5, large 1 of 2, 0 could start. A snapshot twenty minutes earlier showed servers 2, 4 and 5
with nothing in flight at all.

Yet the files exist. "Not queued yet by server and size" in the same report: server 2 small 1,798, large 446;
server 4 small 20,872, large 5,083; server 5 small 4,812, large 1,341 (server 1: 43,695 and 8,796).

The top-up that is meant to prevent this (`ix_topup.go`, 12.20 to 12.24) reports: 4,175 files queued since
start (server 2: 1,984; server 4: 988; server 5: 1,203), "last 1 minute ago", 5,561 skipped (saved, queued or
filtered meanwhile), **one read of the saved messages took 22.1 s**, and **"read again early when a server ran
dry": 0 times**. Minutes a server got nothing, by why, since start: server 5 "-503 storm" 128, "files
retrying" 28; server 2 "plain wait" 22; server 4 "plain wait" 19, "set-aside files go first" 14.

The files pass (rescan) meanwhile: "waiting for room" 22-24 minutes of each unlimited hour, the queue at 764
of its limit of 500, 241-362 slot-minutes of idle download slots an hour while it waited.

Speed per slot-second when these servers do have work (20:00 and 21:00): server 2 about 3.4-3.9 MB, server 4
about 3.8 MB, the same as the others. **So the servers are not slow; they are unfed.** A rough ceiling from
those figures, not a forecast: server 2 at 2-3 parts could carry roughly 25-40 GB an hour against 6-12, and
server 4 at 2 parts roughly 27 against 18-22. Whether that is reached depends on its files and on Telegram.

## 2. What was tried before (do not repeat it; build on it)

From the changelog and `ix_topup.go`'s own comments:
- 12.20: top-up from saved messages once a minute, a few files per idle server: server 2 went from 5-8.3 to
  18.6 GB in an hour.
- 12.22: read the saved messages again when a server with free slots has no candidates left (at most every
  3 minutes), and 4 files per free slot instead of fewer. It runs only while the speed limit is off.
- 12.23, 12.24: the same under the limit, up to 3 files kept, larger first (under 512 MB).
- 12.25: the 1 GB big-file limit per server instead of per account.
- Earlier: raising or bypassing the 500 queue limit was considered (12.17 added the report line that asks
  whether it is worth raising) and not done.
- **Result today, after all of it: 57-90% of server 2's room and 51-98% of server 5's still unused.**

## 3. What is NOT known (find out first; do not assume)

These are guesses from reading the constants (`ixTopUpEvery = 1 minute`, `ixTopUpPerSlot = 4`,
`ixTopUpMax = 30` per server and size per step) and the report. **Prove or disprove each from the code and
the report before changing anything, and write down what you found.**

- **A. The step is too coarse for small files.** One step a minute queues at most 4 files per free slot, 20 for
  five small slots. Small files finish in a second or two in unlimited hours, so the server may run dry within
  seconds and idle until the next minute. (12.24's comment describes exactly this under the limit: "its small
  files finished within the minute, then it waited for the next step".) Check: how long 20 small files of
  server 2 last at its measured speed; whether the report's per-hour "files" per server fits "20 a minute".
- **B. The early re-read never fires** ("ran dry 0"). Why: is its condition ever true, is it blocked by the
  22 s read, by `msgMark` not moving, or by the candidates list not being empty while every candidate is
  refused?
- **C. Candidates are refused more often than queued** (5,561 skipped against 4,175 queued). By what: already
  saved or queued, the chat's filter, the deadline order's set-aside, held as copies? If most candidates of a
  server are refused, a longer list per read, or skipping refused ones cheaply, matters more than the step.
- **D. The 22 s read.** What it reads and decodes, whether it holds a lock or the database writer, and whether
  it can keep a per-server list that is consumed across steps instead of being rebuilt.
- **E. Server 4's large slots** stood at 1 of 2 with "0 could start" and 235 large files set aside. Which
  set-aside (deadline order, big-file lane, copies)? Is the top-up queueing large files for server 4 at all
  (it has 5,083 large files not queued)?
- **F. Server 5 is a different problem**: half its slot time goes to "-503" timeouts (2,640 of 5,220 s at
  20:00, 3,981 of 8,280 s at 19:00). Feeding it more will not help much. Leave it out of the goal.

Also seen, **not part of this task unless the owner asks**: on server 1 at 19:00, 3,538 of 12,680 slot-seconds
went to "-503" answers, with 26 runs of 20 or more retries and "try 3+: 0 of 489 answered". The set-aside rule
of 12.19-12.21 should have ended those runs after 2 or 3. Report why it did not (read `timeout_aside.go` and
its conditions), as a finding only.

## 4. The change wanted (only if section 3 supports it)

Goal: in hours without the speed limit, a server with free file slots and files of its own known in saved
messages is given work within seconds, not within a minute, until its slots are full or its list is empty.

Shape (adjust to what you find; say what you changed and why):
- Keep the existing top-up and its filter, order (ranked chats first) and copy handling. No new kind of
  Telegram request: each queued file still costs the one message refresh every file gets when it is claimed.
- When a server and size class has a free slot and nothing that could start, top it up **when that happens**
  (or on a short tick of about 5 s for servers with free slots), not once a minute; size the batch from what
  the server consumed in the last minute (files finished per minute for that server and class), with a hard
  cap, so a server of small files gets enough to last until the next look and a server of large files is not
  flooded.
- Keep a per-server candidate list between reads and take from it; re-read the saved messages when a list is
  short, off the hot path, at most every 3 minutes as now (or sooner only if D shows the read is cheap).
- Only while the speed limit is off (as 12.22). Under the limit nothing changes.
- A setting to switch the new pacing off (back to once a minute), following the existing `topUpOff` pattern.
- The report says what happened: per server and hour, minutes with a free slot while candidates existed, files
  queued by the top-up, top-up steps, candidates refused by why. Each new counter has a test on a known case.

Do **not**: raise or remove the 500 queue limit; change the window, the waits, the file slots (5 small and 2
large per server are Telegram's own), the deadline order, or anything about copies; let probable copies go
ahead of unique files; add sessions or connections.

## 5. Proof before release

- Tests with invented data: a server whose small files finish in 1 s each stays above N files ready for an
  hour of simulated time; a server with only refused candidates does not spin or re-read in a loop; under the
  limit the behaviour is byte-for-byte the old one; the setting off gives the old once-a-minute behaviour; the
  queue's count of top-up files stays bounded.
- `go vet`, the package tests, `ix-tools/race.sh`, the pre-push checklist.
- An independent challenger review of the diff (download path): give it this file and the report numbers.
- A short note for the owner: what changed, the requests it adds per hour (expected: about one message
  refresh per additional file downloaded, nothing else), how to switch it off, and what to look at after it is
  live: in the next unlimited hours, "room unused: nothing in the way" for servers 2 and 4 against today's
  57-90% and 17-45%, and GB per hour per server against the table in section 1. Compare unlimited hours with
  unlimited hours only. If the numbers do not move, say so; do not explain it away.

## 6. Release

Only with the owner's explicit OK for the version number, by the flow in `START-HERE.md`. Publishing installs
itself on the live archive and restarts it; in unlimited hours the owner has seen that take about 30 s. Say
that in the request for the OK, with the time of day you propose.
