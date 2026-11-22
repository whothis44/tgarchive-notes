# Brief G17: the app's pages on a NEW, EMPTY catalogue; the Theme row's hint (pages, P6, 11-16)

**The first rule of this folder: routine steps in one go or by a script, never one call at a time for its
own sake.** You are one Opus coder. Work only in the copy and on the branch your start message names
(`wt-pages-empty`, `wip/pages-empty`). Never touch `repo-archiver` itself or another `wt-*` copy.

## What the owner saw (11-16 18:05 to 18:15, the first real start of the folder's program)
"Well, deeply unsatisfying so far." Two of the things on the owner's screen are this piece:
- **(a) The Queue page showed nothing but an error: "Cannot read properties of null (reading
  'length')".** The catalogue was minutes old: one account just signed in, no chat chosen, no file. A
  page script took the length of a list that the answer gave as `null`. **Nobody had ever opened the
  pages on an empty catalogue:** every test and every look used the fixture or the demo's invented
  archive.
- **(b) Settings, "Display", the Theme row: two lines of its hint are drawn on top of each other**
  ("Light, dark, or follow this computer. Default: follow this computer." with a second text over its
  first words).

## What the old app already knows
Its dashboard was opened on a fresh folder at every install, so an empty archive was its everyday first
state; nothing of its code is to port. The lesson is the one this app's own record already has
(`LESSONS-viewer-ix12.32.md`, and this track's reviews): a page is "done" when it was opened in the state
the owner will meet first, and a page must never be one error box because one list is missing.

## What to build
**A. The cause, at its source.** Find why the Queue page's answer holds `null` for a list on an empty
catalogue (a nil Go slice or map marshalled as `null`), fix it there (the answer carries `[]` or `{}`),
and then look for the same in EVERY answer the pages' scripts read: all `GET /api/...` routes of
`internal/server` (the route table; the program's routes with the collector's seams too) and the
adapters in `internal/collector/livepages` that fill them.

**B. A test that keeps it true, on catalogues the tests never used.** New tests in `internal/server`:
build a catalogue the way the program does at its first start (the catalogue's own open of a new file:
NOT the fixture, NOT the demo) in these states: (1) nothing at all; (2) one account on record, signed
in, no chat; (3) one account and one chat row with no message and no file. For each, with the program's
seams as an idle collector gives them (the existing fakes, with empty answers, nil slices and nil maps
on purpose where a seam's type allows them: a real idle collector returns such values) and once without
the program (the read-only pages): ask every GET route the scripts use and assert: the status is 200 or
the route's documented refusal; **no value is `null` where the script reads a list or an object's keys.**
Choose the form that keeps this true for routes added later (for example: walk every answer and fail on
any `null` that is not in a short allow-list of fields that mean "not known", each with its reason
beside it). State (3) and a catalogue with many accounts are cheap to add: add what you find missing.

**C. The scripts must not die whole on one missing value.** In `internal/server/web/assets/js` (every
page and shared module): find each place that takes `.length`, iterates, spreads or reads keys of a
value from an answer, and make sure it is either guaranteed by B or guarded in the script (an empty
list is drawn as the page's own "nothing yet" words, which you write where a page has none: say what a
new owner should do next, in one plain sentence, for example on the Queue page "Nothing is queued:
choose a chat on the Chats page and its files appear here."; keep the words true of the code). Where a
page has a common loader, a failed region should show its own error line and let the rest of the page
draw, if that is a small change; if it is not small, say so and leave it.

**D. Every page OPENED on the empty catalogue, by you, before you hand back.** Serve the pages on a
scratch port over each of B's states (a scratch folder under your copy or the system's temporary
folder; invented data only; the read-only app command or a look test, whichever the package already
has: `TestStagingPageLook` and `TestStagingLiveLook` show how earlier pieces served pages for a look)
and load EVERY page of the top bar and every sub-page a link reaches (Overview, Chats, Queue, Staging,
Accounts, Settings with all its regions, the mirror's regions) in a real browser engine, at a wide and a
narrow width. A way that leaves nothing behind and sends nothing outside this PC: Edge headless with a
profile folder of its own in your scratch folder and
`--headless=new --disable-gpu --no-first-run --disable-background-networking --disable-component-update --disable-sync --proxy-server=http://127.0.0.1:9 --virtual-time-budget=8000 --dump-dom <address>`
(127.0.0.1 is reached directly; everything else goes to a dead port: the browser's own calls to its
maker never leave). Read the dumped page for an error box, the words "Cannot read", "undefined", "null"
shown to a person, an empty region where words belong. **If this can be kept as a test** (a Go test
that is skipped unless an environment variable names the browser's program, as the look tests are
skipped, and that fails on any page with an error box or a script error), add it: it would be the first
test that runs the page scripts at all, and the track needs one. Say plainly what you looked at, how,
and what you did NOT look at.

**E. The Theme row (b).** Find why two hint lines overlap in Settings, "Display", "Theme" (markup or
CSS: two hints in one cell, an absolutely placed element, a label and a help line sharing a grid cell)
and fix the cause; then look at every other row of Settings for the same pattern at a wide and a
narrow width (the look of D). Do not restyle anything: the look of the whole app is being decided with
the owner separately; this is only the defect.

## Rules
- Files: `internal/server` (Go, `web/assets`, tests) and, only where an adapter gives a nil list,
  `internal/collector/livepages`. Nothing in the collector's own files, the catalogue, the launcher.
  If the cause of a `null` lies in another track's package, do not change it there: make the server's
  answer whole and name the place in the hand-back.
- No test function removed or renamed; no route's meaning changed; no new request to anything.
- **Every go, gofmt and vet command goes through the track's lock script** (other agents of this track
  run go commands; the PC's memory is tight):
  `bash /c/Users/trabi/Claude/Projects/Telegram/runs-pages-p6/go1.sh /c/Users/trabi/Claude/Projects/Telegram/wt-pages-empty/archiver go test -p 1 -count=1 -run '^(TestA|TestB)$' -timeout 5m ./internal/server/`
  Named tests only, nothing over two minutes a command, no whole package, no race detector, no vet over
  packages (the full runs are made once after the review). Write first, test in few larger steps.
- Never a Windows path inside a shell string: the Write and Edit tools for files, `/c/...` in bash.
- Never open the owner's real folder, pages, catalogue or anything under `E:`; the owner's app may be
  running on this PC right now on port 8787 or another: use a scratch port of your own (for example one
  above 20000 that nothing listens on) and never ask a port you did not start.
- Commit as you go and push to the remote `private` only (`git push private wip/pages-empty`):
  `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Invented data only everywhere. Leave no
  process and no browser behind (look before you hand back).

## Hand back (at most 15 lines)
The pushed head; files with +/- lines; the cause of the owner's error in one line (route, field, the
script's line); every other `null` you found, by route; test functions added and removed; the named
tests run; what you opened in a browser engine, in which states and widths, and what you saw; the Theme
row's cause; what is not verified. A report as `archiver/docs/progress/pages-empty-REPORT.md`.
