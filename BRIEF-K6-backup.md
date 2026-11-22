# Brief K6: a checked backup of the catalogue and the session files, as a small program of its own (Core, 2026-11-15)

For one Opus coder. Listed: `FEATURES.md` section 4 ("Nightly backup of catalogue and sessions, N kept, each
checked, 'Back up now'; the secret key never copied with them": keep) and the roadmap's row "Nightly backup;
copy before an update" (C4, core, none built). You work in the copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-core-backup`, branch `wip/core-backup` (cut from the main head
2625aa0), Go module in `archiver/`.

This piece is **one checked copy on demand**. The nightly timer, its retries and a button on a page come
later, in the collector, and call the package you build.

## What the old app already knows (read by the Core session in its code, `wt-v12.31`)

`core-service/internal/app/ix_backup.go` (631 lines) and `internal/backup/snapshot.go`. Its way, which
worked for weeks on the old archive and is to be ported, not reinvented:
- **The database is never copied as a file.** A consistent snapshot is taken while the app runs
  (`VACUUM INTO` a new file, from a reading connection), into a folder on the LOCAL disk.
- **SQLite's integrity check runs on that local snapshot** (opened read-only and immutable), never on
  the share: "a network path is not something to trust its driver with". Then the snapshot is hashed
  again: it must still be the bytes that were checked.
- **The copy to the NAS is checked by size and SHA-256:** written, flushed, read back and compared;
  the source hashed again afterwards (a file rewritten while it was copied is copied again; 3 tries).
- **Session files are copied exactly as they are, still encrypted. The key that opens them is never
  copied** (its README says so, and what a restore needs).
- A copy is built in `<name>.partial` and renamed when whole; a manifest (sizes and SHA-256 of every
  file) and a README go in it; the newest 7 are kept (it was 4 until 12.13); only folders it made
  itself (named by date and time, holding a manifest) are ever removed, and a `.partial` left by an
  interrupted run is removed.
- The snapshot has a bound of 30 minutes. A failed night was tried again an hour later, 3 times a day
  (the timer: not this piece).
- **No number is on record for how long its backup took or how large it was**: yours prints its own.
- One thing the old app could not know: it refused a `\\server\share` path for the integrity check, but
  on this PC the NAS is a mapped drive letter, which that test does not see. Yours asks Windows what
  kind of drive the work folder is on (below).

The new app's files, for a catalogue at `<dir>\catalog.sqlite` (read by the Core session in
`internal/collector/collector.go` and `internal/catalog/catalog.go`): the catalogue is SQLite in WAL mode,
written by the running collector; readers open it with `mode=ro`. The session files are
`<dir>\sessions\account-<number>.session`, encrypted; **their key is a file outside the data folder
(`TRIED-BEFORE.md` 21, C6: "so that a copy of the data folder holds no usable session") and this tool
never learns where it is.** Other programs keep SQLite files of their own beside it (the viewer's marks).

## The shape: a separate small program, no existing file touched

Other branches are changing `internal/collector`, `internal/catalog` and `cmd/`. **You edit no existing
file.** New only:
- `archiver/internal/backup` (everything but the flags),
- `archiver/cmd/tgarchive-backup` (the program).

Imports: the standard library and the SQLite driver the module already requires (`modernc.org/sqlite`,
through `database/sql`). No `tgarchive/internal/...` package at all (not the catalogue: you open the
file yourself, read-only), no Telegram library, no `net`. A wall test in each of the two packages says
so (`internal/watchdog/wall_test.go` shows the form). No `go.mod` change, no schema step. The tool never
opens a network connection and never reads the library.

```
tgarchive-backup run   -db <catalogue> -to <backups folder> [-also <sqlite file>]... [-work <local folder>] [-keep N] [-reason manual|nightly]
tgarchive-backup list  -to <backups folder>
tgarchive-backup check -to <backups folder> [-name <copy>]
tgarchive-backup version
```

## What `run` does, in this order

1. **Refuses before it writes anything**, in fixed words, exit 2:
   - `-db` is not an existing regular file; `-to` is empty, is the top of a drive or share, is the
     catalogue's own folder or inside it, or holds the catalogue's folder;
   - `-work` (default: a folder `backup-work` beside the catalogue) is not on a local fixed disk. Ask
     Windows (`GetDriveTypeW` on the path's root through `syscall`; a UNC path is a network path
     without asking); elsewhere than Windows take any path that is not UNC. The check is a function
     value the tests replace;
   - `-keep` below 1 or above 365 (default 7); an `-also` path given twice or equal to `-db`.
2. **One run at a time:** a lock file in `-work`, held for the process's life
   (`internal/watchdog/lock*.go` shows the way on Windows and elsewhere: copy the few lines, do not
   import). A second run says so and exits 2.
3. **The catalogue's snapshot:** opened `mode=ro` with a busy timeout (the collector may be writing),
   `VACUUM INTO` a new file in `-work`, bounded by 30 minutes, the file flushed. Then SQLite's
   `PRAGMA integrity_check` on the snapshot opened `mode=ro&immutable=1`: exactly one line, "ok", or
   the run fails. Then size and SHA-256 of the snapshot, twice (it must not change after the check).
4. **The copy:** into `<to>\<name>.partial\catalog.sqlite`, where `<name>` is the local date and time
   `2006-01-02_150405`. Written, flushed, read back; size and SHA-256 equal to the snapshot's; else it
   is written again, 3 tries, then the run fails. A copy of that name already there: fail, nothing
   overwritten.
5. **The session files:** every regular file directly in `<catalogue's folder>\sessions`, byte for
   byte into `sessions\` of the copy, each checked the same way, and the source hashed again after the
   copy (a session the collector rewrote meanwhile is copied again; 3 tries). No folder is followed
   and no link. No `sessions` folder: said as a number (0 session files), not an error.
6. **`-also`:** each further SQLite file gets steps 3 and 4 into `also\<its base name>`. A file that
   does not exist is said and skipped; one that is not an SQLite database fails the run. (This is how
   "the key is never copied" is kept by construction: the tool copies SQLite snapshots and the files
   of one named folder, nothing else, and has no flag for a plain file.)
7. **`manifest.json`** (made, in UTC; the reason; the tool's build; every file with its path inside
   the copy, bytes and SHA-256; "integrity": "ok"; the fixed note that the sessions are encrypted and
   their key is not here) **and `README.txt`** (fixed words: what each file is, that the key is not in
   the copy, how to put a copy back: stop the app, put `catalog.sqlite` and `sessions` back, the key
   file must be where it was).
8. **Publish and rotate:** `.partial` renamed to `<name>`; then the newest `-keep` copies are kept and
   older ones removed. Only folders whose name is that date-and-time form AND that hold a
   `manifest.json` are ever removed; a `<name>.partial` of that form left by an earlier run is
   removed. Nothing else in `-to` is touched or listed.
9. The local snapshot is removed whether the run worked or not. A failed run leaves no `.partial`.
10. **What it prints: numbers and fixed words only.** Per step the seconds; the catalogue's bytes; the
    session files' count and bytes; MB a second of the copy to `-to`; copies kept; "ok" or the failed
    step in fixed words. Never a path, never an error's own text (it can hold a path: map errors to
    fixed words, as `internal/watchdog` `startWords` does); the copy's `<name>` (a date and time) may
    be printed. Exit 0 done, 1 failed, 2 refused.
11. **`backup-status.json` in `-work`**, rewritten by a temporary file and a rename at the end of
    every run: version 1, written-at, the reason, ok, the failed step's fixed word, bytes, the
    catalogue's bytes, session files, copies kept, the copy's name, last-ok-at and its bytes, seconds
    by step. For a page later. No path in it.

`list` prints the copies in `-to` that this tool made (name, bytes by the manifest, files), newest first.
`check` reads one copy (the newest without `-name`) and compares every file with its manifest: it reads
the share, so it runs only when asked; "ok" or the count of files that differ, exit 0 or 1.

## Not in this piece

The nightly timer and its 3 tries; "Back up now" on a page; a copy before an update; a "final" copy
(the old account does not move to this app); an off-site or encrypted destination; restoring by itself.

## Tests (named tests only; invented data in temporary folders; no Telegram, no network, no real archive)

Run only your two packages, with `GOGC=25 GOMAXPROCS=1 go test -p 1 ./internal/backup/ ./cmd/tgarchive-backup/`
after `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`. No whole-module run,
no `go vet ./...`, no race detector (the full runs are the main session's, once, after the review).
Judge no test on real seconds. At least:
- a snapshot of a WAL database taken while another connection writes to it: the copy opens, passes the
  integrity check and holds a consistent state (rows of one transaction all or none);
- the integrity check's failure fails the run (damage the snapshot through a hook between steps);
- a copy that reads back differently is written again and, three times wrong, fails the run with no
  `.partial` left (inject the writer);
- a session file rewritten during its copy is copied again; a folder and a link inside `sessions` are
  not followed;
- `-also` with a missing file (skipped, said), with a file that is no database (fails), with a real one;
- rotation: 9 copies and `-keep 7` leave the newest 7; a folder with another name, a date-named folder
  without a manifest, and a plain file in `-to` are untouched; an old `.partial` is removed;
- every refusal of step 1 (the drive-kind function replaced); a second run while the lock is held;
- the status file's content after a good and after a failed run; nothing printed holds the temporary
  folder's path (search the output for it);
- `check` on a good copy and on one with a changed byte; `list`;
- the two wall tests.

## How you work

- Measure the PC first (free memory; keep about 2 GB free; never pin the CPU; other sessions' coders
  and a running app share this PC). One go command at a time.
- Commit to `wip/core-backup` as you go (`git -c user.name=Claude -c user.email=noreply@anthropic.com
  commit`, ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`) and push it to the
  remote named `private` (`git push private wip/core-backup`). Never the main branch, never `origin`.
- `gofmt -l` on your files must print nothing before you hand back.
- Write `archiver/docs/progress/core-backup-REPORT.md` on the branch: what is built, each test and what
  it shows, what departs from this brief and why, what you doubt. Numbers and fixed words only.
- Hand back commit-ready: everything committed and pushed, the copy clean. Say the head's short hash.
- Stop and say so, instead of working around it, if anything here would need an existing file changed.
