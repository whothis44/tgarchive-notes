# Brief M10c (FINAL, 11-16 09:23, the mirror session M5): F10, the automatic mirror's chat-list interval as a setting

**For the coder of M10, in the same copy and round as `BRIEF-M10b-fixes.md` (same house rules and limits). Its
own commit, after F1 to F9; if F1 to F9 are already handed back, this is one more small round on that head.**

## The owner, 11-16 about 09:20 (on reading that the list comes "at most 30 minutes later")
"30 minutes seems too long. Can we make it a selectable option? Maybe default to 10, with some fuzziness. Same
with the standalone NAS version."

## What the record says (so nothing is reinvented)
- The old app compared the chats it could see with its archive every 30 minutes (12.30): that is where this
  number came from; nothing on record says a shorter interval costs a wait, and nothing says it does not:
  the chat list's requests are counted per kind and hour, so the first real run shows it.
- A chat the account joins while the program runs normally reaches the task through the live monitor (the
  nudge), not through the list: the list is what sets the baseline after the switch goes on, and the net for
  what the monitor did not say.
- The pattern exists: M7's gathering (`mirror/timing.go`: one settings row `mirror.auto.gather`, `ReadGather`,
  `SetGather`, `CheckGather`, a random part from `mirror.NewVary` keyed by the forward secret so that a
  pending time is the same after a restart and nothing is stored, off with `-auto-mirror-steady`). Port it.

## What to build
1. **The setting, in `internal/mirror/autonew.go`:** one settings row `mirror.auto.list_every` (minutes; for
   every account, as the gathering is; a catalogue setting, so that any program that runs the mirror's task
   on this catalogue, the planned one on the NAS included, reads the same value). `ListEveryDefault` 10
   minutes; range 5 to 1440; `CheckListEvery(minutes) error` (fixed words), `ReadListEvery(ctx, s)
   (minutes int, stored bool, err error)` (absent: the default; a value that cannot be read or is out of
   range: an error with fixed words, never the default silently), `SetListEvery(ctx, s, minutes)`.
2. **The random part:** each interval is the set minutes plus a random part of 0 to a fifth of it, at most 5
   minutes, never shorter than the set value; from the existing `Vary` (keyed by the forward secret, the
   account and the time of the last stored chat list, so the same pending time after a restart; nothing
   stored); none with `-auto-mirror-steady`, and none when there is no secret.
3. **The collector (`mirror_auto.go`):** `chatListEvery()` has no context: the task's look (`autoLook`) reads
   the setting every turn (one more settings read) and keeps it on the session (the reader's goroutine
   only); `chatListEvery()` uses the kept value with its random part, and the run's own `ChatListEvery` when
   that is sooner, as today. A setting that cannot be read: 30 minutes (the old fixed value: the slower,
   safe side), said once a session, and the pages' fact says unreadable. `Config.AutoListEvery`: keep it as
   the tests' override (a test that sets it gets exactly it, no random part; the existing tests must pass
   unchanged: say how you tell "set by a test" from the default, for example the default no longer filled
   in by `New` and 0 meaning "the stored setting"). `mirror.AutoListEvery` stays as the 30-minute fallback's
   name or is renamed: your choice, said in the report. F6 uses the interval in force (the set value with
   its random part) in place of the fixed 30 minutes: after a set-up made by the task, the first list comes
   one interval later, not at the click.
4. **The doors (`mirror_door.go`), catalogue only:** `MirrorListEvery(ctx) (MirrorListEveryFacts, error)`
   (`Minutes`, `Stored`, `Default`, `Unreadable`, `SpreadMaxSeconds`: the largest random part at that value)
   and `SetMirrorListEvery(ctx, minutes int) error` (the check first; the task reads it at its next turn;
   nudge every account's task as the gathering's door does, or as you find it does).
5. **Words:** the `-auto-mirror` paragraph of `command.go`'s help (the chat list every 10 minutes by default
   with a random part, set from the Settings page; no longer "30 minutes"); `autoMirrorNote` if it names the
   interval.
6. **Tests (named):** absent: 10 minutes; a stored value in force at the task's next turn without a restart;
   out of range and unreadable: refused by the door, and in the task 30 minutes with the line once; the
   random part never below the set value and never above its bound over many keys, the same after a
   "restart" (the same key), none with steady; after a task-made set-up the fake's chat-list requests do
   not grow before one interval has passed (F6's test on the setting); the tests that set
   `Config.AutoListEvery` unchanged.

## Hand-back
A section "M10c" in the report: as M10b's. The head's short hash, pushed; test functions removed or renamed
(expected: none).
