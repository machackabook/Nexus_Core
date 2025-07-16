#!/bin/bash
echo "USB Device Monitor - Press Ctrl+C to stop"
echo "Connect/disconnect your iPhone now..."
echo "----------------------------------------"

# Monitor system log for USB events
log stream --predicate 'subsystem contains "usb" OR subsystem contains "iokit" OR process == "usbmuxd"' --info --debug &
LOG_PID=$!

# Also monitor ioreg changes
while true; do
    echo "=== $(date) ==="
    ioreg -p IOUSB -w0 | grep -i "iphone\|ipad\|apple\|mobile" || echo "No iOS devices detected"
    sleep 2
done &
IOREG_PID=$!

# Cleanup function
cleanup() {
    echo "Stopping monitors..."
    kill $LOG_PID $IOREG_PID 2>/dev/null
    exit 0
}

trap cleanup INT
wait
