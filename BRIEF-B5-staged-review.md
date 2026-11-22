# Review brief B5-S: an independent, read-only review of "the viewer knows where a saved file's bytes are"

You are an independent reviewer (Opus) for the viewer track of the new archiver. You did not write this code
and you owe its coder nothing. The piece: branch `wip/b-staged`, head 3f4030ba, cut from 698ee15d, in the
copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-viewer` (Go module in `archiver/`). What it was asked to
do: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-B5-staged-lost.md` (read it in full first).
Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash (Go is not on PATH).

## How
- **Read-only on the copy and the branch:** change no tracked file, commit nothing, push nothing. Probes and
  scratch tests live in a new folder `C:\Users\trabi\Claude\Projects\Telegram\wt-b5-review-S-scratch` (copy a
  test file into the package only for a run and remove it after, or use `go test -overlay`; the copy must be
  clean when you end: say so).
- Read the brief, then the whole difference (`git diff 698ee15d..HEAD`), then the code around it as far as
  a doubt takes you: `internal/catalog/schema8.go` and `staging.go` (what writes `file.location`, what
  `WantAgain` and a revive do to `tg_media.file_id`, what the change log says), `internal/store`
  (`StagedName`, the copier's removal step, `sweepStaged`), the viewer's makers and index.
- Judge against the brief and these standing rules: only a content name of a validated hash is ever opened
  in the staging folder, and nothing there is listed, written, moved or removed; the viewer never makes
  the copier's work fail; a staged file never counts towards the library-health rule, found or not, and
  "not there now" never leaves a mark; nothing in the background opens a library file while a copy is due,
  and a person's ask is never held; no request a page depends on waits on the library; nothing
  proportional to the archive per request, per poll or per index update; no new field per media in the
  index; invented data only, and no name, path, hash, id or text in any log line, error, counts file or
  printed line; no Telegram code and no outbound connection in the viewer (the wall tests); nothing depends
  on this PC's absolute paths, the start folder or PATH; a test must not judge real time; every number says
  what it counts.
- **Try to break it.** A finding is **confirmed** only with a probe that shows it or a line-by-line
  argument nobody could doubt; otherwise it is **plausible**, and say what would settle it. Look hardest at:
  1. **The index** (`refresh.go`): a file lost and saved again through the catalogue's own doors
     (`WantAgain`, then `Saved` reviving the row), not by hand-written SQL: does the incremental update
     give exactly what a full read gives, at every step, for states, "saved copy" stand-ins, "each file
     once" and faces? Can the set of lost-linked media grow without bound or go stale? What does each
     index update now cost on a catalogue of 600,000 media and 500,000 file rows with none lost (measure
     the full read's new pass and an update with nothing new; `tgarchive fabricate` makes invented
     catalogues: say the sizes you used)?
  2. **The staged open** (`staging.go`): every way to make it open or hand a helper program something
     other than the staged bytes of that row (a link or junction as the two-digit folder or as the file, a
     file swapped between the look and the open, a size that changes, a hash with upper-case or odd
     characters, a name with a path in it, the staging folder itself being a link, the staging folder being
     the library or inside it or holding it, the data folder inside it). The symlink case could not be made
     on this PC by the coder: try a junction (`mklink /J`, no rights needed) and say what you could make.
  3. **The copier's side:** with the viewer holding a staged file open (a person's download in progress, a
     maker, ffmpeg and mpv handed the path), does the store's removal succeed, and when it does not, does
     anything of the viewer keep a file alive, or keep reading bytes of a file whose row now says library
     at another size? Read the store's code; run the viewer's side on Windows.
  4. **The health rule and the marks:** runs of staged files, of staged files that are not there, of a
     staging folder that disappears mid-run, mixed with library files that are really missing: does the
     rule trip when it must not, or fail to trip when the library really lacks its files? Can a staged
     file that fails every time (unreadable, or not a picture) make a hot loop, or be retried without bound
     faster than the walk's pace?
  5. **Giving way to copies:** is a person's ask (a tile, an open, a player, the home-network listener)
     ever held or slowed by it; is any background path left that opens a library file while a copy is due
     (the walk, fresh files, `recheck`, `whileMissing`, the second thumbnail folder, the health sample, a
     converted copy for a browser); what happens when the queue never empties for days (memory of the
     held-for-later list, the walk's position, the counts); **how long does a staged file far down the
     walk's order wait for its thumbnail while copies are due, at 600,000 media** (give the number and how
     you got it); what the copy-queue query costs on a queue of 100,000 rows of which none is due.
  6. **The pages and the words:** every new string a page or a console can show is one of a closed set of
     fixed words; the home-network access classes are unchanged for a staged file; the Settings sentence
     and the fixed line appear exactly where the brief says and nowhere a library file is concerned.
  7. **A catalogue from before step 8**, and one stepped to it while the viewer runs.
- **Known to the main session already (do not spend probes on proving them; say only if they are worse than
  stated):** while the library is unreachable or marked "files missing" the workers sleep, staged work
  included (to be changed in the fix round: staged files go on); a staged file whose read fails is retried
  each walk round without a mark; "not there now" answers 404 with no hint of when to ask again.
- **Privacy and load:** never start the owner's viewer, window, collector or old app; never open the owner's
  catalogues, library, staging folder or any real media (nothing under
  `%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b`, `%LOCALAPPDATA%\tgarchive`,
  `E:\T`, the NAS). `GOMAXPROCS=2`, `go test -p 1`, `GOGC=50`, named tests and your probes only, free memory
  checked first (wait while under 2 GB); no whole run of `internal/viewer`, no race detector (the main
  session runs both once, after the fixes); no Docker; never any cache clean-up or prune.

## Hand back, as your last message
Write `REVIEW.md` in your scratch folder (**no path of this PC in it**: name files relative to the module or
to your scratch folder) and give its content: a verdict in three lines; the findings worst first, each with:
confirmed or plausible, the file and line, what happens and to whom, the probe (its file in the scratch
folder and what it printed), and the smallest fix you would accept; then "Checked and sound" (what you tried
to break and could not), "The tests the hand-back leans on" (which of the coder's tests would still pass
with the defect present), the numbers asked for above, and "Not run". No praise, no summary of what the code
does.
