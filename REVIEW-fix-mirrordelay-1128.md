# Review: wip/mirror-delay (2dbfd92b on f1dc9a40), the mirror's turn when its time comes

One independent Opus review (11-28), of the code that changes when the automatic mirror writes and how history
reading gives way. Only the code was read; nothing real was run.

**Verdict: fix first.**

One HIGH (a hot loop that a probe reproduced) and one MED (the early chat list breaks the pacing-settings rule).
No write can go sooner than any bound: every bound is gated inside `mirror.Turn` from the catalogue at each call.

## Runs
- `go vet` on collector, telegram and mirror: clean.
- `go test ./internal/collector -run 'MirrorWake|MirrorAuto|Reader|Click'`: ok (382 s). telegram `-run 'Read|History|Pass'`: ok.
  mirror `-run 'Turn|Auto|Timing|Single'`: ok (109 s).
- Probe for H1, in a scratch worktree that has since been removed: autoRig with the switch off, history of an approved
  chat told to wait 120 s every 2 pages. The probe set `auto.live=true` and called `wakeForMirror()` (what `liveSeen`
  does). Result: **1454** "a wait stated earlier runs N s more; slept before the request" lines in 1.5 s of wall time
  (60 s of the clock). The control with no stale flag gave **0**. No history request was sent inside the wait (held).

## Findings

### HIGH 1: a `live` flag left true makes the reader spin for the whole of any stated history wait
- `mirror_wake.go:99` sets `auto.live`, and only `mirror_auto.go:1259` clears it. That line comes after many early
  returns of `autoTurn`:
  - the switch off with no owner's want (`:1227-1228`, where `sources` is cleared but `live` is not);
  - `st.off` (`:1166`; `sources` is never cleared there, so every later message of a former source sets `live` again);
  - `fail` (`:1188`, `:1213`, `:1223`);
  - no secret, or no store or memo.
- While `live` is true, `mirrorCutAt` returns "at once" (`mirror_wake.go:139`). `readerClock.Sleep` then sleeps
  nothing (`click.go:1209`) and cancels the pass (`click.go:1244`). `readTurn` returns did=true with no idle. The next
  pass goes into `held`, and the same cut happens again at once. The result is a busy loop of catalogue reads
  (readChats, OpenGaps, settings, autoTurn) and one log line per round (`telegram/call.go:120`), for as long as the
  wait lasts, up to MaxWait.
- Failing case: the owner switches the automatic mirror off from a page, has no owner's want, and a post of a mirrored
  source arrives between the last full turn and the switch. Or the account ends (`AccountEnds`) while its sources keep
  posting. Either way the next FLOOD_WAIT on getHistory spins the PC and floods the log. Even with no wait, every
  history pass stops after one page for the rest of the session.
- Fix:
  - Clear `live` (and `sources`) on every path where the task does not turn (the off, st.off and no-want paths), at
    the top of `autoTurn` before the early returns, or in `setDue(time.Time{})`.
  - Have `liveSeen` ignore messages while `st.off`.
  - Add a backstop in `mirrorCutAt`: an "at once" cut counts only once per pass. For example, record the `live`
    generation that a cut acted on, so that a second cut needs a new message or a turn that ran.
  - Add a test: switch off with live set and a history wait, and assert that the log does not grow and no request is
    sent early.

### MED 2: the early chat list floor is a constant of 1 minute, below the stored interval's own minimum of 5
- `mirror_wake.go:54` and `reader.go:630`. The stored chat-list interval (`mirror.ListEvery*`) is 10 min by default,
  5 min at the least, and has a random part of up to 5 min. `autoJoinListAfter` is fixed at 1 min with no random part.
  CLAUDE.md asks that every pacing interval be a stored setting with a random part.
- Worst case: `joinHint` clears before each list and is set again by any bare `updateChannel` or `updateChat` of a
  channel or group that the catalogue does not hold the account in after the list. Examples:
  - a chat that the list does not name (left, previewed, or one the list cannot mark as "in");
  - a chat whose bare updates keep coming;
  - several such chats.
- In that case the list goes every minute: **60 lists an hour, against 4-6 at the default interval.** Each list pages
  both folders at 100 per page (`dialogs.go:141,151`), about 8-10 `messages.getDialogs` for the owner's ~700 chats.
  That is about 500-600 requests an hour instead of about 50.
- Whether Telegram sends bare `updateChannel` for chats the account is not in is not known on record. The bound must
  not depend on it.
- Fix:
  - Make the floor a stored setting with a random part (Vary keyed like `ListInterval`), with its default no shorter
    than `ListEveryMin`, or simply reuse the interval in force with the hint only halving it.
  - Answer a hint only once per chat: keep the hinted chat ids, and do not hint again for a chat the last list did
    not name.
  - Say the cost (requests per list × lists per hour) to the owner.

### LOW 3: a busy source runs a full turn per message
- `liveSeen` wakes the reader at every new message of a mirrored source, including the getDifference burst after a
  reconnect. Each wake runs a whole `readTurn` and `mirror.Turn` (dozens of catalogue reads) and cuts the history
  pass after one page. No Telegram request is added (history still gets at least one page a pass), but a group with a
  few posts a second costs that many full turns a second.
- Fix: coalesce. Wake at most once a second, or skip the wake when `due` is already set sooner than now plus the
  single wait's low end.

### LOW 4: each mirror cut inside a stated wait writes a log line again
- Every cut re-enters `held`, which logs "a wait stated earlier runs N s more" (`telegram/call.go:120`), and the
  `mirror.reader_gave_way` count grows with it. With a pace of 3-5 s inside a wait of several minutes, that is dozens
  of lines per wait. Clicks already had this, but rarely.
- Fix: say it once per wait end, or drop to a count while the same wait record is being re-slept.

### NOTE 5: bounds (check 1)
- Pace and adaptive factor, `gapAt` (one whole second), pause and new-per-day, per-hour (`hourRoom`), recorded waits
  (memo), single wait and album rule: all of these are read from the catalogue at each `mirror.Turn`.
- The random parts come from the keyed `Vary` (`timing.go:137`), so calling the turn more often never re-rolls them
  towards the low end.
- The 1 s re-due after a send cannot send anything by itself. The turn after it returns at `st.yield`
  (`mirror_auto.go:1196`), the next one is gated, and `autoIdle` keeps at least 1 s.
- The album rule (90 s after each part's own time) is unchanged. Turns now run at that exact moment rather than up
  to an idle later. That is the agreed rule, but the hidden slack of 60-120 s is gone.

### NOTE 6: history cuts (check 2)
- `Yield` is checked after `SavePage` and the cursor are saved, and before the next request
  (`telegram/reader.go:640`). It is never checked before the first page or for a range read.
- A cut inside `takeWait` or `held` leaves the record in place. The next history request sleeps the rest first.
- A cut pass returns `fired` (`reader.go:797` and onward), not `chatFailed`, so no back-off is added. No page is read
  twice and no gap is left.
- Starvation is bounded: at least one page per pass outside a wait, and a wait still ends at its recorded time.
  H1 is the exception.
- A history `LongWait` (over MaxWait) still holds the whole loop at `waitUntil`, so the mirror waits behind it as
  before (`reader.go:~592`). This was not changed and is not a regression.

### NOTE 7: concurrency (check 4)
- `due`, `live`, `sources` (a fresh map per Store), `joinHint` and `cutFrom` are atomics.
- `srcTg` and `listSoonAt` are touched only by the reader's goroutine.
- `wakeForMirror` cancels under `sleepMu`, and every pass through the loop re-registers under the lock and re-reads
  the click flags, so no click wake is lost.
- No wake is lost between the store and `live` (the message is stored first, `live` is reset before `Turn` reads).
  A spurious early wake costs one extra round.
- Shutdown is safe: `nudgeReader` does not block, and `sleeping` is nil outside a sleep.

### NOTE 8: clicks (check 5) and privacy (check 6)
- In `readerClock`, `pending` and `woken` are checked before the mirror's cut. `clickStep` still runs before
  `readTurn`, and `clickPending()` still comes before `autoTurn`. Clicks still go first.
- No new log call was added. The counter name is constant. Nothing of real data is printed.

## Second pass (the fix): 2dbfd92b..e565242f

**Verdict: may be merged.**

Every finding stands fixed. The fix added no logic error. Three small notes remain, none blocking.

Runs on e565242f:
- gofmt and vet are clean on collector, telegram, mirror and server.
- telegram `-run 'Read|History|Pass'`: ok.
- mirror `-run 'Turn|Auto|Timing|Single|JoinList|ListEvery'`: ok (111 s).
- server `-run 'TestAssets|Security|Mirror'`: ok.
- collector `-run 'MirrorWake|MirrorAuto|Reader|Click' -timeout 30m`: ok (425 s). This includes the new
  TestMirrorWakeNoSpin and TestMirrorWakeHintOnce.

### H1: fixed
- The source list and the live flag are now cleared on every early return:
  - the not-turning paths at the top of `autoTurn` (hooks off, not signed in, `st.off`);
  - the switch off with no owner's want;
  - `AccountEnds`.
  For every other path, `live` is cleared at the top, before `fail`, `autoLook`, the yield, the secret check and the
  store check. Each of those paths either reads the catalogue or brings a turn soon (1 s after a send, 1 min after a
  failure), so no message is lost: the candidates come from the catalogue, not from the flag.
- One cut per live message: `mirrorCutDue` records `cutGen = liveGen`, and `mirrorCutAt` cuts again only for a new
  `liveGen`. Once a turn has run, the cut goes no sooner than `lastRun + 1 s`.
- TestMirrorWakeNoSpin is my probe, counted on `HeldWaits` (at most 3 in 60 s of the clock; it was 1454 before the
  fix).
- Every new field is reader-only or atomic: `cutGen` and `lastRun` are read only in the reader goroutine, and
  `mirrorCutAt` returns at `cutFrom == 0` before it reads them.

### M2: fixed
- `mirror.auto.join_list_after`:
  - default and minimum 5 min (`ListEveryMin`), maximum 1440;
  - a random part of `ListSpread`, keyed by account and last list, never shorter than the floor;
  - a stored value that cannot be read gives `joinAfter = 0`, so no list goes early (safe side).
- `hintNew` answers each chat's bare hint once per session. Every list, early or regular, resets the floor's start
  (`lastAt`), so the worst case is 12 lists an hour, and only with a new hinting chat for each one.
  TestMirrorWakeHintOnce: 4 bare updates of one chat over 16 minutes give 1 list.
- Racing a hint against a list can at most add one list at the floor; it never loses a hint.
- The route `POST /api/mirrors/join-list` is registered by `mirrorRoutes` beside list-every, so it has the same guard.
  It refuses a missing field and values out of range beside the field. The page row uses `textContent` and the
  stepper like its siblings.

### L3: fixed
- `liveSeen` wakes only when the flag goes from false to true, and `liveHeld` allows at most one turn a second after
  the last run of `mirror.Turn`.

### L4: fixed
- `memo.heldNew` says the held-wait line once per wait end, while the count still grows.

### Remaining notes
- **NOTE a:** a chat whose bare hint was answered asks no second early list in that session, even if a real join of
  it later comes bare. The regular interval finds it. This is the safe side.
- **NOTE b:** on the `fail` path with a busy source, `liveHeld` does not apply, because `lastRun` is moved only by a
  real turn. That gives one cheap turn per message while the catalogue cannot be read, with no Telegram request.
  This is rare.
- **NOTE c:** when the stored list interval cannot be read, `autoListInterval` returns before it reads the floor, so
  `joinAfter` keeps its last value (0 at the start: no early list). This is acceptable.
