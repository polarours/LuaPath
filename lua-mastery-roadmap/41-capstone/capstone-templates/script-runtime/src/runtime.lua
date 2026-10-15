-- runtime.lua
local sandbox      = require "sandbox"
local plugin_loader = require "plugin-loader"
local event_bus    = require "event-bus"

local M = {}

local Runtime = {}
Runtime.__index = Runtime

function Runtime.new(config)
  -- config: { plugins_dir, tick_interval }
  return setmetatable({
    _plugins = {},       -- [id] = { ref = module, alive = true }
    _config  = config,
    _bus     = event_bus.new(),
    _errors  = {},
  }, Runtime)
end

function Runtime:load_plugin(path)
  -- 1. require the module (with error isolation)
  -- 2. sandbox.build() the module's env
  -- 3. call M.on_init(config) in pcall
  -- 4. register with event bus
  -- 5. return plugin id
  -- TODO
end

function Runtime:hot_reload(plugin_id)
  -- 1. call M.on_destroy()
  -- 2. remove from require cache
  -- 3. re-require
  -- 4. call M.on_init()
  -- TODO
end

function Runtime:tick(dt)
  for id, p in pairs(self._plugins) do
    if p.alive then
      local ok, err = pcall(p.ref.on_tick, p.ref, dt)
      if not ok then
        table.insert(self._errors, { plugin = id, err = err, time = os.time() })
        p.alive = false
      end
    end
  end
  -- TODO: emit tick event
end

M.Runtime = Runtime
return M
