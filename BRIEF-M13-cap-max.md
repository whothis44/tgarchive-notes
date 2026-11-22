# Brief M13: the cap on new mirrors in 24 hours without the upper bound of 50 (session M-6, 11-16)

**For one Opus coder (high effort).** Branch `wip/mirror-capmax`, its own copy `wt-mirror-capmax` (cut from the
main head, which holds M12). A very small piece: one bound, its words and its tests. No schema step, no
`go.mod` change, nothing against Telegram. Hand back commit-ready work on that branch, pushed to `private`
(never the main branch, never `origin`).

**The rules (the project folder's `CLAUDE.md`, archiver section):** every go, gofmt and vet command goes through
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-mirror-m6/go1.sh <your copy's archiver folder> go test ...`
(a lock and a wait for the PC; never `go` directly); named tests only, each with `-timeout`; no whole run of
`internal/collector` or `internal/catalog`, no race detector; counts and fixed words only in log lines, test
names, commit messages and the report; you stop and say so first when a file outside the list must change.

## 1. What the owner said (11-16 17:58, to the integrator; the board's message 149 b)
"The daily mirror cap should be 20, but the maximum of 50 is dumb. It should be higher if needed,
configurable." It replaces the line of 13:34 ("1 to 50, the upper bound raised only after the first real run").

## 2. What the old app and the record already know
- The same as M12's brief (`BRIEF-M12-new-per-day.md` section 2: read it): the old app added up to 10 chats per
  half hour and the harm was choosing for the owner, not the rate; Telegram's one documented limit is 500
  channels and supergroups for an account, every mirror counting; one create has run for real (three
  requests, no wait); **what many creates in a day cost is not on record.** The owner has now decided the
  bound all the same; what keeps a high value safe is what was always there and does not change: every wait
  Telegram states is slept in full and lengthens the pause, one create at most a turn, the account's writes
  the pause apart, the guard at 500 channels, the look's cap of 10 chats.
- In the code (M12, on the head): `internal/mirror/auto.go` has `AutoNewPerDayDefault = 20`,
  `AutoNewPerDayMin = 1`, `AutoNewPerDayMax = 50`, `AutoNewPerDayCareful = 5`; `ChannelLimit = 500` is in
  `internal/mirror/mirror.go`; `newperday.go` checks, formats and reads the setting (`ErrNewPerDayRange` says
  "1 to 50"); the flag and its words are in `internal/collector/mirror_auto.go`; the doors' facts
  (`MirrorNewPerDayFacts.Max`) in `mirror_door.go`; the help in `command.go`.

## 3. What to build
- **The upper bound is what Telegram itself bounds: the account's limit on channels.** `AutoNewPerDayMax`
  becomes `ChannelLimit` (500: a larger number could never be reached, since every mirror is a channel of
  the account and the guard keeps the count under that limit). The default stays 20, the least 1, the careful
  value 5. The stored setting, the run's flag `-auto-mirror-new-per-day` and the set door all take 1 to 500.
- **No fixed "50" or "500" in words that a page or the owner reads:** the range refusal's words, the flag's
  usage line, the help's paragraph and the start's line take the number from the constant (so that the bound
  is said once, in the code); `MirrorNewPerDayFacts.Max` gives it to the page as it does today.
- **A stored value from 51 to 500 is valid** (read, in force at the next turn and plan); 0, 501, text and the
  other unreadable forms still give the careful 5 and the line. Say in the report, as known: a build older
  than this one reads a stored value above 50 as unreadable and uses 5 (fail closed).
- **Nothing else changes:** the look's cap of 10, the 500 guard, the pause, the bound per hour, every wait, the
  cost's words ("what many creates in a day cost is not on record" stays wherever it is said).

## 4. Tests, and what you run
Each with a test that fails without the change: 51 and 500 stored are in force (a rig run with the cap at 60
and 55 used: the 56th create goes); 501 refused by the set door and unreadable when stored (5 in force); the
flag at 500 accepted and at 501 refused at the start; the facts' `Max` is 500; the range words name the bound
from the constant. Existing tests that name 50 or 51 as the bound: change the number, list each in the report;
remove or rename none. Named runs through `go1.sh`: your tests and every test of M12 by name
(`TestNewPerDay|TestMirrorNewPerDay|TestMirrorDoorCap|TestMirrorAutoNewPerDay`) in `internal/mirror` and
`internal/collector`; `gofmt -l` and `go vet` on both.

## 5. Files
`internal/mirror/auto.go` (the constant), `internal/mirror/newperday.go` (the words), their tests;
`internal/collector/mirror_auto.go` (the flag's words), `mirror_door.go` only if a word there names 50, the
`-auto-mirror` paragraph of `command.go`'s help, their tests. Nothing else; `internal/server` and
`livepages` (pages' invented numbers) are not yours: name any "50" you see there in the report.

## 6. The hand-back
`archiver/docs/progress/mirror-capmax-REPORT.md` on the branch (short: what changed, every place a number
was named, tests added and changed with why, removed 0, the runs' "go1: exit N" lines, what is not verified).
One or two commits, the branch pushed, the copy clean. Final message to me, short: the head's 8-character
hash; tests added, changed (each named), removed (0); every run's exit line; anything not as written.
