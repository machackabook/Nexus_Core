#!/usr/bin/env python3
"""
NEXUS Google Colab Integration - The Crucible
Exports Python scripts and Jupyter notebooks to Google Drive for Colab execution
"""

import os
import json
import shutil
from datetime import datetime
import subprocess

class ColabExporter:
    def __init__(self):
        self.nexus_home = os.path.expanduser("~/NEXUS_CORE")
        self.colab_staging = "/tmp/nexus_colab_staging"
        self.gdrive_path = "gdrive:NEXUS_COLAB"
        
    def create_notebook_from_script(self, script_path, output_path):
        """Convert Python script to Jupyter notebook format"""
        with open(script_path, 'r') as f:
            script_content = f.read()
        
        # Create notebook structure
        notebook = {
            "cells": [
                {
                    "cell_type": "markdown",
                    "metadata": {},
                    "source": [
                        f"# NEXUS Colab Execution\n",
                        f"**Script**: {os.path.basename(script_path)}\n",
                        f"**Exported**: {datetime.now().isoformat()}\n",
                        f"**Source**: NEXUS_CORE Repository\n\n",
                        "---\n"
                    ]
                },
                {
                    "cell_type": "code",
                    "execution_count": None,
                    "metadata": {},
                    "outputs": [],
                    "source": script_content.split('\n')
                }
            ],
            "metadata": {
                "kernelspec": {
                    "display_name": "Python 3",
                    "language": "python",
                    "name": "python3"
                },
                "language_info": {
                    "name": "python",
                    "version": "3.8.0"
                }
            },
            "nbformat": 4,
            "nbformat_minor": 4
        }
        
        with open(output_path, 'w') as f:
            json.dump(notebook, f, indent=2)
    
    def export_to_colab(self, file_path):
        """Export file to Google Colab via Google Drive"""
        print(f"🚀 Exporting {file_path} to The Crucible (Google Colab)")
        
        # Create staging directory
        os.makedirs(self.colab_staging, exist_ok=True)
        
        filename = os.path.basename(file_path)
        base_name = os.path.splitext(filename)[0]
        
        if file_path.endswith('.py'):
            # Convert Python script to notebook
            notebook_path = os.path.join(self.colab_staging, f"{base_name}.ipynb")
            self.create_notebook_from_script(file_path, notebook_path)
            upload_file = notebook_path
        elif file_path.endswith('.ipynb'):
            # Copy notebook directly
            upload_file = os.path.join(self.colab_staging, filename)
            shutil.copy2(file_path, upload_file)
        else:
            print(f"❌ Unsupported file type: {filename}")
            return False
        
        # Upload to Google Drive using rclone
        try:
            cmd = f"rclone copy '{upload_file}' {self.gdrive_path}/ --progress"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            
            if result.returncode == 0:
                print(f"✅ Successfully exported to Google Drive")
                
                # Generate Colab URL
                colab_filename = os.path.basename(upload_file)
                colab_url = f"https://colab.research.google.com/drive/{colab_filename}"
                print(f"🔗 Colab URL: {colab_url}")
                
                # Clean up staging
                os.remove(upload_file)
                return True
            else:
                print(f"❌ Upload failed: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ Export error: {e}")
            return False
    
    def batch_export(self, directory):
        """Export all Python files and notebooks from a directory"""
        exported_count = 0
        
        for root, dirs, files in os.walk(directory):
            for file in files:
                if file.endswith(('.py', '.ipynb')):
                    file_path = os.path.join(root, file)
                    if self.export_to_colab(file_path):
                        exported_count += 1
        
        print(f"🎯 Exported {exported_count} files to The Crucible")

def main():
    """Main execution function"""
    import sys
    
    exporter = ColabExporter()
    
    if len(sys.argv) < 2:
        print("Usage: python3 export_to_colab.py <file_or_directory>")
        print("Example: python3 export_to_colab.py ~/NEXUS_CORE/scripts/")
        return
    
    target = sys.argv[1]
    
    if os.path.isfile(target):
        exporter.export_to_colab(target)
    elif os.path.isdir(target):
        exporter.batch_export(target)
    else:
        print(f"❌ Target not found: {target}")

if __name__ == "__main__":
    main()
