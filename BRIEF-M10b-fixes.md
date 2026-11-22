# Brief M10b (FINAL, 11-16, the mirror session M5): M10's fix round

**You are the coder of M10, continued. Same copy (`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-autonew`,
branch `wip/mirror-autonew`, head ea105e9b), same house rules and limits as `BRIEF-M10-auto-switch.md`**, with
these files added to what you may edit: `internal/collector/words.go` (one line: the two new sentinels) and the
one sentence of `command.go`'s help named in F9. Each fix its own commit, each with a named test that fails
without it (say in the report which line you took out to see it fail). Do not merge the main head.

**The independent review is `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review13-scratch\REVIEW.md`: read
it in full first** (read-only; its probes `zz_m10probe_test.go` and plants are beside it: you may copy a probe's
idea into a test of your own, never the reviewer's folder into the tree). Its verdict: may be listed after
these fixes. Its finding 1 is HIGH and was missed by you and by my own read.

## The fixes, most severe first
- **F1 (review 1, HIGH, confirmed). The look reads the baseline raw.** In `autoTurn` the look takes its
  baseline with `readUnix(ctx, cat, keyAutoBaseline(a.id))` (about line 909), not through `autoBaseline`: so a
  page's "on" takes chats joined while the switch was off or unreadable. Read it through `autoBaseline`, and
  then search the whole package for any other raw read of `keyAutoBaseline` (none may stay but
  `autoBaseline`'s own and the writer's). **Tests, each of which must fail on ea105e9b:** on, then the row
  made unreadable, a chat joined, on from the page: never taken; on, off, a chat joined, on, under
  `-auto-mirror-download`: never taken; off and on again before the task's next turn (two door calls with no
  turn between), a chat joined between them: never taken; a restart of the collector between the off and
  the on: never taken; in each, a chat joined after the new baseline is taken (the positive control). And
  `MirrorTask.AutoNewFrom` is zero exactly while the look takes nothing.
- **F2 (review 7, my read). "Since" can never leave the old baseline in force.** In the door's transaction
  "since" becomes the later of now and (the baseline row's value + 1) when that row reads; a baseline row
  that cannot be read: "since" is now (check that every reader of the baseline then fails closed, and say).
  `autoListed` writes no baseline until the clock has passed "since" (it has that check: keep it). Test: a
  clock set back below the old baseline before the "on": the chat joined while off is never taken.
- **F3 (my read; review's departure 5). Under the run's flag an "off" is not undone backwards either.** In
  `autoSetUp`, when the run has the flag: if the stored switch reads "off" with a time not before "since",
  or cannot be read, "since" is moved exactly as F2 moves it, in one transaction with the read (once: after
  the move a stored "off" is older than "since" and moves nothing at the next start; a row that cannot be
  read moves it at every flag start until it is written anew: said in the line), and a constant line says
  that chats joined before this start are not taken because the switch was off, or not readable, on
  record. A stored "on", or no row: nothing moves (chats joined between two runs are taken, as before). The
  stored row itself is never written by a flag run. Also make `autoSince`'s read-then-write one transaction.
- **F4 (review 2, MEDIUM, confirmed: 190 history requests in two minutes of the clock). An allow while the
  switch is off must not let a held chat be read.** In `accountDeps`: while the account is not set up
  (`AutoWantsHeld`), `ResumeRead`, and `Approve` where it only clears an end on a record already there, do
  nothing for a chat whose live want is not the owner's; the set-up clears the end when the switch is on
  again (`autoReads` does). An owner's want is never affected; a new want of the owner's still approves and
  clears as today. Tests: the reviewer's case (an allow with nothing to undo, the switch off: the reader's
  history requests for that chat do not grow over two minutes of the clock); the switch on afterwards: read
  on from its cursor.
- **F5 (review 6, first half). Held chats are not read on while the set-up fails.** The switch on but the
  set-up failing (no secret, "since" not stored, the baseline unreadable), in `autoLook` and at the start: the
  reads of the automatic wants are ended as for "off" (once, recorded when it went through; the policy for
  new chats left as it is); a later set-up clears them (it does already). The account's own refusal
  (`st.off`) is left as it is today: say it under "known" in the report.
- **F6 (review 3, MEDIUM, confirmed: a chat list 0.33 s after the click). No chat list because of a click.**
  `chatListEvery` goes to the 30-minute interval the moment the account is set up, and the reader counts
  from the last list, which with the switch off is usually older than 30 minutes. When the set-up is made
  by the task (`autoLook`), the 30-minute interval applies only from that set-up plus `AutoListEvery` on
  (a time kept on the session or the account; atomic if another goroutine reads it); until then the run's
  own interval. A set-up at the start keeps today's behaviour (a start asks its chat list as it always
  did). Test: the reviewer's rig (`ChatListEvery` 24 h, the last list older than 30 minutes): the fake's
  chat-list requests do not grow in the 29 minutes of the clock after the click, and one list comes after
  30. (The owner is asked whether the list should rather come at once with its cost on the switch: if the
  answer is yes this fix is two lines to take out; build it so.)
- **F7 (review 4). A test that sees the order.** Taking `on := a.autoOn()` before `autoLook` survived every
  test. Add one that counts the fake's creates and forwards and the wants taken from the moment the task's
  turn has read "off" (use the turn's injected point, `mirror turn N`, or the applied line): exactly 0
  after it, not "at most one".
- **F8 (my read; review 5). Small.** (a) `SetMirrorAutoNew(..., false)` is accepted for an account that is
  not signed in on record, and when the sign-in record cannot be read: only "on" needs it; the run's flag
  still refuses both. (b) `autoLook` ends the reader's turn only when a read record was really written.
  (c) A switch unreadable at the start is said once, not twice (the start's line counts as said for the
  account's first session). (d) No test covers the start's A6 (a restart with held wants while the switch
  is off: no history request for them; with it on: read on): add it. (e) `TestMirrorAutoNewSignInLater`
  seeds an "on" row without "since", which no real path writes: seed what the door writes.
- **F9. Words.** The comment on `chatStateOf` in `mirror/door.go`; the sentence of `command.go`'s help that
  says the policy is removed in a run without `-auto-mirror` (now: when the switch is off);
  `ErrAutoNewByRun` and `mirror.ErrBadAutoNew` in `words.go`'s sentinels.

Not yours (the mirror session tells the tracks): the page's facts mapped from `AutoJoined` and the door's
refusal missing from pages' `doorRefusals` (review 8); the reader's skip line (Core's).

## Hand-back
A new section "M10b" in the report on the branch: per fix what changed (file, function), its tests by name
and the line you took out to see each fail; the commands and their "ok" lines with seconds; test functions
removed or renamed (expected: none; `git diff dbca91d4 -- . | grep '^-func Test'`); anything of this brief
you did not do, and why. The named runs once at the end: the collector's `-run '^TestMirror(Auto|Door)'`,
whole `./internal/mirror/`, gofmt and vet on the two packages (the PC measured before each; one at a time).
Then your last message: the head's short hash, pushed or not, the counts, every departure.
