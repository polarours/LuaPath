-- examples/simple.lua — Example build script for a simple project
-- Demonstrates task dependencies and incremental build semantics.

-- Resolve the implementation directory from this script's own location, so
-- the test works regardless of the absolute path on disk.
local function _script_dir()
  local src = arg and arg[0] or debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then src = src:sub(2) end
  return src:match("^(.*/)") or "./"
end
package.path = _script_dir() .. "../src/?.lua;" .. package.path


local Build = require("build")

print("=== Lua Build System Demo ===")

local b = Build.new()

-- Define tasks with dependencies

b:task("clean", {}, function(build)
  print("[clean] Cleaning build artifacts...")
  return { cleaned = true }
end)

b:task("compile", {"clean"}, function(build)
  print("[compile] Compiling source files...")
  -- Simulate compiling three files
  local objects = {}
  for i = 1, 3 do
    objects[i] = ("file" .. i .. ".obj")
  end
  print("[compile] Compiled: " .. table.concat(objects, ", "))
  return { objects = objects }
end)

b:task("link", {"compile"}, function(build)
  print("[link] Linking object files...")
  print("[link] Linking object files (simulated)...")
  return { executable = "myapp" }
end)

b:task("test", {"compile"}, function(build)
  print("[test] Running tests...")
  print("[test] 3/3 tests passed")
  return { passed = true, tests = 3 }
end)

b:task("deploy", {"link", "test"}, function(build)
  print("[deploy] Deploying build...")
  print("[deploy] Deploying myapp (simulated)...")
  return { deployed = true }
end)

print("\nTask graph:")
print(b)
print("\nExecution order:", table.concat(b:resolve_order(), " -> "))
print()

print("Executing 'deploy' task...")
local result = b:execute("deploy")
print("\nResult:", result.deployed and "SUCCESS" or "FAILED")
print()

print("Running incremental build (re-execute 'deploy')...")
-- Second execution should skip already-executed tasks
local result2 = b:execute("deploy")
print("Incremental result:", result2.deployed and "SUCCESS" or "FAILED")
print()
print("=== Demo complete ===")
