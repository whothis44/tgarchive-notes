# Brief W1: the shell — one list on the left, in the new look, over the app's pages (pages, P6, 11-16)

**The owner, 11-16 19:30, on what is left of this week's usage (about an hour): "to actually deliver
something, meaning the features that work with the much improved look".** This piece is that look on
the app's own pages. Take the shortest path to something the owner can open; commit and push after
every step that works (the usage can end in the middle of anything: a pushed half is worth more than an
unpushed whole). You are one Opus coder. Work only in the copy and on the branch your start message
names (`wt-pages-shell`, `wip/pages-shell`).

## Read first (all short)
- `DESIGN-ONE-WINDOW.md` and `DESIGN-ONE-WINDOW-HOW.md` in the project folder (the owner's decision and
  how it is built: sections 2, 3, 5 and 9 of the second bind this piece).
- **The picture the owner chose: `design-options/app-look-options.html`, the first option (`id="o-d"`,
  "The combination") and the stylesheet above it.** Take its look as it is: its colours (the `:root`
  variables), the window's top strip (the name, one pill "Collecting · speed · N waiting", "VPN"), the
  list on the left (Overview; Saved Messages; "Library": All media, New, Deleted on Telegram, First
  seen here, Probable copies; "Chats": each with its state in a few words; Settings · Accounts at the
  foot), the content on the right. Invented data only, as there.

## What to build
**A. A new small package `archiver/internal/appshell`** (it imports the catalogue and the standard
library only: the viewer mounts it later and may not import Telegram code or `internal/server`):
- its assets, embedded: ONE stylesheet and ONE script (the top strip, the list, the frame; the strip's
  height and markup fixed here: a later piece puts the window's own buttons into it);
- one Go builder `List(ctx, catalogue, options) (Answer, error)` that reads the list from the
  catalogue: the accounts; per account its own chat when there is a row for it ("Saved Messages": the
  chat of a person whose Telegram id is the account's own; absent: the entry is drawn with "not read
  yet"); the chats by newest activity (bounded: the first 200, then "N more" as one entry), each with
  its state in a few plain words from the chat's and the mirror's rows (collecting; not collected;
  mirrored; waiting: use the catalogue's existing reads the Chats page uses; say which); never a
  `null` list; cheap (no walk of messages or files: say what each read costs on the server package's
  test at size if one exists);
- a handler helper both servers can mount: the assets under one path and `GET /api/shell` (the answer:
  the list; the places this server owns; the other server's address when known; the pill's facts when
  this server has them, else absent).
**B. Mount it on the app's pages (`internal/server`).** Every page is drawn as: the top strip, the list
on the left, its own content on the right. The present top bar and its tabs go; every place it had
stays reachable from the list:
- Overview first; then Saved Messages; "Library" (the five views); "Chats"; and, because the picture's
  list has no entry for them and the Overview's links come in a later piece, a group "Collecting":
  Queue, Staging, "Choose chats" (the present Chats page: collect switches, topics, mirror), and the
  mirror's settings where they are today; Settings and Accounts at the foot.
- **The viewer's places** (Saved Messages, the library's views, each chat) are plain links to the
  viewer's address with the viewer's own paths (`DESIGN-ONE-WINDOW-HOW.md` section 9: `/`,
  `/?deleted=1`, `/?first=1`, `/?copies=probable`, `/chat/ID`; New: `/?first=1&from=<a date 7 days
  back>`), built from the address the pages already have (`-viewer-url`, or the stored viewer
  address). When no viewer address is known: the entries are drawn, and a click shows one plain line
  in the content ("The viewer is not open: ..." with what the page offers today for it). The counts
  beside the views are NOT asked in this piece: the list is drawn without counts.
- **The pill** from what the pages already have (the live snapshot: running or not, the speed, how
  many wait; the VPN's state if the pages know it): it links to the Overview. No new request to
  anything, nothing read from the library.
- **Layout rules that are not negotiable (the viewer will mount the same shell):** the list is a fixed
  column beside a document that scrolls as a whole (never two inner scrolling boxes around the
  content); at a narrow width the list folds away behind one button in the strip and the content takes
  the width (today every page is about 450 px wide at phone width: with the shell no page may be wider
  than the screen); a click on a same-origin entry is handed to the page through ONE hook the shell
  offers (the pages' own script changes the place without a reload, as its tabs do today); the list
  keeps its scroll place and its selected entry across a change of page and of server (kept per
  address); it paints from what it kept before it asks again.
- **Words:** plain, true of the code, no jargon. An entry that leads nowhere yet says so.
**C. The look on the content.** The pages' own stylesheet takes the picture's colours and type for the
dark theme (map the existing variables; do not rewrite every page's styles); the light theme and "follow
this computer" keep working (derive a light set from the picture's roles; say what you chose). The
content of each page stays as it is in this piece.

## Tests and looks
- Go: the builder on a new empty catalogue, on one with an account and no chat, on the fixture (the
  states' words; Saved Messages found and not found; the bound of 200); `GET /api/shell` in the same
  states with and without the program. `TestEmptyCatalogueAnswersWhole` and
  `TestEmptyCatalogueRoutesListed` (on your base) must pass with the new route in them.
- **`TestPagesInBrowser` (set `TGARCHIVE_BROWSER` to Edge: see the test's head) must pass on every
  page with the shell at both widths, on the empty states AND on the fixture;** add to it: the list is
  there, the old top bar is not, no page is wider than the screen at the narrow width, a click on a
  list entry of the pages changes the place.
- Look at screenshots of the Overview, the Queue and Settings at both widths in both themes yourself
  (Edge headless `--screenshot`), beside the picture: say what differs from the picture and why.

## Rules
- Files: the new `internal/appshell`; `internal/server` (`web/index.html`, the scripts, the styles, the
  route, tests). Nothing in the collector, the catalogue, the viewer, the launcher. Other pieces of this
  track change `internal/server`'s Settings scripts and header at the same time (a "Program" link, the
  viewer's row, a mirror cap row): keep your changes to the frame, `main.js`, the styles' variables and
  the new files, and touch page scripts only where the frame forces it; say every page script you
  touched.
- No test function removed or renamed. No new request to anything outside this PC; `script-src 'self'`
  stays; no web font, no outside image.
- **Every go, gofmt and vet command through the track's lock script:**
  `bash /c/Users/trabi/Claude/Projects/Telegram/runs-pages-p6/go1.sh /c/Users/trabi/Claude/Projects/Telegram/wt-pages-shell/archiver <command...>`
  (it may wait for the lock). Named tests only, nothing over two minutes a command (the browser test
  by name may take longer: give it its own command and a timeout of 10 minutes), no whole package, no
  race detector.
- The owner's real app may be running on this PC (ports 8786, 8787, 8788; `C:\Users\trabi\tgarchive-app`):
  never touch it; ports the system chooses; Edge headless only with a profile folder of your own and
  everything but 127.0.0.1 sent to a dead port (the test's flags); never end a process you did not
  start (by its id). Nothing under `E:`. Never a Windows path inside a shell string.
- Commit and push OFTEN (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the last
  line `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; `git push private wip/pages-shell`
  only). Invented data only. Leave no process, no browser and no profile folder behind.

## Order of work (push after each)
1. The package with its builder and tests. 2. The frame on the pages (the list, the strip, the old bar
gone), the browser test green. 3. The look's colours on the content, both themes. 4. The narrow width.
5. The report `archiver/docs/progress/pages-shell-REPORT.md` (what the viewer must do to mount it: the
hook, the paths, the strip's height).

## Hand back (at most 15 lines)
The pushed head; what is done of the five steps; files with +/- lines; test functions added and
removed; the named tests run; what the browser test loaded and found; what the screenshots show beside
the picture; what is NOT done and NOT verified.
