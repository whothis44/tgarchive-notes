# Brief: an independent review of M5 (the mirror's stored name, the name rule, a rename, one settle rule)

You are a challenger, not the author. Read-only: **edit and commit nothing** in
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-name` (branch `wip/mirror-name`, head 02abe15, clean; the piece
is `git diff 9dd5a21..02abe15`, module in `archiver/`) or in any other copy. Your own folder:
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review7-scratch` (make it). Your report goes there as
`REVIEW.md`; your probes go there as test files loaded with `go test -overlay` (an `overlay.json` mapping a path
inside the copy's package to your file), never written into the copy. Look at
`wt-mirror-review6-scratch` (`REVIEW.md`, `zz_m6probe_test.go`, `overlay.json`) for the form of an earlier review
of the same packages.

## What the piece is (the author's brief, for what was asked: `BRIEF-M5-mirror-name.md` in the project folder)
A private Go program that mirrors a Telegram chat into a private channel it creates. This piece: (A) the
mirror's name is stored on its ledger row (`c_mirror.name`, a schema step) instead of being rebuilt in SQL in
three places; (B) the name rule (a prefix and a separator around the source's name, the number automatic) is a
setting for new mirrors only, and a stored value that cannot be read must create nothing; (C) the owner can
rename one mirror: `mirror -rename N -to "name"`, exactly one `channels.editTitle`, never by the automatic task;
(D) in the settle of a batch of unknown outcome, while a batch message has no message row on record nothing is
found by media. The coder's own report: `archiver/docs/progress/mirror-name-REPORT.md` (its departures and
doubts are claims to test, not facts).

**What a defect costs here.** This code acts for the owner on Telegram: a request sent twice, a second channel
created, a mirror that can never be found again after a lost answer, a setting that silently falls back, a
name in a log. The project's rules for such code: one request at a time, never repeated by itself; every wait
slept in full; an unknown outcome said and never guessed; fail closed on a stored value that cannot be read;
the owner's own marks and choices never undone; names, message text, ids and links never in a log line, an
error, a printed line or a counts file (lengths and fixed words only).

## Attack these, and anything else you find
1. **The schema step** (`internal/catalog/schema_mirrorname.go`, `catalog.go`): a file at the step before; run
   twice; a file that already has the column; rows whose name is empty afterwards; a read-only handle on an
   older file (the command makes its plan read-only before the owner's yes: every reader of a mirror row);
   the step's number is "21 on top of 18" on this branch and other tracks take 19 and 20 at the merge: what
   breaks if a file at 19 or 20 meets it, and what must the integrator change.
2. **A create whose answer was lost** (`schema_mirrorauto.go` `lostCreateSQL`, `lostChats`; `mirrorsettle.go`
   `MirrorNameOnRecord`, `MirrorCreateNotMade`; the turn's adoption in `internal/mirror/auto.go`): found by the
   stored name under the old rule and under a new one; the rule changed between the intent and the look; two
   rows that end up with the same name under two rules; a mirror renamed by the owner and a later lost create
   of the old name; an owner's chat that happens to carry the name.
3. **The rule** (`internal/mirror/name.go`, the plan in `mirror.go`, `step.go` `makeMirror`, `auto.go`): is there
   ANY path on which an unreadable or invalid stored rule creates a mirror under the default (the command, the
   automatic task, a nil `Settings`); the checks' edges (UTF-16 units, surrogate pairs, control and format
   characters, invalid UTF-8, a prefix or separator that makes the name empty or over Telegram's limit, a title
   cut inside a rune); is the name sent to Telegram always exactly the name stored on the row.
4. **The rename** (`internal/telegram/forward.go` `RenameMirror`, `internal/mirror/rename.go`,
   `internal/collector/mirror_name_cmd.go`, `catalog.RenameMirror`): more than one request on any path; any
   caller but the owner's command; what the catalogue says after a wait, an unknown outcome, a refusal, a
   stop in the middle, "not modified"; a mirror that is blocked, ended, protected, not created, or whose chat
   the owner removed; an error of Telegram's on the rename that marks the ACCOUNT refused or stores a wait that
   then holds creates and forwards (`answered`, the wait memo's kinds in `call.go`: read, do not edit); the
   service message a title edit leaves in the mirror and the settle; **privacy: the new name or the old one in
   any log line, error text, printed line, the status file or the hourly counts** (prove with a marker name).
5. **Part D** (`mirrorsettle.go` `weighBatch`): does a lost message stop every match by media, also under the
   owner's `-take`; does the result depend on the order of the batch; did the rule break a case that settled
   before (the tests `TestMirrorSettle...` in `internal/mirror` and `internal/catalog` are the earlier cases).
6. **The command** (`mirror_cmd.go`, `mirror_name_cmd.go`): combinations of the new flags with `-chat`,
   `-settle`, `-batches`, `-never`, `-allow`, `-list`; is the collector's lock held; is anything written before
   a yes or on a "no"; a catalogue older than the build.
7. **Tests that cannot fail:** for the main claims of the report, undo the code in your overlay (or reason from
   the test) and say whether a named test would notice.

## How to work
- Prove with probes where you can: invented data and the tests' injected clock only; nothing is run against
  Telegram; never open real data, `E:\T`, any `start.bat`, or anything under `%LOCALAPPDATA%\tgarchive`.
- In Git Bash: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then ONE go command at
  a time with `GOGC=25 GOMAXPROCS=1` and `-p 1`; named tests only (`-run`); compile a package's test binary once
  (`go test -c -overlay ...`) and run it with `-test.run` where that saves time. Never a whole run of
  `internal/catalog` or `internal/collector`, never the race detector, never Docker. The PC is shared: if a
  command is slow, wait; leave nothing running when you finish.
- Mark every finding CONFIRMED (a probe or an exact reading shows it; give the probe's name and what it printed,
  as counts and fixed words) or PLAUSIBLE (by reading; say what would confirm it), with a severity (high: a
  wrong request to Telegram, a lost or doubled mirror, a name leaked; medium; low), the file and line, and the
  smallest fix you would accept. Say also what you found sound, and what you did not check.
- Anything you write holds counts, sizes and timings only; invented names in probes.

## Hand-back
`REVIEW.md` in your folder, findings most severe first. Final message, under 30 lines: the number of findings by
severity and verdict, one line each for the confirmed ones, what you did not check.
