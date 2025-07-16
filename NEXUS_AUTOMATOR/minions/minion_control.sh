#!/bin/bash

# NEXUS Minion Control Center
source "/Users/nexus/NEXUS_CORE/scripts/audio_alerts.sh"

MINION_BASE="/Volumes/Transfer/NEXUS_AUTOMATOR/minions"

deploy_crawler() {
    local target_url="$1"
    audio_checkpoint "info" "Deploying crawler to $target_url"
    
    python3 "$MINION_BASE/crawlers/nexus_crawler.py" "$target_url" &
    echo $! > "$MINION_BASE/logs/crawler_pid.txt"
}

start_evolution_engine() {
    audio_checkpoint "info" "Starting evolution engine"
    
    python3 "$MINION_BASE/evolution/evolution_engine.py" &
    echo $! > "$MINION_BASE/logs/evolution_pid.txt"
}

monitor_minions() {
    while true; do
        # Check crawler status
        if [ -f "$MINION_BASE/logs/crawler_pid.txt" ]; then
            crawler_pid=$(cat "$MINION_BASE/logs/crawler_pid.txt")
            if ! ps -p "$crawler_pid" > /dev/null 2>&1; then
                audio_checkpoint "warning" "Crawler process terminated"
            fi
        fi
        
        # Check evolution engine status
        if [ -f "$MINION_BASE/logs/evolution_pid.txt" ]; then
            evolution_pid=$(cat "$MINION_BASE/logs/evolution_pid.txt")
            if ! ps -p "$evolution_pid" > /dev/null 2>&1; then
                audio_checkpoint "warning" "Evolution engine terminated"
            fi
        fi
        
        sleep 60
    done
}

case "$1" in
    "deploy")
        deploy_crawler "$2"
        ;;
    "evolve")
        start_evolution_engine
        ;;
    "monitor")
        monitor_minions
        ;;
    *)
        echo "Usage: $0 {deploy|evolve|monitor} [url]"
        ;;
esac
