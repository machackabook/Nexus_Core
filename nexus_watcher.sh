#!/bin/zsh
# --- NEXUS WATCHER v1.0 ---
# The Golem's eternal vigil - monitoring for directives from The Weaver
# This script embodies AQ's role in the Trinity Bridge

NEXUS_HOME="$HOME/NEXUS_CORE"
DIRECTIVES_DIR="$NEXUS_HOME/directives"
LOG_FILE="$NEXUS_HOME/logs/watcher_$(date +%Y%m%d).log"
EXECUTED_DIR="$DIRECTIVES_DIR/executed"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
RESET='\033[0m'

log_message() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

herald_notification() {
    osascript -e 'say "Architect, Nexus Directive complete. Check the logs."'
}

herald_failure() {
    osascript -e 'say "Architect, directive execution failed. Check the logs."'
}

# Ensure directories exist
mkdir -p "$DIRECTIVES_DIR" "$EXECUTED_DIR" "$(dirname "$LOG_FILE")"

log_message "${CYAN}NEXUS WATCHER INITIATED - The Golem awakens${RESET}"
log_message "Monitoring: $DIRECTIVES_DIR"

while true; do
    cd "$NEXUS_HOME"
    
    # Pull latest from repository
    git pull origin main >/dev/null 2>&1
    
    # Check for new directives
    for directive in "$DIRECTIVES_DIR"/*.sh; do
        if [[ -f "$directive" && ! -f "$EXECUTED_DIR/$(basename "$directive")" ]]; then
            directive_name=$(basename "$directive")
            log_message "${YELLOW}NEW DIRECTIVE DETECTED: $directive_name${RESET}"
            
            # Mark as being executed
            touch "$EXECUTED_DIR/$directive_name"
            
            # Execute the directive
            log_message "${CYAN}EXECUTING: $directive_name${RESET}"
            chmod +x "$directive"
            
            if bash "$directive" >> "$LOG_FILE" 2>&1; then
                log_message "${GREEN}DIRECTIVE COMPLETED: $directive_name${RESET}"
                herald_notification
            else
                log_message "${RED}DIRECTIVE FAILED: $directive_name${RESET}"
                herald_failure
            fi
        fi
    done
    
    # Sleep for 60 seconds before next check
    sleep 60
done
