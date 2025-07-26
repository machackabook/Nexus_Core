#!/bin/zsh
# VISUAL PERMISSIONS SETUP - System Prompts for Authorization
# Creates visual acknowledgment and triggers actual permission dialogs

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

show_permission_dialog() {
    local title="$1"
    local message="$2"
    local button_text="${3:-Continue}"
    
    osascript << EOF
display dialog "$message" with title "$title" buttons {"Cancel", "$button_text"} default button "$button_text" with icon caution
EOF
}

trigger_full_disk_access() {
    local app_name="$1"
    echo -e "${CYAN}🔐 Triggering Full Disk Access request for $app_name...${RESET}"
    
    # Show visual prompt first
    show_permission_dialog "NEXUS Authorization Required" "About to request Full Disk Access for $app_name.\n\nThis will open System Settings where you need to:\n1. Click the '+' button\n2. Navigate to and select $app_name\n3. Enable the toggle switch\n\nClick Continue when ready." "Open Settings"
    
    # Open System Settings to the Full Disk Access pane
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
    
    # Wait for user acknowledgment
    show_permission_dialog "Permission Status" "Have you successfully added $app_name to Full Disk Access?" "Yes, Added"
}

trigger_accessibility_access() {
    local app_name="$1"
    echo -e "${CYAN}♿ Triggering Accessibility request for $app_name...${RESET}"
    
    show_permission_dialog "NEXUS Accessibility Required" "About to request Accessibility access for $app_name.\n\nThis will open System Settings where you need to:\n1. Click the '+' button\n2. Navigate to and select $app_name\n3. Enable the toggle switch\n\nClick Continue when ready." "Open Settings"
    
    # Open System Settings to Accessibility pane
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    
    show_permission_dialog "Permission Status" "Have you successfully added $app_name to Accessibility?" "Yes, Added"
}

trigger_automation_access() {
    local source_app="$1"
    local target_apps="$2"
    echo -e "${CYAN}🤖 Setting up Automation for $source_app → $target_apps...${RESET}"
    
    show_permission_dialog "NEXUS Automation Setup" "About to configure Automation permissions.\n\n$source_app needs permission to control:\n$target_apps\n\nSystem Settings will open to the Automation pane.\nLook for $source_app and enable the required targets." "Open Settings"
    
    # Open System Settings to Automation pane
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
    
    show_permission_dialog "Automation Status" "Have you enabled $source_app to control the required applications?" "Yes, Configured"
}

setup_dictation() {
    echo -e "${CYAN}🎤 Setting up Dictation for Abracadabra protocol...${RESET}"
    
    show_permission_dialog "NEXUS Dictation Setup" "About to enable Dictation for voice commands.\n\nSystem Settings will open to Keyboard > Dictation.\nPlease:\n1. Turn ON Dictation\n2. Choose your preferred language\n3. Select microphone source\n\nThis enables the 'Abracadabra' voice protocol." "Open Settings"
    
    # Open Keyboard settings
    open "x-apple.systempreferences:com.apple.Keyboard-Settings.extension"
    
    show_permission_dialog "Dictation Status" "Have you successfully enabled Dictation?" "Yes, Enabled"
}

create_permission_test() {
    local app_name="$1"
    local permission_type="$2"
    
    # Create a test that will trigger the permission request
    case "$permission_type" in
        "full_disk")
            # Try to access a protected directory to trigger Full Disk Access prompt
            osascript << EOF
try
    tell application "$app_name"
        activate
    end tell
    
    -- This will trigger Full Disk Access if not already granted
    do shell script "ls ~/Library/Application\\ Support/ > /dev/null 2>&1"
on error
    display dialog "Permission request triggered for $app_name" buttons {"OK"} default button "OK"
end try
EOF
            ;;
        "accessibility")
            # Try to use accessibility features to trigger prompt
            osascript << EOF
try
    tell application "System Events"
        tell application "$app_name" to activate
        -- This will trigger Accessibility prompt if not granted
        get name of every process
    end tell
on error
    display dialog "Accessibility permission request triggered for $app_name" buttons {"OK"} default button "OK"
end try
EOF
            ;;
    esac
}

main_setup_sequence() {
    echo -e "${BLUE}🚀 NEXUS VISUAL PERMISSIONS SETUP${RESET}"
    echo -e "${BLUE}Creating system prompts for authorization process${RESET}"
    echo ""
    
    # Welcome dialog
    show_permission_dialog "NEXUS Integration Protocol" "Welcome to the NEXUS Permissions Setup.\n\nThis process will guide you through granting the necessary system permissions for full integration.\n\nEach step will:\n1. Show you what's needed\n2. Open the correct System Settings pane\n3. Wait for your confirmation\n\nReady to begin?" "Let's Start"
    
    echo -e "${YELLOW}=== PHASE 1: FULL DISK ACCESS ===${RESET}"
    
    # Full Disk Access for each app
    apps_full_disk=(
        "iTerm"
        "Terminal"
        "Obsidian"
    )
    
    for app in "${apps_full_disk[@]}"; do
        echo -e "${CYAN}Setting up Full Disk Access for $app...${RESET}"
        trigger_full_disk_access "$app"
        sleep 2
    done
    
    # Special handling for rclone (binary file)
    echo -e "${CYAN}Setting up Full Disk Access for rclone...${RESET}"
    show_permission_dialog "rclone Binary Access" "rclone is a command-line tool that needs Full Disk Access.\n\nIn the next dialog:\n1. Click '+' to add\n2. Press Cmd+Shift+G to 'Go to Folder'\n3. Type: /usr/local/bin/rclone\n4. Click 'Go' and select rclone\n5. Enable the toggle\n\nIf rclone isn't there, try: /opt/homebrew/bin/rclone" "Open Settings"
    
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
    show_permission_dialog "rclone Status" "Have you successfully added rclone to Full Disk Access?" "Yes, Added"
    
    echo -e "${YELLOW}=== PHASE 2: ACCESSIBILITY ACCESS ===${RESET}"
    
    apps_accessibility=(
        "iTerm"
        "Automator"
    )
    
    for app in "${apps_accessibility[@]}"; do
        echo -e "${CYAN}Setting up Accessibility for $app...${RESET}"
        trigger_accessibility_access "$app"
        sleep 2
    done
    
    echo -e "${YELLOW}=== PHASE 3: AUTOMATION PERMISSIONS ===${RESET}"
    
    trigger_automation_access "iTerm" "System Events, Finder, Mail"
    
    echo -e "${YELLOW}=== PHASE 4: DICTATION SETUP ===${RESET}"
    
    setup_dictation
    
    echo -e "${YELLOW}=== PHASE 5: VERIFICATION ===${RESET}"
    
    # Final verification dialog
    show_permission_dialog "Setup Complete" "NEXUS Permissions Setup is complete!\n\nPlease verify all permissions are granted:\n✓ Full Disk Access: iTerm, Terminal, Obsidian, rclone\n✓ Accessibility: iTerm, Automator\n✓ Automation: iTerm controls System Events/Finder/Mail\n✓ Dictation: Enabled\n\nClick 'Launch Sequence' to activate NEXUS Integration." "Launch Sequence"
    
    # Mark permissions as granted
    touch ~/NEXUS_CORE/.permissions_granted
    
    echo -e "${GREEN}🎉 PERMISSIONS MANIFEST COMPLETE${RESET}"
    echo -e "${GREEN}The human handshake has been acknowledged.${RESET}"
    echo -e "${GREEN}NEXUS Integration Protocol is ready for activation.${RESET}"
    
    # Final system notification
    osascript -e 'display notification "NEXUS Integration Protocol Ready" with title "System Authorization Complete" sound name "Glass"'
    osascript -e 'say "NEXUS Integration Protocol activated. All systems ready for operation."'
}

# Execute main setup
main_setup_sequence
