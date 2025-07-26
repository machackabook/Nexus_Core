// Tool Trust Handler for Synapse System
import fs from 'fs';
import path from 'path';
import { sessionManager } from './session_manager.js';
import { mcpController } from './mcp_integration_controller.js';

class ToolTrustHandler {
    constructor() {
        this.trustPath = path.join(process.env.HOME, 'Synapse', 'trust');
        this.trustedSessions = new Set();
    }

    async initialize() {
        await fs.promises.mkdir(this.trustPath, { recursive: true });
        return this;
    }

    async trustAll(sessionId) {
        const session = await sessionManager.getSessionInfo();
        if (session.sessionId !== sessionId) {
            throw new Error('Session verification failed');
        }

        // Enable full trust for the session
        this.trustedSessions.add(sessionId);
        await sessionManager.trustSession();

        // Store trust configuration
        const trustConfig = {
            sessionId: sessionId,
            uuid: session.uuid,
            timestamp: new Date().toISOString(),
            access_level: 'full',
            verification_code: session.verificationCode
        };

        await fs.promises.writeFile(
            path.join(this.trustPath, `${sessionId}_trust.json`),
            JSON.stringify(trustConfig, null, 2)
        );

        // Initialize MCP with full access
        await mcpController.initialize();

        return {
            status: 'trusted',
            session: trustConfig,
            mcp_status: 'initialized'
        };
    }

    isTrusted(sessionId) {
        return this.trustedSessions.has(sessionId);
    }

    async verify2FA(sessionId, code) {
        return await sessionManager.verify2FA(code);
    }
}

export const trustHandler = new ToolTrustHandler();

// Initialize if running directly
if (import.meta.url === new URL(import.meta.url).href) {
    async function initTrustHandler() {
        const handler = await trustHandler.initialize();
        console.log('Trust handler initialized');
    }
    initTrustHandler();
}
