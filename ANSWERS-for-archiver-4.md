# Answers to QUESTIONS-for-fork-4 (fork session, 2026-11-13 ~22:30 local)

Read-only. Sources:
- the hourly reports in `data\ixreports` (the 49 files and `latest.txt`, plus the 49 older ones in `ixreports.zip`):
  hourly lines cover 11-08 14:00 to 11-13 22:00 local without a gap (129 hours); the newest is 12.30's, 22:08 local;
- the database opened `mode=ro` (scripts `ix-tools/live_q11.py`, `ix-tools/report_hours_q4.py`);
- the 12.30 source (`wt-v12.30`, tag `v3.4.18-ix.12.30` = `e18f80a`).

No Telegram request was made. Numbers only. "Not recorded" means no counter, table or report line holds it. Days are
local (EST); the dedup table's days are the archive's local days.

**The short version for the new app's bounds:**
- The preview hash is equal: all 4 invented previews give exactly the expected values (E.13).
- The exact check (byte for byte) found 5,007 files the same since 11-04, **all by Telegram's hashes**. Its own
  fallback, comparing the raw bytes of three 1 MiB parts when Telegram has no hashes, never decided a match.
  - That fallback is **not** the sampled-frame check (sections B and C). The frame check finds look-alike copies and
    has done most of the work: 5,564 held videos confirmed (corrected in answers 5), 577 GB held now as confirmed
    copies.
- Telegram had no hashes, or the hash request failed, in 18 of about 9,000 checks.
- No exact match has ever been undone: `ix_subst_block` has 0 rows. Nothing ever re-checks a match, though.
- Hash requests use the download pool's connections of the file's server, at most one per downloading file: 7 per
  server at 12.30's slots. Waits on them are not counted per method.
- No part request failed with a lost connection in 129 hours.

---

## A. `upload.getFileHashes` (the exact check)

**Two checks with similar words; section A is only about the first:**
- **The exact check (`ix_subst.go`), before a download:** is the queued file byte for byte the same as a saved file
  of exactly its size? First it asks Telegram's part hashes. For video from 2 MiB only, when Telegram has no hashes,
  its fallback downloads three 1 MiB parts and compares their raw bytes with the saved file. In this section,
  **"sampled parts" means that byte fallback only.**
- **The sampled-frame check (`ix_copies_sample.go`, `ix_dl_check.go`):** does a big video *look* like a saved one?
  It catches re-encoded, trimmed or resized copies, which the exact check cannot. A match is a probable copy, held at
  the back. It is covered in sections B and C.

### 1. Windows per answer and their size
**Not recorded.**
- The old app neither logs nor stores how many `FileHash` entries an answer carried, nor their `limit`.
- From the code (`ix_subst.go`):
  - it asks at offsets rounded down to 131,072 bytes;
  - it keeps each entry that has a 32-byte hash, a positive limit and an offset inside the file;
  - for the full check it steps on from the last window's end, at most 64 requests a file.
  - For video from 2 MiB it asks only at the start, the middle and the last byte, then compares every window
    returned.
- The count of requests a check made is not stored either.

### 2. Per day, from the dedup counters (`ix_dedup_daily`)
In the table below:
- **checks**: files compared on Telegram;
- **no hashes**: `check-nohash`. It also counts a hash request that failed: any error, a wait over 60 s, or a wait
  still refused after 3 tries. Telegram keeping no hashes cannot be told apart from a failed request;
- **failed**: `check-failed`, the byte fallback's parts could not be read;
- **same**: not downloaded, with the MB they would have cost;
- **MB sampled**: bytes the byte fallback downloaded. This is not the frame check's parts, which are in section C.

| Day | Checks | No hashes | Failed | Same (files / MB) | MB sampled |
|---|---|---|---|---|---|
| 11-04 | 717 | 0 | 0 | 269 / 1,277 | 0 |
| 11-05 | 161 | 0 | 0 | 112 / 11,305 | 0 |
| 11-06 | 829 | 0 | 0 | 510 / 21,643 | 0 |
| 11-07 | 982 | 0 | 0 | 540 / 39,354 | 0 |
| 11-08 | 604 | 0 | 0 | 364 / 25,907 | 0 |
| 11-09 | 1,634 | 8 | 1 | 914 / 45,275 | 5 |
| 11-10 | 524 | 0 | 0 | 288 / 16,134 | 0 |
| 11-11 | 1,680 | 9 | 0 | 944 / 31,377 | 0 |
| 11-12 | 1,519 | 1 | 1 | 838 / 34,311 | 0 |
| 11-13 (to 22:08) | 396 | 0 | 0 | 228 / 13,380 | 0 |
| **All** | **9,046** | **18** | **2** | **5,007 / 239,963** | **5** |

- **Split by how it was decided** (`ix_subst.how`, one row per file not downloaded; its total equals the table's
  5,007):
  - "telegram-hashes": **5,007 files / 239,968 MB**;
  - **"sampled-parts": 0**.
- So since counting began on 11-04, every exact "same" came from Telegram's hashes.
  - The byte fallback (three 1 MiB parts compared byte for byte) was needed only where Telegram had no hashes: at
    most the 18 checks above. It never decided a match. Its only cost was 5 MB on 11-09.
  - This says nothing about the sampled-frame check, which is a different check (section C).
- The report's 7-day line agrees: "re-upload checks on Telegram 7,339 (no part hashes 18, parts unreadable 2, 5 MB
  sampled)".

### 3. Checks with more than one saved candidate of the same size
**Not recorded per check.**

What the catalogue holds now (database, read at 22:30), as a stand-in:
- **Queued files of 256 KiB or more** (the ones the check would see): 50,245. By the number of saved files of
  exactly their byte size:

  | Saved files of that size | 0 | 1 | 2 | 3 | 4 | 5 or more |
  |---|---|---|---|---|---|---|
  | Queued files | 19,531 | 27,015 | 2,382 | 743 | 239 | 335 |

  - Of the 30,714 with any candidate, **3,699 (12.0%) have more than one**.
  - The code takes at most 5 candidates.
  - This counts catalogue rows by `file_size` only. The check also matches `telegram_media_size`, and for photos it
    also needs the same pixel size and preview. So read it as an upper bound for photos.
- **Saved files of 256 KiB or more**: 117,389 sizes belong to a single file. 3,772 sizes are shared by 2 files, 629 by
  3, 155 by 4 and 117 by 5 or more.
- **A second candidate costs no new request** when the hashes are already held. The check keeps Telegram's answers
  for the file and compares the next candidate against them. It stops at the first candidate where Telegram cannot
  tell.

### 4. FLOOD_WAIT or timeout on `upload.getFileHashes`
**Not recorded per method or per hour.**
- **How the code handles it:**
  - a hash request is not a file part, so it goes through the flood guard's account path;
  - a wait of up to 60 s is slept, up to 3 tries, and it closes the account's gate for every request that is not a
    file part. That includes message refreshes and history reads; file parts do not wait on that gate under
    per-request waits;
  - the account's request-rate limiter (60 a second, burst 60) also applies;
  - there is no per-request timeout: only the download's own deadline;
  - a lost connection is retried up to 6 times.
- **Counters:**
  - the hourly "waits" and per-server wait counts in the report cover **file parts only**;
  - the guard's total wait counter mixes every method and is not in the report per method;
  - the only upper bound is the 18 "no hashes" checks above. Each is a check in which a hash request ended in an error
    or an empty answer, for any reason.
- The report has never shown a file part held at the account's gate ("held per server" causes over 129 hours: "all
  servers" and "plain waits slept alone" only). That cannot show hash waits, because parts skip that gate.

### 5. A "same" later found to differ
**0 found, but never looked for.**
- `ix_subst_block` ("Fetch the real files") has **0 rows**.
- Nothing in the old app compares a substituted file again later.
- The report's "after download, same bytes" (2,514 in 7 days) is a different check: copies found after downloading,
  and it is not about the exact check.

## B. The look-alike hold

### 6. Held now as probable copies, by kind of evidence
Pending queue items not released, by `ix_copy_hold.how` (GB = 10⁹ bytes):

| How | Files | GB | Of which confirmed by frames (files / GB) |
|---|---|---|---|
| saved | 39,798 | 1,989.9 | 1,203 / 633.3 |
| sampled | 4,204 | 576.7 | 4,204 / 576.7 (all confirmed) |
| queued | 1,544 | 150.1 | 103 / 44.2 |
| unlinked-copy (12.9 repair) | 2,466 | 15.5 | 12 / 6.7 |
| sampled-partial | 15 | 4.6 | 0 (all "unconfirmed") |
| recognition | 0 | 0 | |
| album | 0 | 0 | (the album hold is off) |
| **All** | **48,027** | **2,736.8** | |

The report says 48,028 held at 22:08.

### 7. Holds later checked by sampled frames

> **Corrected in ANSWERS-for-archiver-5.md.** The figures below wrongly include 67,186 "looked at, not held" marker
> rows (`ix_held.released_at = -1`). Real holds with a frame check: confirmed 5,564 (4,204 of them held by the frame
> check itself), **released 678**, partial 369, failed 7. Look-alike holds judged by frames: 1,360 confirmed against
> 675 released.

- **Items ever held that have a frame check** (`ix_copy_sample`, one row per queue item, its last outcome):
  - **confirmed 5,617**;
  - **released, no match 12,926**;
  - **partial 368**: no match on the whole, but partly the same, so `how` became "sampled-partial";
  - failed 52.
- **Frame checks of items never held** (checks in the download that found nothing): no match 1,947, confirmed 18,
  failed 6.
- 15 of the 368 partial items are still held. The rest were released.

## C. The sampled-frame check and kept parts

### 8. Frame checks per day
- `ix_copy_sample` keeps **one row per queue item, dated by its last check**. So a day's counts are items whose last
  check fell on that day.
- It does not say whether a check ran in the download or in the background.
- Partial is a "nomatch" whose hold became "sampled-partial".
- Parts are 1 MiB parts read, summed over the item's tries.

| Day | Checks | Confirmed | No match | Partial | Failed | Parts: median / largest |
|---|---|---|---|---|---|---|
| 11-04 | 333 | 106 | 205 | 14 | 8 | 16 / 66 |
| 11-05 | 340 | 226 | 44 | 68 | 2 | 11 / 28 |
| 11-06 | 239 | 88 | 127 | 21 | 3 | 7 / 14 |
| 11-07 | 2,640 | 401 | 2,207 | 28 | 4 | 8 / 32 |
| 11-08 | 3,748 | 740 | 2,966 | 36 | 6 | 8 / 32 |
| 11-09 | 4,187 | 1,084 | 3,024 | 73 | 6 | 8 / 32 |
| 11-10 | 1,366 | 420 | 906 | 38 | 2 | 8 / 39 |
| 11-11 | 2,967 | 946 | 1,970 | 36 | 15 | 8 / 86 |
| 11-12 | 3,265 | 1,007 | 2,210 | 45 | 3 | 8 / 32 |
| 11-13 (to 22:30) | 1,849 | 617 | 1,214 | 9 | 9 | 8 / 196 |

**Failed, by reason** ("final" means a reason in the file itself, not tried again):
- parts-cap 22 (final);
- timeout 15;
- bad-data 5 (final);
- ffmpeg 5;
- message 5 (final);
- telegram 5;
- unrecorded 1.

By day:

| Day | Failed checks by reason |
|---|---|
| 11-04 | ffmpeg 3, timeout 4, unrecorded 1 |
| 11-05 | timeout 2 |
| 11-06 | message 3 |
| 11-07 | bad-data 1, parts-cap 2, telegram 1 |
| 11-08 | bad-data 1, parts-cap 4, telegram 1 |
| 11-09 | bad-data 1, parts-cap 5 |
| 11-10 | timeout 2 |
| 11-11 | bad-data 1, message 1, parts-cap 9, telegram 1, timeout 3 |
| 11-12 | bad-data 1, parts-cap 1, timeout 1 |
| 11-13 | ffmpeg 2, message 1, parts-cap 1, telegram 2, timeout 3 |

**Seconds per check: not recorded per check.** (`dur_ms` in that table is the video's length.) The only figure is
the report's "seconds a check added to its download" for checks run in the download, averaged per run. The table
below shows the last report of each run. These runs mix hours with and without the speed limit, so this is "looks
like", not a measurement:

| Run | Checks in the download | Copies / partial / no match / failed | MB of parts | Seconds added per check |
|---|---|---|---|---|
| 12.21 (11-09, mostly unlimited) | 2,583 | 604 / 22 / 1,949 / not shown | 22,166 | **9.7** |
| 12.23 (11-10) | 1,139 | 282 / 15 / 840 / not shown | 9,460 | **18.2** |
| 12.28 (11-11, 10 unlimited hours) | 2,814 | 846 / 1 / 1,914 / 43 | 23,092 | **21.2** |
| 12.29 (11-12) | 2,478 | 645 / 9 / 1,801 / 23 | 19,888 | **21.7** |
| 12.29 (11-13, restarted) | 1,604 | 471 / 1 / 1,107 / 24 | 12,811 | **20.5** |
| 12.22, 12.24–12.27 (speed limit nearly throughout) | 1 to 47 each | | | **180–835** |
| 12.30 (since 14:42, speed limit throughout) | 19 | 1 / 0 / 9 / 9 (all 9 timed out at the 10-minute bound) | 89 | **610.9** |

- **So: about 10–22 s per check in runs that had unlimited hours, and 3–14 minutes under the speed limit.** Under
  the limit about half time out.
- That is why 12.26 puts a big video back when its check gets no answer under the limit. Put back now: `timeout` 3
  items, 21 times; `telegram` 1 item, once.

### 9. Kept parts
- **Kept now:** 37,179 parts, **35,407 MB**, of 3,986 files (database). The report says 35,397 MB, cap 100 GB, kept
  only above 60 GB free.
- **Reused by downloads:** the report's counter starts again at each restart. Summing the last figure of every run in
  the reports (from 11-09 11:31 local, 12.21 on) gives **at least 63.4 GB reused in 7,916 downloads**. It is "at
  least" because each run's final hour after its last report is missing, as is everything before 11-09 11:31.

  | Run | MB reused / downloads |
  |---|---|
  | 12.21 | 15,827 / 1,986 |
  | 12.28 | 16,608 / 2,011 |
  | 12.29 (first run) | 14,585 / 1,844 |
  | 12.29 (second run) | 9,148 / 1,148 |
  | 12.23 | 6,710 / 867 |
  | the other runs together | 515 / 60 |
- **Refused on reuse: 0 wrong length, 0 wrong bytes, 0 unreadable, in every report since 11-09.**
- This run (12.30): 124 MB in 14 downloads; 452 MB newly kept; 24 files' parts removed; 0 failed writes.

### 10. MP4 or MOV among saved videos
Saved downloads with a `video/*` MIME type (or typed video) total 127,698. MP4 and MOV together are **127,247
(99.6%)**, and **3,649.5 of the 3,680 GB (99.2%)**. By MIME:

| MIME | Files | GB |
|---|---|---|
| video/mp4 | 122,363 | 3,544.5 |
| video/quicktime | 4,884 | 105.0 |
| video/x-matroska | 185 | 11.5 |
| video/x-msvideo | 94 | 6.7 |
| video/x-m4v | 76 | 8.2 (also an MP4 container: 99.7% with it) |
| video/vnd.avi | 25 | 1.3 |
| video/avi | 25 | 1.1 |
| video/x-ms-wmv | 15 | 0.6 |
| video/x-flv | 15 | 0.5 |
| video/mpeg | 11 | 0.6 |
| video/webm | 3 | 0.1 |
| video/x-ms-asf | 2 | 0.0 |

## D. Waits, for the new app's first real download run

### 11. Waits on parts per server and hour, 11-11 00:00 to 11-13 22:00 (71 hours)
- **Smallest, median and largest wait: not recorded.** The report gives per server per hour only the count and the
  total seconds asked ("N plain waits asked S"), so only the hourly mean is known.
- Plain waits, every hour that had any:

| Day | Server | Plain waits | Seconds asked | Hours with any, as hour: count / seconds |
|---|---|---|---|---|
| 11-11 | DC1 | 15 | 21 | 18:00 7/12, 20:00 5/6, 21:00 3/3 |
| 11-11 | DC2 | 6 | 7 | 18:00 2/3, 21:00 1/1, 23:00 3/3 |
| 11-11 | DC4 | 14 | 15 | 17:00 3/3, 18:00 1/1, 20:00 3/3, 22:00 7/8 |
| 11-11 | DC5 | 3 | 92 | 05:00 1/48, 17:00 1/15, 23:00 1/29 |
| 11-12 | DC1 | 22 | 55 | 00:00 12/18, 01:00 3/5, 03:00 6/11, 04:00 1/21 |
| 11-12 | DC2 | 4 | 4 | 00:00 4/4 |
| 11-12 | DC4 | 12 | 17 | 00:00 9/13, 02:00 1/1, 03:00 2/3 |
| 11-12 | DC5 | 1 | 52 | 03:00 1/52 |
| 11-13 | DC1 | 8 | 8 | 03:00 1/1, 04:00 5/5, 05:00 2/2 |
| 11-13 | DC2 | 0 | 0 | none |
| 11-13 | DC4 | **116** | 158 | **04:00 116/158** (one unlimited hour) |
| 11-13 | DC5 | 1 | 31 | 04:00 1/31 |

- Speed-limit waits per server per day:

  | Day | DC1 | DC2 | DC4 | DC5 |
  |---|---|---|---|---|
  | 11-11 | 4,873 | 4,558 | 4,520 | 4,541 |
  | 11-12 | 4,771 | 95 (it had no files) | 4,484 | 4,680 |
  | 11-13 | 6,416 | 4,112 | 6,120 | 6,263 |
- **Over all 129 hours, 11-08 14:00 to 11-13 22:00:**

  | Server | Plain waits | Seconds asked | Hours with any | Hourly mean asked: smallest / median / largest | Speed-limit waits |
  |---|---|---|---|---|---|
  | DC1 | 101 | 165 | 22 | 1.0 / 1.2 / 21 s | 31,409 |
  | DC2 | 73 | 101 | 13 | 1.0 / 1.4 / 2.0 s | 17,798 |
  | DC4 | 179 | 234 | 18 | 1.0 / 1.0 / 2.0 s | 30,193 |
  | DC5 | 6 | 209 | 6 | 15 / 34 / 52 s | 32,397 |

- So on DC1, DC2 and DC4, plain waits are almost all 1–2 s, and they come in unlimited hours. DC5's are rare and
  long.
- Speed-limit waits are about 14–16 s each ("s asked on average" in the hourly lines: 13.2–15.8 s in the last hours).
- The full hour-by-hour table: run `python -I ix-tools/report_hours_q4.py` (numbers only).

### 12. Waits on reading messages for file references
**Not recorded.**
- The only counter is the message refreshes before a download:
  - 12.30 since 14:42: 113, all with a changed reference;
  - last hour: 14;
  - 11-13 morning (12.29): 3,317 in 9.6 h.
- Their waits fall in the account's gate, which is not counted per method (see A.4).
- The account flag "flood wait" in the report's recent errors is false now. That is a current state, not a count.

## E. The preview hash

### 13. `ixPreviewHash` on the four invented previews
A throwaway test in `wt-v12.30/core-service/internal/app`, at tag `v3.4.18-ix.12.30` = `e18f80a`, the source of the
installed 12.30:
- it was run alone (`-run '^TestZZThrowawayPreviewHash$'`, `-p 1`, `GOGC=25`);
- it took 0.17 s;
- it was then deleted: never committed, and the worktree is clean.

| Preview | Old app's value | Has a hash | Expected | Equal |
|---|---|---|---|---|
| pic1-40x40-q20 | `0xb56a912d5aa54af1` | yes | `0xb56a912d5aa54af1` | **yes** |
| pic2-40x40-q20 | `0xf1080cf5a55197b7` | yes | `0xf1080cf5a55197b7` | **yes** |
| pic3-40x40-q20 | `0x47a55a952b2a956b` | yes | `0x47a55a952b2a956b` | **yes** |
| pic4-40x40-q50 | `0xb61346c8b976ca39` | yes | `0xb61346c8b976ca39` | **yes** |

- **One gap:** this was compiled here with Go 1.27.3. The release was built by CI from `go.mod`, whose toolchain is
  go1.27.2. The JPEG decoder rarely changes in a patch release, but the installed binary itself was not run.
- Question 14 was not needed.

## F. After the review of the new app's exact check

### 15. Hash waits together with part waits on the same server?
**Not recorded.**
- A wait on `upload.getFileHashes` is not counted per method or per server. It closes the account's gate, not the
  server's.
- The report's per-server waits cover file parts only.

### 16. Hash requests in flight at once on one server, and through which connections
**By the code** (not counted):
- **How many at once:**
  - the exact check runs inside a file's download attempt, after the file has taken its slot and before the transfer;
  - one check asks one hash request at a time;
  - so at most **one hash request per downloading file on that server: 7 at 12.30's slots** (5 under 20 MB plus 2
    large);
  - the lower-quality-first check also calls it, within the same attempt, and its "same" answer is reused for
    10 minutes.
- **Which connections:**
  - the **download pool of that server**, the same shared pool as the file parts: up to 12 connections, one request
    each at a time;
  - main addresses only, never the media route;
  - **not** inside the per-server part window (the pacer), but through the account's gate and its request-rate
    limiter (60 a second).
- So hash requests compete with parts for the pool's connections, but not for the part window.

### 17. Download connections lost while requests were in flight

> **Corrected in ANSWERS-for-archiver-6.md (B.5).** "0 connection lost" does not mean no connection died:
> - a death before Telegram acknowledged a request is retried silently by the library and counted nowhere;
> - a death after the acknowledgement is counted under "cancelled", not "connection lost".
>
> Upper bound, unlimited hours: DC4 12 in 23 hours, DC1 88 in 22 hours.

- **Part requests:** the report records per server per hour the failures of kind "connection lost". There were
  **0 in all 129 hours**, 11-08 14:00 to 11-13 22:00: 0 a day on every server.
  - This counts each part request that came back with a lost connection, including the ones later retried.
- **Other requests:** connections re-made, and lost connections on requests other than parts (hashes, message
  reads), are not recorded.
