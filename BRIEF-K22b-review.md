# Independent review of K22b, alerts away from the PC (Core, K-6, 2026-11-22)

You review `wip/core-alerts-away` at dec145e2 against K22's `wip/core-alerts` ecbecda0 in
`C:\Users\trabi\Claude\Projects\Telegram\repo-archiver\archiver`. You did not write it; find what is wrong. Read: the
brief `BRIEF-K22b-alerts-away.md` and `DESIGN-CORE-alerts.md` sections 3 and 5 in `C:\Users\trabi\Claude\Projects\Telegram`;
`archiver/docs/TRIED-BEFORE.md` sections 24 and 25 (the rules for anything that acts for the owner); the coder's report
`archiver/docs/progress/core-alerts-away-REPORT.md` (its six "brief against code" points); then the whole difference.
**This code writes to Telegram for the owner** (the bot's sends and answers; a click on the archived account for Saved
Messages; the bot's `allow` acts on a blocked mirror) and holds a secret (the bot's token).

**Where:** a detached scratch copy: from `C:\Users\trabi\Claude\Projects\Telegram`,
`git -C repo-archiver worktree add --detach ../wt-core-alerts-away-review dec145e2`. Never edit the coder's copy or a
branch; never commit or push. Probes by `go test -overlay` (or uncommitted in the scratch copy). Every go command
through `bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go2.sh <folder> ...`. Named tests only; never the
whole `internal/collector` or `internal/catalog`; no Docker. Invented data and the local fake Bot API only; never the
real Bot API; never touch a running program, `C:\Users\trabi\tgarchive-app` or `E:\`.

**Look hardest at:**
1. **Only the owner acts:** a command from any other user id, a forwarded or edited message, a message in a group the
   bot was added to, a `/start` without the nonce or with an old one, a replayed update id across a restart, a command
   older than 10 minutes, `allow <code>` with a wrong code, a code of an alert already seen or ended, `yes <code>` late
   or twice, two `allow`s for one code. Nothing acted on that the design does not list; free text answers only the list.
2. **The token:** never in a log line, an error's words, a door's answer, the catalogue, a backup, a crash log or the
   status file; the file's permissions; a token rejected by `getMe` is never written; clearing the bot removes it.
3. **Telegram's rules:** every 429 `retry_after` (and a FLOOD_WAIT on the Saved Messages click) slept in full and
   stored; the cap of 20 sends an hour; the resend every 12 h only while unseen and not ended; the VPN check asked
   before every Bot API request, a refusal sending nothing; only `https://api.telegram.org`, no proxy from the
   environment; the long poll never tight-looping on an error.
4. **Saved Messages (C):** through the owner's click path with `made_by = 'alerts'`: the click path's guards unweakened
   (the cap, frozen, signed out, the key); a send queued before a kill never queued twice; an alert about the very
   account that cannot send goes by the bot only. `c_act.made_by` is a column on the client track's table: does
   anything that reads `c_act` (the pages' and viewer's doors, the settle) misread an alert's click as the owner's?
5. **The record:** `c_alert_sent` remade over K22's (empty) form: the step on a catalogue where it holds rows
   (it should be empty: say what happens if not); `c_alert.code` unique, short, not guessable from the id.
6. **Concurrency:** the two new tasks ("alert sends", "alert bot") against the alerts task and the doors: data races by
   reading (say what you would run under the race detector).
7. Privacy: alerts' words fixed, numbers only; chat names only with the setting on; never message text.

**Report:** `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-K22b-alerts-away.md`: verdict first ("may be listed", "may
be listed after these fixes: ...", or "not to be listed"), then each finding with must / should / minor, CONFIRMED (a
probe shows it) or PLAUSIBLE, file and line, a one-sentence fix; the probes and their results. Your last message: the
same, short. Then remove your scratch copy (`git -C repo-archiver worktree remove --force ../wt-core-alerts-away-review`).
