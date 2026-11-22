# Review of N3: the NAS program and its deploy files (independent review, Opus, 2026-11-22)

Scope: `git diff 3764935a..4b698a56` on `wip/nas-program` (worktree `wt-nas-program`), read-only. Read first:
`BRIEF-N3-program.md`, `DESIGN-NAS-downloader.md` sections 1 to 5 and 8. Probes were run with `go test -overlay`
from `scratchpad/review-n3` (file `review_probe_test.go`, not in the tree), through `runs-nas-n1/go1.sh`, on
`./internal/nasdl/` only, named tests only, fake Telegram and loopback only. Nothing was edited, committed or pushed.

CONFIRMED means a probe run showed it (or, for the README, the steps fail as written). PLAUSIBLE means found by
reading.

## Findings, ranked

### 1. The sign-in status says "needs the phone number" for an account that is signed in. A new send_code then goes to Telegram (CONFIRMED)

`internal/nasdl/signin.go:82-93` (the `StepStatus` branch). With no sign-in open, the answer is
`StateSignedIn` only while `ar.state == ClientRunning`. Every other case gets `StateNeedPhone`. That includes an
account with a good session on disk whose work is not running: just after a sign-in, after a PC stop, after a
restart, or while it is dialling or waiting to retry. A new `SignIn` also starts at `StateNeedPhone`, because
`Load` only reads the memo of waits. So nothing stops a second sign-in on a session that is already logged in.

Probe A (`TestReviewStatusAfterSignIn`): after a finished sign-in, `status` returned "needs the phone number". A
`send_code` sent next was answered "code sent", sent 1 `signin` request to the fake, and put a 2nd sign-in
attempt on record.

**Failure scenario:** N4's Accounts page reads the status, shows "needs a sign-in", and the owner types the
phone again. The NAS then sends another `auth.sendCode` for an account that is already logged in. That costs one
of Telegram's sign-in attempts, sends a code to the owner's devices, and may make yet another login. The design
counts every sign-in request as costly (TELEGRAM-FACTS 8).

**Fix:**
- `StepStatus` should answer from the session store: whether it holds an authorisation (the session's own
  record, read with no request), plus `ClientSignedOut` when Telegram refused it.
- `beginSignIn` should refuse `send_code` while the session holds a login that Telegram has not refused (a
  fixed-word error such as "already signed in on the NAS").
- Add a test: status after a sign-in, and after a restart, says "signed in".

### 2. A sign-in that is left open blocks the account's downloads until the program restarts. An out-of-order first step dials Telegram first (CONFIRMED)

`signin.go:94-134`, `program.go:504-509`.

- A sign-in is closed only when a step reaches `StateSignedIn` or `StateRefused`.
- There is no timeout, no cancel step and no watch on the client's `Done()`.
- While `ar.signIn != nil`, `onStart` refuses every start with `ErrBusy` (busy).
- The step name is checked only after `beginSignIn` has already dialled a client (`signin.go:113-126`).

Probe B (`TestReviewAbandonedSignInBlocksWork`): a `password` sent as the first step dialled a client (dials 1) and
was answered "this step does not fit". After it, `Start` was refused as busy, and again 2 s later. The sign-in
stays open until `Close`.

**Failure scenarios:**
- The owner asks for a code and never types it, or the PC restarts mid sign-in. The NAS then refuses all work.
  The status gives no hint beyond the account's state "signing in", and only a container restart frees it.
- The sign-in's client dies (tunnel down, gotd ends). Every later step goes to a dead invoker ("the step
  failed") and the sign-in can never finish or close.

**Fix:**
- Check the step before dialling.
- Close the sign-in on any step error that leaves it at `StateNeedPhone`, and when `signC.Done()` fires.
- Add a "cancel" step, or end an idle sign-in after a few minutes, and say so in the status.
- Test that a started and abandoned sign-in no longer blocks `Start` after that time.

### 3. If the window record cannot be read, a later save writes floor levels over it (PLAUSIBLE)

`program.go:851-867` (`loadWindow` returns nil on any error) and `program.go:869-897` (`saveWindow` sends
`Upward.Remembered()`).

- `Remembered` holds every lane that ran, at the level it started from. With a failed load (link down at a
  reconnection, the 30 s timeout, the PC's `LoadWindow` error), those start levels are the floor (2).
- The version changes as soon as any one lane proves a new level. The save then carries the floor for every
  other lane.
- `Window.Save` is "the newest wins". The collector's record (`internal/collector/window.go:52-83`) is written
  whole.

**Failure scenario:** the PC's record is {2: 4, 4: 3}. A reconnection runs `loadWindow` while the PC is away, and
the NAS starts both lanes at 2. Later, server 2 proves 3, and the NAS saves {2: 3, 4: 2}. Server 4's proven 3
(rule 7 of WINDOW-EVIDENCE) is lost. The same happens to servers in the record that this start's `dcs.<account>`
does not list: they are left out of `Remembered`, so a whole-record save drops them.

The PC's own engine has the same shape, but its read is a local catalogue read. Here it is a network call, made
at every reconnection.

**Fix:**
- When the load failed, do not save for that engine (keep a flag beside `a.up`), or retry the load before the
  lanes start.
- Send only the lanes whose level changed, and have the PC merge them by server.
- Add a test with a `WindowStore` whose `LoadWindow` fails, checking that the record is unchanged after a
  proven step.

### 4. With `home_address = auto`, a direct request outside the tunnel goes out at every dial attempt, not "once at each start of work" (CONFIRMED)

`program.go:584-604` and `runAccount` `program.go:697-708`. `beginSignIn` (`signin.go:139`) does the same.

`makeGate` runs inside the retry loop. With `HomeAuto`, each pass makes one direct HTTPS request from the NAS's
own address to the address service, with system DNS, per account. Passes happen on: no app id, cannot dial, the
VPN check refusing, a lost connection, and every sign-in begun. The retry pause doubles from 5 s to 80 s, so a
lasting condition costs about 45 direct requests an hour per account, with no end.

Probe D (`TestReviewHomeAddressRequestsRepeat`): start without an app id, `RetryEvery` 200 ms. Over 6 s there
were 5 home-address lookups and 0 client dials.

What the documents say is narrower:
- The comment at `program.go:56-59`, `settings.conf.example` and the design say "one direct request ... at each
  start of work".
- The README (line 118) says "The program's only connection to the outside is UDP to the VPN server". It leaves
  out these HTTPS requests and their DNS lookups, and the endpoint's DNS lookup at tunnel start.

No Telegram traffic leaves this way.

**Fix:**
- Learn the home address once per start of work (or once per hour) and keep it in memory. Retries and sign-ins
  reuse it.
- Say in the README that the direct request and DNS lookups exist.
- Count the direct requests in the status.

### 5. The compose health check counts as a refused connection and logs "no paired key" every minute (CONFIRMED)

`cmd/tgarchive-nasdl/main.go:123-142` opens TCP to the listener and closes it before TLS. `internal/nasdl/node.go:437-445`
counts every failed handshake in `refused` and logs "a connection refused: no paired key".

Probe C (`TestReviewHealthCheckCountsAsRefused`): 3 checks moved the refused counter from 0 to 3 and logged 3
"no paired key" lines.

**Failure scenario:** with the compose file's 60 s interval, `Status.Refused` grows by 60 an hour and the log has
a "refused" line every minute. A real stranger's attempt is lost among them. Any alert built on `Refused` (N4,
K22) fires constantly or has to be ignored.

**Fix:**
- Either the check completes a TLS handshake with no client certificate and the node treats that case as
  "check" (not counted, not logged), or the node counts a connection that closes before sending any byte apart
  from real refusals ("closed before the handshake"). Or the check uses a separate local signal, such as a file
  the program touches each minute.

### 6. The README's install steps fail as written (CONFIRMED by reading)

`deploy/nasdl/README.md`:
- **Lines 76-85: step 6 comes before step 7.** Step 6 runs `docker compose run ... pair` in
  `/volume2/docker/tgarchive-nasdl`, but `compose.yaml` is only put there, with its placeholders replaced, in
  step 7. Step 6 fails ("no configuration file", or a bind source that does not exist). Swap the steps.
- **Lines 58-63, step 3.** `mkdir -p /volume2/docker/...` usually needs `sudo` on UGOS, which leaves the folder
  owned by root. The README says `ls -ldn` "must show 1000 10" but gives no command to fix it. Add
  `sudo chown 1000:10 <folder>` before the `chmod 700`. Step 2's test folder needs the same ownership check.

### 7. Memory: no unbounded buffer found in N3's own code; the 279 MB is most likely the tunnel's buffers, doubled by the test rig (PLAUSIBLE)

N3's own queues are bounded:
- the moved channel is 256 and drops when full;
- the journal has its cap;
- status rows are per lane;
- the parts in memory are bounded by the ceiling times the lanes.

The fake Telegram makes each part on demand (`faketg/world.go:67-83`) and holds no whole file.

The gap between the tunnel run and the no-VPN run (279 against 93 MB) sits on the tunnel side. In the test
there are two WireGuard devices and two gVisor stacks in one process (the program and the far end), and the
rig opens one TCP connection per request. wireguard-go on Linux keeps one 64 KiB buffer per packet, in pools
with no cap (`queueconstants_default.go`: `PreallocatedBuffersPerPool = 0 // Disable and allow for infinite
memory growth`). Its queues are 1024 deep, so they hold up to about 64 MB each at the test bind's batch of 1.
When the processor is short (the container's 2 CPUs, the PC busy), those queues fill.

Two probe runs did not reproduce the peak at their size:
- Probe E: 163 files, 251 MB, `GOMAXPROCS` 2: peak heap in use 31 MB.
- Probe E: 228 files, 237 MB, `GOMAXPROCS` 1: peak heap in use 34 MB.

At the first run's peak, the largest in-use entries were the rig's `io.copyBuffer` (the far end's forwarder),
gotd's `bin.Buffer` and the test invoker.

On the NAS there is one device. But the real Linux bind batches up to 128 packets per queue entry, so the bound
is the inner TCP windows times about 45 (64 KiB per packet of about 1.4 KB). If decryption falls behind (the
NAS's processor busy with the media server), this can pass the 340 MiB `GOMEMLIMIT`.

**Fix (measurement first):**
- Have M3 write a heap profile at its peak, as probe E does, so the source is named.
- Watch the peak Go memory at M2 (`vpntest` already prints it) with the NAS under its usual load.
- If wireguard-go's pools are the cause, it is N1's package: a bounded bind, or a smaller receive window in the
  netstack.

### 8. Tests that do not prove what they claim (PLAUSIBLE, by reading)

- **The real dial path never runs.** Every program test uses `viaDialer` (`program_test.go:299-325`), so
  `libDialer`, `telegram.NewClient`'s gate wrap and gotd's own dials (`Primary`, `MediaOnly`, `CDN`, migrations)
  are never exercised. `TestProgramRefusesWithoutResolver` (`program_test.go:1085`) checks only that
  `Options.Resolver` is not nil. It does not check that it is the tunnel's resolver.
  - Cheap fix: assert that `connectConfig` keeps the path's resolver unchanged, and that `NewClient`'s wrapped
    resolver calls it. Use a counting `dcs.Resolver`; no network needed.
- **`TestProgramPeerStoppedMidRun` cannot detect a leak.** `viaDialer` dials a tunnel-only address
  (10.9.0.1), and the fake listens on 127.0.0.1. A dial outside the tunnel would fail rather than reach the fake,
  so "accepted == taken" holds by construction. The test may also `t.Skip`.
- **The window save is tested by hand.** `TestProgramWholeRunThroughTunnel` (`program_test.go:910-918`) sends
  `Window.Save` with a manual `node.call`. The program's `saveWindow` (version tracking, the account filter, the
  retry after a failure) is never run.
- **Paths never tested:**
  - the staging folder with the copier (`pgOpts.staging` is never set);
  - the sign-in through the tunnel (`TestProgramSignIn` uses no VPN);
  - the status after a sign-in (finding 1).

### 9. Low (PLAUSIBLE)

- **Race between a sign-in and a start** (`signin.go:94-101` against `program.go:504-509`, `683-688`).
  `signInStep` sets `busy` before `ar.signIn` exists (that happens after the dial). A start that arrives in
  between is accepted. That account's `runAccount` then finds `busy` and sits idle for the whole work, with no
  state of its own. Its deferred `setState(ClientIdle)` also overwrites "signing in". Fix: have `onStart` test
  `busy` (or a `signingIn` flag set with it), not only `signIn`.
- **`vpntest` follows redirects.** Its `directAddress` (`main.go:249`) sets no `CheckRedirect`, so the direct
  request can be redirected to another host. The program's `homeAddress` refuses redirects (`program.go:628`).
  Make them the same.
- **A third mount.** `compose.yaml:47-50` mounts `/etc/ssl/certs` read-only. That is beyond "the program's own
  folder and one library folder". It is harmless, but it ties the image to the NAS's certificate layout, and
  dangling symlinks there would break the address check (which fails closed). An alternative is to embed the
  roots (`golang.org/x/crypto/x509roots/fallback`).
- **The user id crosses to the PC.** `SignInResult.UserID` (`nasproto/program.go:66`) carries the Telegram
  user id to the PC. N4 must not log or print it.

## Checked and found sound

- **The tunnel is the only way to Telegram when no-VPN is off.**
  - `p.path` is the tunnel's `DialContext` and `Resolver(dcs.PlainOptions{})`, which sets Dial to the tunnel.
  - `newLibDialer` refuses a nil resolver.
  - `connectConfig` sets `opts.Resolver` to the path's, so `NewClient` never falls back to `dcs.DefaultResolver`.
  - gotd's `Primary`, `MediaOnly` and `CDN`, the pools from `NewInvokers`, and migrations all go through the
    gated resolver.
  - The DC addresses are IP literals, so the tunnel looks up no name.
  - `directPath` is built only when `NoVPN` is set.
  - The gate's public check uses `tun.HTTPClient` (no proxy, the tunnel's dialler, no redirects).
  - The route check is off, which is right for an in-process tunnel.
  - If the home address cannot be learnt, nothing is dialled (`ClientNoHome`).
  - A missing `tunnel` key means the tunnel (the VPN is on by default).
- **The no-VPN setting is said in every place it should be:** the start log line, `Status.NoVPN`,
  `Status.Telegram`, the tunnel part of the status, the minute line, and the gate's override verdict. `vpntest`
  refuses when there is no tunnel.
- **Secrets stay out of logs, statuses and the disk:**
  - The phone, code and password are not logged, journaled or put in a status. They live only in the frame
    and are passed to `telegram.SignIn`.
  - The AppHash is kept in memory only, and no log line holds it.
  - The memo file holds wait times and reasons, and attempt times only. It is written 0600 and synced.
  - The session is encrypted with a `KeyFile` (0600, folders 0700). The key sits beside it in the program's
    folder, as the README says.
  - gotd has no logger (`LibLog` nil).
  - Every new log line has a constant format, with numbers and the account number (the collector's own
    convention).
  - Errors printed by `say` are fixed words: `SettingsError` and `wgdial.ConfigError` name the key or the line,
    never the value.
- **The writer stays inside its folders:**
  - Library paths come from the PC's `LibraryPath` through `store.joinRel` (`nashelper.ValidPath`: no `..`, no
    absolute path).
  - `store.Writer`'s rules (never replace a library file, the SHA-256 while writing and again before publishing)
    are unchanged, and `countingSink` passes `Finished` and `Duplicate` straight through.
  - With the root read-only, a library folder that is not mounted refuses to start, because `MkdirAll` fails.
- **Files the PC drops are stopped.** The engine's transport is `p.node.Transport(parts)` (the drop wrapper), and
  the test's `Engine` hook asserts it.
- **The link carries the new calls safely.** `Window.Load`, `Window.Save` and `Parts.Moved` are refused for
  accounts the PC does not serve, the sign-in steps are checked on the PC side, and requests are handled
  concurrently, so a long sign-in does not block pings.
- **The settings parser:** unknown keys and keys given twice are refused; values are never echoed; folders are
  made absolute; the tunnel file name cannot contain a path separator; `listen` cannot be the unspecified
  address.
- **The deploy files** follow the house style:
  - `network_mode: host`, no `ports:`;
  - `user: "1000:10"` (also in the image);
  - `read_only: true`, `cap_drop: [ALL]`, `no-new-privileges`;
  - `mem_limit` 384m with `GOMEMLIMIT` 340MiB, `pids_limit`, `cpus: 2.0`;
  - the health check reads the listen address from `settings.conf`;
  - `FROM scratch`, a static binary, no shell;
  - `stop_grace_period` 30 s, which is more than the engine's 5 s plus the client's 5 s.
- **Shutdown:** `Close` stops the work, then waits for it, the sign-ins, the node, the writer and copier, and the
  tunnel, in that order.

## Second pass (c007d404, 58768b65)

What was reviewed: `git diff 4b698a56..58768b65` only. The probes were re-run at 58768b65 by overlay
(`TestReview2*` in the scratch `review_probe_test.go`, through `go1.sh`, `./internal/nasdl/`, fake and loopback only,
"go1: exit 0"). Nothing was edited, committed or pushed.

### The first pass's findings, one by one

1. **Sign-in status: FIXED.** Probe A2: after a sign-in, status says "signed in". A second `send_code` is
   answered "already signed in on the NAS" with 0 requests to the fake, and the attempts stay at 1.
2. **A sign-in left open: FIXED.**
   - Probe B2: a password as the first step dials nothing (0 dials) and gets "this step does not fit". A
     start right after it is accepted.
   - `cancel`, the idle time (default 10 min) and the end of the sign-in's client each close it (coder's
     `TestProgramSignInOrderCancelIdleEnd`).
   - Wrong codes keep it open, as you accepted. Probe A2: 3 wrong codes made exactly 3 requests, one per
     step typed, and 3 s idle made 0. The idle timer is reset only by a step, never by `status`. Nothing
     loops or retries by itself.
   - Telegram's attempts are spent only by owner steps; the `telegram.SignIn` caps (too many tries) still
     apply.
3. **Window levels: FIXED.**
   - Nothing is saved after a failed load (`wloaded`; `TestProgramWindowNotSavedAfterFailedLoad`).
   - The PC merges by server under `windowMu`, and refuses to write if it cannot read the record. A server
     the NAS did not run keeps its level (5: 7 in `TestProgramWindowSavedAutomatically`).
   - Small cost, PLAUSIBLE: while the PC's `LoadWindow` keeps failing, the NAS asks to save once a second
     (the 1 s ticker), so the PC reads its catalogue once a second, uselessly. A backoff would do.
4. **Home address: FIXED.** Probe D2: 1 lookup at the start, still 1 after 5 s of the cannot-dial loop, and
   the status counts 1 direct request.
   - **Count outside the tunnel in a day,** with `home_address = auto`:
     - one HTTPS request plus its DNS lookup at the start;
     - then at most one every 6 h, and only when a gate is made after that (a dial or a sign-in): at most
       5 a day;
     - with the address service failing, at most one try every 15 min while gates are being made: at most
       96 a day, plus their DNS lookups;
     - plus the endpoint's DNS lookup at each start, and the same again at every container restart.
   - The README's new section "What leaves the NAS outside the tunnel" says exactly this.
5. **Health check: FIXED, with one regression (PLAUSIBLE, by reading).** No connection is made now, so
   nothing is counted as refused. But the heartbeat is written by its own goroutine (`heartbeat.go:31`). It
   keeps the container "healthy" after the listener has failed ("the listener failed; no more connections
   are taken", `node.go:383`), and the PC can then never reach the NAS. Fix: have the accept loop's end stop
   the heartbeat, or record the listener's death in the heartbeat file.
6. **README: FIXED.** `compose.yaml` comes at step 4 and the pairing at step 7, `sudo mkdir` is followed by
   `chown -R 1000:10`, and the paths are full.
7. **Memory: unchanged, as agreed.** M3 now writes a heap profile at the peak. I did not re-measure.
8. **Tests: FIXED.**
   - The real dialler's test (`TestProgramRealDialerThroughTunnel`) is a valid proof of 0 connections
     outside the tunnel. gotd's plain resolver dials **every** candidate for a server at once
     (`dcs/plain.go`: `go tryDial` for each option). The list names the tunnel-only address and the
     system's 127.0.0.1 at the same port, and a listener there counts. So any dial made by the system's
     dialler would show up at that listener, on every connection, and especially while the peer is muted.
     The test asserts 0, and that the parts bridged equal the parts the fake saw.
   - The staging test and the automatic window save test exist now.
9. **The lows: FIXED.**
   - A start during a sign-in now waits in `runAccount` (polling `busy` every `RetryEvery`) instead of
     sitting idle. There is no deadlock: the sign-in's idle close bounds the wait, `siMu` is never held
     across the wait, and `endSignIn` is safe from both the watcher and the step (it checks that `si` is
     still the open one).
   - `vpntest` no longer follows redirects.

### New defects in the fix

**N1. The "signed-in" mark can say signed in when the session is gone or revoked, and nothing on the PC
clears it.**
- How the mark works: `signin.go:77-115`. The mark (`sessions/<n>.signed-in`) is removed only when the
  engine's lane says signed out (`program.go`, `endSignedOut`).
- **Session unusable (CONFIRMED, probe G).** After a sign-in I removed the session's key file. The work's
  dial then fails (client "not started", no new dial), but status still says "signed in". Even after a PC
  stop, `send_code` is answered "already signed in on the NAS". The owner cannot sign in again from the PC
  at all: the only way out is deleting the mark by hand on the NAS. The same happens with a session file
  that is deleted or unreadable.
- **Login revoked (PLAUSIBLE; probe F could not reach it, because the fake does not refuse parts for a
  signed-out account).** Status and `send_code` behave the same while the program is idle. The mark goes
  only when a lane gets a part refused, and an account with no files waiting never finds out.
  - Even after the lane says signed out, `runAccount` keeps the account's `busy` while it waits for the end
    of the work (`<-ctx.Done()`). So a new `send_code` is refused as busy until the PC stops the whole work,
    for every account.
- **The reverse is harmless.** Session good, mark missing (its write failed: only logged) means finding 1
  again. That is rare.
- **Fix:**
  - `signedIn` should be the mark AND a session that loads (`SessionStore.LoadSession` with its key, no
    request).
  - A dial that fails to load the session should remove the mark.
  - Add a PC step "forget the NAS login" that removes the mark and the session, so the owner is never stuck.
  - On `endSignedOut`, release `busy` (return from `runAccount`) so a sign-in can follow without a stop.

**N2. Low (PLAUSIBLE).** A step error outside `keepOpen` closes the open sign-in. That includes
`ErrWrongStep` (for example a password sent while a code is awaited) and a context deadline when the PC's
call times out on a slow tunnel. The code already sent is then lost, and the next try needs a new
`send_code`: one more Telegram attempt and one more code to the owner's devices. Fix: keep the sign-in open
on `ErrWrongStep`, and on a deadline when Telegram has not answered.

### Verdict

Findings 1 to 9 are fixed. N1 has to be fixed before N4 builds the Accounts page on this status: it is the
one place where the owner can be locked out of re-signing in from the PC. N2, the heartbeat regression and
the once-a-second window save are small.
