# LuaPath Makefile
# Common tasks for content development, validation, and testing

.PHONY: help validate lint test-examples test-roadmap-stages test-luajit parity check-links ci clean examples-dir extract-code toc watch version

# Configuration
LUA ?= lua5.4
LUAJIT ?= luajit
LUAC ?= luac5.4
LUA_RUNTIME ?= 5.4
LUAJIT_RUNTIME ?= luajit
EXAMPLES_DIR := examples
SCRIPTS_DIR := scripts

# Default target
help:
	@echo "LuaPath - Makefile Targets"
	@echo ""
	@echo "Validation:"
	@echo "  make validate              - Validate all code snippets (syntax check)"
	@echo "  make lint                  - Run style checks on Lua code"
	@echo "  make test-examples         - Run all example code tests"
	@echo "  make test-roadmap-stages   - Run all roadmap stage project tests"
	@echo ""
	@echo "Development:"
	@echo "  make examples-dir          - Create examples directory structure"
	@echo "  make extract-code          - Extract code blocks from markdown files"
	@echo "  make check-links           - Validate internal links"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean                 - Remove generated files"
	@echo ""
	@echo "Variables:"
	@echo "  LUA=$(LUA)          - Lua interpreter to use"
	@echo "  LUAJIT=$(LUAJIT)    - LuaJIT interpreter"
	@echo ""

# Validate all Lua code snippets in markdown files
validate:
	@echo "==> Validating code snippets..."
	@$(LUA) $(SCRIPTS_DIR)/validate.lua --all
	@echo "==> Validation complete"

# Run linting on Lua code
lint:
	@echo "==> Running linter..."
	@if command -v luacheck >/dev/null 2>&1; then \
		luacheck examples/; \
	else \
		echo "  Note: luacheck not installed. Install with: luarocks install luacheck"; \
	fi
	@if command -v stylua >/dev/null 2>&1; then \
		stylua --check examples/; \
	else \
		echo "  Note: stylua not installed. Install with: cargo install stylua"; \
	fi
	@echo "==> Lint complete"

# Test all example code
test-examples:
	@echo "==> Testing examples with $(LUA)..."
	@$(LUA) $(SCRIPTS_DIR)/test-examples.lua --interpreter "$(LUA)" --runtime "$(LUA_RUNTIME)" --root "$(EXAMPLES_DIR)"
	@echo "==> Example tests complete"

# Test all roadmap stage projects
test-roadmap-stages:
	@echo "==> Testing roadmap stages with $(LUA)..."
	@$(LUA) tests/test-roadmap-stages.lua --interpreter "$(LUA)" --root "lua-mastery-roadmap"
	@echo "==> Roadmap stage tests complete"

# Test with LuaJIT if available
test-luajit:
	@echo "==> Testing examples with LuaJIT..."
	@if command -v $(LUAJIT) >/dev/null 2>&1; then \
		$(LUAJIT) $(SCRIPTS_DIR)/test-examples.lua --interpreter "$(LUAJIT)" --runtime "$(LUAJIT_RUNTIME)" --root "$(EXAMPLES_DIR)"; \
	else \
		echo "  LuaJIT not found. Install or set LUAJIT variable."; \
		exit 1; \
	fi

# Create examples directory structure
examples-dir:
	@echo "==> Creating examples directory structure..."
	@mkdir -p $(EXAMPLES_DIR)/beginner
	@mkdir -p $(EXAMPLES_DIR)/intermediate
	@mkdir -p $(EXAMPLES_DIR)/advanced
	@mkdir -p $(EXAMPLES_DIR)/projects
	@mkdir -p $(SCRIPTS_DIR)
	@echo "==> Structure created"

# Extract code blocks from markdown files
extract-code:
	@echo "==> Extracting code blocks..."
	@$(LUA) $(SCRIPTS_DIR)/extract-code.lua en/
	@$(LUA) $(SCRIPTS_DIR)/extract-code.lua zh/
	@echo "==> Extraction complete"

# Check internal links in markdown files
check-links:
	@echo "==> Checking internal links..."
	@bash $(SCRIPTS_DIR)/check-links.sh
	@echo "==> Link check complete"

# Check EN/ZH mirrored learner content
parity:
	@echo "==> Checking EN/ZH parity..."
	@$(LUA) $(SCRIPTS_DIR)/parity.lua
	@echo "==> Parity check complete"

# Generate table of contents for chapters
toc:
	@echo "==> Generating table of contents..."
	@$(SCRIPTS_DIR)/generate-toc.lua
	@echo "==> TOC generated"

# Run all validation and tests
ci: validate lint check-links parity test-examples test-roadmap-stages
	@echo "==> CI checks complete"

# Clean generated files
clean:
	@echo "==> Cleaning..."
	@rm -rf $(EXAMPLES_DIR)/extracted
	@rm -f luac.out
	@rm -f *.out
	@find . -name "*.luac" -delete
	@echo "==> Clean complete"

# Watch mode for development (requires entr)
watch:
	@echo "==> Watching for changes..."
	@if command -v entr >/dev/null 2>&1; then \
		find en/ zh/ -name "*.md" | entr -r make validate; \
	else \
		echo "  Install entr: sudo pacman -S entr (Arch)"; \
	fi

# Print version info
version:
	@echo "LuaPath development environment"
	@echo "Lua: $$($(LUA) -v 2>&1 || echo 'not found')"
	@echo "LuaJIT: $$($(LUAJIT) -v 2>&1 || echo 'not found')"
	@echo "luacheck: $$(luacheck --version 2>&1 | head -1 || echo 'not found')"
	@echo "stylua: $$(stylua --version 2>&1 || echo 'not found')"
