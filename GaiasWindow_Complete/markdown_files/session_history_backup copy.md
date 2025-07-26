# Amazon Q Session History Backup
Created: $(date)

## Problem Summary
- MacBook crashes upon USB device connection within 1-2 minutes
- Issue occurs immediately after reconnecting the device
- Appears to be on a timer (~60 seconds after connection)
- Likely related to AMPDeviceDiscoveryAgent and USB power management

## Key Findings
1. AMPDeviceDiscoveryAgent appears to trigger the shutdown sequence
2. Device only restarts when charger is reconnected
3. Battery level remains the same after shutdown/restart
4. Suggests a kext or EFI level mechanism rather than normal shutdown

## Solutions Developed
1. USB Power Management Prevention Tool
   - Disables AMPDeviceDiscoveryAgent
   - Modifies power management settings
   - Extends grace periods for power events
   - Monitors for shutdown triggers

2. Fallback Prevention Script
   - Emergency shutdown prevention
   - USB controller reset functionality
   - Continuous system state monitoring

## Next Steps
1. Test iPhone 8 connection via auxiliary port
2. Create recovery partition with Amazon Q CLI access
3. Implement watchdog functionality for system monitoring
4. Configure wake-on-LAN for remote access
5. Disable sleep while on charger

## Technical Notes
- AMPDeviceDiscoveryAgent located at: /System/Library/PrivateFrameworks/AMPDevices.framework/Versions/A/Support/AMPDeviceDiscoveryAgent
- USB events logged in usb_process_capture logs
- Power management controlled via pmset
- Potential need for kext-level intervention
