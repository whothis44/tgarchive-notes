# Brief NA1: the autonomous NAS's memory, measured first (NAS track, N-1, 2026-11-22)

**Why:** the owner decided (11-22, "Yes, as recommended") that the whole collector runs headless on the NAS and the
PC's app is its dashboard: `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-NAS-autonomous.md` (read it whole; section 5
is this piece). The NAS has about 4.4 GB available beside Plex (about 2 GB, which stays). Before anything is built, the
collector's and the viewer's memory at the unified archive's size must be known, with the NAS's limits. **Measurement
only: no product code changes.**

**Rules of the house:** you are the Opus coder of this piece. Invented data only: build the archive with the project's
own `internal/fabricate` (wholly invented); never open the owner's catalogue, the old app's data or any real media.
Numbers only in the report (no names, paths of real data, ids). Nothing against Telegram (the collector's fake only),
nothing on the NAS, never touch the owner's running app or folders. Every `go` command through
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-nas-n1/go1.sh <folder> <command ...>`. Docker on this PC: one
container at a time, `--memory` as stated below, `--cpus 2`, keep 2 GB of the PC free (measure first; the PC also runs
the owner's app). **Where:** `git -C C:/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add ../wt-nas-measure -b wip/nas-measure private/claude/charming-feynman-vm2xia`;
any harness you need goes in a `_test.go` file of `internal/nasdl` (this track's package), skipped unless an
environment variable is set; commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, push only `wip/nas-measure` to `private`.

## What to measure
1. **The archive:** an invented catalogue at the unified archive's size: about 400,000 messages, about 150,000 media files
   (the old archive's order of size, `LESSONS.md` section 1), about 200 chats, 2 accounts, with `fabricate`'s `Reads`;
   no media bytes are needed beyond what fabricate writes for its own previews (say what it wrote and how long it took).
   Its catalogue file size.
2. **The collector, headless, in Docker** (`linux/amd64`, `--memory 1g --cpus 2`, `GOMEMLIMIT` 900MiB): started on a copy
   of that catalogue with the collector's fake Telegram, its usual tasks on (the reader, the live monitor, the automatic
   mirror's task, downloads of a few thousand invented files, the copy checks as the defaults set them, the alerts),
   for at least 30 minutes of its own time: peak and steady memory (the container's `memory.peak` and Go's heap in use,
   said apart: the page cache counts in the first), CPU seconds, the catalogue's page cache setting. If the fake cannot
   drive the whole collector outside its test binary, do it in the test binary in the container, and say so.
3. **The viewer's server, in Docker** (`--memory 1g`): started on the same catalogue: memory after its warm index is built,
   the build's time, then during a scripted browse (the grid, 200 item pages, 200 thumbnails asked).
4. Both at once in one container (`--memory 1.5g`) if (2) and (3) together fit; the sum otherwise.

## Hand back
Commit-ready on `wip/nas-measure` (the harness, gated), pushed, and the numbers in
`C:\Users\trabi\Claude\Projects\Telegram\MEASURE-NA1-memory.md` (one page: what ran, how long, the numbers, "on the PC,
in Docker, one run", what was not measured). Report in at most 20 lines, with the limits you would set for the NAS's
containers; then stop.
