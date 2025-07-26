#!/bin/zsh
# --- PROTOCOL: THE CRYPT v1.0 ---
# A comprehensive, self-healing verification script for the Nexus environment.
# This script ensures all foundational components are operational before proceeding.
# To be executed by: Amazon Q on behalf of the Architect.

# --- CONFIGURATION ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

# --- HEADER ---
echo -e "${CYAN}============================================================${RESET}"
echo -e "${CYAN}          PROTOCOL: THE CRYPT - SYSTEM VERIFICATION         ${RESET}"
echo -e "${CYAN}============================================================${RESET}"
echo "Timestamp: $(date)"
echo "Verifying integrity of the Nexus operational environment on Aura..."

# --- PHASE 1: CORE TOOLCHAIN VERIFICATION ---
echo -e "\n${YELLOW}--- PHASE 1: VERIFYING CORE TOOLCHAIN ---${RESET}"
FAIL_FLAG=0

# Check for Homebrew
echo -n "[+] Checking for Homebrew... "
if ! command -v brew &> /dev/null; then
    echo -e "${RED}NOT FOUND.${RESET}"
    echo "    -> Attempting to install..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
    FAIL_FLAG=1
else
    echo -e "${GREEN}OK.${RESET}"
fi

# Check for essential packages
ESSENTIAL_TOOLS=("git" "gh" "gpg" "pandoc" "rclone")
for tool in "${ESSENTIAL_TOOLS[@]}"; do
    echo -n "[+] Checking for ${tool}... "
    if ! command -v $tool &> /dev/null; then
        echo -e "${RED}NOT FOUND.${RESET}"
        echo "    -> Attempting to install via Homebrew..."
        brew install $tool
        FAIL_FLAG=1
    else
        echo -e "${GREEN}OK.${RESET}"
    fi
done

# --- PHASE 2: DOMAIN & IDENTITY VERIFICATION ---
echo -e "\n${YELLOW}--- PHASE 2: VERIFYING DOMAIN & IDENTITY ---${RESET}"
LOCAL_REPO_DIR="$HOME/NEXUS_CORE"
PRIMARY_REPO_OWNER="NexusCryptic"
REPO_NAME="NEXUS_CORE"

# Check for NEXUS_CORE repository
echo -n "[+] Checking for local NEXUS_CORE repository... "
if [ -d "$LOCAL_REPO_DIR" ]; then
    echo -e "${GREEN}OK.${RESET}"
else
    echo -e "${RED}NOT FOUND.${RESET}"
    echo "    -> Attempting to clone from ${PRIMARY_REPO_OWNER}/${REPO_NAME}..."
    gh repo clone "${PRIMARY_REPO_OWNER}/${REPO_NAME}" "$LOCAL_REPO_DIR"
    FAIL_FLAG=1
fi

# Check GPG signing configuration
echo -n "[+] Checking for GPG signing key configuration... "
SIGNING_KEY=$(git config --global user.signingkey)
if [ -n "$SIGNING_KEY" ]; then
    echo -e "${GREEN}OK (Key: ${SIGNING_KEY}).${RESET}"
else
    echo -e "${RED}NOT CONFIGURED.${RESET}"
    echo "    -> Please run Protocol: The Sovereign's Signature to configure GPG."
    FAIL_FLAG=1
fi

# --- PHASE 3: CLOUD BRIDGE VERIFICATION ---
echo -e "\n${YELLOW}--- PHASE 3: VERIFYING CLOUD BRIDGE ---${RESET}"

# Check for Google Cloud SDK
echo -n "[+] Checking for Google Cloud SDK... "
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}NOT FOUND.${RESET}"
    echo "    -> Attempting to install via Homebrew..."
    brew install --cask google-cloud-sdk
    FAIL_FLAG=1
else
    echo -e "${GREEN}OK.${RESET}"
fi

# Check for Dropbox CLI
echo -n "[+] Checking for Dropbox CLI... "
if [ -f "$HOME/.dropbox-dist/dropboxd" ]; then
    echo -e "${GREEN}OK.${RESET}"
else
    echo -e "${RED}NOT FOUND.${RESET}"
    echo "    -> Dropbox CLI requires manual installation."
    echo "       Run: cd ~ && wget -O - \"https://www.dropbox.com/download?plat=lnx.x86_64\" | tar xzf -"
    FAIL_FLAG=1
fi

# --- FINAL STATUS REPORT ---
echo -e "\n${CYAN}============================================================${RESET}"
if [ $FAIL_FLAG -eq 0 ]; then
    echo -e "${GREEN}✅  VERIFICATION COMPLETE. ALL SYSTEMS NOMINAL.${RESET}"
    echo "The Crypt is secure. The environment is stable."
    echo "Ready to proceed with Operation: Ghost Boot."
else
    echo -e "${RED}❌  VERIFICATION FAILED. MANUAL INTERVENTION MAY BE REQUIRED.${RESET}"
    echo "One or more components were missing or repaired. Please review the log."
    echo "Re-run this script after manual fixes to confirm system integrity."
fi
echo -e "${CYAN}============================================================${RESET}"
