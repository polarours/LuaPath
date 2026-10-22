#!/usr/bin/env lua

-- check-stdlib-names.lua
-- Checks that every standard library member the documentation names actually
-- exists.
--
-- A chapter that tells the reader to call `os.sleep` or `math.clamp` is
-- teaching a function that is not in any Lua: the snippet fails, and the
-- reader has no way to tell the difference between a typo and a version
-- difference. The inventory in this file is the set of members the five
-- supported runtimes actually provide.
--
-- A member that exists in only some of them is not an error -- `table.move`
-- is 5.3+ and `table.maxn` is 5.1 -- but the text has to say which.
--
-- Usage: lua scripts/check-stdlib-names.lua

local INVENTORY = {
  ["5.1"] = {
    "coroutine.create", "coroutine.resume", "coroutine.running", "coroutine.status", "coroutine.wrap",
    "coroutine.yield", "debug.debug", "debug.getfenv", "debug.gethook", "debug.getinfo",
    "debug.getlocal", "debug.getmetatable", "debug.getregistry", "debug.getupvalue", "debug.setfenv",
    "debug.sethook", "debug.setlocal", "debug.setmetatable", "debug.setupvalue", "debug.traceback",
    "io.close", "io.flush", "io.input", "io.lines", "io.open",
    "io.output", "io.popen", "io.read", "io.stderr", "io.stdin",
    "io.stdout", "io.tmpfile", "io.type", "io.write", "math.abs",
    "math.acos", "math.asin", "math.atan", "math.atan2", "math.ceil",
    "math.cos", "math.cosh", "math.deg", "math.exp", "math.floor",
    "math.fmod", "math.frexp", "math.huge", "math.ldexp", "math.log",
    "math.log10", "math.max", "math.min", "math.mod", "math.modf",
    "math.pi", "math.pow", "math.rad", "math.random", "math.randomseed",
    "math.sin", "math.sinh", "math.sqrt", "math.tan", "math.tanh",
    "os.clock", "os.date", "os.difftime", "os.execute", "os.exit",
    "os.getenv", "os.remove", "os.rename", "os.setlocale", "os.time",
    "os.tmpname", "package.config", "package.cpath", "package.loaded", "package.loaders",
    "package.loadlib", "package.path", "package.preload", "package.seeall", "string.byte",
    "string.char", "string.dump", "string.find", "string.format", "string.gfind",
    "string.gmatch", "string.gsub", "string.len", "string.lower", "string.match",
    "string.rep", "string.reverse", "string.sub", "string.upper", "table.concat",
    "table.foreach", "table.foreachi", "table.getn", "table.insert", "table.maxn",
    "table.remove", "table.setn", "table.sort",
  },
  ["5.3"] = {
    "coroutine.create", "coroutine.isyieldable", "coroutine.resume", "coroutine.running", "coroutine.status",
    "coroutine.wrap", "coroutine.yield", "debug.debug", "debug.gethook", "debug.getinfo",
    "debug.getlocal", "debug.getmetatable", "debug.getregistry", "debug.getupvalue", "debug.getuservalue",
    "debug.sethook", "debug.setlocal", "debug.setmetatable", "debug.setupvalue", "debug.setuservalue",
    "debug.traceback", "debug.upvalueid", "debug.upvaluejoin", "io.close", "io.flush",
    "io.input", "io.lines", "io.open", "io.output", "io.popen",
    "io.read", "io.stderr", "io.stdin", "io.stdout", "io.tmpfile",
    "io.type", "io.write", "math.abs", "math.acos", "math.asin",
    "math.atan", "math.atan2", "math.ceil", "math.cos", "math.cosh",
    "math.deg", "math.exp", "math.floor", "math.fmod", "math.frexp",
    "math.huge", "math.ldexp", "math.log", "math.log10", "math.max",
    "math.maxinteger", "math.min", "math.mininteger", "math.modf", "math.pi",
    "math.pow", "math.rad", "math.random", "math.randomseed", "math.sin",
    "math.sinh", "math.sqrt", "math.tan", "math.tanh", "math.tointeger",
    "math.type", "math.ult", "os.clock", "os.date", "os.difftime",
    "os.execute", "os.exit", "os.getenv", "os.remove", "os.rename",
    "os.setlocale", "os.time", "os.tmpname", "package.config", "package.cpath",
    "package.loaded", "package.loadlib", "package.path", "package.preload", "package.searchers",
    "package.searchpath", "string.byte", "string.char", "string.dump", "string.find",
    "string.format", "string.gmatch", "string.gsub", "string.len", "string.lower",
    "string.match", "string.pack", "string.packsize", "string.rep", "string.reverse",
    "string.sub", "string.unpack", "string.upper", "table.concat", "table.insert",
    "table.move", "table.pack", "table.remove", "table.sort", "table.unpack",
    "utf8.char", "utf8.charpattern", "utf8.codepoint", "utf8.codes", "utf8.len",
    "utf8.offset",
  },
  ["5.4"] = {
    "coroutine.close", "coroutine.create", "coroutine.isyieldable", "coroutine.resume", "coroutine.running",
    "coroutine.status", "coroutine.wrap", "coroutine.yield", "debug.debug", "debug.gethook",
    "debug.getinfo", "debug.getlocal", "debug.getmetatable", "debug.getregistry", "debug.getupvalue",
    "debug.getuservalue", "debug.setcstacklimit", "debug.sethook", "debug.setlocal", "debug.setmetatable",
    "debug.setupvalue", "debug.setuservalue", "debug.traceback", "debug.upvalueid", "debug.upvaluejoin",
    "io.close", "io.flush", "io.input", "io.lines", "io.open",
    "io.output", "io.popen", "io.read", "io.stderr", "io.stdin",
    "io.stdout", "io.tmpfile", "io.type", "io.write", "math.abs",
    "math.acos", "math.asin", "math.atan", "math.atan2", "math.ceil",
    "math.cos", "math.cosh", "math.deg", "math.exp", "math.floor",
    "math.fmod", "math.frexp", "math.huge", "math.ldexp", "math.log",
    "math.log10", "math.max", "math.maxinteger", "math.min", "math.mininteger",
    "math.modf", "math.pi", "math.pow", "math.rad", "math.random",
    "math.randomseed", "math.sin", "math.sinh", "math.sqrt", "math.tan",
    "math.tanh", "math.tointeger", "math.type", "math.ult", "os.clock",
    "os.date", "os.difftime", "os.execute", "os.exit", "os.getenv",
    "os.remove", "os.rename", "os.setlocale", "os.time", "os.tmpname",
    "package.config", "package.cpath", "package.loaded", "package.loadlib", "package.path",
    "package.preload", "package.searchers", "package.searchpath", "string.byte", "string.char",
    "string.dump", "string.find", "string.format", "string.gmatch", "string.gsub",
    "string.len", "string.lower", "string.match", "string.pack", "string.packsize",
    "string.rep", "string.reverse", "string.sub", "string.unpack", "string.upper",
    "table.concat", "table.insert", "table.move", "table.pack", "table.remove",
    "table.sort", "table.unpack", "utf8.char", "utf8.charpattern", "utf8.codepoint",
    "utf8.codes", "utf8.len", "utf8.offset",
  },
  ["5.5"] = {
    "coroutine.close", "coroutine.create", "coroutine.isyieldable", "coroutine.resume", "coroutine.running",
    "coroutine.status", "coroutine.wrap", "coroutine.yield", "debug.debug", "debug.gethook",
    "debug.getinfo", "debug.getlocal", "debug.getmetatable", "debug.getregistry", "debug.getupvalue",
    "debug.getuservalue", "debug.sethook", "debug.setlocal", "debug.setmetatable", "debug.setupvalue",
    "debug.setuservalue", "debug.traceback", "debug.upvalueid", "debug.upvaluejoin", "io.close",
    "io.flush", "io.input", "io.lines", "io.open", "io.output",
    "io.popen", "io.read", "io.stderr", "io.stdin", "io.stdout",
    "io.tmpfile", "io.type", "io.write", "math.abs", "math.acos",
    "math.asin", "math.atan", "math.ceil", "math.cos", "math.deg",
    "math.exp", "math.floor", "math.fmod", "math.frexp", "math.huge",
    "math.ldexp", "math.log", "math.max", "math.maxinteger", "math.min",
    "math.mininteger", "math.modf", "math.pi", "math.rad", "math.random",
    "math.randomseed", "math.sin", "math.sqrt", "math.tan", "math.tointeger",
    "math.type", "math.ult", "os.clock", "os.date", "os.difftime",
    "os.execute", "os.exit", "os.getenv", "os.remove", "os.rename",
    "os.setlocale", "os.time", "os.tmpname", "package.config", "package.cpath",
    "package.loaded", "package.loadlib", "package.path", "package.preload", "package.searchers",
    "package.searchpath", "string.byte", "string.char", "string.dump", "string.find",
    "string.format", "string.gmatch", "string.gsub", "string.len", "string.lower",
    "string.match", "string.pack", "string.packsize", "string.rep", "string.reverse",
    "string.sub", "string.unpack", "string.upper", "table.concat", "table.create",
    "table.insert", "table.move", "table.pack", "table.remove", "table.sort",
    "table.unpack", "utf8.char", "utf8.charpattern", "utf8.codepoint", "utf8.codes",
    "utf8.len", "utf8.offset",
  },
  ["luajit"] = {
    "coroutine.create", "coroutine.isyieldable", "coroutine.resume", "coroutine.running", "coroutine.status",
    "coroutine.wrap", "coroutine.yield", "debug.debug", "debug.getfenv", "debug.gethook",
    "debug.getinfo", "debug.getlocal", "debug.getmetatable", "debug.getregistry", "debug.getupvalue",
    "debug.setfenv", "debug.sethook", "debug.setlocal", "debug.setmetatable", "debug.setupvalue",
    "debug.traceback", "debug.upvalueid", "debug.upvaluejoin", "io.close", "io.flush",
    "io.input", "io.lines", "io.open", "io.output", "io.popen",
    "io.read", "io.stderr", "io.stdin", "io.stdout", "io.tmpfile",
    "io.type", "io.write", "math.abs", "math.acos", "math.asin",
    "math.atan", "math.atan2", "math.ceil", "math.cos", "math.cosh",
    "math.deg", "math.exp", "math.floor", "math.fmod", "math.frexp",
    "math.huge", "math.ldexp", "math.log", "math.log10", "math.max",
    "math.min", "math.modf", "math.pi", "math.pow", "math.rad",
    "math.random", "math.randomseed", "math.sin", "math.sinh", "math.sqrt",
    "math.tan", "math.tanh", "os.clock", "os.date", "os.difftime",
    "os.execute", "os.exit", "os.getenv", "os.remove", "os.rename",
    "os.setlocale", "os.time", "os.tmpname", "package.config", "package.cpath",
    "package.loaded", "package.loaders", "package.loadlib", "package.path", "package.preload",
    "package.searchpath", "package.seeall", "string.byte", "string.char", "string.dump",
    "string.find", "string.format", "string.gmatch", "string.gsub", "string.len",
    "string.lower", "string.match", "string.rep", "string.reverse", "string.sub",
    "string.upper", "table.concat", "table.foreach", "table.foreachi", "table.getn",
    "table.insert", "table.maxn", "table.move", "table.remove", "table.sort",
  },
}

-- The libraries the documents talk about.
local LIBS = {
  string = true, table = true, math = true, os = true, io = true,
  coroutine = true, debug = true, package = true, utf8 = true,
}

-- File names end in these, and "05-readonly-table.lua" is not a member call.
local EXTENSIONS = {
  ["lua"] = true, ["md"] = true, ["c"] = true, ["h"] = true, ["txt"] = true,
  ["json"] = true, ["ini"] = true, ["yml"] = true, ["yaml"] = true, ["so"] = true,
  ["zip"] = true, ["rockspec"] = true, ["sh"] = true,
}

local function read_file(path)
  local fh = io.open(path, "r")
  if not fh then return nil end
  local content = fh:read("*a")
  fh:close()
  return content
end

local function list_files(dir, pattern)
  local out = {}
  local ok, pipe = pcall(io.popen, string.format(
    "find %s -type f -name '%s' | sort", "'" .. dir:gsub("'", "'\\''") .. "'", pattern))
  if not ok or not pipe then return out end
  for path in pipe:lines() do out[#out + 1] = path end
  pipe:close()
  return out
end

-- The union of every supported runtime, and the runtimes each member is in.
local known = {}
for _, members in pairs(INVENTORY) do
  for _, name in ipairs(members) do
    known[name] = true
  end
end

local errors = 0
local checked = 0

local directories = { "en", "zh", "pitfalls/en", "pitfalls/中文版", "references" }
for _, dir in ipairs(directories) do
  for _, path in ipairs(list_files(dir, "*.md")) do
    local content = read_file(path)
    if content then
      -- The character in front of the library name has to be a word
      -- boundary, so that "05-readonly-table.lua" is not read as a call to
      -- table.lua.
      for _, lib, member in content:gmatch("([^%w_%-])([%a]+)%.([%a][%w_]*)") do
        if LIBS[lib] and not EXTENSIONS[member:lower()] then
          local name = lib .. "." .. member
          checked = checked + 1
          if not known[name] then
            errors = errors + 1
            print(string.format("  %s: %s does not exist in any supported runtime", path, name))
          end
        end
      end
    end
  end
end

print()
print("Summary")
print("-------")
print(string.format("Names checked:    %d", checked))
print(string.format("Mismatched:        %d", errors))
print()

if errors > 0 then
  print("STDLIB NAME CHECK FAILED")
  os.exit(1)
end

print("STDLIB NAME CHECK PASSED")
