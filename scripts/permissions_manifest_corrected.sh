#!/bin/zsh
# CORRECTED PERMISSIONS MANIFEST - macOS Only
# Visual system prompts for authorization process

echo "🔐 NEXUS PERMISSIONS MANIFEST (macOS Corrected)"
echo "Visual authorization with system prompts"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

echo -e "${YELLOW}=== CORRECTED REQUIREMENTS (macOS Only) ===${RESET}"
echo ""

echo -e "${BLUE}FULL DISK ACCESS:${RESET}"
echo "• iTerm.app"
echo "• Terminal.app" 
echo "• Amazon Q.app (or its daemon)"
echo "• Obsidian.app"
echo "• rclone (binary at /usr/local/bin/rclone or /opt/homebrew/bin/rclone)"
echo ""

echo -e "${BLUE}ACCESSIBILITY:${RESET}"
echo "• iTerm.app"
echo "• Automator.app"
echo "• System Events (for automation)"
echo ""

echo -e "${BLUE}AUTOMATION:${RESET}"
echo "• iTerm.app → System Events, Finder, Mail"
echo "• Automator.app → System Events, Finder"
echo ""

echo -e "${BLUE}DICTATION:${RESET}"
echo "• Enable in System Settings > Keyboard > Dictation"
echo "• Required for 'Abracadabra' voice protocol"
echo ""

echo -e "${YELLOW}=== VISUAL SETUP AVAILABLE ===${RESET}"
echo ""
echo "Run the visual setup script for guided authorization:"
echo -e "${GREEN}./scripts/visual_permissions_setup.sh${RESET}"
echo ""
echo "This will:"
echo "• Show dialog prompts for each permission"
echo "• Open the correct System Settings panes"
echo "• Guide you through each authorization step"
echo "• Verify completion with visual confirmation"
echo ""

# Check if visual setup has been completed
if [[ -f ~/NEXUS_CORE/.permissions_granted ]]; then
    echo -e "${GREEN}✅ PERMISSIONS MANIFEST COMPLETE${RESET}"
    echo -e "${GREEN}Visual authorization process completed successfully.${RESET}"
    
    # Show completion notification
    osascript -e 'display notification "All permissions granted successfully" with title "NEXUS Authorization Complete" sound name "Glass"'
else
    echo -e "${YELLOW}⏳ Ready for visual authorization process...${RESET}"
    echo ""
    echo "Choose your setup method:"
    echo "1. Visual guided setup: ./scripts/visual_permissions_setup.sh"
    echo "2. Manual setup: Follow the requirements above"
    echo "3. Mark complete: touch ~/NEXUS_CORE/.permissions_granted"
fi
