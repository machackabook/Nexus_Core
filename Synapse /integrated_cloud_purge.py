#!/usr/bin/env python3
import os
import sys
import json
import shutil
import subprocess
import datetime
import asyncio
import websockets
import requests
from urllib.parse import urlparse, parse_qs
from pathlib import Path

class IntegratedCloudPurge:
    def __init__(self):
        self.home_dir = os.path.expanduser("~")
        self.nexus_core = os.path.join(self.home_dir, "NEXUS_CORE")
        self.staging_path = "/Volumes/Transfer/NEXUS_STAGING"
        self.jupyter_token = None
        self.jupyter_port = 8888
        self.connections = set()
        self.special_char_connections = {}
        
        # Initialize logging
        self.log_file = os.path.join(
            self.nexus_core,
            "logs",
            f"cloud_purge_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
        )

    async def initialize(self):
        """Initialize the integrated cloud purge system"""
        print("Initializing Integrated Cloud Purge System...")
        
        # Create necessary directories
        os.makedirs(self.staging_path, exist_ok=True)
        os.makedirs(os.path.dirname(self.log_file), exist_ok=True)
        
        # Start Jupyter server if not running
        await self.ensure_jupyter_server()
        
        # Start WebSocket server for special character monitoring
        await self.start_websocket_server()
        
        self.log_message("System initialized successfully")

    async def ensure_jupyter_server(self):
        """Ensure Jupyter server is running and get token"""
        try:
            # Check if Jupyter is running
            response = requests.get(f"http://localhost:{self.jupyter_port}/api/status")
            if response.status_code == 200:
                self.log_message("Jupyter server already running")
                self.jupyter_token = self.extract_token_from_running_server()
            else:
                self.log_message("Starting Jupyter server")
                await self.start_jupyter_server()
        except requests.exceptions.ConnectionError:
            self.log_message("Starting Jupyter server")
            await self.start_jupyter_server()

    def extract_token_from_running_server(self):
        """Extract token from running Jupyter server"""
        try:
            # Check notebook list for token
            response = requests.get(f"http://localhost:{self.jupyter_port}/api/notebooks")
            if 'token' in response.url:
                query = urlparse(response.url).query
                token = parse_qs(query).get('token', [None])[0]
                if token:
                    self.log_message(f"Found Jupyter token: {token}")
                    return token
        except Exception as e:
            self.log_message(f"Error extracting token: {e}")
        return None

    async def start_jupyter_server(self):
        """Start Jupyter server and get token"""
        try:
            process = await asyncio.create_subprocess_exec(
                'jupyter', 'notebook',
                '--no-browser',
                f'--port={self.jupyter_port}',
                '--NotebookApp.token=""',  # Empty token for our secure environment
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE
            )
            
            # Wait for server to start
            while True:
                line = await process.stderr.readline()
                if not line:
                    break
                if b'http://localhost' in line:
                    self.jupyter_token = ""  # We're using empty token
                    self.log_message("Jupyter server started successfully")
                    break
                
        except Exception as e:
            self.log_message(f"Error starting Jupyter server: {e}")
            raise

    async def start_websocket_server(self):
        """Start WebSocket server for monitoring connections"""
        server = await websockets.serve(
            self.handle_websocket,
            "localhost",
            8765  # WebSocket port
        )
        self.log_message("WebSocket server started")
        return server

    async def handle_websocket(self, websocket, path):
        """Handle WebSocket connections"""
        self.connections.add(websocket)
        try:
            async for message in websocket:
                await self.process_message(websocket, message)
        finally:
            self.connections.remove(websocket)

    async def process_message(self, websocket, message):
        """Process incoming WebSocket messages"""
        try:
            data = json.loads(message)
            if '©' in data.get('text', '') or 'ß' in data.get('text', ''):
                await self.handle_special_char_connection(websocket, data)
        except json.JSONDecodeError:
            pass

    async def handle_special_char_connection(self, websocket, data):
        """Handle connections using special characters"""
        client_address = websocket.remote_address
        if client_address not in self.special_char_connections:
            self.special_char_connections[client_address] = {
                'first_seen': datetime.datetime.now().isoformat(),
                'occurrences': 0,
                'special_chars': set()
            }
        
        conn_data = self.special_char_connections[client_address]
        conn_data['occurrences'] += 1
        if '©' in data.get('text', ''):
            conn_data['special_chars'].add('©')
        if 'ß' in data.get('text', ''):
            conn_data['special_chars'].add('ß')
        
        await self.log_special_char_connection(client_address, conn_data)

    async def log_special_char_connection(self, address, data):
        """Log special character connections"""
        log_entry = {
            'timestamp': datetime.datetime.now().isoformat(),
            'address': str(address),
            'data': {
                'first_seen': data['first_seen'],
                'occurrences': data['occurrences'],
                'special_chars': list(data['special_chars'])
            }
        }
        
        with open(self.log_file, 'a') as f:
            json.dump(log_entry, f)
            f.write('\n')

    async def cloud_purge(self):
        """Main cloud purge function"""
        self.log_message("--- PROTOCOL: CLOUD PURGE INITIATED ---")
        
        try:
            # Scan for files to purge
            await self.scan_and_stage_files()
            
            # Process staged files
            await self.process_staged_files()
            
            # Clean up
            await self.cleanup()
            
        except Exception as e:
            self.log_message(f"Error during cloud purge: {e}")
            raise

    async def scan_and_stage_files(self):
        """Scan and stage files for processing"""
        self.log_message("Scanning for files to process...")
        
        # Define patterns to match
        patterns = [
            "*.log", "*.tmp", "*.cache",
            "**/node_modules/**",
            "**/.git/**",
            "**/build/**"
        ]
        
        for pattern in patterns:
            for file_path in Path(self.home_dir).rglob(pattern):
                if await self.should_process_file(file_path):
                    await self.stage_file(file_path)

    async def should_process_file(self, file_path):
        """Determine if file should be processed"""
        # Check if file is in use
        try:
            with open(file_path, 'rb') as f:
                return True
        except (IOError, PermissionError):
            return False

    async def stage_file(self, file_path):
        """Stage file for processing"""
        relative_path = os.path.relpath(file_path, self.home_dir)
        stage_path = os.path.join(self.staging_path, relative_path)
        
        os.makedirs(os.path.dirname(stage_path), exist_ok=True)
        shutil.copy2(file_path, stage_path)
        
        self.log_message(f"Staged file: {relative_path}")

    async def process_staged_files(self):
        """Process staged files"""
        self.log_message("Processing staged files...")
        
        for root, _, files in os.walk(self.staging_path):
            for file in files:
                file_path = os.path.join(root, file)
                await self.process_file(file_path)

    async def process_file(self, file_path):
        """Process individual file"""
        try:
            # Check for special characters in content
            with open(file_path, 'r', errors='ignore') as f:
                content = f.read()
                if '©' in content or 'ß' in content:
                    await self.handle_special_char_file(file_path, content)
                    
            # Archive processed file
            await self.archive_file(file_path)
            
        except Exception as e:
            self.log_message(f"Error processing file {file_path}: {e}")

    async def handle_special_char_file(self, file_path, content):
        """Handle files containing special characters"""
        self.log_message(f"Found special characters in: {file_path}")
        
        # Log occurrence
        log_entry = {
            'timestamp': datetime.datetime.now().isoformat(),
            'file': file_path,
            'special_chars': {
                '©': content.count('©'),
                'ß': content.count('ß')
            }
        }
        
        with open(self.log_file, 'a') as f:
            json.dump(log_entry, f)
            f.write('\n')

    async def archive_file(self, file_path):
        """Archive processed file"""
        archive_path = os.path.join(
            self.staging_path,
            'archived',
            datetime.datetime.now().strftime('%Y%m%d'),
            os.path.basename(file_path)
        )
        
        os.makedirs(os.path.dirname(archive_path), exist_ok=True)
        shutil.move(file_path, archive_path)
        
        self.log_message(f"Archived: {file_path} -> {archive_path}")

    async def cleanup(self):
        """Clean up after processing"""
        self.log_message("Performing cleanup...")
        
        # Remove empty directories
        for root, dirs, files in os.walk(self.staging_path, topdown=False):
            for dir in dirs:
                try:
                    os.rmdir(os.path.join(root, dir))
                except OSError:
                    pass  # Directory not empty
                    
        self.log_message("Cleanup complete")

    def log_message(self, message):
        """Log a message to both console and file"""
        timestamp = datetime.datetime.now().isoformat()
        log_entry = f"[{timestamp}] {message}"
        
        print(log_entry)
        with open(self.log_file, 'a') as f:
            f.write(log_entry + '\n')

async def main():
    purge_system = IntegratedCloudPurge()
    await purge_system.initialize()
    await purge_system.cloud_purge()
    
    # Keep the WebSocket server running
    while True:
        await asyncio.sleep(1)

if __name__ == "__main__":
    asyncio.run(main())
