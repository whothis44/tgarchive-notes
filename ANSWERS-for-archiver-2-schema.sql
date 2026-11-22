-- Layout of the fork's database (ix.12.29, live), from sqlite_master, read-only on 2026-11-13 01:19 local.
-- No row content. Row counts are comments. Runs as is in an empty database (checked with Python's sqlite3).
-- PRAGMA user_version=0; journal_mode=wal; page_size=4096. tgdl_schema_meta.version=1.
-- fts5 shadow tables are made by their virtual table and are listed as comments only: downloads_fts_config, downloads_fts_data, downloads_fts_docsize, downloads_fts_idx, ix_fts_config, ix_fts_data, ix_fts_docsize, ix_fts_idx, ix_ocr_fts_config, ix_ocr_fts_content, ix_ocr_fts_data, ix_ocr_fts_docsize, ix_ocr_fts_idx, ix_stt_fts_config, ix_stt_fts_content, ix_stt_fts_data, ix_stt_fts_docsize, ix_stt_fts_idx.
-- sqlite_sequence is SQLite's own.

-- backup_destinations: 0 rows
CREATE TABLE backup_destinations (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            name            TEXT    NOT NULL,
            provider        TEXT    NOT NULL,
            config_blob     BLOB    NOT NULL,
            enabled         INTEGER NOT NULL DEFAULT 1,
            encryption      INTEGER NOT NULL DEFAULT 0,
            encryption_salt BLOB,
            mode            TEXT    NOT NULL DEFAULT 'mirror',
            cron            TEXT,
            retain_count    INTEGER DEFAULT 7,
            last_success_at INTEGER,
            last_failure_at INTEGER,
            last_error      TEXT,
            total_bytes     INTEGER NOT NULL DEFAULT 0,
            total_files     INTEGER NOT NULL DEFAULT 0,
            throttle_bps    INTEGER,
            created_at      INTEGER NOT NULL
        );

-- backup_jobs: 0 rows
CREATE TABLE backup_jobs (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            destination_id  INTEGER NOT NULL,
            download_id     INTEGER,
            snapshot_path   TEXT,
            status          TEXT    NOT NULL DEFAULT 'pending',
            attempts        INTEGER NOT NULL DEFAULT 0,
            max_attempts    INTEGER NOT NULL DEFAULT 5,
            next_retry_at   INTEGER,
            started_at      INTEGER,
            finished_at     INTEGER,
            bytes_uploaded  INTEGER NOT NULL DEFAULT 0,
            error           TEXT,
            remote_path     TEXT,
            FOREIGN KEY (destination_id) REFERENCES backup_destinations(id) ON DELETE CASCADE,
            FOREIGN KEY (download_id) REFERENCES downloads(id) ON DELETE CASCADE
        );

-- chat_access: 378 rows
CREATE TABLE chat_access (
                chat_id       TEXT    PRIMARY KEY,
                state         TEXT    NOT NULL,
                code          TEXT,
                detail        TEXT,
                migrated_to   TEXT,
                first_seen_at INTEGER,
                checked_at    INTEGER NOT NULL,
                next_check_at INTEGER,
                checks        INTEGER NOT NULL DEFAULT 0,
                accounts      TEXT,
                updated_at    INTEGER NOT NULL
            );

-- cluster_audit: 0 rows
CREATE TABLE cluster_audit (
            id      INTEGER PRIMARY KEY AUTOINCREMENT,
            ts      INTEGER NOT NULL,
            peer_id TEXT,
            kind    TEXT    NOT NULL,
            detail  TEXT,
            ok      INTEGER NOT NULL DEFAULT 1
        );

-- cluster_egress_log: 0 rows
CREATE TABLE cluster_egress_log (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            peer_id     TEXT,
            bytes       INTEGER NOT NULL,
            served_at   INTEGER NOT NULL,
            from_cache  INTEGER NOT NULL DEFAULT 0
        );

-- downloads: 186586 rows
CREATE TABLE downloads (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            group_id TEXT NOT NULL,
            group_name TEXT,
            message_id INTEGER NOT NULL,
            file_name TEXT,
            file_size INTEGER,
            file_type TEXT, -- photo, video, document
            file_path TEXT,
            status TEXT DEFAULT 'completed',
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP, ttl_seconds INTEGER, file_hash TEXT, pinned INTEGER DEFAULT 0, pending_until INTEGER, rescued_at INTEGER, nsfw_score REAL, nsfw_checked_at INTEGER, nsfw_whitelist INTEGER DEFAULT 0, telegram_media_kind TEXT, telegram_media_id TEXT, telegram_media_size INTEGER, ai_indexed_at INTEGER, owner_peer_id TEXT, telegram_mime TEXT, media_width INTEGER, media_height INTEGER, media_duration_ms INTEGER, forward_origin TEXT, telegram_thumb BLOB,
            UNIQUE(group_id, message_id)
        );

-- downloads_fts: 186586 rows
CREATE VIRTUAL TABLE downloads_fts USING fts5(
                file_name, group_name,
                content='downloads',
                content_rowid='id'
            );

-- faces: 0 rows
CREATE TABLE faces (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            download_id INTEGER NOT NULL,
            x           REAL    NOT NULL,
            y           REAL    NOT NULL,
            w           REAL    NOT NULL,
            h           REAL    NOT NULL,
            embedding   BLOB    NOT NULL,
            person_id   INTEGER, quality_score REAL, exif_oriented INTEGER, frame_time_sec REAL, gender TEXT,
            FOREIGN KEY (download_id) REFERENCES downloads(id) ON DELETE CASCADE,
            FOREIGN KEY (person_id)   REFERENCES people(id)    ON DELETE SET NULL
        );

-- image_embeddings: 0 rows
CREATE TABLE image_embeddings (
            download_id INTEGER PRIMARY KEY,
            embedding   BLOB    NOT NULL,
            model       TEXT    NOT NULL,
            indexed_at  INTEGER NOT NULL,
            FOREIGN KEY (download_id) REFERENCES downloads(id) ON DELETE CASCADE
        );

-- image_tags: 0 rows
CREATE TABLE image_tags (
            download_id INTEGER NOT NULL,
            tag         TEXT    NOT NULL,
            score       REAL    NOT NULL,
            PRIMARY KEY (download_id, tag),
            FOREIGN KEY (download_id) REFERENCES downloads(id) ON DELETE CASCADE
        );

-- ix_absent: 1 rows
CREATE TABLE ix_absent ( -- message IDs Telegram says are gone
	group_id   TEXT    NOT NULL,
	message_id INTEGER NOT NULL,
	checked_at INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY (group_id, message_id)
);

-- ix_album_orphan: 0 rows
CREATE TABLE ix_album_orphan ( -- a lone file a person said is not part of the album beside it
	post     TEXT PRIMARY KEY, -- <group>:<message> of the lone file
	decision TEXT NOT NULL,    -- out
	at       INTEGER NOT NULL DEFAULT 0
);

-- ix_album_pairs: 0 rows
CREATE TABLE ix_album_pairs ( -- two albums a person said are, or are not, the same
	post_a   TEXT NOT NULL, -- first posts of the two albums, post_a < post_b
	post_b   TEXT NOT NULL,
	decision TEXT NOT NULL, -- same, different
	at       INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY (post_a, post_b)
);

-- ix_alerts: 0 rows
CREATE TABLE ix_alerts (
	key     TEXT PRIMARY KEY,
	sent_at INTEGER NOT NULL DEFAULT 0
);

-- ix_check_putback: 3 rows
CREATE TABLE ix_check_putback ( -- ix.12.26: big videos put back because their check had no answer under the speed limit
	work_id    INTEGER PRIMARY KEY,
	first_at   INTEGER NOT NULL DEFAULT 0, -- first put back (unix ms): the bound counts from it
	last_at    INTEGER NOT NULL DEFAULT 0,
	times      INTEGER NOT NULL DEFAULT 0,
	why        TEXT    NOT NULL DEFAULT '' -- the last reason, a category
);

-- ix_copy_hold: 47080 rows
CREATE TABLE ix_copy_hold ( -- more about held queue items (ix_held), by queue item
	work_id      INTEGER PRIMARY KEY,
	how          TEXT    NOT NULL DEFAULT '', -- saved, queued, recognition
	of_work      INTEGER NOT NULL DEFAULT 0,  -- queued: the queue item it is probably a lesser copy of
	sim          REAL    NOT NULL DEFAULT 0,  -- recognition: likeness of the previews (cosine)
	confirm      TEXT    NOT NULL DEFAULT '', -- '', confirmed, unconfirmed
	confirm_note TEXT    NOT NULL DEFAULT '',
	checked_at   INTEGER NOT NULL DEFAULT 0
);

-- ix_copy_sample: 19100 rows
CREATE TABLE ix_copy_sample ( -- big queued videos checked by frames sampled across the file
	work_id    INTEGER PRIMARY KEY,
	ident      TEXT    NOT NULL DEFAULT '',
	size       INTEGER NOT NULL DEFAULT 0,  -- the file's size
	result     TEXT    NOT NULL DEFAULT '', -- confirmed, nomatch, failed
	note       TEXT    NOT NULL DEFAULT '',
	of_key     TEXT    NOT NULL DEFAULT '', -- confirmed: the saved file
	offset_s   REAL    NOT NULL DEFAULT 0,
	parts      INTEGER NOT NULL DEFAULT 0,  -- 1 MiB parts read from Telegram, all tries
	samples    INTEGER NOT NULL DEFAULT 0,
	tries      INTEGER NOT NULL DEFAULT 0,
	at         INTEGER NOT NULL DEFAULT 0
, reason TEXT NOT NULL DEFAULT '', final INTEGER NOT NULL DEFAULT 0, frames BLOB, dur_ms INTEGER NOT NULL DEFAULT 0);

-- ix_copy_thumb: 13790 rows
CREATE TABLE ix_copy_thumb ( -- Telegram's small previews of queued files
	ident      TEXT    PRIMARY KEY, -- the file's Telegram identity (kind:id:size)
	group_id   TEXT    NOT NULL DEFAULT '',
	message_id INTEGER NOT NULL DEFAULT 0,
	path       TEXT    NOT NULL DEFAULT '', -- under the data folder's ixpreviews
	w          INTEGER NOT NULL DEFAULT 0,
	h          INTEGER NOT NULL DEFAULT 0,
	bytes      INTEGER NOT NULL DEFAULT 0,
	model      TEXT    NOT NULL DEFAULT '',
	vec        BLOB,
	error      TEXT    NOT NULL DEFAULT '',
	tries      INTEGER NOT NULL DEFAULT 0,
	at         INTEGER NOT NULL DEFAULT 0
);

-- ix_dedup_daily: 42 rows
CREATE TABLE ix_dedup_daily ( -- duplicates by how they were found, per day (ix_dedup.go)
	day   TEXT    NOT NULL, -- YYYY-MM-DD in the archive's time zone
	how   TEXT    NOT NULL,
	files INTEGER NOT NULL DEFAULT 0,
	bytes INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY (day, how)
);

-- ix_deferred: 36446 rows
CREATE TABLE ix_deferred ( -- queue items put back so smaller ones go first
	work_id     INTEGER PRIMARY KEY,
	band        INTEGER NOT NULL,
	deferred_at INTEGER NOT NULL DEFAULT 0,
	released_at INTEGER NOT NULL DEFAULT 0
);

-- ix_emb: 169019 rows
CREATE TABLE ix_emb ( -- image embeddings (int8, L2-normalised before scaling)
	key   TEXT PRIMARY KEY,
	model TEXT NOT NULL,
	dim   INTEGER NOT NULL,
	vec   BLOB NOT NULL,
	at    INTEGER NOT NULL DEFAULT 0
);

-- ix_emb_err: 184 rows
CREATE TABLE ix_emb_err (
	key   TEXT PRIMARY KEY,
	model TEXT NOT NULL,
	error TEXT NOT NULL DEFAULT '',
	tries INTEGER NOT NULL DEFAULT 0,
	at    INTEGER NOT NULL DEFAULT 0
);

-- ix_emb_frames: 706525 rows
CREATE TABLE ix_emb_frames ( -- embeddings of distinct video frames (int8, like ix_emb)
	key   TEXT    NOT NULL,
	model TEXT    NOT NULL,
	t_ms  INTEGER NOT NULL, -- where the frame is in the video
	vec   BLOB    NOT NULL,
	PRIMARY KEY (key, t_ms)
);

-- ix_face_done: 113443 rows
CREATE TABLE ix_face_done (
	key   TEXT PRIMARY KEY,
	model TEXT NOT NULL,
	faces INTEGER NOT NULL DEFAULT 0,
	at    INTEGER NOT NULL DEFAULT 0
);

-- ix_face_meta: 2 rows
CREATE TABLE ix_face_meta (
	k TEXT PRIMARY KEY,
	v TEXT NOT NULL DEFAULT ''
);

-- ix_face_prev: 0 rows
CREATE TABLE ix_face_prev (
	face   INTEGER PRIMARY KEY, -- while grouping again: the person a face was with
	person INTEGER NOT NULL
);

-- ix_face_reject: 0 rows
CREATE TABLE ix_face_reject (
	face   INTEGER NOT NULL,
	person INTEGER NOT NULL, -- as it was then; a person merged since is the one merged into
	at     INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY (face, person)
);

-- ix_faces: 80060 rows
CREATE TABLE ix_faces (
	id     INTEGER PRIMARY KEY AUTOINCREMENT,
	key    TEXT    NOT NULL,
	model  TEXT    NOT NULL,
	x1 REAL NOT NULL, y1 REAL NOT NULL, x2 REAL NOT NULL, y2 REAL NOT NULL, -- share of the picture's width and height
	score  REAL    NOT NULL DEFAULT 0,
	vec    BLOB    NOT NULL,
	person INTEGER NOT NULL DEFAULT 0, -- 0: not grouped yet; -1: a person said it is nobody known
	manual INTEGER NOT NULL DEFAULT 0, -- placed by a person
	at     INTEGER NOT NULL DEFAULT 0
, frame INTEGER NOT NULL DEFAULT 0, px REAL NOT NULL DEFAULT 0, blur REAL NOT NULL DEFAULT -1);

-- ix_fixity: 28703 rows
CREATE TABLE ix_fixity ( -- the last integrity check of each stored file
	path       TEXT PRIMARY KEY,
	size       INTEGER NOT NULL DEFAULT 0,
	sha256     TEXT    NOT NULL DEFAULT '',
	checked_at INTEGER NOT NULL DEFAULT 0,
	result     TEXT    NOT NULL DEFAULT ''
);

-- ix_fixity_events: 4 rows
CREATE TABLE ix_fixity_events (
	at      INTEGER NOT NULL,
	path    TEXT    NOT NULL,
	result  TEXT    NOT NULL, -- ok, changed, missing, size, unreadable
	detail  TEXT    NOT NULL DEFAULT ''
);

-- ix_fts: 401270 rows
CREATE VIRTUAL TABLE ix_fts USING fts5(text, content='ix_messages', content_rowid='rowid', tokenize='unicode61 remove_diacritics 2');

-- ix_group_info: 190 rows
CREATE TABLE ix_group_info (
	group_id     TEXT PRIMARY KEY,
	title        TEXT    NOT NULL DEFAULT '',
	kind         TEXT    NOT NULL DEFAULT '', -- channel, supergroup, forum or group
	about        TEXT    NOT NULL DEFAULT '',
	username     TEXT    NOT NULL DEFAULT '',
	members      INTEGER NOT NULL DEFAULT 0,
	pinned_id    INTEGER NOT NULL DEFAULT 0,
	linked_group TEXT    NOT NULL DEFAULT '',
	info_at      INTEGER NOT NULL DEFAULT 0,
	tl           BLOB,
	tg_count     INTEGER NOT NULL DEFAULT 0,
	tg_count_at  INTEGER NOT NULL DEFAULT 0,
	finished_at  INTEGER NOT NULL DEFAULT 0 -- marked finished: rescans leave it alone
, invite_link TEXT NOT NULL DEFAULT '');

-- ix_held: 111633 rows
CREATE TABLE ix_held ( -- queued files held back as probable copies
	work_id    INTEGER PRIMARY KEY,
	group_id   TEXT    NOT NULL,
	message_id INTEGER NOT NULL,
	like_path  TEXT    NOT NULL DEFAULT '',
	like_key   TEXT    NOT NULL DEFAULT '',
	reason     TEXT    NOT NULL DEFAULT '',
	held_at    INTEGER NOT NULL DEFAULT 0,
	released_at INTEGER NOT NULL DEFAULT 0
);

-- ix_lowq: 0 rows
CREATE TABLE ix_lowq ( -- big videos saved in a lower quality first
	group_id    TEXT NOT NULL,
	message_id  INTEGER NOT NULL,
	work_id     INTEGER NOT NULL,
	orig_id     TEXT NOT NULL,              -- the original's Telegram document
	orig_size   INTEGER NOT NULL,
	alt_id      TEXT NOT NULL,              -- the lower quality's
	alt_size    INTEGER NOT NULL,
	alt_short   INTEGER NOT NULL DEFAULT 0, -- its shorter side, 0: unknown
	alt_cost    INTEGER NOT NULL DEFAULT 0, -- bytes downloaded for it (0: it was saved already)
	alt_path    TEXT NOT NULL DEFAULT '',
	keep        INTEGER NOT NULL DEFAULT 0, -- keep the lower quality after the upgrade
	state       TEXT NOT NULL DEFAULT 'saved', -- saved (original to come), released (original queued now), upgraded, kept, dropped
	saved_at    INTEGER NOT NULL DEFAULT 0,
	released_at INTEGER NOT NULL DEFAULT 0,
	upgraded_at INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY (group_id, message_id)
);

-- ix_mcl: 61767 rows
CREATE TABLE ix_mcl ( -- picture clusters: each file and the leader it joined
	key      TEXT PRIMARY KEY,
	cluster  TEXT    NOT NULL,
	how      TEXT    NOT NULL DEFAULT '', -- leader, auto, verified
	distance INTEGER NOT NULL DEFAULT 0
);

-- ix_media_counts: 0 rows
CREATE TABLE ix_media_counts (
	chat_id    TEXT PRIMARY KEY,
	photos     INTEGER NOT NULL DEFAULT 0,
	videos     INTEGER NOT NULL DEFAULT 0,
	files      INTEGER NOT NULL DEFAULT 0,
	audio      INTEGER NOT NULL DEFAULT 0,
	inexact    INTEGER NOT NULL DEFAULT 0,
	error      TEXT    NOT NULL DEFAULT '',
	counted_at INTEGER NOT NULL DEFAULT 0
);

-- ix_message_edits: 0 rows
CREATE TABLE ix_message_edits (
	group_id    TEXT    NOT NULL,
	message_id  INTEGER NOT NULL,
	edit_date   INTEGER NOT NULL DEFAULT 0,
	text        TEXT    NOT NULL DEFAULT '',
	recorded_at INTEGER NOT NULL DEFAULT 0
);

-- ix_messages: 401270 rows
CREATE TABLE ix_messages (
	group_id    TEXT    NOT NULL,
	message_id  INTEGER NOT NULL,
	date        INTEGER NOT NULL DEFAULT 0,
	edit_date   INTEGER NOT NULL DEFAULT 0,
	text        TEXT    NOT NULL DEFAULT '',
	grouped_id  TEXT    NOT NULL DEFAULT '',
	sender_id   TEXT    NOT NULL DEFAULT '',
	post_author TEXT    NOT NULL DEFAULT '',
	fwd_from    TEXT    NOT NULL DEFAULT '',
	fwd_date    INTEGER NOT NULL DEFAULT 0,
	reply_to    INTEGER NOT NULL DEFAULT 0,
	topic_id    INTEGER NOT NULL DEFAULT 0,
	media_type  TEXT    NOT NULL DEFAULT '',
	media_name  TEXT    NOT NULL DEFAULT '',
	media_size  INTEGER NOT NULL DEFAULT 0,
	media_key   TEXT    NOT NULL DEFAULT '',
	views       INTEGER NOT NULL DEFAULT 0,
	tl          BLOB,
	first_seen  INTEGER NOT NULL DEFAULT 0,
	seen_at     INTEGER NOT NULL DEFAULT 0,
	deleted_at  INTEGER NOT NULL DEFAULT 0, service TEXT NOT NULL DEFAULT '', comments INTEGER NOT NULL DEFAULT 0, comment_on TEXT NOT NULL DEFAULT '',
	PRIMARY KEY (group_id, message_id)
);

-- ix_ml_err: 226 rows
CREATE TABLE ix_ml_err (
	task  TEXT NOT NULL,
	key   TEXT NOT NULL,
	model TEXT NOT NULL,
	error TEXT NOT NULL DEFAULT '',
	tries INTEGER NOT NULL DEFAULT 0,
	at    INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY (task, key)
);

-- ix_move_plans: 0 rows
CREATE TABLE ix_move_plans (
	id         INTEGER PRIMARY KEY AUTOINCREMENT,
	kind       TEXT    NOT NULL,
	title      TEXT    NOT NULL DEFAULT '',
	state      TEXT    NOT NULL DEFAULT 'planned', -- planned, applying, applied, undoing, undone, failed
	created_at INTEGER NOT NULL DEFAULT 0,
	applied_at INTEGER NOT NULL DEFAULT 0,
	undone_at  INTEGER NOT NULL DEFAULT 0,
	error      TEXT    NOT NULL DEFAULT ''
);

-- ix_moves: 0 rows
CREATE TABLE ix_moves (
	plan_id INTEGER NOT NULL,
	seq     INTEGER NOT NULL,
	op      TEXT    NOT NULL, -- copy, move, trash
	src     TEXT    NOT NULL,
	dst     TEXT    NOT NULL,
	sha256  TEXT    NOT NULL DEFAULT '',
	size    INTEGER NOT NULL DEFAULT 0,
	repoint TEXT    NOT NULL DEFAULT '', -- downloads rows at src now point here
	state   TEXT    NOT NULL DEFAULT 'planned', -- planned, running, done, failed, undone
	error   TEXT    NOT NULL DEFAULT '',
	at      INTEGER NOT NULL DEFAULT 0, rows TEXT NOT NULL DEFAULT '', src_stored TEXT NOT NULL DEFAULT '',
	PRIMARY KEY (plan_id, seq)
);

-- ix_msg_link: 44455 rows
CREATE TABLE ix_msg_link ( -- messages sharing a saved file (ix_links.go)
	group_id   TEXT    NOT NULL,
	message_id INTEGER NOT NULL,
	how        TEXT    NOT NULL DEFAULT '', -- telegram-file, exact-reupload, after-download
	of_path    TEXT    NOT NULL DEFAULT '', -- the saved file
	sha256     TEXT    NOT NULL DEFAULT '',
	size       INTEGER NOT NULL DEFAULT 0,
	tg_file    TEXT    NOT NULL DEFAULT '', -- the message's own Telegram file, kind:id:size
	name       TEXT    NOT NULL DEFAULT '',
	type       TEXT    NOT NULL DEFAULT '',
	at         INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY (group_id, message_id)
);

-- ix_msug: 43355 rows
CREATE TABLE ix_msug ( -- close pairs a person should look at
	key_a    TEXT    NOT NULL,
	key_b    TEXT    NOT NULL,
	kind     TEXT    NOT NULL DEFAULT '', -- photo, video
	distance REAL    NOT NULL DEFAULT 0,
	found_at INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY (key_a, key_b)
);

-- ix_ocr: 113284 rows
CREATE TABLE ix_ocr (
	key   TEXT PRIMARY KEY,
	model TEXT NOT NULL,
	text  TEXT NOT NULL DEFAULT '',
	at    INTEGER NOT NULL DEFAULT 0
);

-- ix_ocr_fts: 34230 rows
CREATE VIRTUAL TABLE ix_ocr_fts USING fts5(text, tokenize='unicode61 remove_diacritics 2');

-- ix_org_collections: 0 rows
CREATE TABLE ix_org_collections (
	id         INTEGER PRIMARY KEY AUTOINCREMENT,
	name       TEXT    NOT NULL,
	created_at INTEGER NOT NULL DEFAULT 0
);

-- ix_org_items: 0 rows
CREATE TABLE ix_org_items (
	collection_id INTEGER NOT NULL,
	ref           TEXT    NOT NULL, -- post:<group>:<message> or file:<key>
	added_at      INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY (collection_id, ref)
);

-- ix_org_keeper: 0 rows
CREATE TABLE ix_org_keeper ( -- the copy to show for a set of duplicates
	cluster TEXT PRIMARY KEY,
	key     TEXT NOT NULL
);

-- ix_org_pairs: 0 rows
CREATE TABLE ix_org_pairs ( -- review decisions on two files
	key_a      TEXT NOT NULL,
	key_b      TEXT NOT NULL,
	decision   TEXT NOT NULL, -- same, different
	decided_at INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY (key_a, key_b)
);

-- ix_org_set_items: 0 rows
CREATE TABLE ix_org_set_items ( -- a file said to belong to a set, or not
	anchor   TEXT NOT NULL, -- the set's first post
	key      TEXT NOT NULL,
	decision TEXT NOT NULL, -- in, out
	at       INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY (anchor, key)
);

-- ix_org_set_posts: 0 rows
CREATE TABLE ix_org_set_posts ( -- a post taken out of sets, or tied to another
	post  TEXT PRIMARY KEY, -- <group>:<message>
	mode  TEXT NOT NULL,    -- alone, tie
	other TEXT NOT NULL DEFAULT '',
	at    INTEGER NOT NULL DEFAULT 0
);

-- ix_part_store: 33020 rows
CREATE TABLE ix_part_store ( -- 1 MiB parts a check read from Telegram, kept for the download (ix.12.11)
	ident  TEXT    NOT NULL, -- the file's Telegram identity (kind:id:size)
	part   INTEGER NOT NULL, -- offset / 1 MiB
	bytes  INTEGER NOT NULL,
	sha256 TEXT    NOT NULL,
	at     INTEGER NOT NULL,
	PRIMARY KEY (ident, part)
);

-- ix_pdq: 61773 rows
CREATE TABLE ix_pdq ( -- one row per unique picture file
	key        TEXT PRIMARY KEY,
	file_path  TEXT    NOT NULL DEFAULT '',
	hash       BLOB,               -- PDQ, 32 bytes
	quality    INTEGER NOT NULL DEFAULT 0,
	width      INTEGER NOT NULL DEFAULT 0,
	height     INTEGER NOT NULL DEFAULT 0,
	luma       BLOB,               -- 32x32 grey, for checking close matches
	thumb      TEXT    NOT NULL DEFAULT '',
	status     TEXT    NOT NULL DEFAULT '',
	error      TEXT    NOT NULL DEFAULT '',
	updated_at INTEGER NOT NULL DEFAULT 0
);

-- ix_peers: 1474 rows
CREATE TABLE ix_peers (
	peer_id    TEXT PRIMARY KEY,
	kind       TEXT NOT NULL DEFAULT '',
	name       TEXT NOT NULL DEFAULT '',
	username   TEXT NOT NULL DEFAULT '',
	updated_at INTEGER NOT NULL DEFAULT 0
);

-- ix_people: 3749 rows
CREATE TABLE ix_people (
	id          INTEGER PRIMARY KEY AUTOINCREMENT,
	name        TEXT    NOT NULL DEFAULT '',
	hidden      INTEGER NOT NULL DEFAULT 0,
	merged_into INTEGER NOT NULL DEFAULT 0,
	created_at  INTEGER NOT NULL DEFAULT 0,
	updated_at  INTEGER NOT NULL DEFAULT 0
, cover INTEGER NOT NULL DEFAULT 0, auto_cover INTEGER NOT NULL DEFAULT 0);

-- ix_person_pair: 200 rows
CREATE TABLE ix_person_pair (
	a     INTEGER NOT NULL, -- a < b
	b     INTEGER NOT NULL,
	sim   REAL    NOT NULL DEFAULT 0,
	state TEXT    NOT NULL DEFAULT 'ask', -- ask: "same person?"; no: a person said they are different
	at    INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY (a, b)
);

-- ix_retry: 57 rows
CREATE TABLE ix_retry (
	work_key TEXT PRIMARY KEY,
	rounds   INTEGER NOT NULL DEFAULT 0,
	last_at  INTEGER NOT NULL DEFAULT 0
);

-- ix_set_sug: 11766 rows
CREATE TABLE ix_set_sug ( -- lone files that look like they belong with an album
	post     TEXT PRIMARY KEY, -- <group>:<message> of the lone file's post
	key      TEXT NOT NULL,    -- the lone file
	other    TEXT NOT NULL,    -- first post of the album it looks like
	score    REAL NOT NULL DEFAULT 0,
	margin   REAL NOT NULL DEFAULT 0,
	why      TEXT NOT NULL DEFAULT '',
	decision TEXT NOT NULL DEFAULT '', -- '' to review, yes, no
	found_at INTEGER NOT NULL DEFAULT 0,
	at       INTEGER NOT NULL DEFAULT 0
);

-- ix_set_sug_seen: 24864 rows
CREATE TABLE ix_set_sug_seen ( -- lone files already compared, and against how many others
	key   TEXT PRIMARY KEY,
	model TEXT NOT NULL,
	size  INTEGER NOT NULL DEFAULT 0
);

-- ix_stt: 0 rows
CREATE TABLE ix_stt (
	key      TEXT PRIMARY KEY,
	model    TEXT NOT NULL,
	language TEXT NOT NULL DEFAULT '',
	text     TEXT NOT NULL DEFAULT '',
	segments TEXT NOT NULL DEFAULT '', -- JSON: [[start_s, end_s, text], ...]
	at       INTEGER NOT NULL DEFAULT 0
);

-- ix_stt_fts: 0 rows
CREATE VIRTUAL TABLE ix_stt_fts USING fts5(text, tokenize='unicode61 remove_diacritics 2');

-- ix_subst: 4780 rows
CREATE TABLE ix_subst ( -- files not downloaded because the library already has them
	group_id   TEXT    NOT NULL,
	message_id INTEGER NOT NULL,
	identity   TEXT    NOT NULL DEFAULT '',
	size       INTEGER NOT NULL DEFAULT 0,
	of_path    TEXT    NOT NULL DEFAULT '',
	how        TEXT    NOT NULL DEFAULT '', -- telegram-hashes, sampled-parts
	at         INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY (group_id, message_id)
);

-- ix_subst_block: 0 rows
CREATE TABLE ix_subst_block ( -- identities to download for real
	identity TEXT PRIMARY KEY
);

-- ix_topic_dirs: 94 rows
CREATE TABLE ix_topic_dirs ( -- the folder of each forum topic, named at its first file
	group_id TEXT    NOT NULL,
	topic_id INTEGER NOT NULL,
	dir      TEXT    NOT NULL,
	at       INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY (group_id, topic_id)
);

-- ix_topic_rank: 9 rows
CREATE TABLE ix_topic_rank ( -- topics with a place of their own on the ranking (ix_topic_rank.go)
	group_id   TEXT    NOT NULL,
	topic_id   INTEGER NOT NULL,
	place      INTEGER NOT NULL, -- goes with the group ranked here (1 is first)
	updated_at INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY (group_id, topic_id)
);

-- ix_topics: 100 rows
CREATE TABLE ix_topics (
	group_id   TEXT    NOT NULL,
	topic_id   INTEGER NOT NULL,
	title      TEXT    NOT NULL DEFAULT '',
	title_date INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY (group_id, topic_id)
);

-- ix_vband: 0 rows
CREATE TABLE ix_vband (
	band INTEGER NOT NULL,
	v    INTEGER NOT NULL,
	key  TEXT    NOT NULL
);

-- ix_vdup: 92569 rows
CREATE TABLE ix_vdup (
	key_a    TEXT    NOT NULL,
	key_b    TEXT    NOT NULL,
	kind     TEXT    NOT NULL DEFAULT '',
	score    REAL    NOT NULL DEFAULT 0,
	matched  INTEGER NOT NULL DEFAULT 0,
	offset_s REAL    NOT NULL DEFAULT 0,
	found_at INTEGER NOT NULL DEFAULT 0, cover_a REAL NOT NULL DEFAULT 0, cover_b REAL NOT NULL DEFAULT 0,
	PRIMARY KEY (key_a, key_b)
);

-- ix_vfp: 119639 rows
CREATE TABLE ix_vfp (
	key        TEXT PRIMARY KEY,
	file_path  TEXT    NOT NULL DEFAULT '',
	duration   REAL    NOT NULL DEFAULT 0,
	frames     BLOB,
	status     TEXT    NOT NULL DEFAULT '',
	error      TEXT    NOT NULL DEFAULT '',
	updated_at INTEGER NOT NULL DEFAULT 0
, ver INTEGER NOT NULL DEFAULT 1);

-- ix_walks: 537 rows
CREATE TABLE ix_walks (
	job_id      TEXT PRIMARY KEY,
	group_id    TEXT    NOT NULL,
	started_at  INTEGER NOT NULL DEFAULT 0,
	finished_at INTEGER NOT NULL DEFAULT 0,
	processed   INTEGER NOT NULL DEFAULT 0,
	marked_deleted INTEGER NOT NULL DEFAULT 0,
	state       TEXT    NOT NULL DEFAULT ''
);

-- kv: 15 rows
CREATE TABLE kv (
            key        TEXT    PRIMARY KEY,
            value      TEXT    NOT NULL,
            updated_at INTEGER NOT NULL
        );

-- native_backup_host_keys: 0 rows
CREATE TABLE native_backup_host_keys(address TEXT PRIMARY KEY,public_key BLOB NOT NULL);

-- native_backup_retention: 0 rows
CREATE TABLE native_backup_retention(job_id INTEGER PRIMARY KEY REFERENCES backup_jobs(id) ON DELETE CASCADE);

-- native_backup_staging: 0 rows
CREATE TABLE native_backup_staging(name TEXT PRIMARY KEY);

-- native_backup_state: 0 rows
CREATE TABLE native_backup_state(
 destination_id INTEGER PRIMARY KEY REFERENCES backup_destinations(id) ON DELETE CASCADE,
 paused INTEGER NOT NULL DEFAULT 0,
 last_scheduled_minute INTEGER,
 key_verifier BLOB
);

-- native_backup_transfers: 0 rows
CREATE TABLE native_backup_transfers(
 id TEXT PRIMARY KEY,destination_id INTEGER NOT NULL,provider TEXT NOT NULL,config_blob BLOB NOT NULL,
 kind TEXT NOT NULL,remote_path TEXT NOT NULL,upload_id TEXT NOT NULL DEFAULT '',state TEXT NOT NULL,
 attempts INTEGER NOT NULL DEFAULT 0,error TEXT,next_retry_at INTEGER NOT NULL DEFAULT 0,created_at INTEGER NOT NULL
);

-- native_backup_versions: 0 rows
CREATE TABLE native_backup_versions(job_id INTEGER PRIMARY KEY REFERENCES backup_jobs(id) ON DELETE CASCADE,version INTEGER NOT NULL DEFAULT 0);

-- nsfw_hash_blocklist: 0 rows
CREATE TABLE nsfw_hash_blocklist (
                file_hash  TEXT    PRIMARY KEY,
                file_name  TEXT,
                deleted_at INTEGER NOT NULL,
                source     TEXT    DEFAULT 'manual'
            );

-- peer_accounts: 0 rows
CREATE TABLE peer_accounts (
            peer_id    TEXT    PRIMARY KEY,
            payload    TEXT    NOT NULL,
            cached_at  INTEGER NOT NULL
        );

-- peer_delete_jobs: 0 rows
CREATE TABLE peer_delete_jobs (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            peer_id      TEXT    NOT NULL,
            remote_id    INTEGER NOT NULL,
            reason       TEXT,
            status       TEXT    NOT NULL DEFAULT 'pending',
            attempts     INTEGER NOT NULL DEFAULT 0,
            created_at   INTEGER NOT NULL,
            finished_at  INTEGER
        );

-- peer_discoveries: 0 rows
CREATE TABLE peer_discoveries (
            peer_id    TEXT    PRIMARY KEY,
            url        TEXT    NOT NULL,
            name       TEXT,
            version    TEXT,
            source     TEXT    NOT NULL DEFAULT 'broadcast',
            seen_at    INTEGER NOT NULL
        );

-- peer_downloads: 0 rows
CREATE TABLE peer_downloads (
            peer_id     TEXT    NOT NULL,
            remote_id   INTEGER NOT NULL,
            file_path   TEXT    NOT NULL,
            file_name   TEXT,
            file_size   INTEGER,
            file_type   TEXT,
            file_hash   TEXT,
            group_id    TEXT,
            group_name  TEXT,
            message_id  INTEGER,
            created_at  INTEGER,
            status      TEXT,
            nsfw_score  REAL,
            cached_at   INTEGER NOT NULL,
            PRIMARY KEY (peer_id, remote_id)
        );

-- peer_face_centroids: 0 rows
CREATE TABLE peer_face_centroids (
            peer_id          TEXT    NOT NULL,
            remote_person_id INTEGER NOT NULL,
            centroid         BLOB    NOT NULL,
            label            TEXT,
            face_count       INTEGER NOT NULL DEFAULT 0,
            updated_at       INTEGER NOT NULL,
            PRIMARY KEY (peer_id, remote_person_id)
        );

-- peer_failover_log: 0 rows
CREATE TABLE peer_failover_log (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            group_id     TEXT    NOT NULL,
            from_peer_id TEXT    NOT NULL,
            to_peer_id   TEXT    NOT NULL,
            reason       TEXT,
            ts           INTEGER NOT NULL
        );

-- peer_groups: 0 rows
CREATE TABLE peer_groups (
            peer_id    TEXT    PRIMARY KEY,
            payload    TEXT    NOT NULL,
            cached_at  INTEGER NOT NULL
        );

-- peer_history: 0 rows
CREATE TABLE peer_history (
            peer_id    TEXT    PRIMARY KEY,
            payload    TEXT    NOT NULL,
            cached_at  INTEGER NOT NULL
        );

-- peers: 0 rows
CREATE TABLE peers (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            peer_id      TEXT    NOT NULL UNIQUE,
            name         TEXT    NOT NULL,
            url          TEXT    NOT NULL,
            status       TEXT    NOT NULL DEFAULT 'offline',
            stream_mode  TEXT    NOT NULL DEFAULT 'proxy',
            last_seen_at INTEGER,
            paired_at    INTEGER NOT NULL,
            fingerprint  TEXT    NOT NULL,
            version      TEXT,
            notes        TEXT
        , shared_secret BLOB, role TEXT NOT NULL DEFAULT 'admin', ws_last_seen INTEGER);

-- people: 0 rows
CREATE TABLE people (
            id                 INTEGER PRIMARY KEY AUTOINCREMENT,
            label              TEXT,
            embedding_centroid BLOB    NOT NULL,
            face_count         INTEGER NOT NULL DEFAULT 0,
            created_at         INTEGER NOT NULL,
            updated_at         INTEGER NOT NULL
        , gender TEXT);

-- queue: 0 rows
CREATE TABLE queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            group_id TEXT NOT NULL,
            message_id INTEGER NOT NULL,
            meta TEXT, -- JSON payload
            priority INTEGER DEFAULT 0,
            status TEXT DEFAULT 'pending', -- pending, processing, failed
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );

-- seekbar_sprites: 120095 rows
CREATE TABLE seekbar_sprites (
            download_id   INTEGER PRIMARY KEY,
            sprite_path   TEXT NOT NULL,
            meta_path     TEXT NOT NULL,
            duration_sec  REAL,
            frames        INTEGER,
            cols          INTEGER,
            rows          INTEGER,
            tile_w        INTEGER,
            tile_h        INTEGER,
            interval_sec  REAL,
            format        TEXT,
            bytes         INTEGER,
            source_size   INTEGER,
            source_mtime  INTEGER,
            generated_at  INTEGER NOT NULL,
            FOREIGN KEY (download_id) REFERENCES downloads(id) ON DELETE CASCADE
        );

-- share_links: 0 rows
CREATE TABLE share_links (
            id               INTEGER PRIMARY KEY AUTOINCREMENT,
            download_id      INTEGER NOT NULL,
            created_at       INTEGER NOT NULL,
            expires_at       INTEGER NOT NULL,
            revoked_at       INTEGER,
            label            TEXT,
            last_accessed_at INTEGER,
            access_count     INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (download_id) REFERENCES downloads(id) ON DELETE CASCADE
        );

-- tgdl_account_ops: 0 rows
CREATE TABLE tgdl_account_ops (
 id TEXT PRIMARY KEY NOT NULL,payload TEXT NOT NULL
);

-- tgdl_cluster_catalog: 186586 rows
CREATE TABLE tgdl_cluster_catalog (
    remote_id INTEGER PRIMARY KEY,
    revision INTEGER NOT NULL UNIQUE,
    event_type TEXT NOT NULL,
    payload TEXT NOT NULL
);

-- tgdl_cluster_replay: 0 rows
CREATE TABLE tgdl_cluster_replay (
 peer_id TEXT NOT NULL, signature TEXT NOT NULL, expires_at INTEGER NOT NULL,
 PRIMARY KEY(peer_id,signature)
);

-- tgdl_cluster_revision: 1 rows
CREATE TABLE tgdl_cluster_revision (id INTEGER PRIMARY KEY CHECK(id=1), revision INTEGER NOT NULL);

-- tgdl_derived_cleanup: 0 rows
CREATE TABLE tgdl_derived_cleanup (area TEXT NOT NULL,path TEXT NOT NULL,PRIMARY KEY(area,path));

-- tgdl_file_cleanup: 0 rows
CREATE TABLE tgdl_file_cleanup (path TEXT PRIMARY KEY NOT NULL);

-- tgdl_group_rank: 156 rows
CREATE TABLE tgdl_group_rank (
 group_id TEXT PRIMARY KEY,
 rank INTEGER NOT NULL,
 sched_base INTEGER NOT NULL,
 name TEXT NOT NULL DEFAULT '',
 updated_at INTEGER NOT NULL DEFAULT 0
);

-- tgdl_history_jobs: 898 rows
CREATE TABLE tgdl_history_jobs (
 id TEXT PRIMARY KEY NOT NULL,
 group_id TEXT NOT NULL,
 state TEXT NOT NULL,
 payload TEXT NOT NULL
);

-- tgdl_ingest_files: 0 rows
CREATE TABLE tgdl_ingest_files (
        path TEXT PRIMARY KEY NOT NULL, item TEXT NOT NULL, generation INTEGER NOT NULL, sha256 TEXT NOT NULL DEFAULT ''
    );

-- tgdl_message_generations: 245015 rows
CREATE TABLE tgdl_message_generations (
      group_id TEXT NOT NULL,message_id INTEGER NOT NULL,generation INTEGER NOT NULL, registered INTEGER NOT NULL DEFAULT 0,PRIMARY KEY(group_id,message_id));

-- tgdl_part_progress: 15 rows
CREATE TABLE tgdl_part_progress (
 group_id TEXT NOT NULL,
 message_id INTEGER NOT NULL,
 identity TEXT NOT NULL,
 path TEXT NOT NULL,
 size INTEGER NOT NULL,
 offset INTEGER NOT NULL,
 sha256 TEXT NOT NULL,
 updated_at INTEGER NOT NULL, stage_dir TEXT NOT NULL DEFAULT '',
 PRIMARY KEY (group_id,message_id,identity)
);

-- tgdl_purge_jobs: 0 rows
CREATE TABLE tgdl_purge_jobs (
 id TEXT PRIMARY KEY NOT NULL,payload TEXT NOT NULL
);

-- tgdl_queue_state: 1 rows
CREATE TABLE tgdl_queue_state (
 id INTEGER PRIMARY KEY CHECK (id=1),
 paused INTEGER NOT NULL DEFAULT 0,
 updated_at INTEGER NOT NULL
);

-- tgdl_rescue_messages: 0 rows
CREATE TABLE tgdl_rescue_messages (
 group_id TEXT NOT NULL, message_id INTEGER NOT NULL,
 account_id TEXT NOT NULL, channel_id INTEGER NOT NULL,
 pending_until INTEGER NOT NULL, rescued_at INTEGER,
 PRIMARY KEY(group_id,message_id)
);

-- tgdl_schema_meta: 1 rows
CREATE TABLE tgdl_schema_meta (version INTEGER NOT NULL);

-- tgdl_stage_followers: 0 rows
CREATE TABLE tgdl_stage_followers ( -- other messages with the same file, catalogued when it arrives
	path       TEXT NOT NULL,
	group_id   TEXT NOT NULL,
	message_id INTEGER NOT NULL,
	item       TEXT NOT NULL,
	generation INTEGER NOT NULL,
	PRIMARY KEY (path, group_id, message_id)
);

-- tgdl_stage_moves: 0 rows
CREATE TABLE tgdl_stage_moves ( -- downloads waiting in the local staging folder
	path          TEXT PRIMARY KEY NOT NULL, -- final place, relative to the library
	stage_dir     TEXT NOT NULL,             -- the local folder holding it
	item          TEXT NOT NULL,
	generation    INTEGER NOT NULL,
	identity      TEXT NOT NULL,
	sha256        TEXT NOT NULL,
	size          INTEGER NOT NULL,
	state         TEXT NOT NULL DEFAULT 'waiting', -- waiting, or stuck: needs a person
	attempts      INTEGER NOT NULL DEFAULT 0,
	next_at       INTEGER NOT NULL DEFAULT 0,
	failing_since INTEGER NOT NULL DEFAULT 0,
	error         TEXT NOT NULL DEFAULT '',
	created_at    INTEGER NOT NULL
);

-- tgdl_update_channels: 120 rows
CREATE TABLE tgdl_update_channels (
 account_id TEXT NOT NULL,user_id INTEGER NOT NULL,channel_id INTEGER NOT NULL,
 pts INTEGER,access_hash INTEGER,
 PRIMARY KEY(account_id,user_id,channel_id)
);

-- tgdl_update_recovery: 0 rows
CREATE TABLE tgdl_update_recovery (
 account_id TEXT NOT NULL,channel_id INTEGER NOT NULL,
 reason TEXT NOT NULL,created_at INTEGER NOT NULL,
 PRIMARY KEY(account_id,channel_id)
);

-- tgdl_update_recovery_state: 0 rows
CREATE TABLE tgdl_update_recovery_state (
 account_id TEXT NOT NULL,channel_id INTEGER NOT NULL,
 user_id INTEGER NOT NULL,pts INTEGER NOT NULL,
 PRIMARY KEY(account_id,channel_id)
);

-- tgdl_update_state: 1 rows
CREATE TABLE tgdl_update_state (
 account_id TEXT NOT NULL,user_id INTEGER NOT NULL,
 pts INTEGER NOT NULL,qts INTEGER NOT NULL,date INTEGER NOT NULL,seq INTEGER NOT NULL,
 PRIMARY KEY(account_id,user_id)
);

-- tgdl_user_peers: 148 rows
CREATE TABLE tgdl_user_peers (
    account_id TEXT NOT NULL, self_id INTEGER NOT NULL, user_id INTEGER NOT NULL,
    access_hash INTEGER NOT NULL, PRIMARY KEY(account_id,self_id,user_id)
);

-- tgdl_verified_media: 186583 rows
CREATE TABLE tgdl_verified_media (
		path TEXT PRIMARY KEY NOT NULL, size INTEGER NOT NULL, mtime_ns INTEGER NOT NULL, sha256 TEXT NOT NULL, fingerprint TEXT NOT NULL
	);

-- tgdl_work: 284052 rows
CREATE TABLE tgdl_work (
 id INTEGER PRIMARY KEY AUTOINCREMENT,
 account_id TEXT NOT NULL,
 group_id TEXT NOT NULL,
 group_name TEXT NOT NULL,
 message_id INTEGER NOT NULL,
 version INTEGER NOT NULL,
 source_pts INTEGER NOT NULL DEFAULT 0,
 identity TEXT NOT NULL,
 media_type TEXT NOT NULL,
 file_name TEXT NOT NULL,
 file_size INTEGER NOT NULL,
 body BLOB NOT NULL,
 generation INTEGER NOT NULL DEFAULT 1,
 claim_generation INTEGER,
 status TEXT NOT NULL DEFAULT 'pending',
 paused INTEGER NOT NULL DEFAULT 0,
 refresh_required INTEGER NOT NULL DEFAULT 0,
 origin TEXT NOT NULL DEFAULT 'live',
 ttl_seconds INTEGER NOT NULL DEFAULT 0,
 attempts INTEGER NOT NULL DEFAULT 0,
 retry_at INTEGER NOT NULL DEFAULT 0,
 error TEXT,
 created_at INTEGER NOT NULL,
 updated_at INTEGER NOT NULL, sched_order INTEGER NOT NULL DEFAULT 131072, dc INTEGER NOT NULL DEFAULT 0,
 UNIQUE(group_id,message_id)
);

-- update_history: 0 rows
CREATE TABLE update_history (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            from_version TEXT,
            to_version   TEXT,
            started_at   INTEGER NOT NULL,
            finished_at  INTEGER,
            status       TEXT    NOT NULL DEFAULT 'pending',
            error_code   TEXT,
            error_msg    TEXT,
            backup_path  TEXT,
            backup_bytes INTEGER
        , from_instance_id TEXT);

-- web_sessions: 1 rows
CREATE TABLE web_sessions (
            token      TEXT    PRIMARY KEY,
            role       TEXT    NOT NULL CHECK(role IN ('admin','guest')),
            issued_at  INTEGER NOT NULL,
            expires_at INTEGER NOT NULL,
            last_seen  INTEGER NOT NULL
        );

CREATE INDEX idx_backup_jobs_download ON backup_jobs(download_id);

CREATE INDEX idx_backup_jobs_pending ON backup_jobs(destination_id, status, next_retry_at);

CREATE INDEX idx_cluster_audit_ts ON cluster_audit(ts DESC);

CREATE INDEX idx_cluster_egress_time ON cluster_egress_log(served_at);

CREATE INDEX idx_ai_unindexed ON downloads(file_type, ai_indexed_at) WHERE ai_indexed_at IS NULL;

CREATE INDEX idx_created_at ON downloads(created_at);

CREATE INDEX idx_file_hash ON downloads(file_hash) WHERE file_hash IS NOT NULL;

CREATE INDEX idx_file_path ON downloads(file_path);

CREATE INDEX idx_filename_size ON downloads(group_id, file_name, file_size);

CREATE INDEX idx_gallery_group_date ON downloads(group_id, created_at DESC, id DESC);

CREATE INDEX idx_gallery_group_pinned_date ON downloads(group_id, pinned DESC, created_at DESC, id DESC);

CREATE INDEX idx_gallery_group_type_date ON downloads(group_id, file_type, created_at DESC, id DESC);

CREATE INDEX idx_gallery_pinned_date ON downloads(pinned DESC, created_at DESC, id DESC);

CREATE INDEX idx_gallery_type_date ON downloads(file_type, created_at DESC, id DESC);

CREATE INDEX idx_gallery_type_pinned_date ON downloads(file_type, pinned DESC, created_at DESC, id DESC);

CREATE INDEX idx_group_id ON downloads(group_id);

CREATE INDEX idx_group_message ON downloads(group_id, message_id);

CREATE INDEX idx_group_name_size ON downloads(group_id, group_name, file_size);

CREATE INDEX idx_media_facts ON downloads(file_type, media_duration_ms, media_width, media_height) WHERE media_width IS NOT NULL OR media_duration_ms IS NOT NULL;

CREATE INDEX idx_nsfw_review ON downloads(nsfw_score, nsfw_whitelist) WHERE nsfw_score IS NOT NULL;

CREATE INDEX idx_nsfw_tier ON downloads(file_type, nsfw_whitelist, nsfw_score) WHERE nsfw_score IS NOT NULL;

CREATE INDEX idx_nsfw_unscanned ON downloads(file_type, nsfw_checked_at) WHERE nsfw_checked_at IS NULL;

CREATE INDEX idx_pending_until ON downloads(pending_until) WHERE pending_until IS NOT NULL;

CREATE INDEX idx_telegram_media ON downloads(telegram_media_kind, telegram_media_id, telegram_media_size, id);

CREATE INDEX idx_unhashed ON downloads(id DESC) WHERE file_hash IS NULL AND file_path IS NOT NULL;

CREATE INDEX idx_video_filepath ON downloads(file_type, id DESC) WHERE file_type = 'video' AND file_path IS NOT NULL;

CREATE INDEX ix_downloads_size ON downloads(file_size) WHERE status='completed';

CREATE INDEX ix_downloads_tg_size ON downloads(telegram_media_size) WHERE status='completed';

CREATE INDEX idx_faces_download ON faces(download_id);

CREATE INDEX idx_faces_person   ON faces(person_id);

CREATE INDEX idx_tags_tag_score ON image_tags(tag, score DESC);

CREATE INDEX ix_copy_hold_of ON ix_copy_hold(of_work) WHERE of_work<>0;

CREATE INDEX ix_copy_sample_ident_x ON ix_copy_sample(ident);

CREATE INDEX ix_copy_thumb_msg ON ix_copy_thumb(group_id, message_id);

CREATE INDEX ix_faces_key ON ix_faces(key);

CREATE INDEX ix_faces_person ON ix_faces(person);

CREATE INDEX ix_fixity_checked ON ix_fixity(checked_at);

CREATE INDEX ix_fixity_events_at ON ix_fixity_events(at);

CREATE INDEX ix_held_msg ON ix_held(group_id, message_id);

CREATE INDEX ix_lowq_work ON ix_lowq(work_id);

CREATE INDEX ix_mcl_cluster ON ix_mcl(cluster);

CREATE INDEX ix_message_edits_msg ON ix_message_edits(group_id, message_id);

CREATE INDEX ix_messages_comment ON ix_messages(comment_on) WHERE comment_on <> '';

CREATE INDEX ix_messages_date ON ix_messages(group_id, date);

CREATE INDEX ix_messages_grouped ON ix_messages(group_id, grouped_id) WHERE grouped_id <> '';

CREATE INDEX ix_msg_link_tg ON ix_msg_link(tg_file);

CREATE INDEX ix_part_store_at ON ix_part_store(at);

CREATE INDEX ix_vband_key ON ix_vband(key);

CREATE INDEX ix_vband_value ON ix_vband(band, v);

CREATE INDEX ix_walks_group ON ix_walks(group_id, finished_at);

CREATE INDEX native_backup_transfers_ready ON native_backup_transfers(state,next_retry_at,created_at);

CREATE INDEX idx_pdj_pending ON peer_delete_jobs(status, peer_id);

CREATE INDEX idx_peer_downloads_created ON peer_downloads(created_at DESC);

CREATE INDEX idx_peer_downloads_group   ON peer_downloads(group_id);

CREATE INDEX idx_peer_downloads_hash    ON peer_downloads(file_hash, file_size);

CREATE INDEX idx_peer_face_centroids_label
            ON peer_face_centroids(label) WHERE label IS NOT NULL;

CREATE INDEX idx_failover_ts ON peer_failover_log(ts DESC);

CREATE INDEX idx_peers_status ON peers(status);

CREATE INDEX idx_seekbar_generated_at ON seekbar_sprites(generated_at);

CREATE INDEX idx_share_links_download ON share_links(download_id);

CREATE INDEX idx_share_links_expiry ON share_links(expires_at);

CREATE INDEX idx_tgdl_cluster_replay_expiry ON tgdl_cluster_replay(expires_at);

CREATE UNIQUE INDEX idx_tgdl_history_running ON tgdl_history_jobs(group_id) WHERE state='running';

CREATE INDEX idx_tgdl_rescue_account ON tgdl_rescue_messages(account_id,message_id) WHERE channel_id=0;

CREATE INDEX idx_tgdl_rescue_channel ON tgdl_rescue_messages(channel_id,message_id);

CREATE INDEX tgdl_stage_moves_identity ON tgdl_stage_moves(identity);

CREATE INDEX tgdl_stage_moves_wait ON tgdl_stage_moves(state, created_at);

CREATE INDEX idx_tgdl_work_active_identity ON tgdl_work(identity) WHERE status='processing';

CREATE INDEX idx_tgdl_work_big_server ON tgdl_work(dc,paused,CASE WHEN ttl_seconds>0 THEN 0 WHEN origin NOT IN ('live','history') THEN 1 WHEN origin='history' AND sched_order>=131072 THEN 3 ELSE 2 END,sched_order,id) WHERE status='pending' AND ttl_seconds=0 AND file_size>=1073741824;

CREATE INDEX idx_tgdl_work_claim ON tgdl_work(paused,(ttl_seconds=0 AND file_size>=1073741824),CASE WHEN ttl_seconds>0 THEN 0 WHEN origin NOT IN ('live','history') THEN 1 WHEN origin='history' AND sched_order>=131072 THEN 3 ELSE 2 END,sched_order,id) WHERE status='pending';

CREATE INDEX idx_tgdl_work_identity_any ON tgdl_work(identity);

CREATE INDEX idx_tgdl_work_open ON tgdl_work(status,origin,paused,ttl_seconds,file_size,dc,sched_order,retry_at);

CREATE INDEX idx_tgdl_work_pending ON tgdl_work(status,account_id,retry_at,id);

CREATE INDEX idx_tgdl_work_priority ON tgdl_work(status,paused,CASE WHEN ttl_seconds>0 THEN 0 WHEN origin NOT IN ('live','history') THEN 1 WHEN origin='history' AND sched_order>=131072 THEN 3 ELSE 2 END,sched_order,id);

CREATE INDEX idx_tgdl_work_ready_server ON tgdl_work(dc,paused,retry_at) WHERE status='pending';

CREATE INDEX idx_update_history_status ON update_history(status, started_at);

CREATE INDEX idx_web_sessions_expires ON web_sessions(expires_at);

CREATE INDEX idx_web_sessions_role    ON web_sessions(role);

CREATE TRIGGER downloads_fts_delete AFTER DELETE ON downloads BEGIN
                INSERT INTO downloads_fts(downloads_fts, rowid, file_name, group_name)
                VALUES ('delete', old.id, COALESCE(old.file_name,''), COALESCE(old.group_name,''));
            END;

CREATE TRIGGER downloads_fts_insert AFTER INSERT ON downloads BEGIN
                INSERT INTO downloads_fts(rowid, file_name, group_name)
                VALUES (new.id, COALESCE(new.file_name,''), COALESCE(new.group_name,''));
            END;

CREATE TRIGGER downloads_fts_update AFTER UPDATE OF file_name, group_name ON downloads BEGIN
                INSERT INTO downloads_fts(downloads_fts, rowid, file_name, group_name)
                VALUES ('delete', old.id, COALESCE(old.file_name,''), COALESCE(old.group_name,''));
                INSERT INTO downloads_fts(rowid, file_name, group_name)
                VALUES (new.id, COALESCE(new.file_name,''), COALESCE(new.group_name,''));
            END;

CREATE TRIGGER native_backup_download_insert AFTER INSERT ON downloads
WHEN NEW.file_path IS NOT NULL AND NEW.file_path<>''
BEGIN
 INSERT INTO backup_jobs(destination_id,download_id,remote_path)
 SELECT d.id,NEW.id,REPLACE(NEW.file_path,char(92),'/') FROM backup_destinations d
 WHERE d.enabled=1 AND d.mode='mirror'
 AND NOT EXISTS(SELECT 1 FROM backup_jobs j WHERE j.destination_id=d.id AND j.download_id=NEW.id);
END;

CREATE TRIGGER native_backup_download_update AFTER UPDATE OF file_path,file_hash ON downloads
WHEN NEW.file_path IS NOT NULL AND NEW.file_path<>'' AND (NEW.file_path IS NOT OLD.file_path OR NEW.file_hash IS NOT OLD.file_hash)
BEGIN
 INSERT INTO native_backup_versions(job_id,version)
 SELECT j.id,1 FROM backup_jobs j JOIN backup_destinations d ON d.id=j.destination_id
 WHERE j.download_id=NEW.id AND d.enabled=1 AND d.mode='mirror'
 ON CONFLICT(job_id) DO UPDATE SET version=version+1;
 UPDATE backup_jobs SET remote_path=REPLACE(NEW.file_path,char(92),'/'),
 status=CASE WHEN status='uploading' THEN status ELSE 'pending' END,
 attempts=CASE WHEN status='uploading' THEN attempts ELSE 0 END,
 error=NULL,next_retry_at=NULL,finished_at=NULL
 WHERE download_id=NEW.id AND destination_id IN(SELECT id FROM backup_destinations WHERE enabled=1 AND mode='mirror');
 INSERT INTO backup_jobs(destination_id,download_id,remote_path)
 SELECT d.id,NEW.id,REPLACE(NEW.file_path,char(92),'/') FROM backup_destinations d
 WHERE d.enabled=1 AND d.mode='mirror'
 AND NOT EXISTS(SELECT 1 FROM backup_jobs j WHERE j.destination_id=d.id AND j.download_id=NEW.id);
END;

CREATE TRIGGER tgdl_cluster_download_added AFTER INSERT ON downloads WHEN NEW.file_path IS NOT NULL AND NEW.file_path<>'' BEGIN
 UPDATE tgdl_cluster_revision SET revision=revision+1 WHERE id=1; INSERT INTO tgdl_cluster_catalog(remote_id,revision,event_type,payload) VALUES(NEW.id,(SELECT revision FROM tgdl_cluster_revision WHERE id=1),'download_added',json_object('id',NEW.id,'group_id',CAST(NEW.group_id AS TEXT),'group_name',NEW.group_name,'message_id',NEW.message_id,'file_name',NEW.file_name,'file_size',NEW.file_size,'file_type',NEW.file_type,'file_path',NEW.file_path,'file_hash',NEW.file_hash,'status',NEW.status,'created_at',CAST(NEW.created_at AS TEXT),'nsfw_score',NEW.nsfw_score))
 ON CONFLICT(remote_id) DO UPDATE SET revision=excluded.revision,event_type=excluded.event_type,payload=excluded.payload; END;

CREATE TRIGGER tgdl_cluster_download_deleted AFTER DELETE ON downloads BEGIN
 UPDATE tgdl_cluster_revision SET revision=revision+1 WHERE id=1;
 INSERT INTO tgdl_cluster_catalog(remote_id,revision,event_type,payload) VALUES(OLD.id,(SELECT revision FROM tgdl_cluster_revision WHERE id=1),'download_deleted',json_object('remote_id',OLD.id))
 ON CONFLICT(remote_id) DO UPDATE SET revision=excluded.revision,event_type=excluded.event_type,payload=excluded.payload; END;

CREATE TRIGGER tgdl_cluster_download_rekeyed AFTER UPDATE OF id ON downloads WHEN OLD.id<>NEW.id BEGIN
 UPDATE tgdl_cluster_revision SET revision=revision+1 WHERE id=1;
 INSERT INTO tgdl_cluster_catalog(remote_id,revision,event_type,payload) VALUES(OLD.id,(SELECT revision FROM tgdl_cluster_revision WHERE id=1),'download_deleted',json_object('remote_id',OLD.id))
 ON CONFLICT(remote_id) DO UPDATE SET revision=excluded.revision,event_type=excluded.event_type,payload=excluded.payload; END;

CREATE TRIGGER tgdl_cluster_download_updated AFTER UPDATE OF id,group_id,group_name,message_id,file_name,file_size,file_type,file_path,file_hash,status,created_at,nsfw_score ON downloads
 WHEN OLD.id IS NOT NEW.id OR OLD.group_id IS NOT NEW.group_id OR OLD.group_name IS NOT NEW.group_name OR OLD.message_id IS NOT NEW.message_id OR OLD.file_name IS NOT NEW.file_name OR OLD.file_size IS NOT NEW.file_size OR OLD.file_type IS NOT NEW.file_type OR OLD.file_path IS NOT NEW.file_path OR OLD.file_hash IS NOT NEW.file_hash OR OLD.status IS NOT NEW.status OR OLD.created_at IS NOT NEW.created_at OR OLD.nsfw_score IS NOT NEW.nsfw_score BEGIN
 UPDATE tgdl_cluster_revision SET revision=revision+1 WHERE id=1; INSERT INTO tgdl_cluster_catalog(remote_id,revision,event_type,payload) VALUES(NEW.id,(SELECT revision FROM tgdl_cluster_revision WHERE id=1),CASE WHEN NEW.file_path IS NULL OR NEW.file_path='' THEN 'download_deleted' ELSE 'download_updated' END,CASE WHEN NEW.file_path IS NULL OR NEW.file_path='' THEN json_object('remote_id',NEW.id) ELSE json_object('id',NEW.id,'group_id',CAST(NEW.group_id AS TEXT),'group_name',NEW.group_name,'message_id',NEW.message_id,'file_name',NEW.file_name,'file_size',NEW.file_size,'file_type',NEW.file_type,'file_path',NEW.file_path,'file_hash',NEW.file_hash,'status',NEW.status,'created_at',CAST(NEW.created_at AS TEXT),'nsfw_score',NEW.nsfw_score) END)
 ON CONFLICT(remote_id) DO UPDATE SET revision=excluded.revision,event_type=excluded.event_type,payload=excluded.payload; END;

CREATE TRIGGER trg_purge_orphan_people
        AFTER DELETE ON faces
        WHEN OLD.person_id IS NOT NULL
        BEGIN
            DELETE FROM people
             WHERE id = OLD.person_id
               AND NOT EXISTS (SELECT 1 FROM faces WHERE person_id = OLD.person_id);
        END;

CREATE TRIGGER ix_fts_ad AFTER DELETE ON ix_messages BEGIN
	INSERT INTO ix_fts(ix_fts, rowid, text) VALUES ('delete', old.rowid, old.text);
END;

CREATE TRIGGER ix_fts_ai AFTER INSERT ON ix_messages BEGIN
	INSERT INTO ix_fts(rowid, text) VALUES (new.rowid, new.text);
END;

CREATE TRIGGER ix_fts_au AFTER UPDATE OF text ON ix_messages BEGIN
	INSERT INTO ix_fts(ix_fts, rowid, text) VALUES ('delete', old.rowid, old.text);
	INSERT INTO ix_fts(rowid, text) VALUES (new.rowid, new.text);
END;
