# Independent review of N4, the NAS downloader's PC side (wip/nas-pcside 1348c3db against 59388917; 2026-11-22)

**Verdict: may be listed after these fixes: F1 and F2 (both must, both CONFIRMED by a probe); F3 should go with them.**
The rest is should/minor. The things the brief asked about most do hold under probes: start-up recovery with
the NAS up, down or gone; a NAS finish made while the PC was down (probe C); a switch to the PC while the link is cut and
the NAS goes on (probe D); the doors' privacy; the shared dialler. The two musts are both about one gap: the PC keeps a
NAS's files active, but in two cases it never gives them back. Neither case can lose a file or download one twice, but
both leave files held for ever with no way back (F1), or stop the whole collector (F2).

Read for it: NOTE-N4-collector-side.md, DESIGN-NAS-downloader.md sections 1 to 3, DIGEST-LESSONS.md, the whole difference,
and `internal/nasctl` (nasctl.go, apply.go, serve.go, program.go) and `internal/nasdl` (program.go work/onStart, settings
away_stop) where the difference calls them. Scratch copy `wt-nas-pcside-review` (detached at 1348c3db). The probes were
one uncommitted test file there. The copy has been removed.

## Findings

**F1 (must, CONFIRMED, probe A). A NAS's files are held for ever once no account's place names its address.**
`nas_link.go` 403-413: a link is kept for its state file's files only for addresses in `byAddr`, which is built from
the accounts' current places. Suppose an account moves from "nas X" to "nas Y" or "pc Y", or is removed. X's link then
ends (with a Stop when it is up) and is never dialled again. Its state file still holds the grants. `nasHeldAtStart`
(314-336) reads every `nas-*` folder, so every later start keeps those files active as well. Nothing gives them back,
and no page shows them. Probe A: three files in X's state file, the place set to "pc" at another address, the NAS up at
X and holding none of them. After 6 s: 3 of 3 still active, 0 dials. After a restart: 3 of 3 still active.
The coder's own "up" case gives them back within seconds. **Fix:** record each folder's address in the folder (a small
`addr` file next to `link.state`, since the folder name is a digest). In `turnLocked`, link every recorded address
whose state file holds files, with the grants' accounts as its `Accounts`, whatever the places say now. The owner's
"give its files back" step and the `nas.holding` alert (point 2 below) must cover these addresses too.

**F2 (must, CONFIRMED, probe B). One unreadable NAS state file stops the whole collector before it runs.**
`collector.go` 811-830 with `nas_link.go` 327-330: `errNASStateUnreadable` fails the start-up recovery. The recovery
is retried for ever (doubling to a minute) before `c.cat` is set (858). Until then no account reads, no mirror runs, and
every door answers "not running", so no page can show or fix it. Probe B: a truncated state file. After 15 s wall
(minutes of the fast clock) the collector was not running, 10 "start-up recovery failed" lines were logged, and
`NASPlace` answered "collector: not running". The only way out is deleting the file by hand. Doing that gives every
file back while the NAS may still be writing them for up to its `away_stop_minutes` (1 to 10080; `nasdl/settings.go`
211-216). This is "fail closed" for every account and every task, not just that NAS's files, and it is stuck for ever.
**Fix:** on an unreadable state file, keep active every active file of the accounts whose place (current, or the
address recorded under F1) names that folder. Give back the rest, run, and log it with a constant line and an alert.
Leave that address unlinked (nasctl already refuses it) until the owner's step settles it.

**F3 (should, PLAUSIBLE, by reading). A passing catalogue error in the NAS task's turn is treated as an unreadable
place.** `nas_link.go` 386-392: any `readNASPlace` error other than a cancelled context leads to `sayBad`, which
unwants the account and logs "cannot be read". The account also drops out of `byAddr`. At 416-418 the link no longer
matches, so it is closed with a Stop and dialled again, and at the next hello the NAS drops the files it held for that
account (`adopt`'s `!c.acct` path). One busy moment of the catalogue therefore stops and restarts the NAS's work and
throws away its files in hand (no loss: they go back to wanted). **Fix:** as `placeNow` does (823-840), keep the place
last read on an error that is not `ErrBadNASPlace`, or skip that address for this turn.

**F4 (should, PLAUSIBLE). The redial after a lost link is fixed at 5 s for ever.** The `NASEvery`-to-`NASRetryMax`
doubling (`dial`, 494-508) applies only until the first link is made. After that, nasctl's `supervise` redials every
`RedialEvery` (default 5 s; the collector sets it only in tests), forever, while the NAS is away or refusing at hello.
That is a TCP dial plus a TLS handshake every 5 s for days. It is not a tight loop, and it is not what the Config's
words promise. **Fix:** give nasctl a doubling redial bounded by `NASRetryMax`, or close the controller after a few
failed redials and let the manager's doubling take over.

**F5 (minor, PLAUSIBLE). Sign-in steps are not refused without the place.** `nas_doors.go` 320-327 checks only that a
link for the account's address is up. A link is up for an account set to "pc <addr>" while that NAS's state file holds
files or another account downloads there, so `NASSignIn` goes through. The contract says "refused without pairing and
without the place". **Fix:** refuse the steps that write to Telegram (send_code, resend_code, code, password) unless the
place is "nas". Keep status, cancel and forget open. If signing in before the switch is wanted, write that into the
contract instead.

**F6 (minor, by reading). The local engine starts while a NAS may still finish the account's files.**
`workingOn` (156-165) needs the link up and, after a Stop, `setStarted("")`. So the local engine starts as soon as the
Stop is answered, or at once while the link is down. It does not wait for the NAS's releases. The catalogue's claims
keep the two apart: probe D had 11 files active at the cut and still 11 with the local engine running, and none was
taken twice. The doc comment "starts its local engine only once the NAS's work for it has stopped" says more than the
code does. **Fix:** correct the words, or accept and say it in the comment.

**F7 (minor, by reading; nasctl). A NAS's Saved is applied without a grant.** `nasctl/apply.go`'s MSaved checks the
lane's account but not `grantOf`. A finish for a file the PC also has active for the same account (possible only after
a state file was lost: F2's manual remedy) is recorded against the local claim. The local save then becomes a
`SavedAs`/duplicate. There is no loss, and the exact rules are unchanged, because the same file id is involved. Worth a
count ("saved without a grant") so it shows.

**F8 (minor, answer to Core's gap (a)).** It is not said anywhere in N4 that a file released by the NAS at a switch
starts again from 0 on the PC. A staging token ("S") from the NAS names a part only the NAS's disk has, so the PC's
writer restarts it (`store/writer.go` resume). The NAS's part stays in its staging until the NAS program's next start:
its writer sweeps once per program, `nasdl/program.go` 586-600. A library token ("L", a part the NAS wrote straight
into the library) names a path the PC also reaches over the share. The PC would then resume over the Wi-Fi with link
counts that are wrong on the share. That is PLAUSIBLE and not probed. **Fix:** say it in `nas_link.go`'s rules and on
the Accounts page ("files in hand start again on the PC"). Have the NAS remove a part it releases for a Stop, or tag its
tokens so the PC's writer never resumes one.

## The brief's points

1. **Recover at start.** Up, down and gone are right (the coder's test). A NAS finish made while the PC was down is
   right (probe C). Unreadable or corrupt: F2. Missing: every file is given back, which is the owner's doing. A state
   file of another NAS: `adopt` reconciles it at the hello. Of another catalogue: only if NASDir is pointed elsewhere
   by hand (minor). Place back on "the PC": handled while the address is kept (`SetNASPlace` "pc" keeps it, and the
   link stays while files are held). Changed address or a NAS gone for good: F1. The walk past kept chunks is right
   (`TestRecoverActiveExcept` passes).
2. **Place switch.** Mid-run in both directions it is right (the coder's `TestNASSwitchPlaces`; probe D with the link
   cut). An unreadable place builds no lane and is said (the coder's test). With `-no-downloads` no engine task runs,
   so nothing is wanted. A NAS set for an account is still dialled and told to Stop, and nothing starts. That is
   acceptable.
3. **Finished and Duplicate.** One finish, applied once by journal number (probe C: 13 entries, no file fetched twice,
   none restarted). `nasFinished` takes the NAS's done first, then the local writer's. The Supply keeps the done in
   `p.done`, so a retried record does not lose it. Only the same file or the same SHA-256 ends a file. F7 is the one
   edge.
4. **Doors.** One `MSignIn` call per click (nasctl `SignIn`). The phone, code and password are kept nowhere and logged
   nowhere (the coder's `noSecretsIn` over both logs). No user id is in `NASSignInState`. Refused without a link
   (tested). Not refused on place: F5. `NASStatus` with the NAS away answers the last state with Reachable false, its
   AsOf and its NO VPN (tested). The `SetNASPlace` rules match the contract ("pc" keeps the address; "nas" needs a
   pairing; addresses must be private, loopback or link-local). It holds `opMu` across a whole turn, so a click can
   wait about 35 s at worst on a dead NAS (minor).
5. **Shared dialler.** A faithful move of `dialer.go` into `libclient`, plus `NoUpdates` for the NAS. The hold is
   unchanged. The collector's dialler tests pass (below).
6. **Waits and status.** Turns every `NASEvery` (10 s) or on a change. The first dials double up to `NASRetryMax`;
   after a lost link see F4. The PC asks Telegram for the NAS only for what the design keeps on the PC: the exact
   check from the account's own session (`nasChecks`) and the reference refresh through the Supply. No NAS wait is
   slept on the PC's behalf or skipped.
7. **Copies' files.** With keep empty, `RecoverActiveExcept` runs the old query and `Supply.Recover` is
   `RecoverExcept(nil)`: exactly the old behaviour.

## Core's further points (K-6, from C7 and N-1)

- **(1) Judged path.** CONFIRMED by reading. `RecoverActiveExcept` gives files back only through
  `tc.giveBack(ctx, id, recoverSQL)` inside the same `c.Batch` per chunk, with `prepareGiveBack(ctx, recoverSQL)`
  first, as `RecoverActive` did. Kept rows are skipped inside the chunk and do not change the path. One correction:
  the chunk is `recoverChunk = 150` (since K17's review), not 250.
- **(2) A NAS that never returns.** The owner's step "this NAS is gone: give its files back" (warning of a possible
  double download), plus an alert `nas.holding` after a set time away, is enough, and nothing should be released
  without the owner. The PC cannot know the NAS's `away_stop_minutes` (up to a week), so an automatic release could
  hand out a file the NAS is still writing into the same library name. A late finish from that NAS stays harmless: a
  Release or Gone without a grant is stray, and a Saved records real bytes (F7). The condition: the step and the alert
  must also reach addresses no account names any more (F1) and an unreadable state file (F2). The alert must be raised
  from the state files at start too, not only from a live link.
- **(3) A finish made while the PC was down.** CONFIRMED right, probe C. 13 files were held at the restart and left to
  the NAS. The NAS sent 13 journal entries at the link. Every file was saved once, none was fetched twice, none started
  again from 0, and the fake recorded no rule broken. The finish is judged when the link applies it, not in
  `RecoverExcept`'s replay: that replay is the PC's own finish log. Until the link, the file stays active and is never
  handed out.
- **N-1's account of a switch to "the PC".** Confirmed with two corrections:
  - The local engine does not wait for the NAS's releases. It starts once the Stop is answered, or at once with the
    link down, and the claims keep the files apart (F6).
  - The link stays only while the address is still named (F1).

  Gap (a): F8. Gap (b): true; see point (2). The switch while the NAS is away and comes back is right (probe D):
  11 files active at the cut stayed active (not taken by the local engine) until the link returned. Then 3 entries
  were applied, the NAS's work was stopped, every file was saved once, none was fetched twice, none restarted, and the
  fake recorded no rule broken.

## Probes and runs (go1.sh, then go2.sh; named tests only; invented data)

| Probe | Result |
|---|---|
| A `TestProbeN4AddressChangeStrands` | kept files still active: 3 of 3 after 6 s, 3 of 3 after a restart; 0 dials (F1) |
| B `TestProbeN4CorruptStateStuck` | not running after 15 s; 10 recovery failures; doors "not running" (F2) |
| C `TestProbeN4FinishedWhilePCDown` | 13 left to the NAS, 13 entries applied; fetched twice 0; restarted 0; rules broken 0 |
| D `TestProbeN4SwitchWhileAway` | active at the cut 11, while away 11; fetched twice 0; restarted 0; rules broken 0 |
| `TestDialerLab*` (10), `TestOneClientSignInThenAccount` | pass |
| `TestRecoverActiveExcept`, `TestRecoverActive` (catalog) | pass |

Not run: the whole `internal/collector` or `internal/catalog`, the race detector, Docker (as the brief says).

# Second look: the fix round (wip/nas-pcside 58abd9d7; fixes 3cd0378f, ebe906d4, 58abd9d7; 2026-11-22)

**Verdict: may be listed. One should (G1) is best fixed before the first real use of the give-back. The rest is minor.**
F1 and F2 are fixed (probes A2 and B2). The store change keeps the PC's own resume and sweeps unchanged and never
resumes a NAS part (probe S and 22 named store tests). F8 works as corrected. The scratch copy was
`wt-nas-pcside-review2` (detached at 58abd9d7), with uncommitted probe files only; it has been removed.
Every run went through go2.sh, named tests only.

## (1) F1, F2 and the owner's give-back
- **F1: fixed, CONFIRMED (probe A2).** This is the first probe A again: three files in the state file, the place
  "pc" at another address, the NAS up. All 3 were given back within 6 s, 0 of 3 were still active after a restart,
  and the NAS was dialled once. Folders now record their address (`addr`), and every folder whose state holds files
  is linked, whatever the places say now.
- **F2: fixed, CONFIRMED (probe B2).** A truncated state file with the NAS away:
  - The collector runs.
  - The account's active files are kept for that NAS (3 held plus 3 of the PC's own, by the account's place).
  - The status door says `StateUnreadable` with its time.
  - `NASGiveBack` gave back 6 files and left 0 active; the file was set aside and a fresh one written.
- **G1 (should, CONFIRMED in part, probe E). `NASGiveBack` right after a switch to the PC is not refused while the
  NAS is still stopping.**
  - `ErrNASWorking` is decided from `l.startedAccts[account] && l.status.Working` (`nas_doors.go` 411).
  - After the switch, `drive` clears `startedAccts`. The NAS's `stop()` also sets `working=false` at once
    (`nasdl/node.go` 1264-1273), before its engine has ended; the engine has up to `StopGrace` for its writers and
    last Releases. So the guard cannot fire on the path its own message tells the owner to take ("set the account
    to this PC first").
  - Probe E: 7 files active. Right after `SetNASPlace(pc)`, the give-back released 5 of them. One Release from the
    NAS then arrived for a file already given back (stray 1), so the NAS still held it at that moment.
  - Outcome: 0 fetched twice, no rule the fake checks was broken, no loss, 2 files started again from 0 on the PC
    (as F8 means).
  - What remains is a window of seconds. A request already in flight on the NAS is cancelled rather than
    finished; a NAS Saved that lands is recorded, counted as `SavedNoGrant`, and the PC's copy becomes a duplicate.
    In the same window, `DropParts` with ids removes the part of a file still in hand: the ids branch of
    `nasdl.dropParts` has no `held` check, unlike the account branch.
  - **Fix:** refuse the give-back whenever that NAS's link is up (ErrNASReachable). A reachable NAS gives its files
    back itself after the Stop, and the switch path already does that. Keep the step for a NAS that is away or whose
    state cannot be read, which is what it is for. Also skip held ids in `dropParts`' ids branch.
- **Given-back files are not re-granted at a hello.** `adopt` drops any file in `GivenBack`. A later fresh claim by
  that NAS through the Supply clears the mark (`serve.go` claim). That is a new, single grant of a wanted file, so it
  is right.
- **Minor, by reading:**
  - (a) Account A moves from "nas X", with files still held at X, to "nas Y". A then sits in both links' accounts,
    and nasctl's registry refuses the second dial (ErrAccountsTaken). If X is gone for good, A downloads nowhere until
    the owner gives X's files back. That is correct, but the status should say why.
  - (b) A folder without an `addr` file (one made before this build) is never linked. The give-back still reaches it.
  - (c) After `ResetState`, the journal numbers start again, so entries applied before but whose ack was lost are
    applied once more (nasctl's own warning in `loadState`). Name it in the step's warning.
  - (d) `nasHeldAtStart` still fails the start for ever when the NAS folder itself cannot be stat'ed for a reason
    other than "not there". That is rare.
  - (e) An unreadable state file whose address no account's place names keeps nothing at the start: its files are
    given back while that NAS might still write them. That is the same warning as the give-back's.

## (2) The store change (`DropPart`, `TokenTagNAS`): right (probe S)
- PC tokens are unchanged ("tga1"), so a PC part's resume is unchanged: probe S resumed its own token at 4 parts.
- A NAS-tagged token on the PC's writer restarts from 0, and the part stays (no `restart(part)` for another tag).
- The staging sweep and the library-part sweep keep parts of either tag, because `parseToken` accepts both: probe S
  kept 1, removed 0.
- `DropPart` refuses another tag and removes its own. An unknown tag still does not parse.
- The 22 named store tests (`Resume|Token|Sweep|Part`) and the probe pass.

## (3) F8 as corrected: right, with two minor leaks that are bounded
- A Release, Requeue or HandOver of the NAS's own work keeps the part and the token, so a Stop and Start resumes from
  checkpoints.
- Parts are dropped at once on Gone, on a file dropped at a hello, and on `Cmd.DropParts`. `DropParts` is sent by
  `tellLeft` (in `drive`, before the Stop) when an account goes from "nas" to "pc", and with the give-back.
- With the account leaving, files given back later lose their parts (`givenBack`) until a start names the account
  again (`rejoin`).
- Minor leak 1: the NAS's tokens and the PC's `leave` list are in memory only, and a move from "nas X" to "nas Y"
  never tells X. A part kept that way waits for X's writer sweep at its next program start, once no progress row
  names it. A library part waits for a copier's sweep of library parts.
- Minor leak 2: a Saved for a file dropped at a hello leaves its token in memory.

## Probes (second look)
| Probe | Result |
|---|---|
| A2 (F1) | 3 of 3 given back within 6 s; 0 active after a restart; 1 dial |
| B2 (F2) | runs; 6 kept; status StateUnreadable; give-back 6, 0 active after |
| E (give-back right after the switch) | 5 of 7 given back; stray 1; fetched twice 0; restarted from 0: 2; rules broken 0 (G1) |
| S (store tags) | NAS token on the PC: offset 0, part kept; sweep kept 1, removed 0; DropPart other tag refused; own resume at 4 parts |
| store `Resume|Token|Sweep|Part` (22) | pass |
