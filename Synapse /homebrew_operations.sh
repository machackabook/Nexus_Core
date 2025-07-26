#!/bin/bash

echo "=== Starting Homebrew Operations ==="
echo "Timestamp: $(date)"

# Function to log operations
log_operation() {
    echo "[$(date +%H:%M:%S)] $1"
}

# Check Homebrew installation
log_operation "Checking Homebrew installation..."
if ! command -v brew &> /dev/null; then
    log_operation "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    log_operation "Homebrew already installed"
fi

# Update Homebrew
log_operation "Updating Homebrew..."
brew update

# Install required packages
log_operation "Installing required packages..."
packages=(
    "node"
    "cmake"
    "wget"
    "git"
    "python3"
)

for package in "${packages[@]}"; do
    log_operation "Installing $package..."
    brew install $package
done

log_operation "Homebrew operations complete"
echo "=== Homebrew Setup Complete ==="
