# Brief M12: the cap on new mirrors in 24 hours as a stored setting, default 20 (session M-6, 11-16)

**For one Opus coder (high effort).** Branch `wip/mirror-cap`, its own copy `wt-mirror-cap` (cut from the main
head 2b557601, which holds M10). You hand back commit-ready work on that branch, pushed to `private` as you go
(never the main branch, never `origin`). Nothing in this piece runs against Telegram: the fake only. A small
piece: no schema step, no `go.mod` change.

**The rules that bind you before anything else (the project folder's `CLAUDE.md`, archiver section):**
- **Every go, gofmt and vet command goes through the track's one script, which takes a lock and waits for the
  PC** (another coder of this track works beside you): `bash
  /c/Users/trabi/Claude/Projects/Telegram/runs-mirror-m6/go1.sh <your copy's archiver folder> go test ...`.
  Never `go` directly. On its exit 98 (the PC stayed busy) go on writing and try again later; twice in a row:
  say so in your report and hand back what you have.
- While working run only named tests (`-run`, a `-timeout` on every line). **No whole run of
  `internal/collector` or `internal/catalog`, no race detector:** the full runs happen once, after the review.
- Routine sequences (format, vet, the named tests, a commit, a push) are one script of yours, not call by call.
- Counts, sizes and timings only in every log line, test name, commit message and report: never a chat's name,
  a message's text, a path of the owner's or a Telegram id. New log lines use constant format strings.
- You stop and write to me (your report's first lines) instead of deciding, when a rule below cannot be kept
  as written or a file outside the list at the end must change.

## 1. What the owner asked (11-16, to the pages session; the board's message 129)
On the automatic mirror's caps as the page states them (at most 10 chats taken a look, at most 5 new mirrors in
24 hours): "Why are the caps so low? Can we adjust them higher, and make them configurable?" Then, on 20 a day
by default, settable 1 to 50, the upper bound raised only after the first real run has shown what a create
costs: "Let's go with your recommendation for now".

## 2. What the old app and the record already know
- **The old app's cap was far higher and the rate was not what hurt:** 12.30 added chats by itself at up to 10
  per half hour; it added 30, and the owner switched 24 off by hand within the day (`LESSONS-ix12.30-live.md`
  6b in the project folder): the harm was choosing for the owner and taking the queue, not the number per
  day. A mirror takes no bytes and no place in the queue, and "mirror chats I join by themselves" acts only on
  chats the owner joined. From it the rules that bind this piece (`archiver/docs/TRIED-BEFORE.md` sections 24
  and 25): a cap per step stays; a value that cannot be read never reads as "no cap" (fail closed); one row
  per item; nothing a person set is undone.
- **Telegram's side, on record (`archiver/docs/TELEGRAM-FACTS.md` section 11):** the one documented limit is 500
  channels and supergroups for an account without Premium, every mirror counting (the plan already shows the
  count against it); one create has run for real: three requests, no wait. **Not on record: what many creates
  in a day cost.** So 5 was this app's own caution, and 50 stays the upper bound until a real run shows more.
- **In the code today** (read by me on 2b557601): `internal/mirror/auto.go` has `AutoNewPerDayDefault = 5`, min 1,
  max 50; `AutoOptions.NewPerDay` (the run's `-auto-mirror-new-per-day`; 0 becomes the default in `normal()`)
  bounds the task's creates at about line 727 (`created >= int64(o.NewPerDay)`: the automatic and the owner's
  creates of 24 hours together); `AutoDeps.NewPerDay` with `newPerDay()` in `door.go` is what the doors show
  and bound an owner's want by (`CreatesCap`, `CreatesRoomAt`); the collector hands the flag's value to both
  (`mirror_auto.go` about 1444 to 1484, `mirror_door.go` about 89). Nothing in the folder's app sets the flag.
- **The form to follow is M10's chat-list interval** (`internal/mirror/autonew.go`: `ListEveryKey`,
  `CheckListEvery`, `FormatListEvery`, `ReadListEvery`, `SetListEvery`, its two sentinels; the collector's doors
  `MirrorListEvery` and `SetMirrorListEvery` in `mirror_door.go`; `Config.AutoListEvery` where 0 means "the
  stored setting"). Read those first and build this the same way; do not invent a second form.

## 3. What to build
**A. The setting.** One catalogue row, `mirror.auto.new_per_day`: a whole number, 1 to 50; nothing stored: 20.
A stored value that is not exactly what the format writes for a value in range cannot be read: **then 5 is in
force (the careful value), said once a session in a line of fixed words, never 20 and never "no cap".** In
`internal/mirror`: the key, the three numbers, check, format, read (value, stored, error), set, and two
sentinels (cannot be read; out of range: fixed words fit for a page).

**B. Where it is in force: one function, asked at the moment of use.** The task's cap at each turn and the
doors' cap at each plan come from the same function: the run's flag when the run was started with one, else
the stored setting as read then. **A value set from a page holds from the task's next turn and the next plan,
with no restart** (a rig test: 20 by default; set to 3: the third create of the 24 hours is the last; set
back: it goes on). The cap still counts the automatic and the owner's creates of 24 hours together, exactly
as today; lowering it below what is already used undoes nothing and only holds the next create until there
is room; `CreatesRoomAt` stays right.

**C. The run's flag** `-auto-mirror-new-per-day` stays and means "for this run": its default becomes 0 ("not
given: the stored setting"), a given value (1 to 50) is used exactly for the run, and the help's paragraph and
the start's line that states the cap say which is in force. While the run has the flag the set door refuses
in fixed words (as `ErrAutoNewByRun` does for the switch): a stored value that silently does not apply would
be worse than a refusal.

**D. The doors for pages (in `mirror_door.go`, catalogue only, no request):**
`MirrorNewPerDay(ctx) (MirrorNewPerDayFacts, error)` with `PerDay` (in force now), `Stored`, `Default` (20),
`Min`, `Max`, `Unreadable`, `Settable` and `Why` (fixed words when the run's flag holds it), and
`SetMirrorNewPerDay(ctx, n int) error` (range and by-run refusals as sentinels in `words.go`, one line). The
mirror page's per-account numbers (`CreatesDay`, `CreatesCap`: `livepages/mirrors.go` reads them; that file is
pages', do not touch it) must show the value in force through the existing path.

**E. Not changed:** the look's cap of 10 chats (it does not bind at 20 a day; rule 10 keeps a cap per step);
the 500 guard; the pause, the bound per hour, every wait.

**F. Two small things from pages' review of its switch (the board's message 128 a), in the mirror's files:**
1. The comment on `SetMirrorAutoNew` says a written "on" costs one chat-list request per page of the
   account's chats. Also true and missing: the first chat list with the automatic mirror set up in the
   process brings the topic lists of the approved forums with it (`topicsDue` in `mirror_auto.go`:
   `autoTopicsAt` is 0). Put the comment right (words only; no behaviour changes).
2. A set-up that fails for another reason than the missing secret is only logged: `MirrorTask.Why` does not
   carry it, so the page can only say "the program's log says why". Give the task a fact for it in fixed
   words (the kind of failure as the log's fixed word, nothing of the owner's data), set while the last
   set-up try of the account failed and cleared when one succeeds; a test for both.

## 4. Tests, and what you run
Each rule of A to D and F2 gets a test that fails without it: nothing stored (20); a stored value in force at
the next turn without a restart; out of range and garbage refused by the set door; an unreadable stored value
(5, said once, never 20); the flag for this run (used exactly; the door refuses; the facts say why); the
owner's want bounded by the same number as the task; lowering below the used count. **Existing tests that
expected 5 as the default:** change the number where the test is about the default, pin the flag where the test
is about something else; list each in your report; remove or rename none.
Named runs only, through `go1.sh`, each with its `-timeout`: your new tests, the mirror package's tests that
name the cap, the collector's door and automatic tests you touched, `gofmt -l` and `go vet` on
`internal/mirror` and `internal/collector`.

## 5. Files
Yours: `internal/mirror` (a new file for the setting, or beside the interval's in `autonew.go`; `auto.go`,
`door.go`), in `internal/collector`: `mirror_auto.go`, `mirror_door.go`, their tests, the `-auto-mirror`
paragraph of `command.go`'s help, one line of sentinels in `words.go`. **Nothing else** (not `reader.go`,
`account.go`, `collector.go`, nothing of pages: `internal/server/demomirrors.go` shows an invented 5 and is
theirs: name it in your report). If a rule needs a line elsewhere, stop and name the line.

## 6. The hand-back
`archiver/docs/progress/mirror-cap-REPORT.md` on the branch: what is built, part by part; every departure
with its reason; the tests added (count), changed (each named with why), removed (0); the runs with their
"exit" lines and seconds; whether any code that runs concurrently changed (a new field shared between the
pages' goroutines and the task: say which, for the race run's list); what is NOT verified. One commit per
part, the branch pushed, the copy clean. After it: my read, a narrow independent review, its fixes by you,
the full runs once.
