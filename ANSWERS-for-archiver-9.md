# Answers to QUESTIONS-for-fork-9 (fork session, 2026-11-14 ~17:30 local)

Read-only. No Telegram request. Numbers only. MB = MiB. Includes question 10, added at 16:32.

Sources:
- the hourly reports: 142 complete hours, 11-08 14:00 to 11-14 15:00, by `ix-tools/report_q9.py` (it reuses
  `report_q6.py`'s parsing);
- the database opened `mode=ro`, by the same script;
- the code of 12.30 (`wt-v12.30`) and the library at v0.163.0, with v0.166.0 beside it where they differ.

**The short answer: on the old account, plain waits do not go with files started.** The one hour that was nearly
all photos had 5,007 files on one server, 83 a minute (126 in its busiest minute), and **no plain wait.** Your
run had about 200 waits per 1,000 files. The old app's worst server averaged 10 per 1,000. The old app sends one
message re-read per file before its first part (B.3), and it has only ever run on the old account (C.7). So the
gap may be the account, the server, or that per-file pattern. These numbers cannot say which.

## How the numbers were made

- **Server-hours** means a complete hour, no speed-limit wait on that server, and at least 20 files finished on it.
  There are 128 such hours: DC1 37, DC2 25, DC4 36, DC5 30.
- **Files:** finished files per server and hour, with the report's own filter (completed, a server known, not
  skipped as a copy).
  - **Files started are not recorded.** Finish hour stands in for start hour.
- **Part requests:** estimated as the sum over finished files of ceil(size / 1 MiB), so a file of 1 MiB or less
  counts as one request.
  - **The count of part requests per server is not recorded.** The estimate leaves out retries, failed requests,
    waited re-asks and parts that were already kept.
  - The estimate lands within about 3% of each server's MB, so it is close for answered parts.
- **Plain waits:** each hour's plain waits on file parts per server (`N plain waits asked S`), as in answers 6 and 8.

## A. Waits against files

### 1. Per file, per part request, per MB

| Server | Hours | Plain waits | Files | Part requests | MB | Waits per 1,000 files | Per 1,000 part requests | MB per wait | Files of 1 MiB or less | Photos |
|---|---|---|---|---|---|---|---|---|---|---|
| DC1 | 37 | 103 | 67,351 | 1,197,791 | 1,171,142 | 1.5 | 0.09 | 11,370 | 49% | 44% |
| DC2 | 25 | 65 | 6,306 | 203,683 | 201,911 | 10.3 | 0.32 | 3,106 | 38% | 33% |
| DC4 | 36 | 178 | 36,538 | 668,103 | 652,756 | 4.9 | 0.27 | 3,667 | 50% | 44% |
| DC5 | 30 | 3 | 7,957 | 239,574 | 233,402 | 0.4 | 0.01 | 77,801 | 40% | 35% |

**The same hours, grouped by how many of the hour's files were small (1 MiB or less):**

| Small files in the hour | Server-hours | Plain waits | Files | Part requests | Waits per 1,000 files | Per 1,000 part requests | Per 10 GB | Hours with no wait |
|---|---|---|---|---|---|---|---|---|
| under half | 88 | 267 | 52,474 | 1,451,433 | 5.1 | 0.18 | 1.9 | 51 |
| half to 80% | 39 | 82 | 60,671 | 849,039 | 1.35 | 0.10 | 1.0 | 20 |
| 80% or more | 1 | 0 | 5,007 | 8,679 | 0 | 0 | 0 | 1 |

- **Hours with more small files had fewer waits, by every measure,** not more ("looks like": one server-hour in the
  last group, and few waits in all).
- On the old account the rate does not follow "per file started". It is closer to "per part request" or "per MB",
  and even those vary by about 10 times between servers.
- **The small-file hour:** DC4, 11-14 04:00. 5,007 files, 86% photos and 87% of 1 MiB or less, 8,679 part
  requests, 4,501 MB. 83 files a minute on average and 126 in its busiest minute. **0 plain waits.** Parts in
  flight on DC4 averaged 0.6. The next hour on DC4 had 3,076 files, 65% photos, and 6 plain waits.
- **Against your run** (from your notes): 93 waits for 460 files is about 200 per 1,000 files, at about 100 files a
  minute. That is about 20 times the old app's worst server (DC2) and 40 times DC4. **The old app's DC4 took a
  similar file rate with no waits.**
- Not the same server: your run is on DC2. The old account's DC2 never had a busy photo hour: at most 10 files a
  minute over an hour and 72 in one minute (B.3). Its 5 hours with half or more small files are in C.8.

### 4. Where in a file the plain waits fall
**Not recorded.** A plain wait is counted per server and hour, with the seconds asked. Its offset, file and part
number are not kept. Only speed-limit waits keep a file ID, and only to tell a repeat on the same file.

## B. How the old app asks

### 2. Photos
- **The same pool, route, limits and part size as a video.** Through the shared per-server pool (12 connections),
  the main/media route split on DC2 and DC4, the per-server part window, the per-server file slot, the flood guard
  and the account's 60-a-second limiter (`attachment.go` `invokePart`). Not the main connection, and no separate
  limit.
- **The size asked for:** the photo's size with the most bytes among its `photoSize` and `photoSizeProgressive`
  entries (the largest of a progressive one's sizes). Its letter goes in `InputPhotoFileLocation.thumb_size`
  (`attachment.go` `MessageAttachment`). **Which letters that was is not recorded.** The server is the photo's own
  `dc_id`.
- **A photo of 1 MiB or less (nearly all) is one request:**
  - not the old app's own parallel reader, but the library's downloader (`downloader.NewDownloader()
    .WithPartSize(1 MiB).Download(...).Stream`);
  - offset 0, limit 1 MiB, `precise` set, `cdn_supported` not set;
  - the answer is shorter than 1 MiB, so the reader stops after it.
- **A photo over 1 MiB** goes through the old app's own reader, like a video (B.6).
- **The edge case:** a file of exactly 1 MiB would take a second request, answered empty.

### 3. How fast it starts files on one server
**Files finished per minute,** server-hours with at least 200 files (finish times, as starts are not recorded):

| Server | Hours | Files a minute over the hour: lowest / median / highest | Busiest minute in an hour: median / highest | Gap between two finishes: median / 10th percentile / share under 100 ms |
|---|---|---|---|---|
| DC1 | 34 | 5.5 / 30.5 / 74.5 | 93 / 230 | 440 ms / 14 ms / 25% |
| DC2 | 14 | 3.6 / 5.5 / 10.1 | 21 / 72 | 939 ms / 88 ms / 10% |
| DC4 | 31 | 4.2 / 16.9 / 83.5 | 69 / 137 | 457 ms / 21 ms / 22% |
| DC5 | 15 | 3.4 / 6.3 / 15.1 | 23 / 62 | 864 ms / 49 ms / 13% |

**By the code, before a file's first part:**
1. **A message re-read** (`channels.getMessages` or `messages.getMessages`), on the main connection, not the
   download pool (`engine/controller.go` about line 1272).
   - It is done when the item is a retry, is flagged for a refresh, or **was queued more than a minute ago and its
     file is not already saved.** That is nearly every queued download.
   - So the old account sends one message read per file it downloads, a round trip before the file's slot is
     taken.
   - It goes through the same 60-a-second limiter. **Not counted per hour.**
2. **A file slot on that server:**
   - small (under 20 MB) and large slots, from Telegram's app config (`small_queue_max_active_operations_count`
     and `large_..._count`, read by `help.getAppConfig`);
   - the reports show **5 small and 2 large;** the code's defaults, when the config cannot be read, are 4 and 2
     (`download_files.go`);
   - a file waits for a free slot, best-ranked first.
3. **Room in the server's part window** (the pacer), per part.
4. **The flood guard's gates:** a server or account gate closed by an earlier wait. Then the account's limiter:
   **60 requests a second, burst 60**, shared by every request of the account.

- **No pause, delay or spacing between files.**
- **The shortest time between first requests of two different files on one server: no floor.**
  - The re-read happens before the slot is taken, so a waiting file starts as soon as a slot frees.
  - Two files in two slots can send their first parts back to back, within the limiter's burst.
- **In practice:** the 10th percentile of the time between two finishes is 14 to 88 ms. In the busiest minutes, 2
  to 4 files a second finished on one server.

### 5. Requests per connection
- **The library's pool (`pool/pool.go`, the same in v0.163.0 and v0.166.0) hands out the most recently freed
  connection.**
  - Free connections sit in a list. `acquire` takes the last one, and `release` puts it back at the end.
  - A new connection opens only when none is free and fewer than the maximum are open. At the maximum, the request
    waits.
  - So **with 2 parts in flight, about 2 connections carry nearly everything.** The others are opened only when
    more are in flight at once.
- **The old app's case:**
  - more in flight per server: 2.5 to 3.4 parts on average in DC1's busiest hours, and up to the window;
  - on DC2 and DC4, half of the parts go over a second pool to the media address (`MediaOnly`, 4 connections);
  - on DC1, the home server, the media route is a second client with its own in-memory key and `Pool(4)`
    (`route_home.go`).
- **How many connections were open, and how many requests each carried: not recorded.**

### 6. The request itself
- **The old app's own reader,** for files over 1 MiB (`parallel_download.go` `fetchPart`):
  - `upload.getFile{location, offset = k × 1 MiB, limit = 1 MiB}`, with no flags: `precise` and `cdn_supported`
    are not set;
  - **the same 1 MiB limit on every request, the last one too.** A short answer ends the file. A file longer than
    its stated size is read on until a short part;
  - up to 4 parts of a file in flight.
- **The library's reader,** for files of 1 MiB or less (photos, small documents): limit 1 MiB, offset 0,
  `precise` set, `cdn_supported` not set (B.2).
- **v0.166.0 differs:** its master reader sets `precise` only "for parts that need it" (`needPrecise`). Worth a
  check if the new app uses the library's reader.
- **The connection's first request** (`initConnection`): **nothing beyond the library's defaults.**
  - `gotd_client.go` sets only the session storage, the update handler, the proxy resolver and the flood guard
    middleware.
  - No device fields, no ping or ack settings, no PFS.
  - So the device is the library's default, the same in v0.163.0 and v0.166.0: model "Desktop", system
    "Windows 10", app version "6.9.1 x64", system language "en-US", language pack "tdesktop", language "en".
  - `TGDL_VERIFY_CHUNKS` is off, so the old app never asks for file hashes while downloading.

## C. The account and server 2

### 7. Another account
**No.** The old app has only ever downloaded on the old account. The work table holds one account. No run on the
test account or any other is on record. **So the difference may be the account, not the app.** Two more
differences are known:
- **the server:** the old account's busiest file hours were on DC1 and DC4; DC2 never went over 10 files a
  minute in an hour;
- **the per-file message re-read** (B.3), which the old account sends before each download.

### 8. Server 2 only
The 25 DC2 server-hours, over 6 days, 14 of them with a wait:

| | Lowest | Median | Highest |
|---|---|---|---|
| Plain waits per 1,000 files | 0 | 7.4 | 137 |
| Plain waits per 1,000 part requests | 0 | 0.11 | 3.8 |

- **The worst hour, 11-08 19:00:** 25 waits, 182 files, 6,611 part requests, 6,758 MB, 26% small files: a big-file
  hour. Next: 11-08 18:00 (5 waits, 53 files, no small files) and 11-14 10:00 (4 waits, 53 files).
- **DC2 hours with half or more small files:** 5 hours, 8 waits, 1,744 files, 24,190 part requests. That is about
  4.6 waits per 1,000 files.

### 9. Waits every 2 to 3 seconds
**Nothing like it on record.**
- **The most plain waits in any complete server-hour,** speed-limited or not, in the 142 hours: 116 on DC4 at
  11-13 04:00. That is one every 31 s, ten times sparser than your run.
  - It was the first hour after DC4's speed limit lifted (03:00 had 138 speed-limit waits, 04:00 none).
  - Only 10% of its files were small (436 files, 24,743 part requests, 25,701 MB): a big-file hour.
  - It ended by itself: 05:00 had none, with more files (710).
  - Nothing in the app changed then. 12.30 went live at 14:42 that day.
- Next: 25 on DC2 (11-08 19:00), 15 on DC1 (11-09 18:00), 12 on DC1 (11-12 00:00).
- **Before 11-08 14:00:** not read here. The reports on disk start then, so earlier hours are not covered.

## D. Connections

### 10. A pool connection that ends after a few seconds of video parts
**Nothing in the old app's code or the library (v0.163.0) is known to make Telegram end a download connection
after some MB or seconds.** The old app sets nothing on its connections to prevent it either: no ping, ack or
initConnection setting (B.6).

**Its pools' keys:**
- **A non-home server's pool runs every connection on one key, authorized once** (`telegram/pool.go` `dc`):
  - the library keeps one session per server (`c.sessions[dc]`) and every connection the pool opens shares it;
  - the first connection makes the key, and one `auth.exportAuthorization` / `auth.importAuthorization` runs when
    the pool is created;
  - the per-connection import is switched off during it, and runs again only if a key is made anew after a
    reconnect.
- **The media pool on DC2 and DC4 shares that key:** `MediaOnly` takes the same path, with the same session map.
- **The old app opens each pool once per server and keeps it** (`sharedPool`).
- These keys are in memory only. **By the code:** one export and import per server per app start.
- **v0.166.0 adds:** a stored key of a server that is already authorized is reused without an export or import
  (`dcKeyAuthorized`), and a connection slot keeps its server session across reconnects (`SessionState`).

**Pings and acks:** the library's defaults, unchanged by the old app.

| | v0.163.0 | v0.166.0 |
|---|---|---|
| Ping (`ping_delay_disconnect`) | every 1 minute, 15 s pong timeout | every 30–45 s, `disconnect_delay` 60 |
| Acks | batched: 20 messages or 15 s | not compared |
| Future salts | asked every hour | never asked |

**What the old app saw:**
- **Before 3.4.5 (10-13):** each file opened and closed its own pool. That meant a new connection, and on another
  server a new authorization export, per file. Downloads failed in bursts with "engine forcibly closed".
- **3.4.5:** one long-lived pool per server, shared by all downloads. **The changelog says this removed the
  bursts.**
- **3.4.9:** a part whose connection died is asked again on another pooled connection, up to six times.
- **Losses now:** in the same unlimited hours, "connection lost" is **0 on every server** (DC1 1,171,142 MB, DC2
  201,911, DC4 655,309, DC5 233,829). Losses that show as "cancelled" in hours with no -503 at all were at most 2 on
  DC1, 4 on DC4 and 0 on DC2 (answers 8, B.3).
- So DC2's connections carried GBs each, not 23 MB. That is "looks like": how long each connection lived is not
  recorded, and the library's own log is off (`TGDL_TELEGRAM_DEBUG`).

**Differences from your run:**
- **Connections:** at 2 parts in flight on a 4-connection pool, your parts ride about 2 connections (B.5). Each
  will see far more traffic than the old app's, which spreads 2.5 to 3.4 parts over a main and a media pool.
- **Keys:** if your pool imports per connection, or makes a new key per reconnect, that differs from the old app's
  one key per server per start.

Neither is shown to cause the end-of-stream closes. These are leads for your logs, not findings.
