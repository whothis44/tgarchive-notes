# Brief B3-13: "No faces" in "Who is in it" (session B3, 11-15)

You are an Opus coder. Work only in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-faces`. First:
`git fetch private wip/b-viewer2 && git checkout -B wip/b-nofaces private/wip/b-viewer2` (81d2295: the viewer
branch on the main head, schema step 16). Go module: `archiver/`. Go: `source
/c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in each Bash call. Packages:
`archiver/internal/bringin`, `archiver/cmd/tgarchive-bringin` and `archiver/internal/viewer` only. **Nothing in
`internal/catalog`** (not this track's): no schema step, no new constant there. Commit after each part and
`git push private wip/b-nofaces` (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending
with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; no archive numbers).

## What is asked (FEATURES sections 7 and 9: listed)
"Faces counted in one picture or frame (one person / two or more)" is built ("Who is in it": Anyone, One
person, Two or more). The old viewer also had **"No faces"**. It is missing because the bring-in does not
carry which files were looked at. The people page (names, merge, "same person?") stays "later": the old
archive has 3,803 people made by the app, none named, none hidden, 3 merged (counts read 11-14), so a
named-people filter would be nearly empty. Do not build it.

## What the old app knows (read by the main session; read the code named here yourself)
- `wt-v12.32/core-service/internal/app/ix_schema.go`: `ix_face_done(key TEXT PRIMARY KEY, model, faces, at)`:
  one row per file looked at, with how many faces were found. Counts on 11-14: 116,586 files looked at,
  54,045 of them with no face; 84,213 faces in 62,541 files.
- The old viewer's rule (`viewer_index.go`, `ix_faces_quality.go` in `wt-v12.32`): a file's number of people
  is the larger of "most faces in one picture or frame" and "different people recognised"; small or blurred
  faces (`ixFaceJunkPx`, `ixFaceJunkBlur`) are left out unless asked. "No faces" there = looked at, and no
  face that counts. Read how it decides "No faces" for a file whose only faces are small or blurred, and do
  the same.
- The new viewer (`internal/viewer/faces.go`): face rows are read behind the first index in slices (they are
  scattered through the wide `fingerprint` table: reading them all took 18 s of a start), with a progress
  line; counts per saved file, carried to its Telegram files.

## Part 1: the bring-in carries "looked at"
- In `internal/bringin` (`run2.go`'s fingerprint sources are the pattern): `ix_face_done` rows whose key is a
  saved file's become fingerprints of a kind of the bring-in's own, `face_done` (a constant in
  `internal/bringin`, exported for the viewer to import if the viewer's import wall allows `internal/bringin`;
  if it does not, the same literal in both with a test in the viewer that reads the bring-in's source for
  it): one per file and model, the value the number of faces as the old app stored it (a short fixed
  encoding; the catalogue refuses an empty value), `at` carried. Keys that are not a saved file's are
  counted and not carried, like the other sources.
- `plan` and `verify` get their lines (rows read, carried, not a saved file's; equal or a stated reason).
- Named tests on the package's invented old database (add `ix_face_done` rows to it): carried counts,
  verify passes, a rerun (resume) does not double them.

## Part 2: the viewer
- `faces.go`: read the `face_done` rows the same way and at the same pace as the face rows (in the same
  slices, no second pass over the table if one read can take both kinds; nothing on the start path). A file
  is "looked at" when it has such a row. `mediaRec` gets what it needs in the bits it has (it has two
  `uint8` counts and a flags byte with one bit free: check; do not grow the record by more than a byte).
- "Who is in it" gets **No faces**: looked at, and no face that counts under the current "small or blurred"
  choice. A file never looked at is in none of the three (Anyone still shows it). In one-tile-per-post mode a
  tile is "No faces" when every visual file of it was looked at and none has a face that counts. The sidebar
  shows the option only when the catalogue has any `face_done` row, and a line "N of M pictures and videos
  were looked at for faces" (from the index, not SQL per request). Query `faces=none`; in `filter.key`; a
  chip like the others.
- A catalogue without `face_done` rows (a new account, an older bring-in) behaves exactly as today.
- Named tests: the three options partition the looked-at files; small-or-blurred switch moves a file between
  "No faces" and "One person"; a catalogue without the rows; the update path picks up rows added later.

## Tests at the end, once
`go test ./internal/bringin ./cmd/tgarchive-bringin -p 1` (about a minute) and `go test ./internal/viewer -p 1`
(about 3.5 minutes; in the background), `gofmt -l`, `go vet` on the three packages; the scripts parse as
modules (`TestPageScriptsParseAsModules` is in the package; `node --check FILE` alone proves nothing for a
script with imports). No race detector, no mutation checks, one go command at a time.

## One count on the real data (allowed, strictly bounded)
Once, after part 1: a throwaway probe **kept out of the commit**, read-only (`mode=ro`), on the session's
copy of the old database
`C:\Users\trabi\AppData\Local\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b\oldcopy-3\old.sqlite`:
print **only counts**: `ix_face_done` rows, of them with a saved file's key, with 0 faces, distinct models;
and how many saved files have face rows but no `ix_face_done` row. Never print a key, name, path or text. Do
not run `run`, `plan` or `verify` on real files; do not open the catalogues the viewer uses.

## Rules
- Never open the viewer on real data or any real file; nothing against Telegram; do not touch
  `repo-archiver`, `wt-v12.32` (read only), other `wt-*` folders or other packages (above all not
  `internal/catalog`). Do not merge into or push `claude/charming-feynman-vm2xia`, `wip/b-viewer` or
  `wip/b-viewer2`.
- Every viewer route is registered with an access class (`access.go`); you add no route.
- Concurrent code: say exactly which lines run in the index update and the faces read.

## Hand back (short)
Commits, differences from this brief and why, named tests, both whole-package times and results, the real
data's counts, the lines that run in the update, doubts.
