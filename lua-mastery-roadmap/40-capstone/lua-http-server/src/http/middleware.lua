-- middleware.lua — Chained middleware pipeline.
-- Each middleware receives (request, response, next) and decides whether
-- to call next() to pass control downstream or short-circuit with a response.

-- Set up module path when run directly
if arg and arg[0]:match("middleware.lua") then
  package.path = "./../?.lua;./?.lua;" .. package.path
end

local Response = require("response")

local MiddlewarePipeline = {}
MiddlewarePipeline.__index = MiddlewarePipeline

--- Create a new pipeline.
function MiddlewarePipeline.new()
  return setmetatable({
    middlewares = {},
    index = 0,
    is_running = false,
  }, MiddlewarePipeline)
end

--- Add a middleware function to the pipeline.
-- order controls invocation sequence (default: append).
function MiddlewarePipeline:use(fn, order)
  if order then
    table.insert(self.middlewares, order, fn)
  else
    self.middlewares[#self.middlewares + 1] = fn
  end
  return self
end

--- Add built-in logging middleware.
function MiddlewarePipeline:logging(opts)
  opts = opts or {}
  local log_fn = opts.logger or print
  self:use(function(req, res, next)
    local start = os.clock()
    next()
    local duration = os.clock() - start
    log_fn(("%s %s %s %d %.3fs"):format(
      os.date("%Y-%m-%d %H:%M:%S"),
      req.method,
      req.path,
      res:get_status_code(),
      duration
    ))
  end)
  return self
end

--- Add built-in error handler middleware.
function MiddlewarePipeline:error_handler(handler)
  handler = handler or function(err)
    print("[ERROR] " .. tostring(err))
  end
  self:use(function(req, res, next)
    local ok, err = xpcall(
      next,
      function(e) return e end
    )
    if not ok and err then
      handler(err)
      if not res.status_code or res.status_code == 200 and res.body == "" then
        res:set_header("Content-Type", "text/plain"):set_body("Internal Server Error")
      end
    end
  end)
  return self
end

--- Add built-in CORS middleware.
function MiddlewarePipeline:cors(origin)
  origin = origin or "*"
  self:use(function(req, res, next)
    res:set_header("Access-Control-Allow-Origin", origin)
    res:set_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS, PATCH")
    res:set_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
    res:set_header("Access-Control-Max-Age", "86400")

    -- Handle preflight OPTIONS
    if req.method == "OPTIONS" then
      res:set_body("")
        :set_header("Content-Length", "0")
      res.status_code = 204
      return res
    end

    next()
  end)
  return self
end

--- Add built-in compression middleware (gzip hint).
function MiddlewarePipeline:compression()
  self:use(function(req, res, next)
    next()
    -- In a real server, this would compress the body if the client accepts gzip.
    -- Here we just set the encoding header when the body exceeds a threshold.
    if req:get_header("Accept-Encoding") and #req.body > 0 then
      res:set_header("Content-Encoding", "identity")
    end
  end)
  return self
end

--- Execute the pipeline synchronously.
-- request must be mutated in-place (headers modified during execution).
function MiddlewarePipeline:execute(request)
  self.index = 0
  self.is_running = true

  local response = Response.new(200, "")
  request.response = response

  local function next_step()
    if self.index < #self.middlewares then
      self.index = self.index + 1
      local ok, result = xpcall(
        function()
          self.middlewares[self.index](request, response, next_step)
        end,
        function(err)
          return debug.traceback("Middleware error at step " .. self.index .. ": " .. tostring(err), 2)
        end
      )
      if not ok then
        response:set_body("Middleware error: " .. tostring(result))
          :set_header("Content-Type", "text/plain")
          :set_header("X-Error", "middleware-failure")
        response.status_code = 500
      end
    end
    self.is_running = false
  end

  next_step()

  return response
end

--- Run a simplified chain where each middleware calls next() exactly once.
-- Supports both sync and callback-style middlewares.
function MiddlewarePipeline:run(request, final_handler)
  self.index = 0

  local response = final_handler and final_handler(request) or Response.new(200, "")
  if not request.response then
    request.response = response
  end

  local function run_next()
    self.index = self.index + 1
    if self.index <= #self.middlewares then
      local mw = self.middlewares[self.index]
      mw(request, response, function()
        -- Guard against re-entry
        if self.index < #self.middlewares then
          run_next()
        end
      end)
    end
  end

  run_next()
  return response
end

--- Clear all middlewares.
function MiddlewarePipeline:clear()
  self.middlewares = {}
  self.index = 0
  return self
end

--- Get the number of registered middlewares.
function MiddlewarePipeline:count()
  return #self.middlewares
end

return MiddlewarePipeline
