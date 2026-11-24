# Review: wip/fix-wdalerts 53fe56ee (the watchdog's own alerts), against 3dd304df

Independent Opus review, 11-23. **Verdict: no logic error in what is skipped, deleted or decided; three MED (two false
alarms, one owner's word on sends): fix first.** Checked: vet and the named tests on a scratch worktree (alert,
crashlog, watchdog whole; collector `Watchdog|AlertAway|AlertSend|Wall`; catalog `Alert`; launcher
`Wd|Hang|State|Cause|Wall|AlertNote|News`; appshell `Notice|TestAssets|Security`; server
`TestAlertThresholds|TestAssets|Security`): all ok.

## The send path (question 1): scope and bounds, verified
- Only the two named kinds: `AlertsDue`'s new branch needs `a.kind IN (events)`, the one caller passes
  `alert.EventKinds()` = `watchdog.crashed`, `watchdog.hang`. Every other ended kind (test, backup, mirror, NAS ...)
  is still never due (the coder's test pins the test alert; the SQL makes it hold for all). `watchdog.refused` is
  OPEN, so it goes the existing K22b way (sent, again every 12 h while open and unseen) like any open alert.
- An event is sent at most once per channel (`s.sent_at IS NULL`), never when seen, never once raised `resend` hours
  ago; a failed send backs off 1/5/15/60 min (same code as before). The 20-an-hour cap is counted from
  `c_alert_send` in the catalogue, so it holds across restarts and a crash loop (at most ~13 crashes a day can exist:
  the watchdog's own cap). Stated waits: `sendLocked`/`storeWait`/`channelWait` unchanged: slept in full.

## Findings
**MED 1: a false hang line after every resume from sleep.** `launcher/statewords.go` `hangOf`: `now > doc.StaleAfter`
(StaleAfter = last write + 2 min, wall clock). After a sleep longer than 2 min the watchdog's file stays stale until
its next beat (up to 60 s: wait timeouts do not count sleep), and the window (asks on focus and every 15 s) says
"The watchdog's status no longer moves ... Quit and start the app again." Likewise the watchdog's first beat after
resume may find the collector's status not yet rewritten: `StaleNow` true for a whole minute ->
`wordHangCollector`, and if the run ends in that minute (a shutdown right after wake) `stale_at_end` -> a
`watchdog.hang` alert, sent away. Same on a wall-clock jump forward. Fix: one beat of slack (`now > StaleAfter +
EverySecs`), and name a collector hang (and `StaleAtEnd`) only after two stale beats in a row (a counter in the
watchdog's own counts).

**MED 2: a PC shutdown or restart becomes a "hang" alert sent to the phone.** `collector/watchdognews.go`
`watchdogNews`, case `HowNoReport`. A Windows shutdown/update restart while the app runs kills the watchdog if the
collector does not stop within Windows' few seconds; the next boot settles a "no report" line (the history on record
on 11-15 already held 1 such run in 28). That is raised as `watchdog.hang` ("hung, or was ended from outside"), toasted
and sent by bot/Saved Messages. Fix: when the system booted after the run's last sign of life (boot time from
`GetTickCount64`, read by the collector, not the watchdog), use own words ("the PC was shut down, restarted or lost
power while the collector ran") and do not make it an event (record only), or ask the owner.

**MED 3: the owner's word on the sends.** Sending ended alerts changes the coded K22b rule ("seen or ended, never
again") and the approved design note says "No request to Telegram". It is within K22b's agreed "sent once when
raised", scoped and capped (above), but it writes to Telegram for the owner on a new trigger: the integrator should
put one line to the owner (crash/hang messages to the bot and Saved Messages, at most ~13 crash messages a day, 20
an hour). If he says no: drop `eventKindWords()...` from the one `AlertsDue` call in `collector/alertaway.go`; the
record, the list and the Windows notification stay.

**LOW 4: the clock set back skips crashes.** `watchdogNewsFrom`: runs count only when `Ended.After(marker)`. A clock
corrected backwards (or a history line with a future time) puts the marker ahead of every new end: crashes are
missed until the clock passes it. Fix: a marker after `now` is taken as none (the 24-hour window, as for an
unreadable one).

**LOW 5: a run's hang can be lost.** A run with both a crash and `stale_at_end` gives two alerts with the same
`at`; the marker moves to it after the first, so a failed raise of the second is never retried. Fix: mark once per
run, after its last alert.

**LOW 6: an unreadable marker fails open by design** (re-raises the last 24 h, so those are sent again; bounded by
24 and the cap). Same on the first start of this build: the last 24 h's real runs are raised and sent at once.
Acceptable; say it to the owner with MED 3.

**LOW 7: a second refusal keeps the first one's words.** If the open refusal is still unseen, `RaiseAlert` returns
`AlertReturned` (times + 1) and never updates `words`, so the time and reason shown are the first refusal's. Fix: end
it and raise anew for this kind, or update the words on a return.

**LOW 8: the launcher's page says the watchdog's staleness twice** (`ui.go` `statusLines`: the old sentence and now
`wordHangWatchdog`). Drop one.

**NOTE:** the words' "three" and "12" are the default policy's; the launcher passes no policy flags, so they hold.
The "N restarts in 24 hours" is counted over the whole history (all watchdog runs), the watchdog's own count is per
watchdog run: the numbers can differ from its log. The healthy hour is wall time, so a sleep counts toward it.
Words: fixed, numbers and local times only, checked by `alertWordsForm`; log lines constant. The watchdog's wall
holds (it adds two `omitempty` fields to its own history line; older lines read as never stale, tested). No greying:
a hang leaves `state.away` alone. **shell.js is intact:** its one NUL byte is the pre-existing literal in the regex
`[^\x00-\x7f]` (same bytes, moved by the insertions); no CR, no other control byte; a line diff shows only the 7
intended hunks.

**fix first** (MED 1 and 2 are small; MED 3 is the owner's word, not code)

## Second pass (the fix): ebcf7f98 against 53fe56ee
Independent Opus review, 11-23. Checked on a scratch worktree: gofmt, vet (watchdog, launcher, collector, crashlog),
watchdog, crashlog and alert whole, collector `Watchdog|AlertAway|AlertSend|Wall`, launcher
`Wd|Hang|State|Cause|Wall|AlertNote|News|Watchdog`: all ok. The wall holds: the watchdog still never opens the
catalogue; its only additions are a counter in its own status file (no `omitempty`, an older file reads 0: no
collector hang said, the quiet side) and the history line is unchanged (`stale_at_end` now set from two stale beats);
no restart is decided by any of it. MED 3's scope is unchanged (`EventKinds` = crashed, hang).

**MED 1: fixed.** The watchdog's file counts as stale one beat after `stale_after`; the collector's hang and
`stale_at_end` need two stale beats in a row, and a beat more than two beats after the last restarts the row (Go's
monotonic clock on Windows is the interrupt time, which counts sleep: the gap after a resume is seen, and the timer
fires at once). The window says a hang only after two minutes of looks no more than 90 s apart; the first look after
a sleep restarts that hold, and the watchdog writes again within it.

**MED 2: half fixed: still open for an ordinary Shut down.** The cold-start case (restart, update restart, power loss)
is right: `Ended` is the marker's last touch, before the start. But `GetTickCount64` counts on through Fast Startup,
and Fast Startup is on on this PC (`HiberbootEnabled` = 1); the last full start and the current sign-in are the same
day five weeks ago. So every Start > Shut down while the app runs, where the collector does not stop within Windows'
few seconds (live connections, the catalogue), is still raised as `watchdog.hang` and sent to the bot and Saved
Messages. Rare today (no Shut down in five weeks), more frequent once the PC is turned off while the NAS works.
**Cure (recommended): take as "the start" the later of the tick-count start and the logon time of the collector's own
logon session** (`OpenProcessToken` + `GetTokenInformation(TokenStatistics)` for the session's LUID, then
secur32 `LsaGetLogonSessionData` -> `LogonTime`, `LsaFreeReturnBuffer`; about 30 lines, `boottime_windows.go` only).
Fast Startup signs every user out before it hibernates the kernel's session, so the sign-in after power-on is always
newer than the run's last touch; a sign-out (which ends the app too) then also counts as no hang (words: "a shutdown,
restart or sign-out of the PC"). No file format, no watchdog change. Not chosen: the console signal (Go already turns
CTRL_LOGOFF/SHUTDOWN into SIGTERM and the watchdog notes it, but Windows does not deliver those to a process that has
loaded user32, the note must reach the marker inside Windows' ~5 s, and it changes the watchdog's marker: more code,
less sure); "not sent" (the false hang stays on the page and as a toast); the event log or `ShutdownTime` (heavier, and
not sure under Fast Startup). Test: the logon time is read and not before the tick-count start.

**LOW 4: fixed** (a marker after now is taken as none). **NOTE (new, from it):** while the clock is behind a run's end
on record (set back by more than a start's interval), each collector start re-tells the last 24 hours (the marker is
written back to the future run's end). Bounded (12 restarts a day, 20 sends an hour) and on the stated side ("told
twice rather than missed"); exact cure if wanted: find the marker's run by its place in the history (Read is newest
first by append) instead of by time.
**LOW 5: fixed** (the marker moves after a run's last alert; same-run alerts are adjacent). If the second raise fails
the first is told again at the next start: the stated side.
**LOW 6:** unchanged by design (for the owner's line with MED 3).
**LOW 7: fixed** (an open refusal is ended and the new one raised with its own words; tested).
**LOW 8: fixed** (the launcher's page keeps the old sentence; the hang line only for the collector). NOTE: that old
sentence still has no slack, so the launcher's own page shows it for up to a minute after a resume (wording from
before this branch; the window's answer does not).

**fix first** (MED 2 for an ordinary Shut down with Fast Startup: one file, the logon time)
