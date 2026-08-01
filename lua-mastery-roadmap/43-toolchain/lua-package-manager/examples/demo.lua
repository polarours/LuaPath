-- examples/demo.lua — Lua package manager demonstration
-- Shows how to register packages and resolve dependencies.

package.path = "/home/polarours/Projects/Personal/LuaPath/lua-mastery-roadmap/43-toolchain/lua-package-manager/src/?.lua;" .. package.path

local PackageManager = require("pkg_manager")

print("=== Lua Package Manager Demo ===")

local pm = PackageManager.new()

-- Register some packages with dependencies
pm:register("lua-http-server", "1.0.0", { ["lua-build-system"] = "1.0.0" })
pm:register("lua-http-server", "2.0.0", { ["lua-build-system"] = "2.0.0" })

pm:register("lua-build-system", "1.0.0", {})
pm:register("lua-build-system", "2.0.0", { ["lua-core"] = "1.0.0" })

pm:register("lua-core", "1.0.0", {})
pm:register("lua-core", "2.0.0", {})

pm:register("lua-utils", "1.0.0", { ["lua-core"] = "*" })

-- Resolve a set of requested packages (exact versions only)
print("\nRequesting lua-http-server@1.0.0...")
local resolved = pm:resolve { ["lua-http-server"] = "1.0.0" }

if resolved then
  print("Resolution successful!")
  print("Resolved packages:")
  for name, info in pairs(resolved) do
    print("  " .. name .. "@" .. info.version)
  end
else
  print("Resolution failed!")
  print("Conflicts:", table.concat(pm.conflicts, ", "))
end

print()
print("Note: This simple resolver uses exact version matching only.")
print("For production use, add semantic version constraint resolution.")
print()
print("=== Demo complete ===")
