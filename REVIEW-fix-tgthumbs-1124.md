# Review: sharp previews and "Download this file" (wip/tgthumbs 5c0ba941 on d014680)

**Verdict: fix first.**

One independent Opus review of 578bd9fe (sharp previews) and 5c0ba941 (download a file that is not downloaded).
Both MED findings are small changes inside `internal/collector/previews.go`. The release (5c0ba941) has no blocking
finding.

Runs (this PC, GOMAXPROCS=2): vet of catalog, collector, collector/faketg, server, telegram and viewer clean; gofmt clean;
`collector -run 'Preview|Release|Download|TestAssets|Door'` ok (98 s); `catalog -run 'Schema|Step|Preview|OwnerDownload'`
ok (55 s); `telegram -run Preview` ok; `server -run 'TestAssets|Security|Setting|Previews'` ok (the browser tests skip as
before; TestDoorRelease runs, not skipped); `viewer -run 'TestWall|TestHomeDevice|Security|Act|Release|Thumb|Preview|Sharp'`
ok (51 s). The race detector was not run. A scratch worktree was used for one query probe and then removed. The branch was
not changed.

## MED 1: previews ignore the engine's gates and check holds
`internal/collector/previews.go:167-171` (`previewsMayGo`) holds previews back only on `FilesActive`, `InFlight`, `Sleeping`
and `SleepingFreed`. It does not look at `LaneStats.GateUntil`. That field is the lane's "sends nothing new before this":
the gate Telegram's escalation closes (`engine/guard.go:140-195`), the account gate, the transport's recorded wait
(`recUntil`) and the policy hold (`engine/guard.go:200-212`). It also ignores `ChecksHeldUntil` and `ChecksRunning`.
- Failing case: a 600 s FLOOD_WAIT on a part closes the DC 4 lane's gate, and SaveHold records HoldLane. The program
  restarts. The file's own wait is on record (`retry_at`), so it is not supplied, and DC 4 has no other wanted file. After
  the restart, `HoldLane` puts `gateUntil` back (`engine/engine.go:515-531`). The lane shows `FilesActive=0`, `InFlight=0`
  and `Sleeping=0`, so previews go. The task then sends `upload.getFile` (thumbnail) on DC 4 inside the window in which the
  engine itself sends nothing because Telegram escalated there. The same happens in one run when a gated lane has no file.
  If two servers escalate (`HoldAccount`), every server of the account is affected.
- At session start `s.eng == nil`, and line 164 returns true. A preview can therefore go before the engine's first turn has
  loaded the recorded holds.
- Fix: hold while any lane has `GateUntil.After(now)`, `ChecksHeldUntil.After(now)`, `ChecksRunning > 0`, `NetworkAway`,
  `Frozen` or `SignedOut`. When `s.eng` is nil, do not go until the engine has run its first turn, or read the same hold
  records the engine loads (HoldLane and HoldAccount with an end in the future). Add these cases to `TestPreviewsMayGo`.

## MED 2: the reference refresh sends unpaced bursts on the main connection
`internal/collector/previews.go:308-318`: one `Refresher.Refresh` call takes `t` and up to 19 other files of the background
list on the same server. The list is newest first across every chat. `Refresh` sends one request per chat, back to back,
plus follow-up rounds up to `MaxCarriers` (3) for carriers that are gone (`telegram/refresh.go:385-455`). The pace is
applied only after the whole call (line 319-321).
- Failing case: the 20 newest unsaved photos on DC 2 come from 20 channels. One step then sends 20
  `channels.getMessages` within a second or so on the main connection, and up to 60 if carriers are gone. The readers and
  the mirror use the same connection. The Settings page tells the owner "8 to 12 seconds between two preview requests" and
  "one request for up to 20 files of a chat" (`server/previewsetting.go:26-28`). `TestPreviewsBackground` puts every file
  in one channel, so it never sees this.
- Telegram's waits on these requests are held correctly: `wait:refresh` is per account. Because that record is shared, a
  wait that a preview burst brings on also holds the engine's claim-time refreshes, so previews delay downloads.
- Fix: refresh only files of `t`'s chat. Add the space of the newest sighted message to `PreviewTarget` and batch only
  targets with the same space, which gives one request a step. Alternatively, pass at most one chat's files per call and
  leave the next chat to the next paced step. Add a test with files spread over several chats that checks the gaps between
  refresh requests.

## LOW 3: the downloads-first check is not re-checked before sending
`previews.go:276` checks `previewsMayGo` once per step. The refresh (one or more requests on the main connection) and the
fetch (`previews.go:370`) follow with no second look. The engine can claim a file and send parts in between. Its view
(`lane.publish`) is a copy that can also lag. At most one preview request overlaps a download, so this is not a rule
breach, but "never while a lane is mid-part" is not strictly true. Fix: check `previewsMayGo` again immediately before
`FetchPreview`, and before each Refresh call once MED 2 is fixed.

## LOW 4: the Queue page mislabels files the owner asked for
`catalog/ownerdownload.go:141` marks a clicked file `wanted_first = 1`. `server/web/assets/js/pages/queue.js:454` shows
that mark as "first (on another archive's not-saved list)". Failing case: the owner clicks "Download this file" on a held
photo, and the Queue page then says it is on another archive's not-saved list. Fix: change the words to "first (asked by
the owner, or on another archive's not-saved list)", or keep a separate mark.

## LOW 5: two release details
- `viewer/release.go:41` (`ReleaseWordsQueued`) promises: "If it turns out to be a file already saved, it is linked to it,
  not downloaded again." That holds only while the exact check before download is on (`supply/supply.go:818-825`:
  `s.cfg.ExactCheck && !s.exactOff(now)`). With the exact-check setting off, a released file that is byte-identical to a
  saved one under another Telegram id is downloaded (the ladder's SHA-256 then makes it a duplicate). Fix: make the words
  conditional on the setting, or drop the promise.
- `server/clicks.go:433` adds `actRelease` to `stopKeepsDoor`. The comment at lines 404-409 says that during a held stop
  the door "takes no new clicks", and `actQueue` is refused then. A release is a new owner action. It sends nothing, so
  this is harmless, but the code and the comment disagree. Either refuse it during a held stop or update the comment.

## LOW 6: the candidate query scans the whole tg_media table
`catalog/preview.go:262-281`: no index serves `file_id IS NULL`. The plan is a scan of `tg_media`, with three primary-key
lookups per row for the NOT EXISTS checks. The correlated date subquery runs twice, once for `d IS NOT NULL` and once for
the select and ORDER BY, and a temporary B-tree sorts the result. All other lookups use indexes (`attachment_media`,
`sighting_account`, `known_file_key`, primary keys).
- Probe, one run (synthetic data, this PC, warm cache; so "looks like"): 200k media, 150k unsaved, 200k messages and
  sightings. Each call took about 0.72 s with nothing done yet, and about 0.20 s with almost everything done.
- The query runs once per 50 files (about every 8 minutes at the default pace), but once a minute per account when the
  list comes back empty in background mode, which is the steady state. That cost is acceptable, but it is wasted.
- Fix: compute the date once (a JOIN with GROUP BY, or a MATERIALIZED CTE). Back the relist off to about 10 minutes after
  an empty answer. Optionally add a partial index `ON tg_media(id) WHERE file_id IS NULL AND thumb IS NOT NULL`, which
  needs a schema step.

## NOTE 7: costs that are not shown
- `FetchPreview` goes through `invoke`, and `FileInvoker(ctx, dc)` makes a file pool if none is open. A preview to a server
  that downloads have not used in the session therefore costs an authorisation transfer (export and import). It is counted
  under "auth transfer", but `PreviewsCost` does not mention it.
- Refreshes made for previews are counted under "refresh", mixed with the downloads' refreshes, so the hourly counts cannot
  show what previews cost on the main connection. Fix: give them a kind of their own, for example a Refresher made with
  its own counters.
- The first real run should read the hourly "preview" and "refresh" rows.

## NOTE 8: files and folders
- The viewer is no longer read-only towards the catalogue's folder: it writes `previews/asked.txt` whenever that folder
  exists (`viewer/sharp.go:111-175`). A check or tool that starts a viewer with a plain path to the owner's catalogue
  would write into the owner's folder. Use a copy, as the hard rules already require.
- `asked.txt` holds only decimal catalogue ids, at most 200 (`catalog/preview.go:206-251`).
- Previews are never deleted when the file is saved later, and `.<id>-*.tmp` files left by a crash are never cleaned. The
  folder grows by tens of KB per preview, which is about 1 to 2 GB for some 50k files, beside the catalogue.
- A preview can still be written in the moment after the file is saved. It is harmless, because the viewer serves sharp
  previews only for files that are not made and not saved (`viewer/media.go:979`).

## NOTE 9: FROZEN on a preview
A FROZEN refusal on a preview ends only the preview task (`previews.go:427-429`). The account is not marked frozen as an
engine refusal would mark it. The next download request finds out. This is acceptable; just to be aware of it.

## Checked and found sound
- **Waits.** A wait stated on a preview is put in memory first, then in the store under `wait:preview` per account, on a
  context that is not cancelled (`telegram/preview.go:156-168`). Before every fetch the record is read (`PreviewHold`), and
  a wait still running comes back as a Recorded WaitError with nothing sent. That also covers a restart, because the Parts
  memo is the catalogue's store (`collector/account.go:620`). The task adds the parts' margin and sends nothing before
  then (`previews.go:418-426`).
- **Preview waits do not reach downloads.** They live in neither the engine nor the parts' per-server notes beyond
  counting. The waits held by previews are account-wide, which is stricter than per server. Refresh waits are shared with
  the engine. The fake test shows the 9 s wait slept in full.
- **No loops, no double sends.** There is one task per account and one request at a time. A file is claimed across
  accounts. Failures back off: 20 minutes doubling to a day per file, 30 s doubling to 10 minutes per account. No path
  loops without a write or a pace; the only 10 ms re-steps follow a settle or a lost claim race.
- **The download path is unchanged.** The engine and the supply are untouched. `Locator.Preview` is filled by a pure
  function and read only by `FetchPreview`. The counters, `status_file` and the run flag are additions only.
- **Size choice.** For a photo the download's own size type is excluded (`record.go:542`, `refresh.go:717`). A document's
  thumbnail is never the document, because a size type is required and an empty one gives ErrNoPreview. An answer of a
  whole part or more is refused. The bytes must look like a picture.
- **Files and paths.** Paths are built only from numeric ids. Writes go to a temporary file, are synced and renamed into
  place. The folder is `<catalogue folder>/previews`, the app's own data. The viewer serves at most 1 MB, sniffs the type,
  and serves only files that are not saved.
- **Release.** It goes through the Queue page's `Transition`: held to wanted, aside to wanted, ReasonOwner, `released=1`.
  `fetch_real` is never set.
  - The exact check before download still runs (`supply.go:818-825`), and `LinkSame` links a file with the same hashes even
    when it was released (it reads only `fetch_real`).
  - The release refuses a saved file, a file on the saved list of an imported archive (`known_file` with `saved=1`), and an
    exact edge to a saved file.
  - A probable copy is asked about first: the `probable` mark, or a probable reason including kept-held, three-place
    matches, frame copies and the old app's holds.
  - A skipped file is answered "already", and a gone file "gone".
- **Doors.** On the door: the secret, refusal of the page token, Origin, Cookie, Sec-Fetch-* and other methods, a body
  bound, 1 to 100 distinct ids, and unknown fields refused (TestDoorRelease). On the viewer: this PC only (`classLocal`
  plus the handler's own refusal of the LAN listener), the page token, the closed route set (8 routes, 16 checks), the
  index check, saved files answered locally, and the door's answer checked against its form and closed outcome set.
  TestWall and TestHomeDevice pass.
- **Schema step 47.** `CREATE TABLE IF NOT EXISTS`, refused at any version other than 46, no rebuild of an existing table.
  The Schema and Step tests pass.
- **Privacy.** New log lines use constant format strings with only account numbers, seconds and fixed error words. There
  are no ids, names or paths.

## Second pass (the fix): 5c0ba941..60462b53

**Verdict: may be merged.** All nine findings are fixed. The fix adds two LOW issues and one NOTE. Neither LOW blocks the
merge; A is a one-line fix and is worth making in the same round.

Runs at 60462b53 (GOMAXPROCS=2):
- vet is clean on catalog, collector, server, telegram, viewer and cmd/tgarchive-window; gofmt is clean.
- `collector -run 'Preview|Release|Download|TestAssets|Door'` ok (111 s).
- `catalog -run 'Schema|Step|Preview|OwnerDownload'` ok (54 s).
- `telegram -run 'Preview|Refresh'` ok.
- `server -run 'TestAssets|Security|Setting|Previews|DoorRelease'` ok.
- `viewer -run 'TestWall|TestHomeDevice|Security|Act|Release|Thumb|Preview|Sharp'` ok.
- The branch was not changed.

How each finding now stands:
- **MED 1, fixed.** `previewsMayGo` (previews.go:180-199) now waits for `engTurned`. That flag is set only after the engine
  task's first successful look at the servers (account.go:839), whether or not an engine was started then. It holds on
  every lane's `GateUntil`, `ChecksHeldUntil`, `ChecksRunning`, `NetworkAway`, `Frozen` and `SignedOut`. It also holds on
  any `c_hold` record of the account still in force (lane, account, refresh, checks or frozen), with or without an engine,
  and refuses whenever `LoadHolds` fails. The check is made again right before each fetch and each refresh. Shorter
  in-memory gates are lost when an engine stops, as they are for the engine itself.
- **MED 2, fixed.** A separate preview Refresher asks one carrier per file (`MaxCarriers` 1), so there are no follow-up
  rounds.
  - `firstChats` computes the first carrier the Refresher can ask exactly as `reachOf` does, and the batch keeps only files
    whose first carrier is in `t`'s chat. That is one request per paced step: at most 20 ids, under MaxIDs.
  - A chat that refuses the account ends the call after that one request (ReasonNotTried).
  - Waits stay on the shared `wait:refresh` record. It is read from the store at every check (memo.go:236-258), so each
    refresher sees the other's waits.
- **LOW 3, fixed.** The check is made again before each request, as noted under MED 1.
- **LOW 4, fixed.** The Queue page's words now name both reasons.
- **LOW 5, fixed.** The "linked" words are shown only while `exact_mode` is not off. The release is refused during a held
  stop, and the comment now says so.
- **LOW 6, fixed.** The date subquery runs once (a MATERIALIZED CTE), and the list is read again only 10 minutes after an
  empty answer.
- **NOTE 7, fixed.** Refreshes made for previews are counted as `preview_refresh`, and the cost words mention the
  authorisation transfer. See B below for the timing rows.
- **NOTE 8, fixed.**
  - `asked.txt` is written only when `Config.PreviewAsks` is set, and only the app's window sets it (`joined`).
  - Previews of files saved since are removed every 10 minutes, file first, then the mark.
  - Temporary files older than an hour are removed at the start.
- **NOTE 9, fixed.** A frozen refusal now saves `HoldFrozen` through the supply, as a download's refusal does, and ends the
  session frozen. A signed-out refusal ends the session the engine's way.

### New findings
- **LOW A: a busy loop when the list runs out on files claimed elsewhere** (`previews.go:248-277`).
  - The pause before reading the list again now applies only after an empty answer (`batchAt` is zeroed after every
    non-empty read).
  - Failing case: two accounts see the same files near the end of the backlog. Account B's list holds only file X, which
    account A's task has claimed for its request. B drops X as held; the list is now empty while `batchAt` is zero, so B
    reads the list again at once, gets [X] again, and repeats. This continues inside one step, with no sleep, for as long
    as A's request runs: normally under a second, but up to the request's deadline on a bad network.
  - Each turn of the loop is a full candidate query (0.2-0.7 s at 150-200k media in the first pass's probe), so it pins
    a core on the reader connection.
  - Fix: when the batch empties by dropping held files, set `p.batchAt = now`, or return not-ok (look again in 5 s).
- **LOW B: the two refreshers share one in-flight gauge** (`refresh.go:422`, `inflight.go:87`, `timing.go:141-154`).
  - Both call `inFlight(refreshWhat, 0, false, r.pick, …)`, so they share the flight key {"refresh", 0, false}. `nameOf`
    fixes that entry's kind and name at its first use in the run.
  - As a result, the answer-time and wait-seconds rows (`timeAnswer`) and the leave-and-count `InFlightAtLoss` and
    `UnderWait` counts of one refresher are booked under the other's name. Example: a preview refresh sent first in a run
    books every later download refresh's timing as `preview_refresh`. The request counts (`r.pick(st)`) are right.
  - Fix: give the previews' refreshes a flight word of their own, such as "preview refresh", and map it to "refresh" in
    `methodWhat`, so the wait key and the flight's wait stay the method's.
- **NOTE C: the in-memory-first guarantee no longer covers both refreshers.** The guarantee ("no other lane's refresh
  passes the check after this", `refresh.go:431`) now holds per Refresher object only. Between Telegram's answer and the
  store write, the other refresher's check can still pass. The window is tiny and previews go only while downloads are
  idle, so this is acceptable as it stands.
