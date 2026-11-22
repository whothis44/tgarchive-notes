# Digest of lessons: what the old app and the archiver have learnt, one line per item, with the number and source.
When your work touches an area, read that area's source sections too.

Sources: TB TRIED-BEFORE, LS LESSONS, WE WINDOW-EVIDENCE, CC COPY-CHECKS-STUDY, TF TELEGRAM-FACTS (all in
`repo-archiver/archiver/docs`); L29 LESSONS-ix12.29-servers, L30 LESSONS-ix12.30-live, LV LESSONS-viewer-ix12.32,
A4-A10 ANSWERS-for-archiver-N (this folder). Numbers are the old account's (no Premium) unless "test account".

## Hard rules
- Only exact evidence may skip a file: the same Telegram file id, the same SHA-256, or every part hash. TB §6, CC §E.1
- A probable copy is held, never skipped, and never goes before unique files. TB §6, §15
- A frame check's "no match" never releases a file by itself. L30 top, A8 §C.4, A10
- Every wait Telegram states is slept in full; a part's wait plus a 1 s margin. TB §27-28, A6 §A.2
- Never download from a source the owner did not choose: find, count, read, propose; queue nothing without a yes. L30 §6b
- Compare adjacent hours of one regime; marker is MB per speed-limit wait (0.9 before 11-10 16:00, 0.45 after). TB §16
- A number is a defect only if worse than the old app's for the same server and regime; write both first. TB §28
- One day or one run is "looks like"; a lever estimated from one hour (DC1, 13-21 GB/h) was wrong. TB §13, §15

## Telegram limits and waits
- Speed limit per server: ~520-630 MB/h (to 11-08), ~400, then ~190 MB/h since 11-10 16:00, whatever the parts. TB §14, L29 §2
- Speed-limit waits ~14-16 s each, thousands a day per server; volume comes from unlimited hours (60-100 GB/h). A4 §D, L29 §2
- The limit comes in blocks, starts 5-10 min apart per server, lifts together; spells irregular (longest 14 h, 733 GB). TB §14, L30 §6c
- Never settled: whether fewer requests, or less volume taken, shorten limited spells. TB §14, §19
- Plain waits on parts ~1.3 s on DC1/2/4, rare and 31-52 s on DC5; none of 60 s or more on record. A8 §A.1
- Plain waits follow neither the window (as many at 1.1 parts as at 2) nor files started (5,007 files, 0 waits). L29 §4, A9 §A.1
- Old account: one plain wait per 2,500-10,500 MB; test account one per 7-14 MB, unexplained, bytes the same: no hunt. A6 §A.1, TB §28
- gotd's floodwait.Waiter holds every request of one type on all servers: wait inside the lane instead. TF §5
- File slots per server: 5 small (<20 MB) and 2 large, from app config; never raise them. TF §1, TB §18
- A second process on one login gets AUTH_KEY_DUPLICATED: never share a session file. TF item 2
- Permanent refusals only: CHANNEL_PRIVATE, CHAT_FORBIDDEN, CHANNEL_INVALID, PEER_ID_INVALID, FROZEN_METHOD_INVALID. L29 §7
- Frozen account reads and downloads, is refused chat details and lists (remember a day), sees nothing after the freeze. TF §7, A8
- Stored file references are always stale (3,317 of 3,317): refresh just before download, batched (200 ids a call). L29 §7, TF 1
- Self-destructing media (ttl_seconds) is never archived (API terms). TF 6
- History costs ~1 request per 100 messages; getSearchCounters counts a chat's media in 1 request. TB §14, L29 §7
- Persist waits ("not before") across restarts and check them at the top of every step. L29 §7
- Count per method per minute: requests, waits, seconds asked (min/median/max), refusals by code, connection losses. TB §27, L29 §7

## Download path
- Speed is about min(parts x 3.5-4 MB/s, a server ceiling); DC1's ceiling ~11-12 MB/s at 2-4 parts. WE §1, L29 §3
- Under the limit 2 parts per server: 4 parts gave ~810 waits for 622 MB, 2 parts 422 for 612. TB §1
- Window: try upward only, judge speed per busy slot with failed time counted, baseline-trial-baseline, shadow first. WE rule
- Scale the reaction to the wait: a ~1 s wait at the floor sets no ceiling (the trap held DC4 at 2 in 7 of 7 hours). L29 §4
- Judge by the parts in flight when a wait came, not the window afterwards. L29 §4
- A waiting part keeps its slot: freeing it doubled the waits for the same bytes (test account). TB §28
- Old app: wait +1 s inside the request, at most 3 plain waits a request, nothing in flight cancelled, 2-min part deadline. A6 §A
- One long-lived pool per server; per-file pools caused "engine forcibly closed" bursts; home server via Client.Pool. A9 §D, A6 §B
- Parts already ride separate connections (pool of 12): a "second connection" is no lever. WE top, TB §17
- Media address: 3-14% more per slot on DC2 and DC4, split 50/50; DC1 and DC5 have none. TB §15, A8 §A.2
- Test account DC2 at 4.9-5.6 MB/s is inside the old app's range: the download path is finished, do not tune it. TB §28
- A wait holds only its request; a server's gate closes on one 60 s wait or three of 10 s+ in a minute. TB §2, §20
- -503: one retry, aside after 2 in a row, doubling, bounded per lane; second retries answered 0 of ~404. TB §5
- A timeout on every server at once is the local network: no verdict on a file or server. TB §15
- No answer in 2 min counts as a timeout; a failed claim or finish never stops other downloads. TB §21
- Lanes take files from the catalogue by index walk: no cap, ready list or top-up job; count starved seconds. TB §3
- Per-file "have we got it" checks are index lookups (a table walk cost 2.0-2.8 s a file); test at 1,000,000 rows. TB §22
- Candidates are files, not messages (3,438 of ~6,000 were a file already known). TB §22
- Plan per server: account totals hid DC1 (~65 unlimited hours alone against 26 for the account). L30 §4
- Show unique files left per server: an idle server with none is out of supply, not unfed. L29 §1
- Read before estimating: counts x averages said 0.5 TB, reading found ~2 TB. L30 §1
- Under the limit prefer larger files below 1 GB; files of 1 GB or more one per server, in unlimited hours. TB §4, §16
- Resume: from 8 MiB, checkpoint every 8 MiB or 30 s, write-sync-record, prefix re-hashed, mismatch starts over. TB §19
- Long steps stop within seconds; "stop taking work" is its own state; a crash gives attempts back. TB §7, §19, §21
- Credit bytes per file before crediting a change (a convincing coincidence on 11-13). L30 §3

## Copies and deduplication
- Exact check: 5,007 files / 240 GB skipped in 10 days, all by Telegram's hashes, none undone. A4 §A
- Hashes at three places are not "every part": 3,932 videos (233 GB) were judged so; the new app compares in full. A5 §A.1, TB §27
- Byte-identical waste is small (93 files, 0.4 GB a day); the waste is re-encoded copies. TB §21
- Look-alike: length within 500 ms, aspect 2%, preview pHash 6 bits, saved copy >= pixels and 90% bytes; 256 KB floor. CC §A, §E.2
- Preview distance: <=6 bits 95-98% right, 7-12 76%, 13-20 3%; only even distances occur. LS §3, A5 §B.2
- No stored fact separates wrong holds; an equal-size hold goes to the exact check before frames may release it. A5 §B.2
- Twin holds (against a queued file) were 80% the same content (90% with same id); a wrong hold costs a wait. A10
- A frame check against saved videos must not release a twin hold (437 released, 378 same); read the twin's link too. A10
- Frame "copy" is reliable (184 of 186 judged); "no match" against a named file was wrong about 3 in 4. A8 §C.4
- Frame check: 8 key frames, order 0,7,3,5,1,6,2,4, Hamming 8, slack 2.5 s, >=max(3, 60%) hits, cap 32 parts. CC §B
- Probe: parts fetched as a counted download, slot freed, ffmpeg reads local parts only, unknown is never a verdict. CC §E.1
- Checks cost 10-22 s with unlimited hours, 3-14 min under the limit (half time out). A4 §C.8
- Checks read 171 GB of parts instead of 3,031 GB; 5,590 of 20,850 matched. L29 §7
- Kept parts: >=63 GB reused in 7,916 downloads, 0 refused; download comes 23-55 h later: 100 GB cap, 60 GB free floor. A4 §C.9, CC §C
- A file with a partial download is not checked again; every hold records its evidence (474 reasonless). CC §C.2, TB §6
- Held files reach a lane only when it has no unique file; ranked held copies wait behind unranked unique files. TB §3, §15
- Rank probable copies by likely distinct: frame "no match" first, then look-alike, confirmed last; cheapest check first. L30 §6c
- Fingerprint the local staged copy, never read back from the NAS (20-25 GB/h). TB §6
- 72% of files seen and not downloaded are same-id or probable copies. L29 §7
- 99.6% of saved videos are MP4 or MOV. A4 §C.10

## Forwarding and mirrors (test account, five runs: "looks like")
- A first step is 3 requests; forwardMessages carries 100 messages in about 2.3 s. TF §11
- The pause matters, not the count: 9 s wait at a 10 s pause; 352 in 69 s with none at 20 s. TF §11
- A request told to wait forwarded nothing. TF §11
- WORKER_BUSY_TOO_LONG_RETRY may be partly done (64 of 99): settle by reading the mirror, never resend blindly. TF §11
- Albums are not split; unsent messages went again under the same random ids, no refusal. TF §11

## Staging, the NAS and the library
- Never block downloads on staging (full staging once blocked all downloads 3 h); setting "keep N GB free". TB §8
- The Wi-Fi link caps copies at ~14 MB/s and each staged byte crosses twice (write, read back). TB §16, A8 §D.5
- 8 copies at once reached that ceiling; a big file copies at ~4 MB/s alone, small ones 1.5-1.9. A8 §D.5
- Fixed steps take 42% of copy time at ~4.8 MB a file: batch the catalogue work, keep one big-file lane. A7 §4
- The backlog grows 15-50 GB an hour in a spell: plan staging for a whole spell (500 GB or more). A7 §4, TB §16
- Nothing in the background reads the library while copies wait; never remove a catalogue row automatically. TB §8
- Verification is never weakened, nor a NAS hash helper used, without the owner's OK. TB §16, §21
- A missing file is looked for (name, size, hash) before refetching; clean-up is a plan, a trash folder, an undo. TB §18
- The library being away is a state shown and waited out (42 min once, nothing lost). TB §15
- Measure the copy link alone once and show copy speed live: other programs share it. L30 §6d

## The viewer
- Fast = a warm model in a long-lived process; slow = cold builds, a rebuild per minute, tiles waiting on ffmpeg. LS §1, LV §3
- Real scale: 584k messages, 396k with media, 53.6k albums; months hold 0-69k items: page by count. LV §2
- Build the model once or persist it; update in place; never rebuild on "archive changed". LV §4, TB §9
- No request waits on slow I/O: a tile answers with a stand-in at once and says made or stand-in. LV §5-6
- Video thumbnails made ahead from the local staged copy (254k videos had almost none). LV §4
- Run a filter once per query and keep it (posts page 2: 2.24 s to about 1 ms). LV §3, §5
- Page by a stable key (date, id); arrows follow paging; a folded album keeps its month. LV §6
- Show progress; test cold, at real size and shape, under load (toy 1-16 ms, real 9-77 s). LV §4
- Every copy links to its match; 20+ copies fold to one line; an album is one post. TB §15, LS §1
- Never query the real archive or open media for viewer work. LS §6

## Acting for the owner (TB §24-25, L29 §7)
1. Never undo a person's pause: "paused by a person" is its own state.
2. "The owner took this out" is judged from every trace; leaving scope is a decision.
3. A per-item "never" switch, checked again before every request and action.
4. Telegram's waits are stored and checked at the top of every step.
5. Only "this account cannot read it" is permanent; waits, losses, timeouts are retried a few times.
6. One costly failure ends the step (not 40 chat-list reads in a row).
7. One item per call, each success recorded, a failure passed over.
8. Shared "busy" flags are released with `defer`.
9. No request for an item that will never be acted on.
10. A cap per step (the old app: 10 chats per half hour).
11. One lock for every writer of a stored set, or one row per item (two clicks lost 81 of 150 marks).
12. A person's mark follows the item across a change of id (basic group to supergroup).
13. Fail closed: unreadable marks stop the step; a corrupt value never reads as "empty".
- Also: what the app adds is marked with real names, ranked below the owner's own, never swept in by bulk actions. L30 §6b
- Bulk queue actions are one indexed statement, done in seconds at real size (1,000 pauses timed out). L30 §6b

## Tried and FAILED: do not re-propose
- A window that also tries fewer parts, judged by bytes a second: drifted to 1 part. TB §1, WE
- Cutting the window and capping it 10 min or 2 h on every plain wait. TB §1, L29 §4
- Judging by answer time alone: blind to timeouts, never switched on. TB §17
- More parts under the speed limit. TB §1, §17
- A capped "ready" queue fed by history re-reads, and its eleven patches and top-ups. TB §3, §18
- One wait holding every server; 2-hour shared fallbacks. TB §2
- A check inside the download holding a slot; "download unchecked" on failure. TB §6, CC §B.1
- Small files ordered into limited hours (27 hours: no link of size to GB/h). TB §14
- Slower polls (owner refused); make each poll cheap instead (EXISTS: 62.6 MB to 7 pages). TB §15
- A 320 px preview pass; re-comparing kept frames (0 copies in 675). TB §6
- Media routes for DC1 and DC5; a second connection as a lever. TB §5, §17
- Adding chats by media count (24 of 30 junk to the owner, 34 GB). L30 §6b
- Hunting the test account's waits by margin, slot freeing, library logs: same bytes. TB §28
- Trying the stored file reference first. TB §16
- Blaming our code for a rate drop without adjacent hours (12 h lost; Telegram had halved it). TB §16
- More copies at once against the Wi-Fi ceiling. TB §16
- A pool per file. A9 §D
- Hourly-only counters (a crash lost two starts' rows). TB §27
