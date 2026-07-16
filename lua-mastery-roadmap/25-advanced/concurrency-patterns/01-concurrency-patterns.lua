--[[
  Example: Concurrency Patterns
  Chapter: Stage 25 — Advanced
  Difficulty: Advanced
  Lua Version: 5.4
  Demonstrates: Actor model, CSP channels, async/await simulation with coroutines
]]

------------------------------------------------------------
-- 1. ACTOR MODEL
------------------------------------------------------------
local Actor = {}
Actor.__index = Actor

function Actor.new(name, handler)
    return setmetatable({
        name = name,
        mailbox = {},
        handler = handler,
        coroutine = nil,
    }, Actor)
end

function Actor:send(message)
    table.insert(self.mailbox, message)
end

function Actor:start()
    self.coroutine = coroutine.create(function()
        while true do
            if #self.mailbox > 0 then
                local msg = table.remove(self.mailbox, 1)
                self.handler(self, msg)
            else
                coroutine.yield()
            end
        end
    end)
end

function Actor:update()
    if self.coroutine then
        coroutine.resume(self.coroutine)
    end
end

local function demo_actor_model()
    print("=== Actor Model ===")
    local pingActor = Actor.new("Ping", function(self, msg)
        if msg.type == "ping" then
            print(string.format("[%s] received ping, sending pong", self.name))
            msg.from:send({ type = "pong", from = self })
        end
    end)

    local pongActor = Actor.new("Pong", function(self, msg)
        if msg.type == "pong" then
            print(string.format("[%s] received pong", self.name))
        end
    end)

    pingActor:start()
    pongActor:start()

    pingActor:send({ type = "ping", from = pongActor })

    for _ = 1, 10 do
        pingActor:update()
        pongActor:update()
    end
    print()
end

------------------------------------------------------------
-- 2. CSP CHANNELS
------------------------------------------------------------
local Channel = {}
Channel.__index = Channel

function Channel.new(bufferSize)
    return setmetatable({
        buffer = {},
        bufferSize = bufferSize or 0,
        senders = {},
        receivers = {},
    }, Channel)
end

function Channel:send(value)
    if #self.buffer < self.bufferSize or self.bufferSize == 0 then
        table.insert(self.buffer, value)
        if #self.receivers > 0 then
            local co = table.remove(self.receivers, 1)
            coroutine.resume(co, table.remove(self.buffer, 1))
        end
        return true
    end
    return false
end

function Channel:receive()
    if #self.buffer > 0 then
        return table.remove(self.buffer, 1)
    end
    table.insert(self.senders, coroutine.running())
    coroutine.yield()
end

local function demo_csp_channels()
    print("=== CSP Channels ===")
    local ch = Channel.new(3)

    local producer = coroutine.create(function()
        for i = 1, 5 do
            print(string.format("[producer] sending %d", i))
            ch:send(i)
            coroutine.yield()
        end
    end)

    local consumer = coroutine.create(function()
        for _ = 1, 5 do
            local val = ch:receive()
            print(string.format("[consumer] received %d", val))
        end
    end)

    coroutine.resume(producer)
    coroutine.resume(consumer)

    for _ = 1, 20 do
        if coroutine.status(producer) == "suspended" then
            coroutine.resume(producer)
        end
        if coroutine.status(consumer) == "suspended" then
            coroutine.resume(consumer)
        end
    end
    print()
end

------------------------------------------------------------
-- 3. ASYNC/AWAIT SIMULATION
------------------------------------------------------------
local function async(fn)
    local co = coroutine.create(fn)
    return co
end

local function await(co, callback)
    local function step()
        local ok, result = coroutine.resume(co)
        if not ok then
            error(result)
        end
        if coroutine.status(co) == "suspended" then
            coroutine.yield(result)
        else
            callback(result)
        end
    end
    step()
end

local function asyncOperation(value)
    return coroutine.create(function()
        coroutine.yield(value * 2)
        return value * 2
    end)
end

local function demo_async_await()
    print("=== Async/Await Simulation ===")
    local function runAsync()
        local co = coroutine.create(function()
            local op = asyncOperation(21)
            local _, val = coroutine.resume(op)
            print(string.format("[async] operation returned: %d", val))
            return val
        end)

        local _, finalVal = coroutine.resume(co)
        print(string.format("[async] final: %s", tostring(finalVal)))
    end
    runAsync()
    print()
end

------------------------------------------------------------
-- MAIN
------------------------------------------------------------
local function main()
    print("Concurrency Patterns in Lua")
    print("Stage 25 — Advanced")
    print("=" .. string.rep("=", 49))
    print()
    demo_actor_model()
    demo_csp_channels()
    demo_async_await()
    print("All concurrency pattern demos complete.")
end

main()
