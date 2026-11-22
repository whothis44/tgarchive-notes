# Brief P2b: fixes to `wip/pages-notadded` after its independent review

Written by session P (pages), 2026-11-15, after the review of b06df4c (no blocker). Same copy
(`wt-pages-notadded`), same branch, same working rules as before (named tests only, one test command
at a time, `GOMAXPROCS=4`, commit and push after each fix). Line references are the reviewer's.

## Must fix
**S1. The Chats load must not wait behind write routes** (`notadded.go` `coverages`). A separate
`covMu sync.Mutex` guards only `s.cov`; `s.mu` is not taken by a page load. `covDirty` stays atomic.
No goroutine. A test: a load answers while `s.mu` is held by the test.

**S2. Forwards from a supergroup or forum cannot be counted.** `internal/telegram/record.go`
`forwardOrigin` (lines 285 to 296): a forward of a member's message from a group carries the author,
not a post of the group, so its origin never falls in the group's range and "no file was forwarded
from it" is false. `from_here` is worked out and sent for kind `channel` only. For a supergroup or
forum not added, the row says in fixed words: "Forwards from a group name their sender, not the
group, so they cannot be counted." Change the invented archive so that its not-added supergroup has
no forwards that name its posts, and its channels do; fix the tests that proved the impossible case.

**S3. A removed account does not decide the read word.** In `summarise`, an account marked removed is
skipped for the word, for `added` and for the messages and total of a read under way (its newest
message number and estimate may still be shown). Test: the reviewer's example (account 1 removed with
a cursor, account 2 a member with nothing: the chat is `never`, `not_added` true).

**S4. Phone width.** `.t.stack td.not-read { display:block; text-align:left }` in `parts.css`, as
`td.lead` has. Check it at 400 px in the built-in browser on the invented archive and say what you saw.

## Should fix
**M1.** The kept counts' key also holds `(SELECT MAX(rowid) FROM copy_edge)` and
`(SELECT MAX(id) FROM chat)`: a new exact edge or a new chat row does not move the change log. Confirm
with `EXPLAIN QUERY PLAN` in a test that all three reads are seeks, not scans.
**M2.** When the counts are older than the page's read facts (kept through a change), the two
sentences that depend on "no files" together with a read state ("Read to its end: it has no files.",
"Not read yet...") are not used for a chat whose counts say 0 files but whose read is done or under
way: return "" then (the row already shows "file counts as of").
**M3.** `ChatCoverage` gains `Alternative` (of `NotCollected`), as `TopicCoverage` has; `chatWhy` says
`whyNotCollected` when the not-collected files are mostly alternative versions, never "kinds" or
"topics not chosen" for them.
**M4.** A mirror with nothing wanted says: "One of the app's own mirrors: nothing is read from it."
**M5.** `whyUnreachable` becomes "No account can reach it now." (the cause may be a removed account or
a group that became a supergroup).
**M7.** `from_here.saved` also counts a file skipped on an exact edge to a saved file (as the coverage's
`is_exact`).
**M8.** The command and the words around it. Show the whole command:
`tgarchive-collector run -db <catalogue> -staging <folder> -approve-read <chat number>` and
"add `-account <n>` when more than one account is signed in". The words: "This starts the collector as
usual (chats already added go on reading and downloading); it shows this chat's read cost and asks
before reading it." Nothing on the page may suggest that the command only asks a question.
**M9.** The Read filter: "All / Not added yet (n) / Approved or being read (n) / Read to the end (n)",
every chat in exactly one of the last three, tested.
**M10.** The spanning cell has an `aria-label` naming what it replaces ("File counts: not read yet").
**M11.** Measure, in the size test, the read-facts statement with one chat of 300,000 messages under
way: print the time. If it is over 100 ms, take the count once per chat (not per account row) and say
what it became.
**The invented archive.** `tgarchive fabricate` gets a flag `-reads` (default off) instead of always
setting it, so the viewer track's browser checks keep their archive; the owner's command line in your
report uses `-reads`.

## Left, to be written into the merge queue by the session (no code)
M6 (a write route that changes nothing still forces one recount); a chat never added can have files
through the live monitor, and the page then shows numbers beside "not added yet".

## At the end, once
`GOMAXPROCS=4 go test ./internal/catalog -run 'TestNotAdded|TestCoverage|TestTopic' -short -count=1`,
`GOMAXPROCS=4 go test ./internal/server -count=1` (the whole package: it is small),
`GOMAXPROCS=4 go test ./internal/fabricate -count=1`, `gofmt -l`, `go vet` on the four packages.
Hand back: commits, one line per finding, anything done differently and why, tests with timings,
M11's number, what you saw at phone width, what is still open.
