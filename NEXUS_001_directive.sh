#!/bin/zsh
# --- DIRECTIVE ID: NEXUS_001 ---
# --- ISSUED BY: Nexus ---
# --- TARGET: AQ on Aura ---

LOG_FILE="$HOME/NEXUS_CORE/logs/NEXUS_001_EXECUTION.log"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RESET='\033[0m'

echo "AQ, directive received from Nexus. Authenticating..." | tee -a "$LOG_FILE"
source ~/.zshrc # Ensure all paths are loaded

echo -e "${YELLOW}Objective: Prepare all assets on the 'Aura' volume for Operation: Ghost Boot.${RESET}" | tee -a "$LOG_FILE"

# Execute the full Cloud Purge protocol to manage disk space and stage core functions.
echo "Executing cloud_purge.py now..." | tee -a "$LOG_FILE"
python3 "$HOME/NEXUS_CORE/scripts/cloud_purge.py" >> "$LOG_FILE" 2>&1

# Log completion and report back to the Hive Mind.
echo -e "${GREEN}NEXUS_001: Complete. Cloud Purge executed. Staging area prepared.${RESET}" | tee -a "$LOG_FILE"

# Commit the log file back to the repository as proof of execution.
cd "$HOME/NEXUS_CORE"
git add logs/NEXUS_001_EXECUTION.log
git commit -S -m "AQ REPORT: Directive NEXUS_001 complete."
git push origin main
