#!/usr/bin/env bash
# Local Kernel Build Script for Lenovo TB373FU / MT6897 (Dimensity 8300)
# Base: Linux 6.1 GKI (Android Common Kernel android14-6.1)
# Features: KernelSU-Next, SuSFS (Stealth), MGLRU, ZSTD ZRAM, BBR, WireGuard, HZ_300

set -euo pipefail

WORKDIR="${KERNEL_WORKDIR:-$HOME/ack-6.1}"
BRANCH="common-android14-6.1"

echo "=== 1. Checking Environment ==="
if [ "$(uname -s)" != "Linux" ]; then
  echo "ERROR: This build script requires Linux (Ubuntu 22.04 or WSL2)."
  exit 1
fi

for cmd in repo git curl python3 bc bison flex lz4; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing command: $cmd. Run: sudo apt install -y git curl python3 bc bison flex lz4"
    exit 1
  fi
done

echo "=== 2. Initializing & Syncing ACK 6.1 Source ==="
mkdir -p "$WORKDIR"
cd "$WORKDIR"

if [ ! -d ".repo" ]; then
  repo init -u https://android.googlesource.com/kernel/manifest -b "$BRANCH" --depth=1
  repo sync -c -j"$(nproc)" --no-tags --no-clone-bundle
fi

echo "=== 3. Integrating KernelSU-Next & SuSFS ==="
cd "$WORKDIR/common"

if [ ! -d "KernelSU-Next" ]; then
  curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -s next
fi

if [ ! -d "$HOME/susfs" ]; then
  git clone https://gitlab.com/simonpunk/susfs4ksu.git -b gki-android14-6.1 "$HOME/susfs"
  cp "$HOME/susfs/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch" ./KernelSU-Next/
  cp "$HOME/susfs/kernel_patches/fs/"* ./fs/
  cp "$HOME/susfs/kernel_patches/include/linux/"* ./include/linux/
  
  cd KernelSU-Next
  patch -p1 < 10_enable_susfs_for_ksu.patch || true
  cd ..
  
  cp "$HOME/susfs/kernel_patches/50_add_susfs_in_gki-android14-6.1.patch" ./
  patch -p1 < 50_add_susfs_in_gki-android14-6.1.patch || true
fi

echo "=== 4. Applying Kernel Feature Configurations ==="
scripts/config --file arch/arm64/configs/gki_defconfig \
  -e KSU \
  -e KSU_SUSFS \
  -e KSU_SUSFS_SUS_PATH \
  -e KSU_SUSFS_SUS_MOUNT \
  -e KSU_SUSFS_AUTO_ADD_SUS_KSU_DEFAULT_MOUNT \
  -e KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT \
  -e KSU_SUSFS_SUS_KSTAT \
  -e KSU_SUSFS_SUS_OVERLAYFS \
  -e KSU_SUSFS_TRY_UMOUNT \
  -e KSU_SUSFS_SPOOF_UNAME \
  -e KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS \
  -e KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG \
  -d KSU_SUSFS_ENABLE_LOG \
  -e KPROBES \
  -e HAVE_KPROBES \
  -e LRU_GEN \
  -e LRU_GEN_ENABLED \
  -e ZRAM_DEF_COMP_ZSTD \
  --set-str ZRAM_DEF_COMP "zstd" \
  -e OVERLAY_FS \
  -e OVERLAY_FS_REDIRECT_ALWAYS_FOLLOW \
  -e HZ_300 \
  --set-val HZ 300 \
  -e TCP_CONG_BBR \
  --set-str DEFAULT_TCP_CONG "bbr" \
  -e WIREGUARD \
  -e USB_CONFIGFS_MASS_STORAGE

echo "=== 5. Compiling Kernel (Bazel / Kleaf) ==="
cd "$WORKDIR"
LTO=thin tools/bazel run --config=fast //common:kernel_aarch64_dist

echo "=== 6. Packaging Kernel Artifacts ==="
OUTDIR="$WORKDIR/out/kernel_aarch64/dist"
if [ -f "$OUTDIR/Image" ]; then
  gzip -n -k -f -9 "$OUTDIR/Image" > "$OUTDIR/Image.gz"
  echo "Kernel build SUCCESS! Output:"
  echo "  Uncompressed: $OUTDIR/Image"
  echo "  Gzip:         $OUTDIR/Image.gz"
else
  echo "Build failed - Image not found."
  exit 1
fi
