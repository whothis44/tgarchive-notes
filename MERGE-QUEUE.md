# Merge queue (short entries; rebuilt 11-21 22:24; everything before is in `MERGE-QUEUE-LOG.md`)

One entry per branch that is ready, in merge order, at most 15 lines:

```
<ID>. READY (<track>, <time>): `wip/<branch>` at <head>, holds main <commit>
- What it does: <two or three lines>
- Files: <packages touched; anything in another track's files>
- Schema step: <none | N, claimed on the board>
- Review: <none (why: not Telegram, not skip/delete, not download path) | one independent review: findings and fixes>
- Tests run: <named tests and small packages, with times>; whole collector/catalog: left to the integrator
- Not verified: <one or two lines>
```

The integrator marks an entry "MERGED <time> as <commit>" and moves it to the log at the next batch.

## Ready

### In the batch now testing (i6e, started 00:20; merged when it passes)

### Mirror, listed after the batch (M-7)

### Next: the UI batch (F1 first, then U2, F5, F4; the viewer's bring-in U1)

C28. READY (copies, re-listed 09:38): `wip/copies-33` at 799f18ba, holds main f0323f5b (the step after `alertAwaySchema`, 34, the newest on that head; on the merged tree: build, vet catalog, the whole `-run 'Schema|Step'` set 25.5 s and `-run 'TestAlbum|TestLookAlike|TestHold|TestTwin|TestGiveBack'` 331 s ok, gofmt clean)
- What it does: the whole-album rule, COUNTING ONLY (FEATURES: "off, counting what it would hold"; the old app's `ix_album_copies.go`, right 67 to 89%, only counted while held copies wait for good): a wanted video whose album is anchored (2 other members' close twins in one saved album of another chat) and has a twin there at 7 to 20 bits is recorded in `c_album_like`; door `AlbumLikeCounts`. No edge, no `c_want` change, no hold.
- Files: `internal/catalog` (`album_rule.go`, `schema_albumlike.go` new; `catalog.go` schema places; one call in `ladder.go`'s attach; `atsave.go`'s hold body moved unchanged into `holdCoveredStep` plus one call), tests; report `docs/progress/copies-album-rule-REPORT.md`.
- Schema step: 36 in merge order (`albumLikeSchema = albumLikeAfter + 1`).
- Review: one independent (`REVIEW-C28-album-rule.md`): the save path identical by a differential probe; a failure undoes only the rule; nothing else written; Q4 (targets from edges only: the count ran high) fixed with a test. No second pass (a count, no hold).
- Tests run: `-run 'TestAlbum|TestLookAlike|TestHold|TestSchema|TestTwin|TestGiveBack'` 493 s ok on the merged tree; vet catalog; `TestAlbumLikeNothingElseMoves` compares every table. Cost per attach 0.4 to 0.5 ms in an album of 10 (90: up to 5.2 ms, beyond a Telegram album's 10). Whole catalog: the integrator's.
- Not verified: re-judging a row when the owner's word removes an anchor, a twin's bytes are lost, or the file is seen in another album (a count, so left).

### The client (A-1): acting in chats, step 3

A1. NOT READY: WAITS FOR THE K24+K20 HEAD (client A-1, 11-22: joined with K22b at `wip/client-chat` 3455566c on f0323f5b, Schema|Step ok; then the batch with K24 and K20; A1 becomes 37; relisted with its new head. Do not merge f8102bea.) Was: `wip/client-chat` at f8102bea, holds main 09aeba54 (steps to 33). Step 35 after K22b's 34 (on the branch: after `mirrorPutBackSchema`). Merge BEFORE A2 and A3. Whole `internal/catalog` ok 864 s and whole `internal/mirror` ok 376 s on f8102bea. JOIN WITH K22b: K22b edits the same places of `schema_act.go` (`actCols`, `insertClick`, `sendClickAgain`'s insert) and A1's stored rebuild SQL (`schemaActChat`) must then name `made_by` (the migration's `schemaActChatFor` already carries it, tested with 'owner' and 'alerts' rows). The client track does this join on its branch when K22b is on the head: say the word. Earlier: held at ee572e0f, fixed: a `%` left in `readableChatsSQL` (70d29d17), the mirror's older-file test (now the head's M20 copy); two catalog writer-hold tests measured alike on main under load.
- What it does: join with a look first (checkChatInvite or resolveUsername, then importChatInvite or joinChannel; the app's own cap 5 an hour, 20 a day, stored settings), leave (ported from the old app's dialog_remove.go: getPeerDialogs, leaveChannel or deleteChatUser, deleteHistory never revoke; the "left by the owner" mark: the reader and the automatic mirror skip the chat), mute (updateNotifySettings, mute_until only). The owner agreed the design (item 45). Its first commit 2bb5a715 "Client frame:" (six kinds, `c_act` rebuilt) is shared with A2 and A3. No page: data through the door (`/api/act/click`, `/api/clicks/join-cap`).
- Files: `internal/telegram` act*.go and act_chat.go; catalog `schema_act*.go`, `schema_actchat*.go`, `act_settle.go`, `tgchats.go`, `collector_wants.go`; collector `click*.go`, `reader.go`, `pages.go`, livepages, faketg; tgstore. Lent: "Lent to Core:" f1bb7920, 98383f01 and one in S1/S2's round; "Lent to pages (server):" 8eb63aa9, 970e4c36 (server/clicks.go).
- Schema step: 32 (`chatActSchema`, after `mirrorTopicSchema`), `c_act` rebuilt in one transaction after a check of its columns and references (fails closed if they differ).
- Review: one independent (`REVIEW-A1-chat-actions.md`: 2 must, 3 should, 3 minor), all fixed; a second look at F1, F2, F4: 2 should (S1, S2), fixed, read by A-1.
- Tests run: whole `internal/telegram` 51.7 s; catalog and tgstore `TestAct*` with the merged steps' tests 51.7 s; collector 16 named 104.6 s; server, acttest, livepages `Click|Door|Act`; gofmt, vet. Two runs started with the CPU at 100% (load only). No race (nothing concurrent added). Whole collector/catalog: left to the integrator.
- MERGE NOTE: Core's K24 (`account.brought_in` not live, in `insertClick`, `actAccountLive`, the try-again insert of `schema_act.go`) comes with U1. Whichever merges second keeps that condition inside A1's rebuilt statements (K24's test `-run BroughtIn`).
- For the viewer: today's chat box draws look, join, leave and mute rows as messages: told to B9 (skip them).
- Not verified: nothing met Telegram; what getPeerDialogs answers for a left private channel (measured at the first real leave); a rejoin on the phone is seen at the next chat list.

A2. NOT READY: WAITS FOR A1 (client A-1, 11-22; becomes 38; at `wip/client-afile` 2fecc8e2, holds A1 3455566c). Was: `wip/client-afile` at c51427c6, holds A1 f8102bea exactly. Step 36 after A1. Whole `internal/catalog` ok 1060 s and whole `internal/mirror` ok 404 s on c51427c6.
- What it does: a file the archive already holds, sent again from Telegram's own copy, no upload: one read of the source (the refresher's `ask`, one try, 30 s, a stated wait never slept: the click ends "not sent" with its end), the fresh reference, then one `messages.sendMedia` under the text step's rules (Begin first, never repeated, a wait reported). The owner agreed the design (item 45). Data only through `/api/act/queue` (`kind: "sendfile"`, `file`).
- Files: `internal/telegram` act_file.go and lines in act.go; catalog `schema_actfile.go`, `act_settle_file.go`, lines in `schema_act.go`, `act_settle.go`; collector `click_file.go`, lines in click.go, click_api.go. Lent: "Lent to Core:" 96cf358c, ef0293ae (catalog.go, settle.go purge, livepages, faketg); "Lent to pages (server):" 78a3ad63 (server/clicks.go).
- Schema step: 33 (`actFileSchema`, after A1's `chatActSchema`): a new table `c_act_file` keyed by c_act's id, its trigger `c_act_file_again` (a later rebuild of c_act must make it again).
- Review: one independent (`REVIEW-A2-file-from-archive.md`: 1 must, 4 should, 3 minor), all fixed; a second look at F1 (frozen and mirror judged again after the read and after Begin): "may be listed"; one minor left: frozen or mirror found in the milliseconds after Begin ends "not sent" with the word "record unreadable".
- Tests run (on 533dc6ee): whole `internal/telegram` 46 s; catalog named (file, chat, act, schema, migrate) 77 s; collector 5 named 13 s; server `Click|Door|Act` 6 s; faketg and livepages whole; gofmt, vet, build. No race (nothing concurrent). Whole collector/catalog: left to the integrator.
- Not verified: nothing met Telegram; a file reference refreshed then refused at the send is shown and never retried; the viewer draws sendfile as a send.

K29. READY (Core K-6, refitted onto 2b38b2a3, which has N4 and K22b): `wip/core-nasalerts` at a85fa5b0, holds main 2b38b2a3 (the NAS kinds kept beside `bot.refused`; the `turned` flag put back in N4's nas_link.go; differs from the head by K29's own 10 files; after the merge: alert whole, the collector's TestAlerts*, TestAlertsNAS*, N4's recover tests 64 s, server TestAlert and TestF13, TestWall, gofmt, build, vet: ok)
- What it does: the NAS downloader's status as alerts, read through the collector's own `NASStatus` door (agreed with N-1): `nas.away` (15 min), `nas.vpn` (15 min), `nas.signed_out` (at once), `nas.waiting_entry` (30 min), `nas.holding` (1440 min, from the state file, works with the NAS down), `nas.state_unreadable` (at once); each `alert.after.<kind>`, no upper bound. An error from the door or a place that cannot be read raises `alert.unreadable` and ends nothing. Link kinds only for accounts on the NAS; nothing judged before the NAS task's first turn. Words fixed, "the NAS", never its address.
- Files: `internal/alert`, `internal/collector` (alerts_nas.go new, alerts.go hook); lent: one line in N4's `nas_link.go` (an atomic `turned` flag), six titles in pages' `internal/server/alerts.go`.
- Schema step: none.
- Review: none (no Telegram request, nothing decided about a file); my read. One change from the brief, accepted: "AsOf too old" is not applied while the NAS answers (Reachable comes only from a read in the same call).
- Tests run: alert whole; the collector's TestAlerts* and the new TestAlertsNAS* (each kind at its threshold, ended, one row across a restart, the PC place raises none, door error, an old NAS clock, holding with the NAS down) and N4's recover tests, 64 s; server and livepages TestAlert, TestF13; TestWall; gofmt, build, vet.
- Not verified: a real NAS; the cost is one NASStatus a look per account (home network only, 25 s bound).

C32. READY (copies, re-listed 10:43): `wip/copies-37` at 80ef29fe, holds main f0323f5b (independent of C28, C33, C34)
- What it does: a newly fingerprinted video (staged copy or the library pass) is compared, after its copy is let go, with saved videos within 20% of its length (at most 300, 5 s) by `footage.Compare` (the old app's `ix_vdup`): same = a probable edge from the LESSER copy to the BETTER one where it covers it (`lookalike.Better`, `Covers`), else related; clip and overlap related; between SAVED media only; never exact, no `c_want` change, no edge twice, the owner's "not the same" respected.
- Files: `internal/vfp` (`pairs.go` new, `vfp.go`), `internal/catalog/videopairs.go` new (door `PutSavedVideoPair`), the collector's `fingerprints.go` (copies'); tests; report `docs/progress/copies-saved-video-pairs-REPORT.md`.
- Schema step: none.
- Review: one independent (`REVIEW-C32-saved-video-pairs.md`) because an edge feeds `WantAgain` when bytes are lost: F1 (the edge's direction) fixed with `TestSavedPairDirection`; a second pass of the fix: may be listed as it is. While both files stay saved an edge decides nothing; once a file's bytes are lost the lesser copy comes back held behind the better saved one, the better one wanted.
- Tests run: whole `internal/vfp` 47 s; catalog named (the pair door, its plans, `VideoCandidates`, WantAgain's seven) 41 s; collector named `Fingerprint` 33 s; vet; gofmt: ok. No new goroutine: no race run.
- Not verified: clips (the 20% band misses nearly all: a frame-hash index is a later piece); a rare held copy missed when the longer copy has fewer bytes (N1, errs safe).

C33. READY (copies, 11:05): `wip/copies-38` at c2f2b782, holds main f0323f5b (independent of C28, C32, C34)
- What it does: a saved picture gets its PDQ hash (the old app's `ix_pdq.go` ported: new `internal/pdq`, the old values on 11 pictures) from its STAGED copy (new worker `internal/picfp`, beside the video worker, never reads the library, the copy never waits), stored as a `pdq` fingerprint row in the bring-in's form; it is compared with the saved pictures' PDQ (a band index, complete within 31 bits, rarest bands first under a 50,000 cap; 48 µs a lookup at 100,000): a probable edge from the LESSER picture to the BETTER one where it covers (`lookalike.Better`, `Covers`), else related; never exact, never against the owner's "not the same".
- Files: `internal/pdq`, `internal/picfp` new; `internal/catalog/picpairs.go` new; the collector's `fingerprints.go`, `framecheck.go` (copies'), `staging.go` (Core's, about 15 lines: OK'd by K-6); tests; report `docs/progress/copies-picture-pairs-REPORT.md`.
- Schema step: none.
- Review: one independent (`REVIEW-C33-picture-pairs.md`; an edge feeds `WantAgain` when bytes are lost): direction right both ways, only pdq rows and edges move, recall complete; F1 (rows written later for lower ids missed: now a count-checked reload), F3 (words), F4 (rarest bands first) fixed with tests; listed on my read of those fixes.
- Tests run: whole `internal/pdq` and `internal/picfp`; catalog named (13 top-level, `WantAgain`'s seven among them) 23 s; collector named; race on `picfp` and the collector tests (Docker) before the last round; gofmt, vet: ok.
- Not verified: pictures already in the library before it (no library pass); WebP, HEIC, AVIF not read (as the old app); real pictures.

NA2. READY (NAS, lent to Core, 11-22 11:19; on 9cb4edc since): `wip/nas-ctunnel` at f80c30d1, holds main 9cb4edc
- What it does: the collector's way to Telegram as a stored setting `collector.telegram_way`: "system" (Windows default,
  unchanged), "tunnel" (WireGuard in-process; default elsewhere; no file refuses the start), "none" (only when stored, said
  everywhere). Fails closed; the bot dials only through the tunnel; `probe` refuses under "tunnel". For the autonomous NAS.
- Files: collector (command, signin_cmd, mirror_cmd, collector, alertbot, heartbeat, status_file, new telegramway), libclient
  (path, home, NeedResolver: moved from nasdl), telegram/vpn.go (ForbiddenNow, PathUp), botapi (NewDial), probe (WayCheck),
  cmd/tgarchive-collector, nasdl (uses libclient), new wgdial/wgtest.
- Schema step: none
- Review: Core's read and its OK to merge (fixes accepted); one independent review (`REVIEW-NA2-ctunnel.md`): probe dialled direct (must), the gate's cached
  "allowed" while the tunnel died, no-DNS files silent, the tunnel before the lock; all fixed with tests (6a04d72c).
- Tests run: TestTelegramWay* (14) and named dialler/signin/away/bot/VPN/status/mirror tests; libclient, botapi, probe,
  cmd/tgarchive-collector whole; gate tests; nasdl TestProgram*; gofmt, vet. Race (Docker): collector -run TestTelegramWay
  77.6 s, libclient 1.0 s, nasdl two named 14.9 s: no race.
- Not verified: on the NAS, with a real Windscribe file.

C35. READY (copies, re-listed 12:29): `wip/copies-40` at fbade531, holds C32 (80ef29fe) and f0323f5b: merge AFTER C32; with the cap setting `fingerprints.clip_index_mb` (default 128 MB on PC and NAS, 0 off, no upper bound; doors `ClipIndexMB`, `SetClipIndexMB`; over the cap new videos are left out and counted, never a refused start), agreed with N-1 (the NAS's headless collector 105 MiB steady, 204 peak, under GOMEMLIMIT 512; its 1.1 GB start read is the NAS's own disk)
- What it does: clips found at any length: a pure in-memory index of 24 frame hashes per saved video (`internal/clipindex`, the old app's 16-bit slicing; 91 MB, built in 2 s at 136,000 videos; a lookup 76 ms, 578 ms at worst); C32's compare step takes its candidates besides the length band's; `footage.Compare` and C32's door decide as before (clip, overlap: related; same: probable lesser to better).
- Files: `internal/clipindex` new; `internal/vfp` (C32's `pairs.go`); `internal/catalog/clipdoors.go` new (reads only); tests; report `docs/progress/copies-clip-index-REPORT.md`.
- Schema step: none.
- Review: none of its own: it adds candidates only; every edge goes through C32's reviewed door unchanged. My read of the report.
- Tests run: whole `internal/vfp` 33 s and `internal/clipindex` 24 s; catalog named 11 s; collector named `Fingerprint`; vet, gofmt: ok. Recall on invented clips 100/100 at 10%, 30%, 60%, 50/50 reversed, 0 false. No new goroutine.
- Cost to watch: at each start the worker reads every video fingerprint again (about 1.1 GB at the old archive's size), spread over its turns within each file's 5 s; 91 MB of memory held. Not verified on real footage.

NA3. READY (NAS, 11-22 12:20): `wip/nas-app` at f46449cc, holds main 2b38b2a3 (deploy files only)
- What it does: `deploy/nas-app`: a FROM-scratch image (collector, watchdog, backup, the main program for the viewer; no
  ffmpeg), `build.sh`, compose with two services in host mode (collector under the watchdog, 768m; viewer read-only, 1g),
  user 1000:10, read-only root, no capabilities; pages on 127.0.0.1:8797, viewer :8798 for now; README in the owner's order.
- Files: `deploy/nas-app/*` only.
- Schema step: none
- Review: none (deploy files: not Telegram, not skip/delete, not the download path); my read.
- Tests run: compose config; build.sh end to end; the saved image loads and runs on an invented catalogue with
  --network none (collector idle under the watchdog, viewer 200, clean stop); everything it made removed.
- Not verified: on the NAS. The image must be built from a head holding NA2 (Linux refuses without the way). No health
  check yet (needs a collector `check` of the status file's age: a small Core piece). Viewer restarts while the collector
  is stopped (SQLite's -wal/-shm on a read-only mount).

F19. READY (viewer B9 for the archived UI track, 11-22): `wip/ui-batch` at 57821cff, holds F17 1e682d3b (merge AFTER the current UI batch with F17)
- What it does: batch selection with search, like the old app: Choose chats (Select all (N) over what the search and filters show; Group as, Take out of group, Collect on/off, Hide, Show again; one question naming the count, one POST per chat, "N of M done", Undo); the left list's select mode; the pickers with search and ticks (new shell asset `pickers.js`); the library's Select (Hide, Not clutter, Show again); the viewer's reader of the pages' `as-h` hand-off (`carryhide.js`: strict parse, the address cleaned at once, NEVER acting on the address alone: one bar naming the count, only the owner's click posts /api/hide per chat; a device page ignores it).
- Files: appshell (shell.js, pickers.js new, groups.js, shell.go's AssetNames), server web (chatbatch.js), viewer web (carryhide.js new, libselect.js, main.js, library.js), tests in appshell, server, viewer.
- Schema step: none. Review: none (front end over existing routes; nothing new reaches Telegram).
- Tests run: appshell whole 43.4 s; TestSelectModeInBrowser, TestGroupsInBrowser (x4); server security set + TestF19ChooseChatsBatch 35.3 s; viewer security set + TestF19CarryHide/CarryStrict/LibrarySelect 68.0 s; gofmt; vet appshell, viewer, server. Pictures from its own try window: runs-ui-1/f19-pictures (not for the owner).
- Not verified: Take out of group, Collect on, the library's batch Not clutter and the list's Hide on the viewer have no end-to-end test of their own; three assets were over 600 lines before (shell.js now 1771, library.js, app.css).

C36. READY (copies, 12:30): `wip/copies-41` at fdb1d9db, holds main 9cb4edc9 (independent)
- What it does: C29's library pass reaches the old archive's videos through K24's `libroot.Resolve` (`OldLibraryRoot` read each turn; `ErrNoOldRoot` = "no root", any other refusal never read); the copied `oldPlaceSQL` gives way to `catalog.OldPlaceSQL`; the walk restarts from the newest once when the old root is first set or changes (`LibraryWalk.Root`, `Stats.LibraryWalkRestarts`, no path logged); an old place is read only while the old root folder answers (else "away", never counted missing). The gate (no copy waiting, the hour's cap) unchanged.
- Files: `internal/vfp/library.go`, `internal/catalog/vfp.go`; tests; the C29 report's C36 section.
- Schema step: none.
- Review: none (reads the libraries only under the gate and never writes them; writes fingerprint rows as C29 does).
- Tests run: whole `internal/vfp` 36.7 s; catalog named; collector named; build; vet; gofmt: ok. No concurrent code changed.
- Not verified: a real old library on the NAS.

K30. READY (Core K-6, 11-22 12:50): `wip/core-react` at 36e362e0, holds main 9cb4edc9 (a trial merge plus build and vet clean)
- What it does: a message's reactions and a service message's action recorded for the viewer, with no request to Telegram: `message` gains `action` (a fixed word, `catalog.ActionWords`), `action_title`, `action_num`, `action_peer`, `action_ref`, `reactions_at`; a table `message_reaction(message_id, pos, kind, value, count, mine)`, never who reacted. Written at save (`telegram.RecordOf`), on the live monitor's `updateMessageReactions` (`telegram.ReactionEvents`, before counted as unknown), and once for what is stored by a background fill (a task "message facts", about 300 a chunk, a cursor, 50 ms between chunks; the old archive's messages included). Doors for the viewer on any handle: `MessageReactions(ctx, ids)`, `MessageActions(ctx, ids)`, `FactsFillState(ctx)`.
- Files: `internal/catalog` (schema_react.go, the doors, the fill), `internal/telegram` (RecordOf, the monitor's reaction sink), `internal/tgstore`, `internal/collector` (factsfill.go); two of K20's step tests read `SchemaVersion` now.
- Schema step: one, after K20's (`reactAfter = unlSchema`); the number is yours (the UI batch has 37 and 38); safe to run twice.
- Review: none (no request, no Telegram write, nothing decided about a file); my read.
- Tests run: new facts tests in telegram, catalog, tgstore, collector (20 mutants caught); tgstore and bringin whole; the whole catalogue's `-run 'Schema|Step|TestReact|TestUnl'` 56 s; TestWall; the race detector on whole tgstore (430.5 s), telegram's Facts/Monitor/Record, the collector's TestFactsFill: no race.
- Not verified: the fill on the owner's real catalogue size (200,000 invented messages: 3.6 s without the pause, about 37 s with it). A record without a reactions field clears what was stored (Telegram sends the field whenever there are reactions).

R1v. READY (viewer, 11-22): `wip/b-react` at d5ab0b8b, holds Core's K30 `wip/core-react` 36e362e0 (merge AFTER K30)
- What it does: reactions and service actions in the chat page and the post view: DATA per post (`reactions: [{kind, value, count, mine}]`; `action: {word, title?, num?, peer?: {id, name?}, ref?}` on `service: true` posts; `facts_filled` in meta; one call of each K30 door per page through the read-only handle, absent on error, counted in stats) and the DRAWING (I-7's word, the UI track archived): counts under a message, one plain line per service action, nothing when absent, all text as text.
- Files: `internal/viewer` (facts.go new, conv, api, stats, viewer; web/js/facts.js new, chat.js, item.js, app.css; tests).
- OVERLAP: `chatconv_f5_test.go`'s node stubs gain `facts.js` and a `store` in `api.js`; `wip/b-chatconv-j` (c73a29eb) adds `hiding.js` in the same map: keep BOTH at the merge.
- Schema step: none. Review: none (display only).
- Tests run: TestR1v* (page, service actions, older catalogue, door error, cost, drawn in a headless browser), TestLANR1vFacts; `TestWall|TestHomeDevice|TestLAN|Security|TestPageScripts|TestChatConv|TestF16|R1v` 51 pass 19.7 s; gofmt; vet viewer. A page of 50 posts about 1.4 ms (doors 0.2-0.3 ms).
- Not verified: on a real catalogue (older messages fill after the collector's next start).

C37. READY (copies, 14:03): `wip/copies-42` at 32190967, holds f677f3a8 (int/join24); schema step 44 (`heldClassAfter = actUploadSchema`)
- What it does: the held tier's order, likely distinct first (LESSONS-ix12.30 §6c): a stored class `c_want.held_class` (0: frames "no match", hashes differ, or no probable edge to a file of its own size and length; 1: the rest; 2: confirmed by three places, the frames' copy, or the owner's "same"), kept by triggers; tier 5's `k3 = band + 8*(class-1)` (class 1 = the head's key). Only the order among held probable copies changes; no state moves.
- Files: `internal/catalog` (`schema_heldclass.go`, `heldClassSQL`, the view `supplySrcHeldClassSQL`, `sup_want_ai` rebuilt with the class, `ladder.go` writes a hold's edge before its row), tests; report `docs/progress/copies-held-order-REPORT.md`. A chunked fill at Open after the lengths' and the clutter's.
- Review: one independent (`REVIEW-C37-held-order.md`) and a second pass: may be listed as it is; 8 seeds x 260 doors against 9cb4edc9 identical outside tier 5's order; never stale after 1,040 doors. Accepted by me: a held attach +16 to +29 µs (an attach is 60 to 165 µs).
- Tests run on the refit tree: `TestHeldClass` 13 s; `-run 'Unl|Tier|Migrat|Held|Schema|Step'` 127 pass 157 s; `-run 'Twin|CheckFirst|SamePost|Ladder|Album'` 61 pass 232 s; `internal/supply` whole 262 s; vet, gofmt: ok.
- Watch: a later step that rebuilds `sup_want_ai` must keep its class statement, and a view rebuild must start from `supplySrcHeldClassSQL`. A frame verdict costs about +34 µs.

A1V. READY (viewer, 11-22): `wip/b-a1viewer` at 7855f795, holds the join tip f677f3a8 (with the client's A1, step 41)
- What it does: the chat box draws and counts only MESSAGE kinds of `c_act` (send, forward, edit, delete, react, read, sendfile, upload); look, join, leave, mute and any unknown kind are left out of the drawn clicks, "more" and the bound, and the box's routes refuse them ("bad request", the door not called); sendfile and upload drawn as a send (arrived, candidates); `catalog.ActNonePhoto` has its own sentence with the "owner decides" offers.
- Files: `internal/viewer/act.go` and a new test file only.
- Schema step: none. Review: none (it only removes rows and refuses calls; nothing new reaches Telegram).
- Tests run: TestActKinds* (drawn set, chat actions from the ledger, not counted over the bound, the upload photo words), `TestWall|TestHomeDevice|TestLAN|Security|TestAct` 36.6 s; gofmt; vet viewer.
- Not verified: "send again" on a sendfile/upload whose caption was cleared is still offered (the client track's to say).

W9. READY (viewer B9 for the archived pages track, 11-22): `wip/b-windowend` at dd71bc83, holds the join tip f677f3a8
- What it does: the launcher writes ONE constant line at every end of the app's window (joined, solo, pages, a restart, an adopted window, its own stop, a kill from outside): `launcher: the app's window ended: exit code %d (hex %X) after %s; closed by the person: %t; the launcher's own stop: %t`; a run marker `launcher.running` in the logs folder (start time only) so the next start writes `launcher: the previous run ended without its end line (stopped from outside, e.g. killed), it had started %s ago` when the launcher itself was killed (the case of 11-22); `tgarchive-window: ending with exit code %d (hex %X)` at the window's own end.
- Files: `internal/launcher` (present.go, words.go, runmark.go new, launcher.go, log.go, tests), `cmd/tgarchive-window/main.go`. The two older end lines are replaced; their tests updated.
- Schema step: none. Review: none (log lines only; no name, path or id).
- Tests run: TestWindowEndLineEveryEnd (normal, person's close, forced kill, own stop), TestRunMarker* (3), TestEndLinesCode, TestEndLineFixed; launcher `-run 'Window|Close|Joined|Present|TestSecondLauncher|TestLauncherLogNoPathsOrNames|TestRunMarker'` 78 pass 124.3 s (7 real-window skips as before); vet launcher and the window command; gofmt.
- Race: the window's watch runs in its own goroutine: a race run of `internal/launcher -run 'TestWindowEndLineEveryEnd|TestRunMarker'` is the integrator's.
- Not verified: with the real window on the owner's PC.
