# Brief N4: the PC's side of the NAS downloader, a lent commit in Core's collector (NAS track, N-1, 2026-11-22)

**Why:** the NAS program is built (N3, `wip/nas-program` 59388917, which holds N2's link `wip/nas-link` and main
09d63f94; both listed, not yet merged). The collector must now be able to run an account's downloads on the NAS instead
of the PC. This is Core's package; **Core (K-6) asked for it as ONE LENT COMMIT that Core reads before an independent
review** (Core's conditions below are binding). Read first, whole: `C:\Users\trabi\Claude\Projects\Telegram\NOTE-N4-collector-side.md`
(points 1 to 5 and "The collector's doors": the door names are a contract with pages: do not change them),
`DESIGN-NAS-downloader.md` sections 1 to 3, and N2's and N3's packages (`internal/nasproto`, `internal/nasctl`,
`internal/nasdl`).

**Core's conditions:** (1) the collector's `Recover` at start (`internal/collector/collector.go` about line 784,
`sup.Recover()`) skips every file a NAS holds, through `nasctl.HeldInState(path)`, which works with the NAS down; test
it with the NAS up, down, and gone (state file present, NAS never answers). (2) An account set to "the NAS" builds no
local lane and claims nothing locally; its reference refresh and exact check still use the PC's own session.
(3) Default "the PC": nothing dials a NAS unless the owner set it. (4) Named tests and small packages only, NEVER the
whole `internal/collector` or `internal/catalog`; every go command through the lock. (5) The hand-back lists every file
of Core's you touched.

**Rules of the house:** you are the Opus coder of this piece and hand back a branch ready for Core's read. Invented
data only; no name, path, address, key, phone, code, password or id in any log line, error or commit message (new log
lines: constant format strings, numbers and fixed words); never log the user id a sign-in returns; nothing typed in a
sign-in is stored on the PC. Nothing runs against Telegram (the collector's fake only) and nothing touches the NAS.
Never touch a running program, the main copy `repo-archiver`, the owner's folders, anything under `E:\`. **Every go or
gofmt command:** `bash /c/Users/trabi/Claude/Projects/Telegram/runs-nas-n1/go1.sh <folder> go test -p 1 -run '<names>' -timeout 20m ./internal/collector/`
(named tests only there; your own small packages whole are fine). **Where:** from
`C:\Users\trabi\Claude\Projects\Telegram`: `git -C repo-archiver worktree add ../wt-nas-pcside -b wip/nas-pcside wip/nas-program`;
work only in `wt-nas-pcside`. Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the
message beginning "Lent to Core (collector):" and ending `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`;
push only `wip/nas-pcside` to `private` after each step that builds. No stash, no rebase.

## What to build (in the collector, new files where you can: `nas_*.go`)
1. **The place setting** per account (a stored catalogue setting with the house's read/check/set doors, as
   `internal/mirror/autonew.go` does: a value that cannot be read is an error, never the default silently): "pc"
   (default) or "nas", the NAS's address, and the pairing state. On "nas": that account's engine is not started;
   instead `nasctl.Dial` to the NAS with the account's real Supply, `store.Ledger`, exact `Checker` and `PartStore`
   (the same objects the local engine would get), `Config.StatePath` in the app's data folder, the window store and
   `Moved` (point 4), `LocatorCodec` for `telegram.Locator`. Switching back to "pc" stops the NAS's work first.
2. **Recover** as in Core's condition 1.
3. The catalogue supply's `Finished` and `Duplicate` hooks wired to `Controller.Finished` and `Controller.Duplicate`.
4. `nasctl.Config.Window`: a `WindowStore` over the collector's `collector.window_proven.<id>` setting, merging by
   server; `Config.Moved` with `store.Moved`.
5. Core's yes: move `LibraryDialer` (`internal/collector/dialer.go`) and its one-client-per-session-file hold into a
   shared package both the collector and `internal/nasdl` use (drop N3's copy in `nasdl/libdial.go`), and give
   `faketg.RemoteDialer` a `Dial` field (drop N3's test copy).
6. **The six doors**, exactly as named in the note's "The collector's doors", with plain types of the collector's own
   (`NASState`, `NASSignInState`; add `VPNRefused` to `NASState`, from a client state "refused by the VPN check"), for
   pages to call through `internal/collector/livepages` (pages builds that side; you do not edit `livepages` unless a
   one-line seam is needed: say so). `NASPair` makes the key pair with `nasproto.Pair`, keeps the PC's half in the app's
   data folder and returns the NAS's half as the bundle bytes. `NASSignIn` adds AppID and AppHash from the collector's
   own settings and calls `Controller.SignIn`; `NASForgetLogin` is the step "forget".
7. **Tests (fake Telegram, invented data, loopback):** an account on "nas" downloads a set of files end to end through a
   real `nasdl` node in the test (N3's harness shows how) into a temporary library, the catalogue records each once,
   and no local lane ran; Recover with the NAS up, down, gone; the default "pc" dials nothing; switching nas -> pc and
   back; each door, including a sign-in on the fake through the NAS and the forget step; a setting that cannot be read
   refuses, naming the key only; no secret in any log line.

## Hand back
Ready for Core's read on `wip/nas-pcside`, pushed. Report in at most 30 lines: the commit; Core's files touched, one line
each; the doors' signatures; what each test proves and which start goroutines; anything Core or pages must know. Then
stop.
