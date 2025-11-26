#!/bin/bash

# --- ⚙️ Configuration ---

# **!! IMPORTANT !!**
# Hardcoding the target IP address as requested.
NEW_VM_IP="192.168.1.8"

# Configuration: [Mount_Point]
SHARE_CONFIG=(
    "/mnt/tank/photos"
    "/mnt/tank/data"
    "/mnt/tank/media"
    "/mnt/tank/docker"
)

# --- 🛠️ Helper Functions ---

# NOTE: The get_vm_ip function has been removed as the IP is hardcoded.

# Function to update the systemd mount unit with the new IP
update_mount_unit_ip() {
    local MOUNT_POINT="$1"
    local TARGET_IP="$2" 
    
    local MOUNT_UNIT=$(/usr/bin/basename "$MOUNT_POINT" | /usr/bin/sed 's/^/mnt-tank-/')
    local MOUNT_UNIT_PATH="/etc/systemd/system/${MOUNT_UNIT}.mount"

    if [[ ! -f "$MOUNT_UNIT_PATH" ]]; then
        echo "ERROR: Mount unit file not found: $MOUNT_UNIT_PATH" >&2
        return 1
    fi
    
    # Construct the full, desired CIFS path (e.g., //192.168.1.8/media)
    local SHARE_NAME=$(/usr/bin/basename "$MOUNT_POINT")
    local NEW_PATH="//${TARGET_IP}/${SHARE_NAME}"

    # 1. Check if the line already matches the desired path
    if /usr/bin/grep -q "^What=${NEW_PATH}$" "$MOUNT_UNIT_PATH"; then
        echo "➡️ IP check for $MOUNT_UNIT: IP is already correct ($NEW_PATH). No change needed."
        return 0
    fi
    
    # 2. Substitution: Find the line starting with 'What=' and replace the entire line
    echo "🚨 What= line corrupted or changed for $MOUNT_UNIT. Forcing update to: ${NEW_PATH}..."
    
    # Use sed to find the line starting with 'What=' and replace the entire line with the new, correct line.
    /usr/bin/sed -i "/^What=/c\What=${NEW_PATH}" "$MOUNT_UNIT_PATH"

    if [[ $? -eq 0 ]]; then
        echo "✅ IP/PATH UPDATE SUCCESS: Reloading systemd daemon..."
        /usr/bin/systemctl daemon-reload
        return 0
    else
        echo "🔴 IP/PATH UPDATE FAILURE: Failed to update line in $MOUNT_UNIT_PATH. Check file permissions." >&2
        return 1
    fi
}

# Function to check if a directory is mounted
is_mounted() {
    local MOUNT_POINT="$1"
    if /usr/bin/grep -q " ${MOUNT_POINT} " /proc/mounts; then
        return 0 # Mounted
    else
        return 1 # Not mounted
    fi
}

# --- 🚀 Main Logic ---
echo "--- $(/usr/bin/date) --- Starting periodic mount check and IP hardcoding update."

echo "🟢 Target Hardcoded VM IP: $NEW_VM_IP"

# 1. Loop through all configured shares
for MOUNT_POINT in "${SHARE_CONFIG[@]}"; do
    
    # 1a. Update the systemd mount unit with the hardcoded IP (if needed)
    update_mount_unit_ip "$MOUNT_POINT" "$NEW_VM_IP"

    # 1b. Check mount status and attempt mount if not mounted
    if is_mounted "$MOUNT_POINT"; then
        echo "✅ $MOUNT_POINT is already mounted."
    else
        echo "⚠️ $MOUNT_POINT is NOT mounted. Attempting to mount..."

        MOUNT_UNIT=$(/usr/bin/basename "$MOUNT_POINT" | /usr/bin/sed 's/^/mnt-tank-/')

        /usr/bin/systemctl start "$MOUNT_UNIT".mount

        if is_mounted "$MOUNT_POINT"; then
            echo "🟢 Successfully mounted $MOUNT_POINT."
        else
            echo "🔴 Failed to mount $MOUNT_POINT. Check system logs with 'journalctl -xeu ${MOUNT_UNIT}.mount'."
        fi
    fi
done

echo "Finished mount check and IP update."
