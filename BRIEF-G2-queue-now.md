# Brief G2: the Queue page says what is downloading now, what just finished, what failed and why (pages track, session P2; 2026-11-15)

Roadmap row D2; FEATURES section 1 rows 3, 4 and 9 ("files downloading now, per server", "last finished files,
opening the post", "why files failed: kinds with counts; retry"). **Not started: it is cut from G1's head
(`wip/pages-g1`) once G1 is handed back**, because it uses G1's live seam and the pages' refresh. For one Opus
coder; the copy, the branch and the base are named when it is started. Rules of work as in
`BRIEF-G1-one-program.md` ("Rules (hard)": load, named tests only, commits, pushes, the report, never a real
catalogue or account).

## What the old app already knows (read by the main session; the old page is `wt-v12.31` `ixassets/ix.html` 340-392)
- Its Downloads card: one verdict word with a line of advice; "N downloading · N waiting · N failed (N no
  longer retried automatically)"; a table "Why files failed" of error kinds with counts; one button "Retry all
  N failed now"; per server "N at once, speed, seconds a part, state". The owner asked for exactly these three
  lists in the new app (FEATURES 1) and for one vocabulary where every number says what it counts
  (TRIED-BEFORE 10: "Downloading: 424 left" counted held copies; "Downloading 14 vs 25" came from a list cut at
  1,000 beside a count of the whole queue).
- **The queue list jumped** because the page listed in one order while files downloaded in another (12.3):
  a page that shows "next" uses the lane's own order (TRIED-BEFORE 19).
- **Retrying is mostly futile on a server that is timing out**: first retries were answered 651 of 651, 129 of
  243 and 15 of 298 by server; second retries 0 of about 404; the files' server, not the files, was at fault
  (TRIED-BEFORE 5). So "try again now" says what it does and what happens next, and a server in a storm is
  named beside its failed files.
- **Every queue action is one indexed statement, tested at the queue's real size**: the old batch Pause was
  1,000 scans of 361,378 rows and timed out half done (LESSONS-ix12.30 6b). "Stop taking new work" and a
  bulk action never touch held or kept-held files (TRIED-BEFORE 19).
- Decisions made by matching words in error text were a finding of the old app's review (TRIED-BEFORE 21, C5):
  reasons are the engine's fixed words, grouped as they are, never parsed.
- The old app could not say where a file's bytes were (staged, copied, verified) without three screens. The
  new catalogue has one row per file for it (the store's ledger).
- A poll must be cheap: G1's `/api/live` reads no table; lists are asked again only when the change key moved,
  at most every 5 s.

## What exists
`internal/server/queue.go` and `web/assets/js/pages/queue.js` (next small and large by `NextWanted`, set aside,
held with evidence; "Try again now" per set-aside file; release and keep per held file). The catalogue:
`c_want` (state, reason, retry_at, attempts, asides, dc, large, claimed_by; indexes `c_want_state(state, dc,
large)`, `c_want_aside_lane(dc, probable, retry_at)` for aside), `c_progress` (the checkpoint: offset and when;
files under 8 MiB keep none), `file` (saved_at, verified_at), the store's ledger (`catalog/staging.go`
`QueueOf`, `QueueSummary`), `Aside`, `Gone`, `RequeueAsideDC`. Read `state.go` and `staging.go` first.

## What to build (all in `internal/server` and its page; the catalogue only where a read needs a function)
1. **Downloading now**, per server and account: the files in state `active` (by the state index), each with its
   name, the best-ranked chat that carries it, its size, and "at least X of Y, as of the checkpoint N s ago", or
   "started: no checkpoint is kept under 8 MiB". No speed per file is shown (nothing measures it); the
   server's own speed and state from the live snapshot stand above the list. The count is the list's own
   length and is said as such; when the lanes' "files in transfer" differs, both are shown with what each counts.
2. **Just finished**: the last 20 files recorded as saved, newest first, by an index walk (say which index; if
   none serves the order by save time, order by the row's number and say in the heading what the order is; **no
   schema step**: if you find one is needed, stop and say so). Each: name, chat, size, when, and where its
   bytes are in fixed words: in staging, waiting to be copied; copied, not verified yet; in the library,
   verified; written straight to the library. A link to its post in the viewer when the viewer's address is
   set and the viewer has an address for a file by a number the catalogue holds (read `internal/viewer`'s
   routes; if it has none, no link and say so in the report: do not add a route to the viewer).
3. **Failed, with reasons**: files set aside, grouped by the reason on record as it is (fixed words), per
   server: count, bytes, "tried N times" (smallest and largest), the next time one is tried by itself; files
   gone from Telegram counted apart with their reason (nothing retries those). Beside a server's groups: the
   lane's state when it is in a storm or its network is away. Per group one button "Try these N again now": **one
   indexed statement** for the group (state aside, that server, that reason), never a loop over files; its
   sentence says what happens ("They go back in line by rank. A file that times out twice is set aside again,
   for longer."). It never touches a held or kept-held file, a file in transfer, or a file the owner set aside
   by hand if the catalogue tells those apart (find out; say how).
4. **"A held copy waits for your release" (`held_wait`)**: a switch above the held list with its sentence
   (on: a held copy is downloaded only when you release it; off: held copies come last, after every other file
   of their server). Find where the supply reads it and say beside it when a change takes effect.
5. The page never jumps: every list is in the lane's or the statement's own order and is not sorted again in
   the page; while the pointer is over a row with a button, or a click's request is in flight, a refresh waits;
   a refused click keeps its message until the next click. Every list says its age and what it counts; a list
   cut at its limit says "the first N of M".

## Tests (named; invented data; judged by statements, rows and plans, never by seconds)
`TestQueueActiveList` (with and without a checkpoint), `TestQueueActiveCountSaysWhatItCounts`,
`TestQueueJustFinishedOrderAndPlace` (each place), `TestQueueFailedGroups`, `TestQueueGoneCountedApart`,
`TestRetryGroupIsOneStatement` (a counting wrapper; at 300,000 rows the plan uses the index),
`TestRetryGroupLeavesHeldAndActive`, `TestHeldWaitSwitch`, `TestQueueListsCutSayTheirTotal`,
`TestQueueLogNoNames` (the guard of G1 extended to these routes). On the collector's rig, one named run:
a file the fake makes time out twice shows under its reason, "Try these again" gets it downloaded once the
fake answers. Mutations: the retry as a loop of statements; the retry taking a held file; a list sorted again
on the page (a test on the answer's order); "at least X" taken from the file's size instead of the checkpoint.

## Not in this piece (listed, later; say nothing is built for them)
Pausing one file at its next checkpoint; files of 1 GB or more as their own line; downloaded per day; the
per-chat estimate. The Staging page (D4) is its own piece.

## Since this was written (2026-11-15 19:35): what G1 became, and where you work
- **Copy and branch:** `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-g2`, branch `wip/pages-g2`, cut from
  G1's head 541743d (`wip/pages-g1`, which holds the main head fa8c011 with the automatic mirror and K1). G1
  is in its full runs and not merged yet; if it changes you will be told to merge it in. Push with
  `git push private wip/pages-g2`. Progress and report: `archiver/docs/progress/pages-g2-PROGRESS.md` and
  `pages-g2-REPORT.md`.
- **Read G1's report first** (`archiver/docs/progress/pages-g1-REPORT.md`, all its sections) and use what it
  built instead of building beside it: routes are registered through `handle(...)` (the route's pattern is
  what the fixed-words log names); a handler whose work may be long takes `s.lasting(r)`; the Queue's answer is
  kept by the change key with a 5 s floor (`overviewcache.go`: one working-out of the queue at 300,000 files
  measured 188 to 247 ms, close to the quarter second above which the floor must become 30 s: **measure again
  with your lists in it and apply that rule**); the page shows "In transfer now" per server from the lanes and
  a notice while downloads are paused (`pause.js`); the Overview repaints by shape (`shape.js`): give the Queue
  the same (lists and numbers updated in place, controls not rebuilt under the pointer); controls that need
  the program carry `data-needs-program`.
- **The scripts' guards:** after any change under `web/assets/js`, `TestScriptsNoDuplicateOrMissingNames` and
  a module parse of each script with node (`node --input-type=module --check < file`). A page that fails to
  parse shows nothing at all: this happened once on this branch and no Go test saw it.
- **K1 is in:** a file of a chat nobody chose is held as not collected (its reason is the catalogue's fixed
  word): it is not a failure and does not belong under "Failed"; the held list already has its own place.
- **Open it yourself before handing back:** `TestPagesHold` (collector's tests; `TGARCHIVE_PAGES_HOLD=127.0.0.1:<a free port>`)
  serves the pages over the fake Telegram on invented data; look at the Queue page in the built-in browser
  if you have one, with something downloading, something set aside and something just finished; say in the
  report exactly what you saw and what you did not.
- **Two small faults of the Chats page, to fix in this piece** (found in the main session's browser pass):
  (a) after an estimate arrives, the "Asked: the account first waits out a wait..." note stays beside it:
  it goes when the estimate shows; (b) the Collect switch's toast is four sentences and says "No file changes
  state: each is saved, or also in a topic or chat that collects it" for a chat with no files listed: say
  what happened in one sentence with the effect's counts, and "it has no files listed yet" when it has none.
- Memory: the full runs of G1 are using the PC for about an hour from 19:35 (a race run of the collector in
  Docker and whole Windows tests). Until then be sparing: read first, compile late, one go command at a time,
  and wait when free memory is under 3 GB.
