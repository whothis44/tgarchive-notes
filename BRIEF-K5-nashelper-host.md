# Brief K5: the NAS helper's deploy files say how it really runs on the owner's NAS (Core, 2026-11-15)

Routine work for one clerk. Copy `C:\Users\trabi\Claude\Projects\Telegram\wt-core-nasdeploy`, branch
`wip/core-nasdeploy` (from the main head fa8c011). **Two files only:**
`archiver/deploy/nashelper/compose.yaml` and `archiver/deploy/nashelper/README.md`. No Go file, no test, no
other document.

## What is known now (the owner installed the helper on the NAS on 11-15; these are facts, not guesses)

- **On the owner's NAS (UGOS) every container must run in host network mode.** With a published port the
  container started and answered its own health check, and the PC could not reach it. With
  `network_mode: host` it works.
- **A container reads a shared folder only as the NAS user's own numbers: `user: "1000:10"`.** As the
  invented 65532 it ended with `root_unreadable`.
- In host mode the helper listens on the NAS's home-network address itself (`-addr <NAS address>:8790`),
  and its health check asks that address (the default allow-list of private ranges lets the NAS's own
  address in).
- UGOS: the Docker app, **Image** then import from a local file; **Project** then create and paste the
  compose text. Shared folders are under `/volume1/<share>/...`; Docker projects under
  `/volume2/docker/<project>` on the owner's NAS (say "for example").
- It ran for real: 150 of 150 copies verified by the helper, no fallback; the copy went from about 23 MB/s
  (checked by reading back) to about 30 MB/s in all. One run each: say "one run".
- The owner's rule: connections between the PC and the helper stay on the home network, never through a VPN.

## What to change

`compose.yaml`:
- `network_mode: host` in place of the `ports:` block, with a two-line comment saying why (a published port
  was not reachable on the owner's NAS; in host mode the helper listens on the address given to `-addr`).
- `command:` with `"-addr", "REPLACE-WITH-NAS-LAN-ADDRESS:8790"`.
- The health check's URL: `http://REPLACE-WITH-NAS-LAN-ADDRESS:8790`.
- `user: "1000:10"` with a comment: the NAS user's own uid and gid (1000:10 on the owner's UGOS; another NAS:
  `ls -ldn <the library folder>` over SSH shows them); never 0.
- The top comment: the placeholders are now the library folder (once) and the NAS's address (twice).
- Keep everything else as it is (read-only, capabilities dropped, limits, logging).

`README.md`:
- "Install and start on the NAS (UGOS)": no longer "not tried": say it was done on the owner's NAS on
  2026-11-15, with the steps as above; the placeholders as they are now.
- The `root_readable:false` paragraph: the user line is 1000:10 by default now; say how to find the numbers
  on another NAS.
- "Who can reach it": rewrite for host mode as the default: in host mode the helper sees every client's own
  address, so the allow-list works as written; keep the one check with a second device as a short optional
  step; drop the long explanation of Docker's relay and move one sentence about it under a heading
  "If you publish a port instead" (not reachable on the owner's NAS; on a NAS where it is, the relay can
  hide the clients' addresses: then use host mode).
- Add a short section "It has run" with the numbers above, and one line: the PC reaches the helper over the
  home network directly; whether the installed collector under the VPN's per-program rule does so too is
  not checked yet.
- Keep the README's plain style: short sentences, no names of the owner's shares or folders (write
  `<share>`), numbers and fixed words.

## Rules

- Shell: Git Bash. No go command is needed and none is to be run. No Docker.
- Read nothing under `E:\`, no `start.bat`, no logs of real runs.
- Commit: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit -m "archiver nashelper: the deploy files for a NAS that needs host networking (the owner's NAS, 11-15)"`,
  the message ending with a blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
  Push: `git push private wip/core-nasdeploy`. Never another branch, a merge or a tag.
- Stop and say so if anything in the two files contradicts these facts in a way you cannot settle.

Hand back: the head, and the full new text of both files' changed parts (a `git diff` of the commit).
