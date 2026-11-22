# Review E22: the copy checks' switches as stored settings (independent, Opus 5.5 high, one pass, 11-16)

Head read: `wip/copies-22` 536d656e, against 69a9c439 (`git diff 69a9c439 HEAD`). Read: both briefs, the whole
product difference (`internal/copyset/copyset.go`, `collector/copyset.go`, `collector/copyset_door.go`, the
changed lines of `framecheck.go`, `fingerprints.go`, `collector.go`), what it calls (`Run` from the catalogue's
open to `startFrameCheck`, `newFrameCheck`, `partsDirOf`, `claimPartsDir`, `openParts`, `newFingerprints`,
`doorDeps`, `vfp.ValidHWAccel`, `ffmpeg.ValidDecoder`, `parts.Open`), the collector's new tests, then the report.
Probes: scratch copy `wt-copies-review22-scratch` (detached at 536d656e), untracked
`archiver/internal/collector/zz_probe_e22_test.go`; nothing changed in `wt-copies-22`.

## Findings

### 1. HIGH: a stored "on" for the frame check refuses every start when its part store cannot be set up, and no door can undo it
- Lines: `collector/copyset.go` (`cfg.FrameCheck = all.FrameCheck.V` when the flag is not given);
  `collector.go` Run, `startFrameCheck` error -> `return err` (about lines 753-757); `framecheck.go`
  `startFrameCheck` 477-484 returns `newFrameCheck`'s error.
- What happens: `newFrameCheck` refuses (ErrPartsDir) on: the staging folder a drive's root with no `-parts-dir`
  (`errPartsRoot`); `<staging>-parts` overlapping by names or through a link/junction (`errPartsOverlap`);
  the folder not makeable (`errPartsMake`); carrying the staging mark (`errPartsStaging`); another catalogue's
  mark or an unreadable one (`errPartsOther`); not empty and unmarked (`errPartsNotEmpty`); the catalogue's id
  read failing in `claimPartsDir`; `parts.Open` failing four times (`errPartsOpen`, also a passing catalogue
  read error); `probejudge.New` (`errJudgeNew`). With the switch from a row, each of these makes `Run` return an
  error before anything starts, at every start, while the row stays. The collector serves the pages, the
  setters are doors of a running collector (`doorDeps` -> `ErrNotRunning`), and nothing in the app passes
  `-frame-check=false`: the owner has no way back from the app. The refusal's words tell the owner to give
  `-parts-dir`, a flag the app does not expose, and do not name the stored setting.
- Probe (shown): row "on" + a not-empty unmarked `<staging>-parts`: start 1 and start 2 both refused
  (`ErrPartsDir`, "nothing was started"); `CopyChecks` and `SetCopyFrameCheck(false)` after it: "collector: not
  running". Same with the flag (head's behaviour, which is right for a flag: the owner removes it).
- Not refusing (traced): a stored fingerprints "on" (`vfp.New` failing logs "off" and goes on); ffmpeg not found
  (both checks log a line and go on); a decoder word ffmpeg does not know (its self-test fails -> the CPU; never a
  refusal); workers (bounded 1..4 by the check; out of range unreadable -> default); a cap below what is kept
  (the sweep trims over the cap, as with the flag; no refusal).
- Smallest fix (the main session's proposal holds; one place, ours): in `startFrameCheck`, when `newFrameCheck`
  fails, `ctx.Err() == nil` and `!c.cfg.copySet.byRun(flagFrameCheck)`: log the part store's words as today plus
  one fixed line ("the frame check is on by the stored setting, but its part store cannot be set up: it is off
  for this run; the start goes on"), set `c.cfg.FrameCheck = false` and a new `copySet` field (say
  `frameCheckFailed`), `return nil, nil`. Both writes happen before the catalogue is published, so the doors'
  happens-before argument still holds. The door gives the field (e.g. `CopyCheckFacts.FrameCheckSetupFailed`) so
  a page does not say "from the next start" (Pending is true then: stored on, in force off). With the switch off
  for the run, `closeProbesAtStart` closes the checks an earlier run left open: that is today's "off"
  behaviour, acceptable. Nothing to release on the failure paths (`parts.Open` and `probejudge.New` start no
  goroutine). Keep the probe as a test (row: start goes on, door reachable, line once; flag: refused as today).

### 2. LOW: an unreadable row's line names the default "in use" when the run's flag gave the value
- Lines: `collector/copyset.go`, the loop logging `u.err` for every unreadable row, whatever `given`.
- Probe (shown): rows `copies.check_hwaccel`="CPU", `copies.check_workers`="9", flags `-check-hwaccel auto
  -check-workers 3`: in force "auto" and 3, the lines say "cpu is used until it is set anew" and "2 is used until
  it is set anew". Also said for a group that is off.
- Fix: log the unreadable line only when that setting's flag was not given (the door still shows Unreadable).

### 3. LOW: `Pending` compares words, not meanings
- `copyFact`: `Next != InForce`. A flag `-check-hwaccel ""` (the CPU, which the flag takes) against a stored or
  default "cpu" shows Pending true; same with "none". In a sign-in-only run `copySettingsAtStart` is not called
  (Run returns earlier) and the doors (`c.cat` is set by `signin.go`) show the flags' values as in force: harmless
  (no check runs there), but Pending can be true. Fix if wanted: normalise "" and "none" to "cpu" before the
  comparison; nothing else.

### 4. LOW: the report's "no other place in product code makes a `collector.Config`" is not exact
- `signin_cmd.go:152` (`New(Config{... SignInOnly: true})`), `mirror_cmd.go:449`, `command.go:788`,
  `approve_cmd.go:69` build collectors for other commands. None reaches `copySettingsAtStart` or starts either
  check (sign-in-only returns before; the others never call Run's start), so no run skips the rows silently.
  Only the report's sentence is wrong.

### 5. Not this piece (pre-existing, seen in the probe's lines)
- The part store's refusal is logged "collector: collector: the frame check's part store ..." (`startFrameCheck`
  logs `"collector: %s"` over an error that starts with "collector:"). Head's line; noted only.

## The questions
1. Answered in finding 1: yes, one way (the frame check's part store set-up, nine causes), each a refusal of every
   start; everything else from a row goes on.
2. Holds. No row, no flag: `apply` gives `copySet{flags: true, given: {}}`; `copySettingsAtStart` reads six rows
   (`ReadAll`), writes the six fields with values equal to the flags' defaults (`FingerprintDecoderDefault` =
   "auto", `FrameDecoderDefault` = "cpu", `WorkersDefault` = `probejudge.DefaultWorkers`, cap `20<<30`, both off),
   `ignoredOf({}, ...)` = 0 as head's `ignored()`, logs nothing; the call sits after `nextRun` and before
   `newStaging`, and nothing earlier reads the six fields (searched: only `fingerprints.go`, `framecheck.go`).
   Only flags, no row: the fields not given take the same defaults; the counts are head's; the only new lines are
   the "for this run" ones. A failed catalogue read adds one line (said in the report).
3. Holds. 61 malformed values through the start's read on a real catalogue (switches: "", "ON", "On", " on",
   "on ", "on\n", "1", "true", "yes", "on\x00", 5000 chars; decoders: "", "CUDA", " cuda", "cuda ", "-hwaccel",
   "cuda -i ...", a Windows path, "../x", "a/b", 33 letters, "cuda\n", a full-width letter, 5000 chars, "cpu\t";
   workers: "", "+2", "02", " 2", "2 ", "2.0", "0", "5", "-1", "0x2", a full-width digit, 20 nines, 5000 nines;
   cap: "", "+20", "020", "0", "1025", "20GB", "-0", "1e1", 20 nines): every one leaves the six fields at the
   default/off, one line each, the raw value never printed, no read failure. Through `Run` with the switches on
   by rows, a decoder row "cuda -i ..." and one holding a path: in force "auto" and "cpu", neither printed. A
   stored decoder reaches ffmpeg only after `^[a-z0-9_]{1,32}$` (the flag's same check): no option, no path.
4. Holds. The flags take exactly what they took (`FingerprintDecoderFlag` = `vfp.ValidHWAccel` = old
   `hwaccelWord`; `FrameDecoderFlag` = `ffmpeg.ValidDecoder`; 1..`MaxWorkers`; 1..1024); defaults, help and
   refusal numbers now come from the package and are the same values. The stored decoders refuse "" only (a page
   writes "cpu", the same decoder): nothing the flags take or refuse changed.
5. Holds but for findings 2 and 3. Facts traced for: nothing stored; stored = run; stored != run (Pending);
   unreadable (Next off/default, Value default); by the flag (ByRun); a Config by code (`flags` false: every
   ByRun true, nothing read). Setters check first, write nothing on a refusal, fixed sentinel words; doors start,
   make and send nothing; with no run `ErrNotRunning`. Races: the start writes `c.cfg` six fields, `flagsIgnored`
   and `copySet` in Run's goroutine before `c.mu.Lock(); c.cat, ... = ...` (collector.go about 818-819);
   `doorDeps` reads `c.cat` under `c.mu` and returns `ErrNotRunning` while it is nil; `given` is never written
   after `apply`; nothing writes those fields after publication (searched). The argument is right. The sign-in
   path publishes `c.cat` without the start's writes: no write, no race.
6. No product path that starts either check builds its Config without the run command's flags (finding 4).
7. No init function and no goroutine at import in `vfp`, `probejudge`, `parts`, `footage/ffmpeg`; their
   OS-specific files have fallbacks (`parts/sys_other.go`, `ffmpeg/hide_other.go`); the collector imports all four
   already. A NAS program would compile them in; it will need ffmpeg and vfp for the checks anyway. No smaller way
   worth the change.
8. Holds. New formats are constants; the unreadable lines are fixed sentinels through `"collector: %s"`; the read
   failure goes through `errWord`; a decoder word is printed only after the plain-word check (as head prints the
   flag's).

## Not looked at
The `internal/copyset` tests beyond their names; the collector's existing tests (none run but the probes); the
pages (no page uses the doors yet); a run as the owner starts it; the race detector (not run, by the rules).

## Probes run (scratch copy, `go test ./internal/collector -run TestZZProbe... -count=1`)
- `TestZZProbeStoredFrameCheckRefusesStart` (Q1): row and flag both refused twice (ErrPartsDir); doors
  ErrNotRunning after the refusal. Shows finding 1.
- `TestZZProbeMalformedRows` (Q3): 61 values, all unreadable -> default/off, one line, nothing raw. Pass.
- `TestZZProbeMalformedDecodersThroughRun` (Q3 through Run): "auto"/"cpu"/2 in force, option and path not printed.
  Pass.
- `TestZZProbeUnreadableWithFlagGiven` (own choice): shows finding 2.

may be listed after these fixes: 1
