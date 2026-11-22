# Brief B5-S, fix round: the review's findings and two decisions of the main session (viewer session B5, 11-16)

Same copy (`C:\Users\trabi\Claude\Projects\Telegram\wt-b-viewer`), same branch (`wip/b-staged`, head
3f4030ba), same bounds, privacy and load rules as `BRIEF-B5-staged-lost.md`. The independent review is
`C:\Users\trabi\Claude\Projects\Telegram\wt-b5-review-S-scratch\REVIEW.md` (read it in full; its probes
`probe_r5_test.go` and `probe_r5big_test.go` and its two mutants are beside it: you may take tests from the
probes into the package, rewritten as the package's own). Verdict: not ready; F1 to F3 matter. **All seven
findings are accepted**, as below. Do not merge the main head in: the main session does that after this round.

## The review's findings
- **F1 (`recheck` held by waiting copies, so "files missing" never clears while a copy is due):** `recheck`
  is not held by copies. Its sample opens a handful of files once a minute and reads none: say so in the
  makers' head comment as the one background touch of the library that goes on while copies wait (with
  F5's second item: the sample a trip opens).
- **F2 (the health sample can be empty):** an eighth's sample file is taken from the catalogue, among rows
  whose bytes are the library's: eight seeks over the file table's id range (the first library row at or
  after each of eight points; if none ahead, the nearest before), each bounded (no pass over the table: a
  run of staged or lost rows longer than a bound you choose and state gives that eighth no file, and the
  others still answer). An empty sample stays "no answer", but must now need a library with no file row
  at all in it. A catalogue from before step 8: the same seeks without the location.
- **F3 (a staging folder that is not there at the start is never used):** `usable()` looks again when no
  root is kept, through `reopen` and its own gap (one try per 10 s, whoever asks).
- **F4 (a catalogue stepped while the viewer runs):** `hasLoc` and `hasQueue` are atomics, set again
  whenever a full read asks; the readers and the index then cannot disagree past the next full read.
- **F5:** a staged file's job never looks in the second thumbnail folder (`takeFrom`: the NAS run never saw
  staged bytes). The sample opened at a trip stays as it is; say it in the comment (F1).
- **F6:** `New` refuses a staging folder that is the library, inside it or holding it, and one that is the
  data folder, inside it or holding it, each in its own fixed sentence (through `OpenFailureWords`, as the
  other refusals of `New`).
- **F7:** the flag's help says the staging folder cannot be renamed or moved while the viewer runs.
- **The tests the review found leaning:** "saved again" through the catalogue's own doors (`WantAgain`,
  `Claim`, `Saved` with the staging location, `CopyDone`), as the reviewer's `TestR5ReviveThroughDoors`
  does it; a junction case beside the skipped link case (`mklink /J` needs no rights; skip off Windows);
  a test that fails when the same-file check is dropped (a file swapped between the look and the open: a
  second testing-only hook between the two is fine); a test that fails when the two-digit folder's check
  is dropped, or, if nothing can make it fail because the root already refuses it, remove that check and
  say so.

## Two decisions of the main session
- **D1. Staged files go on while the library is away.** Today `run` sends every worker to sleep while the
  library is unreachable or marked "files missing", so with the NAS off (the very time everything new is
  staged) no staged file gets a thumbnail, asked or not. Wanted: in that state the workers still take
  **staged** work (a person's ask for a staged file at once; background staged files as in D2); a job for
  a library file is not taken and not dropped (an asked one stays queued as it does today while the
  workers sleep; say what bounds that queue); `whileMissing` and `recheck` keep their pace and remain the
  only things that look at the library; nothing of a staged job counts towards the rule. One predicate
  says "the library's files are not to be opened by the makers now" with its three reasons (unreachable,
  files missing, a copy due: the third holds background jobs only, never a person's ask), and every place
  that chooses a job asks it: there must not be three half-copies of that decision.
- **D2. While the walk gives way, and whenever it has nothing to hand out, it takes staged files from its
  hint, not by walking the order.** As built, a staged file far down the order waits about 37 minutes with
  two workers at 600,000 media (the reviewer's computation: 4,096 positions a call, 30 s idle after an
  empty call), and up to 6 hours after a finished walk. Wanted: while background library jobs are held
  (D1's predicate), the walk's position does not move and no library file is passed or held for later;
  the worker takes the staged files of the hint in id order, one pass per idle round (a file that is
  "not there now" or has no staging folder is tried once a pass, never in a loop; a made or marked one is
  skipped in memory). The same pass runs when the walk is done or has nothing left to hand out. The
  held-for-later list then holds only the few background jobs that were already taken when the hold
  began (its bound and the restart from the top go away if nothing else needs them; say what you
  removed). The hint must stay bounded by what is staged (an entry leaves when its row is seen as library
  or lost); say how large it gets with 100,000 staged files and what one pass costs.

## Tests for the two decisions, at least
The library unreachable from the start, and then "files missing": a staged file asked is made at once, 30
background staged files are made, no library file is opened by a maker, the asked library job is still
queued and is made when the library is back; a copy due for a long time with 5 staged files among 5,000
library ones far down the order: all 5 made within two idle rounds (a clock handed in), the walk's position
unchanged, nothing held for later; a staged file that is not there is tried once a pass; the coder's
existing `TestWalkGivesWayToCopies` and the health tests still say what they said. No test judges real time.

## At the end, once
As in the first brief (gofmt, vet, your named tests old and new, the wall tests, both builds), and
`go test ./internal/viewer -run 'TestHealth|TestBlip|TestPaced|TestWalk|TestThumb|TestBulk|TestMaker|TestLibrary' -p 1`
since `run` and the walk change. Commit and push `wip/b-staged` as before. Hand back, as your last message:
the commits and the head; each finding and each decision with what was done and any difference with its
reason; the one predicate and every place that asks it; what was removed; the numbers asked for in D2; what
you ran and what it printed; what you did not test; doubts. The copy clean, nothing left running.
