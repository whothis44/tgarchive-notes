# Brief M4-R: independent read-only review of the automatic mirror (2026-11-15)

You are a challenger. You did not write this code. With `run -auto-mirror` the collector, unattended, notices
a chat its owner joined, lets its reader read that chat's history, creates a private mirror chat on Telegram
and forwards the chat's media into it, then keeps it current. Nobody is at the keyboard. The defects that
matter, in order:
1. it acts on a chat the owner marked "never", or recreates a mirror the owner removed, or mirrors a chat that
   was not newly joined (the old app once added 30 chats by itself and the owner switched off 24);
2. a file is queued for download from a chat the owner did not choose;
3. a write to Telegram (create, forward) is sent twice, inside a wait Telegram stated, sooner than the pause,
   past the hourly bound or the new-mirrors-per-day cap, or in a loop after a failure;
4. it holds or changes the collector's own work: the reader's reads, the monitor, the owner's `-approve-read`,
   downloads; with the switch OFF, anything at all differs from before;
5. a mark or a record is lost or misread (two writers, a corrupt row, a restart, a chat that changed identity);
6. something private is shown (a title, username, Telegram id, access hash) in a log, the heartbeat, the
   status file or `mirror -list`.

The code: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-auto` (branch `wip/mirror-auto`), Go module in
`archiver/`. The change under review is `git diff 99b71c3..HEAD` (commits up to 186d76d). What it was asked to
do: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-M4-mirror-auto.md`, plus one decision sent mid-way: with
`-auto-mirror` on and `-auto-mirror-download` off, a stored policy makes every chat row first made for that
account start switched off for downloads, in the catalogue's chat-making path (`internal/catalog/rows.go`
`EnsureChat`), before any message of it is saved; chats that exist are untouched; no policy, no change.
"Newly joined" = joined after the first chat list stored whole after the switch was first on. The rules it
must keep: `archiver/docs/TRIED-BEFORE.md` sections 24 and 25 (13 rules) and
`C:\Users\trabi\Claude\Projects\Telegram\LESSONS-ix12.30-live.md` section 6b: read them. The code underneath
was reviewed three times (`wt-mirror-review-scratch`, `-review2-scratch`, `-review3-scratch`, each `REVIEW.md`):
do not review it again, but check none of those fixes was undone. The coder's report
(`archiver/docs/progress/mirror-auto-REPORT.md`): read it last, trust none of it.

## Read-only (as before)
- Edit nothing in the copy. Probes in a scratch folder of your own
  (`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review4-scratch`, make it), loaded with `go test -overlay`.
  Each finding CONFIRMED (a probe shows it) or PLAUSIBLE (reading only). Write findings into the report as you
  confirm them.
- Nothing against Telegram; never the built command with real settings; never a real catalogue, a session
  file, the API settings file, `E:\T\tg-dl` or media. Invented data only.
- Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`; one go command at a time, each
  with `GOGC=25 GOMAXPROCS=2 -p 1`; only named tests; never a whole-package run of `internal/catalog` or
  `internal/collector`; no race detector, no Docker (the architect runs the race detector on the whole
  collector afterwards: but read every piece of state the new code shares between the monitor's goroutine, the
  reader's, the heartbeat's and the command's, and say where a race or a lock order problem is possible).

## What to try to break
Work through the six classes above in that order. Among other things:
- **The 13 rules, one by one,** each as "met / not needed / broken", with the place in the code.
- **"Never":** set before the look, after the mirror is wanted, between the create and the first batch, between
  two batches, while a request is out; the mark's row corrupt; the marks table missing; two writers; the chat
  migrated to a supergroup; `-allow` then the task; the mark written while `run` runs (the coder says marks are
  written only with the collector stopped: is the refusal real, and is that usable for an owner who is away?).
- **"Newly joined":** chats there before; a chat with no join time; a chat joined between the switch going on
  and the first whole chat list; the catalogue's first-ever chat list under the policy (the coder's doubt:
  every chat of it is made switched off: is that right, and does it stop the owner's own downloads until each
  is approved?); a chat left and joined again; a chat the monitor makes known before any list; private chats,
  bots, forums, the app's own mirrors (a mirror of a mirror); the same channel seen by two accounts.
- **The policy in `EnsureChat`:** every maker of a chat row for an account (the monitor's sink, the chat list,
  the reader, the bring-in, the mirror's create, a migration link); chats made for an account with no policy
  while another account has one; the policy removed when the switch goes off; a policy value that cannot be
  read; the bring-in run while a policy is set (does it make brought-in chats switched off, against what the
  old archive says?).
- **Downloads:** count the wanted files of the joined chat after the read in every order of events (the monitor
  first, the list first, a restart in between, `-auto-mirror-download` on one run and off the next, the owner's
  `-approve-read` of a chat the mirror approved: it must switch the chat on and only then).
- **Writes:** the forwards and creates the fake saw against the pause, the hourly bound, the per-day cap and
  every stated wait, across turns, sessions (a reconnect) and restarts; a failure that would loop (the same
  request every turn); an unknown outcome; CHANNEL_PRIVATE on a forward taken as "the owner removed the
  mirror" when it was something else (the source gone private; a wrong access hash): can a mirror be ended for
  good wrongly, and can it be undone?
- **The reader is not held:** the owner's approved chat keeps reading while mirrors forward; a wait slept
  inside a turn; the idle wake-up; the chat list every 30 minutes (what it costs in requests on an account of
  2,000 chats, by reading the reader's paging).
- **Switch off:** diff the behaviour with the flag off: requests sent, rows written, log lines, the idle time,
  the chat-list interval, `ReadApproval`'s JSON (does a record written by this build still read in the main
  branch's build, and the reverse?), `-approve-read` on a chat with an owner's approval already.
- **The schema step** (18 after 16 on this branch; 17 is another track's): a catalogue at 16 steps to 18; what
  happens at the merge when 17 lands between (two constants: check they are the only place); a catalogue at 18
  opened by a build at 16 fails cleanly; no table rebuild; the read-only commands on an older catalogue.
- **The tests:** for the five rules you judge most important, plant the defect through the overlay and say
  whether a test fails. Any test that judges real seconds.

## One thing the owner hit today, to check in this code too
On the real test catalogue (schema 12, the installed build at 16) the read-only `chats` command failed with a
bare SQL error, because a read-only open cannot step the schema and its query names a newer column. The
`mirror` command makes its plan read-only too. By a probe on an invented catalogue left at an older schema
(12 and 16): what do `mirror -chat N`, `mirror -list`, `mirror -never N` print, and is anything sent or
written? The smallest fix you would accept (fixed words that say the catalogue is at schema N, this build
reads M, and how to step it, before any query that can fail).

## Report
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review4-scratch\REVIEW.md`: findings most severe first, each
with file and line, the scenario, CONFIRMED or PLAUSIBLE, the smallest fix you would accept; the 13 rules'
table; where a race is possible; what you found sound; what you did not check. Lead with what you ran. Final
message: the findings as a numbered list, the rules broken or not met, the older-catalogue probe's result, what
you did not check; under 45 lines.
