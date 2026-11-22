# Brief: the independent review of W1 (the app's own pages in the new look) (pages, P7, 2026-11-21)

Read first: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-P7-review-rules.md` (the house rules: binding).

**The piece:** merged as aa69cd81 (its parent on the head e9413e4e): `git -C <copy> diff e9413e4e aa69cd81`.
A new package `internal/appshell` (`shell.go`: `List(ctx, catalogue, options)` builds the list on the left
from the catalogue: accounts, each account's own chat as "Saved Messages", chats by newest activity with a
state in words, bounded at 200; `assets/shell.css`, `assets/shell.js`) mounted on the app's pages by
`internal/server/shell.go` (routes `/shell/` and `GET /api/shell`), and the pages' `index.html`, `base.css`,
`parts.css`, `main.js` changed for the new look (the top strip with one pill, the list, the content right).
**Later merges touched the same files** (G18, G19 added a "Program" entry and more):
`git diff aa69cd81 af4ca40e -- archiver/internal/appshell archiver/internal/server`. Review the code AS IT
IS ON af4ca40e. **No review was ever made of W1.** The coder's report: `archiver/docs/progress/pages-shell-REPORT.md`.
The design it serves: `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-ONE-WINDOW.md` and `DESIGN-ONE-WINDOW-HOW.md`.

**Where:** your scratch copy `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-w1-scratch` (detached
at af4ca40e, already made). The Go module is in its `archiver` folder. Report to
`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-W1-app-pages-look.md`.

## Questions, in this order

1. **Injection.** Every value from the catalogue that reaches the page through `/api/shell` and the shell's
   script (a chat's name, an account's name, a state word, a count, a link): is any ever set as HTML, put
   in an attribute or a URL unescaped, or used to build a selector? A probe with an invented chat named
   with markup, quotes and `javascript:` text, rendered headless: what the page shows and whether a script
   ran. Same for `main.js`'s new lines (the title, the pill, the selected entry).
2. **The routes.** Who can reach `/shell/` and `/api/shell`: the same gate and address rules as the pages'
   other routes (the one window's gate of e9413e4e, the `-lan` case if the pages have one, a `Host` or
   `Origin` that is not the app's)? Any method other than GET answered? A path that escapes the embedded
   assets (`/shell/../`, encoded forms)?
3. **The list's reads.** `List` on a catalogue of a real archive's size: invent one (the repo has
   fabricate tools, `internal/fabricate`) with, say, 3 accounts and 5,000 chats and 2 million messages if
   cheap, or say the size you used: how long one `/api/shell` takes, how often the page asks for it (a
   timer? every page change?), whether its query uses an index or scans messages (EXPLAIN QUERY PLAN), and
   whether it can hold the catalogue's write lock or slow the collector's writes (the pages open the
   catalogue how?). The bound of 200: what is left out and does the page say so?
4. **Every catalogue state.** An empty catalogue, a catalogue with accounts and no chats, an account with no
   own chat read, a chat with no messages, a chat whose newest message time is missing, a schema older than
   the build (does the shell fail the whole page or only itself?). Each: what the list shows; no script
   error in the console (`TestEmpty*` and the browser test of `internal/server` are the coder's: read
   them, then probe what they skip).
5. **The look, headless.** With an invented catalogue (empty, and filled), the app's pages served by a test
   server, Edge headless: screenshots at 1400x900 and at 390x800, in dark AND light
   (`--force-prefers-color-scheme` or the page's own theme switch if it has one), of the Overview, Chats,
   Queue and Settings. Look at each image yourself: text that cannot be read in one theme (contrast),
   pieces of the old header left, the list cut off or overlapping the content, a page wider than the
   screen at 390, the pill's states. Say what each image shows in a line; keep the files in your scratch
   copy and name them in the report.
6. **What the old pages lost.** Every control and piece of text the pages had before W1 in their head
   (the run controls, "Viewer: set its address", the Overview's links): still reachable from somewhere,
   or gone with no way to it? A list, by name.
7. **The viewer's places.** The list's Library entries link to the viewer's address when `-viewer-url` is
   set: in the one window (both servers behind one gate), do they open the viewer's place in the same
   window, a new window, or the system browser? Without `-viewer-url`: what a click says. Reading only
   where a window would be needed.
8. Anything else in the diff you judge a defect: name it under its own number.
