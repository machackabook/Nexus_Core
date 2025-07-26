# Nexus Integrated Resources

This project integrates the following components into a unified development environment:

1. **Amazon Q Developer CLI** - AWS AI assistant for developers
2. **IBM HyperProtect SDK** - Security-focused SDK for protected environments
3. **Gemini Nexus Environment** - Google Gemini AI integration environment
4. **Vercel Deployment Environment** - Deployment platform for web applications

## Directory Structure

```
integrated_resources/
├── api/                  # API endpoints for Vercel deployment
│   └── index.py          # Main API file
├── bin/                  # Symbolic links to binaries
│   └── qchat             # Link to Amazon Q CLI
├── config/               # Configuration files
│   ├── config.json       # Main configuration
│   └── ibm_sdk_config.json # IBM SDK configuration
├── scripts/              # Utility scripts
│   └── activate_gemini.sh # Script to activate Gemini environment
├── gemini_requirements.txt # Requirements file for Gemini
├── requirements.txt      # Requirements for Vercel deployment
├── run.py               # Main script to run the integrated environment
├── setup.py             # Setup script
└── vercel.json          # Vercel configuration
```

## Prerequisites

- Python 3.8+
- Cargo (Rust build tool)
- Swift compiler
- npm (Node.js package manager)

## Setup

Run the setup script to configure the integrated environment:

```bash
cd /Users/nexus/nexus-bridge/Nexus_Core/AIEnvironment/integrated_resources
python setup.py
```

The setup script will:
1. Check for required prerequisites
2. Create configuration files
3. Set up symbolic links to binaries
4. Configure the Gemini virtual environment
5. Set up the Vercel deployment environment

## Usage

After setup, you can run the integrated environment using:

```bash
python run.py all
```

Or run individual components:

```bash
python run.py amazon-q  # Run Amazon Q Developer CLI
python run.py gemini    # Activate Gemini environment
python run.py vercel    # Start Vercel development server
```

## Component Integration

### Amazon Q Developer CLI

The Amazon Q Developer CLI is integrated as a binary that can be invoked from the integrated environment. It provides AI-assisted development capabilities.

### IBM HyperProtect SDK

The IBM HyperProtect SDK is integrated as a library that can be used for secure data handling and protected environments.

### Gemini Nexus Environment

The Gemini environment is integrated as a Python virtual environment that can be activated to use Google's Gemini AI capabilities.

### Vercel Deployment Environment

The Vercel environment is set up for deploying web applications with API endpoints that can interact with the other integrated components.

## API Endpoints

The integrated API provides the following endpoints:

- `GET /` - Home endpoint that returns the status of the API
- `POST /api/gemini` - Endpoint for interacting with Gemini AI
- `POST /api/hyperprotect` - Endpoint for using IBM HyperProtect SDK

## Security Considerations

- API keys and sensitive credentials should be stored securely
- Use environment variables for sensitive information
- Follow the principle of least privilege when configuring permissions

## Troubleshooting

If you encounter issues during setup or usage:

1. Check that all prerequisites are installed
2. Verify that paths in the configuration files are correct
3. Check the logs for error messages
4. Ensure that all components are properly built and configured

## License

This integration is provided for internal use only.

## Contact

For questions or support, contact the Nexus team.
