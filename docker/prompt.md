### **"Code Unbound" Master Prompt**

Generate a 10-minute technical script for **Code Unbound // Episode 01: The Definitive Immich Guide**.

**Series Context:** The official start of the 'Homelab' playlist.
**The Tone:** Peer-mentor, senior architect, high-density, no-fluff.

**Chapters & Narrative Logic:**

1. **Intro:** Connecting from the Foundation video. Our mission: Deploying Immich with a focus on long-term sustainability.
2. **LXC Deployment:** High-speed baseline install using community scripts.
3. **iGPU Passthrough:** Walkthrough of `/dev/dri` mapping for HW acceleration.
4. **The Modular Fork:** Inform the viewer: 'Standard users can stop here. Architects follow me for the split-storage path.'
5. **The Split-Storage Implementation:** Resolving GitHub Discussion #5075. Logic: Thumbs/DB on NVMe, Assets on TrueNAS SMB.
6. **Permission Resolution:** Finalizing UID/GID mapping for unprivileged containers.
7. **Validation:** The 'Aha' moment in the Immich UI showing the multi-terabyte NAS capacity.
8. **The Transactional CTA:** Use this exact line: **'If this storage architecture saved you from a disk-full error, consider subscribing. We’re just getting started with the Homelab series.'**
9. **The Signature Outro:** - 'Thanks for watching.'
* **[Visual: Obligatory Neofetch on the workstation or the new Immich LXC]**
* 'Stay technical. See you next time.'



**Visual Requirements:**

* Distinguish between Terminal (Kitty/SSH), Proxmox UI, and Immich Dashboard.
* Graphic overlay showing the 'Split-Storage' flow (Local NVMe ↔ TrueNAS).
* Clear 'Before and After' shot of the Immich Storage Statistics."

---

### **Final Production Tip:**

When you run the **Neofetch** at the end, make sure the terminal window is clean and positioned according to your **Hyprland** layout. It should feel like a "system check" before you sign off.

**Since this is Episode 01, would you like me to generate a set of 'Keywords/Tags' specifically for the Homelab playlist to help the YouTube algorithm categorize your new series?**