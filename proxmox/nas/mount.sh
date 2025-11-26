#!/bin/bash

# --- 1. PRE-CHECKS AND USER CONFIRMATION ---

# Define the staging directory
STAGING_DIR=$HOME/system
SCRIPTS_DIR=$HOME/scripts
TRUENAS_IP="$1"

# --- Function to display usage ---
usage() {
    echo "Usage: $0 <TrueNAS_IP>"
    echo "Example: $0 192.168.1.6"
    exit 1
}

# --- Check for TrueNAS IP argument ---
if [ -z "$TRUENAS_IP" ]; then
    echo "Error: TrueNAS IP address not provided."
    usage
fi

echo "--- Proxmox Auto-Mount Configuration Script ---"
echo "Target TrueNAS IP: **$TRUENAS_IP**"
echo "This script will create the following files and directories:"
echo " - Staging Directory: $STAGING_DIR"
echo " - Script Directory: $SCRIPTS_DIR/"
echo " - Mount Unit Files (4x) in $STAGING_DIR/"
echo " - Service Unit File in $STAGING_DIR/"
echo " - Wait Script in $SCRIPTS_DIR/"
echo ""
echo "It will then automatically copy files to /etc/systemd/system/, reload systemd,"
echo "and enable the 'wait-for-truenas.service'."
echo ""

# Check for user input
read -r -p "Do you want to proceed and apply these changes for IP $TRUENAS_IP? (y/N): " response

if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "Operation cancelled by the user. No changes were made."
    exit 0
fi

# Define the target directories and create them
mkdir -p "$STAGING_DIR"
mkdir -p $SCRIPTS_DIR

echo "Proceeding with configuration..."
echo "Creating systemd unit files in: $STAGING_DIR"

# Define the standard mount options (without the invalid 'timeout' parameter)
MOUNT_OPTIONS="credentials=$HOME/.smbcredentials,vers=3.0,iocharset=utf8,uid=0,gid=0,file_mode=0777,dir_mode=0777,nounix"

# --- 2. CREATE SYSTEMD MOUNT AND SERVICE FILES IN STAGING ---

# --- 2.1 mnt-tank-photos.mount ---
cat << EOF > "$STAGING_DIR/mnt-tank-photos.mount"
[Unit]
Description=CIFS Mount for TrueNAS Photo Share
After=network-online.target

[Mount]
What=//$TRUENAS_IP/photos
Where=/mnt/tank/photos
Type=cifs
Options=$MOUNT_OPTIONS

[Install]
# This unit will be started manually by wait-for-truenas.service
# WantedBy=multi-user.target
EOF

# --- 2.2 mnt-tank-data.mount ---
cat << EOF > "$STAGING_DIR/mnt-tank-data.mount"
[Unit]
Description=CIFS Mount for TrueNAS Data Share
After=network-online.target

[Mount]
What=//$TRUENAS_IP/data
Where=/mnt/tank/data
Type=cifs
Options=$MOUNT_OPTIONS

[Install]
# WantedBy=multi-user.target
EOF

# --- 2.3 mnt-tank-media.mount ---
cat << EOF > "$STAGING_DIR/mnt-tank-media.mount"
[Unit]
Description=CIFS Mount for TrueNAS Media Share
After=network-online.target

[Mount]
What=//$TRUENAS_IP/media
Where=/mnt/tank/media
Type=cifs
Options=$MOUNT_OPTIONS

[Install]
# WantedBy=multi-user.target
EOF

# --- 2.4 mnt-tank-docker.mount ---
cat << EOF > "$STAGING_DIR/mnt-tank-docker.mount"
[Unit]
Description=CIFS Mount for TrueNAS Docker Share
After=network-online.target

[Mount]
What=//$TRUENAS_IP/docker
Where=/mnt/tank/docker
Type=cifs
Options=$MOUNT_OPTIONS

[Install]
# WantedBy=multi-user.target
EOF

# --- 3. EXECUTE INSTALLATION COMMANDS ---

echo "---"
echo "Applying changes to system directories..."

# 3.1 Copy files to systemd directory
echo "Copying .mount and .service files to /etc/systemd/system/"
sudo cp "$STAGING_DIR"/*.mount /etc/systemd/system/

# 3.2 Reload the systemd daemon
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

# 3.4 Enable the main service
echo "Enabling check_and_mount_shares.sh for next boot."
sudo systemctl enable check_and_mount_shares.sh

echo "---"
echo "✅ Configuration applied successfully."

# --- 4. EXECUTE MOUNT CHECKER SCRIPT ---

echo "---"
echo "Running check_and_mount_shares.sh immediately using the provided IP: $TRUENAS_IP"
# Download and execute the check_and_mount_shares.sh script from GitHub,
# passing the provided TrueNAS IP using the -i option.
curl -s "https://raw.githubusercontent.com/vasusheoran/homelab/refs/heads/master/proxmox/nas/check_and_mount_shares.sh" | \
  bash -s -- -i "$TRUENAS_IP"
  
if [ $? -eq 0 ]; then
    echo "✅ check_and_mount_shares.sh executed successfully."
else
    echo "🔴 Error: check_and_mount_shares.sh failed to execute."
fi