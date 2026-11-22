# The app used like a Telegram client: the acting side (design note, Core, 2026-11-15 20:47)

For the owner to read before anything is briefed or built. It writes to Telegram, so nothing of it is
started without the owner's word. The reading side (a chat opened at its newest message, live, with
replies, edits and reactions shown) is the viewer track's and sends nothing; this note is only about
what ACTS: send, reply, edit and delete one's own, forward to a chat, react, mark as read.

Listed in `FEATURES.md` section 12, sixteenth round; board message 48 and item 25.

## 1. What already exists (read by me, in the code and the lessons)

**The base app and the old app (`wt-v12.31`):**
- "Auto-forward" (`core-service/internal/telegram/forward.go`, `internal/app/forward.go`): it does not
  forward. It uploads the downloaded file again to a destination (`messages.sendMedia`), with a new
  random id at every try, up to a few tries after a stated wait (the wait plus 1 s). A lost answer is
  "failed"; a later try would post a second copy, and nothing looks first. Whether it ever ran on the old
  account is not on record.
- Leaving a chat (`dialog_remove.go`, `chat_leave_api.go`): only with the chat's own number typed back as
  the confirmation, the chat list read once, 1.5 s between two removals of a batch.
- **Nothing in either sends a text, replies, edits, deletes one message, reacts or marks as read.** So
  there is no number from the old app for any of these requests: no "sends per minute before a wait",
  nothing. The only numbers on writes are the new app's own, from the mirror (below).

**The new app, merged and run for real on the test account (`internal/telegram/forward.go`, `call.go`;
`TELEGRAM-FACTS.md` section 11):**
- A request that writes is sent exactly once (`once`); a wait Telegram states is recorded before it is
  slept, slept in full plus 1 s, and reported as "not carried out"; no answer (a timeout, a lost
  connection, a server error) is "outcome unknown" and is never sent again by the program.
- `USER_RESTRICTED` and `PEER_FLOOD` are final for the account: recorded in the catalogue before
  anything else, every later call refused without a request, cleared only by the owner.
- Every request is counted per kind and hour; waits by length; nothing of a title or text in a log.
- Measured (five runs, "looks like"): a stated wait meant nothing was done; a server error meant "partly
  done" (65 of 99 forwarded); the chat itself said what had arrived; 200 messages in 13 s brought a wait,
  the same at 20 s apart did not.

**So the acting side is built on that request layer, not anew:** the same `once`, the same record of
waits, the same account refusal (one record for the mirror and the client: a refusal stops both), the
same counters. What is new is small: six request kinds, a ledger of the owner's clicks, a turn for them
on the account's one connection, and a local door.

## 2. The requests

One click is one request. No request is made for typing, for being "online", for a draft, or for a link
preview while typing: the app never shows the account as typing or online.

| The owner's action | Telegram's request | Repeating it would | After no answer |
|---|---|---|---|
| Send a text | `messages.sendMessage`, with a random id made once per click | post a second message | "Not known": the owner decides (section 5) |
| Reply | the same, naming the message replied to | post a second message | the same |
| Forward messages to a chat | `messages.forwardMessages` (up to the server's maximum, an album whole), a random id per message made once per click | forward a second time | the same |
| Edit one's own message | `messages.editMessage` | change nothing (Telegram answers "not modified") | shown as not known; the chat's next update says which |
| Delete one's own message | `messages.deleteMessages`, or `channels.deleteMessages` in a channel or supergroup | change nothing | the same |
| React | `messages.sendReaction` (one of the plain emoji; never a paid one) | change nothing | the same |
| Mark a chat as read | `messages.readHistory` or `channels.readHistory`, up to the newest message shown | change nothing | the same |

- **Text only in this step.** Sent as typed (no formatting marks read). At most Telegram's own length
  (asked from the server's configuration, never assumed); a longer text is refused on the page, not cut.
- **Never paid:** no request sets a flag that spends Stars (paid messages, paid reactions). A chat that
  asks for payment answers a refusal, which is shown.
- **Delete** asks once more on the page before the request (it cannot be undone), and says whether it
  deletes for everyone or only for the owner where Telegram offers both. **The archive keeps the message
  and its files, marked deleted**, as for any deleted message.
- **Mark as read** is a switch, off. Reading in the app marks nothing on Telegram unless it is on. On:
  one request when a chat is opened at its newest message and something there is unread, at most one per
  chat in 30 s.
- **Forward** takes its source from any chat the account can read. A chat known to be protected (the
  "protected" flag, Core's K4) is refused on the page before any request.
- **The app's own mirror chats cannot be written to from the client** (refused in fixed words, no
  request): a mirror holds forwards only, and the settle's rules judge what is in it.

## 3. The path of a click

The viewer and the window have no Telegram client and keep none. Every request is the collector's, on the
account's one connection.

1. The page (the viewer's conversation, or the app's own pages) posts the action to **the collector's
   local door**: routes under `/api/act/` on the collector's own listener on 127.0.0.1 (the one G1 opens
   for the pages). The door keeps the pages' existing rules for anything that changes state
   (`internal/server`: POST only, the page's token, the Host and Origin checks, "same-origin" only), so a
   web page open in the owner's browser cannot send a message through it. The viewer is another program:
   its own server passes the click on to the collector's door with a secret both read from the program's
   folder, and only from its this-PC listener. **From another device at home: not in this step** (its own
   security look first, as the home-network mode had).
2. The door checks, with no request to Telegram: the account is signed in and running, not frozen, not
   refused; no stated wait is running for this kind; the chat can be addressed (its access hash is on
   record) and is not a mirror; the text's length; the cap (section 4). Any "no" is answered at once in
   fixed words.
3. **The click is written down before it is sent:** one row in a ledger in the catalogue (the account,
   the chat, the kind, the target message, the random id, the text until the outcome is known, the state
   "sending"). A crash or a kill between the write and the answer leaves "sending", which the next start
   shows as "not known" (never sent again by itself).
4. The request goes out in the account's own loop, between the reader's turns, as the page's "ask how
   large it is" does today (`onReader`). **The owner's click goes before the reader's next page and
   before the automatic mirror's turn**; one request at a time on the connection, as now.
5. The answer is written to the row (done with the new message's number; waited; refused with
   Telegram's own word; not known), then told to the page. The sent message itself reaches the
   catalogue as every message does, through the live monitor.

## 4. The rules it follows (the thirteen of `TRIED-BEFORE.md` sections 24 and 25, as they apply)

- **One click, one request, never repeated by itself.** Not after a wait, not after a timeout, not at a
  restart.
- **A wait Telegram states** (also a chat's slow mode) is recorded before anything else. The request was
  not carried out. The page keeps the text and shows when sending is possible again; **the owner sends
  again; the program does not.** Until then every click of that kind is answered "wait until ..." with
  no request. No setting shortens a wait.
- **A refusal of the account** (`PEER_FLOOD`, `USER_RESTRICTED`): every write of the account stops, the
  mirror's too; recorded first; no retry; only the owner clears it, after reading what it means. One
  shared record (today's `tg_forward_refusal`), so neither side can forget what the other was told.
- **A refusal of the chat** (no right to write, banned, a closed topic, a protected source): shown with
  Telegram's own word; remembered for that chat and kind for a day so that the same refused request is
  not sent again and again; "try again" is the owner's click.
- **Frozen account: off.** A frozen account is read-only at Telegram. The compose box and the buttons
  are replaced by one line; no request is made to find out again. A method refused as frozen is
  remembered as the reader does it.
- **A cap, the app's own caution (no number of Telegram's exists for sends):** at most 1 write a second
  and 30 in any 5 minutes per account, a forward counted by its messages against the mirror's hourly
  bound. Over it: refused in fixed words, no request. It also bounds what a fault in a page could do.
  The owner's clicks count as "the account's last write" for the automatic mirror, which then waits its
  usual pause: the mirror gives way to the person.
- **One row per click, one writer:** the ledger is rows, never a list kept in one value; two clicks at
  once are two rows. A stored value that cannot be read stops the writes (fail closed), never reads as
  "empty".
- **Counted from the first day:** per kind and hour: requests, waits (count, shortest, median, longest),
  refusals by Telegram's word, unknown outcomes, clicks refused by the door and why.
- **Nothing of a message in any log:** the log, the status file and the counts hold the kind, the
  catalogue's own small numbers, milliseconds and Telegram's error word. Never a text, a name, a link or
  a Telegram id. The text lives in the catalogue only (where every message's text already is), and in
  the ledger only until the click's outcome is known.

## 5. An outcome that is not known

A send, a reply or a forward with no answer may have happened. The row says "not known" and the page
shows it on that message's place in the conversation, with what the chat itself shows:

- The live monitor usually brings the account's own new message within seconds. A message of the
  account's own in that chat, after the request, with the same text and the same reply target (for a
  forward: naming the same source post), is shown beside the row: "it is in the chat". The owner
  confirms, or the app marks it arrived when the match is exact and no other click waits with the same
  content. Marking as arrived sends nothing.
- Nothing seen: the owner chooses "send again" (a new request, under the same random id, so that
  Telegram can refuse it as a repeat where it still remembers the first; measured once: ids of messages
  it had not carried out were free six hours later) or "leave it". "Look in the chat" (one read request,
  counted, its cost said) is offered when the monitor is not running.
- An edit, a delete, a reaction or a read mark with no answer: repeating it changes nothing, but the
  program still does not repeat it; the chat's next update shows which it was, and the button is there.

## 6. What is not in this step

Sending files (it uploads bytes; no part of the app does that yet); joining and leaving chats, muting;
formatting, mentions, stickers, polls, scheduled and silent messages; deleting other people's messages
or a chat's history; pinning; anything paid; calls and secret chats (not planned). The home-network
devices.

## 7. How it is built, after the owner's word

Four pieces, each from a brief with its "what the old app already knows" note (section 1 is that note):
1. **Core, the request layer:** the six kinds beside the forwarder in `internal/telegram`, on the same
   `once`, memo and refusal record; a variant that reports a stated wait at once instead of sleeping in
   the call; the fake Telegram's answers. An independent review before anything else (it acts for the
   owner on Telegram).
2. **Core, the ledger and the turn:** a schema step (the next free number when it is listed), the
   catalogue's doors, the click's turn in the account loop, the state at a restart. The race detector on
   the collector (it gains a queue).
3. **Core with pages, the door:** the routes on the collector's listener and their checks; the viewer's
   pass-through with the shared secret.
4. **Viewer:** the compose box, the buttons, the "not known" row, the wait's countdown, the frozen line.

**The first real use is the owner's, on the test account, in Saved Messages** (the account's chat with
itself: nobody else sees it): one text sent, edited, reacted to, deleted; one message forwarded there.
Five requests, each counted; then a text in one real chat of the owner's choosing.

## 8. For the owner: six choices, each with my recommendation

1. **The step as written** (text, reply, edit, delete, forward, react, read mark; files and joining
   later). Recommended: yes.
2. **After a wait Telegram states, the owner sends again; the program does not send by itself when the
   wait is over.** Recommended: yes (it is "one click, one request"). The other way is possible: the
   click stands and goes out once the wait is over.
3. **Mark as read: a switch, off.** Recommended: off, as on the board.
4. **Delete: a second click on the page first; the archive keeps the message, marked deleted.**
   Recommended: yes.
5. **The app's own mirror chats cannot be written to from the client.** Recommended: yes.
6. **The cap: 1 write a second, 30 in 5 minutes, as a start; a setting.** Recommended: yes; raised or
   dropped once real use shows it is in the way.
