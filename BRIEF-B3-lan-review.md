# Brief B3-12: independent security review of the viewer's home-network mode (session B3, 11-15)

You are an independent security reviewer. You did not write this code. **Read only:** change no file in any
copy, commit nothing. Your one output file is
`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-B3-lan.md`.

## What to review
`C:\Users\trabi\Claude\Projects\Telegram\wt-b-faces` at e5ffe20 (branch `wip/b-lan`): the four commits
`git log 1f8b681..e5ffe20` (`dd0e62a`, `3e6ca27`, `1099c73`, `e5ffe20`) in `archiver/internal/viewer` and
`archiver/cmd/tgarchive`, read against the whole of `server.go`, `api.go`, `media.go`, `play.go`,
`decisions.go`. The design it was built to: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-B3-lan.md` (read
it first; its ten numbered points are the claims to test).

## What it is
The viewer shows a private archive (names, messages, pictures, videos) to its owner. Until now it listened
on this PC only (plain HTTP on 127.0.0.1, no password). The new mode, off by default, adds a second,
HTTPS-only listener on one private address of the PC for other devices at home, behind a password. The owner
(11-11): only the home network, and "a password / real security must be enforced". It is merged only after
this review. Treat as the adversary, in turn: a device on the home network without the password (a guest's
phone, a compromised smart device); a web page open in a browser on a home device (cross-site requests, DNS
rebinding); the internet through a router's forwarded port; a signed-in device trying to do more than read
and play; someone who obtains the data folder's files.

## Check, in this order
1. **Default deny.** `lanServer.ServeHTTP` decides before the request is served. Can any route, asset, or
   path form (unclean paths, `..`, encoded slashes, a trailing slash, a redirect by the mux, `CONNECT`,
   `OPTIONS`, `HEAD`, an upgrade) reach a handler, or leak whether something exists, without a session? Is
   the route found by the decision always the route then dispatched? Is every route registered through the
   one helper, and does the test that says so really fail on a stray registration?
2. **Which listener.** Is "this request came in by the LAN listener" unforgeable (a context value, never a
   header), and is it consulted everywhere the two differ: prefs, the password and switch routes, `/api/open`,
   `player_path` in any answer, "unhide all", the token? Can a LAN request reach the loopback-only behaviour
   through the Host header, a proxy header, or an IPv4-mapped IPv6 address? Can a loopback request be made
   to look like a LAN one or the reverse?
3. **The integrator's two points:** "Open in the player" starts a program on this PC and `player_path` names
   it: both must stay this PC's only, the setting not writable (or readable for change) from another device
   by any route; and the converted playback's two ffmpeg slots: another device may hold one at most. Also:
   can a signed-in device make the PC start ffmpeg repeatedly (start, abort, start) in a way that costs more
   than one process at a time?
4. **Password and sessions.** PBKDF2 parameters and storage; constant-time compare really constant (length,
   early exits); the password or cookie in a log, an address, an error, a stats answer; the cookie's
   attributes; the session kept only as a hash; expiry (idle and absolute) enforced at use, not only at
   sign-in; fixation (a cookie set before sign-in surviving it); sign-out and "sign out all"; a password
   change ending every session, also when changed by the command while the viewer runs; the token: derived
   how, tied to the session, compared in constant time; the cap of 64 sessions as a way to sign the owner's
   devices out.
5. **Guessing.** The 5 and 20 limits: bypass by many connections in parallel (checks one at a time: does a
   burst of 100 parallel wrong tries get more than the limit through?), by IPv6 address rotation, by
   restarting nothing; the global close as a way for one device to lock the owner out (how long, and does
   this PC stay able to use the viewer and change the password?); memory growth of the counters.
6. **Who may connect.** The private-address check: every range right (10/8, 172.16/12, 192.168/16,
   169.254/16, fc00::/7, fe80::/10; IPv4-mapped; CGNAT 100.64/10 is not private); refusal before TLS; the
   `-lan` address validation at start; the Host check against rebinding (a name that resolves to the PC's
   LAN address must be refused unless it is the PC's own host name: and is accepting the host name itself a
   rebinding hole when another machine on the LAN can answer for that name?).
7. **TLS and the certificate.** Key generation and file permissions (on Windows: what actually protects the
   key file?); minimum version; the certificate's fields; the fingerprint shown only on this PC; what a
   device sees after a remake; whether sending `Strict-Transport-Security` from a self-made certificate helps
   or harms (the coder doubts it: say which, with the browser behaviour you rely on).
8. **What a signed-in device can read that it should not.** `/api/about` shows the catalogue, library and
   data folder paths; `/api/stats`; error texts; anything naming this PC's folders or the owner's Windows
   user. The owner's privacy rule for logs is counts and fixed words only: is anything else logged by the new
   code?
9. **The command** (`viewer-password`): echo off on Windows and elsewhere; a pipe refused; the password in
   a process argument or environment; the file written atomically.
10. **The tests' honesty.** For each named test in `lan_test.go` that the hand-back leans on (the route walk,
    constant time, the limits, restart and password change, the player path, one conversion): does it test
    what its name says, or a stand-in for it?

## How
Read the code; reason from it. You may write and run small throwaway Go tests **in a scratch directory
outside every copy** when a finding cannot be settled by reading (say so; one go command at a time; `source
/c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`; `httptest` on 127.0.0.1 only; never bind
a listener to a non-loopback address). Never start the viewer on real data, never open a real file, the real
catalogue or the owner's data folder; nothing against Telegram; do not touch `repo-archiver`.

## The report (`REVIEW-B3-lan.md`)
Findings ranked by what an adversary gains: **confirmed** (the exact request sequence, file and line) before
**probable**, each with who can do it, what they get, the smallest fix, and how sure you are. Then a short
list of design points you would change even though they hold (with why), and what you checked and found
sound, in a few lines. A plain verdict at the top: may this be merged switched off; may the owner switch it
on; what must be fixed first for each. No praise, no summary of the code. Your final message: the verdict
and the three worst findings in one line each.
