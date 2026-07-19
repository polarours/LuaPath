-- Lock-Free Queue Implementation
-- Version: Lua 5.4
-- Stage 33: Advanced — Lock-Free Queue

local LockFreeQueue = {}
LockFreeQueue.__index = LockFreeQueue

local function AtomicRef(value)
    return { value = value, version = 0 }
end

local function atomic_load(ref)
    return ref.value, ref.version
end

local function atomic_cas(ref, expected, new_value)
    if ref.value == expected then
        ref.value = new_value
        ref.version = ref.version + 1
        return true
    end
    return false
end

function LockFreeQueue.new()
    local self = setmetatable({}, LockFreeQueue)
    local sentinel = { data = nil, next = AtomicRef(nil) }
    self.head = AtomicRef(sentinel)
    self.tail = AtomicRef(sentinel)
    self.size = 0
    self.stats = { enqueues = 0, dequeues = 0, cas_failures = 0 }
    return self
end

function LockFreeQueue:enqueue(item)
    local node = { data = item, next = AtomicRef(nil) }
    while true do
        local tail = atomic_load(self.tail)
        local tail_next = atomic_load(tail.next)
        if tail_next ~= nil then
            atomic_cas(self.tail, tail, tail_next)
        elseif atomic_cas(tail.next, nil, node) then
            atomic_cas(self.tail, tail, node)
            self.size = self.size + 1
            self.stats.enqueues = self.stats.enqueues + 1
            return true
        else
            self.stats.cas_failures = self.stats.cas_failures + 1
        end
    end
end

function LockFreeQueue:dequeue()
    while true do
        local head = atomic_load(self.head)
        local tail = atomic_load(self.tail)
        local head_next = atomic_load(head.next)
        if head_next == nil then
            return nil, "queue is empty"
        end
        if head == tail then
            atomic_cas(self.tail, tail, head_next)
        else
            local data = head_next.data
            if atomic_cas(self.head, head, head_next) then
                self.size = self.size - 1
                self.stats.dequeues = self.stats.dequeues + 1
                return data
            else
                self.stats.cas_failures = self.stats.cas_failures + 1
            end
        end
    end
end

function LockFreeQueue:is_empty() return self.size == 0 end
function LockFreeQueue:get_size() return self.size end

function LockFreeQueue:get_stats()
    return { enqueues = self.stats.enqueues, dequeues = self.stats.dequeues,
             cas_failures = self.stats.cas_failures, current_size = self.size }
end

local function producer_consumer_demo()
    local queue = LockFreeQueue.new()
    local collected = {}

    local producer = coroutine.create(function(items)
        for _, item in ipairs(items) do
            queue:enqueue(item)
            print(string.format("  [producer] enqueued: %s", item))
            coroutine.yield()
        end
    end)

    local consumer = coroutine.create(function(count)
        for _ = 1, count do
            if not queue:is_empty() then
                local item = queue:dequeue()
                if item then
                    table.insert(collected, item)
                    print(string.format("  [consumer] dequeued: %s", item))
                end
            end
            coroutine.yield()
        end
    end)

    print("=== Lock-Free Queue: Producer/Consumer ===\n")
    local items = {"alpha", "beta", "gamma", "delta", "epsilon"}
    local prod_done, cons_done = false, false

    while not prod_done or not cons_done do
        if not prod_done then
            local ok = coroutine.resume(producer, items)
            if not ok or coroutine.status(producer) == "dead" then prod_done = true end
        end
        if not cons_done then
            local ok = coroutine.resume(consumer, #items)
            if not ok or coroutine.status(consumer) == "dead" then cons_done = true end
        end
    end

    local stats = queue:get_stats()
    print(string.format("\n  Stats: enq=%d deq=%d cas_fails=%d",
        stats.enqueues, stats.dequeues, stats.cas_failures))
    print("  Collected: " .. table.concat(collected, ", "))

    print("\n=== Stress Test ===")
    local stress = LockFreeQueue.new()
    for i = 1, 50 do stress:enqueue(i) end
    assert(stress:get_size() == 50)
    local n = 0
    while not stress:is_empty() do stress:dequeue(); n = n + 1 end
    assert(n == 50)
    local ss = stress:get_stats()
    print(string.format("  50 items round-trip OK. enq=%d deq=%d cas_fails=%d",
        ss.enqueues, ss.dequeues, ss.cas_failures))
end

local function main() producer_consumer_demo() end
main()
