# Brief for the independent review of M6: adopting a chat of the owner's as a source's mirror (session M-6, 11-16)

**Head under review: `wip/mirror-adopt` 44c6a3f7 (six commits on the main head 2b557601; 26 files, +3,258 −55).**
The frozen copy is `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review15-tree` (detached at that head);
your own folder is `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review15-scratch`.
For one Opus reviewer (high effort), who did not write the code. Read-only on the frozen copy; findings are
proved by probe tests in your scratch folder loaded with `go test -overlay`, never by editing the tree; each
finding is marked confirmed (a probe shows it) or plausible (by reading). Named tests only, a `-timeout` on
every line, no whole run of `internal/catalog` or `internal/collector`, no race detector, no Docker. **Every go
command goes through the track's lock script, never directly** (it takes a lock, waits for 2,000 MB free and
runs one go command at a time for the track; it may wait many minutes: run it in the background and read on):
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-mirror-m6/go1.sh /c/Users/trabi/Claude/Projects/Telegram/wt-mirror-review15-tree/archiver go test -overlay <your file> -run 'TestName' -timeout 20m ./internal/catalog/`.
Nothing against Telegram. Counts, sizes and timings only in what you write: never a name, a text, a path of
the owner's or a Telegram id.

**Known already, from my own read of the weigh and the record (do not spend probes on proving them; do say
if you see more of the same kind):**
- (K1) **A copy deleted from the chat since the chat was last read is still "there".** The command's read of
  the chat is a pass of what is newer than what is stored; the weigh takes the chat's messages "not known
  deleted"; nothing asks Telegram whether a copy stored by an earlier read still exists. For a chat read for
  the first time by this command the evidence is exact; for one read earlier it is not. The fix round
  confirms the copies by id lists before the record.
- (K2) **The owner's word (`-adopt N -take arrived`) writes a batch row while a batch of the mirror may block**
  (sending, unknown, already): the settle then finds "a batch after the blocking one" and answers
  `ErrBadLedger` for good. The fix round refuses the word while a batch blocks.
- (K3) `internal/catalog/pairword_test.go` line 75 asserts that the copies track's step is the newest: the
  integrator's line at the merge, not this piece's.

**Read first:** `BRIEF-M6-adopt-chat.md` and `DESIGN-M6-adopt-chat.md` in the project folder; the coder's
`archiver/docs/progress/mirror-adopt-REPORT.md`; the head comment of `internal/catalog/mirrorsettle.go`;
`archiver/docs/TRIED-BEFORE.md` sections 24 and 25. **Read the code around the difference, not only its changed
lines:** the last piece's one high defect sat in a reader the difference did not touch.

**What this code decides:** which messages of a source are forwarded into a chat the owner filled by hand. A
wrong "there" is a hole in the owner's mirror; a wrong "not there" is a second copy in it; anything written to
the owner's chat's record that makes it "the app's own" takes a choice away from the owner.

**The questions, each to be answered with a probe where one is possible:**
1. **A wrong "there".** Any pair of a source message and a chat message the weigh ties that are not the same
   post or the same media: a sender-only origin; a repost inside the source and its original; two source
   messages with one media; an edited source; an alternative or a live photo's video on one side; a copy
   tied to two source messages; a deleted message on either side; a source that is a group, not a channel.
2. **A wrong "not there".** Any source message called "not there" while a message of the chat shares any media
   row with it or names its post.
3. **The weigh against the settle.** Take the settle's own test cases (its rules 3 and 4) and put the same
   messages through the adoption's weigh: every difference in the answer, and whether the brief names it
   (it names two: "twice" by origin is "there"; "not there" looks at every message of the chat).
4. **The record's transaction.** Anything written when a refusal holds at the second look; the counts changed
   between the owner's yes and the write; two commands at once; a crash between the record and the run; the
   record written twice.
5. **What must not be written:** `chat.mirror_of`, the chat's download switch, a `c_chat_made` row, a name by
   the name rule, a number taken from the app's names. After an adoption: the owner's switch works on the
   chat, the client may write to it, the next app-made mirror has the name it would have had.
6. **An adoption is no request and no create:** the pause since the account's last write, the bound per hour,
   the cap on new mirrors, every count of requests: the same before and after. Find every reader of
   `c_mirror`, `c_mirror_batch` and `c_mirror_forward` yourself and compare with the report's list.
7. **Nothing automatic adopts, and nothing automatic touches an adopted mirror without `-keep-current`:**
   requests counted over the automatic task's turns, the switch on, with and without the flag.
8. **A refused post into the chat:** how many forward requests leave after it, over several turns and a
   restart; what the owner is told.
9. **The waiting messages:** never candidates until the owner's word; each word's effect; a word given twice;
   a word for a mirror that is not adopted.
10. **The settle on an adopted mirror, and on an app-made one:** `adopt_top`; a message of the chat that the
    batch does not explain, with and without a shared media row; every existing settle test unchanged, and
    one result compared before and after on an app-made mirror by your own probe.
11. **The 13 rules** (never undo a person's stop or mark; a "never" checked again before every request; waits
    stored and checked at the top of every step; one row per item; a mark follows a migration; fail closed:
    an unreadable row or mark stops the step and never reads as empty).
12. **The schema step:** a file older than it on a read-only handle; the step applied twice; an older build
    on the stepped file.
13. **At size:** the weigh's seconds at 50,000 by 50,000 by your own run of the coder's test; any statement
    without an index.
14. **Planted changes:** take out one rule line at a time (ten of your choice, the weigh's and the record's
    first) and say which planted change no test catches.
15. **Tests removed or renamed** against the base; privacy of every new log line and test name.

**Your result:** `REVIEW.md` in your scratch folder: one line at its top ("may be listed", "may be listed after
these fixes", or "not yet"), then the findings by weight (high, medium, low), each with its probe's numbers,
then what you checked and found sound, then what you did not run.
