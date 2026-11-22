# Review E21: `archiver/tools/probe-misses` (independent, Opus 5.5 high, 11-16)

Head read: `wip/copies-21` cc8f6e43 (`main.go`, `probe.go`, `probe_test.go`; the report last). Catalogue code read
at the same head: `state.go` (Saved, Transition), `exactcheck.go` (LinkSame, matchOf, recordCheck, the candidates),
`bringin.go` (importOne), `probe.go` (probeSettle, savedMediaOf, writeProbeRow), `schema_probe.go`, `vfp.go`
(PutVideoFingerprint, the walks), `imported.go` (PutFingerprints' upsert), `catalog.go` (file, fetch),
`lane.go` (supply guard), `footage/compare.go`, `footage/sample.go` (Verdict), `footage/footage.go`,
`probejudge/turn.go` (outcome). Probes: untracked `zz_probe_review_test.go` in
`wt-copies-review21-scratch/archiver/tools/probe-misses` (detached at cc8f6e43), invented data only.

## Answers

### 1. What "downloaded" and "same bytes" count
Every writer of `tg_media.file_id` (a grep of `SET file_id` / inserts with it outside tests):
- **A real download**, `state.go:567-660` `Saved`: looks the bytes up by `file WHERE sha256 = ?` (line 589;
  `file.sha256` is `NOT NULL UNIQUE`, `catalog.go:372`); identical bytes end on the existing row (Duplicate, line
  592) or revive a lost one (597); `UPDATE tg_media SET file_id` (627); **and always `INSERT INTO fetch`** (631).
  So a download of the named file's bytes does end on the named file's own row: same-bytes == `own.id = of_file`.
- **A skip by exact evidence**, `exactcheck.go:691-765` `LinkSame`: `UPDATE tg_media SET file_id = in.Match`
  (731), "No fetch row: nothing was fetched" (doc, 687-688); a `c_check` row `(tg_media_id, Match, 'same')`
  with its `rule` (recordCheck, 343-358). The rule may be `three-places` (736-738, the owner's default mode since
  11-14, `ExactMode` 405-408): **sampled Telegram part hashes, not a SHA-256 of these bytes.**
- **The bring-in**, `bringin.go:163-216` `importOne`: an existing `tg_media` gets `file_id` (200) with no fetch
  row and no c_check row (a `file_copy` row with the old app's source, 152).

Which probed rows meet the skip: a "nomatch" file goes back wanted (`probe.go:970-984`) and is exact-checked at
its claim against saved files of exactly its size (`exactcheck.go:99-103`), the named file among them when the
sizes match; a "copy" file is held probable (`probe.go:960-967`) and is supplied at tier 5
(`lane.go:37`, `w.state = 'held' AND w.probable = 1`), and an owner's release "is downloaded unless the exact
check finds it the same" (`state.go:490-492`). The tool's join (`probe.go` of the tool, 212-220) takes any
`file_id` as "downloaded" and `own.sha256 = nf.sha256` as "same bytes": **probe P1 shows a "nomatch" row and a
"copy" row linked by `LinkSame` (no download, 0 fetch rows) each counted downloaded 1, same-bytes 1.** Since
such links are selected for equality, they always land in "same-bytes": they raise "copy was right" and "nomatch
was wrong" with files never downloaded, and the column's words ("its SHA-256 equals") are false for a
three-places link. **The catalogue can tell it without guessing:** downloaded = a `fetch` row for the media
(only `Saved` writes one; nothing deletes one but the media's own cascade); linked by Telegram's hashes = no
fetch row and a `c_check` row `(media, own file, 'same')` (its `rule` splits full and three-places); anything
else without a fetch row = brought in. The old table's "skipped by Telegram's hashes" column is exactly this.

### 2. Which file a row is judged against
`of_file` is written only through `evidence()` in `probeSettle` (`probe.go:803-811`), for copy, partly and
nomatch words; a copy whose named file is gone or the owner said differs clears it and ends unchecked
(943-946); other words carry the stored value. For nomatch, `OfFile = ids[out.Of]` (`probejudge/turn.go:606-608`)
with `Of` = "the first with the most hits ... -1 when no sample matched any" (`footage/sample.go:183-186,
208-220`): the closest candidate by sampled hits, or NULL when no frame matched any. So: a nomatch reached
against several candidates is judged against the closest only (a download that copies another candidate counts
"different"); a nomatch with zero hits names nothing and is "not judged: no-named", i.e. the most confident
nomatches drop out of the denominator. That is the old app's "no match against a named file", but the sentence
must say it. **It can change after the result is set (probe P4):** a held file is not caught by the done-row
guard (`probe.go:817-819` tests `!free && !held`); a later decisive word goes through `case VerdictNoMatch`
(970-984) and rewrites result and `of_file`: a row settled "copy" of file X became "nomatch" of file Y, then
"nomatch" with no named file, the file still held. The tool cannot see that history.

### 3. `footage.Compare` as the judge
No product code calls `Compare` on stored fingerprints (only `footage/ffmpeg/fingerprint_test.go`); it is the
port of the old app's post-download `ixVCompare`. The tool feeds it the frames as stored
(`Unpack` of `data`, `PutVideoFingerprint` stores `Pack`ed frames, thinned to 3,600 by the worker) and the meta's
`duration_s` (0 when absent: `Length` takes the frames), which is right. `Compare` returns only None, Same, Clip,
Overlap (`compare.go:13-18, 164-205`); the three non-None are the old table's "same content". One fault: when
both files lack `footage.Version`, the tool compares the highest common other version (`commonVersion`), though
`footage.go:50` says other versions "are not these" and every candidate walk is `ver = footage.Version`
(`vfp.go:368`); the bring-in imports `ix_vfp` with its own `ver` (`bringin/run2.go:131`).

### 4. One cell per row; the sentences
Each downloaded row goes to exactly one of no-named, named-gone, same-bytes, named-gone (lost), or `judge`'s
not-judged reason / different / one relation (`probe.go` 373-395); "all" is the sum (`add`). Holds, apart from
finding 1 (cells right, "downloaded" wrong). The sentences use `judged()` = same-bytes + pairs + different as the
denominator and "too few to read" under 20 (`minJudged`), as briefed; their words need finding 4's additions.

### 5. Writes nothing, prints no data
Closed (no `-wal`): `mode=ro&immutable=1`, nothing appears (coder's test; probe P3 with a lone `-shm`: nothing
appears or changes). `-wal` present: `mode=ro`; with a `-shm` already there one byte of it changes (the read
mark: the collector's shared memory, unavoidable and harmless). **A `-wal` with no `-shm` beside it: probe P2
shows a new 32,768-byte `-shm` made by the run** (SQLite opens the index read-write when it can). A collector
starting between the `Lstat` and the reads: the tool, immutable, reads the main file without its log and without
locks: counts may miss the newest rows or, during that collector's first checkpoint, read a torn page (an error,
or rarely a wrong count); nothing is written. Output and errors: counts and fixed words only (`wordsOf`, `render`);
the coder's no-data test passes. A Go panic would print a stack with argument words (file numbers in hex); no
panic path found in `Compare`/`Unpack` on odd data (NaN times are excluded from gaps).

### 6. Snapshots
The rows are one statement (one snapshot); each pair's reads are later snapshots. A cell can only move forward
in time (a fingerprint that came later gets judged). One wrong-cell path: `fpVersions` sees a frames row, then
`PutFingerprints`' upsert (`imported.go:76-78`) replaces it by a failure row before `readFP`: zero frames,
`Compare` gives None, counted "different". No writer does that today (the worker fingerprints only files with no
row). One read transaction would hold the collector's checkpoints for the run; the smaller risk is to keep the
separate reads and treat zero frames after `readFP` as not judged.

### 7. A lost named file
Nothing deletes a lost file's fingerprint (only `TakeBackVideoFailure` deletes, and only failure rows), and the
fingerprint was made from the bytes when they were there, so judging it would be valid. The loss is small (a lost
file is rare); the "named-gone" count says how many. Acceptable as is; judging them with a count beside is better.

## Findings
1. **High.** "downloaded" and "same-bytes" count media linked without a download (the exact check's `LinkSame`,
   full or three-places; the bring-in). Such links always land in same-bytes, so they make "copy" look right and
   "nomatch" look wrong with no download behind them, and a three-places link is not a SHA-256 equality. **Probe P1
   shows it** (nomatch and copy lines each `[1 1 1 0 ...]` with 0 fetch rows, 2 `c_check` 'same' rows). Smallest
   fix: "downloaded" = `EXISTS (SELECT 1 FROM fetch WHERE tg_media_id = p.tg_media_id)` with the own file; a new
   column "linked, not downloaded" split "by Telegram's hashes" (a `c_check` row `(media, own file, 'same')`,
   optionally by its `rule`) and "other (brought in)", outside "downloaded" and the sentences (or a third
   clause in each sentence: "and N linked by Telegram's hashes"); the column note in fixed words; a test that
   builds the link through `LinkSame` as P1 does. Caveat for the note: a fetch row from an earlier download of a
   media whose file was lost and later re-linked would still count it downloaded (rare).
2. **High (written).** A `-wal` with no `-shm` beside the catalogue: the run makes a 32,768-byte `-shm`. **Probe
   P2 shows it.** Smallest fix: in `openCatalogue`, when `-wal` exists and `-shm` does not, refuse in fixed words
   ("a log without its index is beside the catalogue: refused") and exit 1; a test with a zero-length `-wal`.
3. **Medium (catalogue, not the tool).** A later decisive word on a held file rewrites a settled row's result and
   `of_file` (`probeSettle`: the done-row guard does not cover a held file). **Probe P4:** copy of X became nomatch
   of Y, then nomatch of nothing, the file held throughout. The tool would count such a row in the wrong line.
   Fix in `probe.go` (the copies track's catalogue code): a done row keeps its result and `of_file` whatever the
   file's state; a later word is recorded as late. Not a blocker for listing the tool; goes on the board.
4. **Medium (words).** The nomatch sentence is read as "how often a no match was wrong", but its judged rows are
   only those whose closest candidate (most sampled hits) got a name; a no match with no matching frame is
   "no-named" and left out, and other candidates are never compared. Smallest fix: one fixed line under the
   sentences: "A row is judged against the one saved file its check named: for a copy the file matched, for a no
   match the candidate with the most matching frames; a no match with no matching frame names none and is not
   judged. Same content is same, clip or overlap."
5. Low. A common version other than `footage.Version` is compared with `Compare`. Fix: judge only at
   `footage.Version`; otherwise not judged under "versions" with the words "not both of this build's version".
6. Low. Immutable read while a collector starts: after the pass, `Lstat` the `-wal` again; if one appeared,
   refuse ("a collector started during the read: run again").
7. Low. Zero frames from `readFP` (a row replaced between the two reads) counts "different"; make it not judged.
8. Low. A lost named file is not judged though its fingerprint remains; judge it, keep the named-gone count as
   "of which lost".
9. Low. A panic would print a stack with numbers: a `recover` in `run` printing fixed words, exit 1.

## Not looked at
The supply's exact-check call path itself (that a tier-5 held copy and a released copy reach `LinkSame` is read
from `lane.go:37`, the `ExactTarget` and `Transition` comments, not traced through `internal/supply`);
`footage.SampleMatch`; the catalogue's journal pragmas (whether a closed catalogue can keep a persistent `-wal`);
whether the Windows VFS honours `readonly_shm`; how often a late word reaches a held row in practice; the whole
packages' tests, vet and race (not this pass).

may be listed after these fixes: 1, 2, 4

## The check of the fix round (1440cdc2)

Read: `git diff cc8f6e43 1440cdc2 -- archiver/tools/probe-misses/probe.go`, the new tests `TestProbeMissesExactLink`,
`TestProbeMissesWritesNothing`, the table `wantTable`, and the report's fix-round section. Line numbers are
`probe.go` at 1440cdc2. One test run in the scratch copy (detached at 1440cdc2, under the track's lock, 1.9 GB
free): `go test ./tools/probe-misses -run TestProbeMisses -count=1 -v`. All the coder's tests passed (Table,
ExactLink, LateWord, WritesNothing x4, LogAppeared, ZeroFrames, Panic, PrintsNoData, Refuses x6). My earlier
probes plus one new state also passed: P1 gives nomatch `[1 0 ... 1 0 0 0]` and copy `[1 0 ... 0 1 0 0]`
(linked, not downloaded); P2 is refused with nothing made; P3 makes nothing; the new state, an empty `-wal` with an
empty `-shm`, is below.

**(a) Finding 1: closed.**
- "Downloaded" now needs a fetch row (`EXISTS (SELECT 1 FROM fetch x WHERE x.tg_media_id = p.tg_media_id)`, 255).
  `fetch.tg_media_id` is the media's key, and only `Saved` writes a fetch row (state.go:631), so the join is right.
- A media with its own file and no fetch row goes only to a link column (`if !r.fetched { l.Linked[...]++; continue }`,
  470-473). It never reaches "downloaded", "same-bytes", a pair or "not judged", so it is in exactly one cell.
- The rule lookup (268) is right: `c_check`'s key is `(tg_media_id, file_id)` (schema11.go:55), so the subquery
  returns at most one row. It takes outcome `'same'` on the own file, and `rule` is `NOT NULL DEFAULT ''`
  (schema11.go:53). `linkOf` (514) sends `full` and `three-places` to their columns and anything else to "other
  rule". A media with no such row counts as "brought in". The no-column fallback is never reached (the column is
  in the table's CREATE) and is harmless.
- A spot-checked link (downloaded anyway) has a fetch row and counts as downloaded. That is right.
- The coder's doubt (a media downloaded once, then unlinked and linked again by the exact check): **yes, it can
  happen.**
  - `WantAgain` sets `tg_media.file_id = NULL` when a file is lost (staging.go:630). The media is wanted again
    and can then be linked by `LinkSame`, while its old fetch row stays.
  - The new link can only be to a file row that is not lost (exactcheck.go:670-671). Since `sha256` is unique,
    it ends on its own old bytes' row (revived by another media's download) whenever the hashes were right. Then
    the media did download exactly these bytes once, and counting it as downloaded is true.
  - The only other target is a different row reached by a wrong three-places link, which is negligible.
  - Wording, low (point L1 below): "downloaded: the media was downloaded at least once (a fetch row)".

**(b) Finding 2: closed for the file it named. One small residual write remains.**
- No `-wal` (with or without `-shm`): opened immutable, nothing made or changed (P3 and the test "index alone").
- `-wal` with no `-shm`: refused in fixed words, nothing made (352-365, the test "log without index", P2).
- `-wal` with a `-shm`: opened `mode=ro`. A live `-shm` gets its one-byte read mark (accepted before).
  **An empty `-shm` beside a `-wal` is rewritten to 32,768 bytes** (new state, seen in the run): SQLite rebuilds
  its index into the file. No file is created; the catalogue and the log are untouched. That is the same class
  as the read mark, but it is a write into a file the run did not find in that state.
  - Point L2: refuse a `-shm` shorter than 32,768 bytes with the same words as "log without index".
- Race (point L3): between the two `Lstat`s and the first query (`sql.Open` connects lazily), a collector closing
  cleanly removes `-wal` and `-shm`. The `mode=ro` open would then make both anew, which is the E20 class.
  - The window is milliseconds and was there before the round.
  - Fix: after the pass in log mode, if `-wal` or `-shm` was not there before the open but is there now, that
    cannot be told apart from a collector's own. So say it in the legend, or accept it.

**(c) The fixed lines and the denominators.**
- `judged()` (177) counts only same-bytes, pairs and different. Those fill only after `r.fetched` (470), so linked
  rows are in neither sentence, as the reading line says (`readingLines`, 741), and as `TestProbeMissesExactLink`
  shows (both sentences are "(0): too few to read" with three linked rows).
- The lines say what the code does:
  - judged against the one named file;
  - a nomatch's file is the closest candidate (turn.go:606-608, sample.go:183-186);
  - same content means same, clip or overlap;
  - the held-file fault (finding 3) is named.
- The version rule matches 617; zero frames is not judged (634); a lost named file is judged by its fingerprint,
  and "named-gone" is no row, or lost with no frames (604).
- Wording, low (point L4): the second reading line says a zero-hit nomatch "is counted as not judged: no named
  file". That is true only when it was downloaded (a linked or never-downloaded one is counted elsewhere). Add
  "when it was downloaded".
- Wording, low (point L5): `logAppearedWords` says the counts "may miss its newest rows". During that collector's
  checkpoint an immutable read can also see a page half rewritten. Add "or be off; run again".

**(d) Nothing found broken.**
- Rows still go to one cell each. `add` sums `Linked` (190-192). `wantTable`'s `all` line equals the column sums
  of its lines (23 rows; 16 downloaded + 1 linked + 6 not downloaded).
- No rule value can be printed. The rule string is only compared in `linkOf` (514-525) and printed as one of four
  fixed heads (`linkHeads`) with fixed words. `errFault` prints no value (the recover at 287 discards it).
  `TestProbeMissesPanic` uses an invented ten-digit number in the panic and passes. `PrintsNoData` passes on the
  larger table.

Open points (all low, none blocks listing):
- L1: "downloaded" words: at least once.
- L2: refuse a `-shm` under 32,768 bytes.
- L3: the close-race in log mode (accept, or say it in the legend).
- L4: the zero-hit nomatch line: "when it was downloaded".
- L5: the log-appeared words: "or be off; run again".

may be listed
