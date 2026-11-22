# Review AW: alerts away on the pages (independent, P7, 2026-11-22)

Read: `git diff 5296bf06 0fabf04d` in full (server `alertsaway.go`, `demo_alertsaway.go`, `alertsaway_test.go`, the
`server.go` / `settings.go` / `security_test.go` changes; livepages `alertsaway.go`; collector `pages_alertsaway.go`,
its test, the `pages.go` line), and Core's doors they call (collector `alertaway.go`, `alertbot.go`, `botapi/botapi.go`,
`doorErr`), the guard, `readJSON`, `fail`, `errClass`, `logOnce`, the held stop (`stopheld.go`), `FixedErrorLog`.
Ran (all through `runs-pages-p6/go1.sh`, TEMP/TMP/LOCALAPPDATA/APPDATA in `p7-awrev`, fakes and an invented token only):
uncommitted probes `internal/server/zz_probe_aw_test.go` (3 tests) and `internal/collector/zz_probe_aw_test.go`
(1 test: the pages over Core's real doors on the fake Bot API), and the coder's named tests `TestAway*`, the guard's and the held stop's tests, `TestPagesAwayThroughTheSeam`, `TestAwayTokenNeverShown`: both packages ok.
Line numbers are on 0fabf04d (`wip/pages-alertsaway`): the piece is NOT on the main head af4ca40e (its files do not
exist there), so it is not yet in the program the owner runs.

## Findings

1. **SHOULD FIX: the cap's refusal and a test that meets a stated wait carry no end time.** Confirmed:
   `TestZZProbeAwayCapWaitRemake` over the real doors: with the cap at 1, the second test answers
   `409 {"error":"The cap of alerts sent an hour is reached: nothing was asked.","until":0}`; a test whose send
   Telegram answers 429 (retry 300 s) answers `200 {"outcome":"not sent: a wait Telegram stated"}` with no end; only
   the NEXT press gets `409 ... "until": <now+300>`. Brief Q2 asks ErrAwayWait and ErrAwayCap in fixed words with the
   end time. Where: `internal/collector/pages_alertsaway.go:48` (only ErrAwayWait / ErrBotWait get `Until`);
   `internal/server/alertsaway.go:423-429` (the outcome is passed as it is). A person: presses "Send a test" at the
   cap and is told it is reached, not when it opens (the cap is a rolling hour, so it is not "the next hour"
   either); presses it when Telegram states a wait and is told "a wait Telegram stated" with no time, and must press
   again (asking nothing, but still a click) to learn the end. Cure: in `handleAwayTest`, when the outcome is the
   wait's, read `Facts` once and add `"until"` (the channel's wait end) to the 200 answer; for the cap, the end is the
   oldest counted send of the last hour plus one hour: a small door of Core's (or a field in `AlertAwayFacts`) is
   needed; until it exists, words that say it is a rolling hour and give `asked_last_hour` of `sends_per_hour`.

2. **SHOULD FIX: the start link's words point at a link that is not shown (after the pages are made again) or that
   no longer works (after an hour).** Confirmed: `TestZZProbeAwayStartAfterRemake` (server) and
   `TestZZProbeAwayCapWaitRemake` (real doors): after a paste, a second server on the same doors answers
   `start_waiting: true`, no `link`, no `username`, and the words "The token is set: press Start in the bot from the
   link, then Find the chat."; two hours after the paste, the first server still shows the link and the same words,
   and Find then answers 409 "The start link is older than an hour: make a new link (set the token again)."
   Where: `internal/server/alertsaway.go:241-242` and `251-257` (the link kept in memory only); Core's facts
   (`alertaway.go:554-556`) say a start waits whenever `alert.bot.start` exists and no chat is set, with no age. A
   person: pastes the token, the program is restarted (or the pages are made again) before they press Start; the
   Settings page tells them to press Start "from the link" and shows none. Or they come back after an hour, press
   Start in Telegram from the old link, press Find, and only then learn to paste again. Cure: when a start waits and
   no link is kept, say "The start link is not kept across a restart: paste the token again for a new link (one
   request)"; and have Core's facts carry the start's time (or say expired) so the pages drop the link and say so
   after `botStartFor`.

3. **MINOR: the routes other than the token's own give a door's error text in the answer.** Confirmed:
   `TestZZProbeAwayDoorErrorEcho` with a door failing with an error that holds an invented token:
   `POST /api/alerts/away/test`, `POST /api/settings/alert-names`, `GET /api/alerts/1/sends`,
   `GET /api/alerts/away/hours`, `GET /api/alerts/bot/actions` all answer 500 with the token in the body
   ("the catalogue could not do that: " + `err.Error()`, `fail` in `server.go:630-648`, reached from
   `awayRefused(..., false)` at `alertsaway.go:425, 450, 472, 500` and `awaySet` at `:327`); the log holds only the
   class. Not reachable with Core's doors as they are (botapi never returns a URL or the token; `SendAlertTest`
   drops `botToken`'s error), so no person meets it today; but the bot's test is the one other route that uses the
   token, and its failure words ("the catalogue could not do that") are also wrong for a send. Cure: pass
   `secret=true` in `handleAwayTest` (fixed words, class in the log), as the token, Find and Clear routes do.

4. **MINOR: words not quite true of Core's code** (by reading, one confirmed):
   - `AwayTestSavedWords` (`alertsaway.go:110`) "Sends one message to your Saved Messages now": Core queues a click
     of the account (`alertaway.go:478`, outcome "queued in the clicks of the account"); the click path sends it at
     its own pace and waits. Say "queues one message ... (sent by the clicks' path at its pace)".
   - `AwayTokenWords` (`:112`) "sends one message per alert": an unseen alert is sent again every
     `resend_hours`, and every command of the owner is answered with a message; those answers
     (`alertbot.go:504`) are not counted in the cap (only `sendLocked` records), while the cap's title
     (`:210`) is "Messages an hour at most". Say "requests to send alerts an hour at most; the answers to your
     commands are not counted".
   - `AwayCostPerHour` (`:122`) "over the cap the rest wait for the next hour": the cap is a rolling hour
     (`AlertAskedSince(now-1h)`, `alertaway.go:372`).
   - The bound: a value over 2^40 is refused with "a whole number, 1 or more" (confirmed: the probe's
     `n = 2^41` answers that; Core `alertaway.go:585`). Core's words; say the bound or drop it.
   - With the token refused by Telegram, the bot's test answers "That channel is not set." (Core
     `alertaway.go:637`) while the Settings answer says "Telegram refused the bot's token".

5. **MINOR: the kept link can be cleared by a Settings read that runs beside the paste** (by reading).
   `awayView` (`alertsaway.go:251-257`) clears `awayStart` whenever the facts it read say no start waits; a
   `GET /api/settings` whose `Facts` ran before the door stored `alert.bot.start` but which takes `awayStart.mu`
   after `handleBotToken` stored the answer (`:375-377`) clears the new link. A person: the page reloads Settings
   while the paste is in flight; the link is in the POST's answer but missing from the next Settings answer (then
   the same dead end as finding 2). Cure: clear only on Find's and Clear's success and on a new paste (not on a read),
   or keep a generation number taken before `Facts`.

6. **MINOR: tidy.** The demo/test fake's `FindBotChat` reads `a.f.BotStartWaiting` outside its lock
   (`demo_alertsaway.go:120`); `count`'s `field` parameter is unused (`alertsaway.go:529`, "n" passed literally);
   the comment on `routeWriter` ("no route has an id in its path") is no longer true with `/api/alerts/{id}/sends`
   (harmless: the log uses the pattern).

## Checked and sound

- The token's body: own reader, 512 bytes, exactly `{"token": "<string>"}`; the token as a field name, an unquoted
  token, a broken body, an extra field, a null, an over-long body: fixed words, no decoder text (read, and the
  coder's `TestAwayTokenWriteOnly`).
- The token's answer is `{username, link}` only; the link holds a nonce, no token; refusals in sentinel words;
  failures in fixed words with the error's `%T` class only in the log (`errClass`).
- Core's botapi never puts a URL, the token or Telegram's description in an error (`botapi.go:183-217`); the token
  file's read error is dropped in `SendAlertTest` and fixed-worded on the token/Find routes.
- Over the real doors on the fake Bot API, every answer and both logs were free of the token's secret part
  (probe: "logs hold the token: false false").
- A panic: the program's `http.Server.ErrorLog` is `FixedErrorLog` (one fixed line), and no recover logs a value.
- The guard: every POST needs the page token, a same-origin `Sec-Fetch-Site`, an `Origin` of this host and a known
  `Host` (DNS rebinding refused); a cross-site GET of the records or the Settings answer is refused before any
  handler. The eight POSTs are in `mutating` and `programOnly`; the held stop refuses all eight (409, no door call);
  the demo refuses every POST.
- No GET sends: Facts, Sends, Hours, BotActions, BotStrangers only read; HEAD follows GET.
- A test at the cap or inside a stated wait asks nothing (probe: 2 sendMessage calls for 4 presses: the sent one and
  the one Telegram answered 429).
- The records: `arg` is only a code, a number or "all" (Core validates it before recording); a stranger's message is
  never recorded, only counted (`/strangers` is a number); outcomes and `why` are fixed words; the Saved account is
  the catalogue's number. Nothing in the pages logs a record.
- Settings bounds: `n` must be present and whole; 0 and negatives get Core's words beside the field; the Saved account
  refuses negatives before the door and unknown accounts at the door. `AwayWhen` (30 s look) matches
  `alertSendEvery`; the poll's "about 70 an hour" matches a 50 s hold plus a 1 s gap.
- `made_by`: `/api/act/state` carries no click rows (read), so nothing to keep there; the viewer owns it.

## Not verified

- The real Bot API, a real account, the Saved Messages' test end to end (the fake rig stops at the ledger).
- The page side (U-1 draws it): what the window shows, and whether a double click sends twice (each press is one
  send on the Go side, serialised by Core's lock and counted in the cap).
- With the real program in a real window.
