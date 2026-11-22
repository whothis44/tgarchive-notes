# Brief E19: the owner's "same / not the same" acts on a held copy; a held copy whose saved look-alike is lost (copies, session C4, 11-16)

**For an Opus 5.5 coder at high effort. Routine steps are not yours to repeat: you write code and run only the
named tests of what you changed; the whole runs, vet over packages, the race detector and the merge of the head
are done once, later, by a clerk of the main session.**

- Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-19`, branch `wip/copies-19`, cut from the main head
  dbca91d4. Work only there. Go: `. /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in the Bash
  tool, then the copy's `archiver`.
- Commit as you go: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; `git push private wip/copies-19` after each commit.
  Never another branch; never merge; never tag.
- Invented data only. Nothing runs against Telegram. No log line, test, comment or report carries a real name,
  text, path, id or link; new log calls have constant format strings and print counts and fixed words only.
- Nothing in product code depends on this PC's absolute paths, the start folder, PATH or the start scripts.
- **Another coder of this track works now in `internal/collector`, `internal/supply` and `internal/parts`
  (`wip/copies-18`): you touch none of them.** Core's coders are in `internal/collector` and `internal/store`;
  the viewer's in `internal/viewer`: you read `internal/viewer` and edit nothing there.

## 0. What the old app already knows, and the owner's decisions (read by the main session in full: TRIED-BEFORE 6, 21, 27; answers 4, 5, 8)

- **No stored fact separates a wrong look-alike hold from a right one.** Of the old app's look-alike holds that a
  frame check judged (all over 200 MiB): against a saved file 1,218 confirmed and 275 released. Preview distance,
  length, pixels and byte size are, if anything, closer among the released ones. Among small files about 5% of
  holds by the preview rule were wrong. And the frame check's own "no match" was wrong about 3 times in 4 against a
  named file (at least 23 of the 275 it released were exact copies). **So a hold has only two ways out: exact
  evidence, or the owner's word. This piece builds the owner's word.**
- The old app held 39,798 files against a saved file on 11-13 (1,990 GB). It released a hold whose saved file was
  lost; the new app does not yet: the probable edge outlives the saved file and the hold stays for good.
- **The owner, 11-15 20:37 (item 21): "Yes to both I think. I'm not sure ... I would be using it very often."**
  "Same" keeps the file held and marks the hold as confirmed by the owner: **it is never skipped on a click; only
  the same bytes skip a file.** "Not the same" ends the hold against that one file: the held file is downloaded
  in its turn unless another saved file still holds it, and that pair is never held again. Built small.
- **The owner, 11-15 20:34 (item 27):** when the saved file a held copy was held against is lost, the held file
  is judged again and becomes wanted, unless another saved file still covers it.
- The owner's rules that bind every line: only exact evidence (the same Telegram file, the same SHA-256, every
  part hash) may skip a file; a probable copy is held, never skipped; a frame check's "no match" never releases a
  file by itself; nothing in the background reads the library folder.

## 1. What exists (read these first, in the copy)

- The viewer records the owner's word and does nothing else with it: `internal/viewer/verdicts.go` and
  `decisions.go` (read both headers and `putVerdict`, `openDecisions`). The file is `decisions.sqlite` in the
  viewer's data folder, WAL mode, one writer connection kept open by the viewer. Table `verdict(a_kind, a_tg,
  b_kind, b_tg, verdict, at)`: the two files by Telegram's own file identity as the catalogue stores it
  (`tg_media.kind`, `tg_media.tg_id`), the smaller first, `verdict` `same` or `different`; taking a word back
  deletes its row. Never keyed by a catalogue row number.
- A probable copy in the catalogue: its collector row `c_want` is `held` with `probable = 1` and one of the
  probable reasons (`probableReasonSQL` in `ladder.go`), and a row `copy_edge(a = the held media, b = the saved
  media, relation 'probable', evidence)`. Made by: rung 6 at cataloguing (`ladder.go` `lookAlike`,
  `lookAlikeVideo`), the step at a save (`atsave.go` `holdCoveredBy`), rung 4 (the same post), the exact check's
  "probable" (`exactcheck.go`), the frame check's "copy" (`probe.go` `ProbeVerdict`), the bring-in's old holds
  (`keep_held`). `wantedAsMainSQL` (`ladder.go`) holds a file again from its edge when its role or chat changes.
- The owner's release of a whole file exists already: `c_want.released`, set by `Transition` from held to wanted
  (`schema_released.go`, `state.go`); nothing holds a released file again. This piece is the release **of one
  pair**, which that column cannot say.
- A lost file: `Catalog.WantAgain` (`internal/catalog/staging.go`), one transaction per file; `lookAlikeVideo`
  already skips a saved file whose bytes are lost.
- The frame check's candidates: `ProbeLook` and the candidate walks in `probe.go` and `vfp.go`
  (`VideoCandidates`, `candFirstSQL`, `HeldOf`), and the "copy" a verdict writes (`ProbeVerdict`, `of_file`).

## 2. What to build

### 2.1 The catalogue's own record of the owner's pairs (a schema step)
A new file `schema_pairword.go` as the other steps are written (`schema_actkey.go`'s or `schema_mirrorwant.go`'s
form: the step is "the one after the head it is cut from", the number in two constants, a test of the step at an
old file and a new one). **On the board the step is 25 (24 is Core's, not merged yet); on your branch it follows
the head's newest, and the integrator sets the number at the merge.** One table, `WITHOUT ROWID`:
`c_pair_word(a INT, b INT, word TEXT CHECK (word IN ('same','different')), at INT, applied_at INT, PRIMARY KEY(a, b))`
with `a < b`, both `tg_media.id` (row numbers are right here: this is the catalogue's own table; the stable keys
stay in the viewer's file), each `REFERENCES tg_media(id) ON DELETE CASCADE` if the catalogue's other tables do
that for media (follow `schema_probe.go`'s `c_part`), and an index by `b` so that both sides are found by a seek.

### 2.2 One door: `PairWords`
In a new file `pairword.go`:
`func (c *Catalog) SetPairWord(ctx, x, y int64, word string, at int64) (PairSettled, error)` and
`func (c *Catalog) ClearPairWord(ctx, x, y int64) (PairSettled, error)`, each one transaction, idempotent (the same
word again changes nothing and says so), `ErrNotFound` when either media has no row, refused for `x == y`.
`PairSettled` says in fixed words and counts what happened (edges removed, files made wanted, files held against
another file, files left as they were and why).

- **`different`:**
  1. The row is written (or changed from `same`).
  2. Every `probable` edge between the two media, in either direction, is removed. An `exact` edge is never
     touched, and a pair that has one is refused with a fixed word (the owner's word does not outweigh the same
     bytes; nothing changes).
  3. For each of the two media that is `held` with `probable = 1`, not `keep_held`, and has **no other** probable
     edge left: it is judged again by the catalogue's own rules, as a new attachment would be at this moment, with
     this pair left out: rung 6 against the saved videos (held against another saved file, with a new edge and
     rung 6's evidence), else wanted in its turn, marked for the exact check first when a saved file of its byte
     size exists and the setting is not off (the same decision `holdCoveredBy` and the ladder make: reuse their
     code, do not write the rule a second time). One with another probable edge left stays held as it is.
     A `keep_held` file is left as it is and counted (the bring-in's old holds are not released by this piece).
  4. A file that is wanted with `check_first = 1` only because of this pair's edge: the mark goes when no saved
     file of its byte size is left to compare with by another edge or by the same-size rule (find how
     `markCheckFirst` and its unmarking decide today and use that).
  5. A file in any other state (in transfer, set aside, saved, skipped, gone, held for another reason): only the
     row and the edge's removal; its state is not changed. Never `skipped`, never `gone`, by any path of this
     door.
- **From then on the pair is never held again and never compared:** rung 6 (`lookAlikeVideo`: such a saved
  candidate is passed over and the next is tried), the step at a save (`holdCoveredBy`), `wantedAsMainSQL`'s
  holds (they go by the edge, which is gone: check that nothing writes it back), the frame check (that saved
  file is not a candidate for that queued file, and a "copy" naming it is not written: find the place in
  `ProbeLook` or the candidates' walk and in `ProbeVerdict`; a check whose only candidate it was ends as "no
  candidate" does today), the exact check's "probable" (a three-places "same" against it does not hold the
  file; **a full exact match still skips it**: exact evidence outweighs the word, and the pair's row is then
  kept and counted as contradicted). Each of these reads is one seek of the new table by its key: say in the
  report what each costs and that no walk got a table scan (the plans, as the other steps' reports give them).
- **`same`:** the row is written; nothing else changes. The file stays held; it is never skipped; a later frame
  check's "no match" changes nothing (as today). If the pair has no probable edge any more the row is still
  written (the owner's word is kept).
- **`ClearPairWord`:** the row goes. After a `different` taken back, each of the two media that is plainly wanted
  (not in transfer, not set aside, not released, not marked by the owner's hand: the conditions of
  `coveredWantSQL`) is judged again by rung 6 as in 3 above, so it may be held again against the other file.
- Counts in `c_settings` beside the rung counts (keys `pairword.*`): words applied by kind, files released, files
  held against another, exact contradictions, pairs refused.

### 2.3 A held copy whose saved look-alike is lost (item 27)
A door `lostLookAlike(ctx, mediaID)` in `pairword.go` (or a file of its own), called for each media of the lost
file inside `WantAgain`'s transaction: every media with a `probable` edge to that media loses that edge (its
evidence was the saved bytes, which are gone); each of them that is held as a probable copy with no other probable
edge left is judged again as in 2.2 point 3 (wanted unless another saved file covers it). Counted
(`lookalike.lost_released`, `lookalike.lost_reheld`). **`internal/catalog/staging.go` is Core's file: the call is
one line in `WantAgain` and is asked of Core on the board; write the door and its tests calling it directly, add
the one line in a commit of its own, last, so that it can be dropped if Core says no.** `WantAgain`'s own cost
note must stay true (a file has a few media; the look-ups are seeks by `copy_edge`'s `b`: check that an index
serves it and say which).

### 2.4 The reader: a new package `internal/pairwords`
Reads the viewer's file and applies it through the door. No Telegram code, no viewer code imported (the table's
shape is written here again as constants, with a test that reads a file made by the viewer's own
`openDecisions` in an `_test` package if the import wall allows it, else a file made by the same SQL).
- `New(Config{Catalog, Path string, Clock, Logf, Every})` and `Run(ctx)`; `Path` is the decisions file. It opens
  it **read-only** (`mode=ro`, a busy timeout of 5 s, never `immutable`; it never creates the file or its
  journal's files: a missing file is "no words yet", looked for again at the next turn).
- A turn: `PRAGMA data_version` on its kept connection; unchanged since the last applied read and nothing
  waiting: nothing is read. Changed: the whole table is read (bounded: at most 100,000 rows; more is refused,
  counted and said in fixed words), each pair's two keys are found in the catalogue (`tg_media` by `kind` and
  `tg_id`: one seek each, in chunks of at most 500 pairs per catalogue transaction, with a gap between chunks as
  the catalogue's other chunked doors leave one), then the difference to `c_pair_word` is applied: new or changed
  words by `SetPairWord`, rows whose pair is no longer in the viewer's table by `ClearPairWord` (only rows this
  reader applied: every row of the table is the reader's in this piece).
- A pair with a file the catalogue lacks is kept aside in memory and counted ("absent"); while any is absent the
  catalogue is asked again for them every 10 minutes (at most 10,000 kept; more are dropped and counted).
- `Every`: 30 s by default between turns. A failure of the file or the catalogue: counted by kind, the next turn
  after `Every` doubling to 10 minutes; never a retry without a pause; the reader never ends the program.
- `Run` returns within 5 s of its context's end, also in the middle of a read or a chunk; called again after a
  panic it starts clean. `Stats()` with fixed JSON names and `Report()` lines (counts only).
- **Nothing starts it in this piece**: the collector's line (a flag naming the viewer's data folder, off when
  empty, a task beside the others) comes on a later small branch; write it down in the report as the earlier
  pieces did. It reads one small local file and the catalogue: it never touches the library or staging.

## 3. Tests (by name; invented data; the catalogue's and the viewer's existing rigs)

- The step: on a file at the step before, at the newest, and one relabelled; the table's shape; the plans of the
  new seeks.
- `TestPairDifferentReleases`: a video held by rung 6 against saved A; "different" on (it, A): the edge is gone,
  it is wanted (and marked for the exact check first when A's byte size is its own and another saved file of
  that size exists: one case each way); catalogued again or met at a save of A's twin, **it is not held against A
  again**; with a second saved look-alike B it is held against B with a new edge. Never skipped: assert its state
  after every step.
- `TestPairDifferentOtherStates`: the same word while the file is in transfer, set aside, saved, skipped, held
  as not collected, `keep_held`, released by the owner: the state is unchanged in each.
- `TestPairSameKeepsHeld`: "same": held as before, edge kept, never skipped; then a frame check's "no match"
  through `ProbeVerdict`: still held.
- `TestPairDifferentAndTheFrameCheck`: the saved file is no candidate for that file; a "copy" naming it is not
  written; another candidate still is.
- `TestPairDifferentAndExact`: an exact edge between the pair: the word is refused; a full exact match after a
  "different": the file is skipped by the exact check as today and the contradiction is counted.
- `TestPairClear`: after "different" taken back the wanted file is held again by rung 6; after "same" taken back
  nothing changes.
- `TestLostLookAlike` (2.3): the saved file lost: the held copy is wanted; with a second saved look-alike it is
  held against that one; a copy held with an exact-check mark; `WantAgain`'s existing tests you name still pass.
- The reader: a word given, changed, taken back in the viewer's file while the reader runs; an absent file that
  arrives later; a missing file; a file being written (WAL) by another connection; 600 pairs in chunks; a failing
  catalogue; `Run` ended in the middle; no file but the decisions file is opened and it is never written (assert
  on the folder's listing and times).
- For each rule above say in the report what the test fails on when the rule is broken on purpose (break it once,
  see it fail, restore).
- While working run only these and the catalogue's tests you touch, by name (`-run`, `-count=1`). **Not the whole
  `internal/catalog` (8 minutes), no `go vet` over packages, no race detector.** `gofmt -l` on your files and
  `go build ./...` at the end are yours. Before a test run look at the PC: with less than 2 GB of memory free or
  the CPU above 80% over a few seconds, wait a minute and look again, at most 10 times; then run with
  `GOMAXPROCS=2`.

## 4. Bounds (every wait here has one; a wait you add gets one and a line in the report)

| What | Bound |
|---|---|
| The reader's turn | every 30 s; after a failure doubling to 10 minutes |
| One read of the viewer's table | 100,000 rows, a busy timeout of 5 s |
| One catalogue transaction of the reader | 500 pairs |
| Absent pairs kept | 10,000; asked again every 10 minutes |
| `Run` after its context's end | 5 s |
| The door | one transaction; no loop over the queue, no pass over the library, no timer |

## 5. Hand-back
A report `archiver/docs/progress/copies-pairword-REPORT.md` and a `-PROGRESS.md` beside it kept as you go: what
was built per point; every file touched; test functions removed (none expected: "none" or the list); each named
test and what breaks it; the plans of the new reads; what the collector's line needs; what you could not verify;
every doubt, **above all about a rule of this brief that looks wrong to you** (say so plainly rather than build a
rule you think is wrong; if a rule would let a file be skipped or lost, do not build it and say why). Everything
committed and pushed on `wip/copies-19`; the copy clean. Your last message: the head's short hash, the tests run
with their seconds, the doubts in a few lines.
