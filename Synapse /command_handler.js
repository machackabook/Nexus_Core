// Command Handler for Synapse System
import { sessionManager } from './session_manager.js';
import { trustHandler } from './tool_trust_handler.js';
import { mcpController } from './mcp_integration_controller.js';

class CommandHandler {
    constructor() {
        this.commands = new Map();
        this.initializeCommands();
    }

    initializeCommands() {
        this.commands.set('/tools', this.handleToolsCommand.bind(this));
    }

    async handleToolsCommand(args) {
        if (args[0] === 'trust-all') {
            const session = await sessionManager.initializeSession();
            const trustResult = await trustHandler.trustAll(session.sessionId);
            
            console.log(`Session UUID: ${session.uuid}`);
            console.log(`2FA Code: ${session.verificationCode}`);
            console.log('Trust status:', trustResult);
            
            return {
                status: 'success',
                message: 'Full system access granted',
                session: session,
                trust: trustResult
            };
        }
        throw new Error('Unknown tools command');
    }

    async processCommand(commandStr) {
        const [cmd, ...args] = commandStr.split(' ');
        const handler = this.commands.get(cmd);
        
        if (!handler) {
            throw new Error(`Unknown command: ${cmd}`);
        }
        
        return await handler(args);
    }
}

export const commandHandler = new CommandHandler();

// Initialize if running directly
if (import.meta.url === new URL(import.meta.url).href) {
    async function testCommand() {
        try {
            const result = await commandHandler.processCommand('/tools trust-all');
            console.log('Command result:', result);
        } catch (error) {
            console.error('Command failed:', error);
        }
    }
    testCommand();
}
