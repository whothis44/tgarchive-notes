# Review of follow-up 7 (C32's N1), 11-22

First review (independent Opus): one logic error: the reversed edge was written for pairs whose lengths differ up to
a quarter (a frame match's "same footage"), holding the longer copy behind a shorter one lacking footage; rung 6
holds only within lookalike.DurSlack (500 ms). Readers of copy_edge, cycles, the test's reach and the pictures' door
(no change needed) checked and found right. Fixed: the branch needs the lengths within DurSlack; tests 61.1 s vs
60.9 s (probable), 75 s vs 60 s and 501 ms apart (related).

Second review (the fix only): no logic error. One older point outside this item: the door's first branch
(Covers(better, lesser)) has no length check either, so a copy with more pixels up to a quarter shorter can hold the
longer one; left for the copies track (it changes which file is held: a review of its own).
