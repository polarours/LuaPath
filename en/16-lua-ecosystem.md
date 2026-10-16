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

## Popular Lua Libraries

### Web Frameworks

- **OpenResty**: Nginx + Lua, high-performance web server
- **Lapis**: Full-featured web framework
- **Sailor**: MVC web framework

### Database Drivers

- **luasocket**: TCP/UDP networking
- **lua-nginx-module**: Database access in OpenResty
- **luasql**: SQL database connectivity

### Serialization

- **lua-cjson**: Fast JSON encoding/decoding
- **dkjson**: Pure Lua JSON library
- **lua-MessagePack**: MessagePack serialization
- **cdata**: Binary data handling

### Testing

- **busted**: BDD-style testing framework
- **luaunit**: Unit testing framework
- **deftest**: Test discovery and organization

### Code Quality

- **luacheck**: Static analyzer for Lua
- **stylua**: Code formatter
- **lua-language-server**: VS Code extension with LSP

### CLI Tools

- **cliargs**: Command-line argument parsing
- **penlight**: Utility library with CLI helpers
- **lua-cli**: Interactive Lua shell

---

## Case Study: Choosing a Dependency Without Regret

A project must ship on Lua 5.1, 5.3, 5.4, and LuaJIT, and it must run in
environments where `luarocks` may not be installed. JSON encoding is the need.
The chapter has listed candidates (`cjson`, `dkjson`, `json`); this case study is
about the mechanism that makes picking one reversible.

### The Failure Mode Being Designed Against

Declaring a dependency only tells you what you hoped for. The failure is
discovering the library is missing at *load* time, in an environment you cannot
change — and taking the process down with it. So the decision is made twice:

1. **Install time** — preferred order declared in the `.rockspec`.
2. **Load time** — an actual probe, with a working fallback already in hand.

### The Probe

```lua
local function probe(name)
  local ok, mod = pcall(require, name)
  if ok then return { available = true, module = mod } end
  return { available = false, reason = tostring(mod) }
end

local JSON_CANDIDATES = { "cjson", "dkjson", "json" }
```

`pcall(require, ...)` is the whole trick: a missing module returns an error string
instead of raising, so absence is a normal, handled condition rather than a crash.

On a machine with no JSON libraries installed, the probe reports honestly:

```
Dependency probe
----------------
  cjson                [missing]      not installed
  dkjson               [missing]      not installed
  json                 [missing]      not installed
  built-in fallback    [available]    stdlib only, always present

Selected encoder: built-in fallback
```

### Why The Fallback Must Be Real

This is the part people get wrong. A fallback written as `error("install cjson")`
is not a fallback — it is the original failure with extra steps. Here the fallback
is a complete stdlib-only encoder (~60 lines) that handles string escaping,
array-vs-object detection, cyclic-table rejection, and non-finite numbers:

```lua
-- JSON has no NaN/Infinity representation
if value ~= value or value == math.huge or value == -math.huge then
  error("cannot encode non-finite number: " .. tostring(value))
end
```

A non-finite number makes `value ~= value` true, which is how you detect NaN
without a `math.isnan`. Both of those are cases where a naive encoder silently
produces invalid JSON.

### Reporting The Difference Honestly

When a preferred library *is* present, the example compares its output against
the shipped fallback. Byte-for-byte identity is **reported, not asserted** — key
order and float formatting legitimately differ between libraries:

```
Selected encoder (cjson) vs fallback byte-identical: false
  fallback output:
  {"empty_list":[],"enabled":true,"limits":{"cpu":0.5,...}}
```

Asserting equality here would be the bug: the test would fail for cosmetic
reasons, and someone would delete it. Reporting it keeps the information without
manufacturing a false failure.

### Keeping The Fallback Alive

A fallback that is never executed rots silently — it stops being exercised the
day a fast path exists. So the content checks run on **every available path**:

```
Content checks
--------------
  [cjson] ok   service name preserved
  [cjson] ok   array preserved
  [cjson] ok   newline escaped
  ...
  [fallback] ok   service name preserved
  [fallback] ok   array preserved
  ...
Cyclic input rejected: true
```

Run both paths yourself:

```bash
# Fallback path (no JSON library installed)
lua examples/advanced/24-ecosystem-probe.lua

# Fast path (any library providing a .encode function)
LUA_PATH="/path/to/modules/?.lua;;" lua examples/advanced/24-ecosystem-probe.lua
```

Verified on Lua 5.4, Lua 5.1, and LuaJIT 2.1 — all exit 0.

### Dependency Policy Checklist

Before adding a third-party dependency to a Lua project, answer these:

- **Is there a fallback I would accept as production-grade?** If not, write one
  or decide the dependency is truly mandatory and fail loudly at startup.
- **Is the version constraint narrow enough to be honest, wide enough to be
  useful?** `"cjson >= 2.1"` vs `"cjson"` have very different failure profiles.
- **Does the library support every Lua version I claim to support?** The
  version table earlier in this chapter exists for exactly this check.
- **Will I know when the dependency goes missing?** A probe with a report gives
  you a log line; an unguarded `require` gives you a stack trace.

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

## Exercises

### Beginner (30–60 min)

1. **Package Search**: Use LuaRocks to search for and install a JSON library. Write a small script that uses it to parse a JSON string.

2. **Lint Your Code**: Run luacheck on a Lua file and fix any warnings it reports.

### Intermediate (1–2 hours)

3. **Write a Busted Test**: Create a test file for a simple function using Busted's describe/it/assert syntax. Run it with `busted`.

4. **Create a Rockspec**: Write a `.rockspec` file for a small Lua module you've written. Test it with `luarocks lint`.

### Advanced (2–4 hours)

5. **CI/CD Pipeline**: Set up a GitHub Actions workflow that runs luacheck and busted tests on every push.

6. **Version Compatibility Wrapper**: Create a compatibility layer that provides consistent APIs across Lua 5.1, 5.3, and 5.4.

---

## Further Reading

- [LuaRocks Documentation](https://luarocks.org/)
- [Busted Documentation](https://olivinelabs.com/busted/)
- [Lua Users Wiki](https://lua-users.org/)

---

[Next Chapter: 17 — Embedding Patterns](17-embedding-patterns.md)
