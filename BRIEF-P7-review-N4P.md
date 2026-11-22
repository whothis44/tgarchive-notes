# Brief: the independent review of N4P, the pages' Go side for the NAS downloader (pages, P7, 2026-11-22)

Read first: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-P7-review-rules.md` (binding). TEMP, TMP, LOCALAPPDATA,
APPDATA of test processes in `C:\Users\trabi\AppData\Local\Temp\p7-n4rev\` (outside any git copy). Fakes only:
nothing talks to Telegram or a NAS.

**The piece:** `wip/pages-nas` acee74f9 (from the head): `git diff private/claude/charming-feynman-vm2xia acee74f9`.
The ask: `BRIEF-N4P-nas-pages.md`; the contract: `NOTE-N4-collector-side.md` (section "The collector's doors"); the
coder's report `archiver/docs/progress/pages-nas-REPORT.md`. **It carries the owner's phone, login code and two-step
password from the page towards a sign-in on the NAS, and a button that ends a Telegram login. Find any way something
typed is logged, kept, echoed, cached or reaches a place it should not; any way a request from elsewhere can start a
sign-in step, a forget or a place change; any way the pairing bundle or an address leaks a path; any way the no-VPN
state can be hidden.** Your copy: `git -C C:\Users\trabi\Claude\Projects\Telegram\repo-archiver worktree add --detach ../wt-pages-review-n4p-scratch acee74f9`.
Report to `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-N4P-nas-pages.md`. Within about an hour.

## Questions, in this order
1. **Secrets:** every path of the phone, code and password through the routes, the seam, the adapter and the fake:
   logs (every logger call reachable), error words, answers, the kept per-account brief, panics, request dumps; a
   probe that types each and greps every output. The user id never appears.
2. **The guard:** every new route under the same guard, same-origin rule and held-stop refusal as the PC's sign-in
   routes; a cross-site form POST, a missing token, a GET that changes anything, a body too big.
3. **The address and the bundle:** what the address check accepts (a hostname that resolves elsewhere, an IPv6, a port
   0, a URL with a path); the bundle served as an attachment with a fixed name and no path; anything of this PC's in it.
4. **No-VPN:** shown in every answer carrying the NAS's state and on the Overview per account; can a fake's state make
   it disappear while true?
5. **The written door for Core** (the report's one door): right against the contract and the phone fix?
6. Anything else: its own number.
