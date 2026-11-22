# Brief P1b: fixes to `wip/pages-topics` after its independent review

Written by session P (pages), 2026-11-15, after the review of 5b57467. Same copy (`wt-pages-topics`), same
branch, same working rules as `BRIEF-P1-topics.md` (named tests only, commit and push after each fix,
nothing outside the allowed files except where this brief names a file). I checked S1, S2 and M2 in the
code myself; the others are the reviewer's with line references. Do them in this order, a commit each
where it makes sense.

## Must fix
**S1. A forum's General topic.** `internal/telegram/record.go` (lines 149 to 153) says a message in a
forum's General topic carries no topic header, so its `topic_id` is NULL in the catalogue, while
`SaveTopics` stores General as a topic row with `tg_topic_id = 1`. Today, with "only chosen topics" on,
General's files can never be chosen, and General's row says "No files listed in this topic yet", which
is false. Decided: **a message with no topic in a chat that has a topic row with `tg_topic_id = 1`
belongs to that topic** for the rule, the counts and the page.
- `topicPassSQL` and `topicPasses`: also pass when `m.topic_id IS NULL` and the chat's `tg_topic_id = 1`
  topic is chosen (one seek of `UNIQUE(chat_id, tg_topic_id)`).
- Choosing or un-choosing the `tg_topic_id = 1` topic must judge the chat's no-topic messages too: they
  are not in `message_topic`. Store the space intent (`settleChatTopics`) for that topic, in the trigger
  as well, so direct SQL is followed.
- A rank on that topic: `bestRankSQL` only knows `m.topic_id`. Do **not** change the rank path (it is
  lane-order code): instead the page and the route refuse a rank on the General topic with a fixed
  sentence ("General has no rank of its own: its messages carry no topic; rank the chat"), unless you
  find it is one line and provably the same plan. Say what you did.
- `TopicCoverages`: the no-topic row is folded into the `tg_topic_id = 1` topic's row when the chat has
  one; a chat without such a row keeps the "messages in no topic" row, with a Collect box of its own
  only if you can do it without a new column (otherwise that row says in fixed words why it cannot be
  chosen). Counts still add up, tested.

**S2. A message moved to another topic by an edit** (`internal/catalog/tgrows.go`, the
`UPDATE message SET topic_id` near line 383). When the chat collects only chosen topics and the topic
changed, judge that message's files again in the same transaction, inline, no intent:
`wantedAsMainIn` over `IN (SELECT tg_media_id FROM attachment WHERE message_id = ?1)` with
`collectedSQL(..., true)`, then both `topicHoldSQL` statements. No read at all when the chat is not
`topics_only` or the topic did not change. Named test, both directions.

**S3. `SetChatTopicsOnly(on)` on a chat already on** chooses ranked topics again and leaves an intent
nobody settles. Read `topics_only` first and return before any write when it is unchanged.

**S4. The answer's counts can include another action's files.** Before storing an intent in
`SetTopicChosen` and `SetChatTopicsOnly`, take and discard both count keys; `SetTopicRank` takes its
counts after settling (and returns them, so the rank route's `collected` comes from there). When the
intent is still pending after the call (`SettlePending`), the route answers with `pending: true` and
the page says in fixed words "Stored. The files are still being moved; reload to see the numbers",
never "No file changes state".

**S5. A cancelled request or a settle error.**
- The two catalogue calls in `handleTopicsOnly` and `handleTopicChosen`, and the topic-rank call, run
  on `context.WithoutCancel(r.Context())`.
- `settleTopics` does not return Settle's error as the action's failure: the choice is stored; it
  reports "pending" as in S4 (as `SetChatRank` does through `settleNow`).
- At the app's start (not demo, catalogue writable), before it listens: if `SettlePending`, run one
  `Settle` synchronously and print one fixed line with the counts. **No new goroutine.** Find the right
  place in `internal/server` or `cmd/tgarchive/app.go` and say which.

## Should fix
**M1.** A file the owner released by hand (reason `"by the owner"`, `ReasonOwner` in
`server/queue.go`) is not held again by a topic action: move the constant into `internal/catalog`
(the server keeps using it from there) and exclude it in `topicHoldSQL[0]`.
**M2.** `staging.go` `WantAgain` (near line 631): a file carried where its kind is collected but its
topic is not gets `ReasonTopicPref`, not `ReasonChatPref`. One more fact in its query; nothing else in
that file.
**M3.** Count the probable-only flips: `TopicEffect` gains `Supplied` and `NotSupplied` (probable
copies that are again, or no longer, taken after every other file), reported by the routes and said by
the page in plain words.
**M5.** Un-choosing a ranked topic is refused with a field error ("remove its rank first"), in the
catalogue (`SetTopicChosen`) and so in the route; switching on says how many ranked topics it chose
(`chosen_ranked` in the answer, a sentence on the page).
**M6.** In `TopicCoverages` a file skipped on an exact edge to a saved file counts as saved (as the chat
row's "through other chats" does: see `ChatCoverages`' `is_exact`), not in Other; the `why` for
not-collected alternative versions does not say "kinds".
**M8.** `TestTopicSchemaStep` must not assert `topicsAfter == loggingSchema`: it has to pass after the
integrator renumbers the two constants.

## Left as it is, written down (put these three lines in a comment at the top of `topics.go`)
- A file in transfer or set aside when its topic is un-chosen finishes or comes back wanted (M4):
  `state.go` is not ours to change.
- "Always download" un-skips do not look at the topic rule (M7), as they do not look at the kinds.
- A topic action applies the whole `wantedAsMain` rule, so inside its scope a kind switched on "for
  files from now on" also reaches older files that a carrier now collects.

## Tests to add (named `TestTopic...`; all earlier ones must still pass)
General chosen and un-chosen with no-topic messages; the edit both ways (S2); S3's no-op; S4's sequence
(rank, then un-choose after removing the rank: the second answer counts only its own files); a pending
answer when Settle is made to stop (an already cancelled context is enough); M1; M2; M3's counts; M5's
refusal; M6's count. In the oracle: add an alternative-role carrier and a kind switch between actions,
and compare the reason for held probable copies. In the size test: one more case, 2,000 files each
carried by 100 messages of one topic, and the chunk's longest time for it, printed.
Run at the end, once: `go test ./internal/catalog -run 'TestTopic|TestCoverage|TestWantAgain|TestCat3RoleChangeMatrix|TestHoldProbableStates|TestMigrate|TestSchemaStep12' -count=1`
and `go test ./internal/server -run 'TestTopic|TestChat|TestQueue|TestWriteGuards|TestCrossSite|TestDemo|TestCSP' -count=1`;
`gofmt -l` and `go vet` on the two packages.

## Hand back
Commits, what changed per finding in one line each, anything you did differently and why, the test
names with timings, the new size number, and what is still open.
