# Review G15: the Staging page's tests and this PC's disk (independent, 11-16 18:13)

Reviewed: `wt-pages-free`, branch `wip/pages-free`, head 508b4de9 (106b890f the seam and tests; 508b4de9 the
busy flag's order), against the base 78739d59. Read-only: `git status` in the copy is clean after the review,
`gofmt -l` on the seven changed Go files prints nothing. Probes are plain files in
`wt-pages-review-g15-scratch`, loaded with `go test -overlay`; one go command at a time, `-p 1`, named tests
only, free memory 4.7 to 6.3 GB before each. No process of mine left (the three `go` processes running at the
end are other sessions': collector, supply, catalog).

## Probes run

| Probe | Overlay | Tests run | Result (decisive line) |
|---|---|---|---|
| P1 | `freeBytes` answers 1 | pattern A (below) | exit 1, ONE failure: `TestStagingFreeRealCall`: "free space of a folder that does not exist: 1, want -1" |
| P2 | `freeBytes` answers -1 | pattern A | exit 1, ONE failure: `TestStagingFreeRealCall`: "free space of a temporary folder: -1, want above 0" (also lines 66, 73) |
| P3 (control) | P1 plus `freeWithin` ignoring the seam | pattern A | 10 failures: the brief's five (`WaitCauses`, `CopiersFromMemory`, `GaugesWhenNeeded`, `HoldsUnread`, `LiveReadsNoTable`), the four new tests, `NumbersSayWhatTheyCount`: the overlay reaches the code the probes mean to reach |
| P4 | first round's order (`defer` clear after the send) | `TestStagingFreeBackToBack$`, `-count=10` | 10 of 10 failed, "reading 15 of 5000 back to back: -1" (earliest; latest at 497) |
| P5 | none (the head) | `TestStagingFree` and `TestStagingNumbersSayWhatTheyCount$`, `-count=30` | ok, 8.5 s, while three other sessions' go tests ran on the PC |
| P6 | `noRoom` with `<=` | `TestStagingFree` | `TestStagingFreeFromSeam` fails: "seam 53687091200 against 50 << 30 kept free: verdict "no room"" |
| P7 | `readStaging` takes -1 as 0 bytes, known | `TestStagingFree` | `TestStagingFreeNotKnown` fails: "free not said: {... Bytes:0 ... Known:true ...}" and "verdict "no room"" |

Pattern A: `-run 'Staging|Overview|Mirror|Settings|HeldStop|Minors|Verdict|Release|WantAgain|StuckAdvice'`. It is
the brief's pattern plus three words, because the brief's pattern misses four tests that use the staging rig
and read the page: `TestReleaseNothingHeld`, `TestWantAgainSaysItsCost`, `TestStuckAdviceTable`
(`staging_fix_test.go`) and `TestReleaseWantAgainFromPage` (`staging_test.go`). Under pattern A, `go test
-list` names every test that builds the rig, a `Server` with `Config.Staging`, or calls
`stagingNow`/`readStaging`/`freeWithin`. It also names the Overview, Mirror and Settings tests and the
at-size tests (`TestStagingCostAtSize`, `TestStagingCostAtSizeMemory`, `TestOverviewCostAtSize`), which ran.
`TestStagingLiveLook` and `TestStagingPageLook` were skipped as usual (each needs its variable). Each run of
pattern A took about 32 to 36 s.

## Question 1: places a `Server` is built, and what they read

| Place | Free space |
|---|---|
| `staging_test.go` `newStagingEnv(t, true)` (every rig test; `staging_poll_test.go`'s direct `readStaging` too) | seam set (`fixedFree`, 1 << 40) |
| `newStagingEnv(t, false)` | no `Config.Staging`: `readStaging` never calls `freeWithin` |
| `mirrors_test.go` 1050 `TestMirrorHeldStopRefusesChanges` | seam set |
| `staging_fix_test.go` 386 `TestHeldStopRefusesStagingChanges` | seam set |
| `staging_live_test.go` 474 `TestStagingLiveLook` (skipped unless its variable) | seam set |
| `staging_look_test.go` 43 `TestStagingPageLook` (skipped unless its variable) | seam set; its "without room" phase keeps 1 << 50 free, above the seam's 1 << 40, so it still shows no room |
| `staging_free_test.go` 57 `TestStagingFreeRealCall` | real call, asserted on purpose (> 0, see minor 1) |
| every other `New(` in the package's tests (`helpers_test.go` `newEnv`/`newProgramEnv` and the demo's server, `program_test.go`, `program_fix_test.go`, `pause_test.go`, `signin_test.go`, `mirrors_test.go` 32 and 935, `clicks_test.go`, `guard_test.go`, `api_test.go`, `security_test.go`) | no `Config.Staging` (the only way `s.staging` is set, `server.go` 204): no free-space read; the Overview's Staging region is absent |
| `settings.go` 231 `checkLibrary` (`/api/library-check`, the Settings page) | real call, no assertion on it: `settings_test.go` 88/92 and `crosssite_test.go` 106 assert `Writable`, `Problem`, the probe count only |

The coder's lists of what was changed and what was left match the code. P1 and P2 confirm that no test
except `TestStagingFreeRealCall` changes its result with the disk's answer. Nothing in `New` or elsewhere in
the server starts a reading before the tests set the seam: the server's only goroutines are the demo's loop,
the read estimate (`reads.go` 215) and `freeWithin`'s own. Disk speed and the temporary folder's place no
longer matter either: with the seam, the call is instant and ignores the path. Outside this package I found no
collector or launcher test that asserts on an amount of free space. `pages_g5_test.go` 78 accepts any verdict
but "library away", and the launcher's tests check only that the words are shown.

## Question 2: product behaviour

With the seam nil, `freeWithin` calls `freeBytes`, as before. No non-test source in the module sets
`stg.free`: I searched every `.go` file for `stg.free`, `.free =` and `stagingKeep{`, and the only setters are
the six test places above. The field is read on the caller's goroutine, after the CAS and before the
goroutine starts. The goroutine uses its own copy of the function, so a test that changes the field while an
earlier call still runs (`TestStagingFreeBackToBack` after its bounded call) does not race: the old call
never reads the field again. The tests set the field only between readings that are synchronous on the test
goroutine (`e.call` serves through the handler in place, and `freeWithin` is called directly). Nothing reads
the field from another goroutine at that moment. The one change in behaviour is the order inside the goroutine.
A panic in `free` no longer clears the flag through `defer`, but a panic in that goroutine ends the program
either way, so nothing changes in practice.

## Question 3: the order (flag cleared, then the answer sent)

- **Answer in time:** `free` returns, the flag is cleared, then the answer is sent on the buffered channel and
  received. The clear happens before the receive, so the next call by the same caller finds the flag free
  (P4 shows the first round's order failing this 10 of 10 times; P5 shows the head passing it 30 of 30).
- **The bound passes first:** the caller answers -1. The flag stays set until `free` returns, then it is
  cleared and the send lands in the buffer, which nobody reads. It does not block, and the goroutine ends.
- **The call never returns:** the flag stays set for good, and every later call answers -1 at once. This is
  the same as before and is the guard's purpose (review G5, minor 14): no second call while a disk does not
  answer.
- **A second caller during a slow call:** the CAS fails and it answers -1 at once, as before.
- **Can a caller holding an answer meet a busy flag?** It cannot meet its own call's flag. It can meet another
  caller's flag if that caller took it between the clear and the send, which is correct.
- **Two real calls at once?** No. The flag is cleared only after `free` has returned, in both orders, so at
  most one call runs at a time, exactly as before.

## Question 4: the new tests

- `TestStagingFreeFromSeam`: it fails if the seam is ignored (P3) and if the comparison is wrong (P6: the
  case at exactly 50 << 30 catches `<=`; the cases at 49 << 30 and at 1 catch a reversed comparison). It
  times nothing.
- `TestStagingFreeNotKnown`: it fails if -1 is taken as 0 bytes (P7: the number, the verdict, the noting of
  no room and the library's clause all fail). It times nothing.
- `TestStagingFreeBackToBack`: it fails with the first round's order (P4). Its timing: the bounded call
  answers -1 whatever the time, because the call is blocked. The refused call must return within 500 ms (a
  CAS and a return). The released call must clear the flag within 2 s. Readings with an instant seam must
  arrive within the 2 s bound. These margins are generous: 30 of 30 runs passed with three other go test
  processes running.
- `TestStagingFreeRealCall`: it fails if the real call stops being the default (P2). Its assertions hold on any
  PC whose temporary folder has more than 0 bytes free to the user, and whose disk answers within 2 s
  (minor 1).

## Findings

1. **Minor, plausible (read, not run).** `TestStagingFreeRealCall` asserts `freeBytes(t.TempDir()) > 0`, and
   that `freeWithin` and `readStaging` read more than 0. A real call that works can answer 0: a full disk, a
   per-user quota at its limit, or Linux under the full runs' Docker containers, where tests run as root and
   `Bavail` is 0 once only the root-reserved blocks remain while root can still make the folder. So the test
   is not true "including one with very little room": it fails at exactly 0 bytes free to the user.
   `>= 0` (known, any amount) would say what the brief means by "known".
   Also, if the first real `freeWithin` ever takes more than 2 s, the `readStaging` right after it finds the
   flag still set and fails. This is unlikely, and it is the guard working as meant. Not worth a change.
2. **Minor, confirmed by reading the report.** In `archiver/docs/progress/pages-free-REPORT.md`, the
   paragraph "Seen, not changed" still says the order was left as it was ("Product code: left as it is"),
   and the next section says it was changed. A reader of the report alone gets two answers. Mark that
   paragraph as superseded by the second round.
3. **Minor, wording.** The comment on `freeWithin` says "a caller holding an answer never finds the flag
   still set". That is true of its own call only: another caller's call may hold the flag (correctly). Say
   "its own call's flag".
4. **Minor, trivial.** `TestStagingFreeNotKnown` line 131: `Kind == VerdictNoRoom || Kind != VerdictWaiting`.
   The first clause is implied by the second.

Must fix: 0. Should fix: 0. Minor: 4 (none needs doing before the merge).

Facts from the hand-backs, checked: the first round's order fails `TestStagingFreeBackToBack` every time
(here 10 of 10, the earliest at reading 15). With the seam ignored, the rig's tests fail on the disk's
number (here, with the disk made to answer 1 byte, the brief's five tests and five more).

Not checked: the `!windows` real call (`Statfs`: -1 for a missing path, more than 0 for a temporary folder)
was not run, because the review was on Windows only. A disk that is really full was not tried. The two look
tests (`TestStagingLiveLook`, `TestStagingPageLook`) were read, not run.

may be listed
