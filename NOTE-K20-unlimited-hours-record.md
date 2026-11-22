# Downloads only in hours without the speed limit: what the record says (Core, K-5; started 2026-11-16 18:10; NOT COMPLETE)

For the piece after K17, K19 and K18 (the owner's items 10 and 21; "Listed and unbuilt": the middle value of
"downloads for a chat joined while away: off / only in hours without the speed limit / always"). This note is
written while the history is read, so that the reading is not lost if the session ends. **It is not a brief
and the reading is not finished: nothing on the download path is proposed from it until the list at the end
is read through, by the session that writes the brief, itself.**

## Read so far (by K-5, in full)

`repo-archiver/archiver/docs/TRIED-BEFORE.md` sections 1 to 17 (to the middle of section 17, line 420 of the
file as of 78739d59).

## What it says that bears on this piece

- **The limit is per server and comes in solid blocks** (section 14): its start is staggered 5 to 10 minutes
  between servers; it lifts on all servers together. So "is the limit on" is a fact per server, and a lift
  seen on one server is a strong hint for the others, not a proof.
- **What a limited server brings** (section 14, the old app, one account without Premium, 2 parts, about 400
  to 420 speed-limit waits an hour each time): 516 to 626 MB an hour per server (11-06 to 11-08), about 400
  (from 11-08 21:00), about 200 (from 11-10 16:00). The regime marker is MB per speed-limit wait (section
  16: 0.9 before 11-10 16:00, 0.45 after). Unlimited hours on 11-08: 103.0, 87.0 and 74.3 GB an hour over
  all servers (section 15).
- **Spells** (section 14): 4 h without the limit then 8 h with; 2 h then 8 h; 6 h then 17 h; 3 h then more
  than 24 h. "No evidence either way that fewer requests make the limit lift sooner." Open and never
  examined: whether the allowance and a limited spell's length depend on how much was taken before. Plan for
  unlimited hours not returning at the old rate.
- **An idle server under the limit gives the others nothing** (section 16): each busy server brought its own
  350 to 400 MB an hour. So the owner's phone and this app share one allowance per server: what the app
  takes under the limit, the phone does not get (the owner's reason for the setting, item 10).
- **A speed-limit wait holds the request that got it and nothing else** (section 2); which limit applied
  could only be read once the figures were per server (12.4).
- **At most 2 parts under the limit; nothing is learned or tried under the limit** (section 1). Compare only
  adjacent hours of one regime; "looks like" for one day (section 13).
- **Under the limit larger files bring the same bytes for fewer reference refreshes; files of 1 GB or more
  were left for unlimited hours** (section 4, 12.24): the old app already had a class of files that waits
  for unlimited hours, by size. Its code is the thing to read for "how did it know the hour was unlimited".
- The owner's decision (item 21, 11-15 19:49): probing is fine: while a server is under the limit and only
  files of "unlimited hours only" chats wait for it, one part of one such file per server every few minutes
  (at 10 minutes about 6 MB an hour, about 3% of a limited server's 200 MB); an answer without a speed-limit
  wait opens the server for those files, the next speed-limit wait closes it. Every wait slept in full.
- The owner's rule for timers that pace requests to Telegram (11-16 09:20, the mirror's chat list): a
  catalogue setting with a short default and a random part. The probe's interval is such a timer.

## Not read yet, in this order (all in full before a brief)

1. `TRIED-BEFORE.md` from section 17's second half to the end (sections 18 to 28; 24 to 26 and 28 named by
   the board for anything that acts for the owner and for speed claims).
2. `LESSONS.md`, `WINDOW-EVIDENCE.md`, `TELEGRAM-FACTS.md` (section 5 and the speed-limit facts) in
   `repo-archiver/archiver/docs`.
3. `LESSONS-ix12.29-servers.md`, `LESSONS-ix12.30-live.md`, `ANSWERS-for-archiver-4.md` to `-9.md` in the
   project folder.
4. The old app's code for the limit's state per server and for "left for unlimited hours" (`wt-v12.32`,
   `core-service/internal/telegram/pacer.go` and what reads it; the 12.24 changelog entry), with its number
   beside ours.
5. The new app's own: where the engine counts a speed-limit wait per lane (the heartbeat's "speed-limit
   waits"), the Supply's walk (the copies track's: asked on the board before anything is cut), the mirror
   track's `-download` switch (the "off / on" that exists), `FEATURES.md` section 12 on the setting.

## Open design points seen so far (for the brief; none decided)

- While other chats' files download on a server, the limit's state there is known for free from their
  requests; the probe is needed only for a server on which nothing else is in flight.
- "Opens" and "closes" need a rule that does not flap at the block's staggered edges (one wait closes; how
  many clean answers open?), and a count of every probe request per server and hour.
- Where the mark lives: per chat (the setting's three values), so a file carried by an "always" chat and an
  "unlimited only" chat is wanted at once; a schema step; the walk must pass over such files cheaply.

## Read by K-6 (11-21 21:15): TRIED-BEFORE sections 17 (second half) to 28, in full
- **Files of 1 GB or more, one per server, "only when the server is not limited or has nothing else"** (sections 18 and 20, the old app's 12.25): the old app already gave a class of files to unlimited hours; the new app has no such rule ("missing" in section 20's table). The same mechanism as this piece, by size instead of by chat.
- **Under the limit: 2 parts per server; under the limit each server gave the same with 4 or 7 files** (sections 18, 20, 23); about 190 MB an hour per server since 11-10 16:00 whatever the parts. Unlimited hours: 60 to 100 GB an hour on the old account; one part brings 3.5 to 4 MB/s.
- **"Is the limit an allowance that recovers?" never settled** (section 19): it lifted twice after quiet stretches and once without. Nothing in the record says that leaving the limited hours to the phone shortens the limit.
- Speed-limit waits in the old app: about 14 to 16 s each, thousands a day per server (section 27). So the state "limited" is seen many times a minute on a busy server: the probe is needed only where nothing else is in flight (as the open point above says).
- Section 26 rule 3: other servers are kept fed so their own allowance is not wasted; section 28 rule 1: a number is a defect only beside the old app's for the same server and regime.
- Section 19: "stop taking new work" is its own state, never touching a file's held or aside state: an "unlimited hours only" file put off under the limit must not be a held or aside state; it is a filter at the lane's pick.
- LESSONS.md (read in full by K-6): the limit "in solid blocks, starts staggered 5-10 min between servers, lifts together, spells 5-9 h (about 1.2 lifts a day until 11-10, then 21+ h on); fewer requests did not lift it" (section 5); "an account-wide lane of 2 big files let one server hold both while others idled (12.25)": a class of files kept for some hours must be judged per server, never account-wide; under the limit about 400 MB/h per server whatever the sizes, so larger files cost fewer refreshes (12.24). The owner's word (section 6): remove work rather than add waits; "speed-limited" was once shown for plain waits (12.7): the state must come from speed-limit waits (FLOOD_PREMIUM_WAIT), never plain ones.
- TELEGRAM-FACTS sections "What changes the design" to 2 (read by K-6): FLOOD_PREMIUM_WAIT_X is the documented non-Premium download limit, "can only be received when the user has uploaded tens of gigabytes or more"; the tdesktop maintainer described a monthly allowance (community, unverified). TDLib calls `notify_speed_limited` on it: the official clients know the state from that error alone, per query. Nothing documented about when it lifts.
- WINDOW-EVIDENCE (read in full by K-6): under the limit the floor (2), no tries, nothing learned; the window rule's "tries only while not speed-limited" (rule 6) already needs a per-server "limited" state: the engine's lane has `speed_limited` in the status file (`statusLane.Limited`): that state is the one to read, not a new one.
- LESSONS-ix12.29-servers.md (read in full by K-6): **"Check the server's own speed-limit waits from the last minutes, not only the 'capped' flag. A server already at 2 parts is never capped, but it is still under the limit"** (section 4, the 12.30 review's trap): the open/closed state for "unlimited hours only" files must be judged from that server's speed-limit waits over the last minutes, never from a window flag. Each FLOOD_PREMIUM_WAIT asks about 15 to 16 s; 12 of 47 hours had no limit (11-11 to 11-13); volume comes almost entirely from unlimited hours (60 to 100 GB an hour against 0.4 to 0.8). Per-server supply is knowable with no request (the stored message record names the server). Rule 4 (persist waits) and rule 13 (fail closed) apply to a probe's state.
- LESSONS-ix12.30-live.md (read by K-6; the parts on the limit and on acting for the owner): unlimited hours come in irregular spells, about 6 hours a day on average (a 10-hour spell, then none for 24 hours; the longest 14 h, 733 GB, 11-14); **"when one starts, every server must already have work queued"**: so an "unlimited hours only" file must be wanted and waiting at its lane's door (passed over at the pick while the server is limited), not added when the hour begins; under the limit about 190 MB/h per server, allowances separate; §6b: what the app adds by itself stays below the owner's choices (an "unlimited only" chat's files go behind the owner's chosen chats in the lane's order as today: no new rank).
- ANSWERS 4 to 9 (searched by K-6 for every passage on the limit; their other matter, waits, pools and copies, is read for those pieces): a lift is a clean edge per server and hour (11-14: 87 speed-limit waits in the 00:00 hour, 0 from 01:00 for 8 hours; 11-13 DC4: 138 in 03:00, 0 in 04:00); the old app's own definition of an unlimited server-hour is "no speed-limit wait on that server in the hour" (answers 7, 8, 9); a speed-limit wait is about 14 to 16 s; the first hour after a lift can bring a burst of plain waits (DC4 116 at 11-13 04:00, ended by itself): plain waits are no sign of the limit.
- The old app's code (`wt-v12.32` `core-service/internal/telegram/pacer.go` `speedLimitedLocked`, read by K-6): a server is speed-limited while it had a speed-limit wait of its own in the last 2 minutes (`paceCapQuiet`) or is still capped (3 within a minute, `paceCapWaits`, `paceCapWithin`). Its 1 GB rule (12.25): per server, 1 big file at once, 2 when nothing smaller can start; its automatic update waits for the limit (12.27). **The new app's engine has the same detector already:** `internal/engine/lane.go` `notePremium` (3 speed-limit waits within 1 minute mark the lane limited: `LimitedWaits`, `LimitedWithin`) and the tick clears it after 2 minutes with none (`LimitedQuiet`); `statusLane.Limited` shows it. **Old app 3 / 1 min / 2 min, new app 3 / 1 min / 2 min: the same numbers; nothing to change.**

## 11-21 21:17 READING DONE (K-6). The shape for the brief (not yet a brief; the Supply's walk is asked of copies first)
1. The mark per chat: the three values (off / only in hours without the speed limit / always) as the chat's own row (a schema step); "off" is today's switched-off chat; the mirror's `-download` switch maps to "always" today.
2. The pick: a lane passes over a file whose every wanting chat is "unlimited only" while the lane is limited (the engine's own `limited`, never a plain wait, never the window); never a held or aside state (TRIED-BEFORE 19), never ahead of the owner's chosen chats (12.30 6b); the file is wanted and waits at the lane's door so an unlimited spell finds it queued (12.30 rule 4).
3. The probe (the owner's item 21): only on a server that is limited, has nothing else in flight and has such files waiting: one part of one such file every N minutes (a stored setting, default 10, a random part: the owner's timer rule); a speed-limit wait keeps it closed (slept in full); a clean answer and 2 minutes without a speed-limit wait open it (the engine's `LimitedQuiet`). Every probe counted per server and hour; at 10 minutes about 6 MB an hour a server (3% of a limited server's 190 MB).
4. Open for copies: how the Supply's walk passes over such files cheaply (an index or a lane-side filter), asked on the board.
