# Gemini Plugin for Nexus Core

This plugin integrates Google's Gemini 2.5 Pro model with the Nexus Core CLI.

## Installation

1. Make sure the plugin is in the correct directory:
   ```
   /Users/nexus/nexus-bridge/Nexus_Core/plugins/gemini/
   ```

2. Run the setup command:
   ```
   nexus gemini setup
   ```

3. Get a Google API key from [Google AI Studio](https://ai.google.dev/)

4. Set your API key:
   ```
   export GEMINI_API_KEY="your-api-key-here"
   ```

## Usage

### Start an interactive chat
```
nexus gemini chat
```

### Ask a single question
```
nexus gemini ask "What is the capital of France?"
```

### Ask a creative question (higher temperature)
```
nexus gemini creative "Write a short story about a robot learning to paint"
```

### Save conversation history
```
nexus gemini save conversation.json
```

### Load conversation history
```
nexus gemini load conversation.json
```

## Troubleshooting

If you encounter any issues, make sure:
1. The Gemini CLI is properly installed
2. Your API key is set correctly
3. You have an active internet connection

## License

MIT
