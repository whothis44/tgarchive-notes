# Review A3: a file from this PC (the upload)

Independent review of `wip/client-upload`, head a187a1f5, diff `ef0293ae..a187a1f5` (6 commits, 33 files). The
copy is at `C:\Users\trabi\Claude\Projects\Telegram\wt-client-upload`. I read it against
`DESIGN-CLIENT-acting.md` (sections 3, 4.1, 4.2, 5, 6.3; choices 2, 3, 7), `BRIEF-A3-upload.md`, the coder's
`client-upload-REPORT.md`, R1 to R12 (`core-act-REPORT.md`) and reviews A1 and A2. 2026-11-22.

How it was checked: by reading, plus probe tests loaded with `go test -overlay`. Nothing in the tree was edited;
the copy is clean. The probes are in
`C:\Users\trabi\AppData\Local\Temp\claude\71f159c3a9e5d4b9\203f8752-f1fd-4d92-89da-68a6a88f4ca9\scratchpad\review-a3`:
- `probe_collector_test.go`;
- `click_upload_hooked.go` (one hook line, for F3 only);
- `probe_telegram_test.go`;
- `probe_server_test.go`;
- `overlay.json`, `overlay-server.json`, `env.sh`.

The test runs:
- named tests only, `GOMAXPROCS=2 GOGC=25`, each started with the CPU under 85% and more than 7 GB free;
- no race detector, no Docker, no ffmpeg (`FFMPEG_PATH` unset; the rig's probe hook stands in);
- nothing against Telegram.

## Findings

| # | Where | What | Status | Severity |
|---|---|---|---|---|
| F1 | `collector/click_upload.go` `startUploads` | After a reader-task restart in the same session, no upload worker runs: upload clicks hang "queued" | CONFIRMED (probe) | must fix |
| F2 | `collector/click_upload.go` `uploadWorker` / `uploadOne` | A click the worker cannot end is taken again at once: the whole file is uploaded again and again, without bound | CONFIRMED (probe) | must fix |
| F3 | `collector/click_upload.go` `pruneStaged` | A stage that ends during a prune is removed right after the stage answered "kept" | CONFIRMED (probe with a hook for the interleaving) | should fix |
| F4 | `telegram/act_upload.go` `sendUpload`, `collector/click.go` `oneClick` | A file whose parts are all up ends "not sent" at its send on a wait or the cap that began meanwhile; every part is spent | CONFIRMED (probe) | should fix |
| F5 | `collector/click_upload.go` `pruneStaged` / `click_stage.go` `uploadClickIn` | The hour's expiry can remove a file whose click is being written | PLAUSIBLE | minor |
| F6 | `collector/click_upload.go` `startUploads` | The worker is a bare goroutine: a panic in it ends the program | PLAUSIBLE | minor |
| F7 | `collector/click_stage.go` | A staged file lives in the session's memory: lost at a reconnect, and its bytes stay until the next start if the session does not come back | CONFIRMED (reading) | minor |
| F8 | `footage/ffmpeg/probe.go` | A rotated video's attribute keeps the coded width and height | PLAUSIBLE | minor |
| F9 | `catalog/schema_actupload.go` `ReleaseStaged` vs `telegram/act_upload.go` | A send refused (FILE_PARTS_INVALID, FILE_PART_N_MISSING) releases the file, but the code says "send again uploads anew" | CONFIRMED (reading) | minor |
| F10 | `catalog/schema_actupload.go` `ReleaseStaged` | A write transaction every minute per account, and at every wake, uploads or not | CONFIRMED (reading) | minor |

### F1 (must fix): after a reader-task restart, no upload worker runs

**Where:** `collector/click_upload.go`, `startUploads` (`up.once.Do`), with `stopUploads` called from
`clicksStopped` (`click.go`).

**The state that leads there:**
1. The supervisor (`supervisor.go`) restarts the reader task after a panic, "it alone restarts". This is
   `c.supv.Go(..., s.readerTask)` on the same `*session`.
2. `readerTask` defers `s.clicksStopped(cat)`. That calls `s.stopUploads()`, which cancels the worker's context;
   the worker ends.
3. The restarted `readerTask` reaches `clickStep`, then `s.startUploads(ctx, cat)`. `up.once` is spent, so
   nothing starts. `up.started` stays true, so `wakeUploads` sends into a channel nobody reads.
4. The next upload click passes its checks, and `handUpload` sets `handed_ms`.
5. Nobody takes it:
   - `NextClick` does not offer it (`actNotUploadingSQL`);
   - `SweepOldClicks` never sweeps it (`actSweepAgeSQL` is NULL while handed);
   - so it stays "queued" until the connection drops or the owner cancels.
6. For the rest of the session there is no `pruneStaged` either: no hour rule and no removal at an outcome.

Reader-task panics are an expected case: there is `TestChalReaderPanicInsideLongWait`, and Core's driver-panic
guard.

**The probe:** `TestProbeA3WorkerAfterReaderRestart`.
- One upload ends "done".
- The reader task is panicked with `onReader(... panic("injected"))`, and the test waits for its restart.
- Then it stages and queues a second upload.
- Result:
  `after the restart, 10m1s of the clock: state "queued" why "" handed true ready false`, then
  `PROBE F1: the upload click is still queued ... no worker runs after the reader task's restart`.

**Fix:** make the worker restartable per reader run. Keep its `wake`, `done` and `stop` in a small struct behind
an `atomic.Pointer`. `startUploads` makes a new one when there is none or the last one's `done` is closed.
`stopUploads` clears it.

### F2 (must fix): a click the worker cannot end is uploaded again and again

**Where:** `collector/click_upload.go`, `uploadWorker` (the inner `for` around `NextUpload`) and the ends of
`uploadOne`.

**The state that leads there:**
1. The store refuses writes: a full disk under the catalogue (the staging folder sits beside it), or a lock that
   outlives the busy timeout.
2. The parts are all answered. `UploadReady` then fails with an error that is not `ErrActState`.
3. `notSent(ActWhyStore)` runs `UploadNotSent`, which fails too.
4. The click is still "queued", handed and not ready. `uploadOne` returns, and `NextUpload` gives the same click
   at once, with no pause.
5. `UploadParts` makes a new file id and sends every part again, and so on without bound.

The same loop has other ways in:
- `os.Open` or the size check fails, or the Actor is nil, and `UploadNotSent` fails. This spins with no request
  but with no pause either.
- The `stop()` read (`UploadState`) returns an error. `UploadParts` turns any `stop` error into
  `ErrUploadStopped`, and `uploadOne` then marks nothing ("stopped"). The click is re-uploaded from part 0 on
  the next loop, even after one passing read error (PLAUSIBLE; no probe).

This breaks choice 7's bound ("the only repeat, at most 3 times, parts only"). It is also unbounded request
volume against the account.

**The probe:** `TestProbeA3ReuploadWhenTheEndCannotBeWritten`.
- A second connection adds two triggers that refuse `UPDATE OF ready_ms ON c_act_upload` and an upload row's
  state change.
- Then it queues a file of 2 parts.
- Result: `part requests while the store refused the end: 44 in 99ms (a file of 2 parts)`, so 22 full uploads
  in a tenth of a second. Once the triggers are dropped, the click ends "done".

**Fix:**
- The worker keeps the refs it could not end this session in memory (its own goroutine only) and never takes
  them again. `StopUploading` at the session's end marks them.
- A `stop` error that is not `errUploadGone` ends the click `ActWhyStore` instead of "stopped".
- Wait `uploadTick` before taking any click again after a failed end.

### F3 (should fix): a fresh stage can be removed by the worker's prune

**Where:** `collector/click_upload.go`, `pruneStaged`.

**The state that leads there:** `pruneStaged` reads `up.staged` (as `keep`) under the lock first. Then it runs
`ReleaseStaged`, a write transaction of some milliseconds, and only then lists the folder. Take a
`StageUpload` of the same account that starts after the `keep` read and ends before the listing:
- it creates, writes and closes the file, and sets `writing=false`;
- the listing sees the file;
- the id is not `keep`, not `live` and not `curID`, so `os.Remove` succeeds (the file is closed; on Windows the
  open-file case alone fails).

The stage answered 200 with the staged number. The click is then accepted (the file is still in memory) and ends
"not sent: the file to send cannot be read".

A prune runs every minute of the clock and at every wake. Any outcome, cancel or verdict wakes it. A small photo
staged at that moment is enough.

**The probe:** `TestProbeA3PruneRemovesAFreshStage`.
- A hook placed right after the `keep` read (in the overlaid copy) runs one `StageUpload`. It stands for the
  scheduler's interleaving.
- Result:
  - `the stage answered 1000 bytes kept; its file on disk after the prune: gone true`;
  - `PROBE F3: the prune removed a staged file the stage had just answered kept`;
  - its click: `200`, then `"not sent" "the file to send cannot be read"`.

**Fix:** list the folder first (`os.ReadDir` before reading `up.staged` and before `ReleaseStaged`).
- A file that appears after the listing is left for the next look.
- A file listed earlier is either still in memory (kept) or already committed to a click, because `stagedTaken`
  runs after the commit and `ReleaseStaged` is read after memory (live).

### F4 (should fix): an uploaded file ends "not sent" on a wait or the cap at its send, its parts spent

**Where:** `telegram/act_upload.go`, `sendUpload` (`uploadWaits` and `capped`, before Begin, with `act.Upload`
set). `collector/click.go`, `oneClick` then sends it through `clickWhy`: `ActWhyWaiting` or `ActWhyCap`, and
`notSent`.

**The state that leads there:** while the parts go up (minutes for a large file), the turn sends the owner's
other clicks. An upload being uploaded is not offered by `NextClick`, so a text queued after it goes first.
Any of these makes the finished upload's send stop with no request, ending the click "not sent":
- a FLOOD_WAIT on the send's kind;
- a slow mode;
- the cap (1 a second, 30 in 5 minutes), within a second of a text sent just before.

Every part is then spent. "Send again" uploads the whole file anew (the trigger empties its upload's life). For
a 2 GB file that is 4000 requests thrown away by a one-second cap.

The design's "a stated wait is recorded and shown, and you send again" is cheap for a text, not for an upload.
The order also flips: a text the owner typed after the file arrives before it (minor, design note).

**The probe:** `TestProbeA3ReadyUploadEndsOnAWait` (telegram package). One send gets `FLOOD_WAIT_33`. Then an
upload with its 3 parts answered goes to `Do`.
- Result: `a ready upload at its send: telegram: a wait Telegram stated runs 34 s more; nothing was sent,
  outcome 0, requests 0`.
- The collector's mapping to "not sent" is in plain reading (`clickWhy`, `ActWhyWaiting` and `ActWhyCap`).

**Fix:** for a ready upload whose only "no" is a running wait, slow mode or cap that ends within the age bound,
leave it queued (its age still counts from `ready_ms`) and let the step move on until then, as the reader's waits
do. Otherwise, at least say on the page that its parts are spent.

### F5 (minor): the hour's expiry can remove a file whose click is being written

**Where:** `pruneStaged`, which sets `up.staged = nil` once `>= stagedFor`, and `uploadClickIn`, which checks
`< stagedFor` and lets go of the lock before `queueWrite` commits.

**The state that leads there:** the queue arrives in the last moment of the hour.
1. `uploadClickIn` passes.
2. The prune expires the file and reads `live` before the commit, then removes the file.
3. The click commits with no file and ends "not sent (file)".

The window is small. F3's fix does not cover it.

**Fix:** `uploadClickIn` marks the staged file as "being taken" under the lock. The prune neither expires nor
removes a file so marked. `stagedTaken` clears the mark, and a failed write clears it too.

### F6 (minor): the worker goroutine is not supervised

**Where:** `startUploads`, which starts the worker with a bare `go s.uploadWorker(...)`.

A panic anywhere in the worker path ends the whole program:
- the probe's parsing;
- gotd's encoding;
- a catalogue call outside the driver guard.

The reader and the other long tasks restart alone under the supervisor.

**Fix:** run the worker body under `run` (`supervisor.go`), or with a `recover` that logs by type, counts, and
ends the running click with `ActWhyStore`. With F1's fix, the next step can start a new worker.

### F7 (minor): a staged file lives in the session's memory

**Where:** `click_stage.go`, `StageUpload` and `uploadClickIn` (`s.click.up.staged`).

**The state that leads there:**
- A reconnect between the stage and the queue (a new `session`) turns the queue into "no staged file". For a
  large file the owner stages again, and the next session's prune removes the bytes.
- A stage that straddles the session's end writes into the dead session's memory. The bytes go only at the next
  session's prune.
- When the account's session does not come back in this run (stopped, signed out), they go only at the next
  program start. That means no "removed after an hour".

**Fix:** keep the staged file's facts per account on the Collector, not per session; or at least prune an
account's staging files when its session ends.

### F8 (minor): a rotated video's width and height

**Where:** `footage/ffmpeg/probe.go`, `streamRe` and `probeLog`.

The probe reads the coded `WxH` of the stream line. A phone video in portrait carries a display [name removed]: ffmpeg
prints "displaymatrix: rotation of -90.00 degrees" in the stream's side data. Its coded size stays landscape,
for example 1920x1080. `documentAttributeVideo{W:1920,H:1080}` then describes a portrait video as landscape
(the client's frame and aspect).

Not seen: no real ffmpeg was run, as the brief forbids.

**Fix:** read the side data's rotation line in `probeLine`, and swap W and H for 90 or 270 degrees. Add one
invented line to `TestProbeLines`.

### F9 (minor): a refused send releases the file, though the code says "send again" uploads anew

**Where:** `catalog/schema_actupload.go`, `ReleaseStaged` (`actUploadLiveSQL` has no `'refused'`), against
`telegram/act_upload.go` `sendUpload`'s comment. That comment says FILE_PARTS_INVALID and FILE_PART_N_MISSING
are "never remembered: the owner's 'send again' uploads anew".

**The state that leads there:** with a "refused" state, the next prune clears the name and removes the bytes.
- `sendClickAgain`'s clause then refuses the repeat ("not in that state"), and the trigger would too.
- But `actAgainFrom` offers "send again" from `'refused'`.
- So the page offers a "send again" that is always refused, exactly for the upload's own refusals, where a fresh
  upload is the cure.

The brief lists "refused" among the final outcomes, so the release itself follows the brief.

**Fix:** keep the file live for a refusal whose word is one of the upload's own (FILE_PART*, FILE_PARTS_INVALID,
FILE_PART_SIZE_*), or put the comment right and have the state route not offer "send again" for a released
upload.

### F10 (minor): a write transaction every minute per account

**Where:** `ReleaseStaged`, from `pruneStaged`.

Every minute and at every wake (every upload turn, outcome, cancel and verdict), each running account opens a
`Batch` (BEGIN IMMEDIATE) with an UPDATE, whether or not it ever had an upload. That is a writer lock taken
beside the downloads' writes for nothing.

The literal `86400000 * 7` in `actUploadLiveSQL` should come from `ActTextDays`.

**Fix:** skip the release when the account has no `c_act_upload` row with a name (one read), and build the
bound from the constant.

### Notes (no change asked here)

- The viewer's word table (`internal/viewer/act.go`, around line 305) has no line for `catalog.ActNonePhoto`. It
  is the viewer track's to add before a photo's candidates are shown. Not this branch's files.
- An upload being uploaded is not offered by `NextClick`, so the clicks queued after it go first (see F4). Say so
  on the page, or keep the queue's order.
- `supports_streaming` is not set (the report says so). Clients then download a video in full before playing it.
  The first real use will show whether that is wanted.

## Checked and found right

- **The account loop is never held by an upload.**
  - The parts, their waits and the probe run in the worker.
  - The turn only checks (`ErrUploadNeeded`) and hands the click over (`HandUpload`). After the parts it sends one
    `sendMedia`.
  - The one request in the turn is `help.getAppConfig`, once a session, through the pass, bounded.
- **Concurrency, read as a race detector would.** Each shared field and its guard:

  | Field | Guard |
  |---|---|
  | `up.cur`, `up.curCancel`, `up.staged` and the `stagedFile` fields after publication | `up.mu` |
  | `up.started`, `up.actor`, `up.prog`, `up.max`, `up.maxWanted`, `up.saidPrune` | atomic |
  | `up.wake`, `up.done`, `up.stop` | written once inside `once.Do` before `started.Store(true)`; read only after `started.Load()` |
  | `maxFailed`, `maxFails` | reader goroutine only |
  | the Actor's counts, `capMax`, `upMax` | `a.mu` |
  | memo, Counters, Forwarder | their own mutexes |

  - The per-sleep wake goroutine always ends (`stop` is closed).
  - Cancel's two signals (`curCancel`, and `UploadState` before each part) cover the window before `cur` is set.
  - I saw no deadlock: no lock is held across a call that takes another.
- **One upload at a time, one part at a time.** A stop during a part or a wait ends the click "not sent":
  - the context ends the sleep;
  - `StopUploading` marks the handed clicks;
  - `NextClick`'s loop marks the ready ones.
- **The part rules.**
  - A stated wait is recorded, then slept in full plus the margin (taken at most 48 h, the house rule), and the
    part is sent again.
  - No answer is sent again at most 3 times (4 sends), only in `onePart`.
  - A refusal ends the upload with its word.
- **The send.**
  - `messages.sendMedia` only with `act.Upload`, which comes only from a row with `ready_ms`.
  - It goes once through Begin and `report`.
  - The re-check after Begin is the account's refusal, frozen, the kind's frozen record and the mirror.
  - A wait is reported, not slept. A lost answer is "not known".
  - "Send again" reuses the chain's random id, so a repeat of an upload that did arrive is "sent before", not a
    second post.
- **The two-minute rule.**
  - Begin's age is from `ready_ms`: NULL before it, so neither begun nor "not sent in time".
  - The sweep counts from the click until the hand-off, then not at all, then from `ready_ms`.
  - `HandUpload` and `UploadReady` are compare-and-sets.
  - No double Begin.
  - "Never begun" happens only under F1 and F2.
- **The stage route.**
  - Guard and secret: the door's own `doorGuard`.
  - It is refused during a held stop.
  - A size limit that is not known is refused ("limits unknown") and wanted.
  - The disk check is the size plus a tenth.
  - A short or long body is refused, and its partial file removed (`MaxBytesReader` and `LimitReader` of size+1).
  - One staged file per account.
  - No path a caller can steer: the file is named `a<account>-<32 hex>.bin`, from a number and a random id. The
    header's name and type are never used in a path.
  - **The 30-minute deadlines hold on the real listener:** `TestProbeA3StageOutlivesTheServerLimits` sent a body
    over 1.5 s under a 0.3 s read and write limit, and got 200.
  - A stop closes the connections after its bound, so the partial file is removed.
- **The ffmpeg probe.**
  - One process, `exec.CommandContext` with `ProcessLimit` and the 30 s bound.
  - Its arguments are fixed, with `file:` and the app's own path: no option injection and no other protocol.
  - The whitelists, a hidden window, no text kept from the start error.
- **The media, bit for bit.**
  - A photo is `inputMediaUploadedPhoto` with flags 0.
  - A document has the filename attribute; a video adds `documentAttributeVideo` with flags 0.
  - "As a file" is `force_file` (bit 4) only.
  - Over 10 MB it is `inputFileBig` and `saveBigFilePart` with its total.
  - No thumbnail, spoiler, timer or cover.
- **The catalogue.**
  - Every value of `c_act_upload` is checked.
  - The trigger refuses a released or caption-cleared repeat, and the index serves the staged look.
  - The purge deletes the rows before `c_act`. No other place deletes `c_act` rows.
  - `scanUpload` fails closed. `NextClick`, `BeginClick`, `SweepOldClicks` and `sendClickAgain` are as the report
    says.
  - Piece 1's later check `checkChatActTables` runs before this step's trigger exists. It would fail closed if the
    order were ever reversed at the merge.
- **The settle.**
  - A document needs size, name, caption, reply, topic, never edited, exactly one message in the window, and no
    other click that may carry it. Then the 7 days' guard and the gap check.
  - A photo is never "arrived": `other` is `ActNonePhoto`, so `judgeSettle` never sets `arrive`.
  - Videos are `tg_media.kind = 'document'` in this catalogue, so they match.
- **Privacy.**
  - No name, path, caption or id in any log format or error text.
  - `errType` and `errWord` give type names and fixed words.
  - Ffmpeg's start error is dropped.
  - A part's word is a Telegram constant, or "rpc".

## Verdict

**Not ready to list. F1 and F2 must be fixed first.** F3 and F4 should go in the same round. Each fix is a few
lines, and the probes above can become the regression tests (F3's needs a seam for the interleaving, or the
reordering checked by a test that stages between the two looks). The rest is sound and carefully done: the
turn/worker split, the ledger's compare-and-sets, the stage route and the settle all hold up.

**The named tests that most need the race detector** (after the fixes):
1. `TestClickUploadCancelOneAtATimeStop`: the owner's cancel against the worker, the session's stop during the
   parts.
2. `TestClickUploadLoopNotHeld`: the reader turn and a text click beside a running upload.
3. `TestClickUploadThroughTheDoor`: the stage, the queue, the worker and the turn across the door's goroutines.
4. F1's regression test: a reader-task restart, then an upload (the worker's start and stop on `up`).
5. F3's regression test: a stage beside a prune (`up.staged` against the folder).
6. `TestClickUploadPartRules` and `TestClickUploadStagedHour`: the worker's sleep, its wake goroutine, the hour.
7. `TestActUploadStop`, `TestActUploadPartWaitSleptThenSentAgain`, `TestActUploadOnePartAtATime` (telegram): the
   stop, cancel and clock inside `UploadParts`.

## Second look (F1, F2, F4)

**Scope:** `a187a1f5..d6439fba` (dd96bf44, f0a4b3c8, d6439fba), with the report's section 8, read for F1, F2 and
F4 only. 2026-11-22.

**Probes:** two new ones in the `review-a3` folder, both loaded with `-overlay`:
- `probe2_catalog_test.go` (`overlay2.json`);
- `probe2_collector_test.go` (`overlay3.json`).

Nothing was edited. The runs were named tests only, `GOMAXPROCS=2 GOGC=25`, each started after waiting for the
race run's CPU load to fall.

### F1: fixed

The worker is now one `uploadRun` behind `up.run`.
- `startUploads` and `stopUploads` run only on the reader task's goroutine (`clickStep`, `clicksStopped`), so two
  starts never race.
- A run is replaced only when it is absent or its `done` is closed. `stopUploads` swaps it to nil, cancels it and
  waits.
- `wakeUploads` reads the pointer atomically.
- A worker that panics is recovered, closes `done`, and the next step starts another.

**Two workers at once** happens only past `uploadStopBound` (15 s). Then the old run is cancelled but still inside
one request or write while the new one starts. The old one sends no further part: `onePart` checks the context,
and its end is `ctx.Err()`, with nothing written. Then it exits.

The fake showed this overlap: its held part does not return on cancel, so the stop's bound was reached. With
gotd, a cancelled request returns at once.

**Acceptable.** The one consequence is under F2 below.

### F2: fixed for the named paths; one restart path remains

**These paths no longer re-upload:**
- the end not written: the click is stuck and skipped;
- the state read failing: the click ends "not sent" (`ActWhyStore`), and is stuck if that write fails;
- a panic in one upload: `uploadSafe` ends the click "not sent", and it is stuck if that fails.

`TestClickUploadEndNotWritten` covers the first two.

**Stuck clicks are ended later:**
- `stuck` lives on the session, so it survives a reader restart;
- a stuck click is handed and not ready, so it is ended by `StopUploading` at the session's end;
- failing that, by the next session's `StopClicksBefore` or the next start's sweep.

**The pause is right:** 30 s, doubling, at most 10 minutes. It is set back by a write that works and is slept on
the clock, with no spin: the sleep is the smaller of the tick and the pause's end, and at least 1 ms.

**Remaining (minor, CONFIRMED by probe):**
- **The path:** the reader task restarts while a click's parts go up, and `clicksStopped`'s `StopUploading`
  cannot be written.
  - The old worker ended by its context and recorded nothing, so the click is neither ended nor stuck.
  - After a restart `st.swept` stays true, so `StopClicksBefore` does not run again.
  - The new run's worker takes the click and uploads the whole file a second time, from part 0, under a new
    file id.
- **The probe:** `TestProbeA3RestartUploadsTwice`.
  - 3 parts, the second held at the fake.
  - A trigger refuses an upload row's state change while the reader is panicked, and is dropped after the
    restart.
  - Result: `one click of 3 parts across the restart: 5 part requests; the click "done"`.
- **How far it goes:** at most one extra upload per reader restart, and only when the stop's write failed. It
  never sends twice: one `sendMedia`.
- **Fix:** when `uploadOne` ends by its context with the click not ended, add it to `up.stuck`. Or have
  `stopUploads` add the running `cur` to `stuck` before it returns.

### F4: the reuse is right in what it sends; the hour can be stretched by a chain

**Checked and right:**
- **Another file or account:** a "send again" cannot carry parts of either. The trigger copies only the
  `again_of` row's own `c_act_upload`: the same staged file, `file_tg`, parts and video facts. `sendClickAgain`
  copies the account and chat from the same row.
- **Begin, never twice:** the reused row is queued, handed and ready at its own click.
  - `NextUpload` never offers it (it is ready).
  - `NextClick` offers it to the turn, which runs every check again, Begin (age from `ready_ms` = its click, the
    2 minutes), the re-check and one `sendMedia`.
  - Begin's compare-and-set and the chain's shared random id rule out a second post.
- **The two INSERTs** are exact complements: `ready_ms IS NOT NULL` guards the NULL case. So exactly one file row
  is made.
- **States:** the reuse applies only from "waited" and "not sent".
  - "Not known" uploads anew; the random id then answers "sent before" if the first try arrived.
  - "Refused" FILE_PART* (and FILE_PARTS_INVALID) keeps the staged file live, and the next "send again" uploads
    anew. That happens only on the owner's click: nothing ends or resends by itself.

**Not right (should fix, CONFIRMED by probe): the hour can be stretched.**
- The repeat's `ready_ms` is set to its own click (`NEW.clicked_ms`), and the next repeat's window is judged
  against that.
- A chain of "send again"s, each within an hour of the one before, therefore carries parts uploaded long before.
- **The probe:** `TestProbeA3ReuseChainPastTheHour`.
  - The parts end at 0; the send is stopped by the cap.
  - Send again at 50 min: reuse. Stopped by the cap again.
  - Send again at 100 min: still reuse.
  - Result: `the parts of t0 are carried 100 min after their end (the bound is 60 min)`.
- **How far it goes:** Telegram answers parts it no longer holds with FILE_PART*. That is a refusal, the file is
  kept, and the next click uploads anew. So the harm is one wasted send, never a wrong file.
- **Fix:** keep the parts' own end in a column of its own (e.g. `parts_ms`, copied through the chain and set once
  by `UploadReady`). The trigger judges `parts_ms >= NEW.clicked_ms - 3600000`; `ready_ms` stays the age mark.
  The literal `3600000` should also come from `ActUploadReuseMs`.

### Verdict

- **F1 is fixed.**
- **F2 is fixed for every path named in the review.** One further restart path is minor (bounded, no second
  send). Its fix is a line.
- **F4 sends the right file once and only through Begin,** but its one-hour bound can be chained past (should
  fix, small).

The branch can be listed once the F4 chain is fixed. The F2 restart path can go in the same commit or be listed as
known.

**Race detector, for these fixes:**
- `TestClickUploadAfterReaderRestart`;
- `TestClickUploadEndNotWritten`;
- `TestClickUploadWorkerPanic`;
- `TestClickUploadSendAgainKeepsTheParts`;
- this look's `TestProbeA3RestartUploadsTwice`, once its fix lands (`up.run` swap, `stuck` across runs).
