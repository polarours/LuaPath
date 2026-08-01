-- src/pkg_manager.lua — Pure Lua package dependency resolver
-- Implements dependency graph resolution with cycle detection
-- and version constraint handling.

local PackageManager = {}
PackageManager.__index = PackageManager

--- Create a new package manager.
function PackageManager.new()
  return setmetatable({
    registry = {},
    resolved = {},
    conflicts = {},
  }, PackageManager)
end

--- Register a package in the local registry.
-- name: package name
-- version: version string (e.g., "1.0.0")
-- dependencies: map of dep_name -> version_constraint
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
-- Returns a table of resolved packages or nil on conflict/cycle.
function PackageManager:resolve(roots)
  local visiting = {}
  local visited = {}
  
  local function visit(name, version)
    if visiting[name] then
      table.insert(self.conflicts, "Cycle detected: " .. name)
      return nil
    end
    if visited[name] then
      return true
    end
    visiting[name] = true

    local pkg_map = self.registry[name]
    if not pkg_map then
      table.insert(self.conflicts, "Unknown package: " .. name)
      return nil
    end

    local selected_version = version or "latest"
    if selected_version == "latest" then
      local versions = {}
      for v in pairs(pkg_map) do
        if type(v) == "string" then
          table.insert(versions, v)
        end
      end
      if #versions > 0 then
        table.sort(versions)
        selected_version = versions[#versions]
      end
    end

    local pkg = pkg_map[selected_version]
    if not pkg then
      table.insert(self.conflicts, "Unknown version: " .. selected_version .. " for " .. name)
      return nil
    end

    for dep_name, dep_ver in pairs(pkg.dependencies) do
      if not visit(dep_name, dep_ver) then return nil end
    end

    visiting[name] = false
    visited[name] = true
    self.resolved[name] = {
      version = selected_version,
      version_spec = version or "*"
    }
    return true
  end

  for name, version in pairs(roots) do
    if not visit(name, version) then return nil end
  end

  return self.resolved
end

--- Get all resolved package names.
function PackageManager:list()
  local names = {}
  for name in pairs(self.resolved) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

--- Clear the resolved packages (for reuse).
function PackageManager:reset()
  self.resolved = {}
  self.conflicts = {}
  return self
end

return PackageManager
