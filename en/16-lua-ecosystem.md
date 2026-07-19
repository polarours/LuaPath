# Chapter 16: Lua Ecosystem

> **Phase**: Advanced  
> **Prerequisites**: Chapters 06 (Modules), 14 (Production)  
> **Time**: 6–10 hours  
> **Lua Versions**: 5.1, 5.3, 5.4, LuaJIT

---

## Learning Objectives

After this chapter, you will be able to:

1. Navigate the Lua package ecosystem using LuaRocks
2. Set up development environments with proper tooling
3. Use testing frameworks for Lua projects
4. Understand Lua community resources and conventions
5. Choose appropriate libraries for common tasks

---

## Package Management with LuaRocks

### Installation

```bash
# Install LuaRocks
luarocks install --local mypackage

# Search for packages
luarocks search json

# Install specific version
luarocks install mypackage 1.0.0

# List installed packages
luarocks list
```

### Creating Your Own Rocks

```lua
-- mypackage-scm-1.rockspec
package = "mypackage"
version = "scm-1"
source = {
  url = "git://github.com/user/mypackage.git",
  tag = "v1.0.0"
}
dependencies = {
  "lua >= 5.1",
  "luafilesystem >= 1.8"
}
build = {
  type = "builtin",
  modules = {
    mypackage = "src/mypackage.lua"
  }
}
```

### Popular Lua Libraries

| Category | Library | Description |
|----------|---------|-------------|
| HTTP | lua-http, luasocket | HTTP client/server |
| JSON | cjson, dkjson, lua-cjson | JSON encoding/decoding |
| Testing | busted, luaunit | Test frameworks |
| Logging | lua-log, logua | Logging libraries |
| CLI | cliargs, penlight | Command-line parsing |
| Database | luasql, pgmoon | Database drivers |
| Serialization | lua-cjson, serpent | Data serialization |

---

## Development Environment

### Recommended Tools

1. **Editor**: VS Code with Lua extension (sumneko)
2. **Linter**: luacheck for static analysis
3. **Formatter**: stylua for consistent formatting
4. **Debugger**: Local Lua debugger or IDE integration
5. **Profiler**: luaprofiler or external tools

### Project Structure

```
myproject/
├── src/
│   └── mymodule.lua
├── tests/
│   ├── test_mymodule.lua
│   └── helpers.lua
├── examples/
│   └── demo.lua
├── docs/
│   └── README.md
├── myproject-scm-1.rockspec
└── .luacheckrc
```

### Configuration Files

```lua
-- .luacheckrc
std = "lua54"
globals = {
  "MY_GLOBAL"
}
read_globals = {
  "describe",
  "it",
  "assert"
}
```

---

## Testing with Busted

### Installation

```bash
luarocks install busted
```

### Basic Test Structure

```lua
-- tests/test_calculator.lua
local calculator = require("calculator")

describe("Calculator", function()
  describe("add", function()
    it("should add two numbers", function()
      assert.are.equal(5, calculator.add(2, 3))
    end)
    
    it("should handle negative numbers", function()
      assert.are.equal(-1, calculator.add(1, -2))
    end)
  end)
  
  describe("divide", function()
    it("should divide two numbers", function()
      assert.are.equal(2.5, calculator.divide(5, 2))
    end)
    
    it("should error on division by zero", function()
      assert.has_error(function()
        calculator.divide(1, 0)
      end)
    end)
  end)
end)
```

### Running Tests

```bash
# Run all tests
busted

# Run specific file
busted tests/test_calculator.lua

# Run with coverage
busted --coverage

# Run with output
busted -o utfTerminal
```

---

## Code Quality Tools

### Luacheck

```bash
# Install
luarocks install luacheck

# Run on project
luacheck src/ tests/

# Fix automatically
luacheck src/ --fix
```

### Stylua

```bash
# Install
cargo install stylua

# Format code
stylua src/

# Check formatting
stylua --check src/
```

---

## Community Resources

### Official Resources

- [Lua.org](https://www.lua.org/) — Official website
- [Lua Reference Manual](https://www.lua.org/manual/5.4/) — Official docs
- [Lua Programming Book](https://www.lua.org/pil/) — Definitive guide
- [Lua Users Wiki](https://lua-users.org/) — Community wiki

### Community

- [Lua Discourse](https://discuss.lua.org/) — Official forum
- [Reddit r/lua](https://reddit.com/r/lua) — Community discussions
- [Stack Overflow](https://stackoverflow.com/questions/tagged/lua) — Q&A

### Learning Resources

- [Learn Lua in Y Minutes](https://learnxinyminutes.com/docs/lua/) — Quick reference
- [Lua Tutorial](https://www.tutorialspoint.com/lua/) — Step-by-step tutorial
- [Programming in Lua](https://www.lua.org/pil/) — Comprehensive book

---

## Version Compatibility

### Version Differences

| Feature | 5.1 | 5.3 | 5.4 | LuaJIT |
|---------|-----|-----|-----|--------|
| Integers | No | Yes | Yes | No |
| Bitwise ops | No | Yes | Yes | Yes |
| Generational GC | No | No | Yes | No |
| `goto` | No | Yes | Yes | Yes |
| `_ENV` | No | Yes | Yes | Partial |

### Compatibility Libraries

```lua
-- Lua 5.1 compatibility for 5.2+
local unpack = unpack or table.unpack

-- Bitwise operations for 5.1
local bit = require("bit32") or require("bit")

-- Select version at runtime
local function is_lua51()
  return _VERSION == "Lua 5.1"
end
```

---

## Best Practices

1. **Use LuaRocks** for package management
2. **Set up luacheck** early in development
3. **Write tests** before implementing features
4. **Document your APIs** for team collaboration
5. **Pin dependency versions** in production

---

## Key Takeaways

- LuaRocks is the standard package manager for Lua
- Busted provides a modern testing framework
- Luacheck and stylua ensure code quality
- Community resources are available for learning and support
- Version compatibility requires careful planning

---

## Further Reading

- [LuaRocks Documentation](https://luarocks.org/)
- [Busted Documentation](https://olivinelabs.com/busted/)
- [Lua Users Wiki](https://lua-users.org/)

---

[Next Chapter: 17 — Embedding Patterns](17-embedding-patterns.md)
