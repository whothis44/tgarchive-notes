# Hand-over: the fork's archive viewer, 12.32

**State on 11-14 evening: pushed to tg1 with the owner's OK; draft CI-only PR whothis44/tg1#2; CI green on c7debda (CI, Archive features with ffmpeg, Docker all succeeded). Tag `v3.4.18-ix.12.32` only with the owner's OK and only once CI is green.**
- **Commit:** `c7debda` on branch `ix/v12.32` (worktree `wt-v12.32`), on top of the 12.31 tag (195d5c5). One
  commit with the version (3.4.18-ix.12.32), the CHANGELOG in both copies (identical) and the tests.
- **Checks on the final code:** gofmt and vet clean; the full `./internal/app`, `./internal/webassets` and
  `./internal/api` tests pass.
  - The race detector ran on the viewer tests twice each, in Docker with 1.5 CPUs and 3 GB, and passed. At 2 GB
    the race build is killed compiling gotd/td/tg.
  - `tests/ui/viewer_pages.py` passes.
  - `tests/ui/viewer_big.py` timings and the arrow-past-a-part check pass.
  - The independent review was done, and its findings are fixed.
- **Numbers:** in LESSONS-viewer-ix12.32.md sections 5 and 6.
- **Next, only with the owner's OK for 12.32:**
  1. Push `ix/v12.32` to tg1.
  2. Open the draft CI-only PR.
  3. Once CI is green, tag `v3.4.18-ix.12.32`.

  The owner installs it by hand.
- **Not verified:** the real NAS's thumbnail times (2 s per video was an assumption) and the real archive
  (never opened).
- The scratch 12.31 checkout has been removed.

---
(Earlier notes, kept for the record.)

# Hand-over: the fork's archive viewer, 12.32 (written 2026-11-14 16:35, resume at 19:41)

Task (from the session that started this one): the owner says the fork's "new viewer" is "basically busted,
doesn't work at all … painfully slow", while the old viewer (media browser) loads. Find out why, fix it in the
fork for 12.32, with measured before/after numbers on invented data; pre-push checks, challenger review, commit
on the new branch. **No push, tag or publish without the owner's OK for 12.32.** Don't touch `wt-v12.31`,
`wt-v12.30`, the 12.31 PR or its tag.

Read with this: `LESSONS-viewer-ix12.32.md` (findings and lessons for the new app; the owner asked for it,
11-14).

## Where things are
- Worktree **`wt-v12.32`**, branch **`ix/v12.32`**, rebased onto the 12.31 tag `v3.4.18-ix.12.31` (195d5c5, which has the fix for
  tests that measured the build machine's free disk). WIP commit **a1fb541** (local only).
- **Go:** `source ix-tools/env-archiver.sh` worked all along. Another session repointed `ix-tools/env.sh` to an
  intact go1.27.3 at about 16:30 local, so either works now (source it again). Run with `GOMAXPROCS=2 GOFLAGS=-p=2`, plus `GOMEMLIMIT` (1GiB for tests, 2GiB for the full archive)
  and `GOGC=25`. Check free memory first; keep 2 GB free.
- **Invented archives** (scratchpad `C:\Users\trabi\AppData\Local\Temp\claude\71f159c3a9e5d4b9\6837fa25-e406-4e31-9b84-20eee8cbe477\scratchpad\big\`):
  - `full` (real size: 396k media messages, 388k files in the model, 228k distinct, 174k posts);
  - `q1` (quarter size);
  - `run logs full.log` (12.31 baseline) and `q1.log`.
  - The generator is `viewer_big_test.go` (`VIEWER_BIG_DIR`, `VIEWER_BIG_SCALE`, `VIEWER_BIG_SERVE=port`). In
    serve mode it writes empty library files and picture thumbnails for the newest 30k tiles.
  - Note: the generator's reposts can be dated up to 2028 (harmless, same data before and after).
- **Baseline checkout of 12.31:** scratchpad `base1231` (`git worktree add --detach`, b065246). It holds copies
  of `viewer_big_test.go`, `viewer_base_test.go` (the months test) and `tests/ui/viewer_big.py`. Remove it with
  `git worktree remove` when done.
- **Slow ffmpeg stand-in:** scratchpad `fakeff\ffmpeg.exe` (sleeps `FAKE_FFMPEG_MS`, default 2000, makes no
  picture). Use it as `FFMPEG_PATH` to time the thumbnail behaviour.

## Found (details and numbers in LESSONS-viewer-ix12.32.md section 3)
1. (Corrected 19:50: 77 s was with the PC busy; quiet, 9–14 s. See LESSONS section 5.) The viewer process builds the whole model itself: **77 s** before the first page at real size (12.31, 2
   cores). **45% of that (27 s) is reading the image embeddings** (SQLite reading 157k rows in key order, with
   a small cache). The owner's running viewer was seen at 2.2 GB working set (process counters only).
2. It rebuilt every minute while in use, because the archive changes every minute.
3. A tile's thumbnail request waited up to 3 s for ffmpeg over the NAS. With HTTP/1.1's ~6 connections, that
   blocked everything else, including the click that opens a file.
4. Every request re-ran the whole filter: posts page 2 took 2.24 s, a video filter 0.65 s.
5. A whole month came in one answer (1.2 MB for 6k tiles).
6. **Bug:** folded album tiles put months out of order. The grid had 201 month sections for 95 months, and the
   repeated sections stayed empty gaps.

## Done in a1fb541 (all in core-service/internal/app)
- `viewer_index.go`: `vIndexEvery` = 10 min; `firstBuild()`; the embeddings are loaded in the background
  after the index.
- `viewer_query.go`: info answers 503 `{"building":true,"seconds":n}` at once while building (`wait=1` waits).
  Also: the `vEvalCache` (8 kept, singleflight) with month spans and the posts list; months in parts (`limit`
  ≤ 1000, `cursor`, `n`, `next`); `e.first` keeps album tiles in their place's month; tile `tp` (thumbnail
  pending).
- `viewer_media.go`: thumbnails without waiting for tiles (faces still wait 3 s), a newest-first stack of at
  most 256, `waiting()`.
- `ix_browse.go` / `ix_ml.go`: in viewer mode, no sets, suggestions, soft pairs or album suggestions;
  `ixEmbSimLater()` (lazy).
- `app.js`: "Reading the archive… N s" with retry; months in parts of 600 with a watched rest placeholder;
  tiles marked `tp` are asked again up to 3 times (after 4, 8 and 12 s).
- Tests: `viewer_1232_test.go` (months once and in parts; kept evaluations and the viewer model without sets;
  the thumbnail queue). `viewer_api_test.go` and `viewer_open_test.go` were updated to the new behaviour.
  Targeted runs pass: `-run 'Viewer|Ix1219|Ix127Browse|Ix1217View'` and the 3 new tests.
- The months test fails on the 12.31 checkout, as expected.

## Next steps, in order
1. Re-run the full-size measurement on the new code (reuses `big/full`), and compare with `full.log`:
   ```bash
   source ix-tools/env-archiver.sh; cd wt-v12.32/core-service
   GOMEMLIMIT=2GiB GOGC=25 GOMAXPROCS=2 GOFLAGS=-p=2 VIEWER_BIG_DIR=<scratchpad>/big/full go test -count=1 -run 'TestViewerBig$' -timeout 0 -v ./internal/app/
   ```
2. Browser timings, before (in `base1231`) and after (in `wt-v12.32`), one at a time:
   - serve with `FFMPEG_PATH=<scratchpad>/fakeff/ffmpeg.exe VIEWER_BIG_DIR=<full> VIEWER_BIG_SERVE=8799` (in the
     background);
   - then run `ix-tools/pwvenv/Scripts/python.exe tests/ui/viewer_big.py` with
     `PLAYWRIGHT_BROWSERS_PATH=ix-tools/pw-browsers`.
   - Record: the first tile, opening a file, next file, scrolling, posts, chats, and the API medians.
3. Run `tests/ui/viewer_pages.py` against the small fixture (see its docstring) to check the page still works.
4. Version bump (`internal/version/app.go`, `docs/archive-data-sample/data/manifest.json`) and a CHANGELOG entry
   in both copies (no archive numbers).
5. Pre-push checks (PRE-PUSH-CHECKLIST.md):
   - gofmt and vet;
   - the full `./internal/app` tests, plus `./internal/webassets` and `./internal/api` since pages changed;
   - a race run on `./internal/app` limited to the viewer tests, with Docker `--cpus 1.5` (not race.sh as is).
6. An independent challenger review (read-only agent) of the viewer changes; fix what it confirms.
7. Fill in section 5 of `LESSONS-viewer-ix12.32.md` with numbers; report to the session that started this one.
   Ask the owner before any push.
