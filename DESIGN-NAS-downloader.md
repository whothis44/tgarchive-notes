# The NAS downloader: design (session N-1, 11-21 21:27)

The owner, 11-14: a downloader on the NAS is wanted, "as long as the app/control remains on the PC and connects
to it". This note says how, what is decided by the design, and what only the owner decides (section 8, also on
the board's "Waiting for the owner" list). Nothing here has run, nothing is deployed, nothing has gone to Telegram.

Read for it, in full, by this session: `CLAUDE.md`; `BOARD.md`; the memories `nas-downloader-plan`,
`nas-over-wifi`, `nas-docker-host-network`; `ROADMAP.md` (the staging rows and row 200, the copy checks on the
NAS); `TRIED-BEFORE.md`; `LESSONS.md`; `WINDOW-EVIDENCE.md`; `TELEGRAM-FACTS.md` sections 1, 2 and 8;
`ANSWERS-for-archiver-7.md` and `-8.md`; the code of `internal/engine` (its interfaces), `internal/store`,
`internal/nashelper`, `internal/telegram/connect.go` and `vpn.go`, and `deploy/nashelper`.

## 0. What the old app's numbers say, beside what the NAS changes

| | Number on record | Source |
|---|---|---|
| Old app, whole account, hours without the speed limit | 60 to 100 GB an hour (17 to 28 MB/s), from the PC through the VPN | TRIED-BEFORE 18, answers 7 section 1 |
| Old app, copies from the PC's staging to the NAS | 9.6 MB/s median, 14.0 best, with 8 copies; the backlog grew 15 to 30 GB an hour in a spell (217 GB waiting on 11-14 08:36) | answers 8 D, answers 7 section 4 |
| New app, copies to the NAS (one test run, invented files) | 22.6 and 23.7 MB/s by read-back; 30.1 MB/s with the helper's hash on the NAS | nas-docker-host-network |
| The NAS's own internet link, no VPN | 45.4 to 48.0 MB/s, three runs of 1 GiB, with other NAS traffic running | nas-over-wifi |
| Under the speed limit | about 190 MB an hour per server, whatever the parts | TRIED-BEFORE 23 |
| New app on the test account, server 2, at 2 parts | 4.85 to 5.6 MB/s, inside the old app's range | TRIED-BEFORE 28 |

So, in plain words: **a downloader on the NAS does not get more bytes out of Telegram.** The speed limit and the
server ceilings are per account (TELEGRAM-FACTS 2: "the current account"), and the PC already reaches them. What
it removes is the second trip: every byte today crosses the air from the PC to the NAS (twice with a read-back),
at 14 to 30 MB/s, so in an unlimited spell the copies fall behind by 15 to 30 GB an hour. On the NAS each byte is
written once, to the NAS's own disk, and checked there. The gain shows only when downloads run faster than the
copies (unlimited hours on an account with a large backlog) and as a PC and Wi-Fi link left free. On the test
account at about 5 MB/s it will not show in a speed number; it shows in "saved in the library" time and in the
link being idle. The owner judged it worth having (11-14) and that is not argued again here.

## 1. The shape: the engine runs on the NAS, the catalogue stays on the PC

The new app's engine is already cut at the right place. `internal/engine` talks to the rest of the app only
through interfaces (`internal/engine/types.go`): a `Supply` (which file next, claim, saved, aside, progress
rows, the reference refresh), a `Transport` (fetch one part from Telegram), a `Sink` (write the file),
`Checker` / `CheckSupply` (the exact check before download), `ProbeSupply` and `PartStore` (the copy checks'
probe and its kept parts). `internal/store` is the `Sink` (writer, resume checkpoints, journal, copier, links),
with its own `Ledger` interface to the catalogue, and it already builds for Linux (`osfs_linux.go`).

So the NAS program is **the same engine and the same writer, unchanged, compiled for Linux, with two of their
interfaces answered by the PC over the home network**:

```
 PC (control, catalogue)                             NAS (fetch, write, hash)
 ---------------------------                         ----------------------------------------
 collector                                            tgarchive-nasdl (one container, host mode)
   catalogue: Supply, Ledger, Checker,   <== link ==>   engine (internal/engine, as on the PC)
   PartStore, the reference refresh       (LAN only,     Transport: gotd, dialled ONLY through the
   settings, pause, stop, the pages        mutual TLS)     WireGuard tunnel inside the process
   reads the NAS's counters each minute                 Sink: internal/store on the NAS's own disk
                                                         a small journal of its own (finishes not yet
                                                         told to the PC)
```

- **What runs on the NAS:** the lanes (one per server), the window rule, the waits (slept in full plus 1 s),
  the -503 handling, resume checkpoints (8 MiB or 30 s), writing, the SHA-256 while writing and again from disk
  before a file is published, publishing into the library. Requests the NAS sends to Telegram: `upload.getFile`,
  and what a connection needs (`initConnection`, `help.getConfig`, the authorisation transfer to each server).
  Nothing else.
- **What stays on the PC:** everything that decides. Which file is next (the lane's walk over the catalogue, its
  tiers, the held copies, the owner's choices), the exact check before download (its `upload.getFileHashes` from
  the PC's own session), the copy checks' probes, the reference refresh (`messages.getMessages` /
  `channels.getMessages`, batched, from the PC's session), the library paths, the catalogue rows, the pages, the
  alerts, start and stop.
- **One place per account:** an account's downloads run either on the PC or on the NAS, never both (a stored
  setting, default "on the PC"). Running both would only split the same allowance and double the lanes.
- **Fail closed:** the NAS takes no work by itself. With no link to the PC it claims nothing new; files already
  claimed go on to their end or to a checkpoint; their finishes wait in its journal and are told when the link is
  back (each finish once: the PC's answer is idempotent by file and attempt). After 10 minutes without the PC
  (a setting) it stops at checkpoints. It has no catalogue, no chat list, no message, no name: what the PC hands
  it per file is the location (server, id, access hash, reference, size) and the library path to write to.

**What is not taken over from the PC:** the probe's frame check and the fingerprints run where ffmpeg is today
(the PC) in the first version; kept parts from a probe are handed to the NAS with the job (the `PartStore` is
answered by the PC, a few MB a probe). Fingerprints of a saved video must then not read it back over the Wi-Fi
(the old app's 12.16 lesson, 20 to 25 GB an hour): so for accounts downloading on the NAS the fingerprint worker
moves to the NAS too, which is the roadmap row "the copy checks on the NAS" (row 200; copies' packages already
build for Linux). That is phase N5, with the thumbnails, after the memory number.

## 2. The link between the PC and the NAS

- **Direction:** the PC dials the NAS (as it does the helper, which works in host mode on 10.0.0.42:8790); the
  NAS listens on its home-network address only (port 8791 by default, a setting), host network mode. One long-lived
  connection carries calls both ways: the NAS's `Supply` and `Ledger` calls go up it to the PC, the PC's commands
  (start, stop, pause, settings, "tell me your counters") go down it. No port is opened on the PC.
- **Never through a VPN** (the owner, 11-15): the program's tunnel carries Telegram only; the link is plain home
  network. **Owed check (measured, not assumed):** the installed collector runs under the VPN's per-program rule
  on the PC, and whether its LAN connection leaves directly has never been seen (nas-docker-host-network). The
  NAS program logs the address each PC connection comes from: a home address means direct.
- **Who may talk to it:** mutual TLS with pinned keys, made at pairing: the PC makes a key pair for itself and
  one for the NAS and writes the NAS's into the NAS program's folder (one file the owner copies once, or written
  over the share); the NAS accepts only the PC's key, the PC only the NAS's. Go's own library, no outside CA. And
  the helper's allow-list of private networks stays. A device on the home network that is not the PC cannot ask
  the NAS to download anything, nor read its counters.
- **The wire:** length-prefixed frames of JSON, one request id each, the methods named after the interfaces'
  methods (`Supply.Next`, `Supply.Claim`, `Supply.Saved`, ..., `Ledger.*`, `PartStore.Kept`), plus `Hello`
  (versions of both programs and of the wire; a mismatch refuses), `Status` (the NAS's counters each minute:
  the engine's per-server counters as the PC writes them, the journal's length, memory, the tunnel's state), and
  `Command`. Calls have deadlines; a lost link fails the calls in flight with a typed error the engine already
  handles as a failed claim or finish (retried by its own worker; it never stops other downloads: the old app's
  A3 lesson).
- **Cost on the link:** one call per claim and per finish, one per progress row (every 8 MiB or 30 s per file),
  one status a minute. Small: a few KB a file, no media bytes.

## 3. The session question (decided by the owner: section 8, item A)

The NAS needs a way to call `upload.getFile` as the account. Three ways:

| | How | For | Against |
|---|---|---|---|
| **A. Its own sign-in (recommended)** | The NAS program signs in as a second login of the account, the code and the two-step password typed on the PC's Accounts page and handed to the NAS over the link (never stored on the PC); the key stays on the NAS, encrypted, in its own folder | Every server works, home server included; nothing shared with the PC's session, so no `AUTH_KEY_DUPLICATED` risk to the PC's login; a second login of the test account was made on 11-16 with no refusal (TELEGRAM-FACTS 8); the PC can end it from the account's list of logins | A new login shows on the account's devices; it is one more unofficial login "under observation" (TELEGRAM-FACTS 8); needs the owner's explicit OK per account |
| B. The PC lends one server at a time | The PC asks `auth.exportAuthorization` for a server and the NAS imports it with a fresh key of its own, as any client does for a server other than its home | No new login on the account's devices | The account's home server cannot be lent this way, so its files stay on the PC: a split per server, two writers of one account; how Telegram treats an import from another address is not documented or measured |
| C. The NAS holds the only session | Every request of the account, reads and mirror included, goes through the NAS | One login | Moves all of Telegram off the PC, against "control on the PC" in spirit; the NAS away stops everything; much more to build |

**Recommended: A, first on the test account only, one sign-in, measured.** In both A and B the file references
come from the PC's refresh: whether a reference fetched by one login works for another login of the same account
is not documented and is measured first (one file on the test account; if not, the NAS refreshes for itself,
counted, and that is said before it is built). The old account is not touched (it stays on the old app; the
fork's rule "never add sessions" stands for it).

## 4. The VPN, and the check that nothing leaves outside it (decided by the owner: section 8, item B)

The owner pictured the VPN on the NAS as one Docker container (11-14), and tried `gluetun` with Windscribe over
WireGuard (result not in). But on this NAS every container must run in host network mode (11-15), and a VPN
container in host mode puts its tunnel and its firewall on the NAS itself: every NAS program's traffic (the
backups, syncthing, tailscale, the shares) would follow it or be cut by it. The usual way round, the downloader
inside the VPN container's network (`network_mode: service:vpn`), needs Docker's own networking, which is what
failed on this NAS.

**Recommended: the tunnel inside the downloader's own process.** The program carries WireGuard in user space
(`wireguard-go` with its `netstack`, MIT licence: a TCP/IP stack inside the program that only talks through the
tunnel). The Telegram client's dialler is that stack's and nothing else. The container stays in host mode for
the link to the PC; the NAS's routes, firewall and other programs are not touched; no Linux capabilities, no
`/dev/net/tun`. The owner downloads a WireGuard configuration for the NAS from Windscribe (a file) and puts it
in the program's folder on the NAS; no session reads it, prints it or copies it.

**The check that nothing leaves outside it**, in four parts:
1. **By construction.** The Telegram client is given one resolver, whose dial goes into the tunnel's stack; a
   test proves that every dial of the client goes there, and that the program's other dialler (the one for the
   link) refuses any address outside the home ranges. With no tunnel up there is no route at all: nothing falls
   back to the NAS's own network.
2. **At start and at every reconnection:** the tunnel's last handshake is fresh, and the existing gate
   (`internal/telegram/vpn.go`, the public-address check) is asked through the tunnel: the address seen outside
   must not be the home's public address (measured directly once at start, one request to the same address
   service, not to Telegram). A refusal starts nothing and raises the alert "VPN check refusing" (Core's K22).
3. **While it runs:** the counters carry the tunnel's bytes and handshakes per minute; no handshake for 3 minutes
   stops new parts (the engine sees failed dials, which it already handles) and alerts.
4. **A check the owner can do on the NAS, any time:** Telegram's connections live inside the program, so the NAS's
   own socket table must show none: `ss -tn | grep -E '149\.154\.|91\.108\.'` prints nothing while it downloads,
   and the only outside connection of the program is UDP to the Windscribe server.

**Decided by the owner, 11-21 21:43:** the tunnel inside the program, Windscribe as the likely provider, **and a stored setting for no VPN** (off by default). With it on, the Telegram client dials from the NAS's own network; it is a deliberate choice, shown on the pages and in every status line and log minute (as the PC's gate override of 11-12), and the address check of part 2 is then not a refusal. **Tailscale on the NAS** (the owner thinks it is there; it was busy on 11-14): the tunnel inside the program does not touch Tailscale's interface. One thing matters: if the NAS sends its internet traffic through a Tailscale exit node, the tunnel's UDP (and the no-VPN mode's Telegram traffic) leaves through that node too: asked. The link to the PC uses the home address; a PC coming over Tailscale (100.64.0.0/10) is outside the allow-list and is refused unless added.

**Entry points (the owner, 11-21: "both speed and also security, minimize entry points").** The downloader opens nothing to the internet: it only dials out (UDP to the Windscribe server; Telegram inside the tunnel). Its one listener is on the home address, mutual TLS with pinned keys, private ranges only; no router port is forwarded. It does not need Tailscale: the PC reaches it over the home network. The container is not root, has no capabilities, a read-only root, memory and process limits, and mounts only the folder it writes and its own key folder (not on a share). Recommended to the owner: keep Tailscale only if it is used to reach the NAS from away, with no exit node on the NAS and two-step sign-in on its account. **Decided by the owner, 11-21 21:57: Tailscale kept for remote access, no exit node.**

**The NAS program as a companion with several tasks (the owner, 11-21: "auto forwarding/mirroring, but also downloading, and maybe also hosting the duplicate identification").** The rule for every task it may carry: what goes to Telegram (parts, forwards, chat lists) goes through the tunnel (or direct with the no-VPN setting); what is local work (fingerprints, frame checks, thumbnails on files on the NAS's own disk) uses no network; control, results and the PC's reads go over the home network at its full speed, never through the tunnel. Each new task is its own piece with its own measurement (the NAS's processor for the copy checks); the mirror on the NAS is not designed yet.

## 5. Memory on the NAS, and the measurements needed first

The NAS has 7.7 GB; on 11-14 2.3 GB were available and 4.1 GB of swap in use, and the containers together held
only about 1.3 GB (the rest unexplained). **On 11-21 21:43 (the owner): 3,973 MB available of 7,711, swap 1,397 MB used.** **At about 23:10 (`sudo docker stats`): 9 containers, about 2,790 MiB together (a media server 1,964 MiB, a download manager 516 MiB, the rest under 140 MiB each). So the downloader's limit stays 384 MB, well inside what is available; the thumbnails and fingerprints (N5) get their own container of 512 MB, one ffmpeg at a time, and need nothing stopped. The media server stays (the owner, 23:15: "I'm stuck with it"): nothing is ever proposed that stops it. If the thumbnails' measuring run shows swap growing, they get leaner instead: smaller frames, one at a time, paused while the downloader is busy.** **The owner, 23:15: the download manager (516 MiB) goes away; the media server stays. So about 0.5 GB more is free; the limits above stand.** The old app holds over 2 GB of heap: that is not what runs on the NAS.
The new app's engine used 38 to 59 MB in its real run of 11-13 (734 files). Expected for the NAS program: the
engine and writer as on the PC, plus gotd's pools, plus the tunnel's stack (buffers per connection), plus at
most one part (1 MiB) in memory per part in flight: **about 100 MB, held to a limit of 384 MB** (`mem_limit`),
the Go runtime told the same (`GOMEMLIMIT`). The thumbnails and fingerprints (phase N5) run ffmpeg, one at a time,
in their own limit, only after their own measuring run.

| Measurement | Who | Cost | Before what |
|---|---|---|---|
| M1. The NAS's memory now: `free -m` and `docker stats --no-stream` over SSH, two numbers kept (available, swap used) | the owner | seconds, nothing sent anywhere | before anything is deployed |
| M2. The tunnel's speed and the address check: the NAS program's `vpntest` (no Telegram): downloads a 1 GB test file through the tunnel and reports MB/s, the processor and memory it used, and the check of section 4 | the owner, when built | about 1 GB of the NAS's link, about a minute | before any sign-in on the NAS |
| M3. The program's own memory and processor with the fake Telegram: a day's worth of invented files in a container with the NAS's limits | this track, on the PC (Docker) | the PC's load budget; nothing outside | before the first real run |
| M4. Is a file reference from the PC's login good for the NAS's login? One file of the test account | the owner starts it | one `getFile` and at most one refresh | before the reference design is fixed (section 3) |
| M5. The first real run on the test account: one chat of the owner's choice, into a test folder on the share | the owner starts it, after A and B are decided | the chat's files; every wait slept in full | the step-4 "small copy to a test folder" rule; numbers beside the PC's run of the same server |
| M6. The collector's link to the NAS leaves directly (section 2) | read from the NAS program's log at M5 | none | the first real run |

M2 can be run with the owner's own `gluetun` trial instead if they prefer, but it would measure a different
tunnel from the one the program will use.

## 6. What is ported and what is new

**Ported unchanged (imported, not copied):** `internal/engine` (the lanes, the upward window rule, waits with
the 1 s margin, a waiting part keeping its slot, -503 aside after 2 with storm detection, the counters);
`internal/store` (the writer, checkpoints, the prefix re-hash on resume, never replacing a library file, links,
the journal); `internal/telegram`'s part transport and its gate (with a resolver handed in, which
`ConnectConfig.Options.Resolver` already allows and wraps with the gate). These carry the old app's measured
lessons already (TRIED-BEFORE 1, 2, 5, 7, 19, 27, 28): none is reinvented, and the download path is not tuned.
**The helper's** listener pieces (allow-list, connection cap, numbers-only log) are the model for the NAS
program's listener; the helper itself stays as it is, for the PC's copies while downloads run on the PC.

**New, in packages of this track (nobody else edits them):**
- `internal/wgdial`: the WireGuard tunnel in user space, a dialler and a resolver for gotd, its state and counters;
  the `vpntest` measurement (M2).
- `internal/nasproto`: the wire (frames, methods, versions, typed errors), shared by both programs.
- `internal/nasctl`: the PC's side: serves a real `engine.Supply` / `store.Ledger` / `Checker` / `PartStore` to a
  NAS over the link, refuses a second NAS, reads its status; used by the collector (section 7).
- `internal/nasdl`: the NAS's side: the remote `Supply`, `Ledger`, `Checker` and `PartStore` the engine and the
  writer are given, the journal of finishes not yet told, the program's run loop and its fail-closed rules.
- `cmd/tgarchive-nasdl`: the program (`serve`, `vpntest`, `check`), and `deploy/nasdl`: Dockerfile and compose file
  (host network mode, `user: "1000:10"`, read-only root, `cap_drop: [ALL]`, `no-new-privileges`, `mem_limit`,
  `pids_limit`, its folder for keys, the tunnel's file and the journal; the library mounted read-write: a test
  folder first).

**Other tracks' code this needs:** the collector's side of "this account downloads on the NAS" (do not start its
local lanes, serve `nasctl` instead, show the NAS's counters) is `internal/collector`, Core's: asked of Core on the
board (message 217), offered as a lent commit of this track that Core reads first. The Accounts page's sign-in
"on the NAS" (item A) is pages' and Core's sign-in; it waits for the owner's decision. Thumbnails as files land
use the viewer's `tgarchive thumbs` makers; fingerprints use copies' `internal/vfp`; both phase N5.

## 7. The order of work

| Piece | What | Needs a decision? | State |
|---|---|---|---|
| N1 | `internal/wgdial` and `vpntest` (M2's tool); tests with a WireGuard peer inside the test itself | no | briefed: `BRIEF-N1-wgdial.md` |
| N2 | `internal/nasproto`, `internal/nasctl`, the remote halves in `internal/nasdl`: the real engine runs over the link against the catalogue's in-memory supply and gives the same outcomes as run locally; link lost, replayed finishes, a second NAS refused | no | briefed: `BRIEF-N2-link.md` |
| N3 | The program and its deploy files with the fake Telegram; M3 | no (the session part waits for A) | after N2's wire is settled |
| N4 | The collector's side (Core's package) and the sign-in on the NAS | A (the session), Core's OK | after N2 and the owner's word |
| N5 | Fingerprints and thumbnails on the NAS as files land, the options handed from the PC | the M1 number and the thumbnails' measuring run of 200 (board item 31) | later |

Every real step is the owner's to start: nothing is deployed to the NAS and nothing signs in or downloads there
before the owner says so. Every request it makes is counted per kind and hour from its first minute.

## 8. Decisions for the owner (each also one line on the board)

- **A. The session on the NAS (item 46). DECIDED 11-21 21:43: its own sign-in.** Recommended was: its own sign-in, first on the test account only (section 3).
- **B. The VPN on the NAS (item 47). DECIDED 11-21 21:43: as recommended, plus a no-VPN setting (section 4).** Recommended was: WireGuard inside the downloader's own container, with a
  Windscribe WireGuard file you put in its folder, instead of a separate `gluetun` container (section 4).
- **C. Two numbers from the NAS now (item 48):** `free -m` and `docker stats --no-stream` over SSH, the
  "available" and "swap used" lines and the total of the containers: seconds, nothing sent. Recommended: now,
  and say whether the containers you called junk on 11-14 are stopped.
