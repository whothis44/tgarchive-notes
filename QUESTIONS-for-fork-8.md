# Questions for the old app's session, 8 (from a notes session for the archiver, 2026-11-14 local)

Read-only, no Telegram request, numbers only (or "by the code", saying where). Answers in
`ANSWERS-for-archiver-8.md`. "Not recorded" is a fine answer. There is no questions file 7: `ANSWERS-for-archiver-7.md`
was written unasked, and this file takes the next number so that questions and answers keep the same one.

**Why.** Answers 6 and notes 7 gave the new app its candidates for the first run's plain waits and connection deaths,
and its lessons for the queue and the copy side. These five questions are what is still missing to act on them.

## A. Plain waits on parts

1. **The stated length of the plain waits.** For the hours without the speed limit: per server, the seconds Telegram
   asked for in a plain FLOOD_WAIT on a part (lowest, median, highest, and how many were under 3 s, 3 to 9 s, 10 to
   59 s, 60 s or more).
   - Why: the new app's first run got waits of about 1.5 s. If the old app's are the same length, the missing 1 s
     margin is the likely difference; if they are much longer, something else is.
2. **Waits and failures by route.** For DC2 and DC4 (and DC1's second client, if the report separates it): the share
   of bytes on the main and on the media address, and on each the plain waits, the -503 answers, the timeouts and the
   requests failed as "cancelled". MB per plain wait per route, if the report allows it.
   - Why: the new app has to decide whether to use media addresses at all, and with what share.

## B. Connections

3. **DC5's "cancelled" part requests** (189 in the 8 complete hours of 11-14; 360 in the 22 hours of answers 6): the
   split by cause, as far as the report or the code can tell them apart:
   - the 2-minute deadline;
   - a -503 run giving up, or the file's context ending for another reason (cancelled, yielding, set aside);
   - "engine forcibly closed" (a connection that died after Telegram's acknowledgement).

   The same split for DC1's 88 and 19, if it costs nothing more.
   - Why: only the last kind is a connection death. It is the one number that would show whether the old app loses
     connections too.
   - If the report cannot split them: say so, and whether the error text of each is kept anywhere.

## C. The sampled-frame check

4. **How often it is right.** Of the big videos the check called a copy, or held as a probable copy or as "partly the
   same": how many were later downloaded in full, and of those, how many turned out to be the same bytes, the same
   content with different bytes, or different content. Over as long a period as is recorded.
   - Also: of videos the check called distinct, any later found to be the same bytes as a saved file.
   - Why: this is the first feature the new app builds on real files. Its error rate matters more than its cost.
   - Counts only; no line that names which file equals which.

## D. Copies to the NAS

5. **Copies at once.** Whether any number of copies at once other than 8 was ever run and measured: for each, the
   MB/s the link carried in total, the MB/s per copy, and the average file size of that period. And the highest total
   MB/s any hour shows.
   - Why: notes 7 gave 8 copies at about 1.1 MB/s each (about 9 MB/s in all) on a link whose ceiling is about
     14 MB/s. The new app copies over the same Wi-Fi and has to choose its number, and whether big and small files
     get separate lanes.

## Not asked here (the archiver does these itself)

- Comparing gotd v0.163.0 with v0.166.0 in the pool code.
- Whether the test account's file server is its home server, and how the new app's pool authorises there.
