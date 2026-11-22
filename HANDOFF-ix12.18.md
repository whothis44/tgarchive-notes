# Handoff: after ix.12.17 (published 2026-11-08) — for the session after it

Read with the project memory (MEMORY.md and the files it points to) and HANDOFF-ix12.17.md (rules and tools; all still apply).

## Where things stand

| Version | Tag / commit | State |
|---|---|---|
| ix.12.16 | `v3.4.18-ix.12.16` = 83fc7d1 | live since 11-07 19:33 local; 12.15 ended clean; 0 crashes |
| **ix.12.17** | **`v3.4.18-ix.12.17` = 2176328**, branch `ix/v12.17` (worktree `repo-v12.16`), draft CI-only PR #29 | **PUBLISHED 11-08 ~06:10Z with the user's explicit OK** ("go for launch of 12.17. authorize all needed steps"). Release workflow 42453730080 success, GitHub latest, 8 archives + SHA256SUMS. Install not verified at handoff |

Verify the install: `E:\T\tg-dl\data\crashes\running` shows 3.4.18-ix.12.17 and `history.jsonl` shows 12.16 ended "clean".
At the first start the new index `idx_tgdl_work_open` is built (a few seconds on ~140k rows).

## What 12.17 changed (CHANGELOG.md has the full text)
- Media browser: every listed copy opens; "Shares footage with" opens; `#open=<group>:<msg>` and `#held=<group>` deep links; a filter chosen while a page loaded no longer shows the old results (found by CI).
- Downloads page: held "likely copy" rows link to the saved file. Status bar chip: "N to download · N not queued yet · N held copies" (sums to dlstate ToDownload), click opens Priorities.
- Priorities: one vocabulary that adds up (Files = Saved + Through other groups + Probable copies (held N) + Still needed (waiting / set aside / paused / failed / not queued)), from `ixCoverageWith` + `ixQueueClasses` (cached 2 min, 0.3 s live). Topic box counts (saved/held/waiting/failed/not queued) and the rescan cost on "Add its group to the rescan".
- **Topic ranks: no lane boost, no automatic rescan add** (built, then dropped at the user's call; memory topic-rank-no-requests). Ranking a topic asks nothing of Telegram.
- Report: failed-by-kind merged; `[cpu]` splits system-call time; **queue-limit samples** (`ix_capstat.go`, lines "queue limit of a files pass" and "ranked group's files pass waiting for its lane…", last 6 h, reset at each restart).
- Covering index `idx_tgdl_work_open(status,origin,paused,ttl_seconds,file_size,dc,sched_order,retry_at)` for the 250 ms backpressure counts.
- Rescan tab: quiet time measured server-side, "waiting for room in the download queue", restart-stopped pass keeps its try (max 3 in a row without progress).
- Staging: setting "Copy N files at once" (1-8, default 3; `stageCopies`); a busy staged copy (sharing violation / access denied on Windows) is retried, not set stuck.

## After 12.17 installs: check (report latest.txt, numbers only)
1. [restarts] 0 crashes; [process] CPU (12.16: 114–150%) and reads (12.16: 278–429 MB/s; the new index should cut part of it, not measured); [cpu] `PendingManual` share (12.16: 9%).
2. "queue limit of a files pass" lines after a few hours: idle slot-minutes while a pass waits for room, and how many of those minutes had the speed limit on. That is the evidence for raising the cap of 500 (user asked for it; decide in a later version).
3. Staging line now says "N copies at once". Backlog was 318 GB / 11,729 files at 11-08 03:16Z, copier 18–25 GB/h. The user may raise the setting; compare MB/s per copy an hour later before claiming anything.
4. Failed-by-kind now appears in the per-server time lines.

## Open items
- 2 ranked topics (585 files, 36.3 GB) sit in 2 groups never rescanned (554 and 1,553 archived messages, enabled false, photos/videos/files on): about 44 requests to rescan both. The user can add them (Rescan → Choose groups, or the topic box button); do not do it for them.
- Reads still ~390 MB/s on 12.16 unexplained beyond the backpressure counts.
- Challenger nits not done: topic counts treat every ix_subst row as saved; the per-topic pending `Files` query still runs uncached; GroupToQueue ignores the group's file filters ("up to about").
- Telegram's speed limit was on from 11-07 ~21:00 local (1.4–2.4 GB/h, normal under the limit; 12.16's unlimited hours ran 56–68 GB/h).

## Tools added this session
- `ix-tools/ui.sh WORKTREE [tests…]`: runs the repo's Playwright checks locally (venv `ix-tools/pwvenv`, browsers `ix-tools/pw-browsers`, installed with the user's OK). Invented data only (fake origin http://archive.test); never point them at the live dashboard.
- PRE-PUSH-CHECKLIST.md now also lists `./internal/store` when migrations change.
