# Brief B5-T: every thumbnail made in the background (viewer session B5, 11-15)

You are an Opus coder for the viewer track of the new archiver. Work only in the copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-b-faces` (Go module in `archiver/`), on a new branch
`wip/b-thumbsbulk` cut from `private/wip/b-window` (3244f0d: the main head plus the listed entry 19).
Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash (Go is not on PATH).

## Why (the owner, 11-15 20:25)
"The longer fix for the thumbnails is that the viewer, or another app on the NAS, creates them all in the
background." Earlier the same day: "Faster, and probably built on the NAS directly as part of the
downloader we're also constructing."

## What is already known (read before you design; do not rediscover)
- The old app made a video's thumbnail on first view and worked ahead only while its staging backlog was
  small, which was rare: 254,000 videos had almost none, and tiles waited up to 3 s on ffmpeg reading the
  NAS over Wi-Fi. Its lessons: thumbnails made ahead; no request waits on the library; failures
  remembered; the picture is checked, not ffmpeg's exit code (`LESSONS-viewer-ix12.32.md` 3 and 4,
  `repo-archiver/archiver/docs/LESSONS.md` section 2: read both sections).
- This viewer today: `internal/viewer/maker.go` (read its head comment in full), `thumb.go`, `ffmpeg.go`.
  Makers work behind the pages; the owner's window runs them paced (one background job at a time). Measured
  on this PC against the NAS over Wi-Fi: about 0.43 s a thumbnail, about 2.5 a second with three makers, so
  the library's 241,149 saved pictures and videos take about 27 hours. A thumbnail asked by a tile took
  3.0 s at the median before it was made.
- The library is on a NAS over Wi-Fi that the old app's copies also use: a background reader on this PC
  competes with them (`TRIED-BEFORE.md` section 8: read it). On the NAS itself nothing crosses the Wi-Fi.
  ffmpeg on the NAS was judged "slower for little gain" on 11-09 for fingerprints (whole decodes); for one
  frame per file nobody has a number: **your piece must produce that number in one short run.**
- On the owner's NAS every container runs in host network mode and reads a share only as user `1000:10`
  (`archiver/deploy/nashelper/compose.yaml` is the model; NAS memory is tight).
- The product ends as one program with its own folder (board message 40): nothing in product code depends
  on this PC's absolute paths, the start folder, PATH or a script.

## What to build
1. **A headless command, `tgarchive thumbs`** (`cmd/tgarchive/thumbs.go`, registered like `viewer`), using
   the viewer package's own makers and cache layout (same file names, same two sizes, same failure marks,
   same picture check), through one exported door in `internal/viewer` (your design; no second copy of the
   making code). Flags: `-db FILE` (catalogue, opened read-only through the schema door the viewer uses)
   or `-list FILE` (see 2); `-library DIR`; `-out DIR` (default with `-db`: the viewer's own thumbnail
   folder for that catalogue, so the viewer has them with nothing to set; required with `-list`);
   `-workers N` (default 2); `-ffmpeg`; `-limit N` (stop after N were made or failed: the short measuring
   run); `-sizes grid|both` (default both, as the makers make today: check what they make and keep it).
   - It walks every saved picture and video, newest post first, skips what exists or carries a failure
     mark younger than the makers' own retry time, and ends by itself when the walk is done.
   - Output: **numbers only, constant format strings**: one progress line at most every 10 s (done, of,
     made, already there, failed by word, a second), and a last block with the same counts, the seconds,
     the median and worst seconds per made thumbnail, and bytes read from the library. Never a file name,
     a path, a SHA-256, a chat or an id, in any line or error.
   - Ctrl+C, SIGTERM and a closed console end it cleanly within seconds (the viewer command's signals);
     what was made stays; the next run goes on (resumable by skipping, no state file).
   - A library that is not there or lacks its files stops the run with one plain sentence instead of
     marking every file failed (the makers' existing health rule: use it, do not weaken it).
   - It serves nothing and makes no connection.
2. **A work list for a machine without the catalogue:** `tgarchive thumbs -db FILE -write-list FILE` writes
   one line per distinct saved picture and video (what the makers need and nothing more: SHA-256, size,
   kind, duration, the path relative to the library root), and `-list FILE -library DIR -out DIR` works
   from it with no catalogue and no SQLite opened. The list holds the library's own relative paths: it is
   written only where the owner says, its name is never printed back, and no test uses a real one.
3. **A second, read-only thumbnail folder for the viewer:** `Config.ThumbsFrom` and a flag `-thumbs-from DIR`
   on both `tgarchive viewer` and `tgarchive-window`. Before a maker decodes a file it looks (one stat
   each) in the viewer's own folder (another program may have made it since the start: a thumbnail made
   by `tgarchive thumbs` while the viewer is open must show without a restart) and then in this folder; a
   thumbnail found in the second folder is decoded as a picture first and only then stored locally. This
   happens only in a maker, never on a request's path (the folder may be on the NAS). A failure mark there
   counts only when its word is the file's own fault (`noframe`, `decode`), never `read` or `timeout`.
   Writes into a thumbnail folder are atomic (a temporary name, then a rename), so no reader ever takes a
   half-written file; check what the cache does today and fix it if it is not.
4. **For the NAS: `archiver/deploy/thumbs/`** (a new folder; model: `archiver/deploy/nashelper`): a
   `Dockerfile` (the static Linux `tgarchive` binary and an ffmpeg; say where the ffmpeg comes from and its
   licence; the helper's image is `scratch`, so an ffmpeg needs a base: choose the smallest sound one), a
   `compose.yaml` (`network_mode: host`, `user: "1000:10"`, the library bound read-only, the output folder
   and the list bound, `read_only: true`, no capabilities, `mem_limit` and `cpus` set low with
   `GOMEMLIMIT`, no port, `restart: "no"`: it is a run that ends), and a `README.md` with the owner's
   steps written for the NAS's Docker app (placeholders, no address or folder of this PC or NAS in it):
   first the measuring run (`-limit 200`), then the whole run. `CGO_ENABLED=0 GOOS=linux go build
   ./cmd/tgarchive` must pass. Do not build or load an image on this PC unless a quick `docker build` is
   needed to prove the Dockerfile; never push an image anywhere.

## Bounds
- Only these: `cmd/tgarchive/thumbs.go` (new) and its test, `cmd/tgarchive/viewer.go` and
  `cmd/tgarchive-window/main.go` for the one new flag each, `internal/viewer` (`maker.go`, `thumb.go`, a new
  file for the bulk door, `viewer.go`'s `Config`), `archiver/deploy/thumbs/` (new). No schema step, no
  `go.mod` change, nothing in `internal/catalog` or any other package. Two other coders work in other
  copies on `internal/viewer`'s conversation files and on `internal/window`: keep out of `conv.go`,
  `chats.go`, `lan.go`, `web/`, `internal/window`.
- The viewer's import wall stays (`wall_test.go`): no Telegram code.
- **Privacy:** invented data only, in tests and in anything you run. Never start the owner's viewer or
  window, never open the owner's catalogue or library, never read a real media file. Anything under
  `%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b` and `E:\T` is out of bounds.
- **Load:** the PC is shared with the running old app and other sessions' test runs. `GOMAXPROCS=2`,
  `go test -p 1`, `GOGC=50`; before any test run check free memory
  (`powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB"`) and
  wait while it is under 2 GB. No busy loops, no runs "under load".
- **Tests while working: named tests only** (`-run`), of what you changed. No whole run of
  `internal/viewer` (about 4.5 minutes), no race detector: both happen once, later, by the main session.
  Set `FFMPEG_PATH` to this PC's ffmpeg for the tests that need it (find it with PowerShell's
  `Get-Command ffmpeg`; Go does not find it on this PATH). Tests of concurrent code must not judge real
  time (two of this track's tests failed on a loaded PC for that): use the makers' injected clock.
- New tests, at least: the bulk run over an invented library makes every thumbnail once and a second run
  makes none; `-limit`; a failure mark is respected; a run on the list equals a run on the catalogue (the
  same files, byte for byte the same names); the viewer shows a thumbnail another program made after its
  start; a crafted or half file in the second folder is refused and made locally; a `read` mark there is
  ignored; no output line holds a name, a path or a hash (scan the captured output against the fixture's
  names); the Linux build.
- Commit as you go on `wip/b-thumbsbulk` and push it to `private` (never another branch):
  `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. No archive numbers (counts of the owner's
  files) in commit messages or code comments.

## At the end, once
`gofmt -l` on what you touched; `go vet ./internal/viewer ./cmd/...`; your named tests; `CGO_ENABLED=0 go
build ./...` and the Linux build of `./cmd/tgarchive`. Hand back, as your last message: the commits
(pushed) and the head; what each of 1 to 4 does and any difference from this brief with the reason; the
exact command lines for the owner (the run on this PC and the two runs on the NAS), every path in them a
placeholder; what you ran and what it printed; what you did not test; doubts. Commit-ready, nothing left
running, the copy clean.
