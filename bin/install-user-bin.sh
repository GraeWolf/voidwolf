#!/usr/bin/env bash
# Install voidwolf helper scripts to ~/.local/bin (no sudo).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${PREFIX:-$HOME/.local}/bin"
mkdir -p "$DEST"
shopt -s nullglob
for f in "$ROOT"/bin/voidwolf-*; do
	base=$(basename "$f")
	install -m 0755 "$f" "$DEST/$base"
	echo "installed $DEST/$base"
done
echo "Ensure: export PATH=\"$DEST:\$PATH\""
