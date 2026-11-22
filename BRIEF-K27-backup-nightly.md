# Brief K27: the nightly backup runs by itself, and "Back up now" (Core, K-6, 2026-11-22)

**Why:** `tgarchive-backup.exe` ships in the owner's folder but nothing starts it (`AUDIT-INACTIVE-FEATURES.md`): the
owner's catalogue is never backed up. The backup itself is built and reviewed (`internal/backup`, `cmd/tgarchive-backup`:
`VACUUM INTO` a snapshot on the local disk, SQLite's integrity check there, the copy checked by size and SHA-256 on a
read-back, the session files still encrypted, the key never copied, the newest 7 of this catalogue's copies kept;
reviews `docs/review/core-backup-2026-11-15.md` and `-2-`). This piece makes it run. **The old app's way, ported:** a
nightly run at a set time; a failed night tried again an hour later, at most 3 tries a day; 7 kept.

**Rules:** you are the one Opus coder. Named tests and small packages only (the whole `internal/backup` is small: run
it); never the whole `internal/collector` or `internal/catalog`; every go command through
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go2.sh <folder> ...`. Invented data only; never touch a running
program, the main copy, `C:\Users\trabi\tgarchive-app`, `E:\` or the NAS. Copy `wt-core-backup2`, branch
`wip/core-backup-nightly` from **K22's final head** (`wip/core-alerts`, named when you start: it raises `backup.failed`,
a kind K22 reserved). Commit form as always; push only your branch.

## What to build
1. **Settings** (stored, with doors in the collector's form: read value, stored or default, unreadable; set with a
   check; fixed refusal words): the time of day (default 03:30 local); the destination folder (default: a `backups`
   folder in the app's data folder, beside the catalogue's folder; the owner may set another, e.g. a NAS share; refuse
   a folder inside the library, the old library root (K24, if merged; else leave a note) or the catalogue's own
   folder); kept copies (default 7, at least 1, no upper bound of the app's own); on or off (default on).
2. **The timer in the collector:** a task like the others (`c.supv.Go(...)` in `collector.go` `Run`) that, at the set
   time, runs ONE backup in-process through `internal/backup`'s own entry (no shelling out; if the package has no
   callable entry that writes to an `io.Writer`, add one there). On failure: again an hour later, at most 3 tries in
   the day; then raise `backup.failed` (the alert record's raise door) with fixed words; a later success ends it.
   One at a time (the package's own lock). A run never holds the catalogue's one writer (the snapshot is a read).
   Missed while the program was off: run once at the next start if the last good copy is older than a day.
3. **"Back up now":** a collector door `(*Collector).BackupNow(ctx) (started bool, err error)` (refused while one
   runs, in fixed words) and `(*Collector).BackupStatus(ctx) (BackupFacts, error)`: last good at, last try at, last
   failure as a fixed word, next run at, copies kept, destination set or default. **The button's place is U-1's**
   (the one-window app's page): list the exact names in your hand-back.
4. **Words and privacy:** log lines are constant formats with numbers only (no path). The backup's own words stay
   fixed.

## Tests (each seen failing first)
The timer fires at the set time on a fake clock; a failure retries an hour later and stops after 3 in a day, then
raises `backup.failed`; a later success ends it; "Back up now" while one runs is refused; a destination inside the
library or the catalogue's folder is refused; kept copies honoured; a start after a missed night runs once; off means
never. The whole `internal/backup`; the collector's new tests by name; gofmt, build, vet; the viewer's `TestWall`.

## Hand back
`archiver/docs/progress/core-backup-nightly-REPORT.md` and your last message, short: head pushed; the settings' keys
and the doors' exact names (for U-1); the tests as run; what you could not test (a real NAS destination).
