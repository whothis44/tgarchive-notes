# Start of the fifth archiver session (written by the fourth session, 2026-11-13 11:05)

Paste into a new session in this project folder (Fable 5.2, medium effort):

> Read `START-SESSION-5.md` in this folder and do what it says.

## For the new session

Continue the standalone Telegram archiver as its fifth main session. You are the architect and the judge:
you write briefs, read what was tried before and the risky part of each change, judge reports, decide with
the owner. Opus 5.5 at high effort codes, in its own copy of the repository. A Sonnet clerk does the
mechanical steps on your exact written instructions. One landed piece, then hand over to a fresh session.

**Read first, yourself and in full:**
1. `CLAUDE.md` in this folder (its archiver section was extended on 11-13).
2. The block **"CURRENT STATE (11-13, 11:05 by the clock). THE FIFTH SESSION STARTS HERE"** at the top of
   section 0c of `repo-archiver/archiver/docs/HANDOFF.md`. Stop where it says the block below is superseded.
3. `repo-archiver/archiver/docs/TRIED-BEFORE.md`, all 24 sections.
4. `repo-archiver/archiver/docs/FEATURES.md` section 12.
Your memory files apply: `archiver-working-mode`, `archiver-session-start`, `agent-load-limits`,
`fork-session-contact`, `check-tried-before`.

**Then** tell the owner in a few lines what you read in full and what you did not, and what you start.

**Your piece: the Go library upgrade** (the handoff block, "what stands between now and the test sign-in",
point 1). Read the library's diff of `telegram/updates`, `session` and the request resend path yourself
before briefing anyone. Done means: the four questions in the handoff answered with tests; the whole suite
on Windows; the race detector once on `internal/telegram` and `internal/collector/...` (about 40 minutes
for the collector: tell the owner before starting it); committed and pushed to `private`; the handoff's
CURRENT STATE block rewritten short; a `START-SESSION-6.md` for the next piece (the real dialer's test).

**Not your piece, but know it:** the byte-path challenger has reported and its report is in the checkout
(`archiver/docs/review/bytepath-2-2026-11-13.md`, commit ca1fd11; the handoff block has the verdict): no
blocker, ready for a test library folder with a staging folder of its own, four should-fix findings before
the real library. Its fixes are a later piece; its copy `wt-bytepath2` stays until then. No agent of the
fourth session is running any more.

**Rules most often broken:** never touch the running old app or anything under `E:\T\` beyond what
`CLAUDE.md` allows; invented data only; nothing against Telegram except no-account connections at your own
judgment, sparingly, each recorded in the handoff; no sign-in step without the owner present; 2 cores per
agent, one Go container at a time at `--cpus 1.5` (a container named `immich-ml` is the owner's), never
deliberate load, measure the PC yourself after starting agents; every agent keeps a PROGRESS file; tell the
owner what a long run costs before it starts; nothing new is built before the first real files download.
The owner has limited attention: short reports, numbers first, plain words, say what was not verified, and
lead with what ran for real.

**The fourth session** ("Read START-SESSION-4.md…") has nothing running and can be closed by the owner.
Tell the owner once you have taken over.
