# Brief AN: the launcher's Windows notification for a new alert (pages, P7, 2026-11-22)

You are the coder: Opus 5.5 at high effort, one piece start to finish; hand back a branch ready to list.

## The house rules (binding)
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-P7-review-rules.md` (privacy, safety, every go command through
`runs-pages-p6/go1.sh`, named tests). TEMP, TMP, LOCALAPPDATA, APPDATA of test processes in
`C:\Users\trabi\AppData\Local\Temp\p7-an\` (OUTSIDE any git copy: make-folder refuses a folder inside one). **No window
and no notification on the owner's screen in tests:** the Windows calls behind an interface, stand-ins in tests.
Invented data only. Commits `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push `git push private HEAD:wip/pages-alertnote` only. The
launcher's look files (`ui.go`'s rendering, `look.go`, `page.go`) are the UI track's: not needed here.

## Where
`git -C repo-archiver fetch private && git -C repo-archiver worktree add -b wip/pages-alertnote ../wt-pages-alertnote private/claude/charming-feynman-vm2xia`
(the head 09aeba54: it holds the tray icon (L3, in `internal/launcher`, a file named like tray*.go) and the pages' alerts
(`internal/server/alerts.go`: `GET /api/alerts` with `unseen`, `change`, each alert's fixed `words`)). Report:
`archiver/docs/progress/pages-alertnote-REPORT.md`.

## What to build
1. While the launcher runs and the pages answer, it asks the pages' `GET /api/alerts?limit=5` (loopback, the pages'
   address it already knows; the same way the launcher already reads the pages' state, if it does: read how) every 30 s,
   one ask at a time, a 3 s bound. **No catalogue read in the launcher** (it has no SQLite by design) and nothing over the
   network beyond 127.0.0.1.
2. When `change` moves and an alert that was not there before is unseen and not ended, the tray icon shows ONE Windows
   notification (the balloon of `Shell_NotifyIcon` with `NIF_INFO`; no new dependency): title "TG Archive", text the
   alert's fixed words (one; "and N more" when several are new at once), at most one notification a minute. A click on
   the notification (the tray's balloon-click message) opens the app's window on the pages' alerts place (read U-1's
   address for it in appshell or the pages' router; if none exists say so and open the Overview). The test alert
   (kind "test") is shown too (so the owner can check it end to end with the pages' "Send a test alert").
3. Nothing is shown on the launcher's first look after a start (alerts already unseen at the start are not news), and
   nothing when the tray icon is not shown (the window is open): say in the report whether the icon is shown whenever
   the launcher runs or only after "keep it running", and what that means for the notification.
4. Tests with the stand-in pages (an httptest server answering /api/alerts) and a stand-in tray: a new alert notifies
   once; the same change does not again; the first look notifies nothing; several new at once say "and N more"; the
   one-a-minute bound; a pages that do not answer or are slow stop nothing; the click opens the right address. The whole
   `internal/launcher` once at the end, gofmt, vet.
Hand back: head, report path, one line not verified.
