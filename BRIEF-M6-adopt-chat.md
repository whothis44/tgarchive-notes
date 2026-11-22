# Brief M6: an existing chat of the owner's as a source's mirror (session M-6, 11-16)

**For one Opus coder (high effort).** Branch `wip/mirror-adopt`, its own copy `wt-mirror-adopt`, cut from the main
head that holds M10. You hand back commit-ready work on that branch, pushed to `private` as you go (never the
main branch, never `origin`). Nothing in this piece runs against Telegram: the fake only.

**The rules that bind you before anything else (the project folder's `CLAUDE.md`, archiver section):**
- Routine sequences (format, vet, named tests, a commit, a push) are one script of yours or one Sonnet clerk
  call, not call by call in your context. Say in your report which.
- While working run only named tests (`-run`, with a `-timeout` on every line). **No whole run of
  `internal/catalog` or `internal/collector`, no race detector:** the full runs happen once, after the review.
- **Every go, gofmt and vet command goes through the track's one script, which takes a lock, measures the PC
  and waits** (another coder of this track works beside you, in `wt-mirror-cap`, on the cap of new mirrors:
  `mirror/auto.go`, `mirror/door.go`, `mirror_door.go`; you will meet its lines at the merge, not before):
  `bash /c/Users/trabi/Claude/Projects/Telegram/runs-mirror-m6/go1.sh <your copy's archiver folder> go test ...`.
  Never `go` directly. On its exit 98 (the PC stayed busy) go on writing and try again later.
- Counts, sizes and timings only in every log line, test name, commit message and report: never a chat's name,
  a message's text, a path of the owner's or a Telegram id. New log lines use constant format strings.
- You stop and write to me (your report's first lines) instead of deciding, when: a rule below cannot be kept
  as written; a file outside the list at the end must change; the schema step needs more than is named.

## 1. What the owner asked, and what was decided
The owner (11-15 12:38): "a nice feature to have, in case I attach the app to an existing account, and want you
to effectively create a cloud mirror". Instead of a new channel the owner names a chat the account already has
(filled by hand, 100 forwards at a time) as the mirror of a source. What is already in it is never forwarded a
second time. The design is `DESIGN-M6-adopt-chat.md` in the project folder (read it first, one page); the owner
decided it "as written" (11-15 21:53): messages that cannot be told wait for the owner's word and are never
guessed; the chat is kept current by itself only when the command says so. **The owner's chat is never renamed,
emptied, switched off or counted as made by the app.**

## 2. What the old app and the record already know (read before you design anything)
- **The old app has nothing that forwards.** What it has is what goes wrong when an app acts for its owner:
  12.30 added 30 chats by itself and the owner switched 24 off by hand within the day; two clicks at once lost
  81 of 150 "never" marks kept as one stored list; a queue action that matched on a computed expression was a
  scan of 361,378 rows per file, 1,000 files timed out. From these the 13 rules of
  `archiver/docs/TRIED-BEFORE.md` sections 24 and 25 (read both sections): never undo a person's stop or mark;
  a "never" checked again before every request; Telegram's waits stored and checked at the top of every step;
  one item per call; no request for an item that will never be acted on; a cap per step; one row per item; a
  mark follows the chat through a migration; fail closed (a mark or row that cannot be read stops the step, a
  corrupt value never reads as empty). And `LESSONS-ix12.30-live.md` section 6b in the project folder: what the
  app does stays below the owner's choices; every action on many rows is one statement on an index, tested at
  real size.
- **The new app's own numbers (the mirror command's real runs, `archiver/docs/TELEGRAM-FACTS.md` section 11):** a
  forwarded message names its source post; a source message that is itself a forward keeps its ORIGINAL origin
  on its copy; a hidden sender leaves none. The settle built on this ran for real: 65 of 99 told (64 by the
  post each forward names, 1 by the same media), none wrong, none twice. In the test mirror 1 of 751 copies
  carried no post-naming origin.
- **Where those rules failed in their three reviews** (each was a second copy or a hole until the rule said
  "cannot tell"): an origin without a post number is a sender, never an identity; a repost inside the source and
  its original share one origin; an edit changes a message's media rows on one side only; alternative-quality
  rows differ between a source and its copy. Adoption meets all of them at once over a whole chat.
- **So: port the settle's rules, do not invent new ones.** They are the head comment and `weighBatch` of
  `internal/catalog/mirrorsettle.go`: read both in full before writing a line.

## 3. What my four code readings found (11-16; check each, they decide the shape)
1. **`weighBatch` cannot be called for a whole chat.** It is bound to one blocking batch (its rules 1 and 2) and
   its media pass and `couldBeOwn` compare every message of the batch with every eligible mirror message
   (fine at 100, about 2.5 thousand million steps at 50,000 by 50,000); `sourceKeys` and `mediaOf` ask two
   queries per message. Adoption needs **its own weigh in set form** (maps by origin key, by media key and by
   single media row; the rows read by a few set queries on the existing indexes), with the same rules.
2. **`AdoptMirror` (`schema_mirrorauto.go`) is not reusable beyond its shape** (one transaction, checked again
   inside). It adopts the channel of a create whose answer was lost: it requires the row "creating" or
   "unknown", sets `chat.mirror_of` and switches the chat off for downloads. An owner's chat gets neither.
3. **Whether the account may post in a chat is not on record.** `internal/telegram/dialogs.go` keeps "left",
   the view ban and the megagroup flag; no creator or admin rights. So the plan cannot refuse beforehand: it
   says so in fixed words, and the first forward is the test. Recording the rights from the chat list is NOT
   in this piece.
4. **Every reader of `chat.mirror_of` means "the app's own chat":** the owner's switch for downloads is refused
   on it (`OwnerSetChatCollect`: `ErrMirrorChat`), the client's writes are refused (`telegram/act.go`
   `IsMirror`, the viewer's `actMirrors`), the mass switch-off passes it over, `ChatsMadeOff` leaves it out,
   `MirrorNameOnRecord` and `lostCreateSQL` use it, the plan refuses it as a source (`WhyIsMirror`), the look
   passes it over. **So `mirror_of` is NOT set for an adopted chat**: the relation lives in the mirror row
   (`c_mirror.mirror_chat`) with a mark that it was adopted. What an adopted chat must still inherit comes
   through the mirror row instead (part D).
5. Found on the way: **the pace reads every batch row as a forward request**
   (`mirrorpace.go`: `mirrorLastForwardSQL`, `mirrorSentSinceSQL`; and the query at about line 776 of
   `schema_mirrorauto.go`), and **`MirrorCreatesSince` counts every mirror row as a create** against the cap
   on new mirrors. An adoption makes no request and no channel: neither may see it (part C).

## 4. What to build

### A. The command (in `internal/collector`, the mirror command's files; the logic in `internal/mirror`)
`mirror -adopt N -into M` (N: the source's chat number in the catalogue, M: the existing chat's), with
`-keep-current` (off by default) and the mirror command's existing choice of "media only (default) or every
message". It is only ever the owner's command: nothing automatic calls any of it.
1. **The plan: read-only, no request.** It refuses in fixed words (sentinels in `words.go`, one line) when: N
   has an open mirror row or a want of any kind; M is one of the app's mirrors (`mirror_of`), or the chat of
   an open mirror row, or the source of a mirror row or a want, or is N; M is not a channel or a supergroup
   (a forum and a basic group are refused in this piece); N or M carries the "never" mark; N is known
   protected; N is one of the app's mirrors; the account is not in N or in M by Telegram's evidence; the
   account is frozen (as the mirror command refuses today). It says, in fixed words, that whether the account
   may post in M is not on record and the first forward will show it.
2. **First yes: the reads.** N is read as the mirror command reads a source today (its cost shown first, to
   its end). M is read the same way: its cost shown first (one request for the estimate, then the pages),
   messages only, to its end. **M's switch for downloads and every other choice of the owner's on M is the
   same after the read as before** (a test compares the chat's row and the owner's records). Each read must be
   a pass this command began and that finished; a pass that did not finish: nothing is weighed, said.
3. **The weigh (part B), then the counts and the second yes:** "of N's X messages: A are in the chat, B are
   not, C cannot be told; B will be forwarded in about K batches, after what is there (so the chat is not
   oldest first); M holds U messages that are not N's". With C above 0 it says that those wait for the owner's
   word and block nothing.
4. **After the second yes: the record (part C), in one transaction, then the usual run** of the mirror command
   for N as it is today (the same pause, bound per hour, album never split, every stated wait slept in full, an
   unknown outcome settled from the chat and never sent again). No new sending code.
5. **The owner's word for the waiting ones, later:** `mirror -adopt N -take arrived` or `-take not-arrived`
   (the settle's words and its risk lines, said before its yes): "arrived": they become rows "missing" (no
   mirror id known) and are never forwarded; "not-arrived": they become candidates. One transaction.
6. **`-keep-current`** writes the owner's want for N through the same catalogue function the page's "Mirror
   this chat" uses (no new kind of want), so the automatic task keeps it current as it does any owner's
   want. Without it there is no want: a test runs the automatic task's turns with its switch on and counts 0
   requests for N and for M.

### B. The weigh (new file in `internal/catalog`; reads only; the settle's rules in set form)
Keys exactly as the settle's rule 3 (`namesPost`; for a source that is a broadcast channel with no forward
origin on record, the source's marked id and the message id; the media key of the current main rows; every
row for "anything in common"). N's side for every uniqueness count is ALL of N's non-service messages on
record (a deleted one too: its copy may be in M); the messages told are the ones a mirror would forward (the
candidates' filter; media only by default). M's side is its non-service messages not known deleted.
For one message x of N:
- **By origin:** x has an origin key no other message of N has, and M has messages with that origin: there
  (its copy is the lowest id; more than one is counted "twice"), as the settle does.
- **An origin key several messages of N share:** when no message of M has that origin and none shares any
  media row with any of them: each is not there; otherwise each cannot be told.
- **By media** (x has no origin key, or no message of M names it): there, when exactly one message of M with no
  post-naming origin carries x's media key, x's media key is no other message's of N, and no other message of
  either side holds any media row of x or of that copy. Not there, when no message of M (whatever its origin)
  shares any media row with x. **Cannot tell in every other case**, and for a message with no key at all.
- A copy in M is tied to at most one message of N (an assertion and a test: two messages of N never get the
  same copy).
It returns the three lists, the counts by origin and by media, "twice", M's messages tied to nothing, and M's
highest message id on record. **Never by text, date or position.**
**At size:** a test builds 50,000 invented messages on each side (albums, reposts inside the source, edits,
alternatives among them) and prints the weigh's seconds; it must be linear in practice (a few seconds: say the
number; if it is above 30 s on this PC, stop and tell me).
Each rule gets a test that fails without it, and the cases of section 2's third point each get one: a sender-only
origin; a repost and its original; a source edited after its copy; an alternative on one side.

### C. The record (schema step 26: mine; the board has the claim)
- `c_mirror` gains `adopted_at INT NULL` (set: the row is an owner's adopted chat) and
  `adopt_top INT NOT NULL DEFAULT 0` (M's highest message id at the weigh); a new table
  `c_mirror_adopt_wait(mirror_id, src_msg)`, one row per message that waits for the owner's word. Follow the
  form of the mirror's earlier steps (`schema_mirrorname.go`, `schema_mirrorwant.go`): the step's own file,
  `catalog.go`'s three schema places, the "after" constant on the head's newest step (24 on the main head
  today; Core's K14 is 25 and may land first or second: whoever is second sets its constant), a read-only
  handle on an older file answering "none".
- **One transaction, everything checked again inside it:** the refusals of A1; the weigh done again inside the
  transaction must give the counts the owner saw (else nothing is written: "it changed, look again"). Then:
  the mirror row for N: created, M as its chat, started by the owner, `adopted_at`, `adopt_top`, its reason in
  fixed words, its stored name M's title as it is (catalogue only); the "there" rows as forward rows
  "forwarded" with their copy's id, on one batch row "done" whose reason is a new constant of fixed words
  that says no request went out; the waiting rows.
- **Not written, each with a test:** `chat.mirror_of`; M's download switch; a `c_chat_made` row; any name by the
  name rule (read `name.go` and the unique index on base and ordinal: an adopted row must take no number from
  the app's names: the next app-made mirror gets the name it would have got without the adoption).
- **An adoption is not a request and not a create:** `MirrorLastForwardAt`, `MirrorSentSince`, the third time
  reader and `MirrorCreatesSince` give the same answers before and after an adoption (a test each). Search for
  every other reader of `c_mirror_batch`, `c_mirror_forward` and `c_mirror` yourself, and list each in your
  report with one line: what an adopted row does there. The candidates' filter also leaves out the waiting
  rows.

### D. What an adopted mirror inherits, through its mirror row
- M is never a source while it is a mirror row's chat: the plan of `mirror M` and the page's door refuse it in
  fixed words, and the look (`MirrorAutoNewChats`) passes it over.
- The rename command and the name rule refuse an adopted mirror in fixed words.
- Nothing switches M off, and the owner's own switch and the client's writes work on M as on any chat of the
  owner's (a test: `OwnerSetChatCollect` on M after an adoption is not refused).
- **A forward refused because the account may not post in M** (read `internal/telegram/forward.go`'s sorting of
  refusals first, and say in your report what such a refusal does today): it ends the step in fixed words and
  is on record so that no forward for that mirror leaves again by itself, with or without `-keep-current`,
  until the owner's word (use the existing block of a want or the row's end words; no new mechanism if one
  fits). A test counts the forward requests over several turns of the automatic task after one such refusal:
  1.
- The pages' facts: the mirror's row for the pages gains one field, "adopted", and nothing else changes on a
  page in this piece (the page is the pages track's).

### E. The settle on an adopted mirror (`mirrorsettle.go`; the design's point 7)
- The eligible mirror messages are those above the larger of the ledger's newest copy and `adopt_top`.
- On an adopted mirror only: an eligible message that the batch does not explain is "not the batch's"
  (ignored, counted under a new number) when it shares no media row with any message of the batch (every row,
  either side); otherwise it stays "unexplained" as today. The plan of a settle on an adopted mirror says that
  such a chat asks the owner more often.
- **On a mirror the app made, every result is the same as before:** the settle's existing tests pass unchanged
  and none is removed or renamed.

## 5. Tests and what you run
- The fake Telegram (`internal/collector/faketg`, the mirror's create and forward answers) for one end-to-end
  test of the command: plan, the two reads, the counts, the record, the run forwards exactly B messages and
  none of A, a second run forwards 0.
- Named runs only, each line with its `-timeout`: your new tests by name in `internal/catalog`,
  `internal/mirror` and `internal/collector`, the settle's existing tests by name, `gofmt -l` and `go vet` on
  the three packages. One script, kept in the copy's report folder.
- No test function removed or renamed: say the count against the base in your report (0 expected).

## 6. Files
Yours to change: in `internal/catalog` the mirror's files (new `schema_mirroradopt.go` and `mirroradopt.go`,
`mirrorsettle.go`, `mirrorpace.go`, `schema13.go`, `schema_mirrorauto.go`, `schema_mirrorwant.go`,
`schema_mirrorname.go`) and `catalog.go`'s three schema places only; `internal/mirror`; in
`internal/collector` the mirror's command files (a new `mirror_adopt_cmd.go` beside `mirror_cmd.go` and
`mirror_settle_cmd.go`), `mirror_door.go` for D's refusal and the "adopted" fact, the mirror command's
paragraph of `command.go`'s help, one line of sentinels in `words.go`; the fake's mirror answers. **Nothing
else** (not `reader.go`, `account.go`, `collector.go`, `dialogs.go`, nothing of pages, the viewer or Core):
if a rule needs a line there, stop and name the line.

## 7. The hand-back
`archiver/docs/progress/mirror-adopt-REPORT.md` on the branch: what is built, part by part; every departure
from this brief with its reason; every reader of the three tables with its line; what a refused post does
today and after; the weigh's seconds at size; the tests added (count) and removed (0); the runs with their
"exit" lines and seconds, and by whom (script or clerk); what is NOT verified (nothing has met Telegram; the
rights question). One commit per part, the branch pushed, the copy clean. After it: my read of the weigh and
the record's transaction, then an independent review with probes, its fixes by you, the same reviewer again,
and the full runs once.
