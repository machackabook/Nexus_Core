#!/usr/bin/env python3
"""
Nexus Integration Script

This script integrates the following resources:
1. Amazon Q Developer CLI
2. IBM HyperProtect SDK
3. Gemini Nexus Environment
4. Vercel Deployment Environment

Author: Nexus System
Date: 2025-07-17
"""

import os
import sys
import subprocess
import json
import shutil
from pathlib import Path

# Define base paths
BASE_DIR = Path(os.path.dirname(os.path.abspath(__file__)))
AMAZON_Q_PATH = Path("/Users/nexus/amazon-q-developer-cli")
IBM_SDK_PATH = Path("/Users/nexus/IBM-HyperProtectSDK")
GEMINI_VENV_PATH = Path("/Users/nexus/nexus-bridge/Nexus_Core/AIEnvironment/GeminiNexus/gemini_venv")
VERCEL_PATH = Path("/Users/nexus/nexus-bridge/Nexus_Core/AIEnvironment/vercel")

# Configuration
CONFIG = {
    "project_name": "NexusIntegrated",
    "environment": "development",
    "components": {
        "amazon_q": {
            "enabled": True,
            "path": str(AMAZON_Q_PATH),
            "build_command": "cargo build --release",
            "binary_path": "target/release/qchat"
        },
        "ibm_sdk": {
            "enabled": True,
            "path": str(IBM_SDK_PATH),
            "build_command": "swift build",
            "library_path": ".build/debug"
        },
        "gemini": {
            "enabled": True,
            "path": str(GEMINI_VENV_PATH),
            "activate_script": "bin/activate" if os.name != "nt" else "Scripts/activate"
        },
        "vercel": {
            "enabled": True,
            "path": str(VERCEL_PATH),
            "deploy_command": "npm run deploy"
        }
    }
}

def check_prerequisites():
    """Check if all required tools are installed"""
    prerequisites = {
        "python": "python --version",
        "cargo": "cargo --version",
        "swift": "swift --version",
        "npm": "npm --version"
    }
    
    missing = []
    for tool, command in prerequisites.items():
        try:
            subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            print(f"✅ {tool} is installed")
        except subprocess.CalledProcessError:
            print(f"❌ {tool} is not installed")
            missing.append(tool)
    
    if missing:
        print(f"\nMissing prerequisites: {', '.join(missing)}")
        print("Please install the missing prerequisites and try again.")
        return False
    return True

def setup_amazon_q():
    """Set up Amazon Q Developer CLI"""
    if not CONFIG["components"]["amazon_q"]["enabled"]:
        print("Amazon Q setup is disabled in config")
        return True
    
    print("\n--- Setting up Amazon Q Developer CLI ---")
    try:
        # Create symbolic link to Amazon Q binary
        amazon_q_bin = AMAZON_Q_PATH / CONFIG["components"]["amazon_q"]["binary_path"]
        target_bin = BASE_DIR / "bin" / "qchat"
        
        if not os.path.exists(BASE_DIR / "bin"):
            os.makedirs(BASE_DIR / "bin")
        
        if os.path.exists(amazon_q_bin):
            if os.path.exists(target_bin):
                os.remove(target_bin)
            os.symlink(amazon_q_bin, target_bin)
            print(f"Created symbolic link to Amazon Q binary at {target_bin}")
        else:
            print(f"Amazon Q binary not found at {amazon_q_bin}")
            print("You may need to build it first using: cd {AMAZON_Q_PATH} && {CONFIG['components']['amazon_q']['build_command']}")
        
        return True
    except Exception as e:
        print(f"Error setting up Amazon Q: {e}")
        return False

def setup_ibm_sdk():
    """Set up IBM HyperProtect SDK"""
    if not CONFIG["components"]["ibm_sdk"]["enabled"]:
        print("IBM SDK setup is disabled in config")
        return True
    
    print("\n--- Setting up IBM HyperProtect SDK ---")
    try:
        # Create configuration for IBM SDK
        ibm_config = {
            "sdk_path": str(IBM_SDK_PATH),
            "library_path": str(IBM_SDK_PATH / CONFIG["components"]["ibm_sdk"]["library_path"]),
            "version": "1.0.0"
        }
        
        config_dir = BASE_DIR / "config"
        if not os.path.exists(config_dir):
            os.makedirs(config_dir)
        
        with open(config_dir / "ibm_sdk_config.json", "w") as f:
            json.dump(ibm_config, f, indent=2)
        
        print(f"Created IBM SDK configuration at {config_dir / 'ibm_sdk_config.json'}")
        return True
    except Exception as e:
        print(f"Error setting up IBM SDK: {e}")
        return False

def setup_gemini_venv():
    """Set up Gemini virtual environment"""
    if not CONFIG["components"]["gemini"]["enabled"]:
        print("Gemini setup is disabled in config")
        return True
    
    print("\n--- Setting up Gemini Environment ---")
    try:
        # Create activation script
        activate_script = "#!/bin/bash\n\n"
        activate_script += f"source {GEMINI_VENV_PATH / CONFIG['components']['gemini']['activate_script']}\n"
        activate_script += "echo 'Gemini virtual environment activated'\n"
        
        script_dir = BASE_DIR / "scripts"
        if not os.path.exists(script_dir):
            os.makedirs(script_dir)
        
        with open(script_dir / "activate_gemini.sh", "w") as f:
            f.write(activate_script)
        
        os.chmod(script_dir / "activate_gemini.sh", 0o755)
        print(f"Created Gemini activation script at {script_dir / 'activate_gemini.sh'}")
        
        # Create requirements file that points to the Gemini venv site-packages
        requirements_file = "# Gemini Environment Requirements\n"
        requirements_file += f"# This file points to packages in the Gemini virtual environment\n"
        requirements_file += f"--find-links={GEMINI_VENV_PATH}/lib/python3.*/site-packages\n"
        
        with open(BASE_DIR / "gemini_requirements.txt", "w") as f:
            f.write(requirements_file)
        
        print(f"Created Gemini requirements file at {BASE_DIR / 'gemini_requirements.txt'}")
        return True
    except Exception as e:
        print(f"Error setting up Gemini environment: {e}")
        return False

def setup_vercel():
    """Set up Vercel deployment environment"""
    if not CONFIG["components"]["vercel"]["enabled"]:
        print("Vercel setup is disabled in config")
        return True
    
    print("\n--- Setting up Vercel Environment ---")
    try:
        # Create vercel configuration
        vercel_config = {
            "version": 2,
            "builds": [
                {
                    "src": "api/*.py",
                    "use": "@vercel/python"
                }
            ],
            "routes": [
                {
                    "src": "/(.*)",
                    "dest": "api/index.py"
                }
            ],
            "env": {
                "NEXUS_ENVIRONMENT": CONFIG["environment"]
            }
        }
        
        with open(BASE_DIR / "vercel.json", "w") as f:
            json.dump(vercel_config, f, indent=2)
        
        print(f"Created Vercel configuration at {BASE_DIR / 'vercel.json'}")
        
        # Create API directory and sample file
        api_dir = BASE_DIR / "api"
        if not os.path.exists(api_dir):
            os.makedirs(api_dir)
        
        sample_api = """from flask import Flask, request, jsonify
import os

app = Flask(__name__)

@app.route('/', methods=['GET'])
def home():
    return jsonify({
        "status": "success",
        "message": "Nexus Integrated API is running",
        "environment": os.environ.get("NEXUS_ENVIRONMENT", "development")
    })

@app.route('/api/gemini', methods=['POST'])
def gemini_api():
    # This would integrate with the Gemini environment
    return jsonify({
        "status": "success",
        "message": "Gemini API endpoint"
    })

@app.route('/api/hyperprotect', methods=['POST'])
def hyperprotect_api():
    # This would integrate with the IBM HyperProtect SDK
    return jsonify({
        "status": "success",
        "message": "IBM HyperProtect API endpoint"
    })

if __name__ == '__main__':
    app.run(debug=True)
"""
        
        with open(api_dir / "index.py", "w") as f:
            f.write(sample_api)
        
        print(f"Created sample API file at {api_dir / 'index.py'}")
        
        # Create requirements.txt for Vercel
        requirements = """flask==2.0.1
requests==2.26.0
"""
        
        with open(BASE_DIR / "requirements.txt", "w") as f:
            f.write(requirements)
        
        print(f"Created requirements.txt at {BASE_DIR / 'requirements.txt'}")
        return True
    except Exception as e:
        print(f"Error setting up Vercel environment: {e}")
        return False

def create_main_script():
    """Create the main script to run the integrated environment"""
    try:
        main_script = """#!/usr/bin/env python3
import os
import sys
import subprocess
import json
from pathlib import Path

BASE_DIR = Path(os.path.dirname(os.path.abspath(__file__)))

def load_config():
    with open(BASE_DIR / "config" / "config.json", "r") as f:
        return json.load(f)

def run_amazon_q():
    print("Starting Amazon Q Developer CLI...")
    q_path = BASE_DIR / "bin" / "qchat"
    if os.path.exists(q_path):
        subprocess.run([q_path], check=True)
    else:
        print("Amazon Q binary not found")

def run_gemini():
    print("Starting Gemini environment...")
    activate_script = BASE_DIR / "scripts" / "activate_gemini.sh"
    if os.path.exists(activate_script):
        subprocess.run(f"source {activate_script} && python -c 'print(\"Gemini environment is ready\")'", 
                      shell=True, check=True)
    else:
        print("Gemini activation script not found")

def run_vercel_dev():
    print("Starting Vercel development server...")
    subprocess.run(["npm", "run", "dev"], cwd=BASE_DIR, check=True)

def main():
    if len(sys.argv) < 2:
        print("Usage: python run.py [amazon-q|gemini|vercel|all]")
        return
    
    command = sys.argv[1].lower()
    
    if command == "amazon-q":
        run_amazon_q()
    elif command == "gemini":
        run_gemini()
    elif command == "vercel":
        run_vercel_dev()
    elif command == "all":
        # Run all components
        run_gemini()
        run_vercel_dev()
        run_amazon_q()
    else:
        print(f"Unknown command: {command}")
        print("Available commands: amazon-q, gemini, vercel, all")

if __name__ == "__main__":
    main()
"""
        
        with open(BASE_DIR / "run.py", "w") as f:
            f.write(main_script)
        
        os.chmod(BASE_DIR / "run.py", 0o755)
        print(f"Created main script at {BASE_DIR / 'run.py'}")
        return True
    except Exception as e:
        print(f"Error creating main script: {e}")
        return False

def create_config_file():
    """Create the main configuration file"""
    try:
        config_dir = BASE_DIR / "config"
        if not os.path.exists(config_dir):
            os.makedirs(config_dir)
        
        with open(config_dir / "config.json", "w") as f:
            json.dump(CONFIG, f, indent=2)
        
        print(f"Created configuration file at {config_dir / 'config.json'}")
        return True
    except Exception as e:
        print(f"Error creating configuration file: {e}")
        return False

def main():
    print("=== Nexus Integration Setup ===")
    
    if not check_prerequisites():
        return
    
    # Create configuration
    if not create_config_file():
        return
    
    # Set up components
    setup_amazon_q()
    setup_ibm_sdk()
    setup_gemini_venv()
    setup_vercel()
    
    # Create main script
    create_main_script()
    
    print("\n=== Setup Complete ===")
    print(f"Integration directory: {BASE_DIR}")
    print("\nTo run the integrated environment:")
    print(f"  python {BASE_DIR / 'run.py'} all")
    print("\nOr run individual components:")
    print(f"  python {BASE_DIR / 'run.py'} amazon-q")
    print(f"  python {BASE_DIR / 'run.py'} gemini")
    print(f"  python {BASE_DIR / 'run.py'} vercel")

if __name__ == "__main__":
    main()
