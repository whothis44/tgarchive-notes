# Brief B3-16: the viewer found no ffmpeg on the owner's PC (session B3, 11-15)

You are an Opus coder. Work only in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-faces`. First:
`git fetch private wip/b-review2fix && git checkout -B wip/b-ffmpeg private/wip/b-review2fix` (86a397d). Go
module: `archiver/`. Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in each
Bash call. Packages: `archiver/internal/viewer` and `archiver/cmd/tgarchive/viewer.go` only. Commit per part,
pushed to `private` as `wip/b-ffmpeg` (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`,
ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; no archive numbers).

## What happened (the owner opened the viewer for the first time today; measured by the main session)
The owner: "It loads. The first video I clicked took a long time to play. There's basically no thumbnails
for anything." In that one-minute session the viewer's cache got 9 thumbnails made, all photos, and 70
failure marks, all videos. Cause, proven with a small Go probe: **this PC's PATH has an entry with one stray
quote character (entry 18 of 37). Windows and PowerShell still find ffmpeg (entries 23 and 36); Go's
`exec.LookPath` does not** (`filepath.SplitList` treats the quote as opening a quoted run, so 37 entries
become 18). So `findFFmpeg()` returned "", every video went to `errNoFrame`, and each got a failure mark
that keeps its thumbnail away for a day. The converted copy had no encoder either (501). The old app's
notes blamed "PATH cut at 2,046 characters" for the same symptom (LESSONS section 2); this is the likelier
cause. The owner's starter now puts ffmpeg's folder first in the viewer's PATH and sets `FFMPEG_PATH`, and
the 70 wrong marks were removed by hand; the program must not depend on that.

## What to do
1. **Find ffmpeg robustly** (`ffmpeg.go` `findFFmpeg`), in this order: a new flag `tgarchive viewer -ffmpeg
   FILE` (through `Config`), the environment variable `FFMPEG_PATH` (COPY-CHECKS-STUDY E.7 already names
   it), `exec.LookPath`, then the PATH split on `;` by hand with quote characters dropped from each entry,
   looking for `ffmpeg.exe` (Windows only; elsewhere LookPath is enough). A file named by the flag or the
   variable that is not there is said at start in one plain line and the search goes on. The same for the
   player's encoder lookup (it uses the same program).
2. **A missing tool is not the file's fault.** When there is no ffmpeg (or it cannot be started at all), a
   video's thumbnail gets no failure mark: the answer is `X-Thumb: none` and nothing is written. A failure
   mark is written only when ffmpeg ran and no picture came out. At start, when ffmpeg is found, failure
   marks left by a run that had none are dropped: record in the mark why it failed (one fixed word: `noframe`,
   `decode`, `timeout`, `read`) and drop the `noframe` ones and marks with no word (the old format) for
   videos once, counted in one log line.
3. **Say it on the page.** No ffmpeg: one line on the library page ("Video thumbnails and converted copies
   are off: ffmpeg was not found. Settings says how.") and in Settings / About where ffmpeg was looked for and
   how to name it. The old lesson (TRIED-BEFORE 10): every state says why.
4. **Why a thumbnail failed, as counts.** `/api/stats` thumbs: made, and failed by that fixed word; ffmpeg's
   stderr is read (bounded, 2 KB) and mapped to the word, never logged or shown as text.
5. **A counts-only snapshot the session can read after the owner closes the viewer.** The viewer writes
   `stats-last.json` in its data folder (atomic write) once a minute while something changed and at stop:
   exactly `/api/stats`' answer plus, per route, time to first byte (median and worst) for `/media/{id}/file`
   and `/media/{id}/play`, how many file requests were ranges, the library's open and first-read times
   (median and worst), and how long the first index, the faces read and the looked-at read took. Numbers and
   fixed words only: no id, title, path, address or text. Not served to the LAN listener (it is a file).
   This is for the owner's other complaint, a first video that took long to start, which is **not
   diagnosed**: nothing was measured in that session. Do not guess at a fix for it.
6. **Thumbnail makers on request:** the default of `-thumb-workers` stays; nothing else changes in the
   maker's rules.

## Tests (named, while working)
The PATH with a stray quote (a temp folder holding a stand-in `ffmpeg.exe` after a quoted entry: found);
the flag and the variable win in order; no ffmpeg: a video gets no mark and `X-Thumb: none`; a `noframe`
mark and an old-format video mark are dropped at start when ffmpeg is found, a `decode` mark is kept; the
page line is in the meta answer; the snapshot file has no string that is not in a fixed list of keys and
words (walk the JSON). Then once at the end: `go test ./internal/viewer -p 1` (about 3.5 minutes, in the
background), `gofmt -l`, `go vet ./internal/viewer ./cmd/tgarchive`; the scripts parse as modules. No race
detector, no mutation checks, one go command at a time. The import wall lists what the package may import.

## Rules
- Never open the viewer on real data or any real file, never run ffmpeg on a real file; nothing against
  Telegram; do not touch `repo-archiver`, other `wt-*` folders or other packages. Do not merge into or push
  `claude/charming-feynman-vm2xia`, `wip/b-viewer`, `wip/b-viewer2`, `wip/b-nofaces` or `wip/b-review2fix`.
- Every route is registered with an access class; anything new that names this PC is `classLocal`.
- Concurrent code: say exactly what requests and the makers share that you changed (the snapshot writer is a
  new goroutine: how it stops).

## Hand back (short)
Commits, differences from this brief and why, named tests, whole-package time and result, what is shared
and how it is guarded, doubts.
