#!/bin/bash

# Sarafin Master Script
# This script orchestrates the entire Sarafin environment setup
# Created: $(date)

# Set color codes
GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
BLUE='\033[34m'
PURPLE='\033[35m'
RESET='\033[0m'

echo -e "${GREEN}=== Sarafin Master Script Started ===${RESET}"
echo -e "${BLUE}Initializing Sarafin environment...${RESET}"

# Create log directory
mkdir -p ~/Documents/AmazonQChatLogs/sarafin_logs

# Log file
LOG_FILE="~/Documents/AmazonQChatLogs/sarafin_logs/master_$(date +"%Y%m%d_%H%M%S").log"

# Function to log messages
log_message() {
    echo "$(date): $1" >> $LOG_FILE
    echo -e "${GREEN}$1${RESET}"
}

# Function to display error messages
error_message() {
    echo "$(date): ERROR: $1" >> $LOG_FILE
    echo -e "${RED}ERROR: $1${RESET}"
}

# Function to display warning messages
warning_message() {
    echo "$(date): WARNING: $1" >> $LOG_FILE
    echo -e "${YELLOW}WARNING: $1${RESET}"
}

# Function to display system messages
system_message() {
    echo "$(date): SYSTEM: $1" >> $LOG_FILE
    echo -e "${PURPLE}SYSTEM: $1${RESET}"
}

# Function to check battery level
check_battery() {
    BATTERY_LEVEL=$(pmset -g batt | grep -o '[0-9]*%' | cut -d% -f1)
    log_message "Current battery level: $BATTERY_LEVEL%"
    
    if [ $BATTERY_LEVEL -ge 95 ]; then
        log_message "Battery level above 95%. Enabling high-performance mode."
        return 0
    elif [ $BATTERY_LEVEL -le 69 ]; then
        warning_message "Battery level at or below 69%. Reverting to normal operation mode."
        return 1
    else
        log_message "Battery level between 70% and 94%. Maintaining current performance settings."
        return 0
    }
}

# Function to configure terminal
configure_terminal() {
    system_message "Configuring Sarafin terminal environment..."
    
    # Run terminal configuration script
    bash ~/Documents/AmazonQChatLogs/terminal_config_sarafin.sh
    
    if [ $? -eq 0 ]; then
        log_message "Terminal configuration completed successfully"
    else
        error_message "Terminal configuration failed"
    fi
}

# Function to configure network security
configure_network_security() {
    system_message "Configuring network security..."
    
    # Run network security configuration script
    bash ~/Documents/AmazonQChatLogs/network_security_config.sh
    
    if [ $? -eq 0 ]; then
        log_message "Network security configuration completed successfully"
    else
        error_message "Network security configuration failed"
    fi
}

# Function to set up multi-OS environment
setup_multi_os() {
    system_message "Setting up multi-OS environment..."
    
    # Run multi-OS setup master script
    bash ~/Documents/AmazonQChatLogs/multi_os_setup_master.sh
    
    if [ $? -eq 0 ]; then
        log_message "Multi-OS environment setup completed successfully"
    else
        error_message "Multi-OS environment setup failed"
    fi
}

# Function to optimize system performance
optimize_performance() {
    system_message "Optimizing system performance..."
    
    # Check battery level
    check_battery
    HIGH_PERFORMANCE=$?
    
    if [ $HIGH_PERFORMANCE -eq 0 ]; then
        # High performance mode
        log_message "Enabling high performance mode"
        
        # Disable App Nap
        defaults write NSGlobalDomain NSAppSleepDisabled -bool YES
        
        # Disable sudden termination
        defaults write NSGlobalDomain NSDisableSuddenTermination -bool YES
        
        # Disable automatic termination
        defaults write NSGlobalDomain NSDisableAutomaticTermination -bool YES
        
        # Disable hibernation
        sudo pmset -a hibernatemode 0
        
        # Disable sleep
        sudo pmset -a sleep 0
        
        # Disable disk sleep
        sudo pmset -a disksleep 0
        
        log_message "High performance mode enabled"
    else
        # Normal operation mode
        log_message "Enabling normal operation mode"
        
        # Enable App Nap
        defaults write NSGlobalDomain NSAppSleepDisabled -bool NO
        
        # Enable sudden termination
        defaults write NSGlobalDomain NSDisableSuddenTermination -bool NO
        
        # Enable automatic termination
        defaults write NSGlobalDomain NSDisableAutomaticTermination -bool NO
        
        # Enable hibernation
        sudo pmset -a hibernatemode 3
        
        # Enable sleep (but set to a high value)
        sudo pmset -a sleep 180
        
        # Enable disk sleep (but set to a high value)
        sudo pmset -a disksleep 180
        
        log_message "Normal operation mode enabled"
    fi
}

# Function to display menu
show_menu() {
    clear
    echo -e "${BLUE}===== Sarafin Environment Control Panel =====${RESET}"
    echo -e "${YELLOW}1. Configure Terminal${RESET}"
    echo -e "${YELLOW}2. Configure Network Security${RESET}"
    echo -e "${YELLOW}3. Setup Multi-OS Environment${RESET}"
    echo -e "${YELLOW}4. Optimize System Performance${RESET}"
    echo -e "${YELLOW}5. Launch Sarafin Terminal${RESET}"
    echo -e "${YELLOW}6. Monitor Network Connections${RESET}"
    echo -e "${YELLOW}7. Check Battery Status${RESET}"
    echo -e "${YELLOW}8. Exit${RESET}"
    echo -e "${BLUE}==========================================${RESET}"
    echo -n "Enter your choice: "
}

# Main execution
system_message "Sarafin Master Script started"

# Check initial battery status
check_battery

# Main menu loop
while true; do
    show_menu
    read choice
    
    case $choice in
        1) configure_terminal ;;
        2) configure_network_security ;;
        3) setup_multi_os ;;
        4) optimize_performance ;;
        5) bash ~/Documents/AmazonQChatLogs/launch_sarafin.sh ;;
        6) netstat -an | grep ESTABLISHED ;;
        7) check_battery ;;
        8) 
            system_message "Exiting Sarafin Master Script"
            exit 0
            ;;
        *) 
            warning_message "Invalid choice. Please try again."
            ;;
    esac
    
    echo -e "${BLUE}Press Enter to continue...${RESET}"
    read
done
