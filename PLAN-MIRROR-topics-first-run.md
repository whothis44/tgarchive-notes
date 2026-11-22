# Plan: the first real forum mirror (M15), measuring what a topic costs (mirror track, M-7, 11-21)

Nothing here runs before M15 is merged and installed and the owner starts it. On the test account only, VPN on.

**What is known:** creating a mirror chat: 1 request, answered within a second, no wait (TELEGRAM-FACTS 11,
first automatic run: 4 creates). Forwards: about 2.4 s per batch of 100, no wait at a pause of 20 s; one 9 s wait
at a pause of 10 s. **Creating a forum topic has never been tried; renaming one neither.** No number on record
for how many topic creates an account may make in an hour.

**The run:** the owner wants the mirror of ONE forum of the three (the smallest that has more than one topic is
the safest first: 7 topics, about 70 media messages; then the one with 10 topics and about 8,250 media messages
as its history). The app sends, in this order, each a write after the account's pause (20 s plus 0 to 10 s):
1 create of the forum mirror; then per source topic with candidates, 1 topic create before its first forward;
then the forwards, one topic per batch, oldest first.

**Expected cost, 7-topic forum:** 1 create + 7 topic creates + about 7 to 10 forwards (topics' runs of up to 100)
= about 15 to 18 writes, at about 25 s apart: about 7 minutes, if no wait is stated. 10-topic forum: 1 + 10 +
about 85 forwards (8,250 media messages, batches of up to 100, split by topic): about 96 writes, about 40 minutes.

**What is measured and read afterwards (counts only, from the log's mirror lines and the catalogue read-only):**
per kind (create mirror, create topic, rename topic, forward): requests, answer time (smallest, median, largest),
waits stated and their seconds, refusals by type; whether the mirror's topics are as many as the source's and
each message sits in its topic (read from the mirror chat by the settle's read, one request); renames: one change
of a topic's title in the source by the owner, then the one edit and its answer.

**What ends the run early:** any stated wait over 60 s on a topic create (the pause is then doubled by the
existing rule; the owner is told the number), a refusal of a topic create (the want is blocked by design), an
unknown outcome (settled by one read of the mirror's topic list).

**Into TELEGRAM-FACTS 11 the same hour:** the numbers above, "looks like" for one run.
