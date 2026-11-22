# Brief B5-W2: the fix round for `wip/b-winlan` after its independent look (viewer session B5, 11-15)

Same coder, same copy (`wt-b-window`), same branch (`wip/b-winlan`, on top of 58149f87), all earlier rules
(`BRIEF-B5-window-only.md`: privacy, load, named tests, commits). The review is
`C:\Users\trabi\Claude\Projects\Telegram\wt-b5-review-W-scratch\REVIEW.md`: read it in full first; its probes
are beside it (read-only: take the cases as tests of your own). It found no way round the bridge, the
navigation rules or the access classes. The main session's decisions:

- **F1 (confirmed; the one that holds the merge): no path on the console.** `shell_windows.go` logs the
  start error's raw text, which holds the catalogue's full path. The window's lines are fixed words only:
  "window: the viewer did not start" and, when the error carries words, those words. Then go through
  **every** line the window program and `internal/window` can print (`say`, `logf`) and every error that can
  reach `main`'s last `say("tgarchive-window: %v", err)` (a `Close`, a `Shutdown`, a listener error, a flag
  error holding a value): none may carry a path, an address or an error's raw text; map each to fixed
  words or drop the detail. A test with a catalogue in an invented folder of a distinctive name scans
  every captured line for that name (the reviewer's probe P1 is the start).
- **F2: a window closed while the archive is still opening.** `stop` before `start` has set the viewer must
  not leave listeners up or a viewer unclosed: a `stopped` mark under the session's lock; `start`, after
  `viewer.New` and again after the listeners are open, sees it, closes what it opened and returns an error
  of fixed words. Test: stop first, then start, with a stand-in home listener: nothing accepts afterwards,
  the viewer is closed, its numbers written or deliberately not (say which and why).
- **F3: both servers are shut down at the same time**, each with the whole bound, and a server that did
  not finish in the bound is closed (`Close`), so no request of a home device outlives `Stop` while the
  viewer is closed under it. The end is not an error when only the bound was reached by a stream (exit
  code 0, no line). The same pattern is in `cmd/tgarchive/viewer.go` `stopViewer`: fix it there the same
  way (touch nothing else in that file: another coder added one flag line to it). Tests for both with two
  servers holding streaming requests, on an injected or short bound, not on real seconds.
- **F4: `LANRefusalWords` becomes a closed set.** It answers one of the listener's own fixed sentences by
  `errors.Is` against the sentinels (wrap the password error with `%w` where it is built), and one fixed
  sentence for anything else ("Other devices could not be switched on."); the two returns in `listenLAN`
  that build text from another error keep that error wrapped, never as text. A test hands it an error
  holding a path and gets the fixed sentence.
- **F5: a relative `-ffmpeg` or `FFMPEG_PATH` is refused**, as the window refuses a relative `-mpv` and
  `MPV_PATH`: full paths only, after quote stripping, one fixed line saying so, and ffmpeg is then looked
  for in the other places. Never the current folder. The reviewer's probe is the test.
- **F6: the one-folder-up place is skipped when that folder is a volume root** (`C:\ffmpeg\`, a share's
  root), for ffmpeg and for mpv alike, each with a named test. And **the two orders become one:** an
  explicit flag, then the program's own folder (beside, the tool's folder beside, one folder up), then
  the environment variable, then PATH: mpv's order changes to ffmpeg's (board message 40: the program's
  folder first). Say in the help texts and in the hand-back what the one order is. The About page's words
  for where each was found stay kinds of place.
- **F7:** a catalogue on a share that cannot be reached gets the "not there" words too: the Windows error
  numbers the reviewer names, through `errors.As`, only under the catalogue's own prefix.
- **F8:** the window no longer drops the home server's `Serve` error: when it returns anything but the
  server-closed error while the window runs, the viewer is told (one small exported door in `lan.go`) so
  that Settings says other devices are off, in one fixed sentence, and the console gets one fixed line.
  Test with a listener that fails its accept.
- **From "Other notes":** `noViewerText` also refuses Unicode format characters and line and paragraph
  separators; the `-lan` check moves after the first-instance check, so a second start prints only
  "already open". The rest of the notes stay as they are.
- **The 1 s ping goes back to 2 s** (the reviewed value): no number on record shows the shorter one pays,
  and it samples a busy mpv more often before its first picture. Remove the test that only pins the
  constants. Say in a comment where the 7 s of an over-cap file go, so nobody measures it again.
- **A minimised window goes on playing** (the main session's decision, the owner told): drop the
  `visibilitychange` stop in `web/js/play.js` (you may edit that one line and its comment; the review's
  lead 7 found nothing else relies on it: `pagehide`, the window's own navigation handlers and the close
  each stop mpv themselves). The self-check's minimise step then expects mpv to go on (position moving,
  no stop) and the page not to poll the server while hidden. Write under "for the owner" what only a real
  screen shows: a locked screen and a fully covered window now also keep playing.
- **The tests the review says would pass with the defect present:** replace or extend them so each fails
  on its defect: the served-and-stopped test compares `/api/lan`'s `on` with what really listens and holds
  a request in flight over the stop; the "never the current folder" case uses a relative value; the busy
  and sharing words come from a real `New` where a test can make them (a second handle holding the file),
  else say why not.

## At the end, once
`gofmt -l`; `go vet ./internal/window ./internal/viewer ./cmd/...`; your named tests and the ones you
changed; `go test ./internal/window -p 1`; `go test ./cmd/... -p 1`; `CGO_ENABLED=0 go build ./...`; the
`-selfcheck` through the real pages once, briefly (the minimise step, an archive that cannot be opened if
the self-check can show the painted words without a pointer). Hand back: the commits (pushed) and the head;
what was done for each of F1 to F8 and the notes, with any difference and its reason; the list of every
line the window program can print; the one order for ffmpeg and mpv; what you ran and what it printed; what
you did not test; doubts. Commit-ready, nothing left running, the copy clean.
