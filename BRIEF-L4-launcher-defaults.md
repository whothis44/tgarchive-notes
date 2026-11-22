# Brief L4: two launcher defaults the audit found off (pages, P7, 2026-11-22)

Same coder and rules as L3, a NEW branch `wip/pages-defaults` cut from your L3 head (new copy `wt-pages-defaults`).
Read `C:\Users\trabi\Claude\Projects\Telegram\AUDIT-INACTIVE-FEATURES.md` (rows on `-pair-words` and `-no-links`).

1. **The owner's "same / not the same" verdicts:** the viewer records them, but the launcher never passes
   `run -pair-words <the viewer's data folder>` (`pairwordsline.go`, default off), so 0 are applied. Make it ON by
   default: the launcher passes the joined window's (the viewer's) data folder, a stored launcher setting can turn it
   off, and a flag in `run_flags` still overrides. Find in `internal/viewer` / `cmd/tgarchive-window` where that data
   folder is (read only; the viewer track's), and pass exactly it (one function, as the catalogue path in SW). Ask
   nothing of copies' code: it already reads them (`internal/pairwords`); say in the report what the collector then
   does with a verdict (read it: a "not the same" releases a held copy to the queue, a "same" keeps it held?) so the
   owner's line is true.
2. **Hard links:** `-no-links` is in the launcher's default `run_flags` (`settings.go` about line 89), copied from the
   test account's start script `a3\a3-start.ps1` (line 113), whose library was on the NAS share (link counts over
   the share are wrong: see the memory note on the NAS). No record says the owner chose it for a local library.
   Make links ON by default when the library is on a local disk, OFF when it is on a network share (a UNC path or
   a mapped network drive: `GetDriveType` DRIVE_REMOTE), as a stored launcher setting with three values (auto, the
   default; on; off). **An old `-no-links` in `run_flags` is NOT the owner's choice** (it is the launcher's former default,
   copied from that script; the owner's running app has exactly it): it is ignored while the setting is "auto" (not
   passed to the collector; say so once in the start's log line, constant format), and never stored as "off". Only a
   value the owner sets by hand in the new setting stays off. The owner's line: links come on for the local library at
   the next start. Read what the collector does with links on (`internal/store`: the links it
   makes for files posted in several chats, 262 owed in the owner's catalogue): when the setting turns them on, does
   it make the owed ones by itself, or only new ones? Say it.
3. **Both** as settings in `launcher-prefs.json` (L2's file), with `GET/POST /api/prefs` fields (`pair_words`:
   on|off; `links`: auto|on|off) and fixed words for the UI track; tests; the whole `internal/launcher` once; the
   report with ONE line for the owner of what changes at the next start.
Hand back as before: head, report path, the owner's line, one line not verified.
