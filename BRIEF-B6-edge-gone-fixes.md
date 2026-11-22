# Brief B6-E2: the fix round of "a removed look-alike edge taken in place" (viewer session B6, 11-16 evening)

You are an Opus coder for the viewer track of the new archiver, taking over a branch another coder built.
Work only in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-faces` (Go module in `archiver/`), on the
branch `wip/b-edgegone` (head 25af0b2b, pushed; check the copy is clean and on that head first; if not, stop
and say so). Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash. **The
hard rules of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-B6-edge-gone.md` bind you unchanged** (read its
second paragraph: no search over a whole drive; invented data only; one go command at a time with
`GOGC=50 GOMAXPROCS=2 GOFLAGS=-p=1`, named tests only, measure before each and wait while under 2.5 GB free
or over 85%; only `internal/viewer` may change; commits; push only `wip/b-edgegone` to `private`). **Do not
merge any other branch in this round** (the main head is merged in later, when the catalogue's step is on
it).

**Read first, in full:** `C:\Users\trabi\Claude\Projects\Telegram\wt-b6-review-E-scratch\REVIEW.md` (verdict:
ready for its full runs; three findings, all low, all confirmed) with its probes `zz_review_e_test.go` and
`overlay.json` and its outputs beside it (read-only: copy what you turn into tests); the code its findings
name.

## The decisions (the main session's: all three fixed now)
1. **Finding 1 (the proof by count can be fooled when an unlogged removal and a reused row id fall into one
   update).** The proof and the few-minutes count check compare a SUM beside the count: the writer keeps
   the sum of `a + b` over the edge rows it has read (a full read adds every row; new edges add theirs; the
   re-read moves it exactly as it moves the count, by the re-read rows minus the held entries); the SQL
   asks `COUNT(*)` and `COALESCE(SUM(a + b), 0)` in the same one pass. A difference in either is a full
   read. Mind what the count already minds (rows from a file to itself, rows whose file the index does not
   hold: the two sides must count the same rows; say how the sum treats each). The reviewer's probe
   `TestZZE1MaskedByCount` becomes a test: it must end with a full read and an index equal to a full read.
   Say in the comment what can still mask (two swapped pairs with equal sums): accepted.
2. **Finding 2 (an unnamed file's list in another order than a full read's).** The mirrored additions are
   made after the per-file loop, in one pass over the re-read rows in row id order, so that every list is
   in row id order as a full read gives it. The reviewer's probe `TestZZE3MirrorOrder` becomes a test, and
   **the package's comparison of an updated index with a full read gains a check of each file's edge list
   UNSORTED** (in the edge tests at least; if the strong fingerprint itself can compare unsorted without
   breaking tests that are right, do it there and say what it found).
3. **Finding 3 (the live record does not name posts whose edge-derived values changed).** A post whose
   files' edge lists changed in an update (an edge added OR removed) is named in the update's live record,
   so that an open chat page is sent that post again (its set's items, a file's "probable"): bounded by
   the files whose lists changed and their places. The reviewer's probe `TestZZE4Mixed` (its last check)
   becomes a test, for a removed and for an added edge.

## At the end, once
`gofmt -l internal cmd`; `go vet ./internal/viewer`; `go build ./...`; by name: every test you added, all of
`TestEdgeGone`, `TestChangeLogEachChangeFollowed`, `TestRandomUpdatesMatchFullRead`, `TestChalRandomStrong`,
`TestLive`, `TestIncremental|TestFullReadMatchesReference|TestStandIn|TestFold|TestVerdicts|TestLost|TestStaged`;
`git diff 25af0b2b HEAD -- archiver/internal/viewer | grep '^-func Test'` prints nothing or you account for
each line. (`TestActClicksReadBounded` fails on this base in its own set-up: known, not yours; do not run the
`TestAct` family.) Commit and push. Hand back, as your last message: the head (pushed); each of the three
with what you did and any difference and its reason; the three probes as tests, failing on 25af0b2b for the
review's reason and passing now (the lines); what the unsorted comparison found, if anything; the cost of
the proof with the sum (the count's milliseconds before and after at 100,000 edges); what you did NOT
test; your doubts, plainly. Commit-ready, nothing left running, the copy clean.
