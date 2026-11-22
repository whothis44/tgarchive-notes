# Setting up the second PC as a test runner (paste everything below the line into a Claude Code session on that PC)

---

You are setting up this Windows PC as a **test runner** for a private Go project. The owner's main PC will reach it over
SSH on the home network, and run the project's long test suites here. This PC gets **code only**: no archive data, no
Telegram sign-in, nothing that talks to Telegram. Work in PowerShell. Ask the owner before each step that needs an
administrator PowerShell window, and before anything that restarts the PC. Report each step's result in one line.

1. **Admin check:** run `whoami` and `([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)`.
   If the session is not elevated, ask the owner to open "Windows PowerShell (Admin)" for steps 2 and 3 and run the
   commands you give them there.

2. **OpenSSH Server** (elevated):
   ```
   Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
   Start-Service sshd
   Set-Service -Name sshd -StartupType Automatic
   New-NetFirewallRule -Name 'OpenSSH-Home' -DisplayName 'OpenSSH (home network only)' -Enabled True -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow -Profile Private -RemoteAddress LocalSubnet
   ```
   If the network is set to "Public", tell the owner, and do not open the port on the Public profile. The owner can
   switch the home network to Private in Windows' Wi-Fi or Ethernet settings.

3. **The main PC's key** (elevated). This is the public key; it is safe to paste:
   ```
   ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINOuEGOqUIXsHMogC7AtLVFvx26Dp/lYuswFaB8oXKkO tgarchive-test-runner
   ```
   - If the Windows user is an administrator, put that line in `C:\ProgramData\ssh\administrators_authorized_keys`,
     then: `icacls C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"`.
   - Otherwise put it in `%USERPROFILE%\.ssh\authorized_keys`.
   - Then `Restart-Service sshd`.

4. **Tools** (`winget`; accept the prompts with the owner):
   - Git: `winget install --id Git.Git -e`
   - GitHub CLI: `winget install --id GitHub.cli -e`
   - **Go 1.27.3 exactly**, unpacked (not installed system-wide): download `go1.27.3.windows-amd64.zip` from
     https://go.dev/dl/, unpack it to `C:\tgwork\goroot-1.27.3`, and check that
     `C:\tgwork\goroot-1.27.3\go\bin\go.exe version` says go1.27.3.
   - Docker Desktop, only if the owner agrees (it needs WSL2 and a restart; it is used only for the race detector's
     runs): `winget install --id Docker.DockerDesktop -e`.

5. **The code:**
   - The owner signs in to GitHub themselves: they run `gh auth login` in this window and follow its steps. Never type
     a password or token yourself.
   - Then `gh repo clone whothis44/tgarchive C:\tgwork\repo-archiver -- -b claude/charming-feynman-vm2xia`.
   - Then, in `C:\tgwork\repo-archiver\archiver`, with `$env:GOROOT='C:\tgwork\goroot-1.27.3\go'` and that `go.exe`
     first on PATH: `go build ./...`. Say whether it built.

6. **Sleep:** ask the owner whether this PC may [name removed] while plugged in (for runs of up to an hour). Only with
   their yes: `powercfg /change standby-timeout-ac 0`.

7. **Report to the owner**, in a few lines to pass to the main PC's session:
   - this PC's name (`hostname`) and its home-network IPv4 address (`Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred | Where-Object InterfaceAlias -notmatch 'Loopback|vEthernet'`);
   - the Windows user name, and whether it is an administrator;
   - whether sshd is running and the firewall rule is on the Private profile;
   - the Go version and whether `go build ./...` passed;
   - whether Docker is installed.

Do not install anything else, and do not change other settings.
