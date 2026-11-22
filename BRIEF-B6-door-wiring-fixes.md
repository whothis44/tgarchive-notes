# Brief B6-D5: the fix round of the wiring, after the reviewer's third look (viewer session B6, 11-16 afternoon)

You are an Opus coder for the viewer track of the new archiver, taking over a branch others built. Work only
in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-viewer` (Go module in `archiver/`), on the branch
`wip/b-door` (head e6223482, pushed; check the copy is clean and on that head first; if not, stop and say
so). Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash. **The hard
rules of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-B6-door-wiring.md` bind you unchanged** (read its
first section: no search over a whole drive; addresses, never host names; invented data only; the PC's
memory: one go command at a time with `GOGC=50 GOMAXPROCS=2 GOFLAGS=-p=1 GOMEMLIMIT=900MiB`, named tests only,
measure before each and wait at most 20 minutes while under 1.2 GB free or over 85%; words; commits; push
only `wip/b-door` to `private`).

**Read first, in full:** `C:\Users\trabi\Claude\Projects\Telegram\wt-b6-review-D-scratch\REVIEW-3.md` (five
findings) with its probe `probe_b6d3_test.go` and `overlay4.json` (read-only: copy what you turn into
tests); `BRIEF-B6-door-wiring.md`; the code the findings name.

## The decisions (the main session's; every finding is accepted)
**1. Finding 1 (a queued click not learnt while the collector is away, and its retry refused by the viewer's
own gates).** All three, each small:
- (a) the state route's `key_ref`: when no account is resolved (every account "not running"), the key memory
  is asked for each account of the chat that could have made the click (bounded by the chat's accounts);
- (b) the page sends its uncertain key with EVERY state read while it holds one, not only while Send is
  held (the node harness of the page's key rules gains the case);
- (c) in the click route, a key the viewer's own memory does not hold is looked up in the catalogue's key
  memory first; **a key the catalogue knows goes straight to the door, past the viewer's own state, limit
  and hold gates** (the door answers a known key before anything else and still refuses it with the word
  "key" when the content differs; the viewer never answers such a click by itself: the door is asked,
  once). A key the catalogue does not know takes the gates as now.
The reviewer's probe T1 becomes tests: the door away and no account named: `key_ref` is the click's number;
the cap, a wait or a slow mode running: the retry under the known key reaches the door once and comes back
with the first click's number.

**2. Finding 2 (the door is found by folder only, so another catalogue in the same folder takes it).** The
door file names the catalogue file it serves, and the finder answers "no door" unless that is the viewer's
own. **This needs lines in two files that are not this track's (`internal/actdoor/door.go` and the one call
in `internal/collector/pages.go`): they are LENT LINES, asked of their owners on the board by the main
session: make them ONE separate commit, last but one, as few lines as it takes, with the subject "Lent
lines: the door file names its catalogue", so that it can be taken, replaced or dropped.** In it: the
document gains one field, the catalogue file's base name as the collector opened it (a name, never a path;
bounded; the reader's strict form extended by exactly that field; a file without it is "not whole", so an
older writer's file is never taken for a door); `Write` takes the name; `Door` carries it; the package's
own tests extended; nothing else in those two packages. Then, in this track's own commit: the two commands'
finder compares it with the base name of the `-db` the viewer opened (same folder and same name: the same
file) and answers "no door" otherwise; `filepath.Abs` is taken ONCE, when the finder is made (finding 5).
Tests: a door file naming another catalogue: no door, nothing asked; the whole-chain test still passes; a
second viewer on a copy of the catalogue in the same folder draws nothing and sends nothing. **If the lent
lines turn out to need more than those two files or a change of the door's routes: stop, do not make them,
and say what they would need.**

**3. Finding 3 (a link preview counts as a caption).** The viewer judges an edit by the caption's limit only
where the message is surely a caption: today that is one sign, the message is part of an album (the
catalogue cannot tell a preview's picture from a sent one; a web page is never in an album). Every other
edit is judged by the text's limit, and a caption of a single photo or file that is too long is left to
Telegram (one request, its refusal shown on the row). "Limits unknown" for a caption limit of 0 only in the
album case. Check what the collector's queue does today with an edit of a message that has an attachment
(`core-door-REPORT.md` section 2 says it judges every edit by the text's limit; the reviewer read part 4
otherwise): one test through the real chain settles it (an edit of 1,500 units on a message with an
attachment and no album: queued); if the collector refuses it, do NOT change the collector: say so in the
hand-back for the main session to put to Core. The reviewer's probe T2 becomes a test.

**4. Finding 4 (the end-to-end test hides the viewer's holds).** The chain test's helper fails on a "cap" or
"wait" that the state read before it did not announce in `not_before`; one more step stops the collector
between the lost answer and the retry, checks `key_ref` while it is away (decision 1 a), starts it again
(a new secret, the same key memory) and checks that the retry under the key gives the first click's number
with no second send. The port for the collector's pages is picked so that another program cannot take it
in between where the collector's flags allow it (if they do not, say so and leave it).

**5. Words.** `SEAM-B5-viewer-act.md` (the project folder; the file-writing tool; no Windows path) gains a
section "Changed by the wiring's fix round": the door file's catalogue name and what it protects against;
the caption rule and what is left to Telegram; a known key going past the viewer's gates.

## At the end, once
`gofmt -l internal cmd`; `go vet ./internal/viewer ./internal/acttest ./internal/actdoor ./cmd/tgarchive ./cmd/tgarchive-window`;
`go build ./...`; by name: every test you added or changed, the viewer's
`TestAct|TestWall|TestLAN|TestChanges|TestDeleted|TestLive`, the four of `internal/acttest`, `internal/actdoor`'s
own tests, the door's tests in `internal/server` and `internal/collector` that read or write the door file
(find them by the names that mention the door file; by name only), the two commands' `TestActDoorFind`;
`node --check` on each changed script; `git diff e6223482 HEAD | grep '^-func Test'` prints nothing or you
account for each line. Hand back, as your last message: the head (pushed); each decision with what you did
and any difference and its reason; the lent lines exactly (files, lines, what a reader of an older file
does); the tests before and after (the reviewer's two probes failing on e6223482 and passing now); any new
or changed string; what you did NOT test; your doubts, plainly. Commit-ready, nothing left running, the copy
clean.
