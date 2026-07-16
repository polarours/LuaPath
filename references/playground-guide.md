# Interactive Lua Playground

Online environments where you can run Lua code directly in your browser.

## Recommended Playgrounds

### 1. Lua 5.4 (Official)

**URL**: https://www.lua.org/try.html

- Runs Lua 5.4 (latest stable)
- Official sandbox from lua.org
- Limited features, no file I/O
- Good for quick syntax testing

### 2. LuaJIT Playground

**URL**: https://luajit.org/try.html

- Runs LuaJIT (Lua 5.1 compatible with extensions)
- Includes FFI support
- Good for testing JIT-specific behavior

### 3. Replit (Full IDE)

**URL**: https://replit.com/languages/lua

- Full IDE with file system
- Supports Lua 5.3/5.4
- Can save and share projects
- Good for building complete programs

### 4. Paiza.IO

**URL**: https://paiza.io/en/languages/lua

- Online editor with run button
- Supports stdin input
- Good for competitive programming style

### 5. Ideone

**URL**: https://ideone.com/lua

- Supports multiple Lua versions
- Can share code links
- Good for code sharing and discussion

## Local Quick Start

If you prefer running locally:

```bash
# Install Lua 5.4 (Ubuntu/Debian)
sudo apt-get install lua5.4

# Install Lua 5.3
sudo apt-get install lua5.3

# Install LuaJIT
sudo apt-get install luajit

# Quick REPL
lua5.4        # Start interactive Lua 5.4
lua5.3        # Start interactive Lua 5.3
luajit        # Start interactive LuaJIT

# Run a file
lua5.4 my_script.lua
```

## VS Code Setup

For a better local experience:

1. Install [Visual Studio Code](https://code.visualstudio.com/)
2. Install the **Lua** extension by sumneko
3. Create a `.lua` file
4. Press `Ctrl+F5` to run

## Emacs Setup

```elisp
;; Add to init.el
(setq lua-default-directory "/path/to/lua-journey")
(setq lua-indent-level 2)
```

## Vim/Neovim Setup

```vim
" Add to init.vim or init.lua
let g:lua_syntax_conceal = 0
let g:loaded_lua = 1
```

## Tips for Using Playgrounds

1. **Test examples from chapters** — Copy code snippets and run them
2. **Experiment with variations** — Modify examples to see behavior changes
3. **Check version differences** — Run the same code on Lua 5.3 vs 5.4
4. **Use print() for debugging** — Most playgrounds only support stdout
5. **Save interesting code** — Use Replit or local files for persistence

## Limitations of Online Playgrounds

- No file I/O (most sandboxes)
- No C API / FFI (except LuaJIT playground)
- No network access
- Limited runtime (memory, CPU)
- No persistent storage

For exercises requiring file I/O, C API, or networking, use a local setup.
