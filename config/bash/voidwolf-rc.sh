# voidwolf interactive bash defaults (PR12)
# Sourced from ~/.bashrc after voidwolf-path.sh. Not a full bashrc replacement.
# Marker: voidwolf-bash-rc-v1

# Only interactive shells
case "$-" in
	*i*) ;;
	*) return 0 2>/dev/null || exit 0 ;;
esac

# --- history ---
export HISTSIZE=50000
export HISTFILESIZE=100000
export HISTCONTROL=ignoreboth:erasedups
export HISTTIMEFORMAT='%F %T '
# Append history; reload on prompt so multiple terminals share
shopt -s histappend 2>/dev/null || true
shopt -s checkwinsize 2>/dev/null || true
shopt -s cmdhist 2>/dev/null || true

# --- editor ---
export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-$EDITOR}"
export PAGER="${PAGER:-less}"
export LESS="${LESS:--R}"

# --- voidwolf nvim config (NVIM_APPNAME) ---
# Installs to ~/.config/voidwolf-nvim so existing ~/.config/nvim is never clobbered.
if [[ -z "${NVIM_APPNAME:-}" && -f "${HOME}/.config/voidwolf-nvim/init.lua" ]]; then
	export NVIM_APPNAME=voidwolf-nvim
fi

# --- completion ---
if [[ -z "${BASH_COMPLETION_VERSINFO:-}" ]]; then
	if [[ -f /usr/share/bash-completion/bash_completion ]]; then
		# shellcheck disable=SC1091
		. /usr/share/bash-completion/bash_completion
	elif [[ -f /etc/bash_completion ]]; then
		# shellcheck disable=SC1091
		. /etc/bash_completion
	fi
fi

# --- fastfetch on interactive shell start (once per login shell) ---
# Set VOIDWOLF_NO_FASTFETCH=1 to disable. Uses -l so nested interactive shells skip.
if [[ -z "${VOIDWOLF_NO_FASTFETCH:-}" && -z "${VOIDWOLF_FASTFETCH_DONE:-}" ]]; then
	if command -v fastfetch >/dev/null 2>&1; then
		fastfetch
		export VOIDWOLF_FASTFETCH_DONE=1
	fi
fi

# --- aliases (lean) ---
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias g='git'
alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias vw-theme='voidwolf-theme'
alias vw-gpu='voidwolf-gpu-check'
alias vw-dogfood='voidwolf-dogfood-check'

# --- prompt (simple; no starship dependency) ---
# Prefer a readable two-tone prompt; keep short for st.
if [[ -z "${VOIDWOLF_PROMPT_OFF:-}" ]]; then
	# shellcheck disable=SC2034
	__vw_ps1_git() {
		git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 0
		local b
		b=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null) || return 0
		printf ' [%s]' "$b"
	}
	if [[ "${TERM:-}" != "dumb" ]]; then
		PS1='\[\e[1;34m\]\u@\h\[\e[0m\]:\[\e[1;32m\]\w\[\e[0;33m\]$(__vw_ps1_git)\[\e[0m\]\$ '
	else
		PS1='\u@\h:\w\$ '
	fi
fi

# Reload history into this shell after each command (multi-terminal)
if [[ -z "${VOIDWOLF_NO_SHARED_HISTORY:-}" ]]; then
	case "${PROMPT_COMMAND:-}" in
		*'history -a; history -c; history -r'*) ;;
		*)
			PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"
			;;
	esac
fi
