# Review G4, second pass: the fix round, the conversion onto the mirror's real door, the merges — read-only

Reviewed: `wip/pages-g4` at 8bba0348 in the copy `wt-pages-g4` (left clean: no file changed, no git command that
writes). Read: `git diff 1929057a..9c98e3dd` (the fix round), `git diff 4842f7fa..550be61c` (the conversion), the
merge of 639ed1c0; the real door (`internal/mirror/door.go`, `internal/collector/mirror_door.go`,
`collector/pages_mirrors.go`, `catalog.MirrorChatRows`, `collector/mirror_auto.go` autoApprove, `reader.go`
ApproveRead), the rig test, the guard and held stop, the rewritten `DESIGN-G4-mirror-from-page.md`; the report's
three new sections last. 2026-11-16 04:22.

Ran (named only, `GOGC=25 GOMAXPROCS=2 -p 1`; the PC measured before each: 7.3 to 7.8 GB free, CPU 35 to 48 %):
my 4 server probes again, adapted (`-overlay`, 1.5 s); 2 new probes on the real door through the pages over the
running collector on the fake Telegram (`-overlay`, 217 s); the rig test `TestMirrorPagesWishOnFakeTelegram`
(28.8 s, pass); the door's scale test `TestMirrorWantChatRowsAtSize` (3.1 s, pass); node runs of `mirrorwords.js`.
Nothing against Telegram; no race detector, no Docker, no whole-package run.

Count of new findings: **must fix 1, should fix 7, minor 8.** Of the 28 earlier findings: 25 closed, 3 partly,
0 not. Of the 7 earlier untrue lines: the page was rewritten; 6 of the new page's lines are not true (below).

---

## The earlier findings

| # | Finding (first pass) | Now | Evidence |
|---|---|---|---|
| M1 | Chosen chats end a stop | **closed** (residual: N6) | `chosenItems` takes only state `none`; stopped, never, ended, blocked, going left out and counted (`mirrorwords.js` 256-277); the row's yes says "ends your stop" |
| M2 | Settle word names no block | **closed** | the door's `ChatState.Block` (mirror row, state, batch, block words, word on record) goes back with the word; `SettleWord` refuses `ErrBlockChanged` in the same transaction; keys carry block and batch; after a rebuild the keyboard never lands on a word (`settleSafe`); a second tab is refused because the first word changes the token |
| M3 | Contradiction offered by-rules | **closed** | the door's `BlockOffers` gives arrived / not-arrived; the table words them "under new ids" |
| S1 | Cancelled poll kept as failure | **closed** | probe again: the next polls at +0 s, +14 s show no error (door asked with `s.base`, 10 s bound) |
| S2 | Missing account read as "Not mirrored" | **closed** | `ListAccounts` failure fails the route; an account absent from the answer: "Not read yet: nothing is offered" |
| S3 | Overview "none" when unreadable | **closed** (new gap: N5) | `none` needs no failed account |
| S4 | Task's "cannot run" not shown | **closed** | `taskNote` in every cell's note and in the plan box |
| S5 | Estimate 202 "Telegram answered" | **closed** | 202 says "Asked: the answer is not in yet" |
| S6 | Allow under a mark lifts unseen things | **closed** (but N3) | "Under the mark: ..." and "Allow again: this also lifts the ..." |
| S7 | Settle words not the command's | **closed** (minor N9) | the catalogue's Take...Risk words by block; create-not-made with its condition and risk |
| S8 | Protection "no" when not known | **closed** | "not known" |
| S9 | Empty request list agreeable | **closed** | `yesBlockedWhy` |
| S10 | Rebuild under the pointer | **closed by reading** | words patched in place; a new shape held while the pointer is on a row; not seen in a browser |
| S11 | "Nothing was recorded" unknown | **closed** | failure words say the next reading shows it (probe); a stored setting whose re-read fails says "Stored." |
| S12 | Log on every poll | **closed** | probe: 4 lines for 6 polls on 2 failing accounts (was 14) |
| S13 | Bound not said on a single yes | **closed** | the sentence says the create waits, with the time room returns |
| m1 | Moved plan, re-read failed | closed | the plan is closed with "open it again"; the bulk words say to click again |
| m2 | Failures called refusals | closed | "Refused" for 409/400, "Failed" otherwise; the bulk says which |
| m3 | Chosen label and cap | closed | label counts the shown ticked; over the cap counted "for the next click"; a failed plan read offers nothing |
| m4 | Sentence on every row without the door | closed | one sentence beside the filter, the title on buttons; no button for private chats or forums |
| m5 | Overview rebuilt every 5 s | closed | `?counts=1`; rebuilt only when its line or as-of changed, focus kept by link |
| m6 | Focus after a click | **partly** | after a yes or a word: to the answer; after "Never mirror" still to the next chat's "Never mirror" (the earlier reviews' rule) |
| m7 | Raw words | closed | unknown offer words dropped; a word on record in words |
| m8 | Choice never read | **partly** | blocks with no offer now get Allow; but `st.choice` is read and the door has no `Choice` field: dead code (N13) |
| m9 | Comment on `When` | closed | field gone |
| m10 | "16 characters" | closed | "16 UTF-16 units" |
| m11 | Tests of the fake | **partly** | a rig test now drives the real door; its claims are stronger than its checks (N8); chatmirror.js still has no test |
| m12 | Statement-count wobble | closed | `countedIn` counts only the test's own catalogue file |

Earlier untrue lines of the owner's page (all 7): the page was rewritten from the door; the old lines are gone. The
new page is judged below.

---

## New findings

### Must fix before the merge

#### N1. A chat never read cannot be mirrored from the page: the yes is recorded and nothing more happens — CONFIRMED (probe on the real door)
`internal/collector/mirror_auto.go` 382-397 (autoApprove), `internal/mirror/door.go` 457-482 (Want),
`internal/collector/reader.go` 601-605 (the reader reads a chat only when approved or under way),
`mirrorwords.js` 59 and 99-106 (the page's yes is off until an estimate is on record).
The page lets the owner agree to a never-read chat only once its size is on record ("Ask Telegram how large it
is" writes the estimate into `collector.read.<account>.<chat>`). The door's Want then approves the read with
`autoApprove`, which leaves any record already there "as it is": the estimate stays unapproved, the reader never
reads the chat, and the task waits for the read for ever. Probe `TestReviewG4bWantAfterEstimate` (pages over the
running collector, fake Telegram): estimate route 200; the plan shows the estimate, not blocked; the yes 200; the
read record after the yes: approved **false**; a second chat wanted without an estimate (the control; the page
itself would not allow that yes) was complete after 2 min 7 s of the clock; the first chat after **60 min of the
clock: still "wanted", 0 forwarded, no mirror made for it**. So every chat the page lets the owner mirror from
"never read" stays "Wanted: waiting for its read", with no word that it never will. The rig test passes only
because it wants a never-read chat with no estimate on record, which the page disables.
Smallest change: in the door's Want, for a source not read, write the approval onto an estimate record that is the
owner's (keep the estimate, `ApprovedAt` and `By: mirror`), and bind it to the cost the page showed: the want
carries the estimate's request count the page showed and the door refuses (moved) when the record's count differs
(as `ApproveRead` does: `EstimateRequests == requests`). A rig test: the estimate through the route, the plan, the
yes, then the chat read and mirrored.

### Should fix

#### N2. The read's cost on the screen is not bound to the yes — CONFIRMED by reading
`mirror/door.go` 377-388 (Token), 468-481; `server/mirrors.go` 669-676. The estimate the page shows is added by the
server from the catalogue; `Plan.Token()` does not cover it, and the door's approval checks no count. A newer
estimate written between the plan and the yes (another tab's "Ask Telegram"), or a want sent for a chat with no
estimate at all (the page's "yes stays off" is the page's only), is approved all the same. Fixed together with N1.

#### N3. A command mirror's block: "not one this page knows", and an Allow that lifts nothing — CONFIRMED by reading
`mirror/door.go` 258-263, 272-290 (offers only for a chat with a want); `livepages/mirrors.go` 223-233;
`mirrorwords.js` 201-211. A mirror made by the command (no want) with a batch of unknown outcome or a create with
no answer is "blocked" with no offers; the page says "This block is not one this page knows" and offers "Allow
again: this also lifts the block; the task may then send for this chat again". The allow removes a want's block,
and there is no want: it lifts nothing. What would work, a want on that mirror ("Mirror this chat": the door takes
it, `WaitsFor` "a batch of unknown outcome", and the task settles it), is not offered. Smallest change: for a
blocked state with `by == "command"`, offer the plan ("Mirror this chat") instead of Allow, with true words.

#### N4. An account not signed in (or not loaded by the running collector) reads "Cannot be read now" on every row — CONFIRMED by reading
`mirror/door.go` 211-214 (`States` refuses `ErrNotSignedIn`); `pages_mirrors.go` 31-32; `server/mirrors.go`
415-428 (any error of `States` is a failed reading). The refusal's words are lost: every row of that account says
"The mirror's record of this account cannot be read now". Smallest change: keep a refusal of `States` as the
account's words ("the account is not signed in: nothing is done for it"), offering nothing.

#### N5. The Overview does not count "waiting" mirrors and calls them none — CONFIRMED (node)
`mirrorwords.js` 325-337. `overviewLine` adds wanted, creating, forwarding but not `waiting` (nor `unknown`); with
only waiting wants (node: `counts {waiting: 3}`) it says "No chat is mirrored, wanted or marked yet." The Chats
filter counts them as "under way". Smallest change: add `waiting` to "under way" (and an "unknown" group).

#### N6. The chosen chats take a plan the door says is stopped — CONFIRMED (node), harm PLAUSIBLE (a race)
`chatmirror.js` 274-286; `mirrorwords.js` 99-106. `chosenItems` judges by the page's last reading (up to about 20 s
old); the plan read next may say `stopped: true`, and `yesBlockedWhy` passes it (node: a stopped plan is not
blocked), so a chat stopped meanwhile in another tab is in the one yes and its stop is ended without a word.
Smallest change: in `planChosen`, leave out a plan with `stopped` (and say so).

#### N7. The rig test proves less than the report and the owner's page say — CONFIRMED by reading
`collector/pages_mirror_test.go` 118-196.
- The counts are taken around chat A only (from after the chat list to A complete); they assert `creates == 1`,
  forwards between 2 and 3, `help.getConfig` 0 or 1, and count no read: "exactly 2 forwards, 1 help.getConfig,
  nothing else" is what this run did (I saw 1, 2, 1), not what the test holds.
- "Nothing sent for a chat marked never": B never had a want; nothing could be sent for it. A never mark on a chat
  under way is not tested here (my probe did it once: 0 writes over 10 min of the clock after the mark).
- "No write over 5 minutes of the clock" after the stop: the rig's `FastClock` moves whether or not the task
  runs, and nothing after the stop shows the task alive: it passes if the task died. A forward whose intent was
  written before the stop and sent after the answer (allowed by the door) would fail it: a possible flake.
- Real time only bounds the waits: it judges nothing on real time.
- A second create for A inside its window is caught; a forward into the wrong mirror is not checked (only kinds
  are counted; A's mirror's contents are not compared with A's messages).
- It never takes the page's own path for a chat never read (N1).
Smallest change: assert the counts the report states; add a chat under way that is marked never; a second chat
going on after C's stop as the positive control; compare the fake's mirror contents with the source.

#### N8. Not done at the conversion: the wording of a block no table row knows — minor-to-should, CONFIRMED by reading
`livepages/mirrors.go` 211-217, 234-243: a word the door offers for a block word not in `blockOffers` gets the
plain words (e.g. "taken as not arrived" without "under new ids"). Every block word the door can offer for today
is in the table (checked against `BlockOffers`), so this is only for the next block word; a test that every
`BlockOffers` case has a table row exists (the report). Kept as a should only because a new block would be worded
falsely without a failing test if the test lists the cases by hand.

### Minor
- **N9** create-not-made's words omit the second condition the task keeps: the word is carried out only once the
  chat list was stored after the create plus the margin (`CheckNotMade.Listed`); until then it waits.
- **N10** `mirrorRouteList` (mirrors_test.go 507-521) lacks `POST /api/mirrors/name-check`: no-store, 405 and the
  log test do not cover it (the guard lists do).
- **N11** `mirrorStates` holds the server-wide lock across `States` and `Task` (up to 10 s each by the bound; 0.28 s
  at 300 mirrors and 200,100 forward rows): a slow door holds every poll of every account.
- **N12** The yes sentence says "1 request asking the chat's size" for a chat whose size is already on record: the
  door's plan lists it (`MethodHistory`, 1) but nothing in the page's flow asks it again.
- **N13** `cellOf` reads `st.choice`; the door has no `Choice` field: dead words.
- **N14** The token binds neither account nor chat (`Plan.Token()`): two chats in equal states share one; a body
  `{chat B, token of A}` passes. The page never sends one so; only a crafted request with the run's token could.
- **N15** `patch()` builds every row's cell again off the page on each poll whose words changed (2,000 cells every
  5 s while a mirror moves).
- **N16** After "Never mirror", the keyboard goes to the next chat's "Never mirror" (m6, by the earlier rule).

---

## The conversion against the real door

**(a) The yes.** `Plan.Token()` hashes the plan's fingerprint (mirror row, last batch and its state, batches,
candidates, exists, protected, refused, blocked words, pause, read done, cursor, known, switch off, adoption, name
rule) plus mark, stop, end, kind, mirror chat, put-back count, frozen, gap, read done, the chat list's protection.
It moves with a new candidate, a mark, a create (door tests) and with any of these; it does **not** bind the
account, the chat (N14) or the read's estimate (N2). Want makes the plan again, compares the token, refuses by
`wantRefusal`, and writes the want in one transaction; a yes for a plan the owner was not shown is refused except
through N2 and N14. `WaitsFor` (no candidates now, the bound per hour, a long wait, an open gap, a batch of
unknown outcome or refused as a repeat): the door takes the want and the task waits, as the page says; the settle's
reads for a batch of unknown outcome are on the plan's "The settle" line, not in the yes's sentence. A chat never
read: N1 and N2.

**(b) The settle word.** One block, one word: the token includes the word on record, so a second word (two tabs)
is refused as moved; a block that changed is refused; `wordFits` is the same rule for the door and the task. The
door offers: cannot tell, contradiction, repeat → arrived, not-arrived; again, a day's settles → by-rules; a create
with no answer and no block words → create-not-made; else nothing. The page's words for each are true of that
block (contradiction and repeat "under new ids"), except N9. A block no row knows: N8. A command mirror: N3.

**(c) Stop, never, allow on the real door, through the routes.** "An allow never undoes a stop": shown by the rig
test (an allow after the stop, still stopped). "A never mark does not recall a request whose intent was written; no
request starts after it": my probe marked a chat never after its first forward: 0 writes over 10 min of the clock
(the "not recalled" half did not occur in that run). "Stopped, never and ended chats are left out of the chosen
chats": never and ended are refused by the door itself (`ErrWantMarked`, `ErrWantEnded`); a stop is left out by
the page only, as of its last reading (N6).

**(d) The wrapper** `collector/pages_mirrors.go`: converts `MirrorTask` and `MirrorNameRuleFacts`, holds the
compile-time check, maps `errNoSuchAccount`, `ErrNotRunning`, `errNoSecretFile` (and `catalog.ErrNotFound` of the
task) to the adapter's sentinels. It takes no lock; the doors take `c.mu`, `a.mu` and `s.auto.mu` for a moment
each, none across a catalogue call. An unmapped collector error (`errSignInUnreadable`, a catalogue failure) is a
failure: "The mirror's record failed now ...; whether anything was kept shows at its next reading", logged by its
class. A refusal of `States` is shown as a failure (N4). Nothing here can delay the collector's stop: the server
asks with the pages' own context, bounded at 10 s, and the doors answer `ErrNotRunning` once the catalogue is gone.

**(e) The states' route.** `MirrorChatRows` at 300 mirrors and 200,100 forward rows: **9 statements, 0.28 s**
(the door's own test, run here); the door adds 2 reads of the sign-in record, and the task 1 refusal read, 2
sign-in reads and a file check. Asked at most every 5 s per account while the catalogue's key moves, every 15 s
when quiet: at most about 170 statements and 3.4 s of one reader connection a minute per account. Right after the
owner's own click the guard's change count forces a new reading (probe again: never and stop seen at once).

## The merges
- The held stop refuses every change route registered through `handle`, the mirror's 8 and the Staging page's 2
  included; `TestMirrorHeldStopRefusesChanges` is real (the actual routes through the guard, no door reached,
  `GET /api/mirrors` still 200) and counts 10.
- Guard lists, checked by hand: all 8 mirror change routes (want, stop, never, allow, settle, name-check,
  name-rule, gather) are in `mutating` and `programOnly`; the 3 reads are refused cross-site by the guard before any
  handler (`TestCrossSiteRefusedOnEveryRoute` walks the patterns). Only the test-own `mirrorRouteList` lacks
  name-check (N10).
- The Overview shows the Staging line, then the Mirrors region (counts only); N5.
- `api.js` `body || {}`: every reader uses `err.body?.x`; nothing shows the body raw.

## Lines of the owner's page (`DESIGN-G4-mirror-from-page.md`, 11-16 04:15) that are not true

1. **Lines 7-8**, "one create, two batches of forwards, one request for Telegram's limits, nothing else". True:
   "one mirror was made through the pages on the fake Telegram in a test, for a chat whose size had not been asked
   (in that run: one create, two forwards, one request for Telegram's limits; the test allows a third forward and
   counts no read)."
2. **Lines 12-16**, the row words. A chat that forbids forwarding is not "Not possible" on its row: it reads "Not
   mirrored" (its plan says it is protected and blocks) or "Ended for good: the source protects its content". The
   list lacks "Waiting: waits for the automatic mirror to be switched on" and "Not read yet". "Cannot be read now
   (then nothing is done for it)": true is "then nothing is offered for it"; and an account not signed in shows it
   too (N4).
3. **Line 28**, "Yes, mirror it": "for a chat not read to its end, your approval of its read with it" and "(1) the
   chat read to its end by the reader". True today: "for a chat never read, whose size you asked first, the wish is
   written but its read is not approved: it is not read and nothing more is sent for it" (N1).
4. **Lines 50-51**, point 3, "A chat that was never read is read for its mirror on your yes ... Built so." Not
   true (N1). Also "its files stay not downloaded" holds only for a chat the catalogue did not know; a chat on the
   Chats page is known, so its own download switch decides whether its read queues files.
5. **Line 29**, the chosen chats: "a chat you stopped ... is left out". True: "left out as of the page's last
   reading (a stop made in the last seconds elsewhere is not seen)" (N6).
6. **Lines 31 and 33**, "the button says which before you click" and "Where a block offers nothing ... use Allow
   again or the command": for a mirror made by the command, the row calls its block one the page does not know and
   its "Allow again: this also lifts the block" lifts nothing (N3). Line 33's "it was not created only when no
   channel of that name exists" omits that the task also waits for the chat list read after the create (N9).

True as written, checked: the plan line (26), the estimate button (27), the chosen chats' cap and one yes, never
(30), allow keeps a stop (31), the stop and its caveat (32: nothing in this tree writes the read's end mark yet, so
the reader may still read), the settle words (33, but for N9), Settings (34), the bounds (37-41).

## What I found sound
- The block token and its one transaction; the word refused for any other block; keys and focus that cannot carry a
  word to another block.
- The server asks the doors with its own context and logs a failure once per class; the own click is seen at once;
  a failed account offers nothing; the task's state shown where the owner clicks.
- `MirrorsOf` over the compile-time-checked wrapper; refusals by sentinel; words never parsed for offers; the
  door's offers only, the page's table for words.
- The guard and held stop over every mirror and Staging change route; the demo's fake memory-only (every route,
  name-check and a settle with its block included, left the catalogue file unchanged: probe).
- The states' door: a fixed 9 statements at size.

## What I did not look at
The pages in a browser (desktop, phone, the pointer hold, focus); the task's turns themselves (`auto.go` beyond what
the door and the probes touch); the "not recalled" half of never and stop (it did not occur in my one run); a real
account; whole-package and race runs; the Staging page itself beyond its merge points.

## What the race detector should be run on for this piece
- `internal/server`, named: `TestMirrorNeverTwoClicksAtOnce`, `TestMirrorStatesCostBounded`, the cancelled-poll test
  (`ctxMirrors`), `TestMirrorHeldStopRefusesChanges`, `TestMirrorRoutesInGuard`: the kept states under one mutex
  read by concurrent polls and `keptTask`, the server's own context.
- `internal/collector`, named: `TestMirrorPagesWishOnFakeTelegram` (HTTP goroutines calling the doors while the
  reader goroutine runs the task: the wrapper and the `turnDue` nudge). `livepages` is pure: no race run.
