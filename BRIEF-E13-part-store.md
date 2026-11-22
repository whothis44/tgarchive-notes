# Brief E13: the part store: parts a frame check fetched, kept on disk and reused by the download (copies track, 2026-11-15)

For one Opus coder, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-footage` on branch
`wip/copies-13` (made for you from the main branch's head d1af260; change no branch). Go module in `archiver/`.
Commit work in progress as you go (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`,
messages starting `WIP copies: `, ending with a blank line and `Co-Authored-By: Claude Opus 5.5
<noreply@anthropic.com>`, no number of any real archive) and push with `git push private wip/copies-13`; never
`origin`, never the main branch, never a force-push.

The design this is one piece of: `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-COPIES-frame-check.md` (read it
first; your piece is E13 in its table). **You build one new package, `archiver/internal/parts`, and touch no
other package.** The engine, the catalogue and the collector will be joined to it by later pieces.

## What the old app already knows (its numbers; read before the code)
Read `C:\Users\trabi\Claude\Projects\Telegram\wt-v12.32\core-service\internal\app\ix_part_store.go` (all) and
`...\internal\telegram\kept_parts.go` (all). Read-only: never edit or build anything in that folder.
- A frame check reads 8 parts of 1 MiB at the median (cap 32). Before parts were kept, 2.06 GB was fetched
  twice for 147 videos. Kept since 12.11: **at least 63 GB reused in 7,916 downloads; refused on reuse: 0
  wrong length, 0 wrong bytes, 0 unreadable.** Kept at one moment: 37,179 parts, 35 GB, of 3,986 files.
- Its rules, which you port: a part is written to a temp file and renamed, then its row (length, SHA-256,
  time) is written; **a part is read back only when its length and SHA-256 equal the row's**; anything
  doubtful is simply not used (the download asks Telegram as before); a failed write keeps nothing; rows are
  removed before files, "so that a download looking at the same time finds nothing rather than a part
  going"; a cap in all, and a floor of free disk space under which nothing is kept and the oldest go; a sweep
  that removes the parts of files that no longer need them and folders no row names; every use counted.
- Its history: a 4 GB cap was too small (12.12: 100 GB) because there a checked video was downloaded a day or
  two later; parts were lost on a timeout (12.25) and on an update's drain (12.27) because they were kept only
  when a check ended well. **Here every part is kept the moment it arrives.**
- What the old app did not have and you do not add: no check against Telegram's own part hashes; the SHA-256
  is ours, taken when the part is kept (it proves the disk did not change it).

## What to build: `internal/parts`
Parts are `PartSize` bytes (a constant 1 MiB = 1,048,576; the last part of a file shorter). A file is named by
the catalogue's number for it (an `int64`); the package knows nothing else about a file.

- **`Ledger`** (an interface; the catalogue will implement it later) and **`MemLedger`** (in memory, for tests
  and for this piece): the rows `(file, index, bytes, sha256, at)`: put one, list a file's, list every file
  with its part count, bytes and newest time, remove one part, remove a file's. Every method may fail; the
  store must behave when it does (below).
- **`Store`**, made by `Open(ctx, Config)`; `Config`: the folder (absolute; made if missing), the ledger, the
  cap in bytes (default 20 GiB), `Floor func() int64` (free bytes under which nothing is kept; default 60
  GiB), `Free func(dir string) (int64, bool)` (default: the real disk; look at how `internal/store`'s `FS.Free`
  reads it and do the same without importing more than you need), a clock, and hooks for write, rename, read
  and remove so tests can make each fail. `Open` reads the ledger once to build the in-memory set of files
  that have a part.
  - `Has(file) bool`: **in memory, no disk and no ledger call**, safe from any goroutine, for a file without
    parts one map read. The engine will call it for every part of every download.
  - `Indexes(file) []int64`: the kept indexes, sorted (in memory too).
  - `Put(ctx, file, index, data) error`: refuses an index below 0, empty data, data longer than `PartSize`;
    `ErrNoRoom` (counted) when the free space less the data would be under the floor, or free space cannot
    be read; an index already kept is left as it is (nil). Else: temp file in the file's folder, rename, then
    the row; a failure at any step removes what it wrote, keeps nothing, counts, returns the error. Layout:
    `<dir>/<two hex digits of file mod 256>/<file>/<index>`; temp `<index>.tmp`. After a put the cap is
    looked at: over it, the oldest files' parts go, never those of the file just written.
  - `Kept(file, index, want int) ([]byte, bool)`: the part's bytes when a row exists, `want` equals the row's
    length (the caller passes the length the part must have: `PartSize`, or the file's last part's), the
    file on disk has that length and its SHA-256 equals the row's. Anything else: false, counted by kind
    (missing, wrong length, wrong bytes), **and that part's row and file are removed** so it is never offered
    again. It never panics (recover: false, counted). Each success is counted (parts, bytes).
  - `Remove(ctx, file)`: the rows first, then the files and the folder; the in-memory set follows the rows.
  - `Sweep(ctx, needs func(ctx, files []int64) (map[int64]bool, error))`: removes the parts of every file
    `needs` does not name (the catalogue will say which files may still be probed or downloaded); if `needs`
    fails, nothing is removed for that reason. Then folders and files under the store's folder that no row
    names **and that are older than 10 minutes** (a part being written now must not be swept), then the
    oldest over the cap, then the oldest while the disk is under the floor (counted as "for space"). It
    stops at once when ctx ends. Nothing outside the store's folder is ever touched: resolve and check every
    path you remove; a folder entry that is not a plain number is left alone and counted.
  - `Source(file, size int64, mime string)`: a value with `Size() int64`, `Mime() string` and
    `Part(index int64) ([]byte, bool)` (`Kept` with the right length for that index), which satisfies
    `footage/ffmpeg.Source` and `footage/mp4index.Source` as they are (read both definitions; do not import
    either package in non-test code: a compile-time check in a test file is enough).
  - `Stats()` and `Stats.Report() []string`: parts and bytes kept, kept now (files, parts, bytes), refused
    for room, failed writes, refused on reading by kind, used (parts, bytes, files), removed (not needed,
    over the cap, for space). Numbers and fixed words only.
- Concurrency: `Put` for one file from one goroutine at a time but for many files at once, `Kept` and `Has`
  from many goroutines, `Sweep` and `Remove` at any time. One mutex for the bookkeeping, **no file read or
  write and no ledger call while holding it** where that can be avoided (say in the report where it could
  not). A reader that loses a race with a removal gets false, never wrong bytes and never a panic.
- After a crash (a part file with no row; a row with no file; a temp file left): the first is never read
  and is swept, the second is refused on reading and its row removed, the third is swept.

## Tests (named; invented bytes only; the whole small package may be run)
Each rule above has a test that fails when the rule is broken. Among them: a part with one byte changed on
disk, a short one, a longer one, a missing file, a row with no file, a file with no row; `want` different from
the row's length; a failing ledger at put (nothing kept, no file left), at read, at remove; a failing rename;
no room; free space unreadable; the cap never removing the file just written; the floor removing the oldest
first; a sweep that leaves a part written 1 minute ago with no row yet and removes one of 11 minutes;
`needs` failing; a store reopened on the same folder and ledger (`Has` and `Indexes` equal to before);
**a file put together from kept parts and "fetched" parts equals the original byte for byte** for random
part choices (the property the download will rely on); `Has` for a file without parts touches neither disk
nor ledger (the hooks count their calls); many goroutines putting, reading, removing and sweeping at once
for a few hundred operations with every returned part checked against its source (this test must also be
clean under the race detector, which the main session runs later: write it for that). The fake clock for
every age; no test judges real time.
Mutations you must show caught (revert, run, restore): the SHA-256 comparison; the length comparison; "rows
before files" in `Remove`; the 10-minute age in the sweep; the path check before a removal; "never the file
just written" at the cap.
Run: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then in `archiver/`:
`GOGC=25 GOMAXPROCS=2 go test -p 1 -count=1 ./internal/parts/`; also `gofmt -l internal/parts` and `go vet
./internal/parts/`. Nothing else (no other package, no race detector, no `go vet ./...`). The first go command
compiles everything once (the toolchain changed today): let it. Before each go command check memory
(`powershell -c "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB"`): under 2.5 GB free, wait a
minute and look again. If the repository has a test that lists the packages allowed to import each other
(look for `wall_test.go`), do not edit it: say in the report which line the new package needs.

## Rules (hard)
- This package never asks Telegram for anything and imports nothing of `internal/telegram`, `internal/engine`,
  `internal/catalog`, `internal/collector` or `internal/store`.
- A part is returned only when its length and SHA-256 match its row. There is no path, flag or setting that
  returns unverified bytes.
- Nothing outside the store's own folder is created, read or removed. Tests use `t.TempDir()`.
- Logs, counts and errors: numbers and fixed words; never a path, a name or a file's number in a log line or
  an error's text (an error may wrap the system's error for the caller, but `Report` and any log line may
  not carry it). Never open anything under `E:\` or any real catalogue.

## Hand-back
Commit-ready on `wip/copies-13`, pushed, the copy clean. A report `archiver/docs/progress/copies-parts-REPORT.md`:
the package's doors as built, each named test and what it proves, the mutations and whether each was caught,
the cost of `Has` and of one `Kept` (measured), every departure from this brief with its reason, and what you
doubt. Your final message to the main session: the head commit, then at most 20 lines.
