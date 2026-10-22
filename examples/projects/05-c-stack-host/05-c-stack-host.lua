-- Example 64: C Stack Host (build + run the C API example)
-- Chapter: 11-lua-c-api
-- Difficulty: Advanced
-- Lua Version: 5.1+
--
-- Driver for host.c, which is the example proper. This script compiles it,
-- runs it, and asserts on the report it prints.
--
-- The build step is the point of the example, so it is skipped loudly rather
-- than faked: with no C compiler or no Lua headers the script prints SKIP with
-- a reason and exits 0, and that line stays visible in `make test-examples`.

local function section(title)
  print()
  print(string.rep("=", 64))
  print(title)
  print(string.rep("=", 64))
end

local checks, failures = 0, 0
local function check(label, ok)
  checks = checks + 1
  if ok then
    print(string.format("  [ok  ] %s", label))
  else
    failures = failures + 1
    print(string.format("  [FAIL] %s", label))
  end
end

local function file_exists(path)
  local handle = io.open(path, "r")
  if handle then handle:close() return true end
  return false
end

-- Returns (ok, output). `quiet` suppresses echoing the output.
local function run(cmd, quiet)
  local pipe = io.popen(cmd .. " 2>&1")
  if not pipe then return false, "could not run: " .. cmd end
  local out = pipe:read("*all")
  local ok = pipe:close()
  if not quiet then print(out) end
  return (ok == true or ok == 1) and true or false, out
end

local function which(program)
  local pipe = io.popen("command -v " .. program .. " 2>/dev/null")
  if not pipe then return nil end
  local path = pipe:read("*l")
  pipe:close()
  if path and #path > 0 then return path end
  return nil
end

local script = (arg and arg[0]) or ""
local base_dir = script:match("^(.*)/[^/]+$") or "."
local source = base_dir .. "/host.c"
local binary = base_dir .. "/host"

--------------------------------------------------------------------------------

section("Locating a toolchain")

if not file_exists(source) then
  print("SKIP: " .. source .. " not found")
  os.exit(0)
end
print("  source: " .. source)

local compiler = nil
for _, cc in ipairs({ "cc", "gcc", "clang" }) do
  local path = which(cc)
  if path then compiler = cc break end
end

if not compiler then
  print("SKIP: no C compiler on PATH (tried cc, gcc, clang)")
  os.exit(0)
end
print("  compiler: " .. compiler .. " (" .. which(compiler) .. ")")

local flags, flags_pkg = nil, nil
for _, pkg in ipairs({ "lua5.4", "lua5.3", "lua5.1", "lua", "luajit" }) do
  local ok, out = run("pkg-config --cflags --libs " .. pkg .. " 2>/dev/null", true)
  if ok and out then
    local trimmed = out:gsub("%s+$", "")
    if #trimmed > 0 then flags, flags_pkg = trimmed, ("pkg-config " .. pkg) break end
  end
end

if not flags then
  local candidates = {
    { "-I/usr/include/lua5.4 -llua5.4", "/usr/include/lua5.4/lua.h", "lua5.4 headers" },
    { "-I/usr/include/lua5.3 -llua5.3", "/usr/include/lua5.3/lua.h", "lua5.3 headers" },
    { "-I/usr/include/lua5.1 -llua5.1", "/usr/include/lua5.1/lua.h", "lua5.1 headers" },
    { "-I/usr/include/luajit-2.1 -lluajit-5.1", "/usr/include/luajit-2.1/lua.h", "luajit headers" },
  }
  for _, c in ipairs(candidates) do
    if file_exists(c[2]) then flags, flags_pkg = c[1], c[3] break end
  end
end

if not flags then
  print("SKIP: Lua headers not found (pkg-config found nothing, no system headers)")
  print("      install e.g. `pacman -S lua` or `lua51` to build this example")
  os.exit(0)
end
print("  lua flags: " .. flags .. "   (via " .. flags_pkg .. ")")

--------------------------------------------------------------------------------

section("Building host.c")

local build_cmd = string.format("%s -Wall -Wextra -o %s %s %s -lm",
  compiler, binary, source, flags)
print("  $ " .. build_cmd)

local build_ok, build_out = run(build_cmd, true)
if not build_ok then
  print("BUILD FAILED")
  print(build_out)
  os.exit(1)
end
check("compiles clean under -Wall -Wextra", true)
print("  build ok")

--------------------------------------------------------------------------------

section("Running the host")

local run_ok, run_out = run(binary, true)
print(run_out or "")

os.remove(binary)   -- always clean the artefact up, pass or fail

--------------------------------------------------------------------------------

section("Verifying the report")

local out = run_out or ""

check("the host process exited successfully", run_ok == true)
check("C-side stack checks all passed", out:find("HOST_FAILURES=0", 1, true) ~= nil)
check("Lua-side expectations all passed", out:find("LUA_FAILURES=0", 1, true) ~= nil)
check("no expectation line reported a failure",
  out:find("EXPECT %[[^%]]-FAIL", 1) == nil)

-- An empty report would otherwise pass every assertion above.
local expect_count = 0
for _ in out:gmatch("EXPECT %[[^%]]+%]") do expect_count = expect_count + 1 end
check(string.format("report carries %d expectations (not an empty report)",
  expect_count), expect_count >= 20)

-- Show which version-specific branch ran, so the reader does not have to guess.
local _, _, version_str = out:find("LUA_VERSION_NUM=(%d+)")
local version_num = tonumber(version_str)
if version_num then
  -- plain search: the strings below are literal, not patterns
  local took_new = out:find("5.3+: luaL_checkinteger", 1, true) ~= nil
  local took_old = out:find("pre-5.3: luaL_checkinteger", 1, true) ~= nil
  print(string.format("  built against LUA_VERSION_NUM=%d (%s)", version_num,
    version_num >= 503 and "integer-subtype aware" or "pre-subtype truncating"))
  check("the matching version branch was exercised",
    version_num >= 503 and took_new or took_old)
else
  check("the host reported the Lua version it was built against", false)
end

--------------------------------------------------------------------------------

print()
print(string.rep("=", 64))
print(string.format("%d checks, %d failures.", checks, failures))
if failures > 0 then
  print("C STACK HOST FAILED")
  os.exit(1)
end
print("All checks passed.")
print(string.rep("=", 64))
print("C STACK HOST OK")
