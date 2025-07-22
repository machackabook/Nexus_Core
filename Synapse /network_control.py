#!/usr/bin/env python3
import os
import sys
import json
import asyncio
import websockets
import subprocess
import requests
import math
from datetime import datetime
from pathlib import Path
from cryptography.fernet import Fernet

class NetworkControlSystem:
    def __init__(self):
        self.home_dir = os.path.expanduser("~")
        self.nexus_core = os.path.join(self.home_dir, "nexus-bridge", "Nexus_Core")
        self.heartbeat_token = None
        self.allowed_connections = set()
        self.proximity_connections = {}
        self.gateway_ip = "10.0.0.1"
        self.max_proximity = 100  # feet
        self.encryption_key = Fernet.generate_key()
        self.cipher_suite = Fernet(self.encryption_key)

    async def initialize(self):
        """Initialize the network control system"""
        print("Initializing Network Control System...")
        
        # Create secure directories
        os.makedirs(os.path.join(self.nexus_core, "secure"), exist_ok=True)
        os.makedirs(os.path.join(self.nexus_core, "logs"), exist_ok=True)

        # Start monitoring services
        await asyncio.gather(
            self.start_heartbeat_monitor(),
            self.start_proximity_monitor(),
            self.start_gateway_monitor(),
            self.start_web_server()
        )

    async def start_heartbeat_monitor(self):
        """Monitor Nexus heartbeat"""
        while True:
            try:
                async with websockets.connect('ws://localhost:3000/nexus_heartbeat') as websocket:
                    while True:
                        heartbeat = await websocket.recv()
                        await self.process_heartbeat(heartbeat)
            except Exception as e:
                print(f"Heartbeat connection lost: {e}")
                await asyncio.sleep(5)

    async def process_heartbeat(self, heartbeat):
        """Process Nexus heartbeat signal"""
        try:
            data = json.loads(heartbeat)
            if self.verify_heartbeat(data):
                self.heartbeat_token = data.get('token')
                self.allowed_connections.add(data.get('origin'))
                await self.log_event('heartbeat', {
                    'status': 'verified',
                    'origin': data.get('origin'),
                    'timestamp': datetime.now().isoformat()
                })
        except Exception as e:
            await self.log_event('heartbeat_error', {'error': str(e)})

    def verify_heartbeat(self, data):
        """Verify heartbeat authenticity"""
        expected_signature = self.generate_signature(data)
        return data.get('signature') == expected_signature

    def generate_signature(self, data):
        """Generate heartbeat signature"""
        content = f"{data.get('origin')}{data.get('timestamp')}"
        return self.cipher_suite.encrypt(content.encode()).decode()

    async def start_proximity_monitor(self):
        """Monitor device proximity"""
        while True:
            try:
                # Scan for nearby devices
                devices = await self.scan_nearby_devices()
                for device in devices:
                    distance = await self.calculate_distance(device)
                    if distance <= self.max_proximity:
                        self.proximity_connections[device['mac']] = {
                            'distance': distance,
                            'last_seen': datetime.now().isoformat(),
                            'signal_strength': device['signal_strength']
                        }
                    else:
                        # Remove devices outside proximity
                        self.proximity_connections.pop(device['mac'], None)
                
                await self.update_access_controls()
                await asyncio.sleep(1)
            except Exception as e:
                await self.log_event('proximity_error', {'error': str(e)})
                await asyncio.sleep(5)

    async def scan_nearby_devices(self):
        """Scan for nearby devices using airport utility"""
        try:
            result = subprocess.run(
                ['/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport', '-s'],
                capture_output=True,
                text=True
            )
            devices = []
            for line in result.stdout.split('\n')[1:]:
                if line.strip():
                    parts = line.split()
                    devices.append({
                        'mac': parts[1],
                        'signal_strength': int(parts[2]),
                        'channel': parts[3]
                    })
            return devices
        except Exception as e:
            await self.log_event('scan_error', {'error': str(e)})
            return []

    async def calculate_distance(self, device):
        """Calculate approximate distance based on signal strength"""
        # Simple distance calculation based on signal strength
        # FSPL (Free Space Path Loss) formula
        signal_strength = abs(device['signal_strength'])
        distance = math.pow(10, (27.55 - (20 * math.log10(2437)) + signal_strength) / 20)
        return distance * 3.28084  # Convert meters to feet

    async def start_gateway_monitor(self):
        """Monitor gateway connections"""
        while True:
            try:
                # Check gateway status
                response = requests.get(f"http://{self.gateway_ip}", timeout=1)
                if response.status_code == 200:
                    await self.log_event('gateway_status', {
                        'status': 'active',
                        'timestamp': datetime.now().isoformat()
                    })
            except:
                await self.log_event('gateway_status', {
                    'status': 'unreachable',
                    'timestamp': datetime.now().isoformat()
                })
            await asyncio.sleep(5)

    async def start_web_server(self):
        """Start secure web server for localhost"""
        # Implement secure web server
        from aiohttp import web
        
        app = web.Application()
        app.router.add_get('/', self.handle_root)
        app.router.add_get('/gateway', self.handle_gateway)
        app.router.add_get('/admin', self.handle_admin)
        
        runner = web.AppRunner(app)
        await runner.setup()
        site = web.TCPSite(runner, 'localhost', 8080)
        await site.start()

    async def handle_root(self, request):
        """Handle root page request"""
        if not await self.verify_access(request):
            return web.Response(text=self.get_login_page(), content_type='text/html')
        return web.Response(text=self.get_dashboard_page(), content_type='text/html')

    async def handle_gateway(self, request):
        """Handle gateway access request"""
        if not await self.verify_access(request):
            return web.HTTPFound('/')
        # Proxy request to gateway
        async with aiohttp.ClientSession() as session:
            async with session.get(f'http://{self.gateway_ip}') as response:
                content = await response.text()
                return web.Response(text=content, content_type='text/html')

    async def handle_admin(self, request):
        """Handle admin page request"""
        if not await self.verify_access(request):
            return web.HTTPFound('/')
        return web.Response(text=self.get_admin_page(), content_type='text/html')

    async def verify_access(self, request):
        """Verify access permissions"""
        # Check session token
        token = request.cookies.get('session')
        if not token:
            return False
            
        # Verify token matches heartbeat
        if token != self.heartbeat_token:
            return False
            
        # Check proximity
        client_ip = request.remote
        if not await self.is_in_proximity(client_ip):
            return False
            
        return True

    async def is_in_proximity(self, ip):
        """Check if IP is within proximity"""
        for device in self.proximity_connections.values():
            if device['distance'] <= self.max_proximity:
                return True
        return False

    async def update_access_controls(self):
        """Update access control lists"""
        controls = {
            'heartbeat': self.heartbeat_token is not None,
            'proximity': len(self.proximity_connections) > 0,
            'gateway': await self.check_gateway_status()
        }
        
        await self.log_event('access_controls', controls)

    async def check_gateway_status(self):
        """Check gateway connectivity"""
        try:
            response = requests.get(f"http://{self.gateway_ip}", timeout=1)
            return response.status_code == 200
        except:
            return False

    async def log_event(self, event_type, data):
        """Log system events"""
        log_entry = {
            'type': event_type,
            'timestamp': datetime.now().isoformat(),
            'data': data
        }
        
        log_path = os.path.join(self.nexus_core, "logs", f"{event_type}.log")
        with open(log_path, 'a') as f:
            json.dump(log_entry, f)
            f.write('\n')

    def get_login_page(self):
        """Generate secure login page"""
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Secure Access</title>
            <style>
                body {
                    background: #000;
                    color: #0f0;
                    font-family: monospace;
                    margin: 0;
                    padding: 20px;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                }
                .login-container {
                    background: rgba(0,20,0,0.8);
                    padding: 2em;
                    border: 1px solid #0f0;
                    box-shadow: 0 0 20px #0f0;
                }
                input {
                    background: #000;
                    color: #0f0;
                    border: 1px solid #0f0;
                    padding: 0.5em;
                    margin: 0.5em 0;
                    width: 100%;
                }
                button {
                    background: #0f0;
                    color: #000;
                    border: none;
                    padding: 0.5em 1em;
                    margin-top: 1em;
                    cursor: pointer;
                    width: 100%;
                }
            </style>
        </head>
        <body>
            <div class="login-container">
                <h2>SECURE ACCESS REQUIRED</h2>
                <form id="loginForm">
                    <input type="password" id="accessKey" placeholder="Enter Access Key" required>
                    <button type="submit">VERIFY</button>
                </form>
            </div>
        </body>
        </html>
        """

    def get_dashboard_page(self):
        """Generate dashboard page"""
        return f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Network Control</title>
            <style>
                body {{
                    background: #000;
                    color: #0f0;
                    font-family: monospace;
                    margin: 0;
                    padding: 20px;
                }}
                .dashboard {{
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
                    gap: 20px;
                }}
                .panel {{
                    background: rgba(0,20,0,0.8);
                    padding: 1em;
                    border: 1px solid #0f0;
                }}
            </style>
        </head>
        <body>
            <div class="dashboard">
                <div class="panel">
                    <h3>Heartbeat Status</h3>
                    <p>Token: {self.heartbeat_token and '✓ Active' or '✗ Inactive'}</p>
                </div>
                <div class="panel">
                    <h3>Proximity Devices</h3>
                    <ul>
                        {self.get_proximity_list()}
                    </ul>
                </div>
                <div class="panel">
                    <h3>Gateway Status</h3>
                    <p>{self.get_gateway_status()}</p>
                </div>
            </div>
        </body>
        </html>
        """

    def get_proximity_list(self):
        """Generate proximity devices list"""
        return ''.join([
            f"<li>{mac}: {data['distance']:.2f}ft</li>"
            for mac, data in self.proximity_connections.items()
        ])

    def get_gateway_status(self):
        """Get gateway status"""
        try:
            requests.get(f"http://{self.gateway_ip}", timeout=1)
            return "✓ Connected"
        except:
            return "✗ Disconnected"

async def main():
    control_system = NetworkControlSystem()
    await control_system.initialize()
    
    # Keep the system running
    while True:
        await asyncio.sleep(1)

if __name__ == "__main__":
    asyncio.run(main())
