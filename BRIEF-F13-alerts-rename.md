# Brief F13: alerts in the app, and renaming a mirror (UI track, session U-1, 11-22)

You are an Opus coder for the UI track of a private Go project (a Telegram archiver for Windows; a WebView2 window over the
collector's pages, `internal/server`, and the viewer, `internal/viewer`; one frame `internal/appshell` with its control set,
side sheet and `AppShell.ask`). Work ONLY in your copy `C:\Users\trabi\Claude\Projects\Telegram\wt-ui-f13` (branch
`wip/ui-alerts`, cut from UI-3 `wip/ui-qa2` 915686c1). First merge pages' `private/wip/pages-alerts` a2b6e93c (AL) and
`private/wip/pages-rename` 0a9674bf (RN); if either needs a branch of Core or the mirror track that is not on your tree (K22,
M19), merge what it holds and say so. Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each
message ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `git push private wip/ui-alerts`.

## Rules (binding)
The "Rules" section of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-F1-one-frame.md` binds you word for word (invented data
only; the owner's real window is open: never a screen screenshot, never computer-use; pictures only of your own try window
with `runs-ui-1\shot.ps1`; Go through `ix-tools/env-archiver.sh`, one command at a time, named tests only; nothing against
Telegram: never press Send a test or Rename against anything real; TEMP/TMP outside the project folder). Try ports 18876-18879.
A rename acts on Telegram: its words and cost are said before the click and one click is one request (the door's contract).

## The doors (pages' P7)
**Alerts (AL):** GET /api/alerts[?limit] {alerts: [{id, kind, account?, chat? (mirror.blocked: a /api/chats id), raised_at,
since_at?, last_at, ended_at?, seen_at?, ended, seen, times, words}], unseen, change, record: {failing, since?, words?},
can_write, words?, test_words}: poll `change` and fetch again when it moves; GET /api/alerts/history?before=&limit= {alerts,
before, change}; POST /api/alerts/seen {"id"} or {"all": true}; POST /api/alerts/test {}; /api/settings `alert_thresholds`
{kinds: [{kind, title, minutes, default, min, stored, unreadable, words}], when, cost, route} with POST
/api/settings/alert-threshold {"kind","minutes"}; /api/shell `counts["alerts"]` (unseen). Without the program: list, history
and change only; the writes answer 404.
**Rename (RN):** POST /api/mirrors/rename-plan {account, chat, title} → {account, chat, mirror_exists, mirror_chat,
mirror_state, current_name, name_len, name_limit (128), name_why, same_name, name_taken, wait_until, method, requests, cost,
sends, blocked, token (good for ONE click)}; POST /api/mirrors/rename {account, chat, title, token} → 200 {words, result{outcome,
words, reason, requests, waits, waited_seconds, wait_until, recorded}}; 409 {error, moved: true, plan} for a used or stale
token (fetch a fresh plan to retry); 409 {error, moved: false, plan|result} when blocked or the account refuses; 502 {error,
result} when Telegram renamed it but the record failed; 400 {fields} for an empty, blank or too long title.

## The goal
1. **Alerts:** an "Alerts" entry in the list (appshell; its count = unseen, red when > 0); an Alerts place: unseen first, each in
   its words with when and how many times, a link to its place (a blocked mirror opens that chat's Mirror part), "Seen" per
   alert and "Mark all seen"; ended alerts quieter; history below ("Show older"). A quiet toast at the strip when `change` moves
   and a new unseen alert appears (never more than one toast at a time; never for one already seen). The Overview's Needs you
   gains "N alerts · Open". When the record is failing, a line says so with its words.
2. **Settings › Alerts:** each kind's threshold as a stepper (minutes, its min, default, words), saved on change; "Send a test"
   with `test_words` said before the click (a confirm). Without the program: the rows say so and are off.
3. **Rename a mirror:** in the chat's Mirror part (F11a's sheet) and on the Mirrors place's row: "Rename the mirror…" opens a
   step in the sheet: the current name, a title field (its limit counted), then "Check" asks the plan and shows it in words (the
   name's why, same or taken, any wait with its end time, the cost and what is sent); "Rename" sends once with the plan's token;
   a 409 moved fetches a fresh plan and says so; the result's words after. Settings' "Rename a mirror" Coming row goes.

## Done means
- Named tests: the list entry and count; the Alerts place (unseen first, seen, all seen, history paging, link to a blocked
  mirror's chat); the toast's rules; Settings' thresholds and the test's confirm; the rename steps (plan words, one POST with the
  token, 409 moved → fresh plan, 400 fields, 502 words); appshell whole; gofmt, vet.
- Pictures (your real try window, invented data and the demo's doors): the list with alerts, the Alerts place, a toast,
  Settings › Alerts, the rename step with its plan. In `runs-ui-1/f13-pictures/`, for U-1's check.
- Report: branch head, what you merged, files, tests with times, pictures, what is not done (under 25 lines). Close your programs.
