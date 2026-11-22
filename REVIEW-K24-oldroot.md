# Independent review of K24: the brought-in account and the old library as a read-only root (Core, 2026-11-22)

Reviewed `wip/core-oldroot` at 75c22c19 against 6aa225fb, in a detached scratch copy (`wt-core-oldroot-review`, plus a
second detached copy of the head, `wt-core-oldroot-review-head`, for the cost comparison; both removed afterwards).
Probes were added by `go test -overlay` from files in my scratch folder, every go command went through
`runs-core-k5/go1.sh`, and only named tests ran. No race detector, no Docker. Invented data only. Nothing touched the
coder's copy, a branch, a running program, the app's folder, E: or the NAS.

## Verdict

**May be listed after these fixes: F1 and F2** (both in `bi_reach_ai`, `internal/catalog/schema_broughtin.go:112`).
The shoulds (F3 to F6) may come in the same pass or go onto Core's list. The rest is minor.

The gate itself is sound. The old bytes stay exact evidence (probes P4), the step keeps the two-constant form, refuses
other versions and rolls back cleanly (P5), JoinUnder never lets a stored place climb out (P6), and the other tracks'
files changed only as listed.

## Findings

**F1 (must, CONFIRMED by P1): the revival counts the old account's chats as "collecting", so the outcome depends on
which account saw the file first.**
- Where: `schema_broughtin.go:112-120` (`bi_reach_ai` uses `collectedSQL`, `topics.go:68`, which looks at every message
  that carries the file, whoever sighted it).
- Old account first (in a channel only it has, collecting videos), then the live account in its own chat that collects
  no videos: the file ends up **wanted**, with a lane row for the live account.
- The reverse order (live first, then old) leaves it held as not collected, with no lane row. That is the ladder's
  answer, because `attach` skips `wantedAsMain` for a brought-in account.
- So a message of the old account makes a file wanted for a live account. This is the "reverse" case the brief names,
  and it means a download from a chat the owner left off.
- Fix: in `bi_reach_ai`, count as collecting only messages that a live account has a sighting of: add `AND EXISTS
  (SELECT 1 FROM sighting s CROSS JOIN account a ON a.id = s.account_id WHERE s.message_id = m.id AND a.brought_in =
  0)`. The sighting must be written before the reach row; `seenAgain` and `attach` already do that or must be made to.

**F2 (must, CONFIRMED by P2): the revival ignores a probable edge, so a probable copy becomes plain wanted.**
- Where: `schema_broughtin.go:115-119`.
- The probe: a parked file is given a probable edge to a saved file (`AddCopyEvidence`), then a live account reaches it
  in a collecting chat. Result: `wanted`, probable = 0.
- Control: the same file held as not collected, with the same edge, then collected through `wantedAsMain`. Result:
  `held`, "looks like a saved file", probable = 1.
- This breaks the hard rule (a probable copy is held, never before unique files). The bring-in writes 98,583 probable
  edges, and later copy layers add edges to files that may already be parked.
- Fix: use `wantedAsMainSQL`'s `back` expression in the trigger: held as a probable copy when an unreleased probable
  edge exists, otherwise wanted, keeping `released` and `fetch_real` as it does.

**F3 (should, CONFIRMED by P3): deleting a live account leaves files that only the old account still reaches
"wanted".**
- Where: `settle.go:451` (`deleteAccountChunk`, the `delReach` phase); nothing parks on a delete of `c_reach`.
- After `DeleteAccount` and the settle: the file is `wanted`, Totals counts 1 as waiting, it has no lane row, and its
  only reach row is the old account's.
- It also counts as "coming" for the twin rule (`twinLivePre` checks only `removed_at`), so a lesser twin would wait
  behind it for ever.
- The coder lists this and defers it to the 11-29 settle. But it is reachable today from the owner's own Delete, and it
  breaks "waiting in no count".
- Fix: in the `delReach` chunk (or an AFTER DELETE trigger on `c_reach` of a live account), park the chunk's files
  that only brought-in accounts reach now. Also make `twinLivePre` read `ra.brought_in = 0`.

**F4 (should, CONFIRMED by reading the code order): the collector writes into its staging folder before it checks
that folder against the old root.**
- Where: `collector/staging.go`. The order is: `MkdirAll(dir)` (181), the staging lock file `collector.lock` (187),
  the staging mark from `claimStaging`/`writeMark` (202). Only then does it read `OldLibraryRoot` (209), and
  `NewWriter` refuses the overlap.
- So a staging folder set to the old library, or inside it, gets a folder, a lock file and a mark file written there
  before the refusal.
- `SetOldLibraryRoot` (`schema_broughtin.go:316`) checks only the library, not the staging folder that the brief named.
- Fix: read the old root and run `checkOldRoot(old, lib, dir)` before line 181. Also refuse in `SetOldLibraryRoot`
  when the stored staging setting overlaps.

**F5 (should, CONFIRMED by P7): `libroot.Overlap` compares spellings, not folders.**
- Where: `libroot.go:116-140`.
- Reported as not overlapping when they are the same folder or one holds the other: the library against its own
  `\\?\C:\...` form; against `\\?\` of its sub-folder; against `\\.\C:\...`; against `\\localhost\C$\...`; and
  against a junction to its sub-folder.
- Case, a trailing separator, `sub\..` and trailing ". " are caught.
- Every store writer and the backup rely on this check (`store/oldroot.go`, `backup.go`).
- Fix: when both folders exist, compare resolved paths: `filepath.EvalSymlinks`, then strip `\\?\` and `\\.\`, then
  case-fold; or walk the ancestors with `os.SameFile`. Keep the text compare as the fall-back for a missing folder.

**F6 (should, PLAUSIBLE): the old account's chats also keep a live account's file wanted after the owner switches the
live chat off.**
- P1b: the live chat's videos are switched off and the settle runs. The file is still `wanted` with a live lane row,
  because an old-only channel that collects carries it. The control file goes to held.
- This is today's rule for several live accounts. With the old account it is fed by the old app's switches, which the
  design (section 3, rule 2) says "change nothing any new account collects".
- Fix: one decision for Core and B9, through the integrator. Either the settle's collected checks count only messages
  a live account sighted (the same clause as F1), or the bring-in writes chats that only the old account has with
  collecting off.

**F7 (minor, PLAUSIBLE): the lock file is named after the catalogue path's own spelling.**
- Where: `catlock.go:38` (`Path`).
- On Windows these spellings give the same file: different case, relative against absolute, `\\?\`.
- These give a different lock file, so both programs would hold "the" lock: a symbolic or hard link to the catalogue,
  an 8.3 short name in the last part of the path, or a trailing dot or space that Windows strips.
- Fix: name the lock after the catalogue's final path (`GetFinalPathNameByHandle` on the open file), or document that
  the bring-in must open the catalogue by exactly the path the launcher gives the collector.
- Release on panic is safe: the OS closes the handle when the process ends, and a second `release()` does nothing.

**F8 (minor): `HoldCollectorLock` is a method of an open Catalog, and `Open(path, false)` migrates first.**
- Where: `schema_broughtin.go:349`.
- A bring-in that opens read-write before it takes the lock changes the schema under a running collector.
- Fix: document "open read-only (or call `catlock.Acquire(path)`) and take the lock before `Open(path, false)`". Also
  document that `MarkBroughtIn` is called with the lock held and before the old account's first `SaveMessages`.

**F9 (minor): the server's sign-in door accepts a brought-in account.**
- Where: `server/signin.go:519` (`signInAccount` checks only `removed`).
- The collector refuses it (`ErrSignInNotLoaded`), so nothing reaches Telegram, but the page gives the wrong reason.
- `appshell` and the server's account lists still show it as an account (the coder lists this).
- Fix: refuse with its own error when `BroughtIn`.

**F10 (minor, CONFIRMED by P6): `JoinUnder` accepts elements Windows rewrites.**
- `a/x.` and `a/x ` open `a/x`; `a/.. ` opens `a/`.
- None of them climbs out (checked with `syscall.FullPath`). A stored place can name another file in the same folder.
- Fix: refuse an element that ends in a dot or a space.

**F11 (minor, note for the integrator):** a later step that rebuilds `c_supply_src` must start from
`supplySrcBroughtInSQL`, or the old account's lanes come back.

## Probes run (all through go1, named; all PASS as tests; the outcomes are the findings)

- **P1** `TestProbeK24OrderRevivalViaOldChat` (catalog): old first ends wanted with 1 live lane row; live first ends
  held as not collected with 0. F1.
- **P1b** `TestProbeK24LiveChatOffOldChatOn`: after the live chat is switched off, the file with the old account stays
  wanted (1 lane row); the control goes to held (0). F6.
- **P2** `TestProbeK24RevivalIgnoresProbableEdge`: revived plain wanted (probable 0); the control is held probable
  (probable 1). F2.
- **P3** `TestProbeK24DeletedLiveAccount`: after the delete, wanted, 1 counted waiting, 0 lane rows, 1 reach row (the
  old account's). F3.
- **P4** `TestProbeK24OldBytesEvidence`. All as required:
  - the same Telegram file as an old saved one: rung 2, saved;
  - another file of the same size: the exact check returns the old file as its candidate with `Old = true`;
  - the same SHA-256 at save: duplicate, linked to the old row;
  - a parked file that the old app then saves (`ImportSaved`): its collector row is removed and it is saved.
- **P5** `TestProbeK24StepRollback`:
  - a file at v28 whose step fails (a table where the view should be): Open fails, the file stays at v28, with no
    column and no `bi_` triggers;
  - the step on a v3 file is refused with its own words.
- **P6** `TestProbeK24JoinUnder` (libroot, Windows): every climbing form in the list is refused: `..`, `.\`, mixed
  slashes, `C:x`, `c:../x`, `\\?\`, `//?/`, UNC, a leading `/`, streams (`::$DATA`), NUL, `CON`, `COM¹`, `CONIN$`,
  empty elements. Every accepted form, checked with `syscall.FullPath`, stays inside the root (trailing dots and
  spaces, `NUL.mp4`, `COM1.jpg`, `CONOUT$.x`, full-width dots, the division slash). F10.
- **P7** `TestProbeK24Overlap`: the misses of F5. Case, a trailing separator, `..` and trailing ". " are caught.

Not re-run: the coder's own store, backup, collector and watchdog tests. I read the code they cover. The writers
(writer, start-up sweep, copier, linker) all join under staging or the library through `joinRel` and refuse an
overlapping old root. The linker also refuses a source or target under it, `LinksDue` drops old-placed files, and the
backup refuses `-to` and `-work`. Those claims hold, apart from F4 (collector order) and F5 (path spellings).

## The measured trigger cost (one run each, a busy PC: "looks like")

The shape: 300,000 media rows for the old account (240,000 saved with a file row each), 300,000 reach rows and 60,000
collector rows (40,000 wanted, 20,000 held probable), written in chunks of 2,048 (the bring-in's largest). Then 10,000
new files of a live account, then 10,000 live reach rows onto the old account's files. Raw SQL, so the trigger and view
cost is isolated. Plus 20,000 messages of the old account through the ladder (`CatalogueMessage`, same chunks).

| Step | Head 6aa225fb (no step) | Branch 75c22c19 (marked first) |
|---|---|---|
| Old account fill (per 1,000 media) | 46.3 ms (13.9 s) | 70.0 ms (21.0 s) |
| Live account, new files (per 1,000) | 51.2 ms | 82.5 ms |
| Live reach onto old files (per 1,000) | 11.4 ms | 32.3 ms (each one runs the revival) |
| Old account through the ladder (per 1,000 messages) | 406 ms | 523 ms |
| `MarkBroughtIn` after an unmarked fill (300,000 reach rows) | n/a | 1.0 s, one transaction (40,000 parked, 0 lane rows) |
| A full read of `c_supply_src` | 93 ms (80,000 rows) | 88 ms (10,000 rows) |

- About 0.03 ms more per live file inserted, for as long as the app runs.
- About 0.12 ms more per old message in the bring-in: roughly +36 s over 310,000 media.
- No read grows with the archive: every trigger lookup is by key.
- Acceptable. The live-insert overhead comes mostly from `bi_want_ai`'s WHEN, which is evaluated on every wanted
  insert once any account is marked.

## Other tracks' files

These changed only as the report lists, and the changes are correct:
- the client's `schema_act.go`: three account checks gain `brought_in = 0`;
- the server's `accounts.go`, `overview.go`, `mirrors.go`: the brought-in account is left out of the fetch counts and
  of "only this account's", and gets no lane group and no mirror row;
- the mirror's `newChatPolicy`;
- `supply.HandOver`.

Both reads of the column are on the writer's file or on a file this build's step has reached. Older files are refused
by the read-only schema door.

---

## Second look: the fix round (`wip/core-oldroot` b3c6e10f; fixes 63aa27dc, the merge 43cef593 of the head e34f4f64, the test change), 2026-11-22

**Verdict: may be listed after one fix: S1** (`seenAgain`, `internal/catalog/ladder.go:196`). S2 to S4 are shoulds;
S5 is minor.

F1 to F3 and F6 are fixed (all my probes re-run, below). A catalogue with no brought-in account behaves as before: every
new clause opens with "is any account brought in", which is false there. The merge added only the overview's
not-added rule, and it is correct. One fix of the round opened a new hole (S1).

Where it ran:
- a detached scratch copy `wt-core-oldroot-review2`, plus `wt-core-oldroot-review2-head` at e34f4f64 for the timing
  comparison; both removed;
- every go command through `runs-core-k5/go2.sh`, probes by `-overlay`, named tests only, invented data.

### Findings

**S1 (must, CONFIRMED): since F1's fix, a live account's later sighting of a collecting message changes nothing.**
- Where: `ladder.go:196` (`seenAgain`, rung 1). It adds the sighting and the reach and judges no file again.
- Before the round the revival covered this case; now "collected" depends on who sighted the message, and a new live
  sighting is a new fact that nothing acts on.
- Probe `TestProbeK24bSeenAgainAfterNotCollected`. The old account catalogues a file in a shared channel that collects;
  the live account meets it first in its own chat that does not collect, then reads the channel's same message:
  - old account marked: held as not collected, 0 lane rows;
  - the same order with the old account as an ordinary account (control): wanted, 1 lane row.
- So a file a live account wants by the older rule is lost.

**S2 (must, the same root and the same fix, CONFIRMED): the old app's holds stay unsupplied after a live account reads
the same message.**
- Probe `TestProbeK24bOldHoldThenSeenAgain`. `HoldProbable` holds a file only the old account carries: probable = 0,
  which is correct.
- The live account then reads the same channel message (rung 1): still probable = 0, 0 lane rows. The control has
  probable = 1 and 1 lane row.
- Only a new live message carrying the file mends it (probable = 1, 1 lane row).
- A probable copy is held, never lost; this one would never be supplied.

Fix for both: when `seenAgain` writes a new sighting for a live account (`res.NewSighting`) and some account is marked,
judge again the message's files. Run what attach's "seen again" branch runs (`wantedAsMain` when the chat collects the
kind and the topic passes; the always-download unskip), or the same as one statement over the message's attachments.

**S3 (should, CONFIRMED on a local disk): `libroot.Within` now costs about 4 ms a call, and the linker calls it for
every link.**
- Where: `store/links.go:74` (a link's source) and `:113` (every target).
- Probe `TestProbeK24bReal`: 1,000 calls took 3.8 s for a target that does not exist yet and 4.4 s for an existing
  folder, both on the local temp disk.
- Each call runs `Real` on both paths (an `Lstat` per path element, the link walk, `GetLongPathName`), then `os.Stat` up
  the ancestors.
- On the NAS over Wi-Fi each of those is a network round trip, on the copy path, where fixed steps already took 42% of
  copy time (A7 §4). The NAS cost is PLAUSIBLE, not measured: never touch the NAS.
- Fix: resolve the old root once in `NewLinker`. The library was shown not to overlap it at start (`checkOldRoot`), and
  every target is joined under the library (`joinRel`). So per link, either drop the check or compare text only
  (`withinText`) against the resolved root. Keep `Real` and `os.SameFile` for the checks made once (start, settings,
  backup).

**S4 (should, PLAUSIBLE): F10's fix (my own suggestion) may refuse places the old app really wrote.**
- Where: `libroot.go` `JoinUnder` now refuses an element ending in a dot or a space.
- The old app's `safeComponent` (`core-service/internal/download/library.go:457`) trims spaces and dots first, then cuts
  the name to 120 bytes, so a cut folder name can end in a space or a dot.
- Such old files would read as missing: the viewer cannot show them, and the exact check says "unknown", so the live
  file is downloaded instead of linked.
- I withdraw F10 as written. The count needs the real archive, and I did not read it (never `E:\`).
- Fix: B9 counts, on its copy of the old archive, the old places with such an element (a count only). If any exist,
  open them as the old app wrote them (the `\\?\` long form keeps the name as stored) rather than refuse them. Keep the
  refusal of "." and "..".

**S5 (minor, CONFIRMED): `catlock.Path` still gives two locks for a trailing dot and for a hard link.**
- Probe `TestProbeK24bLockSpellings`: `catalogue.sqlite.` gets its own lock file and both holds succeed; a hard link to
  the catalogue does too.
- The same lock is held, before and after the catalogue exists, for: a junction folder, a junction to a junction, the
  `\\?\` form, a relative spelling and upper case.
- Fix: in `Real`, drop the final element's trailing dots and spaces on Windows, as Windows does. For hard links, name
  the lock by the file's identity (volume serial and file index) once it exists, or document the limit.
- The probe's FAIL line is its own clean-up: a second lock it did not release. It is not a defect of the code.

### Probes re-run and their results

| Probe | At 75c22c19 | At b3c6e10f |
|---|---|---|
| P1 order | old first: wanted (1 lane) | held as not collected (0 lanes), either order: **F1 fixed** |
| P1b live chat off | stayed wanted | held, as the control: **F6 fixed** |
| P2 probable edge | plain wanted | held, "looks like a saved file", probable 1, as the control: **F2 fixed** |
| P3 deleted live account | wanted, 1 waiting | parked, 0 waiting, 0 lane rows: **F3 fixed** |
| P4 old bytes | rung 2, `Old` candidate, linked at save | unchanged |
| P5 step | refusal and rollback at v28 | the same at v31 (the step is now 32) |

`libroot.Real` and `Overlap`:
- Caught: a junction, a junction to a junction, a path under a junction that does not exist yet, a short (8.3) name,
  `\\?\UNC\localhost\C$`, forward slashes, trailing ". ".
- A junction loop ends after 34 ms and overlaps nothing.
- A path where nothing exists returns unchanged with no error.
- Not tested: a relative symbolic link (it needs a privilege this PC's test process does not have). The code joins a
  relative target to the link's own folder, which is right.

### The collect check's cost with an account marked (`account_brought_in`, `liveCarrierSQL`)

- `TestProbeK24bSettleCost`: 20,000 files in a live chat, half also carried by the old account's chat. The chat's
  videos switched off, then on, with every chunk settled.
- Unmarked: 938 ms off, 1,044 ms on. Marked: 1,237 ms off, 1,383 ms on, about 32% more.
- One run each: "looks like". Every lookup is by key: the index answers "is any account brought in" in one seek, then
  one seek in sighting's key per carrying message.

### The two timing tests, on the same PC, against the base head

| Run | `TestGiveBackRecoverMany` | `TestTopicSettleAtSize` (switch to chosen / back; longest chunk) |
|---|---|---|
| branch 1 | PASS, 928 ms | PASS, 15.8 s / 12.0 s; 218 ms |
| branch 2 | PASS, 615 ms | PASS, 11.1 s / 11.8 s; 61 ms |
| head e34f4f64 1 | PASS, 999 ms | **FAIL**: a chunk held the writer 254 ms (16.0 s / 13.2 s) |
| head e34f4f64 2 | PASS, 1,008 ms | PASS, 14.6 s / 15.1 s; 224 ms |

The base head trips the same limit under the same load. The branch is not slower. The trips are the PC's load, not
K24.

### The head merge

- `overviewneeds.go` `notAddedSQL` reads a brought-in account as one that never reads, as `ListChatReads` does: correct.
- The step now follows the mirror's topic step. It rebuilds the view and the twin's two account triggers last. The
  merged steps (mirror repeats, video lengths, forum topics) rebuild neither.
- No new reader of `removed_at` that leaves a brought-in account in came with the merge. The ones left are those listed
  in the first round: the UI's account lists, the sign-in door, the demo.
