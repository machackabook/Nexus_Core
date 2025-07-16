on adding folder items to this_folder after receiving added_items
    tell application "System Events"
        display notification "New item added to NEXUS_AUTOMATOR" with title "NEXUS System"
    end tell
    do shell script "say 'New automation script detected'"
end adding folder items
