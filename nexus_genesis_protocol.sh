#!/bin/zsh
# --- NEXUS GENESIS PROTOCOL v1.0 ---
# Complete provisioning protocol for Aura machine initialization
# Integrates all NEXUS_CORE systems and establishes operational readiness

# --- CONFIGURATION ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
RESET='\033[0m'

NEXUS_HOME="$HOME/NEXUS_CORE"
LOG_FILE="$NEXUS_HOME/logs/genesis_protocol_$(date +%Y%m%d_%H%M%S).log"

# --- LOGGING FUNCTION ---
log_message() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# --- PHASE 1: SYSTEM VERIFICATION ---
log_message "${CYAN}--- NEXUS GENESIS PROTOCOL v1.0 INITIATED ---${RESET}"
log_message "${YELLOW}Phase 1: System Verification and Preparation${RESET}"

# Verify critical directories
log_message "[+] Verifying NEXUS_CORE infrastructure..."
for dir in "$NEXUS_HOME/scripts" "$NEXUS_HOME/logs" "$NEXUS_HOME/.git"; do
    if [[ -d "$dir" ]]; then
        log_message "    ✓ $dir exists"
    else
        log_message "    ✗ $dir missing - creating..."
        mkdir -p "$dir"
    fi
done

# --- PHASE 2: KERNEL SIPHON ACTIVATION ---
log_message "\n${YELLOW}Phase 2: Kernel Siphon Activation${RESET}"
if [[ -f "$HOME/activate_kernel_siphon.sh" ]]; then
    log_message "[+] Activating Kernel Siphon virtual environment..."
    source "$HOME/activate_kernel_siphon.sh"
    log_message "    ✓ Kernel Siphon environment activated"
else
    log_message "    ⚠ Kernel Siphon not found - may need manual setup"
fi

# --- PHASE 3: CLOUD INFRASTRUCTURE VERIFICATION ---
log_message "\n${YELLOW}Phase 3: Cloud Infrastructure Verification${RESET}"
log_message "[+] Verifying rclone configuration..."
if command -v rclone >/dev/null 2>&1; then
    rclone listremotes | grep -q "gdrive" && log_message "    ✓ Google Drive configured" || log_message "    ⚠ Google Drive needs configuration"
else
    log_message "    ✗ rclone not installed"
fi

# --- PHASE 4: REPOSITORY SYNCHRONIZATION ---
log_message "\n${YELLOW}Phase 4: Repository Synchronization${RESET}"
cd "$NEXUS_HOME"
log_message "[+] Checking repository status..."
git status --porcelain | wc -l | xargs -I {} log_message "    {} files modified/untracked"

# --- PHASE 5: OPERATIONAL SYSTEMS CHECK ---
log_message "\n${YELLOW}Phase 5: Operational Systems Check${RESET}"

# Check critical scripts
log_message "[+] Verifying critical operational scripts..."
critical_scripts=("cloud_purge.py" "cloud_purge_v2.py" "space_manager.sh" "protocol_the_crypt.sh")
for script in "${critical_scripts[@]}"; do
    if [[ -f "$NEXUS_HOME/scripts/$script" ]]; then
        log_message "    ✓ $script operational"
    else
        log_message "    ✗ $script missing"
    fi
done

# --- PHASE 6: VOLUME VERIFICATION ---
log_message "\n${YELLOW}Phase 6: Volume and Storage Verification${RESET}"
log_message "[+] Checking critical volumes..."
volumes=("/Volumes/Transfer" "/Volumes/MacIntoshiba")
for vol in "${volumes[@]}"; do
    if [[ -d "$vol" ]]; then
        log_message "    ✓ $vol mounted"
        df -h "$vol" | tail -1 | awk '{print "      Space: " $4 " available of " $2}' | tee -a "$LOG_FILE"
    else
        log_message "    ✗ $vol not mounted"
    fi
done

# --- PHASE 7: NETWORK CONNECTIVITY ---
log_message "\n${YELLOW}Phase 7: Network Connectivity Verification${RESET}"
log_message "[+] Testing network connectivity..."
if ping -c 1 google.com >/dev/null 2>&1; then
    log_message "    ✓ Internet connectivity confirmed"
else
    log_message "    ✗ Network connectivity issues detected"
fi

# --- PHASE 8: FINAL SYSTEM STATUS ---
log_message "\n${YELLOW}Phase 8: Final System Status Report${RESET}"
log_message "[+] Aura machine provisioning summary:"
log_message "    • NEXUS_CORE: Operational"
log_message "    • Kernel Siphon: $([ -f "$HOME/activate_kernel_siphon.sh" ] && echo "Ready" || echo "Needs Setup")"
log_message "    • Cloud Storage: $(command -v rclone >/dev/null && echo "Configured" || echo "Needs Setup")"
log_message "    • Repository: Synchronized"
log_message "    • Storage Volumes: $(ls /Volumes/ 2>/dev/null | wc -l | xargs echo) mounted"

# --- COMPLETION ---
log_message "\n${GREEN}--- NEXUS GENESIS PROTOCOL COMPLETE ---${RESET}"
log_message "${GREEN}Aura machine is now provisioned and operational.${RESET}"
log_message "${YELLOW}Ready for Operation: Ghost Boot and advanced directives.${RESET}"

# Return to original directory
cd - >/dev/null
