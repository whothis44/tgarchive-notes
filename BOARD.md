# The board: current state only (one page; rebuilt 11-21 22:24 under the lean workflow)

Rules: `CLAUDE.md` (rewritten 11-21). Lessons: `DIGEST-LESSONS.md`. Keep this page under about 12 KB: change only your
own row, write state, not history. Messages between sessions go by direct message to the session; anything the
owner must decide goes under "Waiting for the owner". Everything before 11-21 22:24 is in `BOARD-LOG.md`.

## The order of work
1. **Ship what is merged to the owner:** each merged batch goes into the second folder `C:\Users\trabi\tgarchive-app-next`;
   the owner switches with one command (pages is building it).
2. **The mirror works unattended:** M14 (deleted messages never block; single posts 5 to 20 s; exact repeats skipped),
   then M15 (forums mirrored as forums). Alerts (Core K22) tell the owner when something needs a person.
3. **One unified archive:** the old archive brought into the new catalogue; copy checks across both; new media flagged
   (copies leads, `DESIGN-UNIFIED-ARCHIVE.md`; the viewer and Core follow).
4. **The app the owner uses (the owner, 11-21 22:40: "the UI right now, and actual user experience, is basically a
   disaster"):** `DESIGN-ONE-WINDOW.md` built end to end by ONE track, UI (U-1), which owns the whole front end; pages
   and the viewer serve it data and doors. An audit with screenshots goes to the owner first.
5. **The NAS downloader** (`DESIGN-NAS-downloader.md`) and **the client acting in chats** (`DESIGN-CLIENT-acting.md`).
6. **The owner's priorities of 11-22 morning (all four to be built NOW: the owner to I-7, 11-22 about 10:20, "All four now is fine, we can make it"; the owner 12:30 at 94%: no artificial stop, let work in progress build and merge):** the NAS autonomous (the PC as dashboard/controller; design note first, N-1); new items against the saved library (copies); chats grouped with suggested names and manual overrides (viewer + UI); clutter: hide chats and posts, a better detector (viewer + copies).
7. Everything else in `FEATURES.md` and `ROADMAP.md`, in each track's order.

## Tracks
| Track | Session | Owns | State (one line, the track's own) |
|---|---|---|---|
| Integrator | I-7 (Opus), `SESSION-11-PROGRESS.md` | merges, `BOARD.md`, `MERGE-QUEUE.md`, `ix-tools`, `archiver/docs` | 11-22 12:20: head 9cb4edc (K24 35, U1, K20 36, K28b, M21, MF, LT merged), pushed; second folder built from it; UI batch (F17: clutter 37, chat groups 38; F18, QC2, WP, OS) in its runs on int/join22; next K29, NA2, C28, C32, C33, F19, then A1-A3 (the client session is archived: a fresh one refits); usage 92% |
| Mirror | M-7, `SESSION-MIRROR-PROGRESS.md` | `internal/mirror`, forward and create in `internal/telegram`, the collector's `mirror_*.go` | 11-22: M-7 ARCHIVED (done): M21 and MF merged (9cb4edc); race run of internal/mirror ok (2 h 37 min). Owed to a fresh mirror session: the night's numbers after the owner's switch, pages' doors, the first adoption; state block in SESSION-MIRROR-PROGRESS.md |
| Core | K-6, `SESSION-CORE-PROGRESS.md` | `internal/telegram` (rest), `reader`, `engine`, `collector` (rest), `tgstore`, `crashlog`, `watchdog`, `sqlguard`, staging | 11-22 12:50: K24, K20, K28b merged (9cb4edc). Listed K29 (after the UI batch), K30 (reactions, step number I-7's). Nothing runs; context near full. Take-over: SESSION-CORE-PROGRESS.md |
| Pages | P7, `SESSION-PAGES-PROGRESS.md` | `internal/server` (Go), `launcher` (logic), `actdoor`, `collector/livepages`, `cmd/tgarchive-open`, `deploy/folder` | 11-22 11:52: P7 done, its context nearly full: nothing runs. LISTED: LT, QC2, WP. Owed: K24's sign-in refusal (after K24). Take-over block in SESSION-PAGES-PROGRESS.md |
| Viewer | B9, `SESSION-B-PROGRESS.md` | `internal/viewer` (Go: handlers, index, data; NOT `web`: the UI track's since 11-21), `window` (native parts, with U-1), `bringin`, `cmd/tgarchive-bringin`, `cmd/tgarchive-window`, `cmd/tgarchive/viewer.go` | 11-22: MERGED W1v, U2, the bring-in (with K24, 9cb4edc). In I-7's UI batch: G1v chat groups, CL1v clutter (in F17). LISTED: MCv (after pages' MC). WITH A CODER: F19 finish (the archived UI track's batch selection, `wip/ui-batch`) |
| Copies | C7, `SESSION-COPIES-PROGRESS.md` | `lookalike`, `exact`, `supply`, `parts`, `partsledger`, `probejudge`, `pairwords`, `vfp`, `footage`, the catalogue's hold and copy files | LISTED: C32 (saved video pairs), C33 (picture pairs by PDQ), C34 (clutter score, B9 suggests), C28 (whole-album rule, after the K24/K20 batch); next: the K24 follow-ups (C29's resolver; the held tier's order) |
| Client | A-1, `SESSION-CLIENT-PROGRESS.md` | the acting requests and doors (agreed with Core) | 11-22: A1 (join, leave, mute, step 32) and A2 (a file from the archive, step 33, after A1) LISTED; A3 (upload, step 35) in its second look and race run; never run against Telegram |
| NAS | N-1, `SESSION-NAS-PROGRESS.md` | the NAS downloader's new packages, the NAS helper, `deploy/nas` | 11-22 08:34: STOPPED (usage). N1, N2, N3 merged; N4 (PC side) LISTED after pages' N4P; next N5 after item 31; nothing runs |
| UI | U-1 (Opus), `SESSION-UI-PROGRESS.md` | the whole front end: `internal/server/web`, `internal/viewer/web`, `appshell`, the launcher's `ui.go`/`look.go`/`page.go`, the window's shell | 11-22: ui-all, UI-3, F7 merged; F15, F16a, F16 listed (after K24 + the bring-in), taking main 09aeba54; usage 80%: nothing new started; state block for a take-over written |
| The old app | none (closed) | `wt-v12.*`, `whothis44/tg1` | fulfilled its purpose; the owner is basically done running it |

## Merge queue
`MERGE-QUEUE.md`: one short entry per listed branch, in merge order.

## Schema numbers
Set by the integrator (the number is the order of the merge). On the head 9cb4edc: ... 34 K22b, 35 K24, 36 K20. **In the UI batch: 37 clutter (C34, in F17), 38 chat groups (G1v, in F17). Next: 39 C28 (copies, `albumLikeAfter`), then A1, A2, A3 (client) in that order.** At the merge each step's "after" is the step merged just before it; a track whose step moves sets it when it merges the head in.

**Viewer (B9, 11-22): one step claimed for the owner's chat-group overrides (`chat_group_word`, `wip/b-chatgroups`); numbered at the merge.**

**Copies (C7, 11-22): one step claimed for the clutter detector's scores (`c_clutter_score`, `wip/copies-39`, C34); numbered at the merge.**

**Copies (C7, 11-22): one step claimed for the held tier's order (a class column on `c_want`, the tier-5 key; `wip/copies-42`, C37); numbered at the merge.**

## Waiting for the owner (open items only; one line each, with a recommendation)
- ~~42. Alerts away from the PC: which channel?~~ **DECIDED by the owner 11-21, before 22:50 (the minute was not taken from the clock): A and C** (a bot of the owner's, and the archived
  account's own Saved Messages; "keeps it probably more secure"). Core builds it as K22b after K22. Plus the Windows notification at the PC.
- ~~43 and 44~~ **DECIDED by the owner 11-21 about 22:38: the old app is done now (its last write is made); the bring-in is a step the owner starts from the launcher, first on a copy of the catalogue.** Copies leads; pages and UI for the step.
- ~~48~~ **ANSWERED by the owner 11-21 about 22:41:** 9 containers about 2,790 MiB (a media server 1,964 MiB, a download manager 516 MiB still running); sent to N-1.
- ~~49. Downloads only in unlimited hours: how a probe opens a limited server~~ **DECIDED by the owner 11-22 09:57: the 2-minute trial, "Option B for now".** After a clean probe only the probe file runs for 2 minutes; the other waiting files are claimed only if no speed-limit wait comes. `engine.unl_trial_minutes` defaults to 2 in K20 (0 turns it off).
- ~~50. The NAS runs the app~~ **DECIDED by the owner 11-22: "Yes, as recommended" (all three). Build by the NAS track in small pieces; first the memory measurement.** As asked: The NAS runs the app, the PC is its dashboard (NAS track, N-1, 11-22; `DESIGN-NAS-autonomous.md`, one page; your words of this morning):** the whole collector (mirror, its automatic task, downloads, alerts, the bot) runs on the NAS, the PC's window shows it and sends commands, everything goes on with the PC off. Three yeses asked: (1) this shape; (2) the PC's login MOVES to the NAS with the catalogue (no new device; the PC's copy removed); (3) the PC downloads nothing for an archive the NAS runs (the limit is the account's). Recommended: yes to all three. Nothing is built before your yes.
- **The switch to the new build:** when pages' update command is ready, quit the app and run it (the integrator hands it
  over with M14).
- Older "READY for you to start" items from 11-15 and 11-16 (the first real runs on the test account: items 8, 20, 26,
  29, 33, 37, 39) are in `BOARD-LOG.md`; most were overtaken by your own use of the app since 11-19. Ask a track if one
  still matters.
- **45. The bot answers back (your wish, 01:20):** recommended and being built with K22b (`DESIGN-CORE-alerts.md` §5):
  `status`, `alerts`, `seen`, `pause <hours>`, `resume`, and `allow <code>` (needs your `yes <code>`, since the mirror
  then forwards with your account); only your own user id; stale after 10 minutes. About 70 requests an hour to the bot's
  servers only. Say if you want a command added or dropped.
- **First adoption (mirror, M6, `PLAN-MIRROR-first-adoption.md`):** an existing chat of yours as a source's mirror. Recommended: name a small pair (a source and the chat already holding your copies of it); the mirror track then gives the exact command (the app stopped, about 10 minutes).
- **For the morning: the copy checks, built but not running for you (copies, C7, 02:17).** Today your app runs the exact check, the same-file and same-bytes links and the look-alike hold; the frame check ("smart sampling"), the fingerprints and the reuse of sampled parts are built but OFF, because they were switched on only by start flags your app does not pass. C31 turns them ON by default (your "off" on Settings stays off). Once installed: each saved video gets a fingerprint from its local staged copy (no request, a few seconds of the graphics card); a new video of 20 MB or more with a saved look-alike is checked by about 8 sampled parts (8 MB) before it downloads, a copy is held (never skipped) and the parts are reused when it does download. Your catalogue has 0 video fingerprints now, so the frame check starts finding copies as fingerprints build up (new saves; C29 adds the 605 already in your library; the old archive's 136,000 come with the bring-in). Nothing to decide unless you want them off.
- **Frame-check held copies? (copies, C30, 04:56; listed, off by default.)** Your held probable copies wait for your release; with this switch on, a download lane that has nothing unique left to fetch, in hours without the speed limit, checks one held video at a time by its sampled frames (about 8 parts, 8 MB, at most 30 an hour per server by a setting), never downloads it, and marks it: "a copy" (keep it held) or "frames found no match" (worth your look before releasing; a no-match is wrong about 3 in 4, so nothing is released by it). Recommended: ON once C31 and C29 have built fingerprints, so your release decisions have evidence; it uses only an otherwise idle server's allowance.
