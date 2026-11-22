# Review C26: lesser copies wait behind the best, on by default

Reviewer: independent, Opus 5.5, 2026-11-21. The piece: branch head 4c280c09 (base 6aa225fb), read in the detached
copy `wt-copies-review30-scratch`. Brief `BRIEF-C26-twin-on.md`; the coder's report
`archiver/docs/progress/copies-twin-on-REPORT.md`. Nothing tracked was edited in the copy. The probes are in the
uncommitted file `archiver/internal/catalog/zz_probe_c26_test.go` there; the overlays and mutated copies are in my
scratchpad. Every go command went through `runs-copies-r26/go1.sh`, and the logs are in `runs-copies-r26/`. Only named
tests were run. No race detector, no real catalogue, no Telegram request. All data is invented.

## Findings in short

| # | Finding | Real? | Severity |
|---|---|---|---|
| F1 | The owner's "different" on a waiting pair is ignored by the next arrival: the lesser file waits behind the very file the owner said it differs from | **real** (probe fails) | **must fix** (small, in `twin.go`) |
| F2 | The ten tests that failed with the switch on fail only on their own setups; each end state holds with the switch on | not real | none |
| F3 | Pin 2's "rung 2" world is a normal save, not a save as a link | real (test wording) | note |
| F4 | Nothing outside `internal/catalog` reads the switch. The owner has no door to store the "0" that now means off | no caller relies on the old meaning; the missing door is real | should fix (pages or copies settings, not C26's files) |
| F5 | The line added to `exact/wire/review2_test.go` | needed | keep it |
| F6 | ROADMAP.md row "Confirm or release…" still says "Not built: lesser copies behind the best" | real (stale doc) | note |

## 1. The ten tests with the switch on (the main question)

**How I ran them.**
- I used an overlay of `lookalike_rule_test.go` and `checkfirst_test.go` without their `SetTwinHold(false)` line
  (`ov/on.json`).
- Run `on1` (49 s) reproduces the coder's `cand1` exactly: the same 10 top-level tests and the same subtests fail. The
  six `checkfirst_test` tests pass on the default; their line is only a precaution.
- Then each failing scenario was rebuilt on the default (no row) and carried to its end. The door
  (`SettlePairPending`) runs after every save. I checked the original test's own expectations at the end, plus "never
  left waiting, skipped or gone". Run `probe1`: every scenario passes except F1's.

**Two kinds of setup failure explain all the failures. Neither is a program defect.**
- **The file the test means to save waits behind the other** ("claim of N refused", "setup: saved video 1 is held").
  - Two look-alikes are queued at once, and the lesser one now waits. That is the feature.
  - `newLookWorld` posts the "saved" videos in one message and then saves them. With the switch on, the second waits
    behind the first, so it cannot be claimed.
- **A rung 6 hold expected at the save comes one step later, from the door.** For example "want held; got held/looks
  like a better copy that is still queued".
  - The lesser file waited. At the save it goes to `c_pair_pending`. The door then judges it by rung 6 against the
    saved files.
  - Right after the save the test still sees the wait. After the door it sees the expected hold.

| Test (failing subtests) | What failed on | With the switch on, to the end (probe) | Verdict |
|---|---|---|---|
| `TestHoldAtSave` / the better one saved | setup: the worse one waits | The door holds it as a probable copy, with the identical evidence string. at-save counts [0 0 0], twin Reheld 1 | test's assumption |
| / the worse one saved first | claim refused (it waits) | Real-world form: the worse one in transfer before the better one comes. The better one stays wanted, no edge | test's assumption |
| / a saved file of its byte size (marked) | waits | After the door: wanted, ReasonLookAlikeCheckFirst, marked, 1 edge. ExactCandidates: HoldUnlessSame, LookAlike = the saved file, 1 candidate | test's assumption |
| / the same, the check off | waits | After the door: held as a probable copy | test's assumption |
| / 12 threshold cases | waits, or the one to save waits | All 24 thresholds run both ways ("queued first" where the one to save does not wait, and "saved one in transfer first"). **Every case ends exactly as the table says, held or wanted, with 0 or 1 edges.** Where the lesser one waited behind a better one that rung 6 does not cover (pixels, 90% of bytes), the door made it wanted | test's assumption |
| / the match after twenty | claim refused | q is held against the saved one. None of the 20 near ones has an edge. 19 of them wait behind the best of the 20: they look alike to each other (8 bits from the match, 0 from each other). The test assumed they stay wanted | test's assumption |
| / a third look-alike not plainly wanted | setup claim refused | Set up with the switch off, then a and the plain one posted on the default. **All 12 untouched files** (active, aside, kept held, fetch real, skipped, gone, marked, owner-released with edge, owner-released bare, alternative, not collected, held before) are unchanged at a's attach and after the save and the door. The plain one ends held | test's assumption |
| `TestHoldAtSaveImported` | the second import's look-alike waits | After the door: held as a probable copy, edge to the imported file | test's assumption |
| `TestHoldAtSaveDuplicateBytes` (2) | waits, claim refused | Bytes on record: b held, edge to a. In transfer at the earlier save (b claimed first): held and dup are held by the door against y. After the owner's release and b's give-back, b is held against dup at dup's save. The one held first keeps 1 edge | test's assumption |
| `TestHoldAtSaveStepFails` | waits | The at-save step never runs for waiting files (fault calls 0), so the fault cannot fire. The door then holds both as probable copies (Reheld 2, Failed 0). Nothing is stranded or left waiting. The test's "the step fails and is undone" cannot happen on this path | test's assumption |
| `TestChosenLaterVideoIsJudged` and `…ByOwnerDoor` (sized) | the better copy waits | It waits behind the **owner-released** look-alike: same facts, lower id, wanted by the owner's hand, so it is coming. The released one is downloaded as the owner wants. Then the door marks the better copy for the exact check first (same size). It is judged against a saved file, never wanted without a comparison. A non-plain file may be the one others wait behind, by design (only plain files are made to wait) | test's assumption |
| `TestLookAlikeOldRule` (3 setups, 1 assertion) | the saved album's videos wait behind each other; "held against a file only queued" | Saved with the switch off, then the default: all three rung 6 holds are against the right saved file. "Not saved": rung None, no copy edge, not probable, waits behind the first (c_twin), not supplied. That is the feature, not rung 6 | test's assumption |
| `TestPairDifferentReleases` (2) | x waits behind B; the setup's album waits | x (the owner's "different" was against A, not B) waits behind B, then after B's save the door holds it against B: edge to B 1, to A 0, not skipped. Marked case: unchanged | test's assumption |
| `TestReleasedNeverHeldAgain` / retry now | claim refused (it waits) | b in transfer before a comes, set aside. Owner's "retry now": stays wanted "by the owner", also after a third look-alike arrives and after a's save and the door. Control (clock requeue): held | test's assumption |
| `TestClaimRefusesNewlyMarked` | waits | After the door b is marked and wanted. The three Unmarked claims refuse it untouched; a plain Claim takes it | test's assumption |

**No file is stranded, skipped, released or downloaded against a rule.** In every world the end state matches what the
switch-off test asserts, or the rule's own result, and nothing is left waiting. keep_held, release, the owner's retry
and check_first are all kept.

**One real defect, found while checking the owner's words: F1 (must fix).**
- `twinRule` reads the owner's words only for x, the new or judged file, and only at the door (`words` is false at an
  attach). A plainly wanted **member** m is made to wait behind the best without any read of m's word against the
  best.
- Probe `TestZZOnWordThenThird` (run `probe2`):
  - B (best) and N (lesser) are queued, and N waits behind B.
  - The owner says N and B are "different". The door makes N wanted, `released` 0, not waiting: correct.
  - A third look-alike arrives (a middle one, or one lesser than N). **N waits behind B again**, held "looks like a
    better copy that is still queued", in both worlds.
  - When B is saved, the door makes N wanted with no edge to B. So the word wins in the end, and the cost is a wait,
    never a file.
  - Still, it is a hold against the owner's explicit word on that pair. With the switch on by default it reaches every
    owner's "different" on a waiting pair.
- The same gap applies at the door, for members other than the file judged.
- Fix (in `twin.go`, inside the brief's files): in `twinRule`, leave out a member whose pair with the chosen best has
  the owner's "different". For example, read `pairDiffer(best.ID)` once when best ≠ x and skip such members, or check
  each plain member's word against the best. Pin it with the probe above (its two worlds). Also check the case where
  x is not the best and has a "different" word with the best: today `differ` removes the best from the candidates
  before it is chosen, so that case is safe.

## 2. Do the two new tests prove what they claim? Yes, with one wording note (F3)

I made three mutations through overlays and ran the two pins under each:
- **M1** (`ov/probe_m1.go`): a "no match" verdict lets a held file go (`probeSettle`'s `wanted`, the held branch
  skipped for `VerdictNoMatch`; the old app's `ixLetGo`).
  - `TestTwinNoMatchNeverReleases/its_own` **fails**: "x's own no match: fate wanted, want held".
- **M1b** (`ov/probe_m1b.go`): a better copy's "no match" answers for the files waiting behind it (the old app's
  `ixSampleAnswerFor`).
  - Both "the better copy's" worlds **fail**: "file 2: wanted, want it waiting".
  - "its own" passes, as it should.
- **M2** (`ov/twin_m2.go`): the door lets a waiting file go without rung 6 (`pairRejudge` replaced by a plain set to
  wanted).
  - **All 3 worlds of pin 1 and all 4 of pin 2 fail**: "after the door: wanted…, want held as a probable copy" or
    "…marked for the exact check first".

So each world is held up by a check that a plausible regression breaks. The claims stand:
- "no match" never releases a waiting file;
- a better copy saved through rung 7 or `LinkSame` sends the waiting file to the door, which judges it against the
  saved file (held, or marked for the same size).

The coder's finding is right: a waiting file can still receive the verdict of a check already in its judge phase, and
`probeSettle` keeps it held.

**F3 (note).** The world "the same Telegram file saved through another message (rung 2)" saves b normally:
`save(t, c, acct2, b, 1)` writes its own bytes. The later rung 2 message only links a message to an already saved
file. Because one Telegram file is one `tg_media` row here, "the better copy saved only as a link by rung 2" cannot
happen, and this world repeats `TestTwinBetterSaved`. It is harmless (it also fails under M2). Rename it or add a
comment saying that the real link cases are rung 7 and `LinkSame`.

## 3. Callers of `TwinHold` and the old meaning: not real (F4: a missing door)

**I searched the whole `archiver` tree for `TwinHold`, `SetTwinHold`, `twin_hold`, `twinHoldKey`, `LookAlikeTwins`,
`TwinCounts`, `TwinOf`, `LookAlikeAtSave` and `LookAlikeWouldHold`.**
- **No caller outside `internal/catalog`.**
  - No page door, no collector start line, no command.
  - `internal/copyset`'s settings page has no key for it.
  - None of the counts is shown anywhere.
- Inside the package, the only readers are `twinAtAttach` and `twinPendingJudge`. Both want "on" exactly as
  `TwinHold` now returns it.
- The schema triggers (`schema_twin.go`) never read the switch.
- The invariant query in `twin_never_test.go` was changed to "a stored row other than '1'", which matches the new
  meaning.

**Nothing relied on "off when nothing is stored".**

**Two consequences, both outside C26's files.**
- **F4 (should fix).** Now that "off" exists only as a stored "0", the owner has no way to store it short of editing
  the database. With the default on, the switch the owner is meant to have needs a door. It should be a copies
  setting on the pages, beside `copies.frame_check` and the others. Put it on the board for the pages or copies
  track; it is not a C26 change.
- **Counts move (note).** With the switch on, holds that used to be counted at the save
  (`LookAlikeAtSave`: [0 0 0] in the probes) are now counted as the twin door's "reheld" (`TwinCounts.Reheld`). No
  page shows either count today. Whoever builds that page should show both.

The fail-closed reading ("", "on", "true", "2", " 1" all read off and stored) is sound. `SetTwinHold` only ever writes
"0" or "1". An old catalogue with no row turns on at its first attach after the upgrade. Files already queued are not
made to wait after the fact: the rule runs only at an attach and at the door.

## 4. The line in `internal/exact/wire/review2_test.go`: keep it

Probe `wire_off` (overlay without the line, with logging):
- b is **held** (waiting) right after its post.
- Its hash calls start 4.1 s after a's last one: 05.586..05.627 for a, 09.696..09.776 for b.
- So "two re-uploads checked at once on one server" no longer happens, and the PW1 count "0 hash calls inside the
  wait" holds only because nothing else is being compared. **The test still passes, but it proves nothing.**

The control `wire_ctl` (the line kept): b is wanted at its post, and the two comparisons overlap (b 14.527..14.567,
a 14.536..14.576).

**Keep the line.** It restores the test's premise. All 10 named tests of `exact/wire` pass on the new default (run
`wire_all`, 5.3 s).

## 5. Other notes

- **F6.** `docs/ROADMAP.md`, row "Confirm or release of held files…", still ends "Not built: lesser copies behind the
  best". It should say built (C22), on by default since C26.
- One message (album) of two look-alikes: the lesser one waits behind the other (probe log). This matches the rule
  (rung 6 never held within a message only because nothing in it is saved yet). A wrong wait costs a wait only. It is
  for the planned whole-album rule to weigh, not a C26 defect.
- The coder's runs did not cover the collector, supply, fabricate or bring-in tests. I checked the test sources: the
  other packages that post media with previews either post photos (`pairwords`) or use previews that do not decode
  (`collector/pairwordsline_test.go`, supply, bring-in). The `exact/wire` tests, which do post look-alike videos with
  decodable previews, all pass on the default.

## Verdict

may be listed after these fixes: F1 (in `twinRule`, a plainly wanted member is not made to wait behind a file it has
the owner's "different" with, pinned by `TestZZOnWordThenThird`'s two worlds); F3 and F6 are notes to fold in on the
way; F4 goes on the board for the pages or copies track.

## Second pass (F1)

This pass reviews only the fix: 08e33b79 on `wip/copies-30`, on d7c658a5 (4c280c09 with the main head 09d63f94
merged in).
- I read the diff in `wt-copies-30` and did not edit it. I checked 08e33b79 out, detached, in the scratch copy.
- The probes are the uncommitted `zz_probe_c26b_test.go` there, beside the first pass's file. The logs are
  `runs-copies-r26/p2_*`. For each "before" comparison I overlaid d7c658a5's `twin.go` (`ov/prefix.json`).
- The fix: in `twinRule`, after the best is chosen, it reads `pairDiffer(best.ID)` once (both sides of the word
  table), and `waits` returns false for any file with the owner's "different" against the best. The pin is
  `TestTwinOwnerDifferentStays`. The diff also renames and comments pin 2's rung 2 world (F3).

### 1. Is F1 closed in every path? Yes

| Path | Probe | With the fix | Before the fix |
|---|---|---|---|
| A member, at a new arrival (a middle one or a lesser one) | `TestTwinOwnerDifferentStays`, `TestZZOnWordThenThird` | pass: N stays wanted, and after B's save it is wanted with no edge to B | fail (both worlds) |
| The door's re-judge, both orders | `TestZZ2DoorBothOrders`: T best, B and N wait behind T, the owner says B and N differ, T stops coming, the door judges B and N in either id order, then a later arrival | pass: both wanted, neither waits behind the other, the later one waits behind B and N stays wanted | fail: N waits behind B after the later arrival |
| A word written while the file waits, either argument order; a word against a file that is not its best | `TestZZ2WordWhileWaiting` | pass: N leaves the wait through `pairEnded` and the door. M, whose word is with N and not with its best B, keeps waiting behind B. A new best: B and N wait behind it (the word is on its pair only) | pass (that path was already right) |
| x itself | `TestZZ2XItselfWithWord` | not reachable: a Telegram file catalogued again gets no new collector row ("no row"), so x at an attach is always a new media with no word. At the door, `differ` already left out x's partners before the best is chosen. Even so, `waits` now checks x too (`differBest[x.ID]`) | not reachable |
| The viewer's reader of words | by reading | `ApplyPairWords` calls `SetPairWord` and `ClearPairWord`, so it takes the same paths | |

- The fix and the old checks pass together: `TestTwinOwnerDoors`, both pins, `TestTwinOnByDefault` and
  `TestAttachAsksNoWord` (run `p2_fix`).
- `TestAttachAsksNoWord` still passes because its attach reaches no wait.

### 2. Does it open anything new? Not real

- **The best is chosen as before.** The word is read only after the choice, and only to leave files out of the wait.
- **A file the word keeps apart stays wanted.** It cannot wait behind any other file instead:
  - every other coming look-alike of the group is either the best or itself waits behind the best;
  - a file never waits behind a waiting file.
- **This fails toward downloading, as the switch off does.** One example: a file in transfer that is better than N. N
  is not made to wait behind it, but the step at that file's save still holds N if N is still wanted then.
- **The rank guard and the other doors are unchanged.** A pair the word keeps apart is not counted as "rank kept".

### 3. Cost: not real

- **The read.** It is one read of the owner's words for one file: two seeks, by `c_pair_word`'s key and by
  `c_pair_word_b`. It runs once per weighing that reaches its waits: an attach of a new video with a queued
  look-alike, or a judgement at the door. It does not run for each member.
- **Measured** (`TestZZ2Cost`, 200 attaches that each made a lesser copy wait, run 3 times with and without the fix,
  logs `p2_cost_*`):
  - about 1.1 to 2.6 ms per attach with the fix, against 1.1 to 1.4 ms before;
  - so at most a few tenths of a millisecond, inside the noise;
  - **no growth with 99,925 words stored** (200 of them on the best) against none.
- **Notes, no fix needed:**
  - The new comment says "none when the catalogue has no word at all". That is not so: on the writer
    `hasPairWords` is always true (it checks the schema, not the words). The read ran 200 times of 200 in the world
    with no word.
  - At an attach where the new file is itself the best, the read cannot find anything: a new media has no word, and
    any word the members have with x is with a file that has none. It could be skipped with
    `if words || best.ID != x.ID`. This only saves time.
  - A pair kept apart by the owner's word is not counted anywhere. A count beside "rank kept" would show it on the
    pages later.

**may be listed** (the comment's "none when the catalogue has no word" is to be corrected when next touched; the
skip and the count are optional)
