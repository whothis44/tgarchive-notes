# Brief K29: the NAS's status raised as alerts (Core, K-6, 2026-11-22)

**Why:** a NAS that downloads for an account (N4, the NAS track's `wip/nas-pcside`, listed after pages' N4P) can be
away, refused by its VPN check, signed out by Telegram, waiting for the PC, or holding files for a long time while
unreachable. Nobody knows unless the owner looks. K22's alerts (merged) raise and record what needs a person; K22b
(merged next) sends them away from the PC. This piece adds the NAS's kinds. Agreed with the NAS track (N-1): read
the collector's own door, never `nasctl` directly.

**Rules:** you are the one Opus coder. Named tests and small packages only; never the whole `internal/collector` or
`internal/catalog`; every go command through `bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go2.sh <folder> ...`.
Invented data only; nothing against Telegram or a NAS (the in-process fakes only); never touch a running program, the
main copy, `C:\Users\trabi\tgarchive-app`, `E:\` or the NAS. Copy `wt-core-nasalerts`, branch `wip/core-nasalerts`
from `private/claude/charming-feynman-vm2xia` (the newest), with `private/wip/nas-pcside` merged in (N4 is not on the
head yet: say so in the hand-back so the integrator merges N4 first). Commit form as always; push only your branch.

## What to build
1. **Kinds in `internal/alert`**, each with its threshold as a stored setting (`alert.after.<kind>`, minutes, no upper
   bound of the app's own), from the collector's `(*Collector).NASStatus(ctx, acct) (NASState, error)` (read it on N4's
   branch: `Reachable`, `AsOf`, `VPNRefused`, `SignedOutByTelegram`, `WaitingEntry`, `WaitingSeconds`, `StateUnreadable`,
   `StateUnreadableSince`, `Held`, `UnreachableSince`):
   - `nas.away`: `!Reachable` (or `AsOf` older than the threshold), for an account whose place is the NAS; default 15 min.
   - `nas.vpn`: `VPNRefused`; default 15 min.
   - `nas.signed_out`: `SignedOutByTelegram`; at once.
   - `nas.waiting_entry`: `WaitingEntry != 0` for longer than the threshold; default 30 min.
   - `nas.holding`: `Held > 0 && !Reachable` for `alert.after.nas.holding`; default 1440 (24 h).
   - `nas.state_unreadable`: `StateUnreadable`; at once.
   An error from `NASStatus` itself raises `alert.unreadable` (fail closed), never "all is well".
2. **In K22's alerts task:** only for accounts whose place is the NAS (N4's place door); the "since" of each kept as
   K22 keeps its own (no restart ends a true alert: K22's F1 rule); an account set back to "the PC" ends its NAS alerts
   except `nas.holding` and `nas.state_unreadable`, which last while the condition holds (files still held).
3. **Words:** fixed, numbers only; the NAS named only as "the NAS", never its address.

## Tests (each seen failing first; the fake NAS link of N4's tests)
Each kind raised at its threshold and not a minute before; ended when the condition ends; across a restart one open row
(K22's rule); an account on "the PC" raises none of the link kinds; `nas.holding` from a state file with the NAS down; an
error from `NASStatus` raises `alert.unreadable`; K22's existing `TestAlerts*` pass. gofmt, build, vet; the viewer's `TestWall`.

## Hand back
`archiver/docs/progress/core-nasalerts-REPORT.md` and your last message, short: head pushed; the kinds and settings; the
tests as run; that N4 must merge first.
