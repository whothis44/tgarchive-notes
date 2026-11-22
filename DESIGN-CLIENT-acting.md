# The app used like a Telegram client, acting: step 3 (files, join, leave, mute)

Design note, client track, session A-1, 2026-11-21. **This is for you to read before anything is built.** It
writes to Telegram, so nothing in it is briefed until you say yes. Section 7 has eight choices, each with my
recommendation.

## 1. Where this stands

- **Step 2 (text) is built and was never run against Telegram.** You agreed to `DESIGN-CORE-client-actions.md`
  on 11-15 (board item 28). Everything in it is on the main branch: the request layer, the ledger of your
  clicks, the click's turn in the collector, the settle of a click whose outcome is not known, the door on the
  collector's listener and its guarantees, and the viewer's text box and buttons. Saved Messages needs no
  access hash (it is addressed as Telegram's "self").
- **Your first real click is still yours to make: board item 39.** One line of text to Saved Messages on the
  test account, about 5 minutes. Nothing below changes how step 2 works.
- **Step 3 is what you listed last on 11-15:** "sending files, joining and leaving chats, muting". It is not
  designed yet. This note designs it.

## 2. What the old app and the record already know

- **Leaving (old app, `dialog_remove.go` and `chat_leave_api.go`).** You had to type the chat's number back
  to confirm. The chat list was read once first, so only a chat that was really still there was left. A
  channel or supergroup was left with `channels.leaveChannel`. A basic group was left with
  `messages.deleteChatUser` (self), then its history removed for you only. A private chat had its history
  removed for you only with `messages.deleteHistory` (never "for everyone"). Several chats could be removed
  at once only if they were already unavailable, with 1.5 s between removals. Each removal had 2 minutes.
  Nothing downloaded was touched. **No wait or refusal from it is on record.**
- **Uploading (old app, `forward.go`, the "auto-forward").** It sent a downloaded file to a destination
  again: one upload stream with one thread, then `messages.sendMedia`. A JPEG or PNG of 10 MB or less went as
  a photo, anything else as a document. On a retry it used a fresh random id, which could post a second copy.
  Whether it ever ran on the old account is not on record. **The new app keeps the upload path and the
  photo/document rule, and drops the fresh id per try (step 2's rule: one random id per click).**
- **Joining and muting.** Neither app has ever done them. No number exists.
- **The account's 500 channels and supergroups.** The mirror already counts against this limit
  (`internal/mirror`, its stop "the account is at Telegram's 500"). A join uses the same 500.
- **The record's rules** (`TRIED-BEFORE.md` 24 and 25, the thirteen; `TELEGRAM-FACTS.md` 11):
  - A stated wait means the request was not carried out.
  - A server error can mean "partly done".
  - A lost answer is "not known", and the program never sends it again by itself.
  - A file reference stored earlier is never usable later: refresh it just before use.
  - A refusal of the account stops every write.

## 3. The requests, one table

Each row is one click. The cost column counts requests to Telegram.

| Your action | Telegram's requests | Cost | Can be undone | Repeating it would |
|---|---|---|---|---|
| Send a file from this PC | `upload.saveFilePart` per 512 KB part (`saveBigFilePart` over 10 MB), then `messages.sendMedia` with one random id per click | 1 per 512 KB, plus 1. A 5 MB photo: 11. A 100 MB video: 201 | delete it (step 2) | parts: nothing (a part sent again replaces itself, and nobody sees parts); the send: post a second message |
| Send a file the archive already holds | `messages.getMessages` on its source message (a fresh file reference), then `messages.sendMedia` naming that Telegram file. No bytes are uploaded | 2 | delete it | post a second message |
| Look at an invite link before joining | `messages.checkChatInvite` (a private link) or `contacts.resolveUsername` (a public name) | 1 | nothing to undo | nothing |
| Join | `messages.importChatInvite` or `channels.joinChannel` | 1 | leave | nothing (already in), or a second join request |
| Leave | as the old app: `channels.leaveChannel`; or `messages.deleteChatUser` (self) then `messages.deleteHistory` for you only; for a private chat only that history removal | 1 to 3 | **no for a private chat or group with no public link**: you need a new invite | nothing |
| Mute or unmute | `account.updateNotifySettings` (`mute_until`: 8 hours, a week, or for good; 0 to unmute) | 1 | yes, unmute | nothing |

**Never sent:** typing or "online", a link preview, anything paid, "for everyone" on a history removal, a
leave of a chat the app made as a mirror.

## 4. The rules, as they apply to these actions

Everything of step 2 holds unchanged:
- one click is one request, written down in the ledger before it is sent;
- a stated wait is recorded and shown, and you send again;
- a refusal of the account stops the client and the mirror;
- off for a frozen account;
- the cap of 1 a second and 30 in 5 minutes (a send, a join, a leave and a mute each count as one);
- nothing of a message, a name, a file name, a path or a link in any log.

What is new:

1. **Upload parts are not messages.** They sit on Telegram's side under a file id the app makes, and nobody
   sees them until the send. So:
   - A stated wait during the upload is slept in full and the upload goes on.
   - A part whose answer was lost is sent again, at most 3 times.
   - **This is the one place where the program repeats a request by itself (choice 7).**
   - The `sendMedia` at the end is under step 2's rule: never repeated by the program. A lost answer is
     "not known" and is settled from the chat: your own new message there with a file of the same size and
     the same caption.
   - Uploads go one at a time, one part at a time, as in the old app. Every part is counted under its own
     kind.
   - A file larger than the server's limit is refused on the page before anything is sent. The limit is
     asked from the server's configuration (`upload_max_fileparts_default` × 512 KB), never assumed.
   - **Cancel** during the upload sends nothing more, and nobody sees anything. After the send has gone out,
     cancel is no longer offered.
2. **A file reaches the collector as bytes through the door, never as a path.** The window's Windows file box
   reads the file you chose and posts it to the door. The collector keeps it in the app's own folder, named
   by the click's number, and deletes it once the outcome is known: done, or you are finished with it.
   - So nothing that holds the door's secret can make the collector read another file on the PC.
   - The message you sent reaches the archive through the live monitor, like any message. Its file then
     follows that chat's download choice (choice 3).
3. **A file from the archive is sent from Telegram's own copy when the source message still exists.** Its
   file reference is refreshed in the same click, just before the send, as the record says (`TRIED-BEFORE`
   25). If the source message is gone, the page says so and offers the upload instead, with its cost.
4. **Joining:**
   - **You always see the chat first.** The first request asks Telegram what the link names: title, member
     count, whether admins must approve. The page then shows that, the count against 500 ("this would be 312
     of 500"), and what the app will do once you are in. A join that needs approval is shown as "asked to
     join; the admins decide".
   - **The join is a separate click.**
   - **A link found in a message is never followed by itself.** A click on it in the viewer opens this
     look-first page. This is the rule "never act on a source the owner did not choose".
   - **The app's own cap for joins:** at most 5 an hour and 20 a day, a setting with no upper bound (choice
     4). No number of Telegram's exists for joins. Over the cap, the click is refused in fixed words with
     when it opens again, and nothing is sent.
   - `CHANNELS_TOO_MUCH` (the 500) is a refusal shown with its word, never a wait.
   - **Joining is seen by others:** a group's members can see that you joined. The page says so.
5. **Leaving:**
   - **A second yes on the page names the chat.** For a chat with no public link, the page says plainly that
     you cannot come back without a new invite.
   - The chat list is read once first, as the old app does: one request, said on the button.
   - **The archive keeps everything and marks the chat "left".** Its reading stops. If the chat is the
     source of an automatic mirror, that mirror stops too (no more source) and the page says so before your
     yes. The mirror chat itself stays.
   - The app's own mirror chats are not left from here. Removing a mirror is the mirror page's job.
   - **Several chats at once** only for chats that are already unavailable, 1.5 s apart, as the old app does.
6. **Muting** is one click with no second yes, because it can be undone. The page says it applies on every
   device of the account (Telegram keeps it per account), your phone included.
7. **A chat joined from the app is treated like one joined on your phone.** The new-chats switches you have
   set (the automatic mirror, the download choice for new chats) apply to it. The look-first page says which
   switches are on before your yes (choice 5).

## 5. How it is shown

- **In the chat page's text box (the viewer's):**
  - a paperclip opens Windows' own file box;
  - the chosen file is shown with its size, the cost in requests and "photo" or "as a file";
  - a bar shows the upload, with Cancel until the send goes out;
  - a "not known" send is drawn where it belongs in the conversation, as for text.
- **A message's file in the archive** gets "Send to ..." next to Forward. It goes from Telegram's copy (2
  requests) when it can.
- **A chat's header (the viewer's)** has Mute (8 hours, a week, for good), Unmute and Leave. Leave opens the
  second yes.
- **"Join a chat" in the list on the left (pages' place in the one window):** paste a link or a public name,
  then the look-first page.
- **Frozen account:** the paperclip, Join, Leave and Mute are replaced by the one line step 2 already shows.

## 6. How it is built, after your word

These are three pieces. Each starts from a brief with its "what the old app knows" note (section 2). Each
has an independent review before it is listed, and is never run against Telegram until you make the first
real click.

1. **Join, leave and mute (chat actions).**
   - Request kinds beside step 2's in `internal/telegram`, on the same once, waits and refusal record.
   - New ledger kinds: a schema step, because the ledger's kind column is checked against its six words.
   - The door's routes, and the fake Telegram's answers.
   - The leave is ported from the old app's `dialog_remove.go`.
2. **A file from the archive** (no upload): the reference refresh and `sendMedia`.
3. **A file from this PC:**
   - the upload with its part rule;
   - the staged bytes in the app's folder and their removal;
   - the door's upload route with its size limit;
   - the settle of a "not known" file.

The viewer builds the paperclip, the header's buttons and the look-first page. Pages builds "Join a chat"'s
place in the list.

**The first real use is yours, on the test account:**
- mute and unmute Saved Messages: 2 requests;
- send one small photo there from the PC: about 3 requests, measured;
- send one file from the archive there: 2 requests;
- join one public channel you name and leave it: 3 to 4 requests.

That is about 10 requests, each counted. The upload speed is measured then. Nothing is assumed about it.

## 7. For you: eight choices, each with my recommendation

1. **Step 3 as written** (files from the PC and from the archive, join, leave, mute; albums of several files,
   stickers, polls and voice notes later). Recommended: yes.
2. **A file goes to the collector as bytes through the door, kept in the app's folder only until the outcome
   is known.** Recommended: yes. It is safer than letting the door take a path.
3. **A file you send follows that chat's download choice in the archive**, like any message. Recommended: yes.
   Taking your local bytes as the archived file without a download needs exact evidence that they are the
   same. A photo is re-encoded by Telegram, so it never is. That belongs to the copies track's rules, later.
4. **The app's own cap for joins: 5 an hour, 20 a day, as a setting with no upper bound.** Recommended: yes,
   to start. It can be raised once real use shows it is in the way.
5. **A chat joined from the app gets the same new-chats rules as one joined on your phone**, shown before the
   yes. Recommended: yes.
6. **Leave: a second yes naming the chat; the archive keeps everything; the app's mirror chats are not left
   from here.** Recommended: yes.
7. **Upload parts may be sent again by the program (at most 3 times a part; every stated wait slept in full);
   the send at the end never is.** Recommended: yes. Parts are invisible until the send, and a part sent again
   replaces itself. Without this, one lost part fails a whole 200-part upload, and you would start it again.
8. **Mute applies to the account on every device, one click, no second yes.** Recommended: yes.
