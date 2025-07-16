#!/bin/bash

# TIER 3: NETWORK MONITORING & SECURITY ACTIVATION
# Audio Checkpoint Integration

echo "=== NEXUS SECURITY LAYER ACTIVATION ==="
say "Activating Security Layer - Tier 3"

source "/Users/nexus/NEXUS_CORE/scripts/audio_alerts.sh"

# 3.1 Port Listening System
echo "[3.1] Implementing port monitoring and intrusion detection..."
cat > "/Users/nexus/NEXUS_CORE/scripts/port_monitor.sh" << 'EOF'
#!/bin/bash

# NEXUS Port Monitoring System
source "/Users/nexus/NEXUS_CORE/scripts/audio_alerts.sh"

MONITOR_LOG="/Users/nexus/NEXUS_CORE/logs/port_monitor.log"
ALERT_THRESHOLD=5  # Alert after 5 repeated attempts

monitor_ports() {
    echo "$(date): Starting port monitoring..." >> "$MONITOR_LOG"
    
    while true; do
        # Monitor common ports for suspicious activity
        netstat -an | grep LISTEN > /tmp/current_ports.txt
        
        # Check for new connections
        lsof -i -P -n | grep LISTEN | while read line; do
            port=$(echo "$line" | awk '{print $9}' | cut -d':' -f2)
            process=$(echo "$line" | awk '{print $1}')
            
            # Log all listening ports
            echo "$(date): Port $port - Process: $process" >> "$MONITOR_LOG"
            
            # Alert on suspicious ports
            case "$port" in
                22|23|135|139|445|1433|3389)
                    audio_checkpoint "warning" "Suspicious port activity detected on port $port"
                    ;;
            esac
        done
        
        # Monitor for repeated connection attempts
        netstat -an | grep -E "(SYN_RECV|TIME_WAIT)" | awk '{print $5}' | cut -d':' -f1 | sort | uniq -c | while read count ip; do
            if [ "$count" -gt "$ALERT_THRESHOLD" ]; then
                audio_checkpoint "critical" "Multiple connection attempts from IP $ip - Count: $count"
                echo "$(date): ALERT - Multiple attempts from $ip ($count connections)" >> "$MONITOR_LOG"
            fi
        done
        
        sleep 30
    done
}

# Export function
export -f monitor_ports
EOF

chmod +x "/Users/nexus/NEXUS_CORE/scripts/port_monitor.sh"

# 3.2 GitHub Integration Monitoring
echo "[3.2] Setting up GitHub repository monitoring..."
cat > "/Users/nexus/NEXUS_CORE/scripts/github_monitor.sh" << 'EOF'
#!/bin/bash

# NEXUS GitHub Integration Monitor
source "/Users/nexus/NEXUS_CORE/scripts/audio_alerts.sh"

REPO_PATH="/Users/nexus/NEXUS_CORE"
LAST_COMMIT_FILE="/Users/nexus/NEXUS_CORE/logs/last_commit.txt"

monitor_github() {
    echo "Starting GitHub repository monitoring..."
    
    while true; do
        cd "$REPO_PATH"
        
        # Fetch latest changes
        git fetch origin main 2>/dev/null
        
        # Get current commit hash
        current_commit=$(git rev-parse HEAD)
        
        # Check if we have a previous commit recorded
        if [ -f "$LAST_COMMIT_FILE" ]; then
            last_commit=$(cat "$LAST_COMMIT_FILE")
            
            if [ "$current_commit" != "$last_commit" ]; then
                audio_checkpoint "success" "New GitHub updates detected - pulling changes"
                
                # Pull new changes
                git pull origin main
                
                # Check for new scripts in specific directories
                git diff --name-only "$last_commit" "$current_commit" | grep -E "\.(sh|py|js)$" | while read script; do
                    if [ -f "$script" ]; then
                        audio_checkpoint "info" "New script detected: $script"
                        chmod +x "$script" 2>/dev/null || true
                    fi
                done
                
                # Update last commit
                echo "$current_commit" > "$LAST_COMMIT_FILE"
            fi
        else
            # First run - record current commit
            echo "$current_commit" > "$LAST_COMMIT_FILE"
        fi
        
        sleep 300  # Check every 5 minutes
    done
}

export -f monitor_github
EOF

chmod +x "/Users/nexus/NEXUS_CORE/scripts/github_monitor.sh"

# 3.3 Network Security Dashboard
echo "[3.3] Creating network security dashboard..."
cat > "/Users/nexus/NEXUS_CORE/scripts/security_dashboard.sh" << 'EOF'
#!/bin/bash

# NEXUS Security Dashboard
source "/Users/nexus/NEXUS_CORE/scripts/audio_alerts.sh"

display_security_status() {
    clear
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    NEXUS SECURITY DASHBOARD                  ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║ System Status: $(date)                           ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    
    # Active Connections
    echo "║ ACTIVE CONNECTIONS:                                          ║"
    netstat -an | grep ESTABLISHED | wc -l | xargs printf "║ Established: %-47s ║\n"
    
    # Listening Ports
    echo "║ LISTENING PORTS:                                             ║"
    netstat -an | grep LISTEN | wc -l | xargs printf "║ Total Listening: %-43s ║\n"
    
    # Disk Usage
    echo "║ DISK USAGE:                                                  ║"
    df -h / | awk 'NR==2 {printf "║ Root Volume: %-47s ║\n", $5}'
    
    # Recent Alerts
    echo "║ RECENT ALERTS:                                               ║"
    if [ -f "/Users/nexus/NEXUS_CORE/logs/audio_alerts.log" ]; then
        tail -3 "/Users/nexus/NEXUS_CORE/logs/audio_alerts.log" | while read line; do
            printf "║ %-60s ║\n" "${line:0:60}"
        done
    fi
    
    echo "╚══════════════════════════════════════════════════════════════╝"
}

# Continuous dashboard update
while true; do
    display_security_status
    sleep 10
done
EOF

chmod +x "/Users/nexus/NEXUS_CORE/scripts/security_dashboard.sh"

audio_checkpoint "success" "Security Layer Activation Complete"
echo "✓ Security Layer Activation Complete"
say "Security Infrastructure Deployed - Proceeding to Tier 4"
