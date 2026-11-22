# Brief M13b: the review's fix round for M13 (session M-6, 11-16)

For the same coder, in `wt-mirror-capmax` on `wip/mirror-capmax` from 6ca8b178. The independent look
(`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review16-scratch\REVIEW.md`: read it; its probes are beside
it, read-only for you) says "may be listed after these fixes": the change itself is right (caps from 51 to 500
hold, 501 and every unreadable form give 5, all three planted changes caught); one medium finding that is not
on a line of your commit, and two low. One commit per fix, each with a test that fails without it. The rules
of `BRIEF-M13-cap-max.md` hold (every go command through `go1.sh`; named tests with `-timeout`; no whole
package; privacy; stop and say so when a file outside the list must change).

- **F1 (review M1, medium, confirmed): the guard at the account's limit on channels must hold for the task's
  own creates too.** `WhyAt500` lives only in `MakeRunPlan` (the page's plan, the owner's yes, the command);
  the automatic task's turn never reads the channel count. With the count on record at 500 the reviewer's
  probe saw 4 creates sent for 4 automatic wants: each would be refused by Telegram, block its want and count
  against the cap, and with the cap's bound now 500 that is up to 500 refused creates a day. **My brief was
  wrong to count on the guard there: it did not exist for the task.** Rule 9 of TRIED-BEFORE 24: no request
  for an item that will never be acted on. **Build:** in `Turn` (`internal/mirror/auto.go`), before a create
  is decided, the account's channel count is read once a turn by the same reading the plan uses
  (`MirrorChannelCount`, or whatever `MakeRunPlan` asks: one source for both); while it is at or above
  `ChannelLimit`: no create is sent in that turn, NO want is blocked or ended by it (they go on once a channel
  is left: the count is read again every turn), forwards into mirrors that exist go on as ever, and the turn
  raises one event in fixed words with the count ("the account holds N channels, the most an account may:
  no mirror is created until one is left"), which the collector says once per time it becomes true (the form
  of the cap's "cannot be read" line: said again after it was false in between). A count that cannot be read
  is an error of the turn (no create), as the cap's read is. The door's facts for the pages already carry
  the count against the limit (`Channels`, `ChannelLimit`): nothing new there. Tests: the reviewer's probe
  taken over (count at the limit: 0 creates over several turns, no want blocked, forwards still go, the
  line once); one below the limit: 1 create; back under the limit after being at it: creates resume and the
  line is said again at the next time.
- **F2 (review L1, low, confirmed): the room after a lowered cap in one read.** `createsRoom` walks the creates
  one read at a time when the cap was lowered (501 reads, 363 ms with 500 creates on record, at every turn
  and plan until room returns). One sorted query with an offset in the catalogue (the mirror's file where
  `MirrorCreatesSince` lives: the time of the k-th newest create that counts, the same starters and the same
  24 hours) gives the same answer in one read. The answers must be exactly today's: the reviewer's nine
  `createsRoom` cases as a test (take them over), and one at 500 creates with the cap lowered to 1 that
  counts the reads (2 at most).
- **F3 (review L2, low): the range words cannot drift.** `NewPerDayRangeWords` becomes a function (or an
  unexported value behind one), so nothing outside the package can change what the refusal, the flag's usage
  and the help say.
- **F4: the report.** A section "M13b": the three fixes, tests added, runs; under "Known": what many creates
  in a day cost is not on record; a build older than this reads a stored value above 50 as unreadable (5).

**Files:** as before, and for F1 and F2: `internal/mirror/auto.go`, `internal/mirror/newperday.go` (or where
`createsRoom` lives), the catalogue's mirror file that holds `MirrorCreatesSince`
(`internal/catalog/schema_mirrorwant.go`: the mirror's own), `internal/collector/mirror_auto.go` (the line
said once), `words.go` only if a sentinel is added (one line), and tests. Nothing else.

**Runs:** your new tests, every cap test of M12 and M13 by name in `internal/mirror`, `internal/collector`
and (for F2) the catalogue's test of the new query; the mirror package's automatic-task tests that name a
create (`TestMirrorAuto` by name is fine: it is the package's own set, about a minute); gofmt and vet on the
three packages. Final message, short: the head's 8-character hash; each fix in one line; tests added
(count, names) and removed (0); every run's "go1: exit N" line; anything not as written here.
