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
