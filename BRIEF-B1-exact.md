# Brief B1: the exact re-upload check before download (ninth session, 11-13 night)

To be moved to `repo-archiver/archiver/docs/EXACT-CHECK-BRIEF.md` once the counter's commit is in. For one
Opus agent in its own copy, made from the branch AFTER the leave-and-count commit (it changes
`internal/telegram` and the catalogue's schema to 10: this piece is schema 11).

## What it is

A wanted file that a saved file matches in exact size is compared with that saved file through Telegram's
own part hashes (`upload.getFileHashes`) before any part is downloaded. Every hash matches: it is the same
bytes, nothing is downloaded, and the catalogue links the Telegram file to the saved file. The old app found
266 to 340 such files a day this way (TRIED-BEFORE 20).

## Read first, in full

- `docs/COPY-CHECKS-STUDY.md` section E (the adopted design; this piece is E.2's last rung and rule R3) and
  section A3 (what the old app does).
- `docs/TRIED-BEFORE.md` sections 6, 20 and 22.
- The old app's code, version 12.30, on this PC (read only, never build or run it):
  `C:\Users\trabi\Claude\Projects\Telegram\wt-v12.30\core-service\internal\app\ix_subst.go` (all of it),
  `...\internal\telegram\ix_parts.go`, `...\internal\download\library.go` lines 250 to 380 (the order of
  steps), and the tests `ix_subst_test.go`, `ix_dedupfix_test.go` for cases.
- The new app: `internal/telegram/hashes.go` (the request layer exists: `Parts.Hashes`, `Parts.Verify`,
  the "no hashes" memo, the window bound), `parts.go`, `internal/engine/types.go` (Supply, RefreshOutcome),
  `internal/engine/lane.go` (claim, markStale, refreshLoop and how each RefreshOutcome is applied),
  `internal/supply/supply.go`, `internal/catalog/ladder.go` (rungs 2, 6, 7), `state.go` (Saved, the
  same-bytes path), `hold.go`, `internal/store/writer.go` (where a saved file's bytes are: staging or
  library), `internal/storeledger`.

## Rules taken from the old app and its history (do not weaken)

1. **Exact means every part hash of the whole file matched the saved file** (or the same file id, or the
   SHA-256 after download, which exist already). Some hashes, or sampled parts, are never exact. The old
   app judged videos of 2 MiB or more on the hashes at the start, middle and end, or on three sampled
   parts: in the new app that evidence gives at most a **probable copy, held**, never a skip (rule R3;
   pre-ix.10.2 a three-place match lost 93 GB).
2. Floor 256 KiB. Candidates: saved files of exactly the wanted file's size, at most 5; for a photo also
   the same pixel size and the same stripped preview bytes.
3. Numbered parts of a split archive (name.part01.rar, .r00, .z01, .7z.001, .001) are all one size and are
   not copies: never candidates on size alone (the old app's `ixPartName`).
4. A bound on hash requests per file (the old app: 64). Over the bound: not exact; see point 6 below.
5. "Telegram cannot tell" (no hashes for the file or its chat: the existing memo; a wait; a timeout; a
   reference error) is **unknown**: the file is downloaded as if never checked, counted by reason. The
   SHA-256 after download still catches same bytes (rung 7). Never held on unknown.
6. A file the owner set to be fetched for real is never checked or matched (the old app's
   `ix_subst_block`): keep a place for that mark, checked before any request.
7. Every hash request is counted (kind `hashes`, already) and goes through the server's file pool (its two
   hash connections, `HashSlots`); a wait Telegram states on one is the engine's to hold, as for a part: no
   request of the check is sent again by the check itself, and nothing sleeps inside the check.

## Design decisions of the main session (build this; say so if the code shows it cannot work)

- **When:** as the first step of the file's own turn, after its reference is refreshed and before its
  first part is asked (rule R7: no separate job). The file holds its file slot and no window slot
  meanwhile.
- **Where:** a new step the lane runs for a claimed file whose `engine.File` says it has same-size saved
  candidates (the Supply sets that from an indexed lookup at `Next`: `tg_media_lookalike` or a new index
  on size where `file_id` is set; a lookup, never a walk; TRIED-BEFORE 22). The engine calls a new
  optional interface (a `Checker` given in `engine.Config`, nil: no check) with the lane, the file and its
  fresh reference; the checker asks hashes through `Parts.Hashes` and reads the saved candidate's bytes
  through the store. Outcomes: `Same` (finish with no download: a new Supply call records the link and the
  exact edge), `Probable` (back to the Supply as held with its evidence, no attempt spent), `Different`
  and `Unknown` (the download goes on). Propose the exact names and signatures in PROGRESS before coding
  the engine side, with the lane states it touches.
- **Reading the saved file:** from its staged copy when it is still in staging, else from the library.
  Only as many bytes as the hashes cover. When the library is away: unknown. Bytes read are counted.
- **Large files:** when the whole file's hashes fit the request bound, compare all: exact or different.
  When they do not: ask at the start, middle and end; all returned windows match: probable, held, evidence
  "same size, and Telegram's hashes at three places match"; any differs: different. The bound is a
  setting-free config field (default 64) until the real number of windows per answer is measured.
- **Catalogue (schema 11):** what the check found per file (outcome, candidate, requests, bytes read, at),
  so a file is not checked twice against the same candidate, and an hourly count per outcome. The link
  for `Same` uses the catalogue's existing exact-copy path (as rung 2 or rung 7 does), with its own rung or
  reason so that it is counted apart.
- **Off switch:** one setting, on by default (the old app's `substExact`), read at start.
- Not in this piece: the same-size wait for a twin being downloaded now (the old app's
  `ixSubstituteWait`), the look-alike rule, sampled frames, kept parts.

## Tests (fake Telegram and invented files only)

- Every hash matches: no part request, the link and the edge are there, the slot is free again, counted.
- One window differs, in the first, a middle and the last window: downloaded; the short last window right.
- No hashes (the memo then spares the next file of the chat a request); a wait on the hash request (held
  by the engine, the check not repeated inside the wait); a timeout; an expired reference: each unknown,
  downloaded, counted by its reason.
- Over the bound: three places match: held as probable with that evidence, never skipped; one differs:
  downloaded.
- Five candidates, the fourth matches. A candidate whose file is missing or shorter. A photo with another
  preview: not a candidate. A numbered archive part: not a candidate. The fetch-for-real mark: no request.
- A kill and a restart between the check and its record: nothing lost, nothing linked twice.
- A held file is never supplied while its lane has a wanted file (the existing rule still holds).
- Mutations, each shown failing: "three places" treated as exact; unknown treated as held; the candidate
  lookup without its size condition; the check's wait slept or retried inside the check.
- The package privacy guard tests still pass: log lines carry counts, sizes, server numbers and fixed
  words only (the old app logged a path here: do not).

## Rules (hard)

- Machine: at most 2 cores, `GOMAXPROCS=2 go test -p 1`, one run at a time; check free memory before a run
  that compiles the Telegram package (under 1.5 GB: wait). No race detector, no Docker, no busy loops, no
  "under load", no whole-repository runs. Git Bash; `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env.sh`.
- Nothing against Telegram. Invented data only. Never read under `E:\T\` or `%LOCALAPPDATA%\tgarchive\`.
- No wait is shortened. No new kind of request beyond `upload.getFileHashes`.
- `docs/progress/exact-PROGRESS.md` after every step; the tree compiles at every pause; no commit, no push.
- Hand back commit-ready with `docs/progress/exact-REPORT.md`: what was built, each rule and decision above
  kept or changed (and why), every test with its mutation, what was NOT verified, the changed files, and a
  drafted commit message with no numbers of any real archive in it.

## ADDENDUM (11-13 late night): the owner's decision on videos, and the review's findings

Read `docs/FEATURES.md` section 12, **thirteenth round**, in full: it is part of this brief now.
- **A video is compared in full** (every window), not at three places; the bound of 64 hash requests no
  longer stops a full comparison. "Three places" survives only as one value of the setting.
- Build, with it, every guard and every count that round lists: the budget per server and hour, the rule
  of three waits, at most two hash requests in flight per server, the per-comparison record and log line,
  the spot check of one skipped file in a hundred with its alarm and switch-off, the library's turn, and
  the setting with three values. Each with a test and a mutation.
- The independent review's findings (`wt-review-exact-scratch/REVIEW.md` in the project folder) and the two
  decisions sent with them still stand (a wait on a hash call holds that server's checks only; where
  "three places" is used at all, it is for video only).
- A held file whose byte size equals a saved file's goes to this check FIRST; nothing else (a frame check,
  later) may release it until Telegram's hashes said "different" (the old app's answers 5: its frame check
  released exact copies).
- Test runs carry `GOMEMLIMIT` and `-timeout`; no test process is left behind.
