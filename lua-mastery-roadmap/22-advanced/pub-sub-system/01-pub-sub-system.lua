-- Example: Pub-Sub System
-- Stage: 22
-- Difficulty: Advanced
-- Lua Version: 5.1+
--
-- Demonstrates: topic-based pub/sub, wildcard subscriptions, message routing

local PubSub = {}
PubSub.__index = PubSub

function PubSub.new()
    return setmetatable({ subscribers = {}, history = {} }, PubSub)
end

function PubSub:subscribe(topic, callback)
    local subs = self.subscribers[topic]
    if not subs then
        subs = {}
        self.subscribers[topic] = subs
    end
    subs[#subs + 1] = callback
    return function()
        for i, cb in ipairs(subs) do
            if cb == callback then
                table.remove(subs, i)
                return true
            end
        end
        return false
    end
end

function PubSub:publish(topic, data)
    self.history[#self.history + 1] = { topic = topic, data = data, time = os.time() }
    local delivered = 0
    for pattern, subs in pairs(self.subscribers) do
        if self:match_topic(pattern, topic) then
            for _, callback in ipairs(subs) do
                local ok, err = pcall(callback, topic, data)
                if not ok then
                    print(string.format("  [ERROR] %s: %s", topic, err))
                else
                    delivered = delivered + 1
                end
            end
        end
    end
    return delivered
end

function PubSub:match_topic(pattern, topic)
    if pattern == "#" then return true end
    if pattern == topic then return true end
    if pattern:sub(-2) == ".#" then
        local prefix = pattern:sub(1, -3)
        return topic:sub(1, #prefix) == prefix
    end
    return false
end

function PubSub:subscriber_count(topic)
    local count = 0
    for pattern, subs in pairs(self.subscribers) do
        if self:match_topic(pattern, topic) then
            count = count + #subs
        end
    end
    return count
end

local function main()
    print("=== Pub-Sub System ===\n")

    local bus = PubSub.new()

    local unsub1 = bus:subscribe("user.created", function(topic, data)
        print(string.format("  [user.created] Welcome %s!", data.name))
    end)

    bus:subscribe("user.created", function(topic, data)
        print(string.format("  [user.created] Log: new user %s", data.name))
    end)

    bus:subscribe("user.*", function(topic, data)
        print(string.format("  [user.*] Event: %s", topic))
    end)

    bus:subscribe("#", function(topic, data)
        print(string.format("  [#] Audit: %s", topic))
    end)

    print("--- Publish user.created ---")
    bus:publish("user.created", { name = "Alice" })

    print("\n--- Unsubscribe one handler ---")
    unsub1()
    bus:publish("user.created", { name = "Bob" })

    print("\n--- Publish order.placed ---")
    bus:publish("order.placed", { id = 1001 })

    print("\n--- Subscriber count ---")
    print("user.created:", bus:subscriber_count("user.created"))
    print("user.*:", bus:subscriber_count("user.*"))

    print("\n=== Done ===")
end

main()
