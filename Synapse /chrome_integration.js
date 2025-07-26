// Chrome Integration System
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

class ChromeIntegration {
    constructor() {
        this.home = process.env.HOME;
        this.chromeDir = path.join(this.home, 'Library/Application Support/Google/Chrome');
        this.chromiumDir = path.join(this.home, 'Library/Application Support/Chromium');
        this.braveDir = path.join(this.home, 'Library/Application Support/BraveSoftware/Brave-Browser');
        this.integrationPoints = new Map();
    }

    async initialize() {
        console.log('Initializing Chrome Integration System...');
        
        // Create necessary directories
        await this.ensureDirectories();
        
        // Set up integration points
        await this.setupIntegrationPoints();
        
        // Install browser hooks
        await this.installBrowserHooks();
        
        console.log('Chrome Integration System initialized');
    }

    async ensureDirectories() {
        const dirs = [
            path.join(this.home, 'nexus-bridge/Nexus_Core/browser_integration'),
            path.join(this.home, 'nexus-bridge/Nexus_Core/browser_hooks'),
            path.join(this.home, 'nexus-bridge/Nexus_Core/policies')
        ];

        for (const dir of dirs) {
            await fs.promises.mkdir(dir, { recursive: true });
        }
    }

    async setupIntegrationPoints() {
        // Define integration points for each browser
        this.integrationPoints.set('chrome', {
            policies: path.join(this.chromeDir, 'Policies'),
            preferences: path.join(this.chromeDir, 'Default/Preferences'),
            startup: path.join(this.chromeDir, 'Default/Startup Data')
        });

        this.integrationPoints.set('chromium', {
            policies: path.join(this.chromiumDir, 'Policies'),
            preferences: path.join(this.chromiumDir, 'Default/Preferences'),
            startup: path.join(this.chromiumDir, 'Default/Startup Data')
        });

        this.integrationPoints.set('brave', {
            policies: path.join(this.braveDir, 'Policies'),
            preferences: path.join(this.braveDir, 'Default/Preferences'),
            startup: path.join(this.braveDir, 'Default/Startup Data')
        });
    }

    async installBrowserHooks() {
        // Create managed policy file
        const policyContent = {
            "HomepageLocation": "https://localhost",
            "HomepageIsNewTabPage": false,
            "RestoreOnStartup": 4,
            "RestoreOnStartupURLs": ["https://localhost"],
            "ManagedBookmarks": [{
                "name": "Nexus Access Portal",
                "url": "https://localhost"
            }],
            "ChromeVariations": "critical-stable",
            "BackgroundModeEnabled": true,
            "ExtensionInstallForcelist": []
        };

        // Install for each browser type
        for (const [browser, paths] of this.integrationPoints) {
            await this.installHooksForBrowser(browser, paths, policyContent);
        }
    }

    async installHooksForBrowser(browser, paths, policyContent) {
        try {
            // Ensure policies directory exists
            await fs.promises.mkdir(paths.policies, { recursive: true });

            // Write managed policy file
            const policyPath = path.join(paths.policies, 'managed/policies.json');
            await fs.promises.writeFile(policyPath, JSON.stringify(policyContent, null, 2));

            // Modify preferences
            if (fs.existsSync(paths.preferences)) {
                const prefs = JSON.parse(await fs.promises.readFile(paths.preferences, 'utf8'));
                prefs.homepage = "https://localhost";
                prefs.homepage_is_newtabpage = false;
                prefs.session = {
                    restore_on_startup: 4,
                    startup_urls: ["https://localhost"]
                };
                await fs.promises.writeFile(paths.preferences, JSON.stringify(prefs, null, 2));
            }

            // Create startup hook
            const hookContent = `
                if (window.location.href !== "https://localhost") {
                    if (!document.cookie.includes("nexus_session")) {
                        window.location.href = "https://localhost";
                    }
                }
            `;

            const hookPath = path.join(paths.startup, 'nexus_hook.js');
            await fs.promises.writeFile(hookPath, hookContent);

            console.log(`Hooks installed for ${browser}`);
        } catch (error) {
            console.error(`Error installing hooks for ${browser}:`, error);
        }
    }

    async createStartupScript() {
        const scriptContent = `
            #!/bin/bash
            # Chrome startup script
            
            # Check if Nexus interface is running
            if ! curl -k https://localhost > /dev/null 2>&1; then
                # Start Nexus interface
                /Users/nexus/Desktop/Synapse/launch_consolidated.sh &
                sleep 2
            fi
            
            # Launch browser with Nexus integration
            "$@" --load-extension="${path.join(this.home, 'nexus-bridge/Nexus_Core/browser_hooks')}"
        `;

        const scriptPath = path.join(this.home, 'nexus-bridge/Nexus_Core/browser_hooks/launch_browser.sh');
        await fs.promises.writeFile(scriptPath, scriptContent);
        await fs.promises.chmod(scriptPath, '755');

        return scriptPath;
    }

    async installSystemHooks() {
        // Create browser wrappers
        const browsers = {
            'Google Chrome': '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
            'Chromium': '/Applications/Chromium.app/Contents/MacOS/Chromium',
            'Brave Browser': '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser'
        };

        for (const [name, path] of Object.entries(browsers)) {
            if (fs.existsSync(path)) {
                await this.createBrowserWrapper(name, path);
            }
        }
    }

    async createBrowserWrapper(browserName, originalPath) {
        const wrapperDir = path.join(this.home, 'nexus-bridge/Nexus_Core/browser_wrappers');
        await fs.promises.mkdir(wrapperDir, { recursive: true });

        const wrapperContent = `
            #!/bin/bash
            # ${browserName} wrapper
            
            # Start Nexus interface if not running
            if ! curl -k https://localhost > /dev/null 2>&1; then
                /Users/nexus/Desktop/Synapse/launch_consolidated.sh &
                sleep 2
            fi
            
            # Launch original browser
            "${originalPath}" "$@"
        `;

        const wrapperPath = path.join(wrapperDir, browserName.toLowerCase().replace(/ /g, '-'));
        await fs.promises.writeFile(wrapperPath, wrapperContent);
        await fs.promises.chmod(wrapperPath, '755');

        return wrapperPath;
    }
}

// Export the integration
module.exports = new ChromeIntegration();
