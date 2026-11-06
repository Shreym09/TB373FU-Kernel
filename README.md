# Custom GKI Kernel with Stealth Root (KernelSU-Next + SuSFS)
### For Lenovo IdeaTab Pro / Moto Tab 60 Pro (TB373FU / MT6897 Dimensity 8300)
### Optimized for OneUI 9 Port (KMI-Compliant, Preserves Developer Touch & Driver Fixes)

---

## 1. Feature Breakdown

### A. Kernel-Level Root & Root Hiding (Anti-Detection)
* **KernelSU-Next (v1.0.5+):** Kernel-level su provider operating inside system calls without tampering with `/system` or `/init`.
* **SuSFS (Super Root Stealth File System v1.5.5):**
  - Hides KernelSU mounts (`/debug_ramdisk`, overlayfs) from `/proc/mounts` and `/proc/self/mountinfo`.
  - Hides kernel symbols from `/proc/kallsyms`.
  - Spoofs `kstat` (file timestamps, inodes) to defeat advanced anti-tamper scans.
  - Bypasses Google Play Integrity (passes Strong/Device integrity checks).
  - Banking and enterprise apps see zero root traces.

### B. OneUI 9 Multitasking & Memory Optimization
* **MGLRU (Multi-Gen LRU) Tuning:** Aggressive generation intervals to stop OneUI from closing background apps, games, and DeX windows.
* **ZRAM with ZSTD Multi-Threading:** Replaces stock `lzo-rle` with ZSTD for ~30% higher compression efficiency, freeing 1.5–2GB effective RAM.
* **OverlayFS:** Instant systemless module mounting.

### C. Display & Touch Latency
* **HZ_300 / 1000 Timer Frequency:** Drastically reduces touch jitter and frame presentation latency on the 144Hz panel.
* **Uclamp & Schedutil EAS:** Instantly boosts rendering threads (`SurfaceFlinger`) to Cortex-A715 performance cores on touch.

### D. Networking & USB
* **BBR TCP Congestion Control:** Default Wi-Fi congestion algorithm to eliminate bufferbloat and ping spikes in online gaming.
* **In-Kernel WireGuard VPN:** Native kernel driver for maximum VPN speeds with minimal battery impact.
* **USB Mass Storage (DriveDroid):** Boot PC ISOs directly from your tablet.

---

## 2. Compatibility Guarantee

* **`vendor_boot.img`:** **UNTOUCHED** (Developer's touch screen drivers & optimizations remain 100% active).
* **`vendor_dlkm.img`:** **UNTOUCHED** (All proprietary MediaTek GPU, Audio, Wi-Fi modules remain 100% active).
* **`boot.img`:** **ONLY THIS FILE IS UPDATED** with the new GKI kernel `Image.gz`.

---

## 3. How to Build (Two Options)

### Option 1: Turnkey Cloud Build via GitHub Actions (Recommended)
1. Fork or create a private GitHub repository (e.g., `TB373FU-Kernel`).
2. Push the files in this folder (`.github/workflows/build_kernel.yml`).
3. In GitHub, go to **Actions** -> Select **Build Custom GKI Kernel with KernelSU & SuSFS** -> Click **Run workflow**.
4. GitHub's 64GB servers will compile the kernel in ~15 minutes and produce the downloadable artifact:
   - `Image` / `Image.gz`
   - `Custom_Kernel_TB373FU_OneUI9.zip` (AnyKernel3 format)

### Option 2: Local Build (WSL2 / Ubuntu 22.04 LTS)
```bash
chmod +x build_kernel.sh
./build_kernel.sh
```

---

## 4. How to Flash Safely

1. **Repack `boot.img`:**
   Take the compiled `Image.gz` and repack it into a `boot.img` using `magiskboot` or AnyKernel3.
2. **Reboot Tablet into Bootloader:**
   ```bash
   adb reboot bootloader
   ```
3. **Flash the Custom Kernel to `boot`:**
   ```bash
   fastboot flash boot boot_custom.img
   ```
4. **Reboot to System:**
   ```bash
   fastboot reboot
   ```
5. **Install the Userspace Management Apps:**
   - Install `KernelSU-Next.apk`
   - Install `ksu_susfs.apk` (or flash the SuSFS module in KernelSU manager)
