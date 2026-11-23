# Review of the sign-in fix of 11-23 (wip/fix-signin), two independent Opus passes

## First pass (01510923..60074c6d)
One logic error: a cancel ended a sign-in waiting out a stated wait whose record write had failed (the wait held
only in the sign-in object), so a Start again could send auth.sendCode inside a FLOOD_WAIT. Minor: ResendCode did
not hold the pages' begin lock (a resend after the stop was asked; a hold's end shown too early); "Send a new code"
stayed on when Telegram named no next way (a wasted request each time); a cancel of every sign-in (account 0)
accepted at any time; resend_after a large negative number when unknown. Checked and right: no request without a
click, double clicks held off, a FLOOD_WAIT stated on a resend recorded and honoured, cancel sends nothing, an old
sign-in's connection always ended, the gate asked at every dial, resend refused during a held stop, new words
inserted as text.

## Fixes (60074c6d..2d046951)
RecordWait before a cancel ends a sign-in in a stated wait (a failed save keeps it and refuses the cancel);
ResendCode under the begin lock's read side; ErrSignInNoNextWay before sending and the button off; account 0 only
during a held stop; resend_after 0 when unknown; StopHeld reads the hold's end whenever a stop is asked and
ForceStop has not decided.

## Second pass (the fixes only)
The fixes are sound: no request inside a stated wait or without a click, no deadlock (beginMu read side only, the
stopper takes its write side without the sign-in lock), never a held program without its bar. Follow-ups outside
this change, listed for the next run: the NAS's cancel (nasdl) and the stop's closeSignIns do not save a stated wait
first; the NAS's page resends with no next way; a hold's end shown early in one rare interleaving (the bar stays).
