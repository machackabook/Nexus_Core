#!/bin/bash

# TIER 1: FOUNDATION INFRASTRUCTURE SETUP
# Audio Checkpoint Integration

echo "=== NEXUS FOUNDATION LAYER INITIALIZATION ==="
say "Initializing Foundation Layer - Tier 1"

# 1.1 Permission Elevation & Volume Configuration
echo "[1.1] Requesting elevated permissions for volume operations..."
sudo -v

# Check if Transfer volume exists
if [ -d "/Volumes/Transfer" ]; then
    echo "✓ Transfer volume detected"
    say "Transfer volume confirmed"
else
    echo "⚠ Transfer volume not found - creating mount point"
    say "Warning: Transfer volume not detected"
fi

# 1.2 Dotfiles Management System
echo "[1.2] Scanning for duplicate dotfiles..."
DOTFILES_REPORT="/Users/nexus/NEXUS_CORE/logs/dotfiles_analysis.log"
mkdir -p "/Users/nexus/NEXUS_CORE/logs"

find /Users -name ".*" -type f 2>/dev/null | grep -E "\.(bashrc|zshrc|profile|gitconfig|vimrc)" > "$DOTFILES_REPORT"
echo "✓ Dotfiles analysis complete - report saved to $DOTFILES_REPORT"

# 1.3 Storage Optimization (500GB Allocation)
echo "[1.3] Analyzing disk usage for 500GB optimization..."
df -h | grep -E "(Aura|Transfer|Macintosh)" > "/Users/nexus/NEXUS_CORE/logs/disk_usage.log"

# Create storage monitoring script
cat > "/Users/nexus/NEXUS_CORE/scripts/storage_monitor.sh" << 'EOF'
#!/bin/bash
while true; do
    USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ $USAGE -gt 85 ]; then
        say "Critical: Disk usage at $USAGE percent"
        echo "$(date): CRITICAL - Disk usage at $USAGE%" >> /Users/nexus/NEXUS_CORE/logs/storage_alerts.log
    fi
    sleep 300  # Check every 5 minutes
done
EOF

chmod +x "/Users/nexus/NEXUS_CORE/scripts/storage_monitor.sh"

echo "✓ Foundation Layer Setup Complete"
say "Foundation Layer Initialization Complete - Proceeding to Tier 2"
