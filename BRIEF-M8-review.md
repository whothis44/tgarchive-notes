# Brief for the independent review of M8 (11-15 23:27, the mirror session M4)

You review one piece of a private Go application (a standalone Telegram archiver) that you did not write. You
are read-only on its tree: **you edit nothing in `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-protected`**.
Your own folder is `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review10-scratch`: probe tests go there
and are loaded with `go test -overlay` (an overlay JSON that places your `zz_m10*_test.go` files into the
package's folder without writing them there); your report is `REVIEW.md` in that folder.

**How to work: read `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-M7-review.md`, its sections "How to work" and
"Hand-back", and follow them here** (the same method, budget and report shape: each finding high, medium or
low, and CONFIRMED by a probe or PLAUSIBLE by reading; what you did not check, said plainly). Go commands:
`source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, `GOGC=25 GOMAXPROCS=2`, `-p 1`, one
at a time, named tests only (`-run`), never a whole package, no Docker, no race detector; measure the PC
before each (under 2 GB free or over 85% CPU: wait). Nothing runs against Telegram; never start any program
outside `go test`; never open a real catalogue, log or media file. No chat name, message text, id or link in
your report (it goes into pushed documents: no path of this PC in it either, say "the copy" and "the scratch
folder").

## The piece
The tree: the worktree above, branch `wip/mirror-protected`, the range `f2cedf18..cd4a6c95` (the commit
0040495d in it is a one-line test fix from another branch: not yours to review). What was asked:
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-M8-protected-and-lows.md`. What the coder says it built, its
five departures and its 24 one-line mutants: `archiver/docs/progress/mirror-protected-REPORT.md` in the tree.
In short: (A) the owner's `mirror -chat` plan and (B) the automatic mirror refuse, before any request, a chat
the chat list says is protected (`chat.protected`, read through a new door `MirrorSourceProtected`), and say
"not known" where the flag is not known; a count `Gathering` for a want whose batch the gathering holds; (C)
nine small fixes from an earlier review (the text check of a name rule, `BaseFor`'s trimming, the settle's
lost-row rule, a rename's outcome words, flags refused beside `-never`, `-allow`, `-list`, two plan lines).

This code acts for the owner on Telegram. The rules it must keep: one request at a time, never repeated by
itself; the owner's "never" mark and the protected check read before every request; fail closed on a stored
value that cannot be read (never "not protected", never a default); no request for an item that will never be
acted on; an unknown outcome said, never guessed.

## Attack these, and anything else you find
1. **Any request for a chat known to be protected.** Every path: the command's plan, the step after the yes
   (`Run`, `ReadThenRun`, `Estimate`), the settle (`-settle`), the automatic task (`Look`'s take with its read
   approval, `autoCheck`, the create, the forward, the settle's own read of the mirror chat, the config
   request). Count requests on the packages' fakes: the answer must be 0 for the source, and no approval of
   its read, no want, no create intent may be written. Also the flag flipping at each point between two
   turns and between the plan and the yes.
2. **A door error, a missing chat row, a NULL, or an older read-only file read as "not protected"** anywhere;
   and the opposite fault: one chat whose door fails starving every other chat for good (`Look` returns the
   error for the whole look: is that the existing path for its other reads, and does a later look recover?).
3. **`mirror -allow` while the source still says protected:** ended again at 0 requests each time; does it
   log or write one more line or row every turn without bound?
4. **The stored name rule.** A rule the OLD check allowed and the new one refuses (an odd character, a
   separator ending in a digit): does it still read back (`ReadNameRule`), still name a new mirror, and is it
   refused only when written anew? Every caller of `CheckNameRule` against `checkStoredRule`: is any stored
   path on the stricter one, or any new-rule path on the laxer one?
5. **`BaseFor`'s trimming and mirrors begun before it.** A create left "creating" or "unknown" under the old
   code and looked for by its intended name after the upgrade (`MirrorLostChats`, `MirrorNameOnRecord`, the
   command's `-create not-made`): is the name read from the stored row, or computed again with the new
   trimming (then the lost channel would not be found and a second one could be made)? Probe it.
6. **The settle's widened lost-row rule (N4).** Can it now turn a settle that the rules decided before into
   "cannot tell" in an ordinary case (an earlier missing message that is deleted, or one with no media row),
   or change the outcome of the case that ran for real (a batch of 99: 64 found by the post each forward
   names, 1 by the same media, 34 not arrived, none [name removed])? Build that case and compare before and after.
7. **The `Gathering` count changes no time.** With the earlier review's probes if they still build
   (`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review9-scratch`, `zz_m9probe_test.go`, `zz_m9b_test.go`:
   read-only there too): the turn's wake and the moments of every request are the same on f2cedf18 and on
   cd4a6c95 for the same inputs.
8. **The flags now refused beside `-never`, `-allow`, `-list` (departure 5: the VPN and key flags too).** Read
   (do not run) the owner's scripts `C:\Users\trabi\Claude\Projects\Telegram\a3\a3-mirror.ps1` and
   `a3-auto-mirror.ps1`: does any of them pass a flag that is now refused with one of these modes?
9. **Words and logs:** no name, title, text, id or link in any new line, error or event; format strings
   constant; the new plan lines true in each of their three forms.
10. **The tests:** pick 6 of the report's 24 mutants yourself, undo each line by overlay, and see the named
    test fail; look for a test that stores its case as no real path does (the earlier timing review found
    one).

## Hand-back
`REVIEW.md` in your folder, and your final message: the verdict in one line (may be listed / may be listed
after these fixes / not yet); the findings most severe first with file and line, each CONFIRMED or PLAUSIBLE
and its probe's name; what you did not check.
