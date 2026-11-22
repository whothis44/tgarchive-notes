# Brief K6b: the backup's fix round after its independent review (Core, 2026-11-15)

For the coder of K6, in the same copy (`C:\Users\trabi\Claude\Projects\Telegram\wt-core-backup`, branch
`wip/core-backup`, on top of 3cd837f). The review: `C:\Users\trabi\Claude\Projects\Telegram\wt-core-backup-review-scratch\REVIEW.md`
(read it whole first; its probes are `zz_probe_test.go` and `zz_probe2_test.go` in that folder, loaded by
overlay: do not edit that folder). The reviewer's verdict: a single run on its own path held up under
attack; what fails is a backups folder shared with anything else. Every finding is accepted; what to do
with each is below. Where this brief and `BRIEF-K6-backup.md` disagree, this one wins. Still new files and
your own files only; no existing file of the repository is edited.

## The changes, by the review's numbers

**1 and 2 (high): a copy says whose it is, in its name.** A copy's folder is now
`tga-<id>-<2006-01-02_150405>` and its half-made form `tga-<id>-<date_time>.partial`, where `<id>` is the
first 8 hex characters of the SHA-256 of the catalogue's absolute, cleaned path (lower-cased on Windows,
separators as the system writes them). The manifest gains `"source": "<id>"` and its version becomes 2.
- Rotation, the removal of an old `.partial`, `list` and `check`'s default ("the newest") take ONLY folders
  whose name carries this run's id AND whose manifest parses, names the same id, lists `catalog.sqlite` and
  says `"integrity":"ok"` (finding 8). Everything else in the folder is not touched and not counted.
- `list` ends with one more line when there are any: "copies of another catalogue here: N (never touched)"
  (folders of this tool's name form with another id). The old app's folders (a bare date and time) match
  neither form and are never counted or touched: a test with such a folder, with and without a manifest.
- `list` and `check` therefore take `-db` as well (to know the id); `check -name` takes a full name of this
  tool's form with any id (reading is harmless), and still refuses anything else.
- The README of a copy says in one line that the name's middle part marks the catalogue it was made from,
  and that after the data folder is moved the older copies are kept and no longer rotated.

**3 (high): one run at a time per backups folder, and nothing is published that is not whole.**
- (a) A second lock, a file in `-to` (a fixed name of this tool's, for example `tgarchive-backup.lock`),
  taken after the refusals and the work folder's lock and held for the whole run, the same technique as the
  work folder's lock. A run that finds it held, or cannot take it for any other reason, is refused in fixed
  words, exit 2, having written nothing else there. The lock file is never removed by rotation or listed
  as anything. Rotation and every removal in `-to` happen only under this lock.
- (b) Just before the rename, every file the manifest lists is looked at again inside the `.partial`
  (`Lstat`: a regular file of the manifest's size); the manifest and the README too. Anything else: the run
  fails at "publish", and the `.partial` is removed.
- The reviewer's probe `TestProbeConcurrentRotationPublishesBadCopy`, fitted to the new names, becomes a
  test: the second run is refused while the first holds the folder; and, with the lock taken away by a test
  seam, (b) alone fails the publish.

**4 (high): only the collector's own session files are copied.** Names matching `^account-\d+\.session$`
directly in `sessions` (regular files, as before). Everything else there is counted and said as
"not copied N" (folders and links included in that count or beside it, as you find clearer), never copied.
The README says it. The reviewer's probe as a test: a key-named file and a temporary file of the session
store's form in `sessions` do not reach the copy.

**5 (medium): a session file is never held open while the NAS is written.** Read it whole into memory
(refuse one over 1 MiB: counted as "too large, not copied", not a failure), close it, then write, flush
and read back from memory's hash; then hash the source again from a fresh short read, as now (changed:
again, 3 tries). The reviewer's probe as a test: a rename over the session file during the write to the
destination succeeds.

**6 (low): the folders are compared as the system sees them.** The refusals about `-to` and the
catalogue's folder use `os.SameFile` walking up the parents on both sides (the `\\?\` form, a junction, a
short name), not the paths' text. The reviewer's probe as a test.

**7 (low): the work folder is kept apart.** The default work folder, `backup-work` inside the catalogue's
folder, stays allowed (a subfolder of its own). Refused, exit 2, is a `-work` that is (by `os.SameFile`)
the very folder that directly holds `-db` or any `-also` file, the `sessions` folder or anything inside
it, `-to` or anything inside it, or a folder that holds `-to`.
And the local snapshots get names nothing else has (a fixed prefix of this tool's and the process id),
and the clean-up at the start removes only files of exactly that form. The reviewer's probe as a test.

**8 (low):** in 1 above. `check` fails a copy whose manifest lists no `catalog.sqlite` or does not say
`"integrity":"ok"`. `TestRotation`'s helper no longer makes `{}` copies pass a check.

**9 (low):** the reviewer's probe `TestProbeSnapshotChangedBeforeCopy` becomes a test: a byte of the local
snapshot changed after its check and before its copy fails the run at the copy, nothing published.

**10 (low):** before the drive's kind is asked, the work folder's nearest existing ancestor is resolved
(`filepath.EvalSymlinks`), and the test for a network path is applied to the result too.

**11:** no change. One sentence in the package's comment: the read-back may be answered from the system's
cache; `check` run later reads the share.

## Also

- Everything printed and recorded stays numbers and fixed words; the copy's name now holds 8 hex
  characters of a hash, which may be printed.
- Keep every existing test's intent; change expectations only where this brief changes the behaviour, and
  say each in the report.
- Named tests only, your two packages, as before (`GOGC=25 GOMAXPROCS=1 go test -p 1 -count=1
  ./internal/backup/ ./cmd/tgarchive-backup/`); measure the PC first; no race detector, no Docker.
- `gofmt -l` clean; commit and push to `private` as before (`wip/core-backup` only); add a section "The fix
  round" to `archiver/docs/progress/core-backup-REPORT.md`: each finding, what changed, the test that now
  fails when it is undone, anything left and why, what you doubt.
- Hand back commit-ready; say the head's short hash.
