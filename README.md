# Security Lab Notes

Study notes and lab writeups for Security+ and PenTest+.

## Lab environment

- **Hypervisor**: UTM (Apple Silicon Mac)
- **Attacker box**: Kali Linux (ARM64) — recon, scanning, exploitation tooling
- **Targets**: TryHackMe / HackTheBox rooms over VPN (no local target VMs — keeps disk usage low)

## How this repo works

Every time you sit down to practice, copy `notes/template.md` into `notes/`, rename it something like `2026-08-11-intro-to-nmap.md`, and fill it in as you go. Doesn't need to be polished — the point is to have a trail of what you tried, what broke, and what you learned. This becomes genuinely useful later: PenTest+ expects you to write findings up like a professional pentester would, and a habit of writing notes now makes that second nature.

## Log

- [2026-08-11 — Lab setup](notes/2026-08-11-lab-setup.md)
- [2026-08-12 — Installing Kali in UTM: fighting a black screen](notes/2026-08-12-kali-install-black-screen.md)
