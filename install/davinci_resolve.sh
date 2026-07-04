#!/usr/bin/env bash

set -euo pipefail

echo "=== Void Linux DaVinci Resolve Setup Script ==="

# Configuration
CONTAINER_NAME="resolve-nvidia"
IMAGE="quay.io/rockylinux/rockylinux:8"  # Stable for Resolve
RESOLVE_RUN_FILE=$(ls DaVinci_Resolve_*.run 2>/dev/null | head -n1 || echo "")

if [ -z "$RESOLVE_RUN_FILE" ]; then
    echo "ERROR: DaVinci_Resolve_*.run not found in current directory!"
    echo "Download it from Blackmagic Design and place it here."
    exit 1
fi

# 1. Update system and install host dependencies
echo "Updating system and installing host packages..."
sudo xbps-install -Syu
sudo xbps-install -y distrobox podman nvidia-container-toolkit lshw

# Ensure user in groups
sudo usermod -aG render,video "$(whoami)"

# 2. NVIDIA CDI Setup
echo "Setting up NVIDIA CDI..."
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
nvidia-ctk cdi list

# 3. Create Distrobox Container
echo "Creating Distrobox container with NVIDIA support..."
if distrobox list | grep -q "$CONTAINER_NAME"; then
    echo "Container exists. Removing old one..."
    distrobox rm -f "$CONTAINER_NAME"
fi

distrobox create --nvidia \
    -i "$IMAGE" \
    -n "$CONTAINER_NAME" \
    --additional-flags "--device nvidia.com/gpu=all --security-opt=label=disable" \
    -H ~/.distrobox/resolve-home

# 4. Enter container and install dependencies + Resolve
echo "Setting up inside container..."
distrobox enter "$CONTAINER_NAME" -- bash -c '
set -euo pipefail

echo "Installing dependencies inside container..."
sudo dnf install -y epel-release
sudo dnf update -y
sudo dnf install -y alsa-lib apr apr-util fontconfig freetype \
    libglvnd libglvnd-egl libglvnd-glx libglvnd-opengl librsvg2 \
    libXcursor libXfixes libXi libXinerama libxkbcommon-x11 \
    libXrandr libXrender libXtst libXxf86vm mesa-libGLU mtdev \
    pulseaudio-libs xcb-util xcb-util-image xcb-util-keysyms \
    xcb-util-renderutil xcb-util-wm fuse-libs ocl-icd glib2 pango \
    compat-libstdc++-33 libxcrypt-compat

# # NVIDIA symlink fix in .bashrc
# cat >> ~/.bashrc << "EOF"
# # NVIDIA Distrobox fix
# fix_nvidia_symlink() {
#     local link="$1" target="$2"
#     if [ ! -e "$target" ]; then return 1; fi
#     if [ ! -e "$link" ] || { [ -L "$link" ] && [ ! -e "$link" ]; } || { [ -f "$link" ] && [ ! -s "$link" ]; }; then
#         sudo rm -f "$link"
#         sudo ln -sf "$target" "$link" && NEEDS_LDCONFIG=1
#     fi
# }
# NEEDS_LDCONFIG=0
# fix_nvidia_symlink "/usr/lib64/libcuda.so" "/usr/lib64/libcuda.so.1"
# fix_nvidia_symlink "/usr/lib64/libnvcuvid.so" "/usr/lib64/libnvcuvid.so.1"
# [ "$NEEDS_LDCONFIG" = 1 ] && sudo ldconfig
# EOF
#
# source ~/.bashrc

# Copy and install Resolve
cp /run/host/home/"$(whoami)"/"$RESOLVE_RUN_FILE" ~/
chmod +x ~/"$RESOLVE_RUN_FILE"
echo "Installing DaVinci Resolve (this may take time)..."
sudo ~/"$RESOLVE_RUN_FILE" --install

echo "Setup complete inside container!"
'

echo "=== Setup Finished! ==="
echo "Launch Resolve with:"
echo "distrobox-enter $CONTAINER_NAME -- bash -c '"
echo "  export __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia QT_QPA_PLATFORM=xcb"
echo "  /opt/resolve/bin/resolve"
echo "'"

echo "Create a desktop launcher for convenience if desired."
