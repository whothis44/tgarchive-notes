# Answers to QUESTIONS-for-fork-5 (fork session, 2026-11-13 ~23:30 local)

Read-only:
- the database opened `mode=ro`, by `ix-tools/live_q12.py` and inline queries;
- a throwaway Go test in `wt-v12.30`, never committed and since deleted, which opened the same database read-only to
  decode the held messages' length and pixel size.

No Telegram request. Numbers only. MB = MiB (1,048,576 bytes); GB = 10⁹ bytes.

**The preview-hash distances in B.2 were added later**, with the owner's OK. A second throwaway test (never committed,
since deleted) hashed the stored previews in memory and printed only counts per group: no preview bytes, no hash
values, nothing per file.

## Correction to answers 4, B.7 (please read first)
Answers 4 said that of held items later frame-checked, 5,617 were confirmed and 12,926 released. **That counted
items that were never held.**
- The look-alike check marks every queued video it looked at and did not hold with an `ix_held` row with
  `released_at = -1` and no reason. 67,186 such marker rows exist. Answers 4 joined on `ix_held` without excluding
  them.
- **Real holds** (`released_at` 0 = held now, or > 0 = let go) that got a frame check, read now:

  | Outcome | Files |
  |---|---|
  | Confirmed | **5,564** |
  | Released, no match | **678** |
  | Partial (still at the back as partly the same) | 369 |
  | Failed | 7 |

- **Never held, frame-checked:** no match 14,195, confirmed 73, failed 51. These are mostly checks run in the
  download of videos nothing had held.
- So the "wrong holds" to explain are **678, not 12,926**. Of the 5,564 confirmed, 4,204 were held *by* the frame
  check itself ("sampled") and are confirmed by definition. **Look-alike holds that a frame check judged: 1,360
  confirmed against 675 released** (saved 1,218 / 275; queued 130 / 400; plus 12 confirmed from the 12.9 repair and
  3 released whose evidence row is gone).
- Answers 4's file has the same correction note.

## A. The exact check: what the stricter rule moves

### 1. The 5,007 files the exact check found the same (`ix_subst`, all "telegram-hashes"), by kind and size
Kind is the saved file's catalogue MIME type, or its catalogue type when there is no MIME. Every one of the 5,007 has
a catalogue row.

| Class | Judged by (old code) | Files | MB |
|---|---|---|---|
| (a) everything under 2 MiB | every part's hash | 1,071 | 1,247 |
| (b) video 2–64 MiB | three places | 3,193 | 41,046 |
| (b) video 64–256 MiB | three places | 511 | 70,837 |
| (b) video 256 MiB–1 GiB | three places | 201 | 88,392 |
| (b) video 1 GiB or more | three places | 27 | 38,417 |
| (c) non-video 2 MiB or more (all `application/*`) | every part's hash | 4 | 30 |
| **All** | | **5,007** | **239,969** |

- **So the new rule would move 3,932 files / 238,692 MB (99.5% of the bytes saved) from "not downloaded" to
  "held".**
- Only (a) and (c), 1,075 files / 1,277 MB, were judged on every part and stay skipped.
- **Not recorded:** how many windows each three-place answer covered. The old code compared every window Telegram
  returned, not just one per place. So some of class (b) may in fact have had every part compared, but no record
  says which.

## B. The look-alike hold: confirmed against wrong holds

### 2. By hold evidence, confirmed against released

**Preview-hash distance** (`ixPreviewHash` of the held message's stored preview against the saved file's stored
preview, or, for "queued", against the queued file's message preview), as bits that differ out of 64. Every row of
each group was used. "7+" is 7 or more.

| Evidence / outcome | Holds | Both hashable | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7+ | No preview on one side |
|---|---|---|---|---|---|---|---|---|---|---|---|
| saved / **confirmed** | 1,218 | 1,157 | 885 (76%) | 0 | 184 | 0 | 59 | 0 | 24 | 5 | 61 |
| saved / **released** | 275 | 221 | 182 (82%) | 0 | 30 | 0 | 7 | 0 | 2 | 0 | 54 |
| queued / **confirmed** | 130 | 118 | 84 (71%) | 0 | 15 | 0 | 13 | 0 | 5 | 1 | 12 |
| queued / **released** | 400 | 346 | 323 (93%) | 0 | 12 | 0 | 11 | 0 | 0 | 0 | 54 |
| sampled-partial / partial | 369 | 325 | 209 | 0 | 47 | 0 | 28 | 0 | 7 | 34 | 44 |
| sampled / confirmed (held by the frame check itself) | 4,204 | 3,608 | 539 | 0 | 1,005 | 0 | 636 | 0 | 317 | 1,111 | 596 |
| unlinked-copy / confirmed | 12 | 10 | 7 | 0 | 2 | 0 | 0 | 0 | 0 | 1 | 2 |

- **A tighter preview threshold would not cut the wrong holds.** Released holds are, if anything, *closer* by preview
  than confirmed ones: 82% against 76% at 0 bits for "saved", and 93% against 71% for "queued".
  - At a threshold of 0 bits, "saved" holds would keep 182 of 221 wrong holds and lose 272 of 1,157 confirmed copies
    (24%).
  - At 2 bits: keep 212 of 221 wrong holds, lose 88 confirmed (8%).
- **Only even distances occur** (0, 2, 4, 6), in every group. That is a property of the hash as computed, seen here,
  not checked in the code. So the steps that matter are 0, 2, 4 and 6.
- **The frame check finds what the preview rule cannot.** Of the 3,608 copies the frame check found by itself
  ("sampled"), 1,111 (31%) are 7 or more bits apart by preview, beyond the look-alike rule's 6.
- Together with the size facts below: the wrong holds look the same as the confirmed ones by every stored fact
  (preview, length, pixels, size). Many of them were exact copies that the frame check missed (see below). **The
  stored facts give no rule that removes wrong holds. The way to reduce them looks like the exact check (Telegram's
  hashes) on a hold whose byte size equals the saved file's, before a frame check may release it.**

**Length, size and pixels.** These compare the held item's message (length and pixels from its stored record, byte size from its queue row)
with what it was held against:
- for "saved" and "sampled": the saved file named in the hold (`like_path`, its catalogue length, pixels and size);
- for "queued": the queued file it was held behind (`of_work`, its message record).

Every row of each group was used (no sampling). Length difference is the absolute difference in ms. Size ratio is
held over saved.

| Evidence / outcome | Holds | With facts both sides | Length diff ms p10 / median / p90 | Within 500 ms | Size ratio p10 / median / p90 | Same pixels | Held has more pixels | Same byte size | Same byte size, same pixels and length within 500 ms |
|---|---|---|---|---|---|---|---|---|---|
| saved / **confirmed** | 1,218 | 1,218 | 0 / 0 / 280 | 1,166 | 0.9997 / 1.0000 / 1.0000 | 1,175 | 0 | 975 | 971 |
| saved / **released** | 275 | 275 | 0 / 0 / 4,837 | 226 | 0.9999 / 1.0000 / 1.0179 | 239 | 0 | 204 | 203 |
| queued / **confirmed** | 130 | 130 | 0 / 0 / 266 | 123 | 0.9993 / 1.0000 / 1.0000 | 118 | 0 | 103 | 100 |
| queued / **released** | 400 | 400 | 0 / 0 / 500 | 360 | 1.0000 / 1.0000 / 1.0000 | 383 | 0 | 355 | 347 |
| sampled-partial / partial | 369 | 349 | 0 / 0 / 565 | 312 | 0.9996 / 1.0000 / 1.0436 | 305 | 27 | 235 | 234 |
| sampled / confirmed (held by the frame check itself) | 4,204 | 4,138 | 0 / 115 / 933 | 2,807 | 0.5364 / 1.0004 / 3.9152 | 1,884 | 1,242 | 318 | 264 |
| unlinked-copy / confirmed | 12 | 11 | 0 / 0 / 272 | 10 | all 1.0000 | 10 | 1 | 11 | 9 |

**What this shows:**
- **Length, size and pixels do not separate confirmed from released holds.** Both groups have a median length
  difference of 0 ms and a median size ratio of 1.0000. Most of both have the same pixels and the same byte size.
- The only visible difference is the length tail. Outside 500 ms: 4% of confirmed "saved" holds (52 of 1,218)
  against 18% of released ones (49 of 275). Queued: 5% against 10%.
- A tighter length bound would cut few wrong holds and some right ones. The preview distance does not separate them
  either (table above).
- **Some "released" holds were byte-identical copies after all**, so the frame check's "no match" was wrong for them.
  Of the released "saved" holds since downloaded:
  - **18** were then skipped by the exact check (Telegram's hashes matched the saved file);
  - **5** more, once downloaded, had the same whole-file hash as the saved file;
  - 64 had a different whole-file hash;
  - 185 have no catalogue row to compare: possibly still in staging, or removed as copies after download. Not
    checked further.
  - Queued released holds: 2 were skipped by the exact check.
  - Partial holds: 41 skipped by the exact check, and 17 with the same whole-file hash after download.
- **So at least 23 of the 275 released "saved" holds were exact copies**, and the frame check released them.
- The same pattern holds for 58 of the 369 "partial" ones.
- This looks like more than chance: 203 of the 275 released "saved" holds had the saved file's exact byte size,
  pixels and length. It is "looks like": no media was opened to see why the frames disagreed.

**For the new app, from these numbers ("looks like", not proven):**
- A hold whose byte size equals the saved file's should go to the exact check (Telegram's hashes) before any frame
  check is allowed to release it.
- In the old app the frame check can release such a file, and it is then downloaded unless the exact check catches it
  at download time.

### 3. By evidence and by size class
**By evidence:** see the table above.
- Hold reasons as stored (`ix_held.reason`), real holds only:
  - "looks like a saved copy": confirmed 1,218, released 278, partial 263, failed 5;
  - "looks like a copy of a queued file": 130 / 400 / 16 / 2;
  - "the same footage as a saved video (sampled frames)": confirmed 4,196;
  - "partly the same footage (sampled frames)": confirmed 8, partial 86;
  - older "marked done before ix.10.2": confirmed 12, partial 4.
- No real hold has the evidence "recognition" or "album".

**By size class of the held file** (real holds only):

| Size class | Evidence | Confirmed (files / GB) | Released (files / GB) | Partial | Failed |
|---|---|---|---|---|---|
| under 20 MiB | any | 0 | 0 | 0 | 0 |
| 20–200 MiB | sampled (frame check's own) | 3,568 / 233.7 | | | |
| 20–200 MiB | sampled-partial | | | 64 / 3.8 | |
| over 200 MiB | saved | 1,218 / 642.0 | 275 / 187.1 | | 5 |
| over 200 MiB | queued | 130 / 60.3 | 400 / 249.7 | | 2 |
| over 200 MiB | sampled | 636 / 343.0 | | | |
| over 200 MiB | sampled-partial | | | 305 / 154.5 | |
| over 200 MiB | unlinked-copy | 12 / 6.7 | | | |
| over 200 MiB | evidence row gone | | 3 / 2.2 | | |

- **Every look-alike hold that a frame check judged is over 200 MiB.** The background check's floor is 200 MB; under
  that, only checks run in the download hold anything.
- So the wrong holds (675) and the confirmed look-alike holds (1,360) are all big videos: 437 GB released against
  709 GB confirmed.
