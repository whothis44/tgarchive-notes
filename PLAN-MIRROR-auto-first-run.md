# The automatic mirror's first real run (the test account): the steps, what you will see, what is read afterwards

Written 2026-11-15 20:32 by the mirror session (M3). `run -auto-mirror` has never run against Telegram.
**Only the owner starts it.** About 20 to 30 minutes, with the phone at hand.

## What it is
With the switch on, the running collector notices a chat the account joins, reads it from its beginning
(messages only, nothing downloaded), creates one private channel as its mirror and forwards the chat's media into
it, oldest first, 100 at a time, 20 to 30 s between two requests (20 s and a random part of up to 10 s);
afterwards each new message follows when it is 90 to 120 s old (90 s and a random part of up to 30 s, the same
for the members of one album). Everything so far was a command you answered "yes" to; this is the first time the app decides by
itself. One mirror of one chat was completed by hand on 11-15 (751 messages); the automatic task uses the same
request code.

## Which build
The installed collector has it. **Since 11-15 23:37 that is the build of 5a516ac (the integrator's install),
which holds the timing piece: the task's times are varied by default.** No time is sooner than the fixed one
(20 s between writes, 90 s for a message), a wait Telegram states is never shortened, and the random part is
the same number every turn and after a restart. Your own look at the times, read-only, any time:
`powershell -ExecutionPolicy Bypass -File "C:\Users\trabi\Claude\Projects\Telegram\a3\a3-mirror.ps1" -Timing`.
New messages go "at once" (the default; a gathering of N minutes is a setting you have not made: leave it for
this run). Its `run -h` names `-auto-mirror`, `-no-downloads` and `-auto-mirror-steady` (checked 23:44; the
steady switch gives the fixed times and is not used by the starter). **Since 11-16 about 01:00 the installed
build is 698ee15, which also refuses a chat that protects its content before any request** (the chat list says
so at no request: such a chat is left, counted and said once: "protects its content"; nothing is read,
created or forwarded for it). Its first start steps the test catalogue's schema to 21 (an older build then
refuses that file). Checked 01:10: its `run -h` names the starter's flags; no collector running.
**Since 11-16 12:58 the installed build is 2b55760 (session M-6 checked it at 14:06: its `run -h` names all 16
flags the starter and this plan use). New in it for this run: while the switch is on, the chat list is asked
every 10 to 12 minutes (10 minutes and a random part of up to 2; it was a fixed 30), so three times as many
chat-list requests as before in the same time: how many requests one list costs on this account is counted
per kind and hour and is read from this run. The interval is a setting on record (5 to 1440 minutes; nothing
is set, so 10). The starter was tried again at 12:53 on the start script of 07:06 (a scratch copy, a stand-in
program, nothing dialled): it works as written below.**
**Since 11-16 16:47 the installed build is 44a6d7b (session M-6 read its `run -h` at 16:52: the help only).
New in it: the cap on new mirrors in any 24 hours is a setting on record, 20 unless set (it was a fixed 5; 1
to 50, and 1 to 500 since M13, merged 11-21 at 6aa225fb; the starter does not pass `-auto-mirror-new-per-day`, so this run uses the setting). For this first
run it changes nothing you will see: one chat is joined, one mirror is made.**
**With the pages too, if you like:** add ` -Pages` to the start command of step 1: the same run, and the app's
pages at `http://127.0.0.1:8787/` (this PC only); Quit on the page ends the run as the stop script does.
**One collector at a time:** this run and the day-long run of the board's item 29 use the same start script;
whichever is running, stop it before starting the other.

## Before you start
- Nothing started from the `a3` folder is running (if one is:
  `powershell -ExecutionPolicy Bypass -File "C:\Users\trabi\Claude\Projects\Telegram\a3\a3-stop.ps1"`). The VPN
  is on (WireGuard): the collector refuses to start otherwise.
- **Pick the chat you will join, and do not join it yet.** For this first run: a channel or group that (a) allows
  forwarding (one that restricts saving content is now left before any request, with a line saying so: nothing
  to see for a first run), (b) is not a forum (forums are not
  mirrored yet: it would be left, with a line saying so), (c) holds a few hundred messages with media at most
  (each 100 is one request, 20 to 30 s apart: 500 take about two minutes after the read), (d) if possible
  posts something new while you watch.
- The first `run` of this build on the test catalogue also does the one-time step of item 23 of the board's
  waiting list (chats that collect with no sign of your hand are switched off, their files held; two lines,
  numbers only).

## The steps (each works from any folder)
1. **Start:**
   `powershell -ExecutionPolicy Bypass -File "C:\Users\trabi\Claude\Projects\Telegram\a3\a3-auto-mirror.ps1"`
   You see: "the automatic mirror's run: run -auto-mirror -no-downloads (nothing is downloaded in this run)",
   then "started: watchdog pid=N, collector pid=N" and the paths of the logs. Downloads are off in this run on
   purpose, so that it shows the mirror's requests alone (`-Downloads` leaves them on).
2. **After about two minutes, look:**
   `powershell -ExecutionPolicy Bypass -File "C:\Users\trabi\Claude\Projects\Telegram\a3\a3-auto-mirror.ps1" -Lines`
   It starts nothing and prints the automatic mirror's own lines from the log (the catalogue's chat numbers
   and fixed words only). Wait until this line is there:
   "automatic mirroring: the chat list stored whole after its start: chats joined from now on are mirrored".
   **A chat joined before that line is never mirrored by itself** (by design: only chats joined from then on).
3. **Join the chat from the phone.**
4. **Look again after a minute or two** (the same `-Lines` command). In order:
   "automatic mirroring took chat N (joined while away): read first by the reader, then mirrored" (within
   seconds when Telegram's live updates name the chat, else at the next chat list: within about 12 minutes,
   the list being asked every 10 to 12 minutes in this run);
   then, once the chat is read to its end: "help.getConfig asked (once a session)", "a mirror was created",
   and "a batch was forwarded" once for every 100 messages.
   On the phone: a new private channel named "X-", the chat's name and "-1", filling up oldest first.
5. **If the source posts something new while you watch:** it appears in the mirror when it is 90 to 120 s old,
   not at once (an album that is still arriving is never split), and later still while the pause since the
   account's last write runs.
6. **Stop** when the mirror has caught up, or whenever you like:
   `powershell -ExecutionPolicy Bypass -File "C:\Users\trabi\Claude\Projects\Telegram\a3\a3-stop.ps1"`
   Then tell any session that it ran; nothing else is needed from you.

## If something else shows
- "Telegram stated a wait": a wait under 60 s is slept, a longer one is recorded and nothing is sent before its
  end; the pause is doubled and stored. Nothing to do.
- "a request ... had no answer: recorded as unknown; that mirror is blocked": nothing is sent again for it. A
  minute later the task reads the mirror channel once and settles what arrived by itself ("is settled ... the
  mirror goes on"), or says that it waits for your word. Leave it running or stop; tell a session.
- "is blocked until the owner looks": nothing more is sent for that chat by itself. Stop and tell a session.
- To end one chat's mirror yourself while it runs: leave the source chat, or delete the mirror channel, on the
  phone; the task ends that mirror once the account's chat list shows it (at once by a live update, else within
  about 12 minutes) and says so.

## What stays afterwards
The mirror goes on only while the collector runs with the switch (this script); a start with `a3-start.ps1`
alone mirrors nothing by itself and loses nothing: the next run with the switch carries on where it stopped.
At most 20 new mirrors are created in any 24 hours (the setting's default; it was 5 before the build of
16:47), 10 chats are taken at each look.

## What is read afterwards (the mirror session; read-only; counts, seconds and fixed words only)
- From the log's lines and their times: seconds from the join to "took", to the end of the read, to the create,
  to the first forward; the gaps between forwards (each at least 20 s); every wait, unknown outcome or block.
- From the catalogue, read-only: the want and the mirror's state; the batches by state; forwarded rows against
  the chat's media messages (each once, none left); the hour's requests per kind (config, create, forward,
  history) with waits and seconds asked.
- A new message's delay from its post to its forward (90 s to about three minutes expected: 90 to 120 s by the
  rule, then the task's next turn and the pause), and the gaps between forwards against 20 to 30 s.
- The numbers go to `TELEGRAM-FACTS.md` section 11 through the integrator, as "looks like" (one run).

## What was tried here first (11-15 20:29 to 20:31; nothing was sent to Telegram, no real catalogue opened)
The script `a3\a3-auto-mirror.ps1` is new (the mirror track's; not in git, as the other `a3` scripts): no byte
below 32 in it, it parses. Run by its full path from another folder on a scratch copy (`-Root`, `-State`; an
empty placeholder for the catalogue; a stand-in program that only writes down its arguments in place of the
collector): (1) with `-NoWatchdog`: "started without the watchdog", the stand-in saw `run ... -auto-mirror
-no-downloads`; (2) the default way, through the installed watchdog, with `-Downloads`: "started: watchdog
pid=N, collector pid=N", the stand-in saw `run ... -auto-mirror`, the watchdog ended with "the program ended
cleanly"; (3) `-Lines` on that copy with two invented mirror lines and one other line in the log: the two
shown; (4) a program that is not there: "not started, nothing was sent", exit code 2; (5) `-Lines` where
nothing was ever started: "nothing to show". Two look-ups of the public address by the start script, as it
always does. The scratch copy is removed. **Not tried, because only you can:** the real collector with the
switch on.
**It starts through `a3-start.ps1` and is stopped by `a3-stop.ps1`: both are Core's.** Core changed them again
until 20:45 and has run them as you do (board message 52, 20:40). **Tried again by me at 20:50 on the start
script of 20:45,** the default way through the installed watchdog with the stand-in program, by full path from
another folder: "started: watchdog pid=N, collector pid=N", the stand-in saw `run ... -auto-mirror
-no-downloads`, the watchdog ended "the program ended cleanly"; `-Lines` afterwards: "not running", "the
automatic mirror has said nothing in it yet". One more look-up of the public address; the scratch copy removed.
**And at 21:47, on the build installed at 21:41, with the new switch `-Pages`:** started through the installed
watchdog, the stand-in saw `run ... -pages -pages-addr 127.0.0.1:8787 -auto-mirror -no-downloads`, the start
script named the pages' address, the watchdog ended cleanly; the script has no byte below 32 and parses.
**And at 23:44, after the install of 5a516ac (session M4):** by its full path from another folder, on a scratch
root and state folder, through the installed watchdog with a stand-in program (built for the try; it only
writes down its arguments), with `-Pages`: "started: watchdog pid=N, collector pid=N", the pages' address named,
the stand-in saw `run ... -pages -pages-addr 127.0.0.1:8787 -auto-mirror -no-downloads`, the watchdog's record:
ended cleanly, no restart; `-Lines` afterwards: "not running", "the automatic mirror has said nothing in it
yet". One look-up of the public address; the scratch copy and the stand-in removed.
Two things from Core's message that matter to you: start these scripts in a PowerShell window as written (a
program that captures their output waits until the collector ends); and a start under the watchdog cannot take
a typed answer, which this run never needs.
