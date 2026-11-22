# Brief B6-D3: a last small round on the viewer's pass-through, after the review's second look (viewer session B6, 11-16)

You are an Opus coder for the viewer track of the new archiver, taking over a branch others built. Work only
in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-viewer` (Go module in `archiver/`), on the branch
`wip/b-door` (head 25365ae2, pushed; check the copy is clean and on that head first; if not, stop and say
so). Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash. **Named tests
only**; the hard rules of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-B6-door.md` bind you unchanged
(privacy, words, load: check free memory and CPU before each go command and wait while the CPU is over 85%
or free memory under 2.5 GB; commits; push only `wip/b-door` to `private`). **Tests and probes name
addresses, never host names.**

**Read first:** `C:\Users\trabi\Claude\Projects\Telegram\wt-b6-review-D-scratch\REVIEW-2.md` (the second look:
six new findings) with its probes and its `js/harness.mjs` (read-only: copy what you turn into tests);
`BRIEF-B6-door-fixes.md` (the decisions the last round built); the code the findings name.

## The decisions (the main session's)
1. **Finding 2 (the box loses an uncertain key when another text comes between).** The box keeps its
   uncertain keys by content in a small map, as the buttons' `held` is kept: an entry stays until a state
   read shows a number for its key; Send reuses the key of an uncertain entry with the same content
   (account, kind, message, reply, topic, text: the fields `same` compares). Bounded as the buttons' are (the
   same fixed sentence when full; never forgotten for room). The reviewer's harness case S1c must print
   that the last key IS the uncertain key: make it a test the package runs if the copy can run node from a
   Go test without a new requirement (say how); otherwise pin the rule by a source-text test as the other
   page rules are pinned, and say so.
2. **Finding 3 (the wall).** `forbiddenSelectors` also refuses, in every file of the package: every
   `net.Lookup*`, every `net.Resolve*`, `net.ListenPacket`, `net.ListenUDP`, `net.ListenIP`,
   `net.ListenMulticastUDP`, `syscall.Socket`, `syscall.Connect` (by prefix where the review says "every").
   If a file of the viewer uses one of them rightly today, do NOT remove the use: name the file as the one
   exception with a comment saying what it does and why it reaches nothing, and say so in the hand-back.
   Show the mutation each new entry catches (the reviewer's probe Q3 has the forms).
3. **Finding 5 (the state route).** A 404 is "cannot write: not running" only when its body's word is "no
   door"; a 403 only when its body's word is "refused"; a 503 as now. Any other body on 404 or 403 is a
   failure (a moved route or a wrong secret must not look like a stopped collector for good).
4. **Finding 1, the stopgap only** (the full check, by the click's key, comes with the wiring, when Core's
   key memory is merged: do not build it now). The ledger check believes a queue's number only when the
   row's own click time is not older than the moment the viewer began this request, less 5 seconds for the
   clock (the viewer's clock, handed in as the other clocks are); for "send again" the same on the new row.
   The reviewer's probe Q2 (a 3-day-old row of the same account, chat and kind) becomes a test: it fails on
   25365ae2 and passes after.
5. **Finding 4, words only.** `SEAM-B5-viewer-act.md` (the project folder; written with the file-writing tool;
   no Windows path) says in two sentences that a kept key can hold one text or, at 32, every new button
   until the page is loaded again, and that loading the page again is the way out and forgets the page's
   keys.
6. **Not yours:** finding 6 (the door's side), the wiring, the two commands, `catalog.ActKey`.

## At the end, once
`gofmt -l`, `go vet ./internal/viewer`, your named tests and
`go test ./internal/viewer -run 'TestAct|TestWall|TestLAN' -p 1`, `node --check` on each changed script,
`CGO_ENABLED=0 go build ./...`; `git diff 25365ae2 HEAD | grep '^-func Test'` prints nothing or you account
for each line. Commit and push. Hand back, as your last message: the head (pushed); each of the five with
what you did and any difference and its reason; the tests before and after; the mutations; any new or
changed string the page can show; what you did NOT test; your doubts, plainly. Commit-ready, nothing left
running, the copy clean.
