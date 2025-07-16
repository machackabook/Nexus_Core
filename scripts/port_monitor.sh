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
