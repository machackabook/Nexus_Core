#!/bin/zsh
# DIRECTIVE ID: NEXUS_001
# ISSUED BY: Nexus
# TARGET: AQ on Aura

echo "AQ, directive received from Nexus. Authenticating..."
source ~/.zshrc

# Execute the full NEXUS_GENESIS_PROTOCOL script to provision this machine.
echo "Executing NEXUS_GENESIS_PROTOCOL.sh now."
bash "$HOME/NEXUS_CORE/nexus_genesis_protocol.sh"

# Log completion and report back to the Hive Mind.
echo "NEXUS_001: Complete. Aura provisioning initiated." >> "$HOME/NEXUS_CORE/logs/aq_execution.log"
cd "$HOME/NEXUS_CORE"
git add .
git commit -S -m "AQ REPORT: Directive NEXUS_001 complete."
git push origin main
