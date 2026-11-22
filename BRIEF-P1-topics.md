# Brief P1: topics on the chat's own row (rank a topic; collect only chosen topics)

Written by session P (pages and chats), 2026-11-15 08:47. For an Opus 5.5 coder at high effort.

## Where you work
- Your copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-topics`, branch `wip/pages-topics`, cut from
  4f1992e (the head of `claude/charming-feynman-vm2xia`). Go module in `archiver/`.
- Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in each Bash call.
- Commit as you go, small commits, on your branch only:
  `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. After each commit `git push private wip/pages-topics`.
  Never push anything else, never touch `main`, the main branch, another copy, or `repo-archiver` itself.
- Rules that are not negotiable: invented data only (tests, fixtures, the demo); never open a real
  catalogue, the real library, the old app's folders or `E:\T`; nothing in this piece may send a request
  to Telegram or start the collector; print counts and timings only.
- Tests while working: **only named tests** (`go test ./internal/catalog -run 'Topic' -count=1`, the same
  for `./internal/server`). No whole-package run of `internal/catalog` (3.5 minutes), no race detector,
  no `go vet` over many packages. `gofmt -l` and `go vet` on the two packages once at the end. Do not pin
  the CPU: no `-parallel` above 4, one test command at a time.

## What the owner asked for (FEATURES.md section 12, third round; roadmap D3)
"A topic can be ranked on its own ('Football' first in a Sports chat) and a chat can be set to collect
only chosen topics." The old app had topic ranks in a second card with a search box (12.15) and a topic
filter elsewhere; the owner wants **one place, on the chat's own row**, and better than either.

## What is already known (read it; do not rediscover it)
- The old app (`wt-v12.31/core-service/internal/app/ix_topic_rank.go`, read in full by the session): a
  topic had a "place" on the chats' ranking; per topic it showed files, saved, waiting, held, failed, not
  queued, each message once (`ixTopicCountsSQL`: saved first, then held, then waiting). Port that idea
  of the counts: one statement per topic set, each file in one state. Do **not** port its rescan
  columns: the new app has no rescan and no queue to be missing from.
- 12.17 tried to make a topic's rank cause reading of its group: dropped. **A rank, a choice or a click
  here changes the catalogue only.** Measured 11-07: two of five ranked topics showed "0" with no
  reason. **Every 0 says why in plain words.**
- LESSONS-ix12.30 6b: every per-chat action is one indexed statement (or chunks of one), tested at
  hundreds of thousands of rows; an action on many rows finishes in seconds and never leaves half done
  without a stored intent.
- In the new app today: `topic.rank` (schema 4), `Catalog.SetTopicRank` (`rows.go`), the settle action
  `settleRankTopic` (`settle.go`, `schema6.go`), `bestRankSQL` (best of chat and topic rank). Nothing
  calls `SetTopicRank`. What a chat collects is decided at `attach` (`ladder.go`: `chatWants`,
  `collectsSQL`); a kind not collected is held with `ReasonChatPref`, `probable = 0`, so no lane takes
  it; `wantedAsMain` wants it when a collecting chat carries it. The Chats page: `internal/server/chats.go`
  and `web/assets/js/pages/chats.js`.

## What to build

### 1. Catalogue: schema step 16 (`internal/catalog/schema_topics.go`, new)
- Follow `schema12.go` for how a step is registered (two constants in your file for its number and
  the step it follows, so the integrator can renumber it in one place: 13, 14 and 15 are taken by other
  branches not merged yet; yours sits on 12 as 13 for now, named `topicsSchema` / `topicsAfter`).
- `ALTER TABLE chat ADD COLUMN topics_only INT NOT NULL DEFAULT 0;`
  `ALTER TABLE topic ADD COLUMN chosen INT NOT NULL DEFAULT 0;`
  Added only when missing, as `schemaV9For` does.
- `Chat.TopicsOnly`, `Topic.Chosen` in `rows.go` (`chatCols`, `scanChat`).

### 2. Catalogue: the rule (new file `internal/catalog/topics.go`; keep edits to `ladder.go` to the
few lines needed, because the copies session edits rung 6 in that file)
- A carrier (a message carrying a file) **collects** the file when the chat collects its kind (today's
  `collectsSQL`) **and** (`chat.topics_only = 0` or the message's topic has `chosen = 1`). A message
  with no topic in a `topics_only` chat does not collect.
- At `attach`: `chatWants` gets the topic condition. A file first met only in a topic not chosen is
  **held**, `probable = 0`, with a new fixed reason `ReasonTopicPref = "this chat collects only chosen
  topics"`. Never skipped. The ladder's earlier rungs (known, same post, look-alike) keep their order
  and reasons exactly as with `ReasonChatPref`.
- Owner actions, each stored as a settle intent and applied in chunks like `settleRankTopic` (index
  `message_topic`) and `settleRankSpace` (by `msg_id`); add the kinds to `applyChunk`, change nothing
  else in the settle loop:
  - `SetTopicChosen(ctx, topicID, chosen bool)`
  - `SetChatTopicsOnly(ctx, chatID, on bool)`
  Unlike the kinds, these act on files already catalogued, in both directions. For each file of the
  chunk, with K = "some carrier collects its kind" and T = "that carrier also passes the topic rule":
  - held with `ReasonTopicPref` and now a carrier with K and T exists: back to wanted (or held as a
    probable copy when it has a probable edge: see `wantedAsMain`'s second and third statements and
    `heldReasonSQL`; reuse them, do not write a second version of that logic);
  - a held file with `probable = 0`, not kept held, a ladder reason, and now a carrier with K and T:
    `probable = 1` (as `wantedAsMain`'s third statement);
  - `wanted` (not active, not aside, not claimed) and a carrier with K but without T exists and no
    carrier with K and T: held, `ReasonTopicPref`, `probable = 0`;
  - held with `probable = 1`, not kept held, and no carrier with K and T while one with K without T
    exists: `probable = 0` (it keeps its reason and its evidence).
  A file whose kind no chat collects any more is left as it is (kinds apply "from now on" today; do
  not change that). Active, aside, saved, skipped, gone: untouched.
- `SetTopicRank` stays; in a `topics_only` chat ranking a topic also chooses it (one Batch).
- `ListTopics(ctx, chatID)` and `TopicCoverages(ctx, chatID)`: per topic of one chat, and one more row
  for messages with no topic: files (each Telegram file once per topic), saved (on disk, through any
  chat), held as a probable copy, wanted (wanted, active, aside), not collected (held with
  `ReasonChatPref`, `ReasonTopicPref` or the alternative-version reason), other (skipped, gone,
  untracked). **saved + held + wanted + not collected + other = files**, tested. One statement, driven
  by `message(space_id)` / `message_topic`, for one chat on demand: never for every chat at page load.
- `ChatCoverage` (`stats.go`) gains `NotCollected` (held with those reasons), taken out of `Held`, so
  the chat row's "Held" means probable copies only and the sum still equals `Files`.

### 3. Server (`internal/server`)
- `GET /api/chats/topics?chat=ID`: the chat's topics with the counts above, rank, chosen, the chat's
  `topics_only`, and for each topic a `why` in fixed words when wanted is 0, chosen by the server from
  the counts and settings, for example: "No files listed in this topic yet." / "Everything listed is
  saved." / "Not chosen: this chat collects only chosen topics." / "The rest are held as probable
  copies of saved files." / "This chat does not collect these kinds." Constant strings only.
- `POST /api/chats/topic-rank` `{topic, rank|null, seen}`: 1 to 1,000,000 or null; answers with the
  same `rankEffect` words the chat rank gives (reuse `laneKeys` by the topic's files).
- `POST /api/chats/topics-only` `{id, on}` and `POST /api/chats/topic-chosen` `{topic, chosen}`:
  answer with how many files became wanted, how many became not collected.
- Each follows the existing handlers' guards (`readJSON`, `s.mu`, field errors, the cross-site and
  security tests' expectations: read `guard_test.go` and `crosssite_test.go` before adding routes).
  In demo mode nothing is saved, as the other routes behave.
- `/api/chats` rows gain `topics_only`, `topics` (count of topics, one grouped statement) and
  `not_collected`.

### 4. The page (`web/assets/js/pages/chats.js`, `parts.css`)
- A chat with topics gets a "Topics (n)" button on its own row; it opens the topics **in place, under
  the row** (rows of the same table), loaded on demand, closed again by the same button; keyboard and
  screen-reader usable like the rest of the page (look at how `row()` labels its controls).
- Above the topic rows, one switch: "Collect only chosen topics". Off: every topic is collected and
  the "Collect" boxes are shown ticked and disabled with that reason as their title.
- Per topic: title; a "Collect" box (when the switch is on); rank as a small number input with "Set"
  and "Remove"; the five numbers under the chat's own column heads (Saved, Held, Wanted, Other; "not
  collected" joins Other's tooltip as it does for the chat); the `why` line when wanted is 0.
- One line of plain words: "A topic's rank is on the same scale as the chats': rank 3 downloads with
  the chat ranked 3. A file takes the best rank of the chats and topics it is in. A file posted in two
  topics is counted in both." And the page's footer promise stays true: no click sends a request to
  Telegram.
- After each action: the status line says what changed in numbers; focus returns to the control.
- The page loads nothing from outside (no CDN, no font, no image from the network).
- The summary sentence under the table: "saved + through other chats + held + wanted + other".
  Keep it true with `not_collected` inside "other" and say so in Other's tooltip.

### 5. The invented archive
- `internal/fabricate` already makes forums with six topics. Check that `tgarchive fabricate` then
  `tgarchive app -demo` shows a forum whose row opens to topics with numbers; if the demo's read-only
  mode makes the switches refuse, the refusal must say so in plain words. Write the two commands the
  owner types to open it into your report (paths under the scratch folder
  `C:\Users\trabi\AppData\Local\Temp\claude\71f159c3a9e5d4b9\2859fa9c-25e5-415d-a210-fa8d7d19cca3\scratchpad`).

## Tests (named; all must pass before you hand back)
Catalogue (`-run 'Topic'`):
- the schema step on a fresh file and on a v12 file; idempotent.
- attach: a file first met in a topic not chosen is held with `ReasonTopicPref`; in a chosen topic,
  wanted; with no topic in a `topics_only` chat, held; a look-alike there keeps the look-alike reason
  with `probable = 0`.
- choose, un-choose, switch on, switch off, in every order over a small invented forum: after each,
  every file's state equals what a fresh catalogue fed the same messages under the final settings
  would give (an oracle test, as `chal2_oracle_test.go` does), for files that are wanted or held.
  Active, aside, saved and kept-held files are shown untouched.
- a file carried by a chosen topic and an unchosen one stays wanted; carried also by another chat
  that collects it, stays wanted.
- `c_supply` equals `c_supply_src` after each action (the existing tests have a helper for it).
- counts add up for every topic and for the chat, including the "no topic" row.
- **size:** 200,000 messages with a file each in one forum over 50 topics (build it with direct SQL in
  a Batch, not through `attach`, to keep the test under a minute; skip under `-short`): choosing a
  topic, un-choosing it and switching the chat settle with no chunk holding the writer over 250 ms
  (`settleObserver`), and `TopicCoverages` answers in under 1 s. Print the timings with `t.Logf`.
  `EXPLAIN QUERY PLAN` of each chunk statement and of the coverage statement shows no scan of
  `message`, `attachment` or `c_want` without an index: assert it.
Server (`-run 'Topic'`): the four routes' happy paths and field errors, the demo refusal, a stale
`seen`, the page's JSON shape, and that the routes are covered by the existing guard tests' lists.

## What you must not touch
`internal/viewer`, `internal/bringin`, `internal/engine`, `internal/lookalike`, `internal/exact`,
`internal/supply`, `internal/mirror`, `internal/telegram`, `internal/collector`, `lane.go`, `state.go`,
`exactcheck.go`, the hold tables, `archiver/docs`. In `ladder.go` only `chatWants`, `collectsSQL` and
their call sites. If the work seems to need anything else, stop and say so in your report instead.

## Hand back
Commit-ready and pushed. Your last message: the commits (hashes), what each route and function does in
one line, the named tests and their timings, the size test's numbers, `gofmt`/`vet` result, whether any
code that runs concurrently changed (a new settle kind inside the unchanged settle loop is "no new
goroutine"; say exactly what you touched), anything you could not do or are unsure of, and the two
commands that open the page on invented data. No claim without a number or a test name behind it.
