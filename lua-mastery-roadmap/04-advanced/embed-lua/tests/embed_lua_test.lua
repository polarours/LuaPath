-- tests/embed_lua_test.lua — Unit tests for the embed_lua C host
-- Run from project root with: lua lua-mastery-roadmap/04-advanced/embed-lua/tests/embed_lua_test.lua
--
-- Tests compile and run the C host binary and verify its output.
-- This script does NOT require the Lua host to be pre-built; it builds
-- as needed from the C source in the parent directory.

-- Resolve the tests/ directory so we can find the sibling C source
local function _script_dir()
  local src = arg and arg[0] or debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then src = src:sub(2) end
  return src:match("^(.*/)") or "./"
end

-- helpers
local function run(cmd)
  local pipe = io.popen(cmd .. " 2>&1")
  local out = pipe:read("*all")
  pipe:close()
  return out
end

local function assert_substr(haystack, needle, msg)
  if not haystack:find(needle, 1, true) then
    error(string.format("FAIL: %s — expected output to contain: %q", msg, needle), 2)
  end
end

print("=== embed_lua C Host Tests ===\n")

local stage_dir = _script_dir() .. "../"
local c_src = stage_dir .. "05-embed-lua.c"
local binary = stage_dir .. "embed_lua"

-- -----------------------------------
-- 1. Verify C source exists
-- -----------------------------------
print("1. C source exists")
local f = io.open(c_src, "r")
if not f then error("C source not found: " .. c_src, 0) end
f:close()
print("   PASS: " .. c_src)

-- -----------------------------------
-- 2. Build (try lua5.4 lib, fall back to lua5.5)
-- -----------------------------------
print("\n2. Build C host")
-- Try lua5.4 lib first; fall back to lua5.5 (confirmed on this system)
-- Check exit code explicitly (avoid substring match on FALLOK / OK ambiguity)
local function build_host(llib)
  return os.execute(string.format(
    "cd %s && gcc -o embed_lua 05-embed-lua.c -l:%s -lm -ldl > /dev/null 2>&1", stage_dir, llib
  ))
end
local ok4 = build_host("liblua5.4.so")
local ok5 = build_host("liblua5.5.so")
if not ok4 and not ok5 then
  local err = run(string.format("cd %s && gcc -o embed_lua 05-embed-lua.c -l:liblua5.5.so -lm -ldl 2>&1", stage_dir))
  print("   BUILD FAILED:\n" .. err)
  os.exit(1)
end
print("   PASS: compiled (lua5.5 lib)")

-- -----------------------------------
-- 3. Binary runs without crashing
-- -----------------------------------
print("\n3. Binary runs without crashing")
local output = run(binary)
assert_substr(output, "Lua Embed Demo", "binary runs")
print("   PASS: binary executed")

-- -----------------------------------
-- 4. host.log output appears
-- -----------------------------------
print("\n4. host.log output appears")
assert_substr(output, "[INFO] Lua script started", "log INFO level")
assert_substr(output, "[WARN] Caught error", "log WARN level")
print("   PASS: host.log levels present")

-- -----------------------------------
-- 5. Counter userdata works
-- -----------------------------------
print("\n5. Counter userdata works")
assert_substr(output, "Counter(15)", "Counter increments correctly")
assert_substr(output, "[INFO] Counter get: 15", "Counter :get() works")
print("   PASS: Counter userdata")

-- -----------------------------------
-- 6. host.time returns a number
-- -----------------------------------
print("\n6. host.time returns a number")
assert_substr(output, "Host time:", "host.time output present")
-- verify it printed a number
local time_line = output:match("Host time: ([%d%.]+)")
if not time_line then error("Could not parse host.time output", 0) end
local t = tonumber(time_line)
if not t then error("host.time did not return a number: " .. time_line, 0) end
print("   PASS: host.time = " .. time_line)

-- -----------------------------------
-- 7. Script completes successfully
-- -----------------------------------
print("\n7. Script completes successfully")
assert_substr(output, "Script completed successfully", "completion message")
assert_substr(output, "=== Done ===", "binary footer")
print("   PASS: script completed")

-- -----------------------------------
-- 8. Error across Lua/C boundary is caught
-- -----------------------------------
print("\n8. Error across Lua/C boundary is caught")
-- C outputs the Lua error string in quotes: "deliberate error from Lua side"
assert_substr(output, "deliberate error from Lua", "pcall catches Lua error")
print("   PASS: error propagation")

-- -----------------------------------
-- 9. Type validation works (Counter rejects bad input)
-- -----------------------------------
print("\n9. Type validation works")
assert_substr(output, "bad argument #1 to 'Counter'", "type check rejects string")
assert_substr(output, "number expected, got string", "error message is descriptive")
print("   PASS: type validation")

print("\n=== ALL TESTS PASSED ===")
