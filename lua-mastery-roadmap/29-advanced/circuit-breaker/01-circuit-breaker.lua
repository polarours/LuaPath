-- Circuit Breaker Pattern Implementation
-- Version: Lua 5.4
-- Stage 29: Advanced — Circuit Breaker

local CircuitBreaker = {}
CircuitBreaker.__index = CircuitBreaker

-- States
local CLOSED = "closed"
local OPEN = "open"
local HALF_OPEN = "half-open"

function CircuitBreaker.new(opts)
    opts = opts or {}
    local self = setmetatable({}, CircuitBreaker)
    self.failure_threshold = opts.failure_threshold or 5
    self.timeout = opts.timeout or 10
    self.state = CLOSED
    self.failure_count = 0
    self.last_failure_time = 0
    self.fallback = opts.fallback
    return self
end

function CircuitBreaker:is_available()
    if self.state == CLOSED then
        return true
    elseif self.state == OPEN then
        local now = os.time()
        if now - self.last_failure_time >= self.timeout then
            self.state = HALF_OPEN
            return true
        end
        return false
    else -- HALF_OPEN
        return true
    end
end

function CircuitBreaker:record_success()
    self.failure_count = 0
    if self.state == HALF_OPEN then
        self.state = CLOSED
        print("[CircuitBreaker] Recovery confirmed — circuit CLOSED")
    end
end

function CircuitBreaker:record_failure()
    self.failure_count = self.failure_count + 1
    self.last_failure_time = os.time()

    if self.state == HALF_OPEN then
        self.state = OPEN
        print("[CircuitBreaker] Failure in half-open — circuit re-OPENED")
    elseif self.failure_count >= self.failure_threshold then
        self.state = OPEN
        print("[CircuitBreaker] Failure threshold reached — circuit OPENED")
    end
end

function CircuitBreaker:execute(fn, fallback_fn)
    if not self:is_available() then
        print("[CircuitBreaker] Circuit is OPEN — executing fallback")
        if fallback_fn then
            return fallback_fn()
        elseif self.fallback then
            return self.fallback()
        end
        error("circuit breaker is open and no fallback provided")
    end

    local ok, result = pcall(fn)
    if ok then
        self:record_success()
        return result
    else
        self:record_failure()
        if self.fallback then
            return self.fallback()
        end
        error(result)
    end
end

function CircuitBreaker:get_state()
    return self.state
end

function CircuitBreaker:reset()
    self.state = CLOSED
    self.failure_count = 0
    self.last_failure_time = 0
end

-- Example usage
local function main()
    local call_count = 0

    local cb = CircuitBreaker.new({
        failure_threshold = 3,
        timeout = 2,
        fallback = function() return "cached_response" end
    })

    -- Simulate a failing service
    local function unreliable_service()
        call_count = call_count + 1
        if call_count <= 4 then
            error("service unavailable")
        end
        return "fresh_data"
    end

    print("=== Circuit Breaker Demo ===\n")

    -- Attempt 1-3: failures accumulate
    for i = 1, 3 do
        local ok, val = pcall(function()
            return cb:execute(unreliable_service)
        end)
        print(string.format("Attempt %d: state=%s result=%s",
            i, cb:get_state(), tostring(val)))
    end

    -- Circuit is now open — fallback kicks in
    print("\n--- Circuit is OPEN ---")
    for i = 1, 3 do
        local val = cb:execute(unreliable_service)
        print(string.format("Attempt %d: state=%s result=%s",
            i, cb:get_state(), tostring(val)))
    end

    -- Wait for timeout, then test recovery
    print("\n--- Waiting for timeout ---")
    os.execute("sleep 3")

    local val = cb:execute(unreliable_service)
    print(string.format("Recovery attempt: state=%s result=%s",
        cb:get_state(), tostring(val)))

    -- Service is back — circuit closes
    for i = 1, 2 do
        val = cb:execute(unreliable_service)
        print(string.format("Stable call %d: state=%s result=%s",
            i, cb:get_state(), tostring(val)))
    end
end

main()
