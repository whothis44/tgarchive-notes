# Brief K22b: alerts sent away from the PC: a bot of the owner's, and the account's Saved Messages (Core, K-6, 2026-11-21)

**The owner's decision (board item 42, 11-21, before 22:50 (the minute was not taken from the clock)): "A and C"**, both: (A) a Telegram bot the owner makes and
(C) the archived account's own Saved Messages. Read `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-CORE-alerts.md`
section 3 (the common rules) and K22's report on `wip/core-alerts` (the record `c_alert`, the empty
`c_alert_sent` table made for this piece, the doors). **This piece writes to Telegram for the owner: one
independent review follows it.** Cut from K22's final head (named when you start); same rules, lock and commit
form as K22's brief; branch `wip/core-alerts-away`, copy `wt-core-alerts-away`.

## Common to both channels
- Each channel is **off until the owner sets it** (stored settings; doors for pages: read, set, "send a test
  alert through this channel"). Nothing is sent by a build that has no setting.
- An alert is sent once when raised, again every 12 h while it lasts and is unseen (a setting, default 12 h, no
  upper bound of the app's own); an alert seen or ended is never sent again. At most 20 sends an hour in all (a
  setting, the same rule). Per alert and channel the outcome goes into `c_alert_sent` (sent at, tries, the last
  refusal as a fixed word), so a restart never sends twice and a failure is visible to the page.
- **The words:** fixed words and numbers only, a short fixed prefix naming the app; **no chat name** unless the
  owner's setting "names in messages" is on (default off; then the chat's name from the catalogue, never
  message text). Never a path, id or link.
- A refusal's stated wait (FLOOD_WAIT, a bot API 429 with `retry_after`) is slept in full before that channel
  asks again; stored, so a restart keeps it (TRIED-BEFORE rule 4). A failed send is tried again later (1, 5, 15,
  60 minutes), never in a loop.
- Every send counted per channel and hour; one constant log line per send outcome (kind as a fixed word,
  account number only).

## A. The owner's bot (Telegram's Bot API over HTTPS)
- The owner pastes the bot's token on the Settings page (a write-only door). **The token is a secret:** kept in
  a file of its own in the data folder beside the session files' key (owner-only file permissions), never in the
  catalogue, never logged, never answered back by any door (a door says only "set" or "not set"), not in
  backups unless the session files are (say what `internal/backup` copies).
- Set-up: `getMe` (checks the token) and `getUpdates` (finds the one private chat that pressed Start; if none or
  more than one, the door says so in fixed words and stores nothing); the chat id stored. Then `sendMessage` per
  alert. Two requests at set-up, one per alert.
- **Through the VPN:** the same gate the collector asks before any Telegram connection (find it: `gate.go`,
  the VPN check); refused: not sent, tried later, counted. A plain HTTP client with a timeout; no proxy from the
  environment; only `https://api.telegram.org`.
- Works whatever the archived account's state (frozen, signed out): it does not use the account.

## A2. Two-way: the owner answers the bot (the owner, 11-22 01:20; `DESIGN-CORE-alerts.md` section 5)
Build section 5 exactly: the bot's `getUpdates` as a long poll (timeout 50 s, through the VPN check, only while the bot
is set); only the owner's user id (recorded at the first Start from the Settings link; any other sender ignored,
counted, never answered); a command older than 10 minutes refused as stale; each update id acted on once ever (a
table, so a restart never repeats one); the five commands of the table and nothing else (free text gets the list);
each alert's short code (a few characters, unique among open alerts, not guessable from its id); `allow <code>` only
after the owner's `yes <code>` within 10 minutes; every action recorded (command, time, outcome) and answered in fixed
words; the bot never ends an owner's pause except by `resume`. Use the existing doors (`Collector.PauseDownloads`, the
mirror's `Collector.MirrorAllow`, the alert record's see doors, the Overview's totals); do not edit the mirror's files.
Tests (local fake Bot API): a stranger's command ignored and counted; a stale command refused; a repeated update not
acted twice across a restart; `allow` without `yes`, with a wrong code, with a late `yes`: nothing done; `pause 3`
then `resume`; free text answers the list; the poll stops when the bot is unset. Record the owner's words of 01:20 in
`archiver/docs/FEATURES.md` section 12 with this piece.

## C. The account's own Saved Messages
- The send goes through **the existing request layer and ledger for the owner's clicks** (`internal/telegram`
  `act.go` `ActSend`, the collector's click path `click.go`, the ledger `c_act`, the cap and the frozen checks),
  as an act written down before it is sent, with a new fixed "by" word for the app's alerts so the ledger tells
  them from the owner's own clicks. Find the place; if the click path cannot take an act that is not the
  owner's without weakening a guard, stop and say so.
- Which account: a setting naming one account (default none: off). Its chat: `catalog.SelfChat`. A frozen,
  signed-out or not-signed-in account: nothing sent, the outcome "not sent: the account cannot send" recorded,
  no request. An alert about that very account cannot go this way: it goes by the bot only (say so on the page).
- Say in the report: whether the reader then reads these messages back into the archive (the own chat is read by
  itself since K21) and how the viewer can tell them (the ledger's message ids); do not change the reader or the
  viewer.

## Tests (each seen failing first; the fake Telegram and a local fake of the Bot API: never the real one)
Off by default sends nothing; a raise sends once on each set channel, again after 12 h unseen, never after
seen or ended; a restart does not send twice; the cap of 20 an hour; a stated wait slept and stored; a refused
VPN gate sends nothing; the token never in a log line, a door's answer or the catalogue; `getUpdates` with zero
or two chats refuses; C on a frozen account sends nothing and records why; C's act is in the ledger with the
app's "by" word; names off by default. Named tests only, through the lock; gofmt, build, vet the changed
packages; the viewer's `TestWall`.

## Hand back
`archiver/docs/progress/core-alerts-away-REPORT.md` and your last message, short: head pushed; the doors for
pages with exact names; where the token lives; the requests each channel makes; tests as run; what the code
contradicts in this brief.
