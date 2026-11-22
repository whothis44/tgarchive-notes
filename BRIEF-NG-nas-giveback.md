# Brief NG: the NAS state's last fields and the give-back on the pages (Go side) (pages, P7, 2026-11-22)

Same coder and rules as N4P (`BRIEF-N4P-nas-pages.md`): go1.sh, named tests, TEMP etc. in
`C:\Users\trabi\AppData\Local\Temp\p7-ng\` (outside any git copy), Go only (U-1 draws), fakes only. Branch
`wip/pages-nasgive` cut from the NAS track's `private/wip/nas-pcside` 58abd9d7 (it holds your N4P and N4's doors,
`internal/collector/nas_doors.go`, and the lent wiring 6cee4192 in `collector/pages.go`). Report: append "NG" to
`archiver/docs/progress/pages-nas-REPORT.md`.

1. **The last five fields** of the collector's `NASState` (Why, StateUnreadable, StateUnreadableSince, Held,
   UnreachableSince): livepages' `NASState` takes them, `pagesNAS` (the lent wiring in collector/pages.go) hands them
   over (a small lent change there: one commit "Lent to the NAS track (collector/pages.go): ..."), and the pages'
   answers carry `held` (files the NAS holds of the account, readable with the NAS down), `unreachable_since`, `why`
   (fixed words), `state_unreadable` with its since, each with fixed words where a person reads it.
2. **The give-back:** `NASGiveBack(ctx, acct) (int, error)` (refused with `ErrNASWorking` while that NAS works for
   the account; the count is files given back; `NASGiveBackWords`, including that such a file starts again from 0 on
   the PC). A route `POST /api/nas/giveback {account}`, the owner's click only, the same guard and held-stop as
   forget; its warning said BEFORE the click in the facts' answer (the NAS's held count, and "if that NAS still runs,
   these files may download twice; each starts again from 0 here"), the count said after; ErrNASWorking in fixed
   words. Offered only when the NAS is away (unreachable) and holds files: say what the facts carry for that.
3. Tests for each (the fake: held with the NAS away, working, given back); the guard's lists; gofmt, vet, named tests.
Hand back: head, the JSON changes for U-1 in two lines, one line not verified. One independent review follows.
