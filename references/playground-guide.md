# Interactive Lua Playground

Online environments where you can run Lua code directly in your browser.

## Quick Start

Try Lua right now with this one-liner:

```bash
lua -e 'print("Hello, Lua " .. _VERSION .. "!")'
```

Or paste this into any online playground:

```lua
-- Quick Lua Demo
local function factorial(n)
  if n <= 1 then return 1 end
  return n * factorial(n - 1)
end

print("Factorial of 10:", factorial(10))
print("Lua version:", _VERSION)
print("Table example:", table.concat({1, 2, 3, 4, 5}, ", "))
```

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

## Playground Comparison

| Feature | Lua 5.4 | LuaJIT | Replit | Paiza.IO | Ideone |
|---------|---------|--------|--------|----------|--------|
| Lua Version | 5.4 | 5.1+ext | 5.3/5.4 | Multiple | Multiple |
| File I/O | ✗ | ✗ | ✓ | ✗ | ✗ |
| C API/FFI | ✗ | ✓ | ✗ | ✗ | ✗ |
| Save Projects | ✗ | ✗ | ✓ | ✗ | ✗ |
| Stdin Support | ✗ | ✗ | ✓ | ✓ | ✓ |
| Share Links | ✗ | ✗ | ✓ | ✓ | ✓ |
| Full IDE | ✗ | ✗ | ✓ | ✗ | ✗ |

## Interactive Examples

### Example 1: Hello World with Functions

```lua
-- Function declaration
local function greet(name)
  return "Hello, " .. name .. "!"
end

-- Table iteration
local names = {"Alice", "Bob", "Charlie"}
for _, name in ipairs(names) do
  print(greet(name))
end
```

### Example 2: Metatables

```lua
-- Simple OOP with metatables
local Person = {}
Person.__index = Person

function Person.new(name, age)
  return setmetatable({name = name, age = age}, Person)
end

function Person:introduce()
  return string.format("I'm %s, %d years old", self.name, self.age)
end

local p = Person.new("Lua", 30)
print(p:introduce())
```

### Example 3: Coroutines

```lua
-- Producer-consumer with coroutines
local function producer()
  for i = 1, 5 do
    coroutine.yield(i)
  end
end

local co = coroutine.create(producer)
for i = 1, 5 do
  local ok, value = coroutine.resume(co)
  print("Received:", value)
end
```

### Example 4: Pattern Matching

```lua
-- String pattern matching
local text = "Email: user@example.com, Phone: 123-456-7890"

-- Extract email
local email = text:match("[%w%.]+@[%w%.]+")
print("Email:", email)

-- Extract phone
local phone = text:match("%d%d%d%-%d%d%d%-%d%d%d%d")
print("Phone:", phone)
```

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

## Troubleshooting

### Common Issues

1. **"attempt to call a nil value"** - You're trying to call something that doesn't exist. Check spelling and make sure required libraries are loaded.

2. **"index out of range"** - Lua arrays are 1-indexed, not 0-indexed. Use `#table` to get length.

3. **"attempt to concatenate a nil value"** - You're trying to concatenate nil. Check if variables are assigned before use.

4. **Version-specific errors** - Some features only exist in certain versions:
   - `//` integer division: Lua 5.3+
   - `goto`: Lua 5.2+
   - `<close>` variables: Lua 5.4+

### Getting Help

- Check the [Glossary](../GLOSSARY.md) for term definitions
- Review [Pitfalls](../pitfalls/) for common mistakes
- Look at [Examples](../examples/) for working code patterns

## Tips for Using Playgrounds

1. **Test examples from chapters** — Copy code snippets and run them
2. **Experiment with variations** — Modify examples to see behavior changes
3. **Check version differences** — Run the same code on Lua 5.3 vs 5.4
4. **Use print() for debugging** — Most playgrounds only support stdout
5. **Save interesting code** — Use Replit or local files for persistence

## Using Playgrounds with lua-journey

### Testing Chapter Examples

1. Find an example in `examples/` directory
2. Copy the code into a playground
3. Run and modify to understand the behavior
4. Try different Lua versions to see differences

### Testing Roadmap Projects

1. Navigate to `lua-mastery-roadmap/` directory
2. Find a project that interests you
3. Copy the `.lua` file content into Replit (for multi-file projects)
4. Or paste into a simple playground for single-file projects

### Testing Exercises

1. Look at exercises in `en/exercises/` or `zh/exercises/`
2. Try solving them in a playground first
3. Check solutions in `en/exercises/beginner-solutions.md` when stuck
4. Modify solutions to explore alternatives

## Limitations of Online Playgrounds

- No file I/O (most sandboxes)
- No C API / FFI (except LuaJIT playground)
- No network access
- Limited runtime (memory, CPU)
- No persistent storage

For exercises requiring file I/O, C API, or networking, use a local setup.
