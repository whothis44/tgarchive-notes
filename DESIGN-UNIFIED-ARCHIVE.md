# One unified archive: the design note (copies, session C7, 2026-11-21)

The owner, 11-16 night: "The whole point is to have a unified archive, so the new app we're building can run
duplicate detection against the archive the old one downloaded to flag new media and the rest." The board's
Direction (first line), messages 198, 199 and 201, FEATURES 12 (eighteenth round), the roadmap row "ONE UNIFIED
ARCHIVE". Copies leads; Core and the viewer and bring-in with it.

Read in full by this session before writing: `TRIED-BEFORE.md`, `COPY-CHECKS-STUDY.md`, `LESSONS.md`,
`TELEGRAM-FACTS.md` (in `repo-archiver/archiver/docs`); `ANSWERS-for-archiver-4.md`, `-5.md`, `-8.md`; the copy
sections of `ANSWERS-for-archiver-7.md`, `LESSONS-ix12.29-servers.md` and `LESSONS-viewer-ix12.32.md`;
`HANDOFF-ix12.21.md` ("a second account later"); `STANDALONE-PLAN.md` 5.3 and 5.4; `docs/BRINGIN-WANTED.md`;
the new app's ladder (`internal/catalog/ladder.go`), `known.go`, `bringin.go`, `vfp.go`, `internal/exact`,
`internal/bringin/plan.go`. The download-path files (`WINDOW-EVIDENCE.md`, answers 6, 7 and 9) were read by their
headings only: nothing here touches the download path.

## 0. In short

- **One catalogue for both, not a read of the other.** The old archive is brought into the app's own catalogue
  as an account of its own that is never signed in. Every copy layer the app has then runs against the old
  archive with no new code in the layer itself: they are queries over the same tables.
- **Measured today, read-only, counts only** (the owner's app catalogue against the old archive's 11-15
  bring-in, `tgarchive-b\old-archive-4`): of the owner's new archive's 4,900 media, **4,507 are the same Telegram
  file (kind and id) as a media of the old archive, every one of the same byte size**; **114 of its 416 saved
  files (224 MB of 933 MB, 24%) are bytes the old archive already holds**, all 114 through the same Telegram
  file. In one catalogue the ladder's rung 2 would have linked those 114 and downloaded none of them.
- **"New" is decided per Telegram file from the copy edges and one fact per file (does the old app hold these
  bytes)**, derived, not stored per click; four words: in the old archive / probably in the old archive / partly
  in the old archive / new. "New" means "no layer found it", and its words say which layers ran, so a frame
  check's "no match" (wrong about 3 times in 4, answers 8) never stands alone as proof.
- **What it takes, by track:** the bring-in learns to write into the app's catalogue (viewer and bring-in); the
  old account row that is never signed in, the old library as a second read-only root, the owner's step that
  runs the bring-in (Core); the cost of every layer at the unified size and the door for "new" (copies); the
  words and the filter (viewer).

## 1. What the record already says (the old app's numbers beside this design)

| Layer | The old app (its numbers) | Crosses accounts? |
|---|---|---|
| Same Telegram file (kind + id) | 10,332 files, 132 GB not downloaded in one day (answers 7, 5); 3,438 of about 6,000 top-up candidates (TRIED-BEFORE 22) | **Yes, now measured:** 4,507 of 4,507 shared ids have equal sizes; 114 of 114 shared saved files have equal SHA-256 (section 0). Before today only "inferred" (TELEGRAM-FACTS 4) |
| Same post (forward origin) | rung 4: held, never skipped | Yes in shared spaces (channel message numbers are the same for every account, TELEGRAM-FACTS 6) |
| Exact check: Telegram's part hashes against a saved file of exactly the size | 5,007 files, 240 GB in ten days; 0 undone (answers 4) | Yes: it compares bytes, whatever account saved them |
| Look-alike (preview hash within 6 bits, length within 500 ms, shape, saved copy as good) | right 95% at 6 bits (study A); 1,360 confirmed against 675 released by frames (answers 5) | Yes: the hash equals the old app's (answers 4, E.13); **147,750 of the old archive's 152,055 saved videos carry it** |
| Frame check against fingerprints | "copy" right (184 of 188 downloaded anyway); "no match" wrong about 3 in 4 against a named candidate (answers 8) | Yes: **136,128 old saved videos have a fingerprint in the same packing and version** (`catalog/vfp.go`: the bring-in writes exactly what the worker writes) |
| Same SHA-256 after download | 734 files a day, nearly all small (answers 7) | Yes: `file.sha256` is unique in one catalogue |
| Image recognition (Immich vectors) | the copy checks by "how alike the previews look"; one preview request per file (study A6) | Only from the same model (message 201); **not part of this design** (section 6) |

So nothing new has to be invented to "run duplicate detection against the archive the old one downloaded": the
layers exist and take any file in the catalogue as a candidate. What is missing is that the old archive's files
are not in the app's catalogue.

## 2. One catalogue, or a read of the other

**One catalogue (recommended).** The bring-in writes the old archive into the app's own catalogue, the one the
collector writes and the window shows. Why:
- every rung, the exact check's candidates, the frame check's candidates (`VideoCandidates`) and the at-save
  SHA-256 link already read the catalogue's own tables: they gain the old files with no change of rule;
- a copy edge between a new file and an old one is a row with both ends in the same tables (foreign keys,
  cascades, the change log the viewer follows); across two databases it could not be;
- the catalogue was built for several accounts sharing one archive (`space.shared`: a channel is one space for
  every account; a basic group or private chat is a space per account, so the old account's message numbers
  never meet a new account's: the trap `HANDOFF-ix12.21.md` warned of is designed out);
- the viewer shows one archive because there is one catalogue; the old archive's own window starter (`b`) can
  then go.

**A read of the other (not recommended):** the collector opens the old archive's catalogue read-only beside its
own. Every rung would need a second lookup and its own cost test; an edge could not point into the other file;
the viewer would merge two catalogues per click (the slow viewer of `LESSONS-viewer-ix12.32.md`); and the
snapshot ages. The only thing it saves is the bring-in's run into the live catalogue.

**What exists that is close:** `known_file` and `ImportKnown` (the old app's `already_archived.jsonl`: kind, id,
SHA-256, size): rung "known" skips a file whose Telegram id the other archive saved. It covers only the first
layer, by id, with no message, no edge and nothing for the viewer to show. It stays for other archives; for the
old app's own archive the bring-in replaces it.

## 3. What the bring-in carries, and what it must change for this

Carried today (`internal/bringin`, the 11-15 run): 584,075 messages, 310,557 media (241,447 saved), 230,430 files
(4.52 TB), 232,026 places of those bytes, the copy edges (9,475 exact, 98,583 probable, 38,802 partly), 68,778
held files with their evidence, 1,597 "not a copy" pairs, and the fingerprints as bytes: 136,128 video, 84,675
picture hashes (PDQ) and grey pictures, 205,584 picture embeddings, 812,887 frame embeddings, 84,213 faces,
113,284 texts in pictures. Its catalogue is 2.88 GB; a run took about 15 minutes (the viewer's fourth run).

What it must change to write into the app's catalogue (all the bring-in's own package, viewer and bring-in
track), each a rule:
1. **It accepts a catalogue that holds accounts it did not make** (today `ErrNotOurs` refuses it), and writes the
   old account as an account row of its own, marked as brought in.
2. **It never changes the owner's choices in the app's catalogue.** A channel the app already has keeps its
   rank, its collect switch, its kinds and its topics; the old app's values for a chat the app does not have yet
   are kept as the old app's record and change nothing any new account collects (the old app had 99 of 190
   chats switched off: carried as they are, they would switch those channels off for the new accounts too).
   Which chats are read, mirrored or downloaded stays the owner's choice.
3. **It never re-holds, releases or relinks a file the app has decided since,** and never adds an edge the
   owner called "not the same" (the owner's words on pairs, `not_copy`, a release, `keep_held`). It only adds.
   A second run adds what the old app wrote since and nothing else (its doors already write nothing on a repeat).
4. **It writes in small transactions on the collector's own writer, or with the collector stopped by the
   owner** (TRIED-BEFORE 21: long writes are chunked; never hold the writer for seconds). Which of the two is
   Core's question (section 5).
5. **The old files keep the old library as their root** (section 5, Core), read only, never written, never
   moved.

## 4. How "new" is decided and shown

One fact per file, and the edges that exist:
- **The old app holds these bytes:** the file has a place of source "old app" (`file_copy.source`, written by
  `ImportSaved`).
- **A Telegram file is in the old archive** when its own file is such a file, or it has an **exact** edge to a
  media whose file is (the same Telegram file is one row, so rung 2 is this case by construction).
- **Probably in the old archive:** a **probable** edge to such a media (same post, look-alike, frames), until
  exact evidence or the owner's word settles it. It is held as every probable copy is: never skipped, never
  before unique files.
- **Partly in the old archive:** a **related** edge (partly the same footage).
- **New:** none of the above. **The words say which layers ran**, so that "new" never claims more than was
  checked: "new: no file of the old archive has its Telegram id, bytes, post or look" for a picture; for a video
  of 20 MB or more with saved videos of a near length, also "frames compared: no match" or "frames not compared
  yet". A frame check's "no match" never releases a file (answers 8); here it only says that one layer found
  nothing, which is what "new" means.
- **Seen by the old app, never saved** (the old archive's 68,778 held files and 332 wanted): these are media the
  old archive does not hold. They are "new" by the owner's words when no edge says otherwise; most carry a
  probable edge to an old saved file and so read "probably in the old archive".

**Derived, not stored per click** (LESSONS 1, `LESSONS-viewer-ix12.32.md`): the viewer already loads every copy
edge and follows the change log (a removed edge has its kind since C19). It needs one more bit per file, "the old
app holds these bytes", read once with its index and kept by the change log. No new table and no schema step for
the showing side, if the viewer agrees (section 5).

**Counted for the owner** (TRIED-BEFORE 10: every number says what it counts and adds up): per account and per
chat, a new account's files as in the old archive (exact) + probably + partly + new = its files, each once; and
by layer, how many each found. This is the number that answers "flag new media".

## 5. What each track is asked for

**Viewer and bring-in (B9):**
1. The bring-in into the app's catalogue, by the five rules of section 3, with a dry run that prints only the
   counts it would write (the plan command exists).
2. The four words and "seen by the old app, never saved" on a tile and in a post's facts; a filter "new since the
   old archive" beside "first seen here" and "only here"; the counts of section 4 on the Overview. From the edges
   and the one bit; say if you would rather read a door of the catalogue than derive it.
3. Retiring the `b` window starter once the app's window shows the old archive.

**Core (K-6):**
1. **An account that is never signed in:** the old account's row is marked as a brought-in archive; the collector
   never asks for its session, never reads, mirrors or downloads with it, and its lanes are never built. Its
   reach rows (the files it saw and never saved) are not "waiting" in any count.
2. **The old library as a second root, read only:** a stored setting with its folder; files of source "old app"
   resolve under it; nothing ever writes, moves or deletes there; its reads follow the NAS rule (nothing in the
   background reads the library while copies wait; the exact check already falls back when they do).
3. **How the bring-in runs against the live catalogue:** the owner's own step from the launcher (stop the app,
   bring in, start: about 15 minutes) or a collector door that runs it in small transactions while the collector
   runs. The hard rule stands: no session stops, restarts or reconfigures the owner's app; the owner does, or a
   door the owner presses.
4. The settle (`catalog/settle.go`) on an account deleted by Telegram (the old account on 11-29): its files stay,
   its reach rows go.

**Copies (this track, C7):**
1. **Every layer's cost at the unified size,** before the bring-in runs into the live catalogue: rung 6's reads
   and rung 4's pinned plan at 241,000 saved media (rung 4 is measured at 200,000: 7.5 to 9 ms for 100 forwarded
   attachments), the exact check's candidate read, `VideoCandidates` with 136,128 fingerprints, the at-save link.
   A cost test per read on invented data of that shape; a read that grows with the archive is fixed first.
2. **The door for "new"** if the viewer asks for one, and the counts of section 4 per account and chat.
3. **The same Telegram file across accounts:** this note's count goes into `TELEGRAM-FACTS.md` 4 (to the
   integrator: the docs are its).
4. The copy rules unchanged: only exact evidence skips; a probable copy is held, never before unique files;
   a frame check's "no match" releases nothing; nothing from a source the owner did not choose; nothing in the
   background reads the library on the NAS while copies wait.

## 6. Not in this design, and why

- **Image recognition (the Immich vectors, 205,584 picture and 812,887 frame embeddings):** carried as bytes. A
  likeness between a new picture and an old one is only comparable from the same model (message 201); the
  service is stopped at the owner's word (11-17 00:03) and the new app has no such layer. It is a layer of its
  own for later, with a measurement first; the old app's own use of it cost one preview request per file.
- **Picture hashes (PDQ, 84,675):** the old app never held a queued picture by them (study A12, "not sure"). Not
  a gate here; the viewer may show them.
- **Kept parts and partial downloads of the old app** (about 33 GB, 15 partials): of no use now that the old
  account is ending.
- **The old account's own reading or downloading in the new app:** off the path (the Direction, 11-14 night).

## 7. What it costs, and the order

- **Disk:** the app's catalogue grows from 34 MB to about 2.9 GB (the 11-15 bring-in's size; the old app has
  written a little since).
- **Time:** about 15 minutes of bring-in, once, then a second short run if the old app writes more. The owner is
  "basically done running the old app": the final bring-in is best run once the old app has stopped for good.
  When that is, is the owner's (one line on the waiting list).
- **Requests:** none. Everything here reads what the old app already downloaded and recorded.
- **Order:** (1) this note, and the answers of the viewer and Core on the board; (2) copies' cost tests at the
  unified size and the bring-in's five rules, side by side; (3) Core's account mark and the second root; (4) the
  bring-in into a COPY of the owner's catalogue, opened in the app's window by the owner, with the counts of
  section 4; (5) the real one, the owner's step.

## 8. Open, for the owner (one line each on the board's waiting list)

- When the old app stops for good, so that the final bring-in is the only one (recommended: run it then).
- The owner's step that runs the bring-in: from the launcher with the app stopped (recommended: simplest, 15
  minutes, nothing runs beside it), or a door while the app runs.
