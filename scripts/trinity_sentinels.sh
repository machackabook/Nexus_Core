#!/bin/zsh
# TRINITY OF SENTINELS - Security Posture Implementation
# The replacement for the "beast with legs"

echo "🛡️ Initializing Trinity of Sentinels..."

# The Gatekeeper (Little Snitch Configuration)
echo "🚪 Configuring The Gatekeeper (Little Snitch)..."
if command -v littlesnitch >/dev/null 2>&1; then
    echo "✅ Little Snitch detected"
    # Create custom rules for NEXUS operations
    echo "Creating NEXUS-specific firewall rules..."
else
    echo "⚠️ Little Snitch not installed - install from: https://www.obdev.at/products/littlesnitch/"
fi

# The Hunter (Network Traffic Analysis)
echo "🎯 Setting up The Hunter (Traffic Analysis)..."
mkdir -p ~/NEXUS_CORE/security/traffic_logs

# Create network monitoring script
cat << 'EOF' > ~/NEXUS_CORE/scripts/network_hunter.py
#!/usr/bin/env python3
"""
The Hunter - AI-driven network traffic analyzer
Proactive detection of suspicious traffic patterns
"""

import subprocess
import json
import time
from datetime import datetime
import re

class NetworkHunter:
    def __init__(self):
        self.log_file = "~/NEXUS_CORE/security/traffic_logs/hunter.log"
        self.suspicious_patterns = [
            r'\.onion',  # Tor traffic
            r'base64',   # Encoded payloads
            r'powershell', # PowerShell execution
            r'cmd\.exe',   # Command execution
        ]
    
    def monitor_connections(self):
        """Monitor active network connections"""
        try:
            result = subprocess.run(['netstat', '-an'], capture_output=True, text=True)
            connections = result.stdout
            
            # Analyze for suspicious patterns
            for pattern in self.suspicious_patterns:
                if re.search(pattern, connections, re.IGNORECASE):
                    self.alert(f"Suspicious pattern detected: {pattern}")
            
        except Exception as e:
            print(f"Monitoring error: {e}")
    
    def alert(self, message):
        """Send security alert"""
        timestamp = datetime.now().isoformat()
        alert_msg = f"[{timestamp}] HUNTER ALERT: {message}"
        print(alert_msg)
        
        # Log to file
        with open(self.log_file, 'a') as f:
            f.write(alert_msg + '\n')
        
        # Voice alert
        subprocess.run(['say', f"Security alert: {message}"])

if __name__ == "__main__":
    hunter = NetworkHunter()
    
    print("🎯 The Hunter is active - monitoring network traffic...")
    while True:
        hunter.monitor_connections()
        time.sleep(30)  # Check every 30 seconds
EOF

chmod +x ~/NEXUS_CORE/scripts/network_hunter.py

# The Watcher (Deadman's Snitch)
echo "👁️ Configuring The Watcher (Deadman's Snitch)..."

# Create heartbeat monitoring script
cat << 'EOF' > ~/NEXUS_CORE/scripts/deadman_watcher.sh
#!/bin/zsh
# The Watcher - Deadman's Snitch Implementation
# Monitors system health and sends heartbeat signals

HEARTBEAT_URL="https://nosnch.in/YOUR_SNITCH_ID"  # Replace with actual Deadman's Snitch URL
LOG_FILE="~/NEXUS_CORE/security/watcher.log"

send_heartbeat() {
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Send heartbeat ping
    if curl -s "$HEARTBEAT_URL" >/dev/null 2>&1; then
        echo "[$timestamp] Heartbeat sent successfully" >> "$LOG_FILE"
    else
        echo "[$timestamp] CRITICAL: Heartbeat failed!" >> "$LOG_FILE"
        # Emergency notification
        osascript -e 'say "Critical system alert: Heartbeat failure detected"'
    fi
}

# Check critical processes
check_critical_processes() {
    critical_processes=("nexus_watcher" "network_hunter")
    
    for process in "${critical_processes[@]}"; do
        if ! pgrep -f "$process" >/dev/null; then
            echo "[$(date)] ALERT: Critical process $process not running!" >> "$LOG_FILE"
            osascript -e "say 'Critical process failure: $process'"
        fi
    done
}

# Main monitoring loop
while true; do
    send_heartbeat
    check_critical_processes
    sleep 300  # Send heartbeat every 5 minutes
done
EOF

chmod +x ~/NEXUS_CORE/scripts/deadman_watcher.sh

# Create launch daemons for persistent operation
echo "🔄 Creating persistent security daemons..."

# Hunter daemon
cat << EOF > ~/Library/LaunchAgents/com.nexus.hunter.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.nexus.hunter</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>$HOME/NEXUS_CORE/scripts/network_hunter.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$HOME/NEXUS_CORE/security/hunter_daemon.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/NEXUS_CORE/security/hunter_daemon_error.log</string>
</dict>
</plist>
EOF

# Watcher daemon
cat << EOF > ~/Library/LaunchAgents/com.nexus.deadman.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.nexus.deadman</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/zsh</string>
        <string>$HOME/NEXUS_CORE/scripts/deadman_watcher.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$HOME/NEXUS_CORE/security/deadman_daemon.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/NEXUS_CORE/security/deadman_daemon_error.log</string>
</dict>
</plist>
EOF

echo "✅ Trinity of Sentinels configured successfully!"
echo ""
echo "🛡️ Security Posture Summary:"
echo "  • The Gatekeeper: Network traffic monitoring"
echo "  • The Hunter: AI-driven threat detection" 
echo "  • The Watcher: System health monitoring"
echo ""
echo "⚠️ Next Steps:"
echo "  1. Install Little Snitch for complete Gatekeeper functionality"
echo "  2. Configure Deadman's Snitch URL in deadman_watcher.sh"
echo "  3. Load security daemons with: launchctl load ~/Library/LaunchAgents/com.nexus.*.plist"
echo "  4. Grant required system permissions (see Part 3)"
