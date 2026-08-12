# Security Lab Notes

Study notes and lab writeups for Security+ and PenTest+.

## Lab environments

Two machines, two setups — we're studying together and each needed a lab that fit its hardware.

**M-series Mac (mine)**
- **Hypervisor**: UTM (Apple Silicon)
- **Attacker box**: Kali Linux (ARM64) — recon, scanning, exploitation tooling
- **Targets**: TryHackMe / HackTheBox rooms over VPN (no local target VMs — keeps disk usage low)

**Intel MacBook Air (my friend's, practicing alongside me)**
- **Hypervisor**: VirtualBox (Intel Mac — UTM's ARM64 images don't run here)
- **Attacker box**: Kali Linux (amd64), `Kali-Attacker`
- **Target**: Metasploitable2 running locally, `Metasploitable2` — this machine had enough disk/RAM headroom to keep a target VM on-box instead of relying on TryHackMe
- Both VMs sit on an isolated VirtualBox NAT Network so they can attack each other without touching the real home network
- Reproduction script: [`scripts/setup-virtualbox-lab.sh`](scripts/setup-virtualbox-lab.sh)
- Full writeup: [2026-08-12 — VirtualBox lab on the Intel MacBook Air](notes/2026-08-12-virtualbox-lab-intel-macbook-air.md)

## How this repo works

Every time you sit down to practice, copy `notes/template.md` into `notes/`, rename it something like `2026-08-11-intro-to-nmap.md`, and fill it in as you go. Doesn't need to be polished — the point is to have a trail of what you tried, what broke, and what you learned. This becomes genuinely useful later: PenTest+ expects you to write findings up like a professional pentester would, and a habit of writing notes now makes that second nature.

## Log

- [2026-08-11 — Lab setup](notes/2026-08-11-lab-setup.md)
- [2026-08-12 — Installing Kali in UTM: fighting a black screen](notes/2026-08-12-kali-install-black-screen.md)
- [2026-08-12 — VirtualBox lab on the Intel MacBook Air](notes/2026-08-12-virtualbox-lab-intel-macbook-air.md)
