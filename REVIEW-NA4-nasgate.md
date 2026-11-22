# Review NA4: the gate (`wip/nas-gate`, 6627605d + 447668c6 over a0de4f1), independent, Opus, 2026-11-22

Read: BRIEF-NA4-nasgate.md, DESIGN-NAS-autonomous.md section 2, all of `internal/nasgate`, `cmd/tgarchive-nasgate`,
the `deploy/nas-app` diff, `internal/nasproto/keys.go` and `bundle.go`, `wgdial.LANDialer`, and the Host and
site guards of `internal/server` and `internal/viewer`. The tree was not edited. Probes ran by `go test -overlay`
from `C:\Users\trabi\AppData\Local\Temp\claude\71f159c3a9e5d4b9\eb2fe7b8-c207-44b6-ab26-9a345fd154a3\scratchpad\review-na4`
(`probe_test.go`, `probe_cmd_test.go`, `overlay.json`) through `runs-nas-n1/go1.sh`: `go1: exit 0`, all five probes
reproduced what they claim. The branch's own tests of both packages also pass here (4.1 s and 0.7 s).

No way was found for a device other than the paired PC to reach the pages or the viewer. Each finding below is
about availability, privacy hygiene or defence in depth.

## Findings, ranked

### 1. Medium, CONFIRMED: a half-closed connection keeps both places for good; nothing times out after the handshake
`internal/nasgate/gate.go:141-149` (`finishCopy`: a clean end only half-closes), `gate.go:120-136` (`pipe` waits for
both directions with no deadline), `back.go:482`, `front.go:264`.
- **What happens:** when the NAS's server closes a connection (its header, idle or write timeout), the Front only
  CloseWrites toward the PC, and the Back only CloseWrites toward the client. Both then wait, with no deadline, for
  the client to end its own direction. A client that keeps its socket open and sends nothing holds one Back place
  and one Front place for as long as it likes. The servers' own anti-slowloris timeouts are defeated, because the
  server's close no longer reaches the gate's places.
- **Probe** `TestProbeHalfCloseHoldsPlaces` (Back MaxConns 2; the server's header timeout 300 ms): two raw
  connections that never send. Each client sees EOF, yet 2 s later `back active=2 front active=2`, and the window's
  own request is refused (`refused_cap=1`). Everything is freed only when the clients close.
- **Who can do it:** any process of any Windows user on the PC, a hung window, or a stalled reader. A window that
  stops reading also blocks the copies in `Write` (zero window), with no deadline either. 64 such connections lock
  the window out of the NAS until the Back restarts, and they hold the Front's 64 as well. On a PC that sleeps in the
  middle of a stream, the Front waits for TCP's own give-up (keep-alive does not apply while data is unacked).
- **Fix:**
  - When the server side ends (on the Front, the copy `t→tc`; on the Back, the copy `tc→c`), close everything after
    a short linger (a read deadline of a few seconds on the other source), instead of waiting for the client.
  - Give both copies a write deadline that moves forward with every write (the viewer's `progressWriter` idea, a
    stall bound of about 1 to 2 minutes).
  - Add a test for each: the server closes and the client stays; the client stops reading.

### 2. Medium-low, CONFIRMED (scaled down): a stranger at home with a few addresses fills all handshake places, and the paired PC is refused before its handshake
`front.go:206-215` (`takePending`), the default allow-list (`front.go:87-90`: every private range, 127/8 included),
`cmd/tgarchive-nasgate/main.go:199-200` (no way to set `Allow`).
- **What happens:** the per-address share (16) stops one address only. With the defaults, 256 in all ÷ 16 = 16
  addresses (aliases are trivial on a home LAN) fill every place. Each idle TCP connection holds its place for the
  10 s handshake timeout and is then renewed.
- **Probe** `TestProbeFewAddrsFillPendingTotal` (4 in all, 2 per address): two idle connections each from 127.0.0.3
  and 127.0.0.4. The PC's request from 127.0.0.1 is then refused (`RefusedPending=1`, `Forwarded=0`).
- **Fix:**
  - A `-allow` flag for the front, set in compose.yaml to the PC's own address (/32, with a reservation in the
    router, as the README already asks for the NAS). A stranger is then closed before any place is taken. Until the
    flag exists, the allow-list of every private range buys nothing on a home network.
  - A shorter handshake timeout on the LAN (about 3 s).
  - The test's claim "a stranger cannot hold the cap" should then cover more than one address.

### 3. Low, CONFIRMED: a mistyped flag, or `-h`, prints the PC's keys folder (a path holding the Windows user name)
`main.go:100` and `main.go:214` (the default `pcKeysDir()`), and `main.go:98-99`/`211-212` (`flag.ContinueOnError`
with its default usage, which prints every flag's default).
- **Probe** `TestProbeUsagePrintsKeysPath`: `back -nosuch` and `pair -h` both print the invented `LOCALAPPDATA`
  folder. This is against the program's own rule ("never a path").
- **Fix:** `fs.Usage = func(){ fixed words }` for every flag set, or default `""` and resolve `pcKeysDir()` after
  `Parse`. Add `-h` and an unknown flag to `TestFrontAndBackRefuseInFixedWords`.

### 4. Low, PLAUSIBLE: "never through a VPN" is enforced by the address alone
`back.go:457` with `wgdial/dialers.go:121-160`.
- **What happens:** `LANDialer` checks that 10.0.0.x is private. It cannot see that a system VPN on the PC with no
  LAN exception (or a VPN whose own network is 10.x) routes 10.0.0.x into the tunnel. The pin keeps this fail-closed:
  no one in the VPN can be the NAS. But the ClientHello goes into the tunnel, and its SNI (`tgarchive-nas`, from
  `nasproto.ClientTLS`) and ALPN (`tgarchive-pages/1`, `tgarchive-viewer/1`) travel in clear there and on the home
  Wi-Fi, naming the app.
- **Fix:**
  - After the dial, refuse unless `raw.LocalAddr()` is in a configured home prefix (the NAS's subnet, not a /8).
  - Set `tcfg.ServerName = ""` in the Back: no SNI is sent, and the pin does not need it.
  - Optionally, make the ALPN names opaque (`"p1"`, `"v1"`).

### 5. Low: the gate shares the writable `./tmp` with the collector and the viewer
`deploy/nas-app/compose.yaml:268-271`.
- **What happens:** the service on the home address can read and write the collector's SQLite temporary files and
  anything else either writes there.
- **Fix:** give the gate its own `tmpfs` (`/tmp:size=1m,mode=0700`, or with uid 1000 and gid 10) and keep the
  heartbeat there. The health check runs inside the same container, so it still finds it.

### 6. Low: `pair -replace` and where the NAS's half is written
- **`-replace`** (`main.go:135` → `nasproto/keys.go:119-133`) rewrites the three files in place, one after another.
  A failure between two writes leaves neither the old pairing nor the new one: it fails closed, but the old pairing
  is lost. Fix: write into a new folder and rename it over the old one.
- **README G1** writes `nasgate-pairing.pem` (the NAS's private key) inside the repository checkout
  (`deploy/nas-app/pc/`, ignored by git). One `git add -f`, or a copy of the folder, carries it. Better outside any
  checkout, for example `%LOCALAPPDATA%\tgarchive\nasgate-pairing.pem`.

### 7. Informational: TLS session tickets
`front.go:121`.
- **What happens:** the Front's Go TLS 1.3 server issues tickets, and `VerifyPeerCertificate` is not called again
  on a resumed connection.
- **Why it is no hole today:**
  - Tickets are sent only after the client's certificate has been checked (Go sends them after the client's
    Finished when it requested a certificate), so only a pinned client ever holds one.
  - The Back sets no `ClientSessionCache`, so it never resumes.
  - A new process makes new ticket keys.
- **Fix:** set `tc.SessionTicketsDisabled = true` to remove the whole class at no cost. Optionally add a
  `VerifyConnection` that checks the peer's certificate on every connection, resumed or not.

### 8. Informational: what the pin proves
The pin proves the PC as a machine, not the window.
- **Who else can reach the NAS:** any process of any Windows user on the PC reaches the NAS's pages and viewer at
  127.0.0.1:8797 and 8798, including reading the whole archive through the viewer. That is the same as the SSH
  tunnel of step 9 and as the local app.
- **Browser pages are stopped by the servers, not by the gate:**
  - DNS rebinding arrives with a foreign Host and gets 421 (the branch's test shows the bytes reach the server
    unchanged).
  - Cross-site and same-site requests are refused by `server.crossSite` and `refuse` (Sec-Fetch-Site, Origin, the
    page token) and by `viewer.guard`.
  - The door (`/api/act/`) needs its per-run secret and refuses anything a browser marks.
  - No cookies are used on these listeners (cookies ignore ports).
- **What follows for later targets:** the gate's protection rests entirely on each target's exact-Host check. Any
  later target added behind it must have one, and this belongs in the package comment.

### 9. Tests that do not prove all they claim, or are missing
- `TestGateStrangerCannotHoldTheCap` shows the per-address share only. Strangers from several addresses do hold
  it (finding 2).
- Not tested (my probes show these cases are sound; worth adding):
  - a client with no certificate (`TestProbeNoClientCert`: `RefusedHandshake=1`, nothing forwarded);
  - the pinned PC certificate shown with another private key (refused at the CertificateVerify);
  - the pinned certificate inside a two-certificate chain (refused by `len(raw) != 1`).
- Not tested at all:
  - a server that closes while the client stays (finding 1);
  - a client that stops reading;
  - a Back facing a TLS 1.3 front with the right key but no ALPN or the other ALPN (the code checks
    `NegotiatedProtocol`, so this is likely sound).

### 10. Nits
- **`-front` accepts a 127.x address** (loopback is in `PrivateRanges`). `-front 127.0.0.1:8797` makes the Back
  dial itself, up to the cap, until the handshake timeouts. Refuse loopback for `-front` (a NAS is never 127.x).
- **The health check** proves only that the heartbeat loop runs, not that the accept loop does. Acceptable as
  briefed, since `acceptLoop` ends only at Close.

## Checked and found sound
- **TLS:**
  - TLS 1.3 only, both ways (`MinVersion`=`MaxVersion`); the Back also checks the version and the negotiated stream.
  - `RequireAnyClientCert`, with exactly one DER equal to the pinned one.
  - Proof of possession comes from the CertificateVerify signature (probe: the pinned certificate without its key
    is refused).
  - TLS 1.3 has no renegotiation; Go has no 0-RTT and no post-handshake authentication.
  - ALPN: an unknown name fails the handshake in Go; no name gives `RefusedStream`.
- **Addresses:**
  - The Front never listens on 0.0.0.0, `::`, a name, a zoned or a public address. Its targets are 127.x only.
  - The Back listens on `tcp4` 127.x only and refuses a non-loopback peer.
  - `-front` must be a private literal address, checked again by `LANDialer` before the dial and on the socket.
- **Caps:**
  - The cap is counted after the pinned handshake on the Front.
  - A pending place is released on every path (refused at `add`, `spawn` refused, handshake ended).
  - The handshake is bounded by `HandshakeContext`, which closes the socket at the timeout.
  - The Back's dial and handshake are bounded (5 s and 10 s).
- **Goroutines:**
  - `conns.spawn` and `closeAll` cannot race (closed flag and `wg.Add` under one mutex).
  - `pipe` waits for its second copy.
  - Close ends every connection and goroutine. The branch's tests and all my probes pass `env.close`'s goroutine
    count.
- **Logs:**
  - `eventLog` writes constant words and integers only.
  - `say` prints only `nasgate:` and `nasproto:` errors, which are fixed words (checked in `keys.go` and
    `bundle.go`).
  - No address, key or error text is logged (apart from finding 3).
- **pair:**
  - It refuses to overwrite a pairing without `-replace`.
  - It writes the bundle with `O_EXCL` and 0600, the bundle first and removed when the PC's half fails.
- **compose.yaml:**
  - `network_mode: host`, `user: "1000:10"`, `read_only`, `cap_drop: [ALL]`, `no-new-privileges`, `init`.
  - mem 64m with GOMEMLIMIT 40MiB (about 64 × 2 copy buffers plus TLS state is under 10 MiB), `pids_limit` 64,
    1 CPU.
  - The keys are mounted read-only.
  - The health check opens no connection.
- **README:**
  - The steps are in order: G1 to G3 before step 8, and step 4's grep expects the one placeholder left for G3.
  - The keys folder is 700 and the file 600.
  - It warns about the SSH tunnel's same ports and about the UGOS firewall, and says that the launcher does not
    start the Back yet.

## Second pass (c25fd362)

Only `git diff 447668c6..c25fd362` was reviewed; the tree was not edited. The probes are in the same scratch
folder (`probe2_test.go`, `probe2_cmd_test.go`, `overlay2.json`) and ran through `runs-nas-n1/go1.sh` with
`go1: exit 0`. The branch's own tests pass at c25fd362 (nasgate 5.3 s, cmd 0.8 s).

### Each finding
| # | Fixed? | Shown by |
|---|---|---|
| 1 half-close, stall | **Fixed.** `copyHalf` (gate.go): once one direction ends, the other must bring bytes every `linger` (3 s), and each write has 2 min. | Probe: with the defaults, both places are freed 3.3 s after the server's close while the clients keep their sockets, and the window gets through. Branch tests `TestGateHalfClosedReleasesPlaces` and `TestGateStoppedReaderReleasesPlaces`. |
| 2 pending total | **Fixed by `-allow`**, put in compose.yaml as the PC's /32 (a placeholder for step G3). `ParseAllow` refuses 0.0.0.0/0, x/0, 10/7, ::/0, names, zones and public addresses, and maps `::ffff:` (probe). The handshake timeout is now 5 s. | Branch test `TestGateAllowNamesThePC`: 16 stranger addresses refused, the PC gets through. Without `-allow` the old exposure is unchanged, by design. |
| 3 path in usage | **Fixed.** Fixed-words usage; the flag package prints nothing. | Probe: `back -nosuch`, `pair -h` (now exit 0), and a bad `-max-conns` or `-max-age` name neither the folder nor the value. |
| 4 VPN, SNI | **Fixed as far as an address check goes.** Route check on the socket's own end (`back.go` serve); `ServerName ""`. | Branch test: the hello carries no server name. Probe: the route check refuses (`refused_route=1`, `forwarded=0`), but see new point A. ALPN names are still in clear (optional; accepted). |
| 5 shared tmp | **Fixed.** The gate has its own tmpfs `/tmp` (1 MB). | |
| 6 pair | **Fixed.** `writeHalf`: new folder, then renames. The bundle is now written under LOCALAPPDATA, outside the checkout. | Probe: `-replace` while a file of the folder is open (Windows refuses the rename) exits 1, the old pairing is whole and readable, the new bundle is removed, and the message names no path. |
| 7 tickets | **Fixed.** `SessionTicketsDisabled`. | Probe: a paired client with a session cache resumed 0 of 3 times. |
| 8 trust model | **Written** in the package comment and the README. | |
| 9 tests | **Added:** no certificate, pinned certificate with another key, chain of two, half-close, stopped reader, allow, route, SNI, a right-key front with no or the other ALPN. | |
| 10 nits | **`-front` 127.x refused.** The test hook `loopbackFrontForTests` is unexported and set only in `TestMain`. | Probe: `back -front 127.0.0.1:8799` exits 1. |

### The timers against legitimate traffic
- **A live long-poll** (the request sent, no half-close, the server silent for 8 s, more than the linger): it passes
  (probe). The linger only starts once a direction has ended.
- **A slow video range** (64 KB read, then a 5 s pause, three times; 1 MiB): it arrives whole (probe).
- **The 2 min write stall** is looser than the viewer's own `fileStall` (1 min): the server would cut a paused
  reader first, so the gate changes nothing there.
- **A client that half-closes after its request** (browsers and Go's Transport do not) would have a silent answer
  cut after 3 s. The probe could not show it: Go's servers end such a request themselves when they see the client's
  EOF (its context is cancelled), so with the real pages and viewer the linger cuts nothing extra.
- **I found nothing that is cut wrongly.**

### New points (none is a way in)
- **A. Low, PLAUSIBLE: the route check's default /24 is a guess.**
  - **A real home network that is not a /24:** on a wider network (a /23, a /22 such as Eero's 192.168.4.0/22 in
    router mode, a /16), a PC whose address is outside the Front's /24 is refused on every connection
    (`refused_route`). That fails closed, the README gives `-home`, but the count is the owner's only clue.
  - **A real network narrower than /24:** a tunnel address in the same /24 but outside the real subnet passes.
  - **A VPN client address inside the home /24:** this also passes. For example, a self-made WireGuard
    configuration on 10.0.0.2 while the home network is 10.0.0.0/24.
  - **The check runs after the TCP connect:** the connection itself goes along the VPN's route. The probe shows the
    far end accepted it, though no TLS byte follows. The README's "closed before anything is sent" is right for the
    TLS bytes only.
  - **Fix:** take the home network from the PC's own interface whose on-link network holds the Front's address
    (`net.Interfaces`, `Addrs`), and dial from that address (`LocalAddr`). Windows's strong host model then keeps
    the SYN off the tunnel, so the gate even works while a full-tunnel VPN runs. Failing that, refuse at start when
    `-home` does not contain the Front's address.
- **B. Nit, crash safety of `writeHalf`:** a crash between its two renames leaves `<dir>.old` and no `<dir>`. The
  Back then refuses to start, which fails closed, and a plain `pair` would make a new pairing. Rare; it could be
  said in the README.
- **C. Nit, README table:** the new `gatekeys` row sits after the paragraph, outside the folders table, so it shows
  as a stray line. Move it under `tmp`.
- **D. Scope:** the fix commit also changes the staging folder's text in the README and in compose.yaml (comments
  only, no effect on the gate). It is fine, but it is not part of NA4.

### Checked: no new way in, no new exhaustion, no goroutine left, no path, address or key in a log
- **pipe:**
  - Each direction's goroutine ends on EOF, an error or a deadline.
  - A failure or a timeout closes both, so the other ends at once.
  - `pipe` still waits for both. The buffer is the same 32 KB that `io.Copy` used.
  - tls `CloseWrite` keeps its own 5 s bound.
- **Goroutine checks:** every new test and every probe passes `env.close`'s goroutine count.
- **New fixed-word texts:** the new errors (`ErrAllow`, `ErrHome`, `errSwap`), the `refused_route` count and the
  usage text are fixed words. `-home` and `-allow` errors print no value (branch test, probe).
