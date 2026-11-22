# Review of G12 (wip/pages-autonew, head 8184fdfc, against 2b557601): the switch "mirror chats I join by themselves" and the chat list's interval on the pages

**Verdict: may be listed after these fixes** (2 must fix, 3 should fix, 8 minor).

Reviewer: an independent Opus agent, 11-16. Read-only on the worktree; probes and planted copies under
`wt-pages-review-g12-scratch`, loaded with `go test -overlay`. Every go command: one at a time, `-p 1`,
`GOMAXPROCS=4 GOGC=50`, `-count=1`, named tests only; free memory 2.0-2.1 GB and CPU 59-81 % before each batch.
Nothing talked to Telegram; no window, no program but go, gofmt (list), git (read), node and PowerShell (measuring).

The server's route, its body checks, the guard, the staleness of the kept reading, the adapter and the words
pinned by tests are sound: every probe of points 1 and 2 came out right, and all six planted changes (plus a
seventh for the guard's markDirty) were caught by a named test. The two must-fixes are both in the Settings
page's handling of the owner's "off", the one act rule 1 says must always be possible and never undone.

## Findings, by weight

### 1. MUST FIX: a signed-out account whose switch is on cannot be switched off from the page (rule 1)
*Confirmed by probe `TestProbeG12Refused`.*
- `web/assets/js/mirrorwords.js` `autoNewView`, the line `if (acct.refused) return { words: acct.refused, tone: 'muted', buttons: [] };`
  (the third `if`), and `pages/chatmirror.js` (its new line is drawn only for `!x.refused` accounts).
- The doors refuse a not-signed-in account's states (`mirror.States` → `d.signedIn` → `ErrNotSignedIn`,
  internal/mirror/door.go 211-213), so `mirrorStates` sets `k.refused`. **But the task is still read**: `Task` is
  asked before the refusal check (server/mirrors.go 511-512) and the collector's `MirrorTask` door does not refuse
  a signed-out account (mirror_door.go 393-435: it only sets `Why`). `keptTask` hands both back.
- Probe output: with `refuseStates` set and the stored switch on, `GET /api/mirrors` gives account 1
  `"task":{... "auto_new":true, "auto_new_settable":true ...}, "refused":"This account is not signed in: nothing is done for it."`;
  `autoNewView` of that answer gives `buttons=0`; `POST /api/mirrors/auto-new {"account":1,"on":false}` answers 200
  (the real door takes an "off" for any account it has: mirror_door.go 481-483, 520-533 checks sign-in for "on" only).
- Why it matters: the owner who signed an account out and wants the automatic mirror off before signing in again
  has no way to say so. At the sign-in the switch is still on, the task sets it up at its next turn and the look
  takes the chats joined since the old baseline (possibly joined while signed out) before the owner can reach a
  button. That is exactly the "off" rule 1 (TRIED-BEFORE 24/25) says must always be possible. The brief's case 1
  ("refused: no button at all") produced this; the brief was wrong here, not the coder.
- **Smallest fix accepted:** in `autoNewView`, when `acct.refused` is set and the task is readable (no
  `task_error`, `auto_new_settable === true`): if `auto_new === true`, words "<refused words> The switch is on: it
  acts again once the account is signed in." and ONE button, "Switch off"; if `auto_new_unreadable`, the error
  box and ONE button, "Write it anew: off"; otherwise (off) the refused words and no button. Never an "on" for a
  refused account. A node case for each. The Chats page may keep its present behaviour, or show the state line
  for refused accounts too (the task is in the answer).

### 2. MUST FIX (plausible): after a click the keyboard lands on the opposite button, so a repeated Enter writes the opposite value
*Plausible (code read; browser key repeat not run here).*
- `pages/mirrorsettings.js` `setAuto`, its last line:
  `(block?.querySelector('button[data-auto]') || block?.querySelector('[data-msg]'))?.focus();`
- After a successful "Switch off" the block is painted from the answer's task: state "off", one button, "Switch
  on (asks Telegram for one chat list now)", and the focus goes to it. A held Enter (key repeat fires a click per
  repeat on a focused button) or a second Enter pressed because the first seemed not to register writes "on": a
  chat list asked of Telegram and, from then on, channels created and messages forwarded, which the owner did not
  ask for. The same after "Switch on" (focus on "Switch off": the safe direction) and, worse, in the unreadable
  state: its first button is "Write it anew: on", so after a refused or failed "Write it anew: off" (no repaint
  of the buttons) the keyboard sits on "on". The disabling during the request does not cover the moment after
  the answer.
- The project already learnt this: `mirrorwords.js` `settleSafe`/`focusAfterClick` send the keyboard to the
  answer after a yes because "a rebuild ... could put it on a button that means something else". The brief's
  "focus returns to the block's button" repeated the hazard.
- **Smallest fix accepted:** always focus the block's answer line (`[data-msg]`, which already has
  `tabindex="-1"` and `role` status/alert), never a button. One line.

### 3. SHOULD FIX: the cost sentence promises more than the task does ("Chats you join from that first list on are mirrored by themselves")
*Confirmed by reading (no probe).*
- `internal/server/mirrors.go`, `mirrorAutoNewCostTail`.
- `internal/mirror/auto.go` 310 (`ch.Kind == "user" || ch.Bot`: private chats and bots are never taken), 320
  (only group, supergroup and channel), 349-355 (a chat that protects its content is not taken), 41-44 (at most
  `AutoLookCap` = 10 a look and `AutoNewPerDayDefault` = 5 new mirrors in any 24 hours, the rest later).
- The words say every chat joined is mirrored. Smallest fix: "Groups and channels you join from that first list
  on are mirrored by themselves (not private chats or bots, not a chat that forbids forwarding; at most 5 new
  mirrors a day, the rest later): for each, ...". The test pins the words, so the test changes with them.

### 4. SHOULD FIX: the "one chat list at once" can carry the topic lists of the approved forums too
*Plausible (code read; the collector rig was not run).*
- Words: `mirrorAutoNewCostHead` "(one request per page of the account's chats)" (copied from the door's comment,
  mirror_door.go 502-507, which says the same).
- Code: `reader.go` 557-559 asks the topic lists after a chat list when `s.topicsDue(now)`; `mirror_auto.go`
  732-742 `topicsDue` with the switch on returns true when `a.autoTopicsAt` is 0, i.e. at the first chat list
  with the automatic mirror set up in this process. A page's "on" in a running program makes exactly that list
  (the one at once), so it also asks the topic list of every approved forum of the account.
- Smallest fix: "(one request per page of the account's chats, and with the first one the topic lists of the
  forums you approved)". The door's comment should be put right by the mirror track (not this piece's file): a
  line on the board.

### 5. SHOULD FIX: the Chats page's line is not updated for an account that becomes refused, and is never added for one that stops being refused
*Confirmed by reading.*
- `pages/chatmirror.js` `patch`: `if (el && !a.refused && ...)` skips refused accounts, and the line exists only
  for accounts that were not refused at the last full paint; `again()` repaints in full only when the shape
  (rows, cells' keys) changed. So a "on: ..." line stays painted for an account that is now refused, until a full
  paint. The words are a reading of the switch, which the answer still carries for a refused account; the skip is
  not needed.
- Smallest fix: drop `!a.refused` from the patch (and, with finding 1, draw the line for every account).

### 6. MINOR: `autoNewView` shows "on for this run" whenever `auto_new_settable` is not true
*Confirmed by probe `TestProbeG12View`; not reachable from this server.*
- Probe: `{auto_new:false, auto_new_settable:false}`, `{auto_new:false}` (settable missing) and
  `{auto_new:true}` (settable missing) all give "on for this run"; `auto_new_settable: 'false'` (a string) offers
  "Switch on"; `auto_new_unreadable: 'false'` (a string) offers both writes anew; `auto_new_from: 5` gives "chats
  you joined after not known are taken".
- Reachable? No: the door sets `AutoNew` true whenever it is not settable (mirror_door.go 449-451), `convTask`
  maps it, Go writes booleans, and the page ships in the same binary as the server. The fake does the same.
- What it should say (fail closed, rule 13): "on for this run" only for `auto_new === true && auto_new_settable === false`;
  any other non-boolean or contradictory combination: "its state is not in the answer: nothing is offered", no
  button. Compare with `=== true` / `=== false` throughout. Cheap; recommended with finding 1.

### 7. MINOR: "(when this stays, the task's line says why)" is not always true
*Confirmed by reading.* A set-up that fails for any reason but the missing secret is only logged
(mirror_auto.go 1230-1251); `MirrorTask.Why` (mirror_door.go 417-433) does not reflect it, so the task's line is
empty while "not set up yet" stays. Smallest fix: "(when this stays, the program's log says why)" or drop the
parenthesis.

### 8. MINOR: the settings answer now fails as a whole when the interval's read fails
*Confirmed by reading.* `mirrorSettingsAnswer` returns the interval door's error (mirrors.go, the third read),
and `mirrorsettings.js` then paints one error box in place of the name rule, the gathering, the interval and
every account's switch (paint: `if (!data || data.error)`). In practice the three reads are settings rows of
the same catalogue and fail together (or are all `ErrDoorNotRunning`), so no real case is worse than before; but
the switches, which come from `/api/mirrors`, are now hostage to the settings answer (and `Promise.all` makes
each answer hostage to the other). Not required; if touched: paint the switch blocks from `/api/mirrors` alone.

### 9. MINOR: the body parse takes the last of duplicated keys and matches keys without case
*Confirmed by probe `TestProbeG12Bodies`.* `{"account":1,"on":true,"on":false}` → 200, one door call, off;
`{"account":1,"ON":true}` → 200, on; `{"account":1,"on":false,"On":true}` → on; `{"account":1,"on":true,"account":2}`
→ account 2. This is Go's `encoding/json`, shared by every route, behind the token and the same-origin guard;
the page's own body (`JSON.stringify`) cannot carry duplicates. Information only.
All other probes as intended: `on` as array, object, `True`, string, number, null, missing → 400 and no door
call; account float, string, 0 → 400; two objects → 400; `text/plain` → 415; 1 MB body → 413; GET and PUT →
405; cross-site, same-site, no token, a foreign Origin → 403; each with 0 door calls.

### 10. MINOR: the cost omits the forward secret's file and the "next turn" of the off
- An "on" also makes the forward secret file when it is absent (mirror_door.go 530): a file written, no request.
- `MirrorAutoNewOffDone` and the cost's off clause say "Nothing more is taken or sent by itself"; the task reads
  the switch at its next turn (mirror_auto.go 1194-1283), so a request already under way is not recalled (the
  page's own `MirrorNeverDone` says this for "never"). Optional: "... from the task's next turn on; a request
  already under way is not recalled."

### 11. MINOR: the demo's fake refuses an "off" where the door takes it
`demomirrors.go` `SetAutoNew`: `refuseAuto` refuses on and off alike; the door refuses only "on" for an account
not signed in. The fake's `AutoRunning` is tied to `AutoNew` (the door's `AutoJoined` is independent and can be
true for up to a turn after an off). `SetListEvery` ignores `failAll` and the hook. Only the tests use these (the
demo refuses every change in the guard); worth fixing with finding 1 so a test can hold the refused "off".
Invented data only: confirmed (account ids of the fixture catalogue, `now()-3600`, no name, path or text).

### 12. MINOR: the folder script does not count `tgarchive-backup*`
`deploy/folder/make-folder.sh` builds `programs/tgarchive-backup.exe` (line 130) but its running check counts
tgarchive, collector, watchdog, window, viewer. Outside the brief (which named window and viewer). The changed
PowerShell line itself is right: quoting holds inside bash single quotes; `Get-Process -Name` takes the
wildcards; `$p -and` skips a process whose Path is empty (an elevated or another user's process: not counted,
as before); the names match those the script builds (lines 125-129). Run once by itself against the scratch
folder: exit 0, count 0, no error.

### 13. MINOR: tests that hold none of the page scripts' DOM rules
No test runs `mirrorsettings.js` `setAuto`/`autoBlock` (the disabling, painting from `r.task`, the re-read's
"cannot be read", the focus) or `chatmirror.js`'s line and patch. The brief asked them "tested as today"; today
nothing tests these two files' DOM code. Findings 2 and 5 live there.

### 14. Point 5's questions, answered
- `autoLine` (a `const` arrow declared after `filter`, chatmirror.js line 280): no ReferenceError. `mirrorPart`
  runs straight through to its `return` (line 429) with no call at its top level (checked: no statement between
  lines 39 and 429 calls `filter`); `filter` is called only after `mirrorPart` returned, when `autoLine` is
  initialised.
- `#/settings` is the router's address of the Settings page (main.js 27 `pages.settings`; main.js 155 uses the
  same link).
- The poll's update keeps the line right for accounts not refused (finding 5 for the rest).

## The planted changes and the tests that caught each
Base run first: `internal/server -run 'TestMirrorAutoNew|TestMirrorListEvery|TestMirrorRoutesInGuard|TestMutationsRefusedFromElsewhere|TestMirrorHeldStopRefusesChanges'` ok 1.7 s;
`internal/collector/livepages -run TestMirrorAdapter` ok 0.6 s.

| # | Planted | Caught by |
|---|---------|-----------|
| 1 | the `on` parse's default branch: `on = false` instead of the field message | `TestMirrorAutoNewRefusedBeforeTheDoor` (status 200, want 400) |
| 2 | `convTask`: `AutoNew: t.AutoJoined` | `TestMirrorAdapterTaskSwitch` (2 cases) |
| 3 | `doorRefusals`: the row of `ErrDoorAutoNewByRun` removed | `TestMirrorAdapterSwitchRefusals` (2 lines) |
| 4 | `autoNewView`: the unreadable branch removed (a copy of mirrorwords.js, the test's path pointed at it) | `TestMirrorAutoNewView` |
| 5 | the account check removed (`if false && !contains(...)`) | `TestMirrorAutoNewRefusedBeforeTheDoor` (status 200, want 404) |
| 6 | no re-read: the answer's task from `keptTask` | `TestMirrorAutoNewOneCallEach`, `TestMirrorAutoNewRefusedFailedReread` |
| 7 (extra, point 2) | the guard's two `markDirty` calls removed (server.go) | `TestMirrorAutoNewOneCallEach` ("the next reading kept the task from before the click") |

Point 2 probe (`TestProbeG12Stale`): the kept reading primed, the door's switch changed behind the server
(the kept reading still said off: the premise held), then a click on each path; the next `GET /api/mirrors` asked
the doors again every time: success 200, asks 1→2, on; refusal 409, 1→2, on; failure 502, 1→2, on; re-read
failed 200, 1→2, on. The claim "stale through the guard's markDirty" holds on every path.

Test functions removed or renamed against the base: **0** (13 added; `git diff` shows no `-func Test`).
`gofmt -l` on the 9 changed Go files: clean.

## Point 6, clause by clause
| Clause | Borne out? | Where |
|---|---|---|
| "Switching it on writes two rows (the switch and the moment it began)" | yes (nothing when on already; also makes the secret file: finding 10) | mirror_door.go 544-562, 530 |
| "and sends nothing by itself" | yes | mirror_door.go 509-582 (catalogue only) |
| "asks Telegram for the chat list of this account once, at once" | yes, at the reader's next turn once set up; with no list on record the next turn's own list | mirror_door.go 554-557, 573-576; mirror_auto.go 588-594, 619-620 |
| "(one request per page of the account's chats)" | **not fully**: the first list with the switch set up in the process also asks the approved forums' topic lists (finding 4) | reader.go 557-559; mirror_auto.go 732-742 |
| "afterwards every N minutes plus a random part of up to S seconds while it is on" | yes ("up to" covers -auto-mirror-steady and no secret: no random part) | mirror_auto.go 614-626, 656-679; mirror/autonew.go 158-170 |
| "Chats you join from that first list on are mirrored by themselves" | **no**: not private chats, bots, other kinds, protected chats; 10 a look, 5 a day (finding 3) | mirror/auto.go 41-44, 310, 320, 349-355 |
| "reads its history, creates a private channel of yours and forwards its messages with a file (the default)" | yes (media only unless -auto-mirror-all-messages) | mirror/auto.go 9-13, 68-69 |
| "in its own turns" | yes | mirror/auto.go 15-20 |
| "A chat you joined while it was off is never taken later." | yes | mirror_door.go 490-497 (autoMovedSince) |
| "Switching it off: nothing more is taken or sent by itself; the chats already taken wait, their reads too." | yes, from the task's next turn (finding 10) | mirror_auto.go 1259-1282; mirror_door.go 145-157 |
| `MirrorAutoNewOnDone` (conditional list) | yes; "now" means at the set-up turn | as above |
| `MirrorAutoNewOffDone` | yes, from the next turn | as above |
| `MirrorListEveryWhen` "reads it at its next turn" / "counts only ... switch is on" | yes | mirror_auto.go 1221-1226, 616-617 |
| `MirrorListEveryCost` "three times as often as at 30"; "not measured yet"; "the run's report counts them per hour" | arithmetic yes; the per-hour count not traced beyond `telegram/counters.go` 80 (`Dialogs`) and `ctr.ChatLists` | reader.go 536 |
| unreadable interval "every 30 minutes until ... stored again" | yes | mirror_auto.go 662-665; mirror/auto.go 57 |
| `auto_new_from`: "chats you joined after <time> are taken" | yes (joined_at > baseline), with finding 3's limits | catalog/schema_mirrorauto.go 838; mirror_door.go 466-472 |
| `auto_running` false: "not set up yet: the mirror task sets it up at its next turn" | yes; "(when this stays, the task's line says why)" not always (finding 7) | mirror_auto.go 1227-1257; mirror_door.go 402, 417-433 |

## Point 11: paths, names, ids
Nothing found. The one new log line ("pages: %s: the task's re-read failed (%s)") carries the route's fixed name
and the error's type only (`errClass`); `TestMirrorAutoNewRefusedFailedReread` checks no words reach the log.
The answers carry the account number, fixed words and the door's fixed `auto_new_why`. The scripts show only the
server's words, the door's refusal words and the account number.

## What I did not look at
- The collector's own tests (`TestPagesMirrorsSwitchThroughTheSeam`, `...UnderTheFlag`, `...DoorErrSwitch`) were
  read, not run (the collector package's test build under this PC's memory); no plant in `pages_mirrors.go`.
- No page was opened in a browser; the DOM code of `mirrorsettings.js` and `chatmirror.js` was read only.
- The `internal/launcher` tests of the folder script were not run; the script was not run (only its PowerShell
  line, against the scratch folder).
- The hourly report's per-hour count of chat lists was not traced to its printed line.
- Whole-package runs, race, vet: not mine (the pages session's full runs).

## Scratch
`C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g12-scratch`: `probe_g12_test.go` (the four probes),
`overlay-*.json`, the planted copies under `p1` to `p7` and `js`, `plants.sh` (the runs).
