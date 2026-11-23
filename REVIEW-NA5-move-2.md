# Review NA5, second pass (fix round 50bd1206..1d2675fb on wip/nas-move), Opus, 2026-11-22

Read: REVIEW-NA5-move.md, BRIEF-NA5-move.md, the diff (nasmove, cmd/tgarchive-nasmove, collector lock/words/command/
moved_test, bringin run/fixes_test, backup run, deploy/nas-app, deploy/nasdl), and the whole current files of
`internal/nasmove` (nasmove.go, layout.go, locks.go, catdb.go, bundle.go, out.go, in.go, mark/mark.go, both test files),
plus the parts of backup (CatalogID, Within, copySessions, copyAlso), collector (backupnight defaults, stagingmark,
moved.go, signin) and telegram (SessionStore.LoadSession: reads only) that the fixes lean on. Nothing in the tree edited.
The package's own tests pass (`./internal/nasmove/...`, exit 0). Probes: `probe2_test.go` in my own temp folder
mapped in with `-overlay`, run through `runs-nas-n1/go1.sh ... -run TestProbe`: Q1 to Q4 all show the outcome below
(exit 1, as intended). Invented data only.

## Findings 1 to 13 of the first review: fixed?
1. Fixed for the flows the README uses: `in`/`back` consume (in.go:419-434, bundle.go:379-389), `in` refuses a bundle
   made on its `-layout` (in.go:83), README deletes both copies right after `in`. Tested with a carried copy. Residual
   in the accepted class: see Q2.
2. Fixed: the chain `nasmove.placed_from` -> manifest `came_from` -> `back` requires `CameFrom == m.Bundle`
   (in.go:261); a consumed or elsewhere-placed bundle is refused (in.go:273-282). Two round trips tested.
3. Fixed: `apart` both directions (out.go:136-143), a folder is emptied only with out's own progress mark for this
   archive (out.go:608-655), failures after the first write say "run again", never "Nothing was changed". Residual: Q1a.
4. Fixed: `in` removes the old-library and `backup.to` settings unless `-old-library-root` is given (in.go:162-178);
   `back` puts both back from the mark (in.go:338-347).
5. Partly fixed: see Q1b.
6. Fixed: every bundle session opened with the bundle's key before the mark, at `-finish`, and before `in`/`back`
   place (bundle.go:394-406). LoadSession only reads (no rewrite, no key made), so the hashes stay valid.
7. Fixed by `placed_from` (in.go:99-115); residual Q4 (hand copy only).
8. Fixed: decisions carried as a backup `-also` file (snapshot, integrity checked), placed into `-viewer`, an earlier
   file put aside (in.go:396-414, 553-568).
9. Fixed: staging mark must name `collector.catalogue_id` (out.go:213-218); missing staged files asked before the mark
   (out.go:359-366).
10. Fixed: `acquireLock` looks at the mark again under the lock (collector/lock.go:39-42), so run, mirror, choose,
    exact-mode and telegram-way all refuse; the bring-in looks before and under its lock (bringin/run.go:112, 170).
11. Fixed ("none" said, backup.to cleared and restored). 12. Fixed for the bring-in and `PathFor` (libroot.Real); the
    viewer still opens a moved catalogue (accepted, LOW). 13. Fixed (`out -abort`); residual Q3.

## New findings, ranked

### Q1a. MEDIUM, CONFIRMED (probe Q1): step 5 can delete the bundle's own login files, then release it: the login is lost
`out.go:83` (the `apart` map has no backups folder), `out.go:461,480-484` (`backupCopies(m.BackupTo)` removes every
`tga-<id>-<date>/sessions` there), `out.go:492` (released.json written with no re-check). With `backup.to` naming
`<bundle>\backup` (not yet made, so the bundle folder is still new), the checked copy out itself makes in the bundle
has the nightly copies' name form and the same CatalogID: step 5 deletes the PC's login files, then the bundle's, then
releases. Probe: out exit 0, PC 0 sessions, bundle 0 sessions, released; `in` refuses ("not a whole move bundle").
Rare (that exact setting), but the result is the one thing the move must never do.
**Fix:** put the backups folder (the setting, or the default `<data>\backups`) into the `apart` map at out.go:83;
in `backupCopies` skip any path `backup.Within(p, bundle)`; and in `removeSessions`, `verifyWhole(o.bundle, man)` once
more right before writing released.json (refuse to release otherwise).

### Q1b. MEDIUM-LOW, CONFIRMED (probe Q1): finding 5 is fixed for one folder only
`out.go:147-167`. Copies are looked for in ONE folder (`backup.to` when set, else the default) and only under
`backup.CatalogID(<the -data path as given>)`, which is the hash of the path. Copies keep their login files when they
are (i) in the default folder from before `backup.to` was set (probe: the fixture's default-folder copy kept its
session file while the summary counted 0), (ii) made under another spelling or an earlier place of the data folder (a
junction, a moved app folder: "a catalogue moved to another folder gets another id", backup.go:118-120). The summary
then says "the login files of 0 backup copies", which the owner reads as "none left".
**Fix:** look in both the stored and the default folder; take every `tga-[0-9a-f]{8}-<date>` copy whose
`catalog.sqlite` (opened `mode=ro&immutable=1`) holds this `collector.catalogue_id` (or `nasmove.archive_id`), not only
this path's CatalogID; count them in the summary as now.

### Q3. LOW, CONFIRMED (probe Q3): `-abort` with a `-bundle` that is not the move's checks only a count
`out.go:436-445`. When the given bundle is not the mark's (another folder, deleted), abort removes the mark if the
number of `account-N.session` files here equals `m.Sessions`. After a released move (the other side live), login files
put back by hand (a copy kept outside the backups folder) plus `out -abort -bundle <anything>` make the PC live again
(probe: exit 0, mark gone, the other folder live), and it prints "the bundle was never released", which is untrue.
**Fix:** abort only with the mark's own bundle (`sum == m.Bundle`), not released, and `presentSessions` equal to it;
otherwise refuse ("give the bundle this archive was moved with"). If undoing without the bundle is wanted, record the
session files' SHA-256s in the mark and require them equal.

### Q4. LOW, CONFIRMED (probe Q4): `in`'s "last" path does not check the folder's catalogue (Back does)
`in.go:118` (`last := resume && hasPlaced && placed.Consumed`) versus `in.go:279` (Back also requires
`placedFrom(p.Catalogue) == sum`). A hand copy of a half-placed folder (placing mark, catalogue, login files) brought to
the placed folder's path (always the same path inside the container) after the placing finished: `in` removes its
placing mark with none of its settings set (library, old library, way): a second live folder (probe: exit 0, unmarked,
2 sessions, old library still set, `placed_from` unset). Needs a hand copy of a data folder, hence LOW.
**Fix:** `last` also requires `placedFrom(p.Catalogue) == sum`; with `hasPlaced && placed.Consumed && !last` refuse
("placed already").

### Q2. Accepted class, CONFIRMED (probe Q2), wider than stated
`in.go:83` compares the bundle's `From` with the `-layout` flag, not with the machine. So the sender's copy is
placeable (a) on the PC itself with `in -layout nas` (a wrong flag; probe: two live folders on one machine), (b) on
the way back, the NAS's copy of the back bundle with `in -layout pc` (on the NAS, or carried), and (c) any old copy of
any round trip, at any later time. Accepting it is right only with a cheap narrowing, I think: refuse `-layout nas` on
Windows and `-layout pc` off Windows (an Env switch for the tests), so a copy places only on the other machine; and
have `out`'s last line say to delete this side's copy right after `in`.

### D1. LOW, by reading: an `.env` with uid 0 is not refused
`compose.yaml:126,225` (nas-app) and the nasdl `user:` line: `${TGARCHIVE_UID:?}` refuses an unset or empty value only;
`0` (or the admin's uid) starts. cap_drop [ALL], read_only, no-new-privileges, host network and no Docker socket are
unchanged in both compose files; `.env.example` sits beside each; the collector's new `./viewer` -> `/viewer` bind is
the same user's folder (no new trust) and matches the NAS default `-viewer`. **Fix:** one README check line (the
app user's uid is not 0 and the user is not in the admin group), or the watchdog/collector refusing to run as uid 0.

### Out of scope, noted
On the NAS the default backups folder is `/backups` (`Dir(Dir(<data>/catalogue.sqlite))` = the container's root, which
is read-only); with `in` now clearing `backup.to`, the NAS's nightly backup has nowhere to write until one is set.
Pre-existing.

## README (deploy/nas-app/README.md): what is missing (the lines the guard kept out, and others)
1. Step 4 (lines 291-293): after the copy to the NAS, a recursive chown of the carried bundle to `<uid>:<gid>` and
   mode 700; the `chmod -R go-rwx` done as the owner's user makes the bundle unreadable to the app's user, so `in`
   cannot read it nor write placed.json or consume it.
2. Step 2 (line 255): dated names for the put-aside folders (`data-before-move-<date>`, `keys-before-move-<date>`); a
   repeat or a second move otherwise moves `data` INTO an existing `data-before-move`.
3. Step 6 (lines 316-320): the NAS-side delete needs root (the bundle is then the app user's, 700).
4. Way back step 2 (line 335): the back bundle is the app user's, 700/600: the owner's NAS user cannot copy it off;
   a chown to the owner's NAS user (or a root copy into a folder of the owner's) first.
5. Way back step 3 (line 351): "as in step 6" names `tgarchive-move-bundle`; the way back needs its own two delete
   commands for `tgarchive-back-bundle` (NAS side as root, PC side `Remove-Item`).
6. A second move after a way back: the NAS's data folder then holds a moved mark; say whether to use `back` on the NAS
   or step 2 (dated put-aside, then `in`); both are safe with the code.
7. Minor: step 2 leaves the test run's viewer state (thumbnails) in `./viewer`; only its decisions file is put aside.

## Verdict
The fixes of 1-13 are sound and add no logic error in the main flows (crashes at every hook, re-runs, two round trips,
copied bundles, folders moved aside). Q1a can still lose the login (rare, cheap to close), Q1b leaves finding 5 half
done while the summary says "0 copies", Q3 and Q4 are small guards. All four fixes are a few lines each.

Verdict: fix first

## Re-check of the fixes (2d2993c2)
Read the diff 1d2675fb..2d2993c2 (out.go, in.go, nasmove.go, the tests, README). Probes rerun through the same overlay,
with two changes: Q2 now runs with `Env.GOOS` "windows" (and a `-layout pc` try under "linux"), and a new Q1c checks
the default folder with `backup.to` set elsewhere. The package's tests pass (`./internal/nasmove/...`, exit 0). The tree
was left clean.
- **Q1a, fixed (probe).** fresh refuses a bundle inside or holding either backups folder before writing anything
  (out.go:290-296); `backupCopies` skips anything within the bundle (out.go:186); `verifyWhole` runs before
  released.json (out.go:568). Probe Q1: exit 2, PC 2 sessions, nothing released. (My old probe's "Q1b" line is a false
  positive here, because out refused before step 5.)
- **Q1b, fixed (probe Q1c and the coder's TestOutBackupCopies).** Both folders are searched (out.go:151-170), and a
  copy is matched by its name id or by the identity in its catalogue (out.go:175-224, opened read-only and immutable).
  Another catalogue's copy is kept. One note, by reading, LOW and pre-existing: a copy whose name id is this PATH's is
  taken without the identity check (out.go:190), so an abandoned earlier archive that lived at the same path loses its
  copies' login files too. Requiring the identity whenever the copy's catalogue reads would close that.
- **Q2, narrowed (probe).** `in` refuses `-layout nas` on Windows and `-layout pc` elsewhere (in.go:85-89). Both probe
  tries are refused. What remains is the accepted class: a copy carried to the other machine.
- **Q3, fixed (probe).** abort needs the mark's own bundle, not released, with every login file of it here
  (out.go:504-517). The probe's abort with another bundle is refused and the mark stays. The cost: if the unreleased
  bundle is deleted by hand, neither abort nor finish can end the move without a hand edit. That is acceptable, but
  README could say "keep the bundle until out said done".
- **Q4, fixed (probe).** `last` requires `placedFrom == sum`, and otherwise refuses (in.go:125-128). Probe: refused,
  placing mark kept.
- **D1, fixed in deploy/nas-app/README.md** (the uid is never 0 and is not the owner's). deploy/nasdl/README.md, which
  uses the same `.env`, has no such line (LOW).
- **New, LOW, by reading:** removeSessions' backups-folder check (out.go:530-534) uses `refused`, which prints
  "Nothing was changed" and exits 2 although the archive is marked moved by then. It is practically unreachable (fresh
  ran the same check on the same values), but `failed` would say the truth.

No new logic error. None of (a)-(d) is reachable in the probed sequences.

Verdict after the fixes: may be listed
