# Plan: the first real adoption (M6, `mirror -adopt N -into M`), on the test account (mirror track, M-7, 11-22)

Nothing here runs before the owner starts it. M6 is in the installed build since the batch of 11-22 (head e34f4f64).

**What it is:** an existing chat of the owner's (a channel or supergroup the account already has, filled by hand)
becomes the mirror of a source chat. What is already in it is never forwarded again; what cannot be told waits for
the owner's word (`-take arrived|not-arrived`). Never done by anything automatic. Forums are refused (as source
or chat), as are protected sources and chats the app made itself.

**Which two chats:** the owner's choice: one source chat N and the chat M that already holds the owner's hand-made
copies of it. Best first: a small pair (a few hundred messages), M filled by hand from N only.

**How it runs (the owner, the app stopped, VPN on):** the collector's `mirror -adopt N -into M` (N and M: the
catalogue's chat numbers, shown by `mirror -list` and on the Chats page). It asks three questions, each "yes" or
the end:
1. Both chats' sizes, and whether each has been read: a read of N and M by this command if not (cost said first).
2. Only if M was read before this command: one `channels.getMessages` per 100 copies told "there", to confirm they
   still exist (counted under the refresh's kind).
3. The counts: "A are in the chat, B are not, C cannot be told; B will be forwarded in about K batches; M holds U
   messages that are not N's", then the record (catalogue only, no request).
After the yes, the usual `mirror` run (or the automatic task with `-keep-current`) forwards B.

**Cost, for a pair of a few hundred messages:** the reads: a few `messages.getHistory` pages of 100 each; the id
lists: up to a few `channels.getMessages`; the forwards: B / 100 batches, 20 s apart. Every wait slept in full.

**Read afterwards (counts only, catalogue read-only, into TELEGRAM-FACTS 11 the same hour):** A, B, C, U; requests
per kind with answer times; waits and refusals; whether the first forward into M was accepted (posting rights are
not on record: the first forward is the test; a refusal holds the chat and retries by itself since M14).

**For the owner's list (one line):** "First adoption: pick a source N and the chat M that already holds your copies
of it, then run `mirror -adopt N -into M` with the app stopped; the mirror track gives the exact command when you
name the pair."
