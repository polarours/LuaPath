--[[
  Example: Cache System
  Chapter: 11 — Advanced
  Difficulty: Advanced
  Lua Version: 5.3+
  Demonstrates: LRU eviction, TTL expiration, metatables, doubly linked list, eviction callbacks
]]

local LRUCache = {}
LRUCache.__index = LRUCache

function LRUCache.new(opts)
    opts = opts or {}
    local self = setmetatable({
        _max = opts.max or 128,
        _ttl = opts.ttl or math.huge,
        _on_evict = opts.on_evict,
        _store = {},
        _order = { head = nil, tail = nil, len = 0 },
        _hits = 0,
        _misses = 0,
    }, LRUCache)
    return self
end

-- Doubly linked list node
local function make_node(key, value, expires)
    return { key = key, value = value, expires = expires, prev = nil, next = nil }
end

local function list_remove(self, node)
    if node.prev then node.prev.next = node.next else self._order.head = node.next end
    if node.next then node.next.prev = node.prev else self._order.tail = node.prev end
    node.prev, node.next = nil, nil
    self._order.len = self._order.len - 1
end

local function list_push_front(self, node)
    node.next = self._order.head
    node.prev = nil
    if self._order.head then self._order.head.prev = node end
    self._order.head = node
    if not self._order.tail then self._order.tail = node end
    self._order.len = self._order.len + 1
end

local function is_expired(self, node)
    return node.expires and os.clock() > node.expires
end

local function evict_lru(self)
    local node = self._order.tail
    if not node then return end
    list_remove(self, node)
    self._store[node.key] = nil
    if self._on_evict then self._on_evict(node.key, node.value) end
end

function LRUCache:set(key, value)
    local existing = self._store[key]
    if existing then
        list_remove(self, existing)
        self._order.len = self._order.len
    end
    if self._order.len >= self._max then evict_lru(self) end
    local node = make_node(key, value, os.clock() + self._ttl)
    self._store[key] = node
    list_push_front(self, node)
end

function LRUCache:get(key)
    local node = self._store[key]
    if not node then self._misses = self._misses + 1; return nil end
    if is_expired(self, node) then
        list_remove(self, node)
        self._store[key] = nil
        self._misses = self._misses + 1
        return nil
    end
    self._hits = self._hits + 1
    list_remove(self, node)
    node.expires = os.clock() + self._ttl
    list_push_front(self, node)
    return node.value
end

function LRUCache:remove(key)
    local node = self._store[key]
    if not node then return false end
    list_remove(self, node)
    self._store[key] = nil
    return true
end

function LRUCache:clear()
    self._store = {}
    self._order = { head = nil, tail = nil, len = 0 }
end

function LRUCache:stats()
    return {
        size = self._order.len,
        max = self._max,
        hits = self._hits,
        misses = self._misses,
        hit_rate = (self._hits + self._misses) > 0
            and (self._hits / (self._hits + self._misses)) or 0,
    }
end

-- Main demo
function main()
    print("=== LRU Cache System ===\n")

    local evicted = {}
    local cache = LRUCache.new({
        max = 3,
        ttl = 0.5,
        on_evict = function(k, v)
            table.insert(evicted, { key = k, value = v })
            print(string.format("  [evict] key=%s value=%s", k, v))
        end,
    })

    cache:set("a", 1)
    cache:set("b", 2)
    cache:set("c", 3)
    print("After inserting a,b,c:")
    print(string.format("  cache size: %d", cache._order.len))

    cache:set("d", 4)
    print("\nAfter inserting d (evicts least-used 'a'):")
    print(string.format("  evicted count: %d", #evicted))

    print(string.format("\n  get(a) = %s", tostring(cache:get("a"))))
    print(string.format("  get(b) = %s", tostring(cache:get("b"))))
    print(string.format("  get(c) = %s", tostring(cache:get("c"))))
    print(string.format("  get(d) = %s", tostring(cache:get("d"))))

    print("\n  Accessing b then c (promotes b to most recent):")
    cache:get("b")
    cache:get("c")
    cache:set("e", 5)
    print(string.format("  After set(e), get(d) = %s (should be nil — d evicted)", tostring(cache:get("d"))))

    local s = cache:stats()
    print(string.format("\n  Stats: size=%d hits=%d misses=%d hit_rate=%.0f%%",
        s.size, s.hits, s.misses, s.hit_rate * 100))

    print("\n--- TTL Expiration Demo ---")
    local ttl_cache = LRUCache.new({ max = 10, ttl = 0.1 })
    ttl_cache:set("temp", "data")
    print("  set(temp, data) with TTL=0.1s")
    print(string.format("  get(temp) immediately = %s", tostring(ttl_cache:get("temp"))))
    os.execute("sleep 0.2 > /dev/null 2>&1 || ping -c 1 -w 0.2 127.0.0.1 > /dev/null 2>&1")
    print(string.format("  get(temp) after 0.2s  = %s (should be nil)", tostring(ttl_cache:get("temp"))))

    print("\n=== Done ===")
end

main()

return LRUCache
