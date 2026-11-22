# Brief K26: forum topics without titles (Core, K-6, 2026-11-22)

**Why:** the owner's catalogue (counts read-only, 11-22) has 35 topic rows, 25 with an empty title, so the mirror
named its forum topics "Topic N". By chat: one forum whose read the OWNER approved has all 10 titled, each with its
top message and date (its topic list was stored). One forum whose read the AUTOMATIC MIRROR approved has 22 topics,
all untitled, none with a top message or date: **its topic list was never stored.** One forum with no read record
has one untitled topic, known only from a message. The app's own forum mirror has two untitled topics; the reader
skips it on purpose.

**Rules:** you are the one Opus coder. Named tests and small packages only; never the whole `internal/collector` or
`internal/catalog`; every go command through `bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go2.sh <folder> ...`.
Invented data only; nothing against Telegram (the fake only); never touch a running program, the main copy,
`C:\Users\trabi\tgarchive-app` or `E:\`. Copy `wt-core-topics`, branch `wip/core-topics` from
`private/claude/charming-feynman-vm2xia` (e34f4f64 or later); commit form as always; push only your branch. The
mirror's files are not yours (M-7): read them, never edit them.

## What to do
1. **Find why a forum whose read the automatic mirror approved never gets its topic list stored.** The pass is
   `internal/collector/reader.go` around line 576: `topicsDue`, then per chat
   `ch.ref.Forum && ch.approved && !ch.selfHeld && !s.skipEnded(...) && !c.isOwnMirror(...)`, then
   `r.ListTopics` and `store.SaveTopics`. Build that state on the fake: a forum chat in the chat list, its read
   approved with the mirror's `By` word, the automatic mirror on. Find which condition or step drops it. Candidates:
   `ref.Forum` false on a chat whose kind is forum (how the ref is built in `readChats`); `topicsDue` with the
   automatic mirror on; the catch-all of the error switch, which drops any other error with no line and no count;
   `SaveTopics` storing under another chat; a page limit (more than one page of topics). Write down the cause
   with the test that shows it failing first.
2. **Fix it** so every forum whose read is approved, by the owner or by the mirror, gets its topic list stored at
   the next due pass. Paging: all topics, at the request loop's pace, every wait slept in full.
3. **No silent failures:** every topic-list error the pass meets is counted per kind and logged once per chat and
   session (constant format, numbers only).
4. **Titles for topics known only from messages, cheaply:** in an approved forum, a topic row with an empty title
   is filled by the pass (the list holds it). Ask for no topic list of a forum whose read is not approved (the
   owner's rule: no read without approval); say what that forum's topic shows meanwhile.
5. **A door for the mirror** (M-7 asked to read topics itself; one read, not two): `(*Collector).TopicTitle(ctx,
   chat, tgTopicID) (title string, known bool, err error)` on the catalogue, plus a way for the mirror to make the
   next pass due for one forum now (e.g. `(*Collector).TopicsDueNow(account, chat)`, a flag the pass reads; no
   request of its own). Tell me the exact names in the hand-back.

**Cost:** one topic-list request per approved forum per due pass, as today (one page each; more pages only for
forums with more topics than a page). Measure it on the fake: requests per pass for 1, 3 and 30 forums.

## Hand back
`archiver/docs/progress/core-topics-REPORT.md` and your last message, short: head pushed; the cause, with its
failing-first test; the fix; the doors for the mirror; the counted costs; the tests as run.
