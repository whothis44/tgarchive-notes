# Brief M9b (FINAL, 11-16 00:18, the mirror session M4): what pages and Core asked of the door, and three points of your report

Your hand-back (e57adb3f) is read. Its independent review runs now on a frozen copy of e57adb3f; its findings
come to you afterwards as a third, small round ("M9c"): do not wait for it. Same copy (`wt-mirror-door`), same
branch, same house rules as `BRIEF-M9-mirror-door.md`. For this round you may also edit
`internal/collector/mirror_marks.go` and `mirror_settle_cmd.go` (both the mirror's own). Decided, from the
board's messages 81 to 84 (pages and Core) and from your report:

0. **Merge the main head in first** (29bcfa2e or later on `private`: it holds K8, Core's request layer; the
   mirror shares `internal/telegram/memo.go` with it). Conflicts in files that are not the mirror's: stop and
   say. Build and vet after it.
1. **A settle word names the block it was chosen for (pages' review, a must-fix).** `ChatState` gains
   `Block string`: an opaque token of the block on record (the mirror row, the blocking batch's id or the
   create's intent, and the block word). The doors become `mirror.SettleWord(ctx, ..., account, chat, word,
   block string)` and `(*Collector).MirrorSettleWord(ctx, account, chat int64, word, block string) error`:
   refused with a sentinel in fixed words, nothing written, when the block on record now is not that one
   (read in the same transaction as the write). The stored word keeps the block it was given for, and the
   task applies it only to exactly that block (as built), else removes it and says so. Tests: a word given
   for block A after the mirror moved on to block B is refused at the door; two tabs: the second click with
   the old token is refused; the token is the same across two readings while nothing changed.
2. **The offers are the door's to say.** `ChatState` gains `Offers []string` (which of `by-rules`, `arrived`,
   `not-arrived`, `create-not-made` may be given now; none: empty) and `Stopped bool` (ended with "stopped by
   the owner"); the field `Choice` goes. One function in `internal/mirror` maps a block word to its offers,
   read off the command's own paths (what `mirror -settle` does for each block word, with and without
   `-take`, and `-create not-made` with its condition): the door and the task both use it, so a word the door
   offers is a word the task can carry out. The pages track's table (board message 83 b of pages) is the
   expectation; where the command's code says otherwise, the code wins and the report says where. A test per
   block word.
3. **An allow does not undo the owner's stop.** `MirrorAllow` leaves an end of `MirrorEndStopped` in place (want
   and mirror row); only `AddOwnerMirrorWant` clears it. Tests: allow after a stop changes nothing for that
   chat and says 0 cleared; a mark on the same chat is still removed by the allow.
4. **`(*Collector).MirrorCheckNameRule(prefix, sep string) error`**: `mirror.CheckNameRule`, its fixed words.
5. **An account that is not signed in on record:** every door refuses it in fixed words and the task runs no
   turn for it (say in the report what each reads today; add only what is missing).
6. **Your departure 1: `mirror -list` says who started each want** (`mirror_marks.go`: `w.By` in fixed words:
   "asked for by the owner" or "taken by the automatic mirror"); a test.
7. **Your departure 2: one condition, not two.** The rule "the chat list was stored after the create plus the
   margin, and holds no channel of the mirror's name" lives in one function of `internal/mirror`; the
   command's `notMade` (`mirror_settle_cmd.go`) and the task's `chatListAfterCreate` both call it. The
   command's behaviour and words do not change (its tests pass unedited).
8. **Your departure 10: the state says what the door will do.** `ChatState.Never` is true when the mark is on
   the chat or on a chat its migration links it to (the rule `MirrorMarked` and `Want` use), still inside the
   fixed number of statements; say the statement count as built. `Left` stays "media only" and its comment
   says so (the page's words are the pages track's).
9. Accepted as built, no change: your departures 3 to 9 (a chat nothing knows is switched off for downloads,
   as the command's default; plans blocked only for a while are accepted; the fits rule of each word; the cap
   counting every starter; automatic wants waiting for the switch).
10. **Not here (a piece of its own after Core's round is merged):** the read approval's "ended" mark when a
   want ends (board messages 79 b, 81, 84 e).

Named tests only; at the end the brief M9's end-of-work runs once more, full output kept; a section "M9b" in
the report; the final list of exported names and collector methods at the top of the report, as built, for
the pages track's conversion place.
