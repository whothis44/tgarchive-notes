# Brief K20: downloads only in hours without the speed limit (Core, K-6, 2026-11-22)

**The owner's decision** (CLAUDE.md, the mirror; the old board's items 10 and 21): downloads of a chat joined while
away are a setting with three values: off, only in hours without the speed limit, always. K28 (`wip/core-newdl`, listed)
made it a stored setting `catalog.new_chats_download` with `off` and `always`; `unlimited` is reserved and refused until
this piece (`newChatsAccepted`). The owner on item 21: probing is fine. While a server is under the limit and only
files of "unlimited only" chats wait for it, one part of one such file per server every few minutes; an answer
without a speed-limit wait opens the server for those files, and the next speed-limit wait closes it. Every wait is
slept in full. **This changes the download path: one independent review follows it.**

**Read first, yourself:** `C:\Users\trabi\Claude\Projects\Telegram\NOTE-K20-unlimited-hours-record.md` (the record, and
the shape at its end), `DIGEST-LESSONS.md`, and the copies track's answer below. The old app's detector and the new
engine's are the same numbers (`internal/engine/lane.go` `notePremium`, `LimitedWaits` 3 within `LimitedWithin` 1 min,
cleared after `LimitedQuiet` 2 min): nothing to change there.

**The copies track's design for the walk (C7, agreed):** a key column, the way `huge` already is (`schema4.go`: "a lane
that may not take one passes over them by the key"). `c_want` gets a stored column `unl` (1 when no chat that carries
the file as its own media is "always"), kept by triggers from the chats' values (as `best_rank`, `home` and the partly
mark are). It goes into `c_supply`'s key right after `tier` (`tier, unl, huge, ...`). A limited lane walks `unl = 0`
only (an empty range costs two seeks); a lane without the limit merges both by key, as it merges `huge`. Tier 5 (held
probable copies, `lane.go`, `state.go`) carries it too. **Never a walk proportional to the queue per pick**
(TRIED-BEFORE 22). Lent lines in `internal/supply` and tier 5 are yours for this piece; copies reads that diff before
the review and then makes `HeldProbeNext`'s one-line follow-up (tell them the column's name).

**Rules:** you are the one Opus coder. Named tests and small packages only; never the whole `internal/collector` or
`internal/catalog`; every go command through `bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go2.sh <folder> ...`.
Invented data only; nothing against Telegram (the fake only); never touch a running program, the main copy,
`C:\Users\trabi\tgarchive-app` or `E:\`. **Cut from K24's latest head** (`wip/core-oldroot`, which rebuilds `c_supply_src`)
and merge K28 (`wip/core-newdl`) in: copy `wt-core-unl`, branch `wip/core-unl`. A schema step: on the branch after the
newest step on your tree; I claim the number on the board. Commit form as always; push only your branch.

## What to build
1. **The chat's value:** a column per chat, `dl_when`: `always` (default for every chat the owner chose and every
   existing row) or `unlimited`. A chat first met while the stored setting is `unlimited` is made collecting with
   `dl_when = unlimited`. A door for pages to set it per chat (`SetChatDownloadWhen(ctx, chat, value)`) and its read.
   Add `unlimited` to K28's accepted values.
2. **The column, its triggers and the key** as copies' design says; the step rebuilds `c_supply` with the new key.
   Any later rebuild of the view starts from K24's `supplySrcBroughtInSQL`.
3. **The walk:** a limited lane asks only `unl = 0`; an unlimited lane both. The lane's `limited` is the engine's own
   detector. Show by test that a limited lane's pick costs the same with 0 and with 100,000 `unl` files waiting.
4. **The probe:** only on a server that is limited, has nothing else in flight, and has `unl` files waiting: one part
   of one such file every N minutes (a stored setting, default 10, a random part of up to half of it, no upper bound of
   the app's own; the owner's timer rule). A speed-limit wait on it is slept in full and keeps the server closed; a
   clean answer lets the detector clear after its 2 quiet minutes, and the lane then walks `unl` files too. Count
   every probe per server and hour (requests, clean, limited).
5. **The counters:** a limited lane with only `unl` files left reads "waiting for hours without the speed limit",
   never "out of supply" (TRIED-BEFORE 23), on the status file and the lane's state words.
6. Never held, aside or skipped by this: an `unl` file stays wanted, and only the pick passes it over.

## Tests (each seen failing first; the fake Telegram, which can answer speed-limit waits)
A limited lane never takes an `unl` file and takes the others; the moment it is not limited it takes `unl` files; a
file carried by one `always` and one `unlimited` chat is never `unl`; a chat switched between the values moves its
files' `unl` (triggers); the probe fires only as item 4 says, at most one part per server per interval, its wait slept
in full, counted; the pick's cost flat in the number of `unl` files; tier 5 likewise; the counters' words; K28's setting
accepts `unlimited` and a chat made under it is `dl_when = unlimited`. gofmt, build, vet; the viewer's `TestWall`.

## Hand back
`archiver/docs/progress/core-unl-REPORT.md` and your last message, short: head pushed; the schema step; the column's and
the doors' names (for pages and copies); the probe's numbers on the fake; the tests as run; what the code contradicts here.
