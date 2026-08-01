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
	@echo "Note: full package/session/theme targets land in later PRs."

# --- Planned (stubs return a clear message until implemented) ---

bootstrap: ## Run repository wiring (repos-only; full bootstrap lands PR3+)
	@./bootstrap/bootstrap.sh --repos-only

repos-dry-run: ## Dry-run third-party repo wiring (no root)
	@./bootstrap/repos.sh --dry-run

build-suckless: ## Build and install dwm/st/dmenu to ~/.local (PR4)
	@echo "Not implemented yet (PR4). See suckless/ and bootstrap/build-suckless.sh."
	@exit 1

install-dotfiles: ## Install config/ session files (PR5)
	@echo "Not implemented yet (PR5). See bootstrap/install-dotfiles.sh."
	@exit 1

theme-list: ## List themes (PR8)
	@echo "Not implemented yet (PR8). See bin/voidwolf-theme."
	@exit 1

test: ## Run tests/ checks
	@./tests/repos-pins-validate.sh
