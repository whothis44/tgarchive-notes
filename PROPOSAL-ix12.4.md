# ix.12.4 proposal and 12.3 speed findings (2026-11-05, ~22:45 local)

Read only. Counts only. Nothing in the live install was touched.

## 12.3 is live

`tgdl-server 3.4.18-ix.12.3`, started 21:19:03 under the crash-capture supervisor (two processes, `window.log` present).
No crash. Heap 741 MB and resident 1,379 MB at 80 min uptime (12.1 swung 620-1,180 MB heap): nothing unusual yet.

## Why downloading looks stalled

**Telegram's speed limit has been on since about 18:20.** The archive is getting what it got under 12.1 in the same
stretch. Bytes per hour, from the pacer's hour records (every part, unfinished files included):

| hour | version | MB | parts allowed, average | speed-limit waits | parts between waits |
|---|---|---|---|---|---|
| 14:00 | 12.1 | 3,621 | 4.6 | 246 | 14.8 |
| 15:00 | 12.1 | 1,575 | 2.5 | 258 | 6.1 |
| 16:00 | 12.1 | 3,925 | 3.1 | 170 | 23.2 |
| 19:00 | 12.1 | 2,026 | 2.2 | 181 | 11.3 |
| 20:00 | 12.1 | 1,541 | 1.5 | 205 | 7.6 |
| 21:00 | 12.1 / 12.3 from 21:19 | 1,226 | 1.3 | 190 | 6.5 |
| 22:00 (first 29 min) | 12.3 | 586 (≈1,230 an hour) | 1.2 | 94 | 6.3 |

**What happens now:**
- All 25 downloading files sit on one Telegram server (DC1).
- DC1 may have **1 part** in flight. The pacer learned that window earlier and does not change it while
  speed-limit waits come in.
- Each speed-limit wait closes the gate for every file for about 15 s. Then about 6 parts arrive in about
  1.2 s, and the next wait comes.
- In the 22:00 hour, the one slot spent 125 s receiving parts and the rest of the 29 minutes waiting.
- That cycle is the bottom bar's pattern: 0 B/s, then 3 MiB within its 5-second window (= 614 KB/s), then 0 again.

**More parts in flight brought more under the limit on earlier hours.** 14:00 had 4.6 parts allowed, 14.8 parts
between waits and 3.6 GB. 22:00 has 1.2 parts, 6.3 between waits and about 1.2 GB an hour. 15:00 does not fit,
and the limit's severity may change by the hour, so this is a correlation, not a proof. Still, it contradicts the
code's assumption that fewer parts at once make no difference against this limit (`floodguard.go`).

**Why the drain and pausing felt faster.** During the drain no new file started. The same 1.2-2 GB an hour went
into fewer files, and they finished one after another. Now 25 files share it (20 of them over 20 MB, 1,985 MB in
all), so few finish: 7 in the last hour. The hour totals do not show the drain itself bringing more bytes
(20:00: 1.5 GB). Nothing records minutes, so I cannot check your pausing moments.

**Task Manager.** Over 30 s, the WireGuard tunnel (Telegram) received 0.42 MB/s, which matches the app's
0.36 MB/s plus overhead. WiFi received 7.2 MB/s. That includes the tunnel's traffic a second time (encrypted),
plus about 6.8 MB/s from something else. That is most likely the app reading the library from the NAS
(integrity checks: 5,960 this cycle; video frames: 3,547 to go), or other programs on WiFi. It is not
Telegram, and it does not slow Telegram down (parts are answered in 0.2 s).

**Big-video checks** since 12.3 started: 11 checks used 114 MB of parts (about 8 % of what arrived), and 8 matched.

**"Telegram profile photo unavailable" over and over:** no request reaches Telegram. This run has no chat list
(the account is frozen and the listing is refused), so each page load asks for every group's photo and prints
a line for each. It is harmless. 12.4 fix: remember the miss and say it once.

### Added after your question: one server holds every download slot

Counted read-only from the queued messages (each file records the server it is stored on):

| | DC1 | DC2 | DC4 | DC5 |
|---|---|---|---|---|
| downloading now | 24 files | 0 | 1 | 0 |
| ranked, free to claim | 579 / 68.5 GB | 158 / 16.8 GB | 402 / 45.0 GB | 73 / 8.3 GB |
| next 300 in claim order | 152 | 35 | 94 | 19 |

- Workers claim files in rank order without looking at the server. A DC4 or DC2 file finishes and its worker
  takes the next file. A DC1 file stays. So workers pile up on DC1: 24 of 25 are there. Most of them wait for one
  of DC1's 2 large-file slots (17.9 on average in the 22:00 hour), while DC2, DC4 and DC5 sit idle with
  ranked work queued.
- A speed-limit wait on any server closes the gate for every server (`floodguard.go`: one `filesUntil` per account).
  So the app would hide a per-server limit even if there was one. The earlier "30-hour history said no" could not
  have told the difference.
- Evidence for a per-server limit is mixed. In the 21:00 hour, DC4 also had 8 speed-limit waits of its own
  (122 MB), against DC1's 130 (734 MB). That is too little to decide.
- Telegram does not assign servers by group. Each file stays on the server it was uploaded to, usually the
  uploader's home server, and a forward keeps the original's. Groups mix servers, so spreading by server works
  better than picking groups.

**Proposed first (C), before B:**
- **C1.** A server may hold at most as many downloading files as it has file slots (2 large + 5 small). Workers
  then take the next file in rank order on another server. Each queued row gets its server at queue time, and
  existing rows get it once from their stored message.
- **C2.** A speed-limit wait holds only the server that got it. A plain FLOOD_WAIT still stops the whole
  account.
  - Fallback: if other servers get speed-limit waits within a minute of each other more than twice in an hour,
    go back to the shared gate for 2 hours.
  - The report counts this, which answers "per server or not" from measurements.
- Neither raises any server's window or slot count.

### Speed: options (your decision)

- **A. Leave it.** The limit lifts some hours: 17:00-18:20 today gave 10-12 GB an hour.
- **B. In 12.4 (recommended to try):** while the speed limit is on, let DC1's window be tried upward, carefully:
  - one part more at a time, up to 4 at most (below the 4.6 it had at 14:00);
  - each step held for 15 minutes and kept only if parts per hour rose by a clear margin;
  - any plain FLOOD_WAIT cuts it back and stops trying for 2 hours.
  This is not the answer-time pacer. The last day had no plain FLOOD_WAIT during limited hours at windows up
  to 4.6 (the 21 came in unlimited hours).
- **Not recommended:** Settings → "download pacing" off goes back to giving every file its own parts (25 files at
  once). It is too [name removed], and it is the flooding the old pacer caused.

## ix.12.4 copies: exact changes (keeping the design)

Held now: 14,122 files in all.
- Held on look-alike evidence never checked: 9,352 (459 GB).
- Lesser copies of queued files: 3,844 (322 GB).
- Matched by sampled frames: about 311 (198 GB).
- **Sampled with no match but still held: 167 (125 GB).**
- Held with no reason row: 474 (35 GB).

1. **No-match goes back to its place.** A held video whose sampled check found at most 0-2 of 8 frames matching
   leaves the hold. Done once at start, with a report line.
   - **90 files, 82 GB:** 52 ranked (38 GB) go back to their group's place; 27 unranked (27 GB) join the
     normal queue (deadline order then applies); 11 unranked (15 GB) are already set aside and stay so.
   - **3-4 of 8 (77 files, 43 GB)** stay at the back, renamed "partly the same footage". They count as
     needed-later, not as probable copies, and "until I release them" does not keep them for ever (the rule
     new partial matches already follow).
   - A failed or timed-out check changes nothing.
   - Cost under today's limit: the 38 GB of ranked files come before the unranked queue, about 30 hours at
     1.2 GB an hour.
2. **Check order.** Today checks go in download order. 1,084 unheld big videos (398 GB) wait for a check ahead
   of 728 held ones never checked (248 GB). Checks just ahead of download are the ones saving bytes now (8 of 11
   matched). **I propose one check in three for held files** (ranked groups first, then the largest), with the
   same number of checks as today. The handoff said "held first". Your call.
3. **Wording:** "matched by sampled frames" everywhere a sampled match says "confirmed". Stored values stay.
4. **Two switches.**
   - "Hold probable copies at the back" (`holdLikely`, as today).
   - "Check big videos by sampling" (new `sampleBig`; when missing it takes `holdLikely`'s value, so nothing
     changes until you change it).
   - With holding off, a sampled match is recorded and shown, but nothing moves.
   - "…until I release them" stays under the first switch. Old keys stay readable.
5. **Finish estimate:** it uses the larger of the queue (2.54 TB, held and set-aside included) and the distinct
   files still to get (2.93 TB), so taking held rows out of the queue figure changes nothing today. Instead, add a line:
   "ahead of held copies and set-aside files: 15,101 files / 1.38 TB, finishes yes/no".

Also in 12.4 (no decision needed):
- the `[memory]` report section (heap, reserved, goroutines, top 10 functions by in-use heap: names and bytes only);
- the profile-photo line printed once;
- the CI split into four jobs (race tests, process E2E, media E2E, browser E2E).
The pacer item waits for your decision on B.
