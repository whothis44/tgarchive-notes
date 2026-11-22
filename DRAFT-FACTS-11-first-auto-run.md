Draft for `archiver/docs/TELEGRAM-FACTS.md` section 11 (session M-7, read 11-21 21:10 from the owner's catalogue,
read-only, counts only). To be added on `wip/mirror-m14` after the coder's hand-back.

- **The automatic mirror's first real run (the owner's folder program, one account, since 11-19 00:30; read
  11-21 21:10):** 4 mirror channels made, each create answered within the second it began (no wait, none
  refused). 52 forward batches: 51 answered, 1 refused; 243 messages sent, 242 forwarded, 1 answered as
  missing; **no wait stated on any forward** (no batch waited, no forward wait on record). Batches of 1 to 86
  messages (28 of 1, 9 of 2; one of 86, a chat's history, answered in about 2 s); answers within 0 to 2 s by the
  catalogue's whole-second clock. Batches of the account 22 s to about 26 minutes apart (median 155 s; the pause
  is 20 s plus its random part). Every mirror is caught up: no media message of the four sources that is not
  deleted is outside the ledger. Over the busiest stretch, one mirror took 45 batches (118 messages) in about
  3 hours, about 15 forwards an hour, without a wait.
- **A message deleted at the source, by itself in a batch, is refused MESSAGE_ID_INVALID ("looks like": one
  case):** a batch of 12 with one message deleted at the source was answered (11 forwarded, 1 missing); a batch
  of 1 whose message was deleted was refused MESSAGE_ID_INVALID. The live monitor recorded that deletion 7 s
  after the refusal. Until M14 any refused batch blocked the mirror until the owner looked: that chat sent
  nothing for about three hours, and 38 media messages were deleted before they were saved. **They were
  not unique content (the integrator's read, counts only):** all 40 deleted media messages there came from one
  sender with one identical media set, the same media already kept once (a bot that posts and deletes its
  message); the chat's other deletions were 42 service messages and 2 texts. Mirror 3's chat shows the same
  shape with one sender's text (39 of 40 deleted, 3 distinct texts; median lifetime 30 to 49 s).
- **What a deleting source looks like:** about 25 posts an hour (61 single posts, 17 albums in 3.1 hours), the
  median gap between posts 69 s, 17 of 77 gaps under 30 s. Of the 38 media messages deleted before they were
  saved: 3 lived 20 s or less, 11 lived 90 s or less, 26 over 120 s (median 196 s). The old wait (90 to 120 s
  for every message) is longer than about a third of those lifetimes; hence the 5 to 20 s for single posts (M14),
  with exact repeats of a message already forwarded kept out of the mirror (M14 part C), so that such a bot's
  message is forwarded once.
- Not known yet: whether a batch of several messages that are ALL deleted is refused the same way; how fast
  the live monitor records a deletion in general (one case: 7 s); forwards per hour before a wait (none met at
  about 15 an hour).
