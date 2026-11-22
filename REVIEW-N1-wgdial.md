# Review N1: `internal/wgdial` (independent review, Opus, 2026-11-21)

Branch `wip/nas-wgdial`, commits e50d44e7 and 6fc6346a over af4ca40e, read in `wt-nas-wgdial` (nothing edited
there). I read the brief (`BRIEF-N1-wgdial.md`), section 4 of `DESIGN-NAS-downloader.md`, all of the package's code
and tests, gotd's `dcs/plain.go` (v0.166.0), wireguard-go's `tun/netstack/tun.go` and `device/uapi.go`
(b3bc704ef0ee), gVisor's `gonet` and `log` (39ed1f5ac29c), and the gate's `PublicConfig` in
`internal/telegram/vpn.go`.

Probe tests: `C:\Users\trabi\AppData\Local\Temp\claude\71f159c3a9e5d4b9\eb2fe7b8-c207-44b6-ab26-9a345fd154a3\scratchpad\review-n1\zz_review_test.go`,
loaded with `go test -overlay` (`overlay.json` beside it). All runs went through `runs-nas-n1/go1.sh`, exit 0. The
package's own nine tests pass. `GOOS=linux go vet ./internal/wgdial/` is clean. The probes print booleans, counts
and timings, and no key material.

**Summary:** the main claim holds. No Telegram dial, DNS lookup or HTTP request of the tunnel's client can leave
through the system's network, and I found no way past `LANDialer`. There are two problems to fix before the
package is used: a private-key leak through `%v`, and a handshake rule that can hold a working tunnel "down".
Five smaller ones follow, then gaps in the tests.

## Findings, ranked

### 1. The private key prints through `%v` of a `*Tunnel`, or of any struct holding a `Config` in an unexported field (CONFIRMED)
- Where: `tunnel.go:130` (`cfg Config`, unexported, kept for the tunnel's whole life); `config.go:29-38` (`Key` is
  a `[32]byte` with its `Format` method).
- Why: `fmt` cannot call a method on a value it reaches through an unexported field (`CanInterface` is false), so
  `Key.Format` is skipped and the key's 32 bytes print as `[n n n ...]`. The package test only prints a `Config`
  directly (`wgdial_test.go:304`), and on that path `Format` does run.
- Shown by probe R1: `%v` and `%+v` of a started `*Tunnel`, and `%+v` of `struct{ c Config }`, all hold the private
  key's byte array. They also hold the endpoint. `%+v` of a `Config` itself holds no key, but it does hold the
  endpoint and the tunnel's own address.
- Failure: a debug line in the NAS program writes the WireGuard private key into its log, for example
  `log.Printf("tunnel %v", tun)`, or a status struct holding `cfg wgdial.Config` printed with `%+v`.
- Fix:
  - Do not keep the keys after `Start`: `IpcSet` has them. Keep only MTU, AllowedIPs, the DNS count and
    IgnoredKeys in the `Tunnel`.
  - Make `Key` safe on any path: `type Key struct{ p *[32]byte }`. Past the top level, `fmt` prints a pointer
    field as its address, never what it points to.
  - Give `Config` a `Format` or `String` that hides `Endpoint`, `Addresses` and `DNS`.
  - Add a test that prints a started `*Tunnel` and a struct holding a `Config`.

### 2. A `HandshakeLimit` below WireGuard's key life holds a working tunnel "down" and refuses most dials (CONFIRMED)
- Where: `tunnel.go:76-81` and `101-104` (any value over 0 is accepted); `tunnel.go:371-373` (fresh means "last
  handshake no older than the limit").
- Why: WireGuard makes a new handshake only when its keys need one, at about 120 s with traffic, and a key works
  until 180 s. A tunnel can carry traffic for up to 180 s after its last handshake. With a shorter limit, the
  handshake time alone calls a healthy tunnel stale.
- Shown by probe R2b: limit 2 s, peer healthy, an idle tunnel, then dials every 100 ms for 5 s. 23 dials worked, 27
  were refused with `ErrTunnelDown`, and Status said "down" the whole time. Every probe let through worked.
- Failure: the owner or a later piece lowers the setting to 60 s "to detect a dead VPN sooner". Once each tunnel
  idles, it allows one dial per `RetryEvery` (15 s) and refuses the rest. The Telegram engine sees mass dial
  failures, with no fault anywhere.
- At the default (180 s) it is sound by reading: working traffic implies a handshake within 180 s.
- Fix:
  - Clamp `HandshakeLimit` to at least 180 s (WireGuard's RejectAfterTime) and say so in the field's comment.
  - Or also count the tunnel fresh while `rx_bytes` has grown within the limit. That is a better sign of life, and
    it also covers a wall-clock jump (finding 7).

### 3. With `::/0` allowed and no IPv6 address on the interface, an IPv6 dial takes the one probe slot while down (CONFIRMED)
- Where: `tunnel.go:601-614` (`allowedLocked` checks AllowedIPs, not whether the stack has an address of that
  family); `tunnel.go:479-485` (one probe at a time).
- How it happens: gotd's `dcs.Plain.connect` dials every candidate of a DC at the same moment. Its candidates
  include Telegram's IPv6 addresses (`FindDCs`, IPv4 first, IPv6 still included).
- Shown by probe R3, Address IPv4 only, AllowedIPs `0.0.0.0/0, ::/0`:
  - While up, the IPv6 dial is counted as a dial (`Dials` 1, `Refused` 0) instead of being refused.
  - While down, with the peer back: the IPv6 dial took the probe and failed at once with `ErrTunnelDown`. The IPv4
    dial straight after was refused, and nothing was sent.
- Failure: provider files often list `::/0`. Each time the tunnel recovers, about half the probes are spent on
  addresses that cannot be routed, so the time back up grows by multiples of `RetryEvery`.
- Fix:
  - In `allowedLocked`, refuse with `ErrRefused` a family the file's `Address` has none of. This is the same rule
    netstack applies, but made before the handshake rule.
  - Optionally have `Resolver` filter out IPv6 options when the interface has no IPv6.

### 4. Down comes up to twice the limit after the last handshake; Status says "starting" for a stale tunnel with no dial (CONFIRMED)
- Where: `tunnel.go:471-477` (the trying window opens at the first stale dial, not when the tunnel went stale);
  `tunnel.go:717-730`.
- Shown by probe R2: the peer went silent just after a handshake (limit 2 s), and the first `ErrTunnelDown` came
  4.0 s later. States seen in order: up, starting, trying, down.
- At the defaults this is up to 6 minutes. Design section 4 part 3 says "no handshake for 3 minutes stops new
  parts". Meanwhile, dials in the fresh part get no deadline from the package and wait for gotd's 35 s dial
  timeout.
- Also, a tunnel that went dead while nothing dialled shows "starting" forever. An alert keyed on "down" never
  fires until the engine dials.
- Fix:
  - Open the trying window at `max(first stale dial, lastHS + limit)`. Or, with a keepalive configured (handshakes
    then come about every 2 min even when idle), count stale as down at once.
  - Name the stale idle state "idle" and not "starting" once there has been a handshake.

### 5. `HTTPClient` keeps every transport it ever made until `Close` (CONFIRMED)
- Where: `dialers.go:49-53`.
- Shown by probe R6: 1000 calls leave 1000 transports held. Each `Measure` adds two.
- Failure: the NAS program builds a client per gate check, at start and at every reconnection, for days. Memory
  grows slowly, along with each transport's idle connections (30 s each).
- Fix: make one client per tunnel (lazily, with the timeout set per request through the context), or drop a
  transport from the list once the caller is done with it.

### 6. A `Start` that fails while netstack is making its stack leaks the stack's goroutines (CONFIRMED)
- Where: `tunnel.go:195-198`. netstack's `CreateNetTUN` returns nil on an `AddProtocolAddress` error without
  closing the gVisor stack it made.
- Shown by probe R8: a `Config` with the same address twice makes `Start` fail, as it should. Goroutines went from
  2 to 12 over 5 attempts, 2 per attempt.
- Failure: a program that retries `Start` on a bad file leaks a little on every try.
- Fix: in `ParseConfig`, or at the top of `Start`, refuse or merge duplicate addresses, so this error path in
  netstack cannot be reached.

### 7. Smaller points
- **Errors on the returned connection carry addresses (PLAUSIBLE).** `tunnel.go:527-529` returns gVisor's
  `*gonet.TCPConn` as it is. Its Read and Write errors are `*net.OpError` holding `Source` (the tunnel's own
  address, from the provider) and `Addr` (Telegram's server), for example "read tcp A:p->B:443: ...". The same is
  true of system sockets, so this only matters if the program logs gotd's connection errors unscrubbed. Wrapping
  the connection so its errors are classified would make the package's "no address in an error" rule cover these
  too.
- **The handshake time is compared on the wall clock (PLAUSIBLE).** `tunnel.go:331` and `372`: wireguard-go gives
  the handshake time as Unix nanoseconds, so `Now().Sub(lastHS)` has no monotonic part. If the NAS clock steps
  back by more than the limit, a dead tunnel stays "fresh" until the clock catches up. If it steps forward, the
  tunnel is held trying until the next handshake. The fix in finding 2 (rx progress) covers this.
- **`PrivateRanges` is an exported, writable package variable (by reading).** `dialers.go:65`. A
  `LANDialer{Allow: nil}` uses it live, so one line anywhere in the program can widen the allow-list for every
  LAN dialler. Fix: make it unexported, with a function that returns a copy.
- **gVisor's log emitter is replaced while other stacks are already running (PLAUSIBLE, tests only).**
  `tunnel.go:163-167`: the write to `gvlog.Log().Emitter` is unsynchronised. In the tests, `newPair` makes the far
  end's stack before `New` (`fixture_test.go:305-313`), so this is a data race under `-race`, and the far stack's
  early log lines would go to stderr. Fix: set the emitter in the package's `init()`.
- **The WireGuard UDP socket listens on every interface (by reading, for information).** Default bind,
  `tunnel.go:199-202`: Linux's `StdNetBind` binds `0.0.0.0` and `::` on a random port, or on a fixed one when the
  file gives `ListenPort`. WireGuard answers nothing that is not authenticated with its public key. Still, on a
  NAS with a global IPv6 address and an open router it is an entry point, which section 4 says should not exist.
  Possible fix: bind only the endpoint's family, and ignore `ListenPort`.
- **The byte cap is 1 GiB, not 1 GB (nit).** `measure.go:57-59` gives `1<<30`; the brief says 1 GB.

## Tests that do not prove what they claim
- **`wgdial_test.go:318`, "a line without =":** a 32-byte key in base64 ends in `=`. The line is read as an
  unknown key and ignored, and the case fails only for another reason (no `[Peer]`). Probe R7: a full file that
  also holds such a bare key line is accepted. Harmless, but the case does not test its name.
- **`TestParseConfigNeverPrintsAKey`:** prints a `Config` only at the top level. It would not have caught finding
  1. `TestStatusAndUAPIHoldNoSecretInText` checks a `Status{}` it built itself, not a started tunnel's status.
- **The probe logic is not tested at all.** That covers recovery after the peer comes back, one probe at a time,
  and `RetryEvery`. `TestNoFallbackWhenPeerStops` stops at "down". Probe R2 shows recovery works: one dial after
  the peer was back, at a 2 s limit, the key still valid. Findings 2 to 4 sit in the same untested code.
- **`TestNoFallbackWhenPeerStops`, the dials to `farAP` (10.9.0.1):** they could not show a fallback, because a
  system dial to 10.9.0.1 would never reach the 127.0.0.1 listener. Only the `loopAP` dials prove "nothing
  reaches the system". They do, so the claim stands, but on half the dials it implies.
- **The resolver test:** gives one option per DC, so gotd's racing of several candidates (finding 3) is never
  exercised.

## Checked and sound
- **No way out through the system's network.**
  - In the non-test code, the only system dialler is `LANDialer`'s `net.Dialer` (`dialers.go:140`). The only
    system name lookup is the endpoint's, done once at `Start` (`tunnel.go:113`), as the brief allows: it is the
    VPN server's name.
  - `DialContext` dials only `tnet.DialContextTCPAddrPort`. A name is looked up only through netstack's own DNS,
    over the tunnel, which never falls back to the system. With no DNS in the file, a name is refused.
  - Before `Start`, after `Close` and when not allowed, a dial returns before anything is sent.
  - The resolved addresses are checked against AllowedIPs again.
- **HTTP.** `HTTPClient` has `Proxy: nil` and a custom `DialContext`, and follows no redirect. Probe R4: with
  `HTTP_PROXY`, `HTTPS_PROXY` and `ALL_PROXY` pointing at a listener on 127.0.0.1, the request still went through
  the tunnel. The listener was never reached, and a name with no DNS was refused, not looked up by the system.
- **gotd.** `Resolver` always replaces `Dial` and forces `"tcp"`. `dcs.Plain` uses that `Dial` for Primary,
  MediaOnly and CDN, and has no other way out. `Obfuscated`, `NoObfuscated`, `PreferIPv6` and `Protocol` change
  only what is sent or which candidates are picked. A risk for the integration, not this package:
  `telegram.NewClient` falls back to `dcs.DefaultResolver()` (system network) when `Options.Resolver` is nil.
  The NAS program should refuse to start without the tunnel's resolver unless the owner's no-VPN setting is on.
- **IPv6 and mapped addresses on the tunnel path.** Addresses are unmapped. Zoned and unspecified addresses are
  refused. netstack has routes only for the families in `Address`.
- **`LANDialer`** (probe R5 plus the package test): public addresses, names, UDP, `::ffff:8.8.8.8`, NAT64
  `64:ff9b::`, `::`, `0.0.0.0` and `::ffff:0.0.0.0` are all refused. A zoned `fe80::1%1` is refused too
  (`Prefix.Contains` is false for a zoned address), and `::ffff:127.0.0.1` is allowed. The `Control` hook checks
  the very address the socket connects to, so there is no rebinding: names are never resolved.
- **The gate's public-address check.** It needs no new seam: `PublicConfig.Client = tun.HTTPClient(timeout)`. For
  the integration: the gate's `RouteConfig` must stay unset on the NAS. It asks the system's routes, which never
  go through a tunnel inside the program.
- **Key text.** Parse errors and `Status` hold no key. wireguard-go's error lines are only counted, its verbose
  lines dropped, and the `IpcSet` error text is dropped. The stats reader keeps only the handshake time and the
  byte counters.
- **Goroutines.** Shutdown is in order: the sampler is stopped and waited for, the idle connections are closed,
  then `dev.Close` (which closes the netstack stack). `TestCloseLeavesNoGoroutine` went 2 → 108 → 2 in my run.
  `Measure`'s memory sampler is stopped and waited for.
- **State fields.** They are read and written under `t.mu`. The configuration is copied before use, and the
  sampler's channels are set before the `go`. When `Start` and `Close` overlap, the second state check handles
  it.
- **`Measure`.** The address seen is never kept in the result, and "same" refuses the download. The byte cap,
  time cap and MB/s (10^6 bytes) are correct. The Unix build of `processCPUSeconds` compiles for Linux (vet
  clean).
