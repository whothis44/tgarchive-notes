# Brief G12b: the review's fixes for G12 (pages, P5, 11-16)

For the coder of G12, on the same copy and branch (`wt-pages-autonew`, `wip/pages-autonew`, from 8184fdfc).
The review: `REVIEW-G12-auto-switch.md` in the project folder (read it whole first; its finding numbers are
used here). ONE round; the same rules as the first brief (named tests only, one go command at a time with
`-p 1`, no door changed, no file outside the first brief's list, commit and push, no process left).

## To fix (all of these)
1. **Finding 1 (must): an "off" must always be possible.** `autoNewView`: an account the doors refused
   (`acct.refused`) whose task is readable (no `task_error`, a task in the answer) and settable:
   switch on: the refused words, then "The switch is on: it acts again once the account is signed in.",
   and ONE button "Switch off"; switch unreadable: the error box and ONE button "Write it anew: off";
   switch off: the refused words, no button. Never an "on" of any kind for a refused account. Under the
   run's flag (not settable): the refused words and the door's why words, no button. The Chats page's
   line is drawn for every account, refused or not (the task is in the answer), and its patch no longer
   skips refused accounts (**finding 5**).
2. **Finding 2 (must): after any click on a switch button the keyboard goes to the block's answer line
   (`[data-msg]`), never to a button**, on every path (success, refusal, failure, re-read failed). Say in
   the function's comment why (the rule `focusAfterClick` already keeps). If the answer line can be absent
   on some path, make it present.
3. **Finding 6: strict comparisons, fail closed.** "on for this run" only for `auto_new === true &&
   auto_new_settable === false`; every button only on exact booleans; any missing, non-boolean or
   contradictory combination: "its state is not in the answer: nothing is offered", no button. A time
   that cannot be shown: say "after a moment the answer does not give" is NOT wanted: show no "taken
   after" clause then, only "on".
4. **Findings 3, 4, 7 and 10: the words, true of the code** (check each number against the constants and
   say in the report where it comes from; if a number is a setting or a flag, say "by default"):
   - the cost's list clause: "(one request per page of the account's chats, and with the first list the
     topic lists of the forums you approved)";
   - the cost's take clause: "Groups and channels you join from that first list on are mirrored by
     themselves (not private chats or bots, not a chat that forbids forwarding; at most 10 are taken a
     look and at most 5 new mirrors are made in 24 hours by default, the rest later): for each, the
     mirror task reads its history, creates a private channel of yours and forwards its messages with a
     file (the default), in its own turns.";
   - the cost's on clause also says the file: "writes two rows (the switch and the moment it began),
     makes the forward secret's file when there is none, and sends nothing by itself";
   - the off clause and `MirrorAutoNewOffDone`: "from the mirror task's next turn on nothing more is
     taken or sent by itself for this account (a request already under way is not recalled); the chats
     already taken wait, their reads too";
   - "not set up yet: the mirror task sets it up at its next turn (when this stays, the program's log
     says why)".
   The tests that pin the words change with them.
5. **Finding 11: the fake as the door.** `demomirrors.go`: an "off" is taken for an account not signed in
   (only "on" is refused); `AutoRunning` is not tied to `AutoNew` (a test can set them apart);
   `SetListEvery` honours the fake's failure switches as the other calls do. Add the test the review
   asks for: a refused account with the switch on shows one "Switch off" and the route takes that "off"
   with one seam call.
6. **Finding 12: the folder script also counts `tgarchive-backup*`** from the folder (the command, the
   header's point 3, the refusal's words), in the folder script's own commit style (a separate commit).
7. **Finding 8, only this much:** in `mirrorsettings.js` the two reads no longer fail each other: when
   `/api/mirrors/settings` fails and `/api/mirrors` reads, the accounts' switch blocks are still painted
   (their "off" stays possible), with the settings' error in place of the rows it could not read and the
   cost sentence replaced by "The cost sentence could not be read: nothing is switched on from here until
   it reads again." and NO "on" button of any kind then (only the off ones). When `/api/mirrors` fails:
   as today.

## Left on purpose (say so in the report, do not build)
Finding 9 (Go's last-key rule, shared by every route); finding 13 (no DOM test harness exists for the two
page scripts: name it under "not verified"); the door's comment of finding 4 (the mirror track's).

## Tests and hand-back
Node cases for every branch of `autoNewView` named above (refused on, refused unreadable, refused off,
refused under the flag, each contradictory combination of finding 6) and for the settings-failed view;
the server's named tests; `gofmt -l` and `go build ./...`; test functions removed or renamed: name each
(aim 0). Extend `archiver/docs/progress/pages-autonew-REPORT.md` with a section "The review's round".
Last message, at most 12 lines: the head, pushed; each point 1 to 7 as done or not with one clause; the
named tests with counts and seconds; anything the code made you change in these words.
