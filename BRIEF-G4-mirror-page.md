# Brief G4: mirroring a chat from the Chats page (pages track, session P3; 2026-11-15 23:40)

For one Opus coder. The owner, 11-15 23:20: "add in a functioning mirror option since that is immediately
useful and we've tested it." Roadmap rows "Choosing chats to mirror by multi-select on the Chats page" and the
mirror's settings' place on a page. **Read first, in full:**
`C:\Users\trabi\Claude\Projects\Telegram\DESIGN-G4-mirror-from-page.md` (what the owner is told each click
sends: your page must make every line of it true) and board message 75 in
`C:\Users\trabi\Claude\Projects\Telegram\BOARD.md` (the seam agreed with the mirror track; read any answer of
the mirror track under it: where its answer changes a name or a field, its answer wins and you say so in the
report).

## What is known already (read by the main session)
- **The mirror exists and ran for real** (the test account, 11-15): the command `mirror` shows a plan and after
  a yes creates one private channel and forwards in batches of up to 100; a batch whose outcome is unknown is
  settled by reading the mirror chat; the automatic task (`internal/mirror/auto.go`: `Look`, `Turn`; the
  collector's `mirror_auto.go`) does the same inside the running program, at most one request a turn. The
  mirror track owns all of it. **This piece sends nothing and adds no request:** it records the owner's wish
  through the mirror track's door and shows the task's state.
- **The old app's rules for anything that acts for the owner** (TRIED-BEFORE 24 and 25, thirteen rules; the
  ones a page can break): a person's pause is its own state and nothing undoes it; a "never" mark per chat is
  checked before every action; one lock for every writer of a stored set, or one row per item (two clicks at
  once lost 81 of 150 "never" marks kept as one list while every request answered 200); a mark that cannot be
  read stops the step and never reads as "empty"; one item per call, each result recorded; a cap per step.
- **The old app's interface lessons** (TRIED-BEFORE 10, 15, 19): one row per chat in one place with one
  vocabulary; every number says what it counts; a state says why in plain words; a page that could not
  refresh said "no progress for 55 min": show the age of the data; a control in one place only.
- **Today's two reviews of this track's pages** (`REVIEW-G2-queue.md`, `REVIEW-G3-signin.md`), as rules to
  build to from the start: a reading says when it was read; the numbers on one page add up; after the owner's
  own click the clicked region shows the result at once and a button is disabled until its answer is painted;
  the keyboard's place after a click is the next control of the same kind, found by the row's key; an action
  over a set is bounded and is one item per call; a refusal never offers the same request again without saying
  it is one; "approve" can never approve a cost the owner was not shown.

## What to build (`internal/server`, its scripts, one adapter file; nothing in the mirror's packages)
1. **The seam `Mirrors`** in `internal/server` (a new file; `internal/server` imports neither the collector,
   Telegram nor `internal/mirror`: the wall test stays), exactly as board message 75 lists it: the task's
   state and the "mirror chats I join" switch; a plan for one chat as data; the owner's wish for one chat with
   the plan's token the page showed; stop; the state of every chat of an account; never and allow; the
   settle's choice; the name rule and the gathering. Nil in `tgarchive app` and whenever the collector does not
   give it: every control then carries `data-needs-program` with one sentence.
2. **A fake of the seam for the tests and for the demo** (`tgarchive app -demo` shows invented mirrors in every
   state), and **the adapter** `internal/collector/livepages/mirrors.go` written against a small interface of
   the collector that DOES NOT EXIST YET (the mirror track builds it to message 75): the adapter compiles
   against the interface, is tested with a stand-in, and `pages.go` hands it over only when the collector
   implements the interface (a type assertion; until then the seam is nil and the page says the mirror is used
   with the command). Do not write the collector's side.
3. **Routes**, all inside the guard, POST for every change, `no-store`: the plan (a read: GET), the wish, stop,
   never and allow, the settle's choice, the switch, the two settings. One chat a call; "Mirror the chosen
   chats" is the page calling the wish once per ticked chat, in order, stopping at the first refusal and
   saying how many were recorded (rule 7), at most 20 at a click (a cap, said on the button).
4. **The Chats page:** a mirror cell on each row from the states' one answer (one statement set for the
   account, kept by the change key with its own floor, its own "As of"): not mirrored; waiting for its read;
   N of M forwarded; complete; blocked with why (the task's fixed words, never parsed); never mirror; not
   possible (a private chat, a forum, protected: each with its sentence). "Mirror this chat" opens the plan in
   place: every number of the plan with what it counts, what blocks it, the sentence of what a yes will send
   (from the plan's own request list, never invented by the page), and the yes, which carries the plan's
   token: a plan that moved meanwhile is refused and shown again. A chat never read offers the existing
   estimate button first. "Stop mirroring", "Never mirror", "Allow again". A blocked mirror that waits for a
   settle shows the settle's plan and, where the rules cannot tell, the command's two choices as two buttons
   with the command's own words; nothing is chosen by default. Multi-select as point 3 says.
5. **Settings:** the name rule (prefix and separator through the seam's check; the example with the invented
   title the mirror package gives; "new mirrors only"), the gathering (at once, or 3 to 1440 minutes; an
   unreadable stored value is shown as "cannot be read: the automatic mirror sends nothing until it is set
   again", never as "at once"), the switch "mirror chats I join by themselves" (when the program can set it;
   else shown as a fact with how it was started). Each says when a change takes effect.
6. **The Overview:** one line: mirrors by state (counts) with a link to Chats filtered to them; a blocked
   mirror is among "what needs you".

## Tests (named; the fake seam; invented chats; no test judges on real time)
`TestMirrorCellEachState`, `TestMirrorPlanShownThenWishCarriesItsToken` (a moved plan refused),
`TestMirrorWishOneChatACall`, `TestMirrorChosenChatsStopAtFirstRefusal` (and the cap of 20),
`TestMirrorNeverTwoClicksAtOnce` (two requests at once for two chats: both marks kept),
`TestMirrorNeverUnreadableFailsClosed`, `TestMirrorStopIsNotUndoneByThePage`, `TestMirrorSettleChoiceNoDefault`,
`TestMirrorSettingsNameRuleAndGather` (each refusal's words; the unreadable value), `TestMirrorRoutesInGuard`,
`TestMirrorRoutesOnlyWithProgram`, `TestMirrorLogNoNames` (hostile chat titles and rule text through every
route: only fixed words in the log), `TestMirrorPageWordsFromThePlan` (node: the yes's sentence is built from
the plan's request list), `TestMirrorCellKeepsFocusAndOrder` (node), `TestMirrorStatesCostBounded` (statements
per poll with 2,000 chats; skipped under `raceOn` if it fills a large catalogue). The adapter: a stand-in
collector records the calls: one call per click, the token passed through unchanged. Mutations: a wish sent
without the token; "never" written as one list; a settle choice preselected; the yes's sentence written by
the page; a stop cleared by a later wish of another chat.

## Rules (hard)
- Copy and branch: make them yourself: `git -C C:/Users/trabi/Claude/Projects/Telegram/repo-archiver fetch private`,
  then `git -C C:/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add -b wip/pages-g4 ../wt-pages-g4 <the head of private/claude/charming-feynman-vm2xia>`
  (write the exact commit into your progress file). Work only in
  `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-g4`.
- Product code in `internal/server`, its scripts, and ONE new file in `internal/collector/livepages`; in
  `internal/collector/pages.go` the one place that hands the adapter over. Nothing in `internal/mirror`, the
  collector's mirror files, `internal/telegram`, the catalogue (no schema step, no catalogue function: the
  states come through the seam), the engine, the supply, the store, the viewer, `faketg`.
- **Nothing is sent to Telegram by anything you write, and nothing runs against Telegram.** Invented data
  only; never touch `E:\T\tg-dl`, the folders `a3`, `b`, `app`, any real catalogue, media, session or account;
  start no installed program (the owner's own program may be running: leave every process alone).
- New log, error and state text is constant words with numbers: never a chat's title, a name, a path, an id or
  a text. The name rule's prefix is the owner's own text: shown on the owner's page, never logged.
- The head's `TestAssetsStaySmall` holds every script under 600 lines and `pages/chats.js` is at 598: the
  mirror's part of the Chats page is its own script (`pages/chatmirror.js` or the like), wired with a few lines.
- After any change under `web/assets/js`: `TestScriptsNoDuplicateOrMissingNames`, `TestAssetsStaySmall` and a
  module parse of each script with node (`node --input-type=module --check < file`).
- Go: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, one go command at a
  time, `GOGC=25 GOMAXPROCS=2 go test -p 1 -run '<names>' ./internal/<package>`, named tests only: no whole run of
  `internal/server`, `internal/collector` or `internal/catalog`, no race detector, no Docker. Before each go
  command: `powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`;
  wait when free memory is under 2.5 GB or the CPU is over 85%.
- **Open it before handing back:** `tgarchive app -demo` or `TestPagesHold` with the fake seam on
  `127.0.0.1:8799`, the Chats page in the built-in browser if you have one, at desktop and phone width: a plan
  opened and agreed, a moved plan refused, twenty ticked chats, never and allow, a settle's two choices, the
  Settings rows. Say exactly what you saw and what you did not.
- Any file that holds a Windows path is written with the file-writing tool, never from inside a shell or script
  string.
- Commits: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; commit work in progress as you go and push only
  `git push private wip/pages-g4`. Never push, merge into, rebase or switch any other branch; never stash.
- Keep `archiver/docs/progress/pages-g4-PROGRESS.md` current from your first action and commit it with each
  step.

## Hand back
Commit-ready: everything committed and pushed, the tree clean, `gofmt -l` clean, `go vet` on the packages you
changed. `archiver/docs/progress/pages-g4-REPORT.md`: what was built against each numbered point; **the seam
as you built it, method by method, and the small interface the adapter expects of the collector, written so
that the mirror track can build to it without reading your code**; every route (method, path, what it calls);
every test and mutation with its result; what you saw in the browser and what you did not; what was NOT
verified (no collector implements the interface yet: nothing here has mirrored anything, on the fake or
otherwise); anything in the design page, message 75 or this brief you found wrong; the changed files; a
drafted final commit message. Your final message: the head commit and the main head it sits on, what is built
and tested, what is not, every departure, and your doubts, plainly.
