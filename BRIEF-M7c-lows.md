# Brief M7c: two low findings of the second review pass, then the piece is listed

Written 2026-11-15 21:36 by the mirror session (M3). Same copy, branch and rules as before (`wt-mirror-timing`,
`wip/mirror-timing`, from its head 36b9c7d). The second pass is the section "Second pass (36b9c7d)" at the end of
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review9-scratch\REVIEW.md` (read N1, N2 and N4 there; its
probes are `zz_m9b_test.go` beside it). Its verdict: F1, F2, F4 and F3 fixed, part A byte for byte as it was,
nothing sooner in over 220,000 probed cases; the piece may be listed. Two lows are closed first, because one
of them is words the owner reads. **Nothing else changes: not part A, not the gathering's rule, not its bounds.**

## N1: a held batch keeps the young rule's wake too
`autoBatch` returns the gathering's moment as the only wake time when it holds the batch, and drops `youngAt`.
When a young message (an album's later half, say) becomes old enough before that moment and carries an earlier
post date, the batch could go then, and the task learns it only at the reader's next idle turn (the reviewer's
`TestM9bHeldWake`: +361 s following the wakes, +300 s with a turn every 5 s). Never sooner than allowed: later.
**Fix:** when the gathering holds, the wake time is the earlier of the gathering's moment and `youngAt` (when
`youngAt` is not zero). One named test, the reviewer's probe as `TestMirrorAutoGatherHeldWake`: following the
wakes alone, the batch goes at the first moment the rule allows; and no turn is woken more than once for the
same moment (no loop: count the turns).

## N2: the printed words say only what the code does
`mirror -gather`'s cost lines and `mirror -timing` (and the same sentences wherever they are repeated: the
flags' help, `run -h`'s paragraph, the note line, `timing.go`'s head comment):
- Not "forwarded at the latest N plus its random part after it was posted". Say what decides and what else can
  hold it: a batch goes once its earliest-posted message is N minutes old, plus a random part of at most P;
  an album still arriving, the pause between the account's writes, a wait Telegram stated and the bound per
  hour can each hold it longer.
- Not "a message deleted within N minutes of its post is not saved". Say: a message deleted at its source
  before its batch goes is not saved in the mirror; with a gathering that can be as long as N minutes plus P
  after it was posted (a message that shares a batch with older ones goes sooner).
- One line more in `-timing` and `-gather`, for N4 (the rule as written): while a chat's history is still being
  forwarded, new messages go with it and are not gathered.
The command tests follow the words.

## Left, and said in the report as known
F5 (a gathering mirror counted "caught up"); N3 (the older rig stores histories with no sighting time: it no
longer hides anything about the gathering).

## Running things, hand-back
Named tests while working. Once at the end: `go test ./internal/mirror -count=1`; `go test ./internal/collector
-run 'Mirror' -count=1`; gofmt on the changed files; `go vet` on `./internal/mirror` and `./internal/collector`.
The report gains a short section "M7c". Commit, push, the copy clean, nothing running. Final message under 15
lines: the pushed head, the two points, tests as counts and seconds, anything you did not do.
