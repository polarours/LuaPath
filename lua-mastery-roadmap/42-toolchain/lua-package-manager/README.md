# Stage 42.3: Lua Package Manager

**Level**: Advanced  
**Description**: Build a lightweight, pure-Lua package dependency resolver. Learn to parse package manifests, resolve dependency graphs, handle version constraints, and implement package loading — all in Lua without external dependencies.

## Prerequisites

- Chapter 06 — Modules
- Stage 27 — Memory Management
- Chapter 12 — Performance

## Project Structure

```
42-toolchain/lua-package-manager/
├── README.md
├── README.zh-CN.md
├── src/
│   └── pkg_manager.lua    — Package resolver core
├── examples/
│   └── demo.lua       — Package resolution demo
└── tests/
    └── resolve_test.lua  — Dependency resolution tests
```

## Background

Package managers like luarocks, npm, and pip solve the "dependency hell" problem by resolving version constraints and ensuring all required packages are available. This project implements a simplified package manager in pure Lua, focusing on the core dependency resolution algorithm.

## Implementation

### Package Resolver (`src/pkg_manager.lua`)

```lua
local PackageManager = {}
PackageManager.__index = PackageManager

--- Create a new package resolver.
function PackageManager.new()
  return setmetatable({
    registry = {},     -- package name -> version list
    resolved = {},     -- resolved packages
    conflicts = {},    -- detected conflicts
  }, PackageManager)
end

--- Register a package in the local registry.
function PackageManager:register(name, version, dependencies)
  if not self.registry[name] then
    self.registry[name] = {}
  end
  self.registry[name][version] = {
    name = name,
    version = version,
    dependencies = dependencies or {},
  }
  return self
end

--- Resolve a set of requested packages and their constraints.
-- Returns a table of resolved packages or nil on conflict.
function PackageManager:resolve(roots)
  local visiting = {}
  local function visit(name, version)
    if visiting[name] then
      table.insert(self.conflicts, "Cycle: " .. name)
      return nil
    end
    visiting[name] = true
    local pkg = self.registry[name][version]
    if not pkg then
      table.insert(self.conflicts, "Unknown package: " .. name .. "@" .. version)
      return nil
    end
    for dep_name, dep_ver in pairs(pkg.dependencies) do
      local ok = visit(dep_name, dep_ver or "latest")
      if not ok then return nil end
    end
    visiting[name] = false
    self.resolved[name] = { version = version, version_spec = version or "*" }
    return true
  end

  for name, version in pairs(roots) do
    if not visit(name, version) then return nil end
  end

  return self.resolved
end

--- Get all installed packages.
function PackageManager:list()
  local names = {}
  for name in pairs(self.resolved) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

return PackageManager
```

### Example (`examples/demo.lua`)

```lua
local PackageManager = require("src.pkg_manager")

local pm = PackageManager.new()
pm:register("lua-http-server", "1.0.0", { ["lua-build-system"] = "1.0.0" })
pm:register("lua-build-system", "1.0.0", {})
pm:register("lua-build-system", "1.1.0", {})

local resolved = pm:resolve {
  ["lua-http-server"] = "1.0.0"
}

if resolved then
  print("Resolved packages:")
  for name, info in pairs(resolved) do
    print("  " .. name .. "@" .. info.version)
  end
else
  print("Resolution failed!")
end
```

## Time Estimate

8–12 hours
