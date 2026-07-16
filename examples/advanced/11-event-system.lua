-- Example 11: Event System
-- Chapter: 11-advanced
-- Difficulty: Advanced
-- Lua Version: 5.1+
--
-- Demonstrates: event bus with priority, once handlers, unsubscribe, error isolation
-- Shows: pub/sub, wildcard topics, event history, typed events

local M = {}

function M.new_bus()
    local bus = {
        handlers = {},      -- topic -> { {fn, priority, once, id} }
        history = {},        -- { {topic, data, time} }
        next_id = 1,
        max_history = 100,
    }

    -- Subscribe to a topic
    function bus:on(topic, fn, opts)
        opts = opts or {}
        local id = self.next_id
        self.next_id = self.next_id + 1
        self.handlers[topic] = self.handlers[topic] or {}
        table.insert(self.handlers[topic], {
            fn = fn,
            priority = opts.priority or 0,
            once = opts.once or false,
            id = id,
        })
        -- Sort by priority (higher first)
        table.sort(self.handlers[topic], function(a, b)
            return a.priority > b.priority
        end)
        -- Return unsubscribe function
        return function()
            self:off(topic, id)
        end
    end

    -- Subscribe for one emission only
    function bus:once(topic, fn, opts)
        return self:on(topic, fn, vim and vim.tbl_extend("force", opts or {}, { once = true }) or { once = true, priority = (opts or {}).priority })
    end

    -- Unsubscribe by id
    function bus:off(topic, id)
        local list = self.handlers[topic]
        if not list then return end
        for i = #list, 1, -1 do
            if list[i].id == id then
                table.remove(list, i)
                return true
            end
        end
        return false
    end

    -- Emit an event with error isolation
    function bus:emit(topic, data)
        -- Record history
        self.history[#self.history + 1] = {
            topic = topic,
            data = data,
            time = os.time(),
        }
        if #self.history > self.max_history then
            table.remove(self.history, 1)
        end

        -- Collect matching handlers (exact + wildcard)
        local to_call = {}
        local list = self.handlers[topic] or {}
        for _, h in ipairs(list) do
            to_call[#to_call + 1] = h
        end
        -- Wildcard: "user.*" matches "user.created"
        for t, handlers in pairs(self.handlers) do
            if t ~= topic and t:match("%*") then
                local pattern = t:gsub("%*", ".*")
                if topic:match(pattern) then
                    for _, h in ipairs(handlers) do
                        to_call[#to_call + 1] = h
                    end
                end
            end
        end

        -- Execute with error isolation
        local results = {}
        local to_remove = {}
        for _, h in ipairs(to_call) do
            local ok, err = pcall(h.fn, data, topic)
            if not ok then
                print(string.format("  [ERROR] Handler %d on '%s': %s", h.id, topic, tostring(err)))
            end
            results[#results + 1] = ok
            if h.once then
                to_remove[#to_remove + 1] = { topic = topic, id = h.id }
            end
        end

        -- Remove once-handlers
        for _, r in ipairs(to_remove) do
            self:off(r.topic, r.id)
        end

        return results
    end

    -- Get history for a topic
    function bus:get_history(topic, limit)
        local result = {}
        for i = #self.history, 1, -1 do
            if not topic or self.history[i].topic == topic then
                result[#result + 1] = self.history[i]
                if limit and #result >= limit then break end
            end
        end
        return result
    end

    -- List active handlers
    function bus:list_handlers()
        local count = 0
        for topic, handlers in pairs(self.handlers) do
            for _, h in ipairs(handlers) do
                count = count + 1
                print(string.format("  [%d] %s (priority=%d%s)",
                    h.id, topic, h.priority, h.once and ", once" or ""))
            end
        end
        return count
    end

    -- Clear all handlers
    function bus:clear()
        self.handlers = {}
        self.history = {}
    end

    return bus
end

function M.demo_basic_pubsub()
    print("=== Basic Pub/Sub ===")
    local bus = M.new_bus()

    bus:on("message", function(data)
        print(string.format("  Received: %s", data))
    end)

    bus:emit("message", "Hello, World!")
    bus:emit("message", "Second message")
    print()
end

function M.demo_priority()
    print("=== Priority Handling ===")
    local bus = M.new_bus()

    bus:on("request", function(data)
        print(string.format("  [low]   处理: %s", data))
    end, { priority = 1 })

    bus:on("request", function(data)
        print(string.format("  [high]   处理: %s", data))
    end, { priority = 10 })

    bus:on("request", function(data)
        print(string.format("  [medium] 处理: %s", data))
    end, { priority = 5 })

    bus:emit("request", "task-A")
    print("  (higher priority runs first)")
    print()
end

function M.demo_once()
    print("=== Once Handler ===")
    local bus = M.new_bus()
    local call_count = 0

    bus:once("init", function(data)
        call_count = call_count + 1
        print(string.format("  Init handler called (count=%d)", call_count))
    end)

    bus:emit("init", "start")
    bus:emit("init", "again")
    bus:emit("init", "once more")
    print(string.format("  Total calls: %d (expected 1)", call_count))
    print()
end

function M.demo_unsubscribe()
    print("=== Unsubscribe ===")
    local bus = M.new_bus()
    local count = 0

    local unsub = bus:on("tick", function()
        count = count + 1
        print(string.format("  Tick %d", count))
    end)

    bus:emit("tick", nil)  -- count=1
    bus:emit("tick", nil)  -- count=2
    unsub()
    bus:emit("tick", nil)  -- no change
    print(string.format("  After unsub: %d (expected 2)", count))
    print()
end

function M.demo_error_isolation()
    print("=== Error Isolation ===")
    local bus = M.new_bus()

    bus:on("data", function(d)
        print(string.format("  Handler A: %s", d))
    end)

    bus:on("data", function(d)
        error("intentional error!")
    end)

    bus:on("data", function(d)
        print(string.format("  Handler C: %s (still runs!)", d))
    end)

    bus:emit("data", "test")
    print("  All handlers ran despite error in B")
    print()
end

function M.demo_wildcard()
    print("=== Wildcard Topics ===")
    local bus = M.new_bus()

    bus:on("user.*", function(data, topic)
        print(string.format("  [user.*] %s: %s", topic, data))
    end)

    bus:emit("user.created", "alice")
    bus:emit("user.updated", "bob")
    bus:emit("post.created", "post-1")  -- not matched
    print()
end

function M.demo_history()
    print("=== Event History ===")
    local bus = M.new_bus()

    bus:emit("click", { x = 10, y = 20 })
    bus:emit("click", { x = 30, y = 40 })
    bus:emit("hover", { target = "button" })

    local click_history = bus:get_history("click", 1)
    print(string.format("  Last click: x=%d y=%d", click_history[1].data.x, click_history[1].data.y))

    local all_history = bus:get_history(nil, 2)
    print(string.format("  Last 2 events: %d total stored", #all_history))
    print()
end

function M.demo_typed_events()
    print("=== Typed Events (Simulated) ===")
    local bus = M.new_bus()

    local types = {
        LOGIN  = "user.login",
        LOGOUT = "user.logout",
        ERROR  = "system.error",
    }

    bus:on(types.LOGIN, function(data)
        print(string.format("  User logged in: %s", data.user))
    end)

    bus:on(types.LOGOUT, function(data)
        print(string.format("  User logged out: %s", data.user))
    end)

    bus:on(types.ERROR, function(data)
        print(string.format("  Error: %s (code=%d)", data.msg, data.code))
    end)

    bus:emit(types.LOGIN, { user = "alice" })
    bus:emit(types.ERROR, { msg = "disk full", code = 507 })
    bus:emit(types.LOGOUT, { user = "alice" })
    print()
end

function M.main()
    print("Event System in Lua")
    print(string.rep("=", 40))
    print()

    M.demo_basic_pubsub()
    M.demo_priority()
    M.demo_once()
    M.demo_unsubscribe()
    M.demo_error_isolation()
    M.demo_wildcard()
    M.demo_history()
    M.demo_typed_events()

    print("=== Design Notes ===")
    print("- Priority determines execution order (higher first)")
    print("- Once handlers auto-remove after first emit")
    print("- pcall isolation prevents one bad handler from breaking others")
    print("- Wildcards use Lua patterns: 'user.*' matches 'user.created'")
    print("- History is bounded (max_history) to prevent memory growth")
    print()
end

M.main()
return M
