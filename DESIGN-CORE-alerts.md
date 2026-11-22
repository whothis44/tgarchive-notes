# Alerts: the app tells the owner when something needs a person (ROADMAP C7; Core, K-6, 11-21)

**Why now (the integrator I-6, 11-21):** the automatic mirror blocked a chat at 18:08 (a batch refused
MESSAGE_ID_INVALID, its message deleted at the source); nobody knew until the owner looked about three
hours later; 38 posts were lost meanwhile. The owner: it must work "when the owner is away from the
computer". The mirror fixes that block itself (M14). Alerts are the general cure.

**Who does what.** Core: what raises an alert, the record, sending it away from the PC. Pages: where it
shows (the one window's list, a count, "Seen", the settings row, the launcher's Windows notification).
Mirror: its block words (`c_mirror_want.block_why`, already fixed words). Viewer: nothing.

## What the old app did (ported, not written anew)
`wt-v12.31` `core-service/internal/app/ix_alerts.go` (269 lines): every minute it looks at a list of
conditions; each has a key; a key is sent once, then again after 24 h while it lasts ("once" keys never
again); destinations ntfy, Discord, JSON or email; never message text, group names only by a setting; a
test button. **The old archive's `ix_alerts` table holds 0 rows (counted read-only, 11-21): no
destination was ever set, so the old app never sent one.** So the conditions, keys and repeat are its
way; the record kept until seen is new (the old app kept only "sent at").

## 1. The record (piece K22, no owner's word needed: nothing leaves the PC)
- A schema step: table `c_alert`, one row per raised alert: kind (fixed word), key (the condition: kind,
  account, chat or mirror row), raised_at, last_at (still true at), ended_at (the condition gone; null
  while it lasts), seen_at (the owner's "Seen"; null until then), times (how often raised again), fixed
  words and numbers. One open row per key (a unique index on key where ended_at is null). An alert stays
  on the list **until the owner has seen it**, even after its condition ended ("ended 19:40 by itself").
  Seen and ended rows are kept 90 days, then removed.
- Doors for pages: the open-or-unseen list, a cheap change number (to poll), "Seen" for one or all,
  "Send a test alert". All by the catalogue's one writer (rule 11: one row per item).
- **Fail closed (rule 13):** a row that cannot be written is logged once and tried again at the next
  look; a condition that cannot be read is itself an alert ("the app cannot tell whether ..."), never "all
  is well".

## 2. What raises one (the collector's alerts task: every 30 s; memory and one catalogue query; no request)
| Kind | Condition (source in the code today) | Raised after |
|---|---|---|
| mirror.blocked | a chat's automatic mirror blocked until the owner looks (`c_mirror_want.block_at` set) | at once |
| account.frozen | `StateFrozen` | at once |
| account.signed_out | `StateSignedOut` (Telegram ended the session) | at once |
| account.vpn | `StateGateRefused`: the VPN check refuses | 15 min |
| account.retrying | `StateRetrying`: the connection fails | 30 min |
| library.away / library.full | `Copier.Away()` / `LibraryFull()` | 30 min |
| staging.away / staging.full | `Writer.StagingNow()` Away / Resting | 30 min |
| downloads.stalled | files wanted, downloads on and not paused, none finished for an hour (the old app's rule) | 1 h |
| backup.failed | the nightly backup failed its retries (with the timer, a later Core piece) | at once |

Each threshold is a stored setting with that default and no upper bound of the app's own (the owner's
rule on caps). The collector being dead cannot raise anything: the watchdog's side (crashes, a restart
refused, a hang) is a later piece, listed.

## 3. Reaching the owner away from the PC (piece K22b: THE OWNER'S CHOICE, item 42)
**Decided by the owner 11-21, before 22:50 (the minute was not taken from the clock): A and C, both** ("keeps it probably more secure"), with E at the PC.
Each channel is off until the owner sets it; a test button; at most 20 alerts sent an hour (rule 10); a
refusal's stated wait is slept in full; only fixed words and counts, no chat names unless a setting says
so (off by default); sent once when raised, again every 12 h while it lasts and is unseen (a setting).

| Channel | On the phone | Works when the account is frozen or signed out | Cost | Needs from the owner |
|---|---|---|---|---|
| **A. A bot of the owner's (recommended)** | a normal Telegram message with its notification | yes: it does not use the archived account | one HTTPS request to Telegram's bot servers per alert (none on the account's limits), two at setup (check the token, find the chat); sent through the VPN check like every Telegram request | make a bot once with @BotFather, paste its token on the Settings page, press Start in it |
| B. ntfy (the old app's code) | a push by the ntfy app | yes | one HTTPS request to ntfy.sh (or a small ntfy on the NAS, host mode) per alert | install the ntfy app, pick a topic name |
| C. The account's own Saved Messages | probably **no** notification (a message one's own account sends is silent; not checked) | **no** (the alerts that matter most cannot be sent) | one send on the archived account per alert, in its request layer | nothing |
| D. Email (the old app's code) | a mail | yes | one mail per alert | a mail server and its password stored |
| E. A Windows notification only | nothing (only at the PC) | yes | none | nothing |

**Recommended: A, with E always on at the PC (pages' launcher shows the record's new alerts).** B is a
small port of the old app's code and can come with A if the owner prefers it; C is not recommended; D only
if asked. The bot's token is a secret: kept in a file of its own beside the session files' key, never in
the catalogue, never printed, never on a page after it is saved.

## 5. Two-way: the owner answers the bot (the owner, 11-22 01:20; with K22b)
The owner: "If one of the options for the notifications/alerts is a bot, can we build in 2-way logic? the app reads
the reply/message from the owner and acts on it". Recommended as below; built with K22b unless the owner says otherwise.
- **How it reads:** the bot's own `getUpdates` as a long poll (one request held up to 50 s: about 70 requests an hour to
  Telegram's bot servers, none on the archived account), through the VPN check like every alert. Off unless the bot is set.
- **Only the owner:** the owner's Telegram user id, recorded when the owner first presses Start from the Settings
  page's link; every other sender ignored, counted, never answered. A command older than 10 minutes is refused as
  stale. Each update is acted on once ever (its update id recorded), so a restart never repeats a command.
- **The commands** (fixed words only; anything else is answered with this list):

| Command | What it does | Writes to Telegram with the account? | Confirm? |
|---|---|---|---|
| `status` | the Overview's few numbers: accounts and their state, files waiting, saved today, mirrors blocked, alerts open | no | no |
| `alerts` | the unseen alerts, each with its short code | no | no |
| `seen <code>`, `seen all` | marks alerts seen (as the page's "Seen") | no | no |
| `pause <hours>`, `resume` | pauses downloads for that long, or resumes (the owner's own pause, `PauseDownloads`) | no | no |
| `allow <code>` | "Allow again" on the blocked mirror the alert names (the page's door, `MirrorAllow`) | yes: the mirror forwards again | **yes**: the bot asks, the owner answers `yes <code>` within 10 minutes |

- **Every action recorded** (who, the command, the time, the outcome) and answered by the bot with what was done, in
  fixed words (TRIED-BEFORE 24 and 25: one row per item, fail closed, never undo a person's own pause). One `sendMessage`
  per answer. A paused account's pause is never ended by the bot unless the owner sends `resume`.
- Not in it: free text acted on, any command that deletes, reading the account's Saved Messages for replies.

## 4. Not in these pieces
The watchdog's own alerts; a "the PC is off" check from outside (a heartbeat to a service: needs the
owner's word); alerts for the old app (it keeps running as it is).
