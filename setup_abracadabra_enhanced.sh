#!/bin/bash
# Enhanced Setup script for Abracadabra Protocol
# Created: July 15, 2025

echo "===== Setting up Enhanced Abracadabra Protocol ====="

# Create necessary directories
echo "Creating required directories..."
mkdir -p ~/Desktop/SharedLinks/captures

# Copy the AppleScript to the SharedLinks folder
echo "Installing AppleScript..."
cp ~/NEXUS_CORE/enhanced_abracadabra.applescript ~/Desktop/SharedLinks/abracadabra_protocol.applescript

# Compile AppleScript to application
echo "Compiling AppleScript to application..."
osacompile -o ~/Desktop/SharedLinks/AbracadabraProtocol.app ~/Desktop/SharedLinks/abracadabra_protocol.applescript

# Set executable permissions
chmod +x ~/Desktop/SharedLinks/AbracadabraProtocol.app/Contents/MacOS/*

# Create symbolic link in Applications folder
echo "Creating symbolic link in Applications folder..."
ln -sf ~/Desktop/SharedLinks/AbracadabraProtocol.app ~/Applications/
ln -sf ~/Desktop/SharedLinks/AbracadabraProtocol.app /Applications/

# Create integration with dictation app
echo "Setting up integration with dictation app..."
cat > ~/Desktop/SharedLinks/abracadabra-dictation/abracadabra-integration.js << 'EOL'
// Abracadabra Protocol Integration
// This script integrates the dictation app with the Abracadabra Protocol

document.addEventListener('DOMContentLoaded', function() {
    // Add Abracadabra Protocol button
    const controlPanel = document.querySelector('.control-panel');
    if (controlPanel) {
        const abracadabraBtn = document.createElement('button');
        abracadabraBtn.className = 'control-btn abracadabra-btn';
        abracadabraBtn.innerHTML = '<i class="fas fa-magic"></i> Abracadabra';
        abracadabraBtn.title = 'Activate Abracadabra Protocol';
        
        abracadabraBtn.addEventListener('click', function() {
            activateAbracadabra();
        });
        
        controlPanel.appendChild(abracadabraBtn);
    }
    
    // Add voice command listener
    if (window.webkitSpeechRecognition) {
        const recognition = new webkitSpeechRecognition();
        recognition.continuous = true;
        recognition.interimResults = true;
        
        recognition.onresult = function(event) {
            for (let i = event.resultIndex; i < event.results.length; i++) {
                const transcript = event.results[i][0].transcript.trim().toLowerCase();
                
                if (transcript.includes('abracadabra')) {
                    activateAbracadabra();
                }
            }
        };
        
        // Start listening
        try {
            recognition.start();
        } catch (e) {
            console.log('Speech recognition already started');
        }
    }
});

function activateAbracadabra() {
    // Open the Abracadabra Protocol app
    const iframe = document.createElement('iframe');
    iframe.style.display = 'none';
    iframe.src = 'abracadabra://activate';
    document.body.appendChild(iframe);
    
    // Show notification
    showNotification('Abracadabra Protocol activated');
    
    // Remove iframe after a short delay
    setTimeout(() => {
        document.body.removeChild(iframe);
    }, 100);
}

function showNotification(message) {
    const notification = document.createElement('div');
    notification.className = 'abracadabra-notification';
    notification.textContent = message;
    
    // Style the notification
    notification.style.position = 'fixed';
    notification.style.bottom = '20px';
    notification.style.right = '20px';
    notification.style.backgroundColor = 'rgba(75, 0, 130, 0.9)';
    notification.style.color = 'white';
    notification.style.padding = '10px 20px';
    notification.style.borderRadius = '5px';
    notification.style.zIndex = '9999';
    notification.style.transition = 'opacity 0.5s';
    
    document.body.appendChild(notification);
    
    // Remove after 3 seconds
    setTimeout(() => {
        notification.style.opacity = '0';
        setTimeout(() => {
            document.body.removeChild(notification);
        }, 500);
    }, 3000);
}
EOL

# Add CSS for Abracadabra integration
cat >> ~/Desktop/SharedLinks/abracadabra-dictation/abracadabra.css << 'EOL'
/* Abracadabra Protocol Integration Styles */
.abracadabra-btn {
    background-color: #4B0082;
    color: white;
}

.abracadabra-btn:hover {
    background-color: #6A0DAD;
}

.abracadabra-notification {
    box-shadow: 0 4px 8px rgba(0,0,0,0.2);
    animation: fadeIn 0.5s;
}

@keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
}
EOL

# Update the HTML to include the integration
sed -i.bak 's/<\/head>/<link rel="stylesheet" href="abracadabra.css">\n<script src="abracadabra-integration.js"><\/script>\n<\/head>/' ~/Desktop/SharedLinks/abracadabra-dictation/index.html

# Create a README file with instructions
cat > ~/Desktop/SharedLinks/ABRACADABRA_README.md << 'EOL'
# Abracadabra Protocol

## Overview
The Abracadabra Protocol is a voice-activated system that enables screen reading, content capture, and saving through simple voice commands.

## Voice Commands
- **"abracadabra"** - Activate the protocol and read screen content
- **"abracadabra capture"** - Capture the current screen content
- **"abracadabra save"** - Save the last captured content
- **"abracadabra read"** - Read the current screen content

## Required Permissions
For the Abracadabra Protocol to work properly, you need to grant the following permissions:

1. Open System Preferences > Security & Privacy > Privacy
2. Grant permissions for:
   - Accessibility
   - Speech Recognition
   - Automation
   - Files and Folders

## Integration with Dictation App
The Abracadabra Protocol is integrated with the dictation app. You can activate it by:
- Saying "abracadabra" while the dictation app is running
- Clicking the Abracadabra button in the dictation app interface

## Captured Content
All captured content is saved in the ~/Desktop/SharedLinks/captures folder.

## Troubleshooting
If the protocol is not responding to voice commands:
1. Make sure all permissions are granted
2. Restart the application by opening /Applications/AbracadabraProtocol.app
3. Check if Speech Recognition is enabled in System Preferences > Accessibility > Voice Control

## Support
For assistance, contact the Nexus Core support team.
EOL

# Guide user through permissions setup
echo "=============================================="
echo "IMPORTANT: You need to grant the following permissions:"
echo "1. Open System Preferences > Security & Privacy > Privacy"
echo "2. Grant permissions for:"
echo "   - Accessibility"
echo "   - Speech Recognition"
echo "   - Automation"
echo "   - Files and Folders"
echo "=============================================="

# Ask if user wants to open System Preferences
read -p "Would you like to open System Preferences now? (y/n): " answer
if [[ $answer == "y" || $answer == "Y" ]]; then
    open "x-apple.systempreferences:com.apple.preference.security?Privacy"
fi

# Ask if user wants to launch the application
read -p "Would you like to launch Abracadabra Protocol now? (y/n): " launch
if [[ $launch == "y" || $launch == "Y" ]]; then
    open /Applications/AbracadabraProtocol.app
fi

echo "Setup complete! Say 'abracadabra' to activate the protocol."
echo "For more information, see ~/Desktop/SharedLinks/ABRACADABRA_README.md"
