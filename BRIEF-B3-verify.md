# Brief B3-3: the bring-in's verify: a linked row is saved only when its link's file is (session B3, 11-15)

You are an Opus coder. Work only in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-bringin`. First:
`git checkout -B wip/b-verify private/claude/charming-feynman-vm2xia` (4f1992e, the main branch's head; the
copy's old branch `wip/b-bringin` is merged). Go module: `archiver/`. Go: `source
/c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in each Bash call. Packages:
`archiver/internal/bringin` and `archiver/cmd/tgarchive-bringin` only.

## What is known (measured 11-14 by the main session, read-only counts)
The bring-in ran for real on a copy of the old app's database (584,075 messages; 8 min 52 s). `verify` exited 1
on three small differences, so the "complete" mark was not set:
1. **119 completed work rows whose file is not saved** (5,343 against 5,224 expected). Diagnosed: all 119 have
   no saved-file row of their own and one link of kind `telegram-file` whose path has no saved-file row in the
   old database any more (78 distinct files). The new catalogue has them as not saved (118 held, 1 wanted),
   which is right. **Verify's expectation is wrong:** `facts.go` `work()` counts every completed row with a
   link as saved (`case linked: f.C1Linked++`) without asking whether the link's file is saved. `f.saved`
   already holds what is saved in effect (saved rows' identities, and linked ones only where the link's path
   is a saved row's).
2. 13 video fingerprints fewer in the catalogue than expected. Not diagnosed.
3. 8 open work rows counted "wanted" where "not collected" was expected. Not diagnosed.

## What to do
1. Fix 1: a completed row with a link counts as linked (`C1Linked`) only when its file is saved in effect
   (`ok && f.saved[idt]`); otherwise it is an orphan (`C1Orphan`). Check that `plan`'s lines 3c.1 and
   verify's two checks (`verify.go` about line 338) still say what they count; change the wording where it
   no longer fits. A named test on the package's invented old database: one completed row whose link's path
   has no saved row is expected as an orphan, and verify passes with it.
2. Diagnose 2 and 3 with **read-only counts** on the two real files (open both with `mode=ro`; print only
   counts and fixed words, never a name, text, path, id or link):
   - the copy of the old database:
     `C:\Users\trabi\AppData\Local\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b\oldcopy\old.sqlite`
   - the catalogue the run made:
     `C:\Users\trabi\AppData\Local\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b\old-archive\catalog.sqlite`
   - the run's own report beside them: `run-1.txt` (counts and fixed words).
   For each: is the catalogue right and the expectation wrong (fix the expectation, with a named test), or
   did `run` lose or misplace rows (say exactly which stage and why; fix it only if the fix is a few lines
   and cannot lose or overwrite data, otherwise hand it back described)? Throwaway probes stay out of the
   commit.
3. `go test ./internal/bringin ./cmd/tgarchive-bringin -p 1` once at the end (about 30 s), `gofmt -l`,
   `go vet` on the two packages. No race detector (nothing concurrent changes), no mutation checks.
4. Commit (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
   `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; **no archive numbers in the message**) and
   `git push private wip/b-verify`.

## Rules
- The old app's folder `E:\T\tg-dl` is not touched at all by you (the session's copy above is what you read).
- Do not run `run` or `plan`; do not write into either real file or their folders. Nothing against Telegram.
- Do not touch `repo-archiver`, other `wt-*` folders, or packages other than the two named (one exception
  is known and not yours: a line in `bringin.go`'s insert belongs to the copies session; leave it).
- Do not merge into or push `claude/charming-feynman-vm2xia`.

## Hand back (short)
The commit; for each of the three differences: cause, who was wrong, what changed; tests and result; doubts.
