# Start of the sixth archiver session (written by the fifth session, 2026-11-13 12:50)

Paste into a new session in this project folder (Fable 5.2, medium effort):

> Read `START-SESSION-6.md` in this folder and do what it says.

## For the new session

Continue the standalone Telegram archiver as its sixth main session. You are the architect and the judge:
you write briefs, read what was tried before and the risky part of each change, judge reports, decide with
the owner. Opus 5.5 at high effort codes, in its own copy of the repository. A Sonnet clerk does the
mechanical steps on your exact written instructions. One landed piece, then hand over to a fresh session.

**Read first, yourself and in full:**
1. `CLAUDE.md` in this folder.
2. The block **"CURRENT STATE (11-13, 12:50 by the clock). THE SIXTH SESSION STARTS HERE"** at the top of
   section 0c of `repo-archiver/archiver/docs/HANDOFF.md`. Stop where it says the block below is superseded.
3. `repo-archiver/archiver/docs/TRIED-BEFORE.md`, all 24 sections.
4. `repo-archiver/archiver/docs/FEATURES.md` section 12.
5. `repo-archiver/archiver/docs/progress/gotd-REPORT.md` (the library upgrade: what the library now does by
   itself, and its open points).
Your memory files apply: `archiver-working-mode`, `archiver-session-start`, `agent-load-limits`,
`fork-session-contact`, `check-tried-before`.

**Then** tell the owner in a few lines what you read in full and what you did not, and what you start.

**Your piece: the test of the real dialer** (the handoff block, "what stands between now and the test
sign-in", point 2). `collector.LibraryDialer` is used by no test and has never run. Read
`internal/collector/dialer.go`, `seam/seam.go`, `internal/telegram/connect.go` and `vpn.go` yourself before
briefing anyone. Done means:
- the dialer run against the library's loopback server (`github.com/gotd/td/tgtest`, 127.0.0.1 only; the
  fifth session's `internal/telegram/gotd166_loopback_test.go` shows how, with a dialer that refuses every
  other address): connect, the VPN gate asked before every dial, a request answered, a dropped connection
  redialled, a clean stop;
- **the session file has one writer:** show that the sign-in's client and the account's client can never
  be open on one session file at once (`collector/signin.go:79`, `collector/account.go:348`); two writers
  lose saves (the upgrade's report, Q4);
- then **one real connection through the dialer with no account** (the owner's standing permission:
  FEATURES section 12, ninth round; sparingly), its numbers recorded in the handoff;
- the whole suite on Windows; the race detector on the packages touched (the collector's race run is about
  40 minutes at 1.5 cores including the compile: tell the owner before it starts);
- committed and pushed to `private`; the handoff's CURRENT STATE block rewritten short; a
  `START-SESSION-7.md` for the next piece (build `tgarchive-collector.exe` to its fixed path and tell the
  owner to add it to Windscribe's split tunnelling, then the sign-in with the owner present).

**A decision to put to the owner in the same turn as your first report (small, one question):** the
upgrade proved that the library sends a pending request again by itself when its connection dies, below
our wait check. It is closed for live updates. It is open for file-reference refreshes, part hashes, the
authorisation transfer and the forwarder (two requests of one kind can be in flight). It matters from the
first download (step 3), not for sign-in or reading a chat. The choice: one request in flight per kind
(slower refreshes, nothing can arrive inside a wait), or leave it and count what the library sends again.
Give your recommendation with it.

**Not your piece, but know it:** the byte path's four should-fix findings
(`archiver/docs/review/bytepath-2-2026-11-13.md`) are a later piece, before anything is written to the real
library; the reviewer's copy `wt-bytepath2` stays until then. `gofmt -l .` lists
`internal/bringin/verify.go`: a one-line job for your clerk.

**Rules most often broken:** never touch the running old app or anything under `E:\T\` beyond what
`CLAUDE.md` allows; invented data only; nothing against Telegram except no-account connections at your own
judgment, sparingly, each recorded in the handoff; no sign-in step without the owner present; 2 cores per
agent, one Go container at a time at `--cpus 1.5` (a container named `immich-ml` is the owner's), never
deliberate load, measure the PC yourself after starting agents; every agent keeps a PROGRESS file; tell the
owner what a long run costs before it starts; nothing new is built before the first real files download.
Go is not on the PATH: `source ix-tools/env.sh` in Git Bash first. Make an agent's copy by hand
(`git worktree add --detach ../wt-<name> HEAD` from `repo-archiver`). The owner has limited attention:
short reports, numbers first, plain words, say what was not verified, and lead with what ran for real.

**The fifth session** ("Read START-SESSION-5.md…") has nothing running and can be closed by the owner.
Tell the owner once you have taken over.
