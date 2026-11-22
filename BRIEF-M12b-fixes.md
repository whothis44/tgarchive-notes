# Brief M12b: the review's fix round for M12 (session M-6, 11-16)

For the same coder, in `wt-mirror-cap` on `wip/mirror-cap` from 52696bad. The independent review
(`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review14-scratch\REVIEW.md`: read its findings L1 to L7) says
"may be listed": no high or medium finding, 13 of 14 planted changes caught. Five small fixes, one commit each,
each with a test that fails without it. The rules of `BRIEF-M12-new-per-day.md` hold unchanged (every go
command through `go1.sh`; named tests with `-timeout`; no whole package, no race detector; privacy).

- **F1 (review L1): the set-up's fact does not outlive the switch.** After a failed set-up, an "off" from the
  page (or a switch that cannot be read) leaves `AutoSetUpFailed` set. Clear it wherever the look finds the
  switch off or unreadable and no set-up is tried. Take the reviewer's probe `TestProbeM12FactAfterOff` over
  as a test (invented data, your own name for it).
- **F2 (review L2): a test for the missing secret.** A try that fails for the missing secret must leave the
  fact empty (the task's own words say that case); the planted change that took that clearing out was not
  caught. One test that fails with the clearing out.
- **F3 (review L3): a run without `-auto-mirror` but with `-auto-mirror-new-per-day N` says so at its start**,
  in one line of fixed words with the number (the cap bounds the owner's wants for this run; a page cannot
  set it). Where `run` says its `-auto-mirror` line today; if that place is outside the mirror's lines of
  `command.go`, it is one line there beside the existing call and you name it in the report. A test.
- **F4 (review L4): the line "the cap ... cannot be read: 5 is in force" is said once per time it goes bad,**
  as the chat-list interval's line is: after the value read well again, a later unreadable value is said
  again (once). Follow the interval's form (its key is deleted when the value reads again). A test: bad,
  good, bad gives 2 lines; bad for many turns gives 1.
- **F5 (review L6): the report's numbers** (12 tests added by the first round, 7 of them in
  `internal/mirror`), and a section "M12b" with this round: what changed, tests added, runs.

**Not changed, and said in the report under "Known":** L7 (with no settings at all the read gives 20: both
production callers set them; the interval's form does the same); L5 (the words name the Settings page before
that page has the row: pages builds it on these doors).

**Runs:** your new tests and every test of the first round by name, in `internal/mirror` and
`internal/collector`; gofmt and vet on both. Hand back as before: the head's hash, tests added, the "go1: exit
N" lines, anything not as written here.
