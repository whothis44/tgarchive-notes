# Brief B3-8: a video the browser cannot play is converted while it plays (session B3, 11-15)

You are an Opus coder. Work only in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-viewer`. First:
`git fetch private wip/b-viewer && git checkout -B wip/b-play private/wip/b-viewer` (fa3c002). Go module:
`archiver/`. Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in each Bash call.
Package: `archiver/internal/viewer` only (Go and `web/`). Commit as you go and `git push private wip/b-play`
(`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; no archive numbers).

## What is asked (FEATURES section 7: listed, so already asked for)
"A video the browser cannot play: converted while it plays, or opened in the system player." Build the
conversion. (Opening the system player from the server is not built: say so in the hand-back.)

## What the old app already has: port it, do not write it anew
`C:\Users\trabi\Claude\Projects\Telegram\wt-v12.32\core-service\internal\app\ix_play.go` (216 lines; read it
in full, and its test beside it if there is one). It was built at 12.20 because Firefox on Windows refuses
HEVC without Windows' extension, 10-bit and 4:4:4 H.264, and MPEG-4 Part 2; the archive then held 339 HEVC
videos, 49 MPEG-4 Part 2, and 25,949 whose codec Telegram did not give. What it does, all to keep:
- one request streams the saved video through ffmpeg to 8-bit H.264 (at most 1280 wide) with AAC sound in
  fragmented MP4, from `t` seconds; asked only by a person's click; nothing made ahead or kept;
- at most 2 conversions at once (a third is refused with 503 and a plain sentence); ffmpeg stops when the
  request ends; a copy left unread for 2 minutes is stopped (write deadline);
- the first H.264 encoder this ffmpeg has, found once (`libx264`, then the graphics card's, then
  `libopenh264`); none: 501 with a plain sentence;
- the first bytes decide the answer: ffmpeg failing at once answers an error (422), not an empty video;
- the file is opened through the library root first (no path outside it); `Cache-Control: no-store`,
  `nosniff`; the child process has no window.

## In the new viewer
- `GET /media/{id}/play?t=<seconds>` in a new file `play.go`: the same checks as `handleFile` in `media.go`
  (the same id, the same "saved and reachable" rule, the same library root and `LibraryDelay`, the same
  foreign-origin refusal and headers as the other `/media` routes; read `server.go` and `media.go` first).
  ffmpeg from the viewer's own finder (`ffmpeg.go`). The process must be started without a console window on
  Windows and killed with the request (`sidefiles_windows.go` shows the package's way of per-system files).
  The slot count and the encoder are fields of the `Viewer`, not globals.
- This reads the library because a person clicked: it is not background work. It must never be asked for by
  the page by itself except as below.
- The page (`web/js/item.js`, the post page's video): when the `<video>` reports an error it cannot decode
  (`error.code` 3 or 4) **or** has loaded data but shows no picture (`videoWidth` 0 with a video track), it
  switches once, by itself, to `/media/{id}/play?t=<where it stopped>` and shows one line under the video:
  "This video's format cannot be played by the browser: a converted copy is playing (lower quality; the saved
  file is unchanged)." A button "Play a converted copy" is always in the video's menu or details line for
  the cases the browser does not report. Seeking in a converted copy: the stream has no length, so the page
  shows its own position bar from the file's known duration and a seek restarts the stream at `t` (the old
  app's media browser did this: look at how `browse.html` in `wt-v12.32` handles `ix/play` and take what
  fits). On 503 the line says "Two converted copies are already playing: close one and try again"; on 501
  and 422 it says so plainly and offers "Save the file".
- `/api/stats`: conversions started, running now, refused, failed at once.

## Tests (named, while working)
With a stand-in ffmpeg (the package's tests already fake ffmpeg for thumbnails: use the same way): the
stream's first bytes and headers; `t` passed on; a third request refused while two run; the slot given back
when the request is cancelled; a stand-in that writes nothing answers 422; no encoder answers 501; a file
not saved answers 404; a foreign origin refused. Then once at the end: `go test ./internal/viewer -p 1`
(about 3 minutes, in the background), `gofmt -l`, `go vet ./internal/viewer`, `node --check` on the changed
scripts. No race detector, no mutation checks, one go command at a time.

## Rules
- Never open the viewer on real data or any real file, never run ffmpeg on a real file; nothing against
  Telegram; do not touch `repo-archiver`, `wt-v12.32` (read only), other `wt-*` folders or other packages.
  Do not merge into or push `claude/charming-feynman-vm2xia` or `wip/b-viewer`.
- CSS in one block at the end of `web/app.css`. Other coders change `item.js` (thumbnails' signal, the
  arrows) and `library.go` on other branches: keep your page changes inside the video's own drawing code and
  a new script file where you can.
- Concurrent code: say exactly what is shared between requests (the slots, the encoder lookup) and how it is
  guarded. The viewer's import wall (`TestWallImports`) lists what the package may import: keep inside it
  or say why it must grow.

## Hand back (short)
Commits, what was ported unchanged and what differs and why, named tests, whole-package time and result,
what is shared and how it is guarded, doubts.
