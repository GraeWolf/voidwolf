#!/usr/bin/env bash
# voidwolf — enable Void nonfree + third-party XBPS repos (XLibre, vw-repo)
# Fail closed on key fingerprint / SHA256 mismatch.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYS_DIR="${SCRIPT_DIR}/keys"
PINS_FILE="${KEYS_DIR}/pins.conf"
XBPS_KEYS_DIR="${XBPS_KEYS_DIR:-/var/db/xbps/keys}"
XBPS_D_DIR="${XBPS_D_DIR:-/etc/xbps.d}"

WITH_32BIT=0
SKIP_XLIBRE=0
SKIP_VW=0
SKIP_NONFREE=0
DISABLE_THIRD_PARTY=0
SYNC=1
DRY_RUN=0

usage() {
	cat <<'EOF'
Usage: repos.sh [options]

Enable official Void nonfree (and optional multilib) plus voidwolf third-party
repos (XLibre, vw-repo) with fail-closed key pins.

Options:
  --with-32bit            Also enable multilib + multilib-nonfree
  --skip-nonfree          Do not install void-repo-nonfree
  --skip-xlibre           Do not configure XLibre repo/key
  --skip-vw-repo          Do not configure vw-repo/key
  --disable-third-party   Disable XLibre + vw-repo confs (*.disabled) and sync
  --no-sync               Do not run xbps-install -S
  --dry-run               Print actions without writing (no root required)
  -h, --help              Show this help

Environment:
  XBPS_KEYS_DIR   Override key install dir (default /var/db/xbps/keys)
  XBPS_D_DIR      Override conf dir (default /etc/xbps.d)
EOF
}

log()  { printf '==> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

run_as_root() {
	if [[ "${DRY_RUN}" -eq 1 ]]; then
		printf '[dry-run] %s\n' "$*"
		return 0
	fi
	if [[ "${EUID}" -eq 0 ]]; then
		"$@"
	elif command -v sudo >/dev/null 2>&1; then
		sudo "$@"
	else
		die "root or sudo required to run: $*"
	fi
}

sha256_file() {
	local f="$1"
	if command -v sha256sum >/dev/null 2>&1; then
		sha256sum "$f" | awk '{print $1}'
	elif command -v shasum >/dev/null 2>&1; then
		shasum -a 256 "$f" | awk '{print $1}'
	else
		die "need sha256sum or shasum to verify key pins"
	fi
}

assert_file_sha256() {
	local f="$1" expected="$2" label="$3"
	[[ -f "$f" ]] || die "missing key file for ${label}: $f"
	local got
	got="$(sha256_file "$f")"
	if [[ "${got}" != "${expected}" ]]; then
		die "SHA256 mismatch for ${label} key (fail closed)
  file:     ${f}
  expected: ${expected}
  got:      ${got}
Refusing to install untrusted key material."
	fi
}

install_key_plist() {
	local src="$1" fp="$2" expected_sha="$3" label="$4"
	assert_file_sha256 "$src" "$expected_sha" "$label"

	local base
	base="$(basename "$src")"
	[[ "${base}" == "${fp}.plist" ]] || die "${label}: filename ${base} does not match fingerprint ${fp}.plist"

	local dest="${XBPS_KEYS_DIR}/${fp}.plist"
	log "Install ${label} key → ${dest}"
	if [[ "${DRY_RUN}" -eq 1 ]]; then
		printf '[dry-run] install key %s\n' "$dest"
		return 0
	fi
	run_as_root mkdir -p "${XBPS_KEYS_DIR}"
	run_as_root install -m 0644 "$src" "$dest"
}

write_repo_conf() {
	local conf_path="$1" url="$2" label="$3"
	log "Write ${label} repo conf → ${conf_path}"
	if [[ "${DRY_RUN}" -eq 1 ]]; then
		printf '[dry-run] repository=%s > %s\n' "$url" "$conf_path"
		return 0
	fi
	run_as_root mkdir -p "${XBPS_D_DIR}"
	# shellcheck disable=SC2024
	printf 'repository=%s\n' "$url" | run_as_root tee "$conf_path" >/dev/null
}

disable_conf() {
	local conf="$1"
	if [[ -f "$conf" ]]; then
		log "Disable ${conf} → ${conf}.disabled"
		run_as_root mv -f "$conf" "${conf}.disabled"
	elif [[ -f "${conf}.disabled" ]]; then
		log "Already disabled: ${conf}.disabled"
	else
		warn "no conf to disable: ${conf}"
	fi
}

require_void_or_warn() {
	if [[ ! -f /etc/os-release ]]; then
		warn "cannot read /etc/os-release"
		return 0
	fi
	# shellcheck disable=SC1091
	. /etc/os-release
	if [[ "${ID:-}" != "void" ]]; then
		if [[ "${DRY_RUN}" -eq 1 ]]; then
			warn "not Void (ID=${ID:-unknown}); dry-run continues"
		else
			die "this script targets Void Linux (ID=void), got ID=${ID:-unknown}"
		fi
	fi
}

enable_nonfree() {
	log "Enable official nonfree (void-repo-nonfree — mirror-aware)"
	if [[ "${DRY_RUN}" -eq 1 ]]; then
		printf '[dry-run] xbps-install -y void-repo-nonfree\n'
		return 0
	fi
	if xbps-query -R void-repo-nonfree >/dev/null 2>&1 || \
	   xbps-query void-repo-nonfree >/dev/null 2>&1; then
		# Package may already be installed; still ensure present
		run_as_root xbps-install -y void-repo-nonfree || true
	else
		run_as_root xbps-install -y void-repo-nonfree
	fi
}

enable_multilib() {
	log "Enable multilib + multilib-nonfree (--with-32bit)"
	if [[ "${DRY_RUN}" -eq 1 ]]; then
		printf '[dry-run] xbps-install -y void-repo-multilib void-repo-multilib-nonfree\n'
		return 0
	fi
	run_as_root xbps-install -y void-repo-multilib void-repo-multilib-nonfree
}

sync_repos() {
	log "Sync package indexes (xbps-install -S)"
	if [[ "${DRY_RUN}" -eq 1 ]]; then
		printf '[dry-run] xbps-install -S\n'
		return 0
	fi
	# Keys are pre-installed; non-interactive sync should not prompt
	run_as_root xbps-install -S
}

# --- parse args ---
while [[ $# -gt 0 ]]; do
	case "$1" in
		--with-32bit) WITH_32BIT=1 ;;
		--skip-nonfree) SKIP_NONFREE=1 ;;
		--skip-xlibre) SKIP_XLIBRE=1 ;;
		--skip-vw-repo) SKIP_VW=1 ;;
		--disable-third-party) DISABLE_THIRD_PARTY=1 ;;
		--no-sync) SYNC=0 ;;
		--dry-run) DRY_RUN=1 ;;
		-h|--help) usage; exit 0 ;;
		*) die "unknown option: $1 (try --help)" ;;
	esac
	shift
done

[[ -f "${PINS_FILE}" ]] || die "missing pins file: ${PINS_FILE}"
# shellcheck disable=SC1090
source "${PINS_FILE}"

: "${XLIBRE_KEY_FP:?}" "${XLIBRE_KEY_SHA256:?}" "${XLIBRE_KEY_FILE:?}"
: "${XLIBRE_REPO_URL:?}" "${XLIBRE_CONF:?}"
: "${VW_KEY_FP:?}" "${VW_KEY_SHA256:?}" "${VW_KEY_FILE:?}"
: "${VW_REPO_URL:?}" "${VW_CONF:?}"

require_void_or_warn

if [[ "${DISABLE_THIRD_PARTY}" -eq 1 ]]; then
	log "Disabling third-party repos (rollback)"
	disable_conf "${XLIBRE_CONF}"
	disable_conf "${VW_CONF}"
	if [[ "${SYNC}" -eq 1 ]]; then
		sync_repos
	fi
	log "Third-party repos disabled."
	exit 0
fi

if [[ "${SKIP_NONFREE}" -eq 0 ]]; then
	enable_nonfree
else
	log "Skipping void-repo-nonfree"
fi

if [[ "${WITH_32BIT}" -eq 1 ]]; then
	enable_multilib
fi

if [[ "${SKIP_XLIBRE}" -eq 0 ]]; then
	install_key_plist \
		"${KEYS_DIR}/${XLIBRE_KEY_FILE}" \
		"${XLIBRE_KEY_FP}" \
		"${XLIBRE_KEY_SHA256}" \
		"XLibre"
	write_repo_conf "${XLIBRE_CONF}" "${XLIBRE_REPO_URL}" "XLibre"
else
	log "Skipping XLibre repo"
fi

if [[ "${SKIP_VW}" -eq 0 ]]; then
	install_key_plist \
		"${KEYS_DIR}/${VW_KEY_FILE}" \
		"${VW_KEY_FP}" \
		"${VW_KEY_SHA256}" \
		"vw-repo"
	write_repo_conf "${VW_CONF}" "${VW_REPO_URL}" "vw-repo"
else
	log "Skipping vw-repo"
fi

if [[ "${SYNC}" -eq 1 ]]; then
	sync_repos
fi

log "Repository wiring complete."
if [[ "${DRY_RUN}" -eq 0 ]]; then
	log "Next: install packages (PR3) or query: xbps-query -Rs xlibre ; xbps-query -Rs brave-origin"
fi
