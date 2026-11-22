# Independent review of K20, downloads only in hours without the speed limit (Core, K-6, 2026-11-22)

You review `wip/core-unl` at f5e5291f, cut from `wip/core-oldroot` 7cd86537 (K24) with `wip/core-newdl` 3c9c8ae9 (K28)
merged in, in `C:\Users\trabi\Claude\Projects\Telegram\repo-archiver\archiver`. You did not write it; find what is wrong.
Read: the brief `BRIEF-K20-unlimited-hours.md`, the record `NOTE-K20-unlimited-hours-record.md` and `DIGEST-LESSONS.md` in
`C:\Users\trabi\Claude\Projects\Telegram`; the coder's report `archiver/docs/progress/core-unl-REPORT.md` (its six "differs
from the brief" points); then the whole difference against the merge of K24 and K28. **It changes the download path.**

**Where:** a detached scratch copy (`git -C repo-archiver worktree add --detach ../wt-core-unl-review f5e5291f`). Never edit
the coder's copy or a branch; never commit or push. Probes by `go test -overlay`. Every go command through
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go2.sh <folder> ...`. Named tests and the small `internal/engine`
whole; never the whole `internal/collector` or `internal/catalog` (the catalogue's `-run 'Schema|Step'` is fine); no
Docker. Invented data, the fake Telegram only.

**House rules it must keep:** every wait Telegram states is slept in full; under the limit at most 2 parts a server and
nothing learned; a file is never held, set aside or skipped by this (only the pick passes it over); never a walk
proportional to the queue per pick (TRIED-BEFORE 22); a limited lane with only such files reads "waiting for hours
without the speed limit", never "out of supply".

**Look hardest at:**
1. **The mark fails open (the coder's point 1; my first concern):** an "always" chat counts if it collects the file's
   kind, without asking whether a LIVE account reaches it, the topic rule, or the brought-in mark. Since K24, a file is
   collected only through a live account's chats. Show whether an old-app (brought-in) chat or a chat whose topic rule
   leaves the file out makes a shared file download under the limit. Say exactly which conditions `unl` must take to
   equal "no chat that would make this file wanted for a live account is always".
2. **The lane's own "shut" state** (point 2): it shuts at any speed-limit wait and opens only after a clean answer plus 2
   quiet minutes. Can it stick shut for ever (a lane with no probe file, a probe file that is given back or held, a
   restart), or open with no answer? Does a non-`unl` file under the limit still flow at 2 parts?
3. **The probe:** only on a server that is limited, has nothing else in flight and has `unl` files waiting; one part of
   one file per interval; its wait slept in full and stored; its claim's reference refresh counted; never a file marked for
   the exact check or a frame-check plan. Can probes pile up (several accounts, several lanes of one server)?
4. **The give-back at the first speed-limit wait** (point 3): no attempt spent; its checkpoint kept; never a loop of
   claim and give back under the limit.
5. **The key and triggers:** `unl` correct after every change (a chat switched between values, a file gaining or losing
   an always-chat, a chat removed, a brought-in mark, an owner's release); `c_supply` and `c_lane_chat` rebuilt with their
   rows; every walk of `c_supply` names `s.unl` (a walk that doesn't stops at the tier: find any). The pick's cost flat.
6. **Concurrency:** the engine's lane code changed: say what to run under the race detector.

**Report:** `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-K20-unl.md`: verdict first, findings with must / should /
minor, CONFIRMED or PLAUSIBLE, file and line, a one-sentence fix; the probes and their results. Your last message: the
same, short. Remove your scratch copy after.
