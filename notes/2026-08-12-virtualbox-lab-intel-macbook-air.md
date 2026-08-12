# Second lab: VirtualBox on the Intel MacBook Air

**Date:** 2026-08-12
**Topic / Security+ or PenTest+ domain:** N/A — environment setup

## Goal

My close friend has my old Intel MacBook Air now and we're studying for Security+/PenTest+ together, so I wanted him to have his own hands-on lab instead of just watching over my shoulder. This machine can't run what I set up on the M-series Mac ([2026-08-11 lab setup](2026-08-11-lab-setup.md)) — UTM + ARM64 Kali needs Apple Silicon — so this is the Intel-compatible version of the same idea.

## What I did

- Checked the hardware first: i3-1000NG4 (2 cores/4 threads, 1.1GHz), 8GB RAM, ~45GB free disk. Low-power chip, tight but workable for one attacker VM + one lightweight target at a time.
- Installed VirtualBox via `brew install --cask virtualbox` instead of UTM (UTM leans on Apple Silicon's virtualization framework; VirtualBox is the standard free option on Intel Macs).
- Had to run the brew install in a real Terminal window, not through automation — the VirtualBox `.pkg` needs an interactive `sudo` password prompt.
- After install, macOS blocked VirtualBox's kernel extension. Had to approve it manually in System Settings → Privacy & Security → Allow.
- Downloaded Kali's official amd64 VirtualBox image from `cdimage.kali.org`. Unlike the ARM64 installer ISO, this ships as a `.7z` (not a ready `.ova`), so needed `brew install sevenzip` to unpack it. Verified the SHA256 against Kali's published checksum before extracting.
- The extracted archive turned out to already be a full VirtualBox VM export (`.vbox` + `.vdi`), so `VBoxManage registervm` on the `.vbox` file directly, rather than an OVA import.
- Downloaded Metasploitable2 (an intentionally vulnerable Ubuntu 8.04 target VM, the classic practice target for nmap/exploitation basics) as the second VM. It ships as a VMware `.vmdk`; converted it to VirtualBox's format with `VBoxManage clonemedium ... --format VDI` and attached it to a new VM (768MB RAM, 1 CPU — it's an old, light OS).
- Built an isolated network so the two VMs can attack each other without touching the real home Wi-Fi: gave each VM a second network adapter on a private VirtualBox **NAT Network** (`10.13.37.0/24`), separate from their first adapter (per-VM NAT, for internet/updates only).

## What happened / what broke

- Typing `!brew install --cask virtualbox` into a terminal did **not** run that command — zsh's `!` is history-expansion syntax, so it silently re-ran an old command from shell history instead. Lesson: don't put `!` in front of a command in an interactive shell unless you mean "re-run history," which is basically never what you want.
- Tried VirtualBox's "Host-only Network" for the isolated segment first (the more textbook-correct choice), but it needs its own kernel networking component (`vboxnetctl`) that wasn't loaded — probably needed a reboot after approving the system extension, which I hadn't done. Switched to a **NAT Network** instead, which uses a different backend and worked immediately without a reboot.
- The NAT Network's built-in DHCP server was flaky: its log showed it sending valid DHCP OFFERs, but the Kali guest never saw them and just kept re-broadcasting DISCOVER forever. Rather than debug VirtualBox's DHCP relay further, gave both VMs static IPs by hand instead (Kali `10.13.37.10` via `nmcli`, Metasploitable2 `10.13.37.20` via `/etc/network/interfaces`) — simpler and one less moving part to trust.
- Metasploitable2 has no VirtualBox Guest Additions installed, so there's no shared clipboard between the Mac and its console window — pasting a multi-line command into it silently mangled into garbage (a heredoc turned into a pile of `cat: no such file or directory` errors). Fix: typed it in as single-line commands instead of a heredoc, and for the parts that were still awkward to type by hand, used `VBoxManage controlvm <vm> keyboardputstring "..."` from the host terminal to inject keystrokes directly — works even without Guest Additions since it's emulating the keyboard at the VM level, not going through any clipboard.
- First attempt at verifying the two VMs were properly isolated from the real home LAN gave a false pass — I pinged the host's real IP from Kali and it succeeded, which looked like a leak. Turned out that ping went out over Kali's *other* adapter (the per-VM NAT meant for internet access), not the isolated one. Redid the test pinned to the isolated interface specifically (`ping -I eth1 <host-ip>`) and got 100% packet loss, confirming it's actually isolated.

## What I learned

- "Bridged" networking exposes a VM directly on the real Wi-Fi/LAN — anyone else on that network could reach it. "NAT" and "Internal/Host-only" networks keep a VM behind a private virtual router that nothing outside can initiate a connection into. This is the difference that actually matters for not putting a deliberately-vulnerable machine at risk.
- When testing whether something is really isolated, you have to force the test traffic out the specific interface you're checking (`ping -I <iface>`), not just ping and assume the default route used the interface you meant.
- A DHCP server can be sending valid offers and a client can still never receive them — the failure can be entirely on the delivery path, not the server logic. Reading the DHCP server's own log (which showed OFFER being sent every time) was what made it obvious this wasn't a config mistake on the client side, just an unreliable relay.
- Old appliance VMs (like Metasploitable2) often don't have Guest Additions and don't auto-configure every network adapter — only check what's in `/etc/network/interfaces` (or equivalent) at boot.

## Questions / follow-up

- Reboot this Mac once and see if Host-only Networking starts working (would let the DHCP server actually function instead of relying on static IPs).
- Walk through a first nmap scan + one obvious Metasploitable2 exploit (e.g. the exposed `vsftpd` backdoor) together as a joint session.
- Decide if a second target VM (e.g. a deliberately vulnerable web app) is worth the disk space on this machine, or if that's better done via TryHackMe like the other lab.
