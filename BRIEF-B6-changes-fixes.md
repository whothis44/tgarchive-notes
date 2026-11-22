# Brief B6-C2: the fix round of the "what changed" feed (viewer session B6, 11-16)

You are an Opus coder for the viewer track of the new archiver, taking over a branch another coder built.
Work only in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-faces` (Go module in `archiver/`), on the
branch `wip/b-changes` (head 9d24b538, pushed; check the copy is clean and on that head first; if not, stop
and say so). Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash.
**Named tests only; the whole runs and the race detector are not yours** (`CLAUDE.md`, the archiver section,
second point). The hard rules of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-B6-changes.md` bind you
unchanged (only `internal/viewer`; privacy; words; load: check free memory and CPU before each go command and
wait while the CPU is over 85% or free memory under 2.5 GB; commits; push only `wip/b-changes` to `private`).

**Read first, in full:** `BRIEF-B6-changes.md`; the independent review
`C:\Users\trabi\Claude\Projects\Telegram\wt-b6-review-C-scratch\REVIEW.md` (seven findings, with numbers
before and after) and its probes beside it (`prb_cost_test.go`, `prb_feed_test.go`, `prb_random_test.go`,
`prb_query_test.go`, the two overlay files; read-only: copy what you turn into tests); `feed.go`,
`changes.go`, `web/js/changes.js`, and in `refresh.go` the functions `read`, `unchanged`, `apply` and what
keeps things per index version (`ix.gen`: the library's listings, the marks' and the verdicts' resolution).

## The decisions (the main session's; every finding is accepted)
1. **Finding 1 (the cost of an update that names many messages by kind 2).** The joined read of the message
   row with its versions stays only for the ids the change log names with kind 4 (`d.textLog`). For ids
   named only by kind 2, read the versions' index alone
   (`SELECT message_id, COUNT(*), COALESCE(MAX(replaced_at), 0) FROM message_version WHERE message_id IN (...) GROUP BY message_id`)
   and take the edit date and the deleted mark from what the index already holds; a message with no version
   row returned keeps its state. Say in a comment what cannot be told this way (a version written with no
   `replaced_at` by a tool). **The measure:** the review's probe `TestPrbCost` at 600,000 messages, 8,000
   named by kind 2: 122 ms before the piece, 185 ms with it; after your fix say the number (the versions'
   read alone was 7.6 ms against 65 ms in the review's own trial).
2. **Finding 2 (an edit must not make the library start again).** An update whose only changes are the
   feed's (an edit of a message read earlier) must not make the library rebuild its listing, nor the marks
   and the verdicts resolve again: before this piece such an update kept the version, by design. The
   reviewer's first choice is a generation of its own for what the library keeps, which an update does not
   advance when every dirty post's reason is the feed's only and nothing else moved; keeping the feed
   outside the version is another. Choose the smallest sound one, say why, and **prove it by tests:** after
   an edit of a known message (and after a files-only edit that changes no file the library shows: say what
   a files-only edit really changes and whether the library must then follow) the library's listing is the
   kept one (count the rebuilds, do not time them), the Changes page shows the edit, and the chat page's
   live ask still learns of it (`noteLive`'s step). The review's probe block "one text edit per update"
   becomes a test: 0 of 5 edits may start the listing again.
3. **Finding 3 (a long text edited after its first 4,000 bytes).** Whether the text changed is decided on the
   WHOLE texts on the server and sent with the row; the page uses that, never a comparison of cut texts.
   The texts sent are cut only at 16,384 bytes (the most 4,096 characters can take), at a character's
   boundary, and a text that was cut says so in fixed words on the page. The review's probe
   `TestPrbLongTextEdit` becomes a test.
4. **Finding 4 (a deleted post whose lead changes between two pages).** A deletion's row is keyed by the
   post's smallest message id (the catalogue's id: it never changes as messages join the post, and a full
   read gives the same), in the lists and in the cursor; the comment at the top of `feed.go` is made true.
   The review's probe `TestPrbCursorLeadChange` becomes a test. The old `/api/deleted` answer keeps its
   shape; its cursor is whatever the new key needs (nothing reads it but tests: say what changed).
5. **Finding 5 (words).** An "edited" row whose versions are not found at page time keeps "the app saw the
   change" as its kind of time (the index's time came from it); it never says "Telegram's edit time" over a
   time the app saw.
6. **Finding 6 (no second list of deletions).** `ix.deleted` goes: `deleted_posts` in `/api/meta` is computed
   from the feed's deletion classes; `deletedFiles` stays as it is unless it falls out of the same lists
   for free (say which). The existing tests that read `ix.deleted` are changed to the feed, not removed.
7. **Finding 7.** "That is all N." counts the rows the page has drawn. Nothing else.

## Tests
- The four probes named above as tests of the package, each failing on 9d24b538 for the review's reason and
  passing after (show both runs' lines); the cost probe as a counts test (statements and rows per update
  with 0, 500, 2,000 and 8,000 messages named by kind 2: the joined read is bounded by the kind 4 ids), with
  the milliseconds printed, not judged.
- The review's random sequence (`prb_random_test.go`: albums completed later, marks taken back, two edits in
  one update) kept as a test beside the coder's own, the feed compared with a full read after each step.
- The existing `TestChanges*`, `TestDeleted*`, `TestLive*`, `TestWall*`, `TestLAN*`,
  `TestIncrementalRefreshMatchesFullRead`, `TestRandomUpdatesMatchFullRead` and the library's tests that
  key on the version pass by name. `git diff 9d24b538 HEAD | grep '^-func Test'` prints nothing, or you
  account for each line.

## At the end, once
`gofmt -l`, `go vet ./internal/viewer`, your named tests, `node --check` on each changed script,
`CGO_ENABLED=0 go build ./...`. Commit on `wip/b-changes` and push only that branch. Hand back, as your last
message: the head (pushed); each of the seven with what you did and any difference and its reason; for
decision 2 the design you chose and everything that is keyed by the new generation or left on the old one;
the numbers of decision 1 before and after; the probes as tests, before and after; any new or changed string
the page can show; what you did NOT test; your doubts, plainly. Commit-ready, nothing left running, the copy
clean.
