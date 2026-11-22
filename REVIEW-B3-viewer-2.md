# Review B3-14: the viewer at a713cfc (`wt-b-faces`, `wip/b-nofaces`): the pieces after the first review

Read-only, from the code alone. No test was written or run, no go command was used, and nothing was started. Line
numbers are at a713cfc, in `archiver/internal/viewer`. The LAN mode was not reviewed again.

## Confirmed

### C1. A preference changed elsewhere makes the library loop shape and block requests without end (or draw tiles in the wrong boxes)
- **Sequence:**
  1. A listing's identity is only the index version and the decisions version: `listID(gen, dec)` (library.go:283).
     `buildListing` sets it from those two alone (library.go:534). The preferences are in the listing's key (the
     clutter rule and `perFile`, library.go:247-256), but not in its identity.
  2. Saving the preferences does not change the decisions version: `setPrefs` (decisions.go:279-292) leaves `d.ver`
     as it was, and `handleSetPrefs` (api.go:53-68) does nothing else.
  3. Take the library open in tab A, or on a phone at home, with list `G.D`. In tab B (Settings on the PC), "One tile
     per album" is turned off, or a clutter kind, side, size or seconds is changed. The catalogue does not change, so
     the index stays at G.
  4. Tab A then asks for a block it has not loaded. `listingFor` sees `g == cur.gen && d == f.dec` (library.go:502)
     and answers from the current listing, which is built with the new preferences. `res.list` is still `G.D`, but
     `res.pos` differs from `b*120` (library.js:1043), so the page calls `reloadInPlace`.
  5. The new shape again has list `G.D`. `update` takes it for "the very same listing" (library.js:181), keeps the
     old grid and drops only the blocks still loading. `schedule` then asks for the same block again: back to step 4.
  6. Nothing breaks the loop until the index version changes. In an archive that is not being written (the old
     archive brought in, once the faces are read), it never does.
- **What the owner sees:**
  - The tiles not loaded yet stay grey boxes for good.
  - The viewer runs one shape and one block request per round trip, back to back. Each shape answers every tile's
    shape (about 470 KB base64 at 350k tiles per file) plus a catalogue read for its first block. That is CPU on the
    PC beside the collector, for as long as the tab stays open.
  - If `res.pos` happens to match (a change that only moves tiles after that block), the block from the new
    listing is drawn into boxes laid out for the old one: cropped or stretched tiles (the first review's C5 again).
- **The same mismatch in two more places:**
  - The page's own listener for preference changes (library.js:112-113) would end in the same "very same listing"
    branch. No preference in its list can change while the library is mounted in the same tab today.
  - The version numbers start again from 1 when the viewer restarts (viewer.go:294-296, `genN`). A page kept open
    across a restart can meet its old id with different content. This lasts at most until the next version.
- **Smallest fix:** `d.ver++` in `setPrefs`. The old listing's `peek` then misses (the filter key differs) and the
  answer is "stale". The new shape gets a new id, and the grid is drawn again in place. For robustness, add a
  per-process random part to `listID`, so an id from before a restart never matches.
- **How sure:** certain from the code (library.go:283/502/534, decisions.go:279-292, library.js:181/1043-1045).
  The request rate is an estimate, not measured.

### C2. "+n probable" on a tile per post counts files that have a tile of their own in the same grid
- **Sequence (album tiles, the default; no `first=1`):**
  1. Set S is an album with x (saved) and y (not downloaded). File c elsewhere (not downloaded, the same kind) is
     folded behind x: x is saved, so it comes first in face order (fold.go:152-161).
  2. With "Not downloaded" (`state=missing`), S still has a tile because of y. But `noteSet` marks x as a face with a
     tile only when x passes `mediaOK` (library.go:830), and x does not (state).
  3. So `foldedOut(c)` is false (library.go:379-385) and c keeps its own tile (library.go:1052-1062).
  4. `tiles()` counts "+n" over every face of `s.media`, without asking whether that face has a tile in this listing
     (library.go:1469-1476). S's tile says "+1 probable".
  5. S's post page lists c as "folded under them in the library" (`foldFor` ignores the listing's filters,
     fold.go:271-286; post.go:623).
- **The same happens with:** a type filter on an album of mixed kinds (the face's kind filtered out), a face hidden
  as clutter inside its tile, and `only=1` or a spread filter in album mode, where `noteTile` marks only the faces
  among the shown files (library.go:563-576).
- **What the owner sees:** "+1 probable" on S's tile while c is a tile of its own a few rows away. The chip
  "Probable copies folded: N" does not count c, so the tile's number and the chip disagree.
- **Smallest fix:** in `tiles()`, count under face x only when x has a tile in this listing
  (`l.faceIn[x>>6]&(1<<(x&63)) != 0`). Optionally say on the post page which files the opened listing actually
  folded.
- **How sure:** certain from the code. How often it happens depends on how often the owner filters by state or
  type in album mode.

### C3. The review page's S and N keys act on the same pair again while its verdict is on its way
- **Sequence:**
  1. `current()` returns the focused card, or the first card that is neither done nor skipped (copies.js:149-153).
  2. `card.judge` marks the card done only after the answer arrives (copies.js:187-207).
  3. So S then N pressed within one answer's time both POST for pair 1. Pair 2 gets nothing.
  4. The two requests are separate fetches. The server orders them only by `vmu` and `d.mu`
     (verdicts.go:381, 207-237). The page keeps the verdict of the answer that arrived last. The file keeps the one
     written last, and the two may differ.
  5. A verdict waits longer while an update holds `vmu` for `resolveVerdicts`' catalogue read (verdicts.go:258-308),
     and on a phone over HTTPS.
- **What the owner sees:** reviewing at keyboard speed, the "the same" just given to pair 1 is replaced by "not the
  same", and pair 2, meant for the N, is still waiting. After a reload the page may show another verdict for pair 1
  than it showed before.
- **Smallest fix:** mark the card busy when `judge` starts (`card.busy = true`). `current()` then skips busy cards,
  `judge` returns while busy, and focus moves to the next card at once. Do the same for the fold card's buttons on
  the post page (item.js:689-702).
- **How sure:** certain about the mechanism. It needs two keys within one answer's time.

### C4. The album strip loads the grid address when only the large thumbnail exists, and keeps the stored preview
- **Sequence:**
  1. strip.js:67 tests `g.thumb`, which means "either size is made" on post-page files (conv.go:58-62). It should
     test `gridOf(g)`, as the filmstrip, copies and chat pages now do.
  2. With only the screen size made, the strip's `<img>` gets `/thumb?s=grid`. `handleThumb` answers the stored
     preview, `no-store`, pending (media.go:358-372).
  3. No `whenThumb` record is made for it, so it is never swapped.
- **What the owner sees:** a blurred, upscaled preview as the item's picture in "In which chats" until the post is
  drawn again. This is the first review's P1, left in the new strip.
- **Smallest fix:** `if (gridOf(g))` at strip.js:67.
- **How sure:** certain. Low effect.

### C5. Two hiding chips open a listing whose count is not the chip's number
- **"Hidden posts: N":**
  - N counts each hidden-post tile before clutter is judged (library.go:1028-1034).
  - Its link sets `hidden=1` (library.js:801-802). That listing applies the clutter rule and the fold to those very
    tiles (`mayHide` turns only the post rule off, library.go:999).
  - So a hidden post that is also clutter, or that becomes folded, is counted in N but not shown behind the link.
- **"Clutter hidden: N":**
  - Its link `clutter=show` (library.js:806) lets clutter faces have tiles, so the clutter files folded behind them
    disappear into the fold.
  - The listing then shows N minus those, and its "Probable copies folded" chip goes up by as many.
- **What the owner sees:** "Hidden posts: 12", then 10 tiles. Each view's own chips add up, so it is explainable,
  but the chip's number is not what its link shows.
- **Smallest fix:**
  - Say it in the chips' title.
  - Or give the hidden-posts link `clutter=show`, and count clutter-hidden tiles folded behind a clutter face under
    "folded".
- **How sure:** certain. The size is small.

## Probable

### P1. A shape that fails while blocks answer "stale" reloads without a pause
On a keep-reload whose shape fails, the page keeps the old shape and schedules again (library.js:167-175). Its
blocks are again answered "stale" (library.go:1411-1413, which needs no catalogue read), and that calls
`reloadInPlace` again (library.js:1043-1045). If the shape fails fast (a catalogue that cannot be read, such as a
file being replaced), this is a tight loop. A busy catalogue paces it at the 5 s busy timeout. A failed block
already backs off (library.js:1053-1057). The shape needs the same backoff when it was reached from a stale block.

### P2. "Hide files that are not downloaded" makes the arrows leave the run with `first=1`
With every file of the run hidden by the switch, `walkOf` falls back to every shown file of the set (item.js:241-246).
So the arrows walk the set's other files instead of going on to the next tile. Rare (a tile of a file not
downloaded, with the switch on). Fix: fall back to an empty walk, so the arrows go to `prev`/`next`.

### P3. Cost per index version (not defects; what a collector writing every 2 s makes the viewer redo)
- **Every listing that is not `first=1` needs the version's overlap walk and fold** (library.go:543-551).
  - This is one walk over every file's group, even for a one-chat filter or a search. A narrow listing that cost
    milliseconds before now costs at least that walk on the first request of each version.
  - Opening a post from the library builds the current listing (post.go:1031-1032), so after each version change
    the first post opened pays the listing plus the walk. The page's prefetch hides it from the arrows.
- **`first=1` repeats that same walk.** It runs its own `decideFirst` (library.go:768-770) although the overlap
  table already holds the same decision. The two differ only by the hidden and left-out chats; when there are
  none, `shown` could be taken from the table.
- **Kept per version:** the listing, the overlap table and fold, the clutter bits, the totals and the tiles'
  shapes (about 470 KB per shape at 350k tiles).
- **For a change that only touched states:** the fold could be reused when the version's delta has no edge, place
  or saved-state change. Nothing above grows without bound: 12 listings, 2 overlap versions, 1 clutter rule,
  1 totals, 1 review count.

## Checked and sound
- **The first review's fixes:**
  - A block is cut from the listing its shape named, while it is kept (`listingFor`, `peek` waits for a build).
  - One build per key, with waiters.
  - A failed build is taken out and tried again.
  - Eviction keeps waiters served.
  - The version's number now lives on the index.
  - Re-anchoring uses the first row's cursor, and the tile after it when that tile was folded or filtered away;
    there is no scroll to the top on a kept reload.
  - `decideFirst` hides a file only behind a shown file of its own group.
  - The tile's context carries `tz`, and the fallback address drops it.
  - The large picture swaps in by `&m=1`.
  - A failed block backs off three times.
- **Fold:**
  - A file is folded only behind a shown face with a tile in the listing.
  - A face is never folded, so no tile holding a face is dropped.
  - The drop runs before the sort, on the notes' own positions.
  - `filtered = shown + chats + posts + clutter + folded` holds.
  - The verdict buttons name a pair with a probable edge (`linkFrom`).
- **Overlap page:** every cell equals its library link's count with `first=1`, one tile per file, no hidden chats
  and clutter shown. The page says this about album tiles, hidden chats and clutter. "Lacks" is files(other) −
  shared − wide shared, the link `with=other&without=this`. The pairs leave out groups in more than 20 chats,
  exactly as `with` with two chats does.
- **Keys and versions:**
  - Listing key: gen, filter key, decisions version.
  - Overlap tables: (version, sameprob, verdict generation).
  - Review counts: (version, verdict generation).
  - Clutter bits: (version, rule, table).
  - Totals: version.
  - The hidden-items snapshot: (ver, res, vres).
  - A hide, a verdict and a per-chat clutter choice each bump `d.ver`.
- **Marks and verdicts:**
  - Every table in `decisions.sqlite` is keyed by stable keys: posts and chats by space plus Telegram numbers;
    verdicts by `tg_media(kind, tg_id)`, which is `UNIQUE` in the catalogue; per-chat clutter by space key.
  - The file is written before memory, under `d.mu`.
  - The lock order is vmu → d.mu everywhere.
  - "Unhide all" keeps the marks for absent items and the clutter choices.
  - A fresh bring-in resolves everything again by key.
- **Converted copy:**
  - The slot is taken and given back by `defer` with nothing between them.
  - A HEAD request takes and starts nothing.
  - ffmpeg is killed on the request's end, on a stall (2 min), on a sign-out (LAN) and on a panic.
  - `ReadTimeout` does not cancel a GET's context (net/http clears the read deadline when its background read
    starts), which is what the existing test shows.
  - On shutdown, ffmpeg ends at its next write once the process exits.
- **Open in the player:**
  - The path comes from the catalogue through `lib.abs` (inside the library) and is one argument.
  - It is started without a shell, and only from this PC.
  - The default program is used only for known media extensions.
  - Not verified on Windows: a library path with spaces through `rundll32 url.dll,FileProtocolHandler`.
- **"No faces":**
  - Looked-at is read over the same file ranges as the faces.
  - The flag bit is kept by every update path.
  - A never-looked file is in no choice; a tile needs every picture and video looked at.
  - The page reloads in place when the first read ends.
- **Scripts:**
  - Every imported name is exported.
  - No listener is added twice on a reload.
  - Every element the pages look up is made by them.
  - The copies tabs drop late answers (`seq`).
