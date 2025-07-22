#!/usr/bin/env python3
import os
import sys
import json
import asyncio
import aiohttp
import datetime
from google.colab import auth
from google.colab import drive
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from google.auth.transport.requests import Request
from google_auth_oauthlib.flow import InstalledAppFlow

class ColabBackendIntegration:
    def __init__(self):
        self.port = 8888
        self.drive_service = None
        self.history_cache = {}
        self.deleted_items = []
        self.recovery_queue = []
        self.SCOPES = [
            'https://www.googleapis.com/auth/drive.file',
            'https://www.googleapis.com/auth/drive.metadata',
            'https://www.googleapis.com/auth/drive.activity',
            'https://www.googleapis.com/auth/drive.activity.readonly'
        ]

    async def initialize(self):
        """Initialize the Colab backend integration"""
        print("Initializing Colab Backend Integration...")
        
        # Set up secure directories
        os.makedirs('drive_cache', exist_ok=True)
        os.makedirs('history_logs', exist_ok=True)
        
        # Initialize Google Drive connection
        await self.setup_drive_connection()
        
        # Start monitoring services
        await asyncio.gather(
            self.start_history_monitor(),
            self.start_backend_server(),
            self.monitor_deletions()
        )

    async def setup_drive_connection(self):
        """Set up Google Drive connection with enhanced security"""
        try:
            # Authenticate with enhanced security
            creds = None
            if os.path.exists('token.json'):
                with open('token.json', 'r') as token:
                    creds = Credentials.from_authorized_user_file('token.json', self.SCOPES)

            if not creds or not creds.valid:
                if creds and creds.expired and creds.refresh_token:
                    creds.refresh(Request())
                else:
                    flow = InstalledAppFlow.from_client_secrets_file(
                        'credentials.json', self.SCOPES)
                    creds = flow.run_local_server(port=0)

                with open('token.json', 'w') as token:
                    token.write(creds.to_json())

            self.drive_service = build('drive', 'v3', credentials=creds)
            print("Drive connection established")
            
            # Mount Google Drive
            drive.mount('/content/drive')
            
        except Exception as e:
            print(f"Error setting up drive connection: {e}")
            raise

    async def start_history_monitor(self):
        """Monitor Google Drive history"""
        while True:
            try:
                # Get activity feed
                activities = await self.get_drive_activities()
                
                # Process activities for deletions
                for activity in activities:
                    if self.is_deletion_activity(activity):
                        await self.process_deletion(activity)
                
                # Cache history
                await self.cache_history(activities)
                
                await asyncio.sleep(60)  # Check every minute
            except Exception as e:
                print(f"History monitor error: {e}")
                await asyncio.sleep(5)

    async def get_drive_activities(self):
        """Get Google Drive activity feed"""
        try:
            service = build('driveactivity', 'v2', credentials=self.drive_service._credentials)
            results = service.activity().query(body={
                'pageSize': 1000,
                'filter': "time >= \"2024-01-01T00:00:00Z\""
            }).execute()
            
            return results.get('activities', [])
        except Exception as e:
            print(f"Error getting drive activities: {e}")
            return []

    def is_deletion_activity(self, activity):
        """Check if activity is a deletion"""
        try:
            actions = activity.get('actions', [])
            for action in actions:
                if action.get('delete'):
                    return True
            return False
        except Exception:
            return False

    async def process_deletion(self, activity):
        """Process and log deletion activity"""
        try:
            timestamp = activity['timestamp']
            targets = activity.get('targets', [])
            
            for target in targets:
                file_name = target.get('driveItem', {}).get('name', 'Unknown')
                self.deleted_items.append({
                    'name': file_name,
                    'timestamp': timestamp,
                    'activity_id': activity['id']
                })
                
                # Add to recovery queue
                self.recovery_queue.append({
                    'file_name': file_name,
                    'activity_id': activity['id'],
                    'timestamp': timestamp
                })
                
                await self.log_deletion(file_name, timestamp, activity['id'])
        except Exception as e:
            print(f"Error processing deletion: {e}")

    async def cache_history(self, activities):
        """Cache drive history"""
        cache_file = os.path.join('drive_cache', f'history_{datetime.datetime.now().strftime("%Y%m%d")}.json')
        
        try:
            with open(cache_file, 'w') as f:
                json.dump(activities, f)
        except Exception as e:
            print(f"Error caching history: {e}")

    async def start_backend_server(self):
        """Start the backend server"""
        from aiohttp import web
        
        app = web.Application()
        app.router.add_get('/', self.handle_root)
        app.router.add_get('/history', self.handle_history)
        app.router.add_get('/deleted', self.handle_deleted)
        app.router.add_post('/recover', self.handle_recover)
        
        runner = web.AppRunner(app)
        await runner.setup()
        site = web.TCPSite(runner, 'localhost', self.port)
        await site.start()
        print(f"Backend server running at http://localhost:{self.port}")

    async def handle_root(self, request):
        """Handle root endpoint"""
        return web.json_response({
            'status': 'active',
            'endpoints': ['/history', '/deleted', '/recover'],
            'timestamp': datetime.datetime.now().isoformat()
        })

    async def handle_history(self, request):
        """Handle history endpoint"""
        try:
            activities = await self.get_drive_activities()
            return web.json_response({
                'activities': activities,
                'cached_items': len(self.history_cache),
                'timestamp': datetime.datetime.now().isoformat()
            })
        except Exception as e:
            return web.json_response({
                'error': str(e)
            }, status=500)

    async def handle_deleted(self, request):
        """Handle deleted items endpoint"""
        return web.json_response({
            'deleted_items': self.deleted_items,
            'recovery_queue': self.recovery_queue,
            'timestamp': datetime.datetime.now().isoformat()
        })

    async def handle_recover(self, request):
        """Handle recovery endpoint"""
        try:
            data = await request.json()
            activity_id = data.get('activity_id')
            
            if not activity_id:
                return web.json_response({
                    'error': 'activity_id required'
                }, status=400)
            
            recovery_result = await self.attempt_recovery(activity_id)
            return web.json_response(recovery_result)
        except Exception as e:
            return web.json_response({
                'error': str(e)
            }, status=500)

    async def attempt_recovery(self, activity_id):
        """Attempt to recover deleted item"""
        try:
            # Find item in recovery queue
            item = next((item for item in self.recovery_queue 
                        if item['activity_id'] == activity_id), None)
            
            if not item:
                return {
                    'status': 'error',
                    'message': 'Item not found in recovery queue'
                }
            
            # Attempt recovery from trash
            file_id = await self.find_in_trash(item['file_name'])
            if file_id:
                await self.restore_from_trash(file_id)
                return {
                    'status': 'success',
                    'message': f"Recovered {item['file_name']}"
                }
            
            return {
                'status': 'error',
                'message': 'Item not found in trash'
            }
            
        except Exception as e:
            return {
                'status': 'error',
                'message': str(e)
            }

    async def find_in_trash(self, file_name):
        """Find file in Google Drive trash"""
        try:
            results = self.drive_service.files().list(
                q=f"name = '{file_name}' and trashed = true",
                spaces='drive',
                fields='files(id, name)'
            ).execute()
            
            files = results.get('files', [])
            if files:
                return files[0]['id']
            return None
            
        except Exception as e:
            print(f"Error finding in trash: {e}")
            return None

    async def restore_from_trash(self, file_id):
        """Restore file from trash"""
        try:
            self.drive_service.files().update(
                fileId=file_id,
                body={'trashed': False}
            ).execute()
            return True
        except Exception as e:
            print(f"Error restoring from trash: {e}")
            return False

    async def monitor_deletions(self):
        """Monitor for new deletions"""
        while True:
            try:
                # Get recent activities
                activities = await self.get_drive_activities()
                
                # Check for new deletions
                for activity in activities:
                    if self.is_deletion_activity(activity):
                        await self.process_deletion(activity)
                
                await asyncio.sleep(30)  # Check every 30 seconds
            except Exception as e:
                print(f"Deletion monitor error: {e}")
                await asyncio.sleep(5)

    async def log_deletion(self, file_name, timestamp, activity_id):
        """Log deletion event"""
        log_file = os.path.join('history_logs', 'deletions.log')
        
        try:
            with open(log_file, 'a') as f:
                log_entry = {
                    'file_name': file_name,
                    'timestamp': timestamp,
                    'activity_id': activity_id,
                    'logged_at': datetime.datetime.now().isoformat()
                }
                f.write(json.dumps(log_entry) + '\n')
        except Exception as e:
            print(f"Error logging deletion: {e}")

async def main():
    backend = ColabBackendIntegration()
    await backend.initialize()
    
    # Keep the server running
    while True:
        await asyncio.sleep(1)

if __name__ == "__main__":
    asyncio.run(main())
