# Review of G16: the cap on new mirrors in 24 hours as a Settings row (pages, P7, 2026-11-21)

Read: the brief and the house rules; `git diff af4ca40e da8c1c3d` whole (server `mirrors.go`, `demomirrors.go`,
the tests, `mirrorwords.js`, `mirrorsettings.js`, livepages `mirrors.go`, collector `pages_mirrors.go`); the coder's
report; the collector's cap door (`mirror_door.go` `MirrorNewPerDay`/`SetMirrorNewPerDay`), `mirror/newperday.go`,
`createsRoom`, `AutoCapStarters`, catalog `MirrorCreatesSince`; `readJSON`, the guard, `settingsAnswer`,
`settingRefused`, `api.js`; M13's diff (`wip/mirror-capmax` c7ea2d40) for the cap; the mirror track's facts draft
of 11-21 (counts only). Ran, in the scratch copy `wt-pages-review-g16-scratch` (every go command through
`runs-pages-p6/go1.sh`, named tests only, no race detector): the trial merge with M13 (clean, then aborted); on the
merge `go build ./...` and the named tests of server, livepages, mirror and collector; on da8c1c3d a compiled
server test binary for three probes (`zz_probe_g16_test.go`) and a probe server (`zz_probe_g16_serve_test.go`,
invented doors, `127.0.0.1:0`) driven by a headless Edge over CDP (`zz_out/drive.mjs`: 8 states x 4 views
(1400x900 and 390x800, light and dark), clicks and keyboard; 45 screenshots in `zz_out/shots`, looked at).
Nothing ran against Telegram; no window was shown; nothing committed or pushed.

## Findings

1. **SHOULD FIX** (by reading; the screenshots show the two accounts' "at most 20" under one row that says 20 in
   all). **The row says a catalogue-wide total, but the cap is counted per account.**
   `internal/server/web/assets/js/mirrorwords.js` `newPerDayView` (the `state` words, line 264 on da8c1c3d):
   "At most 20 new mirrors are created in any 24 hours (yours and the automatic ones together)". The setting is one
   catalogue value, but the count it bounds is per account: `createsRoom(ctx, l, account, ...)`
   (`internal/mirror/newperday.go`) calls `MirrorCreatesSince(ctx, account, ...)`, whose SQL is
   `WHERE account_id = ?` (`internal/catalog/schema_mirrorwant.go` 426). The cost sentence `MirrorNewPerDayCost`
   (`internal/server/mirrors.go`) does not say it either. How a person meets it: with two accounts signed in, the
   owner reads "at most 20 new mirrors in any 24 hours", sets 20, and the program may make 40 channels in a day
   (20 for each account). Each account's own block underneath says "at most 20 ... made" with no hint that the
   two add up. The plan's line on the Chats page ("1 of at most 20") is per account and true. The owner is adding
   accounts, so this will happen. Smallest cure: in the state words, "At most N new mirrors are created in any 24
   hours for each account (yours and the automatic ones together...)", and "for each account" in the cost
   sentence's first clause; pin it in `TestMirrorNewPerDayView` / `TestMirrorNewPerDayWords`. If per-account is
   not what the owner wants, that is a decision for the mirror track, not for the page.

2. **SHOULD FIX** (by reading). **The cost sentence says the automatic mirror has never run against Telegram, and it
   has.** `MirrorNewPerDayCost` (`internal/server/mirrors.go` 457): "What
   many creates in a day cost is not on record: the automatic mirror has not run against Telegram yet". The mirror
   track's facts draft of 11-21 21:10 (`DRAFT-FACTS-11-first-auto-run.md`, from the owner's catalogue, counts only)
   records the automatic mirror's first real run since 11-19: 4 mirror channels made, each create answered within
   its second, no wait. How a person meets it: the owner, who started that run, reads a sentence on the Settings
   page that is false. The rule "reports lead with what ran for real" points the other way too. Smallest cure:
   "What many creates in a day cost is not on record yet: the first automatic run made 4, each answered at once with
   no wait; every wait Telegram states is waited out in full." (or drop the clause), and the pin in
   `TestMirrorNewPerDayWords`.

3. **MINOR** (by reading). **"At 500, no new mirror is created" is true of the automatic task only once M13 is in.**
   The sentence is `MirrorNewPerDayCost`. On da8c1c3d alone, the automatic task's turn does not read the channel
   count. Only the owner's plan blocks at `ChannelLimit` (`mirror.go` 660). At 500 the task sends
   `channels.createChannel` and Telegram refuses it with CHANNELS_TOO_MUCH, which blocks that want (`auto.go` 1345,
   `step.go` 847). So a request is sent and the chat waits for the owner. M13b F1 adds the hold (`AutoEvChannelLimit`).
   How a person meets it: only if G16 is merged and installed before M13 and an account reaches 500. Cure: merge
   M13 before (or with) G16, or say "Telegram refuses a create at 500" until it is in.

4. **MINOR** (confirmed: the headless drive, "KEY ... Enter in field" in all 4 views). **A stale "Stored." stays on
   the answer line while the field shows a number that was not stored.** In `mirrorsettings.js` `capRows`, the field
   is not in a form, and the answer line keeps the last message until the next click. Sequence: store 17 (the line
   says "Stored."), type 23 in the field, press Enter. Nothing is sent, the field shows 23 and "Stored." is still
   under it. The row's sentence above still says 17, so this is a misreading, not wrong data. The interval's row
   behaves the same (no form, the message kept). Also, after a refusal (900, or an empty field), the repaint puts
   the stored number back in the field: the typed text is gone and the refusal is shown. Smallest cure: clear
   `msg.cap` on the field's `input` event, and let Enter in the field act as the button (a keydown handler or a
   `<form>`).

5. **MINOR** (by reading). **A failure that is not a refusal is shown without "Not stored".** `saveCap` (`mirrorsettings.js` 153) shows
   `err.fields?.new_per_day || err.message`. For a 500 from `mirrorOutcome`, "The app does not answer", a 415 or a
   409, the line says only the error, with no "Not stored:" in front. The other rows add it (`save()`: `Not stored:
   ${err.message}`). The door's own refusals already carry "Not stored", which is why the prefix was left out. Also,
   a field text that JavaScript turns into a number JSON writes with an exponent (typing `1e21`: `Number` is a
   whole number, and `JSON.stringify` sends `1e+21`) comes back as the server's lowercase "send a whole number".
   Cure: prefix "Not stored: " when `err.fields?.new_per_day` is absent, or when it is the server's "send a whole
   number"; or refuse in `newPerDayAsked` any text that is not `/^\d+$/`.

6. **MINOR** (confirmed: screenshot `narrow-dark-byrun.png` and the drive's "byrun" state). **Under the run's flag the
   door's words start in lower case and the stored value is not mentioned.** The note is the collector's
   `MirrorNewPerDayByRun`, which starts with "the program was started with ...". It is shown as a sentence of its
   own, so it starts lower case and has no full stop. The value stored on the page, which applies again after the
   run, is not said (the facts carry `Stored`). Cure: capitalise the first letter and add the full stop in
   `newPerDayView` (as `MirrorNewPerDayByRunWords` does for the refusal), and add "N is stored for later runs" when
   `stored > 0`.

## Checked and sound
- Q1, trial merge with M13 (`git merge --no-commit --no-ff private/wip/mirror-capmax`): clean, no conflict;
  `go build ./...` exit 0. On the merge, these all passed: server (G16's named set: `TestMirrorNewPerDay*`,
  `TestMirrorAutoNewCostCap`, `TestMirrorNoCapConstantInServer`, `TestMirrorAutoNewWords`, `TestMirrorListEverySetting`,
  the guard and route lists, `TestMutationsRefusedFromElsewhere`, the plan-words tests); livepages
  (`TestMirrorAdapter*`, `TestMirrorNoCapConstantInLivepages`); mirror (`TestNewPerDay|TestMirrorNewPerDay|TestMirrorDoorCap|TestMirrorAutoNewPerDay|TestMirrorAutoChannelLimit`);
  collector (`TestPagesMirrors|TestNewPerDay|TestMirrorNewPerDay|TestMirrorDoorCap|TestMirrorAutoNewPerDay|TestMirrorAutoChannelLimit`).
  The one failure, `TestMirrorNewPerDayRunLine`, came from my own setup: with TEMP inside the scratch git copy, the
  run refuses "the API settings file is inside a git repository" (shown by a probe). With TEMP in the session
  scratchpad it passed. Merge aborted, HEAD back at da8c1c3d.
- Q1, the row with Max 500 (probe state `stored500`): label "At most (from 1 to 500)", field `max="500"`, value 137,
  and the switch's cost "at most 137". With Max 0: "At most (1 or more)" and no `max` attribute. Max not above Min:
  "1 or more" (node test). The refusal with M13's door: "... from 1 to 500." (`TestMirrorAdapterNewPerDayRefusals`;
  the seam reads the door's bounds again).
- Q2, the body (probe `TestZZProbeG16Bodies`). 20.0, 1e3, 1E3, 7e-0, a number past int64, null, a string, a list,
  nested, a null body: 400 "send a whole number", door not reached. -0, -1, 2^31, max and min int64: reached the
  door and were refused in its range words, nothing stored. Two objects, a leading zero, `[7]`, a bare number, an
  empty body: 400, door not reached. Over 64 KB: 413. text/plain or no Content-Type: 415. Duplicate keys: the last
  wins (Go's decoder, as on every route); `{"N":9}` is taken (case-insensitive key, as on every route). Neither
  gets past the door's range check.
- Q2, the guard (probe `TestZZProbeG16Guard`, the mirror seam present): no token, wrong token, other, https and null
  origin, cross-site, same-site, none: 403. Rebinding host and other port: 421. The door was reached 0 times and
  nothing was stored, the same as `list-every` case for case. GET is 405.
- Q2, the run's flag before anything is written: the collector checks `c.cfg.AutoMirrorOpts.NewPerDay != 0` before
  `CheckNewPerDay` and before the write (`mirror_door.go` 809). The fake too (probe `TestZZProbeG16ByRunFirst`: 0,
  9 and 1000 all get the flag's words, nothing stored).
- Q3: with the cap's door failing (an error or a refusal), the settings answer comes with every other setting.
  Only `mirrorsettings.js` reads `new_per_day` from it (the Chats page reads the plan's own field). Headless: an
  error box "cannot be read now", no field, no button, and the switch's cost "capped (the cap cannot be read now)".
  The failure is logged by its class only; a refusal is not logged.
- Q4: "each account's mirror task reads it at its next turn and every plan from then on" is true:
  `NewPerDayInForce` is called at the turn and at the plan. "Lowering it ... undoes nothing: the next create waits
  until there is room again" is true (`createsRoom`, and M13's rank read). "yours and the automatic ones together"
  is true (`AutoCapStarters` = auto + owner; M13c leaves adopted rows out, and adopting is not a create). "One
  request that creates a private channel" is true (`help.getConfig` is once a session; a rename is the owner's
  alone). See findings 1 to 3 for what is not.
- Q5, headless: all 8 states in 4 views rendered with no console error or exception and no sideways scroll (0 px in
  all 56 readings). The default, stored, unreadable (error box, empty field, "5 is in force"), by-run, failed and
  refused states are each as the view says. After a click (empty, 900, 42) and after Tab then Enter, focus is on
  `mirror-cap-msg`, never lost and never on the button. A second Enter there does nothing. The button stays enabled
  after the answer.
- Q6, the lent lines (1111450a): only `collector/pages_mirrors.go` and its test change. `doorErr` maps
  `ErrNewPerDayByRun` as it maps `ErrAutoNewByRun`. The range sentinel passes through like the other doors' own
  sentinels. Nothing in the collector's run changed.
- The seam has no number of the cap's own (`TestMirrorNoCapConstant*`). The demo fake's plan takes the fake's cap in
  force.

## Not verified
- The real collector's doors with a real catalogue in the browser: only the invented doors were driven. The real
  doors were covered by `TestPagesMirrorsNewPerDayThroughTheSeam` on the merge.
- The look inside the real window (WebView2): not verified, needs a real window. Only headless Edge was used.
- The collector's named set on da8c1c3d alone (it was run on the merge with M13).
