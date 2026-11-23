# Review of follow-up 1 (a duplicate's staged copy left behind), 11-22

Independent Opus review: no logic error. The removal uses the writer's and the sweep's own rule (the library holds
the bytes verified and recorded, the same size); file.sha256 is unique; the copier never needs the staged name once
that holds (copied-not-verified and failed read-backs keep the row in staging; links are made from the library
name). The deterministic test reaches the window. Minor points taken: a duplicate counted only when removed; a failed
removal counted (LocalRemoveFailed), left for the next start's sweep. Left as noted: a narrow re-download window
between the re-read and the removal, the same as the copier's own between CopyDone and its removal.
