Setting up Sunshine on an Arch Linux VM using a virtio-gpu (VirGL/Venus) requires specific permissions and driver configurations to ensure hardware-accelerated capture and encoding. Since you're in a virtualized environment, you'll primarily rely on KMS (Kernel Mode Setting) capture.

Follow these steps to complete the setup:

1. Install Necessary Drivers

For virtio-gpu to work with hardware acceleration (OpenGL/Vulkan), you need the correct Mesa drivers within the guest.

```bash
sudo pacman -S mesa libva-mesa-driver vulkan-virtio
vulkan-virtio: Provides the "Venus" driver for Vulkan acceleration (if supported by your host/QEMU version).
```

libva-mesa-driver: Required for VA-API hardware encoding.

2. Configure Permissions (Crucial)

Sunshine needs permission to access the kernel's display buffer (KMS) and the input system (uinput).

A. Enable KMS Capture Sunshine requires the cap_sys_admin capability to grab the screen directly from the DRM/KMS interface in a VM.

```bash
sudo setcap cap_sys_admin+p $(readlink -f $(which sunshine))
```

B. Setup Uinput Rules This allows Sunshine to simulate mouse and keyboard input.

```bash
echo 'KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"' | sudo tee /etc/udev/rules.d/60-sunshine.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo modprobe uinput
```

3. Ensure KMS is Loaded Early

Edit your /etc/mkinitcpio.conf to ensure the virtio-gpu driver is loaded at the earliest possible stage:

Find the `MODULES` line and add `virtio_gpu`: `MODULES=(virtio_gpu ...)`

Regenerate the initramfs:

```bash
sudo mkinitcpio -P
```

4. Configuration & Running

Start Sunshine:

```bash
sunshine
```

Access Web UI: Open a browser on the VM (or from the host if networking is bridged) at https://localhost:47990.

Capture Method: In the Sunshine Web UI under Settings > Audio/Video, ensure the "Preparation" or "Video" settings are pointing to the correct KMS grabber. On Linux, it should auto-detect, but if you see a black screen, ensure your user is in the video and render groups:

```bash
sudo usermod -aG video,render $USER
```

(Log out and back in for group changes to take effect.)

5. Troubleshooting Black Screens

Virtual GPUs can be finicky with resolution. If Moonlight shows a black screen:

Force a Resolution: In the Sunshine Web UI, go to Applications > Desktop and set a specific resolution (e.g., 1920x1080) to match your VM's virtual display.

Check VA-API: Run vainfo in the terminal. If it doesn't show virtio_gpu as an entry, Sunshine will fall back to software encoding (libx264), which is much slower.

To automate your setup, we need to handle this in two layers: the **System Level** (getting to the login screen) and the **User Level** (starting Sunshine once you are in your desktop).

### 1. Enable SDDM (System Level)

SDDM is a system service, so we enable it using `sudo`. This will ensure that when you boot your Arch VM, you are greeted by the login screen instead of a black terminal.

```bash
# Install SDDM if you haven't already
sudo pacman -S sddm

# Enable it to start on every boot
sudo systemctl enable sddm

# (Optional) If you want your VM to log in automatically to the desktop:
# Create an autologin config
sudo mkdir -p /etc/sddm.conf.d/
echo -e "[Autologin]\nUser=$USER\nSession=hyprland" | sudo tee /etc/sddm.conf.d/autologin.conf

```

---

### 2. Enable Sunshine (User Level)

Sunshine should **not** run as a system service because it needs access to your specific Wayland/Hyprland session to capture the screen. You have two ways to do this:

#### Method A: The Hyprland Way (Easiest)

Simply tell Hyprland to launch Sunshine the moment it starts.
Edit `~/.config/hypr/hyprland.conf` and add this line:

```bash
exec-once = sunshine

```

#### Method B: The Systemd User Way (More Robust)

If you want the system to automatically restart Sunshine if it crashes, use a user-level service:

```bash
# Enable Sunshine for your specific user
systemctl --user enable sunshine

# Note: For this to work on Wayland, you may need to ensure your 
# graphical session is "imported" into systemd. 
# Most Hyprland users add this to their hyprland.conf:
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

```

---

### 🎥 The "Content" Strategy: The "Pro Home-Lab" Workflow

This is where you bridge the gap between "technical" and "convenience" for your viewers.

* **News/Hack (Collaborator):** > "Tired of typing your password every time you want to stream? We set up SDDM autologin so the VM boots straight into Hyprland and Sunshine. Now, my Arch desktop is ready to stream the second I turn on my Proxmox server."
* **Deep Dive (You):** > Explain **`systemctl --user`**. Why don't we use `sudo systemctl` for Sunshine? Because of **XDG_RUNTIME_DIR** and **Wayland Permissions**. Explain that Sunshine needs to 'live' inside your user's graphical session to have the rights to record the screen.

---

### Next Step: Testing the Boot Loop

1. **Reboot your VM:** `sudo reboot`
2. **Wait 30 seconds.**
3. **Check Moonlight on your Mac.**

**Does the VM show up as "Online" without you having to touch the Proxmox console?**


Here is a clean, copy-pasteable `README.md` formatted specifically for your Arch Linux VM project. It includes the "Dependency Hell" fixes we navigated (like the `icu` library) and the specific configurations for Hyprland and Proxmox.

---

# 🚀 Arch Linux Streaming VM Setup (Sunshine + Hyprland)

This guide covers the installation of **Sunshine** for low-latency streaming on Arch Linux within a Proxmox environment, including the fixes for common library errors and Intel iGPU drivers.

---

## 1. Intel Graphics & Media Drivers

Install the necessary drivers for Intel UHD 740 and the `vainfo` utility to verify hardware acceleration.

```bash
sudo pacman -S --needed intel-media-driver libva-utils base-devel git

```

**Verify Driver:**

```bash
# This should show 'iHD' and entrypoints for H.264/HEVC
LIBVA_DRIVER_NAME=iHD vainfo

```

---

## 2. Sunshine Installation & Dependency Fixes

Since Sunshine often breaks during Arch `icu` library updates, we use the compatibility package.

```bash
sudo pacman -S sunshine --needed



sudo nmcli connection modify "Wired Connection 1" \
ipv4.method "manual" \
ipv4.addresses "192.168.1.202/16" \
ipv4.gateway "192.168.29.1" \
ipv4.dns "192.168.1.151"

sudo nmcli connection up "Wired Connection 1"
```

---

## 3. Network Configuration

To access the Sunshine Web UI from your Mac, you must allow LAN traffic.

1. **Edit Config:** `nano ~/.config/sunshine/sunshine.conf`
2. **Add/Update these lines:**
```text
origin_web_ui_allowed = lan
external_ip = 192.168.1.202

```


3. **Firewall (UFW):** Open the "Magic 8" ports for Moonlight. In this case not required since ufw and firewalld is disabled.
```bash
sudo ufw allow 47984,47989,48010/tcp
sudo ufw allow 47998,47999,48000,48002,48010/udp

```



---

## 4. Hyprland & SDDM (Boot Configuration)

To make the VM "headless-ready" so it boots straight to a streamable state.

### A. Enable SDDM (Login Manager)

```bash
sudo pacman -S sddm
sudo systemctl enable sddm

```

### B. Configure Hyprland (`~/.config/hypr/hyprland.conf`)

Add these lines to handle the cursor and autostart Sunshine:

```bash
# Fix invisible cursor on VirtIO/iGPU
cursor {
    no_hardware_cursors = true
}

# Ensure systemd environment is aware of Wayland
# exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

# Autostart Sunshine
exec-once = ... & sunshine

```

---

## 5. Streaming Shortcuts (Moonlight Client)

| Action | Key Combination (Mac) |
| --- | --- |
| **Quit Session** | `Shift` + `Ctrl` + `Opt` + `Q` |
| **Toggle Mouse Capture** | `Ctrl` + `Opt` + `Cmd` + `G` |
| **Stats Overlay** | `Ctrl` + `Opt` + `Cmd` + `S` |

---

## 🛠️ Troubleshooting Tips

* **Web UI Address:** `https://<VM_IP>:47990` (Ignore the "Insecure" certificate warning).
* **Resetting PINs:** If pairing fails, delete `~/.config/sunshine/sunshine.conf` and restart.
* **Proxmox Hardware:** Ensure the VM "Network" tab has the **Firewall** box **unchecked** if you cannot find the PC in Moonlight.

---

### 🎙️ The "Content" Next Step

**Would you like me to draft the "News/Hack" script for your collaborator based on this README, or should we move on to the Proxmox Host configuration for the GPU Passthrough?**