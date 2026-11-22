# Brief C36: the library pass reaches the old archive's videos through Core's resolver (C29's follow-up)

For ONE coder (Opus 5.5, high effort), start to finish. Written by the copies session C7, 2026-11-22. Small; no
review (reads only; it writes fingerprint rows, as C29 does).

## What stands
- C29 (merged) fingerprints library videos without a fingerprint while no copy waits. It joins app-library places
  under the library folder with its own guard (`libraryPath` in `internal/vfp/library.go`), skips every old-app place
  and counts it as "no root", and uses an unexported copy of K24's test (`oldPlaceSQL` in `internal/catalog/vfp.go`,
  with a comment naming `wip/core-oldroot`). Its walk is stored as `fingerprints.library_walk`.
- K24 is merged (head 9cb4edc): `internal/libroot` (`Resolve(appRoot, oldRoot, Place)`, `JoinUnder`, `ErrNoOldRoot`,
  `SettingKey = "library.old_root"`), and in `internal/catalog/schema_broughtin.go` `OldPlaceSQL(alias)`,
  `FilePlace(ctx, fileID)`, `OldLibraryRoot(ctx)`.

## Where and how (these bind)
- Copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-41`, branch `wip/copies-41` from 9cb4edc. Go commands only
  through `bash /c/Users/trabi/Claude/Projects/Telegram/runs-copies-c36/go1.sh <log> <go args...>`. Named tests and the
  whole of `internal/vfp`; NEVER the whole `internal/catalog` or `internal/collector`.
- Files: `internal/vfp/library.go` and its tests, `internal/catalog/vfp.go` (drop the copy, use `OldPlaceSQL`), the
  collector's `fingerprints.go` if it hands the old root, the C29 report (a short section). Commits as usual, push
  `wip/copies-41` to `private`. Invented data only. Never check out anything in the main `repo-archiver` tree.

## The change
1. `libraryPath` becomes one call of `libroot.Resolve` with the app's library folder and `OldLibraryRoot` (read at the
   pass's start and at each turn's gate check, cheap); `ErrNoOldRoot` counts "no root" as today; anything else Resolve
   refuses is counted "refused", never read.
2. `oldPlaceSQL` goes; the door uses `catalog.OldPlaceSQL`.
3. The walk is cleared (started again from the newest) when the old root is first seen set or changes, so the old
   archive's videos passed over as "no root" are walked: store the root the walk was made under beside it; numbers
   only in logs, never the path.
4. The gate is unchanged (no read while a copy waits; the hour's cap), and the old library is read only under it.

## Tests
An old-app place read under the old root; refused without one; a path leaving the old root refused; the walk cleared
once when the root is set, not again; the gate holds for old-library reads too; the library trees unchanged.

## Done
All of it, named runs and `internal/vfp` whole, gofmt and vet, committed and pushed. Hand back with the head. Stop at
the first thing not as written.
