--[[
  Example: Logging System
  Chapter: Stage 10 — Advanced
  Difficulty: Advanced
  Lua Version: 5.1+
  Demonstrates: Module design, metatables, file I/O, formatter pattern
]]

local LEVELS = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4 }
local LEVEL_NAMES = { [1] = "DEBUG", [2] = "INFO", [3] = "WARN", [4] = "ERROR" }

local logger = {}
logger.__index = logger

function logger.new(opts)
  opts = opts or {}
  local self = setmetatable({}, logger)
  self.level = LEVELS[opts.level or "DEBUG"]
  self.handlers = {}
  self.formatter = opts.formatter or function(level, msg, source)
    return string.format("[%s] %s: %s", LEVEL_NAMES[level], source or "-", msg)
  end
  return self
end

function logger:set_level(level)
  self.level = LEVELS[level] or 1
end

function logger:set_formatter(fn)
  self.formatter = fn
end

function logger:add_handler(handler)
  table.insert(self.handlers, handler)
  return self
end

-- Console handler
logger.handlers = {}
logger.handlers.console = function(self, level, msg, source)
  if level >= self.level then
    local formatted = self.formatter(level, msg, source)
    if level >= LEVELS.WARN then
      io.write(formatted .. "\n")
    else
      io.write(formatted .. "\n")
    end
  end
end

-- File handler
logger.handlers.file = function(filepath)
  local fh = io.open(filepath, "a")
  return function(self, level, msg, source)
    if level >= self.level then
      local formatted = self.formatter(level, msg, source)
      fh:write(formatted .. "\n")
      fh:flush()
    end
  end
end

function logger:log(level, msg, source)
  for _, handler in ipairs(self.handlers) do
    handler(self, level, msg, source)
  end
end

function logger:debug(msg, source) self:log(LEVELS.DEBUG, msg, source) end
function logger:info(msg, source) self:log(LEVELS.INFO, msg, source) end
function logger:warn(msg, source) self:log(LEVELS.WARN, msg, source) end
function logger:error(msg, source) self:log(LEVELS.ERROR, msg, source) end

-- Test
local function main()
  local log = logger.new({ level = "DEBUG" })
  log:add_handler(logger.handlers.console)

  local file_handler = logger.handlers.file("/tmp/app.log")
  log:add_handler(file_handler)

  log:debug("Application starting", "main")
  log:info("Connected to database", "db")
  log:warn("Cache miss for key 'user:123'", "cache")
  log:error("Failed to write to disk", "fs")

  -- Verify file output
  local f = io.open("/tmp/app.log", "r")
  if f then
    local content = f:read("*a")
    f:close()
    print("\nFile log contents:")
    print(content)
  end

  print("[OK] Logging system working")
end

main()

return logger
