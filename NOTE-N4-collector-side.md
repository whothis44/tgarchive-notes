# N4: the PC's side of the NAS downloader (for Core and pages; from the NAS track, N-1, 11-22)

The NAS program is listed (N1 merged; N2 `wip/nas-link` and N3 `wip/nas-program` in `MERGE-QUEUE.md`). What it needs
from the PC lives in Core's and pages' packages, so it is theirs to build (or to take as a lent commit of mine that they
read first: say which). Design: `DESIGN-NAS-downloader.md` sections 1 to 3.

**Core (`internal/collector`):**
1. A stored setting per account, "downloads run on: the PC | the NAS" (default the PC). On "the NAS" the collector starts
   no local lanes for that account and runs `nasctl.Dial` to the NAS (address and the pairing file from settings) with
   the account's real `Supply`, `store.Ledger`, exact `Checker` and `PartStore`; the reference refresh and the exact
   check keep using the PC's own session.
2. **Recover at start must skip files a NAS holds:** `nasctl.HeldInState(path)` works with the NAS down
   (REVIEW-N2-link.md, finding 2: otherwise files being downloaded on the NAS are handed out twice).
3. Wire the catalogue supply's `Finished` and `Duplicate` hooks to `Controller.Finished` and `Controller.Duplicate`.
4. `nasctl.Config.Window`: a `WindowStore` over the collector's `collector.window_proven.<id>` setting (merge by server);
   `Config.Moved` with `store.Moved`.
5. Lent changes N3 asks for (optional, to drop N3's copies): move `collector.LibraryDialer` and its one-client-per-
   session-file hold into a shared package; give `faketg.RemoteDialer` a `Dial` field.
6. The NAS's status each minute (`nasctl` status: engine stats, journal length, tunnel or "NO VPN", sign-in state,
   `SignedOut`, `Permanent`, `Stray`, `WaitingEntry`) into the account's counters and Core's alerts (K22): "the NAS
   away", "VPN check refusing", "signed out by Telegram", "waiting for the PC to take entry N" for long.

**Pages (Accounts and Settings):**
1. Per account: where downloads run; the NAS's address; pairing (writes the bundle for the owner to copy once).
2. Sign-in on the NAS through `Controller.SignIn`: the same steps as the PC's sign-in page (code, two-step password,
   cancel), status from the NAS ("signed in on the NAS", "signed out by Telegram"), and a "forget the NAS login" button
   (one `auth.logOut`, said on the button). Nothing typed is logged or stored on the PC. The user id in the sign-in result
   is never logged.
3. The no-VPN setting on the NAS shown as the PC's gate override is shown: loudly, wherever the state is.

Nothing of this runs against Telegram or on the NAS before the owner starts it; the first real run is the owner's, on
the test account, into a test folder.

## The collector's doors (the contract pages builds against; fixed 11-22 by N-1 with pages' proposal; Core writes them)
Plain types defined in the collector (pages imports no `nasctl`/`nasproto`); per account:
- `NASPlace(ctx, acct) (place string /* "pc" | "nas" */, addr string, paired bool, err error)`
- `SetNASPlace(ctx, acct, place, addr string) error` (default "pc"; nothing dials the NAS until the owner sets "nas")
- `NASPair(ctx, acct) (bundle []byte, err error)` (bytes the page offers as a download; never a path)
- `NASStatus(ctx, acct) (NASState, error)`: Reachable, SignedIn, SignedOutByTelegram, NoVPN, Journal, WaitingEntry,
  WaitingSeconds, Permanent, Stray, AsOf
- `NASSignIn(ctx, acct, step, phone, value string) (NASSignInState, error)` (corrected 11-22 with pages: the NAS's `code`
  step needs the phone and the code): phone (digits) for "send_code", "resend_code" and "code"; value the code or the
  password; steps "status", "send_code", "resend_code", "code", "password", "cancel"; the collector keeps neither between steps; mirroring the PC's sign-in door; the collector adds AppID and
  AppHash itself and passes `Controller.SignIn`; NASSignInState carries the fixed words of `nasproto.SignInResult`
  (state, delivery, code length, resend/wait times, wrong counts, refusal), never what was typed, never the user id.
- `NASForgetLogin(ctx, acct) (NASSignInState, error)`: step "forget" (one `auth.logOut`, then the NAS deletes its login)
Nothing signs in by itself: every sign-in step is the owner's click.
- Added 11-22 with pages' review: `NASState` carries `VPNRefused` (after NoVPN); `SetNASPlace(ctx, acct, "pc", "")` keeps
  the stored address (moving back to the PC never wipes it); `NASStatus` with the NAS away answers the last known state
  with `Reachable=false` (and its `AsOf`), never an error that loses it, so a NO VPN warning never disappears.
- Added 11-22 with Core and copies (for N4's fix round): `NASState` ends with `Held int` (files the NAS holds, from its
  state file) and `UnreachableSince time.Time`; the owner's step "this NAS is gone: give its files back" (a door, the page
  warns those files may download twice if the NAS still runs). No setting of N4's own: Core's alert "nas.holding"
  (Held > 0, unreachable that long) uses the alerts' `alert.after.nas.holding`, default 1440 minutes (Core's point 6).
