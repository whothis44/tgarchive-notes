# The NAS runs the app; the PC is its dashboard (session N-1, 11-22; for the owner's yes)

**The owner, 11-22 morning:** "the PC can decide and send commands, but once that's done, the NAS needs to be
autonomous. The PC is effectively the dashboard/controller ... the NAS needs to handle the rest, even if the PC is off";
"so that the PC can be turned off or used for something else while the NAS still forwards, and downloads when we turn
it on". This replaces the 11-14 condition "control remains on the PC". Nothing here is built; nothing runs.

## In one paragraph
The whole collector (catalogue, reader, mirror and its automatic task, downloads, copy checks, alerts and the bot) runs
on the NAS, headless, in one container, reaching Telegram only through the WireGuard tunnel already built (`wgdial`) or
direct with the no-VPN setting. The PC's app becomes a window onto it: the same pages and viewer, served by the NAS and
shown in the PC's own window over the home network. Every command (a chat to mirror, a download switched on, a pause,
a sign-in step) is stored in the NAS's catalogue and carried out there, so it goes on with the PC off. **Checked today:
the collector, the watchdog, the backup and the main program (with the viewer and pages) all build for Linux as they are
(`GOOS=linux CGO_ENABLED=0 go build`, 11-22).**

## 1. Where the catalogue and the decisions live
- **On the NAS:** the catalogue (SQLite, on the NAS's own disk, never on a share: SQLite over a network share is not
  safe), the account sessions, the collector's tasks (reader, live monitor, mirror and its automatic task, the engine,
  staging or straight-to-library writing, the copy checks, fingerprints and thumbnails as files land, alerts, the bot),
  the viewer's server. The library is the NAS's own folder, read and written locally: no Wi-Fi copy at all.
- **On the PC:** the app's window (`tgarchive.exe`, Windows only) and nothing that decides. It shows the NAS's pages and
  viewer; it can be closed or the PC turned off at any time.
- **Recommended.** Other way: catalogue on the PC and the NAS as a pure downloader (what N2 to N4 built): the PC must
  stay on for anything to happen, which is what the owner no longer wants.

## 2. How a command reaches the NAS and is carried out with the PC off
- The PC's window shows the pages the NAS's collector serves (the collector already serves its own pages, `-pages`); a
  click is a request to the NAS, written into its catalogue (the click ledger, the mirror's wants, the download switches,
  the pause with its end time) before anything is sent to Telegram, exactly as today on the PC. The NAS's tasks read
  those rows; nothing waits on the PC.
- The owner's bot (Core's K22b, two-way commands) runs inside the NAS's collector, so a command by bot works with the PC
  off; an automatic mirror after rejoining a chat is the collector's own task, also with the PC off.
- **The connection:** the NAS listens on its home address only; the PC reaches it through the window's own gate (it
  already proxies every request of the window) over mutual TLS with the keys paired once (N2's `nasproto.Pair`), so no
  other device at home can use the pages. Never through the VPN. **Recommended**; other way: a password on the pages
  (weaker, one more thing to type).

## 3. The PC's downloads versus the NAS's: one engine owner
- One collector holds a catalogue at a time (the staging mark and the catalogue's own lock already refuse a second). With
  the catalogue on the NAS, **the PC downloads nothing for that archive**: the speed limit is the account's, so a second
  engine on the PC adds no bytes, and its bytes would have to cross the Wi-Fi. **Recommended.**
- "Toggle a download on the PC" is a command to the NAS (section 2). The PC's own app keeps no lanes for an account
  the NAS holds. If one day the PC should help (another account, or the NAS away for long), the N2 link already does the
  reverse role (a remote engine with the catalogue elsewhere); not proposed now.

## 4. Sign-in and the VPN
- **One WireGuard key per program (Core's review of NA2, 11-22):** on the NAS the collector and the NAS downloader (`nasdl`) never share one WireGuard key or file; two programs on one key disturb each other's tunnel. Each gets its own Windscribe WireGuard file.
- **The VPN:** decided: WireGuard inside the container (`wgdial`), Windscribe, the no-VPN setting off by default and said
  everywhere; the collector's dialler gets the tunnel's resolver (the shared `libclient` dialler already takes one).
- **The sign-in, two ways:** (A) **move the PC's login to the NAS** with the catalogue (the session file and its key
  copied once, the PC's copy then removed and its app refusing to run that account): one login, no new device on the
  account; the risk is a copy left running in two places at once (Telegram would cancel the login), closed by the move
  being one step of the app that marks the PC's side moved. (B) a new sign-in on the NAS (agreed on 11-21 as fine): shows
  as a new device; the PC's login stays unused. **Recommended: A** for accounts already signed in; B for a new account.

## 5. Memory (Plex stays, about 2 GB; about 4.4 GB available with JDownloader gone)
- Measured on the PC today, the owner's running collector: 49 MB working set, 101 MB private (catalogue about 37 MB).
  The unified archive (the old app's catalogue brought in, 1.9 GB) makes the catalogue far larger: the page cache is set,
  so memory should grow with the indexes in use, not the file; **not measured**. The viewer's warm index on about 400,000
  messages: **not measured**. ffmpeg for fingerprints and thumbnails: one at a time, its own limit.
- **Measured 11-22 (NA1, `MEASURE-NA1-memory.md`; on the PC, in Docker, one run each, an invented archive of 401,407 messages, 136,289 files, a 392 MiB catalogue):** the collector headless, 32 minutes of its tasks on the fake Telegram: Go heap 20 to 69 MiB, the container's own memory about 105 MiB steady, 204 MiB at peak, about 0.4 of a core; the viewer: index built in 2.6 s, 226 MiB of Go heap, 803 MiB at peak (about 250 of it SQLite's), about 570 after 10 minutes. **Limits set from it:** collector 768 MiB (`GOMEMLIMIT` 512MiB), viewer 1 GiB (`GOMEMLIMIT` 600MiB, one thumbnail maker), ffmpeg 512 MiB: 2.25 GiB of the about 4.4 available. Not measured: ffmpeg, real Telegram, the NAS's slower processor, the viewer under `GOMEMLIMIT`, and the real unified catalogue (about five times larger): the viewer is the one to watch; its first run on the NAS is measured before the move.
- **First:** measure the headless collector and the viewer in Docker on the PC with the NAS's limits, on a copy of the
  owner's catalogue with the old archive brought in (opened read-only, numbers only), a day's worth of fake traffic.
  Proposed limit: 1 GB for the collector's container, 512 MB for ffmpeg's; to be set from that measurement.

## 6. What is reused and what is new
- **Reused as is:** the collector and all its tasks, the engine, the store, the catalogue, the mirror, the bot and
  alerts, the viewer's server, `wgdial`, N3's container style (`deploy/nasdl`: host mode, 1000:10, read-only root, no
  capabilities, limits, the heartbeat check), `nasproto.Pair` for the keys.
- **New:** (a) `deploy/nas-app`: the collector, watchdog, backup and viewer in one image, its compose file and README
  (Core's packaging with this track); (b) the collector's Telegram dialler through the tunnel on Linux, and the VPN gate's
  NAS form (route check off, address check through the tunnel), as N3 already does for `nasdl`; (c) the pages and viewer
  listening on the NAS's home address behind the pinned keys; (d) the window's gate forwarding to the NAS (the UI and
  viewer tracks); (e) the move (section 7); (f) the measurement of section 5.
- **What happens to N2 to N4** (the NAS as a downloader for the PC's catalogue): merged or listed, they stay as they are
  and nothing more is built on them; the autonomous NAS does not need them. Whether to keep them as an option or remove
  them later is the next integrator's call.

## 7. The move, and back
- **To the NAS:** one step of the app, with the counts first: the PC's app stops its collector (the owner's quit), takes
  a consistent copy of the catalogue (`tgarchive-backup`), copies it, the sessions and their keys (A), and the settings to
  the NAS's program folder; the NAS's container starts on them; library paths are already relative to the library root,
  so only the root setting changes (the NAS's own path); files waiting in the PC's staging are copied first, or left to
  be fetched again (said with their count). The PC's app then opens as the dashboard.
- **Back to the PC:** the same step the other way (the NAS stops, the copy comes back, the PC's app runs the collector
  again). Neither direction leaves two collectors on one catalogue or one login in two places.
- First on the TEST account's archive, then the owner's.

## For the owner's yes (one line each on the board)
1. This shape (the NAS runs everything, the PC is the dashboard). Recommended: yes.
2. The login: move the PC's login to the NAS (A). Recommended: A.
3. The PC downloads nothing for an archive the NAS runs. Recommended: yes.
