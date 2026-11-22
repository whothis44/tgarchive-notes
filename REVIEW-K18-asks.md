# Independent review of K18, the small asks (Core), 2026-11-21

Reviewed: `wip/core-asks` 7528e205 against 0942a7dc (K21), in a detached scratch copy
(`wt-core-asks-review`, removed after this report). Read: BRIEF-K18-small-asks.md, the coder's report (both
rounds), the whole difference, and the code each change depends on (settle.go's chunk runner,
mirror_auto.go `autoReads`, mirror_door.go `heldAuto`, the catalogue's mirror tables, store guard.go,
the watchdog's loop and status file).

## Verdict

**May be listed.** Nothing found in K18's own changes is wrong. One SHOULD is outside this piece's
packages (the mirror's per-account tables outlive a deleted account), and it touches nothing live today
(`Catalog.DeleteAccount` has no caller outside tests). It goes to the integrator for the mirror track,
together with the minor notes below.

## Findings

1. **SHOULD, CONFIRMED (not a K18 regression; mirror track): a new account given a deleted account's number
   inherits the old account's mirror rows.** `internal/catalog/settle.go` `deleteAccountChunk` (the list at
   lines 520-529) does not delete `c_mirror_want`, `c_mirror_mark` or `c_chat_made`
   (schema_mirrorauto.go: `account_id` with no foreign key and no cascade). The probe deletes account 1 and
   adds a new account, which gets number 1 again. The new account then has 1 want, 1 never mark and 1
   chat-made row, and `MirrorWantOf(new, chat)` answers a live automatic want. With the switch on, the
   automatic mirror (`autoReads`, the mirror task) would act on a chat the [name removed] never chose. K18 clears
   the settings rows, so the brief's point about the mirror's pause and baseline is met. The rows are not
   settings. Fix: add `DELETE FROM c_mirror_want / c_mirror_mark / c_chat_made WHERE account_id = ?` to
   that list. The mirror track decides about `c_mirror_word` and `c_mirror`, which schema13.go keeps on
   purpose.
2. **MINOR, CONFIRMED (bring-in's keys): `bringin.v1.account` names an account by its value.** If the
   bring-in's account is deleted while a bring-in is under way, a new account given the same number is
   taken as the bring-in's (`bringInCarrying(new) = true` in the probe). This is unlikely, since there is
   no door to delete an account. Fix: `deleteAccountChunk` refuses, or stops the carrying, when the
   account is the bring-in's (chosen.go `bringInCarrying`).
3. **MINOR, PLAUSIBLE (by reading): `-approve-read` now refuses the owner's yes when the held/ended
   judgement cannot be read.** `internal/collector/approve_cmd.go:128`: an error from `endedKindOf` returns
   from `chatStateOf`, and the dialogue says "cannot be read ... not approved". Before K18 that read did not
   exist and the yes went through. Only the words depend on the read. Fix: on an error, keep
   `mirrorHeld` false and use `approveEndedWords` (both lines end the same way: "a yes ... reads on from its
   cursor").
4. **MINOR, PLAUSIBLE (by reading): while the kind cannot be read, the reader says nothing, and it reads
   again at every skip, not hourly.** `internal/collector/reader.go:413`: a failed `endedKindOf` leaves
   `endedKind` unset, so `known` is false at every later skip (the topic loop, the main loop and
   `readGap`, every turn). Before K18 the ended line was said at the first skip whatever happened. What is
   read and what is skipped do not change (the skip returns true in every case), and no request is sent.
   Fix: on a failure, say `readEndedLine` once as before, and cache the failure until the next clock
   hour.
5. **MINOR (wording): "two or three catalogue reads" per judgement.** It is `hasAuto` (free on the
   writer) plus one want read, then `chatFamily` plus one mark read per family member. It is still once
   per chat and clock hour, so it is bounded. Fix: change the words in the comment and the report.
6. **NOTE: what is deleted for good.** If the same Telegram user is later added again under the same
   number, the frozen-method marks (`collector.method_frozen.<n>.*`) and `window_proven` are gone: at most
   one refused request per frozen method to learn each again. This is consistent with `tg_memo` (Telegram's
   waits), which the delete already removed before K18. No Telegram wait is bypassed. Nothing deleted must
   outlive the account.
7. **NOTE: new per-account keys on unmerged branches.** `accountSettings` is a hand-kept list, and
   `TestK18AccountKeysAgree` holds only the four mirror builders to it. A per-account key added later
   (M6, M13 or elsewhere) is missed silently. Fix: one wall test that fails on a new `"<x>." + account`
   builder whose key is not in `accountSettings`, or a line on the board for every track.

## Checked and found right

- **Point 1, the delete:**
  - Exact keys and two key ranges, `[prefix, prefix with its last byte + 1)`, with no LIKE. The closing
    dot keeps account 1 apart from 10, 11 and 100. Keys with bytes above '.' and above 0x7f after the
    prefix are inside the range (probe).
  - It runs in the final chunk, inside the chunk's one transaction (settle.go:155, `tc.applyChunk`)
    together with the account row. A delete cut between chunks leaves every setting in place, and the
    restart's settle finishes it.
  - A grep of every `SetSetting`, raw `c_settings` write and key builder in the tree (collector, mirror,
    catalogue, bring-in, server, copyset, store, telegram, tgstore, fabricate) finds no other account
    key. Mirror waits live in `tg_memo`, which was already deleted by account.
  - Chat keys and catalogue-wide keys are kept (coder's test).
- **Point 2, `Copier.Load`:**
  - `wantMem` is written only under `wantMu`, at every change of `want`/`wantRead`: the read, a failed
    read, the latch set, the count written and the release.
  - A failed read after a good one cannot happen, because `readWant` never reads again once `wantRead`
    is set.
  - Before the first read it is "unread". A latch set in memory but not saved reads as held, which
    matches what the copier does.
  - `Load` takes only `c.mu`, which `HoldStaged` and its release hold briefly. `holdSince` is changed
    only under `c.mu`. `Load` never waits on `wantMu`.
  - No data race by reading. The race run I would make before the merge:
    `go test -race -run 'TestK18Load' ./internal/store/`.
- **Point 3, held or ended:**
  - `endedKindOf` judges held exactly as `autoReads` writes and clears the hold: a live automatic want
    (`EndWhy == ""`, not the owner's). The clear passes over a chat marked never, and so does
    `endedKindOf`, through the same `MirrorMarked` with the migration family.
  - `EndMirror` writes its end word in the same transaction, so a want ended for good reads as ended.
  - A change from held to ended is seen at the next clock hour, then said once.
  - The reader's maps belong to the reader's goroutine only. A race run I would make:
    `go test -race -run 'TestK18ReaderHeldAndEndedLines|TestReadEnded' ./internal/collector/`.
- **Point 4, the watchdog:**
  - `childEnviron` drops an inherited value, in any case on Windows, keeps `=C:`-style entries and longer
    names, and adds one value.
  - `cmd.Env` is built from `os.Environ()`. `-dir` is made absolute after the flags are checked. The
    status file is written in that folder (`writeStatusFile(w.cfg.Dir)`).
  - The collector reads the variable once in `New`. Unset, empty, relative, drive-relative `C:x` and
    rooted-without-drive `\x` all mean "not under a watchdog". `C:\x\..\y` is cleaned, and UNC is
    accepted (probe).
- **Point 5, privacy and other behaviour:**
  - The one new log line (`readHeldLine`) is a constant format with numbers only, and the watchdog's
    refusal is in fixed words. No name, path or id appears in any line or error.
  - Nothing changes beyond the six asks, except finding 3's refusal.

## Probes run (all through `runs-core-k5/go1.sh`, exit 0)

The probe files are kept in `C:\Users\trabi\Claude\Projects\Telegram\review-k18-probes\`. They were
copied into the scratch copy, never committed.

- `internal/catalog -run 'TestProbeK18Rev|TestK18'`: ok, 0.76 s.
  `TestProbeK18RevMirrorRowsOutliveAccount` logs that the new account gets number 1 and inherits 1 want,
  1 mark and 1 chat-made row (a live automatic want), and that `bringInCarrying` is true. The pause key
  and the high-byte read keys are gone.
- `internal/collector -run 'TestProbeK18Rev|TestK18'`: ok. All 8 of the coder's K18 tests pass, and
  `TestProbeK18RevWatchdogDirForms` (the Windows path forms) passes.
- `internal/store -run TestK18`: ok. `internal/watchdog -run 'TestChildEnviron|TestExecStarterHandsDirToChild'`:
  ok.
