# Review B3-5: the viewer at a46139f (`wt-b-faces`, `wip/b-filters`)

Read-only, by reading the code only. No test, no go command, nothing started. Line numbers are at a46139f, in
`archiver/internal/viewer`.

## Confirmed

### C1. The library jumps back to the top while the index changes (every ~2 s with the collector running, and for the first ~1.5 min after start)
- **Sequence:**
  1. `handleShape` stamps the shape with `gen` (library.go:679). Every index version gets a new gen (viewer.go:244-257).
  2. A new version is made by every update that finds any change (refresh.go:139-146, 238). While the collector writes, that is every update, at most every `MinRebuild` (2 s).
  3. Until the first face read is done, `watch` marks every update dirty (viewer.go:323-325). Each slice changes face counts (`d.faceSet` non-empty, refresh.go:238), so it makes a new version every ~2 s. That is about 45 slices on the real catalogue (faces.go:86-93).
  4. The page then scrolls to a block it has not loaded. `loadBlock` sees `res.gen !== this.shape.gen` and calls `update(…, true)` (library.js:708-710).
  5. `update` drops every loaded block and node. Because `this.key` is already set, `sameFilter` is true and it runs `window.scrollTo(0, 0)` (library.js:121, 150-155, 165).
- **Two smaller paths to the same reset:**
  - `v.gen(ix)` returns 0 when the version is swapped between `v.index()` and `v.gen()` (viewer.go:246-247; library.go:679, 770).
  - The faces-done reload and every prefs reload also scroll to the top (library.js:415, 100-101).
- **What the owner sees:**
  - Scrolling down the library, the grid turns to grey boxes and snaps back to the newest tiles. While the collector runs, nothing deeper than a few seconds' scrolling can be reached.
  - Opening a post deep in the grid, closing it and scrolling on throws them to the top.
  - The browser check has no case where the index changes between the shape and a block (`browsercheck/run.py`).
- **Smallest fix:**
  - Serve a block from the listing its shape was built on. `listCache` already keeps each listing with its own `ix`: send the listing's identity (gen plus the decisions version) with the shape, pass it back on `tiles`, and answer from that cached listing while it is held.
  - Only when it has been evicted, reload the shape keeping the place: no `scrollTo(0,0)` on a forced reload, re-anchor on the first visible tile's cursor.
  - Take the gen from a value kept on the index (or on the listing), not from a map entry deleted at swap.
- **How sure:** certain from the code. The ~2 s rate is the update pacing in viewer.go, not a measurement.

### C2. Previous / next on the post page ignore the time zone, so with a date filter they stop early or step outside the range
- **Sequence:**
  - A tile's link carries `ctx=lib:` + `this.query`, which holds only `FILTER_KEYS`, without `tz` (library.js:12-13, 57-61, 726-727).
  - `neighbours` parses that ctx with `parseFilter`, which falls back to UTC (post.go:922-924; library.go:63, 118-128). `from`/`to` then cut at UTC midnight, while the grid used the page's zone.
- **What the owner sees (UTC-5, filter From A To B):**
  - Posts from 19:00 to 24:00 local on day B are in the grid but not in the neighbours' listing. They are the top tiles. Opening one finds no run (`first < 0`), so both arrows say "This is the first/last post" (post.go:947-949).
  - From the last tile in range, → steps into posts from 19:00 to 24:00 local on the day before A, which the grid does not show.
  - The same applies to "New between" with `first=1`.
- **Side effect:** the key differs from the grid's, so every post opened from the library builds a second listing after each index change. On the real catalogue that is 23-76 ms unfiltered and 141-207 ms with `first=1` (SESSION-B-PROGRESS.md line 323-324).
- **Smallest fix:** carry `tz` in the ctx (or as its own parameter of `/api/post`) and use it in `neighbours`.
- **How sure:** certain from the code.

### C3. "Only where it first appeared" hides files that no shown copy stands for (groups are not symmetric)
- **Sequence:**
  - A file's group is its exact closure plus one probable step from it (appear.go:105-138). A file is shown only when its group's first place is its own (library.go:375-379).
  - Take probable edges t~x and x~y, no edge t~y, with y posted before x and x before t:
    - G(t) = {t, x}. Its first place is x's, so t is hidden.
    - G(x) = {x, t, y}. Its first place is y's, so x is hidden.
    - G(y) = {y, x}. y is shown.
  - So t appears nowhere, although nothing one step from it is shown. The 64-file exact cap makes groups asymmetric the same way (appear.go:116-124).
- **What the owner sees:** with `first=1` (the default `sameprob`), media missing from the combined view, represented only by a file two steps away. That is the chaining the owner refused.
  - On the real catalogue the largest group was 4,463 files, around one file with about 4,462 probable links (SESSION-B-PROGRESS.md line 325). Every link posted after that hub, and the hub itself, is hidden this way.
  - The planned cap (a file with more than 20 probable links pulls in none) fixes the hub case only, not chains of small degree.
- **Smallest fix:**
  - Decide in first-place order. Walk the files by their own earliest counting place, ascending. A file is shown unless a file of its own group was already shown.
  - Equivalently: t is hidden only by an earlier file of G(t) that is itself shown.
  - Count, on the real catalogue (counts only), the files hidden whose group has no shown file.
- **How sure:** certain about the mechanism. How many files it touches is not measured.

### C4. The large picture (and a video's poster) can stay on the 720 px stand-in after the large one is made
- **Sequence:**
  1. A file has a grid thumbnail but no screen one, so `had` is true (`f.thumb` is `hasAny`, media.go:211; thumb.go:96-98).
  2. `drawMedia` sets `img.src` (or `v.poster`) to the plain screen address (item.js:384, 407). `handleThumb` answers with the grid picture as a stand-in, no-store, `X-Thumb: pending`, and queues the screen job (media.go:356-363).
  3. The record's first ask is a HEAD that waits for a free ask. The ask line is newest-first with two at a time (dom.js:199-208), and the filmstrip's places are registered after the main picture (item.js:256-257), so the strip's asks go first.
  4. If the screen thumbnail is made before that first HEAD, the answer is `made` with `late` still false (dom.js:214-220; `late` is only set on `pending`, dom.js:222-223).
  5. `onMade(false)` with `had` true does nothing (item.js:388, 409-410).
- **What the owner sees:** a soft, upscaled 720 px picture or poster on the post page until it is opened again in a new page load. This is most likely with a fast library (staging, local disk) or a long filmstrip.
- **A second path (probable):** the user arrows past a file before its first ask runs, the screen is made meanwhile, and they come back. The plain address may then come from the page's own list of loaded pictures, which ignores no-store, and `late` is again false.
- **Smallest fix:** when the plain address was loaded before the record knew the file was made (`had` and `rec.st !== 'made'` at draw time), always swap to `&m=1` on made. One extra local request at most.
- **How sure:** high for the first path. The second path depends on the browser's image list.

### C5. Hiding a post shifts the loaded library under the same gen
- **Sequence:** the listing key carries the decisions version (library.go:175-178), but `gen` does not, and the page checks only `gen` and `pos` (library.js:708). After "Hide this post from the library" in the overlay (item.js:817-825, which clears only the post cache):
  - Blocks already loaded still show the hidden post.
  - In a later block whose anchor is after the hidden tile, `pos` is one less, which leads to the C1 reset to the top.
  - In a block containing the hidden tile, `pos` matches but every tile after it moves one place left. The tiles are drawn in boxes laid out for their neighbours' shapes (aspects from the old shape), and the block's last tile is the next block's first.
- **What the owner sees:** the hidden post still there, then a jump to the top or one block of cropped or stretched tiles.
- **Fix:** the same as C1 (the listing identity includes the decisions version). In addition, reload the library in place when a post is hidden.
- **How sure:** certain from the code.

## Probable

### P1. A tile whose large thumbnail alone exists stays on the stored preview
`mi.thumb` is `hasAny` (grid or screen; media.go:211). A tile, a filmstrip item, a chat mosaic or a copies row with `thumb` true loads the plain grid address directly and never asks again (library.js:739-740; item.js:473; chat.js:214; copies.js:71). When the grid is missing, `handleThumb` answers the stored preview with `pending` (media.go:356-371), and the tile keeps it while on screen. If the page's image list holds the preview for that address, it keeps it after a redraw too.

When this happens:
- Ahead mode: the grid job was dropped from the 2,048 queue (maker.go:119-123), or is not made yet.
- Asked-only mode (the owner's starter): the short window before the grid is made from the screen picture (maker.go:393-397).

Fix: report "grid made" separately (`has(grid)`) for the grid's consumers, and give them `whenThumb` otherwise. Sure about the mechanism; how often it happens is low.

### P2. No single build per listing
`listCache.get` builds outside the lock with nothing in flight shared (library.go:249-272). After each index change, every request for the same filter builds its own copy: the blocks `render()` asks for at once, the shape, and the post page (C2). That is 23-207 ms each on the real catalogue, beside the collector, and it contradicts lesson 4 of LESSONS-viewer-ix12.32.md ("Let concurrent requests for the same query wait for one run"). The cache also keeps up to 12 listings, each holding its own index version: up to ~11 MB of entries each per-file. Fix: an in-flight entry per key (`sync.Once` or a channel). Sure about the mechanism; the CPU cost is not measured.

### P3. With `first=1`, one tile per file, a set's tiles stand apart, but the post page walks the whole set at each of them
`neighbours` finds the run of the opened post (post.go:926-958). The page shows and walks every file of the set (item.js:224-245), including files the listing shows at the set's other run or hides as "not first here".
- Walking by arrows therefore shows the same files twice, against "each file once".
- ← from the tile after a run lands on the set's last file, not the run's last tile.
- Corner case: a tile's date with `first=1` is a message date (`fp.date`, appear.go:169), not the post's. An album whose messages differ by a second can split one post's run around another set's tile. → then alternates between the two posts for good (the second run always resolves to the first).

Fix: send with the post the media of its run when ctx is a filtered per-file listing, and walk those. Or key the run on `(post, f)` and use the post's own date. This is a design call for the owner.

### P4. Small paging gaps (each low)
- **Failed blocks:** a failed library block is deleted but not asked again until the next scroll event (library.js:715-717). The 12.32 lesson "a failed part never asked again" applies.
- **Chat and Deleted pages:** they load more only when the IntersectionObserver reports a change (chat.js:23-29; deleted.js:25-28), so they stall when the sentinel stays in view after a short page or an error.
- **Chat topic in arrows:** the chat page's topic choice is not in the post ctx (chat.js:187), so the arrows leave the topic (post.go:896-918).
- **Copies tabs:** switching tabs before the first answer arrives lets the other tab's answer write the summary. "N probable pairs" then shows the count of files in most places, and the late answer throws on `r.pairs` (copies.js:24-64).
- **Connection pool:** the viewer's catalogue pool is 4 connections (viewer.go:104):
  - The watcher holds one for good (viewer.go:289).
  - An update's transaction holds one.
  - In ahead mode, the makers' `catchUp` holds one for its whole scan (maker.go:279-299).

  So page requests can queue for a connection. This is not measured.

## Checked and sound
- **Cursors:**
  - Library: the cursor seek (`entryLess` against `ix.library` order) is consistent, and months are contiguous after the sort (no repeated months).
  - Deleted page: the `(deleted, lead, v=-1)` seek skips exactly the last post shown. A post whose mark changes can be skipped, but never repeated.
  - Chat: `before`/`after` exclude the cursor post.
  - Copies "most": the `(places, id-1, MaxInt32)` seek is right.
- **Versions:**
  - Nothing a request can see is changed in place: `vecW.mut`, olist chunk copies, chat post lists clipped before insert, `slices.Concat` for a post's messages, `finishSet` cloning, and the text index appending past older versions' lengths.
  - An update that finds nothing keeps the same version.
- **Deleted mark:**
  - The deleted list and `deletedFiles` are kept per dirty post, including a lead change.
  - Catalogue trigger kind 4 covers `deleted_at`, and a full read gives the same result.
- **Faces:**
  - Slices end at file boundaries.
  - Carried counts are kept across a full read.
  - Files that lost their faces are zeroed within the slice range.
- **Locks:**
  - `rawMu` is taken only by refresh and checkCounts; no request takes it.
  - The maker's `qmu` is apart from `mu`.
  - `thumbCache.mu` is short.
  - There is no lock cycle between the update, the faces read, the makers and the decisions file.
  - A request waits on a lock across I/O only in a decisions write (`decisions.mu` held during the SQLite write) and in `handleFile`'s library open.
- **Thumbnails:**
  - `handleThumb` never waits on the library or a maker.
  - Asks are HEAD, at most two at a time, with at most 7 tries per record (then 120 s before a redraw may start again).
  - `warm` uses `ask=0` and loads only a picture the server says is made.
  - Stand-ins are no-store, and `max-age` is set only on the made thumbnail under its own address.
- **Filter cache key:** the key carries every input: tz, clutter, tile mode, decisions version, topics, deleted, first/only, and `sameprob` only with first or only.
- **First appearance, one tile per file:** a file gives at most one tile (its first place must be in its own set).
- **Server:**
  - Loopback only, with a Host check.
  - `/api` and `/media` are refused when Sec-Fetch-Site or Origin is foreign.
  - Changes need the token, JSON and the same origin.
  - Library paths go through `os.Root` with `IsLocal`.
  - Thumbnail file names are sanitised.
  - Files are served with a sandbox CSP and only safe inline types.
  - Logs hold fixed words, counts and route patterns only.
  - `countingWriter` unwraps, so the file answer's stall deadline works.
- **Bounds:** 500 files, 200 places, 30 sources, 2,000 overlap posts a step, 20 posts per file for overlaps, at most 5 steps.
