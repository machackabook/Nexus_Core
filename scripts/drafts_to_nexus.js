// NEXUS Drafts Integration Script
// This script formats Drafts content and saves it to NEXUS_CORE repository

// Get the current draft content
let content = draft.content;
let title = draft.title || "Untitled";

// Generate timestamp for filename
let now = new Date();
let timestamp = now.toISOString().slice(0, 19).replace(/:/g, '-');
let filename = `${timestamp}_${title.replace(/[^a-zA-Z0-9]/g, '_')}.md`;

// Format as Markdown with NEXUS metadata
let markdownContent = `---
title: "${title}"
created: ${now.toISOString()}
tags: [nexus, mobile-capture, draft]
source: drafts-app
status: new
---

# ${title}

${content}

---
*Captured via Drafts App - The Conduit*
*Timestamp: ${now.toLocaleString()}*
`;

// Create file manager instance
let fm = FileManager.createCloud();

// Define path to NEXUS_CORE Chronicles directory
let nexusPath = "/NEXUS_CORE/Chronicles/";
let fullPath = nexusPath + filename;

// Write the file
if (fm.writeString(fullPath, markdownContent)) {
    app.displaySuccessMessage("Intelligence captured and staged for NEXUS assimilation");
    
    // Optional: Add to git staging (if Working Copy is available)
    let workingCopyURL = `working-copy://x-callback-url/write/?key=nexus-core&path=Chronicles/${filename}&text=${encodeURIComponent(markdownContent)}&message=Mobile intelligence capture: ${title}`;
    
    // Open Working Copy to stage the file
    app.openURL(workingCopyURL);
} else {
    app.displayErrorMessage("Failed to capture intelligence - check NEXUS_CORE access");
}

// Mark draft as processed
draft.addTag("nexus-processed");
draft.update();
