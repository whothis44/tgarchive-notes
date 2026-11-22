# Review G4: mirroring a chat from the Chats page (the pages' side) — independent, read-only

Reviewed: `wip/pages-g4` at 1929057a against 2ea9b465 (19 files), in the copy `wt-pages-g4` (left clean: no file
changed, no git command that writes). Read in full: the brief, `BRIEF-G4-mirror-page.md`,
`DESIGN-G4-mirror-from-page.md`, board message 77, every changed file, the mirror package's block words
(`internal/mirror/auto.go`, `mirror.go`), the command's settle (`internal/collector/mirror_cmd.go`,
`mirror_settle_cmd.go`), the guard and `reads.go`; the author's report last. 2026-11-16 00:08.

Ran (named only, `GOGC=25 GOMAXPROCS=2 -p 1`, the PC measured before each: 7.9 to 8.7 GB free, CPU 50 to 82 %):
the branch's 15 `TestMirror*` tests in `internal/server` (all pass, 2.5 s), `internal/collector/livepages` (pass,
0.7 s), and 4 probes of mine loaded with `-overlay` from `wt-pages-review-g4-scratch` (1.5 s); node runs of the
pure functions of `mirrorwords.js`. No browser, no Docker, no race detector, nothing against Telegram.

Count: **must fix 3, should fix 13, minor 12.** Owner's page: 7 lines not true of the page.

---

## Must fix before the merge

### M1. "Mirror the chosen chats" undoes the owner's stop without saying so — CONFIRMED
`pages/chatmirror.js` 224-234 (planChosen), 276 (the list line); `mirrorwords.js` 129-130 (cellOf).
A stopped chat's cell offers `open` (node: `stopped offers open: true`; the branch's own test prints
`stopped | ... | mirror-open-40,mirror-never-40`). planChosen keeps every ticked chat whose cell offers `open`,
reads its plan and lists it as "N messages to forward, about N batches. <sentence>" — nothing says it was
stopped by the owner. Sequence: the owner stops chat A; later ticks "Tick every chat shown" (chats.js 497-500)
to set a rank, presses "Mirror the 20 chosen chats" and "Yes, mirror these 20": A's want is recorded with its
fresh token and A's stop is ended — by a bulk click that never named A. That is the one rule a page can break
here: a stop ends only by the owner's own new want for that chat.
Smallest change: in planChosen, a chat whose state is a stop is left out ("left out: stopped by you; Mirror this
chat on its row goes on where it stopped"); a test (node, over `cellOf` plus a pure `chosenItems`) that a
stopped chat is never in the yes's list.

### M2. A settle word carries nothing of the block it was chosen for — CONFIRMED at the seam, harm PLAUSIBLE until the door exists
`server/mirrors.go` 69, 425-431, 556-560; `mirrorwords.js` 126; `chatmirror.js` 287-300; `chats.js` 524-531.
`SettleWord(ctx, account, chat, word)` and the body `{account, chat, word}` carry no token, batch or block; the
button's key is `mirror-word-<word>-<chat>`, the same for every block of that chat. The page's states are up to
about 20 s old (5 s page poll, 15 s server quiet time). Sequence: block A (AutoBlockCannotTell) shows "Count them
as arrived"; the task settles A and, on the next batch, blocks B (AutoBlockRepeat); the owner, reading A's
row, clicks — or the poll rebuilds the table and `paint(had)` puts the keyboard back on the new block's button
with the same key, and Enter sends it — and `arrived` is recorded for B, whose messages the owner never saw. The
door cannot keep message 77's promise ("a word given for a batch that is no longer the blocking one is removed")
because it is never told which batch the owner meant; at the click it only knows the batch blocking now. An
`arrived` on the wrong batch leaves messages missing from the mirror for good; a `not-arrived` sends requests
the owner was not shown.
Smallest change: the word goes with the plan's token (or the blocking batch's number and the block's word) the
page showed, the door refuses on a mismatch (a sentinel, shown as a refusal that says it is one), and the
button's key carries the block's identity so a rebuild never focuses a new block's button. Needs the mirror
track's word on message 77 (7).

### M3. A contradiction block is offered "settle by the rules", which cannot settle it — CONFIRMED by reading
`collector/livepages/mirrors.go` 237; the command: `mirror_settle_cmd.go` 184-200; the task: `mirror/auto.go`
945-952. `AutoBlockContradiction` is written when the settle's result is `SettleContradiction`; the command
settles such a batch only with `-take arrived` or `-take not-arrived` (without one: "not settled:
contradiction"). offersOf gives `by-rules` for it, so the owner's only button makes the task read the mirror chat
again (1 request per 100 messages) and land on the same block; the two words that do settle it are not offered.
Smallest change: move `mirror.AutoBlockContradiction` to the `arrived, not-arrived` case (the batch was refused as
a repeat, so `not-arrived` goes under new ids); extend `TestMirrorAdapterStates` with that row.

---

## Should fix

### S1. A poll whose page went away is kept as the account's failed reading for every page — CONFIRMED (probe)
`server/mirrors.go` 311-333. The states are asked with the caller's request context, under the server-wide lock,
and an error is kept like any reading. Probe `TestReviewG4CancelledPollKeptAsFailure` (a door that honours its
context): one cancelled poll, then the next polls at +0 s and +14 s answer "cannot be read" (nothing offered on
any open page); +16 s reads again. Sequence: the owner switches from the Chats page to the Overview while a poll
is in flight; the other tab's cells read "Cannot be read now: nothing is offered" for up to 15 s.
Smallest change: do not keep a reading whose error is the caller's own context (`ctx.Err() != nil`), or ask
the door with a context of the server's own (`s.base`) and a bound.

### S2. An account missing from the answer reads as "Not mirrored", with controls — CONFIRMED (reading, node)
`server/server.go` 535-547 (`accountIDs` returns nil on any error), `mirrors.go` 375; `chatmirror.js` 171-177;
`mirrorwords.js` 107-112. If ListAccounts fails, `GET /api/mirrors` answers 200 with no accounts; every cell
then shows "Not mirrored" with "Mirror this chat" and "Never mirror" (node: `account absent from the answer:
Not mirrored | open,never`), so a chat marked never, blocked or mirrored reads as empty. (The change routes
then answer 404, so nothing is recorded; the harm is the false state.) Smallest change: handleMirrors fails when
the accounts cannot be read; cellOf treats an account absent from the answer as not read (no controls).

### S3. The Overview says "No chat is mirrored, wanted or marked yet" when no record could be read — CONFIRMED (node)
`pages/overview.js` 285-286; `mirrorwords.js` 199. A failed account answers `states: []`; overviewLine gives
`none: true, failed: 1`, and the region prints both "cannot be read" and "No chat is mirrored...". Smallest
change: `none` only when no account failed.

### S4. The task's own "cannot run now" is never shown where the owner clicks — CONFIRMED (reading)
`chatmirror.js` 171-203, 143-168; `mirrorwords.js` 102-135. `Task.Runs/Why` and `task_error` are read only by
Settings (`mirrorsettings.js` 92-97). When the task cannot run for an account (stopped by the owner, no forward
secret, the account refused, the record unreadable), the row still says "Wanted: waiting for its turn" or
"300 of 1,200 forwarded" and the plan's sentence says "Afterwards the mirror task sends...". Smallest change:
the cell and the plan box show the account's `task.why` (or `task_error`) beside the state and the yes.

### S5. The estimate inside the plan says "Telegram answered" when it has not — CONFIRMED (reading)
`chatmirror.js` 122-128; `server/reads.go` 233-239. `/api/chats/estimate` answers 202 with `note` when the
answer outlives its bound; `post` resolves on 202, the plan is re-read (still no cost) and the page says
"Telegram answered; the plan below is counted again with it." Smallest change: on 202 show the answer's `note`.

### S6. "Allow again" on a marked chat also lifts an end or block the page does not show — CONFIRMED (node)
`mirrorwords.js` 110. A never mark hides the state under it (node: a chat marked never over an end for good
shows only "Never mirror (your mark) | Allow again"). Allow also clears an end for good and unblocks a want
(message 77 (6); the answer says "(those mirrors go on)"), so the click restarts forwarding the owner was not
shown. Smallest change: the cell shows what lies under the mark and what Allow lifts with it (or, where it
lifts an end or block, the button opens the plan first).

### S7. The settle buttons' words are not the command's — CONFIRMED (reading)
`server/mirrors.go` 196-201 against `catalog/mirrorsettle.go` 168-172 and `mirror_cmd.go` 292. "Send them again
under new ids" is true only for a batch refused as a repeat (the command says new ids only then); "Count them
as arrived: they stay out of the mirror, on record as missing" says the opposite of `TakeArrivedRisk` for any
that did arrive. "The create was not made" omits the condition the command keeps (only when the stored chat
list holds no channel of its name) and the risk of a second channel if it was made. Smallest change: show
`TakeArrivedRisk`, `TakeNotArrivedRisk` or `TakeNotArrivedNewRisk` by the batch's state (the plan carries
`LastBatchState`), and the create's condition and risk.

### S8. A protection not known is shown as "Protects its content: no" — PLAUSIBLE (until M8's field lands)
`mirrorwords.js` 63; `livepages/mirrors.go` 100. Message 77 (2): "Protected known or not known" comes with M8;
the seam has one bool. Smallest change: a `ProtectedKnown` field, "not known" said as such.

### S9. A plan whose request list is empty can still be agreed — CONFIRMED (node and reading)
`chatmirror.js` 160; `mirrorwords.js` 31. With `requests: []` and no block, the sentence is "the plan lists no
request after it" and the yes stays enabled (label "Yes, mirror it"); the task will still create and forward.
Smallest change: the yes is disabled, with a sentence, when the list is empty and the plan is not blocked.

### S10. The whole table is rebuilt under the pointer on any mirror change — PLAUSIBLE
`chatmirror.js` 287-301. Every 5 s, any change of any account's states (each forwarded batch moves `forwarded`)
repaints the whole Chats table (2,000 rows); only a focused field holds it, the pointer never does (the G2b
`placeAction` "hold" exists in `queuelists.js` 218-222 and is not used). With the Mirror filter on, a chat that
leaves the filter shifts every row below it: a click aimed at one row's "Never mirror" can land on the next
row's "Stop mirroring". Also no check of a dragged row (chats.js's own poll has one). Settle it in the browser
with a filter on and a mirror moving. Smallest change: patch the mirror cells in place when only words and
numbers changed; hold a rebuild while the pointer is on a row with a control.

### S11. "Nothing was recorded" said when it is not known, or not true — CONFIRMED for the settings, PLAUSIBLE for the want
`server/mirrors.go` 258, 636, 656, 661-668. After a name rule or gathering is stored, the settings are read
again; if that read fails the answer is 502 with "could not be read or written now: nothing was recorded", and
the page says "Not stored: ..." for a value that was stored. Any non-refusal from `Want` is told "nothing was
recorded" whatever the door did. Smallest change: after a stored write answer "Stored" with the re-read's failure
apart; for other failures say the record shows what was kept after the next read.

### S12. A failing task is logged on every poll — CONFIRMED (probe)
`server/mirrors.go` 377-378. Probe `TestReviewG4FailureWordsAndLogPerPoll`: 6 polls on 2 accounts with the doors
failing: 14 log lines (the task's failure each poll, each account; the states' once). An open Chats page and the
Overview, polling every 5 s each, give about 48 lines a minute per account into the collector's shared log.
Smallest change: keep the task's answer with the states (same floor), log a class once per change of class.

### S13. The bound on new mirrors is not said on a single yes when it is reached — CONFIRMED (reading)
`mirrorwords.js` 62, 16-20. The plan line says "5 of at most 5"; the yes's sentence still says "1 request creating
the mirror" with no word that the create waits until room returns (the chosen-chats path says it, 281). Smallest
change: when `new_today >= new_per_day` and no mirror exists, the sentence says the create waits for room.

---

## Minor

1. **A moved plan whose re-read fails** (`mirrors.go` 521-528; `chatmirror.js` 116): the refusal says "The plan on
   record now is shown" but the old plan stays with its old token and an enabled yes. In the chosen-chats path the
   same words are shown and no plan at all (`yesChosen` empties the list). CONFIRMED.
2. **Failures called refusals**: a 502 or "The app does not answer" is shown as "Refused: ..." (chatmirror.js 85)
   and "Stopped at the first refusal" (mirrorwords.js 178); `mirrorFailedWords` says "nothing is offered until it
   reads again" while the cell and the plan keep their controls. CONFIRMED.
3. **The chosen chats' label and cap**: the label counts every ticked chat, hidden ones included (bulk 260, 273),
   while only the shown ones are planned; the cap takes the first 20 ticked, already wanted ones included, so a
   21st ticked chat is never reached until chats are unticked. A plan read that fails midway still offers "Yes,
   mirror these N" for those read. CONFIRMED.
4. **Without the door** (the real program today) every row, private chats and forums included, shows "Not mirrored
   from here", a disabled "Mirror this chat" and the full sentence again (2,000 times). CONFIRMED.
5. **The Overview's region** is rebuilt every 5 s whether it changed or not (focus on its links lost) and fetches
   every state of every account for counts. CONFIRMED.
6. **Focus after a click**: after a yes the keyboard lands on that row's "Stop mirroring"; after "Never mirror" on
   the next chat's "Never mirror" (the earlier reviews' rule); a repeated Enter acts on it. CONFIRMED.
7. **Raw words**: an offered word the server does not know is a button labelled with the bare word (and its click
   answers 400); a word on record is shown bare ("Your word is recorded (arrived)"). CONFIRMED.
8. **Choice is never read** (`mirrorwords.js`): message 77's `Choice` ("only an allow lifts it") is neither shown
   nor answered with "Allow again"; a blocked mirror with no offer (read refused, two channels) has no control
   but Stop. PLAUSIBLE until the door's states exist.
9. **Comment** `mirrors.go` 351-353 says the request methods' words come in `when`; they live in mirrorwords.js.
10. **Help text** "At most 16 characters" (mirrorsettings.js 57-58) where the check counts UTF-16 units.
11. **Tests of the fake, not the product**: `TestMirrorNeverTwoClicksAtOnce` and
    `TestMirrorStopIsNotUndoneByThePage` judge the invented doors (the server keeps no list and no stop); the
    "two at once" overlap is never asserted (the 10 s guard lets a lone request through and the test still
    passes), so the "never as one list" mutation can only have been applied to the fake; and the one real way a
    stop is undone by the page (M1) is in `chatmirror.js`, which no test drives. A cellOf "primary" mutation is
    caught, but chatmirror.js renders every word button the same and a mutation there would not be.
12. **The statement-count wobble** (`TestChatsAskAgainOnKey` 4 against 5, the cost test 5 against 6): the counter
    in `stmtcount_test.go` is process-wide and counts every catalogue connection of the test binary; the extra
    statement was on the "alone" side, i.e. another goroutine's. This branch adds no goroutine (its seam calls
    are synchronous; the demo's loop is closed in cleanup), so PLAUSIBLY not its doing; candidates are earlier
    tests' estimate goroutines (`s.bg`, not awaited by the test helpers) and demo loops between Close and their
    last step. Settle by logging the tables of the extra statement; fix by counting only the test's own catalogue
    (filter on the connection's path) or awaiting `WaitWork` in cleanup. No test of this branch judges on real time.

---

## Block word -> what the page offers (offersOf, `livepages/mirrors.go` 228-241; a word on record: nothing)

| Block word (mirror package) | Offered | Right? |
|---|---|---|
| AutoBlockCannotTell | arrived, not-arrived | the right two; the words wrong in part (S7: "new ids" only after a repeat) |
| AutoBlockRepeat | arrived, not-arrived | right (the command: -take; not-arrived under new ids) |
| AutoBlockContradiction | by-rules | **wrong** (M3): needs arrived / not-arrived |
| AutoBlockAgain | by-rules | right (mirror -settle decides; it may then block on "cannot tell" and offer the two) |
| AutoBlockDay | by-rules | acceptable (an owner's settle past the task's 3 a day) |
| AutoBlockReadRefused | nothing | right (no read possible); only Stop is left (minor 8) |
| WhyBatchUnknown | by-rules | right |
| WhyBatchAlready | by-rules | right |
| WhyUnknown (a create with no answer) | create-not-made | the command's word, but its words omit the condition and the second-channel risk (S7) |
| WhyTwoChannels, WhyMirrorNoHash, WhyNameRule, WhyAccountRefused, any other | nothing | right |

Every offer depends on exact equality with today's text; a block word stored by an older build matches nothing and
offers nothing (fails closed).

## Lines of the owner's page (`DESIGN-G4-mirror-from-page.md`) not true of the page

1. Line 7-8 "It is built and tried on the fake Telegram only": the page was tried on invented doors in memory; no
   door exists, nothing ran on the fake Telegram, nothing has mirrored anything.
2. Lines 11-12 the row words: the page also shows "Wanted: waiting for its turn", "Creating its mirror", "N
   forwarded" without M (whenever the door does not know what is left: message 77 says that may be most rows),
   "Stopped by you", "Ended for good", "Not possible", "Cannot be read now"; and in the program today every row
   says "Not mirrored from here".
3. Line 20 "protected or not": a protection not known is shown as "no" (S8).
4. Line 21 the estimate: after a 202 the page says Telegram answered (S5).
5. Line 23 the chosen chats "the same, chat after chat": a stopped chat among them is started again without a word
   (M1).
6. Line 24 "Never mirror / Allow again: afterwards nothing": an allow that lifts an end or a block lets the mirror
   task go on sending (S6); the row does not show what it lifts.
7. Line 26 the blocked mirror: the page offers a third button the page does not describe (create-not-made); for a
   contradiction it offers "settle by the rules" instead of the two choices (M3); the buttons are not the
   command's words (S7); "a word given for a batch that no longer blocks is dropped and said" cannot hold with a
   word that names no batch, and the page has no place where "dropped" is said (M2).

Not the page's to make true, said so the owner reads it rightly: line 25 "Stop mirroring: nothing more for that
chat" holds only once the reader stops reading for an ended want (board messages 79 (b) and 81, not built).

## What must change at the conversion place (`livepages/mirrors.go` 40-253), and what a test must then prove

- The interface's returns become `mirror.Plan`, `[]mirror.ChatState` and the collector's `MirrorTask` as message 77
  names them. **Until they match exactly, `MirrorsOf` answers nil silently and the page stays disabled with no
  failing test.** Add in the collector package `var _ livepages.MirrorDoors = (*Collector)(nil)` (livepages cannot
  import the collector) and a test that `livepages.MirrorsOf(c) != nil` for a real collector.
- `convPlan`: the token from `Plan.Token()`; `Protected` known or not (S8); the batch's state for the settle words
  (S7); `AboutBatches`, the 24-hour numbers, `Minutes` only if the plan has them.
- `doorRefusals`: the mirror package's sentinels, and the ones the list lacks today: "already wanted", "not the
  account's chat" (both now answered as a failure of the record, with a log line), a settle word for a batch no
  longer blocking (M2).
- `doorWhyStopped`: the mirror package's stop word, better a `Stopped` field in `ChatState`; else a stopped chat
  whose word differs shows "Ended for good" with "Allow again".
- `offersOf`: M3 now; better the offers from the door itself.
- Tests then: every sentinel the doors can return maps to a refusal (table over the package's exported errors); a
  token of chat A is refused for chat B and for another account with the same numbers, and after a never, a stop
  and a block; a stopped chat is `Stopped`; for each block word the offered words are the ones the command accepts
  for it; a settle word for a batch no longer blocking is refused at the click; on the fake Telegram, one want
  through the page leads to exactly the requests the plan's list named, by method and count.

## What I checked and found sound

- No text becomes markup: `dom.js` makes every string a text node; titles, the prefix, refusals and reasons go
  through `text`/text nodes or attributes only; keys are numbers and server words, looked up with `CSS.escape`.
- All 10 routes are behind the guard (host, cross-site, token and origin for POST), `no-store`, POST for every
  change, 405 for the wrong method; unknown fields are refused, so a list of chats is not understood; an empty or
  missing token is refused before the door; a missing, empty or unknown settle word likewise; a removed or unknown
  account is 404; no seam: all 10 routes 404 and the page says why.
- Logs: only fixed words with the route and the error's type; refusals, titles and the prefix never logged.
- The own click is seen at once: the guard's `markDirty` before and after every POST moves the change count, and
  the next poll asks the door again (probe `TestReviewG4OwnClickSeenAtOnce`). "As of" is the reading's own time.
- The yes: the token of the plan shown; a moved plan refused and the plan on record shown (when it can be read);
  the button disabled from the click until painted; a double click is one request; the chosen chats send each
  shown plan's own token, in order, stop at the first refusal, at most 20.
- The demo: the fake is made only when `Demo` is set and has no catalogue handle after its one read; the guard's
  exemption is tied to it; every mirror route in the demo left the catalogue file's bytes unchanged (probe
  `TestReviewG4DemoEveryRouteCatalogueUnchanged`, 7 change routes plus the reads).
- `MirrorsOf` returns an untyped nil (a true nil interface) when the collector lacks the doors; the placeholder
  sentinels are fresh values nothing returns, so they match no real error; refusals are matched with `errors.Is`.
- The unreadable gathering is never "at once"; a failed settings read shows an error, not values.

## Cost of an open Chats page with 2,000 chats (statements; the door's side not built)

Per `GET /api/mirrors`: 5 to 6 statements of the server (the change key and the accounts; measured by the branch's
own test), one `Task` per account (not kept), and `States` per account at most every 5 s while the catalogue
changes, every 15 s when quiet. The Chats page polls every 5 s, and its own list refresh (when the chats' key
moved) loads `/api/mirrors` again: up to 24 answers a minute, about 120-144 server statements, up to 24 `Task`
calls and at most 12 `States` calls a minute per account; each answer carries every state (about 300 KB at 2,000
states by my estimate, not measured). The Overview adds 12 answers a minute. Asked of the door: `States` in a fixed
number of statements and `Task` cheap, as message 77 promises.

## What I did not look at

The pages in a browser (desktop and phone width, CSS, focus as seen, the region under the pointer); chats.js
beyond the diff; the real doors, the task and the reader (not built or not in this branch); whole-package and race
runs; the Settings page's behaviour against a real door.
