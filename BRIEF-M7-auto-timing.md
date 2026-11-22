# Brief M7: the automatic mirror's timing varied, and "new messages at once, or gathered for N minutes"

Written 2026-11-15 20:26 by the mirror session (M3).
Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-timing` (branch `wip/mirror-timing`, cut from the main head
2625aa0, clean). Work only there, in `archiver/`. Commit as you go and push the branch to the remote `private`
(`git push private wip/mirror-timing`; never `origin`, never a tag, never another branch). Never touch another copy
(`repo-archiver`, `wt-mirror-name`, `wt-int-batch`, any `wt-*`). Never stash, reset or switch branches. Nothing is
run against Telegram. Invented data and the injected clock only. Anything you write holds counts, sizes and timings
only: a chat's or a mirror's name, message text, an id or a link never goes to a log line, an error, a test's output
or a commit message. New log lines use constant format strings. No schema step. No goroutine, lock or channel.

## What the owner asked (11-15 18:52, after the test mirror completed)
How often the automatic mirror fires, whether a chat with 20 messages left waits for 80 more, and: "can it do it
automatically on a timer, but variable to avoid looking like a bot". Listed on the board for this track: a bounded
random part on the pause and on the 90 s a message must be old, never shorter than today's values and never under
a wait Telegram stated; and a setting "new messages go at once / gathered for N minutes", at once the default (the
mirror exists so that items are saved before they are deleted). It must not slow the first save more than its own
small bound says.

## What is there today (read by me on 2625aa0; check each before you build on it)
- `internal/mirror/auto.go` `Turn`: at most one request a turn for the account, never a sleep: every bound is a
  not-before time; the earliest is returned as `TurnResult.NextAt`, and the collector's reader wakes at it
  (`collector/mirror_auto.go` `autoIdle`: the reader's idle is a minute, or until `NextAt`, never under a second).
  Nothing of the bounds is kept in memory: each is read from the catalogue every turn.
- **The pause:** `autoPause` gives the pause in use (the flag `-auto-mirror-pause`, default 20 s, or the stored,
  lengthened one, never shortened; `pause.go`); `Turn` reads the account's last write (`MirrorLastWriteAt`, whole
  seconds), and `pauseAt = lastAnswerFrom(last) + pause` (`pace.go` `waitLeft`, rounded up to whole seconds) is the
  not-before of the next create or forward (`createAt`, `forwardAt`), each combined with Telegram's recorded waits
  by `later(...)`. After a wait Telegram states, `autoLengthen` doubles the pause and stores it.
- **The 90 s:** `AutoYoung`. `autoBatch` takes the source's oldest candidates and cuts before the first one whose
  time (`MirrorMessageTimes`: the later of its Telegram date and the account's first sighting) is newer than
  `now - AutoYoung`; that message's whole album waits with it; `youngAt` = its time + 90 s + 1 s is a wake time.
  The reason for the 90 s: an album still arriving must never be split.
- **No wait for a full batch:** whatever is older than 90 s goes, 1 message or 100. No variation anywhere.
- The test fake (`auto_test.go` `autoInvoker`, `noBreach`) already fails a test when two writes are closer than the
  pause in use or a request goes inside a stated wait. Keep it; it is the "never shorter" guard for the pause.

## What the old app and the record already know (read by me; nothing here is to be rediscovered)
- **The old app never forwarded and never created a chat** (its "auto-forward" uploads the file again, one at a
  time; FEATURES 12 fourth round). It has no pause between forwards to port.
- **Its one random timer:** `wt-v12.31/core-service/internal/app/forward.go` `recheckDelay`: a refused destination
  is checked again after 1 h, 6 h, 24 h, each times a factor between 0.9 and 1.1 (`math/rand`). It is the base
  app's code; no number on record says why, or that it mattered. Note that it may go SHORTER than its base: ours
  never does. Its automatic count-and-add (12.30) ran on a fixed half hour, 10 chats at most each time; no
  refusal by Telegram is on record for that fixed pattern (86 counts in under 2 minutes, none refused).
- **The numbers on record for forwards** (TELEGRAM-FACTS 11, one account, one day, "looks like"): at a pause of
  10 s the fourth request was told to wait 9 s (after 300 messages in about 5 minutes, 200 of them in 13 s); at
  20 s, 352 messages in four batches and 34 before them went without a wait. "The pause between requests looks
  like what matters, not the count." Hence the default of 20 s: it is a floor here.
- **No number anywhere says that varying the timing lowers any risk.** I searched the lessons files, the answers
  files, TRIED-BEFORE, TELEGRAM-FACTS and WINDOW-EVIDENCE for it: nothing. So this piece is judged by two things
  only: it never sends sooner than today's code would, and it does what the owner asked. Your report claims
  nothing about risk or about speed.
- **The lessons that bind it** (TRIED-BEFORE 24 and 25, the 13 rules; the six mirror reviews in
  `archiver/docs/review`): the "never" mark is read before every request (unchanged: `autoCheck` stays in front);
  Telegram's waits are stored and checked first; a stored value that cannot be read never reads as the default
  (fail closed); one request a turn; nothing repeated by itself; "a switch nobody flips in time helps nothing"
  (so the variation is on by default, with one switch to turn it off). The reviews found, four times, a rule
  that every test passed without: each rule below gets a test that fails when its line is undone.

## Part A: the random part (new file `internal/mirror/timing.go`; small call sites in `auto.go`)
**It must be the same number every time it is asked for the same thing.** `Turn` is called again and again before
a time is reached; a number drawn afresh each turn would let the earliest draw win and pull the times toward
their floor. So the random part is a pure function of a key and of what it is for, never a draw kept in memory
and never stored:
- `type Vary func(what string, account, a, b int64) float64` (a number from 0 up to but not 1), and
  `NewVary(key []byte) Vary`: HMAC-SHA-256 of a fixed label, `what` and the three numbers under the key, its
  first 8 bytes scaled. The collector gives it the forward secret it already holds (`Config.AutoMirrorSecret`, 32
  bytes), so the same pending time is the same after a restart. `AutoDeps` gains `Vary` (nil: no random part,
  exactly today's times: every existing test of `internal/mirror` stays as it is, unedited).
- `AutoOptions` gains `Steady bool` (`run -auto-mirror-steady`, off by default: "no random part, the fixed times";
  for a comparison run). `Turn` varies only when `d.Vary != nil && !o.Steady`.
- **The pause:** the not-before of the account's next write becomes last answer + pause + extra, where extra is
  whole seconds from 0 to `min(pause/2, 60 s)` inclusive, `what` "pause", keyed by the account and the last
  write's second. The pause in use (the base) is what `autoLengthen` doubles and stores and what the fake's guard
  compares: the random part is never stored and never doubled. A larger pause with the same key gives a larger
  or equal extra.
- **The 90 s:** a candidate is young while `now` is before its time + `AutoYoung` + extra, extra whole seconds from
  0 to `AutoYoungSpread` = 30 s inclusive, `what` "young", keyed by the account, the source's catalogue chat
  number and the message's album id when it has one, else its message id (an album's members share one time).
  `youngAt` is that varied time (+ 1 s as today). The cut stays "before the first young candidate, with every
  album any later candidate belongs to": oldest first and "an album is never split" must hold exactly as today.
- Never shorter, by construction: extra is never negative; the stated waits are separate not-before times that
  the random part never touches (`later(...)` stays; the forwarder's own `held` check stays).
- Constants with their reasons in comments; the three numbers above are mine, not Telegram's: say so there.

## Part B: "new messages at once, or gathered for N minutes" (a stored setting; `timing.go`)
- One settings row, key `mirror.auto.gather`, catalogue-wide (the owner sets it once; the pages track will put
  it on the Settings page). Absent: at once (today's behaviour, the default). Stored: whole minutes from 1 to
  1440. Follow the shape of the name rule's doors on the branch `wip/mirror-name` (read it with
  `git show wip/mirror-name:archiver/internal/mirror/name.go`; do NOT merge that branch): exported
  `GatherKey`, `CheckGather(minutes int) error` (fixed words fit for a page), `FormatGather`, `ReadGather(ctx,
  Settings) (minutes int, stored bool, err error)`, `SetGather(ctx, Settings, minutes int) error` (0 writes "at
  once" explicitly), `ErrBadGather`. A stored value that does not read back byte for byte as one of the two
  forms is `ErrBadGather`, never "at once".
- **What gathering does in `autoBatch`:** with N minutes set, the mirror's OLDEST candidate must be N minutes old
  (its time as today, + a random part of whole seconds from 0 to `max(30 s, N/4)`, `what` "gather", the same key
  as the young rule) before anything of that mirror goes; until then the batch is empty and the wake time is
  that moment. Once it is, the batch is cut exactly as today (every candidate past the young rule, at most the
  server's maximum, albums whole). So: a backlog (a joined chat's history, messages put back by a settle) goes
  without any gathering, because its oldest candidate is old; a live chat sends about one request per N minutes
  with everything that arrived meanwhile; the owner's 20 last messages never wait for 80 more under either
  value. No create is spent while the only candidates are being gathered (the existing "nothing to forward yet:
  no mirror is spent" path).
- **Fail closed:** `Turn` reads the setting once, with the account's other bounds and before any request; on
  `ErrBadGather` it returns the error (nothing is sent for the account this turn; no want is blocked or marked;
  the collector's existing `fail` says "the record cannot be read" once and tries again each minute, and says so
  when it reads again). Add the error to the collector's fixed error words (`internal/collector/words.go`, one
  line, beside `mirror.ErrBadPause`).
- **The owner's command** (`internal/collector/mirror_cmd.go`: flags and one call only; the code in a new
  `mirror_timing_cmd.go`): `mirror -timing` shows, read-only, numbers and fixed words: the setting in force (at
  once, or N minutes), the pause in use for the account and its random part's bound, the 90 s and its bound, and
  whether a stored value cannot be read. `mirror -gather N` (minutes; 0: at once) shows the same, says in fixed
  words what gathering costs ("a message deleted at its source within N minutes is not saved in the mirror"),
  asks yes, writes (catalogue only, nothing sent, under the collector's lock as every writing mirror command).
  Not yes or the input ended: nothing written. Refused with fixed words beside `-chat`, `-settle`, `-never`,
  `-allow`, `-list` and their flags: never dropped silently. The owner's own `mirror -chat N` is NOT gathered
  or varied: it is the owner's action at the keyboard (`step.go`, `pace.go`, `pause.go`'s plan: no change).
- `run`: the flag `-auto-mirror-steady` in `addAutoMirrorFlags`; `autoMirrorNote` and the `-auto-mirror`
  paragraph of `run -h` (`command.go`, that paragraph only: it says "A message newer than 90 seconds is not
  forwarded yet") say the times as they now are, each number with what it counts; the collector's `autoTurn`
  hands `Vary` to the deps.

## What it will meet when M5 lands (`wip/mirror-name` fb8ab31 merges before this piece; do not merge it now)
M5 changes, in `auto.go`: two lines of `AutoLedger` (`BeginMirrorCreateBy` gains a rule; `MirrorBatchPutBack`
added); a constant `AutoEvNameRule`; `AutoNumbers.CreatesHeld`; three fields at the end of `turnCtx`; **a block
that reads the name rule right after `autoPause` and right before `var pauseAt`**; a hold before
`if !t.st.HaveLimits` in `mirrorTurn`; `autoCreate`'s signature; the repeat case in `settle`. In
`collector/mirror_auto.go`: one case in `sayTurn`. In `mirror_cmd.go`: new flags (`-name-rule`, `-name-prefix`,
`-name-sep`, `-rename`, `-to`) and one more refusal in the `-never`/`-allow`/`-list` branch. So: keep your lines
in `auto.go` few and away from those places where you can (read your setting after the hour's rows, not between
`autoPause` and `pauseAt`; the logic in `timing.go`), add your flags in one block of their own, and list in the
report every hunk of yours that touches a line M5 also touches. The merge of the new head into this branch is a
later round, not yours now.

## Not in this piece
The owner's `mirror` command's own pause between batches; the chat list's interval (the reader's); the setting's
page (pages); refusing a protected chat and the second review's six low findings (after M5 and K4 merge);
adopting an existing chat; forums. `reader.go`, `account.go`, the engine, `internal/telegram`, the catalogue's SQL:
no change; if one seems needed, stop and say why.

## Files you may edit
`internal/mirror`: a new `timing.go` and its tests, `auto.go` (the call sites), `auto_test.go`'s rig (a way to
hand it a `Vary`; existing tests' expectations unedited). `internal/collector`: `mirror_auto.go`, `mirror_cmd.go`
(flags and one call), a new `mirror_timing_cmd.go`, `words.go` (one line), `command.go` (the one paragraph), the
collector's mirror tests and their rig (it may run steady so that existing tests keep their times: say so in
the report). `docs/progress/mirror-timing-REPORT.md` (new).

## Tests (named; the injected clock only, never real seconds; each rule's test seen to fail once with its line undone)
`internal/mirror`:
- `TestMirrorTimingVary`: the same inputs give the same number; over a few thousand invented keys every extra
  is inside its bound and whole seconds, both ends of the bound are reached, the numbers are not all equal; a
  larger pause under one key never gives a smaller extra; another key gives other numbers.
- `TestMirrorAutoTimingSameEachTurn`: many turns before the varied time: the same `NextAt` every turn, no
  request; one request at it.
- `TestMirrorAutoTimingPause`: a backlog of several batches: every gap between two writes in the fake's log is
  at least the pause in use and at most pause + its bound + the turn's own second; the gaps are not all equal;
  `noBreach` holds.
- `TestMirrorAutoTimingYoung`: a live message is not forwarded before 90 s and is forwarded by 90 s + 30 s (+ the
  turn's seconds); an album arriving in two halves is never split (the existing halves test, with `Vary` on).
- `TestMirrorAutoTimingUnderWait`: a recorded wait that ends after the varied pause: nothing before its end; a
  wait stated on the turn's own request: the pause is doubled and stored as today (the stored value is the
  doubled BASE), and the next write is not before the wait's end nor before the doubled pause.
- `TestMirrorAutoTimingSteady`: `Steady`, and a nil `Vary`: today's exact times.
- `TestMirrorGatherSetting`: the check's edges (0, 1, 1440, 1441, negative), a stored value read back byte for
  byte, three unreadable forms.
- `TestMirrorAutoGatherHolds`: N = 5: a live message is not forwarded before 5 minutes; then one request carries
  it and every later message past the young rule; a message newer than that stays; the wake time is the
  gather's moment. `TestMirrorAutoGatherBacklog`: a joined chat's history and messages put back by a settle go
  without waiting. `TestMirrorAutoGatherAlbum`: an album across the gather's edge and across the young cut is
  whole or absent. `TestMirrorAutoGatherNoCreate`: no create while the only candidates are being gathered.
  `TestMirrorAutoGatherUnreadable`: no request, the error, no want blocked or ended; written anew: it goes on.
  `TestMirrorAutoGatherNeverMark`: a chat marked "never" while its messages are being gathered ends before any
  request.
`internal/collector`: `TestMirrorCommandTiming` (shown; read-only), `TestMirrorCommandGather` (yes writes; not
yes and an ended input write nothing; the refusals beside other flags; nothing dialled), `TestMirrorAutoRunSteadyFlag`
(the flag reaches the task; the note line's words), and one run of the automatic mirror in the collector's rig
with `Vary` on that forwards a joined chat whole (no breach of the fake's rules). No name, text or id in any
printed line (the package's privacy test pattern).

## Running things
In Git Bash: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then ONE go command at a
time with `GOGC=25 GOMAXPROCS=1` and `-p 1`. Before every go command measure the PC (PowerShell:
`(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory` in KB, and the CPU load): under 2 GB free or over
85% CPU, wait and measure again; never start a second go process. The first go command compiles everything once
(a few minutes). While working: named tests only (`-run`). Never: a whole run of `internal/catalog` or
`internal/collector`, the race detector, Docker, `go vet ./...`. Anything likely to take over 2 minutes runs in
the background and you wait for it; nothing is left running at the hand-back. Once, at the end:
`go test ./internal/mirror -count=1` (about 100 s); `go test ./internal/collector -run 'Mirror' -count=1` (about 3
minutes); `go test ./cmd/tgarchive-collector -count=1`; `gofmt -l` on the changed files; `go vet` on
`./internal/mirror` and `./internal/collector`. Scan the files you wrote for bytes below 32 other than line ends
and tabs at a line's start (a tool fault has put control bytes into text here before): none may remain.

## Report and hand-back
`archiver/docs/progress/mirror-timing-REPORT.md`: per part, what changed (file, function) and its tests; how each
rule's test was seen to fail; every line changed outside the files listed above; every hunk that touches a line
M5 also touches; concurrent code (none expected); departures from this brief; doubts; what was not verified.
Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no archive numbers, no names; push to `private`. The
copy clean at the end. Final message to the architect, under 40 lines: the pushed head; one line per part; tests
as counts and seconds; concurrent code; departures; doubts.
