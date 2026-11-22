# Brief B4-3: files that are not downloaded, in the library: the saved copy in their place, or left out; remembered (session B4, 11-15)

You are an Opus coder. Work only in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-faces`. First:
`git checkout -B wip/b-notsaved f0e3f0c` (the main branch's head; the copy is clean, on a merged branch). Go
module: `archiver/`. Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in each
Bash call. Package: `archiver/internal/viewer` only (Go and `web/`). Commit as you go and push to `private`
as `wip/b-notsaved` (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; no archive numbers in any message).

## What the owner said (11-15 15:49, using the viewer on the old archive)
"Do the settings save between sessions? For example, seeing not downloaded files in the library isn't useful.
They should be hidden, or they should link to their known duplicates."

## What exists (read first, yourself)
- The library (`library.go`, `web/js/library.js`): tiles are posts; a tile whose file is not saved carries
  the mark "Not downloaded" (or "Probable copy · not downloaded") over Telegram's small preview. The sidebar
  has FILE: Saved / Not downloaded / Held as probable copy (`state=` in the page's address:
  `setSaved|setMissing|setHeldProb`), which is **not remembered**: it lives in the address only.
- The post page already does the right thing for one file (`post.go` `standInOf`, `standInJSON`;
  `item.js` `standInNote`): a file that is not downloaded is shown as **its saved copy from another chat**
  (an exact or a probable copy edge, exact first), with the line "Not downloaded here. Showing the saved
  copy from <chat>, <day>: the same file, proven / probably the same, not proven (evidence) · Open that
  post". And it has a remembered switch for its own files only (`hide_not_saved`).
- Preferences (`decisions.go` `Prefs`, `/api/prefs`, `settings.js`) are kept by the server in the viewer's
  own file for every browser, so they survive a restart: a rule that is to be remembered is a preference.
- Probable copies are folded under the best of them (`fold.go`), and every active filter and hiding rule
  is a removable chip with a count (`library.js`, the chips; `hidden` in the listing's answer).

## What the old app and the lessons already say (read by the main session)
- The owner, 11-07: a copy shown but not clickable was "a major usability hindrance": **every copy links to
  the file it matches** (`TRIED-BEFORE.md` 15). 11-09: the aim is "viewing the media as the most complete
  set, sourced from everywhere it was posted" (`LESSONS.md` 1).
- Every number says what it counts and adds up; a state says why in plain words (`TRIED-BEFORE.md` 10).
- A filter is evaluated once per query and kept; nothing proportional to the archive per click; the
  default library's first load is at its 200 ms budget on the real catalogue already (150 to 190 ms), so
  **this rule may add no walk of edges per request**: it is a bit per file, kept up to date by the index's
  own incremental update (`LESSONS-viewer-ix12.32.md` 4; `TRIED-BEFORE.md` 9).
- Paging keeps its place by a stable key, and the arrow keys follow what is shown
  (`LESSONS-viewer-ix12.32.md` 6): a tile left out must be left out of the keyboard's order and of the
  counts in the same way.

## What to build
1. **One remembered rule, three values** (a new preference `library_not_saved`: `copy`, the default;
   `show`; `hide`), applied by the server when it evaluates a library query:
   - **`copy` (default): the saved copy in their place, the rest left out.** A tile none of whose files is
     saved is kept only if one of its files has a saved copy by `standInOf`'s rule (exact or probable edge
     to a saved file that is in a post). Such a tile shows **the saved copy's picture** (its cached
     thumbnail, as a saved tile does) and carries, in place of "Not downloaded", the mark "Saved copy from
     <chat>" (exact) or "Probably the same, saved in <chat>" (probable), with the full sentence in its
     title; opening it opens the post as today (the post page already shows the copy and "Open that
     post"). A tile with no saved file and no saved copy is left out.
   - **`show`:** as today, every tile, with today's marks.
   - **`hide`:** every tile none of whose files is saved is left out, a known saved copy or not.
   One tile per album: the rule looks at the tile's files together (`Saved == 0` of its `Count`); a tile with
   any saved file is always kept. Folded probable copies stay folded as today.
2. **An explicit choice wins.** When the address names a state (`state=missing` or `state=held`, the
   sidebar's FILE filter), the rule is off for that query: whoever asks for files not downloaded sees them.
3. **A chip with a count, and a way back for this view.** When the rule leaves tiles out, the library shows
   a chip in the existing style: "Not downloaded, no saved copy: N left out" (`copy`) or "Not downloaded:
   N left out" (`hide`); clicking it shows them for this view (`nd=show` in the address, which overrides
   the preference for that query only) and the chip then reads "Showing N not downloaded" with a way to
   leave them out again. The heading's "X of Y posts" and the chips add up: X + what the chips say were left
   out = Y, each post once. The sidebar's counts beside FILE keep counting what they count today.
4. **Settings** (`settings.js`): one group "Files that are not downloaded, in the library" with the three
   choices as radio buttons, each with one plain sentence saying what it does, written through the existing
   preference route; the library redraws when it changes. The post page's own switch stays as it is.
5. **Cost.** Whether a file has a saved copy to show is one bit per file in the index (and which file it
   is, where the tile needs it), computed when the index is built and kept right by the incremental update
   when a file is saved, an edge appears or goes, or a place appears or goes; never a walk of edges per
   request or per tile. The kept result of a query is keyed by the rule too (the preference and `nd`), so
   two values never share a kept listing.
6. The home-network pages get the same rule (it is the server's); a device that may not change preferences
   still gets the chip's way back for its own view.

## Risky parts (the main session reads these first)
- The incremental update keeping the bit right (`refresh.go`): a file saved later must turn its copies'
  tiles from "left out" to "saved copy" without a full rebuild; the package's reference tests
  (`reference_test.go`, `refresh_random_test.go`: an index updated step by step must equal one built
  afresh) must cover the new bit.
- Counts that add up under every combination: the rule with hidden chats, clutter, "each file once"
  (`first=1`), folded probable copies, the chat and topic filters, search.
- The arrow keys and paging over a listing with tiles left out.

## Tests (named, while working; no whole-package run, no race detector, no vet over other packages)
- The three values on a small invented catalogue with: a saved file; a file not saved with an exact saved
  copy elsewhere; one with only a probable saved copy; one with none; an album with none saved and one copy
  known; an album half saved. What is listed, each tile's mark, the chip's count, X + left out = Y.
- `state=missing` and `nd=show` override the rule; the kept listing is not shared between values.
- The incremental update: after "the copy gets saved", "the edge goes", "the place goes", the updated index
  equals a fresh one (extend the reference tests' comparison to the new bit).
- Timing: `TestTimingOnBigCatalogue` by name must still pass with the rule at its default (it is the
  default library's first load: say its numbers before and after in the hand-back). **No new test may judge
  a span of real time**; do not loosen the existing budget.
- The page: `TestPageScriptsParseAsModules`; the script-reading tests for controls a device may not use
  (`TestLANPageDrawsNoRefusedControls`); no `innerHTML` with data.
- At the end, once: `gofmt -l` on the package, `go vet ./internal/viewer`, `go test ./internal/viewer -p 1`
  in the background (about 3.5 minutes): its time and result on the commit that is handed back.

## Load
Another coder is working in `wt-b-viewer` and other sessions are compiling. One go command at a time,
`-p 1`, `GOMAXPROCS=2 GOGC=50` for test runs; if free memory is under 2.5 GB (`powershell -NoProfile -Command
"[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`), wait, do not start.

## Rules
- Never open the viewer on real data or any real file; never read the owner's viewer folder; nothing
  against Telegram. Invented data only.
- Do not touch `repo-archiver`, other `wt-*` folders or other packages; do not merge into or push
  `claude/charming-feynman-vm2xia`.
- The other coder (`wip/b-open`) is changing `media.go`, `stats.go`, `snapshot.go`, `viewer.go`,
  `maker.go`, `web/js/item.js`, `play.js`, `chat.js` and one line of `settings.js` (line 84, the "hidden"
  sentence): stay out of those files where you can, and in `settings.js` add your group as one new block
  away from that line.
- CSS in one block at the end of `web/app.css`. Words on the page are plain: no setting key is shown.
- Not in this piece: remembering the sidebar's other filters; anything that downloads; the Chats page.

## Hand back (short, commit-ready)
The commits; what was built for each of the six points and any difference from this brief with the reason;
the named tests; the timing test's numbers before and after; the whole-package time and result on the
handed-back commit; doubts, and what a reviewer should try to break first.
