# Start of the ninth archiver session (written by the eighth session, 2026-11-13)

Paste into a new session in this project folder (Fable 5.2, medium effort):

> Read `START-SESSION-9.md` in this folder and do what it says.

## For the new session

Continue the standalone Telegram archiver as its ninth main session. You are the architect and the judge:
briefs, reading what was tried before and the risky part of each change, judging reports, decisions with the
owner, reading the real runs. Opus 5.5 at high effort codes in its own copy. A Sonnet clerk does the
mechanical steps on exact written instructions. One landed piece, then a fresh session.

**Read first, yourself and in full:**
1. `CLAUDE.md` in this folder.
2. The block **"CURRENT STATE ... THE NINTH SESSION STARTS HERE"** at the top of section 0c of
   `repo-archiver/archiver/docs/HANDOFF.md`. Stop where it says the block below is superseded.
3. `repo-archiver/archiver/docs/ROADMAP.md`. You are at stage A, before step A3.
4. `repo-archiver/archiver/docs/TRIED-BEFORE.md`, all 26 sections (2, 5, 7 and 23 matter most for downloads).
5. `repo-archiver/archiver/docs/FEATURES.md` section 12 (the eleventh round: "leave and count").
6. For this piece, the code, before any brief: in `internal/telegram` the connection watch (`ConnWatch`,
   in `options.go` and `connect.go`), `invokers.go`, `parts.go`, `refresh.go`, `call.go`, `counters.go`;
   then, before A3 runs, the engine's start (`internal/engine`), `internal/collector/staging.go` and how a
   kill is recovered (`supply.Recover`, the staging sweep). The eighth session read none of these.
Your memory files apply: `archiver-working-mode`, `archiver-session-start`, `agent-load-limits`,
`fork-session-contact`, `check-tried-before`.

**Then** tell the owner in a few lines what you read in full and what you did not, and what you start.

**Where things stand:** A1 (sign-in) and A2 (one chat read to its end: 760 messages in 8 requests, no wait)
have run for real on the test account; the VPN check has refused for real. The program at
`%LOCALAPPDATA%\tgarchive\bin\tgarchive-collector.exe` is built at e8f6e04 and is in Windscribe's split
tunnelling. The catalogue `%LOCALAPPDATA%\tgarchive\test\catalog\catalog.sqlite` holds 12 chats, chat 4
read to its end, and **741 wanted files (17.8 GB; 734 on server 2), none fetched.** If the collector's code
changes, build to the same path (`source ix-tools/env.sh`, then from `repo-archiver/archiver`: `go build -p
2 -o "$LOCALAPPDATA/tgarchive/bin/tgarchive-collector.exe" ./cmd/tgarchive-collector`), with no collector
running.

**Your piece, in two parts. Each may be a session of its own: say so to the owner if the first fills it.**

1. **The "leave and count" counter** (must exist before the first download). At each connection loss or new
   server session: per kind and hour, how many requests were then in flight, and how many of those were of a
   kind with a stated wait still running. Read the code named above, write the brief, an Opus coder builds
   it in its own copy with tests on the fake, you read the risky part of the diff, a clerk brings it in. A
   race-detector run of the changed packages is owed for this and for e8f6e04 (none was done): in Docker,
   capped, compile step apart (memory `agent-load-limits`).
2. **A3: download the chat's files with a kill and a restart.** Before it starts, decide with the owner:
   - **How much.** `run` without `-no-downloads` starts fetching all 741 files (17.8 GB) at once; there is
     no "these files only". Either the owner accepts the whole chat, or a coder adds a bound first.
   - **Where the kill comes** (mid-file, so a checkpoint and a resume are seen), and how (Task Manager, not
     Ctrl-C: Ctrl-C is the clean stop).
   - **Room on the staging disk** (the default keeps 50 GB free) and the test library folder.
   - Tell the owner beforehand what a downloading `run` sends (parts, reference refreshes per chat, the file
     pools' connections to other servers) from the code, as the eighth session did for the read.
   Then numbers, from `c_hourly`, `c_tg_hourly`, `c_conn_hourly` and `status`: bytes and parts by server,
   speed per busy slot, waits stated and slept, timeouts, what the kill left and what the restart gave back
   and resumed (bytes kept, prefix re-hashed), files verified. The engine's window is still `Careful` (the
   trap of TRIED-BEFORE 23): report its steps; no comparison with the old app's speed.

**Small things found in A2, for a coder when one is in the collector anyway** (the handoff has the list):
`signin` on a missing folder gives a bare error; nothing is printed when the chat list is stored; no time
per page and no wait lengths are kept; the others are in the handoff.

**Rules most often broken:** never touch the running old app or anything under `E:\T\` beyond what
`CLAUDE.md` allows; invented data only in tests; numbers only from real runs (never a name, text, id,
phone, code, password or address; the `chats` command's output is for the owner's eyes and is never
pasted); **no step against Telegram on an account without the owner present**; agents start at 2 cores and
may have about 4 when the PC shows room (the owner, 11-13), memory is the tight side (about 3 GB free), one
Go container at a time (`immich-ml` is the owner's), never deliberate load, measure the PC yourself after
starting agents; every agent keeps a PROGRESS file. Go is not on the PATH: `source ix-tools/env.sh` in Git
Bash first. Make an agent's copy by hand (`git worktree add --detach ../wt-<name> HEAD` from
`repo-archiver`). Every git command that makes a commit needs `-c user.name=Claude -c
user.email=noreply@anthropic.com`. The owner has limited attention: short reports, numbers first, plain
words, say what was not verified, and lead with what ran for real. A run that prints nothing looks stuck to
the owner: say beforehand what silence means.

**The eighth session** ("START-SESSION-8.md") has nothing running and can be closed by the owner. Tell the
owner once you have taken over.
