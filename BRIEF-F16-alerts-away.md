# Brief F16: alerts away from the PC, in Settings and in the chat (UI track, session U-1, 11-22)

You are an Opus coder for the UI track of a private Go project (a Telegram archiver for Windows; a WebView2 window over the
collector's pages, `internal/server`, and the viewer, `internal/viewer`; one frame `internal/appshell` with its control set,
side sheet and `AppShell.ask`; Settings in one module per section). Work ONLY in your copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-ui-f16` (branch `wip/ui-alertsaway`, cut from F15 `wip/ui-nasgive` b9766541).
First merge pages' AW `private/wip/pages-alertsaway` 5a879e87 (it holds Core's K22b and AL) and the viewer's ACv
`private/wip/b-alertclicks` b4d22edc. Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each
message ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `git push private wip/ui-alertsaway`.

## Rules (binding)
The "Rules" section of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-F1-one-frame.md` binds you word for word (invented data
only; the owner's real window is open: never a screen screenshot, never computer-use; pictures only of your own try window
with `runs-ui-1\shot.ps1`; Go through `ix-tools/env-archiver.sh`, one command at a time, named tests only; **nothing against
Telegram: never enter a real bot token, never press a test send against anything real**; TEMP/TMP outside the project
folder). Try ports 18926-18929. Before pushing, by name: server `-run 'TestAssets|Security|TestEmptyCatalogue'`, viewer
`-run 'TestWall|TestHomeDevice|TestLAN|Security'`. Every asset under 600 lines. Another coder (F16a, `wt-ui-f16a`) fixes the
viewer pages' list counts and Choose chats' marks: do not touch those. The bot token is a secret of the owner's: the field is
write-only (type password, never pre-filled, never echoed, never put in the address, in storage, in a log or a picture);
after a save the page shows only the bot's username and its Start link.

## The doors (pages' AW; shapes in its `archiver/docs/progress/pages-alertsaway-REPORT.md`)
/api/settings `alerts_away`: resend_hours, sends_per_hour (title "Requests to send alerts an hour at most"), names: each
{title, value, default, min, max, words, cost, when, route}; unreadable, asked_last_hour; bot {token_set, chat_set,
start_waiting, start_at, start_expired, unreadable, refused, wait_until?, username?, link?, words[], token_words/route,
find_words/route, clear_words/route, test_words/route}; saved {account (0 off), unreadable, wait_until?, words[], note, cost,
when, route, test_words, test_route}; `alerts_away_why` when absent. POST /api/settings/alert-resend-hours {"n"},
alert-sends-per-hour {"n"}, alert-names {"on"}, alert-saved-account {"account"} → {alerts_away, note, when}. POST
/api/alerts/bot/token {"token"} → {username, link}; /bot/find {} → {found, words}; /bot/clear {} → {cleared, words};
/away/test {"channel":"bot"|"saved"} → {outcome, until?}; the cap's 409 {error, until, asked_last_hour, sends_per_hour}.
Records: GET /api/alerts/{id}/sends, /api/alerts/away/hours?from=, /api/alerts/bot/actions?limit=, /api/alerts/bot/strangers.
The viewer's ACv: in GET /api/act/chat/{id} each `clicks[]` entry may carry `made_by: "alerts"`; then `can` is [] (only
["cancel"] while queued), no `in_chat` hint, and again/verdict/not-arrived answer 400.

## The goal
1. **Settings › Alerts away** (a new section module, beside Alerts): the bot as a small step card: not set → a token field
   (write-only) and Save, its words first; set → the bot's username, the one-time Start link with "works once, for an hour"
   (start_expired says so and offers to make a new one by saving the token again), "Find the chat" after the owner pressed Start,
   "Remove the bot" behind a confirm; refused/wait shown in words. Saved Messages: a select of the accounts (Off = 0) with its
   cost said first. Resend hours, requests per hour, names on/off as F10 rows. "Send a test" per channel with its test words in a
   confirm; the cap's 409 says until when. A "Sent" record: the last hours and the bot's actions as a short list (strangers who
   wrote to the bot shown as a count and a list, never their messages).
2. **The alerts' own sends** on the Alerts place: each alert's sends (channel, when, outcome) in its row's details.
3. **The chat box:** a click made_by "alerts" in Saved Messages is drawn as the app's alert (a small "from the app" mark, the
   alert's icon), with no send-again, no verdict, no not-arrived buttons; only Cancel while it is queued.

## Done means
- Named tests: the section's rows and their POSTs; the token field never echoed (the page's DOM, storage and address hold no
  token after a save: a test checks); the Start link's expiry; the confirms; the 409; the chat box's made_by rendering (no
  buttons but Cancel while queued); the security sets; appshell whole; gofmt, vet.
- Pictures (your real try window, invented data and the demo's doors; a typed fake token only): Settings › Alerts away (bot not
  set, bot set with its Start link), the test's confirm, Saved Messages with an alert from the app. In
  `runs-ui-1/f16-pictures/`, for U-1's check.
- Report: branch head, files, tests with times, pictures, what is not done (under 20 lines). Close your programs.
