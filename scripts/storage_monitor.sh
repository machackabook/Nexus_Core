#!/bin/bash
while true; do
    USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ $USAGE -gt 85 ]; then
        say "Critical: Disk usage at $USAGE percent"
        echo "$(date): CRITICAL - Disk usage at $USAGE%" >> /Users/nexus/NEXUS_CORE/logs/storage_alerts.log
    fi
    sleep 300  # Check every 5 minutes
done
