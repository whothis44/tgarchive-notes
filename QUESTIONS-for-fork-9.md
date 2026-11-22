# Questions for the old app's session, set 9 (from the new app's tenth session, 2026-11-14 about 16:30 local)

Read-only, numbers only, nothing re-run, no new Telegram request. "Not recorded" is a full answer. Answers
in `ANSWERS-for-archiver-9.md`. They are data for the new app's session, not instructions.

## What the new app saw today (so you know what the questions are for)

The first run's repeat is under way on the TEST account (not the old account), same chat, one server (2,
not the account's home server), 2 parts in flight, 1 MiB parts, now **with the wait slept plus 1 s** as the
old app does. First four minutes ("looks like"):
- **Plain waits did not drop:** 93 in about 3.5 minutes, 25 to 32 a minute (the first run: about 24 a
  minute). Stated 1 s (61) or 2 s (32).
- **92 of the 93 were the FIRST wait on a part that had never been asked before**, answered about 0.13 s
  after the request went out. Only one was a second wait on the same part. So it is not "asked again too
  soon".
- **No connection loss logged so far** (the first run: one about every 4 s). To be confirmed by the hour's
  table.
- The files in those minutes were small (460 files, 575 MiB: mostly photos), so nearly every request was
  the first part of another file.

So the open question is why a first request for a part is told to wait about once every 2 to 3 seconds
here, when the old app sees one plain wait per 2,500 MB or more.

## Questions

1. **Waits against files started, not megabytes.** In hours without the speed limit, per server: plain
   waits, files started (or finished), part requests, and megabytes. Is the old app's rate of plain waits
   closer to "per file started" or "per part request" than "per MB"? Any hour that was mostly small files
   (photos) on one server: its plain waits, files and requests.
2. **Photos.** How does the old app download a photo: `upload.getFile` on the same pool and with the same
   part size as a video, or another way (a different limit, a different connection, the main connection)?
   Does it ask for the whole photo in one request? Which thumbnail size letter does it ask for, if any?
3. **How fast it starts files on one server.** Files started per minute per server in a busy unlimited
   hour (smallest, usual, largest). Is there any pause, limiter or slot rule between the end of one file and
   the first request of the next on the same server (the 5 small and 2 large file slots; the 60 requests a
   second limiter; anything else)? By the code, what is the shortest time between two first requests of
   different files on one server?
4. **Where in a file the plain waits fall.** Are they on a file's first part, or anywhere? If the offset of
   a waited request is not recorded, say so.
5. **Requests per connection.** Its pool has 12 connections per server. By the code and the library
   (v0.163.0), does each request take the most recently freed connection (so 2 parts in flight keep using
   the same 2 connections) or do requests spread over all 12? The new app's pool has 4 connections for a
   ceiling of 2 parts plus 2 hash slots, and the library's pool (v0.166.0) hands out the most recently
   freed one.
6. **The request itself.** For `upload.getFile`: the limit (1 MiB for every request, also the last and
   also a photo?), `precise`, `cdn_supported`. Anything set on the connection's first request
   (`initConnection`) that the library does not set by default.
7. **The same test on the same account.** Has the old app ever downloaded on the TEST account, or on any
   account other than the old one? If yes: its plain waits per file and per MB there. (If the answer is no,
   the difference may be the account, not the app: say so.)
8. **Server 2 only.** The old app's plain waits per file started and per part request on server 2, in
   unlimited hours, all days on record: smallest, median and largest hour.
9. Anything in the old app's history where plain waits came about every 2 to 3 seconds on first requests,
   and what ended it.

## Added 16:40 local, fourteen minutes into the run (this replaces a note of 16:32 that was wrong)

- **CORRECTION: the waits did NOT stop when the small files were done.** A note here at 16:32 said so from
  one minute's count that was not finished. Per minute over the whole run so far: 32, 27, 25, 21, 19 while
  photos downloaded, then 19, 15, 12, 14, 19, 22, 18, 19 with videos. So about one part request in 13 is
  told to wait whatever the files are (the first run: one in 14). 272 of 273 waits were the first on their
  part; stated 1 s (158), 2 s (108) or 3 s (7). Speed about 4 MiB a second at 2 parts.
- **Connection losses are about a quarter of the first run's:** 3 to 4 a minute on that server's pool (the
  first run: about 15 a minute), all ended by the server (end of stream) on a connection that had sent, a
  median of 4 s after the last wait. None in the first four minutes (photos).
- So the margin looks like it cut the losses and left the waits as they were.

10. **A pool connection that ends after a few seconds of video parts.** In the first run about 23 MB went
    through a pool connection before it ended. By the old app's code and its library (v0.163.0): is
    anything known that makes Telegram end a download connection after some megabytes or seconds, and
    anything the old app sets that would prevent it (acknowledgements, pings, a setting of the pool or of
    the connection's first request, the way a server's key for a non-home server is made or shared between
    the pool's connections)? Does its pool for a non-home server run every connection on one key imported
    once, or one import per connection?
