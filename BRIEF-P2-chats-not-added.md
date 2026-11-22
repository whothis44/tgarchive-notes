# Brief P2: chats not added yet, in the same list; why a number is 0

Written by session P (pages and chats), 2026-11-15 08:48. For an Opus 5.5 coder at high effort.
**Starts on the head of `wip/pages-topics` after piece P1 is handed back** (it edits the same files:
`internal/server/chats.go`, `web/assets/js/pages/chats.js`, `internal/catalog/stats.go`). Branch
`wip/pages-notadded`, cut from that head, in the same copy `wt-pages-topics` or a new `wt-pages-notadded`
(the session says which). Working rules, commits, pushes, privacy, tests: exactly as `BRIEF-P1-topics.md`
"Where you work" and "What you must not touch". No schema step is expected; if you need one, stop and say so.

## What the owner asked for (FEATURES.md section 2 and 11; roadmap D3; TRIED-BEFORE 15)
"Chats not selected yet belong in the same view, with their size and an estimate of overlap with what is
saved." The owner called this a critical weak point. And: every number says what it counts; every 0 says
why in plain words.

## What is already known
- The old app listed chats not added with a media count fetched on a click ("Count media", cost shown
  first). Its estimate from those counts was **wrong by a factor of 4 or more** (56 channels: "about
  0.5 TB" from counts; reading 6 of them took the known unique files from 319 GB to about 2 TB;
  TRIED-BEFORE 26). So: **a count is never shown as a size, and nothing here multiplies a count by an
  average.** A chat's size and its copies come from its read messages.
- 12.30 added 30 chats by itself and they flooded the queue (1,571 of 1,575 startable files): the owner
  switched 24 off by hand. **Propose, never queue: this page starts no download and no read.**
- In the new app a chat is in the catalogue as soon as the account's chat list is read
  (`account_chat`). It is "added" once a read is approved or under way: an approval in the settings
  (`collector.read.<account>.<chat>`, JSON `estimate_requests`, `estimate_messages`, `estimated_at`,
  `approved_at`: see `internal/collector/reader.go` `ReadApproval`; read it through
  `Catalog.GetSetting`, do not import `internal/collector`) or a cursor (`account_chat.cur_at`,
  `cur_done`, `cur_total`, `cur_pages`). "Not added yet" = no approval and no cursor for any account.
- What is stored about a chat never read, at no request: kind, members, `account_chat.top_msg` (the
  newest message's number: for a channel, supergroup or forum an upper bound on its messages; for a
  person or basic group it is the account's own numbering and says nothing: show it only for shared
  kinds), `top_date`, access, a stored estimate when one was asked, `chat.mirror_of`,
  `chat.fwd_restricted`.
- The one overlap fact available without reading: **files already in the archive that were forwarded
  from that chat.** `message.fwd_origin` is `"<marked chat id>:<post>"` when it names a post
  (`namesPost` in `ladder.go`), indexed by `message_fwd_origin`. For a shared chat with Telegram id X:
  the messages whose origin lies in the range of that prefix, their attachments, each file once:
  how many, and how many of them are saved. One range seek per chat. Bare origins (no post number)
  are not counted (they name a sender, not a post).

## What to build
1. `/api/chats` rows gain, per chat: `read` (fixed words: `never`, `estimated`, `approved`, `under way`,
   `done`, `refused`, the best over its accounts), `read_messages` and `read_total` when under way,
   `top_msg` (shared kinds only), `members`, `estimate` (`requests`, `messages`, `at`) when stored,
   `mirror_of`, `from_here` (`files`, `saved`: the forwards fact above), and `why`: one fixed sentence
   when wanted is 0, chosen by the server:
   - never read: "Not read yet: its files are not known."
   - read under way: "Being read: N of about M messages so far."
   - every file saved (here or through other chats): "Everything listed is saved."
   - the rest held: "The rest are held as probable copies of saved files."
   - switched off or kinds off: "This chat does not collect these kinds." / "Switched off."
   - only chosen topics and none chosen (P1): "It collects only chosen topics and none is chosen."
   - no account can reach it: "No account can reach it now (left, banned or gone)."
   - no media: "Read to its end: it has no files."
   All in two statements for the whole list at most (one for the read facts, one batch for
   `from_here` limited to chats not read to their end), no statement per chat in a loop that walks
   messages.
2. The page: the same table. A filter "Read: all / not added yet (n) / being read / read"; the row of a
   chat not added shows, where the numbers would be, one cell spanning them: "Not read yet" and under
   it what is known, in this order and only what is stored: "newest message number N (at most N
   messages)", "a read was estimated at about R requests (date)", "F files already in the archive were
   forwarded from it, S of them saved". Never a size in bytes, never "about N files".
   Sort "most already in the archive" (by `from_here.files`).
   How to add it, in plain words under the table, since this page sends nothing to Telegram: the
   command `tgarchive-collector run -approve-read <chat number>` shows the read's cost and asks. Show
   the chat's number in the row's title for that. No button that approves a read (that is a later
   piece, decided with the integrator: the approval is the collector's record).
   A chat that is one of the app's own mirrors (`mirror_of`) is labelled "the app's mirror of <title>"
   and is never counted as "not added yet".
3. The age of the data: the page says when it was loaded ("as of HH:MM:SS") and has a Reload button.
4. **Size.** `ChatCoverages(ctx, 0)` walks every message and attachment at each load. Measure it in a
   named test on an invented catalogue of 300,000 messages with a file each over 400 chats (direct SQL
   in a Batch; skip under `-short`) and print the time. If it is over 1 s: keep the result in the
   server, worked out again only when the catalogue changed (`PRAGMA data_version` on the read
   connection, or the change log's last id; say which and why) and never more often than every 5 s,
   with its age in the JSON so the page can show it. Do not rewrite the coverage query itself unless
   the plan shows a scan without an index; report the plan.

## Tests (named, `-run 'NotAdded|ChatWhy|CoverageSize'`)
- each `why` sentence from an invented chat in that state; a chat never read has no numbers and its
  `why`; a mirror is not "not added".
- `from_here`: forwards that name a post are counted once per file, bare origins are not, a chat id
  that is a prefix of another (12 and 123) does not catch the other's forwards.
- the plans of both statements show index use; the size test's timing with `t.Logf`.
- the page's JSON shape; the guard tests still pass for the unchanged routes.

## Hand back
As P1: commits pushed, one line per function and field, tests with timings, the coverage timing and
plan, gofmt and vet, what you could not do, and the commands that open the page on invented data
(`tgarchive fabricate` must produce at least three chats never read: add them there if it does not,
which is `internal/fabricate`, a test-data package you may edit for this).
