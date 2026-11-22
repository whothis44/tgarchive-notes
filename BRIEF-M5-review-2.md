# Brief: the second pass of the independent review of M5 (the fix round, `02abe15..fb8ab31`)

Written by the integrator, 11-15 evening. You are a challenger, not the author. **Read-only: edit and commit
nothing** in `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-name` (branch `wip/mirror-name`, head fb8ab31,
clean; Go module in `archiver/`) or in any other copy. Your own folder:
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review8-scratch` (make it). Your report goes there as
`REVIEW-2.md`. Probes are test files in your folder, loaded with `go test -overlay` (an overlay file mapping a
path inside the copy's package to your file); never written into the copy.

## What you are checking
The first review is `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review7-scratch\REVIEW.md`, with its probes
(`zz_m7probe_test.go`, `zz_m7cat_test.go`, its three overlay files, `mut\`). Its brief, for what the piece is and
what a defect costs: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-M5-review.md`. The fix round's brief:
`BRIEF-M5b-fixes.md`; the coder's report: `archiver/docs/progress/mirror-name-REPORT.md` on the branch (its
claims are to be tested, not believed).

The fix round is three commits, `git -C wt-mirror-name diff 02abe15 fb8ab31` (17 files, about 300 changed lines
outside tests): `catalog/schema13.go`, `schema_mirrorname.go`, `mirrorsettle.go`; `mirror/auto.go`, `name.go`,
`rename.go`, `step.go`, `mirror.go`; `collector/mirror_cmd.go`, `mirror_settle_cmd.go`, `mirror_auto.go`,
`mirror_name_cmd.go`. No reviewer has read it; the track's own session read it and ran 11 of its tests by name.

## Do, in this order
1. **Each finding of the first review: FIXED, NOT FIXED or PARTLY, with the evidence.** Run the first
   review's probes again on fb8ab31 (through overlays of your own that point at your copies of its probe
   files; adapt a probe only where a signature changed, and say so). The one that mattered most: two rules
   could give two live rows of one account the same name, so a create whose answer was lost could adopt the
   other source's channel.
2. **Attack the fix round's own new code.** In particular:
   - the number's loop that skips a taken name (`name.go`, `schema13.go`): can it still hand out a name a live
     row of the account holds (a row made between the look and the write; a renamed mirror; a row of another
     account; the 10000 bound); can it loop without end;
   - a rename refused because a live row holds the name: checked in the same transaction as the write, or can
     two renames, or a rename and a create, still end with two live rows of one name;
   - the automatic task's hold while the rule cannot be read (`auto.go`): does anything still create, mark a
     chat, or spend a request in that state; does it go on by itself when the rule reads again; does a hold
     starve forwards of mirrors that already exist (it should not);
   - the text check on a rule or a new name: what passes that should not (invisible characters, odd spaces,
     a space at an end), and what the source's own title in the middle of the name can still carry;
   - the settle's narrowed rule (a batch message with no message row on record): with `-all-messages`, a text
     message has no media by nature: is "found by media" now blocked exactly when it must be, in both callers;
   - "flags never dropped beside `-never`, `-allow`, `-list`" (`mirror_cmd.go`): does any combination now send
     a request that the old code did not, or refuse a command line the owner has used (`-chat N`,
     `-chat N -batches 5`, `-settle N`, `-settle N -take arrived|not-arrived`).
3. **The rules this code must keep** (any breach is a finding): one request at a time, never repeated by
   itself; every wait Telegram states slept in full; an unknown outcome said, never guessed; a stored value
   that cannot be read creates nothing and never reads as "empty" or as the default; the owner's "never
   mirror" mark checked before every request; nothing renamed, created or forwarded without the owner's yes
   except what the automatic task was switched on for; names, message text, ids and links never in a log
   line, an error, a printed line or a counts file.
4. **The schema number.** On the branch the step is 21 on top of 18. The integrator will merge it as step 20
   on top of a step 19 that adds one nullable column to `chat` and one trigger. Say exactly which lines and
   which tests name 21 or depend on a gap, and whether the step is safe to run on a file at 19.

## Bounds
- Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then every go command with
  `GOGC=25 GOMAXPROCS=1` and `-p 1`. Named tests only (`-run`), in `internal/mirror`, `internal/catalog` and
  `internal/collector`; **no whole-package run, no race detector, no Docker, no `go vet` over many packages**.
  Other sessions' test runs share this PC: before each go command measure free memory (PowerShell,
  `Get-CimInstance Win32_OperatingSystem`), and wait if less than 2.5 GB is free.
- Invented data only. Open no real catalogue, no file under `E:\T`, no file under `a3\`, nothing of the owner's
  archive. Nothing is sent to Telegram: the tests' fake server only.
- In your report and your final message: counts, timings and fixed words; no chat names, message text, ids,
  links or paths of this PC outside the project folder.
- Mark each finding **confirmed** (a probe shows it) or **plausible** (by reading), with a severity (high: a
  second channel, a request sent twice, a wrong channel adopted, a name in a log; medium; low), the file and
  line, and the smallest fix you see. Do not fix anything.
- About an hour. If you run out of time, write what you did not reach.

## Your final message
The verdict in one line (may it merge as it is, or is a round needed), then the findings as a short list with
severity and "confirmed" or "plausible", then what you did not check. The full text is `REVIEW-2.md`.
