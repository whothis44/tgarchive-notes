# Brief N3: the NAS program and its deploy files, on the fake Telegram (NAS track, session N-1, 2026-11-21)

**Why:** the downloader that runs on the owner's NAS (`C:\Users\trabi\Claude\Projects\Telegram\DESIGN-NAS-downloader.md`:
read it whole, with the owner's decisions in sections 3, 4 and 8) is made of three pieces built today: the tunnel
(`internal/wgdial`, branch `wip/nas-wgdial`, brief `BRIEF-N1-wgdial.md`) and the link with the NAS's remote halves
(`internal/nasproto`, `internal/nasctl`, `internal/nasdl`, branch `wip/nas-link`, brief `BRIEF-N2-link.md`). Both are
in independent review now; their fixes will be merged into your branch later. This piece makes them one program
that runs the real engine and writer on the NAS, and its Docker files, tested on the collector's fake Telegram only.
**Nothing signs in to Telegram, nothing is deployed, nothing goes to the NAS.** The PC's side in the collector (which
account downloads where, the Accounts page's sign-in relay) is NOT yours (Core's and pages' packages, piece N4).

**The owner's decisions that bind this piece (11-21):** the NAS signs in on its own (a second login of the account,
the code and password typed on the PC and relayed over the link, the key kept only on the NAS, encrypted); the VPN is
WireGuard inside the program, Windscribe the likely provider; **and a stored setting for no VPN**, off by default: with
it on, Telegram is dialled from the NAS's own network, said in every status and in the log's minute line, and the
address check is not a refusal. Every container on the NAS runs in host network mode (never bridge, never `ports:`),
as the NAS user `user: "1000:10"`, never root. Traffic between the PC and the NAS never goes through the tunnel.

**Rules of the house:** you are the Opus coder of this piece and hand back commit-ready work. Named tests only while
you work (`-run`, or your own small packages whole; never `internal/engine`, `internal/store`, `internal/collector`,
`internal/catalog` or `internal/telegram` whole); no race detector; no `go vet` over many packages. Invented data
only. No name, path, address, key or id in any log line, error text or commit message: new log lines are constant
format strings with numbers and fixed words only. Never touch a running program, the main copy `repo-archiver`, the
owner's folder `C:\Users\trabi\tgarchive-app`, anything under `E:\`, or the NAS. **You edit no existing package
outside this track's own** (`internal/wgdial`, `internal/nasproto`, `internal/nasctl`, `internal/nasdl` are this
track's; you may add to them; you add `cmd/tgarchive-nasdl` and `deploy/nasdl`). If something you need is unexported
in another package, say exactly what (a lent change for its owner to read); copying a small piece of assembly code
into your own package is fine, copying a mechanism is not. **Every `go` or `gofmt` command goes through the track's
lock script:** `bash /c/Users/trabi/Claude/Projects/Telegram/runs-nas-n1/go1.sh <folder> go test -p 1 -run '<names>' -timeout 15m ./internal/nasdl/ ./cmd/tgarchive-nasdl/`
(it prints "go1: exit N"; 97 or 98: nothing was run, wait and try again; reviewers share the lock). **Docker on the
PC** is allowed for the measurement M3 only, one container at a time, with the limits of the compose file
(`--memory 384m --cpus 2`), never pinned to all cores; measure the PC's free memory first and keep 2 GB free.

**Where:** from `C:\Users\trabi\Claude\Projects\Telegram`, two commands:
`git -C repo-archiver worktree add ../wt-nas-program -b wip/nas-program wip/nas-link`, then in
`C:\Users\trabi\Claude\Projects\Telegram\wt-nas-program`: `git merge --no-edit wip/nas-wgdial` (both branches only add
packages; a conflict can only be in `go.mod`/`go.sum`: keep both sides' lines). Work only there. Commit with
`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `wip/nas-program` to `private`, work in progress
too, after each step that builds. No `git stash`, no rebase.

## What exists (read before writing)

- How the PC assembles an account's downloads: `internal/collector/account.go`, the function that ends in
  `engine.New(ecfg)` (about lines 760 to 830: the transport `s.parts`, the Sink `store.Writer`, the exact checker,
  the window policy `supply.UpwardPolicy(st, loadWindow(...))`, `ecfg.Parts`), and `dial` (about line 410: the session
  store, the gate, `seam.DialParams`). Find the `seam` package it uses and how the parts transport is made from a
  connection. `internal/collector/staging.go` line 212: how `store.NewWriter` is configured.
- `internal/telegram/connect.go` (`NewClient`, `ConnectConfig`: the resolver handed in is wrapped by the gate),
  `vpn.go` (the gate: on the NAS `PublicConfig.Client = tun.HTTPClient(0)` and `RouteConfig` nil, as N1 found),
  `session.go` (`NewSessionStore`, `KeySource`), `parts.go` (`Locator`).
- `internal/collector/faketg`: the fake Telegram the collector's tests use. Your tests run the program against it
  through the real `nasctl` on the PC side and a `MemSupply` / `MemLedger` behind it.
- N2's report items for you: `FileRef.Locator` is `any`, so a `nasproto.LocatorCodec` must be given for
  `telegram.Locator` (its binary encoding); granted claims live in the PC's memory; `PartStore.Indexes` is a network
  call there. Read N2's packages before you start.
- `deploy/nashelper` and `deploy/thumbs` (Dockerfile, compose, README): the house style for the NAS (host mode, the
  uid and gid, read-only root, `cap_drop: [ALL]`, `no-new-privileges`, limits, a health check on the NAS's address).

## What to build

1. **The program, `cmd/tgarchive-nasdl`**, with the assembly in `internal/nasdl` (a `Program` type, testable):
   - `serve`: reads one settings file of plain words and numbers from its folder (listen address, the tunnel's file
     name or "none" for the no-VPN setting, folders, limits, the time without the PC before it stops), starts the
     tunnel (or, with no VPN, a direct dialler for Telegram only, said loudly), listens for the PC with N2's
     `nasdl` listener, and on the PC's start builds per account: the session store in its own folder (a key file of
     its own, made once), the Telegram client through `telegram.NewClient` with the tunnel's resolver and the gate,
     the parts transport, `store.Writer` on the NAS's disk (staging folder and library folder from the settings;
     straight to the library when no staging folder is set), the remote Supply/Ledger/Checker/PartStore from N2, the
     window policy, then `engine.New` and `Start`. Stop by the PC's command or after the time without the PC, at
     checkpoints. **The window policy's remembered levels** (rule 7 of WINDOW-EVIDENCE: what was proven per server,
     kept across restarts) live in the PC's catalogue today (`loadWindow`): give the NAS a way to read them at start
     and to write them back over the link (a call added to N2's table), or say why another way is better.
   - The NAS's side of the sign-in: methods over the link for "send the code", "the code", "the password", which
     drive the sign-in on the NAS's own session store; the PC side of it is N4's. Tested on the fake Telegram only.
   - `vpntest`: runs N1's `Measure` and prints its result as numbers and fixed words (MB/s, seconds, bytes, peak
     memory, CPU seconds, "address: different / same: refused / cannot tell"); never the address.
   - `check`: the health check (the listener answers), for the compose file.
   - `pair`: writes the NAS's half of N2's key pair from a file the PC made, and nothing else.
   - The status each minute over the link: the engine's per-server stats, the journal's length, Go's memory, the
     tunnel's `Status` (or "no VPN, by the setting"), bytes written.
2. **`deploy/nasdl`:** Dockerfile (static Linux binary, a small base, no shell needed at run time) and `compose.yaml`
   (`network_mode: host`, no `ports:`; `user: "1000:10"`; `read_only: true`; `cap_drop: [ALL]`;
   `no-new-privileges`; `mem_limit: 384m` and `GOMEMLIMIT` a little under it; `pids_limit`; `cpus: 2.0`; volumes: the
   program's own folder (keys, session, the tunnel's file, the journal, settings) and ONE library folder read-write,
   with placeholders and a comment that the first runs use a test folder; the health check on the NAS's address);
   a `README.md` in plain steps for the owner, with full commands, including how to put the Windscribe WireGuard file
   in the folder without anyone else reading it, and the check `ss -tn | grep -E '149\.154\.|91\.108\.'`.
3. **Tests (fake Telegram, loopback, invented data):** a whole run: the PC side (`nasctl` over `MemSupply` and
   `MemLedger`) starts the NAS program, which downloads a set of invented files from the fake Telegram through a
   tunnel to a test WireGuard peer (reuse N1's test fixture) into a temporary library; every file ends saved with the
   right SHA-256, the PC's ledger says so, the counters add up. The same run with the no-VPN setting (direct dial to
   the fake, and the status says "no VPN"). With the tunnel's peer stopped mid-run: no part goes anywhere else, files
   wait, nothing is lost, and the run finishes when the peer is back. The sign-in methods on the fake. The settings
   file: a bad value refuses to start with the key's name only.
4. **M3, the program's own memory and processor:** in Docker on the PC with the compose file's limits, a run of a few
   thousand invented files (mixed sizes, up to a few hundred MB, a total of several GB) against the fake Telegram:
   peak memory (container and Go heap), CPU seconds, MB/s; the tunnel on and off. One run each, said as "on the PC,
   in Docker, one run". If the fake Telegram cannot run outside the test binary, say so and measure in the test
   binary instead.

## Hand back

Commit-ready on `wip/nas-program`, pushed. Report in at most 50 lines: the commits; how the program is assembled
(what is reused, what was copied, what lent change another package would need, if any); the policy-memory choice;
what each test proves; M3's numbers; the files of `deploy/nasdl`; which tests start goroutines; anything in the design
that turned out wrong. Then stop.
