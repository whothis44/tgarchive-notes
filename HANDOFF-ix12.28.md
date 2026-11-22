# Handoff: ix.12.28 live, for the session after it (written 2026-11-11 ~09:00 local)

Read first: `START-HERE.md`, `CLAUDE.md`, then this file, then `PRE-PUSH-CHECKLIST.md` before any push.
`HANDOFF-ix12.24.md` holds 12.23–12.27 (what each changed and what to read after it). Everything below is
numbers only, from `E:\T\tg-dl\data\ixreports\*.txt` and `data\crashes\` (read-only).

## 1. Where things stand
| Version | Tag = commit | Branch | State |
|---|---|---|---|
| ix.12.27 | `v3.4.18-ix.12.27` = 66cdc26 | `ix/v12.27` in `repo-v12.16` | ran 11-11 00:37:18–02:45:52, ended clean |
| **ix.12.28** | `v3.4.18-ix.12.28` = 999a4af | **`ix/v12.28` in `repo-v12.16`** | **live since 11-11 02:46:26**; draft CI-only PR #40; release 42978971801 (8 archives + SHA256SUMS, latest) |

- The 12.27 → 12.28 install happened at 02:45 local under the speed limit, 34 s between stop and start: it looks like
  12.27's fix (automatic install under the limit) worked. Not proven it was not a manual install; ask the user if it matters.
- Further work branches from `ix/v12.28`. The user's OK for 12.28 ("Build and push it out") does not carry over.

## 2. What 12.28 is
`core-service/internal/telegram/floodguard.go`, the "most file requests refused" fallback. That fallback puts every file on
every server behind one shared gate for 2 h: each speed-limit wait (FLOOD_PREMIUM_WAIT) holds them all, and the engine
can't claim new files (`engine/controller.go` `unthrottled()` is empty while the files gate is closed). 12.28 changes when
it may fire:
- **Warm-up:** it needs `premiumRecent` (10 min) of record first. The record restarts at a start, after 10 quiet minutes
  (`recordStartLocked`), and after the fallback's own 2 h (`fallBackLocked` clears the record, `filesSince = sharedUntil`).
- **Busy servers:** every busy server (`premiumServerMin` = 10 or more parts plus waits in the window) must be refusing
  on its own (more than 2 waits per answered part), on top of the old account-wide rule (40 or more waits, more than 2 per
  part). Servers with fewer count neither way.
- **Setting `speedFallbackOff`** (Settings → Downloads, unticked by default): never take the fallback. Switching it off
  ends one in progress and clips its period in the report.
- **Tests:** `premium_ix124_test.go` (start, one refusing server, quiet server, light server, no re-arm, quiet stretch,
  the switch); `ix1217_report_test.go` `TestIx1228SpeedFallbackSwitchReachesTheDownloads`.
- **Review:** challenger reviewed it twice. The first pass found the fallback re-arming itself at the end of its 2 h
  (fixed); the second found no blockers. No new Telegram requests.

## 3. Findings (the important part)

### 3a. The speed limit is Telegram's, and our wait handling makes no difference now
This morning I claimed the fallback caused the slowdown since 11-10 16:00. **That was wrong**; 12.28's live hours
disproved it. Its CHANGELOG entry states that wrong cause: **correct it in the next release's notes.**

Servers 1+2+4 (DC1, DC2, DC4; server 5 left out because it swings 0–200 MB/h by itself), MB an hour under the limit:

| Hours (local) | Speed-limit waits handled | Servers 1+2+4, MB/h | MB per speed-limit wait |
|---|---|---|---|
| 11-10 01:00–12:00 | each wait holds its own request | 770–1,030 | ~0.9 |
| 11-10 17:00 – 11-11 02:00 | every file waits (fallback) | 530–590 | ~0.9 |
| **11-11 03:00–05:00 (12.28)** | **each wait holds its own request** | **561–581** | **~0.45** |
| 11-11 06:00–07:00 (12.28) | every file waits (fallback fired 06:04, 08:21) | 557–588 | ~0.9 |

- Around 11-10 16:00 Telegram halved each server's allowance: about 190 MB/h per server now, against 350–410 before.
  Asked wait stayed ~16 s.
- The two ways bring the same bytes. With each wait holding its own request we get about twice the refused requests
  (~420 waits/h per server against ~200); with every file waiting we get the same bytes with half the refusals.
  So the fallback firing under 12.28 costs nothing measurable. **Do not spend more work on the fallback.**
- Lesson: compare two ways of doing something **within the same Telegram conditions** (adjacent hours, same day), never a
  morning against an evening. MB per speed-limit wait is a quick check of which conditions an hour was in.

### 3b. Where the volume comes from
- Last 24 h at 08:00 11-11: 197.8 GB in 7,109 files (2.40 MB/s average). Nearly all of it comes from unlimited hours
  (50–103 GB/h; 11-10 14:00 and 15:00 ~68–70 GB/h). Limited hours bring ~0.6–0.8 GB/h for the whole account.
- 19 days left (account deleted 2026-11-30). The report's forecast (11-11 01:00) said everything queued fits at the last
  24 h speed.

### 3c. An outside LLM review (pasted by the user 11-11), checked against 12.27's code and the report
It read old code (pre-12.4 semantics). Point by point:
1. "Workers can't claim while the gate is closed": true only while the fallback is on. It is on often, but in this
   Telegram regime it doesn't change bytes (3a).
2. "One wait closes every server, plus 1 s margin": since 12.4 per request, except in the fallback. The 1 s margin
   (`floodGateMargin`) is still added to every wait (~6% of a 16 s wait). **Not changed:** unmeasured, and changing it
   changes the request pattern.
3. "Window capped at 2–8, can't grow under the limit": true and deliberate (12.21 caps 2 per server under the limit).
4. **"Growth slow and noisy in unlimited hours": supported, and the best open lever.** In 11-10's unlimited hours 14:00–15:00:
   - DC1's window was full at ~3 parts (of 8 allowed) with ~14 parts waiting, room unused 2–3%;
   - each slot brought ~3.2–4.1 MB/s (KB per slot-second on the routes line);
   - DC1 tried a bigger window 5 times, kept 2;
   - DC2/DC4/DC5 had 30–66% of their room unused for **lack of files** ("nothing in the way").

   paceByAnswers stays off (the user's choice).
5. "Build a throughput harness against a fake Telegram": reasonable in principle. It would not have caught this, though:
   its model would encode the same wrong assumption. The hourly report is the evidence that counts.

## 4. What to do next (each needs the user's OK; numbers first, one recommendation)
1. **Unlimited hours (the main lever).** Read every unlimited hour since 11-08 (`by hour` lines with speed limit ~0):
   - per-server window, "room unused", "nothing in the way", bigger windows tried and kept, KB per slot-second;
   - whether servers other than DC1 sit idle for lack of files. That is a claim/queue problem (top-up and lanes, see
     `ix_topup.go`, `engine/work.go`), not the pacer.

   Then propose one measured change, e.g. a faster climb on a server whose window is full with parts waiting, or keeping
   the learned window across a limited stretch. Unlimited hours are rare: plan for several before any "looks like".
2. **Under the limit: keep all four servers busy.**
   - Server 5 often brings 0–50 MB/h while getting ~200 waits/h (11-11 06:00–07:00: 45 and 22 MB). Read its -503 and
     set-aside lines before proposing anything.
   - Check servers with free slots and nothing claimable (top-up line, "idle download slots").
3. **Order:** with ~0.7 GB/h under the limit, check the front of the queue holds unique files of the ranked groups
   (held copies stay at the back, by the user's rule).
4. **Housekeeping:** correct 12.28's changelog cause in the next release; open items from HANDOFF-ix12.24.md still stand
   (item 16 import, A4, A5).

## 5. After any release, read (counts only)
- `crashes\running` (version) and `history.jsonl` (previous ended "clean").
- Report `update:` line, "speed-limit waits: … back to every file waiting, since start".
- `by hour` lines: servers 1+2+4 MB/h and MB per speed-limit wait (which Telegram conditions the hour was in) before
  comparing anything.
