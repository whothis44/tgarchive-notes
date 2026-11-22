# Lessons from the fork's archive viewer (12.22–12.31), for the new app's viewer

Written 2026-11-14 while fixing the fork's viewer for 12.32 (worktree `wt-v12.32`, branch `ix/v12.32`). The
before and after numbers are in section 5. Everything was measured
on invented data only (`core-service/internal/app/viewer_big_test.go`, at the real archive's size). Real
archive figures below are counts only, read read-only.

## 1. What the owner said
- 11-09 (12.22): slow to open a file, albums not shown as one post, Chats "doesn't work at all", 20+ copies
  listed. Viewing the most complete set comes first; the information is second.
- 11-14 (12.31): the new viewer is "basically busted, doesn't work at all … painfully slow"; "the old viewer
  [the media browser] at least loads".

## 2. The scale a viewer must handle (real archive, 11-14, counts only)
- 584k messages, 396k with media (254k videos incl. gifs, 125k photos, 8k stickers); 53.6k albums holding
  283k of those messages (largest 90 files); 85% of media messages are forwards.
- 352k files in the model, 185k distinct, 291k saved; 213 chats (the largest holds 36k media messages).
- **Messages are bunched by month:** 77 months, the largest has 69k media messages and the 8 largest hold
  78%. A "month" can't be a unit of loading.
- 85k pictures with a grid thumbnail; **254k videos with almost no thumbnails made**: the server's
  background maker is paused while the staging backlog is large, which is most of the time.
- 205k image embeddings (768 bytes each), 84k faces, 65k video matches, 54k held copies.
- The live server's own model of all this ("browser index") takes about 22 s to build.

## 3. What made the fork's viewer slow or look broken (found so far)
1. **A second process rebuilt the whole model.** The viewer is a separate program that builds the same model
   as the server from the database (read-only, small cache). On the invented archive at real size:
   - **77 s** at 2 cores while the PC was busy (CPU near 99%, the owner's own viewer building at the same time);
   - **9–14 s** on a quiet PC with the database in Windows' file cache.

   The model held 520 MB of heap and asked the system for 840–1,010 MB. In the busy run, 45% of the build was
   reading the 157k image embeddings in key order (SQLite page reads). They are needed only for one
   "look-alike pictures" row.
   - **Lesson: measure under the load the owner's PC really has.** My first baseline was mostly load, which I
     only noticed when the "after" number came out 7 times better than the work removed could explain. Observed on
   the PC (process counters only): the owner's viewer held **2.2 GB working set**, beside a 3.8 GB server, on
   a PC with 2.5–5 GB free.
   - The page showed a blank area during that time: no "reading the archive" message.
   - After 30 minutes without use it stops, so every later visit pays the full build again.
2. **It rebuilt every minute while in use.** It checked the archive's stamp every minute, and the downloader
   changes the archive every minute, so a viewer in use rebuilt the whole model about once a minute. That
   meant two models in memory during each build, and tens of seconds of CPU beside the downloader.
3. **Thumbnails held the browser's connections.** A tile's thumbnail, when not made yet, made the request
   wait up to 3 s for ffmpeg to read the video from the NAS over Wi-Fi (2 workers). The dashboard is plain
   HTTP/1.1, so a browser opens about 6 connections to it; a screen of video tiles filled them. The grid's
   other pictures, the next month's tiles and **the file a click opened waited behind them**. The old media
   browser answered at once with Telegram's preview: that is why it "at least loads".
4. **Every request ran the whole filter again.** The grid count, then each month's tiles, then each page of
   posts each filtered every distinct file; posts also walked every post and sorted them. On the invented
   archive: video filter 0.65 s, text search 0.41 s, posts page 1 0.34 s, **posts page 2 2.24 s** (all
   posts walked and sorted again for 30 more).
5. **A whole month in one answer.** A month's tiles came in one answer and were laid out at once (1.2 MB of
   JSON for a 6k-tile month on the invented archive; the real archive's months are larger).
6. **Album tiles broke the month order (a real bug).** Folding an album into one tile put the tile in the
   month of the file shown, out of the grid's newest-first order. The months list then repeated months: 201
   sections for 95 months on the invented archive. The page loads a month only once, so the repeated sections
   stayed **empty gaps** while scrolling.

## 4. Lessons for the new app's viewer
- **Build the read model once, in the process that already has it, or keep it on disk.** Don't let a
  second process rebuild a 350k-item model from SQL on every start. If the viewer is separate, give it an
  incremental or persisted index (append new files; rebuild in full rarely), and measure its first-open
  time at the archive's size.
- **Never rebuild on a timer keyed to "the archive changed"** while a downloader writes every minute. Update
  incrementally, or rebuild rarely and in the background, with one copy of the model in memory.
- **No request that a page depends on may wait for slow I/O.** Thumbnails: answer at once with what exists
  (a stand-in), make the real one in the background, newest asked first, and let the page ask again. Count
  the browser's ~6 connections per host as a shared, scarce resource (or serve HTTP/2).
- **Make thumbnails ahead for videos.** In the fork almost no video has one, because the makers pause under
  the staging backlog. A video thumbnail made while the file is still on local staging costs no network.
- **Evaluate a filter once per query and keep it**, keyed by the index, the owner's decisions and the
  settings; page through the kept result. Let concurrent requests for the same query wait for one run.
- **Page by count, not by calendar.** Months hold 0 to 70k items.
- **Show progress.** A blank page for a minute reads as "doesn't work at all".
- **Test at the real size with a generator that matches the archive's shape:** month bunching, album sizes,
  forward ratio, video share, missing thumbnails. The fork's own scale test (12.22) built the model in memory
  and skipped the database, the thumbnails and the page, so it reported "a quarter of a second" and "1–16 ms"
  while the real thing took 9–77 s, depending on how busy the PC was.
- **Check that grouping keeps the order the page relies on** (an album folded into one tile must stay in its
  place's month), with a test that the months list has no repeats.

## 5. Fixes in 12.32, with numbers

On the same invented archive (real size), 2 cores, quiet PC.

Server side (`TestViewerBig`, runs alternated):

| | 12.31 | 12.32 |
|---|---|---|
| Build the index | 9.1–9.5 s (14.3 s on the first, colder run) | 6.4–6.9 s (11.4 s on the first) |
| Heap in use | 520 MB | 405 MB |
| Asked of the system | 840–1,010 MB | 640–660 MB |
| Posts page 2 | 88 ms | ~1 ms |
| Month list | 201 months (repeats) | 83 months (no repeats) |

The browser side (`tests/ui/viewer_big.py`) used an ffmpeg stand-in that takes 2 s per video thumbnail:

| | 12.31 | 12.32 |
|---|---|---|
| Open a file (its details shown) | 0.86 s | 0.11 s |
| Next file | 0.01–1.85 s | 0.01–0.03 s |
| Thumbnail answers | median 8.1 s, max 18 s | median 21 ms, max 44 ms |
| Item answers | median 0.95 s, max 2.0 s | median 19 ms, max 51 ms |
| Posts view | 2.4 s | 0.12 s |
| Search a word | 2.4 s | 0.22 s |
| Open the largest chat | 2.9 s | 0.20 s |
| Chats list | 0.8 s | 0.04 s |
| Tiles after scrolling 6 screens | 152 (no new tiles) | 433 |

The first tile showed in 0.4–0.5 s in both, because the test server builds its index before serving. On the
real archive the first open also pays the index build, now with a "Reading the archive… N s" message.
Not measured: the real NAS's thumbnail times (2 s is an assumption) and the real archive itself
(privacy: never opened).

What changed:
- The index is checked against the archive every 10 minutes, not every minute.
- While the first index is built, the info answer says so at once (with the seconds so far), and the page
  shows "Reading the archive… N s" and asks again.
- Filters are run once and kept (the last 8, for the current index); months and posts are cut from the kept
  result.
- A month comes in parts of at most 1,000 tiles; the page asks for the next part when it scrolls near.
- Thumbnails: a tile never waits; it gets Telegram's preview (or the tiny one) at once, and the thumbnail is
  made newest-asked first (at most 256 waiting). Tiles still without one are marked, and the page asks again
  a few times.
- Album tiles keep the month of their place: no repeated months, no empty gaps.

## 6. What the independent review caught (fixed before release)
- **Paging by position breaks when the index is rebuilt between pages.** New files at the top move every
  later position, so part 2 repeated tiles from part 1 and the arrow keys looped. 12.32 drops tiles already
  shown. A stable key (the last item's date and id) is better for the new app.
- **The keyboard order must follow paging.** The arrow keys used only the parts loaded so far, so they
  stopped (or jumped a month) at the end of a part. Now → at the end of a part loads the next part first.
  The browser check passes: 1,200 tiles before, 3,000 after, and the next file is in the same month.
- **"Pending" needs a "done" signal.** The page could not tell a stand-in from the real thumbnail, so it
  re-asked 3 times regardless. And thumbnails served from the archive's own caches stayed "pending" forever.
  Now the server sends `X-Thumb: made|standin`; the page checks with HEAD and swaps the picture in only when
  it is made. Stand-ins for a thumbnail being made are not cached (they had `max-age=3600` under the final
  address).
- **Small things:**
  - an empty "look-alike" row when nothing was embedded;
  - an evaluation cache emptied by late requests on an old index;
  - a failed part never asked again (an IntersectionObserver fires only on a change);
  - a short row every 600 tiles;
  - two "reading the archive" loops;
  - timing and exact-number assertions that could be flaky in CI.
- **Lesson:** an independent read-only reviewer found 2 confirmed user-visible regressions in code whose
  timings were already excellent. Run one before calling UI work done.
