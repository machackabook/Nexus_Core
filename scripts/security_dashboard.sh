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
