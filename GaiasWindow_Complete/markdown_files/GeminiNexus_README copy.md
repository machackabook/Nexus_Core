# GeminiNexus Protocol Implementation

This repository contains the implementation of the GeminiNexus Protocol, which enhances Gemini's CLI capabilities and integrates it with Amazon Q and other LLMs.

## Setup Instructions

1. **Set up the Gemini environment**:
   ```bash
   /Users/cryptichelps/setup_gemini_environment.sh
   ```
   This will create a Python virtual environment and install the required packages.

2. **Configure your Gemini API Key**:
   ```bash
   /Users/cryptichelps/setup_gemini_api_key.sh
   ```
   You'll need to obtain a Gemini API Key from Google AI Studio first.

3. **Set up the three-profile window configuration**:
   ```bash
   /Users/cryptichelps/setup_three_profile_windows.sh
   ```
   This will create and open three terminal windows for different profiles:
   - User profile - For regular user interaction
   - Agent profile - For agent operations
   - System profile - For system monitoring and maintenance

4. **Schedule automatic backups**:
   ```bash
   /Users/cryptichelps/schedule_backups.sh
   ```
   This will set up scheduled backups at 5, 10, or 15 minute intervals.

## Running GeminiNexus CLI

To run the GeminiNexus CLI:
```bash
/Users/cryptichelps/run_gemini.sh
```

## Available Commands in GeminiNexus CLI

- `EXEC:` - Execute shell commands directly (use with caution)
- `AQ:` - Prompt Amazon Q
- `GROK:` - Prompt Grok (simulated)
- `WATSON:` - Send text to Watson NLU (simulated)

## Files and Directories

- `/Users/cryptichelps/gemgem_cli.py` - The core GeminiNexus CLI script
- `/Users/cryptichelps/backup_qchat_logs.sh` - Script for backing up chat logs
- `/Users/cryptichelps/setup_three_profile_windows.sh` - Script for setting up the three-profile window configuration
- `/Users/cryptichelps/setup_gemini_api_key.sh` - Script for setting up the Gemini API Key
- `/Users/cryptichelps/schedule_backups.sh` - Script for scheduling automatic backups
- `/Users/cryptichelps/setup_gemini_environment.sh` - Script for setting up the Gemini environment
- `/Users/cryptichelps/GeminiNexus_TaskList.md` - Task list for implementing the GeminiNexus Protocol
- `/Users/cryptichelps/gemini_venv/` - Python virtual environment for GeminiNexus

## Log Directories

- `/Users/cryptichelps/Desktop/Documents/AmazonQChatLog/` - User log directory
- `/Users/cryptichelps/Desktop/Documents/AmazonQChatLogAgent/` - Agent log directory
- `/Users/cryptichelps/Desktop/Documents/AIEnvironment/` - System log directory
