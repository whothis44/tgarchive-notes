# Brief K17b: the fix round after K17's independent review (Core, K-5, 2026-11-16)

**Rules of the house:** you are an Opus coder and hand back commit-ready work. Named tests only (`-run`, the
one package; the whole `internal/catalog` is not yours to run); no race detector. Invented data only; nothing
of a name, text, path or id in any log line, error or commit message. Never touch a running program, the main
copy `repo-archiver` or anything under `E:\`. **Every `go`, `gofmt` or `vet` command goes through the track's
lock script** (another coder of this track works beside you; the script waits for memory and sets the
environment): `bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go1.sh <folder to run in> go test -p 1 -run '<names>' -timeout 15m ./internal/catalog/`
(it prints "go1: exit N"; 97 or 98: nothing was run, wait and try again).

**Where:** the existing copy `C:\Users\trabi\Claude\Projects\Telegram\wt-core-giveback`, branch
`wip/core-giveback`, head bd195424 (clean, pushed). New commits on top; commit with `git -c user.name=Claude
-c user.email=noreply@anthropic.com commit`, the message ending `Co-Authored-By: Claude Opus 5.5
<noreply@anthropic.com>`; push only that branch to `private`. No `git stash`, no rebase, no amend.

## Read first

1. `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-K17-giveback.md`, in full (the independent review: its
   answers 2, 3, 5, 9, 11 and its six findings).
2. `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-K17-give-back-judged.md` and, on the branch,
   `archiver/docs/progress/core-giveback-REPORT.md` and the diff `git diff 78739d59 bd195424 -- archiver/internal/catalog`.
3. The reviewer's probes (read-only; take them over as tests where this brief says so):
   `wt-core-giveback-review-scratch\archiver\internal\catalog\zz_probe_k17_*_test.go`.

## The decisions (the Core session's, on every finding)

1. **Finding 1, must fix: the give-back's role column goes.** A file carried only as an alternative version
   is a legitimate waiting state in four ways the review showed (an edit that replaces the attachment while
   another message carries the file as an alternative; a deleted space; a removed account whose private chat
   carried it; "always download"), and a give-back cannot tell those from an edit made during its transfer.
   Holding what the rules want downloaded, for good, is worse than what the column closed. So:
   - `giveBackReadSQL` answers ONE thing: no carrier collects the file under the full rule (kinds and
     topics). `judgeGivenBack` runs the settle's four statements and nothing else. `giveBack`, `requeueOne`
     and their callers lose the role answer.
   - `ladder.go` goes back to the main head's bytes (`git checkout 78739d59 -- archiver/internal/catalog/ladder.go`):
     `roleHoldSQL` is no longer used outside `roleChanged`, so the piece does not touch that file.
   - **The brief's case 4 (a file in transfer when an edit leaves it only an alternative version comes back
     wanted) is then open again, as on the head, and is WRITTEN DOWN as known:** in the comment above the
     give-back's rule in `state.go` (what it is, that it is bounded by the transfers under way during such an
     edit, that the bytes are a lesser version from a chat the owner chose, never from a source the owner did
     not choose, and that closing it needs a mark written when `roleChanged` meets a file in transfer), and
     in the report. Its probe test stays in the tree as a test of what IS (it asserts the file comes back
     wanted, named so: e.g. `TestGiveBackRoleKnownOpen`), so that whoever closes it later sees the test
     change.
   - The tests of the role column (`TestGiveBackProbeRole`, `TestGiveBackRoleOwnersWord`, the role class of
     `TestGiveBackTwins` and of the owner's-hand test) are changed to the above or removed; say each by name
     in the report (functions removed: list them; this is the one place where removing a test is right).
2. **Finding 6: the four paths as tests, through the real doors** (take the reviewer's
   `zz_probe_k17_alt_test.go` over, renamed without the `zz` prefix, and the "edit: replaced" class of its
   twins): an edit made through the page-save door that replaces the attachment, `DeleteSpace`, an account's
   removal, an "always download" unskip: in each the file in transfer, given back by each of the four doors,
   ends as its waiting twin (wanted, supplied). Each seen FAILING on bd195424 first.
3. **Finding 3: `RecoverActive` on a read-only handle answers what the head answered** (`ErrReadOnly`), also
   with nothing active: the check comes before the read. A test.
4. **`recoverChunk`: 150** (the review measured 54 to 56 ms for a chunk of 250 judged rows; the settle's own
   target for one write is 40 ms). Measure the longest chunk at 150 all-judged rows three times and put the
   numbers in the report; the test's bounds stay as they are.
5. **Findings 4 and 5, the report's words:** "the settle's own bound" becomes what it is (the test's bounds,
   150 ms at p99 and 250 ms at worst; the settle's target for one write is 40 ms); the common case's cost is
   said as measured. **Measure `Release` again after this round** (the read is now one answer): the common
   case and the held case, three runs each at 100,000 want rows, beside the reviewer's numbers for the head
   (333 µs, spread 312 to 350; held 223 µs) and for bd195424 (379 µs; held 424 µs).
6. **Finding 2 is not code:** the Core session tells the copies track. In the report, one paragraph: what a
   trigger `AFTER UPDATE OF state` on `c_want` sees at each door after this round (the reviewer's
   `TestZZK17Trigger` shows how; run it on your head and give its counts).

Nothing else changes. The claim path stays untouched.

## Also, for the full runs (the Core session starts them, not you)

List in the report, by exact test name patterns, the tests OUTSIDE `internal/catalog` that reach `Release`,
the requeue, `RecoverActive` or an account's removal: in `internal/supply` and in `internal/collector`
(restart, stop, chosen chats, the baseline, an account deleted). Read them by `grep`; do not run the
collector's.

## Checks

The new and changed tests by name; the piece's whole test file (`-run 'TestGiveBack'`); the existing tests
named in the first brief's test 6, by name, once; `gofmt -l`; `go build ./...`; `go vet ./internal/catalog`.

## Hand back

The report file brought up to date and committed, the branch pushed, and your last message, short: the head;
per decision above what was done; test functions removed and added, by name; the timings; the trigger
paragraph; the list for the full runs; anything that is not as this brief says. Then stop.
