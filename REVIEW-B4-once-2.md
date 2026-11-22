# Second independent review of `wip/b-once` (head d38479c) against d1af260 (11-15)

Read-only. Worktree `wt-b-faces` left as it was (clean, at d38479c). Probes: test files in my own scratch folder
`C:\Users\trabi\AppData\Local\Temp\claude\71f159c3a9e5d4b9\08e0726b-fa56-4719-8490-c6d0ae9663c1\scratchpad\rev2`
(`zz_rev2_test.go`, `zz_r2first_test.go`, `zz_r2cost_test.go`, loaded with `go test -overlay overlay*.json`), run by
name, `-p 1`, `GOMAXPROCS=2 GOGC=50`, one at a time. d1af260's `archiver/` was extracted with `git archive` into
`rev2\old` (a scratch copy, nothing checked out) to compare `first=1` on both. Invented data only. Free memory 8.0 to
8.6 GB at every run; CPU 45 to 84 % busy before the runs (another coder on the PC), so every time is "looks like".

Counts: the first review's 7 findings: **all gone** (7 for default tiles; it stays for `first=1`, which is as before by
the brief). New: **2 CONFIRMED** (1 "one picture on two tiles" against the fold, 1 "wrong number"), **3 PLAUSIBLE**
(cosmetic), plus test gaps. No file missing and no count that fails to add up in any probe.

---

## A. The first review's findings

| # | Then | Now | Shown by |
|---|------|-----|----------|
| 1 | Hidden earliest post took the file away | **gone** | `TestR2Finding1HiddenEarliest`: x1's post hidden, x2's tile there under `show`, `copy`, `hide`; counts add up. Also the brief's own `TestEachOnceAmongWhatIsListed` (clutter-hidden earliest copy) passes. |
| 2 | Search / type / date range missed later posts | **gone** | `TestR2Finding2SearchTypeRange`: `q=zebraprobe` 2 tiles (one per group), `type=photo` keeps the photo (document earliest, probable edge), a range over the later day keeps y2; all three rules. |
| 3 | Chain t~c~y: c lost under `hide`, c twice under `copy` | **gone** | `TestR2Finding3Chain`: c's own tile once, c's picture on exactly 1 tile under `copy` and `hide` (and `show`). The probable step is no longer in the group, so the case is the fold's again. |
| 4 | Sidebar switch with two handlers | **gone** | Wiring identical to d1af260 (`library.js` `this.firstOpt = flag('first', …)`, `press(this.firstOpt, first)`, no `.onclick`); test `TestVideoClickLineAndFirstSwitch` (source text). |
| 5 | Two snapshot writers | **gone** | `snapMu` around `writeSnapshot`; `snapStopped` drops every non-stop write after the first stop; `TestSnapshotStopIsLast`, `TestSnapshotWriterUseWrites` (injected clock: "same use", gap "armed 8s") pass, 15 repeats at 84 % CPU without a failure. |
| 6 | Video click: strip drag, late double click, opening line | **gone** (one residue, C below) | `play.js` judges the strip at `pointerdown`, a move over 5 px is a drag, `dblclick` undoes a toggle under 600 ms, `.frame > .open-wait { pointer-events: none }`. |
| 7 | "also in N chats" counted hidden chats | **gone** for the default tiles | `TestR2AlsoHiddenChat`: one file in chats A, B, C; C hidden: `also` 1 (2 before hiding). With `first=1` it still counts hidden chats, as on d1af260 (`ap.also`), which the brief keeps unchanged. |

---

## B. New findings, most severe first

### B1. CONFIRMED, one picture on two tiles (no file missing): the fold loses its face when the group's place goes to another exact copy

- Where: `library.go:1277-1366` (the once pass places a group at its earliest passing tile) against `fold.go`
  `decide` (a probable copy is folded behind one particular file, the face, decided over the whole archive) and
  `foldedOut` (`library.go:443`: folded only when that very face has a tile, `faceIn`). The once pass marks `faceIn`
  only for the files it keeps (`noteTile(e.set, kept)`), never for the face's exact copies.
- Inputs, all saved (`TestR2FoldFaceMovedSaved`): x1 (chat A, earliest) = x2 (chat B) exact; p (chat C, 800x600) a
  probable copy linked to x2 only. Fold: x1 and x2 both shown, p folded behind x2 (p's group reaches x2 only).
  - `once=0`: x1 and x2 (+1 probable), p folded: 2 tiles.
  - each file once (the default), under `copy`, `show` and `hide` alike: **x1 and p**, p's own tile, no "+1". The
    picture is still on two tiles, but now the probable copy is unfolded, against "probable copies stay with the
    fold exactly as before" and the owner's "folded under one".
- Worse under `copy` (`TestR2SameSavedTwice`): x1 (earliest, not downloaded) = x2 (saved); y (not downloaded) a
  probable copy of x2. Default listing: x1's tile shows x2 as its copy, and y (its face x2 now without a tile) is not
  folded and shows **x2 as its copy too: the same saved file on two tiles**. Same with a saved p
  (`TestR2FoldFaceMoved`, copy and show). This is the usual archive shape: the exact copy that was not downloaded
  because its twin was saved is often the earlier post.
- How often: the randomized [name removed] (`TestR2Matrix`, 8 invented archives, 72 query combinations each) finds it in
  most archives: 1 to 3 of about 15 default tiles per archive are a file that is folded with `once=0` and has its own
  tile with each file once (C6 counts 4 to 94 per archive over all queries).
- Smallest fix I would accept: the fold must follow the group's place. Either (a) when the once pass keeps file t,
  treat every face among t's exact group (`grp.members`) as having its tile there: `faceIn` for them, the tile's
  "+n probable" counting `under(F)` for those faces, and the post page's folded list (`foldFor`/`foldedBehind`)
  taking the faces of the shown files' groups; or (b) the cheaper tie-break: among a group's candidates the rule
  keeps, prefer a member that is a fold face, then the earliest (fixes both probes above; leaves the rare group with
  two faces on two members, which (a) covers). Plus named tests with the two fixtures above.

### B2. CONFIRMED, wrong number: an album tile counts files whose place is at another tile

- Where: `library.go:1900-1920` (`tiles`: `t.Count, t.Saved = ix.slotCounts(e.set)`; the fold's slots are taken off
  by `slotsFoldedOut`, the once pass's are not).
- Inputs (`TestR2AlbumCount`): al0 single post (B, earlier), album {al1, al2} (A) with al1 = al0 exact. Default:
  album tile keeps al2 only (cover al2, right) but says **count 2, saved 2**; al1 is also al0's own tile. With one
  tile per file the album gives al2's tile only (right).
- Whether the post's own two items should show on the badge is arguably the owner's call; it is inconsistent with the
  fold, whose folded slots are taken off the same badge. Smallest fix: keep per listing a bit per file "placed at
  another tile" and take those slots off as `slotsFoldedOut` does, or say on the board that the badge counts the post.

### B3. PLAUSIBLE (reading), cosmetic: a double click undoes an earlier single click's toggle

- Where: `play.js` `clickToPlay`: `toggledAt` is cleared only by a `dblclick`, never by a new single click.
- Inputs: click at 0 ms (toggles at 250 ms), then a double click whose first click is at 600 ms (past the 500 ms
  double-click time, so `detail` 1) and second at 700: the `dblclick` sees `toggledAt` 450 ms old (< 600) and toggles
  back. The owner paused, then went full screen, and the video plays.
- Fix: `toggledAt = 0` at every press that starts a new click (`pointerdown` with `detail` 1, or in `click` before
  arming the timer).

### B4. PLAUSIBLE (reading), cosmetic: the early write is signalled before the request's own numbers are recorded

- Where: `snapshot.go` `usedBy` sends on `v.used` when the handler returns; `server.go:177-180` records the route
  (`stats.request`, `ttfb`) after that, in the outer wrapper.
- With the real 3 s wait nothing is lost. In `TestSnapshotWriterUseWrites` (wait 1 ms) the write can come before the
  record; the later record then bumps `stats.ver`, and the step expected as "same use" becomes "wrote use": a test
  that can fail under load. 15 repeats at 84 % CPU did not fail.
- Fix: signal the writer from the outer wrapper after `stats.request` for the three routes.

### B5. PLAUSIBLE (reading), cosmetic

- `tiles()` (`library.go:1898`) calls `v.onceGroupsFor(ix)` per tile. One slot is kept: two pages on two index
  versions scrolling at once rebuild the groups in turn, possibly per tile (about 1 ms each on the 120,586-file
  catalogue). Never a wrong answer (`g.ix == ix`). Fix: take it once before the loop.
- `decisions.go:60-64` still says "at its earliest post (first appearance, appear.go)": stale comment.
- `onceGroups` is unbounded (the brief said "up to the existing bound", `maxExactGroup` 64). More correct; the cost
  is in `also` per tile over all members (only places capped). Fine at today's sizes.
- Under the rule `show`, a group whose earliest post is not downloaded is shown there, and its saved twin has no tile
  (`TestR2SameSavedTwice`, show: x2's bytes on 0 tiles). This is what the brief says ("the rule keeps every tile");
  noted for the owner, not a defect.

---

## C. Checked and found sound

- **No file missing, none twice (by cover), counts add up**: `TestR2Matrix`, 8 invented archives (18 exact classes of
  1 to 3 files, star or chain edges, probable look-alikes, saved and not, tiny clutter files, a chat that hides clutter,
  albums mixing groups, equal dates, captions), two hidden posts and a hidden chat, both tile modes, the three rules,
  and the queries default, `nd=show`, `prob=apart`, `q=zebra`, `type=photo`, `type=file`, a one-day range,
  `state=saved`, `copies=exact`, `q=zebra&prob=apart`, `nd=show&type=photo`, `clutter=show`. For every one: no exact
  group on two tiles' covers; every group whose saved file is a cover or copy with `once=0` (524 to 818 per archive)
  is in the listing (as a cover, a copy, an album's file or folded behind a face with a tile); shown + chips =
  filtered; `filtered`, hidden chats, posts and clutter equal to `once=0`'s. The code's groups equal my classes.
- **`first=1` exactly as on d1af260**: `TestR2FirstDump` run on d1af260 (scratch copy) and on d38479c: 3 invented
  archives x hidden chat off/on x both tile modes x three rules x 14 `first=1` queries (with `sameprob=0`, type,
  search, chat, range, `nd=show`, `prob=apart`, `state=missing`, `clutter=show`, `only=1`, `hidden=1`,
  `clutter=only`, `copies=exact`): every listing's entries, every count, and the first block's tiles (count, saved,
  also, folded, chats, copy, state): **byte-identical** (192,614 lines). The new `ap.first = tb.firstAt` is the same
  walk with no chat left out (`newAppear(…, nil, true)`, every file filled by `decideFirstEach`), read only.
- `parseFilter`: rule only with no chat, no topic, not `hidden=1`, not `clutter=only`, not `first=1`; `once=0` gives
  the key of the preference off; a stored preferences row without the field gets the default (laid over defaults).
- Kept listing: a preference change bumps the decisions version, so a page holding the old listing id gets "stale"
  and reloads; `onceGroupsFor` checks `g.ix == ix`, so a listing never uses another version's groups
  (`TestR2GroupsVersion`). Arrows walk the listing (`TestEachOnceArrows`).
- Snapshot: one lock, `snapMu` outside the stats' own locks and nothing takes them the other way; after a stop only
  `stop`; the writer ends on the context before `wg.Wait` returns, so nothing writes after `Close`; the early timer
  is stopped by `defer`; sends on `used` never block.
- Video click (reading): never twice (acts only when `paused` is as at the press); keys, touch, modifiers left alone;
  GIF-type clips get no handler; nothing outlives the element.
- Cost (looks like; CPU 45 % before the timing test, 82 % before the probe; invented 200,000-message catalogue,
  92,233 posts, 40,865 sets, 120,586 files): `TestTimingOnBigCatalogue` by name: PASS, library first page cold
  18.0 ms, warm 2.5 ms, filters 6 to 19.5 ms, searches 8 to 15.6 ms, cold start 1.187 s. Probe `TestR2Cost` (rule on
  vs `once=0`, cold): default no chat hidden: off 11.5 ms (on, with the table built first: 35.8); `type=photo` 19.0 vs
  11.5; `q=harbour` 15.5 vs 10.5; one chat hidden: default 20.5 vs 16.5, search 14.1 vs 12.0; groups built in 1.0 ms.
  So a few ms, not the 15 to 20 of the first round. Note: the invented catalogue has **no exact edges** (120,586
  groups for 120,586 files), so it measures the pass, not large groups.
- The branch's own tests by name: `TestEachOnce.*`, `TestNotSavedCountsAddUpEverywhere`, `TestVideoClick.*`: PASS.

## D. Guarantees with no test that would fail if they broke

- The fold following the group's place (B1): no test; `TestEachOnceNoFileVanishes` checks tile posts only, with the
  probable copy linked to the exact copy that holds the place.
- The album badge (B2): `TestEachOnceAmongWhatIsListed` checks the album's cover, not its count.
- `first=1` "exactly as on d1af260": `TestEachOnceLeavesFirstAlone` compares the rule on and off **on the same
  branch**, so a change to the shared `first=1` path (such as `tb.firstAt`) would pass it; nothing compares with
  recorded old answers as the brief asked. (My dump shows it is identical today.)
- "also in N chats" leaving out hidden chats (finding 7's fix): no test with a hidden chat.
- The video click and the sidebar's one handler: source-text tests only (any logic change keeping the strings passes).

## E. Not checked

- No browser run (page, chips, the click). Not the whole package, `go vet`, `gofmt`, `cmd/tgarchive` tests (not mine
  to run). Windows' real console-close timing. Verdicts ("same"/"not the same") combined with the rule: by reading
  only (they change the fold, not the exact groups).
