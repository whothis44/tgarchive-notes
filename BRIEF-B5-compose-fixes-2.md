# Brief B5-A, second fix round: the second review look's nine findings (viewer session B5, 11-16)

You are an Opus coder for the viewer track of the new archiver, taking over a piece another coder built.
Work only in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-window` (Go module in `archiver/`), on the
branch `wip/b-compose` (head b1dc2f9f; check the copy is clean and on that branch first; if not, stop and say
so). Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash.

## Read first
- What the piece is: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-B5-compose.md` (the chat page acts,
  behind a seam `Config.Act` that is nil in both commands: nothing can send) and
  `C:\Users\trabi\Claude\Projects\Telegram\SEAM-B5-viewer-act.md` (the seam as built).
- The second review look, in full: `C:\Users\trabi\Claude\Projects\Telegram\wt-b5-review-A-scratch\REVIEW-2.md`
  (its probes: `probe2_b5_test.go` beside it; take them into the package as its own tests where they fit).
  Verdict: ready to be listed behind a nil seam; not ready for a live seam. **All nine new findings are
  accepted, as decided below.**
- The code: `internal/viewer/act.go`, `act_keys.go`, `act_ledger.go`, `web/js/act.js`, and the tests
  `act_test.go`, `act_fix_test.go`.

## The findings, as decided
1. **A click key is tied to its click.** The server keeps with each key a hash of the click's resolved
   form (account, chat, kind, the target messages, reply, topic, destination, emoji, revoke, try-again, the
   text) and answers "bad request" when a known or busy key comes with another form; the check is made
   after the click is resolved and before the seam. The page's "same click" also compares the account and
   the topic. (Core is told that the door must tie its key to the content too.)
2. **The box is emptied only for the click that was queued.** No match by text. The state read takes the
   page's held key (`?key=`) and the answer says whether the viewer holds a click number for that key
   (and the number). After "failed" or a timeout: that number is there: the click is queued, the box is
   emptied, the key dropped; it is not there: the text and the key stay, Send comes back, and the next
   Send goes out under the same key. A state read that began before the click does not release the hold.
3. **Forward, delete and reaction keep their key too.** After an answer that was not a refusal, the page
   keeps the key for that same action (kind, post, destination or emoji, revoke) and reads the state
   before the same button sends again; a refusal, or the key's number in the state, drops it.
4. **Open tips the walk left out come back.** When tips were dropped for lack of room and room is free
   again, the chat is walked again (bounded as the first walk; say what an ask costs then).
5. **The newest clicks are always drawn.** Of the 50 lines, the 10 newest open tips are drawn whatever
   their number, the rest are the oldest; "more" as now. The owner's own click of a moment ago is then
   always on the page.
6. **One deadline for one request.** The calls of the seam in one request share one deadline of 20 s. For
   a queue, a cancel, a send again and a verdict, the seam's call runs on a context the page's abort does
   not cancel (the request's values, not its cancellation), so that a queue under way finishes and its key
   gets its number; the answer is then written if the page is still there. The state read's calls (one
   per account) share the request's 20 s and stop when the page goes.
7. **"reading" does not stick.** The page's own timer also runs while the box says "reading", and is
   armed again after a failed read (with the same pause; only while the tab is visible).
8. **A forward of a post with a deleted message is refused**, before the seam, with one new word and its
   line ("Part of this post was deleted; it is not forwarded from here"). A delete still leaves the deleted
   ones out.
9. **"bad character" says which:** the line names U+FFFD or NUL. The rule stays.

## Bounds
`internal/viewer` only; no schema step, no `go.mod` change, no new import outside the viewer's wall, no dial;
both commands stay unchanged (the seam stays nil there). Invented data only; never open the owner's
catalogues, library or real media; never start the collector, the old app, or a viewer or window on anything
but a scratch folder of your own; nothing may reach Telegram. Every new string is in the piece's closed
sets; no click text, name, id, path or hash in a log line, an error or the counts file.
Load: `GOMAXPROCS=2`, `go test -p 1`, `GOGC=50`; check free memory before a run
(`powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB"`, wait while
under 2 GB). Named tests only: never the whole package, never the race detector, no Docker, never any cache
clean-up. Tests do not judge real time. Another agent works in the copy `wt-b-viewer`: do not touch it. Do
not merge any branch in.

## Tests
One for each of 1 to 9 (the reviewer's probes among them: the key with another chat, text or kind; the
evicted tips; the newest not drawn; the deadlines adding up; a queue that finishes after the page went).
The page's behaviour of 2, 3 and 7: open the page once in the browser pane on an invented archive with a
fake seam, served by a temporary test on 127.0.0.1 that you remove and never commit (the first coder did the
same: its fixture and fake seam are in the tests), and say for each what you saw: after "failed" with
nothing queued the text stays and Send comes back; after "failed" with the click queued the box empties; a
forward tried again after "failed" goes out under the same key (the fake seam shows the keys); "reading"
ends away from the newest end.

## At the end, once
`gofmt -l` on what you touched; `go vet ./internal/viewer`; `go test ./internal/viewer -run 'TestAct' -p 1`
and `-run 'TestWall|TestLAN|TestPageScripts' -p 1`; `CGO_ENABLED=0 go build ./...`. Commit on `wip/b-compose`
with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no archive numbers in it, and push only that
branch, only to `private`. Hand back, as your last message: the commit and the head; each of the nine with
what was done and any difference with its reason; what changed in the seam or its words (for
`SEAM-B5-viewer-act.md`); what you saw in the browser pane; what you ran and what it printed; what you did
not test; doubts. The copy clean, nothing left running.
