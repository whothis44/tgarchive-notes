# Review NG: the NAS give-back and the NAS state's last fields on the pages (P7, 2026-11-22)

Read: `git diff 58abd9d7 a43fbd91` in full (server/nas.go, demonas.go, nas_ng_test.go, nas_test.go, security_test.go,
livepages/nas.go and its test, collector/pages.go), the collector's doors `NASStatus`, `nasHeldOf`, `NASGiveBack`,
`nasGiveBackUnreadable` (internal/collector/nas_doors.go), `workingOn`, `drive`, `nasWhy` (nas_link.go),
`nasctl.GiveBack`/`GiveBackInState`, `catalog.Release`'s doc, the pages' `nasBriefOf`/`readBrief`, the Overview's and
Accounts' callers, the held stop's `stopKeeps`, `loadAccounts`. Ran (through go1.sh, scratch copy
`wt-pages-review-ng-scratch` at a43fbd91, TEMP/TMP/LOCALAPPDATA/APPDATA under `Temp\p7-ngrev`, fakes only): the
piece's tests and the guard/held-stop/demo tests by name, plus an uncommitted probe `zz_probe_ng_test.go`
(TestZZProbeKeepUnderSlowNAS, TestZZProbeKeepConcurrent, TestZZProbeOfferWords); all passed. Lines below are on
a43fbd91 (the piece is not on af4ca40e).

## Findings

1. **SHOULD FIX: under a slow NAS the 5 s keep never serves, and the Overview and Accounts answers take 10 s per NAS
   account, every poll, each request reading on its own.** Confirmed (TestZZProbeKeepUnderSlowNAS,
   TestZZProbeKeepConcurrent). `nasBriefOf` (server/nas.go 1115-1136) takes `now` before the read and stores
   `nasKept{at: now}` (line 1133) after it; a read that takes 5 s or more is already older than the floor when it is
   stored. Probe, two accounts on the NAS, fake clock moved only by the reads: a 1 s read gives 2 reads over 3
   Overview polls (the keep works, 2 s then 0 s per poll); a 6 s read gives 6 reads and 12 s per poll; a 10 s read
   (the collector's bound, and the pages' `nasBound`) gives 6 reads and **20 s per poll**, every poll. There is no
   one-at-a-time: 4 Overview polls at once made 8 status reads, 4 in flight together. The accounts are read one
   after another (overview.go 241, accounts.go 100), each with its own fresh 10 s bound, so N NAS accounts cost
   N x 10 s; the Accounts list also reads removed accounts. How a person meets it: the NAS's link is up but the NAS
   answers slowly (busy disk, Wi-Fi), the Overview stops refreshing for 20 s at a time and the Accounts page hangs
   as long, with nothing on screen saying why. The code predates NG (N4P), but NG's report names this as its open
   risk and adds to it (finding 3). Smallest cure: stamp the kept row with the time after the read (or keep the
   answer for the floor from its end), and read one account at a time per seam behind a single flight (one read in
   flight per account; others take the last kept brief, marked "as last read"); a shorter bound for the brief
   (2-3 s) than for the facts.

2. **SHOULD FIX: a removed account's give-back is promised by the pages but refused by the real collector after a
   restart, in words that hide why.** By reading. The route accepts a removed account (server/nas.go 1282,
   `nasAccount(..., true)`; TestNASGiveBackRoute proves it only against the fake). The collector's `NASGiveBack`
   starts with `c.nasAccount` (nas_doors.go 385), which needs `c.account(id)`; `loadAccounts` (account.go 127-139)
   leaves removed accounts out of `c.accts` at every start, and nothing deletes them while it runs. So from the
   program's next start the door answers `ErrNASNoAccount`, which the lent mapping (collector/pages.go 806) does not
   map: the pages answer 500 "The NAS step could not be done: nothing more was sent; try again." The facts for that
   account fail the same way (its `NASPlace` refuses first), so no offer is shown either, and the Accounts list shows
   its NAS as "cannot be read" on every poll with a log line each time. How a person meets it: the owner set the
   account back to this PC, its NAS was gone (so `nasRemoveBlock`, which looks only at the pairing and the NAS's
   sign-in, let the removal through), restarts the program: the files that NAS held of the account stay claimed and
   can never be given back from the pages. Smallest cure: in the door, let `NASGiveBack` (and `NASStatus` for the
   held count) take a removed account (a catalogue check instead of `c.account`), as the forget's route already
   intends; and map `ErrNASNoAccount` to fixed 404/409 words; or, if removed accounts are not to be served, refuse
   them in the route too and block the removal while `Held > 0`.

3. **SHOULD FIX: the facts of an account on this PC now read the NAS over the link (up to 10 s, with side effects on
   the contact record), and still miss the case the door's F1 was built for.** Confirmed for the read
   (TestZZProbeOfferWords, "pc place: 1 status reads, 10 fake seconds"); the rest by reading. server/nas.go 745-755:
   with the place "pc" and the pairing kept, `GET /api/nas` calls `NASStatus`, which (nas_doors.go 328-342) does a
   live `StatusNow` and a sign-in status over the link when it is up, and calls `contactOK`/`contactFailed`: a
   page read of an account that downloads nothing there now moves `UnreachableSince`. Yet an account whose place
   names a different, unpaired address (the owner typed a new NAS address with "pc", nas_doors.go 149-156) is never
   read (`paired` false), although the collector's `Held` counts every NAS folder (`nasHeldOf`, 353-361): the files
   an old NAS holds are shown nowhere and never offered. Likewise with the place "nas" on a new reachable NAS B
   while an old NAS A no place names holds files: `Held` counts A's files under B's words ("The NAS holds N
   file(s)"), and no offer (B answers), though the door would give A's back. How a person meets it: after moving to
   a new NAS address, the old one's files stay held with no button; or the facts page of an account on this PC
   takes 10 s when the old NAS is slow. Smallest cure: read the held count without the link (a door that returns
   `Held`, `StateUnreadable`, `UnreachableSince` from the folders only, no `StatusNow`), call it whatever the
   pairing, and offer the give-back on `Held > 0 && (the place's NAS does not answer || the files are of a NAS the
   place does not name)`; if that is the door's part, list it for the NAS track.

4. **MINOR: the offer can say "holds 0 file(s) of this account" and the after-note overstates.** Confirmed
   (TestZZProbeOfferWords: held 0 with the record unreadable gives "The NAS does not answer and holds 0 file(s) of
   this account. Give the NAS's files back: ... of any account."). server/nas.go 1257: with an unreadable record
   the count is not known (the collector's `nasHeldOf` skips the unreadable file), so "holds 0" is false comfort
   before a step that gives back files of every account. After the click (1291) "they are wanted again on this PC"
   is not true of every file: `catalog.Release` holds a probable copy again (state.go 294-296), and the count
   includes other accounts' files in the unreadable case (only `in.Account`'s brief is dropped). Cure: with
   `StateUnreadable`, say "an unknown number of files, of every account on that NAS" instead of the count; after:
   "N file(s) given back to this PC's queue (a probable copy waits behind the unique files, as always)".

5. **MINOR: the offer appears from the first failed contact, and its words never say it is for a NAS that is gone.**
   By reading. `nasHeld` (server/nas.go 1256) offers whenever `Reachable` is false; the collector sets that on any
   failed `StatusNow` (a 10 s timeout) or while a redial waits out its back-off (up to `NASRetryMax`). The NAS keeps
   its files in hand while the link is down (TestNASSwitchWhileAway), so a click during a blip is the
   double-download case. The pages' `NASGiveBackWords` (1214) do warn "may download twice", but drop the collector's
   own premise ("This NAS is gone: ...", collector `NASGiveBackWords`, nas_doors.go 365, now unused), and the two
   constants of one name differ. Also: a NAS whose link is up but whose status timed out is offered "does not
   answer", then refused with "That NAS answers and works for this account" (the door looks at `ctl.Up()` and the
   last status, nas_doors.go 411): the two words contradict. Cure: lead the offer with "Only if that NAS is gone or
   broken for good:", show since when (already in `unreachable_words`), and consider offering only after the NAS
   has not answered for some minutes; word the 409 "That NAS's link is up and it was working for this account at
   its last status".

6. **MINOR: the lent commit's comment is stale.** By reading. collector/pages.go 784-785 still says the five fields
   "which the pages do not take yet", above the code that now hands them over. The commit otherwise does only what
   it says (see below).

## Checked and sound

- The `yes` flag: without it a 400 whose `yes` field gives the words, and no door is called (TestNASGiveBackRoute:
  0 calls before the yes).
- A request from elsewhere: the route is in the guard's write list and program-only (TestNASRoutesInGuardLists,
  TestMutationsRefusedFromElsewhere pass with it).
- The held stop: `/api/nas/giveback` is not in `stopKeeps`, so `changeRoute` refuses it; TestNASHeldStop passes and
  no "giveback" reached the doors.
- The demo refuses the route (TestNASDemo* pass; the fake's give-back clears nothing in the demo).
- A replayed click: the second call finds nothing held and answers "Nothing was given back" (no second release);
  the door holds `opMu`, so two clicks at once are one after the other.
- The NAS working: the door refuses only when the link is up, the account started there, the last status read and
  `Working`; `ErrNASWorking` is mapped through livepages to the pages' fixed 409 words (TestNASLastFieldsAndGiveBack,
  TestNASGiveBackRoute). A stale page's click after the NAS answers again but does not work for the account gives
  back over the live controller (the NAS is told, its parts dropped): no double download from that path.
- The five new fields: `why` goes through `nasFixed` (digit runs and control bytes refused, prefixes trimmed); the
  collector's `Why` sources are fixed words (`nasWhy`, "not linked", "no NAS address is set"); no address, path or id
  in any of the new fields or words; `state_unreadable` and its since are said in words (`state_unreadable_words`).
- The facts' own read is bounded: one `nasBound` (10 s) for the whole `nasFacts`, the collector's 10 s inside it.
- The lent commit a43fbd91: one file, the five fields copied, `GiveBack: c.NASGiveBack`, `Working: ErrNASWorking`;
  nothing else changed. `NASOf` returns nil when the new door is missing (tested).
- "Each starts again from 0 here" is true of the door: the NAS drops its parts of files given back over a live link
  (`DropParts`; one given back offline keeps its part on the NAS until the NAS program's next start), and the PC
  starts it afresh.

## Not verified

- The collector's real give-back and status against a NAS (fakes only; no collector rig was run for the removed
  account of finding 2: by reading).
- How the front end polls (whether a 20 s Overview answer stacks polls): no front end in this piece.
- Whether a `StatusNow` timeout closes the link (which would end the slow-NAS case after one read).
- Ran and passed besides: TestNASRoutesInGuardLists (server), TestNASSeamOverDoors, TestNASStatusAwayKeepsState,
  TestNASLastFieldsAndGiveBack (livepages), TestPagesNASWired (collector). The probe file is uncommitted and left in
  the scratch copy only.
