# Answers to QUESTIONS-for-fork-8 (fork session, 2026-11-14 ~13:00 local)

**Added 11-14 ~13:30, not asked: the frozen account sees no message posted after the freeze.**
- The newest message stored in any chat is from 10-30 23:23. The account was frozen on 10-31.
- 657 messages are dated 10-30 alone, and none on or after 10-31. Yet 10 of the owner's groups had averaged about 195
  posts a day over their last 30 stored days.
- The history reads after the freeze (median 3.9 days ago, 90% within 8.8 days) would have returned newer posts if
  the account could see them.
- So this looks like what the frozen account can see, not a gap in reading. Not proven: other explanations, such as
  every chat going quiet at once, are only less likely.
- **For the new app:** on a frozen account, a rescan for new posts brings nothing. Reading the history once is
  enough. Here, rereading the owner's 194 groups would cost about 8,200 requests for no files.

Read-only. No Telegram request. Numbers only. MB = MiB.

Sources:
- the hourly reports: 142 complete hours from 11-08 14:00 to 11-14 11:00, by `ix-tools/report_q8.py`, which reuses
  `report_q6.py`'s parsing;
- the database opened `mode=ro`, by `ix-tools/live_q13.py` and one inline count;
- the code of 12.30 (`wt-v12.30`).

"Server-hours without the limit" means hours with no speed-limit wait on that server and at least 1,000 MB on it, as
in answers 6.

## A. Plain waits on parts

### 1. The stated length
**Each wait's length is not recorded.** Each hour records, per server, the number of plain waits on parts and the
seconds Telegram asked for in all (`N plain waits asked S`). So below are means, per hour and over all hours, with
upper bounds.

| Server | Hours with waits | Waits | Seconds asked | Mean | Hour means: lowest / median / highest | Most asked in one hour |
|---|---|---|---|---|---|---|
| DC1 | 20 | 96 | 125 | 1.30 s | 1.0 / 1.0 / 1.8 s | 18 s |
| DC2 | 14 | 65 | 86 | 1.32 s | 1.0 / 1.1 / 2.0 s | 35 s |
| DC4 | 18 | 178 | 240 | 1.35 s | 1.0 / 1.1 / 2.0 s | 158 s (116 waits) |
| DC5 | 3 | 3 | 117 | 39 s | 31 / 34 / 52 s | 52 s |

- **By bucket, as far as the means allow:**
  - DC1, DC2 and DC4: every hour's mean is under 3 s. A wait is a whole number of seconds, at least 1, so an hour
    with mean 1.0 had only 1 s waits.
  - DC5: its 3 waits were 31, 34 and 52 s, one in each of 3 hours. All three fall in 10–59 s.
- **No wait of 60 s or more in any report.** The flood guard closes a server's gate on a wait of 60 s or more, or on
  3 waits of 10 s or more within a minute. All 98 reports say "a server's gate closed by its escalating waits, since
  start: none".
- **So for DC1, DC2 and DC4 the old app's waits have the same length as the new app's** (about 1.3 s against about
  1.5 s), and it gets far fewer of them per MB (answers 6, notes 7).
  - That fits "the missing 1 s margin" better than "much longer waits".
  - By the code (`floodguard.go`): the old app sleeps the stated wait plus 1 s before asking again, on the same
    request alone (answers 6, A.2).
- **DC5 is the exception:** rare, but 30–50 s each.

### 2. By route (DC2 and DC4; DC1 has no media address)
- **Recorded per route:** the share of parts, -503 per 1,000 requests, and KB per slot-second.
- **Not recorded per route:** plain waits, timeouts and "cancelled". The failures by kind are kept per server only.
- **DC1's second client** (the home server's `Pool(4)`) is not reported apart: DC1 shows as "main 100%".

Hour medians:

| Server | Media share | Hours | MB | Main: -503 per 1,000 / KB per slot-second | Media: -503 per 1,000 / KB per slot-second |
|---|---|---|---|---|---|
| DC2 | 50% | 20 | 168,459 | 0 / 3,398 | 0 / 3,541 |
| DC2 | 48–59% (other hours) | 5 | 33,452 | 0 / 3,265–4,080 | 0 / 3,421–4,375 |
| DC4 | 50% | 30 | 578,684 | 0 / 3,694 | 0 / 3,699 |
| DC4 | 74% | 2 | 26,704 | 2.5 / 3,458 | 6 / 3,490 |
| DC4 | 51–56% | 2 | 43,619 | 0 / 3,594–3,767 | 0 / 3,543–3,870 |

- **The two routes are nearly the same,** with the media route up to about 4% faster per slot. -503s are rare on
  both.
- The only hours with more -503s are the 2 hours at a 74% media share.
- 12.30 asks for half of the parts on each route on DC2 and DC4. Before 11-10, 85% went to the media route.
- **For the new app ("looks like"):**
  - the media address is worth having, with no measured downside on DC2 and DC4;
  - a 50/50 split is the measured setting, but nothing shows it beats other shares;
  - DC1 and DC5 have none.

## B. Connections

### 3. The "cancelled" part requests
- **By the code,** `pacer_fails.go` `failKind` sorts a part's failure in this order:
  - a speed-limit wait;
  - a plain wait;
  - `context.Canceled` → "cancelled";
  - `context.DeadlineExceeded` → "no answer in time";
  - -503;
  - "connection lost";
  - and so on.

  So:
  - **the 2-minute deadline is not in "cancelled":** it is "no answer in time", and shown apart;
  - **a connection that died after Telegram's acknowledgement** ("engine forcibly closed: context canceled") **and a
    request whose file's context ended** (a -503 run ending, the file set aside, paused, yielding, an update's drain)
    **both land in "cancelled".** The report cannot split them.
- **Numbers, the same server-hours, summed:**

  | Server | Hours | Cancelled (s) | No answer in time | -503 | Hours with a cancelled request / of them with -503s that hour | Cancelled in hours with no -503 | -503 runs ended "cancelled" (routes line) |
  |---|---|---|---|---|---|---|---|
  | DC5 | 29 | 542 (1,893 s) | 1 | 20,667 | 29 / 29 | 0 | 820 |
  | DC1 | 33 | 125 (394 s) | 5 | 5,237 | 29 / 27 | 2 | 254 |
  | DC4 | 34 | 15 (38 s) | 2 | 374 | 3 / 1 | 4 | 3 |
  | DC2 | 25 | 0 | 2 | 695 | 0 | 0 | 13 |

- **What this shows ("looks like", not proven):**
  - DC5's cancelled requests come only in hours of its -503 storms: 29 of 29 hours. They take about 3.5 s each, and
    the -503 runs that ended by cancelling outnumber them.
  - So they look like the parts of files whose -503 runs ended, not connection deaths.
  - **Cancelled requests in hours with no -503 at all,** the likeliest connection deaths: 2 on DC1, 4 on DC4, 0 on
    DC5 and DC2, in 25–34 hours each.
  - In hours with -503s the two kinds cannot be told apart, so the strict upper bound on deaths after
    acknowledgement stays the full counts above (DC5 542, DC1 125, DC4 15, DC2 0).
  - Either way it is far from the new app's 759 in 52 minutes.
- **Error text:** not kept per part request.
  - A file keeps only its last error (`tgdl_work.error`), and only while it fails or waits to retry: 2,448 rows hold
    one now.
  - None of them contains "forcibly closed", "context canceled" or "connection". 11 say "deadline exceeded" and 23
    a -503.
  - The report's "recent errors" list keeps a few recent texts with counts (on 11-14: -503s and "context deadline
    exceeded" only).

## C. The sampled-frame check

### 4. How often it is right
- **Recorded:** 27,051 checked queue items, 11-04 00:16 to 11-14 12:06. One row per item holds its last outcome.
- **"Downloaded in full"** means a saved file of that message with a content hash. "The file it was compared with"
  is the saved file the check sampled against, or failing that the one the hold named.
- **How each was judged after download:**
  - same bytes: equal SHA-256;
  - same content, different bytes: the archive's own video duplicate check over saved files paired them (`ix_vdup`:
    kind "same" or "overlap");
  - different content: both files are fingerprinted (`ix_vfp`) and no pair was found.
- No file was opened.

| Called by the check | Items | Skipped by Telegram's hashes (same bytes) | Downloaded in full | Same bytes | Same content, different bytes ("same" / "overlap") | Different content | Not judged (a file not fingerprinted, or nothing to compare) |
|---|---|---|---|---|---|---|---|
| A copy | 6,950 | 10 | 188 | 118 | 66 (50 / 16) | 2 | 2 |
| Partly the same | 373 | 46 | 111 | 18 | 68 (37 / 31) | 0 | 25 |
| No match, after a look-alike hold | 739 | 24 | 212 | 6 | 29 (19 / 10) | 44 | 133 |
| Distinct (never held) | 18,925 | 11 | 16,869 | 1 | 882 (477 / 405) | 257 | 15,729 |
| Check failed | 66 | 2 | 42 | 1 | 0 | 0 | 41 |

- **When it says "copy", it looks right:**
  - of the 188 downloaded anyway: 184 confirmed, 118 as the same bytes and 66 as the same content, and 2 different;
  - 10 more were the same bytes by Telegram's hashes;
  - the other 6,739 are still held, not downloaded.
- **"Partly the same" was never different content** in the 86 downloads that could be judged: 18 same bytes, 68
  same or overlapping content. Another 46 were the same bytes by Telegram's hashes.
- **When it says "no match", it misses copies:**
  - Look-alike holds it released: of 79 that could be judged after download, 35 were the same bytes or content, and
    44 different. 24 more were exact copies by Telegram's hashes (answers 5 found 23 such).
  - Videos it called distinct and compared with a specific saved file: of 1,140 judged after download, 882 were
    paired with that file by the post-download check (477 "same", 405 "overlap"), 1 was the same bytes, and 257
    were different. 11 more were exact copies by Telegram's hashes.
  - **So on these numbers, about 3 in 4 of its "no match" verdicts against a named candidate were wrong**, if the
    post-download check is right.
  - Two checkers disagree here, and nothing here says which is right. "Overlap" can mean a clip or a partial match,
    not a full copy. The 477 "same" are the stronger signal.
  - Most of these checks ran in the download (videos of 20 MB or more), on parts read once.
- **Also, called distinct and later found the same bytes as some other saved file:** 14 (not the one compared with).
- **For the new app ("looks like"):**
  - the frame check's positive answers can be trusted;
  - its negative answers cannot, and should not release or pass a file on their own;
  - re-check by Telegram's hashes when the byte size equals the candidate's (answers 5), and by a fuller frame
    sample before calling a pair distinct;
  - measure the miss rate on the test account, against downloads, from the start.

## D. Copies to the NAS

### 5. Copies at once
- **Two settings were run:**
  - 6 copies at once until 11-10 about 00:00;
  - 8 since.

  Each report's staging line gives the last hour's files, MB and MB/s per copy. "MB/s in all" below is that hour's
  MB / 3,600 s, so it is low when the mover ran for only part of the hour. Only hours that copied at least 1,000 MB
  are counted.

  | Copies at once | Report hours | MB/s in all, median / highest | MB/s per copy, median | Average file (median of hours) | Copying at once while the mover ran (median) |
  |---|---|---|---|---|---|
  | 6 | 6 (11-09 19:00 to 11-10 00:00) | 8.6 / 9.3 | 1.6 | 13.7 MB | not in those reports |
  | 8 | 35 (11-10 01:00 to 11-14 17:00) | 9.6 / **14.0** | 1.5 | 21.2 MB | 8.0 |

- **The highest hour on record:** 50,532 MB copied, 14.0 MB/s in all. That was 8 copies at once, 1.9 MB/s each,
  20 MB per file. It equals the Wi-Fi ceiling noted on 11-09 (about 14 MB/s).
- **Big files copy faster per copy:**
  - hours whose average file was 300–430 MB moved 3.6–4.3 MB/s per copy, against 1.5–1.9 for files of about 20 MB;
  - in those hours few files were waiting, so the totals were low (0.4–1.1 MB/s in all).
- On 11-08, under the 6-copy setting, about 3.3 copies ran on average (`START-HERE.md`). No other number of copies
  was run.
- **For the new app ("looks like"):**
  - the link reached its ceiling with 8 small-file copies in a busy hour, so more copies would not add much;
  - per-file overhead (notes 7: 42% of the copy time on fixed steps) is what holds small files back;
  - one big-file lane beside the small-file copies would keep the link full: a big file copies at about 4 MB/s alone.
  - Not measured: 2 lanes, or more than 8 copies.
