# Brief K1: files are downloaded only from chats the owner chose (core, lent to the integrator's session; 2026-11-15)

For one Opus coder, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-core-chosen` on branch
`wip/core-chosen` (made for you; change no branch). **It is cut from the mirror track's unmerged branch
`wip/mirror-auto` (c599ac5), on purpose:** that branch already has the mechanism this piece needs (a policy
"a chat first made starts switched off", the table `c_chat_made`, `ownerChose`, who approved a read). The
mirror session is still finishing that branch: **never commit to, push or touch `wip/mirror-auto` or the copy
`wt-mirror-auto`**; your branch is merged after theirs. Go module in `archiver/`. Commit work in progress as
you go (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, messages starting `WIP core: `,
ending with a blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`) and push with
`git push private wip/core-chosen`; never `origin`, never the main branch, never a force-push.

## The owner's rule, and what the app does today
- The owner, 11-14: "a newly joined chat is mirrored automatically (no bytes); its files are downloaded only
  when the owner chooses the chat." 11-15, for a chat joined while away: downloads "an option we can enable.
  Perhaps off by default". The lessons' rule for every source: find, count, read and propose; **download only
  what the owner chose**.
- What the old app learnt (TRIED-BEFORE sections 24 to 26, `archiver/docs`; read them): its 12.30 added 30
  channels by itself and the queue of unique files went from about 319 GB to about 2 TB, nearly all on the
  server that was already the limit; the owner sent them to the trash. Its ten rules for anything that acts
  for the owner apply here: never undo a person's choice; a durable record of everything put in scope, one
  row per item; fail closed when a stored value cannot be read; no request for an item that will never be
  acted on.
- **Today (found by the mirror session, board message 14, checked by reading):** a chat row is made
  collecting every kind (`internal/catalog/rows.go`, the one place a chat row is made); `SaveMessages` makes a
  row for an unknown chat; `attach` (`ladder.go`) asks only `chatWants`. So with `run`, a live message in
  **any** chat the account is in gets its files wanted and downloaded, approved or not. The mirror branch
  closes this only for chats joined after the automatic mirror was switched on, and only for groups and
  channels; run without `-auto-mirror` it removes its policy again.
- **Also today:** switching a chat on or off (`SetChatCollect`, `SetChatWants`, `imported.go`) "applies to
  files catalogued from now on". So a chat read while switched off, then chosen by the owner, downloads
  nothing of what was read. The topics already have what is needed (`topics.go`: an intent on record, then
  `settleTopics` in chunks, both ways).

## What to build

### 1. A chat the collector first meets starts switched off, whatever its kind and whatever the mirror's switch
- One catalogue setting, set by `run` at its start before any account's task starts and read in the one
  place a chat row is made: every chat row made from then on starts switched off for downloads and is
  recorded in `c_chat_made` (extend what the mirror branch built; do not add a second mechanism beside it,
  and keep its per-account policy working underneath for its own case). Every kind, the first chat list of a
  new account included: at sign-in the owner has chosen nothing.
- Not touched: a row the bring-in makes (it sets the old app's own choice), a mirror's own chat (already made
  switched off), a chat row that exists.
- `run -new-chats-download` (default off) is the owner's open choice to make new chat rows collecting, as
  before; `-auto-mirror-download` keeps its meaning for the mirror's case. Say in `run -h`, in plain words,
  what a new chat does by default and how a chat is chosen.
- A setting that cannot be read makes rows switched off (fail closed) and is counted, as the mirror branch
  does for its policy.

### 2. Choosing a chat acts on its files already listed, both ways
- `SetChatCollect` (and `SetChatWants`, the kinds) settle the files already catalogued, as `settleTopics` does
  for topics: switched on, a file held only because its chat did not collect it (`ReasonChatPref`) becomes
  wanted, or a probable copy where the ladder found it like a saved file (`wantedAsMainIn`: reuse it;
  `c_want.released`, `check_first` and the look-alike rule keep their meaning); switched off, a wanted file
  that no other chat carrying it collects is held with that reason. Never a file that is in transfer, saved,
  linked, set aside by the owner's hand, or released by the owner. In chunks, with an intent on record first,
  so a stop in the middle is finished at the next open and the writer is never held for seconds (the topics'
  machinery; measure a chat of 50,000 files on invented data and say the longest write).
- The owner's approval of a read (`ApproveRead`, the `-approve-read` path, `ownerChose`) switches the chat on
  through this, for every chat that is switched off because nobody chose it (made off under the setting, or
  switched off at the baseline below), and for no other reason: a chat the owner switched off by hand stays
  off (tell the two apart by the records; say how).
- The Chats page already calls `SetChatWants` (`internal/server/chats.go`): it must keep working unchanged
  from the page's side; its answer may carry the effect's counts as the topics' does, nothing else there.

### 3. Chats that exist already and nobody chose: a baseline, once
- At the first `run` with the setting, once per catalogue and recorded as done: every chat that collects, has
  no approval by the owner from any account (an approval by the mirror does not count), and is not a mirror's
  own chat, is switched off, **one settings row per chat** saying when (so each is listed and can be told
  from a chat the owner switched off), and its files settle as in section 2. Counted: chats switched off,
  files held by it.
- **A catalogue the bring-in ever wrote (any `bringin.v1.` setting) is not baselined at all**: the old app's
  choices stand there. Say so in one line with the count of chats left as they are.
- It runs before any account's task starts, in chunks, and never twice: a chat the owner switches on later is
  never switched off by it again.
- `chats` (the command) shows for each chat whether it collects, and why not when not (never chosen: made
  switched off; switched off at the baseline; switched off by the owner), and one line with the totals.

### 4. Read-only commands on a catalogue older than the build (board message 18)
`chats`, `status` and any other command that opens the catalogue read-only say, in fixed words, "the
catalogue is at schema N, this build reads M: start `run` once (it steps the catalogue and sends nothing by
itself), or use the build that wrote it" and end with their refused exit code, instead of an SQL error. If the
mirror branch already has such a check for its commands, use that one for all of them.

## Tests (named; invented data; the collector's fake Telegram; fake clocks, no real time judged)
- `TestNewChatStartsOff` (each kind; from the monitor's sink, the chat list and the reader; recorded in
  `c_chat_made`; a live message in it catalogues its media and wants nothing, no supply row),
  `TestNewChatsDownloadFlag`, `TestBringInRowsUntouched`, `TestMirrorChatUntouched`,
  `TestSettingUnreadableFailsClosed`.
- `TestChooseChatSettlesFiles` (on: held for the chat's sake becomes wanted; a look-alike becomes a probable
  copy; a released file stays released; off: wanted becomes held unless another collecting chat carries it;
  in transfer, saved, set aside by hand: untouched), `TestChatSettleResumesAfterStop`,
  `TestChatSettleAtSize` (rows touched per chunk bounded; judged by counts, not seconds),
  `TestApproveReadSwitchesOn`, `TestOwnerOffStaysOff`.
- `TestBaselineOnce` (switched off with a row each; files held; a second run does nothing; a chat switched on
  after it stays on), `TestBaselineLeavesApproved`, `TestBaselineLeavesBroughtIn`,
  `TestBaselineMirrorApprovalDoesNotCount`.
- `TestE2ELiveMessageInUnchosenChat` (the collector's rig: a live message with media in a chat nobody chose:
  0 part requests, 0 files wanted; after `-approve-read` of that chat: its files are wanted and downloaded).
- `TestReadOnlyOlderCatalogueWords` (each read-only command; the file's hash unchanged).
- The mirror branch's own tests that touch the policy, the approval and `ownerChose` pass; list every existing
  test whose expectation you had to change and why (a test that relied on a new chat collecting must now
  choose the chat or pass the flag: say which you did for each).
- Mutations, each shown failing a named test, then undone: a new row made collecting; the bring-in's row
  switched off; the settle wanting a released file; the settle touching a file in transfer; the baseline
  running twice; the baseline run on a brought-in catalogue; a mirror's approval counted as the owner's; the
  owner's "off" undone by an approval.

## Rules (hard)
- Touch only what this needs in: `archiver/internal/catalog` (the chat-making place, the setting, the chat
  settle beside the topics', the baseline, counts), `archiver/internal/collector` (the start of `run`, its
  flags and help, `ApproveRead`/`ownerChose`, the `chats` and `status` commands, the read-only check),
  `archiver/internal/server/chats.go` only if the page's call needs a line, tests, and
  `archiver/docs/progress/`. Not the engine, the supply's claim path, the reader's requests, the mirror's
  run, the store, the viewer. **No schema step** (settings rows and the tables that exist); if you find one is
  needed, stop and say so in the report.
- No request to Telegram is added, moved or removed. Nothing here downloads, forwards or deletes; a file held
  here keeps its row and comes back when its chat is chosen. Only exact evidence ends a file without bytes.
- No goroutine, timer or lock is added: the baseline and a settle run in the caller's turn, in chunks.
- New log, error and count text is constant words with numbers: never a chat's name, id or text.
- Load: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`,
  `GOMAXPROCS=2 go test -p 1 -run '<names>' ./internal/<package>`: named tests only while working. No
  whole-package run of the catalogue or the collector (minutes each), no race detector, no Docker: the full
  runs are the main session's, once, after the review. Other agents are compiling on this PC: one go command
  at a time. Never touch `E:\T\tg-dl`, the folder `a3`, or any real catalogue, media or account.
- Keep `archiver/docs/progress/core-chosen-PROGRESS.md` current and commit it with each step; at the end
  `archiver/docs/progress/core-chosen-REPORT.md`: what a new chat, a chosen chat and an existing unchosen chat
  do now, each with its test and mutation; how "nobody chose it" and "the owner switched it off" are told
  apart; the settle's cost; every existing test changed and why; what was NOT verified (it has not run on the
  test account); anything in this brief you found wrong or contradictory (say so rather than build around
  it); the changed files; a drafted final commit message. Hand back commit-ready: everything committed and
  pushed, the tree clean, gofmt clean.
