# Review E19: the owner's word on a probable pair (independent, Opus 5.5, 11-16)

**Head reviewed:** `4bb0ba2c` on `wip/copies-19`, against `dbca91d4`. I read the whole diff and the brief
(`BRIEF-E19-owner-verdicts.md`) first and the coder's report after. Read-only on `wt-copies-19`.

**Scratch copy:** `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-review19-scratch`, detached at `4bb0ba2c` (it was
moved to `dbca91d4` and `90343b99` for two measurements and put back). Not committed, left in place, holding three
untracked probe files:
- `archiver/internal/catalog/zz_probe_e19_test.go`: `TestProbeQ1ChatOffInTransfer`, `TestProbeQ1ChatOffLost`,
  `TestProbeQ1AltInTransfer`, `TestProbeQ1ControlSwitchOffWhileHeld`, `TestProbeQ2HoldExactKeepsProbable`,
  `TestProbeQ2TwinEdge`, `TestProbeQ4WriterTime`, `TestProbeQ4Chunk`, `TestProbeBatchPanic`. **Warning:
  `TestProbeBatchPanic` hangs by design (it shows the hang). Run it only with `-timeout`.**
- `archiver/internal/catalog/zz_probe_rate_test.go`: `TestProbeQ3Rate`, which also compiles on the base.
- `archiver/internal/pairwords/zz_probe_e19_test.go`: `TestProbeQ7Opens`, `TestProbeQ7KeptConnection`,
  `TestProbeQ7MissingTable`.

All data is invented. Nothing ran against Telegram, and no folder of the owner's was opened. Only named tests ran
(`-run`, `-count=1`, `GOMAXPROCS=2`), on a PC with 5.4 GB free and the CPU at 22-41%. Not run: the whole
`internal/catalog`, `go vet`, the race detector.

---

## Findings

### 1. HIGH (confirmed). A word, or a lost look-alike, makes a file wanted from a chat the owner switched off, or one carried only as an alternative version
`pairEdgeLost` takes "held and `probable = 1`" as proof that the file is collected, and `pairRejudge` then writes
`state = 'wanted'`. That proof does not hold. `Release` keeps `probable = 1` on a file whose chat was switched off
while it was in transfer (`releaseSQL`: `probable = 1` → held, reason and flag kept). The edit that makes a file an
alternative version (`roleChanged`) leaves a file in transfer alone, and so does `chatHoldSQL`. Such a file comes
back held with `probable = 1`. On the base it is held: tier 5, or never under `HeldWait`. After the word it is
wanted at its normal rank.
- `TestProbeQ1ChatOffInTransfer`. The trace: claimed → chat switched off (`SetChatCollectEffect(false)`) → `Release`
  gives `held/ptrue` → "different" gives `wanted/pfalse`. **Fails: CONFIRMED.**
- `TestProbeQ1ChatOffLost`: the same file through `WantAgain` of the saved look-alike (`lostLookAlike`) ends
  `wanted/pfalse`. **CONFIRMED.**
- `TestProbeQ1AltInTransfer`: the attachment is made an alternative version while in transfer → `Release` gives
  `held/ptrue` → the word gives `wanted`. **CONFIRMED.**
- Control `TestProbeQ1ControlSwitchOffWhileHeld`: a file held when the chat is switched off gets `probable = 0` from
  `chatHoldSQL`, and the word leaves it held. This passes.
- The same hole exists in `HoldLookAlike`'s new "ended" branch. It gives a file back `wanted` whether or not any
  carrier collects it. This one was traced, not probed.

The brief itself says "judged again ... as a new attachment would be at this moment", and a new attachment asks
`chatWants` and `!alt`. **Smallest fix:** where `pairRejudge` releases (and in `HoldLookAlike`'s ended branch), decide
as `wantAgainMedia` does, reusing its facts read:
- not carried as a message's own media → held, `ReasonAlternative`, not probable;
- not collected → held, `ReasonChatPref` or `ReasonTopicPref`, not probable;
- otherwise wanted.

Add a test per case: chat switched off, topic not chosen, alternative version, each in transfer when the change came.

### 2. MEDIUM (confirmed). A missing `verdict` table takes back every word
`read()` treats "no such table" as an empty table. `apply` then clears every catalogue word, and `pairTakenBack`
holds the files again.
- `TestProbeQ7MissingTable`: a word is applied and the file is wanted; `DROP TABLE verdict`; the next turn returns
  ok with no failure, the word is "" and the file is held again. **CONFIRMED.**

The same happens to a table that has been emptied (deviation 6), and to a decisions file replaced by a fresh one (a
reinstalled viewer, a reset data folder). Nothing is skipped, but every "not the same" the owner gave is undone without
the owner. **Smallest fix:**
- A file with no `verdict` table is `FailFile`.
- A read with 0 rows while the catalogue holds words is not applied. It is counted (`refused_empty`) and logged in fixed
  words.
- A test for each.

### 3. MEDIUM (confirmed, measured). The writer is held without a bound in `WantAgain` and in a 500-pair chunk
These were measured on a catalogue that is almost empty; on the owner's catalogue rung 6's read per file is dearer
(`TestLookAlikeCostAtScale`).
- `TestProbeQ4WriterTime`: `WantAgain` of a saved file with 10, 1,000 and 5,000 look-alikes held against it holds
  the writer **4 ms, 343 ms and 1.95 s** (about 0.39 ms per file, all in one transaction).
- `TestProbeQ4Chunk`:
  - one `SetPairWord` (a release): 2.5 ms;
  - one chunk of 500 "different": 168 ms;
  - one chunk of 500 taken back (each file judged again by rung 6): **478 ms**.

The old app held about 39,800 files against saved files, and one popular file can have hundreds or thousands.
`WantAgain`'s cost note ("a file has a few media") is no longer true. This bends the rule of `TRIED-BEFORE` 21.
**Smallest fix:**
- `lostLookAlike` inside `WantAgain` settles at most 200 look-alikes. The rest are left to a stored intent that a
  later turn applies in chunks (as the chat settle does), counted (`lookalike.lost_pending`).
- `ApplyPairWords` takes at most 100 ops when they can judge files again ("different" and take-backs).

### 4. MEDIUM (confirmed). The reader's kept connection blocks the viewer's file and leaves journal files in its folder; a replaced file is never noticed
- `TestProbeQ7KeptConnection` (Windows):
  - The reader's turn runs while the viewer is open.
  - The viewer then closes. Its `-wal` and `-shm` stay, because the reader's connection is still open.
  - Renaming another file over `decisions.sqlite` fails ("Access is denied"). Removing it fails ("being used by
    another process").
  - After the reader closes too, `decisions.sqlite-wal` and `-shm` are still in the viewer's folder.
- So in effect the reader does leave files in the viewer's folder, and it blocks a restore or delete of the viewer's
  file for as long as the collector runs. `data_version` is always read on the one kept connection. On a system that
  allows a replace, the stale handle would never be noticed: it is reopened only after an error.

**Smallest fix:** no kept connection.
- Each turn, stat the main file and `-wal` (size and modification time). Read only when that changed.
- When the journal files exist, open `mode=ro`, read and close in the same turn.
- When they are absent (the viewer is closed), read a private copy (finding 4b).

### 4b. Question 7's request: the smallest safe way to read a file the viewer has closed (probed)
`TestProbeQ7Opens`, a WAL-mode file with no journal files:
- **`mode=ro`** creates `-wal` and `-shm` in the viewer's folder. Deviation 1 is true.
- **`immutable=1`** reads and creates nothing. It is unsafe, though: it takes no lock, so a viewer that opens the
  file during the read could tear the read. A torn read that drops rows would take words back (finding 2).
- **`nolock=1`** fails ("unable to open database file").
- **A private copy** works: the bytes are copied with a plain read-only `os.Open` into the reader's own temporary
  folder and opened there. It reads 1 row; the viewer's folder lists only `decisions.sqlite`.

**Recommended:**
1. Stat the main file and its absent `-wal`/`-shm`.
2. Copy the main file to the reader's own folder.
3. Stat again. If the size or modification time changed, or a journal file appeared, discard the copy and retry at the
   next turn.
4. Open the copy and read it. A `PRAGMA quick_check` on a file this small is cheap.

This lets a word given just before the viewer closed be applied at once.

### 5. MEDIUM (confirmed; the defect is in `Batch`, Core's `catalog.go`). A panic inside a catalogue transaction hangs with the writer held
`TestProbeBatchPanic`: a panic inside `Batch`'s function never reaches a `recover`. `Batch`'s deferred
`wstmts.preparePending` calls `db.PrepareContext` on the writer, whose one connection the abandoned transaction still
holds. The goroutine blocks there for good. The timeout stack shows `preparePending` → `PrepareContext`.
- So the reader's "a turn that panics is counted and the reader goes on" is false for a panic inside
  `ApplyPairWords`: the catalogue's single writer stalls (every claim and finish), and the program does not crash.
- This was on the base already for every `Batch` caller.
- **Fix (Core):** in `Batch`, `recover` → `tx.Rollback()` → re-panic, ordered before `preparePending`. In the reader:
  do not swallow a panic from the catalogue. Also, after `safeTurn`'s `reset()` the pause never doubles across repeated
  panics (`fails` is set to 0, then 1): 30 s forever (low).
- For the board's Messages to Core.

### 6. MEDIUM (confirmed on a constructed state). `HoldExact`'s word branch makes wanted a file still held against another file and leaves `probable = 1`
`TestProbeQ2HoldExactKeepsProbable`:
1. x is held against A by rung 6, and has a second edge to C (the frame check's, made by `AddCopyEdge`). C is saved at
   x's size.
2. "different" on (x, C): left, held against another file still.
3. x is claimed in tier 5. `HoldExact` matches C at three places, and x becomes `wanted/ptrue`, edge to A kept.
4. A later claim and `Release` put it back `held/ptrue`.

A probable copy of A goes ahead at its normal rank, and the next stop of its transfer undoes that. **Fix:** in the
`released || differs` branch write `state = ` + `backToSQL` (held when `probable = 1`, else wanted). For a released
file `probable` is 0, so nothing changes there.

### 7. LOW-MEDIUM (confirmed on a constructed edge). The word removes edges only between the two media, not to a twin of the same bytes
`TestProbeQ2TwinEdge`: x has edges to A and to A2, saved with A's bytes. The A2 edge is the exact check's three-places
edge, which `matchOf` points at the lowest media id of the file. "different" on (x, A) leaves x **held against A2**:
the same bytes the owner just judged. This is inconsistent with rung 6, the step at a save, the frame check and the
exact check, which all apply the word by bytes. The owner has to judge the same bytes again. **Fix:** `pairEnded` also
removes the probable edges from each file to the media saved with the other's bytes (`tg_media_file`), both ways.

### 8. MEDIUM (plausible, not probed). The bring-in can hold a file again against a pair the owner said differs, for good
`bringin.go holdOne` guards `released` but not the word. A bring-in run after "different" holds the file again, and
its caller writes the edge back (deviation 6, gap 2). The reader never applies the word again: its row is already in
`c_pair_word`, so `have` equals `want`. The file stays held against that pair until the owner acts again, and the
viewer shows the pair as decided. **Fix:** `holdOne` passes over, and counts, a file with a "different" word whose
other file is the hold's target, as it does for `released`.

### 9. LOW (confirmed). Rules without a test
- **Break B2:** `lostLookAlike` deleting every edge to the lost media, exact ones included. `TestPair*` and
  `TestLostLookAlike` all pass. There is no test that an exact edge survives a loss.
- No test of finding 1's cases: a file not collected, a topic not chosen, an alternative version, each after the word.
- No test of a missing or emptied table (finding 2), and none of `WantAgain`'s writer time with many look-alikes.

### 10. LOW (traced). `applied_at` is `time.Now()` inside `SetPairWord`
The catalogue's other doors take a given time. **Fix:** a parameter, passed from the reader's `Clock`.

### 11. LOW (measured, "looks like"). Wasted reads at cataloguing
At `attach` the media is new, so no word can exist for it. Yet `lookAlikeVideo` and the stills rule pay the two
`pairDiffer` seeks whenever a candidate passes the rule. The stills rule now also reads all 16 rows, thumbnails
included, before deciding. **Fix:** skip the words' read when called from `attach` (pass a flag, or `ar` new).

### 12. LOW (a rule of the brief). "different" on a `keep_held` file only removes the edge
The bring-in's kept holds (and the owner's own Keep held) stay held. They are counted under "kept held", but nothing
the owner sees says the word did nothing. See question 13.

---

## Answers per question

**Q1.** No: see finding 1. "Held and probable" is not proof of being collected. Three paths make it false, all
confirmed:
- chat switched off in transfer → `Release`;
- an alternative version made by an edit in transfer → `Release`;
- by trace, the topic rule in transfer, because `noneCollectsSQL` ignores topics.

`chatHoldSQL` and `topicHoldSQL` take `probable` off only for files not in transfer (control probe passes).
`ClearPairWord` holds only plainly wanted, collected files (`coveredWantSQL`), so it is safe. `lostLookAlike` has the
same hole as `SetPairWord` (confirmed). `HoldLookAlike`'s ended branch gives back wanted without the check (traced).

**Q2.** I traced every `UPDATE c_want` and `DELETE` of the piece:
- `pairRejudge`: held → held or wanted, wanted → held or wanted.
- `pairEdgeLost`'s active/aside update: flags only.
- `HoldExact`/`HoldLookAlike`: wanted.
- `pairEnded` and `lostLookAlike`: `DELETE` of probable edges only.
- `ClearPairWord`: `DELETE` of the word's row.

No path writes `skipped` or `gone` and no `c_want` row is deleted. A full exact match after "different" still links and
counts (`TestPairDifferentAndExact`; break B1, where the word blocks `LinkSame`, makes it fail as it should).

There is no loop between the door and another rule. `wantedAsMainSQL` and `markCheckFirst` go by an edge, which is
gone. There are two ways in and out: finding 6 (wanted, then held again at the next `Release`) and finding 8 (the
bring-in). "Held for good with no edge": a `keep_held` file (by the brief's rule), or held against a twin (finding 7).
An active or aside file loses `probable` and comes back wanted. `Release` then applies the not-collected rule
correctly (deviation 2: sound).

**Q3.** With `c_pair_word` empty, rung 6, the stills rule, `holdCoveredBy`, `HoldLookAlike`, `HoldExact`, `LinkSame`,
`VideoCandidatesOf` and `ProbeVerdict`'s copy give the same result as the base: every new branch is guarded by a word
read that finds nothing. Probes and the coder's tests pass.

Cost per new attachment:
- a plain one: nothing new;
- one where rung 6 finds a candidate: two key seeks (`pairDiffer`), the same at 10,000 words (plans in
  `TestPairWordPlans`: no table walked);
- the stills rule reads up to 16 rows whole.

Measured with `TestProbeQ3Rate` (1,500 each, 3 rounds; first round, fresh catalogue):

| | held videos | plain videos | held stills |
|---|---|---|---|
| branch | 1645/s | 2076/s | 1737/s |
| base | 1750/s and 1861/s | 2110/s and 2216/s | 1835/s and 2033/s |

Later rounds overlap. It looks like a few per cent on the held paths, within this PC's noise (finding 11). No new read
runs on a read-only handle of an older file: `hasPairWords` guards `pairDiffer`, `PairWordOf` and `PairWords`, and
everything else runs on the writer.

**Q4.** See finding 3, from `TestProbeQ4WriterTime` and `TestProbeQ4Chunk`:

| What | Writer held |
|---|---|
| One `SetPairWord` | 2.5 ms |
| A chunk of 500 "different" | 168 ms |
| A chunk of 500 taken back | 478 ms |
| `WantAgain`, 10 look-alikes | 4 ms |
| `WantAgain`, 1,000 look-alikes | 343 ms |
| `WantAgain`, 5,000 look-alikes | 1.95 s |

Bounds needed: 200 look-alikes per `WantAgain` transaction with the rest as a stored intent, and 100 ops per chunk.

**Q5.**
- "different" → "same" → taken back, "same" → "different", the same word twice: traced and covered by `TestPairClear`
  and `TestPairDifferentReleases` (idempotent, `Changed` false).
- One file saved: the saved side is counted "saved or not queued".
- Both saved: refused if the same bytes, otherwise only the edges go.
- Both queued: the row only; later saves pass over by bytes.
- A-B different with A-C same: A stays held against C ("held against another file still").
- Edges both ways: both removed.
- Cascade: works (the step test), but nothing in product code deletes `tg_media` rows.
- Twin bytes: finding 7.
- `applied_at` is the wall clock: finding 10.

**Q6.** The step follows `schema_mirrorwant.go`:
- the two constants;
- refused at another version (tested);
- `IF NOT EXISTS`, so a relabelled file is right (tested);
- the three places in `catalog.go` (`SchemaVersion`, `steps`, `migrate`) are present.

`WITHOUT ROWID` and `CHECK` follow the house; no step uses `STRICT`. The index by `b` is used (plans). The foreign keys
cascade like `c_part`'s, and no product code deletes `tg_media`.

**Q7.**
- Deviation 1 is true (probed), but its remedy delays words: use the private copy (finding 4b).
- A missing table is taken as "no words" and every word is taken back: confirmed (finding 2).
- An emptied table does the same (by trace).
- `data_version` is read on the same kept connection. A replaced file is refused on Windows while the reader holds it,
  and is never noticed otherwise (finding 4).
- The cap of 100,000 is tested. Memory at that size was not measured; by estimate, three maps of 100,000 to 200,000
  entries make tens of MB, briefly.
- Absent pairs are asked again every 10 minutes. Pairs dropped over 10,000 come back only when the viewer's file
  changes (low).
- The pause doubles after failures, but not after panics (finding 5).
- `Run` ends at once in a wait. Inside a read it is bounded by the 5 s busy timeout (by trace).
- A panic inside the catalogue hangs instead of being counted (finding 5).
- It writes nothing, but it leaves `-wal`/`-shm` behind and blocks a rename or remove (finding 4).

**Q8.**
- The order is right: `wantAgainMedia` sets `file_id` to NULL and the file is marked lost before `lostLookAlike`, so
  rung 6 passes over the lost bytes.
- `WantAgain`'s own media with an edge to another saved file: held as a probable copy by `wantAgainMedia`;
  `lostLookAlike` removes only the edges *to* the lost media.
- A lost file revived by `Saved`: the released look-alikes are plainly wanted, so the step at its save
  (`holdCoveredBy`) holds them again (traced; not tested).
- With the last commit dropped (`90343b99`): `go build ./...` passes, and `TestLostLookAlike`, `TestPair*` and
  `TestWantAgain*` pass. The bound of finding 3 is needed before this line stays in.

**Q9.** With no word, `VideoCandidatesOf` *is* `VideoCandidates`, called with the same arguments
(`len(differ) == 0`), so it is the same list in the same order by construction. I did not probe it separately. With
words, `first` is a file id (`HeldOf` from `lookAlikeFileSQL`), so the filter is right. `internal/probejudge` run whole
with `FFMPEG_PATH` (the second line of `where.exe ffmpeg`): 37 PASS, 0 skipped, 36 s.

**Q10.**
- The errors carrying row numbers (`validPair`, `guardedBy`) go only into `PairOpResult.Err`, which the reader counts
  and never logs.
- The two `Logf` lines have constant formats: `%d` of `MaxRows` and a fixed failure word.
- `Report()` gives counts and fixed words.
- The counts' keys are constants.
- No path, name or id reaches a log.

**Q11.**
- Rung 6 only (not rung 4): it can only miss a hold, a download rung 4 might have held. Low; may stay.
- Bring-in not guarded: a stuck hold against the owner's word (finding 8). Should be closed.
- Rung 7 contradiction not counted: a count only. May stay.
- Emptied or missing table: undoes the owner's words (finding 2). The missing table must be closed before listing.

None of the four gaps skips or loses a file, and none downloads from a source not chosen. Finding 1 does, and it is
not among the listed gaps.

**Q12.** Three rules broken in the scratch copy:

| Break | Result |
|---|---|
| B1: the word blocks a full exact match in `LinkSame` | `TestPairDifferentAndExact` fails (`a full match: linked false, wanted`) |
| B2: `lostLookAlike` deletes exact edges too | **nothing fails** (finding 9) |
| B3: the reader never takes a word back | `TestReaderFollowsTheViewer` and `TestReaderChunks` fail |

Rules with no test: finding 1's not-collected and alternative cases, the missing table, the writer's time. The only
existing test file changed is `probejudge/fake_test.go`: the method was renamed and its asserts are unchanged.
**Test functions removed: none.**

**Q13.** Rules of the brief that are wrong or risky:
- **"Never `immutable`, `mode=ro`, never creates journal files"** cannot all hold for a closed WAL file. The private
  copy satisfies the intent (finding 4b).
- **"Every row of the table is the reader's; rows no longer in the viewer's table are taken back"** is unbounded. An
  absent or emptied table erases every word (finding 2).
- **"A `keep_held` file is left as it is"**: the owner's "not the same" on a kept hold (and on the bring-in's kept old
  holds, likely the most frequent case) does nothing visible. Either release it as for a probable copy (keep_held is
  the owner's own keep, and a later word is newer), or have the viewer say plainly that the hold is kept.
- **2.3's "a file has a few media"** sets no bound on the look-alikes held against a saved file (finding 3).
- **"Chunks of 500 pairs"** is too large when each op may judge two files again (finding 3).
- **2.2 point 3** names rung 6 alone. "As a new attachment would be" must include the collected and alternative
  checks (finding 1).
- `applied_at` has no stated source (finding 10).

**Judgement of the coder's deviations:**
1. True, but the answer should be the private copy (finding 4b).
2. Sound: the `Release` path is correct. `HoldLookAlike`'s ended branch needs finding 1's check.
3. Sound.
4. Sound: it avoids a hold without evidence.
5. Sound: 37/37 pass.
6. See Q11.

## What I did not look at
- The viewer's own code beyond the DSN line and the table text.
- Memory of the reader at 100,000 rows (estimated only).
- `TestLookAlikeCostAtScale`-sized catalogues for finding 3's times.
- The real bring-in sequence (finding 8 is traced only).
- A revived lost file's holds coming back (traced only).
- A race run.

**may be listed after these fixes: 1, 2, 3, 4, 6** (5 goes to Core on the board; 7 and 8 are strongly recommended
in the same round).
