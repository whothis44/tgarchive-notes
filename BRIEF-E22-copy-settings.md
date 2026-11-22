# Brief E22 (merge entry "C16"): the copy checks' switches as stored settings a page can set (copies, session C5, 11-16)

**For an Opus 5.5 coder at high effort. A small plumbing piece: it changes nothing a check does. You write code
and run only the named tests of what you changed; whole packages, vet over packages, the race detector and the
merge of the head are done once, later, by a clerk of the main session. Read only what section 1 names.**

- Copy: make it first, from the Bash tool, **from the main head named in your start message** (it must hold the
  commit "the collector's -pair-words starts the reader": check `git log --oneline -8` for it; if it is not
  there, stop and say so):
  `git -C /c/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add -b wip/copies-22 /c/Users/trabi/Claude/Projects/Telegram/wt-copies-22 <the head>`
  Work only in that copy. Go: `. /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then the
  copy's `archiver`.
- **Memory: one go command at a time, each with `GOMAXPROCS=2 GOMEMLIMIT=1GiB GOFLAGS=-p=1`; before each,
  `powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`
  must be at least 1.2; under it wait 2 minutes and look again (the owner lowered the bar for this track's coders
  on 11-16 14:33). Write the code first, then test: do not build after every edit.**
- Commit as you go: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; `git push private wip/copies-22` after each commit.
  Never another branch; never merge; never tag.
- Invented data only. Nothing runs against Telegram. No log line, test, comment or report carries a real name,
  text, path, id or link; new log calls have constant format strings and print counts and fixed words only.
- Nothing in product code depends on this PC's absolute paths, the start folder, PATH or the start scripts.
- A text with a Windows path is written with the Write or Edit tool, never through a shell string.
- `collector.go` and `command.go` are Core's files, lent again for this piece (the board's message from copies
  of 11-16 about 14:45): **the fewest lines there** (a block of unexported fields in `Config`; at most ONE call
  line in `Run` if no place in our own files runs early enough; nothing else). You touch no other Core file,
  nothing in `internal/store`, `internal/engine`, `internal/supply`, `internal/mirror` (read `autonew.go` as the
  pattern, edit nothing), the pages or the viewer. `internal/catalog`: nothing (the settings table and
  `GetSetting`, `SetSetting` exist).

## 0. What is there, and what the owner has said
- The fingerprint worker (`-fingerprints`) and the frame check (`-frame-check`) are merged (C12) and each is off
  unless its start flag is given. **Nothing in the app's own folder passes those flags**, so from the one program
  the owner opens, the copy checks cannot be switched on at all. The owner, 11-15: "we want a functional app,
  with a GUI"; 11-16, on the mirror's interval: "Can we make it a selectable option?"; and the board's rule that
  a listed function is usable from the pages before more depth is built behind it.
- The old app's numbers for the checks themselves are in `PLAN-C12-first-real-run-frame-check.md` (its table);
  **this piece changes no default and nothing a check does: both stay off until the owner switches them on, and
  every bound stays what the flags' defaults are today.** The first real run (the owner's item 37) has not
  happened; the page's words about a switch must not promise what has not been seen.
- The pattern exists, built and reviewed three times today: the mirror's stored switch and interval (M10):
  one key per setting in the catalogue's `c_settings`, a value that is exactly what its formatter writes or
  else "cannot be read" (never the default silently), a door on the collector that gives a page the facts
  (stored or default, unreadable, set by the run's flag), a start flag that means "for this run".

## 1. Read first (in the copy; no more than this)
- `internal/mirror/autonew.go` from `ListEveryKey` to `SetListEvery` (the key, the check, the formatter, the
  read with "stored" and "bad", the set), and how the same file treats the switch set by the run's flag
  (search `ByRun`): the shapes to follow.
- `internal/collector/mirror_door.go`: `MirrorListEveryFacts`, `MirrorListEvery`, `SetMirrorListEvery` and
  `doorDeps` (how a door reaches the catalogue while the collector runs and what it answers when it does not).
- `internal/collector/framecheck.go`: `addFrameCheckFlags`, `check`, `apply`, `ignored` (the flags, their
  defaults and bounds: these are the settings), `startFrameCheck`; `internal/collector/fingerprints.go`: where
  `Config.Fingerprints` is first read. In `collector.go` only: `Config`'s frame check block, and in `Run` the
  order from the catalogue's open to `startFrameCheck` (find where the fingerprint worker is made: you need the
  earliest place that runs after the catalogue is open and before anything reads those `Config` fields).
- `internal/catalog/settings.go`: `GetSetting`, `SetSetting` (the typed `Settings` blob is NOT used here).

## 2. What to build

### 2.1 A small pure package `internal/copyset` (ours; no goroutine, no Telegram, no collector import)
The copy checks' settings as rows, for every program that reads the catalogue (the collector now, the NAS
program later). Over an interface with `GetSetting` and `SetSetting` (as `mirror.Settings` is; do not import
`internal/mirror`).

| Key | Values | Nothing stored |
|---|---|---|
| `copies.fingerprints` | `on`, `off` | off |
| `copies.frame_check` | `on`, `off` | off |
| `copies.fingerprint_hwaccel` | `auto`, `cpu`, or one plain word (the flag's own check) | `auto` |
| `copies.check_hwaccel` | `cpu`, `auto`, or one plain word (the flag's own check) | `cpu` |
| `copies.check_workers` | 1 to 4 | the flag's default |
| `copies.parts_cap_gb` | 1 to 1024 | the flag's default |

- The defaults and bounds are NOT written a second time: take them from where the flags take them
  (`probejudge.DefaultWorkers`, `probejudge.MaxWorkers`, `parts.DefaultCap`, the two word checks), moving a
  check into this package and calling it from the flags if that is what it takes to have one place.
- For each key: a check, a formatter, `Read` (the value in force, `stored`, and a fixed error when the stored
  value is not exactly what the formatter writes for a value the check takes), `Set` (check first; nothing
  written on a refusal). Refusals are sentinel errors with fixed words fit for a page.
- **A stored value that cannot be read is never taken as its default silently.** For the two switches the value
  in force is then **off** (today's behaviour, and the side that cannot hold a file wrongly); for the four
  others the flag's default; each is said once at the start in fixed words and shown by the door as
  "unreadable".
- `-parts-dir`, `-ffmpeg` and `-card-decoders` stay flags only (folders and hardware lists are the launcher's
  settings file's); so does `-pair-words`.

### 2.2 The collector reads them at its start
- A flag given on the command line means **"for this run"** and wins (for the two switches also
  `-fingerprints=false`); a flag not given: the stored row; nothing stored: the default. Which flags were given
  is known in `apply` (the flag set's `Visit`, as `ignored` uses it): carry that in unexported `Config` fields.
- The rows are read once, after the catalogue is open and before anything reads the six `Config` fields, in a
  function of ours (a new file `internal/collector/copyset.go`); a read that fails (the catalogue's error, not
  a bad value) refuses nothing: the flags' values stand, said once in fixed words.
- One line at the start per switch that is on, saying where it came from (the run's flag, or the stored
  setting), in fixed words; the lines the head logs today stay as they are when no row is stored and no flag is
  given.
- **With no row stored and no flag given, a run is the main head's: kept by a test** (no line more, no read but
  the six `GetSetting`s, nothing made).
- `ignored()` (flags given while their group is off) counts against the value in force, not the flag alone.

### 2.3 The doors for a page (new file `internal/collector/copyset_door.go`)
- `CopyChecks(ctx) (CopyCheckFacts, error)`: for each of the six: the value stored (or that none is), whether
  it is unreadable, **the value in force in this run**, and whether this run's value came from a start flag
  (then a page's change takes effect only at a start without that flag: say so in a field, as the mirror's
  `ByRun` does). Catalogue only; while no run is up, what `doorDeps` answers.
- One setter per key (`SetCopyFingerprints(ctx, on bool) error`, `SetCopyFrameCheck`, `SetCopyCheckWorkers`,
  ...): check, store, nothing else. **A stored change takes effect at the collector's next start, not in the
  running one**: the facts show "stored" beside "in force", so a page can say "from the next start" truthfully
  and only while the two differ. Do not build a live switch in this piece; write in the report, from the code,
  what switching each of the two on and off in a running collector would need (the worker; the part store, the
  judge and the engines' part stores) in ten lines at most.
- No request to Telegram, no file made, nothing started by a door.

### 2.4 What is NOT in this piece
No page (the pages track builds the controls on Settings from the doors); no default changed; no live switch; no
setting for a folder or for ffmpeg's place; nothing in the typed `catalog.Settings` blob; no schema step.

## 3. Tests (every name starts with `TestCopySet`; invented data)
In `internal/copyset`: for each key, the check's bounds, the formatter and read round trip, a stored value that
is not the formatter's (a space, a capital, a number out of range, an empty string) is "unreadable" and never
the default silently, a set that is refused writes nothing.
In `internal/collector` (new file `copyset_test.go`; take C12's rig and its "off as today" test's way):
1. `TestCopySetOffIsToday`: no row, no flag: the run's lines, tasks and folders are the head's.
2. `TestCopySetStoredSwitchesOn`: a stored `on` for each switch, no flag: the worker (the frame check) runs,
   the start's line names the stored setting; a stored `off` with the flag given: on, "for this run"; a stored
   `on` with `-fingerprints=false`: off.
3. `TestCopySetUnreadableIsOff`: a bad stored value for each switch: off, said once, the door says unreadable;
   for the numbers and words: the default, said once.
4. `TestCopySetDoorFacts`: stored beside in force after a set in a running collector (they differ until the
   next start); the refusals' fixed words; a door while no run is up.
5. `TestCopySetFlagsOneSource`: the flags' defaults and bounds are the package's (change one constant in the
   package in the test's own copy of the expectation and the flag's help and refusal follow).
Say for each test what change in the code makes it fail (seen failing once, by hand).
Run while working: `go test ./internal/copyset -count=1`, `go test ./internal/collector -run 'TestCopySet|TestFlags|TestFrameCheckOff' -count=1`
(and C12's tests by name if you changed a helper they use), `go build ./...`, `gofmt -l` on your files. **Not**
the whole collector, not the race detector, not vet over packages.

## 4. Hand-back
A report `archiver/docs/progress/copies-copyset-REPORT.md`: what was built per point; every file touched, and
for `collector.go` and `command.go` the added and removed line counts and each place by name; **what a run with
no row and no flag does that the head's does not** (expected: six reads of the settings table; if anything
else, each thing by name); the doors' names and fields as built (the pages track builds from this section);
test functions removed (none expected); each test and what breaks it; the ten lines on a live switch; what you
could not verify; every doubt, above all about a rule of this brief that looks wrong to you. Everything
committed and pushed on `wip/copies-22`; the copy clean. Your last message: the head's short hash, the tests
run with their seconds, the doors in one line each, the doubts in a few lines.
