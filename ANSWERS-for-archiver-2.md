# Answers for the archiver session, second set, from the fork session (2026-11-13, ~01:50 local)

Answers `QUESTIONS-for-fork-2.md`. No change to the fork, nothing pushed. Read-only: the database opened as
`file:E:/T/tg-dl/data/db.sqlite?mode=ro` with `PRAGMA query_only=1`, and the fork's code at 12.29 (`repo-v12.16`,
branch `ix/v12.29`, gotd `v0.163.0`). Numbers, table and column names, fixed words and public constants only.

**Counts are a snapshot taken 11-13 between about 01:05 and 01:45 local while 12.29 ran.** They move by a few rows
an hour (one saved file was added between two of my reads). The bring-in should take its own counts in **one read
transaction** and compare against those, not against these.

Beside this file: **`ANSWERS-for-archiver-2-schema.sql`**, every `CREATE` statement from `sqlite_master` (136 tables,
159 indexes, 13 triggers), with each table's row count as a comment. It holds no row content. It runs as is in an empty
database: I loaded it into an empty in-memory SQLite and got the same 136 / 159 / 13. Use it to build the invented test
database in the exact old layout.

## Short answers

1. **Layout:** everything the new app must carry is in 43 tables plus 4 JSON values in the `kv` table. Section 1 lists
   them with row counts. Missing from your list:
   - **the links** (`ix_msg_link`, `ix_subst`): about 48,000 messages whose file is another message's saved file;
   - **chat settings live in JSON**, not in tables: `kv` key `config` (the 190 chats, their filters, on/off), `ix_queue`
     (the rescan state), `history_jobs` (the passes), `ix_settings` (the archive's settings);
   - the picture embeddings, clusters and video matches (`ix_emb`, `ix_emb_frames`, `ix_mcl`, `ix_vdup`), OCR text,
     topic folders, Telegram's previews of queued files, and the integrity checks.
2. **Encodings:** section 2.
   - **`media_key` is `<kind>:<id>:<size>`**, and **`tgdl_work.identity` is the same three parts joined by NUL (0x00)**.
     I checked every row that has both: 0 differ.
   - **`tl` is the whole message**, TL-serialised by gotd v0.163.0 (layer 232) with its constructor id. All 400,982
     ordinary messages are `message#7600b9d3` and all 288 service messages are `messageService#7a800e0a`, so one decoder
     reads them all.
   - **Times are mixed:** Telegram's dates are unix seconds; the fork's own times are unix ms; `downloads.created_at` is
     UTC text.
   - **Chat ids are marked text:** 9 chats are `-100<id>` (all forum supergroups) and **181 are `-<id>`, real basic
     groups**. I checked the raw messages: their peer is `peerChat`.
3. **Counts:** section 3. Six things do not add up, and each has a known cause (section 3c), for example 17,093 queued
   rows whose Telegram file is already saved.
4. **Library:** `<chat folder>/[<topic folder>/]<images|videos|documents|audio|gifs|stickers>/<name stem>_<message id>_<32
   hex><ext>`. Every path is relative to the library root, with `/` separators. The fork never counts "row but no file"
   for the whole library. Its integrity check has looked at 28,659 files: 4 unreadable, 0 missing.
5. **Traps:** section 5. The worst: a chat's folder is its name at save time; a `released_at` of -1 does not mean held;
   `minDate` 1 is a flag, not a date; a stale settings key; `ix_group_info.kind` is empty for all 181 basic groups;
   status `completed` does not mean "has a file row".

---

## 1. The layout, what to carry, and row counts

The exact `CREATE` statements are in the `.sql` file beside this one. The DB is WAL, `page_size` 4096, `user_version` 0
(unused), and `tgdl_schema_meta.version` = 1 (unused for the `ix_*` tables, which are made with `CREATE TABLE IF NOT
EXISTS` and `ALTER TABLE ADD COLUMN` at start).

### 1a. Carry

| What | Where | Rows |
|---|---|---|
| Messages (raw record, text, album, topic, forward, reply, views, service) | `ix_messages` | 401,270 |
| Older texts of edited messages | `ix_message_edits` | 0 |
| Message ids Telegram says are gone | `ix_absent` | 1 |
| Topic names | `ix_topics` | 100 (9 chats) |
| Senders' and chats' names | `ix_peers` | 1,474 (user 1,247; chat 190; channel 37) |
| Chat details (forums only, see trap 5.6) | `ix_group_info` (`tl` = `messages.chatFull#e5d7d19c`) | 190 (9 with details) |
| Saved files | `downloads` | 186,585 |
| Each saved file's size, mtime and SHA-256 as last verified | `tgdl_verified_media` | 186,583 |
| Messages that point at another message's saved file | `ix_msg_link` | 44,455 |
| Files not downloaded because the library has the same bytes | `ix_subst` | 4,780 |
| Identities to download for real (an override of the above) | `ix_subst_block` | 0 |
| Work rows | `tgdl_work` | 284,052 |
| Which edit of a message the library holds | `tgdl_message_generations` | 245,012 |
| Partial downloads | `tgdl_part_progress` | 15 |
| Kept 1 MiB parts | `ix_part_store` (+ files, section 2) | 33,000 parts, 3,539 files |
| Holds (probable copies), current and past | `ix_held` | 111,633 |
| How each hold was found, and its confirmation | `ix_copy_hold` | 47,080 |
| Big videos checked by sampled frames | `ix_copy_sample` | 19,097 |
| Telegram's small previews of queued files | `ix_copy_thumb` (+ files under `data\ixpreviews`) | 13,780 |
| Rows put back so smaller files go first | `ix_deferred` | 36,446 |
| Big videos put back when their check had no answer | `ix_check_putback` | 3 |
| Retry rounds per work key | `ix_retry` | 57 |
| Lower-quality-first videos | `ix_lowq` | 0 |
| Chat ranking | `tgdl_group_rank` | 156 |
| Topic ranking | `ix_topic_rank` | 9 (5 chats) |
| Topic folder names | `ix_topic_dirs` | 94 |
| What Telegram said about each chat seen (access, refusals, migrations) | `chat_access` | 378 |
| "Count media" answers for chats not added | `ix_media_counts` | 0 |
| Update state | `tgdl_update_state` | 1 |
| Update state per channel, with the channel's access hash | `tgdl_update_channels` | 120 |
| Users' access hashes | `tgdl_user_peers` | 148 |
| Video fingerprints | `ix_vfp` | 119,466 |
| Picture hashes (PDQ + 32×32 grey) | `ix_pdq` | 61,773 |
| Picture embeddings | `ix_emb` | 169,017 |
| Video frame embeddings | `ix_emb_frames` | 706,505 (111,681 videos) |
| Picture clusters | `ix_mcl` | 61,767 |
| Video matches between saved videos | `ix_vdup` | 92,251 (same 59,510; overlap 25,984; clip 6,880) |
| Close pairs to review | `ix_msug` | 43,221 |
| Lone files that look like part of an album | `ix_set_sug`, `ix_set_sug_seen` | 11,764; 24,862 |
| Faces, people, face decisions | `ix_faces`, `ix_people`, `ix_person_pair`, `ix_face_done`, `ix_face_reject`, `ix_face_meta` | 80,060; 3,749; 200; 113,443; 0; 2 |
| OCR text | `ix_ocr` (+ `ix_ocr_fts`) | 113,284 (34,230 with text) |
| Integrity checks | `ix_fixity`, `ix_fixity_events` | 28,659; 4 |
| Duplicates found per day, by how | `ix_dedup_daily` | 40 (10 days) |
| Person decisions on albums and sets | `ix_album_orphan`, `ix_album_pairs`, `ix_org_*` | all 0 |
| The rest of the fork's state (JSON) | `kv`: `config`, `ix_queue`, `history_jobs`, `ix_settings` | 4 values |
| One-off flags (carry only as "done") | `kv`: `ix_freeze`, `ix_copy_calib`, `ix_rank_stars_done`, `ix_unlinked_repair_v1`, `ix_deadline_auto_1220`, `ix_sample_recheck_vfp` | |

### 1b. Do not carry (empty, derived, or the fork's own plumbing)
- **Copies of other tables:**
  - `tgdl_cluster_catalog` (186,585) is a trigger-made copy of `downloads`;
  - `downloads_fts` and `ix_fts` are full-text indexes, rebuilt from `downloads` and `ix_messages`.
- **Pictures the new app will make again:** `seekbar_sprites` (120,093 rows, 9.7 GB of sprite files).
- **Plumbing:** `tgdl_history_jobs` (898) is the fork's job runner; `ix_queue` and `history_jobs` in `kv` say the same
  things more simply. `ix_walks` (537) records older passes.
- **Empty and unused:**
  - backup: `backup_*`, `native_backup_*`;
  - cluster and peers: `cluster_*`, `peer*`, `peers`;
  - old ML tables: `faces`, `people`, `image_embeddings`, `image_tags`;
  - other: `queue`, `update_history`, `tgdl_account_ops`, `tgdl_purge_jobs`, `tgdl_rescue_messages`,
    `tgdl_update_recovery*`, `tgdl_ingest_files`, `tgdl_stage_followers`, `tgdl_stage_moves` (0 now), `ix_stt*`,
    `ix_vband`, `ix_move_plans`, `ix_moves`, `ix_alerts`, `nsfw_hash_blocklist`, `share_links`.
- **Secrets:** `web_sessions` and the `kv` keys `cluster_token`, `cluster_catalog_epoch` and `peer_id`.
  - `kv` `config` also holds the API hash, a password hash and a share secret: **read only `groups` from it.**
  - `ix_settings` holds alert addresses and SMTP settings; the SMTP password itself is never stored there.

### 1c. Where each thing on your list lives

**Messages** (`ix_messages`, key `(group_id, message_id)`):
- `text`;
- album: `grouped_id`, the int64 as decimal text, '' when none (265,017 messages in 49,231 albums);
- topic: `topic_id`, 0 = no topic mark (20,697 have one);
- forward: `fwd_from` and `fwd_date`;
- reply: `reply_to`, 0 = none (3,344);
- sender: `sender_id`;
- service: `service` (288 service messages);
- `deleted_at` (0 for every row);
- `media_type`, `media_name`, `media_size`, `media_key`;
- `views`, `comments`;
- `first_seen` and `seen_at` (ms).

**Files:**
- **Saved files: `downloads`.**
  - `file_path`, `file_size` and `file_hash` (SHA-256, lower hex, 64 characters on every row);
  - Telegram's identity in three columns: `telegram_media_kind`, `telegram_media_id`, `telegram_media_size`;
  - `telegram_mime`, `media_width`, `media_height`, `media_duration_ms`, `forward_origin`;
  - `telegram_thumb`: Telegram's stripped thumbnail bytes, 8 to 301 bytes, on 184,944 rows.
- **Work rows: `tgdl_work`.**
  - `status`, `paused`, `dc` (the server), `identity`, `attempts`, `retry_at`, `error` (the last error, free text);
  - `origin`: always 'history' today;
  - `sched_order`: claim order, 131072 = unranked;
  - `body`: the queued message, `message#7600b9d3`, emptied to `X''` once completed.
  - There is no "last error kind" column: the kind has to be parsed from `error`. The classes seen are in section 3b.
- **Partial downloads: `tgdl_part_progress`.**
  - It has `path` (the final place, relative to the library), `size` (the file's full size), `offset` (bytes already
    on disk), `sha256` and `stage_dir`.
  - The bytes are in `<stage_dir or library root>/<folder of path>/.tgdl-<file name>.part`.
  - Only files of 8 MiB or more are kept this way.
- **Kept parts: `ix_part_store`**, one row per 1 MiB part, with `ident`, `part` (= offset / 1 MiB), `bytes`, `sha256`
  and `at`.
  - The bytes are in `data\ixparts\<SHA-256 hex of the ident string "kind:id:size">\<part number>`.
  - 33,000 parts of 3,539 files hold 32,949,460,358 bytes. All are documents (videos).

**Holds and copies:**
- **Holds: `ix_held`**, one row per work row:
  - `released_at`: 0 = held now, -1 = looked at and not held, >0 = let go (ms);
  - `reason`: the rule, in fixed words (section 3b);
  - `like_key`: `h:<SHA-256 of the saved file it looks like>`, and `like_path`: that file's path. Both are set when
    the hold is against a saved file and empty when it is against a queued file.
- **More about each hold: `ix_copy_hold`:**
  - `how`: saved, queued, sampled, sampled-partial, unlinked-copy;
  - `of_work`: for `queued`, the work row it is a copy of;
  - `sim`: the preview likeness;
  - `confirm`: '', confirmed, unconfirmed.
- **Confirmed copies:** `ix_copy_hold.confirm='confirmed'` and `ix_copy_sample.result='confirmed'`. `of_key` names the
  saved file as `h:<sha256>`.
- **"Partly the same":**
  - held: `ix_held.reason` 'partly the same footage as a saved video (sampled frames)', or `ix_copy_hold.how`
    'sampled-partial';
  - between saved videos: `ix_vdup.kind` 'overlap' or 'clip'.
- **Given up:** `tgdl_work.status='failed'`.
- **Skipped as exact copies:** `ix_subst` (same bytes, checked by Telegram's part hashes) and `ix_msg_link` (how:
  telegram-file, exact-reupload, after-download). Status 'skipped' exists in the code but has 0 rows.

**Per chat and per topic:**
- **Chats added, on/off, filters:** `kv` `config` → `groups`, a JSON array of 190.
  - Each has `id` (a JSON number, the marked id), `name`, `enabled` (91 on, 99 off), `filters`, `topics`,
    `rescueMode`, `autoForward` and `trackUsers`.
  - `filters` holds photos, videos, files, audio, gifs, stickers, voice, links, urls. Every chat has photos, videos
    and files on; audio, gifs, stickers and voice off; links and urls on for 2.
  - `topics.enabled` is false for all; `autoForward` and `trackUsers` are off for all.
- **"Always download": the fork has no such setting.** The nearest things are:
  - the ranking;
  - `ix_settings.groupPolicy` ('order' or 'spread': what the ranking means);
  - `ix_subst_block` (download for real despite a known copy; 0 rows).
- **Rank:** `tgdl_group_rank`.
  - `rank` 1 is first: 156 chats ranked, 1 to 156, no gaps.
  - `sched_base` = rank × 8. It is copied into `tgdl_work.sched_order` of that chat's rows.
  - Topics: `ix_topic_rank.place`, which is the chat rank the topic sits beside.
- **Rescan state:** `kv` `ix_queue` → `items`, 162 chats. Each item has:
  - `state`: done 136, waiting 25, running 1;
  - `phase`: files 157, messages 5;
  - `messagesAt`: ms, when its messages pass finished, set for all 162;
  - `messages`, `missing`, `processed`, `downloaded`, `attempts`;
  - `priority` (150 true), `startedAt`, `finishedAt`, `addedAt`;
  - `resumeFrom`: the message id to carry on from, set for 1;
  - `jobId`.

  Each pass is also in `kv` `history_jobs` (897, mode 'pull-older' for all):
  - `minDate` 1 means "to the very start" (trap 5.3);
  - `offsetDate` (seconds, 31 set), `messagesOnly`, `state`, `processed`, `error`.

  **Not stored: "files pass done" and "last message read" as columns.** The fork derives them:
  - files pass done = item `phase`, `state` and `finishedAt`;
  - the place a pass reached = the `cursor` in `tgdl_history_jobs.payload`.
- **Marked finished:** `ix_group_info.finished_at` (0 for all).
- **Paused:** per chat = `enabled` false; for the whole queue, `tgdl_queue_state.paused`.

**Access and refusals:**
- **Access data:**
  - Basic groups need no access hash. The 181 are reached by bare chat id.
  - Channels: `tgdl_update_channels.access_hash` (INTEGER, signed int64), keyed by the bare positive `channel_id`.
    It is set for all 120 rows, including the 9 forums.
  - Users: `tgdl_user_peers.access_hash` (INTEGER).
  - The kind follows from the id's form (section 2), and `ix_peers.kind` says the same.
  - gotd's own peer cache lives in the session files, not in this database; I did not read them.
- **Chats seen and not added:** `chat_access` rows whose `chat_id` is not in `config.groups`. There are 188:
  ok 79, restricted 48, migrated 10, deleted 51. The names are in `ix_peers`.
- **Refusals remembered:** `chat_access.state` and `code`:
  - restricted: code 'terms' 47, 'porn' 1;
  - deleted: USER_DELETED 51;
  - migrated: CHAT_MIGRATED 10, with `migrated_to`.

  The `channels.getFullChannel` refusal is held **in memory only** (24 h) and is in no table.

**Fingerprints, previews and faces:** section 2.

**Staging:** `tgdl_stage_moves`, **0 rows now** (state 'waiting', or 'stuck': needs a person).
- `path`: final place, relative to the library;
- `stage_dir`: the absolute local folder;
- `item`: JSON of the fork's `download.Item`, with keys GroupID, GroupName, MessageID, Name, Type, Identity{Kind, ID,
  Size}, Facts, TTLSeconds, Topic, SkipDuplicates, Requeue;
- `generation`, `identity` (NUL form), `sha256`, `size`, `attempts`, `next_at`, `failing_since`, `error`.

**Update state:**
- `tgdl_update_state`: one row (`account_id`, `user_id`, `pts`, `qts`, `date` in seconds, `seq`).
- `tgdl_update_channels`: 120 rows (`account_id`, `user_id`, `channel_id`, `pts`, `access_hash`). `pts` is NULL on
  111 of them.

**Settings:** `kv` `ix_settings`, one JSON object.
- The fork's struct has **65 fields** (not 62).
- **55 keys are stored.** 54 are struct fields; `bigAtOnce` is a stale key (trap 5.4).
- Eleven fields are absent and take their defaults (`omitempty`): sampleBig, checkInDownload, mediaRoutesOff,
  classicWaits, timeoutAsideOff, speedFallbackOff, topUpOff, topUpFastOff, bigPerServer, checkFromMb, alertSmtpPass.
- All 65 names: exportEnabled, exportTime, exportDir, backupOff, pauseOnFreeze, quietStart, quietEnd, pace,
  dupEnabled, dupHwaccel, dupQuietStart, dupQuietEnd, autoRetry, fixityEnabled, substExact, holdLikely, holdForever,
  holdAlbums, sampleBig, checkInDownload, mlUrl, mlModel, mlFaces, mlTextModel, mlText, mlDupes, mlThings, sttUrl,
  sttModel, mlContainer, sttContainer, mlAutoStart, deadlineOrder, groupPolicy, downloadPacing, paceByAnswers,
  mediaRoutesOff, classicWaits, timeoutAsideOff, speedFallbackOff, topUpOff, topUpLimited, topUpFastOff, lowqFirst,
  lowqKeep, stageDir, stageCapGb, stageKeepFreeGb, stageCopies, bigPerServer, checkFromMb, alertWebhook,
  alertWebhookKind, alertSmtpHost, alertSmtpPort, alertSmtpUser, alertSmtpPass, alertSmtpPassSet, alertEmailFrom,
  alertEmailTo, alertNames, confirmedGoEarly, copyThumbsOff, previewsAll, autoUpdate.
- Behaviour also comes from `kv` `config`: `download.skipDuplicates` (true), `allowDmDownloads` (false), `rateLimits`,
  `advanced.downloader`, `advanced.history`.
- Two environment variables the launcher sets: `TGDL_DATA_DIR` and `TGDL_DOWNLOADS_DIR`, the library root. Neither
  is in the database.

## 2. Encodings

**Telegram file identities.** The same three parts, in two spellings:

| Spelling | Format | Columns |
|---|---|---|
| Colon | `<kind>:<id>:<size>` | `ix_messages.media_key`, `ix_part_store.ident`, `ix_copy_thumb.ident`, `ix_copy_sample.ident`, `ix_msg_link.tg_file` |
| NUL | `<kind>\x00<id>\x00<size>` | `tgdl_work.identity`, `ix_subst.identity`, `ix_subst_block.identity`, `tgdl_stage_moves.identity`, `tgdl_part_progress.identity` |
| Three columns | kind, id, size | `downloads.telegram_media_kind`, `telegram_media_id`, `telegram_media_size` |

- `kind` is `photo` or `document`, in lower case.
- `id` is the Telegram photo or document id, a signed int64 in decimal.
- `size`:
  - for a document, its size;
  - for a photo, the byte size of its largest `photoSize` or `photoSizeProgressive` (the one downloaded).
- Conversion: replace ':' with NUL. Every one of 325,671 media keys has exactly two colons.
- A thumbnail identity, `thumb-<kind>`, exists in the code but is in no row.

**Saved-file keys:** `h:<SHA-256 lower hex>` of the saved bytes (66 characters). Used in:
- `ix_vfp.key`, `ix_pdq.key`, `ix_emb.key`, `ix_emb_frames.key`, `ix_faces.key`, `ix_ocr.key`, `ix_mcl.key`;
- `ix_vdup.key_a` / `key_b`, `ix_msug`;
- `ix_held.like_key`, `ix_copy_sample.of_key`.

`p:<path>` is the fallback when a file has no hash; there are 0 such rows.

**Raw Telegram records:**
- `ix_messages.tl` is the **whole message**, boxed (it starts with its 4-byte constructor id, little-endian). It is
  serialised by gotd v0.163.0, TL layer 232:
  - `message#7600b9d3`: 400,982;
  - `messageService#7a800e0a`: 288.
  - Lengths are 48 to 3,784 bytes, average 361.
  - It includes the media with the file reference **as read then** (expired by now: refresh before downloading).
- `tgdl_work.body`: the same `message#7600b9d3`, on the 48,641 open rows; `X''` on every completed row.
- `ix_group_info.tl`: `messages.chatFull#e5d7d19c`, 9 rows (the forums).
- Photo and document constructors inside, for parsing: `photo#fb197a65`, `document#8fd4c4d8`,
  `messageMediaPhoto#e216eb63`, `messageMediaDocument#52d8ccd9`.
- The server is not a column of `ix_messages`. It is `dc_id` inside the photo or document in `tl`; the first answers
  file explains how to reach it. `tgdl_work.dc` has it for open rows (0 on 78,591 completed rows saved before the
  column existed).

**Times:**

| Unit | Columns |
|---|---|
| Unix seconds (Telegram's) | `ix_messages.date`, `edit_date`, `fwd_date`; `ix_topics.title_date`; `tgdl_work.version` (= max(date, edit_date)); `tgdl_update_state.date`; `history_jobs.offsetDate` |
| Unix ms (the fork's own; nearly all `*_at` columns) | `first_seen`, `seen_at`, `created_at` and `updated_at` in `tgdl_work`, `held_at`, `released_at`, `checked_at`, `at`, `info_at`, `tg_count_at`, `kv.updated_at`, every `*At` in the `kv` JSON |
| Text, UTC | `downloads.created_at`: `YYYY-MM-DD HH:MM:SS` (SQLite `CURRENT_TIMESTAMP`, 19 characters on every row) |
| Nanoseconds | `tgdl_verified_media.mtime_ns` |

- 0 means "not set" everywhere, and -1 has a meaning in `ix_held.released_at`.
- The fork shows days in America/Toronto. `ix_dedup_daily.day` is that zone's date.

**Paths:**
- `downloads.file_path` is **relative to the library root**, with `/` (0 rows with `\`, 0 absolute).
- The same form is used in `ix_held.like_path`, `ix_msg_link.of_path`, `ix_subst.of_path`, `ix_fixity.path`,
  `tgdl_verified_media.path`, `tgdl_part_progress.path` and `tgdl_stage_moves.path`.
- Every `of_path`, `like_path` and fixity path is a saved path today (0 dangling).
- `tgdl_part_progress.stage_dir` is an absolute local folder.
- `ix_copy_thumb.path` is relative to `data\ixpreviews`.
- Kept parts are under `data\ixparts`, by the rule in section 1c.

**Chat and peer ids:**
- **Marked, as text**, in `group_id` and `chat_id` columns:
  - `-100<id>` for supergroups and channels (14 characters here; the 9 forums);
  - `-<id>` for basic groups (11 characters here; 181);
  - the plain id for users (75, in `chat_access` only).
- Converting a channel: marked = -1000000000000 − id. `ixBare` in `ix_data.go` turns a marked id back into a bare one.
- In `kv` `config.groups[].id` they are JSON numbers, all negative and all within 2^53 (safe as float64).
- **Bare, with a prefix**, in `ix_peers.peer_id`, `ix_messages.sender_id` and `fwd_from`: `user:<id>`,
  `channel:<id>`, `chat:<id>`.
  - `fwd_from` can also be the original sender's display name, for a hidden sender (99,803 rows), or 'hidden'.
  - Read a value without one of the three prefixes as a name.
- **Bare integers:** `tgdl_update_channels.channel_id`, `tgdl_user_peers.user_id`.

**Booleans:** INTEGER 0/1 (`paused`, `refresh_required`, `final`, `manual`, `hidden`, `keep`...); true/false in JSON.

**Fingerprints and vectors:**

| Table.column | Bytes | What it is |
|---|---|---|
| `ix_vfp.frames` (ver 2 on all rows) | 20 per frame | Repeated `float32 t` (seconds) + `uint64 H` + `uint64 HF`, little-endian: two 64-bit DCT hashes of a frame. 20 to 72,000 bytes (1 to 3,600 frames), about 29 bytes per second of video. `duration` is in seconds (REAL). |
| `ix_copy_sample.frames` | 20 per frame | The same packing, for frames sampled from a queued video (`ixPackSampled`). |
| `ix_pdq.hash` | 32 | A PDQ 256-bit hash. |
| `ix_pdq.luma` | 1,024 | A 32×32 8-bit grey image. |
| `ix_emb.vec`, `ix_emb_frames.vec`, `ix_copy_thumb.vec` | 768 | int8, dim 768, model `ViT-B-16-SigLIP2__webli`. Read as int8 / 127, then L2-normalise. |
| `ix_faces.vec` | 512 | int8, model `buffalo_l`. Box `x1,y1,x2,y2` as a share of width and height; `frame` (0 for pictures); `person` (0 = not grouped, -1 = nobody known, else `ix_people.id`). |
| `tgdl_verified_media.fingerprint` | 43 to 46 characters | An OS file identity (volume, file id, change time) tied to this disk and folder. Do not carry: verify again instead. |

`ix_people`: 3,749 people, 0 named, 2 merged into another (`merged_into`).

## 3. Counts the bring-in must reproduce

### 3a. Main counts

| What | Count | Query |
|---|---|---|
| Messages | 401,270 | `ix_messages` |
| Messages with a file | 325,671 | `media_key<>''` |
| … by `media_type` | video 234,482; photo 90,105; gif 527; document 368; sticker 188; voice 1; '' 75,599 (includes 288 service) | |
| … by key kind | document 236,161 messages / 173,993 files; photo 89,510 / 72,719 | prefix of `media_key` |
| Albums | 49,231 albums, 265,017 messages | distinct `(group_id, grouped_id)` |
| **Distinct Telegram files** | **246,712** | distinct `media_key`; adding work identities and `downloads` keys adds none |
| Saved-file rows | 186,585; 3,838,950,813,279 bytes | `downloads`, all `status='completed'` |
| … by `file_type` | video 124,247 / 3,518,993,885,426 B; photo 62,047 / 6,181,459,129 B; document 291 / 313,775,468,724 B | |
| … distinct paths | 186,582; 3,838,937,615,058 bytes | 3 paths are shared by 2 rows each |
| … distinct Telegram files saved | 186,535 | 50 rows repeat a Telegram file |
| … distinct SHA-256 | 185,836 | 749 rows repeat bytes |
| Work rows by status | completed 235,411; pending 48,610; processing 17; failed 14; skipped 0 | `tgdl_work` |
| … pending, paused / not paused | 47,007 / 1,603 | |
| … pending by server | DC1 30,570; DC2 3,975; DC4 11,390; DC5 2,675 | `dc` |
| … all rows by server | 0 (unknown) 78,591; DC1 112,547; DC2 19,453; DC4 56,074; DC5 17,387 | |
| … distinct identities | 219,465 | |
| Held now | 45,428 (all pending and paused) | `ix_held` `released_at=0 AND reason<>''` |
| Looked at, not held | 64,375 | `released_at=-1` |
| Let go | 1,830 | `released_at>0` |
| Confirmed copies (holds) | 4,915 | `ix_copy_hold.confirm='confirmed'` (held now: 4,910) |
| Unconfirmed | 891 | |
| Sampled checks | confirmed 5,022; no match 14,021; failed 54 (30 final) | `ix_copy_sample.result` |
| Linked to another message's file | 44,455: telegram-file 36,910; exact-reupload 4,780; after-download 2,765 | `ix_msg_link.how` |
| Same bytes, not downloaded | 4,780 (237,989,158,779 bytes) | `ix_subst`, all 'telegram-hashes' |
| Given up | 14 (timeout 10, deadline 4) | `tgdl_work.status='failed'` |
| Chats | 190: 181 basic groups, 9 forum supergroups; 190 have messages; 179 have saved files | |
| Chats added | 190 (91 on) | `kv` `config.groups` |
| Chats seen, not added | 188 | `chat_access` minus `config.groups` |
| Topics | 100 in 9 chats; 94 topic folders | |
| Ranked | 156 chats; 9 topics in 5 chats | |
| Video fingerprints | 119,466: ok 119,296, error 170 | `ix_vfp` |
| PDQ hashes | 61,773: ok 61,767, error 6 | `ix_pdq` |
| Picture embeddings | 169,017 | `ix_emb` |
| Frame embeddings | 706,505 rows, 111,681 videos | `ix_emb_frames` |
| Faces | 80,060 (29,071 grouped); 3,749 people | |
| Kept parts | 33,000 parts; 3,539 files; 32,949,460,358 bytes | `ix_part_store` |
| Partial downloads | 15: 2,282,749,952 bytes on disk of 3,531,963,437 | `tgdl_part_progress` |
| Staging | 0 files | `tgdl_stage_moves` |

### 3b. Holds by rule (held now, 45,428)

| `ix_held.reason` | Rows | `ix_copy_hold.how` |
|---|---|---|
| looks like a saved copy | 37,945 | saved (36,808 unconfirmed, 1,101 confirmed) |
| the same footage as a saved video (sampled frames) | 3,708 | sampled (all confirmed) |
| probably a copy of a saved file (the same size): marked done before ix… without a record | 2,144 | unlinked-copy |
| looks like a copy of a queued file | 1,228 | queued (1,142 unconfirmed, 82 confirmed) |
| probably a copy of a saved file (more than one saved file has its size): marked done before… | 322 | unlinked-copy |
| partly the same footage as a saved video (sampled frames) | 81 | sampled-partial (113 unconfirmed rows; see 3c) |

Reasons in the code that hold no rows today: 'looks like a saved copy (its album matches a saved album)'.

Errors on open rows (last error only):
- pending: timeout 17, file reference 6, deadline 2, wait 1;
- processing: other 11, deadline 3, file reference 2.

### 3c. Known not to add up, and why
1. **Completed work rows ≠ saved-file rows.** Of 235,411 completed rows:
   - 183,244 have their own `downloads` row;
   - 43,300 have none but are linked (`ix_msg_link` or `ix_subst`);
   - 8,786 have none and no link, but **the same Telegram file is saved under another message**: linked in effect,
     not recorded (older versions did not write `ix_msg_link`);
   - **82** have none, and their Telegram file is saved nowhere. These are true orphans: treat them as not saved.
2. **Saved-file rows with no work row:** 1,116 (document 1,036, photo 80). They were saved before the work table
   existed or came in by import. Do not invent work rows for them.
3. **Open rows whose message already has a saved file:** 2,226, all pending, held and paused.
   - 2,171 have the same identity. These are re-queued copies: a newer `tgdl_message_generations` generation, with a
     hold kept at the back.
   - 55 have a newer generation (an edit).
   - Check: 183,244 + 1,116 + 2,226 = 186,586, the `downloads` count at that moment.
4. **Open rows whose Telegram file is already saved:** 17,093 of 48,610 pending rows. The fork would link them at
   claim (no transfer). They are not work to do: **mark them "already have"**.
5. **Stale side rows, safe to drop or to carry as history only:**
   - `ix_copy_hold`: 1,652 rows whose hold is no longer current;
   - `ix_deferred`: 34,039 rows already released (all 2,407 open ones belong to pending rows);
   - `ix_held` rows -1 and >0: their work rows are mostly completed (61,279 and 1,724);
   - `ix_part_store`: 34 files whose identity is already completed (dead weight; deleted by the fork's sweep).
   - The 113 'sampled-partial' rows in `ix_copy_hold` against 81 held: 32 belong to rows held under another reason.
6. **New files in saved messages with no work row:** 40,503 messages with a file have neither a work row nor a
   `downloads` row. The first answers file found about 26,400 distinct new files among them; the rest are copies by
   Telegram file. **This is the discovery backlog, not a fault.**
7. **`tgdl_work.dc` = 0** on 78,591 completed rows: unknown, not a server.

## 4. The library on disk

As written today (`destinationParts` in `internal/download/library.go`):

```
<library root>/<chat folder>/[<topic folder>/]<type folder>/<name stem>_<message id>_<32 hex><ext>
```

- **`<library root>`:** `TGDL_DOWNLOADS_DIR` from the launcher, or `<data>/downloads` if it is not set.
- **`<chat folder>`:** the chat's name **as it was when that file was saved**, made safe:
  - control characters and `/\:*?"<>|` become `_`;
  - leading and trailing spaces and dots are trimmed;
  - it is cut to 120 bytes (whole characters);
  - an empty name becomes `media`;
  - when the chat has no name, its marked id is used.
  - 172 top folders for 179 chats. 2 chats have files in two top folders (renamed). 0 files are under a bare-id
    folder.
- **`<topic folder>`:** a forum topic's name at its first saved file (`ix_topic_dirs`), made safe the same way. It is
  left out for no topic and for General.
  - 9,927 files sit under a topic folder (path depth 3), all with a topic in their message; 176,658 do not (depth 2).
  - Topic files saved before 12.10 sit in the chat's own type folder.
- **`<type folder>`:** `images` (photo), `videos`, `documents`, `audio`, `gifs`, `stickers`. Today: images 62,047,
  videos 124,247, documents 291.
- **File name:** the Telegram file name made safe (photos: `photo_<photo id>.jpg`), extension split off, then
  `_<message id>_` + 32 random hex digits + the extension. 186,410 of 186,586 rows follow this exactly; the other 176
  are older names.
- **Row without file, and the reverse:**
  - the fork counts neither for the whole library;
  - `ix_fixity` re-reads files in turns: 28,659 checked, 28,655 ok, **4 unreadable**, 0 missing or changed;
  - `orphansFor` looks for a file without a row only in the one folder it is about to save into.
  - A whole-library check would need a listing of the NAS, which I did not make.

## 5. Traps (what a second reader has got wrong, or would)

1. **`released_at` = -1 is not "held".** It means "looked at, not a copy". Held = `released_at=0 AND reason<>''`,
   with the work row pending and paused. A reader taking every row of `ix_held` gets 111,633 instead of 45,428.
2. **`status='completed'` does not mean "has a file row".** See 3c.1. A "saved" message is: own `downloads` row, or an
   `ix_msg_link` or `ix_subst` row, or its identity in `downloads`.
3. **`minDate` = 1 in `history_jobs` is a flag** ("read to the start of the chat"), not a date. `offsetDate` is a real
   date in seconds.
4. **`ix_settings.bigAtOnce` is stale** (12.24, whole account). 12.25 replaced it with `bigPerServer` (per server)
   and does not read the old key. Do not map it across. Absent `omitempty` keys mean "default", not "off".
5. **The chat folder is the name at save time.** Do not rebuild paths from today's name: take `file_path` as stored.
6. **`ix_group_info.kind` is '' for all 181 basic groups.** That is not "unknown channel": only the 9 forums have
   details saved.
   - Take the kind from the id's form, or from the peer in `tl` (`peerChat#36c6019a` / `peerChannel#a2a5371e`).
   - **These 181 basic groups are not in `tgdl_update_channels`.** Their updates come through the account's common
     `pts`.
7. **Two identity spellings** (colon and NUL; section 2) and the three-column form in `downloads`. Lower-case the
   kind when joining `downloads`.
8. **`downloads.created_at` is UTC text**, while everything else the fork writes is ms.
9. **`tgdl_work.body` is empty on completed rows**, and `tgdl_work.dc` is 0 on old ones. Read the server and the
   message from `ix_messages.tl`.
10. **`group_name`, `file_name`, `tgdl_group_rank.name` and `ix_peers.name` are copies of names**, taken at different
    times. The `config.groups[].name` is the user's current label.
11. **`tgdl_cluster_catalog`** mirrors `downloads` through triggers. Count it and you double the files.
12. **Read together, in one transaction**, because the fork changes them together while it runs:
    - `tgdl_work` with `ix_held`, `ix_copy_hold` and `ix_deferred`: a hold and its `paused` are set in one transaction;
    - `downloads` with `tgdl_message_generations`: a save registers both in one transaction, and the work row is
      marked completed just after;
    - `tgdl_stage_moves` with `downloads`: a staged file gets its row only when copied;
    - `ix_part_store` rows with their files: the files are written first; the sweep (`ix_part_store.go`) removes any
      part folder with no rows, and the parts of files already saved.

    The DB is WAL. One read transaction (`BEGIN` then all reads) gives one consistent snapshot without blocking the
    app. Better still, run the bring-in on a copy of the database that the owner makes with the app stopped.
13. **`chat_access` is not the chat list.** It holds every chat the account was seen in, including users (75). The
    added chats are `config.groups`.
14. **`ix_messages.media_type` 'photo' (90,105) ≠ photo keys (89,510).** Some pictures sent as documents are typed
    photo but keyed `document:`. Count files by key, not by type.
15. **Free-text columns** (`error`, `ix_held.reason`, `tgdl_stage_moves.error`): only the last value is kept, and the
    wording changed between versions (for example the 'marked done before ix…' reasons). Map by the fixed phrases in
    3b, with "other" as a fallback.

## How this was measured
- Read-only Python `sqlite3` with `?mode=ro`, `PRAGMA query_only=1` and a 60–120 s limit per query, run with
  `python -I -X utf8`. Only counts, lengths, magnitudes, public constants and fixed words were printed. Category
  values passed a letters-only filter.
- One join (hold keys against saved hashes, with no index) ran past its limit. I stopped it and redid it in Python
  with sets. Nothing else touched the live archive.
- The chat kind was checked by finding `peerChat#36c6019a` or `peerChannel#a2a5371e` + the bare id in one `tl` of
  each chat: 181 + 9, no exceptions.
- Code read: `ix_record.go`, `engine/work.go`, `telegram/dedup.go`, `telegram/attachment.go`,
  `download/library.go`, `download/resume.go`, `download/manager.go`, `ix_part_store.go`, `ix_held.go`,
  `ix_vdup.go`, `ix_sample_recheck.go`, `ix_copies_ml.go`, `ix_faces.go`, `ix_sched.go`, `ix_safety.go`,
  `ix_data.go`, `ix_notadded.go`, `ix_dedup.go`.
