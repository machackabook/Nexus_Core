#!/bin/bash
# Build script for Dictation App with Abracadabra Protocol integration

echo "Building Dictation App with Abracadabra Protocol integration..."

# Set up environment
export PATH="/Users/nexus/bin:$PATH"
cd /Users/nexus/Downloads/dictation-app

# Install dependencies
echo "Installing dependencies..."
/Users/nexus/bin/npm install

# Build the app
echo "Building the app..."
/Users/nexus/bin/npm run build

# Create integration directory
echo "Creating integration directory..."
mkdir -p /Users/nexus/Desktop/SharedLinks/abracadabra-dictation

# Copy built files
echo "Copying built files..."
cp -r dist/* /Users/nexus/Desktop/SharedLinks/abracadabra-dictation/

# Create integration script
cat > /Users/nexus/Desktop/SharedLinks/abracadabra-dictation/integrate.js << 'EOF'
// Abracadabra Protocol Integration Script
document.addEventListener('DOMContentLoaded', function() {
  // Listen for voice commands
  const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
  
  if (SpeechRecognition) {
    const recognition = new SpeechRecognition();
    recognition.continuous = true;
    recognition.interimResults = true;
    
    recognition.onresult = function(event) {
      const transcript = Array.from(event.results)
        .map(result => result[0])
        .map(result => result.transcript)
        .join('');
      
      if (transcript.toLowerCase().includes('abracadabra')) {
        console.log('Abracadabra command detected!');
        
        // Trigger the appropriate action
        if (transcript.toLowerCase().includes('capture')) {
          captureScreen();
        } else if (transcript.toLowerCase().includes('save')) {
          saveToCloud();
        } else if (transcript.toLowerCase().includes('read')) {
          readAloud();
        } else {
          // Default action
          captureScreen();
        }
      }
    };
    
    recognition.start();
    console.log('Abracadabra voice recognition active');
  }
  
  function captureScreen() {
    console.log('Capturing screen content...');
    // Implementation would depend on browser permissions
    // This is a placeholder
    
    const captureData = {
      timestamp: new Date().toISOString(),
      content: document.body.innerText,
      title: document.title
    };
    
    localStorage.setItem('abracadabra_capture', JSON.stringify(captureData));
    
    // Notify user
    const notification = document.createElement('div');
    notification.className = 'abracadabra-notification';
    notification.textContent = 'Screen content captured!';
    document.body.appendChild(notification);
    
    setTimeout(() => {
      notification.remove();
    }, 3000);
  }
  
  function saveToCloud() {
    console.log('Saving to cloud...');
    // Implementation would connect to cloud storage
    // This is a placeholder
    
    const captureData = localStorage.getItem('abracadabra_capture');
    if (captureData) {
      // In a real implementation, this would save to a cloud service
      console.log('Data ready for cloud save:', captureData);
      
      // Notify user
      const notification = document.createElement('div');
      notification.className = 'abracadabra-notification';
      notification.textContent = 'Saved to cloud!';
      document.body.appendChild(notification);
      
      setTimeout(() => {
        notification.remove();
      }, 3000);
    }
  }
  
  function readAloud() {
    console.log('Reading aloud...');
    // Implementation uses the Web Speech API
    
    const captureData = localStorage.getItem('abracadabra_capture');
    if (captureData) {
      const data = JSON.parse(captureData);
      const utterance = new SpeechSynthesisUtterance(data.content);
      utterance.rate = 1.0;
      utterance.pitch = 1.0;
      utterance.volume = 1.0;
      
      window.speechSynthesis.speak(utterance);
    } else {
      // Read current page if no capture exists
      const utterance = new SpeechSynthesisUtterance(document.body.innerText);
      window.speechSynthesis.speak(utterance);
    }
  }
});
EOF

# Create CSS for notifications
cat > /Users/nexus/Desktop/SharedLinks/abracadabra-dictation/abracadabra.css << 'EOF'
.abracadabra-notification {
  position: fixed;
  top: 20px;
  right: 20px;
  background-color: rgba(0, 0, 0, 0.8);
  color: white;
  padding: 15px 20px;
  border-radius: 5px;
  z-index: 9999;
  animation: fadeInOut 3s ease-in-out;
}

@keyframes fadeInOut {
  0% { opacity: 0; }
  10% { opacity: 1; }
  90% { opacity: 1; }
  100% { opacity: 0; }
}
EOF

# Update index.html to include integration
sed -i '' -e '</head>/i\
    <script src="integrate.js"></script>\
    <link rel="stylesheet" href="abracadabra.css">\
' /Users/nexus/Desktop/SharedLinks/abracadabra-dictation/index.html

# Create launcher script
cat > /Users/nexus/Desktop/SharedLinks/launch-dictation.sh << 'EOF'
#!/bin/bash
# Launcher for Dictation App with Abracadabra Protocol

# Start a simple HTTP server
cd /Users/nexus/Desktop/SharedLinks/abracadabra-dictation
python3 -m http.server 8000 &
SERVER_PID=$!

# Open the app in the browser
open http://localhost:8000

# Function to handle cleanup
cleanup() {
  echo "Shutting down server..."
  kill $SERVER_PID
  exit 0
}

# Set up trap for cleanup
trap cleanup INT TERM

# Wait for user to press Ctrl+C
echo "Dictation App with Abracadabra Protocol is running."
echo "Press Ctrl+C to stop the server."
wait
EOF

# Make launcher executable
chmod +x /Users/nexus/Desktop/SharedLinks/launch-dictation.sh

# Create symbolic link to Abracadabra Protocol
ln -sf /Users/nexus/Desktop/SharedLinks/abracadabra-dictation /Users/nexus/Desktop/SharedLinks/abracadabra_protocol/dictation

echo "Build complete! To launch the app, run:"
echo "/Users/nexus/Desktop/SharedLinks/launch-dictation.sh"
