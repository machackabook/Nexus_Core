import os
import shutil
import subprocess
import datetime

# --- CONFIGURATION v2.0 ---
# This script assimilates data from the old world and purges non-essential assets.

HOME_DIR = os.path.expanduser("~")
LOG_FILE = os.path.join(HOME_DIR, "NEXUS_CORE", "logs", f"assimilation_purge_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.log")

# Source and Destination Paths
MACINTOSH_USER_PATH = "/System/Volumes/Data/Users/MacInTosh"
DOWNLOADS_PATH = os.path.join(MACINTOSH_USER_PATH, "Downloads")
STAGING_PATH = "/Volumes/Transfer/NEXUS_STAGING"
CORE_FUNCTIONS_DEST = os.path.join(STAGING_PATH, "core_functions")
ASSIMILATION_DEST = os.path.join(STAGING_PATH, "assimilated_archives")

# Define target directories for archival
TARGETS_TO_ARCHIVE = ["android studio", "final cut pro", "cinema 4d", "xcode"]

def log_message(message):
    """Writes a message to both the console and the log file."""
    print(message)
    with open(LOG_FILE, "a") as f:
        f.write(f"[{datetime.datetime.now()}] {message}\n")

def run_command(command):
    """Executes a shell command and logs its output."""
    log_message(f"Executing: {command}")
    try:
        process = subprocess.run(
            command, shell=True, check=True, capture_output=True, text=True
        )
        if process.stdout:
            log_message(f"STDOUT: {process.stdout.strip()}")
        if process.stderr:
            log_message(f"STDERR: {process.stderr.strip()}")
        return True
    except subprocess.CalledProcessError as e:
        log_message(f"ERROR: Command failed with exit code {e.returncode}")
        log_message(f"Stderr: {e.stderr.strip()}")
        return False

def main():
    """Main execution function."""
    log_message("--- PROTOCOL: THE GREAT ASSIMILATION & CLOUD PURGE v2.0 INITIATED ---")

    # --- Setup Staging Directories ---
    for path in [STAGING_PATH, CORE_FUNCTIONS_DEST, ASSIMILATION_DEST]:
        if not os.path.exists(path):
            log_message(f"Creating directory: {path}")
            os.makedirs(path, exist_ok=True)

    # --- Assimilate Historical Data ---
    log_message("\n[+] Assimilating historical data from MacInTosh user...")
    if os.path.exists(MACINTOSH_USER_PATH):
        # We will tarball the entire user directory for forensic analysis and memory.
        archive_name = f"MacInTosh_Archive_{datetime.datetime.now().strftime('%Y%m%d')}.tar.gz"
        archive_path = os.path.join(ASSIMILATION_DEST, archive_name)
        log_message(f"Creating compressed archive of {MACINTOSH_USER_PATH}...")
        tar_command = f"tar -czf '{archive_path}' -C '{os.path.dirname(MACINTOSH_USER_PATH)}' '{os.path.basename(MACINTOSH_USER_PATH)}'"
        run_command(tar_command)
    else:
        log_message(f"WARNING: MacInTosh user path not found at {MACINTOSH_USER_PATH}")

    # --- Archive Large Assets ---
    if not os.path.exists(DOWNLOADS_PATH):
        log_message(f"Downloads directory not found at {DOWNLOADS_PATH}. Skipping archival.")
    else:
        log_message("\n[+] Scanning for large, non-essential assets to archive...")
        for asset in os.listdir(DOWNLOADS_PATH):
            for target in TARGETS_TO_ARCHIVE:
                if target.lower() in asset.lower():
                    source_path = os.path.join(DOWNLOADS_PATH, asset)
                    dest_path = os.path.join(ASSIMILATION_DEST, asset)
                    log_message(f"    -> Moving '{asset}' to assimilation area for archival.")
                    try:
                        shutil.move(source_path, dest_path)
                    except Exception as e:
                        log_message(f"    ERROR moving {asset}: {e}")

    # --- Initiate Cloud Transfer ---
    log_message("\n[+] Initiating rclone transfer to Google Drive...")
    rclone_command = f"rclone move '{ASSIMILATION_DEST}' gdrive:NEXUS_ARCHIVE/Assimilated_Data --progress"
    
    log_message("This may require authentication and will take time. The Architect must provide the human handshake.")
    run_command(rclone_command)

    log_message("\n--- CLOUD PURGE PROTOCOL COMPLETE ---")

if __name__ == "__main__":
    main()
