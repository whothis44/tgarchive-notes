# Brief B4-9: mpv's bar hides again, plainer; a play ended by the window closing is not a failure (session B4, 11-15)

Same coder (the native window), copy `wt-b-window`, branch `wip/b-window` on top of 1aa9ac4 (`git log -1`
first: the main session joined the thumbnail piece and the main branch's head into it). Package
`internal/window` and `cmd/tgarchive-window` only; all earlier rules (the load measured in a command of its
own before each go command; the self-check at the end, briefly; nothing left running; the owner's pointer
never moved).

## What the owner said after using the always-shown bar (11-15 20:18)
"It's mostly good. I think the viewer bar progress/seeking bar itself is kind of ugly and busy, and I did
prefer when it hid."

## What to build
1. **The bar hides again** (the controller's own automatic mode), and it is not boxed under the picture any
   more: the picture has the whole frame. Drop yesterday's always-shown set and the message that put it back
   at each first picture.
2. **Plainer.** Read this mpv's manual for the controller's layouts and options and choose the plainest set
   that still has: play and pause, the seek bar, the time, the volume. No playlist, chapter, subtitle,
   audio-track or window buttons if an option removes them; the slim layouts are the candidates. Keep its
   full-screen button doing nothing of mpv's own (full screen is the page's).
3. **It does not vanish under the hand** (the owner's first complaint: on one video the bar hid although the
   pointer was on it; the cause was never found): a longer hide time than the default half second (about
   2 s), and **while the video is paused the bar stays shown** (the bridge already hears `pause`: switch the
   controller's mode by its script message at each change, and back to automatic when playing). Say what
   else in the controller's options bears on "the pointer is over the bar" (its dead zone, its minimum
   mouse movement) and set what the manual says helps.
4. **Two pictures for the owner to choose from:** in the self-check, with an invented clip paused so the bar
   shows, save a picture of the program's own window's client area (not the screen: the window's own
   content only, by its handle) for the set you chose and for the plain default layout, as
   `C:\Users\trabi\Claude\Projects\Telegram\window-bar-chosen.png` and `window-bar-default.png`. Invented
   content only. If the window's content cannot be captured by its handle (the WebView2 and mpv draw with
   the graphics card), say so and save nothing rather than capturing the screen.
5. **A play that is ended by the window closing, the page leaving or a new file is not a failure:** the
   owner's last use counted `plays_failed: player 1` for a video that had its picture after 572 ms and
   was playing when the window was closed. Such a play counts as stopped (a new count beside ended and
   failed); `player` stays for an mpv that died or hung under a play.

## Tests
The command line's options in the arguments' test; the bar's mode following pause on the bridge with the
stand-in mpv; a play stopped by the close counted as stopped. The self-check once at the end through the
real pages. Then: `gofmt -l`; `go vet ./internal/window ./cmd/tgarchive-window`; `go test ./internal/window
-p 1 -count=2`; `CGO_ENABLED=0 go build ./...`.

## Hand back (short)
The commits (pushed); the options chosen with the manual's words; whether the two pictures were saved; the
self-check's numbers; doubts.
