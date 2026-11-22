# Brief G12: the switch "mirror chats I join by themselves" as a control, and the chat list's interval as a setting (pages, P5, 11-16)

You are an Opus coder for the pages track of the standalone archiver (Go module `archiver/` in your copy).
One piece, commit-ready. Read this whole brief before the first edit.

**Rules of the house, first.** Routine steps are yours to script, not to repeat by hand. While working run
only NAMED tests (`go test ./internal/server -run 'TestMirror...' -count=1`); never the whole
`internal/server` (158 s), never the whole `internal/collector` (19 minutes), no race detector, no `go vet`
over many packages: the full runs are made once by the pages session after the review. Nothing here talks to
Telegram: start no collector, no launcher, no window, open nothing on the desktop. Invented data only in
tests and the demo (no real name, text, path or id). No text with a Windows path goes through a shell
string. Commit as you go to your branch and push it to the remote `private` (never the main branch):
`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. No archive numbers in commit messages.

## 0. Where you are
- Your copy and branch are named in the message that started you (cut from the main head that holds the
  mirror's piece M10). Change only: `internal/server` (Go, `web/assets`), `internal/collector/livepages`,
  `internal/collector/pages_mirrors.go` with its test, `deploy/folder/make-folder.sh` (part C), and one
  report file. **Nothing else in `internal/collector`, nothing in `internal/mirror`, `internal/catalog`,
  `internal/launcher`, `internal/window`, `internal/viewer`.** If a door does not give what this brief
  needs, stop and say so in your report: do not change the door.
- Read first: `internal/collector/mirror_door.go` (the type `MirrorTask`, `autoNewFacts`,
  `SetMirrorAutoNew` with its long comment, `MirrorListEveryFacts`, `MirrorListEvery`,
  `SetMirrorListEvery`), `internal/mirror/autonew.go` (the constants `ListEveryDefault`, `ListEveryMin`,
  `ListEveryMax`, `ListSpread`, the sentinels), `internal/collector/words.go` (which sentinels exist),
  then the pages' side as it is: `internal/server/mirrors.go` (the seam `Mirrors`, `MirrorTask`,
  `mirrorStates` and `keptTask`, the settings routes at the end), `internal/server/demomirrors.go`,
  `internal/collector/livepages/mirrors.go` (`DoorTask`, `doorRefusals`, `convTask`, the seam),
  `internal/collector/pages_mirrors.go` (`doorErr`, `MirrorTask`),
  `web/assets/js/pages/mirrorsettings.js` (whole: 133 lines; the fact is shown there today),
  `web/assets/js/mirrorwords.js` (`taskNote`), `web/assets/js/pages/chatmirror.js` (where an account's
  line is painted), and how the existing tests of these files are made.

## 1. What the old app already knows (the record; nothing to re-derive)
- The old app's 12.30 added chats by itself and flooded the owner's queue; its review found, after every
  test had passed, the rules any automatic act for the owner must keep (`archiver/docs/TRIED-BEFORE.md`
  sections 24 and 25; read both, about 65 lines). The ones this page meets: (1) a person's "off" is never
  undone by the program (the door keeps it; the page never writes "on" by itself, never toggles, never
  retries a click); (7) one item per call (one account a call); (9) no request for something that will
  not be acted on (the page asks Telegram nothing, ever); (11) one row per item, written by the door, never
  a list kept by the page; (13) **fail closed: a switch that cannot be read is shown as "cannot be read",
  never as off and never as on, and a task that cannot be read offers no "on".**
- The old app compared the chat list every half hour. The owner (11-16) on the new app's interval: "30
  minutes seems too long. Can we make it a selectable option? Maybe default to 10, with some fuzziness."
  And on a switch-on asking for one chat list at once: "Yes". Both are built in M10's doors; this piece
  only shows and sets them. The cost on record: at 10 minutes the chat list is asked three times as often
  as at 30 while the switch is on; how many requests one chat list costs on an account is not measured yet
  (the first real run counts it per hour). The page says exactly that and no number it does not have.

## 2. Part A: the switch (per account)
**The facts (the door's `MirrorTask`):** `AutoNew` (the switch in force: stored on, or the run's flag),
`AutoNewSettable` (false only while the run has `-auto-mirror`), `AutoNewWhy` (the door's fixed words when
not settable), `AutoNewUnreadable` (the stored row cannot be read: nothing is taken or sent by itself;
writing it anew is the remedy and is allowed), `AutoNewFrom` (while on: chats joined after it are taken;
zero: none yet, it comes with the next chat list stored whole), and `AutoJoined` (set up and running now:
false for up to a turn after an "on", and while a set-up fails).

1. **The wrapper and the adapter carry all of them.** `livepages.DoorTask` and `server.MirrorTask` gain
   the fields; **`server.MirrorTask.AutoNew` is mapped from the door's `AutoNew`, no longer from
   `AutoJoined`** (today `convTask` does the latter: the mirror's review named it). JSON, additive:
   `auto_new` (now: the switch in force), `auto_new_settable`, `auto_new_why`, `auto_new_unreadable`,
   `auto_new_from` (Unix seconds, 0: none), `auto_running` (the door's `AutoJoined`). Put the comments of
   `MirrorTask` right.
2. **The seam gains `SetAutoNew(ctx, account int64, on bool) error`** (`server.Mirrors`, the adapter's
   `mirrorSeam`, `livepages.MirrorDoors.SetMirrorAutoNew`, the wrapper, `demomirrors.go`'s fake).
   Refusals: every sentinel `SetMirrorAutoNew` can return gets its row in `doorRefusals` with the page's
   words ending in "nothing was recorded": the run's flag (`ErrAutoNewByRun` is the collector's: give it
   through `doorErr` as a new `livepages` sentinel, as the five there are; words: "The program was started
   with -auto-mirror: the switch is on for this run and is not set from a page. Nothing was recorded."),
   not signed in (`mirror.ErrNotSignedIn` has a row), no such account, not running, no secret file (rows
   exist). Find by reading the door what else it can return (the sign-in record unreadable; the forward
   secret's error) and say in your report how each reaches the page: a named refusal, or the page's
   failure words. A test walks the list: every sentinel the three new doors can return has a row or is
   named in the report as a failure on purpose.
3. **The route `POST /api/mirrors/auto-new`**, body `{"account": N, "on": true|false}`: both fields
   required (`on` a JSON boolean and nothing else: no "toggle", no default; a missing or wrong one is a
   400 beside its field and the door is not called); the account must be one of the catalogue's accounts
   not marked removed (404 otherwise, as the other mirror routes); the server's work context; ONE door
   call; no retry. After a door call that returned nil: the account's kept reading (`keptOf`) is made
   stale in the way the other changing routes make it stale (read how a want or a stop does it; if they
   do not, say so and add the smallest correct thing under the kept reading's own lock), the task is read
   again through the seam and answered: `{"words": ..., "account": N, "task": {...}}`; when that re-read
   fails: the stored words plus "could not be read again now: reload the page", `"reread_failed": true`,
   and no task. A refusal: 409 with the door's words (`mirrorOutcome`); a failure: 502 with the page's
   failure words; neither logs the words.
4. **The words, as server constants (tests pin them; the scripts show them and add none of their own
   about cost):**
   - Before the click, beside the control, always visible while the control is (`MirrorAutoNewCost`, with
     the interval's numbers filled in by the server from the list-every facts: N minutes, S seconds):
     "Switching it on writes one row and sends nothing by itself. The running program then asks Telegram
     for the chat list of this account once, at once (one request per page of the account's chats), and
     afterwards every N minutes plus a random part of up to S seconds while it is on. Chats you join from
     that first list on are mirrored by themselves: for each, the mirror task creates a private channel
     of yours and forwards its messages, in its own turns. A chat you joined while it was off is never
     taken later. Switching it off: nothing more is taken or sent by itself; the chats already taken
     wait, their reads too." When the interval cannot be read, the sentence says "every 30 minutes until
     the interval is stored again" (the door's fallback) in place of N and S. Check each clause against
     the door's comments and M10's code; where the code says otherwise, the code wins and your report
     says which clause you changed.
   - After an "on" (`MirrorAutoNewOnDone`): "Recorded: on. Nothing was sent at the click. If the switch
     was not on already, the running program asks Telegram for one chat list of this account now, once."
     (The door answers nil both when it wrote and when it was on already: the page cannot tell, so the
     sentence is conditional. Do not claim a list was asked.)
   - After an "off" (`MirrorAutoNewOffDone`): "Recorded: off. Nothing more is taken or sent by itself for
     this account; the chats already taken wait."
5. **The control (`mirrorsettings.js`, the region "Mirrors: chats you join"; one block per account).**
   Build the state line and the choice of buttons in ONE pure function in `mirrorwords.js`
   (`autoNewView(acct)` giving the words, the tone and which buttons), used by both pages and tested as
   the file's other functions are. Its cases, in this order:
   - the account's task cannot be read (`task_error`), or the account's doors refused it: those words; **no
     button at all**;
   - `auto_new_unreadable`: an error box "The stored switch cannot be read: nothing is taken or sent by
     itself for this account until it is written anew."; two buttons: "Write it anew: on (asks Telegram
     for one chat list now)" and "Write it anew: off";
   - not settable: "on for this run", then the door's `auto_new_why` words as given, shown and never
     parsed (the page's old sentence "Set by how the program was started" goes; nothing says "cannot
     change it yet"); no button;
   - on: "on" plus one of: `auto_running` false: "not set up yet: the mirror task sets it up at its next
     turn (when this stays, the task's line says why)"; `auto_new_from` zero: "no chat list is stored
     whole since it was switched on: nothing is taken before one is"; else "chats you joined after
     <the time, as the pages show times> are taken"; one button: "Switch off";
   - off: "off: no chat you join is mirrored by itself"; one button: "Switch on (asks Telegram for one
     chat list now)".
   The task's own "does not run for this account now: why" line stays as it is, after these. The cost
   sentence stands under every block that has a button. A button is disabled while its request runs and
   after it the block is painted from the answer's task (not from a guess); the answer's words or the
   refusal show under the block (`role="status"` or `"alert"` as the file does); focus returns to the
   block's button. With the pages alone (`needs`): the block's buttons shown disabled with the `needs`
   words, as the file's other controls. Every button carries `dataset.needsProgram` as its neighbours do.
6. **The Chats page:** one line per account where its task note is painted today, from the same
   `autoNewView`: the state words only and "(set on the Settings page)" as a link to that page; no
   button there. If there is no natural place without restructuring the page, leave this point out and
   say so.

## 3. Part B: the chat list's interval (catalogue-wide), on the Settings page beside the gathering
1. The seam gains `ListEvery(ctx) (MirrorListEvery, error)` and `SetListEvery(ctx, minutes int) error`
   through the same four layers. `server.MirrorListEvery`: `minutes`, `stored`, `unreadable`,
   `spread_max_seconds`, `min`, `max` (the adapter fills min and max from `mirror.ListEveryMin` and
   `ListEveryMax`, as it does for the gathering). `mirror.ErrListEveryRange` gets a row in `doorRefusals`
   whose words are built from the two constants ("The chat list's interval is 5 to 1440 whole minutes.").
   `GET /api/mirrors/settings` gains `list_every`, `list_every_when` and `auto_new_cost`.
2. The route `POST /api/mirrors/list-every`, body `{"minutes": N}`: as `handleMirrorGather` (a missing
   field is a 400; the door checks the range and its refusal is shown beside the field in its words; the
   answer is `settingsAnswer`).
3. The words: `MirrorListEveryWhen`: "Stored at once; each account's mirror task reads it at its next
   turn. It counts only for an account whose switch \"mirror chats I join by themselves\" is on."
   `MirrorListEveryCost`: "A shorter interval asks Telegram for the chat list more often: at 10 minutes
   three times as often as at 30. How many requests one chat list costs on an account is not measured
   yet: the run's report counts them per hour."
4. The rows (`mirrorsettings.js`, in the region "Mirrors: chats you join", above the accounts' blocks):
   the state ("The chat list is asked every N minutes, plus a random part of up to S seconds" with "(the
   default)" when none is stored; unreadable: an error box "The stored interval cannot be read: the chat
   list is asked every 30 minutes until it is stored again here."), a number field (min, max, step 1,
   empty when unreadable) with "Store the minutes", the page's own whole-number check as the gathering
   has, the cost and the "when" sentences, the message line. Look at what the door gives for the random
   part in a run started with `-auto-mirror-steady` (the task then uses none): if the facts cannot tell,
   the words say "up to" and your report notes it.

## 4. Part C (its own commit; another file): the folder script's running check
`deploy/folder/make-folder.sh`, the function `running()` and the header's point 3: it counts
`tgarchive.exe`, `tgarchive-collector*` and `tgarchive-watchdog*` running from the folder. Add
`tgarchive-window*` and `tgarchive-viewer*` (by the program's path under the folder, as the others), in
the command and in the header's and the refusal's words. Do not run the script against any folder but a
scratch one you make under your copy; never the owner's folder. If the script has a test or a dry mode,
use it; else read it twice and say "not run" in the report.

## 5. Tests (named; yours while working)
- `internal/server`: the route's refusals without a door call (missing `on`, `on` not a boolean, unknown
  or removed account); an "on" and an "off" each make exactly one seam call with that account and value;
  a seam refusal is a 409 in its words and a failure a 502 in the page's words, neither logged with
  words; the answer's task is the one read after the call, and the next `GET /api/mirrors` does not show
  the task kept from before the click; a failed re-read answers "stored" with `reread_failed`;
  `auto_new_unreadable` true is serialised as that with `auto_new` false and the view never calls it
  off; the settings answer carries the interval and both cost sentences; `list-every` as the gathering's
  tests. The pages alone (no seam): the routes are not registered.
- The scripts: `autoNewView`'s five cases and the unreadable interval, tested the way `mirrorwords.js` and
  `mirrorsettings.js` are tested today.
- `internal/collector/livepages`: `convTask` maps `AutoNew` from the door's `AutoNew` (a task with
  `AutoJoined` false and `AutoNew` true shows on); every new sentinel has a row; the rig's fake doors
  gain the three calls.
- `internal/collector` (the wrapper's own test file, by name): through the real doors on a test
  catalogue, a `SetAutoNew(true)` from the seam writes the row and the task then reads on; under
  `Config.AutoMirror` the seam's refusal carries the flag's words. Use the mirror's own test helpers
  (`mirror_autonew_test.go`); if such a test needs more than about a minute, name it and say so.
- **Count the test functions you remove or rename against your base and name each in the report** (the
  aim is 0).

## 6. Hand back
Everything committed and pushed on your branch; `gofmt -l` clean on what you touched and
`go build ./...` exit 0 for Windows (those two are yours); the named tests you ran with their results;
a report `archiver/docs/progress/pages-autonew-REPORT.md`: what was built, each place the code made you
change this brief's words, the door's returns and how each reaches the page, files touched, test
functions added and removed, what was NOT verified (nothing here has run against Telegram; no page was
opened in a real window). Leave no process behind. Your last message: the head's short hash, the test
counts, and anything you could not do, in at most 15 lines.
