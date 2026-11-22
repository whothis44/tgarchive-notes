# Answers to QUESTIONS-for-fork-6 (fork session, 2026-11-14 ~00:30 local)

Sources:
- the hourly reports, read-only, by `ix-tools/report_q6.py`, numbers only;
- the 12.30 source (`wt-v12.30`, tag `v3.4.18-ix.12.30`);
- the gotd source the old app builds with (`github.com/gotd/td@v0.163.0` in the local module cache).

No Telegram request, no database change. "By the code" names the file.

**The short version:**
- The old app gets about **180 to 750 times fewer plain waits per MB** than your run, leaving out DC5, which has
  almost none. At about the same parts in flight:
  - DC4, 1.8 parts in flight on average: 3,079 MB per wait;
  - DC1, 2.8 parts in flight: 10,540 MB per wait;
  - your run: about 14 MB per wait.
- Upper bound from the reports: in 23 unlimited hours (474 GB), at most 12 DC4 part requests failed in a way a
  connection dying after Telegram acknowledged them would show up as. Your run had 759 deaths in 52 minutes. That
  bound does not cover deaths before the acknowledgement: the library retries those silently and nothing counts them.
- By the code, the biggest differences:
  - (1) every plain wait is slept in full, plus 1 s, by the request that got it, before it asks again;
  - (2) there is one request-rate limit for the whole account;
  - (3) the home server's pool comes from `Client.Pool`, not `Client.DC`;
  - (4) pools live as long as the app.

  Details in section C.

## A. Plain waits per request

### 1. Work per plain wait, in hours without the speed limit
**Source:** the hourly reports.
- **Which hours:** complete hours, 11-08 14:00 to 11-13 22:00 local, in which that server had **0 speed-limit
  waits** and moved at least 1,000 MB.
- **Parts:** MB of the server's saved bytes that hour. At 1 MiB a part, MB is about part requests answered.
- **Plain waits:** the server's "N plain waits asked" on parts.
- **Request counts per hour are not in the report**, so this is "MB per wait", not "requests per wait".

| Server | Hours | MB in those hours | Plain waits | MB per wait overall | Hours with no plain wait | MB per wait, hours with any: worst / median / best | Parts in flight, hourly mean: lowest / median / highest | MB an hour, median |
|---|---|---|---|---|---|---|---|---|
| DC1 | 22 | 758,868 | 72 | **10,540** | 9 | 2,507 / 7,070 / 20,231 | 1.7 / 2.8 / 3.6 | 38,534 |
| DC2 | 20 | 144,065 | 58 | **2,484** | 10 | 270 / 1,712 / 9,322 | 0.6 / 1.4 / 2.5 | 6,758 |
| DC4 | 23 | 474,176 | 154 | **3,079** | 11 | 222 / 7,328 / 23,968 | 0.8 / 1.8 / 2.1 | 22,355 |
| DC5 | 22 | 182,641 | 3 | **60,880** | 19 | 2,158 / 3,982 / 5,718 | 1.5 / 2.7 / 4.1 | 7,702 |

- **The worst hours** (MB, waits):
  - DC4 11-13 04:00: 25,701 MB, 116 waits (222 MB per wait);
  - DC2 11-08 19:00: 6,758 MB, 25 waits (270);
  - DC1 11-12 00:00: 30,082 MB, 12 waits (2,507).
- **Your run:** 17.4 GB and 1,261 waits is about **14 MB per wait**. That is 16 times worse than the old app's worst
  hour on any server, and about 220 times worse than DC4 overall. The old app's DC4 ran at a similar 1.8 to 2.1
  parts in flight.
- The servers differ (your test account's server is not named here), so this compares like with like only roughly.

### 2. By the code: a plain FLOOD_WAIT on a part
(`floodguard.go` `invokeGate`; `attachment.go` `sharedInvoker.Invoke` and `invokePart`; `pacer.go`.)

**(a) The request that got the wait:**
- **Under 60 s, and the server not escalated:** that request alone sleeps the wait **plus 1 s** (`floodGateMargin`),
  outside the file's time budget. Then it asks again.
  - It asks through the same server pool's `Invoke`, so the library takes a free connection. The pool reuses the
    last one freed, which is usually the connection that carried the wait. That is not guaranteed.
  - Before asking again it passes the server's gate and the account's request-rate limiter again.
- **More than 3 plain waits on one request** (`floodInlineRetries` = 3): the attempt ends with an error ("Telegram
  kept refusing this file"). The file is tried again later. The old app never re-asks before a stated wait is over.
- **Escalation, per server:** a wait of 60 s or more, or 3 waits of 10 s or more within a minute on that server. The
  server's own gate closes for the wait plus 1 s, and every part on that server waits at it.
  - Two servers escalating within a minute close all servers' file gate.
  - Twice in an hour, it falls back to 12.17's waits for a time.
  - Since 11-08 the report says "escalations: none".

**(b) The other part requests in flight on that server:** untouched. Nothing in flight is cancelled.
- The pacer reacts on its next 10-second tick:
  - it cuts the server's window to 60% (`paceCut`), but never below 2 parts for a short wait;
  - it holds the window for a minute (`paceFloodHold`) and sets a ceiling for a while.
- At 2 parts or fewer, with no more than 2 in flight when the wait came, a short wait only holds: no cut, no ceiling
  (12.30).
- The file's thread tuner halves that file's threads after a wait (`threadTuner`, default 4 threads a file). New
  parts then start only within the window.

**(c) The connection:** kept.
- A FLOOD_WAIT is an ordinary answer, so the library puts the connection back on the pool's free list (gotd
  `pool.DC.Invoke` calls `release`).
- The old app never closes, replaces or marks a connection after a wait.

### 3. By the code: part requests cancelled while in flight
**Yes, three ways:**
- **Deadline:** each part request has a **2-minute** deadline (`filePartTimeout`, `invokeGate`).
- **File ends:** the file's own context ends. That happens when a download is cancelled, yields to a ranked file, is
  set aside, the app stops, or a -503 run gives up (the report's "run ends: cancelled").
- **Window shrinking never cancels anything:** it only stops new parts from starting.

**What happens to the connection afterwards:** the old app does nothing to it.
- In the library, a request cancelled after it was sent gets an `rpc_drop_answer` (gotd `rpc/engine.go`). The
  connection goes back to the free list (`pool.DC.Invoke` releases it on any error).
- One exception, also the library's: if the connection had already died, the pool marks it dead and takes another.

## B. Connections to a file server

### 4. By the code: how the pool makes, keeps and drops connections
(`attachment.go` `guardedClient.Pool`/`DC` and `sharedPool`; `ix_archive.go` `fileDC`; `route.go`;
`route_home.go`.)

- **One shared pool per server for the life of the app.** It is made on first use and kept in `c.pools`:
  - **home server: `Client.Pool(12)`**, the main client's own pool, sharing the main session;
  - **other servers: `Client.DC(ctx, dc, 12)`**, with gotd's auth export and import when the pool is made.
- **Media addresses**, used for DC2 and DC4 parts about half the time:
  - other servers: `Client.MediaOnly(ctx, dc, 4)`;
  - home server: a second gotd client (`route_home.go`, its own memory copy of the session, no updates), with
    `Pool(4)`, resolving media addresses first.
- **Limits:** up to **12 connections per server pool** (`downloadPoolConnections`), and 4 per media pool.
  - The pool hands one request to one connection at a time.
  - Connections are dialled only when no free one exists (gotd `acquire`).
  - Free ones are reused last-in, first-out, so with 2 parts in flight about 2 or 3 stay busy and the rest go idle.
- **Closed only by the library:** when a connection's run loop ends (a read or write error, a missed pong) or a
  request finds it dead.
  - The pool then deletes it and dials a new one on the next need.
  - Nothing closes a connection after an error, a wait or a cancel. Nothing recycles one by age or bytes.
  - The app closes a pool only at shutdown, or when the media-route setting is turned off.
- **Ping:** gotd's defaults, which the old app does not change. `ping_delay_disconnect` every 60 s, pong timeout
  15 s, disconnect delay 75 s (`mtproto/options.go`, `ping.go`).
- **Dialler:** gotd's default resolver, unless a proxy is configured, which then dials with a 30 s timeout and 30 s
  TCP keep-alive (`proxy.go`). Whether the live install has a proxy set was not checked. The VPN is not a proxy.
- **Flood-wait middleware:** the flood guard sits on the main client (`Middlewares`), and on every pool request
  through `sharedInvoker` (parts, hashes, ranges).

### 5. Counts of connections dialled, re-made or closed
**None. The old app does not count them**, per hour or per run.
- The only log is gotd's own debug log: "Connection died", "Creating new connection". It is written only when
  `TGDL_TELEGRAM_DEBUG` is set (`gotd_client.go`), to the console, which is off limits here.

**Correction to answers 4, F.17:** "0 lost connections in 129 hours" does not show that connections did not die.
- **Death before Telegram acknowledged a request:** the library retries the request on another connection by
  itself (`pool.DC.Invoke`, `errRetryableOnNewConn`). The app never sees it, so **it is counted nowhere**.
- **Death after the acknowledgement, before the answer:** the request fails with "engine forcibly closed: context
  canceled".
  - The old app's failure kinds test `context.Canceled` **before** "connection lost" (`pacer_fails.go`), so the
    report counts it as **"cancelled"**, not "connection lost".
  - Its request is asked again (`retryLostConnection` matches the text).
  - So "cancelled" is an **upper bound** for those deaths. It also holds real cancellations.
- **"Cancelled" part requests in the unlimited hours above:**

  | Server | Hours | Cancelled in all | Per hour: lowest / median / highest |
  |---|---|---|---|
  | DC1 | 22 | 88 | 0 / 3 / 12 |
  | DC2 | 20 | 0 | 0 / 0 / 0 |
  | DC4 | 23 | 12 | 0 / 0 / 11 |
  | DC5 | 22 | 360 | 2 / 16 / 42 (its -503 runs end "cancelled") |

  So DC4, at about 1.8 parts in flight, had **at most 12** deaths after an acknowledgement in 23 unlimited hours
  (474 GB). Deaths before the acknowledgement are unknown.

### 6. Library version
`github.com/gotd/td v0.163.0` (`core-service/go.mod`). No `replace` directive, no vendored copy and no fork. The Go
toolchain is go1.27.2. The new app uses v0.166.0: what changed between them was not read.

### 7. By the code: part size, and connections per file
- **Part size 1 MiB** (`downloadPartSize`). Checks may read smaller ranges, which divide 1 MiB.
- **A file's parts are spread over connections.**
  - Each file downloads with up to 4 threads (`defaultDownloadThreads`; halved after a wait, one added back after 8
    clean files). The server's window bounds them.
  - Each part request goes through the server pool's `Invoke`, which takes whichever connection is free.
  - On DC2 and DC4 each part also picks the main or the media route by share (`route.go` `pick`).
  - Nothing keeps a file on one connection.

## C. What might make the difference (by the code, not measured)

### 8. Candidates, most likely first
1. **When a request asks again after a plain wait.**
   - The old app sleeps the full stated wait plus 1 s for that request before asking again.
   - It also passes the server gate and the account-wide rate limiter (60 requests a second, burst 60,
     `accountRequestRate`) on every part.
   - Your run has no flood-wait middleware. If anything in it asks again before the wait is over (the "ask early"
     switch, or a retry loop of the pool or the downloader), Telegram may answer by closing the connection.
   - Your figure of about 0.6 losses per plain wait fits a link between the two. The old app has never asked early,
     so it has no number on this.
2. **The home server's pool.**
   - The old app never uses `Client.DC` for the home server: `fileDC` and `guardedClient.Pool` call
     `Client.Pool`, which shares the main session's key.
   - In gotd v0.163, `Client.DC` for the home server makes a pool with a session of its own, and skips the auth
     transfer, because the server equals the home DC (`telegram/pool.go`, `dc`).
   - If the test account's file server is its home server, check how your pool authorises. A connection whose key
     is refused would die and be re-dialled.
3. **Pool lifetime.** The old app keeps each pool for the app's life and never closes a pool or a connection itself.
   A pool made, or closed, per file or per batch would show as a stream of new dials.
4. **Long per-part deadlines.** The old app's 2 minutes means a slow part is almost never cancelled. A cancel does
   not close the connection in gotd, but a short deadline plus your own handling might.
5. **The library version** (v0.163.0 against v0.166.0): not compared.

**Not causes, by the code:**
- The pool's size (12 against your 6): with 2 in flight both use about 2 or 3 connections.
- The ping settings: both use gotd's defaults, unless yours changes them.

**What would tell them apart on your side:**
- turn on gotd's debug log for one run, and count "Connection died" by its error (missed pong, EOF, a transport
  code such as -404 or -429);
- note whether a death follows a wait on the same connection, and how soon.
