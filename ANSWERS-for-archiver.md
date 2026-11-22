# Answers for the archiver session, from the fork session (2026-11-12, ~19:30 local)

Answers `QUESTIONS-for-fork.md`. No change to the fork, nothing pushed. Read-only: the hourly reports
(`data\ixreports\*.txt`, 49 saved, 11-10 19:00 to 11-12 18:52), the database opened `?mode=ro`, and the fork's code at
12.29 (`repo-v12.16`, branch `ix/v12.29`). Numbers, error type names and fixed words only. 12.29 has been running since
11-12 00:38:36 with no restart since.

## Short answers

1. **Staging:** two bursts, both ended on their own (no restart, no action on the NAS). Every waiting file failed at once,
   fast and before any byte was written, then copied on its next tries. **The error kind is not recoverable:** the fork
   keeps only each file's last error and deletes the row once it is copied. The likeliest cause is the library share being
   unreachable for a few minutes. That fits every number but is **not proven**.
2. **Discovery:** measured. What is left for DC2 is **almost all copies held at the back**: 3,974 of its 3,975 queued files
   are held as probable copies, and only **208 new DC2 files (about 9 GB)** are in messages already read. Messages not read
   yet are not the store: every group has had its messages pass. Meanwhile **about 26,400 new files (about 628 GB) on
   DC1, DC4 and DC5 sit in saved messages, not queued**. They are reachable with no history requests at all.
3. **Frozen account:** in 49 hours of records, **no file part, message refresh or history page was refused as frozen**.
   The update state is current, so update differences are answered. The one refusal on record is
   `channels.getFullChannel` → `FROZEN_METHOD_INVALID`, for nearly every chat. On file parts, beyond waits, -503 and file
   references, the fork saw **no other Telegram error type at all** in 48 hours.

---

## 1. Staging: the copy failures

**Timeline** (hourly reports; "failing" = staged files whose last copy try failed and that are not copied yet):

| Report (local) | Waiting | Failing | Copy tries that hour | Copied that hour |
|---|---|---|---|---|
| 11-11 22:xx | 9,573 / 133 GB | 0 | 1,062 | 1,023 |
| **11-11 23:xx** | 12,049 / 158 GB | **5,536, since 50 min** | **35,616** | 675 |
| 11-12 00:xx | 13,082 / 173 GB | 5,086 | 883 | 549 |
| 11-12 01:xx (12.29 since 00:38) | 15,462 / 206 GB | 3,455 | 1,010 | 948 |
| 11-12 02:xx | 19,225 / 248 GB | 1,473 | 2,194 | 2,104 |
| 11-12 03:xx to 06:xx | 19,297 to 16,389 | 0 | 2,867 to 3,587 | 2,697 to 3,499 |
| **11-12 07:xx** | 13,519 / 237 GB | **11,632, since 39 min** | **48,823** | 3,158 |
| 11-12 08:xx to 11:xx | 10,084 to 4,094 | 8,193, 6,300, 4,658, 2,192 | 1,835 to 3,176 | 1,750 to 3,009 |
| 11-12 12:xx | 1,104 / 36 GB | 0 | 3,309 | 3,115 |
| 11-12 14:xx to now | 0 | 0 | 2 to 5 | 2 to 5 |

- **Two bursts:** about 22:20 on 11-11 and about 06:28 on 11-12.
- **What the 5,667 meant:** "failing" is not "failing now". It counts files that failed once and still wait their turn.
  It fell steadily while all 8 copiers ran full. The update restart at 00:38 kept the count (it comes from the journal).
- **How long each outage lasted (estimate):** the extra tries were about 34,600 over 5,536 files (about 6 each) and about
  45,700 over 11,632 (about 4 each). With the retry pause starting at 5 s and doubling, that suggests each file kept
  failing for roughly 2 to 5 minutes. **This is an estimate, not measured.**
- **Where the tries failed:** in "prepare", before writing. Prepare seconds went from 2,521 (22:xx) to 7,224 (23:xx), and
  from 1,364 (06:xx) to 3,793 (07:xx), while write seconds fell. In `moveStaged`, prepare is reading the journal row,
  opening the local copy, `ensureDir` of the library folder, `os.OpenRoot` of the library and its folder, and creating the
  `.part` on the share. A local-disk or database failure would not fail every file at once and then clear by itself. A
  share that could not be reached for a few minutes would. **Not proven.**
- **The kind is lost:** `tgdl_stage_moves.error` keeps only the latest error and the row is deleted once copied. The table
  is empty now. The report counts no staging failures by kind. The `[recent errors]` section holds download errors only.
  Its 16 "Runtime already running" at 23:xx are an engine-start conflict, not copies.
- **Not related:** the nightly backup ran at about 04:15. The background library reads were light at 22:00 (38 files)
  and 06:00 (43 files).

**For the copier (`STAGING-BRIEF.md`):**
- Count failures by step and by OS error class (share unreachable, access denied, file busy, disk full, missing, other), per
  hour, kept apart from the last-error text.
- Report "failing now" (failed within the last N minutes) apart from "failed once, waiting its turn".
- When every copy fails at the prepare step within seconds, treat it as one outage: probe the share once and pause every
  copier until it answers, rather than each file spending its own 4 to 6 tries. The fork's per-file backoff cost
  35,000 to 49,000 refused tries in an hour, harmlessly in this case.

## 2. Discovery: what is left for DC2

**Measured.** Server of each file is read from the saved raw message: the `dc_id` of the photo or document whose id is in
`media_key`. Checked first against 5,000 saved messages whose server the queue already knew: **5,000 of 5,000 matched.**

**DC2 now:**
- Queued: **3,975** pending. **3,974 are held as probable copies** (all paused, at the back by design); 63 are also set aside.
- In saved messages, not queued, a Telegram file not saved or queued anywhere: **208** (135 small, 73 large; about 9.4 GB).
  This matches the top-up's own list (DC2 small 84 + large 120 = 204).

**Every server: new files in saved messages with no queue row** (distinct Telegram files, not saved or queued anywhere):

| Server | Small | Large (20 MB or more) | Files | GB |
|---|---|---|---|---|
| DC1 | 14,613 | 2,861 | 17,474 | ~368 |
| DC2 | 135 | 73 | 208 | ~9 |
| DC4 | 6,563 | 1,593 | 8,156 | ~207 |
| DC5 | 145 | 427 | 572 | ~44 |
| **All** | | | **~26,400** | **~628** |

- The same saved messages also hold 12,798 copies by Telegram file and 1,344 repeats of one file in other messages. The
  top-up refuses those one by one.
- Nearly all of the new files (25,800) are in the **26 groups whose files pass has not run yet**. Their messages passes
  ran within the last 7 days.
- **Not read yet:** every group in the rescan has had its messages pass ("0 not read"). Each group's latest read has a
  date floor more than a year back. Not measured: messages older than that floor, and any message since a group's last
  messages pass that the update stream missed.

**DC2's supply, by hour** (queue rows created, all servers' figures for comparison):
- 11-11 18:00 to 11-12 01:00: DC2 got 159 to 1,042 a hour (DC1 1,709 to 5,591).
- 11-12 02:00: 63; 03:00: 20; 04:00: 78. DC1 still got 2,238 to 4,074 and DC4 886 to 1,433 in those hours.
- Under the speed limit (05:00 onward) nearly nothing is created on any server: the files pass waits for room under the
  500 limit (52 to 57 minutes an hour at 16:00 to 18:00).

**History requests per newly found file:**
- Last 24 h: 54 files passes (30 done, 17 errors, 6 cancelled, 1 running) read 62,992 messages.
- In those groups during those passes, 53,600 queue rows were created, 29,354 not held as copies. DC2: 1,630 rows,
  1,482 not held. These figures include any top-up rows in the same group at the same time: every row's origin is
  "history", so the two cannot be told apart.
- Pages: **at least 683** (one page holds up to 100 messages). The real count is higher: a page shrinks to the room left
  under the 500 limit, and the report counts no history requests.
- So, as lower bounds: at least 0.023 pages per new file (at most 43 new files a page); for DC2 alone, at least 0.46 pages
  per DC2 file.
- **The point that matters more:** the fork's files pass re-reads history the messages pass has already saved. The 26,400
  new files above could be queued from saved messages for **no history request**. The cost would be one message refresh
  per file when it is claimed, as the top-up already does. The top-up does not take them because it feeds idle servers
  only, and DC1 and DC4 are busy.

**For the new app:**
- Read each message once.
- Keep the raw message, or at least the file's id, size and server.
- Queue from that store by Telegram file, with no second history read.
- History reads then serve only messages not seen yet. They become the only discovery cost, and the only reason to spend
  history requests.

## 3. The frozen account, as Telegram answers it

Recorded refusals (since the freeze on 10-31):

| Request | Refused? | Evidence |
|---|---|---|
| `channels.getFullChannel` (chat details) | **Yes, `FROZEN_METHOD_INVALID`**, for nearly every chat | On 11-10, 180 of 189 chats had never had their details saved (12.25 changelog). Since 12.25 a refused chat is not asked again for 24 h, held in memory only: at most about one request per chat per day, and one more after each restart. Not counted per day anywhere. |
| Forum topic list (`channels.getForumTopics`) | Refused (12.13 changelog) | The error type is not recorded. |
| `upload.getFile` (file parts) | **No `FROZEN_*` seen** | 48 hourly lines (11-10 18:00 to 11-12 17:00): "other Telegram error", where an unknown type would land, is **0**. |
| Message refresh at claim (`channels.getMessages`) | **No `FROZEN_*` seen** | The report's "refused as frozen" was false in all 49 reports. It reads the last 6 h of download-work errors, rescan-job errors and rescan-queue errors. |
| History pages (`messages.getHistory`) | **No `FROZEN_*` seen** | 895 stored rescan jobs. The 273 that ended in error: context canceled 154, deadline exceeded 101, 18 with no Telegram type. |
| Update differences (`updates.getDifference`, `getChannelDifference`) | **Answered** | The stored update state is 0.2 h old; 120 channels are tracked. Errors are not recorded, so there is no count. |
| `users.getUsers` (self), `updates.getState` | Not recorded | The fork's session check expects `FROZEN_METHOD_INVALID` on the first and falls back to the second. Whether the first is refused is not on record. |
| `FROZEN_PARTICIPANT_MISSING` | **Never seen** | Not in any error column of the database or in any saved report. |

Caveats:
- Work rows keep only their last error (300 newest read), and reports older than 11-10 19:00 have rotated out.
- So "never seen" means "not in these 49 hours of records". It does not mean Telegram never refused.
- The database holds no `FROZEN_*` text anywhere today.

**File-part failures by kind** (the fork's `failKind`, summed over every server, from each report's last full hour):

| Kind | 11-10 (5 h, all limited) | 11-11 (24 h, 18 limited) | 11-12 (19 h, 15 limited) |
|---|---|---|---|
| speed limit (`FLOOD_PREMIUM_WAIT`) | 3,730 | 18,496 | 10,250 |
| Telegram timeout (-503) | 770 | 7,073 | 7,830 |
| file reference (`FILE_REFERENCE_EXPIRED` / `_INVALID`) | 242 | 1,273 | 1,068 |
| cancelled (by us) | 12 | 173 | 194 |
| plain wait (`FLOOD_WAIT_n`) | 0 | 38 | 39 |
| no answer in time (our deadline) | 3 | 9 | 4 |
| other, not from Telegram | 0 | 0 | 5 |
| connection lost, network timeout | 0 | 0 | 0 |
| **any other Telegram error type** | **0** | **0** | **0** |

- In `[recent errors]` and the work rows, only these types appear:
  - `FILE_REFERENCE_EXPIRED` (code 400; never `_INVALID`);
  - `Timeout` (code -503);
  - `FLOOD_WAIT_16` (once);
  - `context deadline exceeded`, `context canceled`;
  - the fork's own set-aside notices ("server N timed out on this file N times in a row").
- For `errors.go`, then: on file parts this account meets waits, the speed limit, -503, expired file references and
  nothing else. `FROZEN_*` is worth handling as fatal for the method that got it (chat details, topic lists), not for
  downloads.

## How this was measured (to repeat it)

- Read-only Python with `sqlite3` on `file:E:/T/tg-dl/data/db.sqlite?mode=ro` and `PRAGMA query_only=1`. Run with
  `python -I -X utf8`: `-I` ignores `PYTHONUTF8`.
- Every query prints counts only.
- Server of a saved message: find the 8-byte id from `media_key` (`photo:<id>:<size>` / `document:<id>:<size>`) in
  `ix_messages.tl`. Check that the constructor 8 bytes earlier is `photo#fb197a65` or `document#8fd4c4d8`. Skip
  access_hash, file_reference, date, then the sizes and thumbs vectors (and for documents the mime type and size). The
  next int is `dc_id`.
- Copies by Telegram file: `media_key` with `:` replaced by NUL equals `tgdl_work.identity`, or the id equals
  `downloads.telegram_media_id`.
- Rescan state: `kv` key `ix_queue`. Files passes: `tgdl_history_jobs.payload` (`job.processed` counts every message read).
