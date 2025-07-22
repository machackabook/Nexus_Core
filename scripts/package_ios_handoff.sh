#!/bin/bash
# Package and transfer Gaia presentation via Handoff/AirDrop

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Paths
NEXUS_CORE="/Users/nexus/nexus-bridge/Nexus_Core"
GAIA_ROOT="/Users/nexus/GAIA_ROOT"
BUILD_DIR="$NEXUS_CORE/build/ios"
MEMORY_DIR="$NEXUS_CORE/memory_recognition"

# Create necessary directories
mkdir -p "$BUILD_DIR"
mkdir -p "$MEMORY_DIR"

# Log function with memory recognition
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local message="$1"
    local memory_file="$MEMORY_DIR/package_history.json"
    
    echo -e "${BLUE}[${timestamp}]${NC} $message"
    
    # Save to memory recognition system
    if [ ! -f "$memory_file" ]; then
        echo '{"packages":[]}' > "$memory_file"
    fi
    
    # Add new entry
    local entry="{\"timestamp\":\"$timestamp\",\"action\":\"$message\",\"status\":\"success\"}"
    tmp=$(mktemp)
    jq ".packages += [$entry]" "$memory_file" > "$tmp" && mv "$tmp" "$memory_file"
}

# Package the presentation
package_presentation() {
    log "Starting iOS package creation"
    
    # Create iOS-specific assets
    mkdir -p "$BUILD_DIR/assets"
    
    # Copy presentation files
    cp -r "$GAIA_ROOT/presentations/ios/"* "$BUILD_DIR/"
    
    # Add Handoff support
    cat >> "$BUILD_DIR/index.html" << EOL
    <script>
        // Handoff Integration
        if ('serviceWorker' in navigator) {
            navigator.serviceWorker.register('handoff-worker.js');
        }
        
        // Enable Handoff functionality
        document.addEventListener('visibilitychange', () => {
            if (document.visibilityState === 'hidden') {
                // Save state for Handoff
                localStorage.setItem('handoffState', JSON.stringify({
                    section: currentSection,
                    timestamp: Date.now()
                }));
            }
        });
    </script>
EOL
    
    # Create service worker for Handoff
    cat > "$BUILD_DIR/handoff-worker.js" << EOL
    self.addEventListener('fetch', event => {
        if (event.request.headers.get('handoff')) {
            event.respondWith(
                caches.match(event.request)
                    .then(response => response || fetch(event.request))
            );
        }
    });
EOL
    
    # Create package
    cd "$BUILD_DIR"
    zip -r "../gaia_nexus_ios.zip" ./*
    
    log "Package created successfully"
}

# Setup Handoff via AppleScript
setup_handoff() {
    log "Setting up Handoff integration"
    
    osascript << EOL
    tell application "System Events"
        tell process "SystemUIServer"
            try
                set handoff to menu bar item "Handoff" of menu bar 1
                click handoff
            end try
        end tell
    end tell
EOL
}

# Transfer via AirDrop
transfer_airdrop() {
    log "Initiating AirDrop transfer"
    
    osascript << EOL
    tell application "Finder"
        activate
        select POSIX file "$BUILD_DIR/../gaia_nexus_ios.zip"
        tell application "System Events"
            keystroke "U" using {command down, shift down}
        end tell
    end tell
EOL
}

# Setup Drafts integration
setup_drafts() {
    log "Setting up Drafts integration"
    
    # Create Drafts action
    cat > "$BUILD_DIR/GaiaNexus.draftsAction" << EOL
    {
        "name": "Open Gaia Nexus",
        "description": "Open Gaia Nexus presentation",
        "type": "url",
        "url": "gaia-nexus://open?section={{section}}"
    }
EOL
}

# Main execution
echo -e "${BLUE}=== Gaia Nexus iOS Package Creator ===${NC}"

# Run all steps
package_presentation
setup_handoff
setup_drafts
transfer_airdrop

# Push to GitHub
log "Pushing to GitHub"
cd "$NEXUS_CORE"
git add .
git commit -m "Update iOS package with Handoff support"
git push origin main

echo -e "${GREEN}Package created and transferred successfully${NC}"
echo -e "${YELLOW}Check your iOS device for the AirDrop transfer${NC}"
