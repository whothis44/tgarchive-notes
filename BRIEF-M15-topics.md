# Brief M15: a forum is mirrored as a forum, with the same topics

Mirror track, session M-7, 11-21. For one Opus 5.5 coder at high effort. Copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-topics`, branch `wip/mirror-topics`, cut from the main head
af4ca40e. **When the integrator announces a new main head on the board (`BOARD.md`, messages section; it will
hold K21, C22, M6 and M13, in about an hour from 21:40), merge it into your branch ONCE** (`git fetch private`,
`git merge private/claude/charming-feynman-vm2xia`); in conflicts keep both sides' meaning; your schema step then
becomes the step after that head's newest (its "after" constant moved). M14 (`wip/mirror-m14`, another coder,
the same `auto.go`) is NOT in your tree: the integrator joins the two, keeping both. Commit work in progress to
your branch and push it to `private` (`git push private wip/mirror-topics`), never any other branch. Commits:
`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. No archive numbers in messages.

**Rules (CLAUDE.md in the project folder):** nothing runs against Telegram (fake Telegram, invented data only);
never open `C:\Users\trabi\tgarchive-app`. **Tests: named tests (`-run`) and one small package at a time; no
whole run of `internal/collector` or `internal/catalog`; no race detector.** Git Bash, `source
/c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` before every `go`; `GOMAXPROCS=4`, `GOGC=25`.

## Why
The owner, 11-21, twice ("Are we working on the topics fix? If not, please add it"): "does our mirror function
also create topics (if topics are detected ... convert it to a group that supports topics and automatically
name them as per the source)?". FEATURES section 12, third round: "a forum is mirrored as a forum with the same
topics". Today a forum is not mirrored at all (`mirror.go` `WhyForum`, `door.go` `ErrWantForum`, `auto.go` Look
counts `Forums`). The owner's catalogue has 3 forums (read-only counts): 10, 1 and 7 topics on record; about
8,250, 12 and 70 media messages; one forum's media sit mostly in General (no topic).

What exists: `telegram.Forwarder.CreateMirror(ctx, account, title, forum bool)` makes a supergroup with topics
when `forum`; `telegram.Forwarder.CreateTopic` (messages.createForumTopic with a random id, one request, counted
as `Stats.Topic`, request kind "create topic"); `ForwardBatch(..., topic int)` sets `top_msg_id`. The catalogue:
`topic(chat_id, tg_topic_id, title, ..., chosen)`, `message.topic_id` (the topic row; NULL for General), the
reader keeps titles from `messages.getForumTopics` (`schema_topics.go`, "topics chosen per chat"). The fake
Telegram answers `getForumTopics` but not `createForumTopic` or `editForumTopic`: add both (mirror-owned answers).
**Never tried against Telegram: creating a topic, its cost and pace** (TELEGRAM-FACTS 11 "Not known: what a forum
topic does").

Read first: `internal/mirror/mirror.go` (the plan's blocks, `WhyForum`), `auto.go` (Look, mirrorTurn,
autoCreate, autoBatch, forward and its block rules), `step.go` (the `mirror` command's run: it must do the same),
`telegram/forward.go` CreateMirror, CreateTopic, ForwardBatch, `catalog/schema13.go` (ledger, candidates),
`schema_topics.go`, and the M4 reviews `docs/review/mirror-auto-*.md` (how a lost create's answer is settled:
`AutoEvTwoChannels`), `TRIED-BEFORE.md` sections 24 and 25 (13 rules).

## What to build
1. **A forum source is mirrored.** `WhyForum` no longer blocks the plan, the owner's want or the automatic
   task's take; Look no longer passes forums over. Its mirror is created with `forum = true` (a supergroup with
   topics; still private, no invite link, the same name rule). The mirror's row records that it is a forum.
2. **Topics ledger, a schema step** (the step after the head's on your branch, a new file
   `schema_mirrortopic.go`, the number in two constants, written on the board's schema section by the session):
   e.g. `c_mirror_topic(mirror_id, src_topic INT (the source's tg_topic_id), mirror_topic INT NULL (the mirror's
   topic id), title TEXT (the title last set at Telegram), state TEXT CHECK IN ('creating','created','unknown',
   'refused'), reason, begun_at, ended_at, PRIMARY KEY(mirror_id, src_topic))`. One row per source topic.
3. **Batches never mix topics.** Candidates are cut per topic: a batch holds messages of one source topic
   (General, `topic_id` NULL, is its own group and goes with no `top_msg_id`). Oldest first stays the order
   across the chat: the batch is the oldest candidate's topic's run of candidates. Albums stay whole (one topic).
   M14 changes `autoBatch`'s timing (single posts) in another branch: keep your change to the batch's TOPIC cut
   apart from the timing lines, so the join is clean.
4. **A topic is created before its first forward, as its own write.** When the batch's topic has no `created`
   row: that turn sends exactly one `CreateTopic` (title: the source topic's title as in the catalogue; an empty
   title: fixed words such as "Topic" with its number) and no forward; the forward goes in a later turn after the
   account's pause. A create is a write like any other: the account's pause and its random part before it, a
   stated wait slept in full and the pause lengthened, counted per kind. An intent row (`creating`) is written
   before the request, its end after, on a record context (as `BeginMirrorBatch` / `FinishMirrorBatch`).
5. **A topic create whose answer was lost (`unknown`)** is never sent again blindly: the next turn reads the
   mirror's topic list once (`messages.getForumTopics` of the MIRROR, the reader's existing call or one of the
   forwarder's, counted) and adopts the one topic of that title made after the intent; none: created again once
   (counted; a second loss blocks the want with words); two or more: the want is blocked with words ("two topics
   of one title in the mirror: the owner looks"). Follow how a lost create of the mirror chat itself is settled.
6. **A refused topic create** (any definite refusal) blocks the want with the refusal's words, as a refused
   create does today; `CHANNEL_FORUM_MISSING` / `ErrNotForum` (the mirror is not a forum) blocks with words that
   say so. Never sent again every pause.
7. **Renamed in the source, renamed in the mirror:** when the catalogue's source topic title differs from the
   row's `title`, one `messages.editForumTopic` (a new forwarder call `RenameTopic` beside `RenameMirror`: one
   request, never repeated by the layer, counted, the same error sorting) goes in a turn where that mirror has no
   batch ready to forward (saving posts comes first), at most one rename per turn. Telegram's "not modified"
   counts as done. A refused rename is recorded and NOT retried until the source title changes again; it never
   blocks forwards.
8. **Chosen topics:** if the source chat collects only chosen topics (`topic.chosen`, `schema_topics.go`), the
   mirror forwards those topics only (the same choice the owner made for the download), and says so in the
   plan's words and the doors' facts; otherwise every topic.
9. **A source that is a forum while its mirror is a plain channel** (an existing mirror, or a chat that became a
   forum): no conversion by itself. The want is blocked with words ("the source is a forum; its mirror has no
   topics: the owner decides") and nothing is forwarded for it. A chat that stops being a forum: its topics'
   later messages go to General's group (no `top_msg_id`).
10. **The `mirror` command** (`step.go`, the owner's own runs, `-history`) does the same for a forum source: its
    plan's cost counts the topic creates ("about N batches and K topics").
11. **Counts and words:** per turn and in the doors' facts per mirror: topics created, unknown, refused, renamed;
    every new event and block with fixed words (no apostrophes; `fixedOK`). Names and titles never go to a log
    line (privacy): counts and ids of the app's own rows only.
12. **Requests:** new kinds are `messages.createForumTopic` (exists in the layer), `messages.editForumTopic` (new)
    and the mirror's own `messages.getForumTopics` read for a lost create. Each is counted per kind and hour by
    the existing counters; nothing else new.

## Tests (named)
The fake: `createForumTopic` (answers `UpdateMessageID` with the random id and the topic's service message),
`editForumTopic` (and "not modified"), a forum mirror's topic list, `top_msg_id` on a forward placing the
messages in that topic, refusals (`CHANNEL_FORUM_MISSING`, a definite error, no answer, a wait). Cases: a forum
with three topics and General: the mirror made as a forum, three topic creates in three turns each after the
pause, forwards per topic with the right `top_msg_id`, General with none, albums whole, oldest first across
topics; a lost topic create adopted from the list / created again once / two of one title blocked; a refused
create blocked once and never sent again; a rename in the source gives one edit, not modified counts as done, a
refused rename does not block forwards and is not retried; chosen topics only; a forum source with a plain
mirror blocked with its words; the `mirror` command's plan and run; across a restart the topic rows hold; an
older file without the table read-only; the schema step on the head's version.

## Hand back
Commits on `wip/mirror-topics` pushed to `private` (the head's id; whether the new main head is merged in);
files changed; every reader of the new table and of a forum mirror's row; the new requests and where each is
counted; the named tests with result lines (counts and times); what you did not do or found wrong in this brief.
gofmt your files. Do not run the full packages.

## Fix round T1 (the session, after the hand-back of bd48566b)
1. **Batches per topic, not per consecutive run.** The batch is the oldest candidate's topic, then THAT topic's
   oldest candidates up to the maximum (other topics' messages in between wait for their own batches; albums
   whole). Oldest first holds within each topic (each topic is its own thread in the mirror); across topics the
   next batch is again the topic of the oldest candidate left. The plan's "about N batches" counts per topic. A
   test: two topics interleaved one by one, 200 messages: 2 to 4 batches, not 200.
2. **No owner block for a topic (the owner, 11-21: "The owner will be away from the computer. Why wouldn't the
   mirror continue automatically?").** (a) Two or more topics of one title made after the intent: they are the
   app's own; take the one of the lowest id, leave the others unused and count them ("N spare topics"), no block.
   (b) A second lost create: no block; tried again by itself after 10 min, 30 min, 1 h, 3 h, 6 h, then every 6 h
   (durable; each counted), the other topics going on meanwhile. (c) A refused topic create (a definite answer):
   the same backoff for that topic only; the other topics and General go on. (d) `CHANNEL_FORUM_MISSING` (the
   mirror is not a forum): hold that chat and try again by the same backoff, said on the page. (e) Left as a
   block: only a forum source whose mirror is a plain channel (the owner's question about converting), with its
   words. (f) A rename with no answer twice: recorded, tried again when the source title changes, never a block.
   Say in the hand-back every block that is left.
3. A test for "a chat that stops being a forum" (later messages to General).
Hand back as before (head, tests by name, the whole internal/mirror and faketg).

## Fix round T2 (the independent review M15-R of e54c7163; its file, probes and overlay:
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review18-scratch\` (`archiver\docs\review\mirror-m15-2026-11-21.md`,
`probe\zz_m15r_probe_test.go`, `overlay.json`); read it first; copy the review file unchanged into
`archiver/docs/review/` on your branch)
1. **F1:** a failed read of the mirror's topic list after a lost create goes under the same STORED back-off as a
   held topic (10 min ... every 6 h, durable across a restart); that topic only waits; General and the other topics
   go on. A test: 24 hours of refusals and of server errors: at most the back-off's reads, forwards of the other
   topics go on.
2. **F2:** `MirrorNameOnRecord` (`mirrorsettle.go:901`) counts `kind IN ('channel','forum')`, as the lost-create
   search does; a test that a lost forum mirror's create is never taken as "not made".
3. **F3:** a forward refused for ONE topic (`TOPIC_DELETED`, `TOPIC_CLOSED` and the like, by error type) holds
   that topic under the back-off and remakes it (a new topic create) at the retry; the other topics and General go
   on. No block.
4. **F4:** `-list` (`mirror_marks.go`) says the forum facts (topics made, held with until, spares, not-a-forum
   hold). The page (`internal/collector/livepages/mirrors.go`, `convState` and the dead "not mirrored yet" words at
   ~136) is the pages track's: do NOT change it; list in the hand-back exactly which `ChatState` fields the page
   should show.
5. **F5:** after a not-a-forum hold ends, nothing goes with a `top_msg_id` until one request has shown the mirror is
   a forum again (the next topic create, or a General forward followed by one create): say which you chose.
6. **F6:** a forum mirror chat is never in the reader's topic pass (no recurring topic-list request for the app's
   own mirrors). If the line belongs in `internal/collector/reader.go` (Core's file), keep it to one condition and
   name it in the hand-back as a lent line.
7. **F7:** `BeginMirrorTopicRename` re-checks the owner's stop and never mark (`intentHeld`) as creates and batches do.
Tests one per finding; then gofmt, vet, the whole internal/mirror and faketg, the named tests touched. Push; hand back.
