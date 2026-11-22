# Review of brief E24 ("C19"): a removed copy edge logged as kind 1 for its two media

Independent Opus 5.5 review, high effort, 11-16 about 16:50. Head read: `wip/copies-24` **ead8f212** (copy
`wt-copies-24`, clean), against 5d884fc2. Read: the brief, the whole difference, `internal/viewer/refresh.go`
(`update` checks 575-585, `readLog` 993-1064, `readStates` 1066-1083, `apply` 1188-1402), `internal/viewer/check.go`,
`internal/viewer/viewer.go` `watch`/`refresh` (509-610), the viewer tests that failed, `catalog.go`'s `Open` and
`migrate`, `changelog.go` (prune), `chatreads.go` `CountsKey`, `pairword.go` `lostLookAlike`, the WantAgain timing
test; the coder's report last. Probes in my scratch copy `wt-copies-review24-scratch` (detached at ead8f212):
`archiver/internal/catalog/zz_probe_edgelog_test.go`, outputs `zz_viewer_branch.txt`, `zz_catalog_probe.txt`.
Nothing changed in `wt-copies-24` or in any `internal/viewer`.

## Question 1: is the viewer RIGHT after this step? No: only the state is read again; the removed pair stays

What the index writer does with a kind 1 row:
- `readLog` (refresh.go 1034-1037): `case catalog.ChangeMedia: if id <= w.lastMedia { media[id] = true }`. Kind 3 was
  `default: gone = true` -> `errFullRead` (1052-1061).
- Those ids go to `readStates` (1066-1083): `SELECT t.id, <state cols>, w.state, w.reason FROM tg_media t LEFT JOIN
  c_want w ...`: the media's state only. **No read of `copy_edge` for them.**
- `apply` (1296-1339): per state row, `if m.state == st && (m.flags&mfHeldCopy != 0) == held { continue }`: a media
  whose state did not change is not even marked dirty. `edges` (the index's per-media edge lists) is begun from the old
  version (1247) and only ever APPENDED to, from edges with `rowid > w.lastEdge` (862-881, 1378-1402). Nothing in an
  incremental update removes an edge, clears `mfEdgeProb`, or lowers `ix.probablePairs`.
- The only nets: `MAX(rowid) FROM copy_edge < w.lastEdge` -> full read (575-584: catches only the removal of the
  newest edge), and the count check (`check.go`: `COUNT(*) FROM copy_edge WHERE rowid <= lastEdge` != `w.edgeRows` ->
  `needFull`), which `watch` runs every `checkEvery = 5 * time.Minute` (viewer.go 550-555).

So with this step alone: after the owner's "not the same", or a lost look-alike, every open viewer keeps the removed
probable edge in its index: in the two media's edge lists (the fold's "+n probable" and the post page's folded list,
appear.go's one probable step, the item count of a complete post, `standIn` / `copyOf`: a file shown with a saved copy
through an edge that is gone), the `mfEdgeProb`/`mfProbable` flags ("Has probable copies"), and `probablePairs`.
**For how long: until the next count check, 0 to 5 minutes (plus one refresh tick), or sooner if anything else asks
for a full read (another row gone, the newest edge removed, a pruned log). Then a full read happens anyway**: the
same ~4 s the step was meant to save is only delayed (several removals inside 5 minutes share one). The owner's own
"not the same" given through the viewer is partly masked by the viewer's own verdict (appear.go 217-243 skip a pair
judged "different"), but not the twins' edges the catalogue also removes (the verdict names the pair, not the twin),
nor the flags, counts and stand-ins; the lost look-alike has no verdict at all.

Viewer tests by name on the branch (`go test ./internal/viewer -run 'TestLost|TestStaged|TestIncremental|TestRandomUpdates|TestChanges|TestChangeLog|TestWall' -count=1`,
run twice, 104 s and 97 s, 8.7 GB free): FAIL, three tests, everything else in the set passes.
- `TestChangeLogEachChangeFollowed/a_copy_edge_went_away` (review_chal2_test.go 380-382): **wrong result**. "updates
  0, full reads 0; want 1 and 1" (the update found nothing to change and kept the old version), then "updated vs full
  read": the updated index keeps edge 8-9 (`edges [9/2]`, `[8/2]`, flags 19/27 vs 1/11), `probable 33` vs `32`,
  and media 9 keeps `copy 8` (a saved stand-in through the removed edge) where the full read and the reference have
  `copy 0`.
- `TestLostThroughIncrementalUpdate` (staged_b5_test.go 459, 489, 508): **wrong result, through three successive
  incremental updates** (WantAgain, the revival, CopyDone): media 11 and 68 keep the removed probable edge 11-68
  (`edges [1/1 68/2]` vs `[1/1]`; flags 55/23 vs 37/5; `probable 9` vs `8`); after the revival media 68 shows
  `copy 11` (a saved copy through the removed edge) where the full read has none. Its last assertion (0 full reads)
  now passes; on the head it failed for 1 full read (the board's 135).
- `TestRandomUpdatesMatchFullRead` seeds 1-5 (refresh_random_test.go 530): "0 full reads, want 1" after the random
  "an edge removed" operation: **an assertion of the old cost**; it is a `Fatalf`, so its index comparison is never
  reached; by the two tests above it would show the same stale edge (not run to that point: I did not change the
  viewer).

## Question 2: the step itself: sound
- Refused on any version but `edgeLogAfter`, in fixed words (`schemaEdgeLogFor`); `TestEdgeLogStep` checks it on a
  file at `actAfter`. Idempotent (`DROP TRIGGER IF EXISTS` then `CREATE`; the test runs the text again and opens
  twice: same schema objects). A file at the step before takes it once (trigger text read from `sqlite_master`
  before and after). A catalogue made new runs every step (`migrate` from `steps[0]`) and has the same text (test
  compares). Run on the branch: `TestEdgeLog|TestChangeLogEveryPath` all PASS (0.18-0.58 s each).
- Nothing else in the schema names `cl_edge_ad` (only `changelog.go` v3 and `schema_edgelog.go`). Every non-test
  reader of the log in the repository:
  1. `internal/viewer/refresh.go` `readLog`: kind 3 -> full read; kind 1 -> the id into `readStates` (see 1). A kind
     1 for a media that no longer exists (the cascade case): `readStates`' `IN (...)` returns no row for it, `apply`
     never sees it: harmless; and the cascade's `(3, m)` in the same statement (after the edge pairs: the coder's
     `TestEdgeLogOtherRowsStillGone` checks the order) asks for the full read anyway. Already so at v3 through
     `cl_want_ad`.
  2. `internal/catalog/chatreads.go` `CountsKey`: `MAX(seq)` of the log (plus `MAX(rowid)` of `copy_edge`): moves
     on either kind; unaffected.
  3. `internal/catalog/changelog.go` `pruneChangeLog`: by seq range, blind to kind and id; unaffected (measured, 3).
  No reader in `internal/server`, the pages or anywhere else (grep of `change_log`, `ChangeGone`, `ChangeMedia` over
  non-test Go code).

## Question 3: volume and the writer: no measurable difference
Probe `TestZZProbeEdgeLogVolume` (5,000 held look-alikes against one saved file, WantAgain; the head's trigger put
back by SQL on the branch's file for the "old" rounds, alternated):

| round | trigger | WantAgain | edges phase (`lostTrace`) | log rows (kind 1 / of A / kind 3) | prune of all, slowest chunk |
|---|---|---|---|---|---|
| 0 | head (kind 3) | 183 ms | 19 ms | 5,151 (151 / 2 / 5,000) | 48 ms, 31 ms |
| 1 | branch (kind 1) | 183 ms | 21 ms | 10,143 (10,143 / 5,002 / 0) | 54 ms, 32 ms |
| 2 | head | 164 ms | 17 ms | 5,158 | 65 ms, 29 ms |
| 3 | branch | 178 ms | 17 ms | 10,162 | 73 ms, 31 ms |

The second insert per edge is lost in the noise; the existing 500 ms bound of `TestWantAgainManyLookAlikes` is far.
The 200 cap (`lostSettleMax`) bounds the settle only, not the delete (one statement per media, unbounded): 2E rows for
E edges, E of them the lost media's id. The viewer keeps ids in a map (`media[id] = true`): 5,000 repeats cost one
entry. Pruning is by seq range and does not care.

## Question 4: the tests
- `TestChangeLogEveryPath`, case "a copy edge removed": from `contains {3, 0}` (at least one kind 3 with any id; the
  head's comment "the edge's rowid, checked below" was never checked) to `want {1, m1}, {1, m2}` (exactly these rows,
  any order): stricter. The order a-then-b is checked by `TestEdgeLogStep` and `TestEdgeLogRemovedEdgeIsTwoMediaChanges`.
- Do the new tests fail on the head's trigger for the reason they name? Probe `TestZZProbeEdgeLogHeadTriggerFails`
  (SetPairWord "different", head's trigger put back): log `[{3 1} {1 2}]`, kind 3: 1, adjacent `(1,a),(1,b)` pairs: 0
  -> `edgeLogged` would report both "a kind 3 row" and "no rows (1, a), (1, b)"; on the branch's trigger
  `[{1 2} {1 1} {1 2}]`, kind 3: 0, pairs: 1. Consistent with the coder's report of the one failing run.

## Question 5: old programs and old rows
- Kind 3 rows for edges already in a stepped catalogue's log: any viewer positioned before them reads in full once;
  harmless.
- An older read-write program on a catalogue at the new step: `migrate` refuses ("file has schema v%d, this program
  reads v%d"). **An older viewer: `catalog.Open(path, true)` checks no version and the viewer probes features
  (`hasLog`, `hasLoc`, `hasQueue`), so it opens the stepped catalogue and behaves exactly as in question 1: stale up
  to 5 minutes per removal.** Every viewer build without the viewer's side (the owner's folder, the viewer track's
  `bin`, entry 25's build) is in that state the moment a collector of this step opens the catalogue read-write.

## Findings

1. **HIGH (the viewer shows a stale and wrong result after the step): a removed edge stays in every open viewer's
   index for up to 5 minutes (until the count check), then the full read happens anyway.** Shown by
   `TestChangeLogEachChangeFollowed/a_copy_edge_went_away` and `TestLostThroughIncrementalUpdate` (index differs from a
   full read and from the reference: edge kept, probable flags and count, a saved stand-in through the removed edge).
   The catalogue's step is correct; the piece cannot be listed alone. Smallest fix, the viewer's file
   (`internal/viewer/refresh.go`, the viewer track's): in `readLog`/`update`, for the kind 1 ids (at most `lastMedia`)
   read their edges again (`SELECT rowid, a, b, relation FROM copy_edge WHERE a IN (...)` and `... WHERE b IN (...)`,
   rowid at most `lastEdge`), and in `apply` replace those media's edge lists (both ends of each removed edge),
   recompute `mfEdgeProb`/`mfProbable`, lower `probablePairs`, `dirtySetsOf` and `noteStand` both ends, and lower
   `w.edgeRows` by the removed count (else the count check still calls the full read). It must also cope with a
   changed relation and with `INSERT OR REPLACE` of a pair (tests only today: the old edge's kind 1 rows, then a new
   rowid). A stop-gap with no speed gain, if the step had to go first: for kind 1 ids, compare their edge count with
   the index's and return `errFullRead` when it fell. **List C19 only together with the viewer's side (one merge, or
   the viewer's side first and this right after), as copies' message 139 (c) already proposes.**
2. **MEDIUM: viewer builds without that side keep working on a stepped catalogue and are wrong in the same way**
   (question 5). Fix (the integrator's, at the merge): the collector in place, the owner's folder and the viewer
   track's `bin` are rebuilt from the same head that carries both sides, in one go; no collector of this step is put
   in place beside an older viewer.
3. **LOW: three viewer tests assert the old cost and are the viewer track's to set:** `TestChangeLogEachChangeFollowed`
   case "a copy edge went away" (`full: 1` -> 0), `TestRandomUpdatesMatchFullRead` (its "edge removed" operation sets
   `full`; line 530 is a `Fatalf` that hides the index comparison: after the fix the comparison is the real check), and
   `TestLostThroughIncrementalUpdate` as mended in entry 25 (one full read at the lost step -> none). Each should then
   assert 0 full reads AND the index equal to a full read.
4. **LOW: the premise in the brief section 0 and in the coder's three lines is wrong for edges:** "Kind 1 is what a
   reader already gets when a hold is made or ended, and the viewer redoes that media's sets in place." Kind 1 makes
   the viewer redo a media's STATE, and its sets only when the state or the held flag changed (refresh.go 1307); it
   never reads edges. Fix: the report's line 3 for the viewer track says "the viewer must read those media's edges
   again (it does not today)"; the brief is history.
5. **LOW: `TestEdgeLogStep` pins `edgeLogAfter != actKeySchema`** (and `edgeLogAfter = actKeySchema` in the step
   file): with the mirror's M6 claiming 26, the integrator moves both at the merge (the report says so). Note only.

## Not looked at
The viewer's fold, appear and stand-in code beyond the lines named; `internal/server` and the pages beyond a grep;
the whole `internal/catalog`, `internal/viewer`, any race run, vet; `lostLookAlike`'s probable edges with the lost
media on the `a` side (not deleted by it; outside this piece); the interplay with M6's schema step 26; the viewer's
`changes.go` page (it does not read `change_log`).

may be listed after these fixes: 1, 2
