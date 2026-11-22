# Brief M10e (FINAL, 11-16, the mirror session M5): M10's last small round

**For the coder of M10. Same copy (`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-autonew`, branch
`wip/mirror-autonew`, head ef7199b0), same house rules and limits as the earlier briefs, with two files added
to what you may edit, for the lines named below only: `internal/collector/account.go` (L3) and
`internal/collector/collector.go` (L2).** One commit per point. Do not merge the main head. Read first the
section "Second pass (ef7199b0)" at the end of
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review13-scratch\REVIEW.md` (read-only): its verdict is "may
be listed after two fixes" (A and B there: L1 and L2 here); every first-pass finding is closed.

- **L1 (second pass A, confirmed: the line said 25 times in two minutes of the clock, "since" moved again
  and again). Under the run's flag "since" is moved at most once a run per account.** `autoSetUp` calls
  `autoSince(..., flag)` from every `autoLook` that tries a failed set-up again. The flag's move (a stored
  "off" not older than "since", or a row that cannot be read) happens in the first `autoSince` of the run
  for that account whose transaction commits; later calls in the same run read "since" and move nothing; the
  line is said once. Keep it one transaction. Test: the reviewer's case (the flag, the stored switch row
  unreadable, the baseline row unreadable, so that the set-up fails every turn): "since" is written once,
  the line said once, over two minutes of the clock; and the existing F3 tests unchanged.
- **L2 (second pass B). "0 means: use the stored setting", in place of "exactly 30 minutes means it".**
  `Config.AutoListEvery` zero: the stored setting (default 10 minutes, with its random part); any other
  value: exactly that value, no random part (the tests' override, and a deliberate 30 minutes is then 30
  minutes). For it, in `collector.go`: take out the line that fills the default (`def(&c.AutoListEvery,
  mirror.AutoListEvery)`, about 345) and bring the field's comment (about 271) up to this; nothing else in
  that file. Your `listRig` sets 0. Test: a `Config.AutoListEvery` of exactly 30 minutes is used as 30
  minutes; zero uses the stored value. Every existing test that sets the field passes unchanged.
- **L3. The two marks are fields of the account, not package-level maps.** `badSaidAtStart` and
  `listNowMarks` become two `atomic.Bool` fields beside `autoReady` in `account.go` (the mirror's own lines
  there; a one-line comment each), with exactly the behaviour they have now; no package-level state stays.
- **L4 (second pass C: a plant survived). A test for the door's "off" clearing a mark not yet used:** set
  up; then from the page off, on, off with no task turn between (your `turnGate`): no chat list is asked
  after the last "off" (the fake's chat-list requests do not grow). It must fail when the clear is taken
  out.
- **L5 (second pass E). `heldApprove` goes:** no path reaches it (an owner's new want is on record before the
  approval runs), so no test can hold it. Keep `heldResume` exactly as it is. If you find a path that does
  reach it, keep it, name the path and add its test instead.
- **Left as they are, to be written under "Known" in the report:** the one-list mark is used up without a
  list when the chat-list method is frozen or the account is signed out (the safe side); a list that meets
  a wait may be followed by the usual next list when the last recorded one is older than the interval (the
  usual rule, not the mark); an "on" and an "off" from two goroutines at once can leave one mark (one list
  at most); the account's own refusal does not end held reads.

## Hand-back
A section "M10e" in the report: per point what changed, its test and the line taken out to see it fail; the
commands and "ok" lines; test functions removed or renamed against dbca91d4 (expected: none). The named runs
once at the end, as last time (the two collector runs, whole `./internal/mirror/`, gofmt and vet on the two
packages; the PC measured before each: over 80% CPU or under 2 GB free means wait, also for a short run).
Then your last message: the head's short hash, pushed, the counts, every departure.
