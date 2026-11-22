# Brief M8 (FINAL, 11-15 22:46, the mirror session M4): a chat known to be protected is refused before any request; the review's low findings

Drafted by session M3 at 20:36 after its full reading; made final by session M4 on the head that holds M5, K4
and M7. **Your copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-protected`, branch `wip/mirror-protected`,
cut from `wip/mirror-timing` f2cedf18** (the main head 4daa0309 with the timing piece on it: this piece sits on
the timing piece because both edit `auto.go` and `mirror_cmd.go`). The Go module is `archiver/` in the copy.

The house rules of every mirror brief apply: read `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-M7-auto-timing.md`,
its first paragraph and its sections "Running things" and "Report and hand-back", and follow them here: one
copy, commit as you go and push only `wip/mirror-protected` to `private` (never the main branch, never `origin`),
nothing against Telegram, invented data and the injected clock, no name, text, id or link in any log, error,
printed line, test name or commit message, constant format strings, named tests only (`-run`), one go command
at a time (`source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, `GOGC=25 GOMAXPROCS=2`,
`-p 1`), the PC measured before each go command (wait under 2 GB free or over 85% CPU). Commits:
`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
**No schema step, no goroutine, lock or channel, no file of `internal/telegram`, `internal/reader`,
`internal/engine` or `internal/server`.** If you find you need one of those, stop and say so in your report.

## What is asked (FEATURES 12 round 1: "chats that block forwarding reported, not retried"; review M4-R finding 7)
Today a protected source is known only after Telegram refused a forward (`chat.fwd_restricted_at`,
`MirrorSourceFacts.Protected`, `schema13.go`): the command's plan sends a create and a forward first; the
automatic task reads the whole chat, creates a channel and forwards once, and an empty channel is left in the
owner's account and counts against the day's cap (probe of review M4-R: config 1, create 1, forward 1
refused). Core's K4 (schema step 19, merged) records the chat list's own flag at no request: `chat.protected`
(NULL not known, 0, 1).

## What the old app and the record know
The old app never forwarded (it uploaded files again, so that protected chats "still work": FEATURES 12 fourth
round); it has nothing to port. On record: `CHAT_FORWARDS_RESTRICTED` is Telegram's answer for such a chat
(documented; never met for real: the test mirror's source was not protected). TELEGRAM-FACTS 11 lists "what a
protected source does" as not known. TRIED-BEFORE 24, rule 9: no request for an item that will never be acted
on; rule 3: a mark is checked again before every request; TRIED-BEFORE 25, rule 13: fail closed, a value that
cannot be read never reads as "not protected". LESSONS-ix12.30-live 6b: what the app does by itself stays
visibly the app's (here: a chat it leaves is counted and said, never silently dropped).

## Checked on f2cedf18 by me (M4), so you need not search
- The doors, `internal/catalog/schema_protected.go`: `ChatProtected(ctx, chat) (protected, known bool, err)`
  (`ErrNotFound` for no such chat) and `ProtectedChats(ctx, account) ([]int64, error)`. On a read-only handle of
  a file older than step 19 both return an error with the words "file has schema v%d, this program reads v%d"
  (built with `fmt.Errorf`, no sentinel: **if you need to tell it from another error, do not match its text:
  ask `FileSchema` yourself first, or stop and say that a sentinel is wanted from Core**). A read-write handle
  always has the column.
- The flag is known for a chat or channel the chat list sent whole (`internal/telegram/dialogs.go`,
  `ProtectedKnown`); not known for the short forms. So "not known" is rare after a chat list stored whole.
- `autoCheck` is `auto.go:1038`; it ends a want with `catalog.MirrorEndProtect` when `src.Protected` (the
  refusal's memory). `Look` is `auto.go:217`; `LookResult` has `Forums` and `ForumChats` as the model for a
  counted, said-once kind. The plan blocks with `WhyProtected` at `mirror.go:521` and `:555`.
- `MirrorAllow` is `schema_mirrorauto.go:422`: read what it does with an end of `MirrorEndProtect` and write it
  in your report; do not change it without saying.
- Board message 43 (b) is NOT done on this head: the plan's line "messages that may still be forwarded: N (…)"
  (`mirror_cmd.go:1018`) says nothing of album members without a media row.
- `AutoNumbers` (`auto.go:397`) has `CaughtUp` and, from M5, `CreatesHeld`; `CaughtUp++` is at `:783`.

## Part A: the plan (the owner's `mirror -chat N`; `internal/mirror/mirror.go` `MakePlan`, the command's words)
- Known and protected: the plan is blocked with fixed words (the existing `WhyProtected`, said with "as the chat
  list last said", so that it can be told from a refusal Telegram gave), before the yes; nothing is dialled,
  read or created; the per-day and 500 counts untouched.
- Known and not protected: one plan line says so ("the chat allows forwarding, as the chat list last said").
- **Not known** (NULL; or a file older than step 19 on the plan's read-only handle): one plan line in fixed
  words: "whether this chat allows forwarding is not known (the chat list has not said): if it does not, this
  step costs one create and one refused forward". Never said as "allows". The step goes on as today.
- Any other error of the door: the plan fails closed (nothing sent), as its other reads do.
- The flag is read again at the step, after the yes and before the first request (a chat that became protected
  between the plan and the yes sends nothing; the words say why).
- A source the refusal's memory already marks (`src.Protected`) keeps today's words and path.

## Part B: the automatic task (`internal/mirror/auto.go`)
- `Look`: a chat known to be protected is left: no want, no approval of its read (so the reader never reads it
  for the mirror); counted (`LookResult.Protected`, with its chat numbers for the collector's once-a-session
  line, as forums have); weighed again at every look, so a chat whose owner allows forwarding later is taken
  then. A chat whose flag is not known is taken as today and counted (`ProtectedNotKnown`), said in the look's
  line in fixed words.
- `autoCheck` (read before every request for every want): known and protected ends the want with the existing
  `MirrorEndProtect`, before the read's approval is used further, before any create or forward, also for a
  mirror that already exists (its next forward would be refused). The owner's `mirror -allow` is the way back,
  as for every end: when the flag still says protected after an allow, the want is ended again at 0 requests
  (a test), never a loop that sends.
- A door error is this side's failure for that chat: passed over this turn, nothing sent for it (the existing
  path for a failed read; say which path you used).
- The order in `autoCheck` stays: the owner's "never" mark first, then left, then protected (either source).
- **A count for a mirror whose batch is held (the timing review's F5, known and left in M7):** a want whose
  batch is held this turn by the gathering is counted in a number of its own in `AutoNumbers` (`Gathering`),
  not as `CaughtUp`; the collector's numbers line gains it in fixed words. Nothing else of the timing changes:
  no time, no key, no wake.

## Part C: the second review's low findings (`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review8-scratch\REVIEW-2.md`, section 5 and "Notes")
- N1: `plainText` (`name.go:121`) also refuses categories Co and Cn, U+FFFD, the fillers U+115F, U+1160,
  U+3164, U+FFA0, U+2800, U+034F, and a separator made only of marks (Mn, Me). The check's test gets the
  reviewer's 11 characters.
- N2: a separator whose last rune is a digit is refused (fixed words).
- N3: `BaseFor` (`name.go:206`) trims spaces at the cut end, and at the start when the prefix is empty or ends
  with a space. **A rule stored before this change must still read back** (`ReadNameRule` compares byte for
  byte): N1 and N2 tighten the CHECK for a new rule or name only; a stored rule that the old check let through
  is still read and used (say in the report if you find that cannot hold, and what you did).
- N4: `lostInBatch` (`catalog/mirrorsettle.go`) is also true when any earlier "missing" message has no
  message row.
- N5: `rename.go`: `ErrMirrorNameTaken` from the record after Telegram's answer is said with the words of a
  taken name and "the channel was renamed at Telegram; the record keeps the old name: rename it again", never
  as "the catalogue failed".
- N6: `MirrorNameOnRecord` (`mirrorsettle.go:861`) counts only channels with `mirror_of IS NULL`.
- N8: `-never`, `-allow`, `-list` refuse every other mode's flag in fixed words instead of dropping it.
- N9: a plan blocked by an album too large does not print "in this batch: 0" as a counted number.
- Board message 43 (b): the plan's "messages that may still be forwarded: N" says in fixed words that album
  members without a media row are counted in it.

## Files
`internal/mirror` (`mirror.go`, `step.go` if the step's second read sits there, `auto.go`, `name.go`,
`rename.go`), `internal/catalog/mirrorsettle.go` (N4, N6: the mirror's own queries),
`internal/collector/mirror_cmd.go`, `mirror_auto.go` (the look's and the numbers' lines), their tests. Core's
`schema_protected.go` and the chat facts: read only. The test rigs may set `chat.protected` through whatever
the chat list's store path offers (find how K4's own tests set it); do not add a product door to write it.

## Tests (named; each rule's test seen to fail once with its line undone, and said so in the report)
Plan: protected known (blocked, 0 requests, nothing written), not protected (the line), not known (the line; the
step as today), an older read-only file (not known, no SQL error printed), protected between plan and step (0
requests). Task: a joined chat known protected (no want, no approval, no read, no request; counted; said
once); it becomes unprotected (taken at the next look); a want whose chat becomes protected before its create
(ended, 0 requests) and with a mirror (ended, no forward); allow while still protected (ended again, 0
requests); not known (taken, counted); the gathering count (held: `Gathering` 1, `CaughtUp` 0). Part C: one test
per item; the reviewer's probes as tests where they exist (`zz_m8probe_test.go`, `zz_m8cat_test.go` in
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review8-scratch`). A stored rule the old check allowed still
reads (N3's note).

## Running things, and the end
While working: only the tests you add or touch, by name. At the end, once, one at a time: whole
`internal/mirror` (about 100 s); `internal/catalog -run 'Mirror|Protected'`; `internal/collector -run 'Mirror'`
(about 3.5 minutes; `TestMirrorAutoReaderGoesOn` is known to fail now and then under load: run it by name again
and write the load); `cmd/tgarchive-collector`; gofmt and vet on the three packages. No race detector. Report:
`archiver/docs/progress/mirror-protected-REPORT.md` on the branch (what was built per part, every departure
from this brief with its reason, each rule line undone and the test that caught it, the runs with their
numbers, what was not checked), the branch pushed, the copy clean, the final commit named in your last message.
