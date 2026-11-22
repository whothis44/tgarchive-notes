# Brief B4-4c: the fix round for `wip/b-window` after its independent review (session B4, 11-15)

Same coder, same copy (`wt-b-window`), same branch (`wip/b-window`, on top of d59160a), all earlier rules.
The review is `REVIEW-B4-window.md` in the project folder: read F1 to F10, "Checked and found sound" and
"Not checked" in full first; its probes are in the scratch folder it names (read-only: take the cases,
write your own tests in the package). The main session's decisions, every finding fixed:

- **F1 (downloads):** a `DownloadStarting` handler. A download is let through only when its address is our
  own origin and its path is one of the viewer's own file routes (`/media/{id}/file`, as the pages' "Save
  the file" and "Download the file" links ask: read which routes the pages link with `download`); anything
  else (`blob:`, `data:`, another path, another origin) is cancelled and counted by a fixed word. Check in
  WebView2's documentation, as it is today, which interface and vtable slots this needs with the pinned
  binding (the review names ICoreWebView2_4) and what the default download dialog can then still do; say it
  in the hand-back. Self-check: a `blob:` download with a `download` name is refused and no file appears in
  a folder the check can see (do not look into the owner's real Downloads folder: point the WebView2's
  default download folder at the self-check's temporary folder for that run if the API allows, else count
  the handler's refusals only and say so).
- **F2 (the job kills what must outlive the window):** the job allows breakaway, and exactly two launches
  break away: the player of "Open in the player" (`internal/viewer`'s detached start, used by the browser
  viewer too) and the browser fallback. **A program that is in a job which does not allow breakaway fails
  to start with that flag** (the browser viewer may itself be started inside such a job): try with
  breakaway, and on that refusal start once more without it; a named test for the choice of flags and the
  retry (a stand-in starter; no real process needed), and the review's probe as a self-check step (a
  child started the detached way outlives the program; mpv and the WebView2 processes still die with it:
  run the job test again and report the counts, since a job that allows breakaway must not let Chromium's
  own children escape).
- **F3 (a new document):** a `hello` (and a navigation or reload the shell sees) ends the old document's
  play and its full screen before anything else: mpv stopped, the child hidden, the window's frame put
  back. Test on the bridge with the stand-in mpv; in the self-check: reload while playing and while in full
  screen.
- **F4 (the fatal guard holds the log's lock):** the guard's `Write` only notes the failure and returns; the
  fallback runs on the UI thread afterwards. Nothing may block inside a log writer. Test: a log line
  written from another goroutine while the guard handles a fatal line returns.
- **F5 (close during the embed):** a close while the WebView2 is being embedded ends the program cleanly
  (the job's cleanup, the viewer's `Close`); after 30 s without the controller the browser fallback runs.
  The 30 s on an injected clock in its test.
- **F6 (disc readers and file names):** the library keeps names that came with the files, so this is
  reachable. `checkPath` refuses a file whose name ends in `.ifo`, `.bup`, `.bdmv`, `.mpls`, `.clpi`,
  `.m2ts` only when it sits in a `BDMV`/`VIDEO_TS` tree (decide the exact rule from what this mpv's stream
  handlers look at: read its manual and log at `--msg-level=all=debug` on invented files, and say the rule),
  with the why word `format` (the page then falls back to the browser's path). If this mpv has options that
  switch its disc and device stream handlers off (look for them; the review saw `ifo_dvda`, `ifo_dvdnav`,
  `bdmv/bluray` tried before `file`), add them to the fixed command line and show in the self-check's log
  count that they are no longer tried. Hostile cases in the self-check: a real small DVD-style `VIDEO_TS`
  tree and a `BDMV` tree made with invented clips if ffmpeg or a few written bytes can make ones those
  readers accept; if they cannot be made here, say so and keep the name rule.
- **F7 (browser keys):** the browser's own accelerator keys off (reload, print, find, history, zoom), after
  reading in WebView2's documentation what that setting leaves on (text editing, the clipboard, the page's
  own key handlers must keep working: the self-check sends the page's Space and arrows again).
- **F8 (a dropped stop):** a `stop` is never dropped: when the queue is full it empties it and goes first;
  drops of other commands are counted by a fixed word. Test.
- **F9 (a relative mpv path):** `-mpv` and `MPV_PATH` count only when they are full paths; otherwise they
  are ignored with one fixed-word line. Test.
- **F10 (a huge picture):** a cap on a decoded picture's size in mpv's command line (the review suggests
  the decoder's `max_pixels`; check the option's name and meaning in this mpv), proven with an invented
  file that declares a size over the cap (refused with a why word) and one under it (plays). Also say what
  bounds mpv's memory for a very long or very high bit-rate file (its demuxer cache options, read and set
  explicitly).

## Also, from the owner's use and the other branch
- The pages' help list says what the arrow keys do while a video plays in the window (they seek; previous
  and next are the buttons): one line, only drawn where the shell is.
- `wip/b-once` (the browser's click on the video; files changed: `web/js/play.js`, `item.js`) is in its own
  fix round: **do not merge it yet**; the main session sends the commit when it is final. Keep your changes
  in those two files as they are (new functions, one-line hooks).

## At the end, once
`gofmt -l`; `go vet ./internal/window ./internal/viewer ./cmd/...`; `go test ./internal/window -p 1`;
`go test ./internal/viewer -p 1` in the background (`GOMAXPROCS=2 GOGC=50`, `FFMPEG_PATH` set) only if this
round changed `internal/viewer`'s Go code (F2 does: the detached start); `CGO_ENABLED=0 go build ./...`; the
`-selfcheck` with the new steps, once, briefly, the PC's load noted, nothing left running. Hand back: the
commits (pushed); what was done for each finding and any difference with the reason; mpv's final command
line; the self-check's numbers; the whole-package results on the exact commit; doubts.
