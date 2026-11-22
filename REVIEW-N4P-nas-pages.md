# Review of N4P, the pages' Go side for the NAS downloader (pages, P7 review, 2026-11-22)

What I read: `git diff private/claude/charming-feynman-vm2xia acee74f9` in full (`internal/server/nas.go`, `demonas.go`,
`nas_test.go`, the changes to `server.go`, `stopheld.go`, `overview.go`, `accounts.go`, `security_test.go`;
`internal/collector/livepages/nas.go` and its test), the brief, `NOTE-N4-collector-side.md` (the doors), the coder's
report, the PC's sign-in parts it reuses (`readSecret`, `PhoneDigits`, `codeDigits`, `signInAccount`, `refuse`, the
guard, the held stop, `errClass`, `lasting`), the account removal in `accounts.go`, and `nasproto` on
`wip/nas-pcside` (`SignInArgs`, `SignInResult`, the status). What ran: a scratch copy
`wt-pages-review-n4p-scratch` at acee74f9; my probes `zz_probe_nas_test.go` (uncommitted, `TestZZProbeNAS*`, eight
tests) and the coder's named tests with the guard tests (`TestNAS.*`, `TestMutationsRefusedFromElsewhere`,
`TestWriteGuards`, `TestDemoRunWritesNothing`, `TestHeldStopRefusesChanges`, `TestPagesLogNoNames`, `TestAccounts`,
`TestOverviewShapeKeepsControls`, `TestNASSeamOverDoors`): all pass. Every go command went through
`runs-pages-p6/go1.sh`, test processes with TEMP, TMP, LOCALAPPDATA and APPDATA in `%TEMP%\p7-n4rev`. Invented
doors only; nothing talked to Telegram or a NAS. Line numbers are on acee74f9 (the piece is not on the main head).

## Findings

1. **SHOULD FIX: the no-VPN state disappears whenever the NAS's status comes back with an error, the NAS away
   included.** Confirmed: `TestZZProbeNASNoVPNUnread` (an account on the NAS, signed in, `NoVPN: true`; the door's
   status answering an unmapped error, `ErrNASNotRunning`, then `ErrNASAway`): each time the facts say
   `"no_vpn":false`, the facts hold no VPN word at all, and the Overview says `no_vpn` false. Where:
   `internal/server/nas.go` 557-572 (away: `st = NASState{}`; any other error: `unread`, NoVPN never set),
   940-954 (the brief: the same), and `livepages/nas.go` 147-153 (`NASStatus` throws the door's state away on any
   error, so a door that answers its last known state with an "away" error loses it before the pages see it). How a
   person meets it: the owner has the NAS's no-VPN setting on. The PC's link to the NAS drops (Wi-Fi, a restart of
   the collector). The away words say "files it holds finish there", so the NAS is still sending requests straight
   to Telegram, but every page now shows [name removed] VPN line. The same happens for the few seconds the collector is
   starting (`ErrNASNotRunning`). The brief's question 4 ("can a fake's state make it disappear while true?"): yes.
   Smallest cure: keep the last `NoVPN` seen per account in `nasKeep`, and when the status cannot be read say it
   with one more field and fixed words ("no_vpn_unknown": true, "The NAS's VPN setting cannot be read now: it was
   NO VPN when last seen"), never a plain `false`. Also let the adapter pass the door's state through when the error
   is the away sentinel, and tell Core in the door that `NASStatus` answers its memory with `Reachable:false` rather
   than an error.

2. **SHOULD FIX: the sign-in step answers and the forget answer do not carry the no-VPN state.** Confirmed:
   `TestZZProbeNASNoVPNInSteps` (the NAS on no VPN; the facts say `"no_vpn":true`): `POST /api/nas/signin/status`,
   `send_code`, `code` and `forget` each answer 200 with no `no_vpn` field and [name removed] VPN words. Where: `nas.go`
   695-703 (`nasStep`) and 864 (`handleNASForget`); `NASSignInAskWords` (165) does not mention it either. The brief,
   point 3, asks for it "in every answer that carries the NAS's state", and these are the answers to the clicks that
   make the NAS send to Telegram (a code request, the code, the password, `auth.logOut`). How a person meets it: the
   owner clicks "Ask Telegram for a code for the NAS" on a NAS that has no VPN. The request goes straight to
   Telegram from the home address, and nothing in the click's answer says so. If U-1 builds the panel from the step
   answer, the warning is not there while the owner types the code. Smallest cure: in `nasStep` and
   `handleNASForget`, read the kept brief (`nasBriefOf`, memory) and add `no_vpn`/`no_vpn_words` to the answer.
   Put the no-VPN words into the ask words when it is on, or refuse `send_code` until the owner has seen them.

3. **SHOULD FIX: a removed account's NAS login can no longer be seen, cancelled or forgotten, and the removal does
   not check for it.** Confirmed: `TestZZProbeNASRemoved` (an account on the NAS, signed in there on no VPN, then
   marked removed in the catalogue): `POST /api/nas/forget` answers 409 "This account is marked removed: nothing is
   sent for it. Bring it back first.", `cancel` 409, `GET /api/nas` 409, and the Accounts list carries no NAS field
   for it. The forget never reached the doors. Where: `nas.go` 513, 715, 855 (`signInAccount` refuses removed
   accounts); `accounts.go` 99-102 (the removed rows get no brief); `accounts.go` 174-195 (the removal only checks the
   PC's sign-in, `signInOpen` and `signGate`, never the NAS's login or a NAS code under way). How a person meets
   it: the owner stops an account whose downloads ran on the NAS and removes it. The NAS still holds a Telegram login
   of that account, perhaps with no VPN. The pages show nothing of it, and "forget the NAS login" is refused. The
   only way out is to bring the account back, forget, and remove it again, and nothing on the pages says so.
   Smallest cure: have the removal refuse in fixed words while the account's place is "nas" with a pairing, or while
   its NAS sign-in is past the phone stage ("Forget the NAS login first, or set the account back to this PC").
   Failing that, let `forget`, `cancel` and the facts accept a removed account (they only end or read something) and
   keep the brief on removed rows.

4. **MINOR: the pages' last guard on the NAS's words stops only runs of four digits. A password, a phone number
   written in groups of three, and the `Resume` field all pass through.** Confirmed: `TestZZProbeNASWordsEcho` (the
   door's sign-in state with an invented password-like text in `Error`, `Delivery` and `Resume`, and an invented
   number written as `447-700-900-12` in `Refusal`): all four are in the step's answer. Where: `nas.go` 381-383
   (`Resume` goes through unfiltered and is not checked against the stages, unlike `Stage`), 397-422 (`nasFixed`).
   How a person would meet it: only if Core's door or the NAS echoed something typed, which the contract forbids. So
   this is a backstop that does less than its comment and `TestNASNothingTypedLeaks` claim ("Words of the NAS that
   would quote one: replaced"). Smallest cure: map `Resume` through the same stage switch as `Stage`. Count digits
   across separators in `nasFixed` (any 4 digits within 8 bytes). Say in its comment that it cannot catch a password.

5. **MINOR: the address check holds IPv4 addresses to private ones, but takes any host name, which defeats that
   rule.** Confirmed: `TestZZProbeNASAddr`. Taken: `invented-public.example.com`, `127.0.0.1.nip.io` (a public name
   for this PC), `ip6-localhost`, `localhost.localdomain`, `0x7f000001` and `0x0a000001` (one label; some system
   resolvers read these as numeric addresses), `1-2`, `xn--invented`, and the network and broadcast addresses
   `10.0.0.0` and `10.255.255.255`. Refused, as said: port 0, `:080`, `:65536`, IPv6 with or without brackets, a
   path, a scheme, a user, public, loopback, link-local and CGNAT IPv4, leading zeros, short forms, `localhost` and
   `*.localhost`, two colons. A trailing space or tab is trimmed and taken. The check never resolves a name. Where:
   `nas.go` 241-287. How a person meets it: a mistyped or copied name makes the PC dial a host off the home network
   with the NAS link (the pairing's keys should stop a stranger from being the NAS, which I did not verify), and
   `NASAddrWords` suggests that only home-network addresses are taken. Smallest cure: either say plainly in
   `NASAddrWords` that a name is taken as typed and not checked, or take only names with one label or `.local` /
   `.lan` / `.home.arpa` endings, and refuse names with `localhost` in any label and labels starting `0x`. The
   collector should also check the resolved address at dial time (Core's).

6. **MINOR: a HEAD request makes a new pairing.** Confirmed: `TestZZProbeNASPairHead`: `HEAD /api/nas/pair?account=1`
   with the token answers 200 and the fake counts one pairing made, with the body thrown away. Go's `GET` pattern
   also serves HEAD. Where: `nas.go` 189, 668-692. How a person meets it: only something holding the page's token
   (the page, or a tool on this PC) can do it. A HEAD replaces the NAS's pairing without the file reaching anyone,
   and the NAS then has to be paired again. Every other way in is refused: no token, a wrong token, cross-site,
   same-site, `Sec-Fetch-Site: none` (typed in the address bar), another origin (all 403). Smallest cure: answer 405
   when `r.Method != http.MethodGet` in `handleNASPair`. Better, make the pairing a POST that answers the bytes
   (U-1 has to fetch it with a header anyway).

7. **MINOR: a place word the server does not know is shown as "on this PC", and the account's NAS state disappears.**
   Confirmed: `TestZZProbeNASPlaceWord` (the door answers `"NAS"`, a signed-in NAS on no VPN): the facts say
   `"place":"pc"`, and the Overview carries no `nas` field. Where: `nas.go` 549-551 and 936-938. The brief's own
   comment (900-902) promises "fail closed: never shown as on this PC". How a person meets it: only through a door
   that answers another spelling (Core's door is written to the two words), but then the NO VPN line goes quietly.
   Smallest cure: treat any word other than "pc" and "nas" as unread (`NASStateUnread`, with the words), not as "pc".

8. **MINOR: the written door for Core does not match the contract Core reads in two places, and one of its four
   points is stale.** By reading. (a) `NOTE-N4-collector-side.md` line 39 lists `NASState` without `VPNRefused`, but
   the door's plain conversion `livepages.NASState(s)` (report, "What waits for Core's doors", and
   `livepages/nas.go` 33-45) needs it, in that place. If Core builds to the contract, the wiring does not compile.
   The report's point 2 says so, but the contract does not. (b) The pages call `SetNASPlace(acct, "pc", "")` to
   mean "keep the stored address" (`nas.go` 49-51, 636-645). The contract does not say that "" keeps it, so a door
   that stores "" wipes the address when the owner moves an account back to the PC. (c) The report's point 1 ("the
   contract's `NASSignIn(ctx, acct, step, value)` is one value short") is stale: the contract was corrected the same
   day to `step, phone, value`, which the door matches. Otherwise the door is right against the contract and
   `nasproto`: the six functions with the contract's names and arguments, the phone for `send_code`, `resend_code`
   and `code`, the `SignInResult` fields in order without `UserID`, and the state words as `telegram.SignInState`
   words. Smallest cure: add `VPNRefused` (after `NoVPN`) and "addr "" with place pc keeps the stored one" to the
   contract's doors, and drop point 1 from the report.

## Checked and sound
- Nothing typed in any log line: every `logf` reachable from the NAS routes (`nasErr`, the three status, sign-in and
  setting lines) prints a fixed route name and `errClass` (the innermost error's Go type) only. The probes' logs held
  no typed value, and neither did `TestNASNothingTypedLeaks`'s (passes).
- Bodies: every NAS route decodes with `readSecret` (fixed words, unknown fields refused, one object, `maxJSONBody`).
  A 70,000-byte password answers 400 with 79 bytes of fixed words, and a refused address is not echoed
  (`TestZZProbeNASEcho`).
- A door error that wraps a sentinel is answered with the sentinel's own words, never the wrapped text. Any other
  error answers fixed words (500).
- The typed values live only in the handler's locals, and the struct fields are cleared after the check. The kept
  brief holds no typed value. The test fake keeps only fixed words and two booleans. No type at any layer has a
  user-id field.
- The guard: all eight NAS POSTs are in `mutating` and `programOnly`. A cross-site POST, a `text/plain` cross-site
  body, `Origin: null`, a form-encoded body with the token (415) and a missing token are all refused. GET on a POST
  route answers 405. Without the doors every route is 404, and `"nas"` is in no answer.
- The held stop: code, password, status and cancel go on. Place, send_code, resend_code and forget are refused in the
  held stop's words, and so is the pairing (in its handler), with nothing reaching the doors (`TestNASHeldStop`).
- The demo refuses every NAS POST through the guard, and its pairing is an invented file.
- The pairing download: `Content-Disposition: attachment; filename="nas-pairing.pem"`, no path, `no-store`,
  `nosniff`, CORP same-origin. A failed pairing sends no attachment header and no error text.
- The phone is checked twice and compared as digits before anything is sent. The code is digits only, the password
  at most 1,024 bytes. Each step takes the same `signGate` read side as the PC's.
- The address: port 0, ports out of range, leading zeros, IPv6, schemes, paths, users and public, loopback and
  link-local IPv4 are refused (finding 5 lists what is taken).
- The no-VPN line is in the facts, in the place answer, and in the Overview's and the Accounts list's brief whenever
  the status reads (`TestNASFactsEveryState`, `TestNASBriefOnOverviewAndAccounts`). It is apart from the one-word
  state, so "signed in" and "away" do not hide it.

## Not verified
- The real collector's doors (not on the head): what `NASPair`'s bytes hold (whether anything of this PC's, such as
  a path or a name, is in the bundle is Core's), whether `NASStatus` answers memory or an error when the NAS is away
  (finding 1), and whether the steps' door is bounded in time. A step runs on `lasting(r)` (the program's base
  context, no timeout, as the PC's sign-in does) and holds `signGate`'s read side while it runs, so a hung NAS step
  would refuse an account's removal until it ends.
- Whether the pairing's keys stop a host reached through a wrong name from acting as the NAS (finding 5).
- How a Windows resolver reads one-label hex names: not tried, so as not to send a lookup off this PC.
- A panic inside a door: net/http prints the panic's value, which a door could fill with a typed value. There is no
  recover in the pages, as before this piece.
- The front end (U-1): nothing uses these routes yet. The whole `internal/server` package was not run (named tests
  only).
