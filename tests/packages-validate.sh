#!/usr/bin/env bash
# Validate PR15 packaging templates and local-repo build.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG="${ROOT}/packages"
fail=0

need() {
	if [[ -e "$1" ]]; then
		echo "OK   $1"
	else
		echo "FAIL missing $1"
		fail=1
	fi
}

need_x() {
	if [[ -x "$1" ]]; then
		echo "OK   executable $(basename "$1")"
	else
		echo "FAIL not executable $1"
		fail=1
	fi
}

need "$PKG/version.conf"
need "$PKG/build-local-repo.sh"
need "$PKG/README.md"
need "$ROOT/docs/packaging.md"
need "$PKG/xbps.d/98-voidwolf-local.conf.example"
need_x "$PKG/build-local-repo.sh"

for m in voidwolf-base voidwolf-desktop voidwolf-themes voidwolf-laptop voidwolf-helpers \
	voidwolf-dwm voidwolf-st voidwolf-dmenu voidwolf-suckless; do
	need "$PKG/$m/DESCRIPTION"
done

# version.conf parseable
# shellcheck disable=SC1091
source "$PKG/version.conf"
if [[ -n "${VOIDWOLF_PKGVER:-}" && -n "${VOIDWOLF_PKGREVISION:-}" ]]; then
	echo "OK   version ${VOIDWOLF_PKGVER}_${VOIDWOLF_PKGREVISION}"
else
	echo "FAIL version.conf incomplete"
	fail=1
fi

# dry-run always
if bash "$PKG/build-local-repo.sh" --dry-run >/tmp/voidwolf-pkg-dry.$$.log 2>&1; then
	echo "OK   build-local-repo --dry-run"
else
	echo "FAIL build-local-repo --dry-run"
	cat /tmp/voidwolf-pkg-dry.$$.log || true
	fail=1
fi
rm -f /tmp/voidwolf-pkg-dry.$$.log

# real build if xbps-create present
if command -v xbps-create >/dev/null 2>&1 && command -v xbps-rindex >/dev/null 2>&1; then
	tmp_repo=$(mktemp -d)
	if VOIDWOLF_LOCAL_REPO="$tmp_repo" bash "$PKG/build-local-repo.sh" --clean >/tmp/voidwolf-pkg-build.$$.log 2>&1; then
		echo "OK   build-local-repo real build"
		n=$(find "$tmp_repo" -name 'voidwolf-*.xbps' | wc -l)
		# PR15 metas (5) + PR16 suckless (4) = 9 when full build
		if [[ "$n" -ge 9 ]]; then
			echo "OK   built $n voidwolf xbps packages"
		else
			echo "FAIL expected >=9 xbps packages (meta+suckless), got $n"
			fail=1
		fi
		if find "$tmp_repo" -name 'voidwolf-dwm-*.xbps' | grep -q . \
			&& find "$tmp_repo" -name 'voidwolf-st-*.xbps' | grep -q . \
			&& find "$tmp_repo" -name 'voidwolf-dmenu-*.xbps' | grep -q .; then
			echo "OK   suckless binary packages present"
		else
			echo "FAIL missing voidwolf-dwm/st/dmenu xbps"
			fail=1
		fi
		if [[ -f "$tmp_repo/x86_64-repodata" ]] || [[ -f "$tmp_repo/noarch-repodata" ]] || ls "$tmp_repo"/*-repodata >/dev/null 2>&1; then
			echo "OK   repodata present"
		else
			# xbps-rindex may name by arch of host
			if ls "$tmp_repo"/*repodata* >/dev/null 2>&1; then
				echo "OK   repodata present"
			else
				echo "FAIL missing repodata"
				fail=1
			fi
		fi
		# themes package should contain a known theme
		if command -v xbps-query >/dev/null 2>&1; then
			if xbps-query --repository="$tmp_repo" -f voidwolf-themes 2>/dev/null | rg -q 'usr/share/voidwolf/themes/nord.toml'; then
				echo "OK   voidwolf-themes contains nord.toml"
			else
				# -f lists files of installed pkg; for uninstalled use xbps-query -i on the xbps file
				if xbps-query -i "$tmp_repo"/voidwolf-themes-*.xbps 2>/dev/null | rg -q 'nord' \
					|| tar -tf "$tmp_repo"/voidwolf-themes-*.xbps 2>/dev/null | rg -q 'nord.toml'; then
					echo "OK   voidwolf-themes archive has nord"
				else
					# try bsdtar / xbps files
					if xbps-query --repository="$tmp_repo" -Rf voidwolf-themes 2>/dev/null | rg -q nord; then
						echo "OK   voidwolf-themes file list has nord"
					else
						echo "WARN could not list voidwolf-themes contents (non-fatal if query flags differ)"
					fi
				fi
			fi
			# bare deps break install: "can't guess pkgname for dependency 'sudo'"
			deps=$(xbps-query --repository="$tmp_repo" -p run_depends voidwolf-base 2>/dev/null || true)
			if printf '%s\n' "$deps" | rg -q 'sudo>='; then
				echo "OK   voidwolf-base deps are versioned patterns (sudo>=…)"
			else
				echo "FAIL voidwolf-base run_depends must use patterns like sudo>=0 (got: ${deps//$'\n'/ })"
				fail=1
			fi
			# dry-run resolve against real repos + local (needs network/repos configured)
			if xbps-install -n --repository="$tmp_repo" voidwolf-helpers voidwolf-suckless >/tmp/voidwolf-pkg-n.$$.log 2>&1; then
				echo "OK   xbps-install -n voidwolf-helpers+suckless resolves"
			else
				if rg -q "can't guess pkgname" /tmp/voidwolf-pkg-n.$$.log; then
					echo "FAIL deps still bare (can't guess pkgname)"
					cat /tmp/voidwolf-pkg-n.$$.log || true
					fail=1
				else
					echo "WARN xbps-install -n failed (repos/network?); not treating as fail"
					head -5 /tmp/voidwolf-pkg-n.$$.log || true
				fi
			fi
			rm -f /tmp/voidwolf-pkg-n.$$.log
		fi
	else
		echo "FAIL build-local-repo real build"
		cat /tmp/voidwolf-pkg-build.$$.log || true
		fail=1
	fi
	rm -rf "$tmp_repo" /tmp/voidwolf-pkg-build.$$.log
else
	echo "SKIP xbps-create/rindex not available"
fi

# docs mention local repo
if rg -q 'build-local-repo|voidwolf-desktop|/usr/share/voidwolf|voidwolf-dwm|voidwolf-suckless' "$ROOT/docs/packaging.md"; then
	echo "OK   packaging.md content"
else
	echo "FAIL packaging.md incomplete"
	fail=1
fi
if rg -q 'voidwolf-dwm|build_dwm' "$PKG/build-local-repo.sh"; then
	echo "OK   build script has suckless packages"
else
	echo "FAIL build-local-repo missing suckless builders"
	fail=1
fi

# gitignore build artifacts
if rg -q 'packages/repo/' "$ROOT/.gitignore" && rg -q 'packages/\.build/' "$ROOT/.gitignore"; then
	echo "OK   gitignore packages build output"
else
	echo "FAIL .gitignore should ignore packages/repo and packages/.build"
	fail=1
fi

if [[ "$fail" -ne 0 ]]; then
	echo "packages-validate: FAILED"
	exit 1
fi
echo "packages-validate: all OK"
