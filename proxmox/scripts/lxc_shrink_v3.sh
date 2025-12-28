#!/bin/bash

# ==============================================================================
# --- Functions ---
# ==============================================================================

# Function for error checking and early exit
error_exit() {
    echo -e "\n\033[0;31mERROR:\033[0m $1" >&2
    echo -e "\033[0;33m--- Exiting Script ---\033[0m" >&2
    exit 1
}

# Function to check the exit status of the previous command
verify_step() {
    if [ $? -ne 0 ]; then
        error_exit "Step '$1' failed. Check the output above for details."
    fi
}

# Function to display usage information
show_usage() {
    echo "Usage: $0 <VMID> <NEW_DISK_SIZE> [DISK_FILENAME]"
    echo ""
    echo "  <VMID>            : The container ID (e.g., 165)."
    echo "  <NEW_DISK_SIZE>   : The final desired disk size (e.g., 50G, 20G). Must be smaller than current size."
    echo "  [DISK_FILENAME]   : Optional. The raw image filename (e.g., vm-165-disk-0.raw)."
    echo "                      Default value is calculated as: vm-<VMID>-disk-0.raw"
    echo ""
    exit 1
}

# Function to get user permission before critical steps
prompt_and_confirm() {
    local message="$1"
    local command_desc="$2"
    echo -e "\n\033[1;33m[ACTION REQUIRED]\033[0m: ${message}"
    echo "The next command is: \033[0;36m${command_desc}\033[0m"
    read -r -p "Do you want to proceed? (y/N): " response
    
    if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        error_exit "User canceled the operation."
    fi
    echo -e "\033[0;32mPermission Granted.\033[0m"
}

# ==============================================================================
# --- Input and Configuration ---
# ==============================================================================

# Check for minimum required arguments
if [ "$#" -lt 2 ]; then
    show_usage
fi

# Set variables from arguments
VMID="$1"
NEW_DISK_SIZE="$2"
DISK_FILENAME="${3:-vm-${VMID}-disk-0.raw}" # Use argument 3, or default if missing

# Calculate filesystem size (0.5G smaller than disk size)
if ! command -v units &> /dev/null; then
    # Simple fallback
    NEW_FS_SIZE_VAL=$(echo "${NEW_DISK_SIZE%G} - 0.5" | bc)
    NEW_FS_SIZE="${NEW_FS_SIZE_VAL}G"
else
    # Calculate more precisely
    TARGET_BYTES=$(units -t -o '%.0f' "${NEW_DISK_SIZE}" 'bytes')
    REDUCED_BYTES=$(( TARGET_BYTES - 500 * 1024 * 1024 )) # Subtract 500MB
    BYTES_IN_G=$(units -t -o '%.0f' '1G' 'bytes')
    NEW_FS_SIZE=$(echo "scale=1; $REDUCED_BYTES / $BYTES_IN_G" | bc)
    NEW_FS_SIZE="${NEW_FS_SIZE}G"
fi

# --- Paths ---
LXC_CONF="/etc/pve/lxc/${VMID}.conf"
DISK_PATH="/var/lib/vz/images/${VMID}/${DISK_FILENAME}"
TEMP_CONF_FILE="/tmp/${VMID}_conf_backup.conf"

# ==============================================================================
# --- Verification Functions ---
# ==============================================================================

# Function to check current sizes and validate target size
verify_current_size() {
    echo "--- Current State Verification ---"
    
    # 1. Check Configuration File Existence
    if [ ! -f "${LXC_CONF}" ]; then
        error_exit "Container config file not found: ${LXC_CONF}. Check VMID: ${VMID}."
    fi

    # 2. Check Disk File Existence
    if [ ! -f "${DISK_PATH}" ]; then
        error_exit "Disk file not found at: ${DISK_PATH}. Check DISK_FILENAME: ${DISK_FILENAME}."
    fi
    echo -e "\033[0;32mVerification OK:\033[0m Config and Disk file paths confirmed."

    # 3. Get and compare current size
    CURRENT_CONF_LINE=$(grep "rootfs:" ${LXC_CONF})
    if [[ ! "${CURRENT_CONF_LINE}" == *"${DISK_FILENAME},size="* ]]; then
        error_exit "Rootfs line in config does not match expected filename: ${DISK_FILENAME}. Check config: ${LXC_CONF}"
    fi

    CURRENT_CONF_SIZE=$(echo "${CURRENT_CONF_LINE}" | sed -n 's/.*size=\([0-9]\+[Gg]\).*/\1/p')
    
    # Get actual size in GB for comparison
    CURRENT_DISK_GB=$(qemu-img info --output=json ${DISK_PATH} 2>/dev/null | grep -oP '"actual-size": \K[0-9]+' | awk '{print int($1/1024/1024/1024)}' )
    TARGET_DISK_GB=$(echo "${NEW_DISK_SIZE%G}")
    
    echo "Current Config Size: ${CURRENT_CONF_SIZE}"
    echo "Current Actual Disk Size (approx): ${CURRENT_DISK_GB}G"
    echo "Target New Disk Size: ${NEW_DISK_SIZE}"
    echo "Target New Filesystem Size: ${NEW_FS_SIZE}"
    
    if [[ "${CURRENT_DISK_GB}" -le "${TARGET_DISK_GB}" ]]; then
        error_exit "Current disk size (${CURRENT_DISK_GB}G) is smaller than or equal to the target size (${TARGET_DISK_GB}G). Aborting."
    fi

    # 4. Check Container Status
    STATUS=$(pct status ${VMID})
    if [[ "${STATUS}" != "status: stopped" ]]; then
        error_exit "Container ${VMID} must be stopped to perform filesystem operations. Current status: ${STATUS}. Please run 'pct stop ${VMID}' first."
    fi

    echo -e "\033[0;32mVerification OK:\033[0m Container is stopped and ready for operation."
}

# ==============================================================================
# --- Main Execution ---
# ==============================================================================

echo "--- Starting LXC Disk Shrink for VMID ${VMID} ---"

# 1. Initial Verifications
echo -e "\n\033[1m[STEP 1/5] Running Initial Checks...\033[0m"
verify_current_size

# 2. Filesystem Check (e2fsck)
echo -e "\n\033[1m[STEP 2/5] Checking Filesystem Integrity...\033[0m"

prompt_and_confirm \
    "About to check the filesystem for errors. This is required before shrinking." \
    "e2fsck -fy ${DISK_PATH}"

echo "Running e2fsck on ${DISK_PATH}..."
e2fsck -fy ${DISK_PATH}
verify_step "e2fsck"

# 3. Filesystem Shrink (resize2fs)
echo -e "\n\033[1m[STEP 3/5] Shrinking Filesystem...\033[0m"

prompt_and_confirm \
    "About to shrink the filesystem inside the raw image file to ${NEW_FS_SIZE}. Do NOT proceed if you have not backed up your container." \
    "resize2fs ${DISK_PATH} ${NEW_FS_SIZE}"

echo "Shrinking filesystem to ${NEW_FS_SIZE}..."
resize2fs ${DISK_PATH} ${NEW_FS_SIZE}
verify_step "resize2fs"

# 4. Disk Image Shrink (qemu-img resize --shrink)
echo -e "\n\033[1m[STEP 4/5] Shrinking Raw Disk Image File...\033[0m"

prompt_and_confirm \
    "About to PHYSICALLY shrink the raw disk image file to ${NEW_DISK_SIZE}. This is a critical, potentially destructive step." \
    "qemu-img resize --shrink ${DISK_PATH} ${NEW_DISK_SIZE}"

echo "Running qemu-img resize --shrink to ${NEW_DISK_SIZE}..."
qemu-img resize --shrink ${DISK_PATH} ${NEW_DISK_SIZE}
verify_step "qemu-img resize"

# Verify the qemu-img operation was successful
NEW_ACTUAL_SIZE_GB=$(qemu-img info --output=json ${DISK_PATH} 2>/dev/null | grep -oP '"actual-size": \K[0-9]+' | awk '{print int($1/1024/1024/1024)}' )
if [[ "${NEW_ACTUAL_SIZE_GB}" -gt "${TARGET_DISK_GB}" ]]; then
    error_exit "Disk file size after shrink (${NEW_ACTUAL_SIZE_GB}G) is larger than target size (${TARGET_DISK_GB}G). Manual inspection required."
fi
echo -e "\033[0;32mVerification OK:\033[0m Disk file physically shrunk to ~${NEW_ACTUAL_SIZE_GB}G."


# 5. Update Container Configuration
echo -e "\n\033[1m[STEP 5/5] Updating Proxmox Configuration...\033[0m"

prompt_and_confirm \
    "About to update the Proxmox configuration file to reflect the new size (${NEW_DISK_SIZE})." \
    "sed -i 's/size=.../' ${LXC_CONF}"

# Backup original config
cp ${LXC_CONF} ${TEMP_CONF_FILE}
verify_step "Config Backup"
echo "Original config backed up to ${TEMP_CONF_FILE}"

# Use sed to replace the size in the rootfs line
sed -i "s/\(rootfs:.*size=\)[0-9]\+[Gg]/\1${NEW_DISK_SIZE}/" ${LXC_CONF}
verify_step "Config Update (sed)"

# Verify the config update was successful
if ! grep -q "size=${NEW_DISK_SIZE}" ${LXC_CONF}; then
    error_exit "Failed to verify the config file update. The new size ${NEW_DISK_SIZE} was not found."
fi
echo -e "\033[0;32mVerification OK:\033[0m ${LXC_CONF} updated to size=${NEW_DISK_SIZE}."


# 6. Finalize
echo -e "\n\033[1m[STEP 6/6] Finalizing...\033[0m"
echo -e "\033[0;32m--- Script Finished Successfully ---\033[0m"
echo -e "\n\033[0;34mNext Steps:\033[0m"
echo "1. Start container ${VMID}: \033[0;36mpct start ${VMID}\033[0m"
echo "2. Verify the size inside: \033[0;36mpct enter ${VMID} && df -h\033[0m"