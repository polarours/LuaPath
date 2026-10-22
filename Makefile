# LuaPath Makefile
# Common tasks for content development, validation, and testing

.PHONY: help validate validate-51 lint test-examples test-roadmap-stages test-version-facts test-lua51 test-luajit parity check-links check-chapters check-stage-refs check-code-mirror check-stage-files check-pitfall-examples check-stdlib-names check-capi-names ci ci-matrix clean examples-dir extract-code toc watch version

# Configuration
LUA ?= lua5.4
LUAJIT ?= luajit
LUAC ?= luac5.4
LUACHECK ?= luacheck
LUA_RUNTIME ?= 5.4
LUAJIT_RUNTIME ?= luajit
LUA51 ?= lua5.1
LUA51_RUNTIME ?= 5.1
EXAMPLES_DIR := examples
SCRIPTS_DIR := scripts
ROADMAP_DIR := lua-mastery-roadmap
# Paths covered by `make lint`.
LINT_PATHS := $(EXAMPLES_DIR) $(SCRIPTS_DIR) tests $(ROADMAP_DIR)
# Directories whose markdown is scanned for links and anchors.
LINK_DIRS := en zh $(ROADMAP_DIR) pitfalls/en pitfalls/中文版 references

# Default target
help:
	@echo "LuaPath - Makefile Targets"
	@echo ""
	@echo "Validation:"
	@echo "  make validate              - Validate all code snippets (syntax check)"
	@echo "  make validate-51           - Validate snippets against the Lua 5.1 baseline"
	@echo "  make lint                  - Run style checks on Lua code"
	@echo "  make test-examples         - Run all example code tests"
	@echo "  make test-roadmap-stages   - Run all roadmap stage project tests"
	@echo ""
	@echo "Cross-version:"
	@echo "  make test-lua51            - Run examples + stages on Lua 5.1 (oldest baseline)"
	@echo "  make test-luajit           - Run examples + stages on LuaJIT"
	@echo "  make ci-matrix             - Full CI: 5.4 baseline plus 5.1 and LuaJIT"
	@echo ""
	@echo "Development:"
	@echo "  make examples-dir          - Create examples directory structure"
	@echo "  make extract-code          - Extract code blocks from markdown files"
	@echo "  make check-links           - Validate internal links"
	@echo "  make check-chapters        - Verify example Chapter: headers resolve"
	@echo "  make check-stage-refs      - Verify Stage/Chapter references resolve"
	@echo "  make check-code-mirror     - Verify EN/ZH code samples are the same code"
	@echo "  make check-stage-files     - Verify stage READMEs name files that exist"
	@echo "  make check-pitfall-examples - Run the code samples in the pitfall articles"
	@echo "  make check-stdlib-names  - Verify the stdlib members the docs name exist"
	@echo "  make check-capi-names    - Verify the C API functions the docs name exist"
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

# Validate the snippets against the oldest supported baseline. A snippet that
# needs a newer Lua is fine as long as it says so: the validator skips the
# labelled blocks and fails on the ones that quietly need more than 5.1.
validate-51:
	@echo "==> Validating code snippets against Lua 5.1..."
	@$(LUA51) $(SCRIPTS_DIR)/validate.lua --all
	@echo "==> 5.1 validation complete"

# Run linting on Lua code
lint:
	@echo "==> Running linter..."
	@if command -v $(LUACHECK) >/dev/null 2>&1; then \
		$(LUACHECK) $(LINT_PATHS); \
	elif [ -x "$(LUACHECK)" ]; then \
		$(LUACHECK) $(LINT_PATHS); \
	else \
		echo "  Note: luacheck not installed. Install with: luarocks install luacheck"; \
	fi
	@if command -v stylua >/dev/null 2>&1; then \
		stylua --check $(EXAMPLES_DIR)/ || \
		echo "  Note: the tree is not stylua-formatted. stylua always puts spaces"; \
		echo "        inside table braces, which this code does not, and the option"; \
		echo "        to turn that off does not exist. Reformatting is a separate"; \
		echo "        change of roughly 5500 lines -- deliberately not enforced here."; \
	else \
		echo "  Note: stylua not installed. Install with: cargo install stylua"; \
	fi
	@echo "==> Lint complete"

# Test all example code
test-examples:
	@echo "==> Testing examples with $(LUA)..."
	@$(LUA) $(SCRIPTS_DIR)/test-examples.lua --interpreter "$(LUA)" --runtime "$(LUA_RUNTIME)" --root "$(EXAMPLES_DIR)"
	@echo "==> Example tests complete"

# Check that every C API function the documents name exists
check-capi-names:
	@echo "==> Checking the C API names in the documents..."
	@$(LUA) $(SCRIPTS_DIR)/check-capi-names.lua
	@echo "==> C API name check complete"

# Check that every standard library member the documents name exists
check-stdlib-names:
	@echo "==> Checking the standard library names in the documents..."
	@$(LUA) $(SCRIPTS_DIR)/check-stdlib-names.lua
	@echo "==> Standard library name check complete"

# Run the code samples in the pitfall articles
check-pitfall-examples:
	@echo "==> Checking the pitfall examples with $(LUA)..."
	@$(LUA) $(SCRIPTS_DIR)/check-pitfall-examples.lua --interpreter "$(LUA)"
	@echo "==> Pitfall example check complete"

# Check the version comparison table against the runtime that is running it
test-version-facts:
	@echo "==> Checking the version facts with $(LUA)..."
	@$(LUA) tests/test-version-facts.lua
	@echo "==> Version fact check complete"

# Test all roadmap stage projects
test-roadmap-stages:
	@echo "==> Testing roadmap stages with $(LUA)..."
	@$(LUA) tests/test-roadmap-stages.lua --interpreter "$(LUA)" --runtime "$(LUA_RUNTIME)" --root "lua-mastery-roadmap"
	@echo "==> Roadmap stage tests complete"

# Test against Lua 5.1 -- the oldest version the examples claim to support
test-lua51:
	@echo "==> Testing examples with Lua 5.1..."
	@$(LUA51) $(SCRIPTS_DIR)/test-examples.lua --interpreter "$(LUA51)" --runtime "$(LUA51_RUNTIME)" --root "$(EXAMPLES_DIR)"
	@echo "==> Testing roadmap stages with Lua 5.1..."
	@$(LUA51) tests/test-roadmap-stages.lua --interpreter "$(LUA51)" --runtime "$(LUA51_RUNTIME)" --root "lua-mastery-roadmap"
	@echo "==> Lua 5.1 tests complete"

# Test with LuaJIT if available
test-luajit:
	@echo "==> Testing examples with LuaJIT..."
	@if command -v $(LUAJIT) >/dev/null 2>&1; then \
		$(LUAJIT) $(SCRIPTS_DIR)/test-examples.lua --interpreter "$(LUAJIT)" --runtime "$(LUAJIT_RUNTIME)" --root "$(EXAMPLES_DIR)"; \
		$(LUAJIT) tests/test-roadmap-stages.lua --interpreter "$(LUAJIT)" --runtime "$(LUAJIT_RUNTIME)" --root "lua-mastery-roadmap"; \
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
	@bash $(SCRIPTS_DIR)/check-links.sh $(LINK_DIRS)
	@echo "==> Checking link anchors..."
	@$(LUA) $(SCRIPTS_DIR)/check-anchors.lua
	@echo "==> Link check complete"

# Verify every example's `-- Chapter:` header names a real chapter
check-chapters:
	@echo "==> Checking example chapter references..."
	@$(LUA) $(SCRIPTS_DIR)/check-example-chapters.lua
	@echo "==> Chapter check complete"

# Check EN/ZH mirrored learner content
parity:
	@echo "==> Checking EN/ZH parity..."
	@$(LUA) $(SCRIPTS_DIR)/parity.lua
	@echo "==> Parity check complete"

# Verify that every "Stage NN" / "Chapter NN" reference names the right thing
check-stage-refs:
	@echo "==> Checking stage and chapter references..."
	@$(LUA) $(SCRIPTS_DIR)/check-stage-refs.lua
	@echo "==> Stage reference check complete"

# Verify that the code samples in the two language tracks are the same code
check-code-mirror:
	@echo "==> Checking EN/ZH code sample mirroring..."
	@$(LUA) $(SCRIPTS_DIR)/check-code-mirror.lua
	@echo "==> Code mirror check complete"

# Verify that the stage READMEs name the files that exist on disk
check-stage-files:
	@echo "==> Checking stage README file references..."
	@$(LUA) $(SCRIPTS_DIR)/check-stage-files.lua
	@echo "==> Stage file check complete"

# Generate table of contents for chapters
toc:
	@echo "==> Generating table of contents..."
	@$(SCRIPTS_DIR)/generate-toc.lua
	@echo "==> TOC generated"

# Run all validation and tests
ci: validate validate-51 lint check-links check-chapters check-stage-refs check-code-mirror check-stage-files check-pitfall-examples check-stdlib-names check-capi-names parity test-examples test-roadmap-stages test-version-facts
	@echo "==> CI checks complete"

# Run the full version matrix: 5.4 baseline plus the 5.1 and LuaJIT baselines
ci-matrix: ci test-lua51 test-luajit
	@echo "==> Matrix checks complete"

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
