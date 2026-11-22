# Brief N4P: the pages' Go side for the NAS downloader (Accounts and Settings) (pages, P7, 2026-11-22)

You are the coder: Opus 5.5 at high effort, one piece start to finish; hand back a branch ready to list.

## The house rules (binding)
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-P7-review-rules.md` (privacy, safety, every go command through
`runs-pages-p6/go1.sh`, named tests). TEMP, TMP, LOCALAPPDATA, APPDATA of test processes in
`C:\Users\trabi\AppData\Local\Temp\p7-n4p\` (outside any git copy). Invented data only. **Nothing here may talk
to Telegram or a NAS: fakes only.** Commits `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`,
ending `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push `git push private HEAD:wip/pages-nas` only.
**Go only: the front end (`internal/server/web`, `internal/appshell`) is the UI track's (U-1); do not edit it.**
Do not edit `internal/collector` outside `livepages` (Core's), nor `internal/nas*` (the NAS track's).

## Where
`git -C repo-archiver fetch private && git -C repo-archiver worktree add -b wip/pages-nas ../wt-pages-nas private/claude/charming-feynman-vm2xia`.
Report: `archiver/docs/progress/pages-nas-REPORT.md`.

## Read first
1. `C:\Users\trabi\Claude\Projects\Telegram\NOTE-N4-collector-side.md` whole, and its section "The collector's
   doors": the contract (Core writes those doors in `internal/collector`; they are NOT on the head yet).
2. `DESIGN-NAS-downloader.md` sections 1 to 3 (same folder).
3. How the PC's own sign-in page is built end to end: its seam in `internal/server` (the sign-in interface, its
   routes, the guard, the held-stop rules, the words), its adapter in `internal/collector/livepages`, its tests and
   the demo's fake. Follow that pattern exactly.

## What to build
1. **A seam in `internal/server`** (an interface `NAS` with plain types of the server's own, field for field the
   contract's): place (get, set: "pc" or "nas" and the address), pair (the bundle as bytes), status, the sign-in
   steps (status, send_code, resend_code, code, password, cancel) and forget. `nil` when the program offers no NAS
   doors: then nothing NAS shows.
2. **Routes**, under `/api/accounts/{id}/nas...` or as the sign-in page's routes are shaped (follow it):
   GET the account's NAS facts (place, address, paired, status) in one answer; POST place; GET the pairing bundle
   as a download (`Content-Disposition: attachment`, a fixed file name, no path anywhere); POST each sign-in step;
   POST forget (its cost said in the answer before: "one request to Telegram that ends the NAS's login").
   Same guard, same-origin rule, held-stop refusal and route lists as the PC's sign-in routes (update the guard
   tests' lists). **Nothing typed (phone, code, password) is logged, stored, or echoed back**; the user id never
   appears. Address input: only a plain host or IPv4:port the contract allows (say what you accept), refused
   otherwise with fixed words.
3. **The no-VPN state** in every answer that carries the NAS's state (`no_vpn: true` with fixed words), and in the
   Overview's answer per account when the place is "nas" (one field, so U-1 can show it loudly everywhere).
4. **The adapter in `livepages`**: build it against the contract's names; since Core's doors are not on the head,
   put the adapter behind an interface of livepages' own that the collector will satisfy, with a compile-time
   check in a file that Core's merge will make compile (or leave the wiring as ONE short written door in the
   report for Core: say which, and why).
5. **The demo's fake** (as the sign-in's): every state (pc, nas not paired, paired and signed out, waiting for a
   code, wrong code, two-step password, signed in, signed out by Telegram, no VPN, the NAS away).
6. **Tests:** each route and state with the fake; the guard and held-stop; nothing typed in any log line or answer
   (a test that types a phone, a code and a password and greps every log and answer for them); the bundle as an
   attachment with no path. gofmt, vet, named tests.

## Hand back
Branch pushed, copy clean; the report (the JSON shapes for U-1; what waits for Core's doors). Final message: head,
report path, one line not verified.
