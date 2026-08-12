#!/usr/bin/env bash
# Recreates the Intel-Mac VirtualBox pentest lab described in
# notes/2026-08-12-virtualbox-lab-intel-macbook-air.md
#
# Target hardware this was built/tested on: 8GB RAM, dual-core Intel Mac.
# Not a one-shot "just run it" script — a couple of steps need a human
# (sudo password prompts, approving VirtualBox's kernel extension). Read
# the comments and run section by section the first time.

set -euo pipefail

LABDIR="$HOME/PentestLab"
KALI_VER="2026.2"   # check https://cdimage.kali.org/ for the current release
NATNET="pentestlab-natnet"
NATCIDR="10.13.37.0/24"
KALI_LAB_IP="10.13.37.10"
TARGET_LAB_IP="10.13.37.20"

mkdir -p "$LABDIR"
cd "$LABDIR"

### 1. VirtualBox + 7z ###
# VirtualBox's .pkg installer needs an interactive sudo password — run this
# line in a real terminal window, not from a non-interactive script/agent.
brew install --cask virtualbox
# After this, macOS will block the kernel extension: go to
# System Settings -> Privacy & Security -> Allow, then continue.

brew install sevenzip   # Kali's amd64 image ships as .7z, not .ova

### 2. Kali Linux (attacker box) ###
curl -LO "https://cdimage.kali.org/kali-${KALI_VER}/kali-linux-${KALI_VER}-virtualbox-amd64.7z"
curl -LO "https://cdimage.kali.org/kali-${KALI_VER}/SHA256SUMS"
grep "virtualbox-amd64.7z\$" SHA256SUMS | shasum -a 256 -c -   # verify before trusting it

7zz x "kali-linux-${KALI_VER}-virtualbox-amd64.7z" -o./kali-extract
VBOXFILE=$(find kali-extract -name "*.vbox" | head -1)
VBoxManage registervm "$VBOXFILE"
KALI_ORIG_NAME=$(basename "$VBOXFILE" .vbox)
VBoxManage modifyvm "$KALI_ORIG_NAME" --name "Kali-Attacker"

### 3. Metasploitable2 (vulnerable target) ###
curl -L -o metasploitable-linux-2.0.0.zip \
  "https://sourceforge.net/projects/metasploitable/files/Metasploitable2/metasploitable-linux-2.0.0.zip/download"
unzip -o metasploitable-linux-2.0.0.zip

VBoxManage createvm --name "Metasploitable2" --ostype "Ubuntu_64" --basefolder "$LABDIR/VMs" --register
VBoxManage clonemedium disk Metasploitable2-Linux/Metasploitable.vmdk \
  "$LABDIR/VMs/Metasploitable2/Metasploitable2.vdi" --format VDI
VBoxManage modifyvm "Metasploitable2" --memory 768 --cpus 1 --ioapic on --nic1 nat
VBoxManage storagectl "Metasploitable2" --name "SATA Controller" --add sata --controller IntelAhci
VBoxManage storageattach "Metasploitable2" --storagectl "SATA Controller" --port 0 --device 0 \
  --type hdd --medium "$LABDIR/VMs/Metasploitable2/Metasploitable2.vdi"

# Cleanup: reclaim disk space once both VMs are registered
rm -f "$LABDIR/kali-linux-${KALI_VER}-virtualbox-amd64.7z"
rm -f "$LABDIR/metasploitable-linux-2.0.0.zip"
rm -rf "$LABDIR/Metasploitable2-Linux"

### 4. Isolated lab network ###
# Tried Host-only Networking first (the more textbook choice) but its kernel
# component (vboxnetctl) wasn't loaded on this machine without a reboot.
# NAT Network is a different backend that worked immediately, no reboot needed.
VBoxManage natnetwork add --netname "$NATNET" --network "$NATCIDR" --enable --dhcp on
VBoxManage modifyvm "Kali-Attacker" --nic2 natnetwork --nat-network2 "$NATNET"
VBoxManage modifyvm "Metasploitable2" --nic2 natnetwork --nat-network2 "$NATNET"

echo ""
echo "VMs registered. Two manual steps left (the built-in DHCP on this NAT"
echo "Network was flaky for us, so we hand-assigned static IPs instead):"
echo ""
echo "1. Start Kali-Attacker, log in (kali/kali), and run:"
echo "   sudo nmcli connection modify 'Wired connection 2' ipv4.method manual \\"
echo "     ipv4.addresses ${KALI_LAB_IP}/24 ipv4.gateway '' ipv4.dns ''"
echo "   sudo nmcli connection up 'Wired connection 2'"
echo ""
echo "2. Start Metasploitable2, log in (msfadmin/msfadmin), and run:"
echo "   echo auto eth1 | sudo tee -a /etc/network/interfaces"
echo "   echo iface eth1 inet static | sudo tee -a /etc/network/interfaces"
echo "   echo address ${TARGET_LAB_IP} | sudo tee -a /etc/network/interfaces"
echo "   echo netmask 255.255.255.0 | sudo tee -a /etc/network/interfaces"
echo "   sudo ifup eth1"
echo ""
echo "Then from Kali: ping ${TARGET_LAB_IP}  (should succeed)"
echo "and:            ping -I eth1 <your-real-LAN-IP>  (should NOT succeed)"
