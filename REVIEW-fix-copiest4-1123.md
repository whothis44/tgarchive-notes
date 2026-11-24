# Review of wip/fix-copiest4 (2f440cf4; fix 64257cf6), 11-23

**Verdict: no logic error. May be merged.** One LOW (existing edges are not corrected) and three NOTEs.

Checked: `git diff 2315335 2f440cf4`, every writer of `c_want`, the two claim paths, the word's two callers, the
step, the pair door and what reads its edges. Ran in a scratch worktree: vet on catalog and supply;
`internal/catalog -run 'Schema|Step|TestSavedPair|TestHeldTurn'` (ok, 57 s); `internal/supply -run
TestSupplyHeldProbeWordTurnMark` (ok). The worktree has been removed.

## Item 1: C30 T4, `c_want.held_turn`

- **Claim paths: correct.** Only two statements in the tree set `state = 'active'`:
  - `claimSetSQL` (state.go:177) writes `held_turn = 0`. It is used by `ClaimWith` for plain, HeldWait, exclude and
    unmarked claims, and so by `ClaimNext` too.
  - `heldProbeClaimSetSQL` (state.go:181) writes 1. It is used only by `heldProbeClaim` (probeheld.go:416), which is
    reached only through `ClaimOptions.HeldProbe` (supply.go:1074, set by `heldTaken`).
  - The two INSERTs into `c_want` (ladder.go:654, staging.go:656) never make a row active and take the default 0. No
    other statement sets `claimed_by` to a value. No code outside catalog writes to `c_want`.
- **Stale 1: harmless.** No give-back clears the column (Release, recoverSQL, Aside, Gone, Saved, the exact check's
  paths). The word reads it only together with `state = 'active'`, and every way into active writes it again. The
  coder's test case "held copy claimed for real, row open" sets a stale 1 first and shows it is overwritten.
- **Give-back, crash, restart mid-turn: correct.** After a restart, recoverSQL takes the file back. Its next claim,
  whichever kind, writes the mark again.
- **The step: correct.** It refuses any version other than 45, adds the column only when it is missing (safe to run
  twice), and existing rows get `NOT NULL DEFAULT 0`. A fresh file has the column, since the supply tests write it.
  No step rebuilds the table and no query selects `c_want.*`.
- **NOTE (word refused across the update): moot.** The step runs at Open, so at program start, after the update. Every
  claim made before the update is given back by recovery. So no turn can be in progress across the step, and the
  "refused, as before C30" case in the step's comment cannot arise. Elsewhere, the refusal the owner sees for a real
  download (`ErrWrongState`) reads "this file has changed state meanwhile; reload the page" (server.go:714). That is
  plain enough, and pressing again after the turn ends works.
- **NOTE (comment drift):** the commit message says "schema step 45, on top of C37's 44". The merge renumbered it to
  46 on top of 45, and the code is right. Fix the wording in the queue entry only.

## Item 2: C32 N1, the door's first branch (videopairs.go:146)

- **The one-sided check is right.**
  - "Same" footage needs most of both copies covered. So a shorter copy held behind a longer one that has more
    pixels lacks little, and a probable copy is only held, never skipped. The owner can release it.
  - A shorter copy with more pixels still holds a longer one within 500 ms. That matches rung 6 (CheapSame within
    DurSlack plus Covers), so the door and the ladder agree.
  - The pixel-equal case where both lengths are in the same whole second and differ by 501 to 999 ms falls to
    related in both branches. That is conservative.
  - The change never flips an edge's direction: it only turns some probable edges into related ones. So no reader of
    `copy_edge`'s direction needs a change.
  - WantAgain's ladder (rung 6) cannot write the dropped probable edge back, because CheapSame needs DurSlack.
- **LOW (existing wrong edges stay).** C32 (e6db2aac) is in the integration branch and has been installed.
  - **What stays wrong:** any probable edge the door wrote before this fix, from a copy longer by more than 500 ms
    to a shorter one with more pixels, stays as it is. `savedPairEdgeSQL` answers "known", so the door never
    rewrites it.
  - **Failing scenario:** a 60 s saved copy whose edge points at a 45 s copy with more pixels. The 60 s copy is lost,
    and WantAgain makes it held behind the 45 s copy instead of wanted. Nothing is skipped and the owner can release
    it, so nothing is lost wrongly; the cost is a file wrongly held.
  - **Fix (optional, later, the copies track):** first a count by the integrator on the read-only catalogue, counts
    only. Count probable edges whose evidence is LIKE 'same footage (%' and where a's duration_ms minus b's is more
    than 500. If the count is not zero, a one-time step turns them into related and re-runs the held rule for any
    row that is held because of them. This does not block the merge.
- **NOTE:** a copy whose duration_ms is 0 (unknown) never counts as "longer", so it can still be held behind
  another. That was the case before this change too, and it is unchanged.

**May be merged.**
