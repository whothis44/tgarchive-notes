# Brief BK: two Settings doors from Core, the joined-chat downloads and the nightly backup (pages' Go side) (pages, P7, 2026-11-22)

Same coder and rules as CS and AL (go1.sh, named tests, TEMP etc. in `C:\Users\trabi\AppData\Local\Temp\p7-bk\` outside
any git copy, Go only: U-1 draws). TWO branches, one per Core piece, each with its own report section in
`archiver/docs/progress/pages-backup-REPORT.md` (on each branch):

1. **`wip/pages-newdl`** from Core's `private/wip/core-newdl` 3c9c8ae9 (K28): "downloads for a chat joined while away":
   `(*Collector).NewChatsDownload(ctx)` (Value, Stored, Default, Unreadable, Accepted (today `[off always]`), InForce,
   NewChatsRun, AutoMirrorRun: a start flag for this run, "", off or always) and `SetNewChatsDownload(ctx, value)`
   (refuses with `catalog.ErrNewChatsDownloadValue`, writes nothing). In the Settings answer `new_chats_download`
   {value, stored, default, accepted, in_force, by_run (words when a start flag overrides it for this run), unreadable,
   words per value, cost, when, route}; `POST /api/settings/new-chats-download {"value"}` (a value not in Accepted
   refused before the door). Words true of the code (read what "always" makes the collector do for a newly joined chat,
   and that the mirror reads it too).
2. **`wip/pages-backup`** from Core's `private/wip/core-backup-nightly` b74d0e21 (K27, holds K22): the backup on
   Settings and a "Back up now": `BackupNow(ctx)` (`ErrBackupRunning`), `BackupStatus(ctx)` (On, Running,
   RunningReason, LastGoodAt, LastTryAt, LastFailure, NextRunAt, TriesToday, CopiesKept, Keep, DestinationSet,
   DestinationUnreadable), `BackupSettings(ctx)` (each {Value, Default, Stored, Unreadable}, DefaultTo), setters
   `SetBackupOn`, `SetBackupTime` ("HH:MM", `ErrBackupTime`), `SetBackupKeep` (`ErrBackupKeep`), `SetBackupTo` (""
   = the default; `ErrBackupToNotFull`, `ErrBackupToTop`, `ErrBackupToCatalogue`, `ErrBackupToLibrary`), each
   `ErrNotRunning` while the collector does not run. In the Settings answer `backup` {status with fixed words for each
   time and failure, the settings, routes}; `POST /api/backup/now` (its words before the click: what is copied, where,
   about how long; answered "started" or the refusal), `POST /api/settings/backup-on|backup-time|backup-keep|backup-to`.
   The destination is the owner's own folder: shown as Core's door gives it; never logged by the pages.
3. For each: the seam, the livepages adapter, the guard's lists, held-stop, the demo fake, tests; gofmt, vet, named.
Hand back: the two heads, the JSON shapes for U-1 in a few lines each, one line not verified.
