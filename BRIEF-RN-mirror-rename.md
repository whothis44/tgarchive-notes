# Brief RN: renaming a mirror from the running app (pages' Go side) (pages, P7, 2026-11-22)

Same coder and rules as MD (`BRIEF-MD-mirror-doors.md`): go1.sh, named tests, TEMP etc. in
`C:\Users\trabi\AppData\Local\Temp\p7-rn\` (outside any git copy), Go only (U-1 draws). **This route makes a request
to Telegram for the owner (channels.editTitle): nothing is sent without the owner's click on a plan the owner saw;
fakes only in tests.** Branch `wip/pages-rename` cut from the mirror track's `private/wip/mirror-renamedoor` 6e610344
(M19, listed: its doors are `internal/collector/mirror_rename_door.go`; read it whole, and the mirror's words for
each end and refusal). Report: `archiver/docs/progress/pages-rename-REPORT.md`.

1. **Seam and adapter** (`Mirrors.RenamePlan`, `Mirrors.Rename`, plain types of the server's own, field for field
   M19's `MirrorRenamePlan` and `MirrorRenameResult`: never the current name in a log; NameLen and NameLimit; the
   cost "1 request: channels.editTitle"; `sends` false when blocked).
2. **Routes:** `GET /api/mirrors/rename-plan?account=&chat=&title=` (catalogue only: the plan with its cost and any
   block in fixed words; a plan token as the mirror's `want` routes carry, tying the click to this plan: read how
   `handleMirrorWant` ties its token) and `POST /api/mirrors/rename {account, chat, title, token}` (refused when the
   token is not the plan's or the plan changed: the "moved" answer as `want` does). Every End and refusal sentinel
   mapped to fixed words (M19 lists them: EndRenamed, EndRenameSame, EndRenameWaited/LongWait with WaitUntil said,
   EndRenameUnknown "safe to run again", EndRenameRefused with Reason, ...; ErrRenameBusy, NotSignedIn, Frozen,
   WaitHeld, NotRunning, Blocked with its Why words). The same guard, held-stop refusal and route lists as the other
   mirror change routes (update the counts: `mirrorRouteList`, `security_test`'s lists, the held-stop test's number).
   A title over the limit or empty refused before any door call.
3. **The demo fake** and tests for each end and refusal, the token's tie, the guard. gofmt, vet, named tests.
Hand back: head, the JSON shape for U-1 in a few lines, one line not verified. One independent review follows (it
writes to Telegram).
