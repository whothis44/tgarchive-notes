# Brief M4c-R: independent read-only review of the settle's rewritten rules (2026-11-15, the integrator)

You are a challenger. You did not write this code. One commit on `wip/mirror-auto` is under review: 224a615
(the settle's rules rewritten after an earlier review), as it stands at the branch's head 464e840. The copy:
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-auto` (Go module in `archiver/`). The change:
`git -C <copy> diff d5a4a7c..464e840`. What was asked of the coder: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-M4c-settle-fixes.md`.
The earlier review whose five findings it answers: `wt-mirror-review5-scratch\REVIEW.md` (its probes are in that
folder). The coder's report (`archiver/docs/progress/mirror-auto-REPORT.md`, section "The settle's fix round"):
read it last, trust none of it.

**What a settle is.** A batch of forwards into the owner's mirror channel whose outcome is unknown (no answer, a
server error that carried out part of it, a kill with the request out, a refusal as a repeat) blocks its mirror.
It is settled from what the mirror chat holds, never by sending the batch again. **A wrong "not arrived" puts a
second copy of a message in the owner's mirror; a wrong "arrived" leaves a hole for good.** The automatic task
may settle with nobody present, up to 3 times a day per mirror. When the evidence is not exact the settle must
say "cannot tell" and write nothing.

## Read-only
Edit nothing in the copy. Probes in a scratch folder of your own
(`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review6-scratch`, make it), loaded with `go test -overlay`
(see how `wt-mirror-review5-scratch` did it). Each finding CONFIRMED (a probe shows it) or PLAUSIBLE (reading
only); write each finding into the report as soon as it is confirmed, not at the end. Nothing against Telegram;
never the built command with real settings; never a real catalogue (nothing under `%LOCALAPPDATA%\tgarchive`), a
session file, the API settings file, `E:\T\tg-dl` or media. Invented data only. Go:
`source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`; **the PC is short of memory (under
4 GB free, other sessions compiling): one go command at a time, each with `GOGC=25 GOMAXPROCS=1 -p 1`; only named
tests (`-run`); never a whole-package run of `internal/catalog`, `internal/collector` or `internal/mirror`; no
race detector, no Docker, no `go vet` over packages.** Compile once and reuse (`go test -c` into your scratch
folder, then run the binary with `-test.run`) where that saves compiles. Aim to finish in about 30 minutes: the
merge waits for you.

## What to attack (the files: `internal/catalog/mirrorsettle.go`; the settle turn in `internal/mirror/auto.go`
## `(*turnCtx).settle`; the command's settle in `internal/collector/mirror_settle_cmd.go`; the collector's
## `ReadMirror` in `internal/collector/mirror_auto.go`)
Hunt on your own first; then these, each to be confirmed or refuted by a probe:
1. **The integrator's first suspicion, from reading: "nothing in common with the batch" is tested on whole
   keys.** A message's media key is every `attachment` row of the message joined into one string
   (`mediaKey`), read with no `replaced_at IS NULL`. A mirror message with no forward origin on record is
   "not a forward" when no batch message has exactly its key (`!batchMedia[m.media]`). So a copy that shares
   one media row with a batch message but not the whole set (the source's media was replaced by an edit,
   before or after the forward, so the source holds old and new rows or only the new one; a video whose
   alternative-quality rows are on record for one of the two messages and not the other) is counted "not a
   forward", and with a hidden sender (no origin on its copy) the batch message is then "not arrived" while its
   copy is in the mirror. Confirm or refute for a supergroup source and for a channel's repost of a hidden
   sender; say what the reader records as attachments for an edit and for alternatives
   (`internal/catalog/tgrows.go` `saveOne` and what follows, `internal/telegram/record.go`), and the smallest
   fix you would accept (for example: keys from rows not replaced; "in common" by any single media row, replaced
   ones included; anything in common and untied is unexplained).
2. **The second: the candidates put back carry the same random ids.** `telegram/forward.go` `forwardRandomID`
   derives a forward's random id from the secret, the account, the two chats and the message. After a settle
   tells N messages "not arrived" they are candidates again and the next batch carries them with the same
   random ids. Trace both of the fake's modes (Telegram remembers the ids of a request it carried out in part;
   it does not): what the ledger and the automatic task do, how many requests are sent over 3 hours of the
   clock, whether anything loops, and what the owner can still do for those N messages (is there any way they
   are ever forwarded, or only `-take arrived`, which leaves them missing).
3. **Which read counts, in the automatic turn.** `AutoState.SettlePass` is kept per mirror chat for the
   session and written only when the turn saw "no pass under way". The mirror chat is also read by the
   collector's own reader loop (it has an approval) and its live updates are stored by the monitor. Can the
   time handed to `SettleMirrorBatch` as `BegunAt` be one at which no pass that covers the batch began: a
   stale entry from an earlier batch's settle; a pass begun by the reader's own loop between the batch's
   request and the need time and resumed by the settle; a failed read that saved pages; a restart? Can a
   settle happen from a pass whose first page was read before the need time?
4. Rule 2's "above the ledger's newest copy before the batch": earlier batches whose last messages are
   `missing` (no id), an earlier batch settled by the owner's word, a first batch (nothing before: every
   message of the mirror chat is eligible), an earlier mirror row of the same mirror chat, a forward the owner
   made by hand into the mirror, the owner's own post with one of the batch's media.
5. The origin pass: a source message that is a forward of a post of the SOURCE channel itself; two source
   messages forwarding the same other post, one in this batch and one in an earlier batch forwarded with an
   id; a mirror copy counted "twice"; what `namesPost` accepts.
6. The write: the counts on the batch row, the forward rows, the candidates' order afterwards, the per-hour
   bound's reading of a settled batch, a second settle of the same batch, `-take` in both words, a batch
   "already", a batch "sending" left by a kill; the guard (`MirrorSettleGuard`) when a `waited` or `unsent`
   batch sits between.
7. Are the earlier review's five findings (P1 to P5) really fixed: run its probes again against this code.

## Report
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review6-scratch\REVIEW.md`: lead with what you ran; findings
most severe first, each with file and line, the scenario, CONFIRMED or PLAUSIBLE, and the smallest fix you would
accept; the verdict on suspicions 1 to 3; the earlier five findings (fixed / partly / not); what you found
sound; what you did not check. Counts and fixed words only: the data is invented, keep it so. Final message:
the findings as a numbered list with severity, the verdicts, what you did not check; under 40 lines.
