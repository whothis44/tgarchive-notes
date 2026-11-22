# Pre-push checklist (ix releases)

Why this file: CI kept failing after pushes for reasons a local run could have caught: test-only **data races** (12.14:
an unguarded append in a test callback, a test assigning `a.dataDir` while background workers read it; 12.16: a
background goroutine reading a package variable that a test's cleanup restores), and **tests that depend on what the
app's background loops do** (12.16: the app's own staging mover copied a file before the test read it). This PC's Go
has no cgo, so `go test -race` cannot run natively, which is why races only showed up in CI. They now can be caught
here: see step 3.

Run all of this **before** `git push`. Each CI run costs 30-50 minutes and the user's attention.

## 1. Format and vet (seconds)
```bash
source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env.sh
cd /c/Users/trabi/Claude/Projects/Telegram/<worktree>/core-service && gofmt -l . && go vet ./...
```
`gofmt -l` must print nothing. In a background command put the `cd` inside the command group
(`{ cd …/core-service || exit 1; … }`).

## 2. Tests natively (about 4 minutes)
`go test -count=1` for `./internal/app`, `./internal/engine`, `./internal/telegram`, `./internal/download`, and
**`./internal/store` whenever `migrate.go` or a schema changes** (12.17: a new index broke its old-schema migration
tests, which drop columns), separately
(a full `./...` piped through `head` hides lines). Windows baseline failures, not regressions: `backup`, `config`,
`dbread`, `faststart`, `fsx`, `hash`. Known flaky (check alone before blaming a change): `TestIx127LibraryReadsByHour`
(global hourly counter), `TestIxMLParallelismSettlesNearTheService` (load), `TestRenderGalleryThumbStill` (fails only
with the WhisperJAV ffmpeg on PATH: no WebP encoder), `TestHistoryBackpressureHonorsConfiguredStallDeadline` (release CI).

## 3. Race detector, like CI (new: `ix-tools/race.sh`)
```bash
cd /c/Users/trabi/Claude/Projects/Telegram
ix-tools/race.sh <worktree> <every package you changed>          # e.g. ./internal/download ./internal/engine
ix-tools/race.sh <worktree> ./internal/app -- -run '<your tests>|<code you touched>' -count=2
```
Runs `go test -race` in the local `golang:1.27.3` Docker image (already on this PC; never pull another image without
the user's OK), worktree and module cache mounted read-only, no network. Verified 11-07: it reproduces CI's 12.16 race
on f5d0a49 and passes on the fix. The download package takes ~95 s under `-race`; all of `./internal/app` ~25 min, so
for app run your own tests plus the tests of every file you touched, or run the whole package in the background
while you write the changelog.

## 4. Read your new tests for these patterns (they caused every CI-only failure so far)
- **Package variables changed by a test** (`old := x; x = …; t.Cleanup(restore)`): is `x` read by any goroutine,
  background loop, or anything started by `ixTestApp` / `newConfiguredTestApp`? If so, read it once *before* starting
  the goroutine, or make it an atomic, or don't change it in the test.
- **Fields of `App` or a library assigned in a test** after the app started (`a.dataDir = …`,
  `a.library.StageHold = …`): background workers read them. Set them before starting, or not at all.
- **Callbacks appending to shared slices** (`OnStaged`, hooks): guard with a mutex.
- **The test app runs background loops** (`ixBackground` list in `ix_queue.go`: staging mover, held copies, previews,
  …). A test that expects a file, row or state to stay put must stop the loop that would touch it (e.g.
  `ixStagingRunnerOff`, `ixVdupBackground`) or tolerate it. Run new tests with `-count=5` to see flakes.
- **Goroutines that outlive the test** (background removals, timers): they must not read test-modified globals.
- **Time and machine load**: no assertions on how fast something happens under a loaded full run.

## 5. Release hygiene
Version in `core-service/internal/version/app.go` and `docs/archive-data-sample/data/manifest.json`; CHANGELOG in two
identical copies (`cmp CHANGELOG.md core-service/internal/webassets/public/CHANGELOG.md`); repo files LF; invented test
data only; any new `ixLog` with a constant format string; report lines numbers only. Commit with
`git -c user.name=Claude -c user.email=noreply@anthropic.com commit …` ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Push and PR only with the user's OK; tag/publish only with
the user's explicit OK for that version.
