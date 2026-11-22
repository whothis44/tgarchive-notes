# Start of the seventh archiver session (written by the sixth session, 2026-11-13)

Paste into a new session in this project folder (Fable 5.2, medium effort):

> Read `START-SESSION-7.md` in this folder and do what it says.

## For the new session

Continue the standalone Telegram archiver as its seventh main session. You are the architect and the judge:
briefs, reading what was tried before and the risky part of each change, judging reports, decisions with the
owner, reading the real runs. Opus 5.5 at high effort codes in its own copy. A Sonnet clerk does the
mechanical steps on exact written instructions. One landed piece, then a fresh session.

**Read first, yourself and in full:**
1. `CLAUDE.md` in this folder.
2. The block **"CURRENT STATE ... THE SEVENTH SESSION STARTS HERE"** at the top of section 0c of
   `repo-archiver/archiver/docs/HANDOFF.md`. Stop where it says the block below is superseded.
3. `repo-archiver/archiver/docs/ROADMAP.md`: the one ordered path to feature complete and every feature's
   state (the owner agreed the order of stages A to F on 11-13). You are at stage A, step A1.
4. `repo-archiver/archiver/docs/TRIED-BEFORE.md`, all 25 sections (25 is new).
5. `repo-archiver/archiver/docs/FEATURES.md` section 12 (the eleventh round is new).
6. `repo-archiver/archiver/docs/progress/signin-REPORT.md` and the "Second task" section of
   `docs/progress/dialer-REPORT.md` (what the sign-in command does now).
Your memory files apply: `archiver-working-mode`, `archiver-session-start`, `agent-load-limits`,
`fork-session-contact`, `check-tried-before`.

**Then** tell the owner in a few lines what you read in full and what you did not, and what you start.

**Your piece: the test account signs in (A1).** The owner is at the PC whenever asked. In order:
1. Build the collector to its fixed path (a clerk job, or do it yourself: one command):
   `go build -o "$LOCALAPPDATA/tgarchive/bin/tgarchive-collector.exe" ./cmd/tgarchive-collector` from
   `repo-archiver/archiver` after `source ix-tools/env.sh`. Tell the owner the file exists; **the owner adds it
   to Windscribe's split tunnelling** (inclusive mode, confirmed by the owner on 11-13: only listed programs
   use the VPN; the old app's entry stays). Wait for the owner to say it is done.
2. **The home address, read fresh** (it is not static; never write it in any file, log, commit or report):
   just before the sign-in, ask a plain-text address service from a program that is NOT in the split tunnel
   (for example `curl` in Git Bash) and pass the answer as `-public-forbid`. The owner can also read it out.
3. Read `internal/collector/signin_cmd.go` yourself before the run, and tell the owner beforehand what the
   command will ask and do: the gate's verdict is printed before anything is typed; the phone is asked
   twice; **one code is asked for per run** (a short wait Telegram states is slept in full, then the command
   ends and is run again; a long one exits); there is no limit per day any more; a `-db` path that does not
   exist makes a new catalogue; the real Windows console (echo off and back, Ctrl-C at a prompt) is untested.
4. With the owner present:
   `tgarchive-collector.exe signin -db <test catalogue> -staging <test staging> -vpn-adapter WindscribeOpenVPN -public-forbid <home address>`
   The three test folders exist and are empty: `%LOCALAPPDATA%\tgarchive\test\catalog`, `...\staging`,
   `...\library`. They are the test account's alone: a staging folder now belongs to one catalogue (a mark
   at its root) and the app refuses another's.
   **This is the first time the route check meets Windscribe's per-program rule.** `vpn.go`'s own comment
   says it is not known whether such a rule shows in the routing the check reads. If the gate refuses while
   the program is in the split tunnel: do not use the override; stop, record the verdict's fixed words, and
   decide with the owner (the public-address check alone may be the honest gate on this PC).
5. Record in the handoff: the gate's verdict words, the counts the command prints, requests by method,
   waits stated and slept, how long each step took, what the real console did. Numbers only: never the
   phone, the code, the Telegram id or the address.
6. **Then the two-step password, for real** (the frozen account has one; the test account has none; the
   fake cannot tell a right password answer from a wrong one): ask the owner to set a two-step password on
   the test account from the phone; sign in again into a second, new test catalogue folder (the same day is
   fine) and record the same numbers. Not known: whether a frozen account is refused
   `account.getPassword`.
7. Committed and pushed to `private`; the roadmap's rows updated on evidence only; the handoff's CURRENT
   STATE block rewritten short; a `START-SESSION-8.md` for A2 (read one small chat the owner approves, counts
   compared with the owner's phone). Before A3 (downloads) the "leave and count" counter must exist
   (FEATURES section 12, eleventh round).

**State of the repository at hand-over:** branch `claude/charming-feynman-vm2xia` at 62eef2d, pushed to
`private`, working tree clean. The coders' copies `wt-dialer` and `wt-bytefix` are already removed (the
handoff still says they "can be removed"); `wt-bytepath2` is left (18 uncommitted reviewer files, not checked
against the committed copies). Whole suite on Windows and the race detector on telegram, collector, store,
storeledger and tgstore: clean on the final code.

**Open points from the sixth session that touch your piece or the next (none is fixed):**
- A file pool can save a server's key after the client's run has ended (the dialer report's open points):
  matters from A3.
- A client that never ends keeps its session file held: the account then waits at "connecting" with one log
  line. Not seen for real.
- A stop in the instant between creating the staging mark and writing it leaves an empty mark; every start
  then refuses until a person deletes that file.
- An unused copy of the old sign-in limit is left in `internal/catalog` (`ReserveSignInAttempt`): a
  one-line clerk job plus its tests, or leave it.
- Minor findings 5 to 12 of the second byte-path review are not fixed: before the real library.

**Rules most often broken:** never touch the running old app or anything under `E:\T\` beyond what
`CLAUDE.md` allows; invented data only; nothing against Telegram except no-account connections at your own
judgment, sparingly, each recorded in the handoff; **no sign-in step without the owner present**; 2 cores per
agent unless the owner says there is headroom (on 11-13 the owner allowed 4 for the Docker race run), one Go
container at a time (a container named `immich-ml` is the owner's), never deliberate load, measure the PC
yourself after starting agents (free memory was between 0.6 and 4.3 GB on 11-13); every agent keeps a
PROGRESS file; tell the owner what a long run costs before it starts; nothing new is built before the first
real files download. Go is not on the PATH: `source ix-tools/env.sh` in Git Bash first. Make an agent's copy
by hand (`git worktree add --detach ../wt-<name> HEAD` from `repo-archiver`). **Every git command a clerk runs
that makes a commit needs** `-c user.name=Claude -c user.email=noreply@anthropic.com` **(cherry-pick too).**
The owner has limited attention: short reports, numbers first, plain words, say what was not verified, and
lead with what ran for real.

**The sixth session** ("START-SESSION-6.md") has nothing running once its handoff is pushed and can be
closed by the owner. Tell the owner once you have taken over.
