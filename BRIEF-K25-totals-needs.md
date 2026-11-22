# Brief K25: the Overview's "Needs you" sums from the totals' own scan (Core, K-6, 2026-11-22)

**Why (pages, P7):** the Overview's "Needs you" (`internal/server/overviewneeds.go`, `needCountsSQL`) counts `c_want` rows
`state = 'held' AND probable = 1 AND keep_held = 0` and `state = 'aside' AND asides > 0 AND reason NOT IN (...)` in one
statement of its own. At 300,000 added files with 60,000 held or set aside it takes 218.5 ms, about as much as the
totals' own scan, so each Overview reading pays twice. Fold the two sums into `catalog.Totals`' scan
(`internal/catalog/stats.go` `Totals`): no schema step, no new index. Target: the two sums cost under 50 ms extra at that size.

**Rules:** you are the one Opus coder. Named tests and small packages only; never the whole `internal/catalog`; every
go command through `bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go2.sh <folder> ...`. Invented data only.
Copy `wt-core-needs`, branch `wip/core-needs` from `private/claude/charming-feynman-vm2xia` (the newest). Commit form
as always; push only your branch. `internal/server` is pages': do not edit it; name the fields for them.

## What to build
1. Two new fields on `catalog.Totals` (name them, e.g. `HeldProbableOpen`, `AsideFailed`), computed in the same scan
   with exactly `needCountsSQL`'s conditions (read it; the reason list is built from catalogue constants: keep one
   definition, exported for the server to drop its own statement).
2. A test that the two fields equal `needCountsSQL`'s answers on invented catalogues (empty, mixed states, the
   excluded reasons, `keep_held`), and a cost test at 300,000 files with 60,000 held or set aside: the totals before
   and after, and the old statement alone, three runs each ("looks like").
3. Totals' other numbers unchanged (its existing tests by name).

## Hand back
`archiver/docs/progress/core-needs-REPORT.md` and your last message, short: head pushed; the field names (for pages);
the times measured; the tests as run.
