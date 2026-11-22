# Review B8-L1: the launcher starts the app as one window (`wip/b-launch` e9413e4e..c4d0f502; a lent commit in `internal/launcher`)

One independent Opus reviewer, read-only on the copy `wt-b-launch`, 11-16 20:52 to 20:56; written down by the
viewer session B8 from its hand-back (the reviewer cannot write files). It read the change, `present.go`,
`start.go`, `launcher.go` and `ui.go` as far as each question needed; it built and ran nothing. The brief of the
change: `BRIEF-B8-L1-launcher-one-window.md`. The session's decisions and its own look are at the end.

## Verdict: MAY BE LISTED AFTER THESE FIXES: 1, 2

## The answers, in short
- **Other settings:** `viewer` browser or none and `pages_open` browser behave exactly as the base
  (`joinedViewer` is false; `ownWindowSpec` gives the base's two addresses). The front start, the adoption
  and "Try the window again" carry the list of three correctly.
- **The list:** `sameAddrs` sees another length at most once per event (no loop); the stored list is always
  what was started; the base never had three entries, so the test "three, the last no http address" is
  safe. The front start of a joined window ends with 0 before it listens (the instance check comes first).
  The redirect from the launcher's page is not broken; it is armed and logged for a page the joined window
  does not show first.
- **The flag `win.joined`:** set, read and cleared under the window's lock; the settings are never read
  while that lock is held; a refusal or an end always passes `rescope(false)`.
- **No viewer started:** `viewerSpec` has one caller, which returns quietly: no line, no note, Quit's stop
  of the viewer does nothing. Nothing claims a viewer failed.
- **The tests:** the two changed ones still test what they tested; the new ones pin the three lines for
  every SETTINGS combination and would catch the three wrong edits asked about; they pin no run-time
  state (the pure test even forces "the window failed" and expects the joined line).
- **Linux, the log:** nothing Windows-only; the new log line is fixed words.

## Findings
1. **Medium-high.** The joined decision is read from the settings in three places (`launcher.go` 501 and 732,
   `present.go` 357) and looks at neither "the window failed in this run" nor a viewer still running.
   (a) The window failed earlier in this run, then the programs start: the collector gets the link, no
   viewer is started, the pages go to the browser: no viewer at all (the base started the viewer's own
   window). (b) A viewer window of its own still runs (it is closed only at Quit): the joined window finds
   the viewer's instance folder taken and ends with 0, which the launcher takes as the person's close:
   the app's pages appear in no window and in no browser, and every later event repeats it. Smallest fix:
   decide once in `begin` (the settings, not failed, no viewer running), hand it to `collectorArgs` and
   `viewerSpec`, store it, and let `windowForPages` use the stored value.
2. **Medium.** `present.go` 812 to 827: a change to the browser on the launcher's page while the window is
   joined ends the window and with it the viewer; the collector keeps a link that leads nowhere; the
   base's viewer window stayed open. Fix: start the viewer's own window there, or say that it is accepted.
3. Low. Exit 7 (the viewer's port held by another program) makes the whole window fall back to the browser
   for the run, where the base showed two windows. Known; nothing was to be built.
4. Low. `start.go` 157: the collector's link uses the address as written, the window gets the normalised
   one; a sign before the port passes the address check and gives an invalid link. Fix: the normalised form.
5. Low. A start that finds a watchdog already running is joined too; the collector's link depends on who
   started it. Harmless; one comment.
6. Low. The setup page still says "The viewer's own window" for the default (`ui.go` 845); and `-first
   viewer` hides the launcher's own statuses ("starting", "the pages could not be made") behind the viewer.
7. Low, not verified by the reviewer. On a fresh folder the catalogue does not exist yet when the window
   starts; the base skipped the viewer there; whether the window program tries again was not checked.

## Not checked by the reviewer
Nothing was built or run; the stand-in fixtures; how the window program uses the second address; whether the
collector accepts a link with a leading zero in the port.

## The session's look (B8, 20:50 to 20:54; the folder built from c4d0f502 into a copy outside every repository, its own ports)
- **The copy's own program, started by its full path from another folder, REFUSED to start anything:** "The
  VPN adapter named in the settings is not on this PC" (the default name; no adapter like it is on this PC
  at this hour; "nothing was started, nothing was sent"). It showed its page in its own window (the plain
  line). The session did not point it at another adapter: the real collector was NOT part of the look.
- **The joined line by hand, exactly as `windowLine` builds it** (the pages first, the launcher's page
  second, the copy's catalogue, library and staging, `-addr`, `-first viewer`, no `-data`), with the pages
  served by the folder's own page program: (a) **on a catalogue that does not exist yet: the window stays
  up and says "The archive could not be opened. The catalogue file is not there ..." and never tries
  again** (the viewer's api stayed 503 after the catalogue was made): finding 7 is REAL; (b) on the
  catalogue once made: the viewer answers, the list has 15 entries, "Overview" leads to the app's pages
  (the first address), not to the launcher's page. A close as a person closes (WM_CLOSE): exit 0; the
  launcher goes on running after its window is closed, as on the head (G18's).

## The session's decisions (B8)
- **1: fixed as the reviewer says** (one decision per start, in `begin`).
- **2: fixed if it is small once 1 is in** (the viewer's own window started when the choice goes to the
  browser); else accepted with a comment and said in the entry.
- **4: fixed** (the normalised form). **3 and 5: comments.** **6: pages' words, told on the board.**
- **7: fixed in the viewer track's own program, not in the launcher:** in the joined mode the window
  program waits up to 60 s for a catalogue that is not there or is being made, before it opens it
  (`cmd/tgarchive-window`); the small page already says "Opening the archive..." meanwhile.
- One fix round, one fresh Opus coder (`BRIEF-B8-L1b-fixes.md`); then the session's read; no second
  independent look unless the round rewrites more than the decision's hand-over.
