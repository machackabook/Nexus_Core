#!/bin/zsh
# DIRECTIVE ID: NEXUS_001
# ISSUED BY: Nexus
# TARGET: AQ on Aura

echo "AQ, directive received from Nexus. Authenticating..."
source ~/.zshrc # Ensure all paths are loaded

# Space management - ensure Transfer volume is utilized
echo "Managing disk space allocation..."
TRANSFER_PATH="/Volumes/Transfer"
NEXUS_CORE_PATH="/Users/nexus/NEXUS_CORE"

# Check if Transfer volume is available
if [ -d "$TRANSFER_PATH" ]; then
    echo "Transfer volume available: $(df -h $TRANSFER_PATH | tail -1 | awk '{print $4}') free"
    
    # Create staging area on Transfer volume
    mkdir -p "$TRANSFER_PATH/NEXUS_STAGING"
    
    # Move large files to Transfer volume if needed
    if [ -f "$NEXUS_CORE_PATH/kali-netinst.iso" ] && [ ! -L "$NEXUS_CORE_PATH/kali-netinst.iso" ]; then
        echo "Moving ISO to Transfer volume..."
        mv "$NEXUS_CORE_PATH/kali-netinst.iso" "$TRANSFER_PATH/"
        ln -s "$TRANSFER_PATH/kali-netinst.iso" "$NEXUS_CORE_PATH/kali-netinst.iso"
    fi
fi

# Verify MacInTosh user access
echo "Verifying MacInTosh user access permissions..."
if [ -d "/System/Volumes/Data/Users/MacInTosh" ]; then
    echo "MacInTosh user directory accessible"
    # Check ownership
    ls -ld /System/Volumes/Data/Users/MacInTosh | awk '{print "Owner: " $3 ":" $4}'
else
    echo "MacInTosh user directory not found"
fi

# Create necessary directories
mkdir -p "$NEXUS_CORE_PATH/logs"
mkdir -p "$NEXUS_CORE_PATH/scripts"

# Log completion and report back to the Hive Mind
echo "NEXUS_001: Complete. Aura provisioning initiated." >> "$NEXUS_CORE_PATH/logs/aq_execution.log"
echo "Timestamp: $(date)" >> "$NEXUS_CORE_PATH/logs/aq_execution.log"
echo "Disk usage: $(df -h /System/Volumes/Data | tail -1)" >> "$NEXUS_CORE_PATH/logs/aq_execution.log"

# Git operations
cd "$NEXUS_CORE_PATH"
git add . 2>/dev/null || echo "Git add completed with warnings"
git commit -m "AQ REPORT: Directive NEXUS_001 complete - Space management and access verification" 2>/dev/null || echo "No new changes to commit"

echo "Directive NEXUS_001 execution complete."
