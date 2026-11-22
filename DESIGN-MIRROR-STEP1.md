# Mirror groups, the first real step: design note for the owner (2026-11-14)

One page. Test account only. What is known and not known is in `SESSION-MIRROR-PROGRESS.md` section 1.

## What the step does
One command, started by you in your own window, with the collector stopped:

    tgarchive-collector mirror -db <catalogue> -chat <chat number> -vpn-adapter WindscribeOpenVPN

1. **It shows the plan and sends nothing.** For the chat you named (its number from the `chats` command): how many
   of its messages are on record, how many go in this batch (at most 100, an album never split), how many
   channels and supergroups the account is in against the 500 (from the stored chat list, with its age), any
   wait of Telegram's still running, and the requests it will send: 1 `help.getConfig`, 1
   `channels.createChannel`, 1 `messages.forwardMessages`.
2. **It asks for "yes" at the console.** Anything else: nothing is sent.
3. On yes, after the VPN check: it reads the server's maximum per forward; creates **one private channel**, no
   invite link, no username, named "X-<the source's name>-1"; forwards **one batch** of the chat's oldest
   messages on record into it; then stops and prints the numbers.

Run again on the same chat, it creates nothing new: it shows the plan for the next batch into the same mirror.

## The rules it keeps
- **One request at a time**, three requests in all. Nothing that writes is ever sent twice by itself.
- **Every request is counted per method**: sent, answered, waits and their seconds, timeouts, refusals by code,
  and the time each took.
- **A wait Telegram states is written to the catalogue before it is slept, slept in full plus 1 s,** and checked
  before every later request, also after a stop or a restart. A wait over 10 minutes ends the command and says
  when to run it again; running it earlier sends nothing. After a wait that was slept, the batch is sent once
  more; a second wait ends the command.
- **What is about to be sent is written down first** (the mirror being created, the batch being sent), and every
  forwarded message is recorded with its new number: one row per message. If no answer comes, the outcome is
  recorded as unknown and the command never repeats it by itself: it tells you, and nothing more is sent for
  that chat until it is looked at.
- **If the record cannot be read, nothing is sent.**
- `USER_RESTRICTED` or `PEER_FLOOD`: the account's mirroring stops for good, on record. `CHANNELS_TOO_MUCH`:
  said, nothing created. A protected source (`CHAT_FORWARDS_RESTRICTED`): remembered, never asked again.
- Messages known to be deleted, and messages with self-destructing media, are left out of a batch.
- **The mirror is marked as the app's own in the catalogue** (its source on record) and **switched off for
  downloads**, so its copies never queue a file by themselves. A forward keeps Telegram's file id, so no byte is
  downloaded or uploaded.
- Output is numbers and fixed words: no chat name, no title, no id of Telegram's.
- Nothing is automatic in this step. It acts on one chat you name, when you say yes.

## What you get back
Requests per method, waits and their seconds, the time of each request, messages forwarded and messages Telegram
left out, and the count against 500. That is the first number anyone has for "time per batch": the old app never
forwarded (it uploads each file again), so there is nothing to compare with except your own experience by hand.

## What it does not do yet
Forum topics in a mirror; a chat's whole history with a pause between batches; mirrors for newly joined chats by
themselves (your decision of 11-14: mirrored automatically, files only when you choose the chat); a "never
mirror" switch per chat (needed before anything is automatic, not for a command you start per chat).

## Choices I made that are yours to change
1. **A private channel, not a private group.** It is what you described ("only the owner has access") and it
   needs no second member. A forum mirror later has to be a supergroup; both count against the 500.
2. **The oldest messages first**, as you forwarded history by hand. For a first test the newest 100 would do as
   well.
3. ~~Only messages already read into the catalogue are forwarded.~~ **Corrected by the owner, 11-15: wrong for
   the goal.** A mirror must work on a chat the app has never read: you join a group on the phone while away,
   and the app goes back to the group's beginning (before you joined) and forwards its media into a mirror.
   So the mirror reads the chat itself first (messages only, about one request per 100 messages, no download;
   your decision of 11-13 that a signed-in account reads what it can see), then forwards, oldest first. See
   "Corrected, 11-15" below.
4. **A protected chat is found out only by the forward being refused, after its mirror exists** (one of the 500
   spent). The app does not record a chat's "protected" flag today. For this step: name a chat that is not
   protected. Before anything mirrors by itself, the flag is recorded and checked first.

## Before the real step
Built and tested against the fake Telegram; one independent read-only review (it writes to Telegram); then you
start it, present, behind the VPN, on the test account. Nothing is run against Telegram before that.

## Corrected, 11-15 (the owner): the mirror reads the chat itself, and starts by itself
What you said: the point is that a group joined while you are away is mirrored without you, from its
beginning. What that changes, in the order it is being built:
1. **The command reads first** (being built now). `mirror -chat N` on a chat never read: the plan shows the
   read's cost (Telegram's message count, about one request per 100) with the forward's; one yes covers both.
   It reads the history (messages only), then forwards batch after batch. A chat read this way is **not
   switched on for downloads**: its files are downloaded only when you choose the chat (your decision of
   11-14 22:38).
2. **Media only, by default** (your words: "forward the media"): messages that carry a photo, a video or a
   file go to the mirror, albums whole; plain text and service messages do not. A flag forwards everything.
   **Say if you want every message.**
3. **By itself, in the running collector** (next; it needs a place in the collector's live run, asked of the
   integrator): a chat that appears in the account's chat list and was not there before is read and mirrored
   without a command, the oldest first, then kept current as new media arrives; with a "never mirror" mark per
   chat, a cap per hour, every wait slept in full, and the mirror shown as the app's own.
What it cannot do: where a group hides its earlier history from new members, Telegram gives the account
nothing from before the join, so the mirror starts at the join. A protected group cannot be forwarded at all.

