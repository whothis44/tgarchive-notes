# Brief CS: the copy checks' settings on the Settings page (Go side) (pages, P7, 2026-11-22)

Same coder and rules as T1 (`twin_hold`): go1.sh, named tests, TEMP etc. in `C:\Users\trabi\AppData\Local\Temp\p7-cs\`
(outside any git copy), Go only (the UI track draws; its F10 already shows these rows switched off until the routes
answer). Branch `wip/pages-copysettings` from the main head (fetch first), new copy `wt-pages-copysettings`. Report:
`archiver/docs/progress/pages-copysettings-REPORT.md`.

1. **The copy checks' six settings** (the collector's door `internal/collector/copyset_door.go` exists; the server has
   no seam method and no route): add the seam methods, the livepages adapter and, in the Settings answer, one object
   per setting (`{on|value, stored, default, bounds, unreadable, settable, words, cost}`, as `twin_hold` and the cap
   do), and `POST` routes to set each: fingerprints of saved videos (on/off); look at frames before a video is
   downloaded (on/off); the fingerprints' decoder; the frame check's decoder; videos the frame check judges at once
   (a number); kept parts at most (GB). Read the door and the copies' code for each one's true words and cost (what
   turning it off or on changes, whether it takes effect at once or at the next start, whether anything is ever
   skipped by it: by the house rule, nothing is skipped on a probable copy). The owner needs the OFF switches.
2. **The exact check** (`settings.exact_check`): its read and set the same way (find its door: catalogue or collector).
3. **"Back up now":** only if a door exists to start the backup from the running app (read `cmd/tgarchive-backup`,
   `internal/backup`, and the collector for a backup door); if none, say so in the report (the Core track owns the
   backup and its timer) and add nothing.
4. The same guard, held-stop refusal, route lists (update the guard tests' lists), the demo fake, tests for each;
   gofmt, vet, named tests.
Hand back: head, the JSON shape in a few lines for the UI track, one line not verified.
