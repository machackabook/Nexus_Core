-- Enhanced Abracadabra Protocol: Voice Command System for Screen Reading and Content Capture
-- Created: July 15, 2025
-- This script enables voice commands for screen reading, content capture, and saving

-- Global variables
global lastCapturedContent
global captureMode
global capturesFolder

-- Initialize the script
on initialize()
    set captureMode to "read" -- Default mode: read, capture, save
    set lastCapturedContent to ""
    set capturesFolder to (path to desktop folder as text) & "SharedLinks:captures:"
    
    -- Create captures folder if it doesn't exist
    tell application "Finder"
        if not (exists folder capturesFolder) then
            make new folder at (path to desktop folder as text) & "SharedLinks:" with properties {name:"captures"}
        end if
    end tell
    
    -- Start listening for voice commands
    startListening()
end initialize

-- Start the speech recognition system
on startListening()
    -- In a real implementation, this would use macOS's speech recognition API
    -- For now, we'll simulate with a notification
    display notification "Voice command system active" with title "Abracadabra Protocol" subtitle "Listening for commands..."
    
    -- Register our commands with the system
    tell application "System Events"
        -- These would be registered with the actual speech recognition system
        -- "abracadabra" - Activate the protocol
        -- "abracadabra capture" - Capture screen content
        -- "abracadabra save" - Save captured content
        -- "abracadabra read" - Read screen content
    end tell
end startListening

-- Handle the "abracadabra" command
on handleAbracadabra()
    display notification "Protocol activated" with title "Abracadabra"
    say "Abracadabra protocol activated. Reading screen content."
    
    -- Read the current screen content
    readScreenContent()
end handleAbracadabra

-- Handle the "abracadabra capture" command
on handleCapture()
    display notification "Capturing screen content" with title "Abracadabra Capture"
    say "Capturing screen content."
    
    -- Capture the current screen content
    captureScreenContent()
end handleCapture

-- Handle the "abracadabra save" command
on handleSave()
    display notification "Saving captured content" with title "Abracadabra Save"
    say "Saving captured content."
    
    -- Save the last captured content
    saveContent()
end handleSave

-- Handle the "abracadabra read" command
on handleRead()
    display notification "Reading screen content" with title "Abracadabra Read"
    say "Reading screen content."
    
    -- Read the current screen content
    readScreenContent()
end handleRead

-- Read the current screen content
on readScreenContent()
    tell application "System Events"
        set frontApp to name of first process whose frontmost is true
        set frontWindow to ""
        try
            set frontWindow to name of first window of process frontApp
        end try
        
        -- Get the focused UI element (this is a simplified approach)
        set focusedElement to ""
        try
            set focusedElement to value of attribute "AXFocusedUIElement" of process frontApp
        end try
        
        -- Compose the content to read
        set contentToRead to "Current application: " & frontApp
        if frontWindow is not "" then
            set contentToRead to contentToRead & ", Window: " & frontWindow
        end if
        if focusedElement is not "" then
            set contentToRead to contentToRead & ", Content: " & focusedElement
        end if
        
        -- Speak the content
        say contentToRead
        
        -- Store the content for potential saving
        set lastCapturedContent to contentToRead
    end tell
end readScreenContent

-- Capture the current screen content
on captureScreenContent()
    tell application "System Events"
        set frontApp to name of first process whose frontmost is true
        
        -- Take a screenshot of the current window
        set timestamp to do shell script "date +%Y%m%d_%H%M%S"
        set screenshotPath to capturesFolder & "screenshot_" & timestamp & ".png"
        
        -- Use screencapture command to capture the current window
        do shell script "screencapture -l$(osascript -e 'tell app \"" & frontApp & "\" to id of window 1') " & quoted form of screenshotPath
        
        -- Store text description
        set lastCapturedContent to "Screenshot of " & frontApp & " taken at " & timestamp
        
        -- Confirm capture
        say "Screen content captured."
        display notification "Screenshot saved to captures folder" with title "Content Captured"
    end tell
end captureScreenContent

-- Save the captured content
on saveContent()
    if lastCapturedContent is "" then
        say "No content has been captured yet."
        return
    end if
    
    -- Generate a filename with timestamp
    set timestamp to do shell script "date +%Y%m%d_%H%M%S"
    set filePath to capturesFolder & "capture_" & timestamp & ".txt"
    
    -- Save the content to a file
    try
        set fileRef to open for access file filePath with write permission
        write lastCapturedContent to fileRef
        close access fileRef
        
        say "Content saved successfully."
        display notification "Content saved to: " & filePath with title "Content Saved"
    on error errMsg
        say "Error saving content: " & errMsg
        display notification "Error: " & errMsg with title "Save Failed"
    end try
end saveContent

-- Process incoming voice commands
on processCommand(commandText)
    if commandText is "abracadabra" then
        handleAbracadabra()
    else if commandText is "abracadabra capture" then
        handleCapture()
    else if commandText is "abracadabra save" then
        handleSave()
    else if commandText is "abracadabra read" then
        handleRead()
    end if
end processCommand

-- Main execution
on run
    initialize()
    
    -- For testing purposes, simulate the commands
    -- In a real implementation, these would be triggered by voice recognition
    processCommand("abracadabra")
    delay 2
    processCommand("abracadabra capture")
    delay 2
    processCommand("abracadabra save")
end run

-- Handle speech recognition events (would be implemented with actual speech recognition API)
on speakRecognized(thePhrase)
    processCommand(thePhrase)
end speakRecognized

-- To make this script run automatically:
-- 1. Save it as an application
-- 2. Add it to Login Items in System Preferences > Users & Groups
-- 3. Grant necessary permissions in System Preferences > Security & Privacy > Privacy
--    - Accessibility
--    - Speech Recognition
--    - Automation
--    - Files and Folders
