# Brief MD: the mirror track's new doors on the pages (Go side) (pages, P7, 2026-11-22)

Same rules as your G16 brief (`BRIEF-G16b-cap-fixes.md`'s house rules: go1.sh, named tests, TEMP etc. in
`C:\Users\trabi\AppData\Local\Temp\p7-md\`, outside any git copy). **Go only: the front end (`internal/server/web`,
`internal/appshell`) is the UI track's (U-1), who draws what you answer.** Branch `wip/pages-mirrordoors`, new copy
`wt-pages-mirrordoors`, from the main head e34f4f64 (it holds the mirror's M14 and M15). Report:
`archiver/docs/progress/pages-mirrordoors-REPORT.md`.

## What to build (read the mirror's M14 and M15 commits on the head first: `git log --oneline -20 private/claude/charming-feynman-vm2xia -- archiver/internal/mirror archiver/internal/collector/mirror_door.go`)
1. **The single-post wait** (`mirror.auto.single_wait`, doors `MirrorSingleWaitFacts` / `SetMirrorSingleWait` in
   `internal/collector/mirror_door.go`, shaped as the cap's): a Settings row's Go side exactly as G16 did for the
   cap: the seam methods, the adapter, the settings answer's field (low and high seconds, stored, default, bounds,
   unreadable, settable, words, cost and when sentences), `POST /api/mirrors/single-wait {"low": n, "high": n}`,
   the guard's lists, the demo fake, tests. Words true of the code (default 5 to 20 s random; no upper bound of the
   app's own).
2. **The new mirror states for a chat** (M14: a chat held with its end time, messages set aside, exact repeats not
   forwarded again; M15: a forum mirrored as a forum: the ChatState fields Forum, TopicsChosenOnly, TopicsCreated,
   TopicsUnknown, TopicsRefused, TopicsRenamed, TopicsHeld, TopicsRetryAt, TopicsSpare, TopicsWhy, TopicsHeldUntil):
   carried from the collector's door through livepages (`convTask`/the state conversion) into the server's mirror
   answers (`/api/mirrors` states, the chat's mirror plan), each with fixed words where a person reads it; the old
   words "A forum is not mirrored yet" (livepages/mirrors.go about line 136) go.
3. **D1's follow-up:** `mirrors_made_24h` says when the cap in force is the careful value because the stored cap
   cannot be read (take NewPerDayInForce's second value: a field `careful: true` with fixed words).
4. Tests for each; the named mirror tests of `internal/server` and livepages; gofmt, vet.

## Hand back
Branch pushed, copy clean; the report with the JSON shapes for U-1. Final message: head, one line of JSON changes, one
line not verified.
