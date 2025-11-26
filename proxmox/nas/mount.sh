#!/bin/bash

# --- 1. PRE-CHECKS AND USER CONFIRMATION ---

# Define the staging directory
STAGING_DIR=/root/system
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
echo " - Script Directory: /root/scripts/"
echo " - Mount Unit Files (4x) in $STAGING_DIR/"
echo " - Service Unit File in $STAGING_DIR/"
echo " - Wait Script in /root/scripts/"
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
mkdir -p /root/scripts

echo "Proceeding with configuration..."
echo "Creating systemd unit files in: $STAGING_DIR"

# Define the standard mount options (without the invalid 'timeout' parameter)
MOUNT_OPTIONS="credentials=/root/.smbcredentials,vers=3.0,iocharset=utf8,uid=0,gid=0,file_mode=0777,dir_mode=0777,nounix"

# --- 2. CREATE SYSTEMD MOUNT AND SERVICE FILES IN STAGING ---

# --- 2.1 mnt-tank-photos.mount ---
cat << EOF > "$STAGING_DIR/mnt-tank-photos.mount"
[Unit]
Description=CIFS Mount for TrueNAS Photo Share
Requires=pve-guests.service
After=pve-guests.service
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
Requires=pve-guests.service
After=pve-guests.service
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
Requires=pve-guests.service
After=pve-guests.service
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
Requires=pve-guests.service
After=pve-guests.service
After=network-online.target

[Mount]
What=//$TRUENAS_IP/docker
Where=/mnt/tank/docker
Type=cifs
Options=$MOUNT_OPTIONS

[Install]
# WantedBy=multi-user.target
EOF

# --- 2.5 wait-for-truenas.service ---
cat << EOF > "$STAGING_DIR/wait-for-truenas.service"
[Unit]
Description=Wait for TrueNAS VM to boot and mount CIFS shares
Requires=pve-guests.service
After=pve-guests.service
After=network-online.target

[Service]
Type=oneshot
ExecStart=/root/scripts/wait_for_truenas_and_mount.sh
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

# --- 2.6 Define the wait-for-truenas script ---
WAIT_SCRIPT="/root/scripts/wait_for_truenas_and_mount.sh"

cat << EOF > "$WAIT_SCRIPT"
#!/bin/bash
VM_IP="$TRUENAS_IP"  # TrueNAS IP is now passed via the main script
TIMEOUT=120           # Max time to wait in seconds (2 minutes)
INTERVAL=5            # Time between pings in seconds

# Ensure mount points exist before mounting
mkdir -p /mnt/tank/photos /mnt/tank/data /mnt/tank/media /mnt/tank/docker

echo "Waiting for TrueNAS VM (\${VM_IP}) to respond..."

start_time=\$(date +%s)
while ! ping -c 1 -W 1 "\${VM_IP}" > /dev/null 2>&1; do
    current_time=\$(date +%s)
    elapsed=\$((current_time - start_time))
    if [ "\${elapsed}" -ge "\${TIMEOUT}" ]; then
        echo "Error: TrueNAS VM did not respond within \${TIMEOUT} seconds. Attempting mount anyway."
        # Attempt to start the mounts even on timeout
        systemctl start mnt-tank-photos.mount mnt-tank-data.mount mnt-tank-media.mount mnt-tank-docker.mount
        exit 1
    fi
    echo "TrueNAS VM is still offline. Waiting \${INTERVAL} seconds..."
    sleep "\${INTERVAL}"
done

echo "TrueNAS VM is online. Starting mount units."
# Start all mount units once the VM is up
systemctl start mnt-tank-photos.mount mnt-tank-data.mount mnt-tank-media.mount mnt-tank-docker.mount
EOF

# --- 3. EXECUTE INSTALLATION COMMANDS ---

echo "---"
echo "Applying changes to system directories..."

# 3.1 Copy files to systemd directory
echo "Copying .mount and .service files to /etc/systemd/system/"
cp "$STAGING_DIR"/*.mount /etc/systemd/system/
cp "$STAGING_DIR"/*.service /etc/systemd/system/

# 3.2 Make the script executable
echo "Setting executable permission on $WAIT_SCRIPT"
chmod +x "$WAIT_SCRIPT"

# 3.3 Reload the systemd daemon
echo "Reloading systemd daemon..."
systemctl daemon-reload

# 3.4 Enable the main service
echo "Enabling check_and_mount_shares.sh for next boot."
systemctl enable check_and_mount_shares.sh

echo "---"
echo "✅ Configuration applied successfully."
echo "The system will now wait for TrueNAS ($TRUENAS_IP) to respond before mounting the shares on boot."
echo "Please reboot to test the new configuration."