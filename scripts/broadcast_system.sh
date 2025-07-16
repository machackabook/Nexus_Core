#!/bin/bash

# NEXUS Broadcast System for Multi-Terminal Coordination
BROADCAST_DIR="/Users/nexus/NEXUS_CORE/broadcast"
mkdir -p "$BROADCAST_DIR"/{queue,active,completed}

broadcast_task() {
    local task_name="$1"
    local command="$2"
    local priority="${3:-normal}"
    
    local task_file="$BROADCAST_DIR/queue/${priority}_$(date +%s)_${task_name}.task"
    
    cat > "$task_file" << TASK_EOF
#!/bin/bash
# Task: $task_name
# Priority: $priority
# Created: $(date)

source /Users/nexus/NEXUS_CORE/scripts/audio_alerts.sh

echo "Executing broadcast task: $task_name"
audio_checkpoint "info" "Starting task $task_name"

$command

if [ \$? -eq 0 ]; then
    audio_checkpoint "success" "Task $task_name completed successfully"
    mv "$task_file" "$BROADCAST_DIR/completed/"
else
    audio_checkpoint "error" "Task $task_name failed"
fi
TASK_EOF

    chmod +x "$task_file"
    echo "✓ Broadcast task '$task_name' queued with priority: $priority"
}

# Task processor daemon
start_task_processor() {
    while true; do
        for task in "$BROADCAST_DIR/queue"/*.task; do
            if [ -f "$task" ]; then
                mv "$task" "$BROADCAST_DIR/active/"
                bash "$BROADCAST_DIR/active/$(basename "$task")" &
            fi
        done
        sleep 5
    done
}

export -f broadcast_task
export -f start_task_processor
