#!/bin/bash

# Synapse Access Alias Script
SYNAPSE_PORT=443
SYNAPSE_HOST="localhost"

# Check if browser is installed
if [ -d "/Applications/Google Chrome.app" ]; then
    BROWSER="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
elif [ -d "/Applications/Firefox.app" ]; then
    BROWSER="/Applications/Firefox.app/Contents/MacOS/firefox"
elif [ -d "/Applications/Safari.app" ]; then
    BROWSER="/Applications/Safari.app/Contents/MacOS/Safari"
else
    echo "No supported browser found"
    exit 1
fi

# Function to check if synapse is running
check_synapse() {
    nc -z $SYNAPSE_HOST $SYNAPSE_PORT >/dev/null 2>&1
    return $?
}

# Start synapse if not running
if ! check_synapse; then
    echo "Starting Synapse..."
    node /Users/nexus/Desktop/Synapse/login_interface.js &
    sleep 2
fi

# Open browser to synapse login
"$BROWSER" --new-window "https://$SYNAPSE_HOST" >/dev/null 2>&1 &

# Add to shell configuration
if ! grep -q "alias synonnym=" ~/.zshrc; then
    echo 'alias synonnym="/Users/nexus/Desktop/Synapse/synapse_alias.sh"' >> ~/.zshrc
    source ~/.zshrc
fi
