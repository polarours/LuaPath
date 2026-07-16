--[[
  Example: Deployment Patterns
  Chapter: Stage 28 — Advanced
  Difficulty: Advanced
  Lua Version: 5.4
  Demonstrates: Sandboxing, resource limits, hot-reload, version compatibility
]]

------------------------------------------------------------
-- 1. SANDBOXING
------------------------------------------------------------
local Sandbox = {}

function Sandbox.create(permissions)
    local env = {
        print = permissions.print and print or function() end,
        tostring = tostring,
        tonumber = tonumber,
        type = type,
        error = error,
        assert = assert,
        pcall = pcall,
        ipairs = ipairs,
        pairs = pairs,
        select = select,
        unpack = unpack or table.unpack,
    }

    if permissions.math then
        env.math = math
    end
    if permissions.string then
        env.string = string
    end
    if permissions.table then
        env.table = table
    end

    env._G = env
    return env
end

function Sandbox.execute(code, permissions)
    local env = Sandbox.create(permissions)
    setmetatable(env, { __index = function(_, k)
        error("Access denied: " .. k, 2)
    end})
    local fn, err = load(code, "sandbox", "t", env)
    if not fn then return nil, err end
    return pcall(fn)
end

local function demo_sandboxing()
    print("=== Sandboxing ===")
    local safeEnv = Sandbox.create({
        print = true, math = true, string = true, table = true,
    })

    local ok1, err1 = Sandbox.execute(
        'print("Hello from sandbox!")',
        { print = true, math = true }
    )
    print(string.format("  Safe code: %s", tostring(ok1)))

    local ok2, err2 = Sandbox.execute(
        'os.execute("rm -rf /")',
        { print = true }
    )
    print(string.format("  Unsafe code blocked: %s (error: %s)",
        tostring(ok2), tostring(err2)))
    print()
end

------------------------------------------------------------
-- 2. RESOURCE LIMITS
------------------------------------------------------------
local ResourceLimiter = {}

function ResourceLimiter.create(opts)
    return {
        maxTime = opts.maxTime or 1.0,
        maxMemory = opts.maxMemory or 1024,
        maxOps = opts.maxOps or 10000,
        startTime = os.clock(),
        ops = 0,
    }
end

function ResourceLimiter.wrap(fn, limiter)
    return function(...)
        limiter.ops = limiter.ops + 1
        if limiter.ops > limiter.maxOps then
            error("Resource limit: operations exceeded (" .. limiter.maxOps .. ")")
        end
        if os.clock() - limiter.startTime > limiter.maxTime then
            error("Resource limit: time exceeded")
        end
        local mem = collectgarbage("count")
        if mem > limiter.maxMemory then
            error("Resource limit: memory exceeded")
        end
        return fn(...)
    end
end

local function demo_resource_limits()
    print("=== Resource Limits ===")
    local limiter = ResourceLimiter.create({ maxOps = 5, maxMemory = 2048 })

    local safeAdd = ResourceLimiter.wrap(function(a, b) return a + b end, limiter)

    for i = 1, 4 do
        print(string.format("  call %d: %d", i, safeAdd(i, i + 1)))
    end

    local ok, err = pcall(function()
        for i = 1, 10 do
            safeAdd(i, 1)
        end
    end)
    print(string.format("  call 5 (exceeds limit): ok=%s, err=%s",
        tostring(ok), tostring(err)))
    print()
end

------------------------------------------------------------
-- 3. SCRIPT HOT-RELOAD
------------------------------------------------------------
local HotReloader = {}

function HotReloader.new()
    return setmetatable({
        modules = {},
        versions = {},
    }, { __index = HotReloader })
end

function HotReloader:register(name, code)
    local version = (self.versions[name] or 0) + 1
    self.versions[name] = version
    local fn, err = load(code, name, "t")
    if not fn then return nil, err end
    local module = fn()
    self.modules[name] = { fn = module, version = version, code = code }
    return module, version
end

function HotReloader:reload(name)
    local entry = self.modules[name]
    if not entry then
        return nil, "module not found"
    end
    return self:register(name, entry.code)
end

function HotReloader:version(name)
    local entry = self.modules[name]
    return entry and entry.version or 0
end

local function demo_hot_reload()
    print("=== Script Hot-Reload ===")
    local loader = HotReloader.new()

    local m1, v1 = loader:register("utils", [[
        return { greet = function() return "v1 hello" end }
    ]])
    print(string.format("  loaded utils v%d: %s", v1, m1.greet()))

    loader.modules["utils"].code = [[
        return { greet = function() return "v2 hello" end }
    ]]
    local m2, v2 = loader:reload("utils")
    print(string.format("  reloaded utils v%d: %s", v2, m2.greet()))
    print(string.format("  current version: %d", loader:version("utils")))
    print()
end

------------------------------------------------------------
-- 4. VERSION COMPATIBILITY
------------------------------------------------------------
local VersionCompat = {}

function VersionCompat.check(required)
    local major, minor, patch = string.match(_VERSION, "(%d+)%.(%d+)%.?(%d*)")
    major, minor = tonumber(major), tonumber(minor)
    patch = tonumber(patch) or 0

    local rMajor, rMinor, rPatch = string.match(required, "(%d+)%.(%d+)%.?(%d*)")
    rMajor, rMinor = tonumber(rMajor), tonumber(rMinor)
    rPatch = tonumber(rPatch) or 0

    if major > rMajor then return true end
    if major == rMajor and minor > rMinor then return true end
    if major == rMajor and minor == rMinor and patch >= rPatch then return true end
    return false
end

function VersionCompat.feature(name)
    local features = {
        utf8 = function()
            return utf8 ~= nil
        end,
        generational_gc = function()
            return collectgarbage("isrunning") ~= nil
        end,
        bitwise_ops = function()
            return load("return 1 & 2") ~= nil
        end,
        warnings = function()
            return load("local w = function() end") ~= nil
        end,
    }
    local check = features[name]
    if not check then return false end
    return check()
end

local function demo_version_compat()
    print("=== Version Compatibility ===")
    print(string.format("  Lua version: %s", _VERSION))
    print(string.format("  Requires 5.3: %s",
        tostring(VersionCompat.check("5.3"))))
    print(string.format("  Requires 5.4: %s",
        tostring(VersionCompat.check("5.4"))))

    for _, feat in ipairs({ "utf8", "generational_gc", "bitwise_ops" }) do
        print(string.format("  Feature '%s': %s", feat,
            tostring(VersionCompat.feature(feat))))
    end
    print()
end

------------------------------------------------------------
-- MAIN
------------------------------------------------------------
local function main()
    print("Deployment Patterns in Lua")
    print("Stage 28 — Advanced")
    print("=" .. string.rep("=", 49))
    print()
    demo_sandboxing()
    demo_resource_limits()
    demo_hot_reload()
    demo_version_compat()
    print("All deployment pattern demos complete.")
end

main()
