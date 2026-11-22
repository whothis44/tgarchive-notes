# Brief: an independent, read-only review of `wip/b-open` (the viewer's library opens) (session B4, 11-15)

You are an independent reviewer. You did not write this code and you are not told what its author or the
main session think of it: read the code and try to break it.

## What to review
The branch `wip/b-open` against `f0e3f0c`, in the git worktree
`C:\Users\trabi\Claude\Projects\Telegram\wt-b-viewer` (Go module `archiver/`, package
`archiver/internal/viewer`, Go files and `web/js`). See it with `git diff f0e3f0c...wip/b-open --stat` and
then file by file. What it was asked to do is in `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-B4-open.md`
(parts 1 to 4) plus two small page fixes (the word "null" on a chat's page; "1 chats" in Settings): read
the brief for the guarantees it names, then judge the code, not the brief.

## Where to look hardest (every finding needs the file and line, the inputs or the interleaving, and what goes wrong)
1. **The library's root and its lock** (`media.go`): can any open use a root that was closed; can a root leak
   when the library goes away and comes back many times; can the lock be held across a call that touches
   the network or the disk; can two checks run at once and both swap; what happens to opens in flight during
   `Close`; is "the library went away" still noticed, and still reported as "not found" rather than as a
   failure of the file (the thumbnail makers must not mark a file as failed for it).
2. **"A person's open goes before the makers'"**: can the makers wait for ever (a person's open that never
   returns, a request whose client went away, a panic between "begin" and "end"); can a counter go negative
   or stay above zero; a deadlock at `Close` or when the context ends; many people's opens at once (the
   home-network listener allows other devices).
3. **The numbers** (`stats.go`, `snapshot.go`): each new number says what it counts and is right on a known
   case; the bands by seconds since start; the slowest open's record under concurrent opens; nothing but
   numbers and fixed words can reach the snapshot file (no id, name, path, address or error text).
4. **The page** (`web/js/item.js`, `play.js`, `chat.js`, `settings.js`): the "Opening…" line appears and is
   always removed (first picture, error, the item closed, stepping to the next file, the converted copy
   taking over); no timer or listener is left behind when the page moves on; nothing it shows is built with
   `innerHTML` from data; the home-network pages draw no control they would be refused.
5. **Tests**: does any test judge a span of real time, or pass only because the PC was quiet; does each
   named guarantee have a test that would fail if the guarantee broke (say which do not).
6. **Three parts added to the branch after the brief was written** (they are in its commits; judge them the
   same way):
   - *A converted copy's speed* (`ffmpeg.go`, `play.go`, `stats.go`, `snapshot.go`): ffmpeg now writes
     progress lines to its standard error and the viewer reads them. Can ffmpeg ever block because that
     pipe is not drained (for the conversion's whole life, also when the person leaves, the stall timer
     fires, or ffmpeg floods errors); is a goroutine or a process left behind on any path; can anything
     from standard error but exact progress lines reach a number, a log or the snapshot (a crafted file can
     put text there); are the speed numbers right on a known case (a seek, a conversion stopped early, one
     that wrote nothing); did the failure words (`failWord`) keep working.
   - *The background thumbnail walk gives way while a converted copy plays* (`maker.go` `nextOr`,
     `giveWayToPlay`; `play.go` `conv`): asked thumbnails must go on; the walk must start again when the
     last copy ends (also when two overlap, and when a conversion fails to start); what the two "gave way"
     numbers count with several workers waiting at once; no busy loop.
   - *Crafted files* (`ffmpeg.go`: the format whitelist on the frame command and on the conversion; the
     output's frame mode): with a real ffmpeg (`FFMPEG_PATH`; this PC has 7.1.1 and a 9.0.2 build, try both
     if you can find both, and say which you ran): does a text file in ffmpeg's concat or playlist format
     under a video's name still make it read another file; do real MP4, MOV, MKV, WebM, AVI, WMV, FLV and
     MPEG-TS clips (make small ones with ffmpeg's test sources in your scratch folder) still give a frame
     and a stream; is every option passed accepted by both builds; can two frames far apart in time still
     make the conversion write frames for the gap. The findings this answers are F1 to F5 in
     `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-review10-scratch\REVIEW.md` (read-only).
   - Two page fixes: `chat.js` (the word "null" under a chat's header) and `settings.js` ("1 chats").
7. Anything that changed the behaviour of code outside these parts.

## How to work (rules)
- **Read-only: do not edit, commit or check out anything in `wt-b-viewer` or any other folder of the
  project.** Prove a finding with a probe test written in your own scratch folder and loaded with
  `go test -overlay` (an overlay JSON that adds your `_test.go` file to the package), run by name with
  `-run`, `-p 1`, `GOMAXPROCS=2 GOGC=50`. Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`
  in each Bash call. No Docker, no whole-package run, no race detector, one go command at a time; before a
  run check free memory (`powershell -NoProfile -Command
  "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`) and wait if it is under
  2.5 GB.
- Never start the viewer on real data, never read the owner's viewer folder or library, never open a real
  media file, nothing against Telegram. Invented data only.
- Mark each finding **CONFIRMED** (a probe shows it) or **PLAUSIBLE** (by reading only), with a severity
  (wrong result or hang for the owner; wrong number; cosmetic) and the smallest fix you would accept.

## Hand back
Write the review to `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-B4-open.md` (findings most severe
first, then what you checked and found sound, then what you did not check) and give a ten-line summary as
your final message: the counts by mark and severity, and the two findings you would fix first.
