# What the 12.13 diagnostics report could leak

Every one of the app's 84 archive log lines, filled with **made-up** names, run through the **12.13** redactor (the one in your current reports) and the **12.14** one. Only lines where a made-up word survived are listed. No real data was read.

Made-up names: group **Sunset Riders** (the report turns a group name into `G7`), topic **Beach Week** (turned into `<name>`), file names with the words *Maria, Tom, Lisbon, party, final cut, iCaps*.

**12.14:** 0 leaks across all lines and shapes.

## Which shapes of value leaked in 12.13

| Value put in the log line | Log lines that leaked | Example of what 12.13 showed |
|---|---|---|
| chat name alone | 0 | (hidden) |
| topic name alone | 0 | (hidden) |
| relative path, plain file name | 0 | (hidden) |
| relative path, file name holding a topic/chat name | 69 | `alert "G7/videos/Maria and Tom <name><file>": G7/videos/Maria and Tom <name><file>` |
| relative path, name glued to a word | 69 | `alert "G7/videos/_iCaps<name>.mp4": G7/videos/_iCaps<name>.mp4` |
| relative path in a topic folder | 0 | (hidden) |
| relative path followed by ': error' | 0 | (hidden) |
| Windows path, plain file name | 0 | (hidden) |
| Windows path, file name holding a topic/chat name | 0 | (hidden) |
| Windows path with an error after it | 0 | (hidden) |
| bare file name | 0 | (hidden) |

## Words that got through (count of leaking lines)

- Tom: 69
- iCaps: 69
- Maria: 69

## Each leaking line (log line, 12.13 report, 12.14 report)

### relative path, file name holding a topic/chat name (69 log lines)

`ix_alerts.go:112:5`
- logged: `alert "Sunset Riders/videos/Maria and Tom Beach Week_005_final cut.mp4": Sunset Riders/videos/Maria and Tom Beach Week_005_final cut.mp4`
- 12.13: `alert "G7/videos/Maria and Tom <name><file>": G7/videos/Maria and Tom <name><file>`
- 12.14: `alert "<path>": <path>`

`ix_alerts.go:146:3`
- logged: `alert "Sunset Riders/videos/Maria and Tom Beach Week_005_final cut.mp4": Sunset Riders/videos/Maria and Tom Beach Week_005_final cut.mp4`
- 12.13: `alert "G7/videos/Maria and Tom <name><file>": G7/videos/Maria and Tom <name><file>`
- 12.14: `alert "<path>": <path>`

`ix_api.go:279:5`
- logged: `rescan: adding 3 group(s) refused: a group's download settings could not be saved (3: Sunset Riders/videos/Maria and Tom Beach Week_005_final cut.mp4)`
- 12.13: `rescan: adding 3 group(s) refused: a group's download settings could not be saved (3: G7/videos/Maria and Tom <name><file>)`
- 12.14: `rescan: adding 3 group(s) refused: a group's download settings could not be saved (3: <path>)`

`ix_subst.go:435:4`
- logged: `not downloading Sunset Riders/videos/Maria and Tom Beach Week_005_final cut.mp4 #3: same bytes as Sunset Riders/videos/Maria and Tom Beach Week_005_final cut.mp4 (Sunset Riders/videos/Maria and Tom Beach Week_005_final cut.mp4)`
- 12.13: `not downloading G7/videos/Maria and Tom <name><file> #<n>: same bytes as G7/videos/Maria and Tom <name><file> (G7/videos/Maria and Tom <name><file>)`
- 12.14: `not downloading <path>)`

The same happens in: `ix_api.go:315:3`, `ix_api.go:321:2`, `ix_api.go:466:4`, `ix_backup.go:565:3`, `ix_backup.go:624:4`, `ix_browse.go:231:5`, `ix_browse_api.go:1286:4`, `ix_chat.go:30:4`, `ix_chat.go:49:3`, `ix_chat.go:104:5`, `ix_chat.go:144:3`, `ix_copies.go:563:5`, `ix_copies_ml.go:344:4`, `ix_copies_ml.go:349:4`, `ix_copies_ml.go:352:4`, `ix_copies_ml.go:357:4`, `ix_copies_ml.go:653:3`, `ix_copies_sample.go:1020:3`, `ix_copies_sample.go:1044:4`, `ix_deadline.go:290:4`, `ix_dl_check.go:159:4`, `ix_dl_check.go:284:4`, `ix_dl_check.go:336:4`, `ix_docker.go:186:2`, `ix_downloads.go:121:4`, `ix_final.go:74:3`, `ix_final.go:79:3`, `ix_fixity.go:54:4`, `ix_gone.go:181:3`, `ix_gone.go:405:3`, `ix_gone.go:425:5`, `ix_held.go:197:4`, `ix_held.go:626:5`, `ix_held.go:708:3`, `ix_live.go:124:3`, `ix_live.go:258:2`, `ix_lowq.go:265:2`, `ix_lowq.go:310:4`, `ix_media.go:108:5`, `ix_ml.go:762:4`, `ix_part_store.go:252:4`, `ix_part_store.go:470:4`, `ix_previews_all.go:564:4`, `ix_previews_all.go:644:5`, `ix_queue.go:195:4`, `ix_queue.go:224:5`, `ix_queue.go:511:4`, `ix_queue.go:516:3`, `ix_record.go:487:4`, `ix_record.go:494:4`, `ix_record.go:529:3`, `ix_record.go:537:3`, `ix_reportfile.go:40:4`, `ix_sched.go:113:5`, `ix_sched.go:263:3`, `ix_site.go:477:5`, `ix_staging.go:103:3`, `ix_staging.go:105:3`, `ix_staging.go:172:3`, `ix_subst.go:297:3`, `ix_unlinked.go:181:3`, `ix_update.go:326:2`, `ix_update.go:348:3`, `ix_vdup.go:728:5`, `purge_api.go:711:4`

### relative path, name glued to a word (69 log lines)

`ix_alerts.go:112:5`
- logged: `alert "Sunset Riders/videos/_iCapsBeach Week.mp4": Sunset Riders/videos/_iCapsBeach Week.mp4`
- 12.13: `alert "G7/videos/_iCaps<name>.mp4": G7/videos/_iCaps<name>.mp4`
- 12.14: `alert "<path>": <path>`

`ix_alerts.go:146:3`
- logged: `alert "Sunset Riders/videos/_iCapsBeach Week.mp4": Sunset Riders/videos/_iCapsBeach Week.mp4`
- 12.13: `alert "G7/videos/_iCaps<name>.mp4": G7/videos/_iCaps<name>.mp4`
- 12.14: `alert "<path>": <path>`

`ix_api.go:279:5`
- logged: `rescan: adding 3 group(s) refused: a group's download settings could not be saved (3: Sunset Riders/videos/_iCapsBeach Week.mp4)`
- 12.13: `rescan: adding 3 group(s) refused: a group's download settings could not be saved (3: G7/videos/_iCaps<name>.mp4)`
- 12.14: `rescan: adding 3 group(s) refused: a group's download settings could not be saved (3: <path>)`

`ix_subst.go:435:4`
- logged: `not downloading Sunset Riders/videos/_iCapsBeach Week.mp4 #3: same bytes as Sunset Riders/videos/_iCapsBeach Week.mp4 (Sunset Riders/videos/_iCapsBeach Week.mp4)`
- 12.13: `not downloading G7/videos/_iCaps<name>.mp4 #<n>: same bytes as G7/videos/_iCaps<name>.mp4 (G7/videos/_iCaps<name>.mp4)`
- 12.14: `not downloading <path>)`

The same happens in: `ix_api.go:315:3`, `ix_api.go:321:2`, `ix_api.go:466:4`, `ix_backup.go:565:3`, `ix_backup.go:624:4`, `ix_browse.go:231:5`, `ix_browse_api.go:1286:4`, `ix_chat.go:30:4`, `ix_chat.go:49:3`, `ix_chat.go:104:5`, `ix_chat.go:144:3`, `ix_copies.go:563:5`, `ix_copies_ml.go:344:4`, `ix_copies_ml.go:349:4`, `ix_copies_ml.go:352:4`, `ix_copies_ml.go:357:4`, `ix_copies_ml.go:653:3`, `ix_copies_sample.go:1020:3`, `ix_copies_sample.go:1044:4`, `ix_deadline.go:290:4`, `ix_dl_check.go:159:4`, `ix_dl_check.go:284:4`, `ix_dl_check.go:336:4`, `ix_docker.go:186:2`, `ix_downloads.go:121:4`, `ix_final.go:74:3`, `ix_final.go:79:3`, `ix_fixity.go:54:4`, `ix_gone.go:181:3`, `ix_gone.go:405:3`, `ix_gone.go:425:5`, `ix_held.go:197:4`, `ix_held.go:626:5`, `ix_held.go:708:3`, `ix_live.go:124:3`, `ix_live.go:258:2`, `ix_lowq.go:265:2`, `ix_lowq.go:310:4`, `ix_media.go:108:5`, `ix_ml.go:762:4`, `ix_part_store.go:252:4`, `ix_part_store.go:470:4`, `ix_previews_all.go:564:4`, `ix_previews_all.go:644:5`, `ix_queue.go:195:4`, `ix_queue.go:224:5`, `ix_queue.go:511:4`, `ix_queue.go:516:3`, `ix_record.go:487:4`, `ix_record.go:494:4`, `ix_record.go:529:3`, `ix_record.go:537:3`, `ix_reportfile.go:40:4`, `ix_sched.go:113:5`, `ix_sched.go:263:3`, `ix_site.go:477:5`, `ix_staging.go:103:3`, `ix_staging.go:105:3`, `ix_staging.go:172:3`, `ix_subst.go:297:3`, `ix_unlinked.go:181:3`, `ix_update.go:326:2`, `ix_update.go:348:3`, `ix_vdup.go:728:5`, `purge_api.go:711:4`
