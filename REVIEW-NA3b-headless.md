# Review of NA3b (headless NAS): `wip/nas-headless` e83c4259, base a0de4f1

One independent review (Opus), 11-22. Code and tests only; no real data opened. Worktree of my own at e83c4259,
removed at the end.

**Verdict: may be listed.** Must 0, should 4, minor 6. No file can be lost, corrupted, skipped without exact
evidence or counted saved before it is on disk. The staging path (with `-staging`) is unchanged. The four shoulds
are real gaps that have workarounds. S1 and S2 are small and worth fixing before the first real headless run.

## What I ran
- `gofmt -l` (clean) and `go vet` on `internal/store`, `internal/collector` and `cmd/tgarchive-collector` (clean).
- `go test ./internal/collector -run 'TestNoStaging|TestNASDoorsRefuseTheOldArchive|TestCheckCommand|TestNASSwitchPlaces' -v`:
  all 6 PASS (the cut file resumed from its 3 MiB checkpoint; 14 staged files waiting, so the no-staging run was refused).
- `go test ./internal/store -run 'Copier|Straight|Writer'`: ok. `go test ./cmd/tgarchive-collector -run TestCommands`: ok.
- Not run: the race detector (the author still owes it, see "Concurrency").

## The binding rules, one by one

**(a) Final name only after the full write, the length check and fsync: holds.** The no-staging path makes no new
write code. It uses the writer's existing library mode: `place` returns `LocLibrary` when `StagingDir == ""`, and
`create` → `createLibrary` writes `.tga-<attempt>.part` beside its place. `fileWriter.Close(true)` checks
`written != size` (and removes the part), calls `Sync`, then `Close`, and only then calls `publishLibrary` →
`FS.Publish`, which is a no-replace rename (or link then remove). The Supply records the file only after `Close`
returns (`Finished`). A cut download keeps its part when a checkpoint is on record (`fw.kept`). The token is `L`,
and `partOf` resumes it under the library. `TestNoStagingCutResumes` shows this end to end. The directory is not
fsynced after the rename (M5); the check queue covers that case.

**(b) The read-back runs on the named file: holds, and the bad case is handled.** The trigger `file_queue_straight`
puts every unverified library row into `check`. `checkStraight` reads the file back. On `ErrCopyMismatch` it calls
`wantAgain`, which confirms with a second read-back after `MissingRecheck`. Then `setAside` renames the bad file
(it is never removed) and the media is wanted again. A missing file goes to `gone`, then `lookInLibrary`, then
`wantAgain`. So a bad file is counted saved but unverified only until its read-back. In that window:
- the exact check reads its bytes, so a corrupt copy cannot match Telegram's windows, and a missing one is
  `CheckUnknown`, which means held, not skipped;
- a later copy with the same SHA is kept, never removed (`Writer.Duplicate`).

But the read-back may be put off for up to `DeferMax` (24 h) by default: see S2.

**(c) The copier hands out no copies: holds.** `dueCopies` returns nil, the `waiting` probe is false, and
`copyStaged` returns `outStopped` if a copy ever reaches it. So `CopiesWaiting()` is false except in
`c.away && c.backlog`, the library-away case, where reading nothing is right. On the NAS the library is the local
disk, so letting the exact check read the library while copies wait does no harm.

**No new requests to Telegram, nothing done for the owner: holds.** `check` opens one file. The NAS doors only
refuse more often. The no-staging start sends nothing before its refusal: `TestNoStagingRefusedWhileStagedWait`
counts the requests. The `Hang` hold in `TestNASSwitchPlaces` exists only in the test.

**The staging path is unchanged: holds.** Every new branch in `copier.go` checks `StagingDir == ""`. With a staging
folder, `NewCopier` validates exactly as before. `newStaging` after its new early return is the same code. The only
other change is `release()` with a nil-lock guard. `nasdl` makes a copier only when `set.Staging != ""`, so the
relaxed `NewCopier` check does not reach it. The launcher still refuses an empty staging folder
(`launcher.missingFolders`) and always passes `-staging`. One change in behaviour is real: `run` without
`-staging` used to be refused and now switches mode (S3).

**The old archive is never signed in, read or downloaded with: holds.** `nasAccount` now reads the catalogue row
every time and returns `ErrNASOldArchive` for `BroughtIn`. Every door passes through it:
- `NASHeld`, `NASPlace`, `SetNASPlace` and `NASPair`;
- `NASStatus`, `NASForgetLogin` and `NASSignIn` with `status`/`cancel`, all via `nasCtlOf`;
- `NASSignIn`'s Telegram steps, directly;
- `NASGiveBack`.

The link manager's `turnLocked` and the alerts loop go only over running accounts (`c.accts`). A brought-in account
is never among them. `TestNASDoorsRefuseTheOldArchive` covers every door and every step. The pages do not show the
refusal's words (S4).

**Log lines: hold.** The new `c.logf` and `fmt.Fprintln` lines are constant strings with no paths, names or ids.
`check` prints only fixed words and numbers.

**Concurrency: no race found.** The `Kick` closure in `newLibraryOnly` reads `cp`, which is assigned before any
writer goroutine runs. It is never called in library mode anyway: only `publishStaged` calls `Kick`. Straight files
are picked up by `PollEvery`. `CopierConfig.StagingDir` is read-only after `NewCopier`. No goroutine is new. Doors
now call `ListAccounts` concurrently, which the catalogue already allows. The race run is still owed:
`collector -run TestNoStaging` and `store -run Copier`.

## Should

**S1. `ErrStagedWaiting` misses staged files whose library copy waits for its read-back.**
`newLibraryOnly` counts `file_queue WHERE state = 'copy'`. But `CopyCopied` (catalog/staging.go) turns the entry
into `state = 'check', part = <copy part>` and keeps `file.location = 'staging'` ("The bytes stay staged"). On the PC
these are common: a copy over the share whose read-back is put off to the speed-limited hours. A no-staging run then
starts, and `Copier.check` handles those rows:
- **if the read-back passes:** `finish` publishes the part, `CopyDone`, then
  `Remove(StagedName("", sha))`. That is a path relative to the process's working folder (`ab/<sha>`), not the
  staging folder. Practically this harms nothing: the real staged copy is orphaned and is removed by a later
  staging run's sweep. But it is a remove outside the app's folders.
- **if it fails:** the part is removed and `CopyBack` returns the row to `copy`. That row is then never handed out
  in this run, and the next start is refused.

Until then the viewer and the exact check see these files as staged and unreadable (`OpenSaved` →
`ErrSavedMissing` → `exact.ErrMissing` → held). No bytes are lost.

Fix: count `SELECT COUNT(*) FROM file WHERE location = 'staging'`, which covers every row whose bytes are in
staging, stuck ones included. Also make `finish` skip the local remove when `StagingDir == ""`: pass `local = ""`
from `check` in that case. Add a test with one row in `check` with a part.

**S2. With no staging the read-back is put off by default (up to `DeferMax`, 24 h).** `mayDefer` defers unless
`-read-back-now` is given or the hour is speed-limited, so a headless NAS run keeps every new file "saved,
unverified" for up to a day. The deferral exists to spare the share link. On the NAS the library is its own disk:
`nasdl` itself sets `ReadBackNow: true` for the same disk-to-disk case (nasdl/program.go). Fix: set `ReadBackNow`
when `Staging == ""`, or say in the run's start line and in the NAS compose that `-read-back-now` is wanted.
Workaround: pass `-read-back-now`.

**S3. A missing `-staging` now silently changes the mode, where it used to be refused.** Any start line in which the
staging value comes out empty (a hand-made line, a script variable that expands empty) now writes every download
straight into the library. On the PC that is the Wi-Fi share, with read-backs put off. The launcher is safe (it
refuses an empty staging folder), but the CLI is not. Fix: an explicit `-no-staging` switch, with `-staging` still
required otherwise (or refuse `-staging ""` given explicitly). The start line already says the mode, which is the
only guard today.

**S4. The pages do not know `ErrNASOldArchive`.** It is not in livepages `nasDoors.nasErr`'s map or in
server/nas.go `nasSentinels`. The pages therefore answer 500 "The NAS step could not be done: nothing more was
sent; try again." and log "a NAS route failed". The doc comment says these are "the pages' fixed words", but the
owner never sees them, and "try again" never helps. Fix: add an `OldArchive` field to the doors' errors, a server
sentinel with these words, and the mapping, plus a pages test of `GET /api/nas?account=<old>`. The refusal itself
already works.

## Minor

- **M1.** `check -max-age` defaults to 3m whatever the collector's interval, but `-counts-every` may be up to 1 h. A
  collector started with `-counts-every 5m` is then reported unhealthy all the time. The file carries `stale_after`
  (written_at + 2 × every_secs): use it when `-max-age` is not given, or say the limit in the help.
- **M2.** No test covers S1's case (a `check` row with a part at a no-staging start). There is [name removed]-staging test
  of a failed read-back either: the copier tests cover `checkStraight` already, but not through the new
  `StagingDir == ""` copier.
- **M3.** In library-only mode `fw.bypass` is false, so the store's hour lines count straight downloads as neither
  staged nor bypassed. The engine's counts still have them. A pages line may read 0 written files on the NAS.
- **M4.** `nasAccount` lost its fast path for running accounts. Every door call, and each alert snapshot per running
  account, now calls `ListAccounts` on `context.Background()` with a 10 s limit rather than the caller's `ctx`. A
  passing catalogue error now fails the doors of a running account too, so an alert reads "bad". Cheap, but use the
  caller's ctx.
- **M5.** `publishNoReplace` does not fsync the folder after the rename (this predates the change). After a power
  loss the row may name a file that is not there. The check queue handles it (`gone` → want again; the full part
  is swept after `OrphanAge`): no corruption, only a download again.
- **M6.** `SetNASPlace(old, pc)` is refused as well, so a NAS place stored for the old archive before this change
  cannot be cleared through the doors. It does no harm (the account never runs), but the comment could say so.
  `ErrNASOldArchive` is the only sentinel of this file without the `collector:` prefix. That is deliberate (the
  pages' words) and is consistent once S4 is fixed.
