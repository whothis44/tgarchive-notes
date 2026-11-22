# Brief M9e (11-16 01:25, the mirror session M4): the second pass's low findings; then the piece is listed

The reviewer's second pass on 21153789 says "may be listed": all eight first findings fixed; five new ones,
all low (`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review11-scratch\REVIEW.md`, "Second pass"; its
probes in the `pass2` folder there, read-only for you). Same copy (`wt-mirror-door`, now at 75af73a5), same
branch, same house rules. Decided:

1. **N2 (confirmed): after the owner's `mirror -settle ... -take`, the owner is told the wrong next step.** The
   batch is settled but the want stays blocked, the command says "the mirror goes on" and "run mirror
   again", and the next run ends "blocked ... mirror -allow lifts it" with 0 forwards (new since the intent's
   check). **Fix: the owner's settle lifts the block it answers.** In the transaction in which the command's
   settle settles the batch (or ends a create as not made), a block of that chat's want is cleared when, and
   only when, its word is one of the settle's own (the words `BlockOffers` maps to a word: cannot tell,
   repeat, contradiction, again, day, and the lost create): the owner has looked, which is what those blocks
   wait for. Every other block word (a refused create or batch, an unsent batch, the mirror chat refusing
   the read, two channels) stays and still needs the allow. One function decides "this block is the
   settle's" and the door, the task and the command use it. The command's words after a settle then say
   what is true in each case (the mirror goes on; or: blocked for another reason, with the allow). Tests:
   the reviewer's `TestZZ2CommandAfterSettle` as yours (settle, then the next step forwards); a want blocked
   by a refused create is not lifted by a settle of something else; a command-made mirror with no want as
   before.
2. **N3 (confirmed): a mirror stopped from a page says the wrong way back.** The plan's and the command's
   words for an end of "stopped by the owner" say what is true: stopped by the owner from a page; "Mirror this
   chat" on the Chats page starts it again; `mirror -allow` does not. (`WhyEndedForGood`'s sentence stays for
   every other end.) The command's `-allow` on such a chat says in fixed words that the stop is kept. Tests
   from `TestZZ2CommandStopAllow`.
3. **N4 (by reading): a catalogue read error is taken for "not signed in" and ends the mirror task for the
   session.** In `mirror_door.go`, the sign-in read used by the doors and by the top of the turn returns
   (bool, error): an error is "the record cannot be read" (the doors say so; the turn fails as its other
   failed reads do and tries again), never "not signed in". Core's `isSignedIn` in `account.go` is not
   edited: read the same record through a function of your own beside the doors and pin with one test that
   both give the same answer in each readable case.
4. **N5 (confirmed, older than this piece): an unreadable end word on the mirror row does not stop the
   task.** `intentHeld` (or the read of the open mirror row that precedes it) reads `c_mirror.end_why` of the
   row the intent is for: a word that cannot be read is `ErrBadLedger` (nothing begun, nothing sent); a row
   ended for good holds the intent as an ended want does. Test from `TestZZ2Unreadable`: 0 forwards.
5. **The concurrent test also writes:** `TestMirrorDoorRunReadWhileForwarding` (or a second test whose name
   also begins `TestMirrorDoorRun`) calls doors that write (never, allow, a stop and a new want on another
   chat) from another goroutine while a history is forwarded, so that the nudge flag is crossed under the
   race detector. No new assertion on timing beyond "no request for the stopped chat after its stop
   returned and the turn in flight ended".
6. **A comment:** the schema step's comment says it follows "(21)" where the step itself is 22 on this tree:
   put it right, without a number a later merge could make false ("the step after the newest on the head").
7. **N1 is not changed in code, on purpose:** the boundary is the intent row; after it a request already
   begun is not recalled, and the forwarder may sleep a wait Telegram stated meanwhile before it leaves (at
   most the task's 60 s). Add that sentence to the comment of `Stop` and `Never` in `door.go` and to the
   report's list "what a click sends"; the page's words are the pages track's.

Named tests only, PC measured before each go command; then by name: the tests you added or changed, the
mirror's and the collector's tests whose names hold `Door`, `Want`, `Settle` or `Stop`, the catalogue's `-run
'Mirror|Schema'`; build, gofmt, vet of the three packages. **No whole package and no `-run Mirror` set: the
whole runs and the race run are started for me by a clerk on your final head.** A section "M9e" in the
report; commit, push, the copy clean; final message: the final commit, what changed per point, each new
rule's undone line and its test, the named runs, anything not done.
