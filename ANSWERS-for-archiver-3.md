# Answers to QUESTIONS-for-fork-3 (fork session, 2026-11-13 ~11:15 local)

Read-only: hourly reports (newest 2026-11-13 10:2x), the database opened `mode=ro`, no Telegram request. Numbers only.
"Unique" means not the same Telegram file (document or photo id) as one already saved or queued. That is a match by id
only: some of these may still turn out to be visual copies, and group download filters were not applied.

## A. What is left on the old account

### 1. Queued and not downloaded, per server (files / GB)

The stages are the ones the fork's forecast uses (`ix_forecast.go`).

| Server | Unique, ready | Downloading | Set aside by the deadline order | Held probable copies | Confirmed copies | Other paused |
|---|---|---|---|---|---|---|
| DC1 | 1,536 / 196.4 | 7 / 0.5 | 1,432 / 151.6 | 26,611 / 829.6 | 2,602 / 578.0 | 1 / 0.5 |
| DC2 | 0 | 0 | 0 | 3,246 / 135.9 | 745 / 176.5 | 1 / 2.2 |
| DC4 | 20 / 6.6 | 2 / 1.0 | 15 / 15.3 | 10,447 / 376.7 | 1,695 / 300.4 | 0 |
| DC5 | 7 / 0.9 | 7 / 0.3 | 1 / 0.2 | 2,344 / 82.6 | 435 / 95.4 | 0 |

- Held and confirmed rows include repeats of one Telegram file. Distinct Telegram files: held DC1 21,001, DC2 2,816,
  DC4 8,317, DC5 2,069; confirmed DC1 2,025, DC2 584, DC4 1,345, DC5 358.
- **Not queued**, unique files in messages already saved (from LESSONS-ix12.29-servers.md, measured 09:35 today):
  DC1 14,354 / 182 GB, DC4 6,407 / 106 GB, DC5 329 / 22 GB, DC2 208 / 8.7 GB.

### 2. Unlimited hours needed, per server

**Rate:** the 11 unlimited hours of the last two days (11-11 18:00–22:00, 11-12 00:00–03:00, 11-13 04:00–05:00), GB per
hour per server, mean:

| DC1 | DC4 | DC5 | DC2 |
|---|---|---|---|
| 30.7 | 20.7 | 7.3 | 3.7 |

- DC2 brought 9.2 a hour when it still had files (11-11 18:00–20:00) and 0 since 11-12 02:00.
- DC5's rate is held down by -503 timeouts and by its supply running short, so its hours are rough.

**(a) Unique files**, queued (ready, downloading, set aside, other paused) plus not queued:

| Server | Unique GB | Unlimited hours |
|---|---|---|
| DC1 | ~531 | ~17 |
| DC4 | ~129 | ~6 |
| DC5 | ~23 | ~3–4 |
| DC2 | ~11 | ~1–3 |

The servers download side by side, so **DC1 sets the total: about 17 unlimited hours.** This corrects the fork's earlier
estimate of 11–12 hours, which divided all servers' GB by the whole account's rate. DC2 and DC5 cannot help DC1.

**(b) Held probable copies afterwards:**

| Server | Held GB | Unlimited hours |
|---|---|---|
| DC1 | 829.6 | ~27 (~44 in all with its unique files) |
| DC4 | 376.7 | ~18 (~24 in all) |
| DC2 | 135.9 | ~15 at 9.2 GB/h |
| DC5 | 82.6 | ~11 |

**Unlimited hours left before 2026-11-29 22:24** (about 16.5 days): about **90** at the last two days' frequency (11 in
48 h). The fork's own report gives about **100**, from 12 of the last 47 measured hours. They come in irregular spells:
10 h from 11-11 18:00, then none for about 24 h, then about 3 h on 11-13 from 03:00. **So DC1's unique and held files look
like they fit (~44 h), but only if the spells keep coming at this rate: not proven.**

### 3. Held probable copies checked by sampled frames

- **Checked so far:** 20,850 files.
  - 5,590 confirmed (matched);
  - 15,202 no match: those go back to their place in the queue;
  - 58 failed (26 of them to be tried again).

  The report counts 19,782 big videos checked using 171 GB of parts instead of 3,031 GB.
- **Held now, by how:**

  | How | Held |
  |---|---|
  | Copy of a saved file, by size and other evidence, not frame-checked | 38,604 |
  | Same, confirmed | 1,166 |
  | Confirmed by sampled frames | 4,199 |
  | Partly the same (unconfirmed) | 114 |
  | Lesser copies of queued files | 1,475, plus 101 confirmed |
  | Copies found by the 12.9 repair | 2,455, plus 11 confirmed |

  The report's "waiting for a check" is 930 videos of 200 MB or more, the size floor in use.
- **Checks an hour (last 48 h):**
  - limited hours: 2–33 an hour, most of them 5–16;
  - unlimited hours: 150–953 an hour (11-11 17:00–23:00: 212, 588, 608, 567, 303, 387, 150; 11-12 00:00–04:00: 800, 953,
    486, 500, 358; 11-13 03:00–05:00: 247, 750, 682);
  - last 24 h: 1,702 checks, 15.0 GB of parts, 492 copies, 72 partly the same.

### 4. Chats not added
- **Now 188:** 56 channels or supergroups, 2 basic groups, 21 private chats, 10 migrated groups, 48 restricted, 51
  deleted. Against the 11-09 note: 56 channels and supergroups against 58, and 48 restricted against 46. The cause of the
  difference was not checked.
- Restriction codes stored: 47 "terms", 1 "porn". The 51 deleted are deleted users.
- **No size estimate is stored.** `ix_media_counts` is empty: media counting runs only on a click, and none was made
  ("count requests since start 0, refused 0").
- **Nothing stored says whether the frozen account would be given these chats' history:** no history read of an un-added
  chat was ever made, so there is no refusal and no success counted. Reads of chats it has added still work (section 7).

## B. Waits on requests that are not file parts

### 5. Per-method requests and waits
**Not kept.** The report counts plain waits for file parts per server only, plus message refreshes (one per file, 7 in
the last hour, 3,317 since the start 9.6 h ago, all with a changed file reference). It has no per-method count for
getHistory, getDifference or getChannelDifference, getMessages or users.getUsers. The unredacted console log is off limits.
Counting per method would need a code change in the fork.

### 6. Plain FLOOD_WAIT lengths on file parts
The split by length is **not kept**; the report has the count and total seconds asked per server per hour. Over the 22
unlimited hours since 11-08:

| Server | Waits | Seconds asked | Mean | Hours with any | Highest hourly mean |
|---|---|---|---|---|---|
| DC1 | 74 | 99 | 1.3 s | 14 | 1.8 s |
| DC2 | 55 | 73 | 1.3 s | 9 | 2.0 s |
| DC4 | 154 | 206 | 1.3 s | 12 | 1.8 s |
| DC5 | 3 | 117 | **39 s** | 3 | 52 s |

So on DC1, DC2 and DC4 nearly all plain waits are 1–2 s. DC5's few are long. No server's waits escalated into closing its
gate ("since start: none").

### 7. Frozen-account refusals
- **Today:** "refused as frozen false, deactivated false". The report's recent errors hold only 2 FILE_REFERENCE_EXPIRED.
- **Earlier (ANSWERS-for-archiver.md, 11-12):** no FROZEN_* error on file parts, message refreshes or history pages in 49 h
  of records. The only method refused was `channels.getFullChannel` (chat details). The fork skips it for 24 h on a frozen
  account since 12.25.
- **Never signed out:** no AUTH_KEY_* or SESSION_* error has been reported. Not checked beyond the current report and those
  earlier records.

## C. For the bring-in

### 8. Stored message records
**Yes.** All 325,671 stored media messages have a record, and every one decodes with gotd and carries a server: 236,161
documents and 89,510 photos.

| DC1 | DC4 | DC2 | DC5 |
|---|---|---|---|
| 183,008 | 91,066 | 26,469 | 25,128 |

None lacks a record. No web-page or other media kinds are among them. The whole read took 1.5 s.

### 9. Partial downloads and kept parts on disk
- **Partial downloads kept for resuming:** 10 files, about 0.8 GB reached. None of these files is saved yet.
- **Parts kept from copy checks:** 36,799 parts, 35.0 GB, of 3,949 files. All 3,949 are unsaved and queued (all have a
  stored message). Since the start, downloads reused 8.9 GB of kept parts in 1,129 downloads, with 0 refused.
