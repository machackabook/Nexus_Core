import os
import shutil
import subprocess

# --- CONFIGURATION v2.0 ---
HOME_DIR = os.path.expanduser("~")
DOWNLOADS_PATH = os.path.join(HOME_DIR, "Downloads")
STAGING_PATH = "/Volumes/Transfer/NEXUS_STAGING"
CORE_FUNCTIONS_SOURCE = os.path.join(HOME_DIR, "NEXUS_CORE", "scripts")
CORE_FUNCTIONS_DEST = os.path.join(STAGING_PATH, "core_functions")

# Define target directories within Downloads to archive
TARGETS = ["android studio", "final cut pro", "cinema 4d", "xcode"]

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

def cloud_purge():
    """
    Identifies large assets, moves them to a staging area, stages core
    functions for recovery, and uploads the assets to cloud storage.
    """
    print("--- PROTOCOL: CLOUD PURGE v2.0 INITIATED ---")
    print(f"Staging Area: {STAGING_PATH}")

    # --- Setup Staging Directories ---
    for path in [STAGING_PATH, CORE_FUNCTIONS_DEST]:
        if not os.path.exists(path):
            print(f"Creating directory: {path}")
            os.makedirs(path)

    # --- Stage Core Functions for Recovery ---
    print("\n[+] Staging core functions for startup volume...")
    if os.path.exists(CORE_FUNCTIONS_SOURCE):
        for item in os.listdir(CORE_FUNCTIONS_SOURCE):
            source_item = os.path.join(CORE_FUNCTIONS_SOURCE, item)
            if os.path.isfile(source_item):
                shutil.copy2(source_item, CORE_FUNCTIONS_DEST)
        print(f"    -> Core functions copied to {CORE_FUNCTIONS_DEST}")
    else:
        print(f"    WARNING: Core functions source not found at {CORE_FUNCTIONS_SOURCE}")


    # --- Archive Large Assets ---
    if not os.path.exists(DOWNLOADS_PATH):
        print(f"Downloads directory not found at {DOWNLOADS_PATH}. Skipping archival.")
    else:
        print("\n[+] Scanning Downloads directory for large assets...")
        assets_to_move = []
        for item in os.listdir(DOWNLOADS_PATH):
            for target in TARGETS:
                if target.lower() in item.lower():
                    assets_to_move.append(item)
                    break
        
        if not assets_to_move:
            print("No primary target assets found to archive.")
        else:
            print("\n[+] Moving identified assets to staging area...")
            for asset in assets_to_move:
                source_path = os.path.join(DOWNLOADS_PATH, asset)
                dest_path = os.path.join(STAGING_PATH, asset)
                print(f"    -> Moving '{asset}'")
                try:
                    shutil.move(source_path, dest_path)
                except Exception as e:
                    print(f"    ERROR moving {asset}: {e}")

    # --- Initiate Cloud Transfer ---
    print("\n[+] Initiating rclone transfer to Google Drive...")
    rclone_command = f"rclone move '{STAGING_PATH}' gdrive:NEXUS_ARCHIVE --progress"
    
    print(f"Executing: {rclone_command}")
    print("This may require authentication and will take time.")
    run_command(rclone_command)

    print("\n--- CLOUD PURGE PROTOCOL COMPLETE ---")

if __name__ == "__main__":
    cloud_purge()

if __name__ == "__main__":
    cloud_purge()
