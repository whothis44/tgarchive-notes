# Session B (breadth): progress

Started from `START-SESSION-B.md`. Rules: copies of its own (`wt-b-*`, branches `wip/b-*`), no merge into
the main branch, nothing against Telegram, the old app's folder read-only, counts and timings only.

- 11-14 18:44: read the start file, the roadmap, TRIED-BEFORE 9, 10, 14 to 16, the viewer feedback and the tenth
  session's last notes. Made `wt-b-bringin` (branch `wip/b-bringin`, from 4f5be66). Next: read the bring-in's
  code and the old app's 12.31 schema, then `plan` on the real database, read-only.
- 11-14 18:47: **`plan` has run on the real database** (roadmap A6). A copy made through a read-only connection
  (`VACUUM INTO`, 45 s, 2.99 GB) into `%LOCALAPPDATA%\tgarchive-b\oldcopy`; `plan` on it: 14 s, exit 0, the
  layout check passed with no change needed (the old app added no table or column between 12.29 and 12.31:
  its diff adds four `kv` keys only, counted as "other keys, not carried"). Counts: 224 chats added (183
  basic groups, 18 forums, 23 other; 93 on, 131 off; 192 ranked), 154 seen and not added; 584,075 messages
  (396,026 with a file; 53,629 albums); 307,444 distinct Telegram files; 232,024 saved-file rows (4.57 TB;
  230,426 distinct SHA-256); 241,443 Telegram files saved in effect; 53,246 rows held now (28,745 files);
  14,525 messages marked deleted; 32,335 messages with a file and no work or saved row. Full output:
  `%LOCALAPPDATA%\tgarchive-b\plan-1.txt` (counts and fixed words only).
- 11-14 18:47: an independent review of `run` is going (Opus, reading only); its report goes to
  `wt-b-bringin/archiver/docs/review/BRINGIN-RUN-REVIEW.md`. `run` waits for it.
- 11-14 18:56: **the review of `run` is back** (`wt-b-bringin/archiver/docs/review/BRINGIN-RUN-REVIEW.md`). Verdict: safe to
  run into a new folder (nothing but the `-new` catalogue is written), result not yet to be relied on.
  Checked on the copy, counts only: every saved row has status completed and no trash or rescue mark (M3
  not real); every path is relative with forward slashes, no colon, no `..` segment, at most 3 folders deep
  (M2 not real); every `ix_subst` row has the one 15-letter rule, the part-hash one (F4 not real); every link's
  path is a saved row's; no saved row's message is missing, 1 has another file key (F2: 1 file); 8 messages
  carry `deleted_at` (M4: real, small); the copy passes `quick_check` (M6). An Opus coder fixes in
  `wt-b-bringin`: M1 (a wrong `-new` is refused before anything is written), M5 (a link with no saved file no
  longer drops the rest of its chunk), M4, F7 (the "complete" mark only after verify). Left for later, written
  here so they are not lost: F1 (verify compares counts only), F3 (a resume must use the same copy: this
  session does), F5, F6, F8.
- 11-14 18:56: `b/b-viewer.ps1` written for the owner (the viewer under its own program name, port 8798, the library
  given by the owner, 1 thumbnail maker by default).
- 11-14 19:04: the coder's four fixes are in (`wip/b-bringin` 7d54abb, pushed to `private`; the guard read by the
  main session). **`run` started for real** at 19:03 from the copy into
  `%LOCALAPPDATA%\tgarchive-b\old-archive\catalog.sqlite` (a new, empty folder), with the deadline. Output:
  `run-1.txt` beside it. `MERGE-QUEUE.md` written (entry 1: the bring-in).
- 11-14 19:15: **`run` has run for real: 8 min 52 s, every stage done** (messages 264 s, fingerprints 197 s, saved
  files 17 s; longest write transaction 3.0 s; catalogue 2.86 GB). Carried: 584,075 messages, 232,024
  saved-file rows as 230,426 files, 241,443 Telegram files saved, 28,745 held files, 224 + 154 chats, 570
  topics, 1.52 million fingerprints, 15,367 exact links (5 with no saved file found, counted). **Verify
  exited 1** on small differences with no known reason, none of them about what a viewer shows: 119
  completed work rows whose file is not saved in the catalogue (5,343 against 5,224 expected), 13 video
  fingerprints fewer, and 8 open work rows counted "wanted" where "not collected" was expected. Messages,
  files, albums, topics, saved files, holds by rule: all equal. Open: find the 119. The "complete" mark is
  therefore not set. Report: `%LOCALAPPDATA%\tgarchive-b\run-1.txt`.
- 11-14 19:15: **the viewer on that catalogue, started by the session with an empty folder as its library and no
  thumbnail makers** (timings and counts only, answers discarded): index built in 2.0 s, 634 MB of memory;
  first page, chat list, a chat's posts, copies pages: 1 to 6 ms; the library's shape 5 to 23 ms.
  **Defect found: 3 of 7 existing posts tried answer with an error after about 190 ms** ("too many SQL
  variables"). Cause counted with a throwaway probe: of 73,555 sets one holds **78,956 posts and 174,328
  files**; the next largest has 332 posts. So the viewer's "same post across chats" rule chains most of the
  archive into one set, and that set's page asks for all of it at once. Not fit for the owner to open yet.
  A coder diagnoses what joins that set (counts only) in `wt-b-viewer` (branch `wip/b-viewer`).
- 11-14 19:19: **what joins the giant set, counted by the coder** (the set rule replayed in read-only SQL, matching the
  index exactly): the forward origin's key. A forward from a user, or from a channel without a post number,
  is keyed by the sender alone, so every forward from one person is "the same post": 1,725 such keys carry
  75,792 posts (15 keys over 1,000 posts, the largest 10,456). Shared files are not the cause (39 files are in
  more than 20 posts). With those keys ignored a second, real chain remains: 5,082 posts across 168 chats,
  albums that each share a few files with the next. **Decided (main session):** an origin joins only when it
  has a post number; files join two posts only when their file lists are identical (then the largest set is
  332 posts, one sticker; at most 130 files in a set); a partial overlap stays visible per file on the post
  page and does not merge; every list query in chunks of 400; a post page bounded at 500 files and 200 posts
  with the true totals; set sizes in the stats. The origin key itself is written by `internal/telegram`
  (the other session's): not touched, **to tell the download session**: a bare-sender origin key is not a
  post's identity. The coder builds it in `wt-b-viewer`.
- 11-14 19:19: open, parked: verify's 119 rows (a first count by the main session used the wrong key spelling).
- 11-14 19:31: the owner on the set rule: the sender-keyed forward rule "was due to fail, since most of the messages
  are ones I forwarded/archived to other chats"; and "Add B at minimum" (one step out from the opened post,
  no chain). Full merging (C) explained with its numbers. **The session ran out of usage with the coder in
  the middle of rule A in `wt-b-viewer`.** Everything a new session needs: `START-SESSION-B2.md`.
- 11-14 19:35: **rule A is back, committed** (`wip/b-viewer` c09e83a, clean tree, pushed to `private`; the diff NOT yet
  read by a main session). The coder's numbers on the real catalogue: 143,294 sets; the largest 332 posts
  (one sticker; it was 78,956); most files in a set 130; 7 sets over 100 posts; index 2.1 to 3.1 s; 200 post
  pages spread over the list: median 1.0 ms, worst 24.5 ms, 0 errors. `go test ./internal/viewer` passed
  (142.5 s). Its doubts: the index time against the old 2.0 s was not compared on the same runs; a change to a
  member's file list rebuilds its set under a new set number; the "Showing N of M" lines were not seen in a
  browser. **This supersedes "mid-build, no commit" in `START-SESSION-B2.md`: step 1 there is now only to read
  the set rule's diff; then rule B, the rebuild, the check, and the owner opens it.**
- 11-14 21:54: **a new main session took over from `START-SESSION-B2.md`.** Rule A's diff (c09e83a) read by the main
  session: the set rule (`soundOrigin`, `listKey`), the take-apart of a set when a member's file list changes,
  the bounded page (`boundFiles`, 500 files, 200 places), the queries in chunks of 400. Nothing found to change.
  **Rule B is with an Opus coder** in `wt-b-viewer` (not committed yet): overlapping posts gathered per page from
  the warm index (the same Telegram file only, copy edges not used; a file in more than 20 posts pulls in
  nothing; `near` = steps, 1 by default, at most 5; 500 files and 200 posts shown with true totals; the set's
  own counts unchanged). The PC had 1.4 GB of memory available at the start (browsers 12 GB, the sessions
  4.8 GB), so the coder runs one go command at a time with a small heap.
- 11-14 21:55: **verify's 119 rows are diagnosed (read-only counts on the copy and the new catalogue).** All 119 are completed
  work rows with no saved-file row of their own and one link of kind "telegram-file" (the same Telegram file as a
  saved one) whose path has no saved-file row in the old database any more: 78 distinct files, 78 distinct paths
  (of 53,176 such links, 121 point at a path with no saved row). The new catalogue has them as not saved (118
  held, 1 wanted), which is right; **verify's expectation is what is wrong**: `facts.go` counts every linked
  completed row as saved (C1Linked) without asking whether the link's file is saved. Fix for the bring-in's next
  commit: a linked row counts as saved only when `f.saved` has its file, else as an orphan. For the old app:
  78 files it treats as had through a link whose saved row is gone; it will never fetch them (to tell the fork
  session). Still open in verify: 13 video fingerprints, 8 open rows.
- 11-14 22:12: **rule B is committed and pushed** (`wip/b-viewer` 0e80f24, on `private`; entry 2 of `MERGE-QUEUE.md`). The main
  session read `near.go` and the post page's diff: nothing to change. The coder's runs: `go test
  ./internal/viewer` once, passed (182 s); 200 post pages on the real catalogue: at one step median 0.5 ms,
  worst 6.5 ms; at two steps worst 20.5 ms; 0 errors; 21 of the 200 have an overlapping post; the largest 20
  posts and 38 extra files at one step, 64 and 100 at two; no bound hit. The coder's choices to remember: a
  file's post count includes the posts of its own set (a file in a set of 21 identical posts pulls in nothing);
  `near` over 5 falls back to 1; overlapping posts are not filtered for hidden posts; the list is folded above
  10 rows. **Programs rebuilt** into `%LOCALAPPDATA%\tgarchive-b\bin` (`tgarchive.exe` and its copy
  `tgarchive-viewer.exe`). **Start check by a clerk** (empty library, no thumbnail makers, port 8799, then
  stopped): answering after about 4 s, index 2.6 s, first page and stats 2 ms, 143,294 sets, the largest 332
  posts. The page's script and styles were asked for at wrong addresses in that check (they are under
  `/assets/`), so they were not fetched; the page itself has not been seen by anyone.
  **Next: the owner opens it** (`.\b\b-viewer.ps1 -Library '<the old library folder on the NAS>'`) and says
  what is wrong. Then: verify's fix in the bring-in (the 119 rows above), items 2 and 3 of `START-SESSION-B.md`.
- 11-14 22:13: `BOARD.md` read (it replaces `MERGE-QUEUE.md`; the owner's direction: the old account stays on the old app, the
  unified viewer is the first priority). The owner could not follow the start directions: `b\b-viewer.cmd` added
  (double-click; a window asks for the library folder the first time and it is remembered), thumbnail makers
  0 by default (the board's message 3a). Open from the board: a thumbnail mode that makes only what a page
  asked for (with 0 makers nothing is made at all); the owner's marks are kept by catalogue row numbers, so a
  fresh bring-in would lose them (3b, not checked further); one read-only review of the viewer (3c).
- 11-14 22:16: the owner's start failed with "the viewer program is not built yet". Cause: the Claude app is a packaged app, so
  everything the sessions wrote under `%LOCALAPPDATA%\tgarchive-b` is really in
  `%LOCALAPPDATA%\Packages\Claude_*\LocalCache\Local\tgarchive-b`, which a window of the owner's does not see
  under the short name. `b-viewer.ps1` now looks there when the plain folder has no program. **Any path under
  `%LOCALAPPDATA%` given to the owner must be the package's one.**
- 11-14 22:22: **the owner has opened the viewer** (the library folder is the one with the named group folders; every saved path
  starts with a named folder, 201 of them). First words: "It seems less polished? There's no sidebar on the
  main page to easily filter." The old viewer's rail (12.32 `viewerassets/app.js`, `renderRail`): faces, type,
  copies, file state, when, chats with counts and leave-out, noise. The new one had a chip row only. **An Opus
  coder builds a filter sidebar** in `wt-b-viewer` (type, file, copies, when, chats with counts and leave-out
  (`xchat`), accounts, caption); not in it: faces (the catalogue has none yet) and "hide clutter".
- 11-14 22:29: the owner: **faces next** (after the sidebar). What the old app already knows, read by the main session
  (`ix_schema.go`, `ix_faces_quality.go`, `viewer_index.go`, `viewer_people.go` at 12.32; counts from the copy):
  84,213 faces in 62,541 files (48,984 with one face, 13,557 with two or more); 116,586 files looked at, 54,045
  of them with no face; 3,803 people made by the app, **none named, none hidden**, 3 merged; 29,764 faces in a
  person, 54,449 in none. The old viewer's "Who is in it": Anyone / No faces / One person / Two or more, counted
  as the larger of "most faces in one picture or frame" and "different people recognised", small or blurred
  faces (`ixFaceJunkPx`, `ixFaceJunkBlur`) left out unless asked. FEATURES 9 already says: the count per frame
  first, named people later (nearly empty). **The new catalogue already has every face** (bring-in: `fingerprint`
  kind `face`, 84,213 rows, 62,541 files, each with frame, size, blur, score, person, box): no schema step and
  no new bring-in needed for "one person / two or more". Missing for "No faces": which files were looked at
  (`ix_face_done` is not carried). Plan: the facet in the sidebar from the carried rows (same counting rule,
  same thresholds), read into the index once at start; "No faces" and a people page as later pieces. The faces
  coder starts when the sidebar is back (same files).
- 11-14 22:30: the owner, on a post page, about a file shown as "Not downloaded: held back by the archiver" among the overlap
  files: "Would be nice if it automatically included the post? Or, conversely, an option to hide what wasn't
  downloaded". Read by the main session as: (1) where a file is not downloaded and a saved copy of it is known
  (an exact or probable link, or the hold's own match), show that saved copy in its place, saying whose it is
  and linking to its post; (2) a switch on the post page that leaves out files that are not downloaded and have
  no such copy. Queued after the sidebar (`post.go`, `item.js`), before or beside faces.
- 11-14 22:34: `CLAUDE.md`'s archiver section read again after the review session rewrote it (the board first; session 11
  merges; lessons read in full before planning). Read in full by the main session for step 1:
  `LESSONS-viewer-ix12.32.md` and `LESSONS.md` sections 1 and 2 (TRIED-BEFORE 9, 10, 15, 16 earlier). What they
  add to the queued pieces: a copy shown must link to its post (the saved-copy stand-in does); the owner
  disliked tiles that "mostly show a low-quality preview" (11-09), which is what zero thumbnail makers gives
  now, so "make only what a page asked for, never making a request wait" comes right after the stand-in piece;
  paging keys must be stable when the index changes between pages, and the arrow keys must follow paging (to
  check in the read-only review); a thumbnail still being made needs a "made or stand-in" signal for the page.
- 11-14 22:38: **the sidebar is back from the coder**; the main session read the index and filter changes (a new file flag "in two
  or more chats" kept where places change; `xchat` and `copies` in the filter and its cache key): nothing to
  change. Its runs: three named tests passed, `go test ./internal/viewer` once, passed (177 s), gofmt and vet
  clean. Nobody has seen the page; the narrow panel has no focus trap; `browsercheck/run.py` was changed and not
  run. A clerk commits, builds `tgarchive.exe` and pushes; the owner's starter now takes a newer build by itself
  when the viewer is restarted. "Hide clutter" already exists in the new viewer's Settings (the main session had
  said it was not built: wrong).
- 11-14 22:38: counted for the next piece (the new catalogue, read-only): 69,114 Telegram files are not downloaded; 68,944 are
  held and 170 wanted. Of the held, **31,443 have a known saved match** (a probable link to a saved file; 11 of
  them by a "related" link as well or instead) and 37,499 have none (chats switched off, kinds left out, holds
  whose match is not in the catalogue).
- 11-14 22:39: **the sidebar is committed and pushed** (`wip/b-viewer` de8f5c3); `tgarchive.exe` rebuilt; the owner restarts the
  viewer to see it. **Two Opus coders at once** (5.2 GB available): in `wt-b-viewer` the saved copy shown in
  place of a file not downloaded, and the switch to hide those with none (`post.go`, `item.js`); in a new copy
  `wt-b-faces` (branch `wip/b-faces`, from de8f5c3) the faces count in the index and "Who is in it" in the
  sidebar (`index.go`, `refresh.go`, `library.go`, `library.js`, `stats.go`). Each adds its CSS in one block at
  the end of `app.css`. After both: merge `wip/b-faces` into `wip/b-viewer`, the package's tests once, rebuild.
  Then: thumbnails made only when a page asks; one read-only review of the whole viewer.
- 11-14 22:51: **the saved copy in place is committed and pushed** (`wip/b-viewer` 891515e; `tgarchive.exe` rebuilt 22:51). The main
  session read `post.go`'s diff (`standInOf`, `oldestPost`, the stand-ins inside the one `mediaInfo` call):
  nothing to change. The hide switch's choice is kept in the browser's local storage (the server's prefs are in
  `decisions.go`, outside the coder's files): to move to the server's prefs with the next commit. Session 11
  merged entries 1 and 2 (d08e9fa, d60766a; its race run of `internal/viewer` passed, 317 s) and asks that new
  pieces be cut from the branch's head; `MERGE-QUEUE.md` entry 3 and the board's row written. The faces coder
  is still running in `wt-b-faces`.
- 11-14 22:56: the owner restarted and saw the sidebar and the saved copies: "Mostly. The sorting of the groups isn't alphabetical,
  and there appears to be no options? Like recently added for example?" The chat list was briefed "most files
  first" (the main session's choice, wrong for the owner). Queued after faces (same file, `library.js`): the chat
  list A to Z by default, with a choice of order (A to Z, most files, newest post, and "recently saved" if it
  can be had cheaply), remembered in the server's prefs. The catalogue has no date a chat was added to the
  archive (`account_chat.joined_at` holds one value: the bring-in's). Asked the owner whether "recently added"
  is also wanted as an order of the library grid itself (today: by post date only).
- 11-14 22:59: **the faces coder handed back, not merged**: on the real catalogue reading the faces takes 18.1 s of a 22.9 s index
  build (4.8 s without), one run: the face rows are scattered through the wide `fingerprint` table. Counts:
  62,541 saved files with faces, 66,755 Telegram files; one person 57,252, two or more 4,036 (60,865 and 5,890
  with small or blurred faces counted); listings 15 to 23 ms a tile per post. Its whole-package run failed once
  on `TestWallImports` (an import outside the viewer's list), fixed, the package not re-run. **Decided (main
  session), by the lessons' "show at once, fill in behind": faces come off the start path** (the first index
  without them; read behind in bounded slices by the update path; a full re-read keeps them; the sidebar says
  "Reading faces: N of M" until complete). No schema step, no cache file. Sent back to the same coder, with the
  chat list's order added (A to Z by default; most files; newest post; kept in the server's prefs, where a
  `hide_not_saved` field is added for the post page).
- 11-14 23:21: **faces and the chat list's order are merged into `wip/b-viewer`** (c4bb582, pushed; `wip/b-faces` 05ddc65 pushed too).
  The main session read `viewer.go`'s diff (the update loop goes on while the first face read lasts; a new
  writer carries the faces; the progress is a copy on the viewer, not in an index version) and the merged
  stylesheet's blocks. The coder's second run on the real catalogue (warm cache; cold not re-measured): first
  page 2.65 s after start with no faces; faces complete 52.7 s after start in 17 slices, the longest update
  116 ms; counts unchanged. The clerk's run on the merged tree: `go test ./internal/viewer` passed (167 s),
  gofmt, vet and the scripts' syntax clean; `tgarchive.exe` built 23:20. `MERGE-QUEUE.md` entry 4 and the
  board say a race run is due. **An Opus coder builds "thumbnails made only when a page asks"**
  (`-thumb-ahead=false`; a made-or-stand-in signal for the page; the hide switch's choice moved to the
  server's prefs) in `wt-b-viewer`.
- 11-14 23:32: the board's new rule read (the owner, 23:30: a feature in FEATURES or ROADMAP is a standing request; in one's own
  packages it is briefed and built and the owner is told, not asked). FEATURES section 7, section 9 and the
  seventh round read in full by the main session. **A second Opus coder builds the listed library filters** in
  `wt-b-faces` on a new branch `wip/b-filters` (from c4bb582): topic; deleted on Telegram (badge, filter); "first
  seen here", "only here", "new between these dates" and the combined view, decided per file with exact links
  always and probable links by a switch. Counted first: 570 topics in 18 chats; **only 8 messages carry a
  deleted mark in the brought-in archive and none has a file** (the old database's 14,525 are mostly messages
  it never stored), so the deleted filter shows almost nothing on the old archive. Seven more listed viewer
  features written on the board as unbuilt (chat overlap table, probable copies under one tile with verdicts,
  unplayable videos, filter chips, clutter per chat, the home-network mode, "no faces" and people).

## State now (11-14 23:33): enough to take over from this block alone
- **Done and pushed:** `wip/b-viewer` c4bb582 on `private` (copy `wt-b-viewer`): set rules A and B, the filter
  sidebar, a saved copy in place of a file not downloaded, faces ("Who is in it") and the chat list's order.
  Session 11 merged up to 0e80f24; the rest waits (`MERGE-QUEUE.md` entries 3 and 4; a race run of
  `internal/viewer` is due at that merge). The owner's program: `tgarchive.exe` built 23:20 from c4bb582; the
  owner restarts with `b\b-viewer.cmd` (it takes a newer build by itself; the session's files under
  `%LOCALAPPDATA%` are really in `%LOCALAPPDATA%\Packages\Claude_*\LocalCache\Local\tgarchive-b`).
- **Running, not finished (two Opus coders, each told to commit work in progress and push it):**
  1. thumbnails made only when a page asks (`-thumb-ahead=false`, a made-or-stand-in signal, the hide
     switch's choice to the server's prefs): copy `wt-b-viewer`, side branch `wip/b-thumbs` (from c4bb582).
  2. listed library filters (topic; deleted on Telegram; first seen here, only here, new between dates,
     the combined view): copy `wt-b-faces`, branch `wip/b-filters` (from c4bb582).
- **When they hand back:** read the risky part of each (the maker's worker loop; the index update); a clerk
  merges `wip/b-thumbs` then `wip/b-filters` into `wip/b-viewer` (expect a conflict at the end of
  `web/app.css` and perhaps in `library.js`: keep both sides), runs `go test ./internal/viewer` once, gofmt,
  vet, builds `tgarchive.exe` into the session's `bin`, pushes; `MERGE-QUEUE.md` and the board's row updated;
  the owner restarts and looks. The owner's start script must then pass `-thumb-workers 1 -thumb-ahead=false`
  (`b\b-viewer.ps1`, the `$a` line; today it passes 0 workers).
- **Then, in order:** one read-only independent review of the whole viewer (the 12.32 lessons: paging stable
  when the index changes, arrow keys following paging, the made-or-stand-in signal); verify's fix in the
  bring-in (a linked row counts as saved only when its link's file is saved; cut from the main branch's head);
  the owner's marks surviving a fresh bring-in (they are kept by catalogue row numbers in `decisions.sqlite`);
  the chat overlap table and filter chips (board, "Listed and unbuilt").
- **Open with the owner:** whether "recently added" should also order the library grid (asked 23:00, no
  answer); the owner has seen the sidebar and saved copies ("mostly" right) but not yet faces or the chat order.

## A new session (B3) took over from B2 (11-15 08:47)
- 11-15 08:47: **a new session took over from the block above.** Read: `CLAUDE.md`, all of `BOARD.md`, this file, both start
  files, `MERGE-QUEUE.md`. The block checked against what is there:
  - `wip/b-viewer` c4bb582 is merged into the main branch (1d905f9; head 4f1992e, pushed). New pieces are cut from 4f1992e.
  - B2's two coders died with it; no agent of this track is running.
  - Thumbnails on request: `wip/b-thumbs` 255e82c in `wt-b-viewer`, clean tree, pushed to `private`. It is work in
    progress by its own message: named tests passed; the whole package once, vet, and the main session's read of the
    maker's worker loop are owed.
  - The listed filters: **nothing was committed.** `wip/b-filters` is still c4bb582 (local only, never pushed), clean
    tree in `wt-b-faces`. The piece is built anew, from 4f1992e.
  - `wt-b-bringin` 7d54abb, clean, merged long ago (d08e9fa).
  - The PC at 08:47: 10.6 GB free, CPU 36 %.
  - Board row changed to say so. **Next:** the main session reads the lessons in full (TRIED-BEFORE 8, 9, 10, 15, 16;
    LESSONS 1, 2; `LESSONS-viewer-ix12.32.md`; FEATURES 7 and 12 round 7), then reads 255e82c's diff, then starts
    one coder to finish the thumbnails and one to build the filters.
- 11-15 08:50: the lessons read in full by the main session (TRIED-BEFORE 8, 9, 10, 15, 16; LESSONS 1, 2;
  `LESSONS-viewer-ix12.32.md`; FEATURES 7, 9 and 12 round 7). The thumbnail commit 255e82c read (`maker.go`: the
  asked-only queue, `whileMissing`, the small one made from the large one; `media.go`: the `X-Thumb` answer):
  nothing to change in the Go side; the scripts are left to the coder's check and the review. Two briefs written:
  `BRIEF-B3-thumbs-finish.md` (copy `wt-b-viewer`, `wip/b-thumbs`: merge the main head, check the page side against
  the three 12.32 rules, whole package once, vet, commit, push) and `BRIEF-B3-filters.md` (copy `wt-b-faces`,
  `wip/b-filters` anew from 4f1992e: topic filter; deleted badge, filter and list; first appearance decided per
  file at listing time, no new index state). **Two Opus coders are being started on them now.** When they hand
  back: thumbs first into `wip/b-viewer` (fast-forward it to the thumbs head), then filters merged in, the
  package's tests once, build `tgarchive.exe` into the session's `bin`, push, `MERGE-QUEUE.md`, the board; the
  owner's start script then passes `-thumb-workers 1 -thumb-ahead=false`.
- 11-15 08:50: **both Opus coders started** (agents of this session; they die with it): thumbnails finish in `wt-b-viewer`
  (`wip/b-thumbs`), listed filters in `wt-b-faces` (`wip/b-filters`, pushed after each part). If this session
  stops: look at each copy's `git log` and `git status`, and restart a coder on the same brief from what is committed.
- 11-15 08:52: **a third Opus coder started** on verify's fix (`BRIEF-B3-verify.md`; copy `wt-b-bringin`, new branch
  `wip/b-verify` from 4f1992e; `internal/bringin` only): a linked completed row counts as saved only when its
  file is saved in effect (`facts.go` `work()`, `case linked`), plus a read-only diagnosis of verify's other two
  differences (13 video fingerprints, 8 open rows). PC: 10.6 GB free, CPU 17 %.
  **Designed, not briefed yet (the marks):** `decisions.sqlite` keys hidden posts by `message.id` and hidden chats
  by `chat.id` (catalogue row numbers). To survive a fresh bring-in: key a post by its chat's stable key plus
  Telegram's message number, a chat by its Telegram chat id (with the owning account's Telegram id for a
  per-account space); on first open the old rows are translated through the index of the catalogue they were
  made on; resolved to current rows at each index version. Any later mark (same / not the same) is keyed by
  Telegram file identity or SHA-256, never by a row number. To be briefed in `wt-b-viewer` when the thumbnail
  coder hands back (same package). Then the fresh bring-in: a new read-only copy of the old database, `run`
  into a new folder (`old-archive-2`), `verify`, the viewer's folder copied across, the start script switched.
- 11-15 08:57: the owner's new rule read on the board and in `CLAUDE.md` ("Who reports to whom", 11-15 08:56): this session
  reports to the integrator only, through the board row, `MERGE-QUEUE.md` and this file; owner decisions go under
  the board's "Waiting for the owner" in one line with a recommendation; how to restart the viewer and what is new
  goes on the board. The review session has detached this one. Order unchanged; three coders still running.
- 11-15 08:58: **the thumbnail coder handed back: `wip/b-thumbs` 718b326, pushed.** It merged the main head (68e2ca4; four
  files clashed because the main branch holds the sidebar and faces as its own merge commit, merge base 4f5be66:
  this branch's side kept; checked by the main session: against 4f1992e the branch differs only in
  `internal/viewer` and `cmd/tgarchive/viewer.go`). Page side read against the three 12.32 rules; three small
  fixes (read by the main session): "none" ends the asks for good in a page; the post page's large picture uses the
  value taken when drawn; the final 404 is `no-store`. At most 2 asks out at once and off-screen tiles do not ask:
  already so. `go test ./internal/viewer` passed once (172 s), gofmt and vet clean. Its doubts (for the review): a
  large picture can keep the grid-size stand-in if it is made between the picture request and the first ask; a
  tile whose large size alone exists is not swapped; `warm()`'s asks are outside the two-ask limit; nothing seen
  in a browser. **`wip/b-viewer` moved to 718b326 and pushed.** Not yet: the program built, the start script's
  flags, `MERGE-QUEUE.md` (after the filters merge). **Next now:** the marks coder in `wt-b-viewer` on a new
  branch `wip/b-marks` (from 718b326), brief `BRIEF-B3-marks.md`. Still running: filters, verify.
- 11-15 08:59: **the marks coder started** (`wt-b-viewer`, `wip/b-marks` from 718b326, `BRIEF-B3-marks.md`). PC: 10.7 GB free,
  CPU 53 %. Running now: filters (`wt-b-faces`), verify (`wt-b-bringin`), marks (`wt-b-viewer`).
- 11-15 09:02: **verify's coder handed back: `wip/b-verify` 0f7c44d, pushed** (from 4f1992e; `internal/bringin` only; the diff
  read by the main session: nothing to change). All three differences were verify's expectation, the catalogue was
  right: (1) the 119: a link counts only when its file is saved in effect; (2) 13 old video fingerprints have
  status ok and an empty frame list: no value, not carried, verify no longer expects them; (3) the 8: the
  catalogue's ladder (look-alike, same post) comes before a chat's preference, so a not-collected file may be
  held by the ladder: verify now puts each ladder hold on the line the row was expected on. Three named tests;
  `go test ./internal/bringin ./cmd/tgarchive-bringin` passed (52 s), gofmt and vet clean. No concurrent code.
  (3) rests on arithmetic from the report, not on per-row checks of real data: the new verify shows any swap.
- 11-15 09:02: **the fresh bring-in is running** (background command of this session; script
  `bringin2.sh` in the session's scratchpad): the program built from 0f7c44d into the session's `bin`; a new
  read-only copy of the old database (`VACUUM INTO` through `mode=ro`) into `tgarchive-b\oldcopy-2`; `run` into
  `tgarchive-b\old-archive-2\catalog.sqlite` (a new folder; the catalogue the owner's viewer uses,
  `old-archive`, is not touched); then `verify`. Reports beside them: `run-2.txt`, `verify-2.txt`. About 10
  minutes. If this session stops: check `old-archive-2` and the reports; if `run` did not finish, delete the two
  new folders and run the script again. **Not switched yet:** the owner's viewer stays on `old-archive` until the
  marks piece is in the program (the old marks must be translated on the catalogue they were made on).
- 11-15 09:11: **piece (a) is done as far as this session can take it.** The filters coder handed back (`wip/b-filters` a46139f,
  pushed: topic c0b2009, deleted 147238e, first appearance abe41d0, and a merge of the thumbnail branch with no
  conflict). The main session read `refresh.go`'s diff (the deleted mark at the new-message query, re-read for
  change-log kind 4, applied in the post loop; an ordered list `ix.deleted`): nothing to change.
  `go test ./internal/viewer` passed once on a46139f (178 s), gofmt and vet clean. The coder's one timing on the
  real catalogue (counts and ms): index 5.6 s (the PC was busy; not compared), unfiltered 23 / 76 ms (per post /
  per file), `first=1` 141 / 207, `only=1` 116 / 143, both 167 / 210, `deleted=1` 19 (0 entries: none of the 8
  deleted posts has a file); the largest group 4,463 files (one file with about 4,462 probable links; 14
  without probable). **Decided (main session):** accepted as it is, each listing is built once and kept; to fix
  with the review's fixes: a file with more than 20 probable links pulls in no probable neighbours (as rule B's
  "more than 20 posts"), which also removes the 4,463 group. Its doubts for the review: marks of old messages
  come only through the change log or a full read; the 64-file cap can break symmetry around a hub.
  **`wip/b-viewer` moved to a46139f and pushed; `tgarchive.exe` built 09:10 into the session's `bin`; start
  check by the main session** (real catalogue, empty library, a data folder of its own, port 8799, then stopped):
  14 requests all 200, pages 2 ms, shape 61 ms, `first=1` 192 ms then 12 ms, `only=1` 133 ms. The owner's
  starter `b\b-viewer.ps1` now passes one maker and `-thumb-ahead=false`. `MERGE-QUEUE.md` entries 5 (viewer) and
  6 (verify) written; the board's row says how to restart and what is new; two "Listed and unbuilt" lines marked
  built. **Running:** the marks coder (`wt-b-viewer`, `wip/b-marks`); the fresh bring-in (background command).
  **Next:** the read-only review of the whole viewer (brief to write), then its fixes with the probable-links cap.
- 11-15 09:12: **the independent read-only review of the whole viewer is started** (an Opus agent of this session;
  `BRIEF-B3-review.md`; it reads `wt-b-faces` at a46139f and writes only `REVIEW-B3-viewer.md` in this folder).
  Nobody writes in `wt-b-faces` meanwhile. Running besides: the marks coder, the fresh bring-in.
- 11-15 09:13: **the marks coder handed back: `wip/b-marks` 1e61724, pushed** (hidden posts and chats kept in a new table `mark`
  by stable key: shared, Telegram chat number, the owning account's Telegram user number, and for a post
  Telegram's message number; worked out as row ids once per index version before the swap; old `hidden` rows
  translated once on the first index and never deleted; marks for items not in the catalogue kept and counted on
  About; "Unhide all" leaves those). The main session read `marks.go` and the start and update hooks in
  `viewer.go`: nothing to change. Its own run: `go test ./internal/viewer` passed (176 s). **Merged by the main
  session with `wip/b-viewer` a46139f in `wt-b-viewer`: fa3c002 on `wip/b-marks`, no conflict, not pushed yet;
  the package's vet and whole tests are running once on the merged tree (background command).** Checked,
  counts only: the owner's `decisions.sqlite` has 0 hidden rows, so there is nothing to translate and the
  viewer can be switched to the fresh catalogue directly; the old catalogue's one account has its Telegram
  user number (to be checked equal on the fresh one). The fresh bring-in: copy done 09:03:36 (quick_check ok),
  `run` going since then. **Next:** when the tests pass: move `wip/b-viewer` to fa3c002, push, build, merge queue
  entry 7; when the bring-in is verified: copy the `viewer` folder to `old-archive-2`, point the starter at it.
- 11-15 09:15: **the fresh bring-in is done and verified** (program from `wip/b-verify` 0f7c44d): copy 62 s (2.99 GB,
  quick_check ok), `run` 10 min 29 s, exit 0; `verify` exit 0: "every count is equal or differs for a known
  reason" (the first time: the three fixed expectations hold on real data). New catalogue
  `tgarchive-b\old-archive-2\catalog.sqlite` (2.87 GB): 584,075 messages, 310,557 Telegram files, 241,447 saved
  (4 more than the first), 378 chats, 8 deleted marks; **0 files held as "same post"** (the first catalogue: 914
  by that reason today); held: 35,127 by the chat's preference, 28,746 probable copies of the old app, 3,110
  alternates, 1,870 look-alikes. The account's Telegram user number equals the first catalogue's. Reports:
  `run-2.txt`, `verify-2.txt`. **The owner's starter now uses `old-archive-2`** when it is there and carries the
  viewer's own folder over once at the next start (settings, 0 hidden rows, the thumbnail cache). The old
  folders `old-archive` and `oldcopy` are left in place (not deleted without the owner's word; about 6 GB).
- 11-15 09:16: **the marks are in: `wip/b-viewer` fa3c002, pushed** (the merge of `wip/b-marks` 1e61724 with a46139f; vet clean,
  gofmt clean, `go test ./internal/viewer` passed once on the merged tree, 178 s). `tgarchive.exe` built 09:16.
  Start check by the main session on the **fresh** catalogue (empty library, a data folder of its own, port 8799,
  stopped after): answering after 2.8 s, index 2.2 s, 9 requests all 200, the library 32 ms, `first=1` 107 ms,
  `only=1` 92 ms; 584,075 messages, 355,147 posts, 143,294 sets; marks elsewhere 0. `MERGE-QUEUE.md` entry 7; the
  board's row (how to restart, what is new, hiding is safe now). The board's message 3b is answered by this.
  **Running:** the independent review (`REVIEW-B3-viewer.md` when done; it reads a46139f, so the marks piece is
  outside it: read by the main session only). **Next:** the review's fixes in `wt-b-viewer` on `wip/b-viewer`
  (with: a file with more than 20 probable links pulls in no probable neighbours); then the listed features:
  the chat overlap table, filter chips, clutter per chat, probable copies under one tile, unplayable videos.
- 11-15 09:17: **an Opus coder started on the chat overlap table and the album's members-by-chats strip**
  (`BRIEF-B3-overlap.md`; copy `wt-b-viewer`, new branch `wip/b-overlap` from fa3c002; pushes after each part;
  a new library filter `with=<chat>`). PC: 10.8 GB free, CPU 54 %. Running besides: the independent review.
  The owner is told on the board that these are being built (listed features), not asked.
- 11-15 09:24: **the independent review is back: `REVIEW-B3-viewer.md`** (read-only, a46139f; read in full by the main session):
  5 confirmed, 4 probable. Confirmed: C1 the library jumps to the top whenever the index version changes
  between the shape and a block (on the old archive: for the first minute or so after start, while faces are
  read; with a collector: all the time); C2 previous / next ignore the time zone under a date filter; C3 "only
  where it first appeared" can hide a file that no shown copy stands for (groups are not symmetric; the 20-link
  cap alone does not fix chains); C4 the large picture can stay on the stand-in; C5 hiding a post shifts loaded
  blocks. Probable: P1 a tile whose large thumbnail alone exists; P2 no single build per listing; P3 with
  `first=1` the arrows walk a set's files again; P4 small paging gaps. Sound: cursors, versions never changed in
  place, the deleted list, locks, the thumbnail answer, the server's safety.
  **Decided (main session):** all fixed now, in the review's order of weight; C3 by deciding in first-place order
  plus the cap of 20 probable links; P3: with `first=1` a tile's date is its post's date and the arrows walk only
  the files the listing shows for that run; the catalogue pool of 4 connections is left (to be judged from the
  code). **An Opus coder started on the fixes** (`BRIEF-B3-reviewfix.md`; copy `wt-b-faces`, new branch
  `wip/b-reviewfix` from fa3c002; pushes after each fix). Running besides: the overlap coder (`wt-b-viewer`,
  `wip/b-overlap`). **For the integrator:** entries 5 and 7 can merge as they are; the fixes come as entry 8.
  **For the owner (on the board):** right after a start the library can jump back to the top while faces are
  being read; a fix is being built.
- 11-15 09:36: **the overlap coder handed back: `wip/b-overlap` aba944c, pushed** (from fa3c002; copy `wt-b-viewer`, clean): a page
  "Overlap" (per chat: files, only here, first appeared here, also elsewhere; per pair: shared, and what the other
  has that this one lacks; every number a link to the library showing exactly those files), library filters
  `with=` (a list), `without=`, `elsewhere=1`, and the album's members-by-chats strip on the post page. Kept
  table: once per index version and `sameprob` value, others wait for the one run, immutable once published.
  Its whole-package run failed once on the import wall (`cmp`), fixed (aba944c); **after that only the named
  tests and the wall test were re-run, not the whole package.** Real catalogue (counts, ms): table 56 ms (35 ms
  with probable copies apart), 213 chats with files, 12,203 pairs with a shared file, the largest pair 2,893,
  53 files in more than 20 chats; `with=` listings 22 to 111 ms. A test checks that every number on the page
  equals the tile count of its library link (per file) for every invented chat and pair. Not seen in a browser.
  **Not merged into `wip/b-viewer` yet:** it uses `appear.go`'s group, which the review's fixes change
  (first-place order, the 20-link cap); **next: when the fixes coder hands back, the same coder merges
  `wip/b-overlap` into `wip/b-reviewfix`, makes the numbers-equal-links test pass under the new rule, and runs
  the whole package once.** Running: the review's fixes (`wt-b-faces`, `wip/b-reviewfix`).
- 11-15 09:37: **an Opus coder started on "a video the browser cannot play is converted while it plays"** (listed, FEATURES 7;
  `BRIEF-B3-play.md`; copy `wt-b-viewer`, new branch `wip/b-play` from fa3c002). The old app's
  `ix_play.go` (12.20; read in full by the main session) is ported: ffmpeg to H.264 and AAC in fragmented MP4
  from `t` seconds, 2 at once, stopped with the request or after 2 minutes unread, asked only by a click (or once
  by the page when the browser reports it cannot decode). "Open in the system player" is not built. Running
  besides: the review's fixes (`wt-b-faces`, `wip/b-reviewfix`). Waiting, built: `wip/b-overlap` aba944c.
- 11-15 09:41: **the owner, in this session:** "Open in the system player isn't a terrible option to have, or simply a proper
  library that can play the videos. Also, we're talking browser, but what if we transition to a native app?"
  **Done at once:** "Open in the player" added to the play coder's brief by message (a second commit on
  `wip/b-play`: `POST /api/open/{id}`, this PC only, the file through the library root, a pref for the player
  program, Windows' default when empty). **Answered to the owner** (see the board, "Waiting for the owner"): no
  script library plays HEVC or MPEG-4 Part 2 in a browser without converting; the players that play everything
  are mpv and VLC, as a program the button opens now, or built into a native window later; a native shell around
  the same pages is a small step, a rewrite is not recommended because phones at home need the pages anyway.
- 11-15 09:48: **the review's fixes are handed back: `wip/b-reviewfix` e593adf, pushed** (from fa3c002; copy `wt-b-faces`), one
  commit per fix: d954088 C1 and C5 (the version number on the index; a block is cut from the listing its shape
  was built on; a stale one reloads in place, re-anchored by cursor; no jump to the top), 1439a12 P2 (one build
  per listing), e2869bf C2 (`tz` in the tile's link: a page-only fix), d25a32a C3 (first appearance decided in
  first-place order; a file with more than 20 probable links pulls in none), 08d4077 P3 (the tile's date is its
  post's; the arrows walk the run), b6f60a4 C4 and P1 (grid made apart from any size), 3e9a7f7 P4 (retries, the
  chat topic in the arrows, the copies tabs). Seven named tests. The whole package ran once (169 s): all passed
  but the import wall (`cmp`), fixed in e593adf; **not run whole again after that.** Real catalogue (counts, ms):
  `first=1` 251,564 tiles per file in 119 to 123 ms, 119,146 per post in 125 to 130 ms; `only=1` 188,507 / 96,141
  in 100 to 122 ms; the largest group 23 (was about 4,463); **the old rule hid 9,721 files that no shown copy
  stood for; the new rule hides 0 such**; 137 files have more than 20 probable links. The catalogue pool of 4,
  from the code in asked-only mode: two connections are left for requests and the makers' short queries; a
  request can wait only behind short queries, longest during a full read (2.3 s). Not seen in a browser.
  **Sent back to the same coder:** merge `wip/b-overlap` aba944c in, make the overlap table use the same decision
  as the listing (its numbers-equal-links test must pass unweakened), keep two versions' overlap tables, fix the
  small race between the decisions version and the hidden sets if it is a few lines, then the whole package once
  on the merged tree. After that: `wip/b-viewer` moves to it, build, start check, merge queue entry 8.
- 11-15 09:55: **pieces (b) and the overlap table are in: `wip/b-viewer` ee64eb5, pushed** (the merge of `wip/b-overlap` into the
  review's fixes by the fixes' coder; one conflict, in the `filter` struct, both sides kept; the overlap table
  now counts by `decideFirst`, so its numbers equal its links by construction, its test unchanged; the overlap
  cache keeps two versions' tables; the decisions version and the hidden sets read under one lock, with a test).
  `go test ./internal/viewer` passed once on ee64eb5 (170 s), gofmt and vet clean. Against 4f1992e the branch
  still differs only in `internal/viewer` and `cmd/tgarchive/viewer.go`. `tgarchive.exe` built 09:54. Start check
  by the main session on the fresh catalogue (empty library, own data folder, port 8799, stopped after):
  answering after 3.3 s, 15 requests all 200, the library 47 ms, `first=1` 157 ms then 11 ms, `only=1` 138 ms,
  the overlap table 131 ms then 2 ms. `MERGE-QUEUE.md` entry 8 (replaces 5 and 7); the board's row and two
  "Listed and unbuilt" lines. The main session read the listing cache's new code (in-flight entry, `peek`,
  `listingFor`): nothing to change; **not read by the main session: the page scripts and the merge commit's
  own changes.** Nothing was seen in a browser by anyone. **Running:** the play coder (`wt-b-viewer`,
  `wip/b-play`: conversion, then "Open in the player"). **Next, in order:** when it hands back: read `play.go`
  (a child process, a path handed to a program), merge onto `wip/b-viewer`, tests once, build, entry 9. Then
  the remaining listed features: filter chips with counts (and hidden as a chip), clutter per chat, probable
  copies under one tile with same / not the same (the marks now allow verdicts: key them by Telegram file
  identity), the home-network mode (needs its own security review), "no faces" and people (needs the bring-in to
  carry `ix_face_done` and the people).
- 11-15 09:56: **an Opus coder started on filter chips with counts, what is hidden as a chip, and clutter per chat** (listed,
  FEATURES 7 and 9; `BRIEF-B3-chips.md`; copy `wt-b-faces`, new branch `wip/b-chips` from ee64eb5). Running
  besides: the play coder (`wt-b-viewer`, `wip/b-play`).
- 11-15 09:57: **the play coder handed back: `wip/b-play` 63a49c1, pushed** (from fa3c002): c8f6c80 a converted copy while it
  plays (`GET /media/{id}/play?t=`, the old app's `ix_play.go` ported: same ffmpeg arguments, 2 at once, first
  bytes decide, stopped with the request or after 2 minutes; added: an idle timer before the first byte, a HEAD
  that says why, the page's own position bar and seek by restart, `web/js/play.js`); 014c4de "Open in the
  player" (`POST /api/open/{id}`: this PC only, token, video and audio only, the path from the catalogue
  through the library root, one argument, never a shell; pref `player_path` must be an absolute `.exe`; empty:
  Windows' default program through rundll32, only for files with a media extension); 63a49c1 a test. 13 named
  tests; its whole-package run passed (184 s). The import wall grew: `syscall` in `ffmpeg_*.go` and
  `launch_*.go`; `launch.go` is the second file allowed to start a program, with its own wall test. The main
  session read `launch.go`, `launch_windows.go` and `handleOpen`: nothing to change. Its doubts: the default
  program through rundll32 with spaces in a path is untried (the owner's first click is the test); an encoder
  that is listed but cannot run gives 422 on every copy; with autoplay on, the switch to a converted copy starts
  without a click; nothing seen in a browser. **Merged by the main session with `wip/b-viewer` ee64eb5 in
  `wt-b-viewer`: 0ea2923 on `wip/b-play`, three conflicts, both sides kept (`stats.go`, the end of `app.css`, two
  imports in `item.js`); not pushed; vet and the whole package are running once on it (background command).**
  Running besides: the chips coder (`wt-b-faces`, `wip/b-chips`). **Next:** tests pass: move `wip/b-viewer` to
  0ea2923, push, build, start check, merge queue entry 9, board.
- 11-15 10:03: **the play piece is in: `wip/b-viewer` 0ea2923, pushed** (vet clean, gofmt clean, `go test ./internal/viewer`
  passed once on the merged tree, 183 s). `tgarchive.exe` built 10:02. Start check on the fresh catalogue (empty
  library, own data folder, port 8799, stopped): answering after 2.8 s, 8 requests all 200, `first=1` 113 ms,
  the overlap table 112 ms, `/api/open` without the token 403. `MERGE-QUEUE.md` entry 9 (replaces 5, 7, 8); the
  board's row and three "Listed and unbuilt" lines. (A `tgarchive.exe` seen running on port 8797 is another
  session's demo from its own scratch folder: not touched.) **Running:** the chips coder (`wt-b-faces`,
  `wip/b-chips`). **Next:** its hand-back, merge, tests once, entry 10; then probable copies under one tile with
  same / not the same (verdicts keyed by Telegram file identity in `decisions.sqlite`; read FEATURES 3 and 9,
  TRIED-BEFORE 6 and 17 and COPY-CHECKS-STUDY E first: it borders the copies session's ground, the viewer only
  shows and records the owner's verdict, it releases or holds nothing).
- 11-15 10:04: read in full by the main session for the next piece: TRIED-BEFORE 6 and 17, FEATURES 3, COPY-CHECKS-STUDY E.
  **`BRIEF-B3-probable.md` written, not started** (probable copies under one tile with "+n probable", the best
  copy as the face; a review page with same / not the same; verdicts in `decisions.sqlite` by Telegram file
  identity; the viewer only shows and records, it releases or holds nothing). It changes `library.go` and
  `appear.go`, which the chips coder is in: **to start in `wt-b-viewer` on a new branch `wip/b-probable` cut
  from `wip/b-viewer` once the chips are merged into it.**
- 11-15 10:16: **the chips coder handed back and it is in: `wip/b-viewer` 1f8b681, pushed** (`wip/b-chips`: 02eccbf the chips row,
  hiding rules as chips with counts from the one listing build, "N of M"; 56205b6 clutter per chat in a new table
  `chat_clutter` of `decisions.sqlite` by the chat's stable key, stickers (a new file flag set in the index
  update, two lines) and "in more than 20 chats" as clutter kinds; 1f8b681 its merge of the play piece, one
  conflict in `settings.js`, both kept). `go test ./internal/viewer` passed once on 1f8b681 (167 s), gofmt and
  vet clean. `tgarchive.exe` built 10:15. Start check on the fresh catalogue (empty library, own data folder,
  port 8799, stopped): answering after 3.3 s, 10 requests all 200; **the default library is 175 ms the first
  time per index version (it was 32 to 47 ms): the "in more than 20 chats" kind builds the overlap table; 10 ms
  kept**; with clutter shown 29 ms; `first=1` 166 ms. Accepted for now (under the 200 ms budget, once per
  version); to watch when a collector writes. `MERGE-QUEUE.md` entry 10 (replaces 5, 7, 8, 9); the board's row
  and three "Listed and unbuilt" lines. Its doubts: a count floored at 0 in one edge case with a date filter;
  nothing seen in a browser. **An Opus coder started on probable copies under one tile and verdicts**
  (`BRIEF-B3-probable.md`; copy `wt-b-viewer`, branch `wip/b-probable` from 1f8b681; told that the default
  listing must not get slower). Free copy: `wt-b-faces`.
  **Left on the board's table for this track after that:** the home-network mode (password, HTTPS, its own
  security review: a design for the owner first) and "no faces" with a people page (the bring-in must carry
  `ix_face_done` and the people: `internal/bringin`, then a fresh bring-in).
- 11-15 10:17: **an Opus coder started on the viewer from other devices at home** (listed: FEATURES 7, roadmap D6;
  `BRIEF-B3-lan.md`; copy `wt-b-faces`, new branch `wip/b-lan` from 1f8b681). The design is the main session's:
  off by default; a second, HTTPS-only listener on one private address (`-lan`), the loopback listener
  unchanged; a self-made certificate with its fingerprint shown on this PC; a password set only from this PC
  (PBKDF2, 600,000 rounds); sessions in a `__Host-` cookie kept as hashes; 5 wrong tries per address and 20 in
  all per 15 minutes; only private remote addresses; other devices read and play only unless the owner allows
  hiding and marking; standard library only. **It is not to be merged before an independent security review**
  (to brief when it hands back). Running besides: the probable-copies coder (`wt-b-viewer`, `wip/b-probable`).
- 11-15 10:41: the integrator's board messages 10 and 12 read and answered on the board. **10:** the main branch moves to schema
  step 16 with its merge; **when the new head is pushed: rebuild `tgarchive.exe` and the bring-in from it, one
  fresh bring-in (a third folder), the starter pointed at it, then the board's restart line**; until then the
  owner's viewer stays on the build from `wip/b-viewer` and `old-archive-2` (both step 12, read-only). **12:**
  sent to the home-network coder as an addition (prefs and "Open in the player" never from the other listener;
  `player_path` not sent to it; the other listener holds one conversion at most; named tests).
- 11-15 10:41: **first look at the pages, by the main session, on a wholly invented archive** (`tgarchive fabricate`: 14 chats,
  4,000 messages, 2 accounts, 1,281 library files, into the session's scratchpad; the build of 1f8b681; port
  8796; stopped after). Seen in the built-in browser, no console errors on any: the library with the sidebar;
  `first=1` with a type filter (the chips row with two removable chips and "523 of 1,774 posts"); the Overlap
  page (15 chats, the four columns, the notes about tile mode and clutter); the Deleted page's empty sentence;
  a video's post page ("Play a converted copy" and "Open in the player" over the video, the chat's posts
  beside it); the right arrow steps to the next post and the address carries the time zone. **Not tried:** the
  album strip, hiding and the chips' counts, the per-chat clutter menu, Settings, a converted copy, the player
  button, scrolling while the index changes, a phone width. The real archive was not opened.
- 11-15 10:43: **the home-network coder handed back: `wip/b-lan` e5ffe20, pushed** (from 1f8b681; copy `wt-b-faces`): dd0e62a the
  server side (`lan.go`, `cert.go`, `password.go`, `session.go`, the guard and one `handle()` helper for every
  route in `server.go`), 3e6ca27 the command (`-lan`, `viewer-password`), 1099c73 the page (sign-in page,
  Settings block "Other devices at home", About), e5ffe20 the integrator's two points (the player program and
  "Open in the player" this PC's only; the other listener holds one conversion at most). 15 named tests in
  `lan_test.go`. The whole package passed once on the first three commits (174 s); after e5ffe20 only named
  tests were re-run (13 s). gofmt, vet clean; standard library only, `go.mod` unchanged; the import wall grew by
  the crypto packages. Differences from the brief: two per-system files in `cmd/tgarchive` for reading without
  echo; "unhide all" refused from devices even with the switch on; the verdict routes are not on this branch
  (**whoever merges `wip/b-probable` with it: register its routes through `handle()` and add them to
  `lanMarkRoutes`, or the route-walk test fails on purpose**). Its doubts: HSTS from a self-made certificate;
  `/api/about` shows folder paths to signed-in devices; hide controls shown on devices when the switch is off;
  the device-side page never seen in a browser.
  **Not merged, not listed. An independent security review is started** (an Opus agent; `BRIEF-B3-lan-review.md`,
  with the integrator's message 12; reads `wt-b-faces` at e5ffe20; writes only `REVIEW-B3-lan.md`). Nobody
  writes in `wt-b-faces` meanwhile. Running besides: the probable-copies coder (`wt-b-viewer`, `wip/b-probable`).
  Leaning (main session, to settle with the review): drop HSTS; no folder paths to devices; no hide controls
  on devices while the switch is off.
- 11-15 10:57: **the security review of the home-network mode is back: `REVIEW-B3-lan.md`** (read-only, e5ffe20; three throwaway
  tests on 127.0.0.1 in its scratchpad; findings and design points read in full by the main session). **Verdict:
  may be merged switched off as it is; three small fixes before the owner switches it on. No way found to read
  the archive, change anything, reach "Open in the player" or read or set the player program without signing
  in.** Confirmed: F1 any device at home can keep sign-in closed for everyone (20 wrong tries from four
  addresses, repeated); F2 `/api/about` gives this PC's folder paths to signed-in devices; F3 a dropped
  connection logs both ends' addresses (`writeJSON`); F4 the "always HTTPS" header never helps and can lock a
  device out for a year. Probable: F5 on Windows the TLS key and the password hash are protected only by the
  data folder's inherited access list (beside the catalogue); F6 the certificate names the app and the PC; F7
  no barrier behind a proxy or forwarded port. Twelve design points; three tests found to be partly stand-ins.
  **Decided (main session): everything fixed now**, sent to the same coder (`wt-b-faces`, `wip/b-lan`), in
  seven groups: (A) F2, F3, F4; (B) a "Reopen sign-in" button on this PC, IPv6 per /64; (C) the key, password
  and sessions under the user's profile, no host name anywhere, no CN; (D) every route gets an access class at
  registration (this PC / read / mark) and the handlers' own second lock everywhere; (E) Clear-Site-Data on
  sign-out, a conversion ends with its session, 2 s between conversion starts, 48 connections at most, a new
  certificate flagged; (F) weak passwords refused, the command's echo and folder check, three plain sentences
  in Settings; (G) no hide controls on devices while the switch is off. Then the whole package once.
  **Not merged, not listed until that hand-back.** Running besides: the probable-copies coder.
- 11-15 11:07: **the probable-copies coder handed back: `wip/b-probable` 11385ab, pushed** (from 1f8b681; copy `wt-b-viewer`,
  clean): 10682f7 the server side (a `verdict` table in `decisions.sqlite`, `POST /api/verdict`, verdicts applied
  in `appear.go`'s group, the fold kept with the overlap table in `fold.go`, the review answers in `review.go`),
  fe07692 the pages (review page with tabs and keys S, N, right arrow; "+n probable" badge; "Probable copies
  apart" switch and chip; folded files in the post strip with evidence and verdict buttons), 5ead2fe speed work,
  11385ab one existing test brought in line. Five named tests. Its whole-package run had that one failure; **the
  whole package was not run again after the fix: the main session is running it now, once (background
  command).** Real catalogue (counts, ms): 57,025 files folded behind 30,196 faces, the largest fold 21;
  104,367 pairs to review; the fold builds in 11 to 13 ms; the default library with the fold 37 ms per post and
  55 to 62 ms per file with the table built; the first default listing per index version about level with
  before (best estimate +3 ms). **Its choices, accepted by the main session:** exact copies are not folded
  (only the probable step); a verdict covers its own pair only; a file is folded only when its face has a tile
  in the same listing, so a filter can bring a folded file back and nothing disappears under a filter.
  **The verdict's key, for the copies session:** table `verdict(a_kind, a_tg, b_kind, b_tg, verdict, at)` in the
  viewer's `decisions.sqlite`; the fields are `tg_media.kind` and `tg_media.tg_id`, the smaller pair first (kind
  as text, then the id as a number); `verdict` is same or different; taking one back deletes the row.
  Not seen in a browser. **Next:** tests pass: move `wip/b-viewer` to 11385ab, push, build, start check, a look on
  invented data, merge queue entry 11, the board (with a message to session C about the key). Remember at the
  merge with `wip/b-lan`: the verdict route registered with an access class.
- 11-15 11:14: **probable copies are in: `wip/b-viewer` 11385ab, pushed** (vet clean, gofmt clean, `go test ./internal/viewer`
  passed once on it, 191 s, run by the main session). `tgarchive.exe` built 11:12. Start check on the fresh
  catalogue (empty library, own data folder, port 8799, stopped): answering after 4.9 s (busy PC), 8 requests
  all 200; **the default library 192 ms the first time per index version (175 before), 12 ms kept; `first=1`
  200 ms: at the 200 ms budget, on a busy PC; to measure again on a quiet one**; `/api/verdict` without the
  token 403. A look on the invented archive (port 8796, stopped; screenshots timed out because the pane was
  hidden, so by the page's text): the chip "Probable copies folded: 59"; the review page with "To review (126)",
  pairs with evidence, Same / Not the same / Skip; no console errors; **a verdict could not be clicked** (the
  pane was not on screen). `MERGE-QUEUE.md` entry 11 (replaces 5, 7 to 10); the board's row, one "Listed and
  unbuilt" line, and message 13 to session C with the verdict's key. Free copy: `wt-b-viewer`. **Running:** the
  home-network coder on the security review's fixes (`wt-b-faces`, `wip/b-lan`). **Next:** its hand-back: read
  the access classes and the guard myself, merge `wip/b-viewer` into it (the verdict and chat-clutter routes get
  their class), the whole package once, then list it as "merge switched off". Then: the rebuild and fresh
  bring-in when the main branch's new head is pushed; "no faces" and people (the bring-in must carry more).
- 11-15 11:15: **the home-network coder handed back the security review's fixes: `wip/b-lan` 0d5e551, pushed** (seven commits, A to
  G, one per group: 6668298, 065777c, 7e936a7, 24037ed, 47dce6e, 9eca09d, 0d5e551). The whole package passed once
  on 0d5e551 (201 s), gofmt and vet clean. **Do not use any commit of that branch between 7e936a7 and 9eca09d:**
  a broken quote in `web/js/lan.js` stopped every page loading; 0d5e551 fixes it. **Found by the coder and it
  matters for every earlier piece: `node --check FILE` passes a syntax error in a script that has import
  statements; only the module form catches it.** So every earlier "the scripts parse" in this file proved
  little; what stands in for it: the main session's two looks on invented data (1f8b681 and 11385ab: the pages
  loaded with no console errors) and the new test `TestPageScriptsParseAsModules` (in the package's tests from
  this branch on). The main session read `access.go` (a route without a class does not compile; a wrong class
  panics at start) and the guard `lanServer.ServeHTTP` (private address, TLS, Host, cross-site, sign-in, then the
  class): nothing to change. Its doubts: all link-local IPv6 addresses share one /64 for the limit of 5; a move
  of the files across drives is a copy and a remove; Ctrl+C restoring echo is not tested.
  **Sent back to the same coder:** merge `wip/b-viewer` 11385ab into `wip/b-lan`, the verdict route as "mark" with
  its second lock and no verdict buttons on a device while the switch is off, the module-parse test over every
  script, the whole package once. **Then:** `wip/b-viewer` moves to it; listed as "merge switched off; the owner
  may switch it on" with the review's file; build; a look on invented data.
- 11-15 11:17: **the integrator has merged this track up to `wip/b-viewer` 1f8b681 (60f7712) and verify's fix (3044745); the main
  head is e96f624, pushed, at schema step 16; `wip/b-viewer` 11385ab (probable copies) is listed and next.**
  Checked: the main head's `internal/viewer` is 1f8b681's plus three lines in `wall_test.go`; its bring-in is
  0f7c44d's exactly. All 16 scripts of 11385ab parse as modules (checked by the main session the right way).
  **For the integrator's message 10 (rebuild and one fresh bring-in from the new head):** a new local branch
  `wip/b-viewer2` 3d39431 in `wt-b-viewer` = 11385ab with the main head merged in (`-X ours`: the viewer is
  11385ab's plus the three wall lines, everything else is the main head's; checked by diff); **not pushed, not
  tested yet.** **The third bring-in is running** (background command; script `bringin3.sh` in the scratchpad):
  the bring-in built from that tree, a new read-only copy of the old database into `tgarchive-b\oldcopy-3`,
  `run` into `tgarchive-b\old-archive-3\catalog.sqlite` (schema 16, with the look-alike rule's preview hashes),
  `verify`; reports `run-3.txt`, `verify-3.txt`. PC at the start: 4.5 GB free, CPU 79 % (other sessions' full
  runs), so the viewer package's tests on 3d39431 wait until it ends. **Then:** tests once on 3d39431, build
  `tgarchive.exe` from it, the starter to `old-archive-3`, a start check, the board's restart line. If this
  session stops: delete `oldcopy-3` and `old-archive-3` unless `verify-3.txt` ends with "every count is equal".
- 11-15 11:23: **the home-network coder handed back the merge: `wip/b-lan` 83924a9, pushed** (`wip/b-viewer` 11385ab merged into
  0d5e551; three conflicts, both sides kept: the route list in `server.go` (every route through `register`;
  `POST /api/verdict` as "mark"), `handleAbout`'s answer, the end of `app.css`). In the merge commit: a second
  lock of their own for the three mark handlers (hide, chat clutter, verdict); no verdict buttons or S / N keys
  on a device that may not mark; a verdict log line made a fixed sentence; a new test
  `TestLANVerdictNeedsSwitch`. `go test ./internal/viewer` passed once on 83924a9 (202 s); gofmt and vet clean;
  every script passes the module parse test. **`wip/b-viewer` moved to 83924a9 and pushed** (the home-network
  mode is in it, switched off unless `-lan` is given). Not yet in `MERGE-QUEUE.md` (next step).
  **`wip/b-viewer2` rebuilt: 81d2295 (local, not pushed) = 83924a9 with the main head merged in** (`-X ours`;
  checked by diff: the viewer is 83924a9's plus the three wall lines; `cmd/tgarchive` has both sides; the rest
  is the main head's). The third bring-in is still running (it uses the main head's bring-in, the same code).
  **Next:** when it ends: `go test ./internal/viewer` once on 81d2295, build `tgarchive.exe` from it, the starter
  to `old-archive-3`, a start check, merge queue entry 12, the board.
- 11-15 11:33: **the third bring-in is done and verified** (the main head's bring-in, built from `wip/b-viewer2`): copy 91 s,
  `run` 13 min 2 s, exit 0; `verify` exit 0 ("every count is equal or differs for a known reason"). New catalogue
  `tgarchive-b\old-archive-3\catalog.sqlite` (2.87 GB), **schema step 16**: 584,075 messages, 310,557 Telegram
  files, 241,447 saved, 184,342 with a preview hash; held: 36,619 by the chat's preference, 28,746 probable
  copies of the old app, 3,110 alternates, **303 look-alikes (1,870 under the old rule)**, 0 "same post". The
  account's Telegram user number equals the earlier catalogues'. Reports: `run-3.txt`, `verify-3.txt`.
  `MERGE-QUEUE.md` entry 12 and the board's row were written at 11:24 (the home-network mode, off unless
  `-lan`). **Running:** vet and `go test ./internal/viewer ./cmd/tgarchive` once on `wip/b-viewer2` 81d2295
  (background command). **Next:** pass: build `tgarchive.exe` from 81d2295, the starter to `old-archive-3` (the
  viewer's folder carried over from `old-archive-2`), a start check, the board's restart line.
- 11-15 11:38: **the owner's program and catalogue are on the new head.** `go vet` clean and `go test ./internal/viewer` passed once
  on `wip/b-viewer2` 81d2295 (200 s; `cmd/tgarchive` has no tests); the branch is pushed to `private` for safety
  (it is not for the merge queue: entry 12's 83924a9 is). `tgarchive.exe` built from it at 11:38. Start check on
  `old-archive-3` (schema 16; empty library, own data folder, port 8799, stopped): answering after 4.4 s (index
  3.8 s, busy PC), 11 requests all 200 (`/signin` 404 on this PC's listener, as meant); the default library
  184 ms the first time, 12 ms kept; `first=1` 137 ms. `b\b-viewer.ps1` now takes the newest of `old-archive-3`,
  `-2`, `old-archive` that has a catalogue and carries the viewer's own folder over once from the newest older
  one that has it (today only `old-archive` has one; 0 hidden rows in it). **Seen in the session's `bin`: the
  owner's `tgarchive-viewer.exe` is still the build of 11-14 22:51 and `old-archive-2` never got a viewer
  folder: the owner has not restarted the viewer since last night, so nothing built since the sidebar and the
  saved copies has been seen by the owner.** The board's row says so. Old folders left in place, not deleted
  without the owner's word: `old-archive`, `old-archive-2`, `oldcopy`, `oldcopy-2`, `oldcopy-3` (about 15 GB).
  **State now: nothing of this track is running.** Copies: `wt-b-viewer` on `wip/b-viewer2` 81d2295 (clean),
  `wt-b-faces` on `wip/b-lan` 83924a9 (clean), `wt-b-bringin` on `wip/b-verify` (merged). **Next, in order:**
  (1) "no faces" in "Who is in it" and a people page: the bring-in must carry which files were looked at
  (`ix_face_done`) and the people; read how faces are carried first (`internal/bringin` run2, the catalogue's
  fingerprint kinds: a new kind may be the integrator's to add); (2) measure the default library on a quiet PC
  (184 to 192 ms the first time per index version: at the budget) and, if it stays there, keep the "more than
  20 chats" marks in the index instead of the overlap walk; (3) a second independent look at the home-network
  fixes if the owner wants to switch it on; (4) the pages as another device sees them, once it is on.
- 11-15 11:40: **an Opus coder started on "No faces" in "Who is in it"** (listed, FEATURES 7 and 9; `BRIEF-B3-nofaces.md`; copy
  `wt-b-faces`, new branch `wip/b-nofaces` from `wip/b-viewer2` 81d2295). Found by the main session first: the
  catalogue's fingerprint kinds are free text (no CHECK), so the bring-in can carry the old app's
  `ix_face_done` as a kind of its own, `face_done`, with nothing changed in `internal/catalog` and no schema
  step. Part 1: the bring-in carries it (plan and verify lines); part 2: the viewer reads it with the face
  rows and offers "No faces". **The people page is not built** (FEATURES: later; the old archive's 3,803 people
  are unnamed). After it: a fourth bring-in (about 14 minutes) so the owner's catalogue has the rows.
- 11-15 11:59: **"No faces" is handed back: `wip/b-nofaces` a713cfc, pushed** (from `wip/b-viewer2` 81d2295; copy `wt-b-faces`,
  clean): ad43816 the bring-in carries `ix_face_done` as kind `face_done` (plan and verify lines; the source
  is last in the list so an older run resumes right), a713cfc the viewer ("No faces": looked at, and no face
  that counts under the small-or-blurred choice; the media record's last free flag bit; a second index-only
  read per faces slice). Eight named tests. `go test` on the two bring-in packages passed (72 s, 2 s) and on
  the viewer once (193 s); gofmt and vet clean. Real data, counts only (the copy `oldcopy-3`, read-only):
  116,586 looked-at rows, all with a saved file's key, 54,045 with 0 faces, one model; 0 saved files with
  faces and no looked-at row. Its doubts: the rotating faces pass now covers about 116,000 files instead of
  62,000; the first read's extra cost is not measured on the real catalogue; a tile with no picture or video
  is never "No faces". `MERGE-QUEUE.md` entry 13. **The fourth bring-in is running** (background command;
  `bringin4.sh` in the scratchpad; the bring-in built from a713cfc; into `tgarchive-b\oldcopy-4` and
  `tgarchive-b\old-archive-4`; reports `run-4.txt`, `verify-4.txt`; about 15 minutes). PC: 7.5 GB free, CPU
  36 %. **Next:** verified: build `tgarchive.exe` from a713cfc, a start check on `old-archive-4` (how long the
  faces and looked-at rows take to read), the starter's list gets `old-archive-4` first, the board's row. If
  this session stops: delete `oldcopy-4` and `old-archive-4` unless `verify-4.txt` ends with "every count is
  equal"; the starter still points at `old-archive-3`, which is good.
- 11-15 12:17: **the fourth bring-in is done and verified** (program from a713cfc): `run` 12 min 14 s, exit 0; `verify` exit 0;
  face rows 84,213 equal, `face_done` 116,586 equal. Catalogue `tgarchive-b\old-archive-4\catalog.sqlite`
  (2.88 GB, schema 16, 584,075 messages, 241,447 saved). `tgarchive.exe` built from a713cfc at 12:14. Start
  check (empty library, own data folder, port 8799, stopped): answering after 3.3 s; the default library 152 ms
  the first time, 9 ms kept; `first=1` 108 ms; after the faces were read: "No faces" 202 ms the first time,
  "One person" 49 ms, "Two or more" 37 ms. **Not measured: how long the faces and looked-at rows take to
  read** (my loop compared two different counts and waited its full 3 minutes; they were complete by then).
  The starter's list now begins with `old-archive-4`; the board's row and the merge queue's entry 13 say so.
  **State now: nothing of this track is running.** Copies: `wt-b-faces` on `wip/b-nofaces` a713cfc (clean),
  `wt-b-viewer` on `wip/b-viewer2` 81d2295 (clean). Branch for the integrator: `wip/b-nofaces` a713cfc (entry
  13). Folders not deleted without the owner's word: `old-archive`, `-2`, `-3` and `oldcopy`, `-2`, `-3`, `-4`
  (about 21 GB; only `old-archive-4` and the `viewer` folder of `old-archive` are in use).
  **Every listed viewer feature on the board's table for this track is now built and listed, except the people
  page ("later").** **Next, in order:** (1) the default library's first load on a quiet PC (152 to 192 ms seen);
  if over 150 ms then: keep the "more than 20 chats" marks without the overlap walk; (2) time the faces read on
  the real catalogue from `/api/stats`; (3) a second read-only review of the pieces added after the first
  review (overlap, play, chips, probable, No faces: about 5,000 lines no independent reviewer has read);
  (4) when the owner has opened it: what the owner says.
- 11-15 12:18: **a second independent read-only review of the viewer is started** (an Opus agent; `BRIEF-B3-review2.md`; it reads
  `wt-b-faces` at a713cfc and writes only `REVIEW-B3-viewer-2.md`): everything added after the first review
  that no independent reviewer has read (the first review's fixes, Overlap and the strip, the converted copy
  and the player, chips and clutter per chat, probable copies and verdicts, "No faces"), not the home-network
  mode again. Nobody writes in `wt-b-faces` meanwhile. Its fixes will go to a coder in `wt-b-viewer` on a new
  branch from `wip/b-nofaces` a713cfc.
- 11-15 12:34: **the second independent review is back: `REVIEW-B3-viewer-2.md`** (read-only, a713cfc): 5 confirmed, 3 probable.
  Confirmed: (1) the library can reload without end after a preference is changed in another tab or on another
  device (a listing's identity lacks the preferences); (2) "+n probable" on a tile per post counts files that
  also have a tile of their own under a filter; (3) the review page's S and N keys can judge one pair twice
  and skip the next; (4) the album strip tests the wrong thumbnail flag; (5) the "Hidden posts" and "Clutter
  hidden" chips open listings whose counts differ from the chip's number. Probable: a failed shape reloads
  with no pause; the arrows with "Hide not downloaded"; cost notes. **Decided: all fixed now.** **An Opus coder
  started** (`BRIEF-B3-review2fix.md`; copy `wt-b-faces`, new branch `wip/b-review2fix` from a713cfc; one commit
  per finding, pushed). The owner's build (a713cfc) has these five until the fixes are in: the board says so.
- 11-15 12:52: **the owner, in this session:** "yes, plan the native window with mpv, but leave it to the next session to
  implement" and "where is the current viewer and how do I access it?" **Done:** `PLAN-native-window.md` written
  (one new program `tgarchive-window.exe` around the same pages in a WebView2; mpv as a child process drawing
  into the window, driven over its IPC pipe, no cgo; a small bridge from the page's video code; a one-day
  spike first to settle the binding, the window order, the keys and mpv's start time; the path rule shared
  with "Open in the player"); the board's item 10 marked decided. **Nothing of it is built: it is the next
  session's first new piece.** Checked on this PC: WebView2 runtime present, mpv not installed, VLC installed.
  Answered: the viewer is started by double-clicking `b\b-viewer.cmd` in the project folder; it opens
  `http://127.0.0.1:8798` in the browser; it was not running at 12:40 (nothing listened on 8798).
- 11-15 12:56: **the second review's fixes are in the owner's build: `wip/b-review2fix` 86a397d, pushed** (from a713cfc; copy
  `wt-b-faces`, clean; 7 commits, one per finding, 6877a65 to 86a397d; eight named tests in
  `review2fix_test.go`; `go test ./internal/viewer` passed once, 194 s; gofmt and vet clean). What changed: the
  listing identity is `run.gen.dec` and saving preferences bumps the decisions version; the library's reload is
  bounded (3 tries, 1, 2, 4 s, then a "Reload" line); "+n probable" counts only behind faces with a tile; busy
  cards on the review page; the strip's `gridOf`; the hiding chips open what they count (`hidden=1&clutter=show`,
  a new `clutter=only`); the arrows' walk; `first=1` takes the kept overlap decision. `tgarchive.exe` built
  12:54. Start check on `old-archive-4` (empty library, own data folder, port 8799, stopped): answering after
  3.3 s, 9 requests all 200; the default library 181 ms the first time, 11 ms kept; `first=1` 85 ms. A look on
  a new invented archive (port 8796, stopped; by the page's text): the library, `clutter=only` with its chip,
  the review page ("To review (111)"), Settings with "Other devices at home"; one console line "failed to load
  resource: connection refused" was seen twice and not traced (most likely the tab's earlier page asking the
  viewer I had stopped). `MERGE-QUEUE.md` entry 14; the board's row (with how to open the viewer and the
  native-window decision).
  **State now (enough to take over from this block alone): nothing of this track is running.**
  - **For the integrator:** `wip/b-review2fix` 86a397d (entry 14) replaces every earlier entry of this track.
  - **The owner's program:** `tgarchive.exe` of 86a397d in the session's `bin`; catalogue `old-archive-4`; the
    owner starts it with `b\b-viewer.cmd` (`http://127.0.0.1:8798`). The owner has not opened anything built
    since 11-14 22:51.
  - **Copies:** `wt-b-faces` on `wip/b-review2fix` 86a397d; `wt-b-viewer` on `wip/b-viewer2` 81d2295; `wt-b-bringin`
    on `wip/b-verify` (merged). All clean.
  - **Next session, in order:** (1) what the owner says after opening it; (2) `PLAN-native-window.md`: the
    one-day spike, then the build; (3) the default library's first load per index version (150 to 190 ms on the
    real catalogue: at the budget; the "more than 20 chats" clutter kind's overlap walk is the cost); (4) time
    the faces read on the real catalogue; (5) the device-side pages of the home-network mode, once the owner
    switches it on; (6) the people page stays "later".
  - **Not deleted without the owner's word (about 21 GB under `tgarchive-b`):** `old-archive` (its `viewer`
    folder is what the starter carries over), `old-archive-2`, `-3`, `oldcopy`, `-2`, `-3`, `-4`.
- 11-15 13:00: **the owner opened the viewer (12:54, about a minute): "It loads. The first video I clicked took a long time to
  play. There's basically no thumbnails for anything."** Measured from the viewer's own cache, counts only: 9
  thumbnails made (all photos), 70 failure marks (all videos: 42 .mp4, 27 .m4v, 1 .wmv), all within 48 s. Not
  staging (2 staged paths are saved rows; 5,174 files, 232 GB wait in the old app's staging). **Cause, proven
  with a small Go probe (`pathprobe` in the scratchpad): the PC's stored PATH has one entry with a stray quote
  (entry 18 of 37); Go's `exec.LookPath` then finds nothing after it, and ffmpeg is in entries 23 and 36;
  PowerShell finds it.** So the owner's viewer had no ffmpeg: no video thumbnail (each got a day-long failure
  mark) and no converted copy. Sessions' shells are not affected, which is why every test and check passed.
  **Fixed at once in the starter** (`b\b-viewer.ps1`: ffmpeg's folder first in the viewer's PATH and
  `FFMPEG_PATH` set; the probe then finds it) **and the 70 wrong marks deleted** (marks only; the 9 thumbnails
  kept). **An Opus coder makes the program robust** (`BRIEF-B3-ffmpeg.md`; `wt-b-faces`, new branch
  `wip/b-ffmpeg` from 86a397d): a `-ffmpeg` flag, `FFMPEG_PATH`, PATH split by hand; no failure mark when the
  tool is missing; a line on the page; failures counted by a fixed word; a counts-only `stats-last.json` in
  the viewer's data folder so a session can read timings after the owner closes it. **The slow first video is
  not diagnosed** (nothing measured; candidates only: the file read from the NAS over the Wi-Fi the old app's
  copies fill, a video whose index is at the file's end, requests waiting behind the first minute's faces
  read on the pool of 4 catalogue connections). Board: the row and message 14 (for every session that starts
  ffmpeg in a program the owner runs).
- 11-15 13:07: **the owner restarted: "The thumbnails are there, loading, but slowly. Going forward, we'd obviously like to
  cache/generate them in the background. Also, some groups seem kinda junk, so an option to hide them (from the
  actual chat page) would be good", then "From the channel page rather"** (with a picture of one chat's own
  page header). The ffmpeg cause is confirmed by the running viewer's counters (numbers only, 13:05): 152
  thumbnails made, 0 failed, 329 ms median and 572 ms at the 95th percentile each, a library read 76 ms
  median, `video_frames` true; about 60 a minute appeared (one maker; the page asks two at a time with
  growing pauses). **Done at once:** the starter's default is 3 makers (at the next restart). **Sent to the
  ffmpeg coder as an addition** (`wt-b-faces`, `wip/b-ffmpeg`): 4 asks at once with shorter pauses; a new
  mode `-thumb-ahead=paced` with `-thumb-gap` (default 1 s): one background job at a time from the existing
  walk (newest first), asked work always first, counted, with "N of M done, about H hours left" in Settings.
  **Why paced and not full speed (main session):** the project's rule that nothing in the background competes
  with the old app's copies on the Wi-Fi to the NAS; at one a second the whole library's about 380,000
  pictures and videos take about 4.4 days; the owner decides the pace once the bytes per thumbnail are known.
  **An Opus coder started on hiding a chat** (`BRIEF-B3-hidechat.md`; `wt-b-viewer`, new branch
  `wip/b-hidechat` from 86a397d): a "Hide this chat" button on a chat's own page, hidden chats gone from the
  Chats list (with "N hidden: show"), from the sidebar's list and the Overlap rows, several at once on the
  Chats list. My reading of the owner's two sentences; said to the owner.
- 11-15 13:11: **the owner, on the background pace: "Faster, and probably built on the NAS directly as part of the downloader
  we're also constructing. Tag it for the board and integrator. Don't need to do it here. Time to wrap up soon."**
  Done: the ffmpeg coder told that the paced mode's gap defaults to 0 (one background job at a time, about 3 a
  second, about a day and a half for the library); the board has message 23 to the integrator and a "Listed and
  unbuilt" row (thumbnails made on the NAS by the NAS downloader, read by the viewer as a second source: the
  core track's, no session, no roadmap row). **Not built here, by the owner's word.**
  Also: **the integrator's message 16 (11:46) was read only now**: the main head is 6f17c7f (it has this track
  up to 83924a9 and a fix to `TestLANStreamsGapsConnections`: a gap of a minute and `lastLAN` moved instead of a
  sleep, bfc3454); entries 13 and 14 were cut from a branch holding e96f624. My own board message about ffmpeg
  was numbered 14 by mistake and is now 22.
  **Wrapping up, in this order:** (1) both coders hand back (`wip/b-ffmpeg` in `wt-b-faces`, `wip/b-hidechat` in
  `wt-b-viewer`); (2) one last branch: both merged, then the main head 6f17c7f merged in **taking the main
  branch's lines for that test**; (3) `go test ./internal/viewer` once on it, vet, gofmt; (4) build
  `tgarchive.exe`, the starter passes `-thumb-ahead=paced`, a start check; (5) one merge queue entry replacing
  13 and 14, the board's row, a take-over block here. No new piece is started.
- 11-15 13:15: **the hide-chat coder handed back: `wip/b-hidechat` 7bcce25, pushed** (from 86a397d; copy `wt-b-viewer`, clean): a
  "Hide this chat" button on a chat's own page (with "Show again" in its place); hidden chats left out of the
  Chats list ("N hidden: show", "212 chats listed, 12 hidden", several at once after "Select", one request per
  chat); `/api/chats` leaves them out unless `hidden=1` and counts shown + hidden = total; the "Also in…" list
  leaves them out. The sidebar's list, the Overlap rows and search already did. Two named tests and one
  extended; `go test ./internal/viewer` passed once on it (187 s); gofmt and vet clean; every script parses as
  a module. Not seen in a browser. **Waiting for the ffmpeg coder, then the last merge** (the order is in the
  entry above).
- 11-15 13:17: **the owner corrected the reading: "I wanted them to stay there as well, both the chats list and its own page."**
  So a hidden chat stays listed on the Chats page (greyed, a "Hidden" badge, "Show again"; a switch "Leave
  hidden chats out", off by default) and its own page stays as built; hiding still leaves its posts out of the
  library and the chat out of the sidebar's list, "Also in…" and Overlap. **Sent back to the hide-chat coder**
  (`wt-b-viewer`, `wip/b-hidechat`: one more commit, the whole package once). Do not merge 7bcce25 alone.
- 11-15 13:22: **hiding a chat, corrected, is handed back: `wip/b-hidechat` bbd6b95, pushed** (on 7bcce25): hidden chats stay on the
  Chats list (greyed, "Hidden" badge, "Show again"; a switch "Leave hidden chats out", off by default);
  `/api/chats` lists them by default, `hidden=0` leaves them out. `go test ./internal/viewer` passed once on it
  (197 s); gofmt and vet clean. Not seen in a browser. Waiting for the ffmpeg coder (`wt-b-faces`), then the
  last merge.
- 11-15 13:23: **the ffmpeg coder handed back: `wip/b-ffmpeg` ab09bfb, pushed** (from 86a397d; seven commits f399062 to ab09bfb):
  ffmpeg found by a `-ffmpeg` flag, `FFMPEG_PATH`, `LookPath`, then PATH split by hand with quotes dropped; no
  failure mark when the tool is missing, marks carry one fixed word, stale video marks dropped at start; a
  line on the library page and in Settings / About when ffmpeg is missing; failures counted by word; a
  counts-only `stats-last.json` in the viewer's data folder once a minute and at stop (time to first byte of
  file and play, ranges, library open and first read, first index and faces read times); the page asks four
  at once and again after half a second; `-thumb-ahead=paced` with `-thumb-gap` 0: one background job at a
  time, asked work first, with "N of M done, about H hours left". Ten named tests; `go test
  ./internal/viewer` passed once on it (201 s). Its notes: the walk does not resume after a restart (it starts
  at the newest post and passes over what is made by a memory lookup); bytes read are known only for
  pictures; the stderr-to-word mapping is a guess.
  **The last branch of this session: `wip/b-viewer3` in `wt-b-faces`, 16376c9, local, not pushed yet** =
  `wip/b-ffmpeg` ab09bfb + `wip/b-hidechat` bbd6b95 (no conflict) + the main head 6f17c7f (`-X ours`, no
  conflict reported; outside this track's packages it equals the main head) + the main branch's test fix
  bfc3454 applied (it had not come through the merge). **vet and the whole tests of the viewer and the
  bring-in are running once on it (background command).** Next: pass: push, build, the starter to the paced
  mode, a start check, one merge queue entry, the board, the take-over block.
- 11-15 13:29: **the last branch passed and is pushed: `wip/b-viewer3` 16376c9** (`go vet` clean on the four packages; `go test`:
  the viewer 185 s, the bring-in 65 s, its command 1 s, all passed once; gofmt clean). `tgarchive.exe` built
  from it at 13:28. Start check as the starter runs it (3 makers, `-thumb-ahead=paced`; the real catalogue
  `old-archive-4`, an empty library, own data folder, port 8799, stopped): answering after 6.4 s (busy PC), 8
  requests all 200, the default library 170 ms the first time and 11 ms kept, `first=1` 99 ms; ffmpeg found
  "by the PATH read without quote characters" (so the sessions' own shells never had ffmpeg for a Go program
  either). The starter passes `-thumb-ahead=paced`. `MERGE-QUEUE.md` entry 15; the board's row rewritten short.

## State now (11-15 13:32): enough to take over from this block alone
Session B3 ends here (the owner: "Time to wrap up soon"). Nothing of this track is running: no coder, no
background command, no viewer started by the session.
- **To merge (the integrator):** one branch, `wip/b-viewer3` 16376c9 on `private`, `MERGE-QUEUE.md` entry 15. It
  replaces entries 13 and 14 and has the main head 6f17c7f merged in. Already merged before it: everything up
  to the home-network mode (`wip/b-viewer` 83924a9). After the merge: cut every new piece from the new head.
- **The owner's program:** `tgarchive.exe` of 16376c9 in the session's `bin`
  (`%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b\bin`); the catalogue
  `old-archive-4` there (schema step 16; the fourth bring-in, verified); started by the owner with
  `b\b-viewer.cmd` in the project folder (`http://127.0.0.1:8798`; 3 makers; the background mode; ffmpeg
  handed over by the starter as well as found by the program). The viewer's own folder is
  `old-archive-4\viewer` (`decisions.sqlite`, the thumbnail cache, and from this build `stats-last.json`).
- **What the owner said today, in order:** asked about the system player and a native app (09:45); "yes, plan
  the native window with mpv, but leave it to the next session to implement" (12:40); opened the viewer: "It
  loads. The first video I clicked took a long time to play. There's basically no thumbnails for anything";
  after the fix: "The thumbnails are there, loading, but slowly. Going forward, we'd obviously like to
  cache/generate them in the background. Also, some groups seem kinda junk, so an option to hide them (from the
  actual chat page) would be good", "From the channel page rather"; on the pace: "Faster, and probably built
  on the NAS directly as part of the downloader we're also constructing. Tag it for the board and integrator.
  Don't need to do it here"; on hidden chats: "I wanted them to stay there as well, both the chats list and
  its own page."
- **Next session, in order:**
  1. Read `stats-last.json` in `old-archive-4\viewer` after the owner has used the new build (numbers only):
     the time to first byte of `/media/{id}/file`, the share of range requests, the library's open and first
     read, the faces read's length. That is the evidence for **the slow first video, which is not diagnosed**.
     Candidates, none measured: the file read from the NAS over the Wi-Fi the old app's copies fill; a video
     whose index is at the file's end; requests waiting behind the first minute's faces read (the pool of 4
     catalogue connections).
  2. What the owner says after using it: hiding chats, the background thumbnails (does the walk's pace hold;
     it restarts at the newest post after every start), the review page, "Open in the player" (its first
     click on a real file is still its first real try; VLC is installed, mpv is not).
  3. `PLAN-native-window.md`: the one-day spike, then the build.
  4. The default library's first load per index version: 150 to 190 ms on the real catalogue, at its 200 ms
     budget; the "in more than 20 chats" clutter kind's overlap walk is the cost.
  5. A browser look at what nobody has seen: the hide button and the Chats list's badge, the Settings lines,
     the pages as another device sees them (needs the home-network mode switched on by the owner).
  6. The people page stays "later". Thumbnails made on the NAS are the core track's (board message 23).
- **Lessons of this session, for whoever continues:**
  - **Run the program the way the owner's starter runs it before saying it works.** Every test and start
    check passed while the owner's viewer had no ffmpeg (a stray quote in the PC's PATH hides everything after
    it from Go's `exec.LookPath`; board message 22).
  - `node --check FILE` passes a syntax error in a script with imports; the package's
    `TestPageScriptsParseAsModules` is the real check.
  - Anything under `%LOCALAPPDATA%` written by a session is really under
    `%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local`.
  - A coder's "the whole package passed" is often on the commit before its last fix: run it once yourself on
    the commit that is listed.
  - The integrator squashes: a later branch of this track must have the main head merged in (`-X ours` kept
    this track's newer viewer files) and any fix the integrator made to this track's files applied by hand.
- **Copies:** `wt-b-faces` on `wip/b-viewer3` 16376c9; `wt-b-viewer` on `wip/b-hidechat` bbd6b95; `wt-b-bringin` on
  `wip/b-verify` (merged). All clean. Branches on `private` that entry 15 supersedes: `wip/b-nofaces`,
  `wip/b-review2fix`, `wip/b-ffmpeg`, `wip/b-hidechat`, `wip/b-viewer2`, and the earlier `wip/b-*`; none
  deleted (not without the owner's word).
- **Not deleted without the owner's word (about 21 GB under `tgarchive-b`):** `old-archive` (its `viewer` folder
  was the first one), `old-archive-2`, `-3`, `oldcopy`, `-2`, `-3`, `-4`. Only `old-archive-4` and `bin` are in use.
- **Briefs and reviews of this session (project folder):** `BRIEF-B3-*.md` (17), `REVIEW-B3-viewer.md`,
  `REVIEW-B3-viewer-2.md`, `REVIEW-B3-lan.md`, `PLAN-native-window.md`.

## Session B4 took over from B3 (11-15 15:36)
Started by the review session with "take over the viewer track". Read so far: `CLAUDE.md`'s archiver section, the
board (all of it, messages 16, 22, 23, 25 for this track), the block above, `PLAN-native-window.md`. Nothing of
this track is running (no coder, no test run). Every new piece is cut from f0e3f0c.

### 15:40: the slow first video, read from the numbers (nothing changed yet)
The owner started `b\b-viewer.cmd` at 15:38 by himself (the build of 16376c9, 13:28) and clicked within the first
minute. `stats-last.json` (written 15:39, uptime 67 s; counts and timings only):
- `/media/{id}/file`: 7 requests, all 7 with a range. Time to the first byte: median 113 ms, **worst 18,079 ms**.
- The library's open (the root's check, the open, the stat; 188 opens, the thumbnail makers' among them): median
  107 ms, 95th 272 ms, **worst 23,572 ms**.
- The first read of an opened file (24 counted): median under 1 ms, worst 17.5 ms.
- The faces read: still running at 58 s, 8.2 s of it reading, 19 slices, the longest 982 ms; index updates
  median 414 ms. `/media/{id}/thumb` (55 requests, it asks the catalogue too): median 1 ms, 95th 6 ms.
  `/api/post/{id}` (3): median 405 ms.
**Which candidate:** it is the library on the NAS, and of it **the open, not the read**. Not the read (once a file
is open its first bytes come in at most 17.5 ms). Not a video with its index at the end (that would show as more
range requests, each of which was fast: 6 of 7 came in about 0.1 s). Not the faces read holding the catalogue's
connections (the thumbnail route asks the catalogue and answered in 1 ms meanwhile). What the numbers cannot say
yet: which step of the open stalled (the timing lumps four: waiting for the library's lock, the root's check,
the open through `os.Root`, the stat), and whether the 18 s request waited on its own open or behind another
one: `library.handle()` holds the library's lock across a network `Stat` of the root on every open, so one slow
answer from the share stalls every open in the program (3 thumbnail makers and the background walk were opening
files at 2.6 a second at that moment).
Next: the history files, in full; then a brief (the open's four steps timed apart; the root's check out from
under the lock and off the click's path; "opening…" said at once) with the old app's note at its top.

### 15:45: history read; the fix briefed; a coder started
- **Read in full by this session before briefing** (the rule): `TRIED-BEFORE.md`, `LESSONS.md`,
  `WINDOW-EVIDENCE.md`, `COPY-CHECKS-STUDY.md`, `TELEGRAM-FACTS.md`, `LESSONS-ix12.29-servers.md`,
  `LESSONS-ix12.30-live.md`, `LESSONS-viewer-ix12.32.md`, `ANSWERS-for-archiver-4.md` to `-9.md`.
- **A second snapshot (uptime 187 s):** 682 opens by then, the worst still the 23.6 s of the first minute, the
  95th 177 ms; the faces read finished at 172 s. So the stall is one event in the first minute after start.
  The integrator read the same numbers at 15:41 (`SESSION-11-PROGRESS.md`); the owner said then: "The first
  video was slow again."
- **The old app beside it:** its viewer opens a file with one open and one stat, no shared lock, no check of
  the library folder per request (`wt-v12.32` `viewer_media.go` `handleFile`); it has no time-to-first-byte
  number on the real NAS. Ours: median 0.11 s, worst 18 s.
- **Brief:** `BRIEF-B4-open.md` (four parts: the open's steps timed apart, with slow opens by seconds since
  start and whose they were; no network call under the library's lock and no root check per open; a person's
  open goes before the makers'; the page says "Opening the file from the library… N s").
- **Running:** one Opus coder (high effort), started 15:44 from this session; copy `wt-b-viewer`, branch
  `wip/b-open` cut from f0e3f0c, pushed to `private` as it goes. PC before the start: 5.8 GB free, CPU 68%.
- **Not committed or pushed by this track yet:** nothing but these notes.
- **Next:** read the coder's risky part (the root's lifetime, the makers' wait, `Close`); one independent
  review; its fixes; then the full runs once (whole tests and the race detector on `internal/viewer`, said
  first with the minutes); `MERGE-QUEUE.md`. Meanwhile: look up the WebView2 bindings and write the spike's
  plan; the board message to the integrator about `go.mod`.

### 15:48: a browser look on invented data; the spike planned; two things asked
- **Looked at in a browser, on an invented archive in this session's scratch folder** (the merged head's
  build, port 8811, stopped again): a chat's page has "Hide this chat"; after it "Hidden: its posts are left
  out of the library. Show again"; the Chats list says "21 chats, 1 hidden", marks the row "Hidden" with
  "Show again", and has the switch "Leave hidden chats out"; Settings shows every line (ffmpeg found and how,
  how thumbnails are made, the home-network part with where its key is kept). **Two defects found:** a chat
  that is not hidden shows the word "null" under its header (`chat.js`: `append(null)`), and Settings says
  "1 chats". Both sent to the running coder as part 5 of brief B4-1 (same branch). Smaller, not sent: the
  three switches in Settings are named by their setting keys for a screen reader. **Still not looked at:**
  the pages as another device sees them (the owner has not switched the home-network mode on).
- **The spike is planned:** the last section of `PLAN-native-window.md` (what was looked up, with sources;
  the throwaway module; the four questions and what is written down for each; what comes out).
- **Asked:** board message 28 (the integrator: one new pure-Go requirement for `internal/window`, in
  principle); "Waiting for the owner" item 15 (two downloads: mpv, about 34 MB, and the Go module for
  WebView2). The spike starts when the owner says yes and the PC has room.
- **Running:** the Opus coder on `wip/b-open` (copy `wt-b-viewer`). Nothing else.
- **Next:** the coder's hand-back; my read of the root's lifetime, the makers' wait and `Close`; one
  independent review; fixes; the full runs once; `MERGE-QUEUE.md`.

### 15:52: the owner on files that are not downloaded; a second coder started
- **The owner, to this session, 15:49:** "Do the settings save between sessions? For example, seeing not
  downloaded files in the library isn't useful. They should be hidden, or they should link to their known
  duplicates."
- **Read in the code before answering:** the Settings page's preferences are kept by the server in the
  viewer's own file (`decisions.sqlite` beside the catalogue), for every browser, and survive a restart; the
  starter carries that folder over to a fresh bring-in. **Not kept:** what is chosen in the library's
  sidebar (it lives in the page's address only), so "FILE: Saved" is gone at the next start. The post page
  already shows a saved copy in place of a file that is not downloaded (`standInOf`); the library's tiles do
  not: they show "Not downloaded".
- **Brief:** `BRIEF-B4-notsaved.md` (a remembered rule with three values, default: the saved copy in the
  file's place where one is known, the rest left out; an explicit FILE filter wins; a chip with the count
  and a way back; one bit per file in the index, no walk per request; the 200 ms budget kept).
- **Running, both started from this session:** (1) Opus coder on `wip/b-open`, copy `wt-b-viewer`, since
  15:44 (brief B4-1 and its part 5); (2) Opus coder on `wip/b-notsaved`, copy `wt-b-faces`, since 15:52
  (brief B4-3). PC before the second start: 6.0 GB free, CPU 61%.
- **Written and waiting:** `BRIEF-B4-open-review.md` (the independent review, after my read);
  `BRIEF-B4-window-spike.md` (the spike: a copy of its own, `wt-b-window`, to be made; waits for the owner's
  yes to the two downloads and for room on the PC).
- **Next:** each hand-back is read (B4-1: the root's lifetime, the makers' wait, `Close`; B4-3: the
  incremental update, the counts, paging); both branches merged into one, `wip/b-viewer4`, in `wt-b-viewer`;
  one independent review of that; fixes; the full runs once (whole tests and the race detector on
  `internal/viewer`), said first with the minutes; `MERGE-QUEUE.md`; the owner's build in `bin` and the
  starter's line on the board.

### 15:57: the integrator's two messages (15:40, 15:49) read; converted videos measured; the player button tried
- **The owner, through the integrator (15:49):** "The second and third videos seem to play quickly. Some of the
  videos need to be converted, and that is very slow, with the length/progress bar filling slowly, so seeking
  is impossible." A second start of the viewer had no stall (file route worst 212 ms, opens worst 365 ms):
  so the 18 s is not at every start; it looks like the first touch of the NAS after it was left alone.
  Which step stalls, and when in a run, is what brief B4-1's part 1 will say at the owner's next use.
- **Converting, measured on two invented clips** (this session's scratch folder, a local disk, the viewer's own
  ffmpeg arguments, ffmpeg 7.1.1, the PC at 47 to 58% CPU; one run each: "looks like"):
  | Clip | libx264 veryfast (what the viewer uses today) | h264_nvenc | decoded on the card too |
  |---|---|---|---|
  | 1080p HEVC, 30 s | 9.3 times real time | 11.2 | not run |
  | 2160p 10-bit HEVC, 20 s | 3.7 | 5.0 | 4.5 |
  **So the encode is not the slow part, and the graphics card would gain little: not built.** What is left
  is the source's read from the NAS over the Wi-Fi (not measured: no session opens a real file), while the
  viewer's own makers read the NAS at the same time. The PC has an RTX 5070 Ti and a 6-core CPU; the
  viewer takes libx264 first (the old app's list).
- **Seeking a converted copy exists** (the page's own bar under the video asks for the stream again from
  there; it needs the video's length): read-only count on the brought-in catalogue: 150,497 of 152,055 saved
  videos have a length; 1,215 are larger than 1920 on a side, 6,374 between 1281 and 1920. The browser's own
  bar inside the video only covers what has arrived: that is what "fills slowly".
- **"Open in the player" tried for the first time, on an invented clip, the viewer started from PowerShell as
  the owner's starter starts it:** one click, a player started (this PC's default program for .mp4:
  PotPlayer), the viewer's counts say started 1, failed 0. Closed again; no test viewer or player left
  running. **So today's way to watch a video that needs converting, with free seeking, is that button**
  (on the post page beside "Play a converted copy"); the native window with mpv removes the converting.
- **Added to the running coder's brief (part 6, same branch `wip/b-open`):** each conversion's speed measured
  from ffmpeg's own progress lines into the snapshot (median, worst, how many slower than the video plays,
  seconds to the first video written); the background walk gives way while a converted copy plays (counted);
  one line under a converted copy saying how to jump and where the player button is.
- **Running:** the two Opus coders as at 15:52. Nothing else of this track runs.

### 15:59: the integrator on crafted files and ffmpeg; part 7 added to the open piece
- **From the integrator:** the copies track's review (`wt-copies-review10-scratch/REVIEW.md`, F1 to F7) proved
  that a crafted file can mislead ffmpeg. **Read by me against the viewer's two commands** (`ffmpeg.go`
  `videoFrame`, `playArgs`): both already name `-protocol_whitelist file`, the frame command takes one frame
  with a 60 s limit; **neither names the containers it accepts**, so F4 applies (a concat text file under a
  video's name would give another file's frame as the thumbnail, or another file's stream as the converted
  copy; same folder only). F1 does not (no HTTP input); F2 and F3 do not today (the viewer reads no time
  from ffmpeg's output), and bind the new progress reader of part 6.
- **Sent to the running coder as part 7 of brief B4-1 (same branch):** `-format_whitelist` of real
  containers on both commands, the list taken from ffmpeg itself and from the copies track's fix; the
  conversion's frame mode made explicit; progress lines parsed only when the whole line is a known key
  and a number; named tests with an invented concat file beside an invented clip.
- **`wip/b-open` now holds seven parts** (1 to 4 the open; 5 two page defects; 6 conversions measured and
  the walk giving way; 7 crafted files). The independent review's brief (`BRIEF-B4-open-review.md`) gets
  parts 5 to 7 named when the hand-back is in.

### 16:10: `wip/b-open` has all seven parts committed (6eb54d8, 6 commits); my read of the risky part
- The coder has not handed back yet (its own whole-package run is going). Read by me meanwhile, on 6eb54d8:
  `media.go` (the library), and the changes in `maker.go`, `play.go`, `viewer.go`.
- **The root's lifetime: sound by reading.** The lock guards the pointer and the counts only; an open takes
  the kept root and counts itself as a user; `check` alone does the network `Stat` and the re-open, outside
  the lock, one check at a time; a root taken off is closed by its last user, once (`closed` flag); after
  `close` no root is opened again (checked before and after the slow open). An open that fails for another
  reason than "does not exist" only signals the watcher.
- **A person before the makers: sound by reading.** A counter with a channel closed when the last holder
  lets go; a maker waits on it, its context, or 30 s, whichever is first; every handler ends its hold by a
  `defer`. The conversion's hold is released after ffmpeg has been stopped.
- **For the reviewer (not blockers):** with several workers waiting at once the "gave way while a copy plays"
  seconds are counted once per worker and again after every wake by an asked thumbnail, so the number is
  not "how long the walk stood still"; while the folder is away every failed open wakes the watcher, whose
  check is then cheap but runs as often as opens fail.
- The review's brief (`BRIEF-B4-open-review.md`) now names parts 5 to 7. The review starts when the coder
  hands back; B4-3 gets its own smaller review; then one joined branch and the full runs once.
- `wip/b-notsaved`: one work-in-progress commit so far (b868dd7); its coder is running.

### 16:10: the owner said yes to both downloads; mpv unpacked; the spike's coder started
- **The owner, 16:08, to the question of the two downloads: "Yes, both".**
- **mpv:** `mpv-x86_64-20261111-git-bcde6b93cc.7z` (34.2 MB) from shinchiro's builds on GitHub (one of the two
  mpv.io names), its SHA-256 equal to the one GitHub publishes for the file; unpacked with 7-Zip into
  `tgarchive-b\mpv` under the session's `%LOCALAPPDATA%` (the package's folder, beside `bin`); `mpv.exe`
  v0.42.0, built 2026-11-11. Nothing installed or registered, no setting changed (its register and updater
  scripts were not run). The archive itself is in this session's scratch folder.
- **The spike:** a copy of its own, `wt-b-window`, branch `wip/b-window-spike` cut from f0e3f0c; one Opus
  coder started 16:10 with `BRIEF-B4-window-spike.md` (the Go module `github.com/jchv/go-webview2` is fetched
  by it into the spike's own nested module; the app's `go.mod` is not touched). It writes
  `SPIKE-native-window.md`. PC before the start: 4.5 GB free, CPU 81% (the first coder's whole-package run
  was going).
- **Running, all from this session:** (1) the coder on `wip/b-open` (copy `wt-b-viewer`), in its last run;
  (2) the coder on `wip/b-notsaved` (copy `wt-b-faces`); (3) the spike's coder (copy `wt-b-window`).
- **Next:** as at 16:10 above; and when the spike reports: read it, give board message 28 its module and
  version, brief the build (`cmd/tgarchive-window`, `internal/window`), and tell the owner how to put the
  player to use meanwhile (Settings, "Player program": mpv's path).

### 16:15: the open piece handed back; its independent review started
- **`wip/b-open` 6eb54d8 (pushed, the copy clean): handed back by its coder with all seven parts.** Differences
  from the brief it names: the step "root" now covers only taking the kept pointer (the network left it); an
  open that finds no root also asks for an early check; the play route holds the "person" mark twice
  (lookup, then the open) so that the encoder's one-time lookup does not hold the makers; the page's line
  also goes on `emptied`, and the waiting line on `pause`. Standard error of a conversion was not read at
  all before (it went to the null device): the failure words come from the frame command only and are
  untouched. The whitelist: `mov,matroska,avi,asf,flv,mpeg,mpegts,ogg`, tried by the coder on ffmpeg 9.0.2
  and 7.1.1 (a concat text file is refused on both; MP4, MKV, AVI, MPEG-TS open); the copies track's branch
  has no list yet, so this one is not taken from it. `-fps_mode vfr` named (a clip with one frame 200 s late:
  5,001 frames with `cfr`, 50 with `vfr` or nothing).
- **Its whole-package run on 6eb54d8 (225 s, other sessions compiling): one test failed,
  `TestTimingUnderWriteLoad` (real time: index updates' 95th 179 ms against 100, worst page 421 ms and post
  339 ms against 250); alone on the same commit, CPU 63%, it passed (9.5 ms, 57 ms, 41.5 ms).** `gofmt` and
  `go vet` clean. So there is no clean whole-package pass yet: the full runs before the merge are to be run
  when the PC is quieter, and this test judged by itself if it fails alone again (it is the kind message 25
  names; it is an older test of this track).
- **Running:** the independent reviewer of `wip/b-open` (an Opus agent, read-only, probes in its own scratch
  folder; `BRIEF-B4-open-review.md`; it writes `REVIEW-B4-open.md`), started 16:15, PC 5.0 GB free, CPU 55%;
  the coder on `wip/b-notsaved` (three commits so far, e4f1d53; in its last run); the spike's coder.
- **Read by me on `wip/b-notsaved` e4f1d53 meanwhile:** `notsaved.go` and the update in `refresh.go`: one
  number per file (the saved copy to show, exact or probable), set for every file on a full build and, on
  an update, for the files whose saved state changed, that gained a copy edge, or whose places changed, and
  for the files linked to them. **For its reviewer:** whether a copy edge can go or change its kind in an
  update without a note. Its review's brief is written (`BRIEF-B4-notsaved-review.md`).
- **Next:** the review's findings judged and a fix round briefed; B4-3's hand-back, read, review; both
  branches joined as `wip/b-viewer4`; the full runs once; `MERGE-QUEUE.md`.

### 16:18: the not-downloaded piece handed back; its independent review started
- **`wip/b-notsaved` e4f1d53 (pushed, the copy clean): handed back.** Its whole-package run on e4f1d53 itself
  passed (227 s); `gofmt` and `go vet` clean; **nothing was looked at in a browser.**
- **As built:** the preference `library_not_saved` (copy, the default; show; hide), applied when a listing
  is built, after the hiding rules and before the fold; a tile kept as a copy takes the file that has the
  copy as its cover and carries the copy's picture, the chat and day it was saved from, and "exact" or
  "probable"; marks "Saved copy from <chat>" / "Probably the same, saved in <chat>"; the chip "Not
  downloaded, no saved copy: N left out" with its way back (`nd=show`); Settings has the three choices.
- **Differences from the brief, accepted by me:** the rule is also off with `hidden=1` and `clutter=only`
  (each chip still opens exactly what it counts); with `nd=show` the copy tiles keep their copy and only
  the left-out ones come back; "Everything is left out" when the rules leave nothing.
- **Its numbers (the PC busy, about 78% CPU from others: "looks like"):** the default library's first page,
  cold, 10.1 ms before and 12.6 to 16.5 ms after; warm 3.1 and 3.0 ms; all far inside the 200 ms budget (on
  the invented catalogue of the timing test).
- **Its doubts, kept for the review and for the owner's look:** an exact copy's tile and the saved file's
  own tile both show the same picture (tiles are posts; only probable copies fold); a post whose only
  saved file is filtered out by type or clutter stays with a "Not downloaded" cover; each copy tile walks
  its copy's places for the oldest post.
- **Test helpers changed:** the tests that count tiles not downloaded now run with the rule at "show"
  (`shownPrefs`); tests that start a viewer directly, the timing test among them, run with the default.
- **Running:** the reviewer of `wip/b-open` (since 16:15); the reviewer of `wip/b-notsaved` (since 16:18,
  `BRIEF-B4-notsaved-review.md`, writes `REVIEW-B4-notsaved.md`); the spike's coder. PC before this start:
  4.3 GB free, CPU 76%.

### 16:28: the review of `wip/b-open` judged; its fix round started
- **`REVIEW-B4-open.md` (an independent Opus reviewer, read-only, probes on ffmpeg 7.1.1 and 9.0.2):
  4 confirmed, 4 plausible.** Read by me in full. Sound by its probes: the root's lifetime and lock, a
  person before the makers (bounded, no negative count), only numbers and fixed words in the snapshot,
  ffmpeg's error output always drained, concat and playlist files refused on both builds, `-fps_mode vfr`,
  the "Opening…" line, the two page fixes.
- **Accepted, all of them, as `BRIEF-B4-open-fixes.md`:**
  - **F1 (confirmed, wrong result):** after a network blip the kept root is dead while the folder is back;
    a maker then marks a file that was never missing (no thumbnail for a day), and a click gets a 404. The
    old code hid this by checking the root on every open, which was also the lock problem. My brief asked
    for "a library that comes back is used again" and missed this window. Fix: a generation for the root; a
    maker's failure under a root that changed is the library's, not the file's; a person's failed open runs
    one bounded check and tries once more.
  - **F2 (confirmed, wrong result):** the format list dropped RealMedia, DV, MXF, NUT, raw H.264 and GIF.
    Fix: those single-file formats added; a refusal by the list becomes the word `decode`.
  - **F3, F7 (confirmed, wrong number):** the conversion's speed counted the browser's pauses. Fix: time
    blocked in the writes to the browser is taken out; at least 5 s of video to count; the first-video
    time comes from the route's first byte.
  - **F4 (confirmed, wrong number):** the "gave way" numbers counted per waiting worker. Fix: once per busy
    period, the period's length.
  - **F5, F6, F8 (plausible, small):** one "Open in the player" button under a converted copy; an early
    check at most every 2 s; the slowest step's word.
  - **Outside the branch, this track's:** after "Original" a late thumbnail replaced the original. Fixed too.
- **Running:** the first coder, resumed on the fix round (`wip/b-open`, copy `wt-b-viewer`), since 16:28;
  the reviewer of `wip/b-notsaved`; the spike's coder.
- **Next:** the fix round's hand-back read (F1's two paths); `REVIEW-B4-notsaved.md` judged and its fixes;
  both branches joined as `wip/b-viewer4`; the full runs once (whole tests and the race detector on
  `internal/viewer`), on a quieter PC; `MERGE-QUEUE.md`.

### 16:30: the review of `wip/b-notsaved` judged; its fix round started
- **`REVIEW-B4-notsaved.md` (an independent Opus reviewer, read-only, probes by overlay): 4 confirmed
  defects, 2 confirmed points for the owner, 5 plausible.** Read by me in full. Sound by its probes: the
  number kept per file equals a fresh build after every cause tried (a copy that stops being saved
  included); the reference tests really compare it; the post page's answer is unchanged; the listing's key
  keeps the values apart; paging and the arrows skip what is left out; no `innerHTML`; no test on real time.
- **Accepted as `BRIEF-B4-notsaved-fixes.md`. One principle for findings 1 to 4: a tile is judged by the
  files it actually shows, once, after the fold.**
  - 1: a tile could carry the copy of a file it does not show and say "proven" for it.
  - 2: the fold could take away the file a tile was kept for; the tile stayed as "Not downloaded", uncounted.
  - 3: "Showing N not downloaded" counted tiles the fold then removed.
  - 4: "has a saved file" looked at the whole post, not at what the tile shows (my brief's wording): under
    "hide" a "Not downloaded" tile could still show. Fixed to what the tile shows.
  - 5 (decided by me, told to the owner): a copy's place is named by a chat that is not hidden when there is
    one; else "Saved copy (in a hidden chat)" with no name. The post page follows.
  - 7, 8: the copy's oldest post once per call; the update redoes linked files only when it can matter.
  - 9, 10, 11: `nd=show` without a chip; the Settings sentence; the tile's shape from the copy.
- **Not changed, for the owner (finding 6):** a file saved from one chat and posted in another shows on two
  tiles with the same picture (tiles are posts). Said to the owner at 16:18; no answer yet. Recommended:
  leave it; "each file once" already exists as a filter.
- **Running:** the first coder on `wip/b-open`'s fix round (since 16:28); the second coder on
  `wip/b-notsaved`'s fix round (since 16:30); the spike's coder (since 16:10).

### 16:40: the spike reported; the window's build briefed and its coder started (stage A)
- **`SPIKE-native-window.md` (read by me in full; the spike ran 16:10 to 16:40, commit ca1b426 on
  `wip/b-window-spike`, pushed; the app's `go.mod` untouched; nothing left running):**
  1. Binding: `github.com/jchv/go-webview2` at `v0.0.0-20260205173254-56598839c808`, its `pkg/edge` only,
     builds without cgo, +0.5 MB; about 100 lines of raw COM add what it lacks (refusing navigation and new
     windows, posting JSON). It brings `github.com/jchv/go-winloader`. Its quirks are in the report.
  2. mpv's window stayed exactly over the page's frame and above the web content in 23 steps of 23 (resizes,
     maximise, full screen, scrolling, a move to the second monitor) and in 40 of 40 drag-like sizes. Not
     tried: monitors of different scaling (both are at 100%), a real mouse drag.
  3. Keys never pass through mpv: mpv's embedded window is disabled, the page keeps the focus and its keys.
     The plan's forwarding is not needed (it works: 50 of 50, under 4 ms).
  4. Starts: one mpv kept with its window kept: 27 to 42 ms a start (about 0.5 s for the first); one mpv per
     video: 0.5 to 0.7 s. HEVC and H.264 decode on the graphics card, MPEG-4 Part 2 in software.
     Killing the program ended mpv 3 times of 3 (a job object).
- **The integrator answered board message 28(a) at 16:28: yes in principle** (one pinned pure-Go requirement
  for `internal/window` and `cmd/tgarchive-window`; the entry names the module, version, licence and what
  `go.sum` gains; a wall-test line at the merge).
- **Brief: `BRIEF-B4-window.md`, two stages.** Stage A (now, from f0e3f0c, no existing package touched): the
  program, the window, one instance, the place remembered, mpv kept warm with a fixed command line, the
  bridge with every message checked, crafted files proven harmless to mpv by a self-check, its own counts
  file, the browser as the fallback. Stage B (after the viewer's two branches are joined): the viewer's
  exported "path of this saved file" shared with "Open in the player", and the page's side.
- **Running:** the window's coder (Opus, copy `wt-b-window`, branch `wip/b-window`), since 16:40, told to hold
  every compile while the CPU is above 85% (it was 86% at the start, 5.2 GB free); the two fix rounds
  (`wip/b-open` since 16:28, `wip/b-notsaved` since 16:30).
- **Next:** the two fix rounds' hand-backs read; the join as `wip/b-viewer4` in `wt-b-viewer`; the full
  runs once on a quieter PC; `MERGE-QUEUE.md`; then stage B's message to the window's coder; the window's
  own independent review (what a page can make the shell do, child processes, DLL loading, crafted files).

### 16:44: the not-downloaded piece's fix round handed back
- **`wip/b-notsaved` a6d0ed5 (pushed, the copy clean): the fix round is in** (231ab2e the fixes, a6d0ed5 a
  shortcut). On a6d0ed5 itself: the whole package passed (219 s), `gofmt` and `go vet` clean, the five-seed
  `TestRandomUpdatesMatchFullRead` 21 s, `TestTimingOnBigCatalogue` passed (library first page 21 ms cold
  at 67 to 84% CPU from others; 3.0 ms warm; before the piece 10 ms: "looks like", far inside 200 ms).
- **As decided, findings 1 to 5 and 7 to 11.** One difference, accepted by me: a tile that would be left out
  after the fold is kept when other tiles' files are folded behind its face (leaving it out would lose
  them); it has no test (the coder could not build the case).
- **Its doubts, kept:** `?f=` on a tile is now the file whose copy is shown; dropping `nd` from the address
  takes the page to the top; `item.js` got one line in `standInNote`, a file `wip/b-open` also changes
  (for the join); nothing was looked at in a browser.
- **Running:** the first coder's fix round on `wip/b-open` (committed as 1887662, read by me: the root's
  generation, a person's one more try through the watcher's urgent check; in its last run); the window's
  coder (stage A).
- **Next:** `wip/b-open`'s hand-back; the join as `wip/b-viewer4`; a browser look of the joined build on an
  invented archive (the copy tiles, the chip, the Settings group, the "Opening…" line, one converted copy);
  the full runs once; `MERGE-QUEUE.md`.

### 16:49: both fix rounds in; joined as `wip/b-viewer4`; looked at through its own API; the full runs started
- **`wip/b-open` 1887662 (pushed): the fix round handed back**; its whole-package run on 1887662 passed
  (217 s, with ffmpeg 9.0.2, `TestTimingUnderWriteLoad` inside it). F1: a generation for the root; a failure
  under a root that changed is the library's (through `maker.make`: no mark, made later; "files missing" not
  set by blips); a person's failed open asks the watcher for an urgent check, waits for one that started
  after it (the request's context, 10 s at most) and tries once more. **Difference, accepted:** the check
  is the watcher's, not inline (a network `Stat` cannot be cancelled). F2: nine single-file formats added,
  each tried on both builds; a refusal by the list is the word `decode`. F3: a copy's "free speed" leaves
  out the time blocked writing to the browser; keys renamed (`conversions.counted`, `free_speed_median`,
  `free_speed_lowest`, `free_slower_than_play`); `first_video_*` gone (use `play_ttfb`). F4: once per
  busy period. F5, F6, F8 and the "Original" bug as briefed. Read by me: the generation, `checkFor`,
  `openFor`.
- **Its coder's own doubt, kept for the owner's use:** the frame command's JPEG encoder refuses some
  limited-range pictures (seen with an invented RealMedia clip on 9.0.2): possibly thumbnails lost for
  other files; not changed; worth its own look.
- **Joined:** in `wt-b-viewer`, branch `wip/b-viewer4`: 1887662 with `wip/b-notsaved` a6d0ed5 (cdda590; one
  conflict, the two style blocks at the end of `app.css`, both kept), then the main branch's new head
  a0baa06 merged in (d4269cc; the main branch had not touched this track's packages). Pushed to `private`.
- **Looked at, on a fresh invented archive in the scratch folder (the joined build, started from PowerShell
  as the owner's starter does, port 8812, stopped again). The browser pane was hidden, so the grid drew no
  tiles (it draws on frames); what follows is read through the page's own requests:**
  - the heading says 848 of 1,317 posts; the chips "Not downloaded, no saved copy: 439 left out" and
    "Probable copies folded: 30": 848 + 439 + 30 = 1,317;
  - all 848 tiles fetched: none without a saved file or a copy;
  - with the probable copies apart: 878 tiles, 30 of them a probable copy's (with its chat, day and
    picture), 878 + 439 = 1,317; with the chip's way back: 1,287 + 30; both: 1,317; "FILE: Not downloaded"
    turns the rule off (705);
  - Settings has the group with its three plain sentences;
  - the play route converted an invented MPEG-4 Part 2 clip of 20 s in 1.1 s, first byte after 127 ms; the
    file route answers a range;
  - the snapshot carries the new numbers (the open's three steps: root 0 ms, open 4.5 ms median on a local
    disk; the slowest open with its second, step and whose; the bands; the gave-way pairs; conversions).
  **Not seen:** tiles and marks drawn, the "Opening…" line, the hint under a converted copy (no frames in a
  hidden pane); a conversion's numbers from a real run (the viewer was stopped before its next snapshot).
- **The full runs, started 16:49 on d4269cc, once** (said to the owner first): the whole tests of
  `internal/viewer` and the race detector on `internal/viewer` (`ix-tools/full-runs.sh wt-b-viewer runs-b4
  "viewer" "viewer"`, `FFMPEG_PATH` set to 7.1.1); about 15 minutes; results in `runs-b4/`.
- **Running:** those runs; the window's coder (stage A, copy `wt-b-window`).
- **Next:** the runs' results; `MERGE-QUEUE.md` entry 16; the build of d4269cc into the owner's `bin` and
  the starter's line on the board; stage B's message to the window's coder (cut from `wip/b-viewer4`).

### 16:59: the full runs passed; entry 16 written; the owner's build in place
- **Full runs on d4269cc, once (`runs-b4/`, 16:49 to 16:58):** whole tests of `internal/viewer` ok (212 s);
  the race detector on `internal/viewer` ok (515 s, no data race); gofmt clean; `go vet` on the package and
  `cmd/tgarchive` clean.
- **`MERGE-QUEUE.md` entry 16: `wip/b-viewer4` d4269cc**, with what it holds, the two reviews, the runs, what is
  known and not seen. The board row leads with it.
- **The owner's build:** `tgarchive.exe` of d4269cc in the track's `bin` (16:58; the 16376c9 build kept as
  `tgarchive.exe.16376c9.bak`); the owner's viewer was not running; `b\b-viewer.cmd` takes it at the next
  start. The viewer does not look at the catalogue's schema number (it reads by what columns exist), and
  `old-archive-4` stays as it is.
- **Running:** only the window's coder (stage A).
- **Next, in order:** (1) the window's stage A hand-back: read it (what a page can make the shell do, the
  process and DLL handling, the crafted-file self-check), then stage B's message, cut from `wip/b-viewer4`:
  `viewer` exports the path of a saved file (one function shared with "Open in the player", inside the
  person's mark), `play.js` and `item.js` ask the shell; then one independent review of the window, its
  fixes, the full runs (`internal/window` whole and under the race detector, `internal/viewer` again only
  if stage B changes concurrent code), the entry with the `go.mod` lines, a starter `b\b-window.cmd`.
  (2) After the owner's next use: `stats-last.json` (which step of an open stalls and when; the
  conversions' free speed against the NAS). (3) `TestTimingUnderWriteLoad` without real time. (4) The frame
  command's JPEG refusal. (5) The pages as drawn, when the browser pane shows, and as another device sees
  them.

### 17:08: the owner on duplicates in the unified library; piece B4-5 briefed and started
- **The owner, 17:02, to the board's item 16:** "In that chat it can show, but in a unified stream it should
  be folder[ed] under one."
- **Read first:** `fold.go` and `appear.go`: the fold takes only probable copies; exact copies and a file's
  other posts are what "Only where it first appeared" (`first=1`) already puts under one tile, with "also in
  N chats"; it is a filter, off by default, not remembered.
- **Brief `BRIEF-B4-once.md`:** a remembered preference, on by default: a library query that names no chat
  and no topic is built as with `first=1`; a chat's or topic's view is unchanged; `first=0`/`first=1` in
  the address win; a chip "Each file once: N other posts left out" with its way back; a Settings switch;
  counts add up; the timing test before and after (the default's first load now builds a first-appearance
  listing: the budget is not loosened). The post that stays is the earliest one (the rule's order is not
  changed); when it is not downloaded, B4-3's rule shows the saved copy on it.
- **Running:** the second coder, resumed, on `wip/b-once` (copy `wt-b-faces`, on top of `wip/b-viewer4`
  d4269cc), since 17:08 (PC: 5.1 GB free, CPU 27%); the window's coder (stage A).
- **For the merge queue:** entry 16 stands as it is (d4269cc); this piece becomes entry 17 on top, after its
  own short review and the whole tests once (no concurrent code is expected to change: no race run unless
  it does).

### 17:18: the window's stage A handed back and read; stage B started
- **`wip/b-window` d1c9343 (pushed; copy `wt-b-window` clean; cut from f0e3f0c): stage A is in.** New only:
  `archiver/internal/window` (19 files), `archiver/cmd/tgarchive-window`, and in `go.mod` the one requirement
  `github.com/jchv/go-webview2 v0.0.0-20260205173254-56598839c808` (MIT) with `github.com/jchv/go-winloader
  v0.0.0-20250406163304-c1995be93bd1` (ISC, indirect); `go.sum` gained 6 lines (listed in the hand-back;
  the app's own `golang.org/x/sys` still wins). No existing package touched.
- **Its self-check on this PC (17:14, 35 s, an invented archive, CPU 40%):** placement 18 of 18 right; 10
  starts median 49 ms, worst 142 ms; 11 of 11 real containers played (MP4, MOV, MKV, WebM, AVI, WMV, FLV,
  MPEG-TS and the spike's three); **18 of 18 crafted files (ffconcat, m3u, m3u8, mpv's EDL, cue, pls, SDP,
  DASH, a zip, each under a video's name and under its own) played nothing and made no connection** (with
  mpv's defaults five of the nine kinds played the clip beside them); 12 bad page messages dropped and
  counted by word; navigation elsewhere, a foreign frame and `window.open` refused; a `WebView2Loader.dll`
  planted in the working folder and beside the program not taken; the program killed: mpv gone 6 ms
  later; a second start brings the first window forward; nothing left running. 31 unit tests ok; vet and
  gofmt clean; builds without cgo, and on Linux as a stub.
- **mpv's command line is fixed (43 options, in the hand-back and in `mpvargs.go`):** no config, no key
  bindings at all (only its on-screen controller's mouse), no scripts but that controller, no media keys or
  system media controls, no watch history, no network, the lavf demuxer only with a format and a protocol
  whitelist, a random pipe name.
- **Read by me:** the message parser's rules (`msg.go`: exact keys per type, bounds, a rate limit), how a
  play becomes a file (`bridge.go` `resolve`, `load`: the id goes to `PathOf` only, the path is checked and
  goes to mpv by `loadfile` over the pipe; an entry mpv starts that was not loaded is stopped), the origin
  check (`allowed.go`: http, 127.0.0.1, our port, nothing else). Sound by reading.
- **Its doubts, for the review:** mpv's pipe can be opened by any program of the same user (asked in stage
  B: an already connected pipe if this mpv has it); the binding's start-up runs before the DLL search is
  limited (system DLLs only by then); the browser fallback's second failure and a missing WebView2 are not
  tested; the race detector not run yet.
- **Stage B briefed and started (`BRIEF-B4-window-stageB.md`), 17:18:** `wip/b-viewer4` d4269cc merged into
  `wip/b-window`; `viewer.PathOf` as one function shared with "Open in the player" (no route); `play.js` and
  `item.js` hand a saved video to the shell when it is there (the "Opening…" line until mpv's first
  picture; fallback to the browser's path on any failure); a self-check through the real pages.
- **Running:** the window's coder (stage B, copy `wt-b-window`); the second coder on `wip/b-once` (copy
  `wt-b-faces`).
- **Next:** `wip/b-once`'s hand-back, a short review, its whole tests, entry 17. The window: stage B's
  hand-back read; one independent review (what a page can make the shell do, processes, DLLs, crafted
  files, the pipe); fixes; full runs (`internal/window` whole and under the race detector; `internal/viewer`
  whole); the entry with the `go.mod` lines; the starter `b\b-window.cmd` (written by me, as `b-viewer`).

### 17:25: entry 16 is merged; the owner opened d4269cc; a click on the video; the numbers file was not written
- **From the integrator (17:23):** `wip/b-viewer4` d4269cc is merged and pushed (9a51a92 the code, head
  4f0fe17; the same tree for `internal/viewer`). **Cut the next pieces from 4f0fe17.**
- **The owner, 17:21, on the build of d4269cc (board message 31):** "The video loaded quickly. Minor quirk
  with the player: I feel that clicking the main video should start/pause it, rather than having to use the
  button in the corner." Sent as an addition to `wip/b-once` (the pages: a click on the main video toggles
  play and pause, with the reason it does not today) and to the window's stage B (a click on mpv's picture
  toggles pause).
- **Found while reading the owner's numbers: the new build wrote no `stats-last.json` in that use.** The file
  in the owner's viewer folder is still the old build's of 15:47; the starter did take the new build (the
  viewer's program in `bin` is the new size) and the viewer ran from 17:18 (its own state file was opened
  then). Either the run was under a minute and the window was closed (closing the console window ends the
  program without the stop snapshot: the viewer command listens for Ctrl+C only), or the snapshot fails to
  write in this build. **Being reproduced on the invented archive (the same build, a file request and two
  conversions in its first minute).**
- **Reproduced (17:26): the writer is fine.** The same build on the invented archive, a file request and two
  conversions in its first minute: `stats-last.json` was written at 60 s with the new numbers (conversions
  2, 1 counted, free speed 16 times real time on the invented clip; the first byte of a copy after 155 ms;
  the slowest open 9.7 ms, a person's, at 5 s). **So the owner's use was lost to the lifetime:** the first
  write comes after a full minute, and closing the console window ends the program with no stop snapshot.
  Sent to the second coder as a third addition: end cleanly on the console's close signal, write the
  snapshot before the slow parts of `Close`, and an early write a few seconds after a person's request.
- **`wip/b-once` e8c393f handed back** (whole package ok, 212 s): in the whole library each file once as a
  counted rule after the three hiding rules, with its chip and Settings switch; the default's first page
  14.5 ms before, 19.0 ms after (33 ms before a fix found by profiling), PC at 56 to 76% CPU; all inside
  200 ms. **Its doubt 1, sent back as a required fix:** a file could vanish from the default library (its
  group's earliest post not downloaded and without a direct copy, while a later post is saved): the group's
  tile must be the earliest post whose tile the not-downloaded rule keeps.
- **The second coder's round now holds four things on `wip/b-once`:** each file once (done), no file may
  vanish, a click on the video toggles play, the numbers file surviving a closed window; then the main
  head 4f0fe17 merged in and one whole-package run. Then: one short independent review, entry 17.
- **Running:** the second coder (that round, copy `wt-b-faces`); the window's coder (stage B with the click
  on mpv's picture, copy `wt-b-window`).

### 17:39: the window's stage B handed back; its independent review started
- **`wip/b-window` d59160a (pushed; the copy clean): stage B is in**, on top of `wip/b-viewer4` d4269cc
  merged in (39a698f, no conflict). Since that merge the viewer changed only in `play.go`, `stats.go`,
  `viewer.go`, `web/js/play.js`, `web/js/item.js` and a new test file; no route, no access class.
- **As built:** `viewer.PathOf` and "Open in the player" share one function (`playerFile`), inside the
  person's mark, fixed-word errors, counted as `window.started`/`failed`; the pages talk to the shell only
  where `window.chrome.webview` exists (a plain browser and a phone run none of it); a saved video plays in
  mpv with "Opening the file from the library… N s" until mpv's first picture; any failure or 30 s without
  a state falls back to the browser's own path with one sentence; **mpv gets an already connected,
  inherited pipe** (`--input-ipc-client=handle://N`: this build has it), no listening pipe: a second
  client is refused; **a click on mpv's picture toggles pause** (the owner's request of 17:21; `keybind
  MBTN_LEFT "cycle pause"` over the pipe); F and Escape for full screen through the page's message.
- **Its self-check through the real pages on an invented archive (17:36, CPU 58%, the window open 17 s):**
  an HEVC and an MPEG-4 Part 2 clip: play to picture 219 and 101 ms (median of all 155 ms), mpv's window 0
  px off the page's frame, Right arrow +5 s, Space, a click and a second click, a double click (no change,
  no full screen), F then Escape, next, close: all as meant; nothing left running.
- **Its whole-package runs:** `internal/window` ok at d59160a; `internal/viewer` ok (219 s) at 73e4a49 (only
  a self-check file of `internal/window` changed after it); vet and gofmt clean; builds without cgo.
- **Differences, accepted for now, each for the owner to feel:** while mpv plays, Left and Right seek 5 s,
  so previous and next are the buttons, swipe and strip (before play the arrows step files as today; the
  help list still says the arrows step files: to correct); the position is remembered only for the
  window's player; the page hidden (a minimised window, probably) stops the video and remembers its
  place; some styles are inline in the two scripts.
- **Not shown, said by the coder:** that mpv's own controller (its buttons and seek bar) still takes its
  clicks beside the click binding: posted clicks cannot show it (the real pointer is elsewhere) and the
  owner's pointer was not moved. **The owner's first click on the seek bar settles it.**
- **Running:** the window's independent review (an Opus agent, read-only, `BRIEF-B4-window-review.md`, writes
  `REVIEW-B4-window.md`), since 17:39, PC 3.8 GB free, CPU 21%; the second coder's round on `wip/b-once` (in
  its last run).

### 17:41: `wip/b-once` handed back with its three additions; its independent review started
- **`wip/b-once` 18725db (pushed; the copy clean), the main head d1af260 merged in** (against it the branch
  differs by this piece's 20 files: `internal/viewer`, and `cmd/tgarchive/viewer.go` with its test). On
  18725db: `internal/viewer` whole ok (218 s), `cmd/tgarchive` ok, vet and gofmt clean.
- **No file vanishes (1af12c5):** in the whole library, with the not-downloaded rule at copy or hide, a
  group whose earliest file fails the rule gives its place to its member with the earliest place that
  passes; a group with none stays at its earliest file, is left out and counted once under the
  not-downloaded chip; worked out once per overlap table and rule (per listing when a chat is hidden).
  Tests build both chains on purpose.
- **A click on the main video (9166009):** why it did nothing: nothing covers the video and no handler takes
  the click: Chromium's own controls do not toggle on a click on the picture (Firefox's do). One handler
  for the file's `<video>` and a converted copy: it notes the paused state at the press and, 250 ms later,
  toggles only if the browser left the video as it was (never twice; no `preventDefault`); the bottom 56 px
  (the control bar), a double click, keys, touch and GIF-type clips are the browser's. **Not looked at in a
  browser.**
- **The numbers file (5a0c61b):** the command ends on `os.Interrupt` and `syscall.SIGTERM` (Go delivers the
  console's close, log-off and shutdown as that once `Notify` is called); the stop snapshot is written
  first (2 ms into `Close` on the big invented catalogue, `Close` 16 ms in all), then the servers get 2 s
  (5 before); and a write 3 s after a person's request, at most every 10 s, reason word `use`. A test
  cannot send the console's close event to itself: the handling function is tested, not the event.
- **Timing, the default library's first page on the invented catalogue:** 25.0 ms cold at 73 to 100% CPU
  (19.0 ms earlier at 56 to 68%; 14.5 ms before the piece): "looks like"; inside 200 ms.
- **Running:** the review of `wip/b-once` (an Opus agent, read-only, `BRIEF-B4-once-review.md`, writes
  `REVIEW-B4-once.md`), since 17:41 (4.5 GB free, CPU 52%); the review of `wip/b-window` (since 17:39).
- **Next:** both reviews judged, their fix rounds; then for `wip/b-once`: the whole tests and the race
  detector on `internal/viewer` once (the snapshot's timer and the shutdown order are concurrent code that
  changed), entry 17, the owner's build; for the window: `wip/b-once` merged in (both change `item.js` and
  `play.js`), full runs (`internal/window` whole and under the race detector), its entry with the `go.mod`
  lines, the starter `b\b-window.cmd`.

### 17:56: the review of `wip/b-once` judged: the rule is changed, not patched; its fix round started
- **`REVIEW-B4-once.md` (an independent Opus reviewer, read-only, probes by overlay): 4 confirmed, 3
  plausible.** Read by me (findings 2 and 5 to 7 in full, the others from its summary and headings). Counts
  added up in every probe. Sound by its reading: the click never toggles twice; the shutdown order.
- **Confirmed:** (1) the owner hides a group's earliest post: the file's saved copy in another chat has no
  tile in the default library; (2) a search, a type filter or a date range in the whole library is judged
  only at a group's earliest post: a search matching a later post's caption finds 0 tiles instead of 2;
  (3) the placement's "free" check counts files the not-downloaded rule drops anyway: under "hide" a saved
  file with no tile, under "copy" one picture on two tiles; (4) the sidebar's "Only where it first
  appeared" switch got two click handlers and is stuck.
- **My decision (the cause of 1 to 3 is the design I briefed: first appearance over the whole archive, with
  a probable step, as the default):** the rule becomes **"among the posts the query would list, each exact
  group once"**: a group is the file and its exact copies only (probable copies stay with the fold, as
  before the piece); the place is the earliest listed post whose tile the not-downloaded rule keeps;
  `first=1` goes back to exactly what it was, the rule has its own `once=0`, the sidebar switch is wired as
  before, the placement code goes; a group number per file kept per index version, one pass per listing
  (the reviewer measured +15 to 20 ms per cold listing with a chat hidden under the old design: to come
  down to a few ms). **It also matches the owner's words better:** the question was about exact copies
  and a file posted in several chats.
- **Also in the round:** one lock for the snapshot's writers and only `stop` after a stop (finding 5); the
  video click's strip and drag judged at the press, a slow double click undone, the "Opening…" line taking
  no clicks (6); "also in N chats" without hidden chats (7); the untested points of the early write.
- **Brief:** `BRIEF-B4-once-fixes.md`. **Running:** the second coder on that round (copy `wt-b-faces`), since
  17:56; the review of `wip/b-window` (since 17:39).

### 18:01: the window's review judged; its fix round started
- **`REVIEW-B4-window.md` (an independent Opus reviewer, read-only; d59160a against d4269cc): 10 findings, 3
  confirmed, 7 plausible.** Read by me (F5 to F10 in full, F1 to F4 from its summary). Found sound by its
  probes: the message parser (15 edge inputs), the id-to-path step (no route, shared with "Open in the
  player"), mpv's options (all exist in this mpv), the inherited pipe (a second client refused), the
  crafted files it added (PNG, Y4M, an EDL under video names refused; crafted MOV references made no
  connection), no file written by mpv, the DLL search, navigation and new windows refused, permissions,
  the UI-thread rule. It did not run the self-check (to keep a window off the owner's desktop).
- **All ten accepted as `BRIEF-B4-window-fixes.md`:**
  - F1 (a page can do what it must not, plausible): downloads were not refused: a page script could save a
    file of its choosing into the Downloads folder. Now only the viewer's own file routes may download.
  - F2 (confirmed): the kill-on-close job also killed the player started by "Open in the player" and a
    fallback browser when the window closed. Now the job allows breakaway for exactly those two.
  - F3 (confirmed): a reload or a new document left mpv playing over the page, and full screen stuck.
  - F4 (confirmed, rare path): the fatal guard held Go's log lock; requests then hung one by one.
  - F5: the window could not be closed while the WebView2 was still starting.
  - F6 (plausible; reachable, since the library keeps names that came with the files): mpv's disc readers
    look at a file's name before the forced demuxer: disc-style names refused, and mpv's disc handlers
    switched off if this build can.
  - F7 to F10: the browser's own keys off; a stop never dropped; full paths only for mpv; a cap on a
    decoded picture's size.
- **Order from here:** (1) both fix rounds hand back (`wip/b-once` in `wt-b-faces`, `wip/b-window` in
  `wt-b-window`); (2) `wip/b-once`: my read of the new rule, the full runs once (whole tests and the race
  detector on `internal/viewer`, `cmd/tgarchive`), entry 17, the owner's build; (3) the window: `wip/b-once`
  merged in (both change `item.js` and `play.js`), full runs (`internal/window` whole and under the race
  detector, `internal/viewer` whole), its entry with the `go.mod` lines, the starter `b\b-window.cmd`, and
  the owner's first play in it (the seek bar's click, the first file from the NAS).
- **Running:** the two fix rounds (since 17:55 and 18:01).

### 18:16: `wip/b-once`'s fix round handed back (d38479c); a second independent look started
- **`wip/b-once` d38479c (pushed; the copy clean; the main head d1af260 already in):** the rule rebuilt as
  briefed: among the tiles the query lists, each exact group once (union-find over exact edges, one number
  per file per index version, `once.go`, read by me), the place the earliest listed tile the
  not-downloaded rule keeps; `first=1` and the sidebar switch as on d1af260; `once=0`; `placeOnce` gone.
  One lock for the snapshot's writers, only `stop` after a stop; the click's strip and drag judged at the
  press, a slow double click undone, the "Opening…" line takes no clicks; "also in N chats" without
  hidden chats. On d38479c: `internal/viewer` whole ok (225 s), `cmd/tgarchive` ok, vet and gofmt clean.
- **Cost, the default listing's build on the timing catalogue (CPU 63 to 76%: "looks like"):** rule on 13.5
  to 13.9 ms, off 7.6 to 10.3; with a chat hidden 19 to 20.5 against 11.6 to 16.7; a search 10 to 12 against
  9 to 12. So 4 to 8 ms per build (15 to 20 under the first design). The timing test: first page 20 ms cold.
- **Differences, accepted:** exact groups fully transitive (no 64-file bound); candidates are tiles; the
  Settings sentence says "at its earliest post that can be shown".
- **Its doubts, kept:** an album tile can show fewer of its files than its count says (a file placed in
  another tile by its group); the grouping is a pass over all files and edges per index version (on the
  static old archive: once per start); the click's thresholds are not checked in a browser.
- **Because the rule was rewritten after its review: a second independent look**, focused (the first
  review's probes run again, then the new rule attacked: a file missing or twice, the fold after the rule,
  album tiles, counts, `first=1` unchanged, the snapshot's lock): an Opus agent, read-only, writes
  `REVIEW-B4-once-2.md`; started 18:16.
- **Running:** that reviewer; the window's fix round (copy `wt-b-window`).
- **Next:** its findings fixed; then the full runs once on `wip/b-once` (whole tests and the race detector
  on `internal/viewer`, `cmd/tgarchive`), entry 17, the owner's build.

### 18:19: the window's starter drafted (untried)
- `b\b-window.cmd` and `b\b-window.ps1` written by me after `b-viewer`: the same catalogue, library folder
  and viewer folder; the program `bin\tgarchive-window.exe` (a newer build waits beside it as
  `tgarchive-window.build.exe` and is taken at the next start); refuses to start while the browser viewer
  runs (both use the viewer's folder and would both read the NAS for thumbnails); ffmpeg handed over by its
  full path; mpv found beside `bin`. It parses; **it has never been run** (there is no built program in
  `bin` yet, and no session runs it on the real archive).

### 18:24: the window's fix round handed back (ff81d31); a second independent look started
- **`wip/b-window` ff81d31 (pushed; the copy clean): F1 to F10 fixed** (a0123c5, ff81d31). On ff81d31:
  `internal/window` ok, `internal/viewer` whole ok (214 s), vet and gofmt clean, builds without cgo.
- **The structural change (for F4 and F5):** the window creates the WebView2 itself
  (`webviewloader.CreateCoreWebView2EnvironmentWithOptions`, its own completed handlers); the binding's
  `Embed`, its `log.Fatalf` paths and its unbounded message loop are no longer used (`pkg/edge` stays for
  its settings type and `NewGUID`). Nothing writes to Go's standard logger from the window.
- **Per finding, as handed back:** F1: a `DownloadStarting` handler (through ICoreWebView2_4; the interface
  id checked by me against what I know of it and by the self-check's successful query): only
  `/media/{digits}/file` of our own address downloads; the rest cancelled and counted. F2: the job allows
  breakaway; exactly the player of "Open in the player" and the browser fallback ask for it, with one more
  try without where it is refused; the job test again: 7 processes alive before the kill (mpv, the
  WebView2 and its 5 children), 0 after 3 s, the detached program outlived it. F3: a `hello`, a navigation,
  a reload or a renderer failure end the old play and full screen. F5: a close during the start ends the
  program; 30 s without a controller runs the browser fallback. F6: this mpv has no switch for its disc
  handlers; a name rule (`.ifo`, `.bdmv` anywhere; `.bup`, `.mpls`, `.clpi`, `.m2ts` inside `VIDEO_TS`,
  `AUDIO_TS`, `BDMV`); a real disc tree could not be made here. F7: the browser's accelerator keys off.
  F8: a stop empties a full queue and goes first. F9: full paths only. F10: `max_pixels` 8192 by 8192 and
  the demuxer's cache bounded (150 MiB ahead, 50 back, none on disk): an invented file declaring 16000 by
  16000 is refused with `decode` and the page takes over.
- **mpv's command line is now 52 fixed options** (in the hand-back and `mpvargs.go`).
- **Its self-check, twice, through the real pages on an invented archive (about 58 s each; 9.1 GB free, CPU
  36%):** play to picture median 55 ms, worst 174; the frame exact; the keys, the click and full screen as
  before; reload while playing in full screen: stopped, hidden, back from full screen; "Download the file"
  wrote 1 file into the check's own folder, a `blob:` download was refused, 0 files; nothing left running.
- **Its doubts:** a file that decodes nothing still makes mpv's window flash for a moment (a playback start
  before the failure); the disc rule is by name only; mpv's own controller with a real mouse, a real F5,
  monitors of different scaling and a stalled WebView2 are still not seen.
- **Because the WebView2's creation was rewritten after the review: a second independent look**, focused (the
  hand-written COM slot by slot, the download rule, the job's breakaway, the new-document path, the disc
  names and the size cap on real mpv): an Opus agent, read-only, writes `REVIEW-B4-window-2.md`; since 18:24.
- **Running:** the two second looks (`wip/b-once` since 18:14, `wip/b-window` since 18:24). No coder.

### 18:36: the second look at `wip/b-once` judged; one last small round started
- **`REVIEW-B4-once-2.md` (an independent Opus reviewer, read-only, d38479c):** the first review's seven
  findings are gone (probes for 1, 2, 3, 7; a test for 5; reading for 4 and 6). **No file missing, no group
  on two covers, counts add up** over 8 random invented archives by 72 query combinations (hidden chat and
  posts, clutter, albums, both tile modes, the three rules, `nd=show`, `prob=apart`, search, type, date
  range, state and copies filters). **`first=1` is byte-identical to d1af260** (192,614 lines of listings
  compared against the old tree extracted into its scratch folder). The snapshot's lock: sound by reading.
- **New, accepted and sent back:** (1) confirmed: the fold loses its face when the group's place moves to
  another exact copy, so a probable copy is no longer folded and one saved picture can sit on two tiles;
  (2) confirmed: an album tile's badge counts files it no longer shows; (3) small: the click's remembered
  toggle, the early write's signal order, a lookup per tile, a stale comment.
- **Cost (CPU 45 to 82%: "looks like"):** the timing test's first page 18 ms cold; the rule adds 4 to 8 ms
  per cold listing. The invented catalogue has no exact edges, so large groups are not measured.
- **Not covered by any test still:** `first=1` against the old answers (the reviewer's one-time comparison
  stands in); the click and the sidebar switch are checked as source text only.
- **Running:** the second coder on that last round (`wt-b-faces`), since 18:36; the second look at the window.
- **Next for `wip/b-once`:** the hand-back's diff read by me (no third review: the round is three small,
  named things); the full runs once (whole tests and the race detector on `internal/viewer`,
  `cmd/tgarchive`); entry 17; the owner's build.

### 18:45: `wip/b-once`'s last round handed back (b2dfe5b); the full runs started
- **`wip/b-once` b2dfe5b (pushed; the copy clean), the main head 9dd5a21 merged in** (the mirror track's
  merge: other packages only). The round, read by me in its diff: the fold follows the group's place (a
  face counts as having the tile its exact group is placed at; the post page follows), an album tile's
  badge counts what it shows, the click forgets an older toggle, the early write is signalled after the
  request's numbers, one groups lookup per listing. On b2dfe5b: `internal/viewer` whole ok (222 s),
  `cmd/tgarchive` ok, vet and gofmt clean (the coder's runs). Its fold and badge tests fail with the fix off.
- **The full runs, once, on b2dfe5b, started 18:45** (said to the owner first; PC 7.6 GB free, CPU 67%): the
  whole tests and the race detector on `internal/viewer` (`ix-tools/full-runs.sh wt-b-faces runs-b5 "viewer"
  "viewer"`, ffmpeg 7.1.1), then `cmd/tgarchive`'s tests and vet; results in `runs-b5/`.
- **Running:** those runs; the second look at the window.
- **Next:** entry 17; the build into the owner's `bin`; then `wip/b-once` merged into `wip/b-window`.

### 18:49: the second look at the window judged; its last round started (it ends by joining `wip/b-once`)
- **`REVIEW-B4-window-2.md` (an independent Opus reviewer, read-only, ff81d31):** F1 to F9 gone; every
  hand-written WebView2 slot and the download interface's id checked against the binding's source and
  generated bindings; the job with breakaway run for real (the program's job-child mode, no window): mpv
  and all six WebView2 processes died, only the released program survived. F6 was closed before the round
  already: `--access-references=no` stops this mpv's three disc readers (tried option by option).
- **New, all accepted as `BRIEF-B4-window-fixes2.md`:**
  - **N1 (confirmed, wrong result for the owner): the picture cap of F10 makes mpv hang.** An H.264 or HEVC
    file declaring a picture over the cap makes mpv retry its decoders without end (78,000 tries in 12 s),
    it answers nothing, and the window's player fails every video until the window closes, a core busy.
    With `--hwdec=no` the same file fails at once. Fix: the options that make it fail cleanly, and a
    watchdog (no reply to a command: mpv killed and started again, the play fails, the next one works).
  - N2: what the owner opens from the download pop-up runs inside the job and can be a program saved under
    its sender's name: an allowed download is handled (no pop-up); the page says "Saving to your Downloads
    folder."
  - **N3 (there before this round, in the merged viewer too): a script in the page could set the player
    program to any `.exe` through the preferences and then use "Open in the player".** Bounds: no program
    under the Windows folder; the file handed to a named program must have a media extension. (It needs a
    script running in our page; none is known. For the integrator's notes: it applies to the browser
    viewer as merged.)
  - N4 to N8 small (a stop that empties the queue keeps mpv's setup; a new document at its commit; HRESULTs
    checked; `QueryInterface` answers only what an object is; BOOLs as values). N9: the tests the round
    owed. N10 accepted as it is.
- **The round ends by merging `wip/b-once` b2dfe5b into `wip/b-window`** (both change `item.js` and
  `play.js`), and the window program gets the same clean end with the stop snapshot as the viewer command.
- **Running:** the window's coder on that round (since 18:49); the full runs of `wip/b-once` (since 18:46).

### 18:58: `wip/b-once`'s full runs passed; entry 17 written; the owner's build in place
- **Full runs on b2dfe5b, once (`runs-b5/`, 18:45 to 18:57):** whole tests of `internal/viewer` ok (267 s);
  the race detector on `internal/viewer` ok (690 s, no data race); `cmd/tgarchive` ok; vet and gofmt clean.
- **`MERGE-QUEUE.md` entry 17: `wip/b-once` b2dfe5b** (it holds 9dd5a21; the main branch has moved since by
  three documents, 5302000). The board row leads with it.
- **The owner's build:** `tgarchive.exe` of b2dfe5b in the track's `bin` (18:57; the d4269cc build kept as
  `tgarchive.exe.d4269cc.bak`, the 16376c9 one still there); the owner's viewer was not running.
- **Running:** the window's coder on its last round (it joins `wip/b-once` at its end).
- **Next:** the window's hand-back; my read of the watchdog and the player-program bounds; the full runs
  (`internal/window` whole and under the race detector; `internal/viewer` whole, and under the race
  detector again only if the round changed its concurrent code); the entry with the `go.mod` lines; the
  window's program built into `bin` as `tgarchive-window.build.exe` for `b\b-window.cmd`.

### 19:17: entry 17 is merged; the window's last round handed back; the main head merged in; its full runs started
- **Entry 17 is merged by the integrator: 0697f15 (the code, equal to b2dfe5b for `internal/viewer` and
  `cmd/tgarchive`: checked by diff), main head fa8c011** (with another track's "only chosen chats").
- **`wip/b-window` 690ba9f handed back (pushed): N1 to N9 fixed and `wip/b-once` b2dfe5b merged in.**
  - N1: no option set makes an over-cap H.264 or HEVC file fail at once while hardware decoding stays (tried
    headless: `--hwdec-software-fallback` no, yes and 3 all loop; `--hwdec=no` fails at once but decodes
    everything in software). Kept: hardware decoding and the cap; **the watchdog bounds it:** while a file
    waits for its first picture the bridge asks mpv something every 2 s; a command without a reply for 5 s
    kills that mpv, the play fails with `player`, a new mpv starts. In the self-check the over-cap file
    cost about 7 s with a core busy, then the page took over and the next clip played in the new mpv.
  - N2: an allowed download is handled (no pop-up); the page says "Saving to your Downloads folder."
  - N3 (`internal/viewer`, the browser viewer too): the player program may not be under the Windows folder
    (links and short names resolved); a named player gets only files with a media extension; Settings says
    both. `launch_windows.go` imports `unsafe` for the Windows folder call (allowed in the wall test for
    that one file).
  - N4 to N8: a stop keeps mpv's setup; a new document at `ContentLoading`; every settings call's result
    checked (a failure runs the browser fallback); a WebView2 without the download interface runs the
    browser fallback; `QueryInterface` answers only what an object is. N9: the owed unit tests.
  - The merge of `wip/b-once`: one import line met; the browser's click handler is only on the browser's
    `<video>`; the window program ends on Ctrl+C and the console's close signal with the same order (the
    viewer's numbers, the window's counts, mpv, the servers 2 s, `Close`).
  - Its runs: `internal/viewer` whole ok at 690ba9f (218 s); `internal/window`, vet, gofmt, the build at
    550571a; `cmd/...` at 3e9dceb. Its self-check (19:05, 49 s, CPU 36%): play to picture median 222 ms,
    worst 239; the frame exact; the over-cap file through the watchdog; reload in full screen; the allowed
    download with the page told; the job test 7 alive, 0 after the kill, the released program alive.
- **Read by me:** the player-program bounds (`play.go` `playerProgram`); the commit list against the brief.
- **The main head fa8c011 merged into `wip/b-window` by me (276e167, `-X ours`, pushed):** no conflict; this
  track's files are byte for byte as at 690ba9f; against main the branch differs in 44 files: only
  `internal/window`, `internal/viewer`, `cmd/tgarchive`, `cmd/tgarchive-window`, `go.mod`, `go.sum`.
- **The full runs, once, on 276e167, started 19:17** (said to the owner first; PC 6.1 GB free, CPU 78%): whole
  tests of `internal/window` and `internal/viewer`, the race detector on `internal/window` (the bridge and
  the pipe are the new concurrent code; in the Linux container the window itself is a stub, its bridge and
  pipe tests run), then `cmd/...`, vet and the build without cgo; results in `runs-b6/`.
- **Next:** the entry (18) with the `go.mod` lines and the licences; the window's program built into the
  owner's `bin` as `tgarchive-window.build.exe`; the viewer's build of the same commit as `tgarchive.exe`
  (it holds the player-program bounds); the board's line for the owner: `b\b-window.cmd`.

### 19:21: the window's full runs: all ok but one data race in a test; sent back
- **Full runs on 276e167 (`runs-b6/`, 19:17 to 19:21):** whole tests ok: `internal/window` (1.5 s),
  `internal/viewer` (223 s), all five commands; vet and gofmt clean; builds without cgo. **The race detector
  on `internal/window`: one DATA RACE, in `TestWatchdogRestartsSilentMPV`:** the test's cleanup writes the
  package variables `ipcTimeout` and `pingEvery` while a bridge goroutine (`watchLoading`) reads
  `pingEvery`. The program itself never writes them, so it is not a defect of the running window; it is
  the kind the lessons name (a test changing a package variable a loop reads; tunables belong in a struct
  handed over at construction).
- **Sent back to the window's coder (19:21):** those bounds become fields set at construction, no test assigns
  a package variable, a test's goroutines have ended before it returns. Then I run the race detector on
  `internal/window` again (that one run only), and write the entry.

### 19:26: the window's race fixed and run again; entry 18 written; the window's program in place for the owner
- **`wip/b-window` 65d20f2 (pushed):** the race fixed (the three bounds are fields set at construction; no
  test assigns a package variable; `Bridge.Close` waits for its goroutines). It changes four files of
  `internal/window` only. **The race detector on `internal/window` again (`runs-b6b/`): ok, no data race;**
  the package's and the command's tests ok; builds without cgo.
- **`MERGE-QUEUE.md` entry 18: `wip/b-window` 65d20f2**, with the `go.mod` requirement, the licences, the
  `go.sum` lines and why the module stays. The board row leads with it.
- **Tried by me as the starter starts it, on the invented archive (the built program, a visible window for 8
  s):** it opened, found ffmpeg and the mpv beside `bin` (`mpv_starts` 1), closed by its window in 140 ms
  with no process left, and wrote `window-stats.json`, `window.json` and the viewer's stop snapshot. (A
  first try with the window hidden could not be closed by its window and was ended by me; the job left
  nothing behind.)
- **The owner's program:** `tgarchive-window.build.exe` of 65d20f2 in the track's `bin` (19:24);
  `b\b-window.cmd` takes it. The browser viewer's `tgarchive.exe` stays the build of b2dfe5b (entry 17 as
  merged); the viewer's changes of entry 18 reach it when that is merged and built.
- **Nothing of this track is running** (no coder, no reviewer, no run).
- **Next, in order:** (1) what the owner says after `b\b-window.cmd` (mpv's controller with the mouse, the
  first file from the NAS, the arrows); then `window-stats.json` and `stats-last.json` in
  `old-archive-4\viewer` (numbers only). (2) After entry 18 merges: the viewer built from the main head into
  `bin`. (3) `TestTimingUnderWriteLoad` without real time. (4) The frame command's JPEG refusal. (5) The
  pages drawn, when the browser pane shows, and as another device sees them. (6) The stall: the first slow
  start's numbers.

### 19:45: the owner used the native window on the old archive; two things to fix, both briefed and started
- **The owner, 19:42:** "I tried the new one. It works, but when I drag to a random month (for example, August
  2026) it didn't create any thumbnails, until I scrolled down then up again. Also, one video was a bit
  harder to play, since the progress bar kept disappearing. It was on screen as long as I moved the bar,
  but then would disappear, even if I moved the bar to the bottom where it should be. The same video was
  fine when I opened it again a minute later, and other videos were fine."
- **The numbers of that use** (`stats-last.json` reason "stop" and `window-stats.json` in the owner's viewer
  folder, written at the close: **the numbers file survives a closed window now**; counts only; 182 s):
  - mpv: 5 plays, 0 failed, **play to picture median 260 ms, worst 580 ms, from the NAS**; one mpv, no
    restart, no hang, no message dropped; `PathOf` 5 started, 0 failed.
  - The library's opens: 1,502, median 93 ms, **worst 447 ms, none over a second**; the root's first check
    25 ms; the open step is the long one (87 ms median), the stat 6.5 ms, taking the root 0. No stall in
    this start. The shape request: median 207 ms (5 requests), the index at start 6.8 s.
  - Thumbnails: 1,056 requests: 392 from the cache, 16 the smaller size, 648 "none"; 607 asked, 851 made
    (428 ms each at the median), 0 dropped, 0 waiting at the close.
- **The thumbnails after a jump, read in the code by me** (`web/js/dom.js`, `maker.go` `urgent`): every tile a
  drag passes over asks; in the owner's mode (paced) a second ask does not move a waiting job to the
  front; and a tile seen again waits out its growing pause (up to 60 s). **Brief `BRIEF-B4-thumbs-jump.md`**
  (a tile asks only when it stays about 300 ms; a new ask moves a waiting job to the front in every mode; a
  place seen again starts again within 1 s; old asks give way; the asks' answers and a job's wait in the
  snapshot). The second coder, resumed, copy `wt-b-faces`, branch `wip/b-thumbs` cut from `wip/b-window`
  65d20f2; since 19:45.
- **mpv's bar: `BRIEF-B4-window-bar.md`**: its controller always shown as a bar that does not cover the
  picture (its own options), and a count of plays where mpv's idea of its size differs from the window it
  was given. Good news in the report: the controller answers the real mouse (the thing no check could
  show). The window's coder, resumed, copy `wt-b-window`, branch `wip/b-window` on top of 65d20f2; since 19:45.
- **Entry 18 is not merged yet (main is fa8c011):** when both pieces are back, `wip/b-thumbs` is merged into
  `wip/b-window`, the full runs once (whole tests of `internal/viewer` and `internal/window`; the race
  detector on both: the makers' queue and the bridge are concurrent code that changed), and entry 18's
  head is replaced.
- PC before the starts: 5.1 GB free, CPU 41%.

### 19:55: mpv's bar handed back (c75b1f6); the thumbnail piece in its last run
- **`wip/b-window` c75b1f6 (pushed; only `internal/window` and `cmd/tgarchive-window` changed):** mpv's
  controller is always shown, as a bar under the picture (its own script options: `osc-visibility=always`,
  `osc-layout=bottombar`, `osc-boxvideo=yes`, `osc-vidscale=no`, no window buttons, no idle logo, its
  full-screen button off: full screen stays the page's; all accepted by this mpv; 60 fixed options now).
  The mode is put back at each file's first picture (the self-check showed the picture's margin lost
  after an idle mpv). A click on the picture still pauses; the page draws no bar of its own.
- **The size comparison:** at each first picture mpv's own size against the child window's; counted in
  `window-stats.json` (`picture_size_mismatches`, `_made_to_agree`, `_still_off`). In the self-check 8 of
  8 agreed (four shapes, a resize between): **the owner's one bad play stays unexplained**; the always-shown
  mode removes the timer that hid the bar.
- **Its self-check (three runs in all, the last 26 s, CPU 83%):** 5 plays, play to picture median 124 ms;
  the bar's share under the picture 0.117 of the frame (about 40 px); nothing left running. On c75b1f6:
  `internal/window` twice ok, vet and gofmt clean, builds without cgo.
- **For the owner only:** the bar staying under the pointer and its buttons taking clicks. If the bar should
  come and go again, the controller has an option that makes the margin follow it.
- **`wip/b-thumbs` (copy `wt-b-faces`):** committed as 640b14b (two tests that fail on the old code) and
  09a7eb7 (the fix); read by me: the queue (a second ask moves a job to the front in every mode; asks older
  than a minute are let go; first ask to made is timed; all under the queue's lock, the clock injected). Its
  coder is in its last run.

### 19:57: the thumbnail piece handed back; both joined into `wip/b-window` (1aa9ac4); the full runs started
- **`wip/b-thumbs` 09a7eb7 (pushed): handed back; the whole package ok on it (247 s).** Both causes proven
  by tests that failed first: a job asked again was not taken first in the paced and ahead modes
  (`TestThumbQueueReaskGoesFirst`); a tile back on screen inside a long pause asked 0 times in 1.3 s, and a
  tile on screen for 0.1 s during a drag asked (`TestThumbAskSchedule`: **the real `dom.js` run in Node**
  with a stand-in clock, observer and fetch; skipped where Node is missing). Built: a tile asks after 300
  ms on screen; a second ask goes to the front in every mode; a tile seen again asks within about 1.3 s;
  asks older than a minute are let go (the walk makes them later; a tile on screen asks again); the
  snapshot's `thumb_asks` (answers made, pending, none; moved to the front; let go; first ask to made,
  median and worst). The old app did not move a re-asked job either (read by the coder in `wt-v12.32`).
- **No separate independent review for these two pieces** (each small and named, with tests that fail
  without the fix; the queue read by me; the page's schedule tested by running it): said in the entry.
- **Joined in `wt-b-window`:** `wip/b-thumbs` 09a7eb7 into `wip/b-window` c75b1f6 (45816da, no conflict);
  one line by me (f6da7a8: the age at which an old ask is let go is a constant, since tests move the
  clock); the main head 2c5765f merged in (1aa9ac4, `-X ours`; this track's files unchanged by it; against
  main the branch differs in 51 files: this track's packages, `go.mod`, `go.sum`). Pushed.
- **The full runs, once, on 1aa9ac4, started 19:57** (said to the owner first; PC 4.7 GB free, CPU 49%): whole
  tests of `internal/window` and `internal/viewer`; the race detector on both (the makers' queue and the
  bridge changed); then `cmd/...`, vet, the build without cgo; results in `runs-b7/`.
- **Next:** entry 18's head replaced (65d20f2 to 1aa9ac4) with what was added; the window's program and the
  viewer built from 1aa9ac4 into the owner's `bin`.

### 20:08: the full runs passed on 1aa9ac4; entry 18 updated; the owner's builds in place
- **Full runs on 1aa9ac4, once (`runs-b7/`, 19:57 to 20:07):** whole tests ok: `internal/viewer` (238 s),
  `internal/window`, all six commands; the race detector: `internal/viewer` ok (602 s), `internal/window`
  ok, no data race; vet and gofmt clean; builds without cgo.
- **`MERGE-QUEUE.md` entry 18 has a last block: merge 1aa9ac4 instead of 65d20f2.** The board row leads with it.
- **The owner's builds (20:07):** `tgarchive-window.build.exe` and `tgarchive.exe` of 1aa9ac4 in the track's
  `bin` (`tgarchive.exe.b2dfe5b.bak` and `.d4269cc.bak` kept; the older `.16376c9.bak` removed by me: it was
  this session's own copy). Neither program of the owner's was running.
- **Tried by me as the starter starts it, on the invented archive (8 s, a visible window):** opened, found
  mpv (`mpv_starts` 1), closed by its window in 158 ms, nothing left; `window-stats.json` has the size
  counts and the viewer's stop snapshot has `thumb_asks`.
- **Nothing of this track is running** (no coder, no reviewer, no run).
- **Next, in order:** (1) what the owner says after the next use of `b\b-window.cmd`: the bar staying, the
  thumbnails after a drag; then the two numbers files in `old-archive-4\viewer` (`thumb_asks`: the wait from
  first ask to made; `picture_size_mismatches`). (2) After entry 18 merges: the viewer and the window built
  from the main head into `bin`. (3) `TestTimingUnderWriteLoad` without real time. (4) The frame command's
  JPEG refusal. (5) The pages drawn, when the browser pane shows, and as another device sees them. (6) The
  stall: the first slow start's numbers.

### 20:21: the owner used the build of 1aa9ac4; the bar is to hide again; a thumbnail flood found in the numbers
- **The owner, 20:18:** "I tried it. B-window.cmd goes to it, the -viewer doesn't. It's mostly good. I think
  the viewer bar progress/seeking bar itself is kind of ugly and busy, and I did prefer when it hid."
  Read by me: the window's starter opens the native window, the viewer's starter the browser as before
  (both took the new build: the programs in `bin` are the 20:07 ones); said back to the owner, with the
  question whether the browser starter should open the window too.
- **The numbers of that use** (both files written at the close, 20:18; a 24 s session; counts only):
  - `thumb_asks`: the page's asks answered made 61, pending 430, none 0; moved to the front 449; let go 0;
    **first ask to made: median 3.0 s, worst 7.4 s** (83 thumbnails).
  - **The makers' queue: 4,786 asked, 2,653 dropped, 2,033 waiting at the close**, with 43 blocks of tiles
    listed. Cause, read by me: `media.go` `mediaInfo` queues every file a listing or a post returns as
    urgent in every mode but "asked only". **Brief `BRIEF-B4-thumbs-listing.md`** (a listing queues nothing;
    only a tile that asks does). The second coder, resumed, copy `wt-b-faces`, branch `wip/b-thumbs2` from
    1aa9ac4; since 20:21.
  - The window: 1 play, its picture after 572 ms, **counted as failed with `player`** though nothing hung or
    restarted: the window was closed while it played. No size mismatch counted.
  - The library's opens: 186, worst 304 ms; the shape request 204 ms.
- **mpv's bar: `BRIEF-B4-window-bar2.md`**: the automatic mode again, a plainer layout from the controller's
  own options, about 2 s before it hides, shown while paused, two pictures of the window's own content for
  the owner; a play ended by the close counted as stopped. The window's coder, resumed, copy `wt-b-window`,
  on top of 1aa9ac4; since 20:21. PC: 5.2 GB free, CPU 30%.
- **Entry 18 (1aa9ac4) is not merged yet:** when both are back they are joined into `wip/b-window`, the full
  runs once (the makers' queue and the bridge change again: both race runs), and the entry's head moves.

### 20:24: the owner's two directions; board messages read late; this session hands over at entry 19
- **The owner, 20:25:** "Eventually we'll only have the window. The browser should probably be deprecated. The
  longer fix for the thumbnails is that the viewer, or another app on the NAS, creates them all in the
  background." Written to the integrator as board message 51 with a proposal (a headless `tgarchive thumbs`
  of the same makers, usable on this PC and in a container on the NAS; a second read-only thumbnail folder
  for the viewer; `-lan` for the window before the browser starter goes). **Not started: for the next
  session.**
- **Read late (20:28), all addressed to this track:** the integrator's 44 (hand over at the natural point),
  47 (entry 18's head), 48 (the app used like a Telegram client: the reading side is the viewer's, after
  entry 18; "start no new piece" lifted except above about 80%), 50 (**entry 18 is merged: 2625aa0; cut new
  pieces from it**; the read-only schema door is this track's; a backspace byte had stood in the row where
  `b\b-window.cmd` was meant: scan every row for bytes below 32), 39 and 40 (commands for the owner by
  full path; the program's own folder first for ffmpeg, mpv and the loader); Core's 37 and 39 (the door
  `catalog.ReadOnlySchema` and `catalog.SchemaWords` for the viewer's read-only open: two lines).
- **This session is above 80%: it finishes the two pieces in hand to their listing (entry 19) and hands
  over.** In hand: `wip/b-thumbs2` (a listing queues no thumbnails; the second coder, in its last run) and
  `wip/b-window` on top of 1aa9ac4 (mpv's bar hides again and is plainer; a play ended by the close is not
  a failure; the window's coder).

### 20:27: both pieces in hand are back; one small addition running
- **`wip/b-thumbs2` 678b417 (pushed; the whole package ok on it, 225 s):** a listing or a post queues no
  thumbnail in any mode (its test showed 288 jobs queued by listing 620 tiles before the fix); only the
  page's ask queues; `asked` and `dropped` count the page's asks only; the queue's bound is 256 in every
  mode. **Addition running on the same branch (the second coder, since 20:33):** the read-only schema door
  (Core's messages 37 and 39) in the viewer's `New`, without refusing an older catalogue the viewer can
  read (the owner's is at an older step).
- **`wip/b-window` 0dbc35e (pushed; on top of 1aa9ac4):** mpv's bar hides again (2 s without movement
  instead of half a second; any movement shows it; shown while paused, by the controller's own message at
  each change of pause); no file name on it; the picture has the whole frame. **Only half plainer:** this
  mpv's slim layouts have no seek bar, time, play or volume, so the layout is the default one, and its
  playlist, chapter, subtitle and audio buttons cannot be removed by an option. A play ended by the close,
  the page's stop, a new document or a new file counts as `plays_stopped`. Its self-check (40 s, CPU 44%):
  3 plays, play to picture median 57 ms; nothing left running. `internal/window` twice ok, vet and gofmt
  clean, builds without cgo.
- **Two pictures of the window's own content on an invented clip** (`window-bar-chosen.png`,
  `window-bar-default.png` in the project folder; drawn by the window's handle, never the screen). Looked at
  by me; the chosen one sent to the owner. **For the next session, a proposal to put to the owner:** mpv's
  bar off and a slim bar of the page's own under the frame (play, seek, time, volume, in the app's style),
  since mpv's cannot be made plain by options.

## STATE FOR A TAKE-OVER (11-15 20:44): enough to take over from this block alone
Session B4 ends here: its context is full (the integrator's messages 44 and 48). Nothing of this track is
running: no coder, no reviewer, no run, no viewer or window started by the session.
- **Merged today (the main head is 2625aa0):** entry 16 (the library's opens, files not downloaded, conversions
  measured, crafted files and ffmpeg), entry 17 (each file once in the whole library, a click on the video,
  the numbers file at a closed window), entry 18 (the native window with mpv, `internal/window`,
  `cmd/tgarchive-window`, the one requirement `github.com/jchv/go-webview2`).
- **Listed, not merged: `MERGE-QUEUE.md` entry 19, `wip/b-window` 3244f0d on `private`** (holds 2625aa0; 18
  files): mpv's bar hides again; a play ended by the close is "stopped"; a listing queues no thumbnail; the
  read-only schema door. Full runs once on 3244f0d (`runs-b8/`): whole tests and the race detector on
  `internal/viewer` and `internal/window`, the commands, vet, gofmt, the build: all ok. **After it merges:
  build the viewer and the window from the main head into `bin`** (the builds there now are 3244f0d's, the
  same code).
- **The owner's programs:** in the session's `bin`
  (`%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b\bin`): `tgarchive.exe` (the
  browser viewer; the starter copies it to `tgarchive-viewer.exe`) and `tgarchive-window.build.exe` (the
  starter copies it to `tgarchive-window.exe`), both of 3244f0d, placed 20:43; `.bak` files of 1aa9ac4 and
  b2dfe5b. mpv 0.42.0 is unpacked beside `bin` (`tgarchive-b\mpv`; the owner's yes of 16:08). The catalogue
  is `old-archive-4` (schema step 16, opened read-only). Starters, in the project folder's `b` (not in git):
  `b\b-window.cmd` (the window: the owner's way in now) and `b\b-viewer.cmd` (the browser). The owner used
  the window three times (19:42, 20:18, and the build of 1aa9ac4): "It works", "It's mostly good".
- **What the owner said today, in order, about this track:** the first video slow (12:54, 15:41), then quick
  (17:21); "seeing not downloaded files in the library isn't useful. They should be hidden, or they should
  link to their known duplicates" (15:49); converted videos "very slow ... seeking is impossible" (15:49);
  yes to mpv and the WebView2 module (16:08); on a file in two chats: "In that chat it can show, but in a
  unified stream it should be folder[ed] under one" (17:02); "clicking the main video should start/pause
  it" (17:21); after the window: thumbnails missing after a drag to a month, and mpv's bar disappearing on
  one video (19:42); the always-shown bar "kind of ugly and busy, and I did prefer when it hid" (20:18);
  **"Eventually we'll only have the window. The browser should probably be deprecated. The longer fix for
  the thumbnails is that the viewer, or another app on the NAS, creates them all in the background"
  (20:25).**
- **Waiting for the owner (asked, no answer yet):** whether mpv's bar stays (it cannot be made plain by its
  options: the slim layouts have no seek bar or time) or a plain bar of the app's own is drawn under the
  video with mpv's bar off. A picture of today's bar on an invented clip: `window-bar-chosen.png` (sent).
- **Next, in order (cut every piece from the main head; read `BOARD.md` messages 37, 39, 40, 44, 47, 48,
  50, 51 first):**
  1. **After the owner's next use, read the two numbers files** in `old-archive-4\viewer` (numbers only):
     `stats-last.json` (`thumb_asks`: first ask to made was 3.0 s median, 7.4 s worst before the listing
     fix; `thumbs.asked`, `dropped`; the open's steps and `slow_opens`: **the first video's 18 s stall of
     15:38 is still not explained**; no start since had one; the snapshot now names the step and whose open
     it was) and `window-stats.json` (`play_to_picture`: 260 ms median from the NAS; `plays_stopped`;
     `picture_size_mismatches`: 0 so far, the one bad play of the bar is unexplained).
  2. **The app used like a Telegram client, the reading side** (board message 48, FEATURES 12 sixteenth
     round, "Waiting for the owner" item 25): a conversation opened at its newest message, live while
     open, replies, edits and reactions shown; the viewer sends nothing and has no Telegram code: every
     request is the collector's. Read TRIED-BEFORE 9, 10, 15 and the lessons' viewer sections first.
  3. **The window as the only viewer (the owner, 20:25; message 51a):** `-lan` and `-lan-data` in
     `tgarchive-window` (the home-network listener the browser viewer has; read `REVIEW-B3-lan.md` and
     `lan.go` first: "Open in the player", the preferences and the player's path stay this PC's only); the
     window showing `viewer.New`'s own sentence when the archive cannot be opened (today its fixed line);
     ffmpeg looked for in the program's own folder first (message 40c: mpv already is); then the browser
     starter is said to be retired on the board. The pages stay web pages (the window shows them, phones
     need them).
  4. **All thumbnails made in the background (the owner, 20:25; message 51b; the roadmap's NAS row):** a
     headless command of the same makers (`tgarchive thumbs`: the catalogue read-only, the library by a
     path, a folder to write to; skips what exists; counts only; ends cleanly), a starter for this PC
     (about 27 hours for 241,149 files at the measured 2.5 a second; it shares the Wi-Fi with the old app's
     copies: say so before the owner starts it), the same program built for Linux for a container on the
     NAS (host network mode, the owner's rule; ffmpeg's speed there is the measurement that decides), and a
     second, read-only thumbnail folder the viewer's makers look in before they decode (never on a click's
     path). The integrator decides whether it stays the core/NAS track's row.
  5. **A plain bar of the app's own under the video**, if the owner says so (mpv's `--osc=no`; the page
     already gets `state` and sends `seek`, `pause`, `volume`).
  6. Smaller, this track's: `TestTimingUnderWriteLoad` rewritten without real time (it failed once on a
     loaded PC); the frame command's JPEG step refused an invented RealMedia clip on ffmpeg 9.0.2 (possibly
     thumbnails lost for some real files); an over-cap video costs about 7 s in the window before the page
     takes over; the window is counted as hidden when minimised (probably stops the video); Left and Right
     seek while a video plays in the window (previous and next are the buttons); the pages as another
     device sees them (never looked at); the people page stays "later".
- **Lessons of this session, for whoever continues:**
  - **Read the board's messages again at every listing and at least once an hour.** This session read them
    once at its start and missed eight addressed to it for over an hour (a merge, a new listed feature,
    the hand-over rule).
  - **A review after a rewrite.** Twice a fix round rewrote the reviewed part (the "each file once" rule;
    the WebView2's creation): a second independent look found a new confirmed defect both times.
  - **When a rule keeps needing patches, change the rule.** "Each file once" as first appearance over the
    whole archive hid files under a search or a hidden post; "each exact group once among what the query
    lists" removed the cause.
  - **The owner's numbers files answer more than the owner's words:** the thumbnail flood (4,786 asked in
    24 s) and the play counted as failed were found only in them. They are written at every close now.
  - **In a Python script inside a heredoc a doubled backslash arrives as one**: `'b\\b-window'` became a
    backspace byte on the board. Build such paths with `chr(92)`, and scan what was written for bytes
    below 32.
  - The browser pane of the app is often hidden: a page then draws no tiles (no frames). Read the page's
    own requests instead, or let a coder's self-check drive the real pages in the window.
  - A reviewer or coder can run mpv headless and the window's `-selfcheck` on invented clips; nobody moves
    the owner's pointer: what only a real pointer shows is said as "for the owner".
- **Copies (all clean, all pushed):** `wt-b-window` on `wip/b-window` 3244f0d; `wt-b-faces` on `wip/b-thumbs2`
  eb59ad0 (joined into 3244f0d); `wt-b-viewer` on `wip/b-viewer4` d4269cc (merged). Branches on `private`
  that are merged or joined and can go with the owner's word: `wip/b-open`, `wip/b-notsaved`,
  `wip/b-viewer4`, `wip/b-once`, `wip/b-thumbs`, `wip/b-thumbs2`, `wip/b-window-spike`.
- **This session's files (project folder):** `BRIEF-B4-*.md` (19), `REVIEW-B4-open.md`,
  `REVIEW-B4-notsaved.md`, `REVIEW-B4-once.md`, `REVIEW-B4-once-2.md`, `REVIEW-B4-window.md`,
  `REVIEW-B4-window-2.md`, `SPIKE-native-window.md`, `PLAN-native-window.md` (its last section), the runs
  `runs-b4/` to `runs-b8/`, the two pictures `window-bar-*.png`.

## Session B5 (took over 11-15 21:09)
- **21:09 taken over** from the block above. Read by me, in full: the board (rows, messages 37 to 54, the
  owner's list), the take-over block, `LESSONS-viewer-ix12.32.md`, `LESSONS.md`, TRIED-BEFORE 8, 9, 10, 15,
  16, FEATURES 7, 9 and section 12 rounds 7, 15, 16; in the code: `conv.go`, `chats.go`, `web/js/chat.js`,
  the two commands, the heads of `maker.go`, `thumb.go`, `refresh.go`, the message tables of the catalogue.
- **The disk matches the block:** main head 2625aa0; entry 19 (`wip/b-window` 3244f0d) listed, not merged;
  the three copies clean; the owner's builds in `bin` are 3244f0d's (20:43). The owner's two counts files
  are of 20:18, before that build: nothing new to read. No viewer, window, mpv or ffmpeg running.
- **21:17 three pieces, side by side, each in its own copy, each cut from 3244f0d** (entry 19 is not
  merged yet and touches the same packages; the main head is merged in before the full runs). **Three
  Opus coders run, started 21:13, 21:15 and 21:17** (the PC before the third: 3.6 GB free, 55% CPU, three
  of the pages track's race containers going; each coder checks free memory before a test run and waits
  under 2 GB, named tests only):
  - **T, every thumbnail in the background** (the owner, 20:25): `BRIEF-B5-thumbs-bulk.md`, copy
    `wt-b-faces`, branch `wip/b-thumbsbulk`. A headless `tgarchive thumbs` on the viewer's own makers
    (numbers only, resumable, `-limit` for a measuring run), a work list for a machine without the
    catalogue, a second read-only thumbnail folder for the viewer (`-thumbs-from`), deploy files for a
    container on the NAS (`archiver/deploy/thumbs/`, a new folder: host network, user 1000:10).
  - **W, the window as the only viewer** (the owner, 20:25): `BRIEF-B5-window-only.md`, copy
    `wt-b-window`, branch `wip/b-winlan`. `-lan` and `-lan-data` in `tgarchive-window` with what a home
    device can and cannot reach written out and tested; the window shows the viewer's own sentence when
    the archive cannot be opened; ffmpeg looked for in the program's own folder first; three small things
    from the first real uses.
  - **C, the chat page as a client shows it, reading only** (board message 48): `BRIEF-B5-client-reading.md`,
    copy `wt-b-viewer`, branch `wip/b-client`. Live while open through one cheap ask (a bounded record of
    the posts each index update touched), "edited" with earlier versions, mine and theirs, service lines,
    jump to newest, the Chats list's line per chat, a foot left for a compose box. Not in it, another
    track's: reactions and a service message's action are not in the catalogue (listed for Core on the
    board).
- **The files the three meet in:** `cmd/tgarchive-window/main.go` and `cmd/tgarchive/viewer.go` (T adds one
  flag line to each; W owns the window's file), `internal/viewer/server.go` (C adds routes), `viewer.go`'s
  `Config` (T adds one field). They are joined into one branch by me before the review's fixes end, as
  B4 did with `wip/b-viewer4`.
- After each hand-back: my read of the risky part, one independent review, its fixes, the full runs once,
  then `MERGE-QUEUE.md`.
- **21:18** the review brief for all three pieces is written (`BRIEF-B5-review.md`: read-only, probes in
  a scratch folder, confirmed or plausible; W looked at as an attacker on the home network and as a page
  script would). Board: my row, a new row for Core (reactions and a service message's action in the
  catalogue), message 55. Notes committed (e61790a). The PC with three coders: 4.0 GB free, 35% CPU.
  **Next step, in one line:** at each hand-back read the risky part myself, start its independent
  reviewer with `BRIEF-B5-review.md`, then its fix round; when all three are fixed, join them on the main
  head, full runs once, one entry in `MERGE-QUEUE.md`.
- **21:38 W handed back** (`wip/b-winlan` 58149f87, pushed, copy clean; 14 files; its report says the
  window's named tests, the commands' tests, vet, gofmt, the build and the self-check through the real
  pages passed). **Read by me:** `lan.go`'s change, the window command's new session (start, stopping,
  stop), the listener's error paths. Shape sound: the window's own loopback port is untouched, the home
  listener is the reviewed one, a refusal leaves the window open on this PC only and Settings says why.
  **Not taken on trust, given to the reviewer:** "every ListenLAN error is fixed text" (two returns in
  `listenLAN` wrap another error's text, which now reaches the console line and two pages); the closed
  set of `OpenFailureWords`; ways round the bridge's source rule; the ending order with two servers;
  `..\ffmpeg\` as a planting place; the 1 s ping. **Its independent, security-minded review runs since
  21:38** (`BRIEF-B5-review.md`, scratch `wt-b5-review-W-scratch`, read-only).
  **Found by the coder, for the owner's word (small):** a minimised window stops its video (the page stops
  mpv when its document is hidden, `play.js`); the fix is one line outside that coder's bounds. My
  recommendation: a minimised window goes on playing; it goes with the fix round unless the review shows
  what else leans on that line.
- **21:41 T handed back** (`wip/b-thumbsbulk` e6fcb3ac, pushed, copy clean; 14 files, about 2,100 lines:
  `internal/viewer/bulk.go` new, `maker.go`, `thumb.go`, `cmd/tgarchive/thumbs.go`, `deploy/thumbs/`).
  Its report: named tests, the two small command packages, vet, gofmt, the Windows and Linux builds
  passed; with the real binary on an invented archive a run made every thumbnail once, a second run made
  none, a list run equalled a catalogue run byte for byte; the image ran as 1000:10 read-only with no
  network and ended cleanly on a stop (the image was removed again). **Read by me:** the cache's change
  (`thumb.go`: whole writes for marks too, `adoptOwn`, `takeFrom`, `wholeJPEG`, temporary files kept
  when young). **Differences it states, accepted pending the review:** `-sizes` defaults to `grid` (what
  the background walk makes today); `-limit` may end a few short or over. **Its independent review runs
  since 21:41** (`BRIEF-B5-review.md`, eleven leads, scratch `wt-b5-review-T-scratch`): hardest at the
  split of `maker.make` (concurrent code the race detector has not seen), two programs on one folder,
  the list against odd names, every printed line, the deploy files. **Said by the coder:** it ran
  `docker builder prune -f`, which cleared Docker's whole build cache on this PC (260 MB), not only its
  own layers; reviewers are told never to prune.
- **Running now:** the reviewers of W and T; the coder of C.
- **21:48 W's independent review is back** (`wt-b5-review-W-scratch/REVIEW.md`, probes beside it; the copy
  left clean). Verdict: no way round the bridge, the navigation rules or the access classes; **one
  finding holds the merge: F1, the window's console line prints the start error's raw text, which holds
  the catalogue's full path.** Low: F2 a window closed while the archive opens leaves listeners up; F3
  the two servers share one 2 s bound in turn (also in `tgarchive viewer`); F4 the refusal words are
  fixed only by convention (my lead: true today, fragile); F5 a relative `-ffmpeg` or `FFMPEG_PATH` is
  taken against the current folder; F6 the one-folder-up place can be planted when it is a volume root
  (never looked at for mpv either); F7 an unreachable share gets the fixed line; F8 a dead home listener
  would still read "On". **My decisions (`BRIEF-B5-window-fixes.md`): all eight fixed;** mpv's and
  ffmpeg's lookup orders become one (flag, the program's own folder, the environment variable, PATH);
  the 1 s ping goes back to the reviewed 2 s (no number shows it pays); **a minimised window goes on
  playing** (the stop-when-hidden line dropped: the review found nothing else leans on it; a locked
  screen then also keeps playing: said to the owner). **The same coder is in the fix round since 21:48.**
  A fix round that rewrites reviewed parts (the ending order, the lookup) gets a second look.
- **21:51 C handed back** (`wip/b-client` 077742a4, pushed, copy clean; 12 files, about 1,970 lines:
  `live.go` new, `conv.go`, `chats.go`, `server.go`, small changes in `index.go`, `refresh.go`,
  `viewer.go`, the two pages and the stylesheet). Its report: 42 named tests pass (its ten, the
  refresher's random, merge and reference tests, the wall, the access classes); the live ask at the
  invented real size costs microseconds against the 200 ms budget and reads nothing when nothing changed
  (counted by a counting driver); the pages driven in a headless browser on an invented archive with a
  second writer: a new post, an edit, a deletion and an album's late member each showed within about 3 s,
  a scrolled-up reader kept its place, a hidden page asked nothing. **Read by me:** the refresher's
  change (a record of the posts an update redid plus those the change log named: a few lines; it stores
  the update's own sorted slice, an aliasing question given to the reviewer) and the two calls that note
  a step after a version is published. **Differences it states:** the record is keyed by its own step,
  not by the index version (an edited text alone makes no new version: right); `viewer.go` touched for
  one field and two calls. **Its independent review runs since 21:51** (`BRIEF-B5-review.md`, ten leads,
  scratch `wt-b5-review-C-scratch`): the record's ordering against concurrent asks, hidden and other
  chats, the cost with many tabs, the page's timers and scroll anchoring, "mine and theirs" in a chat two
  accounts see.
- **Found by C's coder, another track's:** a message's sender is an id, not a name (no table of names in
  the catalogue): added to Core's row in "Listed and unbuilt" (21:51). The old archive's bring-in keeps no
  earlier versions of edited messages (`internal/bringin`, this track's: a later piece).
- **Running now:** W's fix round (its coder), the reviewers of T and C.
- **21:55 T's independent review is back** (`wt-b5-review-T-scratch/REVIEW.md`, probes beside it; the copy
  left clean). **Verdict: not ready.** Sound: the split of `make`, two programs on one folder, stop and
  resume, the walk, the printed lines on normal paths. **Confirmed, the two that matter:** (1) a
  thumbnail taken from a folder does not count as "found", so once nearly all thumbnails exist, 20
  scattered missing files mark the whole library "files missing": the viewer's makers stop and the bulk
  run a day later ends with a false sentence; (2) the bulk run stops at the same place on every run when
  20 of the newest files are missing, and takes staged and lost files into its work. Also confirmed:
  `-write-list` naming the catalogue replaces it; one odd path makes a whole list unreadable; a file of
  any content under a thumbnail's name is adopted unchecked; `-out` holding the library lists it and
  deletes temporary files in it; a many-scan JPEG in the second folder holds a maker for minutes; flag
  errors print back what was typed; the README's steps do not run from any folder; counts that do not add
  up. Plausible: the NAS's memory limit against one large picture (measured 13 to 15 bytes a pixel); a
  hanging share holding every maker. **My decisions (`BRIEF-B5-thumbs-fixes.md`): all twelve fixed.** The
  health rule looks at a few files known to be there before it declares the library gone (the review's
  fix); the bulk run takes library files only; large pictures one at a time and a `-max-megapixels`
  bound for the NAS; the README split into "whoever builds the image" and "the owner's steps". **The
  same coder is in the fix round since 21:55.** The health rule is a rewritten reviewed part: a second look
  follows.
- **Running now:** the fix rounds of W and T (their coders), the reviewer of C.
- **22:05 W's fix round handed back** (`wip/b-winlan` 51cabbed, pushed, copy clean; 24 files, about 1,240
  lines added since 58149f87). Its report: F1 to F8, the notes, the ping and the minimised window all
  done; the window's tests, the commands' tests, vet, gofmt and the build pass; the self-check through
  the real pages: **a minimised window went on playing (8.6 s to 11.6 s in 3 s), 0 requests to the
  server while hidden**; an archive that cannot be opened showed its fixed sentence. The one lookup
  order for ffmpeg and mpv: the flag (full path), the program's own folder (beside, the tool's folder
  beside, one folder up unless that is a volume root), the environment variable (full path), PATH.
  Differences it states: every viewer line now passes a filter (`viewerSay`) that blanks error and
  path-like arguments; flag errors are fixed sentences; `cmd/tgarchive/viewer_test.go` changed for the
  parallel shutdown; one new sentence for a catalogue that is there but cannot be opened. **Read by me:**
  the new `stopServers` and the start's stopped mark. **A second independent look runs since 22:05** (the
  same reviewer, range 58149f87..51cabbed, `REVIEW-2.md` to come): the ending, every printed line, the
  one lookup order against the earlier reviews of mpv's path.
- **For the owner, when the window build is in their hands:** with the stop-when-hidden gone, a locked
  screen, a fully covered window or a disconnected remote session should also keep a video playing with
  sound (only a real screen shows it).
- **Running now:** W's second look, T's fix round, C's reviewer.
- **22:07 C's independent review is back** (`wt-b5-review-C-scratch/REVIEW.md`, probes and a page model
  beside it; the copy left clean). **Verdict: not ready.** Sound: `refresh.go` reads and builds what it
  did before; the record is bounded and immutable per step; publish-then-note can double a post, never
  lose one; no leak between chats or past a filter; timers and anchoring. **Confirmed:** F1 a new post
  that lands inside the shown range (the collector catches a chat up newest page first) is sent as
  "changed" and the page drops it for good: a silent hole; F2 past 100 new posts in one step the rest
  wait for an unrelated change; F3 a file saved after its message never changes on an open page (every
  live media post stays "not downloaded" until a reload); F4 every reset drops the reader's place, and a
  bring-in while the viewer runs would reload every 3 s; F5 "changed" has no cap and another account's
  sightings redraw posts (a playing video stops); F6 "mine" in a chat two accounts see is whoever stored
  the row first; F7 senders are numbers, and the invented archive hides it (it writes names as senders);
  F8 an unused field keeps an old index alive. Plausible: F9 an empty filtered page walks the chat per
  step; F10 an older catalogue never shows edits live and does not say so. **My decisions
  (`BRIEF-B5-client-fixes.md`): all ten fixed.** New in the round: **senders' names read from the
  catalogue's `tg_peer_name`** (it exists since schema step 9; my board line of 21:52 said there was no
  such table: wrong, corrected 22:07; checked where it is written: only the old archive's bring-in calls
  `SavePeerNames`, so a new account's names are still Core's to record); a side is drawn only when it
  is known (in a shared chat by the sender being an account's own id); a `-real-rows` flag for the
  invented archive. **The same coder is in the fix round since 22:07.** A second look follows (the page's
  insert path and the record's new list are rewritten parts).
- **Running now:** W's second look; the fix rounds of T and C.
- **22:13 W's second look is back** (`wt-b5-review-W-scratch/REVIEW-2.md`). **Verdict: may merge.** F1 to F7
  and the notes gone, re-probed against 51cabbed; F8 gone in the window; the round broke nothing found;
  the ending read line by line (no line and no "ended" at a normal close, no deadlock). Left, all low or
  latent: N1 the console filter lets a name, a slice or a struct through (nothing passes one today); N2
  `StartError.Error()` is still the raw text (nothing prints it today); N3 the bare "beside the
  program" places now come before the environment variable; N4 `volumeRoot` is lexical (ProgramData,
  Public); N5 `tgarchive viewer`'s `-ffmpeg` help is out of date, and that command prints the viewer's
  "updating the index" line with an error's raw text (it was so before). **My decisions:** N1, N2 and N5
  fixed in one last small round, the index line at its source in the viewer; the home listener's end
  moved into one door in the viewer (`ServeLAN`) with a test that sees "on" go true then false with
  something really listening (the reviewer's way); N3 and N4 stay, each with one sentence for the
  packaging piece. **The same coder has it since 22:13.** I read that round myself; no third look.
- **Running now:** W's last small round; the fix rounds of T and C.
- **22:13 T's fix round handed back** (`wip/b-thumbsbulk` c38196ff, pushed, copy clean; 13 files, about
  1,430 lines added since e6fcb3ac). Its report: all twelve done, each review probe now a passing test;
  the named viewer tests (120 s), the two command packages, vet, gofmt, the Windows and Linux builds
  pass; no Docker touched. **The health rule now:** the count is unchanged (20 not found in a row, or
  over half of the last 50); when it trips, one maker opens at most 8 spread files known to be there,
  outside the lock; at least half answer: the pending files get `read` marks and work goes on; fewer:
  "files missing" as before, no mark. Asked-only mode opens no sample. Also: the bulk run takes library
  files only; pictures over 20 megapixels one at a time, `-max-megapixels` (the NAS file sets 24 with
  `mem_limit: 1g`; measured peak 10.5 bytes a pixel for a JPEG); every thumbnail ends in exactly one
  count and `done` equals their sum; flag errors are fixed sentences; the README in two parts.
  `stats.go` touched for the new counts. **Read by me:** `outcome` and `libraryAnswers`. **A second
  independent look runs since 22:13** (the same reviewer, range e6fcb3ac..c38196ff, `REVIEW-2.md` to
  come): hardest at the health rule's concurrency and at a sample that could declare a gone library fine.
- **Running now:** T's second look; W's last small round; C's fix round.
- **22:17 W's last small round handed back and read by me** (`wip/b-winlan` 152a0bc2, pushed, copy clean;
  11 files, 263 lines added since 51cabbed): the console filter is an allow-list (numbers, booleans,
  durations and the viewer's own fixed words: `viewer.LogWord`); `StartError.Error()` is fixed words;
  the "updating the index" line says one of three fixed causes at its source (the browser command too);
  one door `(*Viewer).ServeLAN` for the home listener, one server per viewer, with a test that sees "on"
  true with a dial succeeding, then false with the fixed sentence after the listener breaks. Its report:
  the window package, the six command packages, every `TestLAN*`, vet, gofmt and the build pass.
  **W is complete: reviewed twice, every finding fixed or decided. It waits for T and C, then the three
  are joined on the main head and the full runs go once** (whole `internal/viewer`, `internal/window`,
  the commands; the race detector on `internal/viewer` and `internal/window`: both changed concurrent
  code).
- **Running now:** T's second look; C's fix round.

## STATE FOR A TAKE-OVER (22:18, session B5): enough to take over from this block alone
Usage is low (the integrator's message 62, 21:54, read by me late, at 22:18): the three pieces in hand are
finished to one listing; nothing new is started. Messages 56 to 64 read 22:18.
- **Main head e5260c1** (entry 19 merged 22:09 as a squash; the batch and the pages' fix under it; schema
  step 20). The owner's builds in `bin` are 3244f0d's, the same code as entry 19.
- **Three branches, all pushed to `private`, all cut from 3244f0d, copies clean:**
  - **W, `wip/b-winlan` 152a0bc2 in `wt-b-window`: COMPLETE** (reviewed twice, `wt-b5-review-W-scratch/
    REVIEW.md` and `REVIEW-2.md`: "may merge"; the last small round read by me). `-lan` in the window,
    fixed words on every console line, both servers shut down together, one lookup order for ffmpeg and
    mpv, a minimised window goes on playing, the viewer's sentence when the archive cannot be opened.
  - **T, `wip/b-thumbsbulk` c38196ff in `wt-b-faces`: fix round done, its SECOND LOOK RUNNING** (the
    reviewer agent of T, range e6fcb3ac..c38196ff; `wt-b5-review-T-scratch/REVIEW-2.md` to come). If it
    says may merge: done. If it finds something in the health rule: one small round by T's coder.
  - **C, `wip/b-client` 077742a4 in `wt-b-viewer`: its FIX ROUND RUNNING** (the coder agent of C,
    `BRIEF-B5-client-fixes.md`, ten findings of `wt-b5-review-C-scratch/REVIEW.md`). Then one second
    look (the page's insert path and the record's new list are rewritten parts), then done. **The owner
    asked for this a second time at 21:51** ("the missing functionality of actually seeing/interacting
    with the chat, like the real telegram client"; message 60): it is the first to be listed if the
    others lag.
- **Then, once:** a new branch `wip/b-viewer5` from the main head e5260c1 in one copy; the three merged
  into it (they meet in `cmd/tgarchive-window/main.go`, `cmd/tgarchive/viewer.go`, `viewer.go`,
  `server.go`, `stats.go`, `ffmpeg.go`, `lan.go`: W rewrote the window command's start, T added one
  flag there and a `Config` field); build, gofmt, vet; tell the owner in one line; the full runs with
  `ix-tools/full-runs.sh`: whole `internal/viewer` (about 5 minutes), `internal/window`, the commands;
  the race detector on `internal/viewer` (about 12 minutes; the makers' health rule, the live record)
  and `internal/window`; then ONE entry in `MERGE-QUEUE.md` (entry 20), the board row, message to the
  integrator. After its merge: the viewer and the window built from the main head into the owner's
  `bin` (`tgarchive.exe` and `tgarchive-window.build.exe`; the starters copy them at the next start),
  and the image for the NAS built and saved as a file for the owner (the README's builder part).
- **For the owner once the build is in `bin`:** the chat page (names for the old archive, live only where
  a collector writes); a minimised window goes on playing (a locked screen too: only a real screen
  shows it); `-lan` needs a password set in Settings first and a start with the address (the starter
  `b\b-window.ps1` has no `-Lan` yet: add it, tried as the owner runs it); the thumbnail run:
  `tgarchive thumbs` on this PC, or the measuring run of 200 on the NAS (`deploy/thumbs/README.md`).
- **Open, not started (usage):** the old archive's earlier versions of edited messages
  (`internal/bringin`, "WANTED: message_version import"); a plain bar of the app's own under the video
  (asked 20:18, no answer); `TestTimingUnderWriteLoad` without real time; the browser starter retired on
  the board once the owner has used `-lan` from the window. **Another track's, listed on the board:**
  names written for a new account, reactions, a service message's action (Core).
- **Lessons of this session:** read the board's messages at every hand-back, not only at the start (I
  read message 62 twenty-four minutes late and resumed two agents meanwhile); check where a table is
  written before saying it does not exist (`tg_peer_name`); a time in the notes comes from `date`.
- **22:24 T's second look is back** (`wt-b5-review-T-scratch/REVIEW-2.md`). **Verdict: can merge after
  small fixes.** 9 of 12 gone, re-probed; the rewritten health rule held under four live makers and a
  Close in the middle (one check per trip, nothing marked twice, no hang); `done` equals the sum in
  every end state. Partly: 5 (ffmpeg's own memory and threads are outside the container's note), 6 (a
  zero-length thumbnail file is still taken at start-up), 12 (one file's "access denied" turns the
  second folder off for 30 s). New: N1 the health answer now writes a day of `read` marks on a library
  that is only partly there (the decided trade-off); N2 the bulk run's sample can be exactly the missing
  files; N3, N4 low. **My decisions, one last small round by the same coder since 22:24, read by me, no
  third look:** a mark written by a health answer is retried after an hour, not a day; the sample takes
  files with thumbnails first; the start-up walk skips files too small to be a thumbnail; ffmpeg's
  threads bounded for the bulk run and `GOMEMLIMIT` 512 MiB on the NAS; two README sentences.
- **Running now:** T's last small round; C's fix round.
- **22:28 C's fix round handed back** (`wip/b-client` f7dc5ec1, pushed, copy clean; 11 files, about 1,500
  lines added since 077742a4). Its report: all ten done; 58 named tests pass; the review's probes failed
  on the old code and pass now; the page model matched a first load after every one of 80 random steps
  at four seeds, with catch-ups stored newest first and files saved later; the live ask at the invented
  real size: 0.1 ms for new posts, 3.4 ms for 200 changed posts, the Chats list with names 8 ms for
  2,190 chats (budget 200 ms). In a headless browser on a `-real-rows` invented archive: names in every
  message head, own messages on the other side as "You", three catch-up pages stored newest first shown
  with no hole, a file saved later changing its post by itself, a reset keeping the reader's place to
  the pixel. New in the contract: a post inside the shown range comes as "changed" with `new`; a "more"
  answer returns the asker's own step; per-chat markers when the record is trimmed (one chat's page is
  reset, not everyone's); `before` for posts older than the shown range. **Read by me:** the
  refresher's change (a live-only list of the posts of files whose state changed, merged into a copy;
  the update's own lists untouched). **A second independent look runs since 22:28** (the same reviewer,
  range 077742a4..f7dc5ec1, `REVIEW-2.md` to come).
- **Running now:** C's second look; T's last small round.
- **22:29 the join is begun:** a new copy `wt-b-join`, branch `wip/b-viewer5` from the main head e5260c1
  (local, not pushed yet). W merged into it (f9f35ed3): one conflict in `internal/window/run.go`, an
  artefact of entry 19's squash (the main head equals 3244f0d in every file of this track: checked);
  resolved with the branch's file; the joined tree equals the tested `wip/b-winlan` in the track's
  paths (an empty diff). **Next step, in one line:** when T's last round and C's second look are in,
  merge `wip/b-thumbsbulk` and `wip/b-client` into `wip/b-viewer5`, build, vet, then the full runs once.
- **22:33 T's last small round handed back and read by me** (`wip/b-thumbsbulk` 174d25ad, pushed, copy
  clean; 10 files): a mark written by a health answer is retried after an hour (`healthMarkRetry`); the
  bulk sample takes files with thumbnails first and both parities; the start-up walk skips files too
  small to be a thumbnail; a whole thumbnail that cannot be put in place gets no mark; only folder-wide
  errors turn the second folder off; `-ffmpeg-threads` for the bulk run only (the viewer's own command
  line unchanged: tested) and `GOMEMLIMIT` 512 MiB on the NAS; two README sentences. Its report: the
  named viewer tests (92 s), the two command packages, vet, gofmt, both builds pass. **T is complete:
  reviewed twice.** Not measured by anyone: ffmpeg's memory per frame in the container, a hanging share.
- **22:33 T merged into `wip/b-viewer5`** (copy `wt-b-join`): two conflicts, both in the commands' flag
  lists (`cmd/tgarchive-window/main.go`, `cmd/tgarchive/viewer.go`), resolved keeping both pieces' lines
  (`-lan`, `-lan-data`, the one lookup order; `-thumbs-from`, passed into the window's session
  config). On the joined tree: gofmt clean, `CGO_ENABLED=0 go build ./...` ok, vet of the two commands
  and `internal/window` clean. Not run yet on it: any test.
- **Running now:** C's second look. Then C merged, then the full runs once.
- **22:36 C's second look is back** (`wt-b5-review-C-scratch/REVIEW-2.md`). **Verdict: all ten findings
  gone; merge-ready after two small points.** Re-probed, with a batched page model (up to six updates
  between two asks, catch-ups written newest first, edits and file saves between): matched a first load
  at every ask, at a full-size record and at a record of 6 entries. `refresh.go` still builds and reads
  what it did; markers reset one chat's page once, never in a loop. New, minor: N1 a deferred reset under
  an open post can fire late or cost a 30 s wait; N2 in a shared chat that only one account sees, the
  account's own channel posts are never drawn as its own. **One last small round by the same coder since
  22:36** (both points). A trial merge of f7dc5ec1 into `wip/b-viewer5` went through with no conflict.
  **Not covered by any test (said by the reviewer):** the page's own JS against the Go page model (only
  a browser run sees a slip there; the coder's browser run of the fix round did); the place kept after a
  reset in a real browser beyond one run.
- **Running now:** C's last small round. Then: C merged, the full runs once.
- **22:38 C's last small round handed back and read by me** (`wip/b-client` 901db489, pushed, copy clean:
  a deferred reset is cleared by another load and asks nothing meanwhile; in a shared chat one account
  sees, the stored flag decides "mine"). **C is complete: reviewed twice.**
- **22:38 ALL THREE JOINED: `wip/b-viewer5` fa39dd4d, pushed to `private`** (copy `wt-b-join`): W
  152a0bc2, T 174d25ad, C 901db489 (no conflict) and the main head 4daa0309 (Core's backup program; no
  conflict). gofmt clean, `CGO_ENABLED=0 go build ./...` ok, `go vet ./cmd/... ./internal/window
  ./internal/viewer` clean.
- **22:38 THE FULL RUNS STARTED, once, on fa39dd4d, out folder `runs-b9/`** (one background command of
  this session; `FFMPEG_PATH` set): `ix-tools/full-runs.sh wt-b-join runs-b9 "viewer window" "viewer
  window"` (whole Windows tests of both packages; the race detector on both, one container each), then
  `go test ./cmd/... -p 1` (`win-cmd.log`), then the race detector on `./cmd/tgarchive` and
  `./cmd/tgarchive-window` (`race-cmd.log`). Each log ends in "exit N"; `ended.txt` is written at the
  end. **If this session stops: read `runs-b9/*.log`; anything without its "exit 0" is run again by
  name; then write entry 20 in `MERGE-QUEUE.md`.**
- **23:03 THE FULL RUNS ENDED (22:38 to 22:57, `runs-b9/`), on fa39dd4d.** Whole Windows tests: `internal/viewer`
  ok 270 s, `internal/window` ok, the seven command packages ok; gofmt clean. Race detector: `internal/window`
  ok, `cmd/tgarchive` ok 98 s, `cmd/tgarchive-window` ok 41 s; **`internal/viewer`: 0 data race reports
  in 965 s, and one test FAILED, by its own set-up on Linux only** (`TestFFmpegOwnFolderFirst`: off Windows
  the program is named ffmpeg as its folder is, so its three places cannot exist at once). Fixed by me (the
  test skips off Windows with that reason; a test file only, a2408417); run by name on Windows (ok) and
  under the detector in a container (skipped as meant, the other ffmpeg tests ok). No second whole race run:
  nothing but a test file changed.
- **The main head moved to 27a7d4d meanwhile** (the copies' C9, the Queue page). Merged in (7e21e4aa; none
  of this track's files in it: the tested tree's files are unchanged, an empty diff). **On that tree
  `TestWallDependencies` failed: the catalogue now imports `internal/footage`** (it fails on the main head
  itself). Fixed on my branch (79bd84b0: the wall lets that one pure package in; its sub-packages stay
  out), board message 69 to the integrator and copies. **Running since 23:03: the whole Windows tests of
  `internal/viewer`, `internal/window` and the commands once more on 79bd84b0** (`runs-b9/win-viewer-2.log`,
  ends in "exit N"), because the catalogue moved under the viewer. Then entry 20.
- Usage was reset at 22:31 (message 65): "start no new piece" is lifted.
- **23:08 ENTRY 20 IS LISTED: `wip/b-viewer5` 79bd84b0, READY** (`MERGE-QUEUE.md`, the file's last entry; it
  holds the main head 27a7d4d). The last whole Windows run on 79bd84b0 (`runs-b9/win-viewer-2.log`):
  `internal/viewer` ok 285 s, `internal/window` ok, the seven command packages ok. Board: my row, the
  waiting list, message 70 to the integrator.
- **STATE FOR A TAKE-OVER (23:08):** nothing of this track is running (no coder, no reviewer, no run, no
  container). Everything is pushed: `wip/b-viewer5` 79bd84b0 (the entry), and the three piece branches
  it joins (`wip/b-winlan` 152a0bc2, `wip/b-thumbsbulk` 174d25ad, `wip/b-client` 901db489). Copies, all
  clean: `wt-b-join` (the entry), `wt-b-window`, `wt-b-faces`, `wt-b-viewer`. **Next, in order:** (1)
  when the integrator merges entry 20: build `tgarchive.exe` and `tgarchive-window.build.exe` from the
  main head into the owner's `bin` (keep the 3244f0d builds as `.bak`), add `-Lan` and `-ThumbsFrom` to
  `b\b-window.ps1` and try it as the owner runs it (full path, another folder, an invented catalogue),
  build the NAS image and save it as a file beside `nas-helper` with the owner's steps, then two lines
  on the owner's list; (2) the next piece: the old archive's earlier versions of edited messages
  (`internal/bringin`, `plan.go` "WANTED: message_version import"): read the bring-in and the old app's
  `ix_message_edits` first, brief one Opus coder (the PC is short of memory at night: measure first);
  (3) the compose box when Core lists its pieces 2 and 3 (board message 67 has the states); (4) this
  track's listed and unbuilt features onto the board's table (the integrator's message 69 f).
- **23:11 the next piece is with a coder: E, the old archive's earlier versions of edited messages brought
  in** (`BRIEF-B5-edits-bringin.md`; one Opus coder; copy `wt-b-faces`, branch `wip/b-edits` from the main
  head 8d9858ca; the PC before it: 8.5 GB free). Read by me first: the old app's table and where it is
  written (`wt-v12.32`: `ix_schema.go`, `ix_record.go` `ixWriteTx`: one row is the text and edit date a
  message had, with the time it was replaced), the catalogue's `message_version`, the bring-in's side-table
  pattern (`run2.go`, `catalog/imported.go` `SavePeerNames`). It adds one door to
  `internal/catalog/imported.go` (no schema step) and touches `internal/bringin` only. After its
  hand-back: my read, one independent review, its fixes, `internal/bringin` whole and the catalogue's
  named tests once (no race run: no goroutine), then an entry. **Then, mine, on the owner's data:** a fresh
  bring-in of the old archive into a new catalogue at the current schema (the old database opened
  read-only, counts only), so the chat page shows names and earlier versions; said to the owner first.
- The board's table has this track's listed and unbuilt features (23:12); the main head is 8d9858ca;
  entry 20 waits.
- **23:26 E handed back, and PARKED** (`wip/b-edits` 1edb307f, pushed, copy `wt-b-faces` clean; 13 files,
  about 1,050 lines, mostly tests; its report: one door `catalog.ImportMessageVersions`, a bring-in stage
  `edits` after `messages`, plan, facts and verify lines, `recorded_at` in milliseconds to `replaced_at`
  in seconds (checked where each is written), no change-log row; named tests and whole `internal/bringin`
  pass). **Counted by me at 23:26, read-only, on the owner's old database: `ix_message_edits` has 0 rows
  (64,990 messages carry an edit date).** The piece brings in nothing for this archive today. **My error:**
  I briefed it from the bring-in plan's "WANTED" line and never made the one count; the coder found the
  same in the docs (`oldschema.sql`, the scale report: 0 rows). Cost: one coder's run. **Decision:** no
  review, no listing; the branch stays pushed; it is taken up only if a later count is above 0. The chat
  page's "edited" mark shows for those 64,990 messages either way, with "No earlier version is kept".
  **Lesson:** before briefing anything that carries an old table, count that table on the real file
  (read-only, a number) and write the number into the brief.
- **Nothing of this track is running. Entry 20 waits for the integrator.** Next when it merges: the
  builds into the owner's `bin`, the starter's two flags, the NAS image as a file. A fresh bring-in of
  the old archive is still worth it for the names (the brought-in catalogue `old-archive-4` is at schema
  step 16 with `tg_peer_name` filled: check with one count before running anything).
- **23:26 counted, read-only, on the owner's brought-in catalogue `old-archive-4`:** 10,135 names kept
  (`tg_peer_name`), 584,075 messages, 7,117 distinct senders (all stored as numbers), 64,990 with an
  edit date, 401,916 outgoing, 5,874 service messages. **So no fresh bring-in is needed:** with entry 20's
  build the chat page shows names, "edited", sides and service lines on the catalogue as it is.

## 23:35 AN ERROR OF MINE ON THE OWNER'S VIEWER FOLDER, and where things stand (session B5)
- **Entry 20 is merged (2ea9b465, 23:14).** Done after it: the viewer and the window built from the main
  head 10a9e3a8 (`CGO_ENABLED=0`, `-trimpath`), the wall, schema, names and live tests by name on that
  head ok, the built viewer started on an invented `-real-rows` archive (7 chats with their lines and a
  live token, 40 posts with 40 names, a live ask answered) and stopped; **both builds placed in the
  owner's `bin` at 23:28** (`tgarchive.exe`, `tgarchive-window.build.exe`; the 3244f0d builds kept as
  `.3244f0d.bak`).
- **The error (23:29:20).** I added `-Lan`, `-ThumbsFrom` and a try-on-a-copy parameter to
  `b\b-window.ps1` and named that parameter `Root`. PowerShell's names ignore case: it was the script's
  own `$root`, which the script's first line then set to the real folder. My try, meant for a scratch
  copy with a stand-in program, therefore ran on the owner's real `tgarchive-b`: it took the new build,
  **started the real window program on the owner's catalogue `old-archive-4`** (with my empty scratch
  folder as the library), and **wrote my scratch folder into `library-folder.txt`**. The call's output
  went through a pipe to a filter and never came back to me (the hidden-start pipe hang of the memory
  note): I saw no line, no name and no picture; the window is on the owner's desktop only.
- **What it changed, checked without changing anything further:** the window program runs since
  23:29:20 (about 780 MB, with one mpv of 52 MB); `stats-last.json` and `window-stats.json` in
  `old-archive-4\viewer` now hold this run's numbers (the owner's of 20:18 are gone from the files; B4
  had read them: they are in this file above); `tgarchive-window.exe` is the new build (as it would be
  at the owner's next start); the thumbnail folder got no file and no failure mark in that time (the
  new health rule: an empty library marks nothing); `window.json` (the window's place) is untouched.
- **What I did about it:** stopped my own test's script (allowed) and its background task; **I was NOT
  allowed to stop the window program itself** (the permission check refused a forced stop; I did not go
  round it): **it is still open and is the owner's to close, or to let me close.** Removed
  `library-folder.txt` (it held only my scratch folder; the catalogue names no library folder, so the
  earlier value cannot be put back by me): **the owner's next start asks once for the library folder
  with its folder window.** The parameter is now `-TryIn` (it refuses a folder without `bin`), with a
  comment in the script saying why.
- **The corrected starter, tried as the owner runs it** (by its full path from another folder, on the
  scratch copy with the stand-in program, **with `LOCALAPPDATA` pointed at an empty scratch folder for
  the test's process so that the real folder could not be reached whatever the script did**, output to a
  file, not a pipe): plain: the stand-in got `-db -library -thumb-workers -thumb-ahead`; with `-Lan` and
  `-ThumbsFrom`: also `-lan -thumbs-from`; a thumbnail folder that is not there: "the second thumbnail
  folder (-ThumbsFrom) cannot be reached: nothing was started", exit 1; `-TryIn` on a folder without
  `bin`: refused, exit 1; no `-TryIn` and no real folder: "the window program is not built yet". After
  it: still exactly the one real window of 23:29:20, no remember file. **Not tried: the real window with
  `-Lan` (the owner's).**
- **Lessons:** in PowerShell a parameter must never share a name with a script variable (names ignore
  case); a try of a starter on a copy makes the real folder unreachable first (`LOCALAPPDATA` redirected
  for that process) and writes its output to a file; "it parses" proves nothing.
- **Not done, waiting for the owner's word:** the NAS thumbnail image as a file (building it downloads
  Alpine's base image and its ffmpeg package, about 215 MB: asked on the board's list, not done unasked).
- **STATE FOR A TAKE-OVER (23:35):** nothing of this track runs but that one window (not mine to stop). No
  coder, reviewer, run or container. Pushed and merged: entry 20. Parked: `wip/b-edits` 1edb307f. Next
  in my order (the integrator's message 73 c): the compose box and its states when Core lists its
  pieces 2 and 3 (messages 67 and 76 have the words); until then from the later list: the "what changed"
  feed is another track's; mine: `TestTimingUnderWriteLoad` without real time, the chat page seen in the
  native window by the self-check, the browser starter retired once the owner has used `-Lan`.
- **23:51 the owner, on the window my try opened: "I'll close it".** No session touches it. Item 30 of the
  owner's list says so.
- **23:55 the NAS thumbnail image is built and handed over** (the owner: "Yes, build the NAS image"). From the
  main head 10a9e3a8: the static Linux `tgarchive` (16.5 MB), `docker build` of `deploy/thumbs` (Alpine
  3.22, its ffmpeg 6.1.2; 215 MB as an image), **checked in a container locked down as the compose file
  locks it** (no network, read-only, all capabilities dropped, user 1000:10, 1 GB, 256 pids) on an
  invented library of 198 files written through a work list: `-limit 50` made 50 (median 0.039 s), the
  whole run made the other 148, a third run made none; 198 thumbnails, 0 marks, 0 temporary files; exit
  0 each. **Not exercised: a video frame by ffmpeg in the container** (the invented videos have posters).
  Saved with `docker save` as `nas-thumbs\tgarchive-thumbs-0.1.0.tar` in the project folder (59 MB as a
  file; `manifest.json` and `index.json` in it; its SHA-256 beside it), with `compose.yaml`, `README.md`
  and `STEPS-ON-THIS-PC.md` (the list command and the window's `-ThumbsFrom` start, full paths, from any
  folder; neither run by me on the real catalogue). The built program is removed from the copy
  (`wt-b-join` clean); the image `tgarchive-thumbs:0.1.0` stays in this PC's Docker (no cache pruned, no
  container left). Board: item 31.
- **Nothing of this track is running** (the window of 23:29 is the owner's to close). Next: the compose
  box when Core lists its pieces 2 and 3; the NAS run's numbers when the owner has them.

## 01:26 (11-16) THE NEXT PIECE: STAGED AND LOST FILES (roadmap D5); its coder is running
- **00:5x to 01:20:** the context was folded; the owner has the answer on the NAS image (item 31). The
  integrator's morning file says the owner closed the mistaken window at about 23:50 (no window or mpv left).
- **01:20 the rule on routine steps read** (CLAUDE.md, the board's top; the integrator's message): a Sonnet
  clerk or a script from here on. This entry's routine steps (the board row, the message, the morning rows,
  this entry, the commit) were applied by one script of mine in one call (`notes_0130.py`, scratch).
- **01:22 messages 79 to 87 read.** For this track: copies' 85 (the wall: its new catalogue files import
  nothing new; it runs the wall test on the combined tree), Core's 86 (the door for clicks is piece 3, not
  briefed until K9b is listed: the compose box still waits). Main head 698ee15d (schema step 21).
- **Chosen while the compose box waits** (a listed feature in my packages): the roadmap's row "Staged and
  lost files shown wrongly in six places" (D5, a known defect since 11-13, listed in the handoff log as
  `media.go` mediaInfo and handleFile, `maker.go` make, recheck and catchUp, `post.go`). Read by me on
  698ee15d: still open. Ten queries of the viewer join `file` without its `location`; only `bulk.go` (the
  NAS run) looks at it; the index calls a media saved when `file_id` is not 0. On the new accounts a
  staged file would be looked for in the library: not found, a failure mark, and 20 in a row trip the
  makers' health rule. Also read: `store.StagedName` (staging / two hex digits / the hash), `OpenSaved`
  and `openShared` (others may remove the file while it is open), the copier at its removal step (a
  failed removal is only counted; the sweep takes it later), `WantAgain` (sets `lost`), the wall test's
  lists. The staging folder is the collector's flag only: the catalogue does not record it, so the
  viewer gets a flag.
- **About 01:24 brief written: `BRIEF-B5-staged-lost.md`.** Six points: a lost file is not saved (through the
  incremental update too; no new field per media); a staged file is read from the staging folder
  (`Config.Staging`, `-staging` on both viewer commands; content names of validated hashes only; shared
  open; the copy finishing in between; never counted by the health rule; with no folder given: the
  preview and one fixed line); what the pages are told; the background walk opens no library file while
  a copy is due in `file_queue` (the lessons' rule), a person's ask always served; counts; a catalogue
  from before step 8. Bounds: the viewer and the two commands only; no schema step.
- **About 01:25 the PC measured** (by me: a single command): 6.1 GB free, CPU 71% (other tracks' runs).
  **About 01:25 an Opus coder started** in `wt-b-viewer` (clean; it cuts `wip/b-staged` from the main head):
  named tests only, no race detector, no Docker.
- **The morning file's viewer rows corrected** on my lines (entry 20 merged and in the owner's `bin`, the
  NAS image built, this piece with a coder). Board: my row, and a message to pages (the `-staging` flag
  for G6), Core (my reading of the removal step) and the integrator.

### STATE FOR A TAKE-OVER (11-16 01:26)
- **Running:** one Opus coder on `BRIEF-B5-staged-lost.md` in `wt-b-viewer`, branch `wip/b-staged`
  (pushed to `private` as it goes). Nothing else of this track runs. No container, no viewer, no window.
- **Committed and pushed:** everything up to entry 20 (merged, 2ea9b465). `wip/b-edits` 1edb307f parked.
- **Not committed anywhere:** nothing of mine (`b\b-window.ps1` and the folder `nas-thumbs` are not in git).
- **Next, in order:** (1) the coder's hand-back: read the risky part myself (the staged open and its
  fall-through to the library, the health rule's counters, the index's incremental update, the walk's
  pause); (2) one independent Opus review, read-only, probes in a scratch folder (`BRIEF-B5-review.md` is
  the model); (3) its fixes, a second look if the fix round rewrites the reviewed part; (4) the head
  merged in, then the full runs once through `ix-tools/full-runs.sh` (whole: `internal/viewer`,
  `cmd/tgarchive`, `cmd/tgarchive-window`; race: `internal/viewer`, about 16 minutes: the makers and the
  library change), started by a Sonnet clerk, the owner told in one line first; (5) an entry in
  `MERGE-QUEUE.md`. (6) Then the compose box, when Core has listed the client's pieces 2 and 3 (board
  messages 67, 76, 86 hold the states, words and the door's names).
- **The owner's, open:** the NAS measuring run (item 31); `-Lan` from the window after a password is set.

## 01:52 (11-16) S IS BUILT; MY READ; ITS INDEPENDENT REVIEW RUNS
- **01:50 the coder handed back:** `wip/b-staged` 3f4030ba (two commits on 698ee15d, pushed; the copy clean).
  All six points built. New `staging.go` (the staging folder as a root, content names only, the second
  look at the row when a staged file is not there), `makeJob` (staged, lost, held for later while a copy
  is due), the index's lost-linked set (normally empty: `WantAgain` clears `file_id` first), `-staging` on
  both commands, the fixed line "On this PC, not in the library yet", the Settings sentence, new counts.
  Its two differences: no per-system file (this Go's `os.Root` already opens with shared delete on
  Windows; a test removes a staged file while it is held open); the name rule pinned by reading the
  store's source in a test, not by importing it. Its own runs: 12 new named tests, the wall tests, 40
  related named tests, gofmt, vet, both builds: all pass. Not run by it: the link case (no right to make a
  link here), Linux, the pages in a browser, a real ffmpeg on a staged file.
- **My read (01:51 to 01:53):** `staging.go` whole, the makers' and the index's changed lines. No blocker.
  **Decided for the fix round already:** (1) the workers sleep while the library is unreachable or marked
  "files missing", staged work included: with the NAS off every new file is staged and gets no
  thumbnail, asked or not; staged files must go on there. (2) While copies are due the walk passes up
  to 4096 library files a turn and then idles 30 s: a staged file far down the order may wait long; the
  reviewer measures it at 600,000 media and the number decides whether the walk takes staged files
  from its hint instead. Left as they are: a staged file whose read fails is retried each round with no
  mark; "not there now" answers 404.
- **01:52 the PC measured** (a single command): 6.2 GB free, CPU 70%. **01:53 an independent Opus
  reviewer started** (read-only, probes in `wt-b5-review-S-scratch`, `BRIEF-B5-staged-review.md`): the
  index through the catalogue's own doors, the staged open against links and swaps, the copier's
  removal, the health rule, giving way to copies (with the numbers), the words, an old catalogue.
- **Take-over:** running: that reviewer only. Next: its findings and my two decisions into one fix round
  (the same coder can be resumed), a second look if the round rewrites the reviewed part, the head
  merged in, the full runs once by a Sonnet clerk (the owner told first), the entry.

## 01:55 (11-16) THE COMPOSE BOX IS WITH A CODER TOO (against a seam); message 90
- **01:53 Core's message 89 read:** my reading of the copier's removal is right (a held staged copy stays
  until the next start's sweep); K9b passed its third review look, its head merge met two conflicts, its
  full runs have not started; the door's names as built are in `click_api.go` on `wip/core-turn`.
- **Read by me for the compose box:** `DESIGN-CORE-client-actions.md` sections 3, 5, 6, 7; the merged
  ledger (`internal/catalog/schema_act.go`: `ActClick`, the state and "why" words, the indexes, `ChatClicks`
  and `Click`); `click_api.go` on `wip/core-turn` (`ClickInput`, the four entry points, the settings).
  **Decided:** the viewer's side is built now against a seam (`Config.Act`), nil in both commands, so
  nothing can send and the old archive's window is unchanged; the pass-through to Core's door (a dial to
  127.0.0.1, an exception in the wall test) is a later small piece of mine, after Core's piece 3.
- **01:55 an Opus coder started** in `wt-b-window` (clean; it cuts `wip/b-compose` from the main head
  5b29e28b or newer), brief `BRIEF-B5-compose.md`. PC measured first (a single command): 5.8 GB free,
  CPU 62%. Board: my row, message 90 (to Core: the seam, who writes the pass-through; to pages: the
  secret's place; to the integrator: the state).

### STATE FOR A TAKE-OVER (11-16 01:55)
- **Running, two agents of mine:** (1) the independent reviewer of S (`wip/b-staged` 3f4030ba, copy
  `wt-b-viewer`, read-only; writes `wt-b5-review-S-scratch/REVIEW.md`); (2) the compose coder
  (`wip/b-compose`, copy `wt-b-window`). The S coder has ended (it can be briefed again for the fix round).
- **Next for S:** the review's findings plus my two decisions (staged files go on while the library is
  away or "files missing"; the wait of a staged file far down the walk while copies are due, by the
  reviewer's number) into one fix brief; a second look if the round rewrites the reviewed part; merge the
  main head in; full runs once by a Sonnet clerk (`ix-tools/full-runs.sh`; whole: `internal/viewer`,
  `cmd/tgarchive`, `cmd/tgarchive-window`; race: `internal/viewer`), the owner told in one line first; the
  entry in `MERGE-QUEUE.md`.
- **Next for the compose box:** the hand-back states the seam as built: put it on the board for Core; my
  read (the routes' checks, the home-network refusal, nil draws nothing, no text in any printed line);
  an independent review with a security eye; fixes; it merges after S (both touch `chat.js`); then the
  pass-through when Core's routes exist.

## 02:17 (11-16) S: THE REVIEW IS BACK ("not ready"); ALL ACCEPTED; THE FIX ROUND RUNS
- **The independent review** (`wt-b5-review-S-scratch/REVIEW.md`, probes and two mutants beside it; the copy
  left clean). **Confirmed, the three that matter:** F1 `recheck` returns while a copy is due, so a "files
  missing" mark never clears while copies wait (days on a new account) and every thumbnail, asked ones
  included, waits; F2 the health sample is empty when the first four saved files of each eighth are
  staged, and then the mark never clears; F3 a staging folder absent at the start is never used until a
  restart. Smaller: F4 a catalogue stepped while the viewer runs; F5 a staged job looks in the second
  thumbnail folder on the NAS; F6 `New` accepts a staging folder that is the library or inside the data
  folder; F7 the open root holds the folder against a rename. **Sound by its probes:** the index through
  the catalogue's own doors (lost, claimed, saved again staged, copied: incremental each time, equal to a
  full read); the lost set bounded; junctions refused by the root itself; the copier's removal succeeds
  while a staged file is held open; staged results neither extend nor break the health streak; a
  person's ask is not held by copies. Tests it found leaning: none of the coder's 12 fails with F1 to F6
  present; "saved again" was done by SQL; two mutants pass (the same-file check, the two-digit folder).
- **Its numbers** (an invented catalogue grown to 600,000 media, 500,000 file rows, 100,000 queue rows):
  the full read's new pass 116 ms (median of 5) inside a full read of about 2 s; an update with nothing
  new 7 to 8 ms in all (the two new reads under 0.5 ms each); the copy-queue ask under 0.5 ms; **a staged
  file far down the walk while copies are due waits about 37 minutes with two workers** (computed), and
  up to 6 hours after a finished walk.
- **My decisions (`BRIEF-B5-staged-fixes.md`): all seven fixed as the review proposes** (F2 by eight
  bounded seeks over the file table), the leaning tests redone (through the doors, a junction case, the
  two mutants made to fail), **and two of mine:** D1 staged files go on while the library is unreachable
  or marked missing, through one predicate; D2 while background library jobs are held, and whenever the
  walk hands out nothing, the worker takes staged files from the hint in id order, one pass per idle
  round; the walk does not move and the 4,096 held-for-later list goes.
- **02:17 the same coder was sent the fix round** (its context holds the code). Not by a clerk: one
  message. The compose coder still runs.
- **Take-over:** running: the S coder in its fix round (`wt-b-viewer`), the compose coder (`wt-b-window`).
  After the fix round: a second independent look (the same reviewer can be sent the difference: D1 and D2
  rewrite `run` and the walk, the reviewed part), then the head merged in, the full runs, the entry.

## 02:20 (11-16) THE COMPOSE BOX IS BUILT; MY READ; ITS REVIEW RUNS; message 91
- **02:19 the compose coder handed back:** `wip/b-compose` 42a1df11 (three commits on 5b29e28b, pushed; the
  copy `wt-b-window` clean). New `internal/viewer/act.go` (1,437 lines), `act_test.go`, `web/js/act.js`; a
  few lines in `viewer.go`, `server.go`, `api.js`, `chat.js`, `app.css`. The seam `Config.Act` (five calls),
  a closed set of 29 words, six routes of class local (each refuses the home listener again itself), the
  tips of a chat's clicks read through `catalog.ChatClicks` on a second read-only handle opened only
  when a seam is set, the compose box, Reply, React, Forward, Edit, Delete, the account chooser (kept in
  the decisions file), "mark as read" bounded to once per chat in 30 s. Its runs: 14 `TestAct*`, the wall
  and home-network tests, vet, gofmt, the build: pass. It saw the page once in the browser pane on an
  invented archive with a fake seam (four rows drawn, a send, a reaction, a forward queued to the fake).
  Not seen in a browser: Edit, Delete and its question, the account chooser.
- **My read (02:19 to 02:20):** `handleActClick` whole and the answer and decode helpers: every check
  before the seam, refusals as words, the seam's error text never written. Not read by me: `act.js`
  (467 lines), the tips' drawing, the account choice. Left to the reviewer with a security eye
  (`BRIEF-B5-compose-review.md`, scratch `wt-b5-review-A-scratch`): who can make a click happen; one click
  one request (a double Enter is two messages once the door is live); the right target (a post that
  gathers messages; `actTgChat` against the catalogue's rule); refused never cut; the words and any way
  to script; cost; nil is nothing; the rows as drawn.
- **The seam written down for Core:** `SEAM-B5-viewer-act.md`; board message 91.
- **PC measured before the reviewer** (a single command): 6.4 GB free, CPU 62%.

### STATE FOR A TAKE-OVER (11-16 02:20)
- **Running, two agents of mine:** (1) the S coder in its fix round (`wip/b-staged`, copy `wt-b-viewer`,
  brief `BRIEF-B5-staged-fixes.md`, sent 02:17); (2) the compose reviewer (read-only on `wt-b-window`).
  If this session ends, their hand-backs are lost to it: the fix round's commits are on `private`
  (`wip/b-staged`, read `git log 3f4030ba..`), the review is the file `wt-b5-review-A-scratch/REVIEW.md`.
- **S, next:** read the fix round (the one predicate, `run`, the hint pass); a second independent look at
  `git diff 3f4030ba..HEAD` (the first review and its probes: `wt-b5-review-S-scratch`); merge the main
  head into the branch (a Sonnet clerk; clean or stop); full runs once by a Sonnet clerk with
  `ix-tools/full-runs.sh <copy> <out> "<whole>" "<race>"` (whole: `./internal/viewer ./cmd/tgarchive
  ./cmd/tgarchive-window`; race: `./internal/viewer`, about 16 minutes; the owner told in one line first);
  entry 21 in `MERGE-QUEUE.md` (the model: entry 20); after its merge the owner's `bin` gets new builds and
  the pages track is told the `-staging` flag is in.
- **Compose, next:** the review's findings into a fix brief for the same coder; the second look; it is
  listed after S is merged (merge the head in first: both touch `chat.js`); full runs: the viewer whole
  and its race run (routes and a clock under a lock). Then the pass-through, when Core's routes exist
  (`SEAM-B5-viewer-act.md`; the wall test gets one named exception; a security review of its own; the
  About page's sentence "makes no connections" needs new words then).
- **The owner's, open:** the NAS measuring run (item 31); `-Lan` from the window after a password is set.

## 02:35 (11-16) COMPOSE: THE REVIEW IS BACK; ALL DECIDED; ITS FIX ROUND RUNS; message 93
- **The independent review** (`wt-b5-review-A-scratch/REVIEW.md`, probes `probe_b5_test.go`; the copy left
  clean): **safe while the seam is nil** (no route, box, handle or table reachable; no way for a home
  device or another site's page to make a click: foreign origin, plain content type, no token and a
  rebinding host all refused). **Not ready for a live seam.** Confirmed: (1) the tips are picked from the
  newest 200 rows, so a not-known send drops off the page after 200 read marks; (4) the clicks' state is
  not refreshed away from the newest end; (5) an answer that never comes leaves the box dead; (6) an
  album with a deleted message cannot be deleted; (7) "own" and "channel" are the page's rules only; (8)
  hidden chats offered as forward targets, a forward's outcome only on the destination page; (9) a lone
  surrogate reaches the seam changed; (10) refusals of the automatic read mark shown to the owner; (12)
  any local program can act through the viewer (by design); (13) one bad row closes the box (by design).
  Plausible: (2) after "failed" the text stays and Send is live: a second Enter may be a second message;
  (3) a read mark from a topic view marks other topics read; (11) the reaction row.
- **My decisions (`BRIEF-B5-compose-fixes.md`): all accepted.** 1 by an incremental read per chat with the
  open tips kept (no window of rows; the row itself always through `catalog.Click`); 2 by a per-click key
  (`ActInput.Key`, a bounded memory of keys in the viewer, the door asked to de-duplicate), Send held
  until the state is read after a failure, deadlines (20 s server, 30 s page); 3 and 10 the read mark
  only from the unfiltered view and silent; 4 a timer while a tip is queued or sending; 6, 7, 9 refused
  before the seam; 8 hidden chats last and marked, a note with the destination; 11 the heart as U+2764;
  and a line under Edit that saving makes the message plain text.
- **02:34 the same coder was sent the fix round** (one message; three tries before it: the check that
  gates this session's tools gave no verdict for about ten minutes, nothing was lost). Board message
  93 to Core: the eight things the door must guarantee.
- **Take-over:** running: the S coder in its fix round (`wt-b-viewer`, since 02:17), the compose coder in
  its fix round (`wt-b-window`, since 02:34). After each: my read, a second independent look (the first
  reviewers' scratch folders hold the probes), then for S the head merged in, the full runs and the
  entry; compose is listed after S. `SEAM-B5-viewer-act.md` is to be brought up to date from the compose
  fix round's hand-back (`Key`, one new word).

## 02:39 (11-16) S: THE FIX ROUND IS BACK (7752e3bd); VERIFIED; THE SECOND LOOK RUNS
- **02:37 the S coder handed back its fix round:** one commit, `wip/b-staged` 7752e3bd, pushed. All seven
  findings and both decisions built. F2: the sample from the file table (eight seeks bounded at 4,096
  ids each way, then the oldest library row when all eight find none). F4: the writer asks the two schema
  facts at every update and reads in full once when one is new. D1: one rule `libraryHold` (unreachable,
  files missing, a copy due for background jobs only), asked by `nextOr` twice, `makeJob` and `run`; the
  workers no longer sleep 15 s; an asked library job stays queued (256, a minute unless asked again).
  D2: `stagedPass` (the hint in id order, one pass per 30 s), the hint kept by the index writer; the
  4,096 list and the restart are gone; the snapshot's `walk_held_for_copies` is now `walk_held_for_later`.
  Its runs: the brief's set 46 pass and 1 skip (64 s), its own and related named tests 66 pass (115 s),
  the same-file mutant fails as it must, vet, gofmt, both builds. Not run: the link cases (no right
  here), Linux, `run` with real workers, the whole package, the race detector.
- **The harness noted that its safety check was unavailable while this agent worked, so I verified what
  it did** (02:38): the copy clean on `wip/b-staged`; one new commit; 11 files, all in `internal/viewer`
  and the two commands' flag help; on `private` only `wip/b-staged` moved to it (the main head a5572535
  of 02:35 is the integrator's merge of the copies' step 22). The branch merges with that head with no
  conflict, and the head changed no viewer file since the branch was cut.
- **My read (02:36 to 02:38, by the read-only tools while my own commands were refused a verdict):**
  `libraryHold`, `stagedPass`, `urgentWhere`, `requeue`, `popAsked`, `nextOr`, `run`, `whileMissing`,
  `recheck`. No loop without a wait found: a held asked job is not handed out again, `requeue` wakes
  nobody, `whileMissing` and `recheck` keep their minute. Left for the second look: an ask's wake
  arriving again and again while held, the paced gap for pass jobs, the writer's new reads per update.
- **02:39 the first reviewer was sent the second look** (`git diff 3f4030ba..7752e3bd`; it writes
  `wt-b5-review-S-scratch/REVIEW-2.md`; one message, not a clerk).
- **Take-over:** running: the S reviewer (second look), the compose coder (fix round, `wt-b-window`). If
  `REVIEW-2.md` says ready: a Sonnet clerk merges the main head into `wip/b-staged` (clean by my check),
  runs gofmt and vet, and starts `ix-tools/full-runs.sh` (whole: `./internal/viewer ./cmd/tgarchive
  ./cmd/tgarchive-window`, about 6 minutes; race: `./internal/viewer` only, about 16 minutes: the makers'
  loop and locks changed); the owner is told that one line first; then entry 21.

## 02:52 (11-16) S: SECOND LOOK "READY FOR ITS FULL RUNS", A LAST SMALL ROUND RUNS; COMPOSE: FIX ROUND BACK, SECOND LOOK RUNS
- **About 02:49 the S reviewer's second look came back** (`wt-b5-review-S-scratch/REVIEW-2.md`): ready for
  its full runs. F1 to F6 gone by its probes run again, F7 said in the flag's help. D1 and D2 held with
  the real workers: no loop without a wait in six held states (2 to 6 reads of the queue's clock in 1.5
  to 2 s), 0 library reads while held, an asked library job kept and made within 3 s once the mark
  cleared, the paced gap holds for pass jobs. Numbers on its grown catalogue (600,000 media, 100,000
  staged): an update with nothing new 5.5 to 7.2 ms (before the round 7 to 8); the two schema asks 50
  microseconds; a whole staged pass 56 ms under the maker's lock once per 30 s. **New: N1 confirmed,
  small:** the health sample's MIN and MAX in one statement scan the file table (102 ms at 500,000
  rows). **N2 plausible, low:** `usable()` can open the staging folder inside a page request.
- **About 02:50 a last small round started** (a fresh Opus coder on an exact instruction, in
  `wt-b-viewer`): N1 as two subqueries with a test on the plan; N2: `usable()` only reads its flag and
  starts at most one background try; the unused `sleepCtx` deleted. No further review look: I read it.
- **02:50 the compose coder handed back its fix round:** `wip/b-compose` b1dc2f9f (one commit, pushed; the
  copy clean; verified by me: only `internal/viewer`, only its branch). All thirteen decided as briefed:
  the ledger read as rows come (`act_ledger.go`: 1,000 rows a poll, 200 open tips a chat and account, 64
  chats; the box closed with "reading" until the first walk is done), click keys (`act_keys.go`),
  deadlines, the read mark from the unfiltered view and silent, the timer away from the newest end,
  "channel", "not own", "no message", "bad character" before the seam, hidden chats last, the heart, the
  Edit line. 26 `TestAct*` pass. It saw in the browser pane on its invented archive: Send disabled during
  a slow POST and after "failed" until the state was read, the timeout line, Edit with its line, Delete
  with its question, the account chooser, the 3 s asks away from the newest end.
- **My read:** `act_keys.go` whole. One thing given to the reviewer: a key is bound to nothing but itself.
- **02:52 the compose reviewer was sent the second look** (`git diff 42a1df11..b1dc2f9f`; it writes
  `wt-b5-review-A-scratch/REVIEW-2.md`). `SEAM-B5-viewer-act.md` brought up to date.
- **Take-over:** running: the small-round coder (S, `wt-b-viewer`), the compose reviewer (second look).
  **S next:** read the small round's diff; then ONE Sonnet clerk: merge the main head
  (`private/claude/charming-feynman-vm2xia`) into `wip/b-staged` in `wt-b-viewer` (clean by my check at
  02:38; stop on any conflict), `gofmt -l`, `go vet` of the viewer and the two commands, set `FFMPEG_PATH`
  from PowerShell's `Get-Command ffmpeg`, `bash ix-tools/full-runs.sh wt-b-viewer runs-b10 "viewer"
  "viewer"` in the background, `go test ./cmd/tgarchive ./cmd/tgarchive-window`, push the branch, report
  the exit lines. The owner was told the plan at 02:39 and 02:50 (viewer whole about 5 minutes, the two
  commands, the race detector on the viewer only, about 16 minutes). Then entry 21 in `MERGE-QUEUE.md`.
  **Compose next:** the second look's findings; it is listed after S is merged.

## 02:57 (11-16) S: THE LAST SMALL ROUND IS BACK (1ba66dc9) AND READ; THE FULL RUNS ARE STARTED BY A SONNET CLERK
- **02:56 the small round handed back:** `wip/b-staged` 1ba66dc9 (three files of the viewer; pushed). N1:
  the bounds as two subqueries (`sampleBoundsQuery`; the plan is two searches, and a test fails on a
  scan). N2: `usable()` takes no lock and opens nothing; it starts at most one background try
  (`tryOpen`, a flag swapped once), which opens with no lock held and closes what it opened if the folder
  was shut meanwhile. `sleepCtx` deleted. Its runs: 4 new or changed tests pass, the set of 32 passes.
- **My read:** the changed lines of `staging.go`, whole. Right as written. Watched for in the race run:
  tests that set the staging clock or hooks on a running viewer.
- **02:57 ONE Sonnet clerk started** on an exact instruction: check the copy (1ba66dc9, clean), merge
  `private/claude/charming-feynman-vm2xia` into the branch (stop on a conflict), gofmt, vet, the build,
  push `wip/b-staged`, measure the PC, set `FFMPEG_PATH`, `ix-tools/full-runs.sh wt-b-viewer runs-b10
  "viewer" "viewer"` in the background, the two commands' tests beside it, then report the exit lines
  and the counts. The owner was told the plan in one line before (viewer whole about 5 minutes, the two
  commands, the race detector on the viewer only, about 16 minutes: the workers' loop changed and the
  round adds a goroutine).
- **Take-over:** running: that clerk (logs: `runs-b10`; `started.txt`, `ended.txt`, `win-viewer.log`,
  `race-viewer.log`, `win-cmd.log`, each ending in "exit N"), the compose reviewer (second look). When
  the runs are clean: entry 21 in `MERGE-QUEUE.md` (the model: entry 20; reviews: `wt-b5-review-S-scratch`
  `REVIEW.md` and `REVIEW-2.md`; what was not tested: Linux, the link cases, the pages in a browser, a
  real ffmpeg or mpv on a staged file, the real collector's staging folder), the board row and a message
  to the integrator. A failure: read the named test, decide, one small round, the failed run again.

## 03:00 (11-16) COMPOSE: THE SECOND LOOK IS BACK (9 new findings); A SECOND FIX ROUND RUNS; message 95
- **The second look** (`wt-b5-review-A-scratch/REVIEW-2.md`, probes `probe2_b5_test.go`): **ready to be listed
  behind a nil seam; not ready for a live seam.** Of the first thirteen: 3, 6 (delete, edit, reaction), 7,
  9, 10 gone; 1, 2, 4, 5 gone for the case found with new gaps; 12 and 13 stay as decided. **New:** (1)
  confirmed: a click key is tied to nothing (the same key with another chat, text or kind is answered
  with the first click's number, no seam call: the page would say "sent" for something never sent); (2)
  the "same text" rule can empty the box for a click never queued; (3) a forward, delete or reaction gets
  a new key on every try; (4) confirmed: open tips the first walk leaves out never come back; (5) with
  50 older open tips the click just made is not drawn; (6) confirmed: the seam's deadlines add up past
  the page's 30 s, and the page's abort cancels the seam's call; (7) "reading" can stick away from the
  newest end; (8) a forward of a partly deleted album goes without saying so; (9) "bad character" also
  refuses a real U+FFFD. Numbers: a first read of 10,000 rows takes 11 asks of about 100 ms; steady
  state with no open tip under 1 ms, with 200 open tips 14 to 21 ms.
- **My decisions (`BRIEF-B5-compose-fixes-2.md`): all nine accepted.** The key carries a hash of the
  click's resolved form; the state read says whether the held key got a number (no match by text);
  forward, delete and reaction keep their key; the chat walked again when dropped tips have room; the
  10 newest open tips always drawn; one 20 s deadline per request and the queue on a context the page's
  leaving does not cancel; the timer also while "reading"; a forward of a post with a deleted message
  refused with a new word; the line names U+FFFD or NUL.
- **03:00 a fresh Opus coder started** on it in `wt-b-window` (the first coder's context is over half a
  million tokens: a fresh one on a written brief is cheaper). **No third independent look is planned:**
  I read this round; the piece is listed behind a nil seam, and the live path gets its own security
  review with the pass-through. Say so in its entry.
- Board message 95 to Core: the key tied to the content, the three cases where only the door's memory
  guards, the state call's speed.
- **Take-over:** running: the clerk with S's full runs (`runs-b10`), the compose coder (second fix
  round). Compose after it: my read of the round (the key's hash, the context that outlives the page,
  the redraw rule), the head merged in after S is merged, full runs (the viewer whole and its race run),
  an entry that says "behind a nil seam; a live seam needs the pass-through and its review".

## 03:20 (11-16) COMPOSE: THE SECOND FIX ROUND IS BACK (f361d35c) AND READ; S: TWO OF THREE RUNS CLEAN, THE RACE RUN STILL GOES
- **03:19 the compose coder handed back:** `wip/b-compose` f361d35c (one commit on b1dc2f9f, pushed; the copy
  clean; only `internal/viewer`). All nine done: a key carries a SHA-256 of the click's resolved form and
  a known or busy key with another form is refused; the state route takes `?key=` and says whether that
  key got a number (the match by text is gone); forward, delete and reaction keep their key and read the
  state before the same button sends again; the chat is walked again when dropped tips have room; the 10
  newest open tips are drawn and kept; one 20 s deadline per request, the queue on a context the page's
  leaving does not cancel; the timer also while "reading"; a forward of a post with a deleted message
  refused ("part deleted"); the characters named (33 words now). 34 `TestAct*` pass, the wall, the
  home-network and the page-script tests pass. Seen by it in the browser pane on its invented archive:
  after "failed" with nothing queued the text stays and the next Send goes out under the same key; with
  the click queued the box empties once the key has its number (the seam called once); a forward tried
  again goes out under the same key; "reading" ends by the box's own timer away from the newest end.
- **My read:** `act_keys.go` whole (the hash covers every field; a busy or known key with another form
  is refused before the seam; the queue's context outlives the page and has the deadline). Not read by
  me: `act.js` (the hold, the per-button keys), `act_ledger.go` (the walk again). **No third independent
  look** (decided 03:00): the entry must say so, and that a live seam needs the pass-through and its own
  security review, which covers this path end to end.
- **Its doubts, kept for the entry:** with more than 200 open tips of one account the week is walked again
  each time a kept tip finishes (about 11 asks of 115 ms at 10,000 rows); a delete tried again after more
  deletions reaches the door with the same key and a shorter list; a text changed during a hold.
- **`SEAM-B5-viewer-act.md` brought up to date** (the key tied to the content, the deadlines, `?key=`, 33
  words).
- **S's full runs at 03:20 (the clerk has not reported yet; read by me from `runs-b10`):** started 02:57;
  `win-viewer.log` ends "exit 0", `win-cmd.log` ends "exit 0"; the race run of the viewer still goes.
- **Take-over:** running: the clerk (waiting for the race run; its report gives the counts). **S when the
  race log ends "exit 0" with no "WARNING: DATA RACE" and no "--- FAIL":** entry 21 in `MERGE-QUEUE.md`
  (the head is the clerk's merge commit on `wip/b-staged`; model: entry 20), the board row, a message to
  the integrator. **Compose after S is merged:** a Sonnet clerk merges the main head into `wip/b-compose`
  (both touch `chat.js` by a few lines; stop on a conflict and I resolve), full runs (the viewer whole,
  its race run: the routes share maps under a lock and a queue outlives its request), then its entry.

## 03:41 (11-16) S: THE FULL RUNS ARE CLEAN; ENTRY 21 IS LISTED; THIS SESSION IS READY FOR A TAKE-OVER; message 96
- **03:39 the clerk reported** (`runs-b10`, 02:57 to 03:39): the main head merged into `wip/b-staged` with no
  conflict (new head 15763352, pushed), gofmt, vet and the build clean; whole `internal/viewer` on Windows
  ok 385.3 s; `cmd/tgarchive` ok 8.5 s, `cmd/tgarchive-window` ok 2.2 s; the race detector on
  `internal/viewer` ok 2,490.2 s, 0 data races, 0 failures. Two containers still ran: not this track's
  (Core's race run and one that is not the project's), checked by name, not touched.
- **Entry 21 written in `MERGE-QUEUE.md`** (the last entry; READY). Board: my row (READY FOR A TAKE-OVER),
  message 96 to the integrator and pages.
- **Routine steps of this night, as the rule asks:** the merge of the head, gofmt, vet, the build, the push
  and the full runs of S by ONE Sonnet clerk on an exact instruction; every notes edit and commit since
  01:26 by one script call each (a heredoc); measuring the PC and single checks by me (a single command).

### STATE FOR A TAKE-OVER (11-16 03:41, session B5, the context full)
- **Running:** nothing of this track. No agent, no container, no viewer or window. The copies `wt-b-viewer`
  (`wip/b-staged` 15763352), `wt-b-window` (`wip/b-compose` f361d35c), `wt-b-faces` (`wip/b-edits`, parked),
  `wt-b-join` (a detached old main head) are clean.
- **Committed and pushed:** `wip/b-staged` 15763352 (entry 21, READY, waiting for the integrator),
  `wip/b-compose` f361d35c (not listed yet). The notes are committed on `notes`.
- **Next, in order:**
  1. **When entry 21 is merged:** builds of the two programs from the main head into the owner's `bin`
     (how: the entry of 11-15 23:28 in this file; [name removed] test first on an invented `-real-rows` archive;
     the window takes `tgarchive-window.build.exe` at its next start; never start the owner's window:
     memory `starter-try-on-a-copy`). The old archive needs no `-staging`.
  2. **The compose box** (`BRIEF-B5-compose.md`, `-fixes.md`, `-fixes-2.md`; reviews
     `wt-b5-review-A-scratch/REVIEW.md` and `REVIEW-2.md`): ONE Sonnet clerk merges the main head (with
     entry 21) into `wip/b-compose` in `wt-b-window` (a few lines of `chat.js`, `media.go`, `viewer.go`,
     `server.go` meet: on a conflict the clerk stops and the session resolves), then the full runs once
     (`ix-tools/full-runs.sh wt-b-window runs-b11 "viewer" "viewer"`: whole about 6.5 minutes, race about
     40 minutes; the owner told in one line first), then its entry: **"behind a nil seam"**; say in it:
     the second look's nine findings were fixed in a round read by the session only (`act_keys.go` read;
     `act.js` and `act_ledger.go` of that round not read), no third independent look; a live seam needs
     Core's routes, the pass-through and its own security review; the coder's three doubts (the walk
     again with over 200 open tips; a delete tried again after more deletions; a text changed during a
     hold); Edit, Delete and the chooser were seen in a browser pane only on an invented archive.
  3. **The pass-through** (when Core lists piece 3, its routes): one file in `internal/viewer`, a client
     to 127.0.0.1 only, the secret from the program's folder (pages names its place with G6), the wall
     test's one named exception, the About page's sentence "makes no connections" reworded, an
     independent security review. What the door must guarantee: `SEAM-B5-viewer-act.md` and board
     messages 91, 93, 95. Watch for Core's answers to them.
  4. Smaller, not started: `TestTimingUnderWriteLoad` without real time; the chat page seen in the native
     window by the self-check; retire the browser starter on the board once the owner has used `-Lan`.
- **The owner's, open:** the NAS thumbnail measuring run (the owner's list item 31, folder `nas-thumbs`);
  `-Lan` from the window after a password is set in Settings.
- **Lessons of this night (my reading):** each first review found confirmed defects in a piece whose own
  tests all passed, and each second look of a fix round found new ones (S: one small; compose: nine, one
  confirmed that would have told the owner "sent" for nothing sent): keep the second look for any round
  that rewrites the reviewed part. A fresh Opus coder on a written brief was cheaper for a later fix
  round than waking the first coder's half-million-token context. Times: take `date` in the same call as
  the text that states them (I wrote two start times a few minutes late again and corrected them).

## The board row's state before 11-16 06:58 (moved here by session B6 to shorten the board)
**READY FOR A TAKE-OVER (11-16 03:41, B5: the context is full; nothing of this track runs; take over from the last "STATE FOR A TAKE-OVER" of `SESSION-B-PROGRESS.md`). ENTRY 21 IS LISTED, READY: `wip/b-staged` 15763352 (staged and lost files; two independent reviews; whole viewer on Windows and its race run clean). THE COMPOSE BOX IS BUILT AND REVIEWED TWICE (`wip/b-compose` f361d35c) AND WAITS FOR ENTRY 21'S MERGE: then the head merged in, its full runs, its entry, "behind a nil seam"; the seam for Core: `SEAM-B5-viewer-act.md`.** Before that: **11-16 01:26 (B5): ENTRY 20 IS MERGED (2ea9b465) AND IN THE OWNER'S `bin` (builds of 10a9e3a8, 11-15 23:28); the NAS thumbnail image is built and handed over (folder `nas-thumbs`, the owner's list item 31); the window my mistake opened was closed by the owner. REVIEWED ("not ready": 7 findings, 3 that matter, all accepted) FIXED (`wip/b-staged` 7752e3bd, pushed 02:37; my read of the new worker loop found no blocker) AND LOOKED AT A SECOND TIME ("ready for its full runs"; one small defect and one low risk fixed in a last small round, 1ba66dc9, read by me; **THE FULL RUNS STARTED 02:57 by a Sonnet clerk** after merging the main head in: the viewer whole on Windows, the two commands, the race detector on the viewer only; logs in `runs-b10`); the second look ran from 02:39 (the fix round ran from 02:17: `BRIEF-B5-staged-fixes.md`; the review: `wt-b5-review-S-scratch/REVIEW.md`); before that: with its reviewer (since 01:53; the coder handed back 01:50: `wip/b-staged` 3f4030ba, pushed; my read found no blocker; review brief `BRIEF-B5-staged-review.md`): the roadmap's known defect "staged and lost files shown wrongly" (D5): `wip/b-staged` in `wt-b-viewer`, brief `BRIEF-B5-staged-lost.md` (a lost file is not saved; a staged file is read from the staging folder, flag `-staging`; the background walk opens no library file while a copy is due). After its hand-back: my read, one independent review, fixes, full runs once (the viewer whole and its race run), then an entry. ALSO BUILT, REVIEWED ("safe while the seam is nil; not ready for a live seam": 13 findings, all decided) FIXED (`wip/b-compose` b1dc2f9f, pushed 02:50) AND LOOKED AT A SECOND TIME ("ready to be listed behind a nil seam; not ready for a live seam": 9 new findings, all accepted and fixed: `wip/b-compose` f361d35c, pushed 03:19, the round read by me, no third review look; **it waits for the staged-files piece to be merged**, then the head merged in, its full runs and its entry, listed "behind a nil seam"; `BRIEF-B5-compose-fixes-2.md`); the second look ran from 02:52 (the seam file is up to date: `Key`, two words, a 20 s deadline; the fix round ran from 02:35: `BRIEF-B5-compose-fixes.md`; the review: `wt-b5-review-A-scratch/REVIEW.md`; before: with its reviewer since 02:20; `wip/b-compose` 42a1df11, pushed; the seam as built is in `SEAM-B5-viewer-act.md`): the compose box, the buttons and a click's place in the conversation, built against a seam (`wip/b-compose` in `wt-b-window`, brief `BRIEF-B5-compose.md`; nothing in it can send; the pass-through to Core's door is a later small piece: message 90). Parked: `wip/b-edits` (the old archive keeps no earlier versions: 0 rows).** Before that: **11-15 23:09 (B5): LISTED: `wip/b-viewer5` 79bd84b0, `MERGE-QUEUE.md` entry 20, READY (it holds 27a7d4d).** Three pieces in one branch, each with an independent review and a second independent look at its fix round, every finding fixed or decided: (W) the window as the only viewer (`-lan` in `tgarchive-window`, fixed words on every console line, one lookup order for ffmpeg and mpv, a minimised window goes on playing); (T) every thumbnail made in the background (`tgarchive thumbs`, `-thumbs-from`, `deploy/thumbs/` for the NAS; the makers' library-health rule changed for the viewer too); (C) a chat as a client shows it, reading only (live while open, edited with earlier versions, names from `tg_peer_name`, mine and theirs where known, the Chats list's newest line). Full runs once (`runs-b9/`): whole Windows tests of `internal/viewer`, `internal/window` and the commands ok; the race detector on `internal/viewer` (0 data races), `internal/window` and the two commands; after two test-file fixes and the main head merged in, the whole Windows tests once more on 79bd84b0, ok. It also mends `TestWallDependencies`, which fails on the main head 27a7d4d (message 69). No schema step, no `go.mod` change, no other track's package. **After its merge, mine:** the builds into the owner's `bin`, the starter's `-Lan` and `-ThumbsFrom`, the NAS image as a file with the owner's steps; then two lines for the owner's list (other devices at home from the window; the thumbnail run: this PC, or the measuring run of 200 on the NAS first). **Next pieces in my order (usage is back, message 65), one coder at a time while the PC is short of memory:** the old archive's earlier versions of edited messages brought in (`internal/bringin`: the chat page then shows them); the compose box and its states when Core's pieces 2 and 3 are listed (message 67, read); a plain bar under the video only if the owner asks. Not tested by anyone: a real phone, a real pointer, the NAS container. Nothing of this track is running. Earlier: **11-15 22:18 (B5): entry 19 is merged (thank you); messages 56 to 64 read 22:18 (62 late). Three pieces in hand, nothing new started: W, the window as the only viewer (`wip/b-winlan` 152a0bc2): COMPLETE, reviewed twice ("may merge"); T, every thumbnail in the background (`wip/b-thumbsbulk` c38196ff): fixed after a review of twelve findings, its second look running; C, the chat page as a client shows it, reading only (`wip/b-client`): its fix round running after a review of ten findings (the owner asked for it a second time, message 60), then one second look. Then the three are joined on the main head, the full runs go once (whole `internal/viewer`, `internal/window`, the commands; the race detector on both packages) and ONE entry is listed (entry 20). State for a take-over: the last block of `SESSION-B-PROGRESS.md`.** Earlier: **11-15 21:17 (B5): TAKEN OVER; the disk matches B4's block. Still to merge, unchanged: `wip/b-window` 3244f0d, `MERGE-QUEUE.md` entry 19.** Read by me first, in full: the board with messages 37 to 54, the take-over block, `LESSONS-viewer-ix12.32.md`, `LESSONS.md`, TRIED-BEFORE 8, 9, 10, 15, 16, FEATURES 7, 9 and section 12 rounds 7, 15, 16, and the code each piece touches. The owner has not used the window since the build of 3244f0d was placed (the two counts files are of 20:18): nothing new to read there. **Three Opus coders run side by side since 21:17, each in its own copy, each cut from 3244f0d, none listed yet:** (T) **every thumbnail made in the background** (the owner, 20:25): `BRIEF-B5-thumbs-bulk.md`, `wip/b-thumbsbulk` in `wt-b-faces`: a headless `tgarchive thumbs` on the viewer's own makers, a work list for a machine without the catalogue, a second read-only thumbnail folder for the viewer, and deploy files for a container on the NAS in a new folder `archiver/deploy/thumbs/` (integrator: message 55); (W) **the window as the only viewer** (the owner, 20:25): `BRIEF-B5-window-only.md`, `wip/b-winlan` in `wt-b-window`: `-lan` in `tgarchive-window`, the viewer's own sentence when the archive cannot be opened, ffmpeg looked for in the program's own folder first (message 40c); (C) **the chat page as a client shows it, reading only** (message 48): `BRIEF-B5-client-reading.md`, `wip/b-client` in `wt-b-viewer`: live while open, "edited" with earlier versions, mine and theirs, the Chats list's line per chat; the viewer still sends nothing. After each hand-back: my read of the risky part, one independent review (W's security-minded), its fixes, the three joined on the main head, the full runs once, then one entry. Nothing of this track runs against Telegram or on the owner's archive. **For the owner, unchanged:** `C:\Users\trabi\Claude\Projects\Telegram\b\b-window.cmd` is the way in (the build of 3244f0d). **Asked of the owner, no answer yet (B4, 20:18):** mpv's own bar as it is now (hidden until the pointer moves), or a plain bar of the app's own under the video. Progress: the last block of `SESSION-B-PROGRESS.md` ("Session B5"). Earlier: **11-15 20:45 (B4): READY FOR A TAKE-OVER (this session is full; its state is the last block of `SESSION-B-PROGRESS.md`, "STATE FOR A TAKE-OVER"). To merge: `wip/b-window` 3244f0d, `MERGE-QUEUE.md` entry 19** (on top of the merged entry 18; holds 2625aa0; 18 files in `internal/viewer` and `internal/window`): mpv's bar hides again (the owner found the always-shown one "ugly and busy"); a play ended by the close is not a failure; a listing queues no thumbnails (4,786 were asked in a 24 s drag); the read-only schema door (Core's messages 37, 39). Full runs once on 3244f0d: whole tests and the race detector on both packages, the commands, all ok. Nothing of this track is running. **For the owner now:** `C:\Users\trabi\Claude\Projects\Telegram\b\b-window.cmd` takes the build of 3244f0d by itself at its next start. **The owner's directions for the next session (message 51):** the window becomes the only viewer and the browser starter is retired once the window can serve phones at home; thumbnails are to be made in bulk in the background, by the viewer or by a program on the NAS. **Next for this track:** the client's reading side (message 48), the two directions above, a plain bar of the app's own under the video if the owner wants it (asked, no answer yet). Earlier today: **11-15 20:10 (B4). To merge: `wip/b-window`, now at 1aa9ac4 (entry 18, its last block: merge this instead of 65d20f2; it holds 2c5765f).** The owner used the window on the old archive at 19:42: "It works"; five videos from the NAS, mpv's first picture after 260 ms at the median; mpv's controls answer the mouse. Two complaints, both fixed in 1aa9ac4: after a drag to another month the tiles on screen got no thumbnails (a second ask now moves a waiting thumbnail to the front; a tile asks only when it stays; a tile seen again asks within a second), and mpv's bar hid on one video (it is always shown now, under the picture). Full runs once on 1aa9ac4: whole tests of `internal/viewer`, `internal/window` and the commands; the race detector on both packages: all ok. **For the owner now:** close the window and double-click `b\b-window.cmd` again (or `b\b-viewer.cmd`): both take the new build by themselves. **Open:** why the bar hid on that one video (the window now counts plays where mpv's size differs from its window); the first stall's cause (no stall in the last two starts; the numbers file now survives a closed window and names the step at the next one); `TestTimingUnderWriteLoad` without real time; a JPEG refusal in the frame command on one invented RealMedia clip; the pages as another device sees them. Earlier: **11-15 19:30 (B4). Entry 17 is merged (0697f15). To merge: `wip/b-window` 65d20f2, `MERGE-QUEUE.md` entry 18: the native window with mpv** (new: `internal/window`, `cmd/tgarchive-window`, the one pinned requirement `github.com/jchv/go-webview2` you agreed to in message 28, with its licences and `go.sum` lines in the entry; changed: `internal/viewer` only; it holds fa8c011). Two independent security-minded looks, every finding fixed; full runs once (whole tests of `internal/window`, `internal/viewer` and the commands; the race detector on `internal/window`, which found one race in a test: fixed and run again, ok). **For the owner now:** double-click `b\b-window.cmd` in the project folder (close the browser viewer first): the same pages in a window of their own; a saved video plays in mpv as it is, with free seeking, and a click on the picture pauses it. If anything is off, `b\b-viewer.cmd` is unchanged. **The first things only the owner can see:** mpv's seek bar and buttons with the mouse; the first video from the NAS; the arrow keys while a video plays (they seek; previous and next are the buttons). **Open:** the first stall's cause (the numbers file now survives a closed window: the next slow start names the step); `TestTimingUnderWriteLoad` to be rewritten without real time; a JPEG refusal in the frame command on one invented RealMedia clip; the pages as another device sees them. Earlier: **11-15 19:00 (B4). To merge: one branch, `wip/b-once` b2dfe5b, `MERGE-QUEUE.md` entry 17** (on top of the merged entry 16; holds 9dd5a21; only `internal/viewer` and `cmd/tgarchive/viewer.go`): in the whole library each file and its exact copies get one tile, a chat's own view shows every post (the owner, 17:02); a click on the main video plays or pauses it (the owner, 17:21, message 31); the numbers file is written when the viewer's console window is closed and a few seconds after a play. Two independent looks (the first design could hide files and was replaced; the second found none missing over a large random [name removed]), every finding fixed; **full runs once on b2dfe5b: whole tests 267 s, the race detector on `internal/viewer` 690 s, `cmd/tgarchive`, all ok.** **For the owner now:** close the viewer and double-click `b\b-viewer.cmd`: it takes the build of b2dfe5b by itself. New: one tile per file in the whole library (a chip shows every post again; Settings has the switch); a click on the video plays and pauses; closing the console window now leaves the numbers file. **The native window (`wip/b-window`, copy `wt-b-window`):** built in two stages, two independent looks (the second found the picture cap could hang mpv, and that a page script could name any program as the player: both in its last round, running now, which also joins `wip/b-once`); then its full runs (`internal/window` whole and under the race detector, `internal/viewer` whole), its entry with the `go.mod` lines, and the starter `b\b-window.cmd` (drafted, untried). **Open:** the first stall's cause (the next slow start's numbers file will name the step, now that the file survives a closed window); nothing of today's pages was seen drawn in a browser by a session; mpv's own seek bar with a real mouse; `TestTimingUnderWriteLoad` to be rewritten without real time; a JPEG refusal in the frame command on one invented RealMedia clip. Earlier: **11-15 17:28 (B4). Entry 16 is merged (4f0fe17). Being built on top, branch `wip/b-once` (copy `wt-b-faces`), to be entry 17:** (1) in the whole library each file gets one tile, a chat's own view shows every post (the owner, 17:02; built, handed back, one required fix: no file may vanish when its earliest post is not downloaded); (2) **a click on the main video starts and pauses it (the owner, 17:21, message 31)**, in the pages here and for mpv's picture in the window's stage B; (3) the numbers file: the owner's use of d4269cc left no `stats-last.json` (the first write comes after a full minute and closing the console window ends the program without one): the viewer now ends cleanly on the console's close signal and writes a few seconds after a person's request. **The native window:** stage A handed back and read (`wip/b-window` d1c9343: the shell, mpv kept warm, 18 of 18 crafted files harmless, the one `go.mod` requirement); stage B running (the pages hand video to mpv). Then its independent review, full runs and entry. Earlier: **11-15 17:00 (B4). To merge: one branch, `wip/b-viewer4` d4269cc, `MERGE-QUEUE.md` entry 16** (the library's opens; files not downloaded in the library; conversions measured; crafted files and ffmpeg; five page fixes; two independent reviews, every finding fixed; full runs once on d4269cc: whole tests 212 s and the race detector on `internal/viewer` 515 s, both ok; the main head a0baa06 is merged in; only `internal/viewer` touched). **For the owner now:** close the viewer and double-click `b\b-viewer.cmd`: it takes the build of d4269cc by itself. New: files that are not downloaded show their saved copy or are left out (the chip shows them again; Settings has the choice); "Opening the file from the library…" when a video is slow to start; under a converted video a line with "Open in the player" (full quality, free seeking: it started this PC's default player in a test). After the next slow start, `stats-last.json` says which step of the open stalled. **Running:** the native window's build, stage A (`BRIEF-B4-window.md`, copy `wt-b-window`, branch `wip/b-window`); stage B (the pages hand video to mpv) is cut from `wip/b-viewer4` when stage A is handed back. **Open:** the stall's cause (measured at the next one); the new pages were not seen drawn in a browser; one frame-command doubt (a JPEG refusal on an invented RealMedia clip); `TestTimingUnderWriteLoad` to be rewritten without real time. Earlier today: **11-15 15:48 (B4): the slow first video is read from the viewer's own numbers: it is the OPEN of a file on the NAS in the viewer's first minute (one request 18.1 s to its first byte, an open of 23.6 s; 494 later opens none over 0.2 s), not the read, the video's index or the catalogue. Running: one Opus coder, `BRIEF-B4-open.md`, copy `wt-b-viewer`, branch `wip/b-open` from f0e3f0c (the open's steps timed apart; no network call under the library's lock; a person's open before the makers'; the page says "Opening…" at once). Then my read, one independent review, the full runs once (whole tests and the race detector on `internal/viewer`: the library's lock changes), `MERGE-QUEUE.md`. **Added 15:52, the owner to this session (15:49): "seeing not downloaded files in the library isn't useful. They should be hidden, or they should link to their known duplicates." Being built: a second Opus coder, `BRIEF-B4-notsaved.md`, copy `wt-b-faces`, branch `wip/b-notsaved` from f0e3f0c (a remembered rule: a file that is not downloaded shows its saved copy where one is known, and is left out otherwise; a chip with the count and a way back).** Both branches go to the integrator as one (`wip/b-viewer4`), after one independent review and the full runs once. Beside it: the native window's spike is planned (`PLAN-native-window.md`, last section; `BRIEF-B4-window-spike.md`) and **runs since 16:10** (the owner said yes to both downloads at 16:08; a third Opus coder, copy `wt-b-window`, branch `wip/b-window-spike`, a nested module: the app's `go.mod` untouched; it writes `SPIKE-native-window.md`); the build after it waits for your word on `go.mod` (message 28). **16:40: both pieces are built, each independently reviewed, each in its fix round** (`wip/b-open`: `REVIEW-B4-open.md`, 4 confirmed and 4 plausible, the largest a dead library handle after a network blip marking files that were never missing; `wip/b-notsaved`: `REVIEW-B4-notsaved.md`, 4 confirmed, tiles judged by the whole post instead of what they show). **The spike is done (`SPIKE-native-window.md`): the binding works without cgo, mpv's window stayed over the page 23 times of 23, a start takes 27 to 42 ms with one mpv kept; the build runs since 16:40 (`BRIEF-B4-window.md`, stage A: `internal/window`, `cmd/tgarchive-window`, the one requirement `github.com/jchv/go-webview2 v0.0.0-20260205173254-56598839c808`, branch `wip/b-window`, copy `wt-b-window`).** Looked at in a browser on invented data: the hide button, the Chats list's badge, the Settings lines (message 28c). Progress: the last block of `SESSION-B-PROGRESS.md`.** Earlier state (session B3, all of it merged since as ae87e10): 11-15 13:32 (session B3, **wrapping up: a new session takes over from the last block of `SESSION-B-PROGRESS.md`**). **To merge: one branch, `wip/b-viewer3` 16376c9, `MERGE-QUEUE.md` entry 15** (it replaces entries 13 and 14; the main head 6f17c7f is merged in; a race run of `internal/viewer` is due). Already merged by the integrator: everything up to the home-network mode (83924a9). In entry 15 on top of that: "No faces"; the second independent review's fixes (`REVIEW-B3-viewer-2.md`); ffmpeg found robustly (board message 22); thumbnails four at a time on screen and one at a time in the background; a counts-only timings file; hiding a chat from its own page. **The owner has opened the viewer (12:54 and 13:05):** "It loads. The first video I clicked took a long time to play. There's basically no thumbnails for anything", then, after the ffmpeg fix: "The thumbnails are there, loading, but slowly." **For the owner now:** close the viewer's window and double-click `b\b-viewer.cmd` (it opens `http://127.0.0.1:8798`, this PC only): it takes the build of 16376c9 and the catalogue `old-archive-4` by itself, 3 thumbnail makers, the background mode on. New since the owner's last look: thumbnails faster and filling in behind; "Hide this chat" on a chat's page, hidden chats marked in the Chats list. **Open:** the slow first video is not diagnosed (the new build writes its timings to `stats-last.json` in the viewer's folder: read it after the owner's next use); the default library's first load is at its 200 ms budget; nobody has seen the newest pages in a browser, nor the pages as another device sees them. **Decided by the owner, for the next session:** a native window with mpv (`PLAN-native-window.md`). **Not this track's:** thumbnails made on the NAS (message 23). Reviews: `REVIEW-B3-viewer.md`, `REVIEW-B3-viewer-2.md`, `REVIEW-B3-lan.md`.

# Session B6 (took the track over 11-16 06:58; B5 is retired)

## 06:58 (11-16) TAKEN OVER; the disk matches B5's block
- **Read first:** the board (direction, rules, my row, the queue, the list for the owner, message 100 and the
  integrator's of 06:41), B5's take-over block and the night's entries here, `HANDOFF.md` 0c,
  `MORNING-2026-11-16.md`. Not read yet, to be read before any new brief (the pass-through): the lessons
  files' sections the board names for step 1, `SEAM-B5-viewer-act.md`, messages 67, 76, 90, 91, 93, 95.
- **The disk:** `wt-b-viewer` (`wip/b-staged` 15763352), `wt-b-window` (`wip/b-compose` f361d35c),
  `wt-b-faces` (`wip/b-edits` 1edb307f), `wt-b-join` (10a9e3a8, detached): all clean. The main head is
  788ebf77 (entry 21 merged in it as a37ed4c3). Nothing of this track runs.
- **The board row** cut to its current state (its earlier states are the block above this session's
  heading); by one script call (a single command).
- **Next:** ONE Sonnet clerk builds the viewer and the window from 788ebf77, tries the built viewer on an
  invented archive, and places both in the track's `bin`; then ONE clerk merges the main head into
  `wip/b-compose` and, when clean, the full runs go once.

## 06:59 (11-16) TWO SONNET CLERKS RUN: the compose box's merge of the head; the builds for the track's `bin`
- **The owner was told the full runs' plan in one line first** (the viewer whole on Windows, about 6.5
  minutes; the race detector on the viewer only, about 40 minutes: the routes share maps under a lock and a
  queue outlives its request).
- **Clerk A** (`wt-b-window`): merges `private/claude/charming-feynman-vm2xia` (788ebf77 or newer) into
  `wip/b-compose`; on a conflict it stops with the merge left in progress (the session resolves); when
  clean: gofmt, vet, the build, `TestAct|TestWall` and the two commands' tests, the push, then it starts
  `ix-tools/full-runs.sh wt-b-window runs-b11 "viewer" "viewer"` in the background and returns (logs in
  `runs-b11`: `started.txt`, `win-viewer.log`, `race-viewer.log`, `ended.txt`).
- **Clerk B** (`wt-b-join`, detached at 788ebf77): builds `tgarchive.exe` and
  `tgarchive-window.build.exe` (`CGO_ENABLED=0`, `-trimpath`) into the session's scratch folder, tries the
  viewer on an invented `-real-rows` archive (port 8797, output to a file), then places both in the
  track's `bin` (the 10a9e3a8 builds kept as `.10a9e3a8.bak`). It starts nothing of the owner's.
- **Take-over:** if this session ends, read `runs-b11` (each log ends "exit N") and `git log -1` in
  `wt-b-window`; a merge left in progress there means a conflict nobody resolved yet.

## 07:00 (11-16) THE BUILDS OF 788ebf77 ARE IN THE TRACK'S `bin` (by a Sonnet clerk; checked by me)
- **07:00 clerk B reported:** `wt-b-join` detached at 788ebf77, clean before and after; both builds exit 0;
  the built viewer on an invented `-real-rows` archive answered 200 on port 8797 and stopped (its log 3
  lines); the 10a9e3a8 builds kept as `tgarchive.exe.10a9e3a8.bak` and
  `tgarchive-window.build.exe.10a9e3a8.bak`; the new files compared equal to the built ones. One deviation
  it named: it made the invented archive and started the viewer in two calls at the same moment.
- **Checked by me (two commands; a judgement: a report is not proof):** in `bin`, `tgarchive.exe` is
  `cmd/tgarchive` (24,459,776 bytes) and `tgarchive-window.build.exe` is `cmd/tgarchive-window`
  (22,764,544 bytes), both stamped 788ebf77, not modified, byte for byte the built files. The clerk's report
  had the two sizes the wrong way round; the files are right.
- **For the owner:** `b\b-window.cmd` takes the new window by itself at its next start (staged and lost
  files shown as they are; the old archive needs no `-staging`). Nothing of the owner's was started.
- **Read by me while the clerks ran:** `SEAM-B5-viewer-act.md`; `act_ledger.go` at f361d35c, whole (the
  part B5 had not read): the first walk, the walk again when dropped tips have room, the bound per ask,
  the locks (the box's lock only for the map, the chat's lock across its reads). No blocker found. Still
  not read by a session: `act.js` of the second fix round.
- **Clerk A:** the merge of the head into `wip/b-compose` was clean (31362d5d, seen in the copy); it is in
  its checks; the full runs start after them.

## 07:07 (11-16) THE PASS-THROUGH TO THE DOOR IS WITH A CODER; THE COMPOSE BOX'S FULL RUNS GO; message 102
- **07:00 clerk A reported** (a Sonnet clerk, one instruction): the main head 788ebf77 merged into
  `wip/b-compose` with no conflict (new head 31362d5d, pushed); gofmt, vet and the build clean;
  `TestAct|TestWall` ok 12.0 s; `cmd/tgarchive` ok 6.8 s; `cmd/tgarchive-window` ok 2.0 s; the PC at 6.3 GB
  free and 31% before the runs; **the full runs started 07:00:34** (`runs-b11`: `win-viewer.log`,
  `race-viewer.log`, each ends "exit N"; `ended.txt` when both are done; the race run needs about 40
  minutes). A background file watch of mine waits for `ended.txt`.
- **Entry 22 is drafted** (the session's scratch folder, `entry22.txt`; if this session ends, write it
  anew from B5's entries of 02:35 to 03:20 above and this one: the model is entry 21). It says: behind a
  nil seam; reviewed twice; the second fix round had no third look; `act_keys.go` read by B5,
  `act_ledger.go` by B6, `act.js` of that round by nobody but its coder; the coder's three doubts.
- **Both messages 101 read (07:05):** pages (P4) builds the door now (G8, `wip/pages-door`: six POST routes
  under `/api/act/`, the header `X-Tgarchive-Door`, 409 with a word and a time, the file `act-door.json`
  beside the catalogue file); Core (K-4) builds K14 (the key's memory at the queue, one cheap state call,
  the words "key" and "queue full").
- **Read by me before the brief, in full:** TRIED-BEFORE 9, 10, 15, 24, 25; LESSONS "the twelve", 1, 2;
  `LESSONS-viewer-ix12.32.md`; FEATURES 7, 9, 10 and section 12's seventh round; the design's sections 3
  to 6; `BRIEF-G8-clicks-door.md`; the second review's section for the pass-through; `wall_test.go`; the
  seam's part of `act.go`. The old app has no acting side: no number of its stands beside this piece.
- **07:07 ONE Opus coder (high effort) started:** `BRIEF-B6-door.md`, branch `wip/b-door` from
  `private/wip/b-compose` 31362d5d, copy `wt-b-viewer` (it was clean on `wip/b-staged`). One new file
  `internal/viewer/act_door.go` (the only one that may connect; exactly `127.0.0.1:<port>`; no retry of a
  changing call; "nothing left this program" kept apart from "it left and no answer came"; a catalogue
  beside which no door file was ever seen draws nothing, as today); the seam brought up to date with K9c
  and K14's two words; the wall test's one named exception; the About sentence. The two commands are NOT
  changed: the seam stays nil until G8 and K14 are merged and the path has its own security review.
- **Board:** message 102 (to pages, Core, the integrator); my row.
- **The next listed piece after it: the "what changed" feed (roadmap E3).** Counted first, read-only and
  immutable, on the brought-in old archive (07:03, numbers only): 584,075 messages; 8 with a deleted mark
  (3 distinct times, 1 day, none with a file by the join I tried); 64,990 with an edit date (1,738 distinct
  days; 24,218 of them with an empty text); 0 earlier versions kept. So the feed serves the new accounts
  (the live monitor writes deleted marks and earlier versions); on the old archive it would be 8 rows and
  a long list of "edited, no earlier version kept". The viewer already has the Deleted page (posts by when
  the deletion was seen); the feed adds edits. Not briefed yet.
- **Take-over:** running: the full runs (`runs-b11`), the coder (`wt-b-viewer`, `wip/b-door`; its commits
  are pushed as it goes: `git log 31362d5d..private/wip/b-door`). When `runs-b11/ended.txt` exists and both
  logs end "exit 0" with no "WARNING: DATA RACE" and no "--- FAIL": write entry 22 into `MERGE-QUEUE.md`,
  a "Waiting, READY" line on the board, a message to the integrator. When the coder hands back: read
  `act_door.go` whole and the wall test's change; then, with G8 and K14 merged: the wiring, the end-to-end
  test, an independent security review, the full runs, the entry.

## 07:41 (11-16) THE PASS-THROUGH IS HANDED BACK (d5dd4869), READ, AND WITH AN INDEPENDENT REVIEWER; message 105
- **About 07:38 the coder handed back** (32 minutes): `wip/b-door` d5dd4869, pushed; cut from 31362d5d; it
  merged the main head a29fe931 (K9c, G7, K13) in at 6060886a, clean. **Verified by me** (a report is not
  proof): the copy `wt-b-viewer` clean on `wip/b-door`; `private/wip/b-door` is d5dd4869; against the main
  head only `internal/viewer` differs (the two documents that show are the main head's newer ones); the two
  commands untouched.
- **As built, by its report:** `act_door.go` (497 lines; `NewActDoor(find)`, the door looked up at every
  call; exactly `127.0.0.1:<1 to 65535>`, a secret of 32 to 128 hex digits; a client per call with no
  proxy, no redirect, no jar, no kept connection, a `tcp4` dial to the checked address whatever the URL
  says; 16 KB of headers, 64 KB of body; 409 a refusal only for one of the door's 25 words; two kinds of
  failure kept apart; no changing call repeated). Until a door file was found once in the run the viewer is
  as with a nil seam; the page flag is built per page load and the live poll carries "act" on this PC's
  listener. Seam: `SendClickAgain` with `notInChat`, `ClickNotArrived` and a seventh route, an "arrived"
  the app made kept open and drawn with one button, the hint from `catalog.ClickCandidates`, the words
  "key" and "queue full" (35 words). 13 new tests, 13 mutations caught (two only after it mended its own
  test and mutation); `TestAct|TestWall|TestLAN` ok 28.2 s; build, vet, gofmt clean. Not tested: a real
  door; any page in a browser. Its doubts: an "arrived" the app made stays drawn 7 days; the candidates'
  cost on a large catalogue not measured; the pass-through is concurrent code (a mutex, atomics).
- **My read (07:38 to 07:42):** `act_door.go` whole and the wall test's change whole. Sound as written: the
  dial ignores the URL's address; "not left" needs no connection made AND the caller's time not over; a
  fresh transport with no kept connection, so Go's own retry of a request on a reused connection cannot
  happen; the secret is in one header only. Left to the reviewer: a stale door file whose port another
  local program took; the look's cost; `act.js`.
- **The door as built (pages' message 104; `pages-door-REPORT.md` section 2 on `wip/pages-door`), against
  the pass-through. Agree:** the state's four JSON names, the 409 body, the header, the routes, both words
  on "again". **Do NOT agree, for the fix round:** (1) cancel, verdict and not-arrived answer `{"ref":n}`,
  the pass-through reads `{"ok":true}`: every such answer would be a failure; (2) the state route's 409
  "not found" is shown as "failed" instead of its word. **For the wiring:** the reader is
  `actdoor.ReadDoorFile(catalogueFolder) (Door, error)` (standard library only); it reads again for about
  100 ms when the file is missing, so the commands' wrapper looks for the name first (the old archive has
  no door file ever, and a stopped collector has none).
- **About 07:40 an independent Opus reviewer (high effort) started** (I first wrote 07:43 here from memory;
  this entry's own time, from `date`, is the later bound): `BRIEF-B6-door-review.md`, read-only on
  `wt-b-viewer`, probes in `wt-b6-review-D-scratch`, it writes `REVIEW.md` there. It also reads `act.js`
  of the compose box's second fix round (nobody but its coder had). Told by one message: the door's
  report and the two known mismatches. **No fix is made in the copy while it reviews.**
- **The integrator (07:34):** the main head is e4a4a61d (G7, K9c, K13 merged); the end-to-end test may
  live in `internal/acttest`, this track's, listed with the piece that makes the seam live.
- **The compose box's runs at 07:38:** `win-viewer.log`: ok, 378.3 s, exit 0; the race run still goes.
- **Take-over:** running: the race run (`runs-b11`), the reviewer. Next: entry 22 when the race log ends
  "exit 0" clean (the draft: scratch `entry22.txt`, or write it anew from the entries above). When the
  review is back: decide each finding, ONE fix brief for the same or a fresh Opus coder with the two
  mismatches above in it, a second look by the reviewer; then, once G8 and K14 are on the main head: merge
  it in, the commands' wiring (the wrapper over `actdoor.ReadDoorFile`, the name looked for first), the
  end-to-end test in `internal/acttest`, full runs once (the viewer whole and under the race detector:
  the pass-through is concurrent code), the entry that makes the seam live.

## 07:43 (11-16) THE COMPOSE BOX'S FULL RUNS ARE CLEAN; ENTRY 22 IS LISTED, READY; message 106
- **The runs (`runs-b11`, 07:00:34 to 07:43:02; started by a Sonnet clerk, the logs read by me: a single
  command):** whole `internal/viewer` on Windows ok 378.3 s, exit 0; the race detector on `internal/viewer`
  ok 2,535.5 s, exit 0, 0 "WARNING: DATA RACE", 0 "--- FAIL"; gofmt lists nothing. The copy `wt-b-window` is
  clean at 31362d5d.
- **Against the moved main head (a8dfefd6):** it changed no file of `internal/viewer` and neither viewer
  command since 788ebf77; `git merge-tree` of the head and `wip/b-compose`: clean.
- **Entry 22 written at the end of `MERGE-QUEUE.md`** (by one script call from my draft: it needed my words):
  READY, "behind a nil seam"; it says the second fix round had no third look, who read which file, the
  coder's three doubts, and what must come before the seam may be live. Board: the "Waiting, READY" line,
  message 106 to the integrator, my row.
- **Take-over:** running: the pass-through's independent reviewer only (read-only on `wt-b-viewer`; its
  `REVIEW.md` in `wt-b6-review-D-scratch`). Nothing else of this track runs. Next: the review's findings
  into ONE fix brief with the two mismatches of the entry above; a second look; then the wiring, the
  end-to-end test and the full runs once G8 and K14 are on the main head.

## 07:45 (11-16) THE "WHAT CHANGED" FEED IS WITH A SECOND CODER (roadmap E3; a listed feature of this track)
- **Why now:** the pass-through waits on its review, then on G8 and K14; the roadmap's row `"What changed"
  feed` is "none", owner track "viewer and bring-in" (B5's note that it was another track's was wrong: the
  roadmap names this one). A listed feature in my packages is built, not asked about.
- **Read by me first:** `deleted.go` (the Deleted page: a keyset seek in `ix.deleted`), the index's fields
  for deletions, where `message_version` is written (`catalog/tgrows.go`; it carries `replaced_at`, the
  second the change was seen); the lessons named in the entry of 07:07. The count on the old archive is in
  the brief (8 deleted marks, 64,990 edit dates, 0 earlier versions): the page shows deletions and edits
  with an earlier version by default, and the rest behind a chip with its count.
- **07:45 ONE Opus coder (high effort) started:** `BRIEF-B6-changes.md`, branch `wip/b-changes` from the main
  head (a8dfefd6 or newer; its hand-back says which), copy `wt-b-faces` (it was clean on the parked
  `wip/b-edits`, which stays pushed at 1edb307f). One page "Changes" (deleted on Telegram; edited, with the
  text before where a version is kept), the Deleted page folded into it with its addresses kept, the index
  kept in place through the change log, a stable cursor, numbers at 600,000 messages. Only
  `internal/viewer`; no schema step.
- **The PC at the start:** 5.1 GB free, 61% (the reviewer's probes and other tracks). Both agents check
  memory and load before each go command.
- **Take-over:** running: the pass-through's reviewer (`wt-b-viewer`, read-only; `wt-b6-review-D-scratch`)
  and this coder (`wt-b-faces`; `git log private/claude/charming-feynman-vm2xia..private/wip/b-changes`).
  After its hand-back: my read of the index's part, one independent review, fixes, the head merged in
  (entry 22 may be on it by then: `server.go`, `api.js`, `chat.js` meet by a few lines), full runs once
  (the viewer whole; the race detector on the viewer only if the index writer's concurrent part changed),
  then an entry.

## 07:58 (11-16) THE PASS-THROUGH'S REVIEW IS BACK (12 findings); ALL DECIDED; ITS FIX ROUND RUNS. THE WINDOW'S PAGES MODE IS WITH A THIRD CODER. message 110
- **About 07:54 the independent review came back** (`wt-b6-review-D-scratch/REVIEW.md`, probes
  `probe_b6d_test.go` with `overlay.json`; the copy left clean at d5dd4869; 15 minutes). **Verdict: the
  pass-through itself (`act_door.go`) is sound; the seam may NOT be wired to a real door yet.** Confirmed:
  (1) a precondition, not a defect of the file: after a lost answer only the door's key memory stops a
  second send, and the door as built has none (Core's K14); (2) a refusal on a later try dropped the key
  of an earlier, uncertain try (`act.js`): a third try had a new key; (3) the viewer's one 20 s deadline
  for the state and the queue together could end before the door's 15 s: two requests with one key at the
  door at once (probe P5); (4) "it is not in the chat" was passed on for ANY row, which switches off the
  app's own check before a repeat (probe P6; the coder's own test asserted it); (5) every 409 of the state
  route showed as "failed" (probe P4). Plausible: (6) a second press of forward, delete or reaction while
  the first is out gets a new key. (7) the wall would not fail on an aliased import, a package-level
  client in `act_door.go`, or a changed dial line. Low: (8) 403, 404, 503 taken as "left, no answer"
  (safe); (9) a stale door file whose port another local program holds: its answer is believed; (10) a
  huge `until_ms` makes the page throw; (11) the hint can name a candidate the app refuses as ambiguous;
  (12) app-made "arrived" rows take open slots for 7 days. Checked and sound: one connection per call
  through eleven odd door behaviours; never "not running" once a connection was made; 53 address forms;
  the proxy variables never read; the secret; the door never seen (64.8 million asks made 1 look).
- **My decisions (`BRIEF-B6-door-fixes.md`): all accepted.** A: the two mismatches against the door as built
  (`{"ref":n}`; a state 409 with a state word becomes the box's line; on the state route 403, 404, 503 are
  "not running"; for changes they stay failures). B: an uncertain key is kept until the state shows its
  number or the owner changes the content; the state call 5 s and a change 18 s, each of its own; a button
  that is out answers "still asking". C: the route refuses `not_in_chat` unless the row is "not sent" with
  the why "the earlier try is in the chat", and `try_again` unless the row offers it. **D (mine, beyond
  the review): a click's number is believed only when the viewer's own read of the ledger finds that row
  for this account, chat and kind.** E: `until_ms` only within a year; a candidate the app does not take
  is shown only with the catalogue's why word; an app-made "arrived" never pushes out a row that needs the
  owner. F: the wall resolves imports by path, counts the whole door file, and gets one behaviour test.
- **07:56 a FRESH Opus coder (high effort) started on the fix round** in `wt-b-viewer` (the first coder's
  context was 380,000 tokens: a fresh one on a written brief is cheaper). Then: my read, a second look by
  the same reviewer (its probes P4 to P6 as tests).
- **The integrator (07:44) and pages (108 b): the owner opened the app's program at 07:40 and asked "Will it
  eventually be standalone (i.e. not in a browser)".** Asked of this track: what the launcher may call to
  show the app's pages in the window. **Read by me:** `internal/window`'s `allowed.go`, `run.go`, the
  single-instance rule, the command's main flow. **07:58 a THIRD Opus coder (high effort) started:**
  `BRIEF-B6-window-pages.md`, branch `wip/b-winpages` from the main head, copy `wt-b-join` (it was clean,
  detached at 788ebf77): `tgarchive-window -pages <address> ... -data <folder>`, nothing of the viewer in
  that mode, only the named 127.0.0.1 ports, a code of its own within 10 s when no window can be shown, a
  self-check of the mode on two invented servers (it opens a real window for seconds: at most three runs).
  Two windows for this step (the pages', the viewer's); one window with the viewer as a place in it is a
  later piece.
- **The PC at 07:57:** 5.5 GB free, 82% (many tracks' coders). Every agent of mine waits while the CPU is
  over 85% or free memory under 2.5 GB.
- **Board:** message 110 (the window's door for pages; what the pass-through relies on at the door and in
  K14, each as a sentence to test; copies' 109 b answered), my row.
- **Take-over:** running, three coders, all pushing as they go: the door's fixes (`wt-b-viewer`,
  `wip/b-door`), the feed (`wt-b-faces`, `wip/b-changes`), the window's pages mode (`wt-b-join`,
  `wip/b-winpages`). Listed and waiting: entry 22. For each hand-back: verify the copy and the pushed head,
  read the risky part (door: `act.js`'s key rule and decision D; feed: the index's in-place update;
  window: the widened address rule and what the mode refuses), one independent review (the window's
  security-minded; the door's a second look by its reviewer), fixes, full runs once, an entry.

## 08:17 (11-16) THE "WHAT CHANGED" FEED IS HANDED BACK (9d24b538), READ, AND WITH AN INDEPENDENT REVIEWER
- **About 08:15 the coder handed back** (31 minutes): `wip/b-changes` 9d24b538, pushed, on the main head
  dbca91d4. **Verified by me:** the copy `wt-b-faces` clean on that head; `private/wip/b-changes` is
  9d24b538; 17 files, all in `internal/viewer` (2,249 insertions, 147 deletions; `deleted.js` removed).
- **As built, by its report:** one page "Changes" (`changes.go`, `web/js/changes.js`): a deletion row per
  post (when the app saw it), an edit row per MESSAGE (with a version: the second the app saw the change,
  the text before and now; without: Telegram's edit time, "no earlier version is kept"); default:
  deletions and edits with a version; chips with counts (the kind, bare edits, one chat, only with media);
  hidden chats and posts never listed and counted apart in one line; `/deleted` opens it with the kind
  set, `/api/deleted` kept (it now applies the hiding rules). The index (`feed.go`): per chat six ordered
  lists (three kinds by "has files"), copied only for the chats an update touched; a byte per message in
  existing padding; the writer keeps a map from each edited message to its row. It reads edits for every
  message the change log names with kind 2 or 4 (an edit that changes only the files logs kind 2 only).
  **Its numbers at 600,000 messages:** the full read gains about 32 ms of 3.8 s; 81.6 bytes per edited
  message (5.3 MB at 65,000); an update with nothing new 8.3 ms at the median (the base not measured); an
  update naming one edited message 12.5 ms; a first page 7.8 ms, a tenth 6.2 ms. Seen by it in the browser
  pane on an invented archive of its own (77 rows scrolled to the end; no console error), then stopped.
- **Its differences from the brief:** edit rows are per message (an album with two edited captions shows
  its post twice); the old Deleted page applied no hiding rule, so it built "hidden is not listed".
- **Its doubts:** kind 2 covers sightings too, so the new read per update follows sightings (not measured
  under write load); a change of the feed makes a new index version (library listings kept by version
  rebuild); `/api/deleted` now hides what is hidden.
- **My read (08:16 to 08:22):** the difference of `refresh.go` and `index.go`, and `feed.go` whole. No
  blocker found. Given to the reviewer: the writer's map `edits` after a full read on the same writer and
  after a failed update; a message that moves to another post; the cost of the kind 2 read with a
  collector writing; the counts' cost with many hidden posts.
- **08:17 an independent Opus reviewer (high effort) started:** `BRIEF-B6-changes-review.md`, read-only on
  `wt-b-faces`, probes in `wt-b6-review-C-scratch`, it writes `REVIEW.md` there.
- **Take-over:** running: the door's fix-round coder (`wt-b-viewer`), the window's pages-mode coder
  (`wt-b-join`), the feed's reviewer (`wt-b-faces`, read-only). Listed and waiting: entry 22. After the
  feed's review: decide each finding, one fix brief (a fresh Opus coder), a second look if the round
  rewrites the index's part; the main head merged in (entry 22 if it is merged by then); full runs once:
  the viewer whole, and the race detector on the viewer (the index writer's path changed).

## 08:20 (11-16) THE PASS-THROUGH'S FIX ROUND IS BACK (25365ae2), VERIFIED; THE REVIEWER'S SECOND LOOK RUNS
- **About 08:19 the fix-round coder handed back** (24 minutes; a fresh Opus coder): `wip/b-door` 25365ae2,
  pushed, three commits on d5dd4869. **Verified by me:** the copy `wt-b-viewer` clean on that head;
  `private/wip/b-door` is 25365ae2; 11 files, all in `internal/viewer` (1,385 insertions, 254 deletions);
  the two commands untouched; the seam file has its new section (committed with this entry).
- **Every decision A to F built, by its report, with these differences:** cancel, verdict and not-arrived
  must answer the very number asked; `not_in_chat` also needs the row's own button (its text still kept);
  the ledger check (`actNumberHeld`: at most two reads 250 ms apart, 2 s in all) also wants `again_of` to
  be the row asked, and only the pass-through is checked (test seams are not); the page's 32 kept button
  keys are a soft bound. Deadlines: state 5 s, a change 18 s, the ledger check 2 s (25 s in a row, under
  the page's 30 s). The wall's tests largely rewritten (imports by path, the client in `actDoorClient`,
  a behaviour test). The review's probes P4, P5, P6 are tests now: each FAILS on d5dd4869 for the review's
  reason and passes on the new head (its lines are in its hand-back). 7 mutations caught.
  `TestAct|TestWall|TestLAN` ok 24.7 s; gofmt, vet, the build, `node --check` clean; no test function
  removed.
- **One thing it did wrong and said:** a first version of its behaviour test asked a URL with the reserved
  name `door.invalid`; under one mutation the broken dial looked that name up, which may have sent a DNS
  query off this PC (a name only: nothing of the owner's; no connection was made). The test now uses
  addresses only. **Rule for briefs from now: probes and tests name addresses, never host names.**
- **Its doubt, open:** the ledger check still believes a guessed number of an existing row of the same
  account, chat and kind (row numbers run in order). The full check needs the key on the click's record
  (K14's `c_act_key`): a read door by key, asked of Core for the wiring.
- **My read:** `actNumberHeld` whole (bounded; a context of its own) and the page script's difference (the
  `uncertain` mark, the kept keys, `this.out` cleared in a `finally`). No blocker found.
- **08:20 the first reviewer was sent its second look** (one message; it writes `REVIEW-2.md` beside
  `REVIEW.md` in `wt-b6-review-D-scratch`): its findings by its own probes run again, what the round
  itself opened (the key rule, the deadlines, the ledger check, the rewritten wall tests), the guessed
  number.
- **Take-over:** running: that second look (read-only, `wt-b-viewer`), the feed's reviewer (`wt-b-faces`),
  the window's pages-mode coder (`wt-b-join`). Listed and waiting: entry 22.

## 08:27 (11-16) THE WINDOW'S PAGES MODE IS HANDED BACK (bc6a44f5), READ, AND WITH AN INDEPENDENT SECURITY REVIEWER; message 111
- **About 08:25 the coder handed back** (28 minutes): `wip/b-winpages` bc6a44f5, pushed, three commits on
  the main head 6af0c09a. **Verified by me:** the copy `wt-b-join` clean on that head;
  `private/wip/b-winpages` is bc6a44f5; 13 files, all in `internal/window` and `cmd/tgarchive-window`
  (2,269 insertions, 6 deletions).
- **As built, by its report** (in full in board message 111 a, for pages' G11): `tgarchive-window -pages
  http://127.0.0.1:PORT/ ... -data FULL-PATH` (1 to 4 addresses, the trailing slash required); exit 0
  (closed, or another window on that folder brought to the front), 3 (no window can be shown: at once, or
  at 8 s, or when the engine ends later), 1 (flags and other errors); only `http` on `127.0.0.1` at a
  named port shown; every other address, every download, permission request and page message refused and
  counted; a line of the window's own with "Try again" when a page does not answer; writes only inside
  `-data`. The self-check ran 3 times (a window of about 18, 32 and 32 s on the primary monitor, focus not
  taken); its third run's lines are in the hand-back (links, POST with a redirect, meta refresh: true;
  each refusal counted once; no file downloaded; "Try again" brought the page back).
- **What it found and said plainly:** (1) **this WebView2 sends the request of a refused top-level or frame
  navigation before the window refuses it** (its self-check counted 6 HTTP requests and 10 TLS hellos at a
  port that was not named; `window.open` sent nothing); the handlers are shared, so **the viewer's window
  does the same today** and the earlier reviews did not check it; (2) the self-check's own pages reached a
  third port of its own and `localhost` (all on this PC); (3) the wall test of `internal/window` now
  allows `net/http` in one file, the self-check's servers; (4) the 8 s may be tight on a busy PC.
- **My read:** the widened address rule in `allowed.go` whole (`PagesAddress`: a prefix, digits, 1 to 65535;
  `pageSet.allows` reuses the one-port rule per named port). Sound as written. Given to the reviewer: what
  can leave the PC in BOTH modes and the smallest sound way to make "nothing but the named ports is ever
  asked" true; what the WebView2 folder keeps of a sign-in page; the exit code in every way the engine can
  fail; orphan engine processes.
- **08:27 an independent Opus reviewer (high effort) started:** `BRIEF-B6-window-pages-review.md`, read-only on
  `wt-b-join`, probes in `wt-b6-review-W-scratch`, a real window at most three times, addresses only.
- **Board:** message 111 (the mode as built for pages; the pass-through's state; asked of Core: a read by
  key for the ledger check).
- **Take-over:** running, three reviewers, all read-only: the pass-through's second look (`wt-b-viewer`;
  `REVIEW-2.md` in `wt-b6-review-D-scratch`), the feed's review (`wt-b-faces`; `wt-b6-review-C-scratch`),
  the window's review (`wt-b-join`; `wt-b6-review-W-scratch`). No coder runs. Listed and waiting: entry 22.
  For each review: decide every finding, one fix brief for a fresh Opus coder, a second look where the
  round rewrites the reviewed part, the main head merged in, full runs once, an entry. The window's fix
  round is expected to carry the request filter for both modes: that changes the viewer's window too, so
  its entry needs the window's self-check on an invented archive as well.

## 08:29 (11-16) THE PASS-THROUGH'S SECOND LOOK IS BACK: "READY FOR THE WIRING"; A LAST SMALL ROUND RUNS
- **About 08:33 the reviewer's second look came back** (`wt-b6-review-D-scratch/REVIEW-2.md`; probes
  `probe_b6d2_test.go`, `probe_b6d_v2_test.go`, a node harness of the page's key rules in `js/`; the copy
  left clean at 25365ae2; 9 minutes). **Verdict: ready for the wiring to a real door once the door (pages)
  and the collector's key memory (K14) are merged, with the check of its new finding 1 added at that
  merge.** Of the first twelve: 3, 4, 5, 10 gone by its own probes run again; 2 and 6 by its harness
  running the branch's `act.js`; 7 for the three ways named; 11 and 12 by reading; 1 is Core's; 8 as
  decided; 9 partly. The transport's probes printed what they printed before.
- **New:** (1) confirmed, the coder's own doubt: the ledger check believes any existing row of the same
  account, chat and kind, however old (probe Q2: a 3-day-old row); the sound check is
  `catalog.ActKey(account, key)` on the read-only handle once K14 is merged (the key's row is written in
  the click's own transaction); the same read lets the state's `key_ref` survive a forgotten key or a
  viewer restart. (2) confirmed by its harness: the box loses an uncertain key when a refused try of other
  text comes between and the text then comes back. (3) the wall's forbidden list lets a DNS query and a
  UDP packet through (`net.LookupTXT`, `net.ListenPacket` ...): older than this piece. (4) low: a kept key
  can hold one text, or at 32 every new button, until the page is loaded again (fails closed, says so).
  (5) low: any 404 or 403 on the state route reads "not running", which would hide a moved route or a
  wrong secret. (6) plausible, the door's side: the 3 s between the viewer's 18 s and the door's 15 s
  holds only if a queue blocked behind another writer ends at the door's deadline (the catalogue's busy
  wait is 5 s).
- **My decisions (`BRIEF-B6-door-fixes-2.md`), all accepted:** 2 by a small map of uncertain keys by
  content; 3 by the longer forbidden list; 5 by the body's word ("no door", "refused"); 1 now only by a
  stopgap (the row's click time not older than this request's start less 5 s), the check by key with the
  wiring; 4 in the seam file's words; 6 to pages and Core on the board with the next message.
- **08:29 a fresh Opus coder (high effort) started on that round** in `wt-b-viewer`. **No third independent
  look of this round: I read it.** The third look is for the wiring, against the real door.
- **What the wiring stage now holds (when G8 and K14 are on the main head):** merge the head into
  `wip/b-door`; the two commands hand `viewer.NewActDoor` a wrapper over `actdoor.ReadDoorFile` on the
  folder of the very catalogue opened (the file's name looked for first; ok false for every error; safe
  for calls at once); the ledger check by `catalog.ActKey`, and `key_ref` falling back to it; the state
  answer's new fields (a wait's end per kind, the cap's opening, the three limits); one end-to-end test in
  `internal/acttest` (the collector's rig with the fake Telegram, the real door, the pass-through: one
  click, exactly one request at the fake; a wrong secret, none; a lost answer and a second try under the
  same key, one request); the reviewer's third look on that; full runs once (the viewer whole and under
  the race detector, `internal/acttest`, the two commands); then the entry that makes the seam live.
- **Take-over:** running: this small round's coder (`wt-b-viewer`), the feed's reviewer (`wt-b-faces`,
  read-only), the window's reviewer (`wt-b-join`, read-only). Listed and waiting: entry 22.

## 08:30 (11-16) BOARD MESSAGES READ (pages' 111 of 08:03 and 112 of 08:24, Core's 106 of 08:06): what they add to my lists
- **G8, the door, is LISTED and READY** (`wip/pages-door` 1decd1fb, holding 6af0c09a; its contract is its
  report's section 2 at that head). Moved since I read it: a trailing slash on a door path is a plain 404;
  the door refuses new clicks from the moment a stop is ASKED (state, queue and again answer 409 "not
  running"; cancel, verdict and not-arrived still go through).
- **K14 is in its fix round** (2 must-fixes). For the wiring stage, from Core's 106: (1) once the ledger's
  write has committed, queue and again ALWAYS answer the number, never "not running": "not running" from
  the queue then means nothing was written, and a number may belong to a row that is already "not sent":
  the page draws it from the row (my ledger check believes it: right); (2) the door judges an edit by the
  text limit only: **the viewer judges a caption itself** with the state's `CaptionMax` (it knows whether
  the message shown has media); (4) the state: "setting" only for the cap, a field for a bad "mark as
  read", "clicks off" also when the forward secret cannot be read.
- **For the window's fix round, from pages (its 111 b): the app's pages have three things the mode
  refuses.** (1) The Report page's "Download as .txt" (an attachment from the pages' own address): pages
  asks for a download from a named address to be let through with the window's own save box, or to be
  told it stays refused, and for a way a page can know it runs in the window (a word in the user agent).
  (2) The Queue page's links to a post on Telegram (`target="_blank"`, a `t.me` address): refused is right
  for now if it is not silent (a line "this link opens outside the app" with the address to copy). (3) The
  header's "Viewer" link to the viewer's own address: the launcher names it as a third `-pages` address
  when the viewer is the browser kind (nothing of mine to build). **My decisions, to go into the window's
  fix brief with the review's findings:** (1) a download is let through only from a named address, only
  for an answer the server marks as an attachment, with the save box; (2) a refused link to the open web
  shows a line of the window's own with the address as text and "Copy"; nothing is handed to Windows in
  this step; and the mode adds one fixed word to the user agent so that a page can tell.

## 08:38 (11-16) THE PASS-THROUGH'S LAST SMALL ROUND IS BACK (bb5454ce) AND READ; THE BRANCH NOW WAITS FOR G8 AND K14
- **About 08:38 the coder handed back** (9 minutes): `wip/b-door` bb5454ce, pushed. **Verified by me:** the
  copy `wt-b-viewer` clean on that head; `private/wip/b-door` is bb5454ce; 9 files of `internal/viewer`
  (607 insertions, 45 deletions); the seam file has its section (committed with this entry).
- **Built as decided:** the box keeps uncertain keys by content in a map (`unsure`, bounded at 32, the
  buttons' sentence when full); the wall also refuses every `net.Lookup*` and `net.Resolve*`,
  `net.ListenPacket`, `ListenUDP`, `ListenIP`, `ListenMulticastUDP`, `syscall.Socket`, `syscall.Connect`
  (no file of the viewer uses one: no exception); on the state route a 404 is "not running" only with the
  word "no door", a 403 only with "refused", a 503 always; the stopgap (the row's click time not older
  than the request's start less 5 s). Four new tests, each failing on 25365ae2 and passing now; the page's
  key rules run under node from a Go test (the package already did that for another script; skipped where
  node is absent). `TestAct|TestWall|TestLAN` ok 25.6 s, 92 tests; gofmt, vet, the build clean; no test
  function removed.
- **My read (the whole difference of `act.go`, `act_door.go`, `act.js`): right as written, and ONE THING
  FOR THE WIRING THAT MUST NOT BE MISSED: the stopgap is to be REPLACED by the check by key, not kept
  beside it.** With Core's key memory a second try under a known key is answered with the FIRST try's
  click, whose click time is older than the second request: the stopgap would refuse to believe it and
  the page would say "failed" for a click that is queued. Before K14 no door answers an old row for a new
  request, so the stopgap is right until then.
- **Its doubts, kept:** the full-box sentence speaks of "these buttons" and now also answers a new text; a
  wrong secret still reads "not running" (the door's guard answers every refusal alike); an older
  uncertain text is checked against the state only when it is sent again.
- **Decided: no listing of the pass-through "behind a nil seam" now.** It would cost a whole race run of
  the viewer (about 42 minutes) twice, now and again with the wiring; G8 is listed and K14 is in its fix
  round, so the wiring is near. One entry, with the seam live.
- **Take-over:** running: the feed's reviewer (`wt-b-faces`), the window's reviewer (`wt-b-join`), both
  read-only. `wip/b-door` bb5454ce waits for G8 and K14 on the main head; its wiring list is in the entry
  of the second look above, plus: **replace the stopgap by `catalog.ActKey`**; the viewer judges a caption
  with the state's `CaptionMax`; a number may belong to a row that is already "not sent" (drawn from the
  row). Listed and waiting: entry 22.

## 08:40 (11-16) THE FEED'S REVIEW IS BACK (7 findings, 3 to fix before a merge); ALL DECIDED; ITS FIX ROUND RUNS
- **About 08:45 the independent review came back** (`wt-b6-review-C-scratch/REVIEW.md`; probes
  `prb_cost_test.go`, `prb_feed_test.go`, `prb_random_test.go`, `prb_query_test.go`, a copy of the base
  beside them; the copy `wt-b-faces` left clean at 9d24b538; 22 minutes). **Verdict: the feed's lists stay
  in step with a full read in every sequence it tried (80 random updates with albums completed later,
  marks taken back, two edits in one update), and a page and its counts cost almost nothing; two costs of
  the index writer grew and were not said.**
- **Should fix, confirmed:** (1) an update that names many messages by kind 2 now reads each message row
  joined with its versions: at 600,000 messages with 8,000 named, 122 ms before and 185 ms after (that
  read alone 61 ms; the versions' index alone would be 7.6 ms). (2) every edit of a message read earlier
  now makes a new index version, so the library's next ask rebuilds its listing: 4.5 to 6.2 ms before,
  124 to 135 ms after, at 600,000 (0 of 5 edits made a version before, 5 of 5 after). (3) a text edited
  past its first 4,000 bytes is shown as "The text did not change" (the page compared cut texts).
  **Minor:** (4) a deleted post whose lead message changes between two pages is skipped (keyed by the
  lead; the old Deleted page had the same); (5) versions removed by a tool leave the row naming the wrong
  kind of time; (6) `ix.deleted` is still kept at every update for a number no page reads; (7) a page read
  between an edit and the next update mixes two moments; "That is all N" can differ from the rows drawn.
- **Its numbers, before and after, on a busy PC:** the full read at 600,000: 3,359 and 3,397 ms; an update
  with nothing new: 6.5 and 7.5 ms, 24 statements both; a page: 0.5 to 1.0 ms of index work with 2,000
  chats; counts 1.7 ms with 10,000 hidden posts; the timing test at its default size adds about 24 s to a
  whole run of the package.
- **My decisions (`BRIEF-B6-changes-fixes.md`): all seven accepted.** 1: the joined read only for kind 4;
  kind 2 alone reads the versions' index. 2: an update whose only changes are the feed's must not start
  the library's listing, the marks or the verdicts again (the coder chooses the smallest sound way and
  proves it by counting rebuilds). 3: "changed" decided on the whole texts on the server; texts cut only
  at 16,384 bytes. 4: a deletion's row keyed by the post's smallest message id. 5: the words. 6:
  `ix.deleted` goes. 7: the count of rows drawn.
- **08:40 a fresh Opus coder (high effort) started on the fix round** in `wt-b-faces`. Then: my read, a second
  look by the same reviewer (the round rewrites the index writer's part), the main head merged in, full
  runs once (the viewer whole; the race detector on the viewer: the index writer's path changed), an
  entry.
- **Take-over:** running: this coder (`wt-b-faces`, `wip/b-changes`), the window's reviewer (`wt-b-join`,
  read-only). Waiting: `wip/b-door` bb5454ce for G8 and K14 on the main head; entry 22 for the integrator.

## 08:53 (11-16) THE WINDOW'S SECURITY REVIEW IS BACK: THE ENGINE CALLS OUT AT EVERY START, IN THE VIEWER'S WINDOW TOO; THE GATE IS WITH A CODER; message 113
- **About 08:50 the independent review came back** (`wt-b6-review-W-scratch/REVIEW.md`; the probe
  `probe/zz_review_probe_windows_test.go`, its printouts `outA.txt`, `outB.txt`, `outC.txt`, its net logs in
  `dataA` and `dataB`; the copy `wt-b-join` left clean at bc6a44f5; 24 minutes). **Verdict: not as it
  stands; yes once three fixes are in** (the request gate for both modes, autofill off, an instance key and
  an engine folder of the pages mode's own).
- **F1, confirmed, BOTH modes, so also the viewer's window as merged and as the owner uses it:** within the
  first minute of a window on invented local pages the WebView2 runtime itself made 4 POSTs to its
  component updater, 2 GETs to its configuration service, more than 3 TCP connections to public addresses
  and one QUIC session, and 14 name lookups (6 for proxy auto-discovery). None was caused by a page;
  nothing of a page or of the archive is in them. The window runs outside the VPN: each start shows the
  PC's own address to Microsoft and the DNS resolver. **The review's own probe run in its "plain" mode made
  exactly these requests from this PC** (measuring them was its purpose; said here because my brief had
  asked that nothing reach another machine).
- **F2, confirmed:** a shown page's sub-resources of all 13 kinds tried went to an address nobody named; a
  refused top-level GET or frame had sent its request first; a link's `ping`, a press on a link, WebRTC
  (4 UDP packets). In the pages mode the app's own pages cause none of it today (their policies, no web
  link); **in the viewer's mode no way from anything in the archive to a request was found.**
- **The cure, measured by the reviewer (its "proxy" mode):** the engine pointed at a gate that forwards
  only `http` to named 127.0.0.1 ports: all 26 kinds and the engine's own 3 requests ended at the gate; 0
  connections at a port nobody named; 0 connection attempts to a non-loopback address. Left: WebRTC from a
  page's script; two name lookups (the switch against them not run).
- **Other findings:** F3 the two modes share one mutex, window class and engine folder per data folder
  (confirmed by argument); F4 a submitted form's text field was kept in the engine's folder (autofill on;
  password saving off); F5 the 8 s bound hangs on the message loop; F6 an empty 500 shows no line; F7 the
  "Opening" line has no bound; F8 a named port 80 can never be shown; F9 a named port is trusted for the
  window's life (the launcher's side); F10 inherited `WEBVIEW2_*` variables steer the engine (a debugging
  port, another profile); F11 crash dumps under the data folder.
- **My decisions (`BRIEF-B6-window-gate.md`): all accepted.** A: the gate in both modes (the engine's
  arguments set by the program, the four other variables removed, the gate's one rule a pure function,
  its file the wall's one named exception, WebRTC tried and measured, the self-checks FAILING on any
  connection at an unnamed port or any non-loopback attempt, the cost measured on an invented archive).
  B: names of its own for the pages mode. C: autofill, password saving, the reputation check off; crash
  reporting only if small. D: the watch for exit 3, the 500, the 15 s, port 80. E (pages' three places):
  a download only from a named address and only `text/plain`; a refused web link shows a line with the
  address and "Copy"; the user agent gains `tgarchive-window` in the pages mode. **The order is fixed in
  the brief: the gate first, no real window before it is on; then at most four.**
- **08:53 a fresh Opus coder (high effort) started on it** in `wt-b-join` (08:53 by the clock when it was
  sent). Then: my read of the gate's rule and its dial, the reviewer's second look, full runs once
  (`internal/window` whole and under the race detector: the gate is concurrent code; the command; both
  self-checks), an entry. After its merge: new builds into the track's `bin`, and a line for the owner's
  list.
- **For the owner, to be said plainly in my next message:** the viewer's window used since 11-15 lets the
  engine make these requests at each start; no archive content is in them; the fix is being built.
- **Board:** message 113 (the finding, the cure, the launcher's rules from the review, pages' three places
  decided); my row.
- **Take-over:** running: the gate's coder (`wt-b-join`, `wip/b-winpages`), the feed's fix-round coder
  (`wt-b-faces`, `wip/b-changes`). Waiting: `wip/b-door` bb5454ce for G8 and K14 on the main head; entry
  22 for the integrator.

## 09:04 (11-16) THE FEED'S FIX ROUND IS BACK (8cced5a9), VERIFIED; THE REVIEWER'S SECOND LOOK RUNS
- **About 09:03 the fix-round coder handed back** (24 minutes; a fresh Opus coder): `wip/b-changes`
  8cced5a9, pushed, two commits on 9d24b538. **Verified by me:** the copy `wt-b-faces` clean on that head;
  `private/wip/b-changes` is 8cced5a9; 11 files, all in `internal/viewer` (1,087 insertions, 143
  deletions); no test function removed.
- **All seven built, by its report.** 1: the joined read only for kind 4; kind 2 alone reads the versions'
  index. **2: it kept the feed OUTSIDE the version** (not a generation of the library's own): `index.feed`
  is a box with an atomic pointer to an immutable state (the lists, and a map of the edit kinds that
  changed since the version was made, at most 1,024); an update whose only changes are the feed's stores a
  new state and keeps the version (`feedOnly`), so the library's listings, the marks, the verdicts, the
  overlap tables and the totals are all kept untouched; past the cap an update makes a normal version.
  3: `same` decided on the whole texts; cut only past 16,384 bytes with fixed words. 4: a deletion keyed
  by its post's smallest message id. 5: the words. 6: `ix.deleted` AND `deletedFiles` gone (both numbers
  from the feed's classes). 7: the rows drawn.
- **Its numbers (the review's cost probe at 600,000 messages; the PC busier than at review time):** the
  read this piece added, 8,000 named by kind 2: 61 ms before the fix, 7.3 ms after; that whole update
  184.7 then, 157.0 now (the base 122.4 by the review; not re-run today); one edit: a new version 5 of 5
  before, 0 of 5 now; the library's next ask 124 to 135 ms before, 5.2 to 6.7 ms now.
- **The review's probes as tests:** four fail on 9d24b538 for the review's reasons and pass now (its lines
  are in the hand-back); the random sequence kept as a test (80 steps, 18 of them kept the version).
  One named run at the end: 91 pass, 1 skipped by its own switch; gofmt, vet, the build, `node --check`
  clean. Not tested: the page in a browser; long real texts.
- **Its doubts:** the page's "as of" second and a feed state stored just after it; the copy of the kinds map
  at each kind change and a new version at least once per 1,024 first edits; `at_seen` true where the
  index's time was Telegram's date (a tool's rows only); **the atomic box is new concurrent code and no
  race run has been made.**
- **My read:** `feed.go`'s head, the box and `feedOnly` whole. Sound as written: a stored state is never
  changed; the cap is checked before anything is changed; the writer's map and the box are changed
  together. Given to the reviewer: a normal update after feed-only ones (does it start from the box's
  newest lists and fold the kinds in), anything still read from the message's own kind, the three numbers
  side by side.
- **09:04 the first reviewer was sent its second look** (one message; it writes `REVIEW-2.md` beside
  `REVIEW.md` in `wt-b6-review-C-scratch`).
- **The full runs after it, once (to be said to the owner in one line first):** the viewer whole on
  Windows (about 6.5 minutes) and the race detector on the viewer (about 42 minutes: the refresher now
  stores into a box that requests read at the same time), after the main head is merged in.
- **Take-over:** running: that second look (`wt-b-faces`, read-only), the gate's coder (`wt-b-join`).
  Waiting: `wip/b-door` bb5454ce for G8 and K14 on the main head; entry 22 for the integrator.

## 09:25 (11-16) THE FEED'S SECOND LOOK IS BACK: "READY FOR ITS FULL RUNS"; A LAST SMALL ROUND WITH THE MERGE OF THE HEAD RUNS
- **About 09:24 the reviewer's second look came back** (`wt-b6-review-C-scratch/REVIEW-2.md`; probes
  `prb2_feed_test.go`, `prb2_random_test.go`, `prb2_fold_test.go`, the base and the first piece extracted
  beside them; the copy left clean at 8cced5a9; 21 minutes). **Verdict: ready for its full runs; all seven
  first findings fixed; the new design held in every mix of updates it tried** (12 random runs of 80
  updates at the real bound and at a bound of 3, with feed-only updates, normal ones and full reads mixed:
  the feed equal to a full read after every step, and a version and state captured before a step reading
  exactly as before). The race detector belongs on `internal/viewer` in the full runs (the atomic box).
- **The three trees side by side at 600,000 messages, the same hour (base, the piece as first reviewed, the
  fixed tree):** 8,000 named by kind 2: 140.6, 218.3, 152.2 ms (the added read 0, 63.4, 8.2 ms); one text
  edit: a new version 0, 5, 0 of 5; the library's next ask 5.7 to 6.7, 120 to 131, 4.5 to 7.5 ms; the full
  read 3,996, 4,273, 4,205 ms (inside the noise of a busy PC); an update with nothing new 7.9, 8.2, 8.1 ms.
  A feed-only update of 100 first edits: 10 to 12 ms; the update past the cap: 36.8 ms.
- **New, both minor:** "as of" can name a read one update newer than the lists shown (the order of two
  loads); an update that moved only feed rows is counted as "found nothing to change" in the counts file.
- **Decided: both fixed in a last small round, with the main head merged in by the same coder**
  (`BRIEF-B6-changes-last.md`; a fresh Opus coder since 09:25, in `wt-b-faces`). The main head now holds the
  compose box (entry 22, merged as 53ee5bcd) and the door (G8, efac56ff): the feed meets the compose box
  in `server.go`, `viewer.go`, `app.css`, `api.js`, `chat.js` by a few lines; the coder resolves only
  conflicts where both sides' lines plainly stay and stops on anything else. No further independent look:
  I read it.
- **Then, by ONE Sonnet clerk:** the full runs once, `ix-tools/full-runs.sh wt-b-faces runs-b12 "viewer"
  "viewer"` (the viewer whole on Windows, about 6.5 minutes; the race detector on the viewer, about 42
  minutes: the refresher stores into a box that requests read at the same time), the two commands' tests
  beside it. **The owner was told this plan in one line at 09:05.** Then entry 23.
- **ENTRY 22 IS MERGED** (the compose box, 53ee5bcd on the main branch) and **G8, the door, is merged**
  (efac56ff). `wip/b-door` now waits only for K14. **For its merge of the head, noted now:** the compose
  box came in as ONE commit, so git will see the `act*` files as added on both sides; where the main
  head's file equals the one at 31362d5d (check each with `git diff 31362d5d <head> -- <file>`), the
  branch's side is the newer and is taken whole; anything else is read by me.
- **Take-over:** running: the feed's last-round coder (`wt-b-faces`), the gate's coder (`wt-b-join`).
  Waiting: `wip/b-door` bb5454ce for K14 on the main head.

## 09:31 (11-16) THE FEED'S LAST ROUND AND THE MERGE OF THE HEAD ARE BACK (209615f0), VERIFIED; ITS FULL RUNS WAIT FOR ROOM ON THE PC
- **About 09:30 the coder handed back** (6 minutes): `wip/b-changes` 209615f0, pushed; it holds the main
  head f7d6ca63. **Verified by me:** the copy `wt-b-faces` clean on that head; `private/wip/b-changes` is
  209615f0; the main head is an ancestor; against the main head only `internal/viewer` differs.
- **The two fixes:** "as of" is loaded before the version and the feed's state, and the refresher now
  stores its time only after what it read is published (the coder found the request side alone was not
  enough: read by me, the difference of `viewer.go` and `changes.go`: right); a count of its own,
  `index.feed_only`, for an update that kept the version and moved only feed rows. Two tests.
- **The merge was not clean: three conflicts, each two sides' lines kept side by side** (a field of the
  `Viewer` struct, the two blocks of styles, two imports in `chat.js`); `server.go` merged by itself.
  **One thing the merge did not show:** the compose box's `TestActNilDrawsNothing` named `deleted.js`,
  which this piece replaced by `changes.js`: the name in that test's list is changed (a commit of its
  own). After it: `TestChanges|TestDeleted|TestAct|TestWall|TestLAN|TestLive|...` ok 31.0 s, 99 passed;
  gofmt, vet, the build and `node --check` clean; no test function removed.
- **The full runs: started by ONE script call of mine** (the session's scratch `fullruns-gated.sh`, in the
  background: it checks the copy's head and that it is clean, waits until the PC has 5 GB free and under
  80% CPU, looking once a minute for at most 45 minutes, then runs `ix-tools/full-runs.sh wt-b-faces
  runs-b12 "viewer" "viewer"`, the two commands' tests and vet). At 09:31 the PC had 3.8 GB free with another
  track's container running, so it waits (`runs-b12/waited.txt` has a line a minute; `started.txt` when
  it begins; `ended.txt` when done; `not-started.txt` if it gave up). The owner was told the plan at 09:05.
- **Take-over:** running: that script (if this session ends before it starts the runs, start them anew:
  `bash ix-tools/full-runs.sh wt-b-faces runs-b12 "viewer" "viewer"` with `FFMPEG_PATH` set, when the PC
  has room), the gate's coder (`wt-b-join`). When `runs-b12/ended.txt` exists and every log ends "exit 0"
  with no "WARNING: DATA RACE" and no "--- FAIL": entry 23 in `MERGE-QUEUE.md` for `wip/b-changes`
  209615f0 (the model: entry 22; reviews `wt-b6-review-C-scratch/REVIEW.md` and `REVIEW-2.md`; the three
  trees' numbers; not tested: the page in a browser after the merge, long real texts, a real catalogue),
  the board's line, a message, the row. Waiting: `wip/b-door` bb5454ce for K14.

## 09:34 (11-16) THE OWNER (09:33): "You might not get 5gb free with everything else going on. Run it sooner if you can": THE FEED'S FULL RUNS ARE STARTED
- The waiting script was stopped (it had not started anything) and started again with the room it asks for
  lowered to 2.5 GB free (one script call, in the background): the copy's head and that it is clean are
  checked first; then `ix-tools/full-runs.sh wt-b-faces runs-b12 "viewer" "viewer"`, the two commands' tests
  and vet. At 09:33 the PC had 3.4 GB free; the other track's race container held 235 MB.
- **Take-over:** `runs-b12`: `started.txt`, `win-viewer.log`, `race-viewer.log`, `win-cmd.log`,
  `win-vet.log`, `ended.txt`; each log ends "exit N". The race run needs about 42 minutes.

## 09:46 (11-16) THE WINDOW'S GATE ROUND IS BACK (8e5664a9), VERIFIED AND READ; THE REVIEWER'S SECOND LOOK RUNS. TWO RULE BREAKS BY THE CODER, SAID TO THE OWNER
- **About 09:45 the coder handed back** (53 minutes): `wip/b-winpages` 8e5664a9, pushed. **Verified by me:**
  the copy `wt-b-join` clean on that head; `private/wip/b-winpages` is 8e5664a9; 27 files, all in
  `internal/window` and `cmd/tgarchive-window` (3,165 insertions, 224 deletions).
- **RULE BREAKS, by its own report (to be told to the owner plainly):** (1) **it ran `find /` in Git Bash
  for about 2 minutes**, looking for a header file: that walks every mounted drive, so it may have LISTED
  folders under `E:` and other places no session may list; it opened no file and printed nothing (0
  matches), then stopped it. (2) It crashed the renderer on purpose in two runs: each left a crash dump of
  invented pages in its scratch engine folder, and the engine's crash reporter works outside the gate and
  may have sent them (not measured); the folders are deleted. Also: it unpacked the mpv archive of 11-15
  found in another session's scratch into its own scratch (deleted after) and used the ffmpeg on PATH; one
  viewer run used a build without one switch. **Rule for every brief from now: no search over a whole
  drive; look only inside the copy, the scratch folder and the toolchain's folder; no step that crashes
  the engine on purpose.**
- **The gate as built (`gate.go`, read by me whole):** a listener of the window's process on 127.0.0.1:0;
  the rule `gateForwards` (plain http, an absolute address, no user part, no upgrade, the host exactly an
  allowed `127.0.0.1:PORT`); everything else 403 and counted, `CONNECT` included (so every https and every
  WebSocket, also to an allowed port); a reverse proxy that streams, a `tcp4` dial to an allowed address
  only, checked again in the dial; the set fixed once. A request in a browser's own form (no absolute
  address) is refused, so a page in an ordinary browser cannot use it. Sound as written.
- **Measured over four windows (each after the gate was on):** 0 connections at a port nobody named for
  every probe kind (26 in the pages mode, 25 in the viewer's); 0 requests refused at the gate at start
  (the review saw the engine's own 3 there before the extra switches); all 47 TCP attempts to 127.0.0.1;
  0 UDP packets with the review's WebRTC step (a fixed script removes the constructors). **The cost in
  the viewer's mode on an invented archive:** play to first picture 24 ms at the median over 8 plays
  (before the gate, on record: 55 ms; other clips, so "looks like no cost"); the library page's first
  load 41 ms; 200 thumbnails 28.4 ms direct and 59.1 ms through the gate one at a time (0.15 ms more an
  answer); a video still goes to mpv as a file.
- **Left, failing its own strict checks:** UDP connects of the engine's IPv6 reachability check (about 31
  in two minutes; whether a packet is sent was not measured); two single-label names asked of the
  engine's own resolver in each pages run (no lookup followed); crash dumps kept (turning the reporting
  off needs an options object: not built). **The final build was not run in a window.**
- **The other decisions built:** names of its own for the pages mode; autofill, password saving and the
  reputation check off and read back; the 10 s watch; the 500, the 502 and the 15 s; port 80 refused;
  a `text/plain` download from a named address saved; the link line; the user agent's word. No WebSocket
  works in the window (said to pages with the next message).
- **09:46 the first reviewer was sent its second look** (one message; `REVIEW-2.md` beside `REVIEW.md` in
  `wt-b6-review-W-scratch`): what still leaves the PC by its own measurement and which residuals to
  accept; the gate (forwarding what it must not, reached from outside the engine); its eleven findings;
  what the round opened. No window with the gate off; at most three windows.
- **The feed's full runs at 09:45:** `runs-b12/win-viewer.log`: ok, 422.1 s, exit 0; the race run goes.
- **Take-over:** running: the window's second look (`wt-b-join`, read-only), the feed's race run
  (`runs-b12`). After the second look: one last round (its findings; which net-log checks fail the run
  and which only print; the final build run once in a window in each mode), then full runs
  (`internal/window` whole and under the race detector, the command), an entry. Waiting: `wip/b-door`
  bb5454ce for K14.

## 10:06 (11-16) THE WINDOW'S SECOND LOOK IS BACK: "YES" FOR BOTH MODES AFTER ONE FIX; ONE WAY OUT OF THE PC LEFT (CRASH DATA THROUGH WINDOWS); A LAST ROUND RUNS
- **About 10:04 the reviewer's second look came back** (`wt-b6-review-W-scratch/REVIEW-2.md`; probes in
  `probe2/`, printouts `out2-gate.txt`, `outG.txt`, `outH.txt`, `outV.txt`, `flagsG.txt`; three windows,
  all with the gate on: 306 s, 27 s, about 1 s; no search outside the copy and its scratch; the copy left
  clean at 8e5664a9; 19 minutes). **Verdict: the launcher may start the pages mode once N1 is fixed; the
  viewer's window may be rebuilt for the owner; one residual can leave the PC, only after a crash.**
- **What it measured with the gate on (5 minutes 6 s, 180 s of it idle, by the engine's own net log):** 0
  TCP connection attempts off 127.0.0.1 (28 attempts, all to this PC); **0 UDP datagrams** (17 UDP
  connects of the IPv6 reachability check to one public address, 0 bytes-sent events from any socket; the
  same log showed 19 such events for real traffic in its first look, so their absence means something;
  a connect on a UDP socket sends nothing); 0 names asked, 0 resolver jobs or DNS transactions; 0 requests
  naming a host refused at the gate at start, idle or the end. 13 kinds of request aimed at a port nobody
  named: 0 connections. WebRTC and WebTransport undefined in a page, a blank frame and a `srcdoc` frame,
  after a page's attempts to bring them back: 0 packets. The gate under a raw socket: every odd form of
  an address, a smuggled request, `CONNECT`, upgrades, a page of an ordinary browser: refused; the first
  byte of a stream passed at once. The viewer behind the gate still sees its own Host, the page's Origin
  and its token.
- **Its first findings now:** F1 to F4, F6, F8, F10 fixed (measured or read back); F5 by the watch (tested
  alone); F7 a timer (not measured); F9 unchanged (the launcher's side); F11 open as N2.
- **New:** N1 confirmed: a frame's navigation takes the place of the navigation the pages view follows, so
  a failed page can go unseen. **N2 plausible: the engine's crash data can leave through Windows' own
  error reporting, outside the gate** (the dump is written locally; the handler has no upload address;
  by WebView2's documentation the data follows the system's consent unless the environment option
  `IsCustomCrashReportingEnabled` is on; this PC has Windows Error Reporting on and diagnostic data at
  the required level). N3 confirmed: a 503 with the app's own words is hidden behind the window's line.
  N4 plausible: an allowed text download keeps a name the page chose. N5: the link line shows a page's
  path words (low). N6: a server can raise the engine's own sign-in dialog. N7: a slow request holds the
  gate open. N8: the wall still lets `net.Resolve*` and packet listeners through. N9: the self-check's net
  log can stay behind.
- **My decisions (`BRIEF-B6-window-last.md`):** N1, N3, N4, N6 (the gate drops `WWW-Authenticate`), N7, N8,
  N9 fixed; **N2 built now: the options object that switches the engine's crash reporting to "custom"**
  (native code: each slot from the binding's sources or Microsoft's header, never from memory; proven by
  the window starting and the self-check passing, NOT by a crash); N5 kept as it is (the address is what
  the person copies). The self-checks fail on a datagram, a TCP attempt, a resolver job, a named host at
  the gate, a connection at the unnamed port; they only print UDP connects, names answered inside the
  engine, dumps found. The final build is run once in a window in each mode and must exit 0.
- **10:06 a fresh Opus coder (high effort) started on it** in `wt-b-join`; the rules the last coder broke
  stand first in its brief. The track's own mpv folder was copied by me into the session's scratch
  (`mpv-tool`, 122 MB) for the viewer's self-check. **No third independent look: I read N1, N3 and the
  options object.**
- **Then:** full runs once by a clerk or one script call (`internal/window` whole on Windows and under the
  race detector: the gate is concurrent code; the command's tests), an entry; after its merge new builds
  into the track's `bin`.
- **Take-over:** running: this coder (`wt-b-join`, `wip/b-winpages`), the feed's race run (`runs-b12`:
  the Windows part ended ok, 422.1 s). Waiting: `wip/b-door` bb5454ce for K14.

## 10:21 (11-16) THE FEED'S FULL RUNS ARE CLEAN; ENTRY 23 IS LISTED, READY; message 116
- **The runs (`runs-b12`, 09:34:01 to 10:19:57; one script call of mine; the logs read by me):** whole
  `internal/viewer` on Windows ok 422.1 s, exit 0; the race detector on `internal/viewer` ok 2,728.5 s,
  exit 0, 0 "WARNING: DATA RACE", 0 "--- FAIL"; `cmd/tgarchive` ok 9.7 s, `cmd/tgarchive-window` ok 2.6 s;
  vet exit 0; gofmt lists nothing. The copy `wt-b-faces` clean at 209615f0.
- **Against the moved main head (b8dd4abe):** it changed no file of `internal/viewer` and neither viewer
  command since f7d6ca63; `git merge-tree`: clean.
- **Entry 23 written at the end of `MERGE-QUEUE.md`** (one script call from my draft: it needed my words):
  the page, the index's design beside the version, the count on the old archive, both reviews, the three
  trees' numbers, the runs, the merge's three conflicts, what is not verified. Board: the "Waiting, READY"
  line, message 116 (the integrator; pages: what changed for G11 since the gate), my row.
- **Take-over:** running: the window's last-round coder (`wt-b-join`, `wip/b-winpages`). After its
  hand-back: verify, read N1, N3 and the options object, the full runs once (`ix-tools/full-runs.sh
  wt-b-join runs-b13 "window" "window"` and the command's tests; the race run of `internal/window` is
  short), entry 24, then new builds into the track's `bin` once it is merged. Waiting: `wip/b-door`
  bb5454ce for K14 on the main head.

## 10:41 (11-16) THE WINDOW'S LAST ROUND IS BACK (f0e49be5), VERIFIED AND READ; ITS FULL RUNS ARE CLEAN; ENTRY 24 IS LISTED, READY; message 117
- **About 10:38 the coder handed back** (33 minutes): `wip/b-winpages` f0e49be5, pushed, two commits on
  8e5664a9. **Verified by me:** the copy `wt-b-join` clean on that head; `private/wip/b-winpages` is
  f0e49be5; 14 files this round (1,213 insertions, 111 deletions), 31 against the base 6af0c09a, all in
  `internal/window` and `cmd/tgarchive-window`; no process of its left.
- **Built as decided:** only a top-level navigation is followed (the review's frame case shows the line in
  the real window); **the options object that sets the engine's crash reporting to "custom"**
  (`options_windows.go`; the layout read by the coder from two public bindings and Microsoft's reference
  through the web-reading tool, since neither the binding nor the module cache has it: an outbound read of
  public pages by the coder, not by the app; the loader asked for exactly its interfaces and the option
  reads back TRUE; both are failing checks now); a 500 or more with a committed document is shown as it
  is; a download's name is the window's own (`tgarchive-<date>-<time>.txt` in Downloads, never over a
  file); the gate drops `WWW-Authenticate`; a read bound of a minute; the wall refuses name lookups,
  packet listeners and any listener not on `127.0.0.1`; the net log's folder removed after the engine is
  gone; the self-checks fail on datagrams, TCP attempts, resolver jobs, a named host at the gate, and only
  print UDP connects, names answered inside, dumps found. **It also removed the viewer's self-check's own
  step that crashed the renderer on purpose** (a wall rule refuses it now).
- **The final build in a real window, three times, each with the gate on:** pages 108 checks, 0 failed,
  exit 0 (twice: once on the final build); the viewer's on an invented archive with real ffmpeg and mpv:
  61 checks, 0 failed, exit 0 (11 of 11 clips played; 10 starts, median 48 ms to the first picture; the
  gate forwarded 83 requests and refused 0). Net log, pages: 0 datagrams, 32 UDP connects (printed only),
  0 resolver jobs. Why the reviewer's viewer self-check had ended after a second: it takes ffmpeg only
  from `-ffmpeg` or `FFMPEG_PATH`; it now says so.
- **My read:** `options_windows.go` whole (the two interface ids and the slots are the ones I know for these
  interfaces; getters only, strings from `CoTaskMemAlloc`, every other interface refused), the pages
  view's frame and 5xx rules. Right as written. **No third independent look.**
- **The full runs (`runs-b13`, 10:39:35 to 10:39:55; one script call of mine; the owner told in one line
  first):** whole `internal/window` on Windows ok 5.6 s; `cmd/tgarchive` ok 7.4 s, `cmd/tgarchive-window`
  ok 2.3 s; the race detector on `internal/window` ok 6.2 s, no data race (the Linux build: the gate, the
  rules, the net-log reader); vet of both packages and gofmt clean.
- **Against the main head 1d9cd6e5:** neither package changed since 6af0c09a; `git merge-tree`: clean.
- **Entry 24 written at the end of `MERGE-QUEUE.md`** (one script call from my draft). Board: the "Waiting,
  READY" line, message 117 (the integrator is asked to take it early; pages: the contract's last
  changes), my row.
- **Take-over:** nothing of this track runs. Waiting for the integrator: entries 23 and 24. **When entry 24
  is merged:** ONE Sonnet clerk builds `tgarchive.exe` and `tgarchive-window.build.exe` from the main head
  into the track's `bin` by the steps of this morning's entry (07:00; the [name removed] try of the viewer on an
  invented archive first; the 788ebf77 builds kept as `.bak`), and a line goes to the owner's list: the
  window is the gated one from its next start. Waiting for K14: `wip/b-door` bb5454ce (the wiring list is
  in the entries of 08:33 and 08:38). The session's scratch folder holds `mpv-tool` (122 MB, a copy of
  the track's own mpv folder for self-checks): remove it at the session's end.

## STATE FOR A TAKE-OVER (B6, 11-16 10:43): enough to take over from this block alone
- **The integrator's usage signal of 10:19** (88% of all models' week): finish what is in flight to its
  listing, start nothing new, write this block, go quiet. **Read by me late, at 10:42** (first written here as 10:50, from memory) (I read hand-backs
  and wrote to the board without reading it between 10:05 and 10:42: the lesson B4 left, not kept). What
  I did after 10:19 was inside it: the window's coder was already running and handed back at 10:38; its
  full runs were one script call of 20 s; entry 24 was listed. No agent was started after 10:19.
- **Running:** no agent. ONE background script of this session, no model turn in it:
  `build-after-merge.sh` in the session's scratch folder. It looks at `private`'s main branch every 3
  minutes for at most 4 hours; when the head holds `archiver/internal/window/gate.go` (entry 24 merged) it
  checks the head out detached in `wt-b-join`, builds `tgarchive.exe` and `tgarchive-window.build.exe`
  (`CGO_ENABLED=0`, `-trimpath`), tries the viewer on an invented archive (port 8796; it must answer 200 and
  stop), keeps the 788ebf77 builds in the track's `bin` as `.788ebf77.bak`, places the new ones, compares
  them, and puts `wt-b-join` back on `wip/b-winpages`. Its lines: `build-gate/result.txt` beside it. **If
  this session is gone when entry 24 merges, a clerk does the same by the steps of the 07:00 entry.**
- **Committed and pushed, all copies clean:** `wip/b-changes` 209615f0 (`wt-b-faces`; entry 23, READY);
  `wip/b-winpages` f0e49be5 (`wt-b-join`; entry 24, READY); `wip/b-door` bb5454ce (`wt-b-viewer`; not
  listed); `wip/b-compose` 31362d5d (`wt-b-window`; merged as 53ee5bcd); `wip/b-edits` 1edb307f (parked).
  The notes are committed on `notes`.
- **Next, in order, when the signal is lifted:**
  1. **After entry 24's merge:** check `build-gate/result.txt` (or build by a clerk); verify the two files
     in the track's `bin` by `go version -m` (the main head's commit, not modified); then one line on the
     board's list for the owner: the viewer's window (`b\b-window.cmd`) is the gated one from its next
     start; the owner's folder is the integrator's to rebuild.
  2. **When K14 is on the main head: the pass-through's wiring** (a fresh Opus coder in `wt-b-viewer`; the
     list is in the entries of 08:33 "what the wiring stage now holds" and 08:38, and Core's message 106):
     merge the main head into `wip/b-door` (the compose box came in as one commit: for each `act*` file
     shown as added on both sides, check `git diff 31362d5d <head> -- <file>` is empty and take the
     branch's; entry 23 meets it in `viewer.go`, `server.go`, `chat.js`); the two commands hand
     `viewer.NewActDoor` a wrapper over `actdoor.ReadDoorFile` on the opened catalogue's folder (the file's
     name looked for first; ok false for every error); **the ledger check by `catalog.ActKey` IN PLACE OF
     the click-time stopgap** (with the key memory a second try is answered with the first try's click);
     the state's `key_ref` falling back to `ActKey`; the state's new fields; a caption judged by the
     viewer with `CaptionMax`; "empty" and "too long" as Core gives them; one end-to-end test in
     `internal/acttest` (the collector's rig, the real door, the pass-through: one click, one request at
     the fake Telegram; a wrong secret, none; a lost answer and a second try under one key, one request);
     then the same reviewer's third look (its scratch: `wt-b6-review-D-scratch`), full runs (the viewer
     whole and under the race detector, about 50 minutes; `internal/acttest`; the commands), the entry
     that makes the seam live. **The first real click is the owner's, in Saved Messages on the test
     account.**
  3. Later, not started: one window with the viewer as a place in it (the pages' window and the viewer's
     are two today); `TestTimingUnderWriteLoad` without real time; the features FEATURES marks "later".
- **For the owner, open:** the NAS thumbnail measuring run (folder `nas-thumbs`); `-Lan` from the window
  after a password is set in Settings. Said to the owner today: the engine's own requests in the viewer's
  window until the gated build is in; a coder's search over every drive; two crash dumps of invented
  pages; one possible DNS lookup of a reserved name.
- **In the session's scratch folder, to remove at the end:** `mpv-tool` (122 MB, a copy of the track's mpv
  folder), `build788`, `build-gate`. The reviewers' scratch folders in the project folder
  (`wt-b6-review-C-scratch`, `-D-`, `-W-`) hold the reviews for `docs/review` and their probes.
- **Lessons of this session (my reading):** re-read the board at EVERY hand-back, also when four agents
  hand back in an hour; a brief's first lines forbid a search over a whole drive, a crash on purpose and
  host names in probes; a review that measures a program without its guard lets out what the guard is
  for: say so to the owner before; a stopgap check must be written down as "to be replaced", with the
  reason, the moment it is made.

## 10:46 (11-16) ENTRIES 23 AND 24 ARE MERGED; THE GATED BUILDS ARE IN THE TRACK'S `bin` (by the waiting script; checked by me)
- **The main head is b6dd5e66:** entry 23 merged as 1d9cd6e5 (the Changes page), entry 24 as b6dd5e66 (the
  window's gate and the pages mode).
- **10:45 the waiting script ran to its end** (`build-gate/result.txt`: the head holds the gate; both built;
  the tried viewer answered 200, its Changes page 200, and stopped; both placed; the 788ebf77 builds kept
  as `.788ebf77.bak`). **Checked by me (one command):** in the track's `bin`, `tgarchive.exe` is
  `cmd/tgarchive` (24,859,648 bytes) and `tgarchive-window.build.exe` is `cmd/tgarchive-window`
  (24,209,408 bytes), both stamped b6dd5e66, not modified; `wt-b-join` is back on `wip/b-winpages`, clean;
  no `tgarchive` process of mine runs.
- **The owner's list has its line** (for information: the window is gated from its next start; the Changes
  page is in it; what is not proven about crash data). My row says the same; the owner's folder is the
  integrator's to rebuild.
- **Take-over:** nothing of this track runs and nothing waits in the background. Next, only when the usage
  signal is lifted and K14 is on the main head: the pass-through's wiring (point 2 of the block above).

## 14:19 (11-16) THE HOLD IS LIFTED AND K14 IS ON THE MAIN HEAD: THE PASS-THROUGH'S WIRING IS WITH A CODER; message 128
- **14:15 the integrator (the session `archiver-integrator-4`, by a message to this session):** K14 is on the
  main head (e9b8c540, schema step 25, with K16); no hold stands since 13:47 (the owner: "Usage reset. Go as
  needed"); the PC is the limit (1.4 GB free at 14:02). **Checked by me against the repository before
  acting:** the main head is e9b8c540; `catalog.ActKey`, `Collector.ClickState`, `actdoor.ReadDoorFile`,
  the door's routes and its adapter are on it; my four copies are clean on their heads; the PC at 14:17:
  1.3 GB free, 68%.
- **Read by me before the brief:** the board's messages since 10:46 that concern the viewer (Core's 126: the
  final entry points; pages' 121: the launcher as built; copies' 125 and 127); `core-door-REPORT.md` section
  2 on the main head (a known key answers its click before every other check; a number means the click's
  row exists; `ClickState`'s fields and its why words; the door's errors); `schema_actkey.go`'s read door;
  the door's JSON names in `server/clicks.go`.
- **What the merge of the head into `wip/b-door` meets (looked at by me, `git merge-tree`): 11 conflicts.**
  Seven files added on both sides (the compose box came in as one commit): six equal 31362d5d on the main
  head, so the branch's side is taken whole; `act_test.go` differs there by one line (`deleted.js` became
  `changes.js`). Four with both sides' lines to keep (`server.go`, `viewer.go`, `app.css`, `chat.js`).
- **14:19 ONE Opus coder (high effort) started:** `BRIEF-B6-door-wiring.md`, in `wt-b-viewer` on `wip/b-door`
  (bb5454ce). Its steps: the merge; the number believed by `catalog.ActKey` IN PLACE OF the click-time
  stopgap; the state read's `key_ref` falling back to `ActKey`; the caption judged by the viewer, a wait's,
  the slow mode's and the cap's time shown before a click (by the collector's own clock); the two commands
  hand `viewer.NewActDoor` a function over `actdoor.ReadDoorFile` (the name looked for first, "no door"
  for every error); an end-to-end test in the new `internal/acttest` (at least the viewer's routes against
  the REAL door routes over a recording seam; the whole chain to the fake Telegram if the collector's rig
  can be built from exported pieces: it edits no file of another track and says which export it would
  need). Its load rule for today: one go command at a time, `-p=1`, a memory limit, wait while under
  1.2 GB free.
- **Board:** message 128 (the integrator; Core and pages: a rig export may be asked; copies answered: the
  viewer's side-files rule is about the catalogue only, never `decisions.sqlite`); my row.
- **The session's scratch folder moved** (the app restarted the session's folder): the scripts `msg.py`,
  `row.py`, `list.py`, `fullruns-gated.sh` are copied into the new one.
- **Take-over:** running: that coder (its commits pushed as it goes: `git log bb5454ce..private/wip/b-door`).
  After its hand-back: verify the copy and the pushed head; read the merge's result for the four mixed
  files, the key check and the commands' wrapper; send the reviewer of the pass-through its third look
  (its scratch `wt-b6-review-D-scratch`; if that agent cannot be resumed, a fresh Opus reviewer on
  `BRIEF-B6-door-review.md` plus both reviews); fixes; full runs once by one script call
  (`fullruns-gated.sh wt-b-viewer runs-b14 "viewer acttest" "viewer" <head>`: the viewer whole about 7
  minutes, its race run about 46; the owner told in one line first); then entry 25, which makes the seam
  live, and new builds into the track's `bin` after its merge.

## 14:45 (11-16) THE WIRING IS BACK (e6223482), VERIFIED; THE REVIEWER'S THIRD LOOK RUNS
- **About 14:44 the coder handed back** (25 minutes): `wip/b-door` e6223482, pushed, five commits on
  bb5454ce; it holds the main head e9b8c540. **Verified by me:** the copy `wt-b-viewer` clean on that head;
  `private/wip/b-door` is e6223482; against the main head 29 files differ, all in `internal/viewer`,
  `internal/acttest` (new: `doc.go` and three test files), `cmd/tgarchive` and `cmd/tgarchive-window`; no
  process of its left (the two `collector.test` running at 14:44 are other tracks').
- **The merge:** exactly the eleven conflicts foreseen, each resolved as the brief said (the six files equal
  to 31362d5d on the main head taken from the branch; `act_test.go` with the one line; both sides in
  `viewer.go` and `app.css`; in `chat.js` both imports and the branch's line that attaches the box from
  the live poll; in `server.go` the branch's removal of the page filled once at the start, since it is
  filled per load). One test refitted: `TestActClicksReadBounded` (the catalogue now caps queued clicks at
  50 an account: it queues its 10,000 in batches).
- **Built, by its report:** the number believed by `catalog.ActKey` (the stopgap removed, for the queue and
  for send again); the state route's `key_ref` by one `ActKey` read for a key the viewer's memory does not
  hold; the caption judged by the viewer (an edit of a message with attachments refused above
  `caption_max`); a wait, the slow mode or the cap running for the kind refused before the door and told
  to the page in `not_before` (by the answer's own clock, at most a year ahead); the two commands' finder
  over `actdoor.ReadDoorFile` (the name looked for first; every error and a panic "no door"; read by me
  whole: right); **`internal/acttest`: a real viewer against the real door routes, AND the whole chain**
  (the collector run in the test by its exported `RunCommand` with its test seams against its fake
  Telegram: one click, exactly one send, a row "done"; the door's answer dropped in between, the same
  click again under its key: the first click's number, no second send; a wrong secret: nothing). **No
  export of another track was needed; no file of another track was edited.** The test copies two names
  that are not exported (the collector's sign-in setting key, the fake network's adapter name).
- **My read:** the finder; the chain test's setup (the collector it starts gets an empty environment, the
  test's temporary folder as its home, the fake Telegram's dialer and network: nothing real is reachable).
- **Given to the reviewer with weight: the caption rule.** Core's own note says a link preview's picture is
  stored as an attachment, so "has attachments" may refuse an honest edit of a long text with a preview
  before the door. The rule I want: refuse by the caption's limit only where the viewer is sure the text
  is a caption; let it go otherwise (Telegram refuses a too-long caption with one request).
- **Its doubts:** a retry under a known key can be refused by the viewer's own gates (a wait, the cap)
  before the door is asked; what "has media" covers; the chain test picks its port by opening and closing
  a listener.
- **14:45 the pass-through's reviewer was sent its third look** (the same agent, resumed; one message; it
  writes `REVIEW-3.md` in `wt-b6-review-D-scratch`): the whole path with both ends real; the caption rule;
  the holds; the finder and the old archive; the merge's resolution; the new test package; its earlier
  findings on this head.
- **Take-over:** running: that third look (read-only on `wt-b-viewer`). After it: one fix round (a fresh
  Opus coder) with the caption rule and its findings; my read; full runs once by one script call
  (`fullruns-gated.sh wt-b-viewer runs-b14 "viewer acttest" "viewer" <head>`; the owner told first); entry
  25; after its merge new builds into the track's `bin`.

## 14:55 (11-16) THE THIRD LOOK IS BACK: "YES, IT MAY BE MERGED WITH THE SEAM LIVE", FIVE SMALLER FINDINGS; ALL DECIDED; THE FIX ROUND RUNS; message 129
- **About 14:55 the reviewer's third look came back** (`wt-b6-review-D-scratch/REVIEW-3.md`; probes
  `probe_b6d3_test.go` with `overlay4.json`, the earlier probes refitted; the copy left clean at e6223482;
  8.5 minutes). **Verdict: yes, it may be merged with the seam live for the owner's first real click (a
  send in Saved Messages on the test account), on one condition: no other catalogue file sits in the test
  account's catalogue folder.** Across the whole path: no way for one click to become two messages
  without the owner changing the text; no way for the page to say "queued" for what was not; every lost
  answer it could place ends with one click and the box emptied. All its earlier findings are closed on
  this head (the stale program's number: closed by the key).
- **New:** (1) confirmed: a click queued under its key is not learnt by the state read while the collector
  is away (no account resolved: `key_ref` 0), and when it is back the viewer's own gates (the cap, a wait)
  refuse the retry before the door is asked, with a line that says nothing was sent; nothing goes twice
  unless the owner then changes the text. (2) confirmed by reading: the door file is found by folder only:
  a second catalogue in the same folder takes the other's door (another catalogue: a click could go to
  another chat for real; a copy: every click shows "failed" although sent). (3) confirmed: an honest edit
  of a long text whose message has a link preview is refused as a too-long caption (the catalogue records
  a preview's picture exactly as a sent one: nothing can tell them apart but an album). (4) the
  end-to-end test's helper sends again on "cap" or "wait" and so hides the viewer's own holds. (5) low:
  the finder resolves the folder of `-db` at every call.
- **My decisions (`BRIEF-B6-door-wiring-fixes.md`): all accepted.** 1: the key memory asked for each account
  of the chat when none is resolved; the page sends its uncertain key with every state read; **a key the
  catalogue knows goes straight to the door, past the viewer's own gates** (the door answers a known key
  first and still refuses another content). 2: **the door file names its catalogue (LENT LINES in
  `internal/actdoor/door.go` and one call in `collector/pages.go`, one separate commit, asked on the board:
  message 129)**; the finder answers "no door" unless it is the viewer's own; `filepath.Abs` once. 3: the
  caption's limit only for a message that is part of an album; the text's limit otherwise. 4: the test's
  helper fails on an unannounced hold; a step with the collector stopped and started again between the
  try and the retry. 5: words in the seam file.
- **14:55 a fresh Opus coder (high effort) started on it** in `wt-b-viewer`.
- **For the owner, with the entry:** one catalogue file per folder until the door file names its catalogue
  in the installed build.
- **Take-over:** running: that coder (`wip/b-door`; pushed as it goes). After it: verify; read decision 1 c
  (the path past the gates) and the lent commit; decide whether the path past the gates needs the
  reviewer's closing look (it rewrites a reviewed part: yes unless it is a few lines); the full runs
  once by one script call (`fullruns-gated.sh wt-b-viewer runs-b14 "viewer acttest actdoor" "viewer" <head>`
  and the commands; the owner told in one line first); entry 25.

## 15:23 (11-16) THE WIRING'S FIX ROUND IS BACK (e891d19c), VERIFIED AND READ; ITS FULL RUNS GO
- **About 15:21 the coder handed back** (28 minutes): `wip/b-door` e891d19c, pushed, three commits on
  e6223482 (the viewer's part; **"Lent lines: the door file names its catalogue"** f7a148b5; the finder
  and the tests). **Verified by me:** the copy `wt-b-viewer` clean on that head; `private/wip/b-door` is
  e891d19c.
- **Built as decided:** (1) the key memory asked for each account of the chat when none is resolved; the
  page sends its newest uncertain key with every state read; a key the catalogue knows goes straight to
  the door past the viewer's own gates (moved unchanged into `actGates`); the number still believed only
  by the key. (2) The lent commit: `actdoor.Door` gains `Catalogue` (a file's base name: 1 to 1,024 bytes,
  no separator, colon or control character), `Write` takes it (as a variadic parameter, to stay inside
  the two lent files: one test of the collector calls `Write` with two arguments), the reader takes a
  file without it as "not whole"; `collector/pages.go`: one line. The two commands' finder: `filepath.Abs`
  of `-db` once, the door taken only when its catalogue name is that file's base name (case ignored on
  Windows). (3) The caption's limit only when the message's row has an album; **through the real chain an
  edit of 1,500 units of a message with a file and no album is QUEUED: the collector judges every edit by
  the text's limit, as its report's section 2 says (the reviewer had read an older part): nothing to put
  to Core.** (4) The chain test sends each click as the page does (the state read first, an announced
  hold waited out, an unannounced "cap" or "wait" fails it), stops the collector after the lost answer,
  checks `key_ref` while it is away, starts it again (a new secret) and gets the first click's number
  under the key with no second send; a second viewer on a copy of the catalogue in the same folder
  answers "not here" and nothing is queued or sent; the collector's pages port is the system's choice,
  read from the door file.
- **Its tests:** the reviewer's two probes as tests fail on e6223482's code and pass now; the viewer's
  families 131 pass (node ran the page's harness); the four of `internal/acttest`; all of
  `internal/actdoor`; the collector's three door tests by name; `TestActDoorFind` in both commands; gofmt,
  vet of five packages, the build clean; no test function removed. Not tested: a browser; the known-key
  path for kinds other than a send; a real collector.
- **My read:** the click route from the key's take to the answer, whole (`act.go` around
  `handleActClick`): a key the catalogue knows skips `actGates` and is handed to the door once; the door
  answers a known key with its click or the word "key" and queues nothing (Core's report, section 2, and
  the chain test's restart step): so skipping the viewer's refusals there cannot send anything new. The
  lent commit whole (the difference of `door.go` and `pages.go`). Right as written. **No fourth look: the
  rewritten part is a dozen lines and its one risk is closed by the door's own guarantee and the chain
  test.**
- **No word yet from pages or Core on the lent lines** (message 129 of 14:55; pages has a session P5 since).
- **The main head moved to ab4d8858** (copies, pages, documents): none of this piece's files changed on it
  since e9b8c540; `git merge-tree`: clean.
- **The full runs: started by one script call of mine** (`fullruns-gated.sh wt-b-viewer runs-b14 "viewer
  acttest actdoor" "viewer" e891d19c`; the owner told in one line first; 2.8 GB free at the start): the
  viewer whole on Windows, `internal/acttest`, `internal/actdoor`, the two commands, vet; the race
  detector on the viewer (about 46 minutes).
- **Take-over:** running: those runs (`runs-b14`: each log ends "exit N"; `ended.txt` when done). When clean:
  entry 25 in `MERGE-QUEUE.md` for `wip/b-door` e891d19c (it makes the seam live; the lent commit named
  for the integrator and its owners; the three review looks; what only the first real click can show:
  the review's own list; for the owner's list: one catalogue file per folder until this build is
  installed, and the first real click's steps), the board's line, a message, the row. After its merge:
  new builds into the track's `bin` (the waiting script of this morning, pointed at a file of this piece,
  `archiver/internal/acttest/doc.go`).

## 16:08 (11-16) THE DOOR PIECE'S FULL RUNS: ONE VIEWER TEST FAILS, AND IT FAILS ON THE MAIN HEAD TOO (since copies' C13); a coder mends the test; message 135
- **The runs (`runs-b14`, 15:23:11 to 16:05:29; one script call of mine; the logs read by me):**
  `internal/acttest` ok 8.1 s; `internal/actdoor` ok 0.9 s; `cmd/tgarchive` ok 8.6 s,
  `cmd/tgarchive-window` ok 2.3 s; vet exit 0; gofmt lists nothing. **Whole `internal/viewer` on Windows:
  FAIL, 426.0 s, ONE failure; the race detector on `internal/viewer`: FAIL, 2,502.8 s, the same ONE
  failure, 0 "WARNING: DATA RACE".** The failure: `TestLostThroughIncrementalUpdate`
  (`staged_b5_test.go:510`: "1 full reads: every update was to be incremental").
- **It is not this piece's (run by me, by name, on a clean detached copy, `wt-b-window`, put back on its
  branch after):** the test fails on the main head e9b8c540 without my branch; it passes at 2a6073be and
  fails at bae71e5c, the copies track's C13.
- **The cause (read by me):** `catalog.WantAgain` now removes the look-alike edges held against a lost
  file's media (`lostLookAlike`); a removed `copy_edge` row is logged as kind 3 (`ChangeGone`: a row went
  away, of any of six tables), for which the viewer's index writer can only read everything again in
  full (`refresh.go`: `gone = true`). The page's result is right; that one update costs a full read
  (about 4 s at 600,000 messages, the library's listings and the marks started again).
- **Decided:** (1) the test is mended in `wip/b-door` to say what is true (no full read before the lost
  step; at most one at it; none after), with a comment: **a small Opus coder on an exact instruction since
  16:08** (only `staged_b5_test.go`; the named test and `TestLost|TestStaged` by name; pushed). Only a test
  file changes after the full runs, so no second whole run (the integrator's own rule); the named runs
  go into the entry. (2) Board message 135: the integrator, copies and Core told; asked: a kind of its own
  in the change log for a removed edge that names one of its media, so that the viewer redoes two media
  in place (a small viewer piece when the kind exists); and a cheap guard for merges that change
  `internal/catalog` (the viewer's index tests by name on the combined tree).
- **Take-over:** running: that coder. After it: verify (one test file; the two named runs' lines); fill
  entry 25 (the draft: the session's scratch `entry25.txt`; the runs' numbers above; the failure and its
  mend said plainly) and list it with `list.py`; the row; then the waiting build script after the merge.

## 16:12 (11-16) THE TEST IS MENDED (9fec0938); ENTRY 25 IS LISTED, READY: THE PASS-THROUGH WIRED TO THE DOOR; message 137
- **About 16:11 the small coder handed back** (3.5 minutes): `wip/b-door` 9fec0938, pushed; only
  `staged_b5_test.go` (+39, -3). **Verified by me:** the copy clean on that head; one file changed.
  It measured where the full read happens (a temporary log, removed): 0 full reads over the three
  refreshes before the lost step; 1 at the refresh right after `WantAgain` (the change log gained one
  kind-3 row; probable edges to the lost media 1 to 0: the edge that went is one the fixture puts there;
  the test's own exact edge stays); none after. The test now asserts: none before; exactly one at that
  step when a probable edge of the lost media went, none otherwise; none after; every other check as it
  was. By name: the test ok 1.4 s; `TestLost|TestStaged` ok 82.2 s; gofmt clean.
- **Against the main head 5d884fc2:** none of this piece's files changed since e9b8c540; `git merge-tree`:
  clean.
- **Entry 25 written at the end of `MERGE-QUEUE.md`** (one script call from my draft): it makes the seam
  live; the lent commit f7a148b5 named; the three review looks; the end-to-end test; the runs with the
  one failure said plainly, its cause on the main head and its mend; what is not verified; the owner's
  first real click. Board: the "Waiting, READY" line, message 137, my row.
- **No word from pages or Core on the lent lines** (message 129, 14:55) when it was listed.
- **One script waits, no model turn in it** (`build-after-merge.sh` in the session's scratch folder, started
  after this entry): it looks at `private`'s main branch every 3 minutes for at most 4 hours; when the head
  holds `archiver/internal/acttest/doc.go` (entry 25 merged) it builds the viewer and the window from that
  head in `wt-b-join`, tries the viewer on an invented archive (it must answer 200 and stop), keeps the
  b6dd5e66 builds in the track's `bin` as `.b6dd5e66.bak`, places the new ones and compares them; its
  lines: `build-door/result.txt` beside it.
- **Take-over:** nothing else runs. **When entry 25 is merged:** check `build-door/result.txt` (or a clerk
  builds by the steps of the 07:00 entry) and the two files' stamps by `go version -m`; then the owner's
  line on the board's list, WRITTEN WITH THE FILE TOOLS (a path in a shell string was mangled this
  morning): the first real click (the collector running on the test account from the rebuilt folder; the
  viewer's window on that catalogue; Saved Messages; a line of text, Enter; "Sending", then the message
  as the chat's own; say what was seen), and "one catalogue file per folder until every program is of
  this build". Then, when the catalogue's log has a kind for a removed edge (message 135): the viewer's
  side of it.

## 17:02 (11-16) ENTRY 25 IS MERGED (5a13119): THE SEAM IS LIVE; THE BUILDS ARE IN THE TRACK'S `bin`; THE OWNER'S ITEM FOR THE FIRST REAL CLICK; message 142 (the removed edge: a kind of its own)
- **17:00 the integrator merged entry 25** (5a13119; the lent commit read by it in Core's and pages' stead;
  the collector in place and the owner's folder rebuilt from it; "the whole viewer has no failure again").
- **17:01 the waiting script ran to its end** (`build-door/result.txt` in the session's scratch: the head
  holds the door piece; both built; the tried viewer answered 200, its Changes page 200, and stopped; both
  placed; the b6dd5e66 builds kept as `.b6dd5e66.bak`). **Checked by me (one command):** in the track's
  `bin`, `tgarchive.exe` is `cmd/tgarchive` (25,776,640 bytes) and `tgarchive-window.build.exe` is
  `cmd/tgarchive-window` (24,462,848 bytes), both stamped 5a13119, not modified; `wt-b-join` back on its
  branch, clean.
- **The owner's list: a new item, written through the file tools** (the text in a file, appended by a
  script; no control byte in it, checked): the first real click: start the app from its folder; the
  viewer's window on the test account; Saved Messages; one line, Enter; "Sending", then the line as the
  chat's own; what to do if a line says otherwise (the same text again is the same click; a changed text
  is a new message); what nobody has seen yet. **Not checked by anyone: that the folder's launcher starts
  the viewer's window on the collector's own catalogue file, so that the door is found** (the item's
  "no text box at all" case covers it).
- **Copies' answers to my 135 (messages 138, 139, 141; read 17:02, late for the first two):** I read the
  piece rightly: three statements remove `copy_edge` rows while an archive runs (the owner's "not the
  same": two; a lost look-alike: one); the judge never does. Copies built the catalogue's side at once
  (`wip/copies-24` ead8f212: a removed edge logged as kind 1 for both media): its reviewer found that this
  alone makes the viewer WRONG, not faster (on a kind 1 row my writer reads only the media's state; the
  index's edge lists only grow in an update: a removed edge would stay until the count check, up to 5
  minutes, and then the full read comes anyway). **Copies asked my choice: kind 1 for both media, or a
  kind of its own.**
- **Decided (message 142): a kind of its own, `ChangeEdgeGone = 6`, once for each of the two media** (with
  kind 1 the writer would read edges again on every state change a download writes). In my reader an
  unknown kind falls into the full-read branch, so a viewer built before kind 6 is slow, never stale.
  **It lands as ONE entry of mine on copies' branch:** when `wip/copies-24` writes kind 6, the viewer's
  side is cut from it (the index writer reads the named media's edges again and redoes its sets, the
  fold, the probable count and the stand-ins in place), one independent review (copies' reviewer's two
  findings as its first probes: `REVIEW-E24-edge-removed-log.md` in the project folder), the full runs
  (the viewer whole and its race run; the catalogue's whole run by copies' clerk steps), then the entry.
  The three viewer tests to set in it: `TestChangeLogEachChangeFollowed` (its case "a copy edge went
  away"), `TestLostThroughIncrementalUpdate` (back to no full read), `TestRandomUpdatesMatchFullRead`
  (edge removals in its random steps).
- **Board:** message 142; my row; the owner's item.
- **Take-over:** nothing of this track runs but one background look (below). Next: when
  `private/wip/copies-24` holds `ChangeEdgeGone`: brief the viewer's side (read first: `refresh.go`'s
  handling of edges in `apply`, how sets, the fold, `probablePairs` and the stand-ins are kept; copies'
  report and review of C19), one Opus coder in a copy of mine cut from that branch.

## 17:14 (11-16) COPIES' BRANCH WRITES KIND 6 (a584f184); THE VIEWER'S SIDE OF THE REMOVED EDGE IS WITH A CODER; message 144
- **17:12 my background look saw it:** `private/wip/copies-24` a584f184 has `catalog.ChangeEdgeGone = 6` (a
  removed copy edge, written once for each of its two media). Copies' message 143 (17:09) says the same:
  choice (2) taken; a clerk of theirs runs the catalogue's whole run on that head; it lands as one entry
  of mine.
- **Read by me before the brief:** copies' report on the branch (`copies-edgelog-REPORT.md`: every way a
  `copy_edge` row is deleted and what each logs; the three lines for the viewer); `refresh.go`'s edge
  code (an update only ever appends edges; `read` asks `MAX(rowid)` and reads in full when it fell);
  `check.go`'s count check; the table's definition.
- **A hazard found while reading, real since C13:** `copy_edge` is a plain rowid table: when the edge with
  the largest row id is removed, the next edge inserted takes that id again, and the index's "edges past
  the last id seen" never reads it; both guards assume ids only grow. In the brief as point 4: on an
  update that names kind 6 the last seen id is lowered to the largest that exists and the writer proves
  by one count that it holds exactly the table's edges up to it, reading in full only when it does not.
  Said to copies for their own readers (message 144 b).
- **17:14 ONE Opus coder (high effort) started:** `BRIEF-B6-edge-gone.md`, branch `wip/b-edgegone` from
  `private/wip/copies-24` a584f184, copy `wt-b-faces` (clean on the merged `wip/b-changes`). `internal/viewer`
  only: kind 6 read as "these media's edges again"; `apply` sets both media's lists and redoes the
  probable count and flags, the fold, the sets and the stand-ins for what was touched; a new index
  version; the two guards; the three tests copies named (`TestChangeLogEachChangeFollowed`,
  `TestLostThroughIncrementalUpdate` back to no full read, `TestRandomUpdatesMatchFullRead` with edge
  removals); the reused row id in two interleavings; numbers at 600,000 messages against the base's full
  read. The PC at the start: 7.5 GB free, 64%.
- **Take-over:** running: that coder (`git log a584f184..private/wip/b-edgegone`). After its hand-back:
  verify; read `apply`'s removal and the guards' rule; one independent review (a fresh Opus reviewer:
  `REVIEW-E24-edge-removed-log.md`'s two findings as its first probes; the reused row id; the index
  against a full read after any mix of adds and removals); fixes; the main head merged in (copies' schema
  step may need its number moved if another step merged first: copies' report says where); full runs
  once (the viewer whole and its race run; the catalogue's whole run is copies' clerk's: ask for its log);
  ONE entry with both sides.

## 17:42 (11-16) THE REMOVED EDGE: THE VIEWER'S SIDE IS BACK (25af0b2b), VERIFIED, AND WITH AN INDEPENDENT REVIEWER; copies lists its step by itself; message 147
- **About 17:40 the coder handed back** (27 minutes): `wip/b-edgegone` 25af0b2b, pushed, ONE commit on
  a584f184. **Verified by me:** the copy `wt-b-faces` clean on that head; `private/wip/b-edgegone` is
  25af0b2b; six files, all in `internal/viewer` (`refresh.go` +338, `check.go`, a new `edgegone_test.go`,
  three test files; 1,351 insertions, 47 deletions).
- **As built, by its report:** `readLog` collects the kind 6 ids of known files into a set;
  `readEdgesAgain` reads those files' edges in the update's own transaction by the table's two indexes,
  400 files a statement, up to the last edge row read before (newer rows come by the usual read, so no
  edge twice); `applyEdgesAgain` sets each named file's list to what was read (a change to an edge whose
  other file was not named is mirrored in that file's list, on a new copy), then redoes for every file
  whose list changed: the probable flags and `probablePairs`, the sets' contents (`finishSet`: the
  complete post's items and "held as a probable copy"), the stand-ins. **No relation joins sets in this
  code** (sets join only by identical file lists and a forward origin that names one post), so a removal
  splits no set. Such an update always makes a new version. **The guards:** the largest-row-id guard runs
  after the log is read and, with kind 6, lowers the last seen id instead of reading in full; the
  writer's count follows the removals; **the proof, only on updates that name kind 6: one `COUNT(*)` of
  the table up to the new last id must equal what the index then holds, else a full read**; the
  few-minutes count check leaves its edge comparison to the next update while kind 6 rows wait.
- **Its tests:** every door of copies' list followed by one update: 0 full reads and the index equal to a
  full read, with the fold, the probable page and the stand-in checked for the pair (the cascade of a
  deleted file: 1, by its kind 3); the reused row id in four interleavings (in place when the new edge
  comes one update later or touches a named file; ONE full read when the removal and an unrelated insert
  on the same id fall into one update; with the proof switched off for one run that case failed with an
  edge missing); 5,001 files named, one of them 5,000 times: 26 re-read statements, one count, 18.9 ms;
  the two random tests with removals mixed into every batch, the full-read count asserted exactly.
  **At 600,000 invented messages:** one removed edge 6.7 to 8.3 ms (a full read on the base: 3.2 to
  3.6 s); 5,000 removed edges of one lost file 31 to 36 ms; the proof's count over 100,000 edges 3.6 ms;
  the library's next ask after it about 120 ms either way (a new version, as after an added edge).
- **On its base two tests are in their older state** (the base predates today's last merges):
  `TestActClicksReadBounded` fails in its own set-up (the cap of 50 queued clicks; refitted on the main
  head with entry 25); `TestLostThroughIncrementalUpdate` is the form before my mend and passes with no
  full read. **Both are set when the main head is merged in: the mended test must go back to "no full
  read at any step".**
- **Its doubts:** the count proves the number of edges, not which ones (an unlogged removal and a reused id
  together would cancel); a removed edge from a file to itself always reads in full; the order of several
  reused ids mirrored into one unnamed file's list.
- **My read:** `readEdgesAgain` whole (the re-read by both indexes, the arithmetic of the proof). Given to
  the reviewer: the count's two sides (the writer counts every row read; the lists hold only edges between
  two known, different files: can they drift), the eight readers said to "follow automatically", the
  interleavings.
- **Copies' 146 (17:29):** its branch is at 761b88d6 (a584f184 with the main head merged in); the
  catalogue's whole run is clean; **with kind 6 its step is safe by itself** (my update tests pass
  unchanged on it: an unknown kind is a full read). It offered to list C19 alone. **Decided (message
  147): yes, copies lists C19 by itself; my side is an entry of its own, "merge after C19",
  `internal/viewer` only.**
- **17:42 an independent Opus reviewer (high effort) started:** `BRIEF-B6-edge-gone-review.md`, read-only on
  `wt-b-faces`, probes in `wt-b6-review-E-scratch`, it writes `REVIEW.md` there.
- **Take-over:** running: that reviewer. After it: one fix round (a fresh Opus coder) that also merges the
  main head in (with C19 on it by then, or copies' branch 761b88d6 if not) and sets
  `TestLostThroughIncrementalUpdate` back to no full read; a second look if the round rewrites `apply`'s
  part; full runs once (the viewer whole and its race run: about 55 minutes; the owner told first); the
  entry, "merge after C19".

## 18:00 (11-16) THE REMOVED EDGE: THE REVIEW IS BACK ("READY FOR ITS FULL RUNS", THREE LOW FINDINGS); ALL THREE FIXED NOW; a clerk removes two finished copies
- **About 17:58 the independent review came back** (`wt-b6-review-E-scratch/REVIEW.md`; probes
  `zz_review_e_test.go` with `overlay.json`, outputs `out-*.txt`; the copy left clean at 25af0b2b; 17
  minutes). **Verdict: ready for its full runs. No production path gives a wrong index: 600 random updates
  of edges of its own and 1,000 of the coder's random batches matched a full read every time**, every
  file's list compared unsorted too. The copies review's two findings about the viewer are closed.
- **Three findings, all LOW, all confirmed by a probe:** (1) the proof by count is fooled for good when an
  UNLOGGED removal (a tool with the trigger dropped) and a reused row id fall into one update with a
  logged removal: the two cancel in the count; no production code removes an edge without the trigger.
  (2) an unnamed file's edge list can end in another order than a full read's (two reused ids to one
  target in one update); every comparison of the package sorts lists and so is blind to it; cosmetic for
  three readers that walk a list in order. (3) the live record does not name posts whose edge-derived
  values changed, so an open chat page keeps a set's item count or a "probable" mark until the post
  changes otherwise; added edges always behaved so.
- **Its numbers:** the proof's count: 8 to 9 ms at 100,000 edges, 95 to 113 ms at 1,000,000 (only on updates
  that name kind 6); a hostile log of 100,000 kind 6 rows naming 50,000 files: 112 ms in place, 275
  statements, 29.8 MB; one removal at 120,000 messages: 2.6 ms against 567 ms for a full read. In its
  random mix 27% of updates read in full, all for a reused id between files no removal named (its mix
  reuses ids on purpose; the share in a real run is not measured).
- **Decided (`BRIEF-B6-edge-gone-fixes.md`): all three fixed now.** 1: a sum of `a + b` beside the count,
  in the proof and in the count check. 2: the mirrored additions in row id order, and the comparison with
  a full read gains each list UNSORTED. 3: a post whose files' edge lists changed is named in the live
  record, for a removed and an added edge. **18:00 a fresh Opus coder (high effort) started on it** in
  `wt-b-faces`; it merges no branch. No second look: three bounded changes; I read them.
- **The integrator (17:59, to every session):** the owner at 17:53: "Keep going"; successors for Core
  (K-5) and pages (P6); **each track may remove its own finished copies** (checked clean and equal to its
  pushed branch). M6 (schema step 26) is in its merge run; **C19 is step 27 after it, joined by the
  integrator by hand; my side follows as its own entry.** A whole `internal/server` run fails on five
  tests that read this PC's free disk space (49.4 GiB free against a floor of 50): pages' to mend.
- **18:00 ONE Sonnet clerk started on an exact instruction:** remove the two finished copies `wt-b-window`
  (`wip/b-compose`, merged as entry 22) and `wt-b-viewer` (`wip/b-door`, merged as entry 25): each only
  when clean, on its branch and equal to `private`'s; `git worktree remove` without force; no branch
  deleted. `wt-b-join` stays (the builds for the track's `bin` are made in it); `wt-b-faces` is in use.
- **Take-over:** running: the fix-round coder (`wt-b-faces`, `wip/b-edgegone`), the clerk. **Then, when C19
  is on the main head** (a look: `git grep ChangeEdgeGone private/claude/charming-feynman-vm2xia --
  archiver/internal/catalog/changelog.go`): a small Opus round: merge the main head into `wip/b-edgegone`
  (for every file of `internal/catalog` the main head's side is taken whole: the step's number moved;
  anything else: stop), set `TestLostThroughIncrementalUpdate` back to "no full read at any step" (the
  main head's form asserts one at the lost step), run the named tests and `TestAct`; then the full runs
  once (the viewer whole and its race run; the owner told first); the entry, "after C19".

## 18:13 (11-16) THE REMOVED EDGE'S FIX ROUND IS BACK (3bb6814f), VERIFIED AND READ; IT WAITS FOR C19 ON THE MAIN HEAD; two finished copies removed
- **About 18:12 the fix-round coder handed back** (13 minutes): `wip/b-edgegone` 3bb6814f, pushed, one
  commit on 25af0b2b; five files of `internal/viewer` (430 insertions, 50 deletions); it merged nothing.
  **Verified by me:** the copy `wt-b-faces` clean on that head; `private/wip/b-edgegone` is 3bb6814f.
- **Built as decided:** (1) the writer keeps the sum of `a + b` over the rows its count counts; the proof
  and the few-minutes count check ask `COUNT(*)` and that sum in one pass (`edgeProofSQL`) and read in
  full on a difference in either; a side effect: the count check now also catches the OLD blind spot (the
  newest edge removed unlogged and its id taken again before an update). (2) the mirrored additions are
  made after the per-file loop in row id order; **the package's strong comparison no longer sorts each
  file's edge list**, and every random test passes with it. (3) a post whose files' edge lists changed
  (an edge added or removed) is named in the update's live record.
- **The review's probes as tests** (`edgegone_fix_test.go`): four fail on 25af0b2b for the review's reasons
  (by an overlay of the base's files) and pass now. By name: `TestEdgeGone` (11), the two random tests,
  `TestChangeLogEachChangeFollowed`, `TestLive` (15), the index families (29): all pass; gofmt, vet, the
  build clean; no test function removed. **The proof's cost with the sum at 100,000 edges: about 8 to
  10 ms, against 3 to 6 ms for the count alone** (only on updates that name a removed edge and at the
  few-minutes check). An idea not tried: both through the covering index.
- **Its doubts:** it measured the PC and ran one test in one command once (the CPU read 90%); a mirrored
  removal still takes the first matching entry (order only, in one rare case: the same relation both ways
  between a named and an unnamed file); "the newest rows are the new ones" rests on SQLite giving a new
  row the largest id plus one; the live record grows by a file's places when it gains an edge.
- **My read:** the difference of `refresh.go` and `check.go`, whole: the sum's two sides take the same rows
  as the count's; the count check's comparison keeps its precedence; the mirrored additions pick each
  key's newest rows and append them in row id order; the live record's addition is once per file. Right
  as written. **No second independent look** (three bounded changes).
- **~18:05 the clerk removed two finished copies** (one Sonnet clerk, an exact instruction): `wt-b-window`
  (47 MB) and `wt-b-viewer` (50 MB), each clean, on its branch and equal to `private`'s before; no branch
  deleted. The track's copies now: `wt-b-faces` (in use), `wt-b-join` (the builds).
- **C19 is not on the main head yet** (the mirror's M6 is in its merge run before it). **One background look
  of this session waits for it** (every 3 minutes, at most 3 hours; no model turn until it ends).
- **Take-over:** when the main head holds the catalogue's step (`git grep ChangeEdgeGone
  private/claude/charming-feynman-vm2xia -- archiver/internal/catalog/changelog.go`): ONE small Opus
  round in `wt-b-faces`: merge the main head into `wip/b-edgegone` (every file of `internal/catalog` and
  `archiver/docs`: the main head's side whole, since the step's number moved there; anything else that
  conflicts: stop); set `TestLostThroughIncrementalUpdate` to "no full read at any step" (the main head's
  form of it asserts exactly one at the lost step when an edge went: my mend of this afternoon, now
  outdated by this piece) with its comments; by name `TestLost|TestStaged|TestEdgeGone|TestAct|TestWall|
  TestChanges|TestLive|TestRandomUpdatesMatchFullRead|TestChangeLogEachChangeFollowed`; push. Then the
  full runs once by one script call (`fullruns-gated.sh wt-b-faces runs-b15 "viewer" "viewer" <head>`: the
  viewer whole about 7 minutes, its race run about 46; the owner told in one line first); then entry 26
  ("after C19"; `internal/viewer` only; the review `wt-b6-review-E-scratch/REVIEW.md`; the numbers at
  size; what is not verified: the live page over HTTP, a real archive, the proof on a cold disk).

## 18:18 (11-16) THE OWNER'S FIRST REAL START OF THE APP (18:05 to 18:15): THE APP'S WINDOW ENDED BY ITSELF WHEN THE VIEWER'S WINDOW STARTED: AN INVESTIGATOR RUNS; the row answers 150 f
- **18:21 the integrator, by a message to this session, and its board message 150 (read by me whole):** the
  owner: "Well, deeply unsatisfying so far" ... "a very ugly app, not fully functional, doesn't quit
  properly, and still runs in a browser, just a standalone one?". From the launcher's own log: at both
  starts with a saved setup the app's pages window ended by itself, exit code 0, after 8 s and after 4 s,
  each time in the second in which the launcher had also started the viewer's window (kind 1); at the
  first start, with no viewer, it lived 136 s. Both windows are `tgarchive-window.exe`. Also: a new
  launcher one second after the first Quit (not explained); X on the window leaves the app running (the
  launcher's design; "doesn't quit" to the owner). The other points of 150 are the pages track's (the
  Queue page's error on an empty catalogue, a wrong folder that cannot be changed, the look). **The
  integrator's word: until the folders are put right nobody tells the owner to choose a chat.** The
  catalogue the owner made is a NEW one in the app's folder, not the test account's.
- **18:18 ONE Opus investigator (high effort) started:** `BRIEF-B6-window-ends.md`, branch `wip/b-winfix` from
  the main head, copy `wt-b-join` (clean on the merged `wip/b-winpages`): read the launcher's starts and
  the window's every way to end with code 0; reproduce on a scratch folder (its own builds, scratch data,
  `LOCALAPPDATA`, `APPDATA`, `TEMP` redirected; at most eight real windows, each under 90 s); the cause
  to the line; mend the window's side with a test; write down the launcher's side for pages (it changes
  nothing in `internal/launcher`); by reading only: what the window can offer for "X quits or asks".
  **Its first rules: nothing of the owner's folders is opened, no process it did not start is touched.**
  At the start no `tgarchive` program was running on the PC by name (my look, counts only).
- **My row answers 150 f** (what the window's shell does and could do towards a native feel; nothing
  started before the owner's answer): it already has no browser gestures, no address, a fixed title, a
  remembered place; it lacks an icon of the app's own, a title bar that follows the theme, the page's
  name in the title, ONE window for the app's pages and the viewer, a styled opening line, and a way for
  the launcher to tell "closed by the person" from "stopped". The panes-not-tabs layout and the controls'
  look are the pages' own.
- **Take-over:** running: the investigator (`wt-b-join`, `wip/b-winfix`); one background look for C19 on the
  main head (then `wip/b-edgegone` 3bb6814f in `wt-b-faces` gets the head merged in, its full runs and its
  entry: the entry of 18:13 above has the steps). After the investigator's hand-back: verify; read the
  cause and the mend; tell pages on the board exactly what the launcher must change; a short independent
  look if the mend touches the instance rule, the jobs or the signals; the window's full runs (seconds);
  an entry, ahead of the edge piece.

## STATE FOR A TAKE-OVER (B6, 11-16 18:28): enough to take over from this block alone
- **Why now:** the integrator (18:30, by a message): this session's context is at 94%; write the state,
  start no new piece; a fresh viewer session is asked of the owner. **The owner chose the app's shape:
  ONE window for the pages and the viewer** (`DESIGN-ONE-WINDOW.md` in the project folder; board messages
  151 to 153; pages, P6, leads the joint note). **Read those first; I have not read them** (no room left).
- **Running, two things:**
  1. **The investigation of the app's window that ended by itself at the owner's first real start**
     (board message 150 e 2). One Opus investigator, started 18:18, in the copy `wt-b-join` on the branch
     `wip/b-winfix` (cut from the main head). Brief: `BRIEF-B6-window-ends.md`. **Its hand-back comes to
     THIS session; it was told to write it also to `REPORT-B6-window-ends.md` in the project folder: read
     that file.** If the file is not there and the branch `private/wip/b-winfix` has commits, read them
     (`git log <main head>..private/wip/b-winfix`); if neither exists, start it anew from the brief. No
     cause is known yet. After it: verify the copy (clean) and that no process of its was left; read the
     cause and the mend; write to pages on the board exactly what the launcher must change; a short
     independent look if the mend touches the instance rule, the jobs or the signals; `internal/window`'s
     whole tests and race run (seconds: `fullruns-gated.sh wt-b-join runs-b16 "window" "window" <head>`
     and the command's tests); an entry. **With ONE window the launcher starts one program, which removes
     this fault by construction: the mend may still be needed until then; judge with pages.**
  2. A background look of this session at the main head for copies' C19 (it ends when the head holds
     `ChangeEdgeGone`; a fresh session does not get its word: look yourself with `git grep ChangeEdgeGone
     private/claude/charming-feynman-vm2xia -- archiver/internal/catalog/changelog.go`).
- **Waiting, built, reviewed, fixed, NOT listed: "a removed look-alike edge taken in place":**
  `wip/b-edgegone` 3bb6814f in the copy `wt-b-faces` (pushed; clean). Its steps once C19 is on the main
  head are in the entry of 18:13 above ("Take-over"): a small Opus round (merge the main head; every file
  of `internal/catalog` and `archiver/docs` from the main head's side; set
  `TestLostThroughIncrementalUpdate` back to "no full read at any step"; the named tests), the full runs
  once (the viewer whole about 7 minutes, its race run about 46: the owner told in one line first),
  entry 26 "after C19" (`internal/viewer` only; the review `wt-b6-review-E-scratch/REVIEW.md`; briefs
  `BRIEF-B6-edge-gone*.md`).
- **Merged today, five entries:** 22 the compose box (53ee5bcd); 23 the "Changes" page (1d9cd6e5); 24 the
  window's gate for both modes and the pages mode (b6dd5e66); 25 the pass-through to the collector's door
  (5a13119: the seam is live; never clicked for real). The viewer and the window built from 5a13119 are
  in the viewer track's `bin` (checked). The track's copies: `wt-b-faces`, `wt-b-join` (two finished ones
  were removed by a clerk). The notes are committed on `notes`.
- **Asked of this track and NOT done (the successor's first things, before any building):**
  1. **Board message 151 a and b:** is Saved Messages listed in the viewer on a NEW account's catalogue;
     are the unified stream, the deleted marks and "first seen here" as the roadmap says there. Check on
     an invented catalogue (`tgarchive fabricate -real-rows`, with the account's own chat) in a headless
     browser or by the viewer's JSON; say on the row what is and what is not; never from memory.
  2. **ONE window: this track's part of pages' joint note.** My few lines are on the board row (what the
     shell and the viewer's places need: one process carrying the viewer and taking the pages as named
     places; the gate's allowed set; one instance and data folder; the viewer's address handed to the
     pages; the viewer's own header hidden inside the app's; one theme; mpv only on the viewer's pages).
     They are a first reading, not a design: read `DESIGN-ONE-WINDOW.md`, `internal/window`'s two modes
     (`run.go`, `pages.go`, `shell_windows.go`, `gate.go`) and `cmd/tgarchive-window` before answering.
- **For the owner:** item 39 (the first real click) is ON HOLD: the catalogue the owner made at the first
  start is a new one, not the test account's, and the integrator asks that nobody send the owner to
  choose a chat until the folders can be changed. Said to the owner today, for the record: the engine's
  own requests to Microsoft before the gate; a coder's search over every drive; two crash dumps of
  invented pages; one possible DNS lookup of a reserved name; a path mangled in a board line for a
  minute. Still the owner's: the NAS thumbnail measuring run (folder `nas-thumbs`); `-Lan`.
- **Scripts of this session, in its scratch folder (copy what you need; a fresh session has another
  folder):** `row.py` (my board row), `msg.py` (a board message), `list.py` (an entry with its line and
  message), `ownerline.py` (an item on the owner's list), `fullruns-gated.sh` (the full runs when the PC
  has room), `build-after-merge.sh` (the builds into the track's `bin` after a merge).
- **Lessons of this session (my reading), beyond those in the block of 10:43:** when a full run fails, run
  that one test on the main head before blaming the piece (twice today the cause was another track's
  merge); an independent reviewer's third look with both ends real still found what tests on a fake
  could not (the door found by folder only; a retry refused by the viewer's own gates); a table whose row
  ids can be used again breaks "read past the last id": look at the table's definition before trusting a
  watermark; **what was built and reviewed to the last detail today (the gate, the door, the key memory)
  did not touch what the owner judged at the first real start: the look, the window that closed, a wrong
  folder that could not be changed. A real start by the owner, early, is worth more than a third review
  look.**

## 18:37 (11-16) AFTER THE TAKE-OVER BLOCK: THE INVESTIGATION OF THE WINDOW THAT ENDED BY ITSELF IS BACK
- **The investigator handed back (19 minutes).** It could not write its report file; I wrote
  `REPORT-B6-window-ends.md` in the project folder from its hand-back: read that file.
- **In one line: no defect that ends the window was found; the most likely cause is the owner's own close of
  the app's window (inferred, not proven: to be asked of the owner); three reproductions did not end it; a
  job kill also gives exit code 0, so 0 alone proves nothing.**
- **`wip/b-winfix` 69e3f3ad** (one commit on the main head 78739d59; `internal/window` only; pushed; the copy
  `wt-b-join` clean on it): the window prints how it ended. NOT reviewed, NOT listed: the successor decides
  with pages whether it is listed as it is (small; its named tests pass) or joined to the one-window work.
- **For pages (the launcher):** the report's section says what to change. My row on the board carries the
  result. Nothing of this track runs now but the background look for C19, which reports to this session only.

## The board row's state before 11-16 18:38 (moved here by session B7 to shorten the board)
| Viewer and bring-in (step 1) | **session B6** (took over from B5, 11-16; B5 is retired: do not message it) | `internal/viewer`, `internal/window`, `internal/bringin`, `cmd/tgarchive-bringin`, `cmd/tgarchive-window`, `cmd/tgarchive/viewer.go`; copies `wt-b-*` | **11-16 11-16 18:28 (session B6): READY FOR A TAKE-OVER (the context is full; I start no new piece). Take over from the block "STATE FOR A TAKE-OVER (B6, 11-16 11-16 18:28)" at the end of `SESSION-B-PROGRESS.md`.** **RUNNING, two things, both write to files:** (1) **the investigation of the app's window that ended by itself (150 e 2):** one Opus investigator in `wt-b-join` on `wip/b-winfix` (from the main head); it reproduces it on a scratch folder, finds the cause to the line, mends the window's side with a test and writes what the launcher must change; **DONE 18:37: its report is `REPORT-B6-window-ends.md` in the project folder (written by me from its hand-back). NO DEFECT FOUND THAT ENDS THE WINDOW: nothing in the window or the launcher ends the app's window when the viewer's starts, and three reproductions on a scratch folder (the launcher's own code among them) did not end it; exit code 0 is a close, and the launcher takes 0 as "closed by the person" and leaves everything running in silence. The most likely cause, inferred and not proven: the owner closed the app's window (two windows come up in the same instant: the viewer's and the app's); with the person's close posted to a test window after 8 s the launcher's log had the owner's very line. To be asked of the owner. Mended on `wip/b-winfix` 69e3f3ad (`internal/window` only; not reviewed, not listed): the window now prints how it ended (closed by the person; a close from outside; stopped from outside; its own end). For pages: the report's section on the launcher (X must quit or say that the app goes on; do not take 0 alone for the person's close; do not start the two windows in the same instant).** (2) a background look of this session for C19 on the main head. **WAITING, built and reviewed: "a removed look-alike edge taken in place": `wip/b-edgegone` 3bb6814f (copy `wt-b-faces`), after C19:** then the main head merged in, one test set back to "no full read", the full runs, an entry (the steps: the progress entry of 18:13). **ONE WINDOW (the owner's choice, messages 151 to 153; pages leads the note): what the window's shell and the viewer need, in a few lines.** The shell: ONE process of `tgarchive-window` that carries the viewer (its catalogue, library, mpv and the page-to-window channel, for the viewer's own origin only) and ALSO takes the launcher's and the app's pages as named places (today the two modes refuse each other's flags: that rule goes; the gate's allowed set becomes the viewer's port plus the named ports; one instance key and one data folder; the launcher starts one window, not two, which also removes today's fault by construction). The viewer's places are routes of its own origin (`/` the library, `/chats` and a chat's page, `/changes`, `/copies/probable` the review, `/overlap`, `/settings`, `/about`): under one navigation they need (a) the app's navigation to know the viewer's address (its port is picked at start: the window must hand it to the pages, or the launcher fixes it), (b) the viewer's own header hidden when it sits inside the app's (one switch), (c) one theme setting for both (each has its own today), (d) a video's player area (mpv) only on the viewer's pages. Each origin keeps its own token and guards; a link from one to the other is a plain navigation, which the pages mode already allows. **151 a and b: NOT checked by me (no time left): whether Saved Messages is listed in the viewer on a new catalogue, and whether the unified stream, the deleted marks and "first seen here" behave as the roadmap says on a NEW account's catalogue: the successor's first check, on an invented catalogue (`tgarchive fabricate -real-rows` with the account's own chat), before anything is said to the owner.** **MERGED today, five entries:** 22 the compose box; 23 the "Changes" page; 24 the window's gate for both modes and the pages mode; 25 the pass-through to the collector's door (the seam is live; never clicked for real). The builds of 5a13119 are in the viewer track's `bin`. **The owner's, open:** item 39 (the first real click) is ON HOLD until the folders are put right (the integrator's word); the NAS thumbnail measuring run (folder `nas-thumbs`); `-Lan` from the window. |

# SESSION B7 (took the viewer track over 11-16 18:38; started by the owner with `START-VIEWER-B7.md`)

## 18:38 (11-16) TAKEN OVER; what is on disk against B6's block; two looks run; the joint note's questions 1 and 4 answered (message 161)
- **Read in, by myself:** `START-VIEWER-B7.md`; `CLAUDE.md`'s archiver section; `DESIGN-ONE-WINDOW.md`; pages'
  `DESIGN-ONE-WINDOW-HOW.md` whole; the picture's first button (its title bar is the app's own: name, pills,
  window buttons); the board's direction, "Listed and unbuilt", the five rows, the integrator's 150 to 153,
  pages' 155, 156, 159; B6's block of 18:28 and its entries of 18:13 and 18:18; `LESSONS-viewer-ix12.32.md`;
  the handoff's 0c (its first block). In the code (`wt-b-join`, 78739d59): `cmd/tgarchive-window/main.go` and
  `pages.go` whole; of `internal/window`: `doc.go`, `run.go`, `instance_windows.go`, the head of `pages.go`,
  the navigation rule (`mayShow`), the message rule (`onWebMessage`, `Bridge.OnPageMessage`), the address
  rule (`origin.allows`, `PagesAddress`, `pageSet`). NOT read: `gate.go`, `shell_windows.go` and
  `webview_windows.go` beyond those functions; the viewer's page scripts (the look below reads them).
- **The disk against B6's block (18:32 to 18:36):** the main head is 78739d59 (M6 and C19 not merged:
  `ChangeEdgeGone` is not in the head's `changelog.go`). `REPORT-B6-window-ends.md` does not exist and
  `wip/b-winfix` is not on `private`. **B6's investigator is alive:** `wt-b-join` (on `wip/b-winfix`, at
  78739d59) has uncommitted changes in `internal/window/ending.go`, `pages_windows.go`, `shell_windows.go`, a
  new `endnote_test.go` (all written 18:33) and an untracked `cmd/tgarchive-window/zzlaunch` (18:25); no
  `tgarchive` program ran at 18:32 and 18:35 (counts). Its draft of `ending.go` says it measured that a
  process ended by the closing of a kill-on-close job has exit code 0. So: not started anew. **A background
  look of this session waits for the report file** (every 15 s, at most 40 minutes; no model turn until it
  ends).
- **18:38, about 18:34 started: ONE Opus investigator (high effort) for the integrator's 151 a and b and
  the joint note's questions 2 and 3.** Read-only on `wt-b-faces` (no edit, no commit); it builds
  `tgarchive.exe` once into `runs-b7/look151`, makes an invented catalogue with the account's own chat and a
  new empty one, starts `tgarchive viewer` on each (127.0.0.1, profile folders redirected, no window, no
  browser), and answers by route, JSON shape and file:line: Saved Messages in the chat list; the unified
  stream and its kind toggles; the deleted marks and the Changes page; "first seen here" and "only here";
  every page on the empty catalogue (a null where a script takes a length); which routes are places; what
  assumes the viewer's top bar; the filter addresses and whether the filter is in the query; counts for the
  five views; the guards on a navigation from another local port; how the port is chosen. Its report:
  `REPORT-B7-viewer-151.md`. Memory before: 5.1 GB free, CPU 62%.
- **Board message 161 to pages (the viewer's half of the joint note, first part):** 155 c: no, a window
  sends nothing to another program's window (its own mutex and class by mode and data folder; "bring to the
  front" only for its own class); question 1: yes, the viewer's window gains the named addresses (what W2
  changes: both flag sets together, the navigation rule and the gate for the viewer's port plus the named
  ones, the channel to mpv the viewer's alone as it is, "Try again", `-first`, `-addr 127.0.0.1:PORT` with
  the launcher picking the port); question 4: exit codes of their own for "closed by the person" and
  "already open", built on the investigator's mend; the title bar in three steps (caption text and colour in
  W2; the pill in the shell; the app's own strip as "W2b").
- **Scripts of this session:** `runs-b7/b7-scripts/board.py` (`row`, `msg`, `prog`: one call each; the row's
  old state was moved to the end of this file by it). Routine steps so far: by that script; the two looks at
  the disk were single commands.
- **Take-over, if this session stops here:** (1) the report file of B6's investigator: as B6's block says
  (verify `wt-b-join`, read the cause and the mend, write the launcher's change to pages, a short independent
  look if the mend touches the instance rule, the jobs or the signals, `internal/window`'s whole tests and
  race run, an entry); if `wt-b-join` shows no new write for 30 minutes and no report, B6's session has
  ended with its agent: commit nothing of the draft, read it, and start one Opus round from
  `BRIEF-B6-window-ends.md` with the draft named. (2) `REPORT-B7-viewer-151.md`: read it, verify its main
  claims against the code, put 151 a and b on the row and questions 2 and 3 on the board. (3) The pieces in
  the row's order (W1's viewer part when pages names its branch; W2). (4) The removed edge after C19, as
  B6's entry of 18:13 says.

## 18:41 (11-16) THE WINDOW THAT "ENDED BY ITSELF": THE INVESTIGATION IS BACK (no cause in the code; a person's close fits); told to pages (message 162); the owner asked (item 40); exit codes behind `-tell-close` are with a coder
- **18:37 B6's session wrote `REPORT-B6-window-ends.md`** (its investigator could not write files) and the
  investigator pushed `wip/b-winfix` 69e3f3ad (one commit on 78739d59; `internal/window` only: `ending.go`,
  2 lines in `pages_windows.go`, 9 in `shell_windows.go`, a test). **Verified by me:** `wt-b-join` clean on
  that head; `private/wip/b-winfix` is 69e3f3ad; its harness folder is gone.
- **The result, as the report says (inferred, not proven):** nothing in `internal/window`,
  `cmd/tgarchive-window` or `internal/launcher` ends the app's window when the viewer's starts; three
  reproductions with the launcher's own code did not end either window; a person's close posted after 8 s
  gave the launcher's log the owner's very line; a process killed with its kill-on-close job ends with code
  0 too (measured). "The same second as the viewer" is how the launcher's `begin()` starts things at every
  start. Not tested: a real mpv in the viewer's window, the real collector and watchdog, a near-empty new
  catalogue, Windows' own job around a program started from Explorer.
- **My read of the mend (the two loops and the window procedure, whole):** the notes are atomic and only
  note; the new `WM_SYSCOMMAND` case falls out of the switch into Windows' own handling as before; the line
  is printed once when the loop has ended, in both modes. Right as written. No exit code changed.
- **My judgement:** accepted as "no fault of the window's found; the owner's answer is the proof". The mend
  is worth listing before the one window exists, with one addition the launcher needs now: a code that
  means "closed by the person" and nothing else (pages' G18 builds a question at the person's close and the
  launcher reads 0 for it today, which a stop and a job kill give too).
- **Message 162 to pages:** what was found; the launcher's three changes (0 is not the person's close; do
  not bring the viewer's window up in front of the app's in the same instant until ONE window exists; the
  second launcher of 18:07:55 came from outside); the four fixed lines; the offered codes.
- **Item 40 on the owner's list:** one yes-or-no question: did you close the app's window yourself at about
  18:08 and 18:09.
- **18:41 ONE Opus coder (high effort) started:** `BRIEF-B7-tell-close.md`, copy `wt-b-join`, branch
  `wip/b-winfix` from 69e3f3ad: the flag `-tell-close` in both modes (4 closed by the person; 6 already
  open, brought to the front; 0 every other clean end; without the flag as on the head), plain tests of the
  mapping, at most 4 real windows on a scratch folder (`runs-b7/tellclose`, profile folders redirected).
  Memory before: 5.4 GB free, CPU 54%. The look for message 151 still runs (its one build is done or under
  way: the coder measures memory before each go command).
- **Routine steps:** the board message, the owner's item, the row and this entry by this session's script
  (`board.py`), one call each.
- **Take-over, if this session stops here:** the coder's hand-back comes to this session only: if it is
  lost, look at `private/wip/b-winfix` past 69e3f3ad and at `wt-b-join`'s state; then: read the difference
  whole (it is small), one narrow independent look with probes (the mapping; nothing changed without the
  flag; an error wins over 4), the full runs once (`ix-tools/full-runs.sh wt-b-join runs-b16 "window"
  "window"`, then `go test ./cmd/tgarchive-window`, `go vet` on both: said on the row first), entry 26 at
  the end of `MERGE-QUEUE.md`, "LISTED, READY" on the row, a line to pages. The look for 151:
  `REPORT-B7-viewer-151.md` when it exists (the first entry's take-over says what to do with it).

## 18:42 (11-16) THE BRIEF FOR "W2" (ONE WINDOW) IS WRITTEN, NOT STARTED: `BRIEF-B7-W2-one-window.md`
- Written from my own read of the window's two modes while the two agents run (the look for 151; the coder
  for `-tell-close`). In short: `-db` and `-pages` together are the joined mode; `-addr 127.0.0.1:PORT` for
  the viewer (exit 7 when the port is taken); the navigation rule and the gate allow the viewer's address
  plus the named ones, fixed once before the engine starts; the channel to mpv stays the viewer's alone;
  the place named by `-first` shows at once and the archive opens behind it (a small fixed page until the
  viewer serves; a failure's safe words there, the named pages go on); "Try again" for a named address;
  no fallback to the browser inside the program (exit 3); one link "The app" in the viewer's header back
  to the first named address until W1's list exists (`viewer.Config.AppURL`); a self-check with real
  windows on a scratch folder. Its two old modes are unchanged.
- **Not started because:** it is cut from `wip/b-winfix` once the `-tell-close` piece is on it (same
  files, one coder at a time in `wt-b-join`), and its section 5.9 waits for the look's answer on where the
  viewer's header is built. **Take-over:** fill 5.9 from `REPORT-B7-viewer-151.md` (question 2), start
  one Opus coder with it on a new branch `wip/b-onewin` from the head of `wip/b-winfix`; afterwards my
  read, ONE independent security review with probes (the gate's set, the message rule, the small page),
  fixes, the full runs once, an entry.

## 18:45 (11-16) THE OWNER'S ANSWER ON THE WINDOW: NOT CLOSED BY HAND; WINDOWS FLICKERED UP SEVERAL TIMES
- The owner, asked by me: "I don't think I closed it. I did see them flicker up, several times." The
  investigator's inference (a close by hand) is most likely wrong. The next suspects are at the end of
  `REPORT-B6-window-ends.md` and in a board message of this minute (my script's edit of the row failed: the
  row's sentence "To be asked of the owner" is answered by that message): first the launcher's "bring to
  the front" second start of the window and its kill-on-close job around the first (a job kill gives exit
  code 0), to be reproduced with a second start of the launcher a second after the first; then mpv's start
  in the viewer's window.
- **For the successor, first thing, with pages (P6):** that reproduction; and get `wip/b-winfix` 69e3f3ad
  reviewed and listed soon: with it the installed window says in its own output how it ended.

## 18:46 (11-16) THE LOOK FOR 151 IS BACK: SAVED MESSAGES IS NOT NAMED IN THE VIEWER; THE THREE FEATURES OF 151 b ARE AS THE ROWS SAY; questions 2 and 3 answered (message 164)
- **About 18:43 the investigator handed back** (9 minutes; 83 tool calls). It could not write its report file:
  `REPORT-B7-viewer-151.md` was written down by me from its hand-back, whole. It changed no tracked file;
  its scratch folder `runs-b7/look151` stays (two invented catalogues F and E, the probe's outputs); no
  `tgarchive` program of its was left (its count: 0).
- **Checked by me in the code before anything was said:** the guard's rule (`internal/viewer/server.go` 153
  to 170 and `crossSite`: a navigation from another port passes, `/api/` and `/media/` never do from a
  browser on another origin); "Saved Messages" stands nowhere in `internal/viewer` (0 lines); a dialog with a
  person is titled first and last name with no look at self (`internal/telegram/dialogs.go` 405 to 418); the
  header is one piece in `web/index.html` 16 to 46; the live monitor's `MessageSeen` saves with no approval
  check. NOT checked by me: the counts' sources, the styles' lines, the empty catalogue's script paths.
- **151 a:** the account's own chat is listed (on a row added by hand) as a person's chat under the
  account's own name; nothing names it "Saved Messages". By reading: a row on a new account, no history
  without the owner's choice, new messages stored by the monitor.
- **151 b:** the unified stream with `type=`, the deleted mark, filter and Changes page, "first seen here",
  "only here", new between dates: as the roadmap's rows say (D5 rows at ROADMAP lines 186, 190, 194, 204; E3
  at 215), on invented data, by JSON; the deleted marks on rows written by hand. No "New" without dates.
- **The empty catalogue:** all 200; one `null` (`anchors`) that the script does not read with 0 tiles; an
  empty sentence on every place, none says what to do next. By reading only.
- **Message 164** (to pages, Core, the integrator): all of the above; question 2 (one page with a
  router: the shell must hand same-origin clicks to it; the grid scrolls the window: a fixed list column;
  the 272 px filter column; the post view covers the window; mpv's rectangle unaffected); question 3 (the
  addresses); the counts (kept: all media, deleted; a walk per index change: first seen, new, probable;
  not measured at size); what I build and in which order.
- **`BRIEF-B7-W2-one-window.md` section 5.9 filled in** (the header's file and lines, the page flags).
- **Decided by me (mine to decide; said on the board):** "S1", a small viewer piece: the account's own chat
  known, named "Saved Messages", first in the list, at `/saved`, with plain words when it has not been
  read; "New" = first seen here since the owner last opened that view (kept in the viewer's settings; 7
  days at first use), with W4; the post view keeps covering the whole window.
- **Routine steps:** the message, the row and this entry by `board.py`; the report's file by the Write tool
  (a script to take it from the agent's transcript found the transcript empty: two calls lost).
- **Still running:** the coder for `-tell-close` (`wt-b-join`, `wip/b-winfix`). **Next:** its hand-back
  (my read, a narrow independent look, the full runs once, entry 26); then W2's coder on `wip/b-onewin`
  from that head; S1's brief (read `internal/viewer/chats.go` and how `refresh.go` reads `tg_user_id`
  first); the counts measured on the invented archive of real size before W4.

## 18:48 (11-16) "S1" (SAVED MESSAGES BY NAME IN THE VIEWER) IS BRIEFED AND WITH A CODER; two coders run
- **Read by me for it:** `internal/viewer/chats.go` (`handleChats`), `refresh.go` near 508 and 528, `index.go`
  near 170 to 196: the index already holds per chat `shared`, `owner`, `tgChatID` and per account `tgUser`,
  so the account's own chat is known with no new read and no schema change (a chat of kind user in a space
  that is not shared whose Telegram id is its owner account's own).
- **`BRIEF-B7-S1-saved-messages.md`:** the index marks it; its shown name is "Saved Messages" everywhere (one
  place; the marks' stable key unchanged; "Saved Messages (LABEL)" with several accounts); first in the Chats
  list; an address `/saved` (`?account=ID`); two plain empty sentences (no row; a row with no message); the
  old archive's case reported from a read of the bring-in; named tests; one look by the viewer's own answers
  on copies of the look's two invented catalogues.
- **18:48 ONE Opus coder (high effort) started on it:** it makes the copy `wt-b-saved` on `wip/b-saved`
  from the newest main head itself; `internal/viewer` only. Memory before: 4.1 GB free, CPU 87% (other
  tracks' runs): its go commands go one at a time through the lock folder `runs-b7/golock` with a memory
  floor of 2.5 GB, `GOMAXPROCS=2`.
- **Two coders of this track run now:** `-tell-close` in `wt-b-join` (five files changed, uncommitted, at
  18:47) and S1 in `wt-b-saved`. W2's coder starts in `wt-b-join` after the first hands back.
- **For S1 after its hand-back:** my read of the one place the shown title is made and of the index rule;
  ONE narrow independent look with probes (the key for marks unchanged; full read against incremental
  update; every answer that carries a title); the full runs once: whole `internal/viewer` on Windows (about
  7 minutes), gofmt, vet; NO race run (the rule is a field set where the chats are read: no code that runs
  concurrently changes); an entry.
- **To say to the integrator at the next board message:** the fabricate command can make neither the
  account's own chat nor a deleted mark (the look had to add both by hand): whose is `internal/fabricate`,
  and a small piece for both would let every track's look and tests use them.

## 18:51 (11-16) `-tell-close` IS HANDED BACK (ca98432f), VERIFIED AND READ; ITS INDEPENDENT LOOK RUNS; W2 (THE ONE WINDOW) IS WITH A CODER; three agents run
- **About 18:49 the coder handed back** (9 minutes): `wip/b-winfix` ca98432f, pushed, one commit on 69e3f3ad;
  156 lines added, 33 removed, about half comments; `internal/window` (`ending.go`: `ErrClosedByPerson`,
  `endNote.result`; `TellClose` in both configs; both loops return `result`) and `cmd/tgarchive-window`
  (the flag, the codes as named constants with one list of every code, `exitCode`, "already open" as an
  error of its own with no end line). **Verified by me:** `wt-b-join` clean on that head; `private`'s branch
  is ca98432f; 0 `tgarchive` programs running.
- **Built as briefed:** with `-tell-close`: 4 the person's close, 6 already open and brought to the front,
  0 every other clean end; an error and "no window" (3) win over 4; without the flag as on the head;
  `-tell-close` with `-selfcheck` is refused in fixed words (exit 1).
- **Its tests:** the mapping (`TestTellCloseResult`), the command's package whole (23 tests, the old ones
  unchanged; "already open" through the real mutex held by the test: 6 with the flag, 0 without, both
  modes); gofmt and vet clean. **Real windows, pages mode, scratch folder, profile folders redirected:**
  the X's message with the flag: exit 4 and the person's line; a bare close message: 0 and the "from
  outside" line; a second start: 6; the X's message without the flag: 0.
- **Its doubts:** it made 7 real starts, not 4 (a first try of 3 found no window through a script error;
  those ran about 65 s each and were ended by its script: its own processes only); Ctrl-C to 0 is covered
  by the plain test only; the viewer's mode's 4 is covered by a stand-in test only; the pages mode's
  refusal words for a viewer flag still say "takes only -data and -selfcheck" (an existing test pins
  them); a person's close racing a Ctrl-C keeps the first noted.
- **My read (the product difference, whole, about 100 lines):** the mapping is in one place; an error wins
  because `result` returns it first; both loops call `result` once at their end; the flag reaches both
  configs; nothing changes without the flag but the constant names. Right as written.
- **18:51 ONE narrow independent look started** (Opus, high; both commits against 78739d59; six questions:
  nothing changed without the flag; any path to a wrong 4 or a missed 4, the note taken before the window
  really closes included; the instance rule; the note's atomics; fixed words; six planted changes against
  the named tests in its own scratch copy `wt-b7-review-T-scratch`). **After it:** its fixes if any, then
  THE FULL RUNS ONCE, by one Sonnet clerk: whole `internal/window` and the command's package on Windows,
  gofmt, vet, the race detector on `internal/window` (the note is written from the window's thread and a
  goroutine): seconds to a few minutes; then entry 26 and a line to pages.
- **18:51 W2's coder started** (Opus, high): `BRIEF-B7-W2-one-window.md` (section 5.9 filled; its copy
  changed to a NEW one, `wt-b-onewin`, branch `wip/b-onewin` from ca98432f, so that the look and the full
  runs keep `wt-b-join`); told to push in four steps (flags and the allowed set; the start's order; "Try
  again" and the rules; the link; the self-check last).
- **The PC:** 6.5 GB free, CPU 94% at 18:50 (other tracks' runs). Every go command of this track goes one at
  a time through `runs-b7/golock` with a floor of 2.5 GB free and, since now, a CPU load under 90%.
- **Running, three agents:** S1's coder (`wt-b-saved`), W2's coder (`wt-b-onewin`), the look
  (`wt-b7-review-T-scratch`). Routine steps of this entry: the look at the branch was one command; the
  notes by `board.py`.
- **Take-over:** the three hand-backs come to this session only. If lost: S1: `private/wip/b-saved`; W2:
  `private/wip/b-onewin` (pushed in steps); the look: start it again from this entry's questions. Then per
  piece: my read, the independent look (W2: a security review with probes of the gate's set, the message
  rule, the small page and the new link), fixes, the full runs once, an entry in `MERGE-QUEUE.md`.

## 18:52 (11-16) THE OWNER ON ITEM 40: "I honestly can't remember. Maybe? It was 40 minutes ago"
- So whether the owner closed the app's window at 18:08 and 18:09 stays unproven either way. Nothing more is
  asked of the owner. What stands: no cause in the code, not reproduced; the window's last line and the
  exit codes behind `-tell-close` name the cause the next time. Item 40 is struck with the answer. For
  pages: the launcher's three changes of message 162 hold whatever the answer was.

## 19:00 (11-16) THE LOOK AT `-tell-close` IS BACK: "MAY BE LISTED AFTER THESE FIXES" (all low); DECIDED: NO FIX ROUND; ITS FULL RUNS GO (one Sonnet clerk)
- **The review:** `REVIEW-B7-tell-close.md` in the project folder (written down by me from the hand-back, with
  my decisions at its end). Five findings, none above low; six planted changes: four caught by named tests,
  the window procedure's wiring and "the line printed twice" not caught.
- **Decided:** finding 1 (nothing tests where the window notes its end) is answered by the coder's four real
  windows, which the reviewer had not been told of; 2 accepted and said; 3 (an older rare race: the engine's
  "process failed" handled after the person's close gives code 3, not 4) and 4 (the usage lines) are given to
  W2's coder by a message, since it works in the same functions. So no fix round on `wip/b-winfix`.
- **The full runs, said to the owner first, started about 19:00 by ONE Sonnet clerk on ca98432f in `wt-b-join`**
  (log folder `runs-b16`): `ix-tools/full-runs.sh wt-b-join runs-b16 "window" "window"` (whole
  `internal/window` on Windows, gofmt, the race detector on `internal/window` in a container), then the
  command's package whole, vet for Windows and for Linux; through the track's lock, 5 GB free and CPU under
  90% first. **Then:** entry 26 at the end of `MERGE-QUEUE.md` (`internal/window` and
  `cmd/tgarchive-window` only; the review above; NOT verified: Ctrl-C and the viewer's mode with a real
  window, Alt+F4 inside a child window, the taskbar's Close), "LISTED, READY" on the row, a line to pages.
- **Running:** the clerk; S1's coder (`wt-b-saved`); W2's coder (`wt-b-onewin`).

## 19:02 (11-16) THE FULL RUNS OF `-tell-close` ARE CLEAN ON ca98432f; NOT LISTED YET: pages' 166 asks one small addition first; a coder adds it
- **About 19:00 the clerk (ONE Sonnet clerk) handed back, every line exit 0** (log folder `runs-b16`): whole
  `internal/window` on Windows ok 5.7 s; the race detector on it in a container ok 6.6 s, no data race; gofmt
  clean; whole `cmd/tgarchive-window` ok 2.9 s; vet for Windows and for Linux. Memory 8.7 to 9.2 GB free, CPU
  about 70%.
- **Pages' message 166, read by me whole at 19:02:** (a) G18's coder found a SECOND story that gives the
  owner's log lines, with the real windows, in the LAUNCHER: after a start refused before its programs ran,
  "Try again" started the viewer's window and in the same second the launcher itself ended the app's window
  by its own clean stop (code 0) and started a new one. Mended on pages' branch; which story was the owner's
  is the integrator's to read from the folder's log. (b) the exit codes are taken as I gave them; G18 merges
  AFTER my entry; its own lent commit in `internal/window` is dropped. **One thing asked of my piece: at the
  person's close the window passes on the right to come to the front (`AllowSetForegroundWindow`), or the
  launcher's question box comes up behind.** (c) my answers are the joint note's section 9; the strip's height
  and markup fixed in `internal/appshell` from the start: wanted; W1 is briefed after G17 is listed.
- **19:02 ONE Opus coder (high effort) started for that one addition** on `wip/b-winfix` in `wt-b-join` (about 10
  lines in `internal/window`: the call at the moment the person's close is noted, only with `TellClose`; a
  pure function for the decision with a plain test; named tests, gofmt, vet; no real window). **Then:** my
  read; the same full runs again by one Sonnet clerk (seconds); entry 26 (its text is ready in
  `runs-b7/b7-scripts/mq-26.md`: change the head and add the addition), the row, message to pages
  (`msg-4.txt`, to be adjusted: it must answer 166). W2's coder merges the new head of `wip/b-winfix` at its end.
- **Running:** that coder; S1's coder (`wt-b-saved`); W2's coder (`wt-b-onewin`).

## 19:07 (11-16) ENTRY 26 IS LISTED, READY (`wip/b-winfix` b0c1c970); S1 IS HANDED BACK AND IN ITS INDEPENDENT LOOK; C19 IS ON THE MAIN HEAD: THE REMOVED EDGE'S ROUND RUNS; message 168
- **The addition pages asked for (166 b) came back at about 19:03** (one Opus coder, 76 s of work): `wip/b-winfix`
  b0c1c970, one commit on ca98432f, pushed, the copy clean: at the person's close with `TellClose` the window
  procedure calls `AllowSetForegroundWindow` for any process (`passForeground` in `ending.go`, a field on the
  shell, one proc). **My read, whole (20 lines): right as written.** Not seen with a real window.
- **The full runs again, by ONE Sonnet clerk, on b0c1c970 (`runs-b17`), every line exit 0:** whole
  `internal/window` on Windows ok 5.9 s; the race detector on it ok 7.0 s, no data race; gofmt clean; whole
  `cmd/tgarchive-window` ok 3.3 s; vet for Windows and Linux. Memory 8.5 to 9.1 GB free, CPU about 80%.
- **ENTRY 26 is at the end of `MERGE-QUEUE.md`** (appended by one command; its note on the main head put
  right after the head moved: a trial merge onto 5bfecb58 by `git merge-tree` is clean). **Message 168** to
  pages and the integrator (166 answered: the ask is in; G18 merges after entry 26; the removed edge is
  entry 27 now; the fabricate command's two gaps; the look's catalogues are at schema step 26).
- **About 19:04 S1's coder handed back** (17 minutes): `wip/b-saved` 076eeab7, two commits on 78739d59, pushed,
  the copy `wt-b-saved` clean (verified by me); `internal/viewer` only, 658 lines added, 56 removed.
  `ownChats` marks the account's own chat at every read of the chats; `(*index).shownTitle` is the one place
  the shown title is made ("Saved Messages", with the account's label in brackets when there are several);
  the title as read goes out as `name`; `chatsInOrder` puts own chats first in `/api/chats` and `/api/meta`;
  `/api/meta`'s accounts carry `saved` (the chat's id or 0); the route `/saved` with `web/js/saved.js`; the
  two fixed sentences. Its named tests pass (the six `TestSaved...`, the random and strong-comparison tests
  with a new operation "own chat arrives", marks, wall, page scripts, LAN, headers, overlap, strip, changes:
  26.8 s). Its look by the viewer's own answers on copies of the two invented catalogues: the own chat is
  row 0 of 15, titled "Saved Messages"; on the empty one `/saved` answers and the page shows the first
  sentence.
- **Its doubts, and mine after reading the core (`chats.go`'s new functions, the two lines in `refresh.go`,
  `api.go`, `server.go`: right as written):** the look's catalogues were at schema step 26 and its head read
  25: it set the version back on its COPIES only (step 26 replaces one trigger); the owner's label is
  dropped after "Saved Messages (A)" in five places so that it is not said twice; `saved.js` asks
  `/api/meta` once more when the first answer says 0; the chat page's own links leave `/saved` for
  `/chat/ID`; a sentence for an unknown account that the brief did not have; **the old archive: its Saved
  Messages is recognised only if the old database's state row gave the bring-in the account's user number
  and the old app listed that chat under its numeric id (read in `internal/bringin`, not run): to be
  counted read-only on the bring-in's own catalogue before anyone says the old archive has it.**
- **19:07 S1's independent look runs** (one Opus reviewer, high; seven questions and eight planted changes in
  its own scratch copy `wt-b7-review-S-scratch`). **After it:** fixes if any; the main head (5bfecb58) merged
  in; THE FULL RUNS ONCE: whole `internal/viewer` on Windows (about 7 minutes), gofmt, vet; no race run
  (a field set where the chats are read and a sort per request: no code that runs concurrently changes);
  entry 28.
- **C19 is on the main head since about 19:05 (5bfecb58; `ChangeEdgeGone` is in its `changelog.go`): the
  removed edge's round is started** (one Opus coder in `wt-b-faces` on `wip/b-edgegone` 3bb6814f, B6's steps
  of 18:13: the main head merged in, `internal/catalog` and `docs` made equal to the head's, the one test
  set back to "no full read at any step", the named viewer tests, push). **After it:** my read of what the
  merge changed; THE FULL RUNS ONCE, said to the owner first: whole `internal/viewer` on Windows (about 7
  minutes) and the race detector on `internal/viewer` (about 46 minutes: the update path that the live
  pages read while it runs was changed by this piece, B6's plan); then entry 27.
- **Running, four agents:** W2's coder (`wt-b-onewin`), S1's reviewer, the edge round's coder (`wt-b-faces`);
  and nothing else. Routine steps of this entry: the runs by a Sonnet clerk; the queue, the message, the row
  and this entry by script.
- **Take-over:** entry 26 needs nothing more. S1: the reviewer's hand-back comes to this session only (if
  lost: start it again from `BRIEF-B7-S1-saved-messages.md` and this entry's doubts). The edge round: its
  result is on `private/wip/b-edgegone` past 3bb6814f. W2: `private/wip/b-onewin`.

## 19:07 (11-16) C19 IS ON THE MAIN HEAD (5bfecb58): the removed-edge piece can go on (for the successor: this session is handed over and starts nothing)
- The background look of this session ended: the main head holds the catalogue's step for a removed edge
  (`ChangeEdgeGone`). So `wip/b-edgegone` 3bb6814f (copy `wt-b-faces`) no longer waits: its steps are in the
  entry of 18:13 above ("Take-over"): a small Opus round (merge the main head; `internal/catalog` and
  `archiver/docs` from the main head's side; `TestLostThroughIncrementalUpdate` back to "no full read at
  any step"; the named tests), the full runs once, entry 26. Not started by me.

## 19:12 (11-16) THE REMOVED EDGE'S ROUND IS BACK (3c6ba693), VERIFIED; ITS FULL RUNS GO (by a script, one call)
- **About 19:13 the coder handed back** (5 minutes): the main head 5bfecb58 merged into `wip/b-edgegone` with NO
  conflict; the new head is the merge 3c6ba693, pushed; `wt-b-faces` clean (verified by me). The branch's
  earlier copy of the catalogue's side was already the head's final form: `git diff 5bfecb58 --
  archiver/internal/catalog archiver/docs` is empty; what differs from the head is 8 files of
  `internal/viewer` (1,761 lines added, 81 removed). The catalogue's contract is as the viewer's code
  expects (`ChangeEdgeGone` is 6; the rows `(6, a)` then `(6, b)`).
- **The one test:** `TestLostThroughIncrementalUpdate` now asks for no full read right after the lost step and
  none at the end, with comments saying why. **Its doubt, kept:** the test does not REQUIRE that an edge
  really goes at that step (the edge count is only said in the failure message); the proof that a removed
  edge is taken in place is the eleven `TestEdgeGone` tests and the random tests, not this one.
- **Its named tests:** build ok; 138 passed in 182 s (the lost, staged, edge-gone, act, wall, changes, live,
  random and change-log families); gofmt and vet clean. Memory about 9 GB free.
- **19:12 THE FULL RUNS, said to the owner at 19:08, started by ONE script call in the background**
  (`runs-b7/b7-scripts/fullruns-viewer.sh wt-b-faces runs-b15 3c6ba693 yes`): the whole `internal/viewer` on
  Windows through the track's lock (about 7 minutes), gofmt, vet for Windows and Linux, and beside them the
  race detector on `internal/viewer` in a container of 2 CPUs and 4 GB (about 46 minutes; needed because
  this piece changed the update path that the live pages read while it runs). Its lines end up in
  `runs-b15/summary.txt`. **Then:** entry 27 (`internal/viewer` only; the review
  `wt-b6-review-E-scratch/REVIEW.md`; the briefs `BRIEF-B6-edge-gone*.md`; the numbers at size from B6's
  entries of 17:42 to 18:13; NOT verified: the live page over HTTP, a real archive, the proof on a cold
  disk).
- **Take-over:** if this session stops, the runs go on by themselves: read `runs-b15/summary.txt` (every
  line must say exit 0, races=0, fails=0) and write entry 27 from B6's entries and this one.
- **Running:** that script; W2's coder (`wt-b-onewin`); S1's reviewer.

## 19:27 (11-16) W2 (THE ONE WINDOW) IS HANDED BACK (`wip/b-onewin` 3c504d2c), VERIFIED, ITS CORE READ; ITS INDEPENDENT SECURITY REVIEW RUNS
- **The coder handed back after about 35 minutes:** `wip/b-onewin` 3c504d2c, pushed, `wt-b-onewin` clean
  (verified by me); cut from ca98432f, with `wip/b-winfix` b0c1c970 merged in clean (796ab601). 24 files,
  2,009 lines added, 20 removed against b-winfix: new `cmd/tgarchive-window/joined.go` (341) and its test
  (379), `internal/window/joined.go` (209), `joined_windows.go` (204), `joinedcheck_windows.go` (180) and a
  test (336), `internal/viewer/appurl.go` (49) and its test; small edits in `main.go` (+120) and ten more
  files of the window, and in the viewer `viewer.go`, one line of `server.go`, `index.html`, `api.js`,
  `main.js`, `app.css`.
- **Built (its words, checked by me where marked):** `-db` with `-pages` is the joined mode; `-addr
  127.0.0.1:PORT`, listened on before the window, exit 7 when taken; the rule `joinedSet` (the viewer's
  address plus the named ones; the gate's set from it, fixed once: READ BY ME, `internal/window/joined.go`
  58 to 148); the page's messages go to the bridge, which drops a source that is not the viewer's (read by
  me); every new document, viewer or named, calls the bridge's `NewDocument` (the video area hidden, mpv
  stopped); **the small page:** an "early" listener serves it on the viewer's port until the viewer serves,
  then new connections are handed to the viewer's own server through a queue (READ BY ME,
  `cmd/tgarchive-window/joined.go` 115 to 270: the listener only accepts; the small page answers 403 for
  another Host, 503 for `/api/`, `/media/` and anything but GET or HEAD, with a policy of its own; a
  failure's safe words, escaped, and the named pages go on); "Try again"; no fallback to the browser in
  the joined mode; `-first`; the link "The app" in the viewer's header (`viewer.Config.AppURL`, exactly
  `http://127.0.0.1:PORT/`); the guard `afterClose` for the review's old race (a "process failed" after the
  person's close is counted only); the usage lines.
- **Its tests:** eight new named tests of the window, the command's package whole (with the flags, exit 7,
  the small page and the start's order on an invented catalogue), the viewer's by name; the old modes'
  tests unchanged but ONE: `TestPagesRefusesViewerFlags` (its case `-pages` with `-db` is the joined mode
  now). gofmt and vet clean on the window and the command.
- **ONE real window (the joined self-check, a scratch folder, profile folders redirected, an invented
  archive):** the first named page shown; a link to the viewer's chats followed and back by "The app"; two
  messages from a named page dropped by source; a third port refused by the gate, 0 connections reached
  it; the person's close: exit 4; 12 checks, 0 failed; 0 programs left. **NOT run: a clip played and then
  navigated away from (no mpv or ffmpeg named in its environment): that rule is covered by a plain test
  only.**
- **Where it left the brief, each said by it:** the one changed test; `-addr` without `-pages` also listens
  first and exits 7; `-tell-close` with `-selfcheck` only in the joined mode; four self-check flags refused
  in the joined mode; `-first` refused outside it. **Its doubts:** the engine's user-agent word is on the
  viewer's pages too in the joined mode; "Try again" loads the first place, not the one that failed; the
  small page reloads every second while the archive opens (each reload a new document); the joined window
  is shown and activated at once.
- **My read (the rules and the hand-off, about 250 lines of the 2,009): right as written. NOT read by me:**
  `joined_windows.go` (the window's side), the changes in `webview_windows.go`, the self-check.
- **One thing I gave the reviewer as its first question beyond the brief:** until now the window refused
  every navigation away from the viewer's own address; now a viewer page may navigate to a named address.
  If any viewer page turns text from a Telegram message into a link, a message could carry the window to
  the collector's pages at an address of its choosing. To be answered from the viewer's page scripts
  before this is listed.
- **19:27 ONE independent security review started** (Opus, high; `BRIEF` in its prompt: seven questions
  (reach; the two origins in one window; the small page and the hand-off; the flags and the exit codes;
  the app's link, also towards other devices at home; the guard; ten planted changes), named tests only
  through the lock, no real window; scratch copy `wt-b7-review-W2-scratch`). **After it:** its fixes (one
  Opus round), then THE FULL RUNS ONCE: whole `internal/window` and the command's package on Windows, the
  viewer's page, flag, LAN and wall tests by name (the whole viewer only if the fixes touch more of it
  than the link), gofmt, vet, the race detector on `internal/window` (the early listener and the hand-off
  are concurrent code: in `cmd`, which the container can run too); then its entry and what pages needs for
  the launcher (the flags, the codes 3, 4, 6, 7).
- **Running:** the removed edge's full runs (the script; the viewer whole, then the race run to about
  20:05); S1's reviewer; W2's reviewer.
- **Take-over:** both reviewers hand back to this session only; if lost, start each again from this entry
  and the entry of 19:07. Nothing of W2 is listed.

## 19:34 (11-16) THE OWNER'S OBJECTIVE (19:31, through the integrator): "to actually deliver something, meaning the features that work with the much improved look": THE LIST ON THE LEFT IS WITH A CODER ON THE VIEWER'S PAGE; message 171 (the cut, and what the launcher passes)
- **19:33 the integrator, by a message to this session and its board message 155 (19:33; read by me whole):**
  about an hour of usage is left this week; pages and the viewer are the delivery: the first start's faults,
  then the one window's shell with the list on the left in the new look over the pages and the viewer as
  they are, then the Overview's links; "a shell with plain links that works beats a finished design note";
  entry 26 is MERGED (f1d7127) and the owner's folder rebuilt from it; the removed edge can wait; list each
  piece as soon as it is ready; commit and push at every step.
- **Decided by me (the shortest path; said to pages in message 171, who may say no):** pages' shared package
  does not exist yet, so the viewer draws the list on its own page now, as a block of markup and styles of
  its own that the shared package can take over later. **19:37 ONE Opus coder started:**
  `BRIEF-B7-W1v-list.md`, a NEW copy `wt-b-shell`, branch `wip/b-shell` from the main head with
  `wip/b-saved` and `wip/b-onewin` merged in; `internal/viewer` only (and the joined self-check for
  pictures): the list (Overview when the app's address is known, Saved Messages, the library's views, the
  chats, the foot), the top bar as the picture's strip, empty sentences that say what to do next, and PNG
  pictures of the window on invented data (a filled archive, a filter chosen, a chat, `/saved`, an EMPTY
  catalogue) in `runs-b7/shell/pictures` for me to look at. It pushes after every step.
- **What the launcher must pass for the one window is in message 171 (c)**; until pages' launcher does, the
  one window is opened by hand or by a start script (asked of pages).
- **Running:** the list's coder (`wt-b-shell`); S1's reviewer; W2's security reviewer; the removed edge's
  race run (the script; it lists nothing by itself).
- **Take-over, in the order of the delivery:** (1) S1: the reviewer's findings, a fix round on
  `wip/b-saved`, `bash runs-b7/b7-scripts/fullruns-viewer.sh wt-b-saved runs-b18 <head> no`, an entry;
  (2) W2: the security review's findings, a fix round on `wip/b-onewin`, the window's full runs, an entry;
  (3) the list: `private/wip/b-shell`: look at the pictures, one narrow look, the viewer's full run, an
  entry that says it holds S1 and W2; (4) the removed edge: `runs-b15/summary.txt`, entry 27.

## 19:36 (11-16) S1's INDEPENDENT LOOK IS BACK: "MAY BE LISTED AFTER THESE FIXES" (one medium, on the page); ITS FIX ROUND RUNS
- **The review:** `REVIEW-B7-S1-saved-messages.md` (written down by me, my decisions at its end). The server
  side holds (the rule on every path, the one title function, nothing keyed by a title, the guards on
  `/saved`; six of eight plants caught, the other two harmless). **One medium finding:** on `/saved` the
  inner chat page later moves the address to `/chat/ID`, the router then mounts a new page: a flash, a jump
  to the top, and the reader's place can be lost. Low: the two chat finders (library, Overlap) no longer
  find the own chat by the account's own name. Outside the piece, older: a sign-in that writes an account's
  Telegram number after marks exist changes its per-account chats' stable keys (their marks stop applying).
- **19:36 ONE Opus coder started on `wip/b-saved` in `wt-b-saved`:** fix 1 the reviewer's way (`saved.js`
  replaces the address with `/chat/ID` once it knows the id: `/saved` is an entry address), fix 2 (both
  finders match the name as read too), the main head merged in, named tests, push. The list's coder was
  told (the Saved Messages entry is the current place on `/saved` and on that chat's own address; merge
  the fix at its end).
- **Then:** my read of the fix; `bash runs-b7/b7-scripts/fullruns-viewer.sh wt-b-saved runs-b18 <head> no`
  (whole `internal/viewer` on Windows, about 7 minutes; gofmt; vet; no race run: no code that runs
  concurrently changes); entry 28; a board line with the marks' key finding for Core.
- **Running:** S1's fix coder; the list's coder (`wt-b-shell`); W2's security reviewer; the removed edge's
  race run.

## 19:49 (11-16) THE LIST ON THE LEFT IS BUILT (`wip/b-shell` da0939b2) AND SEEN IN THE REAL WINDOW ON INVENTED DATA; two pictures sent to the owner; its narrow independent look runs. S1's FIX ROUND IS BACK (fb09df28), its full run goes
- **S1's fix round (about 19:50):** `wip/b-saved` fb09df28, pushed, clean (verified); fix 1 as the reviewer
  said (`saved.js` replaces `/saved` with `/chat/ID` one microtask after its mount; read by me whole: right
  as written), fix 2 (both finders match the name as read; `/api/overlap` got the `name` field); the main
  head f1d7127b merged in clean; its named tests ok 29.7 s; gofmt, vet clean. **Its full run goes by the
  script** (`fullruns-viewer.sh wt-b-saved runs-b18 fb09df28 no`). **Entry 28's text is ready in
  `runs-b7/b7-scripts/mq-28.md`: put the run's lines in place of RUNLINES and the time, append it to
  `MERGE-QUEUE.md`.**
- **The list's coder handed back (about 15 minutes):** `wip/b-shell` da0939b2, pushed; cut from the main
  head f1d7127b with `wip/b-saved` and `wip/b-onewin` merged in (conflicts in `cmd/tgarchive-window/main.go`,
  `internal/window/ending.go` and `run.go`: the one window's side taken, the other side was a subset), then
  the moved `wip/b-saved` (1775bc80; fb09df28's merge of the head is not in yet). New `web/js/shell.js`
  (about 125 lines), `app.css` +69, `index.html` +24, a few lines in `main.js`, `library.js`, `chats.js`;
  `shell_test.go`; pictures in the joined self-check (+70, by an environment variable only).
- **What it shows (its words; seen by me in the pictures):** a fixed list of 240 px: Overview (when the
  app's address is set), Saved Messages, the library's eight views (the entry of the current place marked,
  by path and by filter), the chats newest first with a coloured initial, Copies, Overlap, Settings, About
  at the foot; the top bar is a strip with the name and the search box; the library's own filter column
  stays beside it; the document scrolls as a whole; under 1,100 px the list folds behind one button; the
  new empty sentences. Not for other devices at home (hidden there by the script: its markup is in their
  page too, since a test wants the pages equal).
- **THE PICTURES, looked at by me** (`runs-b7/shell/pictures`, the real window, 1264 by 821, invented
  data): `filled-a-library.png` (the list, the filters, the grid by month: it reads as an app; All media
  marked), `filled-c-chat.png` (a chat with its entry marked in the list), `empty-a-library.png` ("No files
  in this archive yet. Files appear here once the app has collected a chat: choose one under Overview.",
  with a stray "null" under it that the coder fixed AFTER the picture: not shot again). **Wrong in them:**
  the filter column shows a horizontal scrollbar at its foot. Not looked at by me: `filled-b-deleted.png`,
  `filled-d-saved.png`. **Two pictures were sent to the owner** (the library, a chat).
- **Its doubts:** the device's page carries the hidden markup; the tabs are hidden with the CSS `:has()`;
  no state pill in the strip (it would need a request); no narrow or light-theme picture.
- **19:49 ONE narrow independent look started** (Opus, high; eight questions: text only and no new request;
  other devices at home; the page's layout rules and the video's rectangle; the mark; `:has()`; the
  scrollbar; the pictures code; the two tests).
- **Then, for the list:** ONE small Opus round (the look's fixes, the scrollbar, `wip/b-saved` fb09df28 and
  W2's fixes merged in, the empty picture shot again), my look at the new pictures, the full runs once
  (the viewer whole about 7 minutes; the window and its command whole: seconds; gofmt; vet; the race
  detector on `internal/window`), then ONE entry for `wip/b-shell` that says it holds S1 and W2.
- **Running:** S1's full run; the list's reviewer; W2's security reviewer; the removed edge's race run.

## 19:53 (11-16) THE LIST'S INDEPENDENT LOOK IS BACK: "MAY BE LISTED AFTER THESE FIXES"; its fix round runs
- **The reviewer (Opus, 3 minutes; d7e9391b..da0939b2, the list only; 44 named tests ok 18.4 s):**
  1. MEDIUM: the list goes stale (`shell.js` draws once; a chat hidden or shown again sends the page event
     `viewer:marks`, which the list does not hear): a chat just hidden stays in the list until a reload.
  2. LOW-MEDIUM: `shell.fill(meta)` runs inside `start()`'s try in `main.js`: a throw there would show "The
     archive could not be opened" over a good catalogue.
  3. LOW: combined filters mark no entry (nothing wrong or doubly marked). ACCEPTED.
  4. LOW: the folded list (under 1,100 px) closes by Esc or a choice only; no click outside.
  5. LOW: `TestShellListOnThisPCOnly` checks source text, not behaviour. ACCEPTED, said in the entry.
  - Its answers: every string from data is drawn as text; links are fixed paths and numeric ids; no new
    request; nothing of this PC's addresses reaches another device's page and the list fails closed there;
    the document scrolls as a whole; the post view still covers the list; the video's rectangle is measured
    against the viewport, so the shift is in it; the mark is right for every single-filter address;
    `:has()` could be a class set by the script; the filter column's horizontal scrollbar is most likely
    OLDER than this piece (`.side` has only `overflow-y: auto`); the pictures code writes only when its
    environment variable is set. Not checked by it: a browser or window, the narrow width, the merges.
- **19:53 ONE Opus coder started on `wip/b-shell`:** fixes 1, 2, the class in place of `:has()`, the scrollbar,
  a click outside closes the fold; `wip/b-saved` fb09df28 merged in; the five pictures shot again into
  `runs-b7/shell/pictures2`; named tests; a push after each step.
- **The two background runs at 19:53:** S1's full run has not passed its gate yet (the script waits for the CPU
  to fall under 90%); the removed edge's race run still goes (its Windows part ended 19:21).
- **Still out:** W2's security review. Its fixes go to `wip/b-onewin` and are merged into `wip/b-shell`
  before the list is listed.

## 19:56 (11-16) W2's SECURITY REVIEW IS BACK: "MAY BE LISTED AFTER THESE FIXES" (one medium); its fix round runs
- **The review:** `REVIEW-B7-W2-one-window.md` (written down by me, my decisions at its end). **Medium:** in
  the joined mode a new-window request was followed for the viewer's address too: the viewer's "Open the
  saved copy" would load a raw file into the window with no way back, and a named page could make the
  window load viewer addresses the viewer's guard refuses to other ports. Low: the gate's real list has no
  test; a test gap for the app's address; the window's posts to the page after a navigation; the
  self-check's clip step not built; the watch's exit skips the viewer's last counts; cookies are shared
  between the two ports (none is set today). **My first question is answered: nothing in the viewer's
  scripts turns text from a message into a link.** Eight of ten plants caught.
- **19:56 ONE Opus coder started on `wip/b-onewin` in `wt-b-onewin`:** fixes 1 (new windows only for the named
  addresses, a pure function and a test), 2 (one function makes the gate's list), 3 (two test cases), 4
  (posts only while the viewer's document is shown); named tests; a push after each.
- **Then:** my read of fix 1; `wip/b-onewin`'s new head merged into `wip/b-shell` (after the list's fix
  round); the full runs once on `wip/b-shell`: the viewer whole (about 7 minutes), the window and its
  command whole (seconds), gofmt, vet, the race detector on `internal/window` and on the command's package
  (the early listener's hand-off is concurrent code); ONE entry for `wip/b-shell` holding S1, W2 and the
  list. For the board: the cookie rule (7) and the marks' key finding (S1's review, 4).
- **Running:** W2's fix coder; the list's fix coder; S1's full run (waiting at its gate or running); the
  removed edge's race run.

## STATE FOR A TAKE-OVER (B7, 11-16 20:00): enough to take over from this block alone
- **Why now:** this session's context is at 89% (the owner asked for the plan at 19:58). It starts no new
  piece. Everything below is pushed; the notes are committed on `notes`.
- **The owner's objective (19:31, through the integrator's board message 155 of 19:33):** "to actually
  deliver something, meaning the features that work with the much improved look". The viewer and pages are
  the delivery; the removed edge can wait; list each piece as soon as it is ready.
- **MERGED today from this session:** entry 26 (the window says how it ended; `-tell-close`: 4 closed by the
  person, 6 already open, 0 every other clean end), f1d7127.
- **THE DELIVERY BRANCH: `wip/b-shell`** (copy `wt-b-shell`; cut from the main head f1d7127b; it HOLDS
  `wip/b-saved` and `wip/b-onewin`): the list on the left in the new look on the viewer's page
  (`BRIEF-B7-W1v-list.md`), seen by me in the real window on invented data (`runs-b7/shell/pictures`; two
  pictures sent to the owner at about 19:48). **Running on it: its fix round** (one Opus coder; the look's
  findings: the list hears `viewer:marks`; `shell.fill` out of the start's try; a class in place of the CSS
  `:has()`; the filter column's horizontal scrollbar; a click outside closes the fold; `wip/b-saved`
  fb09df28 merged in; the pictures shot again into `runs-b7/shell/pictures2`). It pushes after each step
  (`private/wip/b-shell` was 2a9a6a7b at 19:59). Its hand-back comes to this session only: if it is lost,
  read `git log da0939b2..private/wip/b-shell` and look at `pictures2`.
- **`wip/b-onewin` (the one window, W2; copy `wt-b-onewin`; 3c504d2c): running on it: the security review's
  fix round** (one Opus coder; `REVIEW-B7-W2-one-window.md`, findings 1 to 4: new-window requests followed
  only for the named addresses; one function makes the gate's list; two test cases for the app's address;
  the window posts to the page only while the viewer's document is shown). It pushes after each fix. If its
  hand-back is lost: `git log 3c504d2c..private/wip/b-onewin`; read fix 1 yourself (a pure function
  `joinedNewWindow` or the like, and its test).
- **`wip/b-saved` (Saved Messages by name, S1; copy `wt-b-saved`; fb09df28, holds f1d7127b): reviewed, fixed,
  read. ITS FULL RUN GOES** (a background script of this session, started 19:53: `runs-b18/summary.txt`; a
  fresh session does not get its word: read that file: `win-viewer` must say `ok` and `exit 0`, gofmt
  `lines=1`, both vets `exit 0`). **Its entry is written: `runs-b7/b7-scripts/mq-28.md`:** put the run's
  lines in place of the word RUNLINES and the time in place of 20:00, append the file to the end of
  `MERGE-QUEUE.md` (a blank line first), tell the integrator on the board. If the run failed: that one test
  on the main head first, before blaming the piece.
- **`wip/b-edgegone` (the removed edge's viewer side; copy `wt-b-faces`; 3c6ba693, holds 5bfecb58): ITS FULL
  RUNS GO** (a background script, started 19:12: `runs-b15/summary.txt`; the Windows part ended 19:21, the
  race run on the viewer takes about 46 minutes and had not ended at 19:59). When the summary has its
  lines, each with `exit 0`, `races=0`, `fails=0`: write entry 27 from B6's entries of 17:42 to 18:13 and my
  entries of 19:07 and 19:16 (`internal/viewer` only, 8 files; the review `wt-b6-review-E-scratch/REVIEW.md`;
  NOT verified: the live page over HTTP, a real archive, the proof on a cold disk). It can wait behind the
  delivery.
- **THE NEXT STEPS, in order (each small; routine ones by ONE Sonnet clerk call or the scripts):**
  1. S1's summary, then entry 28 (above).
  2. W2's fix round back: read fix 1; then merge `private/wip/b-onewin` into `wip/b-shell` (after the
     list's fix round is back; conflicts are unlikely: the list touches `internal/viewer` only), and the
     newest main head (it was e78ef361 at 19:59), push.
  3. Look at `runs-b7/shell/pictures2` yourself (the Read tool shows PNG files): the empty catalogue's
     library without the stray "null", no horizontal scrollbar in the filter column, `/saved`, a chat.
  4. THE FULL RUNS ONCE on `wip/b-shell`, said to the owner in one line first: the viewer whole
     (`bash runs-b7/b7-scripts/fullruns-viewer.sh wt-b-shell runs-b19 <head> no`: about 7 minutes; no race
     run on the viewer: the list is page code); the window and its command whole and the race detector on
     them (`bash ix-tools/full-runs.sh wt-b-shell runs-b20 "window" "window"`, then
     `go test ./cmd/tgarchive-window`, vet for Windows and Linux: seconds; the early listener's hand-off is
     concurrent code in `cmd/tgarchive-window`: run that package under the race detector too if the
     container can: `bash ix-tools/race-archiver.sh <copy> ./cmd/tgarchive-window 2 4g 20m`).
  5. ONE entry for `wip/b-shell` at the end of `MERGE-QUEUE.md`: it holds S1 (entry 28: if that is merged
     first, say so), W2 and the list; the three reviews (`REVIEW-B7-S1-saved-messages.md`,
     `REVIEW-B7-W2-one-window.md`, the list's look: its findings are in my entry of 19:55); what is seen (the
     pictures; the joined self-check: 12 checks, the first named page, to the viewer and back, a third port
     refused, exit 4) and **what is NOT: a clip played in the joined window; the narrow width; the light
     theme; the launcher starting it (pages' side: board message 171 c has the exact start line and the exit
     codes 3, 4, 6, 7; no answer from pages by 19:59); a real catalogue; the old archive's Saved Messages
     (one read-only count owed); the window still has Windows' own title bar ("W2b", not started).**
  6. Until pages' launcher starts the one window: the first way in for the owner is a start script in the
     owner's folder (offered in 171 c; not written): ask pages on the board first.
- **Owed on the board (not written yet; one message):** the cookie rule for both tracks (neither program
  sets a cookie on 127.0.0.1: the two ports share the engine's cookies; a wall test owed); for Core: a
  sign-in that fills an account's Telegram number after the owner's marks exist changes its per-account
  chats' stable keys (`marks.go` 72 to 77; S1's review, finding 4); the answer to the integrator's question
  who owns `internal/fabricate` is still open (my 168 d).
- **This track's copies:** `wt-b-shell`, `wt-b-onewin`, `wt-b-saved`, `wt-b-faces`, `wt-b-join` (entry 26 is
  merged: it may be removed after a check that it is clean and equal to `private/wip/b-winfix`); the looks'
  scratch copies `wt-b7-review-T-scratch`, `-S-scratch`, `-W2-scratch` (their reviews are files in this
  folder now: they may go).
- **This session's tools (`runs-b7/b7-scripts`):** `board.py` (`row FILE`, `msg FILE`, `owner FILE`,
  `prog FILE`: one call each; a row file is two parts separated by a line `====` and must hold no `|`),
  `fullruns-viewer.sh` (the viewer's full run, with or without the race run, through the lock), `row-1.txt`
  (the row's text as last written), `mq-28.md`. The track's go lock: the folder `runs-b7/golock` (taken by
  `mkdir`, released by `rmdir`; if it is left behind by a stopped agent and no go program of this track
  runs, remove it).
- **Lessons of this session (my reading):** an agent cannot write a report file: its hand-back is the
  report, so write it down at once; a look for "is the feature there" answered in nine minutes from the
  program's own answers on an invented catalogue what nobody had checked; the pictures from the window's
  own self-check were the first time anyone on this track SAW the look before saying it exists: ask for
  them in every brief that changes a page; the fabricate command makes neither the account's own chat nor a
  deleted mark, so two of the owner's four questions could only be seen on rows added by hand; a full run
  that holds the track's lock for seven minutes stalls every agent's named tests: start it when the coders
  are reading, not when they are testing.

## 20:02 (11-16) ENTRY 28 IS LISTED, READY: `wip/b-saved` fb09df28 (Saved Messages by name); the board's owed message is written (B7, after its take-over block)
- **S1's full run ended 20:01, every line exit 0** (`runs-b18/summary.txt`, by the script): the whole
  `internal/viewer` on Windows ok 413.7 s; gofmt clean; vet for Windows and Linux; the copy clean. A trial
  merge onto the main head e78ef361 is clean.
- **Entry 28 is appended to `MERGE-QUEUE.md`; the board message of 20:02** tells the integrator (entry 28; the
  delivery branch is not listed yet), pages (`/saved`, `saved` in `/api/meta`; the cookie rule) and Core (the
  marks' key and a sign-in; reading Saved Messages by itself). **So the take-over block's step 1 and its
  "owed on the board" are DONE; the next step is 2.**
- **Still running at 20:02:** the list's fix round (`wip/b-shell`), the one window's fix round
  (`wip/b-onewin`), the removed edge's race run (`runs-b15`).


# SESSION B8 (took the viewer track over 11-16 20:03; started by the owner with `START-VIEWER-B8.md`)

## 20:10 (11-16) B8 HAS THE TRACK; both of B7's fix rounds are still at work; fix 1 of the one window read
- **Read by me:** the start file; B7's block of 20:00 and its entries from 19:40; the board's rows of pages,
  the integrator and the viewer; messages 155 and 168 to 176 (nothing addressed to the viewer after 176);
  `DESIGN-ONE-WINDOW.md`; two of the pictures the owner was shown (`runs-b7/shell/pictures`: the filled
  library, the empty one with its stray "null" and the filter column's sideways scrollbar).
- **On disk at 20:03 (one read-only command of mine):** `wt-b-shell` clean at 2a9a6a7b, equal to `private`
  (the list's five fixes and the merge of `wip/b-saved` fb09df28 are in; `pictures2` does not exist yet; its
  coder's test and vet files in `runs-b7/shell` are of 20:03: it is at work). `wt-b-onewin` at 0b08b8e3
  with 4 files changed and not committed: its coder is at work on fixes 2 to 4. The removed edge's race run
  has not ended (`runs-b15/summary.txt` has no race line). The main head on `private` is one commit past
  what `wip/b-shell` holds.
- **Fix 1 of the one window (0b08b8e3), read by me whole (code, not the test):** `joinedNewWindow` is a pure
  function: followed only when the address was read and is a NAMED one; in the joined mode a request for
  the viewer's address is refused and counted as the viewer's window counts it; the plain pages mode keeps
  its own rule. It is what the review's medium finding asked.
- **Both coders hand back to B7, which is retired: I take their work from the copies.** Two background
  watches of this session end when a copy is clean and its head has not moved for about three minutes
  (the one window) and when `pictures2` holds its pictures (the list). No message is sent to either.
- **Routine steps of this entry:** the row, this entry and the commit by one script call
  (`runs-b8/b8-scripts/save.sh`); no go command was run.
- **Next:** read the one window's fixes 2 to 4 from the log; merge `private/wip/b-onewin` and the main head
  into `wip/b-shell` (one Sonnet clerk); the new pictures; my own opening of the window on an empty and on
  a filled invented catalogue; the full runs once, said to the owner first; ONE entry for `wip/b-shell`.

## 20:04 (11-16) THE LIST'S FIX ROUND IS BACK: `wip/b-shell` 2a9a6a7b (B7, after its take-over block; not read by me: no room left)
- **The coder's hand-back, as it said it (verify: `git log da0939b2..private/wip/b-shell`):** all five fixes
  are in and pushed: the list is drawn again on `viewer:marks` (69ca21d7); `shell.fill` in its own
  try/catch with a `shell.off()` that hides only the list (b850fd69); the class `has-places` on the root in
  place of the CSS `:has()`, the test pins it (b850fd69); `.side { overflow-x: hidden }` and wrapping filter
  labels (ec2464e6); a click outside closes the folded list (27dbc5cb); `private/wip/b-saved` fb09df28
  merged in clean (2a9a6a7b). Named tests ok 16.2 s; build, gofmt, vet clean. No process of its left.
- **New pictures, NOT looked at by me:** `runs-b7/shell/pictures2/filled` and `runs-b7/shell/pictures2/empty`,
  each with `a-library.png`, `b-deleted.png`, `c-chat.png`, `d-saved.png` (the script:
  `runs-b7/shell/scripts/pictures2.sh`). The coder looked at the two library ones: the horizontal scrollbar
  and the stray "null" are gone.
- **ONE THING THAT LOOKS WRONG, for the successor to judge before the listing:** in the window's pictures
  (round 1 too: I saw it in `filled-a-library.png` without naming it) the library's filter column shows NO
  checkboxes before its labels, only a gap. Not known whether it is older than the list (compare a picture
  of the main head's viewer in the window, or read `.check` in `web/app.css` and the filter's markup in
  `library.js`); if the list's CSS caused it, it is a fix before the listing; if it is older, say so in
  the entry and list it as a defect of the viewer in the window.
- **So the take-over block's step 3 has its pictures, and step 2 waits only for the one window's fix round**
  (`wip/b-onewin`, still running at 20:04).

## 20:05 (11-16) THE ONE WINDOW'S FIX ROUND IS BACK: `wip/b-onewin` 99cef0f1 (B7, after its take-over block; fix 1's one line looked at, the rest not read by me)
- **The coder's hand-back, as it said it (verify: `git log 3c504d2c..private/wip/b-onewin`):** four commits,
  each pushed: 0b08b8e3 (the medium finding: `joinedNewWindow` in `internal/window/joined.go`: a new-window
  request is followed only for a NAMED address; the viewer's own address is refused and counted;
  `TestJoinedNewWindow`); cf6ec8dd (`joinedGateHosts` is the one place the joined gate's list is made, used
  by `runJoined` and the tests; the exact list asserted); 2453dff9 (two test cases for the app's address;
  `appurl.go` unchanged); 99cef0f1 (`shellUI.Post` posts to the page only while the shown document is the
  viewer's: `joinedPostOK`; otherwise dropped and counted as `posts_not_to_viewer_dropped`). Build, the
  window's named tests (5.1 s), the command's package (2.8 s), `TestAppURL`, gofmt, vet: clean. No window
  started.
- **Looked at by me, one line only:** 
- **Its doubts:** fix 4 is as exact as the engine's own address of the shown document (a message queued
  just before a navigation to a named page is dropped); it added one counter field in `pages.go`; the
  joined counts file has a new key and no test pins its keys.
- **So the take-over block's step 2 is ready to do:** read fix 1 and fix 4 whole (`git diff 3c504d2c
  99cef0f1 -- archiver/internal/window`), merge `private/wip/b-onewin` and the newest main head into
  `wip/b-shell` (2a9a6a7b), push; then steps 3 to 5 (the pictures in `runs-b7/shell/pictures2`, the
  checkboxes question of my entry before this one, the full runs once, ONE entry for `wip/b-shell`).
- **Nothing of this session runs any more but the removed edge's race run** (`runs-b15/summary.txt`).

- **Correction to the entry above (B7, 20:05):** my one command to look at `joinedNewWindow` failed, so NOTHING of
  the one window's fix round was looked at by me: the heading's "fix 1's one line looked at" and the empty
  line "Looked at by me" are wrong. The successor reads fix 1 and fix 4 whole before the merge.

## 20:16 (11-16) THE DELIVERY BRANCH HOLDS EVERYTHING: `wip/b-shell` 4243ba3e, pushed; opened by me on an empty and a filled invented catalogue, every place clicked; ONE FAULT FOUND (no way back from the app's pages), its fix is with a coder; the full runs go (B8)
- **A correction:** my first entry is headed 20:10; `date` said 20:04 when it was written.
- **B7 was still writing after my take-over** (its entries of 20:04 and 20:05 and a correction, below my
  first entry): read by me whole. Both fix rounds' hand-backs are there in the coders' words.
- **Read by me, whole (code, not tests):** the one window's fixes 1 to 4 (`git diff 3c504d2c 99cef0f1`, the
  window's package): `joinedNewWindow` (only a named address), `joinedGateHosts` (one function makes the
  gate's list; `runJoined` uses it), the test case for the app's address, `joinedPostOK` (the window's
  messages go to the page only while the shown document is the viewer's; read on the window's own thread
  at the moment of the post; dropped ones counted). Each does what the review asked.
- **Merged by one script call (`runs-b8/b8-scripts/merge-shell.sh`; `runs-b8/merge/summary.txt`):**
  `private/wip/b-onewin` 99cef0f1 and the main head e78ef361 into `wip/b-shell`, both clean; gofmt 0 files,
  vet ok, the viewer's named tests ok 13.0 s, `internal/window` whole ok 5.4 s, `cmd/tgarchive-window`
  whole ok 3.4 s; both programs built into `runs-b8/look`; pushed: **4243ba3e**, equal to `private`.
- **THE NEW PICTURES, looked at by me** (`runs-b7/shell/pictures2`; the real window, 12 checks, 0 failed, on
  each catalogue): the empty library without the stray "null"; no sideways scrollbar in the filter
  column; the filled library; a chat with its entry marked; Saved Messages ("not in this archive yet": the
  invented data has no own chat, so that page was NOT seen filled).
- **B7's question (no checkboxes in the filter column): judged: not a fault of this piece.** The filter's
  options are buttons with a tick that shows only when the option is chosen (`.opt .opt-check`, hidden
  until `.opt.on`); the same on the main head e78ef361 (4 rules in `app.css`, 6 uses in `library.js`).
- **OPENED BY ME (`runs-b8/b8-scripts/look.sh`; scratch folder `runs-b8/look`, the engine's folders
  redirected into it; invented data):** the app's pages by the real `tgarchive app` and the REAL one window
  started with the line of message 171 c (`-db -library -data -addr -pages -tell-close`); the window
  started and stayed up on both catalogues; a second start while the first still held the port ended
  with "the port is taken" as written. **My clicks went through the browser pane to the SAME two servers
  the window showed** (I cannot click inside the window: a desktop screenshot could show the owner's
  other windows). **Filled (600 messages, 14 chats): all 28 entries of the list open their place and are
  marked, no page error. Empty (a catalogue made by the program): all 14 open and are marked, each with
  its empty sentence, no page error.** Overview leads to the app's first page on both.
- **THE FAULT (found by the look; nobody had clicked it): no way back from the app's pages.** The pages'
  header link "Open viewer" is a new-window link (`target=_blank`) to the viewer's first page. Since fix
  1 (0b08b8e3) the one window refuses every new-window request for the viewer's address, and it has no
  back button: after "Overview" the owner would sit on the app's pages for good. (Reasoned from the code
  and the link read on the real page; not seen in the window.) **The fix, briefed 20:14 to ONE Opus
  coder on `wip/b-onewin` (`BRIEF-B8-W2c-way-back.md`):** a new-window request is also followed for the
  viewer's first page EXACTLY (the root: no path, query or fragment), by a pure function with a table
  of tests; everything else on the viewer's address stays refused; one new step in the joined
  self-check clicks such a link in the real window. Safe because a named page may already send the
  window to any viewer page by a plain link; the review's finding was about the viewer's files and api
  and the raw file with no way back, and the first page is neither.
- **Small things seen, NOT fixed (said in the entry):** the page's title stays "Changes" on Chats, Copies,
  Overlap, Settings and About after Changes was shown (only `changes.js` sets a title; the window's own
  title bar does not show it); "Deleted on Telegram" and Saved Messages were only seen empty (the
  fabricate command makes neither).
- **THE FULL RUNS GO since 20:08 on 4243ba3e (said to the owner first; one script,
  `runs-b8/b8-scripts/fullruns-shell.sh`; `runs-b8/full/summary.txt`):** the viewer whole, the window and
  its command whole, gofmt, vet for both systems, the race detector on the window and on its command.
  The way-back fix changes `internal/window` only: after its merge the window's and the command's runs
  and both race runs are made again on the new head; the viewer's whole run stands (its tree is the same).
- **For the owner's start (the block's step 6), read in the launcher's code (pages' package, read only):**
  the launcher's defaults are the pages on 127.0.0.1:8787, the launcher on 8786, the viewer on 8788, and
  it already gives the collector `-viewer-url` with the viewer's address. So the one window in the
  owner's folder is the launcher's own window start (`present.go`) with `-db`, `-library`, `-staging`,
  `-addr <the viewer's address>` and `-tell-close` added, and the separate viewer start left out. Put to
  pages on the board (message of 20:16).
- **Routine steps:** the merge, tests, build and push by one script call; the full runs by one script call;
  the look's starts and stops by a script; the row, this entry and the commit by one script call.
- **Next:** the coder's hand-back; my read of its rule; merge into `wip/b-shell`; the window's runs on the
  new head; ONE entry for `wip/b-shell` in `MERGE-QUEUE.md`; the board.

## 20:23 (11-16) ENTRY 29 IS LISTED, READY: `wip/b-shell` 73315e27 (the one window with the list in the new look); the removed edge's runs ended clean (B8)
- **The first full runs (on 4243ba3e, ended 20:15; `runs-b8/full/summary.txt`):** the whole viewer on Windows ok
  410.7 s; the window ok 5.5 s; its command ok 2.9 s; gofmt and vet for Windows clean; the race detector
  on the command ok, no race. **Two lines failed, one cause: the window's tests did not build on Linux**
  (`joined_test.go` used `textOpening`, defined in a Windows file; it came with W2 and no run had been made
  on Linux before). Given to the coder who was in that package.
- **The way-back coder's hand-back (20:17; one Opus coder, about 117 thousand tokens; `wip/b-onewin`
  99cef0f1 to bedbc04f, three commits, pushed):** cbe52411 the rule (`joinedNewWindow` also follows the
  viewer's first page exactly; the pure function `viewerRoot`; 12 new table rows); 78334347 the word
  `textOpening` moved into `pages.go`, built on every system; bedbc04f the self-check's steps (b2) a
  new-window link to the viewer's first page followed here, (b3) one to another viewer address refused.
  Its self-check in the real window on a fresh invented archive: checks 14, failed 0. Not as written: B7's
  invented archive is at schema step 26 and `wip/b-onewin` reads 25, so it fabricated its own.
- **Read by me whole:** `viewerRoot` and its use (first `origin.allows`: scheme, no user part, the exact host
  and port, no control characters; then no `?` or `#` anywhere; then the path empty or `/` and no raw path),
  the call site's branches, the moved word.
- **ONE narrow independent look at the rule's change (Opus, read-only, about 103 thousand tokens, 2
  minutes): "MAY BE LISTED"; three lows in the self-check's wording and the test table, accepted as they
  are.** Written down: `REVIEW-B8-W2c-way-back.md`.
- **The merge into `wip/b-shell`: ONE conflict, resolved by me** (`joinedcheck_windows.go`: the list's picture
  step and the way-back steps were added at the same place; both kept, the pictures first), then the main
  head 49c310a1 (clean): **73315e27**, pushed. Named tests, both window packages whole, gofmt, vet, the
  build: clean (one script call through the lock). **The viewer's tree is file for file the same as on
  4243ba3e** (`git diff` empty), so its whole run stands.
- **A slip of mine, said plainly:** my first call started the merge and the window's full runs in one chain
  while the independent look was still out; the conflict stopped the chain before any run started, so the
  order was kept by luck, not by me. The runs below were started after the look came back.
- **The joined self-check in the REAL window on the merged build (`runs-b8/b8-scripts/selfcheck.sh`, one
  start, invented archive, pictures in `runs-b8/look/pictures3`): checks 14, failed 0**, with the pictures
  step before (b2) and (b3) as merged. The library's picture looked at by me: as `pictures2`.
- **The window's full runs on 73315e27 (said to the owner first; 20:21 to 20:22; `runs-b8/full2/summary.txt`),
  every line exit 0:** `internal/window` whole ok 5.7 s; `cmd/tgarchive-window` whole ok 2.9 s; gofmt; vet for
  Windows and Linux; the race detector on `internal/window` ok 6.5 s and on `cmd/tgarchive-window` ok
  52.2 s, no data race (a Linux container: the files built for Windows only are not in it).
- **Entry 29 is appended to `MERGE-QUEUE.md`; the board message of 20:23** tells the integrator and pages;
  the row is new. The review file and the brief are committed with the notes.
- **The integrator's 177 (20:16), read 20:17:** the owner saw my look's window at about 20:10 and took it for
  the old version, because it opened on the app's pages (the old look). Binding: every start line carries
  `-first viewer`; in `look.sh` since 20:17; in entry 29's start line. Three more test windows came up
  between about 20:15 and 20:21 (the coder's two self-checks, mine), each under a minute.
- **The removed edge (`wip/b-edgegone` 3c6ba693): its full runs ended 20:17, every line exit 0**
  (`runs-b15/summary.txt`: the whole viewer on Windows ok 499.3 s; gofmt; vet for both systems; the race
  detector on the whole viewer ok 3,884.4 s, no data race; the copy clean). Not listed yet: entry 27 is
  next (the main head merged in first; a Sonnet clerk drafts the entry from B6's and B7's entries).
- **Routine steps:** the merges' tests, build and push by one script call each; both full runs by one script
  call each; the self-check by a script; the entry, the message, the row and the commit by one script
  call. The conflict was resolved by me (a judgement).
- **Next:** entry 27; pages' answer on the launcher's start line (178 c) or the start script; then the next
  step of the delivery on the viewer's side.

## 20:28 (11-16) THE INTEGRATOR ASKED FOR THE START SCRIPT (181): NOT WRITTEN, said at once; what the owner can open tonight without it (B8)
- **The integrator's 181 (20:27) and its direct message, read 20:26 to 20:27:** entry 29 is in its merge run; write
  the start script for the owner's folder now; say at once if it cannot be done in about 20 minutes.
- **Read by me (pages' `internal/launcher`, read only):** `settings.go` (the settings file's fields; `viewer` is
  window, browser or none; `pages_open` is window or browser, no "none"), `start.go` 154 to 190 (the
  collector's line: `-viewer-url` is given only for the browser kind of viewer; the viewer's start),
  `present.go` 181 (the window's line: `-pages .. -data ..`), `launcher.go` 570 to 580 (one request for the
  home public address before anything starts: the collector's `-public-forbid`), `folder.go` (the layout).
- **Decided: no script.** Starting the collector outside the launcher means copying its steps (the public
  address for the VPN rule, the folder's `updating` mark, the watchdog and status file, the stop at Quit)
  into PowerShell in a hurry, tried against no real collector. Starting only the window beside the
  launcher cannot give one window: the launcher always opens the pages itself and falls back to the
  browser when its window ends. **The right way is three small places in the launcher** (the collector's
  `-viewer-url` for the window kind; no separate viewer window then; the window's line with `-db`,
  `-library`, `-staging`, `-addr`, `-first viewer`): pages'; offered as a lent commit (message of 20:28).
- **WHAT THE OWNER CAN OPEN TONIGHT, checked 20:27 (`runs-b8/b8-scripts/plain.sh`, the listed head's build,
  the invented archive):** the viewer ALONE, as the launcher starts it today, already has the list: served
  by `tgarchive viewer` and read in the browser pane: 28 entries shown, the list 240 px wide at the left,
  no "Overview" entry (no app address is given), the old row of tabs not shown; the window program's own
  self-check in that mode (the real window, one start): 4 checks, 0 failed. So with entry 29 in the folder
  the viewer's window is in the new look; the app's pages stay a second window in the old look.
- **The removed edge:** the main head 49c310a1 is merged into `wip/b-edgegone` (one conflict, resolved by me:
  `refresh_random_test.go`: this branch's removed-edge operations and the head's own-chat operation added
  variables and a closing check at the same places; both kept): bbb8afba, not pushed yet; its whole viewer
  run on the merged tree goes by a script (`runs-b8/edge/summary.txt`); pushed and listed as entry 27 when
  it ends clean (`runs-b8/b8-scripts/mq-27.md` is written, with three placeholders).
- **Routine steps:** the two looks by a script; the message, the row, this entry and the commit by one script call.

## 20:39 (11-16) ENTRY 27 IS LISTED (the removed edge, bbb8afba); THE LAUNCHER'S LENT COMMIT IS WITH A CODER (the integrator's 183); the track's `bin` holds e9413e4e's builds (B8)
- **The integrator's 183 (20:31) and its direct message, read 20:30:** no script, agreed; **yes to the lent
  commit in the launcher, now, on e9413e4e (entry 29 is merged there); list it as entry 30**; the look that
  counts is the folder built from the branch into a copy, started by the folder's own program; second and
  small: rebuild the track's `bin` and say whether the old archive's starter may be handed to the owner.
- **Read by me before the brief (pages' `internal/launcher`, read only):** `present.go` 1 to 150 and 186 to 360
  (the window is started on the launcher's page alone at first; the app's pages are NAMED to it when the
  programs start, and `rescope` then ends the window and starts it again on the new addresses; a window's
  addresses are fixed for its life; any end of its window but the person's is a failure and the browser
  is used), `start.go` 154 to 190, the settings and the layout. **What I decided from it:** the joined
  line only while the pages are named (the catalogue may not exist at the setup page); the app's pages
  FIRST in that line (the viewer's "Overview" leads to the first address; the launcher gives its own page
  first today); no `-data` (the viewer's folder, with its thumbnails); no `-tell-close` (G18's).
- **20:32 ONE Opus coder (high effort) started:** `BRIEF-B8-L1-launcher-one-window.md`, the new copy
  `wt-b-launch`, branch `wip/b-launch` from e9413e4e; `internal/launcher` only; it starts no real program.
- **THE REMOVED EDGE:** the main head 49c310a1 merged into `wip/b-edgegone` (one conflict, resolved by me, both
  sides kept, in `refresh_random_test.go`): **bbb8afba**; the whole viewer on it by B7's script
  (`runs-b8/edge/summary.txt`, 20:28 to 20:36), every line exit 0: ok 488.0 s, gofmt, vet for Windows and
  Linux; pushed; a trial merge onto e9413e4e is clean. **Entry 27 is appended to `MERGE-QUEUE.md`** (it
  stands after 29), written by me from B6's entries of 17:42 to 18:13 and B7's of 19:07 and 19:12.
- **183 d, THE TRACK'S `bin` (one script, `runs-b8/b8-scripts/bin-try.sh`, and one command):** the viewer
  program and the window built from e9413e4e in `wt-b-join` (detached for the build, put back; through the
  lock; `CGO_ENABLED=0`, `-trimpath`; both stamped e9413e4e, not modified). **Tried before anything was
  placed:** the viewer refuses only a NEWER catalogue and opens an older one on purpose (`viewer.go` 254 to
  265, read by me); the old archive's catalogue is at schema step 16 (one number, read read-only by
  `oldstep.py`); an invented catalogue written by each of the six older builds kept in the `bin` (steps
  18, 18, 18, 20, 23, 23), opened by the new viewer: the page, `/api/meta`, `/api/chats`, `/saved` all 200,
  6 chats listed, no error line. **Placed 20:37** (no program of the track ran): 5a13119's two kept as
  backups; the viewer program replaced; the window's as the waiting build (the starter takes it at its
  next start); compared equal. **Not tried: step 16 itself; nothing on the real archive.**
- **Routine steps:** the merge's run and push, the builds and the trial by scripts; the placing by one
  command; the entry, the message, the row and the commit by one script call. The conflict and the
  entry's words were mine.
- **Next:** the coder's hand-back; my read; one narrow independent look; the launcher whole; the look on a
  copy of the folder; entry 30.

## 20:52 (11-16) THE LAUNCHER'S LENT COMMIT IS BACK (`wip/b-launch` c4d0f502), READ; its independent look and the folder's build go (B8)
- **About 20:50 the coder handed back** (18 minutes; about 300 thousand tokens): ONE commit on e9413e4e, pushed;
  `internal/launcher` only: `present.go` +53 -4, `start.go` +22 -2, `words.go` +1 (one log line), a new
  `window_joined_test.go` (247 lines), two existing tests touched. **Verified by me:** the copy clean on
  c4d0f502.
- **As built (read by me whole: the three files' difference):** `joinedViewer(s)`: the viewer "window", the
  pages in the window, and a viewer address the window may take (127.0.0.1 and a port, not 80, not the
  pages' or the launcher's). Then: the collector's line gains `-viewer-url http://<ViewerAddr>`;
  `viewerSpec` answers "none"; `windowForPages` notes it for this start (`win.joined`, cleared when the
  pages end); `ownWindowSpec` then gives a list of three (the pages, the launcher's page, the viewer's
  address), which `rescope` compares as before, and `windowLine` makes the joined line from it:
  `-pages P -pages L -db -library -staging [-mpv] -addr 127.0.0.1:V -first viewer`. Anything else is
  `windowArgs` as on the head. An address that cannot be used: today's two windows, one log line.
- **Its tests:** every combination of the two settings with seven viewer addresses (the exact collector's
  line, whether a viewer starts, the window's line named and not named); two through the launcher's start
  with the stand-ins (one window, no viewer, the joined line; a second start brings it forward with the
  same line; after the end the plain line; the setup's window replaced by the joined one). Two existing
  tests changed openly: `TestViewerSpecPassesStaging` (now with the pages in the browser, so the viewer's
  own window is still checked) and `TestWindowLauncherEndsOnlyItsOwn` (now on the two-window fallback).
  Named families: 35 passed; gofmt, vet for Windows and Linux clean. No test function removed.
- **What the launcher does with the joined window's ends, by its report:** exit 3: "Windows' web component",
  the browser once, "Try the window again"; exit 7 (the viewer's port taken): "another error" with the
  same fallback. In the browser fallback the collector keeps its `-viewer-url` and no viewer runs until
  "Try the window again": accepted tonight, written where the fallback is made.
- **Its doubts, kept for the entry:** (1) the setup's window already names the pages, so at the first
  start's "Save and start" the window closes once and opens again as the joined one; (2) on a very first
  start the joined window is given a catalogue the collector may not have made yet (the look below is
  exactly that case); (3) a window that failed before the programs start: the collector still has the
  link and no viewer runs; (4) a start that finds a watchdog already running is joined too, and an older
  collector then has no link; (5) the settings are read again after the watchdog's start.
- **20:52 started, side by side:** ONE narrow independent look (Opus, read-only: every other combination,
  two windows or none, the flag's life, the callers of the viewer's start, the two addresses, the tests);
  and the folder built from the branch into a copy outside every repository (the scratch folder of this
  session, `runs-b8/b8-scripts/folder-look.sh make`, through the lock).
- **Then:** the look's fixes if any; the launcher's package whole, gofmt, vet (said to the owner first); THE
  LOOK with the folder's own program on a new catalogue (the real collector with no account does nothing
  but say so: `cmd/tgarchive-collector/main.go` 38 to 39, read by me); entry 30.
- **Routine steps:** the folder's build by a script; this entry and the commit by one script call.

## 21:00 (11-16) THE LAUNCHER'S ONE WINDOW: THE INDEPENDENT LOOK ("MAY BE LISTED AFTER THESE FIXES: 1, 2") AND MY LOOK ARE BACK; THE COPY'S LAUNCHER REFUSED TO START (no VPN adapter by the default name); ONE REAL FIRST-START FAULT; the fix round runs (B8)
- **The folder built from c4d0f502 into a copy outside every repository** (the session's scratch folder; one
  script call through the lock; 6 programs), its settings written by a script (scratch folders, its own
  ports 24886 to 24888). The integrator was told in one line before the window came up.
- **20:50 THE COPY'S OWN PROGRAM, started by its full path from another folder: IT REFUSED TO START ANYTHING**
  (its log: "not started: reason 7"; its page: "The VPN adapter named in the settings is not on this PC ...
  Nothing was started, nothing was sent"). The settings named the default adapter. Looked at by me
  (statuses and counts only): no adapter like a VPN's is up or present on this PC at this hour; no dial-up
  kind of VPN connection is up; one process of the VPN's program runs. **I did not point the copy at
  another adapter** (that would be the VPN rule gone round): **the real collector is NOT part of this
  look.** Whether the owner's VPN is connected in a way these looks do not see, I do not know: said to the
  owner and on the board.
- **The joined line BY HAND, exactly as the launcher builds it** (`folder-look.sh hand`; the pages by the
  folder's own page program): **(a) on a catalogue that does not exist yet (a first start): the window
  stays up, says "The archive could not be opened. The catalogue file is not there ..." and NEVER tries
  again** (the api stayed 503 after the catalogue was made). (b) once the catalogue is there: every
  answer 200, the list has 15 entries, "Overview" leads to the app's pages (the first address). A close
  as a person closes: exit 0; the launcher goes on running after its window is closed (as on the head).
  The look's programs were ended by their path under the copy; none is left.
- **20:56 THE INDEPENDENT LOOK (Opus, read-only, 4 minutes, about 136 thousand tokens):
  `REVIEW-B8-L1-launcher-one-window.md`: "may be listed after these fixes: 1, 2".** 1 (medium-high): the
  joined decision looks only at the settings: after a failed window in this run the owner would have no
  viewer; with a viewer window of its own still open the joined window ends at once and the pages show
  nowhere. 2 (medium): changing to the browser while joined ends the viewer with the window. Five lows,
  among them the first-start case my look showed to be real.
- **Decided (in the review file):** 1 fixed the reviewer's way (one decision per start, in `begin`); 2 fixed
  if small, else accepted with a comment; the link in its normalised form; **the first-start fault fixed
  in the window program** (in the joined mode it waits up to 60 s for a catalogue that is not there or is
  being made). **21:00 ONE fresh Opus coder started: `BRIEF-B8-L1b-fixes.md`** (part A the launcher, part
  B `cmd/tgarchive-window`; two commits on `wip/b-launch`).
- **Then:** my read of both parts; the full runs once, said to the owner first (the launcher whole, the
  window's command whole, gofmt, vet for both systems; the race detector on both packages: a decision
  handed through a state machine that runs concurrently, and a wait beside the window); the joined line
  by hand once more on a catalogue that does not exist (the window must come to the library by itself);
  entry 30, saying plainly that the folder's own start with the real collector was NOT seen.
- **Routine steps:** the folder's build, its settings, the starts, the states and the ends by scripts; this
  entry, the message and the commit by one script call.

## 21:13 (11-16) ENTRY 30 IS LISTED, READY: `wip/b-launch` 3b77f5ea (the launcher starts the app as one window; the window waits for a new catalogue) (B8)
- **A correction:** my entry headed 21:00 was written at 20:56.
- **About 21:07 the fix-round coder handed back** (13 minutes; about 226 thousand tokens): two commits on
  c4d0f502, pushed: **8e513c78** (`internal/launcher`: `viewerJoined`, ONE decision per start in `begin`
  before the watchdog's line: the settings, the window not failed in this run, no viewer of the launcher's
  own still running; handed as a parameter to `collectorArgs`, `watchdogArgs`, `viewerSpec` and
  `startViewer`, stored for the window; `windowForPages` no longer reads the settings; the link in the
  normalised form; comments for exit 7 and for a watchdog found running) and **3b77f5ea**
  (`cmd/tgarchive-window`: `waitCatalogue` before `viewer.New` when the viewer's address is listened on
  before the window: a look every 500 ms for at most 60 s, until the file is there and its schema reads and
  is not 0; ends at once with the context, before the next look when the window was closed).
- **The review's 2 (a change to the browser while joined): NOT fixed, the comment's way, and I take it:** the
  change runs on the page's request, the viewer's handle belongs to the start's goroutine; starting a
  viewer from there is a data race or a new action in `follow`. Said in the entry and to the integrator.
- **Read by me whole (the round's difference in the four files):** the decision is made once and stored
  under the window's lock, the viewer's "runs" read before that lock is taken; the three callers take
  the parameter; the wait's loop ends on each of its four conditions. **One thing I noted for the entry:**
  the wait also applies to a catalogue that cannot be READ (60 s of "Opening the archive..." before the
  failure's words), and in the mode with `-addr` alone.
- **Its doubt, kept:** the new stand-in test `TestJoinedNotAfterFallNorBesideOwnViewer` failed once for it (a
  wait of 60 s for the first start's pages) and passed 22 times after; it passed in my whole run.
- **THE FULL RUNS, said to the owner first, one script (`fullruns-launch.sh`; `runs-b8/full3/summary.txt`;
  21:09 to 21:11), every line exit 0:** the whole `internal/launcher` on Windows ok 102.0 s (no failed or
  skipped line); `cmd/tgarchive-window` whole ok 3.4 s; gofmt; vet for Windows and Linux; the race detector
  on the launcher ok 2.8 s and on the window's command ok 75.1 s, no data race (a Linux container: little
  of the launcher's own tests build there).
- **THE LOOK AGAIN, on the copy rebuilt from 3b77f5ea (one script call through the lock), the joined line by
  hand on a catalogue that does not exist:** the page says "Opening the archive... 11 s" with the app's
  link; the api 503; **one second after the folder's page program made the catalogue: the api and the
  chats answer 200** (before the fix: never). A person's close: exit 0. The look's programs ended by their
  path; none left. **Not seen: the folder's own start with the real collector (the launcher's refusal for
  the VPN adapter, my entry before this one).**
- **The main head is aa69cd81 (pages' shell, committed 20:43):** it touches neither of this branch's
  packages; a trial merge is clean; the branch is listed as tested, not merged with it. **Pages' new pages
  were NOT seen by me inside the one window.**
- **Entry 30 is appended to `MERGE-QUEUE.md`; the board message of 21:13** (the integrator: what was seen and
  what not; my recommendation that a copy is started once where the VPN's adapter is present before the
  owner is told "one window"; pages: the two lists until the shell is mounted on the viewer's page).
- **Usage of this session's agents so far (their own counts):** the way-back coder 117 thousand tokens and
  its look 103; the launcher's coder 300, its look 136, its fix round 226: about 880 thousand of Opus.
- **Routine steps:** the copy's rebuild, the look's starts and ends, the full runs by scripts; the entry, the
  message, the row and the commit by one script call.
- **Next:** the integrator's and pages' word; then the shell mounted on the viewer's page or "W2b", with the
  board. **If this session stops here: everything is pushed and listed; nothing runs; the take-over is
  this entry and the row.**

## STATE FOR A TAKE-OVER (B8, 11-16 21:18): enough to take over from this block alone
- **Why now:** three pieces landed in this session and its context is long; a fresh session takes the next
  piece (the start file: `START-VIEWER-B9.md`). Everything below is pushed; the notes are committed on
  `notes`. **Nothing of this track runs: no agent, no script, no program.**
- **The owner's objective (19:31):** deliver the features that work, in the new look, as ONE window.
- **MERGED today:** entry 26 (`-tell-close`), entry 28 (Saved Messages by name), **entry 29 (e9413e4e: the
  one window, `tgarchive-window`'s joined mode, with the list on the left in the new look).**
- **LISTED, READY, waiting for the integrator:** **entry 27** `wip/b-edgegone` bbb8afba (copy `wt-b-faces`;
  the removed edge taken in place; holds 49c310a1). **Entry 30** `wip/b-launch` 3b77f5ea (copy
  `wt-b-launch`; cut from e9413e4e; a LENT commit in pages' `internal/launcher`: with the defaults the
  folder's program starts ONE window; and `cmd/tgarchive-window` waits up to 60 s for a catalogue not made
  yet). Each entry in `MERGE-QUEUE.md` says what is NOT verified. If the integrator hands one back: read
  its message, one fresh Opus coder on a written brief, the named tests, the entry again.
- **WHAT NOBODY HAS SEEN (the first thing to do when it becomes possible):** the folder's own program
  starting the REAL collector and the one window together. My look's copy of the folder refused to start:
  "The VPN adapter named in the settings is not on this PC" (20:50; the default adapter name; I found no
  VPN-like adapter on the PC then and did not go round it; told to the owner and on the board, 189 a).
  The tools for that look are ready: `runs-b8/b8-scripts/folder-look.sh` (`make`, `settings`, `start`,
  `state`, `hand`, `app`, `close`, `kill`; the copy lives in this session's scratch folder: give it a new
  folder outside every repository, `make-folder.sh` refuses one inside a repository).
- **THE OLD ARCHIVE'S STARTER (folder `b`):** the track's `bin` (`%LOCALAPPDATA%/tgarchive-b/bin`) holds
  e9413e4e's builds since 20:37 (the window's as `tgarchive-window.build.exe`, taken at the starter's next
  start; 5a13119's kept as `.5a13119.bak`). It may be handed to the owner as it is: the viewer opens an
  older catalogue on purpose (the old archive's is at schema step 16; tried on invented catalogues of
  steps 18, 20 and 23, not on 16, not on the real archive). After a later merge that changes the viewer or
  the window: `runs-b8/b8-scripts/bin-try.sh build <head>`, then `old`, then place as the entry of 20:39
  says.
- **THE NEXT STEPS, in order:**
  1. Read the board's messages after 191 and the integrator's row: whether 27 and 30 are merged, and what
     the owner saw at the first start of the rebuilt folder (that comes before everything else).
  2. **Pages' shell on the viewer's page.** Pages' `internal/appshell` is on the head since aa69cd81 (its
     W1); the viewer's page still draws its own list (`internal/viewer/web/js/shell.js`, the block in
     `app.css`). Until the shell is mounted on the viewer's page there are two lists in two looks (the
     viewer's and the pages'), and I have NOT seen pages' new pages inside the one window. Read
     `DESIGN-ONE-WINDOW-HOW.md` and `internal/appshell`'s door, ask pages on the board which call mounts it
     (its 166 c offered it), then ONE Opus coder; pictures by the joined self-check
     (`TGARCHIVE_JOINED_PICTURES`) and a look with the real programs before listing.
  3. Pages' 188 (20:42), read by me late (21:14): the pages first and the launcher's page second breaks
     nothing; its one optional line (do not arm the launcher's redirect when the joined window is what
     runs: `openPages`, the window's branch) is NOT in entry 30: add it with the next touch of the
     launcher, or leave it to G18.
  4. The review's finding 2 of entry 30 (a change to the browser while joined ends the viewer with the
     window): accepted with a comment; mended only with a new action in the launcher's `follow`: pages'.
  5. Small, known: the page's title stays "Changes" on five places in a browser tab; the three lows of
     `REVIEW-B8-W2c-way-back.md` (the self-check's wording, two table rows); the joined self-check's clip
     step is not built; "W2b" (the app's own title bar) is not started.
- **This track's copies:** `wt-b-launch` and `wt-b-faces` (listed: keep until merged); `wt-b-shell`,
  `wt-b-onewin`, `wt-b-saved`, `wt-b-join` (merged; `wt-b-join` makes the `bin`'s builds: keep it; the
  others may go after a check that each is clean and equal to its branch on `private`: one Sonnet clerk);
  three looks' scratch copies of B7 (`wt-b7-review-*-scratch`: their reviews are files: may go).
- **This session's tools (`runs-b8/b8-scripts`):** `save.sh` (the queue, the board, the progress file and the
  notes commit in one call; it uses `runs-b7/b7-scripts/board.py`), `merge-shell.sh`, `build-test.sh`,
  `fullruns-shell.sh`, `fullruns-launch.sh`, `look.sh` (the one window by hand on invented archives),
  `selfcheck.sh`, `plain.sh`, `folder-look.sh` with `folder-settings.py` and `folder-procs.ps1`,
  `bin-try.sh`, `oldstep.py`. The track's go lock: the folder `runs-b7/golock` through
  `runs-b7/shell/scripts/gorun.sh`.
- **Message numbers, a correction:** my board messages are 178, 180, 182, 186, 189 and 191; where my row and
  message 191 say "187 a" for the VPN adapter, it is 189 a (187 is pages' listing of W1).
- **Lessons of this session (my reading):** the look with the real programs found the two faults that
  mattered (no way back from the app's pages; a first start that never opened the archive) after the
  reviews and every test had passed: do it before listing, with a catalogue that does not exist yet too;
  a test window on the screen was taken by the owner for the old version within ten minutes: say so
  first and open on the approved look; asked for a start script, the right answer was no and the
  launcher's three places; I read pages' answer half an hour late because I looked for new messages only
  by their number at the end of the board: read every message after my last one at each hand-back; three
  of my headings were a few minutes ahead of `date`.

## The board row's state before 11-21 21:08 (moved here by session B7 to shorten the board)
| Viewer and bring-in (step 1) | **session B8** (viewer; took the track over 11-16 20:03 from B7's block of 20:00, started by the owner with `START-VIEWER-B8.md`; B7 and the sessions before it are retired: do not wait for them or message them); progress in `SESSION-B-PROGRESS.md` under "SESSION B8" | `internal/viewer`, `internal/window`, `internal/bringin`, `cmd/tgarchive-bringin`, `cmd/tgarchive-window`, `cmd/tgarchive/viewer.go`; copies `wt-b-*` | **11-16 21:18 (session B8): ENTRY 30 IS LISTED, READY since 21:13: `wip/b-launch` 3b77f5ea: THE LAUNCHER STARTS THE APP AS ONE WINDOW** (a lent commit in pages' `internal/launcher` at the integrator's word, 183, with its fix round; and the window program waits up to 60 s for a catalogue that is not made yet). One independent look ("may be listed after these fixes: 1, 2": 1 fixed; 2 accepted with a comment: a change to the browser while joined ends the viewer with the window); the full runs every line exit 0 (the whole launcher 102.0 s, the window's command, gofmt, vet for both systems, the race detector on both). **SEEN: the joined line by hand exactly as the launcher builds it, with the folder's own programs (a copy of the folder outside every repository): the window comes to the library by itself once a new catalogue is made; the list; "Overview" to the app's pages. NOT SEEN BY ANYONE: the folder's own program starting the real collector and the one window together: the copy's launcher REFUSED to start because no VPN adapter by the default name is on this PC at this hour (board message 189 a: the owner's to look at; nothing of mine touched the VPN, the owner's app or its settings).** **ENTRY 27 IS LISTED, READY since 20:39: `wip/b-edgegone` bbb8afba (the removed edge, the viewer's side).** **ENTRY 29 IS MERGED (e9413e4e: the one window with the list in the new look).** **THE OWNER'S SENTENCE, true now: the app opens as before; with the folder rebuilt from e9413e4e or later the VIEWER's window has the list on the left in the new look; ONE window comes when entry 30 is merged and the folder rebuilt, and its first start on the owner's folder will be the first real one.** **THE OLD ARCHIVE'S WINDOW STARTER (the folder `b`) may be handed to the owner as it is: the track's `bin` holds e9413e4e's builds since 20:37 (taken at its next start): the list on the left in the new look, no "Overview" entry; tried on invented catalogues of older steps (18, 20, 23), not on step 16 itself (the old archive's) and not on the real archive.** **What does NOT work yet, said plainly:** pages' new shell (aa69cd81) and the viewer's list are two lists until the shell is mounted on the viewer's page (pages names the door, I mount it): NOT seen together by me; Saved Messages is empty on a new archive until Core's piece of 173 reads it (never seen filled; nor "Deleted on Telegram"); no state pill, no counts beside most views, no chat states; Windows' own title bar; a clip never played in the joined window; the narrow width and the light theme not looked at; no click by a person inside the real window; the old archive's Saved Messages not confirmed. **THE STATE FOR A TAKE-OVER is the block "STATE FOR A TAKE-OVER (B8, 11-16 21:18)" at the end of `SESSION-B-PROGRESS.md`; a fresh session is started by the owner with "Read `START-VIEWER-B9.md` and do what it says" for the next piece; this session still answers the integrator on entries 27 and 30 while it is open. Nothing of this track runs.** **NEXT (the block's order):** what the owner sees at the first start of the rebuilt folder; pages' shell mounted on the viewer's page (pages names the door); pages' optional line of 188 (read late, 21:14: not in entry 30). **The owner's, open:** item 39 (the first real click) on hold; the NAS thumbnail measuring run; `-Lan` from the window. **The track's copies:** `wt-b-launch` (listed), `wt-b-faces` (listed), `wt-b-shell`, `wt-b-onewin`, `wt-b-saved`, `wt-b-join` (merged: may go after a check; `wt-b-join` makes the `bin`'s builds), three looks' scratch copies (may go). Routine steps: by scripts in `runs-b8/b8-scripts` and `runs-b7/b7-scripts` or one Sonnet clerk call, said in each entry. |

# SESSION B9 (viewer and bring-in; Opus; started 11-21 21:08 by the integrator I-6, detached)
## 11-21 21:08: taken over from the block "STATE FOR A TAKE-OVER (B8, 11-16 21:18)"
- Started by the integrator (I-6) with `START-VIEWER-B9.md`. Model rule since 11-21 (the owner): Opus is the
  orchestrator; Fable only if fully stuck, after asking the integrator on the board. Coders Opus 5.5 high.
- What changed since B8's block: entries 27 (c866927) and 30 (9980a21) are merged; G18 and G19 merged on the
  pages' side; the main head is af4ca40. The owner's folder was built from 70b0c7e and runs since 11-19 00:30 as
  ONE window: the first real use of the joined window; the owner has not said what they saw. Never stopped,
  restarted or reconfigured by me; any test window on the owner's screen is announced on my row first.
- My order, as given: (1) pages' shell (`internal/appshell`) and the viewer's own list made ONE, with pages
  (session P7); (2) the unified archive's viewer side with copies (session C7 writes `DESIGN-UNIFIED-ARCHIVE.md`
  first): the old archive and the new accounts in one view, media the old archive lacks flagged as new; (3) the
  rest of B8's "THE NEXT STEPS".
- Tools: `runs-b9/b9-scripts/save.sh` (B8's, copied: Opus co-author line, B9 globs). Nothing of this track runs.
- Board row cut at the take-over: B8's row moved below by `board.py row --keep-old`.

## 11-21 21:11: W1v (the two lists made one) with one Opus coder
- Read: B8's block; the board's viewer, pages and integrator rows; messages 173 to 203; `DESIGN-ONE-WINDOW.md`
  and `DESIGN-ONE-WINDOW-HOW.md` (sections 2, 3, 9); `internal/appshell` (shell.go, assets/shell.js) and the
  viewer's own list (`web/js/shell.js`, `nav#places` in index.html, main.js's router), on af4ca40.
- Judged: appshell is the base (the joint note). What the viewer's list has that the package lacks: Photos,
  Videos, Files, Changes, the deleted count, hidden chats left out, Copies, Overlap, the viewer's Settings and
  About, the device-at-home page keeping its top bar. What the package has that the viewer's lacks: Overview,
  Collecting, the pill, chat states, Program, dead entries with a reason.
- Board message 204 to pages (P7): the lent part in `internal/appshell` proposed, additive only, in ONE
  commit of its own ("Lent to pages (appshell):") so that it can be reworked or dropped; P7's yes asked
  before it lands; P7's W1-review fixes in appshell to be taken in either way.
- Copy `wt-b-onelist` made from af4ca40, branch `wip/b-onelist` (one command, by me). PC 9.9 GB free, 41% CPU.
- **One Opus coder (high) started 11-21 21:11 on `BRIEF-B9-W1v-one-list.md`**: part A the lent appshell commit
  (Entry.Count, Options.Counts, SkipChat, NoCollector for the old archive's window, Photos/Videos/Files and
  Changes in Library, a "Viewer" group); part B the viewer mounts the shell on this PC's page only (its own
  list, top bar and "The app" link removed; search into the content's head; the router's hook and select);
  part C the joined self-check's pictures (one real window up to 90 s, announced on my row).
- Not in this piece, said plainly: the pill on the viewer's pages (a cross-server read: the next piece);
  the launcher's address on the viewer's pages if the window is not given it.
- Next: P7's answer to 204; the coder's hand-back; my read of the risky part; one independent review.

## 11-21 21:16: pages' 206 crossed my 204; copies' unified note read; U1 (the bring-in into the app's catalogue) with a second Opus coder
- Pages (P7) posted 206 at 21:11, the mirror of my 204 (its coder, my side lent). Answered in 208: one coder
  (mine, already at work), one branch `wip/b-onelist`, pages' side as ONE lent commit P7 reads and approves;
  counts from the catalogue measured at real size and the pages' server-side read of hidden chats are pages'
  next pieces on the same door. Not yet answered by P7.
- Copies (C7) wrote `DESIGN-UNIFIED-ARCHIVE.md` (210): one catalogue for both; the old archive brought in as
  an account never signed in. Read whole by me; with it `BRINGIN-WANTED.md` whole, TRIED-BEFORE 6, 9, 10,
  and the bring-in's run.go (refusal, account, chats). **Not read in full by me (said plainly): the rest of
  TRIED-BEFORE, LESSONS, COPY-CHECKS-STUDY, TELEGRAM-FACTS**; C7 read them for the note; this piece touches
  no download path and writes nothing real.
- Answered in 211: the viewer derives the four words itself (one bit per file, no door); the bring-in's five
  rules to a coder now; one door asked of Core: `MarkBroughtIn(ctx, account)` and the old library's root.
- Copy `wt-b-unified` from af4ca40, branch `wip/b-unified` (one command, by me). **Second Opus coder (high)
  started 11-21 21:16 on `BRIEF-B9-U1-bringin-unified.md`**: a mode `-into-app` (never default), rules 1 to 5, a dry
  run, tests on invented catalogues only; `MarkBroughtIn` through the bring-in's Doors (stops cleanly when
  missing). Both coders share the track's go lock.
- Running: coder W1v (`wt-b-onelist`), coder U1 (`wt-b-unified`). Next: hand-backs; my reads; one
  independent review each.

## 11-21 21:29: pages agreed (216); its two changes to part A handed to coder W1v
- Pages (P7), 216: one coder (mine), one branch; no second coder of pages. P7 changed part A of the brief in
  two places (Counts takes List's context, a count not ready left out; no group "Viewer": Copies and Overlap in
  Library, Viewer settings after Settings at the foot, About last); handed to the coder by one message.
  The catalogue-side counts and the pages' server asking the viewer for hidden chats are pages' next pieces.
  P7 reads the lent commit before listing: its head to be said on the board.
- Copies (C7), 213 d: my 211 agreed in full; the door names are Core's (K-6): not yet named.
- The integrator (I-6), direct message: the owner says the running app is no reason to hold back fixes;
  tries go in a folder of our own with invented data and LOCALAPPDATA redirected. Nothing of this track was
  held back; W1v's self-check is already of that kind (`runs-b9/look`).
- Client track (A-1), 215 b: its step 3 buttons are the viewer's once the owner agrees (item 45): nothing now.

## 11-21 21:40: W1v handed back (1e9da60e, pushed); my read; a fix round with the same coder
- Coder's commits: eba58517 and 091983ea (lent to pages, appshell), ae7c95d0 (the viewer mounts the shell;
  its own list removed), 1e9da60e (the window's joined self-check looks for the one list; LauncherURL from the
  second `-pages` address). Tests by name: appshell whole 3.2 s and 4.3 s; the viewer's named sets (shell,
  wall, LAN classes, cross-site, page scripts, saved, video) pass; one failure fixed and re-run
  (TestHomeDeviceGetsNoWindowBehaviour); gofmt; vet of `internal/window`. The self-check once: 19 checks, 0
  failed; pictures in `runs-b9/look/pictures1` (a-library, b-deleted, c-chat; no Saved Messages picture: the
  invented archive has no own chat). Looked at by me: a-library: the one list, the strip, the search in the
  library's head.
- My read of the risky part (shellmount.go, server.go's fillPage gate and route classes, the window's
  LauncherURL): this PC only by class local plus a second lock; the device's page unchanged; the list read
  through the clicks' read-only catalogue handle (no second open). **Found: the list's reads on an OLDER
  catalogue (the old archive's window, step 16): catalog.Open read-only does not migrate, so a read on a
  missing table would answer 500 and leave the list empty: a regression for the old archive's window.** And
  the coder's find: pages' `.as-pill` shows two empty outlines when hidden.
- Fix round to the same coder (resumed, its context kept): List degrades per part on an older schema (a lent
  commit), the pill line, a viewer test at step 16; board message 220 to pages: read the lent commits, confirm
  the changed foot test, the launcher's address order.
- Next: the fix round's hand-back; ONE independent Opus review of the whole branch; its fixes; the full runs;
  the look with the real programs (filled, empty, not made yet); then the entry in `MERGE-QUEUE.md`.

## 11-21 22:08: W1v's fix round back (dad8caa1, pushed); ONE independent Opus review started
- Fix round by the same coder: 8673ec5c (lent to pages: the list on an older catalogue drawn per part, told
  apart from a fault of this build by the existing doors `FileSchema`/`FitOf`; the pill's `[hidden]` rule;
  pages' two Chats lines) and dad8caa1 (the viewer's test at step 16 and at the v2 shape). At step 16 none of
  the list's four reads fails; at v2 three do and are drawn without their data. Tests by name: appshell whole
  5.2 s (14), TestShellOlderCatalogue 6.8 s, the shell and wall tests 8.2 s; vet of appshell; gofmt. The
  self-check rebuilt from dad8caa1: 19 checks, 0 failed; pictures `runs-b9/look/pictures2` (the empty pill
  outlines gone). A first re-run was void (the build gave up at 93-100% CPU and ran the old exe): said by the
  coder, its pictures deleted.
- Pages (P7): 221 the lent part approved, 8673ec5c said yes in advance (220 b); 226: W1's fix round W1b is cut
  from dad8caa1 and merges after W1v; it re-asks the list every 60 s and on a state change (accepted for the
  viewer's pages); 225: G18d lends one commit in `cmd/tgarchive-window` (finding 7) for me to read.
- Core (K-6), 227 b: the bring-in's account setting can name a reused account number: sent to coder U1 with
  "refuse in -into-app mode when the number no longer names the bring-in's account" and "name every new key
  that carries an account number" (Core's `accountSettings` list).
- **Review started 11-21 22:08:** one Opus reviewer on `BRIEF-B9-W1v-review.md` (the code and the goal, not my
  conclusions; a scratch copy of its own; output `REVIEW-B9-W1v-one-list.md`).

## 11-21 22:10: U1 handed back (`wip/b-unified` 04000899, pushed); my decision on its point 1; its review started
- Five commits (c68a1f16, a992c606, 0da6e89a, d127c1c7, 04000899), all in `internal/bringin` and
  `cmd/tgarchive-bringin`. The mode `-into-app`: its own keys under `bringin.app.v1.` (never `bringin.v1.*`);
  refusals before any write (not a catalogue, the other mode's catalogue, a different schema version: opening
  read-write would migrate the app's catalogue, `ErrAccountTaken`, `ErrAccountLost`); rule 2 no chat choice
  (the old choices as JSON per chat, never read by the collector); rule 3 only adds, with a guard that undoes
  a chunk if a state of the app changed (`ErrWouldChange`); rule 4 chunks of at most 2,048 rows, the writer
  held 153 ms at most (3,000 messages, 51 transactions); rule 5 old places beside the app's; a dry run.
  Tests by name: 7 new of the mode (1.4 to 4.4 s each), 8 earlier ones unchanged, the command's two; gofmt
  and vet of both packages. Commits made by the coder itself, not by a clerk.
- Doors WANTED of Core: `MarkBroughtIn` (with its point b: a message catalogued for this account never
  changes a file's collector state) and `OwnerSpokeOn`; without them a run stops at the account stage, before
  writing. Board message 230 to Core: the contracts, the key `bringin.app.v1.account` for its list, the
  second root resolving source "old app".
- **Decided by me (the coder's point 1): a plainly wanted file of the app becomes saved by the old app's bytes
  when it is the same Telegram file** (exact evidence by the copy rules; the note's 114 files); every file in
  another state or the owner spoke on keeps it. Said in 230 e.
- **Review started 11-21 22:10:** one Opus reviewer on `BRIEF-B9-U1-review.md`; output `REVIEW-B9-U1-bringin-unified.md`.
  Two reviews run (W1v's and U1's).

## 11-21 22:11: U2 ("in the old archive" or "new" in the viewer) with a third Opus coder
- Copy `wt-b-oldnew`, branch `wip/b-oldnew`, cut from `wip/b-onelist` dad8caa1 (it uses the list's count door).
  PC before: 7.4 GB free, 60% CPU; go commands queue on the track's lock.
- Coder started 11-21 22:11 on `BRIEF-B9-U2-old-or-new.md`: one bit per file (an old-app place) read with the index and
  kept by the change log; the word per media as JSON data (the owner, 11-21: "remember the interface, since the
  whole app will need a rework for UI"); a filter `/?old=new`; the counts per account and chat at
  `/api/oldnew`; the list's count `lib:oldnew` through Counts; the appshell entry named for pages, not edited.
- Running now: reviewer of W1v, reviewer of U1, coder U2.
