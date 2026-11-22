# Brief B4-4d: the last round for `wip/b-window` after its second independent look (session B4, 11-15)

Same coder, same copy (`wt-b-window`), same branch (`wip/b-window`, on top of ff81d31), all earlier rules.
The second look is `REVIEW-B4-window-2.md` in the project folder: read N1 to N10 and "Not run" in full
first; its probes and its test files are in the scratch folder it names (read-only: take the cases). It
found F1 to F9 gone and every hand-written COM slot right. The main session's decisions:

- **N1 (confirmed; the important one): the picture cap makes mpv hang.** With the fixed options an H.264 or
  HEVC file declaring a picture over the cap makes mpv try its decoders without end; mpv then answers
  nothing, and the window's player is dead for the session with a core busy. Two things, both:
  1. **Find the option set that makes such a file fail at once** (the reviewer saw a clean failure with
     `--hwdec=no`; look in this mpv's manual for what bounds the retry or the fallback from hardware to
     software decoding, and keep hardware decoding for ordinary files if it can be kept). Prove it headless
     with over-cap H.264, HEVC and MJPEG files you make (declared sizes just over and far over the cap) and
     with ordinary HEVC and H.264 clips still decoding on the graphics card.
  2. **A watchdog, whatever the cause of a silence:** a command to mpv that gets no reply within its bound
     (the bridge already waits 5 s) is taken as mpv hanging: mpv is killed and started again (as when it
     dies), the play fails with the why word `player`, and the next play works. Count it. Test on the
     bridge with a stand-in mpv that stops answering; in the self-check, one over-cap H.264 file through
     the real pages: the play fails with a why word, the page takes over, and the next ordinary clip plays
     in mpv.
- **N2 (the download pop-up):** an allowed download is marked handled, so the WebView2 shows no pop-up and
  offers no "Open file" (what it opened would run inside the job, and a saved file can be a program under
  its sender's name). The shell tells the page with one new message `{"type":"saving"}` when it lets a
  download through, and the page shows one plain line for a few seconds: "Saving to your Downloads
  folder." (only where the shell is; a browser keeps its own download bar). Check in WebView2's
  documentation that a handled download with no result path still saves to the default folder; say so.
- **N3 (the player program; in `internal/viewer`, for the browser viewer too):** "Open in the player" starts
  the program the owner named in Settings with a library file's path as its one argument. Two bounds, each
  with a named test and a plain sentence when it refuses: the program may not be under the Windows folder
  (script hosts and shells live there), by its cleaned full path, whatever the case; and the file handed
  to a named program must have a media extension, the same list the system-default path already asks for.
  The Settings page says both under the player's line.
- **N4:** a `stop` that empties a full queue keeps a newly attached mpv's setup (the property observers and
  the click binding): test.
- **N5 to N8:** a new document is taken when it is committed, not at a navigation's start (a refused or
  failed navigation must not stop the play); every settings call's HRESULT is checked and a failure there
  runs the browser fallback rather than leaving the defaults on; without the download interface, downloads
  are refused by the navigation rule or the program says in one fixed-word line that they keep the
  defaults (say which is possible); `QueryInterface` answers only the interfaces each object is; the BOOL
  arguments are passed as values.
- **N9 (tests the round owed):** the over-cap files and the watchdog as above; the 30 s start-up fallback's
  timer on the injected clock (not only a comparison); the job's breakaway flag and the download handler's
  decision each as a unit test of the function that decides (the wiring stays the self-check's).
- **N10:** accepted as it is (the player may leave an outer job that allows it; that is the point).
- **Not changed:** the disc name rule stays as a second layer (the reviewer showed `--access-references=no`
  already stops this mpv's disc readers: say so in the comment).

## Then, in the same round: join the other branch
`git fetch private wip/b-once && git merge --no-ff private/wip/b-once` (b2dfe5b: the library's "each file
once", the browser's click on the video in `web/js/item.js` and `play.js`, the numbers file written when the
console closes; it holds the main head 9dd5a21). Resolve `item.js` and `play.js` keeping both: the
browser's click handler for the browser's `<video>`, your shell path for the window. Check by reading that
the click handler is not attached to anything the shell path draws, and that the window program also ends
cleanly on the console's close signal and writes the viewer's stop snapshot (the command of `wip/b-once`
does this in `cmd/tgarchive/viewer.go`: `cmd/tgarchive-window` must do the same when its window or its
console is closed; a named test of the ending's order as that branch has).

## At the end, once
`gofmt -l`; `go vet ./internal/window ./internal/viewer ./cmd/...`; `go test ./internal/window -p 1`;
`go test ./internal/viewer -p 1` in the background (`GOMAXPROCS=2 GOGC=50`, `FFMPEG_PATH` set);
`go test ./cmd/...`; `CGO_ENABLED=0 go build ./...`; the `-selfcheck` through the real pages once, briefly
(the PC's load noted, nothing left running, the owner's pointer never moved). Hand back: the commits
(pushed); what was done for each of N1 to N9 and any difference with the reason; mpv's final command line;
the self-check's numbers; the whole-package results on the exact commit; doubts.
