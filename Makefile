# voidwolf — top-level helper targets
# Implementation lands in later PRs; PR1 only documents the surface.

.PHONY: help
.DEFAULT_GOAL := help

help: ## Show available targets
	@echo "voidwolf — available make targets"
	@echo ""
	@grep -E '^[a-zA-Z0-9_-]+:.*?## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  %-18s %s\n", $$1, $$2}'
	@echo ""
	@echo "Note: hardware profiles PR11; packaging later."

# --- Planned (stubs return a clear message until implemented) ---

bootstrap: ## Print bootstrap help
	@./bootstrap/bootstrap.sh --help

repos-dry-run: ## Dry-run third-party repo wiring (no root)
	@./bootstrap/repos.sh --dry-run

bootstrap-dry-run: ## Dry-run full PR2+PR3 path (profile=desktop gpu=none)
	@./bootstrap/bootstrap.sh --profile desktop --gpu none --dry-run

build-suckless: ## Build and install dwm/st/dmenu to ~/.local (no sudo)
	@./bootstrap/build-suckless.sh
	@./bin/install-user-bin.sh

install-dotfiles: ## Install session .xinitrc, Xresources, PipeWire conf.d
	@./bootstrap/install-dotfiles.sh

theme-list: ## List themes
	@VOIDWOLF_ROOT="$(CURDIR)" ./bin/voidwolf-theme list

test: ## Run tests/ checks
	@./tests/repos-pins-validate.sh
	@./tests/package-lists-validate.sh
	@./tests/session-files-validate.sh
	@./tests/keybind-lint.sh
	@./tests/helpers-validate.sh
	@./tests/theme-schema-validate.sh
	@./tests/nvidia-helpers-validate.sh
	@./tests/bash-nvim-validate.sh
	@./tests/displays-tui-validate.sh
	@./tests/packages-validate.sh

packages-repo: ## Build local XBPS meta packages into packages/repo
	@./packages/build-local-repo.sh
