# Brief B3-4: the owner's marks survive a fresh bring-in (session B3, 11-15)

You are an Opus coder. Copy and branch: given in the prompt that started you. Go module: `archiver/`. Go:
`source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in each Bash call. Package:
`archiver/internal/viewer` only. No schema step in the catalogue (the viewer opens it read-only).

## The problem
`decisions.sqlite` (the viewer's own file, beside the catalogue in its `viewer` folder) keeps the owner's
marks in `hidden(kind, id, at)`: a hidden post by its lead `message.id`, a hidden chat by `chat.id`. Both are
the catalogue's own row numbers. The old archive is brought in afresh from time to time (the old app writes
until 11-29), into a new catalogue whose row numbers are new. The marks would then point at other posts and
chats. The owner has been told not to mark until this is fixed. Old app's lesson (TRIED-BEFORE 8 and the
12.22 viewer): a decision the owner made is remembered for good and never lost by a rebuild.

## The design (decided by the main session)
- **Stable keys.** A space is `(shared, tg_chat_id, the owning account's tg_user_id or 0)`
  (`catalog.go`: `space`, `account.tg_user_id`). A chat's stable key is its space's. A post's stable key is
  its space's key plus Telegram's message number of its lead message (`message.msg_id`; `postRec.leadNo`).
  The index reads accounts as `id, label` today: add `tg_user_id`; `chatRec` already has `tgChatID`,
  `shared`, `owner`.
- **A new table** in `decisions.sqlite`: `mark(kind TEXT CHECK (kind IN ('post','chat')), shared INT,
  tg_chat INT, tg_user INT, msg_no INT (0 for a chat), at INT, PRIMARY KEY(kind, shared, tg_chat, tg_user,
  msg_no)) WITHOUT ROWID`. All new hides and unhides write it.
- **One translation of the old rows.** When `hidden` has rows and a pref `marks_keyed` is not set: after the
  first index is built, each old row is looked up in that index (`msgByID` / `chatByID`), written to `mark`
  by its stable key, and the pref is set, in one transaction; `hidden` is left as it is (never deleted) and
  not read again. A row whose id the index does not know is counted and kept in `hidden` (the log line says
  how many, counts only). The translation must happen on the catalogue the marks were made on: it is the
  first thing after the first index, before anything can hide or unhide.
- **Resolution.** In memory the marks are kept by stable key. For each index version the hidden sets by
  current row id (`hiddenSets`, `isHidden`, `hiddenCounts`) are worked out once and kept with the decisions'
  version (`ver`) so listings' cache keys still change on a hide: chats by a map from stable key (built
  once per index version from `ix.chats`, 224 entries), posts by the chat and then the lead number. Cost per
  index version: proportional to the number of marks, not to the archive (find a post by `(chat, msg no)`
  with what the index has; if nothing fits, a binary search over the chat's messages by number is fine;
  do not build an archive-sized map).
  A mark whose post or chat is not in the current catalogue stays in the file, is counted
  (`/api/about`: "marks kept for items not in this archive: N") and comes back when the item does.
- **A rule for later marks**, written as a comment at the top of `decisions.go`: nothing in this file may be
  keyed by a catalogue row number; posts and chats by the keys above, files by Telegram file identity or
  SHA-256.
- The HTTP API stays as it is for the page (it sends row ids of the current index; the server translates).

## Tests (named, while working)
On invented catalogues (the package's helpers): hide a post and a chat; build a second catalogue with the
same messages inserted in another order (other row ids); open the same `decisions.sqlite` on it: the same
post and chat are hidden, the listing leaves them out, the counts agree. An old-style `hidden` row is
translated once and not twice. A mark for an item the second catalogue lacks is kept and counted. Then once
at the end: `go test ./internal/viewer -p 1` (about 3 minutes, in the background), `gofmt -l`,
`go vet ./internal/viewer`. No race detector, no mutation checks, one go command at a time.

## Rules
- Never open the viewer on real data or any real file; never open the owner's real `decisions.sqlite`;
  nothing against Telegram; do not touch `repo-archiver`, other `wt-*` folders or other packages.
- Do not merge into or push `claude/charming-feynman-vm2xia`. Commit as you go
  (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; no archive numbers) and push your branch to
  `private`.
- Say in the hand-back exactly what runs concurrently (the translation after the first index; anything in
  the update loop).

## Hand back (short)
Commits, differences from this brief and why, tests and result, doubts.
