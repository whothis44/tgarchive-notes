# Start of the fourth archiver session (written by the third session, 2026-11-13 08:40)

Paste into a new session in this project folder (Fable 5.2, medium effort, Remote Control as you like):

> Read `START-SESSION-4.md` in this folder and do what it says.

## For the new session

Continue the standalone Telegram archiver as its fourth main session. You are Fable orchestrating; Opus 5.5 at
high effort does the coding through agents; you read, brief, verify, commit and own the outcome.

**Read first, yourself and in full:**
1. `CLAUDE.md` in this folder.
2. The block **"CURRENT STATE (11-13, 08:36 by the clock). THE FOURTH SESSION STARTS HERE"** at the top of
   section 0c of `repo-archiver/archiver/docs/HANDOFF.md`. Stop where it says the block below is superseded:
   the rest of that file is the log, for details only.
3. `repo-archiver/archiver/docs/TRIED-BEFORE.md`, all of it.
4. `repo-archiver/archiver/docs/FEATURES.md` section 12 (the owner's decisions, ten rounds).
Your memory files apply: `agent-load-limits`, `archiver-working-mode`, `archiver-session-start`,
`fork-session-contact`, `check-tried-before`.

**Then** tell the owner briefly what you read in full and what you did not, the state in a few lines, and
what you will start. Work on the handoff's FIRST OBJECTIVE, in its order:
1. Understand the one request seen inside a stated wait for the update monitor
   (`repo-archiver/archiver/docs/progress/coll2-REPORT.md`, open point 1): read
   `internal/telegram/monitor.go` and the Go library's update manager yourself before briefing anyone.
   With it, the Telegram package's other open points: the refresh race, one wait key per Telegram method,
   and re-running the reviewer's mutant "waits of 2 s or less ignored" against the strict fake.
2. A sign-in command for the collector (none exists).
3. A test of the real dialer against a loopback stand-in.
4. A second independent challenger for the byte path as fixed (`internal/store`, `internal/storeledger`,
   the catalogue's v8 and v9 sides, the collector's wiring of them).
5. The collector built to `%LOCALAPPDATA%\tgarchive\bin\tgarchive-collector.exe`; tell the owner, who adds
   it to Windscribe's split tunnelling. Then the TEST account's sign-in with the owner present, one small
   approved chat, a test library folder, links off.

**Done means, for each piece:** a written brief with acceptance tests; an Opus agent in folders no other
agent is editing; verified by you (its tests re-run on Windows within the machine budget; the riskiest part
of its diff read; the commit message saying what you did not read); committed and pushed to the remote
`private`, branch `claude/charming-feynman-vm2xia`; the CURRENT STATE block of the handoff updated and pushed
after every piece, with times taken from `date`.

**Rules the handoff and memory spell out; the ones most often broken:** never touch the running old app or
anything under `E:\T\` beyond what `CLAUDE.md` allows; invented data only; nothing against Telegram except
no-account connections at your own judgment, sparingly, each recorded in the handoff; no sign-in step
without the owner present; 2 cores per agent, at most four agents on heavy tests, never deliberate load,
every heavy run named and counted, measure the machine yourself after each start; every agent keeps a
PROGRESS file; tell the owner before a long run what it costs in usage (the week stood at 68% at 08:10 on
11-13 and resets 11-14 15:00). The owner has limited attention: short reports, numbers first, plain words,
say what was not verified.

**The third session** ("Fable/Opus orchestration handoff") is still open. It can pass a question to one of
the night's agents as a last resort (it costs context twice: read `docs/progress/` and `docs/review/`
first). Once you have read the handoff, tell the owner to let it know you have taken over, or message it
yourself if you can see it, so it cancels its wake-up for 11-14 15:07.
