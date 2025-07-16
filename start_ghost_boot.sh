#!/bin/zsh
# --- GHOST BOOT SERVER v2.0 ---

# Configuration
KALI_URL="https://cdimage.kali.org/current/kali-linux-2025.2-installer-netinst-amd64.iso"
ISO_NAME="kali-netinst.iso"
TFTP_ROOT="/private/tftpboot"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RESET='\033[0m'

echo -e "${YELLOW}[+] Acquiring Kali Netinstaller asset...${RESET}"
wget -O "$ISO_NAME" "$KALI_URL"

echo -e "${YELLOW}[+] Preparing TFTP root at ${TFTP_ROOT}...${RESET}"
sudo mkdir -p "$TFTP_ROOT/pxelinux.cfg"
sudo chmod 777 "$TFTP_ROOT"

echo -e "${YELLOW}[+] Extracting boot files...${RESET}"
7z x "$ISO_NAME" -o"$TFTP_ROOT/" debian-installer/amd64/pxelinux.0 debian-installer/amd64/ldlinux.c32 debian-installer/amd64/vmlinuz debian-installer/amd64/initrd.gz

echo "[+] Cleaning up ISO asset..."
rm "$ISO_NAME"

echo -e "${YELLOW}[+] Forging dnsmasq configuration...${RESET}"
cat << EOF | sudo tee "$(brew --prefix)/etc/dnsmasq.conf"
# DHCP/PXE Server Configuration
dhcp-range=192.168.2.50,192.168.2.150,12h
dhcp-boot=pxelinux.0
enable-tftp
tftp-root=${TFTP_ROOT}
EOF

echo -e "${GREEN}[+] LAUNCHING GHOST BOOT SERVER...${RESET}"
sudo brew services restart dnsmasq
