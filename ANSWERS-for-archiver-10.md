# Answers to QUESTIONS-for-fork-10 (fork session, 2026-11-21 ~21:30 local)

Read-only. No Telegram request. Numbers only. MB = MiB, GB = 10⁹ bytes.

Sources:
- the database opened `mode=ro`, by three throwaway Python scripts (not committed) that print counts only. **Its last
  queue change is 11-14 about 19:30 local**, so every count below is as of then, not today;
- `ixreports\latest.txt` (12.30, written 11-14 22:22 UTC), counts only;
- the code of 12.31 (`wt-v12.31`).

**The short answer: your reading of the code is right, and the counts settle it. The "400 released" were mostly
right holds.**
- **None of the files they waited behind was in the library at the time of the frame check.** The check compared each
  held video only with other saved videos.
- **Of the released holds that can be judged now, 97% were the same content as the file they waited behind, and 94%
  were the same bytes.** By the current counts that is 378 of 391, and 366 of them byte for byte.
- **350 of the 437 were the very same Telegram file** as the one they waited behind (same kind, id and size).
- **272 never had a frame read.** They took over the "no match" of an earlier check of the same Telegram file. For
  248 of them, that earlier check was the check of the file they waited behind.

## How the groups were made

The groups are the holds with `ix_copy_hold.how = 'queued'` as they are now: 2,529 rows. Answers 5 counted the same
groups on 11-13 23:30, so these numbers are a day later and a little larger.

| Group now | Rows | In answers 5 |
|---|---|---|
| **A**: let go after a frame check said "nomatch" (`result='nomatch'`, `confirm='unconfirmed'`, let go) | **437** | the 400 |
| **A3**: let go the same way; the result was later changed to "confirmed" | 16 | then probably among the 400 |
| A2: let go by something else first, checked "nomatch" later | 32 | |
| **B**: confirmed by a frame check (`confirm='confirmed'`): 132 still held, 6 let go | **138** | the 130 |
| B2: confirmed, but only after the hold was let go | 9 | |
| **C**: no frame check ever | **1,894** | |
| check failed | 3 | |

About A3: when more saved videos get fingerprints, `ixSampleRecheck` compares a "nomatch" video's kept frames again.
For 13 of the 16, the new match was **the very file they had waited behind**, once that file was saved and
fingerprinted. By then all 16 had been let go and downloaded.

**What the rows cannot show:**
- `of_work` is the file a hold waits behind now. Step 2 of `ixHeldTriage` and `ixPromote` both rewrite it, so the file
  at the time of the check may in rare cases have been another one.
- Holds that `ixRecheckAgainstSaved` kept are rewritten to `how='saved'`, `of_work=0`, and promoted holds are deleted.
  So "ever made" is not fully on record (question 3).

## Your reading of the code (12.31): right, with one thing to add

- **`ixHeldTriage` step 2** calls `ixHoldWork(ctx, q.f, "queued", "", "", best.f.ID, …)`, which leaves `like_path`
  and `like_key` empty.
- **`ixSampleCandidates(f, likeKey)`** adds the held file's twin only through `likeKey`, so here never. It adds the
  saved fingerprints (`ix_vfp`, status ok) 20% shorter to 20% longer, at most 300. **The twin can be among them only
  if it is already in the library and fingerprinted.** For group A it never was at the time of the check
  (question 1).
- **`ixSampleRecord`**, with `j.held` and "nomatch" below `ixSamplePartialHit`, calls `ixLetGo` whatever `how` the
  hold has. `ixHeldOutweighed` does the same over the same rows.
- **To add: `ixSampleAnswerFor(ident, likeKey)`.** With an empty `likeKey`, it hands a held row any earlier "nomatch"
  of the same Telegram file. The guard `likeKey != "" && like != likeKey …` only applies when `likeKey` is set.
  - So when the twin is the same Telegram file, the twin's own check (against saved videos) answers for the held copy.
  - `ixSampleReuse` and `ixSampleRound` pass that answer on, and the copy is let go.
  - **This happened 248 times.**
- **So "released" in answers 5 means "its frames, or its twin's frames, matched no saved video".** It does not mean
  "not a copy of the file it waited behind".

## 1. Was the file each waited behind saved at the time of the check?

**Group A (437, released on "nomatch"):**

| The file it waited behind, at the time of the check (`ix_copy_hold.checked_at`) | Holds |
|---|---|
| in the library before the check (by its catalogue row's or link's time) | **0** |
| finished downloading before the check, not yet in the library (its queue row's time) | 103 (93 of them in the 10 minutes before) |
| finished after the check | 303 |
| never finished: still pending | 21 |
| never finished: skipped (cancelled by a queue action) | 10 |

The 303 that finished after the check, by how long after:

| Finished after the check | Holds |
|---|---|
| under 1 minute | 44 |
| 1 to 10 minutes | 56 |
| 10 to 60 minutes | 17 |
| 1 to 24 hours | 123 |
| over a day | 63 |

- **Pending or in transfer at the check is not recorded.**
  - The 100 that finished within 10 minutes after the check were very probably in transfer.
  - The 103 that finished before it were in local staging: downloaded, not yet in the library. (`ixHeldRecheck`
    waits on those with `ixStagedNow`, but the frame check does not.)
  - The rest were most likely pending.
- **How the check was made:**
  - 165 had their own frames read;
  - 272 took the answer of an earlier check of the same Telegram file (`reason='same-file'`), 248 of them the check
    of the file they waited behind.
  - Around that file's own download this is tight: 91 of the 93 checks within 10 minutes after the file finished were
    such answers. **That looks like the check in its own download handing its "nomatch" straight to its twin.**
- **Group B (138 confirmed):** the file they waited behind was not saved at the time of the check for all 138. It is
  still pending for 132, and was saved later for 6. **So the 130 "confirmed" in answers 5 were confirmed against some
  other saved video, never against their twin.**
  - For 6 of them, the frame check's matched file (`of_key`) has the same SHA-256 as the twin once that was saved.
    The twin was itself matched to that saved file by the exact check or as the same Telegram file.
- A2 (32): the twin was in the library at the check for 4, and those 4 also had its fingerprint. For the other 28 it
  was saved later.

## 2. What became of the 400 afterwards (group A, 437 now)

**The held file now:** finished 424, skipped 13 (cancelled by a queue action), still waiting 0.

**How the 424 were saved:**

| How | Files |
|---|---|
| downloaded in full (a catalogue row with its own file) | 124 |
| same Telegram file as a saved one, nothing downloaded (`ix_msg_link` telegram-file) | 285 |
| skipped by the exact check (Telegram's hashes; `ix_subst` / exact-reupload) | 4 (all 4 against the file it waited behind) |
| downloaded, then found the same bytes and removed (after-download) | 1 |
| no record of the saved file | 10 |

**Against the file they waited behind:**

| Outcome | Files |
|---|---|
| **same bytes** (equal SHA-256, the same saved file, or the exact check against it) | **366** |
| ...of which the same Telegram file | 333 |
| ...of which a different Telegram file, same bytes | 33 |
| **same content, other bytes** (`ix_vdup` between the two files) | **12** (same 9, overlap 3) |
| **different content** (both fingerprinted, no pair) | **13** |
| cannot be judged | 33 (31: the twin never saved or a record missing; 2: a fingerprint missing) |

- Of the files that were not the same bytes as their twin, 7 are the same bytes as some other saved file.
- **What the release cost in bytes was small, because later checks caught most of it.** Of the 124 downloaded in
  full, 87 were the same bytes as their twin:
  - 64 were the same Telegram file and went first, and the twin was then matched to them. One download, nothing lost.
  - 4: the twin was then skipped by the exact check. 1: the twin was matched to it later.
  - **18: the twin was downloaded in full too, and both are still kept: 11.1 GB downloaded a second time.** Different Telegram files,
    same SHA-256. Why the after-download check did not remove one was not looked into.
  - 9 more downloaded in full were the same content with other bytes (same 7, overlap 2).
- **The file they waited behind:**

  | How it ended | Files |
  |---|---|
  | saved: downloaded itself | 290 |
  | saved: same Telegram file as a saved one | 100 |
  | saved: exact check | 10 |
  | saved: no record found | 6 |
  | still pending | 21 |
  | skipped | 10 |
  | gone or failed | 0 |

**A3 (16, released, later confirmed):**
- 3 the same bytes, 11 the same content with other bytes (same 8, overlap 3), 1 different, 1 cannot be judged;
- all 16 were finished.

## 3. Holds against a queued file that no frame check judged

| | Files |
|---|---|
| **on record now** (`how='queued'`, no `ix_copy_sample` row) | **1,894** (plus 3 whose check failed) |
| held now | 1,036 |
| ...the file waited behind is pending | 982 |
| ...it is finished (in staging, or not yet rechecked) | 50 |
| ...it failed | 4 |
| **let go** | **858** |

- **Of the 858 let go, every one had its twin finished.** 857 were let go after the twin's last queue change. So
  nearly all look like `ixRecheckAgainstSaved` releases ("the file it waited for was saved and does not look the
  same").
  - Not recorded apart from the other two ways out: a person resuming the file, and `ixReleaseSome` while the twin was
    in staging.
- **Turned into a hold against the saved file by the recheck (kept): not recorded.** The recheck rewrites the row to
  `how='saved'`, `of_work=0` and the "saved copy" reason.
  - Estimate: 7,572 `how='saved'` holds were made more than a minute before their saved file's first catalogue row.
    A step-1 hold cannot be made then, so these look like converted holds.
  - 7,200 of them are still held, 372 let go.
  - By size: under 20 MiB 2,244, 20–200 MiB 4,873, over 200 MiB 455.
  - Upper bound, "looks like": a saved file catalogued again under the same path would also count.
- **Promoted (`ixPromote`): not recorded.** `ixUnhold` deletes both rows. `latest.txt` holds no such log line, and
  none of the recheck's "goes" lines either.
- **Possible defect in the old app, found while counting:** `ixRecheckAgainstSaved` reads only the twin's own
  catalogue row: `downloads WHERE group_id=? AND message_id=? AND status='completed' AND file_path<>''`.
  - A twin saved only as a link (same Telegram file or exact check, `ix_msg_link`, no row of its own: `Record.Skipped`)
    makes that read fail, and the held copy is let go without any comparison.
  - **501 of the 858 have such a twin now** (exact check 328, same Telegram file 173).
  - 334 of those held copies were the same bytes as the twin. They cost no download: the exact check or the
    same-file rule caught them later.
  - Whether the twin had no row at the time of the recheck is not recorded.

**What became of the 858 let go:** finished 856, skipped 2.

Against the twin, 839 can be compared on both sides:

| Outcome | Files |
|---|---|
| **same bytes** | **343** (the same Telegram file 258) |
| **same content, other bytes** | **355** (same 291, overlap 64) |
| **different content** | **107** |
| cannot be judged | 34 |

**Downloaded in full, 386 (45.5 GB):**

| Against the twin | Files | GB |
|---|---|---|
| same bytes | 1 | 0.1 |
| same content: "same" | 227 | 17.1 |
| same content: overlap | 50 | 6.6 |
| different content | 78 | 19.3 |
| cannot be judged | 30 | 2.4 |

- Where the twin was itself downloaded in full, 174 of these pairs are the same content (131 same, 43 overlap), so
  both were downloaded (16.7 GB for the held side).

## 4. Sizes

These are all 2,529 `how='queued'` holds on record. Exact size and identity are compared with the current `of_work`.

| Size class | Files | GB | Same byte size as the twin | Same Telegram file as the twin |
|---|---|---|---|---|
| under 20 MiB | 282 | 3.7 | 128 | 89 |
| 20–200 MiB | 1,502 | 106.6 | 789 | 576 |
| over 200 MiB | 745 | 420.7 | 564 | 449 |
| **All** | **2,529** | **531.0** | **1,481** | **1,114** |

- Every frame-checked hold is over 200 MiB, which is the background check's floor. Group A is 437 files / 267.5 GB,
  396 of them with the twin's exact size.
- **Not in the table:** the converted holds (estimate in 3: 2,244 / 4,873 / 455 by class). Their twin was erased
  from the row, so they cannot be compared.

## 5. Pairs inside one chat

| | Same chat as the twin | Another chat |
|---|---|---|
| all 2,529 | **639** | **1,890** |
| A (released by a frame check) | 143 | 294 |
| B (confirmed) | 24 | 114 |
| C (no frame check) | 456 | 1,438 |
| A2, A3, B2, failed | 16 | 44 |

Every hold's twin still has a queue row, so none is unknown.

## 6. Both downloaded anyway

- **No count of "both in transfer at the same time" or "the lesser one claimed first" is recorded.**
- **The same Telegram file cannot be in transfer twice.** The engine's claim (`claimFree` in `engine/work.go`) never
  takes a row whose identity is being transferred, so the second one waits and is then matched to the first.
  - So two rows can only be in transfer together when they are different Telegram files.
- **"After download, same bytes"** (`ix_dedup_daily`, `after-download`): 3,590 files / 4,561 MB from 11-04 to 11-14.
  The report's last 7 days: 3,156 files / 4,135 MB.
  - That is about 1.3 MB a file, so mostly small files, not these video pairs.
  - How many of them were in transfer while their twin was: not recorded.
- **From the holds on record:**
  - **18 pairs (group A) were both downloaded in full with the same SHA-256, and both kept: 11.1 GB.** The held copy
    finished first in 7, the twin in 11.
  - In group C, 1 more (0.1 GB), whose twin was then skipped by the exact check.
  - Same content with other bytes, both downloaded in full: 174 pairs in C (16.7 GB for the held side). In A, 9 held
    copies downloaded in full were the same content as their twin; whether the twin was downloaded in full too was
    not split out.

## What this means for the switch `copies.twin_hold`

**Should it be on by default?** On these counts, yes.

**The counts:**
- **Different Telegram files only.** The same Telegram file is found by its identity anyway, so it is not the case
  `twin_hold` is for. Of the queued holds since finished where both files can be judged, **516 of 644 (80%) were the
  same content as the twin.**
  - 131 the same bytes, 313 "same", 72 "overlap";
  - **128 (20%) were different.**
  - Group A alone: 45 of 58. Group C alone: 440 of 547, though C was let go *because* the recheck thought the pair
    did not look alike.
- **Counting the same Telegram file too:** 1,127 of 1,255 (90%).
- **A wrong hold costs a wait, not a file.** The held copy downloads once its twin is saved and found different. The
  rule "probable copies are held, never skipped" covers it.

**Two of the old app's release paths are wrong and should not be copied:**
- **a frame check against saved videos must not release a twin hold.** Here it released 437, of which 378 were the
  same content;
- **the recheck must read the twin's link as well as its own catalogue row.** Here 501 were let go on a twin with
  only a link.

**How confident:**
- **Fairly confident that a twin hold is usually right.** The figures are hundreds of pairs, and the byte matches are
  exact (SHA-256).
- **Less confident about the 20% "different":**
  - "Different" means two post-download fingerprints with no `ix_vdup` pair. Answers 8 showed that this checker
    misses copies too, so the true share of wrong holds may be lower.
  - "Overlap" may be a clip rather than a copy.
  - `of_work` may have changed since the hold was made.
- **Not measured: what holding would save in bytes.** In the old app most released twins cost nothing extra, because
  the same-file rule and the exact check caught them. The measured waste is 18 pairs / 11.1 GB of equal bytes, plus
  about 17 GB of same-content pairs both downloaded.
