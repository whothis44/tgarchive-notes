# Brief M6b: the fix round for M6, adopting a chat (session M-6, 11-16)

For the same coder, in `wt-mirror-adopt` on `wip/mirror-adopt` from 44c6a3f7. The independent review
(`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review15-scratch\REVIEW.md`: read it whole first; its probes
are beside it, read-only for you) says **"may be listed after these fixes"**: 1 high, 5 medium, 8 low; 0 wrong
"there" in 1,600 random worlds; the app-made settle unchanged in 300; 23 of 27 planted changes caught. My own
read found two more (K1, K2). Every finding is accepted as decided below. One commit per fix, each with a test
that fails without it (take the reviewer's probes over as tests of your own where one exists). The rules of
`BRIEF-M6-adopt-chat.md` hold unchanged (every go command through `go1.sh`; named tests with `-timeout`; no
whole package, no race detector; privacy; stop and say so when a file outside the list must change).

## 0. First: the main head
Merge the main head into the branch (`git merge --no-ff claude/charming-feynman-vm2xia`, after a `git fetch
private` in `repo-archiver` shows local and `private` equal). It holds K14 now: **the catalogue is at schema
step 25 on the head; yours is the step after it.** One conflict is expected, `internal/catalog/catalog.go`, in
the schema's three places: your "after" constant becomes K14's step, `SchemaVersion` yours, both entries in
`steps`, both cases in the switch. Look at how K14's merge left `pairword_test.go`'s line about the newest step
and do the same for K14's own such test if it has one (name any line outside the mirror's files in your
report). It also brought the pages' control for the switch (`livepages`, `pages_mirrors.go`) and copies' lines
in `command.go`: no rule of yours changes. Build and your named tests again before anything else.

## 1. The fixes
- **F1 (review H1, high): what the adoption weighed must bound what is forwarded later.** The weigh tells
  messages with media only by default, the record does not keep that choice, and a later run with every
  message (the owner's, or the automatic task's) forwards text that is already in the chat. **Decided:** the
  mirror row keeps two more facts, in the same schema step: `adopt_all` (the adoption weighed every message)
  and `adopt_src_top` (the source's highest message id on record at the weigh). On an adopted mirror whose
  adoption weighed media only, a message WITHOUT media with an id up to `adopt_src_top` is never a candidate,
  whatever a later run or the automatic task asks for (it was not weighed: it may be in the chat); above
  `adopt_src_top` the run's own choice holds. The plan of the adoption says so in fixed words ("messages
  without media that the source holds now are not weighed and will never be forwarded into this chat; adopt
  with every message to have them weighed"), and so does the plan of a later every-message run on such a
  mirror, with the count left out. With `adopt_all` nothing is left out. Tests: the reviewer's probe (the
  every-message candidates after a media-only adoption), the automatic task with its every-message switch,
  a text message newer than `adopt_src_top` (it goes).
- **F2 (review M1): messages without media that share one origin.** They follow the single message's rule:
  "not there" only when the chat has no message with neither a post-naming origin nor media; else "cannot
  tell". The reviewer's random worlds found 14 wrong "not there" of about 7,500: take its case over.
- **F3 (review M2): an album is never cut by a waiting member.** While any member of an album waits for the
  owner's word, no member of that album is a candidate (the album goes whole after the word, or its members
  that are not "there" go together). An album of which some members are "there" and the others "not there"
  forwards the missing ones together, as today. A test with an album of 3, the middle one waiting.
- **F4 (review M3 and M4): the two planted changes no test caught.** A test for part E's safety half (on an
  adopted mirror a message of the chat that shares a media row with the batch stays "unexplained"), and one
  for the record's re-check of each refusal inside its transaction (a refusal that becomes true between the
  plan and the record: nothing written), each failing with the reviewer's plant.
- **F5 (my K1): a copy told "there" must exist now.** The command's read of the chat is a pass of what is
  newer than what is stored; a copy the owner deleted from the chat since an earlier read, with no live
  update, is still a row "not known deleted" and is told "there": a hole. **Decided:** when the chat had
  messages on record before this command's read began, the copies told "there" are confirmed by id lists
  before the record (the existing kind of request: 100 ids a request; counted per kind as the other
  requests are; every stated wait slept in full; a wait over the command's bound ends the command with
  nothing written). Its cost is shown with the reads' ("about K requests to confirm the copies"). A copy
  that is gone is marked deleted as the catalogue marks a deletion elsewhere, and the weigh is done again
  before the counts are shown; an id list that fails or is cut off: nothing is recorded, said. For a chat
  this command read whole for the first time nothing is asked (its evidence is of now). Read
  `internal/telegram/refresh.go` first: if it has a call that answers which ids of a chat still exist, use
  it; if not, a small new file of the mirror's own in `internal/telegram` beside the forward code (not a
  change to Core's file), and the fake's existing id-list answer. Tests on the fake: a copy deleted since an
  earlier read becomes "not there" and is forwarded; a chat read for the first time costs 0 such requests;
  the request count for 250 copies is 3; a failed id list writes nothing.
- **F6 (my K2, and review L2): the owner's word and a blocking batch.** `AdoptTake` is refused in fixed words
  while a batch of the mirror is sending, unknown or already (the settle would otherwise find "a batch after
  the blocking one" and answer bad ledger for good). And the adoption's batch rows (both reasons) are left
  out of `MirrorSettleGuard` and of every other reader that takes a batch row for a request: the reviewer's
  L2 names the guard; search again.
- **F7 (review L1 and L3): the waiting messages and the adoption's rows are said where the owner looks.** The
  plan of `mirror N` on an adopted mirror and `mirror -list` say how many messages wait for the owner's word
  and how to give it, and `mirror -list` says the adoption's rows as "found in the chat at the adoption" and
  "taken as arrived by the owner", not as forwarded batches. The pages' facts gain the waiting count beside
  "adopted" (one field; no page changes).
- **F8 (review L6): the source's migration twin is refused as the chat to adopt** (a basic group and the
  supergroup it became are one chat: rule 12), in the plan and in the record's re-check.
- **F9 (review L7): the refused post's words and block only for a refusal that names the chat's rights.** A
  refusal for another reason (a source message that is gone, a restricted source) is handled as today, with
  today's words. List the refusals you take as "the account may not post here" in the report.
- **F10: the report.** A section "M6b": each fix, the tests added, the runs; and the reviewer's L3 (the one
  reader missing from your list) added to the list of readers.

## 2. Left as they are, and said under "Known" in the report
- Review M5, first half and L4: an edit of a source message's media that the catalogue has not seen (the
  source's read is also a pass of what is newer): its copy made after the edit without a post-naming origin
  is told "not there" (a second copy; rare: such copies were 1 of 751 in the test mirror); a copy made before
  an edit counts as "there" with the old file, as in the settle.
- Review M5, second half and L5: what the owner forwards into the chat by hand after the adoption's reads
  began is not known to the app: a later run may forward the same message again. **The adoption's plan says
  this in one line of fixed words before the second yes** (that line is part of this round). A weigh again
  at each later run of an adopted mirror would close it: not in this piece.
- Review L8 (no index on `c_mirror.mirror_chat`: the scans are small); the reviewer's plants W3 and R5 (not
  defects).

## 3. Runs and the hand-back
Your new tests and every adoption test of the first round by name in the three packages; the settle's
existing tests by name; the catalogue's schema tests by name (the step moved); gofmt and vet on the three
packages; one script. Final message as before, short: the head's 8-character hash; the merge (the head's
hash, what the conflict was, any line outside the mirror's files); each fix in one line; tests added (count)
and removed (0); every run with its "go1: exit N" line; anything not as written here; what is not verified.
