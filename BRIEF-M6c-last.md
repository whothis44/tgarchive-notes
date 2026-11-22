# Brief M6c: the last small round for M6, adopting a chat (session M-6, 11-16)

For the same coder, in `wt-mirror-adopt` on `wip/mirror-adopt` from 5e46b061. The reviewer's second pass (the
section "Second pass (5e46b061)" at the end of
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review15-scratch\REVIEW.md`: read it) closes every finding of
its first pass and my two, and says "may be listed after these fixes" for one new medium finding. Four small
fixes, one commit each, each with a test that fails without it; the rules of the earlier briefs hold (every go
command through `go1.sh`; named tests with `-timeout`; no whole package; privacy).

- **L1 (review N1, medium, confirmed): the id lists must sleep the waits of their own method.** `MessagesGone`
  sends `channels.getMessages` under the wait key "confirm", while a wait Telegram stated for that method is
  kept under the refresh's key: with a stored refresh wait still running the command sent 1 request anyway.
  **Every wait Telegram states is slept in full: this is the track's first rule.** The call uses the
  refresh's wait key (`refreshWhat`, as the reviewer names it; read how the refresher keys its waits and use
  exactly that), so a wait stored by either is honoured by both. A test: a refresh wait on record and not
  over: 0 requests before its end (or the command ends with the long wait's words when it is over the
  bound), 1 after. Take the reviewer's probe over.
- **L2 (review N5): two tests for rules no test holds.** The "names every id asked" check (its plant Q4) and
  the confirmation of a copy the weigh newly ties after a deletion (its plant Q10): take its probes
  `TestReview15BConfirmFewerIDs` and `TestReview15BConfirmTwice` over as tests of your own.
- **L3 (review N4): the words.** The command says the request by its right name for the chat's kind
  (`channels.getMessages` for a channel or supergroup). Counting under the refresh's kind stays (the same
  method): said under "Known".
- **L4 (review L6, the half still open): the chat to adopt's own migration family.** The refusals that ask
  whether the chat to adopt is a mirror's chat, a source or marked "never" also ask its migration twin (the
  basic group it came from, or the supergroup it became), in the plan and in the record's re-check. A test.
- **L5: the report.** A section "M6c": the four fixes, tests added, runs. Under "Known", added: review N2 (a
  source message that reaches the catalogue after the weigh with an id at or below `adopt_src_top`, a gap
  filled later, is decided by its id alone: a text is never forwarded, a media message is forwarded
  unweighed; the plan refuses an adoption while a gap is open, so it needs a gap that opens later below the
  top); review N3 (when a later id-list round fails, an earlier round's deletion mark stays: the copy is
  gone, the mark is true; the adoption is not written).

**Runs:** your new tests and every adoption test of both rounds by name in the packages you touched; the
telegram package's tests that name the forwarder's waits; gofmt and vet. Hand back as before, short: the
head's hash; each fix in one line; tests added, removed (0); the "go1: exit N" lines; anything not as written.
