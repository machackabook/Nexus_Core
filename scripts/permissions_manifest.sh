#!/bin/zsh
# PERMISSIONS MANIFEST - The Final Human Handshake
# Verifies and guides setup of required system permissions

echo "🔐 NEXUS PERMISSIONS MANIFEST"
echo "The final human handshake to empower our integrated system"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

check_permission() {
    local app_name="$1"
    local permission_type="$2"
    
    echo -e "${BLUE}Checking $permission_type for $app_name...${RESET}"
    
    # This is a simplified check - actual permission verification requires more complex queries
    case "$permission_type" in
        "Full Disk Access")
            # Check if app has full disk access
            if sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "SELECT * FROM access WHERE service='kTCCServiceSystemPolicyAllFiles' AND client='$app_name';" 2>/dev/null | grep -q "$app_name"; then
                echo -e "${GREEN}✅ $app_name has Full Disk Access${RESET}"
            else
                echo -e "${RED}❌ $app_name needs Full Disk Access${RESET}"
            fi
            ;;
        "Accessibility")
            if sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "SELECT * FROM access WHERE service='kTCCServiceAccessibility' AND client='$app_name';" 2>/dev/null | grep -q "$app_name"; then
                echo -e "${GREEN}✅ $app_name has Accessibility access${RESET}"
            else
                echo -e "${RED}❌ $app_name needs Accessibility access${RESET}"
            fi
            ;;
        *)
            echo -e "${YELLOW}⚠️ Manual verification required for $permission_type${RESET}"
            ;;
    esac
}

echo -e "${YELLOW}=== FULL DISK ACCESS REQUIREMENTS ===${RESET}"
echo "Navigate to: System Settings > Privacy & Security > Full Disk Access"
echo ""

apps_full_disk=(
    "iTerm.app"
    "Terminal.app" 
    "Amazon Q.app"
    "Obsidian.app"
    "rclone"
)

for app in "${apps_full_disk[@]}"; do
    check_permission "$app" "Full Disk Access"
done

echo ""
echo -e "${YELLOW}=== ACCESSIBILITY REQUIREMENTS ===${RESET}"
echo "Navigate to: System Settings > Privacy & Security > Accessibility"
echo ""

apps_accessibility=(
    "iTerm.app"
    "Automator.app"
    "Shortcuts.app"
)

for app in "${apps_accessibility[@]}"; do
    check_permission "$app" "Accessibility"
done

echo ""
echo -e "${YELLOW}=== AUTOMATION REQUIREMENTS ===${RESET}"
echo "Navigate to: System Settings > Privacy & Security > Automation"
echo ""
echo "Required automation permissions:"
echo "• iTerm.app → System Events, Finder, Mail"
echo "• Shortcuts.app → iTerm.app, Working Copy"

echo ""
echo -e "${YELLOW}=== DICTATION SETUP ===${RESET}"
echo "Navigate to: System Settings > Keyboard > Dictation"
echo "Ensure Dictation is enabled for 'Abracadabra' protocol"

# Check if dictation is enabled
if defaults read com.apple.speech.recognition.AppleSpeechRecognition.prefs DictationIMMasterDictationEnabled 2>/dev/null | grep -q "1"; then
    echo -e "${GREEN}✅ Dictation is enabled${RESET}"
else
    echo -e "${RED}❌ Dictation needs to be enabled${RESET}"
fi

echo ""
echo -e "${BLUE}=== MANUAL VERIFICATION STEPS ===${RESET}"
echo ""
echo "1. Open System Settings"
echo "2. Navigate to Privacy & Security"
echo "3. For each category below, add the specified applications:"
echo ""
echo -e "${YELLOW}Full Disk Access:${RESET}"
echo "   • iTerm"
echo "   • Terminal" 
echo "   • Amazon Q (or its daemon)"
echo "   • Obsidian"
echo "   • rclone (may need to browse to /usr/local/bin/rclone)"
echo ""
echo -e "${YELLOW}Accessibility:${RESET}"
echo "   • iTerm"
echo "   • Automator"
echo "   • Shortcuts"
echo ""
echo -e "${YELLOW}Automation:${RESET}"
echo "   • Grant iTerm permission to control:"
echo "     - System Events"
echo "     - Finder"
echo "     - Mail"
echo "   • Grant Shortcuts permission to control:"
echo "     - iTerm"
echo "     - Working Copy"
echo ""

# Create verification completion marker
echo ""
echo -e "${BLUE}After completing permissions setup, run:${RESET}"
echo "touch ~/NEXUS_CORE/.permissions_granted"
echo ""
echo -e "${GREEN}This will mark the human handshake as complete.${RESET}"

# Check if permissions have been marked as complete
if [[ -f ~/NEXUS_CORE/.permissions_granted ]]; then
    echo ""
    echo -e "${GREEN}🎉 PERMISSIONS MANIFEST COMPLETE${RESET}"
    echo -e "${GREEN}The human handshake has been acknowledged.${RESET}"
    echo -e "${GREEN}NEXUS Integration Protocol is ready for activation.${RESET}"
else
    echo ""
    echo -e "${YELLOW}⏳ Awaiting human handshake completion...${RESET}"
    echo -e "${YELLOW}Run 'touch ~/NEXUS_CORE/.permissions_granted' when done.${RESET}"
fi
