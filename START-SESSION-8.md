# Start of the eighth archiver session (written by the seventh session, 2026-11-13)

Paste into a new session in this project folder (Fable 5.2, medium effort):

> Read `START-SESSION-8.md` in this folder and do what it says.

## For the new session

Continue the standalone Telegram archiver as its eighth main session. You are the architect and the judge:
briefs, reading what was tried before and the risky part of each change, judging reports, decisions with the
owner, reading the real runs. Opus 5.5 at high effort codes in its own copy. A Sonnet clerk does the
mechanical steps on exact written instructions. One landed piece, then a fresh session.

**Read first, yourself and in full:**
1. `CLAUDE.md` in this folder.
2. The block **"CURRENT STATE ... THE EIGHTH SESSION STARTS HERE"** at the top of section 0c of
   `repo-archiver/archiver/docs/HANDOFF.md`. Stop where it says the block below is superseded.
3. `repo-archiver/archiver/docs/ROADMAP.md`. You are at stage A, step A2.
4. `repo-archiver/archiver/docs/TRIED-BEFORE.md`, all 26 sections (26 is new: a count is not a plan).
5. `repo-archiver/archiver/docs/FEATURES.md` section 12 (the twelfth round is new: read every visible chat
   by default, and further).
6. For this piece, the code the run goes through, before the run: `internal/collector/command.go` (the `run`
   command and its flags), how a chat is approved for reading, and the reader (`reader.go`). The seventh
   session read none of these.
Your memory files apply: `archiver-working-mode`, `archiver-session-start`, `agent-load-limits`,
`fork-session-contact`, `check-tried-before`.

**Then** tell the owner in a few lines what you read in full and what you did not, and what you start.

**Where things stand:** the test account is signed in, for real, in two catalogues (numbers in the handoff):
`%LOCALAPPDATA%\tgarchive\test\catalog\catalog.sqlite` (use this one; its `staging` and `library` folders
beside `catalog` are empty) and `...\test2\...` (spare). The program is at
`%LOCALAPPDATA%\tgarchive\bin\tgarchive-collector.exe`, built at 62eef2d, and is in Windscribe's split
tunnelling. **If the collector's code changes, build to the same path** (`source ix-tools/env.sh`, then from
`repo-archiver/archiver`: `go build -p 2 -o "$LOCALAPPDATA/tgarchive/bin/tgarchive-collector.exe"
./cmd/tgarchive-collector`); the Windscribe entry is by path and stays.

**Your piece: one small chat read for real (A2).** The owner is at the PC whenever asked. In order:
1. Read the code named above and tell the owner beforehand, in plain words, what `run` will send on its
   own once started (the sign-in report says a started collector reads the chat list; what else: the
   library's own requests at connect, updates, topics) and what it will not do until a chat is approved.
   If `run` would start anything the owner has not agreed to for this step (downloads, reads of more than
   the one chat), say so and decide with the owner before it starts; a change to the code is a coder's job.
2. The owner runs, in their own PowerShell with Windscribe connected (the home address is read inside the
   command line and never seen):
   `& "$env:LOCALAPPDATA\tgarchive\bin\tgarchive-collector.exe" run -db "$env:LOCALAPPDATA\tgarchive\test\catalog\catalog.sqlite" -staging "$env:LOCALAPPDATA\tgarchive\test\staging" -vpn-adapter WindscribeOpenVPN -public-forbid (curl.exe -s https://api.ipify.org)`
   plus whatever flags the test library and "links off" need (read `run -h`). The owner pastes the output;
   it is fixed words and numbers.
3. The owner picks one small chat of the test account (say so: small, nothing private that matters) and
   approves it the way the app offers. The chat is read to its end.
4. Numbers, read from the catalogue read-only (`status`, and `c_tg_hourly` / `c_conn_hourly` by kind; never
   a name, text, id or link): messages read, with media, files recorded by server; requests by method;
   messages per request; seconds per request; waits stated and slept, with their lengths; connections lost.
   **The owner compares the message and media counts with the phone.** A difference is a finding, not noise.
5. **Look at the three counter oddities first** (the handoff: `answered` 0 for sign-in kinds, `migrations`
   0, `status` leaving sign-in requests out): A2's numbers come from the same tables.
6. Once, with nothing typed and nothing sent: the refusing side of the VPN check for real (for example
   `signin` on a new empty folder with Windscribe disconnected; the verdict is printed before any prompt;
   Ctrl-C at the phone prompt). Record the verdict's words. Ask the owner first: it means disconnecting the
   VPN, and the old app runs behind it. **If the old app would be touched in any way, do not do it.**
7. Recorded in the handoff; roadmap rows changed on evidence only; committed and pushed to `private`; a
   `START-SESSION-9.md` for A3. **Before A3 the "leave and count" counter must exist** (FEATURES section
   12, eleventh round): brief a coder for it in this session if A2 leaves time.

**The owner's decisions of 11-13 evening that A2 feeds (not built, not to be built before the first real
files download):** every visible chat read by default, the cost shown first; chats never downloaded read
too; kept current by the live monitor; read again for deletions and edits without excessive scanning. A2's
messages per request and waits per hour are the first real numbers for that cost: report them as such.

**Open points that touch this piece:** a client that never ends keeps its session file held (the account
then waits at "connecting" with one log line): if `run` sits at connecting, that is the first suspect. The
rest are in the handoff's list.

**Rules most often broken:** never touch the running old app or anything under `E:\T\` beyond what
`CLAUDE.md` allows; invented data only in tests; numbers only from real runs (never a name, text, id,
phone, code, password or address); **no step against Telegram on an account without the owner present**;
2 cores per agent unless the owner says there is headroom, one Go container at a time (`immich-ml` is the
owner's), never deliberate load, measure the PC yourself after starting agents; every agent keeps a
PROGRESS file; nothing new is built before the first real files download. Go is not on the PATH: `source
ix-tools/env.sh` in Git Bash first. Make an agent's copy by hand (`git worktree add --detach ../wt-<name>
HEAD` from `repo-archiver`). Every git command that makes a commit needs `-c user.name=Claude -c
user.email=noreply@anthropic.com`. The owner has limited attention: short reports, numbers first, plain
words, say what was not verified, and lead with what ran for real.

**The seventh session** ("START-SESSION-7.md") has nothing running and can be closed by the owner. Tell the
owner once you have taken over.
