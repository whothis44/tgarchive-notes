# Independent review of NA2, the collector's way to Telegram (lent to Core by the NAS track; K-6, 2026-11-22)

You review `wip/nas-ctunnel` at 9c85b6a3 (holds main 2b38b2a3) in
`C:\Users\trabi\Claude\Projects\Telegram\repo-archiver\archiver`. You did not write it; find what is wrong. Read: the brief
`BRIEF-NA2-collector-tunnel.md` and the design `DESIGN-NAS-autonomous.md` (sections 4 and 6) in
`C:\Users\trabi\Claude\Projects\Telegram`; then the whole difference against 2b38b2a3. **It changes how the collector dials
Telegram**, and on the NAS the only allowed way is the in-process WireGuard tunnel (unless the owner stored "none").

**Where:** a detached scratch copy (`git -C repo-archiver worktree add --detach ../wt-nas-ctunnel-review 9c85b6a3`). Never
edit a branch; never commit or push. Probes by `go test -overlay`. Every go command through
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go2.sh <folder> ...`. Named tests and small packages whole
(`internal/collector/libclient`, `internal/wgdial`, `internal/botapi`, `internal/telegram` vpn tests); never the whole
`internal/collector` or `internal/catalog`; no Docker. Invented data, the fake Telegram and the test WireGuard peer
(`internal/wgdial/wgtest`) only; never the real Telegram, the NAS or the owner's folders. Never print a key, address or path.

**Look hardest at (fail closed everywhere):**
1. **No direct dial under "tunnel".** Every way the collector reaches out: each account's client (main, media and file
   pools, the reference refresh, the exact check's hashes, the sign-in steps, the mirror's commands), the VPN check's
   public-address request, the bot's `getMe`/`getUpdates`/`sendMessage`, anything resolved by name. With the tunnel's
   peer muted or the tunnel down, nothing may reach the system's own network: prove it with a listener on loopback.
   The hand-run `probe` command dials direct today: it must refuse under "tunnel" (asked of N-1; check).
2. **Defaults and bad values:** "system" on Windows, "tunnel" elsewhere, "none" only when stored; a value or file that
   cannot be read refuses to start, naming the key only; a stored "none" said at start, in every heartbeat, in the
   status file and in the gate's verdict.
3. **The tunnel's life:** started before any account dials; a dial before it is up waits or refuses, never goes direct;
   closed at the stop; a tunnel that dies mid-run makes the accounts read "the VPN check refuses" (K22's `account.vpn`)
   and nothing is queued to go out later direct.
4. **"system" unchanged:** the gate's and dialler's existing tests by name; nothing moved into `libclient` changes the
   PC's behaviour.
5. **The bot through the tunnel's dialler** (not its HTTP client, for the 50 s long poll): its own timeouts still bound.
6. Privacy: no key, endpoint address or path in a log line, an error or the status file.

**Report:** `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-NA2-ctunnel.md`: verdict first, findings with must / should /
minor, CONFIRMED or PLAUSIBLE, file and line, a one-sentence fix; the probes and their results; what to run under the race
detector. Your last message: the same, short. Remove your scratch copy after.
