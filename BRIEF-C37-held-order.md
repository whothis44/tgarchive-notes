# Brief C37: the held tier's order, likely distinct first

For ONE coder (Opus 5.5, high effort), start to finish; ONE independent review follows (it changes which file a lane
takes: the download path's order). Written by the copies session C7, 2026-11-22.

## What the record says (LESSONS-ix12.30-live.md §6c, read it; DIGEST "Copies")
"Rank probable copies by how likely each is distinct, so a spell's spare hours go to the likeliest first: 'no match'
from a frame check (often wrong, answers 8) before 'look-alike', and confirmed copies last; a different byte size or
length before an equal one; within each, the cheapest check first." Today tier 5 (held probable copies) is ordered by
rank, then the not-saved list, then size band (`c_supply_src`, `schema4.go`; rebuilt by K24 and K20: read the view as it
is on 9cb4edc, `supplySrcUnlSQL`). Tier 5 is supplied only with `held_wait` off, or to a released file's lane.

## Where and how (these bind)
- Copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-42`, branch `wip/copies-42` from 9cb4edc. Go commands only
  through `bash /c/Users/trabi/Claude/Projects/Telegram/runs-copies-c37/go1.sh <log> <go args...>`. Named tests and the
  whole of `internal/supply`; NEVER the whole `internal/catalog` or `internal/collector`; a race run of `internal/supply`
  by name through `ix-tools/copies-runs.sh` (Docker) if the walk's concurrent use changes.
- Files: `internal/catalog` (a new schema file for the step, the view's tier-5 key, a stored column on `c_want` kept by
  triggers, `lane.go` only if a walk must name it), tests, the report `archiver/docs/progress/copies-held-order-REPORT.md`.
  A schema step: claim one on the board ("numbered at the merge"), wire it after the newest on 9cb4edc. Commits as
  usual, push `wip/copies-42` to `private`. Invented data only. Never check out anything in the main `repo-archiver`
  tree.

## The change
1. A held probable copy's class, a stored column kept by triggers from what is already recorded (a view may read only
   stored columns): 0 = the frame check said "no match" (`c_probe` result nomatch, C30's mark) or its byte size or
   length differs from the saved file it looks like; 1 = a look-alike or same post with equal size; 2 = a confirmed
   copy (the frames' "copy", the exact check's three-places hold). Say what you chose for each case and why.
2. Tier 5's key: within the same rank and not-saved mark, class first (0 before 1 before 2), then the existing order.
   Every other tier's key unchanged; every walk names `unl` as K20 requires.
3. Nothing else changes: no file becomes wanted, held or skipped by this; only the order among held files.

## Tests
The order of a mixed tier 5 (each class, ranks, sizes); every other tier row for row the head's; the class kept by
every door that writes its facts (a frame verdict, a hold, a release, the owner's words); the step and its fill at
100,000 held rows (chunked if over a second).

## Done
All of it, the named runs and `internal/supply` whole, any race run, gofmt and vet, committed and pushed, the report.
Hand back with the head. Stop at the first thing not as written.
