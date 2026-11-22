# Brief AW: alerts away from the PC on the pages (Go side) (pages, P7, 2026-11-22)

Same coder and rules as AL (go1.sh, named tests, TEMP etc. in `C:\Users\trabi\AppData\Local\Temp\p7-aw\` outside any
git copy, Go only: U-1 draws, fakes only). **These routes send to Telegram for the owner (a bot's message, a Saved
Messages message, the bot's token check): nothing is sent without the owner's click; the bot's token is WRITE-ONLY:
never echoed in any answer, logged, kept by the pages or put in an error word.** Branch `wip/pages-alertsaway` cut from
Core's `private/wip/core-alerts-away` 5296bf06 (K22b, listed), with your AL branch `private/wip/pages-alerts` merged in
(keep both sides). Report: `archiver/docs/progress/pages-alertsaway-REPORT.md`.

## The doors (package collector, on that branch)
Settings: `AlertAway(ctx) (AlertAwayFacts, error)` (with `AskedLastHour` and `BotRefused`), `SetAlertResendHours`,
`SetAlertSendsPerHour`, `SetAlertNames`. The bot: `SetAlertBotToken(ctx, token) (AlertBotStart{Username, Link}, error)`
(refusals incl. `ErrBotWait`, `ErrBotStartOld`), `FindAlertBotChat(ctx)` (`ErrBotNoChat`, `ErrBotManyChats`),
`ClearAlertBot(ctx)`. Saved Messages: `SetAlertSavedAccount(ctx, account)` (0 off). `SendAlertTest(ctx, channel)
(outcome string, error)` with `catalog.AlertChannelBot` / `AlertChannelSaved` (`ErrAwayWait` inside a stated wait,
`ErrAwayCap` at the cap). Records: `AlertSendsOf(ctx, alertID)`, `AlertSendHours(ctx, from)`, `AlertBotActions(ctx,
limit)`, `AlertBotStrangers()`. New kind `bot.refused`. For the chat box: `catalog.ActClick.MadeBy` ("owner"|"alerts").

## What to build
1. The seam methods, the livepages adapter, and in the Settings answer `alerts_away` {the facts with fixed words, each
   setting with words, cost, when, route; the bot's state (set or not, username, its start link, refused); the Saved
   Messages account (or off)}; routes: `POST /api/settings/alert-resend-hours`, `alert-sends-per-hour`, `alert-names`,
   `alert-saved-account`; `POST /api/alerts/bot/token {"token"}` (answers `{username, link}` only; the token in no
   answer, log or error; a body over a small limit refused), `POST /api/alerts/bot/find`, `POST /api/alerts/bot/clear`;
   `POST /api/alerts/away/test {"channel":"bot"|"saved"}` (words before the click: "one message to your bot chat /
   your Saved Messages"; every refusal in fixed words with the wait's end time); the records as GETs
   (`/api/alerts/{id}/sends`, `/api/alerts/away/hours?from=`, `/api/alerts/bot/actions`, `/api/alerts/bot/strangers`).
2. `bot.refused` words in the alerts' list; `made_by` kept in `/api/act/state`'s answer (read the door's click state).
3. The same guard, held-stop refusal, route lists, demo fake; tests for each, including one that posts a token and
   greps every answer and log line for it. gofmt, vet, named tests.
Hand back: head, the JSON shapes for U-1 in a few lines, one line not verified. One independent review follows.
