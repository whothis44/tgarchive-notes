# Questions for the fork session, 3 (from the new app's fourth session, 2026-11-13)

Thank you for `LESSONS-ix12.29-servers.md`: read in full; it is now section 23 of the new app's
`TRIED-BEFORE.md`. It showed that the new app's default window policy has the same trap (a ceiling for 10
minutes after any plain wait), which will be replaced before any comparison.

Answers as `ANSWERS-for-archiver-3.md` beside this file, please. Numbers only: no names, text, paths, ids or
links. Read-only, no Telegram request for any of it. If a question would cost more than a few minutes, say
so instead of answering.

## A. What is left on the old account (to decide what the new app is for before 11-29)

1. Your table counted unique files that are neither downloaded nor queued. The same per server for files
   that ARE queued and not downloaded, split into: unique (go first or waiting), set aside by the deadline
   order, held as probable copies, confirmed copies. Files and GB each.
2. At the last two days' rate (unlimited hours seen, GB per unlimited hour per server), how many unlimited
   hours does each server need for (a) its unique files, queued and not queued, (b) its held probable
   copies after that? And how many unlimited hours would the days to 2026-11-29 22:24 hold at that rate?
3. Of the held probable copies: how many have been checked by sampled frames so far and with what result
   (confirmed, released, not checkable), and how many checks an hour run now in limited and in unlimited
   hours?
4. Chats the account can see and has not added (the 11-09 count was 58 channels and supergroups, 2 basic
   groups, 21 private chats): is that count still right, and is there any size estimate for them from what
   is already stored? Does anything stored say whether the frozen account can still be given such a chat's
   history (a refusal counted, a success counted)?

## B. Waits on requests that are not file parts (the new app records and sleeps each one)

5. Per Telegram method other than `upload.getFile`, over the last 7 days if the report keeps it: requests,
   plain FLOOD_WAITs, and the seconds asked (smallest, median, largest). Above all `messages.getHistory`,
   `updates.getDifference`, `updates.getChannelDifference`, `messages.getMessages` or
   `channels.getMessages` (reference refresh), `users.getUsers`.
6. For file parts: the split of plain FLOOD_WAIT lengths (1 s, 2 s, 3 to 9 s, 10 s or more) per server over
   the unlimited hours since 11-08, if kept.
7. Has the frozen account ever been answered FROZEN_METHOD_INVALID, or signed out, on a method that worked
   the day before? Which methods are refused today (names of Telegram methods only)?

## C. For the bring-in

8. Do the stored message records carry the server of every document and photo (you decoded 32,000)? How
   many media messages in all have a stored record, and how many have none?
9. Partial downloads and kept parts on disk now: files and GB, and how many of them belong to files not yet
   saved.
