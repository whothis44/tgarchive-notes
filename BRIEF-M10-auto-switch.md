# Brief M10 (FINAL, 11-16 07:50, the mirror session M5): the switch "mirror chats I join by themselves", stored and set from a page; an account added or signed in while the program runs

**Your copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-autonew`, branch `wip/mirror-autonew`, cut from
the main head dbca91d4** (e4a4a61d with Core's K15 in `internal/store` and a roadmap line: no file of the
mirror's differs). The Go module is `archiver/` in the copy. You are the coder (Opus 5.5, high effort);
you hand back commit-ready work; the mirror session reads the risky part, an independent reviewer follows, the
whole runs and the race run are a clerk's afterwards: not yours.

**House rules (they bind every line):** one copy, yours; commit as you go
(`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message ending with the line
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`) and push only `wip/mirror-autonew` to the remote
`private`; never the main branch, never a merge of the main head. Nothing runs against Telegram: invented data,
the fakes and the injected clock only. No name, text, id, link or path of anybody's data in any log line,
error, printed line, test name or commit message; log lines use constant format strings and the catalogue's
numbers only. No schema step (a settings row needs none): if you find you need one, STOP and report. Files you
may edit: in `internal/mirror` a new file `autonew.go` with its test, and `door.go` only for part B2; in
`internal/collector` only `mirror_auto.go`, `mirror_door.go`, their tests and new test files of your own, the
`-auto-mirror` paragraph of `command.go`'s help, and in `account.go` only the comment of the field `autoReady`
and, if part A4 needs it, the one line that makes the monitor's sink (about 544). Read, never edited: Core's
`reader.go`, `collector.go`, `click.go`; pages' `pages_mirrors.go`, `livepages`, `internal/server`. The fields
`MirrorTask.AutoJoined` and `MirrorTask.AutoNewSettable` keep their names and types (pages' adapter reads them).
**Running things:** before every go command measure the PC (free memory under 2 GB or the CPU over 80%: wait
60 s and measure again, at most 10 times, then stop and report); `source
/c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, `export GOGC=25 GOMAXPROCS=2`; one go
command at a time; named tests only (`go test -count=1 -run '<names>' ./internal/collector/`, the same for
`./internal/mirror/`); never the whole `internal/collector` or `internal/catalog`, never the race detector,
never `go vet ./...` (vet only the two packages you changed, once, at the end, with `gofmt -l` on them). A
named run that has not ended after 10 minutes: stop it and report. Every wait in a test has a bound (the
injected clock, or a real timeout of at most 60 s).

## What the old app already knows (read by the mirror session itself; the numbers are the old app's)
- The old app has no mirror by itself; what it did by itself was add chats (12.30): every half hour it counted
  the chats it could see and added those with 20 media or more, at most 10 a half hour. It added 30 channels
  in one night; the owner could not recognise them, they took 1,571 of 1,575 startable files (615 GB), and by
  noon the owner had switched off 24 of the 30 by hand; 17,613 files (34 GB) had come from them
  (`LESSONS-ix12.30-live.md` 6b). The lesson for this piece: what the app does by itself stays visibly the
  app's and below the owner's choices, and the owner's "off" must work at once and stay off.
- The 13 rules for anything that acts for the owner (`TRIED-BEFORE.md` 24 and 25). The ones this piece meets:
  (1) never undo a person's stop; (3) a "never" or an "off" is checked again before every request; (9) no
  request for an item that will never be acted on; (11) one row per item (the old app lost 81 of 150 marks
  kept in one JSON list under two clicks at once): so one settings row per account; (13) fail closed: a
  record that cannot be read stops the automatic step and never reads as "empty" or as "on".
- "A switch nobody flips in time helps nothing" (TRIED-BEFORE 25): today the automatic mirror is a flag of
  the run; in the one program with its folder nobody types flags, so the switch must be on a page and stored.
- The new app's own numbers, unchanged by this piece: at most one writing request a turn for the whole
  account, 20 s between the account's writes (longer after any wait, never shorter), at most 5 new mirrors
  in any 24 hours, the chat list every 30 minutes while the automatic mirror is on. The automatic mirror has
  never run against Telegram (the owner's item 26).

## Why
Today (`internal/collector/mirror_auto.go`): `autoOn()` is `cfg.AutoMirror && autoReady`, and `autoReady` is
set by `startAutoMirror`, which runs once, in `Run`, over the accounts of the start. So (a) a page cannot
switch it (`MirrorTask.AutoNewSettable` is false), and (b) an account added or signed in while the program
runs gets no automatic mirror and no policy for new chats until a restart (the board's "Listed and unbuilt"
row; found by the sign-in page's review). Also, with the switch off, the chats the task took by itself
earlier are held (`AutoDeps.AutoWantsHeld`, `AutoOptions.OwnerOnly`) but the reader goes on reading their
history: requests for something that is not acted on (rule 9).

## What to build

### Part A1. The stored switch (`internal/mirror/autonew.go`, pure; modelled on `timing.go`'s gathering doors)
- `AutoNewKey(account int64) string`: `"mirror.auto.new." + the account's number`: one settings row per account.
- The stored value has exactly two forms, `on <unix seconds>` and `off <unix seconds>` (the second it was
  set, above 0). `ReadAutoNew(ctx, s Settings, account) (AutoNew, error)` with `AutoNew{On bool; At int64;
  Stored bool}`: absent: `{}` (off, not stored: the default stays `autoMirrorDefault`, false); a value in
  neither form: `ErrBadAutoNew` (fixed words), never off, never on; a failed read: the error.
- `FormatAutoNew(on bool, at int64) string` for the writer. No writer here: the write is the collector's (it
  shares a transaction with two keys of the collector's).

### Part A2. One function sets the automatic mirror up for an account, at the start and in the task
In `mirror_auto.go`. `autoOn()` becomes "the automatic mirror is set up for the account in this run and its
switch was on at the last look at it" (the atomic alone; the flag is no longer part of it: the flag is one of
the two things that make the switch on).
- **Whether the switch is on for an account, read fresh every time it is asked:** `cfg.AutoMirror` (the run's
  flag: "on for this run"; the stored row is then not read at all), else `ReadAutoNew`. Three answers: on,
  off, cannot be read (`ErrBadAutoNew`); a failed read of the catalogue is an error.
- **At the start (`startAutoMirror`, still before any account's task, for every account of the start):** what
  it does today, per account, with "the switch" in place of `cfg.AutoMirror`, through one function that part
  A3 calls too. Kept exactly: an off switch (or `-auto-mirror-download`) removes a policy for new chats an
  earlier run left; on and signed in: "since" stored at its first time (`autoSince`), the baseline read, the
  policy set when a baseline is on record and downloads are not asked, the `ChatsMadeUnreadable` line, ready,
  the line `autoLineOn`. Changed: (i) the forward secret is `cfg.AutoMirrorSecret` or the file
  (`hasForwardSecret()`); with none the account is not set up and the line says so, and the loop goes on to
  the next account (today it returns out of the whole loop: do not keep that); (ii) a switch that cannot be
  read: not set up, the policy left exactly as it is (fail closed: chats stay made switched off), a constant
  line once.
- `autoSince`'s comment: "since" is stored at the first set-up and moved only by the owner's switch from a
  page (part A5).

### Part A3. The task looks at the switch every turn (`autoTurn`, the reader task's goroutine)
After the returns for `autoHooksOff`, not signed in and `st.off`, and before `on := a.autoOn()` is taken (so
that the look and the turn of this very reader turn obey what was just read: no automatic request is ever
sent in a turn in which the switch was read as off or unreadable):
- on, and the account not set up in this run (added later, signed in later, or switched on from a page): the
  set-up of A2; then `lookDue`. A set-up that fails (no secret; "since" cannot be stored; the baseline cannot
  be read) leaves it not set up, said once a session, tried again at a later turn; the turn goes on for the
  owner's wants only.
- off, and set up: no longer set up; the policy for new chats removed as the start removes it; one constant
  line ("automatic mirroring is switched off for the account: nothing more is taken or sent by itself; the
  chats it took wait until it is on again"). From this turn on `OwnerOnly` is true and `AutoWantsHeld` true.
- cannot be read: as off, except that the policy for new chats is left as it is; a constant line once a
  session; the pages' facts say it (A6). When it reads again (the owner wrote it anew): said once, as
  `autoLineReadAgain` is.
- a failed read of the catalogue: the turn's own `fail(err)` (nothing is sent for the account this turn).
This costs one settings read a reader turn without the flag: fine. Keep `autoTurn`'s other lines as they are;
its existing tests pass unchanged unless one asserts the internals changed here (say which, and why).

### Part A4. What reads `autoOn()` when a session began before the switch
- `autoSink` decides once, when the session's monitor is made: with the switch flipped later the nudge would
  be missing until the next session. Make the wrapper always (not with `autoHooksOff`), and let
  `chatNudge.ChatChanged` set `lookDue` and nudge only when `autoOn()` is true at that moment.
- `chatListEvery`, `topicsDue`, `autoListed`, `accountDeps` (`AutoWantsHeld`), `MirrorTask` read it at call
  time already: check each still says the right thing, and say so in the report.
- **No chat list is asked because of a click.** After a set-up in the task the baseline comes from the next
  chat list the reader stores in its own time (`autoListed`; at most `AutoListEvery`, 30 minutes, after the
  last one once the switch is on). Do not make the list due sooner: that would be Telegram requests caused by
  a click, with no cost shown.

### Part A5. The door (`mirror_door.go`): `SetMirrorAutoNew(ctx, account int64, on bool) error`
Catalogue only; it sends nothing.
- Refusals, nothing written, each a fixed-word exported error: an account the collector does not have
  (`errNoSuchAccount`, as the other doors); an account not signed in on record (`mirrorSignedIn`: the track's
  guard against a reused account number; its unreadable answer is `errSignInUnreadable`); a run started with
  `-auto-mirror` (`ErrAutoNewByRun`: "the program was started with -auto-mirror: the switch is on for this
  run and is not set from a page").
- on: `makeForwardSecret()` first, as `MirrorWant` does (its error is returned, nothing written).
- One transaction (`cat.Batch`), reading the row first:
  - on asked, the row readable and on already: nothing is written (a second click must not move anything).
  - on asked otherwise (absent, off, or unreadable): the row `on <now>`; "since" set to now (overwritten);
    the baseline row deleted. **This is the rule that an off is never undone backwards (rule 1): chats the
    owner joined while the switch was off are never taken by a later "on": "from now on" begins again, and
    the first chat list stored whole after this moment is the new baseline.** The automatic wants already on
    record are not touched: they go on when the switch is on.
  - off asked, the row readable and off already (stored): nothing written. Otherwise: the row `off <now>`.
- After the commit: `nudgeMirror(account)` (the task looks at its next turn).
- Reading for the pages, added to `MirrorTask` (existing fields keep their meaning: `AutoJoined` is "set up
  and running for the account now"): `AutoNew bool` (the switch as it is in force: the flag, or the stored
  row on), `AutoNewSettable` (true unless the run has the flag), `AutoNewWhy string` (fixed words when not
  settable), `AutoNewUnreadable bool` (the stored row cannot be read: writing it anew through the door is
  the remedy, and is allowed), `AutoNewFrom time.Time` (the baseline on record: chats joined after it are
  taken; zero: none yet, it comes with the next chat list stored whole). `MirrorTask` reads the catalogue
  already: these are two or three more settings reads, no request.

### Part A6. The reads of chats the task took, while the switch is off (rule 9; its own commit)
When the task stops being set up for an account (A3: off or unreadable), and at an account's first look of a
run that finds the switch off: for every automatic want of the account that has not ended, the mirror's end
of the chat's read is written (`setReadEnd` through the existing closure of M11, its rules unchanged: the
owner's own record is never touched, a record that cannot be read is left and counted). At a set-up (A2 at
the start, A3 in the task): for every automatic want that has not ended, that end is cleared, so the read
goes on from its cursor. Each chat in its own small transaction, or all of an account's in one: your choice,
say which; an error stops the step and is tried again at the next look (the switch's state "applied" is only
recorded when the step went through). The owner's wants are never touched by this. If this part turns out to
need more than `mirror_auto.go` and its tests, STOP it there, leave it out, and say what it would need.

### Part B (small; each its own commit; only after part A's named tests pass)
- **B1.** `MirrorWantRead` and `wantApprove` in `mirror_door.go` carry the words "LENT LINES ... for the mirror
  track to take or replace": the mirror track takes them as they are. Reword the two comments (no "lent");
  no behaviour and no test changes.
- **B2.** `Plan.Token()` (`internal/mirror/door.go`) binds neither the account nor the chat (pages' second
  review). Read `fingerprint()` first: if it already holds both, change nothing and say so. Otherwise add
  the account and the chat to what is hashed, with a test: a token made for one chat's plan is refused
  (`ErrWantChanged`) for another chat and for another account whose plans are otherwise equal. The page
  treats the token as opaque: nothing of pages' changes.

## Tests (named; on the fakes; the rig of the existing `TestMirrorAuto*` and door tests)
Each rule below needs a test that fails when its line is taken out (the reviewer will plant such changes):
1. Without the flag and with the stored switch on at the start: set up before any task (the policy for new
   chats in force before the monitor stores a chat: the existing flag test's case, on the stored switch).
2. Switched on through the door in a running program: no request because of the click; after the next chat
   list stored whole, a chat joined later is taken and mirrored on the fake Telegram; a chat joined before
   that list is not.
3. Switched off through the door in a running program: after the off no look, no create and no forward by
   itself (the fake's requests counted before and after: at most the one request under way lands); the
   automatic wants are held; an owner's want of the same account is still carried out.
4. Off, then chats joined, then on: none of those chats is ever taken; one joined after the new baseline is.
5. On asked twice: "since" and the baseline are not moved by the second.
6. A row that cannot be read: nothing automatic is sent, said once, `MirrorTask` says unreadable, the policy
   for new chats is left, an owner's want is still served; a write through the door repairs it.
7. The run's flag: the door refuses with `ErrAutoNewByRun`, `AutoNewSettable` false with its words; a stored
   "off" under the flag: on for this run, the row untouched.
8. An account that signs in after the start (the flag on; and the stored switch on): it is set up at its
   task's first turn ("since" stored, the baseline at its first whole list), without a restart. Use the
   rig the sign-in page's tests use if it serves; if no rig can sign an account in mid-run within the files
   you may edit, say so and test the set-up function on an account marked signed in after `Run` began.
9. The door for an account not signed in, and for an unknown account: refused, nothing written.
10. Part A6: a held automatic want's chat gets no history request after the off (counted on the fake), and
    its read goes on from its cursor after the on; an owner's record is never touched.
11. B2's two refusals.
The whole existing `TestMirror*` set of the collector and `internal/mirror`'s tests are run once at your end
by name pattern (`-run 'Mirror|ReadEnded'` for the collector: about 15 minutes; measure the PC first), with
`gofmt -l` and `go vet` on the two packages.

## Report and hand-back
`archiver/docs/progress/mirror-autonew-REPORT.md` in the copy, committed with the code: what was built, part
by part, with file and function names; every place where you departed from this brief and why; the answers
asked above (A3: tests changed; A4: each reader of `autoOn()`; A6: one transaction or many; B2: what
`fingerprint()` holds); the exact test commands and their "ok" lines with seconds; the files touched; **the
test functions removed or renamed (expected: none; `git diff dbca91d4 -- . | grep '^-func Test'`)**; what
you did not do. Then your last message to the mirror session: the head's short hash, pushed or not, the
tests' counts, and anything it must read first. Do not start anything else.
