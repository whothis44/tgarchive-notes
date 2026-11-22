# NA1: memory of the headless collector and the viewer at the unified archive's size (NAS track, N-1, 2026-11-22)

**On the PC, in Docker (linux/amd64, `--cpus 2`, `--memory-swap` = `--memory`, `--network none`), one run each, on invented
data only** (the project's `fabricate`; the collector's in-process fake Telegram). Harness: `internal/nasdl/na1_measure_test.go`
on `wip/nas-measure` (9826f390), skipped unless `NA1_MEASURE=1`. "Anon" is the container's own memory (Go plus SQLite's);
"page cache" is the file cache the container's figure also counts (reclaimable). MiB throughout.

## 1. The archive (fabricate, 2 accounts, `Reads` on)
- 401,407 messages, 207 chats, 260,929 Telegram media rows, **136,289 distinct files**; states: saved 140,425, wanted 78,319,
  held 25,974, aside 7,165, gone 4,577, skipped 4,469.
- **Catalogue file: 392 MiB.** Written for its previews: 121,898 files, 16.2 GiB (JPEGs for saved photos, posters for saved
  videos; no clips). Took 2,015 s (34 min) on 2 CPUs.

## 2. The collector, headless (`--memory 1g`, `GOMEMLIMIT 900MiB`)
- What ran: `run` as the program runs it (`collector.RunCommand`, in the test binary in the container: the fake cannot be
  reached from outside its process), with the reader, the live monitor, `-auto-mirror -auto-mirror-download`, downloads,
  the copy checks at their defaults, the alerts at their defaults (channels off), the pages on 127.0.0.1. A 60 s setup pass
  stored the fake's chat lists, then 28 chats' reads were approved; then **1,920 s of wall time = 3,840 s of its own clock**
  (fake clock x2), with a live post every 2 s (960: new files, re-uploads, look-alikes), 87 edits, 73 deletions.
- Done: 5,060 part and 1,234 hash requests, 132 history pages; 3,701 files (2.2 GiB) staged, 5,285 files (2.5 GiB) into the
  library. The archive's 78,319 wanted files belong to invented chats the fake does not have: 87,834 reference refreshes,
  then set aside (most in the first 10 minutes).
- **Memory: Go heap in use 20 to 69 (median 48 in the second half); Go's total 120 at most; anon steady 100 to 110, peak
  204.** The container's figure sat at the 1 GiB limit most of the run: page cache 650 to 930 (catalogue and written files).
  Not killed, no panic.
- **CPU: 764 s in 1,920 s (0.4 of a core on average); about 1.7 cores in the first 3 minutes** (the start, the 78k wanted).
- Page cache settings: the writer's `cache_size` 64 MiB; each reader's SQLite default (2 MiB).

## 3. The viewer's server (`--memory 1g`, no `GOMEMLIMIT`, defaults: refresh 1 s, 2 thumbnail makers working ahead)
- **Index built in 2.6 s.** Then: Go heap in use 381, 226 after a GC; Go total 489; **anon 543**.
- Browse: shape 152 ms; 200 blocks of 120 tiles (24,000 of 102,132) in 0.76 s (2.6 ms each, at most 36); 200 item pages
  1.2 ms each (at most 17); 200 thumbnails asked: 163 made within 5.5 s, 37 have no picture.
- **During: Go heap at most 517, Go total 557, anon peak 803**; the container reached its 1 GiB (page cache 130 to 230);
  not killed. After 10 minutes: heap 277, anon 567. About 250 of the anon is outside Go's figures (SQLite's own memory;
  the viewer keeps 4 connections of 32 MiB cache each).
- The makers made a thumbnail for every library file in about 100 CPU s (121,900 files, 17 GiB: the invented JPEGs already
  fit the box and are copied as they are). 96 CPU s in all.

## 4. Both at once (`--memory 1.5g`): not measured
Tried twice; each time the PC's free memory fell under 2 GB within 2 minutes (Docker's VM grew), and the run was stopped.
**The sum instead:** anon peaks 204 + 803 = about 1.0 GiB; steady about 110 + 570 = 0.7 GiB; the page cache is shared.

## Limits I would set on the NAS
- Collector: **768 MiB, `GOMEMLIMIT 512MiB`** (3.7x its measured peak, for real connections and the frame check's queue);
  ffmpeg in its own container at 512 MiB, as proposed. Viewer: **1 GiB, `GOMEMLIMIT 600MiB`, one thumbnail maker**.
  Together 2.25 GiB of the 4.4 GiB, leaving about 2 GiB for the page cache.

## Not measured
The combined container; ffmpeg (not in the container: no fingerprints, frame checks, real thumbnails or video posters);
real Telegram connections (the fake runs in the process: no TLS or MTProto buffers); a mirror being made (no chat was joined);
alerts sent; the VPN tunnel; the NAS's own CPU (slower than this PC's); `GOMEMLIMIT` on the viewer; the owner's real
catalogue (the unified one is expected near 1.9 GB, five times this one).
Left behind: the Docker volume `na1data` (36 GiB: the archive and the viewer's thumbnails), kept for a rerun of (4);
`docker volume rm na1data` removes it.
