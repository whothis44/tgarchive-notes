# Brief B6-D2: the fix round of the viewer's pass-through to the door (viewer session B6, 11-16)

You are an Opus coder for the viewer track of the new archiver, taking over a branch another coder built.
Work only in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-viewer` (Go module in `archiver/`), on the
branch `wip/b-door` (head d5dd4869, pushed; check the copy is clean and on that head first; if not, stop and
say so). Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash.
**You run named tests only; the whole runs and the race detector are not yours** (`CLAUDE.md`, the archiver
section, second point).

**Read first, in full:**
- `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-B6-door.md` (what the piece is; its hard rules bind you
  unchanged: privacy, words, load, commits, the one branch you may push).
- `C:\Users\trabi\Claude\Projects\Telegram\wt-b6-review-D-scratch\REVIEW.md` (the independent review: twelve
  findings) and its probes `probe_b6d_test.go` with `overlay.json` beside it (read-only: do not change that
  folder; copy what you turn into tests).
- The door as built: `git -C C:/Users/trabi/Claude/Projects/Telegram/repo-archiver show private/wip/pages-door:archiver/docs/progress/pages-door-REPORT.md`,
  section 2 (read only; do not touch that branch or its copy).
- `internal/viewer/act_door.go`, `act.go`, `act_keys.go`, `act_ledger.go`, `web/js/act.js`, `wall_test.go`.

## The decisions (the main session's; every finding is accepted unless it says otherwise)
**A. The two mismatches against the door as built.**
- A1. Cancel, verdict and not-arrived answer 200 `{"ref":n}` (the click acted on, n at least 1), not
  `{"ok":true}`. Read them strictly as that. The fake door in the tests answers as the real one does, route
  by route, as the report's table says (also its 404 `{"word":"no door"}`, 403 `{"word":"refused"}`, 503).
- A2 (the review's finding 5). On the STATE route: a 409 whose word is a state word (`actWhyWords`: "not
  running", "not found" and the others) becomes `ActState{Why: word}`, so the page shows that word's line;
  any other 409 word there stays a failure. Also on the state route only: 403, 404 and 503 are "cannot
  write: not running" (nothing is at stake in a state read, and "look in the chat" would send the owner to
  check something never sent). **For the five changing calls nothing changes: 400, 403, 404, 500, 503 stay
  failures** (the review's finding 8 is decided "keep as it is" for changes).

**B. One click, one request (the review's findings 2, 3, 6).**
- B1 (finding 2). Once a key has had an answer that was not a refusal (a failure, a timeout), the page keeps
  that key with that content until a state read shows a number for it or the owner changes the content. A
  refusal of a later try does NOT drop it. The same for the buttons' `held` keys; an uncertain key is never
  the one evicted when the map is full (say what happens when only uncertain keys are left: refuse a new
  click of that kind in fixed words rather than forget one).
- B2 (finding 3). Deadlines: the state call gets a short bound of its own (5 s); a changing call gets a
  deadline of its own LONGER than the door's 15 s (18 s), so the viewer never gives up on a change the door
  is still working on; both stay under the page's 30 s when they follow each other in one request. The seam
  file says the new numbers.
- B3 (finding 6). A forward, a delete or a reaction that is out is recorded before the ask: while it is, the
  same button answers the existing "still asking" words and sends nothing.

**C. The right to say "it is not in the chat" (finding 4).** `handleActAgain` looks at the row: `not_in_chat`
is refused ("bad request") unless the row is "not sent" with the why "the earlier try is in the chat";
`try_again` is refused unless the row's own buttons would offer "try again". `TestActNotArrivedAndNotInChat`
is changed to assert this (it asserts the opposite today). The door and the catalogue are asked by the main
session to refuse the same; the viewer refuses it first regardless.

**D. A number is believed only when the ledger has it (finding 9, decided beyond the review's "accept the
risk").** After a 200 with a click's number from queue or again, the viewer reads that row itself through
the catalogue's own door (`catalog.Click`, read-only, as `act_ledger.go` does): if there is no such row, or
it is not of this account, this chat and this kind (for "again": the kind and chat of the row sent again),
the answer is a failure (the page's existing words for a failed change; the key is kept as in B1). So a
program that is not the door, sitting on a stale door file's port, cannot make the page say a click was
queued. If the viewer's read handle can lag the collector's write, say how you bound that (one read again
after a short bounded wait, never a loop) and test the lag. The seam file also says, in one plain sentence,
what such a program still receives (the old secret, which is worthless, and the text of the click) and
that this is accepted on a PC with one user.

**E. Smaller.**
- E1 (finding 10). `until_ms` of "wait" and "cap" is taken only when it lies between now and one year from
  now (the viewer's clock, handed in as the other clocks are); otherwise the word is kept without a time.
- E2 (finding 11). The hint beside a "not known" click: a candidate the app itself would take is shown as
  today; a candidate the app does not take is shown only together with the catalogue's fixed why word for
  it in plain words (the catalogue's constants: one sentence each, in the one place the page's words live),
  never as a plain "It is in the chat".
- E3 (finding 12). An "arrived" the app made must never push out a row that needs the owner: when the open
  tips are over their bound, such rows leave first. Keep the seven days.

**F. The wall (finding 7).** (1) `TestWallImports` and `TestWallNoOutboundCalls` resolve every selector through
the file's import table (the import's path, not its local name) and refuse a renamed or dot import of `net`,
`net/http`, `crypto/tls` and `os/exec` anywhere in the package. (2) `TestWallDoorOneClient` counts the
allowed selectors in the WHOLE of `act_door.go` (package-level declarations too) and requires every one
inside `actDoorPost` (or the one small function you factor the transport into, pinned the same way). (3) One
behaviour test: a request whose URL names another port, sent through the very transport the pass-through
builds, reaches only the checked port (two listeners that count accepts). For each of the three, show the
mutation it now catches.

**Not yours:** finding 1 (the door's key memory is Core's piece; the seam stays nil in both programs until
it is merged). The two commands stay unchanged. No retry of any changing call, ever.

## Tests
- The review's probes P4, P5 and P6 turned into tests of the package (each fails on d5dd4869 for the reason
  the review gives and passes after your fix: show both runs' lines).
- B1 and B3 are page behaviour: test what can be tested in Go (the routes, the key memory), pin the page's
  rule by a source-text test as the piece's other page tests do, and **say plainly that no browser ran**
  unless you run one on an invented archive with a slow fake door (if the copy has a headless browser check
  already, use it; do not install anything).
- D: a fake door that answers a number the ledger does not hold; one that answers another chat's click; the
  honest case; the lag case.
- The existing `TestAct*`, `TestWall*`, `TestLAN*` pass. Before handing back,
  `git diff d5dd4869 HEAD | grep '^-func Test'` prints nothing, or you account for each line.

## At the end, once
`gofmt -l`, `go vet ./internal/viewer`, your named tests and
`go test ./internal/viewer -run 'TestAct|TestWall|TestLAN' -p 1`, `node --check` on each changed script,
`CGO_ENABLED=0 go build ./...`. Bring `C:\Users\trabi\Claude\Projects\Telegram\SEAM-B5-viewer-act.md` up to
date (a section "Changed by the pass-through's fix round"; written with the file-writing tool; no Windows
path in it). Commit on `wip/b-door` and push only `git push private wip/b-door`. Hand back, as your last
message: the head (pushed); each decision A1 to F with what you did and any difference and its reason; the
probes as tests, before and after; the mutations; every new or changed string the page can show; what you
did NOT test; anything in the review or the door's report that you found wrong; your doubts, plainly.
Commit-ready, nothing left running, the copy clean.
