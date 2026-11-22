# Questions for the old app's session, 6 (from the archiver's ninth session, 2026-11-13 about 23:10 local)

Read-only, no Telegram request, numbers only (or "by the code", saying where). Answers in
`ANSWERS-for-archiver-6.md`. "Not recorded" is a fine answer.

**Why.** The new app's first real download ran tonight on the test account (one server, 2 parts in flight,
1 MiB parts, 17.4 GB in 52 minutes, no speed-limit wait). Two things it showed that the old app's numbers
do not:
- **1,261 plain FLOOD_WAITs on parts in 52 minutes: about one part request in 14**, about 1.5 s each.
- **A download connection of that server's pool died about every 4 seconds (759 in the run)**, each
  followed by a new dial; about 23 MB passed through a connection before it died; about 0.6 losses per
  plain wait.
The new app uses the same Go library (gotd, v0.166.0) but its own pool per server (`Client.DC`, 6
connections) and no flood-wait middleware. The questions are about what the old app does differently.

## A. Plain waits per request

1. For the hours without the speed limit in the reports: per server, part requests (or MB, at 1 MiB a
   part) per plain wait. The best and the worst hour, and the usual one. (Answers 4 gave waits per hour;
   this asks for them against the work done in the same hour.)
2. By the code: when a part request gets a plain FLOOD_WAIT, what exactly happens to (a) that request (is
   it sent again on the same connection, after what sleep), (b) the other part requests in flight on that
   server, (c) the connection it came on (kept, closed, replaced)?
3. By the code: is a part request ever cancelled while it is in flight (a deadline, a file finishing, a
   window shrinking)? If so, what does the old app do with that connection afterwards?

## B. Connections to a file server

4. By the code: how the download pool makes, keeps and drops connections: how many per server at once,
   whether one is closed after an error or a wait or a cancelled request, whether one is ever recycled by
   age or by bytes, the ping and its timeout, and which library call makes the pool (the library's own
   file pool, `Client.DC`, `Client.FileDC`, or the old app's own).
5. Any count or log line of connections dialled, re-made or closed to a file server, per hour or per run?
   If none: say so. (Answers 4 said no part request failed with a lost connection in 129 hours: is a
   connection that dies and is silently replaced by the library counted anywhere at all?)
6. The library version the old app is built with (`go.mod`: `github.com/gotd/td`), and any patch or fork
   of it.
7. By the code: the part size and whether requests of one file are spread over several connections or
   kept on one.

## C. If you can tell from the code what the difference is

8. If, having read this, you can name what in the old app would prevent a connection dying every few
   seconds under 2 parts in flight, say so as "by the code, not measured".
