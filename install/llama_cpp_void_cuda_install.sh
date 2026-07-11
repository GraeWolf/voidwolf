#!/usr/bin/env bash
#
# Script created using Grok build.
#
# llama.cpp Installer for Void Linux + NVIDIA CUDA
# Builds from source with CUDA acceleration, HTTPS support (OpenSSL),
# and includes llama-server target.
#
# Usage:
#   chmod +x llama_cpp_void_cuda_install.sh
#   ./llama_cpp_void_cuda_install.sh
#
# After running:
#   - CUDA must be installed separately first (runfile recommended)
#   - Edit the example service with your actual model path
#   - Enable the service for persistence across suspend/reboot
#
# Notes:
#   - Assumes you have NVIDIA drivers (DKMS) already working (nvidia-smi works)
#   - No ASUS G15-specific suspend hooks included (per your request)
#   - Uses --sleep-idle-seconds in example service for efficient suspend behavior
#   - HTTPS enabled via -DLLAMA_OPENSSL=ON

set -euo pipefail

echo "=========================================="
echo "  llama.cpp Installer - Void Linux + CUDA"
echo "=========================================="

# ============================================
# 1. Install Build Prerequisites
# ============================================
echo ""
echo "[1/6] Installing build dependencies via xbps..."

sudo xbps-install -Sy \
    git \
    cmake \
    ninja \
    openssl-devel \
    pkg-config \
    gcc \
    libstdc++-devel \
    make

echo "Build dependencies installed."

# ============================================
# 2. Install CUDA Toolkit (using provided runfile)
# ============================================
echo ""
echo "[2/6] Installing CUDA Toolkit 13.3.1 from official runfile..."

CUDA_RUNFILE="cuda_13.3.1_610.43.02_linux.run"
CUDA_URL="https://developer.download.nvidia.com/compute/cuda/13.3.1/local_installers/${CUDA_RUNFILE}"

if [ ! -f "$CUDA_RUNFILE" ]; then
    echo "Downloading CUDA runfile (~4-5 GB - this will take time depending on your connection)..."
    wget --continue --progress=bar:force "$CUDA_URL" -O "$CUDA_RUNFILE"
else
    echo "CUDA runfile already present. Skipping download."
fi

# Basic integrity check (MD5 from NVIDIA docs for similar releases)
echo "Computing MD5 checksum for verification..."
COMPUTED_MD5=$(md5sum "$CUDA_RUNFILE" | awk '{print $1}')
echo "MD5: $COMPUTED_MD5"
echo "You can compare this against NVIDIA's published checksums (see md5sum.txt link you provided)."

echo ""
echo "Running CUDA installer (toolkit only, silent mode)..."
echo "WARNING: This requires root, may take 10-20 minutes, and assumes your NVIDIA driver is compatible."
echo "It installs to /usr/local/cuda by default and skips the driver."

sudo sh "$CUDA_RUNFILE" --toolkit --silent || {
    echo "Installer encountered an issue (or requires interaction)."
    echo "Try running it manually for more control:"
    echo "  sudo sh $CUDA_RUNFILE --toolkit"
    echo "Then re-run this script."
    exit 1
}

echo "CUDA Toolkit installed successfully!"

# Quick sanity check
if ! command -v nvidia-smi >/dev/null 2>&1; then
    echo "WARNING: nvidia-smi not found. Make sure NVIDIA drivers are properly installed."
fi

# ============================================
# 3. Set up Persistent CUDA Environment
# ============================================
echo ""
echo "[3/6] Setting up persistent CUDA environment variables..."

CUDA_ENV_FILE="/etc/profile.d/cuda.sh"

sudo tee "$CUDA_ENV_FILE" > /dev/null << 'EOF'
# CUDA environment for llama.cpp and other tools
export PATH="/usr/local/cuda/bin:${PATH}"
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH:-}"
EOF

echo "Created $CUDA_ENV_FILE"
echo "Log out and back in (or source it) for changes to take effect in new shells."

# Apply immediately for this script
export PATH="/usr/local/cuda/bin:${PATH}"
export LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH:-}"

# ============================================
# 4. Clone or Update llama.cpp
# ============================================
echo ""
echo "[4/6] Preparing llama.cpp source..."

LLAMA_DIR="${HOME}/llama.cpp"

if [ -d "$LLAMA_DIR" ]; then
    echo "Existing directory found. Updating..."
    cd "$LLAMA_DIR"
    git fetch --all
    git pull --rebase || true
else
    echo "Cloning fresh repository..."
    git clone https://github.com/ggml-org/llama.cpp "$LLAMA_DIR"
    cd "$LLAMA_DIR"
fi

echo "Source ready at $LLAMA_DIR"

# ============================================
# 5. Build with CUDA + HTTPS + Server
# ============================================
echo ""
echo "[5/6] Building llama.cpp with CUDA, OpenSSL (HTTPS), and llama-server..."

cd "$LLAMA_DIR"

# Clean previous build
rm -rf build
mkdir -p build
cd build

cmake .. \
    -DGGML_CUDA=ON \
    -DCMAKE_CUDA_ARCHITECTURES="native" \
    -DLLAMA_OPENSSL=ON \
    -DLLAMA_BUILD_SERVER=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -G Ninja

echo "Configuring done. Starting build (this may take a while)..."

ninja -j"$(nproc)"

echo ""
echo "Build completed successfully!"
echo ""
echo "Binaries are located in:"
echo "  $LLAMA_DIR/build/bin/"
echo ""
echo "Key binaries:"
echo "  - llama-cli     (command line inference)"
echo "  - llama-server  (HTTP/OpenAI-compatible server with CUDA + HTTPS support)"

# ============================================
# 6. Create Example Service for Persistence
# ============================================
echo ""
echo "[6/6] Creating example runit service for persistence across suspend/reboot..."

SERVICE_NAME="llama-server"
SERVICE_DIR="/etc/sv/${SERVICE_NAME}"
RUN_SCRIPT="${SERVICE_DIR}/run"

sudo mkdir -p "$SERVICE_DIR"

# Create the run script (user must edit MODEL_PATH)
sudo tee "$RUN_SCRIPT" > /dev/null << 'RUNSCRIPT'
#!/bin/sh
exec 2>&1

# ============================================
# EDIT THESE PATHS FOR YOUR SETUP
# ============================================
LLAMA_DIR="$HOME/llama.cpp"
MODEL_PATH="/path/to/your/model.gguf"          # <--- CHANGE THIS to your GGUF model
PORT=8080
CONTEXT_SIZE=8192
GPU_LAYERS=99                                  # Adjust based on your VRAM

cd "$LLAMA_DIR/build"

exec ./bin/llama-server \
    -m "$MODEL_PATH" \
    --host 0.0.0.0 \
    --port "$PORT" \
    -ngl "$GPU_LAYERS" \
    -c "$CONTEXT_SIZE" \
    --sleep-idle-seconds 600 \                 # Unloads model after 10 min idle (saves VRAM/power, helps with suspend)
    --jinja                                      # Enable Jinja2 templating (recommended)
RUNSCRIPT

sudo chmod +x "$RUN_SCRIPT"

echo "Example runit service created at: $SERVICE_DIR"
echo ""
echo "To enable and start the service:"
echo "  sudo ln -s $SERVICE_DIR /var/service/"
echo "  sudo sv up $SERVICE_NAME"
echo ""
echo "Check status:"
echo "  sudo sv status $SERVICE_NAME"
echo ""
echo "View logs:"
echo "  sudo svlogtail $SERVICE_NAME   # or check /var/log/sv/$SERVICE_NAME/"
echo ""
echo "To stop/disable:"
echo "  sudo sv down $SERVICE_NAME"
echo "  sudo rm /var/service/$SERVICE_NAME"

# ============================================
# Final Instructions
# ============================================
echo ""
echo "=========================================="
echo "           INSTALLATION COMPLETE"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Log out and back in so CUDA environment variables take effect."
echo ""
echo "2. Edit the service file and set your actual model path:"
echo "   sudo nano $RUN_SCRIPT"
echo ""
echo "3. Enable the service (recommended for persistence through suspend):"
echo "   sudo ln -s $SERVICE_DIR /var/service/"
echo "   sudo sv up $SERVICE_NAME"
echo ""
echo "4. Test the server:"
echo "   curl http://localhost:8080/health"
echo ""
echo "5. For HTTPS on the server, add these flags to the Exec line:"
echo "   --ssl-cert /path/to/cert.pem --ssl-key /path/to/key.pem"
echo ""
echo "6. For better conversation persistence across restarts:"
echo "   Add --slot-save-path /path/to/slot_cache to the server command"
echo ""
echo "The --sleep-idle-seconds flag helps the server behave well during"
echo "system suspend by unloading the model from GPU when idle."
echo ""
echo "Enjoy your local LLM server with CUDA acceleration!"
echo ""
