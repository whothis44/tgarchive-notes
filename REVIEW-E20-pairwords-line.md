# Review E20: the collector's -pair-words line (independent, Opus 5.5 high, one pass, 11-16)

Head read: 4fde3acf (`wip/copies-20`) against bae71e5c: collector.go, command.go, framecheck.go, pairwordsline.go,
pairwords.go (two constants), and what they call: `internal/pairwords` Run/safeTurn/stampOf/readAndApply/
privateCopy/dsn, `catalog.Batch`, `catalog.ApplyPairWords`' use of it. The coder's report read last. Probes in the
scratch copy `wt-copies-review20-scratch` (untracked `zz_probe_*_test.go`, left there).

## Findings

**1. High (rule 2; fix: words, and one line for the owner). The viewer's folder is written, and in a race made
into, by the reader this piece starts; the help text, the flag's usage, the start line and the comments say
"never written to, made".**
- Every in-place read (the viewer open: `-wal` and `-shm` there) changes bytes of `decisions.sqlite-shm`: SQLite's
  read mark. The file and its `-wal` stay byte-identical. Probe 1b confirms the coder's finding. `readonly_shm=1`
  added to the DSN does not stop it on this build (probe 1b, second pass), so no one-parameter code fix exists.
- New, not in the coder's report: `turn` stamps the file (`-wal` and `-shm` there), then `readAndApply` opens it in
  place a few milliseconds later. If the viewer closes in that gap (its close removes `-wal` and `-shm`), the
  read-only connection opens a WAL-mode file that has no journal files. SQLite then **creates** `-wal` and `-shm`
  in the viewer's folder, and they **stay after the reader closes**: a read-only connection cannot checkpoint, so
  it never removes them. Probe 1a: before `[decisions.sqlite]`; during and after the read
  `[decisions.sqlite, -shm, -wal]`. That is the exact state the copy path exists to avoid. The window is a few
  milliseconds per read, and reads happen only when the file changed. It is rare, and no data is harmed: the
  viewer opens normally over them, and later turns read in place without creating more. It still breaks "never
  made".
- A related case with no write by the reader: if the viewer closes while the reader holds its read connection, the
  viewer cannot remove its own `-wal` and `-shm`, and the reader does not remove them either. They stay.
- Smallest honest fix (this piece's words, nowhere else): in the `-pair-words` help text, the flag usage, the start
  line, the `Config` comment and the header of pairwordsline.go, replace "never written to, made" with something
  like: "the decisions file and its journal are never written; while the viewer has the file open, SQLite's own
  lock file beside it (-shm) takes the reader's read mark, and if the viewer closes at the moment of a read SQLite
  may leave its two journal files there". Keep "never listed" (true: only three names are stat'ed). Fix the same
  claim in the package comment of `internal/pairwords` ("creates nothing in the viewer's folder"). A code fix
  that writes nothing at all would read only through private copies, the viewer's `-wal` included. That is a
  design change to the merged reader: it belongs on the board's "Waiting for the user" list as one line, not in
  this piece.

**2. Medium (rule 5): a panic inside `ApplyPairWords`' transaction leaves the catalogue's only write connection in
an open transaction until the store's context ends. This piece makes that reachable; on the head nothing starts
the reader.**
- What happens: `Catalog.Batch` (catalog.go:248) has no recover, so a panic skips `tx.Rollback`. The deferred
  `preparePending` runs while the panic unwinds; if a query is pending, it waits for the connection the open
  transaction holds, and `safeTurn` recovers only when the store's context ends. `safeTurn` then counts
  FailPanic, and the reader goes on and blocks at its next `BeginTx`. Every catalogue write of the run (the
  store's writer, the Supply's finishes, settle) waits behind the open transaction until the stop. At the stop,
  database/sql rolls the transaction back (it was begun on the reader's context, which is the store's context).
  The stop still completes: the engines' waits end on their own contexts, then the store's context ends.
- Probe 2 (catalog package): after a recovered panic in `Batch`, a second `Batch` fails with "context deadline
  exceeded" after 2 s; once the first context is cancelled, the next `Batch` succeeds.
- This needs a bug that panics. Fix: list this piece only on a head that holds Core's K16 (`Batch` rolls back on a
  panic), or record that dependency on the board so nobody turns `-pair-words` on before K16. No code change in
  this piece. No K16 commit is in the repository's log as of this review.

**3. Low (rule 2, merged code): the resolved folder check follows one link per side and does not chain them.** If
the viewer's folder is reached through a link to D:\x\sub and the staging folder is a junction to D:\x, under two
other names, neither direction sees the overlap. That is the same limit as the part store's check (its comment
says "one level"). The check by names and the folders as they are spelled still decide. Not probed.

**4. Low: the help text says the file is "read only when it changed".** It is also read once a take-back is due
(at most once a day). Optional wording.

**5. Low (process): `withinBound` keeps `partsDirResolved`'s goroutine pattern exactly (a buffered channel, so no
goroutine waits forever). The new concurrent code is the `pair-words` task on the store's context and the atomic
pointer read by the hourly line.** A race run over the whole collector package is not needed for this; a race run
of `-run TestPairWords` in `internal/collector` covers it, if the main session wants one.

## The three claims, my ranks
1. `-shm` changed: true, and the wording "never written to" is false. Also a creation race the coder did not
   find (finding 1). The fix is words; the code is SQLite's normal reader protocol, and `readonly_shm` does not
   help.
2. `foldersMeet`, traced:
   - With `holds` true nothing changed: `either` is the same symmetric test, and its swapped arguments
     (`either(dir, p)` for `either(p, dir)`) are equal under symmetry. The guard on the ancestors' SameFile check is
     unchanged when `holds` is true. `withinBound` returns `(false, false)` on a timeout exactly as before, and its
     channel stays buffered.
   - With `holds` false: in part 1, SameFile on dir's ancestors finds only "dir is o or inside o", and `either(p, o)`
     is `pathWithin(p, o)`. In part 2, the "o inside dir" check is skipped, and `either(dir, p)` is
     `pathWithin(dir, p)`. Both are right in each direction.
   - Probe 3 covers nine cases, links on either side: each gave the expected answer for both values of `holds`, and
     `foldersOverlap` gave the same as `holds` true.
3. `filepath.Abs` for the default work folder: right. A relative `-db` resolves against the start folder exactly as
   the catalogue itself is opened. The result is a full path (probe 4). A catalogue inside the viewer's folder
   gives the default's refusal. Nothing else depends on the start folder.

## Rules traced
- Rule 1, with `-pair-words` empty:
  - `pw.check()` returns "", so `cmp.Or` gives `ff.check()`'s answer, and `pw.apply` returns the config unchanged
    (it counts `-pair-words-work` only).
  - `startPairWords` stores nil and returns; `pairWordsTask` and `logPairWordsHour` return at once.
  - The ignored-flags line is unchanged when `pairWordsIgnored` is 0.
  - `ErrPairWords` in the exit switch and in `partsWord` can only be reached with the line on.
  - Nothing runs, is made or is logged. The coder's TestPairWordsOffIsToday passed.
- Rule 2: broken only as in finding 1.
  - The viewer's folder is never listed: three names are stat'ed, and the header is read through a plain read-only
    open.
  - The work folder is made only by `privateCopy`, lazily.
  - The checks for "the work folder is the viewer's, staging's, library's or part store's folder, inside one, or
    holds one" and "the viewer's folder is one of the others or inside one" are done by names, then resolved and
    bounded.
  - A kill leaves the copy only in the work folder, and the next Run removes it.
- Rule 3: a missing or unreadable table is a failure of the file (merged package). Nothing is applied, and the
  hourly line (`logStoreHour` → `logFrameCheckHour` → `logPairWordsHour`, unconditional) shows the failures.
- Rule 4: no rule added. The only catalogue writes are through the reader.
- Rule 5: the task is on `storeCtx` and `storeWG`. A stop ends it; a restart starts it clean (merged Run). The
  panic case is finding 2.
- Rule 6: the refusals and the start line are constant texts with no path; the reader's lines go through
  "collector: "+format, a constant prefix on constant formats.
- Rule 7: holds.

## Probes run (all in the scratch copy, named tests, -count=1, GOMAXPROCS=4)
- 1a `internal/pairwords` TestZZProbeInPlaceAfterViewerClosed: the in-place read after the viewer closed
  **created** `-wal` and `-shm`, and they stayed after the close.
- 1b `internal/pairwords` TestZZProbeInPlaceViewerOpen, with the viewer open:
  - without the parameter: the file unchanged, `-wal` unchanged, `-shm` changed;
  - with `readonly_shm=1`: the same result.
- 2 `internal/catalog` TestZZProbeBatchPanicLeavesTx: the writer was held 2 s (deadline exceeded) and freed
  once the context ended.
- 3 `internal/collector` TestZZProbeFoldersMeetDirections: 9 of 9 cases as expected for both values of `holds`;
  `foldersOverlap` equals `holds` true.
- 4 `internal/collector` TestZZProbeDirsOfDefault: a relative `-db` gives a full work path; a catalogue in the
  viewer's folder gives the default's refusal; the refusal texts hold no path.
- The coder's `-run TestPairWords` in `internal/collector`: ok (11 s).
- Free memory before each run: 2.0 to 2.2 GB.

## Not looked at
The test file in full; the supervisor's restart policy, beyond Run's own contract; the stop test's timing; a real
Windows junction (the stand-in only); the bounded look's timeout under a folder that is away; the help text as
printed.

may be listed after these fixes: 1, 2
