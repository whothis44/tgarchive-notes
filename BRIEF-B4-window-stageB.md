# Brief B4-4, stage B: the pages hand video to the window's mpv (session B4, 11-15)

Same coder, same copy (`wt-b-window`), same branch (`wip/b-window`, on top of d1c9343), all rules of
`BRIEF-B4-window.md`. Stage A is accepted as handed back (its differences too). Now `internal/viewer` may
change, **only as written here**.

## First
`git fetch private wip/b-viewer4 && git merge --no-ff private/wip/b-viewer4` into `wip/b-window` (d4269cc: the
viewer track's joined branch, listed to merge; it holds the main head a0baa06 and changes `play.go`,
`media.go`, `play.js` and `item.js`: read those four as they are now before writing). Resolve `go.mod`/`go.sum`
if they meet; nothing else should.

## The viewer's side (`internal/viewer`, Go)
1. `func (v *Viewer) PathOf(ctx context.Context, id int64) (string, error)`: the full path of a saved video
   or audio file for a player on this PC, by **one function that `handleOpen` ("Open in the player") uses
   too** (not a copy): the index's type and saved state, the catalogue's path and hash for that id, then
   `v.lib.abs(ctx, rel, openPerson)` inside the person's mark (`v.lib.person()`), exactly as `handleOpen`
   does today. Errors are fixed words (not saved, not a video or audio file, cannot be reached), never a
   path. It is a Go method only: **no new route, no change to any route's access class**, nothing a device
   on the home network can reach. `handleOpen`'s own answers and its extension rule for the system's default
   program stay as they are. Count the shell's plays in the viewer's numbers beside `open` (started, failed).
2. The command passes the viewer as the bridge's `PathSource` (your one line in `cmd/tgarchive-window`).

## The page's side (`web/js/play.js` and the video part of `item.js` only)
3. **Is a shell there:** only when `window.chrome && window.chrome.webview` exists the page posts
   `JSON.stringify({type:'hello'})` and listens; it takes only object messages (the binding's echo is a
   string) of the known types; no answer within 1 s, or `mpv:false`, means the browser's own path exactly as
   today. A browser and a phone never see any of this (no request to the server is involved: nothing to
   refuse on the home-network pages).
4. **A saved video with the shell there** (type video; GIF-type clips and audio stay with the browser's own
   elements): the frame keeps its poster; on play (a click, or at once with "Play videos when opened") the
   page posts `play {id, t, rect, muted}` and from that moment shows the existing "Opening the file from the
   library… N s" line; **the shell shows mpv's window only from its first picture** (change that in the
   bridge if it shows earlier today: the line must stay readable while a file on the NAS is slow to open),
   and the line goes at the first `state`. `failed {why}` or no `state` within 30 s: one line in the page's
   words for that `why` (a fixed sentence per word) and the browser's own path takes over (`<video>`, then
   the converted copy), as today.
5. **Around the frame:** nothing the page draws may lie over the frame while mpv shows (its window covers
   it): the close, previous and next controls, the copies strip and any line sit outside the frame's
   rectangle in that state; the page posts `rect` on resize, scroll, a ResizeObserver on the frame and a
   change of resolution, `stop` when the file is left (next, previous, close, a navigation, the page
   hidden), and `fullscreen {on}` for its full-screen control and Escape. mpv's own controller does seeking
   and volume with the mouse; the page's keys keep their meaning: Space posts pause or resume, Left and
   Right post `seek` by 5 s from the last `state`, the others (next, previous, close, the verdict keys) are
   the page's as today. `ended` does what the `<video>`'s `ended` does today. The position is remembered
   when stepping away and back as it is for `<video>` (the last `state`'s `pos`, sent back as `t`).
6. **Every message the page posts is a string of `JSON.stringify` with exactly the keys of its type** (your
   parser drops anything else): one small function builds them.

## The pipe (your doubt 2)
Look in this mpv's manual and option list for a way to hand mpv an already connected pipe instead of a
named one it listens on (`--input-ipc-client`, if this Windows build has it). If it exists and works here,
use it (no listening pipe at all) and show it in the self-check; if not, keep the random name and say so.

## Tests
- `PathOf` and `handleOpen` share the function: the cases `handleOpen`'s tests cover (not saved, a picture,
  a path outside the root, the library away) answer the same through both; a blip (the review's stand-in
  root) gets its one more try through `PathOf` too.
- Script-reading tests in the package's style: the page posts only through the one builder; takes only
  object messages; draws no shell control on the home-network pages; falls back on `failed`.
- The bridge: the child is shown at the first picture, not before (stand-in mpv).
- `-selfcheck` once at the end through **the real pages** on an invented archive (`tgarchive fabricate` from
  this tree with `FFMPEG_PATH`, plus an invented HEVC and an MPEG-4 Part 2 clip put in place of two saved
  videos): open a post, play, the frame's rectangle against mpv's window, a seek by key, next, close; the
  numbers and fixed words only. The PC's load noted.
- At the end, once: `gofmt -l`; `go vet ./internal/window ./internal/viewer ./cmd/...`; `go test
  ./internal/window -p 1`; `go test ./internal/viewer -p 1` in the background (about 3.6 minutes;
  `GOMAXPROCS=2 GOGC=50`, `FFMPEG_PATH` set); `CGO_ENABLED=0 go build ./...`. The race detector is the main
  session's.

## Hand back
The commits (pushed); `PathOf`'s exact rule and what it shares with `handleOpen`; what the page does in each
case of points 3 to 5 and any difference with the reason; the pipe's answer; the self-check through the real
pages; the whole-package results on the exact commit; doubts, and what a reviewer should try first.
