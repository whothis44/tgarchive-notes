# Audit: features we think we have, against what the owner's app runs (2026-11-22)

Read-only. Sources: main at e34f4f64 (the build in the owner's folder, `folder.version` says so), `ROADMAP.md` and
`FEATURES.md` at that commit, the launcher's run line (`internal/launcher/start.go` `collectorArgs`, the stored
`run_flags`), the collector's flags (`internal/collector/command.go`, `framecheck.go`, `mirror_auto.go`,
`pairwordsline.go`, `pages_cmd.go`), and the owner's catalogue opened read-only (setting keys and row counts only).

**The run line the launcher builds:** `run -db -staging -library -vpn-adapter -public-forbid -pages -pages-addr
-viewer-url -launcher-url -no-links -read-back-now`. Not passed: `-frame-check`, `-fingerprints`, `-pair-words`,
`-nas-helper`, `-auto-mirror` (the stored per-account switch is on instead), `-auto-mirror-download`,
`-new-chats-download`, `-exact-spot-*`. The viewer runs joined in the window on the app's own catalogue, with no `-lan`.

**What the catalogue shows ran (counts only):** 1,205 files saved and verified, all in the library; 0 hard links
made, with 262 files owing links; 0 video fingerprints; 0 frame-check rows (`c_probe`) and 0 kept parts (`c_part`);
284 probable-copy edges and 278 files held as "looks like a saved file"; 0 lesser-copy holds (`c_twin`); 0 owner pair
verdicts applied (`c_pair_word`); 721 messages marked deleted and 291 earlier versions kept; 5 mirrors with 675
forwards and 8 mirrored topics; 1 send click, done; 0 known-file imports. The stored copy settings: none, so every
copy switch is at its default. `settings`: exact check on, held copies wait on, hand-over off.

**States:** A running now · B built, switched off (flag not passed, or off by default) · C built, not wired · D only
on the page · E only ever run on invented data or a copy · F listed, not built.

**Correction to what we thought:** the reuse of kept parts is wired into the engine. Since 11-16,
`collector/account.go:823` gives `ecfg.Parts` the value of `enginePartStore` (`framecheck.go:794`), but that is the
frame check's store and it is nil while the frame check is off. So it is **B, not C**, and it comes on with the frame
check. ROADMAP row "Kept parts reused by the download" still says "To build: the collector's lines". That line is out
of date.

## 1. Deduplication

| Feature | State | The switch or the missing line | Track | What it takes |
|---|---|---|---|---|
| Sampled-frame check before download | **B** | `run -frame-check` (`framecheck.go` `flagFrameCheck`, default false); stored key absent; the launcher does not pass it | copies | C31 (with a coder): on by default; then the owner's first real run and the `probe-misses` count |
| Video fingerprints of saved files (the worker) | **B** | `run -fingerprints` (`flagFingerprints`, default false); 0 fingerprints in the catalogue | copies | C31 turns it on; the frame check has no candidates until fingerprints exist |
| Kept parts reused by the download | **B** | wired through `enginePartStore` (`framecheck.go:794`), nil while the frame check is off | copies | comes on with C31; fix the ROADMAP row |
| More frames on the cusp (second round) | **B** | inside `footage/ffmpeg/check.go` (`MoreRounds`), so it runs only when the frame check runs | copies | comes on with C31 |
| `tools/probe-misses` (the frame check against outcomes) | **E** | never run on a real catalogue; there is nothing to count while the check is off | copies | run it after the first real week of the frame check |
| The copy checks' six settings on the Settings page | **C** | doors exist (`internal/copyset`, collector `copyset_door.go`); no control in `server/web` (grep: no "frame check" on any page) | UI | F10 (Settings rebuilt) with a coder |
| The owner's "same / not the same" applied to held copies | **B** | `run -pair-words <viewer data folder>` (`pairwordsline.go:219`, default off); `internal/launcher` never passes it; 0 verdicts applied | pages (launcher); copies | the launcher passes the window's data folder; the viewer records verdicts today that nothing reads |
| ONE UNIFIED ARCHIVE: copy checks against the old archive, new media flagged | **F** | the app's catalogue holds only the new accounts; the bring-in into the app's catalogue (viewer U1, pages L1/SW, Core K24) is listed, not merged | copies leads; Core, viewer, pages | merge K24, then U1 and L1; the owner starts the step on a copy first; then the cross-archive rules (`DESIGN-UNIFIED-ARCHIVE.md`) |
| Fingerprints for videos already in the library | **F** | C29 with a coder (605 library videos have none) | copies | merge C29 |
| Whole-album rule (off, counting) | **F** | C28 listed (schema slot 36), not merged | copies | merge C28 |
| Confirm or release held files by a check; probe held files | **F** | C30 paused | copies | after C31 |
| Copy checks run on the NAS | **F** | no host program or control interface | NAS; copies | with the NAS downloader |
| Exact re-upload check (three places) | **A** | `settings.exact_check` on; `exact-mode` default | copies | nothing |
| Exact spot checks | **B** | `-exact-spot-every`, `-exact-spot-first` are test flags, off by design | copies | nothing (on purpose) |
| The same Telegram file never fetched twice; forwards of a catalogued post | **A** | none | copies | nothing |
| Look-alike hold (old app's rule) and the step at save | **A** | 278 held, 284 probable edges | copies | nothing |
| A look-alike of a saved file's byte size goes to the exact check first | **A** | engine `HoldUnlessSame` | copies | nothing |
| A held copy waits for the owner (`held_wait`) | **A** | `settings.held_wait` on; switch on the Queue page | copies; pages | nothing |
| Lesser copies wait behind the best one | **A** | `copies.twin_hold`, on by default since 11-22 (`catalog/twin.go`); none found yet; door for a page, but no control (F4 of `copies-twin-on-2026-11-22.md`) | copies; UI | a Settings control in F10 |

## 2. Saving before deletion (download, library, safety)

| Feature | State | The switch or the missing line | Track | What it takes |
|---|---|---|---|---|
| Lanes, waits with margin, resume, reference refresh, window upward, files only from chosen chats | **A** | defaults | Core | nothing (path finished) |
| Delete marks on messages | **A** | 721 marked | Core | nothing |
| Edits kept with earlier text; auto-delete timer tagged | **A** | 291 versions; 231 tagged | Core | nothing |
| Staging, then a verified copy to the library | **A** | read-back (`-read-back-now`); the library is on a local drive | Core | nothing |
| The NAS helper verifies a copy | **B** | `-nas-helper` not passed (the library is local today) | Core; pages | pass it only when the library moves to the NAS |
| Hard links for a file posted in several chats | **B** | `-no-links` is in the launcher's default `run_flags` (`launcher/settings.go:89`); 0 links, 262 files owe them | pages (launcher default); Core | drop `-no-links` from the default when the owner agrees (FEATURES 12, sixth round, says "on by default") |
| Nightly backup, a copy before an update, `Back up now` | **C** | `tgarchive-backup.exe` ships in `programs/`, but nothing starts it: no timer in the collector or launcher, no button | Core; pages | the timer and its retries in the collector, and a button; the update command could call it first |
| Every chat the account sees read early, messages only | **F** | only approved or chosen chats are read; no "read all" and no cost line | Core; pages | brief it (the owner said yes on 11-13) |
| Chats not added: media counts, one request each | **F** | none | pages; Core | brief it |
| Downloads only in hours without the speed limit | **F** | the engine has no such mode | Core | brief it |
| Hand-over between accounts on a wait | **B** | `settings.hand_over` false (off by design) | Core | nothing unless asked |
| Asking again before a stated wait is over | **B** | off by the owner's rule | Core | nothing unless the owner asks for the trial |
| An account's number never given twice | **F** | latent; nothing deletes an account yet | Core | a schema step before any delete exists |
| Watchdog restarts and crash log | **A** | the launcher starts the watchdog; no crash met | Core | nothing |
| Status file, hourly counts | **A** | `collector-status.json` beside the catalogue | Core | nothing |
| The numbers-only report saved to a file | **F** | page only | Core | small |
| The account's own chat (Saved Messages) read by itself | **A** | merged 11-21 | Core | nothing |

## 3. The mirror

| Feature | State | The switch or the missing line | Track | What it takes |
|---|---|---|---|---|
| A chat joined is mirrored by itself | **A** | stored `mirror.auto.new.<account>` = on; 5 mirrors, 675 forwards | mirror | nothing |
| Mirror from the Chats page; plan, yes, stop, never, allow | **A** | `c_mirror_want` 5 | pages; mirror | nothing |
| Forums mirrored as forums, with topics | **A** | merged 11-22; 8 topics | mirror | M17 for titles and pace |
| A deleted source message never blocks a mirror; exact repeats not forwarded | **A** | merged 11-22 (M14) | mirror | nothing |
| A protected chat refused before any request; cap per 24 h; varied timing | **A** | stored settings | mirror | nothing |
| An unknown batch settled by itself | **F** | M16 with a coder; today only `mirror -settle`, a command with the collector stopped | mirror | merge M16 |
| Topic titles, and the pace of topic creates | **F** | M17 with a coder (now about one create every 2 min) | mirror | merge M17 |
| Adopting an existing chat as a mirror | **E** | `mirror -adopt -into` (schema step 28): a command only, with the app stopped, never run (`c_mirror_adopt_wait` 0) | mirror | the owner names a pair (board item); a page later |
| Renaming a mirror; gathering new messages for N minutes | **C** | `mirror -rename`, `mirror -gather`: commands only, with the collector stopped; no control in the running app | mirror; UI | a Settings or Mirrors control (F10, F11a) |
| Downloads for a chat joined while away | **B** | `-auto-mirror-download` not passed (off is the owner's default); no page setting; the "only in unlimited hours" value is **F** | mirror; Core; pages | a setting on a page; the hours mode in the engine |

## 4. Alerts

| Feature | State | The switch or the missing line | Track | What it takes |
|---|---|---|---|---|
| Alerts (a Windows notification; the bot and Saved Messages; the bot's answers) | **F** | K22 (schema 34) in its last round, not merged; K22b next | Core | merge K22, then K22b |
| The watchdog's state on the Overview | **F** | the watchdog does not tell its child where its folder is | Core; pages | small |

## 5. The viewer

| Feature | State | The switch or the missing line | Track | What it takes |
|---|---|---|---|---|
| The unified viewer over the old archive, in the app | **C** | the launcher opens the viewer on the app's own catalogue only (`viewerSpec`, `-db l.Catalog`); the brought-in catalogue is a separate copy | viewer; pages | the bring-in into the app's catalogue (U1, L1), as above |
| Bring-in `plan`, `run`, `verify` | **E** | real only on a copy, into a catalogue of its own (11-14, 11-15) | viewer | as above |
| "Who is in it", "No faces" | **C** | the data comes only with the bring-in, so these are empty in the running app | viewer | follows the bring-in |
| One tile per file, posts, search, thumbnails on demand, staged and lost files | **A** | none | viewer | nothing |
| Probable copies grouped; the verdict page | **A** | the verdict reaches the collector only through `-pair-words` (section 1, **B**) | viewer | see section 1 |
| The Changes feed (deleted, edited) | **A** | 721 deleted, 291 versions to show | viewer | nothing |
| "First seen here", "only here", overlap | **A** | within the new accounts only; across both archives is **F** (unified archive) | viewer | follows the bring-in |
| The native window, mpv, the gate | **A** | `tools/mpv.exe` and `tools/ffmpeg.exe` in the folder | viewer | nothing |
| Every thumbnail in the background (`tgarchive thumbs`, the NAS container) | **C** | a command; nothing starts it; never run on the NAS | viewer | start it from the launcher, or the owner's measuring run of 200 on the NAS |
| Use from other devices at home (password, HTTPS) | **B** | `-lan` not passed (`launcher` has no `-lan`) | viewer; pages | the review's F5 (where the key lives), then a setting |

## 6. The rest

| Feature | State | The switch or the missing line | Track | What it takes |
|---|---|---|---|---|
| The client: send in a chat | **A** | one real send, done | client; Core | nothing |
| The client: reply, edit, delete, forward, react, mark as read | **E** | live in the window, never run for real | client; Core | the owner's first click of each |
| The client: join, leave, mute; send a file from the archive; upload | **F** | A-1 pieces 1 to 3 with coders | client | merge in order |
| One window: the list, the Overview as a dashboard with links, counts in the list | **A** | merged 11-22; the owner has not seen it | UI; pages | the owner looks |
| Title bar, Quit dialog, pill, details panel, Settings rebuilt | **F** | F9 and F10 on `wip/ui-all`, not merged | UI | merge |
| Sign-in and accounts pages; Staging and Queue pages; pause; Stop and Start; estimate and approve | **A** | none | pages | nothing |
| Import page (lists of known files) | **E** | 0 imports on the real catalogue | pages | only when the owner has a list |
| The owner's update command | **A** | `update-folder.ps1` put e34f4f64 in; automatic updates are **F** | pages | signed updates later |
| NAS downloader: tunnel | **C** | `internal/wgdial` merged, no caller | NAS | N2, N3 and N4 |
| NAS downloader: link, program, PC side | **F** | N2, N3 listed; N4 in review | NAS; Core | merge in order |
| Thumbnails made on the NAS as files land | **F** | needs a measurement first | NAS | after the downloader |
| Plain-file export, monthly re-read, adoption and clean-up plans, collections, recognition | **F** | none | Core; viewer | the "Later" row of the ROADMAP |
| Hard links for the old library's files | **F** | toggle, off | Core | with the bring-in |
| Deadline forecast and banners, read-only end state, lower quality first, frozen sign-in, Takeout | **F** | off the path by the owner's direction | Core | nothing (not owed) |

## Count per state (rows above)
A 27 · B 12 · C 7 · D 0 · E 5 · F 21 (72 rows). No D: every page control found has a working door behind it. The opposite
gap shows up instead: doors with no control (the copy settings, the lesser-copies switch, rename and gather).
