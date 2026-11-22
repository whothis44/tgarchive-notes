# G4: mirroring a chat from the Chats page: what each click sends (pages track, session P3; written 2026-11-15; corrected 11-16 05:05 after the second review's fix round; the stop's line corrected 11-16 05:50)

For the owner to read; one page. The owner, 11-15 23:20: "add in a functioning mirror option since that is
immediately useful and we've tested it." Nothing here is a new kind of request to Telegram: a mirror started
from the page is carried out by the same mirror task that ran for real on the test account on 11-15. The page
writes down your wish and shows the task's state. **Where it stands:** the page and the mirror track's side are
joined. In a test on the fake Telegram one mirror was made through the pages by the page's own path for a
chat never read: its size asked (1 request), the yes at that cost, the chat read (3 requests for 230
messages), one create, two batches of forwards, one request for Telegram's limits; the mirror then held every
message with a file once, in order. (A second review had found that such a chat could not be mirrored at all
once its size was asked; that is fixed on the branch, with this test.) It is not merged or installed yet, and
nothing of it has run against Telegram. **The first real click is yours, on the test account.**

## What you see
- On the Chats page each chat's row says its mirror in one of these words: not mirrored; not read yet;
  wanted, waiting for its read or its turn; waiting; creating its mirror; N of M forwarded (or N forwarded
  while what is left is not counted); complete (new messages follow); blocked, with why; stopped by you; ended
  for good, with why; never mirror (your mark); not possible (a private chat, a forum, a chat that forbids
  forwarding: each with its sentence); cannot be read now (then nothing is offered for it). For an account
  that is not signed in nothing is offered, said once for the account.
- "Mirror this chat" on a row, and "Mirror the chosen chats" for several ticked rows.
- On Settings: the name rule for new mirrors (prefix and separator, checked before it is stored, shown with an
  invented example) and "new messages go at once, or gathered for N minutes". Whether chats you join are
  mirrored by themselves is shown as a fact: today it is set when the program is started; the switch on the
  page comes with the mirror track's next piece.

## What each click sends to Telegram
| Click | Sent at the click | Sent afterwards by the mirror task, one request at a time |
|---|---|---|
| Open "Mirror this chat" (the plan) | nothing | nothing. The plan is counted from what is stored: messages, how many may be forwarded, about how many batches, your channels against Telegram's 500, the new mirrors of the last 24 hours against the bound (yours and the automatic ones together), protected or not (or "not known"), anything that blocks it, whether you stopped it. |
| A chat that was never read: "Ask Telegram how large it is" | 1 request (the button the Chats page has today) | nothing; the yes stays off until the answer is on record, so the read's cost is on the screen before you agree. |
| "Yes, mirror it" | nothing: one row is written (your wish; for a chat not read to its end whose size you asked first, your yes approves its read at the cost shown, refused if the estimate on record changed meanwhile; the chat is not switched on for downloads, and a chat nothing knew yet has its downloads switched off) | whenever the program runs for a signed-in account: (1) the chat read to its end by the reader, with its usual pauses; (2) one request for Telegram's limits per session; (3) one request that creates the mirror, a private channel of yours named by your rule, when the chat has none (counted against 5 new mirrors in any 24 hours; past it, the create waits); (4) the messages, oldest first, up to 100 a request, an album never split, at least the account's pause between writes (20 s, lengthened after any wait Telegram states; every wait slept in full), at most 10,000 messages in any 60 minutes; (5) a request with no answer is never sent again: the mirror chat is read and the batch told from it; (6) afterwards, new messages as they come. |
| "Mirror the chosen chats" (at most 20 at a click; every plan shown before the one yes) | nothing | the same, one wish per chat, in the table's order; never two requests at once. A chat you stopped, marked never, or whose mirror ended for good is left out and counted, by the page's last reading and again by each plan read at the click (a stop made elsewhere meanwhile is seen then): each is started again only from its own row. |
| "Never mirror" | nothing (one row) | a request that was already written down as going out is not recalled; no request for the chat starts after the mark. |
| "Allow again" (offered only where it lifts something) | nothing (one row) | it lifts your mark, an end for good or a wish's block (the button says which before you click); the task may then send for that chat again. It never undoes a stop of yours. A mirror made by the command and blocked: the page says so and offers its plan; where the mirror's side does not take a wish on it, the command. |
| "Stop mirroring this chat" | nothing (one row) | a request already written down as going out is not recalled; nothing more after it; what is in the mirror stays. "Mirror this chat again (ends your stop)" goes on with the same mirror. The chat's read by the reader ends with the stop as well (the mirror track's piece of 11-16, on the main branch), except for the one turn of the reader that was already under way at your click: at most 10 more requests for that chat's messages, no bytes; closing that last turn is Core's to decide. A stop and a new "Mirror this chat again" on a chat still being read lets its read go on from where it stopped (being brought onto the branch now). |
| A blocked mirror: one of the words the block offers | nothing: your word is written for that one block (refused, nothing written, if the block changed meanwhile) | the task carries it out in its own turn, by the command's rules: "settle by the rules" reads the mirror chat (1 request per 100 messages) and tells the batch from it; "taken as arrived" or "taken as not arrived" settles what the rules cannot tell (sent again under new ids only after Telegram refused a repeat); "it was not created" is offered only for a create that got no answer, and carried out only when no channel of that name exists and after a chat list stored since the create (else a second channel could be made: the words say so). Each is its own button, none chosen for you. Where a block offers nothing (the mirror chat refuses the read; a refused create), the page says to use "Allow again" or the command. |
| The Settings rows | nothing | nothing; the name applies to mirrors created from then on, the gathering from the task's next turn. |

## The bounds, as decided for the command and kept
Every wait Telegram states is slept in full and stored. At most 10,000 messages in any 60 minutes; at most 5
new mirrors in any 24 hours (a setting, 1 to 50); a message younger than 90 seconds waits (an album still
arriving is never split); a refusal of the account stops every mirror; a chat that forbids forwarding is
refused before any request and said so; a private chat and a forum are not mirrored yet and the page says so.
Nothing is downloaded by a mirror: whether a chat's files are downloaded stays its own switch.

## Three things that are new with the page, each with what is built until you say otherwise
1. **A mirror you ask for counts against the "5 new mirrors in 24 hours" like one the app starts by itself.**
   Built so (the mirror track agreed). So 12 chosen chats are created over three days unless you raise the
   bound.
2. **The mirror task runs whenever the program runs, for a signed-in account, and serves your wishes.** Built
   so: a wish no longer depends on how the program was started. The automatic take of chats you join is still
   the program's start with its switch; the page shows it as a fact.
3. **A chat that was never read is read for its mirror on your "yes", at the cost shown on the screen.** Built
   so. Its files are not downloaded by the mirror: a chat nothing knew yet is switched off; a chat already on
   your Chats page keeps its own switch, which decides whether its read queues files.

Not in this piece: renaming an existing mirror from the page, choosing an existing chat of yours as a mirror,
forums; a note on the page when the task dropped a word of yours (the mirror's side gives no such sign yet).
