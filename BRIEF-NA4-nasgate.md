# Brief NA4: the PC reaches the NAS's pages and viewer behind pinned keys (NAS track, N-1, 2026-11-22)

**Why:** the app runs headless on the NAS (`C:\Users\trabi\Claude\Projects\Telegram\DESIGN-NAS-autonomous.md`, section 2);
the PC's window must show the NAS's pages and viewer over the home network, and no other device at home may use them.
The NAS's collector serves its pages on `127.0.0.1:8797` and the viewer on `127.0.0.1:8798` (`deploy/nas-app`, merged),
each accepting only that exact Host. This piece is a small front of this track's own, at both ends, so that NO page,
viewer or window code changes: on the NAS a front listens on the NAS's home address with mutual TLS and forwards to the
two local servers; on the PC a back end listens on `127.0.0.1:8797` and `127.0.0.1:8798` and forwards over that mutual TLS,
so the PC's window points at the same addresses it would for a local app.

**Rules:** you are the Opus coder. This track's packages only (new `internal/nasgate`, new `cmd/tgarchive-nasgate`; reuse
`internal/nasproto`'s `Pair`/`Bundle` keys and `nashelper`'s allow-list and connection cap ideas). Invented data only;
numbers and fixed words in logs (never a path, address or key). Nothing against Telegram, nothing on the NAS, never the
owner's running app or folders. Every go command through
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-nas-n1/go1.sh <folder> go test -p 1 -run '<names>' -timeout 15m ./internal/nasgate/ ./cmd/tgarchive-nasgate/`.
**Where:** `git -C C:/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add ../wt-nas-gate -b wip/nas-gate private/claude/charming-feynman-vm2xia`;
commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `wip/nas-gate` to `private`.

## What to build
1. **`internal/nasgate`:** `Front` (NAS side): listens on a configured home address, TLS 1.3 with the paired keys only
   (the PC's certificate pinned; the private ranges allow-list; a connection cap counted after the handshake with a
   handshake timeout), and forwards each TLS connection to one of two local targets chosen by the client (a fixed
   one-byte or header prefix per stream, or two listen ports: pick and say why); it rewrites nothing in HTTP if it
   forwards bytes (the PC side sets the Host), or, if it proxies HTTP, sets Host to the target's exact address. `Back`
   (PC side): listens on 127.0.0.1 at the two ports, and for each connection dials the Front over the same mutual TLS.
   Never through a VPN: the Back dials only private addresses (`wgdial.LANDialer`).
2. **`cmd/tgarchive-nasgate`:** `front` (NAS), `back` (PC), `pair` (makes the key bundle for the NAS from the PC's side and
   writes the PC's half; the same `nasproto` bundle format), `check` (health: a heartbeat file, no network).
3. **Tests (loopback, invented):** two local HTTP servers that, like the real ones, refuse a wrong Host; a request through
   Back and Front reaches each with the right Host and back; a third key pair is refused both ways; plain TCP and TLS 1.2
   refused; a public remote address refused by the allow-list; a stranger cannot hold the cap; long-lived connections
   (the viewer's media ranges, a websocket or event stream if the pages use one: check) pass through; no goroutine left
   after Close; no address or key in any log line.
4. **Deploy:** add the front as a third service to `deploy/nas-app/compose.yaml` (host mode, 1000:10, read-only, no
   capabilities, a small mem_limit, the heartbeat check) and a short section to its README: pairing once, then the PC's
   side. Say in the README how the PC runs `back` until the app's launcher starts it itself (a later piece).

## Hand back
On `wip/nas-gate`, pushed. Report in at most 15 lines: commits, the stream choice and why, what each test proves, which
tests start goroutines; then stop.
