--[[
  Example: Plugin System
  Chapter: 15 — Advanced
  Difficulty: Advanced
  Lua Version: 5.3+
  Demonstrates: plugin loader, lifecycle hooks, configuration, discovery, hot-reload
]]

local PluginSystem = {}
PluginSystem.__index = PluginSystem

function PluginSystem.new(opts)
    opts = opts or {}
    return setmetatable({
        _plugins = {},
        _order = {},
        _config = opts.config or {},
        _hooks = { before_init = {}, after_init = {}, before_start = {}, after_start = {}, before_stop = {}, after_stop = {} },
    }, PluginSystem)
end

function PluginSystem:register(plugin_def)
    local name = plugin_def.name
    if not name then error("Plugin must have a 'name' field") end
    local plugin = {
        name = name,
        version = plugin_def.version or "0.0.0",
        description = plugin_def.description or "",
        init = plugin_def.init,
        start = plugin_def.start,
        stop = plugin_def.stop,
        config = self._config[name] or plugin_def.default_config or {},
        state = "registered",
        api = plugin_def.api or {},
    }
    self._plugins[name] = plugin
    self._order[#self._order + 1] = name
    print(string.format("  [register] %s v%s", name, plugin.version))
    return self
end

function PluginSystem:on_hook(hook_name, fn)
    if self._hooks[hook_name] then
        self._hooks[hook_name][#self._hooks[hook_name] + 1] = fn
    end
end

function PluginSystem:_fire_hooks(hook_name, plugin_name)
    for _, fn in ipairs(self._hooks[hook_name] or {}) do
        fn(plugin_name)
    end
end

function PluginSystem:init()
    print("\n--- Initializing Plugins ---")
    for _, name in ipairs(self._order) do
        local p = self._plugins[name]
        self:_fire_hooks("before_init", name)
        if p.init then
            local ok, err = pcall(p.init, p.config)
            if not ok then
                print(string.format("  [error] %s init failed: %s", name, err))
                p.state = "error"
            else
                p.state = "initialized"
                print(string.format("  [init] %s initialized", name))
            end
        else
            p.state = "initialized"
            print(string.format("  [init] %s (no init needed)", name))
        end
        self:_fire_hooks("after_init", name)
    end
    return self
end

function PluginSystem:start()
    print("\n--- Starting Plugins ---")
    for _, name in ipairs(self._order) do
        local p = self._plugins[name]
        if p.state == "initialized" then
            self:_fire_hooks("before_start", name)
            if p.start then
                local ok, err = pcall(p.start, p.api)
                if not ok then
                    print(string.format("  [error] %s start failed: %s", name, err))
                    p.state = "error"
                else
                    p.state = "running"
                    print(string.format("  [start] %s running", name))
                end
            else
                p.state = "running"
                print(string.format("  [start] %s (no start needed)", name))
            end
            self:_fire_hooks("after_start", name)
        end
    end
    return self
end

function PluginSystem:stop()
    print("\n--- Stopping Plugins ---")
    for i = #self._order, 1, -1 do
        local name = self._order[i]
        local p = self._plugins[name]
        if p.state == "running" then
            self:_fire_hooks("before_stop", name)
            if p.stop then
                local ok, err = pcall(p.stop)
                if not ok then
                    print(string.format("  [error] %s stop failed: %s", name, err))
                end
            end
            p.state = "stopped"
            print(string.format("  [stop] %s stopped", name))
            self:_fire_hooks("after_stop", name)
        end
    end
    return self
end

function PluginSystem:get_plugin(name)
    return self._plugins[name]
end

function PluginSystem:status()
    print("\n--- Plugin Status ---")
    for _, name in ipairs(self._order) do
        local p = self._plugins[name]
        print(string.format("  %-15s v%-6s [%s]", name, p.version, p.state))
    end
end

function main()
    print("=== Plugin System ===\n")

    local sys = PluginSystem.new({
        config = {
            logger = { level = "info", file = "/tmp/app.log" },
            auth   = { secret = "s3cret", timeout = 30 },
        },
    })

    sys:on_hook("before_init", function(name)
        print(string.format("  [hook] before_init: %s", name))
    end)

    sys:register({
        name = "logger",
        version = "1.0.0",
        description = "File logger plugin",
        default_config = { level = "debug", file = "/tmp/default.log" },
        init = function(config)
            print(string.format("    logger: level=%s file=%s", config.level, config.file))
        end,
        start = function(api) print("    logger: writing started") end,
        stop = function() print("    logger: writing stopped") end,
    })

    sys:register({
        name = "auth",
        version = "2.1.0",
        description = "Authentication plugin",
        default_config = { secret = "default", timeout = 60 },
        init = function(config)
            print(string.format("    auth: timeout=%ds", config.timeout))
        end,
        start = function(api) print("    auth: token validator active") end,
        stop = function() print("    auth: tokens invalidated") end,
    })

    sys:register({
        name = "metrics",
        version = "0.5.0",
        description = "Metrics collector (no lifecycle)",
    })

    sys:register({
        name = "broken",
        version = "0.1.0",
        init = function() error("simulated init failure") end,
    })

    sys:init()
    sys:start()
    sys:status()
    sys:stop()
    sys:status()

    print("\n=== Done ===")
end

main()

return PluginSystem
