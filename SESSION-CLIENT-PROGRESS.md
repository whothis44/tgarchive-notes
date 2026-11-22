# The client track: acting in chats (newest state only; older text in SESSION-CLIENT-LOG.md)

## STATE (A-1, 11-22 09:31)
- **Joined with K22b (head f0323f5b), all runs ok:** A1 3455566c (`made_by` in the stored rebuild SQL, `actSel` one, send again copies it),
  A2 2fecc8e2, A3 9351a8bf (upload worker code byte-identical to the race-clean 099e867c; whole mirror ok 428 s). A3's `TestProbeRealFFmpeg`
  needs ffmpeg 9.0.2 (fails on 7.1.1: the clip not turned): note for its entry.
- K24 (35) and K20 (36) were relisted first: **A1 37 (after K20), A2 38, A3 39.** After the integrator sends that batch's head: merge it
  (keep K24's `brought_in` in `insertClick`, `actAccountLive`, the try-again insert; `-run BroughtIn`), set the afters, `Schema|Step`, relist.
- **The integrator is I-7 (session local_78ac6953-2e70-4c12-a371-4f255f71e85c): listings and reports go to it.** It announces the head after K24/K20 and the step numbers. Queue entries A1, A2 marked NOT READY until relisted.
- Notes for the merges: Core's K24 (with U1) keeps `account.brought_in` = not live in `insertClick`, `actAccountLive` and the try-again
  insert (`-run BroughtIn`); the viewer (B9, U-1) skips look, join, leave, mute rows in the chat box and needs a word for `ActNonePhoto`.
