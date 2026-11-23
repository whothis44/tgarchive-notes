# The watchdog's own alerts: design note (Core's next item; a recommendation, no code)

Written 11-22 by the Console run (follow-up 10). **The owner's yes is asked before anything is built.**

## The problem
Three things the watchdog knows never reach the alerts record (K22, `c_alert`): a **crash** of the collector (and
the watchdog's restart), a **restart refused** (three quick deaths in a row, or 12 restarts in 24 hours: "a person
is needed"), and a **hang** (the collector alive but its status not moving, or the watchdog itself killed: its
status file older than its `stale_after`). Today they are lines in the watchdog's log and fields of its status file
(`watchdog-status.json`) only. The watchdog never opens the catalogue (its wall test allows the standard library and
`internal/crashlog` only), and that wall is worth keeping: a crash loop must never touch the archive.

## Recommendation: the watchdog keeps its wall; the collector and the window carry its news
1. **Crash and restart (the collector is running again).** At its start, the collector reads the watchdog's status
   file and crash record (read-only, files in the watchdog's own folder, as the launcher reads them today) and, for
   each crash it has not reported yet, raises one alert **ended as it is raised** (`RaiseEndedAlert`, a new kind
   `watchdog.crashed`): "The collector stopped by itself at 14:05 and the watchdog started it again (2 restarts in
   24 hours)". Fixed words, numbers and times only (the alert words' rule). A marker in the catalogue (the last crash
   time reported) keeps it to once per crash.
2. **Restart refused (nothing runs).** The collector is down, so nothing can write the record now. The window
   (`tgarchive.exe`, its list's notice, which already says "the collector is not running") names the watchdog's
   decision from its status file: "The collector stopped by itself three times in a row: the watchdog does not start
   it again by itself. Start the app again when you have looked." When the owner next starts the collector, step 1
   records it as an open alert (`watchdog.refused`) that ends at the first healthy hour, so it is in the history.
3. **Hang.** A collector that is alive but whose status no longer moves cannot raise anything itself; the window's
   notice says so from the status files' ages (the collector's own `stale_after`, the watchdog's), with what to do
   ("Quit and start the app again"). The next start records it as in step 2 (`watchdog.hang`, ended at once).

## What it costs and what it never does
- No request to Telegram, no new process, no write by the watchdog; the collector reads two small files at its start;
  the window reads what it reads today. Three new alert kinds with their threshold rows (0: at once).
- Never: the watchdog opening the catalogue, a restart decided by these alerts, a log line's text in an alert.

## Alternatives weighed (not recommended)
- **The watchdog writes the record itself:** breaks its wall; a crash loop would then write to the archive at every
  death; two writers of the catalogue while the collector runs.
- **A helper process that tails the watchdog's log into the record:** one more program to keep alive for little gain;
  the window already reads the status file.

## Asked of the owner
Yes or no to the three steps (they can be built one by one: step 1 alone already puts every crash in the history).
