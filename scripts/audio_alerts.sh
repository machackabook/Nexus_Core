#!/bin/bash

# NEXUS Audio Alert System
audio_checkpoint() {
    local event_type="$1"
    local message="$2"
    
    case "$event_type" in
        "success")
            say "Success: $message"
            afplay /System/Library/Sounds/Glass.aiff 2>/dev/null || true
            ;;
        "warning")
            say "Warning: $message"
            afplay /System/Library/Sounds/Sosumi.aiff 2>/dev/null || true
            ;;
        "error")
            say "Error: $message"
            afplay /System/Library/Sounds/Basso.aiff 2>/dev/null || true
            ;;
        "critical")
            say "Critical Alert: $message"
            for i in {1..3}; do
                afplay /System/Library/Sounds/Funk.aiff 2>/dev/null || true
                sleep 0.5
            done
            ;;
        *)
            say "$message"
            ;;
    esac
    
    # Log all alerts
    echo "$(date): [$event_type] $message" >> /Users/nexus/NEXUS_CORE/logs/audio_alerts.log
}

# Export function for use in other scripts
export -f audio_checkpoint
