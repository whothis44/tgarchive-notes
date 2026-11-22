# Independent review of K20, downloads only in hours without the speed limit (`wip/core-unl` f5e5291f)

Reviewer: an Opus agent for Core (K-6), 2026-11-22. Scratch copy `wt-core-unl-review` (detached at f5e5291f, removed after).
Probes by `go test -overlay` only, every go command through `runs-core-k5/go2.sh`; invented data, the fake transport and
temporary catalogues only. Nothing ran against Telegram; no branch or copy of the coder's was touched.

## Verdict: NOT READY. Two musts, both confirmed by probes

1. The mark fails open: three paths make a file wanted only through an "unlimited" chat download under the limit.
2. Under the limit as the coder's own tests model it, the lane opens and shuts **every 2 minutes**: 88 requests and 29
   opens in an hour that was limited throughout, where the brief expects about 6 probes.

There are also two "should" findings where the lane stays shut for ever (confirmed), and two minors. The rest holds: the
walk (every range names `unl`, the shut spread walk goes through `c_lane_chat_unl`, and the pick costs the same with 0 and
100,000 waiting files), the held gate, the triggers for the chat's value, switch and kinds and for attachments, the
schema step and the counters' plumbing. The coder's tests pass: catalogue `TestUnl|TestNewChats` ok, and the engine
package as a whole ok in 43.6 s.

## Findings

### M1 (must, CONFIRMED): the mark fails open. `internal/catalog/schema_unl.go:93-95` (`unlSQL`), `:78-86`
The "always" side asks only `collectsKindSQL`. It does not ask `liveCarrierSQL` (K24) or `topicPassSQL`, but both are part
of what makes a file wanted (`collectedSQL`, `topics.go:68-76`). Probe `TestK20RevFailOpen*`: in each case the file was
wanted only through the live "unlimited" chat, and the result was `unl = 0`, with `LaneNext{UnlShut}` handing it out:
- **R1a**: the app's own channel (always, collecting) that the old account also read. The message carrying the file was
  sighted only by the brought-in account. The bring-in puts old messages into the app's existing chat row (into.go rule
  2: "a chat the app has keeps its own facts"), so this does not depend on how bring-in makes chats. It is the unified
  archive's ordinary case.
- **R1b**: an old-only chat switched on in the app. Its `dl_when` defaults to `always` (`collect_off 0`, `dl_when always`).
- **R1c**: an "always" forum chat that collects only chosen topics, carrying the file in a topic that is not chosen.

**On the coordinator's question (copies, C7):** that claim is right for chats the bring-in itself makes. Under
`-into-app` they are made switched off, and a chunk that made one collecting is undone and the run stopped
(`internal/bringin/into.go:352-354` on `wip/b-unified2`, `ErrChatCollecting`). Such a chat is therefore never "always and
collecting" unless the owner switches it on, which is R1b. R1a and R1c do not involve a chat the bring-in made, so the
fail-open stands.

**Fix, the exact condition:** `unl = (some carrier in an 'unlimited' chat) AND NOT (some carrier in a chat with dl_when <>
'unlimited' AND collectsKindSQL AND topicPassSQL AND liveCarrierSQL)`. In other words, the always side is `collectedSQL(media,
true)` restricted to non-"unlimited" chats. The "unlimited" side can stay as it is (it fails closed). Then add triggers or
settle intents for what the new terms read:
- `topics_only` in `unlChatChanged`;
- a change to `topic.chosen` (settle the space);
- `message.topic_id` moved (`tgrows.go:383`);
- a live account's sighting of a message coming or going (K24's "seen again" path);
- `account.brought_in` set (a chunked recompute).
Extend `unlDrift`'s cases to cover them.

### M2 (must, CONFIRMED on the fake): under the limit the lane flaps every 2 minutes. `internal/engine/lift.go:94-104` (`openUnl`, `liftNext` reset at line 99), `lane.go:2481`
The probe `TestK20RevFlapUnderTheLimit` uses the coder's own model of the limit from `TestLiftShutLaneNeverTakesUnl` and
`TestLiftGivenBackAtTheLimit`: a request is answered when 8 s or more have passed since the last answered one, and every
other request gets FLOOD_PREMIUM_WAIT_15. The hour was limited throughout, and the lane held only waiting files. In 60
minutes:

| What | Count |
|---|---|
| Requests | 88 |
| Probes (all 30 clean) | 30 |
| Parts of waiting files fetched | 59 (about 59 MiB, against the owner's estimate of about 6 MB an hour) |
| Speed-limit waits | 29 |
| Opens | 29 |
| Shuts | 29 |
| Files given back | 58 |

Each cycle: a lone probe after idle is clean; 2 quiet minutes pass; the lane opens and claims 2 files; the first
speed-limit wait shuts it and gives both back. `openUnl` zeroes `liftNext`, so the next probe goes out at once, not after
an interval. Every cycle is about 3 claims, which in real use means reference refreshes. Bytes below the 8 MiB checkpoint
are fetched again later. This is the "never a loop of claim and give back under the limit" the brief forbids, and the
flapping the record warned about (NOTE-K20, "open design points"). An isolated request tells little when the limit allows
roughly one part in 19 s.

The coder's "7 requests in 65 minutes" comes from `TestLiftProbeEachInterval`, whose fake never answers a request under
the limit.

**Fix:**
- Never reset `liftNext` on an open, so that a shut after an open waits a full interval.
- Make an open from probe evidence a trial: only the probe file runs, at the window, for `LimitedQuiet`. Other waiting
  files are claimed only if no speed-limit wait came in that time. A wait during the trial shuts the lane and keeps the
  probe file, with no give-back churn.
- Count trials.

Because this goes beyond the owner's "an answer without a speed-limit wait opens", put it on "Waiting for the user" with
these numbers.

### S1 (should, CONFIRMED on the fake): the lane is shut for ever when the first 4 waiting files are not plain. `lift.go:168-193` (`liftLook`, `liftAsk = 4`)
The probe asks for only 4 files per size class and takes only a plain one (no `Check`, `HoldUnlessSame` or `Plan`). Probe
`TestK20RevNoPlainProbeFile`: the server was not limited at all, 4 waiting files marked for the exact check came first and
a plain one fifth. Over 60 minutes there were 0 requests and 0 probes, and the lane stayed shut. Meanwhile the state read
"one part of one of them every 10m0s or more tells when the limit lifts". The same happens when every waiting file of a
server has a frame-check plan.

**Fix:** ask again with the files already seen excluded, up to a bound. Failing that, let the probe use a `Check` file's
part with its check left until the lane opens. Count "no file to probe with" and say it in the words.

### S2 (should, CONFIRMED in the catalogue): held waiting copies (tier 5) never count as waiting. `schema_unl.go:332-333` (`laneUnlWaitingSQL`, `tier IN (1, 2, 3, 4)`)
Probe `TestK20RevTier5NotWaiting`: one `unl` held probable copy at tier 5. `LaneUnlWaiting` returned false, while the
probe's own ask (`UnlOnly`) handed it out. On a server whose only waiting files are such copies there is then no probe and
no open, even in unlimited hours, and the lane reads "nothing to do" instead of "waiting for hours without the speed limit".

**Fix:** include tier 5 (the supply guard already covers its state) or, if the exclusion is intended, say so in the words.

### m1 (minor, PLAUSIBLE by reading): a waiting file claimed while the lane was open can join after it shut. `lane.go:521`, `:709`
The hint is taken at `startClaim`. If a speed-limit wait shuts the lane while the claim goroutine runs, the waiting files
it claimed join a shut lane. They download under the limit until the next wait.

**Fix:** in the block at line 709, also give back `got` files with `f.Unl && !x.lift`, and count them.

### m2 (minor, PLAUSIBLE): an open can rest on an answer to a request sent before the last speed-limit wait. `lane.go:2481`, `lift.go:95`
`lastClean` is the answer's end, not when the request was sent.

**Fix:** keep `lastClean` only for requests sent after `unlQuietFrom`.

### Notes (not defects)
- There is one lane per account and server, so N accounts mean N probes per server per interval. That is right if each
  account's allowance is its own, as the record says.
- The interval holds from the next start of the engine (the coder's point 5). After a restart the first probe goes out at
  once, but any wait on record is still slept.
- For the integrator: a later step that rebuilds `c_supply_src` must start from `supplySrcUnlSQL`. One built on
  `supplySrcBroughtInSQL` breaks `INSERT INTO c_supply SELECT *`, but loudly. Copies' `HeldProbeNext` follow-up for `unl`
  is still owed.
- The coder's point 6 (within one chat, a lane that is not shut walks the waiting files after the others) is fine.
- `UnlWaiting` (the pages' count) drops a file once it is saved (probe R5): fine.

## Race detector (point 6)
- **Run under it:**
  - `internal/engine`, whole: the lane's claim goroutine now calls `liftLook` outside the lock, and `unlShut`,
    `liftNext`, `unlWaiting` and `lastClean` are new state.
  - `internal/supply`: the new `unlShut` map, guarded by `s.mu`, is touched from every lane's Next and Claim; at least
    `TestUnlSupply` and the supply's concurrent tests.
- **No race run needed:**
  - `internal/catalog`: SQL only, no goroutine.
  - `internal/collector`: the interval is read once at the engine's start.

## Probes and results
All probe files were in the scratchpad, fed to the build by `-overlay`, and are not committed.

| Probe | What it showed | Result |
|---|---|---|
| Catalogue `TestK20RevFailOpenOldOnlyMessageInAppChat` (R1a) | `unl` 0, file wanted, shut lane takes it; control file `unl` 1 | FAIL |
| Catalogue `TestK20RevFailOpenOldOnlyChatOn` (R1b) | chat `dl_when always`, `collect_off 0`; `unl` 0, shut lane takes it | FAIL |
| Catalogue `TestK20RevFailOpenTopicRule` (R1c) | `unl` 0, shut lane takes it | FAIL |
| Catalogue `TestK20RevTier5NotWaiting` (R4) | tier 5, `unl` 1; `LaneUnlWaiting` false; probe ask returns the file | FAIL |
| Catalogue `TestK20RevUnlWaitingCountsSaved` (R5) | count 1 before the save, 0 after | pass |
| Engine `TestK20RevFlapUnderTheLimit` (E1) | the 60 limited minutes in the table under M2 | FAIL |
| Engine `TestK20RevNoPlainProbeFile` (E2) | 60 unlimited minutes: 0 requests, shut, plain file still wanted | FAIL |

Also run:
- Catalogue `-run 'TestUnl|TestNewChats'`: ok, 17.2 s together with R5.
- `internal/engine` whole: ok, 43.6 s.

## Second look: the fix round (`wip/core-unl` edea54d6, code in b0931548), 2026-11-22

**Verdict: M1, M2, S1 and S2 are resolved; one new fail-open path should be fixed before the merge (R8, a
migration, small); nothing else blocks.** Scope as asked: M1 (with other paths and the bring-in's scale), M2 (the
model with the trial off and at 2 minutes, and the coder's one-part gap), S1 (the re-ask's bound). Detached copy
`wt-core-unl-review2`, probes by `-overlay`, every go command through go2.sh; invented data; removed after.

### M1: resolved; one path left (R8)
- R1a, R1b, R1c re-run unchanged: `unl` 1 in all three, and a shut lane does not take the file (they were 0 and
  taken at f5e5291f). The coder's `TestUnlReview*` (7 tests) pass.
- Other paths, each a probe, each with the drift check (`unl_wrong`, `c_supply`, `c_lane_chat` all 0):
  - R6, a live sighting of the always channel's message removed: `unl` 0 then 1. CORRECT.
  - R7, the second live account (the only live sighter) deleted (`DeleteAccount`, its sightings deleted in
    chunks, so `unl_sighting_ad` fires per row): 0 then 1. CORRECT.
  - R9, the always chat's carrier made the alternative version (`unl_att_au` on `role`): 0 then 1. CORRECT.
  - **R8 (should, CONFIRMED): a migration drops the chat's download hours.** `rows.go:337-341` (EnsureChat), `tgchats.go:265-272`
    (saveMigration). An "unlimited" basic group becomes a supergroup; the successor's row is made by the policy
    for a new chat, and `dl_when` does not follow `migrated_from`. With the stored setting "always": the successor
    collects with `dl_when always`, so the group's files download under the limit (the fail-open of M1, by
    another door). With "off": made switched off with `dl_when always`, so switching it on makes it "always".
    TRIED-BEFORE rule 12 (a person's mark follows the item across a change of id). Fix: when saveMigration links
    a successor it just made, copy the group's `dl_when` to it (one UPDATE beside the `migrated_from` one). The
    collect switch does not follow either (K28's, not this piece's): worth the same line on the board.
- The triggers and the "unl all" settle are complete for what `unlAlwaysSQL` reads (kinds and switch, topics_only,
  topic chosen / coming / going, a message's topic, attachments and roles, sightings while a brought-in archive
  exists, `brought_in` set or cleared). Not covered, by reading, and not worth a trigger: a `tg_media.type` change
  and a message moved to another space by hand-written SQL.
- **The bring-in's scale (timed, `TestK20R2Scale`):** an old account reaching 300,000 files (300 channels of 1,000,
  each file with its message, sighting, attachment, collector row and reach), the brought-in mark set:

  | | no unlimited chat | one unlimited chat |
  |---|---|---|
  | MarkBroughtIn (K24's own work) | 6.29 s | 6.20 s |
  | Settle after it ("unl all") | 1 ms (nothing) | 587 ms: 154 chunks, the longest 6.6 ms |
  | 20,000 live sightings of old messages, one statement | 71 ms (3.6 us each) | 207 ms (10.4 us each) |

  Cheap. One note: between the mark and the next Settle the marks are as before the mark (MarkBroughtIn does not
  settle at once); with "unl all" at 0.6 s for 300,000 rows the window is the Supply's settle interval. Minor.

### M2: resolved under the owner's rule; the one-part gap matters only with the trial on
The 60-minute model (an answer when 8 s or more since the last one, every other request FLOOD_PREMIUM_WAIT_15,
limited throughout, only waiting files, interval 10 minutes, no jitter), `TestK20Rev2Model`, 60 waiting files:

| 60 limited minutes | requests | probes (clean / limited) | parts | waits | opens | shuts | given back | trials | saved |
|---|---|---|---|---|---|---|---|---|---|
| f5e5291f (first look), 40 MiB | 88 | 30 (30 / 0) | 59 MiB | 29 | 29 | 29 | 58 | - | 0 |
| trial off, 40 MiB | 17 | 7 (6 / 0) | 6 MiB | 10 | 5 | 5 | 5 | 0 | 0 |
| trial 2 min, 40 MiB | 17 | 17 (6 / 10) | 6 MiB | 10 | 0 | 0 | 0 | 5 | 0 |
| trial off, 300 KiB photos | 17 | 7 (6 / 0) | 1.8 MiB | 10 | 5 | 5 | 25 | 0 | 6 |
| trial 2 min, 300 KiB photos | 17 | 7 (6 / 0) | 1.8 MiB | 10 | 5 | 5 | 25 | **0** | 6 |

- Trial off (the owner's rule): at most one open an interval, about 6 MiB an hour (the owner's estimate), the same
  as the coder's `TestLiftUnderTheLimitModel`. The cost to know: each open claims the lane's free slots (with
  small files 5), all given back at the first wait: 25 claims (reference refreshes) an hour per limited server with
  photos, 5 with 40 MiB files. That is the owner's rule as it stands, not a defect.
- **The one-part gap (should, CONFIRMED, only with the trial on):** a probe file that finishes in one part
  (`lift.go` openUnl: the trial needs `hasLift()`) never starts a trial: with photos the trial at 2 minutes gives
  exactly the numbers of no trial (0 trials, 5 opens, 25 given back). The probe asks the small class first, so on a
  server whose waiting files are photos, voice notes or small documents the trial never runs. Fix: with the trial
  on, when the probe file is saved before the trial began (or has one part), claim the next waiting file as the
  trial's file and run the trial on it; or pick a probe file of more than one part while the trial is on.

### S1: bounded, never per pick
- `liftLook` (`lift.go`): at most 4 asks of 16 per size class, the seen ones passed over by `NextHint.Skip`
  (into `LaneOptions.Exclude`), only on a probe due (once an interval, 10 to 15 minutes, per shut idle lane):
  never on a pick. The pick of a lane (open or shut) does not see Skip.
- The real bound is larger than "64": each of those asks is the Supply's `Next`, which asks again when files were
  passed over (marked look-alikes the pen cannot take now), at 8 and 64 times the files missing
  (`supply.go` the `round` loop): at most 16 + 128 + 1,024 rows an ask, about 9,350 rows and their index lookups
  per probe in the worst case (both classes, 4 asks). Still a constant, once an interval; fine. Say it in the
  comment (minor).
- With none plain in those, the lane counts `LiftNoFile` and says so; it then waits for another file of the server
  to show the lift (by design; a server whose first files all want a check stays shut while idle: minor, the words
  say it).

### Probes (scratchpad, by `-overlay`, not committed)
Catalogue: R1a-c, R4, R5 again (all as fixed), R6, R7, R9 (pass), R8 (FAIL: the successor `dl_when always`,
collecting under "always"), the scale (above); the coder's `TestUnlReview*` ok. Engine: `TestK20Rev2Model` (the
table), the coder's `TestLiftUnderTheLimitModel` and `TestLiftProbePastCheckFiles` ok.
