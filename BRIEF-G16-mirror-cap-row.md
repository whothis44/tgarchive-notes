# Brief G16: the cap on new mirrors in 24 hours as a row on the Settings page (pages, P6, 11-16)

**The first rule of this folder, for you as for every session: routine steps are done in one go or by a
script, never one call at a time for its own sake.** You are one Opus coder. Work only in the copy and on
the branch your start message names (`wt-pages-cap`, `wip/pages-cap`). Never touch `repo-archiver` itself
or another `wt-*` copy.

## The owner's words
- 11-16 13:28, on G12's cost sentence: "Why are the caps so low? Can we adjust them higher, and make them
  configurable?" 13:34, on 20 a day by default: "Let's go with your recommendation for now".
- 11-16 17:58: "The daily mirror cap should be 20, but the maximum of 50 is dumb. It should be higher if
  needed, configurable."
So: the default is 20; the owner sets the number on the Settings page; **the upper bound is the mirror
track's to change (it is changing it now) and the page must follow with NO change of its own: every bound
the page shows, checks or says comes from the door at the moment of the answer, never from a constant or
from fixed words.**

## What the old app already knows (read by me: `TRIED-BEFORE.md` sections 24 and 25)
The old app's 12.30 added chats by itself, "at most 10 per half hour", and its first night's 30 added
channels flooded the queue (the owner: trash). No number exists for what a created channel costs: the
automatic mirror has never run against Telegram, no wait on a create is on record, and the one documented
limit is 500 channels and supergroups for an account without Premium, every mirror counting
(`mirror.ChannelLimit`, kept by a guard). Its independent review left 13 rules for anything that acts for
the owner; the ones this piece meets: **(10) a cap per step** (this row raises or lowers one: say its cost
before the click); **(13) fail closed** (a stored value that cannot be read is never "no cap" and never
the default: the door puts 5 in force and says so; the page shows exactly that and offers "store it
anew"); **(11) one row per item** (the door's; nothing for you). So the page ports nothing: it shows the
door's facts truthfully and adds no rule of its own.

## The doors, merged as M12 (`internal/collector/mirror_door.go`, about 741 to 816; read them whole)
- `MirrorNewPerDay(ctx) (MirrorNewPerDayFacts{PerDay, Stored, Default, Min, Max, Unreadable, Settable, Why}, error)`:
  `PerDay` is the cap IN FORCE now (the run's flag, else the stored value, else `Default`; while the stored
  value cannot be read: 5); `Stored` the value on record (0: none, or it cannot be read); `Settable` false
  with `Why` (`MirrorNewPerDayByRun`) in a run started with `-auto-mirror-new-per-day`.
- `SetMirrorNewPerDay(ctx, n int) error`: refusals, nothing written: `mirror.ErrNewPerDayRange`,
  `ErrNewPerDayByRun` (the collector's). Setting anew is allowed while the stored value is unreadable. The
  value holds from each account's task's next turn and from the next plan; no nudge.
- `MirrorTask.AutoSetUpFailed` (about line 52): fixed words while the account's last set-up try of the
  automatic mirror failed for another reason than the missing secret; "" otherwise.
- The per-account numbers the mirror page shows already (`CreatesDay`, `CreatesCap`, `CreatesRoomAt` in
  the plan, read in `livepages/mirrors.go` about 192) carry the value in force: nothing to do there.

## What to build
It follows the chat list's interval, built in G12, step for step: read that path first
(`server/mirrors.go`: `MirrorListEvery`, the seam's `ListEvery`/`SetListEvery`, `mirrorSettingsAnswer`,
`handleMirrorListEvery`, the route; `livepages/mirrors.go`: `DoorListEvery`, the seam's two methods, the
refusal table; `collector/pages_mirrors.go`: the wrapper; `web/assets/js/mirrorwords.js`: `listEveryView`;
`web/assets/js/pages/mirrorsettings.js`: `listRows`; `demomirrors.go`: the fake).

**A. The seam and the adapter.**
1. `internal/server/mirrors.go`: a type `MirrorNewPerDay` with JSON names (`per_day`, `stored`,
   `default`, `min`, `max`, `unreadable`, `settable`, `why`); the seam gains `NewPerDay(ctx)` and
   `SetNewPerDay(ctx, n int) error`.
2. `internal/collector/livepages/mirrors.go`: `DoorNewPerDay` (the collector's facts, field for field),
   the two methods on the door interface and on `mirrorSeam`; **`Min` and `Max` are handed through from
   the door's facts. Do NOT name `mirror.AutoNewPerDayMin`, `AutoNewPerDayMax`, `AutoNewPerDayDefault` or
   `AutoNewPerDayCareful` anywhere in `internal/server` or `livepages` (the mirror track is about to
   change or remove the upper one: a reference would break its merge).**
3. The refusals (the table in `livepages/mirrors.go`):
   - `mirror.ErrNewPerDayRange`: words WITHOUT a number of the page's own: when the set is refused for the
     range, the adapter reads the facts again and says "Not stored: new mirrors in any 24 hours are a
     whole number from MIN to MAX." with the door's numbers of that moment; when the facts cannot be read
     then, or `Max` is not above `Min`: "Not stored: the number is outside what the program takes; the
     row shows its bounds." (If the table's form cannot carry a refusal built at the moment, build it in
     the seam's `SetNewPerDay`; say in the report which way and why.)
   - the collector's `ErrNewPerDayByRun`: through the wrapper as a `livepages` sentinel, as
     `ErrDoorAutoNewByRun` is: "The program was started with -auto-mirror-new-per-day: the cap is set for
     this run and is not set from a page. Nothing was recorded."
4. `internal/collector/pages_mirrors.go` (Core's file with the pages' wrapper: LENT LINES, one commit of
   their own, named in the hand-back): `MirrorNewPerDay`, `SetMirrorNewPerDay`, as the two list-every
   methods beside them; and `AutoSetUpFailed` handed through where the task is converted.

**B. The route and the settings answer.**
5. `POST /api/mirrors/new-per-day` with `{"n": N}` (a missing or non-integer `n`: a field refusal, no
   door call, as `handleMirrorListEvery` does); behind the page token and the program's guard as every
   settings route; on success `settingsAnswer` with the row's "when" words; the kept task readings made
   stale exactly as the interval's route does or does not (say which, and why it is right: the plans'
   numbers change with the cap).
6. `mirrorSettingsResp` gains `new_per_day` (the facts), `new_per_day_when`, `new_per_day_cost`.
   **If the cap's door fails, the settings answer must not fail whole** (G12's review, point 4, found the
   interval's failure doing that): the answer carries the other settings and, for the cap, an error
   field the row shows as "cannot be read now"; no number is shown then and no button but none is needed
   either: say what you did.

**C. The words (constants in `server/mirrors.go`, pinned by tests; the scripts add none about cost).**
Each clause must be true of the code: check it against the door and `internal/mirror` and say in the
report where each fact comes from. Proposed, to correct where the code says otherwise:
- the row's state (built in `mirrorwords.js` from the facts, as `listEveryView`): in force and stored:
  "At most N new mirrors are created in any 24 hours (yours and the automatic ones together)."; in force
  by default: the same with " (the default)"; unreadable: an error box "The stored cap cannot be read: N
  is in force until it is stored again here." with the door's `PerDay` as N (never a constant) and the
  input empty; not settable: the state and the door's `Why`, the input and the button absent;
- `MirrorNewPerDayWhen`: "Stored at once; each account's mirror task reads it at its next turn and every
  plan from then on. Lowering it below what the last 24 hours used undoes nothing: the next create
  waits until there is room again.";
- `MirrorNewPerDayCost`: "Each new mirror is one request that creates a private channel of yours, and
  its chat's messages are then forwarded into it. What many creates in a day cost is not on record: the
  automatic mirror has not run against Telegram yet, and every wait Telegram states is slept in full.
  An account may hold a limited number of channels (500 without Premium, every mirror counting): a
  create that would pass it is not made." (Check the last sentence against the guard; drop what the code
  does not do.)
- **the switch's cost sentence (`MirrorAutoNewCost`)** takes the cap too: in place of "at most 5 new
  mirrors are made in 24 hours by default" it says "at most N new mirrors are made in any 24 hours (the
  cap in force: its row is on this page)", with the door's `PerDay`; when the cap cannot be read at all
  (the door failed): "new mirrors in any 24 hours are capped (the cap cannot be read now)". "at most 10
  are taken a look" stays as fixed words (the mirror's 130 a: that cap is a constant). Keep every other
  clause of the sentence byte for byte.

**D. The page (`mirrorsettings.js`, `mirrorwords.js`).**
7. A block "New mirrors in 24 hours" directly under the chat list's interval, in the same region: the
   state line, a number input whose `min` and `max` attributes and label ("from MIN to MAX") come from
   the answer (**no `max` attribute and "MIN or more" when the answer's `max` is absent, 0 or not above
   `min`**; the mirror track may come to say "no upper bound" that way: my board message asks; build it so
   either answer works), the button "Store the cap", the cost and the when sentences, the answer line.
   A non-integer or empty input: refused in the page with the bounds of the answer, no request. After a
   click the keyboard goes to the row's answer line, never to a button (G12's rule `focusAfterClick`).
   Strict reads, fail closed: a missing or non-number `per_day`: "its state is not in the answer:
   nothing is offered", no input.
8. **`AutoSetUpFailed`** through the task's answer (`auto_set_up_failed`, a string) and shown in
   `autoNewView` in the state "on: not set up yet": when it is not empty, the door's words stand in the
   place of "(when this stays, the program's log says why)" as ": not set up yet: <the door's words>; the
   mirror task tries again at its next turn"; when empty the words stay as they are. The Chats page's
   state line follows if it says the same thing (look at `chatmirror.js`'s line for the switch).

**E. The demo data and the invented numbers.**
9. `demomirrors.go`: the fake holds a cap (none stored: the door's default as the FAKE's own invented
   default, a named constant of the fake with a comment that it stands for the door's and is not the
   product's rule), an unreadable state and a "by run" state for tests, `SetNewPerDay` with the fake's
   own bounds; the plan's `NewPerDay: 5` becomes the fake's cap in force, so the mirror page and the
   Settings row of the demo agree. Tests that pin "1 of at most 5" and "the bound of 5 new mirrors"
   (`mirrors_test.go` about 837 and 904) follow the fake's number: keep what they test.
10. `livepages/mirrors_test.go` (`CreatesCap: 5`): it tests a hand-through; give it a number that is
    neither the old default nor the new one, with a word in the comment.

## Tests (named; each new rule with the test that fails without it; say the mutation you tried)
- the route: a stored cap is read back in the settings answer; a refusal for the range carries the
  door's bounds of the moment (change the fake's bounds between two sets and see the words follow: this
  is the owner's "configurable" kept by a test); `ErrNewPerDayByRun`; a missing `n`; no door call on a
  bad body; the page token and the program's guard;
- the settings answer when the cap's door fails: the other settings still arrive;
- `MirrorAutoNewCost` with a cap of 20, of 137, unreadable (5 in force, from the facts) and unread;
- the adapter: every field handed through; no constant of the mirror package's cap in the two packages
  (a test that greps its own package's non-test sources for `AutoNewPerDay` and fails on a hit is fine);
- the wrapper in the collector (`TestPagesMirrors...` style): the two calls and `AutoSetUpFailed`.
- The two page scripts have no DOM harness: say plainly what of D is NOT verified by any test, and open
  the demo once (`go run ./cmd/tgarchive app -demo` or however the report of G12 opened it; a scratch
  port, invented data only, the process ended afterwards) to look at the row at two widths, set a value,
  see the refusal's words; say what you saw. Never open the owner's real folder or pages.

## Rules
- Files: `internal/server` (Go, the two scripts, tests), `internal/collector/livepages`, and the lent
  lines in `internal/collector/pages_mirrors.go` with its test. Nothing in `internal/mirror`,
  `mirror_door.go`, `internal/catalog`. Anything else: stop and say so.
- No test function removed or renamed. No schema step. No new exported door.
- One go command at a time, `-p 1`, named tests only, nothing over two minutes, no whole package, no race
  detector, no vet over packages (the full runs are made once after the review, by a script). Look at
  free memory before each go command; under 1.5 GB wait a minute and look again, at most five times.
  Go's environment: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in bash.
- Never a Windows path inside a shell string: the Write and Edit tools for files, `/c/...` in bash.
- Commit as you go and push to the remote `private` only: `git -c user.name=Claude -c
  user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Invented data only; no names, paths, ids or
  counts of anyone's archive anywhere. Leave no process behind.

## Hand back (at most 15 lines)
The pushed head; files with +/- lines; the lent commit's hash; test functions added and removed; the named
tests run and their result; the mutations tried; where the code made you change this brief's words; what
is not verified by any test; what you saw in the demo. A report as
`archiver/docs/progress/pages-cap-REPORT.md` on the branch.
