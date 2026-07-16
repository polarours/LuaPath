-- Example 11: Module Patterns
-- Chapter: 10-modules
-- Difficulty: Intermediate
-- Lua Version: 5.1+
--
-- Demonstrates: module design, require caching, stateful vs stateless modules

--- Pattern 1: Stateless utility module
-- Functions only, no internal state — safe to share across consumers
local MathUtils = {}

function MathUtils.clamp(val, lo, hi)
  return math.max(lo, math.min(hi, val))
end

function MathUtils.lerp(a, b, t)
  return a + (b - a) * t
end

function MathUtils.round(n, decimals)
  local mult = 10 ^ (decimals or 0)
  return math.floor(n * mult + 0.5) / mult
end

function MathUtils.average(t)
  local sum = 0
  for _, v in ipairs(t) do sum = sum + v end
  return sum / #t
end

--- Pattern 2: Stateful service module
-- Returns a constructor; each instance holds its own state
local Counter = {}
Counter.__index = Counter

function Counter.new(start)
  return setmetatable({value = start or 0, history = {}}, Counter)
end

function Counter:increment(n)
  n = n or 1
  self.value = self.value + n
  self.history[#self.history + 1] = self.value
  return self.value
end

function Counter:decrement(n)
  return self:increment(-(n or 1))
end

function Counter:current() return self.value end

function Counter:get_history()
  local copy = {}
  for i, v in ipairs(self.history) do copy[i] = v end
  return copy
end

--- Pattern 3: Factory module
-- Creates specialized objects via a factory function
local Logger = {}
Logger.__index = Logger

function Logger.new(name, level)
  level = level or "INFO"
  return setmetatable({name = name, level = level, entries = {}}, Logger)
end

local LEVELS = {DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4}

function Logger:log(msg, lvl)
  lvl = lvl or "INFO"
  if LEVELS[lvl] >= LEVELS[self.level] then
    local entry = string.format("[%s] %s: %s", lvl, self.name, msg)
    self.entries[#self.entries + 1] = entry
    return entry
  end
  return nil
end

function Logger:dump()
  for _, e in ipairs(self.entries) do print("  " .. e) end
end

--- Demonstrate require caching and package.loaded
local function demo_require_caching()
  print("3. Require Caching (package.loaded):")
  -- package.loaded tracks loaded modules; require returns cached entry
  local m1 = require("math")
  local m2 = require("math")
  print(string.format("  math loaded: %s", tostring(m1 == m2)))

  -- Fake module in package.loaded
  local fake_name = "my_fake_module_" .. tostring({})
  package.loaded[fake_name] = {value = 42}
  local loaded = require(fake_name)
  print(string.format("  Fake module value: %d", loaded.value))
  package.loaded[fake_name] = nil
end

local function main()
  print("=== Module Patterns ===\n")

  -- 1. Stateless utility
  print("1. Stateless Utility Module:")
  print(string.format("  clamp(15, 0, 10) = %d", MathUtils.clamp(15, 0, 10)))
  print(string.format("  lerp(0, 100, 0.3) = %g", MathUtils.lerp(0, 100, 0.3)))
  print(string.format("  round(3.14159, 2) = %g", MathUtils.round(3.14159, 2)))
  print(string.format("  average({10,20,30}) = %g", MathUtils.average({10, 20, 30})))

  -- 2. Stateful service
  print("\n2. Stateful Service Module (Counter):")
  local c1 = Counter.new(0)
  local c2 = Counter.new(100)
  c1:increment(5)
  c1:increment(3)
  c1:decrement(2)
  print(string.format("  c1: current=%d, history={%s}",
    c1:current(), table.concat(c1:get_history(), ", ")))
  print(string.format("  c2: current=%d (independent)", c2:current()))

  -- 3. Factory module
  print("\n3. Factory Module (Logger):")
  local app_log = Logger.new("app", "DEBUG")
  local db_log = Logger.new("db", "WARN")
  app_log:log("started", "INFO")
  app_log:log("debugging", "DEBUG")
  app_log:log("something broke", "ERROR")
  db_log:log("query slow", "WARN")
  db_log:log("this should not appear", "DEBUG")
  print("  App logger:")
  app_log:dump()
  print("  DB logger (WARN+ only):")
  db_log:dump()

  -- 4. Require caching
  print("")
  demo_require_caching()

  print("\n✓ All module pattern demos completed!")
end

main()
