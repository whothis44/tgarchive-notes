# Review: wip/fix-libpics f754b2a4 (against 3dd304df), 11-23

**Verdict: fix first (one MED in the shared budget; the rest is small).** The hold/skip/release rules hold: the pass
holds, skips and releases nothing itself.

Checked and found sound:
- **The path to the catalogue.** The pass writes only PDQ rows (PutPictureHash) and edges through AddPicturePair. That
  door needs both files saved, honours "different" and not_copy, never writes exact, and never touches c_want. A
  library-pass edge is the same as a staged one (same door, same evidence, same lesser-to-better rule). Every rule that
  reads a `probable` edge (probableBackSQL, WantAgain, coveredWantSQL, markCheckFirst, the album rule) does one of two
  things. Either it only holds, bringing a lost lesser back held behind the better saved one, or it filters on the video
  look-alike evidence. None skips or releases on a picture edge.
- **Other checks.** The gate (copies waiting or running, library away, cap 0 or unreadable) holds, fails closed and is
  looked at before each file. Old-library reads use the read-only shared open (GENERIC_READ). Log lines are constant
  formats with counts only. Take locks the check and the charge together. A store that cannot be read holds reads back.
  There is no busy loop (capUntil, Tick, the 1 h rest).
- **The Settings POST.** It accepts 0 and 9e12, refuses -1, 1.5, "lots", null, true and an empty body, and is in the
  security list.
- **Tests.** Named tests pass: libcap, picfp, vfp `TestLibrary*`, server `LibraryReads|TestAssets|Security`, catalog
  `LibraryPictures|LibraryRead*`, plus vet.

## MED 1: the shared hour is reset by a slightly older "now" (the total can be passed)
- **Where:** `internal/libcap/libcap.go` `roll`: `|| now.Before(from)` treats any `now` before the hour's start as a
  clock set back. It begins a new hour with 0 bytes. In `internal/picfp/library.go` `libraryStep`, `now` is read once
  and then used for every Take and Add of a batch of up to 16 reads, hashes and compares. `vfp.libCap` reads its own
  `now` before it gets the lock.
- **Failing scenario (probe test, run and removed):** the video pass begins hour 2 at T+1h and takes 900 MB of a
  1,000 MB budget. The picture pass is mid-batch with its `now` = T+59m59s. Its Take then resets the hour (from =
  T+59m59s, bytes 0) and is granted 900 MB. Result: 1,800 MB begun against a 1,000 MB hour, and the video's bytes are
  lost from the count. The same race exists at millisecond scale between the two goroutines at any hour boundary,
  even with a fresh `now`.
- **Fix:**
  - In `roll`, treat `now` before `from` as inside the hour (`now = from`) unless it is earlier by more than an hour.
    Only that is a real clock set back.
  - In picfp, read `w.cfg.Clock.Now()` before each Take and Add.
  - Add a libcap test with a stale `now` across an hour the other taker began.

## LOW 2: picfp does not wait out an old library that is away
- **Where:** `picfp/library.go`. There is no equivalent of vfp's `placeUp` (the old root's Stat), and no re-check of
  `LibraryUp` after a failed open or read.
- **Scenario:** the old library's drive or share is away. Every old place opens with ErrNotExist (counted "missing",
  walked past) or another error (a read error; given up after 3 walks, until the program restarts). Nothing is written,
  so no lasting harm. But the requirement "the library being away is waited out" is not met, and the counts mislead.
- **Fix:** before an old place, Stat the old root (as vfp does). After an open or read failure, check LibraryUp and the
  old root again. If either is away, hold the turn (`LibraryHeld`), leave `below` where it is, and do not passOver.

## LOW 3: an old-root read error restarts the walk and passes old places over
- **Where:** `picfp/library.go`: `OldLibraryRoot` error → `oldDir = ""`.
- **Scenario:** with an old root named, one failed setting read makes the walk start again with no root. Old places
  are passed over as "no root" (10 min skip each). The next good read restarts the walk again.
- **Fix:** on an error, hold the turn (fail closed), as vfp's `libRoot` does.

## LOW 4: the picture pass reads up to the hour's total plus one file
- **Where:** `picfp/library.go`: the charge is the size on record, capped at MaxBytes. `Add` charges after the read.
- **Scenario:** a size on record below the true size (or 0) lets a read pass the total by up to MaxBytes (40 MB).
  This is bounded and small against 50,000 MB, but it is not "never passes".
- **Fix:** accept and document it, or charge MaxBytes at Take and give back the unused part.

## NOTE 5: the skip map grows with library pass-overs
`passOver` for no-root and missing library files adds them to `w.skip`. With no old root named, every hourly walk puts
each old picture in the map. `turn` then raises `limit` by `len(skip)` and loops the whole map on each of about N/16
back-to-back turns. Not a correctness issue. The walk's `below` already moves past them, so drop the passOver for
no-root and missing.

## NOTE 6: other small points
- **One write per picture:** `Take` writes the hour to c_settings for every picture, a second write per picture beside
  its PDQ row. Could be kept every N files or every few seconds.
- **No watch during a read:** a picture (40 MB at most) is read without watching copies or the library during the read,
  unlike vfp's 2 s look. Acceptable for this size.
- **Too-large pictures:** a picture whose size on record is over MaxBytes is still read (40 MB over the link) only to
  write "too-large". It could be written from the size on record.
- **Corrupt stored hour:** `LibraryReadHour` reads a corrupt stored hour as "no hour" (a fresh full hour), not as held.
  Only the app writes it, so this is minor.
- **Two reads at once:** the two passes can each read one library file at the same time.

**Fix first** (MED 1; LOW 2 and 3 are cheap to fold into the same round).

## Second pass (the fix): 775dac88 against f754b2a4

**Verdict: may be merged.** Every finding is fixed or answered. The fix adds no error that passes the total, holds
forever, or holds, skips or releases a file.

- **MED 1: fixed.** `roll` now treats a `now` up to an hour before `from` as inside the hour. picfp reads
  `Clock.Now()` right before each Take, and vfp already did. The 900+900 scenario is refused with a wait of 1 to 2 h,
  and only the remaining 100 MB is granted (`TestStaleNowAtTheHoursTurn`, including two goroutines at the turn).
  `Add` is gone, so no charge can land after a read in a rolled hour.
  - **Clock steps (probe, run and removed).** Set back 30 min with the hour spent: held 90 min, then granted. Set back
    3 h: a new hour at once, and the clock moving forward again starts another at once. Set back exactly 1 h: held
    2 h, then on. So a clock set back never holds reads for more than the step plus an hour.
  - **picfp's own wait.** `capUntil` and `restUntil` are compared on Go's monotonic reading, so a wall-clock step does
    not stretch them.
  - **A stale reading of more than an hour.** This needs a clock jump inside the few ms between the clock read and the
    Take. At worst it starts one extra hour, once. Not worth more code.
- **Damaged stored hour: fixed.** `LibraryReadHour` returns `libcap.ErrDamaged`. `load` takes it as an hour spent
  from now (bytes MaxInt64) and stores that. Reads are held for 1 h, then a new hour begins.
  - A restart within that hour reads the stored spent hour and holds only until its end (probe: 50 min left after
    10 min).
  - If the store write fails, a restart holds one more hour from the restart. That fails closed, and recovers.
  - vfp's `Seed` cannot undo the hold: the walk's hour is older than `now`.
  - Nothing else reads the setting (grep). MaxInt64 round-trips through the JSON as int64.
- **LOW 2: fixed.** `placeAway` (LibraryUp, plus a Stat of the old root for an old place) runs before each open and
  again after any open or read failure. While a library is away: `LibraryHeld`, `below` is not moved, there is no
  passOver, and the step returns false, so the next try waits for the Tick (no busy loop). The picture stays next in
  line and is read once the library answers (`TestLibraryPicturesOldAwayWaitedOut`).
- **LOW 3: fixed.** A failed `OldLibraryRoot` read now counts StoreErrors and LibraryHeld and returns. The walk does
  not restart, and nothing is walked past.
- **LOW 4: fixed.** The charge is the open file's true size (Stat), capped at MaxBytes. The read is a LimitReader at
  charge+1, and longer data is `errLonger`, which records nothing. A picture whose true size is over MaxBytes gets its
  "too-large" row from the size: unread and uncharged. The production open (`OpenShared` → `*os.File`) always has
  Stat, so `errLonger` arises only for a file that grows between the Stat and the read.
  - **Does `errLonger` loop or starve? No (probe, run and removed: 3 pictures, the middle one longer than charged,
    200 turns of 10 min).** It counts as a read error with passOver(tried): `below` moves past it and the others are
    read in the same turn. It is tried once per walk, so at most one charge per hourly walk. After 3 tries it is given
    up until the restart. Result: 2 rows, 3 read errors, 1 given up.
- **NOTE 5: fixed.** No root and missing no longer go into the skip map.
- **Unchanged rules.** Nothing is held, skipped or released by this pass: rows go only through PutPictureHash and
  AddPicturePair, and the hold edges are as before. The diff adds no log calls.

New, NOTE only (no fix needed for merging):
- **N1 (`picfp/library.go`, a read failure while away).** If a read fails after its Take and the library is then
  away, the bytes stay charged and the picture is charged again on its retry. That is one picture per away episode,
  within the total's intent (bytes begun are counted).
- **N2 (`picfp/library.go`, an open with no Stat).** With an open that cannot Stat and a size on record below the true
  size, the picture is given up after 3 walks and never hashed. Before the fix it was read and over-charged. Only a
  test opener lacks Stat today. Keep Stat on any future opener.
- **N3 (`picfp.go` `turn`).** Library ids given up (`errLonger` or read errors) still sit in `w.skip` for the run and
  raise the staged list's `limit`. This is the remainder of NOTE 5: small.

Tests run (`-count=1`): libcap whole (with the probe), picfp `Library` (with the probe), vfp `TestLibrary`, catalog
`LibraryRead|LibraryPictures`, and vet of libcap, picfp and vfp: all pass. The race detector did not run: cgo is off
in this environment. The two takers share one mutex, and the goroutine test passed without it.

**May be merged.**
