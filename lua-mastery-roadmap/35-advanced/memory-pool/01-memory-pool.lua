-- Memory Pool Implementation
-- Version: Lua 5.4
-- Stage 35: Advanced — Memory Pool

local MemoryPool = {}
MemoryPool.__index = MemoryPool

function MemoryPool.new(opts)
    opts = opts or {}
    local self = setmetatable({}, MemoryPool)
    self.factory = opts.factory or function() return {} end
    self.reset_fn = opts.reset or function(o) return o end
    self.min_size = opts.min_size or 8
    self.max_size = opts.max_size or 64
    self.growth = opts.growth_factor or 2
    self.available = {}
    self.in_use = {}
    self.stats = { acquired = 0, released = 0, grown = 0, hits = 0, misses = 0 }
    self:_fill(self.min_size)
    return self
end

function MemoryPool:_fill(n)
    for _ = 1, n do table.insert(self.available, self.factory()) end
end

function MemoryPool:acquire()
    if #self.available == 0 then
        local total = self:_count_used()
        if total < self.max_size then
            self:_fill(math.min(self.growth, self.max_size - total))
        else
            self:_fill(self.growth)
        end
        self.stats.grown = self.stats.grown + 1
        self.stats.misses = self.stats.misses + 1
    else
        self.stats.hits = self.stats.hits + 1
    end
    local obj = table.remove(self.available)
    self.in_use[obj] = true
    self.stats.acquired = self.stats.acquired + 1
    self.reset_fn(obj)
    return obj
end

function MemoryPool:release(obj)
    if not self.in_use[obj] then return false end
    self.in_use[obj] = nil
    table.insert(self.available, obj)
    self.stats.released = self.stats.released + 1
    return true
end

function MemoryPool:release_all()
    local n = 0
    for obj in pairs(self.in_use) do
        self.in_use[obj] = nil
        table.insert(self.available, obj)
        n = n + 1
    end
    self.stats.released = self.stats.released + n
    return n
end

function MemoryPool:_count_used()
    local n = 0; for _ in pairs(self.in_use) do n = n + 1 end; return n
end

function MemoryPool:get_stats()
    local used = self:_count_used()
    local total_req = self.stats.hits + self.stats.misses
    return { available = #self.available, in_use = used,
             total = #self.available + used,
             hit_rate = self.stats.hits / math.max(1, total_req) * 100 }
end

local function vector_pool_demo()
    print("=== Vector Object Pool ===\n")
    local pool = MemoryPool.new({
        factory = function() return { x = 0, y = 0, z = 0 } end,
        reset = function(v) v.x, v.y, v.z = 0, 0, 0 end,
        min_size = 4, max_size = 20
    })

    local vecs = {}
    for i = 1, 12 do
        local v = pool:acquire()
        v.x, v.y, v.z = i, i * 2, i * 3
        table.insert(vecs, v)
        print(string.format("  Acquired vec[%d]: (%d, %d, %d)", i, v.x, v.y, v.z))
    end

    print("\n--- Releasing 6 vectors ---")
    for i = 1, 6 do pool:release(vecs[i]) end

    print("--- Acquiring 3 more (reuse) ---")
    for _ = 1, 3 do
        local v = pool:acquire()
        print(string.format("  Got vec (reset): (%d, %d, %d)", v.x, v.y, v.z))
    end

    local s = pool:get_stats()
    print(string.format("\n  Pool stats: available=%d in_use=%d hit_rate=%.0f%%",
        s.available, s.in_use, s.hit_rate))

    pool:release_all()
    s = pool:get_stats()
    print(string.format("  After release_all: available=%d in_use=%d", s.available, s.in_use))
end

local function buffer_pool_demo()
    print("\n=== Buffer Pool Demo ===\n")
    local pool = MemoryPool.new({
        factory = function() return { data = "", capacity = 256 } end,
        reset = function(b) b.data = "" end,
        min_size = 2, max_size = 16
    })

    local bufs = {}
    for i = 1, 5 do
        local b = pool:acquire()
        b.data = string.rep("x", i * 10)
        table.insert(bufs, b)
        print(string.format("  Buffer %d: len=%d", i, #b.data))
    end
    for _, b in ipairs(bufs) do pool:release(b) end
    local s = pool:get_stats()
    print(string.format("\n  Buffer pool: available=%d hit_rate=%.0f%%", s.available, s.hit_rate))
end

local function main()
    vector_pool_demo()
    buffer_pool_demo()
    print("\n=== All pool demos complete ===")
end

main()
