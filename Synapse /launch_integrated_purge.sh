#!/bin/bash

# Launcher for Integrated Cloud Purge System
echo "Launching Integrated Cloud Purge System..."

# Create necessary directories
mkdir -p ~/NEXUS_CORE/logs
mkdir -p /Volumes/Transfer/NEXUS_STAGING

# Check if Jupyter is running
JUPYTER_PORT=8888
JUPYTER_TOKEN=""

if ! nc -z localhost $JUPYTER_PORT; then
    echo "Starting Jupyter server..."
    jupyter notebook --no-browser --port=$JUPYTER_PORT --NotebookApp.token="" &
    sleep 5  # Wait for server to start
fi

# Start the integrated cloud purge system
echo "Starting cloud purge system..."
python3 /Users/nexus/Desktop/Synapse/integrated_cloud_purge.py &
PURGE_PID=$!

# Write PID to file
echo $PURGE_PID > ~/NEXUS_CORE/logs/cloud_purge.pid

echo "System initialized with PID: $PURGE_PID"
echo "Jupyter server running at: http://localhost:$JUPYTER_PORT"
echo "Monitor logs at: ~/NEXUS_CORE/logs/"

# Monitor logs
tail -f ~/NEXUS_CORE/logs/cloud_purge_*.log
