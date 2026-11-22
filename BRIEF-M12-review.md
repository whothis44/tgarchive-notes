# Brief for the narrow independent review of M12: the cap on new mirrors in 24 hours as a stored setting (session M-6, 11-16)

For one Opus reviewer (high effort), who did not write the code. **Head under review: `wip/mirror-cap` 52696bad
(five commits on the main head 2b557601).** Read-only on the frozen copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review14-tree` (detached at that head); your own folder is
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review14-scratch`. Findings are proved by probe tests in your
folder loaded with `go test -overlay`, never by editing the tree; each finding is marked confirmed (a probe
shows it) or plausible (by reading).

**Rules:** every go command goes through the track's lock script, never directly:
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-mirror-m6/go1.sh /c/Users/trabi/Claude/Projects/Telegram/wt-mirror-review14-tree/archiver go test -overlay <your file> -run 'TestName' -timeout 15m ./internal/mirror/`
(it waits for a lock and for free memory, possibly many minutes: run it in the background and read on
meanwhile; exit 98: try again later). Named tests only, a `-timeout` on every line; no whole run of
`internal/collector` or `internal/catalog`, no race detector, no Docker. Nothing against Telegram; no installed
program is started. Counts, sizes and timings only in what you write: never a name, a text, a path of the
owner's or a Telegram id.

**Read first:** `BRIEF-M12-new-per-day.md` in the project folder; the coder's
`archiver/docs/progress/mirror-cap-REPORT.md` in the frozen copy; `git diff 2b557601 52696bad`. **Read the code
around the difference, not only its changed lines** (the last piece's one high defect sat in a reader the
difference did not touch): `internal/mirror/auto.go`'s `Turn` from where the cap is read to where a create is
decided (`createAt`, every place a create can start in one turn), `door.go`'s `PagePlan` and `Want`,
`internal/collector/mirror_auto.go`'s flags and set-up, `mirror_door.go`'s doors and `MirrorTask`.

**What this code decides:** how many channels the app creates in the owner's account in 24 hours. Too many is
the harm; a cap that reads as absent is the worst case.

**The questions, each with a probe where one is possible:**
1. **Any path on which more creates happen in 24 hours than the cap in force:** within one turn (several wants
   due at once, with 1 below the cap); across the automatic task and an owner's want; right after the cap was
   lowered; with the flag; two accounts (the setting is one row for the catalogue, the count is per account:
   is that what the brief says and what the code does?).
2. **A stored value that cannot be read** (garbage, 0, 51, " 20", "020", an empty value): 5 in force at the
   turn and at the plan, never 20, never no cap; said once a session and not once a turn; the facts' door
   says "unreadable" and still lets the page set it anew. **A settings read that fails** (an I/O error): no
   create in that turn. **`Settings` nil** in production code: can it be (then 20 is in force silently)?
3. **No restart needed:** a value set through `SetMirrorNewPerDay` is the cap at the task's next turn and at
   the next plan; anything that still holds the old number (a copy made at the start, a cached plan, the
   door's token).
4. **The flag for this run:** given: used exactly, the stored row not read, the set door refuses and writes
   nothing; not given: the stored setting; given as 0, 51 or text: the start refused; a run WITHOUT
   `-auto-mirror` but with the flag given: which cap bounds the owner's wants, and what the start says.
5. **`createsRoom`** (the coder's departure): the time it gives when the cap is full, exactly; when the cap was
   lowered below the used count (the k-th oldest's leaving); several creates in one second; no create; its
   catalogue reads when the cap is not full (expected: one). Compare with the old code's answer where the
   cap was not lowered: any difference.
6. **Lowering undoes nothing:** no mirror, want or row is ended or changed by a lower cap.
7. **The doors:** range refusals in fixed words, nothing written on a refusal; the facts when nothing is
   stored, a value is stored, the value is unreadable, the flag holds; the mirror page's per-account numbers
   (`CreatesDay`, `CreatesCap`, `CreatesRoomAt`) carry the value in force.
8. **F2, the set-up's fact (`autoSession.setUpFailed`, `MirrorTask.AutoSetUpFailed`):** set on every kind of
   failed set-up but the missing secret, cleared by a success, never a word of the owner's data in it; read
   and written under the same lock (name every reader and writer); `errAutoRecord` on the sentinels' line:
   what `errWord` gives for it now and gave before, everywhere it is used.
9. **Tests:** the one changed test (`TestMirrorAutoNewPerDay`: the flag pinned to 5) still tests what it
   tested; any other test that passed with 5 as the default and now passes for another reason (search the
   mirror's and the collector's tests for the cap and for 5 creates); test functions removed or renamed
   against 2b557601 (0 expected).
10. **Planted changes:** take out one rule line at a time (six of your choice: the careful value, the flag's
    precedence, the read at each turn, the door's refusal under the flag, the room's loop, the fact's
    clearing) and say which planted change no test catches.
11. **Privacy** of every new log line, event and sentinel; constant format strings.

**Your result:** `REVIEW.md` in your folder: one line at its top ("may be listed", "may be listed after these
fixes", or "not yet"), then the findings by weight (high, medium, low), each with its probe's numbers, then what
you checked and found sound, then what you did not run. Your final message to me: that first line, the
findings in one line each, and the runs with their exit lines.
