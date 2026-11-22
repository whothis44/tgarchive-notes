# Review B7-W2: the one window (the joined mode of `tgarchive-window`; `wip/b-onewin` 3c504d2c against b0c1c970)

One independent Opus security and correctness reviewer, read-only on the reviewed copy, 11-16 about 19:25 to
19:53; written down by the viewer session B7 from its hand-back (the reviewer could not write files). It read
all of the new code and the viewer's page scripts; it started no window. Plants in its own scratch copy
`wt-b7-review-W2-scratch` (left in place, clean); its scripts and logs: `runs-b7/review-W2-reviewer`. The
session's decisions are at the end.

## Verdict: MAY BE LISTED AFTER THESE FIXES

## Findings, most severe first
1. **Medium.** `internal/window/pages_windows.go` 445, `pagesNewWindow`: a new-window request is followed when
   `mayShow` allows it, and in the joined mode that also covers the viewer's address. (i) The viewer's "Open
   the saved copy" button (`web/js/item.js` 511, a new-window link) now loads the raw file into the window
   itself, with no header and no way back (the viewer's window alone refused that request). (ii) The window
   follows such a request with its own navigation, which carries no other-site mark (reasoned, not
   measured): a named page could use `window.open` to make the window load viewer addresses that the
   viewer's guard refuses to every other port (`/media/...`, `/api/...`). It cannot read the answer, but it
   can show any archive file and start thumbnail work. Smallest fix: in the joined mode follow a new-window
   request only for the named addresses; refuse the viewer's and count it; a pure function and a test.
2. **Low.** `joined_windows.go` 69, `startGate(set.hosts())`: the real call site has no test (a planted extra
   port there was not caught: the test builds its own gate; the self-check probes its own third port). Fix:
   one function makes the list for both.
3. **Low (tests).** `appurl_test.go`: a planted "accept a path" was not caught (the one path case lacks the
   final slash). Add `.../x/` and `...//`. The code itself is exact.
4. **Low, not verified.** The window's posts to the page (play state, ended, failed: media ids and positions)
   go to whatever document is shown; one arriving after a navigation to a named page would reach the app's
   page. Fix: in the joined mode post only while the shown document is the viewer's.
5. **Low.** The self-check's step "a clip played, the video area hidden on navigation" was not built (it says
   "not run" even with a player named). The plain test covers the rule.
6. **Low.** The joined mode's 10 s watch ends with `os.Exit(3)` and skips the viewer's stop: its last counts
   are not written. No harm beyond that (the catalogue is read-only).
7. **Low, for later.** Cookies are per host, not per port, and the collector's pages now share the viewer's
   engine profile. Today neither program sets a cookie on 127.0.0.1 (searched). A cookie added later by the
   collector would be sent to the viewer's port. Rule: no cookie on 127.0.0.1, or a wall test for it.

## The answers, in short
1. **Reach:** the gate's set is fixed once before the engine starts and is exactly the viewer's address plus
   the named ones; the early listener only accepts; the gate is still the only place that dials (the wall
   tests pass); redirects go through the navigation rule, page parts through the gate; the browser fallback
   is unreachable in the joined mode; processes started: mpv only.
2. **The two origins:** a named page gets nothing through the channel to the player (dropped by source;
   plant caught); the viewer's pages cannot be framed. **No text from data becomes a link or a navigation
   anywhere in the viewer's scripts** (every address is a fixed path with numeric ids; text goes in as text
   only), so a message holding a local address stays plain text: no new rule needed. The viewer's GET routes
   are read-only. Storage is per origin with the port; cookies are shared (7); no opener exists.
3. **The small page and the hand-off:** the failure's words and the app's link are escaped; the Host check is
   exact; `/api/`, `/media/` and anything but GET or HEAD get 503; timeouts bound a slow client; no
   connection is lost or leaked at the hand-off (at most one already being served still gets the small
   page); the viewer's own server, guard and headers serve the handed-over connections; the Host names it
   takes are those of its own listen.
4. **Flags and codes:** `-addr` is exact; the old modes' tests pass; the one changed test is right; 7 only
   from a taken port; 3 only from no window; 4 and 6 as before; a failing archive does not end the window.
5. **The app's address:** exact; it reaches only this PC's page flags, never another device's (plant caught).
6. **The guard after the close:** set only just before the window is destroyed, so it cannot hide a failure
   while the window is open.

## Plants
Caught by named tests: the rule allowing any local port; a named page's message handed to the channel; the
video not hidden on a new document; the small page unescaped; the small page answering `/api/`; exit 7 as 1;
the app's link sent to other devices; `-addr` taking `localhost`. NOT caught: an extra port in the gate's
real list (2); the app's address taking a path (3).

## Not checked by the reviewer
Any real window; the other-site mark of the window's own navigation (reasoned); when the window's posts
arrive after a navigation; the launcher's side; whether the joined counts file is complete.

## The session's decisions (B7)
- **1, 2, 3, 4: fixed in one round on `wip/b-onewin`** (the reviewer's smallest fixes, each with a plain
  test).
- **5: accepted and said in the entry** (no clip was played in any real-window run of the joined mode).
- **6: accepted** (lost counts only).
- **7: a rule for both tracks, written on the board:** neither program sets a cookie on 127.0.0.1; a wall
  test for it is owed when either next touches its server.
- The reviewer's answer 2 settles the question I had put first: nothing in the viewer turns a message's text
  into a link.
