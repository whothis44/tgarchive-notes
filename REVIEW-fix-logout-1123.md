# Review: wip/fix-logout c686877e (one auth.logOut after a wrong-user sign-in, note C of 11-23)

**Verdict: may be merged.**

Reviewer: one independent Opus review (code that acts for the owner and sends a request to Telegram). Read the
diff cead58bd..c686877e, the whole sign-in path (signin.go, signin_steps.go, signin_pages.go, signin_cmd.go,
account.go's start rule, libclient's one-client-per-file hold), the NAS door (nas_doors.go) and nasdl/signin.go.

Runs (env-archiver, GOMEMLIMIT=1GiB GOMAXPROCS=2 -p=2): gofmt clean; `go vet` collector, server, faketg: clean;
`go test ./internal/collector -run 'SignIn|Signin|WrongUser|LogOut|TestAddAccount'`: ok (62 s);
`go test ./internal/server -run 'SignIn|Signin|TestAssets|Security'`: ok.
Mutations in a scratch worktree (removed afterwards): log-out not sent -> 4 tests fail (NewRow, Fails, OnRecord,
RecordsNothing); log-out moved after the close -> 3 fail; the on-record guard removed -> the OnRecord test fails.

## Does it do exactly the agreed design?
Yes. Every `ErrWrongUser` of a PC sign-in comes from `recordSignedIn` (signin.go:306/314), which is reached only
through `finishSignIn` (BeginSignIn's auth.sentCodeSuccess, signin.go:133, and signStep's StateSignedIn,
signin.go:255). The pages (Begin/Code/Password via runStep) and the console `signin` command (signin_cmd.go
631/689/705) all call those two. `signedIn` is left only for two tests. The NAS has no wrong-user check (below).
The request: one `AuthLogOut` on `s.conn.Main()`, the sign-in's own connection (no new dial, same gate-checked
client as its auth.signIn), bounded 30 s, no retry, a stated wait not slept and not recorded, sent before
`endSignIn` and before the file's removal. On failure the refusal and the removal stand and the words change.

Can it end a login the owner wants? No case found. `StateSignedIn` is set only from an auth.authorization answer
(telegram/signin.go:561), so at the log-out the connection's key carries the authorization this sign-in has
just made; auth.logOut ends only that key's authorization. The connection is built from `sessionPath(account)`,
the row's own file (catlock.SessionFile per id); nothing in product code copies a session file between rows
(nasmove places a whole archive at the same ids; bring-in requires no file; removal only marks `removed_at`, ids
are not reused). Cases: signed in on record -> BeginSignIn refuses before any dial; signed out by Telegram with
the file kept -> fresh=false, onRecord=false, the log-out goes on the row's old key, whose old authorization
Telegram had ended and which now holds only this sign-in's; removed account -> `c.account` nil, nothing dialled;
brought-in -> no file, fresh. The extra guard (onRecord && !fresh -> nothing sent) is conservative and right.

Success path: record, then close, then nudge. The account loop only dials after the record and a wake; its dial
waits on the file's hold (libclient.DialOnePerFile) until the sign-in's client has ended, so two clients never
use the file at once. What is recorded on success, on a refused step and on a record failure is unchanged.

Log lines: constant formats; only the row number, a fixed error word (`rpc.Type`, no argument) or errWord. Words:
pages and console say "ended" only for LogOutEnded; "not ended"/"not sent" both tell the owner to end it in
Settings > Devices; "" keeps the old sentence.

## MED

**M1. A file the dial wrote is kept when the record says signed in (pre-existing rule, now reachable with a
live other-user login if the log-out fails).** signin_steps.go:370 (`if onRecord`), signin.go:279.
Case: the record says signed in (signed_in > signed_out) but the session file is missing at BeginSignIn (an
archive placed without its session files, a file deleted by hand); isSignedIn is false, so the sign-in runs;
fresh=true; the owner types another account's number; at the finish the dial's new file exists, so onRecord is
true, the log-out is sent (good), but the file is KEPT and the row stays "signed in on record". If that log-out
failed (FLOOD_WAIT, cut connection, 30 s), the row now holds the other Telegram user's live login and the account
loop will start it as this row (no self-id check at the client's start: account.go:364, :634 uses the recorded
id only for the monitor). Before this branch the same case kept the live login always; the branch makes it no
worse, so this is not a merge blocker. Fix (one line, small follow-up): keep the file only when
`onRecord && !s.fresh`; a file the sign-in's own dial wrote is never "this account's own kept session".

**M2. The NAS path has no wrong-user check at all (the coder's claim is confirmed).** nasdl/signin.go:260 marks
the account signed in whatever user Telegram answers; the PC door drops `res.UserID` (nas_doors.go:637-639).
Case: a NAS sign-in typed with another account's number is recorded on the NAS as signed in and runs downloads
for that other Telegram user under this row; note C's second login is then not even refused. Outside this
branch (it left the NAS unchanged, as agreed). Fix as its own piece: the PC compares `res.UserID` with the row's
id and, on a mismatch, sends the NAS's existing "forget" step (one auth.logOut there, nasdl logOut) and says so.

## LOW

**L1. The auth.logOut is counted nowhere.** signin_steps.go:337. `si.Stats()` counts only telegram.SignIn's own
requests (endSignIn takes those in for the hourly table); nasdl counts its log-outs (ar.logOuts). Fix: count it
in the account's counters or add "auth.logOut" to the sign-in's request counts, so the hourly table shows it.

**L2. A cut during the log-out hides the outcome.** signin_steps.go:335 derives the bound from the step's context
(150 s for dial and step, cut by a stop or ForceStop). If the cut comes after auth.signIn answered, runStep has
already answered the page "the answer is lost" (StepCutError) while the goroutine's log-out is cut too: the owner
never sees "end it in Settings > Devices". The stop's 10 s wait for the lock (closeSignIns) can also be outlasted
by up to 30 s, so a program that exits then leaves the wrong user's file under the row (not on record; the next
sign-in of that row reuses its key and would log it out). Rare; suggest a line in the cut words, or noting it.

**L3. Test gaps.** No end-to-end test of the `fresh` read or the on-record guard (only the unit test with a fake
conn), none of the auth.sentCodeSuccess finish, none of the console's `sayLogOut` words. The tests that exist do
prove the per-connection count (account 1's connections and every other connection: 0), success sends none,
failure refuses and removes the file, no retry, no wait slept.

## NOTE

**N1.** `fresh` (signin.go:112) is read before the dial takes the file's hold, so a client of the same file
ending meanwhile could write it after the read. Harmless: by M1's and the case walk's reasoning, the key at the
log-out carries only this sign-in's authorization whatever was on file. An exact alternative is the session
store's own load (empty or not) at the dial.

**N2.** The comment on `signin.fresh` and on wrongUserLogOut says the log-out goes on "its own new key"; for
!fresh && !onRecord it goes on the row's old key (whose authorization Telegram ended). That is right; the comment
should say so.

**N3.** gotd's MTProto layer may resend the same unacknowledged message at the transport level; that is the same
request, as for every sign-in request, not a retry by the app.
