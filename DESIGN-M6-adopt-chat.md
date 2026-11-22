# Design note M6: an existing chat of the owner's as a source's mirror (a first design, 11-15 20:56, mirror session M3)

**State: a design to be put to the owner; nothing is briefed or built.** It writes to Telegram (forwards into a
chat the owner already has), so the owner sees it first. Written from what I read in full today (the settle's
three reviews, the automatic mirror's code, TELEGRAM-FACTS 11); the four points under "To read before the brief"
are not read yet and may change details.

## What the owner asked (11-15 12:38)
"A nice feature to have, in case I attach the app to an existing account, and want you to effectively create a
cloud mirror": instead of a new channel, the owner names a chat the account already has (the private chats the
owner filled by hand, 100 forwards at a time, are the case in mind) as the mirror of a source. What is already
in it must not be forwarded a second time.

## What the record already knows
- **The mirror itself says what arrived** (TELEGRAM-FACTS 11): a forwarded message names its source post; a
  source message that is itself a forward keeps its ORIGINAL origin in the copy; a hidden sender leaves none.
  The settle built on this ran for real: 65 of 99 told (64 by the post each forward names, 1 by the same
  media), none wrong, none twice.
- **Where those rules fail, from their three reviews:** an origin without a post number is a sender, not a post
  (never an identity); a repost inside the source and its original share one origin; an edit changes a
  message's media rows on one side only; alternative-quality rows differ between a source and its copy. Each
  of these was a second copy or a hole until the rules said "cannot tell" for it. Adoption meets all of them
  at once, over a whole chat instead of one batch of 100.
- The old app has nothing here (it never forwarded). Its lesson that binds (the live lessons' 6b, TRIED-BEFORE
  24): what the app does by itself stays below the owner's choices and visibly the app's; a person's choice is
  never undone; one costly failure ends the step.

## The design
1. **Only the owner's command, never the automatic task:** `mirror -adopt N -into M` (N: the source's chat
   number, M: the existing chat's). The plan is read-only and sends nothing. It refuses, in fixed words, when: N
   already has a mirror or a want; M is the app's own mirror, or is itself being mirrored, or is N; M is not a
   channel or supergroup the account can post in; either is marked "never"; N is known to be protected.
2. **First yes: M is read whole** by the reader (messages only; its cost shown first, as every read: one request
   for the estimate, then the pages). M's own switch for downloads is the owner's and is not touched. N is read
   as a mirror reads it (to its end) if it is not yet.
3. **What is already there, told from the catalogue, no request:** for every message of N that a mirror would
   forward (media only by default): "there" when exactly one message of M names it as its source post, or (for
   a message with no such origin) when exactly one message of M and exactly one of N share its current main
   media and no other message of either side holds any row of it; "not there" when no message of M shares
   any media row with it and none names it; **"cannot tell" in every other case.** These are the settle's
   rules, applied to the whole chat; nothing is guessed.
4. **The counts, then a second yes:** "of N's X messages: A are in the chat, B are not, C cannot be told; B will
   be forwarded in about K batches, after what is there (so the chat is not oldest first)". For the C the
   owner gives a word, as at a settle: taken as there (never forwarded: a hole if wrong) or taken as not there
   (forwarded: a second copy if wrong); without a word they wait and block nothing else.
5. **The record:** one mirror row for N with M as its chat, marked as adopted by the owner (a new column: a
   schema step), its stored name M's title as it is. The rows of 3 are written as forwarded with their copy's
   id. An adopted chat is never renamed, emptied, switched off or counted as "made by the app"; the name rule
   does not apply to it.
6. **From then on it is a mirror like any other:** the usual batches (the pause, the bound per hour, an album
   never split, every wait slept in full, an unknown outcome settled from the chat, never sent again). The
   automatic task keeps it current only if the owner says so in the same command (`-keep-current`, off by
   default: an adopted chat was filled by hand, and the owner may want to go on doing so).
7. **What differs for a settle later:** an adopted chat holds messages the ledger does not explain (the owner's
   own posts and forwards from elsewhere). The settle counts those as "not the batch's" only when they share
   no media row with the batch; otherwise it is "cannot tell" and waits for the owner. So an adopted chat asks
   the owner more often than an app-made mirror: said in the plan.

## What it costs and what is not known
Requests: M's read (pages of 100) and N's, then B/100 forwards; no create, so nothing against the 500. Not
known: whether forwards into a group pace differently from forwards into a channel; how many of a hand-filled
chat's copies carry no post-naming origin (the test mirror: 1 of 751; a chat forwarded "without quoting the
source" would have none, and then only the media rule tells anything).

## To read before the brief (not read yet)
- `internal/catalog/mirrorsettle.go` `weighBatch`: whether its passes can run over a whole chat (tens of
  thousands of messages) or need a set form; its cost at size.
- `AdoptMirror` and `OpenMirror` (the adoption of a lost create's channel): what of it can be reused, and what
  assumes the channel was made by the app.
- Whether the chat list's record says the account may post in M (creator or admin rights): if not stored, the
  plan cannot refuse beforehand and the first forward would be the test (one refused request).
- Every reader of `chat.mirror_of` (the look, the counts of chats made off, the viewer): what an adopted chat
  must and must not inherit.

## For the owner (one line on the board's waiting list)
Recommended: as written, with two choices that are yours: (a) messages that cannot be told wait for your word
(never guessed); (b) an adopted chat is kept current by itself only when you say so.
