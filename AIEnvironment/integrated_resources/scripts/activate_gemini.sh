#!/bin/bash

# Activate the Gemini virtual environment
source /Users/nexus/nexus-bridge/Nexus_Core/AIEnvironment/GeminiNexus/gemini_venv/bin/activate

# Set environment variables
export GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
export GEMINI_PROJECT="nexus-integration"

echo "Gemini virtual environment activated"
echo "Python executable: $(which python)"
echo "Python version: $(python --version)"

# You can add additional setup commands here
