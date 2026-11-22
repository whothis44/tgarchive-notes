# Brief N1: the WireGuard tunnel inside the program (NAS track, session N-1, 2026-11-21)

**Why:** the new app gets a downloader that runs on the owner's NAS (`C:\Users\trabi\Claude\Projects\Telegram\DESIGN-NAS-downloader.md`:
read sections 0, 1 and 4 first, the whole note if you have time). On that NAS every Docker container must run in host
network mode, so a separate VPN container would put its tunnel and firewall on the whole NAS. The design puts the
tunnel inside the downloader's own process: WireGuard in user space with its own TCP/IP stack, so that the Telegram
client's ONLY way out is the tunnel, and the NAS's routes, firewall and other programs are never touched. This piece
is that tunnel as a package, plus the measuring command the owner will run on the NAS (measurement M2). Nothing here
talks to Telegram.

**Rules of the house:** you are the Opus coder of this piece and hand back commit-ready work. Named tests only while
you work (`-run`, or your own small packages whole); no race detector; no `go vet` over many packages. Invented data
only. No name, path, address, key or id in any log line, error text or commit message: new log lines are constant
format strings with numbers and fixed words only (`ixLog`-style); an address in an error is said as "the tunnel's
endpoint", never printed. Never touch a running program, the main copy `repo-archiver`, the owner's folder
`C:\Users\trabi\tgarchive-app`, anything under `E:\`, or the NAS. Never read, print or copy a real WireGuard
configuration: tests make their own keys. **Every `go` or `gofmt` command goes through the track's lock script:**
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-nas-n1/go1.sh <folder to run in> go test -p 1 -run '<names>' -timeout 15m ./internal/wgdial/`
(it prints "go1: exit N"; 97 or 98: nothing was run, wait and try again).

**Where:** make the copy yourself, one command, from `C:\Users\trabi\Claude\Projects\Telegram`:
`git -C repo-archiver worktree add ../wt-nas-wgdial -b wip/nas-wgdial af4ca40e`. Work only in
`C:\Users\trabi\Claude\Projects\Telegram\wt-nas-wgdial`. Commit with
`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `wip/nas-wgdial` to `private`, work in progress
too, after each step that builds. No `git stash`, no rebase, no other branch.

## What exists (read before writing)

- `archiver/internal/telegram/connect.go` (`NewClient`, `ConnectConfig.Options.Resolver`, `gatedResolver`): the
  Telegram client takes a gotd `dcs.Resolver`, which the gate wraps. Your resolver is what will be handed in there on
  the NAS. Read how `gatedResolver` calls the inner one.
- `archiver/internal/telegram/vpn.go`: the gate and its public-address check (`PublicConfig`, `Gate.public`). On the
  NAS that check must go through the tunnel: find what it uses to make its request (an `http.Client` or a dial
  function) and say in your report how it can be handed your dialler WITHOUT changing that file (it is Core's). If it
  cannot, say exactly which one-line seam it would need; do not edit it.
- `archiver/internal/nashelper` (`server.go`: `DefaultAllow`, the numbers-only log): the model for fixed-word logs and
  the private-range list.
- gotd's `dcs` package at the version in `archiver/go.mod` (v0.166.0): `dcs.Plain(dcs.PlainOptions{Dial: ...})` and
  the `Resolver` interface.

## What to build

1. **A package `archiver/internal/wgdial`** (Linux and Windows both build; tests run on Windows here):
   - `Config` parsed from a standard WireGuard configuration file (`[Interface]` PrivateKey, Address, DNS optional,
     MTU optional; one `[Peer]` with PublicKey, PresharedKey optional, Endpoint, AllowedIPs, PersistentKeepalive
     optional). Parse errors name the line number and the key's name, never its value. A file that gives
     `AllowedIPs` other than everything (`0.0.0.0/0`, `::/0`) is accepted but said in `Status`.
   - `Tunnel`: `Start(ctx, cfg)` brings up `wireguard-go` with `golang.zx2c4.com/wireguard/tun/netstack` (pin the
     versions that build with this module's Go; the dependency's lines in `go.mod`/`go.sum` only). `DialContext`,
     `Close`, and `Status()` (up or not, seconds since the last handshake, bytes in and out, dials made, dials
     refused, the MTU) read from the device without printing keys.
   - **No way round it:** a dial before the tunnel is up, or after it closed, or with no handshake within a
     setting's time (default 3 minutes, a field), fails with a typed error (`ErrTunnelDown`); it never falls back to
     the system's network. Names are resolved only by the tunnel's own DNS (from the file) or not at all: the
     Telegram client dials addresses, so a resolver with no DNS is fine; say which you chose.
   - `Resolver(opts)`: a gotd `dcs.Resolver` whose every dial goes through `Tunnel.DialContext` (built on
     `dcs.Plain` with its `Dial` option, or your own if that is cleaner: say why).
   - `HTTPClient()`: an `http.Client` whose transport dials only through the tunnel (for the address check and the
     speed test), with timeouts.
   - `LANDialer`: the program's other dialler, for the link to the PC: it refuses any address outside the private
     ranges (the same list as `nashelper.DefaultAllow`, copied, not imported, unless importing is clean) with a typed
     error, so nothing of the program can reach the internet except through the tunnel.
   - Counters per minute for the program's status: bytes, handshakes, dials and refusals; no goroutine of the
     package outlives `Close`.
2. **The measurement M2 as a function the NAS program will call** (`Measure(ctx, tun, MeasureConfig)`, no command
   yet: the program is a later piece): one request through the tunnel to a configured address service (the
   address seen outside, compared with a "home address" handed in: result "different", "same: refuse", "cannot
   tell"), then a download of a configured URL (default the test file that worked from the NAS on 11-14,
   `https://ash-speed.hetzner.com/1GB.bin`) to nowhere, with a byte cap (default 1 GB) and a time cap (default
   3 minutes); reports MB/s (10^6 bytes), seconds, bytes, the process's peak memory (Go's runtime numbers) and CPU
   seconds. A result struct, no printing of the address seen.
3. **Tests, all on invented keys and loopback, no internet:** run a second WireGuard device inside the test (both
   ends with netstack, or one end on a loopback UDP socket) with a tiny TCP and HTTP server behind it, and prove:
   a dial through the tunnel reaches the server behind it; `Resolver`'s dials all go through the tunnel (count them
   on the far side); with the peer stopped, dials fail with `ErrTunnelDown` after the handshake limit and NOTHING
   reaches a server listening on the system's own loopback at the same port (the "no fallback" proof); `LANDialer`
   refuses public addresses and allows a private one; the parser refuses bad files without printing a key (feed it
   a key-shaped secret and assert it appears in no error); `Measure` on a local HTTP server behind the tunnel gives
   a plausible MB/s and stops at its byte cap and its time cap; `Close` leaves no goroutine (count before and after).
   A throughput number on this PC for the report: MB/s through the tunnel on loopback, one run, said as "on the PC,
   loopback, one run".

## Hand back

Commit-ready on `wip/nas-wgdial`, pushed. Report in at most 40 lines: the commits; the dependency and its versions
(and their licences); what each test proves; the loopback MB/s; how the gate's address check can be given the
tunnel (the seam, or that none is needed); anything in the design that turned out wrong. Then stop.
