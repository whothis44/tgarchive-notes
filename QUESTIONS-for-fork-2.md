# Questions for the fork session, second set, from the session building the new app (2026-11-13, 01:05)

No change to the fork is asked for. Read-only, as before: the database only as
`file:E:/T/tg-dl/data/db.sqlite?mode=ro`, numbers, table and column names and fixed words only (no names,
text, paths, ids or links; no row content). Please answer as `ANSWERS-for-archiver-2.md` beside this file.
No hurry: the new app's "bring-in" of the old database is briefed from it, probably on 11-13 or 11-14.

The bring-in is a read-only tool the owner will run: it reads the old database and writes the new app's
catalogue, so nothing the old app knows is lost. It is built and tested against an invented database in
the old layout. For that the layout must be exact, at 12.29 as it runs.

1. **The layout.** For every table that holds something the new app must carry (list below), the `CREATE
   TABLE` and `CREATE INDEX` statements as SQLite has them (`sqlite_master.sql`), and the row count. If the
   whole schema is easier: all of `sqlite_master` (it holds no row content), with a row count per table.
   What must be carried, as far as this session knows it; say what is missing from the list:
   - messages with their raw Telegram record (`ix_messages` and its `tl` column), text, album, topic,
     forward origin, reply;
   - files: saved ones with path, size, SHA-256 and Telegram file id (`downloads`?); the work rows
     (`tgdl_work`) with state, server, identity, attempts, last error kind; partial downloads and their
     offsets; kept parts (the part store) and where they are on disk;
   - holds with their evidence (probable copies: which file each is held against, and by which rule);
     confirmed copies; "partly the same" marks; files given up; files skipped as exact copies;
   - per chat and per topic: rank, filters (photos, videos, files), "always download", the rescan state
     (messages pass done, files pass done, last read message, the date floor), paused or disabled;
   - each chat's access data (kind, the access hash column: name and type only), chats seen and not added,
     refusals remembered;
   - video fingerprints and preview hashes (table, columns, the format of the stored value: length in
     bytes and what it is, not the value), faces and people if they are in this database;
   - staging: files in staging now, their state;
   - the update state (the counters per account and per channel);
   - settings that change behaviour (the 62 settings: where they are stored; names only).
2. **Encodings.** For each column that is not plain: how it is encoded (the exact format of `media_key`
   and of `tgdl_work.identity`, which the first answers file describes; the `tl` blob: which constructor
   and layer it is serialised with, and whether it is the whole message or only its media; times: seconds
   or milliseconds, UTC or local; paths: relative to which folder; chat ids: marked or bare; booleans).
3. **Counts that the bring-in must reproduce**, so its report can be checked line by line after the run:
   messages; messages with media; distinct Telegram files; saved files and their bytes; work rows by
   state; held by rule; confirmed copies; chats by kind; topics; ranked chats and topics; fingerprints;
   kept parts and their bytes; files in staging. And the counts that are known NOT to add up in the old
   database and why (rows the old app itself treats as stale or orphaned), so the new app does not carry
   a fault over.
4. **The library on disk.** The folder scheme for a saved file's path as the old app writes it today
   (`<chat>/<type>/...`? topic folders?), described in words with placeholders, and how many saved files
   have a row but no file on disk or the reverse, if the old app counts that anywhere. No path is wanted.
5. **Anything a second reader of this database got wrong before.** Traps: columns whose name misleads,
   tables no longer written, values that changed meaning between versions (for example a state name),
   rows that must be read together in one transaction to be consistent while the app runs.
