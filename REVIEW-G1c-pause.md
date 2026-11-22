# Review G1c: the pause of downloads (independent, read-only)

The review covers `wip/pages-g1` in `wt-pages-g1`, `git diff 1fd0d6d..0ee2c00`. It also reads `account.go` (`runSession`, `engineTask`,
`startEngine`, `stopEngine`, `close`), `collector.go` (`refresherMux`), `supply.Refresh`, `engine.Wait`, `exact.compareOne`,
`reader.go`/`monitor.go` session endings, `ownerstop.go`. The tree was not changed. Probes were loaded with `go test -overlay` from
`C:\Users\trabi\AppData\Local\Temp\claude\71f159c3a9e5d4b9\d968be25-bb4c-460c-a415-c3cbcc8ac244\scratchpad\probe\probe_pause_test.go`.
That file is a minimal `Collector` on a temporary catalogue with a hand clock and no rig. Its run:
`GOGC=25 GOMAXPROCS=2 go test -p 1 -overlay ... -run TestProbe ./internal/collector`, about 0.5 s.

Count: **1 must fix, 2 should fix, 5 minor.**

## Must fix before merge

### F1. An every-account pause replaces and shortens an account's pause "until I resume", which then ends by itself. CONFIRMED (probe P1)
- **File:** `internal/collector/pausedl.go` 326-363 (`PauseDownloads`, `pauseByOwner`: it overwrites memory and the row
  with no regard to a pause already on). The UI path is `internal/server/web/assets/js/main.js` 153: the header offers
  "Pause downloads" for every account whenever `paused_all` is false.
- **Sequence:**
  1. The owner pauses account 1 "until I resume" (say its allowance is shared with the phone).
  2. Account 2 still downloads, so the header shows "Pause downloads" for every account. The owner picks "1 hour".
  3. `PauseDownloads(0, now+1h)` writes "began,now+1h" for account 1 too.
  4. One hour later, account 1's engine starts again by itself, with no Resume.
- **What the owner sees:** the toast says "Downloads of every account paused for 1 hour". The header then says only
  "Downloads paused for every account", because the words differ, so no end is shown. Nothing says that account 1's
  indefinite pause was cut to an hour.
- **Why it is a must fix:** this breaks "a person's pause is never undone by the app" (TRIED-BEFORE 24 rule 1). The pause
  the owner set and never resumed ends without any choice of theirs.
- **Probe P1:** account 1 paused with a zero until, then `PauseDownloads(0, now+1h)`, then the clock moved 2 h on.
  `DownloadPause(1)` = `{Paused:false}`. The probe fails as expected.
- **Smallest change:** for account 0, never shorten a pause that holds. Keep the later end, with 0 ("until resumed")
  winning. For example, in `pauseByOwner` with an `all` flag: if `p.pausedAt(now)` and (`p.until == 0` or
  `u != 0 && u < p.until`), keep the current record and report the account as already paused. A one-account pause may
  still replace its own pause, since the per-account menu is not offered while paused. Add a collector test with the
  probe's sequence.

## Should fix

### S1. A freeze seen by the engine just before a pause is not acted on until the pause ends. The reader and the monitor go on sending on a frozen account meanwhile. PLAUSIBLE (quoted lines; timing not reproduced)
- **Files:** `internal/collector/pausedl.go` 243-257 (the first paused turn calls `s.stopEngine()` without looking at the
  engine's `Stats()`); `internal/collector/account.go` 707-721 (the only place a frozen refusal ends the session:
  `endFrozen` is signalled from the engine task alone, per `grep endFrozen`; the reader and the monitor signal only
  `endSignedOut`).
- **Sequence:**
  1. Turn N checks `re.e.Stats()` and sleeps 1 s.
  2. During that second a part is refused as frozen. The engine freezes the account and saves `HoldFrozen`
     (`engine/lane.go` 1468).
  3. Also during that second, the owner pauses.
  4. Turn N+1 is a paused turn. `stopEngine` throws the engine and its `Frozen` lane state away.
  5. The session stays "Running": its reader and monitor keep sending for the whole pause, which can be "until I
     resume".
  6. Only when the pause ends does the new engine load `HoldFrozen`, show `Frozen` and end the session.
- **Rule broken:** "Telegram refused a download as frozen; nothing is sent until the owner clears it".
- **Smallest change:** in `pausedTurn`, before `s.stopEngine()`, take `re := s.eng` and run the same check as
  account.go 709-720 on `re.e.Stats()`. On `Frozen` or `SignedOut`, signal the session's end and return a value that
  makes `engineTask` return `errDone`. Two or three lines.

### S2. The Overview rebuilds each account's pause menu every 2 s. Keyboard focus on "Pause downloads" is dropped, and a click that spans a repaint is lost. CONFIRMED (quoted lines)
- **Files:** `internal/server/web/assets/js/pages/overview.js` 270-271 and 302 (the whole lanes region is remounted at
  every live answer; focus is restored only through `dataset.key`); `internal/server/web/assets/js/pause.js` 44 (the
  `summary` has no `data-key`; the choices do).
- **Sequence:**
  1. A keyboard user tabs to an account's "Pause downloads" summary.
  2. At the next live answer, within 2 s, the region is replaced. `had` is `undefined`, so focus falls to the body.
  3. Separately, with a mouse: the press lands on "4 hours", and the release lands after a repaint on the new copy of
     the button. No `click` fires, so the pause is silently not made.
- `openMenus` keeps the menu open across repaints, as the author reports; it keeps nothing else. The header and the
  Accounts page do not have this problem, because they remount only when their shape changes.
- **Smallest change:** give the summary a `dataset: { key: \`pause-menu-${key}\` }` so focus is restored. Better, give
  the Overview the shape-keyed repaint the Accounts page already uses (`liveShape`), with the time-left words updated
  in place.

## Minor

- **N1.** A pause that could not be recorded, set over an older recorded pause, lets the older pause come back at the
  next start. CONFIRMED (probe P2). `pausedl.go` 169 and 354-356.
  - Sequence: a recorded pause "until I resume", then a pause for 1 h whose write fails. This run is told "for this
    run only" and downloads again after the hour, because `notRecorded` stops the row from being read again. At the
    next start the old row "began,0" is read, and account 1 is paused until resumed (probe:
    `{Paused:true Until:0}`).
  - Fails toward paused and shows on the pages, so it is minor.
  - Change: on a failed write, also try to delete the old row, or let the words say that the earlier pause on record
    still applies at the next start.
- **N2.** A pause takes effect only at the engine task's next turn. The unpaused turn's 1 s sleep (`account.go` 722) is
  not cut by the pause's kick. A pause that lands while `startEngine` runs (after `pausedTurn` returned false) lets
  the new engine ask parts, refreshes and hashes for up to about 1 s, plus the engine's stop. The author documents
  this ("within a second"), and the rig saw the last part 50-870 ms of the clock after the click.
  - Change, if wanted: let `engineTask`'s sleep also end on `a.pause.kicks()`, or re-check `pausedNow` right after
    `startEngine`.
- **N3.** `pause.heldFor` keeps a pointer to an ended session, with its conn, invokers, reader and refresher, until a
  later session's first paused turn replaces it. If the pause ends while no session runs, the pointer is kept for the
  rest of the run. `pausedl.go` 93, 236-240, 253-255.
  - Change: clear `heldFor` when it is not this session (`p.heldFor != s` in the unpaused branch), or in
    `session.close`.
- **N4.** Every Resume counts `LanesAdded` again for every lane, because the lanes are forgotten at the pause
  (`account.go` 682, `pausedl.go` 249). Ten pauses on 4 servers add 40 "lanes added". The number is exposed in
  `Stats()`. Change: leave the count out when `have` is empty after a pause, or note it.
- **N5.** Words. The header shows no end time when accounts' ends differ by even a second ("Downloads paused for every
  account": `livepages/live.go` `pauseWords`). A Resume refused because the accounts cannot be read answers
  `ErrAccountsUnread`, "...so nothing is started; try again" (`livepages/live.go` `mapErr`), which is Start's wording.
  A collector without its catalogue (`ErrNotRunning`) reaches `s.fail`, not a 409.

## Checked and found sound
- **Refresher at a session's start while paused.** `runSession` puts `s.ref` in the mux, and the first paused turn
  removes it. In that window no engine of the account exists. `refresherMux.Refresh` is reached only through
  `supply.Refresh`, which only an engine calls, for its own `LaneID{Account: a.id}`. No other account's engine or
  supply path asks this account's refresher.
- **The exact check's hash requests.** They go only through `s.parts` (`grep UploadGetFileHashes`, `NewParts`), and
  that is used only by the engine and its `wire` checker. `Engine.Wait` waits for calls in flight (`StopGrace`). The
  checker's leftover goroutines (`exact.go` 1112-1137) read local files only.
- **No other Telegram file request exists outside `telegram/parts.go` and `hashes.go`.** Reader, monitor, mirror and
  copier do not move file bytes.
- **Interleaving of Pause, Resume and the record's read.** All hold `wmu`; memory changes under `mu`.
  - Resume during the first paused turn is not lost: the kick cuts `pauseSleep`, and the next turn restores the
    refresher.
  - A pause then resume between two turns is harmless.
  - A second pause while held does not stop twice.
- **Supervisor restart of the engine task while held.** `heldFor == s` means nothing is repeated.
- **Session end while paused.** `pauseSleep` returns on ctx and `engineTask` returns `nil`: no spin. The helper
  goroutine ends on `done`.
- **Not-paused branch near session close.** The `ctx.Err()` guard is there, and `close` waits `engWG` before
  `mux.set(nil)`.
- **Stop, Start, sign-in and ClearFrozen.** They never touch the pause's row or memory. The loop's top check reads the
  row for stopped and unsigned accounts, so the pages know.
- **Restart.** With time left the pause goes on; with its end passed it is over; the end is judged on `Config.Clock`.
  An unreadable or garbled row is paused and read again after `GateRetryMin`. A first read cut by the ending ctx is
  marked unknown, with retry at once (probe P3: shows Unknown only while the program stops).
- **`stopEngine` for a pause** is the same call as `startEngine`'s restart: transfers given back, counters with the
  checker's counts flushed, window saved. Holds and waits are saved by `Engine.Wait` and reloaded at the restart.
- **`-no-downloads`:** refused in the collector and the adapter, nothing shown, a row on record left alone.
- **Server routes.** They exist only with `program` and a `LivePause` (404 in `tgarchive app`, `state.pause` false).
  Both are in the mutation list of `security_test.go`. The `hours` validation is correct.
- **The snapshot** reads memory only (`pause.view`, `DownloadsOff`).
- **Time left and HH:MM** are computed server-side on the collector's clock.
- **The Accounts page and header** repaint only on a shape change; the time-left words are updated in place.
- **Queue page note.** Navigation clears `liveListeners`, so its listener is cleared on leaving the page.
- **Tests.**
  - The rig's clock is a FastClock (×20), so "wall clock" mutation 5 is caught as claimed.
  - The strictened `TestPauseEndsByItself` now drops files saved before the hold and fails on a file never asked again
    or restarted from 0. It is sound.
  - `TestPauseStopsPartsNotReading` judges requests only after the hold. This is fine for "nothing while paused", but
    it allows the N2 window by design.
  - No test covers F1, S1 or N1.

## Not looked at
- The commits before 1fd0d6d beyond what the pause leans on.
- `TestScriptsNoDuplicateOrMissingNames`, the five page faults, the CSS.
- `livepages/live_test.go` and `server/pause_test.go` beyond their names and `TestLiveStillReadsNoTable`. That test uses
  a fake Live, so it cannot catch a table read in the real adapter. The real adapter was read instead.
- The pages were not opened in a browser. None of the rig tests or the author's tests were re-run; only the three
  probes.
- No race detector.
