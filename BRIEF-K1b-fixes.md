# Brief K1b: the review's fixes for "files only from chats the owner chose" (core, 2026-11-15)

Same copy and branch as K1 (`wt-core-chosen`, `wip/core-chosen`, head 1a25071), same rules, same commit and
push form. The independent review is `C:\Users\trabi\Claude\Projects\Telegram\wt-core-review-scratch\REVIEW.md`:
read it in full; its probes are in that folder (take each as a named test of its package, renamed, never by
overlay). It confirmed nine defects. The decisions below are the main session's; build them as written and say
in the report where one cannot be built so.

**Not in this round (it follows as K1c when the integrator has merged the mirror's branch into the main
branch):** taking the new main head in, the review's P3, and the `released` column's real test. Do not merge
any other branch into yours now.

## The model, corrected (review C1, C5)
The first build let every caller of `SetChatCollect` write the row that says "the owner switched this". No
owner's command calls it: only programs do. So:
1. **Only the owner's own doors write an owner's record.** `SetChatCollect` as programs call it (the mirror's
   read, the mirror's create, the bring-in, a schema step) changes the switch, settles the files, and writes
   **no** owner's record. A new door for the owner's hand (say `OwnerSetChatCollect`) writes it: "on" or "off",
   with the time.
2. **"Nobody chose it"** is: switched off and no owner's record. "The owner switched it off" is: an owner's
   record "off". Nothing else. A chat a program switched off (the mirror's read of an unknown chat) is
   therefore "nobody chose it", and the owner can choose it.
3. **A way to choose that needs no request and no read:** a collector command `choose` (`-chat N` switches the
   chat on as the owner's choice and settles its files; `-off` is the owner's "off"; `-list` shows what
   `chats` shows about collecting). It follows the other owner commands' rules for a running collector (read
   how `approve` and `exact-mode` do it; do the same). It works for every chat: one with a read cursor and no
   approval, one approved by the mirror only, one whose approval record cannot be read, one made under
   `-new-chats-download`, one on a brought-in catalogue. The owner's explicit `choose` always wins, also over
   an earlier owner's "off".
4. **An approval of a read chooses the chat unless the owner's record says "off"** (approving a read is not
   asking for downloads against one's own "off"). **The choice is made first and in the same transaction as
   the approval** (review C4): a failed choice leaves no approval, and the words say what happened.
5. The pages will call the owner's door (`internal/server/chats.go`: the least lines; the page's "collect"
   control is the pages track's, not yours).

## The baseline (review C2, C6, C8, P1, P2)
6. **Its done mark is written after its settle has finished, never before.** Pending chat intents are finished
   at every start, before any account's task starts. An ended context is a stop: said as a stop, nothing
   marked, the next start goes on where it was (review's probe: 950 of 1,200 files still wanted).
7. **It leaves a chat that shows the owner's hand in any stored way:** an approval of the owner's from any
   account, an owner's record, a rank, "always download", chosen topics or "topics only", kinds changed from
   what a new row has. Such chats are counted and left collecting.
8. **Only an approval record that cannot be parsed leaves its chat** (counted); any other error reading ends
   the baseline unmarked, to be run again at the next start.
9. One line before it starts work (chats to switch off, files to settle), one after (done, counts, seconds):
   constant words, numbers. On a catalogue the bring-in wrote it still does nothing, and says each start how
   many collecting chats have no owner's choice on record.
10. A chat made while `-new-chats-download` was given gets an owner's record "on" (the flag is the owner's
    word for those chats), so no later baseline switches it off (review P4).

## The settle (review C3, C7, C9)
11. **A file set aside by the engine with a retry time, in a chat that is switched off, does not come back
    wanted.** At a switch-off the settle holds such set-asides too (not a file the owner set aside or sent
    back by hand); and a file in transfer at a live switch-off, when it is released back, is held if no chat
    that carries it collects it (one indexed read at that release; measure it; the claim path's own statements
    are not to get slower: say what you measured).
12. **A chunk stays bounded when one file has thousands of carriers in other chats** (the review measured a
    1.96 s write with 6,000): the chat settle's own statement, without the first-carrier test; the topics'
    statements are another track's and stay. Test with 6,000 carriers: longest write under 150 ms, judged by
    rows stepped or statements counted as well as the time printed.
13. Deleting a space removes its per-chat records (C9).

## Words and tests (review P5, P7, "tests that cannot fail", question 6)
14. Every sentence the review lists as no longer true is corrected (`mirror`'s help and end line about a chat
    switched on later; "sends nothing by itself"; `run -h`; the automatic mirror's counts say what they count).
15. **The default path gets real tests, not only the new ones.** Keep the rig's flag where a test is about
    something else, but add, under the default (no flag): an end-to-end download of an approved chat; the
    approved read of a chat whose row does not exist yet; the mirror command's read of an unknown chat followed
    by the owner choosing it (review C1's probe); `-auto-mirror-download`; kill and restart. Replace or fix the
    four tests the review says cannot fail for what they claim.

Rules as K1's: no schema step; no request to Telegram added, moved or removed; no goroutine, timer or lock;
constant words with numbers in every log, error and count; invented data only; named tests only, one go
command at a time (the PC is near its limit), no whole-package run, no race detector. Each fix shown failing
its test when undone. Append a section "Review fixes" to `archiver/docs/progress/core-chosen-REPORT.md` (each
item: what changed, its test, its mutation; what was done differently and why; what K1c still has to do at
the merge). Hand back commit-ready and pushed.
