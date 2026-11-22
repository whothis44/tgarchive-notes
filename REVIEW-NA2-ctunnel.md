# Independent review of NA2: the collector's way to Telegram (`wip/nas-ctunnel` 9c85b6a3, holds main 2b38b2a3)

Reviewer: an Opus 5.5 agent at high effort, 2026-11-22. I read the brief, DESIGN-NAS-autonomous.md sections 4 and 6, and the
whole difference against 2b38b2a3. I worked in a detached scratch copy (now removed), ran probes only by `-overlay`, and
put every go command through `runs-core-k5/go2.sh`. I used invented data, the fake Telegram and `wgtest` only.

## Verdict

**Ready after one must and three shoulds.** The tunnel's way fails closed. With "tunnel" set, every Telegram client,
the gate's public-address check and the bot dial only through the tunnel. Nothing falls back to the system's network,
and nothing is kept to go out directly later. "system" is unchanged and "none" is announced everywhere.

- **The must:** the hand-run `probe` command still dials direct. This is already on N-1's fix list.
- **The shoulds:**
  - A tunnel that dies mid-run is not seen by the gate for up to 5 minutes.
  - A tunnel file with no DNS line fails closed, but nothing says why.
  - The tunnel is brought up before the catalogue's lock is taken.

## Findings

1. **MUST, CONFIRMED: `probe` dials direct whatever the stored way is.**
   - `cmd/tgarchive-collector/main.go:85` sends `probe` straight to `probe.Run`.
   - `internal/probe/run.go` has no `-db` and never reads `collector.telegram_way`, so on the NAS `probe -direct`, or a
     `-vpn-adapter` check that passes, connects from the NAS's own network.
   - Fix: give `probe` `-db` and refuse unless the way read is "system", or "none" said aloud. On a non-Windows system
     with no `-db`, refuse.

2. **SHOULD, CONFIRMED: a tunnel that dies mid-run keeps the gate saying "allowed" for up to `PublicMaxAge` (5 min).**
   - Where: `telegramway.go:324` with `libclient/path.go:60-66` and `telegram/vpn.go:404-421`.
   - With the route check off, `DialCheck` answers from the cached public verdict.
   - Probe A shows it: peer muted, tunnel reads `down` (`way.down()` true), and `DialCheck` still returns Allowed in 0 s.
   - Nothing goes direct: the account's dials fail inside the tunnel with ErrTunnelDown.
   - But the accounts do not read "the VPN check refuses" (K22's `account.vpn`) until the cache ages out. On top of that
     comes the tunnel's own 180 s floor before it reads down.
   - `TestTelegramWayTunnelFailsClosed` mutes the peer from the start only, so this case is untested.
   - Fix: give `GateConfig` a per-dial hook (`Up func() bool`, or a tunnel-state check run like the route check on
     every `DialCheck`) set to `!way.down()` under "tunnel". Add a test that mutes the peer mid-run.

3. **SHOULD, CONFIRMED: a tunnel file with no `DNS` line, together with the default address service (a name), refuses
   every check forever and never says why.**
   - Where: `telegramway.go:305-337`.
   - Probe A2: open accepted, note "the tunnel is up", then every verdict is "public cannot tell" ("the public-address
     check did not say allowed").
   - The bot's `api.telegram.org` is refused the same way (`wgdial` refuses names when `dns == 0`).
   - It fails closed, but the owner sees only "VPN check refuses".
   - The tests use the address service by IP (`http://10.9.0.1/ip`) and a file without DNS, so the default form is never
     exercised.
   - Fix: in `openWay`, refuse at start with fixed words naming the key `DNS`, when `wc.DNSServers() == 0` and the
     service's host (or the bot's) is a name.

4. **SHOULD, PLAUSIBLE (stall measured in a probe): the tunnel comes up before the catalogue's lock is checked.**
   - Where:
     - run: `command.go:704`; the lock is taken in `Collector.Run` (`collector.go:773`).
     - signin: `signin_cmd.go:136`; the lock is taken in `c.Run`, after the console check.
     - mirror: `mirror_cmd.go:466`, before `acquireLock` at :478.
   - So a second start beside a running collector (signin is the likely one, or run without `-pages`) brings up a second
     WireGuard device on the same key. With the file's `PersistentKeepalive` it also sends a handshake, and only then is
     it refused.
   - Probe B2 (two tunnels from one file, one peer): with the second held 12 s, 5 of 30 of the first's echoes failed, and
     its connection had not recovered 60 s after the second closed.
   - With a 1.5 s overlap (Probe B), nothing was lost. A refused start lives less than that, so this is plausible, not
     shown.
   - Fix: take or check the catalogue's lock (`acquireLock`, or a non-taking check) before `openWay` in run, signin and
     mirror.
   - Related, design note: on the NAS the collector and `nasdl` must never share one WireGuard file or key.

5. **MINOR, CONFIRMED: the collector never reports the home-address requests made outside the tunnel.**
   - `ow.home` is set (`telegramway.go:334`) but never read.
   - `Home.Logf` is not set in the collector (N3 logs one line per address learnt).
   - `Home.Direct()` appears in no status, while N3's status carries `DirectRequests`.
   - Fix: pass a `Logf` with the fixed line and add `direct_requests` to `statusWay`.

6. **MINOR, CONFIRMED: the tests never dial the production `LibraryDialer` on the tunnel's resolver in the collector;
   `env.NewDialer` replaces it with `faketg.RemoteDialer`.**
   - Probe C covers it: `openWay`'s own dialler, with Primary, Media and CDN dials to a loopback server address, peer
     answering or muted, made 0 connections to the system's loopback.
   - `nasdl`'s `TestProgramWholeRunThroughTunnel` covers the same `libclient.Dialer` with tgtest.
   - Fix (optional): keep Probe C as a test.

7. **MINOR, CONFIRMED: the order of messages and checks around the tunnel.**
   - run and signin print `-direct`'s "connects DIRECTLY" note before `openWay` refuses `-direct` with a stored
     non-system way (`command.go:645`, `signin_cmd.go:121`).
   - signin brings the tunnel up before its console check refuses (`signin_cmd.go:150`).
   - Fix: print the note after `openWay`, and do the console check first.

8. **MINOR, PLAUSIBLE: the bot can stay silent while the tunnel is down.**
   - `botAllowed` returns false while the tunnel reads down (`alertbot.go:131`). With no keepalive in the file and no
     account dialling, nothing probes the tunnel again.
   - Accounts normally do dial, so the tunnel recovers in practice.
   - Fix: let `botAllowed` fall through to `DialCheck` once per `RetryEvery`, since the gate's own request is the probe.

**What holds (checked):**
- Every collector client is built through `openWay`: `env.dialer()` and `gf.gate` are reached only from `openWay`'s
  "system" branch.
- `NeedResolver` stops a nil resolver before the session file is held.
- The gated resolver wraps Primary, Media and CDN.
- The gate's public check uses `tun.HTTPClient`.
- The bot uses `NewDialAt`, with the tunnel's dial in its own transport. Its 50 s poll and every call are still bounded
  by the call's context; the 10 s dial timeout is now covered by the call's bound.
- The only uses of the system network under "tunnel" are by design:
  - the WireGuard UDP itself;
  - the endpoint's name lookup;
  - the home-address learn: one direct request, at most every 6 h, or every 15 min after a failure.
- Defaults are right: "system" on Windows, "tunnel" elsewhere, "none" only when stored.
- Unreadable values and files refuse, naming the key or a line only.
- "none" is said at start, in every heartbeat, in the status file and in the override verdict.
- The tunnel closes by `defer` on every exit path after it opens.
- `nasdl`'s move into `libclient` keeps its behaviour, and its named tests pass.
- Privacy: no key, endpoint, address or path in any line, error or status field. The `wgdial` errors are fixed words,
  and `ConfigError` gives a line and a key only.

## Probes and results (overlay files only; nothing committed)

| Probe | What it checks | Result |
|---|---|---|
| C `TestZZProbeNA2ProductionResolverNeverDirect` | the program's dialler under "tunnel" (no test seam), its resolver's Primary, Media and CDN to 127.0.0.1, peer up and muted | 0 connections to the system's loopback (holds) |
| A `TestZZProbeNA2GateAllowsWhileTunnelDown` | gate allowed with the peer up; peer muted until the tunnel reads down; `DialCheck` again | Allowed, at once (finding 2) |
| A2 `TestZZProbeNA2DefaultServiceNoDNS` | the default service with a file that names no DNS | start accepted; every check "cannot tell" (finding 3) |
| B `TestZZProbeNA2SecondTunnelSameKey` | a second tunnel on the same key up for 1.5 s | the first's echo kept working |
| B2 `TestZZProbeNA2SecondTunnelHeld` (wgdial) | the second held up for 12 s | 5 of 30 echoes failed; no recovery within 60 s after it closed (finding 4) |

**The branch's own tests and the regression runs, all passing:**
- Collector, the seven `TestTelegramWay*` tests: 29.9 s.
- `internal/wgdial/...`, `internal/collector/libclient`, `internal/botapi/...`, each whole.
- `internal/telegram -run 'Public|Gate|VPN|Forbid|Connect'`.
- `cmd/tgarchive-collector -run TestSigninCommand`.
- `internal/nasdl`, named: WholeRunThroughTunnel, NoVPNSetting, PeerStoppedMidRun, RefusesWithoutResolver, SignIn,
  SettingsRefuseByKeyName.

## Under the race detector (once, after the fixes)

- `internal/collector -run 'TestTelegramWay'`: the way is read from heartbeat, status, bot and gate goroutines.
- `internal/collector/libclient`, whole: `Home` uses a mutex and an atomic and is called from the gate.
- `internal/nasdl -run 'TestProgramWholeRunThroughTunnel|TestProgramPeerStoppedMidRun'`: `Home` moved, and is used from
  the start goroutine and from the gate.

`internal/telegram` needs no race run: `ForbiddenNow` is called under the existing `pubMu`.
