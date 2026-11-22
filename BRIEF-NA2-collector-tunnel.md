# Brief NA2: the collector reaches Telegram through the tunnel on the NAS (NAS track, N-1, 2026-11-22; lent to Core)

**Why:** the owner decided (11-22) that the whole collector runs headless on the NAS
(`C:\Users\trabi\Claude\Projects\Telegram\DESIGN-NAS-autonomous.md`, read it whole; this piece is section 4 and 6 (b)).
On the NAS the collector must reach Telegram ONLY through the in-process WireGuard tunnel (`internal/wgdial`, merged),
unless the owner's stored no-VPN setting is on. The NAS program of N3 (`internal/nasdl/program.go`, `libdial.go`,
merged) already does exactly this for its own client: port that way into the collector, do not invent another.
**This is Core's package: a LENT commit (message beginning "Lent to Core (collector):"), Core reads it, then one
independent review** (it changes how the collector dials Telegram).

**Rules of the house:** you are the Opus coder of this piece. Named tests only in `internal/collector` (never the whole
collector or catalog); small packages whole. Invented data only; numbers and fixed words in logs; no key, address,
path or id printed. Nothing against Telegram (the collector's fake and N1's test WireGuard peer only), nothing on the
NAS, never the owner's running app or folders. Every go command through
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-nas-n1/go1.sh <folder> go test -p 1 -run '<names>' -timeout 20m <pkgs>`.
**Where:** `git -C C:/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add ../wt-nas-ctunnel -b wip/nas-ctunnel private/claude/charming-feynman-vm2xia`;
commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `wip/nas-ctunnel` to `private`.

## What to build
1. **A stored setting** for the collector's way to Telegram: "system" (today's: the PC's VPN per-program rule and the
   gate's route and address checks; the default on Windows), "tunnel" (a WireGuard file in the collector's own folder,
   named in the setting), or "none" (the no-VPN setting: direct, said in every status, minute line and gate verdict, as
   N3 does). A value that cannot be read refuses to start, naming the key only.
2. **With "tunnel":** the collector starts `wgdial.Tunnel` before any account dials; every account's client gets the
   tunnel's resolver through the shared dialler (`internal/collector/libclient`); the gate runs with `RouteConfig` unset
   and `PublicConfig.Client = tun.HTTPClient(...)`; the home address learnt once per start and at most every 6 hours, as
   N3; the tunnel's state in the collector's status (and for Core's alerts the existing "VPN check refusing"). A client
   without the tunnel's resolver refuses to dial (N3's `ErrNoResolver` rule). The tunnel closes at the collector's stop.
3. Reuse N3's pieces where they are shareable (move them into `libclient` or `wgdial` rather than copying; say what moved).
4. **Tests:** the collector on the fake Telegram through a test WireGuard peer (N1's fixture): an account reads and
   downloads; with the peer muted nothing reaches a listener on the system's own loopback at the fake's port; "none"
   dials direct and says so; "system" is unchanged (the existing named tests of the gate and dialler pass); a missing or
   bad tunnel file refuses to start without printing it.

## Hand back
Ready for Core's read on `wip/nas-ctunnel`, pushed. Report in at most 20 lines: commits; Core's files touched; what moved
from nasdl; what each test proves; then stop.
