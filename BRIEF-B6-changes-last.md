# Brief B6-C3: a last small round on the "what changed" feed, and the main head merged in (viewer session B6, 11-16)

You are an Opus coder for the viewer track of the new archiver, taking over a branch others built. Work only
in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-faces` (Go module in `archiver/`), on the branch
`wip/b-changes` (head 8cced5a9, pushed; check the copy is clean and on that head first; if not, stop and say
so). Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash. **Named tests
only**; the hard rules of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-B6-changes.md` bind you unchanged
(only `internal/viewer`; privacy; words; load: check free memory and CPU before each go command and wait
while the CPU is over 85% or free memory under 2.5 GB; commits; push only `wip/b-changes` to `private`).

**Read first:** `C:\Users\trabi\Claude\Projects\Telegram\wt-b6-review-C-scratch\REVIEW-2.md`, its section "New
findings" (two, both minor).

## Three steps, in this order
1. **New finding 1.** In the Changes page's handler (and `/api/deleted`'s, if it says "as of" too) the time of
   the last read (`readAt`) is loaded BEFORE the index and the feed's state, so that "as of" never names a
   read later than what is shown. One test that pins the order (a source-order or a hook test, as the
   package does elsewhere; no real time).
2. **New finding 2.** An update that kept the version but moved rows of the feed is not counted as one that
   "found nothing to change": it gets a count of its own in the counts-only snapshot (a fixed name and
   fixed words, a number), and the existing count keeps its meaning. One test.
3. **The main head.** `git fetch private`, then merge `private/claude/charming-feynman-vm2xia` into the branch
   (`git -c user.name=Claude -c user.email=noreply@anthropic.com merge --no-ff`, the message "Merge the main
   head into wip/b-changes" ending with the co-author line). The main head now holds another piece of this
   track that touches the same package (the compose box: new `act*.go`, `web/js/act.js`, and a few lines in
   `server.go`, `viewer.go`, `web/app.css`, `web/js/api.js`, `web/js/chat.js`). **If the merge is clean, go
   on. If it conflicts: resolve only conflicts where both sides' lines plainly stay (two routes added side
   by side, two imports, two style rules, two lines of a script's list); for anything else stop, leave the
   merge in progress, and report the files and the hunks.** After the merge: the wall test must still hold
   (`TestWall*`), and the compose box's own nil-seam test (`TestActNilDrawsNothing`) must still pass: the
   Changes page adds a link on the chat page and must not make the compose box's "nothing is drawn" false.

## At the end, once
`gofmt -l internal cmd` (nothing); `go vet ./internal/viewer ./cmd/tgarchive ./cmd/tgarchive-window`;
`go build ./cmd/tgarchive ./cmd/tgarchive-window`;
`go test ./internal/viewer -run 'TestChanges|TestDeleted|TestAct|TestWall|TestLAN|TestLive|TestPagesReloadBounded|TestHeadersOnEveryAnswer' -p 1 -count=1`;
`node --check` on each script the merge or you touched; `git status --short` prints nothing; push.
`git diff 8cced5a9 HEAD -- archiver/internal/viewer | grep '^-func Test'` prints nothing, or you account for
each line. Hand back, as your last message: the head (pushed) and the main head it now holds; the two fixes
with their tests; the merge (clean, or each conflict and how you resolved it); the runs' lines (numbers);
anything you did NOT do; your doubts. Nothing left running, the copy clean.
