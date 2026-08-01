#!/usr/bin/env bash
# Validate PR10 NVIDIA helpers and config snippets.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0

need() {
	if [[ -f "$1" ]]; then
		echo "OK   $1"
	else
		echo "FAIL missing $1"
		fail=1
	fi
}

need "$ROOT/bin/voidwolf-gpu-check"
need "$ROOT/bin/voidwolf-prime"
need "$ROOT/bootstrap/nvidia-setup.sh"
need "$ROOT/bootstrap/nvidia-fallback-xorg.sh"
need "$ROOT/docs/nvidia.md"
need "$ROOT/config/X11/xorg.conf.d/20-nvidia-discrete.conf"
need "$ROOT/config/X11/xorg.conf.d/20-nvidia-hybrid-prime.conf"
need "$ROOT/config/X11/xorg.conf.d/20-nvidia-hybrid-randr.conf"
need "$ROOT/config/X11/modprobe.d/voidwolf-nvidia.conf"

for s in voidwolf-gpu-check voidwolf-prime; do
	if [[ -x "$ROOT/bin/$s" ]]; then
		echo "OK   executable $s"
	else
		echo "FAIL not executable $s"
		fail=1
	fi
done
for s in nvidia-setup.sh nvidia-fallback-xorg.sh; do
	if [[ -x "$ROOT/bootstrap/$s" ]]; then
		echo "OK   executable $s"
	else
		echo "FAIL not executable $s"
		fail=1
	fi
done

# gpu-check runs without root
if python3 "$ROOT/bin/voidwolf-gpu-check" --print-profile >/dev/null; then
	echo "OK   gpu-check --print-profile"
else
	echo "FAIL gpu-check --print-profile"
	fail=1
fi
if python3 "$ROOT/bin/voidwolf-gpu-check" --json | python3 -c "import sys,json; json.load(sys.stdin)"; then
	echo "OK   gpu-check --json"
else
	echo "FAIL gpu-check --json"
	fail=1
fi

# prime usage (prints to stderr, exits 1)
if out=$("$ROOT/bin/voidwolf-prime" 2>&1); then
	echo "FAIL voidwolf-prime should fail without args"
	fail=1
else
	if printf '%s' "$out" | rg -q 'Usage:'; then
		echo "OK   voidwolf-prime usage"
	else
		echo "FAIL voidwolf-prime usage: $out"
		fail=1
	fi
fi

# dry-run setup
if bash "$ROOT/bootstrap/nvidia-setup.sh" --profile nvidia --dry-run >/dev/null; then
	echo "OK   nvidia-setup dry-run discrete"
else
	echo "FAIL nvidia-setup dry-run"
	fail=1
fi
if bash "$ROOT/bootstrap/nvidia-setup.sh" --profile nvidia-hybrid --dry-run >/dev/null; then
	echo "OK   nvidia-setup dry-run hybrid"
else
	echo "FAIL nvidia-setup hybrid dry-run"
	fail=1
fi
if bash "$ROOT/bootstrap/nvidia-fallback-xorg.sh" --dry-run >/dev/null; then
	echo "OK   nvidia-fallback-xorg dry-run"
else
	echo "FAIL nvidia-fallback dry-run"
	fail=1
fi

# docs content
if rg -q 'voidwolf-prime|PRIME|nvidia-fallback|modeset' "$ROOT/docs/nvidia.md"; then
	echo "OK   docs/nvidia.md content"
else
	echo "FAIL docs/nvidia.md thin"
	fail=1
fi

# conf snippets mention Driver
if rg -q 'Driver' "$ROOT/config/X11/xorg.conf.d/20-nvidia-discrete.conf" \
	&& rg -q 'modesetting' "$ROOT/config/X11/xorg.conf.d/20-nvidia-hybrid-prime.conf"; then
	echo "OK   xorg snippets"
else
	echo "FAIL xorg snippets"
	fail=1
fi

if [[ "$fail" -ne 0 ]]; then
	echo "nvidia-helpers-validate: FAILED"
	exit 1
fi
echo "nvidia-helpers-validate: all OK"
