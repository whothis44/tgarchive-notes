# Brief NA5: the move of an archive from the PC to the NAS, and back (NAS track, N-1, 2026-11-22)

**Why:** the owner decided ("Yes, as recommended", item 50) that the NAS runs the app and the PC's login MOVES with the
catalogue (no new device on the account; the PC's copy removed; the PC's app refusing that archive afterwards). Read
`C:\Users\trabi\Claude\Projects\Telegram\DESIGN-NAS-autonomous.md` whole; this piece is section 7 and section 4's (A).
**The risk to design out: one login used from two places at once** (Telegram would cancel it: `AUTH_KEY_DUPLICATED`)
and two collectors on one catalogue. This first piece is a command of this track's own plus one small LENT change in
Core's collector; the launcher's button is a later pages piece. **One independent review** (it moves the sessions).

**Rules:** you are the Opus coder. Invented data only (a fabricated catalogue and invented session files: never the
owner's); numbers and fixed words in logs, never a path, key, phone or id. Nothing against Telegram, nothing on the NAS,
never the owner's running app or folders (`C:\Users\trabi\tgarchive-app`, `-next`), anything under `E:\`. Named tests
only in `internal/collector`. Every go command through
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-nas-n1/go1.sh <folder> go test -p 1 -run '<names>' -timeout 20m <pkgs>`.
**Where:** `git -C C:/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add ../wt-nas-move -b wip/nas-move private/claude/charming-feynman-vm2xia`;
commits with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; the collector change as ONE commit beginning "Lent to Core
(collector):"; push only `wip/nas-move` to `private`.

## What to build
1. **`internal/nasmove` and `cmd/tgarchive-nasmove`:** `out -data <the app's data folder> -bundle <a new folder>`:
   refuses unless no collector holds that catalogue (its lock, its staging mark, the watchdog's record: find how the app
   tells), and the counts first (accounts, chats, files, staged files waiting for their copy, put-off read-backs; files
   waiting in staging are listed by count: copy them into the bundle's staging, or say they will be fetched again: pick
   copying, if their bytes fit, and say the size); then a consistent copy of the catalogue (the backup program's way,
   `cmd/tgarchive-backup`: reuse it, no second copy method), the sessions and their key files, the settings, written into
   the bundle with a manifest of SHA-256s; then writes a **moved mark** in the PC's data folder (which archive, when, the
   bundle's manifest hash) and, only after the bundle verified whole, removes the PC's session files (kept, if any step
   failed, and said). `in -bundle <folder> -data <a new data folder>` is the reverse (for the way back, or to set up the
   NAS's folder from the bundle on the PC side before the owner copies it): verifies the manifest, places everything,
   sets the library root to a value given by `-library-root`. `back` clears the PC's moved mark only from a bundle that
   came back from the NAS (its manifest says so). Every step idempotent: a crash part way leaves a state the next run
   finishes or undoes, never two live copies of a session.
2. **Lent to Core (collector):** at start, a moved mark in the data folder makes the collector refuse to run (fixed words:
   "this archive runs on the NAS now"), before it opens any session or dials anything. Test it.
3. **Tests:** a fabricated archive with invented sessions moved out: bundle verified, mark written, sessions removed, the
   PC's collector refuses; a crash injected at each step: the next `out` finishes, sessions never in two live places;
   `in` into a new folder and the collector starting there on the fake Telegram (no Telegram); `back` clears the mark only
   with a returned bundle; a running collector makes `out` refuse.
4. **README** (in `deploy/nas-app`, a short section "Moving your archive to the NAS"): the owner's steps in order with full
   commands: quit the app, `out`, carry the bundle (scp, as the README already does), `in` on... (say exactly where it runs:
   the NAS has no Windows; if `in` must run on the NAS, build it for Linux and run it in the image), start the container.
   And the way back.

## Hand back
On `wip/nas-move`, pushed. Report in at most 20 lines: commits (which is Core's), the steps and their order, what each
test proves, what the owner runs where; then stop.
