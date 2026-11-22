# Review NA5: the move (wip/nas-move at 50bd1206), independent, Opus, 2026-11-22

Read: BRIEF-NA5-move.md (with the binding addition: the login files go only on the owner's explicit confirm, after
the bundle verified whole), DESIGN-NAS-autonomous.md sections 4 and 7, all of `internal/nasmove`, `mark`,
`cmd/tgarchive-nasmove`, the collector's lent change, the tests, the NAS README/compose/Dockerfile/build.sh, and the
parts of `internal/backup`, `internal/collector` (run, staging, nightly backup), `internal/store` (old root),
`internal/launcher` (layout, viewer folder), `internal/viewer` (decisions) the move touches. Nothing edited in the
tree. Probes: `C:\Users\trabi\AppData\Local\Temp\claude\71f159c3a9e5d4b9\eb2fe7b8-c207-44b6-ab26-9a345fd154a3\scratchpad\review-na5\probe_test.go`
(with `overlay.json` beside it), run through `runs-nas-n1/go1.sh ... go test -p 1 -overlay <overlay.json> -run TestProbe ./internal/nasmove/`:
all eight probes FAIL as the findings say (exit 1). Invented data, fake Telegram only.

## Findings, ranked

### 1. HIGH, CONFIRMED (probe P1): "placed once only" holds per copy of the bundle, and the README makes two copies
`in.go:69-87` (placed.json), `README.md` steps 4 and 7, `main.go:323-326`.
placed.json is written into the copy `in` ran on. `scp -r` (step 4) leaves the PC's copy, released and unplaced, and
the README keeps it "once the NAS has run well". `in` from that copy into any new folder places the login again; on
Windows `in` defaults to `-layout pc`, so `tgarchive-nasmove in -bundle C:\...\tgarchive-move-bundle -data <new> ...`
on the PC does it. Probe: out, copy the bundle, in on the "NAS" from the copy, in on the "PC" from the original: both
exit 0, both folders hold the sessions with no mark. The same holds for the way back (the NAS keeps its copy of the
back bundle) and for any old bundle: a session file's Telegram key does not age, so a released bundle from months ago
still revives the login. The test `TestInThenCollectorRunsOnFakeTelegram` and the README line "A second `in` into
another folder is refused" claim more than is true.
**Fix:** (a) `in` and `back` consume what they placed from: once the placing is whole and before the placing mark goes
(`in.go:146`, `in.go:279`), delete the bundle's session files and its `keys/` (or the whole bundle) and say so;
(b) `in` refuses a bundle whose `From` equals `-layout` (a PC bundle is never placed on a PC; the way back is `back`);
(c) README: delete the PC's copy at the end of step 5 (right after `in` said done), not in step 7; the same for the
NAS's copy at the end of the way back's step 3; (d) a test with a copied bundle.

### 2. HIGH, CONFIRMED (probe P3): `back` accepts an OLDER returned bundle while the NAS runs a later move
`in.go:193-207`. The checks are: same archive, `From == m.To`, `sum != m.Bundle`, placed.json absent or naming this
folder. A bundle that came back on an earlier round trip passes all four (its placed.json names this PC folder,
because `back` placed it here before). Probe: PC->NAS (A), NAS->PC (B, back), PC->NAS again (C, placed on a new NAS
folder), then `back` with B: exit 0, the PC's mark cleared, the PC's sessions placed, the NAS folder live: the login
in two places, and the PC's catalogue rolled back a whole round trip.
**Fix:** a chain: `in` records in the placed catalogue the manifest sum it was placed from (a setting such as
`nasmove.placed_from`); `out` copies it into its manifest (`came_from`); `back` requires `man.CameFrom == m.Bundle`
(the bundle the mark names). Also refuse in `back` a bundle whose placed.json exists unless the folder is mid-back
(the catalogue there is already the bundle's). Test it with two round trips.

### 3. HIGH, CONFIRMED (probe P8): `-bundle` given as the folder holding the staging folder deletes the staged files, then says "Nothing was changed"
`out.go:58` checks `Within(bundle, staging)` and `Within(bundle, keys)` but not `Within(staging, bundle)` nor
`Within(keys, bundle)`; `prepareBundle` (`out.go:422-447`) takes any folder holding only the names `backup`, `keys`,
`staging`, `bundle.json` for an earlier run's half bundle and `RemoveAll`s them. Probe: staging at `<x>\staging`,
`-bundle <x>`: all 3 staged files are gone; on Windows the removal of the folder itself then fails on out's own staging
lock and out prints "refused: ... Nothing was changed." (on Linux flock does not stop it: the whole folder goes). The
same code path deletes a keys folder named `keys` alone in the given folder: the session key is in no backup, so the
login would be lost (PLAUSIBLE, by reading; the same lines).
**Fix:** refuse a bundle that holds the data, staging or keys folder (both directions of `Within`); write a marker file
first into a new bundle (`bundle-in-progress.json` with the archive id) and empty an existing folder only when it
holds that marker for this archive, never by names alone; "Nothing was changed" only where it is true.

### 4. HIGH, CONFIRMED (probe P7): the PC's old-library folder travels to the NAS and the NAS's collector then cannot start
`in.go:114-125`; `store/oldroot.go:29-41`; `collector/staging.go:187-231`.
`in` keeps `libroot.SettingKey` "as the catalogue has it" (the README says so: the NAS does not mount it). On Linux
`filepath.IsAbs("E:\...")` is false, so `store.NewWriter` refuses it ("the old library's folder must be an absolute
path") and Run ends: "the staging folder or the library cannot be set up: nothing was started". Probe (on Windows, the
NAS's form `/volume1/...` stands for it, `IsAbs` false the same way): Run returned that error on the placed folder. By
then the PC's login files are deleted and `in` cannot be run again ("placed already"); only a hand edit of the
catalogue starts the archive. Any archive with the old app's archive brought in (the unified archive, the goal) has
that setting. The test fixture sets a Windows path and runs on Windows, so the suite cannot see it.
**Fix:** when `-layout` differs from the bundle's `From`, `in` removes the old-library setting unless
`-old-library-root` is given (the PC's value stays in the PC's moved mark for `back`), and says so; do the same for any
other side-bound absolute path in the catalogue (`backup.to`, see 11). Test with the other system's form.

### 5. MEDIUM-HIGH, CONFIRMED by reading: the PC's nightly backups keep the login, and nothing stops restoring one into a new folder
`collector/backupnight.go` (default `<data>\backups`, 7 copies), `backup/run.go:253-300` (every copy holds `sessions/`),
`out.go:109` and the bundle comment (the key stays on the PC). After the move the PC's collector refuses, so its
nightly backup never runs again: the last 7 copies, all from before the move, are never rotated and all hold the
session files; the key that opens them stays in `%LOCALAPPDATA%\tgarchive` (shared with the test archive, so it cannot
simply go). The moved mark is beside the catalogue, not in any copy. Restoring a copy into the same data folder is
refused (the mark stays), but restoring into another data folder (a new app folder, a reinstall, the launcher pointed
at a new data folder) has no mark: the PC's collector runs the login while the NAS does. The README's one line ("never
put one back while the NAS runs") is the only guard; the backup copy's own README says how to put one back and says
nothing of a move. The same holds on the way back for whatever backups the NAS made.
**What the move should do:** at step 5, under the same typed yes, delete the `sessions/` folder of every copy of this
catalogue in its backups folder (the `backup.to` setting, or the default; the copies named `tga-<catalogue id>-...`),
count them in the summary before the yes ("N backup copies hold the login: their login files are deleted too"), and
leave the catalogue copies; if a copy's sessions cannot be deleted, stop before releasing the bundle. Also run a last
backup of the catalogue into the bundle only (already done) and write the backup README's restore paragraph to say: an
archive marked moved is never put back into another folder.

### 6. MEDIUM, CONFIRMED (probe P4): a wrong `-keys` deletes the login files and the bundle cannot open its sessions
`out.go:109-112` checks only that `session.key` exists. With another keys folder holding another key (the test
archive's, a mistyped `-keys`), out copies that key, verifies the bundle byte for byte, marks, deletes the PC's login
files and releases: the bundle's sessions do not open with the bundle's key (`ErrSessionUnreadable`). Recoverable only
by hand (the right key is still on the PC). **Fix:** before writing the mark, open every bundle session with the
bundle's key (`telegram.NewSessionStore(...).LoadSession`), refuse otherwise; the same check in `in` and `back` before
placing.

### 7. MEDIUM, CONFIRMED (probe P2): placed once by path only, and on the NAS every data folder is `/data`
`nasmove.go:288-295`, `in.go:80-87`. `targetID` is the hash of the path; inside the container it is always `/data`.
After a successful `in`, moving the folder aside and running `in` again into a new empty folder at the same path places
it again (probe: exit 0, both folders hold the login with no mark). Repeating the README's step 2 after a failed start
does exactly this (`mv data data-before-move`, which then moves `data` INTO the existing `data-before-move`).
**Fix:** once placed.json exists, accept only a resume (a placing mark with this manifest sum in the folder) or the
no-op (the bundle's catalogue there); refuse a new empty folder. Finding 1's consumption closes it too.

### 8. MEDIUM, CONFIRMED by reading: the owner's viewer decisions do not move
`out.go:164` (no `Also`), `out.go:403` ("an -also file: none is asked for"); `viewer/viewer.go:354`,
`viewer/decisions.go:1-12`, `launcher/defaults.go:40-45,97`. `decisions.sqlite` (the owner's "same / not the same" on
probable copies, the hidden marks, kept "for good") lives in `<data>\catalog\viewer` and is also what the collector's
`-pair-words` reads. It is not in the bundle, so on the NAS every decision is gone and judged copies are held again.
**Fix:** pass it to the backup as an `-also` file (the backup's own way for "the viewer's marks"), carry it with a role
of its own, place it into the other side's viewer folder (`/viewer` on the NAS; a `-viewer` flag), and back the same.

### 9. LOW-MEDIUM, CONFIRMED (probe P5): out does not check that `-staging` is this archive's
`out.go:202-216`. A mistyped or other archive's staging folder: every staged file is "not there", counted as not
copied, and out goes on to delete the login and release; on the NAS those files are downloaded again (Telegram
requests the owner did not agree to). The summary says "the 3 staged files are copied into the bundle" before trying,
then "copied 0, not copied 3". **Fix:** read the staging folder's `collector.mark` (as `checkTargets` does) and refuse
another catalogue's or an unmarked folder when staged files exist; when any staged file is missing, stop before the
mark and ask (count and bytes) instead of going on; say the copy count after the copy only.

### 10. LOW, CONFIRMED (probe P6): the collector checks the mark before the lock, not under it
`collector.go:609-611` (New), `collector.go:781` (Run takes the lock). A mark written after New and before Run is not
honoured: the probe's Run started both accounts on the fake Telegram. Out holds the catalogue's lock while it writes the
mark, so the gap is the time between New and Run's `acquireLock` (with `-pages` the pages' lock, taken earlier, closes
most of it); an out that ends with "stopped, login files kept" inside that gap leaves a collector writing to a
catalogue whose bundle was already taken (later `-finish` would release a stale bundle if the session files did not
change). **Fix:** call `isMoved` again right after `acquireLock` in Run (and in the sign-in path) and return `ErrMoved`.

### 11. LOW, PLAUSIBLE: other side-bound settings travel unseen
`in.go:126-140`. The way "none" (no VPN) is carried to the NAS silently: the NAS would connect directly; say it, or
refuse without a flag. `backup.to` (a Windows path) is not handled either way and is not in the mark for `back`.

### 12. LOW, PLAUSIBLE: the other programs ignore the mark
The bring-in (`tgarchive-bringin`), the viewer and the collector's `chats`, `choose`, `exact-mode`, `telegram-way`
still open the PC's moved catalogue: none sends anything, but work done there (a brought-in archive, a choice, a
decision) never reaches the NAS. The bring-in at least should refuse (it is the unified archive's door). Also
`mark.PathFor` uses `filepath.Dir(catalogue)`, not `libroot.Real` as `catlock.Path` does: a collector given a link to
the catalogue file in another folder does not see the mark.

### 13. LOW, by reading: no way to undo a move that was not released
After "stopped, login files kept" (exit 3) or a lost or damaged bundle before release, the PC refuses its archive and
the only way back is deleting the mark by hand. An `out -cancel` (only while the bundle is not released and the login
files are all here: remove the mark, say so) would make "finishes or undoes" true.

### README (6), apart from the above
- The in-image `in` and `out` work as written in principle: host mode is irrelevant to them, `/data`, `/keys`, `/tmp`,
  the bundle mount are writable by 1000:10, the read-only root is not written, compose run keeps a TTY for the typed
  yes. They depend on the scp'ing NAS user being uid 1000 (placed.json is written into the bundle); say so.
- Order: delete the carried bundle on the PC right after step 5 (finding 1), not after "the NAS has run well".
- Step 2 assumes no earlier `data-before-move`; a second move (after a way back) or a repeat hits it (finding 7). Use
  a dated name.
- The bundle on C: (which the same README says is nearly full) with the staged files; free room is checked only on
  the bundle's disk, not for the backup's snapshot beside the catalogue.

### Tests (8): what they do not prove
- "Placed once only" is tested with the same bundle folder only; no copy (finding 1), no folder moved aside (7).
- `TestBackOnlyWithReturnedBundle` refuses the outgoing bundle by the `From` check (it fires first), so the
  `sum == m.Bundle` check is untested; no second round trip (2).
- The NAS layout is only run on Windows with a Windows old-library path (4).
- `TestOutCrashAtEachStep`'s "never two live places" looks at the PC and that one bundle only.
- No test gives a wrong `-keys`, `-staging` or a bundle folder holding them (3, 6, 9).

## What I found sound
- The lock set: out takes the collector's catalogue lock (by real path), the pages' lock, the staging lock and the
  watchdog's lock for the whole run; a running app, collector, bring-in or watchdog makes it refuse with nothing
  written (tested); none can start meanwhile.
- The order on one copy: checked copy (the backup program's own, integrity checked), keys and staged files through
  temporary names and read back, manifest, whole bundle read back, mark, then the login files only on a typed yes or
  the flag, each session file checked equal to the bundle's before deletion, then released.json. A crash at any step
  of out, in or back leaves the mark, a placing mark or an unreleased bundle; the next run finishes (tested at every
  hook). The binding addition (delete only on the owner's confirm, after the bundle verified whole) is met.
- The collector's refusal: run, signin, mirror, New and openWay check the mark before any lock, session or dial; an
  unreadable mark or anything under its name refuses (fail closed); only `back` removes a moved mark; `in` removes only
  its own placing mark; `out` and `in` refuse a folder with an unreadable or foreign mark.
- The manifest: unknown fields refused, every path checked against its role and fixed place, no `..` or absolute path,
  sizes and SHA-256 compared; the bundle cannot write outside its fixed places.
- `in` sets the library folder, turns "system" into "tunnel" on the NAS; `back` puts the PC's settings back from the
  mark and keeps the catalogue from before aside with its side files.
- Privacy: every line is fixed words and numbers; the flag package's messages are replaced; placed.json names a folder
  by hash only; the tests check that no folder or invented label is printed.
