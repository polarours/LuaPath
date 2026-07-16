-- Example: Object Pool
-- Stage: 21
-- Difficulty: Advanced
-- Lua Version: 5.1+
--
-- Demonstrates: object reuse, pre-allocation, pool statistics

local Pool = {}
Pool.__index = Pool

function Pool.new(factory, opts)
    opts = opts or {}
    local self = setmetatable({
        factory = factory,
        max_size = opts.max_size or 100,
        pool = {},
        active = 0,
        created = 0,
        reused = 0,
    }, Pool)
    if opts.pre_allocate then
        for i = 1, math.min(opts.pre_allocate, self.max_size) do
            self.pool[i] = self.factory()
            self.created = self.created + 1
        end
    end
    return self
end

function Pool:acquire()
    local obj
    if #self.pool > 0 then
        obj = table.remove(self.pool)
        self.reused = self.reused + 1
    else
        obj = self.factory()
        self.created = self.created + 1
    end
    self.active = self.active + 1
    return obj
end

function Pool:release(obj)
    if self.active <= 0 then return end
    self.active = self.active - 1
    if #self.pool < self.max_size then
        self.pool[#self.pool + 1] = obj
    end
end

function Pool:stats()
    return {
        pool_size = #self.pool,
        active = self.active,
        created = self.created,
        reused = self.reused,
        reuse_ratio = self.created > 0 and (self.reused / (self.created + self.reused)) or 0,
    }
end

local function main()
    print("=== Object Pool ===\n")

    local id = 0
    local pool = Pool.new(function()
        id = id + 1
        return { id = id, data = nil }
    end, { max_size = 5, pre_allocate = 3 })

    print("--- Acquire 5 objects ---")
    local objs = {}
    for i = 1, 5 do
        objs[i] = pool:acquire()
        print(string.format("Object %d: id=%d", i, objs[i].id))
    end

    print("\n--- Release 3 objects ---")
    for i = 1, 3 do
        pool:release(objs[i])
        print(string.format("Released object %d", objs[i].id))
    end

    print("\n--- Acquire 3 more (should reuse) ---")
    for i = 1, 3 do
        objs[i] = pool:acquire()
        print(string.format("Object %d: id=%d", i, objs[i].id))
    end

    local s = pool:stats()
    print("\n--- Pool Stats ---")
    print(string.format("Pool size: %d", s.pool_size))
    print(string.format("Active: %d", s.active))
    print(string.format("Created: %d", s.created))
    print(string.format("Reused: %d", s.reused))
    print(string.format("Reuse ratio: %.1f%%", s.reuse_ratio * 100))

    print("\n=== Done ===")
end

main()
