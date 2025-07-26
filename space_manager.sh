#!/bin/zsh
# Space Management Utility for NEXUS_CORE

TRANSFER_PATH="/Volumes/Transfer"
NEXUS_CORE_PATH="/Users/nexus/NEXUS_CORE"

echo "=== NEXUS Space Management ==="
echo "Current disk usage:"
df -h /System/Volumes/Data | tail -1

echo -e "\nTransfer volume status:"
df -h "$TRANSFER_PATH" | tail -1

echo -e "\nLarge files in user directory:"
du -sh /Users/nexus/* | sort -hr | head -5

echo -e "\nNEXUS_CORE directory usage:"
du -sh "$NEXUS_CORE_PATH"/*

# Function to move large files to Transfer volume
move_to_transfer() {
    local file="$1"
    local basename=$(basename "$file")
    
    if [ -f "$file" ] && [ ! -L "$file" ]; then
        echo "Moving $basename to Transfer volume..."
        mv "$file" "$TRANSFER_PATH/"
        ln -s "$TRANSFER_PATH/$basename" "$file"
        echo "Created symlink: $file -> $TRANSFER_PATH/$basename"
    fi
}

# Check for files that could be moved to Transfer
echo -e "\nChecking for files that can be moved to Transfer volume..."
if [ -d "$TRANSFER_PATH" ]; then
    echo "Transfer volume is available"
    mkdir -p "$TRANSFER_PATH/NEXUS_ARCHIVE"
else
    echo "Transfer volume not available"
fi
