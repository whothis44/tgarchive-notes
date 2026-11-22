# Review of E25 (merge entry C18): four small things in the frame check's start and hourly lines

Reviewer: Opus 5.5, high effort, independent; 11-16. Head read: **`wip/copies-25` fc5f9162**, against 5d884fc2
(`git diff 5d884fc2 fc5f9162`). Read: the brief, the difference, what it calls (`claimPartsDir`, `readPartsMark`,
`startFrameCheck`, `newFrameCheck`, `frameCheckOffForRun`, `ignoredOf`, `frameFlags.apply`, `logFrameCheckHour`,
`logStoreHour`, `writeOwnHours`, `writeCounts`, `countsTask`, `holdCounts`/`stopCounts`, Run's stop sequence in
`collector.go` 840-919, `catalog.ProbeStats`, `GetSetting`, `Open`/`dsn`, `schema_probe.go`), then the coder's report
last. Probes: scratch copy `wt-copies-review25-scratch` (detached at fc5f9162), untracked
`archiver/internal/catalog/zz_probe_e25_test.go` and `archiver/internal/collector/zz_probe_e25_test.go`; both left there.

## Probes run (invented data only, named tests, under the track's lock)
| Probe | Result |
|---|---|
| `TestZZProbeE25ProbeStatsCost` (catalog): plans of ProbeStats' statements; 1,000,000 c_probe rows + 100,000 c_part rows | plans: `SCAN c_probe` + `USE TEMP B-TREE FOR GROUP BY`; `SCAN c_part` + `USE TEMP B-TREE FOR count(DISTINCT)`; settings: `SEARCH c_settings USING PRIMARY KEY`. ProbeStats 1.72 s, 1.71 s, 1.65 s (three calls, warm). Three GetSetting reads: under the clock's resolution (0 s). ProbeStats with a 10 ms context: ended with an error after 12.5 ms (the context does interrupt the pass). |
| `TestZZProbeE25StopReadsWords` (collector): frame check on, start then stop, no hour passed | the new words line said **1** time (by the stop's own store report), 0 failed lines |
| `TestZZProbeE25RemoveWhileOpen` (collector): the mark's write fails while a second handle (as `readPartsMark` opens it) holds the mark open | write error answered; **mark left: true**; the next read refuses the folder (errPartsOther) |

## Answers

### 1. Point 1 (`writePartsMark`, framecheck.go 370-390)
- **Can it delete a mark it did not make? No.** The removal (384) is reached only after `os.OpenFile(path,
  O_CREATE|O_EXCL)` (372) succeeded; every open failure returns at 374 before any removal (a mark that existed before,
  another catalogue's mark, the mark of a concurrent start that created first: all `fs.ErrExist` or another open error).
  `path` is `dir/parts.mark` only: the staging folder's mark has another name (`markName`, checked in `claimPartsDir`
  424) and is never on this path. Between the create and the close the handle is open; Go on Windows opens without
  `FILE_SHARE_DELETE`, so nobody can delete or rename the name meanwhile. Between `Close` (380) and `Remove` (384) the
  name could refer to another file only if someone deleted ours and created a new one in that gap: no code of the
  program deletes a mark but this line for its own, and a concurrent start's exclusive create fails (`ErrExist`) while
  ours exists. Only a hand outside the program could do it: inherent to removal by name, not worth more.
- **Folder after a failed write:** as before the call: the mark removed (the folder itself was made by `MkdirAll` in
  `newFrameCheck` 548, as on the head; it stays, empty). The start answers `errPartsMake` (452). **A later start with
  the cause gone** finds no mark and an empty folder and marks it: the coder's test shows it through `Run`
  (`TestPartsMarkFailedWriteLeavesNothing`, second half).
- **If the removal fails:** the short mark stays and every later start is refused with errPartsOther, as on the head,
  and silently. On Windows this happens whenever another handle holds the mark open at that moment (my probe: mark
  left) — a second program's `readPartsMark` in the same instant, a scanner. Finding 2 (low).
- A concurrent second program on the same folder: while our short mark exists it is refused (errPartsOther), as on the
  head; after our removal its own create succeeds. Nothing worse than the head.

### 2. Point 3 (`logFrameCheckWords`, framecheck.go 784-811)
- **Which goroutine.** `logFrameCheckHour` is called only from `logStoreHour` (staging.go 437-443), which runs:
  (a) in the **counts task's goroutine** (`countsTask` → `writeCounts` → `writeOwnHours` → `logStoreHour` per hour
  that ended, at most 2 at once after a sleep: owncounts.go 96-115); (b) on **Run's own goroutine at every stop**:
  `stopCounts` (account.go 1130-1138) calls `writeOwnHours` (an hour that ended: one more report) and then
  `logStoreHour` directly; Run calls it at collector.go 899 with `context.Background()`, **before** `stopStore()` (901),
  `shutParts` (908) and `closeStore()` (915). So the read is not "once an hour" only: it also runs at every stop (probe:
  1 line at a start and stop with no hour passed), up to three times at a stop that ends hours.
- **Can it delay the stop?** Yes, bounded: each read has its own `context.WithTimeout(context.Background(), 10 s)`.
  The stop's own reads (b) run on Run's goroutine: up to 10 s each (up to 3 reads: 30 s worst case). A tick's read (a)
  does not see the stop: `stopTasks()` (876) cancels the tick's ctx, but the read's context comes from Background, and
  `writeCounts` checks `stopNow()` only between its steps. `holdCounts` waits for that tick at most `lastTickGrace`
  = 15 s, whose comment says it is "longer than one write's own bound (10 s)": a tick in `writeOwnHours` with two
  ended hours can now take 2 × 10 s of reads plus its own bounded writes, so the 15 s can run out: then the stop logs
  "a counts tick still writes ... the stop writes no counts of its own", skips `writeTgHours` and `stopCounts`, and the
  tick goes on writing. Bounded, not unbounded; normally the read takes far less than 10 s (1.7 s on a million rows).
- **The writer:** not held. `ProbeStats` and `GetSetting` use `c.r`, the reader pool (`SetMaxOpenConns(8)`, read-only
  DSN, catalog.go 143-154), not the one writer connection (`c.w`, 136). The catalogue is WAL (`dsn` 199), so a reader
  does not block the writer; a 1.7 s read only keeps the checkpoint from passing its snapshot for that time.
- **After the catalogue is closed:** only the tick that outlived `holdCounts` can get there (`closeStore` at 915); a
  closed `*sql.DB` answers at once with an error, the line "they could not be read this hour" is said, nothing
  crashes (the coder's test does exactly that after `r.stop()`).
- **Cost:** `ProbeStats` is three statements on the reader pool: a full `SCAN c_probe` with a temp B-tree for the
  GROUP BY (no index serves `phase, result, why`: c_probe's two indexes are partial, schema_probe.go 68-69), two
  primary-key lookups in `c_settings`, and a full `SCAN c_part` with a temp B-tree for `COUNT(DISTINCT)`. Measured:
  **1.7 s per call on 1,000,000 c_probe rows + 100,000 c_part rows**; the two settings reads alone: under the clock's
  resolution. The line prints only the two settings: the two scans are spent for nothing. Finding 1.
- **The main session's plan, "bind the read to the store's context so a stop ends it": not enough.** The store's
  context (`storeCtx`, collector.go 840) is cancelled by `stopStore()` at 901, **after** `holdCounts` (885) has
  waited for the tick and **after** `stopCounts` (899) has made the stop's own reads. Bound to it, neither the tick's
  read during the hold nor the stop's reads would end any earlier. What is needed: read only the two settings rows
  (milliseconds, finding 1's fix), which makes the bound moot; keep a bound (10 s or the Settle's 2 s). If the read
  should also end at the stop, the only context that is cancelled early is the tasks' one (`stopTasks`, 876), which
  `logStoreHour` has (its `ctx`) but does not pass to `logFrameCheckHour` (staging.go is Core's); within our files the
  equal check is `if c.counts.stopNow() { return }` before the read (the stop's own report then has no words line;
  the hourly ones keep it).

### 3. Points 2 and 4, and every other line
- **Frame check OFF:** `startFrameCheck` 475-487 are the head's lines and return at 486 before anything new;
  `frameCheckOffForRun` is not reached; `writePartsMark` is not reached; `logFrameCheckHour` returns at 767-768
  before 784. **No line changes.**
- **Frame check ON, set up without trouble:** the start's lines are the head's (the success path of
  `writePartsMark` answers nil, the "marked as this catalogue's" line at 447 unchanged; `newFrameCheck` only adds the
  `cat` field; `frameCheckOffForRun` not called; the refusal line at 497 not reached). **The hourly report gains the one
  new line** after the lanes' line — and so does the **stop's** report (it is the same `logStoreHour`; probe: 1 line).
  Within the piece's rule, but the coder's report says "once an hour" and never names the stop.
- **Point 2:** only the line at 497 changes: `strings.TrimPrefix(partsWord(err), "collector: ")` — the error's words
  and `partsWord` unchanged; every `ErrPartsDir` word begins with "collector: " (framecheck.go 66-81), so the line now
  says it once; an `errWord` text without the prefix is unchanged. Refusals only, not a normal start.
- **Point 4:** the new code runs only inside `frameCheckOffForRun` after its `byRun` check (153), i.e. only when a
  stored "on" failed to set up; it says a line only when the count moved (162). `cfg.flagsIgnored` is read nowhere
  after the start's first line (grep: collector.go 344 declaration, copyset.go, framecheck.go), so the new value
  changes nothing else. Note (not a finding): when owner's-words flags were also ignored (`pw > 0`), the first line
  said `n+pw` of "the fingerprints, the frame check or the owner's words", the second says `n` of "the fingerprints or
  the frame check": both true in their words.
- **The changed assertion** (`TestCopySetStoredOnNeverRefusesAStart`, copyset_test.go 609): head: exactly 2 of
  `"collector: " + words`. Now: exactly 2 of `words` and no `"collector: collector:"` anywhere. The words begin with
  "collector: ", so each counted occurrence is "collector: <words>"; any other line carrying the words (an exit line)
  would raise the count above 2 and fail. **At least as strict** (stricter: the doubled prefix is refused anywhere).

### 4. Privacy
New or changed lines: `copyLineIgnoredAfterSetUpFailed` (one `%d`), `frameCheckWordsLine` (two `%d`),
`frameCheckWordsFailed` (constant, no argument, never the error), the refusal line (`"collector: %s"` with
`partsWord`'s fixed words, as on the head). All constant formats, counts and fixed words; no path, name, id or raw
error. Tests use invented values and a `TempDir`.

### 5. Fates and files
Nothing in the difference decides what is held, wanted or skipped. Files: `internal/collector/framecheck.go`,
`copyset.go`, `framecheck_test.go`, `copyset_test.go`, and the report under `docs/progress`. Nothing else.

## Findings
1. **Medium.** The words line pays for `catalog.ProbeStats` (two full scans with temp B-trees: 1.7 s on a million
   check rows) to print two settings rows, and that read runs not only once an hour on the counts task but at **every
   stop on Run's goroutine** before the store stops, each bounded only by its own 10 s from Background; a tick with two
   ended hours can now outlast `holdCounts`' 15 s and cost the stop its own counts. No writer is held; nothing is
   unbounded. **Smallest fix:** read just the two rows — `fc.cat.GetSetting(ctx, "probe_late_verdicts")` and
   `fc.cat.GetSetting(ctx, "probe_settled_row_words")` (parse as ProbeStats does; a failed read: the fixed line) —
   with a test that writes both rows and checks the line against `ProbeStats`' `Late`/`SettledWords` (pins the
   duplicated keys); keep a bound (2 s is enough). Correct the report's "once an hour" (also at each stop). Binding
   to the store's context is not needed after this and would not have helped (see 2).
2. **Low.** When the removal fails (on Windows: whenever another handle holds the mark open, as my probe shows) the
   short mark stays, silently, and every later start is refused with "belongs to another catalogue, or its mark cannot
   be read" — the head's behaviour, as the comment says. **Smallest fix (optional):** try the removal again once or
   twice after a short pause, and if it still fails say one fixed line ("the part store's mark could not be written
   whole nor removed: remove it by hand").

## Not looked at
The whole collector package and other tests that count a stop's lines with the frame check on (the stop's report now
has one more line: the clerk's full run before the merge will show any test that counts them exactly); the race
detector; `pairwordsline.go` (known); the judge's and part store's `Stats` after the stop; Linux/NAS behaviour of the
removal.

may be listed after these fixes: 1
