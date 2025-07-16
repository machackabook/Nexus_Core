#!/bin/bash

# NEXUS MASTER CONTROL INTERFACE
# Complete system orchestration

source "/Users/nexus/NEXUS_CORE/scripts/audio_alerts.sh"
source "/Users/nexus/NEXUS_CORE/scripts/broadcast_system.sh"

NEXUS_STATUS_FILE="/Users/nexus/NEXUS_CORE/logs/nexus_status.json"

show_system_status() {
    clear
    echo "╔════════════════════════════════════════════════════════════════════════╗"
    echo "║                          NEXUS MASTER CONTROL                         ║"
    echo "╠════════════════════════════════════════════════════════════════════════╣"
    echo "║ System Status: $(date)                                    ║"
    echo "╠════════════════════════════════════════════════════════════════════════╣"
    
    # Tier Status
    echo "║ TIER STATUS:                                                           ║"
    echo "║ [✓] Tier 1: Foundation Infrastructure                                 ║"
    echo "║ [✓] Tier 2: Automation Infrastructure                                 ║"
    echo "║ [✓] Tier 3: Network Monitoring & Security                             ║"
    echo "║ [✓] Tier 4: Minion Deployment System                                  ║"
    echo "║ [✓] Tier 5: Cross-Platform Integration                                ║"
    echo "╠════════════════════════════════════════════════════════════════════════╣"
    
    # Active Services
    echo "║ ACTIVE SERVICES:                                                       ║"
    
    # Check port monitor
    if pgrep -f "port_monitor.sh" > /dev/null; then
        echo "║ [✓] Port Monitor: ACTIVE                                               ║"
    else
        echo "║ [✗] Port Monitor: INACTIVE                                             ║"
    fi
    
    # Check GitHub monitor
    if pgrep -f "github_monitor.sh" > /dev/null; then
        echo "║ [✓] GitHub Monitor: ACTIVE                                             ║"
    else
        echo "║ [✗] GitHub Monitor: INACTIVE                                           ║"
    fi
    
    # Check minion control
    if pgrep -f "minion_control.sh" > /dev/null; then
        echo "║ [✓] Minion Control: ACTIVE                                             ║"
    else
        echo "║ [✗] Minion Control: INACTIVE                                           ║"
    fi
    
    # Storage status
    echo "╠════════════════════════════════════════════════════════════════════════╣"
    echo "║ STORAGE STATUS:                                                        ║"
    df -h / | awk 'NR==2 {printf "║ Root Volume: %s used of %s (Available: %s)                    ║\n", $3, $2, $4}'
    
    if [ -d "/Volumes/Transfer" ]; then
        df -h /Volumes/Transfer | awk 'NR==2 {printf "║ Transfer Volume: %s used of %s (Available: %s)                ║\n", $3, $2, $4}'
    fi
    
    echo "╚════════════════════════════════════════════════════════════════════════╝"
}

start_all_services() {
    audio_checkpoint "info" "Starting all NEXUS services"
    
    # Start monitoring services
    nohup /Users/nexus/NEXUS_CORE/scripts/port_monitor.sh > /dev/null 2>&1 &
    nohup /Users/nexus/NEXUS_CORE/scripts/github_monitor.sh > /dev/null 2>&1 &
    
    # Start minion services
    nohup /Volumes/Transfer/NEXUS_AUTOMATOR/minions/minion_control.sh monitor > /dev/null 2>&1 &
    
    # Start sync service
    nohup python3 /Volumes/Transfer/NEXUS_AUTOMATOR/webos/sync/sync_service.py > /dev/null 2>&1 &
    
    # Start task processor
    nohup bash -c 'source /Users/nexus/NEXUS_CORE/scripts/broadcast_system.sh && start_task_processor' > /dev/null 2>&1 &
    
    audio_checkpoint "success" "All NEXUS services started"
}

stop_all_services() {
    audio_checkpoint "info" "Stopping all NEXUS services"
    
    pkill -f "port_monitor.sh"
    pkill -f "github_monitor.sh"
    pkill -f "minion_control.sh"
    pkill -f "sync_service.py"
    pkill -f "start_task_processor"
    
    audio_checkpoint "success" "All NEXUS services stopped"
}

case "$1" in
    "status")
        show_system_status
        ;;
    "start")
        start_all_services
        ;;
    "stop")
        stop_all_services
        ;;
    "restart")
        stop_all_services
        sleep 2
        start_all_services
        ;;
    *)
        echo "NEXUS Master Control"
        echo "Usage: $0 {status|start|stop|restart}"
        echo ""
        echo "Commands:"
        echo "  status   - Show system status dashboard"
        echo "  start    - Start all NEXUS services"
        echo "  stop     - Stop all NEXUS services"
        echo "  restart  - Restart all NEXUS services"
        ;;
esac
