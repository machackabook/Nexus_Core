#!/bin/bash

echo "Setting up integration environment..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install Node.js
echo "Installing Node.js..."
brew install node

# Create integration directories
echo "Creating integration directories..."
mkdir -p /Users/nexus/nexus-bridge/Nexus_Core/integrated_components/{webkit,disk_management,power_management,io_systems,security,network,utilities}

# Set up environment variables
echo "Setting up environment variables..."
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
echo 'export INTEGRATION_PATH="/Users/nexus/nexus-bridge/Nexus_Core/integrated_components"' >> ~/.zshrc

# Source updated environment
source ~/.zshrc

echo "Environment setup complete. Ready for integration."
