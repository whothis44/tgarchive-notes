# Start of a second, parallel archiver session: breadth (written by the tenth session, 2026-11-14 18:50 local)

Paste into a new session in this project folder: "Read `START-SESSION-B.md` and do what it says."

## Why this session exists

The owner, 11-14: "We're a week into development and we have basically nothing." By the roadmap's own
count 12 features have run for real, 28 exist only against fakes, 24 are not built. All the depth went
into the download path. **This session makes things the owner can open and use, for real.** Another
session (the tenth, then the eleventh: `START-SESSION-11.md`) is finishing the download path at the same
time: do not touch its code.

## Read first
1. `CLAUDE.md` in this folder: the hard rules. The privacy rules matter most here: **never open the
   viewer on real data, never open any real media or file, print counts, sizes and timings only**; the
   old app's folder `E:\T\tg-dl` is read-only and its database is opened only as
   `file:E:/T/tg-dl/data/db.sqlite?mode=ro`. The owner looks at pages and media; you never do.
2. `repo-archiver/archiver/docs/ROADMAP.md`: the sections "Staging and the library", "Bringing the old
   archive in", "The app's pages", "The viewer".
3. `repo-archiver/archiver/docs/TRIED-BEFORE.md` sections 9, 10, 15 and 16 (the viewer and the pages: what
   the owner complained about in the old app), and memory `viewer-feedback-1109`.
4. The last 40 lines of `SESSION-10-PROGRESS.md` (today's rules in the owner's words).

## The owner's rules for how to work (11-14)
- "Don't test needlessly. Get it done then test." A coder gets the few tests its brief names; no mutation
  rituals; a package's tests once when its code is complete.
- Independent reviews only for download-path code and for anything that can lose or overwrite data (the
  bring-in's `run` is one; a page is not).
- "Don't reinvent the wheel unless it actually improves things": the old app's code is on this PC
  (`wt-v12.31`); its viewer was the owner's biggest complaint, its media browser (`/browse`) was fast.
- Fable is architect and judge; Opus 5.5 at high effort codes; several coders at once in separate copies
  when memory allows (measure free memory first; keep about 2 GB free; the other session runs coders too).
- Go: `source ix-tools/env-archiver.sh`. Never write a clock time from memory: take it from `date`.
- Keep a `SESSION-B-PROGRESS.md` from the first action and commit it often.
- "Done" means the owner has opened it or run it.

## The work, in this order
1. **The old archive in the new viewer (roadmap A6 then A7).** This has lasting value after the old
   account is deleted on 11-29, and the viewer is what the owner missed most.
   - The bring-in (`internal/bringin`, `cmd/tgarchive-bringin`: `plan`, `run`, `verify`) has only ever run
     on an invented database with the old layout, and was never reviewed. Run `plan` for real: on the old
     app's database opened read-only as above (or on a consistent copy made through that read-only
     connection into a folder of this session's own, if `plan` needs a file of its own). Counts only.
   - Fix what the real database shows (the layout is at 12.31 now, not the 12.2x the fake was built
     from: read the old app's schema in `wt-v12.31` yourself).
   - `run` writes a NEW catalogue in a folder of its own (never the test catalogue the other session
     uses: `%LOCALAPPDATA%\tgarchive\test`; never anything under `E:\T\`). An independent review before
     `run` runs for real.
   - Then the viewer on that catalogue, with the library on the NAS read-only: **the owner opens it**,
     and says what is wrong. The session checks only that it starts, answers, and how fast (timings and
     counts), never what it shows.
2. **The copy to a test folder on the NAS (roadmap A4)**: only after the other session has merged the
   download path (it touches the collector and the store's neighbours): ask the owner or read
   `START-SESSION-11.md` for the state.
3. **The pages the owner needs to steer it** (Queue: downloading now, just finished, failed with reasons;
   Staging), each shown to the owner as it is built.

## Not to collide with the other session
- Work in copies of your own (`git -C repo-archiver worktree add ../wt-b-<name> -b wip/b-<name> <head of
  claude/charming-feynman-vm2xia>`). Never edit `repo-archiver` itself or any `wt-*` folder you did not
  make.
- Do not change `internal/engine`, `internal/telegram`, `internal/exact`, `internal/supply`, the
  collector's download and counting code, or the catalogue's schema steps 11 and 12 (both in flight,
  unmerged). **If you need a schema step, it is 13 at the earliest: write the number you take into
  `SCHEMA-NUMBERS.md` in this folder first** (create it; the other session reads it before merging).
- **Do not merge into `claude/charming-feynman-vm2xia` and do not push it.** Leave each finished piece
  as a local branch with its report, write it into `MERGE-QUEUE.md` in this folder, and tell the owner;
  the download session merges in order. You may push your own `wip/b-*` branches to `private` so the
  work is safe.
- Nothing against Telegram from this session at all, and never start the collector: the test account
  and its catalogue belong to the other session's runs.
- The viewer and the app need program names of their own for the owner's VPN rule (TRIED-BEFORE 14):
  the viewer must stay OFF the VPN (it reads the NAS).
