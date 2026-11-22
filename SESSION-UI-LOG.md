# UI track: the whole front end (newest state only; older text goes to `SESSION-UI-LOG.md`)

Owns: `internal/server/web`, `internal/viewer/web`, `internal/appshell`, the launcher's `ui.go`/`look.go`/`page.go`,
the window's shell and navigation (with the viewer track for `internal/window`'s native parts). Pages (P7) and the
viewer (B9) keep their Go handlers and data and add the doors U-1 asks for. The design: `DESIGN-ONE-WINDOW.md`
(decided 11-16), its picture `design-options/app-look-options.html` ("The combination"). Piece ids: F1, F2, ...
(U1/U2 are taken by pages and the viewer).

## STATE (11-21 night, U-1, Opus)
- Audit DONE and sent to the owner: `AUDIT-UI-1121.md`, pictures `ui-audit-1121/` (invented data; try folder from
  6aa225fb, demo pages plus the joined window; window pictures by `runs-ui-1/shot.ps1`, clicks by `uiclick.ps1`: the
  owner's real window is open, so never a screen screenshot). Plan: F1 one frame, F2 the library without the
  collector, F3 Overview, F4 library, F5 chats, F6 Settings and setup, F7 words.
- **F1 LISTED** (`wip/ui-frame` 1d0e376e, holds W1v 302fbd76): one frame, the owner's list asks; pictures `runs-ui-1/f1-pictures/`.
  Owed: the viewer pages lack the pill and Queue count (needs a state door), hiding chats from the pages' side.
- **F3 LISTED** (`wip/ui-overview` ec953566 with the asset-size fix, after W3): the Overview as the dashboard; New/Deleted/First tiles wait for P7's
  count door: D1 `wip/pages-libcounts` with P7's coder (`library` {new7, deleted, first}, `mirrors_made_24h`
  [{account, made, cap}]; new7/first absent until B9 fills lib:new, lib:first). D1 LISTED 674f1f1a (`library` {new7, deleted, first, oldnew, units},
  `mirrors_made_24h`): F3b draws them (F3's coder) on the batch's merged head plus D1. Next to draw: the `twin_hold` switch (T1 LISTED
  `wip/pages-twinhold` 7a6e2699: GET /api/settings `twin_hold` {on, stored, words, cost}; POST /api/settings/twin-hold
  {on}) on Settings near the copy checks, in F3b or F6. Pictures `runs-ui-1/f3-pictures/` (`*-content.png` cropped: never send the owner the old list again).
- **F4 LISTED** (`wip/ui-library` 71b7c98a with F4b, hide by right-click, after F1 and U2): the library rework and the "New since the old archive" entry.
  Pages' list counts: S1 LISTED by P7 (`wip/pages-shellcounts` b7c7891e).
- **F5 LISTED** (`wip/ui-chat` 0c5e4de3, after W1v and W1b): chats as conversations; 3 pictures sent to the owner
  (`runs-ui-1/f5-pictures/`). Its head's avatar copies appshell's colour list: align after F1.
- F2's door agreed with P7: the launcher still starts the joined window viewer-first when the collector cannot start, and
  `GET /api/state` on the launcher (`collector`, `why`, `since`, `page`, `action`; CORS for its own origins), BUILT on `wip/pages-bringin` 72117787 (in its review; lent commit 8e58ec25 read, fine; shapes in
  `docs/progress/pages-bringin-REPORT.md` there: /api/state, /api/bringin per phase). L1 LISTED b141da57; F2 LISTED (`wip/ui-nocollector` 67d6f50b; brief `BRIEF-F2-no-collector.md`,
  `wip/ui-nocollector` from F1 5bf253bc + L1).
  Check at F2: the servers' CSP `connect-src` must allow the launcher's origin, or relay it.
- Owed to others' pieces (look only): the old archive's bring-in step (launcher, P7's logic; counts in the words of
  `DESIGN-UNIFIED-ARCHIVE.md` §4, before and after, one yes); U2's old-or-new data (`NOTE-UI-oldnew-contract.md`) drawn in F4 plus the `lib:oldnew` line in appshell.
- Owed to the client track (A-1): its acting controls (join after a look, leave with a second yes, mute, send a file
  from the archive; text already through act.js) drawn in the chat's head and foot, per `DESIGN-CLIENT-acting.md` §5;
  after A1/A2 list (F5b).
- **F8, the app's identity** (I-6's ask after the owner's "This looks shabby"): one icon (16-256) in tgarchive.exe, the
  window program, the title bar, taskbar and tray, the folder's shortcut and the setup page; the title "tgarchive · <place>".
  The owner chose C (refined C2: rim, 16-24 px drawing) and the name "TG Archive" (file names unchanged: the VPN list).
  F8 LISTED (`wip/ui-identity` a6e67488, holds F1 5bf253bc).
- **F6 LISTED** (`wip/ui-settings` 06d36442, after F2): Settings in sections,
  folder boxes, twin-hold row, the setup and the bring-in step from /api/bringin. /api/state's `why` names the cause: P7's SW LISTED
  (`wip/pages-statewords` 55a381f0; F2 draws it unchanged). F7 (words; also drop the stray tracked `pages/chats.js.new`) after F6.
- The owner asked "Is this the old app again?" on F6's lone pictures: F6's coder builds `wip/ui-all` (F6 + F8 + F4 + F5 + SW, head-bar
  leftovers removed) and pictures the WHOLE app in a real folder. OWNER 11-22: "Please stop" sending pictures of single
  pieces. Send the owner NOTHING more until the whole combined app matches the agreed picture, checked by me first.
- The bring-in's counted card (after L2 lists): only exact evidence before the run: `counts` plan.total.media, in_exact,
  not_exact (+ per account); words "N already in the old archive (exact); the rest are checked for look-alikes during the
  bring-in"; the four words (in/probably/partly/new) only on the after card.
- Pages' CS LISTED (`wip/pages-copysettings` 2ee66e57): /api/settings `exact_check` (modes, route /api/settings/exact-check) and
  `copy_checks` (six, each with route, words, cost, pending until the collector's next start). F10b LISTED (`wip/ui-copysettings` ccefefc1) wires them.
  F7 note: each setting row's second line repeats its title ("X: off (default)"): say only "Off (default)".
- **ui-all MERGED** (main 32d48a4c with L2, TB; second folder built, the tester on it). UI-2 merging 32d48a4c (F11a's coder), then relisted.
- ui-all's hold lifted: the quiet-PC A/B showed no regression (a post 95th ~2 ms both); the integrator merges ui-all, L2, TB.
- **UI-ALL LISTED** (`wip/ui-all` 3192de6f, on main e34f4f64): everything combined; checked by me against the agreed picture (match). **F9 LISTED**
  (`wip/ui-frame-qa` e23d1e81). Polish owed (F12): account badges cut chat names (use a small mark on the avatar); sparse days
  each take a whole row (pack small days side by side); two theme settings (pages' and viewer's) to become one. Then F7 (words).
- OWNER 11-22: Settings and every old page need a complete modern revamp ("selection boxes, toggles or windows"). **F10** with a
  coder (`BRIEF-F10-controls-settings.md`, `wt-ui-f10`, `wip/ui-controls` from ui-all): one control set in appshell + Settings
  rebuilt. Next **F11**: the remaining old pages (Choose chats as each chat's collecting panel, Accounts, Queue, Staging, Mirrors,
  Import, Report; the viewer's Copies, Overlap, Changes, About) on F10's controls. F7 (words) last, over all of it.
- Pages' L2 LISTED (`wip/pages-asks` 5923815a): /change?folder=, /api/prefs close answer, plan.* exact counts, the bring-in words;
  given to F10. Try runs: TEMP outside the project folder (make-folder refuses it).
- F10 must draw every door the audit (`AUDIT-INACTIVE-FEATURES.md`) found without a control: the six copy checks, twin_hold, exact
  check, held wait; the mirror's single-post wait, pace, cap; Backup if a door. Rename, gather, downloads-joined-away: no door yet
  (P7 wraps M-7's and Core's doors as pages' routes): disabled rows until then. Coming L4: /api/prefs `pair_words` on|off,
  `links` auto|on|off: Settings rows when listed.
- Pages: MC LISTED b3330d26 (list's mirrors count; viewer reads /api/counts: B9 told); CS relisted 9fd132a9 (exact check's words);
  RN (mirror rename-plan/rename) in review: wake the Rename row when listed.
- QA-32d48a4c (the merged ui-all build): "nearly there". **F12 with a coder** (`BRIEF-F12-qa2.md`, `wt-ui-f12`, `wip/ui-qa2` from F11c +
  F10b): pill vs Program words, numbers with units (P7's definitions: held 521 files, held probable 118 files, probable 191 posts,
  saved 2,197 files vs 1,541 posts), Saved Messages not read, Filters panel closing, Overview never redrawing under the pointer,
  counts on every library view (P7 adds lib:copies to `library`).
- **F11c LISTED** (`wip/ui-viewerpages` b3599920): the viewer's pages, sparse days, one theme (cookie), avatar marks.
- **UI-2 HELD** by the integrator on 3 walls (pages' settings.js names a host:port; shelllive.go outbound; /shell/controls.* served to
  the LAN). Fixed on UI-3 (F12's coder); UI-3 replaces UI-2. RULE for every UI listing: server `-run 'TestAssets|Security|TestEmptyCatalogue'`,
  viewer `-run 'TestWall|TestHomeDevice|TestLAN|Security'` by name.
- **UI-3 LISTED** (`wip/ui-qa2` 915686c1 = F10b + F11b + F11c + F12 + MC + MCv); B9: yes, on one condition: a pin test for shelllive.go
  like TestWallPagesCountsOneClient (F12's coder adding it now); B9 then makes one loopback client as a follow-up. RULE: run
  `-run TestWall` in internal/viewer before every UI listing that touches the viewer.
- Core's K22b LISTED (`wip/core-alerts-away` 5296bf06): final names (AskedLastHour, BotRefused; ErrBotWait, ErrBotStartOld; the Start
  link once, 1 h; ErrBotNoChat, ErrBotManyChats; ErrAwayWait, ErrAwayCap; new alert kind bot.refused; ActClick.MadeBy). Waits for
  P7's routes, then F16 (Settings › Alerts away; the chat box's made_by='alerts': B9's ACv LISTED `wip/b-alertclicks`
  b4d22edc: /api/act/chat/{id} clicks[].made_by "alerts", can [] (only cancel while queued), no in_chat hint; draw as the app's alert).
- (was) Coming from Core K22b (alerts away; collector doors, routes via P7): Settings › Alerts away: resend hours, sends per hour, names;
  the bot (a write-only token field, answers the bot's username and Start link; find chat; clear); Saved Messages account (0 off);
  Send a test per channel; records (sends, hours, bot actions, strangers). The chat box: a click with made_by='alerts' gets no
  "send again" and no verdict (act.js). Core's K27 BUILT (`wip/core-backup-nightly` b74d0e21): BackupNow, BackupStatus
  (On, Running, LastGoodAt, LastTryAt, LastFailure, NextRunAt, CopiesKept, Keep, Destination...), settings (on, time, keep, to);
  K28 listed: NewChatsDownload with `Accepted` values. Both wait for P7's routes, then Settings › Backup and Downloads rows (F14).
- **F16 LISTED** (`wip/ui-alertsaway` c7c8b3a7). F16a LISTED (`wip/ui-viewercounts` e4361094) with pages' QC 936f3500. All three
  (F15 first) wait for K24 + the bring-in.
- (was) **F16 with a coder** (`BRIEF-F16-alerts-away.md`, `wt-ui-f16`, `wip/ui-alertsaway` from F15 + pages' AW 5a879e87 + B9's ACv
  b4d22edc): Settings › Alerts away (bot token write-only), the alerts' sends, the chat box's made_by alerts.
- My own whole-app check on main be291417 (a real joined window, `runs-ui-1/try-final.sh`, `final-pictures/`): matches the agreed
  picture; found the viewer pages' list showing no Alerts/Mirrors/Queue counts (pages answer them): **F16a with a coder**
  (`BRIEF-F16a-viewer-counts.md`, `wt-ui-f16a`, `wip/ui-viewercounts` from F15); also Choose chats' text badges → avatar marks.
- **F7 MERGED** (main be291417; the owner's second folder built from it). F15 waits for K27/K28 (in the batch) and K24 + the viewer's
  bring-in (PL's condition); keep F15 current with each new head (merge it in).
- **F15 LISTED** (`wip/ui-nasgive` 4ac79050, holds F14, NG, PL). Pages' NG wording + unreachable_since commit to follow.
- (was) **F15 with a coder** (`BRIEF-F15-nas-giveback.md`, `wt-ui-f15`, `wip/ui-nasgive` from F14 780ad66a) (Accounts' NAS give-back): pages' NG LISTED (`wip/pages-nasgive` 1c70a00d, after N4): NAS facts held,
  held_words, unreachable_since/words, why, state_unreadable(+since,+words), give_back {held, words} (offered after 10 min without an
  answer), give_back_from; POST /api/nas/giveback {account, yes} (409 while the NAS works); Overview/Accounts `nas` is a kept brief
  (state, no_vpn live, as_last_read, last_read_at, held), also for a pc account whose old NAS holds files; removing can 409. With
  Alerts away (K22b routes) when they list.
- **F7 LISTED** (`wip/ui-words` fb02bd1f, replaces F13 + L3) and **F14 LISTED** (`wip/ui-settings2` 780ad66a, holds F7 + ND + BK).
- (was) **F7 built** (`wip/ui-words` 92c9b871 + a stale TestF9MirrorsEntry fix coming): titles' words behind "i", rows say the state only,
  one glossary, native Quit route, setup nav/error. Go-side long words listed (copychecks.go, exactsetting.go, twinhold.go, nas.go,
  alerts record words, launcher words.go): to pass to P7. Then the same coder does **F14** (`wip/ui-settings2`).
- (was) **F7 with a coder** (`BRIEF-F7-words.md`, `wt-ui-f7`, `wip/ui-words` from F13 8bcc0e3e + pages' L3 a99a3b74): the words pass;
  the native Quit route; the setup's step nav and error look. Then F14 (on F7): settings.js split into section modules;
  pages' ND LISTED (`wip/pages-newdl` 70e36ffd: /api/settings new_chats_download, POST new-chats-download) and BK LISTED
  (`wip/pages-backup` 60344917: /api/settings backup {status, on, time, keep, to, now_words, now_route}, POST backup/now, backup-on,
  -time, -keep, -to); a folder-pick route for backup's `to` asked of P7; Alerts away when K22b's routes list.
- **F13 LISTED** (`wip/ui-alerts` 8bcc0e3e): alerts + mirror rename. Next: F7 words over all (on F13), then F14 Settings (split
  settings.js into section modules; Backup, new chats' downloads, Alerts away when P7's routes list). (was:) alerts + mirror rename: pages' AL LISTED (`wip/pages-alerts` a2b6e93c, after Core's K22): GET /api/alerts
  (alerts, unseen, change, record, can_write, test_words), history, POST seen / test, `alert_thresholds` in /api/settings + POST
  alert-threshold, /api/shell counts["alerts"]: an "Alerts" list entry with its unseen count, an Alerts place (unseen first, mark
  seen, history), a quiet toast on a new alert, Overview's Needs you row, Settings › Alerts thresholds + Send a test. Also in F13: mirror RENAME (pages' RN LISTED
  `wip/pages-rename` 0a9674bf after M19: POST rename-plan {account, chat, title} → plan with cost, sends, blocked, a one-click token;
  POST rename {.., token} → result; 409 moved: fetch a fresh plan; 400 fields): a "Rename the mirror" step in the chat's Mirror
  sheet and the Mirrors place (plan shown, its cost said, one click), Settings' Coming row removed. MC now 094e16e5.
- **F11b LISTED** (`wip/ui-pages` 83ccb284). F12 folds F11b in, so UI-3 = F10b + F11b + F11c + F12 in one branch.
- (was) F11b the app's pages (`BRIEF-F11b-app-pages.md`, `wt-ui-f11b`, `wip/ui-pages`: Accounts + NAS, Queue, Staging,
  Import, Report) (also: remove the pages' own Theme row). Then F7 (words) over all.
- **F10 built** (`wip/ui-controls` e2218aa4): the control set (appshell controls.js/css; one dialog = AppShell.ask) and Settings
  rebuilt; 19 controls posting, 10 "Coming" rows (copy checks x6 + exact check: P7's CS; backup: Core's K27 then P7's routes, a Backup
  section to draw then: last good/try/failure, next run, copies kept, destination, time, on/off; joined-away: K28; rename: M19).
- **F11a built** (`wip/ui-chats` 221a90e4, holds F9 e23d1e81, F10 ad113ef0, MD): Chats as a list + side sheet, Mirrors place
  (`#/mirrors`), Date joined. UI-2 LISTED: `wip/ui-chats` c7b4c451 (on main 32d48a4c) = F9+F10+F11a. Owed: Overview's mirror links to #/mirrors;
  the list's mark for #/mirrors; the Mirrors place setting the list's count.
- (was) **F11a with a coder** (`BRIEF-F11a-chats-mirrors.md`, `wt-ui-f11a`, `wip/ui-chats` from ui-all 3192de6f): the Chats page as a list
  with a side sheet per chat (no sideways scroll; whole sentences; the mirror's state and choices readable), the Mirrors place, Date
  joined. The owner's picture of the live Chats page (11-22): "Is this UI being fixed?". F11b (Accounts, Queue, Staging, Import,
  Report, Copies, Overlap, Changes, About) after.
- For F11: a Mirrors place of my own over GET /api/mirrors (per account: chat, mirror_chat, state, by, forwarded, last_at, why,
  choice/word, never, stopped, protected, offers; ?counts=1); pages' MD (`wip/pages-mirrordoors`) adds titles, made_at, topics, and
  the Chats rows' `joined` (Sort by "Date joined", the owner's ask). F9 meanwhile: "Mirrors" in the list opens the Chats mirror filter.
- For F11's Accounts: pages' N4P LISTED (`wip/pages-nas` 485ba7b3; shapes in `docs/progress/pages-nas-REPORT.md` there): each account's
  place pc|nas, pairing (file download), NAS sign-in steps, forget; `no_vpn` shown LOUDLY wherever it appears (also Overview, Accounts).
- Next: owner's word on the plan; F1 and F5 hand back, pictures to the owner, list; F2 on P7's door.
