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
