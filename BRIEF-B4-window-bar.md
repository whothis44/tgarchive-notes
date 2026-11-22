# Brief B4-7: mpv's control bar stays on screen in the window (session B4, 11-15)

Same coder (the native window), same copy (`wt-b-window`), same branch (`wip/b-window`, on top of 65d20f2),
all earlier rules (Go through `env-archiver.sh`, `CGO_ENABLED=0`; the load measured in a command of its own
before each go command; named tests while working; no test judging real time, none starting a real mpv or
WebView2; mpv's manual read as it is today; invented data only; never the owner's folders; the self-check
once, briefly, at the end, nothing left running, the owner's pointer never moved; push only `private
wip/b-window`).

## What the owner said (11-15 19:42, the first use of the window on the old archive)
"It works ... one video was a bit harder to play, since the progress bar kept disappearing. It was on screen
as long as I moved the bar, but then would disappear, even if I moved the bar to the bottom where it should
be. The same video was fine when I opened it again a minute later, and other videos were fine."

## What the numbers of that use say (the window's own counts)
5 plays, 0 failed; play to picture median 260 ms, worst 580 ms (files on the NAS); one mpv, no restart, no
message dropped. So mpv's controller answers the real mouse (the thing no check could show), and for one
play its "the pointer is over the bar, stay" did not hold: the bar hid by its timer although the pointer
was on it. Why is not known (mpv's own hover state in an embedded, enabled child window; a mouse-leave it
got; its picture size against its window for that file): no session can move the owner's pointer to find
out.

## What to build
1. **The bar is always there.** mpv's on-screen controller is set so that it does not hide: read this mpv's
   manual for the controller's options (its script options: visibility, layout, whether the video is boxed
   so the bar does not cover the picture, the bar's size and scaling in a small window) and choose the set
   that gives a bar at the bottom of mpv's window that is always shown and does not lie over the picture.
   Pass them on the fixed command line (the manual's way for script options with `--no-config`); list the
   final line in the hand-back. The click on the picture still pauses; the bar's own buttons and seek bar
   keep their clicks. In full screen the same bar.
2. **Find out what you can about the cause, without the pointer:** at each play's first picture read from
   mpv what it thinks its window and picture sizes are (the properties for the OSD's dimensions and the
   video's output size) and compare them with the size of the child window the shell gave it; count plays
   where they differ by more than a pixel (`window-stats.json`, one number), and if they can differ, make
   them agree (say how). In the self-check: several clips of different shapes one after another (16:9,
   9:16, 4:3, a very small one), a resize between them, and the comparison each time.
3. **The page:** nothing the page draws for the window's player duplicates the bar (no second seek bar);
   the line under the help list about the arrow keys stays.

## Tests
- The command line's new options in the arguments' test; the size comparison's count on the bridge with the
  stand-in mpv (it reports sizes that differ, then agree).
- The self-check through the real pages once: the clips of point 2; the bar's options accepted by mpv (no
  option error in its log); the click on the picture still pauses. What only a real pointer can show (the
  bar staying under the pointer, its buttons) is said as "for the owner".
- At the end, once: `gofmt -l`; `go vet ./internal/window ./cmd/tgarchive-window`; `go test ./internal/window
  -p 1 -count=2`; `CGO_ENABLED=0 go build ./...`.

## Hand back (short)
The commits (pushed); the controller's options chosen and why, with the manual's words for each; what the
size comparison found; the self-check's numbers; doubts.
