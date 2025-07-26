# Sarafin Environment

## Overview
The Sarafin environment is a specialized multi-OS setup designed for running different AI models natively across macOS, Windows 10, and ChromeOS Flex. This environment includes advanced network security, performance optimization, and cross-OS integration.

## Color Scheme
- **Background**: Black
- **Text**: White
- **Code**: Green
- **Alerts**: Red
- **Conversation Responses**: Yellow and Blue
- **System Commands**: Purple

## Components

### 1. Terminal Configuration
- Custom terminal profile with the Sarafin color scheme
- Auto-launch at login
- Multiple tabs for different functions
- Saved window group for persistent configuration

### 2. Network Security
- Comprehensive network monitoring
- Connection logging and alerting
- Geolocation of IP addresses
- Integration with Little Snitch (if available)
- Firewall configuration

### 3. Multi-OS Environment
- Windows 10 (50GB): For running Copilot and Windows-specific AI models
- ChromeOS Flex (20GB): For Gemini's environment and Google services
- Shared File System (15GB): For cross-OS scripts and data

### 4. Performance Optimization
- Dynamic performance based on battery level
- High-performance mode when battery > 95%
- Normal operation mode when battery ≤ 69%
- Power management configuration

## Usage

### Starting the Environment
Run the Sarafin master script:
```bash
~/Documents/AmazonQChatLogs/sarafin_master.sh
```

### Control Panel Options
1. Configure Terminal
2. Configure Network Security
3. Setup Multi-OS Environment
4. Optimize System Performance
5. Launch Sarafin Terminal
6. Monitor Network Connections
7. Check Battery Status
8. Exit

### Launching Individual Components
- Terminal: `~/Documents/AmazonQChatLogs/launch_sarafin.sh`
- Network Security: `~/Documents/AmazonQChatLogs/network_security_config.sh`
- Multi-OS Setup: `~/Documents/AmazonQChatLogs/multi_os_setup_master.sh`

## File Structure
- `~/Documents/AmazonQChatLogs/sarafin_master.sh`: Main control script
- `~/Documents/AmazonQChatLogs/terminal_config_sarafin.sh`: Terminal configuration
- `~/Documents/AmazonQChatLogs/network_security_config.sh`: Network security setup
- `~/Documents/AmazonQChatLogs/multi_os_setup_master.sh`: Multi-OS environment setup
- `~/Documents/AmazonQChatLogs/launch_sarafin.sh`: Terminal launcher
- `~/Documents/AmazonQChatLogs/sarafin_logs/`: Log files

## Security Features
- Real-time network connection monitoring
- Alert system for suspicious connections
- IP geolocation tracking
- Firewall configuration
- Connection restriction

## Performance Features
- Dynamic performance based on battery level
- Process optimization
- Memory management
- Disk I/O optimization

## Cross-OS Integration
- Shared file system accessible from all OSes
- Cross-platform scripts with OS-specific implementations
- Boot manager for easy OS selection
- Recovery mechanisms for each OS
