# The NAS downloader track: progress

Started by the integrator I-6 on 11-21 at the owner's word. The owner's condition (11-14): "as long as the
app/control remains on the PC and connects to it". The NAS part only fetches, writes and hashes; the catalogue,
the checks, the viewer and all control stay on the PC. Also in this track: thumbnails made on the NAS as files
land (roadmap row; a measurement first).

Owns (nobody else edits): to be named in the design note and on the board's Tracks row.

## SESSION N-1 (Opus; started 11-21 21:23)

- 21:23: started. Reading `CLAUDE.md`, `BOARD.md`, the three NAS memories, then the history files in full.
  Nothing runs, nothing is built, nothing is deployed to the NAS. Next: the design note `DESIGN-NAS-downloader.md`.
- 21:27: read in full, myself: `CLAUDE.md`, the board's Direction, Tracks, Listed-and-unbuilt and Waiting sections and
  the messages of 11-21; the three NAS memories; `TRIED-BEFORE.md` (all 28 sections); `LESSONS.md`;
  `WINDOW-EVIDENCE.md`; `TELEGRAM-FACTS.md` 1, 2 and 8; `ROADMAP.md` staging rows and row 200; `ANSWERS-for-archiver-7.md`
  and `-8.md`; the code of `internal/engine/types.go` (interfaces), `internal/store` (writer, `Ledger`),
  `internal/nashelper`, `internal/telegram/connect.go` and `vpn.go`, `deploy/nashelper/compose.yaml`.
- 21:29: **`DESIGN-NAS-downloader.md` written.** In short: the same engine and writer run on the NAS (imported,
  unchanged); `Supply`/`Ledger`/`Checker`/`PartStore` answered by the PC over the home network (the PC dials, mutual
  TLS, never via a VPN); a journal on the NAS so no finish is lost; fail closed without the PC; the tunnel is WireGuard
  in user space inside the program (host mode makes a gluetun container touch the whole NAS); the gain is the Wi-Fi
  copy that disappears, not more bytes from Telegram. Owner's decisions: items 46 (session: own sign-in on the test
  account, recommended), 47 (VPN inside the program, recommended), 48 (two memory numbers from the NAS).
- 21:30: briefs `BRIEF-N1-wgdial.md` (the tunnel, `internal/wgdial`, and the M2 speed test) and `BRIEF-N2-link.md`
  (`internal/nasproto`, `internal/nasctl`, `internal/nasdl`: the link, journal, exactly-once, fail closed). Lock script
  `runs-nas-n1/go1.sh` (a copy of Core's with its own lock). PC at 21:30: CPU 73%, 7.9 GB free.
- 21:31: **TWO OPUS CODERS STARTED (high effort, background agents of this session):** N1 in `wt-nas-wgdial` on
  `wip/nas-wgdial` from af4ca40e; N2 in `wt-nas-link` on `wip/nas-link` from af4ca40e. Both only add packages.
- 21:32: board: my Tracks row; message 217 (to Core: the collector's side later, N4, and the gate's seam; to the
  integrator: the thumbnails row and ROADMAP 137-138 and 200 now have this track as owner); items 46-48; the
  thumbnails line of "Listed and unbuilt" names this track.
- Committed: these notes on `notes` as 50023ba (one command; not a clerk: a single command). This folder has no remote: nothing to push. Pushed: nothing of code yet.
- **Next:** read each coder's hand-back myself (the risky part: N2's exactly-once and fail-closed; N1's "no fallback"
  proof), then an independent Opus review of each, its fixes, then the full runs once (say the plan first), then list
  in `MERGE-QUEUE.md`. Meanwhile: brief N3 (the program and its deploy files on the fake Telegram, M3) once N2's
  wire has settled.
- 21:45: **THE OWNER DECIDED (21:43):** item 46, its own sign-in on the NAS ("fine"); item 47, WireGuard inside the
  program as recommended, Windscribe likely, **plus a stored no-VPN setting** (off by default, shown everywhere);
  memory 3,973 MB available, swap 1,397 MB used. Asked: whether the NAS's Tailscale uses an exit node; `docker stats`
  needs `sudo` (the owner's user is not in the docker group). Board items 46-48 marked, message 222 to the integrator;
  design sections 4, 5 and 8 updated. The no-VPN mode goes into N3 (the program's choice of dialler), not into N1.
  The owner said "Standby": nothing new is started until the coders hand back.
- 21:55: **N1 HANDED BACK:** `wip/nas-wgdial` 6fc6346a, pushed (2 commits over af4ca40e; `internal/wgdial` only, plus
  new lines in go.mod/go.sum: wireguard-go MIT, gVisor Apache-2.0). 10 tests pass on Windows; vet and gofmt clean;
  builds for linux/amd64 and arm64. Loopback 21.9 and 25.1 MB/s with both ends in one process using about 1.8 cores
  (PC, one run each): the NAS's processor may limit the tunnel before its 46 MB/s link: M2 decides. The gate's
  address check needs no edit of Core's `vpn.go` (`PublicConfig.Client = tun.HTTPClient(0)`; `RouteConfig` nil on
  the NAS): message 217 (c) is answered. My own read of the risky part (every dial, `tunnel.go` 416-537,
  `dialers.go` 114-159): Telegram dials only through the netstack; the only system dial is the LAN dialer, private
  ranges checked before and in the socket's Control hook. The VPN server's name is looked up once at start by the
  NAS's own DNS (an address in the file avoids it).
- 21:56: **independent Opus review of N1 started** (background, read-only, report `REVIEW-N1-wgdial.md`). N2 still
  coding. Next: N1's review fixes (by its coder), then list N1; N3's brief after N2.
- 21:57: **THE OWNER ACCEPTED the Tailscale recommendation:** kept for remote access, no exit node used by or offered from the NAS. Board item 47 and the design note say so.
- 21:59: the owner checked the NAS: no Tailscale routing table on the NAS itself (table 52 absent), Tailscale runs in a container of its own; so no exit node carries the NAS's own traffic, and the downloader (host mode) is not affected. Nothing to change.
- 22:10: **N2 HANDED BACK:** `wip/nas-link` f0abe449, pushed (9ce3b4d9 + f0abe449 over af4ca40e; three new packages,
  no existing one edited, about 6,000 lines). Tests pass twice; gofmt and vet clean. Exactly once by a journal number
  per NAS journal epoch, kept by the PC in `Config.StatePath`; a double effect still possible only if the PC crashes
  between an effect and that file's write (then one entry: harmless for the supply's finishes, an extra counted try
  for `CopyFailed`/`CopyBack`, `Checked` twice). Owed by others: the catalogue supply's `Finished`/`Duplicate` hooks
  wired to the controller (N4), the collector's `Recover` at start still needed. My read of `nasctl/apply.go`: an entry
  whose apply returns an error still has its number recorded, so a retry is answered as a duplicate: given to the
  reviewer to settle (it may lose a finish). For the race list: every `internal/nasdl` test but one, three in
  `nasproto`.
- 22:12: **independent Opus review of N2 started** (background, read-only, `REVIEW-N2-link.md`).
- 22:15: **N3 BRIEFED AND STARTED** (`BRIEF-N3-program.md`; Opus, high effort, background): the program
  `cmd/tgarchive-nasdl` (serve, vpntest, check, pair), its assembly in `internal/nasdl`, the no-VPN setting, the NAS
  side of the sign-in on the fake Telegram, the window policy's memory over the link, `deploy/nasdl` (host mode,
  1000:10, 384 MB), M3 in Docker on the PC. Copy `wt-nas-program`, branch `wip/nas-program` = `wip/nas-link` with
  `wip/nas-wgdial` merged in (a local base; the reviews' fixes are merged in later). PC at 22:15: CPU 84%, 6.6 GB free.
- **Running now:** the reviews of N1 and N2; the N3 coder. **Next:** each review's fixes by a fresh Opus coder on its
  branch (the original coders are finished), then the full runs once (plan said first), then list N1 and N2 in
  `MERGE-QUEUE.md`.
- 22:16: **N1's REVIEW IN** (`REVIEW-N1-wgdial.md`): the main property holds (nothing of the tunnel's client leaves through the system's network; proxies ignored; LAN dialer sound); CONFIRMED: the private key printed through %v of a *Tunnel or an unexported Config field (fix before any use), a healthy idle tunnel held down by a short limit, IPv6 taking the one probe, "down" reported at twice the limit, HTTPClient transports never released, a failed Start leaking goroutines; smaller ones and weak tests. My decisions on each sent to N1's coder (resumed, same worktree, fix round on `wip/nas-wgdial`); the two integration notes (refuse without the tunnel's resolver unless no-VPN; RouteConfig unset) sent to N3's coder. N2's review and N3 still running.
- 22:26: **N2's REVIEW IN** (`REVIEW-N2-link.md`): two HIGH, CONFIRMED: an error answer counted as acknowledged (a ledger write lost for good; my question of 22:10, confirmed), and grants in the PC's memory only (a PC restart leaves files owned by nobody; the collector's Recover would free files the NAS is downloading); MEDIUM: a finish sent unjournaled with seq 0 and lost, a replay over 1,024 entries looping (2,500 entries sent 7,016 times), finishes waiting 30 s for acks on the checkpoint path; six low ones; weak tests (no PC restart, no error answer). Sound: TLS pinning, allow-list, privacy, order, fail closed for Next/Claim/Refresh/Check. My decisions on each sent to N2's coder (resumed; fix round on `wip/nas-link`). For N4's brief: the collector's Recover must skip files held by a NAS (Controller.Held). N1's fix round and N3 still running.

## STATE, session N-1 (Opus), 11-22 01:05
- Design: `DESIGN-NAS-downloader.md` (owner: own sign-in on the NAS, test account first; WireGuard inside the program,
  Windscribe; a no-VPN setting, off by default; Tailscale kept, no exit node; limit 384 MB beside Plex).
- N1 MERGED (09d63f94). LISTED: N2 `wip/nas-link` 3764935a, then N3 `wip/nas-program` 868d1b6f (a nasdl data race the integrator's race run found, fixed by me 02:22, race clean in 601 s) (each: one review and a
  second pass, all fixed). Nothing of mine runs. N4 (the PC's side) routed by the integrator to Core K-6 (local_427edf26) and pages P7 (local_b6590024): `NOTE-N4-collector-side.md`. N2, N3 merge in a coming batch with race runs.
- 05:21: **N4 LISTED** (`wip/nas-pcside` 24630f73, after N4P; two review looks; a staging-part leftover found after the merge fixed).
  N4's fix round, besides the review's findings: `NASState.Held` and `UnreachableSince` (at its end); door `NASGiveBack(ctx, acct) (int, error)`; copies' test (a file finished on the NAS while the PC was down is judged by its finish); the livepages wiring as ONE commit \"Lent to pages (livepages):\" (pages reads its head first; `docs/progress/pages-nas-REPORT.md` \"What waits for Core's doors\"). Tell pages the door names when listed. Merge `wip/nas-program` 868d1b6f (the nasdl race fix) into N4 in that round.
- Next: N5 (fingerprints and thumbnails on the NAS as files land) after the owner's thumbnail measuring run (item 31);
  the owner's first real steps after N4: `vpntest` on the NAS (M2), then the test account into a test folder.

## STATE, session N-1 (Opus), 11-22 14:57: the autonomous NAS, built in small pieces on main a0de4f1
- 14:57: NA2 and NA3 MERGED (a0de4f1). **NA3b LISTED 15:54** (`wip/nas-headless` 2bee3134, holds main 3c0c4fa6; earlier: its review back ("may be listed"; 4 shoulds: the staged-wait count, -read-back-now implied, an explicit -no-staging, ErrNASOldArchive mapped in the pages as a lent-to-pages commit): fix round with its coder; race clean (store 33 s, collector named 103 s; `runs-nas-n1/race-na3b.log`); NOTE: without staging the fingerprint and picture-hash workers are off, so the NAS runs WITH a staging folder on its own disk: deploy README to say so: folded into NA4's fix round, which edits that README) (lent to Core: NAS doors refuse the brought-in account, `check` health command, `-staging` optional, TestNASSwitchPlaces's bound) and NA4 (built: `wip/nas-gate` 447668c6, ALPN streams, one NAS port 8799; review back: no way in but the paired PC; 2 medium availability faults (half-closed connections hold places, strangers fill the handshake places) and low ones: fixed (c25fd362; staging required in compose and README; race clean after a test-only race fixed); **LISTED 15:48** at 49dd0d0b, race clean). Core K-6 handed over (context full): NA3b's read and review go to the next Core session, routed by I-7 (send the hand-back to I-7). **NA5 built** (`wip/nas-move` 50bd1206: mark b058606b, Core's lent 8eb5f317, the command 50bd1206; review back: 4 HIGH CONFIRMED (a scp'd copy of the bundle places the login twice; `back` takes an older round trip's bundle; -bundle around staging deletes staged files; the NAS collector refuses the PC's old-library path) and MED ones (backups keep the login files; a wrong key; decisions.sqlite not moved): fix round with its coder, then a second pass). Was: NA5, the move (15:55; `BRIEF-NA5-move.md`, `wip/nas-move`: `tgarchive-nasmove out/in/back` with a moved mark, sessions removed only after the bundle verifies; a lent collector refusal, read by I-7 since Core and pages are archived; one review). NA3b and NA4 go in I-7's NAS batch after V1. Then: the launcher's button and starting the PC's `back` gate (pages). Owner's install steps: written here when a piece needs one.
- Integrator now: **I-7** (local_78ac6953-2e70-4c12-a371-4f255f71e85c): listings and reports go there. N4 MERGED inside F15 (head 2b38b2a3); new pieces build on it. K24 (Account.BroughtIn) not on the head yet: the owed refusal waits.
- Merged: N1 tunnel (09d63f94), N2 link and N3 NAS program (wip/nas-program 868d1b6f). LISTED: N4, the PC's side
  (`wip/nas-pcside` 24630f73, after pages' N4P; Core's read, one review and a second look, all fixed). Nothing runs; no agent.
- 09:58: **NA2 LISTED** (11:19, `wip/nas-ctunnel` 6a04d72c; review fixed; race clean); 10:46; lent to Core; `BRIEF-NA2-collector-tunnel.md`, `wip/nas-ctunnel`, `wt-nas-ctunnel`) with an Opus coder, and **NA1 DONE** (`MEASURE-NA1-memory.md`: collector about 105 MiB steady, 204 peak; viewer 803 MiB peak; limits 768 MiB / 1 GiB / 512 MiB; harness `wip/nas-measure` gated, not for merge; the 36 GiB Docker volume removed) (invented archive at the unified size; collector and viewer in Docker with the NAS's limits) with an Opus coder (`BRIEF-NA1-measure.md`, `wip/nas-measure`, `wt-nas-measure`); **NA3 LISTED 12:20** (`wip/nas-app` f46449cc; needs from others: a collector `check` of the status file's age, `-staging` optional, the pages' listen flag (NA4), the viewer on a read-only WAL catalogue) (12:04, `BRIEF-NA3-deploy-nas-app.md`, `wip/nas-app`); then: the collector's dialler through the tunnel on Linux and the gate's NAS form; `deploy/nas-app`; pages and viewer behind pinned keys; the window's gate to the NAS; the move.
- **11-22: the owner's new direction (the NAS autonomous, the PC the dashboard): `DESIGN-NAS-autonomous.md` written, board item 50 (three yeses); the next integrator dispatches the build after the yes. Checked: collector, watchdog, backup and the main program build for Linux (CGO off).**
- Owed by me (when next in the collector): TestNASSwitchPlaces's 60 s bound fails under heavy load (I-7: rig_test.go:507 "unsaved reachable by 1: 0, by 2: 0", 2 of a whole run; 5/5 when quiet): make its wait follow the test clock or a longer bound.
- Owed by me, after K24 and F15/N4 are on the head: the NAS doors (collector `nas_doors.go`) refuse a brought-in account (`Account.BroughtIn` / `!Live()`) in pages' fixed words ("This is the old archive: it is never signed in."), so the old account never gets a NAS place or sign-in; a small follow-up branch with a test (Core asked 11-22).
- Owed by others: Core's point 6 (the NAS's alerts) after K22; pages' small round (Held, give-back route) on N4.
- Next for this track: N5 (fingerprints and thumbnails on the NAS) after the thumbnails' measuring run (board item 31). The
  owner's first real steps after N4 is installed: deploy (`deploy/nasdl/README.md`), `vpntest` (M2), the test account into a
  test folder. Design: `DESIGN-NAS-downloader.md`; the PC's side: `NOTE-N4-collector-side.md`.

## The owner's steps for the move (for the instructions page; from `deploy/nas-app/README.md`, branch `wip/nas-move`; NOT to run before NA5 is merged and the owner starts it)
1. On the PC: build the NAS image and `tgarchive-nasmove.exe` (README's build step).
2. On the NAS: stop the test project; set its `data` and `keys` aside; keep `wireguard.conf`; make a new staging folder; point the library at the archive's own folder.
3. On the PC: quit the app; run `tgarchive-nasmove out` (it shows the counts first and says the PC's login files are then deleted, which cannot be undone); type yes; copy the bundle to the NAS with `scp -r`.
4. On the NAS: run `in` inside the image (`docker compose run ... --entrypoint /app/tgarchive-nasmove collector in ...`), then `docker compose up -d`.
5. The way back: `out` on the NAS, then `back` on the PC.

## The owner's step for tonight (sent to I-7 for the instructions page, 11-22): the tunnel's speed test on the NAS (M2)
Nothing to Telegram, no sign-in, about 1 GB. The integrator builds `tgarchive-nasdl-0.1.0.tar` (deploy/nasdl/README "Build");
the owner makes a Windscribe WireGuard file (with a DNS line; for this test only), loads the image, makes
`/volume1/<share>/nasdl-test` and `/volume2/docker/tgarchive-nasdl/data` (1000:10, data 700), copies compose.yaml,
settings.conf (listen 10.0.0.42, accounts 1) and wireguard.conf (600), then runs
`cd /volume2/docker/tgarchive-nasdl && sudo docker compose run --rm nasdl vpntest -dir /data` (never `compose up`).
Expected: the address check "different", MB/s and CPU seconds: the one open number of the tunnel on the NAS.
