# Brief B3-11: the viewer from other devices at home, with a password and HTTPS (session B3, 11-15)

You are an Opus coder. Work only in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-faces`. First:
`git fetch private wip/b-viewer && git checkout -B wip/b-lan private/wip/b-viewer` (1f8b681). Go module:
`archiver/`. Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in each Bash call.
Packages: `archiver/internal/viewer` (Go and `web/`) and `archiver/cmd/tgarchive/viewer.go` only. **Standard
library only: `go.mod` is not to be changed** (Go 1.26: `crypto/pbkdf2`, `crypto/tls`, `crypto/x509`,
`crypto/ecdsa` are there). Commit after each part and `git push private wip/b-lan`
(`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; no archive numbers).

## What is asked (FEATURES section 7, roadmap D6: listed, so already asked for)
"Use from other devices at home, with a password and HTTPS: keep, with its own security review (owner,
11-11)." The owner (11-11): only on the home network for now, and a password and real security must be
enforced. The old app's share links, guest password and "force HTTPS" are replaced by this. An independent
security review follows your hand-back before it is merged: write for that reader.

## What exists (read first, in full)
`server.go` (the guard: loopback only, a Host check, Sec-Fetch-Site and Origin rules, the token for changes,
headers and CSP), `api.go`, `media.go` (`handleFile`, `handleThumb`), `play.go` (`/media/{id}/play`,
`/api/open` refused unless the request is from this PC), `decisions.go`, `cmd/tgarchive/viewer.go`, and the
tests `security_test.go`, `readonly_test.go`, `wall_test.go` (the import wall: it will have to grow by the
crypto packages you use: list them exactly, nothing wider).

## The design (decided by the main session; where you must differ, say why)
1. **Off by default, a second listener.** The loopback listener stays exactly as it is (plain HTTP, no
   password, this PC). `tgarchive viewer -lan <address:port>` adds an HTTPS listener bound to that one
   address (never `0.0.0.0` or `::`; the address must be a private one of this PC: RFC 1918, link-local or
   IPv6 unique-local; anything else is refused at start with a plain sentence). No password set: refused at
   start. The two listeners share the index and nothing else: a request knows which listener it came in by
   (a value set by the listener, never taken from a header).
2. **HTTPS.** A self-made certificate, made on first use and kept in the viewer's data folder (ECDSA P-256;
   the key file written with owner-only permissions where the system has them; valid 2 years, remade 30
   days before it ends or when the `-lan` address is not among its names; names: the `-lan` address and the
   PC's host name). TLS 1.2 at least. Its SHA-256 fingerprint is shown on the About page **on this PC** so
   the owner can compare it on the phone's warning page. Plain HTTP on the LAN port answers nothing useful
   (the listener is TLS only).
3. **Password.** Set and changed only from the loopback listener (Settings on this PC) or by
   `tgarchive viewer-password -data DIR` (read without echo, twice). At least 12 characters. Kept in the
   viewer's data folder as PBKDF2-HMAC-SHA256, 600,000 rounds, a 16-byte random salt, the parameters stored
   beside it; compared in constant time. Never logged, never in an address, never sent back.
4. **Sign-in and sessions (LAN listener only).** Every route but the sign-in page, its one stylesheet and
   `POST /api/signin` needs a session. A session is 32 random bytes in a cookie (`__Host-` prefix, `Secure`,
   `HttpOnly`, `SameSite=Strict`, `Path=/`), kept server-side as its SHA-256 only (in the data folder, so a
   restart keeps sessions), ending after 30 days without use or 90 days in all; "Sign out" on the device;
   on this PC, Settings lists the sessions (when made, last used, no address) with "sign out" each and "sign
   out all"; changing the password ends all of them. An answer to a request without a session is a redirect
   to the sign-in page for a page and 401 for `/api` and `/media`, and says nothing about the archive.
5. **Guessing.** After 5 wrong passwords from one address in 15 minutes that address waits 15 minutes; after
   20 wrong in 15 minutes from all addresses together, sign-in is closed for 15 minutes for everyone (the
   page says so); each wrong try also costs a fixed delay of 1 s (not holding a lock). The counters are in
   memory; the About page on this PC shows wrong tries today and the time of the last (no address).
6. **Who may connect.** The remote address must be private (as in 1) or the request is closed before
   anything else: a router's forwarded port from the internet is refused. The Host header must be the
   `-lan` address (with its port) or the PC's host name. The Sec-Fetch-Site, Origin and token rules stay as
   they are for both listeners (the token is tied to the session on the LAN listener).
7. **What a signed-in device may do.** Read everything the viewer shows, play, save a file. By default
   nothing that changes state: hiding, verdicts, per-chat clutter, preferences, the password, the player
   program and "Open in the player" are refused from the LAN listener (403 with a plain sentence), unless
   the owner switched on "Other devices may hide and mark" on this PC, which allows hiding, verdicts and
   per-chat clutter only. The converted copy (`/media/{id}/play`) is allowed (it is how a phone plays what
   it cannot decode), with the same two-at-once limit shared by both listeners.
8. **Headers and caching.** Everything the loopback listener sends, plus `Strict-Transport-Security` on the
   LAN listener; media and thumbnails `private`; the sign-in page `no-store`.
9. **Logging and privacy.** Counts and fixed words only: never an address, a password, a cookie, a title or
   a path. New log lines use constant format strings.
10. **The page.** A sign-in page (one field, one button, the closed-for-15-minutes sentence); "Sign out" in
    the navigation on the LAN listener; on this PC, Settings gets a block "Other devices at home": whether it
    is on, the address to type on the phone, the certificate's fingerprint, set or change the password, the
    sessions, the "may hide and mark" switch, and three plain sentences on what the owner must do in Windows
    Firewall (the viewer changes no system setting). The owner's starter is not changed by you.

## Tests (named, while working; `httptest` with TLS, invented data only)
No session: every existing route answers 401 or the redirect on the LAN listener (walk the route table, so a
route added later is covered); the loopback listener is unchanged (the existing security tests pass
untouched); a public remote address is refused; a wrong Host is refused; the cookie's attributes; a session
survives a restart and ends on password change; the 5 and 20 limits and their expiry (an injected clock);
constant-time compare is used (no early return on length); state-changing routes refused from the LAN
listener, then the three allowed with the switch; `/api/open` and the password routes refused from the LAN
listener whatever the switch; `-lan 0.0.0.0:…` and a public address refused at start; no password refused
at start; the certificate remade when the address changes; the stored password file holds no plain
password. Then once at the end: `go test ./internal/viewer -p 1` (about 3 minutes, in the background),
`gofmt -l`, `go vet ./internal/viewer ./cmd/tgarchive`, `node --check` on the scripts. No race detector, no
mutation checks, one go command at a time.

## Rules
- Never open the viewer on real data or any real file; never bind a listener to a non-loopback address in
  tests or by hand (tests use `127.0.0.1` with the "private address" check given the test's own list);
  nothing against Telegram; do not touch `repo-archiver`, other `wt-*` folders or other packages; do not
  change `go.mod`. Do not merge into or push `claude/charming-feynman-vm2xia` or `wip/b-viewer`.
- CSS in one block at the end of `web/app.css` (the sign-in page has its own small stylesheet). Another coder
  works on `wip/b-probable` (`library.go`, `appear.go`, `copies.go`, `decisions.go`): keep your changes to new
  files (`lan.go`, `session.go`, `cert.go`, …) and the guard in `server.go` where you can.
- Concurrent code: say exactly what the two listeners share and how each shared thing is guarded.

## Hand back
Commits; the threat list you built against (who can reach the port, what each can do before and after
signing in); every place this brief was not followed and why; named tests; whole-package time and result;
what the listeners share; what you would attack first if you were the reviewer; doubts.
