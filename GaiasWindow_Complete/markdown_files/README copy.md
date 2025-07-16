# USB Power Issue Troubleshooting Toolkit

This toolkit contains scripts and tools to diagnose and fix MacBook shutdown issues when connecting USB devices.

## Key Scripts

### Before Connecting USB Device
- `usb_process_capture.sh`: Run this BEFORE connecting your USB device to capture all processes that start when the device is connected.
  ```bash
  ~/Documents/AmazonQChatLogs/usb_process_capture.sh
  ```

### After System Shutdown
- `enhanced_quick_recovery.sh`: Run this after a system shutdown to restore all monitoring and view conversation memory.
  ```bash
  ~/Documents/AmazonQChatLogs/enhanced_quick_recovery.sh
  ```

### Memory Management
- `memory_updater.sh`: Interactive tool to update conversation memory with notes, progress, and next steps.
  ```bash
  ~/Documents/AmazonQChatLogs/memory_updater.sh
  ```

### Monitoring Tools
- `usb_power_monitor_v2.sh`: Monitors USB device connections and logs events.
- `check_suspicious_processes.sh`: Identifies processes that might be causing shutdowns.
- `session_state_backup.sh`: Periodically saves the current troubleshooting state.

## Key Files
- `conversation_memory.txt`: Contains the memory of our troubleshooting conversation.
- `session_summary.md`: Comprehensive summary of the troubleshooting session.
- `RECOVERY_INSTRUCTIONS.txt`: Step-by-step recovery instructions.

## Workflow for Testing USB Device

1. Start the process capture:
   ```bash
   ~/Documents/AmazonQChatLogs/usb_process_capture.sh
   ```

2. Connect your problematic USB device.

3. If the system shuts down, after restarting run:
   ```bash
   ~/Documents/AmazonQChatLogs/enhanced_quick_recovery.sh
   ```

4. Update the conversation memory with new findings:
   ```bash
   ~/Documents/AmazonQChatLogs/memory_updater.sh
   ```

5. Continue troubleshooting based on the captured data.

## Log Locations
- Process capture logs: `~/Documents/AmazonQChatLogs/usb_process_capture_*.log`
- USB monitor logs: `~/Documents/AmazonQChatLogs/usb_power_monitor*.log`
- Session backups: `~/Documents/AmazonQChatLogs/session_backups/`
