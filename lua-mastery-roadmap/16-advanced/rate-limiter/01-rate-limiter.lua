--[[
  Example: Rate Limiter
  Chapter: Stage 16 — Advanced
  Difficulty: Advanced
  Lua Version: 5.4
  Demonstrates: Token bucket algorithm, sliding window log, time-based rate limiting
]]

local RateLimiter = {}
RateLimiter.__index = RateLimiter

-- Token Bucket Algorithm
local TokenBucket = setmetatable({}, { __index = RateLimiter })
TokenBucket.__index = TokenBucket

function TokenBucket:new(config)
    local self = setmetatable({}, TokenBucket)
    self.capacity = config.capacity or 10
    self.tokens = self.capacity
    self.refillRate = config.refillRate or 1
    self.lastRefill = os.time()
    return self
end

function TokenBucket:refill()
    local now = os.time()
    local elapsed = now - self.lastRefill
    self.tokens = math.min(self.capacity, self.tokens + elapsed * self.refillRate)
    self.lastRefill = now
end

function TokenBucket:allow()
    self:refill()
    if self.tokens >= 1 then
        self.tokens = self.tokens - 1
        return true
    end
    return false
end

function TokenBucket:status()
    self:refill()
    return { tokens = self.tokens, capacity = self.capacity }
end

-- Sliding Window Log Algorithm
local SlidingWindow = setmetatable({}, { __index = RateLimiter })
SlidingWindow.__index = SlidingWindow

function SlidingWindow:new(config)
    local self = setmetatable({}, SlidingWindow)
    self.maxRequests = config.maxRequests or 10
    self.windowSize = config.windowSize or 60
    self.log = {}
    return self
end

function SlidingWindow:cleanup()
    local now = os.time()
    local cutoff = now - self.windowSize
    local newLog = {}
    for _, entry in ipairs(self.log) do
        if entry.time > cutoff then
            newLog[#newLog + 1] = entry
        end
    end
    self.log = newLog
end

function SlidingWindow:allow()
    self:cleanup()
    if #self.log < self.maxRequests then
        self.log[#self.log + 1] = { time = os.time() }
        return true
    end
    return false
end

function SlidingWindow:status()
    self:cleanup()
    return { requests = #self.log, limit = self.maxRequests }
end

-- Sliding Window Counter (approximation)
local SlidingWindowCounter = setmetatable({}, { __index = RateLimiter })
SlidingWindowCounter.__index = SlidingWindowCounter

function SlidingWindowCounter:new(config)
    local self = setmetatable({}, SlidingWindowCounter)
    self.maxRequests = config.maxRequests or 10
    self.windowSize = config.windowSize or 60
    self.prevCount = 0
    self.currCount = 0
    self.windowStart = os.time()
    return self
end

function SlidingWindowCounter:rotateWindow()
    local now = os.time()
    if now - self.windowStart >= self.windowSize then
        self.prevCount = self.currCount
        self.currCount = 0
        self.windowStart = now
    end
end

function SlidingWindowCounter:allow()
    self:rotateWindow()
    local elapsed = os.time() - self.windowStart
    local weight = 1 - (elapsed / self.windowSize)
    local estimate = self.prevCount * weight + self.currCount
    if estimate < self.maxRequests then
        self.currCount = self.currCount + 1
        return true
    end
    return false
end

function SlidingWindowCounter:status()
    self:rotateWindow()
    return { current = self.currCount, limit = self.maxRequests }
end

-- Demo
local function main()
    print("=== Rate Limiter Demo ===\n")
    print("--- Token Bucket (capacity=5, refill=2/sec) ---")
    local bucket = TokenBucket:new({ capacity = 5, refillRate = 2 })
    for i = 1, 7 do
        print(string.format("  Request %d: %s", i, bucket:allow() and "ALLOWED" or "DENIED"))
    end
    print("  Status:", bucket:status().tokens, "tokens remaining")
    print("\n--- Sliding Window (max=3 per 60s) ---")
    local window = SlidingWindow:new({ maxRequests = 3, windowSize = 60 })
    for i = 1, 5 do
        print(string.format("  Request %d: %s", i, window:allow() and "ALLOWED" or "DENIED"))
    end
    print("\n--- Sliding Window Counter (max=4 per 60s) ---")
    local counter = SlidingWindowCounter:new({ maxRequests = 4, windowSize = 60 })
    for i = 1, 6 do
        print(string.format("  Request %d: %s", i, counter:allow() and "ALLOWED" or "DENIED"))
    end
    print("\n=== All rate limiters demonstrated ===")
end

main()

return RateLimiter
