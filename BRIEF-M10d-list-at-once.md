# Brief M10d (FINAL, 11-16, the mirror session M5): F6 is reversed: one chat list at once at the page's "on"

**For the coder of M10, same copy, branch, round and house rules as `BRIEF-M10b-fixes.md` and
`BRIEF-M10c-list-every.md`. This replaces F6 of M10b (and the last sentence of point 3 of M10c).**

## The owner, 11-16 (asked: "Should switching it on also ask Telegram for one chat list right away, with that cost said beside the switch?")
"Yes"

## What to build, in place of F6
- **A page's "on" that was written (not the "already on" case) makes ONE chat list due at once for that
  account**, so that the baseline, and with it "chats joined from now on", holds within seconds. The cost is
  said beside the switch by the page (pages' words; the door's comment says it too).
- **Exactly one, whatever happens next (this is the part to get right):** it is a one-shot mark, set by the
  door's written "on" (an atomic on the account or its session, since an HTTP goroutine sets it and the
  reader's reads it), used by `chatListEvery()` to make the list due at the reader's next turn once the
  account is set up, and cleared as soon as that list was asked: a list that fails, is cut off, meets a
  wait, or is stored before the clock has passed "since" (F2: then no baseline is written) does NOT make
  another list due before the usual interval. Never a state rule such as "no baseline in force: ask again":
  that would ask a chat list every reader turn in the cases above. Read how `reader.go` (about 505 to 560)
  decides and records a list to find where "asked" can be told from `mirror_auto.go` alone (`autoListed` is
  told only of a list stored whole; `topicsDue` is called on the way: say what you used). If it cannot be
  told without a line in `reader.go`, STOP this fix, leave the behaviour of ea105e9b (the list comes when
  the last one is older than the interval), and say exactly which line Core would have to lend.
- **Not caused by anything else:** an "off", an "on" that wrote nothing, a set-up at the start, a set-up
  made by the task for an account that signed in later or after a failed set-up, the run's flag: none of
  these sets the mark (a start and a first sign-in ask their list as they always did). A mark set while
  the account has no session, or whose set-up fails, waits; it does not survive the end of the program.
- **Tests (named), in place of F6's:** on the reviewer's rig (`ChatListEvery` 24 h; the last list one minute
  old, and again older than the interval): the click brings exactly one chat list (count the fake's
  chat-list requests against one list's worth before and after) and the baseline line, and no second list
  before one interval of the setting has passed; a second "on": none; an "off": none; the fake failing that
  list: no further list before the interval; the clock set back below "since": one list, no baseline, no
  further list before the interval.

## Hand-back
In the report's section "M10b" under F6: what you built and what tells "asked". Named in your final message.
