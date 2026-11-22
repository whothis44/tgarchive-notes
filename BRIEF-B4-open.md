# Brief B4-1: the first video is slow to play: time the open's steps apart, take the network out from under the library's lock, say "opening…" at once (session B4, 11-15)

You are an Opus coder. Work only in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-viewer`. First:
`git checkout -B wip/b-open f0e3f0c` (the main branch's head; the copy is clean, on `wip/b-hidechat`, which is
merged). Go module: `archiver/`. Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`
in each Bash call. Package: `archiver/internal/viewer` only (Go and `web/`). Commit as you go and push to
`private` as `wip/b-open` (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; no archive numbers in any message).

## What the owner said, and what was measured (counts and timings only)
- 11-15 12:54: "The first video I clicked took a long time to play." 11-15 15:41, on the build of 16376c9:
  "The first video was slow again."
- The viewer's own `stats-last.json` after that use (uptime 67 s, then 187 s):
  - `/media/{id}/file`: 7 requests, all with a range; time to the first byte median 113 ms, **worst 18,079 ms**.
  - `library.open` (188 opens in the first 67 s, the thumbnail makers' among them): median 107 ms, **worst
    23,572 ms**. In the next two minutes: 494 more opens, none slower (95th 177 ms).
  - The first read of an opened file: worst 17.5 ms. The thumbnail route (it asks the catalogue): median 1 ms.
- So: the wait is **opening a file on the NAS in the viewer's first minute**, not reading it, not the
  catalogue, not the video's index. What the numbers cannot say: which step of the open stalled, and whether
  the click waited on its own open or behind another's.

## What the old app already knows (read by the main session; its number beside ours)
- The old app's viewer opens a file for playing with one plain open and one stat of the path, no shared lock
  and no check of the library folder per request (`wt-v12.32/core-service/internal/app/viewer_media.go`
  `handleFile`). **It has no number for the time to a file's first byte from the NAS**: its timings were on
  invented data ("Not measured: the real NAS", `LESSONS-viewer-ix12.32.md` section 5); the owner's words on
  its 12.22 viewer were "slower still to load or play a file". Ours: median 0.11 s, worst 18 s.
- Its lesson, twice (`LESSONS-viewer-ix12.32.md` 3.3 and 4; `TRIED-BEFORE.md` 9): **"the file a click opened
  waited behind" the thumbnails; "no request that a page depends on may wait for slow I/O"** without saying
  so. And the NAS is reached over a Wi-Fi link the old app's copies fill (about 14 MB/s), and this PC's
  network drops out now and then (`TRIED-BEFORE.md` 15, 16).
- What this viewer does today (`media.go`): every `library.open` calls `handle()`, which **holds the
  library's lock across a network `Stat` of the root**; then `os.Root.Open` (on Windows one request per path
  component) and a `Stat`. Three thumbnail makers and the background walk open files at about 2.5 a second
  through the same lock. One slow answer from the share inside `handle()` therefore stalls every open in the
  program, a person's click included. That is a defect whatever the stall's cause turns out to be.

## What to build (four parts, small; nothing else)
1. **The open's steps timed apart** (`media.go`, `stats.go`, `snapshot.go`): for each `library.open`, its
   own ring (count, median, worst, as `spreadJSON`) for (a) getting the root (the wait for the lock, and
   whatever is done under it), (b) the open through the root, (c) the stat. Keep today's total. Add to the
   snapshot, numbers only:
   - slow opens (total over 1 s) counted by seconds since the viewer's start, in fixed bands: under 60 s,
     60 to 300 s, later; and how many of them were a person's (the file route, the play route, "Open in the
     player") against the makers';
   - for the slowest open so far: seconds since start when it began, which step took longest (a fixed word:
     `root`, `open`, `stat`), whose it was (`person` or `maker`), and how many other opens were in flight
     when it began;
   - the root's first check at start (`v.lib.check()` in `New`): its time in ms;
   - for the file route: the catalogue lookup's time apart from the open's (a ring), so the time to the
     first byte can be read as lookup + open + first write.
   No id, name, path or text anywhere; the snapshot's test (the one that allows only its fixed words) is
   extended, not loosened.
2. **No network call under the library's lock, and no check of the root per open.** `handle()` returns the
   kept root at once (the lock guards the pointer only). The check of the root (`Stat(".")`, and opening it
   again when it is gone) is `check()`'s alone: the watcher's every 15 s, as today, with the network calls
   made outside the lock and the pointer swapped under it; an old root is closed only when no open is using
   it (count the users, or let the last user close it). An `open` that fails for a reason other than "does
   not exist" asks for an early check (a non-blocking signal to the watcher; it never checks inline). What
   must stay true, each with a named test: a library that goes away is reported within the watcher's period
   and its opens fail with `errNotFound` without hanging on the lock; a library that comes back is used
   again; `filesMissing` and the makers' "library went away, not the file's fault" branch behave as before;
   nothing reaches outside the root (`localPath`, `os.Root` unchanged).
3. **A person's open goes before the makers'.** While any person's open is in flight (from before its
   catalogue lookup until its file is open or failed), the makers start no new library open (they wait on a
   condition, not a sleep loop, and stop with their context); opens of theirs already in flight are left
   alone. Count how often and for how long in all the makers gave way (two numbers in the snapshot). Not a
   pause for the length of a video: only for the open.
4. **The page says so at once** (`web/js/item.js` where the `<video>` and `<audio>` are made, `play.js`
   where it concerns the converted copy; nothing else): from the moment a file is asked to play (a click
   on play, autoplay, "Original") until its first picture or sound, if nothing came within 400 ms the frame
   shows one line over the poster: "Opening the file from the library… N s" (the seconds counting up, text
   only, `aria-live="polite"`), removed on the first of `loadeddata`, `playing` or `error`; from 10 s on it
   adds "The library is slow to answer." and, on this PC only (where the page already draws it), the
   existing "Open in the player" button. A stall in the middle of playing (`waiting` for more than 2 s)
   shows "Waiting for the library… N s" the same way. No new request, no polling of the server. Same words
   for the phone's pages (the home-network listener), without the button where it is not drawn today.

## Risky parts (the main session reads these first)
- The root's lifetime in part 2: no open may use a closed root, and no root may leak when the library flaps.
- Part 3 must not be able to starve the makers (a person's open that never returns: bound the makers' wait
  by the same deadline the open has, or by the request's context) and must not deadlock at `Close`.
- Nothing here may add a goroutine without a place in the viewer's wait group and an end at `Close`.

## Tests (named, while working; no whole-package run, no race detector, no vet over other packages)
- **No test may judge a span of real time** (board message 25: a test that gave a stand-in one second failed
  under the race detector). Order is proven with channels: a stand-in for the root (a small interface the
  library takes in tests: `Open`, `Stat`, `Close`) whose one call blocks until the test lets it go; the test
  then proves a second open completes while the first is still blocked (part 2), and that a maker's open
  does not start while a person's is in flight and does start after it (part 3). Bounds that exist only so a
  broken build fails instead of hanging are generous (30 s or more).
- The steps' rings and the slow-open bands on known cases with an injected clock (the library takes `now`
  from the viewer; do not sleep to make an open "slow").
- The snapshot's fixed-words test; `TestPageScriptsParseAsModules` for the two scripts (`node --check` alone
  proves nothing for a script with imports); a script-reading test that the new line is text only and that
  the page draws no "Open in the player" where it does not today (`TestLANPageDrawsNoRefusedControls` stays).
- At the end, once: `gofmt -l` on the package, `go vet ./internal/viewer`, and `go test ./internal/viewer
  -p 1` in the background (about 3.5 minutes); say its time and result for the commit that is handed back.
  The race run is the main session's, once, after the review's fixes.

## Load
Other sessions' coders are compiling on this PC. One go command at a time, `-p 1`, `GOMAXPROCS=2 GOGC=50`
for test runs; if free memory is under 2.5 GB (`powershell -NoProfile -Command
"[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`), wait, do not start.

## Rules
- Never open the viewer on real data or any real file; never read the folder of the owner's viewer; nothing
  against Telegram. Invented data only in tests.
- Do not touch `repo-archiver`, other `wt-*` folders or other packages; do not merge into or push
  `claude/charming-feynman-vm2xia`.
- New log lines use constant format strings. CSS, if any, in one block at the end of `web/app.css`.
- Not in this piece: warming the share at start, changing how many makers run, caching file handles, any
  change to the routes' access classes.

## Hand back (short, commit-ready)
The commits; for each of the four parts what was built and any difference from this brief with the reason;
the named tests; the whole-package time and result on the handed-back commit; doubts, and what a reviewer
should try to break first.
