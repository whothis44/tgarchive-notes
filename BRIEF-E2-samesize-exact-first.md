# Brief E2: a look-alike of the same byte size goes to the exact check first (session C, 2026-11-15)

For one Opus coder, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-1` on branch
`wip/copies-2` (already checked out there, head ed87e9f; do not switch branches). That branch holds piece E1
(the old look-alike rule: `internal/catalog/ladder.go` `lookAlikeVideo`, `videoFacts`, `schema_lookalike.go`)
and piece E3 (`held_wait`: held copies are not supplied or claimable; `LaneOptions`/`ClaimOptions.HeldWait`,
`internal/supply` `heldWaits`). Read both pieces' reports under `archiver/docs/progress/` first. Commit work in
progress to the branch as you go (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`,
messages starting `WIP copies: `, ending with a blank line and `Co-Authored-By: Claude Opus 5.5
<noreply@anthropic.com>`, no number of any real archive) and push with `git push private wip/copies-2`; never
`origin`, never the main branch, never a force-push.

**What is broken on this branch today, and is this piece's acceptance test:** with `held_wait` on (the default),
a same-size re-upload that looks like a saved video is held by rung 6, is never claimed, and so never reaches
the exact check. The collector's `TestE2EExact*` (run with `COLLECTOR_SMALL=1`) time out for that reason
("timed out waiting for the spot-checked re-upload saved", and its siblings). **With this piece they must pass
again with the default setting, unchanged** (you may not edit them, nor set the setting off in them; if one
cannot pass for a reason that is not this piece's, stop and say which and why). `TestE2ECleanRun` sets the
setting off already (`heldWaitOff`): leave it.

**The schema step:** 15 on the board. Built as the step after E1's, in a file named by content
(`schema_checkfirst.go`), its number in exactly two constants written as numbers (as E1 does), no name
carrying the number.

## Why (the old app's numbers; do not re-derive)

- Of the look-alike holds a frame check later released in the old app (275 against saved files), 203 had the
  saved file's exact byte size, pixels and length, and at least 23 were exact copies after all (18 skipped
  later by Telegram's hashes, 5 the same SHA-256 after download). Of the 1,218 confirmed, 975 had the same
  byte size. So most look-alike holds are files the exact check can end without bytes.
- The exact check in the old app, ten days: 9,046 checks, 5,007 files not downloaded, every one by Telegram's
  hashes; 18 checks without an answer. The new app's first run: 15 checks, 43 hash requests, no wait.
- The owner (11-14): on a live account a held copy waits for good unless released. A file held by rung 6 is
  therefore never claimed, so today its exact check never runs: an exact copy would sit held for ever
  instead of being linked.

## Ported from (the owner, 11-14 night: port the old app's code, do not write anew)
- `ix_subst.go` (`ixSubstPlanFor`, `ixRemote`, `ixSubstCandidates`, `ixPartName`): already ported, as
  `internal/exact` and `catalog.ExactCandidates`. This piece ports nothing new from it.
- What is new against the old app, for a recorded reason: there the exact check ran at a held file's claim,
  after a frame check might already have released it (at least 23 exact copies released so, answers 5); here
  it runs before the hold.

## The design (decided; the engine is not touched)

The engine already gives a checked file back **held**, no attempt spent, when the Checker answers
`CheckProbable` (`engine/check.go`, `CheckSupply.CheckHeld`, `supply/pending.go` `pendHeld`). So:

1. **A mark on the collector row.** Schema step (number: taken on the board when this is started; next free
   was 15): `c_want.check_first INT NOT NULL DEFAULT 0`. The number is written in one place, as E1's step.
2. **The ladder.** When rung 6 (E1's old rule, videos) finds a saved look-alike AND a saved file of exactly
   the new file's byte size exists that the exact check would take as a candidate (the same lookup as
   `ExactCandidates`: not lost, same size on disk, not a numbered part; size at least `ExactFloor`), and the
   exact check's setting is not off: the file is **not held yet**. It is inserted `wanted`, `check_first = 1`,
   `probable = 0`, with its probable edge and evidence written as for a hold, reason
   `ReasonLookAlikeCheckFirst` ("looks like a saved file of the same size: Telegram's hashes are asked
   first"). `AttachmentResult` says so (rung 6, state wanted, `LinkedTo` set). Everything else of E1 as it is.
   A look-alike with no same-size candidate is held at once, as in E1.
3. **The check.** `catalog.ExactTarget` and `exact.Target` gain `HoldUnlessSame bool` (the row's
   `check_first`) and the look-alike's saved file (the probable edge's target, as a `file.id`), carried
   through `exact/wire`. In `exact.Checker.Check`, for such a target:
   - "same": unchanged (linked, no bytes; the spot-check setting applies as for any file);
   - **every other outcome the Checker itself would return** (`CheckNone` because the setting is off, no
     candidate is left or the file is under the floor; `CheckDifferent`; `CheckUnknown` for any reason of its
     own, the wait rule included) becomes `CheckProbable`, with `Match` the look-alike's saved file and a
     fixed reason that keeps what the hashes said: `ReasonLookAlikeDifferent` ("looks like a saved file;
     Telegram's hashes differ") or `ReasonLookAlikeUndecided` ("looks like a saved file; Telegram's hashes
     did not decide"). `Compared` keeps each candidate's true outcome. `Err` is passed on unchanged (a wait
     must still hold the server's checks).
   - The comparison's counts (`Totals`: different, unknown) count the true outcome; a new count says how many
     were handed back held.
4. **The supply and the catalogue.** `pendHeld` with one of those two reasons calls a new
   `catalog.HoldLookAlike(ctx, rec)` instead of `HoldExact`: in one transaction, guarded by the claim as
   `HoldExact` is: `state = 'held'`, `probable = 1`, `reason = ReasonLookAlike`, `claimed_by = NULL`;
   `check_first = 0` when the hashes differ, left 1 when they did not decide (a later piece offers those
   again and must not let a frame check release them); the check recorded with its true outcome
   (`recordCheck`), so a candidate found different is not compared again. No new edge (rung 6 wrote it).
5. **The owner's release wins.** `Transition` to wanted clears `check_first` (as it clears `probable`): a file
   the owner released is downloaded, never held again by this.
6. **A file that comes back another way keeps its mark:** `CheckLater` (aside, then wanted again), `Release`,
   `RecoverActive`, `RequeueAside`: `check_first` is untouched, so the check runs at the next claim. `Saved`
   and `LinkSame` end the row as now.

## The known gap (count it; do not close it here)

Five outcomes are made by the engine itself and end in the file's download whatever the Checker says: the
lane's checks held by a wait on a hash call (`uncheckedNow`), check slots taken twice, the check's deadline,
a wait stated on this file's own hash call, a panic. A marked file is then downloaded although it looks like
a saved file. Closing it takes a few lines in `internal/engine`, which is the integrator's and is asked for
separately. Here: `Supply.Checked` counts a marked file recorded unknown by the engine
(`LookAlikeUnchecked` in the supply's stats), with a test, so the first real run says how often it happens.

## Tests (invented data only; named)
- `TestCheckFirstLadder` (catalog): same-size look-alike is wanted and marked with its edge; no same-size
  candidate: held as E1; setting off: held as E1; under the floor: held as E1; a numbered part: held as E1.
- `TestCheckFirstOutcomes` (exact): same links; different, each unknown reason, none, wait rule, setting
  turned off mid-check: `CheckProbable` with the right reason, `Match` and `Compared`; a file without the
  mark behaves exactly as before for every one of those (table over both).
- `TestHoldLookAlike` (catalog): the states, the mark kept or cleared, the check rows, the claim guard,
  the saved file gone meanwhile (held all the same: the edge is the evidence).
- `TestCheckFirstThroughSupply` (supply, with the engine's memory lane as the existing exact tests do): a
  marked file whose hashes differ ends held and is not downloaded; one whose hashes match is linked; an
  unmarked file whose hashes differ is downloaded; the engine's own unknown on a marked file is counted.
- `TestCheckFirstOwnerRelease`: released by the owner, claimed, checked different: downloaded, not held.
- `TestCheckFirstSurvivesAside`: marked, sent back by `CheckLater`, requeued: still marked.
- Mutations, each shown failing a named test, then undone: the conversion applied to unmarked files;
  "different" clearing nothing; `Transition` leaving the mark; `HoldLookAlike` without the claim guard;
  "same" converted too.

## Rules (hard)
- `internal/engine`, `internal/viewer`, `internal/bringin`, `internal/telegram`, `cmd/` are not touched.
  `internal/collector` only if a count must be shown and then only by a line in its tally; say so first.
- **This is code beside the download path** (`internal/exact`, `internal/supply`): change nothing in how an
  unmarked file is checked, recorded or downloaded; the table test above is what shows it.
- No new goroutine, timer or background pass.
- Privacy, load, named tests only, no race detector, nothing against Telegram, progress and report files:
  as in brief E1 (`BRIEF-E1-lookalike-rule.md`, "Rules" and "Hand back").
