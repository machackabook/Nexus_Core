#!/bin/bash

# Colab Backend Launcher
echo "Initializing Colab Backend Integration..."

# Create necessary directories
mkdir -p drive_cache history_logs

# Check for existing process
if pgrep -f "colab_backend.py" > /dev/null; then
    echo "Stopping existing backend process..."
    pkill -f "colab_backend.py"
    sleep 2
fi

# Start backend
echo "Starting Colab backend..."
python3 /Users/nexus/Desktop/Synapse/colab_backend.py &
BACKEND_PID=$!

# Write PID to file
echo $BACKEND_PID > history_logs/backend.pid

# Open browser to backend interface
sleep 2
open -a Safari "http://localhost:8888"

echo "Backend initialized with PID: $BACKEND_PID"
echo "Access interface at: http://localhost:8888"
echo "Monitoring logs..."

# Monitor logs
tail -f history_logs/deletions.log
