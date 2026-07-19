-- Middleware Pipeline Implementation
-- Version: Lua 5.4
-- Stage 34: Advanced — Middleware Pipeline

local Pipeline = {}
Pipeline.__index = Pipeline

function Pipeline.new()
    return setmetatable({ middlewares = {}, error_handlers = {} }, Pipeline)
end

function Pipeline:use(mw)
    table.insert(self.middlewares, mw)
    return self
end

function Pipeline:on_error(handler)
    table.insert(self.error_handlers, handler)
    return self
end

function Pipeline:execute(req)
    local res = { status = 200, headers = {}, body = nil, _halted = false }

    local function run(i)
        if res._halted or i > #self.middlewares then return end
        local ok, err = pcall(function()
            self.middlewares[i](req, res, function() run(i + 1) end)
        end)
        if not ok then
            for _, h in ipairs(self.error_handlers) do
                if pcall(h, err, req, res) then break end
            end
        end
    end

    run(1)
    return res
end

local function logging_middleware(req, res, next)
    print(string.format("[LOG] %s %s", req.method, req.path))
    next()
    print(string.format("[LOG] %s %s -> %d", req.method, req.path, res.status))
end

local function auth_middleware(req, res, next)
    local token = req.headers["Authorization"]
    if not token then
        res.status = 401
        res.body = '{"error": "missing authorization token"}'
        res._halted = true
        print("[AUTH] Rejected: no token")
        return
    end
    if token ~= "Bearer valid-token" then
        res.status = 403
        res.body = '{"error": "invalid token"}'
        res._halted = true
        print("[AUTH] Rejected: invalid token")
        return
    end
    req.user = { id = 42, name = "Alice" }
    print("[AUTH] Authenticated: Alice")
    next()
end

local function rate_limiter(limit)
    local counts = {}
    return function(req, res, next)
        local ip = req.headers["X-Forwarded-For"] or "local"
        counts[ip] = (counts[ip] or 0) + 1
        if counts[ip] > limit then
            res.status = 429
            res.body = '{"error": "rate limit exceeded"}'
            res._halted = true
            print(string.format("[RATE] %s blocked (%d/%d)", ip, counts[ip], limit))
            return
        end
        print(string.format("[RATE] %s allowed (%d/%d)", ip, counts[ip], limit))
        next()
    end
end

local function content_type_middleware(req, res, next)
    if req.method == "POST" then
        local ct = req.headers["Content-Type"]
        if not ct or not ct:find("application/json") then
            res.status = 415
            res.body = '{"error": "expected application/json"}'
            res._halted = true
            print("[CT] Rejected: wrong content type")
            return
        end
    end
    next()
end

local function main()
    print("=== Middleware Pipeline Demo ===\n")

    local pipeline = Pipeline.new()
    pipeline:use(logging_middleware)
    pipeline:use(rate_limiter(3))
    pipeline:use(content_type_middleware)
    pipeline:use(auth_middleware)
    pipeline:use(function(req, res, next)
        res.body = string.format('{"message": "hello %s"}', req.user.name)
        next()
    end)
    pipeline:on_error(function(err, req, res)
        res.status = 500
        res.body = '{"error": "internal server error"}'
        print("[ERROR] " .. tostring(err))
    end)

    print("--- Test 1: Valid POST ---")
    local r1 = pipeline:execute({
        method = "POST", path = "/api/data",
        headers = { ["Authorization"] = "Bearer valid-token",
                    ["Content-Type"] = "application/json",
                    ["X-Forwarded-For"] = "10.0.0.1" }
    })
    print(string.format("Result: status=%d body=%s\n", r1.status, r1.body))

    print("--- Test 2: No Auth ---")
    local r2 = pipeline:execute({
        method = "GET", path = "/api/profile",
        headers = { ["X-Forwarded-For"] = "10.0.0.2" }
    })
    print(string.format("Result: status=%d body=%s\n", r2.status, r2.body))

    print("--- Test 3: Rate Limit ---")
    for i = 1, 4 do
        local r = pipeline:execute({
            method = "GET", path = "/api/limit",
            headers = { ["X-Forwarded-For"] = "10.0.0.3",
                        ["Authorization"] = "Bearer valid-token" }
        })
        if r.status == 429 then
            print(string.format("  Attempt %d: BLOCKED (429)", i))
            break
        end
    end
    print("\n=== Pipeline Complete ===")
end

main()
