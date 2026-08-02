# voidwolf bash aliases (PR12+)
# Sourced from voidwolf-rc.sh (interactive). Installed to ~/.config/voidwolf/
# Marker: voidwolf-bash-aliases-v1

# Only interactive shells
case "$-" in
	*i*) ;;
	*) return 0 2>/dev/null || exit 0 ;;
esac

# Set VOIDWOLF_NO_ALIASES=1 to skip
if [[ -n "${VOIDWOLF_NO_ALIASES:-}" ]]; then
	return 0 2>/dev/null || exit 0
fi

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

# Voidwolf repo
alias vw='cd ~/Projects/repos/voidwolf'
