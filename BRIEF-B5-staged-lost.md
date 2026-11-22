# Brief B5-S: the viewer knows where a saved file's bytes are (viewer session B5, 11-16)

You are an Opus coder for the viewer track of the new archiver. Work only in the copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-b-viewer` (Go module in `archiver/`). First, there: check the
copy is clean, `git fetch private`, and cut the branch `wip/b-staged` from
`private/claude/charming-feynman-vm2xia` (the main head, 698ee15d or newer). If the copy is not clean, stop
and say so.
Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash (Go is not on PATH).
ffmpeg, where a test needs it: `FFMPEG_PATH` set to the full path PowerShell's `Get-Command ffmpeg` gives.

## Why
Since schema step 8 a saved file's bytes are in one of three places (`file.location`,
`internal/catalog/schema8.go`, read its head comment; `docs/DESIGN.md`, "Rules" under the step-8 tables):
`library` (at `file.path` under the library folder), `staging` (in the collector's local staging folder under
its content name, `<staging>/<first two hex digits of the SHA-256>/<SHA-256>`: `internal/store/writer.go`
`StagedName`; `file.path` is then only the place it WILL have in the library), or `lost` (nowhere: the row
stays, its media are wanted again). The viewer was written before that and still treats every file row as a
library file. This is the roadmap's known defect "Staged and lost files shown wrongly in six places" (row
D5), listed on 11-13 and never fixed. Only `internal/viewer/bulk.go` (the NAS thumbnail run) looks at the
location today.

It did not matter on the old archive (every brought-in file is `library`). It matters on the new accounts:
the owner keeps downloads in staging and lets the copy to the NAS follow (over 1 TB of staging is free; the
copy is Wi-Fi-bound at about 14 MB/s), so at any moment thousands of saved files can be staged. Today the
viewer looks for each of them in the library, finds nothing, and (a) shows a saved file as unreadable, (b)
writes thumbnail failure marks for files that are fine, (c) can trip the makers' library-health rule (20
not-found in a row: "files missing") and stop every thumbnail.

## The places (find every one; these are the known ones)
`internal/viewer`: `media.go` (`mediaInfo` near the `LEFT JOIN file`, the preview lookup, `handleFile`),
`play.go` (two lookups of `f.path`), `maker.go` (`make`, `recheck`'s sample, `catchUp`, the two SHA
lookups), `refresh.go` (the index: "saved" is `file_id` not 0, in four queries), `post.go` and whatever
reads `mInfo`. Run `grep -n 'file f\b\|JOIN file\|file_id' internal/viewer/*.go` and account for every hit in
your hand-back (changed, or why not).

## What to build
1. **A lost file is not saved.** In the index a media whose file row is `lost` gets the state its want row
   gives (as any file not downloaded), never "saved"; it is never opened, never queued for a thumbnail,
   never the "saved copy" another post is shown as (B4's rule), never the one tile of "each file once", and
   never in `recheck`'s sample. A thumbnail already made for its bytes may still be shown (it is the only
   picture left); say what the page shows. Check what `WantAgain` (`internal/catalog/staging.go`) leaves in
   `tg_media.file_id` and write the rule for both cases (still pointing at the lost row, or cleared). The
   change log writes kind 1 for every media of a file whose location changes: show, by a test, that the
   index's incremental update (not only a rebuild) moves a media to "not saved" when its file becomes lost
   and back when the file is saved again. **No new field per media in the index** (it holds about 800 MB
   on the owner's catalogue): "lost" is a state the index already has; "staged" is read from the file row
   at use.
2. **A staged file is saved, and is read from the staging folder.** `Config.Staging` (the staging folder;
   empty: none) and the flag `-staging FOLDER` on `tgarchive viewer` and `tgarchive-window` (their flag
   lists and help texts; nothing for `tgarchive thumbs`: the NAS has no staging). The folder is opened
   once as a root, read only, like the library's; it is a local disk, so it gets none of the library's
   machinery for a share that comes and goes beyond "not there now". A staged file opens only by its
   content name built from a SHA-256 the viewer validated (64 lower-case hex digits), must be a regular
   file of exactly `file.size` bytes, and nothing else in that folder is ever opened or listed (it also
   holds parts in progress and kept parts).
   - **Every reader takes the right root:** a person's open (`handleFile`), both players (`play.go`: say
     for each whether the helper program gets a path or bytes through the viewer), the makers (`make`).
   - **The copy finishing in between:** a staged open that finds no file reads the file row once more; if
     it is `library` now, the library is opened; if it is still `staging`, the answer is "not there now"
     (a retry-able state, as an unreachable library is; never a permanent failure mark, never counted by
     the library-health rule in either direction: not as "found", not as "not found").
   - **Never in the copier's way:** the copier removes the staged copy after the library's is verified
     (`internal/store/copier.go` near `StepRemove`; a failed removal is only counted and the sweep takes
     the file later: read `sweepStaged` and confirm that in your hand-back). The viewer's own opens of a
     staged file let others remove it while open (Windows: `FILE_SHARE_DELETE`; the store's `openShared` in
     `internal/store/nlink_windows.go` / `osfs_*.go` is the model). The viewer may not import
     `internal/store` (the wall, `wall_test.go`): write the few lines in a per-system file of the viewer
     and add its name to the wall's per-system list with a comment. A test file may import the store to pin
     your name rule to `StagedName`, if the wall tests allow a test's import (they read non-test files);
     say which you did. A helper program handed a path (ffmpeg, mpv) may hold the file against removal for
     as long as it runs: accepted (the sweep removes it later); say so in the hand-back with what you read.
   - **With no staging folder given** (or one that cannot be opened): a staged file is still "saved"; the
     page shows its stored preview or existing thumbnail and one fixed line, "On this PC, not in the
     library yet"; it is not opened, not queued, leaves no mark, and the library-health rule does not see it.
   - **Thumbnails** are keyed by the SHA-256, so one made from the staged copy serves after the copy. The
     background walk and `catchUp` take staged files like any other (from the local disk: this is the
     cheap moment to make them).
3. **`mInfo` and the pages:** where the page needs to know, `mInfo` says where the bytes are (a closed set
   of words: library, staging, and nothing for not saved); "file readable" for a staged file is the staging
   folder's state, not the library's. The post page and the chat page show the fixed line of point 2 where
   a staged file cannot be opened; nothing else changes in what they draw. The home-network listener
   serves a staged file to the same access classes as a library file (`access.go`: no new route, no new
   class).
4. **The background walk gives way to waiting copies** (a rule of the lessons files every step meets:
   nothing in the background reads the library on the NAS while copies wait; the copy and the walk share
   one Wi-Fi link). While the catalogue's copy queue holds a copy that is due (`file_queue`, state `copy`,
   not stuck: read the index `file_queue_due` and what "due" and "stuck" mean in `internal/catalog` before
   writing the query; one indexed existence query, asked at most once every 10 s; no such table: never
   paused), the makers' background work opens no LIBRARY file: the walk goes on with staged files and
   skips library files for later. A person's ask (a tile on screen, an open, a player) is always served at
   once. The counts-only snapshot says how long the walk gave way and how many library files it skipped
   for later; Settings (where the makers' state is already said) gets one fixed sentence while it holds.
5. **Counts:** the counts-only snapshot (`stats-last.json`, the window's numbers file) gains: staged opens
   by who (person, maker), staged "not there now", staged opens that fell through to the library, lost
   media in the index. Numbers only, fixed names.
6. **A catalogue from before step 8** (no `location` column): everything is the library's, as now
   (`bulk.go` shows one way to ask; ask once at open, not per query).

## Bounds
- Only: `internal/viewer` (and its tests), `cmd/tgarchive/viewer.go`, `cmd/tgarchive-window/main.go`, and
  `internal/fabricate` only if no existing option of `tgarchive fabricate` can make staged and lost files
  for your tests (look first: `-real-rows`, `-files`; prefer building the rows in the test's own set-up).
  No schema step, no `go.mod` change, nothing in `internal/catalog`, `internal/store` or `internal/window`.
- **Privacy, hard:** invented data only. Never open the owner's catalogues, library or staging folder
  (`%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b`, `%LOCALAPPDATA%\tgarchive`,
  `E:\T\...`, the NAS), never start the old app, the collector, or a viewer or window on anything but a
  scratch folder of your own with invented files. No error, log line or test message prints a path, a
  name or a SHA-256 from real data; new console lines pass the fixed-words filter (`viewer.LogWord`).
- **Never** `docker builder prune` or any cache clean-up; no Docker at all in this piece.
- **Load:** `GOMAXPROCS=2`, `go test -p 1`, `GOGC=50`; before a test run check free memory
  (`powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB"`) and
  wait while under 2 GB. **Named tests only** (`-run`): the viewer's whole tests take about 5 minutes and
  are the main session's, once, after the review. No race detector from you. Tests do not judge real time.
- New tests, at least: a staged file opens from the staging folder (person and maker) and its thumbnail
  serves after the row turns `library`; the copy finishing between the lookup and the open; a staged file
  removed while the viewer holds it open (Windows: the removal succeeds); no staging folder given: the
  fixed line, no open, no mark; 30 staged files in a row do not trip the library-health rule and leave no
  failure mark; a lost file through the incremental update, there and back; a lost file is nobody's "saved
  copy" and not in `recheck`'s sample; a name in the staging folder that is not a content name is never
  opened (a row with a bad SHA, a wrong size, a folder under the name, a link); the walk gives way while a
  copy is due and resumes, a person's ask served meanwhile; a catalogue without the column; the wall tests.
- Commit as you go on `wip/b-staged` and push it to `private` (never another branch, never `origin`):
  `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no archive numbers in it. A scratch folder of
  your own with a unique name, removed at the end.

## At the end, once
`gofmt -l` on what you touched; `go vet ./internal/viewer ./cmd/tgarchive ./cmd/tgarchive-window`; your named
tests and `go test ./internal/viewer -run 'TestWall' -p 1`; `CGO_ENABLED=0 go build ./...` and
`GOOS=linux CGO_ENABLED=0 go build ./internal/viewer ./cmd/tgarchive`. Hand back, as your last message: the
commits (pushed) and the head; every hit of the grep above with what became of it; for each of the six
points what was built and any difference from this brief with its reason; what a helper program is handed
for a staged file; what the pages show (the fixed words); the snapshot's new names; what you ran and what
it printed (numbers); what you did not test; doubts. Commit-ready, nothing left running, the copy clean.
