# Brief E3: a held copy waits for good unless the owner releases it (session C, 2026-11-14 night)

For one Opus coder, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-heldwait` (branch
`wip/copies-heldwait`, cut from `claude/charming-feynman-vm2xia` at 8c0335e). Go module in `archiver/`. Work
only in that copy. Hand back commit-ready; do not commit, push, merge or switch branches. Another coder
works in `wt-copies-lookalike` on `internal/catalog/ladder.go`, a new schema file and `bringin.go`: do not
edit those files, and add no schema step.

## Why
The owner, 11-14 22:46 (`archiver/docs/FEATURES.md` section 12, fourteenth round): "a held copy on a live
account (one with no deadline) waits for good unless the owner releases it; it is not downloaded 'last' by
itself". Every account of the new app is a live one (the old account stays on the old app). Today the
catalogue supplies held probable copies as tier 5, when a lane has nothing else (`internal/catalog/lane.go`
`supplyGuard` and `LaneNext`, `state.go` `claimable` and `heldGate`), so an idle lane downloads them.

The old app's numbers: 39,798 files (1,990 GB) were held against saved files on 11-13; of the look-alike
holds a frame check judged, 1,360 were confirmed copies and 675 were released. Downloading them "last" is
mostly wasted bytes; and a hold can be wrong, so the owner's release must keep working.

## Ported from
The old app's "hold for ever" setting: `C:\Users\trabi\Claude\Projects\Telegram\wt-v12.31\core-service\
internal\app\ix_held.go`, `ixHeldStep` (lines 204-259): with `HoldForever` on, the step returns before any
release (`ixReleaseSome` is never reached), and only a person's resume lets a held file go (`ixHeldRecheck`,
"Resumed by a person: theirs now"). Read it. The new app has no release step to switch off: the same effect
is that tier 5 is not supplied and not claimable. The old app's default was off (it had a deadline); the new
app's default is on, by the owner's decision above.

## What to build
1. A setting `held_wait` in the catalogue's `Settings` (`internal/catalog/settings.go`), default true: held
   probable copies are not supplied. False restores today's behaviour exactly (tier 5 last).
2. With it on: `LaneNext` returns no tier-5 file, and a claim of a held file is refused (`ClaimWith`,
   `ClaimNext`, `NextWanted` where they take held files). Choose the smallest change: an option carried in
   `LaneOptions` and `ClaimOptions` that `internal/supply` sets from the setting (read when the supply
   starts and again when settings are saved, in whatever way the supply already follows a setting such as
   the exact check's), not a setting read inside every lane walk. The c_supply rows and their triggers stay
   as they are: no schema step.
3. Unchanged, and tested as unchanged: the owner's release (`Transition` held to wanted) makes the file
   wanted at its own rank and it is supplied and claimed as any wanted file; `KeepHeld`; a probable copy
   whose transfer stops goes back to held (`backToSQL`); a held file is never skipped, forgotten or deleted
   by this; counts of held files in stats are the same.
4. A file already active when the setting turns on finishes as it would have.

## Tests (invented data only; named; in `internal/catalog` and `internal/supply`)
- `TestHeldWaitNotSupplied`: a lane with only held probable copies gets nothing and claims nothing, in
  both size classes; with the setting off it gets them last, exactly as the existing tier tests expect.
- `TestHeldWaitOwnerRelease`: a held copy released by the owner is supplied at its rank and claimed.
- `TestHeldWaitBackToHeld`: a released-then-stopped transfer, and a probable copy given back, end where
  they did before.
- `TestHeldWaitThroughSupply` (supply): with the engine's memory lane or the supply's own test harness, an
  idle lane with held copies downloads nothing; setting off: it downloads them.
- Existing tests that expect tier 5 to be supplied: they now set the setting off explicitly (list each in
  the report); do not delete or weaken them.
- Mutations, each shown failing a named test, then undone: the walk still returning tier 5; the claim
  still taking a held file; the release no longer supplied.

## Rules (hard)
- This is the lane's supply: beside the download path. Change nothing for tiers 1 to 4 or 6: no query of
  theirs, no order, no gate. If the smallest change needs more than the option and two conditions, stop and
  say so.
- Do not touch `internal/engine`, `internal/viewer`, `internal/bringin`, `internal/telegram`,
  `internal/collector`, `internal/server`, `cmd/`, `ladder.go`, `bringin.go`. If the collector must pass the
  setting for the build, stop and report the one line it needs instead of editing it.
- No new goroutine, timer or background pass.
- Privacy: invented data only; never read under `E:\T\` or `%LOCALAPPDATA%\tgarchive\`; the old app's code
  is read-only reference, never built or run.
- Load: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then
  `GOMAXPROCS=2 go test -p 1 ./internal/catalog -run '<names>'` (and `./internal/supply -run '<names>'`).
  Only named tests; never a whole package (the main session runs them once after the review); no race
  detector, no Docker, `go vet` only on the two packages once at the end. Another agent's tests may be
  running: leave them alone. If Go or its caches are missing, stop and say so.
- Nothing against Telegram; never start any program of the app.
- Keep `archiver/docs/progress/copies-heldwait-PROGRESS.md` up to date; at the end
  `archiver/docs/progress/copies-heldwait-REPORT.md`: what was built, each test and its mutation, every
  existing test changed and why, what was NOT verified, the changed files, a drafted commit message (no
  number of any real archive in it or in code comments).
