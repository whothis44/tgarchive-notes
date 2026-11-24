# Review: wip/fix-mirrordoor 457f9289 (against 3dd304df)

**Verdict: may be merged. No HIGH or MED findings; four LOW, three NOTE.** Independent Opus review, 11-23.

Checked and found sound:
- **Telegram's waits:** `mirror.ResetPause` writes only `mirror.pause.<account>`. The stated waits (`Waits` memos, `wait:<kind>`)
  and the adaptive pace state (`paceStateKey`, the hour after a wait) are left alone. A running `-pause` run keeps its own
  local `pause` (step.go ~285/615), so a reset during the run never shortens it. The auto mirror reads `autoPause` once a
  turn and still waits out `waitUntil` for every kind. Nothing is sent.
- **A person's pause:** an origin of `flag` gets `PauseResetKept` from the door (`keepPerson=true`). The command's
  `-pause-reset` still removes it, as before.
- **step.go:** the change behaves the same as before: `ResetPause(..., false)` writes `reset` where the old code did. It
  skips the write only when nothing, or `reset`, is already stored. The plan's fingerprint (`pauseRaw`) still turns a reset
  made between plan and yes into `WhyChanged`.
- **Lost updates:** the read and the write happen in one transaction (`UpdateSetting` -> `Batch`). The only race left is
  a step that read P before the reset and then meets a new wait: it writes 2P over the reset. That is the slower side, so it
  is safe. No order of events lets a step run without its wait.
- **The door:** it is in `mutating` and `programOnly`, and the guard refuses a missing token, a wrong token, another origin
  and a cross-site request (the test covers each). It refuses: `account<1` (fields), an account not in `accountIDs` (404),
  an account the collector does not have (`errNoSuchAccount`, a refusal), a list (400) and GET (405). The route exists
  only when the doors offer `MirrorsPace`.
- **Queries (EXPLAIN on a probe):** unknown batches use `c_mirror_source` (covering) then `c_mirror_batch_mirror`. Set-asides
  use `c_mirror_source` then the PRIMARY KEY of `c_mirror_aside`. Put-backs use `c_mirror_source` then
  `c_mirror_putback_msg` (covering), with a temporary B-tree for DISTINCT. None walks a whole table.
- **schema_mirrorputback.go:** the type and the function are additions only. No schema step's SQL changed.
- **Logs:** `logOnce("the mirror's paces", err)` logs the error's class only. The page's lines are fixed words with
  numbers only.
- **Tests at 457f9289 (scratch worktree):** vet is clean. These pass: `mirror -run 'TestResetPause|Pause'`, `livepages`
  (whole), `collector -run TestMirrorPauseResetDoor`, `server -run 'TestMirror|TestAssets|Security'`,
  `catalog -run TestMirrorCountsOf`.

## Findings

**LOW 1: once a wait lengthens a person's pause, the door removes it, despite the words "a pause you set with -pause is
kept".** Places: step.go ~621 and topic.go ~1246, which rewrite the stored value with origin `wait`;
`pauseResetOf` (pause.go). Scenario: the owner runs `mirror -pause 60s`, which stores `60000 <t> flag`. A later run meets a
stated wait and stores `120000 <t> wait`. The door's "Forget" then removes everything. The next `-pause 10s` run goes at
10 s, where before the reset a smaller `-pause` would have been ignored. Telegram's rule is not broken (the stated waits
still hold, and the owner gave the new 10 s). Only the words are untrue. Fix: in `MirrorPauseResetLead` and
`MirrorPauseResetKept`, say "a pause you set with -pause and not lengthened since is kept". Or have the lengthening keep
the person's floor, for example a `flag` origin kept when the value doubles, or a fourth field.

**LOW 2: the confirm and the lead for an unreadable value read as if a learnt pause will be forgotten.** Place:
`keptPace` sets `ResetAsk`/`ResetLead` the same for `PauseUnreadable`. Scenario: the value cannot be read, and it may have
been a person's pause. The confirm says "Forget the longer pause the mirror learnt after a wait". The click turns a closed
state (the auto mirror creates nothing) into the option's pause. That matches what the command's `-pause-reset` always
did. Telegram's waits are untouched, so the owner is not exposed to anything faster than a stated wait. Fix: give the
unreadable case its own ask: "The stored pause cannot be read (it may have been one you set): write it anew as none? The
next run starts from the normal pace."

**LOW 3: the page can show the old facts for up to 15 s after the click.** Place: `handleMirrorPauseReset` does not drop
the account's kept reading. `mirrorStates` serves it for `mirrorFloor` (5 s) or `mirrorQuiet` (15 s), and `CountsKey` does
not change on a write to the settings. The test sets `mirFloor, mirQuiet = 0`, which hides this. Scenario: the owner
clicks and sees "Forgotten". `ui.reload()` still draws "A longer pause of 40 s was learnt…" with the button. A second click
says "nothing to forget". Fix: after a successful door call, mark the kept reading stale under `k.mu` (for example
`k.ok = false`). Or patch `k.pace` (`PauseStored=false`, `PauseUnreadable=false`) from the answer.

**LOW 4: the line "N still wait to go again" can disagree with the total.** Place: `mirrorPaceLines`. `PutBack` counts
every distinct message ever put back. `PutBackWaiting` comes from `MirrorPutBacksWaiting`, which counts only `created`
mirrors and only messages not deleted at the source. The line says "%d still wait … %d of them put back over a day ago"
even when both are 0. Scenario: after old mirrors are stopped, the page reads "7 messages put back…; 0 still wait to go
again, 0 of them…". This is cosmetic. Fix: leave out the "still wait" part when `PutBackWaiting == 0`.

**NOTE 5: more work on each refresh.** Each kept reading now also calls `MirrorPutBacksWaiting` (it joins `message`). The
states door already calls it with a day's bound (door.go:276), so the same query runs twice a reading. The unknown-batches
count reads every batch row of the account, the same access path as the existing states summary
(schema_mirrorwant.go:691). It uses indexes but grows with the account's batches. This is not a defect now. If the readings
slow down, add a partial index `c_mirror_batch(mirror_id) WHERE state='unknown'` and reuse one waiting read.

**NOTE 6:** a reset during a run whose step then meets a new wait is overwritten by 2P. That is correct and the slower
side, but the page's "Forgotten" words do not mention it. No change needed.

**NOTE 7:** the door goes through `doorDeps(ctx, nil)`, so it may refuse while the collector is not ready, although the
reset is catalogue only. That refuses rather than allows, so it is acceptable.

**may be merged** (LOW 1 to 3 are worth a small fix round; none of them blocks the merge)
