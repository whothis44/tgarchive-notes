# Brief M16: after an unknown outcome, the automatic mirror settles by itself and never waits for the owner

Mirror track, session M-7, 11-22. For one Opus 5.5 coder at high effort. Copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-settle`, branch `wip/mirror-settle`, cut from the main head
e34f4f64 (it holds M14 and M15). Push your branch to `private` as you go (never any other). Commits:
`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Rules: `CLAUDE.md` in the project folder (privacy:
invented data only; nothing against Telegram; never open `C:\Users\trabi\tgarchive-app`). Tests: named tests and the
whole `internal/mirror` and `internal/collector/faketg` only; never the whole `internal/collector` or
`internal/catalog`; no race detector. Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`
before every `go`; `GOMAXPROCS=2 GOGC=25 -p=1`. You hand back a branch ready to list (gofmt, vet, the tests).

## What happened (11-22, the owner's catalogue read-only, counts only)
At the switch to the new build (about 01:58) one automatic mirror had 44 messages waiting (posted 21:46 to 23:23,
distinct, none known deleted). Batch of 44 at 01:58:42: Telegram ANSWERED (the hourly counters: 1 request, 1
answered), but the answer named none of the 44 (`internal/telegram/forward.go` ~974: "an answer naming none of the
messages": `UnknownError`, outcome unknown). The settle read the mirror chat: 0 of 44 there; all 44 put back
(`c_mirror_again`, attempt 0). Batch of 44 again at 02:00:44: answered again, none named, unknown again. Then
`AutoBlockAgain` ("the batch after a settle ended unknown or as a repeat again: mirror -settle decides"): the
chat waits for the owner. Not a repeat refusal, so Telegram did not carry the first one out either.
**Likely cause (one case, "looks like"):** the 44 were deleted at the source and the catalogue never heard (channel
deletions reach the app only while it follows the channel's updates); Telegram answers a forward of only gone
messages with an answer that names none (a batch of 1 gone message got MESSAGE_ID_INVALID on 11-21; a batch of 12
with 1 gone was answered with it missing). **Find it out in the fake's terms and say it in the hand-back; the real
answer is measured on the first day.**

The owner (11-21): "The owner will be away from the computer. Why wouldn't the mirror continue automatically?
That's the whole point." The integrator (11-22): an unknown outcome after a settle must be handled by the task
itself, never left for the owner. Bound the repeats, back off, count. **Never forward a message twice: the
settle's evidence (the mirror chat's own messages, which name their source posts) first, as now.**

## What to build (the automatic task; the `mirror` command may keep its own words but must not block the task)
1. **The source is asked before anything is sent again.** When a settle puts messages back ("not there"), and
   before any re-send after an unknown outcome, the task asks the SOURCE once for those ids: M6's id list
   (`internal/telegram/mirror_ids.go`, `channels.getMessages`, 100 ids a request, counted under its kind, its wait
   key; read it first). A message answered as gone (`messageEmpty`) is marked deleted exactly as a live delete
   marks it (as M6 does), so it is never a candidate again and counts as "deleted at the source" (M14's facts). Only
   the ones that exist are sent again. An answer that does not name every id, a wait over the bound or a failure:
   nothing is recorded; the chat is held under the back-off (10 min, 30 min, 1 h, 3 h, 6 h, then every 6 h; M14's).
2. **A re-send that ends unknown again (after a settle that found them not there, and the source says they
   exist):** no block. Settle again from the mirror chat after the back-off's first step (the forwards may simply be
   slow to show); then split: the messages go again in halves, then singles (each send preceded by its settle and
   the source check, as above), to find the message(s) whose forwards never get a named answer. A single message
   that ends unknown twice in this way is SET ASIDE (M14's `c_mirror_aside`, with words such as "no message named in
   the answer"), never sent again by itself; the rest go on. Bound: each message at most 3 sends in all; the chat's
   attempts follow the back-off; every request counted.
3. **Every other settle block becomes self-settling, without a second forward of anything:** (a) "a repeat after a
   settle" (RANDOM_ID_DUPLICATE for messages the mirror did not show): read the mirror again after the back-off; if
   they are still not there, set them aside with the refusal's words (Telegram says done, the mirror disagrees:
   never sent again, listed); (b) "cannot tell" messages (no post-naming copy, media not exclusive): set aside as
   "cannot be told" (never forwarded, listed); the rest go on; (c) "3 settles in 24 hours": a back-off hold, not a
   block; (d) "the mirror chat refuses the read": the chat is held and retried by the back-off (as M14's chat
   refusal); (e) a lost create with two or more channels of the mirror's name, ALL made after the intent: take the
   oldest, count the others as spares, as M15 does for topics (with any made before the intent: hold under the
   back-off and say it). Say in the hand-back every block of the automatic task that is left; the aim is none but
   the account's own end.
4. **The block of 02:00:44 on the owner's catalogue must clear itself after the install:** a want blocked with one
   of the settle words that M16 turns into holds is read as such a hold (no owner's Allow needed). Say how.
5. **Words the owner sees (asked by the UI track U-1):** a forum is mirrored since M15, yet the Chats page still
   says "a forum is not mirrored yet (topics come later)". Find where that comes from on the head (`mirror.go`
   `WhyForum`, `door.go` `case WhyForum: return ErrWantForum`, `livepages/mirrors.go` ~160, `server/demomirrors.go`
   ~192, their tests). Retire `WhyForum` and `ErrWantForum` wherever they no longer apply, so a forum takes the same
   path as any chat; the lines in `livepages` and `server` are lent lines (name them in the hand-back).
6. **Tests (fake Telegram):** the 44 case (an answer naming none for gone messages: the source check marks them
   deleted, nothing re-sent, no block); some exist: they go once more and arrive; one message whose forward never
   gets a named answer: found by the split and set aside, the rest arrive; a repeat after a settle; cannot-tell
   messages; three settles in a day; a refused mirror read; two channels of the name; a want blocked by the old
   words clears itself; across a restart. Count the requests in 24 h for the worst case.

## Hand back
Branch head pushed; files; requests added (where counted); every block left; the tests by name with result lines;
what you found about Telegram's nameless answer in the fake's terms; anything wrong in this brief.
