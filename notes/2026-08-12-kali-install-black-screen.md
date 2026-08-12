# Installing Kali in UTM: fighting a black screen

**Date:** 2026-08-12
**Topic / Security+ or PenTest+ domain:** N/A — environment setup (but good troubleshooting practice)

## Goal

Actually install Kali Linux (from the ARM64 ISO) into the UTM VM, instead of just having it created and empty.

## What I did

Booted the VM, got to the GRUB menu (`Install` / `Graphical install` / etc.) fine. That part always worked.

## What happened / what broke

Every install attempt went to a black screen after picking an option off GRUB:

1. First tried with a "Serial" device attached (added earlier to work around a known UTM display bug per Kali's own docs) — got two windows, one of them blank, and it wasn't obvious which one to use. Removed the Serial device to simplify.
2. Tried "Graphical install" with no Serial device → black screen, nothing rendered.
3. Tried plain text "Install" with no Serial device → also black screen.
4. Checked `ps aux | grep qemu` from the Mac terminal — the VM process was very much alive and burning ~200% CPU, so it wasn't frozen, it just wasn't sending anything to the display. This ruled out "it crashed" and pointed at a display/console handoff issue instead.
5. Tried editing the GRUB boot line (press `e` at the GRUB menu) to add `nomodeset` to the kernel line, hoping to stop a bad video mode switch. Still went to a screen that said "Display output is not active."
6. Realized the actual fix: Kali's own UTM docs *require* that Serial device — I'd removed it for the wrong reason. The two-window situation from step 1 wasn't broken, I just gave up on it too early.
7. Tried `utmctl attach KaliLinux` to view the serial console from the Mac's own Terminal instead of a UTM window — command exists in `--help` but isn't actually implemented in this UTM version ("WARNING: attach command is not implemented yet!").
8. Re-added the Serial device, started the VM again, and this time actually looked closely at *both* UTM windows. One was labeled **"KaliLinux (Terminal 1)"** — that's the serial console, and it had real, live installer text in it the whole time. The other (unlabeled) window is the framebuffer, which is expected to go black/idle once boot proceeds — that's normal, not a failure.

## What I learned

- **A black screen doesn't mean crashed.** Check if the process is still burning CPU (`ps aux | grep qemu`) before assuming something's broken — a live process with a black screen is a display/output problem, not a guest-OS problem.
- **Read the actual official docs' device requirements literally.** Kali's UTM guide says to add a Serial device specifically because of a known display bug on this exact platform combo (UTM + Apple Silicon + Kali ARM64 installer). That instruction existed for a reason — removing it because the result looked confusing was the wrong call.
- With a Serial device attached, UTM opens **two windows** for one VM: the graphical framebuffer (expected to stay dark during a console-only install) and a separate serial console window (labeled "Terminal 1" in the title bar) — that second one is where the real interaction happens.
- Don't trust a CLI tool's `--help` output as proof a command works — `utmctl attach` is documented but not implemented in this version.

## Questions / follow-up

- Finish the base install and first boot
- Try `utmctl attach` again after a UTM update, to see if it's been implemented
