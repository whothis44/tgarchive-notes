# Brief E17: the graphics card as the decoder, with the CPU as the fallback; ffmpeg found beside the program (copies track, session C3, 2026-11-16)

The owner, 11-16, on the frame check and the fingerprints: "The old app used my 5070ti to do this much quicker,
with the cpu as a fallback. Here, we need that option as well, as well as the standalone nas version."

For one Opus coder at high effort, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-17` on branch
`wip/copies-17` (made for you from the main head 29bcfa2e; change no branch, merge nothing). Go module in
`archiver/`. Commits as work goes (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, messages
starting `WIP copies: `, ending with a blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`),
pushed with `git push private wip/copies-17`; never `origin`, never the main branch, never a force-push.

**You change `archiver/internal/footage/ffmpeg` and `archiver/internal/vfp` and their tests, nothing else.** Not
the collector (its flags are written down by you for the main session's board message), not the catalogue, the
supply, the store, `internal/probejudge` (it does not exist on your branch; it takes your runner through an
interface and needs no change).

## What the old app already knows (its code and numbers; read before the code)
Read, read-only: `C:\Users\trabi\Claude\Projects\Telegram\wt-v12.31\core-service\internal\app\ix_vdup.go` lines 570
to 770 (the fingerprint's ffmpeg call, the decoder setting whose default is `cuda`, the rule for blaming the
card) and `ix_copies_sample.go` lines 473 to 536 (one sampled frame: one process, one thread, **no hardware
decoder**). In `archiver/docs`: `COPY-CHECKS-STUDY.md` B ("Saved fingerprints") and E.7; `TRIED-BEFORE.md`
section 6 ("A GPU decode failure on a broken upload switched the whole index to the CPU (12.13 fixed)").
- **The old app used the card for the fingerprints of saved videos** (the whole video decoded at 2 frames a
  second; `cuda` by default, the CPU when the card fails; 82,586 videos fingerprinted that way) **and the CPU
  for the sampled frames of a check** (one key frame a process).
- Its rule for blaming the card (12.13): a card failure counts only when the CPU then reads the file; three
  such files and the rest of the run uses the CPU. That rule is ported (`ffmpeg.GPU`, `FingerprintWith`): keep it.
- **Measured tonight on this PC** (invented clips of 40 s, ffmpeg 9.0.2, two rounds, the PC busy at about 88%
  CPU with other work, so "looks like"):

  | | CPU | `cuda` | `d3d11va` |
  |---|---|---|---|
  | whole clip at 2 frames a second, 1080p H.264 (2 threads) | 2.8 to 3.2 s | 1.3 to 1.6 s | 1.7 to 2.2 s |
  | whole clip at 2 frames a second, 2160p HEVC (2 threads) | 16.0 to 17.8 s | 3.4 s | 6.0 s |
  | 8 key-frame reads, one process each, 1080p H.264 | 1.5 to 1.7 s | 2.3 to 2.4 s | 4.3 to 4.4 s |
  | 8 key-frame reads, one process each, 2160p HEVC | 3.7 to 4.6 s | 2.0 to 2.3 s | 3.2 to 4.2 s |

  So for a fingerprint the card is about 2 times quicker at 1080p and 5 times at 2160p: **the card is the
  default there, as in the old app**. For a check's single frames the card costs about a tenth of a second
  more a frame at 1080p (its start-up) and saves about a quarter of a second a frame at 2160p: **the option is
  built, its default stays the CPU**, and the main session adds "the card for large frames" once the judge
  knows a video's pixel size.
- Today in the new app: `Runner.Fingerprint(ctx, path, hwaccel)` and `FingerprintWith(ctx, path, *GPU)` exist
  (the card as an option, the CPU when it fails, the thread bound with either); the fingerprint worker's
  `Config.HWAccel` takes one decoder word, default the CPU. The sampler (`Sample`, `Check`, `readRound`) has no
  decoder option. ffmpeg is looked for by `Config.Path`, then `FFMPEG_PATH`, then PATH.

## The state today (read first, in full)
`internal/footage/ffmpeg`: `ffmpeg.go` (`Config`, `New`, `find`, the whitelists), `fingerprint.go` (all),
`sample.go` (how one frame's process is built and what each way it ends means), `check.go` (what a second call
resumes), `selftest.go`, `category.go`, `rangeserver.go`, `hide_windows.go` and `hide_other.go`.
`internal/vfp/vfp.go`: `Config`, `New`, the self-test's place, how `gpu` is used, `Stats().Report()`.

## What to build
**1. Which decoder: the word `auto`.** A decoder choice is one of: `""` or `cpu` (the CPU), a decoder word as
ffmpeg's `-hwaccel` takes it (`cuda`, `d3d11va`, `vaapi`, ...), or **`auto`**: the first decoder of a short list
(`cuda`, then `d3d11va`; a `Config` field, so that a build for another machine can name others) that passes a
self-test on this machine, else the CPU. The decoder's self-test: the package's own fabricated clip decoded
with that decoder gives the frames the CPU gives (within the fingerprint's own tolerance), inside a short
limit; run once per runner and decoder, its answer kept. **On a machine with no card (the NAS, a Linux
container) `auto` ends on the CPU by itself, with one counted, fixed-words line and no error.** ffmpeg may fall
back to software by itself when a card decoder cannot start: the frames are right either way, so a report
says the decoder "asked for", never claims the card "was used", unless you can tell it from a typed fact
(not from words in ffmpeg's text).
**2. Fingerprints.** `vfp.Config.HWAccel` takes `auto` (and `cpu`); the worker resolves it once through the
runner's self-test and then works exactly as with a named decoder (the `GPU` blame rule, the thread bound,
the CPU when the card fails on a file). `Stats().Report()` says which decoder was asked for, how many videos
were read with it and how many fell back to the CPU, and the seconds of video read per second by each (so the
first real run says what the card brings). The default in `vfp.Config` stays the zero value (the CPU) so no
existing caller changes; **write down for the collector that its flag's default becomes `auto`**.
**3. A check's frames.** `ffmpeg.Config.SampleHWAccel`: the decoder asked for a sampled frame's process (the
same words; default the CPU, as measured). A frame's process that fails or times out with a card decoder is
run once more on the CPU before it counts as that frame's failure (the same blame rule as fingerprints, on the
runner: three frames the CPU read after the card failed and the runner samples on the CPU from then on;
counted). **Nothing about what a frame means changes:** a frame read with either decoder goes through the same
`showinfo` time, the same scale and hash; a named test shows that the eight frames of an invented clip hash
within the fingerprint's own match distance with the CPU and with a card decoder (skipped with a counted
reason on a machine where no card decoder passes its self-test), and that `Check`'s outcome on the package's
existing end-to-end clips is the same with both. Statuses, categories, `Missing` parts and the resume are
untouched. `Result` (or the runner's counters) says how many processes ran with a card decoder and how many
were run again on the CPU.
**4. ffmpeg beside the program** (the integrator's rule for the one program with its folder, board message
40 c; listed and unbuilt in this track): `find` looks first in the program's own folder (`os.Executable`'s
directory, with links resolved: `ffmpeg.exe` on Windows, `ffmpeg` elsewhere, also in a `tools` folder beside
the program), then `Config.Path`, then `FFMPEG_PATH`, then PATH; and PATH is split by hand so that an entry
with a stray quote character does not hide the entries after it (board message 22: on this PC Go's own
lookup reads 37 entries as 18). A test with temp folders for each step of that order; nothing depends on the
folder the program was started from.
**5. The NAS.** Everything above builds and passes its tests without a card and without Windows: no new
Windows-only call outside `hide_windows.go`; `GOOS=linux GOARCH=amd64 go build ./internal/footage/... ./internal/vfp/`
stays clean (run it at the end). In your report, one paragraph for the main session on what a headless
fingerprint pass on the NAS would need from these two packages (it is a later piece: do not build it).

## Rules that bind every line
A decoder is a speed choice, never a verdict: no status, category or outcome may differ because of it, and
a card that fails is the CPU's turn, never "no match", "unknown" or a failure row by itself. Arguments stay
fixed lists with no shell; a decoder word is a plain word (`hwaccelOK`), `auto` and `cpu` are yours. Logs,
errors and counts: numbers and fixed words, never ffmpeg's own text or a path. Invented clips only. No test
judges on real seconds; a test that needs a card skips with a counted, stated reason where none passes its
self-test, and the same test must pass on this PC with `FFMPEG_PATH` set (the second line `where.exe ffmpeg`
prints).

## Tests and runs
`source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then in `archiver/`:
`GOGC=25 GOMAXPROCS=2 go test -p 1 -count=1 ./internal/footage/ffmpeg/ -run '<names>'` (and `./internal/vfp/`).
Named tests while working (the whole ffmpeg package takes about 3 minutes with the real ffmpeg: once, at the
end, in the background; `internal/vfp` whole once at the end). Before each go command look at the free memory
and the CPU's load and wait a minute when memory is under 2.5 GB or the load is over 85%; never two go
commands at once; no race detector, nothing in Docker, no `go vet` over the tree (vet and gofmt on your two
packages). Mutations: say which rules you broke on purpose to see a test fail (at least: a card failure taken
as the frame's failure; `auto` not ending on the CPU where no card passes; the program's folder not looked at
first; the blame rule's count).

## Hand-back
Commit-ready on `wip/copies-17`, pushed, the copy clean. A report
`archiver/docs/progress/copies-gpu-decoder-REPORT.md` and a progress file beside it kept current with times
from `date`: what was built, the names, the tests and which ran with a card decoder on this PC, **your own
numbers for the table above measured through the package** (seconds a fingerprint and a check take with each
decoder on invented clips, with the PC's load at the time), the mutations, the collector's flags and their
defaults written down, the NAS paragraph, departures and doubts. Your last message to the main session: the
head commit, then at most 25 lines.

## Decided by the owner, 11-16 00:25 (written 00:26): "For the cpu/GPU, auto fallback, with default to gpu then cpu, but also manual. Of course option to pass to and interface/control with the standalone NAS app as well."
This replaces the brief's "its default stays the CPU" for a check's frames:
- **The default is the card first, then the CPU, for both kinds of read** (fingerprints and a check's frames):
  `auto`. **Manual stays:** `cpu`, or a named decoder word. Inside the packages the zero values still mean
  the CPU (no existing caller changes); what you write down for the collector is that **both flags default to
  `auto`**. (The measurement stands as a fact in your report: at 1080p a single frame's read is a little
  slower on the card; the owner chose the card first, which also frees CPU cores. Your own numbers through the
  package go beside it.)
- **"Try again and reset ffmpeg or fallback to CPU":** a runner asked for a card decoder never ends "not
  working" because of the card: its self-test with the card failing is followed by the CPU's, and passing on
  the CPU the runner works on the CPU (counted, said in its state) until it is made anew (the judge and the
  fingerprint worker make a runner anew every minute while ffmpeg is failing: with a new runner the card is
  tried again). A named decoder (manual) that fails falls back the same way: manual chooses what is tried
  first, never "fail rather than use the CPU".
- **Every option is a plain value another program can be handed** (the standalone NAS app takes the same
  options, set and read from the PC): decoder words, numbers, no function-typed setting; the runner's and the
  worker's state and counts are plain data with fixed lower-case JSON field names; your report lists every
  option of the two packages with its words, default and range in one table for the main session.

## Decided by the owner, 11-16 00:51 ("Your recommendation"), after the measurement through the package
A check's 8 frames took 0.84 s (1080p) and 0.96 s (2160p) on the CPU against 1.3 s and 1.4 s on `cuda`
(each frame is its own short process and the card's start-up costs more than its decode saves). So:
**the default for a check's frames is the CPU; the card first (`auto`) stays the default for fingerprints;
either can be set by hand to `auto`, `cpu` or a named decoder.** Nothing changes in the two packages (their
zero values already mean the CPU): the collector's flag `-check-hwaccel` defaults to `cpu`, and
`-fingerprint-hwaccel` to `auto`. The report's flag table on the branch still says `auto` for both: the
collector's lines follow this section.
