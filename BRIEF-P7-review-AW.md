# Brief: the independent review of AW, alerts away on the pages (pages, P7, 2026-11-22)

Read first: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-P7-review-rules.md` (binding). TEMP, TMP, LOCALAPPDATA,
APPDATA of test processes in `C:\Users\trabi\AppData\Local\Temp\p7-awrev\` (outside any git copy). Fakes only: nothing
reaches Telegram or the Bot API.

**The piece:** `wip/pages-alertsaway` 0fabf04d (from Core's K22b `wip/core-alerts-away` 5296bf06 with the pages' AL merged
in): `git diff 5296bf06 0fabf04d`. The ask: `BRIEF-AW-alerts-away.md`; the report:
`archiver/docs/progress/pages-alertsaway-REPORT.md`; the doors: Core's K22b files in `internal/collector`. **It takes the
owner's bot token and sends messages for the owner (a test to the bot chat, a test to Saved Messages). Find any way the
token is echoed, logged, kept, cached, put in an error word or a panic; any way a send happens without the owner's click
or from elsewhere (a cross-site POST, a replay, a held stop); any wait or cap not said; any record leaking a name, text or
id the privacy rules forbid.** Your copy:
`git -C C:\Users\trabi\Claude\Projects\Telegram\repo-archiver worktree add --detach ../wt-pages-review-aw-scratch 0fabf04d`.
Report to `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-AW-alerts-away.md`. Within about an hour.

## Questions
1. The token: every path from the body to the door and back (the reader, the answer, logs, the kept start state, errors,
   the demo, the adapter); a probe that posts an invented token and greps every output, including Go's own error texts.
2. The sends: the guard (same-origin, token, held stop) on the eight POSTs; the test's words before the click; ErrAwayWait
   and ErrAwayCap in fixed words with the end time; no send from a GET.
3. The records' answers: what of a bot action's `arg` or a stranger is shown (a stranger's name or id must not be
   printed by any log; in an answer to the owner's own page, is it needed?).
4. The settings: bounds and words true of Core's code.
5. Anything else: its own number.
