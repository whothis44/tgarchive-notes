# Review: `wip/b-notsaved` (e4f1d53) against `f0e3f0c`: files not downloaded, in the library (session B4, 11-15)

An independent, read-only review. Nothing was changed in `wt-b-faces`. The probes are in
`C:\Users\trabi\AppData\Local\Temp\b4ns-review\zz_review_probe_test.go`, loaded with
`go test -overlay C:\Users\trabi\AppData\Local\Temp\b4ns-review\overlay.json`. Each was run by name with `-p 1`,
`GOMAXPROCS=2 GOGC=50`. All data is invented, from the package's own fixtures (`newSetsFix`, `newNSFix`).

**Counts:** 4 CONFIRMED defects (2 wrong results for the owner, 1 wrong result or wrong number, 1 wrong number).
3 CONFIRMED points for the owner to decide (behaviour the brief allows, but that may surprise him).
2 PLAUSIBLE cost points. 3 PLAUSIBLE cosmetic points.

---

## Findings, most severe first

### 1. CONFIRMED: a tile's saved copy can come from a file the tile does not show, and say "proven" when it is not (wrong result for the owner)
- **Where:** `library.go:1615`, in `tiles()`, against `library.go:943-947`, in `nsKeep`.
- **What goes wrong:** `nsKeep` keeps a set tile using `tileCopy(e.media, s.media, ok)`. Here `ok` is the tile's own
  files: `mediaOK` (type filter, clutter) or `shown` (first=1). `tiles()` works the copy out again with
  `ok = not folded out` only, so it looks through every file of the set. `tileCopy` prefers any file's exact copy
  over the cover's probable copy. So when the tile's shown file has only a probable copy, and a file the tile does
  not show has an exact copy, the tile takes the hidden file's copy. It shows that copy's picture and the mark
  "Saved copy from <chat>" with the title "the same file, proven". Clicking it opens the post on the shown file
  (`?f=` is `t.Media`), and the post page there says "probably the same, not proven", with a different copy.
- **Inputs (probe A, `TestReviewProbeCopyFromUnshownFile`):** one post in chat N with file a (big, not saved,
  probable edge to saved sa) and file b (tiny, so clutter; not saved, exact edge to saved sb). The rule is copy,
  album tiles on, hide clutter on, the query is `chat=N`. The tile shows a (`Media=a`, `Count 2`, `Saved 0`) and
  `Copy = sb, exact=true`.
- **Inputs (probe A2, `TestReviewProbeCopyFromFilteredType`):** photo a (probable copy sa) and video b (exact copy
  sb) in one post, with `type=photo`. The photo's tile shows `Copy = sb` with `type=video, exact=true`: a photo
  filter showing a video's picture.
- The same happens with `first=1`, whose tiles show only `shown`; it was read, not probed.
- **Smallest fix I would accept:** work the copy out once, while building, and only from the files the tile shows.
  Have `nsKeep` leave `e.media` on the file whose copy is shown (it already does). Then in `tiles()` use
  `ix.copyOf(e.media)` for set tiles as well, and drop the second `tileCopy` over `s.media`. Finding 2's fix keeps
  `e.media` right after the fold. Add a test: a shown file with a probable copy plus a clutter or filtered-out file
  with an exact copy.

### 2. CONFIRMED: the fold can take away the file a tile was kept for; the tile stays, reads "Not downloaded", and is not counted (wrong result for the owner)
- **Where:** `library.go:928-960` (`nsKeep` runs before the fold), `library.go:1191-1198` (the fold gives the tile a
  new cover) and `library.go:1615` (`tiles()` then leaves folded files out).
- **What goes wrong:** with the rule copy, a post none of whose files is saved is kept because one file (a2) has a
  saved probable copy. If that copy has its own tile in the listing, the fold takes a2 out of the tile (folded
  behind it). The tile keeps its other file a1, which has no copy. `tiles()` finds no copy, so the tile shows a1
  with the mark "Not downloaded". The rule copy promises to leave such tiles out, and the chip "Not downloaded, no
  saved copy: N left out" does not count it.
- **Inputs (probe B, `TestReviewProbeFoldTakesTheCopyAway`):** chat N has post S (sv, saved) and post A (a1 and a2,
  neither saved). There is a probable edge a2–sv. The rule is copy, the query is `chat=N`. The album tile is listed
  with `Media=a1`, `Count 1`, `Saved 0` and no copy. sv's tile carries "+1 probable". The counts are
  `NotSaved 0, Filtered 2, Total 2`. With `prob=apart` the same tile correctly shows a2 with sv's copy.
- **Smallest fix I would accept:** in the fold step, when a tile kept only for a copy (note it in the fold note)
  needs a new cover, choose a file that is not folded out and has a copy (`tileCopy` over `nt.files`, with `ok` =
  not folded out). If there is none, drop the tile and count it in `notSaved` (or in `ndShown` with nd=show), not
  in `folded`. That keeps X + chips = Y. Add a test.

### 3. CONFIRMED: "Showing N not downloaded" counts tiles the fold then takes out (wrong number)
- **Where:** `library.go:954-956`. `hc.ndShown` is counted before the fold at `library.go:1168-1212`, which can drop
  those same tiles. The chip text is at `web/js/library.js:905-908`.
- **Inputs (probe C, `TestReviewProbeNDShownCountsFolded`):** two files in chat N, neither saved, with a probable
  edge between them and no saved copy. The rule is copy. The default view is `Total 0, NotSaved 2`. With nd=show
  it is `Total 1, NDShown 2, Folded 1`. The chip says "Showing 2 not downloaded", but one tile is shown, and the
  other is also counted in "Probable copies folded: 1". One post is counted under two chips.
- **Smallest fix I would accept:** count `ndShown` after the fold. Mark the entries `nsKeep` let through only
  because of nd (for example a bitset by entry position, or a flag on the fold note), and subtract those that the
  fold drops.

### 4. CONFIRMED: "a tile with any saved file is kept" looks at the whole set, not at the files the tile shows (wrong result for the owner, minor; arguably within the brief's wording)
- **Where:** `library.go:933` (`s.states&setSaved`) and `library.go:1605` (`tiles()` gives no copy to such a set).
- **Inputs (probe G, `TestReviewProbeSavedFileNotShown`, passes and only logs):** one post with a saved photo and a
  video that is not saved, with an exact saved copy elsewhere, and the query `type=video`. Under both copy and
  hide, the tile shows only the video, marked "Not downloaded" (`State held`, `Count 2`, `Saved 1`), with no copy.
  - Under copy, the known exact copy is not shown.
  - Under hide, the owner sees a "Not downloaded" tile although he chose "Leave them out".
  - The same happens when the saved file is clutter, or is folded out (the fold runs after the rule).
- The brief says "the rule looks at the tile's files together (`Saved == 0` of its `Count`)", and `Count`/`Saved`
  are set-wide (minus folded), so this follows the brief. But it is not what the tile shows.
- **Smallest fix I would accept:** judge "has a saved file" over the files the tile shows (the same `ok` as in
  finding 1). If the owner accepts the brief's set-wide reading, say so in the Settings sentence instead.

### 5. CONFIRMED, for the owner to decide: a saved copy from a hidden chat is shown, with that chat's name, on a tile in a visible chat
- **Where:** `notsaved.go:51-86` (`pickStandIn` never looks at hidden chats or hidden posts) and
  `library.go:1684-1686` (the copy's oldest post, in any chat).
- **Probe E** (inside probe A): after chat S was hidden, the tile in chat N still shows "Saved copy from
  Invented Probe S".
- The post page's `standInOf` does the same, so this matches the existing behaviour. The library is a new place
  for it, though, and on the home-network pages too. lan.js says a hidden chat is "left out of the lists, not
  locked", so this is not a lock being broken.
- **Smallest change, if the owner wants one:** name the copy's place by its oldest post in a chat that is not
  hidden, when there is one. The kept vector can stay as it is: hidden marks are per decisions version and must
  not go into the index.

### 6. CONFIRMED, for the owner to decide: the same saved picture can be on two tiles of one listing
- **Probe F (`TestReviewProbeCopyTwiceInOneListing`):** with the rule copy and the query naming both chats, saved
  file sx has its own tile, and file x (not saved, with an exact copy sx) shows sx's picture on a second tile.
- The brief asks for exactly this ("the saved copy in their place"). The owner's words were "hidden, or link to
  their known duplicates". When the duplicate itself is already a tile in the same listing, he may prefer the
  tile for the file not saved to be left out (or folded into "+n").
- Only exact copies do this: probable copies are folded (but see finding 2).

### 7. PLAUSIBLE: work proportional to a saved copy's places, per tile and per block (cost)
- **Where:** `library.go:1684`, where `ix.oldestPost(tc.t)` runs for every copy tile in every block.
- `oldestPost` walks all the copy's places. `pickStandIn` prefers the copy in more places, so the stand-in is often
  a file posted very many times, and several tiles of one block can share it. This is not a walk of copy edges and
  not proportional to the archive. It does grow with how widely one saved file is reposted (thousands of places).
  The post page keeps an `oldest` map per call; `tiles()` does not.
- **Smallest fix:** a map from copy to oldest post per `tiles()` call, as `post.go:656` does.

### 8. PLAUSIBLE: the update's upkeep is the square of a file's links for a widely linked file (cost, at update time only)
- **Where:** `notsaved.go:171-176` and `refresh.go:1819`.
- Every file that gets a new place, gets saved, or gets an edge is worked out again, together with each linked
  file. Each of those reads its own edges. For a group of k files linked to each other (k probable copies of a
  sticker), one new place costs about k² edge reads per update, even when the file is not saved. A file that is
  not saved never takes part in another file's choice, so its places are never needed.
- **Smallest fix:** in `keepStandIns`, redo the linked files only when t's change can matter to them (t is saved
  now, or was saved). Redo a file only if it is not saved, or its saved state just changed. This is not a request
  cost, so the brief's rule is not broken.

### 9. PLAUSIBLE, cosmetic: `nd=show` stays in the address with no chip when the rule is off or set to show
- **Where:** `web/js/library.js:781` counts `nd=show` as one filter on. The chip only appears when `s.nd`
  (`library.js:905`), and the server sets `nd` false under the rule show, `state=missing`/`held`, `hidden=1` or
  `clutter=only`. The sidebar then says "1 on" with nothing on the page to say what or to remove it; only "Remove
  every filter" clears it.
- **Fix:** count it only when `shape.nd` is true, or have the page drop `nd` when the shape says the rule is off.

### 10. PLAUSIBLE, cosmetic: the Settings sentence overstates probable copies
- **Where:** `web/js/settings.js:150`. "shows the same file saved from another chat" is also used for probable
  copies, which the tile itself calls "Probably the same". Suggestion: "the same file, or one that is probably the
  same, saved from another chat".

### 11. PLAUSIBLE, cosmetic: the tile's shape is the cover's, while the picture is the copy's
- **Where:** `library.go:1451`, `tileAspect(e.media)`. A probable copy can have another shape (cropped or
  resized), so its thumbnail may be cut. Exact copies are the same file, so they are not affected.

---

## Checked and found sound

- **The index's number per file and its upkeep:** `pickStandIn`, `keepStandIns` and `apply`. Each cause can only
  reach the vector this way:
  - **The file's own saved state flips:** `noteStand(t)` at `refresh.go:1147`. This covers both directions; probe D
    (`TestReviewProbeUnsaveKeptByUpdate`, **passes**) un-saves the exact copy. The index then moves to the probable
    one with no full read, and still matches a full read and the reference. Saving x itself clears it.
  - **An exact or probable edge appears:** `refresh.go:1218`. A related edge rightly changes nothing.
  - **A place appears:** through `placeWas`, from new messages and late attachments, at `refresh.go:1819`. The
    linked files are redone, so the "more places" tie-break follows.
  - **A new file:** `stand.push(0)`, and its edges are noted.
  - **An edge goes:** always a full read (largest rowid at `refresh.go:460`, or the count check). Edges never change
    kind in place: the catalogue's key is `(a, b, relation)` and it only uses `INSERT OR IGNORE` or an `ON
    CONFLICT` that sets `partly`/`evidence` (`catalog/rows.go:594-606`, `bringin.go:378`). "Changes kind" means a
    second edge of another kind, which is an addition and is followed.
  - **A place goes, a message is removed, a chat is removed:** full reads. Deleted marks, hidden posts and hidden
    chats do not enter `pickStandIn`, the same as `standInOf`.
  - **A full read** (a new writer, `old` empty) works out every file.
  - The tie-break `switch` gives exact first, then more places, then the lower id, and agrees with
    `refStandIn`'s sort.
- **The reference comparisons really compare the new vector:**
  - `fingerprintIndex` against `refFingerprint`, which has its own `refStandIn` written from the rule.
  - `strongFP` (updated against full read) carries `copy id/exact`.
  - `checkStandIns` compares the kept vector with a fresh `standInOf` on the same parts.
  - The random walk produces saves, new edges of all three kinds, new places, late attachments, and deletions of
    edges, attachments and messages. It never un-saves a file (`refresh_random_test.go:297-325`): see the test gaps
    below.
- **`standInOf` moved (point 6 of the brief):** the body is the same logic over `&ix.media`, `&ix.edges` and
  `&ix.places`. `edgesOf` and `placesOf` are exactly `*ix.edges.at(t)` and `*ix.places.at(t)` (`index.go:266-268`).
  The post page's answer is unchanged.
- **The listing key:** `|ns%d,%v` (`library.go:283`). The three values and nd never share a key. With a state
  filter, `hidden=1` or `clutter=only` the rule is off and the value does not matter (the same listing is right).
  `setPrefs` bumps the decisions version (`decisions.go:302`), so a page holding an older listing is stale and
  reloads; it is never served another rule's blocks.
- **Counts:**
  - `notSaved` is counted only at the emit level, after the three hiding rules and before the fold. So shown +
    chats + posts + clutter + notSaved + folded = filtered holds by construction, and `filtered` does not depend on
    the rule.
  - `TestNotSavedCountsAddUpEverywhere` checks this under 13 queries × 3 values × nd × both tile modes.
  - The exceptions are the meaning of `ndShown` (finding 3) and what is shown (findings 2 and 4).
- **Paging and arrows:** tiles left out are not in `l.entries`, which paging, anchors and `navListing` use.
- **The explicit state filter wins:** `state=missing`/`held` turn the rule off (`library.go:245`), and so do
  `hidden=1` and `clutter=only`, so each hiding chip still opens exactly what it counts.
- **Home network:** the rule is the server's. `deviceSettings` draws no radio buttons. `nd=show` is only a query, so
  it is never refused. `TestNotSavedOnADevice` checks that a device cannot change the rule.
- **The page:** no `innerHTML` and the like in the diff. Every string goes through `h(..., {text})`. The mark and
  title say "Saved copy from <chat>" for exact and "Probably the same, saved in <chat>" with "not proven" for
  probable, as the post page does, except in finding 1. The tile still opens its own post (`/post/<t.post>?f=<t.media>`).
  `num()` turns a missing `nd_shown`/`not_saved` into 0. The Settings radios save through `/api/prefs`, and the
  library re-asks on `library_not_saved`.
- **Tests:** no new test judges real time (no `time.` in the new test lines). `TestNotSaved*` (6),
  `TestPageScriptsParseAsModules` and `TestLANPageDrawsNoRefusedControls` all pass by name on e4f1d53.
- **Timing:** `TestTimingOnBigCatalogue`, run once by name on e4f1d53 with the rule at its default (copy). The PC was
  busy: other agents were compiling, and CPU load was 73% before and after the run. So these numbers only "look
  like":
  - 200,000 messages, 92,233 posts, 40,865 sets and 120,586 files; full read 1.468 s (reading 860 ms, deriving
    608 ms).
  - Library first page: 11.0 ms cold, 1.5 ms warm; block 50: 2.0 ms.
  - Filters cold: 8 to 20 ms; searches 12 to 24 ms; a post opened: median 1.5 ms, 95th percentile 5.6 ms.
  - The test passed. I did not run the base commit, so I have no "before" number of my own.
  - No new work in a request is proportional to the archive: `nsKeep` reads one number per file, and `tiles()`
    reads one number per file plus finding 7's places walk.

## Guarantees with no test that would fail if they broke

- The copy shown is the copy of a file the tile shows (finding 1).
- The rule and the fold together (finding 2), and `ndShown` under the fold (finding 3).
- The update when a saved copy stops being saved: the random walk never un-saves. My probe D passes, but nothing
  in the branch would catch a regression there.
- The Settings choices redrawing the library, and the tile's picture being the copy's: JavaScript only, with no
  test beyond the syntax check.

## Not checked

- A browser rendering of the tiles, the chip or the Settings card, and the page on a phone.
- The whole-package run, `go vet` and `gofmt` (not my brief). No race detector.
- Any real catalogue: invented data only, by rule.
- The "before" timing on `f0e3f0c` (I could not check it out without writing in the worktree).
- `first=1` and `only=1` against finding 1 (same cause, read only).
- Load on the update path with large groups of linked files (finding 8 is by reading).
