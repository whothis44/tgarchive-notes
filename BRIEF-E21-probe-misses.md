# Brief E21 (merge entry "C15"): a read-only count of how often the frame check's verdicts were right, after download (copies, session C5, 11-16)

**For an Opus 5.5 coder at high effort. A small tool: one program that reads a catalogue and prints counts. You
write code and run only its own tests; whole packages, vet over packages and the merge of the head are done once,
later, by a clerk of the main session. Read only what section 1 names.**

- Copy: make it first, from the Bash tool:
  `git -C /c/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add -b wip/copies-21 /c/Users/trabi/Claude/Projects/Telegram/wt-copies-21 2b557601`
  (the main head; if the branch or the folder exists already, stop and say so). Work only in that copy. Go:
  `. /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in the Bash tool, then the copy's `archiver`.
- **The PC is short of memory (1.4 GB free at 14:06; other sessions build too). One go command at a time, each
  with `GOMAXPROCS=2 GOMEMLIMIT=1GiB GOFLAGS=-p=1`. Before every go command measure:**
  `powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`
  **Under 2.0: wait 2 minutes and measure again. Your waits are bounded in all, not each: after 30 minutes of
  waiting in total over the whole task, stop waiting, commit what you have, and say in the report and in your
  last message which commands never ran.** Write all the code first, then test: do not build after every edit.
- Commit as you go: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; `git push private wip/copies-21` after each commit.
  Never another branch; never merge; never tag.
- Invented data only in tests. **Never open a real catalogue, anything under `E:\T`, or any folder of the
  owner's: the tool is run on the test account's catalogue later, by the main session, not by you.** Nothing runs
  against Telegram; start no program of the project but `go build` and `go test` of your own package.
- A text with a Windows path is written with the Write or Edit tool, never through a shell string.
- You edit no existing file of the repository (no package of another track, none of ours either): everything is
  new, in one new folder. If you find you need a change elsewhere, do not make it: say so in the report.

## 0. What the old app already knows (read by the main session in full: answers 8, section C; the plan of the real run)
The old app recorded 27,051 frame checks (11-04 to 11-14) and judged each again after download
(`C:\Users\trabi\Claude\Projects\Telegram\ANSWERS-for-archiver-8.md`, section C, 4: read it, 45 lines; its table
is the shape of this tool's output):

| Called by the check | Items | Downloaded in full | Same bytes | Same content, different bytes | Different content | Not judged |
|---|---|---|---|---|---|---|
| A copy | 6,950 | 188 | 118 | 66 | 2 | 2 |
| Partly the same | 373 | 111 | 18 | 68 | 0 | 25 |
| No match, after a look-alike hold | 739 | 212 | 6 | 29 | 44 | 133 |
| Distinct (never held) | 18,925 | 16,869 | 1 | 882 | 257 | 15,729 |

"Same bytes": equal SHA-256. "Same content, different bytes": the archive's own video duplicate check over the
two saved files' full fingerprints paired them ("same" or "overlap"). "Different content": both files have a
fingerprint and no pair was found. **Its conclusion: a "copy" was right 184 times in 188; a "no match" against a
named file was wrong about 3 times in 4** (if the post-download check is right: two checkers disagree, nothing
says which is right; "overlap" can be a clip). The fork's advice for the new app: "measure the miss rate on the
test account, against downloads, from the start." **This tool is that measure.** It decides nothing and changes
nothing: it is read after the owner's first real run of the frame check
(`PLAN-C12-first-real-run-frame-check.md`, point 3).

## 1. Read first (in the copy; no more than this)
- `internal/catalog/schema_probe.go` (the table `c_probe`: `result` is one of `copy`, `partly`, `nomatch`,
  `unchecked`, `left` or empty; `why`; `of_file`: the saved file the check named; the fingerprint index).
- In `internal/catalog/probe.go` only what tells you when `of_file` is written and for which results (search
  `of_file`), and how a `c_probe` row's `tg_media_id` leads to that media's own saved file (the `file` row with
  its SHA-256) once it was downloaded: find the join the catalogue itself uses, do not guess one.
- `internal/catalog/schema9.go`, the table `fingerprint` (kind `video`, model empty, `ver`, `seq` 0, `data`: the
  packed frames; `meta`: JSON with `duration_s`; a failure row has no data), and `internal/catalog/vfp.go`'s
  `PutVideoFingerprint` (what is written) and `VideoCandidates` (how a row is read back).
- `internal/footage/footage.go` `Unpack`, and `internal/footage/compare.go` in full: `Compare(a, b, durA, durB)`
  is the pairing of two full fingerprints, the new app's form of the old app's post-download check; its
  `Relation` names are the words of the output.
- How `archiver/tools/a3-run` is laid out (a listing and its first lines), to put the new tool beside it the same
  way. If `tools` is not a place for Go programs, say so and put it where a non-product program belongs: not in
  `cmd` (everything there is built into the owner's folder).

## 2. What to build: `archiver/tools/probe-misses` (a Go program; its logic in functions a test can call)
- One argument: the catalogue file (a full path; a relative one is refused). Nothing else is read. It prints
  **counts and fixed words only**: never an id, a name, a path (not even the argument), a hash, a length of one
  file, a time of one file.
- **It never writes: not a row, not a file, not a journal file.** It does not go through `catalog.Open` (that
  would step the schema). It opens the file itself with `database/sql` and the driver the catalogue uses:
  when a `-wal` file is beside the catalogue (the collector runs, or ended uncleanly): `mode=ro` with a busy
  timeout of 5 s (never `immutable`); when none is: `immutable=1` and `mode=ro` (a plain `mode=ro` would make
  the journal files anew beside a closed catalogue: review E20 found exactly that today in another reader). Say
  in the output's first line which of the two it was, in fixed words.
- It reads `PRAGMA user_version` first and refuses, in fixed words, a file older than the step that made
  `c_probe` (take the number from the catalogue package's exported schema constants if one fits; else test for
  the table's presence).
- **The table it prints**, one line per result of `c_probe` (`copy`, `partly`, `nomatch`, `unchecked`, `left`,
  and "open" for a row with no result yet), with these counts:
  1. rows;
  2. of them, the media downloaded in full since (it has a saved file of its own with a content hash);
  3. of those: **same bytes** (its SHA-256 equals the named file's);
  4. **same content, different bytes**: both have a video fingerprint of the same version with frames, and
     `footage.Compare` pairs them: one count per `Relation` that means a pair (print the `Relation`'s own word
     for each, as the old table split "same" and "overlap");
  5. **different content**: both fingerprinted, the same version, and `Compare` says no pair;
  6. **not judged**, split by reason in fixed words: no named file on the row; the named file is gone; the
     media's own file has no fingerprint (or a failure row); the named file has none; the two versions differ.
  For `unchecked` rows also a count per `why` word (they are fixed words already: check that in `probe.go`; if a
  `why` can carry anything else, print only the count of distinct values).
- Under the table, two sentences in fixed words that the numbers are filled into: of the "no match" rows that
  could be judged, how many were the same bytes or the same content; of the "copy" rows that could be judged,
  how many were different content. With fewer than 20 judged in a group the sentence says "too few to read".
- **If the catalogue can tell whether a file was held by the look-alike rule before its check** (the old table's
  third and fourth rows) from a column or table without guessing, split `nomatch` into those two; if it cannot,
  do not: say so in the output in fixed words and in the report.
- Bounds: one pass; at most 200,000 `c_probe` rows read (more: refused, said); the two fingerprints of a pair are
  read one pair at a time, never all into memory; a query has the 5 s busy timeout and the whole run a context
  of 10 minutes; exit 0 when the table was printed, 1 on a refusal or a failure (fixed words, no path).

## 3. Tests (in the tool's own package; invented data; every name starts with `TestProbeMisses`)
A catalogue for the tests is made in the test's temporary folder by the catalogue package itself (so the schema
is the real one), filled through the catalogue's own exported doors where one exists and by plain SQL in the test
where none does (say which in the report), closed, and then read by the tool's function.
1. `TestProbeMissesTable`: one invented media per cell of the table (same bytes; a pair for each pairing
   `Relation`, the frames made so that `Compare` gives it; different content; each "not judged" reason; not
   downloaded; a row with no result): the printed counts are exactly those.
2. `TestProbeMissesWritesNothing`: the catalogue's folder holds the same file names and the same bytes after a
   run as before, for a closed catalogue (no journal files: none may appear) and for one a second connection
   holds open (the file and its `-wal` byte for byte; say in the report what happens to `-shm`).
3. `TestProbeMissesPrintsNoData`: the output of test 1 holds none of the invented ids, hashes or the folder's
   path: digits appear only as counts (build the invented ids so that the test can tell them from counts).
4. `TestProbeMissesRefuses`: a relative path; a missing file; a file that is not a database; a catalogue from
   before `c_probe`: fixed words, exit 1, nothing made.
Say for each test what change in the code makes it fail (seen failing once, by hand).
Run: `go test ./tools/probe-misses -count=1` (or the path you chose), `go build` of it, `gofmt -l` on your files.

## 4. Hand-back
A report `archiver/docs/progress/copies-probe-misses-REPORT.md`: what was built; the join from a `c_probe` row
to the media's saved file and to the named file, written out, and where in the catalogue's code you found it;
which results carry `of_file`; whether "held before its check" can be told; what `-shm` does; each test and what
breaks it; the command to run it on a catalogue (a form with a placeholder, no real path); what you could not
verify; which go commands never ran for want of memory; every doubt, **above all where the count could
mislead** (a pair counted in two cells, a file judged against the wrong file, a version mixed). Everything
committed and pushed on `wip/copies-21`; the copy clean. Your last message: the head's short hash, the tests run
with their seconds, the doubts in a few lines.
