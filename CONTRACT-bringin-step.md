# The launcher's bring-in step: the contracts it is built against (pages P7, 11-21)

## From the viewer (B9), 11-21 about 23:15: the bring-in program (`wip/b-unified`, in its fix round)
1. **Program:** `tgarchive-bringin.exe`, NOT built by `make-folder.sh` today: pages adds it (`./cmd/tgarchive-bringin`).
   - Dry run: `tgarchive-bringin plan -into-app -old <old app db> -new <the app's catalogue> [-account-label L]`
   - Real run: the same with `run`.
   - Afterwards: `tgarchive-bringin counts -into-app -new <catalogue>` (read-only: per account, in the old archive /
     probably / partly / new, and seen by the old app never saved; they add up).
   - Paths: the old app's database (read-only, immutable when no -wal beside it; never written) and the app's
     catalogue. The old LIBRARY is not a flag: resolving old files is Core's second root (a stored setting): the step
     sets it (Core names it) or asks for the folder with Windows' folder box. `-account-label` defaults to "Old archive".
2. **Output:** human lines, plus machine lines starting with `@ `:
   - `@ progress stage=<word> done=<n> total=<n>` at least every 2 s in a long stage (total 0 when unknown);
   - `@ count <key>=<n>` (fixed keys, listed in a doc comment);
   - the LAST line `@ result <word>`: done, refused, door-missing, would-change, busy, failed.
3. **Exit codes:** 0 done (plan: it would go through); 1 failed; 2 door-missing (Core's MarkBroughtIn or OwnerSpokeOn
   not in this build); 3 refused before any write (not a catalogue, a catalogue made in its other mode, a schema
   different from this build's, `catalog.chosen_only` not set, an app account with the old account's Telegram user,
   the bring-in's account number reused, the old db missing or not in the expected layout); 4 would-change (its guard
   stopped it: a message would change a file's state the app decided; plan: a count "would stop the run" above 0);
   5 busy (the catalogue held by another writer: the safety net only).
4. **Done:** the setting `bringin.app.v1.complete` = "1", read with the catalogue's GetSetting on a read-only handle;
   a run after it writes nothing, ends `@ result done`, exit 0. The launcher never offers the step when it is 1.
5. **The launcher checks before offering:** the app's collector and window stopped; the catalogue's schema equal to
   this build's; `catalog.chosen_only` set; the old db present; Core's doors in the build (a dry run answers 2 if not).
6. **Ctrl-C or a kill half way:** safe and resumable (small transactions, at most 2,048 rows, the writer held about
   150 ms); the next `run` carries on from its own record.

## From Core (K-6), 11-21 about 23:20
1. **The stop:** after the watchdog ends and the collector's lock (`<catalogue>.collector.lock`) is free, no Core
   program writes the catalogue (the backup runs on demand only; no nightly timer yet; the NAS helper never opens it).
   Add: (a) end every READ-ONLY opener too (the app's window/viewer, tgarchive-open, any pages server): a reader left
   open pins the WAL and the bring-in's big write cannot checkpoint; (b) the bring-in takes the collector's lock
   itself for its whole run (same file, same `lockFile`), so a collector started by mistake refuses with `ErrLocked`
   (Core asks for it to be exported for B9).
2. **The mark** (`MarkBroughtIn`, K24 `wip/core-oldroot`, with a coder) must be on the head AND installed before the
   step may be offered. Core adds a read-only door for the launcher: whether this catalogue's build supports the mark,
   and which accounts are marked. Exact names at K24's hand-back.
3. **The start after:** no flag. Schema steps not yet applied run at open: so never install a new build in the same
   step (install, start once, then the bring-in). The first start after a bring-in gets a longer bound for "the
   collector answers" and fixed words that a large catalogue is being opened (34 MB to about 2.9 GB; the start's own
   reads not timed at that size: measured on the trial copy).

## The step (the owner's decision, item 44, and DESIGN-UNIFIED-ARCHIVE.md §§5, 7, 8)
Offered once; the dry run's counts first; a yes that belongs to those counts; stop the app (collector, watchdog,
window); the bring-in with progress (about 15 minutes); the counts after; start the app again; never offered again
once done; fails closed on anything not as expected. The first try on a COPY of the owner's catalogue in a folder of
our own. The page's look is U-1's.

## Also for the same coder: U-1's door F2 (agreed by message, 11-21 about 23:35)
(a) When the collector cannot start (refused, no sign-in, crashed, the watchdog's give-up), the launcher still starts the ONE
joined window, viewer first (`-first viewer`), the launcher's page named as the second `-pages` address; the pages' address
left out while they do not answer. (b) `GET /api/state` on the launcher's own server (loopback, its guard):
`{"collector":"running|starting|not-running|stopping","why":"<fixed words>","since":<unix s>,"page":"/","action":"<fixed words or empty>"}`;
`Access-Control-Allow-Origin` = exactly the request's origin when it is one of the addresses the launcher started (the pages'
and the viewer's 127.0.0.1:PORT), no credentials, GET only, `Vary: Origin`; any other origin: no CORS header, refused as
today. The shell asks it every 15 s and on focus. Tell U-1 the head when listed.

## From the viewer (B9), the bring-in LISTED at `wip/b-unified` 152fc6bd: three details
1. `counts` names accounts by their place in the catalogue's order (`account.1`, `account.2`, ... by row id, the old
   account included), never by id; the old account's place carries `@ count account.N.old_app=1`; the fixed key list
   is the doc comment of `internal/bringin/intoexit.go`.
2. In `-into-app` mode no output line carries a path, name or id; errors print a fixed sentence or
   "bringin: failed (<error type>)".
3. `plan` exits 4 when its "would stop the run" count is above 0; with Core's K24 that count becomes 0 by itself;
   until K24, `plan` and `run` end with exit 2 (door-missing) before writing.

## From Core (K-6), the second root's writer
The writer is B9's bring-in `run`: it takes the old library folder as ONE flag argument (B9 names the flag) and
sets the setting through K24's catalogue door while it holds the collector's lock, in the same run. The launcher
passes the folder from `bringin-step.json` to that flag and writes nothing itself. B9 gets the door's, the setting's
and the "supports the mark" door's names at K24's hand-back.

## From the viewer (B9): the `state` command (with its coder on wip/b-unified)
`tgarchive-bringin state -into-app -new <catalogue> [-old <old db>]`: `@ count complete=0|1`, `@ count schema.same=0|1`,
`@ count chosen.only=0|1`, `@ count doors=0|1` (MarkBroughtIn, OwnerSpokeOn and the lock door in this build), with -old
also `@ count old.present=0|1`; then `@ result done`, exit 0; not a catalogue: `@ result refused`, exit 3; read-only, no
path or id printed. The old library flag's name: awaited.
- The old library flag: `-old-library <folder>` on BOTH `plan -into-app` and `run -into-app` (one argument, the owner's
  choice). `run` sets the root through K24's door under the collector's lock before writing; without the flag it is refused
  (exit 3) unless the root is already set; `plan` checks the folder is absolute and exists (exit 3 otherwise). Never printed.
- IN at `wip/b-unified` 98a051e3: the `state` command as above; `-old-library` REQUIRED by `run` every time (no getter
  of the root yet, so `state` has no `old.root` line); provisional Core door names until K24: `HoldCollectorLock`,
  `SetOldLibraryRoot`.

## From the viewer (B9), after Core's K24 (in review)
- The collector's lock file is the catalogue path AS SPELT plus `.collector.lock`: the launcher passes `-new <catalogue>`
  with EXACTLY the spelling it gives the collector's `-db`, or the bring-in's lock would not exclude a collector.
- On `wip/b-unified2` (listed after K24): `-old-library` is needed only when the root is not set yet; `state` gains
  `@ count old.root=0|1`.
- LISTED `wip/b-unified2` 16cc0f89 (replaces wip/b-unified; after K24): `doors=1` means SupportsBroughtIn and every door;
  new refusals (exit 3): the old account signed in (a session file or the collector's signed-in mark) or a file in
  transfer for it; the old library refused by the catalogue (not absolute, not a folder, overlapping the app's library);
  busy (exit 5) also when the collector's lock is held. With Core's mark the dry run's "would stop" is 0.
- Coming on `wip/b-unified2`: `plan -into-app` prints before the run, per app account (`account.N`) and in total,
  `@ count plan.total.media=`, `plan.total.in_exact=` (same Telegram file or same SHA-256 as a file the old archive saved),
  `plan.total.not_exact=` (they add up to media), and `plan.account.N.media/in_exact/not_exact`. "Probably" and "partly"
  exist only after the run (`counts`). Words: "N already in the old archive (exact); the rest are checked for
  look-alikes during the bring-in".
- From B9 after K24 (5ae0f34c): `run -into-app` takes an optional `-staging <folder>` (passed to Core's SetOldLibraryRoot so a root
  overlapping the staging folder or the library is refused, exit 3): the launcher passes the app's staging folder. The lock now
  finds the same catalogue under any spelling (libroot.Real): "the same spelling" relaxes to "the same file"; the one path builder stays.
- FINAL: `wip/b-unified2` d0a26560 (merges right after K24): the reference is the contract text in `internal/bringin/intoexit.go`.
