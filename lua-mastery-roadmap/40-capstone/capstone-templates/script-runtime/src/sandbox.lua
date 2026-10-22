-- sandbox.lua
local M = {}

-- Build a restricted _ENV for a plugin
-- @param original_env  the plugin's current environment
-- @return              a new restricted environment table
function M.build(original_env)
  -- Start with a copy of allowed globals
  local env = {
    -- Safe globals
    print      = print,
    string     = string,
    table      = table,
    math       = math,
    pairs      = pairs,
    ipairs     = ipairs,
    type       = type,
    tostring   = tostring,
    tonumber   = tonumber,
    pcall      = pcall,
    xpcall     = xpcall,
    select     = select,
    unpack     = unpack or table.unpack,
    setmetatable = setmetatable,
    getmetatable = getmetatable,
    coroutine  = coroutine,

    -- Plugin access to event bus (injected by runtime)
    -- event_bus = <injected>

    -- Blocked: os.execute, io, loadstring, load, require (except allowlist)
  }

  -- Add allowlisted modules
  -- env.require = function(name)
  --   if name:match("^utils%.") then
  --     return require(name)
  --   end
  --   error("module not allowed: " .. name, 2)
  -- end

  setmetatable(original_env, { __index = env, __newindex = function(t,k,v)
    error("attempt to set new global: " .. tostring(k), 2)
  end })
  return env
end

return M
