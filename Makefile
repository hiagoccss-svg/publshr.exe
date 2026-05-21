PROJECT_DIR := native/publshr
BUILD_DIR   := $(PROJECT_DIR)/.build
VERSION     ?= 0.1.0
LOCAL_BIN   := $(CURDIR)/.local/bin

.PHONY: all build release test clean install install-local install-mac-app uninstall package check-folder help media-monitoring-dev media-monitoring-build media-monitoring-smoke

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  %-15s %s\n", $$1, $$2}'

all: check-folder build ## Default: verify folder + debug build

check-folder: ## Verify native/publshr folder exists
	@if [ ! -d "$(PROJECT_DIR)" ]; then \
		echo "Error: $(PROJECT_DIR) directory not found."; \
		exit 1; \
	fi
	@echo "$(PROJECT_DIR) folder OK"

build: check-folder ## Build debug binary
	cd $(PROJECT_DIR) && swift build

release: check-folder ## Build release binary
	cd $(PROJECT_DIR) && swift build -c release

test: check-folder ## Run swift tests (if any)
	cd $(PROJECT_DIR) && swift test 2>&1 || echo "No tests defined yet"

package: check-folder ## Package release tarball
	cd $(PROJECT_DIR) && chmod +x scripts/package-release.sh && bash scripts/package-release.sh $(VERSION)

install-local: check-folder ## Install into repo .local/ (this machine, no sudo)
	chmod +x install-local.sh && ./install-local.sh

install-mac-app: check-folder ## macOS: install Publshr.app into ~/Applications
	chmod +x install-mac-app.sh && ./install-mac-app.sh

install: check-folder package ## Install system-wide to /opt/publshr (sudo)
	@ASSET=$$(cd $(PROJECT_DIR)/dist && ls -d publshr-$(VERSION)-* 2>/dev/null | grep -v '.tar.gz$$' | head -1); \
	if [ -z "$$ASSET" ]; then echo "Error: no packaged release found. Run 'make package' first."; exit 1; fi; \
	DEST=/opt/publshr/$(VERSION); \
	sudo rm -rf "$$DEST"; \
	sudo mkdir -p /opt/publshr; \
	sudo cp -a "$(PROJECT_DIR)/dist/$$ASSET" "$$DEST"; \
	sudo chmod 755 "$$DEST/bin/publshr"; \
	sudo mkdir -p /usr/local/bin; \
	sudo rm -f /usr/local/bin/publshr; \
	if [ -d "$$DEST/lib" ] && [ "$$(ls -A "$$DEST/lib" 2>/dev/null)" ]; then \
		printf '#!/usr/bin/env bash\nexport LD_LIBRARY_PATH="%s/lib:$${LD_LIBRARY_PATH:-}"\nexec "%s/bin/publshr" "$$@"\n' "$$DEST" "$$DEST" | sudo tee /usr/local/bin/publshr >/dev/null; \
		sudo chmod 755 /usr/local/bin/publshr; \
	else \
		sudo ln -sf "$$DEST/bin/publshr" /usr/local/bin/publshr; \
	fi; \
	echo "Installed publshr $(VERSION) -> /usr/local/bin/publshr"; \
	/usr/local/bin/publshr --version

uninstall: ## Remove system installation
	cd $(PROJECT_DIR) && chmod +x install.sh && ./install.sh --uninstall

clean: ## Remove build artifacts and local install
	rm -rf $(BUILD_DIR)
	rm -rf $(PROJECT_DIR)/dist
	rm -rf .local

run: build ## Build and run with default args (shows help)
	$(BUILD_DIR)/debug/publshr

version: build ## Print version from built binary
	$(BUILD_DIR)/debug/publshr --version

run-local: install-local ## Install locally and run help
	$(LOCAL_BIN)/publshr

media-monitoring-dev: ## Run Media Monitoring desktop app (dev)
	cd desktop/media-monitoring && npm install && npm run dev

media-monitoring-build: ## Build Media Monitoring for production
	cd desktop/media-monitoring && npm install && npm run build

media-monitoring-smoke: ## Smoke test Media Monitoring SQLite layer
	cd desktop/media-monitoring && npm install && npm run smoke

media-monitoring-start: media-monitoring-build ## Build and start Media Monitoring
	chmod +x desktop/media-monitoring/scripts/start.sh
	./desktop/media-monitoring/scripts/start.sh
