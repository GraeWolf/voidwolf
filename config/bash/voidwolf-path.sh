# voidwolf PATH — source from ~/.bashrc via install-dotfiles (PR5/PR12)
# User-local suckless + voidwolf helpers must win over system packages.
# Safe to source multiple times.

# Prefer ~/.local/bin first without duplicating entries
_vw_prepend_path() {
	case ":${PATH}:" in
		*:"$1":*) ;;
		*) PATH="$1${PATH:+:$PATH}" ;;
	esac
}

_vw_prepend_path "${HOME}/.local/bin"
export PATH
unset -f _vw_prepend_path
