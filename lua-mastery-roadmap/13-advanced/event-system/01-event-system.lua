--[[
  Example: Event System
  Chapter: 13 — Advanced
  Difficulty: Advanced
  Lua Version: 5.3+
  Demonstrates: pub/sub, priority handlers, once-handlers, wildcard topics, error isolation
]]

local EventBus = {}
EventBus.__index = EventBus

function EventBus.new()
    return setmetatable({ _handlers = {}, _wildcards = {} }, EventBus)
end

local function parse_topic(topic)
    local parts = {}
    for part in topic:gmatch("[^%.]+") do parts[#parts + 1] = part end
    return parts
end

local function topic_matches(pattern_parts, topic_parts)
    for i = 1, math.max(#pattern_parts, #topic_parts) do
        local p, t = pattern_parts[i], topic_parts[i]
        if not p or not t then return false end
        if p ~= "*" and p ~= t then return false end
    end
    return true
end

function EventBus:on(topic, handler, opts)
    opts = opts or {}
    local entry = {
        handler = handler,
        priority = opts.priority or 0,
        once = opts.once or false,
        id = tostring({}):sub(8),
    }
    if topic:find("*") then
        if not self._wildcards[topic] then self._wildcards[topic] = {} end
        self._wildcards[topic][entry.id] = { entry = entry, pattern = parse_topic(topic) }
    else
        if not self._handlers[topic] then self._handlers[topic] = {} end
        self._handlers[topic][entry.id] = entry
    end
    return entry.id
end

function EventBus:once(topic, handler, opts)
    opts = opts or {}
    opts.once = true
    return self:on(topic, handler, opts)
end

function EventBus:off(topic, id)
    if self._handlers[topic] then self._handlers[topic][id] = nil end
    if self._wildcards[topic] then self._wildcards[topic][id] = nil end
end

function EventBus:emit(topic, ...)
    local results = {}
    local topic_parts = parse_topic(topic)

    local function collect(list)
        for _, entry in pairs(list) do
            results[#results + 1] = entry
        end
    end

    if self._handlers[topic] then collect(self._handlers[topic]) end

    for pattern, entries in pairs(self._wildcards) do
        local wp = entries[next(entries)] and entries[next(entries)].pattern
        if wp and topic_matches(wp, topic_parts) then
            for _, e in pairs(entries) do results[#results + 1] = e.entry end
        end
    end

    table.sort(results, function(a, b) return a.priority > b.priority end)

    local to_remove = {}
    for _, entry in ipairs(results) do
        local ok, err = pcall(entry.handler, ...)
        if not ok then
            print(string.format("  [error] Handler on '%s' failed: %s", topic, tostring(err)))
        end
        if entry.once then to_remove[#to_remove + 1] = entry end
    end

    for _, entry in ipairs(to_remove) do
        self:off(topic, entry.id)
    end
    return #results
end

function EventBus:handler_count(topic)
    local count = 0
    if self._handlers[topic] then
        for _ in pairs(self._handlers[topic]) do count = count + 1 end
    end
    for _, entries in pairs(self._wildcards) do
        for _, e in pairs(entries) do
            if topic_matches(e.pattern, parse_topic(topic)) then count = count + 1 end
        end
    end
    return count
end

function main()
    print("=== Event System ===\n")
    local bus = EventBus.new()

    print("--- Priority Ordering ---")
    bus:on("data.ready", function(d) print("  [low]    received:", d) end, { priority = 1 })
    bus:on("data.ready", function(d) print("  [high]   received:", d) end, { priority = 10 })
    bus:on("data.ready", function(d) print("  [medium] received:", d) end, { priority = 5 })
    bus:emit("data.ready", "payload-1")

    print("\n--- Once Handler ---")
    local call_count = 0
    bus:once("data.ready", function(d)
        call_count = call_count + 1
        print(string.format("  [once] call #%d: %s", call_count, d))
    end)
    bus:emit("data.ready", "first")
    bus:emit("data.ready", "second")
    print(string.format("  once handler called %d time(s)", call_count))

    print("\n--- Wildcard Topics ---")
    bus:on("db.*", function(event, data) print(string.format("  [db.*] %s -> %s", event, data)) end)
    bus:on("db.users.*", function(action, id) print(string.format("  [db.users.*] %s id=%s", action, id)) end)
    bus:emit("db.users.created", 42)
    bus:emit("db.orders.placed", "order-7")

    print("\n--- Error Isolation ---")
    bus:on("risky.event", function()
        error("something went wrong!")
    end)
    bus:on("risky.event", function(d)
        print(string.format("  [safe] still running: %s", d))
    end)
    bus:emit("risky.event", "test-data")

    print("\n--- Handler Count ---")
    print(string.format("  handlers for 'data.ready': %d", bus:handler_count("data.ready")))
    print(string.format("  handlers for 'db.*':       %d", bus:handler_count("db.users.created")))

    print("\n=== Done ===")
end

main()

return EventBus
