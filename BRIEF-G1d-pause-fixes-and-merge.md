# Brief G1d: the pause's review fixes, then the main head merged in (pages track, session P2; 2026-11-15)

For one Opus coder, in the copy `wt-pages-g1` on branch `wip/pages-g1` (head 0ee2c00, tree clean, pushed). The
rules of `BRIEF-G1-one-program.md` ("Rules (hard)") hold unchanged: new code in new files, the fewest lines in
`account.go` and `command.go`, named tests only, commits and pushes, the report, invented data only.

## Part 1: the independent review of the pause (`REVIEW-G1c-pause.md`: read it in full first)
All accepted by the main session.
- **F1 (must): a pause never shortens a pause that holds.** Today a pause for every account ("1 hour") writes
  over an account's "until I resume", which then ends by itself after the hour (the review's probe). In the
  collector, for every call (one account or all): when the account's pause holds, the later end wins and
  "until resumed" beats any end; a call that would shorten leaves the record as it is and its result says so
  per account ("already paused until HH:MM" or "until you resume": left as it is). To shorten a pause the
  owner resumes first. The page's toast and the header say what happened per account. Named test with the
  review's sequence on the rig or the probe's small collector: `TestPauseNeverShortensAPause`; a second for
  the page's words.
- **S1: a freeze or a sign-out the engine saw is acted on before the engine is thrown away.** In the first
  paused turn, before `stopEngine`, the engine's lanes are looked at as `engineTask` does each turn; frozen or
  signed out: the session is asked to end with that ending and the engine task returns as it does there. In
  `pausedl.go` if the return value of `pausedTurn` can carry it without more lines in `account.go` than one;
  say what you did. Named test: the fake refuses a part as frozen in the second before a pause: the account
  ends frozen, nothing more is sent.
- **S2: the Overview does not rebuild an account's pause menu every 2 s.** The Overview repaints by shape, as
  the Accounts page does, with the time left and the numbers updated in place; at the least the menu's summary
  keeps its key so the keyboard's place survives. A named test on what can be tested without a browser (the
  script's shape function, or a test on the answer that the shape does not change when only numbers do).
- **N1:** when a pause cannot be recorded over an older one on record, the words say that the earlier pause
  on record applies again at the next start. **N3:** `heldFor` is cleared when it is not this session.
  **N4:** a pause and Resume do not count the same lanes as added again. **N5:** when the accounts' ends
  differ the header says so and points at each account's own line; a refused Resume has its own words (not
  Start's); a call when the collector is not running answers 409 with fixed words, not 500.
- **N2 is left as it is** (a pause holds within a second of the clock; said in the report and on no page).

## Part 2: the main branch's head merged in
The main branch (`claude/charming-feynman-vm2xia` on `private`) is at 9dd5a21 and now holds the mirror track's
automatic mirror (be429e1: schema step 18; `mirror_auto.go`, `mirror_marks.go`, `mirror_settle_cmd.go`; changes
in `account.go`, `command.go`, `collector.go`, `reader.go`, `approve_cmd.go`, the fake Telegram, the
catalogue). **Merge it into `wip/pages-g1` as a merge commit** (`git fetch private`, then
`git -c user.name=Claude -c user.email=noreply@anthropic.com merge private/claude/charming-feynman-vm2xia`);
never a rebase, never a force-push. If the head has moved past 9dd5a21 when you start, merge the head that is
there and say which. A trial merge by the main session showed two conflicts, both in the lent files:
`archiver/internal/collector/account.go` and `command.go`; everything else merged by itself.
- Resolve both by keeping both sides' meaning: the mirror's lines as they are on the main branch, this
  branch's lines (the owner's Stop check, state and ending; the pause's turn; the pages' flags, bind and run)
  beside them. Change nothing of the mirror's behaviour. Quote each resolved conflict in the report (the two
  sides and the result).
- Then make it compile and hold together. What meets what (read the mirror's code before deciding):
  1. **The automatic mirror's task runs in the account's session.** With the owner's Stop it must end with
     the session and send nothing afterwards (a named test on the rig with the automatic mirror on: after
     Stop the fake counts no request of any kind for the account, forwards and reads included); with a pause
     of downloads it goes on (it moves no file bytes): a named test that says so.
  2. **`EstimateRead` and `ApproveRead` changed on the main branch** (who approved a read: the owner or the
     mirror). The page's approval is the owner's: make the pages' call say so the way the console's
     `-approve-read` does, and check the page's estimate and approve tests still mean what they say.
  3. **A chat row first made while the automatic mirror is on starts switched off** (the main branch's policy):
     the Chats page shows its "Collect" switch off and the row's sentence must be true for it; mirrors the
     app made keep their own sentence. Look at the Chats page's counts and words with the rig's mirror data.
  4. The flags together: `run -pages` with the mirror's flags; the help text reads as one text.
  5. The fake Telegram and the rig changed: `TestPagesHold`, `TestE2EPages` and the pages' rig tests compile
     and pass on the merged tree.
- Run by name on the merged tree: every test this branch added (the three sections of
  `archiver/docs/progress/pages-g1-REPORT.md` list them); the mirror's tests that touch the account's loop,
  the session, the reader's approval and the run command (find them in `mirror_auto_test.go`,
  `mirror_fixround_test.go`, `mirror_settle_test.go` and by `grep`; list which you ran); the server's package
  with `-short`; `livepages`. No whole run of `internal/collector` or `internal/catalog`, no race detector.
- `gofmt` and `go vet` on the changed packages, one at a time.

## Order
Part 1 first, committed and pushed; then the merge as its own commit; then what the merge needs, as commits
after it. If the merge shows something in the mirror's code that this branch breaks or that breaks this
branch and that you cannot settle inside this branch's own files, stop and say exactly what, with the lines.

## The report
Two sections added to `archiver/docs/progress/pages-g1-REPORT.md`: "The pause's review" (each finding, what
was done, its test) and "The main head merged in" (which head; each conflict quoted; each of the five meeting
points with what you found and did; the tests run by name with results; every existing test of either side
whose expectation changed and why; what was not verified). Hand back commit-ready as before.
