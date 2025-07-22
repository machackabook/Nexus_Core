#!/bin/bash

# Enhanced USB Monitor with Power Management
echo "Enhanced USB Device Monitor with Power Management"
echo "-----------------------------------------------"

# Function to monitor USB power states
monitor_usb_power() {
    system_profiler SPUSBDataType | grep -A 4 "Current Available (mA):"
}

# Function to check device power requirements
check_power_requirements() {
    ioreg -p IOUSB -l -w0 | grep -i "MaxPower\|Current Available"
}

# Main monitoring loop
while true; do
    echo "=== $(date) ==="
    echo "USB Power Status:"
    monitor_usb_power
    
    echo -e "\nDevice Power Requirements:"
    check_power_requirements
    
    echo -e "\nUSB Device Status:"
    ioreg -p IOUSB -w0 | grep -i "iphone\|ipad\|apple\|mobile" || echo "No iOS devices detected"
    
    # Log power events
    log stream --predicate 'subsystem contains "usb" OR subsystem contains "power"' --info --debug &
    LOG_PID=$!
    
    sleep 5
    kill $LOG_PID 2>/dev/null
done

# Cleanup function
cleanup() {
    echo "Stopping power monitoring..."
    kill $LOG_PID 2>/dev/null
    exit 0
}

trap cleanup INT
