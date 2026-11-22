# Brief: the independent review of W3 (the Overview's numbers as links; "Needs you") (pages, P7, 2026-11-21)

Read first: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-P7-review-rules.md` (the house rules: binding).
One difference: W3 is NOT merged; it is `wip/pages-overview` c84c77ed, cut from af4ca40e. Findings are on it.
Test processes: `TEMP`/`TMP`/`LOCALAPPDATA`/`APPDATA` in a folder OUTSIDE any git copy
(`C:\Users\trabi\AppData\Local\Temp\p7-w3rev`): a run refuses an API settings file inside a repository.

**The piece:** what was asked: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-W3-overview-links.md`. The
coder's report: `archiver/docs/progress/pages-overview-REPORT.md` on the branch (its table of every number,
the one new read and its time, the tests). Diff: `git diff af4ca40e c84c77ed` (package `internal/server`
only: `overview.go`, the Overview's, Queue's and Chats' scripts, `places.js`, tests).
**Your scratch copy:** `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-w3-scratch` (detached at
c84c77ed, already made). Report to `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-W3-overview-links.md`.

## Questions, in this order
1. **Every number against its place.** For each row of the report's table that has a place: follow the link
   on the invented archive (headless) and say whether what the place shows agrees with the number, and
   whether the owner could be misled where the report says "not the same rule" (the held probable copies
   linked to the viewer's Probable copies while the count is the catalogue's held files; Saved linked to
   All media). Say which link a person would expect, by the design (`DESIGN-ONE-WINDOW.md` point 4: "2
   probable copies opens their review").
2. **The filters by address.** Every new `show=`, `read=`, `mirror=` value, unknown and hostile values,
   two filters at once, a filter with `dc=`; the chip's "show all" (the address after it, the keyboard's
   place, the back button); the selects and the address kept in step both ways.
3. **The one new read** (`ListChatReads` kept in `needsCache`): its cost at a real size (the coder measured
   25.5 ms at 2,437 chats; try 5,000 chats and 2 M messages as the W1 review did:
   `wt-pages-review-w1-scratch` has its fabricate probe `TestZZW1Scale`), whether the cache can go stale
   in a way a person sees (the report names one: an approval written by another process), whether two
   Overviews open at once or a fast poll multiply the reads, and that nothing reads the library's files.
4. **Live updates** (`repaint`): by reading and, where a headless browser can, by a probe: a number's
   link survives every live answer; nothing is rebuilt under the keyboard's focus; a shape change puts the
   focus back on the same number; no update loop when the viewer's state flips (the page asks
   `/api/shell` again on a viewer change: can that flap?).
5. **Injection and routes:** every value from the server that reaches the new markup (chat counts, the
   list's dead words, addresses): text only, no HTML sink; the viewer links only to the list's addresses.
6. **The look**, headless at 1400x900 and a true 390 px (device metrics, as `TestZZW1CDP` in the W1
   scratch copy), dark and light: the Overview with "Needs you", the Queue and Chats with a chip. Look at
   the images yourself: contrast of the links in the tiles, wrapping, overflow.
7. Anything else you judge a defect: its own number.
