# Review B3-12: the viewer's home-network mode (`wip/b-lan` at e5ffe20)

Independent, read-only. Read in full: `lan.go`, `session.go`, `password.go`, `cert.go`, `server.go`, `play.go`,
`media.go`, `api.go`, `viewer.go`, the changed parts of `decisions.go`, `stats.go`, `ffmpeg.go`,
`cmd/tgarchive/viewer.go` and both echo files, the page scripts that changed, and `lan_test.go`. Three
throwaway tests were run in a scratch folder outside every copy (Go 1.27.3, `httptest` on 127.0.0.1 only):
a write error on a broken TLS connection, `ServeMux.Handler` on odd paths, and `OPTIONS *`.

## Verdict

- **Merge switched off: yes, nothing first.** Without `-lan` the loopback listener behaves as before:
  `/signin`, `/api/signin` and `/api/signout` answer 404 there (no `lanReq` in the context), `/api/lan*` only
  read and write files in the data folder, and the guard, token, prefs and play slots for this PC are
  unchanged.
- **Switch on: yes, after three small fixes:** F2 (`/api/about` gives other devices this PC's folder paths), F3
  (a LAN device's address can reach the log), F4 (drop `Strict-Transport-Security`). Each is a few lines. The
  owner should also see the points under F5 (where the data folder lives) before switching on. F1 (anyone on
  the home network can keep sign-in closed) affects availability only. It can ship as is, with a "reopen
  sign-in" control on the PC to follow.
- No confirmed way found to read archive content, change state, reach `/api/open`, read or set
  `player_path`, or get past the password without signing in.

## Findings, worst first

### F1: confirmed. Any home-network device can keep sign-in closed for everyone, indefinitely
- **Who:** any device on the home network that has four addresses. One device can hold four IPv6 addresses
  (SLAAC, privacy or link-local addresses), or four IPv4 addresses with any root-level access. It needs no
  password.
- **Sequence:** from addresses A1 to A4, five times each, `POST /api/signin` with
  `Content-Type: application/x-www-form-urlencoded`, `Origin: https://<lan host>`, `password=x`. Each wrong
  try costs one serialized PBKDF2 (well under a second) plus a 1 s sleep that holds nothing. The 20th wrong
  try sets `g.closed = now+15m` (`session.go:205-209`). Repeat as soon as the close ends: the per-address
  blocks end at the same moment, so the next 20 tries close it again within seconds.
- **What they get:** no new device and no signed-out device can sign in, including the owner's.
  `signIn` returns `signinClosed` before checking the password (`lan.go:635-637`), so the right password
  is refused too. Devices already signed in keep working, and this PC keeps the loopback viewer. Changing
  the password does not reopen sign-in: `setPassword` (`lan.go:706-728`) does not touch `guesses`. Only a
  restart of the viewer clears the counters, and the attacker closes sign-in again within seconds.
- **The brief's other questions:** a burst of 100 parallel wrong tries gets exactly 5 per address and 20 in
  all checked. `verify` (capacity 1) is taken before `state()` and released only after `wrong()` has
  counted the try (`lan.go:624-649`). Rotating IPv6 addresses bypasses the limit of 5 per address but not the
  limit of 20 in all, so guessing stays capped at 20 per 15 minutes. Memory stays bounded: `prune` keeps
  fewer than 20 addresses in `byAddr` and at most 4 in `blocked` per window.
- **Smallest fix:** a "Reopen sign-in" button on this PC (`POST /api/lan/reopen`, loopback-only, which
  clears `guesses`). Also count IPv6 tries per /64, so that one device does not count as four.
- **Sure:** high (read from the code; the logic is small).

### F2: confirmed. A signed-in device reads this PC's folder paths, including the Windows user name
- **Who:** any signed-in device, such as a family member's tablet or a phone whose cookie was copied.
- **Sequence:** sign in, then `GET /api/about`. The answer carries `"catalogue"`, `"library"` and `"data"`
  as full paths (`api.go:132-133`), for example `C:\Users\<owner>\...`. The device's About page shows them,
  because `about.js` draws them on both listeners.
- **What they get:** the PC's folder layout and possibly the owner's Windows account name. This goes
  against design point 8 and the owner's rule of no paths outside this PC. Smaller: `GET /api/stats` gives
  route counts for this PC's own use (for example how often the Deleted page was opened or a player was
  started). These are numbers only.
- **Smallest fix:** in `handleAbout`, when `lanFrom(r) != nil`, leave out `catalogue`, `library` and `data`
  (or send `""`). Hide those three rows in `about.js` when `listener.lan` is set.
- **Sure:** certain.

### F3: confirmed by a scratch test. The addresses of a device and of this PC can reach the log
- **Who:** nobody needs to try. A phone that leaves a page in the middle of a large JSON answer is enough,
  for example `/api/meta`, which lists every chat.
- **Sequence:** a signed-in device `GET /api/meta` (or any JSON route), then closes the connection while the
  body is still being written. `writeJSON` logs `log.Printf("viewer: write json: %v", err)`
  (`viewer.go:481`). Measured on 127.0.0.1 over TLS, the error text is
  `write tcp 127.0.0.1:13240->127.0.0.1:13241: wsasend: An existing connection was forcibly closed by the remote host.`
  On the LAN listener that means `192.168.x.y:port->192.168.x.z:port`: both the PC's address and the
  device's.
- **What they get:** an adversary gains nothing. It breaks design point 9 and the owner's logging rule
  (never an address). The line is old code that the new listener now reaches with home-network addresses.
  The swap of `ErrorLog` for a counting log (`lan.go:346-358`) covers the server's own lines but not this
  one. `httpError` (`viewer.go:492`) logs `%v` of catalogue errors; they hold no addresses, but they are the
  same kind of risk.
- **Smallest fix:** `writeJSON` logs a fixed sentence (or only counts) and never the error text.
- **Sure:** certain about the text. How often it happens depends on phones; it will happen.

### F4: confirmed from the browsers' rules. `Strict-Transport-Security` never helps here and can lock a device out for a year
- `lan.go:394` sends `max-age=31536000` on every answer. RFC 6797 §8.1.1: a user agent must not note an IP
  literal as an HSTS host, so the first address Settings offers (`https://192.168.x.y:port/`) never gets HSTS.
  §8.1, which Chrome and Firefox follow: a header that arrives over a connection with certificate errors
  (the clicked-through self-made certificate) is ignored. HSTS therefore does nothing in the normal case.
- **It takes effect in one case,** and there it does harm: the owner installs the certificate as trusted on
  a device and uses the host-name address. The certificate is remade when the `-lan` address changes, 30
  days before it ends, or when its key file is damaged (`cert.go:39-55`). After that the device shows a
  certificate error that HSTS makes impossible to bypass for that host name, for up to a year, until the
  owner clears the browser's HSTS state. Plain HTTP on the port already gets nothing (Go's TLS server
  answers a fixed 400), so HSTS also adds nothing there.
- **Smallest fix:** remove the header and `hstsValue`, and the two test lines that expect it. The coder's
  doubt is right.
- **Sure:** high about the rules. Not tried on a device.

### F5: probable, depending on where the data folder is. On Windows the TLS key and the password hash are protected only by the folder's inherited access list
- `writeFileAtomic` calls `Chmod(0o600)` (`password.go:176`). On Windows that only clears the read-only
  attribute, so the key file, `lan-password.json`, `lan-signins.json` and `lan-settings.json` take the data
  folder's inherited access list. The default data folder is `viewer` beside the catalogue (`viewer.go:163`).
  On a secondary NTFS drive (the old archive sits on `E:`) the default list usually lets every local account
  read and change those files, and so does any network share the folder sits on.
- **Who:** anyone who gets the data folder's files: another local account, a backup or sync copy, or a NAS
  share. Another local account can already use the loopback viewer without any password, so for it this
  only adds the key.
- **What they get:**
  - With `lan-key.der`, they can impersonate the viewer to every device that has accepted this certificate,
    with no warning. A device's next sign-in then gives them the password, and they can relay whole
    sessions.
  - With the password hash, they can guess offline at 600,000 PBKDF2 rounds per guess: strong for a random
    password, weak for a common phrase of 12 characters or more. The only check on new passwords is the
    length.
  - `lan-signins.json` holds only SHA-256 hashes of the 32 random bytes and is of no use to them.
- **Smallest fix:** keep the key and the password in a folder under the user's profile (for example
  `%LOCALAPPDATA%\tgarchive\viewer-lan`, which takes the profile's owner-only access list) instead of beside
  the catalogue. At the least, Settings should say where they are and that they must not sit on a share.
  Setting an explicit access list needs `advapi32`, which the import wall does not allow today.
- **Sure:** medium. It depends on the folder's real access list, which was not looked at (the owner's
  folders are off limits).

### F6: probable, and small. Before sign-in, any home-network device learns the app's name and the PC's host name
- The certificate's subject is `CN=tgarchive viewer`, and its DNS name is the PC's host name (`cert.go:117,
  125-127`). The sign-in page is titled "Archive viewer". Any device that completes a TLS handshake can read
  all of this; the address check lets every private address that far.
- **What they get:** that this PC holds a Telegram archive, and its host name, which can be a person's name.
  The host name usually leaks through NetBIOS or mDNS anyway.
- **Smallest fix:** a neutral CN (`viewer`, or no CN at all, since the SAN carries the names).
- **Sure:** certain about the content. Whether it matters is the owner's call.

### F7: probable, depending on the setup. The private-address check is no barrier when something on the home network forwards or proxies
- `privateListener` and `ServeHTTP` look at the TCP source address. Some things make every internet client
  appear to come from a private address: a router that masquerades forwarded ports, a reverse proxy, or a
  tunnel (a NAS's reverse proxy, a Cloudflare or Tailscale Funnel tunnel). A commercial VPN adapter on this
  PC has a 10.x address too, if its address is ever given to `-lan`.
- **What remains:** the Host check, which refuses a proxy that passes on the public host name, and the
  password with its limit of 20 in all.
- **What changes:** the limit of 5 per address then applies to every client behind that one address. One
  internet client can then also lock out the owner's devices behind the same proxy, as in F1.
- **Smallest fix:** none in code. One more sentence in Settings: never forward or proxy this port. The
  firewall rule should be Private profile and remote address "Local subnet", not just Private.
- **Sure:** the mechanics are certain. Whether the owner's network has such a path is unknown.

## Design points I would change, although they hold

1. **Reads are allowed by default.** Every new GET route is open to signed-in devices unless someone
   remembers to add it to `lanNever` (`lan.go:78`). `GET /api/lan` is safe today only because it is listed.
   I would give each route an access class at registration (`handle(pattern, h, local|read|mark)`) and have
   the route-walk test fail on any pattern without a class. The other coder is adding routes on
   `wip/b-probable` now.
2. **The second locks are uneven.** `thisPCOnly` (a context check) guards the `/api/lan*` handlers.
   `handleOpen` uses `loopbackRemote` instead (`play.go:369`). `handleSetPrefs` and `handleUnhideAll` have
   no lock of their own and rely on the guard alone. Use `thisPCOnly` in all four.
3. **Nothing is cleared on sign-out.** Thumbnails are kept 7 days (`private, max-age=604800`) and files 1
   hour in the device's cache after sign-out. Send `Clear-Site-Data: "cache", "cookies"` with the sign-out
   answer.
4. **Streams outlive the session.** A file or conversion stream already running continues after sign-out,
   after "sign out all" on the PC, or after a password change, until it ends. Range requests check the
   session again; one conversion stream does not.
5. **Conversion starts are not rate-limited.** Start, abort, start never runs more than one ffmpeg process
   for the LAN listener: `conv.stop()` kills and waits before the deferred `giveFor` (`play.go:245, 258`;
   `ffmpeg.go:129-134`). The loop can still start a process and open a library file over the NAS link many
   times a second. A short gap between two LAN starts would stop that.
6. **No limit on connections** to the LAN listener. Each idle one lasts up to 10 s (`ReadHeaderTimeout`).
   A cap of a few dozen through a counting `Accept` would bound it.
7. **The PC should flag a new certificate.** After a remake (new `-lan` address, renewal, damaged key),
   About should say when the fingerprint changed, so the owner knows to compare again rather than click
   through out of habit.
8. **The host name in the Host set is not a separate rebinding hole,** and I would still drop it. A page
   served under `https://<hostname>:port` by another LAN machine that answers LLMNR, mDNS or NetBIOS for
   that name needs a certificate error clicked through first: browsers remember an exception per host and
   certificate. With that click-through the same machine could simply relay traffic and capture the
   password, so the name adds no power. But it doubles the names whose warning the owner learns to accept,
   and IP-only is simpler to explain. If it stays, Settings should list the IP address first (it does).
9. **Common passwords pass.** Only the length is checked. A small built-in list of common 12-character
   phrases would help the offline case in F5.
10. **The command:** Ctrl+C at the prompt leaves echo off (no signal handler restores it). A wrong `-data`
    folder that exists still reports "set", so the owner believes the running viewer's sign-ins ended when
    they did not.
11. **Port 443 cannot be used:** browsers then send `Host` without a port, and `hostOK` refuses it. This is
    functional, not security; say so at start or accept both forms.
12. **"Hidden" is a filter, not access control.** A signed-in device can still open hidden chats by id.
    The owner should know this before giving the password to anyone.

## The tests the hand-back leans on

- **`TestLANNoSessionEveryRoute`: partly a stand-in.**
  - It walks `v.patterns`, the routes registered through `handle`. The check against a stray registration
    counts `mux.HandleFunc(` and `mux.Handle(` in `server.go` only (`lan_test.go:240-246`), so a
    registration in `lan.go` or any new file would not fail it.
  - It tries no unclean paths, `..`, encoded slashes, `OPTIONS`, `CONNECT` or `*`.
  - The claim holds anyway, from the code: without a session the guard refuses before the mux on any path,
    and the decision and the dispatch run the same `findHandler` on the same request. The scratch test
    confirms that unclean forms map to the clean route's pattern with a 307 handler, encoded slashes to `""`
    (404), and HEAD to the GET pattern. `OPTIONS *` is answered by `net/http` itself (200, empty) and never
    reaches the guard; it leaks nothing.
- **`TestLANPasswordCompareConstantTime`: a source-text stand-in, not a timing test.** It would miss a
  branch hidden in a helper. Reading `matches` confirms it: no branch on the guess, and a key of fixed
  length compared with `subtle.ConstantTimeCompare`. `tokenEqual` too.
- **`TestLANGuessLimits`: real for the counts, the expiry and the 1 s wait holding nothing.** It is
  sequential only, so the claim about parallel tries rests on reading `verify` (F1).
- **`TestLANSessionRestartAndPasswordChange`: real.** It opens a new `Viewer` on the same folder and calls
  the real `SetPassword` while the viewer runs. The echo and pipe refusal of the command is not tested.
- **`TestLANPlayerPathThisPCOnly`: real for the guard, not for the second lock.** LAN requests in the tests
  come from 127.0.0.1 with 127/8 counted as private (`lan_test.go:86, 155`), so `handleOpen`'s own
  `loopbackRemote` check would pass. The 403 it shows comes from `lanNever` alone. The handlers' own
  refusal is tested only for three `/api/lan` routes (`lan_test.go:826-835`).
- **`TestLANPlayOneConversion`: real.** It uses a stand-in process that is really started and killed, and
  it checks the shared slots and that the slot comes back after the LAN request ends. Start, abort, start
  is not tested; the code holds (point 5).

## Checked and sound

- **Default deny:** host, other-site rules, then the session, then `lanNever`, then changes allowed by name
  only. The pattern decided is the pattern dispatched. HEAD maps to the GET pattern. The public routes are
  three exact decoded paths.
- **Which listener:** the context value is set only in `lanServer.ServeHTTP`, never from a header, and
  every LAN request carries it. Host, proxy headers and IPv4-mapped forms cannot reach loopback behaviour.
  `player_path` is removed from `/api/meta`, `/api/prefs` and the prefs answer. `/api/open`, the prefs,
  "unhide all", the password, the sessions and the switch are refused from the LAN listener. The per-run
  token is never served there, and a session's token is SHA-256 of the cookie under a label, compared in
  constant time.
- **Conversions:** two slots in all and one for the LAN listener, given back only after ffmpeg has exited.
  HEAD takes nothing.
- **Password:** PBKDF2-HMAC-SHA256, 600,000 rounds, a 16-byte random salt, parameters stored beside it,
  stored rounds bounded. It never appears in an address, a log, an error or an answer. It is set from the
  loopback listener or the command only.
- **Sessions:**
  - 32 random bytes in a `__Host-` cookie: Secure, HttpOnly, SameSite=Strict, `Path=/`, no Domain.
  - Kept only as a hash. Both expiries are checked at every use. Fixation is impossible: an unknown value
    is never adopted.
  - Sign-out, sign-out of one or all, and a password change end them, also a change by the command within
    2 s. Sessions are bound to the salt, so a sign-in that races a password change is born invalid.
  - The cap of 64 can only be used by someone who knows the password.
- **Who may connect:** the ranges are right (10/8, 172.16/12, 192.168/16, 169.254/16, fc00::/7, fe80::/10).
  IPv4-mapped forms are handled; CGNAT, NAT64, 6to4 and IPv4-compatible forms are not private. Connections
  are refused at accept, before TLS. `-lan` refuses 0.0.0.0, `::`, an empty host, public addresses and
  zones on anything but link-local. An IP-literal Host defeats rebinding.
- **TLS:** ECDSA P-256 from `crypto/rand`, TLS 1.2 at least, `http/1.1` only (no h2), a random serial, a
  server-auth leaf. Plain HTTP gets Go's fixed 400. The fingerprint is shown only on this PC (`/api/lan` is
  in `lanNever`). A remake gives devices a new warning; their sessions continue.
- **Command:** echo is off through `SetConsoleMode` on Windows and `stty` elsewhere. A pipe or a file on
  stdin is refused on both. Nothing goes in arguments or the environment, and the file is written
  atomically with a rename.
- **Logging:** the new log lines use constant format strings with counts only (F3 is old code), and the
  server's error log only counts.
