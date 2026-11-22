# Brief AL: the alerts on the pages (Go side) (pages, P7, 2026-11-22)

Same coder and rules as CS (go1.sh, named tests, TEMP etc. in `C:\Users\trabi\AppData\Local\Temp\p7-al\` outside any
git copy, Go only: the UI track (U-1) draws). Branch `wip/pages-alerts` cut from Core's `private/wip/core-alerts`
ecbecda0 (K22, listed, schema step 34; read its report and `DESIGN-CORE-alerts.md` in the project folder). Report:
`archiver/docs/progress/pages-alerts-REPORT.md`.

## The doors (Core's, on that branch)
`(*Collector).Alerts(ctx, limit)`, `AlertHistory(ctx, before, limit)`, `AlertChange(ctx)`, `SeeAlert(ctx, id)`,
`SeeAllAlerts(ctx)`, `AlertThresholds(ctx)` (Kind, Minutes, Default, Stored, Unreadable, Min), `SetAlertThreshold(ctx,
kind, minutes)` (refuses with `alert.ErrAfterRange`, `alert.ErrNoThreshold`, `alert.ErrStallAfterMin`),
`SendTestAlert(ctx)`, `AlertRecordFailing()` (Failing, Since); on a read-only handle `catalog.Alerts` and
`AlertChange` (`catalog.Alert` has SinceAt; for "mirror.blocked" `MirrorChat` names the chat).

## What to build
1. A seam `Alerts` in `internal/server` with plain types, the livepages adapter, and routes: `GET /api/alerts` (the
   unseen or not-ended ones, newest first, each with its fixed words, since, ended-by-itself-at, seen; the chat's id for
   mirror.blocked, resolvable against /api/chats; plus `change` and the record-failing state with fixed words);
   `GET /api/alerts/history?before=&limit=`; `POST /api/alerts/seen {id}` and `{all: true}`; the thresholds in the
   Settings answer (`alert_thresholds`: per kind minutes, default, stored, min, unreadable, words) and `POST
   /api/settings/alert-threshold {kind, minutes}`; `POST /api/alerts/test` (its words before the click: "one ended,
   unseen test alert; nothing leaves this PC"). Without the program: the read-only handle for the list and change,
   nothing that writes.
2. **The count of unseen alerts on the list:** `counts["alerts"]` in `internal/server/shell.go`'s counts func, from
   `AlertChange`-keyed memory (no read per /api/shell when the change number has not moved), and in MC's `/api/counts`
   if MC is on your base (it is not: say it as a one-line follow-up).
3. Same guard, held-stop refusal, route lists, the demo fake (every kind, ended and not, seen and not, the record
   failing), tests for each; gofmt, vet, named tests.
Hand back: head, the JSON shape for U-1 in a few lines, one line not verified. (The launcher's Windows notification for a
new alert is a later piece, with the tray icon.)
