# Proposal for ix.12.16: catching copies among small files (under 20 MB) and repeated albums

**Status: APPROVED by the user for 12.16 (2026-11-07): Option 1 on by default + Option 2 as a setting, off by default
(with its "would hold" report count). Option 3 not built. Not built yet; approval is for building into 12.16, not for
publishing (publishing 12.16 still needs the user's own OK).**

Written 2026-11-07 (evening, local) from read-only counts of the live database (`mode=ro`, counts only) and the code on
`ix/v12.15` (`repo-v12.11`). Nothing was built, changed or published. The measuring code is a scratch test outside the
repo; it compared the live records with the saved videos' fingerprints (`ix_vfp`) and printed counts only.

## In short

- **Biggest win: two gaps in the free check that already exists, not a new matcher.** In the last 24 h, **~1,070 small
  videos (~5.75 GB) were downloaded although an earlier saved copy at least as good already passed today's own rule**
  (same length to 0.5 s, same shape, Telegram's tiny built-in preview within 6 bits). The fingerprints of both files
  confirm they are the same video. Two causes explain almost all of them:
  1. **A 20,000-row limit.** The hold check (`ixQueuedVideos`, `ix_held.go`) reads only the 20,000 largest queued videos
     of 5 MB or more. 28,462 are queued now, so the cut falls at **16.1 MB**: videos below that are never looked at.
     1,144 queued 5-20 MB videos (13.6 GB) have no check row at all. Last 24 h: ~450 copies (4.35 GB) slipped through.
  2. **A 5 MB floor** (`ixHoldMinSize`). Videos under 5 MB are never checked. Last 24 h: 619 copies (1.4 GB).
- **Album matching ("repeated sets") works only in the strict form.** Matching albums by video lengths alone is
  wrong about 93% of the time (many unrelated albums share clip lengths). An album is a good signal only when it is
  **anchored**: at least 2 *other* files of the same album already match a saved album closely by preview. Then a weak
  preview match is right 67-89% of the time instead of 3-76%. As you asked, it is a **setting, off by default**, and it
  adds little (about 0.3 GB of today's queue).
- **The 75,000 previews are not free.** Each 320 px preview is one request. Bytes are tiny (~10-20 KB each), but
  requests are what is scarce now: since 12.14 started the pass fetched **210 in ~3.4 h (~60/h)**, mostly paused
  because Telegram told the *downloads* to wait (FLOOD_WAIT). A bigger ("high quality") preview costs the same request
  plus more bytes, and hashes no better (hashes work on 32×32 grey). The preview that *is* free is the ~40 px
  "stripped" one inside every message; the archive already hashes it (`ixPreviewHash`), but only for single videos of
  5 MB or more. Fetching all 75,000 to hash them would take weeks at the observed pace, and going faster would compete
  with downloads for requests. **Not recommended.**
- **Recommendation for 12.16:** Option 1 (close the two gaps, on by default, zero requests), plus Option 2 (anchored
  albums) built as a setting, **off by default**, with a "would hold" count in the report so you can decide on
  evidence. Option 3 (targeted previews) not now.

## What is queued (11-07 ~22:00 local)

| Small files (< 20 MB) pending | files | GB |
|---|---:|---:|
| All | 13,233 | 138.3 |
| — videos 5-20 MB | 10,551 | 134.6 |
| — videos under 5 MB | 1,595 | 3.6 |
| — photos | 1,085 | 0.09 |
| In albums (`grouped_id`) | 10,386 of 13,147 matched to a message (**79%**) | 105.7 |
| Held as probable copies | 8,215 | 73.6 |
| — like a saved video (`saved`) | 5,028 | 56.5 |
| — exact size of a saved file, never linked (`unlinked-copy`) | 2,396 | 5.1 |
| — lesser copy of a queued video (`queued`) | 791 | 12.0 |
| Set aside by the deadline order (10-20 MB, private chats) | 2,594 | 38.1 |
| Free in the queue | 2,424 | 26.6 |
| Exactly the size of a saved file (held 6,323 / unheld 331) | 6,654 | 52.3 |

- **Exact size of a saved file:** these get the exact re-upload check when claimed (`ix_subst.go`: Telegram's part
  hashes, one small request, from 256 KB). It already works for small files: 929 substituted so far (5.3 GB), 266-340
  a day. No change proposed there.
- **Last 24 h:** 8,161 files under 20 MB completed (5,672 videos 42.05 GB, 2,489 photos 0.24 GB). After-download
  "same bytes" matches were 93 files / 0.4 GB on 11-07 (all sizes): byte-identical waste is small. The waste is
  **re-encoded copies**.

## How good each signal is (measured, not assumed)

Saved small videos with a saved "twin" in another chat (same length to 0.5 s, same shape), checked by the two files'
video fingerprints (`ixVCompare`: "same" = shares 80% of both). "Preview bits" = difference between the free ~40 px
previews' hashes.

| Twin kind | preview ≤ 6 bits | 7-12 | 13-20 | > 20 | no preview |
|---|---|---|---|---|---|
| Lone file (no album help) | **95%** same (n=4,274) | 76% (713) | 3% (6,303) | 0.2% (11,618) | 2% (296) |
| Album by lengths only ("set") | 94% (2,100) | 76% (597) | 5% (3,656) | 0.4% (12,191) | 7% (176) |
| **Anchored album** (≥ 2 other files of the album match ≤ 6 bits) | **98%** (3,867) | **89%** (415) | **67%** (157) | 20% (143) | 94% (17) |

What this says:
- The free preview hash is the deciding signal. Today's rule (≤ 6 bits) is right ~95% of the time.
- Album by lengths only adds nothing: your worry about mix-and-match is confirmed for that form.
- An anchored album rescues the 7-20 band, but few files fall there (see the options).
- Limits: fingerprint "different" may include a few failures on very short clips; twins were looked for **only in
  other chats**, so copies inside one chat are not counted (all savings below are lower bounds).

## Options, ranked

Speed-limit hours use 2-8 GB/h (the range seen in most hours). "Held" means moved to the back of the queue, never
skipped: the design stays as it is (copies go last; nothing is deleted). So bytes are truly saved only if time runs
out before the back of the queue. Until then the gain is that unique files come that many hours sooner.

### 1. Close the two gaps in the existing check — recommended, on by default

- **Remove the 20,000 limit's blind spot.** Read the queue in pages (keyset on id), or at least order unseen rows
  (no `ix_held` row) first, so every queued video is looked at once. Re-checks of rows already looked at can keep a
  budget per round.
- **Lower the floor** from 5 MB to 256 KB (the size where the exact re-upload check starts). Same rule, same
  "at least as good" requirement (`ixCoversSaved`).
- **Expected:** queued now: up to ~600 files / ~6.8 GB with a saved or queued twin at ≤ 6 bits (about 92% of them
  "at least as good", so ~6.2 GB) → **0.8-3.1 h** of early download time moved to the back. Going forward, if the last
  24 h repeats: **~1,070 files / ~5.75 GB a day → 0.7-2.9 h a day.** About 5% of holds would be wrong (unique
  content waiting at the back; it still downloads there, with the copies, if time allows).
- **Cost:** 0 Telegram requests. CPU: the check every 2 min reads ~28.5k rows instead of 20k plus ~1.6k small videos.
  Today's process already reads ~750 MB/s at ~1.8 cores, so page the work (e.g. new rows every round, all rows once an
  hour) rather than reading everything every 2 min.
- **Risk to downloads:** none by requests. Held files don't count toward the queue limit (`ixWaitingApart`). Main
  risk is a bug pausing too much: guard with a test on a synthetic queue larger than the page size, and a report line
  "looked at N of M queued videos".

### 2. Anchored albums — build as a setting, **off by default**

- When a queued small video's album has ≥ 2 other files matching one saved album at ≤ 6 bits, accept a twin in that
  same saved album at 7-20 bits (or with no preview) as a probable copy (`how = album`). Albums by lengths only are
  never used.
- **Expected:** queued now ~27 files / ~0.3 GB (anchored 7-12: 16 / 0.19 GB, anchored 13-20: 9 / 0.09 GB,
  anchored with no preview: 2). Last 24 h it would have caught ~60 more copies (~0.3 GB) and held ~6 unique files
  wrongly. Small. (Lone files at 7-12 bits, 113 queued / 1.45 GB, are right only 76% of the time: not proposed.)
- **Cost:** 0 requests. One in-memory index of album videos (~151k videos from 206k media messages, ~10 MB), built once
  per process from `ix_messages` and updated from new rows; not rebuilt every round.
- **Risk:** 11-33% wrong in the 7-20 band. That's why it stays off. 12.16 would add a report line: "albums: N files
  would be held (setting off)", so you can decide on evidence.

### 3. Targeted 320 px previews — not now

- Only for queued files whose free preview is uncertain (a twin at 7-20 bits): ~700 files today, not 75,000.
  Fetched inside the existing preview pass's pacing, ahead of its general backlog, so downloads see no extra requests.
- **Expected:** ~115 copies / ~1.5 GB found (most 13-20 twins are truly different, so the previews would mostly
  confirm "keep in place"). At the observed ~60/h it takes ~12 h of the pass.
- **Why not now:** small gain. It needs a comparison rule on 320 px previews (picture hash like `ix_pdq`, or the
  recognition vectors when that service runs) that has not been measured. The pass is paused most of the time because
  downloads get FLOOD_WAITs: raising its pace is the thing you don't want.

## Recommended design for 12.16

1. `ixQueuedVideos`: no blind spot. Each round looks at rows with no `ix_held` row first (all of them, in pages of
   e.g. 5,000), then re-checks a rotating slice of the rest. Report line: "copy check: looked at N of M queued videos;
   oldest unseen X min".
2. `ixHoldMinSize` 5 MB → 256 KB.
3. Setting "Use whole albums to spot copies" (off). When off, count only: "albums would hold N files / GB". When on:
   `how = album`, with the anchoring rule above. The browser shows it as "probable copy (album)".
4. Tests with invented data: a queue larger than one page, all rows looked at; a 1 MB copy held, a better 1 MB copy
   not held; album rule: anchored → held, lengths only → not held, setting off → counted, not held.
5. No change to the preview pass, the exact re-upload check, the in-download check, or the order of the back of the
   queue.

What to watch after the install: the "looked at N of M" line reaches M within an hour; held count rises by roughly the
~600 above and then by ~1,000 a day at most; downloads/hour unchanged; no FLOOD_WAIT change (no new requests exist).
