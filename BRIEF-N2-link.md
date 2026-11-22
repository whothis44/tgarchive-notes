# Brief N2: the link between the PC and the NAS downloader (NAS track, session N-1, 2026-11-21)

**Why:** the new app gets a downloader that runs on the owner's NAS while all control stays on the PC (the owner,
11-14: "as long as the app/control remains on the PC and connects to it"). The design
(`C:\Users\trabi\Claude\Projects\Telegram\DESIGN-NAS-downloader.md`: read sections 1, 2 and 6 first, the whole note
if you have time) runs **the same engine and the same writer, unchanged**, on the NAS, with their interfaces to the
catalogue answered by the PC over the home network. This piece is that link and nothing else: no Telegram, no
program, no Docker. When it is done, the engine must run with every catalogue call going over a real TCP connection
and end exactly as it ends when run in one process.

**Rules of the house:** you are the Opus coder of this piece and hand back commit-ready work. Named tests only while
you work (`-run`, or your own new packages whole; never `internal/engine`, `internal/store`, `internal/collector` or
`internal/catalog` whole); no race detector while you work (the full runs are the session's, once, before the merge;
say which of your tests start goroutines). Invented data only. No name, path, address, key or id in any log line,
error text or commit message: new log lines are constant format strings with numbers and fixed words only. Nothing
runs against Telegram. Never touch a running program, the main copy `repo-archiver`, the owner's folder
`C:\Users\trabi\tgarchive-app`, anything under `E:\`, or the NAS. **You do not edit any existing package:** you only
add new ones. If an existing interface makes something impossible, stop and say exactly what is needed. **Every `go`
or `gofmt` command goes through the track's lock script:**
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-nas-n1/go1.sh <folder to run in> go test -p 1 -run '<names>' -timeout 15m ./internal/nasproto/ ./internal/nasctl/ ./internal/nasdl/`
(it prints "go1: exit N"; 97 or 98: nothing was run, wait and try again). Another coder of this track (N1, the
tunnel) uses the same lock; that is expected.

**Where:** make the copy yourself, one command, from `C:\Users\trabi\Claude\Projects\Telegram`:
`git -C repo-archiver worktree add ../wt-nas-link -b wip/nas-link af4ca40e`. Work only in
`C:\Users\trabi\Claude\Projects\Telegram\wt-nas-link`. Commit with
`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `wip/nas-link` to `private`, work in progress
too, after each step that builds. No `git stash`, no rebase, no other branch.

## What exists (read before writing)

- `archiver/internal/engine/types.go` in full: `Supply`, `CheckSupply`, `ProbeSupply`, `Checker`, `PartStore`,
  `Transport`, `Sink`, `File`, `FileRef`, `Progress`, `LaneID`, `RefreshResult`, `Hold`, the typed errors. Note that
  most `Supply` methods take no context and return no error: over a network that is the hard part (below).
- `archiver/internal/engine/engine.go` (`Config`, `New`, `Start`, `Wait`, `Stats`) and `memsupply.go`
  (`NewMemSupply`): the in-memory supply your tests run the engine against. The engine's own tests show how a fake
  `Transport` and a `Sink` are given (pick the smallest, e.g. in `engine_test.go`).
- `archiver/internal/store/ledger.go` (`Ledger`) and `memledger.go`: the writer's catalogue interface. On the NAS the
  writer (`store.Writer`) and its copier run there and their `Ledger` is answered by the PC.
- `archiver/internal/supply/supply.go`: the catalogue's real `Supply` (copies' package; read only, to learn which of
  its finishing calls are safe to apply twice and which are not).
- `archiver/internal/nashelper/server.go`: the model for the NAS's listener (`DefaultAllow`, the connection cap,
  `connLimit`, the numbers-only log). Copy what you need; do not import it if that drags its HTTP server along.

## What to build (three new packages)

1. **`archiver/internal/nasproto`: the wire.** Length-prefixed frames (a cap on a frame's size), each a JSON object
   with a request id, a method name, arguments or a result or a typed error. Calls go both ways on one connection.
   `Hello` first: program and wire versions of both sides, the NAS's id; a mismatch of the wire's major version
   refuses with a fixed reason. Every call has a deadline; a lost connection fails every call in flight with
   `ErrLinkDown`. Mutual TLS with pinned keys: a `Pair()` that makes two ed25519 key pairs with self-signed
   certificates (the PC's and the NAS's) and writes/reads them as files; each side accepts only the other's pinned
   certificate (no CA, no host-name check, TLS 1.3 only). The method table is written out by hand (no reflection in
   the code); **a test uses reflection to prove that every method of `engine.Supply`, `engine.CheckSupply`,
   `engine.ProbeSupply`, `engine.Checker`, `engine.PartStore` and `store.Ledger` has its wire method**, so a method
   added to an interface later fails that test.
2. **`archiver/internal/nasctl`: the PC's side.** `Dial(ctx, addr, pair)` to the NAS (the PC dials; the NAS
   listens), then serves the NAS's calls from a real `engine.Supply` / `CheckSupply` / `ProbeSupply` / `Checker` /
   `PartStore` and `store.Ledger` it is given, and offers the PC's commands (start, stop taking new work, stop,
   settings as a plain map of words and numbers, status). Refuses a second NAS for the same accounts. Reads the NAS's
   status each minute (the engine's `Stats`, the journal's length, memory, the tunnel's state as an opaque struct the
   NAS fills: N1 builds the tunnel).
3. **`archiver/internal/nasdl`: the NAS's side.** `Listen` on an address with the allow-list of private networks and
   a connection cap; accepts one PC at a time. Gives the engine and the writer **remote implementations** of the
   interfaces above that call the PC. The rules, which are the point of this piece:
   - **Fail closed, no work without the PC:** while the link is down, `Next` returns no file and `Claim` false;
     nothing is claimed that the PC did not hand out. After a setting's time without the PC (default 10 minutes)
     the NAS tells its engine to stop taking work and stops at checkpoints (find how the engine is stopped cleanly
     and use that; do not add to the engine).
   - **No finish is lost:** every call that reports what became of a file or keeps a state (`Saved`, `Aside`,
     `Release`, `Requeue`, `Gone`, `HandOver`, `SaveProgress`, `SaveHold`, `SaveFileWait`, `CheckSame`, `CheckHeld`,
     `Probed`, every `Ledger` write) is first appended to a small journal file on the NAS (written and synced before
     the call returns to the engine) and then sent; on reconnection the journal is replayed in order before any new
     `Next`, and an entry is dropped only when the PC has acknowledged it. Bound the journal (a cap and what happens
     at it: stop taking work, never drop).
   - **Each finish takes effect once on the PC:** a replay after a crash may send an entry twice. Read the real
     supply and ledger and find which calls are not safe twice; make the PC side apply each journal entry exactly
     once (for example a sequence number per NAS kept by the PC side in a small file beside the app's data, written
     in the same step as the effect where that is possible, or a key per claim the PC checks). Say what you chose and
     why, and where a double effect is still possible.
   - **What must come from the NAS itself:** `LoadProgress` answers from the NAS's own journal first (the bytes are
     on the NAS; the PC's row is only shown), then the PC's.
   - `Refresh` and `Checker.Check` go to the PC (its own Telegram session makes those requests) with the caller's
     context; a link error comes back as the typed error the engine already handles (say which one you map to).
   - `PartStore.Kept` fetches a kept part's bytes from the PC (a few MB a probe; a cap per call).
4. **Tests (invented data, loopback TCP, no internet):**
   - **The same run twice:** the real engine with a fake `Transport` (fixed files, a few plain waits and a -503) and
     a `Sink`, against `MemSupply`, once in one process and once with every `Supply` call going over the link; the
     same files end saved, aside or released, with the same attempts. Then the same with the link cut and restored
     twice in the middle, and once with the NAS side "crashing" (its process state dropped, the journal kept) and
     restarting: still every file ends once, nothing claimed twice, no finish lost.
   - The fail-closed rules: no claim while the link is down; stop after the time without the PC (an injected clock,
     no sleeping); the journal's cap.
   - The pinned keys: a third key pair is refused both ways; plain TCP is refused; a public address is refused by
     the allow-list (inject the remote address).
   - The reflection test of the method table.
   - No goroutine outlives `Close` on either side.

## Hand back

Commit-ready on `wip/nas-link`, pushed. Report in at most 50 lines: the commits; the wire in ten lines; the
exactly-once choice and where a double effect is still possible; which existing calls you found unsafe twice; what
each test proves; which tests start goroutines (for the race run's list); anything in the design that turned out
wrong, or any interface that made something impossible. Then stop.
