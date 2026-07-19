-- Balking Pattern Implementation
-- Version: Lua 5.4
-- Stage 31: Advanced — Balking

local Balking = {}
Balking.__index = Balking

function Balking.new(opts)
    opts = opts or {}
    local self = setmetatable({}, Balking)
    self._ready = false
    self._initialized = false
    self._closed = false
    self._data = {}
    return self
end

function Balking:is_ready()
    return self._ready and not self._closed
end

function Balking:initialize()
    if self._initialized then
        print("[Balking] Already initialized — skipping")
        return false
    end
    self._ready = true
    self._initialized = true
    print("[Balking] Initialized successfully")
    return true
end

function Balking:write(key, value)
    if not self:is_ready() then
        print(string.format("[Balking] Not ready — skipping write(%s)", key))
        return false
    end
    self._data[key] = value
    print(string.format("[Balking] Wrote %s = %s", key, tostring(value)))
    return true
end

function Balking:read(key)
    if not self:is_ready() then
        print(string.format("[Balking] Not ready — skipping read(%s)", key))
        return nil
    end
    return self._data[key]
end

function Balking:close()
    if self._closed then
        print("[Balking] Already closed — skipping")
        return false
    end
    self._closed = true
    self._ready = false
    print("[Balking] Closed")
    return true
end

function Balking:flush()
    if not self:is_ready() then
        print("[Balking] Not ready — skipping flush")
        return false
    end
    local count = 0
    for _ in pairs(self._data) do count = count + 1 end
    print(string.format("[Balking] Flushed %d entries", count))
    return true
end

-- Guarded writer: balking if predicate fails
local GuardedWriter = {}
GuardedWriter.__index = GuardedWriter

function GuardedWriter.new(predicate)
    local self = setmetatable({}, GuardedWriter)
    self.predicate = predicate or function() return true end
    self._log = {}
    return self
end

function GuardedWriter:write(data)
    if not self.predicate() then
        print("[GuardedWriter] Predicate not met — balking")
        return false
    end
    table.insert(self._log, data)
    print(string.format("[GuardedWriter] Wrote entry #%d", #self._log))
    return true
end

function GuardedWriter:get_log()
    return self._log
end

-- Example usage
local function main()
    print("=== Balking Pattern Demo ===\n")

    -- Demo 1: Resource lifecycle
    local resource = Balking.new()

    print("--- Before initialization ---")
    resource:write("key1", "value1")
    resource:read("key1")

    resource:initialize()

    print("\n--- While ready ---")
    resource:write("key1", "value1")
    resource:write("key2", "value2")
    resource:flush()

    print("\n--- After close ---")
    resource:close()
    resource:write("key3", "value3")
    resource:flush()

    print("\n--- Double init ---")
    resource:initialize()

    -- Demo 2: Guarded writer with changing predicate
    print("\n=== GuardedWriter Demo ===\n")
    local disk_full = false

    local writer = GuardedWriter.new(function()
        return not disk_full
    end)

    writer:write("log entry 1")
    writer:write("log entry 2")

    disk_full = true
    writer:write("log entry 3")  -- balks
    writer:write("log entry 4")  -- balks

    disk_full = false
    writer:write("log entry 5")  -- succeeds

    print("\nTotal entries written:", #writer:get_log())
end

main()
